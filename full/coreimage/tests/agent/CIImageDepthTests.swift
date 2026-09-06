import CoreImage
import Foundation

func testCIImagePremultiplyUnpremultiplyAlpha() {
    let src = CIImage(color: CIColor(red: 1, green: 0, blue: 0, alpha: 0.5))
        .cropped(to: CGRect(x: 0, y: 0, width: 1, height: 1))
    let premul = src.premultiplyingAlpha()
    let px = ciTestPixel(premul)
    precondition(px.0 == 128 && px.1 == 0 && px.2 == 0 && px.3 == 128)
    let roundTrip = premul.unpremultiplyingAlpha()
    let restored = ciTestPixel(roundTrip)
    precondition(restored.0 == 255 && restored.1 == 0 && restored.2 == 0 && restored.3 == 128)
}

func testCIImageSettingAlphaOneAndOpaque() {
    let translucent = CIImage(color: CIColor(red: 0, green: 1, blue: 0, alpha: 0.25))
        .cropped(to: CGRect(x: 0, y: 0, width: 1, height: 1))
    precondition(!translucent.isOpaque)
    let opaque = translucent.settingAlphaOne(in: translucent.extent)
    precondition(opaque.isOpaque)
    let px = ciTestPixel(opaque)
    precondition(px.0 == 0 && px.1 == 255 && px.2 == 0 && px.3 == 255)
    precondition(CIImage(color: .red).isOpaque)
}

func testCIImageSamplingNearestVersusLinear() {
    let pixels: [UInt8] = [
        255, 0, 0, 255,
        0, 0, 255, 255,
    ]
    let bitmap = CIImage(
        bitmapData: Data(pixels),
        bytesPerRow: 8,
        size: CGSize(width: 2, height: 1),
        format: .RGBA8,
        colorSpace: .sRGB
    )
    let nearest = bitmap.samplingNearest()
    let linear = bitmap.samplingLinear()
    let left = ciTestPixel(nearest, rect: CGRect(x: 0, y: 0, width: 1, height: 1))
    precondition(left.0 == 255 && left.2 == 0)
    let rightNearest = ciTestPixel(nearest, rect: CGRect(x: 1, y: 0, width: 1, height: 1))
    precondition(rightNearest.0 == 0 && rightNearest.2 == 255)
    let midLinear = ciTestPixel(linear, rect: CGRect(x: 0.5, y: 0, width: 1, height: 1))
    precondition(midLinear.0 > 40 && midLinear.0 < 220)
    precondition(midLinear.2 > 40 && midLinear.2 < 220)
}

func testCIImageLabRoundTripAndColorMatch() {
    let white = CIImage(color: .white).cropped(to: CGRect(x: 0, y: 0, width: 1, height: 1))
    let lab = white.convertingWorkingSpaceToLab()
    let labPx = ciTestPixel(lab)
    precondition(labPx.0 == 255)
    precondition(abs(Int(labPx.1) - 128) <= 1)
    precondition(abs(Int(labPx.2) - 128) <= 1)
    let back = lab.convertingLabToWorkingSpace()
    let backPx = ciTestPixel(back)
    precondition(backPx.0 >= 250 && backPx.1 >= 250 && backPx.2 >= 250)

    let gray = CIImage(color: .gray).cropped(to: CGRect(x: 0, y: 0, width: 1, height: 1))
    guard let toLinear = gray.matchedFromWorkingSpace(to: .genericRGBLinear) else {
        preconditionFailure("matchedFromWorkingSpace")
    }
    let linPx = ciTestPixel(toLinear)
    precondition(linPx.0 < 90)
    guard let identity = gray.matchedToWorkingSpace(from: .sRGB) else {
        preconditionFailure("matchedToWorkingSpace")
    }
    let idPx = ciTestPixel(identity)
    precondition(idPx.0 == 128)
}

func testCIImageOrientationTransforms() {
    let down = CIImage.empty().orientationTransform(for: .down)
    precondition(down.a == -1 && down.d == -1 && down.tx == 0)
    let exif1 = CIImage.empty().orientationTransform(forExifOrientation: 1)
    precondition(exif1.a == 1 && exif1.d == 1)
    let exif3 = CIImage.empty().orientationTransform(forExifOrientation: 3)
    precondition(exif3.a == -1 && exif3.d == -1)
    let mirrored = CIImage.empty().orientationTransform(for: .upMirrored)
    precondition(mirrored.a == -1 && mirrored.d == 1)
}

func testCIImageInsertIntermediateGainMapAndTransformQuality() {
    let src = CIImage(color: .blue).cropped(to: CGRect(x: 0, y: 0, width: 2, height: 2))
    let cached = src.insertingIntermediate()
    precondition(ciTestPixel(cached).2 == 255)
    let cachedFlag = src.insertingIntermediate(cache: true)
    precondition(cachedFlag.extent.width == 2)
    let tiled = src.insertingTiledIntermediate()
    precondition(tiled.extent.height == 2)
    let gain = src.applyingGainMap(src)
    precondition(gain.extent.width == src.extent.width)
    precondition(gain.extent.height == src.extent.height)
    precondition(ciTestPixel(gain).2 == 255)
    let hq = src.transformed(
        by: CGAffineTransform(translationX: 3, y: 0),
        highQualityDownsample: true
    )
    precondition(hq.extent.origin.x == 3)
    precondition(hq.extent.width == 2)
}

func testCIImageAutoAdjustProviderTextureURLAndROI() {
    let src = CIImage(color: .red).cropped(to: CGRect(x: 0, y: 0, width: 2, height: 2))
    precondition(src.autoAdjustmentFilters().isEmpty)
    precondition(src.autoAdjustmentFilters(options: [.enhance: true]).isEmpty)

    let provider = NSObject()
    let provided = CIImage(
        imageProvider: provider,
        size: 2,
        2,
        format: .RGBA8,
        colorSpace: .sRGB,
        options: [.providerUserInfo: "tile"]
    )
    precondition(provided.extent.width == 2 && provided.extent.height == 2)
    let black = ciTestPixel(provided)
    precondition(black.0 == 0 && black.1 == 0 && black.2 == 0)

    let texture = CIImage(texture: 12, size: CGSize(width: 4, height: 3), flipped: true, colorSpace: .sRGB)
    precondition(texture.extent.width == 4 && texture.extent.height == 3)

    let roi = src.regionOfInterest(for: src, in: CGRect(x: 1, y: 1, width: 1, height: 1))
    precondition(roi.origin.x == 1 && roi.width == 1)

    let lit = src.settingContentAverageLightLevel(0.4)
    precondition(lit.contentAverageLightLevel == 0.4)
    let props = src.settingProperties(["Make": "OpenUIKit"])
    precondition(props.properties["Make"] as? String == "OpenUIKit")

    let context = CIContext()
    let url = FileManager.default.temporaryDirectory.appendingPathComponent("fw-ci-url.png")
    try! context.writePNGRepresentation(of: src, to: url, format: .RGBA8, colorSpace: .sRGB)
    guard let loaded = CIImage(contentsOfURL: url, options: [.colorSpace: CGColorSpace.sRGB]) else {
        preconditionFailure("contentsOfURL options")
    }
    precondition(loaded.url == url)
    precondition(loaded.extent.width == 2)
    precondition(CIImage(contentsOfURL: URL(fileURLWithPath: "/tmp/missing-coreimage.png"), options: nil) == nil)
}
