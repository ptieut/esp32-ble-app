import Foundation

@MainActor
final class StreamSettings: ObservableObject {
    static let shared = StreamSettings()

    @Published var brightnessOffset: Float = 0.0 {
        didSet { lock.withLock { cachedBrightness = brightnessOffset } }
    }
    @Published var skeletonOverlayEnabled = false
    @Published var autoExposureEnabled = true {
        didSet { lock.withLock { cachedAutoExposure = autoExposureEnabled } }
    }

    private nonisolated(unsafe) let lock = NSLock()
    private nonisolated(unsafe) var cachedBrightness: Float = 0.0
    private nonisolated(unsafe) var cachedAutoExposure = true

    private init() {}

    nonisolated func threadSafeSettings() -> (brightness: Float, autoExposure: Bool) {
        lock.lock()
        defer { lock.unlock() }
        return (cachedBrightness, cachedAutoExposure)
    }
}
