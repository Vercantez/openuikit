#if canImport(Darwin)
import Darwin
#else
import Glibc
#endif
@_exported import Foundation

/// Linux does not ship Darwin `simd`. These aliases and matrix types are a
/// portable stand-in for the identifiers ARKit's public Swift surface uses.
/// They are not additional Apple ARKit symbols.
public typealias simd_float2 = SIMD2<Float>
public typealias simd_float3 = SIMD3<Float>
public typealias simd_float4 = SIMD4<Float>
public typealias vector_float2 = simd_float2

public struct simd_float3x3: Equatable, Sendable {
    public var columns: (simd_float3, simd_float3, simd_float3)

    public init(columns: (simd_float3, simd_float3, simd_float3)) {
        self.columns = columns
    }

    public init() {
        self.columns = (
            simd_float3(repeating: 0),
            simd_float3(repeating: 0),
            simd_float3(repeating: 0)
        )
    }

    public static func == (lhs: simd_float3x3, rhs: simd_float3x3) -> Bool {
        lhs.columns.0 == rhs.columns.0
            && lhs.columns.1 == rhs.columns.1
            && lhs.columns.2 == rhs.columns.2
    }
}

public struct simd_float4x4: Equatable, Sendable {
    public var columns: (simd_float4, simd_float4, simd_float4, simd_float4)

    public init(columns: (simd_float4, simd_float4, simd_float4, simd_float4)) {
        self.columns = columns
    }

    public init() {
        self.columns = (
            simd_float4(repeating: 0),
            simd_float4(repeating: 0),
            simd_float4(repeating: 0),
            simd_float4(repeating: 0)
        )
    }

    public static var identity: simd_float4x4 {
        simd_float4x4(
            columns: (
                simd_float4(1, 0, 0, 0),
                simd_float4(0, 1, 0, 0),
                simd_float4(0, 0, 1, 0),
                simd_float4(0, 0, 0, 1)
            )
        )
    }

    public static func == (lhs: simd_float4x4, rhs: simd_float4x4) -> Bool {
        lhs.columns.0 == rhs.columns.0
            && lhs.columns.1 == rhs.columns.1
            && lhs.columns.2 == rhs.columns.2
            && lhs.columns.3 == rhs.columns.3
    }

    /// Column-major rigid inverse (rotation transpose, translation `-Rᵀt`).
    func rigidInverse() -> simd_float4x4 {
        let r0 = columns.0
        let r1 = columns.1
        let r2 = columns.2
        let t = columns.3
        let ix = simd_float3(r0.x, r1.x, r2.x)
        let iy = simd_float3(r0.y, r1.y, r2.y)
        let iz = simd_float3(r0.z, r1.z, r2.z)
        let it = simd_float3(
            -(ix.x * t.x + ix.y * t.y + ix.z * t.z),
            -(iy.x * t.x + iy.y * t.y + iy.z * t.z),
            -(iz.x * t.x + iz.y * t.y + iz.z * t.z)
        )
        return simd_float4x4(
            columns: (
                simd_float4(ix.x, iy.x, iz.x, 0),
                simd_float4(ix.y, iy.y, iz.y, 0),
                simd_float4(ix.z, iy.z, iz.z, 0),
                simd_float4(it.x, it.y, it.z, 1)
            )
        )
    }

    func transformPoint(_ point: simd_float3) -> simd_float3 {
        let c0 = columns.0
        let c1 = columns.1
        let c2 = columns.2
        let c3 = columns.3
        return simd_float3(
            c0.x * point.x + c1.x * point.y + c2.x * point.z + c3.x,
            c0.y * point.x + c1.y * point.y + c2.y * point.z + c3.y,
            c0.z * point.x + c1.z * point.y + c2.z * point.z + c3.z
        )
    }

    func transformDirection(_ direction: simd_float3) -> simd_float3 {
        let c0 = columns.0
        let c1 = columns.1
        let c2 = columns.2
        return simd_float3(
            c0.x * direction.x + c1.x * direction.y + c2.x * direction.z,
            c0.y * direction.x + c1.y * direction.y + c2.y * direction.z,
            c0.z * direction.x + c1.z * direction.y + c2.z * direction.z
        )
    }

