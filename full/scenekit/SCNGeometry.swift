import Foundation

open class SCNGeometrySource: NSObject, NSSecureCoding {
    public struct Semantic: RawRepresentable, Hashable, Sendable {
        public var rawValue: String
        public init(rawValue: String) { self.rawValue = rawValue }
        public init(_ rawValue: String) { self.rawValue = rawValue }

        public static let vertex = Semantic(rawValue: "vertex")
        public static let normal = Semantic(rawValue: "normal")
        public static let color = Semantic(rawValue: "color")
        public static let texcoord = Semantic(rawValue: "texcoord")
        public static let tangent = Semantic(rawValue: "tangent")
        public static let vertexCrease = Semantic(rawValue: "vertexCrease")
        public static let edgeCrease = Semantic(rawValue: "edgeCrease")
        public static let boneWeights = Semantic(rawValue: "boneWeights")
        public static let boneIndices = Semantic(rawValue: "boneIndices")
    }

    public private(set) var data: Data
    public private(set) var semantic: Semantic
    public private(set) var vectorCount: Int
    public private(set) var usesFloatComponents: Bool
    public private(set) var componentsPerVector: Int
    public private(set) var bytesPerComponent: Int
    public private(set) var dataOffset: Int
    public private(set) var dataStride: Int

    public override init() {
        data = Data()
        semantic = .vertex
        vectorCount = 0
        usesFloatComponents = true
        componentsPerVector = 3
        bytesPerComponent = 4
        dataOffset = 0
        dataStride = 12
        super.init()
    }

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
        self.init()
        self.data = data
        self.semantic = semantic
        self.vectorCount = vectorCount
        self.usesFloatComponents = floatComponents
        self.componentsPerVector = componentsPerVector
        self.bytesPerComponent = bytesPerComponent
        self.dataOffset = dataOffset
        self.dataStride = dataStride
    }

    public convenience init(
        data: Data,
        semantic: Semantic,
        vectorCount: Int,
        floatComponents: Bool,
        componentsPerVector: Int,
        bytesPerComponent: Int,
        offset: Int,
        stride: Int
    ) {
        self.init(
            data: data,
            semantic: semantic,
            vectorCount: vectorCount,
            usesFloatComponents: floatComponents,
            componentsPerVector: componentsPerVector,
            bytesPerComponent: bytesPerComponent,
            dataOffset: offset,
            dataStride: stride
        )
    }

    public convenience init(vertices: [SCNVector3]) {
        var bytes: [Float] = []
        bytes.reserveCapacity(vertices.count * 3)
        for v in vertices {
            bytes.append(v.x)
            bytes.append(v.y)
            bytes.append(v.z)
        }
        let data = bytes.withUnsafeBufferPointer { Data(buffer: $0) }
        self.init(
            data: data,
            semantic: .vertex,
            vectorCount: vertices.count,
            usesFloatComponents: true,
            componentsPerVector: 3,
            bytesPerComponent: 4,
            dataOffset: 0,
            dataStride: 12
        )
    }

    public convenience init(normals: [SCNVector3]) {
        var bytes: [Float] = []
        bytes.reserveCapacity(normals.count * 3)
        for v in normals {
            bytes.append(v.x)
            bytes.append(v.y)
            bytes.append(v.z)
        }
        let data = bytes.withUnsafeBufferPointer { Data(buffer: $0) }
        self.init(
            data: data,
            semantic: .normal,
            vectorCount: normals.count,
            usesFloatComponents: true,
            componentsPerVector: 3,
            bytesPerComponent: 4,
            dataOffset: 0,
            dataStride: 12
        )
    }

    public convenience init(textureCoordinates: [CGPoint]) {
        var bytes: [Float] = []
        bytes.reserveCapacity(textureCoordinates.count * 2)
        for p in textureCoordinates {
            bytes.append(Float(p.x))
            bytes.append(Float(p.y))
        }
        let data = bytes.withUnsafeBufferPointer { Data(buffer: $0) }
        self.init(
            data: data,
            semantic: .texcoord,
            vectorCount: textureCoordinates.count,
            usesFloatComponents: true,
            componentsPerVector: 2,
            bytesPerComponent: 4,
            dataOffset: 0,
            dataStride: 8
        )
    }

    public static var supportsSecureCoding: Bool { true }

    public required init?(coder: NSCoder) {
        return nil
    }

    public func encode(with coder: NSCoder) {}
}

