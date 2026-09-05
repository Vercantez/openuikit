import Foundation
import ModelIO

func testBoxPrimitive() {
    let mesh = MDLMesh(
        boxWithExtent: SIMD3(2, 2, 2),
        segments: SIMD3<UInt32>(1, 1, 1),
        inwardNormals: false,
        geometryType: .triangles,
        allocator: nil
    )
    mdlCheck(mesh.vertexCount > 0, "box vertices")
    let factory = MDLMesh.newBox(
        withDimensions: SIMD3(1, 1, 1),
        segments: SIMD3<UInt32>(1, 1, 1),
        geometryType: .triangles,
        inwardNormals: false,
        allocator: nil
    )
    mdlCheck(factory.vertexCount > 0, "newBox")
}

func testPlanePrimitive() {
    let mesh = MDLMesh(
        planeWithExtent: SIMD3(2, 0, 2),
        segments: SIMD2<UInt32>(2, 2),
        geometryType: .triangles,
        allocator: nil
    )
    mdlCheck(mesh.vertexCount > 4, "plane")
    let factory = MDLMesh.newPlane(
        withDimensions: SIMD2(1, 1),
        segments: SIMD2<UInt32>(1, 1),
        geometryType: .triangles,
        allocator: nil
    )
    mdlCheck(factory.vertexCount > 0, "newPlane")
}

func testSpherePrimitive() {
    let mesh = MDLMesh(
        sphereWithExtent: SIMD3(2, 2, 2),
        segments: SIMD2<UInt32>(8, 8),
        inwardNormals: false,
        geometryType: .triangles,
        allocator: nil
    )
    mdlCheck(mesh.vertexCount > 10, "sphere")
    let ellipsoid = MDLMesh.newEllipsoid(
        withRadii: SIMD3(1, 1, 1),
        radialSegments: 8,
        verticalSegments: 8,
        geometryType: .triangles,
        inwardNormals: false,
        hemisphere: false,
        allocator: nil
    )
    mdlCheck(ellipsoid.vertexCount > 10, "ellipsoid")
}

func testHemispherePrimitive() {
    let mesh = MDLMesh(
        hemisphereWithExtent: SIMD3(2, 2, 2),
        segments: SIMD2<UInt32>(6, 6),
        inwardNormals: false,
        cap: true,
        geometryType: .triangles,
        allocator: nil
    )
    mdlCheck(mesh.vertexCount > 4, "hemisphere")
}

func testCylinderPrimitive() {
    let mesh = MDLMesh(
        cylinderWithExtent: SIMD3(1, 2, 1),
        segments: SIMD2<UInt32>(8, 1),
        inwardNormals: false,
        topCap: true,
        bottomCap: true,
        geometryType: .triangles,
        allocator: nil
    )
    mdlCheck(mesh.vertexCount > 8, "cylinder")
    let factory = MDLMesh.newCylinder(
        withHeight: 2,
        radii: SIMD2(0.5, 0.5),
        radialSegments: 8,
        verticalSegments: 1,
        geometryType: .triangles,
        inwardNormals: false,
        allocator: nil
    )
    mdlCheck(factory.vertexCount > 0, "newCylinder")
}

func testConePrimitive() {
    let mesh = MDLMesh(
        coneWithExtent: SIMD3(1, 2, 1),
        segments: SIMD2<UInt32>(8, 1),
        inwardNormals: false,
        cap: true,
        geometryType: .triangles,
        allocator: nil
    )
    mdlCheck(mesh.vertexCount > 8, "cone")
    let factory = MDLMesh.newEllipticalCone(
        withHeight: 2,
        radii: SIMD2(0.5, 0.5),
        radialSegments: 8,
        verticalSegments: 1,
        geometryType: .triangles,
        inwardNormals: false,
        allocator: nil
    )
    mdlCheck(factory.vertexCount > 0, "newCone")
}

func testCapsulePrimitive() {
    let mesh = MDLMesh(
        capsuleWithExtent: SIMD3(1, 2, 1),
        cylinderSegments: SIMD2<UInt32>(8, 2),
        hemisphereSegments: 4,
        inwardNormals: false,
        geometryType: .triangles,
        allocator: nil
    )
    mdlCheck(mesh.vertexCount > 0, "capsule")
    let factory = MDLMesh.newCapsule(
        withHeight: 2,
        radii: SIMD2(0.5, 0.5),
        radialSegments: 8,
        verticalSegments: 2,
        hemisphereSegments: 2,
        geometryType: .triangles,
        inwardNormals: false,
        allocator: nil
    )
    mdlCheck(factory.vertexCount > 0, "newCapsule")
}

func testIcosahedronPrimitive() {
    let mesh = MDLMesh(
        icosahedronWithExtent: SIMD3(2, 2, 2),
        inwardNormals: false,
        geometryType: .triangles,
        allocator: nil
    )
    mdlCheck(mesh.vertexCount == 60, "20 faces * 3 verts")
    let a = MDLMesh.newIcosahedron(withRadius: 1, inwardNormals: false, allocator: nil)
    mdlCheck(a.vertexCount > 0, "newIco")
    let b = MDLMesh.newIcosahedron(withRadius: 1, inwardNormals: true, geometryType: .triangles, allocator: nil)
    mdlCheck(b.vertexCount > 0, "newIco geom")
}

func testSubdivision() {
    let source = MDLMesh(
        boxWithExtent: SIMD3(1, 1, 1),
        segments: SIMD3<UInt32>(1, 1, 1),
        inwardNormals: false,
        geometryType: .triangles,
        allocator: nil
    )
    let subdivided = MDLMesh(
        meshBySubdividingMesh: source,
        submeshIndex: 0,
        subdivisionLevels: 1,
        allocator: nil
    )
    mdlCheck(subdivided.vertexCount > source.vertexCount, "subdivide grows")
    let factory = MDLMesh.newSubdividedMesh(source, submeshIndex: 0, subdivisionLevels: 1)
    mdlCheck(factory != nil, "newSubdividedMesh")
}
