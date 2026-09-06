import Foundation
import ModelIO

func testSubmeshTopology() {
    let buffer = MDLMeshBufferData(type: .index, length: 12)
    let submesh = MDLSubmesh(
        indexBuffer: buffer,
        indexCount: 3,
        indexType: .uInt32,
        geometryType: .triangles,
        material: nil
    )
    let topology = MDLSubmeshTopology(submesh: submesh)
    topology.edgeCreaseCount = 1
    topology.faceCount = 1
    topology.holeCount = 0
    topology.vertexCreaseCount = 0
    mdlCheck(topology.faceCount == 1, "faceCount")
    mdlCheck(topology.edgeCreaseCount == 1, "edgeCreaseCount")
    topology.edgeCreaseIndices = buffer
    topology.edgeCreases = buffer
    topology.faceTopology = buffer
    topology.holes = nil
    topology.vertexCreaseIndices = buffer
    topology.vertexCreases = buffer
    mdlCheck(topology.edgeCreases != nil, "creases")
}

func testSubmesh() {
    let buffer = MDLMeshBufferData(type: .index, data: Data([0, 1, 2, 0, 2, 3].flatMap { withUnsafeBytes(of: UInt32($0)) { Data($0) } }))
    let material = MDLMaterial()
    let submesh = MDLSubmesh(
        name: "part",
        indexBuffer: buffer,
        indexCount: 6,
        indexType: .uInt32,
        geometryType: .triangles,
        material: material
    )
    mdlCheck(submesh.name == "part", "name")
    mdlCheck(submesh.indexCount == 6, "count")
    mdlCheck(submesh.indexType == .uInt32, "type")
    mdlCheck(submesh.geometryType == .triangles, "geom")
    mdlCheck(submesh.material === material, "material")
    let converted = submesh.indexBuffer(asIndexType: .uInt16)
    mdlCheck(converted.length == 12, "u16 bytes")
    let topology = MDLSubmeshTopology(submesh: submesh)
    let withTopo = MDLSubmesh(
        name: "topo",
        indexBuffer: buffer,
        indexCount: 6,
        indexType: .uInt32,
        geometryType: .triangles,
        material: nil,
        topology: topology
    )
    mdlCheck(withTopo.topology != nil, "topology")
    let copy = MDLSubmesh(mdlSubmesh: submesh, indexType: .uInt32, geometryType: .triangles)
    mdlCheck(copy != nil, "copy init")
    let copy2 = MDLSubmesh(MDLSubmesh: submesh, indexType: .uInt16, geometryType: .triangles)
    mdlCheck(copy2 != nil, "MDLSubmesh: init")
}

func testMeshBuffers() {
    let allocator = MDLMeshBufferDataAllocator()
    let empty = MDLMesh(bufferAllocator: allocator)
    mdlCheck(empty.vertexCount == 0, "empty")
    mdlCheck((empty.allocator as AnyObject) === allocator, "allocator")
    let vertex = allocator.newBuffer(with: Data(count: 36), type: .vertex)
    let descriptor = MDLVertexDescriptor()
    descriptor.addOrReplaceAttribute(
        MDLVertexAttribute(name: MDLVertexAttributePosition, format: .float3, offset: 0, bufferIndex: 0)
    )
    let sub = MDLSubmesh(
        indexBuffer: allocator.newBuffer(12, type: .index),
        indexCount: 3,
        indexType: .uInt32,
        geometryType: .triangles,
        material: nil
    )
    let mesh = MDLMesh(vertexBuffer: vertex, vertexCount: 3, descriptor: descriptor, submeshes: [sub])
    mdlCheck(mesh.vertexCount == 3, "count")
    mdlCheck(mesh.vertexBuffers.count == 1, "buffers")
    mdlCheck(mesh.submeshes?.count == 1, "submeshes")
    _ = mesh.vertexDescriptor
    _ = mesh.boundingBox
    let multi = MDLMesh(vertexBuffers: [vertex], vertexCount: 3, descriptor: descriptor, submeshes: [sub])
    mdlCheck(multi.vertexCount == 3, "multi")
}

func testMeshAttributes() {
    let mesh = MDLMesh(
        boxWithExtent: SIMD3(1, 1, 1),
        segments: SIMD3<UInt32>(1, 1, 1),
        inwardNormals: false,
        geometryType: .triangles,
        allocator: nil
    )
    mesh.addAttribute(withName: "extra", format: .float)
    mdlCheck(mesh.vertexDescriptor.attributeNamed("extra") != nil, "add format")
    mesh.addAttribute(withName: "extra2", format: .float2, type: "float", data: Data(count: 8), stride: 8)
    mesh.addAttribute(withName: "extra3", format: .float3, type: "float", data: Data(count: 12), stride: 12, time: 0.5)
    let data = mesh.vertexAttributeData(forAttributeNamed: MDLVertexAttributePosition)
    mdlCheck(data != nil, "attr data")
    let asFormat = mesh.vertexAttributeData(forAttributeNamed: MDLVertexAttributePosition, as: .float3)
    mdlCheck(asFormat != nil, "as format")
    if let data {
        mesh.replaceAttributeNamed(MDLVertexAttributePosition, with: data)
        mesh.updateAttributeNamed(MDLVertexAttributePosition, with: data)
    }
    mesh.removeAttributeNamed("extra")
    mdlCheck(mesh.vertexDescriptor.attributeNamed("extra") == nil, "removed")
}

func testMeshDerivedAttributes() {
    let mesh = MDLMesh(
        boxWithExtent: SIMD3(1, 1, 1),
        segments: SIMD3<UInt32>(1, 1, 1),
        inwardNormals: false,
        geometryType: .triangles,
        allocator: nil
    )
    mesh.addNormals(withAttributeNamed: MDLVertexAttributeNormal, creaseThreshold: 0.5)
    mesh.addUnwrappedTextureCoordinates(forAttributeNamed: MDLVertexAttributeTextureCoordinate)
    mesh.flipTextureCoordinates(inAttributeNamed: MDLVertexAttributeTextureCoordinate)
    mesh.addTangentBasis(
        forTextureCoordinateAttributeNamed: MDLVertexAttributeTextureCoordinate,
        normalAttributeNamed: MDLVertexAttributeNormal,
        tangentAttributeNamed: MDLVertexAttributeTangent
    )
    mesh.addOrthTanBasis(
        forTextureCoordinateAttributeNamed: MDLVertexAttributeTextureCoordinate,
        normalAttributeNamed: MDLVertexAttributeNormal,
        tangentAttributeNamed: MDLVertexAttributeTangent
    )
    mesh.addTangentBasis(
        forTextureCoordinateAttributeNamed: MDLVertexAttributeTextureCoordinate,
        tangentAttributeNamed: MDLVertexAttributeTangent,
        bitangentAttributeNamed: MDLVertexAttributeBitangent
    )
    mesh.makeVerticesUnique()
    try! mesh.makeVerticesUniqueAndReturnError()
    mdlCheck(mesh.vertexAttributeData(forAttributeNamed: MDLVertexAttributeTangent) != nil, "tangents")
}
