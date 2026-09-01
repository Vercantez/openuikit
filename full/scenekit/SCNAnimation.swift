import Foundation

public final class SCNAnimation: NSObject, SCNAnimationProtocol {
    public var keyPath: String?
    public var duration: TimeInterval = 0
    public var repeatCount: CGFloat = 1
    public var startDelay: TimeInterval = 0
    public var timeOffset: TimeInterval = 0
    public var autoreverses = false
    public var fillsForward = false
    public var fillsBackward = false
    public var usesSceneTimeBase = false
    public var isAdditive = false
    public var isCumulative = false
    public var isRemovedOnCompletion = true
    public var isAppliedOnCompletion = false
    public var blendInDuration: TimeInterval = 0
    public var blendOutDuration: TimeInterval = 0
    public var animationDidStart: SCNAnimationDidStartBlock?
    public var animationDidStop: SCNAnimationDidStopBlock?
    public var animationEvents: [SCNAnimationEvent]?
    public var timingFunction = SCNTimingFunction(timingMode: .linear)

    public override init() { super.init() }

    public init(named animationName: String) {
        super.init()
        keyPath = animationName
    }

    public init(contentsOf animationUrl: URL) {
        super.init()
        keyPath = animationUrl.path
    }

    public convenience init(contentsOfURL animationUrl: URL) {
        self.init(contentsOf: animationUrl)
    }

    public required init?(coder: NSCoder) { return nil }
}

public final class SCNAnimationPlayer: NSObject, SCNAnimatable {
    public let animation: SCNAnimation
    public var speed: CGFloat = 1
    public var blendFactor: CGFloat = 1
    public var paused = false
    var _animationPlayers: [String: SCNAnimationPlayer] = [:]

    public init(animation: SCNAnimation) {
        self.animation = animation
        super.init()
    }

    public required init?(coder: NSCoder) { return nil }

    public func play() { paused = false }
    public func stop() { paused = true }
    public func stop(withBlendOutDuration duration: TimeInterval) {
        _ = duration
        paused = true
    }

    public var animationKeys: [String] { Array(_animationPlayers.keys) }
    public func addAnimation(_ animation: any SCNAnimationProtocol, forKey key: String?) {
        _ = animation
        _animationPlayers[key ?? UUID().uuidString] = self
    }
    public func addAnimationPlayer(_ player: SCNAnimationPlayer, forKey key: String?) {
        _animationPlayers[key ?? UUID().uuidString] = player
    }
    public func animationPlayer(forKey key: String) -> SCNAnimationPlayer? { _animationPlayers[key] }
    public func isAnimationPaused(forKey key: String) -> Bool { _animationPlayers[key]?.paused ?? paused }
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

public final class SCNAnimationEvent: NSObject {
    public let keyTime: CGFloat
    public let eventBlock: SCNAnimationEventBlock

    public init(keyTime time: CGFloat, block eventBlock: @escaping SCNAnimationEventBlock) {
        self.keyTime = time
        self.eventBlock = eventBlock
        super.init()
    }
}

public final class SCNTimingFunction: NSObject {
    public let timingMode: SCNActionTimingMode

    public init(timingMode: SCNActionTimingMode) {
        self.timingMode = timingMode
        super.init()
    }

    public required init?(coder: NSCoder) { return nil }
}

public final class SCNAudioSource: NSObject {
    public var url: URL?
    public var loops = false
    public var isPositional = false
    public var volume: Float = 1
    public var rate: Float = 1
    public var reverbBlend: Float = 0
    public var shouldStream = false
    public private(set) var isLoaded = false

    public convenience init?(named fileName: String) {
        _ = fileName
        return nil
    }

    public convenience init?(fileNamed name: String) {
        _ = name
        return nil
    }

    public init?(url: URL) {
        self.url = url
        super.init()
    }

    public convenience init?(URL url: URL) {
        self.init(url: url)
    }

    public required init?(coder: NSCoder) { return nil }

    public func load() {
        isLoaded = false
    }
}

public final class SCNAudioPlayer: NSObject {
    public let audioSource: SCNAudioSource?
    public var willStartPlayback: (() -> Void)?
    public var didFinishPlayback: (() -> Void)?

    public init(source: SCNAudioSource) {
        self.audioSource = source
        super.init()
    }
}

public final class SCNParticleSystem: NSObject, SCNAnimatable, SCNShadable {
    public struct ParticleProperty: RawRepresentable, Hashable, Sendable {
        public let rawValue: String
        public init(rawValue: String) { self.rawValue = rawValue }

