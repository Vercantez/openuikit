import Foundation
import SpriteKit

func sk_advance(_ scene: SKScene, seconds: TimeInterval, dt: TimeInterval = 1.0 / 60.0) {
    scene.update(0)
    let steps = max(1, Int((seconds / dt).rounded(.up)))
    for index in 1...steps {
        scene.update(TimeInterval(index) * dt)
    }
}

func testNodeSearchSyntaxWildcardAndParent() {
    let root = SKNode()
    root.name = "root"
    let hero = SKNode()
    hero.name = "hero"
    let hat = SKNode()
    hat.name = "hat"
    let decoy = SKNode()
    decoy.name = "helm"
    root.addChild(hero)
    hero.addChild(hat)
    hero.addChild(decoy)
    precondition(root.childNode(withName: "hero") === hero)
    precondition(root.childNode(withName: "//hat") === hat)
    precondition(root.childNode(withName: "*") === hero)
    precondition(hero.childNode(withName: "h*") === hat)
    precondition(hat.childNode(withName: "..") === hero)
    precondition(hat.childNode(withName: "../helm") === decoy)
    var counted = 0
    root.enumerateChildNodes(withName: "//h*") { _, _ in counted += 1 }
    precondition(counted == 3)
    precondition(root["hero/hat"].count == 1)
    let stopName = SKNode()
    stopName.name = "stop"
    root.addChild(stopName)
    var seen = 0
    root.enumerateChildNodes(withName: "*") { _, stop in
        seen += 1
        stop.pointee = true
    }
    precondition(seen == 1)
}

func testNodePausedAndHiddenPropagation() {
    let scene = SKScene(size: CGSize(width: 20, height: 20))
    let parent = SKNode()
    let child = SKNode()
    scene.addChild(parent)
    parent.addChild(child)
    child.run(SKAction.moveBy(x: 10, y: 0, duration: 1))
    parent.isPaused = true
    sk_advance(scene, seconds: 1)
    precondition(abs(child.position.x) < 0.001)
    parent.isPaused = false
    child.removeAllActions()
    parent.isHidden = true
    child.run(SKAction.moveBy(x: 10, y: 0, duration: 0))
    scene.update(2)
    scene.update(3)
    precondition(abs(child.position.x - 10) < 0.001)
    precondition(parent.nodes(at: .zero).filter { $0 === child }.isEmpty)
}

func testNodeAccumulatedFrameInParentSpace() {
    let root = SKNode()
    let sprite = SKSpriteNode(color: .red, size: CGSize(width: 10, height: 10))
    sprite.position = CGPoint(x: 20, y: 0)
    sprite.anchorPoint = CGPoint(x: 0.5, y: 0.5)
    let nested = SKSpriteNode(color: .blue, size: CGSize(width: 10, height: 10))
    nested.position = CGPoint(x: 10, y: 0)
    root.addChild(sprite)
    sprite.addChild(nested)
    let box = root.calculateAccumulatedFrame()
    precondition(box.minX <= 15.1)
    precondition(box.maxX >= 34.9)
}

func testNodeConvertRoundTrip() {
    let root = SKNode()
    let child = SKNode()
    child.position = CGPoint(x: 8, y: 2)
    child.zRotation = 0
    child.setScale(2)
    root.addChild(child)
    let local = CGPoint(x: 1, y: 1)
    let inRoot = child.convert(local, to: root)
    precondition(abs(inRoot.x - 10) < 0.001)
    precondition(abs(inRoot.y - 4) < 0.001)
    let back = child.convert(inRoot, from: root)
    precondition(abs(back.x - 1) < 0.001)
    precondition(abs(back.y - 1) < 0.001)
}

func testSceneTickOrder() {
    final class OrderScene: SKScene {
        var log: [String] = []
        override func update(_ currentTime: TimeInterval) {
            log.append("update")
            super.update(currentTime)
        }
        override func didEvaluateActions() {
            log.append("actions")
            super.didEvaluateActions()
        }
        override func didSimulatePhysics() {
            log.append("physics")
            super.didSimulatePhysics()
        }
        override func didApplyConstraints() {
            log.append("constraints")
            super.didApplyConstraints()
        }
        override func didFinishUpdate() {
            log.append("finish")
            super.didFinishUpdate()
        }
    }
    let scene = OrderScene(size: CGSize(width: 16, height: 16))
    scene.update(1)
    precondition(scene.log == ["update", "actions", "physics", "constraints", "finish"])
}

