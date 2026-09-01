import Foundation

#if canImport(CSceneKit)
@_exported import CSceneKit
#else
public struct SCNVector3: Sendable {
    public var x: Float
    public var y: Float
    public var z: Float

    public init() {
        x = 0
        y = 0
        z = 0
    }

    public init(x: Float, y: Float, z: Float) {
        self.x = x
        self.y = y
        self.z = z
    }
}

public struct SCNVector4: Sendable {
    public var x: Float
    public var y: Float
    public var z: Float
    public var w: Float

    public init() {
        x = 0
        y = 0
        z = 0
        w = 0
    }

    public init(x: Float, y: Float, z: Float, w: Float) {
        self.x = x
        self.y = y
        self.z = z
        self.w = w
    }
}

public struct SCNMatrix4: Sendable {
    public var m11: Float
    public var m12: Float
    public var m13: Float
    public var m14: Float
    public var m21: Float
    public var m22: Float
    public var m23: Float
    public var m24: Float
    public var m31: Float
    public var m32: Float
    public var m33: Float
    public var m34: Float
    public var m41: Float
    public var m42: Float
    public var m43: Float
    public var m44: Float

    public init() {
        m11 = 0; m12 = 0; m13 = 0; m14 = 0
        m21 = 0; m22 = 0; m23 = 0; m24 = 0
        m31 = 0; m32 = 0; m33 = 0; m34 = 0
        m41 = 0; m42 = 0; m43 = 0; m44 = 0
    }

    public init(
        m11: Float, m12: Float, m13: Float, m14: Float,
        m21: Float, m22: Float, m23: Float, m24: Float,
        m31: Float, m32: Float, m33: Float, m34: Float,
        m41: Float, m42: Float, m43: Float, m44: Float
    ) {
        self.m11 = m11; self.m12 = m12; self.m13 = m13; self.m14 = m14
        self.m21 = m21; self.m22 = m22; self.m23 = m23; self.m24 = m24
        self.m31 = m31; self.m32 = m32; self.m33 = m33; self.m34 = m34
        self.m41 = m41; self.m42 = m42; self.m43 = m43; self.m44 = m44
    }
}

public let SCNVector3Zero = SCNVector3()
public let SCNVector4Zero = SCNVector4()
public let SCNMatrix4Identity = SCNMatrix4(
    m11: 1, m12: 0, m13: 0, m14: 0,
    m21: 0, m22: 1, m23: 0, m24: 0,
    m31: 0, m32: 0, m33: 1, m34: 0,
    m41: 0, m42: 0, m43: 0, m44: 1
)

public func SCNVector3Make(_ x: Float, _ y: Float, _ z: Float) -> SCNVector3 {
    SCNVector3(x: x, y: y, z: z)
}

public func SCNVector4Make(_ x: Float, _ y: Float, _ z: Float, _ w: Float) -> SCNVector4 {
    SCNVector4(x: x, y: y, z: z, w: w)
}

public func SCNVector3EqualToVector3(_ a: SCNVector3, _ b: SCNVector3) -> Bool {
    a.x == b.x && a.y == b.y && a.z == b.z
}

public func SCNVector4EqualToVector4(_ a: SCNVector4, _ b: SCNVector4) -> Bool {
    a.x == b.x && a.y == b.y && a.z == b.z && a.w == b.w
}

public func SCNMatrix4EqualToMatrix4(_ a: SCNMatrix4, _ b: SCNMatrix4) -> Bool {
    a.m11 == b.m11 && a.m12 == b.m12 && a.m13 == b.m13 && a.m14 == b.m14
        && a.m21 == b.m21 && a.m22 == b.m22 && a.m23 == b.m23 && a.m24 == b.m24
        && a.m31 == b.m31 && a.m32 == b.m32 && a.m33 == b.m33 && a.m34 == b.m34
        && a.m41 == b.m41 && a.m42 == b.m42 && a.m43 == b.m43 && a.m44 == b.m44
}

