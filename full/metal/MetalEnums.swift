public enum MTLCPUCacheMode: UInt, Equatable, Hashable, Sendable {
    case defaultCache = 0
    case writeCombined = 1
}

public enum MTLStorageMode: UInt, Equatable, Hashable, Sendable {
    case shared = 0
    case `private` = 2
    case memoryless = 3
}

public enum MTLHazardTrackingMode: UInt, Equatable, Hashable, Sendable {
    case `default` = 0
    case untracked = 1
    case tracked = 2
}

public enum MTLTextureType: UInt, Equatable, Hashable, Sendable {
    case type1D = 0
    case type1DArray = 1
    case type2D = 2
    case type2DArray = 3
    case type2DMultisample = 4
    case typeCube = 5
    case typeCubeArray = 6
    case type3D = 7
    case type2DMultisampleArray = 8
    case typeTextureBuffer = 9
}

public enum MTLPrimitiveType: UInt, Equatable, Hashable, Sendable {
    case point = 0
    case line = 1
    case lineStrip = 2
    case triangle = 3
    case triangleStrip = 4
}

public enum MTLIndexType: UInt, Equatable, Hashable, Sendable {
    case uint16 = 0
    case uint32 = 1
}

public enum MTLLoadAction: UInt, Equatable, Hashable, Sendable {
    case dontCare = 0
    case load = 1
    case clear = 2
}

public enum MTLStoreAction: UInt, Equatable, Hashable, Sendable {
    case dontCare = 0
    case store = 1
    case multisampleResolve = 2
    case storeAndMultisampleResolve = 3
    case unknown = 4
    case customSampleDepthStore = 5
}

public enum MTLBlendFactor: UInt, Equatable, Hashable, Sendable {
    case zero = 0
    case one = 1
    case sourceColor = 2
    case oneMinusSourceColor = 3
    case sourceAlpha = 4
    case oneMinusSourceAlpha = 5
    case destinationColor = 6
    case oneMinusDestinationColor = 7
    case destinationAlpha = 8
    case oneMinusDestinationAlpha = 9
    case sourceAlphaSaturated = 10
    case blendColor = 11
    case oneMinusBlendColor = 12
    case blendAlpha = 13
    case oneMinusBlendAlpha = 14
    case source1Color = 15
    case oneMinusSource1Color = 16
    case source1Alpha = 17
    case oneMinusSource1Alpha = 18
}

public enum MTLBlendOperation: UInt, Equatable, Hashable, Sendable {
    case add = 0
    case subtract = 1
    case reverseSubtract = 2
    case min = 3
    case max = 4
}

public enum MTLCompareFunction: UInt, Equatable, Hashable, Sendable {
    case never = 0
    case less = 1
    case equal = 2
    case lessEqual = 3
    case greater = 4
    case notEqual = 5
    case greaterEqual = 6
    case always = 7
}

public enum MTLStencilOperation: UInt, Equatable, Hashable, Sendable {
    case keep = 0
    case zero = 1
    case replace = 2
    case incrementClamp = 3
    case decrementClamp = 4
    case invert = 5
    case incrementWrap = 6
    case decrementWrap = 7
}

public enum MTLCullMode: UInt, Equatable, Hashable, Sendable {
    case none = 0
    case front = 1
    case back = 2
}

public enum MTLWinding: UInt, Equatable, Hashable, Sendable {
    case clockwise = 0
    case counterClockwise = 1
}

public enum MTLDepthClipMode: UInt, Equatable, Hashable, Sendable {
    case clip = 0
    case clamp = 1
}

public enum MTLTriangleFillMode: UInt, Equatable, Hashable, Sendable {
    case fill = 0
    case lines = 1
}

public enum MTLSamplerMinMagFilter: UInt, Equatable, Hashable, Sendable {
    case nearest = 0
    case linear = 1
}

public enum MTLSamplerMipFilter: UInt, Equatable, Hashable, Sendable {
    case notMipmapped = 0
    case nearest = 1
    case linear = 2
}

