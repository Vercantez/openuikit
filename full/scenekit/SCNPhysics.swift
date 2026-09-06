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
    public var transforms: [NSValue]?

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
        sourceObject = shapes
        self.transforms = transforms
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
    weak var _node: SCNNode?
    var _force = SCNVector3Zero
    var _torque = SCNVector4Zero
    var _impulse = SCNVector3Zero

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
        if isResting {
            isResting = false
        }
        if impulse {
            let m = max(Float(mass), 1e-6)
            velocity = _scnAdd(velocity, _scnScale(direction, 1 / m))
        } else {
            _force = _scnAdd(_force, direction)
        }
    }

    public func applyForce(_ direction: SCNVector3, at position: SCNVector3, asImpulse impulse: Bool) {
        applyForce(direction, asImpulse: impulse)
        let r = position
        let t = _scnCross(r, direction)
        applyTorque(SCNVector4(x: t.x, y: t.y, z: t.z, w: 0), asImpulse: impulse)
        _ = position
    }

    public func applyTorque(_ torque: SCNVector4, asImpulse impulse: Bool) {
        if isResting {
            isResting = false
        }
        if impulse {
            angularVelocity = SCNVector4(
                x: angularVelocity.x + torque.x,
                y: angularVelocity.y + torque.y,
                z: angularVelocity.z + torque.z,
                w: angularVelocity.w + torque.w
            )
        } else {
            _torque = SCNVector4(
                x: _torque.x + torque.x,
                y: _torque.y + torque.y,
                z: _torque.z + torque.z,
                w: _torque.w + torque.w
            )
        }
    }

    public func clearAllForces() {
        _force = SCNVector3Zero
        _torque = SCNVector4Zero
        _impulse = SCNVector3Zero
    }

    public func resetTransform() {
        velocity = SCNVector3Zero
        angularVelocity = SCNVector4Zero
        clearAllForces()
        isResting = false
    }

    public func setResting(_ resting: Bool) {
        isResting = resting
        if resting {
            velocity = SCNVector3Zero
            angularVelocity = SCNVector4Zero
            clearAllForces()
        }
    }

    var _invMass: Float {
        if type != .dynamic { return 0 }
        let m = Float(mass)
        return m > 0 ? 1 / m : 0
    }

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
    public internal(set) var collisionImpulse: CGFloat
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

    convenience init(
        nodeA: SCNNode,
        nodeB: SCNNode,
        contactPoint: SCNVector3,
        contactNormal: SCNVector3,
        penetrationDistance: CGFloat,
        collisionImpulse: CGFloat
    ) {
        self.init()
        self.nodeA = nodeA
        self.nodeB = nodeB
        self.contactPoint = contactPoint
        self.contactNormal = contactNormal
        self.penetrationDistance = penetrationDistance
        self.collisionImpulse = collisionImpulse
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
    var _engine: [Int: CGFloat] = [:]
    var _brake: [Int: CGFloat] = [:]
    var _steer: [Int: CGFloat] = [:]

    public var speedInKilometersPerHour: CGFloat {
        CGFloat(_scnLength(chassisBody.velocity) * 3.6)
    }

    public init(chassisBody: SCNPhysicsBody, wheels: [SCNPhysicsVehicleWheel]) {
        self.chassisBody = chassisBody
        self.wheels = wheels
        super.init()
    }

    public func applyEngineForce(_ value: CGFloat, forWheelAt index: Int) {
        _engine[index] = value
    }

    public func applyBrakingForce(_ value: CGFloat, forWheelAt index: Int) {
        _brake[index] = value
    }

    public func setSteeringAngle(_ value: CGFloat, forWheelAt index: Int) {
        _steer[index] = value
    }

    func _linuxApply() {
        guard chassisBody.type == .dynamic else { return }
        var total: Float = 0
        for (index, force) in _engine {
            _ = index
            total += Float(force)
        }
        for (index, brake) in _brake {
            _ = index
            total -= Float(brake)
        }
        if let node = chassisBody._node {
            let forward = _scnNormalize(node.worldFront)
            chassisBody.applyForce(_scnScale(forward, total), asImpulse: false)
            if let first = _steer.values.first, let wheel = wheels.first {
                _ = wheel.steeringAxis
                node.eulerAngles.y += Float(first) * 0.01
            }
        }
    }

    public required init?(coder: NSCoder) { return nil }
}

