import SwiftUI

struct NotificationsView: View {
    @ObservedObject private var viewModel = NotificationsViewModel.shared

    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: Theme.spacingXL) {
                ForEach(viewModel.groupedNotifications, id: \.0) { section, notifications in
                    VStack(alignment: .leading, spacing: Theme.spacingMD) {
                        Text(section.uppercased())
                            .font(.system(size: 11, weight: .semibold))
                            .tracking(1)
                            .foregroundColor(Color(hex: 0x64748B))
                            .padding(.horizontal, 4)

                        ForEach(notifications) { notification in
                            NotificationRow(notification: notification)
                                .onTapGesture {
                                    viewModel.markAsRead(notification.id)
                                }
                        }
                    }
                }
            }
            .padding(Theme.spacingLG)
        }
        .background(Theme.background)
        .navigationTitle("Notifications")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("Clear All") {
                    viewModel.clearAll()
                }
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(Theme.primary)
            }
        }
    }
}

#Preview {
    NavigationStack {
        NotificationsView()
    }
    .preferredColorScheme(.dark)
}
