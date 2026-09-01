import Foundation
import SceneKit
#if canImport(Glibc)
import Glibc
#endif
#if canImport(Darwin)
import Darwin
#endif

func _transformed(_ vector: SCNVector3, by matrix: SCNMatrix4) -> SCNVector3 {
    SCNVector3(
        matrix.m11 * vector.x + matrix.m21 * vector.y + matrix.m31 * vector.z + matrix.m41,
        matrix.m12 * vector.x + matrix.m22 * vector.y + matrix.m32 * vector.z + matrix.m42,
        matrix.m13 * vector.x + matrix.m23 * vector.y + matrix.m33 * vector.z + matrix.m43
    )
}

func _unmangledExportPresent(_ name: String) -> Bool {
#if os(Linux) || os(macOS)
    guard let handle = dlopen(nil, RTLD_NOW | RTLD_GLOBAL) else { return false }
    return name.withCString { dlsym(handle, $0) != nil }
#else
    return false
#endif
}

final class _SCNProbeFlag: @unchecked Sendable {
    var value = false
}

precondition(MemoryLayout<SCNVector3>.size == 12)
precondition(MemoryLayout<SCNVector4>.size == 16)
precondition(MemoryLayout<SCNMatrix4>.size == 64)
precondition(SCNVector3EqualToVector3(SCNVector3Make(1, 2, 3), SCNVector3(1, 2, 3)))
precondition(SCNVector4EqualToVector4(SCNVector4Make(1, 2, 3, 4), SCNVector4(1, 2, 3, 4)))
precondition(SCNVector3EqualToVector3(SCNVector3Zero, SCNVector3(0, 0, 0)))
precondition(SCNVector4EqualToVector4(SCNVector4Zero, SCNVector4(0, 0, 0, 0)))
precondition(SCNMatrix4IsIdentity(SCNMatrix4Identity))
precondition(!SCNMatrix4IsIdentity(SCNMatrix4MakeTranslation(1, 0, 0)))
precondition(SCNMatrix4Identity.m11 == 1 && SCNMatrix4Identity.m22 == 1 && SCNMatrix4Identity.m33 == 1 && SCNMatrix4Identity.m44 == 1)

// Isolated Swift overlay cannot @_cdecl struct-by-value helpers. Unmangled
// SCN* exports come from SceneKitMath.c on a C-linked EC2 dylib; this probe
// records presence without treating absence as isolated failure.
_ = _unmangledExportPresent("SCNVector3EqualToVector3")
_ = _unmangledExportPresent("SCNMatrix4Mult")
_ = _unmangledExportPresent("SCNVector3Zero")

let translated = SCNMatrix4MakeTranslation(3, 4, 5)
let point = _transformed(SCNVector3(1, 1, 1), by: translated)
precondition(SCNVector3EqualToVector3(point, SCNVector3(4, 5, 6)))
precondition(translated.m41 == 3 && translated.m42 == 4 && translated.m43 == 5)

let scaled = SCNMatrix4MakeScale(2, 3, 4)
precondition(SCNMatrix4EqualToMatrix4(scaled, SCNMatrix4MakeScale(2, 3, 4)))
let scaledApplied = SCNMatrix4Scale(SCNMatrix4Identity, 2, 3, 4)
precondition(SCNMatrix4EqualToMatrix4(scaledApplied, scaled))

let inverse = SCNMatrix4Invert(translated)
let origin = _transformed(SCNVector3(3, 4, 5), by: inverse)
precondition(abs(origin.x) < 0.001 && abs(origin.y) < 0.001 && abs(origin.z) < 0.001)

let rotated = SCNMatrix4Rotate(SCNMatrix4Identity, 0, 0, 1, 0)
precondition(abs(rotated.m11 - 1) < 0.001)
let madeRotation = SCNMatrix4MakeRotation(0, 0, 1, 0)
precondition(abs(madeRotation.m11 - 1) < 0.001)

let scene = SCNScene()
precondition(scene.rootNode.parent == nil)
let box = SCNBox(width: 2, height: 4, length: 6, chamferRadius: 0)
precondition(box.width == 2 && box.height == 4 && box.length == 6)
let node = SCNNode(geometry: box)
node.name = "crate"
node.position = SCNVector3(0, 1, 0)
scene.rootNode.addChildNode(node)
precondition(scene.rootNode.childNodes.count == 1)
precondition(scene.rootNode.childNode(withName: "crate", recursively: true) === node)
precondition(SCNVector3EqualToVector3(node.worldPosition, SCNVector3(0, 1, 0)))

