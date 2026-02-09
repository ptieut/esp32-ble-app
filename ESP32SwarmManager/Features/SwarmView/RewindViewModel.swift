import Foundation
import UIKit

@MainActor
final class RewindViewModel: ObservableObject {
    @Published var isRewinding = false
    @Published var isPlaying = false
    @Published var currentRewindFrame: UIImage?
    @Published var scrubPosition: Double = 1.0
    @Published var frameIndex: Int = 0
    @Published var totalFrames: Int = 0
    @Published var currentTimestampLabel: String = "--:--.-"

    let deviceId: String
    private let proxyClient = ProxyAPIClient()
    private var frameTimestamps: [UInt64] = []
    private var playbackTimer: Timer?
    private let timestampFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "HH:mm:ss.S"
        return f
    }()

    init(deviceId: String) {
        self.deviceId = deviceId
    }

    // MARK: - Buffer Loading

    func loadBuffer() {
        Task {
            do {
                let frames = try await proxyClient.getBufferFrames(deviceId: deviceId)
                frameTimestamps = frames.map(\.timestamp_ms)
                totalFrames = frameTimestamps.count

                if !frameTimestamps.isEmpty {
                    frameIndex = frameTimestamps.count - 1
                    scrubPosition = 1.0
                    await fetchFrame(at: frameIndex)
                }
            } catch {
                // Buffer may be empty if device just started
            }
        }
    }

    // MARK: - Seeking

    func seekToPosition(_ position: Double) {
        guard !frameTimestamps.isEmpty else { return }
        let index = Int(position * Double(frameTimestamps.count - 1))
        let clampedIndex = max(0, min(frameTimestamps.count - 1, index))

        guard clampedIndex != frameIndex else { return }
        frameIndex = clampedIndex
        scrubPosition = position

        Task { await fetchFrame(at: clampedIndex) }
    }

    // MARK: - Frame Stepping

    func stepForward() {
        guard frameIndex < frameTimestamps.count - 1 else { return }
        frameIndex += 1
        updateScrubPosition()
        Task { await fetchFrame(at: frameIndex) }
    }

    func stepBackward() {
        guard frameIndex > 0 else { return }
        frameIndex -= 1
        updateScrubPosition()
        Task { await fetchFrame(at: frameIndex) }
    }

    // MARK: - Playback

    func togglePlayback() {
        if isPlaying {
            pausePlayback()
        } else {
            startPlayback()
        }
    }

    private func startPlayback() {
        guard !frameTimestamps.isEmpty else { return }

        if frameIndex >= frameTimestamps.count - 1 {
            frameIndex = 0
        }

        isPlaying = true

        let avgInterval: TimeInterval
        if frameTimestamps.count >= 2 {
            let totalMs = Double(frameTimestamps.last! - frameTimestamps.first!)
            avgInterval = totalMs / Double(frameTimestamps.count - 1) / 1000.0
        } else {
            avgInterval = 1.0 / 15.0
        }

        playbackTimer = Timer.scheduledTimer(
            withTimeInterval: max(avgInterval, 0.02),
            repeats: true
        ) { [weak self] _ in
            Task { @MainActor [weak self] in
                guard let self, self.isPlaying else { return }
                if self.frameIndex < self.frameTimestamps.count - 1 {
                    self.frameIndex += 1
                    self.updateScrubPosition()
                    await self.fetchFrame(at: self.frameIndex)
                } else {
                    self.pausePlayback()
                }
            }
        }
    }

    private func pausePlayback() {
        isPlaying = false
        playbackTimer?.invalidate()
        playbackTimer = nil
    }

    // MARK: - Exit Rewind

    func exitRewind() {
        pausePlayback()
        isRewinding = false
        currentRewindFrame = nil
        frameTimestamps = []
        frameIndex = 0
        totalFrames = 0
        scrubPosition = 1.0
        currentTimestampLabel = "--:--.-"
    }

    // MARK: - Private

    private func fetchFrame(at index: Int) async {
        guard index >= 0, index < frameTimestamps.count else { return }
        let ts = frameTimestamps[index]

        do {
            let (imageData, actualTs) = try await proxyClient.getBufferFrame(
                deviceId: deviceId,
                timestampMs: ts
            )
            if let image = UIImage(data: imageData) {
                currentRewindFrame = image
                let date = Date(timeIntervalSince1970: Double(actualTs) / 1000.0)
                currentTimestampLabel = timestampFormatter.string(from: date)
            }
        } catch {
            // Frame may have been evicted from buffer
        }
    }

    private func updateScrubPosition() {
        guard frameTimestamps.count > 1 else {
            scrubPosition = 0
            return
        }
        scrubPosition = Double(frameIndex) / Double(frameTimestamps.count - 1)
    }
}
