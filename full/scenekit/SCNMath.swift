import Foundation

public struct SCNVector3: Equatable, Sendable {
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

    public init(_ v: SIMD3<Float>) {
        self.init(x: v.x, y: v.y, z: v.z)
    }

    public init(_ v: SIMD3<Double>) {
        self.init(x: Float(v.x), y: Float(v.y), z: Float(v.z))
    }
}

public struct SCNVector4: Equatable, Sendable {
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

    public init(_ v: SIMD4<Float>) {
        self.init(x: v.x, y: v.y, z: v.z, w: v.w)
    }

    public init(_ v: SIMD4<Double>) {
        self.init(x: Float(v.x), y: Float(v.y), z: Float(v.z), w: Float(v.w))
    }
}

public struct SCNMatrix4: Equatable, Sendable {
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
        m11 = 1; m12 = 0; m13 = 0; m14 = 0
        m21 = 0; m22 = 1; m23 = 0; m24 = 0
        m31 = 0; m32 = 0; m33 = 1; m34 = 0
        m41 = 0; m42 = 0; m43 = 0; m44 = 1
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

#if canImport(simd)
    public init(_ m: simd_float4x4) {
        self.init(
            m11: m.columns.0.x, m12: m.columns.0.y, m13: m.columns.0.z, m14: m.columns.0.w,
            m21: m.columns.1.x, m22: m.columns.1.y, m23: m.columns.1.z, m24: m.columns.1.w,
            m31: m.columns.2.x, m32: m.columns.2.y, m33: m.columns.2.z, m34: m.columns.2.w,
            m41: m.columns.3.x, m42: m.columns.3.y, m43: m.columns.3.z, m44: m.columns.3.w
        )
    }

    public init(_ m: simd_double4x4) {
        self.init(simd_float4x4(m))
    }
#endif
}

#if canImport(simd)
extension simd_float4x4 {
    public init(_ m: SCNMatrix4) {
        self.init(columns: (
            SIMD4(m.m11, m.m12, m.m13, m.m14),
            SIMD4(m.m21, m.m22, m.m23, m.m24),
            SIMD4(m.m31, m.m32, m.m33, m.m34),
            SIMD4(m.m41, m.m42, m.m43, m.m44)
        ))
    }
}

extension simd_double4x4 {
    public init(_ m: SCNMatrix4) {
        self.init(simd_float4x4(m))
    }
}
#endif

public let SCNVector3Zero = SCNVector3()
public let SCNVector4Zero = SCNVector4()
public let SCNMatrix4Identity = SCNMatrix4()

public func SCNVector3Make(_ x: Float, _ y: Float, _ z: Float) -> SCNVector3 {
    SCNVector3(x: x, y: y, z: z)
}

public func SCNVector3EqualToVector3(_ a: SCNVector3, _ b: SCNVector3) -> Bool {
    a == b
}

public func SCNVector4Make(_ x: Float, _ y: Float, _ z: Float, _ w: Float) -> SCNVector4 {
    SCNVector4(x: x, y: y, z: z, w: w)
}

public func SCNVector4EqualToVector4(_ a: SCNVector4, _ b: SCNVector4) -> Bool {
    a == b
}

public func SCNMatrix4EqualToMatrix4(_ a: SCNMatrix4, _ b: SCNMatrix4) -> Bool {
    a == b
}

public func SCNMatrix4IsIdentity(_ m: SCNMatrix4) -> Bool {
    m == SCNMatrix4Identity
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
    let len = (x * x + y * y + z * z).squareRoot()
    if len == 0 {
        return SCNMatrix4Identity
    }
    let ax = x / len
    let ay = y / len
    let az = z / len
    let c = cos(angle)
    let s = sin(angle)
    let t = 1 - c
    return SCNMatrix4(
        m11: t * ax * ax + c,      m12: t * ax * ay + s * az,  m13: t * ax * az - s * ay,  m14: 0,
        m21: t * ax * ay - s * az,  m22: t * ay * ay + c,      m23: t * ay * az + s * ax,  m24: 0,
        m31: t * ax * az + s * ay,  m32: t * ay * az - s * ax,  m33: t * az * az + c,      m34: 0,
        m41: 0, m42: 0, m43: 0, m44: 1
    )
}

