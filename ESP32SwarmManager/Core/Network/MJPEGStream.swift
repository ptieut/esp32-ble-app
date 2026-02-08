import Foundation
import UIKit

@MainActor
final class MJPEGStream: ObservableObject {
    @Published var currentFrame: UIImage?
    @Published var isConnected = false

    private var delegate: StreamDelegate?
    private var session: URLSession?
    private var dataTask: URLSessionDataTask?

    func connect(url: URL) {
        disconnect()
        isConnected = true

        let delegate = StreamDelegate { [weak self] image in
            Task { @MainActor [weak self] in
                self?.currentFrame = image
            }
        }
        self.delegate = delegate

        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 30
        config.timeoutIntervalForResource = .infinity
        config.requestCachePolicy = .reloadIgnoringLocalCacheData

        let session = URLSession(configuration: config, delegate: delegate, delegateQueue: nil)
        self.session = session

        var request = URLRequest(url: url)
        request.cachePolicy = .reloadIgnoringLocalCacheData

        let task = session.dataTask(with: request)
        self.dataTask = task
        task.resume()
    }

    func disconnect() {
        dataTask?.cancel()
        dataTask = nil
        session?.invalidateAndCancel()
        session = nil
        delegate = nil
        isConnected = false
        currentFrame = nil
    }
}

private final class StreamDelegate: NSObject, URLSessionDataDelegate {
    private var buffer = Data()
    private let onFrame: @Sendable (UIImage) -> Void

    init(onFrame: @escaping @Sendable (UIImage) -> Void) {
        self.onFrame = onFrame
    }

    func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive data: Data) {
        buffer.append(data)
        extractFrames()
    }

    func urlSession(
        _ session: URLSession,
        dataTask: URLSessionDataTask,
        didReceive response: URLResponse,
        completionHandler: @escaping (URLSession.ResponseDisposition) -> Void
    ) {
        completionHandler(.allow)
    }

    private func extractFrames() {
        while let range = findJPEGRange() {
            let jpegData = buffer[range]
            if let image = UIImage(data: Data(jpegData)) {
                onFrame(image)
            }
            buffer.removeSubrange(buffer.startIndex...range.upperBound)
        }

        // Prevent unbounded buffer growth
        if buffer.count > 1_000_000 {
            buffer.removeAll(keepingCapacity: true)
        }
    }

    private func findJPEGRange() -> ClosedRange<Data.Index>? {
        guard buffer.count >= 4 else { return nil }

        var startIdx: Data.Index?

        for i in buffer.startIndex..<(buffer.endIndex - 1) {
            if buffer[i] == 0xFF && buffer[i + 1] == 0xD8 {
                startIdx = i
                break
            }
        }

        guard let start = startIdx else {
            // Discard bytes before any potential start marker
            if buffer.count > 2 {
                buffer.removeSubrange(buffer.startIndex..<(buffer.endIndex - 1))
            }
            return nil
        }

        for i in (start + 2)..<(buffer.endIndex - 1) {
            if buffer[i] == 0xFF && buffer[i + 1] == 0xD9 {
                return start...(i + 1)
            }
        }

        return nil
    }
}