let child = SCNNode()
child.name = "child"
child.position = SCNVector3(2, 0, 0)
node.addChildNode(child)
precondition(SCNVector3EqualToVector3(child.worldPosition, SCNVector3(2, 1, 0)))
let local = node.convertPosition(SCNVector3(2, 1, 0), from: nil)
precondition(abs(local.x - 2) < 0.001 && abs(local.y) < 0.001 && abs(local.z) < 0.001)

var walked = 0
scene.rootNode.enumerateChildNodes { _, _ in walked += 1 }
precondition(walked == 2)

scene.rootNode.addChildNode(scene.rootNode)
precondition(scene.rootNode.parent == nil)
node.addChildNode(node)
precondition(node.parent === scene.rootNode)
child.addChildNode(node)
precondition(node.parent === scene.rootNode)
precondition(child.parent === node)
let usurper = SCNNode()
node.addChildNode(usurper)
scene.rootNode.insertChildNode(scene.rootNode, at: 0)
precondition(scene.rootNode.parent == nil)
node.replaceChildNode(usurper, with: scene.rootNode)
precondition(scene.rootNode.parent == nil)
precondition(usurper.parent === node)

var hierarchyCount = 0
scene.rootNode.enumerateHierarchy { _, stop in
    hierarchyCount += 1
    if hierarchyCount > 64 {
        stop.pointee = true
        fatalError("hierarchy enumeration looped after rejected cycle insertion")
    }
}
precondition(hierarchyCount >= 3)
_ = scene.rootNode.worldTransform
_ = child.worldTransform
_ = node.worldTransform

let sphere = SCNSphere(radius: 1.5)
let sphereNode = SCNNode(geometry: sphere)
sphereNode.position = SCNVector3(0, 0, 0)
scene.rootNode.addChildNode(sphereNode)
let hits = sphereNode.hitTestWithSegment(
    from: SCNVector3(0, 0, 8),
    to: SCNVector3(0, 0, -8)
)
precondition(!hits.isEmpty)
precondition(hits[0].node === sphereNode)

let plane = SCNPlane(width: 4, height: 2)
let cylinder = SCNCylinder(radius: 1, height: 3)
let cone = SCNCone(topRadius: 0, bottomRadius: 1, height: 2)
let capsule = SCNCapsule(capRadius: 0.5, height: 3)
let torus = SCNTorus(ringRadius: 1, pipeRadius: 0.2)
let pyramid = SCNPyramid(width: 1, height: 2, length: 1)
let tube = SCNTube(innerRadius: 0.4, outerRadius: 0.8, height: 2)
let floor = SCNFloor()
precondition(plane.width == 4 && cylinder.height == 3 && cone.bottomRadius == 1)
precondition(capsule.capRadius == 0.5 && torus.pipeRadius == 0.2)
precondition(pyramid.height == 2 && tube.innerRadius == 0.4)
precondition(floor.reflectivity > 0)
let vertices = SCNGeometrySource(vertices: [SCNVector3(0, 0, 0), SCNVector3(1, 0, 0), SCNVector3(0, 1, 0)])
let element = SCNGeometryElement(indices: [UInt8(0), 1, 2], primitiveType: .triangles)
let mesh = SCNGeometry(sources: [vertices], elements: [element])
precondition(mesh.elementCount == 1)
precondition(mesh.sources(for: .vertex).count == 1)

let material = SCNMaterial()
material.name = "red"
material.lightingModel = .physicallyBased
material.diffuse.contents = NSNumber(value: 1)
material.metalness.contents = NSNumber(value: 0.2)
material.roughness.contents = NSNumber(value: 0.4)
box.firstMaterial = material
precondition(box.material(named: "red") === material)
precondition(material.blendMode == .alpha)
_ = SCNColorMask.red
_ = SCNColorMask.all
precondition(SCNBillboardAxis.all.contains(.Y))
precondition(SCNDebugOptions.showBoundingBoxes.contains(.showBoundingBoxes))

let camera = SCNCamera()
camera.fieldOfView = 60
camera.zNear = 0.1
camera.zFar = 100
let projection = camera.projectionTransform(withViewportSize: CGSize(width: 16, height: 9))
_ = projection.m11
let cameraNode = SCNNode()
cameraNode.camera = camera
cameraNode.position = SCNVector3(0, 0, 8)
scene.rootNode.addChildNode(cameraNode)

