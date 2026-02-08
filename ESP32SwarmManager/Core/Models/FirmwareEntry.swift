import Foundation

struct FirmwareEntry: Identifiable, Codable, Equatable {
    var id: String { version }
    let version: String
    let filename: String
    let size: Int
    let date: String
    let notes: String

    var formattedSize: String {
        let mb = Double(size) / (1024.0 * 1024.0)
        if mb >= 1.0 {
            return String(format: "%.1f MB", mb)
        }
        let kb = Double(size) / 1024.0
        return String(format: "%.0f KB", kb)
    }
}
