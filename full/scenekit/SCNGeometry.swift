import Foundation

public final class SCNGeometrySource: NSObject {
    public struct Semantic: RawRepresentable, Hashable, Sendable {
        public let rawValue: String
        public init(rawValue: String) { self.rawValue = rawValue }
        public init(_ rawValue: String) { self.rawValue = rawValue }

        public static let vertex = Semantic(rawValue: "vertex")
        public static let normal = Semantic(rawValue: "normal")
        public static let color = Semantic(rawValue: "color")
        public static let texcoord = Semantic(rawValue: "texcoord")
        public static let tangent = Semantic(rawValue: "tangent")
        public static let edgeCrease = Semantic(rawValue: "edgeCrease")
        public static let vertexCrease = Semantic(rawValue: "vertexCrease")
        public static let boneWeights = Semantic(rawValue: "boneWeights")
        public static let boneIndices = Semantic(rawValue: "boneIndices")
    }

    public let data: Data
    public let semantic: Semantic
    public let vectorCount: Int
    public let usesFloatComponents: Bool
    public let componentsPerVector: Int
    public let bytesPerComponent: Int
    public let dataOffset: Int
    public let dataStride: Int

    public convenience init(
        data: Data,
        semantic: Semantic,
        vectorCount: Int,
        usesFloatComponents floatComponents: Bool,
        componentsPerVector: Int,
        bytesPerComponent: Int,
        dataOffset: Int,
        dataStride: Int
    ) {
        self.init(
            data: data,
            semantic: semantic,
            vectorCount: vectorCount,
            floatComponents: floatComponents,
            componentsPerVector: componentsPerVector,
            bytesPerComponent: bytesPerComponent,
            dataOffset: dataOffset,
            dataStride: dataStride
        )
    }

    public init(
        data: Data,
        semantic: Semantic,
        vectorCount: Int,
        floatComponents: Bool,
        componentsPerVector: Int,
        bytesPerComponent: Int,
        dataOffset: Int,
        dataStride: Int
    ) {
        self.data = data
        self.semantic = semantic
        self.vectorCount = vectorCount
        self.usesFloatComponents = floatComponents
        self.componentsPerVector = componentsPerVector
        self.bytesPerComponent = bytesPerComponent
        self.dataOffset = dataOffset
        self.dataStride = dataStride
        super.init()
    }

    public convenience init(vertices: [SCNVector3]) {
        var payload = Data(count: vertices.count * MemoryLayout<SCNVector3>.stride)
        payload.withUnsafeMutableBytes { raw in
            guard let base = raw.baseAddress else { return }
            vertices.withUnsafeBytes { source in
                if let src = source.baseAddress {
                    base.copyMemory(from: src, byteCount: source.count)
                }
            }
        }
        self.init(
            data: payload,
            semantic: .vertex,
            vectorCount: vertices.count,
            floatComponents: true,
            componentsPerVector: 3,
            bytesPerComponent: MemoryLayout<Float>.size,
            dataOffset: 0,
            dataStride: MemoryLayout<SCNVector3>.stride
        )
    }

    public convenience init(normals: [SCNVector3]) {
        var payload = Data(count: normals.count * MemoryLayout<SCNVector3>.stride)
        payload.withUnsafeMutableBytes { raw in
            guard let base = raw.baseAddress else { return }
            normals.withUnsafeBytes { source in
                if let src = source.baseAddress {
                    base.copyMemory(from: src, byteCount: source.count)
                }
            }
        }
        self.init(
            data: payload,
            semantic: .normal,
            vectorCount: normals.count,
            floatComponents: true,
            componentsPerVector: 3,
            bytesPerComponent: MemoryLayout<Float>.size,
            dataOffset: 0,
            dataStride: MemoryLayout<SCNVector3>.stride
        )
    }

