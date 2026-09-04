import Foundation

/// Deterministic CPU context. The original lane's linear-gradient rasterizer
/// is preserved: `createCGImage` samples `CIImage` at pixel centers and writes
/// RGBA8 into the module-local `CGImage` buffer.
public class CIContext: @unchecked Sendable {
    public let workingFormat: CIFormat
    public let workingColorSpace: CGColorSpace?
    private let options: [CIContextOption: Any]

    public init() {
        self.options = [:]
        self.workingFormat = .RGBA8
        self.workingColorSpace = .sRGB
    }

    public init(options: [CIContextOption: Any]? = nil) {
        self.options = options ?? [:]
        self.workingFormat = (options?[.workingFormat] as? CIFormat) ?? .RGBA8
        self.workingColorSpace = (options?[.workingColorSpace] as? CGColorSpace) ?? .sRGB
    }

    public func createCGImage(_ image: CIImage, from fromRect: CGRect) -> CGImage? {
        createCGImage(image, from: fromRect, format: .RGBA8, colorSpace: workingColorSpace)
    }

    public func createCGImage(
        _ image: CIImage,
        from fromRect: CGRect,
        format: CIFormat,
        colorSpace: CGColorSpace?
    ) -> CGImage? {
        _ = (format, colorSpace)
        return rasterize(image, from: fromRect)
    }

    public func createCGImage(
        _ image: CIImage,
        from fromRect: CGRect,
        format: CIFormat,
        colorSpace: CGColorSpace?,
        deferred: Bool
    ) -> CGImage? {
        _ = deferred
        return createCGImage(image, from: fromRect, format: format, colorSpace: colorSpace)
    }

    public func createCGImage(
        _ image: CIImage,
        from fromRect: CGRect,
        format: CIFormat,
        colorSpace: CGColorSpace?,
        deferred: Bool,
        calculateHDRStats: Bool
    ) -> CGImage? {
        _ = calculateHDRStats
        return createCGImage(
            image,
            from: fromRect,
            format: format,
            colorSpace: colorSpace,
            deferred: deferred
        )
    }

    public func render(
        _ image: CIImage,
        toBitmap data: UnsafeMutableRawPointer,
        rowBytes: Int,
        bounds: CGRect,
        format: CIFormat,
        colorSpace: CGColorSpace?
    ) {
        _ = (format, colorSpace)
        guard let bitmap = rasterize(image, from: bounds) else { return }
        let width = bitmap.width
        let height = bitmap.height
        for y in 0..<height {
            let dst = data.advanced(by: y * rowBytes)
            let srcOffset = y * width * 4
            let count = min(width * 4, rowBytes)
            if count > 0 {
                bitmap.pixels.withUnsafeBytes { raw in
                    guard let base = raw.baseAddress else { return }
                    dst.copyMemory(from: base.advanced(by: srcOffset), byteCount: count)
                }
            }
        }
    }

    public func draw(_ image: CIImage, in inRect: CGRect, from fromRect: CGRect) {
        _ = (image, inRect, fromRect)
    }

    public func clearCaches() {}

    public func inputImageMaximumSize() -> CGSize {
        CGSize(width: 8192, height: 8192)
    }

    public func outputImageMaximumSize() -> CGSize {
        CGSize(width: 8192, height: 8192)
    }

    public func jpegRepresentation(
        of image: CIImage,
        colorSpace: CGColorSpace,
        options: [CIImageRepresentationOption: Any] = [:]
    ) -> Data? {
        _ = (image, colorSpace, options)
        return nil
    }

    public func pngRepresentation(
        of image: CIImage,
        format: CIFormat,
        colorSpace: CGColorSpace,
        options: [CIImageRepresentationOption: Any] = [:]
    ) -> Data? {
        _ = (image, format, colorSpace, options)
        return nil
    }

    public func tiffRepresentation(
        of image: CIImage,
        format: CIFormat,
        colorSpace: CGColorSpace,
        options: [CIImageRepresentationOption: Any] = [:]
    ) -> Data? {
        _ = (image, format, colorSpace, options)
        return nil
    }

    public func heifRepresentation(
        of image: CIImage,
        format: CIFormat,
        colorSpace: CGColorSpace,
        options: [CIImageRepresentationOption: Any] = [:]
    ) -> Data? {
        _ = (image, format, colorSpace, options)
        return nil
    }

    public func heif10Representation(
        of image: CIImage,
        colorSpace: CGColorSpace,
        options: [CIImageRepresentationOption: Any] = [:]
    ) throws -> Data {
        _ = (image, colorSpace, options)
        throw CIRenderError.unsupported
    }

    public func openEXRRepresentation(
        of image: CIImage,
        options: [CIImageRepresentationOption: Any] = [:]
    ) throws -> Data {
        _ = (image, options)
        throw CIRenderError.unsupported
    }

    public func writeJPEGRepresentation(
        of image: CIImage,
        to url: URL,
        colorSpace: CGColorSpace,
        options: [CIImageRepresentationOption: Any] = [:]
    ) throws {
        _ = (image, url, colorSpace, options)
        throw CIRenderError.unsupported
    }

    public func writePNGRepresentation(
        of image: CIImage,
        to url: URL,
        format: CIFormat,
        colorSpace: CGColorSpace,
        options: [CIImageRepresentationOption: Any] = [:]
    ) throws {
        _ = (image, url, format, colorSpace, options)
        throw CIRenderError.unsupported
    }

