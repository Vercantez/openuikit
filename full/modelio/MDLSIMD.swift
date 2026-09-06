import Foundation

#if canImport(simd)
import simd
#endif

#if !canImport(simd)
func simd_dot(_ a: SIMD3<Float>, _ b: SIMD3<Float>) -> Float {
    a.x * b.x + a.y * b.y + a.z * b.z
}

func simd_length(_ v: SIMD3<Float>) -> Float {
    sqrt(simd_dot(v, v))
}

func simd_normalize(_ v: SIMD3<Float>) -> SIMD3<Float> {
    let length = simd_length(v)
    return length < 1e-8 ? v : v / length
}

func simd_cross(_ a: SIMD3<Float>, _ b: SIMD3<Float>) -> SIMD3<Float> {
    SIMD3(a.y * b.z - a.z * b.y, a.z * b.x - a.x * b.z, a.x * b.y - a.y * b.x)
}

func simd_mix(_ a: SIMD3<Float>, _ b: SIMD3<Float>, _ t: SIMD3<Float>) -> SIMD3<Float> {
    a + (b - a) * t
}

func simd_normalize(_ v: SIMD4<Float>) -> SIMD4<Float> {
    let length = sqrt(v.x * v.x + v.y * v.y + v.z * v.z + v.w * v.w)
    return length < 1e-8 ? v : v / length
}
#endif

#if !canImport(simd)
public typealias vector_float2 = SIMD2<Float>
public typealias vector_float3 = SIMD3<Float>
public typealias vector_float4 = SIMD4<Float>
public typealias vector_double2 = SIMD2<Double>
public typealias vector_double3 = SIMD3<Double>
public typealias vector_double4 = SIMD4<Double>
public typealias vector_int2 = SIMD2<Int32>
public typealias vector_int3 = SIMD3<Int32>
public typealias vector_int4 = SIMD4<Int32>
public typealias vector_uint2 = SIMD2<UInt32>
public typealias vector_uint3 = SIMD3<UInt32>
public typealias vector_uint4 = SIMD4<UInt32>
public typealias MDLVoxelIndex = SIMD4<Int32>

public struct matrix_float4x4: Equatable, Sendable {
    public var columns: (SIMD4<Float>, SIMD4<Float>, SIMD4<Float>, SIMD4<Float>)

    public init(columns: (SIMD4<Float>, SIMD4<Float>, SIMD4<Float>, SIMD4<Float>)) {
        self.columns = columns
    }

    public init() {
        self = .identity
    }

    public static let identity = matrix_float4x4(columns: (
        SIMD4<Float>(1, 0, 0, 0),
        SIMD4<Float>(0, 1, 0, 0),
        SIMD4<Float>(0, 0, 1, 0),
        SIMD4<Float>(0, 0, 0, 1)
    ))

    public static func == (lhs: matrix_float4x4, rhs: matrix_float4x4) -> Bool {
        lhs.columns.0 == rhs.columns.0
            && lhs.columns.1 == rhs.columns.1
            && lhs.columns.2 == rhs.columns.2
            && lhs.columns.3 == rhs.columns.3
    }
}

public struct matrix_double4x4: Equatable, Sendable {
    public var columns: (SIMD4<Double>, SIMD4<Double>, SIMD4<Double>, SIMD4<Double>)

    public init(columns: (SIMD4<Double>, SIMD4<Double>, SIMD4<Double>, SIMD4<Double>)) {
        self.columns = columns
    }

    public init() {
        self = .identity
    }

    public static let identity = matrix_double4x4(columns: (
        SIMD4<Double>(1, 0, 0, 0),
        SIMD4<Double>(0, 1, 0, 0),
        SIMD4<Double>(0, 0, 1, 0),
        SIMD4<Double>(0, 0, 0, 1)
    ))

    public static func == (lhs: matrix_double4x4, rhs: matrix_double4x4) -> Bool {
        lhs.columns.0 == rhs.columns.0
            && lhs.columns.1 == rhs.columns.1
            && lhs.columns.2 == rhs.columns.2
            && lhs.columns.3 == rhs.columns.3
    }
}

public typealias float4x4 = matrix_float4x4
public typealias double4x4 = matrix_double4x4

public struct simd_quatf: Equatable, Sendable {
    public var vector: SIMD4<Float>

    public init(ix: Float, iy: Float, iz: Float, r: Float) {
        vector = SIMD4(ix, iy, iz, r)
    }

    public init(vector: SIMD4<Float>) {
        self.vector = vector
    }

    public static let identity = simd_quatf(ix: 0, iy: 0, iz: 0, r: 1)
}

public struct simd_quatd: Equatable, Sendable {
    public var vector: SIMD4<Double>

    public init(ix: Double, iy: Double, iz: Double, r: Double) {
        vector = SIMD4(ix, iy, iz, r)
    }

    public init(vector: SIMD4<Double>) {
        self.vector = vector
    }

    public static let identity = simd_quatd(ix: 0, iy: 0, iz: 0, r: 1)
}
#endif

func mdlMul(_ a: matrix_float4x4, _ b: matrix_float4x4) -> matrix_float4x4 {
    func dotCol(_ col: SIMD4<Float>) -> SIMD4<Float> {
        a.columns.0 * col.x + a.columns.1 * col.y + a.columns.2 * col.z + a.columns.3 * col.w
    }
    return matrix_float4x4(columns: (dotCol(b.columns.0), dotCol(b.columns.1), dotCol(b.columns.2), dotCol(b.columns.3)))
}

func mdlTranslationMatrix(_ t: SIMD3<Float>) -> matrix_float4x4 {
    var m = matrix_float4x4.identity
    m.columns.3 = SIMD4(t.x, t.y, t.z, 1)
    return m
}

