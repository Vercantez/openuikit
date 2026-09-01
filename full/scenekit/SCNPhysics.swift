import Foundation

public final class SCNPhysicsWorld: NSObject {
    public struct TestOption: RawRepresentable, Hashable, Sendable {
        public let rawValue: String
        public init(rawValue: String) { self.rawValue = rawValue }

        public static let backfaceCulling = TestOption(rawValue: "backfaceCulling")
        public static let collisionBitMask = TestOption(rawValue: "collisionBitMask")
        public static let searchMode = TestOption(rawValue: "searchMode")
    }

    public struct TestSearchMode: RawRepresentable, Hashable, Sendable {
        public let rawValue: String
        public init(rawValue: String) { self.rawValue = rawValue }

        public static let any = TestSearchMode(rawValue: "any")
        public static let closest = TestSearchMode(rawValue: "closest")
        public static let all = TestSearchMode(rawValue: "all")
    }

    public var gravity = SCNVector3(0, -9.8, 0)
    public var speed: CGFloat = 1
    public var timeStep: TimeInterval = 1.0 / 60.0
    public weak var contactDelegate: (any SCNPhysicsContactDelegate)?
    var _behaviors: [SCNPhysicsBehavior] = []
    weak var _scene: SCNScene?

    public override init() { super.init() }
    public required init?(coder: NSCoder) { return nil }

    public var allBehaviors: [SCNPhysicsBehavior] { _behaviors }

    public func addBehavior(_ behavior: SCNPhysicsBehavior) {
        if !_behaviors.contains(where: { $0 === behavior }) {
            _behaviors.append(behavior)
        }
    }

    public func removeBehavior(_ behavior: SCNPhysicsBehavior) {
        _behaviors.removeAll { $0 === behavior }
    }

    public func removeAllBehaviors() {
        _behaviors.removeAll()
    }

    public func updateCollisionPairs() {}

    public func rayTestWithSegment(
        from origin: SCNVector3,
        to dest: SCNVector3,
        options: [SCNPhysicsWorld.TestOption: Any]? = nil
    ) -> [SCNHitTestResult] {
        _ = origin
        _ = dest
        _ = options
        return []
    }

    public func contactTest(
        with body: SCNPhysicsBody,
        options: [SCNPhysicsWorld.TestOption: Any]? = nil
    ) -> [SCNPhysicsContact] {
        _ = body
        _ = options
        return []
    }

    public func contactTestBetween(
        _ bodyA: SCNPhysicsBody,
        _ bodyB: SCNPhysicsBody,
        options: [SCNPhysicsWorld.TestOption: Any]? = nil
    ) -> [SCNPhysicsContact] {
        _ = bodyA
        _ = bodyB
        _ = options
        return []
    }

    public func convexSweepTest(
        with shape: SCNPhysicsShape,
        from: SCNMatrix4,
        to: SCNMatrix4,
        options: [SCNPhysicsWorld.TestOption: Any]? = nil
    ) -> [SCNPhysicsContact] {
        _ = shape
        _ = from
        _ = to
        _ = options
        return []
    }
}

public final class SCNPhysicsBody: NSObject {
    public var type: SCNPhysicsBodyType
    public var physicsShape: SCNPhysicsShape?
    public var isAffectedByGravity = true
    public var allowsResting = true
    public var mass: CGFloat = 1
    public var charge: CGFloat = 0
    public var friction: CGFloat = 0.5
    public var rollingFriction: CGFloat = 0
    public var restitution: CGFloat = 0.5
    public var damping: CGFloat = 0.1
    public var angularDamping: CGFloat = 0.1
    public var velocity = SCNVector3Zero
    public var angularVelocity = SCNVector4Zero
    public var velocityFactor = SCNVector3(1, 1, 1)
    public var angularVelocityFactor = SCNVector3(1, 1, 1)
    public var categoryBitMask = 1
    public var collisionBitMask = ~0
    public var contactTestBitMask = 0
    public var usesDefaultMomentOfInertia = true
    public var momentOfInertia = SCNVector3(1, 1, 1)
    public var centerOfMassOffset = SCNVector3Zero
    public var continuousCollisionDetectionThreshold: CGFloat = 0
    public var linearRestingThreshold: CGFloat = 0.1
    public var angularRestingThreshold: CGFloat = 0.1
    var _resting = false
    var _queuedForce = SCNVector3Zero
    var _queuedTorque = SCNVector4Zero

