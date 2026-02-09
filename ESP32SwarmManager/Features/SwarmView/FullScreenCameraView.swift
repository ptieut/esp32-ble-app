import SwiftUI

struct FullScreenCameraView: View {
    let deviceId: String
    @StateObject private var rewindVM: RewindViewModel
    @StateObject private var stream = MJPEGStream()
    @ObservedObject private var settings = StreamSettings.shared

    init(deviceId: String) {
        self.deviceId = deviceId
        _rewindVM = StateObject(wrappedValue: RewindViewModel(deviceId: deviceId))
    }

    var body: some View {
        ZStack {
            Theme.background.ignoresSafeArea()

            VStack(spacing: 0) {
                frameView
                    .aspectRatio(16 / 9, contentMode: .fit)

                Spacer()

                if rewindVM.isRewinding {
                    rewindControls
                }

                bottomBar
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .navigationTitle(deviceId)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    if rewindVM.isRewinding {
                        rewindVM.exitRewind()
                        connectStream()
                    } else {
                        rewindVM.isRewinding = true
                        stream.disconnect()
                        rewindVM.loadBuffer()
                    }
                } label: {
                    Image(systemName: rewindVM.isRewinding ? "livephoto" : "gobackward.10")
                        .foregroundColor(rewindVM.isRewinding ? Theme.warning : .white)
                }
            }
        }
        .task { connectStream() }
        .onDisappear { stream.disconnect() }
    }

    @ViewBuilder
    private var frameView: some View {
        if rewindVM.isRewinding, let frame = rewindVM.currentRewindFrame {
            Image(uiImage: frame)
                .resizable()
                .aspectRatio(contentMode: .fill)
                .clipped()
        } else if let frame = stream.currentFrame {
            Image(uiImage: frame)
                .resizable()
                .aspectRatio(contentMode: .fill)
                .clipped()
        } else {
            Color(hex: 0x1E293B)
                .overlay(ProgressView().tint(.white.opacity(0.3)))
        }
    }

    private var rewindControls: some View {
        VStack(spacing: Theme.spacingMD) {
            Text(rewindVM.currentTimestampLabel)
                .font(.system(size: 12, weight: .medium, design: .monospaced))
                .foregroundColor(Theme.textSecondary)

            TimelineScrubber(
                value: $rewindVM.scrubPosition,
                range: 0...1,
                onChanged: { rewindVM.seekToPosition($0) }
            )
            .frame(height: 44)
            .padding(.horizontal, Theme.spacingLG)

            HStack(spacing: Theme.spacingXXL) {
                Button { rewindVM.stepBackward() } label: {
                    Image(systemName: "backward.frame")
                        .font(.system(size: 24))
                        .foregroundColor(.white)
                }

                Button { rewindVM.togglePlayback() } label: {
                    Image(systemName: rewindVM.isPlaying ? "pause.fill" : "play.fill")
                        .font(.system(size: 32))
                        .foregroundColor(.white)
                }

                Button { rewindVM.stepForward() } label: {
                    Image(systemName: "forward.frame")
                        .font(.system(size: 24))
                        .foregroundColor(.white)
                }
            }
            .padding(.bottom, Theme.spacingMD)
        }
        .padding(Theme.spacingLG)
        .background(Color(hex: 0x161B22))
    }

    private var bottomBar: some View {
        HStack {
            HStack(spacing: 6) {
                Circle()
                    .fill(rewindVM.isRewinding ? Theme.warning : Theme.success)
                    .frame(width: 8, height: 8)

                Text(rewindVM.isRewinding ? "REWIND" : "LIVE")
                    .font(.system(size: 12, weight: .medium, design: .monospaced))
                    .foregroundColor(.white)
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 6)
            .background(.black.opacity(0.4))
            .background(.ultraThinMaterial)
            .environment(\.colorScheme, .dark)
            .clipShape(RoundedRectangle(cornerRadius: 6))

            Spacer()

            if rewindVM.isRewinding {
                Text("\(rewindVM.frameIndex + 1)/\(rewindVM.totalFrames)")
                    .font(.system(size: 12, design: .monospaced))
                    .foregroundColor(Theme.textSecondary)
            }
        }
        .padding(Theme.spacingLG)
    }

    private func connectStream() {
        let url = ProxyAPIClient().streamURL(
            deviceId: deviceId,
            withPose: settings.skeletonOverlayEnabled
        )
        if let url { stream.connect(url: url) }
    }
}
