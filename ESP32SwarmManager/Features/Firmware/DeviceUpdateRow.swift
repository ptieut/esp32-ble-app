import SwiftUI

struct DeviceUpdateRow: View {
    let device: DeviceUpdateInfo

    var body: some View {
        HStack(spacing: Theme.spacingLG) {
            statusCircle
            deviceDetails
            retryButton
        }
        .padding(Theme.spacingLG)
        .background(Theme.surface)
        .clipShape(RoundedRectangle(cornerRadius: Theme.cornerRadiusMD))
        .overlay(
            RoundedRectangle(cornerRadius: Theme.cornerRadiusMD)
                .stroke(Theme.border.opacity(0.3), lineWidth: 1)
        )
        .overlay(alignment: .leading) {
            Rectangle()
                .fill(device.status.color)
                .frame(width: 3)
                .clipShape(
                    UnevenRoundedRectangle(
                        topLeadingRadius: Theme.cornerRadiusMD,
                        bottomLeadingRadius: Theme.cornerRadiusMD
                    )
                )
        }
        .opacity(device.status == .queued ? 0.7 : 1.0)
    }

    private var statusCircle: some View {
        Circle()
            .fill(device.status.color.opacity(0.1))
            .frame(width: 40, height: 40)
            .overlay(
                Group {
                    if device.status == .flashing {
                        Image(systemName: device.status.icon)
                            .foregroundColor(device.status.color)
                            .rotationEffect(.degrees(360))
                            .animation(.linear(duration: 1).repeatForever(autoreverses: false), value: true)
                    } else {
                        Image(systemName: device.status.icon)
                            .foregroundColor(device.status.color)
                    }
                }
            )
    }

    private var deviceDetails: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(device.name)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(.white)
                    .lineLimit(1)

                Spacer()

                Text(statusLabel)
                    .font(.system(size: 11, weight: .bold))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(device.status.color.opacity(0.1))
                    .foregroundColor(device.status.color)
                    .clipShape(Capsule())
            }

            HStack(spacing: Theme.spacingSM) {
                Text("MAC: \(device.mac)")
                    .font(.system(size: 12))
                    .foregroundColor(Theme.textSecondary)

                if device.rssi != 0 {
                    Circle()
                        .fill(Color(hex: 0x475569))
                        .frame(width: 3, height: 3)

                    HStack(spacing: 2) {
                        Image(systemName: "wifi")
                            .font(.system(size: 12))
                        Text("\(device.rssi) dBm")
                            .font(.system(size: 12))
                    }
                    .foregroundColor(Theme.textSecondary)
                }

                if let error = device.error {
                    Text(error)
                        .font(.system(size: 12))
                        .foregroundColor(Theme.error)
                }
            }

            if device.progress > 0 && device.status != .success {
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 3)
                            .fill(Color(hex: 0x1E293B))
                            .frame(height: 6)

                        RoundedRectangle(cornerRadius: 3)
                            .fill(device.status.color)
                            .frame(width: geometry.size.width * device.progress, height: 6)
                    }
                }
                .frame(height: 6)
                .padding(.top, 4)
            }
        }
    }

    @ViewBuilder
    private var retryButton: some View {
        if device.status == .failed {
            Button {} label: {
                Image(systemName: "arrow.clockwise")
                    .foregroundColor(Theme.textSecondary)
            }
        }
    }

    private var statusLabel: String {
        if device.status == .transferring {
            return "Transferring \(Int(device.progress * 100))%"
        }
        return device.status.rawValue
    }
}

#Preview {
    VStack(spacing: 12) {
        ForEach(PreviewData.firmwareUpdateDevices) { dev in
            DeviceUpdateRow(device: DeviceUpdateInfo(
                id: UUID(),
                name: dev.name,
                mac: dev.mac,
                rssi: dev.rssi ?? 0,
                status: {
                    switch dev.status {
                    case .success: return .success
                    case .flashing: return .flashing
                    case .transferring: return .transferring
                    case .queued: return .queued
                    case .failed: return .failed
                    }
                }(),
                progress: dev.progress ?? 0,
                error: dev.error
            ))
        }
    }
    .padding()
    .background(Theme.background)
    .preferredColorScheme(.dark)
}