open class SCNPhysicsField: NSObject, NSCopying, NSSecureCoding {
    enum Kind {
        case drag, vortex, radial, linear, spring, noise, turbulence, electric, magnetic, custom
    }

    public var strength: CGFloat = 1
    public var falloffExponent: CGFloat = 0
    public var minimumDistance: CGFloat = 0
    public var isActive: Bool = true
    public var isExclusive: Bool = false
    public var halfExtent: SCNVector3 = SCNVector3(x: 1e6, y: 1e6, z: 1e6)
    public var usesEllipsoidalExtent: Bool = false
    public var scope: SCNPhysicsFieldScope = .insideExtent
    public var offset: SCNVector3 = SCNVector3Zero
    public var direction: SCNVector3 = SCNVector3(x: 0, y: -1, z: 0)
    public var categoryBitMask: Int = .max
    var _kind: Kind = .linear
    var _evaluator: SCNFieldForceEvaluator?
    var _smoothness: CGFloat = 1
    var _animationSpeed: CGFloat = 0
    var _origin = SCNVector3Zero

    public override init() { super.init() }

    open class func drag() -> SCNPhysicsField {
        let field = SCNPhysicsField()
        field._kind = .drag
        return field
    }
    open class func vortex() -> SCNPhysicsField {
        let field = SCNPhysicsField()
        field._kind = .vortex
        return field
    }
    open class func radialGravity() -> SCNPhysicsField {
        let field = SCNPhysicsField()
        field._kind = .radial
        return field
    }
    open class func linearGravity() -> SCNPhysicsField {
        let field = SCNPhysicsField()
        field._kind = .linear
        return field
    }
    open class func noiseField(smoothness: CGFloat, animationSpeed speed: CGFloat) -> SCNPhysicsField {
        let field = SCNPhysicsField()
        field._kind = .noise
        field._smoothness = smoothness
        field._animationSpeed = speed
        return field
    }
    open class func turbulenceField(smoothness: CGFloat, animationSpeed speed: CGFloat) -> SCNPhysicsField {
        let field = SCNPhysicsField()
        field._kind = .turbulence
        field._smoothness = smoothness
        field._animationSpeed = speed
        return field
    }
    open class func spring() -> SCNPhysicsField {
        let field = SCNPhysicsField()
        field._kind = .spring
        return field
    }
    open class func electric() -> SCNPhysicsField {
        let field = SCNPhysicsField()
        field._kind = .electric
        return field
    }
    open class func magnetic() -> SCNPhysicsField {
        let field = SCNPhysicsField()
        field._kind = .magnetic
        return field
    }
    open class func customField(evaluationBlock block: @escaping SCNFieldForceEvaluator) -> SCNPhysicsField {
        let field = SCNPhysicsField()
        field._kind = .custom
        field._evaluator = block
        return field
    }

