@_exported import Foundation

public let CMErrorDomain: String = "CMErrorDomain"

/// Public `NS_ERROR_ENUM` overlay. Numeric `rawValue` assignments are Linux
/// fallbacks so the named constants compile; they are not observed Apple ABI.
public struct CMError: Error, Hashable, RawRepresentable, Sendable, BitwiseCopyable {
    public var rawValue: UInt32

    public init(rawValue: UInt32) {
        self.rawValue = rawValue
    }

    public init(_ rawValue: UInt32) {
        self.rawValue = rawValue
    }
}

extension CMError: CustomNSError {
    public static var errorDomain: String { CMErrorDomain }
    public var errorCode: Int { Int(rawValue) }
}

public var CMErrorNULL: CMError { CMError(rawValue: 100) }
public var CMErrorDeviceRequiresMovement: CMError { CMError(rawValue: 101) }
public var CMErrorTrueNorthNotAvailable: CMError { CMError(rawValue: 102) }
public var CMErrorUnknown: CMError { CMError(rawValue: 103) }
public var CMErrorMotionActivityNotAvailable: CMError { CMError(rawValue: 104) }
public var CMErrorMotionActivityNotAuthorized: CMError { CMError(rawValue: 105) }
public var CMErrorMotionActivityNotEntitled: CMError { CMError(rawValue: 106) }
public var CMErrorInvalidParameter: CMError { CMError(rawValue: 107) }
public var CMErrorInvalidAction: CMError { CMError(rawValue: 108) }
public var CMErrorNotAvailable: CMError { CMError(rawValue: 109) }
public var CMErrorNotEntitled: CMError { CMError(rawValue: 110) }
public var CMErrorNotAuthorized: CMError { CMError(rawValue: 111) }
public var CMErrorNilData: CMError { CMError(rawValue: 112) }
public var CMErrorSize: CMError { CMError(rawValue: 113) }

public struct CMAttitudeReferenceFrame: OptionSet, Sendable, Hashable, BitwiseCopyable {
    public let rawValue: UInt

    public init(rawValue: UInt) {
        self.rawValue = rawValue
    }

    public static let xArbitraryZVertical = CMAttitudeReferenceFrame(rawValue: 1 << 0)
    public static let xArbitraryCorrectedZVertical = CMAttitudeReferenceFrame(rawValue: 1 << 1)
    public static let xMagneticNorthZVertical = CMAttitudeReferenceFrame(rawValue: 1 << 2)
    public static let xTrueNorthZVertical = CMAttitudeReferenceFrame(rawValue: 1 << 3)
}

public enum CMAuthorizationStatus: Int, Sendable, Hashable, BitwiseCopyable {
    case notDetermined = 0
    case restricted = 1
    case denied = 2
    case authorized = 3
}

public enum CMMagneticFieldCalibrationAccuracy: Int32, Sendable, Hashable, BitwiseCopyable {
    case uncalibrated = -1
    case low = 0
    case medium = 1
    case high = 2
}

public enum CMMotionActivityConfidence: Int, Sendable, Hashable, BitwiseCopyable {
    case low = 0
    case medium = 1
    case high = 2
}

public enum CMPedometerEventType: Int, Sendable, Hashable, BitwiseCopyable {
    case pause = 0
    case resume = 1
}

public enum CMOdometerOriginDevice: Int, Sendable, Hashable, BitwiseCopyable {
    case unknown = 0
    case local = 1
    case remote = 2
}

public enum CMHighFrequencyHeartRateDataConfidence: Int, Sendable, Hashable, BitwiseCopyable {
    case low = 0
    case medium = 1
    case high = 2
    case highest = 3
}

public struct CMAcceleration: Sendable, BitwiseCopyable {
    public var x: Double
    public var y: Double
    public var z: Double

    public init() {
        self.init(x: 0, y: 0, z: 0)
    }

    public init(x: Double, y: Double, z: Double) {
        self.x = x
        self.y = y
        self.z = z
    }
}

public struct CMRotationRate: Sendable, BitwiseCopyable {
    public var x: Double
    public var y: Double
    public var z: Double

    public init() {
        self.init(x: 0, y: 0, z: 0)
    }

    public init(x: Double, y: Double, z: Double) {
        self.x = x
        self.y = y
        self.z = z
    }
}

public struct CMMagneticField: Sendable, BitwiseCopyable {
    public var x: Double
    public var y: Double
    public var z: Double

    public init() {
        self.init(x: 0, y: 0, z: 0)
    }

    public init(x: Double, y: Double, z: Double) {
        self.x = x
        self.y = y
        self.z = z
    }
}

public struct CMQuaternion: Sendable, BitwiseCopyable {
    public var x: Double
    public var y: Double
    public var z: Double
    public var w: Double

    public init() {
        self.init(x: 0, y: 0, z: 0, w: 0)
    }

    public init(x: Double, y: Double, z: Double, w: Double) {
        self.x = x
        self.y = y
        self.z = z
        self.w = w
    }
}

public struct CMRotationMatrix: Sendable, BitwiseCopyable {
    public var m11: Double
    public var m12: Double
    public var m13: Double
    public var m21: Double
    public var m22: Double
    public var m23: Double
    public var m31: Double
    public var m32: Double
    public var m33: Double

    public init() {
        self.init(
            m11: 0, m12: 0, m13: 0,
            m21: 0, m22: 0, m23: 0,
            m31: 0, m32: 0, m33: 0
        )
    }

