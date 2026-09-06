import Foundation

/// Linux data stand-in for QuartzCore's `CAAnimation`. Isolated SceneKit
/// compiles without QuartzCore; properties are stored, not executed as
/// CoreAnimation. Not claimed Apple-identical.
open class CAAnimation: NSObject {
    public var duration: TimeInterval = 0
    public var animationEvents: [SCNAnimationEvent]?
    public var fadeInDuration: CGFloat = 0
    public var fadeOutDuration: CGFloat = 0
    public var usesSceneTimeBase: Bool = false

    public override init() { super.init() }

    public convenience init(SCNAnimation animation: SCNAnimation) {
        self.init()
        self.duration = animation.duration
        self.usesSceneTimeBase = animation.usesSceneTimeBase
        self.fadeInDuration = CGFloat(animation.blendInDuration)
        self.fadeOutDuration = CGFloat(animation.blendOutDuration)
        self.animationEvents = animation.animationEvents
    }
}

open class SCNMorpher: NSObject, NSSecureCoding, SCNAnimatable {
    public var targets: [SCNGeometry] = []
    public var weights: [NSNumber] = []
    public var calculationMode: SCNMorpherCalculationMode = .normalized
    public var unifiesNormals: Bool = false
    var _named: [String: CGFloat] = [:]
    var _animationPlayers: [String: SCNAnimationPlayer] = [:]

    public override init() { super.init() }

    public func setWeight(_ weight: CGFloat, forTargetAt targetIndex: Int) {
        while weights.count <= targetIndex {
            weights.append(0)
        }
        weights[targetIndex] = NSNumber(value: Double(weight))
    }

    public func weight(forTargetAt targetIndex: Int) -> CGFloat {
        guard weights.indices.contains(targetIndex) else { return 0 }
        return CGFloat(Double(truncating: weights[targetIndex]))
    }

    public func setWeight(_ weight: CGFloat, forTargetNamed name: String) {
        _named[name] = weight
    }

    public func weight(forTargetNamed name: String) -> CGFloat {
        _named[name] ?? 0
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

    public static var supportsSecureCoding: Bool { true }
    public required init?(coder: NSCoder) { return nil }
    public func encode(with coder: NSCoder) {}
}

open class SCNSkinner: NSObject, NSSecureCoding {
    public var baseGeometry: SCNGeometry?
    public var baseGeometryBindTransform: SCNMatrix4 = SCNMatrix4Identity
    public var bones: [SCNNode]
    public var boneInverseBindTransforms: [NSValue]?
    public var boneWeights: SCNGeometrySource?
    public var boneIndices: SCNGeometrySource?
    public weak var skeleton: SCNNode?

    public override init() {
        bones = []
        super.init()
    }

    public convenience init(
        baseGeometry: SCNGeometry?,
        bones: [SCNNode],
        boneInverseBindTransforms: [NSValue]?,
        boneWeights: SCNGeometrySource,
        boneIndices: SCNGeometrySource
    ) {
        self.init()
        self.baseGeometry = baseGeometry
        self.bones = bones
        self.boneInverseBindTransforms = boneInverseBindTransforms
        self.boneWeights = boneWeights
        self.boneIndices = boneIndices
    }

    public static var supportsSecureCoding: Bool { true }
    public required init?(coder: NSCoder) { return nil }
    public func encode(with coder: NSCoder) {}
}

open class SCNAnimation: NSObject, NSCopying, NSSecureCoding, SCNAnimationProtocol {
    public var duration: TimeInterval = 0
    public var keyPath: String?
    public var startDelay: TimeInterval = 0
    public var timeOffset: TimeInterval = 0
    public var repeatCount: CGFloat = 0
    public var autoreverses: Bool = false
    public var blendInDuration: TimeInterval = 0
    public var blendOutDuration: TimeInterval = 0
    public var isRemovedOnCompletion: Bool = true
    public var isAppliedOnCompletion: Bool = false
    public var isAdditive: Bool = false
    public var isCumulative: Bool = false
    public var fillsForward: Bool = false
    public var fillsBackward: Bool = false
    public var usesSceneTimeBase: Bool = false
    public var animationEvents: [SCNAnimationEvent]?
    public var animationDidStart: SCNAnimationDidStartBlock?
    public var animationDidStop: SCNAnimationDidStopBlock?
    public var timingFunction: SCNTimingFunction = SCNTimingFunction()