    public convenience init(textureCoordinates: [CGPoint]) {
        var values: [Float] = []
        values.reserveCapacity(textureCoordinates.count * 2)
        for point in textureCoordinates {
            values.append(Float(point.x))
            values.append(Float(point.y))
        }
        let payload = values.withUnsafeBufferPointer { Data(buffer: $0) }
        self.init(
            data: payload,
            semantic: .texcoord,
            vectorCount: textureCoordinates.count,
            floatComponents: true,
            componentsPerVector: 2,
            bytesPerComponent: MemoryLayout<Float>.size,
            dataOffset: 0,
            dataStride: MemoryLayout<Float>.size * 2
        )
    }

    public required init?(coder: NSCoder) {
        return nil
    }
}

public final class SCNGeometryElement: NSObject {
    public let data: Data
    public let primitiveType: SCNGeometryPrimitiveType
    public let primitiveCount: Int
    public let bytesPerIndex: Int
    public let indicesChannelCount: Int
    public let hasInterleavedIndicesChannels: Bool
    public var maximumPointScreenSpaceRadius: CGFloat = 1
    public var minimumPointScreenSpaceRadius: CGFloat = 0.5
    public var pointSize: CGFloat = 1
    public var primitiveRange: NSRange

    public convenience init(
        data: Data?,
        primitiveType: SCNGeometryPrimitiveType,
        primitiveCount: Int,
        bytesPerIndex: Int
    ) {
        self.init(
            data: data,
            primitiveType: primitiveType,
            primitiveCount: primitiveCount,
            indicesChannelCount: 1,
            interleavedIndicesChannels: false,
            bytesPerIndex: bytesPerIndex
        )
    }

    public init(
        data: Data?,
        primitiveType: SCNGeometryPrimitiveType,
        primitiveCount: Int,
        indicesChannelCount: Int,
        interleavedIndicesChannels: Bool,
        bytesPerIndex: Int
    ) {
        self.data = data ?? Data()
        self.primitiveType = primitiveType
        self.primitiveCount = primitiveCount
        self.bytesPerIndex = bytesPerIndex
        self.indicesChannelCount = indicesChannelCount
        self.hasInterleavedIndicesChannels = interleavedIndicesChannels
        self.primitiveRange = NSRange(location: 0, length: primitiveCount)
        super.init()
    }

    public convenience init<IndexType: FixedWidthInteger>(
        indices: [IndexType],
        primitiveType: SCNGeometryPrimitiveType
    ) {
        let payload = indices.withUnsafeBufferPointer { Data(buffer: $0) }
        let primitiveCount: Int
        switch primitiveType {
        case .triangles: primitiveCount = indices.count / 3
        case .triangleStrip: primitiveCount = max(0, indices.count - 2)
        case .line: primitiveCount = indices.count / 2
        case .point: primitiveCount = indices.count
        case .polygon: primitiveCount = 1
        }
        self.init(
            data: payload,
            primitiveType: primitiveType,
            primitiveCount: primitiveCount,
            bytesPerIndex: MemoryLayout<IndexType>.size
        )
    }

    public required init?(coder: NSCoder) {
        return nil
    }
}

open class SCNGeometry: NSObject, SCNBoundingVolume, SCNAnimatable, SCNShadable {
    public var name: String?
    public var sources: [SCNGeometrySource] = []
    public var elements: [SCNGeometryElement] = []
    public var geometrySourceChannels: [NSNumber]?
    public var materials: [SCNMaterial] = [SCNMaterial()]
    public var levelsOfDetail: [SCNLevelOfDetail]?
    public var subdivisionLevel: Int = 0
    public var tessellator: SCNGeometryTessellator?
    public var wantsAdaptiveSubdivision = false
    public var edgeCreasesElement: SCNGeometryElement?
    public var edgeCreasesSource: SCNGeometrySource?
    var _boundingBoxOverride: (min: SCNVector3, max: SCNVector3)?

    public override init() {
        super.init()
    }

    public convenience init(sources: [SCNGeometrySource], elements: [SCNGeometryElement]?) {
        self.init(sources: sources, elements: elements, sourceChannels: nil)
    }

