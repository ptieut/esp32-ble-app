import SwiftUI

struct CameraTileView: View {
    let deviceId: String
    let name: String
    let isStreaming: Bool

    @StateObject private var stream = MJPEGStream()

    var body: some View {
        ZStack {
            if !isStreaming {
                connectingOverlay
            } else if let frame = stream.currentFrame {
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
                cameraFeedPlaceholder
            }

            statusIndicators
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
            if isStreaming, let url = ProxyAPIClient().streamURL(deviceId: deviceId) {
                stream.connect(url: url)
            }
        }
        .onDisappear {
            stream.disconnect()
        }
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

            if stream.isConnected {
                ProgressView()
                    .tint(.white.opacity(0.3))
            } else {
                Image(systemName: "video")
                    .font(.system(size: 30))
                    .foregroundColor(Color.white.opacity(0.15))
            }

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
                    if isStreaming && stream.currentFrame != nil {
                        HStack(spacing: 6) {
                            Circle()
                                .fill(Theme.error)
                                .frame(width: 8, height: 8)
                                .shadow(color: Theme.error.opacity(0.6), radius: 4)

                            Text("LIVE")
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

                    if isStreaming {
                        Circle()
                            .fill(Theme.success)
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
                    Text(name)
                        .font(.system(size: 12, weight: .bold))
                        .tracking(0.5)
                        .foregroundColor(.white)

                    Text(deviceId)
                        .font(.system(size: 10, design: .monospaced))
                        .foregroundColor(.white.opacity(0.6))
                }

                Spacer()

                if isStreaming && stream.currentFrame != nil {
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
