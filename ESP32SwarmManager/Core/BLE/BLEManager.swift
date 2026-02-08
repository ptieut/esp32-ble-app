import Foundation
import CoreBluetooth
import Combine

final class BLEManager: NSObject, ObservableObject {
    static let shared = BLEManager()

    // MARK: - Published State

    @Published private(set) var isScanning = false
    @Published private(set) var isPoweredOn = false
    @Published private(set) var discoveredDevices: [ScannedDevice] = []
    @Published private(set) var connectedPeripherals: [UUID: CBPeripheral] = [:]

    // MARK: - Private State

    private var centralManager: CBCentralManager!
    private var peripheralDelegates: [UUID: PeripheralDelegate] = [:]
    private var powerOnContinuations: [CheckedContinuation<Void, Error>] = []
    private var connectContinuations: [UUID: CheckedContinuation<CBPeripheral, Error>] = [:]
    private var disconnectContinuations: [UUID: CheckedContinuation<Void, Error>] = [:]
    private var characteristicSubjects: [CBUUID: PassthroughSubject<Data, Never>] = [:]

    // MARK: - Init

    private override init() {
        super.init()
        centralManager = CBCentralManager(delegate: self, queue: .main)
    }

    // MARK: - Power State

    func waitForPoweredOn() async throws {
        if centralManager.state == .poweredOn { return }
        if centralManager.state == .unauthorized {
            throw BLEError.unauthorized
        }
        if centralManager.state == .unsupported {
            throw BLEError.unsupported
        }

        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            powerOnContinuations.append(continuation)
        }
    }

    // MARK: - Scanning

    func startScan() async throws {
        try await waitForPoweredOn()
        discoveredDevices = []
        isScanning = true

        centralManager.scanForPeripherals(
            withServices: BLEConstants.scanServiceUUIDs,
            options: [CBCentralManagerScanOptionAllowDuplicatesKey: false]
        )
    }

    func stopScan() {
        centralManager.stopScan()
        isScanning = false
    }

    // MARK: - Connection

    func connect(to peripheral: CBPeripheral) async throws -> CBPeripheral {
        try await waitForPoweredOn()

        return try await withCheckedThrowingContinuation { continuation in
            connectContinuations[peripheral.identifier] = continuation
            centralManager.connect(peripheral, options: nil)
        }
    }

    func connect(deviceId: UUID) async throws -> CBPeripheral {
        guard let peripheral = findPeripheral(id: deviceId) else {
            throw BLEError.deviceNotFound
        }
        return try await connect(to: peripheral)
    }

    func disconnect(deviceId: UUID) async throws {
        guard let peripheral = connectedPeripherals[deviceId] else {
            throw BLEError.deviceNotFound
        }

        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            disconnectContinuations[deviceId] = continuation
            centralManager.cancelPeripheralConnection(peripheral)
        }
    }

    func disconnectAll() {
        for (_, peripheral) in connectedPeripherals {
            centralManager.cancelPeripheralConnection(peripheral)
        }
    }

    func isConnected(deviceId: UUID) -> Bool {
        connectedPeripherals[deviceId]?.state == .connected
    }

    // MARK: - Characteristic Operations

    func readCharacteristic(
        deviceId: UUID,
        serviceUUID: CBUUID,
        characteristicUUID: CBUUID
    ) async throws -> Data {
        let delegate = try getDelegate(for: deviceId)
        return try await delegate.readCharacteristic(serviceUUID: serviceUUID, characteristicUUID: characteristicUUID)
    }

    func writeCharacteristic(
        deviceId: UUID,
        serviceUUID: CBUUID,
        characteristicUUID: CBUUID,
        data: Data,
        withResponse: Bool = true
    ) async throws {
        let delegate = try getDelegate(for: deviceId)
        try await delegate.writeCharacteristic(
            serviceUUID: serviceUUID,
            characteristicUUID: characteristicUUID,
            data: data,
            type: withResponse ? .withResponse : .withoutResponse
        )
    }

    func subscribeToCharacteristic(
        deviceId: UUID,
        serviceUUID: CBUUID,
        characteristicUUID: CBUUID
    ) -> AnyPublisher<Data, Never> {
        guard let delegate = peripheralDelegates[deviceId] else {
            return Empty().eraseToAnyPublisher()
        }
        return delegate.subscribeToCharacteristic(
            serviceUUID: serviceUUID,
            characteristicUUID: characteristicUUID
        )
    }

    func enableNotifications(
        deviceId: UUID,
        serviceUUID: CBUUID,
        characteristicUUID: CBUUID
    ) async throws {
        let delegate = try getDelegate(for: deviceId)
        try await delegate.setNotifyValue(
            true,
            serviceUUID: serviceUUID,
            characteristicUUID: characteristicUUID
        )
    }

    // MARK: - Helpers

    func peripheral(for deviceId: UUID) -> CBPeripheral? {
        connectedPeripherals[deviceId]
    }

    private func findPeripheral(id: UUID) -> CBPeripheral? {
        connectedPeripherals[id] ?? centralManager.retrievePeripherals(withIdentifiers: [id]).first
    }

    private func getDelegate(for deviceId: UUID) throws -> PeripheralDelegate {
        guard let delegate = peripheralDelegates[deviceId] else {
            throw BLEError.deviceNotFound
        }
        return delegate
    }
}