    public init(
        m11: Double, m12: Double, m13: Double,
        m21: Double, m22: Double, m23: Double,
        m31: Double, m32: Double, m33: Double
    ) {
        self.m11 = m11
        self.m12 = m12
        self.m13 = m13
        self.m21 = m21
        self.m22 = m22
        self.m23 = m23
        self.m31 = m31
        self.m32 = m32
        self.m33 = m33
    }
}

public struct CMCalibratedMagneticField: Sendable, BitwiseCopyable {
    public var field: CMMagneticField
    public var accuracy: CMMagneticFieldCalibrationAccuracy

    public init() {
        self.init(field: CMMagneticField(), accuracy: .low)
    }

    public init(field: CMMagneticField, accuracy: CMMagneticFieldCalibrationAccuracy) {
        self.field = field
        self.accuracy = accuracy
    }
}

public typealias CMAbsoluteAltitudeHandler = (CMAbsoluteAltitudeData?, (any Error)?) -> Void
public typealias CMAccelerometerHandler = (CMAccelerometerData?, (any Error)?) -> Void
public typealias CMAltitudeHandler = (CMAltitudeData?, (any Error)?) -> Void
public typealias CMDeviceMotionHandler = (CMDeviceMotion?, (any Error)?) -> Void
public typealias CMGyroHandler = (CMGyroData?, (any Error)?) -> Void
public typealias CMMagnetometerHandler = (CMMagnetometerData?, (any Error)?) -> Void
public typealias CMMotionActivityHandler = (CMMotionActivity?) -> Void
public typealias CMMotionActivityQueryHandler = ([CMMotionActivity]?, (any Error)?) -> Void
public typealias CMPedometerEventHandler = (CMPedometerEvent?, (any Error)?) -> Void
public typealias CMPedometerHandler = (CMPedometerData?, (any Error)?) -> Void
public typealias CMStepQueryHandler = (Int, (any Error)?) -> Void
public typealias CMStepUpdateHandler = (Int, Date, (any Error)?) -> Void

enum CoreMotionHostBoundary {
    /// Unobserved on Apple; Linux stores whatever the caller assigns.
    static let defaultUpdateInterval: TimeInterval = 0
    static let unavailable: Error = CMErrorNotAvailable
    /// Linux has no motion-privacy prompt path; authorization is fail-closed.
    static let authorization: CMAuthorizationStatus = .denied

    static func deliver<T>(
        _ value: T?,
        error: Error?,
        to queue: OperationQueue,
        handler: @escaping (T?, Error?) -> Void
    ) {
        queue.addOperation {
            handler(value, error)
        }
    }

    static func deliverUnavailable<T>(
        to queue: OperationQueue,
        handler: @escaping (T?, Error?) -> Void
    ) {
        deliver(nil, error: unavailable, to: queue, handler: handler)
    }
}

func cm_quaternionMultiply(_ lhs: CMQuaternion, _ rhs: CMQuaternion) -> CMQuaternion {
    CMQuaternion(
        x: lhs.w * rhs.x + lhs.x * rhs.w + lhs.y * rhs.z - lhs.z * rhs.y,
        y: lhs.w * rhs.y - lhs.x * rhs.z + lhs.y * rhs.w + lhs.z * rhs.x,
        z: lhs.w * rhs.z + lhs.x * rhs.y - lhs.y * rhs.x + lhs.z * rhs.w,
        w: lhs.w * rhs.w - lhs.x * rhs.x - lhs.y * rhs.y - lhs.z * rhs.z
    )
}

func cm_quaternionInverse(_ value: CMQuaternion) -> CMQuaternion {
    let norm = value.x * value.x + value.y * value.y + value.z * value.z + value.w * value.w
    guard norm > 0 else { return value }
    return CMQuaternion(
        x: -value.x / norm,
        y: -value.y / norm,
        z: -value.z / norm,
        w: value.w / norm
    )
}

/// Linux-internal Euler extraction for host-constructed attitudes. Apple's
/// Tait-Bryan convention is unobserved and must not be treated as parity.
func cm_euler(from quaternion: CMQuaternion) -> (roll: Double, pitch: Double, yaw: Double) {
    let x = quaternion.x
    let y = quaternion.y
    let z = quaternion.z
    let w = quaternion.w
    let sinRoll = 2 * (w * x + y * z)
    let cosRoll = 1 - 2 * (x * x + y * y)
    let roll = atan2(sinRoll, cosRoll)
    let sinPitch = max(-1, min(1, 2 * (w * y - z * x)))
    let pitch = asin(sinPitch)
    let sinYaw = 2 * (w * z + x * y)
    let cosYaw = 1 - 2 * (y * y + z * z)
    let yaw = atan2(sinYaw, cosYaw)
    return (roll, pitch, yaw)
}

/// Linux-internal matrix extraction. Apple's row/column convention is unobserved.
func cm_rotationMatrix(from quaternion: CMQuaternion) -> CMRotationMatrix {
    let x = quaternion.x
    let y = quaternion.y
    let z = quaternion.z
    let w = quaternion.w
    return CMRotationMatrix(
        m11: 1 - 2 * (y * y + z * z),
        m12: 2 * (x * y - z * w),
        m13: 2 * (x * z + y * w),
        m21: 2 * (x * y + z * w),
        m22: 1 - 2 * (x * x + z * z),
        m23: 2 * (y * z - x * w),
        m31: 2 * (x * z - y * w),
        m32: 2 * (y * z + x * w),
        m33: 1 - 2 * (x * x + y * y)
    )
}
