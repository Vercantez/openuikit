import Foundation
import SceneKit

func testPhysicsBookkeeping() {
    let body = SCNPhysicsBody.dynamic()
    precondition(body.type == .dynamic)
    let kin = SCNPhysicsBody.kinematic()
    precondition(kin.type == .kinematic)
    let stat = SCNPhysicsBody.static()
    precondition(stat.type == .static)
    let node = SCNNode()
    node.physicsBody = body
    let scene = SCNScene()
    scene.rootNode.addChildNode(node)
    scene.physicsWorld.gravity = SCNVector3Zero
    body.isAffectedByGravity = false
    body.damping = 0
    let before = node.position
    scene.physicsWorld.step()
    precondition(SCNVector3EqualToVector3(node.position, before))
    let world = SCNPhysicsWorld()
    world.gravity = SCNVector3(0, -9.8, 0)
    world.addBehavior(SCNPhysicsHingeJoint(body: kin, axis: SCNVector3(0, 1, 0), anchor: SCNVector3Zero))
    precondition(world.allBehaviors.count == 1)
    let field = SCNPhysicsField.linearGravity()
    precondition(field.isActive)
    _ = SCNPhysicsField.radialGravity()
    _ = SCNPhysicsField.vortex()
    _ = SCNPhysicsField.drag()
    _ = SCNPhysicsField.turbulenceField(smoothness: 1, animationSpeed: 1)
    _ = SCNPhysicsField.noiseField(smoothness: 1, animationSpeed: 1)
    _ = SCNPhysicsField.spring()
    _ = SCNPhysicsField.electric()
    _ = SCNPhysicsField.magnetic()
    let vehicle = SCNPhysicsVehicle(chassisBody: kin, wheels: [SCNPhysicsVehicleWheel(node: node)])
    precondition(vehicle.wheels.count == 1)
    let contact = SCNPhysicsContact()
    precondition(contact.collisionImpulse == 0)
    let shape = SCNPhysicsShape(geometry: SCNBox(width: 1, height: 1, length: 1, chamferRadius: 0), options: nil)
    _ = shape
    _ = SCNPhysicsBallSocketJoint(bodyA: kin, anchorA: SCNVector3Zero, bodyB: body, anchorB: SCNVector3Zero)
    _ = SCNPhysicsSliderJoint(bodyA: kin, axisA: SCNVector3(0, 1, 0), anchorA: SCNVector3Zero, bodyB: body, axisB: SCNVector3(0, 1, 0), anchorB: SCNVector3Zero)
    _ = SCNPhysicsConeTwistJoint(bodyA: kin, frameA: SCNMatrix4Identity, bodyB: body, frameB: SCNMatrix4Identity)
    body.mass = 1
    body.friction = 0.5
    body.restitution = 0.5
    body.damping = 0.1
    body.isAffectedByGravity = true
    _ = body.velocity
    _ = body.angularVelocity
    world.speed = 1
    world.timeStep = 1.0 / 60
    _ = SCNPhysicsWorld.TestOption.collisionBitMask
    _ = SCNPhysicsWorld.TestSearchMode.closest
}

final class _SCNContactProbe: NSObject, SCNPhysicsContactDelegate {
    var began = 0
    var updated = 0
    func physicsWorld(_ world: SCNPhysicsWorld, didBegin contact: SCNPhysicsContact) {
        began += 1
        _ = contact.nodeA
        _ = contact.nodeB
        _ = contact.contactPoint
        _ = contact.contactNormal
        _ = contact.penetrationDistance
        _ = contact.collisionImpulse
        _ = contact.sweepTestFraction
    }
    func physicsWorld(_ world: SCNPhysicsWorld, didUpdate contact: SCNPhysicsContact) {
        updated += 1
    }
}