    public static func translation(_ offset: simd_float3) -> simd_float4x4 {
        var matrix = simd_float4x4.identity
        matrix.columns.3 = simd_float4(offset.x, offset.y, offset.z, 1)
        return matrix
    }

    public static func rotationZ(_ radians: Float) -> simd_float4x4 {
        let cosine = cos(radians)
        let sine = sin(radians)
        return simd_float4x4(
            columns: (
                simd_float4(cosine, sine, 0, 0),
                simd_float4(-sine, cosine, 0, 0),
                simd_float4(0, 0, 1, 0),
                simd_float4(0, 0, 0, 1)
            )
        )
    }
}

func * (lhs: simd_float4x4, rhs: simd_float4x4) -> simd_float4x4 {
    return simd_float4x4(
        columns: (
            lhs * rhs.columns.0,
            lhs * rhs.columns.1,
            lhs * rhs.columns.2,
            lhs * rhs.columns.3
        )
    )
}

func * (matrix: simd_float4x4, vector: simd_float4) -> simd_float4 {
    let c0 = matrix.columns.0
    let c1 = matrix.columns.1
    let c2 = matrix.columns.2
    let c3 = matrix.columns.3
    return simd_float4(
        c0.x * vector.x + c1.x * vector.y + c2.x * vector.z + c3.x * vector.w,
        c0.y * vector.x + c1.y * vector.y + c2.y * vector.z + c3.y * vector.w,
        c0.z * vector.x + c1.z * vector.y + c2.z * vector.z + c3.z * vector.w,
        c0.w * vector.x + c1.w * vector.y + c2.w * vector.z + c3.w * vector.w
    )
}

func arkitDot(_ a: simd_float3, _ b: simd_float3) -> Float {
    a.x * b.x + a.y * b.y + a.z * b.z
}

func arkitLength(_ v: simd_float3) -> Float {
    sqrt(arkitDot(v, v))
}

func arkitNormalize(_ v: simd_float3) -> simd_float3 {
    let length = arkitLength(v)
    guard length > 0 else { return simd_float3(repeating: 0) }
    return simd_float3(v.x / length, v.y / length, v.z / length)
}

func arkitCross(_ a: simd_float3, _ b: simd_float3) -> simd_float3 {
    simd_float3(
        a.y * b.z - a.z * b.y,
        a.z * b.x - a.x * b.z,
        a.x * b.y - a.y * b.x
    )
}

/// Encode a 4×4 as 16 column-major floats for `NSSecureCoding`.
func arkitEncodeMatrix(_ matrix: simd_float4x4) -> [Float] {
    [
        matrix.columns.0.x, matrix.columns.0.y, matrix.columns.0.z, matrix.columns.0.w,
        matrix.columns.1.x, matrix.columns.1.y, matrix.columns.1.z, matrix.columns.1.w,
        matrix.columns.2.x, matrix.columns.2.y, matrix.columns.2.z, matrix.columns.2.w,
        matrix.columns.3.x, matrix.columns.3.y, matrix.columns.3.z, matrix.columns.3.w,
    ]
}

func arkitDecodeMatrix(_ values: [Float]) -> simd_float4x4? {
    guard values.count == 16 else { return nil }
    return simd_float4x4(
        columns: (
            simd_float4(values[0], values[1], values[2], values[3]),
            simd_float4(values[4], values[5], values[6], values[7]),
            simd_float4(values[8], values[9], values[10], values[11]),
            simd_float4(values[12], values[13], values[14], values[15])
        )
    )
}

/// Linux-only documented test hook. Not an Apple ARKit API.
///
/// Default `ARConfiguration.isSupported` is `false`. Tests that need a
/// simulated IMU/camera install a device with `installSimulatedDevice()`.
/// `ARSession.run` then drives `ARSimulatedFrameSource` instead of failing
/// with `unsupportedConfiguration`. World maps, collaboration, high-resolution
/// capture, and geo localization stay fail-closed. There is still no camera,
/// LiDAR, or Apple world-tracking service.
public enum ARKitTestHook: Sendable {
    private static let lock = NSLock()
    private static var simulatedDevice = false
    private static var cameraAuthorized = true

