import Foundation
import UIKit

@MainActor
final class MJPEGStream: ObservableObject {
    @Published var currentFrame: UIImage?
    @Published var isConnected = false

    private var task: Task<Void, Never>?

    func connect(url: URL) {
        disconnect()
        isConnected = true

        task = Task {
            do {
                let (bytes, _) = try await URLSession.shared.bytes(from: url)
                var buffer = Data()

                for try await byte in bytes {
                    guard !Task.isCancelled else { break }
                    buffer.append(byte)

                    // Look for JPEG start (FFD8) and end (FFD9) markers
                    if buffer.count >= 2,
                       buffer[buffer.count - 2] == 0xFF,
                       buffer[buffer.count - 1] == 0xD9 {
                        // Find JPEG start marker
                        if let startIndex = findJPEGStart(in: buffer) {
                            let jpegData = buffer[startIndex...]
                            if let image = UIImage(data: Data(jpegData)) {
                                self.currentFrame = image
                            }
                        }
                        buffer.removeAll(keepingCapacity: true)
                    }

                    // Prevent unbounded buffer growth
                    if buffer.count > 1_000_000 {
                        buffer.removeAll(keepingCapacity: true)
                    }
                }
            } catch {
                if !Task.isCancelled {
                    print("MJPEGStream error: \(error)")
                }
            }

            self.isConnected = false
        }
    }

    func disconnect() {
        task?.cancel()
        task = nil
        isConnected = false
        currentFrame = nil
    }

    private func findJPEGStart(in data: Data) -> Data.Index? {
        for i in data.startIndex..<(data.endIndex - 1) {
            if data[i] == 0xFF && data[i + 1] == 0xD8 {
                return i
            }
        }
        return nil
    }
}
