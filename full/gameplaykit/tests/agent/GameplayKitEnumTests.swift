import Foundation
import GameplayKit

func testEnumAndOptionSetValues() {
    precondition(GKGameModelMaxScore == 1 << 24)
    precondition(GKGameModelMinScore == -(1 << 24))
    precondition(GKRTreeSplitStrategy.halve.rawValue == 0)
    precondition(GKRTreeSplitStrategy.linear.rawValue == 1)
    precondition(GKRTreeSplitStrategy.quadratic.rawValue == 2)
    precondition(GKRTreeSplitStrategy.reduceOverlap.rawValue == 3)
    precondition(GKRTreeSplitStrategy(rawValue: 0) == .halve)
    precondition(GKRTreeSplitStrategy(rawValue: 1) == .linear)
    precondition(GKRTreeSplitStrategy(rawValue: 2) == .quadratic)
    precondition(GKRTreeSplitStrategy(rawValue: 3) == .reduceOverlap)
    precondition(GKRTreeSplitStrategy(rawValue: 99) == nil)
    precondition(GKRTreeSplitStrategy.halve != .linear)
    var hasher = Hasher()
    GKRTreeSplitStrategy.halve.hash(into: &hasher)
    precondition(GKRTreeSplitStrategy.halve.hashValue == GKRTreeSplitStrategy.halve.hashValue)

    precondition(GKMeshGraphTriangulationMode.vertices.rawValue == 1)
    precondition(GKMeshGraphTriangulationMode.centers.rawValue == 2)
    precondition(GKMeshGraphTriangulationMode.edgeMidpoints.rawValue == 4)
    let empty = GKMeshGraphTriangulationMode()
    precondition(empty.isEmpty)
    precondition(GKMeshGraphTriangulationMode(rawValue: 0).isEmpty)
    var mode: GKMeshGraphTriangulationMode = [.vertices, .centers]
    precondition(mode.contains(.vertices))
    precondition(mode.contains(.centers))
    precondition(!mode.contains(.edgeMidpoints))
    let inserted = mode.insert(.edgeMidpoints)
    precondition(inserted.inserted)
    precondition(mode.contains(.edgeMidpoints))
    let removed = mode.remove(.centers)
    precondition(removed == .centers)
    _ = mode.update(with: .vertices)
    precondition(mode.union(.centers).contains(.centers))
    precondition(mode.intersection(.vertices).contains(.vertices))
    precondition(!mode.symmetricDifference(.vertices).contains(.vertices))
    mode.formUnion(.centers)
    mode.formIntersection([.vertices, .centers])
    mode.formSymmetricDifference(.edgeMidpoints)
    precondition(mode.isSubset(of: [.vertices, .centers, .edgeMidpoints]))
    let pair: GKMeshGraphTriangulationMode = [.vertices, .centers]
    precondition(pair.isSuperset(of: .vertices))
    precondition(!mode.isDisjoint(with: .vertices) || mode.contains(.edgeMidpoints))
    precondition(GKMeshGraphTriangulationMode.vertices.isStrictSubset(of: [.vertices, .centers]))
    precondition(pair.isStrictSuperset(of: .vertices))
    var subtractable: GKMeshGraphTriangulationMode = [.vertices, .centers]
    subtractable.subtract(.centers)
    precondition(subtractable == .vertices)
    precondition(GKMeshGraphTriangulationMode.vertices.subtracting(.vertices).isEmpty)
    let fromSequence = GKMeshGraphTriangulationMode([.vertices, .edgeMidpoints])
    precondition(fromSequence.contains(.vertices))
    let literal: GKMeshGraphTriangulationMode = [.centers]
    precondition(literal == .centers)
    precondition(mode != empty)
}

func testGeometryValueTypes() {
    let zeroBox = GKBox()
    precondition(zeroBox.boxMin == SIMD3<Float>(0, 0, 0))
    precondition(zeroBox.boxMax == SIMD3<Float>(0, 0, 0))
    let box = GKBox(boxMin: SIMD3<Float>(-1, -2, -3), boxMax: SIMD3<Float>(1, 2, 3))
    precondition(box.boxMin.x == -1)
    precondition(box.boxMax.z == 3)
    precondition(box != zeroBox)

    let zeroQuad = GKQuad()
    precondition(zeroQuad.quadMin == SIMD2<Float>(0, 0))
    precondition(zeroQuad.quadMax == SIMD2<Float>(0, 0))
    let quad = GKQuad(quadMin: SIMD2<Float>(-2, -3), quadMax: SIMD2<Float>(4, 5))
    precondition(quad.quadMin.y == -3)
    precondition(quad.quadMax.x == 4)

    let zeroTriangle = GKTriangle()
    precondition(zeroTriangle.points.0 == SIMD3<Float>(0, 0, 0))
    let triangle = GKTriangle(points: (
        SIMD3<Float>(1, 0, 0),
        SIMD3<Float>(0, 1, 0),
        SIMD3<Float>(0, 0, 1)
    ))
    precondition(triangle.points.1.y == 1)
    precondition(triangle == triangle)
}
