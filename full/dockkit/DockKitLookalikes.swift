import Foundation

// Isolated-host stand-ins for Spatial, simd, AVFoundation, and CoreVideo
// types that DockKit's public surface mentions but that are not declared
// dependencies of this seed. They are not Darwin identity. Guest builds
// that import the real modules must not rely on these names remaining
// DockKit-owned.

#if !canImport(Spatial)
/// Process-local Spatial `Vector3D` stand-in (x/y/z metres or radians).
public struct Vector3D: Equatable, Hashable, Sendable {
    public var x: Double
    public var y: Double
    public var z: Double

    public init(x: Double = 0, y: Double = 0, z: Double = 0) {
        self.x = x
        self.y = y
        self.z = z
    }
}

/// Process-local Spatial `Rotation3D` stand-in (unit quaternion).
public struct Rotation3D: Equatable, Hashable, Sendable {
    public var x: Double
    public var y: Double
    public var z: Double
    public var w: Double

    public init(x: Double = 0, y: Double = 0, z: Double = 0, w: Double = 1) {
        self.x = x
        self.y = y
        self.z = z
        self.w = w
    }
}
#endif

#if !canImport(simd)
/// Column-major 3×3 matrix matching Darwin `simd_float3x3` / `matrix_float3x3`.
public struct simd_float3x3: Equatable, Sendable {
    public var columns: (SIMD3<Float>, SIMD3<Float>, SIMD3<Float>)

    public init(columns: (SIMD3<Float>, SIMD3<Float>, SIMD3<Float>)) {
        self.columns = columns
    }

    public init() {
        self.columns = (SIMD3<Float>(0, 0, 0), SIMD3<Float>(0, 0, 0), SIMD3<Float>(0, 0, 0))
    }

    public static func == (lhs: simd_float3x3, rhs: simd_float3x3) -> Bool {
        lhs.columns.0 == rhs.columns.0
            && lhs.columns.1 == rhs.columns.1
            && lhs.columns.2 == rhs.columns.2
    }
}

public typealias matrix_float3x3 = simd_float3x3
#endif

#if !canImport(AVFoundation)
/// Namespace for camera-device identity used by `DockAccessory.CameraInformation`.
public enum AVCaptureDevice {
    public struct DeviceType: Hashable, Sendable {
        public let rawValue: String
        public init(rawValue: String) {
            self.rawValue = rawValue
        }
    }

    public enum Position: Int, Equatable, Hashable, Sendable {
        case unspecified = 0
        case back = 1
        case front = 2
    }
}

open class AVMetadataObject: NSObject, @unchecked Sendable {
    public override init() {
        super.init()
    }
}
#endif

#if !canImport(CoreVideo)
/// Isolated-host pixel-buffer stand-in. Linux never produces a camera frame.
open class CVPixelBuffer: NSObject, @unchecked Sendable {
    public override init() {
        super.init()
    }
}
#endif