func testSceneScaleModeViewport() {
    let scene = SKScene(size: CGSize(width: 100, height: 50))
    scene.anchorPoint = .zero
    scene.scaleMode = .aspectFit
    let view = SKView()
    view.bounds = CGRect(x: 0, y: 0, width: 200, height: 200)
    view.presentScene(scene)
    let mapping = SKViewport.mapping(
        sceneSize: scene.size,
        viewSize: view.bounds.size,
        mode: .aspectFit
    )
    precondition(abs(mapping.scaleX - 2) < 0.001)
    precondition(abs(mapping.offsetY - 50) < 0.001)
    let center = scene.convertPoint(fromView: CGPoint(x: 100, y: 100))
    precondition(abs(center.x - 50) < 0.05)
    precondition(abs(center.y - 25) < 0.05)
    let back = scene.convertPoint(toView: center)
    precondition(abs(back.x - 100) < 0.05)
    precondition(abs(back.y - 100) < 0.05)
    scene.scaleMode = .fill
    let fillMap = SKViewport.mapping(sceneSize: scene.size, viewSize: view.bounds.size, mode: .fill)
    precondition(abs(fillMap.scaleX - 2) < 0.001)
    precondition(abs(fillMap.scaleY - 4) < 0.001)
    scene.scaleMode = .aspectFill
    let fillAspect = SKViewport.mapping(sceneSize: scene.size, viewSize: view.bounds.size, mode: .aspectFill)
    precondition(abs(fillAspect.scaleX - 4) < 0.001)
    scene.scaleMode = .resizeFill
    view.presentScene(scene)
    precondition(abs(scene.size.width - 200) < 0.001)
    _ = scene.anchorPoint
    _ = scene.scaleMode
}

func testActionTimingModeDeterministic() {
    let scene = SKScene(size: CGSize(width: 40, height: 40))
    let linear = SKNode()
    let eased = SKNode()
    scene.addChild(linear)
    scene.addChild(eased)
    let moveLinear = SKAction.moveBy(x: 10, y: 0, duration: 1)
    moveLinear.timingMode = .linear
    let moveEase = SKAction.moveBy(x: 10, y: 0, duration: 1)
    moveEase.timingMode = .easeIn
    linear.run(moveLinear)
    eased.run(moveEase)
    scene.update(0)
    for index in 1...30 {
        scene.update(TimeInterval(index) / 60.0)
    }
    precondition(eased.position.x + 0.01 < linear.position.x)
    precondition(linear.position.x > 3)
    precondition(linear.position.x < 7)
}

func testActionReversedMove() {
    let scene = SKScene(size: CGSize(width: 20, height: 20))
    let node = SKNode()
    scene.addChild(node)
    let move = SKAction.moveBy(x: 8, y: 0, duration: 0)
    node.run(move)
    scene.update(0)
    scene.update(1)
    precondition(abs(node.position.x - 8) < 0.001)
    node.run(move.reversed())
    scene.update(2)
    scene.update(3)
    precondition(abs(node.position.x) < 0.001)
    let fade = SKAction.fadeAlpha(by: -0.5, duration: 0)
    node.alpha = 1
    node.run(fade)
    scene.update(4)
    precondition(abs(node.alpha - 0.5) < 0.001)
    node.run(fade.reversed())
    scene.update(5)
    precondition(abs(node.alpha - 1) < 0.001)
}

