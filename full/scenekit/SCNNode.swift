import Foundation

open class SCNConstraint: NSObject, NSCopying, NSSecureCoding, SCNAnimatable {
    public var isEnabled: Bool = true
    public var isIncremental: Bool = false
    public var influenceFactor: CGFloat = 1
    var _animationPlayers: [String: SCNAnimationPlayer] = [:]

    public override init() { super.init() }
    public func copy(with zone: NSZone? = nil) -> Any { SCNConstraint() }

    public var animationKeys: [String] { Array(_animationPlayers.keys) }
    public func addAnimation(_ animation: any SCNAnimationProtocol, forKey key: String?) {
        addAnimationPlayer(SCNAnimationPlayer(animation: animation as? SCNAnimation ?? SCNAnimation()), forKey: key)
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
}

open class SCNLookAtConstraint: SCNConstraint {
    public weak var target: SCNNode?
    public var isGimbalLockEnabled: Bool = false
    public var localFront: SCNVector3 = SCNNode.localFront
    public var targetOffset: SCNVector3 = SCNVector3Zero
    public var worldUp: SCNVector3 = SCNNode.localUp

    public override init() { super.init() }

    public convenience init(target: SCNNode?) {
        self.init()
        self.target = target
    }

    public required init?(coder: NSCoder) { return nil }
}

open class SCNBillboardConstraint: SCNConstraint {
    public var freeAxes: SCNBillboardAxis = .all
    public override init() { super.init() }
    public required init?(coder: NSCoder) { return nil }
}

open class SCNTransformConstraint: SCNConstraint {
    var _worldSpace = false
    var _block: ((SCNNode, SCNMatrix4) -> SCNMatrix4)?

    public override init() { super.init() }

    public convenience init(inWorldSpace world: Bool, with block: @escaping (SCNNode, SCNMatrix4) -> SCNMatrix4) {
        self.init()
        _worldSpace = world
        _block = block
    }

    public convenience init(inWorldSpace world: Bool, withBlock block: @escaping (SCNNode, SCNMatrix4) -> SCNMatrix4) {
        self.init(inWorldSpace: world, with: block)
    }

    public class func orientationConstraint(
        inWorldSpace world: Bool,
        with block: @escaping (SCNNode, SCNQuaternion) -> SCNQuaternion
    ) -> SCNTransformConstraint {
        SCNTransformConstraint(inWorldSpace: world, with: { node, transform in
            _ = block
            return transform
        })
    }

    public class func positionConstraint(
        inWorldSpace world: Bool,
        with block: @escaping (SCNNode, SCNVector3) -> SCNVector3
    ) -> SCNTransformConstraint {
        SCNTransformConstraint(inWorldSpace: world, with: { node, transform in
            _ = block
            return transform
        })
    }

    public required init?(coder: NSCoder) { return nil }
}

open class SCNDistanceConstraint: SCNConstraint {
    public weak var target: SCNNode?
    public var minimumDistance: CGFloat = 0
    public var maximumDistance: CGFloat = 0

    public override init() { super.init() }

    public convenience init(target: SCNNode?) {
        self.init()
        self.target = target
    }

    public required init?(coder: NSCoder) { return nil }
}

open class SCNReplicatorConstraint: SCNConstraint {
    public weak var target: SCNNode?
    public var replicatesOrientation: Bool = true
    public var replicatesPosition: Bool = true
    public var replicatesScale: Bool = true
    public var orientationOffset: SCNQuaternion = SCNVector4(x: 0, y: 0, z: 0, w: 1)
    public var positionOffset: SCNVector3 = SCNVector3Zero
    public var scaleOffset: SCNVector3 = SCNVector3Zero
    public override init() { super.init() }
    public convenience init(target: SCNNode?) {
        self.init()
        self.target = target
    }
    public required init?(coder: NSCoder) { return nil }
}

open class SCNAccelerationConstraint: SCNConstraint {
    public var maximumLinearAcceleration: CGFloat = 0
    public var maximumLinearVelocity: CGFloat = 0
    public var decelerationDistance: CGFloat = 0
    public var damping: CGFloat = 0.1
    public override init() { super.init() }
    public required init?(coder: NSCoder) { return nil }
}

open class SCNAvoidOccluderConstraint: SCNConstraint {
    public weak var target: SCNNode?
    public var occluderCategoryBitMask: Int = 1
    public var bias: CGFloat = 0
    public weak var delegate: SCNAvoidOccluderConstraintDelegate?
    public override init() { super.init() }
    public required init?(coder: NSCoder) { return nil }
}

open class SCNIKConstraint: SCNConstraint {
    public var chainRootNode: SCNNode?
    public var targetPosition: SCNVector3 = SCNVector3Zero
    private var _jointAngles: [ObjectIdentifier: CGFloat] = [:]

