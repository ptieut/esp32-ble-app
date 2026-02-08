import Foundation

struct FirmwareAPIClient {
    private let baseURL: String

    init(baseURL: String = BLEConstants.firmwareServerURL) {
        self.baseURL = baseURL
    }

    func listFirmware() async throws -> [FirmwareEntry] {
        guard let url = URL(string: "\(baseURL)/api/firmware") else {
            throw FirmwareError.invalidURL
        }

        let (data, response) = try await URLSession.shared.data(from: url)

        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw FirmwareError.fetchFailed
        }

        return try JSONDecoder().decode([FirmwareEntry].self, from: data)
    }

    func getLatestVersion() async throws -> FirmwareEntry {
        guard let url = URL(string: "\(baseURL)/api/firmware/latest") else {
            throw FirmwareError.invalidURL
        }

        let (data, response) = try await URLSession.shared.data(from: url)

        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw FirmwareError.fetchFailed
        }

        return try JSONDecoder().decode(FirmwareEntry.self, from: data)
    }

    func downloadFirmware(version: String) async throws -> Data {
        guard let url = URL(string: "\(baseURL)/api/firmware/\(version)/download") else {
            throw FirmwareError.invalidURL
        }

        let (data, response) = try await URLSession.shared.data(from: url)

        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw FirmwareError.downloadFailed
        }

        return data
    }
}

enum FirmwareError: LocalizedError {
    case invalidURL
    case fetchFailed
    case downloadFailed
    case fileNotFound
    case cacheFailed

    var errorDescription: String? {
        switch self {
        case .invalidURL: return "Invalid firmware server URL"
        case .fetchFailed: return "Failed to fetch firmware list"
        case .downloadFailed: return "Failed to download firmware"
        case .fileNotFound: return "Firmware file not found"
        case .cacheFailed: return "Failed to cache firmware"
        }
    }
}
