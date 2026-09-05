import Foundation

open class SKRange: NSObject, NSSecureCoding, NSCopying {
    public var lowerLimit: CGFloat
    public var upperLimit: CGFloat

    public init(lowerLimit lower: CGFloat, upperLimit upper: CGFloat) {
        self.lowerLimit = lower
        self.upperLimit = upper
        super.init()
    }

    public convenience init(constantValue value: CGFloat) {
        self.init(lowerLimit: value, upperLimit: value)
    }

    public convenience init(lowerLimit lower: CGFloat) {
        self.init(lowerLimit: lower, upperLimit: CGFloat.greatestFiniteMagnitude)
    }

    public convenience init(upperLimit upper: CGFloat) {
        self.init(lowerLimit: -CGFloat.greatestFiniteMagnitude, upperLimit: upper)
    }

    public convenience init(value: CGFloat, variance: CGFloat) {
        self.init(lowerLimit: value - variance, upperLimit: value + variance)
    }

    public class func withNoLimits() -> SKRange {
        SKRange(lowerLimit: -CGFloat.greatestFiniteMagnitude, upperLimit: CGFloat.greatestFiniteMagnitude)
    }

    public required init?(coder: NSCoder) {
        lowerLimit = CGFloat(coder.decodeDouble(forKey: "lo"))
        upperLimit = CGFloat(coder.decodeDouble(forKey: "hi"))
        super.init()
    }

    public func encode(with coder: NSCoder) {
        coder.encode(Double(lowerLimit), forKey: "lo")
        coder.encode(Double(upperLimit), forKey: "hi")
    }

    public static var supportsSecureCoding: Bool { true }
    public func copy(with zone: NSZone? = nil) -> Any {
        SKRange(lowerLimit: lowerLimit, upperLimit: upperLimit)
    }

    func _clamp(_ value: CGFloat) -> CGFloat {
        sk_clamp(value, lowerLimit, upperLimit)
    }
}

open class SKConstraint: NSObject, NSSecureCoding {
    public var enabled: Bool = true
    public var referenceNode: SKNode?
    enum Kind {
        case positionX(SKRange)
        case positionY(SKRange)
        case zRotation(SKRange)
        case distance(SKRange, SKNode?, CGPoint?)
        case orient(SKNode?, CGPoint?, SKRange)
    }
    var kind: Kind = .positionX(SKRange.withNoLimits())

    public required override init() { super.init() }
    public required init?(coder: NSCoder) { super.init() }
    public func encode(with coder: NSCoder) {}
    public static var supportsSecureCoding: Bool { true }

    public class func positionX(_ range: SKRange) -> Self {
        let c = Self(); c.kind = .positionX(range); return c
    }

    public class func positionY(_ range: SKRange) -> Self {
        let c = Self(); c.kind = .positionY(range); return c
    }

    public class func positionX(_ xRange: SKRange, y yRange: SKRange) -> Self {
        let c = Self(); c.kind = .positionX(xRange); c._alsoY = yRange; return c
    }

    public class func zRotation(_ zRange: SKRange) -> Self {
        let c = Self(); c.kind = .zRotation(zRange); return c
    }

    public class func distance(_ range: SKRange, to node: SKNode) -> Self {
        let c = Self(); c.kind = .distance(range, node, nil); return c
    }

    public class func distance(_ range: SKRange, to point: CGPoint) -> Self {
        let c = Self(); c.kind = .distance(range, nil, point); return c
    }

    public class func distance(_ range: SKRange, to point: CGPoint, in node: SKNode) -> Self {
        let c = Self(); c.kind = .distance(range, node, point); return c
    }

    public class func orient(to node: SKNode, offset radians: SKRange) -> Self {
        let c = Self(); c.kind = .orient(node, nil, radians); return c
    }

    public class func orient(to point: CGPoint, offset radians: SKRange) -> Self {
        let c = Self(); c.kind = .orient(nil, point, radians); return c
    }

