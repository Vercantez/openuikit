public struct MTLResourceOptions: OptionSet, Hashable, Sendable {
    public let rawValue: UInt

    public init(rawValue: UInt) {
        self.rawValue = rawValue
    }

    public static let cpuCacheModeWriteCombined = MTLResourceOptions(rawValue: 1)
    public static let optionCPUCacheModeWriteCombined = MTLResourceOptions.cpuCacheModeWriteCombined
    /// Lookalike/Darwin alias for default CPU cache (raw 0). Not a distinct
    /// iPhoneOS 26.1 graph case; MetalKit's isolated-host overlay exports it.
    public static let cpuCacheModeDefaultCache = MTLResourceOptions([])
    public static let storageModeShared = MTLResourceOptions([])
    public static let storageModePrivate = MTLResourceOptions(rawValue: 2 << 4)
    public static let storageModeMemoryless = MTLResourceOptions(rawValue: 3 << 4)
    public static let hazardTrackingModeUntracked = MTLResourceOptions(rawValue: 1 << 8)
    public static let hazardTrackingModeTracked = MTLResourceOptions(rawValue: 2 << 8)
}

public struct MTLTextureUsage: OptionSet, Hashable, Sendable {
    public let rawValue: UInt

    public init(rawValue: UInt) {
        self.rawValue = rawValue
    }

    public static var unknown: MTLTextureUsage { [] }
    public static let shaderRead = MTLTextureUsage(rawValue: 0x0001)
    public static let shaderWrite = MTLTextureUsage(rawValue: 0x0002)
    public static let renderTarget = MTLTextureUsage(rawValue: 0x0004)
    public static let pixelFormatView = MTLTextureUsage(rawValue: 0x0010)
    public static let shaderAtomic = MTLTextureUsage(rawValue: 0x0020)
}

public struct MTLColorWriteMask: OptionSet, Hashable, Sendable {
    public let rawValue: UInt

    public init(rawValue: UInt) {
        self.rawValue = rawValue
    }

    public static let red = MTLColorWriteMask(rawValue: 0x1)
    public static let green = MTLColorWriteMask(rawValue: 0x2)
    public static let blue = MTLColorWriteMask(rawValue: 0x4)
    public static let alpha = MTLColorWriteMask(rawValue: 0x8)
    public static let all = MTLColorWriteMask(rawValue: 0xF)
}

public struct MTLBlitOption: OptionSet, Hashable, Sendable {
    public let rawValue: UInt

    public init(rawValue: UInt) {
        self.rawValue = rawValue
    }

    public static let depthFromDepthStencil = MTLBlitOption(rawValue: 1)
    public static let stencilFromDepthStencil = MTLBlitOption(rawValue: 2)
    public static let rowLinearPVRTC = MTLBlitOption(rawValue: 4)
}

public struct MTLBarrierScope: OptionSet, Hashable, Sendable {
    public let rawValue: UInt

    public init(rawValue: UInt) {
        self.rawValue = rawValue
    }

    public static let buffers = MTLBarrierScope(rawValue: 1)
    public static let textures = MTLBarrierScope(rawValue: 2)
}

public struct MTLResourceUsage: OptionSet, Hashable, Sendable {
    public let rawValue: UInt

    public init(rawValue: UInt) {
        self.rawValue = rawValue
    }

    public static let read = MTLResourceUsage(rawValue: 1)
    public static let write = MTLResourceUsage(rawValue: 2)
    public static let sample = MTLResourceUsage(rawValue: 4)
}

public struct MTLPipelineOption: OptionSet, Hashable, Sendable {
    public let rawValue: UInt

    public init(rawValue: UInt) {
        self.rawValue = rawValue
    }

    public static let argumentInfo = MTLPipelineOption(rawValue: 1)
    public static let bindingInfo = MTLPipelineOption.argumentInfo
    public static let bufferTypeInfo = MTLPipelineOption(rawValue: 2)
    public static let failOnBinaryArchiveMiss = MTLPipelineOption(rawValue: 4)
}

public struct MTLStoreActionOptions: OptionSet, Hashable, Sendable {
    public let rawValue: UInt

    public init(rawValue: UInt) {
        self.rawValue = rawValue
    }

    public static let customSamplePositions = MTLStoreActionOptions(rawValue: 1)
}

public struct MTLCommandBufferErrorOption: OptionSet, Hashable, Sendable {
    public let rawValue: UInt

    public init(rawValue: UInt) {
        self.rawValue = rawValue
    }

