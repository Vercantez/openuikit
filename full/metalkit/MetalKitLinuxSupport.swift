// Isolated-host lookalikes for dependency-owned types (Metal, UIKit,
// CoreGraphics, QuartzCore). The host gate compiles this lane standalone
// with toolchain Foundation only. The later integration build wires the
// real modules and must not treat these names as Apple GPU/UI success.

import Foundation

// MARK: - CoreGraphics

open class CGImage: NSObject, @unchecked Sendable {
    public let width: Int
    public let height: Int
    public let bitsPerComponent: Int
    public let bitsPerPixel: Int
    public let bytesPerRow: Int

    public init(
        width: Int,
        height: Int,
        bitsPerComponent: Int = 8,
        bitsPerPixel: Int = 32,
        bytesPerRow: Int = 0
    ) {
        self.width = max(width, 0)
        self.height = max(height, 0)
        self.bitsPerComponent = bitsPerComponent
        self.bitsPerPixel = bitsPerPixel
        self.bytesPerRow = bytesPerRow == 0 ? max(width, 0) * 4 : bytesPerRow
        super.init()
    }
}

// MARK: - UIKit

@MainActor
open class UIView: NSObject {
    open var frame: CGRect
    open var contentScaleFactor: CGFloat
    open var isHidden: Bool
    open var alpha: CGFloat

    public override init() {
        self.frame = .zero
        self.contentScaleFactor = 1
        self.isHidden = false
        self.alpha = 1
        super.init()
    }

    public init(frame: CGRect) {
        self.frame = frame
        self.contentScaleFactor = 1
        self.isHidden = false
        self.alpha = 1
        super.init()
    }

    public init(coder: NSCoder) {
        _ = coder
        self.frame = .zero
        self.contentScaleFactor = 1
        self.isHidden = false
        self.alpha = 1
        super.init()
    }

    open var bounds: CGRect {
        get { CGRect(origin: .zero, size: frame.size) }
        set { frame.size = newValue.size }
    }

    open func setNeedsDisplay() {}

    open func draw(_ rect: CGRect) {
        _ = rect
    }
}

// MARK: - Metal / QuartzCore

public enum MTLPixelFormat: UInt, Sendable, Equatable, Hashable {
    case invalid = 0
    case a8Unorm = 1
    case r8Unorm = 10
    case rgba8Unorm = 70
    case bgra8Unorm = 80
    case bgra8Unorm_srgb = 81
    case depth32Float = 252
    case stencil8 = 253
    case depth32Float_stencil8 = 260
}

public struct MTLClearColor: Equatable, Sendable {
    public var red: Double
    public var green: Double
    public var blue: Double
    public var alpha: Double

    public init(red: Double, green: Double, blue: Double, alpha: Double) {
        self.red = red
        self.green = green
        self.blue = blue
        self.alpha = alpha
    }
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

public enum MTLStorageMode: UInt, Sendable {
    case shared = 0
    case managed = 1
    case `private` = 2
    case memoryless = 3
}

public enum MTLLoadAction: UInt, Sendable {
    case dontCare = 0
    case load = 1
    case clear = 2
}

public enum MTLStoreAction: UInt, Sendable {
    case dontCare = 0
    case store = 1
    case multisampleResolve = 2
}

public struct MTLResourceOptions: OptionSet, Sendable {
    public let rawValue: UInt

    public init(rawValue: UInt) {
        self.rawValue = rawValue
    }

    public static let cpuCacheModeDefaultCache = MTLResourceOptions([])
    public static let storageModeShared = MTLResourceOptions(rawValue: UInt(MTLStorageMode.shared.rawValue) << 4)
    public static let storageModePrivate = MTLResourceOptions(rawValue: UInt(MTLStorageMode.private.rawValue) << 4)
}

open class MTLTextureDescriptor: NSObject, @unchecked Sendable {
    public var pixelFormat: MTLPixelFormat = .bgra8Unorm
    public var width: Int = 1
    public var height: Int = 1
    public var depth: Int = 1
    public var mipmapLevelCount: Int = 1
    public var sampleCount: Int = 1
    public var usage: MTLTextureUsage = [.shaderRead, .renderTarget]
    public var storageMode: MTLStorageMode = .shared

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
        descriptor.pixelFormat = pixelFormat
        descriptor.width = max(width, 1)
        descriptor.height = max(height, 1)
        descriptor.mipmapLevelCount = mipmapped ? 2 : 1
        return descriptor
    }
}

public protocol MTLBuffer: AnyObject {
    var device: any MTLDevice { get }
    var length: Int { get }
}

