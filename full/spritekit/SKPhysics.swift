import Foundation

public protocol SKPhysicsContactDelegate: NSObjectProtocol {
    func didBegin(_ contact: SKPhysicsContact)
    func didEnd(_ contact: SKPhysicsContact)
}

public extension SKPhysicsContactDelegate {
    func didBegin(_ contact: SKPhysicsContact) {}
    func didEnd(_ contact: SKPhysicsContact) {}
}

enum _SKPhysicsShape {
    case circle(radius: CGFloat, center: CGPoint)
    case rectangle(size: CGSize, center: CGPoint)
    case edge(from: CGPoint, to: CGPoint)
    case edgeLoop(CGRect)
    case compound
}

open class SKPhysicsBody: NSObject, NSCopying, NSSecureCoding {
    public var isDynamic: Bool = true
    public var affectedByGravity: Bool = true
    public var allowsRotation: Bool = true
    public var pinned: Bool = false
    public var isResting: Bool = false
    public var usesPreciseCollisionDetection: Bool = false
    public var friction: CGFloat = 0.2
    public var restitution: CGFloat = 0.2
    public var linearDamping: CGFloat = 0.1
    public var angularDamping: CGFloat = 0.1
    public var density: CGFloat {
        get { _density }
        set {
            _density = max(0, newValue)
            _mass = _density * max(area, 0.0001)
        }
    }
    public var mass: CGFloat {
        get { _mass }
        set {
            _mass = max(0, newValue)
            if area > 0 {
                _density = _mass / area
            }
        }
    }
    public var area: CGFloat = 1
    var _mass: CGFloat = 1
    var _density: CGFloat = 1
    public var charge: CGFloat = 0
    public var velocity: CGVector = CGVector()
    public var angularVelocity: CGFloat = 0
    public var categoryBitMask: UInt32 = 0xFFFF_FFFF
    public var collisionBitMask: UInt32 = 0xFFFF_FFFF
    public var contactTestBitMask: UInt32 = 0
    public var fieldBitMask: UInt32 = 0xFFFF_FFFF
    public var joints: [SKPhysicsJoint] = []
    weak var _node: SKNode?
    var shape: _SKPhysicsShape = .rectangle(size: CGSize(width: 1, height: 1), center: .zero)

    public var node: SKNode? { _node }

    public override init() { super.init() }

    public convenience init(circleOfRadius r: CGFloat) {
        self.init(circleOfRadius: r, center: .zero)
    }

    public convenience init(circleOfRadius r: CGFloat, center: CGPoint) {
        self.init()
        shape = .circle(radius: r, center: center)
        area = .pi * r * r
        _density = 1
        _mass = _density * max(area, 0.0001)
    }

    public convenience init(rectangleOf s: CGSize) {
        self.init(rectangleOf: s, center: .zero)
    }

    public convenience init(rectangleOfSize s: CGSize) {
        self.init(rectangleOf: s)
    }

    public convenience init(rectangleOf s: CGSize, center: CGPoint) {
        self.init()
        shape = .rectangle(size: s, center: center)
        area = abs(s.width * s.height)
        _density = 1
        _mass = _density * max(area, 0.0001)
    }

    public convenience init(rectangleOfSize s: CGSize, center: CGPoint) {
        self.init(rectangleOf: s, center: center)
    }

    public convenience init(edgeFrom p1: CGPoint, to p2: CGPoint) {
        self.init()
        shape = .edge(from: p1, to: p2)
        isDynamic = false
        area = 0
    }

    public convenience init(edgeFromPoint p1: CGPoint, toPoint p2: CGPoint) {
        self.init(edgeFrom: p1, to: p2)
    }

    public convenience init(edgeLoopFrom rect: CGRect) {
        self.init()
        shape = .edgeLoop(rect)
        isDynamic = false
        area = 0
    }

    public convenience init(edgeLoopFromRect rect: CGRect) {
        self.init(edgeLoopFrom: rect)
    }

    public convenience init(edgeLoopFrom path: CGPath) {
        self.init(edgeLoopFrom: path.boundingBox)
    }

    public convenience init(edgeLoopFromPath path: CGPath) {
        self.init(edgeLoopFrom: path)
    }