public func SCNMatrix4IsIdentity(_ m: SCNMatrix4) -> Bool {
    SCNMatrix4EqualToMatrix4(m, SCNMatrix4Identity)
}

public func SCNMatrix4MakeTranslation(_ tx: Float, _ ty: Float, _ tz: Float) -> SCNMatrix4 {
    var m = SCNMatrix4Identity
    m.m41 = tx
    m.m42 = ty
    m.m43 = tz
    return m
}

public func SCNMatrix4MakeScale(_ sx: Float, _ sy: Float, _ sz: Float) -> SCNMatrix4 {
    var m = SCNMatrix4Identity
    m.m11 = sx
    m.m22 = sy
    m.m33 = sz
    return m
}

public func SCNMatrix4MakeRotation(_ angle: Float, _ x: Float, _ y: Float, _ z: Float) -> SCNMatrix4 {
    let axis = _scnNormalize(SCNVector3(x, y, z))
    let c = cos(angle)
    let s = sin(angle)
    let t = 1 - c
    let ax = axis.x, ay = axis.y, az = axis.z
    return SCNMatrix4(
        m11: t * ax * ax + c,      m12: t * ax * ay + s * az, m13: t * ax * az - s * ay, m14: 0,
        m21: t * ax * ay - s * az, m22: t * ay * ay + c,      m23: t * ay * az + s * ax, m24: 0,
        m31: t * ax * az + s * ay, m32: t * ay * az - s * ax, m33: t * az * az + c,      m34: 0,
        m41: 0, m42: 0, m43: 0, m44: 1
    )
}

public func SCNMatrix4Translate(_ m: SCNMatrix4, _ tx: Float, _ ty: Float, _ tz: Float) -> SCNMatrix4 {
    SCNMatrix4Mult(SCNMatrix4MakeTranslation(tx, ty, tz), m)
}

public func SCNMatrix4Scale(_ m: SCNMatrix4, _ sx: Float, _ sy: Float, _ sz: Float) -> SCNMatrix4 {
    SCNMatrix4Mult(SCNMatrix4MakeScale(sx, sy, sz), m)
}

public func SCNMatrix4Rotate(_ m: SCNMatrix4, _ angle: Float, _ x: Float, _ y: Float, _ z: Float) -> SCNMatrix4 {
    SCNMatrix4Mult(SCNMatrix4MakeRotation(angle, x, y, z), m)
}

public func SCNMatrix4Mult(_ a: SCNMatrix4, _ b: SCNMatrix4) -> SCNMatrix4 {
    func dot(_ row: (Float, Float, Float, Float), _ col: (Float, Float, Float, Float)) -> Float {
        row.0 * col.0 + row.1 * col.1 + row.2 * col.2 + row.3 * col.3
    }
    let r1 = (a.m11, a.m21, a.m31, a.m41)
    let r2 = (a.m12, a.m22, a.m32, a.m42)
    let r3 = (a.m13, a.m23, a.m33, a.m43)
    let r4 = (a.m14, a.m24, a.m34, a.m44)
    let c1 = (b.m11, b.m12, b.m13, b.m14)
    let c2 = (b.m21, b.m22, b.m23, b.m24)
    let c3 = (b.m31, b.m32, b.m33, b.m34)
    let c4 = (b.m41, b.m42, b.m43, b.m44)
    return SCNMatrix4(
        m11: dot(c1, r1), m12: dot(c1, r2), m13: dot(c1, r3), m14: dot(c1, r4),
        m21: dot(c2, r1), m22: dot(c2, r2), m23: dot(c2, r3), m24: dot(c2, r4),
        m31: dot(c3, r1), m32: dot(c3, r2), m33: dot(c3, r3), m34: dot(c3, r4),
        m41: dot(c4, r1), m42: dot(c4, r2), m43: dot(c4, r3), m44: dot(c4, r4)
    )
}

