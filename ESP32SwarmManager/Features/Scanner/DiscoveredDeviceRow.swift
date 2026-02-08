import SwiftUI

struct DiscoveredDeviceRow: View {
    let device: ScannedDevice
    let isConnecting: Bool
    let isConnected: Bool
    let onConnect: () -> Void

    var body: some View {
        HStack(spacing: Theme.spacingLG) {
            deviceIcon
            deviceInfo
            Spacer()
            connectionStatus
        }
        .padding(Theme.spacingLG)
        .cardStyle()
    }

    private var deviceIcon: some View {
        ZStack {
            RoundedRectangle(cornerRadius: Theme.cornerRadiusMD)
                .fill(iconBackgroundColor)
                .frame(width: 48, height: 48)

            Image(systemName: iconName)
                .font(.system(size: 20))
                .foregroundColor(iconColor)
        }
    }

    private var deviceInfo: some View {
        VStack(alignment: .leading, spacing: 2) {
            HStack(spacing: Theme.spacingSM) {
                Text(device.name)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
                    .lineLimit(1)

                if device.rssi > -50 {
                    Circle()
                        .fill(Theme.success)
                        .frame(width: 8, height: 8)
                        .shadow(color: Theme.success.opacity(0.6), radius: 4)
                }
            }

            HStack(spacing: Theme.spacingMD) {
                Text(device.mac)
                    .font(.system(size: 12, design: .monospaced))
                    .foregroundColor(Theme.textSecondary)

                HStack(spacing: 2) {
                    Image(systemName: signalIcon)
                        .font(.system(size: 12))

                    Text("\(device.rssi) dBm")
                        .font(.system(size: 12, weight: .bold))
                }
                .foregroundColor(Theme.signalColor(rssi: device.rssi))
            }
        }
    }

    @ViewBuilder
    private var connectionStatus: some View {
        if isConnected {
            Text("Connected")
                .font(.system(size: 14, weight: .medium))
                .frame(width: 90, height: 36)
                .background(Theme.success.opacity(0.2))
                .foregroundColor(Theme.success)
                .clipShape(RoundedRectangle(cornerRadius: Theme.cornerRadiusSM))
        } else {
            Button(action: onConnect) {
                if isConnecting {
                    ProgressView()
                        .tint(.white)
                        .frame(width: 70, height: 36)
                } else {
                    Text("Connect")
                        .font(.system(size: 14, weight: .medium))
                        .frame(width: 70, height: 36)
                }
            }
            .background(device.rssi > -50 ? Theme.primary : Color(hex: 0x374151))
            .foregroundColor(.white)
            .clipShape(RoundedRectangle(cornerRadius: Theme.cornerRadiusSM))
            .shadow(color: device.rssi > -50 ? Theme.primary.opacity(0.2) : .clear, radius: 4)
            .disabled(isConnecting)
        }
    }

    private var iconName: String {
        switch device.type {
        case .camera: return "video"
        case .board: return "cpu"
        case .unknown: return "questionmark"
        }
    }

    private var iconBackgroundColor: Color {
        device.type == .camera ? Theme.primary.opacity(0.2) : Color(hex: 0x374151).opacity(0.5)
    }

    private var iconColor: Color {
        device.type == .camera ? Theme.primary : Theme.textSecondary
    }

    private var signalIcon: String {
        if device.rssi > -50 { return "cellularbars" }
        if device.rssi > -70 { return "cellularbars" }
        return "cellularbars"
    }
}

#Preview {
    VStack(spacing: 12) {
        DiscoveredDeviceRow(
            device: PreviewData.scannedDevices[0],
            isConnecting: false,
            isConnected: false,
            onConnect: {}
        )
        DiscoveredDeviceRow(
            device: PreviewData.scannedDevices[1],
            isConnecting: true,
            isConnected: false,
            onConnect: {}
        )
        DiscoveredDeviceRow(
            device: PreviewData.scannedDevices[2],
            isConnecting: false,
            isConnected: true,
            onConnect: {}
        )
    }
    .padding()
    .background(Theme.background)
    .preferredColorScheme(.dark)
}
