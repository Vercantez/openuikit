import Foundation

// Isolated Linux host lookalikes for CoreGraphics / CoreImage / CoreVideo /
// CoreMedia / ImageIO / CoreML identities the sealed gate does not link.
// These are not those modules' ABI; they exist so Vision's public inits compile
// and so classical detectors can read pixels. When the real modules are
// importable, the `#if canImport` branches prefer them.

public typealias simd_float2 = SIMD2<Float>
public typealias simd_float3 = SIMD3<Float>
public typealias simd_float4 = SIMD4<Float>

#if !canImport(CoreVideo)
public typealias OSType = UInt32
/// FourCC 'BGRA'. Linux lookalike; not an Apple CoreVideo oracle.
public let kCVPixelFormatType_32BGRA: OSType = 0x42475241
#endif

public struct simd_float3x3: Equatable, Hashable, Sendable {
    public var columns: (SIMD3<Float>, SIMD3<Float>, SIMD3<Float>)

    public init(columns: (SIMD3<Float>, SIMD3<Float>, SIMD3<Float>)) {
        self.columns = columns
    }

    public static func == (lhs: simd_float3x3, rhs: simd_float3x3) -> Bool {
        lhs.columns.0 == rhs.columns.0
            && lhs.columns.1 == rhs.columns.1
            && lhs.columns.2 == rhs.columns.2
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(columns.0)
        hasher.combine(columns.1)
        hasher.combine(columns.2)
    }

    public static let identity = simd_float3x3(columns: (
        SIMD3<Float>(1, 0, 0),
        SIMD3<Float>(0, 1, 0),
        SIMD3<Float>(0, 0, 1)
    ))
}

public struct simd_float4x4: Equatable, Hashable, Sendable {
    public var columns: (SIMD4<Float>, SIMD4<Float>, SIMD4<Float>, SIMD4<Float>)

    public init(columns: (SIMD4<Float>, SIMD4<Float>, SIMD4<Float>, SIMD4<Float>)) {
        self.columns = columns
    }

    public static func == (lhs: simd_float4x4, rhs: simd_float4x4) -> Bool {
        lhs.columns.0 == rhs.columns.0
            && lhs.columns.1 == rhs.columns.1
            && lhs.columns.2 == rhs.columns.2
            && lhs.columns.3 == rhs.columns.3
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(columns.0)
        hasher.combine(columns.1)
        hasher.combine(columns.2)
        hasher.combine(columns.3)
    }

    public static let identity = simd_float4x4(columns: (
        SIMD4<Float>(1, 0, 0, 0),
        SIMD4<Float>(0, 1, 0, 0),
        SIMD4<Float>(0, 0, 1, 0),
        SIMD4<Float>(0, 0, 0, 1)
    ))

    public static func translation(x: Float, y: Float, z: Float) -> simd_float4x4 {
        simd_float4x4(columns: (
            SIMD4<Float>(1, 0, 0, 0),
            SIMD4<Float>(0, 1, 0, 0),
            SIMD4<Float>(0, 0, 1, 0),
            SIMD4<Float>(x, y, z, 1)
        ))
    }
}

#if !canImport(CoreGraphics)
public struct CGAffineTransform: Equatable, Hashable, Sendable {
    public var a: CGFloat
    public var b: CGFloat
    public var c: CGFloat
    public var d: CGFloat
    public var tx: CGFloat
    public var ty: CGFloat

    public static let identity = CGAffineTransform(a: 1, b: 0, c: 0, d: 1, tx: 0, ty: 0)

    public init(a: CGFloat, b: CGFloat, c: CGFloat, d: CGFloat, tx: CGFloat, ty: CGFloat) {
        self.a = a
        self.b = b
        self.c = c
        self.d = d
        self.tx = tx
        self.ty = ty
    }

    public init(translationX tx: CGFloat, y ty: CGFloat) {
        self.init(a: 1, b: 0, c: 0, d: 1, tx: tx, ty: ty)
    }

    public init(rotationAngle angle: CGFloat) {
        let cosine = Foundation.cos(angle)
        let sine = Foundation.sin(angle)
        self.init(a: cosine, b: sine, c: -sine, d: cosine, tx: 0, ty: 0)
    }