    public func writeTIFFRepresentation(
        of image: CIImage,
        to url: URL,
        format: CIFormat,
        colorSpace: CGColorSpace,
        options: [CIImageRepresentationOption: Any] = [:]
    ) throws {
        _ = (image, url, format, colorSpace, options)
        throw CIRenderError.unsupported
    }

    public func writeHEIFRepresentation(
        of image: CIImage,
        to url: URL,
        format: CIFormat,
        colorSpace: CGColorSpace,
        options: [CIImageRepresentationOption: Any] = [:]
    ) throws {
        _ = (image, url, format, colorSpace, options)
        throw CIRenderError.unsupported
    }

    public func writeHEIF10Representation(
        of image: CIImage,
        to url: URL,
        colorSpace: CGColorSpace,
        options: [CIImageRepresentationOption: Any] = [:]
    ) throws {
        _ = (image, url, colorSpace, options)
        throw CIRenderError.unsupported
    }

    public func writeOpenEXRRepresentation(
        of image: CIImage,
        to url: URL,
        options: [CIImageRepresentationOption: Any] = [:]
    ) throws {
        _ = (image, url, options)
        throw CIRenderError.unsupported
    }

    public func depthBlurEffectFilter(
        for image: CIImage,
        disparityImage: CIImage,
        portraitEffectsMatte: CIImage?,
        orientation: CGImagePropertyOrientation,
        options: [AnyHashable: Any]? = nil
    ) -> CIFilter? {
        _ = (image, disparityImage, portraitEffectsMatte, orientation, options)
        return nil
    }

    public func depthBlurEffectFilter(
        for image: CIImage,
        disparityImage: CIImage,
        portraitEffectsMatte: CIImage?,
        hairSemanticSegmentation: CIImage?,
        orientation: CGImagePropertyOrientation,
        options: [AnyHashable: Any]? = nil
    ) -> CIFilter? {
        _ = hairSemanticSegmentation
        return depthBlurEffectFilter(
            for: image,
            disparityImage: disparityImage,
            portraitEffectsMatte: portraitEffectsMatte,
            orientation: orientation,
            options: options
        )
    }

    public func depthBlurEffectFilter(
        for image: CIImage,
        disparityImage: CIImage,
        portraitEffectsMatte: CIImage?,
        hairSemanticSegmentation: CIImage?,
        glassesMatte: CIImage?,
        gainMap: CIImage?,
        orientation: CGImagePropertyOrientation,
        options: [AnyHashable: Any]? = nil
    ) -> CIFilter? {
        _ = (glassesMatte, gainMap, hairSemanticSegmentation)
        return depthBlurEffectFilter(
            for: image,
            disparityImage: disparityImage,
            portraitEffectsMatte: portraitEffectsMatte,
            orientation: orientation,
            options: options
        )
    }

    public func depthBlurEffectFilter(
        forImageData data: Data,
        options: [AnyHashable: Any]? = nil
    ) -> CIFilter? {
        _ = (data, options)
        return nil
    }

    public func depthBlurEffectFilter(
        forImageURL url: URL,
        options: [AnyHashable: Any]? = nil
    ) -> CIFilter? {
        _ = (url, options)
        return nil
    }

    public func prepareRender(
        _ image: CIImage,
        from fromRect: CGRect,
        to destination: CIRenderDestination,
        at atPoint: CGPoint
    ) throws {
        _ = (image, fromRect, destination, atPoint)
        throw CIRenderError.unsupported
    }

    public func startTask(toClear destination: CIRenderDestination) throws -> CIRenderTask {
        _ = destination
        throw CIRenderError.unsupported
    }

    public func startTask(
        toRender image: CIImage,
        to destination: CIRenderDestination
    ) throws -> CIRenderTask {
        _ = (image, destination)
        throw CIRenderError.unsupported
    }

    public func startTask(
        toRender image: CIImage,
        from fromRect: CGRect,
        to destination: CIRenderDestination,
        at atPoint: CGPoint
    ) throws -> CIRenderTask {
        _ = (image, fromRect, destination, atPoint)
        throw CIRenderError.unsupported
    }

    public func calculateHDRStats(for image: CIImage) -> CIImage? {
        _ = image
        return nil
    }

    public func calculateHDRStats(for cgimage: CGImage) -> CGImage {
        cgimage
    }

    private func rasterize(_ image: CIImage, from rect: CGRect) -> CGImage? {
        let width = max(0, Int(rect.width.rounded(.up)))
        let height = max(0, Int(rect.height.rounded(.up)))
        let bitmap = CGImage(width: width, height: height)
        guard width > 0, height > 0 else { return bitmap }

        for y in 0..<height {
            for x in 0..<width {
                let point = CGPoint(
                    x: rect.origin.x + CGFloat(x) + 0.5,
                    y: rect.origin.y + CGFloat(y) + 0.5
                )
                let sample = image.sample(at: point)
                let offset = (y * width + x) * 4
                bitmap.pixels[offset] = ciByte(sample.0)
                bitmap.pixels[offset + 1] = ciByte(sample.1)
                bitmap.pixels[offset + 2] = ciByte(sample.2)
                bitmap.pixels[offset + 3] = ciByte(sample.3)
            }
        }
        return bitmap
    }
}
