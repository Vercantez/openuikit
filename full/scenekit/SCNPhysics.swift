import Foundation

open class SCNPhysicsShape: NSObject, NSCopying, NSSecureCoding {
    public struct ShapeType: RawRepresentable, Hashable, Sendable {
        public var rawValue: String
        public init(rawValue: String) { self.rawValue = rawValue }
        public static let boundingBox = ShapeType(rawValue: "boundingBox")
        public static let convexHull = ShapeType(rawValue: "convexHull")
        public static let concavePolyhedron = ShapeType(rawValue: "concavePolyhedron")
    }

    public struct Option: RawRepresentable, Hashable, Sendable {
        public var rawValue: String
        public init(rawValue: String) { self.rawValue = rawValue }
        public static let type = Option(rawValue: "type")
        public static let keepAsCompound = Option(rawValue: "keepAsCompound")
        public static let scale = Option(rawValue: "scale")
        public static let collisionMargin = Option(rawValue: "collisionMargin")
    }

    public var sourceObject: Any = ()

    public override init() { super.init() }
    public convenience init(geometry: SCNGeometry, options: [Option: Any]? = nil) {
        self.init()
        sourceObject = geometry
        _ = options
    }
    public convenience init(node: SCNNode, options: [Option: Any]? = nil) {
        self.init()
        sourceObject = node
        _ = options
    }
    public convenience init(shapes: [SCNPhysicsShape], transforms: [NSValue]?) {
        self.init()
        _ = shapes
        _ = transforms
    }

    public func copy(with zone: NSZone? = nil) -> Any { SCNPhysicsShape() }
    public static var supportsSecureCoding: Bool { true }
    public required init?(coder: NSCoder) { return nil }
    public func encode(with coder: NSCoder) {}
}

open class SCNPhysicsBody: NSObject, NSCopying, NSSecureCoding {
    public var type: SCNPhysicsBodyType
    public var physicsShape: SCNPhysicsShape?
    public var mass: CGFloat = 1
    public var charge: CGFloat = 0
    public var friction: CGFloat = 0.5
    public var restitution: CGFloat = 0.5
    public var rollingFriction: CGFloat = 0
    public var damping: CGFloat = 0.1
    public var angularDamping: CGFloat = 0.1
    public var velocity: SCNVector3 = SCNVector3Zero
    public var angularVelocity: SCNVector4 = SCNVector4Zero
    public var velocityFactor: SCNVector3 = SCNVector3(x: 1, y: 1, z: 1)
    public var angularVelocityFactor: SCNVector3 = SCNVector3(x: 1, y: 1, z: 1)
    public var isAffectedByGravity: Bool = true
    public var isResting: Bool = false
    public var allowsResting: Bool = true
    public var categoryBitMask: Int = SCNPhysicsCollisionCategory.default.rawValue
    public var collisionBitMask: Int = SCNPhysicsCollisionCategory.all.rawValue
    public var contactTestBitMask: Int = 0
    public var usesDefaultMomentOfInertia: Bool = true
    public var momentOfInertia: SCNVector3 = SCNVector3(x: 1, y: 1, z: 1)
    public var centerOfMassOffset: SCNVector3 = SCNVector3Zero
    public var linearRestingThreshold: CGFloat = 0
    public var angularRestingThreshold: CGFloat = 0
    public var continuousCollisionDetectionThreshold: CGFloat = 0

    public override init() {
        type = .dynamic
        super.init()
    }

    public convenience init(type: SCNPhysicsBodyType, shape: SCNPhysicsShape?) {
        self.init()
        self.type = type
        self.physicsShape = shape
        if type == .static {
            mass = 0
        }
    }

    open class func `static`() -> SCNPhysicsBody {
        SCNPhysicsBody(type: .static, shape: nil)
    }

    open class func dynamic() -> SCNPhysicsBody {
        SCNPhysicsBody(type: .dynamic, shape: nil)
    }

    open class func kinematic() -> SCNPhysicsBody {
        SCNPhysicsBody(type: .kinematic, shape: nil)
    }

    public func applyForce(_ direction: SCNVector3, asImpulse impulse: Bool) {
        _ = direction
        _ = impulse
    }

