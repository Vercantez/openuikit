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

func testPhysicsFieldForces() {
    let scene = SCNScene()
    scene.physicsWorld.gravity = SCNVector3Zero
    scene.physicsWorld.timeStep = 1
    let node = SCNNode()
    let body = SCNPhysicsBody.dynamic()
    body.mass = 1
    body.damping = 0
    body.isAffectedByGravity = false
    node.physicsBody = body
    scene.rootNode.addChildNode(node)
    let fieldNode = SCNNode()
    let field = SCNPhysicsField.linearGravity()
    field.strength = 4
    field.direction = SCNVector3(1, 0, 0)
    field.falloffExponent = 0
    field.halfExtent = SCNVector3(100, 100, 100)
    field.scope = .insideExtent
    field.isExclusive = false
    field.usesEllipsoidalExtent = false
    fieldNode.physicsField = field
    scene.rootNode.addChildNode(fieldNode)
    scene.physicsWorld.step()
    precondition(abs(body.velocity.x - 4) < 1e-3)
    node.worldPosition = SCNVector3Zero
    body.velocity = SCNVector3Zero
    let radial = SCNPhysicsField.radialGravity()
    radial.strength = 1
    radial.falloffExponent = 0
    fieldNode.physicsField = radial
    node.worldPosition = SCNVector3(2, 0, 0)
    scene.physicsWorld.step()
    precondition(body.velocity.x < 0)
    var customCalls = 0
    let custom = SCNPhysicsField.customField(evaluationBlock: { position, velocity, mass, charge, time in
        customCalls += 1
        _ = position
        _ = velocity
        _ = mass
        _ = charge
        _ = time
        return SCNVector3(0, 3, 0)
    })
    custom.strength = 1
    fieldNode.physicsField = custom
    body.velocity = SCNVector3Zero
    scene.physicsWorld.step()
    precondition(customCalls > 0)
    precondition(abs(body.velocity.y - 3) < 1e-3)
    _ = SCNPhysicsField.noiseField(smoothness: 1, animationSpeed: 1)
    _ = SCNPhysicsField.turbulenceField(smoothness: 0.5, animationSpeed: 2)
    let drag = SCNPhysicsField.drag()
    drag.strength = 1
    _ = drag.linux_evaluate(
        position: SCNVector3Zero, velocity: SCNVector3(4, 0, 0),
        mass: 1, charge: 0, time: 0, origin: SCNVector3Zero
    )
}

func testPhysicsVehicleAndSlider() {
    let scene = SCNScene()
    scene.physicsWorld.gravity = SCNVector3Zero
    scene.physicsWorld.timeStep = 1
    let chassis = SCNNode()
    let body = SCNPhysicsBody.dynamic()
    body.mass = 1
    body.damping = 0
    body.isAffectedByGravity = false
    chassis.physicsBody = body
    scene.rootNode.addChildNode(chassis)
    let wheelNode = SCNNode()
    let wheel = SCNPhysicsVehicleWheel(node: wheelNode)
    wheel.axle = SCNVector3(1, 0, 0)
    wheel.connectionPosition = SCNVector3(0, -0.5, 0)
    wheel.frictionSlip = 1.2
    wheel.maximumSuspensionForce = 100
    wheel.maximumSuspensionTravel = 0.2
    wheel.steeringAxis = SCNVector3(0, 1, 0)
    wheel.suspensionCompression = 0.8
    wheel.suspensionDamping = 0.5
    wheel.suspensionRestLength = 0.4
    wheel.suspensionStiffness = 20
    precondition(abs(Float(wheel.frictionSlip) - 1.2) < 1e-4)
    precondition(abs(wheel.axle.x - 1) < 1e-4)
    let vehicle = SCNPhysicsVehicle(chassisBody: body, wheels: [wheel])
    scene.physicsWorld.addBehavior(vehicle)
    vehicle.applyEngineForce(10, forWheelAt: 0)
    vehicle.applyBrakingForce(0, forWheelAt: 0)
    vehicle.setSteeringAngle(0.1, forWheelAt: 0)
    scene.physicsWorld.step()
    precondition(vehicle.speedInKilometersPerHour > 0)
    let slider = SCNPhysicsSliderJoint(
        bodyA: body, axisA: SCNVector3(0, 1, 0), anchorA: SCNVector3Zero,
        bodyB: SCNPhysicsBody.static(), axisB: SCNVector3(0, 1, 0), anchorB: SCNVector3Zero
    )
    slider.minimumLinearLimit = -1
    slider.maximumLinearLimit = 1
    slider.minimumAngularLimit = -0.5
    slider.maximumAngularLimit = 0.5
    slider.motorTargetLinearVelocity = 2
    slider.motorMaximumForce = 5
    slider.motorTargetAngularVelocity = 0
    slider.motorMaximumTorque = 1
    precondition(slider.maximumLinearLimit == 1)
    precondition(abs(Float(slider.motorTargetLinearVelocity) - 2) < 1e-4)
    scene.physicsWorld.addBehavior(slider)
    _ = SCNPhysicsBehavior()
    let cone = SCNPhysicsConeTwistJoint(bodyA: body, frameA: SCNMatrix4Identity, bodyB: nil, frameB: SCNMatrix4Identity)
    cone.maximumAngularLimit1 = 0.4
    cone.maximumAngularLimit2 = 0.5
    cone.maximumTwistAngle = 0.2
    precondition(abs(Float(cone.maximumTwistAngle) - 0.2) < 1e-4)
}
