import Foundation
import SceneKit


func _transformed(_ vector: SCNVector3, by matrix: SCNMatrix4) -> SCNVector3 {
    SCNVector3(
        matrix.m11 * vector.x + matrix.m21 * vector.y + matrix.m31 * vector.z + matrix.m41,
        matrix.m12 * vector.x + matrix.m22 * vector.y + matrix.m32 * vector.z + matrix.m42,
        matrix.m13 * vector.x + matrix.m23 * vector.y + matrix.m33 * vector.z + matrix.m43
    )
}

precondition(SCNVector3EqualToVector3(SCNVector3Make(1, 2, 3), SCNVector3(1, 2, 3)))
precondition(SCNVector4EqualToVector4(SCNVector4Make(1, 2, 3, 4), SCNVector4(1, 2, 3, 4)))
precondition(SCNMatrix4IsIdentity(SCNMatrix4Identity))
precondition(!SCNMatrix4IsIdentity(SCNMatrix4MakeTranslation(1, 0, 0)))

let translated = SCNMatrix4MakeTranslation(3, 4, 5)
let point = _transformed(SCNVector3(1, 1, 1), by: translated)
precondition(SCNVector3EqualToVector3(point, SCNVector3(4, 5, 6)))

let scaled = SCNMatrix4MakeScale(2, 3, 4)
precondition(SCNMatrix4EqualToMatrix4(scaled, SCNMatrix4MakeScale(2, 3, 4)))

let inverse = SCNMatrix4Invert(translated)
let origin = _transformed(SCNVector3(3, 4, 5), by: inverse)
precondition(abs(origin.x) < 0.001 && abs(origin.y) < 0.001 && abs(origin.z) < 0.001)

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
precondition(SCNColorMask.all.contains(.red))
precondition(SCNBillboardAxis.all.contains(.Y))
precondition(SCNDebugOptions.showBoundingBoxes.contains(.showBoundingBoxes))

let camera = SCNCamera()
camera.fieldOfView = 60
camera.zNear = 0.1
camera.zFar = 100
let projection = camera.projectionTransform(withViewportSize: CGSize(width: 16, height: 9))
precondition(!SCNMatrix4IsIdentity(projection))
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

SCNTransaction.begin()
SCNTransaction.disableActions = true
SCNTransaction.animationDuration = 0.25
SCNTransaction.setValue("ok", forKey: "probe")
precondition(SCNTransaction.value(forKey: "probe") as? String == "ok")
SCNTransaction.commit()
SCNTransaction.disableActions = false

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
