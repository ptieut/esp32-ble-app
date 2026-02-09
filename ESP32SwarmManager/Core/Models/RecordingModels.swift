import Foundation

// MARK: - Buffer Models

struct BufferMetadata: Codable {
    let frame_count: Int
    let oldest_ms: UInt64
    let newest_ms: UInt64
    let duration_ms: UInt64
}

struct BufferFrameInfo: Codable {
    let timestamp_ms: UInt64
    let size: Int
}

// MARK: - Recording Models

struct RecordingStartResponse: Codable {
    let recording_id: String
    let device_id: String
}

struct RecordingStopResponse: Codable {
    let recording_id: String
    let frame_count: Int
    let duration_ms: UInt64
    let download_url: String
    let file_size: UInt64
}

struct RecordingEntry: Codable, Identifiable {
    let recording_id: String
    let frame_count: Int
    let duration_ms: UInt64
    let file_size: UInt64
    let download_url: String

    var id: String { recording_id }

    var formattedDuration: String {
        let seconds = Int(duration_ms / 1000)
        let minutes = seconds / 60
        let secs = seconds % 60
        return String(format: "%d:%02d", minutes, secs)
    }

    var formattedSize: String {
        let formatter = ByteCountFormatter()
        formatter.countStyle = .file
        return formatter.string(fromByteCount: Int64(file_size))
    }
}