/// Product C = A * B. With this port's row-vector transform
/// `p' = p * M`, `SCNMatrix4Mult(A, B)` applies A then B.
public func SCNMatrix4Mult(_ a: SCNMatrix4, _ b: SCNMatrix4) -> SCNMatrix4 {
    func dot(_ aRow: (Float, Float, Float, Float), _ col: (Float, Float, Float, Float)) -> Float {
        aRow.0 * col.0 + aRow.1 * col.1 + aRow.2 * col.2 + aRow.3 * col.3
    }
    // Treat struct rows as (m11 m12 m13 m14) etc. Multiply as row-vector layout
    // matching CATransform3D / SCNMatrix4 field names.
    let r1 = (a.m11, a.m12, a.m13, a.m14)
    let r2 = (a.m21, a.m22, a.m23, a.m24)
    let r3 = (a.m31, a.m32, a.m33, a.m34)
    let r4 = (a.m41, a.m42, a.m43, a.m44)
    let c1 = (b.m11, b.m21, b.m31, b.m41)
    let c2 = (b.m12, b.m22, b.m32, b.m42)
    let c3 = (b.m13, b.m23, b.m33, b.m43)
    let c4 = (b.m14, b.m24, b.m34, b.m44)
    return SCNMatrix4(
        m11: dot(r1, c1), m12: dot(r1, c2), m13: dot(r1, c3), m14: dot(r1, c4),
        m21: dot(r2, c1), m22: dot(r2, c2), m23: dot(r2, c3), m24: dot(r2, c4),
        m31: dot(r3, c1), m32: dot(r3, c2), m33: dot(r3, c3), m34: dot(r3, c4),
        m41: dot(r4, c1), m42: dot(r4, c2), m43: dot(r4, c3), m44: dot(r4, c4)
    )
}

public func SCNMatrix4Translate(_ m: SCNMatrix4, _ tx: Float, _ ty: Float, _ tz: Float) -> SCNMatrix4 {
    SCNMatrix4Mult(m, SCNMatrix4MakeTranslation(tx, ty, tz))
}

public func SCNMatrix4Scale(_ m: SCNMatrix4, _ sx: Float, _ sy: Float, _ sz: Float) -> SCNMatrix4 {
    SCNMatrix4Mult(m, SCNMatrix4MakeScale(sx, sy, sz))
}

public func SCNMatrix4Rotate(_ m: SCNMatrix4, _ angle: Float, _ x: Float, _ y: Float, _ z: Float) -> SCNMatrix4 {
    SCNMatrix4Mult(m, SCNMatrix4MakeRotation(angle, x, y, z))
}

