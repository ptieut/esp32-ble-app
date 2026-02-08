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