    public override init() { super.init() }

    public class func inverseKinematicsConstraint(chainRootNode: SCNNode) -> SCNIKConstraint {
        let constraint = SCNIKConstraint()
        constraint.chainRootNode = chainRootNode
        return constraint
    }

    public func maxAllowedRotationAngle(forJoint node: SCNNode) -> CGFloat {
        _jointAngles[ObjectIdentifier(node)] ?? 180
    }

    public func setMaxAllowedRotationAngle(_ angle: CGFloat, forJoint node: SCNNode) {
        _jointAngles[ObjectIdentifier(node)] = angle
    }

    public required init?(coder: NSCoder) { return nil }
}

open class SCNSliderConstraint: SCNConstraint {
    public var offset: SCNVector3 = SCNVector3Zero
    public var radius: CGFloat = 0
    public var collisionCategoryBitMask: Int = 0
    public override init() { super.init() }
    public required init?(coder: NSCoder) { return nil }
}

open class SCNNode: NSObject, NSCopying, NSSecureCoding, SCNActionable, SCNAnimatable, SCNBoundingVolume {
    public class var localRight: SCNVector3 { SCNVector3(x: 1, y: 0, z: 0) }
    public class var localUp: SCNVector3 { SCNVector3(x: 0, y: 1, z: 0) }
    public class var localFront: SCNVector3 { SCNVector3(x: 0, y: 0, z: 1) }

    public var name: String?
    public var light: SCNLight?
    public var camera: SCNCamera?
    public var geometry: SCNGeometry?
    public var morpher: SCNMorpher?
    public var skinner: SCNSkinner?
    public var categoryBitMask: Int = 1
    public var isHidden: Bool = false
    public var opacity: CGFloat = 1
    public var renderingOrder: Int = 0
    public var castsShadow: Bool = true
    public var movabilityHint: SCNMovabilityHint = .fixed
    public var focusBehavior: SCNNodeFocusBehavior = .none
    public var isPaused: Bool = false
    private var _physicsBody: SCNPhysicsBody?
    public var physicsBody: SCNPhysicsBody? {
        get { _physicsBody }
        set {
            _physicsBody?._node = nil
            _physicsBody = newValue
            _physicsBody?._node = self
        }
    }
    public var physicsField: SCNPhysicsField?
    public var constraints: [SCNConstraint]?
    public weak var rendererDelegate: SCNNodeRendererDelegate?

    public internal(set) weak var parent: SCNNode?
    public private(set) var childNodes: [SCNNode] = []
    var _audioPlayers: [SCNAudioPlayer] = []
    var _particleSystems: [SCNParticleSystem] = []
    var _actions: [_SCNActionRuntime] = []
    var _animationPlayers: [String: SCNAnimationPlayer] = [:]
    var _transformDirty = true
    var _cachedTransform = SCNMatrix4Identity

    public var position: SCNVector3 = SCNVector3Zero {
        didSet { _transformDirty = true }
    }
    private var _rotation = SCNVector4(x: 0, y: 1, z: 0, w: 0)
    private var _orientation = SCNQuaternion(x: 0, y: 0, z: 0, w: 1)
    private var _eulerAngles = SCNVector3Zero

    public var rotation: SCNVector4 {
        get { _rotation }
        set {
            _rotation = newValue
            _orientation = _scnQuatFromAxisAngle(newValue)
            _eulerAngles = _scnEulerFromQuat(_orientation)
            _transformDirty = true
        }
    }

