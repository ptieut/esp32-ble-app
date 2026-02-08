import SwiftUI

struct ContentView: View {
    @State private var selectedTab: Tab = .dashboard
    @State private var unreadNotificationCount = 1
    @State private var lastDeviceCount = 0
    @ObservedObject private var deviceStore = DeviceStore.shared

    var body: some View {
        TabView(selection: $selectedTab) {
            NavigationStack {
                DashboardView(selectedTab: $selectedTab)
            }
            .tabItem {
                Label("Dashboard", systemImage: "square.grid.2x2")
            }
            .tag(Tab.dashboard)

            NavigationStack {
                SwarmViewScreen()
            }
            .tabItem {
                Label("Cameras", systemImage: "video")
            }
            .tag(Tab.cameras)

            NavigationStack {
                NotificationsView()
            }
            .tabItem {
                Label("Alerts", systemImage: "bell")
            }
            .tag(Tab.alerts)
            .badge(unreadNotificationCount)

            NavigationStack {
                ScannerView()
            }
            .tabItem {
                Label("Scan", systemImage: "sensor.tag.radiowaves.forward")
            }
            .tag(Tab.scan)
        }
        .tint(Theme.primary)
        .onChange(of: deviceStore.connectedDevices.count) { newCount in
            if newCount > lastDeviceCount {
                selectedTab = .dashboard
            }
            lastDeviceCount = newCount
        }
    }
}

enum Tab: Hashable {
    case dashboard
    case cameras
    case alerts
    case scan
}

#Preview {
    ContentView()
        .preferredColorScheme(.dark)
}
