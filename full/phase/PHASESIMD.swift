import Foundation

// Isolated-host SIMD spellings. Darwin `simd` is not a declared dependency
// and is absent from this Linux toolchain. Layout matches the documented
// column-major `simd_float4x4` / quaternion payloads. These aliases are not
// Darwin ABI and must not be copied into a guest simd product.

public typealias simd_float3 = SIMD3<Float>
public typealias simd_double2 = SIMD2<Double>

/// Column-major 4x4 transform matching Darwin `simd_float4x4`.
public struct simd_float4x4: Equatable, Sendable {
    public var columns: (SIMD4<Float>, SIMD4<Float>, SIMD4<Float>, SIMD4<Float>)

    public init(columns: (SIMD4<Float>, SIMD4<Float>, SIMD4<Float>, SIMD4<Float>)) {
        self.columns = columns
    }

    public init(_ diagonal: Float) {
        self.columns = (
            SIMD4<Float>(diagonal, 0, 0, 0),
            SIMD4<Float>(0, diagonal, 0, 0),
            SIMD4<Float>(0, 0, diagonal, 0),
            SIMD4<Float>(0, 0, 0, diagonal)
        )
    }

    public static func == (lhs: simd_float4x4, rhs: simd_float4x4) -> Bool {
        lhs.columns.0 == rhs.columns.0
            && lhs.columns.1 == rhs.columns.1
            && lhs.columns.2 == rhs.columns.2
            && lhs.columns.3 == rhs.columns.3
    }

    public static let identity = simd_float4x4(1)
}

/// Isolated-host quaternion matching Darwin `simd_quatf` field names.
public struct simd_quatf: Equatable, Sendable {
    public var vector: SIMD4<Float>

    public init(ix: Float, iy: Float, iz: Float, r: Float) {
        self.vector = SIMD4<Float>(ix, iy, iz, r)
    }

    public init(vector: SIMD4<Float>) {
        self.vector = vector
    }

    public var ix: Float { vector.x }
    public var iy: Float { vector.y }
    public var iz: Float { vector.z }
    public var r: Float { vector.w }

    public static let identity = simd_quatf(ix: 0, iy: 0, iz: 0, r: 1)

    public static func == (lhs: simd_quatf, rhs: simd_quatf) -> Bool {
        lhs.vector == rhs.vector
    }
}

func phaseMultiply(_ a: simd_float4x4, _ b: simd_float4x4) -> simd_float4x4 {
    func mul(_ m: simd_float4x4, _ v: SIMD4<Float>) -> SIMD4<Float> {
        m.columns.0 * v.x + m.columns.1 * v.y + m.columns.2 * v.z + m.columns.3 * v.w
    }
    return simd_float4x4(columns: (
        mul(a, b.columns.0),
        mul(a, b.columns.1),
        mul(a, b.columns.2),
        mul(a, b.columns.3)
    ))
}

/// Invert an affine 4x4 (orthonormal 3x3 + translation). Returns identity if
/// the linear part is degenerate.
func phaseInvertAffine(_ m: simd_float4x4) -> simd_float4x4 {
    let a = m.columns.0
    let b = m.columns.1
    let c = m.columns.2
    let d = m.columns.3
    let r0 = SIMD3<Float>(a.x, b.x, c.x)
    let r1 = SIMD3<Float>(a.y, b.y, c.y)
    let r2 = SIMD3<Float>(a.z, b.z, c.z)
    let t = SIMD3<Float>(d.x, d.y, d.z)
    let invT = SIMD3<Float>(
        -SIMD3<Float>.Dot(r0, t),
        -SIMD3<Float>.Dot(r1, t),
        -SIMD3<Float>.Dot(r2, t)
    )
    return simd_float4x4(columns: (
        SIMD4<Float>(r0.x, r0.y, r0.z, 0),
        SIMD4<Float>(r1.x, r1.y, r1.z, 0),
        SIMD4<Float>(r2.x, r2.y, r2.z, 0),
        SIMD4<Float>(invT.x, invT.y, invT.z, 1)
    ))
}

private extension SIMD3 where Scalar == Float {
    static func Dot(_ a: SIMD3<Float>, _ b: SIMD3<Float>) -> Float {
        a.x * b.x + a.y * b.y + a.z * b.z
    }
}