public func SCNMatrix4Invert(_ m: SCNMatrix4) -> SCNMatrix4 {
    let a = [
        [m.m11, m.m12, m.m13, m.m14],
        [m.m21, m.m22, m.m23, m.m24],
        [m.m31, m.m32, m.m33, m.m34],
        [m.m41, m.m42, m.m43, m.m44]
    ]
    var inv = [[Float]](repeating: [Float](repeating: 0, count: 4), count: 4)
    inv[0][0] = a[1][1] * a[2][2] * a[3][3] - a[1][1] * a[2][3] * a[3][2] - a[2][1] * a[1][2] * a[3][3]
        + a[2][1] * a[1][3] * a[3][2] + a[3][1] * a[1][2] * a[2][3] - a[3][1] * a[1][3] * a[2][2]
    inv[0][1] = -a[0][1] * a[2][2] * a[3][3] + a[0][1] * a[2][3] * a[3][2] + a[2][1] * a[0][2] * a[3][3]
        - a[2][1] * a[0][3] * a[3][2] - a[3][1] * a[0][2] * a[2][3] + a[3][1] * a[0][3] * a[2][2]
    inv[0][2] = a[0][1] * a[1][2] * a[3][3] - a[0][1] * a[1][3] * a[3][2] - a[1][1] * a[0][2] * a[3][3]
        + a[1][1] * a[0][3] * a[3][2] + a[3][1] * a[0][2] * a[1][3] - a[3][1] * a[0][3] * a[1][2]
    inv[0][3] = -a[0][1] * a[1][2] * a[2][3] + a[0][1] * a[1][3] * a[2][2] + a[1][1] * a[0][2] * a[2][3]
        - a[1][1] * a[0][3] * a[2][2] - a[2][1] * a[0][2] * a[1][3] + a[2][1] * a[0][3] * a[1][2]
    inv[1][0] = -a[1][0] * a[2][2] * a[3][3] + a[1][0] * a[2][3] * a[3][2] + a[2][0] * a[1][2] * a[3][3]
        - a[2][0] * a[1][3] * a[3][2] - a[3][0] * a[1][2] * a[2][3] + a[3][0] * a[1][3] * a[2][2]
    inv[1][1] = a[0][0] * a[2][2] * a[3][3] - a[0][0] * a[2][3] * a[3][2] - a[2][0] * a[0][2] * a[3][3]
        + a[2][0] * a[0][3] * a[3][2] + a[3][0] * a[0][2] * a[2][3] - a[3][0] * a[0][3] * a[2][2]
    inv[1][2] = -a[0][0] * a[1][2] * a[3][3] + a[0][0] * a[1][3] * a[3][2] + a[1][0] * a[0][2] * a[3][3]
        - a[1][0] * a[0][3] * a[3][2] - a[3][0] * a[0][2] * a[1][3] + a[3][0] * a[0][3] * a[1][2]
    inv[1][3] = a[0][0] * a[1][2] * a[2][3] - a[0][0] * a[1][3] * a[2][2] - a[1][0] * a[0][2] * a[2][3]
        + a[1][0] * a[0][3] * a[2][2] + a[2][0] * a[0][2] * a[1][3] - a[2][0] * a[0][3] * a[1][2]
    inv[2][0] = a[1][0] * a[2][1] * a[3][3] - a[1][0] * a[2][3] * a[3][1] - a[2][0] * a[1][1] * a[3][3]
        + a[2][0] * a[1][3] * a[3][1] + a[3][0] * a[1][1] * a[2][3] - a[3][0] * a[1][3] * a[2][1]
    inv[2][1] = -a[0][0] * a[2][1] * a[3][3] + a[0][0] * a[2][3] * a[3][1] + a[2][0] * a[0][1] * a[3][3]
        - a[2][0] * a[0][3] * a[3][1] - a[3][0] * a[0][1] * a[2][3] + a[3][0] * a[0][3] * a[2][1]
    inv[2][2] = a[0][0] * a[1][1] * a[3][3] - a[0][0] * a[1][3] * a[3][1] - a[1][0] * a[0][1] * a[3][3]
        + a[1][0] * a[0][3] * a[3][1] + a[3][0] * a[0][1] * a[1][3] - a[3][0] * a[0][3] * a[1][1]
    inv[2][3] = -a[0][0] * a[1][1] * a[2][3] + a[0][0] * a[1][3] * a[2][1] + a[1][0] * a[0][1] * a[2][3]
        - a[1][0] * a[0][3] * a[2][1] - a[2][0] * a[0][1] * a[1][3] + a[2][0] * a[0][3] * a[1][1]
    inv[3][0] = -a[1][0] * a[2][1] * a[3][2] + a[1][0] * a[2][2] * a[3][1] + a[2][0] * a[1][1] * a[3][2]
        - a[2][0] * a[1][2] * a[3][1] - a[3][0] * a[1][1] * a[2][2] + a[3][0] * a[1][2] * a[2][1]
    inv[3][1] = a[0][0] * a[2][1] * a[3][2] - a[0][0] * a[2][2] * a[3][1] - a[2][0] * a[0][1] * a[3][2]
        + a[2][0] * a[0][2] * a[3][1] + a[3][0] * a[0][1] * a[2][2] - a[3][0] * a[0][2] * a[2][1]
    inv[3][2] = -a[0][0] * a[1][1] * a[3][2] + a[0][0] * a[1][2] * a[3][1] + a[1][0] * a[0][1] * a[3][2]
        - a[1][0] * a[0][2] * a[3][1] - a[3][0] * a[0][1] * a[1][2] + a[3][0] * a[0][2] * a[1][1]
    inv[3][3] = a[0][0] * a[1][1] * a[2][2] - a[0][0] * a[1][2] * a[2][1] - a[1][0] * a[0][1] * a[2][2]
        + a[1][0] * a[0][2] * a[2][1] + a[2][0] * a[0][1] * a[1][2] - a[2][0] * a[0][2] * a[1][1]
    let det = a[0][0] * inv[0][0] + a[0][1] * inv[1][0] + a[0][2] * inv[2][0] + a[0][3] * inv[3][0]
    if det == 0 {
        return SCNMatrix4Identity
    }
    let s = 1 / det
    return SCNMatrix4(
        m11: inv[0][0] * s, m12: inv[0][1] * s, m13: inv[0][2] * s, m14: inv[0][3] * s,
        m21: inv[1][0] * s, m22: inv[1][1] * s, m23: inv[1][2] * s, m24: inv[1][3] * s,
        m31: inv[2][0] * s, m32: inv[2][1] * s, m33: inv[2][2] * s, m34: inv[2][3] * s,
        m41: inv[3][0] * s, m42: inv[3][1] * s, m43: inv[3][2] * s, m44: inv[3][3] * s
    )
}

