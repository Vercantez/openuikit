import Foundation
import ImageIO

func testSourceThumbnailMaxPixelSize() {
    // MEASURED 2026-09-05 Apple ImageIO on a 16×12 PNG (macOS 26.1):
    // maxPixel 8 → 8×6, 6 → 6×4, 17 → 16×12 (no upscale).
    // newDim = round-half-to-even(dim * maxPixel / max(w,h)), clamp ≥ 1.
    let png = imageioFixtureData("gradient-16x12.png")
    guard let source = CGImageSourceCreateWithData(png, nil) else { fatalError("src") }
    func thumb(_ maxPixel: Int) -> CGImage {
        let options: CFDictionary = [
            kCGImageSourceCreateThumbnailFromImageAlways: true,
            kCGImageSourceThumbnailMaxPixelSize: maxPixel,
        ]
        guard let image = CGImageSourceCreateThumbnailAtIndex(source, 0, options) else {
            fatalError("thumb \(maxPixel)")
        }
        return image
    }
    let t8 = thumb(8)
    imageioRequire(t8.width == 8 && t8.height == 6, "max 8")
    let t6 = thumb(6)
    imageioRequire(t6.width == 6 && t6.height == 4, "max 6")
    let t17 = thumb(17)
    imageioRequire(t17.width == 16 && t17.height == 12, "no upscale")
}

func testSourceThumbnailWithTransform() {
    // MEASURED 2026-09-05: JPEG orientation 6 + CreateThumbnailWithTransform
    // + max 8 on a 16×12 stored frame → 6×8 (rotate 90° CW after fit).
    let data = NSMutableData()
    guard let dest = CGImageDestinationCreateWithData(data, "public.jpeg", 1, nil) else {
        fatalError("jpeg dest")
    }
    CGImageDestinationAddImage(dest, imageioGradient16x12(), nil)
    imageioRequire(CGImageDestinationFinalize(dest), "finalize")
    let jpeg = imageioInsertExifOrientation(data as Data, orientation: 6)
    guard let source = CGImageSourceCreateWithData(jpeg, nil) else { fatalError("src") }
    imageioRequire(imageioInt(
        CGImageSourceCopyPropertiesAtIndex(source, 0, nil)?[kCGImagePropertyOrientation]
    ) == 6, "ori")
    let options: CFDictionary = [
        kCGImageSourceCreateThumbnailFromImageAlways: true,
        kCGImageSourceCreateThumbnailWithTransform: true,
        kCGImageSourceThumbnailMaxPixelSize: 8,
    ]
    guard let thumb = CGImageSourceCreateThumbnailAtIndex(source, 0, options) else {
        fatalError("thumb")
    }
    imageioRequire(thumb.width == 6 && thumb.height == 8, "rotated 6x8")
}

func imageioInsertExifOrientation(_ jpeg: Data, orientation: UInt16) -> Data {
    let bytes = Array(jpeg)
    imageioRequire(bytes.count >= 4 && bytes[0] == 0xff && bytes[1] == 0xd8, "soi")
    var tiff: [UInt8] = [0x49, 0x49, 0x2a, 0x00, 0x08, 0x00, 0x00, 0x00]
    tiff += [0x01, 0x00]
    tiff += [0x12, 0x01, 0x03, 0x00, 0x01, 0x00, 0x00, 0x00]
    tiff += [UInt8(orientation & 0xff), UInt8(orientation >> 8), 0x00, 0x00]
    tiff += [0x00, 0x00, 0x00, 0x00]
    var app1: [UInt8] = [0x45, 0x78, 0x69, 0x66, 0x00, 0x00]
    app1 += tiff
    let length = app1.count + 2
    var marker: [UInt8] = [0xff, 0xe1, UInt8((length >> 8) & 0xff), UInt8(length & 0xff)]
    marker += app1
    var out = Array(bytes[0..<2])
    out += marker
    out += Array(bytes[2...])
    return Data(out)
}

func testAnimatePNGStillInvokesOnce() {
    let data = imageioFixtureData("sample-2x1.png")
    var calls = 0
    let status = CGAnimateImageDataWithBlock(data, nil) { index, image, stop in
        calls += 1
        imageioRequire(index == 0, "index")
        imageioRequire(image.width == 2, "width")
        stop.pointee = true
    }
    imageioRequire(status == 0, "status")
    imageioRequire(calls == 1, "calls")
    let missing = URL(fileURLWithPath: "/tmp/imageio-missing-\(UUID().uuidString).png")
    let urlStatus = CGAnimateImageAtURLWithBlock(missing, nil) { _, _, _ in
        fatalError("must not run")
    }
    imageioRequire(urlStatus == CGImageAnimationStatus.parameterError.rawValue, "missing url")
}