    public var eulerAngles: SCNVector3 {
        get { _eulerAngles }
        set {
            _eulerAngles = newValue
            _orientation = _scnQuatFromEuler(newValue)
            _rotation = _scnAxisAngleFromQuat(_orientation)
            _transformDirty = true
        }
    }

    public var orientation: SCNQuaternion {
        get { _orientation }
        set {
            _orientation = _scnQuatNormalize(newValue)
            _rotation = _scnAxisAngleFromQuat(_orientation)
            _eulerAngles = _scnEulerFromQuat(_orientation)
            _transformDirty = true
        }
    }
    public var scale: SCNVector3 = SCNVector3(x: 1, y: 1, z: 1) {
        didSet { _transformDirty = true }
    }
    public var pivot: SCNMatrix4 = SCNMatrix4Identity {
        didSet { _transformDirty = true }
    }

    public var transform: SCNMatrix4 {
        get {
            if _transformDirty {
                _cachedTransform = _scnCompose(position, rotation, scale, pivot)
                _transformDirty = false
            }
            return _cachedTransform
        }
        set {
            position = _scnDecomposeTranslation(newValue)
            scale = _scnDecomposeScale(newValue)
            rotation = _scnDecomposeRotation(newValue)
            _cachedTransform = newValue
            _transformDirty = false
        }
    }

    public var worldTransform: SCNMatrix4 {
        get {
            if let parent {
                return SCNMatrix4Mult(parent.worldTransform, transform)
            }
            return transform
        }
        set {
            setWorldTransform(newValue)
        }
    }

    public var worldPosition: SCNVector3 {
        get { _scnDecomposeTranslation(worldTransform) }
        set {
            if let parent {
                position = parent.convertPosition(newValue, from: nil)
            } else {
                position = newValue
            }
        }
    }

    public var worldOrientation: SCNQuaternion {
        get { _scnQuatFromAxisAngle(_scnDecomposeRotation(worldTransform)) }
        set {
            if parent == nil {
                orientation = newValue
            } else {
                let world = _scnMatrixFromQuat(newValue)
                var local = SCNMatrix4Mult(SCNMatrix4Invert(parent!.worldTransform), world)
                local.m41 = transform.m41
                local.m42 = transform.m42
                local.m43 = transform.m43
                local.m11 *= scale.x; local.m12 *= scale.x; local.m13 *= scale.x
                transform = local
            }
        }
    }

    public var worldUp: SCNVector3 { _scnNormalize(_scnTransformDirection(worldTransform, SCNNode.localUp)) }
    public var worldRight: SCNVector3 { _scnNormalize(_scnTransformDirection(worldTransform, SCNNode.localRight)) }
    public var worldFront: SCNVector3 { _scnNormalize(_scnTransformDirection(worldTransform, SCNNode.localFront)) }

    /// True when this node or any ancestor has `isHidden == true`.
    public var linux_worldHidden: Bool {
        var cursor: SCNNode? = self
        while let node = cursor {
            if node.isHidden { return true }
            cursor = node.parent
        }
        return false
    }

    /// Product of this node's opacity and every ancestor's opacity.
    public var linux_worldOpacity: CGFloat {
        var value = opacity
        var cursor = parent
        while let node = cursor {
            value *= node.opacity
            cursor = node.parent
        }
        return value
    }

    /// Bitwise AND of this node's `categoryBitMask` with every ancestor.
    public var linux_worldCategoryBitMask: Int {
        var mask = categoryBitMask
        var cursor = parent
        while let node = cursor {
            mask &= node.categoryBitMask
            cursor = node.parent
        }
        return mask
    }

    public var presentation: SCNNode { self }

    public var audioPlayers: [SCNAudioPlayer] { _audioPlayers }
    public var particleSystems: [SCNParticleSystem]? { _particleSystems.isEmpty ? nil : _particleSystems }

    public var boundingBox: (min: SCNVector3, max: SCNVector3) {
        get { _worldAlignedBounds() }
        set { geometry?.boundingBox = newValue }
    }

