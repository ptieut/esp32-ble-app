import Foundation

enum AutoExposure {
    static let targetLuminance: Float = 0.45
    static let centerWeightRadius: Float = 0.40
    static let centerWeight: Float = 0.60
    static let peripheryWeight: Float = 0.40
    static let smoothingFactor: Float = 0.15
    static let maxEV: Float = 2.0
    static let minEV: Float = -1.0
    static let analysisFrameInterval: Int = 5
    static let luminanceSampleStride: Int = 4
    static let brightnessRange: ClosedRange<Float> = -1.0...1.0

    static let analysisWidth: Int = 80
    static let analysisHeight: Int = 60
}
