import SwiftUI

struct ActionBarView: View {
    let onUpdateWiFi: () -> Void
    let onPushFirmware: () -> Void
    let onViewStream: () -> Void

    var body: some View {
        VStack(spacing: Theme.spacingSM) {
            HStack(spacing: Theme.spacingMD) {
                Button(action: onUpdateWiFi) {
                    HStack(spacing: Theme.spacingSM) {
                        Image(systemName: "wifi")
                            .font(.system(size: 18))
                        Text("Update Wi-Fi")
                            .font(.system(size: 14, weight: .semibold))
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 48)
                    .background(Color(hex: 0x374151))
                    .foregroundColor(.white)
                    .clipShape(RoundedRectangle(cornerRadius: Theme.cornerRadiusSM))
                }

                Button(action: onPushFirmware) {
                    HStack(spacing: Theme.spacingSM) {
                        Image(systemName: "square.and.arrow.down")
                            .font(.system(size: 18))
                        Text("Push Firmware")
                            .font(.system(size: 14, weight: .semibold))
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 48)
                    .background(Theme.primary)
                    .foregroundColor(.white)
                    .clipShape(RoundedRectangle(cornerRadius: Theme.cornerRadiusSM))
                    .shadow(color: Theme.primary.opacity(0.25), radius: 8)
                }

                Button(action: onViewStream) {
                    HStack(spacing: Theme.spacingSM) {
                        Image(systemName: "video")
                            .font(.system(size: 18))
                        Text("View Stream")
                            .font(.system(size: 14, weight: .semibold))
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 48)
                    .background(Color(hex: 0x374151))
                    .foregroundColor(.white)
                    .clipShape(RoundedRectangle(cornerRadius: Theme.cornerRadiusSM))
                }
            }
        }
        .padding(Theme.spacingLG)
        .background(
            Theme.background.opacity(0.95)
                .background(.ultraThinMaterial)
        )
        .environment(\.colorScheme, .dark)
    }
}

#Preview {
    ActionBarView(onUpdateWiFi: {}, onPushFirmware: {}, onViewStream: {})
        .background(Theme.background)
        .preferredColorScheme(.dark)
}
