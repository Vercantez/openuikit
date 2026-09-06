import Foundation
import SceneKit

func testLookAtDistanceBillboard() {
    let scene = SCNScene()
    let target = SCNNode()
    target.position = SCNVector3(10, 0, 0)
    let follower = SCNNode()
    scene.rootNode.addChildNode(target)
    scene.rootNode.addChildNode(follower)
    let look = SCNLookAtConstraint(target: target)
    look.influenceFactor = 1
    look.isGimbalLockEnabled = false
    look.localFront = SCNNode.localFront
    look.targetOffset = SCNVector3Zero
    look.worldUp = SCNNode.localUp
    follower.constraints = [look]
    follower.linux_advanceTime(0)
    precondition(abs(follower.worldFront.x) > 0.5)
    let dist = SCNDistanceConstraint(target: target)
    dist.minimumDistance = 4
    dist.maximumDistance = 4
    follower.constraints = [dist]
    follower.linux_advanceTime(0)
    let dx = follower.worldPosition.x - target.worldPosition.x
    let dy = follower.worldPosition.y - target.worldPosition.y
    let dz = follower.worldPosition.z - target.worldPosition.z
    let len = (dx * dx + dy * dy + dz * dz).squareRoot()
    precondition(abs(len - 4) < 0.05)
    let billboard = SCNBillboardConstraint()
    billboard.freeAxes = .all
    follower.constraints = [look, dist, billboard]
    follower.linux_advanceTime(0)
    precondition(follower.constraints?.count == 3)
    let tf = SCNTransformConstraint(inWorldSpace: false, with: { _, m in m })
    _ = SCNTransformConstraint(inWorldSpace: true, withBlock: { _, m in m })
    _ = SCNTransformConstraint.orientationConstraint(inWorldSpace: false, with: { _, q in q })
    _ = SCNTransformConstraint.positionConstraint(inWorldSpace: false, with: { _, v in v })
    _ = tf
    let accel = SCNAccelerationConstraint()
    accel.damping = 0.2
    let slider = SCNSliderConstraint()
    slider.radius = 1
    let repl = SCNReplicatorConstraint()
    repl.replicatesPosition = false
    let avoid = SCNAvoidOccluderConstraint()
    avoid.bias = 0.1
    let ik = SCNIKConstraint.inverseKinematicsConstraint(chainRootNode: follower)
    precondition(ik.chainRootNode === follower)
    _ = accel.maximumLinearAcceleration
    _ = slider.offset
    _ = repl.orientationOffset
    _ = avoid.occluderCategoryBitMask
}

func testReplicatorConstraintMath() {
    let scene = SCNScene()
    let target = SCNNode()
    target.position = SCNVector3(3, 4, 5)
    target.scale = SCNVector3(2, 2, 2)
    target.eulerAngles = SCNVector3(0, Float.pi / 2, 0)
    let follower = SCNNode()
    scene.rootNode.addChildNode(target)
    scene.rootNode.addChildNode(follower)
    let repl = SCNReplicatorConstraint(target: target)
    repl.replicatesPosition = true
    repl.replicatesOrientation = true
    repl.replicatesScale = true
    repl.positionOffset = SCNVector3(1, 0, 0)
    repl.scaleOffset = SCNVector3(0.5, 0.5, 0.5)
    repl.orientationOffset = SCNQuaternion(x: 0, y: 0, z: 0, w: 1)
    repl.influenceFactor = 1
    follower.constraints = [repl]
    follower.linux_advanceTime(0)
    precondition(abs(follower.worldPosition.x - 4) < 1e-3)
    precondition(abs(follower.worldPosition.y - 4) < 1e-3)
    precondition(abs(follower.scale.x - 2.5) < 1e-3)
    precondition(abs(follower.worldOrientation.y - target.worldOrientation.y) < 0.05)
}
