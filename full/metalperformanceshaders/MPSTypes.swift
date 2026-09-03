import Foundation

public enum MPSAccelerationStructureStatus: UInt, Sendable, Hashable {
    case unbuilt = 0
    case built = 1
}

public struct MPSAccelerationStructureUsage: OptionSet, Sendable, Hashable {
    public let rawValue: UInt
    public init(rawValue: UInt) { self.rawValue = rawValue }

    public static let refit = MPSAccelerationStructureUsage(rawValue: 1 << 0)
    public static let frequentRebuild = MPSAccelerationStructureUsage(rawValue: 1 << 1)
    public static let preferGPUBuild = MPSAccelerationStructureUsage(rawValue: 1 << 2)
    public static let preferCPUBuild = MPSAccelerationStructureUsage(rawValue: 1 << 3)
}

public struct MPSAliasingStrategy: OptionSet, Sendable, Hashable {
    public let rawValue: UInt
    public init(rawValue: UInt) { self.rawValue = rawValue }

    public static let `default` = MPSAliasingStrategy([])
    public static let shallAlias = MPSAliasingStrategy(rawValue: 1 << 0)
    public static let shallNotAlias = MPSAliasingStrategy(rawValue: 1 << 1)
    public static let aliasingReserved: MPSAliasingStrategy = [shallAlias, shallNotAlias]
    public static let preferTemporaryMemory = MPSAliasingStrategy(rawValue: 1 << 2)
    public static let preferNonTemporaryMemory = MPSAliasingStrategy(rawValue: 1 << 3)
}

public enum MPSAlphaType: UInt, Sendable, Hashable {
    case nonPremultiplied = 0
    case premultiplied = 1
    case alphaIsOne = 2
}

public enum MPSBoundingBoxIntersectionTestType: UInt, Sendable, Hashable {
    case `default` = 0
    case axisAligned = 1
    case fast = 2
}

public struct MPSCNNBatchNormalizationFlags: OptionSet, Sendable, Hashable {
    public let rawValue: UInt
    public init(rawValue: UInt) { self.rawValue = rawValue }

    public static let Default = MPSCNNBatchNormalizationFlags([])
    public static let CalculateStatisticsAutomatic = MPSCNNBatchNormalizationFlags([])
    public static let calculateStatisticsAlways = MPSCNNBatchNormalizationFlags(rawValue: 1)
    public static let calculateStatisticsNever = MPSCNNBatchNormalizationFlags(rawValue: 2)
    public static let calculateStatisticsMask = MPSCNNBatchNormalizationFlags(rawValue: 3)
}

public enum MPSCNNBinaryConvolutionFlags: UInt, Sendable, Hashable {
    case none = 0
    case useBetaScaling = 1
}

public enum MPSCNNBinaryConvolutionType: UInt, Sendable, Hashable {
    case binaryWeights = 0
    case XNOR = 1
    case AND = 2
}

public enum MPSCNNConvolutionFlags: UInt, Sendable, Hashable {
    case none = 0
}

public struct MPSCNNConvolutionGradientOption: OptionSet, Sendable, Hashable {
    public let rawValue: UInt
    public init(rawValue: UInt) { self.rawValue = rawValue }

    public static let gradientWithData = MPSCNNConvolutionGradientOption(rawValue: 1 << 0)
    public static let gradientWithWeightsAndBias = MPSCNNConvolutionGradientOption(rawValue: 1 << 1)
    public static let all: MPSCNNConvolutionGradientOption = [gradientWithData, gradientWithWeightsAndBias]
}

public enum MPSCNNConvolutionWeightsLayout: UInt32, Sendable, Hashable {
    case OHWI = 0
}

public enum MPSCNNLossType: UInt32, Sendable, Hashable {
    case meanAbsoluteError = 0
    case meanSquaredError = 1
    case softMaxCrossEntropy = 2
    case sigmoidCrossEntropy = 3
    case categoricalCrossEntropy = 4
    case hinge = 5
    case huber = 6
    case cosineDistance = 7
    case log = 8
    case kullbackLeiblerDivergence = 9
    case count = 10
}

public enum MPSCNNNeuronType: Int32, Sendable, Hashable {
    case none = 0
    case reLU = 1
    case linear = 2
    case sigmoid = 3
    case hardSigmoid = 4
    case tanH = 5
    case absolute = 6
    case softPlus = 7
    case softSign = 8
    case ELU = 9
    case pReLU = 10
    case reLUN = 11
    case power = 12
    case exponential = 13
    case logarithm = 14
    case geLU = 15
    case count = 16
}