    public static func installSimulatedDevice(cameraAuthorized: Bool = true) {
        lock.lock()
        simulatedDevice = true
        self.cameraAuthorized = cameraAuthorized
        lock.unlock()
    }

    public static func removeSimulatedDevice() {
        lock.lock()
        simulatedDevice = false
        cameraAuthorized = true
        lock.unlock()
    }

    public static var isSimulatedDeviceInstalled: Bool {
        lock.lock()
        defer { lock.unlock() }
        return simulatedDevice
    }

    public static var isCameraAuthorized: Bool {
        lock.lock()
        defer { lock.unlock() }
        return cameraAuthorized
    }
}

func arkitCameraUnauthorizedError() -> ARError {
    ARError(
        .cameraUnauthorized,
        userInfo: [
            NSLocalizedDescriptionKey: "Camera unauthorized.",
            NSLocalizedFailureReasonErrorKey:
                "Camera access is not authorized on this host.",
        ]
    )
}

func arkitInvalidWorldMapError() -> ARError {
    ARError(
        .invalidWorldMap,
        userInfo: [
            NSLocalizedDescriptionKey: "Invalid world map.",
            NSLocalizedFailureReasonErrorKey:
                "World map export is not available on this host.",
        ]
    )
}

func arkitLookAt(eye: simd_float3, target: simd_float3, up: simd_float3) -> simd_float4x4 {
    let zAxis = arkitNormalize(simd_float3(eye.x - target.x, eye.y - target.y, eye.z - target.z))
    let xAxis = arkitNormalize(arkitCross(up, zAxis))
    let yAxis = arkitCross(zAxis, xAxis)
    return simd_float4x4(
        columns: (
            simd_float4(xAxis.x, xAxis.y, xAxis.z, 0),
            simd_float4(yAxis.x, yAxis.y, yAxis.z, 0),
            simd_float4(zAxis.x, zAxis.y, zAxis.z, 0),
            simd_float4(eye.x, eye.y, eye.z, 1)
        )
    )
}

/// Documented simulated-camera defaults used by `ARSimulatedFrameSource`.
public enum ARSimulatedCameraDefaults {
    public static let imageResolution = CGSize(width: 640, height: 480)
    public static let fx: Float = 640
    public static let fy: Float = 640
    public static let cx: Float = 320
    public static let cy: Float = 240
    public static let eye = simd_float3(0, 1.2, 1.5)
    public static let target = simd_float3(repeating: 0)
    public static let planeExtent = simd_float3(2, 0, 2)

    public static var intrinsics: simd_float3x3 {
        simd_float3x3(
            columns: (
                simd_float3(fx, 0, 0),
                simd_float3(0, fy, 0),
                simd_float3(cx, cy, 1)
            )
        )
    }

    public static var transform: simd_float4x4 {
        arkitLookAt(eye: eye, target: target, up: simd_float3(0, 1, 0))
    }
}

func arkitInterfaceOrientationRotation(_ orientation: UIInterfaceOrientation) -> simd_float4x4 {
    // Simulated camera buffers are landscape-right (sensor native). Portrait
    // interface orientations rotate about Z by ±90°.
    switch orientation {
    case .portrait:
        return simd_float4x4.rotationZ(-Float.pi / 2)
    case .portraitUpsideDown:
        return simd_float4x4.rotationZ(Float.pi / 2)
    case .landscapeLeft:
        return simd_float4x4.rotationZ(Float.pi)
    case .landscapeRight, .unknown:
        return .identity
    }
}

/// Public NSError domain observed for ARKit session failures
/// (`Domain=com.apple.arkit.error`). Confirm the exact string on an Apple
/// runtime before treating it as ABI-frozen.
public let ARErrorDomain = "com.apple.arkit.error"

