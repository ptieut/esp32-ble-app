import Foundation

final class SSEAlertClient: @unchecked Sendable {
    var onAlert: ((ProxyAlertUpdate) -> Void)?
    private(set) var isConnected = false

    private var task: Task<Void, Never>?

    func connect(url: URL) {
        disconnect()
        isConnected = true
        print("[SSE] Connecting to \(url)")

        task = Task {
            do {
                let (bytes, response) = try await URLSession.shared.bytes(from: url)
                if let http = response as? HTTPURLResponse {
                    print("[SSE] Connected, status: \(http.statusCode)")
                }
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
                            do {
                                let update = try JSONDecoder().decode(ProxyAlertUpdate.self, from: data)
                                print("[SSE] Decoded alert: \(update.alerts.count) alerts for \(update.device_id)")
                                onAlert?(update)
                            } catch {
                                print("[SSE] Decode error: \(error)")
                                print("[SSE] Raw data: \(dataBuffer)")
                            }
                        }
                        eventType = nil
                        dataBuffer = ""
                    }
                }
                print("[SSE] Stream ended")
            } catch {
                if !Task.isCancelled {
                    print("[SSE] Connection error: \(error)")
                }
            }
            isConnected = false
        }
    }

    func disconnect() {
        task?.cancel()
        task = nil
        isConnected = false
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