func _scnLength(_ v: SCNVector3) -> Float {
    (v.x * v.x + v.y * v.y + v.z * v.z).squareRoot()
}

func _scnNormalize(_ v: SCNVector3) -> SCNVector3 {
    let len = _scnLength(v)
    if len == 0 {
        return SCNVector3Zero
    }
    return SCNVector3(x: v.x / len, y: v.y / len, z: v.z / len)
}

func _scnDot(_ a: SCNVector3, _ b: SCNVector3) -> Float {
    a.x * b.x + a.y * b.y + a.z * b.z
}

func _scnCross(_ a: SCNVector3, _ b: SCNVector3) -> SCNVector3 {
    SCNVector3(
        x: a.y * b.z - a.z * b.y,
        y: a.z * b.x - a.x * b.z,
        z: a.x * b.y - a.y * b.x
    )
}

func _scnAdd(_ a: SCNVector3, _ b: SCNVector3) -> SCNVector3 {
    SCNVector3(x: a.x + b.x, y: a.y + b.y, z: a.z + b.z)
}

func _scnSub(_ a: SCNVector3, _ b: SCNVector3) -> SCNVector3 {
    SCNVector3(x: a.x - b.x, y: a.y - b.y, z: a.z - b.z)
}

func _scnScale(_ v: SCNVector3, _ s: Float) -> SCNVector3 {
    SCNVector3(x: v.x * s, y: v.y * s, z: v.z * s)
}

func _scnLerp(_ a: SCNVector3, _ b: SCNVector3, _ t: Float) -> SCNVector3 {
    SCNVector3(
        x: a.x + (b.x - a.x) * t,
        y: a.y + (b.y - a.y) * t,
        z: a.z + (b.z - a.z) * t
    )
}

func _scnTransformPoint(_ m: SCNMatrix4, _ p: SCNVector3) -> SCNVector3 {
    SCNVector3(
        x: m.m11 * p.x + m.m21 * p.y + m.m31 * p.z + m.m41,
        y: m.m12 * p.x + m.m22 * p.y + m.m32 * p.z + m.m42,
        z: m.m13 * p.x + m.m23 * p.y + m.m33 * p.z + m.m43
    )
}

