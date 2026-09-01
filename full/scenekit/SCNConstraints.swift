import Foundation

open class SCNConstraint: NSObject, SCNAnimatable {
    public var isEnabled = true
    public var isIncremental = false
    public var influenceFactor: CGFloat = 1
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

public final class SCNLookAtConstraint: SCNConstraint {
    public var target: SCNNode?
    public var isGimbalLockEnabled = false
    public var targetOffset = SCNVector3Zero
    public var localFront = SCNNode.localFront
    public var worldUp = SCNNode.localUp

    public convenience init(target: SCNNode?) {
        self.init()
        self.target = target
    }
}

public final class SCNBillboardConstraint: SCNConstraint {
    public var freeAxes = SCNBillboardAxis.all
}

public final class SCNTransformConstraint: SCNConstraint {
    var _inWorldSpace = true
    var _transformBlock: ((SCNNode, SCNMatrix4) -> SCNMatrix4)?
    var _orientationBlock: ((SCNNode, SCNQuaternion) -> SCNQuaternion)?
    var _positionBlock: ((SCNNode, SCNVector3) -> SCNVector3)?

    public convenience init(inWorldSpace world: Bool, with block: @escaping (SCNNode, SCNMatrix4) -> SCNMatrix4) {
        self.init()
        _inWorldSpace = world
        _transformBlock = block
    }

    public convenience init(inWorldSpace world: Bool, withBlock block: @escaping (SCNNode, SCNMatrix4) -> SCNMatrix4) {
        self.init(inWorldSpace: world, with: block)
    }

    public class func orientationConstraint(
        inWorldSpace world: Bool,
        with block: @escaping (SCNNode, SCNQuaternion) -> SCNQuaternion
    ) -> SCNTransformConstraint {
        let constraint = SCNTransformConstraint()
        constraint._inWorldSpace = world
        constraint._orientationBlock = block
        return constraint
    }

    public class func positionConstraint(
        inWorldSpace world: Bool,
        with block: @escaping (SCNNode, SCNVector3) -> SCNVector3
    ) -> SCNTransformConstraint {
        let constraint = SCNTransformConstraint()
        constraint._inWorldSpace = world
        constraint._positionBlock = block
        return constraint
    }
}

public final class SCNIKConstraint: SCNConstraint {
    public let chainRootNode: SCNNode
    public var targetPosition = SCNVector3Zero
    var _jointLimits: [ObjectIdentifier: CGFloat] = [:]

    public init(chainRootNode: SCNNode) {
        self.chainRootNode = chainRootNode
        super.init()
    }

    public required init?(coder: NSCoder) { return nil }

    public class func inverseKinematicsConstraint(chainRootNode: SCNNode) -> SCNIKConstraint {
        SCNIKConstraint(chainRootNode: chainRootNode)
    }

    public func maxAllowedRotationAngle(forJoint node: SCNNode) -> CGFloat {
        _jointLimits[ObjectIdentifier(node)] ?? 180
    }

    public func setMaxAllowedRotationAngle(_ angle: CGFloat, forJoint node: SCNNode) {
        _jointLimits[ObjectIdentifier(node)] = angle
    }
}

public final class SCNReplicatorConstraint: SCNConstraint {
    public var target: SCNNode?
    public var replicatesOrientation = true
    public var replicatesPosition = true
    public var replicatesScale = true
    public var orientationOffset = _scnQuaternionIdentity()
    public var positionOffset = SCNVector3Zero
    public var scaleOffset = SCNVector3Zero

    public convenience init(target: SCNNode?) {
        self.init()
        self.target = target
    }
}

public final class SCNAccelerationConstraint: SCNConstraint {
    public var damping: CGFloat = 0.1
    public var decelerationDistance: CGFloat = 0
    public var maximumLinearAcceleration: CGFloat = .greatestFiniteMagnitude
    public var maximumLinearVelocity: CGFloat = .greatestFiniteMagnitude
}

public final class SCNAvoidOccluderConstraint: SCNConstraint {
    public var target: SCNNode?
    public var bias: CGFloat = 0
    public var occluderCategoryBitMask = 1
    public weak var delegate: (any SCNAvoidOccluderConstraintDelegate)?

    public convenience init(target: SCNNode?) {
        self.init()
        self.target = target
    }
}

public final class SCNDistanceConstraint: SCNConstraint {
    public var target: SCNNode?
    public var minimumDistance: CGFloat = 0
    public var maximumDistance: CGFloat = CGFloat.greatestFiniteMagnitude

    public convenience init(target: SCNNode?) {
        self.init()
        self.target = target
    }
}

public final class SCNSliderConstraint: SCNConstraint {
    public var collisionCategoryBitMask = 0
    public var offset: CGFloat = 0
    public var radius: CGFloat = 0.5
}
