import SwiftUI

struct CameraTileView: View {
    let deviceId: String
    let name: String
    let isStreaming: Bool

    @StateObject private var stream = MJPEGStream()
    @ObservedObject private var settings = StreamSettings.shared

    var body: some View {
        ZStack {
            if let frame = stream.currentFrame {
                Image(uiImage: frame)
                    .resizable()
                    .aspectRatio(contentMode: .fill)

                LinearGradient(
                    colors: [.black.opacity(0.9), .black.opacity(0.2), .clear],
                    startPoint: .bottom,
                    endPoint: .top
                )
                .opacity(0.8)
            } else {
                Color(hex: 0x1E293B)

                if isStreaming {
                    ProgressView()
                        .tint(.white.opacity(0.3))
                        .scaleEffect(1.2)
                }

                LinearGradient(
                    colors: [.black.opacity(0.9), .black.opacity(0.2), .clear],
                    startPoint: .bottom,
                    endPoint: .top
                )
                .opacity(0.8)
            }

            statusBadge
            bottomInfo
        }
        .aspectRatio(16 / 9, contentMode: .fill)
        .clipped()
        .clipShape(RoundedRectangle(cornerRadius: Theme.cornerRadiusMD))
        .overlay(
            RoundedRectangle(cornerRadius: Theme.cornerRadiusMD)
                .stroke(Color.white.opacity(0.1), lineWidth: 1)
        )
        .shadow(radius: 8)
        .task {
            connectIfNeeded()
        }
        .onDisappear {
            stream.disconnect()
        }
        .onChange(of: settings.skeletonOverlayEnabled) { _ in
            stream.disconnect()
            connectIfNeeded()
        }
    }

    private func connectIfNeeded() {
        guard isStreaming else { return }
        let url = ProxyAPIClient().streamURL(
            deviceId: deviceId,
            withPose: settings.skeletonOverlayEnabled
        )
        if let url {
            stream.connect(url: url)
        }
    }

    private var statusBadge: some View {
        VStack {
            HStack {
                Spacer()

                HStack(spacing: 6) {
                    Circle()
                        .fill(statusColor)
                        .frame(width: 8, height: 8)
                        .shadow(color: statusColor.opacity(0.6), radius: 4)

                    Text(statusLabel)
                        .font(.system(size: 10, weight: .medium, design: .monospaced))
                        .foregroundColor(.white.opacity(0.9))
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(.black.opacity(0.4))
                .background(.ultraThinMaterial)
                .environment(\.colorScheme, .dark)
                .clipShape(RoundedRectangle(cornerRadius: 4))
                .overlay(
                    RoundedRectangle(cornerRadius: 4)
                        .stroke(Color.white.opacity(0.1), lineWidth: 1)
                )
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
                    Text(name)
                        .font(.system(size: 12, weight: .bold))
                        .tracking(0.5)
                        .foregroundColor(.white)

                    Text(deviceId)
                        .font(.system(size: 10, design: .monospaced))
                        .foregroundColor(.white.opacity(0.6))
                }

                Spacer()

                if stream.currentFrame != nil {
                    HStack(spacing: 6) {
                        Image(systemName: "video")
                            .font(.system(size: 12))
                            .foregroundColor(Theme.success)

                        Text("LIVE")
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

    private var statusLabel: String {
        if stream.currentFrame != nil {
            return "LIVE"
        } else if isStreaming {
            return "CONNECTING"
        } else {
            return "OFFLINE"
        }
    }

    private var statusColor: Color {
        if stream.currentFrame != nil {
            return Theme.success
        } else if isStreaming {
            return .yellow
        } else {
            return .gray
        }
    }
}

#Preview {
    VStack(spacing: 12) {
        CameraTileView(deviceId: "cam-01", name: "Cam-01 Alpha", isStreaming: true)
        CameraTileView(deviceId: "cam-02", name: "Cam-02 Bravo", isStreaming: false)
    }
    .padding()
    .background(Theme.background)
    .preferredColorScheme(.dark)
}
