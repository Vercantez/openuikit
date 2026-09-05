import Foundation

// Isolated-host lookalikes for ModelIO types named in MetalKit's public
// surface. These are not the ModelIO module.

public struct MDLVertexFormat: RawRepresentable, Hashable, Sendable, Equatable {
    public let rawValue: UInt

    public init(rawValue: UInt) {
        self.rawValue = rawValue
    }

    public static let invalid = MDLVertexFormat(rawValue: 0)
    public static let packedBits = MDLVertexFormat(rawValue: 0x1000)
    public static let uCharBits = MDLVertexFormat(rawValue: 0x10000)
    public static let charBits = MDLVertexFormat(rawValue: 0x20000)
    public static let uCharNormalizedBits = MDLVertexFormat(rawValue: 0x30000)
    public static let charNormalizedBits = MDLVertexFormat(rawValue: 0x40000)
    public static let uShortBits = MDLVertexFormat(rawValue: 0x50000)
    public static let shortBits = MDLVertexFormat(rawValue: 0x60000)
    public static let uShortNormalizedBits = MDLVertexFormat(rawValue: 0x70000)
    public static let shortNormalizedBits = MDLVertexFormat(rawValue: 0x80000)
    public static let uIntBits = MDLVertexFormat(rawValue: 0x90000)
    public static let intBits = MDLVertexFormat(rawValue: 0xA0000)
    public static let halfBits = MDLVertexFormat(rawValue: 0xB0000)
    public static let floatBits = MDLVertexFormat(rawValue: 0xC0000)

    public static let uChar = MDLVertexFormat(rawValue: 0x10000 | 1)
    public static let uChar2 = MDLVertexFormat(rawValue: 0x10000 | 2)
    public static let uChar3 = MDLVertexFormat(rawValue: 0x10000 | 3)
    public static let uChar4 = MDLVertexFormat(rawValue: 0x10000 | 4)

    public static let char = MDLVertexFormat(rawValue: 0x20000 | 1)
    public static let char2 = MDLVertexFormat(rawValue: 0x20000 | 2)
    public static let char3 = MDLVertexFormat(rawValue: 0x20000 | 3)
    public static let char4 = MDLVertexFormat(rawValue: 0x20000 | 4)

    public static let uCharNormalized = MDLVertexFormat(rawValue: 0x30000 | 1)
    public static let uChar2Normalized = MDLVertexFormat(rawValue: 0x30000 | 2)
    public static let uChar3Normalized = MDLVertexFormat(rawValue: 0x30000 | 3)
    public static let uChar4Normalized = MDLVertexFormat(rawValue: 0x30000 | 4)

    public static let charNormalized = MDLVertexFormat(rawValue: 0x40000 | 1)
    public static let char2Normalized = MDLVertexFormat(rawValue: 0x40000 | 2)
    public static let char3Normalized = MDLVertexFormat(rawValue: 0x40000 | 3)
    public static let char4Normalized = MDLVertexFormat(rawValue: 0x40000 | 4)

    public static let uShort = MDLVertexFormat(rawValue: 0x50000 | 1)
    public static let uShort2 = MDLVertexFormat(rawValue: 0x50000 | 2)
    public static let uShort3 = MDLVertexFormat(rawValue: 0x50000 | 3)
    public static let uShort4 = MDLVertexFormat(rawValue: 0x50000 | 4)

    public static let short = MDLVertexFormat(rawValue: 0x60000 | 1)
    public static let short2 = MDLVertexFormat(rawValue: 0x60000 | 2)
    public static let short3 = MDLVertexFormat(rawValue: 0x60000 | 3)
    public static let short4 = MDLVertexFormat(rawValue: 0x60000 | 4)

    public static let uShortNormalized = MDLVertexFormat(rawValue: 0x70000 | 1)
    public static let uShort2Normalized = MDLVertexFormat(rawValue: 0x70000 | 2)
    public static let uShort3Normalized = MDLVertexFormat(rawValue: 0x70000 | 3)
    public static let uShort4Normalized = MDLVertexFormat(rawValue: 0x70000 | 4)

