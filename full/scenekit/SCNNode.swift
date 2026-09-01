import Foundation
#if canImport(simd)
import simd
#endif

open class SCNNode: NSObject, SCNActionable, SCNAnimatable, SCNBoundingVolume {
    public class var localFront: SCNVector3 { SCNVector3(0, 0, -1) }
    public class var localRight: SCNVector3 { SCNVector3(1, 0, 0) }
    public class var localUp: SCNVector3 { SCNVector3(0, 1, 0) }
#if canImport(simd)
    public class var simdLocalFront: simd_float3 { simd_float3(0, 0, -1) }
    public class var simdLocalRight: simd_float3 { simd_float3(1, 0, 0) }
    public class var simdLocalUp: simd_float3 { simd_float3(0, 1, 0) }
#endif

    public var name: String?
    public var geometry: SCNGeometry?
    public var camera: SCNCamera?
    public var light: SCNLight?
    public var morpher: SCNMorpher?
    public var skinner: SCNSkinner?
    public var physicsBody: SCNPhysicsBody?
    public var physicsField: SCNPhysicsField?
    public var constraints: [SCNConstraint]?
    public var categoryBitMask = 1
    public var castsShadow = true
    public var isHidden = false
    public var isPaused = false
    public var opacity: CGFloat = 1
    public var renderingOrder = 0
    public var movabilityHint = SCNMovabilityHint.fixed
    public var focusBehavior = SCNNodeFocusBehavior.none
    public weak var rendererDelegate: (any SCNNodeRendererDelegate)?
    public private(set) weak var parent: SCNNode?
    var _children: [SCNNode] = []
    var _position = SCNVector3Zero
    var _orientation = _scnQuaternionIdentity()
    var _scale = SCNVector3(1, 1, 1)
    var _pivot = SCNMatrix4Identity
    var _actions: [String: _SCNActionState] = [:]
    var _animationPlayers: [String: SCNAnimationPlayer] = [:]
    var _audioPlayers: [SCNAudioPlayer] = []
    var _particleSystems: [SCNParticleSystem] = []
    var _boundingBoxOverride: (min: SCNVector3, max: SCNVector3)?

    public required override init() {
        super.init()
    }

    public convenience init(geometry: SCNGeometry?) {
        self.init()
        self.geometry = geometry
    }

    public required init?(coder: NSCoder) { return nil }

    public var childNodes: [SCNNode] { _children }

    public var position: SCNVector3 {
        get { _position }
        set { _position = newValue }
    }

    public var scale: SCNVector3 {
        get { _scale }
        set { _scale = newValue }
    }

    public var orientation: SCNQuaternion {
        get { _orientation }
        set { _orientation = _scnQuaternionNormalize(newValue) }
    }

    public var eulerAngles: SCNVector3 {
        get { _scnEulerFromQuaternion(_orientation) }
        set { _orientation = _scnQuaternionFromEuler(newValue) }
    }

    public var rotation: SCNVector4 {
        get { _scnAxisAngleFromQuaternion(_orientation) }
        set { _orientation = _scnQuaternionFromAxisAngle(SCNVector3(newValue.x, newValue.y, newValue.z), newValue.w) }
    }

    public var pivot: SCNMatrix4 {
        get { _pivot }
        set { _pivot = newValue }
    }

    public var transform: SCNMatrix4 {
        get { _scnComposeTransform(position: _position, orientation: _orientation, scale: _scale, pivot: _pivot) }
        set {
            let parts = _scnDecomposeTransform(newValue)
            _position = parts.0
            _orientation = parts.1
            _scale = parts.2
        }
    }

    public var worldTransform: SCNMatrix4 {
        if let parent {
            return SCNMatrix4Mult(parent.worldTransform, transform)
        }
        return transform
    }

    public func setWorldTransform(_ worldTransform: SCNMatrix4) {
        if let parent {
            transform = SCNMatrix4Mult(SCNMatrix4Invert(parent.worldTransform), worldTransform)
        } else {
            transform = worldTransform
        }
    }

