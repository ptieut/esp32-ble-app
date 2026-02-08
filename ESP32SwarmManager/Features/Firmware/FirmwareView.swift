import SwiftUI

struct FirmwareView: View {
    @StateObject private var viewModel: FirmwareViewModel
    @Environment(\.dismiss) private var dismiss

    init(selectedDevices: [ConnectedDevice]) {
        _viewModel = StateObject(wrappedValue: FirmwareViewModel(selectedDevices: selectedDevices))
    }

    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(spacing: Theme.spacingXL) {
                    sourceToggle
                    FirmwareTargetCard(firmware: viewModel.selectedFirmware)
                    OverallProgressView(
                        progress: viewModel.overallProgress,
                        completedCount: viewModel.completedCount,
                        totalCount: viewModel.totalCount
                    )
                    deviceList
                }
                .padding(Theme.spacingLG)
                .padding(.bottom, 120)
            }

            footer
        }
        .background(Theme.background)
        .navigationTitle("Firmware Manager")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { viewModel.fetchFirmwareList() }
    }

    private var sourceToggle: some View {
        HStack(spacing: 0) {
            ForEach(FirmwareSource.allCases, id: \.self) { source in
                Button {
                    viewModel.source = source
                } label: {
                    Text(source.rawValue)
                        .font(.system(size: 14, weight: .medium))
                        .frame(maxWidth: .infinity)
                        .frame(height: 44)
                        .background(
                            viewModel.source == source
                                ? (source == .local ? Theme.primary : Color(hex: 0x374151))
                                : Color.clear
                        )
                        .foregroundColor(
                            viewModel.source == source ? .white : Theme.textSecondary
                        )
                        .clipShape(RoundedRectangle(cornerRadius: Theme.cornerRadiusSM))
                }
            }
        }
        .padding(4)
        .background(Theme.surface)
        .clipShape(RoundedRectangle(cornerRadius: Theme.cornerRadiusMD))
    }

    private var deviceList: some View {
        VStack(spacing: Theme.spacingMD) {
            ForEach(viewModel.deviceUpdates) { device in
                DeviceUpdateRow(device: device)
            }
        }
    }

    private var footer: some View {
        VStack(spacing: Theme.spacingMD) {
            Divider()
                .background(Color.white.opacity(0.05))

            VStack(spacing: Theme.spacingMD) {
                if viewModel.isUpdating {
                    Button(action: viewModel.stopUpdate) {
                        HStack(spacing: Theme.spacingSM) {
                            Image(systemName: "stop.circle")
                                .font(.system(size: 18))
                            Text("Stop Update")
                                .font(.system(size: 16, weight: .semibold))
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 48)
                        .background(Theme.error)
                        .foregroundColor(.white)
                        .clipShape(RoundedRectangle(cornerRadius: Theme.cornerRadiusMD))
                        .shadow(color: Theme.error.opacity(0.2), radius: 8)
                    }
                } else {
                    Button(action: viewModel.startUpdate) {
                        HStack(spacing: Theme.spacingSM) {
                            Image(systemName: "arrow.down.circle")
                                .font(.system(size: 18))
                            Text("Start Update")
                                .font(.system(size: 16, weight: .semibold))
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 48)
                        .background(Theme.primary)
                        .foregroundColor(.white)
                        .clipShape(RoundedRectangle(cornerRadius: Theme.cornerRadiusMD))
                        .shadow(color: Theme.primary.opacity(0.25), radius: 8)
                    }
                }

                Text("Warning: Do not power off devices during flashing.")
                    .font(.system(size: 12))
                    .foregroundColor(Color(hex: 0x64748B))
                    .multilineTextAlignment(.center)
            }
            .padding(.horizontal, Theme.spacingLG)
            .padding(.bottom, Theme.spacingSM)
        }
        .background(Theme.background.opacity(0.95))
    }
}

#Preview {
    NavigationStack {
        FirmwareView(selectedDevices: PreviewData.connectedDevices)
    }
    .preferredColorScheme(.dark)
}