    public static let shortNormalized = MDLVertexFormat(rawValue: 0x80000 | 1)
    public static let short2Normalized = MDLVertexFormat(rawValue: 0x80000 | 2)
    public static let short3Normalized = MDLVertexFormat(rawValue: 0x80000 | 3)
    public static let short4Normalized = MDLVertexFormat(rawValue: 0x80000 | 4)

    public static let uInt = MDLVertexFormat(rawValue: 0x90000 | 1)
    public static let uInt2 = MDLVertexFormat(rawValue: 0x90000 | 2)
    public static let uInt3 = MDLVertexFormat(rawValue: 0x90000 | 3)
    public static let uInt4 = MDLVertexFormat(rawValue: 0x90000 | 4)

    public static let int = MDLVertexFormat(rawValue: 0xA0000 | 1)
    public static let int2 = MDLVertexFormat(rawValue: 0xA0000 | 2)
    public static let int3 = MDLVertexFormat(rawValue: 0xA0000 | 3)
    public static let int4 = MDLVertexFormat(rawValue: 0xA0000 | 4)

    public static let half = MDLVertexFormat(rawValue: 0xB0000 | 1)
    public static let half2 = MDLVertexFormat(rawValue: 0xB0000 | 2)
    public static let half3 = MDLVertexFormat(rawValue: 0xB0000 | 3)
    public static let half4 = MDLVertexFormat(rawValue: 0xB0000 | 4)

    public static let float = MDLVertexFormat(rawValue: 0xC0000 | 1)
    public static let float2 = MDLVertexFormat(rawValue: 0xC0000 | 2)
    public static let float3 = MDLVertexFormat(rawValue: 0xC0000 | 3)
    public static let float4 = MDLVertexFormat(rawValue: 0xC0000 | 4)

    public static let int1010102Normalized = MDLVertexFormat(rawValue: 0xA0000 | 0x1000 | 4)
    public static let uInt1010102Normalized = MDLVertexFormat(rawValue: 0x90000 | 0x1000 | 4)
}

public enum MDLMeshBufferType: UInt, Sendable {
    case vertex = 1
    case index = 2
    case custom = 3
}

public enum MDLGeometryType: Int, Sendable {
    case points = 0
    case lines = 1
    case triangles = 2
    case triangleStrips = 3
    case quads = 4
    case variableTopology = 5
}

public enum MDLIndexBitDepth: UInt, Sendable {
    case invalid = 0
    case uInt8 = 8
    case uInt16 = 16
    case uInt32 = 32
}

open class MDLMeshBufferMap: NSObject, @unchecked Sendable {
    public let bytes: Data

    public init(bytes: Data) {
        self.bytes = bytes
        super.init()
    }
}

public protocol MDLMeshBufferZone: AnyObject {
    var capacity: Int { get }
}

public protocol MDLMeshBufferAllocator: AnyObject {
    func newZone(_ capacity: Int) -> any MDLMeshBufferZone
    func newBuffer(_ length: Int, type: MDLMeshBufferType) -> any MDLMeshBuffer
    func newBuffer(with data: Data, type: MDLMeshBufferType) -> any MDLMeshBuffer
}

public protocol MDLMeshBuffer: AnyObject {
    var length: Int { get }
    var type: MDLMeshBufferType { get }
    func fill(_ data: Data, offset: Int)
    func map() -> MDLMeshBufferMap
}

open class MDLMeshBufferData: NSObject, MDLMeshBuffer, @unchecked Sendable {
    public let length: Int
    public let allocator: any MDLMeshBufferAllocator
    public let type: MDLMeshBufferType
    private var storage: Data

    public init(allocator: any MDLMeshBufferAllocator, length: Int, type: MDLMeshBufferType, data: Data = Data()) {
        self.allocator = allocator
        self.length = max(length, 0)
        self.type = type
        var storage = Data(count: self.length)
        if !data.isEmpty && self.length > 0 {
            let count = min(data.count, self.length)
            storage.replaceSubrange(0..<count, with: data.prefix(count))
        }
        self.storage = storage
        super.init()
    }

    public func fill(_ data: Data, offset: Int) {
        guard offset >= 0, offset <= storage.count else { return }
        let count = min(data.count, storage.count - offset)
        guard count > 0 else { return }
        storage.replaceSubrange(offset..<(offset + count), with: data.prefix(count))
    }

