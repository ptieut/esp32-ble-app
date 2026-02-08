import Foundation

struct ScannedDevice: Identifiable, Equatable {
    let id: UUID
    let name: String
    let mac: String
    var rssi: Int
    let type: DeviceType

    enum DeviceType: String {
        case camera
        case board
        case unknown
    }

    var signalStrength: SignalStrength {
        if rssi > -50 { return .strong }
        if rssi > -70 { return .medium }
        return .weak
    }

    enum SignalStrength {
        case strong, medium, weak
    }
}
