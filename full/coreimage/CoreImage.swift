@_exported import OpenCoreGraphics

/// Core Image output uses OpenCoreGraphics' existing RGBA8 storage.  The
/// alias keeps image identity shared with UIKit instead of introducing a
/// second pixel-buffer hierarchy at the framework boundary.
public typealias CGImage = OpenCoreGraphics.Bitmap

public struct CIColor: Equatable, Sendable {
    public var red: CGFloat
    public var green: CGFloat
    public var blue: CGFloat
    public var alpha: CGFloat

    public init(
        red: CGFloat,
        green: CGFloat,
        blue: CGFloat,
        alpha: CGFloat
    ) {
        self.red = red
        self.green = green
        self.blue = blue
        self.alpha = alpha
    }

    public static let black = CIColor(red: 0, green: 0, blue: 0, alpha: 1)
    public static let clear = CIColor(red: 0, green: 0, blue: 0, alpha: 0)
}

public struct CIImage: Sendable {
    fileprivate let color0: CIColor
    fileprivate let color1: CIColor
    fileprivate let point0: CGPoint
    fileprivate let point1: CGPoint
}

/// Generated `CILinearGradient` filter surface exported through the
/// `CoreImage.CIFilterBuiltins` Clang submodule.
public final class CILinearGradient: @unchecked Sendable {
    public var color0: CIColor = .black
    public var color1: CIColor = .clear
    public var point0: CGPoint = .zero
    public var point1 = CGPoint(x: 0, y: 1)

    public init() {}

    public var outputImage: CIImage? {
        CIImage(
            color0: color0,
            color1: color1,
            point0: point0,
            point1: point1
        )
    }
}

public enum CIFilter {
    public static func linearGradient() -> CILinearGradient {
        CILinearGradient()
    }

    public static func smoothLinearGradient() -> CILinearGradient {
        CILinearGradient()
    }
}

/// Deterministic CPU context for the first generated-filter slice.
public final class CIContext: @unchecked Sendable {
    public init() {}

    public func createCGImage(_ image: CIImage, from rect: CGRect) -> CGImage? {
        let width = Swift.max(0, Int(rect.width.rounded(.up)))
        let height = Swift.max(0, Int(rect.height.rounded(.up)))
        let bitmap = Bitmap(width: width, height: height)
        guard width > 0, height > 0 else { return bitmap }

        let dx = image.point1.x - image.point0.x
        let dy = image.point1.y - image.point0.y
        let denominator = dx * dx + dy * dy

        for y in 0..<height {
            for x in 0..<width {
                let point = CGPoint(
                    x: rect.origin.x + CGFloat(x) + 0.5,
                    y: rect.origin.y + CGFloat(y) + 0.5
                )
                let raw: CGFloat
                if denominator == 0 {
                    raw = 0
                } else {
                    raw = (
                        (point.x - image.point0.x) * dx
                            + (point.y - image.point0.y) * dy
                    ) / denominator
                }
                let t = Swift.max(0, Swift.min(1, raw))
                let inverse = 1 - t
                let offset = (y * width + x) * 4
                bitmap.pixels[offset] = Self.byte(
                    image.color0.red * inverse + image.color1.red * t
                )
                bitmap.pixels[offset + 1] = Self.byte(
                    image.color0.green * inverse + image.color1.green * t
                )
                bitmap.pixels[offset + 2] = Self.byte(
                    image.color0.blue * inverse + image.color1.blue * t
                )
                bitmap.pixels[offset + 3] = Self.byte(
                    image.color0.alpha * inverse + image.color1.alpha * t
                )
            }
        }
        return bitmap
    }

    private static func byte(_ component: CGFloat) -> UInt8 {
        UInt8(Swift.max(0, Swift.min(255, (component * 255).rounded())))
    }
}
