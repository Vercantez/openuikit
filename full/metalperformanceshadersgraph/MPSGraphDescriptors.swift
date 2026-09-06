import Foundation
import Dispatch

open class MPSGraphCompilationDescriptor: MPSGraphObject {
    public var callables: [String: MPSGraphExecutable]?
    public var compilationCompletionHandler: MPSGraphCompilationCompletionHandler = { _, _ in }
    public var dispatchQueue: dispatch_queue_t = DispatchQueue(label: "MPSGraphCompilation")
    public var optimizationLevel: MPSGraphOptimization = .level0
    public var optimizationProfile: MPSGraphOptimizationProfile = .performance
    public var reducedPrecisionFastMath: MPSGraphReducedPrecisionFastMath = .none
    public var waitForCompilationCompletion: Bool = false
    public private(set) var typeInferenceDisabled: Bool = false

    public func disableTypeInference() {
        typeInferenceDisabled = true
    }
}

open class MPSGraphConvolution2DOpDescriptor: MPSGraphObject {
    public var strideInX: Int = 1
    public var strideInY: Int = 1
    public var dilationRateInX: Int = 1
    public var dilationRateInY: Int = 1
    public var groups: Int = 1
    public var paddingLeft: Int = 0
    public var paddingRight: Int = 0
    public var paddingTop: Int = 0
    public var paddingBottom: Int = 0
    public var paddingStyle: MPSGraphPaddingStyle = .explicit
    public var dataLayout: MPSGraphTensorNamedDataLayout = .NCHW
    public var weightsLayout: MPSGraphTensorNamedDataLayout = .OIHW

    public convenience init?(
        strideInX: Int,
        strideInY: Int,
        dilationRateInX: Int,
        dilationRateInY: Int,
        groups: Int,
        paddingLeft: Int,
        paddingRight: Int,
        paddingTop: Int,
        paddingBottom: Int,
        paddingStyle: MPSGraphPaddingStyle,
        dataLayout: MPSGraphTensorNamedDataLayout,
        weightsLayout: MPSGraphTensorNamedDataLayout
    ) {
        guard groups >= 1, strideInX >= 1, strideInY >= 1 else { return nil }
        self.init()
        self.strideInX = strideInX
        self.strideInY = strideInY
        self.dilationRateInX = dilationRateInX
        self.dilationRateInY = dilationRateInY
        self.groups = groups
        self.paddingLeft = paddingLeft
        self.paddingRight = paddingRight
        self.paddingTop = paddingTop
        self.paddingBottom = paddingBottom
        self.paddingStyle = paddingStyle
        self.dataLayout = dataLayout
        self.weightsLayout = weightsLayout
    }

    public convenience init?(
        strideInX: Int,
        strideInY: Int,
        dilationRateInX: Int,
        dilationRateInY: Int,
        groups: Int,
        paddingStyle: MPSGraphPaddingStyle,
        dataLayout: MPSGraphTensorNamedDataLayout,
        weightsLayout: MPSGraphTensorNamedDataLayout
    ) {
        self.init(
            strideInX: strideInX,
            strideInY: strideInY,
            dilationRateInX: dilationRateInX,
            dilationRateInY: dilationRateInY,
            groups: groups,
            paddingLeft: 0,
            paddingRight: 0,
            paddingTop: 0,
            paddingBottom: 0,
            paddingStyle: paddingStyle,
            dataLayout: dataLayout,
            weightsLayout: weightsLayout
        )
    }

    public func setExplicitPaddingWithPaddingLeft(
        _ paddingLeft: Int,
        paddingRight: Int,
        paddingTop: Int,
        paddingBottom: Int
    ) {
        self.paddingLeft = paddingLeft
        self.paddingRight = paddingRight
        self.paddingTop = paddingTop
        self.paddingBottom = paddingBottom
        self.paddingStyle = .explicit
    }
}

