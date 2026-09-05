import Foundation
import OpenCoreGraphics
#if canImport(OpenUIKitImageIO)
import OpenUIKitImageIO
#else
import ImageIO
#endif
#if canImport(CoreGraphics)
import class CoreGraphics.CGImage
#endif

public class CIContext: NSObject, @unchecked Sendable {
    public let workingFormat: CIFormat
    private let options: [CIContextOption: Any]

    public override init() {
        self.options = [:]
        self.workingFormat = .RGBA8
        super.init()
    }

    public init(options: [CIContextOption: Any]?) {
        self.options = options ?? [:]
        self.workingFormat = (options?[.workingFormat] as? CIFormat) ?? .RGBA8
        super.init()
    }

    public func createCGImage(_ image: CIImage, from fromRect: CGRect) -> CGImage? {
        guard let bitmap = image.rasterize(from: fromRect) else { return nil }
        return ciMakeCGImage(bitmap)
    }

    public func render(
        _ image: CIImage,
        toBitmap data: UnsafeMutableRawPointer,
        rowBytes: Int,
        bounds: CGRect,
        format: CIFormat,
        colorSpace: Any?
    ) {
        _ = (format, colorSpace)
        guard let bitmap = image.rasterize(from: bounds) else { return }
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
}