func testPhysicsGravityIntegration() {
    let scene = SCNScene()
    scene.physicsWorld.gravity = SCNVector3(0, -10, 0)
    scene.physicsWorld.timeStep = 1
    scene.physicsWorld.speed = 1
    let node = SCNNode()
    let body = SCNPhysicsBody.dynamic()
    body.mass = 1
    body.damping = 0
    body.isAffectedByGravity = true
    node.physicsBody = body
    scene.rootNode.addChildNode(node)
    scene.physicsWorld.step()
    // Semi-implicit Euler: v = -10, p = -10.
    precondition(abs(body.velocity.y + 10) < 1e-3)
    precondition(abs(node.position.y + 10) < 1e-3)
    let staticNode = SCNNode()
    staticNode.physicsBody = SCNPhysicsBody.static()
    staticNode.physicsBody?.isAffectedByGravity = true
    scene.rootNode.addChildNode(staticNode)
    let sy = staticNode.position.y
    scene.physicsWorld.step()
    precondition(abs(staticNode.position.y - sy) < 1e-4)
}

func testPhysicsSphereContacts() {
    let scene = SCNScene()
    scene.physicsWorld.gravity = SCNVector3Zero
    scene.physicsWorld.timeStep = 1
    let a = SCNNode(geometry: SCNSphere(radius: 0.5))
    let b = SCNNode(geometry: SCNSphere(radius: 0.5))
    a.position = SCNVector3(-0.25, 0, 0)
    b.position = SCNVector3(0.25, 0, 0)
    let bodyA = SCNPhysicsBody.dynamic()
    bodyA.mass = 1
    bodyA.damping = 0
    bodyA.restitution = 0
    bodyA.isAffectedByGravity = false
    bodyA.physicsShape = SCNPhysicsShape(geometry: a.geometry!, options: nil)
    let bodyB = SCNPhysicsBody.dynamic()
    bodyB.mass = 1
    bodyB.damping = 0
    bodyB.restitution = 0
    bodyB.isAffectedByGravity = false
    bodyB.physicsShape = SCNPhysicsShape(geometry: b.geometry!, options: nil)
    a.physicsBody = bodyA
    b.physicsBody = bodyB
    scene.rootNode.addChildNode(a)
    scene.rootNode.addChildNode(b)
    let overlap = scene.physicsWorld.contactTestBetween(bodyA, bodyB, options: nil)
    precondition(!overlap.isEmpty)
    precondition(overlap[0].penetrationDistance > 0)
    scene.physicsWorld.step()
    let dx = abs(b.worldPosition.x - a.worldPosition.x)
    precondition(dx >= 0.99)
}

func testPhysicsBoxAABBContacts() {
    let scene = SCNScene()
    scene.physicsWorld.gravity = SCNVector3Zero
    scene.physicsWorld.timeStep = 1
    let boxGeom = SCNBox(width: 2, height: 2, length: 2, chamferRadius: 0)
    let moving = SCNNode(geometry: boxGeom)
    let wall = SCNNode(geometry: boxGeom)
    moving.position = SCNVector3(0, 0, 0)
    wall.position = SCNVector3(1.5, 0, 0)
    let dyn = SCNPhysicsBody.dynamic()
    dyn.mass = 1
    dyn.damping = 0
    dyn.restitution = 0
    dyn.isAffectedByGravity = false
    dyn.physicsShape = SCNPhysicsShape(geometry: boxGeom, options: nil)
    let stat = SCNPhysicsBody.static()
    stat.physicsShape = SCNPhysicsShape(geometry: boxGeom, options: nil)
    moving.physicsBody = dyn
    wall.physicsBody = stat
    scene.rootNode.addChildNode(moving)
    scene.rootNode.addChildNode(wall)
    let hits = scene.physicsWorld.contactTest(with: dyn, options: nil)
    precondition(!hits.isEmpty)
    scene.physicsWorld.step()
    precondition(moving.worldPosition.x <= 0.01)
}