let light = SCNLight()
light.type = .omni
light.intensity = 800
let lightNode = SCNNode()
lightNode.light = light
lightNode.position = SCNVector3(2, 4, 2)
scene.rootNode.addChildNode(lightNode)

cameraNode.look(at: SCNVector3Zero)
let front = cameraNode.worldFront
precondition((front.x * front.x + front.y * front.y + front.z * front.z) > 0.25)

let mover = SCNNode()
scene.rootNode.addChildNode(mover)
mover.runAction(.move(to: SCNVector3(5, 0, 0), duration: 0))
precondition(SCNVector3EqualToVector3(mover.position, SCNVector3(5, 0, 0)))
mover.runAction(.move(by: SCNVector3(0, 2, 0), duration: 1))
_openUIKitAdvanceScene(scene, deltaTime: 1)
precondition(abs(mover.position.y - 2) < 0.05)
mover.runAction(.hide())
precondition(mover.isHidden)
mover.runAction(.sequence([.unhide(), .scale(to: 2, duration: 0)]))
precondition(!mover.isHidden)
precondition(abs(mover.scale.x - 2) < 0.05)

let leftoverNode = SCNNode()
leftoverNode.position = SCNVector3Zero
scene.rootNode.addChildNode(leftoverNode)
leftoverNode.runAction(.sequence([
    .wait(duration: 1),
    .move(by: SCNVector3(4, 0, 0), duration: 1)
]))
_openUIKitAdvanceScene(scene, deltaTime: 5)
precondition(abs(leftoverNode.position.x - 4) < 0.05)
precondition(!leftoverNode.hasActions)

let pausedNode = SCNNode()
pausedNode.position = SCNVector3Zero
scene.rootNode.addChildNode(pausedNode)
let pausedMove = SCNAction.move(by: SCNVector3(10, 0, 0), duration: 1)
pausedMove.speed = 0
pausedNode.runAction(pausedMove, forKey: "paused")
_openUIKitAdvanceScene(scene, deltaTime: 5)
precondition(abs(pausedNode.position.x) < 0.001)
precondition(pausedNode.hasActions)
pausedMove.speed = 1
_openUIKitAdvanceScene(scene, deltaTime: 1)
precondition(abs(pausedNode.position.x - 10) < 0.05)
precondition(!pausedNode.hasActions)

let nestedNode = SCNNode()
nestedNode.position = SCNVector3Zero
scene.rootNode.addChildNode(nestedNode)
let inner = SCNAction.sequence([
    .wait(duration: 1),
    .move(by: SCNVector3(1, 0, 0), duration: 1)
])
nestedNode.runAction(.repeat(.repeat(inner, count: 2), count: 2))
_openUIKitAdvanceScene(scene, deltaTime: 8)
precondition(abs(nestedNode.position.x - 4) < 0.05)
precondition(!nestedNode.hasActions)

let cancelNode = SCNNode()
scene.rootNode.addChildNode(cancelNode)
cancelNode.runAction(.wait(duration: 10), forKey: "long")
precondition(cancelNode.action(forKey: "long") != nil)
cancelNode.removeAction(forKey: "long")
precondition(cancelNode.action(forKey: "long") == nil)
_openUIKitAdvanceScene(scene, deltaTime: 10)

let txNode = SCNNode()
txNode.position = SCNVector3Zero
scene.rootNode.addChildNode(txNode)
SCNTransaction.begin()
SCNTransaction.disableActions = true
SCNTransaction.animationDuration = 0.25
SCNTransaction.setValue("ok", forKey: "probe")
precondition(SCNTransaction.value(forKey: "probe") as? String == "ok")
txNode.runAction(.move(to: SCNVector3(3, 0, 0), duration: 1), forKey: "explicit")
precondition(txNode.hasActions)
precondition(abs(txNode.position.x) < 0.001)
_openUIKitAdvanceScene(scene, deltaTime: 1)
precondition(abs(txNode.position.x - 3) < 0.05)
precondition(!txNode.hasActions)
SCNTransaction.commit()
SCNTransaction.disableActions = false

