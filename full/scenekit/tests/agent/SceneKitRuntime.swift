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

    try exerciseExactMath()
    try exerciseNodeCouplingAndConstraints()
    try exerciseGeometryLayouts()
    try exerciseCameraProjection()
    try exerciseActionsEasing()
    try exerciseCPURasterizer()
    try exerciseSCNViewStores()
    try exerciseHitTest()
    try exerciseDeclaredSurface()
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

func exerciseExactMath() throws {
    let rot = SCNMatrix4MakeRotation(Float.pi / 2, 0, 1, 0)
    let p = _transform(rot, SCNVector3(1, 0, 0))
    try expectNear(p.x, 0, "ry x", eps: 1e-5)
    try expectNear(p.y, 0, "ry y", eps: 1e-5)
    try expectNear(p.z, -1, "ry z", eps: 1e-5)

    // SCNMatrix4Scale(m, s) is Mult(m, MakeScale): with the CPU _transform
    // convention this applies m first, then scale.
    let scaled = SCNMatrix4Scale(SCNMatrix4MakeTranslation(1, 2, 3), 2, 2, 2)
    let q = _transform(scaled, SCNVector3(1, 0, 0))
    try expectNear(q.x, 4, "translate then scale x")
    try expectNear(q.y, 4, "translate then scale y")
    try expectNear(q.z, 6, "translate then scale z")

    let simd3 = SIMD3<Float>(SCNVector3(4, 5, 6))
    try expectNear(simd3.x, 4, "simd3 x")
    try expectNear(SCNVector3(simd3).y, 5, "vector from simd3")
    let simd4 = SIMD4<Float>(SCNVector4(1, 2, 3, 4))
    try expectNear(simd4.w, 4, "simd4 w")

    let node = SCNNode()
    node.rotation = SCNVector4(0, 1, 0, Float.pi / 2)
    try expectNear(node.orientation.w, cos(Float.pi / 4), "quat w from axis-angle", eps: 1e-3)
    node.eulerAngles = SCNVector3(0, Float.pi / 2, 0)
    try expectNear(node.eulerAngles.y, Float.pi / 2, "euler yaw roundtrip", eps: 2e-3)
}

func exerciseNodeCouplingAndConstraints() throws {
    let node = SCNNode()
    node.eulerAngles = SCNVector3(0.3, 0.4, 0.5)
    try expect(abs(node.orientation.w) > 0.1, "orientation from euler")
    let restored = node.eulerAngles
    try expectNear(restored.x, 0.3, "euler x", eps: 2e-3)
    try expectNear(restored.y, 0.4, "euler y", eps: 2e-3)
    try expectNear(restored.z, 0.5, "euler z", eps: 2e-3)

    node.simdPosition = SIMD3<Float>(1, 2, 3)
    try expectNear(node.position.y, 2, "simd position")
    try expectNear(node.simdWorldPosition.x, 1, "simd world")
    node.rotation = SCNVector4(0, 1, 0, Float.pi / 2)
    try expectNear(node.worldPosition.x, 1, "position independent of rotation x")
    try expectNear(node.worldPosition.y, 2, "position independent of rotation y")
    try expectNear(node.worldPosition.z, 3, "position independent of rotation z")

    let scene = SCNScene()
    let target = SCNNode()
    target.name = "look-target"
    target.position = SCNVector3(10, 0, 0)
    let follower = SCNNode()
    follower.position = SCNVector3Zero
    scene.rootNode.addChildNode(target)
    scene.rootNode.addChildNode(follower)
    let look = SCNLookAtConstraint(target: target)
    look.influenceFactor = 1
    follower.constraints = [look]
    follower.linux_advanceTime(0)
    try expect(abs(follower.worldFront.x) > 0.5, "look-at aims at target")

    let dist = SCNDistanceConstraint(target: target)
    dist.minimumDistance = 4
    dist.maximumDistance = 4
    follower.constraints = [dist]
    follower.linux_advanceTime(0)
    let dx = follower.worldPosition.x - target.worldPosition.x
    let dy = follower.worldPosition.y - target.worldPosition.y
    let dz = follower.worldPosition.z - target.worldPosition.z
    let distLen = (dx * dx + dy * dy + dz * dz).squareRoot()
    try expectNear(distLen, 4, "distance clamp", eps: 0.05)

    let billboard = SCNBillboardConstraint()
    billboard.freeAxes = .all
    follower.constraints = [look, dist, billboard]
    follower.linux_advanceTime(0)
    try expect(follower.constraints?.count == 3, "constraint order stored")

    let child = SCNNode(geometry: SCNBox(width: 2, height: 2, length: 2, chamferRadius: 0))
    child.position = SCNVector3(5, 0, 0)
    follower.addChildNode(child)
    let flat = follower.flattenedClone()
    try expect(flat.childNodes.isEmpty, "flattened has no children")
    try expect(flat.geometry != nil, "flattened geometry")
    let cloned = follower.clone()
    try expect(cloned.childNodes.count == 1, "clone keeps children")
}