    public class func orient(to point: CGPoint, in node: SKNode, offset radians: SKRange) -> Self {
        let c = Self(); c.kind = .orient(node, point, radians); return c
    }

    var _alsoY: SKRange?

    func _apply(to node: SKNode) {
        switch kind {
        case .positionX(let range):
            node.position.x = range._clamp(node.position.x)
            if let y = _alsoY { node.position.y = y._clamp(node.position.y) }
        case .positionY(let range):
            node.position.y = range._clamp(node.position.y)
        case .zRotation(let range):
            node.zRotation = range._clamp(node.zRotation)
        case .distance(let range, let target, let point):
            let dest: CGPoint
            if let target {
                dest = node.convert(point ?? .zero, from: target)
            } else {
                dest = point ?? .zero
            }
            let dx = node.position.x - dest.x
            let dy = node.position.y - dest.y
            let dist = sk_hypot(dx, dy)
            let clamped = range._clamp(dist)
            if dist > 0, clamped != dist {
                let s = clamped / dist
                node.position.x = dest.x + dx * s
                node.position.y = dest.y + dy * s
            }
        case .orient(let target, let point, let offset):
            let dest: CGPoint
            if let target {
                dest = node.convert(point ?? .zero, from: target)
            } else {
                dest = point ?? node.position
            }
            let angle = CGFloat(atan2(Double(dest.y - node.position.y), Double(dest.x - node.position.x)))
            node.zRotation = offset._clamp(angle)
        }
    }
}

open class SKAttribute: NSObject, NSSecureCoding {
    public let name: String
    public let type: SKAttributeType

    public init(name: String, type: SKAttributeType) {
        self.name = name
        self.type = type
        super.init()
    }

    public required init?(coder: NSCoder) {
        name = (coder.decodeObject(forKey: "name") as? String) ?? ""
        type = SKAttributeType(rawValue: coder.decodeInteger(forKey: "type")) ?? .none
        super.init()
    }

    public func encode(with coder: NSCoder) {
        coder.encode(name, forKey: "name")
        coder.encode(type.rawValue, forKey: "type")
    }

    public static var supportsSecureCoding: Bool { true }
}

open class SKAttributeValue: NSObject, NSSecureCoding {
    public var floatValue: Float = 0
    public var vectorFloat2Value: vector_float2 = SIMD2<Float>(0, 0)
    public var vectorFloat3Value: vector_float3 = SIMD3<Float>(0, 0, 0)
    public var vectorFloat4Value: vector_float4 = SIMD4<Float>(0, 0, 0, 0)

    public override init() { super.init() }
    public convenience init(float value: Float) {
        self.init(); floatValue = value
    }
    public convenience init(vectorFloat2 value: vector_float2) {
        self.init(); vectorFloat2Value = value
    }
    public convenience init(vectorFloat3 value: vector_float3) {
        self.init(); vectorFloat3Value = value
    }
    public convenience init(vectorFloat4 value: vector_float4) {
        self.init(); vectorFloat4Value = value
    }
    public required init?(coder: NSCoder) {
        floatValue = coder.decodeFloat(forKey: "f")
        super.init()
    }
    public func encode(with coder: NSCoder) {
        coder.encode(floatValue, forKey: "f")
    }
    public static var supportsSecureCoding: Bool { true }
}

open class SKUniform: NSObject, NSSecureCoding {
    public let name: String
    public private(set) var uniformType: SKUniformType
    public var floatValue: Float = 0
    public var vectorFloat2Value: vector_float2 = SIMD2<Float>(0, 0)
    public var vectorFloat3Value: vector_float3 = SIMD3<Float>(0, 0, 0)
    public var vectorFloat4Value: vector_float4 = SIMD4<Float>(0, 0, 0, 0)
    public var matrixFloat2x2Value = matrix_float2x2()
    public var matrixFloat3x3Value = matrix_float3x3()
    public var matrixFloat4x4Value = matrix_float4x4()
    public var textureValue: SKTexture?

