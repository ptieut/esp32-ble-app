import Foundation

struct ProxyAPIClient {
    private let baseURL: String

    init(baseURL: String = BLEConstants.proxyServerURL) {
        self.baseURL = baseURL
    }

    func listDevices() async throws -> [ProxyDevice] {
        guard let url = URL(string: "\(baseURL)/devices") else {
            throw ProxyError.invalidURL
        }

        let (data, response) = try await URLSession.shared.data(from: url)

        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw ProxyError.requestFailed
        }

        return try JSONDecoder().decode([ProxyDevice].self, from: data)
    }

    func getMetrics(deviceId: String) async throws -> ProxyMetrics {
        guard let url = URL(string: "\(baseURL)/metrics/\(deviceId)") else {
            throw ProxyError.invalidURL
        }

        let (data, response) = try await URLSession.shared.data(from: url)

        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw ProxyError.requestFailed
        }

        return try JSONDecoder().decode(ProxyMetrics.self, from: data)
    }

    func setPoseMode(deviceId: String, mode: String) async throws {
        guard let url = URL(string: "\(baseURL)/pose-mode/\(deviceId)") else {
            throw ProxyError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONEncoder().encode(["mode": mode])

        let (_, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw ProxyError.requestFailed
        }
    }

    func streamURL(deviceId: String, withPose: Bool = false) -> URL? {
        let path = withPose
            ? "\(baseURL)/live/\(deviceId)?pose=true"
            : "\(baseURL)/live/\(deviceId)"
        return URL(string: path)
    }

    func alertStreamURL(deviceId: String) -> URL? {
        URL(string: "\(baseURL)/pose-alerts-stream/\(deviceId)")
    }

    // MARK: - Buffer (Rewind) Endpoints

    func getBufferMetadata(deviceId: String) async throws -> BufferMetadata {
        guard let url = URL(string: "\(baseURL)/buffer/\(deviceId)") else {
            throw ProxyError.invalidURL
        }

        let (data, response) = try await URLSession.shared.data(from: url)

        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw ProxyError.requestFailed
        }

        return try JSONDecoder().decode(BufferMetadata.self, from: data)
    }

    func getBufferFrames(deviceId: String) async throws -> [BufferFrameInfo] {
        guard let url = URL(string: "\(baseURL)/buffer/\(deviceId)/frames") else {
            throw ProxyError.invalidURL
        }

        let (data, response) = try await URLSession.shared.data(from: url)

        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw ProxyError.requestFailed
        }

        return try JSONDecoder().decode([BufferFrameInfo].self, from: data)
    }

    func getBufferFrame(deviceId: String, timestampMs: UInt64) async throws -> (imageData: Data, timestamp: UInt64) {
        guard let url = URL(string: "\(baseURL)/buffer/\(deviceId)/frame?t=\(timestampMs)") else {
            throw ProxyError.invalidURL
        }

        let (data, response) = try await URLSession.shared.data(from: url)

        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw ProxyError.requestFailed
        }

        let ts = httpResponse.value(forHTTPHeaderField: "X-Frame-Timestamp")
            .flatMap { UInt64($0) } ?? timestampMs
        return (data, ts)
    }

    // MARK: - Recording Endpoints

    func startRecording(deviceId: String) async throws -> RecordingStartResponse {
        guard let url = URL(string: "\(baseURL)/record/start/\(deviceId)") else {
            throw ProxyError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw ProxyError.requestFailed
        }

        return try JSONDecoder().decode(RecordingStartResponse.self, from: data)
    }

    func stopRecording(recordingId: String) async throws -> RecordingStopResponse {
        guard let url = URL(string: "\(baseURL)/record/stop/\(recordingId)") else {
            throw ProxyError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw ProxyError.requestFailed
        }

        return try JSONDecoder().decode(RecordingStopResponse.self, from: data)
    }

    func listRecordings(deviceId: String) async throws -> [RecordingEntry] {
        guard let url = URL(string: "\(baseURL)/record/list/\(deviceId)") else {
            throw ProxyError.invalidURL
        }

        let (data, response) = try await URLSession.shared.data(from: url)

        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw ProxyError.requestFailed
        }

        return try JSONDecoder().decode([RecordingEntry].self, from: data)
    }

    func recordingDownloadURL(recordingId: String) -> URL? {
        URL(string: "\(baseURL)/record/download/\(recordingId)")
    }

    func downloadRecording(recordingId: String) async throws -> URL {
        guard let url = recordingDownloadURL(recordingId: recordingId) else {
            throw ProxyError.invalidURL
        }

        let (tempURL, response) = try await URLSession.shared.download(from: url)

        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw ProxyError.requestFailed
        }

        let destURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("\(recordingId).mp4")
        try? FileManager.default.removeItem(at: destURL)
        try FileManager.default.moveItem(at: tempURL, to: destURL)
        return destURL
    }
}

// MARK: - Models

struct ProxyDevice: Codable, Identifiable {
    let id: String
    let streaming: Bool
    let uptime: Int
    let rssi: Int
    let quality: String
    let last_seen: Int
}

struct ProxyMetrics: Codable {
    let device_id: String
    let frame_count: Int
    let bitrate_kbps: Int
    let avg_frame_size: Int
    let last_frame_size: Int
    let uptime: Int
    let rssi: Int
    let quality: String
    let fps: Double
}

enum ProxyError: LocalizedError {
    case invalidURL
    case requestFailed

    var errorDescription: String? {
        switch self {
        case .invalidURL: return "Invalid proxy server URL"
        case .requestFailed: return "Proxy server request failed"
        }
    }
}
