import Foundation
import MetalKit

private func makeTriangleMesh() -> MDLMesh {
    let allocator = MDLMeshBufferDataAllocator()
    let vertexBytes = Data([
        0, 0, 0, 0,
        0, 0, 128, 63,
        0, 0, 0, 63,
        0, 0, 0, 191,
        0, 0, 0, 63,
        0, 0, 0, 63,
    ])
    let vertexBuffer = allocator.newBuffer(with: vertexBytes, type: .vertex)
    let indexBytes = Data([0, 0, 1, 0, 2, 0])
    let indexBuffer = allocator.newBuffer(with: indexBytes, type: .index)
    let descriptor = MDLVertexDescriptor(
        attributes: [MDLVertexAttribute(name: "position", format: .float3, offset: 0, bufferIndex: 0)],
        layouts: [MDLVertexBufferLayout(stride: 12)]
    )
    let submesh = MDLSubmesh(
        name: "tri",
        indexBuffer: indexBuffer,
        indexCount: 3,
        indexType: .uInt16,
        geometryType: .triangles
    )
    return MDLMesh(
        vertexBuffers: [vertexBuffer],
        vertexCount: 3,
        vertexDescriptor: descriptor,
        submeshes: [submesh],
        name: "triangle"
    )
}

func testMeshBufferAllocatorInitAndDevice() {
    let device = MTLCreateSystemDefaultDevice()!
    let allocator = MTKMeshBufferAllocator(device: device)
    precondition(ObjectIdentifier(allocator.device as AnyObject) == ObjectIdentifier(device as AnyObject))
    let zone = allocator.newZone(64)
    precondition(zone.capacity == 64)
}

func testMeshBufferFromAllocator() {
    let device = MTLCreateSystemDefaultDevice()!
    let allocator = MTKMeshBufferAllocator(device: device)
    let payload = Data([1, 2, 3, 4])
    let buffer = allocator.newBuffer(with: payload, type: .vertex) as! MTKMeshBuffer
    precondition(buffer.length == 4)
    precondition(buffer.offset == 0)
    precondition(buffer.type == .vertex)
    precondition(buffer.buffer.length == 4)
    precondition(buffer.zone() == nil)
    precondition(buffer.map().bytes == payload)
    precondition(ObjectIdentifier(buffer.allocator) == ObjectIdentifier(allocator))
}

func testMeshInitCopiesVertexAndIndexBuffers() {
    let device = MTLCreateSystemDefaultDevice()!
    let source = makeTriangleMesh()
    let mesh = try! MTKMesh(mesh: source, device: device)
    precondition(mesh.name == "triangle")
    precondition(mesh.vertexCount == 3)
    precondition(mesh.vertexBuffers.count == 1)
    precondition(mesh.vertexBuffers[0].length == 24)
    precondition(mesh.vertexBuffers[0].type == .vertex)
    precondition(mesh.vertexDescriptor.attributes[0].format == .float3)
    precondition(mesh.submeshes.count == 1)
}

func testSubmeshPropertiesFromConvertedMesh() {
    let device = MTLCreateSystemDefaultDevice()!
    let mesh = try! MTKMesh(mesh: makeTriangleMesh(), device: device)
    let submesh = mesh.submeshes[0]
    precondition(submesh.name == "tri")
    precondition(submesh.indexCount == 3)
    precondition(submesh.indexType == .uint16)
    precondition(submesh.primitiveType == .triangle)
    precondition(submesh.indexBuffer.length == 6)
    precondition(submesh.indexBuffer.type == .index)
    precondition(submesh.mesh === mesh)
    submesh.name = "renamed"
    precondition(submesh.name == "renamed")
}

func testMeshNewMeshesFromAsset() {
    let device = MTLCreateSystemDefaultDevice()!
    let asset = MDLAsset(meshes: [makeTriangleMesh()])
    let pair = try! MTKMesh.newMeshes(asset: asset, device: device)
    precondition(pair.modelIOMeshes.count == 1)
    precondition(pair.metalKitMeshes.count == 1)
    precondition(pair.metalKitMeshes[0].vertexCount == 3)
}

func testMeshRejectsQuadGeometry() {
    let allocator = MDLMeshBufferDataAllocator()
    let indexBuffer = allocator.newBuffer(4, type: .index)
    let submesh = MDLSubmesh(
        indexBuffer: indexBuffer,
        indexCount: 4,
        indexType: .uInt16,
        geometryType: .quads
    )
    let mesh = MDLMesh(
        vertexBuffers: [],
        vertexCount: 0,
        vertexDescriptor: MDLVertexDescriptor(),
        submeshes: [submesh]
    )
    do {
        _ = try MTKMesh(mesh: mesh, device: MTLCreateSystemDefaultDevice()!)
        preconditionFailure("quads should fail closed")
    } catch let error as NSError {
        precondition(error.domain == MTKModelError.domain.rawValue)
    }
}

func testMeshRejectsUInt8Indices() {
    let allocator = MDLMeshBufferDataAllocator()
    let indexBuffer = allocator.newBuffer(3, type: .index)
    let submesh = MDLSubmesh(
        indexBuffer: indexBuffer,
        indexCount: 3,
        indexType: .uInt8,
        geometryType: .triangles
    )
    let mesh = MDLMesh(
        vertexBuffers: [],
        vertexCount: 0,
        vertexDescriptor: MDLVertexDescriptor(),
        submeshes: [submesh]
    )
    do {
        _ = try MTKMesh(mesh: mesh, device: MTLCreateSystemDefaultDevice()!)
        preconditionFailure("uint8 indices should fail closed")
    } catch let error as NSError {
        precondition(error.domain == "MTKModelErrorDomain")
    }
}

func testEmptyAssetNewMeshes() {
    let pair = try! MTKMesh.newMeshes(asset: MDLAsset(), device: MTLCreateSystemDefaultDevice()!)
    precondition(pair.modelIOMeshes.isEmpty)
    precondition(pair.metalKitMeshes.isEmpty)
}