    public init(sources: [SCNGeometrySource], elements: [SCNGeometryElement]?, sourceChannels: [NSNumber]?) {
        self.sources = sources
        self.elements = elements ?? []
        self.geometrySourceChannels = sourceChannels
        super.init()
    }

    public var elementCount: Int { elements.count }

    public var firstMaterial: SCNMaterial? {
        get { materials.first }
        set {
            if let newValue {
                if materials.isEmpty {
                    materials = [newValue]
                } else {
                    materials[0] = newValue
                }
            } else if !materials.isEmpty {
                materials.removeFirst()
            }
        }
    }

    public func element(at elementIndex: Int) -> SCNGeometryElement {
        elements[elementIndex]
    }

    public func sources(for semantic: SCNGeometrySource.Semantic) -> [SCNGeometrySource] {
        sources.filter { $0.semantic == semantic }
    }

    public func insertMaterial(_ material: SCNMaterial, at index: Int) {
        materials.insert(material, at: index)
    }

    public func material(named name: String) -> SCNMaterial? {
        materials.first { $0.name == name }
    }

    public func removeMaterial(at index: Int) {
        materials.remove(at: index)
    }

    public func replaceMaterial(at index: Int, with material: SCNMaterial) {
        materials[index] = material
    }

    public var boundingBox: (min: SCNVector3, max: SCNVector3) {
        get { _boundingBoxOverride ?? _derivedBoundingBox() }
        set { _boundingBoxOverride = newValue }
    }

    public var boundingSphere: (center: SCNVector3, radius: Float) {
        let box = boundingBox
        let center = SCNVector3(
            (box.min.x + box.max.x) * 0.5,
            (box.min.y + box.max.y) * 0.5,
            (box.min.z + box.max.z) * 0.5
        )
        let radius = _scnLength(_scnSub(box.max, center))
        return (center, radius)
    }

    func _derivedBoundingBox() -> (min: SCNVector3, max: SCNVector3) {
        (SCNVector3(-0.5, -0.5, -0.5), SCNVector3(0.5, 0.5, 0.5))
    }

    public required init?(coder: NSCoder) {
        return nil
    }

    var _animationPlayers: [String: SCNAnimationPlayer] = [:]
    public var animationKeys: [String] { Array(_animationPlayers.keys) }
    public func addAnimation(_ animation: any SCNAnimationProtocol, forKey key: String?) {
        let player = SCNAnimationPlayer(animation: SCNAnimation())
        _animationPlayers[key ?? UUID().uuidString] = player
        _ = animation
    }
    public func addAnimationPlayer(_ player: SCNAnimationPlayer, forKey key: String?) {
        _animationPlayers[key ?? UUID().uuidString] = player
    }
    public func animationPlayer(forKey key: String) -> SCNAnimationPlayer? { _animationPlayers[key] }
    public func isAnimationPaused(forKey key: String) -> Bool { _animationPlayers[key]?.paused ?? false }
    public func pauseAnimation(forKey key: String) { _animationPlayers[key]?.paused = true }
    public func removeAllAnimations() { _animationPlayers.removeAll() }
    public func removeAllAnimations(withBlendOutDuration duration: CGFloat) {
        _ = duration
        _animationPlayers.removeAll()
    }
    public func removeAnimation(forKey key: String) { _animationPlayers.removeValue(forKey: key) }
    public func removeAnimation(forKey key: String, blendOutDuration duration: CGFloat) {
        _ = duration
        _animationPlayers.removeValue(forKey: key)
    }
    public func removeAnimation(forKey key: String, fadeOutDuration duration: CGFloat) {
        _ = duration
        _animationPlayers.removeValue(forKey: key)
    }
    public func resumeAnimation(forKey key: String) { _animationPlayers[key]?.paused = false }
    public func setAnimationSpeed(_ speed: CGFloat, forKey key: String) { _animationPlayers[key]?.speed = speed }
}