open class MPSGraphConvolution3DOpDescriptor: MPSGraphObject {
    public var strideInX: Int = 1
    public var strideInY: Int = 1
    public var strideInZ: Int = 1
    public var dilationRateInX: Int = 1
    public var dilationRateInY: Int = 1
    public var dilationRateInZ: Int = 1
    public var groups: Int = 1
    public var paddingLeft: Int = 0
    public var paddingRight: Int = 0
    public var paddingTop: Int = 0
    public var paddingBottom: Int = 0
    public var paddingFront: Int = 0
    public var paddingBack: Int = 0
    public var paddingStyle: MPSGraphPaddingStyle = .explicit
    public var dataLayout: MPSGraphTensorNamedDataLayout = .NCDHW
    public var weightsLayout: MPSGraphTensorNamedDataLayout = .OIDHW

    public convenience init?(
        strideInX: Int,
        strideInY: Int,
        strideInZ: Int,
        dilationRateInX: Int,
        dilationRateInY: Int,
        dilationRateInZ: Int,
        groups: Int,
        paddingLeft: Int,
        paddingRight: Int,
        paddingTop: Int,
        paddingBottom: Int,
        paddingFront: Int,
        paddingBack: Int,
        paddingStyle: MPSGraphPaddingStyle,
        dataLayout: MPSGraphTensorNamedDataLayout,
        weightsLayout: MPSGraphTensorNamedDataLayout
    ) {
        guard groups >= 1 else { return nil }
        self.init()
        self.strideInX = strideInX
        self.strideInY = strideInY
        self.strideInZ = strideInZ
        self.dilationRateInX = dilationRateInX
        self.dilationRateInY = dilationRateInY
        self.dilationRateInZ = dilationRateInZ
        self.groups = groups
        self.paddingLeft = paddingLeft
        self.paddingRight = paddingRight
        self.paddingTop = paddingTop
        self.paddingBottom = paddingBottom
        self.paddingFront = paddingFront
        self.paddingBack = paddingBack
        self.paddingStyle = paddingStyle
        self.dataLayout = dataLayout
        self.weightsLayout = weightsLayout
    }

    public convenience init?(
        strideInX: Int,
        strideInY: Int,
        strideInZ: Int,
        dilationRateInX: Int,
        dilationRateInY: Int,
        dilationRateInZ: Int,
        groups: Int,
        paddingStyle: MPSGraphPaddingStyle,
        dataLayout: MPSGraphTensorNamedDataLayout,
        weightsLayout: MPSGraphTensorNamedDataLayout
    ) {
        self.init(
            strideInX: strideInX,
            strideInY: strideInY,
            strideInZ: strideInZ,
            dilationRateInX: dilationRateInX,
            dilationRateInY: dilationRateInY,
            dilationRateInZ: dilationRateInZ,
            groups: groups,
            paddingLeft: 0,
            paddingRight: 0,
            paddingTop: 0,
            paddingBottom: 0,
            paddingFront: 0,
            paddingBack: 0,
            paddingStyle: paddingStyle,
            dataLayout: dataLayout,
            weightsLayout: weightsLayout
        )
    }

    public func setExplicitPaddingWithPaddingLeft(
        _ paddingLeft: Int,
        paddingRight: Int,
        paddingTop: Int,
        paddingBottom: Int,
        paddingFront: Int,
        paddingBack: Int
    ) {
        self.paddingLeft = paddingLeft
        self.paddingRight = paddingRight
        self.paddingTop = paddingTop
        self.paddingBottom = paddingBottom
        self.paddingFront = paddingFront
        self.paddingBack = paddingBack
        self.paddingStyle = .explicit
    }
}

open class MPSGraphCreateSparseOpDescriptor: MPSGraphObject {
    public var dataType: MPSDataType = .float32
    public var sparseStorageType: MPSGraphSparseStorageType = .COO