open class SCNGeometryElement: NSObject, NSSecureCoding {
    public private(set) var data: Data
    public private(set) var primitiveType: SCNGeometryPrimitiveType
    public private(set) var primitiveCount: Int
    public private(set) var bytesPerIndex: Int
    public var indicesChannelCount: Int
    public var hasInterleavedIndicesChannels: Bool
    public var maximumPointScreenSpaceRadius: CGFloat
    public var minimumPointScreenSpaceRadius: CGFloat
    public var pointSize: CGFloat
    public var primitiveRange: NSRange

    public override init() {
        data = Data()
        primitiveType = .triangles
        primitiveCount = 0
        bytesPerIndex = 2
        indicesChannelCount = 1
        hasInterleavedIndicesChannels = false
        maximumPointScreenSpaceRadius = 1
        minimumPointScreenSpaceRadius = 1
        pointSize = 1
        primitiveRange = NSRange(location: 0, length: 0)
        super.init()
    }

    public convenience init(
        data: Data?,
        primitiveType: SCNGeometryPrimitiveType,
        primitiveCount: Int,
        bytesPerIndex: Int
    ) {
        self.init()
        self.data = data ?? Data()
        self.primitiveType = primitiveType
        self.primitiveCount = primitiveCount
        self.bytesPerIndex = bytesPerIndex
        self.primitiveRange = NSRange(location: 0, length: primitiveCount)
    }

    public convenience init(
        data: Data?,
        primitiveType: SCNGeometryPrimitiveType,
        primitiveCount: Int,
        indicesChannelCount: Int,
        interleavedIndicesChannels: Bool,
        bytesPerIndex: Int
    ) {
        self.init(data: data, primitiveType: primitiveType, primitiveCount: primitiveCount, bytesPerIndex: bytesPerIndex)
        self.indicesChannelCount = indicesChannelCount
        self.hasInterleavedIndicesChannels = interleavedIndicesChannels
    }

    public convenience init<IndexType: FixedWidthInteger>(
        indices: [IndexType],
        primitiveType: SCNGeometryPrimitiveType
    ) {
        let values = indices
        let data = values.withUnsafeBufferPointer { Data(buffer: $0) }
        let primitiveCount: Int
        switch primitiveType {
        case .triangles:
            primitiveCount = indices.count / 3
        case .triangleStrip:
            primitiveCount = max(0, indices.count - 2)
        case .line:
            primitiveCount = indices.count / 2
        case .point:
            primitiveCount = indices.count
        case .polygon:
            primitiveCount = 1
        }
        self.init(
            data: data,
            primitiveType: primitiveType,
            primitiveCount: primitiveCount,
            bytesPerIndex: MemoryLayout<IndexType>.stride
        )
    }

    public static var supportsSecureCoding: Bool { true }
    public required init?(coder: NSCoder) { return nil }
    public func encode(with coder: NSCoder) {}
}

open class SCNGeometryTessellator: NSObject, NSSecureCoding {
    public var smoothingMode: SCNTessellationSmoothingMode = .none
    public var tessellationPartitionMode: Int = 0
    public var edgeTessellationFactor: CGFloat = 1
    public var insideTessellationFactor: CGFloat = 1
    public var isAdaptive: Bool = false
    public var isScreenSpace: Bool = false
    public var maximumEdgeLength: CGFloat = 1
    public var tessellationFactorScale: CGFloat = 1
    public override init() { super.init() }
    public static var supportsSecureCoding: Bool { true }
    public required init?(coder: NSCoder) { return nil }
    public func encode(with coder: NSCoder) {}
}

open class SCNLevelOfDetail: NSObject, NSCopying, NSSecureCoding {
    public private(set) var geometry: SCNGeometry?
    public private(set) var screenSpaceRadius: CGFloat
    public private(set) var worldSpaceDistance: CGFloat

    public override init() {
        screenSpaceRadius = 0
        worldSpaceDistance = 0
        super.init()
    }

    public convenience init(geometry: SCNGeometry?, screenSpaceRadius radius: CGFloat) {
        self.init()
        self.geometry = geometry
        self.screenSpaceRadius = radius
    }

    public convenience init(geometry: SCNGeometry?, worldSpaceDistance distance: CGFloat) {
        self.init()
        self.geometry = geometry
        self.worldSpaceDistance = distance
    }

    public func copy(with zone: NSZone? = nil) -> Any {
        let copy = SCNLevelOfDetail()
        copy.geometry = geometry
        copy.screenSpaceRadius = screenSpaceRadius
        copy.worldSpaceDistance = worldSpaceDistance
        return copy
    }