    public override init() { super.init() }
    public convenience init?(named name: String) { self.init(); self.keyPath = name }
    public convenience init?(contentsOf url: URL) { self.init(); _ = url }
    public convenience init?(contentsOfURL url: URL) { self.init(contentsOf: url) }
    public convenience init(caAnimation: CAAnimation) {
        self.init()
        duration = caAnimation.duration
        usesSceneTimeBase = caAnimation.usesSceneTimeBase
        blendInDuration = TimeInterval(caAnimation.fadeInDuration)
        blendOutDuration = TimeInterval(caAnimation.fadeOutDuration)
        animationEvents = caAnimation.animationEvents
    }
    public convenience init(CAAnimation caAnimation: CAAnimation) {
        self.init(caAnimation: caAnimation)
    }

    public func copy(with zone: NSZone? = nil) -> Any {
        let copy = SCNAnimation()
        copy.duration = duration
        copy.keyPath = keyPath
        return copy
    }

    public static var supportsSecureCoding: Bool { true }
    public required init?(coder: NSCoder) { return nil }
    public func encode(with coder: NSCoder) {}
}

open class SCNAnimationEvent: NSObject {
    public var time: CGFloat = 0
    public var eventBlock: SCNAnimationEventBlock?

    public override init() { super.init() }

    public convenience init(keyTime time: CGFloat, block eventBlock: @escaping SCNAnimationEventBlock) {
        self.init()
        self.time = time
        self.eventBlock = eventBlock
    }
}

open class SCNAnimationPlayer: NSObject, NSCopying, NSSecureCoding, SCNAnimatable {
    public var animation: SCNAnimation
    public var speed: CGFloat = 1
    public var blendFactor: CGFloat = 1
    public var paused: Bool = false
    var _animationPlayers: [String: SCNAnimationPlayer] = [:]

    public override init() {
        animation = SCNAnimation()
        super.init()
    }

    public convenience init(animation: SCNAnimation) {
        self.init()
        self.animation = animation
    }

    public func play() { paused = false }
    public func stop() { paused = true }
    public func stop(withBlendOutDuration duration: CGFloat) {
        _ = duration
        paused = true
    }

    public func copy(with zone: NSZone? = nil) -> Any {
        let copy = SCNAnimationPlayer(animation: animation)
        copy.speed = speed
        copy.paused = paused
        return copy
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

    public static var supportsSecureCoding: Bool { true }
    public required init?(coder: NSCoder) { return nil }
    public func encode(with coder: NSCoder) {}
}

open class SCNTimingFunction: NSObject, NSSecureCoding {
    var _mode: SCNActionTimingMode = .linear

    public override init() { super.init() }

    open class func function(withTimingMode timingMode: SCNActionTimingMode) -> SCNTimingFunction {
        let function = SCNTimingFunction()
        function._mode = timingMode
        return function
    }

    public static var supportsSecureCoding: Bool { true }
    public required init?(coder: NSCoder) { return nil }
    public func encode(with coder: NSCoder) {}
}

open class SCNAudioSource: NSObject, NSCopying, NSSecureCoding {
    public var loops: Bool = false
    public var isPositional: Bool = false
    public var volume: Float = 1
    public var rate: Float = 1
    public var reverbBlend: Float = 0
    public var shouldStream: Bool = false
    var durationHint: TimeInterval = 0
    var loaded = false

    public override init() { super.init() }
    public convenience init?(named fileName: String) { self.init(); _ = fileName }
    public convenience init?(fileNamed fileName: String) { self.init(named: fileName) }
    public convenience init?(url: URL) { self.init(); _ = url }
    public convenience init?(URL url: URL) { self.init(url: url) }

    public func load() { loaded = true }

    public func copy(with zone: NSZone? = nil) -> Any {
        let copy = SCNAudioSource()
        copy.loops = loops
        copy.volume = volume
        return copy
    }