public enum MTLSamplerAddressMode: UInt, Equatable, Hashable, Sendable {
    case clampToEdge = 0
    case mirrorClampToEdge = 1
    case `repeat` = 2
    case mirrorRepeat = 3
    case clampToZero = 4
    case clampToBorderColor = 5
}

public enum MTLSamplerBorderColor: UInt, Equatable, Hashable, Sendable {
    case transparentBlack = 0
    case opaqueBlack = 1
    case opaqueWhite = 2
}

public enum MTLSamplerReductionMode: Int, Equatable, Hashable, Sendable {
    case weightedAverage = 0
    case minimum = 1
    case maximum = 2
}

public enum MTLTextureSwizzle: UInt8, Equatable, Hashable, Sendable {
    case zero = 0
    case one = 1
    case red = 2
    case green = 3
    case blue = 4
    case alpha = 5
}

public enum MTLPurgeableState: UInt, Equatable, Hashable, Sendable {
    case keepCurrent = 1
    case nonVolatile = 2
    case volatile = 3
    case empty = 4
}

public enum MTLCommandBufferStatus: UInt, Equatable, Hashable, Sendable {
    case notEnqueued = 0
    case enqueued = 1
    case committed = 2
    case scheduled = 3
    case completed = 4
    case error = 5
}

public enum MTLFunctionType: UInt, Equatable, Hashable, Sendable {
    case vertex = 1
    case fragment = 2
    case kernel = 3
    case visible = 5
    case intersection = 6
    case mesh = 7
    case object = 8
}

public enum MTLLanguageVersion: UInt, Equatable, Hashable, Sendable {
    case version1_0 = 0x10000
    case version1_1 = 0x10001
    case version1_2 = 0x10002
    case version2_0 = 0x20000
    case version2_1 = 0x20001
    case version2_2 = 0x20002
    case version2_3 = 0x20003
    case version2_4 = 0x20004
    case version3_0 = 0x30000
    case version3_1 = 0x30001
    case version3_2 = 0x30002
    case version4_0 = 0x40000
}

public enum MTLGPUFamily: Int, Equatable, Hashable, Sendable {
    case apple1 = 1001
    case apple2 = 1002
    case apple3 = 1003
    case apple4 = 1004
    case apple5 = 1005
    case apple6 = 1006
    case apple7 = 1007
    case apple8 = 1008
    case apple9 = 1009
    case apple10 = 1010
    case mac1 = 2001
    case mac2 = 2002
    case common1 = 3001
    case common2 = 3002
    case common3 = 3003
    case macCatalyst1 = 4001
    case macCatalyst2 = 4002
    case metal3 = 5001
    case metal4 = 5002
}

public enum MTLFeatureSet: UInt, Equatable, Hashable, Sendable {
    case iOS_GPUFamily1_v1 = 0
    case iOS_GPUFamily2_v1 = 1
    case iOS_GPUFamily1_v2 = 2
    case iOS_GPUFamily2_v2 = 3
    case iOS_GPUFamily3_v1 = 4
    case iOS_GPUFamily1_v3 = 5
    case iOS_GPUFamily2_v3 = 6
    case iOS_GPUFamily3_v2 = 7
    case iOS_GPUFamily1_v4 = 8
    case iOS_GPUFamily2_v4 = 9
    case iOS_GPUFamily3_v3 = 10
    case iOS_GPUFamily4_v1 = 11
    case iOS_GPUFamily1_v5 = 12
    case iOS_GPUFamily2_v5 = 13
    case iOS_GPUFamily3_v4 = 14
    case iOS_GPUFamily4_v2 = 15
    case iOS_GPUFamily5_v1 = 16
}

public enum MTLArgumentBuffersTier: UInt, Equatable, Hashable, Sendable {
    case tier1 = 0
    case tier2 = 1
}

public enum MTLReadWriteTextureTier: UInt, Equatable, Hashable, Sendable {
    case tierNone = 0
    case tier1 = 1
    case tier2 = 2
}

public enum MTLDispatchType: UInt, Equatable, Hashable, Sendable {
    case serial = 0
    case concurrent = 1
}