func _scnTransformDirection(_ m: SCNMatrix4, _ v: SCNVector3) -> SCNVector3 {
    SCNVector3(
        x: m.m11 * v.x + m.m21 * v.y + m.m31 * v.z,
        y: m.m12 * v.x + m.m22 * v.y + m.m32 * v.z,
        z: m.m13 * v.x + m.m23 * v.y + m.m33 * v.z
    )
}

func _scnCompose(_ position: SCNVector3, _ rotation: SCNVector4, _ scale: SCNVector3, _ pivot: SCNMatrix4) -> SCNMatrix4 {
    let r = SCNMatrix4MakeRotation(rotation.w, rotation.x, rotation.y, rotation.z)
    let s = SCNMatrix4MakeScale(scale.x, scale.y, scale.z)
    let t = SCNMatrix4MakeTranslation(position.x, position.y, position.z)
    let pivotInverse = SCNMatrix4Invert(pivot)
    // Mult(A,B) applies A then B with this port's _transform. SceneKit TRS is
    // pivot^-1, then scale, then rotate, then translate.
    return SCNMatrix4Mult(pivotInverse, SCNMatrix4Mult(s, SCNMatrix4Mult(r, t)))
}

func _scnDecomposeTranslation(_ m: SCNMatrix4) -> SCNVector3 {
    SCNVector3(x: m.m41, y: m.m42, z: m.m43)
}

func _scnDecomposeScale(_ m: SCNMatrix4) -> SCNVector3 {
    let sx = _scnLength(SCNVector3(x: m.m11, y: m.m12, z: m.m13))
    let sy = _scnLength(SCNVector3(x: m.m21, y: m.m22, z: m.m23))
    let sz = _scnLength(SCNVector3(x: m.m31, y: m.m32, z: m.m33))
    return SCNVector3(x: sx, y: sy, z: sz)
}

extension SIMD3 where Scalar == Float {
    public init(_ v: SCNVector3) {
        self.init(v.x, v.y, v.z)
    }
}

extension SIMD3 where Scalar == Double {
    public init(_ v: SCNVector3) {
        self.init(Double(v.x), Double(v.y), Double(v.z))
    }
}

extension SIMD4 where Scalar == Float {
    public init(_ v: SCNVector4) {
        self.init(v.x, v.y, v.z, v.w)
    }
}

extension SIMD4 where Scalar == Double {
    public init(_ v: SCNVector4) {
        self.init(Double(v.x), Double(v.y), Double(v.z), Double(v.w))
    }
}

extension NSValue {
    public convenience init(scnVector3 v: SCNVector3) {
        var copy = v
        self.init(bytes: &copy, objCType: "SCNVector3")
    }

    public convenience init(SCNVector3 v: SCNVector3) {
        self.init(scnVector3: v)
    }

    public convenience init(scnVector4 v: SCNVector4) {
        var copy = v
        self.init(bytes: &copy, objCType: "SCNVector4")
    }

    public convenience init(SCNVector4 v: SCNVector4) {
        self.init(scnVector4: v)
    }

    public convenience init(scnMatrix4 v: SCNMatrix4) {
        var copy = v
        self.init(bytes: &copy, objCType: "SCNMatrix4")
    }

    public convenience init(SCNMatrix4 v: SCNMatrix4) {
        self.init(scnMatrix4: v)
    }

    public var scnVector3Value: SCNVector3 {
        var value = SCNVector3Zero
        getValue(&value)
        return value
    }

    public var scnVector4Value: SCNVector4 {
        var value = SCNVector4Zero
        getValue(&value)
        return value
    }

    public var scnMatrix4Value: SCNMatrix4 {
        var value = SCNMatrix4Identity
        getValue(&value)
        return value
    }
}

func _scnQuatNormalize(_ q: SCNQuaternion) -> SCNQuaternion {
    let len = (q.x * q.x + q.y * q.y + q.z * q.z + q.w * q.w).squareRoot()
    if len == 0 {
        return SCNQuaternion(x: 0, y: 0, z: 0, w: 1)
    }
    return SCNQuaternion(x: q.x / len, y: q.y / len, z: q.z / len, w: q.w / len)
}