// MARK: - CBCentralManagerDelegate

extension BLEManager: CBCentralManagerDelegate {
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        isPoweredOn = central.state == .poweredOn

        let continuations = powerOnContinuations
        powerOnContinuations.removeAll()

        for continuation in continuations {
            switch central.state {
            case .poweredOn:
                continuation.resume()
            case .unauthorized:
                continuation.resume(throwing: BLEError.unauthorized)
            case .unsupported:
                continuation.resume(throwing: BLEError.unsupported)
            default:
                break
            }
        }
    }

    func centralManager(
        _ central: CBCentralManager,
        didDiscover peripheral: CBPeripheral,
        advertisementData: [String: Any],
        rssi RSSI: NSNumber
    ) {
        let name = peripheral.name
            ?? (advertisementData[CBAdvertisementDataLocalNameKey] as? String)
            ?? "Unknown"

        guard name.hasPrefix(BLEConstants.deviceNamePrefix) else { return }

        let deviceType: ScannedDevice.DeviceType
        if name.lowercased().contains("cam") {
            deviceType = .camera
        } else {
            deviceType = .board
        }

        let device = ScannedDevice(
            id: peripheral.identifier,
            name: name,
            mac: formatMAC(peripheral.identifier),
            rssi: RSSI.intValue,
            type: deviceType
        )

        if let index = discoveredDevices.firstIndex(where: { $0.id == device.id }) {
            discoveredDevices[index] = device
        } else {
            discoveredDevices.append(device)
        }
    }

    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        let delegate = PeripheralDelegate(peripheral: peripheral)
        peripheralDelegates[peripheral.identifier] = delegate
        peripheral.delegate = delegate

        peripheral.discoverServices(BLEConstants.scanServiceUUIDs)

        delegate.onServicesDiscovered = { [weak self] in
            guard let self else { return }
            self.connectedPeripherals[peripheral.identifier] = peripheral

            if let continuation = self.connectContinuations.removeValue(forKey: peripheral.identifier) {
                continuation.resume(returning: peripheral)
            }
        }
    }

    func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
        if let continuation = connectContinuations.removeValue(forKey: peripheral.identifier) {
            continuation.resume(throwing: error ?? BLEError.connectionFailed)
        }
    }

    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        connectedPeripherals.removeValue(forKey: peripheral.identifier)
        peripheralDelegates.removeValue(forKey: peripheral.identifier)

        if let continuation = disconnectContinuations.removeValue(forKey: peripheral.identifier) {
            continuation.resume()
        }
    }

    private func formatMAC(_ uuid: UUID) -> String {
        let hex = uuid.uuidString.replacingOccurrences(of: "-", with: "")
        let prefix = String(hex.prefix(12))
        var result = ""
        for (index, char) in prefix.enumerated() {
            if index > 0 && index % 2 == 0 {
                result += ":"
            }
            result.append(char)
        }
        return result.uppercased()
    }
}

// MARK: - Peripheral Delegate

final class PeripheralDelegate: NSObject, CBPeripheralDelegate {
    private let peripheral: CBPeripheral
    private var readContinuations: [CBUUID: CheckedContinuation<Data, Error>] = [:]
    private var writeContinuations: [CBUUID: CheckedContinuation<Void, Error>] = [:]
    private var notifyContinuations: [CBUUID: CheckedContinuation<Void, Error>] = [:]
    private var characteristicSubjects: [CBUUID: PassthroughSubject<Data, Never>] = [:]
    private var remainingServiceDiscoveries = 0
    var onServicesDiscovered: (() -> Void)?

    init(peripheral: CBPeripheral) {
        self.peripheral = peripheral
        super.init()
    }

    // MARK: - Read

    func readCharacteristic(serviceUUID: CBUUID, characteristicUUID: CBUUID) async throws -> Data {
        guard let characteristic = findCharacteristic(serviceUUID: serviceUUID, characteristicUUID: characteristicUUID) else {
            throw BLEError.characteristicNotFound
        }

        return try await withCheckedThrowingContinuation { continuation in
            readContinuations[characteristicUUID] = continuation
            peripheral.readValue(for: characteristic)
        }
    }

    // MARK: - Write

