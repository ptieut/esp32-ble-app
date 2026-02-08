import SwiftUI

struct FirmwareTargetCard: View {
    let firmware: FirmwareEntry?

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("TARGET FIRMWARE")
                        .font(.system(size: 10, weight: .semibold))
                        .tracking(1)
                        .foregroundColor(Theme.textSecondary)

                    Text(firmware?.filename ?? "No firmware selected")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                        .lineLimit(1)

                    if let firmware {
                        Text("Size: \(firmware.formattedSize) \u{2022} Build: Stable")
                            .font(.system(size: 14))
                            .foregroundColor(Theme.textSecondary)
                    }
                }

                Spacer()

                Circle()
                    .fill(Theme.primary.opacity(0.1))
                    .frame(width: 40, height: 40)
                    .overlay(
                        Image(systemName: "doc")
                            .foregroundColor(Theme.primary)
                    )
            }

            Divider()
                .background(Color(hex: 0x334155))
                .padding(.top, 20)

            HStack {
                Spacer()
                Button {} label: {
                    HStack(spacing: 4) {
                        Text("Browse Files")
                            .font(.system(size: 14, weight: .medium))
                        Image(systemName: "folder")
                            .font(.system(size: 16))
                    }
                    .foregroundColor(Theme.primary)
                }
            }
            .padding(.top, Theme.spacingLG)
        }
        .padding(20)
        .surfaceStyle()
    }
}

#Preview {
    FirmwareTargetCard(firmware: PreviewData.firmwareEntries.first)
        .padding()
        .background(Theme.background)
        .preferredColorScheme(.dark)
}