    public var worldPosition: SCNVector3 {
        get {
            let m = worldTransform
            return SCNVector3(m.m41, m.m42, m.m43)
        }
        set {
            if let parent {
                _position = parent.convertPosition(newValue, from: nil)
            } else {
                _position = newValue
            }
        }
    }

    public var worldOrientation: SCNQuaternion {
        get {
            if let parent {
                return _scnQuaternionMultiply(parent.worldOrientation, _orientation)
            }
            return _orientation
        }
        set {
            if let parent {
                let inverse = SCNVector4(-parent.worldOrientation.x, -parent.worldOrientation.y, -parent.worldOrientation.z, parent.worldOrientation.w)
                _orientation = _scnQuaternionNormalize(_scnQuaternionMultiply(inverse, newValue))
            } else {
                _orientation = _scnQuaternionNormalize(newValue)
            }
        }
    }

    public var worldFront: SCNVector3 { convertVector(SCNNode.localFront, to: nil) }
    public var worldUp: SCNVector3 { convertVector(SCNNode.localUp, to: nil) }
    public var worldRight: SCNVector3 { convertVector(SCNNode.localRight, to: nil) }

#if canImport(simd)
    public var simdPosition: simd_float3 {
        get { _scnSimd3(position) }
        set { position = _scnFromSimd3(newValue) }
    }
    public var simdScale: simd_float3 {
        get { _scnSimd3(scale) }
        set { scale = _scnFromSimd3(newValue) }
    }
    public var simdEulerAngles: simd_float3 {
        get { _scnSimd3(eulerAngles) }
        set { eulerAngles = _scnFromSimd3(newValue) }
    }
    public var simdRotation: simd_float4 {
        get { _scnSimd4(rotation) }
        set { rotation = SCNVector4(newValue) }
    }
    public var simdOrientation: simd_quatf {
        get { _scnSimdQuat(orientation) }
        set { orientation = _scnFromSimdQuat(newValue) }
    }
    public var simdPivot: simd_float4x4 {
        get { _scnSimdMatrix(pivot) }
        set { pivot = _scnFromSimdMatrix(newValue) }
    }
    public var simdTransform: simd_float4x4 {
        get { _scnSimdMatrix(transform) }
        set { transform = _scnFromSimdMatrix(newValue) }
    }
    public var simdWorldTransform: simd_float4x4 {
        get { _scnSimdMatrix(worldTransform) }
        set { setWorldTransform(_scnFromSimdMatrix(newValue)) }
    }
    public var simdWorldPosition: simd_float3 {
        get { _scnSimd3(worldPosition) }
        set { worldPosition = _scnFromSimd3(newValue) }
    }
    public var simdWorldOrientation: simd_quatf {
        get { _scnSimdQuat(worldOrientation) }
        set { worldOrientation = _scnFromSimdQuat(newValue) }
    }
    public var simdWorldFront: simd_float3 { _scnSimd3(worldFront) }
    public var simdWorldUp: simd_float3 { _scnSimd3(worldUp) }
    public var simdWorldRight: simd_float3 { _scnSimd3(worldRight) }
#endif

    public var presentation: SCNNode { self }

    public var boundingBox: (min: SCNVector3, max: SCNVector3) {
        get { _boundingBoxOverride ?? geometry?.boundingBox ?? (SCNVector3Zero, SCNVector3Zero) }
        set { _boundingBoxOverride = newValue }
    }

    public var boundingSphere: (center: SCNVector3, radius: Float) {
        let box = boundingBox
        let center = SCNVector3(
            (box.min.x + box.max.x) * 0.5,
            (box.min.y + box.max.y) * 0.5,
            (box.min.z + box.max.z) * 0.5
        )
        return (center, _scnLength(_scnSub(box.max, center)))
    }

    func _wouldCreateCycle(inserting child: SCNNode) -> Bool {
        var current: SCNNode? = self
        while let node = current {
            if node === child { return true }
            current = node.parent
        }
        return false
    }