func mdlScaleMatrix(_ s: SIMD3<Float>) -> matrix_float4x4 {
    matrix_float4x4(columns: (
        SIMD4<Float>(s.x, 0, 0, 0),
        SIMD4<Float>(0, s.y, 0, 0),
        SIMD4<Float>(0, 0, s.z, 0),
        SIMD4<Float>(0, 0, 0, 1)
    ))
}

/// XYZ Tait-Bryan, radians. Linux convention, not claimed Apple-bit-identical.
func mdlRotationMatrixXYZ(_ euler: SIMD3<Float>) -> matrix_float4x4 {
    let cx = cos(euler.x), sx = sin(euler.x)
    let cy = cos(euler.y), sy = sin(euler.y)
    let cz = cos(euler.z), sz = sin(euler.z)
    let rx = matrix_float4x4(columns: (
        SIMD4<Float>(1, 0, 0, 0),
        SIMD4<Float>(0, cx, sx, 0),
        SIMD4<Float>(0, -sx, cx, 0),
        SIMD4<Float>(0, 0, 0, 1)
    ))
    let ry = matrix_float4x4(columns: (
        SIMD4<Float>(cy, 0, -sy, 0),
        SIMD4<Float>(0, 1, 0, 0),
        SIMD4<Float>(sy, 0, cy, 0),
        SIMD4<Float>(0, 0, 0, 1)
    ))
    let rz = matrix_float4x4(columns: (
        SIMD4<Float>(cz, sz, 0, 0),
        SIMD4<Float>(-sz, cz, 0, 0),
        SIMD4<Float>(0, 0, 1, 0),
        SIMD4<Float>(0, 0, 0, 1)
    ))
    return mdlMul(rz, mdlMul(ry, rx))
}

func mdlTRS(_ t: SIMD3<Float>, _ r: SIMD3<Float>, _ s: SIMD3<Float>) -> matrix_float4x4 {
    mdlMul(mdlTranslationMatrix(t), mdlMul(mdlRotationMatrixXYZ(r), mdlScaleMatrix(s)))
}

func mdlFloatToDouble(_ m: matrix_float4x4) -> matrix_double4x4 {
    func c(_ v: SIMD4<Float>) -> SIMD4<Double> {
        SIMD4(Double(v.x), Double(v.y), Double(v.z), Double(v.w))
    }
    return matrix_double4x4(columns: (c(m.columns.0), c(m.columns.1), c(m.columns.2), c(m.columns.3)))
}

func mdlDoubleToFloat(_ m: matrix_double4x4) -> matrix_float4x4 {
    func c(_ v: SIMD4<Double>) -> SIMD4<Float> {
        SIMD4(Float(v.x), Float(v.y), Float(v.z), Float(v.w))
    }
    return matrix_float4x4(columns: (c(m.columns.0), c(m.columns.1), c(m.columns.2), c(m.columns.3)))
}

func mdlLookAt(eye: SIMD3<Float>, target: SIMD3<Float>, up: SIMD3<Float>) -> matrix_float4x4 {
    let f = simd_normalize(target - eye)
    var u = up
    if simd_length(u) < 1e-8 {
        u = SIMD3<Float>(0, 1, 0)
    }
    var s = simd_cross(f, u)
    if simd_length(s) < 1e-8 {
        s = simd_cross(f, SIMD3<Float>(1, 0, 0))
    }
    s = simd_normalize(s)
    let uu = simd_cross(s, f)
    let rot = matrix_float4x4(columns: (
        SIMD4(s.x, uu.x, -f.x, 0),
        SIMD4(s.y, uu.y, -f.y, 0),
        SIMD4(s.z, uu.z, -f.z, 0),
        SIMD4<Float>(0, 0, 0, 1)
    ))
    return mdlMul(rot, mdlTranslationMatrix(-eye))
}

func mdlPerspective(fovYRadians: Float, aspect: Float, near: Float, far: Float) -> matrix_float4x4 {
    let f = 1 / tan(fovYRadians / 2)
    let a = far / (near - far)
    return matrix_float4x4(columns: (
        SIMD4(f / max(aspect, 1e-6), 0, 0, 0),
        SIMD4(Float(0), f, 0, 0),
        SIMD4(Float(0), 0, a, -1),
        SIMD4(Float(0), 0, near * a, 0)
    ))
}

func mdlOrtho(left: Float, right: Float, bottom: Float, top: Float, near: Float, far: Float) -> matrix_float4x4 {
    let sx = 2 / (right - left)
    let sy = 2 / (top - bottom)
    let sz = 1 / (near - far)
    let tx = -(right + left) / (right - left)
    let ty = -(top + bottom) / (top - bottom)
    let tz = near / (near - far)
    return matrix_float4x4(columns: (
        SIMD4(sx, 0, 0, 0),
        SIMD4(Float(0), sy, 0, 0),
        SIMD4(Float(0), 0, sz, 0),
        SIMD4(tx, ty, tz, 1)
    ))
}

func mdlSlerp(_ a: simd_quatf, _ b: simd_quatf, _ t: Float) -> simd_quatf {
    var dot = a.vector.x * b.vector.x + a.vector.y * b.vector.y + a.vector.z * b.vector.z + a.vector.w * b.vector.w
    var bv = b.vector
    if dot < 0 {
        bv = -bv
        dot = -dot
    }
    if dot > 0.9995 {
        return simd_quatf(vector: simd_normalize(a.vector + (bv - a.vector) * t))
    }
    let theta = acos(min(1, max(-1, dot)))
    let s = sin(theta)
    let w1 = sin((1 - t) * theta) / s
    let w2 = sin(t * theta) / s
    return simd_quatf(vector: a.vector * w1 + bv * w2)
}
