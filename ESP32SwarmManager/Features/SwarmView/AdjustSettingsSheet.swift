import SwiftUI

struct AdjustSettingsSheet: View {
    @ObservedObject var settings: StreamSettings
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: Theme.spacingLG) {
                    brightnessSection
                    overlaySection
                    exposureSection
                }
                .padding(Theme.spacingLG)
            }
            .background(Theme.background)
            .navigationTitle("Stream Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Reset") {
                        settings.brightnessOffset = 0.0
                        settings.skeletonOverlayEnabled = false
                        settings.autoExposureEnabled = true
                    }
                    .foregroundColor(Theme.textSecondary)
                }

                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                        .foregroundColor(.white)
                }
            }
        }
        .presentationDetents([.medium])
        .presentationDragIndicator(.visible)
    }

    private var brightnessSection: some View {
        VStack(alignment: .leading, spacing: Theme.spacingSM) {
            HStack {
                Image(systemName: "sun.max")
                    .foregroundColor(Theme.textSecondary)
                Text("Brightness")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.white)

                Spacer()

                Text(brightnessLabel)
                    .font(.system(size: 12, design: .monospaced))
                    .foregroundColor(Theme.textSecondary)
            }

            Slider(
                value: $settings.brightnessOffset,
                in: AutoExposure.brightnessRange
            )
            .tint(Theme.primary)
        }
        .padding(Theme.spacingLG)
        .surfaceStyle()
    }

    private var overlaySection: some View {
        HStack {
            Image(systemName: "figure.stand")
                .foregroundColor(Theme.textSecondary)
            Text("Skeleton Overlay")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.white)

            Spacer()

            Toggle("", isOn: $settings.skeletonOverlayEnabled)
                .labelsHidden()
                .tint(Theme.primary)
        }
        .padding(Theme.spacingLG)
        .surfaceStyle()
    }

    private var exposureSection: some View {
        HStack {
            Image(systemName: "camera.aperture")
                .foregroundColor(Theme.textSecondary)
            Text("Auto Exposure")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.white)

            Spacer()

            Toggle("", isOn: $settings.autoExposureEnabled)
                .labelsHidden()
                .tint(Theme.primary)
        }
        .padding(Theme.spacingLG)
        .surfaceStyle()
    }

    private var brightnessLabel: String {
        let value = settings.brightnessOffset
        if abs(value) < 0.01 { return "0.0" }
        return String(format: "%+.1f", value)
    }
}

#Preview {
    AdjustSettingsSheet(settings: StreamSettings.shared)
        .preferredColorScheme(.dark)
}