    public static let encoderExecutionStatus = MTLCommandBufferErrorOption(rawValue: 1)
}

public struct MTLRenderStages: OptionSet, Hashable, Sendable {
    public let rawValue: UInt

    public init(rawValue: UInt) {
        self.rawValue = rawValue
    }

    public static let vertex = MTLRenderStages(rawValue: 1 << 0)
    public static let fragment = MTLRenderStages(rawValue: 1 << 1)
    public static let tile = MTLRenderStages(rawValue: 1 << 2)
    public static let object = MTLRenderStages(rawValue: 1 << 3)
    public static let mesh = MTLRenderStages(rawValue: 1 << 4)
}

public struct MTLStages: OptionSet, Hashable, Sendable {
    public let rawValue: UInt

    public init(rawValue: UInt) {
        self.rawValue = rawValue
    }

    public static let vertex = MTLStages(rawValue: 1 << 0)
    public static let fragment = MTLStages(rawValue: 1 << 1)
    public static let tile = MTLStages(rawValue: 1 << 2)
    public static let object = MTLStages(rawValue: 1 << 3)
    public static let mesh = MTLStages(rawValue: 1 << 4)
    public static let dispatch = MTLStages(rawValue: 1 << 5)
    public static let blit = MTLStages(rawValue: 1 << 6)
    public static let accelerationStructure = MTLStages(rawValue: 1 << 7)
    public static let machineLearning = MTLStages(rawValue: 1 << 8)
    public static let resourceState = MTLStages(rawValue: 1 << 9)
    public static let all = MTLStages(rawValue: 0x7FFFFFFF)
}

public struct MTLFunctionOptions: OptionSet, Hashable, Sendable {
    public let rawValue: UInt

    public init(rawValue: UInt) {
        self.rawValue = rawValue
    }

    public static let compileToBinary = MTLFunctionOptions(rawValue: 1 << 0)
    public static let storeFunctionInMetalPipelinesScript = MTLFunctionOptions(rawValue: 1 << 1)
    public static var storeFunctionInMetalScript: MTLFunctionOptions { .storeFunctionInMetalPipelinesScript }
    public static let failOnBinaryArchiveMiss = MTLFunctionOptions(rawValue: 1 << 2)
    public static let pipelineIndependent = MTLFunctionOptions(rawValue: 1 << 3)
}

public struct MTLIndirectCommandType: OptionSet, Hashable, Sendable {
    public let rawValue: UInt

    public init(rawValue: UInt) {
        self.rawValue = rawValue
    }

    public static let draw = MTLIndirectCommandType(rawValue: 1 << 0)
    public static let drawIndexed = MTLIndirectCommandType(rawValue: 1 << 1)
    public static let drawPatches = MTLIndirectCommandType(rawValue: 1 << 2)
    public static let drawIndexedPatches = MTLIndirectCommandType(rawValue: 1 << 3)
    public static let concurrentDispatch = MTLIndirectCommandType(rawValue: 1 << 5)
    public static let concurrentDispatchThreads = MTLIndirectCommandType(rawValue: 1 << 6)
    public static let drawMeshThreadgroups = MTLIndirectCommandType(rawValue: 1 << 7)
    public static let drawMeshThreads = MTLIndirectCommandType(rawValue: 1 << 8)
}

public struct MTLAccelerationStructureInstanceOptions: OptionSet, Hashable, Sendable {
    public let rawValue: UInt32

    public init(rawValue: UInt32) {
        self.rawValue = rawValue
    }

    public static let disableTriangleCulling = MTLAccelerationStructureInstanceOptions(rawValue: 1 << 0)
    public static let triangleFrontFacingWindingCounterClockwise = MTLAccelerationStructureInstanceOptions(rawValue: 1 << 1)
    public static let opaque = MTLAccelerationStructureInstanceOptions(rawValue: 1 << 2)
    public static let nonOpaque = MTLAccelerationStructureInstanceOptions(rawValue: 1 << 3)
}

public struct MTLAccelerationStructureUsage: OptionSet, Hashable, Sendable {
    public let rawValue: UInt

    public init(rawValue: UInt) {
        self.rawValue = rawValue
    }

    public static let refit = MTLAccelerationStructureUsage(rawValue: 1 << 0)
    public static let preferFastBuild = MTLAccelerationStructureUsage(rawValue: 1 << 1)
    public static let extendedLimits = MTLAccelerationStructureUsage(rawValue: 1 << 2)
    public static let preferFastIntersection = MTLAccelerationStructureUsage(rawValue: 1 << 3)
    public static let minimizeMemory = MTLAccelerationStructureUsage(rawValue: 1 << 4)
}

