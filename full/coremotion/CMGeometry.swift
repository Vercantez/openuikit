import Foundation

// MARK: - Value types

public struct CMAcceleration: Equatable, Hashable, Sendable {
    public var x: Double
    public var y: Double
    public var z: Double

    public init(x: Double, y: Double, z: Double) {
        self.x = x
        self.y = y
        self.z = z
    }

    public init() {
        self.init(x: 0, y: 0, z: 0)
    }
}

public struct CMRotationRate: Equatable, Hashable, Sendable {
    public var x: Double
    public var y: Double
    public var z: Double

    public init(x: Double, y: Double, z: Double) {
        self.x = x
        self.y = y
        self.z = z
    }

    public init() {
        self.init(x: 0, y: 0, z: 0)
    }
}

public struct CMMagneticField: Equatable, Hashable, Sendable {
    public var x: Double
    public var y: Double
    public var z: Double

    public init(x: Double, y: Double, z: Double) {
        self.x = x
        self.y = y
        self.z = z
    }

    public init() {
        self.init(x: 0, y: 0, z: 0)
    }
}

public struct CMCalibratedMagneticField: Equatable, Hashable, Sendable {
    public var field: CMMagneticField
    public var accuracy: CMMagneticFieldCalibrationAccuracy

    public init(field: CMMagneticField, accuracy: CMMagneticFieldCalibrationAccuracy) {
        self.field = field
        self.accuracy = accuracy
    }

    public init() {
        self.init(field: CMMagneticField(), accuracy: .uncalibrated)
    }
}

/// Unit quaternion. Component layout is (x, y, z, w) as in the public graph.
/// Conversion to Euler angles uses this module's internal ZYX convention and
/// is not claimed to match Apple's unpublished convention.
public struct CMQuaternion: Equatable, Hashable, Sendable {
    public var x: Double
    public var y: Double
    public var z: Double
    public var w: Double

    public init(x: Double, y: Double, z: Double, w: Double) {
        self.x = x
        self.y = y
        self.z = z
        self.w = w
    }

    public init() {
        self.init(x: 0, y: 0, z: 0, w: 1)
    }

    var inverse: CMQuaternion {
        let n = x * x + y * y + z * z + w * w
        if n == 0 {
            return CMQuaternion()
        }
        let s = 1 / n
        return CMQuaternion(x: -x * s, y: -y * s, z: -z * s, w: w * s)
    }

    func multiplied(by other: CMQuaternion) -> CMQuaternion {
        CMQuaternion(
            x: w * other.x + x * other.w + y * other.z - z * other.y,
            y: w * other.y - x * other.z + y * other.w + z * other.x,
            z: w * other.z + x * other.y - y * other.x + z * other.w,
            w: w * other.w - x * other.x - y * other.y - z * other.z
        )
    }

    var normalized: CMQuaternion {
        let n = (x * x + y * y + z * z + w * w).squareRoot()
        if n == 0 {
            return CMQuaternion()
        }
        return CMQuaternion(x: x / n, y: y / n, z: z / n, w: w / n)
    }
}

public struct CMRotationMatrix: Equatable, Hashable, Sendable {
    public var m11: Double
    public var m12: Double
    public var m13: Double
    public var m21: Double
    public var m22: Double
    public var m23: Double
    public var m31: Double
    public var m32: Double
    public var m33: Double

