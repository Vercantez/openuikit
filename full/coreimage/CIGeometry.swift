import Foundation

/// Module-local CoreGraphics lookalike for the isolated Linux host gate.
/// The clean EC2 integration build uses the real CoreGraphics types; this
/// type exists so `CIImage` / `CIContext` rasterization can compile without
/// inventing a second public CoreGraphics module.
public final class CGImage: @unchecked Sendable {
    public let width: Int
    public let height: Int
    public var pixels: [UInt8]

    public init(width: Int, height: Int, pixels: [UInt8]? = nil) {
        self.width = max(0, width)
        self.height = max(0, height)
        let count = self.width * self.height * 4
        if let pixels, pixels.count >= count {
            self.pixels = Array(pixels.prefix(count))
        } else {
            self.pixels = [UInt8](repeating: 0, count: count)
        }
    }
}

/// Module-local color-space token. Isolated Linux has no ColorSync profiles.
public final class CGColorSpace: @unchecked Sendable {
    public let name: String

    public init(name: String) {
        self.name = name
    }

    public static let sRGB = CGColorSpace(name: "sRGB")
    public static let genericRGBLinear = CGColorSpace(name: "genericRGBLinear")
}

/// Module-local CGColor lookalike used by `CIColor` initializers.
public final class CGColor: @unchecked Sendable {
    public let red: CGFloat
    public let green: CGFloat
    public let blue: CGFloat
    public let alpha: CGFloat
    public let colorSpace: CGColorSpace

    public init(
        red: CGFloat,
        green: CGFloat,
        blue: CGFloat,
        alpha: CGFloat = 1,
        colorSpace: CGColorSpace = .sRGB
    ) {
        self.red = red
        self.green = green
        self.blue = blue
        self.alpha = alpha
        self.colorSpace = colorSpace
    }
}

/// Affine transform with the documented CoreGraphics 3x2 layout.
/// Isolated Linux Foundation does not ship `CGAffineTransform`.
public struct CGAffineTransform: Equatable, Sendable {
    public var a: CGFloat
    public var b: CGFloat
    public var c: CGFloat
    public var d: CGFloat
    public var tx: CGFloat
    public var ty: CGFloat

    public init(
        a: CGFloat,
        b: CGFloat,
        c: CGFloat,
        d: CGFloat,
        tx: CGFloat,
        ty: CGFloat
    ) {
        self.a = a
        self.b = b
        self.c = c
        self.d = d
        self.tx = tx
        self.ty = ty
    }

    public static let identity = CGAffineTransform(a: 1, b: 0, c: 0, d: 1, tx: 0, ty: 0)

    public init(translationX tx: CGFloat, y ty: CGFloat) {
        self.init(a: 1, b: 0, c: 0, d: 1, tx: tx, ty: ty)
    }

    public init(scaleX sx: CGFloat, y sy: CGFloat) {
        self.init(a: sx, b: 0, c: 0, d: sy, tx: 0, ty: 0)
    }

    public func concatenating(_ other: CGAffineTransform) -> CGAffineTransform {
        CGAffineTransform(
            a: a * other.a + b * other.c,
            b: a * other.b + b * other.d,
            c: c * other.a + d * other.c,
            d: c * other.b + d * other.d,
            tx: tx * other.a + ty * other.c + other.tx,
            ty: tx * other.b + ty * other.d + other.ty
        )
    }

    public func inverted() -> CGAffineTransform {
        let det = a * d - b * c
        guard det != 0 else { return .identity }
        return CGAffineTransform(
            a: d / det,
            b: -b / det,
            c: -c / det,
            d: a / det,
            tx: (c * ty - d * tx) / det,
            ty: (b * tx - a * ty) / det
        )
    }

    public func applying(to point: CGPoint) -> CGPoint {
        CGPoint(x: a * point.x + c * point.y + tx, y: b * point.x + d * point.y + ty)
    }

    public func applying(to rect: CGRect) -> CGRect {
        let corners = [
            applying(to: CGPoint(x: rect.minX, y: rect.minY)),
            applying(to: CGPoint(x: rect.maxX, y: rect.minY)),
            applying(to: CGPoint(x: rect.minX, y: rect.maxY)),
            applying(to: CGPoint(x: rect.maxX, y: rect.maxY)),
        ]
        let xs = corners.map(\.x)
        let ys = corners.map(\.y)
        let minX = xs.min() ?? 0
        let minY = ys.min() ?? 0
        return CGRect(
            x: minX,
            y: minY,
            width: (xs.max() ?? minX) - minX,
            height: (ys.max() ?? minY) - minY
        )
    }
}

/// Public EXIF/TIFF orientation codes from CGImageProperties.
public enum CGImagePropertyOrientation: UInt32, Sendable {
    case up = 1
    case upMirrored = 2
    case down = 3
    case downMirrored = 4
    case leftMirrored = 5
    case right = 6
    case rightMirrored = 7
    case left = 8
}

func ciByte(_ component: CGFloat) -> UInt8 {
    UInt8(max(0, min(255, (component * 255).rounded())))
}

func ciClamp01(_ value: CGFloat) -> CGFloat {
    max(0, min(1, value))
}
