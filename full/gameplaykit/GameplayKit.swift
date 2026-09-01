#if canImport(simd)
import simd
#endif
import Foundation

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
    public var boxMin: SIMD3<Float>
    public var boxMax: SIMD3<Float>

    public init() {
        boxMin = SIMD3<Float>(0, 0, 0)
        boxMax = SIMD3<Float>(0, 0, 0)
    }

    public init(boxMin: SIMD3<Float>, boxMax: SIMD3<Float>) {
        self.boxMin = boxMin
        self.boxMax = boxMax
    }
}

public struct GKQuad: Equatable, Sendable {
    public var quadMin: SIMD2<Float>
    public var quadMax: SIMD2<Float>

    public init() {
        quadMin = SIMD2<Float>(0, 0)
        quadMax = SIMD2<Float>(0, 0)
    }

    public init(quadMin: SIMD2<Float>, quadMax: SIMD2<Float>) {
        self.quadMin = quadMin
        self.quadMax = quadMax
    }
}

public struct GKTriangle: Sendable {
    public var points: (SIMD3<Float>, SIMD3<Float>, SIMD3<Float>)

    public init() {
        points = (SIMD3<Float>(0, 0, 0), SIMD3<Float>(0, 0, 0), SIMD3<Float>(0, 0, 0))
    }

    public init(points: (SIMD3<Float>, SIMD3<Float>, SIMD3<Float>)) {
        self.points = points
    }

    public static func == (lhs: GKTriangle, rhs: GKTriangle) -> Bool {
        lhs.points.0 == rhs.points.0 && lhs.points.1 == rhs.points.1 && lhs.points.2 == rhs.points.2
    }
}

func gkLength(_ v: SIMD2<Float>) -> Float {
    ((v.x * v.x) + (v.y * v.y)).squareRoot()
}

func gkLength(_ v: SIMD3<Float>) -> Float {
    ((v.x * v.x) + (v.y * v.y) + (v.z * v.z)).squareRoot()
}

func gkNormalize(_ v: SIMD2<Float>) -> SIMD2<Float> {
    let length = gkLength(v)
    if length < 1e-8 { return SIMD2<Float>(0, 0) }
    return v / length
}

func gkNormalize(_ v: SIMD3<Float>) -> SIMD3<Float> {
    let length = gkLength(v)
    if length < 1e-8 { return SIMD3<Float>(0, 0, 0) }
    return v / length
}

func gkDot(_ a: SIMD2<Float>, _ b: SIMD2<Float>) -> Float {
    a.x * b.x + a.y * b.y
}

func gkDot(_ a: SIMD3<Float>, _ b: SIMD3<Float>) -> Float {
    a.x * b.x + a.y * b.y + a.z * b.z
}

func gkDistance(_ a: SIMD2<Float>, _ b: SIMD2<Float>) -> Float {
    gkLength(a - b)
}

func gkDistance(_ a: SIMD3<Float>, _ b: SIMD3<Float>) -> Float {
    gkLength(a - b)
}

func gkClamp(_ value: Float, _ lo: Float, _ hi: Float) -> Float {
    min(max(value, lo), hi)
}

func gkQuadContains(_ quad: GKQuad, _ point: SIMD2<Float>) -> Bool {
    point.x >= quad.quadMin.x && point.x <= quad.quadMax.x
        && point.y >= quad.quadMin.y && point.y <= quad.quadMax.y
}

func gkQuadIntersects(_ a: GKQuad, _ b: GKQuad) -> Bool {
    a.quadMin.x <= b.quadMax.x && a.quadMax.x >= b.quadMin.x
        && a.quadMin.y <= b.quadMax.y && a.quadMax.y >= b.quadMin.y
}

func gkBoxContains(_ box: GKBox, _ point: SIMD3<Float>) -> Bool {
    point.x >= box.boxMin.x && point.x <= box.boxMax.x
        && point.y >= box.boxMin.y && point.y <= box.boxMax.y
        && point.z >= box.boxMin.z && point.z <= box.boxMax.z
}