public func SCNMatrix4Invert(_ m: SCNMatrix4) -> SCNMatrix4 {
    var a: [[Float]] = [
        [m.m11, m.m12, m.m13, m.m14],
        [m.m21, m.m22, m.m23, m.m24],
        [m.m31, m.m32, m.m33, m.m34],
        [m.m41, m.m42, m.m43, m.m44]
    ]
    var inv = [[Float]](repeating: [Float](repeating: 0, count: 4), count: 4)
    for i in 0..<4 { inv[i][i] = 1 }

    for i in 0..<4 {
        var pivot = i
        var best = abs(a[i][i])
        for r in (i + 1)..<4 {
            let value = abs(a[r][i])
            if value > best {
                best = value
                pivot = r
            }
        }
        if best < 1e-8 {
            return SCNMatrix4Identity
        }
        if pivot != i {
            a.swapAt(i, pivot)
            inv.swapAt(i, pivot)
        }
        let diag = a[i][i]
        for c in 0..<4 {
            a[i][c] /= diag
            inv[i][c] /= diag
        }
        for r in 0..<4 where r != i {
            let factor = a[r][i]
            for c in 0..<4 {
                a[r][c] -= factor * a[i][c]
                inv[r][c] -= factor * inv[i][c]
            }
        }
    }
    return SCNMatrix4(
        m11: inv[0][0], m12: inv[0][1], m13: inv[0][2], m14: inv[0][3],
        m21: inv[1][0], m22: inv[1][1], m23: inv[1][2], m24: inv[1][3],
        m31: inv[2][0], m32: inv[2][1], m33: inv[2][2], m34: inv[2][3],
        m41: inv[3][0], m42: inv[3][1], m43: inv[3][2], m44: inv[3][3]
    )
}
#endif

extension SCNVector3: Equatable, Hashable {
    public init(_ x: Float, _ y: Float, _ z: Float) {
        self.init(x: x, y: y, z: z)
    }

    public init(_ x: Double, _ y: Double, _ z: Double) {
        self.init(x: Float(x), y: Float(y), z: Float(z))
    }

    public init(_ x: CGFloat, _ y: CGFloat, _ z: CGFloat) {
        self.init(x: Float(x), y: Float(y), z: Float(z))
    }

    public init(_ x: Int, _ y: Int, _ z: Int) {
        self.init(x: Float(x), y: Float(y), z: Float(z))
    }

    public init(_ v: SIMD3<Double>) {
        self.init(x: Float(v.x), y: Float(v.y), z: Float(v.z))
    }

    public init(_ v: SIMD3<Float>) {
        self.init(x: v.x, y: v.y, z: v.z)
    }

    public static func == (lhs: SCNVector3, rhs: SCNVector3) -> Bool {
        SCNVector3EqualToVector3(lhs, rhs)
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(x)
        hasher.combine(y)
        hasher.combine(z)
    }
}

extension SCNVector4: Equatable, Hashable {
    public init(_ x: Float, _ y: Float, _ z: Float, _ w: Float) {
        self.init(x: x, y: y, z: z, w: w)
    }

    public init(_ x: Double, _ y: Double, _ z: Double, _ w: Double) {
        self.init(x: Float(x), y: Float(y), z: Float(z), w: Float(w))
    }

    public init(_ x: CGFloat, _ y: CGFloat, _ z: CGFloat, _ w: CGFloat) {
        self.init(x: Float(x), y: Float(y), z: Float(z), w: Float(w))
    }

    public init(_ x: Int, _ y: Int, _ z: Int, _ w: Int) {
        self.init(x: Float(x), y: Float(y), z: Float(z), w: Float(w))
    }

    public init(_ v: SIMD4<Double>) {
        self.init(x: Float(v.x), y: Float(v.y), z: Float(v.z), w: Float(v.w))
    }

    public init(_ v: SIMD4<Float>) {
        self.init(x: v.x, y: v.y, z: v.z, w: v.w)
    }

    public static func == (lhs: SCNVector4, rhs: SCNVector4) -> Bool {
        SCNVector4EqualToVector4(lhs, rhs)
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(x)
        hasher.combine(y)
        hasher.combine(z)
        hasher.combine(w)
    }
}