public enum MPSCNNReductionType: Int32, Sendable, Hashable {
    case none = 0
    case sum = 1
    case mean = 2
    case sumByNonZeroWeights = 3
    case count = 4
}

public enum MPSCNNWeightsQuantizationType: UInt32, Sendable, Hashable {
    case none = 0
    case linear = 1
    case lookupTable = 2
}

public enum MPSDataLayout: UInt, Sendable, Hashable {
    case HeightxWidthxFeatureChannels = 0
    case featureChannelsxHeightxWidth = 1
}

public enum MPSDataType: UInt32, Sendable, Hashable {
    case invalid = 0
    case uInt8 = 8
    case uInt16 = 16
    case uInt32 = 32
    case uInt64 = 64
    case uInt4 = 4
    case uInt2 = 2
    case floatBit = 0x1000_0000
    case float16 = 0x1000_0010
    case float32 = 0x1000_0020
    case signedBit = 0x2000_0000
    case int8 = 0x2000_0008
    case int16 = 0x2000_0010
    case int32 = 0x2000_0020
    case int64 = 0x2000_0040
    case int4 = 0x2000_0004
    case int2 = 0x2000_0002
    case normalizedBit = 0x4000_0000
    case unorm1 = 0x4000_0001
    case unorm8 = 0x4000_0008
    case alternateEncodingBit = 0x8000_0000
    case bFloat16 = 0x8000_0010
    case complexBit = 0x0100_0000
    case complexFloat16 = 0x1100_0010
    case complexFloat32 = 0x1100_0020
    case bool = 0x0800_0000

    public static var intBit: MPSDataType { .signedBit }
}

public struct MPSDeviceOptions: OptionSet, Sendable, Hashable {
    public let rawValue: UInt
    public init(rawValue: UInt) { self.rawValue = rawValue }

    public static let Default = MPSDeviceOptions([])
    public static let lowPower = MPSDeviceOptions(rawValue: 1 << 0)
    public static let skipRemovable = MPSDeviceOptions(rawValue: 1 << 1)
}

public enum MPSFloatDataTypeBit: UInt32, Sendable, Hashable {
    case signBit = 0x0080_0000
    case exponentBit = 0x007F_0000
    case mantissaBit = 0x0000_FFFF
}

public enum MPSFloatDataTypeShift: UInt32, Sendable, Hashable {
    case signShift = 23
    case exponentShift = 16
    case mantissaShift = 0
}

public enum MPSImageEdgeMode: UInt, Sendable, Hashable {
    case zero = 0
    case clamp = 1
    case mirror = 2
    case mirrorWithEdge = 3
    case constant = 4
}

public enum MPSImageFeatureChannelFormat: UInt, Sendable, Hashable {
    case none = 0
    case unorm8 = 1
    case unorm16 = 2
    case float16 = 3
    case float32 = 4
    case count = 6
}

public enum MPSIntersectionDataType: UInt, Sendable, Hashable {
    case distance = 0
    case distancePrimitiveIndex = 1
    case distancePrimitiveIndexCoordinates = 2
    case distancePrimitiveIndexInstanceIndex = 3
    case distancePrimitiveIndexInstanceIndexCoordinates = 4
    case distancePrimitiveIndexBufferIndex = 5
    case distancePrimitiveIndexBufferIndexCoordinates = 6
    case distancePrimitiveIndexBufferIndexInstanceIndex = 7
    case distancePrimitiveIndexBufferIndexInstanceIndexCoordinates = 8
}

public enum MPSIntersectionType: UInt, Sendable, Hashable {
    case nearest = 0
    case any = 1
}

public struct MPSKernelOptions: OptionSet, Sendable, Hashable {
    public let rawValue: UInt
    public init(rawValue: UInt) { self.rawValue = rawValue }

    public static let none = MPSKernelOptions([])
    public static let skipAPIValidation = MPSKernelOptions(rawValue: 1 << 0)
    public static let allowReducedPrecision = MPSKernelOptions(rawValue: 1 << 1)
    public static let disableInternalTiling = MPSKernelOptions(rawValue: 1 << 2)
    public static let insertDebugGroups = MPSKernelOptions(rawValue: 1 << 3)
    public static let verbose = MPSKernelOptions(rawValue: 1 << 4)
}