    public static var supportsSecureCoding: Bool { true }
    public required init?(coder: NSCoder) { return nil }
    public func encode(with coder: NSCoder) {}
}

open class SCNGeometry: NSObject, NSCopying, NSSecureCoding, SCNBoundingVolume, SCNAnimatable, SCNShadable {
    public var name: String?
    public var sources: [SCNGeometrySource]
    public var elements: [SCNGeometryElement]
    public var geometrySourceChannels: [NSNumber]?
    public var materials: [SCNMaterial]
    public var levelsOfDetail: [SCNLevelOfDetail]?
    public var subdivisionLevel: Int
    public var tessellator: SCNGeometryTessellator?
    public var wantsAdaptiveSubdivision: Bool
    public var edgeCreasesElement: SCNGeometryElement?
    public var edgeCreasesSource: SCNGeometrySource?
    public var _linuxBoundingBox: (min: SCNVector3, max: SCNVector3)
    public var program: SCNProgram?
    public var shaderModifiers: [SCNShaderModifierEntryPoint: String]?
    public var minimumLanguageVersion: NSNumber?
    var _animationPlayers: [String: SCNAnimationPlayer] = [:]

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

    public var elementCount: Int { elements.count }

    public var boundingBox: (min: SCNVector3, max: SCNVector3) {
        get { _linuxBoundingBox }
        set { _linuxBoundingBox = newValue }
    }

    public var boundingSphere: (center: SCNVector3, radius: Float) {
        let minB = _linuxBoundingBox.min
        let maxB = _linuxBoundingBox.max
        let center = SCNVector3(
            x: (minB.x + maxB.x) * 0.5,
            y: (minB.y + maxB.y) * 0.5,
            z: (minB.z + maxB.z) * 0.5
        )
        let radius = _scnLength(_scnSub(maxB, center))
        return (center, radius)
    }

    public override init() {
        sources = []
        elements = []
        materials = [SCNMaterial()]
        subdivisionLevel = 0
        wantsAdaptiveSubdivision = false
        _linuxBoundingBox = (SCNVector3(x: -0.5, y: -0.5, z: -0.5), SCNVector3(x: 0.5, y: 0.5, z: 0.5))
        super.init()
    }

    public convenience init(sources: [SCNGeometrySource], elements: [SCNGeometryElement]?) {
        self.init()
        self.sources = sources
        self.elements = elements ?? []
        _linuxBoundingBox = Self._box(from: sources)
    }

    public convenience init(
        sources: [SCNGeometrySource],
        elements: [SCNGeometryElement]?,
        sourceChannels: [NSNumber]?
    ) {
        self.init(sources: sources, elements: elements)
        self.geometrySourceChannels = sourceChannels
    }

    public func element(at elementIndex: Int) -> SCNGeometryElement {
        elements[elementIndex]
    }

    public func sources(for semantic: SCNGeometrySource.Semantic) -> [SCNGeometrySource] {
        sources.filter { $0.semantic == semantic }
    }

    public func insertMaterial(_ material: SCNMaterial, at index: Int) {
        let clamped = max(0, min(index, materials.count))
        materials.insert(material, at: clamped)
    }

    public func material(named name: String) -> SCNMaterial? {
        materials.first { $0.name == name }
    }

    public func removeMaterial(at index: Int) {
        guard materials.indices.contains(index) else { return }
        materials.remove(at: index)
    }

    public func replaceMaterial(at index: Int, with material: SCNMaterial) {
        guard materials.indices.contains(index) else { return }
        materials[index] = material
    }

    public func handleBinding(ofSymbol symbol: String, handler block: SCNBindingBlock?) {}
    public func handleUnbinding(ofSymbol symbol: String, handler block: SCNBindingBlock?) {}

    public func copy(with zone: NSZone? = nil) -> Any {
        let copy = SCNGeometry(sources: sources, elements: elements)
        copy.name = name
        copy.materials = materials
        copy.subdivisionLevel = subdivisionLevel
        copy._linuxBoundingBox = _linuxBoundingBox
        return copy
    }