    public class func sparseDescriptor(
        descriptorWithStorageType sparseStorageType: MPSGraphSparseStorageType,
        dataType: MPSDataType
    ) -> MPSGraphCreateSparseOpDescriptor? {
        let descriptor = MPSGraphCreateSparseOpDescriptor()
        descriptor.sparseStorageType = sparseStorageType
        descriptor.dataType = dataType
        return descriptor
    }
}

open class MPSGraphDepthwiseConvolution2DOpDescriptor: MPSGraphObject {
    public var strideInX: Int = 1
    public var strideInY: Int = 1
    public var dilationRateInX: Int = 1
    public var dilationRateInY: Int = 1
    public var paddingLeft: Int = 0
    public var paddingRight: Int = 0
    public var paddingTop: Int = 0
    public var paddingBottom: Int = 0
    public var paddingStyle: MPSGraphPaddingStyle = .explicit
    public var dataLayout: MPSGraphTensorNamedDataLayout = .NCHW
    public var weightsLayout: MPSGraphTensorNamedDataLayout = .OIHW

    public convenience init?(
        dataLayout: MPSGraphTensorNamedDataLayout,
        weightsLayout: MPSGraphTensorNamedDataLayout
    ) {
        self.init()
        self.dataLayout = dataLayout
        self.weightsLayout = weightsLayout
    }

    public convenience init?(
        strideInX: Int,
        strideInY: Int,
        dilationRateInX: Int,
        dilationRateInY: Int,
        paddingLeft: Int,
        paddingRight: Int,
        paddingTop: Int,
        paddingBottom: Int,
        paddingStyle: MPSGraphPaddingStyle,
        dataLayout: MPSGraphTensorNamedDataLayout,
        weightsLayout: MPSGraphTensorNamedDataLayout
    ) {
        self.init()
        self.strideInX = strideInX
        self.strideInY = strideInY
        self.dilationRateInX = dilationRateInX
        self.dilationRateInY = dilationRateInY
        self.paddingLeft = paddingLeft
        self.paddingRight = paddingRight
        self.paddingTop = paddingTop
        self.paddingBottom = paddingBottom
        self.paddingStyle = paddingStyle
        self.dataLayout = dataLayout
        self.weightsLayout = weightsLayout
    }

    public func setExplicitPaddingWithPaddingLeft(
        _ paddingLeft: Int,
        paddingRight: Int,
        paddingTop: Int,
        paddingBottom: Int
    ) {
        self.paddingLeft = paddingLeft
        self.paddingRight = paddingRight
        self.paddingTop = paddingTop
        self.paddingBottom = paddingBottom
        self.paddingStyle = .explicit
    }
}

open class MPSGraphDepthwiseConvolution3DOpDescriptor: MPSGraphObject {
    public var channelDimensionIndex: Int = -4
    public var dilationRates: [NSNumber] = [1, 1, 1]
    public var paddingStyle: MPSGraphPaddingStyle = .explicit
    public var paddingValues: [NSNumber] = [0, 0, 0, 0, 0, 0]
    public var strides: [NSNumber] = [1, 1, 1]

    public convenience init?(paddingStyle: MPSGraphPaddingStyle) {
        self.init()
        self.paddingStyle = paddingStyle
    }

    public convenience init?(
        strides: [NSNumber],
        dilationRates: [NSNumber],
        paddingValues: [NSNumber],
        paddingStyle: MPSGraphPaddingStyle
    ) {
        self.init()
        self.strides = strides
        self.dilationRates = dilationRates
        self.paddingValues = paddingValues
        self.paddingStyle = paddingStyle
    }
}

open class MPSGraphFFTDescriptor: MPSGraphObject {
    public var inverse: Bool = false
    public var roundToOddHermitean: Bool = false
    public var scalingMode: MPSGraphFFTScalingMode = .none
}

