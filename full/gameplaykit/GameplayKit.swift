import Foundation

/// Linux substitutes for the Darwin `simd` C aliases used throughout GameplayKit.
public typealias vector_float2 = SIMD2<Float>
public typealias vector_float3 = SIMD3<Float>
public typealias vector_int2 = SIMD2<Int32>
public typealias vector_double2 = SIMD2<Double>
public typealias vector_double3 = SIMD3<Double>

/// Column-major 3×3 matrix used by `GKAgent3D.rotation`.
public struct matrix_float3x3: Sendable {
    public var columns: (vector_float3, vector_float3, vector_float3)

    public init() {
        columns = (
            vector_float3(1, 0, 0),
            vector_float3(0, 1, 0),
            vector_float3(0, 0, 1)
        )
    }

    public init(columns: (vector_float3, vector_float3, vector_float3)) {
        self.columns = columns
    }

    public static func == (lhs: matrix_float3x3, rhs: matrix_float3x3) -> Bool {
        lhs.columns.0 == rhs.columns.0
            && lhs.columns.1 == rhs.columns.1
            && lhs.columns.2 == rhs.columns.2
    }
}

/// Packed GameplayKit version. Apple's `GK_VERSION` macro is not present as a
/// numeric payload in the pinned graphs; this seed reports the campaign SDK.
public var GK_VERSION: Int32 { 26_01_00 }

public let GKGameModelMaxScore: Int = 1 << 24
public let GKGameModelMinScore: Int = -(1 << 24)

public struct GKMeshGraphTriangulationMode: OptionSet, Sendable {
    public let rawValue: UInt

    public init(rawValue: UInt) {
        self.rawValue = rawValue
    }

    public static let vertices = GKMeshGraphTriangulationMode(rawValue: 1 << 0)
    public static let centers = GKMeshGraphTriangulationMode(rawValue: 1 << 1)
    public static let edgeMidpoints = GKMeshGraphTriangulationMode(rawValue: 1 << 2)
}

public enum GKRTreeSplitStrategy: Int, Sendable {
    case halve = 0
    case linear = 1
    case quadratic = 2
    case reduceOverlap = 3
}

public struct GKBox: Equatable, Sendable {
    public var boxMin: vector_float3
    public var boxMax: vector_float3

    public init() {
        boxMin = vector_float3(0, 0, 0)
        boxMax = vector_float3(0, 0, 0)
    }

    public init(boxMin: vector_float3, boxMax: vector_float3) {
        self.boxMin = boxMin
        self.boxMax = boxMax
    }
}

public struct GKQuad: Equatable, Sendable {
    public var quadMin: vector_float2
    public var quadMax: vector_float2

    public init() {
        quadMin = vector_float2(0, 0)
        quadMax = vector_float2(0, 0)
    }

    public init(quadMin: vector_float2, quadMax: vector_float2) {
        self.quadMin = quadMin
        self.quadMax = quadMax
    }
}

public struct GKTriangle: Sendable {
    public var points: (vector_float3, vector_float3, vector_float3)

    public init() {
        points = (vector_float3(0, 0, 0), vector_float3(0, 0, 0), vector_float3(0, 0, 0))
    }

    public init(points: (vector_float3, vector_float3, vector_float3)) {
        self.points = points
    }

    public static func == (lhs: GKTriangle, rhs: GKTriangle) -> Bool {
        lhs.points.0 == rhs.points.0 && lhs.points.1 == rhs.points.1 && lhs.points.2 == rhs.points.2
    }
}

func gkLength(_ v: vector_float2) -> Float {
    ((v.x * v.x) + (v.y * v.y)).squareRoot()
}

func gkLength(_ v: vector_float3) -> Float {
    ((v.x * v.x) + (v.y * v.y) + (v.z * v.z)).squareRoot()
}

func gkNormalize(_ v: vector_float2) -> vector_float2 {
    let length = gkLength(v)
    if length < 1e-8 { return vector_float2(0, 0) }
    return v / length
}

func gkNormalize(_ v: vector_float3) -> vector_float3 {
    let length = gkLength(v)
    if length < 1e-8 { return vector_float3(0, 0, 0) }
    return v / length
}

func gkDot(_ a: vector_float2, _ b: vector_float2) -> Float {
    a.x * b.x + a.y * b.y
}

func gkDot(_ a: vector_float3, _ b: vector_float3) -> Float {
    a.x * b.x + a.y * b.y + a.z * b.z
}

func gkDistance(_ a: vector_float2, _ b: vector_float2) -> Float {
    gkLength(a - b)
}

func gkDistance(_ a: vector_float3, _ b: vector_float3) -> Float {
    gkLength(a - b)
}

func gkClamp(_ value: Float, _ lo: Float, _ hi: Float) -> Float {
    min(max(value, lo), hi)
}

func gkQuadContains(_ quad: GKQuad, _ point: vector_float2) -> Bool {
    point.x >= quad.quadMin.x && point.x <= quad.quadMax.x
        && point.y >= quad.quadMin.y && point.y <= quad.quadMax.y
}

func gkQuadIntersects(_ a: GKQuad, _ b: GKQuad) -> Bool {
    a.quadMin.x <= b.quadMax.x && a.quadMax.x >= b.quadMin.x
        && a.quadMin.y <= b.quadMax.y && a.quadMax.y >= b.quadMin.y
}

func gkBoxContains(_ box: GKBox, _ point: vector_float3) -> Bool {
    point.x >= box.boxMin.x && point.x <= box.boxMax.x
        && point.y >= box.boxMin.y && point.y <= box.boxMax.y
        && point.z >= box.boxMin.z && point.z <= box.boxMax.z
}

func gkBoxIntersects(_ a: GKBox, _ b: GKBox) -> Bool {
    a.boxMin.x <= b.boxMax.x && a.boxMax.x >= b.boxMin.x
        && a.boxMin.y <= b.boxMax.y && a.boxMax.y >= b.boxMin.y
        && a.boxMin.z <= b.boxMax.z && a.boxMax.z >= b.boxMin.z
}

func gkSegmentsIntersect(_ a1: vector_float2, _ a2: vector_float2, _ b1: vector_float2, _ b2: vector_float2) -> Bool {
    func cross(_ u: vector_float2, _ v: vector_float2) -> Float {
        u.x * v.y - u.y * v.x
    }
    let r = a2 - a1
    let s = b2 - b1
    let denominator = cross(r, s)
    if abs(denominator) < 1e-12 {
        return false
    }
    let qp = b1 - a1
    let t = cross(qp, s) / denominator
    let u = cross(qp, r) / denominator
    return t >= 0 && t <= 1 && u >= 0 && u <= 1
}

func gkPointInPolygon(_ point: vector_float2, _ vertices: [vector_float2]) -> Bool {
    guard vertices.count >= 3 else { return false }
    var inside = false
    var j = vertices.count - 1
    for i in 0..<vertices.count {
        let vi = vertices[i]
        let vj = vertices[j]
        let intersect = ((vi.y > point.y) != (vj.y > point.y))
            && (point.x < (vj.x - vi.x) * (point.y - vi.y) / (vj.y - vi.y + 1e-12) + vi.x)
        if intersect {
            inside.toggle()
        }
        j = i
    }
    return inside
}