    public func map() -> MDLMeshBufferMap {
        MDLMeshBufferMap(bytes: storage)
    }
}

open class MDLMeshBufferDataAllocator: NSObject, MDLMeshBufferAllocator, @unchecked Sendable {
    public override init() {
        super.init()
    }

    public func newZone(_ capacity: Int) -> any MDLMeshBufferZone {
        MetalKitSoftwareMeshZone(capacity: capacity)
    }

    public func newBuffer(_ length: Int, type: MDLMeshBufferType) -> any MDLMeshBuffer {
        MDLMeshBufferData(allocator: self, length: length, type: type)
    }

    public func newBuffer(with data: Data, type: MDLMeshBufferType) -> any MDLMeshBuffer {
        MDLMeshBufferData(allocator: self, length: data.count, type: type, data: data)
    }
}

final class MetalKitSoftwareMeshZone: NSObject, MDLMeshBufferZone, @unchecked Sendable {
    let capacity: Int

    init(capacity: Int) {
        self.capacity = max(capacity, 0)
        super.init()
    }
}

open class MDLVertexAttribute: NSObject, @unchecked Sendable {
    public var name: String
    public var format: MDLVertexFormat
    public var offset: Int
    public var bufferIndex: Int

    public init(name: String, format: MDLVertexFormat, offset: Int, bufferIndex: Int) {
        self.name = name
        self.format = format
        self.offset = max(offset, 0)
        self.bufferIndex = max(bufferIndex, 0)
        super.init()
    }
}

open class MDLVertexBufferLayout: NSObject, @unchecked Sendable {
    public var stride: Int

    public init(stride: Int) {
        self.stride = max(stride, 0)
        super.init()
    }
}

open class MDLVertexDescriptor: NSObject, @unchecked Sendable {
    public var attributes: [MDLVertexAttribute]
    public var layouts: [MDLVertexBufferLayout]

    public override init() {
        self.attributes = []
        self.layouts = []
        super.init()
    }

    public init(attributes: [MDLVertexAttribute], layouts: [MDLVertexBufferLayout]) {
        self.attributes = attributes
        self.layouts = layouts
        super.init()
    }
}

open class MDLSubmesh: NSObject, @unchecked Sendable {
    public var name: String
    public var indexBuffer: any MDLMeshBuffer
    public var indexCount: Int
    public var indexType: MDLIndexBitDepth
    public var geometryType: MDLGeometryType

    public init(
        name: String = "",
        indexBuffer: any MDLMeshBuffer,
        indexCount: Int,
        indexType: MDLIndexBitDepth,
        geometryType: MDLGeometryType
    ) {
        self.name = name
        self.indexBuffer = indexBuffer
        self.indexCount = max(indexCount, 0)
        self.indexType = indexType
        self.geometryType = geometryType
        super.init()
    }
}

open class MDLMesh: NSObject, @unchecked Sendable {
    public var name: String
    public var vertexCount: Int
    public var vertexBuffers: [any MDLMeshBuffer]
    public var vertexDescriptor: MDLVertexDescriptor
    public var submeshes: [MDLSubmesh]

    public init(
        vertexBuffers: [any MDLMeshBuffer],
        vertexCount: Int,
        vertexDescriptor: MDLVertexDescriptor,
        submeshes: [MDLSubmesh],
        name: String = ""
    ) {
        self.vertexBuffers = vertexBuffers
        self.vertexCount = max(vertexCount, 0)
        self.vertexDescriptor = vertexDescriptor
        self.submeshes = submeshes
        self.name = name
        super.init()
    }
}

open class MDLAsset: NSObject, @unchecked Sendable {
    public var meshes: [MDLMesh]

    public init(meshes: [MDLMesh] = []) {
        self.meshes = meshes
        super.init()
    }
}

open class MDLTexture: NSObject, @unchecked Sendable {
    public var name: String
    public var width: Int
    public var height: Int
    public var channelCount: Int
    public var texels: Data

    public init(name: String = "", width: Int, height: Int, channelCount: Int = 4, texels: Data = Data()) {
        self.name = name
        self.width = max(width, 0)
        self.height = max(height, 0)
        self.channelCount = max(channelCount, 0)
        self.texels = texels
        super.init()
    }
}