    public func applyForce(_ direction: SCNVector3, at position: SCNVector3, asImpulse impulse: Bool) {
        _ = direction
        _ = position
        _ = impulse
    }

    public func applyTorque(_ torque: SCNVector4, asImpulse impulse: Bool) {
        _ = torque
        _ = impulse
    }

    public func clearAllForces() {}
    public func resetTransform() {}
    public func setResting(_ resting: Bool) { isResting = resting }

    public func copy(with zone: NSZone? = nil) -> Any {
        let copy = SCNPhysicsBody(type: type, shape: physicsShape)
        copy.mass = mass
        return copy
    }

    public static var supportsSecureCoding: Bool { true }
    public required init?(coder: NSCoder) { return nil }
    public func encode(with coder: NSCoder) {}
}

open class SCNPhysicsContact: NSObject {
    public private(set) var nodeA: SCNNode
    public private(set) var nodeB: SCNNode
    public private(set) var contactPoint: SCNVector3
    public private(set) var contactNormal: SCNVector3
    public private(set) var collisionImpulse: CGFloat
    public private(set) var penetrationDistance: CGFloat
    public private(set) var sweepTestFraction: CGFloat

    public override init() {
        nodeA = SCNNode()
        nodeB = SCNNode()
        contactPoint = SCNVector3Zero
        contactNormal = SCNVector3(x: 0, y: 1, z: 0)
        collisionImpulse = 0
        penetrationDistance = 0
        sweepTestFraction = 0
        super.init()
    }
}

open class SCNPhysicsBehavior: NSObject, NSSecureCoding {
    public override init() { super.init() }
    public static var supportsSecureCoding: Bool { true }
    public required init?(coder: NSCoder) { return nil }
    public func encode(with coder: NSCoder) {}
}

open class SCNPhysicsHingeJoint: SCNPhysicsBehavior {
    public var bodyA: SCNPhysicsBody
    public var bodyB: SCNPhysicsBody?
    public var axisA: SCNVector3
    public var axisB: SCNVector3
    public var anchorA: SCNVector3
    public var anchorB: SCNVector3

    public init(bodyA: SCNPhysicsBody, axisA: SCNVector3, anchorA: SCNVector3, bodyB: SCNPhysicsBody, axisB: SCNVector3, anchorB: SCNVector3) {
        self.bodyA = bodyA
        self.bodyB = bodyB
        self.axisA = axisA
        self.axisB = axisB
        self.anchorA = anchorA
        self.anchorB = anchorB
        super.init()
    }

    public init(body: SCNPhysicsBody, axis: SCNVector3, anchor: SCNVector3) {
        self.bodyA = body
        self.axisA = axis
        self.anchorA = anchor
        self.axisB = axis
        self.anchorB = anchor
        super.init()
    }

    public required init?(coder: NSCoder) { return nil }
}

open class SCNPhysicsBallSocketJoint: SCNPhysicsBehavior {
    public var bodyA: SCNPhysicsBody
    public var bodyB: SCNPhysicsBody?
    public var anchorA: SCNVector3
    public var anchorB: SCNVector3

    public init(bodyA: SCNPhysicsBody, anchorA: SCNVector3, bodyB: SCNPhysicsBody, anchorB: SCNVector3) {
        self.bodyA = bodyA
        self.bodyB = bodyB
        self.anchorA = anchorA
        self.anchorB = anchorB
        super.init()
    }

    public init(body: SCNPhysicsBody, anchor: SCNVector3) {
        self.bodyA = body
        self.anchorA = anchor
        self.anchorB = anchor
        super.init()
    }

    public required init?(coder: NSCoder) { return nil }
}

open class SCNPhysicsSliderJoint: SCNPhysicsBehavior {
    public var bodyA: SCNPhysicsBody
    public var bodyB: SCNPhysicsBody?
    public var axisA: SCNVector3
    public var axisB: SCNVector3
    public var anchorA: SCNVector3
    public var anchorB: SCNVector3
    public var minimumLinearLimit: CGFloat = 0
    public var maximumLinearLimit: CGFloat = 0
    public var minimumAngularLimit: CGFloat = 0
    public var maximumAngularLimit: CGFloat = 0
    public var motorTargetLinearVelocity: CGFloat = 0
    public var motorMaximumForce: CGFloat = 0
    public var motorTargetAngularVelocity: CGFloat = 0
    public var motorMaximumTorque: CGFloat = 0

