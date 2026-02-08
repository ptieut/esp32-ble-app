import Foundation
import Combine

struct WiFiService {
    private let bleManager: BLEManager

    init(bleManager: BLEManager = .shared) {
        self.bleManager = bleManager
    }

    // MARK: - Read Operations

    func readSSID(deviceId: UUID) async throws -> String {
        let data = try await bleManager.readCharacteristic(
            deviceId: deviceId,
            serviceUUID: BLEConstants.wifiServiceUUID,
            characteristicUUID: BLEConstants.ssidCharUUID
        )
        return String(data: data, encoding: .utf8) ?? ""
    }

    func readStatus(deviceId: UUID) async throws -> WiFiStatus {
        let data = try await bleManager.readCharacteristic(
            deviceId: deviceId,
            serviceUUID: BLEConstants.wifiServiceUUID,
            characteristicUUID: BLEConstants.statusCharUUID
        )
        guard let byte = data.first else { return .disconnected }
        return WiFiStatus(byte: byte)
    }

    func readIP(deviceId: UUID) async throws -> String {
        let data = try await bleManager.readCharacteristic(
            deviceId: deviceId,
            serviceUUID: BLEConstants.wifiServiceUUID,
            characteristicUUID: BLEConstants.ipCharUUID
        )
        return String(data: data, encoding: .utf8) ?? ""
    }

    // MARK: - Write Operations

    func writeSSID(deviceId: UUID, ssid: String) async throws {
        guard let data = ssid.data(using: .utf8) else { return }
        try await bleManager.writeCharacteristic(
            deviceId: deviceId,
            serviceUUID: BLEConstants.wifiServiceUUID,
            characteristicUUID: BLEConstants.ssidCharUUID,
            data: data,
            withResponse: true
        )
    }

    func writePassword(deviceId: UUID, password: String) async throws {
        guard let data = password.data(using: .utf8) else { return }
        try await bleManager.writeCharacteristic(
            deviceId: deviceId,
            serviceUUID: BLEConstants.wifiServiceUUID,
            characteristicUUID: BLEConstants.passwordCharUUID,
            data: data,
            withResponse: true
        )
    }

    func applyConfig(deviceId: UUID) async throws {
        let data = Data([0x01])
        try await bleManager.writeCharacteristic(
            deviceId: deviceId,
            serviceUUID: BLEConstants.wifiServiceUUID,
            characteristicUUID: BLEConstants.applyCharUUID,
            data: data,
            withResponse: true
        )
    }

    // MARK: - Monitor

    func monitorStatus(deviceId: UUID) -> AnyPublisher<WiFiStatus, Never> {
        bleManager.subscribeToCharacteristic(
            deviceId: deviceId,
            serviceUUID: BLEConstants.wifiServiceUUID,
            characteristicUUID: BLEConstants.statusCharUUID
        )
        .compactMap { data in
            guard let byte = data.first else { return nil }
            return WiFiStatus(byte: byte)
        }
        .eraseToAnyPublisher()
    }

    // MARK: - Batch Operations

    func pushConfig(ssid: String, password: String, to deviceIds: [UUID]) async -> [UUID: Result<Void, Error>] {
        var results: [UUID: Result<Void, Error>] = [:]

        for deviceId in deviceIds {
            do {
                try await writeSSID(deviceId: deviceId, ssid: ssid)
                try await writePassword(deviceId: deviceId, password: password)
                try await applyConfig(deviceId: deviceId)
                results[deviceId] = .success(())
            } catch {
                results[deviceId] = .failure(error)
            }
        }

        return results
    }
}
