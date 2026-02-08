import Foundation

@MainActor
final class SwarmViewModel: ObservableObject {
    @Published var cameraTiles: [PreviewData.CameraTile] = PreviewData.cameraTiles
    @Published var isCapturing = false

    func toggleCapture() {
        isCapturing.toggle()
    }
}
