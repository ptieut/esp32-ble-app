import SwiftUI

struct NotificationRow: View {
    let notification: AppNotification
    let dimmed: Bool

    init(notification: AppNotification, dimmed: Bool = false) {
        self.notification = notification
        self.dimmed = dimmed
    }

    var body: some View {
        HStack(spacing: Theme.spacingLG) {
            thumbnail
            content
            chevron
        }
        .padding(Theme.spacingLG)
        .background(Color(hex: 0x1C1C1E))
        .clipShape(RoundedRectangle(cornerRadius: Theme.cornerRadiusMD))
        .overlay(
            RoundedRectangle(cornerRadius: Theme.cornerRadiusMD)
                .stroke(Theme.border.opacity(0.3), lineWidth: 1)
        )
        .overlay(alignment: .topTrailing) {
            if notification.isUnread {
                Circle()
                    .fill(Theme.primary)
                    .frame(width: 10, height: 10)
                    .shadow(color: Theme.primary.opacity(0.5), radius: 2)
                    .padding(Theme.spacingLG)
            }
        }
        .opacity(dimmed ? 0.6 : 1.0)
        .saturation(dimmed ? 0 : 1)
    }

    private var thumbnail: some View {
        RoundedRectangle(cornerRadius: Theme.cornerRadiusSM)
            .fill(Color(hex: 0x1E293B))
            .frame(width: 64, height: 64)
            .overlay(
                Image(systemName: notification.type.icon)
                    .font(.system(size: 28))
                    .foregroundColor(notification.type.color)
            )
    }

    private var content: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(notification.title)
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(.white)
                .lineLimit(1)

            Text(notification.message)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(notification.isUnread ? Color(hex: 0xE2E8F0) : Theme.textSecondary)
                .lineLimit(1)

            Text(notification.timeAgo)
                .font(.system(size: 12))
                .foregroundColor(Color(hex: 0x64748B))
                .padding(.top, 2)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var chevron: some View {
        Image(systemName: "chevron.right")
            .font(.system(size: 14))
            .foregroundColor(Color(hex: 0x475569))
    }
}

#Preview {
    VStack(spacing: 12) {
        NotificationRow(notification: PreviewData.notifications[0])
        NotificationRow(notification: PreviewData.notifications[1])
        NotificationRow(notification: PreviewData.notifications[2], dimmed: true)
    }
    .padding()
    .background(Theme.background)
    .preferredColorScheme(.dark)
}