func exerciseGeometryLayouts() throws {
    let box = SCNBox(width: 2, height: 4, length: 6, chamferRadius: 0)
    try expect(box.widthSegmentCount == 1, "box segments")
    try expect(box.sources(for: .vertex).first?.vectorCount ?? 0 >= 24, "box verts")
    try expect(box.sources(for: .normal).isEmpty == false, "box normals")
    try expect(box.elements.first?.primitiveType == .triangles, "box tris")
    try expectNear(box.boundingBox.max.x, 1, "box bound x")
    try expectNear(box.boundingBox.max.y, 2, "box bound y")
    try expectNear(box.boundingBox.max.z, 3, "box bound z")

    let sphere = SCNSphere(radius: 2)
    try expect(sphere.segmentCount == 24, "sphere default segments")
    try expect(sphere.sources(for: .vertex).first?.vectorCount ?? 0 > 8, "sphere verts")

    let plane = SCNPlane(width: 4, height: 2)
    try expect(plane.sources(for: .vertex).first?.vectorCount == 6, "plane two tris")

    let cyl = SCNCylinder(radius: 1, height: 2)
    try expect(cyl.radialSegmentCount == 24, "cyl radial")
    let cone = SCNCone(topRadius: 0, bottomRadius: 1, height: 2)
    try expect(cone.bottomRadius == 1, "cone")
    let cap = SCNCapsule(capRadius: 0.5, height: 2)
    try expect(cap.capSegmentCount == 24, "capsule")
    let torus = SCNTorus(ringRadius: 1, pipeRadius: 0.2)
    try expect(torus.ringSegmentCount == 24, "torus")
    let tube = SCNTube(innerRadius: 0.5, outerRadius: 1, height: 2)
    try expect(tube.outerRadius == 1, "tube")
    let pyr = SCNPyramid(width: 1, height: 2, length: 1)
    try expect(pyr.height == 2, "pyramid")
    let text = SCNText(string: "A", extrusionDepth: 1)
    try expect((text.string as? String) == "A", "text declared")
    let shape = SCNShape()
    shape.extrusionDepth = 2
    try expect(shape.chamferMode == .both, "shape declared")
    let floor = SCNFloor()
    try expect(floor.reflectivity == 0.25, "floor")

    let floats: [Float] = [0, 0, 0, 1, 0, 0, 0, 1, 0]
    let data = floats.withUnsafeBufferPointer { Data(buffer: $0) }
    let src = SCNGeometrySource(
        data: data, semantic: .vertex, vectorCount: 3,
        usesFloatComponents: true, componentsPerVector: 3, bytesPerComponent: 4,
        dataOffset: 0, dataStride: 12
    )
    let elem = SCNGeometryElement(indices: [UInt16]([0, 1, 2]), primitiveType: .triangles)
    let geom = SCNGeometry(sources: [src], elements: [elem])
    try expect(geom.elementCount == 1, "custom geom")
    geom.subdivisionLevel = 2
    try expect(geom.subdivisionLevel == 2, "subdivision declared")
}