/// Portable counterpart of ARKit's bridged `NS_ERROR_ENUM`.
///
/// Numeric codes follow the public `ARErrorCode` enumeration documented for
/// iOS (100-series sensors, 200-series tracking, 300-series assets, 400-series
/// reconstruction, 500-series I/O).
public struct ARError: Error, CustomNSError, Hashable, Equatable, @unchecked Sendable {
    public enum Code: Int, Hashable, Sendable {
        case unsupportedConfiguration = 100
        case sensorUnavailable = 101
        case sensorFailed = 102
        case cameraUnauthorized = 103
        case microphoneUnauthorized = 104
        case locationUnauthorized = 105
        case highResolutionFrameCaptureInProgress = 106
        case highResolutionFrameCaptureFailed = 107
        case worldTrackingFailed = 200
        case geoTrackingNotAvailableAtLocation = 201
        case geoTrackingFailed = 202
        case invalidReferenceImage = 300
        case invalidReferenceObject = 301
        case invalidWorldMap = 302
        case invalidConfiguration = 303
        case invalidCollaborationData = 304
        case insufficientFeatures = 400
        case objectMergeFailed = 401
        case fileIOFailed = 500
        case requestFailed = 501
    }

    public let code: Code
    public let userInfo: [String: Any]

    public init(_ code: Code, userInfo: [String: Any] = [:]) {
        self.code = code
        self.userInfo = userInfo
    }

    public static var errorDomain: String { ARErrorDomain }
    public var errorCode: Int { code.rawValue }
    public var errorUserInfo: [String: Any] { userInfo }

    public static let unsupportedConfiguration = Code.unsupportedConfiguration
    public static let sensorUnavailable = Code.sensorUnavailable
    public static let sensorFailed = Code.sensorFailed
    public static let cameraUnauthorized = Code.cameraUnauthorized
    public static let microphoneUnauthorized = Code.microphoneUnauthorized
    public static let locationUnauthorized = Code.locationUnauthorized
    public static let highResolutionFrameCaptureInProgress = Code.highResolutionFrameCaptureInProgress
    public static let highResolutionFrameCaptureFailed = Code.highResolutionFrameCaptureFailed
    public static let worldTrackingFailed = Code.worldTrackingFailed
    public static let geoTrackingNotAvailableAtLocation = Code.geoTrackingNotAvailableAtLocation
    public static let geoTrackingFailed = Code.geoTrackingFailed
    public static let invalidReferenceImage = Code.invalidReferenceImage
    public static let invalidReferenceObject = Code.invalidReferenceObject
    public static let invalidWorldMap = Code.invalidWorldMap
    public static let invalidConfiguration = Code.invalidConfiguration
    public static let invalidCollaborationData = Code.invalidCollaborationData
    public static let insufficientFeatures = Code.insufficientFeatures
    public static let objectMergeFailed = Code.objectMergeFailed
    public static let fileIOFailed = Code.fileIOFailed
    public static let requestFailed = Code.requestFailed

    public static func == (lhs: ARError, rhs: ARError) -> Bool {
        guard lhs.code == rhs.code else { return false }
        return NSDictionary(dictionary: lhs.userInfo).isEqual(to: rhs.userInfo)
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(code)
    }
}

extension ARError.Code {
    public static func ~= (match: ARError.Code, error: any Error) -> Bool {
        (error as? ARError)?.code == match
    }
}

func arkitUnsupportedConfigurationError() -> ARError {
    ARError(
        .unsupportedConfiguration,
        userInfo: [
            NSLocalizedDescriptionKey: "Unsupported configuration.",
            NSLocalizedFailureReasonErrorKey:
                "The provided configuration is not supported on this device.",
        ]
    )
}

public enum ARConfidenceLevel: Int, Comparable, Hashable, Sendable {
    case low = 0
    case medium = 1
    case high = 2

    public static func < (lhs: ARConfidenceLevel, rhs: ARConfidenceLevel) -> Bool {
        lhs.rawValue < rhs.rawValue
    }
}

public enum ARGeometryPrimitiveType: Int, Hashable, Sendable {
    case line = 0
    case triangle = 1
}

public enum ARMeshClassification: Int, Hashable, Sendable {
    case none = 0
    case wall = 1
    case floor = 2
    case ceiling = 3
    case table = 4
    case seat = 5
    case window = 6
    case door = 7
}