public enum MTLLibraryType: Int, Equatable, Hashable, Sendable {
    case executable = 0
    case dynamic = 1
}

public enum MTLCaptureDestination: Int, Equatable, Hashable, Sendable {
    case developerTools = 1
    case gpuTraceDocument = 2
}

public enum MTLCaptureError: Int, Error, Equatable, Hashable, Sendable {
    case notSupported = 1
    case alreadyCapturing = 2
    case invalidDescriptor = 3
}

public enum MTLVertexStepFunction: UInt, Equatable, Hashable, Sendable {
    case constant = 0
    case perVertex = 1
    case perInstance = 2
    case perPatch = 3
    case perPatchControlPoint = 4
}

public enum MTLHeapType: Int, Equatable, Hashable, Sendable {
    case automatic = 0
    case placement = 1
    case sparse = 2
}

public enum MTLTextureCompressionType: Int, Equatable, Hashable, Sendable {
    case lossless = 0
    case lossy = 1
}

public enum MTLSparsePageSize: Int, Equatable, Hashable, Sendable {
    case size16 = 16
    case size64 = 64
    case size256 = 256
}

public enum MTLSparseTextureMappingMode: UInt, Equatable, Hashable, Sendable {
    case map = 0
    case unmap = 1
}

public enum MTLBufferSparseTier: Int, Equatable, Hashable, Sendable {
    case tierNone = 0
    case tier1 = 1
}

public enum MTLTextureSparseTier: Int, Equatable, Hashable, Sendable {
    case tierNone = 0
    case tier1 = 1
    case tier2 = 2
}

public enum MTLCompileSymbolVisibility: Int, Equatable, Hashable, Sendable {
    case `default` = 0
    case hidden = 1
}

public enum MTLLibraryOptimizationLevel: Int, Equatable, Hashable, Sendable {
    case `default` = 0
    case size = 1
}

public enum MTLMathMode: Int, Equatable, Hashable, Sendable {
    case safe = 0
    case relaxed = 1
    case fast = 2
}

public enum MTLMathFloatingPointFunctions: Int, Equatable, Hashable, Sendable {
    case fast = 0
    case precise = 1
}

public enum MTLMultisampleDepthResolveFilter: UInt, Equatable, Hashable, Sendable {
    case sample0 = 0
    case min = 1
    case max = 2
}

public enum MTLMultisampleStencilResolveFilter: UInt, Equatable, Hashable, Sendable {
    case sample0 = 0
    case depthResolvedSample = 1
}

public enum MTLVisibilityResultType: Int, Equatable, Hashable, Sendable {
    case reset = 0
    case accumulate = 1
}

public enum MTLBindingAccess: UInt, Equatable, Hashable, Sendable {
    case readOnly = 0
    case readWrite = 1
    case writeOnly = 2
}

public enum MTLArgumentType: UInt, Equatable, Hashable, Sendable {
    case buffer = 0
    case threadgroupMemory = 1
    case texture = 2
    case sampler = 3
    case imageblockData = 16
    case imageblock = 17
    case visibleFunctionTable = 24
    case primitiveAccelerationStructure = 25
    case instanceAccelerationStructure = 26
    case intersectionFunctionTable = 27
}

public enum MTLBindingType: UInt, Equatable, Hashable, Sendable {
    case buffer = 0
    case threadgroupMemory = 1
    case texture = 2
    case sampler = 3
    case imageblockData = 4
    case imageblock = 5
    case visibleFunctionTable = 6
    case primitiveAccelerationStructure = 7
    case instanceAccelerationStructure = 8
    case intersectionFunctionTable = 9
    case objectPayload = 10
    case tensor = 11
}

public enum MTLVisibilityResultMode: UInt, Equatable, Hashable, Sendable {
    case disabled = 0
    case boolean = 1
    case counting = 2
}

public enum MTLShaderValidation: Int, Equatable, Hashable, Sendable {
    case `default` = 0
    case enabled = 1
    case disabled = 2
}

public enum MTLPatchType: UInt, Equatable, Hashable, Sendable {
    case none = 0
    case triangle = 1
    case quad = 2
}