    public static var supportsSecureCoding: Bool { true }
    public required init?(coder: NSCoder) { return nil }
    public func encode(with coder: NSCoder) {}
}

open class SCNAudioPlayer: NSObject {
    public var audioSource: SCNAudioSource?
    public var willStartPlayback: (() -> Void)?
    public var didFinishPlayback: (() -> Void)?

    public override init() { super.init() }
    public convenience init(source: SCNAudioSource) {
        self.init()
        self.audioSource = source
    }
}

open class SCNParticlePropertyController: NSObject, NSSecureCoding {
    public var inputMode: SCNParticleInputMode = .overLife
    public var inputOrigin: SCNNode?
    public var inputProperty: SCNParticleSystem.ParticleProperty?
    public var inputScale: CGFloat = 1
    public var inputBias: CGFloat = 0
    public var animation: CAAnimation = CAAnimation()

    public override init() { super.init() }
    public convenience init(animation: CAAnimation) {
        self.init()
        self.animation = animation
    }
    public static var supportsSecureCoding: Bool { true }
    public required init?(coder: NSCoder) { return nil }
    public func encode(with coder: NSCoder) {}
}

open class SCNParticleSystem: NSObject, NSCopying, NSSecureCoding, SCNAnimatable {
    public struct ParticleProperty: RawRepresentable, Hashable, Sendable {
        public var rawValue: String
        public init(rawValue: String) { self.rawValue = rawValue }
        public static let position = ParticleProperty(rawValue: "position")
        public static let angle = ParticleProperty(rawValue: "angle")
        public static let rotationAxis = ParticleProperty(rawValue: "rotationAxis")
        public static let velocity = ParticleProperty(rawValue: "velocity")
        public static let angularVelocity = ParticleProperty(rawValue: "angularVelocity")
        public static let life = ParticleProperty(rawValue: "life")
        public static let color = ParticleProperty(rawValue: "color")
        public static let opacity = ParticleProperty(rawValue: "opacity")
        public static let size = ParticleProperty(rawValue: "size")
        public static let frame = ParticleProperty(rawValue: "frame")
        public static let frameRate = ParticleProperty(rawValue: "frameRate")
        public static let bounce = ParticleProperty(rawValue: "bounce")
        public static let charge = ParticleProperty(rawValue: "charge")
        public static let friction = ParticleProperty(rawValue: "friction")
        public static let contactPoint = ParticleProperty(rawValue: "contactPoint")
        public static let contactNormal = ParticleProperty(rawValue: "contactNormal")
    }

