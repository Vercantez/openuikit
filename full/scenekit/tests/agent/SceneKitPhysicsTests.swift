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
}