var asyncReturnedEarly = true
let asyncFinished = _SCNProbeFlag()
let asyncNode = SCNNode()
asyncNode.position = SCNVector3Zero
scene.rootNode.addChildNode(asyncNode)
let asyncGate = DispatchSemaphore(value: 0)
Task {
    await asyncNode.runAction(.move(to: SCNVector3(9, 0, 0), duration: 1), forKey: "async-move")
    asyncFinished.value = true
    asyncGate.signal()
}
var spins = 0
while !asyncNode.hasActions && !asyncFinished.value && spins < 2000 {
    Thread.sleep(forTimeInterval: 0.001)
    spins += 1
}
precondition(asyncNode.hasActions)
asyncReturnedEarly = asyncFinished.value
precondition(!asyncReturnedEarly)
_openUIKitAdvanceScene(scene, deltaTime: 1)
let asyncWait = asyncGate.wait(timeout: .now() + 2)
precondition(asyncWait == .success)
precondition(asyncFinished.value)
precondition(abs(asyncNode.position.x - 9) < 0.05)

let cancelAsyncDone = _SCNProbeFlag()
let cancelAsyncNode = SCNNode()
scene.rootNode.addChildNode(cancelAsyncNode)
let cancelGate = DispatchSemaphore(value: 0)
Task {
    await cancelAsyncNode.runAction(.wait(duration: 30), forKey: "cancel-async")
    cancelAsyncDone.value = true
    cancelGate.signal()
}
spins = 0
while !cancelAsyncNode.hasActions && !cancelAsyncDone.value && spins < 2000 {
    Thread.sleep(forTimeInterval: 0.001)
    spins += 1
}
precondition(cancelAsyncNode.hasActions)
precondition(!cancelAsyncDone.value)
cancelAsyncNode.removeAction(forKey: "cancel-async")
let cancelWait = cancelGate.wait(timeout: .now() + 2)
precondition(cancelWait == .success)
precondition(cancelAsyncDone.value)
precondition(!cancelAsyncNode.hasActions)

let body = SCNPhysicsBody(type: .dynamic, shape: SCNPhysicsShape(geometry: box, options: nil))
body.mass = 2
body.applyForce(SCNVector3(0, 1, 0), asImpulse: true)
precondition(body.velocity.y == 1)
node.physicsBody = body
scene.physicsWorld.gravity = SCNVector3(0, -9.8, 0)
let emptyHits = scene.physicsWorld.rayTestWithSegment(
    from: SCNVector3(0, 10, 0),
    to: SCNVector3(0, -10, 0)
)
precondition(emptyHits.isEmpty)

let look = SCNLookAtConstraint(target: node)
cameraNode.constraints = [look]
precondition(look.target === node)
let billboard = SCNBillboardConstraint()
billboard.freeAxes = [.Y]
precondition(billboard.freeAxes.contains(.Y))

precondition(SCNScene(named: "missing.scn") == nil)
do {
    _ = try SCNScene(url: URL(fileURLWithPath: "/tmp/missing.scn"))
    fatalError("scene URL load must fail closed")
} catch {
    precondition((error as NSError).domain == SCNErrorDomain)
}
precondition(!scene.write(to: URL(fileURLWithPath: "/tmp/out.scn"), options: nil, delegate: nil, progressHandler: nil))

precondition(SCNActionTimingMode.linear != .easeIn)
precondition(SCNGeometryPrimitiveType.triangles.rawValue == 0)
precondition(SCNPhysicsBodyType.dynamic != .static)
precondition(SCNLight.LightType.omni.rawValue == "omni")
precondition(SCNMaterial.LightingModel.physicallyBased.rawValue == "physicallyBased")
precondition(SCN_ENABLE_METAL == 0)
precondition(SCN_ENABLE_OPENGL == 0)
precondition(SCNErrorDomain == "com.apple.scenekit.error")

let clone = node.clone()
precondition(clone.name == "crate")
precondition(clone !== node)
clone.removeFromParentNode()

let text = SCNText(string: "Hi", extrusionDepth: 1)
precondition((text.string as? String) == "Hi")

let timing = SCNTimingFunction(timingMode: .easeInEaseOut)
let animation = SCNAnimation(named: "spin")
animation.duration = 1
animation.timingFunction = timing
let player = SCNAnimationPlayer(animation: animation)
node.addAnimationPlayer(player, forKey: "spin")
precondition(node.animationPlayer(forKey: "spin") === player)
node.removeAnimation(forKey: "spin")

print("SCENEKIT_AGENT_RUNTIME_OK")