extension SCNMatrix4: Equatable {
    public static func == (lhs: SCNMatrix4, rhs: SCNMatrix4) -> Bool {
        SCNMatrix4EqualToMatrix4(lhs, rhs)
    }
}

#if canImport(simd)
import simd

extension SCNMatrix4 {
    public init(_ m: simd_float4x4) {
        m11 = m.columns.0.x; m12 = m.columns.1.x; m13 = m.columns.2.x; m14 = m.columns.3.x
        m21 = m.columns.0.y; m22 = m.columns.1.y; m23 = m.columns.2.y; m24 = m.columns.3.y
        m31 = m.columns.0.z; m32 = m.columns.1.z; m33 = m.columns.2.z; m34 = m.columns.3.z
        m41 = m.columns.0.w; m42 = m.columns.1.w; m43 = m.columns.2.w; m44 = m.columns.3.w
    }
}

func _scnSimd3(_ v: SCNVector3) -> simd_float3 {
    simd_float3(v.x, v.y, v.z)
}

func _scnSimd4(_ v: SCNVector4) -> simd_float4 {
    simd_float4(v.x, v.y, v.z, v.w)
}

func _scnSimdQuat(_ q: SCNQuaternion) -> simd_quatf {
    simd_quatf(ix: q.x, iy: q.y, iz: q.z, r: q.w)
}

func _scnFromSimd3(_ v: simd_float3) -> SCNVector3 {
    SCNVector3(v.x, v.y, v.z)
}

func _scnFromSimdQuat(_ q: simd_quatf) -> SCNQuaternion {
    SCNVector4(q.vector.x, q.vector.y, q.vector.z, q.vector.w)
}

func _scnSimdMatrix(_ m: SCNMatrix4) -> simd_float4x4 {
    simd_float4x4(
        simd_float4(m.m11, m.m21, m.m31, m.m41),
        simd_float4(m.m12, m.m22, m.m32, m.m42),
        simd_float4(m.m13, m.m23, m.m33, m.m43),
        simd_float4(m.m14, m.m24, m.m34, m.m44)
    )
}

func _scnFromSimdMatrix(_ m: simd_float4x4) -> SCNMatrix4 {
    SCNMatrix4(m)
}
#endif

func _scnLength(_ v: SCNVector3) -> Float {
    sqrt(v.x * v.x + v.y * v.y + v.z * v.z)
}

func _scnNormalize(_ v: SCNVector3) -> SCNVector3 {
    let length = _scnLength(v)
    if length < 1e-8 { return SCNVector3(0, 0, 1) }
    return SCNVector3(v.x / length, v.y / length, v.z / length)
}

func _scnDot(_ a: SCNVector3, _ b: SCNVector3) -> Float {
    a.x * b.x + a.y * b.y + a.z * b.z
}

func _scnCross(_ a: SCNVector3, _ b: SCNVector3) -> SCNVector3 {
    SCNVector3(
        a.y * b.z - a.z * b.y,
        a.z * b.x - a.x * b.z,
        a.x * b.y - a.y * b.x
    )
}

func _scnAdd(_ a: SCNVector3, _ b: SCNVector3) -> SCNVector3 {
    SCNVector3(a.x + b.x, a.y + b.y, a.z + b.z)
}

func _scnSub(_ a: SCNVector3, _ b: SCNVector3) -> SCNVector3 {
    SCNVector3(a.x - b.x, a.y - b.y, a.z - b.z)
}

func _scnScale(_ v: SCNVector3, _ s: Float) -> SCNVector3 {
    SCNVector3(v.x * s, v.y * s, v.z * s)
}

func _scnLerp(_ a: SCNVector3, _ b: SCNVector3, _ t: Float) -> SCNVector3 {
    _scnAdd(a, _scnScale(_scnSub(b, a), t))
}

func _scnQuaternionIdentity() -> SCNQuaternion {
    SCNVector4(0, 0, 0, 1)
}

