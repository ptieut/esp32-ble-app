import Foundation
import Combine

@MainActor
final class DeviceStore: ObservableObject {
    static let shared = DeviceStore()

    @Published private(set) var connectedDevices: [ConnectedDevice] = []

    private let bleManager = BLEManager.shared
    private let wifiService = WiFiService()
    private var cancellables = Set<AnyCancellable>()

    private init() {
        bleManager.$connectedPeripherals
            .receive(on: DispatchQueue.main)
            .sink { [weak self] peripherals in
                guard let self else { return }
                let connectedIds = Set(peripherals.keys)
                self.connectedDevices = self.connectedDevices.filter { connectedIds.contains($0.id) }
            }
            .store(in: &cancellables)
    }

    func addDevice(from scanned: ScannedDevice) {
        guard !connectedDevices.contains(where: { $0.id == scanned.id }) else { return }

        let device = ConnectedDevice(
            id: scanned.id,
            name: scanned.name,
            mac: scanned.mac,
            ip: "--",
            firmwareVersion: "unknown",
            battery: 0,
            signal: scanned.rssi,
            status: .active,
            wifiStatus: .disconnected
        )
        connectedDevices = connectedDevices + [device]

        Task {
            await enrichDevice(id: scanned.id)
        }
    }

    func removeDevice(id: UUID) {
        connectedDevices = connectedDevices.filter { $0.id != id }
        Task {
            try? await bleManager.disconnect(deviceId: id)
        }
    }

    func refreshAll() {
        let deviceIds = connectedDevices.map(\.id)
        Task {
            await withTaskGroup(of: Void.self) { group in
                for id in deviceIds {
                    group.addTask { await self.enrichDevice(id: id) }
                }
            }
        }
    }

    private func enrichDevice(id: UUID) async {
        guard bleManager.isConnected(deviceId: id) else { return }

        var ip = "--"
        var wifiStatus: WiFiStatus = .disconnected

        do {
            ip = try await wifiService.readIP(deviceId: id)
            if ip.isEmpty { ip = "--" }
        } catch {
            // Keep default
        }

        do {
            wifiStatus = try await wifiService.readStatus(deviceId: id)
        } catch {
            // Keep default
        }

        guard let current = connectedDevices.first(where: { $0.id == id }) else { return }

        let updated = ConnectedDevice(
            id: current.id,
            name: current.name,
            mac: current.mac,
            ip: ip,
            firmwareVersion: current.firmwareVersion,
            battery: current.battery,
            signal: current.signal,
            status: current.status,
            wifiStatus: wifiStatus
        )

        connectedDevices = connectedDevices.map { $0.id == id ? updated : $0 }
    }
}