    /// Linux CPU evaluator. `origin` is the field node's world position.
    public func linux_evaluate(
        position: SCNVector3,
        velocity: SCNVector3,
        mass: Float,
        charge: Float,
        time: TimeInterval,
        origin: SCNVector3
    ) -> SCNVector3 {
        guard isActive else { return SCNVector3Zero }
        _origin = origin
        guard _linuxContains(position) else { return SCNVector3Zero }
        let center = _scnAdd(origin, offset)
        switch _kind {
        case .linear:
            let dir = _scnLength(direction) > 1e-8 ? _scnNormalize(direction) : SCNVector3(0, -1, 0)
            return _scnScale(dir, Float(strength))
        case .radial:
            let delta = _scnSub(position, center)
            let dist = max(_scnLength(delta), Float(minimumDistance), 1e-6)
            let fall = pow(dist, Float(falloffExponent))
            return _scnScale(_scnNormalize(delta), -Float(strength) / max(fall, 1e-6))
        case .drag:
            return _scnScale(velocity, -Float(strength))
        case .vortex:
            let delta = _scnSub(position, center)
            let axis = _scnLength(direction) > 1e-8 ? _scnNormalize(direction) : SCNVector3(0, 1, 0)
            return _scnScale(_scnCross(axis, delta), Float(strength))
        case .spring:
            return _scnScale(_scnSub(center, position), Float(strength))
        case .electric:
            let delta = _scnSub(position, center)
            let dist = max(_scnLength(delta), 1e-6)
            return _scnScale(_scnNormalize(delta), Float(strength) * charge / (dist * dist))
        case .magnetic:
            let axis = _scnLength(direction) > 1e-8 ? _scnNormalize(direction) : SCNVector3(0, 1, 0)
            return _scnScale(_scnCross(velocity, axis), Float(strength) * charge)
        case .noise, .turbulence:
            let t = Float(time * TimeInterval(_animationSpeed))
            let s = Float(max(_smoothness, 0.01))
            let nx = sin(position.x * s + t)
            let ny = cos(position.y * s + t * 1.3)
            let nz = sin(position.z * s + t * 0.7)
            var force = SCNVector3(nx, ny, nz)
            if _kind == .turbulence {
                force = _scnAdd(force, _scnScale(velocity, -0.25))
            }
            return _scnScale(force, Float(strength))
        case .custom:
            return _evaluator?(position, velocity, mass, charge, time) ?? SCNVector3Zero
        }
    }

    func _linuxContains(_ position: SCNVector3) -> Bool {
        let local = _scnSub(position, _scnAdd(_origin, offset))
        let hx = max(abs(halfExtent.x), 1e-6)
        let hy = max(abs(halfExtent.y), 1e-6)
        let hz = max(abs(halfExtent.z), 1e-6)
        let inside: Bool
        if usesEllipsoidalExtent {
            let nx = local.x / hx
            let ny = local.y / hy
            let nz = local.z / hz
            inside = nx * nx + ny * ny + nz * nz <= 1
        } else {
            inside = abs(local.x) <= hx && abs(local.y) <= hy && abs(local.z) <= hz
        }
        return scope == .insideExtent ? inside : !inside
    }

    public func copy(with zone: NSZone? = nil) -> Any {
        let copy = SCNPhysicsField()
        copy.strength = strength
        copy.direction = direction
        copy._kind = _kind
        return copy
    }
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
    weak var _root: SCNNode?
    var _accumulator: TimeInterval = 0
    var _livePairs: Set<String> = []

    public override init() { super.init() }

    /// One fixed-dt integration using `timeStep * speed`. Linux CPU solver
    /// (semi-implicit Euler, sphere/sphere and box AABB contacts). Not claimed
    /// Apple-identical.
    public func step() {
        _linuxIntegrate(dt: timeStep * TimeInterval(speed))
    }

