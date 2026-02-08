import Foundation

struct OTAProgress: Equatable {
    let state: OTAState
    let bytesSent: Int
    let totalBytes: Int
    let percent: Int

    static let idle = OTAProgress(state: .idle, bytesSent: 0, totalBytes: 0, percent: 0)
}

enum OTAState: String, CaseIterable {
    case idle
    case starting
    case transferring
    case finishing
    case confirming
    case complete
    case error

    init(byte: UInt8) {
        let states: [OTAState] = [.idle, .starting, .transferring, .finishing, .confirming, .complete, .error]
        if byte < states.count {
            self = states[Int(byte)]
        } else {
            self = .error
        }
    }

    var displayText: String {
        switch self {
        case .idle: return "Idle"
        case .starting: return "Starting"
        case .transferring: return "Transferring"
        case .finishing: return "Finishing"
        case .confirming: return "Confirming"
        case .complete: return "Complete"
        case .error: return "Error"
        }
    }
}