func exerciseCameraProjection() throws {
    let cam = SCNCamera()
    cam.fieldOfView = 90
    cam.zNear = 1
    cam.zFar = 100
    let persp = cam.projectionTransform(withViewportSize: CGSize(width: 100, height: 100))
    let f = 1 / tan(Float.pi / 4)
    try expectNear(persp.m11, f, "persp m11")
    try expectNear(persp.m22, f, "persp m22")
    try expectNear(persp.m34, -1, "persp m34")
    let dz = Float(1 - 100)
    try expectNear(persp.m33, (100 + 1) / dz, "persp m33")
    try expectNear(persp.m43, (2 * 100 * 1) / dz, "persp m43")

    cam.usesOrthographicProjection = true
    cam.orthographicScale = 2
    let ortho = cam.projectionTransform(withViewportSize: CGSize(width: 200, height: 100))
    try expectNear(ortho.m11, 0.25, "ortho m11")
    try expectNear(ortho.m22, 0.5, "ortho m22")
    try expectNear(ortho.m33, -2 / 99, "ortho m33")
}

func exerciseActionsEasing() throws {
    let scene = SCNScene()
    let ease = SCNNode()
    scene.rootNode.addChildNode(ease)
    let move = SCNAction.move(by: SCNVector3(10, 0, 0), duration: 1)
    move.timingMode = .easeIn
    ease.runAction(move)
    ease.linux_advanceTime(0.5)
    try expectNear(ease.position.x, 2.5, "easeIn 0.5^2")

    let out = SCNNode()
    scene.rootNode.addChildNode(out)
    let moveOut = SCNAction.move(by: SCNVector3(10, 0, 0), duration: 1)
    moveOut.timingMode = .easeOut
    out.runAction(moveOut)
    out.linux_advanceTime(0.5)
    try expectNear(out.position.x, 7.5, "easeOut 1-(1-t)^2")

    let group = SCNNode()
    scene.rootNode.addChildNode(group)
    group.runAction(SCNAction.group([
        SCNAction.move(by: SCNVector3(2, 0, 0), duration: 1),
        SCNAction.fadeOut(duration: 1)
    ]))
    group.linux_advanceTime(1)
    try expectNear(group.position.x, 2, "group move")
    try expectNear(Float(group.opacity), 0, "group fade")
}

func exerciseCPURasterizer() throws {
    let scene = SCNScene()
    scene.background.contents = SCNVector3(0, 0, 1)
    let box = SCNBox(width: 2, height: 2, length: 2, chamferRadius: 0)
    let material = SCNMaterial()
    material.lightingModel = .constant
    material.diffuse.contents = SCNVector3(1, 0, 0)
    material.ambient.contents = SCNVector3(0, 0, 0)
    material.isDoubleSided = true
    box.firstMaterial = material
    let cubeNode = SCNNode(geometry: box)
    scene.rootNode.addChildNode(cubeNode)

    let camNode = SCNNode()
    camNode.camera = SCNCamera()
    camNode.camera?.usesOrthographicProjection = true
    camNode.camera?.orthographicScale = 2
    camNode.camera?.zNear = 0.1
    camNode.camera?.zFar = 20
    camNode.position = SCNVector3(0, 0, 5)
    scene.rootNode.addChildNode(camNode)

    let renderer = SCNRenderer()
    renderer.scene = scene
    renderer.pointOfView = camNode
    renderer.currentViewport = CGRect(x: 0, y: 0, width: 32, height: 32)
    let constantImg = renderer.linux_snapshot(size: CGSize(width: 32, height: 32))
    try expect(constantImg.width == 32 && constantImg.height == 32, "raster size")
    let center = constantImg.pixel(x: 16, y: 16)
    try expect(center.0 >= 200, "constant cube red \(center)")
    try expect(center.1 <= 40, "constant cube green \(center)")
    try expect(center.2 <= 40, "constant cube blue \(center)")

    material.lightingModel = .lambert
    let lightNode = SCNNode()
    let light = SCNLight()
    light.type = .directional
    light.intensity = 1000
    light.color = SCNVector3(1, 1, 1)
    lightNode.light = light
    lightNode.position = SCNVector3(0, 0, 5)
    scene.rootNode.addChildNode(lightNode)
    let lambertImg = renderer.linux_snapshot(size: CGSize(width: 32, height: 32))
    let l = lambertImg.pixel(x: 16, y: 16)
    try expect(l.0 >= 200, "lambert red \(l)")

    material.lightingModel = .phong
    material.shininess = 32
    material.specular.contents = SCNVector3(1, 1, 1)
    material.diffuse.contents = SCNVector3(0, 0, 1)
    let phongImg = renderer.linux_snapshot(size: CGSize(width: 32, height: 32))
    try expect(phongImg.pixel(x: 16, y: 16).2 >= 100, "phong blue")

    material.lightingModel = .blinn
    let blinnImg = renderer.linux_snapshot(size: CGSize(width: 32, height: 32))
    try expect(blinnImg.rgba.count == 32 * 32 * 4, "blinn buffer")
}