    public var animationKeys: [String] { Array(_animationPlayers.keys) }
    public func addAnimation(_ animation: any SCNAnimationProtocol, forKey key: String?) {
        let player = SCNAnimationPlayer(animation: animation as? SCNAnimation ?? SCNAnimation())
        addAnimationPlayer(player, forKey: key)
    }
    public func addAnimationPlayer(_ player: SCNAnimationPlayer, forKey key: String?) {
        _animationPlayers[key ?? UUID().uuidString] = player
    }
    public func animationPlayer(forKey key: String) -> SCNAnimationPlayer? { _animationPlayers[key] }
    public func removeAllAnimations() { _animationPlayers.removeAll() }
    public func removeAllAnimations(withBlendOutDuration duration: CGFloat) { _animationPlayers.removeAll() }
    public func removeAnimation(forKey key: String) { _animationPlayers.removeValue(forKey: key) }
    public func removeAnimation(forKey key: String, blendOutDuration duration: CGFloat) { _animationPlayers.removeValue(forKey: key) }
    public func removeAnimation(forKey key: String, fadeOutDuration duration: CGFloat) { _animationPlayers.removeValue(forKey: key) }
    public func isAnimationPaused(forKey key: String) -> Bool { _animationPlayers[key]?.paused ?? false }
    public func pauseAnimation(forKey key: String) { _animationPlayers[key]?.paused = true }
    public func resumeAnimation(forKey key: String) { _animationPlayers[key]?.paused = false }
    public func setAnimationSpeed(_ speed: CGFloat, forKey key: String) { _animationPlayers[key]?.speed = speed }

    public static var supportsSecureCoding: Bool { true }
    public required init?(coder: NSCoder) { return nil }
    public func encode(with coder: NSCoder) {}

    private static func _box(from sources: [SCNGeometrySource]) -> (min: SCNVector3, max: SCNVector3) {
        let verts = sources.first { $0.semantic == .vertex }
        guard let verts, verts.vectorCount > 0, verts.usesFloatComponents, verts.componentsPerVector >= 3 else {
            return (SCNVector3(x: -0.5, y: -0.5, z: -0.5), SCNVector3(x: 0.5, y: 0.5, z: 0.5))
        }
        var minV = SCNVector3(x: Float.greatestFiniteMagnitude, y: Float.greatestFiniteMagnitude, z: Float.greatestFiniteMagnitude)
        var maxV = SCNVector3(x: -Float.greatestFiniteMagnitude, y: -Float.greatestFiniteMagnitude, z: -Float.greatestFiniteMagnitude)
        verts.data.withUnsafeBytes { raw in
            let floats = raw.bindMemory(to: Float.self)
            var offset = verts.dataOffset / 4
            let stride = max(verts.dataStride / 4, verts.componentsPerVector)
            for _ in 0..<verts.vectorCount {
                if offset + 2 < floats.count {
                    let x = floats[offset]
                    let y = floats[offset + 1]
                    let z = floats[offset + 2]
                    minV.x = min(minV.x, x); minV.y = min(minV.y, y); minV.z = min(minV.z, z)
                    maxV.x = max(maxV.x, x); maxV.y = max(maxV.y, y); maxV.z = max(maxV.z, z)
                }
                offset += stride
            }
        }
        return (minV, maxV)
    }
}

open class SCNBox: SCNGeometry {
    public var width: CGFloat
    public var height: CGFloat
    public var length: CGFloat
    public var chamferRadius: CGFloat
    public var widthSegmentCount: Int
    public var heightSegmentCount: Int
    public var lengthSegmentCount: Int
    public var chamferSegmentCount: Int

    public override init() {
        width = 1
        height = 1
        length = 1
        chamferRadius = 0
        widthSegmentCount = 1
        heightSegmentCount = 1
        lengthSegmentCount = 1
        chamferSegmentCount = 5
        super.init()
        _refreshPrimitiveBox()
    }

    public convenience init(width: CGFloat, height: CGFloat, length: CGFloat, chamferRadius: CGFloat) {
        self.init()
        self.width = width
        self.height = height
        self.length = length
        self.chamferRadius = chamferRadius
        _refreshPrimitiveBox()
    }

    public required init?(coder: NSCoder) { return nil }

    private func _refreshPrimitiveBox() {
        _scnAssignMesh(self, _scnBoxMesh(
            width: Float(width),
            height: Float(height),
            length: Float(length),
            wSeg: widthSegmentCount,
            hSeg: heightSegmentCount,
            lSeg: lengthSegmentCount
        ))
    }
}

open class SCNSphere: SCNGeometry {
    public var radius: CGFloat
    public var isGeodesic: Bool
    public var segmentCount: Int