    public func addChildNode(_ child: SCNNode) {
        guard !_wouldCreateCycle(inserting: child) else { return }
        child.removeFromParentNode()
        child.parent = self
        _children.append(child)
    }

    public func insertChildNode(_ child: SCNNode, at index: Int) {
        guard !_wouldCreateCycle(inserting: child) else { return }
        child.removeFromParentNode()
        child.parent = self
        _children.insert(child, at: index)
    }

    public func replaceChildNode(_ oldChild: SCNNode, with newChild: SCNNode) {
        guard let index = _children.firstIndex(where: { $0 === oldChild }) else { return }
        guard !_wouldCreateCycle(inserting: newChild) else { return }
        oldChild.parent = nil
        newChild.removeFromParentNode()
        newChild.parent = self
        _children[index] = newChild
    }

    public func removeFromParentNode() {
        guard let parent else { return }
        parent._children.removeAll { $0 === self }
        self.parent = nil
    }

    public func childNode(withName name: String, recursively: Bool) -> SCNNode? {
        for child in _children {
            if child.name == name { return child }
            if recursively, let found = child.childNode(withName: name, recursively: true) {
                return found
            }
        }
        return nil
    }

    public func childNodes(passingTest predicate: (SCNNode, UnsafeMutablePointer<ObjCBool>) -> Bool) -> [SCNNode] {
        var matches: [SCNNode] = []
        var stop = ObjCBool(false)
        _collectChildren(stop: &stop, predicate: predicate, into: &matches)
        return matches
    }

    private func _collectChildren(
        stop: UnsafeMutablePointer<ObjCBool>,
        predicate: (SCNNode, UnsafeMutablePointer<ObjCBool>) -> Bool,
        into matches: inout [SCNNode]
    ) {
        for child in _children {
            if stop.pointee.boolValue { return }
            if predicate(child, stop) {
                matches.append(child)
            }
            if !stop.pointee.boolValue {
                child._collectChildren(stop: stop, predicate: predicate, into: &matches)
            }
        }
    }

    public func enumerateChildNodes(_ block: (SCNNode, UnsafeMutablePointer<ObjCBool>) -> Void) {
        var stop = ObjCBool(false)
        _walkChildren(stop: &stop, includeSelf: false, block: block)
    }

    public func enumerateHierarchy(_ block: (SCNNode, UnsafeMutablePointer<ObjCBool>) -> Void) {
        var stop = ObjCBool(false)
        block(self, &stop)
        if !stop.boolValue {
            _walkChildren(stop: &stop, includeSelf: false, block: block)
        }
    }

    private func _walkChildren(
        stop: UnsafeMutablePointer<ObjCBool>,
        includeSelf: Bool,
        block: (SCNNode, UnsafeMutablePointer<ObjCBool>) -> Void
    ) {
        _ = includeSelf
        for child in _children {
            if stop.pointee.boolValue { return }
            block(child, stop)
            if !stop.pointee.boolValue {
                child._walkChildren(stop: stop, includeSelf: false, block: block)
            }
        }
    }

    public func clone() -> Self {
        let copy = type(of: self).init()
        copy._copyState(from: self, flatten: false)
        return copy
    }

    public func flattenedClone() -> Self {
        let copy = type(of: self).init()
        copy._copyState(from: self, flatten: true)
        return copy
    }

    func _copyState(from source: SCNNode, flatten: Bool) {
        name = source.name
        geometry = source.geometry
        camera = source.camera
        light = source.light
        _position = source._position
        _orientation = source._orientation
        _scale = source._scale
        _pivot = source._pivot
        opacity = source.opacity
        isHidden = source.isHidden
        categoryBitMask = source.categoryBitMask
        if !flatten {
            for child in source._children {
                addChildNode(child.clone())
            }
        }
    }

    public func convertPosition(_ position: SCNVector3, from node: SCNNode?) -> SCNVector3 {
        let world = node.map { _scnTransformPoint($0.worldTransform, position) } ?? position
        return _scnTransformPoint(SCNMatrix4Invert(worldTransform), world)
    }

