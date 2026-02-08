import CoreImage
import UIKit

final class FrameProcessor {
    private static let sharedContext: CIContext = {
        if let device = MTLCreateSystemDefaultDevice() {
            return CIContext(mtlDevice: device, options: [.workingColorSpace: NSNull()])
        }
        return CIContext(options: [.workingColorSpace: NSNull()])
    }()

    private let ciContext = FrameProcessor.sharedContext
    private var currentEV: Float = 0.0
    private var frameCount: Int = 0

    func processFrame(jpegData: Data, brightnessOffset: Float, autoExposureEnabled: Bool) -> UIImage? {
        guard let ciImage = CIImage(data: jpegData) else { return nil }

        frameCount += 1

        if autoExposureEnabled && frameCount % AutoExposure.analysisFrameInterval == 0 {
            let measured = analyzeLuminance(image: ciImage)
            let targetEV = computeTargetEV(measuredLuminance: measured)
            currentEV = smoothEV(target: targetEV)
        }

        let totalEV: Float
        if autoExposureEnabled {
            totalEV = currentEV + brightnessOffset
        } else {
            totalEV = brightnessOffset
        }

        guard abs(totalEV) > 0.01 else {
            return renderToUIImage(ciImage: ciImage)
        }

        let adjusted = applyExposure(to: ciImage, ev: totalEV)
        return renderToUIImage(ciImage: adjusted)
    }

    func reset() {
        currentEV = 0.0
        frameCount = 0
    }

    // MARK: - Luminance Analysis

    private func analyzeLuminance(image: CIImage) -> Float {
        let width = AutoExposure.analysisWidth
        let height = AutoExposure.analysisHeight
        let bytesPerPixel = 4
        let bytesPerRow = width * bytesPerPixel
        var pixelData = [UInt8](repeating: 0, count: height * bytesPerRow)

        let targetRect = CGRect(x: 0, y: 0, width: width, height: height)
        let scaleX = CGFloat(width) / image.extent.width
        let scaleY = CGFloat(height) / image.extent.height
        let scaled = image.transformed(by: CGAffineTransform(scaleX: scaleX, y: scaleY))

        ciContext.render(
            scaled,
            toBitmap: &pixelData,
            rowBytes: bytesPerRow,
            bounds: targetRect,
            format: .RGBA8,
            colorSpace: CGColorSpaceCreateDeviceRGB()
        )

        let centerX = Float(width) / 2.0
        let centerY = Float(height) / 2.0
        let maxDist = sqrt(centerX * centerX + centerY * centerY)
        let radiusThreshold = AutoExposure.centerWeightRadius * maxDist

        var weightedSum: Float = 0
        var totalWeight: Float = 0
        let stride = AutoExposure.luminanceSampleStride

        for y in Swift.stride(from: 0, to: height, by: stride) {
            for x in Swift.stride(from: 0, to: width, by: stride) {
                let offset = y * bytesPerRow + x * bytesPerPixel
                let r = Float(pixelData[offset]) / 255.0
                let g = Float(pixelData[offset + 1]) / 255.0
                let b = Float(pixelData[offset + 2]) / 255.0

                let luminance = 0.299 * r + 0.587 * g + 0.114 * b

                let dx = Float(x) - centerX
                let dy = Float(y) - centerY
                let dist = sqrt(dx * dx + dy * dy)

                let weight = dist < radiusThreshold
                    ? AutoExposure.centerWeight
                    : AutoExposure.peripheryWeight

                weightedSum += luminance * weight
                totalWeight += weight
            }
        }

        guard totalWeight > 0 else { return AutoExposure.targetLuminance }
        return weightedSum / totalWeight
    }

    // MARK: - EV Computation

    private func computeTargetEV(measuredLuminance: Float) -> Float {
        let clamped = max(measuredLuminance, 0.001)
        let ev = log2(AutoExposure.targetLuminance / clamped)
        return min(max(ev, AutoExposure.minEV), AutoExposure.maxEV)
    }

    private func smoothEV(target: Float) -> Float {
        let alpha = AutoExposure.smoothingFactor
        return currentEV + alpha * (target - currentEV)
    }

    // MARK: - CIFilter Application

    private func applyExposure(to image: CIImage, ev: Float) -> CIImage {
        guard let filter = CIFilter(name: "CIExposureAdjust") else { return image }
        filter.setValue(image, forKey: kCIInputImageKey)
        filter.setValue(ev, forKey: kCIInputEVKey)
        return filter.outputImage ?? image
    }

    // MARK: - Rendering

    private func renderToUIImage(ciImage: CIImage) -> UIImage? {
        guard let cgImage = ciContext.createCGImage(ciImage, from: ciImage.extent) else {
            return nil
        }
        return UIImage(cgImage: cgImage)
    }
}
