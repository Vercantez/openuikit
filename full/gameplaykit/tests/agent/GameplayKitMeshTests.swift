import Foundation
import GameplayKit

func testMeshTriangulation() {
    let wall = GKPolygonObstacle(points: [
        SIMD2<Float>(2, 2), SIMD2<Float>(3, 2), SIMD2<Float>(3, 3), SIMD2<Float>(2, 3)
    ])
    precondition(wall.vertexCount == 4)
    precondition(wall.vertex(at: 0) == SIMD2<Float>(2, 2))
    let mesh = GKMeshGraph<GKGraphNode2D>(
        bufferRadius: 0.1,
        minCoordinate: SIMD2<Float>(0, 0),
        maxCoordinate: SIMD2<Float>(4, 4)
    )
    precondition(mesh.bufferRadius == 0.1)
    mesh.triangulationMode = [.vertices, .centers]
    precondition(mesh.triangulationMode.contains(.vertices))
    mesh.addObstacles([wall])
    precondition(mesh.obstacles.count == 1)
    mesh.triangulate()
    precondition(mesh.triangleCount > 0)
    let triangle = mesh.triangle(at: 0)
    _ = triangle.points.0
    let extra = GKGraphNode2D(point: SIMD2<Float>(0.2, 0.2))
    mesh.connectUsingObstacles(node: extra)
    mesh.removeObstacles([wall])
    _ = mesh.classForGenericArgument(at: 0)
    let withClass = GKMeshGraph<GKGraphNode2D>(
        bufferRadius: 0.2,
        minCoordinate: SIMD2<Float>(0, 0),
        maxCoordinate: SIMD2<Float>(2, 2),
        nodeClass: GKGraphNode2D.self
    )
    _ = GKMeshGraph<GKGraphNode2D>(nodes: [GKGraphNode2D(point: SIMD2<Float>(0, 0))])
    _ = withClass.bufferRadius
}

func testObstacleGraphConnectionsAndLocks() {
    let wall = GKPolygonObstacle(points: [
        SIMD2<Float>(2, 2), SIMD2<Float>(3, 2), SIMD2<Float>(3, 3), SIMD2<Float>(2, 3)
    ])
    let obstacles = GKObstacleGraph<GKGraphNode2D>(obstacles: [wall], bufferRadius: 0.1)
    precondition(obstacles.obstacles.count == 1)
    precondition(obstacles.bufferRadius == 0.1)
    let extra = GKGraphNode2D(point: SIMD2<Float>(0, 0))
    obstacles.connectUsingObstacles(node: extra)
    let other = GKGraphNode2D(point: SIMD2<Float>(4, 0))
    obstacles.connectUsingObstacles(node: other, ignoring: [wall])
    let third = GKGraphNode2D(point: SIMD2<Float>(0, 4))
    obstacles.connectUsingObstacles(node: third, ignoringBufferRadiusOf: [wall])
    obstacles.lockConnection(from: extra, to: extra)
    precondition(obstacles.isConnectionLocked(from: extra, to: extra))
    obstacles.unlockConnection(from: extra, to: extra)
    _ = obstacles.nodes(for: wall)
    obstacles.addObstacles([])
    obstacles.removeObstacles([wall])
    obstacles.removeAllObstacles()
    precondition(obstacles.obstacles.isEmpty)
    _ = obstacles.classForGenericArgument(at: 0)
    let withClass = GKObstacleGraph<GKGraphNode2D>(
        obstacles: [],
        bufferRadius: 0.5,
        nodeClass: GKGraphNode2D.self
    )
    _ = GKObstacleGraph<GKGraphNode2D>(nodes: [GKGraphNode2D(point: SIMD2<Float>(1, 1))])
    _ = withClass.bufferRadius
}
