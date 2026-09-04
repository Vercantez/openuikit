import Foundation

open class MTLTextureDescriptor: NSObject, @unchecked Sendable {
    public var textureType: MTLTextureType = .type2D
    public var pixelFormat: MTLPixelFormat = .rgba8Unorm
    public var width: Int = 1
    public var height: Int = 1
    public var depth: Int = 1
    public var mipmapLevelCount: Int = 1
    public var sampleCount: Int = 1
    public var arrayLength: Int = 1
    public var resourceOptions: MTLResourceOptions = .storageModeShared
    public var cpuCacheMode: MTLCPUCacheMode = .defaultCache
    public var storageMode: MTLStorageMode = .shared
    public var hazardTrackingMode: MTLHazardTrackingMode = .default
    public var usage: MTLTextureUsage = .shaderRead
    public var allowGPUOptimizedContents: Bool = false
    public var compressionType: MTLTextureCompressionType = .lossless
    public var swizzle = MTLTextureSwizzleChannels()
    public var placementSparsePageSize: MTLSparsePageSize = .size16

    public override init() {
        super.init()
    }

    public class func texture2DDescriptor(
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
        descriptor.depth = 1
        descriptor.mipmapLevelCount = mipmapped ? LinuxMTLTexture.mipmapCount(width: width, height: height) : 1
        descriptor.usage = [.shaderRead, .shaderWrite, .renderTarget]
        return descriptor
    }

    public class func textureCubeDescriptor(
        pixelFormat: MTLPixelFormat,
        size: Int,
        mipmapped: Bool
    ) -> MTLTextureDescriptor {
        let descriptor = MTLTextureDescriptor()
        descriptor.textureType = .typeCube
        descriptor.pixelFormat = pixelFormat
        descriptor.width = size
        descriptor.height = size
        descriptor.depth = 1
        descriptor.mipmapLevelCount = mipmapped ? LinuxMTLTexture.mipmapCount(width: size, height: size) : 1
        return descriptor
    }

    public class func textureBufferDescriptor(
        with pixelFormat: MTLPixelFormat,
        width: Int,
        resourceOptions: MTLResourceOptions = [],
        usage: MTLTextureUsage
    ) -> MTLTextureDescriptor {
        let descriptor = MTLTextureDescriptor()
        descriptor.textureType = .typeTextureBuffer
        descriptor.pixelFormat = pixelFormat
        descriptor.width = width
        descriptor.height = 1
        descriptor.resourceOptions = resourceOptions
        descriptor.usage = usage
        return descriptor
    }
}

open class MTLSamplerDescriptor: NSObject, @unchecked Sendable {
    public var minFilter: MTLSamplerMinMagFilter = .nearest
    public var magFilter: MTLSamplerMinMagFilter = .nearest
    public var mipFilter: MTLSamplerMipFilter = .notMipmapped
    public var maxAnisotropy: Int = 1
    public var sAddressMode: MTLSamplerAddressMode = .clampToEdge
    public var tAddressMode: MTLSamplerAddressMode = .clampToEdge
    public var rAddressMode: MTLSamplerAddressMode = .clampToEdge
    public var borderColor: MTLSamplerBorderColor = .transparentBlack
    public var normalizedCoordinates: Bool = true
    public var lodMinClamp: Float = 0
    public var lodMaxClamp: Float = Float.greatestFiniteMagnitude
    public var lodBias: Float = 0
    public var lodAverage: Bool = false
    public var compareFunction: MTLCompareFunction = .never
    public var supportArgumentBuffers: Bool = false
    public var reductionMode: MTLSamplerReductionMode = .weightedAverage
    public var label: String?

    public override init() {
        super.init()
    }
}

open class MTLStencilDescriptor: NSObject, @unchecked Sendable {
    public var stencilCompareFunction: MTLCompareFunction = .always
    public var stencilFailureOperation: MTLStencilOperation = .keep
    public var depthFailureOperation: MTLStencilOperation = .keep
    public var depthStencilPassOperation: MTLStencilOperation = .keep
    public var readMask: UInt32 = 0xFFFFFFFF
    public var writeMask: UInt32 = 0xFFFFFFFF