/// Raw values match `Metal/MTLArgument.h` for the classic table. Newer
/// cases (`bfloat*`, `tensor`, `depthStencilState`) follow the public
/// sequential extension used by iPhoneOS 18+ headers and are recorded in
/// `oracle-questions.tsv` until an Apple-oracle probe confirms them.
public enum MTLDataType: UInt, Equatable, Hashable, Sendable {
    case none = 0
    case `struct` = 1
    case array = 2
    case float = 3
    case float2 = 4
    case float3 = 5
    case float4 = 6
    case float2x2 = 7
    case float2x3 = 8
    case float2x4 = 9
    case float3x2 = 10
    case float3x3 = 11
    case float3x4 = 12
    case float4x2 = 13
    case float4x3 = 14
    case float4x4 = 15
    case half = 16
    case half2 = 17
    case half3 = 18
    case half4 = 19
    case half2x2 = 20
    case half2x3 = 21
    case half2x4 = 22
    case half3x2 = 23
    case half3x3 = 24
    case half3x4 = 25
    case half4x2 = 26
    case half4x3 = 27
    case half4x4 = 28
    case int = 29
    case int2 = 30
    case int3 = 31
    case int4 = 32
    case uint = 33
    case uint2 = 34
    case uint3 = 35
    case uint4 = 36
    case short = 37
    case short2 = 38
    case short3 = 39
    case short4 = 40
    case ushort = 41
    case ushort2 = 42
    case ushort3 = 43
    case ushort4 = 44
    case char = 45
    case char2 = 46
    case char3 = 47
    case char4 = 48
    case uchar = 49
    case uchar2 = 50
    case uchar3 = 51
    case uchar4 = 52
    case bool = 53
    case bool2 = 54
    case bool3 = 55
    case bool4 = 56
    case texture = 58
    case sampler = 59
    case pointer = 60
    case r8Unorm = 62
    case r8Snorm = 63
    case r16Unorm = 64
    case r16Snorm = 65
    case rg8Unorm = 66
    case rg8Snorm = 67
    case rg16Unorm = 68
    case rg16Snorm = 69
    case rgba8Unorm = 70
    case rgba8Unorm_srgb = 71
    case rgba8Snorm = 72
    case rgba16Unorm = 73
    case rgba16Snorm = 74
    case rgb10a2Unorm = 75
    case rg11b10Float = 76
    case rgb9e5Float = 77
    case renderPipeline = 78
    case computePipeline = 79
    case indirectCommandBuffer = 80
    case long = 81
    case long2 = 82
    case long3 = 83
    case long4 = 84
    case ulong = 85
    case ulong2 = 86
    case ulong3 = 87
    case ulong4 = 88
    case visibleFunctionTable = 115
    case intersectionFunctionTable = 116
    case primitiveAccelerationStructure = 117
    case instanceAccelerationStructure = 118
    case depthStencilState = 119
    case bfloat = 121
    case bfloat2 = 122
    case bfloat3 = 123
    case bfloat4 = 124
    case tensor = 125
}

public enum MTLAttributeFormat: UInt, Equatable, Hashable, Sendable {
    case invalid = 0
    case uchar2 = 1
    case uchar3 = 2
    case uchar4 = 3
    case char2 = 4
    case char3 = 5
    case char4 = 6
    case uchar2Normalized = 7
    case uchar3Normalized = 8
    case uchar4Normalized = 9
    case char2Normalized = 10
    case char3Normalized = 11
    case char4Normalized = 12
    case ushort2 = 13
    case ushort3 = 14
    case ushort4 = 15
    case short2 = 16
    case short3 = 17
    case short4 = 18
    case ushort2Normalized = 19
    case ushort3Normalized = 20
    case ushort4Normalized = 21
    case short2Normalized = 22
    case short3Normalized = 23
    case short4Normalized = 24
    case half2 = 25
    case half3 = 26
    case half4 = 27
    case float = 28
    case float2 = 29
    case float3 = 30
    case float4 = 31
    case int = 32
    case int2 = 33
    case int3 = 34
    case int4 = 35
    case uint = 36
    case uint2 = 37
    case uint3 = 38
    case uint4 = 39
    case int1010102Normalized = 40
    case uint1010102Normalized = 41
    case uchar4Normalized_bgra = 42
    case uchar = 45
    case char = 46
    case ucharNormalized = 47
    case charNormalized = 48
    case ushort = 49
    case short = 50
    case ushortNormalized = 51
    case shortNormalized = 52
    case half = 53
    case floatRG11B10 = 54
    case floatRGB9E5 = 55
}

