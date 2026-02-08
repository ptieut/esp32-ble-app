import SwiftUI

struct ScannerView: View {
    @StateObject private var viewModel = ScannerViewModel()

    var body: some View {
        VStack(spacing: 0) {
            radarSection
            deviceListSection
        }
        .background(Theme.background)
        .navigationTitle("Scanner")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    viewModel.toggleScan()
                } label: {
                    Image(systemName: "arrow.clockwise")
                        .foregroundColor(Theme.primary)
                }
            }
        }
        .onAppear { viewModel.startScan() }
        .onDisappear { viewModel.stopScan() }
    }

    private var radarSection: some View {
        VStack(spacing: Theme.spacingLG) {
            RadarAnimationView(isAnimating: viewModel.isScanning)
                .padding(.top, Theme.spacingXL)

            VStack(spacing: Theme.spacingSM) {
                Text("Scanning nearby...")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(.white)

                Text("Looking for ESP32-CAM devices via Bluetooth Low Energy")
                    .font(.system(size: 14))
                    .foregroundColor(Theme.textSecondary)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: 240)
            }
            .padding(.bottom, Theme.spacingXL)
        }
    }

    private var deviceListSection: some View {
        VStack(spacing: 0) {
            HStack {
                Text("Discovered (\(viewModel.sortedDevices.count))")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.white)

                Spacer()

                Text("SORT BY SIGNAL")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(Color(hex: 0x64748B))
                    .tracking(1)
            }
            .padding(.horizontal, Theme.spacingXL)
            .padding(.vertical, 20)

            Divider()
                .background(Color.white.opacity(0.05))

            ScrollView {
                LazyVStack(spacing: Theme.spacingMD) {
                    ForEach(viewModel.sortedDevices) { device in
                        DiscoveredDeviceRow(
                            device: device,
                            isConnecting: viewModel.connectingDeviceId == device.id,
                            isConnected: viewModel.connectedDeviceIds.contains(device.id),
                            onConnect: { viewModel.connect(to: device) }
                        )
                    }

                    if viewModel.isScanning {
                        scanningIndicator
                    }

                    if viewModel.sortedDevices.isEmpty && !viewModel.isScanning {
                        emptyState
                    }
                }
                .padding(.horizontal, Theme.spacingLG)
                .padding(.vertical, Theme.spacingMD)
            }
        }
        .background(Color(hex: 0x151B2B))
        .clipShape(
            UnevenRoundedRectangle(
                topLeadingRadius: Theme.cornerRadiusXL,
                topTrailingRadius: Theme.cornerRadiusXL
            )
        )
        .shadow(color: .black.opacity(0.3), radius: 10, y: -4)
    }

    private var scanningIndicator: some View {
        HStack(spacing: Theme.spacingSM) {
            ForEach(0..<3) { index in
                Circle()
                    .fill(Color(hex: 0x475569))
                    .frame(width: 8, height: 8)
                    .offset(y: scanBounce(index: index))
                    .animation(
                        .easeInOut(duration: 0.6)
                        .repeatForever()
                        .delay(Double(index) * 0.2),
                        value: true
                    )
            }
        }
        .padding(.vertical, Theme.spacingXL)
    }

    private var emptyState: some View {
        VStack(spacing: Theme.spacingMD) {
            Image(systemName: "antenna.radiowaves.left.and.right.slash")
                .font(.system(size: 40))
                .foregroundColor(Theme.textSecondary)

            Text("No devices found")
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(Theme.textSecondary)

            Text("Make sure your ESP32-CAM devices are powered on and in range")
                .font(.system(size: 14))
                .foregroundColor(Color(hex: 0x64748B))
                .multilineTextAlignment(.center)
        }
        .padding(.vertical, 40)
    }

    private func scanBounce(index: Int) -> CGFloat {
        -6
    }
}

#Preview {
    NavigationStack {
        ScannerView()
    }
    .preferredColorScheme(.dark)
}
