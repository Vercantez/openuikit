import Foundation
import GameplayKit

func testGraphAStarAndEdges() {
    let a = GKGraphNode2D(point: SIMD2<Float>(0, 0))
    let b = GKGraphNode2D(point: SIMD2<Float>(1, 0))
    let c = GKGraphNode2D(point: SIMD2<Float>(1, 1))
    a.addConnections(to: [b], bidirectional: true)
    b.addConnections(to: [c], bidirectional: true)
    precondition(a.connectedNodes.count == 1)
    let path = a.findPath(to: c)
    precondition(path.count == 3)
    precondition(c.findPath(from: a).count == 3)
    let graph = GKGraph(nodes: [a, b, c])
    precondition(graph.nodes?.count == 3)
    precondition(graph.findPath(from: a, to: c).count == 3)
    let extra = GKGraphNode2D.node(withPoint: SIMD2<Float>(2, 0))
    graph.add([extra])
    graph.connectToLowestCostNode(node: extra, bidirectional: true)
    precondition(!extra.connectedNodes.isEmpty)
    graph.remove([extra])

    let start = GKGraphNode2D(point: SIMD2<Float>(0, 0))
    precondition(start.findPath(to: start).isEmpty)
    let cycleA = GKGraphNode2D(point: SIMD2<Float>(0, 0))
    let cycleB = GKGraphNode2D(point: SIMD2<Float>(1, 0))
    let cycleC = GKGraphNode2D(point: SIMD2<Float>(1, 1))
    cycleA.addConnections(to: [cycleB], bidirectional: true)
    cycleB.addConnections(to: [cycleC], bidirectional: true)
    cycleC.addConnections(to: [cycleA], bidirectional: true)
    let cyclic = cycleA.findPath(to: cycleC)
    precondition(cyclic.first === cycleA && cyclic.last === cycleC)
    precondition(cyclic.count >= 2)
    let disconnected = GKGraphNode2D(point: SIMD2<Float>(50, 50))
    precondition(a.findPath(to: disconnected).isEmpty)
    cycleA.removeConnections(to: [cycleB], bidirectional: true)
    precondition(cycleA.cost(to: cycleA) == 0)
    _ = cycleA.estimatedCost(to: cycleC)
    let viaInit = GKGraph([a, b])
    precondition(viaInit.nodes?.count == 2)
}

func testGridGraphLookupAndPath() {
    let grid = GKGridGraph<GKGridGraphNode>(
        fromGridStartingAt: SIMD2<Int32>(0, 0),
        width: 4,
        height: 4,
        diagonalsAllowed: false
    )
    precondition(grid.gridWidth == 4)
    precondition(grid.gridHeight == 4)
    precondition(grid.gridOrigin == SIMD2<Int32>(0, 0))
    precondition(grid.diagonalsAllowed == false)
    let start = grid.node(atGridPosition: SIMD2<Int32>(0, 0))
    let end = grid.node(atGridPosition: SIMD2<Int32>(3, 0))
    precondition(start != nil && end != nil)
    let gridPath = grid.findPath(from: start!, to: end!)
    precondition(gridPath.count == 4)
    let standalone = GKGridGraphNode(gridPosition: SIMD2<Int32>(1, 1))
    precondition(standalone.gridPosition.x == 1)
    grid.connectToAdjacentNodes(node: standalone)
    _ = grid.classForGenericArgument(at: 0)
    let withClass = GKGridGraph<GKGridGraphNode>(
        fromGridStartingAt: SIMD2<Int32>(0, 0),
        width: 2,
        height: 2,
        diagonalsAllowed: true,
        nodeClass: GKGridGraphNode.self
    )
    precondition(withClass.diagonalsAllowed)
    let fromNodes = GKGridGraph<GKGridGraphNode>(nodes: [standalone])
    precondition(fromNodes.nodes?.count == 1)
}

func testGraphNode3DAndCopyIndependence() {
    let node = GKGraphNode3D(point: SIMD3<Float>(1, 2, 3))
    precondition(node.position.z == 3)
    let factory = GKGraphNode3D.node(withPoint: SIMD3<Float>(4, 5, 6))
    precondition(factory.position.y == 5)
    let copy = node.copy() as! GKGraphNode3D
    copy.position = SIMD3<Float>(9, 9, 9)
    precondition(node.position == SIMD3<Float>(1, 2, 3))

    let a = GKGraphNode2D(point: SIMD2<Float>(3, 4))
    let nodeCopy = a.copy() as! GKGraphNode2D
    nodeCopy.position = SIMD2<Float>(9, 9)
    precondition(a.position == SIMD2<Float>(3, 4))
    let peer = GKGraphNode2D(point: SIMD2<Float>(1, 0))
    a.addConnections(to: [peer], bidirectional: true)
    let graph = GKGraph(nodes: [a, peer])
    let graphCopy = graph.copy() as! GKGraph
    let copyA = graphCopy.nodes?.first as? GKGraphNode2D
    copyA?.position = SIMD2<Float>(9, 9)
    precondition(a.position == SIMD2<Float>(3, 4))
    precondition(copyA?.connectedNodes.count == 1)
    precondition(copyA?.connectedNodes.first !== peer)
}
