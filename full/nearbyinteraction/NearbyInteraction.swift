import Foundation

// Linux starting point for Apple's NearbyInteraction. UWB ranging, ARKit
// camera assistance, and accessory-firmware blobs are fail-closed: Linux
// has no Nearby Interaction daemon, U1/U2 radio, or entitlement prompt.
// Value types, error codes, configuration storage, and the session
// state machine are implemented and tested here.

// MARK: - SIMD aliases (Darwin `simd` is not a declared dependency)

public typealias simd_float3 = SIMD3<Float>
public typealias simd_double3 = SIMD3<Double>

/// Column-major 4x4 transform matching Darwin `simd_float4x4`.
public struct simd_float4x4: Equatable, Sendable {
    public var columns: (SIMD4<Float>, SIMD4<Float>, SIMD4<Float>, SIMD4<Float>)

    public init(columns: (SIMD4<Float>, SIMD4<Float>, SIMD4<Float>, SIMD4<Float>)) {
        self.columns = columns
    }

    public static var identity: simd_float4x4 {
        simd_float4x4(
            columns: (
                SIMD4<Float>(1, 0, 0, 0),
                SIMD4<Float>(0, 1, 0, 0),
                SIMD4<Float>(0, 0, 1, 0),
                SIMD4<Float>(0, 0, 0, 1)
            )
        )
    }
}

/// ARKit is not a declared dependency of this seed. `NISession.setARSession`
/// accepts `NSObject` so the selector type-checks; camera assistance stays off.
public typealias ARSession = NSObject

// MARK: - Error domain

/// Process-local identity of Apple's `NIErrorDomain` export.
public let NIErrorDomain = "NIErrorDomain"

/// Bridged Nearby Interaction error.
///
/// Raw values are the NS_ERROR_ENUM integers recorded by the pinned
/// dotnet-macios NearbyInteraction bindings (`UnsupportedPlatform = -5889`
/// through `ActiveExtendedDistanceSessionsLimitExceeded = -5880`), which
/// match sequential assignment from the API-digester child order.
@frozen
public struct NIError: Foundation._BridgedStoredNSError, @unchecked Sendable {
    public enum Code: Int, Foundation._ErrorCodeProtocol, Sendable {
        public typealias _ErrorType = NIError

        case unsupportedPlatform = -5889
        case invalidConfiguration = -5888
        case sessionFailed = -5887
        case resourceUsageTimeout = -5886
        case activeSessionsLimitExceeded = -5885
        case userDidNotAllow = -5884
        case invalidARConfiguration = -5883
        case accessoryPeerDeviceUnavailable = -5882
        case incompatiblePeerDevice = -5881
        case activeExtendedDistanceSessionsLimitExceeded = -5880
    }

    public let _nsError: NSError

    public init(_nsError: NSError) {
        self._nsError = _nsError
    }

    public static var _nsErrorDomain: String { NIErrorDomain }

    public static var errorDomain: String { NIErrorDomain }

    public static var unsupportedPlatform: Code { .unsupportedPlatform }
    public static var invalidConfiguration: Code { .invalidConfiguration }
    public static var sessionFailed: Code { .sessionFailed }
    public static var resourceUsageTimeout: Code { .resourceUsageTimeout }
    public static var activeSessionsLimitExceeded: Code { .activeSessionsLimitExceeded }
    public static var userDidNotAllow: Code { .userDidNotAllow }
    public static var invalidARConfiguration: Code { .invalidARConfiguration }
    public static var accessoryPeerDeviceUnavailable: Code { .accessoryPeerDeviceUnavailable }
    public static var incompatiblePeerDevice: Code { .incompatiblePeerDevice }
    public static var activeExtendedDistanceSessionsLimitExceeded: Code {
        .activeExtendedDistanceSessionsLimitExceeded
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(_nsError.domain)
        hasher.combine(_nsError.code)
    }

    public var hashValue: Int {
        var hasher = Hasher()
        hash(into: &hasher)
        return hasher.finalize()
    }
}

// MARK: - DL-TDoA enums

public enum NIDLTDOACoordinatesType: Int, Equatable, Hashable, Sendable {
    case geodetic = 0
    case relative = 1
}

public enum NIDLTDOAMeasurementType: Int, Equatable, Hashable, Sendable {
    case poll = 0
    case response = 1
    case `final` = 2
}