func _scnQuaternionNormalize(_ q: SCNQuaternion) -> SCNQuaternion {
    let length = sqrt(q.x * q.x + q.y * q.y + q.z * q.z + q.w * q.w)
    if length < 1e-8 { return _scnQuaternionIdentity() }
    return SCNVector4(q.x / length, q.y / length, q.z / length, q.w / length)
}

func _scnQuaternionMultiply(_ a: SCNQuaternion, _ b: SCNQuaternion) -> SCNQuaternion {
    SCNVector4(
        a.w * b.x + a.x * b.w + a.y * b.z - a.z * b.y,
        a.w * b.y - a.x * b.z + a.y * b.w + a.z * b.x,
        a.w * b.z + a.x * b.y - a.y * b.x + a.z * b.w,
        a.w * b.w - a.x * b.x - a.y * b.y - a.z * b.z
    )
}

func _scnQuaternionFromAxisAngle(_ axis: SCNVector3, _ angle: Float) -> SCNQuaternion {
    let n = _scnNormalize(axis)
    let half = angle * 0.5
    let s = sin(half)
    return SCNVector4(n.x * s, n.y * s, n.z * s, cos(half))
}

func _scnAxisAngleFromQuaternion(_ q: SCNQuaternion) -> SCNVector4 {
    let nq = _scnQuaternionNormalize(q)
    let angle = 2 * acos(max(-1, min(1, nq.w)))
    let s = sqrt(max(0, 1 - nq.w * nq.w))
    if s < 1e-6 {
        return SCNVector4(1, 0, 0, 0)
    }
    return SCNVector4(nq.x / s, nq.y / s, nq.z / s, angle)
}

func _scnQuaternionFromEuler(_ euler: SCNVector3) -> SCNQuaternion {
    let hx = euler.x * 0.5
    let hy = euler.y * 0.5
    let hz = euler.z * 0.5
    let cx = cos(hx), sx = sin(hx)
    let cy = cos(hy), sy = sin(hy)
    let cz = cos(hz), sz = sin(hz)
    return SCNVector4(
        sx * cy * cz - cx * sy * sz,
        cx * sy * cz + sx * cy * sz,
        cx * cy * sz - sx * sy * cz,
        cx * cy * cz + sx * sy * sz
    )
}

func _scnEulerFromQuaternion(_ q: SCNQuaternion) -> SCNVector3 {
    let nq = _scnQuaternionNormalize(q)
    let sinp = 2 * (nq.w * nq.y - nq.z * nq.x)
    let pitch: Float
    if abs(sinp) >= 1 {
        pitch = copysign(.pi / 2, sinp)
    } else {
        pitch = asin(sinp)
    }
    let roll = atan2(2 * (nq.w * nq.x + nq.y * nq.z), 1 - 2 * (nq.x * nq.x + nq.y * nq.y))
    let yaw = atan2(2 * (nq.w * nq.z + nq.x * nq.y), 1 - 2 * (nq.y * nq.y + nq.z * nq.z))
    return SCNVector3(roll, pitch, yaw)
}

func _scnMatrixFromQuaternion(_ q: SCNQuaternion) -> SCNMatrix4 {
    let nq = _scnQuaternionNormalize(q)
    let x = nq.x, y = nq.y, z = nq.z, w = nq.w
    let xx = x * x, yy = y * y, zz = z * z
    let xy = x * y, xz = x * z, yz = y * z
    let wx = w * x, wy = w * y, wz = w * z
    return SCNMatrix4(
        m11: 1 - 2 * (yy + zz), m12: 2 * (xy + wz),     m13: 2 * (xz - wy),     m14: 0,
        m21: 2 * (xy - wz),     m22: 1 - 2 * (xx + zz), m23: 2 * (yz + wx),     m24: 0,
        m31: 2 * (xz + wy),     m32: 2 * (yz - wx),     m33: 1 - 2 * (xx + yy), m34: 0,
        m41: 0, m42: 0, m43: 0, m44: 1
    )
}

