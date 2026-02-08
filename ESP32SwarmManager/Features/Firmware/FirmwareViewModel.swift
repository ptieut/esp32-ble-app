import Foundation
import Combine

@MainActor
final class FirmwareViewModel: ObservableObject {
    @Published var source: FirmwareSource = .local
    @Published var firmwareEntries: [FirmwareEntry] = PreviewData.firmwareEntries
    @Published var selectedFirmware: FirmwareEntry?
    @Published var isUpdating = false
    @Published var overallProgress: Double = 0
    @Published var deviceUpdates: [DeviceUpdateInfo] = []
    @Published var errorMessage: String?

    let selectedDevices: [ConnectedDevice]

    private let apiClient = FirmwareAPIClient()
    private let cache = FirmwareCache()
    private let otaService = OTAService()

    init(selectedDevices: [ConnectedDevice]) {
        self.selectedDevices = selectedDevices
        self.selectedFirmware = firmwareEntries.first

        deviceUpdates = selectedDevices.map { device in
            DeviceUpdateInfo(
                id: device.id,
                name: device.name,
                mac: device.mac,
                rssi: device.signal,
                status: .queued,
                progress: 0,
                error: nil
            )
        }
    }

    var completedCount: Int {
        deviceUpdates.filter { $0.status == .success || $0.status == .failed }.count
    }

    var totalCount: Int {
        deviceUpdates.count
    }

    func fetchFirmwareList() {
        Task {
            do {
                firmwareEntries = try await apiClient.listFirmware()
                selectedFirmware = firmwareEntries.first
            } catch {
                errorMessage = error.localizedDescription
            }
        }
    }

    func startUpdate() {
        guard let firmware = selectedFirmware, !isUpdating else { return }
        isUpdating = true

        Task {
            do {
                let firmwareData: Data
                if let cached = cache.getCachedFirmware(version: firmware.version) {
                    firmwareData = cached
                } else {
                    firmwareData = try await apiClient.downloadFirmware(version: firmware.version)
                    try cache.cacheFirmware(version: firmware.version, data: firmwareData)
                }

                for index in deviceUpdates.indices {
                    let deviceId = deviceUpdates[index].id

                    deviceUpdates[index] = DeviceUpdateInfo(
                        id: deviceUpdates[index].id,
                        name: deviceUpdates[index].name,
                        mac: deviceUpdates[index].mac,
                        rssi: deviceUpdates[index].rssi,
                        status: .transferring,
                        progress: 0,
                        error: nil
                    )

                    do {
                        try await otaService.performOTA(
                            deviceId: deviceId,
                            firmwareData: firmwareData
                        ) { [weak self] progress in
                            Task { @MainActor in
                                guard let self else { return }
                                self.deviceUpdates[index] = DeviceUpdateInfo(
                                    id: self.deviceUpdates[index].id,
                                    name: self.deviceUpdates[index].name,
                                    mac: self.deviceUpdates[index].mac,
                                    rssi: self.deviceUpdates[index].rssi,
                                    status: progress.state == .complete ? .success : .transferring,
                                    progress: Double(progress.percent) / 100.0,
                                    error: nil
                                )
                                self.updateOverallProgress()
                            }
                        }

                        deviceUpdates[index] = DeviceUpdateInfo(
                            id: deviceUpdates[index].id,
                            name: deviceUpdates[index].name,
                            mac: deviceUpdates[index].mac,
                            rssi: deviceUpdates[index].rssi,
                            status: .success,
                            progress: 1.0,
                            error: nil
                        )
                    } catch {
                        deviceUpdates[index] = DeviceUpdateInfo(
                            id: deviceUpdates[index].id,
                            name: deviceUpdates[index].name,
                            mac: deviceUpdates[index].mac,
                            rssi: deviceUpdates[index].rssi,
                            status: .failed,
                            progress: deviceUpdates[index].progress,
                            error: error.localizedDescription
                        )
                    }

                    updateOverallProgress()
                }

                isUpdating = false
            } catch {
                errorMessage = error.localizedDescription
                isUpdating = false
            }
        }
    }

    func stopUpdate() {
        isUpdating = false
        for index in deviceUpdates.indices {
            if deviceUpdates[index].status == .transferring || deviceUpdates[index].status == .queued {
                deviceUpdates[index] = DeviceUpdateInfo(
                    id: deviceUpdates[index].id,
                    name: deviceUpdates[index].name,
                    mac: deviceUpdates[index].mac,
                    rssi: deviceUpdates[index].rssi,
                    status: .failed,
                    progress: deviceUpdates[index].progress,
                    error: "Cancelled"
                )
            }
        }
    }

    private func updateOverallProgress() {
        let totalProgress = deviceUpdates.reduce(0.0) { $0 + $1.progress }
        overallProgress = totalProgress / Double(max(deviceUpdates.count, 1))
    }
}

// MARK: - Supporting Types

enum FirmwareSource: String, CaseIterable {
    case cloud = "Cloud Library"
    case local = "Local File"
}

struct DeviceUpdateInfo: Identifiable, Equatable {
    let id: UUID
    let name: String
    let mac: String
    let rssi: Int
    let status: UpdateStatus
    let progress: Double
    let error: String?

    static func == (lhs: DeviceUpdateInfo, rhs: DeviceUpdateInfo) -> Bool {
        lhs.id == rhs.id && lhs.status == rhs.status && lhs.progress == rhs.progress
    }
}

enum UpdateStatus: String {
    case queued = "Queued"
    case transferring = "Transferring"
    case flashing = "Flashing"
    case success = "Success"
    case failed = "Failed"

    var color: Color {
        switch self {
        case .queued: return Theme.textSecondary
        case .transferring: return Theme.primary
        case .flashing: return .orange
        case .success: return Theme.success
        case .failed: return Theme.error
        }
    }

    var icon: String {
        switch self {
        case .queued: return "clock"
        case .transferring: return "arrow.down.circle"
        case .flashing: return "arrow.triangle.2.circlepath"
        case .success: return "checkmark.circle"
        case .failed: return "xmark.circle"
        }
    }
}

import SwiftUI