    public init(name: String) {
        self.name = name
        self.uniformType = .none
        super.init()
    }

    public init(name: String, float value: Float) {
        self.name = name
        self.uniformType = .float
        self.floatValue = value
        super.init()
    }

    public init(name: String, vectorFloat2 value: vector_float2) {
        self.name = name
        self.uniformType = .floatVector2
        self.vectorFloat2Value = value
        super.init()
    }

    public init(name: String, vectorFloat3 value: vector_float3) {
        self.name = name
        self.uniformType = .floatVector3
        self.vectorFloat3Value = value
        super.init()
    }

    public init(name: String, vectorFloat4 value: vector_float4) {
        self.name = name
        self.uniformType = .floatVector4
        self.vectorFloat4Value = value
        super.init()
    }

    public init(name: String, matrixFloat2x2 value: matrix_float2x2) {
        self.name = name
        self.uniformType = .floatMatrix2
        self.matrixFloat2x2Value = value
        super.init()
    }

    public init(name: String, matrixFloat3x3 value: matrix_float3x3) {
        self.name = name
        self.uniformType = .floatMatrix3
        self.matrixFloat3x3Value = value
        super.init()
    }

    public init(name: String, matrixFloat4x4 value: matrix_float4x4) {
        self.name = name
        self.uniformType = .floatMatrix4
        self.matrixFloat4x4Value = value
        super.init()
    }

    public init(name: String, texture: SKTexture?) {
        self.name = name
        self.uniformType = .texture
        self.textureValue = texture
        super.init()
    }

    public required init?(coder: NSCoder) {
        name = (coder.decodeObject(forKey: "name") as? String) ?? ""
        uniformType = .none
        super.init()
    }

    public func encode(with coder: NSCoder) {
        coder.encode(name, forKey: "name")
    }

    public static var supportsSecureCoding: Bool { true }
}

open class SKShader: NSObject, NSSecureCoding {
    public var source: String?
    public var uniforms: [SKUniform] = []
    public var attributes: [SKAttribute] = []

    public override init() { super.init() }

    public init(source: String) {
        self.source = source
        super.init()
    }

    public init(source: String, uniforms: [SKUniform]) {
        self.source = source
        self.uniforms = uniforms
        super.init()
    }

    public convenience init(fileNamed name: String) {
        self.init(source: "")
        _ = name
    }

    public required init?(coder: NSCoder) {
        source = coder.decodeObject(forKey: "source") as? String
        super.init()
    }

    public func encode(with coder: NSCoder) {
        coder.encode(source, forKey: "source")
    }

    public static var supportsSecureCoding: Bool { true }

    public func addUniform(_ uniform: SKUniform) {
        uniforms.removeAll { $0.name == uniform.name }
        uniforms.append(uniform)
    }

    public func removeUniformNamed(_ name: String) {
        uniforms.removeAll { $0.name == name }
    }

    public func uniformNamed(_ name: String) -> SKUniform? {
        uniforms.first { $0.name == name }
    }
}

open class SKWarpGeometry: NSObject, NSSecureCoding {
    public override init() { super.init() }
    public required init?(coder: NSCoder) { super.init() }
    public func encode(with coder: NSCoder) {}
    public static var supportsSecureCoding: Bool { true }
}

public protocol SKWarpable: NSObjectProtocol {
    var subdivisionLevels: Int { get set }
    var warpGeometry: SKWarpGeometry? { get set }
}

open class SKWarpGeometryGrid: SKWarpGeometry {
    public let numberOfColumns: Int
    public let numberOfRows: Int
    var source: [vector_float2]
    var dest: [vector_float2]

    public var vertexCount: Int { (numberOfColumns + 1) * (numberOfRows + 1) }

    public convenience init(columns cols: Int, rows: Int) {
        self.init(columns: cols, rows: rows, sourcePositions: [], destinationPositions: [])
    }

