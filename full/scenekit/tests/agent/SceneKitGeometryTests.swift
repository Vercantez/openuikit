import Foundation
import SceneKit

func testPrimitiveLayouts() {
    let box = SCNBox(width: 2, height: 4, length: 6, chamferRadius: 0)
    precondition(box.width == 2 && box.height == 4 && box.length == 6)
    precondition(box.widthSegmentCount == 1)
    precondition(box.sources(for: .vertex).first?.vectorCount ?? 0 >= 24)
    precondition(!box.sources(for: .normal).isEmpty)
    precondition(box.elements.first?.primitiveType == .triangles)
    precondition(abs(box.boundingBox.max.x - 1) < 1e-4)
    let sphere = SCNSphere(radius: 2)
    precondition(sphere.segmentCount == 24)
    let plane = SCNPlane(width: 4, height: 2)
    precondition(plane.sources(for: .vertex).first?.vectorCount == 6)
    let cyl = SCNCylinder(radius: 1, height: 2)
    precondition(cyl.radialSegmentCount == 24)
    let cone = SCNCone(topRadius: 0, bottomRadius: 1, height: 2)
    precondition(cone.bottomRadius == 1)
    let cap = SCNCapsule(capRadius: 0.5, height: 2)
    precondition(cap.capSegmentCount == 24)
    let torus = SCNTorus(ringRadius: 1, pipeRadius: 0.2)
    precondition(torus.ringSegmentCount == 24)
    let tube = SCNTube(innerRadius: 0.5, outerRadius: 1, height: 2)
    precondition(tube.outerRadius == 1)
    let pyr = SCNPyramid(width: 1, height: 2, length: 1)
    precondition(pyr.height == 2)
    let floor = SCNFloor()
    precondition(floor.reflectivity == 0.25)
    let text = SCNText(string: "A", extrusionDepth: 1)
    precondition((text.string as? String) == "A")
    let shape = SCNShape()
    shape.extrusionDepth = 2
    precondition(shape.chamferMode == .both)
    _ = box.chamferRadius
    _ = box.heightSegmentCount
    _ = box.lengthSegmentCount
    _ = sphere.isGeodesic
    _ = plane.widthSegmentCount
    _ = plane.cornerRadius
    _ = cyl.heightSegmentCount
    _ = cone.radialSegmentCount
    _ = cap.radialSegmentCount
    _ = torus.pipeSegmentCount
    _ = tube.radialSegmentCount
    _ = pyr.width
    _ = floor.reflectionFalloffEnd
    _ = text.flatness
    _ = shape.chamferRadius
}

func testCustomGeometrySource() {
    let floats: [Float] = [0, 0, 0, 1, 0, 0, 0, 1, 0]
    let data = floats.withUnsafeBufferPointer { Data(buffer: $0) }
    let src = SCNGeometrySource(
        data: data, semantic: .vertex, vectorCount: 3,
        usesFloatComponents: true, componentsPerVector: 3, bytesPerComponent: 4,
        dataOffset: 0, dataStride: 12
    )
    let elem = SCNGeometryElement(indices: [UInt16]([0, 1, 2]), primitiveType: .triangles)
    let geom = SCNGeometry(sources: [src], elements: [elem])
    precondition(geom.elementCount == 1)
    geom.subdivisionLevel = 2
    precondition(geom.subdivisionLevel == 2)
    _ = geom.sources
    _ = geom.elements
    _ = geom.materials
    _ = geom.firstMaterial
    _ = src.semantic
    _ = src.vectorCount
    _ = src.usesFloatComponents
    _ = src.componentsPerVector
    _ = src.bytesPerComponent
    _ = src.dataOffset
    _ = src.dataStride
    _ = src.data
    _ = elem.primitiveType
    _ = elem.primitiveCount
    _ = elem.bytesPerIndex
    _ = elem.data
    let verts = SCNGeometrySource(vertices: [SCNVector3Zero, SCNVector3(1, 0, 0), SCNVector3(0, 1, 0)])
    _ = SCNGeometrySource(normals: [SCNVector3(0, 1, 0)])
    _ = SCNGeometrySource(textureCoordinates: [CGPoint.zero])
    _ = verts
    let lod = SCNLevelOfDetail(geometry: SCNBox(width: 1, height: 1, length: 1, chamferRadius: 0), screenSpaceRadius: 10)
    precondition(lod.screenSpaceRadius == 10)
    let tess = SCNGeometryTessellator()
    tess.edgeTessellationFactor = 2
    precondition(tess.smoothingMode == .none)
    _ = geom.elements.first
    _ = geom.sources(for: .vertex)
}
