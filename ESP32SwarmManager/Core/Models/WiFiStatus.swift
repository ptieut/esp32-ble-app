import Foundation

enum WiFiStatus: String, CaseIterable {
    case disconnected
    case connecting
    case connected
    case failed

    init(byte: UInt8) {
        switch byte {
        case 0: self = .disconnected
        case 1: self = .connecting
        case 2: self = .connected
        case 3: self = .failed
        default: self = .disconnected
        }
    }

    var displayText: String {
        rawValue.capitalized
    }

    var icon: String {
        switch self {
        case .disconnected: return "wifi.slash"
        case .connecting: return "wifi.exclamationmark"
        case .connected: return "wifi"
        case .failed: return "xmark.circle"
        }
    }
}