    public override init() {
        radius = 0.5
        isGeodesic = false
        segmentCount = 24
        super.init()
        _refresh()
    }

    public convenience init(radius: CGFloat) {
        self.init()
        self.radius = radius
        _refresh()
    }

    public required init?(coder: NSCoder) { return nil }

    private func _refresh() {
        _scnAssignMesh(self, _scnSphereMesh(radius: Float(radius), segments: segmentCount, geodesic: isGeodesic))
    }
}

open class SCNPlane: SCNGeometry {
    public var width: CGFloat
    public var height: CGFloat
    public var cornerRadius: CGFloat
    public var widthSegmentCount: Int
    public var heightSegmentCount: Int
    public var cornerSegmentCount: Int

    public override init() {
        width = 1
        height = 1
        cornerRadius = 0
        widthSegmentCount = 1
        heightSegmentCount = 1
        cornerSegmentCount = 5
        super.init()
        _refresh()
    }

    public convenience init(width: CGFloat, height: CGFloat) {
        self.init()
        self.width = width
        self.height = height
        _refresh()
    }

    public required init?(coder: NSCoder) { return nil }

    private func _refresh() {
        _scnAssignMesh(self, _scnPlaneMesh(width: Float(width), height: Float(height), wSeg: widthSegmentCount, hSeg: heightSegmentCount))
    }
}

open class SCNCapsule: SCNGeometry {
    public var capRadius: CGFloat
    public var height: CGFloat
    public var radialSegmentCount: Int
    public var heightSegmentCount: Int
    public var capSegmentCount: Int

    public override init() {
        capRadius = 0.5
        height = 2
        radialSegmentCount = 24
        heightSegmentCount = 1
        capSegmentCount = 24
        super.init()
        _refresh()
    }

    public convenience init(capRadius: CGFloat, height: CGFloat) {
        self.init()
        self.capRadius = capRadius
        self.height = height
        _refresh()
    }

    private func _refresh() {
        _scnAssignMesh(self, _scnCapsuleMesh(
            capRadius: Float(capRadius),
            height: Float(height),
            radial: radialSegmentCount,
            heightSeg: heightSegmentCount,
            capSeg: capSegmentCount
        ))
    }

    public required init?(coder: NSCoder) { return nil }
}

open class SCNCone: SCNGeometry {
    public var topRadius: CGFloat
    public var bottomRadius: CGFloat
    public var height: CGFloat
    public var radialSegmentCount: Int
    public var heightSegmentCount: Int

    public override init() {
        topRadius = 0
        bottomRadius = 0.5
        height = 1
        radialSegmentCount = 24
        heightSegmentCount = 1
        super.init()
        _refresh()
    }

    public convenience init(topRadius: CGFloat, bottomRadius: CGFloat, height: CGFloat) {
        self.init()
        self.topRadius = topRadius
        self.bottomRadius = bottomRadius
        self.height = height
        _refresh()
    }

    private func _refresh() {
        _scnAssignMesh(self, _scnConeMesh(
            topRadius: Float(topRadius),
            bottomRadius: Float(bottomRadius),
            height: Float(height),
            radial: radialSegmentCount,
            heightSeg: heightSegmentCount
        ))
    }

    public required init?(coder: NSCoder) { return nil }
}

open class SCNCylinder: SCNGeometry {
    public var radius: CGFloat
    public var height: CGFloat
    public var radialSegmentCount: Int
    public var heightSegmentCount: Int

    public override init() {
        radius = 0.5
        height = 1
        radialSegmentCount = 24
        heightSegmentCount = 1
        super.init()
        _refresh()
    }

    public convenience init(radius: CGFloat, height: CGFloat) {
        self.init()
        self.radius = radius
        self.height = height
        _refresh()
    }

    private func _refresh() {
        _scnAssignMesh(self, _scnCylinderMesh(
            radius: Float(radius),
            height: Float(height),
            radial: radialSegmentCount,
            heightSeg: heightSegmentCount,
            top: true,
            bottom: true
        ))
    }

    public required init?(coder: NSCoder) { return nil }
}

open class SCNPyramid: SCNGeometry {
    public var width: CGFloat
    public var height: CGFloat
    public var length: CGFloat
    public var widthSegmentCount: Int
    public var heightSegmentCount: Int
    public var lengthSegmentCount: Int

    public override init() {
        width = 1
        height = 1
        length = 1
        widthSegmentCount = 1
        heightSegmentCount = 1
        lengthSegmentCount = 1
        super.init()
        _refresh()
    }

