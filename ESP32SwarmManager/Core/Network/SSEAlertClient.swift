import Foundation

final class SSEAlertClient: @unchecked Sendable {
    var onAlert: ((ProxyAlertUpdate) -> Void)?

    private var task: Task<Void, Never>?

    func connect(url: URL) {
        disconnect()

        task = Task {
            do {
                let (bytes, _) = try await URLSession.shared.bytes(from: url)
                var eventType: String?
                var dataBuffer = ""

                for try await line in bytes.lines {
                    guard !Task.isCancelled else { break }

                    if line.hasPrefix("event:") {
                        eventType = line.dropFirst(6).trimmingCharacters(in: .whitespaces)
                    } else if line.hasPrefix("data:") {
                        dataBuffer += line.dropFirst(5).trimmingCharacters(in: .whitespaces)
                    } else if line.isEmpty {
                        // Empty line = end of event
                        if eventType == "alerts", !dataBuffer.isEmpty,
                           let data = dataBuffer.data(using: .utf8) {
                            if let update = try? JSONDecoder().decode(ProxyAlertUpdate.self, from: data) {
                                onAlert?(update)
                            }
                        }
                        eventType = nil
                        dataBuffer = ""
                    }
                }
            } catch {
                if !Task.isCancelled {
                    print("SSEAlertClient error: \(error)")
                }
            }
        }
    }

    func disconnect() {
        task?.cancel()
        task = nil
    }
}

// MARK: - Models

struct ProxyAlertUpdate: Codable {
    let device_id: String
    let alerts: [ProxyAlert]
}

struct ProxyAlert: Codable {
    let severity: String
    let message: String
    let category: String
}