    public convenience init(edgeChainFrom path: CGPath) {
        self.init(edgeLoopFrom: path)
    }

    public convenience init(edgeChainFromPath path: CGPath) {
        self.init(edgeChainFrom: path)
    }

    public convenience init(polygonFrom path: CGPath) {
        self.init(rectangleOf: path.boundingBox.size)
    }

    public convenience init(polygonFromPath path: CGPath) {
        self.init(polygonFrom: path)
    }

    public convenience init(texture: SKTexture, size: CGSize) {
        self.init(rectangleOf: size)
        _ = texture
    }

    public convenience init(texture: SKTexture, alphaThreshold: Float, size: CGSize) {
        _ = alphaThreshold
        self.init(texture: texture, size: size)
    }

    public convenience init(bodies: [SKPhysicsBody]) {
        self.init()
        shape = .compound
        area = bodies.reduce(0) { $0 + $1.area }
        _mass = bodies.reduce(0) { $0 + $1.mass }
        _density = area > 0 ? _mass / area : 0
    }

    public required init?(coder: NSCoder) {
        _mass = CGFloat(coder.decodeDouble(forKey: "mass"))
        super.init()
    }

    public func encode(with coder: NSCoder) {
        coder.encode(Double(mass), forKey: "mass")
    }

    public static var supportsSecureCoding: Bool { true }

    public func copy(with zone: NSZone? = nil) -> Any {
        let copy = SKPhysicsBody()
        copy.isDynamic = isDynamic
        copy._mass = _mass
        copy._density = _density
        copy.area = area
        copy.velocity = velocity
        copy.shape = shape
        copy.categoryBitMask = categoryBitMask
        copy.collisionBitMask = collisionBitMask
        copy.contactTestBitMask = contactTestBitMask
        return copy
    }

    public func applyForce(_ force: CGVector) {
        guard isDynamic, mass > 0 else { return }
        velocity.dx += force.dx / mass
        velocity.dy += force.dy / mass
    }

    public func applyForce(_ force: CGVector, at point: CGPoint) {
        _ = point
        applyForce(force)
    }

    public func applyImpulse(_ impulse: CGVector) {
        applyForce(impulse)
    }

    public func applyImpulse(_ impulse: CGVector, at point: CGPoint) {
        applyForce(impulse, at: point)
    }

    public func applyTorque(_ torque: CGFloat) {
        guard isDynamic, allowsRotation else { return }
        angularVelocity += torque
    }

    public func applyAngularImpulse(_ impulse: CGFloat) {
        applyTorque(impulse)
    }

    public func allContactedBodies() -> [SKPhysicsBody] {
        guard let world = _node?.scene?.physicsWorld else { return [] }
        return world._contacts(involving: self).compactMap { contact in
            contact.bodyA === self ? contact.bodyB : contact.bodyA
        }
    }

    func _radius() -> CGFloat? {
        if case .circle(let radius, _) = shape { return radius }
        return nil
    }

    func _overlaps(_ other: SKPhysicsBody) -> Bool {
        if let radiusA = _radius(), let radiusB = other._radius() {
            let a = _node?.position ?? .zero
            let b = other._node?.position ?? .zero
            let dx = b.x - a.x
            let dy = b.y - a.y
            let limit = radiusA + radiusB
            return dx * dx + dy * dy <= limit * limit
        }
        return _aabb().intersects(other._aabb())
    }

    func _aabb() -> CGRect {
        let origin = _node?.position ?? .zero
        switch shape {
        case .circle(let radius, let center):
            return CGRect(
                x: origin.x + center.x - radius,
                y: origin.y + center.y - radius,
                width: radius * 2,
                height: radius * 2
            )
        case .rectangle(let size, let center):
            return CGRect(
                x: origin.x + center.x - size.width / 2,
                y: origin.y + center.y - size.height / 2,
                width: size.width,
                height: size.height
            )
        case .edge(let a, let b):
            return CGRect(
                x: min(origin.x + a.x, origin.x + b.x),
                y: min(origin.y + a.y, origin.y + b.y),
                width: abs(a.x - b.x),
                height: abs(a.y - b.y)
            )
        case .edgeLoop(let rect):
            return rect.offsetBy(dx: origin.x, dy: origin.y)
        case .compound:
            return CGRect(x: origin.x - 0.5, y: origin.y - 0.5, width: 1, height: 1)
        }
    }
}