    public var birthRate: CGFloat = 0
    public var birthRateVariation: CGFloat = 0
    public var warmupDuration: CGFloat = 0
    public var emissionDuration: CGFloat = 1
    public var emissionDurationVariation: CGFloat = 0
    public var idleDuration: CGFloat = 0
    public var idleDurationVariation: CGFloat = 0
    public var loops: Bool = true
    public var birthLocation: SCNParticleBirthLocation = .surface
    public var birthDirection: SCNParticleBirthDirection = .constant
    public var emittingDirection: SCNVector3 = SCNVector3(x: 0, y: 1, z: 0)
    public var spreadingAngle: CGFloat = 0
    public var particleAngle: CGFloat = 0
    public var particleAngleVariation: CGFloat = 0
    public var particleVelocity: CGFloat = 1
    public var particleVelocityVariation: CGFloat = 0
    public var particleAngularVelocity: CGFloat = 0
    public var particleAngularVelocityVariation: CGFloat = 0
    public var particleLifeSpan: CGFloat = 1
    public var particleLifeSpanVariation: CGFloat = 0
    public var particleSize: CGFloat = 1
    public var particleSizeVariation: CGFloat = 0
    public var particleColor: Any = SCNVector4(x: 1, y: 1, z: 1, w: 1)
    public var particleColorVariation: SCNVector4 = SCNVector4Zero
    public var particleImage: Any?
    public var particleIntensity: CGFloat = 1
    public var particleIntensityVariation: CGFloat = 0
    public var blendMode: SCNParticleBlendMode = .additive
    public var orientationMode: SCNParticleOrientationMode = .billboardScreenAligned
    public var sortingMode: SCNParticleSortingMode = .none
    public var isLightingEnabled: Bool = false
    public var isBlackPassEnabled: Bool = false
    public var writesToDepthBuffer: Bool = false
    public var isLocal: Bool = false
    public var acceleration: SCNVector3 = SCNVector3Zero
    public var dampingFactor: CGFloat = 0
    public var speedFactor: CGFloat = 1
    public var stretchFactor: CGFloat = 0
    public var fresnelExponent: CGFloat = 0
    public var isAffectedByGravity: Bool = false
    public var isAffectedByPhysicsFields: Bool = false
    public var particleDiesOnCollision: Bool = false
    public var particleMass: CGFloat = 1
    public var particleMassVariation: CGFloat = 0
    public var particleBounce: CGFloat = 0
    public var particleBounceVariation: CGFloat = 0
    public var particleFriction: CGFloat = 0
    public var particleFrictionVariation: CGFloat = 0
    public var particleCharge: CGFloat = 0
    public var particleChargeVariation: CGFloat = 0
    public var colliderNodes: [SCNNode]?
    public var emitterShape: SCNGeometry?
    public var orientationDirection: SCNVector3 = SCNVector3(x: 0, y: 1, z: 0)
    public var imageSequenceRowCount: Int = 1
    public var imageSequenceColumnCount: Int = 1
    public var imageSequenceInitialFrame: CGFloat = 0
    public var imageSequenceInitialFrameVariation: CGFloat = 0
    public var imageSequenceFrameRate: CGFloat = 0
    public var imageSequenceFrameRateVariation: CGFloat = 0
    public var imageSequenceAnimationMode: SCNParticleImageSequenceAnimationMode = .repeat
    public var propertyControllers: [SCNParticleSystem.ParticleProperty: SCNParticlePropertyController]?
    public var systemSpawnedOnCollision: SCNParticleSystem?
    public var systemSpawnedOnDying: SCNParticleSystem?
    public var systemSpawnedOnLiving: SCNParticleSystem?
    var _animationPlayers: [String: SCNAnimationPlayer] = [:]
    var _modifiers: [(properties: [ParticleProperty], stage: SCNParticleModifierStage, block: SCNParticleModifierBlock)] = []
    var _eventHandlers: [(event: SCNParticleEvent, properties: [ParticleProperty], handler: SCNParticleEventBlock)] = []
    var _particles: [_SCNLinuxParticle] = []
    var _birthAccumulator: CGFloat = 0
    var _emitElapsed: CGFloat = 0
    var _idleElapsed: CGFloat = 0
    var _emitting = true

    /// Linux inspection of live CPU particles. Not an Apple API.
    public var linux_aliveCount: Int { _particles.count }

    /// Linux inspection of the first live particle position. Not an Apple API.
    public var linux_firstPosition: SCNVector3 { _particles.first?.position ?? SCNVector3Zero }

    public override init() { super.init() }
    public convenience init?(named name: String, inDirectory directory: String?) {
        _ = name
        _ = directory
        return nil
    }

    public func reset() {
        _particles.removeAll()
        _birthAccumulator = 0
        _emitElapsed = 0
        _idleElapsed = 0
        _emitting = true
    }

    public func addModifier(
        forProperties properties: [ParticleProperty],
        at stage: SCNParticleModifierStage,
        modifier: @escaping SCNParticleModifierBlock
    ) {
        _modifiers.append((properties, stage, modifier))
    }

    public func handle(
        _ event: SCNParticleEvent,
        forProperties properties: [ParticleProperty],
        handler: @escaping SCNParticleEventBlock
    ) {
        _eventHandlers.append((event, properties, handler))
    }

    public func removeAllModifiers() {
        _modifiers.removeAll()
    }

    public func removeModifiers(at stage: SCNParticleModifierStage) {
        _modifiers.removeAll { $0.stage == stage }
    }

    /// Linux CPU particle clock. Birth rate, life, acceleration, modifiers.
    public func linux_advance(_ dt: TimeInterval) {
        let h = max(dt * TimeInterval(speedFactor), 0)
        guard h > 0 else { return }
        _updateEmission(h)
        _runModifiers(stage: .preDynamics, dt: Float(h))
        _integrate(dt: Float(h))
        _runModifiers(stage: .postDynamics, dt: Float(h))
        _runModifiers(stage: .preCollision, dt: Float(h))
        _collide()
        _runModifiers(stage: .postCollision, dt: Float(h))
        _reap(dt: Float(h))
    }