    public convenience init(
        columns: Int,
        rows: Int,
        sourcePositions: [SIMD2<Float>] = [SIMD2<Float>](),
        destinationPositions: [SIMD2<Float>] = [SIMD2<Float>]()
    ) {
        let count = (columns + 1) * (rows + 1)
        var src = sourcePositions
        var dst = destinationPositions
        if src.count < count {
            src = SKWarpGeometryGrid._identity(columns: columns, rows: rows)
        }
        if dst.count < count {
            dst = src
        }
        self.init(columns: columns, rows: rows, source: src, dest: dst)
    }

    init(columns: Int, rows: Int, source: [vector_float2], dest: [vector_float2]) {
        self.numberOfColumns = max(1, columns)
        self.numberOfRows = max(1, rows)
        self.source = source
        self.dest = dest
        super.init()
    }

    public required init?(coder: NSCoder) {
        numberOfColumns = 1
        numberOfRows = 1
        source = SKWarpGeometryGrid._identity(columns: 1, rows: 1)
        dest = source
        super.init(coder: coder)
    }

    public func sourcePosition(at index: Int) -> vector_float2 {
        guard index >= 0, index < source.count else { return SIMD2<Float>(0, 0) }
        return source[index]
    }

    public func destPosition(at index: Int) -> vector_float2 {
        guard index >= 0, index < dest.count else { return SIMD2<Float>(0, 0) }
        return dest[index]
    }

    public func replacingBySourcePositions(positions source: [SIMD2<Float>]) -> SKWarpGeometryGrid {
        SKWarpGeometryGrid(columns: numberOfColumns, rows: numberOfRows, source: source, dest: dest)
    }

    public func replacingByDestinationPositions(positions destination: [SIMD2<Float>]) -> SKWarpGeometryGrid {
        SKWarpGeometryGrid(columns: numberOfColumns, rows: numberOfRows, source: source, dest: destination)
    }

    static func _identity(columns: Int, rows: Int) -> [vector_float2] {
        var points: [vector_float2] = []
        let cols = max(1, columns)
        let rws = max(1, rows)
        for y in 0...rws {
            for x in 0...cols {
                let u = Float(x) / Float(cols)
                let v = Float(y) / Float(rws)
                points.append(SIMD2<Float>(u, v))
            }
        }
        return points
    }
}

open class SKRegion: NSObject, NSCopying, NSSecureCoding {
    enum Kind {
        case infinite
        case radius(Float)
        case size(CGSize)
        case path(CGPath)
    }
    var kind: Kind = .infinite
    public var path: CGPath?

    public required override init() { super.init() }

    public class func infinite() -> Self {
        let r = Self(); r.kind = .infinite; return r
    }

    public init(radius: Float) {
        kind = .radius(radius)
        super.init()
    }

    public init(size: CGSize) {
        kind = .size(size)
        super.init()
    }

    public init(path: CGPath) {
        kind = .path(path)
        self.path = path
        super.init()
    }

    public required init?(coder: NSCoder) { super.init() }
    public func encode(with coder: NSCoder) {}
    public static var supportsSecureCoding: Bool { true }
    public func copy(with zone: NSZone? = nil) -> Any { self }

    public func contains(_ point: CGPoint) -> Bool {
        switch kind {
        case .infinite:
            return true
        case .radius(let r):
            return sk_hypot(point.x, point.y) <= CGFloat(r)
        case .size(let size):
            return CGRect(x: -size.width / 2, y: -size.height / 2, width: size.width, height: size.height)
                .contains(point)
        case .path(let path):
            return path.contains(point)
        }
    }

    public func inverse() -> Self {
        self
    }

    public func byDifference(from region: SKRegion) -> Self {
        _ = region
        return self
    }

    public func byIntersection(with region: SKRegion) -> Self {
        _ = region
        return self
    }

    public func byUnion(with region: SKRegion) -> Self {
        _ = region
        return self
    }
}
