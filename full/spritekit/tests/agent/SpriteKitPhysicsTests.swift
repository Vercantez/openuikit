import Foundation
import SpriteKit

func testPhysicsBodyShapes() {
    let circle = SKPhysicsBody(circleOfRadius: 5)
    precondition(abs(circle.area - (.pi * 25)) < 0.01)
    _ = SKPhysicsBody(circleOfRadius: 2, center: CGPoint(x: 1, y: 1))
    let box = SKPhysicsBody(rectangleOf: CGSize(width: 4, height: 3))
    precondition(abs(box.area - 12) < 0.001)
    _ = SKPhysicsBody(rectangleOfSize: CGSize(width: 2, height: 2))
    _ = SKPhysicsBody(rectangleOf: CGSize(width: 2, height: 2), center: .zero)
    _ = SKPhysicsBody(rectangleOfSize: CGSize(width: 2, height: 2), center: .zero)
    let path = CGPath(rect: CGRect(x: 0, y: 0, width: 4, height: 4))
    _ = SKPhysicsBody(edgeFrom: .zero, to: CGPoint(x: 1, y: 0))
    _ = SKPhysicsBody(edgeFromPoint: .zero, toPoint: CGPoint(x: 1, y: 1))
    _ = SKPhysicsBody(edgeLoopFrom: CGRect(x: 0, y: 0, width: 8, height: 8))
    _ = SKPhysicsBody(edgeLoopFromRect: CGRect(x: 0, y: 0, width: 8, height: 8))
    _ = SKPhysicsBody(edgeLoopFrom: path)
    _ = SKPhysicsBody(edgeLoopFromPath: path)
    _ = SKPhysicsBody(edgeChainFrom: path)
    _ = SKPhysicsBody(edgeChainFromPath: path)
    _ = SKPhysicsBody(polygonFrom: path)
    _ = SKPhysicsBody(polygonFromPath: path)
    let tex = SKTexture(imageNamed: "p")
    _ = SKPhysicsBody(texture: tex, size: CGSize(width: 4, height: 4))
    _ = SKPhysicsBody(texture: tex, alphaThreshold: 0.5, size: CGSize(width: 4, height: 4))
    _ = SKPhysicsBody(bodies: [circle, box])
}

func testPhysicsWorldStep() {
    let scene = SKScene(size: CGSize(width: 100, height: 100))
    let node = SKNode()
    node.physicsBody = SKPhysicsBody(circleOfRadius: 4)
    node.physicsBody?.affectedByGravity = true
    node.physicsBody?.isDynamic = true
    scene.addChild(node)
    scene.physicsWorld.gravity = CGVector(dx: 0, dy: -10)
    scene.physicsWorld.speed = 1
    let y0 = node.position.y
    scene.update(0)
    scene.update(0.5)
    precondition(node.position.y < y0)
    node.physicsBody?.applyForce(CGVector(dx: 10, dy: 0))
    node.physicsBody?.applyImpulse(CGVector(dx: 1, dy: 0))
    node.physicsBody?.applyForce(CGVector(dx: 1, dy: 0), at: .zero)
    node.physicsBody?.applyImpulse(CGVector(dx: 1, dy: 0), at: .zero)
    node.physicsBody?.applyTorque(0.1)
    node.physicsBody?.applyAngularImpulse(0.1)
    node.physicsBody?.velocity = CGVector(dx: 1, dy: 0)
    node.physicsBody?.angularVelocity = 0
    node.physicsBody?.mass = 2
    node.physicsBody?.density = 1
    node.physicsBody?.friction = 0.2
    node.physicsBody?.restitution = 0.1
    node.physicsBody?.linearDamping = 0.05
    node.physicsBody?.angularDamping = 0.05
    node.physicsBody?.charge = 0
    node.physicsBody?.allowsRotation = true
    node.physicsBody?.pinned = false
    node.physicsBody?.isResting = false
    node.physicsBody?.usesPreciseCollisionDetection = false
    node.physicsBody?.categoryBitMask = 1
    node.physicsBody?.collisionBitMask = 1
    node.physicsBody?.contactTestBitMask = 1
    node.physicsBody?.fieldBitMask = 1
    _ = node.physicsBody?.node
    _ = node.physicsBody?.joints
    _ = node.physicsBody?.copy()
}

