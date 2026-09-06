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

open class SCNTimingFunction: NSObject {
    public override init() { super.init() }
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
    public var inputProperty: String?
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

    public override init() { super.init() }
    public convenience init?(named name: String, inDirectory directory: String?) {
        _ = name
        _ = directory
        return nil
    }

    public func reset() {}
    public func addModifier(forProperties properties: [ParticleProperty], at stage: SCNParticleModifierStage, modifier: @escaping SCNParticleModifierBlock) {
        _ = properties
        _ = stage
        _ = modifier
    }
    public func handle(_ event: SCNParticleEvent, forProperties properties: [ParticleProperty], handler: @escaping SCNParticleEventBlock) {
        _ = event
        _ = properties
        _ = handler
    }
    public func removeAllModifiers() {}
    public func removeModifiers(at stage: SCNParticleModifierStage) { _ = stage }

    public func copy(with zone: NSZone? = nil) -> Any { SCNParticleSystem() }

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