func testPhysicsContactDelegate() {
    let scene = SCNScene()
    scene.physicsWorld.gravity = SCNVector3Zero
    scene.physicsWorld.timeStep = 1
    let probe = _SCNContactProbe()
    scene.physicsWorld.contactDelegate = probe
    let a = SCNNode(geometry: SCNSphere(radius: 1))
    let b = SCNNode(geometry: SCNSphere(radius: 1))
    a.position = SCNVector3(-0.5, 0, 0)
    b.position = SCNVector3(0.5, 0, 0)
    let bodyA = SCNPhysicsBody.dynamic()
    bodyA.mass = 1
    bodyA.damping = 0
    bodyA.isAffectedByGravity = false
    bodyA.contactTestBitMask = .max
    bodyA.physicsShape = SCNPhysicsShape(geometry: a.geometry!, options: nil)
    let bodyB = SCNPhysicsBody.static()
    bodyB.physicsShape = SCNPhysicsShape(geometry: b.geometry!, options: nil)
    a.physicsBody = bodyA
    b.physicsBody = bodyB
    scene.rootNode.addChildNode(a)
    scene.rootNode.addChildNode(b)
    scene.physicsWorld.step()
    precondition(probe.began >= 1)
    scene.physicsWorld.updateCollisionPairs()
}

func testPhysicsForces() {
    let scene = SCNScene()
    scene.physicsWorld.gravity = SCNVector3Zero
    scene.physicsWorld.timeStep = 1
    let node = SCNNode()
    let body = SCNPhysicsBody.dynamic()
    body.mass = 2
    body.damping = 0
    body.isAffectedByGravity = false
    node.physicsBody = body
    scene.rootNode.addChildNode(node)
    body.applyForce(SCNVector3(4, 0, 0), asImpulse: false)
    scene.physicsWorld.step()
    // a = 4/2 = 2, v = 2, p = 2
    precondition(abs(body.velocity.x - 2) < 1e-3)
    precondition(abs(node.position.x - 2) < 1e-3)
    body.clearAllForces()
    body.applyForce(SCNVector3(0, 6, 0), asImpulse: true)
    scene.physicsWorld.step()
    precondition(abs(body.velocity.y - 3) < 1e-3)
    body.applyForce(SCNVector3(0, 0, 1), at: SCNVector3(1, 0, 0), asImpulse: true)
    body.applyTorque(SCNVector4(0, 1, 0, 0.2), asImpulse: true)
    body.setResting(true)
    precondition(body.isResting)
    precondition(abs(body.velocity.x) < 1e-4)
    body.resetTransform()
    precondition(!body.isResting)
    _ = body.allowsResting
    _ = body.angularDamping
    _ = body.angularRestingThreshold
    _ = body.angularVelocityFactor
    _ = body.centerOfMassOffset
    _ = body.charge
    _ = body.collisionBitMask
    _ = body.contactTestBitMask
    _ = body.continuousCollisionDetectionThreshold
    _ = body.linearRestingThreshold
    _ = body.momentOfInertia
    _ = body.physicsShape
    _ = body.rollingFriction
    _ = body.usesDefaultMomentOfInertia
    _ = body.velocityFactor
}

func testPhysicsRayAndContactQuery() {
    let scene = SCNScene()
    let box = SCNNode(geometry: SCNBox(width: 2, height: 2, length: 2, chamferRadius: 0))
    scene.rootNode.addChildNode(box)
    let hits = scene.physicsWorld.rayTestWithSegment(
        from: SCNVector3(0, 0, 5),
        to: SCNVector3(0, 0, -5),
        options: nil
    )
    precondition(!hits.isEmpty)
    let world = SCNPhysicsWorld()
    world.removeAllBehaviors()
    let hinge = SCNPhysicsHingeJoint(body: SCNPhysicsBody.kinematic(), axis: SCNVector3(0, 1, 0), anchor: SCNVector3Zero)
    world.addBehavior(hinge)
    world.removeBehavior(hinge)
    precondition(world.allBehaviors.isEmpty)
    let sweep = world.convexSweepTest(
        with: SCNPhysicsShape(geometry: SCNBox(width: 1, height: 1, length: 1, chamferRadius: 0), options: nil),
        from: SCNMatrix4Identity,
        to: SCNMatrix4MakeTranslation(1, 0, 0),
        options: nil
    )
    precondition(sweep.isEmpty)
}