        public static let position = ParticleProperty(rawValue: "position")
        public static let velocity = ParticleProperty(rawValue: "velocity")
        public static let angle = ParticleProperty(rawValue: "angle")
        public static let angularVelocity = ParticleProperty(rawValue: "angularVelocity")
        public static let bounce = ParticleProperty(rawValue: "bounce")
        public static let charge = ParticleProperty(rawValue: "charge")
        public static let color = ParticleProperty(rawValue: "color")
        public static let contactNormal = ParticleProperty(rawValue: "contactNormal")
        public static let contactPoint = ParticleProperty(rawValue: "contactPoint")
        public static let frame = ParticleProperty(rawValue: "frame")
        public static let frameRate = ParticleProperty(rawValue: "frameRate")
        public static let friction = ParticleProperty(rawValue: "friction")
        public static let life = ParticleProperty(rawValue: "life")
        public static let opacity = ParticleProperty(rawValue: "opacity")
        public static let rotationAxis = ParticleProperty(rawValue: "rotationAxis")
        public static let size = ParticleProperty(rawValue: "size")
    }

    public var birthRate: CGFloat = 0
    public var birthRateVariation: CGFloat = 0
    public var emissionDuration: CGFloat = 1
    public var emissionDurationVariation: CGFloat = 0
    public var idleDuration: CGFloat = 0
    public var idleDurationVariation: CGFloat = 0
    public var loops = true
    public var warmupDuration: CGFloat = 0
    public var birthLocation = SCNParticleBirthLocation.surface
    public var birthDirection = SCNParticleBirthDirection.constant
    public var emittingDirection = SCNVector3(0, 1, 0)
    public var spreadingAngle: CGFloat = 0
    public var emitterShape: SCNGeometry?
    public var orientationMode = SCNParticleOrientationMode.billboardScreenAligned
    public var sortingMode = SCNParticleSortingMode.none
    public var particleAngle: CGFloat = 0
    public var particleAngleVariation: CGFloat = 0
    public var particleAngularVelocity: CGFloat = 0
    public var particleAngularVelocityVariation: CGFloat = 0
    public var particleLifeSpan: CGFloat = 1
    public var particleLifeSpanVariation: CGFloat = 0
    public var particleVelocity: CGFloat = 1
    public var particleVelocityVariation: CGFloat = 0
    public var particleSize: CGFloat = 1
    public var particleSizeVariation: CGFloat = 0
    public var particleColor: Any = NSNumber(value: 1)
    public var particleColorVariation = SCNVector4Zero
    public var particleImage: Any?
    public var fresnelExponent: CGFloat = 0
    public var stretchFactor: CGFloat = 0
    public var blendMode = SCNParticleBlendMode.additive
    public var isBlackPassEnabled = false
    public var isLightingEnabled = false
    public var isLocal = false
    public var dampingFactor: CGFloat = 0
    public var acceleration = SCNVector3Zero
    public var isAffectedByGravity = false
    public var isAffectedByPhysicsFields = false
    public var colliderNodes: [SCNNode]?
    public var particleDiesOnCollision = false
    public var particleMass: CGFloat = 1
    public var particleMassVariation: CGFloat = 0
    public var particleBounce: CGFloat = 0
    public var particleBounceVariation: CGFloat = 0
    public var particleFriction: CGFloat = 1
    public var particleFrictionVariation: CGFloat = 0
    public var particleCharge: CGFloat = 0
    public var particleChargeVariation: CGFloat = 0
    public var particleIntensity: CGFloat = 1
    public var particleIntensityVariation: CGFloat = 0
    public var systemSpawnedOnCollision: SCNParticleSystem?
    public var systemSpawnedOnDying: SCNParticleSystem?
    public var systemSpawnedOnLiving: SCNParticleSystem?
    public var imageSequenceFrameRate: CGFloat = 0
    public var imageSequenceFrameRateVariation: CGFloat = 0
    public var imageSequenceInitialFrame: CGFloat = 0
    public var imageSequenceInitialFrameVariation: CGFloat = 0
    public var imageSequenceAnimationMode = SCNParticleImageSequenceAnimationMode.repeat
    public var imageSequenceColumnCount = 1
    public var imageSequenceRowCount = 1
    public var orientationDirection = SCNVector3(0, 0, 1)
    public var speedFactor: CGFloat = 1
    var _animationPlayers: [String: SCNAnimationPlayer] = [:]