    func writeCharacteristic(
        serviceUUID: CBUUID,
        characteristicUUID: CBUUID,
        data: Data,
        type: CBCharacteristicWriteType
    ) async throws {
        guard let characteristic = findCharacteristic(serviceUUID: serviceUUID, characteristicUUID: characteristicUUID) else {
            throw BLEError.characteristicNotFound
        }

        if type == .withResponse {
            try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
                writeContinuations[characteristicUUID] = continuation
                peripheral.writeValue(data, for: characteristic, type: type)
            }
        } else {
            peripheral.writeValue(data, for: characteristic, type: type)
        }
    }

    // MARK: - Subscribe

    func subscribeToCharacteristic(serviceUUID: CBUUID, characteristicUUID: CBUUID) -> AnyPublisher<Data, Never> {
        let subject = PassthroughSubject<Data, Never>()
        characteristicSubjects[characteristicUUID] = subject

        if let characteristic = findCharacteristic(serviceUUID: serviceUUID, characteristicUUID: characteristicUUID) {
            peripheral.setNotifyValue(true, for: characteristic)
        }

        return subject.eraseToAnyPublisher()
    }

    func setNotifyValue(_ enabled: Bool, serviceUUID: CBUUID, characteristicUUID: CBUUID) async throws {
        guard let characteristic = findCharacteristic(serviceUUID: serviceUUID, characteristicUUID: characteristicUUID) else {
            throw BLEError.characteristicNotFound
        }

        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            notifyContinuations[characteristicUUID] = continuation
            peripheral.setNotifyValue(enabled, for: characteristic)
        }
    }

    // MARK: - CBPeripheralDelegate

    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        guard error == nil, let services = peripheral.services else { return }

        var discoveryCount = 0
        for service in services {
            if service.uuid == BLEConstants.wifiServiceUUID || service.uuid == BLEConstants.otaServiceUUID {
                discoveryCount += 1
            }
        }

        guard discoveryCount > 0 else {
            onServicesDiscovered?()
            onServicesDiscovered = nil
            return
        }

        remainingServiceDiscoveries = discoveryCount

        for service in services {
            let charUUIDs: [CBUUID]
            if service.uuid == BLEConstants.wifiServiceUUID {
                charUUIDs = [
                    BLEConstants.ssidCharUUID,
                    BLEConstants.passwordCharUUID,
                    BLEConstants.statusCharUUID,
                    BLEConstants.ipCharUUID,
                    BLEConstants.applyCharUUID,
                ]
            } else if service.uuid == BLEConstants.otaServiceUUID {
                charUUIDs = [
                    BLEConstants.controlCharUUID,
                    BLEConstants.dataCharUUID,
                    BLEConstants.otaStatusCharUUID,
                ]
            } else {
                continue
            }
            peripheral.discoverCharacteristics(charUUIDs, for: service)
        }
    }

    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        remainingServiceDiscoveries -= 1
        guard remainingServiceDiscoveries == 0 else { return }
        onServicesDiscovered?()
        onServicesDiscovered = nil
    }

    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        if let continuation = readContinuations.removeValue(forKey: characteristic.uuid) {
            if let error {
                continuation.resume(throwing: error)
            } else {
                continuation.resume(returning: characteristic.value ?? Data())
            }
        }

        if let data = characteristic.value {
            characteristicSubjects[characteristic.uuid]?.send(data)
        }
    }

    func peripheral(_ peripheral: CBPeripheral, didWriteValueFor characteristic: CBCharacteristic, error: Error?) {
        if let continuation = writeContinuations.removeValue(forKey: characteristic.uuid) {
            if let error {
                continuation.resume(throwing: error)
            } else {
                continuation.resume()
            }
        }
    }

    func peripheral(_ peripheral: CBPeripheral, didUpdateNotificationStateFor characteristic: CBCharacteristic, error: Error?) {
        if let continuation = notifyContinuations.removeValue(forKey: characteristic.uuid) {
            if let error {
                continuation.resume(throwing: error)
            } else {
                continuation.resume()
            }
        }
    }

    // MARK: - Helpers

    private func findCharacteristic(serviceUUID: CBUUID, characteristicUUID: CBUUID) -> CBCharacteristic? {
        peripheral.services?
            .first(where: { $0.uuid == serviceUUID })?
            .characteristics?
            .first(where: { $0.uuid == characteristicUUID })
    }
}

// MARK: - BLE Errors

enum BLEError: LocalizedError {
    case unauthorized
    case unsupported
    case deviceNotFound
    case connectionFailed
    case characteristicNotFound
    case timeout
    case transferFailed(String)

    var errorDescription: String? {
        switch self {
        case .unauthorized: return "Bluetooth access is not authorized"
        case .unsupported: return "Bluetooth is not supported on this device"
        case .deviceNotFound: return "Device not found"
        case .connectionFailed: return "Failed to connect to device"
        case .characteristicNotFound: return "BLE characteristic not found"
        case .timeout: return "Operation timed out"
        case .transferFailed(let msg): return "Transfer failed: \(msg)"
        }
    }
}
