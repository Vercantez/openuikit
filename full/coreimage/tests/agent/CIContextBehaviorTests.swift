import CoreImage
import Foundation

func testCIContextWorkingSpaceCreateCGImage() {
    let context = CIContext(options: [
        .workingColorSpace: CGColorSpace.sRGB,
        .workingFormat: CIFormat.RGBA8,
        .useSoftwareRenderer: true,
    ])
    precondition(context.workingColorSpace?.name == "sRGB")
    precondition(context.workingFormat == .RGBA8)

    let image = CIImage(color: CIColor(red: 1, green: 0, blue: 0, alpha: 1))
    let rect = CGRect(x: 0, y: 0, width: 2, height: 2)
    guard let bitmap = context.createCGImage(image, from: rect) else {
        preconditionFailure("createCGImage")
    }
    precondition(bitmap.width == 2 && bitmap.height == 2)
    // Working-space rule: unpremultiplied RGBA8 of the sRGB sample.
    precondition(bitmap.pixels[0] == 255)
    precondition(bitmap.pixels[1] == 0)
    precondition(bitmap.pixels[2] == 0)
    precondition(bitmap.pixels[3] == 255)

    guard let formatted = context.createCGImage(image, from: rect, format: .RGBA8, colorSpace: .sRGB) else {
        preconditionFailure("createCGImage format")
    }
    precondition(formatted.pixels[0] == 255)
    guard let deferred = context.createCGImage(
        image, from: rect, format: .RGBA8, colorSpace: .sRGB, deferred: false
    ) else {
        preconditionFailure("deferred")
    }
    precondition(deferred.width == 2)
    guard let hdr = context.createCGImage(
        image, from: rect, format: .RGBA8, colorSpace: .sRGB, deferred: false, calculateHDRStats: false
    ) else {
        preconditionFailure("hdr flag")
    }
    precondition(hdr.height == 2)
    context.clearCaches()
    precondition(context.inputImageMaximumSize().width == 8192)
    precondition(context.outputImageMaximumSize().height == 8192)
}

func testCIContextPNGAndJPEGRepresentation() {
    let context = CIContext(options: [.workingColorSpace: CGColorSpace.sRGB])
    let patch = CIImage(color: .red).cropped(to: CGRect(x: 0, y: 0, width: 2, height: 2))
    guard let png = context.pngRepresentation(of: patch, format: .RGBA8, colorSpace: .sRGB) else {
        preconditionFailure("pngRepresentation")
    }
    let pngBytes = [UInt8](png)
    precondition(pngBytes.count >= 8)
    precondition(pngBytes[0] == 0x89 && pngBytes[1] == 0x50 && pngBytes[2] == 0x4E && pngBytes[3] == 0x47)
    guard let decoded = CIImage(data: png) else {
        preconditionFailure("png decode")
    }
    precondition(decoded.extent.width == 2)
    let px = ciTestPixel(decoded)
    precondition(px.0 == 255 && px.1 == 0 && px.2 == 0 && px.3 == 255)

    let url = FileManager.default.temporaryDirectory.appendingPathComponent("fw-coreimage2.png")
    try! context.writePNGRepresentation(of: patch, to: url, format: .RGBA8, colorSpace: .sRGB)
    guard let fromURL = CIImage(contentsOf: url) else {
        preconditionFailure("contentsOf png")
    }
    precondition(fromURL.extent.height == 2)

    guard let jpeg = context.jpegRepresentation(of: patch, colorSpace: .sRGB) else {
        preconditionFailure("jpegRepresentation")
    }
    let jpegBytes = [UInt8](jpeg)
    precondition(jpegBytes.count >= 2 && jpegBytes[0] == 0xFF && jpegBytes[1] == 0xD8)
    let jpegURL = url.appendingPathExtension("jpg")
    try! context.writeJPEGRepresentation(of: patch, to: jpegURL, colorSpace: .sRGB)
    precondition(FileManager.default.fileExists(atPath: jpegURL.path))

    precondition(context.tiffRepresentation(of: patch, format: .RGBA8, colorSpace: .sRGB) == nil)
    precondition(context.heifRepresentation(of: patch, format: .RGBA8, colorSpace: .sRGB) == nil)
    do {
        _ = try context.heif10Representation(of: patch, colorSpace: .sRGB)
        preconditionFailure("heif10")
    } catch {
        precondition((error as? CIRenderError) == .unsupported)
    }
    do {
        _ = try context.openEXRRepresentation(of: patch)
        preconditionFailure("exr")
    } catch {
        precondition((error as? CIRenderError) == .unsupported)
    }
}

func testCIContextFailClosedDepthAndTasks() {
    let context = CIContext()
    let color = CIImage(color: .red).cropped(to: CGRect(x: 0, y: 0, width: 2, height: 2))
    context.draw(color, in: color.extent, from: color.extent)
    precondition(context.calculateHDRStats(for: color) == nil)
    _ = context.calculateHDRStats(for: CGImage(width: 1, height: 1))
    precondition(
        context.depthBlurEffectFilter(
            for: color, disparityImage: color, portraitEffectsMatte: nil, orientation: .up
        ) == nil
    )
    precondition(
        context.depthBlurEffectFilter(
            for: color, disparityImage: color, portraitEffectsMatte: nil,
            hairSemanticSegmentation: nil, orientation: .up
        ) == nil
    )
    precondition(
        context.depthBlurEffectFilter(
            for: color, disparityImage: color, portraitEffectsMatte: nil,
            hairSemanticSegmentation: nil, glassesMatte: nil, gainMap: nil, orientation: .up
        ) == nil
    )
    precondition(context.depthBlurEffectFilter(forImageData: Data(), options: nil) == nil)
    precondition(
        context.depthBlurEffectFilter(forImageURL: URL(fileURLWithPath: "/tmp/none.png"), options: nil) == nil
    )

    var storage = [UInt8](repeating: 0, count: 16)
    storage.withUnsafeMutableBytes { raw in
        let dest = CIRenderDestination(
            bitmapData: raw.baseAddress!,
            width: 2,
            height: 2,
            bytesPerRow: 8,
            format: .RGBA8
        )
        do {
            try context.prepareRender(color, from: color.extent, to: dest, at: .zero)
            preconditionFailure("prepare")
        } catch {
            precondition((error as? CIRenderError) == .unsupported)
        }
        do {
            _ = try context.startTask(toClear: dest)
            preconditionFailure("clear")
        } catch {
            precondition((error as? CIRenderError) == .unsupported)
        }
        do {
            _ = try context.startTask(toRender: color, to: dest)
            preconditionFailure("render")
        } catch {
            precondition((error as? CIRenderError) == .unsupported)
        }
        do {
            _ = try context.startTask(toRender: color, from: color.extent, to: dest, at: .zero)
            preconditionFailure("render2")
        } catch {
            precondition((error as? CIRenderError) == .unsupported)
        }
    }
}
