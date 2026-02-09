import Foundation

@MainActor
final class SwarmViewModel: ObservableObject {
    @Published var proxyDevices: [ProxyDevice] = []
    @Published var isCapturing = false
    @Published var captureElapsed: TimeInterval = 0
    @Published var captureError: String?
    @Published var showRecordingsSheet = false

    var streamingDevices: [ProxyDevice] {
        proxyDevices.filter(\.streaming)
    }

    private let proxyClient = ProxyAPIClient()
    private var pollTimer: Timer?
    private var captureTimer: Timer?
    private var captureStartDate: Date?
    private var activeRecordings: [String: String] = [:]

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

    func toggleCapture() {
        if isCapturing {
            stopCapture()
        } else {
            startCapture()
        }
    }

    private func startCapture() {
        guard !streamingDevices.isEmpty else { return }
        captureError = nil
        isCapturing = true
        captureStartDate = Date()
        captureElapsed = 0

        captureTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                guard let self, let start = self.captureStartDate else { return }
                self.captureElapsed = Date().timeIntervalSince(start)
            }
        }

        Task {
            for device in streamingDevices {
                do {
                    let response = try await proxyClient.startRecording(deviceId: device.id)
                    activeRecordings[device.id] = response.recording_id
                } catch {
                    // Continue with other devices on individual failure
                }
            }
            if activeRecordings.isEmpty {
                captureError = "Failed to start recording"
                isCapturing = false
                captureTimer?.invalidate()
            }
        }
    }

    private func stopCapture() {
        captureTimer?.invalidate()
        captureTimer = nil

        let recordingsToStop = activeRecordings
        activeRecordings.removeAll()
        isCapturing = false

        Task {
            for (_, recordingId) in recordingsToStop {
                do {
                    _ = try await proxyClient.stopRecording(recordingId: recordingId)
                } catch {
                    // Log but don't block other stop calls
                }
            }
        }
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