public final class SCNBox: SCNGeometry {
    public var width: CGFloat
    public var height: CGFloat
    public var length: CGFloat
    public var chamferRadius: CGFloat
    public var widthSegmentCount = 1
    public var heightSegmentCount = 1
    public var lengthSegmentCount = 1
    public var chamferSegmentCount = 5

    public convenience init(width: CGFloat, height: CGFloat, length: CGFloat, chamferRadius: CGFloat) {
        self.init()
        self.width = width
        self.height = height
        self.length = length
        self.chamferRadius = chamferRadius
    }

    public override init() {
        width = 1
        height = 1
        length = 1
        chamferRadius = 0
        super.init()
    }

    public required init?(coder: NSCoder) { return nil }

    override func _derivedBoundingBox() -> (min: SCNVector3, max: SCNVector3) {
        let hx = Float(width) * 0.5
        let hy = Float(height) * 0.5
        let hz = Float(length) * 0.5
        return (SCNVector3(-hx, -hy, -hz), SCNVector3(hx, hy, hz))
    }
}

public final class SCNSphere: SCNGeometry {
    public var radius: CGFloat
    public var isGeodesic = false
    public var segmentCount = 24

    public convenience init(radius: CGFloat) {
        self.init()
        self.radius = radius
    }

    public override init() {
        radius = 0.5
        super.init()
    }

    public required init?(coder: NSCoder) { return nil }

    override func _derivedBoundingBox() -> (min: SCNVector3, max: SCNVector3) {
        let r = Float(radius)
        return (SCNVector3(-r, -r, -r), SCNVector3(r, r, r))
    }
}

public final class SCNPlane: SCNGeometry {
    public var width: CGFloat
    public var height: CGFloat
    public var cornerRadius: CGFloat = 0
    public var widthSegmentCount = 1
    public var heightSegmentCount = 1
    public var cornerSegmentCount = 5

    public convenience init(width: CGFloat, height: CGFloat) {
        self.init()
        self.width = width
        self.height = height
    }

    public override init() {
        width = 1
        height = 1
        super.init()
    }

    public required init?(coder: NSCoder) { return nil }

    override func _derivedBoundingBox() -> (min: SCNVector3, max: SCNVector3) {
        let hx = Float(width) * 0.5
        let hy = Float(height) * 0.5
        return (SCNVector3(-hx, -hy, 0), SCNVector3(hx, hy, 0))
    }
}

public final class SCNCylinder: SCNGeometry {
    public var radius: CGFloat
    public var height: CGFloat
    public var radialSegmentCount = 48
    public var heightSegmentCount = 1

    public convenience init(radius: CGFloat, height: CGFloat) {
        self.init()
        self.radius = radius
        self.height = height
    }

    public override init() {
        radius = 0.5
        height = 1
        super.init()
    }

    public required init?(coder: NSCoder) { return nil }

    override func _derivedBoundingBox() -> (min: SCNVector3, max: SCNVector3) {
        let r = Float(radius)
        let hy = Float(height) * 0.5
        return (SCNVector3(-r, -hy, -r), SCNVector3(r, hy, r))
    }
}

public final class SCNCone: SCNGeometry {
    public var topRadius: CGFloat
    public var bottomRadius: CGFloat
    public var height: CGFloat
    public var radialSegmentCount = 48
    public var heightSegmentCount = 1

    public convenience init(topRadius: CGFloat, bottomRadius: CGFloat, height: CGFloat) {
        self.init()
        self.topRadius = topRadius
        self.bottomRadius = bottomRadius
        self.height = height
    }

    public override init() {
        topRadius = 0
        bottomRadius = 0.5
        height = 1
        super.init()
    }

    public required init?(coder: NSCoder) { return nil }

    override func _derivedBoundingBox() -> (min: SCNVector3, max: SCNVector3) {
        let r = Float(max(topRadius, bottomRadius))
        let hy = Float(height) * 0.5
        return (SCNVector3(-r, -hy, -r), SCNVector3(r, hy, r))
    }
}

