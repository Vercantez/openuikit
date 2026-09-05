import Foundation
import SpriteKit

func testSpriteAndLabel() {
    let sprite = SKSpriteNode(color: .red, size: CGSize(width: 16, height: 8))
    sprite.anchorPoint = CGPoint(x: 0.5, y: 0.5)
    sprite.colorBlendFactor = 1
    sprite.blendMode = .add
    sprite.centerRect = CGRect(x: 0, y: 0, width: 1, height: 1)
    sprite.lightingBitMask = 1
    sprite.shadowCastBitMask = 1
    sprite.shadowedBitMask = 1
    sprite.scale(to: CGSize(width: 20, height: 10))
    precondition(sprite.size.width == 20)
    let named = SKSpriteNode(imageNamed: "hero")
    _ = SKSpriteNode(imageNamed: "hero", normalMapped: true)
    _ = SKSpriteNode(texture: named.texture)
    _ = SKSpriteNode(texture: named.texture, size: CGSize(width: 4, height: 4))
    _ = SKSpriteNode(texture: named.texture, normalMap: nil)
    _ = SKSpriteNode(texture: named.texture, color: .white, size: CGSize(width: 4, height: 4))
    let label = SKLabelNode(text: "hi")
    label.fontName = "Helvetica"
    label.fontSize = 18
    label.fontColor = .white
    label.color = .red
    label.colorBlendFactor = 0
    label.blendMode = .alpha
    label.horizontalAlignmentMode = .left
    label.verticalAlignmentMode = .top
    label.numberOfLines = 2
    label.lineBreakMode = .byWordWrapping
    label.preferredMaxLayoutWidth = 100
    label.attributedText = NSAttributedString(string: "hi")
    _ = SKLabelNode(fontNamed: "Helvetica")
    _ = SKLabelNode(attributedText: NSAttributedString(string: "x"))
    _ = label.frame
}

func testShapeNodeConstructors() {
    let rect = SKShapeNode(rect: CGRect(x: 0, y: 0, width: 10, height: 6))
    rect.fillColor = .red
    rect.strokeColor = .white
    rect.lineWidth = 2
    rect.glowWidth = 0
    rect.isAntialiased = true
    rect.lineCap = .round
    rect.lineJoin = .round
    rect.miterLimit = 10
    rect.blendMode = .alpha
    precondition(rect.lineLength > 0)
    _ = SKShapeNode(rect: CGRect(x: 0, y: 0, width: 4, height: 4), cornerRadius: 1)
    _ = SKShapeNode(rectOf: CGSize(width: 4, height: 4))
    _ = SKShapeNode(rectOfSize: CGSize(width: 4, height: 4))
    _ = SKShapeNode(rectOf: CGSize(width: 4, height: 4), cornerRadius: 1)
    _ = SKShapeNode(rectOfSize: CGSize(width: 4, height: 4), cornerRadius: 1)
    _ = SKShapeNode(circleOfRadius: 3)
    _ = SKShapeNode(ellipseIn: CGRect(x: 0, y: 0, width: 4, height: 2))
    _ = SKShapeNode(ellipseInRect: CGRect(x: 0, y: 0, width: 4, height: 2))
    _ = SKShapeNode(ellipseOf: CGSize(width: 4, height: 2))
    _ = SKShapeNode(ellipseOfSize: CGSize(width: 4, height: 2))
    var points = [CGPoint(x: 0, y: 0), CGPoint(x: 1, y: 0), CGPoint(x: 1, y: 1)]
    _ = points.withUnsafeMutableBufferPointer { SKShapeNode(points: $0.baseAddress!, count: 3) }
    _ = points.withUnsafeMutableBufferPointer { SKShapeNode(splinePoints: $0.baseAddress!, count: 3) }
    let path = CGPath(rect: CGRect(x: 0, y: 0, width: 2, height: 2))
    _ = SKShapeNode(path: path)
    _ = SKShapeNode(path: path, centered: true)
}

