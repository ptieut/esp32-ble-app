import Foundation

@MainActor
final class NotificationsViewModel: ObservableObject {
    static let shared = NotificationsViewModel()

    @Published var notifications: [AppNotification] = []

    private var alertClients: [String: SSEAlertClient] = [:]
    private let proxyClient = ProxyAPIClient()
    private var monitoringTask: Task<Void, Never>?

    private init() {
        startMonitoring()
    }

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

    func startMonitoring() {
        guard monitoringTask == nil else { return }
        monitoringTask = Task {
            while !Task.isCancelled {
                await refreshDeviceConnections()
                try? await Task.sleep(nanoseconds: 30_000_000_000)
            }
        }
    }

    private func refreshDeviceConnections() async {
        do {
            let devices = try await proxyClient.listDevices()
            let streaming = devices.filter(\.streaming)
            let streamingIds = Set(streaming.map(\.id))
            print("[Alerts] Found \(devices.count) devices, \(streaming.count) streaming, \(alertClients.count) active clients")

            // Remove clients for non-streaming devices or dead connections
            for (deviceId, client) in alertClients {
                if !streamingIds.contains(deviceId) || !client.isConnected {
                    print("[Alerts] Removing client for \(deviceId) (streaming: \(streamingIds.contains(deviceId)), connected: \(client.isConnected))")
                    client.disconnect()
                    alertClients.removeValue(forKey: deviceId)
                }
            }

            // Add clients for new streaming devices
            for device in devices where device.streaming {
                guard alertClients[device.id] == nil else { continue }
                guard let url = proxyClient.alertStreamURL(deviceId: device.id) else { continue }

                print("[Alerts] Creating SSE client for \(device.id)")
                let client = SSEAlertClient()
                let deviceId = device.id
                client.onAlert = { [weak self] update in
                    Task { @MainActor [weak self] in
                        self?.handleAlertUpdate(deviceId: deviceId, update: update)
                    }
                }
                alertClients[device.id] = client
                client.connect(url: url)
            }
        } catch {
            print("[Alerts] refreshDeviceConnections error: \(error)")
        }
    }

    func stopMonitoring() {
        monitoringTask?.cancel()
        monitoringTask = nil
        for (_, client) in alertClients { client.disconnect() }
        alertClients.removeAll()
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

    private func handleAlertUpdate(deviceId: String, update: ProxyAlertUpdate) {
        print("[Alerts] handleAlertUpdate: \(update.alerts.count) alerts for \(deviceId), current notifications: \(notifications.count)")
        let currentCategories = Set(update.alerts.map { "\(deviceId)_\($0.category)" })

        // Remove stale alerts for this device
        notifications.removeAll { notification in
            notification.id.hasPrefix("\(deviceId)_") && !currentCategories.contains(notification.id)
        }

        // Add or update alerts
        for alert in update.alerts {
            let notifId = "\(deviceId)_\(alert.category)"
            if let index = notifications.firstIndex(where: { $0.id == notifId }) {
                // Update existing
                notifications[index] = AppNotification(
                    id: notifId,
                    title: deviceId,
                    message: alert.message,
                    timestamp: Date(),
                    type: .motion,
                    imageURL: nil,
                    isUnread: true
                )
            } else {
                // Add new
                notifications.insert(
                    AppNotification(
                        id: notifId,
                        title: deviceId,
                        message: alert.message,
                        timestamp: Date(),
                        type: .motion,
                        imageURL: nil,
                        isUnread: true
                    ),
                    at: 0
                )
            }
        }
    }
}