    public override init() {
        super.init()
    }
}

open class MTLDepthStencilDescriptor: NSObject, @unchecked Sendable {
    public var depthCompareFunction: MTLCompareFunction = .always
    public var isDepthWriteEnabled: Bool = false
    public var frontFaceStencil: MTLStencilDescriptor! = MTLStencilDescriptor()
    public var backFaceStencil: MTLStencilDescriptor! = MTLStencilDescriptor()
    public var label: String?

    public override init() {
        super.init()
    }
}

open class MTLHeapDescriptor: NSObject, @unchecked Sendable {
    public var size: Int = 0
    public var storageMode: MTLStorageMode = .shared
    public var cpuCacheMode: MTLCPUCacheMode = .defaultCache
    public var sparsePageSize: MTLSparsePageSize = .size16
    public var hazardTrackingMode: MTLHazardTrackingMode = .default
    public var resourceOptions: MTLResourceOptions = .storageModeShared
    public var type: MTLHeapType = .automatic
    public var maxCompatiblePlacementSparsePageSize: MTLSparsePageSize = .size16

    public override init() {
        super.init()
    }
}

open class MTLCompileOptions: NSObject, @unchecked Sendable {
    public var preprocessorMacros: [String: NSObject]?
    public var fastMathEnabled: Bool = true
    public var languageVersion: MTLLanguageVersion = .version2_4
    public var libraryType: MTLLibraryType = .executable
    public var installName: String?
    public var libraries: [any MTLDynamicLibrary]?
    public var preserveInvariance: Bool = false
    public var optimizationLevel: MTLLibraryOptimizationLevel = .default
    public var compileSymbolVisibility: MTLCompileSymbolVisibility = .default
    public var allowReferencingUndefinedSymbols: Bool = false
    public var maxTotalThreadsPerThreadgroup: Int = 0
    public var mathMode: MTLMathMode = .safe
    public var mathFloatingPointFunctions: MTLMathFloatingPointFunctions = .fast
    public var enableLogging: Bool = false
    public var requiredThreadsPerThreadgroup = MTLSize()

    public override init() {
        super.init()
    }
}

open class MTLCommandQueueDescriptor: NSObject, @unchecked Sendable {
    public var maxCommandBufferCount: Int = 0
    public var logState: (any MTLLogState)?

    public override init() {
        super.init()
    }
}

open class MTLCommandBufferDescriptor: NSObject, @unchecked Sendable {
    public var retainedReferences: Bool = true
    public var errorOptions: MTLCommandBufferErrorOption = []
    public var logState: (any MTLLogState)?

    public override init() {
        super.init()
    }
}

open class MTLCaptureDescriptor: NSObject, @unchecked Sendable {
    public var captureObject: Any?
    public var destination: MTLCaptureDestination = .developerTools
    public var outputURL: URL?

    public override init() {
        super.init()
    }
}

open class MTLRenderPassAttachmentDescriptor: NSObject, @unchecked Sendable {
    public var texture: (any MTLTexture)?
    public var level: Int = 0
    public var slice: Int = 0
    public var depthPlane: Int = 0
    public var loadAction: MTLLoadAction = .dontCare
    public var storeAction: MTLStoreAction = .dontCare
    public var storeActionOptions: MTLStoreActionOptions = []
    public var resolveTexture: (any MTLTexture)?
    public var resolveLevel: Int = 0
    public var resolveSlice: Int = 0
    public var resolveDepthPlane: Int = 0

    public override init() {
        super.init()
    }
}

open class MTLRenderPassColorAttachmentDescriptor: MTLRenderPassAttachmentDescriptor, @unchecked Sendable {
    public var clearColor = MTLClearColor()
}

open class MTLRenderPassDepthAttachmentDescriptor: MTLRenderPassAttachmentDescriptor, @unchecked Sendable {
    public var clearDepth: Double = 1
    public var depthResolveFilter: MTLMultisampleDepthResolveFilter = .sample0
}

open class MTLRenderPassStencilAttachmentDescriptor: MTLRenderPassAttachmentDescriptor, @unchecked Sendable {
    public var clearStencil: UInt32 = 0
    public var stencilResolveFilter: MTLMultisampleStencilResolveFilter = .sample0
}