    public var boundingSphere: (center: SCNVector3, radius: Float) {
        let box = boundingBox
        let center = SCNVector3(
            x: (box.min.x + box.max.x) * 0.5,
            y: (box.min.y + box.max.y) * 0.5,
            z: (box.min.z + box.max.z) * 0.5
        )
        return (center, _scnLength(_scnSub(box.max, center)))
    }

    private func _worldAlignedBounds() -> (min: SCNVector3, max: SCNVector3) {
        var points: [SCNVector3] = []
        if let geometry {
            let b = geometry.boundingBox
            let corners = [
                SCNVector3(b.min.x, b.min.y, b.min.z), SCNVector3(b.max.x, b.min.y, b.min.z),
                SCNVector3(b.min.x, b.max.y, b.min.z), SCNVector3(b.max.x, b.max.y, b.min.z),
                SCNVector3(b.min.x, b.min.y, b.max.z), SCNVector3(b.max.x, b.min.y, b.max.z),
                SCNVector3(b.min.x, b.max.y, b.max.z), SCNVector3(b.max.x, b.max.y, b.max.z)
            ]
            points.append(contentsOf: corners)
        }
        for child in childNodes {
            let cb = child.boundingBox
            points.append(contentsOf: [
                child.convertPosition(cb.min, to: self),
                child.convertPosition(cb.max, to: self),
                child.convertPosition(SCNVector3(cb.min.x, cb.min.y, cb.max.z), to: self),
                child.convertPosition(SCNVector3(cb.max.x, cb.max.y, cb.min.z), to: self)
            ])
        }
        if points.isEmpty {
            return (SCNVector3Zero, SCNVector3Zero)
        }
        return _scnBounds(points)
    }

    public required override init() {
        super.init()
    }

    public convenience init(geometry: SCNGeometry?) {
        self.init()
        self.geometry = geometry
    }

    public func setWorldTransform(_ worldTransform: SCNMatrix4) {
        if let parent {
            transform = SCNMatrix4Mult(SCNMatrix4Invert(parent.worldTransform), worldTransform)
        } else {
            transform = worldTransform
        }
    }

    private func _wouldCreateCycle(_ child: SCNNode) -> Bool {
        if child === self {
            return true
        }
        var cursor: SCNNode? = self
        while let node = cursor {
            if node === child {
                return true
            }
            cursor = node.parent
        }
        return false
    }

    public func addChildNode(_ child: SCNNode) {
        insertChildNode(child, at: childNodes.count)
    }

    public func insertChildNode(_ child: SCNNode, at index: Int) {
        if _wouldCreateCycle(child) {
            return
        }
        child.removeFromParentNode()
        let clamped = max(0, min(index, childNodes.count))
        childNodes.insert(child, at: clamped)
        child.parent = self
    }

    public func replaceChildNode(_ oldChild: SCNNode, with newChild: SCNNode) {
        guard let index = childNodes.firstIndex(where: { $0 === oldChild }) else { return }
        if newChild === oldChild {
            return
        }
        if _wouldCreateCycle(newChild) {
            return
        }
        oldChild.removeFromParentNode()
        insertChildNode(newChild, at: min(index, childNodes.count))
    }

    public func removeFromParentNode() {
        guard let parent else { return }
        parent.childNodes.removeAll { $0 === self }
        self.parent = nil
    }

    public func childNode(withName name: String, recursively: Bool) -> SCNNode? {
        for child in childNodes {
            if child.name == name {
                return child
            }
            if recursively, let found = child.childNode(withName: name, recursively: true) {
                return found
            }
        }
        return nil
    }

    public func childNodes(passingTest predicate: (SCNNode, UnsafeMutablePointer<ObjCBool>) -> Bool) -> [SCNNode] {
        var result: [SCNNode] = []
        enumerateChildNodes { node, stopPtr in
            if predicate(node, stopPtr) {
                result.append(node)
            }
        }
        return result
    }

    public func enumerateChildNodes(_ block: (SCNNode, UnsafeMutablePointer<ObjCBool>) -> Void) {
        var stop = ObjCBool(false)
        _enumerateChildren(stop: &stop, block: block)
    }

