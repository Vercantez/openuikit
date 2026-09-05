import Foundation
import SceneKit

func testCPURasterizer() {
    let scene = SCNScene()
    scene.background.contents = SCNVector3(0, 0, 1)
    let box = SCNBox(width: 2, height: 2, length: 2, chamferRadius: 0)
    let material = SCNMaterial()
    material.lightingModel = .constant
    material.diffuse.contents = SCNVector3(1, 0, 0)
    material.isDoubleSided = true
    box.firstMaterial = material
    scene.rootNode.addChildNode(SCNNode(geometry: box))
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
    renderer.autoenablesDefaultLighting = false
    renderer.isPlaying = false
    renderer.loops = true
    renderer.sceneTime = 0
    renderer.debugOptions = []
    renderer.showsStatistics = false
    let img = renderer.linux_snapshot(size: CGSize(width: 32, height: 32))
    precondition(img.width == 32 && img.height == 32)
    let center = img.pixel(x: 16, y: 16)
    precondition(center.0 >= 200)
    material.lightingModel = .lambert
    let lightNode = SCNNode()
    let light = SCNLight()
    light.type = .directional
    light.intensity = 1000
    light.color = SCNVector3(1, 1, 1)
    lightNode.light = light
    lightNode.position = SCNVector3(0, 0, 5)
    scene.rootNode.addChildNode(lightNode)
    let lambert = renderer.linux_snapshot(size: CGSize(width: 32, height: 32))
    precondition(lambert.pixel(x: 16, y: 16).0 >= 200)
    material.lightingModel = .phong
    material.shininess = 32
    material.specular.contents = SCNVector3(1, 1, 1)
    material.diffuse.contents = SCNVector3(0, 0, 1)
    let phong = renderer.linux_snapshot(size: CGSize(width: 32, height: 32))
    precondition(phong.pixel(x: 16, y: 16).2 >= 100)
    material.lightingModel = .blinn
    let blinn = renderer.linux_snapshot(size: CGSize(width: 32, height: 32))
    precondition(blinn.rgba.count == 32 * 32 * 4)
    renderer.render()
    renderer.render(atTime: 0)
    renderer.update(atTime: 0)
    _ = renderer.projectPoint(SCNVector3Zero)
    _ = renderer.unprojectPoint(SCNVector3Zero)
    _ = renderer.hitTest(CGPoint(x: 16, y: 16), options: nil)
    _ = renderer.nodesInsideFrustum(of: camNode)
    _ = renderer.isNode(camNode, insideFrustumOf: camNode)
    _ = renderer.prepare(box, shouldAbortBlock: nil)
    _ = renderer.renderingAPI
    _ = renderer.currentViewport
    _ = renderer.usesReverseZ
    _ = renderer.context
}