func testTextureAndAtlas() {
    let data = Data(repeating: 255, count: 16)
    let tex = SKTexture(data: data, size: CGSize(width: 2, height: 2))
    precondition(tex.size() == CGSize(width: 2, height: 2))
    _ = tex.textureRect()
    _ = tex.cgImage()
    tex.filteringMode = .nearest
    tex.usesMipmaps = false
    _ = tex.generatingNormalMap()
    _ = tex.generatingNormalMap(withSmoothness: 0.5, contrast: 1)
    tex.preload { }
    _ = SKTexture(data: data, size: CGSize(width: 2, height: 2), flipped: true)
    _ = SKTexture(data: data, size: CGSize(width: 2, height: 2), rowLength: 8, alignment: 4)
    _ = SKTexture(imageNamed: "star")
    _ = SKTexture(rect: CGRect(x: 0, y: 0, width: 0.5, height: 0.5), in: tex)
    _ = SKTexture(rect: CGRect(x: 0, y: 0, width: 0.5, height: 0.5), inTexture: tex)
    let img = tex.cgImage()
    _ = SKTexture(cgImage: img)
    _ = SKTexture(CGImage: img)
    _ = SKTexture(noiseWithSmoothness: 0.5, size: CGSize(width: 4, height: 4), grayscale: true)
    _ = SKTexture(vectorNoiseWithSmoothness: 0.2, size: CGSize(width: 4, height: 4))
    let mutable = SKMutableTexture(size: CGSize(width: 2, height: 2))
    mutable.modifyPixelData { _, _ in }
    _ = SKMutableTexture(size: CGSize(width: 2, height: 2), pixelFormat: 0)
    let atlas = SKTextureAtlas(named: "pack")
    _ = atlas.textureNamed("a")
    _ = atlas.textureNames
    atlas.preload { }
    _ = SKTextureAtlas(dictionary: ["a": "a"])
}

func testSceneViewCameraTransition() {
    let scene = SKScene(size: CGSize(width: 320, height: 240))
    scene.scaleMode = .aspectFit
    scene.backgroundColor = .black
    scene.anchorPoint = CGPoint(x: 0.5, y: 0.5)
    scene.sceneDidLoad()
    scene.didChangeSize(CGSize(width: 1, height: 1))
    let view = SKView()
    view.preferredFramesPerSecond = 30
    view.preferredFrameRate = 30
    view.frameInterval = 2
    view.isPaused = false
    view.isAsynchronous = true
    view.ignoresSiblingOrder = true
    view.shouldCullNonVisibleNodes = true
    view.allowsTransparency = false
    view.disableDepthStencilBuffer = true
    view.showsFPS = true
    view.showsNodeCount = true
    view.showsDrawCount = true
    view.showsQuadCount = true
    view.showsPhysics = true
    view.showsFields = true
    final class SceneProbe: NSObject, SKSceneDelegate {
        var updates = 0
        func update(_ currentTime: TimeInterval, for scene: SKScene) { updates += 1 }
        func didEvaluateActions(for scene: SKScene) {}
        func didSimulatePhysics(for scene: SKScene) {}
        func didApplyConstraints(for scene: SKScene) {}
        func didFinishUpdate(for scene: SKScene) {}
    }
    final class ViewProbe: NSObject, SKViewDelegate {
        func view(_ view: SKView, shouldRenderAtTime time: TimeInterval) -> Bool { true }
    }
    let sceneProbe = SceneProbe()
    scene.delegate = sceneProbe
    let viewProbe = ViewProbe()
    view.delegate = viewProbe
    view.presentScene(scene)
    precondition(view.scene === scene)
    precondition(scene.view === view)
    let next = SKScene(size: scene.size)
    let fade = SKTransition.fade(withDuration: 0.1)
    fade.pausesIncomingScene = true
    fade.pausesOutgoingScene = true
    view.presentScene(next, transition: fade)
    _ = SKTransition.crossFade(withDuration: 0.1)
    _ = SKTransition.doorway(withDuration: 0.1)
    _ = SKTransition.doorsOpenHorizontal(withDuration: 0.1)
    _ = SKTransition.doorsOpenVertical(withDuration: 0.1)
    _ = SKTransition.doorsCloseHorizontal(withDuration: 0.1)
    _ = SKTransition.doorsCloseVertical(withDuration: 0.1)
    _ = SKTransition.flipHorizontal(withDuration: 0.1)
    _ = SKTransition.flipVertical(withDuration: 0.1)
    _ = SKTransition.moveIn(with: .up, duration: 0.1)
    _ = SKTransition.push(with: .down, duration: 0.1)
    _ = SKTransition.reveal(with: .left, duration: 0.1)
    _ = SKTransition.fade(with: .white, duration: 0.1)
    let cam = SKCameraNode()
    scene.camera = cam
    scene.addChild(cam)
    _ = cam.contains(scene)
    _ = cam.containedNodeSet()
    let p = scene.convertPoint(fromView: CGPoint(x: 10, y: 10))
    _ = scene.convertPoint(toView: p)
    _ = view.convert(CGPoint.zero, from: scene)
    _ = view.convert(CGPoint.zero, to: scene)
    _ = view.texture(from: SKNode())
    _ = view.texture(from: SKNode(), crop: CGRect(x: 0, y: 0, width: 4, height: 4))
    scene.didMove(to: view)
    scene.willMove(from: view)
    scene.update(1)
    scene.didEvaluateActions()
    scene.didSimulatePhysics()
    scene.didApplyConstraints()
    scene.didFinishUpdate()
    _ = scene.physicsWorld
    _ = scene.listener
}