    public init(bodyA: SCNPhysicsBody, axisA: SCNVector3, anchorA: SCNVector3, bodyB: SCNPhysicsBody, axisB: SCNVector3, anchorB: SCNVector3) {
        self.bodyA = bodyA
        self.bodyB = bodyB
        self.axisA = axisA
        self.axisB = axisB
        self.anchorA = anchorA
        self.anchorB = anchorB
        super.init()
    }

    public init(body: SCNPhysicsBody, axis: SCNVector3, anchor: SCNVector3) {
        self.bodyA = body
        self.axisA = axis
        self.anchorA = anchor
        self.axisB = axis
        self.anchorB = anchor
        super.init()
    }

    public required init?(coder: NSCoder) { return nil }
}

open class SCNPhysicsConeTwistJoint: SCNPhysicsBehavior {
    public var bodyA: SCNPhysicsBody
    public var bodyB: SCNPhysicsBody?
    public var frameA: SCNMatrix4 = SCNMatrix4Identity
    public var frameB: SCNMatrix4 = SCNMatrix4Identity
    public var maximumAngularLimit1: CGFloat = 0
    public var maximumAngularLimit2: CGFloat = 0
    public var maximumTwistAngle: CGFloat = 0

    public init(bodyA: SCNPhysicsBody, frameA: SCNMatrix4, bodyB: SCNPhysicsBody?, frameB: SCNMatrix4) {
        self.bodyA = bodyA
        self.bodyB = bodyB
        self.frameA = frameA
        self.frameB = frameB
        super.init()
    }

    public required init?(coder: NSCoder) { return nil }
}

open class SCNPhysicsVehicleWheel: NSObject, NSCopying, NSSecureCoding {
    public weak var node: SCNNode?
    public var suspensionRestLength: CGFloat = 0
    public var suspensionDamping: CGFloat = 0
    public var suspensionCompression: CGFloat = 0
    public var suspensionStiffness: CGFloat = 0
    public var radius: CGFloat = 0.5
    public var frictionSlip: CGFloat = 1
    public var maximumSuspensionTravel: CGFloat = 0
    public var maximumSuspensionForce: CGFloat = 0
    public var connectionPosition: SCNVector3 = SCNVector3Zero
    public var steeringAxis: SCNVector3 = SCNVector3(x: 0, y: 1, z: 0)
    public var axle: SCNVector3 = SCNVector3(x: 1, y: 0, z: 0)

    public override init() { super.init() }
    public convenience init(node: SCNNode) {
        self.init()
        self.node = node
    }

    public func copy(with zone: NSZone? = nil) -> Any { SCNPhysicsVehicleWheel() }
    public static var supportsSecureCoding: Bool { true }
    public required init?(coder: NSCoder) { return nil }
    public func encode(with coder: NSCoder) {}
}

open class SCNPhysicsVehicle: SCNPhysicsBehavior {
    public private(set) var chassisBody: SCNPhysicsBody
    public private(set) var wheels: [SCNPhysicsVehicleWheel]
    public var speedInKilometersPerHour: CGFloat { 0 }

    public init(chassisBody: SCNPhysicsBody, wheels: [SCNPhysicsVehicleWheel]) {
        self.chassisBody = chassisBody
        self.wheels = wheels
        super.init()
    }

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

    public required init?(coder: NSCoder) { return nil }
}

open class SCNPhysicsField: NSObject, NSCopying, NSSecureCoding {
    public var strength: CGFloat = 1
    public var falloffExponent: CGFloat = 0
    public var minimumDistance: CGFloat = 0
    public var isActive: Bool = true
    public var isExclusive: Bool = false
    public var halfExtent: SCNVector3 = SCNVector3(x: 1, y: 1, z: 1)
    public var usesEllipsoidalExtent: Bool = false
    public var scope: SCNPhysicsFieldScope = .insideExtent
    public var offset: SCNVector3 = SCNVector3Zero
    public var direction: SCNVector3 = SCNVector3(x: 0, y: -1, z: 0)
    public var categoryBitMask: Int = .max