    func _linuxStep(_ dt: TimeInterval) {
        let scaled = dt * TimeInterval(speed)
        if timeStep <= 0 {
            _linuxIntegrate(dt: scaled)
            return
        }
        _accumulator += scaled
        var guardCount = 0
        while _accumulator + 1e-12 >= timeStep && guardCount < 32 {
            _linuxIntegrate(dt: timeStep)
            _accumulator -= timeStep
            guardCount += 1
        }
    }

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
        _ = options
        guard let root = _root else { return [] }
        return _scnHitTestSegment(root: root, from: origin, to: dest, options: [:], spaceNode: nil)
    }

    public func contactTestBetween(
        _ bodyA: SCNPhysicsBody,
        _ bodyB: SCNPhysicsBody,
        options: [TestOption: Any]? = nil
    ) -> [SCNPhysicsContact] {
        _ = options
        if let contact = _scnContact(bodyA, bodyB) {
            return [contact]
        }
        return []
    }

    public func contactTest(with body: SCNPhysicsBody, options: [TestOption: Any]? = nil) -> [SCNPhysicsContact] {
        _ = options
        var results: [SCNPhysicsContact] = []
        for other in _bodies() where other !== body {
            if let contact = _scnContact(body, other) {
                results.append(contact)
            }
        }
        return results
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
        // Fail-closed: no GJK/EPA convex sweep on this Linux host.
        return []
    }

    public func updateCollisionPairs() {
        _ = _collectContacts()
    }

    public static var supportsSecureCoding: Bool { true }
    public required init?(coder: NSCoder) { return nil }
    public func encode(with coder: NSCoder) {}

    private func _bodies() -> [SCNPhysicsBody] {
        var bodies: [SCNPhysicsBody] = []
        _root?.enumerateHierarchy { node, _ in
            if let body = node.physicsBody {
                body._node = node
                bodies.append(body)
            }
        }
        return bodies
    }

    private func _linuxIntegrate(dt: TimeInterval) {
        guard dt > 0, _root != nil else { return }
        let bodies = _bodies()
        let h = Float(dt)
        for behavior in _behaviors {
            (behavior as? SCNPhysicsVehicle)?._linuxApply()
            _linuxApplySlider(behavior, dt: h)
        }
        let fields = _linuxCollectFields()
        for body in bodies {
            guard let node = body._node else { continue }
            defer {
                body._force = SCNVector3Zero
                body._torque = SCNVector4Zero
            }
            if body.type != .dynamic || body.isResting { continue }
            let inv = body._invMass
            if inv <= 0 { continue }
            var force = body._force
            if body.isAffectedByGravity {
                force = _scnAdd(force, _scnScale(gravity, Float(body.mass)))
            }
            force = _scnAdd(force, _linuxFieldForce(on: body, node: node, fields: fields, dt: dt))
            var v = body.velocity
            v = _scnAdd(v, _scnScale(force, inv * h))
            v = SCNVector3(
                x: v.x * body.velocityFactor.x,
                y: v.y * body.velocityFactor.y,
                z: v.z * body.velocityFactor.z
            )
            let damp = max(0, min(1, 1 - Float(body.damping) * h))
            v = _scnScale(v, damp)
            body.velocity = v
            node.worldPosition = _scnAdd(node.worldPosition, _scnScale(v, h))
        }
        _resolveContacts(bodies, dt: h)
    }

    private func _linuxCollectFields() -> [(SCNPhysicsField, SCNVector3)] {
        var fields: [(SCNPhysicsField, SCNVector3)] = []
        _root?.enumerateHierarchy { node, _ in
            if let field = node.physicsField, field.isActive {
                fields.append((field, node.worldPosition))
            }
        }
        return fields
    }

    private func _linuxFieldForce(
        on body: SCNPhysicsBody,
        node: SCNNode,
        fields: [(SCNPhysicsField, SCNVector3)],
        dt: TimeInterval
    ) -> SCNVector3 {
        _ = dt
        var exclusive: [(SCNPhysicsField, SCNVector3)] = []
        for (field, origin) in fields {
            field._origin = origin
            if field.isExclusive && field._linuxContains(node.worldPosition) {
                exclusive.append((field, origin))
            }
        }
        let applicable = exclusive.isEmpty ? fields : exclusive
        var force = SCNVector3Zero
        for (field, origin) in applicable {
            if (field.categoryBitMask & node.categoryBitMask) == 0 { continue }
            let f = field.linux_evaluate(
                position: node.worldPosition,
                velocity: body.velocity,
                mass: Float(body.mass),
                charge: Float(body.charge),
                time: 0,
                origin: origin
            )
            force = _scnAdd(force, f)
        }
        return force
    }

    private func _linuxApplySlider(_ behavior: SCNPhysicsBehavior, dt: Float) {
        guard let slider = behavior as? SCNPhysicsSliderJoint else { return }
        guard slider.bodyA.type == .dynamic else { return }
        let axis = _scnLength(slider.axisA) > 1e-8 ? _scnNormalize(slider.axisA) : SCNVector3(0, 1, 0)
        if slider.motorMaximumForce > 0 && abs(slider.motorTargetLinearVelocity) > 0 {
            let force = min(Float(slider.motorMaximumForce), abs(Float(slider.motorTargetLinearVelocity)) * 10)
            let signed = slider.motorTargetLinearVelocity >= 0 ? force : -force
            slider.bodyA.applyForce(_scnScale(axis, signed), asImpulse: false)
        }
        if let node = slider.bodyA._node {
            let rel = _scnDot(_scnSub(node.worldPosition, slider.anchorA), axis)
            if slider.maximumLinearLimit > slider.minimumLinearLimit {
                if rel > Float(slider.maximumLinearLimit) {
                    node.worldPosition = _scnAdd(slider.anchorA, _scnScale(axis, Float(slider.maximumLinearLimit)))
                    slider.bodyA.velocity = SCNVector3Zero
                } else if rel < Float(slider.minimumLinearLimit) {
                    node.worldPosition = _scnAdd(slider.anchorA, _scnScale(axis, Float(slider.minimumLinearLimit)))
                    slider.bodyA.velocity = SCNVector3Zero
                }
            }
        }
        _ = dt
        _ = slider.motorMaximumTorque
        _ = slider.motorTargetAngularVelocity
        _ = slider.minimumAngularLimit
        _ = slider.maximumAngularLimit
    }

    private func _collectContacts() -> [SCNPhysicsContact] {
        let bodies = _bodies()
        var contacts: [SCNPhysicsContact] = []
        if bodies.count < 2 { return contacts }
        for i in 0..<bodies.count {
            for j in (i + 1)..<bodies.count {
                if let contact = _scnContact(bodies[i], bodies[j]) {
                    contacts.append(contact)
                }
            }
        }
        return contacts
    }

    private func _resolveContacts(_ bodies: [SCNPhysicsBody], dt: Float) {
        var now: Set<String> = []
        if bodies.count < 2 {
            _finishContacts(now: now)
            return
        }
        for i in 0..<bodies.count {
            for j in (i + 1)..<bodies.count {
                let a = bodies[i]
                let b = bodies[j]
                if !_scnCollisionMasksMatch(a, b) { continue }
                guard let contact = _scnContact(a, b),
                      let nodeA = a._node,
                      let nodeB = b._node else { continue }
                let key = _scnPairKey(a, b)
                now.insert(key)
                let n = contact.contactNormal
                let overlap = Float(contact.penetrationDistance)
                let invA = a._invMass
                let invB = b._invMass
                let sum = invA + invB
                if sum > 0 && overlap > 0 {
                    let corr = overlap / sum
                    if invA > 0 {
                        nodeA.worldPosition = _scnSub(nodeA.worldPosition, _scnScale(n, corr * invA))
                    }
                    if invB > 0 {
                        nodeB.worldPosition = _scnAdd(nodeB.worldPosition, _scnScale(n, corr * invB))
                    }
                    let rel = _scnSub(b.velocity, a.velocity)
                    let relN = _scnDot(rel, n)
                    if relN < 0 {
                        let e = min(Float(a.restitution), Float(b.restitution))
                        let j = -(1 + e) * relN / sum
                        if invA > 0 {
                            a.velocity = _scnSub(a.velocity, _scnScale(n, j * invA))
                        }
                        if invB > 0 {
                            b.velocity = _scnAdd(b.velocity, _scnScale(n, j * invB))
                        }
                        contact.collisionImpulse = CGFloat(abs(j))
                    }
                }
                let notify = (a.contactTestBitMask & b.categoryBitMask) != 0
                    || (b.contactTestBitMask & a.categoryBitMask) != 0
                    || a.contactTestBitMask == 0 && b.contactTestBitMask == 0
                if notify {
                    if _livePairs.contains(key) {
                        contactDelegate?.physicsWorld(self, didUpdate: contact)
                    } else {
                        contactDelegate?.physicsWorld(self, didBegin: contact)
                    }
                }
                _ = dt
            }
        }
        _finishContacts(now: now)
    }

    private func _finishContacts(now: Set<String>) {
        let ended = _livePairs.subtracting(now)
        if !ended.isEmpty {
            let dummy = SCNPhysicsContact()
            for _ in ended {
                contactDelegate?.physicsWorld(self, didEnd: dummy)
            }
        }
        _livePairs = now
    }
}