    public func enumerateHierarchy(_ block: (SCNNode, UnsafeMutablePointer<ObjCBool>) -> Void) {
        var stop = ObjCBool(false)
        withUnsafeMutablePointer(to: &stop) { ptr in
            block(self, ptr)
            if !ptr.pointee.boolValue {
                _enumerateChildren(stop: ptr, block: block)
            }
        }
    }

    private func _enumerateChildren(stop: UnsafeMutablePointer<ObjCBool>, block: (SCNNode, UnsafeMutablePointer<ObjCBool>) -> Void) {
        // Snapshot children so mutation during enumeration cannot recurse forever.
        let snapshot = childNodes
        for child in snapshot {
            if stop.pointee.boolValue { return }
            block(child, stop)
            if stop.pointee.boolValue { return }
            child._enumerateChildren(stop: stop, block: block)
        }
    }

    public func convertPosition(_ position: SCNVector3, from node: SCNNode?) -> SCNVector3 {
        let source = node?.worldTransform ?? SCNMatrix4Identity
        let world = _scnTransformPoint(source, position)
        return _scnTransformPoint(SCNMatrix4Invert(worldTransform), world)
    }

    public func convertPosition(_ position: SCNVector3, to node: SCNNode?) -> SCNVector3 {
        let world = _scnTransformPoint(worldTransform, position)
        let dest = node?.worldTransform ?? SCNMatrix4Identity
        return _scnTransformPoint(SCNMatrix4Invert(dest), world)
    }

    public func convertVector(_ vector: SCNVector3, from node: SCNNode?) -> SCNVector3 {
        let source = node?.worldTransform ?? SCNMatrix4Identity
        let world = _scnTransformDirection(source, vector)
        return _scnTransformDirection(SCNMatrix4Invert(worldTransform), world)
    }

    public func convertVector(_ vector: SCNVector3, to node: SCNNode?) -> SCNVector3 {
        let world = _scnTransformDirection(worldTransform, vector)
        let dest = node?.worldTransform ?? SCNMatrix4Identity
        return _scnTransformDirection(SCNMatrix4Invert(dest), world)
    }

    public func convertTransform(_ transform: SCNMatrix4, from node: SCNNode?) -> SCNMatrix4 {
        let source = node?.worldTransform ?? SCNMatrix4Identity
        let world = SCNMatrix4Mult(source, transform)
        return SCNMatrix4Mult(SCNMatrix4Invert(worldTransform), world)
    }

    public func convertTransform(_ transform: SCNMatrix4, to node: SCNNode?) -> SCNMatrix4 {
        let world = SCNMatrix4Mult(worldTransform, transform)
        let dest = node?.worldTransform ?? SCNMatrix4Identity
        return SCNMatrix4Mult(SCNMatrix4Invert(dest), world)
    }

    public func localTranslate(by translation: SCNVector3) {
        position = _scnAdd(position, translation)
    }

    public func localRotate(by rotation: SCNQuaternion) {
        let extra = SCNMatrix4MakeRotation(rotation.w, rotation.x, rotation.y, rotation.z)
        transform = SCNMatrix4Mult(transform, extra)
    }

    public func look(at worldTarget: SCNVector3) {
        look(at: worldTarget, up: SCNNode.localUp, localFront: SCNNode.localFront)
    }

    public func look(at worldTarget: SCNVector3, up worldUp: SCNVector3, localFront: SCNVector3) {
        let rot = _scnLookAtMatrix(from: worldPosition, to: worldTarget, up: worldUp, localFront: localFront)
        worldOrientation = _scnQuatFromAxisAngle(_scnDecomposeRotation(rot))
    }

    public func rotate(by worldRotation: SCNQuaternion, aroundTarget worldTarget: SCNVector3) {
        _ = worldTarget
        localRotate(by: worldRotation)
    }

    public func clone() -> Self {
        let copy = Self.init()
        _copy(into: copy, flatten: false)
        return copy
    }

    public func flattenedClone() -> Self {
        let copy = Self.init()
        _copy(into: copy, flatten: true)
        return copy
    }