func _scnQuatMul(_ a: SCNQuaternion, _ b: SCNQuaternion) -> SCNQuaternion {
    _scnQuatNormalize(SCNQuaternion(
        x: a.w * b.x + a.x * b.w + a.y * b.z - a.z * b.y,
        y: a.w * b.y - a.x * b.z + a.y * b.w + a.z * b.x,
        z: a.w * b.z + a.x * b.y - a.y * b.x + a.z * b.w,
        w: a.w * b.w - a.x * b.x - a.y * b.y - a.z * b.z
    ))
}

func _scnQuatFromAxisAngle(_ aa: SCNVector4) -> SCNQuaternion {
    let axis = _scnNormalize(SCNVector3(x: aa.x, y: aa.y, z: aa.z))
    let half = aa.w * 0.5
    let s = sin(half)
    return _scnQuatNormalize(SCNQuaternion(x: axis.x * s, y: axis.y * s, z: axis.z * s, w: cos(half)))
}

func _scnAxisAngleFromQuat(_ qIn: SCNQuaternion) -> SCNVector4 {
    let q = _scnQuatNormalize(qIn)
    let w = max(-1, min(1, q.w))
    let angle = 2 * acos(w)
    let s = (1 - w * w).squareRoot()
    if s < 1e-6 {
        return SCNVector4(x: 0, y: 1, z: 0, w: angle)
    }
    return SCNVector4(x: q.x / s, y: q.y / s, z: q.z / s, w: angle)
}

/// Linux Y-up right-handed Tait-Bryan XYZ (pitch, yaw, roll).
func _scnQuatFromEuler(_ e: SCNVector3) -> SCNQuaternion {
    let hx = e.x * 0.5
    let hy = e.y * 0.5
    let hz = e.z * 0.5
    let cx = cos(hx), sx = sin(hx)
    let cy = cos(hy), sy = sin(hy)
    let cz = cos(hz), sz = sin(hz)
    return _scnQuatNormalize(SCNQuaternion(
        x: sx * cy * cz - cx * sy * sz,
        y: cx * sy * cz + sx * cy * sz,
        z: cx * cy * sz - sx * sy * cz,
        w: cx * cy * cz + sx * sy * sz
    ))
}

func _scnEulerFromQuat(_ qIn: SCNQuaternion) -> SCNVector3 {
    let q = _scnQuatNormalize(qIn)
    let sinp = 2 * (q.w * q.y - q.z * q.x)
    let yaw: Float
    if abs(sinp) >= 1 {
        yaw = copysign(.pi / 2, sinp)
    } else {
        yaw = asin(sinp)
    }
    let pitch = atan2(2 * (q.w * q.x + q.y * q.z), 1 - 2 * (q.x * q.x + q.y * q.y))
    let roll = atan2(2 * (q.w * q.z + q.x * q.y), 1 - 2 * (q.y * q.y + q.z * q.z))
    return SCNVector3(x: pitch, y: yaw, z: roll)
}

func _scnMatrixFromQuat(_ qIn: SCNQuaternion) -> SCNMatrix4 {
    let q = _scnQuatNormalize(qIn)
    let xx = q.x * q.x, yy = q.y * q.y, zz = q.z * q.z
    let xy = q.x * q.y, xz = q.x * q.z, yz = q.y * q.z
    let wx = q.w * q.x, wy = q.w * q.y, wz = q.w * q.z
    return SCNMatrix4(
        m11: 1 - 2 * (yy + zz), m12: 2 * (xy + wz),     m13: 2 * (xz - wy),     m14: 0,
        m21: 2 * (xy - wz),     m22: 1 - 2 * (xx + zz), m23: 2 * (yz + wx),     m24: 0,
        m31: 2 * (xz + wy),     m32: 2 * (yz - wx),     m33: 1 - 2 * (xx + yy), m34: 0,
        m41: 0, m42: 0, m43: 0, m44: 1
    )
}

