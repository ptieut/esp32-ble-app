import SwiftUI

struct SwarmViewScreen: View {
    @StateObject private var viewModel = SwarmViewModel()
    @State private var showAdjustSheet = false

    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                LazyVStack(spacing: Theme.spacingMD) {
                    ForEach(viewModel.proxyDevices) { device in
                        CameraTileView(
                            deviceId: device.id,
                            name: device.id,
                            isStreaming: device.streaming
                        )
                    }
                }
                .padding(Theme.spacingMD)
            }

            captureFooter
        }
        .background(Theme.background)
        .navigationTitle("Swarm View")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    viewModel.stopMonitoring()
                    viewModel.startMonitoring()
                } label: {
                    Image(systemName: "arrow.clockwise")
                        .foregroundColor(.white)
                }
            }
        }
        .onAppear { viewModel.startMonitoring() }
        .onDisappear { viewModel.stopMonitoring() }
        .sheet(isPresented: $showAdjustSheet) {
            AdjustSettingsSheet(settings: StreamSettings.shared)
        }
    }

    private var captureFooter: some View {
        VStack(spacing: 0) {
            Divider()
                .background(Color.white.opacity(0.05))

            HStack(spacing: Theme.spacingLG) {
                Button {} label: {
                    Image(systemName: "gobackward.10")
                        .font(.system(size: 22))
                        .foregroundColor(Color(hex: 0xCBD5E1))
                        .frame(width: 56, height: 48)
                        .background(Color(hex: 0x1E293B))
                        .clipShape(RoundedRectangle(cornerRadius: Theme.cornerRadiusMD))
                }

                Button(action: viewModel.toggleCapture) {
                    HStack(spacing: Theme.spacingSM) {
                        Circle()
                            .fill(Theme.error)
                            .frame(width: 12, height: 12)
                            .shadow(color: Theme.error.opacity(0.6), radius: 4)

                        Text(viewModel.isCapturing ? "Stop Capturing" : "Start Capturing")
                            .font(.system(size: 16, weight: .bold))
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 48)
                    .background(Theme.primary)
                    .foregroundColor(.white)
                    .clipShape(RoundedRectangle(cornerRadius: Theme.cornerRadiusMD))
                    .shadow(color: Theme.primary.opacity(0.2), radius: 8)
                }

                Button { showAdjustSheet = true } label: {
                    Image(systemName: "slider.horizontal.3")
                        .font(.system(size: 22))
                        .foregroundColor(Color(hex: 0xCBD5E1))
                        .frame(width: 56, height: 48)
                        .background(Color(hex: 0x1E293B))
                        .clipShape(RoundedRectangle(cornerRadius: Theme.cornerRadiusMD))
                }
            }
            .padding(Theme.spacingLG)
            .padding(.bottom, Theme.spacingSM)
            .background(Color(hex: 0x161B22))
        }
    }
}

#Preview {
    NavigationStack {
        SwarmViewScreen()
    }
    .preferredColorScheme(.dark)
}
