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
