import CoreImage
import Foundation

func testCIImageInitVariantsAndExtentArithmetic() {
    let infinite = CIImage(color: .red)
    precondition(infinite.extent.isInfinite)
    precondition(CIImage.empty().extent.isNull)
    precondition(CIImage.black.extent.isInfinite)
    precondition(CIImage.white.extent.isInfinite)
    precondition(CIImage.gray.extent.isInfinite)
    precondition(CIImage.clear.extent.isInfinite)

    let cropped = infinite.cropped(to: CGRect(x: 2, y: 3, width: 8, height: 5))
    precondition(cropped.extent.origin.x == 2)
    precondition(cropped.extent.origin.y == 3)
    precondition(cropped.extent.width == 8)
    precondition(cropped.extent.height == 5)

    let pixels: [UInt8] = [
        255, 0, 0, 255, 0, 255, 0, 255,
        0, 0, 255, 255, 255, 255, 0, 255,
    ]
    let bitmap = CIImage(
        bitmapData: Data(pixels),
        bytesPerRow: 8,
        size: CGSize(width: 2, height: 2),
        format: .RGBA8,
        colorSpace: .sRGB
    )
    precondition(bitmap.extent.width == 2)
    precondition(bitmap.extent.height == 2)
    let sample = ciTestPixel(bitmap, rect: CGRect(x: 0, y: 0, width: 1, height: 1))
    precondition(sample.0 == 255 && sample.1 == 0 && sample.2 == 0)

    let cg = CGImage(width: 3, height: 4, pixels: [UInt8](repeating: 128, count: 3 * 4 * 4))
    let fromCG = CIImage(cgImage: cg)
    precondition(fromCG.extent.width == 3 && fromCG.extent.height == 4)
    let fromCG2 = CIImage(CGImage: cg, options: [.colorSpace: CGColorSpace.sRGB])
    precondition(fromCG2.colorSpace?.name == "sRGB")
    precondition(CIImage(data: Data([0x00, 0x01])) == nil)
    precondition(CIImage(contentsOf: URL(fileURLWithPath: "/tmp/none.png")) == nil)
    precondition(CIImage(coder: NSCoder()) == nil)
}

func testCIImageCroppedTransformedComposited() {
    let red = CIImage(color: .red).cropped(to: CGRect(x: 0, y: 0, width: 2, height: 2))
    let blue = CIImage(color: .blue).cropped(to: CGRect(x: 1, y: 0, width: 2, height: 2))
    let unioned = red.composited(over: blue)
    precondition(unioned.extent.origin.x == 0)
    precondition(unioned.extent.width == 3)

    let translated = red.transformed(by: CGAffineTransform(translationX: 4, y: 5))
    precondition(translated.extent.origin.x == 4)
    precondition(translated.extent.origin.y == 5)
    precondition(translated.extent.width == 2)

    let rotated = CIImage(color: .blue)
        .cropped(to: CGRect(x: 0, y: 0, width: 4, height: 2))
        .transformed(by: CGAffineTransform(rotationAngle: CGFloat.pi / 2))
    // Affine of the axis-aligned 4×2 rect through +π/2 about the origin.
    precondition(abs(rotated.extent.origin.x - (-2)) < 0.001)
    precondition(abs(rotated.extent.origin.y - 0) < 0.001)
    precondition(abs(rotated.extent.width - 2) < 0.001)
    precondition(abs(rotated.extent.height - 4) < 0.001)

    let context = CIContext()
    guard let over = context.createCGImage(
        CIImage(color: .red).cropped(to: CGRect(x: 0, y: 0, width: 1, height: 1))
            .composited(over: CIImage(color: .blue).cropped(to: CGRect(x: 0, y: 0, width: 1, height: 1))),
        from: CGRect(x: 0, y: 0, width: 1, height: 1)
    ) else {
        preconditionFailure("composite raster")
    }
    // Source-over of opaque red on blue is red.
    precondition(over.pixels[0] == 255 && over.pixels[2] == 0 && over.pixels[3] == 255)

    let clamped = red.clamped(to: CGRect(x: 0, y: 0, width: 1, height: 1))
    precondition(clamped.extent.width == 1)
    precondition(red.clampedToExtent().extent.width == 2)
    _ = red.oriented(.up)
    _ = red.oriented(forExifOrientation: 1)
}

func testCIImageApplyingFilter() {
    let src = CIImage(color: .gray).cropped(to: CGRect(x: 0, y: 0, width: 1, height: 1))
    let exposed = src.applyingFilter("CIExposureAdjust", parameters: [kCIInputEVKey: Float(1)])
    let px = ciTestPixel(exposed)
    // Apple CIExposureAdjust: 0.5 * 2^1 = 1.0 → (255,255,255)
    precondition(px.0 == 255 && px.1 == 255 && px.2 == 255)
    let named = src.applyingFilter("CIExposureAdjust")
    precondition(named.extent.width == 1)
    let gain = src.applyingGainMap(src, headroom: 2)
    precondition(gain.contentHeadroom == 2)
}
