import Foundation
import SceneKit

enum SceneKitRuntimeFailure: Error {
    case message(String)
}

func expect(_ condition: Bool, _ message: String) throws {
    if !condition {
        throw SceneKitRuntimeFailure.message(message)
    }
}

func expectNear(_ a: Float, _ b: Float, _ message: String, eps: Float = 1e-4) throws {
    try expect(abs(a - b) < eps, "\(message) (\(a) vs \(b))")
}

func runSceneKitRuntime() throws {
    try expect(SCNVector3EqualToVector3(SCNVector3Zero, SCNVector3Make(0, 0, 0)), "zero vector")
    let v = SCNVector3(1, 2, 3)
    try expectNear(v.x, 1, "vector x")
    try expectNear(v.y, 2, "vector y")
    try expectNear(v.z, 3, "vector z")
    try expect(SCNVector4EqualToVector4(SCNVector4Make(1, 2, 3, 4), SCNVector4(x: 1, y: 2, z: 3, w: 4)), "vec4")
    try expect(SCNMatrix4IsIdentity(SCNMatrix4Identity), "identity")

    let translated = SCNMatrix4MakeTranslation(3, 4, 5)
    let origin = _transform(translated, SCNVector3Zero)
    try expectNear(origin.x, 3, "translate x")
    try expectNear(origin.y, 4, "translate y")
    try expectNear(origin.z, 5, "translate z")

    let scaled = SCNMatrix4MakeScale(2, 3, 4)
    let p = _transform(scaled, SCNVector3(x: 1, y: 1, z: 1))
    try expectNear(p.x, 2, "scale x")
    try expectNear(p.y, 3, "scale y")
    try expectNear(p.z, 4, "scale z")

    let t1 = SCNMatrix4MakeTranslation(1, 0, 0)
    let t2 = SCNMatrix4MakeTranslation(0, 2, 0)
    let composed = SCNMatrix4Mult(t1, t2)
    let c = _transform(composed, SCNVector3Zero)
    try expectNear(c.x, 1, "mult x")
    try expectNear(c.y, 2, "mult y")

    let inv = SCNMatrix4Invert(translated)
    let roundTrip = SCNMatrix4Mult(inv, translated)
    try expect(SCNMatrix4IsIdentity(roundTrip) || _nearIdentity(roundTrip), "invert round-trip")

    try expect(SCNActionTimingMode.linear != .easeIn, "timing cases")
    try expect(SCNBillboardAxis.all.contains(.X) && SCNBillboardAxis.all.contains(.Y), "billboard")
    try expect(SCNDebugOptions.showBoundingBoxes.rawValue == 1 << 1, "debug bits")
    try expect(SCNLight.LightType.omni.rawValue == "omni", "light type")
    try expect(SCNMaterial.LightingModel.blinn.rawValue == "blinn", "lighting model")
    try expect(SCNGeometrySource.Semantic.vertex.rawValue == "vertex", "semantic")

    let scene = SCNScene()
    let parent = SCNNode()
    parent.name = "parent"
    let child = SCNNode()
    child.name = "child"
    scene.rootNode.addChildNode(parent)
    parent.addChildNode(child)
    try expect(child.parent === parent, "parent pointer")
    try expect(parent.childNodes.count == 1, "child count")
    try expect(scene.rootNode.childNode(withName: "child", recursively: true) === child, "recursive lookup")

    parent.addChildNode(parent)
    try expect(parent.childNodes.filter { $0 === parent }.isEmpty, "reject self insert")
    child.addChildNode(parent)
    try expect(child.childNodes.filter { $0 === parent }.isEmpty, "reject ancestor insert")

    var enumerated = 0
    scene.rootNode.enumerateHierarchy { _, _ in enumerated += 1 }
    try expect(enumerated == 3, "hierarchy count \(enumerated)")

    child.position = SCNVector3(x: 1, y: 0, z: 0)
    parent.position = SCNVector3(x: 10, y: 0, z: 0)
    try expectNear(child.worldPosition.x, 11, "world position")
    let local = parent.convertPosition(child.worldPosition, from: nil)
    try expectNear(local.x, 1, "convert from world")

    let clone = parent.clone()
    try expect(clone.childNodes.count == 1, "clone children")
    try expect(clone !== parent, "clone identity")

    var deep: SCNNode = scene.rootNode
    for i in 0..<64 {
        let n = SCNNode()
        n.name = "d\(i)"
        n.position = SCNVector3(x: 0, y: 1, z: 0)
        deep.addChildNode(n)
        deep = n
    }
    try expectNear(deep.worldPosition.y, 64, "deep world y")
    var walk = 0
    scene.rootNode.enumerateChildNodes { _, stop in
        walk += 1
        if walk > 10_000 {
            stop.pointee = true
        }
    }
    try expect(walk < 10_000, "enumeration bounded")

    let box = SCNBox(width: 2, height: 4, length: 6, chamferRadius: 0)
    try expect(box.width == 2 && box.height == 4 && box.length == 6, "box dims")
    try expect(box.sources.first?.semantic == .vertex, "box source")
    let sphere = SCNSphere(radius: 3)
    try expect(sphere.radius == 3, "sphere radius")
    let plane = SCNPlane(width: 5, height: 7)
    try expect(plane.width == 5 && plane.height == 7, "plane")
    let geomNode = SCNNode(geometry: box)
    try expect(geomNode.geometry === box, "geometry attach")

    let cam = SCNCamera()
    cam.fieldOfView = 45
    cam.zNear = 0.1
    cam.zFar = 50
    try expect(cam.fieldOfView == 45, "fov")
    let light = SCNLight()
    light.type = .directional
    light.intensity = 800
    try expect(light.type == .directional, "light")
    let material = SCNMaterial()
    material.lightingModel = .physicallyBased
    material.diffuse.contents = SCNVector3(x: 1, y: 0, z: 0)
    box.firstMaterial = material
    try expect(box.firstMaterial?.lightingModel == .physicallyBased, "material")

    let mover = SCNNode()
    scene.rootNode.addChildNode(mover)
    mover.runAction(SCNAction.move(by: SCNVector3(x: 2, y: 0, z: 0), duration: 1))
    mover.linux_advanceTime(0.5)
    try expectNear(mover.position.x, 1, "move half")
    mover.linux_advanceTime(0.5)
    try expectNear(mover.position.x, 2, "move full")
    try expect(!mover.hasActions, "move completed")

    let leftover = SCNNode()
    leftover.position = SCNVector3Zero
    scene.rootNode.addChildNode(leftover)
    leftover.runAction(SCNAction.sequence([
        SCNAction.wait(duration: 1),
        SCNAction.move(by: SCNVector3(x: 4, y: 0, z: 0), duration: 1)
    ]))
    leftover.linux_advanceTime(1.5)
    try expectNear(leftover.position.x, 2, "sequence leftover")

    let paused = SCNNode()
    scene.rootNode.addChildNode(paused)
    let pausedAction = SCNAction.move(by: SCNVector3(x: 9, y: 0, z: 0), duration: 1)
    pausedAction.speed = 0
    paused.runAction(pausedAction)
    paused.linux_advanceTime(5)
    try expectNear(paused.position.x, 0, "speed zero pauses")

    let repeater = SCNNode()
    scene.rootNode.addChildNode(repeater)
    repeater.runAction(SCNAction.repeat(SCNAction.move(by: SCNVector3(x: 1, y: 0, z: 0), duration: 1), count: 3))
    repeater.linux_advanceTime(3)
    try expectNear(repeater.position.x, 3, "repeat count")

    let nested = SCNNode()
    scene.rootNode.addChildNode(nested)
    nested.runAction(SCNAction.repeat(SCNAction.sequence([
        SCNAction.move(by: SCNVector3(x: 1, y: 0, z: 0), duration: 1),
        SCNAction.wait(duration: 1)
    ]), count: 2))
    nested.linux_advanceTime(4)
    try expectNear(nested.position.x, 2, "nested repeat")

    let large = SCNNode()
    scene.rootNode.addChildNode(large)
    large.runAction(SCNAction.sequence([
        SCNAction.wait(duration: 1),
        SCNAction.move(by: SCNVector3(x: 1, y: 0, z: 0), duration: 1)
    ]))
    large.linux_advanceTime(8)
    try expectNear(large.position.x, 1, "large delta")
    try expect(!large.hasActions, "large delta finished")

    let cancel = SCNNode()
    scene.rootNode.addChildNode(cancel)
    cancel.runAction(SCNAction.move(by: SCNVector3(x: 3, y: 0, z: 0), duration: 2), forKey: "move")
    cancel.linux_advanceTime(0.5)
    try expect(cancel.action(forKey: "move") != nil, "keyed action")
    cancel.removeAction(forKey: "move")
    let xAfter = cancel.position.x
    cancel.linux_advanceTime(2)
    try expectNear(cancel.position.x, xAfter, "cancelled freeze")

    SCNTransaction.begin()
    SCNTransaction.disableActions = true
    let txn = SCNNode()
    scene.rootNode.addChildNode(txn)
    txn.runAction(SCNAction.move(by: SCNVector3(x: 5, y: 0, z: 0), duration: 1))
    try expectNear(txn.position.x, 0, "disableActions does not complete immediately")
    try expect(txn.hasActions, "action still queued")
    txn.linux_advanceTime(1)
    try expectNear(txn.position.x, 5, "queued action still evaluates")
    SCNTransaction.commit()

    let fader = SCNNode()
    scene.rootNode.addChildNode(fader)
    fader.runAction(SCNAction.fadeOut(duration: 1))
    fader.linux_advanceTime(1)
    try expectNear(Float(fader.opacity), 0, "fade out")
    fader.runAction(SCNAction.hide())
    fader.linux_advanceTime(0)
    try expect(fader.isHidden, "hide")

    let instant = SCNNode()
    scene.rootNode.addChildNode(instant)
    var ran = false
    instant.runAction(SCNAction.run { _ in ran = true })
    instant.linux_advanceTime(0)
    try expect(ran, "run block")

    let body = SCNPhysicsBody.dynamic()
    let physicsNode = SCNNode()
    physicsNode.physicsBody = body
    scene.rootNode.addChildNode(physicsNode)
    let before = physicsNode.position
    scene.physicsWorld.step()
    try expect(SCNVector3EqualToVector3(physicsNode.position, before), "physics fail-closed")

    try expect(scene.write(to: URL(fileURLWithPath: "/tmp/scenekit-linux-export.scn"), options: nil, delegate: nil, progressHandler: nil) == false, "export fail-closed")
    try expect(SCNScene(named: "missing") == nil, "named scene nil")
}

func _transform(_ m: SCNMatrix4, _ p: SCNVector3) -> SCNVector3 {
    SCNVector3(
        x: m.m11 * p.x + m.m21 * p.y + m.m31 * p.z + m.m41,
        y: m.m12 * p.x + m.m22 * p.y + m.m32 * p.z + m.m42,
        z: m.m13 * p.x + m.m23 * p.y + m.m33 * p.z + m.m43
    )
}

func _nearIdentity(_ m: SCNMatrix4) -> Bool {
    let id = SCNMatrix4Identity
    func close(_ a: Float, _ b: Float) -> Bool { abs(a - b) < 1e-4 }
    return close(m.m11, id.m11) && close(m.m22, id.m22) && close(m.m33, id.m33) && close(m.m44, id.m44)
        && close(m.m41, 0) && close(m.m42, 0) && close(m.m43, 0)
}

do {
    try runSceneKitRuntime()
    print("SCENEKIT_AGENT_RUNTIME_OK")
} catch {
    fatalError("SCENEKIT_AGENT_RUNTIME_FAIL \(error)")
}