func _scnPairKey(_ a: SCNPhysicsBody, _ b: SCNPhysicsBody) -> String {
    let ia = ObjectIdentifier(a)
    let ib = ObjectIdentifier(b)
    return ia < ib ? "\(ia)-\(ib)" : "\(ib)-\(ia)"
}

func _scnCollisionMasksMatch(_ a: SCNPhysicsBody, _ b: SCNPhysicsBody) -> Bool {
    let aHits = (a.collisionBitMask & b.categoryBitMask) != 0
    let bHits = (b.collisionBitMask & a.categoryBitMask) != 0
    return aHits || bHits
}

enum _SCNCollider {
    case sphere(center: SCNVector3, radius: Float)
    case box(min: SCNVector3, max: SCNVector3)
}

func _scnCollider(for body: SCNPhysicsBody) -> _SCNCollider? {
    guard let node = body._node else { return nil }
    let source: Any? = body.physicsShape?.sourceObject ?? node.geometry
    let pos = node.worldPosition
    let sx = abs(node.scale.x)
    let sy = abs(node.scale.y)
    let sz = abs(node.scale.z)
    if let sphere = source as? SCNSphere {
        let r = Float(sphere.radius) * max(sx, max(sy, sz))
        return .sphere(center: pos, radius: max(r, 1e-6))
    }
    if let box = source as? SCNBox {
        let hx = Float(box.width) * 0.5 * sx
        let hy = Float(box.height) * 0.5 * sy
        let hz = Float(box.length) * 0.5 * sz
        return .box(
            min: SCNVector3(pos.x - hx, pos.y - hy, pos.z - hz),
            max: SCNVector3(pos.x + hx, pos.y + hy, pos.z + hz)
        )
    }
    if let geometry = source as? SCNGeometry {
        let bb = geometry.boundingBox
        let corners = [
            SCNVector3(bb.min.x, bb.min.y, bb.min.z), SCNVector3(bb.max.x, bb.min.y, bb.min.z),
            SCNVector3(bb.min.x, bb.max.y, bb.min.z), SCNVector3(bb.max.x, bb.max.y, bb.min.z),
            SCNVector3(bb.min.x, bb.min.y, bb.max.z), SCNVector3(bb.max.x, bb.min.y, bb.max.z),
            SCNVector3(bb.min.x, bb.max.y, bb.max.z), SCNVector3(bb.max.x, bb.max.y, bb.max.z)
        ].map { _scnTransformPoint(node.worldTransform, $0) }
        let b = _scnBounds(corners)
        return .box(min: b.0, max: b.1)
    }
    return .sphere(center: pos, radius: 0.5 * max(sx, max(sy, sz)))
}