    func _updateEmission(_ dt: TimeInterval) {
        let emitWindow = max(emissionDuration, 0)
        let idleWindow = max(idleDuration, 0)
        if _emitting {
            _emitElapsed += CGFloat(dt)
            if emitWindow > 0 && _emitElapsed >= emitWindow {
                _emitting = false
                _idleElapsed = 0
                if !loops && idleWindow <= 0 { return }
            }
        } else {
            _idleElapsed += CGFloat(dt)
            if loops && _idleElapsed >= idleWindow {
                _emitting = true
                _emitElapsed = 0
            }
        }
        guard _emitting else { return }
        _birthAccumulator += birthRate * CGFloat(dt)
        let spawn = Int(_birthAccumulator)
        if spawn > 0 {
            _birthAccumulator -= CGFloat(spawn)
            var born = 0
            for _ in 0..<spawn {
                _particles.append(_spawnParticle())
                born += 1
            }
            if born > 0 {
                _fireEvent(.birth, count: born)
            }
        }
    }

    func _spawnParticle() -> _SCNLinuxParticle {
        var p = _SCNLinuxParticle()
        p.position = SCNVector3Zero
        if let shape = emitterShape {
            let box = shape.boundingBox
            let tx = (box.min.x + box.max.x) * 0.5
            let ty = (box.min.y + box.max.y) * 0.5
            let tz = (box.min.z + box.max.z) * 0.5
            switch birthLocation {
            case .volume:
                p.position = SCNVector3(
                    x: box.min.x + (box.max.x - box.min.x) * 0.5,
                    y: box.min.y + (box.max.y - box.min.y) * 0.5,
                    z: box.min.z + (box.max.z - box.min.z) * 0.5
                )
            case .vertex, .surface:
                p.position = SCNVector3(x: tx, y: box.max.y, z: tz)
            @unknown default:
                p.position = SCNVector3(x: tx, y: ty, z: tz)
            }
        }
        var dir = _scnNormalize(emittingDirection)
        if _scnLength(dir) < 1e-8 {
            dir = SCNVector3(0, 1, 0)
        }
        if spreadingAngle > 0 {
            let tilt = Float(spreadingAngle) * (.pi / 180) * 0.5
            dir = _scnNormalize(SCNVector3(dir.x + tilt, dir.y, dir.z))
        }
        p.velocity = _scnScale(dir, Float(particleVelocity))
        p.life = Float(max(particleLifeSpan, 0))
        p.maxLife = p.life
        p.size = Float(particleSize)
        p.angle = Float(particleAngle)
        p.angularVelocity = Float(particleAngularVelocity)
        p.rotationAxis = _scnNormalize(orientationDirection)
        if _scnLength(p.rotationAxis) < 1e-8 {
            p.rotationAxis = SCNVector3(0, 1, 0)
        }
        if let color = particleColor as? SCNVector4 {
            p.color = color
        } else if let color = particleColor as? SCNVector3 {
            p.color = SCNVector4(x: color.x, y: color.y, z: color.z, w: 1)
        } else {
            p.color = SCNVector4(1, 1, 1, 1)
        }
        p.bounce = Float(particleBounce)
        p.charge = Float(particleCharge)
        p.friction = Float(particleFriction)
        p.mass = Float(max(particleMass, 1e-6))
        p.frame = Float(imageSequenceInitialFrame)
        p.frameRate = Float(imageSequenceFrameRate)
        return p
    }

    func _integrate(dt: Float) {
        let acc = acceleration
        let damp = max(0, min(1, 1 - Float(dampingFactor) * dt))
        for i in _particles.indices {
            var p = _particles[i]
            p.velocity = _scnAdd(p.velocity, _scnScale(acc, dt))
            if isAffectedByGravity {
                p.velocity = _scnAdd(p.velocity, SCNVector3(0, -9.8 * dt, 0))
            }
            p.velocity = _scnScale(p.velocity, damp)
            p.position = _scnAdd(p.position, _scnScale(p.velocity, dt))
            p.angle += p.angularVelocity * dt
            p.life -= dt
            p.frame += p.frameRate * dt
            _particles[i] = p
        }
    }

