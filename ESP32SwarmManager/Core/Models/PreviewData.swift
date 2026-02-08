import Foundation

enum PreviewData {
    // MARK: - Scanned Devices

    static let scannedDevices: [ScannedDevice] = [
        ScannedDevice(
            id: UUID(uuidString: "00000001-0000-0000-0000-000000000001")!,
            name: "ESP32CAM-Living Room",
            mac: "A4:CF:12:88:90:AB",
            rssi: -45,
            type: .camera
        ),
        ScannedDevice(
            id: UUID(uuidString: "00000001-0000-0000-0000-000000000002")!,
            name: "ESP32CAM-Backyard",
            mac: "B2:AA:56:11:43:CD",
            rssi: -60,
            type: .camera
        ),
        ScannedDevice(
            id: UUID(uuidString: "00000001-0000-0000-0000-000000000003")!,
            name: "ESP32CAM-Garage",
            mac: "FF:12:00:99:11:EF",
            rssi: -88,
            type: .board
        ),
    ]

    // MARK: - Connected Devices

    static let connectedDevices: [ConnectedDevice] = [
        ConnectedDevice(
            id: UUID(uuidString: "00000001-0000-0000-0000-000000000001")!,
            name: "Cam-Unit-Alpha",
            mac: "A4:CF:12:88:90:AB",
            ip: "192.168.1.105",
            firmwareVersion: "v1.2.0",
            battery: 85,
            signal: -45,
            status: .active,
            wifiStatus: .connected
        ),
        ConnectedDevice(
            id: UUID(uuidString: "00000001-0000-0000-0000-000000000002")!,
            name: "Cam-Unit-Beta",
            mac: "B2:AA:56:11:43:CD",
            ip: "192.168.1.106",
            firmwareVersion: "v1.1.9",
            battery: 42,
            signal: -60,
            status: .idle,
            wifiStatus: .connected
        ),
        ConnectedDevice(
            id: UUID(uuidString: "00000001-0000-0000-0000-000000000003")!,
            name: "Cam-Unit-Gamma",
            mac: "FF:12:00:99:11:EF",
            ip: "192.168.1.107",
            firmwareVersion: "v1.2.0",
            battery: 12,
            signal: -88,
            status: .lowBattery,
            wifiStatus: .disconnected
        ),
        ConnectedDevice(
            id: UUID(uuidString: "00000001-0000-0000-0000-000000000004")!,
            name: "Cam-Unit-Delta",
            mac: "A4:CF:12:88:93:11",
            ip: "192.168.1.110",
            firmwareVersion: "v1.2.1",
            battery: 98,
            signal: -55,
            status: .active,
            wifiStatus: .connected
        ),
    ]

    // MARK: - Firmware

    static let firmwareEntries: [FirmwareEntry] = [
        FirmwareEntry(
            version: "v2.4.1",
            filename: "ESP32_Cam_v2.4.1.bin",
            size: 2_516_582,
            date: "2026-02-01",
            notes: "Stable release with improved streaming"
        ),
        FirmwareEntry(
            version: "v2.4.0",
            filename: "ESP32_Cam_v2.4.0.bin",
            size: 2_490_112,
            date: "2026-01-15",
            notes: "Added motion detection support"
        ),
    ]

    // MARK: - Notifications

    static let notifications: [AppNotification] = [
        AppNotification(
            id: "n1",
            title: "Living Room Cam",
            message: "Motion Detected",
            timestamp: Date().addingTimeInterval(-120),
            type: .motion,
            imageURL: nil,
            isUnread: true
        ),
        AppNotification(
            id: "n2",
            title: "Backyard Cam 02",
            message: "Low Battery (15%)",
            timestamp: Date().addingTimeInterval(-3600),
            type: .battery,
            imageURL: nil,
            isUnread: false
        ),
        AppNotification(
            id: "n3",
            title: "Garage Unit",
            message: "Firmware Update Complete",
            timestamp: Date().addingTimeInterval(-86400 - 3600),
            type: .firmware,
            imageURL: nil,
            isUnread: false
        ),
        AppNotification(
            id: "n4",
            title: "Front Door",
            message: "Connection Restored",
            timestamp: Date().addingTimeInterval(-86400 - 7200),
            type: .connection,
            imageURL: nil,
            isUnread: false
        ),
        AppNotification(
            id: "n5",
            title: "Front Door",
            message: "Person Detected",
            timestamp: Date().addingTimeInterval(-86400 - 10800),
            type: .motion,
            imageURL: nil,
            isUnread: false
        ),
    ]

    // MARK: - OTA Progress

    static let otaProgress = OTAProgress(
        state: .transferring,
        bytesSent: 1_509_949,
        totalBytes: 2_516_582,
        percent: 60
    )

    // MARK: - Swarm Camera Tiles

    struct CameraTile: Identifiable {
        let id: Int
        let name: String
        let ip: String
        let fps: String?
        let status: CameraStatus
    }

    enum CameraStatus {
        case recording, active, connecting, warning
    }

    static let cameraTiles: [CameraTile] = [
        CameraTile(id: 1, name: "Cam-01 Alpha", ip: "192.168.1.101", fps: "24 FPS", status: .recording),
        CameraTile(id: 2, name: "Cam-02 Bravo", ip: "192.168.1.104", fps: "15 FPS", status: .active),
        CameraTile(id: 3, name: "Cam-03 Charlie", ip: "--.--.--.--", fps: nil, status: .connecting),
        CameraTile(id: 4, name: "Cam-04 Delta", ip: "192.168.1.108", fps: "24 FPS", status: .active),
        CameraTile(id: 5, name: "Cam-05 Echo", ip: "192.168.1.112", fps: "8 FPS", status: .warning),
    ]

    // MARK: - Firmware Update Devices

    struct FirmwareUpdateDevice: Identifiable {
        let id: Int
        let name: String
        let mac: String
        let rssi: Int?
        let status: FirmwareUpdateStatus
        let progress: Double?
        let error: String?
    }

    enum FirmwareUpdateStatus: String {
        case success = "Success"
        case flashing = "Flashing"
        case transferring = "Transferring"
        case queued = "Queued"
        case failed = "Failed"
    }

    static let firmwareUpdateDevices: [FirmwareUpdateDevice] = [
        FirmwareUpdateDevice(id: 1, name: "Cam-Unit-Alpha", mac: "A4:CF:12:88:90:AB", rssi: -42, status: .success, progress: nil, error: nil),
        FirmwareUpdateDevice(id: 2, name: "Cam-Unit-Bravo", mac: "A4:CF:12:88:91:CD", rssi: -58, status: .flashing, progress: 0.85, error: nil),
        FirmwareUpdateDevice(id: 3, name: "Cam-Unit-Charlie", mac: "A4:CF:12:88:92:EF", rssi: -60, status: .transferring, progress: 0.45, error: nil),
        FirmwareUpdateDevice(id: 4, name: "Cam-Unit-Delta", mac: "A4:CF:12:88:93:11", rssi: -55, status: .queued, progress: nil, error: nil),
        FirmwareUpdateDevice(id: 5, name: "Cam-Unit-Echo", mac: "A4:CF:12:88:94:22", rssi: nil, status: .failed, progress: nil, error: "Timeout"),
    ]
}
