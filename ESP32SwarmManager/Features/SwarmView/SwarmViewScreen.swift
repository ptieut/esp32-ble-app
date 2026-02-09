import SwiftUI

struct SwarmViewScreen: View {
    @StateObject private var viewModel = SwarmViewModel()
    @State private var showAdjustSheet = false
    @State private var selectedDeviceId: String = ""
    @State private var showFullScreenCamera = false

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
                        .onTapGesture {
                            if device.streaming {
                                selectedDeviceId = device.id
                                showFullScreenCamera = true
                            }
                        }
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
        .sheet(isPresented: $viewModel.showRecordingsSheet) {
            RecordingsListSheet(devices: viewModel.streamingDevices)
        }
        .navigationDestination(isPresented: $showFullScreenCamera) {
            FullScreenCameraView(deviceId: selectedDeviceId)
        }
    }

    private var captureFooter: some View {
        VStack(spacing: 0) {
            Divider()
                .background(Color.white.opacity(0.05))

            if viewModel.isCapturing {
                HStack(spacing: Theme.spacingSM) {
                    Circle()
                        .fill(Theme.error)
                        .frame(width: 8, height: 8)
                        .shadow(color: Theme.error.opacity(0.6), radius: 4)
                        .modifier(PulseModifier())

                    Text(formatElapsed(viewModel.captureElapsed))
                        .font(.system(size: 14, weight: .medium, design: .monospaced))
                        .foregroundColor(.white)

                    Spacer()

                    Text("\(viewModel.streamingDevices.count) device(s)")
                        .font(.system(size: 12))
                        .foregroundColor(Theme.textSecondary)
                }
                .padding(.horizontal, Theme.spacingLG)
                .padding(.vertical, Theme.spacingSM)
                .background(Theme.error.opacity(0.15))
            }

            HStack(spacing: Theme.spacingLG) {
                Button { viewModel.showRecordingsSheet = true } label: {
                    Image(systemName: "film.stack")
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
                    .background(viewModel.isCapturing ? Theme.error : Theme.primary)
                    .foregroundColor(.white)
                    .clipShape(RoundedRectangle(cornerRadius: Theme.cornerRadiusMD))
                    .shadow(color: (viewModel.isCapturing ? Theme.error : Theme.primary).opacity(0.2), radius: 8)
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

    private func formatElapsed(_ interval: TimeInterval) -> String {
        let minutes = Int(interval) / 60
        let seconds = Int(interval) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
}

#Preview {
    NavigationStack {
        SwarmViewScreen()
    }
    .preferredColorScheme(.dark)
}