    public func convertPosition(_ position: SCNVector3, to node: SCNNode?) -> SCNVector3 {
        let world = _scnTransformPoint(worldTransform, position)
        if let node {
            return _scnTransformPoint(SCNMatrix4Invert(node.worldTransform), world)
        }
        return world
    }

    public func convertVector(_ vector: SCNVector3, from node: SCNNode?) -> SCNVector3 {
        let world = node.map { _scnTransformVector($0.worldTransform, vector) } ?? vector
        return _scnTransformVector(SCNMatrix4Invert(worldTransform), world)
    }

    public func convertVector(_ vector: SCNVector3, to node: SCNNode?) -> SCNVector3 {
        let world = _scnTransformVector(worldTransform, vector)
        if let node {
            return _scnTransformVector(SCNMatrix4Invert(node.worldTransform), world)
        }
        return world
    }

    public func convertTransform(_ transform: SCNMatrix4, from node: SCNNode?) -> SCNMatrix4 {
        let world = node.map { SCNMatrix4Mult($0.worldTransform, transform) } ?? transform
        return SCNMatrix4Mult(SCNMatrix4Invert(worldTransform), world)
    }

    public func convertTransform(_ transform: SCNMatrix4, to node: SCNNode?) -> SCNMatrix4 {
        let world = SCNMatrix4Mult(worldTransform, transform)
        if let node {
            return SCNMatrix4Mult(SCNMatrix4Invert(node.worldTransform), world)
        }
        return world
    }

#if canImport(simd)
    public func simdConvertPosition(_ position: simd_float3, from node: SCNNode?) -> simd_float3 {
        _scnSimd3(convertPosition(_scnFromSimd3(position), from: node))
    }
    public func simdConvertPosition(_ position: simd_float3, to node: SCNNode?) -> simd_float3 {
        _scnSimd3(convertPosition(_scnFromSimd3(position), to: node))
    }
    public func simdConvertVector(_ vector: simd_float3, from node: SCNNode?) -> simd_float3 {
        _scnSimd3(convertVector(_scnFromSimd3(vector), from: node))
    }
    public func simdConvertVector(_ vector: simd_float3, to node: SCNNode?) -> simd_float3 {
        _scnSimd3(convertVector(_scnFromSimd3(vector), to: node))
    }
    public func simdConvertTransform(_ transform: simd_float4x4, from node: SCNNode?) -> simd_float4x4 {
        _scnSimdMatrix(convertTransform(_scnFromSimdMatrix(transform), from: node))
    }
    public func simdConvertTransform(_ transform: simd_float4x4, to node: SCNNode?) -> simd_float4x4 {
        _scnSimdMatrix(convertTransform(_scnFromSimdMatrix(transform), to: node))
    }
#endif

    public func localTranslate(by translation: SCNVector3) {
        position = _scnAdd(position, translation)
    }

#if canImport(simd)
    public func simdLocalTranslate(by translation: simd_float3) {
        localTranslate(by: _scnFromSimd3(translation))
    }
#endif

    public func localRotate(by rotation: SCNQuaternion) {
        orientation = _scnQuaternionMultiply(orientation, rotation)
    }

#if canImport(simd)
    public func simdLocalRotate(by rotation: simd_quatf) {
        localRotate(by: _scnFromSimdQuat(rotation))
    }
#endif

    public func look(at worldTarget: SCNVector3) {
        look(at: worldTarget, up: SCNNode.localUp, localFront: SCNNode.localFront)
    }

    public func look(at worldTarget: SCNVector3, up worldUp: SCNVector3, localFront: SCNVector3) {
        let direction = _scnSub(worldTarget, worldPosition)
        worldOrientation = _scnLookRotation(direction: direction, up: worldUp, localFront: localFront)
    }

#if canImport(simd)
    public func simdLook(at worldTarget: simd_float3) {
        look(at: _scnFromSimd3(worldTarget))
    }