public struct MTLAccelerationStructureRefitOptions: OptionSet, Hashable, Sendable {
    public let rawValue: UInt

    public init(rawValue: UInt) {
        self.rawValue = rawValue
    }

    public static let vertexData = MTLAccelerationStructureRefitOptions(rawValue: 1 << 0)
    public static let perPrimitiveData = MTLAccelerationStructureRefitOptions(rawValue: 1 << 1)
}

public struct MTLIntersectionFunctionSignature: OptionSet, Hashable, Sendable {
    public let rawValue: UInt

    public init(rawValue: UInt) {
        self.rawValue = rawValue
    }

    public static let instancing = MTLIntersectionFunctionSignature(rawValue: 1 << 0)
    public static let triangleData = MTLIntersectionFunctionSignature(rawValue: 1 << 1)
    public static let worldSpaceData = MTLIntersectionFunctionSignature(rawValue: 1 << 2)
    public static let instanceMotion = MTLIntersectionFunctionSignature(rawValue: 1 << 3)
    public static let primitiveMotion = MTLIntersectionFunctionSignature(rawValue: 1 << 4)
    public static let extendedLimits = MTLIntersectionFunctionSignature(rawValue: 1 << 5)
    public static let maxLevels = MTLIntersectionFunctionSignature(rawValue: 1 << 6)
    public static let curveData = MTLIntersectionFunctionSignature(rawValue: 1 << 7)
    public static let intersectionFunctionBuffer = MTLIntersectionFunctionSignature(rawValue: 1 << 8)
    public static let userData = MTLIntersectionFunctionSignature(rawValue: 1 << 9)
}

public struct MTL4BinaryFunctionOptions: OptionSet, Hashable, Sendable {
    public let rawValue: UInt

    public init(rawValue: UInt) {
        self.rawValue = rawValue
    }

    public static let pipelineIndependent = MTL4BinaryFunctionOptions(rawValue: 1 << 0)
}

public struct MTL4RenderEncoderOptions: OptionSet, Hashable, Sendable {
    public let rawValue: UInt

    public init(rawValue: UInt) {
        self.rawValue = rawValue
    }

    public static let suspending = MTL4RenderEncoderOptions(rawValue: 1 << 0)
    public static let resuming = MTL4RenderEncoderOptions(rawValue: 1 << 1)
}

public struct MTL4ShaderReflection: OptionSet, Hashable, Sendable {
    public let rawValue: UInt

    public init(rawValue: UInt) {
        self.rawValue = rawValue
    }

    public static let bindingInfo = MTL4ShaderReflection(rawValue: 1 << 0)
    public static let bufferTypeInfo = MTL4ShaderReflection(rawValue: 1 << 1)
}

public struct MTL4VisibilityOptions: OptionSet, Hashable, Sendable {
    public let rawValue: UInt

    public init(rawValue: UInt) {
        self.rawValue = rawValue
    }

    public static let device = MTL4VisibilityOptions(rawValue: 1 << 0)
    public static let resourceAlias = MTL4VisibilityOptions(rawValue: 1 << 1)
}

public struct MTL4PipelineDataSetSerializerConfiguration: OptionSet, Hashable, Sendable {
    public let rawValue: UInt

    public init(rawValue: UInt) {
        self.rawValue = rawValue
    }

    public static let captureDescriptors = MTL4PipelineDataSetSerializerConfiguration(rawValue: 1 << 0)
    public static let captureBinaries = MTL4PipelineDataSetSerializerConfiguration(rawValue: 1 << 1)
}

public struct MTLStitchedLibraryOptions: OptionSet, Hashable, Sendable {
    public let rawValue: UInt

    public init(rawValue: UInt) {
        self.rawValue = rawValue
    }

    public static let failOnBinaryArchiveMiss = MTLStitchedLibraryOptions(rawValue: 1 << 0)
    public static let storeLibraryInMetalPipelinesScript = MTLStitchedLibraryOptions(rawValue: 1 << 1)
}

public struct MTLTensorUsage: OptionSet, Hashable, Sendable {
    public let rawValue: UInt

    public init(rawValue: UInt) {
        self.rawValue = rawValue
    }

    public static let compute = MTLTensorUsage(rawValue: 1 << 0)
    public static let render = MTLTensorUsage(rawValue: 1 << 1)
    public static let machineLearning = MTLTensorUsage(rawValue: 1 << 2)
}