    private func _copy(into copy: SCNNode, flatten: Bool) {
        copy.name = name
        copy.camera = camera
        copy.light = light
        copy.position = position
        copy.rotation = rotation
        copy.scale = scale
        copy.pivot = pivot
        copy.opacity = opacity
        copy.isHidden = isHidden
        copy.categoryBitMask = categoryBitMask
        copy.castsShadow = castsShadow
        copy.constraints = constraints
        if flatten {
            copy.geometry = _flattenedGeometry()
        } else {
            copy.geometry = geometry
            for child in childNodes {
                copy.addChildNode(child.clone())
            }
        }
    }

    private func _flattenedGeometry() -> SCNGeometry {
        var vertices: [SCNVector3] = []
        var normals: [SCNVector3] = []
        var uvs: [CGPoint] = []
        var indices: [UInt32] = []
        func gather(_ node: SCNNode, _ transform: SCNMatrix4) {
            if let geometry = node.geometry {
                let worldVerts = _scnReadVertices(geometry)
                let worldNormals = _scnReadNormals(geometry)
                let tex = _scnReadUVs(geometry)
                let tris = _scnReadTriangles(geometry)
                let base = UInt32(vertices.count)
                for v in worldVerts {
                    vertices.append(_scnTransformPoint(transform, v))
                }
                if worldNormals.count == worldVerts.count {
                    for n in worldNormals {
                        normals.append(_scnNormalize(_scnTransformDirection(transform, n)))
                    }
                } else {
                    normals.append(contentsOf: repeatElement(SCNVector3(0, 1, 0), count: worldVerts.count))
                }
                if tex.count == worldVerts.count {
                    uvs.append(contentsOf: tex)
                } else {
                    uvs.append(contentsOf: repeatElement(CGPoint.zero, count: worldVerts.count))
                }
                indices.append(contentsOf: tris.map { base + $0 })
            }
            for child in node.childNodes {
                gather(child, SCNMatrix4Mult(transform, child.transform))
            }
        }
        gather(self, SCNMatrix4Identity)
        let geom = SCNGeometry()
        if vertices.isEmpty {
            return geometry ?? geom
        }
        _scnAssignMesh(geom, _SCNMesh(vertices: vertices, normals: normals, uvs: uvs, indices: indices, min: _scnBounds(vertices).0, max: _scnBounds(vertices).1))
        geom.materials = geometry?.materials ?? [SCNMaterial()]
        return geom
    }

    public func addAudioPlayer(_ player: SCNAudioPlayer) {
        if !_audioPlayers.contains(where: { $0 === player }) {
            _audioPlayers.append(player)
        }
    }

    public func removeAudioPlayer(_ player: SCNAudioPlayer) {
        _audioPlayers.removeAll { $0 === player }
    }

    public func removeAllAudioPlayers() {
        _audioPlayers.removeAll()
    }

    public func addParticleSystem(_ system: SCNParticleSystem) {
        _particleSystems.append(system)
    }

    public func removeParticleSystem(_ system: SCNParticleSystem) {
        _particleSystems.removeAll { $0 === system }
    }

    public func removeAllParticleSystems() {
        _particleSystems.removeAll()
    }

    public func hitTestWithSegment(from pointA: SCNVector3, to pointB: SCNVector3, options: [String: Any]? = nil) -> [SCNHitTestResult] {
        let typed = _scnHitOptions(from: options)
        return _scnHitTestSegment(root: self, from: pointA, to: pointB, options: typed, spaceNode: self)
    }

    public var simdPosition: SIMD3<Float> {
        get { SIMD3(position) }
        set { position = SCNVector3(newValue) }
    }
    public var simdRotation: SIMD4<Float> {
        get { SIMD4(rotation) }
        set { rotation = SCNVector4(newValue) }
    }
    public var simdEulerAngles: SIMD3<Float> {
        get { SIMD3(eulerAngles) }
        set { eulerAngles = SCNVector3(newValue) }
    }
    public var simdOrientation: SIMD4<Float> {
        get { SIMD4(orientation) }
        set { orientation = SCNQuaternion(newValue) }
    }
    public var simdScale: SIMD3<Float> {
        get { SIMD3(scale) }
        set { scale = SCNVector3(newValue) }
    }
    public var simdWorldPosition: SIMD3<Float> {
        get { SIMD3(worldPosition) }
        set { worldPosition = SCNVector3(newValue) }
    }
    public var simdWorldFront: SIMD3<Float> { SIMD3(worldFront) }
    public var simdWorldRight: SIMD3<Float> { SIMD3(worldRight) }
    public var simdWorldUp: SIMD3<Float> { SIMD3(worldUp) }
    public class var simdLocalFront: SIMD3<Float> { SIMD3(localFront) }
    public class var simdLocalRight: SIMD3<Float> { SIMD3(localRight) }
    public class var simdLocalUp: SIMD3<Float> { SIMD3(localUp) }