    public func simdLook(at worldTarget: simd_float3, up worldUp: simd_float3, localFront: simd_float3) {
        look(at: _scnFromSimd3(worldTarget), up: _scnFromSimd3(worldUp), localFront: _scnFromSimd3(localFront))
    }
#endif

    public func rotate(by worldRotation: SCNQuaternion, aroundTarget worldTarget: SCNVector3) {
        let relative = _scnSub(worldPosition, worldTarget)
        let rotated = _scnTransformVector(_scnMatrixFromQuaternion(worldRotation), relative)
        worldPosition = _scnAdd(worldTarget, rotated)
        worldOrientation = _scnQuaternionMultiply(worldRotation, worldOrientation)
    }

#if canImport(simd)
    public func simdRotate(by worldRotation: simd_quatf, aroundTarget worldTarget: simd_float3) {
        rotate(by: _scnFromSimdQuat(worldRotation), aroundTarget: _scnFromSimd3(worldTarget))
    }
#endif

    public func hitTestWithSegment(from pointA: SCNVector3, to pointB: SCNVector3, options: [String: Any]? = nil) -> [SCNHitTestResult] {
        _ = options
        let direction = _scnSub(pointB, pointA)
        var hits: [SCNHitTestResult] = []
        enumerateHierarchy { node, _ in
            if node.isHidden { return }
            let inverse = SCNMatrix4Invert(node.worldTransform)
            let localA = _scnTransformPoint(inverse, pointA)
            let localB = _scnTransformPoint(inverse, pointB)
            let localDir = _scnSub(localB, localA)
            let box = node.boundingBox
            if let t = _scnRayHitsAABB(origin: localA, direction: localDir, minBound: box.min, maxBound: box.max) {
                if t >= 0 && t <= 1 {
                    let localPoint = _scnAdd(localA, _scnScale(localDir, t))
                    let worldPoint = _scnTransformPoint(node.worldTransform, localPoint)
                    hits.append(
                        SCNHitTestResult(
                            node: node,
                            worldCoordinates: worldPoint,
                            localCoordinates: localPoint,
                            worldNormal: node.worldUp,
                            localNormal: SCNNode.localUp,
                            modelTransform: node.worldTransform
                        )
                    )
                }
            }
        }
        hits.sort {
            _scnLength(_scnSub($0.worldCoordinates, pointA)) < _scnLength(_scnSub($1.worldCoordinates, pointA))
        }
        _ = direction
        return hits
    }

    public var audioPlayers: [SCNAudioPlayer] { _audioPlayers }
    public func addAudioPlayer(_ player: SCNAudioPlayer) { _audioPlayers.append(player) }
    public func removeAudioPlayer(_ player: SCNAudioPlayer) { _audioPlayers.removeAll { $0 === player } }
    public func removeAllAudioPlayers() { _audioPlayers.removeAll() }

    public var particleSystems: [SCNParticleSystem]? { _particleSystems.isEmpty ? nil : _particleSystems }
    public func addParticleSystem(_ system: SCNParticleSystem) { _particleSystems.append(system) }
    public func removeParticleSystem(_ system: SCNParticleSystem) { _particleSystems.removeAll { $0 === system } }
    public func removeAllParticleSystems() { _particleSystems.removeAll() }

    public var actionKeys: [String] { Array(_actions.keys) }
    public var hasActions: Bool { !_actions.isEmpty }

    public func action(forKey key: String) -> SCNAction? {
        _actions[key]?.action
    }

    public func removeAction(forKey key: String) {
        if let state = _actions.removeValue(forKey: key) {
            state.resumeCancel()
        }
    }

    public func removeAllActions() {
        let states = Array(_actions.values)
        _actions.removeAll()
        for state in states {
            state.resumeCancel()
        }
    }

    public func runAction(_ action: SCNAction) {
        _run(action, forKey: nil, continuation: nil)
    }

    public func runAction(_ action: SCNAction) async {
        await _runWaiting(action, forKey: nil)
    }

