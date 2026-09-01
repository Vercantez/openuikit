import Foundation

// Local Metal stand-ins. This seed environment has no `Metal` Swift module.
// Signatures match the pinned MPS overlay so Linux sources compile. These
// types are not Apple GPU objects and must be replaced with `import Metal`
// during central integration.

public typealias vector_float4 = SIMD4<Float>
public typealias vector_ushort4 = SIMD4<UInt16>

public protocol MTLResource: AnyObject {
    var label: String? { get set }
    var allocatedSize: Int { get }
}

public protocol MTLDevice: AnyObject {
    var name: String { get }
    var registryID: UInt64 { get }
    var maxBufferLength: Int { get }
}

public protocol MTLCommandBuffer: AnyObject {
    var device: any MTLDevice { get }
    var label: String? { get set }
}

public protocol MTLTexture: MTLResource {
    var device: any MTLDevice { get }
    var width: Int { get }
    var height: Int { get }
    var depth: Int { get }
    var arrayLength: Int { get }
    var pixelFormat: MTLPixelFormat { get }
    var textureType: MTLTextureType { get }
    var usage: MTLTextureUsage { get }
}

public protocol MTLBuffer: MTLResource {
    var device: any MTLDevice { get }
    var length: Int { get }
    var contents: UnsafeMutableRawPointer { get }
}

public struct MTLOrigin: Equatable, Sendable {
    public var x: Int
    public var y: Int
    public var z: Int

    public init(x: Int, y: Int, z: Int) {
        self.x = x
        self.y = y
        self.z = z
    }
}

public struct MTLSize: Equatable, Sendable {
    public var width: Int
    public var height: Int
    public var depth: Int

    public init(width: Int, height: Int, depth: Int) {
        self.width = width
        self.height = height
        self.depth = depth
    }
}

public struct MTLRegion: Equatable, Sendable {
    public var origin: MTLOrigin
    public var size: MTLSize

    public init(origin: MTLOrigin, size: MTLSize) {
        self.origin = origin
        self.size = size
    }

    public static func make2D(_ x: Int, _ y: Int, _ width: Int, _ height: Int) -> MTLRegion {
        MTLRegion(
            origin: MTLOrigin(x: x, y: y, z: 0),
            size: MTLSize(width: width, height: height, depth: 1)
        )
    }
}

public struct MTLPixelFormat: RawRepresentable, Equatable, Hashable, Sendable {
    public let rawValue: UInt

    public init(rawValue: UInt) {
        self.rawValue = rawValue
    }

    public static let invalid = MTLPixelFormat(rawValue: 0)
    public static let r8Unorm = MTLPixelFormat(rawValue: 10)
    public static let r16Float = MTLPixelFormat(rawValue: 25)
    public static let r32Float = MTLPixelFormat(rawValue: 55)
    public static let rgba8Unorm = MTLPixelFormat(rawValue: 70)
    public static let rgba16Float = MTLPixelFormat(rawValue: 115)
    public static let rgba32Float = MTLPixelFormat(rawValue: 125)
    public static let bgra8Unorm = MTLPixelFormat(rawValue: 80)
}

public struct MTLTextureUsage: OptionSet, Sendable, Hashable {
    public let rawValue: UInt

    public init(rawValue: UInt) {
        self.rawValue = rawValue
    }

    public static let unknown = MTLTextureUsage([])
    public static let shaderRead = MTLTextureUsage(rawValue: 1 << 0)
    public static let shaderWrite = MTLTextureUsage(rawValue: 1 << 1)
    public static let renderTarget = MTLTextureUsage(rawValue: 1 << 2)
    public static let pixelFormatView = MTLTextureUsage(rawValue: 1 << 4)
}

public enum MTLCPUCacheMode: UInt, Sendable, Hashable {
    case defaultCache = 0
    case writeCombined = 1
}

public enum MTLStorageMode: UInt, Sendable, Hashable {
    case `shared` = 0
    case managed = 1
    case `private` = 2
    case memoryless = 3
}

public enum MTLTextureType: UInt, Sendable, Hashable {
    case type1D = 0
    case type1DArray = 1
    case type2D = 2
    case type2DArray = 3
    case type2DMultisample = 4
    case typeCube = 5
    case typeCubeArray = 6
    case type3D = 7
}

