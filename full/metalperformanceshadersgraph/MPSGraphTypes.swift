import Foundation

public enum MPSGraphDeploymentPlatform: UInt64, Sendable, Hashable {
    case macOS = 0
    case iOS = 1
    case tvOS = 2
    case visionOS = 3
}

public enum MPSGraphDeviceType: UInt32, Sendable, Hashable {
    case metal = 0
}

public enum MPSGraphExecutionStage: UInt64, Sendable, Hashable {
    case completed = 0
}

public enum MPSGraphFFTScalingMode: UInt, Sendable, Hashable {
    case none = 0
    case size = 1
    case unitary = 2
}

public enum MPSGraphLossReductionType: UInt64, Sendable, Hashable {
    case none = 0
    case sum = 1
    case mean = 2

    /// Historical alias of `.none` in the public overlay.
    public static var axis: MPSGraphLossReductionType { .none }
}

public enum MPSGraphNonMaximumSuppressionCoordinateMode: UInt, Sendable, Hashable {
    /// Overlay name for the C `CornersHeightFirst` enumerator.
    case explicit = 0
    case cornersWidthFirst = 1
    case centersHeightFirst = 2
    case centersWidthFirst = 3
}

public enum MPSGraphOptimization: UInt64, Sendable, Hashable {
    case level0 = 0
    case level1 = 1
}

public enum MPSGraphOptimizationProfile: UInt64, Sendable, Hashable {
    case performance = 0
    case powerEfficiency = 1
}

public enum MPSGraphOptions: UInt64, Sendable, Hashable {
    case none = 0
    case synchronizeResults = 1
    case verbose = 2

    public static var `default`: MPSGraphOptions { .synchronizeResults }
}

public enum MPSGraphPaddingMode: Int, Sendable, Hashable {
    case constant = 0
    case reflect = 1
    case symmetric = 2
    case clampToEdge = 3
    case zero = 4
    case periodic = 5
    case antiPeriodic = 6
}

public enum MPSGraphPaddingStyle: UInt, Sendable, Hashable {
    case explicit = 0
    case TF_VALID = 1
    case TF_SAME = 2
    case explicitOffset = 3
    case ONNX_SAME_LOWER = 4
}

public enum MPSGraphPoolingReturnIndicesMode: UInt, Sendable, Hashable {
    case none = 0
    case globalFlatten1D = 1
    case globalFlatten2D = 2
    case globalFlatten3D = 3
    case globalFlatten4D = 4
    case localFlatten1D = 5
    case localFlatten2D = 6
    case localFlatten3D = 7
    case localFlatten4D = 8
}

public enum MPSGraphRNNActivation: UInt, Sendable, Hashable {
    case none = 0
    case relu = 1
    case tanh = 2
    case sigmoid = 3
    case hardSigmoid = 4
}

public enum MPSGraphRandomDistribution: UInt64, Sendable, Hashable {
    case uniform = 0
    case normal = 1
    case truncatedNormal = 2
}

public enum MPSGraphRandomNormalSamplingMethod: UInt64, Sendable, Hashable {
    case invCDF = 0
    case boxMuller = 1
}

public struct MPSGraphReducedPrecisionFastMath: OptionSet, Sendable, Hashable {
    public let rawValue: UInt

    public init(rawValue: UInt) {
        self.rawValue = rawValue
    }

    public static let none = MPSGraphReducedPrecisionFastMath([])
    public static let allowFP16Conv2DWinogradTransformIntermediate =
        MPSGraphReducedPrecisionFastMath(rawValue: 1 << 1)
    /// Documented alias of `allowFP16Conv2DWinogradTransformIntermediate`.
    public static let allowFP16Intermediates = allowFP16Conv2DWinogradTransformIntermediate
}

public enum MPSGraphReductionMode: UInt, Sendable, Hashable {
    case min = 0
    case max = 1
    case sum = 2
    case product = 3
    case argumentMin = 4
    case argumentMax = 5
}

public enum MPSGraphResizeMode: UInt, Sendable, Hashable {
    case nearest = 0
    case bilinear = 1
}

public enum MPSGraphResizeNearestRoundingMode: UInt, Sendable, Hashable {
    case roundPreferCeil = 0
    case roundPreferFloor = 1
    case ceil = 2
    case floor = 3
    case roundToEven = 4
    case roundToOdd = 5
}

public enum MPSGraphScatterMode: Int, Sendable, Hashable {
    case set = 0
    case add = 1
    case sub = 2
    case mul = 3
    case div = 4
    case min = 5
    case max = 6
}

public enum MPSGraphSparseStorageType: UInt64, Sendable, Hashable {
    case COO = 0
    case CSC = 1
    case CSR = 2
}

public enum MPSGraphTensorNamedDataLayout: UInt, Sendable, Hashable {
    case NCHW = 0
    case NHWC = 1
    case OIHW = 2
    case HWIO = 3
    case CHW = 4
    case HWC = 5
    case HW = 6
    case NCDHW = 7
    case NDHWC = 8
    case OIDHW = 9
    case DHWIO = 10
}

public typealias MPSGraphCompilationCompletionHandler = (MPSGraphExecutable, (any Error)?) -> Void
public typealias MPSGraphCompletionHandler = ([MPSGraphTensor: MPSGraphTensorData], (any Error)?) -> Void
public typealias MPSGraphControlFlowDependencyBlock = () -> [MPSGraphTensor]
public typealias MPSGraphExecutableCompletionHandler = ([MPSGraphTensorData], (any Error)?) -> Void
public typealias MPSGraphExecutableScheduledHandler = ([MPSGraphTensorData], (any Error)?) -> Void
public typealias MPSGraphForLoopBodyBlock = (MPSGraphTensor, [MPSGraphTensor]) -> [MPSGraphTensor]
public typealias MPSGraphIfThenElseBlock = () -> [MPSGraphTensor]
public typealias MPSGraphScheduledHandler = ([MPSGraphTensor: MPSGraphTensorData], (any Error)?) -> Void
public typealias MPSGraphWhileAfterBlock = ([MPSGraphTensor]) -> [MPSGraphTensor]
public typealias MPSGraphWhileBeforeBlock = ([MPSGraphTensor], NSMutableArray) -> MPSGraphTensor