func _scnComposeTransform(position: SCNVector3, orientation: SCNQuaternion, scale: SCNVector3, pivot: SCNMatrix4) -> SCNMatrix4 {
    let t = SCNMatrix4MakeTranslation(position.x, position.y, position.z)
    let r = _scnMatrixFromQuaternion(orientation)
    let s = SCNMatrix4MakeScale(scale.x, scale.y, scale.z)
    let trs = SCNMatrix4Mult(t, SCNMatrix4Mult(r, s))
    if SCNMatrix4IsIdentity(pivot) {
        return trs
    }
    return SCNMatrix4Mult(trs, SCNMatrix4Invert(pivot))
}

func _scnDecomposeTransform(_ m: SCNMatrix4) -> (SCNVector3, SCNQuaternion, SCNVector3) {
    let translation = SCNVector3(m.m41, m.m42, m.m43)
    var axisX = SCNVector3(m.m11, m.m21, m.m31)
    var axisY = SCNVector3(m.m12, m.m22, m.m32)
    var axisZ = SCNVector3(m.m13, m.m23, m.m33)
    var scale = SCNVector3(_scnLength(axisX), _scnLength(axisY), _scnLength(axisZ))
    if scale.x > 1e-8 { axisX = _scnScale(axisX, 1 / scale.x) }
    if scale.y > 1e-8 { axisY = _scnScale(axisY, 1 / scale.y) }
    if scale.z > 1e-8 { axisZ = _scnScale(axisZ, 1 / scale.z) }
    if _scnDot(_scnCross(axisX, axisY), axisZ) < 0 {
        scale.x *= -1
        axisX = _scnScale(axisX, -1)
    }
    let rot = SCNMatrix4(
        m11: axisX.x, m12: axisY.x, m13: axisZ.x, m14: 0,
        m21: axisX.y, m22: axisY.y, m23: axisZ.y, m24: 0,
        m31: axisX.z, m32: axisY.z, m33: axisZ.z, m34: 0,
        m41: 0, m42: 0, m43: 0, m44: 1
    )
    let trace = rot.m11 + rot.m22 + rot.m33
    let q: SCNQuaternion
    if trace > 0 {
        let s = sqrt(trace + 1) * 2
        q = SCNVector4(
            (rot.m32 - rot.m23) / s,
            (rot.m13 - rot.m31) / s,
            (rot.m21 - rot.m12) / s,
            0.25 * s
        )
    } else if rot.m11 > rot.m22 && rot.m11 > rot.m33 {
        let s = sqrt(1 + rot.m11 - rot.m22 - rot.m33) * 2
        q = SCNVector4(
            0.25 * s,
            (rot.m12 + rot.m21) / s,
            (rot.m13 + rot.m31) / s,
            (rot.m32 - rot.m23) / s
        )
    } else if rot.m22 > rot.m33 {
        let s = sqrt(1 + rot.m22 - rot.m11 - rot.m33) * 2
        q = SCNVector4(
            (rot.m12 + rot.m21) / s,
            0.25 * s,
            (rot.m23 + rot.m32) / s,
            (rot.m13 - rot.m31) / s
        )
    } else {
        let s = sqrt(1 + rot.m33 - rot.m11 - rot.m22) * 2
        q = SCNVector4(
            (rot.m13 + rot.m31) / s,
            (rot.m23 + rot.m32) / s,
            0.25 * s,
            (rot.m21 - rot.m12) / s
        )
    }
    return (translation, _scnQuaternionNormalize(q), scale)
}

func _scnTransformPoint(_ m: SCNMatrix4, _ p: SCNVector3) -> SCNVector3 {
    SCNVector3(
        m.m11 * p.x + m.m21 * p.y + m.m31 * p.z + m.m41,
        m.m12 * p.x + m.m22 * p.y + m.m32 * p.z + m.m42,
        m.m13 * p.x + m.m23 * p.y + m.m33 * p.z + m.m43
    )
}