    public init(
        m11: Double,
        m12: Double,
        m13: Double,
        m21: Double,
        m22: Double,
        m23: Double,
        m31: Double,
        m32: Double,
        m33: Double
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

    public init() {
        self.init(
            m11: 1, m12: 0, m13: 0,
            m21: 0, m22: 1, m23: 0,
            m31: 0, m32: 0, m33: 1
        )
    }
}

func coreMotionMatrix(from quaternion: CMQuaternion) -> CMRotationMatrix {
    let q = quaternion.normalized
    let x = q.x
    let y = q.y
    let z = q.z
    let w = q.w
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

func coreMotionQuaternion(from matrix: CMRotationMatrix) -> CMQuaternion {
    let trace = matrix.m11 + matrix.m22 + matrix.m33
    if trace > 0 {
        let s = 0.5 / (trace + 1).squareRoot()
        return CMQuaternion(
            x: (matrix.m32 - matrix.m23) * s,
            y: (matrix.m13 - matrix.m31) * s,
            z: (matrix.m21 - matrix.m12) * s,
            w: 0.25 / s
        ).normalized
    }
    if matrix.m11 > matrix.m22 && matrix.m11 > matrix.m33 {
        let s = 2 * (1 + matrix.m11 - matrix.m22 - matrix.m33).squareRoot()
        return CMQuaternion(
            x: 0.25 * s,
            y: (matrix.m12 + matrix.m21) / s,
            z: (matrix.m13 + matrix.m31) / s,
            w: (matrix.m32 - matrix.m23) / s
        ).normalized
    }
    if matrix.m22 > matrix.m33 {
        let s = 2 * (1 + matrix.m22 - matrix.m11 - matrix.m33).squareRoot()
        return CMQuaternion(
            x: (matrix.m12 + matrix.m21) / s,
            y: 0.25 * s,
            z: (matrix.m23 + matrix.m32) / s,
            w: (matrix.m13 - matrix.m31) / s
        ).normalized
    }
    let s = 2 * (1 + matrix.m33 - matrix.m11 - matrix.m22).squareRoot()
    return CMQuaternion(
        x: (matrix.m13 + matrix.m31) / s,
        y: (matrix.m23 + matrix.m32) / s,
        z: 0.25 * s,
        w: (matrix.m21 - matrix.m12) / s
    ).normalized
}

/// Internal ZYX Euler extraction. Not claimed to be Apple's convention.
func coreMotionEuler(from quaternion: CMQuaternion) -> (roll: Double, pitch: Double, yaw: Double) {
    let q = quaternion.normalized
    let sinp = 2 * (q.w * q.y - q.z * q.x)
    let pitch: Double
    if sinp.absValue >= 1 {
        pitch = (sinp > 0 ? 1 : -1) * Double.pi / 2
    } else {
        pitch = sinp.asinValue
    }
    let roll = (2 * (q.w * q.x + q.y * q.z)).atan2Value(1 - 2 * (q.x * q.x + q.y * q.y))
    let yaw = (2 * (q.w * q.z + q.x * q.y)).atan2Value(1 - 2 * (q.y * q.y + q.z * q.z))
    return (roll, pitch, yaw)
}

import Glibc

private extension Double {
    var absValue: Double { self < 0 ? -self : self }
    var asinValue: Double { asin(self) }
    func atan2Value(_ x: Double) -> Double { atan2(self, x) }
}

public final class CMAttitude: NSObject, NSSecureCoding, NSCopying {
    public static var supportsSecureCoding: Bool { true }

    private var storage: CMQuaternion

    public var quaternion: CMQuaternion { storage }

    public var rotationMatrix: CMRotationMatrix {
        coreMotionMatrix(from: storage)
    }

    public var roll: Double { coreMotionEuler(from: storage).roll }
    public var pitch: Double { coreMotionEuler(from: storage).pitch }
    public var yaw: Double { coreMotionEuler(from: storage).yaw }

    public override init() {
        storage = CMQuaternion()
        super.init()
    }

    init(quaternion: CMQuaternion) {
        storage = quaternion.normalized
        super.init()
    }

    public required init?(coder: NSCoder) {
        guard CoreMotionArchive.hasMarker(coder) else { return nil }
        storage = CMQuaternion(
            x: coder.decodeDouble(forKey: "qx"),
            y: coder.decodeDouble(forKey: "qy"),
            z: coder.decodeDouble(forKey: "qz"),
            w: coder.decodeDouble(forKey: "qw")
        )
        super.init()
    }

    public func encode(with coder: NSCoder) {
        CoreMotionArchive.encodeMarker(coder)
        coder.encode(storage.x, forKey: "qx")
        coder.encode(storage.y, forKey: "qy")
        coder.encode(storage.z, forKey: "qz")
        coder.encode(storage.w, forKey: "qw")
    }

    public func copy(with zone: NSZone? = nil) -> Any {
        CMAttitude(quaternion: storage)
    }

    public func multiply(byInverseOf attitude: CMAttitude) {
        storage = storage.multiplied(by: attitude.storage.inverse).normalized
    }
}
