import Foundation

@MainActor
final class RecordingsListViewModel: ObservableObject {
    @Published var recordings: [RecordingEntry] = []
    @Published var isLoading = false

    private let proxyClient = ProxyAPIClient()

    func loadRecordings(for devices: [ProxyDevice]) async {
        isLoading = true
        defer { isLoading = false }

        var allRecordings: [RecordingEntry] = []

        for device in devices {
            do {
                let deviceRecordings = try await proxyClient.listRecordings(deviceId: device.id)
                allRecordings.append(contentsOf: deviceRecordings)
            } catch {
                // Continue loading other devices
            }
        }

        recordings = allRecordings
    }
}