func testActionFollowPathPolyline() {
    let scene = SKScene(size: CGSize(width: 40, height: 40))
    let node = SKNode()
    scene.addChild(node)
    let path = CGPath(points: [CGPoint(x: 0, y: 0), CGPoint(x: 10, y: 0)])
    let follow = SKAction.follow(path, asOffset: false, orientToPath: true, duration: 1)
    node.run(follow)
    sk_advance(scene, seconds: 1)
    precondition(abs(node.position.x - 10) < 0.2)
    let offsetNode = SKNode()
    offsetNode.position = CGPoint(x: 3, y: 4)
    scene.addChild(offsetNode)
    offsetNode.run(SKAction.follow(path, asOffset: true, orientToPath: false, duration: 0))
    scene.update(2)
    scene.update(3)
    precondition(abs(offsetNode.position.x - 13) < 0.2)
    _ = SKAction.follow(path, duration: 0.1)
    _ = SKAction.follow(path, speed: 10)
}

func testActionSpeedScalesDuration() {
    let scene = SKScene(size: CGSize(width: 20, height: 20))
    let node = SKNode()
    scene.addChild(node)
    let move = SKAction.moveBy(x: 10, y: 0, duration: 1)
    move.speed = 2
    node.run(move)
    scene.update(0)
    for index in 1...30 {
        scene.update(TimeInterval(index) / 60.0)
    }
    precondition(abs(node.position.x - 10) < 0.2)
}

func testSpriteAnchorAndCenterRect() {
    let sprite = SKSpriteNode(color: .red, size: CGSize(width: 20, height: 10))
    sprite.anchorPoint = CGPoint(x: 0, y: 0)
    sprite.position = .zero
    sprite.centerRect = CGRect(x: 0.25, y: 0.25, width: 0.5, height: 0.5)
    precondition(abs(sprite.frame.minX) < 0.001)
    precondition(abs(sprite.frame.width - 20) < 0.001)
    sprite.anchorPoint = CGPoint(x: 0.5, y: 0.5)
    precondition(abs(sprite.frame.minX + 10) < 0.001)
    sprite.scale(to: CGSize(width: 8, height: 4))
    precondition(abs(sprite.size.width - 8) < 0.001)
    _ = sprite.centerRect
}

func testLabelFontMetricFrame() {
    let label = SKLabelNode(text: "ABCD")
    label.fontSize = 20
    label.horizontalAlignmentMode = .left
    label.verticalAlignmentMode = .bottom
    label.position = .zero
    let frame = label.frame
    precondition(abs(frame.width - 40) < 0.001)
    precondition(abs(frame.height - 20) < 0.001)
    precondition(abs(frame.minX) < 0.001)
    label.horizontalAlignmentMode = .center
    precondition(abs(label.frame.minX + 20) < 0.001)
}

func testTexturePNGIHDRAndSubtexture() {
    let png: [UInt8] = [
        137, 80, 78, 71, 13, 10, 26, 10, 0, 0, 0, 13, 73, 72, 68, 82,
        0, 0, 0, 2, 0, 0, 0, 2, 8, 6, 0, 0, 0, 114, 182, 13, 36, 0, 0, 0, 20,
        73, 68, 65, 84, 120, 218, 99, 248, 207, 192, 240, 31, 12, 129, 52, 16,
        48, 252, 7, 0, 71, 202, 8, 248, 91, 154, 164, 190, 0, 0, 0, 0,
        73, 69, 78, 68, 174, 66, 96, 130,
    ]
    let texture = SKTexture(data: Data(png), size: CGSize(width: 1, height: 1))
    precondition(abs(texture.size().width - 2) < 0.001)
    precondition(abs(texture.size().height - 2) < 0.001)
    texture.filteringMode = .nearest
    precondition(texture.filteringMode == .nearest)
    let sub = SKTexture(rect: CGRect(x: 0, y: 0, width: 0.5, height: 0.5), in: texture)
    precondition(abs(sub.size().width - 1) < 0.001)
    precondition(abs(sub.textureRect().width - 0.5) < 0.001)
}

