import Foundation
import GameplayKit

func testOctreeQueries() {
    let box = GKBox(boxMin: SIMD3<Float>(-1, -1, -1), boxMax: SIMD3<Float>(1, 1, 1))
    let tree = GKOctree<NSString>(boundingBox: box, minimumCellSize: 0.5)
    let token = "token" as NSString
    let node = tree.add(token, at: SIMD3<Float>(0, 0, 0))
    precondition(tree.elements(at: SIMD3<Float>(0, 0, 0)).count == 1)
    _ = node.box
    let boxed = tree.add("box" as NSString, in: box)
    _ = boxed
    precondition(tree.elements(in: box).count >= 1)
    precondition(tree.remove(token))
    let keep = "keep" as NSString
    let again = tree.add(keep, at: SIMD3<Float>(0.1, 0, 0))
    precondition(tree.remove(keep, using: again))
}

func testQuadtreeQueries() {
    let quad = GKQuad(quadMin: SIMD2<Float>(-2, -2), quadMax: SIMD2<Float>(2, 2))
    let tree = GKQuadtree<NSString>(boundingQuad: quad, minimumCellSize: 0.5)
    let q = "q" as NSString
    let node = tree.add(q, in: GKQuad(quadMin: SIMD2<Float>(0, 0), quadMax: SIMD2<Float>(0.5, 0.5)))
    precondition(tree.elements(at: SIMD2<Float>(0.1, 0.1)).count == 1)
    precondition(node.quad.quadMin.x == 0)
    let p = "p" as NSString
    _ = tree.add(p, at: SIMD2<Float>(0.2, 0.2))
    precondition(tree.elements(in: quad).count >= 1)
    precondition(tree.remove(p))
    let k = "k" as NSString
    let kept = tree.add(k, at: SIMD2<Float>(0, 0))
    precondition(tree.remove(k, using: kept))
}

func testRTreeQueries() {
    let tree = GKRTree<NSString>(maxNumberOfChildren: 4)
    tree.queryReserve = 8
    precondition(tree.queryReserve == 8)
    tree.addElement(
        "r" as NSString,
        boundingRectMin: SIMD2<Float>(0, 0),
        boundingRectMax: SIMD2<Float>(1, 1),
        splitStrategy: .halve
    )
    tree.addElement(
        "linear" as NSString,
        boundingRectMin: SIMD2<Float>(2, 2),
        boundingRectMax: SIMD2<Float>(3, 3),
        splitStrategy: .linear
    )
    tree.addElement(
        "quad" as NSString,
        boundingRectMin: SIMD2<Float>(4, 2),
        boundingRectMax: SIMD2<Float>(5, 3),
        splitStrategy: .quadratic
    )
    tree.addElement(
        "overlap" as NSString,
        boundingRectMin: SIMD2<Float>(0.2, 0.2),
        boundingRectMax: SIMD2<Float>(0.4, 0.4),
        splitStrategy: .reduceOverlap
    )
    precondition(tree.elements(inBoundingRectMin: SIMD2<Float>(-1, -1), rectMax: SIMD2<Float>(2, 2)).count >= 1)
    tree.removeElement(
        "r" as NSString,
        boundingRectMin: SIMD2<Float>(0, 0),
        boundingRectMax: SIMD2<Float>(1, 1)
    )
}