public enum MTLVertexFormat: UInt, Equatable, Hashable, Sendable {
    case invalid = 0
    case uchar2 = 1
    case uchar3 = 2
    case uchar4 = 3
    case char2 = 4
    case char3 = 5
    case char4 = 6
    case uchar2Normalized = 7
    case uchar3Normalized = 8
    case uchar4Normalized = 9
    case char2Normalized = 10
    case char3Normalized = 11
    case char4Normalized = 12
    case ushort2 = 13
    case ushort3 = 14
    case ushort4 = 15
    case short2 = 16
    case short3 = 17
    case short4 = 18
    case ushort2Normalized = 19
    case ushort3Normalized = 20
    case ushort4Normalized = 21
    case short2Normalized = 22
    case short3Normalized = 23
    case short4Normalized = 24
    case half2 = 25
    case half3 = 26
    case half4 = 27
    case float = 28
    case float2 = 29
    case float3 = 30
    case float4 = 31
    case int = 32
    case int2 = 33
    case int3 = 34
    case int4 = 35
    case uint = 36
    case uint2 = 37
    case uint3 = 38
    case uint4 = 39
    case int1010102Normalized = 40
    case uint1010102Normalized = 41
    case uchar4Normalized_bgra = 42
    case uchar = 45
    case char = 46
    case ucharNormalized = 47
    case charNormalized = 48
    case ushort = 49
    case short = 50
    case ushortNormalized = 51
    case shortNormalized = 52
    case half = 53
    case floatRG11B10 = 54
    case floatRGB9E5 = 55
}

public enum MTLMutability: UInt, Equatable, Hashable, Sendable {
    case `default` = 0
    case mutable = 1
    case immutable = 2
}

public enum MTLMotionBorderMode: UInt32, Equatable, Hashable, Sendable {
    case clamp = 0
    case vanish = 1
}

/// Sequential values matching the documented Metal.h blocks where known.
/// Later Metal 4 cases without integer payloads are recorded in
/// `oracle-questions.tsv` until an Apple-oracle probe confirms them.
public enum MTL4AlphaToCoverageState: Int, Equatable, Hashable, Sendable {
    case disabled = 0
    case enabled = 1
}

public enum MTL4AlphaToOneState: Int, Equatable, Hashable, Sendable {
    case disabled = 0
    case enabled = 1
}

public enum MTL4BlendState: Int, Equatable, Hashable, Sendable {
    case disabled = 0
    case enabled = 1
    case unspecialized = 2
}

public enum MTL4IndirectCommandBufferSupportState: Int, Equatable, Hashable, Sendable {
    case disabled = 0
    case enabled = 1
}

public enum MTL4LogicalToPhysicalColorAttachmentMappingState: Int, Equatable, Hashable, Sendable {
    case identity = 0
    case inherited = 1
}

public enum MTL4CompilerTaskStatus: Int, Equatable, Hashable, Sendable {
    case none = 0
    case scheduled = 1
    case compiling = 2
    case finished = 3
}

public enum MTL4TimestampGranularity: Int, Equatable, Hashable, Sendable {
    case relaxed = 0
    case precise = 1
}

public enum MTLCurveType: Int, Equatable, Hashable, Sendable {
    case round = 0
    case flat = 1
}

public enum MTLCurveBasis: Int, Equatable, Hashable, Sendable {
    case bSpline = 0
    case linear = 1
    case bezier = 2
    case catmullRom = 3
}

public enum MTLCurveEndCaps: Int, Equatable, Hashable, Sendable {
    case none = 0
    case disk = 1
    case sphere = 2
}