    func _collide() {
        guard particleDiesOnCollision, let colliders = colliderNodes, !colliders.isEmpty else { return }
        for i in _particles.indices {
            var p = _particles[i]
            for node in colliders {
                let box = node.boundingBox
                let min = _scnTransformPoint(node.worldTransform, box.min)
                let max = _scnTransformPoint(node.worldTransform, box.max)
                let lo = SCNVector3(x: Swift.min(min.x, max.x), y: Swift.min(min.y, max.y), z: Swift.min(min.z, max.z))
                let hi = SCNVector3(x: Swift.max(min.x, max.x), y: Swift.max(min.y, max.y), z: Swift.max(min.z, max.z))
                if p.position.x >= lo.x && p.position.x <= hi.x
                    && p.position.y >= lo.y && p.position.y <= hi.y
                    && p.position.z >= lo.z && p.position.z <= hi.z {
                    p.life = 0
                    p.contactPoint = p.position
                    p.contactNormal = SCNVector3(0, 1, 0)
                    _particles[i] = p
                    _fireEvent(.collision, count: 1)
                    break
                }
            }
        }
    }

    func _reap(dt: Float) {
        _ = dt
        let before = _particles.count
        _particles.removeAll { $0.life <= 0 }
        let died = before - _particles.count
        if died > 0 {
            _fireEvent(.death, count: died)
        }
    }

    func _runModifiers(stage: SCNParticleModifierStage, dt: Float) {
        let mods = _modifiers.filter { $0.stage == stage }
        guard !mods.isEmpty, !_particles.isEmpty else { return }
        for mod in mods {
            _invokeModifier(mod.properties, dt: dt, block: mod.block)
        }
    }

    func _invokeModifier(
        _ properties: [ParticleProperty],
        dt: Float,
        block: SCNParticleModifierBlock
    ) {
        let count = _particles.count
        guard count > 0, !properties.isEmpty else { return }
        var buffers: [UnsafeMutablePointer<Float>] = []
        var strides: [Int] = []
        for prop in properties {
            let comps = _scnParticleComponents(prop)
            let ptr = UnsafeMutablePointer<Float>.allocate(capacity: count * comps)
            for i in 0..<count {
                _scnParticleWrite(prop, particle: _particles[i], dest: ptr + i * comps)
            }
            buffers.append(ptr)
            strides.append(MemoryLayout<Float>.stride * comps)
        }
        defer { buffers.forEach { $0.deallocate() } }
        var raws = buffers.map { UnsafeMutableRawPointer($0) }
        raws.withUnsafeMutableBufferPointer { rawBuf in
            strides.withUnsafeMutableBufferPointer { strideBuf in
                guard let rawBase = rawBuf.baseAddress, let strideBase = strideBuf.baseAddress else { return }
                block(rawBase, strideBase, 0, count, dt)
            }
        }
        for (index, prop) in properties.enumerated() {
            let comps = _scnParticleComponents(prop)
            let ptr = buffers[index]
            for i in 0..<count {
                _scnParticleRead(prop, particle: &_particles[i], src: ptr + i * comps)
            }
        }
    }

    func _fireEvent(_ event: SCNParticleEvent, count: Int) {
        let handlers = _eventHandlers.filter { $0.event == event }
        guard !handlers.isEmpty, count > 0 else { return }
        var dummy = UnsafeMutableRawPointer(bitPattern: 1)!
        var stride = 0
        var indices = [UInt32](repeating: 0, count: count)
        for handler in handlers {
            withUnsafeMutablePointer(to: &dummy) { dummyPtr in
                withUnsafeMutablePointer(to: &stride) { stridePtr in
                    indices.withUnsafeMutableBufferPointer { idx in
                        handler.handler(dummyPtr, stridePtr, idx.baseAddress, count)
                    }
                }
            }
        }
    }