public enum MPSMatrixDecompositionStatus: Int32, Sendable, Hashable {
    case success = 0
    case failure = -1
    case singular = -2
    case nonPositiveDefinite = -3
}

public struct MPSMatrixRandomDistribution: OptionSet, Sendable, Hashable {
    public let rawValue: UInt
    public init(rawValue: UInt) { self.rawValue = rawValue }

    public static let `default` = MPSMatrixRandomDistribution([])
    public static let uniform = MPSMatrixRandomDistribution(rawValue: 1)
    public static let normal = MPSMatrixRandomDistribution(rawValue: 2)
}

public struct MPSNDArrayQuantizationScheme: OptionSet, Sendable, Hashable {
    public let rawValue: UInt
    public init(rawValue: UInt) { self.rawValue = rawValue }

    public static let none = MPSNDArrayQuantizationScheme([])
    public static let typeAffine = MPSNDArrayQuantizationScheme(rawValue: 1)
    public static let typeLUT = MPSNDArrayQuantizationScheme(rawValue: 2)
}

public struct MPSNNComparisonType: OptionSet, Sendable, Hashable {
    public let rawValue: UInt
    public init(rawValue: UInt) { self.rawValue = rawValue }

    public static let equal: MPSNNComparisonType = []
    public static let notEqual = MPSNNComparisonType(rawValue: 1)
    public static let less = MPSNNComparisonType(rawValue: 2)
    public static let lessOrEqual = MPSNNComparisonType(rawValue: 3)
    public static let greater = MPSNNComparisonType(rawValue: 4)
    public static let greaterOrEqual = MPSNNComparisonType(rawValue: 5)
}

public struct MPSNNConvolutionAccumulatorPrecisionOption: OptionSet, Sendable, Hashable {
    public let rawValue: UInt
    public init(rawValue: UInt) { self.rawValue = rawValue }

    public static let half = MPSNNConvolutionAccumulatorPrecisionOption([])
    public static let float = MPSNNConvolutionAccumulatorPrecisionOption(rawValue: 1 << 0)
}

public struct MPSNNPaddingMethod: OptionSet, Sendable, Hashable {
    public let rawValue: UInt
    public init(rawValue: UInt) { self.rawValue = rawValue }

    public static let centered = MPSNNPaddingMethod([])
    public static let alignTopLeft = MPSNNPaddingMethod(rawValue: 1)
    public static let alignBottomRight = MPSNNPaddingMethod(rawValue: 2)
    public static let align_reserved = MPSNNPaddingMethod(rawValue: 3)
    public static let alignMask = MPSNNPaddingMethod(rawValue: 3)
    public static let topLeft = MPSNNPaddingMethod([])
    public static let addRemainderToTopRight = MPSNNPaddingMethod(rawValue: 1 << 2)
    public static let addRemainderToBottomLeft = MPSNNPaddingMethod(rawValue: 2 << 2)
    public static let addRemainderToBottomRight = MPSNNPaddingMethod(rawValue: 3 << 2)
    public static let addRemainderToMask = MPSNNPaddingMethod(rawValue: 3 << 2)
    public static let validOnly = MPSNNPaddingMethod([])
    public static let sizeSame = MPSNNPaddingMethod(rawValue: 1 << 4)
    public static let sizeFull = MPSNNPaddingMethod(rawValue: 2 << 4)
    public static let size_reserved = MPSNNPaddingMethod(rawValue: 3 << 4)
    public static let sizeMask = MPSNNPaddingMethod(rawValue: 3 << 4)
    public static let excludeEdges = MPSNNPaddingMethod(rawValue: 1 << 6)
    public static let custom = MPSNNPaddingMethod(rawValue: 1 << 13)
    public static let customAllowForNodeFusion = MPSNNPaddingMethod(rawValue: 1 << 14)
    public static let customWhitelistForNodeFusion = MPSNNPaddingMethod(rawValue: 1 << 14)
}

public enum MPSNNRegularizationType: UInt, Sendable, Hashable {
    case None = 0
    case L1 = 1
    case L2 = 2
}

public struct MPSNNTrainingStyle: OptionSet, Sendable, Hashable {
    public let rawValue: UInt
    public init(rawValue: UInt) { self.rawValue = rawValue }

    public static let UpdateDeviceNone = MPSNNTrainingStyle([])
    public static let updateDeviceCPU = MPSNNTrainingStyle(rawValue: 1 << 0)
    public static let updateDeviceGPU = MPSNNTrainingStyle(rawValue: 1 << 1)
}