    public func runAction(_ action: SCNAction, forKey key: String?) {
        _run(action, forKey: key, continuation: nil)
    }

    public func runAction(_ action: SCNAction, forKey key: String?) async {
        await _runWaiting(action, forKey: key)
    }

    private func _runWaiting(_ action: SCNAction, forKey key: String?) async {
        let token = key ?? UUID().uuidString
        try? await withTaskCancellationHandler {
            try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
                _run(action, forKey: token, continuation: continuation)
            }
        } onCancel: {
            removeAction(forKey: token)
        }
    }

    func _run(_ action: SCNAction, forKey key: String?, continuation: CheckedContinuation<Void, Error>?) {
        let token = key ?? UUID().uuidString
        if let previous = _actions.removeValue(forKey: token) {
            previous.resumeCancel()
        }
        let state = _SCNActionState(action: action)
        state.continuation = continuation
        _actions[token] = state
        // Instant actions complete immediately. SCNTransaction.disableActions
        // applies to implicit animations, not explicit SCNAction.runAction.
        if action.duration <= 0 {
            if _advance(state: state, deltaTime: 0, node: self) != nil {
                _actions.removeValue(forKey: token)
                state.resumeSuccess()
            }
        }
    }

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

    public func _openUIKitAdvance(deltaTime: TimeInterval) {
        guard !isPaused else { return }
        for key in Array(_actions.keys) {
            guard let state = _actions[key] else { continue }
            if _advance(state: state, deltaTime: deltaTime, node: self) != nil {
                _actions.removeValue(forKey: key)
                state.resumeSuccess()
            }
        }
        for child in _children {
            child._openUIKitAdvance(deltaTime: deltaTime)
        }
    }

    /// Returns leftover unscaled delta when the action finished; nil if still running.
    func _advance(state: _SCNActionState, deltaTime: TimeInterval, node: SCNNode) -> TimeInterval? {
        let action = state.action
        if !state.started {
            state.started = true
            state.startPosition = node.position
            state.startEuler = node.eulerAngles
            state.startScale = node.scale
            state.startOpacity = node.opacity
        }

        switch action.kind {
        case .sequence:
            var remaining = deltaTime
            while state.sequenceIndex < state.childStates.count {
                let child = state.childStates[state.sequenceIndex]
                if let leftover = _advance(state: child, deltaTime: remaining, node: node) {
                    state.sequenceIndex += 1
                    remaining = leftover
                } else {
                    return nil
                }
            }
            return remaining
        case .group:
            var allDone = true
            var minLeftover = deltaTime
            for child in state.childStates {
                if let leftover = _advance(state: child, deltaTime: deltaTime, node: node) {
                    minLeftover = min(minLeftover, leftover)
                } else {
                    allDone = false
                }
            }
            return allDone ? minLeftover : nil
        case .repeat:
            var remaining = deltaTime
            var steps = 0
            while steps < 1_000_000 {
                if let left = state.repeatRemaining, left <= 0 {
                    return remaining
                }
                steps += 1
                if let leftover = _advance(state: state.childStates[0], deltaTime: remaining, node: node) {
                    if var left = state.repeatRemaining {
                        left -= 1
                        state.repeatRemaining = left
                        if left <= 0 { return leftover }
                    }
                    state.childStates = [_SCNActionState(action: state.childStates[0].action)]
                    if leftover >= remaining && remaining >= 0 && action.duration.isInfinite {
                        return leftover
                    }
                    remaining = leftover
                } else {
                    return nil
                }
            }
            return remaining
        default:
            break
        }

        let duration = max(action.duration, 0)
        if duration == 0 {
            _applyLeaf(state: state, t: 1, node: node)
            return deltaTime
        }

        let speed = Double(action.speed)
        if speed <= 0 {
            return nil
        }

        let scaled = deltaTime * speed
        let needed = duration - state.elapsed
        if scaled >= needed {
            state.elapsed = duration
            _applyLeaf(state: state, t: 1, node: node)
            return (scaled - needed) / speed
        }

        state.elapsed += scaled
        var t = Float(state.elapsed / duration)
        switch action.timingMode {
        case .linear:
            break
        case .easeIn:
            t = t * t
        case .easeOut:
            t = 1 - (1 - t) * (1 - t)
        case .easeInEaseOut:
            t = t < 0.5 ? 2 * t * t : 1 - pow(-2 * t + 2, 2) / 2
        }
        if let timing = action.timingFunction {
            t = timing(t)
        }
        _applyLeaf(state: state, t: t, node: node)
        return nil
    }

    func _applyLeaf(state: _SCNActionState, t: Float, node: SCNNode) {
        switch state.action.kind {
        case .wait:
            break
        case .hide:
            node.isHidden = true
        case .unhide:
            node.isHidden = false
        case .remove:
            node.removeFromParentNode()
        case .fadeTo(let opacity):
            node.opacity = state.startOpacity + (opacity - state.startOpacity) * CGFloat(t)
        case .fadeBy(let factor):
            node.opacity = state.startOpacity + factor * CGFloat(t)
        case .moveBy(let delta):
            node.position = _scnAdd(state.startPosition, _scnScale(delta, t))
        case .moveTo(let location):
            node.position = _scnLerp(state.startPosition, location, t)
        case .rotateBy(let delta):
            node.eulerAngles = _scnAdd(state.startEuler, _scnScale(delta, t))
        case .rotateTo(let euler, _):
            node.eulerAngles = _scnLerp(state.startEuler, euler, t)
        case .rotateByAxis(let angle, let axis):
            let q = _scnQuaternionFromAxisAngle(axis, angle * t)
            node.orientation = _scnQuaternionMultiply(q, _scnQuaternionFromEuler(state.startEuler))
        case .rotateToAxisAngle(let axisAngle):
            node.rotation = axisAngle
        case .scaleBy(let factor):
            let s = 1 + (factor - 1) * t
            node.scale = _scnScale(state.startScale, s)
        case .scaleTo(let value):
            node.scale = _scnLerp(state.startScale, SCNVector3(value, value, value), t)
        case .run(let block):
            block(node)
        case .custom(let block):
            block(node, CGFloat(t))
        case .javascript, .playAudio, .sequence, .group, .repeat:
            break
        }
    }
}

