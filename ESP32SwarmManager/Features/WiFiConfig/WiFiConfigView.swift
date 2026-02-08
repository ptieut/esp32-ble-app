import SwiftUI

struct WiFiConfigView: View {
    @StateObject private var viewModel: WiFiConfigViewModel
    @FocusState private var focusedField: Field?

    enum Field { case ssid, password }

    init(selectedDevices: [ConnectedDevice]) {
        _viewModel = StateObject(wrappedValue: WiFiConfigViewModel(selectedDevices: selectedDevices))
    }

    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(alignment: .leading, spacing: Theme.spacingXL) {
                    credentialSection
                    devicesSection
                }
                .padding(Theme.spacingLG)
                .padding(.bottom, 100)
            }

            pushButton
        }
        .background(Theme.background)
        .navigationTitle("Wi-Fi Configuration")
        .navigationBarTitleDisplayMode(.inline)
    }

    // MARK: - Credentials

    private var credentialSection: some View {
        VStack(alignment: .leading, spacing: Theme.spacingXL) {
            Text("Credential Input Group")
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(.white)

            VStack(alignment: .leading, spacing: Theme.spacingSM) {
                Text("Network Name (SSID)")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(Color(hex: 0xCBD5E1))

                HStack {
                    TextField("Enter SSID", text: $viewModel.ssid)
                        .textContentType(.none)
                        .autocorrectionDisabled()
                        .textInputAutocapitalization(.never)
                        .foregroundColor(.white)
                        .focused($focusedField, equals: .ssid)

                    Image(systemName: "wifi")
                        .foregroundColor(Theme.textSecondary)
                }
                .inputStyle(isFocused: focusedField == .ssid)

                Text("Case sensitive")
                    .font(.system(size: 12))
                    .foregroundColor(Color(hex: 0x64748B))
                    .padding(.horizontal, 4)
            }

            VStack(alignment: .leading, spacing: Theme.spacingSM) {
                Text("Password")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(Color(hex: 0xCBD5E1))

                HStack {
                    Group {
                        if viewModel.isPasswordVisible {
                            TextField("Enter Password", text: $viewModel.password)
                        } else {
                            SecureField("Enter Password", text: $viewModel.password)
                        }
                    }
                    .foregroundColor(.white)
                    .focused($focusedField, equals: .password)

                    Button {
                        viewModel.isPasswordVisible.toggle()
                    } label: {
                        Image(systemName: viewModel.isPasswordVisible ? "eye" : "eye.slash")
                            .foregroundColor(Theme.textSecondary)
                    }
                }
                .inputStyle(isFocused: focusedField == .password)
            }
        }
    }

    // MARK: - Devices

    private var devicesSection: some View {
        VStack(alignment: .leading, spacing: Theme.spacingLG) {
            HStack {
                Text("Selected Devices")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.white)

                Spacer()

                Text("\(viewModel.activeDeviceCount) Active")
                    .font(.system(size: 12, weight: .semibold))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(Theme.primary.opacity(0.2))
                    .foregroundColor(Theme.primary)
                    .clipShape(Capsule())
            }

            VStack(spacing: Theme.spacingMD) {
                ForEach(viewModel.selectedDevices) { device in
                    DeviceWiFiStatusRow(
                        device: device,
                        pushStatus: viewModel.statusFor(deviceId: device.id)
                    )
                }
            }
        }
    }

    // MARK: - Push Button

    private var pushButton: some View {
        VStack(spacing: 0) {
            Divider()
                .background(Color.white.opacity(0.05))

            Button(action: viewModel.pushToDevices) {
                HStack(spacing: Theme.spacingSM) {
                    if viewModel.isPushing {
                        ProgressView()
                            .tint(.white)
                    } else {
                        Image(systemName: "arrow.up.circle")
                            .font(.system(size: 18))
                    }

                    Text(viewModel.isPushing ? "Pushing..." : "Push to Devices")
                        .font(.system(size: 16, weight: .semibold))
                }
                .frame(maxWidth: .infinity)
                .frame(height: 52)
                .background(viewModel.canPush ? Theme.primary : Theme.primary.opacity(0.5))
                .foregroundColor(.white)
                .clipShape(RoundedRectangle(cornerRadius: Theme.cornerRadiusSM))
                .shadow(color: Theme.primary.opacity(0.2), radius: 8)
            }
            .disabled(!viewModel.canPush)
            .padding(Theme.spacingLG)
            .background(Theme.background.opacity(0.9))
        }
    }
}

#Preview {
    NavigationStack {
        WiFiConfigView(selectedDevices: PreviewData.connectedDevices)
    }
    .preferredColorScheme(.dark)
}