func _scnLookAtMatrix(from: SCNVector3, to: SCNVector3, up: SCNVector3, localFront: SCNVector3) -> SCNMatrix4 {
    let dir = _scnNormalize(_scnSub(to, from))
    if _scnLength(dir) == 0 {
        return SCNMatrix4Identity
    }
    let front = _scnNormalize(localFront)
    let angle = acos(max(-1, min(1, _scnDot(front, dir))))
    var axis = _scnCross(front, dir)
    if _scnLength(axis) < 1e-6 {
        if _scnDot(front, dir) > 0 {
            return SCNMatrix4Identity
        }
        axis = _scnLength(_scnCross(front, up)) > 1e-6 ? _scnCross(front, up) : SCNNode.localRight
    }
    axis = _scnNormalize(axis)
    _ = up
    return SCNMatrix4MakeRotation(angle, axis.x, axis.y, axis.z)
}

func _scnPerspectiveProjection(fovYRadians: Float, aspect: Float, zNear: Float, zFar: Float) -> SCNMatrix4 {
    let f = 1 / tan(fovYRadians * 0.5)
    let a = aspect == 0 ? 1 : aspect
    let zn = zNear
    let zf = zFar
    let dz = zn - zf
    let m33: Float = dz == 0 ? -1 : (zf + zn) / dz
    let m43: Float = dz == 0 ? 0 : (2 * zf * zn) / dz
    return SCNMatrix4(
        m11: f / a, m12: 0, m13: 0, m14: 0,
        m21: 0, m22: f, m23: 0, m24: 0,
        m31: 0, m32: 0, m33: m33, m34: -1,
        m41: 0, m42: 0, m43: m43, m44: 0
    )
}

func _scnOrthographicProjection(halfHeight: Float, aspect: Float, zNear: Float, zFar: Float) -> SCNMatrix4 {
    let h = halfHeight == 0 ? 1 : halfHeight
    let a = aspect == 0 ? 1 : aspect
    let w = h * a
    let dz = zFar - zNear
    return SCNMatrix4(
        m11: w == 0 ? 1 : 1 / w, m12: 0, m13: 0, m14: 0,
        m21: 0, m22: 1 / h, m23: 0, m24: 0,
        m31: 0, m32: 0, m33: dz == 0 ? -1 : -2 / dz, m34: 0,
        m41: 0, m42: 0, m43: dz == 0 ? 0 : -((zFar + zNear) / dz), m44: 1
    )
}

/// Axis-angle from the 3x3 of `m`. Linux extraction, not claimed Apple-identical.
func _scnDecomposeRotation(_ m: SCNMatrix4) -> SCNVector4 {
    let scale = _scnDecomposeScale(m)
    let sx = scale.x == 0 ? 1 : scale.x
    let sy = scale.y == 0 ? 1 : scale.y
    let sz = scale.z == 0 ? 1 : scale.z
    let r11 = m.m11 / sx
    let r12 = m.m12 / sx
    let r13 = m.m13 / sx
    let r21 = m.m21 / sy
    let r22 = m.m22 / sy
    let r23 = m.m23 / sy
    let r31 = m.m31 / sz
    let r32 = m.m32 / sz
    let r33 = m.m33 / sz
    let trace = r11 + r22 + r33
    let cosA = max(-1, min(1, (trace - 1) * 0.5))
    let angle = acos(cosA)
    if angle < 1e-6 {
        return SCNVector4(x: 0, y: 1, z: 0, w: 0)
    }
    var ax = r32 - r23
    var ay = r13 - r31
    var az = r21 - r12
    let len = (ax * ax + ay * ay + az * az).squareRoot()
    if len < 1e-6 {
        return SCNVector4(x: 0, y: 1, z: 0, w: angle)
    }
    ax /= len
    ay /= len
    az /= len
    return SCNVector4(x: ax, y: ay, z: az, w: angle)
}
