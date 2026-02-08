import CoreBluetooth

enum BLEConstants {
    // MARK: - WiFi Configuration Service
    static let wifiServiceUUID = CBUUID(string: "12345678-1234-5678-1234-56789abcdef0")
    static let ssidCharUUID = CBUUID(string: "12345678-1234-5678-1234-56789abcdef1")
    static let passwordCharUUID = CBUUID(string: "12345678-1234-5678-1234-56789abcdef2")
    static let statusCharUUID = CBUUID(string: "12345678-1234-5678-1234-56789abcdef3")
    static let ipCharUUID = CBUUID(string: "12345678-1234-5678-1234-56789abcdef4")
    static let applyCharUUID = CBUUID(string: "12345678-1234-5678-1234-56789abcdef5")

    // MARK: - OTA Update Service
    static let otaServiceUUID = CBUUID(string: "12345678-1234-5678-1234-56789abcde00")
    static let controlCharUUID = CBUUID(string: "12345678-1234-5678-1234-56789abcde01")
    static let dataCharUUID = CBUUID(string: "12345678-1234-5678-1234-56789abcde02")
    static let otaStatusCharUUID = CBUUID(string: "12345678-1234-5678-1234-56789abcde03")

    // MARK: - Scan Filters
    static let scanServiceUUIDs: [CBUUID] = [wifiServiceUUID, otaServiceUUID]
    static let deviceNamePrefix = "ESP32CAM-"

    // MARK: - BLE Parameters
    static let requestedMTU = 256
    static let chunkSize = 244 // MTU - 3 bytes ATT overhead
    static let chunkDelayInterval = 10 // Pause every N chunks
    static let chunkDelayMs: UInt64 = 20_000_000 // 20ms in nanoseconds
    static let postStartDelayMs: UInt64 = 500_000_000 // 500ms
    static let postFinishDelayMs: UInt64 = 1_000_000_000 // 1000ms

    // MARK: - OTA Commands
    static let otaCmdStart: UInt8 = 0x01
    static let otaCmdAbort: UInt8 = 0x02
    static let otaCmdFinish: UInt8 = 0x03
    static let otaCmdConfirm: UInt8 = 0x04

    // MARK: - Firmware Server
    static let firmwareServerURL = "http://localhost:3001"

    // MARK: - Proxy Server
    static let proxyServerURL = "http://pitieu:8080"
}