    public func simdConvertPosition(_ position: SIMD3<Float>, from node: SCNNode?) -> SIMD3<Float> {
        SIMD3(convertPosition(SCNVector3(position), from: node))
    }
    public func simdConvertPosition(_ position: SIMD3<Float>, to node: SCNNode?) -> SIMD3<Float> {
        SIMD3(convertPosition(SCNVector3(position), to: node))
    }
    public func simdConvertVector(_ vector: SIMD3<Float>, from node: SCNNode?) -> SIMD3<Float> {
        SIMD3(convertVector(SCNVector3(vector), from: node))
    }
    public func simdConvertVector(_ vector: SIMD3<Float>, to node: SCNNode?) -> SIMD3<Float> {
        SIMD3(convertVector(SCNVector3(vector), to: node))
    }
    public func simdLocalTranslate(by translation: SIMD3<Float>) {
        localTranslate(by: SCNVector3(translation))
    }
    public func simdLook(at worldTarget: SIMD3<Float>) {
        look(at: SCNVector3(worldTarget))
    }
    public func simdLook(at worldTarget: SIMD3<Float>, up worldUp: SIMD3<Float>, localFront: SIMD3<Float>) {
        look(at: SCNVector3(worldTarget), up: SCNVector3(worldUp), localFront: SCNVector3(localFront))
    }

#if canImport(simd)
    public var simdPivot: simd_float4x4 {
        get { simd_float4x4(pivot) }
        set { pivot = SCNMatrix4(newValue) }
    }
    public var simdTransform: simd_float4x4 {
        get { simd_float4x4(transform) }
        set { transform = SCNMatrix4(newValue) }
    }
    public var simdWorldTransform: simd_float4x4 {
        get { simd_float4x4(worldTransform) }
        set { worldTransform = SCNMatrix4(newValue) }
    }
    public var simdWorldOrientation: simd_quatf {
        get {
            let q = worldOrientation
            return simd_quatf(ix: q.x, iy: q.y, iz: q.z, r: q.w)
        }
        set { worldOrientation = SCNQuaternion(x: newValue.imag.x, y: newValue.imag.y, z: newValue.imag.z, w: newValue.real) }
    }
    public func simdConvertTransform(_ transform: simd_float4x4, from node: SCNNode?) -> simd_float4x4 {
        simd_float4x4(convertTransform(SCNMatrix4(transform), from: node))
    }
    public func simdConvertTransform(_ transform: simd_float4x4, to node: SCNNode?) -> simd_float4x4 {
        simd_float4x4(convertTransform(SCNMatrix4(transform), to: node))
    }
    public func simdLocalRotate(by rotation: simd_quatf) {
        localRotate(by: SCNQuaternion(x: rotation.imag.x, y: rotation.imag.y, z: rotation.imag.z, w: rotation.real))
    }
    public func simdRotate(by worldRotation: simd_quatf, aroundTarget worldTarget: SIMD3<Float>) {
        rotate(by: SCNQuaternion(x: worldRotation.imag.x, y: worldRotation.imag.y, z: worldRotation.imag.z, w: worldRotation.real), aroundTarget: SCNVector3(worldTarget))
    }
#endif

    public var hasActions: Bool { _actions.contains { !$0.finished && !$0.cancelled } }
    public var actionKeys: [String] { _actions.filter { !$0.finished && !$0.cancelled }.map(\.key) }