    public convenience init(type: SCNPhysicsBodyType, shape: SCNPhysicsShape?) {
        self.init()
        self.type = type
        self.physicsShape = shape
        if type == .static {
            mass = 0
        }
    }

    public override init() {
        type = .dynamic
        super.init()
    }

    public required init?(coder: NSCoder) { return nil }

    public class func dynamic() -> SCNPhysicsBody {
        SCNPhysicsBody(type: .dynamic, shape: nil)
    }

    public class func kinematic() -> SCNPhysicsBody {
        SCNPhysicsBody(type: .kinematic, shape: nil)
    }

    public class func `static`() -> SCNPhysicsBody {
        SCNPhysicsBody(type: .static, shape: nil)
    }

    public var isResting: Bool { _resting }

    public func setResting(_ resting: Bool) {
        _resting = resting
    }

    public func applyForce(_ direction: SCNVector3, asImpulse impulse: Bool) {
        if impulse {
            velocity = _scnAdd(velocity, direction)
        } else {
            _queuedForce = _scnAdd(_queuedForce, direction)
        }
    }

    public func applyForce(_ direction: SCNVector3, at position: SCNVector3, asImpulse impulse: Bool) {
        _ = position
        applyForce(direction, asImpulse: impulse)
    }

    public func applyTorque(_ torque: SCNVector4, asImpulse impulse: Bool) {
        if impulse {
            angularVelocity = SCNVector4(
                angularVelocity.x + torque.x,
                angularVelocity.y + torque.y,
                angularVelocity.z + torque.z,
                angularVelocity.w + torque.w
            )
        } else {
            _queuedTorque = torque
        }
    }

    public func clearAllForces() {
        _queuedForce = SCNVector3Zero
        _queuedTorque = SCNVector4Zero
        velocity = SCNVector3Zero
        angularVelocity = SCNVector4Zero
    }

    public func resetTransform() {}
}

public final class SCNPhysicsShape: NSObject {
    public struct Option: RawRepresentable, Hashable, Sendable {
        public let rawValue: String
        public init(rawValue: String) { self.rawValue = rawValue }

        public static let keepAsCompound = Option(rawValue: "keepAsCompound")
        public static let collisionMargin = Option(rawValue: "collisionMargin")
        public static let scale = Option(rawValue: "scale")
        public static let type = Option(rawValue: "type")
    }

    public struct ShapeType: RawRepresentable, Hashable, Sendable {
        public let rawValue: String
        public init(rawValue: String) { self.rawValue = rawValue }

        public static let boundingBox = ShapeType(rawValue: "boundingBox")
        public static let convexHull = ShapeType(rawValue: "convexHull")
        public static let concavePolyhedron = ShapeType(rawValue: "concavePolyhedron")
    }

    public let sourceObject: Any
    public let options: [SCNPhysicsShape.Option: Any]?
    public let transforms: [NSValue]?

    public convenience init(geometry: SCNGeometry, options: [SCNPhysicsShape.Option: Any]? = nil) {
        self.init(source: geometry, options: options, transforms: nil)
    }

    public convenience init(node: SCNNode, options: [SCNPhysicsShape.Option: Any]? = nil) {
        self.init(source: node, options: options, transforms: nil)
    }

    public convenience init(shapes: [SCNPhysicsShape], transforms: [NSValue]?) {
        self.init(source: shapes, options: nil, transforms: transforms)
    }

    init(source: Any, options: [SCNPhysicsShape.Option: Any]?, transforms: [NSValue]?) {
        self.sourceObject = source
        self.options = options
        self.transforms = transforms
        super.init()
    }

    public required init?(coder: NSCoder) { return nil }
}

public class SCNPhysicsBehavior: NSObject {
    public override init() { super.init() }
    public required init?(coder: NSCoder) { return nil }
}

public final class SCNPhysicsContact: NSObject {
    public let nodeA: SCNNode
    public let nodeB: SCNNode
    public let contactPoint: SCNVector3
    public let contactNormal: SCNVector3
    public let collisionImpulse: CGFloat
    public let penetrationDistance: CGFloat
    public let sweepTestFraction: CGFloat