func testPhysicsQueriesAndJoints() {
    let scene = SKScene(size: CGSize(width: 80, height: 80))
    let a = SKNode()
    a.position = CGPoint(x: 0, y: 0)
    a.physicsBody = SKPhysicsBody(circleOfRadius: 3)
    a.physicsBody?.categoryBitMask = 1
    a.physicsBody?.contactTestBitMask = 1
    a.physicsBody?.collisionBitMask = 1
    let b = SKNode()
    b.position = CGPoint(x: 1, y: 0)
    b.physicsBody = SKPhysicsBody(circleOfRadius: 3)
    b.physicsBody?.categoryBitMask = 1
    b.physicsBody?.contactTestBitMask = 1
    b.physicsBody?.collisionBitMask = 1
    scene.addChild(a)
    scene.addChild(b)
    final class ContactProbe: NSObject, SKPhysicsContactDelegate {
        var began = 0
        func didBegin(_ contact: SKPhysicsContact) {
            began += 1
            _ = contact.bodyA
            _ = contact.bodyB
            _ = contact.contactPoint
            _ = contact.contactNormal
            _ = contact.collisionImpulse
        }
        func didEnd(_ contact: SKPhysicsContact) {}
    }
    let probe = ContactProbe()
    scene.physicsWorld.contactDelegate = probe
    scene.update(0)
    scene.update(0.1)
    precondition(probe.began > 0)
    _ = a.physicsBody?.allContactedBodies()
    _ = scene.physicsWorld.body(at: .zero)
    _ = scene.physicsWorld.body(in: CGRect(x: -10, y: -10, width: 20, height: 20))
    _ = scene.physicsWorld.body(alongRayStart: .zero, end: CGPoint(x: 10, y: 0))
    scene.physicsWorld.enumerateBodies(at: .zero) { _, _ in }
    scene.physicsWorld.enumerateBodies(in: CGRect(x: -5, y: -5, width: 10, height: 10)) { _, _ in }
    scene.physicsWorld.enumerateBodies(alongRayStart: .zero, end: CGPoint(x: 4, y: 0)) { _, _, _, _ in }
    let pin = SKPhysicsJointPin.joint(withBodyA: a.physicsBody!, bodyB: b.physicsBody!, anchor: .zero)
    pin.frictionTorque = 1
    pin.lowerAngleLimit = -1
    pin.upperAngleLimit = 1
    pin.rotationSpeed = 0
    pin.shouldEnableLimits = true
    scene.physicsWorld.add(pin)
    _ = SKPhysicsJointFixed.joint(withBodyA: a.physicsBody!, bodyB: b.physicsBody!, anchor: .zero)
    let limit = SKPhysicsJointLimit.joint(
        withBodyA: a.physicsBody!, bodyB: b.physicsBody!,
        anchorA: .zero, anchorB: CGPoint(x: 1, y: 0)
    )
    limit.maxLength = 10
    let slide = SKPhysicsJointSliding.joint(
        withBodyA: a.physicsBody!, bodyB: b.physicsBody!,
        anchor: .zero, axis: CGVector(dx: 1, dy: 0)
    )
    slide.lowerDistanceLimit = 0
    slide.upperDistanceLimit = 4
    slide.shouldEnableLimits = true
    let spring = SKPhysicsJointSpring.joint(
        withBodyA: a.physicsBody!, bodyB: b.physicsBody!,
        anchorA: .zero, anchorB: CGPoint(x: 1, y: 0)
    )
    spring.damping = 1
    spring.frequency = 2
    scene.physicsWorld.add(limit)
    scene.physicsWorld.remove(limit)
    scene.physicsWorld.removeAllJoints()
    _ = pin.bodyA
    _ = pin.bodyB
    _ = pin.reactionForce
    _ = pin.reactionTorque
}

func testPhysicsFieldSample() {
    let scene = SKScene(size: CGSize(width: 20, height: 20))
    let field = SKFieldNode.linearGravityField(withVector: SIMD3<Float>(0, 1, 0))
    scene.addChild(field)
    let sample = scene.physicsWorld.sampleFields(at: SIMD3<Float>(0, 0, 0))
    precondition(sample.y != 0)
}