open class MPSGraphGRUDescriptor: MPSGraphObject {
    public var bidirectional: Bool = false
    public var flipZ: Bool = false
    public var outputGateActivation: MPSGraphRNNActivation = .tanh
    public var resetAfter: Bool = true
    public var resetGateActivation: MPSGraphRNNActivation = .sigmoid
    public var resetGateFirst: Bool = false
    public var reverse: Bool = false
    public var training: Bool = false
    public var updateGateActivation: MPSGraphRNNActivation = .sigmoid
}

open class MPSGraphImToColOpDescriptor: MPSGraphObject {
    public var dataLayout: MPSGraphTensorNamedDataLayout = .NCHW
    public var dilationRateInX: Int = 1
    public var dilationRateInY: Int = 1
    public var kernelHeight: Int = 1
    public var kernelWidth: Int = 1
    public var paddingBottom: Int = 0
    public var paddingLeft: Int = 0
    public var paddingRight: Int = 0
    public var paddingTop: Int = 0
    public var strideInX: Int = 1
    public var strideInY: Int = 1

    public convenience init?(
        kernelWidth: Int,
        kernelHeight: Int,
        strideInX: Int,
        strideInY: Int,
        dilationRateInX: Int,
        dilationRateInY: Int,
        dataLayout: MPSGraphTensorNamedDataLayout
    ) {
        guard kernelWidth >= 1, kernelHeight >= 1 else { return nil }
        self.init()
        self.kernelWidth = kernelWidth
        self.kernelHeight = kernelHeight
        self.strideInX = strideInX
        self.strideInY = strideInY
        self.dilationRateInX = dilationRateInX
        self.dilationRateInY = dilationRateInY
        self.dataLayout = dataLayout
    }

    public convenience init?(
        kernelWidth: Int,
        kernelHeight: Int,
        strideInX: Int,
        strideInY: Int,
        dilationRateInX: Int,
        dilationRateInY: Int,
        paddingLeft: Int,
        paddingRight: Int,
        paddingTop: Int,
        paddingBottom: Int,
        dataLayout: MPSGraphTensorNamedDataLayout
    ) {
        self.init(
            kernelWidth: kernelWidth,
            kernelHeight: kernelHeight,
            strideInX: strideInX,
            strideInY: strideInY,
            dilationRateInX: dilationRateInX,
            dilationRateInY: dilationRateInY,
            dataLayout: dataLayout
        )
        self.paddingLeft = paddingLeft
        self.paddingRight = paddingRight
        self.paddingTop = paddingTop
        self.paddingBottom = paddingBottom
    }

    public func setExplicitPaddingWithPaddingLeft(
        _ paddingLeft: Int,
        paddingRight: Int,
        paddingTop: Int,
        paddingBottom: Int
    ) {
        self.paddingLeft = paddingLeft
        self.paddingRight = paddingRight
        self.paddingTop = paddingTop
        self.paddingBottom = paddingBottom
    }
}

open class MPSGraphLSTMDescriptor: MPSGraphObject {
    public var activation: MPSGraphRNNActivation = .tanh
    public var bidirectional: Bool = false
    public var cellGateActivation: MPSGraphRNNActivation = .tanh
    public var forgetGateActivation: MPSGraphRNNActivation = .sigmoid
    public var forgetGateLast: Bool = false
    public var inputGateActivation: MPSGraphRNNActivation = .sigmoid
    public var outputGateActivation: MPSGraphRNNActivation = .sigmoid
    public var produceCell: Bool = false
    public var reverse: Bool = false
    public var training: Bool = false
}

open class MPSGraphPooling2DOpDescriptor: MPSGraphObject {
    public var ceilMode: Bool = false
    public var dataLayout: MPSGraphTensorNamedDataLayout = .NCHW
    public var dilationRateInX: Int = 1
    public var dilationRateInY: Int = 1
    public var includeZeroPadToAverage: Bool = false
    public var kernelHeight: Int = 1
    public var kernelWidth: Int = 1
    public var paddingBottom: Int = 0
    public var paddingLeft: Int = 0
    public var paddingRight: Int = 0
    public var paddingStyle: MPSGraphPaddingStyle = .explicit
    public var paddingTop: Int = 0
    public var returnIndicesDataType: MPSDataType = .int32
    public var returnIndicesMode: MPSGraphPoolingReturnIndicesMode = .none
    public var strideInX: Int = 1
    public var strideInY: Int = 1