func exerciseSCNViewStores() throws {
    let view = SCNView(frame: CGRect(x: 0, y: 0, width: 64, height: 64), options: [
        SCNView.Option.preferredRenderingAPI.rawValue: SCNRenderingAPI.metal
    ])
    let scene = SCNScene()
    view.scene = scene
    view.allowsCameraControl = true
    let cam = SCNNode()
    cam.camera = SCNCamera()
    scene.rootNode.addChildNode(cam)
    view.pointOfView = cam
    try expect(view.allowsCameraControl, "camera control store")
    try expect(view.pointOfView === cam, "pov store")
    try expect(view.scene === scene, "scene store")
    view.play(nil)
    try expect(view.isPlaying, "play")
    view.pause(nil)
    try expect(!view.isPlaying, "pause")
    let snap = view.linux_snapshot()
    try expect(snap.width == 64, "view snapshot")
    _ = view.defaultCameraController
    _ = view.cameraControlConfiguration.allowsTranslation
    try expect(SCNView.Option.preferLowPowerDevice.rawValue.contains("LowPower"), "option")
}

func exerciseHitTest() throws {
    let scene = SCNScene()
    let box = SCNBox(width: 2, height: 2, length: 2, chamferRadius: 0)
    let node = SCNNode(geometry: box)
    node.name = "cube"
    scene.rootNode.addChildNode(node)
    let hits = scene.rootNode.hitTestWithSegment(
        from: SCNVector3(0, 0, 5),
        to: SCNVector3(0, 0, -5),
        options: [SCNHitTestOption.sortResults.rawValue: true]
    )
    try expect(!hits.isEmpty, "cpu hit")
    try expect(hits[0].node === node, "hit node")
    try expectNear(hits[0].worldCoordinates.z, 1, "hit +z face", eps: 0.15)

    let hidden = SCNNode(geometry: box)
    hidden.isHidden = true
    hidden.position = SCNVector3(10, 0, 0)
    scene.rootNode.addChildNode(hidden)
    let ignoreHidden = scene.rootNode.hitTestWithSegment(
        from: SCNVector3(10, 0, 5),
        to: SCNVector3(10, 0, -5),
        options: [SCNHitTestOption.ignoreHiddenNodes.rawValue: true]
    )
    try expect(ignoreHidden.isEmpty, "ignore hidden")

    let audio = SCNAudioSource()
    audio.load()
    try expect(audio.volume == 1, "audio fail-closed storage")
    try expect(SCNAudioSource(named: "missing.wav") != nil, "named audio constructs")
}