func testTextureAtlasFromPlistAndFolder() {
    let folder = NSTemporaryDirectory() + "sk-atlas-\(ProcessInfo.processInfo.globallyUniqueString)"
    try! FileManager.default.createDirectory(atPath: folder, withIntermediateDirectories: true)
    let png: [UInt8] = [
        137, 80, 78, 71, 13, 10, 26, 10, 0, 0, 0, 13, 73, 72, 68, 82,
        0, 0, 0, 2, 0, 0, 0, 2, 8, 6, 0, 0, 0, 114, 182, 13, 36, 0, 0, 0, 20,
        73, 68, 65, 84, 120, 218, 99, 248, 207, 192, 240, 31, 12, 129, 52, 16,
        48, 252, 7, 0, 71, 202, 8, 248, 91, 154, 164, 190, 0, 0, 0, 0,
        73, 69, 78, 68, 174, 66, 96, 130,
    ]
    let pngPath = (folder as NSString).appendingPathComponent("hero.png")
    precondition(FileManager.default.createFile(atPath: pngPath, contents: Data(png)))
    let folderAtlas = SKTextureAtlas(named: folder)
    precondition(folderAtlas.textureNames.contains("hero"))
    precondition(abs(folderAtlas.textureNamed("hero").size().width - 2) < 0.001)
    let plistPath = NSTemporaryDirectory() + "sk-atlas-\(ProcessInfo.processInfo.globallyUniqueString).plist"
    let plist: [String: Any] = [
        "frames": [
            "coin": ["width": 8, "height": 4],
        ],
    ]
    let plistData = try! PropertyListSerialization.data(fromPropertyList: plist, format: .xml, options: 0)
    precondition(FileManager.default.createFile(atPath: plistPath, contents: plistData))
    let plistAtlas = SKTextureAtlas(named: plistPath)
    precondition(plistAtlas.textureNames.contains("coin"))
    precondition(abs(plistAtlas.textureNamed("coin").size().width - 8) < 0.001)
}

func testPhysicsMassDensityArea() {
    let body = SKPhysicsBody(circleOfRadius: 2)
    precondition(abs(body.area - (.pi * 4)) < 0.01)
    precondition(abs(body.mass - body.area) < 0.01)
    body.density = 2
    precondition(abs(body.mass - 2 * body.area) < 0.01)
    body.mass = 10
    precondition(abs(body.density - 10 / body.area) < 0.01)
    let box = SKPhysicsBody(rectangleOf: CGSize(width: 4, height: 3))
    precondition(abs(box.area - 12) < 0.001)
    body.categoryBitMask = 1
    body.collisionBitMask = 2
    body.contactTestBitMask = 4
    precondition(body.categoryBitMask == 1)
    _ = SKPhysicsBody(polygonFrom: CGPath(rect: CGRect(x: 0, y: 0, width: 2, height: 2)))
    _ = SKPhysicsBody(edgeFrom: .zero, to: CGPoint(x: 1, y: 0))
}

func testPhysicsCircleCollisionAndContacts() {
    let scene = SKScene(size: CGSize(width: 80, height: 80))
    scene.physicsWorld.gravity = CGVector(dx: 0, dy: 0)
    let left = SKNode()
    left.position = CGPoint(x: 0, y: 0)
    left.physicsBody = SKPhysicsBody(circleOfRadius: 5)
    left.physicsBody?.isDynamic = true
    left.physicsBody?.affectedByGravity = false
    left.physicsBody?.categoryBitMask = 1
    left.physicsBody?.collisionBitMask = 1
    left.physicsBody?.contactTestBitMask = 1
    let right = SKNode()
    right.position = CGPoint(x: 6, y: 0)
    right.physicsBody = SKPhysicsBody(circleOfRadius: 5)
    right.physicsBody?.isDynamic = true
    right.physicsBody?.affectedByGravity = false
    right.physicsBody?.categoryBitMask = 1
    right.physicsBody?.collisionBitMask = 1
    right.physicsBody?.contactTestBitMask = 1
    scene.addChild(left)
    scene.addChild(right)
    final class Probe: NSObject, SKPhysicsContactDelegate {
        var began = 0
        var ended = 0
        func didBegin(_ contact: SKPhysicsContact) {
            began += 1
            _ = contact.contactNormal
        }
        func didEnd(_ contact: SKPhysicsContact) { ended += 1 }
    }
    let probe = Probe()
    scene.physicsWorld.contactDelegate = probe
    scene.update(0)
    scene.update(1.0 / 60.0)
    precondition(probe.began > 0)
    precondition(right.position.x - left.position.x >= 9.9)
    left.position = CGPoint(x: -40, y: 0)
    right.position = CGPoint(x: 40, y: 0)
    scene.update(2.0 / 60.0)
    scene.update(3.0 / 60.0)
    precondition(probe.ended > 0)
}

