public struct MTLResourceOptions: OptionSet, Hashable, Sendable {
    public let rawValue: UInt

    public init(rawValue: UInt) {
        self.rawValue = rawValue
    }

    public static let cpuCacheModeWriteCombined = MTLResourceOptions(rawValue: 1)
    public static let optionCPUCacheModeWriteCombined = MTLResourceOptions.cpuCacheModeWriteCombined
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
