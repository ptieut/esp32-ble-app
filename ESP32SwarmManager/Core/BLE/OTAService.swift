import Foundation
import Combine

struct OTAService {
    private let bleManager: BLEManager

    init(bleManager: BLEManager = .shared) {
        self.bleManager = bleManager
    }

    // MARK: - OTA Commands

    func startOTA(deviceId: UUID, firmwareSize: Int) async throws {
        var payload = Data([BLEConstants.otaCmdStart])
        payload.append(uint32LE(UInt32(firmwareSize)))

        try await bleManager.writeCharacteristic(
            deviceId: deviceId,
            serviceUUID: BLEConstants.otaServiceUUID,
            characteristicUUID: BLEConstants.controlCharUUID,
            data: payload,
            withResponse: true
        )
    }

    func sendChunk(deviceId: UUID, chunk: Data) async throws {
        try await bleManager.writeCharacteristic(
            deviceId: deviceId,
            serviceUUID: BLEConstants.otaServiceUUID,
            characteristicUUID: BLEConstants.dataCharUUID,
            data: chunk,
            withResponse: false
        )
    }

    func finishOTA(deviceId: UUID) async throws {
        let data = Data([BLEConstants.otaCmdFinish])
        try await bleManager.writeCharacteristic(
            deviceId: deviceId,
            serviceUUID: BLEConstants.otaServiceUUID,
            characteristicUUID: BLEConstants.controlCharUUID,
            data: data,
            withResponse: true
        )
    }

    func confirmOTA(deviceId: UUID) async throws {
        let data = Data([BLEConstants.otaCmdConfirm])
        try await bleManager.writeCharacteristic(
            deviceId: deviceId,
            serviceUUID: BLEConstants.otaServiceUUID,
            characteristicUUID: BLEConstants.controlCharUUID,
            data: data,
            withResponse: true
        )
    }

    func abortOTA(deviceId: UUID) async throws {
        let data = Data([BLEConstants.otaCmdAbort])
        try await bleManager.writeCharacteristic(
            deviceId: deviceId,
            serviceUUID: BLEConstants.otaServiceUUID,
            characteristicUUID: BLEConstants.controlCharUUID,
            data: data,
            withResponse: true
        )
    }

    // MARK: - Monitor

    func monitorProgress(deviceId: UUID) -> AnyPublisher<OTAState, Never> {
        bleManager.subscribeToCharacteristic(
            deviceId: deviceId,
            serviceUUID: BLEConstants.otaServiceUUID,
            characteristicUUID: BLEConstants.otaStatusCharUUID
        )
        .compactMap { data in
            guard let byte = data.first else { return nil }
            return OTAState(byte: byte)
        }
        .eraseToAnyPublisher()
    }

    // MARK: - Full OTA Transfer

    func performOTA(
        deviceId: UUID,
        firmwareData: Data,
        onProgress: @escaping (OTAProgress) -> Void
    ) async throws {
        let totalBytes = firmwareData.count

        onProgress(OTAProgress(state: .starting, bytesSent: 0, totalBytes: totalBytes, percent: 0))

        try await startOTA(deviceId: deviceId, firmwareSize: totalBytes)
        try await Task.sleep(nanoseconds: BLEConstants.postStartDelayMs)

        onProgress(OTAProgress(state: .transferring, bytesSent: 0, totalBytes: totalBytes, percent: 0))

        var offset = 0
        var chunkCount = 0

        while offset < totalBytes {
            let end = min(offset + BLEConstants.chunkSize, totalBytes)
            let chunk = firmwareData[offset..<end]

            try await sendChunk(deviceId: deviceId, chunk: Data(chunk))
            offset = end
            chunkCount += 1

            let percent = Int(Double(offset) / Double(totalBytes) * 100)
            onProgress(OTAProgress(state: .transferring, bytesSent: offset, totalBytes: totalBytes, percent: percent))

            if chunkCount % BLEConstants.chunkDelayInterval == 0 {
                try await Task.sleep(nanoseconds: BLEConstants.chunkDelayMs)
            }
        }

        onProgress(OTAProgress(state: .finishing, bytesSent: totalBytes, totalBytes: totalBytes, percent: 100))

        try await finishOTA(deviceId: deviceId)
        try await Task.sleep(nanoseconds: BLEConstants.postFinishDelayMs)

        onProgress(OTAProgress(state: .confirming, bytesSent: totalBytes, totalBytes: totalBytes, percent: 100))

        try await confirmOTA(deviceId: deviceId)

        onProgress(OTAProgress(state: .complete, bytesSent: totalBytes, totalBytes: totalBytes, percent: 100))
    }

    // MARK: - Helpers

    private func uint32LE(_ value: UInt32) -> Data {
        var data = Data(count: 4)
        data[0] = UInt8(value & 0xFF)
        data[1] = UInt8((value >> 8) & 0xFF)
        data[2] = UInt8((value >> 16) & 0xFF)
        data[3] = UInt8((value >> 24) & 0xFF)
        return data
    }
}
