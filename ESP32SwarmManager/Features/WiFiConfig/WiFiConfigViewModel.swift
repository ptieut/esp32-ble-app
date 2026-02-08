import Foundation
import Combine

@MainActor
final class WiFiConfigViewModel: ObservableObject {
    @Published var ssid = ""
    @Published var password = ""
    @Published var isPasswordVisible = false
    @Published var isPushing = false
    @Published var deviceStatuses: [UUID: WiFiPushStatus] = [:]
    @Published var errorMessage: String?

    let selectedDevices: [ConnectedDevice]

    private let wifiService = WiFiService()

    init(selectedDevices: [ConnectedDevice]) {
        self.selectedDevices = selectedDevices
    }

    var canPush: Bool {
        !ssid.isEmpty && !isPushing
    }

    var activeDeviceCount: Int {
        selectedDevices.count
    }

    func pushToDevices() {
        guard canPush else { return }
        isPushing = true

        for device in selectedDevices {
            deviceStatuses[device.id] = .pushing
        }

        Task {
            let results = await wifiService.pushConfig(
                ssid: ssid,
                password: password,
                to: selectedDevices.map(\.id)
            )

            for (deviceId, result) in results {
                switch result {
                case .success:
                    deviceStatuses[deviceId] = .success
                case .failure(let error):
                    deviceStatuses[deviceId] = .failed(error.localizedDescription)
                }
            }

            isPushing = false
        }
    }

    func statusFor(deviceId: UUID) -> WiFiPushStatus {
        deviceStatuses[deviceId] ?? .ready
    }
}

enum WiFiPushStatus: Equatable {
    case ready
    case pushing
    case success
    case failed(String)

    static func == (lhs: WiFiPushStatus, rhs: WiFiPushStatus) -> Bool {
        switch (lhs, rhs) {
        case (.ready, .ready), (.pushing, .pushing), (.success, .success):
            return true
        case (.failed(let a), .failed(let b)):
            return a == b
        default:
            return false
        }
    }
}
