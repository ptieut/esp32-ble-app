import Foundation

final class SSEAlertClient: NSObject, @unchecked Sendable, URLSessionDataDelegate {
    var onAlert: ((ProxyAlertUpdate) -> Void)?
    private(set) var isConnected = false

    private var dataTask: URLSessionDataTask?
    private var session: URLSession?
    private var eventType: String?
    private var dataBuffer = ""
    private var lineBuffer = ""

    func connect(url: URL) {
        disconnect()
        isConnected = true
        print("[SSE] Connecting to \(url)")

        var request = URLRequest(url: url)
        request.setValue("text/event-stream", forHTTPHeaderField: "Accept")
        request.setValue("no-cache", forHTTPHeaderField: "Cache-Control")
        request.timeoutInterval = .infinity

        let config = URLSessionConfiguration.default
        config.requestCachePolicy = .reloadIgnoringLocalAndRemoteCacheData
        config.timeoutIntervalForRequest = .infinity
        config.timeoutIntervalForResource = .infinity

        let session = URLSession(configuration: config, delegate: self, delegateQueue: nil)
        self.session = session
        dataTask = session.dataTask(with: request)
        dataTask?.resume()
    }

    func disconnect() {
        dataTask?.cancel()
        dataTask = nil
        session?.invalidateAndCancel()
        session = nil
        isConnected = false
        eventType = nil
        dataBuffer = ""
        lineBuffer = ""
    }

    // MARK: - URLSessionDataDelegate

    func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive response: URLResponse, completionHandler: @escaping (URLSession.ResponseDisposition) -> Void) {
        if let http = response as? HTTPURLResponse {
            print("[SSE] Connected, status: \(http.statusCode)")
        }
        completionHandler(.allow)
    }

    func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive data: Data) {
        guard let chunk = String(data: data, encoding: .utf8) else { return }

        lineBuffer += chunk

        // Process complete lines
        while let newlineRange = lineBuffer.range(of: "\n") {
            let line = String(lineBuffer[lineBuffer.startIndex..<newlineRange.lowerBound])
            lineBuffer = String(lineBuffer[newlineRange.upperBound...])
            processLine(line)
        }
    }

    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        if let error = error, (error as NSError).code != NSURLErrorCancelled {
            print("[SSE] Connection error: \(error)")
        } else {
            print("[SSE] Stream ended")
        }
        isConnected = false
    }

    // MARK: - SSE Line Parsing

    private func processLine(_ line: String) {
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
    let snapshot_url: String?
    let timestamp_ms: UInt64?
    let clip_url: String?
}