open class SKPhysicsContact: NSObject {
    public let bodyA: SKPhysicsBody
    public let bodyB: SKPhysicsBody
    public let contactPoint: CGPoint
    public let contactNormal: CGVector
    public let collisionImpulse: CGFloat

    init(bodyA: SKPhysicsBody, bodyB: SKPhysicsBody, point: CGPoint, normal: CGVector, impulse: CGFloat) {
        self.bodyA = bodyA
        self.bodyB = bodyB
        self.contactPoint = point
        self.contactNormal = normal
        self.collisionImpulse = impulse
        super.init()
    }
}

open class SKPhysicsWorld: NSObject, NSSecureCoding {
    public var gravity: CGVector = CGVector(dx: 0, dy: -9.8)
    public var speed: CGFloat = 1
    public weak var contactDelegate: (any SKPhysicsContactDelegate)?
    weak var _scene: SKScene?
    var _joints: [SKPhysicsJoint] = []
    var _activeContacts: [SKPhysicsContact] = []

    public override init() { super.init() }
    public required init?(coder: NSCoder) { super.init() }
    public func encode(with coder: NSCoder) {}
    public static var supportsSecureCoding: Bool { true }

    public func add(_ joint: SKPhysicsJoint) {
        _joints.append(joint)
        joint.bodyA.joints.append(joint)
        joint.bodyB.joints.append(joint)
    }

    public func remove(_ joint: SKPhysicsJoint) {
        _joints.removeAll { $0 === joint }
        joint.bodyA.joints.removeAll { $0 === joint }
        joint.bodyB.joints.removeAll { $0 === joint }
    }

    public func removeAllJoints() {
        for joint in _joints {
            joint.bodyA.joints.removeAll { $0 === joint }
            joint.bodyB.joints.removeAll { $0 === joint }
        }
        _joints.removeAll()
    }

    public func body(at point: CGPoint) -> SKPhysicsBody? {
        _bodies().first { $0._aabb().contains(point) }
    }

    public func body(in rect: CGRect) -> SKPhysicsBody? {
        _bodies().first { $0._aabb().intersects(rect) }
    }

    public func body(alongRayStart start: CGPoint, end: CGPoint) -> SKPhysicsBody? {
        let box = CGRect(
            x: min(start.x, end.x),
            y: min(start.y, end.y),
            width: abs(end.x - start.x),
            height: abs(end.y - start.y)
        )
        return body(in: box)
    }

    public func enumerateBodies(
        at point: CGPoint,
        using block: @escaping (SKPhysicsBody, UnsafeMutablePointer<ObjCBool>) -> Void
    ) {
        var stop = ObjCBool(false)
        for body in _bodies() where body._aabb().contains(point) {
            block(body, &stop)
            if stop.boolValue { break }
        }
    }

    public func enumerateBodies(
        in rect: CGRect,
        using block: @escaping (SKPhysicsBody, UnsafeMutablePointer<ObjCBool>) -> Void
    ) {
        var stop = ObjCBool(false)
        for body in _bodies() where body._aabb().intersects(rect) {
            block(body, &stop)
            if stop.boolValue { break }
        }
    }

    public func enumerateBodies(
        alongRayStart start: CGPoint,
        end: CGPoint,
        using block: @escaping (SKPhysicsBody, CGPoint, CGVector, UnsafeMutablePointer<ObjCBool>) -> Void
    ) {
        var stop = ObjCBool(false)
        if let body = body(alongRayStart: start, end: end) {
            block(body, start, CGVector(dx: 0, dy: 1), &stop)
        }
    }

    public func sampleFields(at position: vector_float3) -> vector_float3 {
        guard let scene = _scene else { return SIMD3<Float>(0, 0, 0) }
        var acc = SIMD3<Float>(0, 0, 0)
        func walk(_ node: SKNode) {
            if let field = node as? SKFieldNode, field.isEnabled {
                acc += field._evaluate(at: position)
            }
            for child in node.children { walk(child) }
        }
        walk(scene)
        return acc
    }