func testCropEffectLightAudioVideo() {
    let crop = SKCropNode()
    crop.maskNode = SKNode()
    let effect = SKEffectNode()
    effect.shouldEnableEffects = true
    effect.shouldCenterFilter = true
    effect.shouldRasterize = false
    effect.blendMode = .multiply
    let light = SKLightNode()
    light.isEnabled = true
    light.falloff = 1
    light.categoryBitMask = 1
    light.ambientColor = .black
    light.lightColor = .white
    light.shadowColor = .black
    let audio = SKAudioNode(fileNamed: "x.caf")
    audio.autoplayLooped = true
    audio.isPositional = true
    _ = SKAudioNode(url: URL(fileURLWithPath: "/tmp/x.caf"))
    _ = SKAudioNode(URL: URL(fileURLWithPath: "/tmp/x.caf"))
    let video = SKVideoNode(fileNamed: "x.mov")
    video.size = CGSize(width: 8, height: 8)
    video.anchorPoint = CGPoint(x: 0.5, y: 0.5)
    video.play()
    video.pause()
    _ = SKVideoNode(url: URL(fileURLWithPath: "/tmp/x.mov"))
    _ = SKVideoNode(URL: URL(fileURLWithPath: "/tmp/x.mov"))
    _ = SKVideoNode(videoURL: URL(fileURLWithPath: "/tmp/x.mov"))
    _ = SKVideoNode(videoFileNamed: "x.mov")
    let ref = SKReferenceNode(fileNamed: "missing.sks")
    ref.resolve()
    ref.didLoad(nil)
    _ = SKReferenceNode(url: URL(fileURLWithPath: "/tmp/x.sks"))
    _ = SKReferenceNode(URL: URL(fileURLWithPath: "/tmp/x.sks"))
    let xf = SKTransformNode()
    xf.xRotation = 0.1
    xf.yRotation = 0.2
    xf.setEulerAngles(SIMD3<Float>(0, 0, 0))
    _ = xf.eulerAngles()
    xf.setQuaternion(simd_quatf())
    _ = xf.quaternion()
    xf.setRotationMatrix(matrix_float3x3())
    _ = xf.rotationMatrix()
    let n3 = SK3DNode(viewportSize: CGSize(width: 8, height: 8))
    n3.loops = true
    n3.isPlaying = false
    n3.autoenablesDefaultLighting = false
    n3.sceneTime = 0
    _ = n3.projectPoint(SIMD3<Float>(0, 0, 0))
    _ = n3.unprojectPoint(SIMD3<Float>(0, 0, 0))
}