    public convenience init?(
        kernelWidth: Int,
        kernelHeight: Int,
        strideInX: Int,
        strideInY: Int,
        dilationRateInX: Int,
        dilationRateInY: Int,
        paddingLeft: Int,
        paddingRight: Int,
        paddingTop: Int,
        paddingBottom: Int,
        paddingStyle: MPSGraphPaddingStyle,
        dataLayout: MPSGraphTensorNamedDataLayout
    ) {
        guard kernelWidth >= 1, kernelHeight >= 1 else { return nil }
        self.init()
        self.kernelWidth = kernelWidth
        self.kernelHeight = kernelHeight
        self.strideInX = strideInX
        self.strideInY = strideInY
        self.dilationRateInX = dilationRateInX
        self.dilationRateInY = dilationRateInY
        self.paddingLeft = paddingLeft
        self.paddingRight = paddingRight
        self.paddingTop = paddingTop
        self.paddingBottom = paddingBottom
        self.paddingStyle = paddingStyle
        self.dataLayout = dataLayout
    }

    public convenience init?(
        kernelWidth: Int,
        kernelHeight: Int,
        strideInX: Int,
        strideInY: Int,
        paddingStyle: MPSGraphPaddingStyle,
        dataLayout: MPSGraphTensorNamedDataLayout
    ) {
        self.init(
            kernelWidth: kernelWidth,
            kernelHeight: kernelHeight,
            strideInX: strideInX,
            strideInY: strideInY,
            dilationRateInX: 1,
            dilationRateInY: 1,
            paddingLeft: 0,
            paddingRight: 0,
            paddingTop: 0,
            paddingBottom: 0,
            paddingStyle: paddingStyle,
            dataLayout: dataLayout
        )
    }

    public func setExplicitPaddingWithPaddingLeft(
        _ paddingLeft: Int,
        paddingRight: Int,
        paddingTop: Int,
        paddingBottom: Int
    ) {
        self.paddingLeft = paddingLeft
        self.paddingRight = paddingRight
        self.paddingTop = paddingTop
        self.paddingBottom = paddingBottom
        self.paddingStyle = .explicit
    }
}

open class MPSGraphPooling4DOpDescriptor: MPSGraphObject {
    public var ceilMode: Bool = false
    public var dilationRates: [NSNumber] = [1, 1, 1, 1]
    public var includeZeroPadToAverage: Bool = false
    public var kernelSizes: [NSNumber] = [1, 1, 1, 1]
    public var paddingStyle: MPSGraphPaddingStyle = .explicit
    public var paddingValues: [NSNumber] = [0, 0, 0, 0, 0, 0, 0, 0]
    public var returnIndicesDataType: MPSDataType = .int32
    public var returnIndicesMode: MPSGraphPoolingReturnIndicesMode = .none
    public var strides: [NSNumber] = [1, 1, 1, 1]

    public convenience init?(kernelSizes: [NSNumber], paddingStyle: MPSGraphPaddingStyle) {
        guard !kernelSizes.isEmpty else { return nil }
        self.init()
        self.kernelSizes = kernelSizes
        self.paddingStyle = paddingStyle
        self.strides = Array(repeating: 1 as NSNumber, count: kernelSizes.count)
        self.dilationRates = Array(repeating: 1 as NSNumber, count: kernelSizes.count)
        self.paddingValues = Array(repeating: 0 as NSNumber, count: kernelSizes.count * 2)
    }