    public func concatenating(_ t2: CGAffineTransform) -> CGAffineTransform {
        CGAffineTransform(
            a: a * t2.a + b * t2.c,
            b: a * t2.b + b * t2.d,
            c: c * t2.a + d * t2.c,
            d: c * t2.b + d * t2.d,
            tx: tx * t2.a + ty * t2.c + t2.tx,
            ty: tx * t2.b + ty * t2.d + t2.ty
        )
    }
}
#endif

public typealias matrix_float3x3 = simd_float3x3

#if !canImport(ImageIO)
@frozen
public enum CGImagePropertyOrientation: UInt32, CaseIterable, Sendable {
    case up = 1
    case upMirrored = 2
    case down = 3
    case downMirrored = 4
    case leftMirrored = 5
    case right = 6
    case rightMirrored = 7
    case left = 8
}
#endif

#if !canImport(CoreGraphics)
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

public final class CGPath: @unchecked Sendable {
    public struct Element: Equatable, Sendable {
        public enum Kind: Int, Sendable {
            case move = 0
            case addLine = 1
            case close = 2
        }
        public var kind: Kind
        public var point: CGPoint
    }

    public private(set) var elements: [Element] = []

    public init() {}

    public func move(to point: CGPoint) {
        elements.append(Element(kind: .move, point: point))
    }

    public func addLine(to point: CGPoint) {
        elements.append(Element(kind: .addLine, point: point))
    }

    public func closeSubpath() {
        elements.append(Element(kind: .close, point: .zero))
    }
}

public typealias CGMutablePath = CGPath
#endif

#if !canImport(CoreImage)
public final class CIImage: NSObject, @unchecked Sendable {
    public let cgImage: CGImage?
    public let extent: CGRect

    public init(cgImage image: CGImage) {
        self.cgImage = image
        self.extent = CGRect(x: 0, y: 0, width: image.width, height: image.height)
        super.init()
    }

    public convenience init(CGImage image: CGImage) {
        self.init(cgImage: image)
    }

    public func oriented(_ orientation: CGImagePropertyOrientation) -> CIImage {
        guard let cgImage else { return self }
        let raster = VisionRaster(cgImage: cgImage).applying(orientation: orientation)
        return CIImage(cgImage: raster.makeCGImage())
    }
}

open class CIBarcodeDescriptor: NSObject, @unchecked Sendable {}
#endif

#if !canImport(CoreVideo)
public typealias CVReturn = Int32
public let kCVReturnSuccess: CVReturn = 0

public final class CVPixelBuffer: @unchecked Sendable {
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
#endif

#if !canImport(CoreMedia)
public struct CMTime: Hashable, Codable, Sendable {
    public var value: Int64
    public var timescale: Int32

    public init(value: Int64, timescale: Int32) {
        self.value = value
        self.timescale = timescale
    }

    public static let zero = CMTime(value: 0, timescale: 1)
    public static let invalid = CMTime(value: 0, timescale: 0)
}

public struct CMTimeRange: Hashable, Codable, Sendable {
    public var start: CMTime
    public var duration: CMTime

    public init(start: CMTime, duration: CMTime) {
        self.start = start
        self.duration = duration
    }

    public static let zero = CMTimeRange(start: .zero, duration: .zero)
}

public final class CMSampleBuffer: @unchecked Sendable {
    public let pixelBuffer: CVPixelBuffer

    public init(pixelBuffer: CVPixelBuffer) {
        self.pixelBuffer = pixelBuffer
    }
}
#endif

#if !canImport(AVFoundation)
public final class AVDepthData: NSObject, @unchecked Sendable {}
#endif

#if !canImport(CoreML)
public struct MLComputeDevice: Hashable, Sendable {
    public let identifier: String
    public init(identifier: String = "cpu") {
        self.identifier = identifier
    }

    public static let cpu = MLComputeDevice(identifier: "cpu")
}

open class MLModel: NSObject, @unchecked Sendable {}

public protocol MLFeatureProvider: AnyObject {}

open class MLMultiArray: NSObject, @unchecked Sendable {
    public let shape: [Int]
    public let data: Data

    public var count: Int {
        max(1, shape.reduce(1, *))
    }

    public init(shape: [Int] = [0], data: Data = Data()) {
        self.shape = shape
        self.data = data
        super.init()
    }
}
#endif

/// Local stand-in for DataDetection.Match so document observations compile.
public enum DataDetector {
    public struct Match: Hashable, Sendable, Codable {
        public var matchType: String
        public var matchedString: String

        public init(matchType: String = "unknown", matchedString: String) {
            self.matchType = matchType
            self.matchedString = matchedString
        }
    }
}