    func _bodies() -> [SKPhysicsBody] {
        guard let scene = _scene else { return [] }
        var bodies: [SKPhysicsBody] = []
        func walk(_ node: SKNode) {
            if let body = node.physicsBody {
                bodies.append(body)
            }
            for child in node.children { walk(child) }
        }
        walk(scene)
        return bodies
    }

    func _contacts(involving body: SKPhysicsBody) -> [SKPhysicsContact] {
        _activeContacts.filter { $0.bodyA === body || $0.bodyB === body }
    }

    func _step(dt: TimeInterval) {
        guard dt > 0 else { return }
        let bodies = _bodies()
        for body in bodies where body.isDynamic && !body.pinned {
            if body.affectedByGravity {
                body.velocity.dx += gravity.dx * CGFloat(dt)
                body.velocity.dy += gravity.dy * CGFloat(dt)
            }
            body.velocity.dx *= max(0, 1 - body.linearDamping * CGFloat(dt))
            body.velocity.dy *= max(0, 1 - body.linearDamping * CGFloat(dt))
            if let node = body.node {
                node.position.x += body.velocity.dx * CGFloat(dt)
                node.position.y += body.velocity.dy * CGFloat(dt)
                if body.allowsRotation {
                    body.angularVelocity *= max(0, 1 - body.angularDamping * CGFloat(dt))
                    node.zRotation += body.angularVelocity * CGFloat(dt)
                }
            }
        }
        var next: [SKPhysicsContact] = []
        for i in 0..<bodies.count {
            for j in (i + 1)..<bodies.count {
                let a = bodies[i]
                let b = bodies[j]
                let mask = (a.categoryBitMask & b.contactTestBitMask) | (b.categoryBitMask & a.contactTestBitMask)
                let collide = (a.categoryBitMask & b.collisionBitMask) != 0 && (b.categoryBitMask & a.collisionBitMask) != 0
                guard a._overlaps(b) else { continue }
                let point = CGPoint(
                    x: (a._aabb().midX + b._aabb().midX) / 2,
                    y: (a._aabb().midY + b._aabb().midY) / 2
                )
                var normal = CGVector(dx: 0, dy: 1)
                if let radiusA = a._radius(), let radiusB = b._radius() {
                    let dx = (b.node?.position.x ?? 0) - (a.node?.position.x ?? 0)
                    let dy = (b.node?.position.y ?? 0) - (a.node?.position.y ?? 0)
                    let dist = sk_hypot(dx, dy)
                    if dist > 0 {
                        normal = CGVector(dx: dx / dist, dy: dy / dist)
                    }
                    if collide, a.isDynamic || b.isDynamic {
                        let overlap = radiusA + radiusB - dist
                        let push = overlap / 2
                        if dist > 0 {
                            if a.isDynamic {
                                a.node?.position.x -= normal.dx * push
                                a.node?.position.y -= normal.dy * push
                            }
                            if b.isDynamic {
                                b.node?.position.x += normal.dx * push
                                b.node?.position.y += normal.dy * push
                            }
                        }
                        let restitution = min(a.restitution, b.restitution)
                        if a.isDynamic {
                            let closing = a.velocity.dx * normal.dx + a.velocity.dy * normal.dy
                            if closing > 0 {
                                a.velocity.dx -= (1 + restitution) * closing * normal.dx
                                a.velocity.dy -= (1 + restitution) * closing * normal.dy
                            }
                        }
                        if b.isDynamic {
                            let closing = b.velocity.dx * (-normal.dx) + b.velocity.dy * (-normal.dy)
                            if closing > 0 {
                                b.velocity.dx += (1 + restitution) * closing * normal.dx
                                b.velocity.dy += (1 + restitution) * closing * normal.dy
                            }
                        }
                    }
                }
                let contact = SKPhysicsContact(
                    bodyA: a,
                    bodyB: b,
                    point: point,
                    normal: normal,
                    impulse: 0
                )
                if mask != 0 {
                    next.append(contact)
                    if !_activeContacts.contains(where: { $0.bodyA === a && $0.bodyB === b }) {
                        contactDelegate?.didBegin(contact)
                    }
                }
                if collide, a._radius() == nil || b._radius() == nil, a.isDynamic || b.isDynamic {
                    let overlapX = min(a._aabb().maxX, b._aabb().maxX) - max(a._aabb().minX, b._aabb().minX)
                    let overlapY = min(a._aabb().maxY, b._aabb().maxY) - max(a._aabb().minY, b._aabb().minY)
                    if overlapX < overlapY {
                        let push = overlapX / 2
                        if a.isDynamic { a.node?.position.x -= push }
                        if b.isDynamic { b.node?.position.x += push }
                    } else {
                        let push = overlapY / 2
                        if a.isDynamic { a.node?.position.y -= push }
                        if b.isDynamic { b.node?.position.y += push }
                    }
                }
            }
        }
        for old in _activeContacts {
            if !next.contains(where: { $0.bodyA === old.bodyA && $0.bodyB === old.bodyB }) {
                contactDelegate?.didEnd(old)
            }
        }
        _activeContacts = next
    }
}

