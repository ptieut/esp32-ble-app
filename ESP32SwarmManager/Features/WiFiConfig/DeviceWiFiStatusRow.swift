import SwiftUI

struct DeviceWiFiStatusRow: View {
    let device: ConnectedDevice
    let pushStatus: WiFiPushStatus

    var body: some View {
        HStack(spacing: Theme.spacingMD) {
            Circle()
                .fill(Theme.primary.opacity(0.2))
                .frame(width: 40, height: 40)
                .overlay(
                    Image(systemName: "video")
                        .font(.system(size: 18))
                        .foregroundColor(Theme.primary)
                )

            VStack(alignment: .leading, spacing: 2) {
                Text(device.name)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.white)
                    .lineLimit(1)

                HStack(spacing: 4) {
                    Image(systemName: statusIcon)
                        .font(.system(size: 12))
                        .foregroundColor(statusColor)

                    Text(statusText)
                        .font(.system(size: 12))
                        .foregroundColor(Theme.textSecondary)
                        .lineLimit(1)
                }
            }

            Spacer()

            statusIndicator
        }
        .padding(Theme.spacingMD)
        .background(Theme.surfaceLight)
        .clipShape(RoundedRectangle(cornerRadius: Theme.cornerRadiusSM))
        .overlay(
            RoundedRectangle(cornerRadius: Theme.cornerRadiusSM)
                .stroke(Theme.border, lineWidth: 1)
        )
    }

    private var statusIndicator: some View {
        Group {
            switch pushStatus {
            case .ready:
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(Theme.primary)
                    .font(.system(size: 24))
            case .pushing:
                ProgressView()
                    .tint(Theme.primary)
            case .success:
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(Theme.success)
                    .font(.system(size: 24))
            case .failed:
                Image(systemName: "xmark.circle.fill")
                    .foregroundColor(Theme.error)
                    .font(.system(size: 24))
            }
        }
    }

    private var statusIcon: String {
        switch pushStatus {
        case .success: return "wifi"
        case .failed: return "wifi.exclamationmark"
        default: return "dot.radiowaves.left.and.right"
        }
    }

    private var statusColor: Color {
        switch pushStatus {
        case .success: return Theme.success
        case .failed: return Theme.error
        default: return Theme.success
        }
    }

    private var statusText: String {
        switch pushStatus {
        case .ready: return "Connected via BLE"
        case .pushing: return "Pushing config..."
        case .success: return "Config applied"
        case .failed(let msg): return "Failed: \(msg)"
        }
    }
}

#Preview {
    VStack(spacing: 12) {
        DeviceWiFiStatusRow(
            device: PreviewData.connectedDevices[0],
            pushStatus: .ready
        )
        DeviceWiFiStatusRow(
            device: PreviewData.connectedDevices[1],
            pushStatus: .pushing
        )
        DeviceWiFiStatusRow(
            device: PreviewData.connectedDevices[2],
            pushStatus: .success
        )
    }
    .padding()
    .background(Theme.background)
    .preferredColorScheme(.dark)
}