public final class SCNHitTestResult: NSObject {
    public let node: SCNNode
    public let worldCoordinates: SCNVector3
    public let localCoordinates: SCNVector3
    public let worldNormal: SCNVector3
    public let localNormal: SCNVector3
    public let modelTransform: SCNMatrix4
    public let faceIndex: Int
    public let geometryIndex: Int
    public let boneNode: SCNNode?

    init(
        node: SCNNode,
        worldCoordinates: SCNVector3,
        localCoordinates: SCNVector3,
        worldNormal: SCNVector3,
        localNormal: SCNVector3,
        modelTransform: SCNMatrix4,
        faceIndex: Int = 0,
        geometryIndex: Int = 0,
        boneNode: SCNNode? = nil
    ) {
        self.node = node
        self.worldCoordinates = worldCoordinates
        self.localCoordinates = localCoordinates
        self.worldNormal = worldNormal
        self.localNormal = localNormal
        self.modelTransform = modelTransform
        self.faceIndex = faceIndex
        self.geometryIndex = geometryIndex
        self.boneNode = boneNode
    }

#if canImport(simd)
    public var simdLocalCoordinates: simd_float3 { _scnSimd3(localCoordinates) }
    public var simdWorldCoordinates: simd_float3 { _scnSimd3(worldCoordinates) }
    public var simdLocalNormal: simd_float3 { _scnSimd3(localNormal) }
    public var simdWorldNormal: simd_float3 { _scnSimd3(worldNormal) }
    public var simdModelTransform: simd_float4x4 { _scnSimdMatrix(modelTransform) }
#endif

    public func textureCoordinates(withMappingChannel channel: Int) -> CGPoint {
        _ = channel
        return .zero
    }
}
