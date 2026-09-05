import Foundation
import GameplayKit

private final class DummyRoot: NSObject, GKSceneRootNodeType {}

func testSceneBookkeeping() {
    let scene = GKScene()
    let entity = GKEntity()
    scene.addEntity(entity)
    precondition(scene.entities.count == 1)
    let a = GKGraphNode2D(point: SIMD2<Float>(0, 0))
    let graph = GKGraph(nodes: [a])
    scene.addGraph(graph, name: "main")
    precondition(scene.graphs["main"] === graph)
    scene.removeGraph("main")
    precondition(scene.graphs["main"] == nil)
    scene.removeEntity(entity)
    precondition(scene.entities.isEmpty)
    let root = DummyRoot()
    scene.rootNode = root
    precondition(scene.rootNode === root)
    let copy = scene.copy() as! GKScene
    _ = copy.entities
}

func testSceneFileNamedFailClosed() {
    precondition(GKScene(fileNamed: "missing.gkscene") == nil)
    precondition(GKScene(fileNamed: "missing.gkscene", rootNode: DummyRoot()) == nil)
}
