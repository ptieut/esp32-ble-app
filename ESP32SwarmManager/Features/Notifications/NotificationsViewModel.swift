import Foundation

@MainActor
final class NotificationsViewModel: ObservableObject {
    @Published var notifications: [AppNotification] = PreviewData.notifications

    var unreadCount: Int {
        notifications.filter(\.isUnread).count
    }

    var groupedNotifications: [(String, [AppNotification])] {
        let grouped = Dictionary(grouping: notifications) { $0.dateSection }

        let sectionOrder = ["Today", "Yesterday"]
        var result: [(String, [AppNotification])] = []

        for section in sectionOrder {
            if let items = grouped[section] {
                result.append((section, items))
            }
        }

        for (section, items) in grouped {
            if !sectionOrder.contains(section) {
                result.append((section, items))
            }
        }

        return result
    }

    func clearAll() {
        notifications = notifications.map { notification in
            AppNotification(
                id: notification.id,
                title: notification.title,
                message: notification.message,
                timestamp: notification.timestamp,
                type: notification.type,
                imageURL: notification.imageURL,
                isUnread: false
            )
        }
    }

    func markAsRead(_ id: String) {
        guard let index = notifications.firstIndex(where: { $0.id == id }) else { return }
        notifications[index] = AppNotification(
            id: notifications[index].id,
            title: notifications[index].title,
            message: notifications[index].message,
            timestamp: notifications[index].timestamp,
            type: notifications[index].type,
            imageURL: notifications[index].imageURL,
            isUnread: false
        )
    }
}