open class MTLRenderPassColorAttachmentDescriptorArray: NSObject, @unchecked Sendable {
    private var storage: [Int: MTLRenderPassColorAttachmentDescriptor] = [:]

    public override init() {
        super.init()
    }

    public subscript(attachmentIndex: Int) -> MTLRenderPassColorAttachmentDescriptor! {
        get {
            if let existing = storage[attachmentIndex] {
                return existing
            }
            let created = MTLRenderPassColorAttachmentDescriptor()
            storage[attachmentIndex] = created
            return created
        }
        set {
            storage[attachmentIndex] = newValue
        }
    }
}

open class MTLRenderPassDescriptor: NSObject, @unchecked Sendable {
    public let colorAttachments = MTLRenderPassColorAttachmentDescriptorArray()
    public var depthAttachment: MTLRenderPassDepthAttachmentDescriptor! = MTLRenderPassDepthAttachmentDescriptor()
    public var stencilAttachment: MTLRenderPassStencilAttachmentDescriptor! = MTLRenderPassStencilAttachmentDescriptor()
    public var visibilityResultBuffer: (any MTLBuffer)?
    public var visibilityResultType: MTLVisibilityResultType = .reset
    public var renderTargetArrayLength: Int = 0
    public var renderTargetHeight: Int = 0
    public var renderTargetWidth: Int = 0
    public var defaultRasterSampleCount: Int = 0
    public var imageblockSampleLength: Int = 0
    public var threadgroupMemoryLength: Int = 0
    public var tileWidth: Int = 0
    public var tileHeight: Int = 0
    public var supportColorAttachmentMapping: Bool = false
    private var samplePositions: [MTLSamplePosition] = []

    public override init() {
        super.init()
    }

    public func getSamplePositions() -> [MTLSamplePosition] {
        samplePositions
    }

    public func setSamplePositions(_ positions: [MTLSamplePosition]) {
        samplePositions = positions
    }
}

open class MTLRenderPipelineColorAttachmentDescriptor: NSObject, @unchecked Sendable {
    public var pixelFormat: MTLPixelFormat = .invalid
    public var isBlendingEnabled: Bool = false
    public var sourceRGBBlendFactor: MTLBlendFactor = .one
    public var destinationRGBBlendFactor: MTLBlendFactor = .zero
    public var rgbBlendOperation: MTLBlendOperation = .add
    public var sourceAlphaBlendFactor: MTLBlendFactor = .one
    public var destinationAlphaBlendFactor: MTLBlendFactor = .zero
    public var alphaBlendOperation: MTLBlendOperation = .add
    public var writeMask: MTLColorWriteMask = .all

    public override init() {
        super.init()
    }
}

open class MTLRenderPipelineColorAttachmentDescriptorArray: NSObject, @unchecked Sendable {
    private var storage: [Int: MTLRenderPipelineColorAttachmentDescriptor] = [:]

    public override init() {
        super.init()
    }

    public subscript(attachmentIndex: Int) -> MTLRenderPipelineColorAttachmentDescriptor! {
        get {
            if let existing = storage[attachmentIndex] {
                return existing
            }
            let created = MTLRenderPipelineColorAttachmentDescriptor()
            storage[attachmentIndex] = created
            return created
        }
        set {
            storage[attachmentIndex] = newValue
        }
    }
}

open class MTLVertexAttributeDescriptor: NSObject, @unchecked Sendable {
    public var format: MTLVertexFormat = .invalid
    public var offset: Int = 0
    public var bufferIndex: Int = 0

    public override init() {
        super.init()
    }
}

open class MTLVertexAttributeDescriptorArray: NSObject, @unchecked Sendable {
    private var storage: [Int: MTLVertexAttributeDescriptor] = [:]

    public override init() {
        super.init()
    }

    public subscript(index: Int) -> MTLVertexAttributeDescriptor! {
        get {
            if let existing = storage[index] {
                return existing
            }
            let created = MTLVertexAttributeDescriptor()
            storage[index] = created
            return created
        }
        set {
            storage[index] = newValue
        }
    }
}