func testConstraintOrientPositionDistance() {
    let scene = SKScene(size: CGSize(width: 80, height: 80))
    let node = SKNode()
    node.position = CGPoint(x: 20, y: 0)
    scene.addChild(node)
    node.constraints = [SKConstraint.positionX(SKRange(lowerLimit: 0, upperLimit: 5))]
    scene.update(0)
    scene.update(0.1)
    precondition(abs(node.position.x - 5) < 0.001)
    let target = SKNode()
    target.position = CGPoint(x: 0, y: 10)
    scene.addChild(target)
    node.position = CGPoint(x: 0, y: 0)
    node.constraints = [SKConstraint.orient(to: target, offset: SKRange(constantValue: 0))]
    scene.update(0.2)
    scene.update(0.3)
    precondition(abs(node.zRotation - CGFloat.pi / 2) < 0.05)
    _ = SKConstraint.orient(to: CGPoint(x: 1, y: 0), offset: SKRange(constantValue: 0))
    _ = SKConstraint.distance(SKRange(lowerLimit: 0, upperLimit: 10), to: target)
    node.position = CGPoint(x: 40, y: 0)
    node.constraints = [SKConstraint.distance(SKRange(lowerLimit: 0, upperLimit: 10), to: .zero)]
    scene.update(0.4)
    scene.update(0.5)
    let distance = (node.position.x * node.position.x + node.position.y * node.position.y).squareRoot()
    precondition(distance <= 10.01)
}

func testCameraContainedNodeSet() {
    let scene = SKScene(size: CGSize(width: 100, height: 100))
    let camera = SKCameraNode()
    camera.position = CGPoint(x: 50, y: 50)
    scene.addChild(camera)
    scene.camera = camera
    let inside = SKSpriteNode(color: .red, size: CGSize(width: 4, height: 4))
    inside.position = CGPoint(x: 50, y: 50)
    let outside = SKSpriteNode(color: .blue, size: CGSize(width: 4, height: 4))
    outside.position = CGPoint(x: 400, y: 400)
    scene.addChild(inside)
    scene.addChild(outside)
    precondition(camera.contains(inside))
    precondition(!camera.contains(outside))
}

func testSoftwareRasterSprite() {
    let sprite = SKSpriteNode(color: .red, size: CGSize(width: 4, height: 4))
    sprite.anchorPoint = CGPoint(x: 0, y: 0)
    sprite.position = .zero
    let view = SKView()
    let texture = view.texture(from: sprite)
    precondition(texture != nil)
    let image = texture!.cgImage()
    precondition(image.width >= 1)
    precondition(image.pixels[0] == 255)
    precondition(image.pixels[1] == 0)
    let shape = SKShapeNode(rectOf: CGSize(width: 4, height: 4))
    shape.fillColor = .blue
    let shaped = view.texture(from: shape, crop: CGRect(x: -2, y: -2, width: 4, height: 4))
    precondition(shaped != nil)
}

func testRendererCPUUpdateFailClosedGPU() {
    let scene = SKScene(size: CGSize(width: 12, height: 12))
    let node = SKNode()
    scene.addChild(node)
    node.run(SKAction.moveBy(x: 4, y: 0, duration: 0))
    let renderer = SKRenderer()
    renderer.scene = scene
    renderer.ignoresSiblingOrder = true
    renderer.shouldCullNonVisibleNodes = true
    renderer.showsDrawCount = false
    renderer.showsFields = false
    renderer.showsNodeCount = true
    renderer.showsPhysics = false
    renderer.showsQuadCount = false
    renderer.update(atTime: 0)
    renderer.update(atTime: 1)
    precondition(abs(node.position.x - 4) < 0.001)
    _ = renderer.scene
}