func _scnTransformVector(_ m: SCNMatrix4, _ v: SCNVector3) -> SCNVector3 {
    SCNVector3(
        m.m11 * v.x + m.m21 * v.y + m.m31 * v.z,
        m.m12 * v.x + m.m22 * v.y + m.m32 * v.z,
        m.m13 * v.x + m.m23 * v.y + m.m33 * v.z
    )
}

func _scnLookRotation(direction: SCNVector3, up: SCNVector3, localFront: SCNVector3) -> SCNQuaternion {
    let targetDir = _scnNormalize(direction)
    let from = _scnNormalize(localFront)
    let dot = max(-1, min(1, _scnDot(from, targetDir)))
    if dot > 0.999999 {
        return _scnQuaternionIdentity()
    }
    if dot < -0.999999 {
        let axis = _scnNormalize(_scnCross(up, from))
        return _scnQuaternionFromAxisAngle(axis, .pi)
    }
    let axis = _scnNormalize(_scnCross(from, targetDir))
    return _scnQuaternionFromAxisAngle(axis, acos(dot))
}

func _scnPerspectiveMatrix(fieldOfViewDegrees: Float, aspect: Float, zNear: Float, zFar: Float, vertical: Bool) -> SCNMatrix4 {
    let safeAspect = aspect == 0 ? 1 : aspect
    let fov = fieldOfViewDegrees * Float.pi / 180
    let f: Float
    if vertical {
        f = 1 / tan(fov * 0.5)
        return SCNMatrix4(
            m11: f / safeAspect, m12: 0, m13: 0, m14: 0,
            m21: 0, m22: f, m23: 0, m24: 0,
            m31: 0, m32: 0, m33: (zFar + zNear) / (zNear - zFar), m34: -1,
            m41: 0, m42: 0, m43: (2 * zFar * zNear) / (zNear - zFar), m44: 0
        )
    }
    f = 1 / tan(fov * 0.5)
    return SCNMatrix4(
        m11: f, m12: 0, m13: 0, m14: 0,
        m21: 0, m22: f * safeAspect, m23: 0, m24: 0,
        m31: 0, m32: 0, m33: (zFar + zNear) / (zNear - zFar), m34: -1,
        m41: 0, m42: 0, m43: (2 * zFar * zNear) / (zNear - zFar), m44: 0
    )
}

func _scnOrthographicMatrix(scale: Float, aspect: Float, zNear: Float, zFar: Float) -> SCNMatrix4 {
    let safeAspect = aspect == 0 ? 1 : aspect
    let right = scale * safeAspect
    let top = scale
    return SCNMatrix4(
        m11: 1 / right, m12: 0, m13: 0, m14: 0,
        m21: 0, m22: 1 / top, m23: 0, m24: 0,
        m31: 0, m32: 0, m33: -2 / (zFar - zNear), m34: 0,
        m41: 0, m42: 0, m43: -(zFar + zNear) / (zFar - zNear), m44: 1
    )
}

func _scnRayHitsAABB(origin: SCNVector3, direction: SCNVector3, minBound: SCNVector3, maxBound: SCNVector3) -> Float? {
    func slab(_ origin: Float, _ dir: Float, _ minB: Float, _ maxB: Float) -> (Float, Float)? {
        if abs(dir) < 1e-8 {
            if origin < minB || origin > maxB { return nil }
            return (-Float.greatestFiniteMagnitude, Float.greatestFiniteMagnitude)
        }
        var t1 = (minB - origin) / dir
        var t2 = (maxB - origin) / dir
        if t1 > t2 { swap(&t1, &t2) }
        return (t1, t2)
    }
    guard let x = slab(origin.x, direction.x, minBound.x, maxBound.x),
          let y = slab(origin.y, direction.y, minBound.y, maxBound.y),
          let z = slab(origin.z, direction.z, minBound.z, maxBound.z) else {
        return nil
    }
    let tMin = max(x.0, y.0, z.0)
    let tMax = min(x.1, y.1, z.1)
    if tMax < tMin { return nil }
    if tMax < 0 { return nil }
    return tMin >= 0 ? tMin : tMax
}