    init(
        nodeA: SCNNode,
        nodeB: SCNNode,
        contactPoint: SCNVector3,
        contactNormal: SCNVector3,
        collisionImpulse: CGFloat,
        penetrationDistance: CGFloat,
        sweepTestFraction: CGFloat
    ) {
        self.nodeA = nodeA
        self.nodeB = nodeB
        self.contactPoint = contactPoint
        self.contactNormal = contactNormal
        self.collisionImpulse = collisionImpulse
        self.penetrationDistance = penetrationDistance
        self.sweepTestFraction = sweepTestFraction
    }
}

public final class SCNPhysicsField: NSObject {
    public var isActive = true
    public var isExclusive = false
    public var strength: CGFloat = 1
    public var falloffExponent: CGFloat = 0
    public var minimumDistance: CGFloat = 1
    public var direction = SCNVector3(0, -1, 0)
    public var scope = SCNPhysicsFieldScope.insideExtent
    public var halfExtent = SCNVector3(1, 1, 1)
    public var usesEllipsoidalExtent = false
    public var offset = SCNVector3Zero
    public var categoryBitMask = Int.max
    var _kind = "linearGravity"

    public override init() { super.init() }
    public required init?(coder: NSCoder) { return nil }

    public class func drag() -> SCNPhysicsField {
        let field = SCNPhysicsField()
        field._kind = "drag"
        return field
    }

    public class func vortex() -> SCNPhysicsField {
        let field = SCNPhysicsField()
        field._kind = "vortex"
        return field
    }

    public class func radialGravity() -> SCNPhysicsField {
        let field = SCNPhysicsField()
        field._kind = "radialGravity"
        return field
    }

    public class func linearGravity() -> SCNPhysicsField {
        let field = SCNPhysicsField()
        field._kind = "linearGravity"
        return field
    }

    public class func noiseField(smoothness: CGFloat, animationSpeed speed: CGFloat) -> SCNPhysicsField {
        _ = smoothness
        _ = speed
        let field = SCNPhysicsField()
        field._kind = "noise"
        return field
    }

    public class func turbulenceField(smoothness: CGFloat, animationSpeed speed: CGFloat) -> SCNPhysicsField {
        _ = smoothness
        _ = speed
        let field = SCNPhysicsField()
        field._kind = "turbulence"
        return field
    }

    public class func spring() -> SCNPhysicsField {
        let field = SCNPhysicsField()
        field._kind = "spring"
        return field
    }

    public class func electric() -> SCNPhysicsField {
        let field = SCNPhysicsField()
        field._kind = "electric"
        return field
    }

    public class func magnetic() -> SCNPhysicsField {
        let field = SCNPhysicsField()
        field._kind = "magnetic"
        return field
    }

    public class func customField(evaluationBlock block: @escaping SCNFieldForceEvaluator) -> SCNPhysicsField {
        _ = block
        let field = SCNPhysicsField()
        field._kind = "custom"
        return field
    }
}

public final class SCNPhysicsHingeJoint: SCNPhysicsBehavior {
    public var bodyA: SCNPhysicsBody
    public var bodyB: SCNPhysicsBody?
    public var axisA = SCNVector3(0, 1, 0)
    public var axisB = SCNVector3(0, 1, 0)
    public var anchorA = SCNVector3Zero
    public var anchorB = SCNVector3Zero

    public init(bodyA: SCNPhysicsBody, axisA: SCNVector3, anchorA: SCNVector3, bodyB: SCNPhysicsBody?, axisB: SCNVector3, anchorB: SCNVector3) {
        self.bodyA = bodyA
        self.bodyB = bodyB
        self.axisA = axisA
        self.axisB = axisB
        self.anchorA = anchorA
        self.anchorB = anchorB
        super.init()
    }

    public required init?(coder: NSCoder) { return nil }
}

public final class SCNPhysicsBallSocketJoint: SCNPhysicsBehavior {
    public var bodyA: SCNPhysicsBody
    public var bodyB: SCNPhysicsBody?
    public var anchorA = SCNVector3Zero
    public var anchorB = SCNVector3Zero