    public func copy(with zone: NSZone? = nil) -> Any {
        let copy = SCNParticleSystem()
        copy.birthRate = birthRate
        copy.loops = loops
        copy.emissionDuration = emissionDuration
        copy.particleLifeSpan = particleLifeSpan
        copy.particleSize = particleSize
        copy.particleVelocity = particleVelocity
        copy.emittingDirection = emittingDirection
        copy.acceleration = acceleration
        copy.emitterShape = emitterShape
        return copy
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

    public static var supportsSecureCoding: Bool { true }
    public required init?(coder: NSCoder) { return nil }
    public func encode(with coder: NSCoder) {}
}

struct _SCNLinuxParticle {
    var position = SCNVector3Zero
    var velocity = SCNVector3Zero
    var rotationAxis = SCNVector3(0, 1, 0)
    var contactPoint = SCNVector3Zero
    var contactNormal = SCNVector3(0, 1, 0)
    var color = SCNVector4(1, 1, 1, 1)
    var angle: Float = 0
    var angularVelocity: Float = 0
    var life: Float = 1
    var maxLife: Float = 1
    var size: Float = 1
    var bounce: Float = 0
    var charge: Float = 0
    var friction: Float = 0
    var mass: Float = 1
    var frame: Float = 0
    var frameRate: Float = 0
}

func _scnParticleComponents(_ property: SCNParticleSystem.ParticleProperty) -> Int {
    switch property {
    case .position, .velocity, .rotationAxis, .contactPoint, .contactNormal:
        return 3
    case .color:
        return 4
    default:
        return 1
    }
}

func _scnParticleWrite(
    _ property: SCNParticleSystem.ParticleProperty,
    particle: _SCNLinuxParticle,
    dest: UnsafeMutablePointer<Float>
) {
    switch property {
    case .position:
        dest[0] = particle.position.x; dest[1] = particle.position.y; dest[2] = particle.position.z
    case .velocity:
        dest[0] = particle.velocity.x; dest[1] = particle.velocity.y; dest[2] = particle.velocity.z
    case .rotationAxis:
        dest[0] = particle.rotationAxis.x; dest[1] = particle.rotationAxis.y; dest[2] = particle.rotationAxis.z
    case .contactPoint:
        dest[0] = particle.contactPoint.x; dest[1] = particle.contactPoint.y; dest[2] = particle.contactPoint.z
    case .contactNormal:
        dest[0] = particle.contactNormal.x; dest[1] = particle.contactNormal.y; dest[2] = particle.contactNormal.z
    case .color:
        dest[0] = particle.color.x; dest[1] = particle.color.y; dest[2] = particle.color.z; dest[3] = particle.color.w
    case .angle:
        dest[0] = particle.angle
    case .angularVelocity:
        dest[0] = particle.angularVelocity
    case .life:
        dest[0] = particle.life
    case .size:
        dest[0] = particle.size
    case .bounce:
        dest[0] = particle.bounce
    case .charge:
        dest[0] = particle.charge
    case .friction:
        dest[0] = particle.friction
    case .frame:
        dest[0] = particle.frame
    case .frameRate:
        dest[0] = particle.frameRate
    case .opacity:
        dest[0] = particle.color.w
    default:
        dest[0] = 0
    }
}

func _scnParticleRead(
    _ property: SCNParticleSystem.ParticleProperty,
    particle: inout _SCNLinuxParticle,
    src: UnsafePointer<Float>
) {
    switch property {
    case .position:
        particle.position = SCNVector3(src[0], src[1], src[2])
    case .velocity:
        particle.velocity = SCNVector3(src[0], src[1], src[2])
    case .rotationAxis:
        particle.rotationAxis = SCNVector3(src[0], src[1], src[2])
    case .contactPoint:
        particle.contactPoint = SCNVector3(src[0], src[1], src[2])
    case .contactNormal:
        particle.contactNormal = SCNVector3(src[0], src[1], src[2])
    case .color:
        particle.color = SCNVector4(x: src[0], y: src[1], z: src[2], w: src[3])
    case .angle:
        particle.angle = src[0]
    case .angularVelocity:
        particle.angularVelocity = src[0]
    case .life:
        particle.life = src[0]
    case .size:
        particle.size = src[0]
    case .bounce:
        particle.bounce = src[0]
    case .charge:
        particle.charge = src[0]
    case .friction:
        particle.friction = src[0]
    case .frame:
        particle.frame = src[0]
    case .frameRate:
        particle.frameRate = src[0]
    case .opacity:
        particle.color.w = src[0]
    default:
        break
    }
}
