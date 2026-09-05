import Foundation
import SceneKit

func testNodeHierarchy() {
    let scene = SCNScene()
    let parent = SCNNode()
    parent.name = "parent"
    let child = SCNNode()
    child.name = "child"
    scene.rootNode.addChildNode(parent)
    parent.addChildNode(child)
    precondition(child.parent === parent)
    precondition(parent.childNodes.count == 1)
    precondition(scene.rootNode.childNode(withName: "child", recursively: true) === child)
    parent.addChildNode(parent)
    precondition(parent.childNodes.filter { $0 === parent }.isEmpty)
    child.addChildNode(parent)
    precondition(child.childNodes.filter { $0 === parent }.isEmpty)
    parent.insertChildNode(SCNNode(), at: 0)
    var enumerated = 0
    scene.rootNode.enumerateHierarchy { _, _ in enumerated += 1 }
    precondition(enumerated >= 3)
    var walk = 0
    scene.rootNode.enumerateChildNodes { _, stop in
        walk += 1
        if walk > 10_000 { stop.pointee = true }
    }
    _ = parent.childNodes(passingTest: { _, _ in true })
    let extra = SCNNode()
    parent.replaceChildNode(child, with: extra)
    extra.removeFromParentNode()
}

func testNodeTransforms() {
    let parent = SCNNode()
    let child = SCNNode()
    parent.addChildNode(child)
    child.position = SCNVector3(x: 1, y: 0, z: 0)
    parent.position = SCNVector3(x: 10, y: 0, z: 0)
    precondition(abs(child.worldPosition.x - 11) < 1e-4)
    let local = parent.convertPosition(child.worldPosition, from: nil)
    precondition(abs(local.x - 1) < 1e-4)
    _ = parent.convertPosition(child.position, to: nil)
    _ = parent.convertVector(SCNVector3(0, 1, 0), from: nil)
    _ = parent.convertVector(SCNVector3(0, 1, 0), to: nil)
    _ = parent.convertTransform(SCNMatrix4Identity, from: nil)
    _ = parent.convertTransform(SCNMatrix4Identity, to: nil)
    child.scale = SCNVector3(2, 2, 2)
    child.pivot = SCNMatrix4Identity
    child.localTranslate(by: SCNVector3(0.5, 0, 0))
    child.localRotate(by: SCNVector4(0, 1, 0, 0.1))
    child.look(at: SCNVector3(0, 0, 1))
    child.look(at: SCNVector3(1, 0, 0), up: SCNNode.localUp, localFront: SCNNode.localFront)
    _ = SCNNode.localRight
    _ = SCNNode.localUp
    _ = SCNNode.localFront
    _ = child.worldUp
    _ = child.worldRight
    _ = child.worldFront
    _ = child.worldOrientation
    _ = child.worldTransform
    _ = child.transform
    child.setWorldTransform(SCNMatrix4MakeTranslation(1, 2, 3))
    child.simdPosition = SIMD3<Float>(1, 2, 3)
    precondition(abs(child.position.y - 2) < 1e-4)
    _ = child.simdWorldPosition
    _ = child.simdEulerAngles
    _ = child.simdRotation
    _ = child.simdScale
    _ = child.simdWorldFront
    _ = child.simdWorldRight
    _ = child.simdWorldUp
    _ = SCNNode.simdLocalFront
    _ = SCNNode.simdLocalRight
    _ = SCNNode.simdLocalUp
    _ = child.simdConvertPosition(SIMD3<Float>(0, 0, 0), from: nil)
    _ = child.simdConvertPosition(SIMD3<Float>(0, 0, 0), to: nil)
    _ = child.simdConvertVector(SIMD3<Float>(0, 1, 0), from: nil)
    _ = child.simdConvertVector(SIMD3<Float>(0, 1, 0), to: nil)
    child.simdLocalTranslate(by: SIMD3<Float>(0, 0, 0))
    child.simdLook(at: SIMD3<Float>(0, 0, 1))
    child.opacity = 0.5
    child.isHidden = false
    child.categoryBitMask = 1
    child.castsShadow = true
    child.renderingOrder = 0
    child.movabilityHint = .fixed
    child.focusBehavior = .none
    child.isPaused = false
    _ = child.presentation
}

func testNodeCloneAndBounds() {
    let node = SCNNode(geometry: SCNBox(width: 2, height: 2, length: 2, chamferRadius: 0))
    node.position = SCNVector3(5, 0, 0)
    let cloned = node.clone()
    precondition(cloned !== node)
    let flat = node.flattenedClone()
    precondition(flat.childNodes.isEmpty)
    _ = node.boundingBox
    _ = node.boundingSphere
    node.rotate(by: SCNVector4(0, 1, 0, 0.2), aroundTarget: SCNVector3Zero)
}

func testNodeAudioAndParticlesAttach() {
    let node = SCNNode()
    let player = SCNAudioPlayer(source: SCNAudioSource())
    node.addAudioPlayer(player)
    _ = node.audioPlayers
    node.removeAudioPlayer(player)
    node.removeAllAudioPlayers()
    let parts = SCNParticleSystem()
    node.addParticleSystem(parts)
    _ = node.particleSystems
    node.removeParticleSystem(parts)
    node.removeAllParticleSystems()
}
