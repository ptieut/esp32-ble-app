import Foundation
import Combine

@MainActor
final class ScannerViewModel: ObservableObject {
    @Published var discoveredDevices: [ScannedDevice] = []
    @Published var isScanning = false
    @Published var errorMessage: String?
    @Published var connectingDeviceId: UUID?
    @Published var connectedDeviceIds: Set<UUID> = []

    private let bleManager = BLEManager.shared
    private var cancellables = Set<AnyCancellable>()

    init() {
        bleManager.$discoveredDevices
            .receive(on: DispatchQueue.main)
            .assign(to: &$discoveredDevices)

        bleManager.$isScanning
            .receive(on: DispatchQueue.main)
            .assign(to: &$isScanning)

        bleManager.$connectedPeripherals
            .receive(on: DispatchQueue.main)
            .map { Set($0.keys) }
            .assign(to: &$connectedDeviceIds)
    }

    func startScan() {
        Task {
            do {
                try await bleManager.startScan()
            } catch {
                errorMessage = error.localizedDescription
            }
        }
    }

    func stopScan() {
        bleManager.stopScan()
    }

    func toggleScan() {
        if isScanning {
            stopScan()
        } else {
            startScan()
        }
    }

    func connect(to device: ScannedDevice) {
        guard connectingDeviceId == nil else { return }
        connectingDeviceId = device.id

        Task {
            do {
                _ = try await bleManager.connect(deviceId: device.id)
                DeviceStore.shared.addDevice(from: device)
                connectingDeviceId = nil
            } catch {
                errorMessage = "Failed to connect: \(error.localizedDescription)"
                connectingDeviceId = nil
            }
        }
    }

    var sortedDevices: [ScannedDevice] {
        discoveredDevices.sorted { $0.rssi > $1.rssi }
    }
}