    public convenience init?(
        kernelSizes: [NSNumber],
        strides: [NSNumber],
        dilationRates: [NSNumber],
        paddingValues: [NSNumber],
        paddingStyle: MPSGraphPaddingStyle
    ) {
        guard !kernelSizes.isEmpty else { return nil }
        self.init()
        self.kernelSizes = kernelSizes
        self.strides = strides
        self.dilationRates = dilationRates
        self.paddingValues = paddingValues
        self.paddingStyle = paddingStyle
    }
}

open class MPSGraphRandomOpDescriptor: MPSGraphObject {
    public var dataType: MPSDataType = .float32
    public var distribution: MPSGraphRandomDistribution = .uniform
    public var max: Float = 1
    public var maxInteger: Int = Int(Int32.max)
    public var mean: Float = 0
    public var min: Float = 0
    public var minInteger: Int = 0
    public var samplingMethod: MPSGraphRandomNormalSamplingMethod = .invCDF
    public var standardDeviation: Float = 1

    public convenience init?(distribution: MPSGraphRandomDistribution, dataType: MPSDataType) {
        self.init()
        self.distribution = distribution
        self.dataType = dataType
    }
}

open class MPSGraphSingleGateRNNDescriptor: MPSGraphObject {
    public var activation: MPSGraphRNNActivation = .relu
    public var bidirectional: Bool = false
    public var reverse: Bool = false
    public var training: Bool = false
}

open class MPSGraphStencilOpDescriptor: MPSGraphObject {
    public var boundaryMode: MPSGraphPaddingMode = .zero
    public var dilationRates: [NSNumber] = [1]
    public var explicitPadding: [NSNumber] = [0, 0]
    public var offsets: [NSNumber] = [0]
    public var paddingConstant: Float = 0
    public var paddingStyle: MPSGraphPaddingStyle = .explicit
    public var reductionMode: MPSGraphReductionMode = .sum
    public var strides: [NSNumber] = [1]

    public convenience init?(explicitPadding: [NSNumber]) {
        self.init()
        self.explicitPadding = explicitPadding
    }

    public convenience init?(offsets: [NSNumber], explicitPadding: [NSNumber]) {
        self.init()
        self.offsets = offsets
        self.explicitPadding = explicitPadding
    }

    public convenience init?(paddingStyle: MPSGraphPaddingStyle) {
        self.init()
        self.paddingStyle = paddingStyle
    }

    public convenience init?(
        reductionMode: MPSGraphReductionMode,
        offsets: [NSNumber],
        strides: [NSNumber],
        dilationRates: [NSNumber],
        explicitPadding: [NSNumber],
        boundaryMode: MPSGraphPaddingMode,
        paddingStyle: MPSGraphPaddingStyle,
        paddingConstant: Float
    ) {
        self.init()
        self.reductionMode = reductionMode
        self.offsets = offsets
        self.strides = strides
        self.dilationRates = dilationRates
        self.explicitPadding = explicitPadding
        self.boundaryMode = boundaryMode
        self.paddingStyle = paddingStyle
        self.paddingConstant = paddingConstant
    }
}

open class MPSGraphExecutionDescriptor: MPSGraphObject {
    public var compilationDescriptor: MPSGraphCompilationDescriptor?
    public var completionHandler: MPSGraphCompletionHandler = { _, _ in }
    public var scheduledHandler: MPSGraphScheduledHandler = { _, _ in }
    public var waitUntilCompleted: Bool = false
}

open class MPSGraphExecutableExecutionDescriptor: MPSGraphObject {
    public var completionHandler: MPSGraphExecutableCompletionHandler = { _, _ in }
    public var scheduledHandler: MPSGraphExecutableScheduledHandler = { _, _ in }
    public var waitUntilCompleted: Bool = false
}

open class MPSGraphExecutableSerializationDescriptor: MPSGraphObject {
    public var append: Bool = false
    public var deploymentPlatform: MPSGraphDeploymentPlatform = .macOS
    public var minimumDeploymentTarget: String = "14.0"
}