    public override init() { super.init() }

    open class func drag() -> SCNPhysicsField { SCNPhysicsField() }
    open class func vortex() -> SCNPhysicsField { SCNPhysicsField() }
    open class func radialGravity() -> SCNPhysicsField { SCNPhysicsField() }
    open class func linearGravity() -> SCNPhysicsField { SCNPhysicsField() }
    open class func noiseField(smoothness: CGFloat, animationSpeed speed: CGFloat) -> SCNPhysicsField {
        _ = smoothness
        _ = speed
        return SCNPhysicsField()
    }
    open class func turbulenceField(smoothness: CGFloat, animationSpeed speed: CGFloat) -> SCNPhysicsField {
        _ = smoothness
        _ = speed
        return SCNPhysicsField()
    }
    open class func spring() -> SCNPhysicsField { SCNPhysicsField() }
    open class func electric() -> SCNPhysicsField { SCNPhysicsField() }
    open class func magnetic() -> SCNPhysicsField { SCNPhysicsField() }
    open class func customField(evaluationBlock block: @escaping SCNFieldForceEvaluator) -> SCNPhysicsField {
        _ = block
        return SCNPhysicsField()
    }

    public func copy(with zone: NSZone? = nil) -> Any { SCNPhysicsField() }
    public static var supportsSecureCoding: Bool { true }
    public required init?(coder: NSCoder) { return nil }
    public func encode(with coder: NSCoder) {}
}

open class SCNPhysicsWorld: NSObject, NSSecureCoding {
    public struct TestOption: RawRepresentable, Hashable, Sendable {
        public var rawValue: String
        public init(rawValue: String) { self.rawValue = rawValue }
        public static let collisionBitMask = TestOption(rawValue: "collisionBitMask")
        public static let searchMode = TestOption(rawValue: "searchMode")
        public static let backfaceCulling = TestOption(rawValue: "backfaceCulling")
    }

    public struct TestSearchMode: RawRepresentable, Hashable, Sendable {
        public var rawValue: String
        public init(rawValue: String) { self.rawValue = rawValue }
        public static let any = TestSearchMode(rawValue: "any")
        public static let closest = TestSearchMode(rawValue: "closest")
        public static let all = TestSearchMode(rawValue: "all")
    }

    public var gravity: SCNVector3 = SCNVector3(x: 0, y: -9.8, z: 0)
    public var speed: CGFloat = 1
    public var timeStep: TimeInterval = 1.0 / 60.0
    public weak var contactDelegate: SCNPhysicsContactDelegate?
    var _behaviors: [SCNPhysicsBehavior] = []

    public override init() { super.init() }

    /// Fail-closed: does not invent motion, contacts, or solver results.
    public func step() {}

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

    public var allBehaviors: [SCNPhysicsBehavior] { _behaviors }

    public func rayTestWithSegment(from origin: SCNVector3, to dest: SCNVector3, options: [TestOption: Any]? = nil) -> [SCNHitTestResult] {
        _ = origin
        _ = dest
        _ = options
        return []
    }

    public func contactTestBetween(
        _ bodyA: SCNPhysicsBody,
        _ bodyB: SCNPhysicsBody,
        options: [TestOption: Any]? = nil
    ) -> [SCNPhysicsContact] {
        _ = bodyA
        _ = bodyB
        _ = options
        return []
    }

    public func contactTest(with body: SCNPhysicsBody, options: [TestOption: Any]? = nil) -> [SCNPhysicsContact] {
        _ = body
        _ = options
        return []
    }

    public func convexSweepTest(
        with shape: SCNPhysicsShape,
        from: SCNMatrix4,
        to: SCNMatrix4,
        options: [TestOption: Any]? = nil
    ) -> [SCNPhysicsContact] {
        _ = shape
        _ = from
        _ = to
        _ = options
        return []
    }

    public func updateCollisionPairs() {}

    public static var supportsSecureCoding: Bool { true }
    public required init?(coder: NSCoder) { return nil }
    public func encode(with coder: NSCoder) {}
}
