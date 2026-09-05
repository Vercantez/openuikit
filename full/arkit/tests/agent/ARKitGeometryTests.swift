import Foundation
import ARKit

func testPlaneGeometryQuadLayout() {
    let geometry = arkitMakeHorizontalPlane().geometry
    arkitRequire(geometry.vertices.count == 4, "vertices")
    arkitRequire(geometry.triangleCount == 2, "triangles")
    arkitRequire(geometry.triangleIndices.count == 6, "indices")
    arkitRequire(geometry.textureCoordinates.count == 4, "uvs")
    arkitRequire(geometry.boundaryVertices.count == 4, "boundary")
    arkitRequire(ARPlaneGeometry().vertices.isEmpty, "empty")
    ARPlaneGeometry().encode(with: NSKeyedArchiver(requiringSecureCoding: true))
}

func testFaceGeometryFailClosed() {
    arkitRequire(ARFaceGeometry(blendShapes: [:]) == nil, "no Apple topology")
    arkitRequire(ARFaceGeometry().triangleCount == 0, "empty triangles")
    arkitRequire(ARFaceGeometry().vertices.isEmpty, "empty vertices")
    arkitRequire(ARFaceGeometry().textureCoordinates.isEmpty, "empty uvs")
    arkitRequire(ARFaceGeometry().triangleIndices.isEmpty, "empty indices")
    ARFaceGeometry().encode(with: NSKeyedArchiver(requiringSecureCoding: true))
}

func testMeshGeometrySources() {
    let mesh = ARMeshAnchor(anchor: ARAnchor(transform: .identity)).geometry
    _ = mesh.vertices
    _ = mesh.normals
    _ = mesh.faces
    _ = mesh.classification
    _ = mesh.vertices.buffer
    _ = mesh.vertices.format
    _ = mesh.vertices.componentsPerVector
    _ = mesh.vertices.count
    _ = mesh.vertices.offset
    _ = mesh.vertices.stride
    _ = mesh.vertices[Int32(0)]
    _ = mesh.faces.buffer
    _ = mesh.faces.bytesPerIndex
    _ = mesh.faces.count
    _ = mesh.faces.indexCountPerPrimitive
    _ = mesh.faces.primitiveType
    _ = mesh.faces[0]
    mesh.encode(with: NSKeyedArchiver(requiringSecureCoding: true))
    mesh.vertices.encode(with: NSKeyedArchiver(requiringSecureCoding: true))
    mesh.faces.encode(with: NSKeyedArchiver(requiringSecureCoding: true))
}

func testPointCloudAndWorldMap() {
    let map = ARWorldMap()
    arkitRequire(map.anchors.isEmpty, "empty map")
    _ = map.center
    _ = map.extent
    _ = map.rawFeaturePoints.points
    _ = map.rawFeaturePoints.identifiers
    map.encode(with: NSKeyedArchiver(requiringSecureCoding: true))
}