func gkBoxIntersects(_ a: GKBox, _ b: GKBox) -> Bool {
    a.boxMin.x <= b.boxMax.x && a.boxMax.x >= b.boxMin.x
        && a.boxMin.y <= b.boxMax.y && a.boxMax.y >= b.boxMin.y
        && a.boxMin.z <= b.boxMax.z && a.boxMax.z >= b.boxMin.z
}

func gkSegmentsIntersect(_ a1: SIMD2<Float>, _ a2: SIMD2<Float>, _ b1: SIMD2<Float>, _ b2: SIMD2<Float>) -> Bool {
    func cross(_ u: SIMD2<Float>, _ v: SIMD2<Float>) -> Float {
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

func gkPointInPolygon(_ point: SIMD2<Float>, _ vertices: [SIMD2<Float>]) -> Bool {
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

enum GKLinuxArchive {
    static let markerKey = "ouik.gk.linux"
    static let marker: Int64 = 1
    static let componentsKey = "ouik.gk.components"
    static let entitiesKey = "ouik.gk.entities"
    static let graphsKey = "ouik.gk.graphs"
    static let graphNamesKey = "ouik.gk.graphNames"
    static let nodesKey = "ouik.gk.nodes"
    static let edgesKey = "ouik.gk.edges"
    static let xKey = "ouik.gk.x"
    static let yKey = "ouik.gk.y"
    static let zKey = "ouik.gk.z"
    static let verticesKey = "ouik.gk.vertices"
    static let rootKey = "ouik.gk.root"
    static let attributeKey = "ouik.gk.attribute"
    static let branchesKey = "ouik.gk.branches"
    static let kindKey = "ouik.gk.kind"
    static let valueKey = "ouik.gk.value"
    static let weightKey = "ouik.gk.weight"
    static let childKey = "ouik.gk.child"
    static let seedKey = "ouik.gk.seed"
    static let stateKey = "ouik.gk.state"
    static let siKey = "ouik.gk.si"
    static let sjKey = "ouik.gk.sj"
    static let indexKey = "ouik.gk.index"
    static let randomKey = "ouik.gk.random"

    static func encodeMarker(_ coder: NSCoder) {
        coder.encode(marker, forKey: markerKey)
    }

    static func hasMarker(_ coder: NSCoder) -> Bool {
        coder.containsValue(forKey: markerKey)
    }

    static func decodeObjectArray<T: NSObject>(_ coder: NSCoder, key: String, classes: [AnyClass]) -> [T]? {
        var allowed: [AnyClass] = [NSArray.self]
        allowed.append(contentsOf: classes)
        return coder.decodeObject(of: allowed, forKey: key) as? [T]
    }

    static func allowedUnarchiveClasses() -> [AnyClass] {
        [
            NSArray.self, NSString.self, NSNumber.self, NSData.self, NSDictionary.self,
            GKComponent.self, GKEntity.self, GKScene.self,
            GKGraph.self, GKGraphNode.self, GKGraphNode2D.self, GKGraphNode3D.self, GKGridGraphNode.self,
            GKPolygonObstacle.self, GKDecisionTree.self, GKDecisionNode.self, GKDecisionBranch.self,
            GKRandomSource.self, GKARC4RandomSource.self,
            GKLinearCongruentialRandomSource.self, GKMersenneTwisterRandomSource.self
        ]
    }
}

@_spi(OpenUIKitHost)
public enum GameplayKitHostArchive {
    /// Linux-keyed archives carry `ouik.gk.linux`. Apple keyed layouts and other
    /// malformed buffers are rejected.
    public static func rejectMalformedCoder(_ coder: NSCoder) -> Bool {
        !GKLinuxArchive.hasMarker(coder)
    }

    public static func unarchivedRoot<T: NSObject & NSCoding>(_ type: T.Type, from data: Data) throws -> T? {
        try NSKeyedUnarchiver.unarchivedObject(ofClass: type, from: data)
    }
}