public final class SCNCapsule: SCNGeometry {
    public var capRadius: CGFloat
    public var height: CGFloat
    public var capSegmentCount = 24
    public var heightSegmentCount = 1
    public var radialSegmentCount = 48

    public convenience init(capRadius: CGFloat, height: CGFloat) {
        self.init()
        self.capRadius = capRadius
        self.height = height
    }

    public override init() {
        capRadius = 0.5
        height = 2
        super.init()
    }

    public required init?(coder: NSCoder) { return nil }

    override func _derivedBoundingBox() -> (min: SCNVector3, max: SCNVector3) {
        let r = Float(capRadius)
        let hy = Float(height) * 0.5
        return (SCNVector3(-r, -hy, -r), SCNVector3(r, hy, r))
    }
}

public final class SCNTorus: SCNGeometry {
    public var ringRadius: CGFloat
    public var pipeRadius: CGFloat
    public var ringSegmentCount = 48
    public var pipeSegmentCount = 24

    public convenience init(ringRadius: CGFloat, pipeRadius: CGFloat) {
        self.init()
        self.ringRadius = ringRadius
        self.pipeRadius = pipeRadius
    }

    public override init() {
        ringRadius = 0.5
        pipeRadius = 0.25
        super.init()
    }

    public required init?(coder: NSCoder) { return nil }

    override func _derivedBoundingBox() -> (min: SCNVector3, max: SCNVector3) {
        let outer = Float(ringRadius + pipeRadius)
        let hy = Float(pipeRadius)
        return (SCNVector3(-outer, -hy, -outer), SCNVector3(outer, hy, outer))
    }
}

public final class SCNPyramid: SCNGeometry {
    public var width: CGFloat
    public var height: CGFloat
    public var length: CGFloat
    public var widthSegmentCount = 1
    public var heightSegmentCount = 1
    public var lengthSegmentCount = 1

    public convenience init(width: CGFloat, height: CGFloat, length: CGFloat) {
        self.init()
        self.width = width
        self.height = height
        self.length = length
    }

    public override init() {
        width = 1
        height = 1
        length = 1
        super.init()
    }

    public required init?(coder: NSCoder) { return nil }

    override func _derivedBoundingBox() -> (min: SCNVector3, max: SCNVector3) {
        let hx = Float(width) * 0.5
        let hy = Float(height)
        let hz = Float(length) * 0.5
        return (SCNVector3(-hx, 0, -hz), SCNVector3(hx, hy, hz))
    }
}

public final class SCNTube: SCNGeometry {
    public var innerRadius: CGFloat
    public var outerRadius: CGFloat
    public var height: CGFloat
    public var radialSegmentCount = 48
    public var heightSegmentCount = 1

    public convenience init(innerRadius: CGFloat, outerRadius: CGFloat, height: CGFloat) {
        self.init()
        self.innerRadius = innerRadius
        self.outerRadius = outerRadius
        self.height = height
    }

    public override init() {
        innerRadius = 0.25
        outerRadius = 0.5
        height = 1
        super.init()
    }

    public required init?(coder: NSCoder) { return nil }

    override func _derivedBoundingBox() -> (min: SCNVector3, max: SCNVector3) {
        let r = Float(outerRadius)
        let hy = Float(height) * 0.5
        return (SCNVector3(-r, -hy, -r), SCNVector3(r, hy, r))
    }
}

public final class SCNFloor: SCNGeometry {
    public var width: CGFloat = 0
    public var length: CGFloat = 0
    public var reflectivity: CGFloat = 0.25
    public var reflectionFalloffEnd: CGFloat = 0
    public var reflectionFalloffStart: CGFloat = 0
    public var reflectionCategoryBitMask = Int.max
    public var reflectionResolutionScaleFactor: CGFloat = 0.5

    public override init() {
        super.init()
    }

    public required init?(coder: NSCoder) { return nil }