open class SKPhysicsJoint: NSObject, NSSecureCoding {
    public var bodyA: SKPhysicsBody
    public var bodyB: SKPhysicsBody
    public var reactionForce: CGVector = CGVector()
    public var reactionTorque: CGFloat = 0

    public init(bodyA: SKPhysicsBody, bodyB: SKPhysicsBody) {
        self.bodyA = bodyA
        self.bodyB = bodyB
        super.init()
    }

    public required init?(coder: NSCoder) {
        return nil
    }

    public func encode(with coder: NSCoder) {}
    public static var supportsSecureCoding: Bool { true }
}

open class SKPhysicsJointFixed: SKPhysicsJoint {
    public class func joint(withBodyA bodyA: SKPhysicsBody, bodyB: SKPhysicsBody, anchor: CGPoint) -> SKPhysicsJointFixed {
        _ = anchor
        return SKPhysicsJointFixed(bodyA: bodyA, bodyB: bodyB)
    }
}

open class SKPhysicsJointLimit: SKPhysicsJoint {
    public var maxLength: CGFloat = 0
    public class func joint(
        withBodyA bodyA: SKPhysicsBody,
        bodyB: SKPhysicsBody,
        anchorA: CGPoint,
        anchorB: CGPoint
    ) -> SKPhysicsJointLimit {
        _ = anchorA
        _ = anchorB
        return SKPhysicsJointLimit(bodyA: bodyA, bodyB: bodyB)
    }
}

open class SKPhysicsJointPin: SKPhysicsJoint {
    public var frictionTorque: CGFloat = 0
    public var lowerAngleLimit: CGFloat = 0
    public var upperAngleLimit: CGFloat = 0
    public var rotationSpeed: CGFloat = 0
    public var shouldEnableLimits: Bool = false
    public class func joint(withBodyA bodyA: SKPhysicsBody, bodyB: SKPhysicsBody, anchor: CGPoint) -> SKPhysicsJointPin {
        _ = anchor
        return SKPhysicsJointPin(bodyA: bodyA, bodyB: bodyB)
    }
}

open class SKPhysicsJointSliding: SKPhysicsJoint {
    public var lowerDistanceLimit: CGFloat = 0
    public var upperDistanceLimit: CGFloat = 0
    public var shouldEnableLimits: Bool = false
    public class func joint(
        withBodyA bodyA: SKPhysicsBody,
        bodyB: SKPhysicsBody,
        anchor: CGPoint,
        axis: CGVector
    ) -> SKPhysicsJointSliding {
        _ = anchor
        _ = axis
        return SKPhysicsJointSliding(bodyA: bodyA, bodyB: bodyB)
    }
}

open class SKPhysicsJointSpring: SKPhysicsJoint {
    public var damping: CGFloat = 0
    public var frequency: CGFloat = 0
    public class func joint(
        withBodyA bodyA: SKPhysicsBody,
        bodyB: SKPhysicsBody,
        anchorA: CGPoint,
        anchorB: CGPoint
    ) -> SKPhysicsJointSpring {
        _ = anchorA
        _ = anchorB
        return SKPhysicsJointSpring(bodyA: bodyA, bodyB: bodyB)
    }
}