public final class MTLTextureDescriptor: NSObject {
    public var textureType: MTLTextureType = .type2D
    public var pixelFormat: MTLPixelFormat = .rgba8Unorm
    public var width: Int = 1
    public var height: Int = 1
    public var depth: Int = 1
    public var mipmapLevelCount: Int = 1
    public var sampleCount: Int = 1
    public var arrayLength: Int = 1
    public var cpuCacheMode: MTLCPUCacheMode = .defaultCache
    public var storageMode: MTLStorageMode = .shared
    public var usage: MTLTextureUsage = [.shaderRead, .shaderWrite]

    public override init() {
        super.init()
    }

    public static func texture2DDescriptor(
        pixelFormat: MTLPixelFormat,
        width: Int,
        height: Int,
        mipmapped: Bool
    ) -> MTLTextureDescriptor {
        let descriptor = MTLTextureDescriptor()
        descriptor.textureType = .type2D
        descriptor.pixelFormat = pixelFormat
        descriptor.width = width
        descriptor.height = height
        descriptor.mipmapLevelCount = mipmapped ? 2 : 1
        return descriptor
    }
}

/// CPU-backed device used to construct MPS objects on Linux. It is not a
/// Metal GPU device; `MPSSupportsMTLDevice` stays false for every handle.
public final class MPSHostDevice: NSObject, MTLDevice {
    public static let shared = MPSHostDevice()

    public let name = "MPSHostDevice"
    public let registryID: UInt64 = 0
    public let maxBufferLength = 1_073_741_824

    public func makeBuffer(length: Int) -> MPSHostBuffer {
        MPSHostBuffer(device: self, length: max(length, 0))
    }

    public func makeTexture(descriptor: MTLTextureDescriptor) -> MPSHostTexture {
        MPSHostTexture(device: self, descriptor: descriptor)
    }

    public func makeCommandBuffer() -> MPSHostCommandBuffer {
        MPSHostCommandBuffer(device: self)
    }
}

public final class MPSHostBuffer: NSObject, MTLBuffer {
    public let device: any MTLDevice
    public var label: String?
    public let length: Int
    private var storage: UnsafeMutableRawBufferPointer

    public init(device: any MTLDevice, length: Int) {
        self.device = device
        self.length = length
        self.storage = UnsafeMutableRawBufferPointer.allocate(
            byteCount: max(length, 1),
            alignment: 16
        )
        self.storage.initializeMemory(as: UInt8.self, repeating: 0)
        super.init()
    }

    deinit {
        storage.deallocate()
    }

    public var allocatedSize: Int { length }

    public var contents: UnsafeMutableRawPointer {
        storage.baseAddress!
    }
}

public final class MPSHostTexture: NSObject, MTLTexture {
    public let device: any MTLDevice
    public var label: String?
    public let width: Int
    public let height: Int
    public let depth: Int
    public let arrayLength: Int
    public let pixelFormat: MTLPixelFormat
    public let textureType: MTLTextureType
    public let usage: MTLTextureUsage
    public let bytesPerRow: Int
    private var storage: Data

    public init(device: any MTLDevice, descriptor: MTLTextureDescriptor) {
        self.device = device
        self.width = max(descriptor.width, 0)
        self.height = max(descriptor.height, 0)
        self.depth = max(descriptor.depth, 1)
        self.arrayLength = max(descriptor.arrayLength, 1)
        self.pixelFormat = descriptor.pixelFormat
        self.textureType = descriptor.textureType
        self.usage = descriptor.usage
        let pixelBytes = mpsHostBytesPerPixel(descriptor.pixelFormat)
        self.bytesPerRow = max(self.width, 1) * pixelBytes
        let total = self.bytesPerRow * max(self.height, 1) * self.depth * self.arrayLength
        self.storage = Data(count: max(total, 0))
        super.init()
    }

    public var allocatedSize: Int { storage.count }

    public var bytes: Data {
        get { storage }
        set { storage = newValue }
    }
}

public final class MPSHostCommandBuffer: NSObject, MTLCommandBuffer {
    public let device: any MTLDevice
    public var label: String?

    public init(device: any MTLDevice) {
        self.device = device
        super.init()
    }
}

func mpsHostBytesPerPixel(_ format: MTLPixelFormat) -> Int {
    switch format {
    case .r8Unorm:
        return 1
    case .r16Float:
        return 2
    case .r32Float:
        return 4
    case .rgba8Unorm, .bgra8Unorm:
        return 4
    case .rgba16Float:
        return 8
    case .rgba32Float:
        return 16
    default:
        return 4
    }
}