    public init(bodyA: SCNPhysicsBody, anchorA: SCNVector3, bodyB: SCNPhysicsBody?, anchorB: SCNVector3) {
        self.bodyA = bodyA
        self.bodyB = bodyB
        self.anchorA = anchorA
        self.anchorB = anchorB
        super.init()
    }

    public required init?(coder: NSCoder) { return nil }
}

public final class SCNPhysicsSliderJoint: SCNPhysicsBehavior {
    public var bodyA: SCNPhysicsBody
    public var bodyB: SCNPhysicsBody?
    public var axisA = SCNVector3(1, 0, 0)
    public var axisB = SCNVector3(1, 0, 0)
    public var anchorA = SCNVector3Zero
    public var anchorB = SCNVector3Zero
    public var minimumLinearLimit: CGFloat = -1e6
    public var maximumLinearLimit: CGFloat = 1e6
    public var minimumAngularLimit: CGFloat = -.pi
    public var maximumAngularLimit: CGFloat = .pi
    public var motorTargetLinearVelocity: CGFloat = 0
    public var motorMaximumForce: CGFloat = 0
    public var motorTargetAngularVelocity: CGFloat = 0
    public var motorMaximumTorque: CGFloat = 0

    public init(bodyA: SCNPhysicsBody, axisA: SCNVector3, anchorA: SCNVector3, bodyB: SCNPhysicsBody?, axisB: SCNVector3, anchorB: SCNVector3) {
        self.bodyA = bodyA
        self.bodyB = bodyB
        self.axisA = axisA
        self.axisB = axisB
        self.anchorA = anchorA
        self.anchorB = anchorB
        super.init()
    }

    public required init?(coder: NSCoder) { return nil }
}

public final class SCNPhysicsConeTwistJoint: SCNPhysicsBehavior {
    public var bodyA: SCNPhysicsBody
    public var bodyB: SCNPhysicsBody?
    public var frameA = SCNMatrix4Identity
    public var frameB = SCNMatrix4Identity
    public var maximumAngularLimit1: CGFloat = .pi / 2
    public var maximumAngularLimit2: CGFloat = .pi / 2
    public var maximumTwistAngle: CGFloat = .pi

    public init(bodyA: SCNPhysicsBody, frameA: SCNMatrix4, bodyB: SCNPhysicsBody?, frameB: SCNMatrix4) {
        self.bodyA = bodyA
        self.bodyB = bodyB
        self.frameA = frameA
        self.frameB = frameB
        super.init()
    }

    public required init?(coder: NSCoder) { return nil }
}

public final class SCNPhysicsVehicleWheel: NSObject {
    public var connectionPosition = SCNVector3Zero
    public var axle = SCNVector3(-1, 0, 0)
    public var steeringAxis = SCNVector3(0, 1, 0)
    public var radius: CGFloat = 0.5
    public var suspensionRestLength: CGFloat = 1
    public var suspensionStiffness: CGFloat = 2
    public var suspensionCompression: CGFloat = 4.4
    public var suspensionDamping: CGFloat = 2.3
    public var maximumSuspensionTravel: CGFloat = 500
    public var frictionSlip: CGFloat = 1
    public var maximumSuspensionForce: CGFloat = 6000
    public let node: SCNNode

    public init(node: SCNNode) {
        self.node = node
        super.init()
    }

    public required init?(coder: NSCoder) { return nil }
}

public final class SCNPhysicsVehicle: SCNPhysicsBehavior {
    public var speedInKilometersPerHour: CGFloat { 0 }
    public var wheels: [SCNPhysicsVehicleWheel]
    public var chassisBody: SCNPhysicsBody

    public init(chassisBody: SCNPhysicsBody, wheels: [SCNPhysicsVehicleWheel]) {
        self.chassisBody = chassisBody
        self.wheels = wheels
        super.init()
    }

    public required init?(coder: NSCoder) { return nil }

    public func applyEngineForce(_ value: CGFloat, forWheelAt index: Int) {
        _ = value
        _ = index
    }

    public func applyBrakingForce(_ value: CGFloat, forWheelAt index: Int) {
        _ = value
        _ = index
    }

    public func setSteeringAngle(_ value: CGFloat, forWheelAt index: Int) {
        _ = value
        _ = index
    }
}