    public func action(forKey key: String) -> SCNAction? {
        _actions.first { $0.key == key && !$0.finished && !$0.cancelled }?.action
    }

    public func removeAction(forKey key: String) {
        for runtime in _actions where runtime.key == key && !runtime.finished {
            runtime.cancelled = true
            runtime.onFinish?()
            runtime.onFinish = nil
        }
        _actions.removeAll { $0.key == key }
    }

    public func removeAllActions() {
        for runtime in _actions {
            runtime.cancelled = true
            runtime.onFinish?()
            runtime.onFinish = nil
        }
        _actions.removeAll()
    }

    public func runAction(_ action: SCNAction) {
        runAction(action, forKey: nil)
    }

    public func runAction(_ action: SCNAction, forKey key: String?) {
        let resolved = key ?? UUID().uuidString
        if let key {
            removeAction(forKey: key)
        }
        _ = SCNTransaction.disableActions
        let runtime = _SCNActionRuntime(action: action, key: resolved)
        _actions.append(runtime)
    }

    public func runAction(_ action: SCNAction) async {
        await runAction(action, forKey: nil)
    }

    public func runAction(_ action: SCNAction, forKey key: String?) async {
        await withCheckedContinuation { (continuation: CheckedContinuation<Void, Never>) in
            let resolved = key ?? UUID().uuidString
            if let key {
                removeAction(forKey: key)
            }
            let runtime = _SCNActionRuntime(action: action, key: resolved)
            runtime.onFinish = { continuation.resume() }
            _actions.append(runtime)
            if action.duration == 0 && TimeInterval(action.speed) != 0 {
                _linuxAdvanceActions(0)
            }
        }
    }

    /// Linux CPU action clock. Not an Apple API. `speed == 0` pauses; leftover
    /// delta is carried across sequence/repeat boundaries.
    public func linux_advanceTime(_ dt: TimeInterval) {
        if isPaused { return }
        _linuxAdvanceActions(dt)
        _linuxApplyConstraints()
        for system in _particleSystems {
            system.linux_advance(dt)
        }
        let snapshot = childNodes
        for child in snapshot {
            child.linux_advanceTime(dt)
        }
    }

    func _linuxApplyConstraints() {
        guard let constraints else { return }
        for constraint in constraints where constraint.isEnabled {
            _scnApplyConstraint(constraint, to: self)
        }
    }

    func _linuxAdvanceActions(_ dt: TimeInterval) {
        var index = 0
        while index < _actions.count {
            let runtime = _actions[index]
            if runtime.cancelled || runtime.finished {
                runtime.onFinish?()
                runtime.onFinish = nil
                _actions.remove(at: index)
                continue
            }
            _ = _scnAdvanceAction(runtime: runtime, node: self, dt: dt)
            if runtime.finished || runtime.cancelled {
                runtime.onFinish?()
                runtime.onFinish = nil
                _actions.remove(at: index)
                continue
            }
            index += 1
        }
    }

    public var animationKeys: [String] { Array(_animationPlayers.keys) }
    public func addAnimation(_ animation: any SCNAnimationProtocol, forKey key: String?) {
        addAnimationPlayer(SCNAnimationPlayer(animation: animation as? SCNAnimation ?? SCNAnimation()), forKey: key)
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

    public func copy(with zone: NSZone? = nil) -> Any { clone() }
    public static var supportsSecureCoding: Bool { true }
    public required init?(coder: NSCoder) { return nil }
    public func encode(with coder: NSCoder) {}
}

open class SCNReferenceNode: SCNNode {
    public var referenceURL: URL?
    public var loadingPolicy: SCNReferenceLoadingPolicy = .immediate
    public private(set) var isLoaded: Bool = false

    public convenience init?(url: URL) {
        self.init()
        self.referenceURL = url
    }

    public convenience init?(URL url: URL) {
        self.init(url: url)
    }

    public func load() {
        // Fail-closed: no Apple scene archive decoder is present.
        isLoaded = false
    }

    public func unload() {
        isLoaded = false
        for child in childNodes {
            child.removeFromParentNode()
        }
    }

    public required init() { super.init() }
    public required init?(coder: NSCoder) { return nil }
}