func _scnContact(_ bodyA: SCNPhysicsBody, _ bodyB: SCNPhysicsBody) -> SCNPhysicsContact? {
    guard let nodeA = bodyA._node, let nodeB = bodyB._node else { return nil }
    guard let ca = _scnCollider(for: bodyA), let cb = _scnCollider(for: bodyB) else { return nil }
    switch (ca, cb) {
    case (.sphere(let pa, let ra), .sphere(let pb, let rb)):
        let delta = _scnSub(pb, pa)
        let dist = _scnLength(delta)
        let overlap = ra + rb - dist
        if overlap <= 0 { return nil }
        let n = dist > 1e-8 ? _scnScale(delta, 1 / dist) : SCNVector3(0, 1, 0)
        let point = _scnAdd(pa, _scnScale(n, ra - overlap * 0.5))
        return SCNPhysicsContact(
            nodeA: nodeA, nodeB: nodeB, contactPoint: point, contactNormal: n,
            penetrationDistance: CGFloat(overlap), collisionImpulse: 0
        )
    case (.box(let minA, let maxA), .box(let minB, let maxB)):
        let overlapX = min(maxA.x, maxB.x) - max(minA.x, minB.x)
        let overlapY = min(maxA.y, maxB.y) - max(minA.y, minB.y)
        let overlapZ = min(maxA.z, maxB.z) - max(minA.z, minB.z)
        if overlapX <= 0 || overlapY <= 0 || overlapZ <= 0 { return nil }
        var n = SCNVector3(0, 1, 0)
        var overlap = overlapY
        if overlapX <= overlapY && overlapX <= overlapZ {
            overlap = overlapX
            n = SCNVector3(nodeA.worldPosition.x <= nodeB.worldPosition.x ? 1 : -1, 0, 0)
        } else if overlapZ <= overlapX && overlapZ <= overlapY {
            overlap = overlapZ
            n = SCNVector3(0, 0, nodeA.worldPosition.z <= nodeB.worldPosition.z ? 1 : -1)
        } else {
            n = SCNVector3(0, nodeA.worldPosition.y <= nodeB.worldPosition.y ? 1 : -1, 0)
        }
        let point = SCNVector3(
            x: (max(minA.x, minB.x) + min(maxA.x, maxB.x)) * 0.5,
            y: (max(minA.y, minB.y) + min(maxA.y, maxB.y)) * 0.5,
            z: (max(minA.z, minB.z) + min(maxA.z, maxB.z)) * 0.5
        )
        return SCNPhysicsContact(
            nodeA: nodeA, nodeB: nodeB, contactPoint: point, contactNormal: n,
            penetrationDistance: CGFloat(overlap), collisionImpulse: 0
        )
    case (.sphere(let p, let r), .box(let mn, let mx)),
         (.box(let mn, let mx), .sphere(let p, let r)):
        let closest = SCNVector3(
            x: min(max(p.x, mn.x), mx.x),
            y: min(max(p.y, mn.y), mx.y),
            z: min(max(p.z, mn.z), mx.z)
        )
        let delta = _scnSub(p, closest)
        let dist = _scnLength(delta)
        let overlap = r - dist
        if overlap <= 0 && dist > 0 { return nil }
        if dist == 0 {
            // Center is inside the box: push out along the smallest axis.
            let dx = min(p.x - mn.x, mx.x - p.x)
            let dy = min(p.y - mn.y, mx.y - p.y)
            let dz = min(p.z - mn.z, mx.z - p.z)
            var n = SCNVector3(0, 1, 0)
            var extra = dy
            if dx <= dy && dx <= dz {
                n = SCNVector3(p.x <= (mn.x + mx.x) * 0.5 ? -1 : 1, 0, 0)
                extra = dx
            } else if dz <= dx && dz <= dy {
                n = SCNVector3(0, 0, p.z <= (mn.z + mx.z) * 0.5 ? -1 : 1)
                extra = dz
            } else {
                n = SCNVector3(0, p.y <= (mn.y + mx.y) * 0.5 ? -1 : 1, 0)
            }
            let sphereIsA: Bool
            if case .sphere = ca { sphereIsA = true } else { sphereIsA = false }
            let normal = sphereIsA ? _scnScale(n, -1) : n
            return SCNPhysicsContact(
                nodeA: nodeA, nodeB: nodeB, contactPoint: closest, contactNormal: normal,
                penetrationDistance: CGFloat(r + extra), collisionImpulse: 0
            )
        }
        let n = _scnScale(delta, 1 / dist)
        let sphereIsA: Bool
        if case .sphere = ca { sphereIsA = true } else { sphereIsA = false }
        let normal = sphereIsA ? _scnScale(n, -1) : n
        return SCNPhysicsContact(
            nodeA: nodeA, nodeB: nodeB, contactPoint: closest, contactNormal: normal,
            penetrationDistance: CGFloat(overlap), collisionImpulse: 0
        )
    }
}

