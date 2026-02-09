import SwiftUI

struct RecordingsListSheet: View {
    let devices: [ProxyDevice]
    @StateObject private var viewModel = RecordingsListViewModel()
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                if viewModel.isLoading {
                    ProgressView()
                        .tint(.white.opacity(0.3))
                        .padding(.top, Theme.spacingXXL)
                } else if viewModel.recordings.isEmpty {
                    emptyState
                } else {
                    LazyVStack(spacing: Theme.spacingMD) {
                        ForEach(viewModel.recordings) { recording in
                            RecordingRow(recording: recording)
                        }
                    }
                    .padding(Theme.spacingLG)
                }
            }
            .background(Theme.background)
            .navigationTitle("Recordings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                        .foregroundColor(.white)
                }
            }
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
        .task {
            await viewModel.loadRecordings(for: devices)
        }
    }

    private var emptyState: some View {
        VStack(spacing: Theme.spacingMD) {
            Image(systemName: "film.stack")
                .font(.system(size: 40))
                .foregroundColor(Theme.textSecondary)

            Text("No Recordings")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.white)

            Text("Start capturing to create recordings")
                .font(.system(size: 14))
                .foregroundColor(Theme.textSecondary)
        }
        .padding(.top, Theme.spacingXXL)
    }
}

private struct RecordingRow: View {
    let recording: RecordingEntry

    var body: some View {
        HStack(spacing: Theme.spacingMD) {
            Image(systemName: "film")
                .font(.system(size: 20))
                .foregroundColor(Theme.primary)
                .frame(width: 40, height: 40)
                .background(Theme.primary.opacity(0.15))
                .clipShape(RoundedRectangle(cornerRadius: Theme.cornerRadiusSM))

            VStack(alignment: .leading, spacing: 2) {
                Text(String(recording.recording_id.prefix(8)) + "...")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.white)

                HStack(spacing: Theme.spacingSM) {
                    Label(recording.formattedDuration, systemImage: "clock")
                    Label("\(recording.frame_count) frames", systemImage: "photo.stack")
                }
                .font(.system(size: 11))
                .foregroundColor(Theme.textSecondary)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 4) {
                Text(recording.formattedSize)
                    .font(.system(size: 12, design: .monospaced))
                    .foregroundColor(Theme.textSecondary)

                if let url = ProxyAPIClient().recordingDownloadURL(
                    recordingId: recording.recording_id
                ) {
                    ShareLink(item: url) {
                        Image(systemName: "square.and.arrow.down")
                            .font(.system(size: 16))
                            .foregroundColor(Theme.primary)
                    }
                }
            }
        }
        .padding(Theme.spacingLG)
        .surfaceStyle()
    }
}