public enum MTLIOPriority: Int, Equatable, Hashable, Sendable {
    case high = 0
    case normal = 1
    case low = 2
}

public enum MTLIOStatus: Int, Equatable, Hashable, Sendable {
    case pending = 0
    case cancelled = 1
    case error = 2
    case complete = 3
}

public enum MTLIOCompressionMethod: Int, Equatable, Hashable, Sendable {
    case zlib = 0
    case lzfse = 1
    case lz4 = 2
    case lzma = 3
    case lzBitmap = 4
}

public enum MTLIOCommandQueueType: Int, Equatable, Hashable, Sendable {
    case concurrent = 0
    case serial = 1
}

public enum MTLMatrixLayout: Int, Equatable, Hashable, Sendable {
    case columnMajor = 0
    case rowMajor = 1
}

public enum MTLPrimitiveTopologyClass: UInt, Equatable, Hashable, Sendable {
    case unspecified = 0
    case point = 1
    case line = 2
    case triangle = 3
}

public enum MTLTessellationControlPointIndexType: UInt, Equatable, Hashable, Sendable {
    case none = 0
    case uint16 = 1
    case uint32 = 2
}

public enum MTLTessellationFactorFormat: UInt, Equatable, Hashable, Sendable {
    case half = 0
}

public enum MTLTessellationFactorStepFunction: UInt, Equatable, Hashable, Sendable {
    case constant = 0
    case perPatch = 1
    case perInstance = 2
    case perPatchAndPerInstance = 3
}

public enum MTLTessellationPartitionMode: UInt, Equatable, Hashable, Sendable {
    case pow2 = 0
    case integer = 1
    case fractionalOdd = 2
    case fractionalEven = 3
}

public enum MTLTransformType: Int, Equatable, Hashable, Sendable {
    case packedFloat4x3 = 0
    case component = 1
}

public enum MTLAccelerationStructureInstanceDescriptorType: UInt, Equatable, Hashable, Sendable {
    case `default` = 0
    case userID = 1
    case motion = 2
    case indirect = 3
    case indirectMotion = 4
}

public enum MTLSparseTextureRegionAlignmentMode: UInt, Equatable, Hashable, Sendable {
    case outward = 0
    case inward = 1
}

public enum MTL4CounterHeapType: Int, Equatable, Hashable, Sendable {
    case invalid = 0
    case timestamp = 1
}

/// Tensor element types. Integer payloads are sequential stand-ins until an
/// Apple-oracle probe records the iPhoneOS 26.1 Metal.h values.
public enum MTLTensorDataType: Int, Equatable, Hashable, Sendable {
    case none = 0
    case float32 = 1
    case float16 = 2
    case bfloat16 = 3
    case int8 = 4
    case uint8 = 5
    case int16 = 6
    case uint16 = 7
    case int32 = 8
    case uint32 = 9
}

public enum MTLStepFunction: UInt, Equatable, Hashable, Sendable {
    case constant = 0
    case perVertex = 1
    case perInstance = 2
    case perPatch = 3
    case perPatchControlPoint = 4
    case threadPositionInGridX = 5
    case threadPositionInGridY = 6
    case threadPositionInGridXIndexed = 7
    case threadPositionInGridYIndexed = 8
}

public enum MTLLogLevel: Int, Equatable, Hashable, Sendable {
    case undefined = 0
    case debug = 1
    case info = 2
    case notice = 3
    case error = 4
    case fault = 5
}

public enum MTLCommandEncoderErrorState: Int, Equatable, Hashable, Sendable {
    case unknown = 0
    case completed = 1
    case affected = 2
    case pending = 3
    case faulted = 4
}

public enum MTLFunctionLogType: UInt, Equatable, Hashable, Sendable {
    case validation = 0
}

public enum MTLIOCompressionStatus: Int, Equatable, Hashable, Sendable {
    case complete = 0
    case error = 1
}

public enum MTLLogStateError: UInt, Error, Equatable, Hashable, Sendable {
    case invalid = 1
    case invalidSize = 2
}
