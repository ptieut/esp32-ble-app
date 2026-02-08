import Foundation

@MainActor
final class SwarmViewModel: ObservableObject {
    @Published var proxyDevices: [ProxyDevice] = []
    @Published var isCapturing = false

    private let proxyClient = ProxyAPIClient()
    private var pollTimer: Timer?

    func toggleCapture() {
        isCapturing.toggle()
    }

    func startMonitoring() {
        fetchDevices()
        pollTimer = Timer.scheduledTimer(withTimeInterval: 3.0, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.fetchDevices()
            }
        }
    }

    func stopMonitoring() {
        pollTimer?.invalidate()
        pollTimer = nil
    }

    private func fetchDevices() {
        Task {
            do {
                proxyDevices = try await proxyClient.listDevices()
            } catch {
                // Keep existing devices on network error
            }
        }
    }
}
