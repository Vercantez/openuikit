#if canImport(Darwin)
import Darwin
#else
import Glibc
#endif
import Foundation

/// Portable stand-ins for Apple modules the sealed host gate does not import
/// (`UIKit`, `SceneKit`, `SpriteKit`, `Metal`, `AVFoundation`, `CoreVideo`,
/// `CoreLocation`, `ImageIO`, `CoreGraphics`, `Vision`). They are **not**
/// additional Apple ARKit symbols. When the real module is on the compile
/// graph, `canImport` selects that identity instead.

#if canImport(UIKit)
import UIKit
#else
/// UIKit orientation raw values match `UIInterfaceOrientation` on iOS.
public enum UIInterfaceOrientation: Int, Hashable, Sendable {
    case unknown = 0
    case portrait = 1
    case portraitUpsideDown = 2
    case landscapeRight = 3
    case landscapeLeft = 4
}

open class UIImage: NSObject {}
#endif

#if canImport(CoreGraphics)
import CoreGraphics
#else
/// Minimal affine transform so `ARFrame.displayTransform` can compile.
public struct CGAffineTransform: Equatable, Sendable {
    public var a: CGFloat
    public var b: CGFloat
    public var c: CGFloat
    public var d: CGFloat
    public var tx: CGFloat
    public var ty: CGFloat

    public init(a: CGFloat, b: CGFloat, c: CGFloat, d: CGFloat, tx: CGFloat, ty: CGFloat) {
        self.a = a
        self.b = b
        self.c = c
        self.d = d
        self.tx = tx
        self.ty = ty
    }

    public static var identity: CGAffineTransform {
        CGAffineTransform(a: 1, b: 0, c: 0, d: 1, tx: 0, ty: 0)
    }

    public init(rotationAngle angle: CGFloat) {
        let cosine = CGFloat(cos(Double(angle)))
        let sine = CGFloat(sin(Double(angle)))
        self.init(a: cosine, b: sine, c: -sine, d: cosine, tx: 0, ty: 0)
    }
}

/// Pixel-buffer sized image descriptor. Not a decoded bitmap.
public final class CGImage: @unchecked Sendable {
    public let width: Int
    public let height: Int

    public init(width: Int, height: Int) {
        self.width = max(width, 0)
        self.height = max(height, 0)
    }
}
#endif

#if canImport(ImageIO)
import ImageIO
#else
public enum CGImagePropertyOrientation: UInt32, Hashable, Sendable {
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

#if canImport(CoreVideo)
import CoreVideo
#else
/// Empty pixel-buffer stand-in. Never contains camera pixels.
open class CVPixelBuffer: NSObject {
    public let width: Int
    public let height: Int

    public init(width: Int = 0, height: Int = 0) {
        self.width = width
        self.height = height
        super.init()
    }
}
#endif

#if canImport(CoreLocation)
import CoreLocation
#else
public struct CLLocationCoordinate2D: Equatable, Hashable, Sendable {
    public var latitude: Double
    public var longitude: Double

    public init(latitude: Double, longitude: Double) {
        self.latitude = latitude
        self.longitude = longitude
    }
}

public typealias CLLocationDistance = Double
#endif

#if canImport(Metal)
import Metal
#else
public protocol MTLBuffer: AnyObject {}
public protocol MTLTexture: AnyObject {}
public protocol MTLDevice: AnyObject {}
public protocol MTLCommandBuffer: AnyObject {}

public enum MTLVertexFormat: UInt, Hashable, Sendable {
    case invalid = 0
    case uchar = 1
    case float = 28
    case float2 = 29
    case float3 = 30
    case float4 = 31
}

public final class ARKitHostMTLBuffer: MTLBuffer {
    public init() {}
}
public final class ARKitHostMTLTexture: MTLTexture {
    public init() {}
}
public final class ARKitHostMTLDevice: MTLDevice {
    public init() {}
}
public final class ARKitHostMTLCommandBuffer: MTLCommandBuffer {
    public init() {}
}
#endif

#if canImport(AVFoundation)
import AVFoundation
#else
open class AVCaptureDevice: NSObject {
    public enum Position: Int, Hashable, Sendable {
        case unspecified = 0
        case back = 1
        case front = 2
    }

    public struct DeviceType: RawRepresentable, Hashable, Sendable {
        public let rawValue: String
        public init(rawValue: String) { self.rawValue = rawValue }
        public static let builtInWideAngleCamera = DeviceType(rawValue: "AVCaptureDeviceTypeBuiltInWideAngleCamera")
    }
}

public enum AVCaptureColorSpace: Int, Hashable, Sendable {
    case sRGB = 0
    case P3_D65 = 1
    case HLG_BT2020 = 2
}

open class AVCapturePhotoSettings: NSObject {}
open class AVDepthData: NSObject {}
#endif

#if canImport(CoreMedia)
import CoreMedia
#else
open class CMSampleBuffer: NSObject {}
#endif

#if canImport(SceneKit)
import SceneKit
#else
open class SCNNode: NSObject {}
open class SCNScene: NSObject {}
open class SCNGeometry: NSObject {}
public protocol SCNSceneRenderer: AnyObject {}
public protocol SCNSceneRendererDelegate: AnyObject {}

public struct SCNDebugOptions: OptionSet, Hashable, Sendable {
    public let rawValue: UInt
    public init(rawValue: UInt) { self.rawValue = rawValue }
}
#endif

#if canImport(SpriteKit)
import SpriteKit
#else
open class SKNode: NSObject {}
public protocol SKViewDelegate: AnyObject {}
#endif

#if canImport(Vision)
import Vision
#else
public struct VNRecognizedPointKey: RawRepresentable, Hashable, Sendable {
    public let rawValue: String
    public init(rawValue: String) { self.rawValue = rawValue }
}
#endif

extension SCNDebugOptions {
    /// ARKit extension bit. Raw value follows the long-published
    /// `ARSCNDebugOptionShowWorldOrigin` flag (1 << 0); confirm on device.
    public static let showWorldOrigin = SCNDebugOptions(rawValue: 1 << 0)
    /// ARKit extension bit. Raw value follows `ARSCNDebugOptionShowFeaturePoints`
    /// (1 << 1); confirm on device.
    public static let showFeaturePoints = SCNDebugOptions(rawValue: 1 << 1)
}

