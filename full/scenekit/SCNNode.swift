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
    public required init?(coder: NSCoder) { return nil }
}

open class SCNAccelerationConstraint: SCNConstraint {
    public var maximumLinearAcceleration: CGFloat = 0
    public var maximumLinearVelocity: CGFloat = 0
    public var decelerationDistance: CGFloat = 0
    public var damping: CGFloat = 0.1
    public required init?(coder: NSCoder) { return nil }
}

open class SCNAvoidOccluderConstraint: SCNConstraint {
    public weak var target: SCNNode?
    public var occluderCategoryBitMask: Int = 1
    public var bias: CGFloat = 0
    public weak var delegate: SCNAvoidOccluderConstraintDelegate?
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
    public var physicsBody: SCNPhysicsBody?
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
    public var rotation: SCNVector4 = SCNVector4(x: 0, y: 1, z: 0, w: 0) {
        didSet { _transformDirty = true }
    }
    public var eulerAngles: SCNVector3 = SCNVector3Zero {
        didSet {
            rotation = SCNVector4(x: 0, y: 1, z: 0, w: eulerAngles.y)
            _transformDirty = true
        }
    }
    public var orientation: SCNQuaternion {
        get { rotation }
        set { rotation = newValue }
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
            if parent != nil {
                position = convertPosition(newValue, from: nil)
            } else {
                position = newValue
            }
        }
    }

    public var worldOrientation: SCNQuaternion {
        get { _scnDecomposeRotation(worldTransform) }
        set {
            if parent == nil {
                orientation = newValue
            } else {
                rotation = newValue
            }
        }
    }

    public var worldUp: SCNVector3 { _scnNormalize(_scnTransformDirection(worldTransform, SCNNode.localUp)) }
    public var worldRight: SCNVector3 { _scnNormalize(_scnTransformDirection(worldTransform, SCNNode.localRight)) }
    public var worldFront: SCNVector3 { _scnNormalize(_scnTransformDirection(worldTransform, SCNNode.localFront)) }

    public var presentation: SCNNode { self }

    public var audioPlayers: [SCNAudioPlayer] { _audioPlayers }
    public var particleSystems: [SCNParticleSystem]? { _particleSystems.isEmpty ? nil : _particleSystems }

    public var boundingBox: (min: SCNVector3, max: SCNVector3) {
        get { geometry?.boundingBox ?? (SCNVector3Zero, SCNVector3Zero) }
        set { geometry?.boundingBox = newValue }
    }

    public var boundingSphere: (center: SCNVector3, radius: Float) {
        geometry?.boundingSphere ?? (SCNVector3Zero, 0)
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
        let from = worldPosition
        let dir = _scnNormalize(_scnSub(worldTarget, from))
        if _scnLength(dir) == 0 { return }
        _ = worldUp
        _ = localFront
        let angle = acos(max(-1, min(1, _scnDot(SCNNode.localFront, dir))))
        let axis = _scnNormalize(_scnCross(SCNNode.localFront, dir))
        if _scnLength(axis) == 0 {
            return
        }
        worldOrientation = SCNVector4(x: axis.x, y: axis.y, z: axis.z, w: angle)
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
        copy.geometry = geometry
        copy.camera = camera
        copy.light = light
        copy.position = position
        copy.rotation = rotation
        copy.scale = scale
        copy.opacity = opacity
        copy.isHidden = isHidden
        copy.categoryBitMask = categoryBitMask
        copy.castsShadow = castsShadow
        if !flatten {
            for child in childNodes {
                copy.addChildNode(child.clone())
            }
        }
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
        _ = pointA
        _ = pointB
        _ = options
        return []
    }

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
        let snapshot = childNodes
        for child in snapshot {
            child.linux_advanceTime(dt)
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