func exerciseDeclaredSurface() throws {
    try expect(SCNBlendMode.add != .multiply, "blend")
    try expect(SCNTransparencyMode.default == .aOne, "transparency")
    try expect(SCNFillMode.lines != .fill, "fill")
    try expect(SCNCullMode.front != .back, "cull")
    try expect(SCNWrapMode.mirror != .clamp, "wrap")
    try expect(SCNFilterMode.nearest != .linear, "filter")
    try expect(SCNChamferMode.front != .back, "chamfer")
    try expect(SCNAntialiasingMode.multisampling4X.rawValue == 2, "aa")
    try expect(SCNHitTestSearchMode.all != .closest, "search")
    try expect(SCNInteractionMode.pan != .fly, "interaction")
    try expect(SCNLightAreaType.polygon != .rectangle, "area")
    try expect(SCNLightProbeType.radiance != .irradiance, "probe")
    try expect(SCNLightProbeUpdateType.realtime != .never, "probe update")
    try expect(SCNMorpherCalculationMode.additive != .normalized, "morph")
    try expect(SCNMovabilityHint.movable != .fixed, "movability")
    try expect(SCNNodeFocusBehavior.focusable != .none, "focus")
    try expect(SCNReferenceLoadingPolicy.onDemand != .immediate, "ref")
    try expect(SCNRenderingAPI.openGLES2 != .metal, "api")
    try expect(SCNShadowMode.deferred != .forward, "shadow")
    try expect(SCNTessellationSmoothingMode.phong != .none, "tess")
    try expect(SCNGeometryPrimitiveType.polygon != .point, "prim")
    try expect(SCNBufferFrequency.perNode != .perFrame, "buffer")
    try expect(SCNColorMask.all.contains(.red), "color mask")
    try expect(SCNDebugOptions.showWireframe.rawValue != 0, "debug")
    try expect(SCNPhysicsCollisionCategory.static.rawValue != 0, "phys cat")
    try expect(SCNBillboardAxis.Z.rawValue != 0, "billboard z")
    try expect(SCNParticleBlendMode.alpha != .additive, "pblend")
    try expect(SCNParticleSortingMode.distance != .none, "psort")
    try expect(SCNSceneSourceStatus.complete != .error, "src status")
    try expect(SCNActionTimingMode.linear.rawValue == 0, "timing")
    try expect(SCNErrorDomain == "SCNErrorDomain", "error domain")
    try expect(SCN_ENABLE_METAL == 0, "metal flag")
    _ = SCNModelTransform
    _ = SCNViewTransform
    _ = SCNProjectionTransform
    _ = SCNGeometrySource.Semantic.tangent
    _ = SCNMaterial.LightingModel.physicallyBased
    _ = SCNLight.LightType.spot
    _ = SCNScene.Attribute.upAxis
    _ = SCNSceneSource.LoadingOption.flattenScene
    _ = SCNHitTestOption.boundingBoxOnly
    _ = SCNShaderModifierEntryPoint.surface

    let light = SCNLight()
    light.type = .spot
    light.spotOuterAngle = 60
    light.intensity = 500
    light.areaExtents = SIMD3<Float>(2, 1, 0)
    try expectNear(light.areaExtents.x, 2, "light simd extents")
    try expect(light.spotOuterAngle == 60, "light store")
    let cam = SCNCamera()
    cam.wantsHDR = true
    cam.fStop = 2.8
    try expect(cam.wantsHDR, "cam hdr store")
    let mat = SCNMaterial()
    mat.isDoubleSided = true
    mat.blendMode = .add
    mat.transparency = 0.5
    try expect(mat.isDoubleSided && mat.blendMode == .add, "material")
    let morph = SCNMorpher()
    morph.setWeight(0.25, forTargetAt: 0)
    try expectNear(Float(morph.weight(forTargetAt: 0)), 0.25, "morph weight")
    let anim = SCNAnimation()
    anim.duration = 1
    anim.keyPath = "position"
    let player = SCNAnimationPlayer(animation: anim)
    player.play()
    try expect(!player.paused, "anim player")
    let node = SCNNode()
    node.addAnimation(anim, forKey: "pos")
    try expect(node.animationKeys.contains("pos"), "animatable")
    node.pauseAnimation(forKey: "pos")
    try expect(node.isAnimationPaused(forKey: "pos"), "paused")
    SCNTransaction.begin()
    SCNTransaction.animationDuration = 0.25
    var completed = false
    SCNTransaction.completionBlock = { completed = true }
    SCNTransaction.setValue("x", forKey: "k")
    try expect(SCNTransaction.value(forKey: "k") as? String == "x", "txn value")
    SCNTransaction.commit()
    try expect(completed, "txn completion")
    let phys = SCNPhysicsBody.kinematic()
    try expect(phys.type == .kinematic, "phys type")
    let world = SCNPhysicsWorld()
    world.gravity = SCNVector3(0, -9.8, 0)
    world.addBehavior(SCNPhysicsHingeJoint(body: phys, axis: SCNVector3(0, 1, 0), anchor: SCNVector3Zero))
    try expect(world.allBehaviors.count == 1, "behavior")
    let field = SCNPhysicsField.linearGravity()
    try expect(field.isActive, "field")
    let particles = SCNParticleSystem()
    particles.birthRate = 10
    try expect(particles.loops, "particles")
    let src = SCNSceneSource(data: Data(), options: nil)
    try expect((try? src?.scene(options: nil)) == nil, "scene source fail-closed")
    let ref = SCNReferenceNode(url: URL(fileURLWithPath: "/tmp/missing.scn"))
    ref?.load()
    try expect(ref?.isLoaded == false, "reference fail-closed")
    let technique = SCNTechnique(dictionary: ["pass": "none"])
    try expect(technique != nil, "technique")
    let program = SCNProgram()
    program.vertexFunctionName = "v"
    try expect(program.isOpaque, "program")
    let lod = SCNLevelOfDetail(geometry: SCNBox(width: 1, height: 1, length: 1, chamferRadius: 0), screenSpaceRadius: 10)
    try expect(lod.screenSpaceRadius == 10, "lod")
    let tess = SCNGeometryTessellator()
    tess.edgeTessellationFactor = 2
    try expect(tess.smoothingMode == .none, "tessellator")
    let ik = SCNIKConstraint.inverseKinematicsConstraint(chainRootNode: node)
    try expect(ik.chainRootNode === node, "ik")
    let accel = SCNAccelerationConstraint()
    accel.damping = 0.2
    try expect(accel.damping == 0.2, "accel")
    let slider = SCNSliderConstraint()
    slider.radius = 1
    try expect(slider.radius == 1, "slider")
    let repl = SCNReplicatorConstraint()
    repl.replicatesPosition = false
    try expect(!repl.replicatesPosition, "replicator")
    let avoid = SCNAvoidOccluderConstraint()
    avoid.bias = 0.1
    try expect(avoid.bias == 0.1, "avoid")
    let timing = SCNTimingFunction()
    _ = timing
    let event = SCNAnimationEvent(keyTime: 0.5, block: { _, _, _ in })
    try expect(event.time == 0.5, "anim event")
    let vehicle = SCNPhysicsVehicle(chassisBody: phys, wheels: [SCNPhysicsVehicleWheel(node: node)])
    try expect(vehicle.wheels.count == 1, "vehicle")
    let contact = SCNPhysicsContact()
    try expect(contact.collisionImpulse == 0, "contact fail-closed")
    let shape = SCNPhysicsShape(geometry: SCNBox(width: 1, height: 1, length: 1, chamferRadius: 0), options: nil)
    _ = shape
    let controller = SCNCameraController()
    controller.interactionMode = .orbitArcball
    try expect(controller.automaticTarget, "cam controller")
}

do {
    try runSceneKitRuntime()
    print("SCENEKIT_AGENT_RUNTIME_OK")
} catch {
    fatalError("SCENEKIT_AGENT_RUNTIME_FAIL \(error)")
}
