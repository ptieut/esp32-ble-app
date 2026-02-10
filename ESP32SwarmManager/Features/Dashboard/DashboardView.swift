import SwiftUI

struct DashboardView: View {
    @Binding var selectedTab: Tab
    @StateObject private var viewModel = DashboardViewModel()
    @ObservedObject private var notificationsVM = NotificationsViewModel.shared
    @State private var showWiFiConfig = false
    @State private var showFirmware = false

    var body: some View {
        ZStack(alignment: .bottom) {
            ScrollView {
                LazyVStack(spacing: Theme.spacingLG) {
                    NetworkTrafficCard()

                    ForEach(viewModel.devices) { device in
                        DeviceCardView(
                            device: device,
                            isSelected: viewModel.isSelected(device.id),
                            onToggle: { viewModel.toggleSelection(device.id) }
                        )
                    }

                    addDeviceButton
                }
                .padding(Theme.spacingLG)
                .padding(.bottom, viewModel.hasSelection ? 140 : 80)
            }
            .background(Theme.background)

            if viewModel.hasSelection {
                ActionBarView(
                    onUpdateWiFi: { showWiFiConfig = true },
                    onPushFirmware: { showFirmware = true },
                    onViewStream: { selectedTab = .cameras }
                )
            }

            addFloatingButton
        }
        .navigationTitle("Device Dashboard")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button {
                    // Menu action placeholder
                } label: {
                    Image(systemName: "line.3.horizontal")
                        .foregroundColor(Color(hex: 0xCBD5E1))
                }
            }

            ToolbarItem(placement: .topBarTrailing) {
                NavigationLink(destination: NotificationsView()) {
                    ZStack(alignment: .topTrailing) {
                        Image(systemName: "bell")
                            .foregroundColor(Color(hex: 0xCBD5E1))

                        if notificationsVM.unreadCount > 0 {
                            Circle()
                                .fill(Theme.error)
                                .frame(width: 10, height: 10)
                                .overlay(
                                    Circle().stroke(Theme.background, lineWidth: 2)
                                )
                                .offset(x: 4, y: -4)
                        }
                    }
                }
            }
        }
        .safeAreaInset(edge: .top) {
            HStack {
                Text("Connected Devices (\(viewModel.devices.count))")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(Theme.textSecondary)

                Spacer()

                Button("Select All") {
                    viewModel.selectAll()
                }
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(Theme.primary)
            }
            .padding(.horizontal, Theme.spacingLG)
            .padding(.vertical, Theme.spacingMD)
            .background(Theme.background)
        }
        .navigationDestination(isPresented: $showWiFiConfig) {
            WiFiConfigView(selectedDevices: viewModel.selectedDevices)
        }
        .navigationDestination(isPresented: $showFirmware) {
            FirmwareView(selectedDevices: viewModel.selectedDevices)
        }
    }

    private var addDeviceButton: some View {
        NavigationLink(destination: ScannerView()) {
            HStack(spacing: Theme.spacingSM) {
                Image(systemName: "plus.circle")
                    .font(.system(size: 20))
                Text("Add New Device")
                    .font(.system(size: 16, weight: .medium))
            }
            .foregroundColor(Theme.textSecondary)
            .frame(maxWidth: .infinity)
            .frame(height: 60)
            .overlay(
                RoundedRectangle(cornerRadius: Theme.cornerRadiusMD)
                    .stroke(Color(hex: 0x334155), style: StrokeStyle(lineWidth: 2, dash: [8]))
            )
        }
    }

    private var addFloatingButton: some View {
        VStack {
            Spacer()
            HStack {
                Spacer()
                NavigationLink(destination: ScannerView()) {
                    Image(systemName: "plus")
                        .font(.system(size: 28))
                        .foregroundColor(.white)
                        .frame(width: 56, height: 56)
                        .background(Theme.primary)
                        .clipShape(Circle())
                        .shadow(color: Theme.primary.opacity(0.4), radius: 12)
                }
                .padding(.trailing, Theme.spacingLG)
                .padding(.bottom, viewModel.hasSelection ? 100 : 20)
            }
        }
    }
}

#Preview {
    NavigationStack {
        DashboardView(selectedTab: .constant(.dashboard))
    }
    .preferredColorScheme(.dark)
}
