import Foundation

open class MTKMeshBufferAllocator: NSObject, MDLMeshBufferAllocator {
    public let device: any MTLDevice

    public init(device: any MTLDevice) {
        self.device = device
        super.init()
    }

    public func newZone(_ capacity: Int) -> any MDLMeshBufferZone {
        MetalKitSoftwareMeshZone(capacity: capacity)
    }

    public func newBuffer(_ length: Int, type: MDLMeshBufferType) -> any MDLMeshBuffer {
        makeBuffer(length: length, type: type, bytes: Data(count: max(length, 0)), zone: nil)
    }

    public func newBuffer(with data: Data, type: MDLMeshBufferType) -> any MDLMeshBuffer {
        makeBuffer(length: data.count, type: type, bytes: data, zone: nil)
    }

    func makeBuffer(
        length: Int,
        type: MDLMeshBufferType,
        bytes: Data,
        zone: (any MDLMeshBufferZone)?
    ) -> MTKMeshBuffer {
        let metal = MetalKitLookalikeBuffer(device: device, length: length, bytes: bytes)
        return MTKMeshBuffer(
            allocator: self,
            buffer: metal,
            offset: 0,
            length: max(length, 0),
            type: type,
            zone: zone
        )
    }
}

open class MTKMeshBuffer: NSObject, MDLMeshBuffer {
    public let allocator: MTKMeshBufferAllocator
    public let buffer: any MTLBuffer
    public let offset: Int
    public let length: Int
    public let type: MDLMeshBufferType
    private let storedZone: (any MDLMeshBufferZone)?

    init(
        allocator: MTKMeshBufferAllocator,
        buffer: any MTLBuffer,
        offset: Int,
        length: Int,
        type: MDLMeshBufferType,
        zone: (any MDLMeshBufferZone)?
    ) {
        self.allocator = allocator
        self.buffer = buffer
        self.offset = max(offset, 0)
        self.length = max(length, 0)
        self.type = type
        self.storedZone = zone
        super.init()
    }

    public func zone() -> (any MDLMeshBufferZone)? {
        storedZone
    }

    public func fill(_ data: Data, offset: Int) {
        if let lookalike = buffer as? MetalKitLookalikeBuffer {
            lookalike.fill(data, offset: self.offset + offset)
        }
    }

    public func map() -> MDLMeshBufferMap {
        if let lookalike = buffer as? MetalKitLookalikeBuffer {
            let bytes = lookalike.copyBytes()
            let start = min(offset, bytes.count)
            let end = min(start + length, bytes.count)
            return MDLMeshBufferMap(bytes: bytes.subdata(in: start..<end))
        }
        return MDLMeshBufferMap(bytes: Data(count: length))
    }
}

open class MTKSubmesh: NSObject {
    public let primitiveType: MTLPrimitiveType
    public let indexType: MTLIndexType
    public let indexBuffer: MTKMeshBuffer
    public let indexCount: Int
    public weak var mesh: MTKMesh?
    public var name: String

    init(
        primitiveType: MTLPrimitiveType,
        indexType: MTLIndexType,
        indexBuffer: MTKMeshBuffer,
        indexCount: Int,
        name: String,
        mesh: MTKMesh?
    ) {
        self.primitiveType = primitiveType
        self.indexType = indexType
        self.indexBuffer = indexBuffer
        self.indexCount = max(indexCount, 0)
        self.name = name
        self.mesh = mesh
        super.init()
    }
}

open class MTKMesh: NSObject {
    public private(set) var vertexBuffers: [MTKMeshBuffer]
    public private(set) var vertexDescriptor: MDLVertexDescriptor
    public private(set) var submeshes: [MTKSubmesh]
    public private(set) var vertexCount: Int
    public var name: String

    public init(mesh: MDLMesh, device: any MTLDevice) throws {
        _ = try MTKMetalVertexDescriptorFromModelIOWithError(mesh.vertexDescriptor)
        let allocator = MTKMeshBufferAllocator(device: device)
        var copiedVertexBuffers: [MTKMeshBuffer] = []
        copiedVertexBuffers.reserveCapacity(mesh.vertexBuffers.count)
        for source in mesh.vertexBuffers {
            copiedVertexBuffers.append(try MTKMesh.copyBuffer(source, allocator: allocator))
        }
        var copiedSubmeshes: [MTKSubmesh] = []
        copiedSubmeshes.reserveCapacity(mesh.submeshes.count)
        for source in mesh.submeshes {
            copiedSubmeshes.append(try MTKMesh.copySubmesh(source, allocator: allocator, mesh: nil))
        }
        self.vertexBuffers = copiedVertexBuffers
        self.vertexDescriptor = mesh.vertexDescriptor
        self.submeshes = copiedSubmeshes
        self.vertexCount = mesh.vertexCount
        self.name = mesh.name
        super.init()
        for submesh in submeshes {
            submesh.mesh = self
        }
    }

    public class func newMeshes(
        asset: MDLAsset,
        device: any MTLDevice
    ) throws -> (modelIOMeshes: [MDLMesh], metalKitMeshes: [MTKMesh]) {
        var metalKitMeshes: [MTKMesh] = []
        metalKitMeshes.reserveCapacity(asset.meshes.count)
        for mesh in asset.meshes {
            metalKitMeshes.append(try MTKMesh(mesh: mesh, device: device))
        }
        return (asset.meshes, metalKitMeshes)
    }

    private static func copyBuffer(
        _ source: any MDLMeshBuffer,
        allocator: MTKMeshBufferAllocator
    ) throws -> MTKMeshBuffer {
        if let existing = source as? MTKMeshBuffer,
           ObjectIdentifier(existing.allocator.device as AnyObject)
            == ObjectIdentifier(allocator.device as AnyObject) {
            return existing
        }
        let bytes = source.map().bytes
        return allocator.makeBuffer(
            length: source.length,
            type: source.type,
            bytes: bytes,
            zone: nil
        )
    }

    private static func copySubmesh(
        _ source: MDLSubmesh,
        allocator: MTKMeshBufferAllocator,
        mesh: MTKMesh?
    ) throws -> MTKSubmesh {
        let indexType = try metalIndexType(source.indexType)
        let primitive = try metalPrimitive(source.geometryType)
        let indexBuffer = try copyBuffer(source.indexBuffer, allocator: allocator)
        return MTKSubmesh(
            primitiveType: primitive,
            indexType: indexType,
            indexBuffer: indexBuffer,
            indexCount: source.indexCount,
            name: source.name,
            mesh: mesh
        )
    }

    private static func metalIndexType(_ depth: MDLIndexBitDepth) throws -> MTLIndexType {
        switch depth {
        case .uInt16:
            return .uint16
        case .uInt32:
            return .uint32
        case .invalid, .uInt8:
            throw metalKitModelError(.unsupportedIndexType(depth))
        }
    }

    private static func metalPrimitive(_ geometry: MDLGeometryType) throws -> MTLPrimitiveType {
        switch geometry {
        case .points:
            return .point
        case .lines:
            return .line
        case .triangles:
            return .triangle
        case .triangleStrips:
            return .triangleStrip
        case .quads, .variableTopology:
            throw metalKitModelError(.unsupportedGeometry(geometry))
        }
    }
}
