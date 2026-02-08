import SwiftUI

struct CameraTileView: View {
    let tile: PreviewData.CameraTile

    var body: some View {
        ZStack {
            if tile.status == .connecting {
                connectingOverlay
            } else {
                cameraFeedPlaceholder
            }

            statusIndicators
            bottomInfo
        }
        .aspectRatio(16 / 9, contentMode: .fill)
        .clipShape(RoundedRectangle(cornerRadius: Theme.cornerRadiusMD))
        .overlay(
            RoundedRectangle(cornerRadius: Theme.cornerRadiusMD)
                .stroke(Color.white.opacity(0.1), lineWidth: 1)
        )
        .shadow(radius: 8)
    }

    private var connectingOverlay: some View {
        ZStack {
            LinearGradient(
                colors: [Color(hex: 0x1E293B), Color(hex: 0x0F172A), .black],
                startPoint: .center,
                endPoint: .bottom
            )

            VStack(spacing: 12) {
                ProgressView()
                    .tint(.white.opacity(0.3))
                    .scaleEffect(1.2)

                Text("Connecting...")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.white.opacity(0.5))
            }
        }
    }

    private var cameraFeedPlaceholder: some View {
        ZStack {
            Color(hex: 0x1E293B)

            Image(systemName: "video")
                .font(.system(size: 30))
                .foregroundColor(Color.white.opacity(0.15))

            LinearGradient(
                colors: [.black.opacity(0.9), .black.opacity(0.2), .clear],
                startPoint: .bottom,
                endPoint: .top
            )
            .opacity(0.8)
        }
    }

    private var statusIndicators: some View {
        VStack {
            HStack {
                Spacer()

                HStack(spacing: 8) {
                    if tile.status == .recording {
                        HStack(spacing: 6) {
                            Circle()
                                .fill(Theme.error)
                                .frame(width: 8, height: 8)
                                .shadow(color: Theme.error.opacity(0.6), radius: 4)

                            Text("REC")
                                .font(.system(size: 10, weight: .medium, design: .monospaced))
                                .foregroundColor(.white.opacity(0.9))
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(.black.opacity(0.4))
                                .background(.ultraThinMaterial)
                                .environment(\.colorScheme, .dark)
                                .clipShape(RoundedRectangle(cornerRadius: 4))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 4)
                                        .stroke(Color.white.opacity(0.1), lineWidth: 1)
                                )
                        }
                    }

                    if tile.status == .active {
                        Circle()
                            .fill(Theme.success)
                            .frame(width: 10, height: 10)
                    }

                    if tile.status == .warning {
                        Circle()
                            .fill(Theme.warning)
                            .frame(width: 10, height: 10)
                    }
                }
                .padding(12)
            }

            Spacer()
        }
    }

    private var bottomInfo: some View {
        VStack {
            Spacer()

            HStack(alignment: .bottom) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(tile.name)
                        .font(.system(size: 12, weight: .bold))
                        .tracking(0.5)
                        .foregroundColor(tile.status == .connecting ? .white.opacity(0.7) : .white)

                    Text(tile.ip)
                        .font(.system(size: 10, design: .monospaced))
                        .foregroundColor(tile.status == .connecting ? .white.opacity(0.3) : .white.opacity(0.6))
                }

                Spacer()

                if let fps = tile.fps {
                    HStack(spacing: 6) {
                        Image(systemName: fpsIcon)
                            .font(.system(size: 12))
                            .foregroundColor(fpsIconColor)

                        Text(fps)
                            .font(.system(size: 12, weight: .medium, design: .monospaced))
                            .foregroundColor(.white)
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 6)
                    .background(.black.opacity(0.4))
                    .background(.ultraThinMaterial)
                    .environment(\.colorScheme, .dark)
                    .clipShape(RoundedRectangle(cornerRadius: 6))
                    .overlay(
                        RoundedRectangle(cornerRadius: 6)
                            .stroke(Color.white.opacity(0.1), lineWidth: 1)
                    )
                }
            }
            .padding(12)
        }
    }

    private var fpsIcon: String {
        tile.status == .warning ? "wifi.exclamationmark" : "video"
    }

    private var fpsIconColor: Color {
        switch tile.status {
        case .warning: return Theme.warning
        case .active: return Theme.success
        default: return Theme.primary
        }
    }
}

#Preview {
    VStack(spacing: 12) {
        CameraTileView(tile: PreviewData.cameraTiles[0])
        CameraTileView(tile: PreviewData.cameraTiles[2])
    }
    .padding()
    .background(Theme.background)
    .preferredColorScheme(.dark)
}