public enum MPSPolygonType: UInt, Sendable, Hashable {
    case triangle = 0
    case quadrilateral = 1
}

public enum MPSPurgeableState: UInt, Sendable, Hashable {
    case allocationDeferred = 0
    case keepCurrent = 1
    case nonVolatile = 2
    case volatile = 3
    case empty = 4
}

public enum MPSRNNBidirectionalCombineMode: UInt, Sendable, Hashable {
    case none = 0
    case add = 1
    case concatenate = 2
}

public enum MPSRNNMatrixId: UInt, Sendable, Hashable {
    case singleGateInputWeights = 0
    case singleGateRecurrentWeights = 1
    case singleGateBiasTerms = 2
    case lstmInputGateInputWeights = 3
    case lstmInputGateRecurrentWeights = 4
    case lstmInputGateMemoryWeights = 5
    case lstmInputGateBiasTerms = 6
    case lstmForgetGateInputWeights = 7
    case lstmForgetGateRecurrentWeights = 8
    case lstmForgetGateMemoryWeights = 9
    case lstmForgetGateBiasTerms = 10
    case lstmMemoryGateInputWeights = 11
    case lstmMemoryGateRecurrentWeights = 12
    case lstmMemoryGateMemoryWeights = 13
    case lstmMemoryGateBiasTerms = 14
    case lstmOutputGateInputWeights = 15
    case lstmOutputGateRecurrentWeights = 16
    case lstmOutputGateMemoryWeights = 17
    case lstmOutputGateBiasTerms = 18
    case gruInputGateInputWeights = 19
    case gruInputGateRecurrentWeights = 20
    case gruInputGateBiasTerms = 21
    case gruRecurrentGateInputWeights = 22
    case gruRecurrentGateRecurrentWeights = 23
    case gruRecurrentGateBiasTerms = 24
    case gruOutputGateInputWeights = 25
    case gruOutputGateRecurrentWeights = 26
    case gruOutputGateInputGateWeights = 27
    case gruOutputGateBiasTerms = 28
    case SingleGateInputWeights = 29
}

public enum MPSRNNSequenceDirection: UInt, Sendable, Hashable {
    case forward = 0
    case backward = 1
}

public enum MPSRayDataType: UInt, Sendable, Hashable {
    case originDirection = 0
    case packedOriginDirection = 1
    case originMinDistanceDirectionMaxDistance = 2
    case originMaskDirectionMaxDistance = 3
}

public enum MPSRayMaskOperator: UInt, Sendable, Hashable {
    case and = 0
    case notAnd = 1
    case or = 2
    case notOr = 3
    case xor = 4
    case notXor = 5
    case equal = 6
    case notEqual = 7
    case lessThan = 8
    case lessThanOrEqualTo = 9
    case greaterThan = 10
    case greaterThanOrEqualTo = 11
}

public struct MPSRayMaskOptions: OptionSet, Sendable, Hashable {
    public let rawValue: UInt
    public init(rawValue: UInt) { self.rawValue = rawValue }

    public static let primitive = MPSRayMaskOptions(rawValue: 1 << 0)
    public static let instance = MPSRayMaskOptions(rawValue: 1 << 1)
}

public enum MPSStateResourceType: UInt, Sendable, Hashable {
    case none = 0
    case buffer = 1
    case texture = 2
}

public enum MPSTemporalWeighting: UInt, Sendable, Hashable {
    case average = 0
    case exponentialMovingAverage = 1
}

public enum MPSTransformType: UInt, Sendable, Hashable {
    case identity = 0
    case float4x4 = 1
}

public enum MPSTriangleIntersectionTestType: UInt, Sendable, Hashable {
    case `default` = 0
    case watertight = 1
}

public func MPSDataTypeBitsCount(_ t: MPSDataType) -> Int {
    switch t {
    case .invalid:
        return 0
    case .bool:
        return 1
    case .unorm1:
        return 1
    case .uInt2, .int2:
        return 2
    case .uInt4, .int4:
        return 4
    case .complexFloat16:
        return 32
    case .complexFloat32:
        return 64
    default:
        return Int(t.rawValue & 0x7F)
    }
}

public func MPSSizeofMPSDataType(_ t: MPSDataType) -> Int {
    let bits = MPSDataTypeBitsCount(t)
    if bits == 0 { return 0 }
    return (bits + 7) / 8
}