    public convenience init(width: CGFloat, height: CGFloat, length: CGFloat) {
        self.init()
        self.width = width
        self.height = height
        self.length = length
        _refresh()
    }

    private func _refresh() {
        _scnAssignMesh(self, _scnPyramidMesh(width: Float(width), height: Float(height), length: Float(length)))
    }

    public required init?(coder: NSCoder) { return nil }
}

open class SCNTorus: SCNGeometry {
    public var ringRadius: CGFloat
    public var pipeRadius: CGFloat
    public var ringSegmentCount: Int
    public var pipeSegmentCount: Int

    public override init() {
        ringRadius = 0.5
        pipeRadius = 0.25
        ringSegmentCount = 24
        pipeSegmentCount = 24
        super.init()
        _refresh()
    }

    public convenience init(ringRadius: CGFloat, pipeRadius: CGFloat) {
        self.init()
        self.ringRadius = ringRadius
        self.pipeRadius = pipeRadius
        _refresh()
    }

    private func _refresh() {
        _scnAssignMesh(self, _scnTorusMesh(
            ringRadius: Float(ringRadius),
            pipeRadius: Float(pipeRadius),
            ringSeg: ringSegmentCount,
            pipeSeg: pipeSegmentCount
        ))
    }

    public required init?(coder: NSCoder) { return nil }
}

open class SCNTube: SCNGeometry {
    public var innerRadius: CGFloat
    public var outerRadius: CGFloat
    public var height: CGFloat
    public var radialSegmentCount: Int
    public var heightSegmentCount: Int

    public override init() {
        innerRadius = 0.25
        outerRadius = 0.5
        height = 1
        radialSegmentCount = 24
        heightSegmentCount = 1
        super.init()
        _refresh()
    }

    public convenience init(innerRadius: CGFloat, outerRadius: CGFloat, height: CGFloat) {
        self.init()
        self.innerRadius = innerRadius
        self.outerRadius = outerRadius
        self.height = height
        _refresh()
    }

    private func _refresh() {
        _scnAssignMesh(self, _scnTubeMesh(
            inner: Float(innerRadius),
            outer: Float(outerRadius),
            height: Float(height),
            radial: radialSegmentCount,
            heightSeg: heightSegmentCount
        ))
    }

    public required init?(coder: NSCoder) { return nil }
}

open class SCNFloor: SCNGeometry {
    public var width: CGFloat = 0
    public var length: CGFloat = 0
    public var reflectivity: CGFloat = 0.25
    public var reflectionFalloffStart: CGFloat = 0
    public var reflectionFalloffEnd: CGFloat = 0
    public var reflectionCategoryBitMask: Int = .max
    public var reflectionResolutionScaleFactor: CGFloat = 0.5

    public override init() {
        super.init()
        _scnAssignMesh(self, _scnPlaneMesh(width: 100, height: 100, wSeg: 1, hSeg: 1))
        _linuxBoundingBox = (SCNVector3(x: -50, y: 0, z: -50), SCNVector3(x: 50, y: 0, z: 50))
    }

    public required init?(coder: NSCoder) { return nil }
}

open class SCNText: SCNGeometry {
    public var string: Any?
    public var extrusionDepth: CGFloat
    public var alignmentMode: String
    public var truncationMode: String
    public var isWrapped: Bool
    public var flatness: CGFloat
    public var chamferRadius: CGFloat
    public var containerFrame: CGRect

    public override init() {
        extrusionDepth = 0
        alignmentMode = "left"
        truncationMode = "none"
        isWrapped = false
        flatness = 0.5
        chamferRadius = 0
        containerFrame = .zero
        super.init()
    }

    public convenience init(string: Any?, extrusionDepth: CGFloat) {
        self.init()
        self.string = string
        self.extrusionDepth = extrusionDepth
    }

    public required init?(coder: NSCoder) { return nil }
}

open class SCNShape: SCNGeometry {
    public var extrusionDepth: CGFloat
    public var chamferMode: SCNChamferMode
    public var chamferRadius: CGFloat

    public override init() {
        extrusionDepth = 1
        chamferMode = .both
        chamferRadius = 0
        super.init()
    }

    public required init?(coder: NSCoder) { return nil }
}

extension SCNGeometry {
    func _extentBox(x: Float, y: Float, z: Float) {
        _linuxBoundingBox = (SCNVector3(x: -x, y: -y, z: -z), SCNVector3(x: x, y: y, z: z))
    }
}