    override func _derivedBoundingBox() -> (min: SCNVector3, max: SCNVector3) {
        let w = width == 0 ? 100 : width
        let l = length == 0 ? 100 : length
        return (SCNVector3(Float(-w / 2), 0, Float(-l / 2)), SCNVector3(Float(w / 2), 0, Float(l / 2)))
    }
}

public final class SCNText: SCNGeometry {
    public var string: Any?
    public var extrusionDepth: CGFloat
    public var alignmentMode = "left"
    public var truncationMode = "none"
    public var containerFrame = CGRect.zero
    public var chamferRadius: CGFloat = 0
    public var flatness: CGFloat = 0.6
    public var isWrapped = false

    public convenience init(string: Any?, extrusionDepth: CGFloat) {
        self.init()
        self.string = string
        self.extrusionDepth = extrusionDepth
    }

    public override init() {
        extrusionDepth = 1
        super.init()
    }

    public required init?(coder: NSCoder) { return nil }

    override func _derivedBoundingBox() -> (min: SCNVector3, max: SCNVector3) {
        (SCNVector3(0, 0, 0), SCNVector3(1, 1, Float(extrusionDepth)))
    }
}

public final class SCNGeometryTessellator: NSObject {
    public var isAdaptive = false
    public var isScreenSpace = false
    public var edgeTessellationFactor: CGFloat = 1
    public var insideTessellationFactor: CGFloat = 1
    public var maximumEdgeLength: CGFloat = 1
    public var smoothingMode = SCNTessellationSmoothingMode.none
    public var tessellationFactorScale: CGFloat = 1

    public override init() { super.init() }
    public required init?(coder: NSCoder) { return nil }
}

public final class SCNLevelOfDetail: NSObject {
    public var geometry: SCNGeometry?
    public var screenSpaceRadius: CGFloat = 0
    public var worldSpaceDistance: CGFloat = 0

    public override init() { super.init() }
    public required init?(coder: NSCoder) { return nil }
}

public final class SCNMorpher: NSObject, SCNAnimatable {
    public var targets: [SCNGeometry] = []
    public var weights: [NSNumber] = []
    public var calculationMode = SCNMorpherCalculationMode.normalized
    public var unifiesNormals = false
    var _animationPlayers: [String: SCNAnimationPlayer] = [:]

    public override init() { super.init() }
    public required init?(coder: NSCoder) { return nil }

    public var animationKeys: [String] { Array(_animationPlayers.keys) }
    public func addAnimation(_ animation: any SCNAnimationProtocol, forKey key: String?) {
        _ = animation
        _animationPlayers[key ?? UUID().uuidString] = SCNAnimationPlayer(animation: SCNAnimation())
    }
    public func addAnimationPlayer(_ player: SCNAnimationPlayer, forKey key: String?) {
        _animationPlayers[key ?? UUID().uuidString] = player
    }
    public func animationPlayer(forKey key: String) -> SCNAnimationPlayer? { _animationPlayers[key] }
    public func isAnimationPaused(forKey key: String) -> Bool { _animationPlayers[key]?.paused ?? false }
    public func pauseAnimation(forKey key: String) { _animationPlayers[key]?.paused = true }
    public func removeAllAnimations() { _animationPlayers.removeAll() }
    public func removeAllAnimations(withBlendOutDuration duration: CGFloat) {
        _ = duration
        _animationPlayers.removeAll()
    }
    public func removeAnimation(forKey key: String) { _animationPlayers.removeValue(forKey: key) }
    public func removeAnimation(forKey key: String, blendOutDuration duration: CGFloat) {
        _ = duration
        _animationPlayers.removeValue(forKey: key)
    }
    public func removeAnimation(forKey key: String, fadeOutDuration duration: CGFloat) {
        _ = duration
        _animationPlayers.removeValue(forKey: key)
    }
    public func resumeAnimation(forKey key: String) { _animationPlayers[key]?.paused = false }
    public func setAnimationSpeed(_ speed: CGFloat, forKey key: String) { _animationPlayers[key]?.speed = speed }
}