open class MTLVertexBufferLayoutDescriptor: NSObject, @unchecked Sendable {
    public var stride: Int = 0
    public var stepFunction: MTLVertexStepFunction = .perVertex
    public var stepRate: Int = 1

    public override init() {
        super.init()
    }
}

open class MTLVertexBufferLayoutDescriptorArray: NSObject, @unchecked Sendable {
    private var storage: [Int: MTLVertexBufferLayoutDescriptor] = [:]

    public override init() {
        super.init()
    }

    public subscript(index: Int) -> MTLVertexBufferLayoutDescriptor! {
        get {
            if let existing = storage[index] {
                return existing
            }
            let created = MTLVertexBufferLayoutDescriptor()
            storage[index] = created
            return created
        }
        set {
            storage[index] = newValue
        }
    }
}

open class MTLVertexDescriptor: NSObject, @unchecked Sendable {
    public let attributes = MTLVertexAttributeDescriptorArray()
    public let layouts = MTLVertexBufferLayoutDescriptorArray()

    public override init() {
        super.init()
    }

    public func reset() {
        for index in 0..<31 {
            attributes[index].format = .invalid
            attributes[index].offset = 0
            attributes[index].bufferIndex = 0
            layouts[index].stride = 0
            layouts[index].stepFunction = .perVertex
            layouts[index].stepRate = 1
        }
    }
}

open class MTLRenderPipelineDescriptor: NSObject, @unchecked Sendable {
    public var label: String?
    public var vertexFunction: (any MTLFunction)?
    public var fragmentFunction: (any MTLFunction)?
    public var vertexDescriptor: MTLVertexDescriptor?
    public let colorAttachments = MTLRenderPipelineColorAttachmentDescriptorArray()
    public var depthAttachmentPixelFormat: MTLPixelFormat = .invalid
    public var stencilAttachmentPixelFormat: MTLPixelFormat = .invalid
    public var sampleCount: Int = 1
    public var rasterSampleCount: Int = 1
    public var isAlphaToCoverageEnabled: Bool = false
    public var isAlphaToOneEnabled: Bool = false
    public var isRasterizationEnabled: Bool = true
    public var maxVertexAmplificationCount: Int = 1
    public var supportIndirectCommandBuffers: Bool = false
    public var maxVertexCallStackDepth: Int = 1
    public var maxFragmentCallStackDepth: Int = 1
    public var supportAddingVertexBinaryFunctions: Bool = false
    public var supportAddingFragmentBinaryFunctions: Bool = false

    public override init() {
        super.init()
    }

    public func reset() {
        label = nil
        vertexFunction = nil
        fragmentFunction = nil
        vertexDescriptor = nil
        depthAttachmentPixelFormat = .invalid
        stencilAttachmentPixelFormat = .invalid
        sampleCount = 1
        rasterSampleCount = 1
        isAlphaToCoverageEnabled = false
        isAlphaToOneEnabled = false
        isRasterizationEnabled = true
        for index in 0..<8 {
            let attachment = colorAttachments[index]!
            attachment.pixelFormat = .invalid
            attachment.isBlendingEnabled = false
            attachment.writeMask = .all
        }
    }
}

open class MTLComputePipelineDescriptor: NSObject, @unchecked Sendable {
    public var label: String?
    public var computeFunction: (any MTLFunction)?
    public var threadGroupSizeIsMultipleOfThreadExecutionWidth: Bool = false
    public var maxTotalThreadsPerThreadgroup: Int = 0
    public var supportIndirectCommandBuffers: Bool = false
    public var maxCallStackDepth: Int = 1
    public var supportAddingBinaryFunctions: Bool = false
    public var requiredThreadsPerThreadgroup = MTLSize()

    public override init() {
        super.init()
    }

    public func reset() {
        label = nil
        computeFunction = nil
        threadGroupSizeIsMultipleOfThreadExecutionWidth = false
        maxTotalThreadsPerThreadgroup = 0
        supportIndirectCommandBuffers = false
        maxCallStackDepth = 1
        supportAddingBinaryFunctions = false
        requiredThreadsPerThreadgroup = MTLSize()
    }
}
