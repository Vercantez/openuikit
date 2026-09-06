import Foundation

// Isolated-host lookalikes for Metal / simd types that appear in MetalFX
// signatures. The sealed `swiftc` gate compiles this module against toolchain
// Foundation only. The later EC2 integration build must import the real
// `Metal` module and drop this file; these names are not Apple GPU objects.

public struct simd_float4x4: Sendable {
    public var columns: (SIMD4<Float>, SIMD4<Float>, SIMD4<Float>, SIMD4<Float>)

    public init(columns: (SIMD4<Float>, SIMD4<Float>, SIMD4<Float>, SIMD4<Float>)) {
        self.columns = columns
    }

    public static let identity = simd_float4x4(
        columns: (
            SIMD4<Float>(1, 0, 0, 0),
            SIMD4<Float>(0, 1, 0, 0),
            SIMD4<Float>(0, 0, 1, 0),
            SIMD4<Float>(0, 0, 0, 1)
        )
    )

    public static let zero = simd_float4x4(
        columns: (
            SIMD4<Float>(repeating: 0),
            SIMD4<Float>(repeating: 0),
            SIMD4<Float>(repeating: 0),
            SIMD4<Float>(repeating: 0)
        )
    )

    public static func == (lhs: simd_float4x4, rhs: simd_float4x4) -> Bool {
        lhs.columns.0 == rhs.columns.0
            && lhs.columns.1 == rhs.columns.1
            && lhs.columns.2 == rhs.columns.2
            && lhs.columns.3 == rhs.columns.3
    }
}

extension simd_float4x4: Equatable {}

public struct MTLPixelFormat: RawRepresentable, Equatable, Hashable, Sendable {
    public var rawValue: UInt

    public init(rawValue: UInt) {
        self.rawValue = rawValue
    }

    public static let invalid = MTLPixelFormat(rawValue: 0)
    public static let r8Unorm = MTLPixelFormat(rawValue: 10)
    public static let r16Float = MTLPixelFormat(rawValue: 25)
    public static let rg16Float = MTLPixelFormat(rawValue: 65)
    public static let r32Float = MTLPixelFormat(rawValue: 55)
    public static let rgba8Unorm = MTLPixelFormat(rawValue: 70)
    public static let bgra8Unorm = MTLPixelFormat(rawValue: 80)
    public static let rgba16Float = MTLPixelFormat(rawValue: 115)
    public static let rgba32Float = MTLPixelFormat(rawValue: 125)
    public static let depth32Float = MTLPixelFormat(rawValue: 252)
}

public struct MTLTextureUsage: OptionSet, Hashable, Sendable {
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

public protocol MTLDevice: AnyObject {
    var name: String { get }
}

public protocol MTLTexture: AnyObject {
    var width: Int { get }
    var height: Int { get }
    var pixelFormat: MTLPixelFormat { get }
    var usage: MTLTextureUsage { get }
}

public protocol MTLFence: AnyObject {
    var label: String? { get set }
}

public protocol MTLCommandBuffer: AnyObject {
    var device: any MTLDevice { get }
    var label: String? { get set }
}

public protocol MTL4CommandBuffer: AnyObject {
    var device: any MTLDevice { get }
    var label: String? { get set }
}

public protocol MTL4Compiler: AnyObject {
    var device: any MTLDevice { get }
}

public final class MetalFXHostDevice: NSObject, MTLDevice {
    public let name: String

    public init(name: String = "OpenUIKit MetalFX Host") {
        self.name = name
        super.init()
    }
}

public final class MetalFXHostTexture: NSObject, MTLTexture {
    public let width: Int
    public let height: Int
    public let pixelFormat: MTLPixelFormat
    public let usage: MTLTextureUsage
    public private(set) var bytes: [UInt8]
    public private(set) var mutationCount: Int = 0

    public init(
        width: Int,
        height: Int,
        pixelFormat: MTLPixelFormat,
        usage: MTLTextureUsage = .unknown,
        fill: UInt8 = 0
    ) {
        self.width = max(width, 0)
        self.height = max(height, 0)
        self.pixelFormat = pixelFormat
        self.usage = usage
        self.bytes = [UInt8](repeating: fill, count: max(width, 0) * max(height, 0) * 4)
        super.init()
    }

    public func replaceBytes(with newBytes: [UInt8]) {
        bytes = newBytes
        mutationCount += 1
    }
}

public final class MetalFXHostFence: NSObject, MTLFence {
    public var label: String?

    public override init() {
        super.init()
    }
}

public final class MetalFXHostCommandBuffer: NSObject, MTLCommandBuffer {
    public let device: any MTLDevice
    public var label: String?
    public private(set) var encodeCallCount: Int = 0

    public init(device: any MTLDevice) {
        self.device = device
        super.init()
    }

    public func noteEncode() {
        encodeCallCount += 1
    }
}

public final class MetalFXHostMTL4CommandBuffer: NSObject, MTL4CommandBuffer {
    public let device: any MTLDevice
    public var label: String?
    public private(set) var encodeCallCount: Int = 0

    public init(device: any MTLDevice) {
        self.device = device
        super.init()
    }

    public func noteEncode() {
        encodeCallCount += 1
    }
}

public final class MetalFXHostMTL4Compiler: NSObject, MTL4Compiler {
    public let device: any MTLDevice

    public init(device: any MTLDevice) {
        self.device = device
        super.init()
    }
}
