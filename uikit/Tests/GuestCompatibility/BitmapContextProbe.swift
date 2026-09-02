// Compile this external client through the portable `CoreGraphics` facade.
// It preserves the exact first-party spelling used by AVFoundation consumers
// and proves that the aliases expose a real bitmap context/image path.
import CoreGraphics

public func makeOnePixelBitmapContextImage() -> CGImage {
    let colorSpace = CGColorSpaceCreateDeviceRGB()
    let context = CGContext(
        data: nil,
        width: 1,
        height: 1,
        bitsPerComponent: 8,
        bytesPerRow: 4,
        space: colorSpace,
        bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
    )!
    return context.makeImage()!
}
