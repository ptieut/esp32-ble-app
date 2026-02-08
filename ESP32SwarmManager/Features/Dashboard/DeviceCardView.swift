import SwiftUI

struct DeviceCardView: View {
    let device: ConnectedDevice
    let isSelected: Bool
    let onToggle: () -> Void

    var body: some View {
        HStack(alignment: .top, spacing: Theme.spacingLG) {
            checkbox
            deviceDetails
        }
        .padding(Theme.spacingLG)
        .cardStyle(isSelected: isSelected)
        .onTapGesture { onToggle() }
    }

    private var checkbox: some View {
        Button(action: onToggle) {
            Image(systemName: isSelected ? "checkmark.square.fill" : "square")
                .font(.system(size: 22))
                .foregroundColor(isSelected ? Theme.primary : Theme.textSecondary)
        }
        .padding(.top, 2)
    }

    private var deviceDetails: some View {
        VStack(alignment: .leading, spacing: Theme.spacingSM) {
            HStack {
                Text(device.name)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
                    .lineLimit(1)

                Spacer()

                statusBadge
            }

            HStack(spacing: Theme.spacingMD) {
                Text("IP: \(device.ip)")
                    .foregroundColor(Theme.textSecondary)
                    .lineLimit(1)

                Circle()
                    .fill(Color(hex: 0x475569))
                    .frame(width: 4, height: 4)

                Text("FW: \(device.firmwareVersion)")
                    .foregroundColor(Theme.textSecondary)
                    .lineLimit(1)
            }
            .font(.system(size: 14))

            HStack(spacing: Theme.spacingLG) {
                HStack(spacing: 6) {
                    Image(systemName: Theme.batteryIcon(level: device.battery))
                        .font(.system(size: 18))
                        .foregroundColor(Theme.batteryColor(level: device.battery))

                    Text("\(device.battery)%")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(Color(hex: 0xE2E8F0))
                }

                Image(systemName: "wifi")
                    .font(.system(size: 18))
                    .foregroundColor(Theme.primary)

                Image(systemName: device.status == .active ? "dot.radiowaves.left.and.right" : "dot.radiowaves.left.and.right")
                    .font(.system(size: 18))
                    .foregroundColor(device.status == .active ? Theme.primary : Color(hex: 0x475569))
            }
            .padding(.top, 4)
        }
    }

    private var statusBadge: some View {
        Text(device.status.rawValue.uppercased())
            .font(.system(size: 10, weight: .bold))
            .tracking(0.5)
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(Theme.statusColor(device.status).opacity(0.1))
            .foregroundColor(Theme.statusColor(device.status))
            .clipShape(Capsule())
    }


}

#Preview {
    VStack(spacing: 12) {
        DeviceCardView(
            device: PreviewData.connectedDevices[0],
            isSelected: true,
            onToggle: {}
        )
        DeviceCardView(
            device: PreviewData.connectedDevices[2],
            isSelected: false,
            onToggle: {}
        )
    }
    .padding()
    .background(Theme.background)
    .preferredColorScheme(.dark)
}
