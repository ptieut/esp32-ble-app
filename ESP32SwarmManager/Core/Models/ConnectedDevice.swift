import Foundation
import CoreBluetooth

struct ConnectedDevice: Identifiable, Equatable {
    let id: UUID
    let name: String
    let mac: String
    var ip: String
    var firmwareVersion: String
    var battery: Int
    var signal: Int
    var status: DeviceStatus
    var wifiStatus: WiFiStatus
    var progress: Double?
    var error: String?

    static func == (lhs: ConnectedDevice, rhs: ConnectedDevice) -> Bool {
        lhs.id == rhs.id &&
        lhs.name == rhs.name &&
        lhs.mac == rhs.mac &&
        lhs.ip == rhs.ip &&
        lhs.firmwareVersion == rhs.firmwareVersion &&
        lhs.battery == rhs.battery &&
        lhs.signal == rhs.signal &&
        lhs.status == rhs.status &&
        lhs.wifiStatus == rhs.wifiStatus &&
        lhs.progress == rhs.progress &&
        lhs.error == rhs.error
    }
}

enum DeviceStatus: String, CaseIterable {
    case active = "Active"
    case idle = "Idle"
    case lowBattery = "Low Batt"
    case flashing = "Flashing"
    case success = "Success"
    case failed = "Failed"
    case queued = "Queued"
    case transferring = "Transferring"
}
