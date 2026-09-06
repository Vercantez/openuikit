import Foundation
import SceneKit

func testHitTestSegment() {
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
    precondition(!hits.isEmpty)
    precondition(hits[0].node === node)
    precondition(abs(hits[0].worldCoordinates.z - 1) < 0.15)
    _ = hits[0].localCoordinates
    _ = hits[0].localNormal
    _ = hits[0].worldNormal
    _ = hits[0].modelTransform
    _ = hits[0].geometryIndex
    _ = hits[0].faceIndex
    _ = hits[0].simdLocalCoordinates
    _ = hits[0].simdWorldCoordinates
    _ = hits[0].simdLocalNormal
    _ = hits[0].simdWorldNormal
    _ = hits[0].textureCoordinates(withMappingChannel: 0)
    let hidden = SCNNode(geometry: box)
    hidden.isHidden = true
    hidden.position = SCNVector3(10, 0, 0)
    scene.rootNode.addChildNode(hidden)
    let ignoreHidden = scene.rootNode.hitTestWithSegment(
        from: SCNVector3(10, 0, 5),
        to: SCNVector3(10, 0, -5),
        options: [SCNHitTestOption.ignoreHiddenNodes.rawValue: true]
    )
    precondition(ignoreHidden.isEmpty)
}

func testHitTestResultBoneNode() {
    let result = SCNHitTestResult()
    precondition(result.boneNode == nil)
    _ = SCNHitTestResult.self
}

func testHitTestFailClosedWithoutScene() {
    let renderer = SCNRenderer()
    renderer.scene = nil
    let empty = renderer.hitTest(CGPoint(x: 16, y: 16), options: nil)
    precondition(empty.isEmpty)
    let view = SCNView(frame: CGRect(x: 0, y: 0, width: 32, height: 32), options: nil)
    view.scene = nil
    precondition(view.hitTest(CGPoint.zero, options: nil).isEmpty)
}