public protocol MTLTexture: AnyObject {
    var device: any MTLDevice { get }
    var width: Int { get }
    var height: Int { get }
    var depth: Int { get }
    var pixelFormat: MTLPixelFormat { get }
    var usage: MTLTextureUsage { get }
    var storageMode: MTLStorageMode { get }
    var sampleCount: Int { get }
}

public protocol MTLDrawable: AnyObject {
    func present()
}

public protocol CAMetalDrawable: MTLDrawable {
    var texture: any MTLTexture { get }
}

public protocol MTLDevice: AnyObject {
    var name: String { get }
    func makeBuffer(length: Int, options: MTLResourceOptions) -> (any MTLBuffer)?
    func makeTexture(descriptor: MTLTextureDescriptor) -> (any MTLTexture)?
}

open class MTLRenderPassAttachmentDescriptor: NSObject, @unchecked Sendable {
    public var texture: (any MTLTexture)?
    public var loadAction: MTLLoadAction = .clear
    public var storeAction: MTLStoreAction = .store
}

open class MTLRenderPassColorAttachmentDescriptor: MTLRenderPassAttachmentDescriptor, @unchecked Sendable {
    public var clearColor: MTLClearColor = MTLClearColor(red: 0, green: 0, blue: 0, alpha: 1)
}

open class MTLRenderPassColorAttachmentDescriptorArray: NSObject, @unchecked Sendable {
    private var slots: [Int: MTLRenderPassColorAttachmentDescriptor] = [:]

    public override init() {
        super.init()
    }

    public subscript(index: Int) -> MTLRenderPassColorAttachmentDescriptor {
        get {
            if let existing = slots[index] {
                return existing
            }
            let created = MTLRenderPassColorAttachmentDescriptor()
            slots[index] = created
            return created
        }
        set {
            slots[index] = newValue
        }
    }
}

open class MTLRenderPassDepthAttachmentDescriptor: MTLRenderPassAttachmentDescriptor, @unchecked Sendable {
    public var clearDepth: Double = 1
}

open class MTLRenderPassStencilAttachmentDescriptor: MTLRenderPassAttachmentDescriptor, @unchecked Sendable {
    public var clearStencil: UInt32 = 0
}

open class MTLRenderPassDescriptor: NSObject, @unchecked Sendable {
    public let colorAttachments = MTLRenderPassColorAttachmentDescriptorArray()
    public var depthAttachment = MTLRenderPassDepthAttachmentDescriptor()
    public var stencilAttachment = MTLRenderPassStencilAttachmentDescriptor()
    public var renderTargetWidth: Int = 0
    public var renderTargetHeight: Int = 0

    public override init() {
        super.init()
    }
}

open class MTL4RenderPassDescriptor: NSObject, @unchecked Sendable {
    public override init() {
        super.init()
    }
}

final class MetalKitLookalikeBuffer: MTLBuffer, @unchecked Sendable {
    let device: any MTLDevice
    let length: Int

    init(device: any MTLDevice, length: Int) {
        self.device = device
        self.length = max(length, 0)
    }
}

final class MetalKitLookalikeTexture: MTLTexture, @unchecked Sendable {
    let device: any MTLDevice
    let width: Int
    let height: Int
    let depth: Int
    let pixelFormat: MTLPixelFormat
    let usage: MTLTextureUsage
    let storageMode: MTLStorageMode
    let sampleCount: Int

    init(device: any MTLDevice, descriptor: MTLTextureDescriptor) {
        self.device = device
        self.width = max(descriptor.width, 1)
        self.height = max(descriptor.height, 1)
        self.depth = max(descriptor.depth, 1)
        self.pixelFormat = descriptor.pixelFormat
        self.usage = descriptor.usage
        self.storageMode = descriptor.storageMode
        self.sampleCount = max(descriptor.sampleCount, 1)
    }
}

public final class MetalSoftwareDrawable: CAMetalDrawable, @unchecked Sendable {
    public let texture: any MTLTexture
    public private(set) var presentCount = 0

    public init(texture: any MTLTexture) {
        self.texture = texture
    }

    public func present() {
        presentCount += 1
    }
}

public final class MetalSoftwareDevice: MTLDevice, @unchecked Sendable {
    public let name = "MetalKit isolated-host software device"

    public init() {}

    public func makeBuffer(length: Int, options: MTLResourceOptions) -> (any MTLBuffer)? {
        _ = options
        return MetalKitLookalikeBuffer(device: self, length: length)
    }

    public func makeTexture(descriptor: MTLTextureDescriptor) -> (any MTLTexture)? {
        MetalKitLookalikeTexture(device: self, descriptor: descriptor)
    }
}

private let isolatedHostDevice = MetalSoftwareDevice()

public func MTLCreateSystemDefaultDevice() -> (any MTLDevice)? {
    isolatedHostDevice
}
