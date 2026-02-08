import Foundation

struct AppNotification: Identifiable, Equatable {
    let id: String
    let title: String
    let message: String
    let timestamp: Date
    let type: NotificationType
    let imageURL: URL?
    var isUnread: Bool

    var timeAgo: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .short
        return formatter.localizedString(for: timestamp, relativeTo: Date())
    }

    var dateSection: String {
        if Calendar.current.isDateInToday(timestamp) {
            return "Today"
        } else if Calendar.current.isDateInYesterday(timestamp) {
            return "Yesterday"
        }
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: timestamp)
    }
}

enum NotificationType: String, CaseIterable {
    case motion
    case battery
    case firmware
    case connection

    var icon: String {
        switch self {
        case .motion: return "video"
        case .battery: return "battery.25"
        case .firmware: return "checkmark.circle"
        case .connection: return "wifi"
        }
    }

    var color: SwiftUI.Color {
        switch self {
        case .motion: return Theme.textSecondary
        case .battery: return .orange
        case .firmware: return Theme.success
        case .connection: return Theme.primary
        }
    }
}

import SwiftUI