    public override init() { super.init() }

    public convenience init?(named name: String, inDirectory directory: String?) {
        _ = name
        _ = directory
        return nil
    }

    public required init?(coder: NSCoder) { return nil }

    public func reset() {}
    public func addModifier(
        forProperties properties: [SCNParticleSystem.ParticleProperty],
        at stage: SCNParticleModifierStage,
        modifier: @escaping (UnsafeMutablePointer<UnsafeMutableRawPointer>, UnsafeMutablePointer<Int>, Int, Int, Float) -> Void
    ) {
        _ = properties
        _ = stage
        _ = modifier
    }
    public func handle(
        _ event: SCNParticleEvent,
        forProperties properties: [SCNParticleSystem.ParticleProperty],
        handler: @escaping (UnsafeMutablePointer<UnsafeMutableRawPointer>, UnsafeMutablePointer<Int>, UnsafeMutablePointer<UInt32>?, Int) -> Void
    ) {
        _ = event
        _ = properties
        _ = handler
    }
    public func removeAllModifiers() {}
    public func removeModifiers(at stage: SCNParticleModifierStage) { _ = stage }

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

public final class SCNParticlePropertyController: NSObject {
    public var animation: SCNAnimation?
    public var inputMode = SCNParticleInputMode.overLife
    public var inputOrigin: SCNNode?
    public var inputProperty: SCNParticleSystem.ParticleProperty?

    public override init() { super.init() }
    public required init?(coder: NSCoder) { return nil }
}

public final class SCNSkinner: NSObject {
    public var baseGeometry: SCNGeometry?
    public var baseGeometryBindTransform = SCNMatrix4Identity
    public var bones: [SCNNode]
    public var boneInverseBindTransforms: [NSValue]?
    public var boneWeights: SCNGeometrySource
    public var boneIndices: SCNGeometrySource
    public weak var skeleton: SCNNode?

    public init(
        baseGeometry: SCNGeometry?,
        bones: [SCNNode],
        boneInverseBindTransforms: [NSValue]?,
        boneWeights: SCNGeometrySource,
        boneIndices: SCNGeometrySource
    ) {
        self.baseGeometry = baseGeometry
        self.bones = bones
        self.boneInverseBindTransforms = boneInverseBindTransforms
        self.boneWeights = boneWeights
        self.boneIndices = boneIndices
        super.init()
    }

    public required init?(coder: NSCoder) { return nil }
}

public final class SCNCameraController: NSObject {
    public weak var delegate: (any SCNCameraControllerDelegate)?
    public var target = SCNVector3Zero
    public var pointOfView: SCNNode?
    public var interactionMode = SCNInteractionMode.orbitTurntable
    public var automaticTarget = true
    public var inertiaEnabled = false
    public var inertiaFriction: CGFloat = 0.05
    public var minimumHorizontalAngle: Float = -.pi
    public var maximumHorizontalAngle: Float = .pi
    public var minimumVerticalAngle: Float = -.pi
    public var maximumVerticalAngle: Float = .pi
    public var worldUp = SCNNode.localUp

    public override init() { super.init() }

    public func translateInCameraSpaceBy(x: Float, y: Float, z: Float) {
        guard let node = pointOfView else { return }
        node.localTranslate(by: SCNVector3(x, y, z))
    }

    public func clearRoll() {
        guard let node = pointOfView else { return }
        var euler = node.eulerAngles
        euler.z = 0
        node.eulerAngles = euler
    }

    public func stopInertia() {}
    public func rollBy(_ delta: Float, aroundScreenPoint point: CGPoint, viewport: CGSize) {
        _ = delta
        _ = point
        _ = viewport
    }
    public func rotateBy(x: Float, y: Float) {
        guard let node = pointOfView else { return }
        var euler = node.eulerAngles
        euler.y += x
        euler.x += y
        node.eulerAngles = euler
    }
}

public final class SCNProgram: NSObject, SCNShadable {
    public var vertexFunctionName: String?
    public var fragmentFunctionName: String?
    public var isOpaque = true
    public weak var delegate: (any SCNProgramDelegate)?

    public override init() { super.init() }
    public required init?(coder: NSCoder) { return nil }
}
