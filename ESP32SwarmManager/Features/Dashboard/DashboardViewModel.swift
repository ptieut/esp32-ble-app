import Foundation
import Combine

@MainActor
final class DashboardViewModel: ObservableObject {
    @Published var devices: [ConnectedDevice] = []
    @Published var selectedDeviceIds: Set<UUID> = []
    @Published var errorMessage: String?

    private var cancellables = Set<AnyCancellable>()

    init() {
        DeviceStore.shared.$connectedDevices
            .receive(on: DispatchQueue.main)
            .sink { [weak self] devices in
                guard let self else { return }
                let validIds = Set(devices.map(\.id))
                self.selectedDeviceIds = self.selectedDeviceIds.intersection(validIds)
                self.devices = devices
            }
            .store(in: &cancellables)
    }

    var selectedCount: Int {
        selectedDeviceIds.count
    }

    var hasSelection: Bool {
        !selectedDeviceIds.isEmpty
    }

    var selectedDevices: [ConnectedDevice] {
        devices.filter { selectedDeviceIds.contains($0.id) }
    }

    func toggleSelection(_ deviceId: UUID) {
        if selectedDeviceIds.contains(deviceId) {
            selectedDeviceIds = selectedDeviceIds.subtracting([deviceId])
        } else {
            selectedDeviceIds = selectedDeviceIds.union([deviceId])
        }
    }

    func selectAll() {
        selectedDeviceIds = Set(devices.map(\.id))
    }

    func deselectAll() {
        selectedDeviceIds = []
    }

    func isSelected(_ deviceId: UUID) -> Bool {
        selectedDeviceIds.contains(deviceId)
    }

    func refreshDeviceInfo() {
        DeviceStore.shared.refreshAll()
    }
}