// MARK: - Device capability

public protocol NIDeviceCapability: AnyObject {
    var supportsPreciseDistanceMeasurement: Bool { get }
    var supportsDirectionMeasurement: Bool { get }
    var supportsCameraAssistance: Bool { get }
    var supportsExtendedDistanceMeasurement: Bool { get }
    var supportsDLTDOAMeasurement: Bool { get }
}

/// Linux capability record: every UWB / camera / DL-TDoA flag is false.
public final class NIHostDeviceCapability: NSObject, NIDeviceCapability {
    public let supportsPreciseDistanceMeasurement = false
    public let supportsDirectionMeasurement = false
    public let supportsCameraAssistance = false
    public let supportsExtendedDistanceMeasurement = false
    public let supportsDLTDOAMeasurement = false

    public static let unsupported = NIHostDeviceCapability()
}

// MARK: - Algorithm convergence

public enum NIAlgorithmConvergenceStatus: Equatable, Sendable {
    case unknown
    case notConverged([NIAlgorithmConvergenceStatus.Reason])
    case converged

    public static func == (
        lhs: NIAlgorithmConvergenceStatus,
        rhs: NIAlgorithmConvergenceStatus
    ) -> Bool {
        switch (lhs, rhs) {
        case (.unknown, .unknown), (.converged, .converged):
            return true
        case let (.notConverged(lhsReasons), .notConverged(rhsReasons)):
            return lhsReasons == rhsReasons
        default:
            return false
        }
    }

    public struct Reason: RawRepresentable, Hashable, Sendable {
        public typealias RawValue = String

        public var rawValue: String

        public init(rawValue: String) {
            self.rawValue = rawValue
        }

        public static let insufficientHorizontalSweep = Reason(
            rawValue: "NIAlgorithmConvergenceStatusReasonInsufficientHorizontalSweep"
        )
        public static let insufficientVerticalSweep = Reason(
            rawValue: "NIAlgorithmConvergenceStatusReasonInsufficientVerticalSweep"
        )
        public static let insufficientMovement = Reason(
            rawValue: "NIAlgorithmConvergenceStatusReasonInsufficientMovement"
        )
        public static let insufficientLighting = Reason(
            rawValue: "NIAlgorithmConvergenceStatusReasonInsufficientLighting"
        )
        public static let insufficientSignalStrength = Reason(
            rawValue: "NIAlgorithmConvergenceStatusReasonInsufficientSignalStrength"
        )

        /// Process-local English text. Apple's bundle copy is unobserved.
        public var localizedDescription: String? {
            switch self {
            case .insufficientHorizontalSweep:
                return "Insufficient horizontal sweep."
            case .insufficientVerticalSweep:
                return "Insufficient vertical sweep."
            case .insufficientMovement:
                return "Insufficient movement."
            case .insufficientLighting:
                return "Insufficient lighting."
            case .insufficientSignalStrength:
                return "Insufficient signal strength."
            default:
                return nil
            }
        }
    }
}

public class NIAlgorithmConvergence: NSObject, NSCopying, NSSecureCoding {
    public let status: NIAlgorithmConvergenceStatus

    public static var supportsSecureCoding: Bool { true }

    public init(status: NIAlgorithmConvergenceStatus) {
        self.status = status
        super.init()
    }

    public required init?(coder: NSCoder) {
        let kind = coder.decodeInteger(forKey: "statusKind")
        switch kind {
        case 0:
            self.status = .unknown
        case 2:
            self.status = .converged
        case 1:
            let raws = (coder.decodeObject(of: [NSArray.self, NSString.self], forKey: "reasons") as? [String]) ?? []
            self.status = .notConverged(raws.map { NIAlgorithmConvergenceStatus.Reason(rawValue: $0) })
        default:
            return nil
        }
        super.init()
    }

    public func encode(with coder: NSCoder) {
        switch status {
        case .unknown:
            coder.encode(0, forKey: "statusKind")
        case .notConverged(let reasons):
            coder.encode(1, forKey: "statusKind")
            coder.encode(reasons.map(\.rawValue) as NSArray, forKey: "reasons")
        case .converged:
            coder.encode(2, forKey: "statusKind")
        }
    }

    public func copy(with zone: NSZone? = nil) -> Any {
        NIAlgorithmConvergence(status: status)
    }
}
