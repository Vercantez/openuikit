import Foundation

open class MLCLayer: NSObject {
    public let layerID: Int
    public var label: String
    public var isDebuggingEnabled: Bool
    public private(set) var deviceType: MLCDeviceType

    public override init() {
        self.layerID = MLCHostCounters.nextLayerID()
        self.label = String(describing: type(of: self))
        self.isDebuggingEnabled = false
        self.deviceType = .cpu
        super.init()
    }

    public class func supportsDataType(_ dataType: MLCDataType, on device: MLCDevice) -> Bool {
        guard device.actualDeviceType == .cpu else { return false }
        switch dataType {
        case .float32, .float16, .int32, .int64, .int8, .uint8, .boolean:
            return true
        }
    }

    func linuxAttach(deviceType: MLCDeviceType) {
        self.deviceType = deviceType
    }
}

open class MLCActivationLayer: MLCLayer {
    public let descriptor: MLCActivationDescriptor

    public convenience init(descriptor: MLCActivationDescriptor) {
        self.init(linuxDescriptor: descriptor)
    }

    public required init(linuxDescriptor: MLCActivationDescriptor) {
        self.descriptor = linuxDescriptor
        super.init()
        label = "activation"
    }

    public class var relu: MLCActivationLayer {
        MLCActivationLayer(descriptor: MLCActivationDescriptor(type: .relu)!)
    }

    public class var relu6: MLCActivationLayer {
        MLCActivationLayer(descriptor: MLCActivationDescriptor(type: .relun, a: 6, b: 0)!)
    }

    public class var leakyReLU: MLCActivationLayer {
        leakyReLU(negativeSlope: 0.01)
    }

    public class func leakyReLU(negativeSlope: Float) -> Self {
        Self(linuxDescriptor: MLCActivationDescriptor(type: .relu, a: negativeSlope)!)
    }

    public class func linear(scale: Float, bias: Float) -> Self {
        Self(linuxDescriptor: MLCActivationDescriptor(type: .linear, a: scale, b: bias)!)
    }

    public class var sigmoid: MLCActivationLayer {
        MLCActivationLayer(descriptor: MLCActivationDescriptor(type: .sigmoid)!)
    }

    public class var hardSigmoid: MLCActivationLayer {
        MLCActivationLayer(descriptor: MLCActivationDescriptor(type: .hardSigmoid)!)
    }

    public class var tanh: MLCActivationLayer {
        MLCActivationLayer(descriptor: MLCActivationDescriptor(type: .tanh)!)
    }

    public class var absolute: MLCActivationLayer {
        MLCActivationLayer(descriptor: MLCActivationDescriptor(type: .absolute)!)
    }

    public class var softPlus: MLCActivationLayer {
        MLCActivationLayer(descriptor: MLCActivationDescriptor(type: .softPlus)!)
    }

    public class func softPlus(beta: Float) -> Self {
        Self(linuxDescriptor: MLCActivationDescriptor(type: .softPlus, a: beta)!)
    }

    public class var softSign: MLCActivationLayer {
        MLCActivationLayer(descriptor: MLCActivationDescriptor(type: .softSign)!)
    }

    public class var elu: MLCActivationLayer {
        MLCActivationLayer(descriptor: MLCActivationDescriptor(type: .elu)!)
    }

    public class func elu(a: Float) -> Self {
        Self(linuxDescriptor: MLCActivationDescriptor(type: .elu, a: a)!)
    }

    public class func relun(a: Float, b: Float) -> Self {
        Self(linuxDescriptor: MLCActivationDescriptor(type: .relun, a: a, b: b)!)
    }

    public class var logSigmoid: MLCActivationLayer {
        MLCActivationLayer(descriptor: MLCActivationDescriptor(type: .logSigmoid)!)
    }

    public class var selu: MLCActivationLayer {
        MLCActivationLayer(descriptor: MLCActivationDescriptor(type: .selu)!)
    }

    public class var celu: MLCActivationLayer {
        MLCActivationLayer(descriptor: MLCActivationDescriptor(type: .celu)!)
    }

    public class func celu(a: Float) -> Self {
        Self(linuxDescriptor: MLCActivationDescriptor(type: .celu, a: a)!)
    }

    public class var hardShrink: MLCActivationLayer {
        MLCActivationLayer(descriptor: MLCActivationDescriptor(type: .hardShrink)!)
    }

    public class func hardShrink(a: Float) -> Self {
        Self(linuxDescriptor: MLCActivationDescriptor(type: .hardShrink, a: a)!)
    }

    public class var softShrink: MLCActivationLayer {
        MLCActivationLayer(descriptor: MLCActivationDescriptor(type: .softShrink)!)
    }

    public class func softShrink(a: Float) -> Self {
        Self(linuxDescriptor: MLCActivationDescriptor(type: .softShrink, a: a)!)
    }

    public class var tanhShrink: MLCActivationLayer {
        MLCActivationLayer(descriptor: MLCActivationDescriptor(type: .tanhShrink)!)
    }

    public class func threshold(_ threshold: Float, replacement: Float) -> Self {
        Self(linuxDescriptor: MLCActivationDescriptor(type: .threshold, a: threshold, b: replacement)!)
    }

    public class var gelu: MLCActivationLayer {
        MLCActivationLayer(descriptor: MLCActivationDescriptor(type: .gelu)!)
    }

    public class var hardSwish: MLCActivationLayer {
        MLCActivationLayer(descriptor: MLCActivationDescriptor(type: .hardSwish)!)
    }

    public class func clamp(min minValue: Float, max maxValue: Float) -> Self {
        Self(linuxDescriptor: MLCActivationDescriptor(type: .clamp, a: minValue, b: maxValue)!)
    }
}

open class MLCArithmeticLayer: MLCLayer {
    public let operation: MLCArithmeticOperation

    public init(operation: MLCArithmeticOperation) {
        self.operation = operation
        super.init()
        label = "arithmetic"
    }
}

open class MLCComparisonLayer: MLCLayer {
    public let operation: MLCComparisonOperation

    public init(operation: MLCComparisonOperation) {
        self.operation = operation
        super.init()
        label = "comparison"
    }
}

open class MLCConcatenationLayer: MLCLayer {
    public let dimension: Int

    public override convenience init() {
        self.init(dimension: 0)
    }

    public init(dimension: Int) {
        self.dimension = dimension
        super.init()
        label = "concat"
    }
}

open class MLCDropoutLayer: MLCLayer {
    public let rate: Float
    public let seed: Int

    public init(rate: Float, seed: Int) {
        self.rate = rate
        self.seed = seed
        super.init()
        label = "dropout"
    }
}

open class MLCGatherLayer: MLCLayer {
    public let dimension: Int

    public init(dimension: Int) {
        self.dimension = dimension
        super.init()
        label = "gather"
    }
}

open class MLCGramMatrixLayer: MLCLayer {
    public let scale: Float

    public init(scale: Float) {
        self.scale = scale
        super.init()
        label = "gramMatrix"
    }
}

open class MLCReshapeLayer: MLCLayer {
    public let shape: [Int]

    public init?(shape: [Int]) {
        guard !shape.isEmpty, shape.count <= MLCTensorDescriptor.maxTensorDimensions else { return nil }
        self.shape = shape
        super.init()
        label = "reshape"
    }
}

open class MLCTransposeLayer: MLCLayer {
    public let dimensions: [Int]

    public init?(dimensions: [Int]) {
        guard !dimensions.isEmpty else { return nil }
        self.dimensions = dimensions
        super.init()
        label = "transpose"
    }
}

open class MLCSoftmaxLayer: MLCLayer {
    public let operation: MLCSoftmaxOperation
    public let dimension: Int

    public convenience init(operation: MLCSoftmaxOperation) {
        self.init(operation: operation, dimension: 0)
    }

    public init(operation: MLCSoftmaxOperation, dimension: Int) {
        self.operation = operation
        self.dimension = dimension
        super.init()
        label = "softmax"
    }
}

open class MLCSelectionLayer: MLCLayer {
    public override convenience init() {
        self.init(linux: ())
    }

    public init(linux: ()) {
        super.init()
        label = "selection"
    }
}

open class MLCSliceLayer: MLCLayer {
    public let start: [Int]
    public let end: [Int]
    public let stride: [Int]?

    public init?(start: [Int], end: [Int], stride: [Int]?) {
        guard start.count == end.count, start.count > 0 else { return nil }
        if let stride, stride.count != start.count { return nil }
        self.start = start
        self.end = end
        self.stride = stride
        super.init()
        label = "slice"
    }
}

open class MLCSplitLayer: MLCLayer {
    public let splitCount: Int
    public let dimension: Int
    public let splitSectionLengths: [Int]?

    public init(splitCount: Int, dimension: Int) {
        self.splitCount = splitCount
        self.dimension = dimension
        self.splitSectionLengths = nil
        super.init()
        label = "split"
    }

    public init(splitSectionLengths: [Int], dimension: Int) {
        self.splitCount = splitSectionLengths.count
        self.dimension = dimension
        self.splitSectionLengths = splitSectionLengths
        super.init()
        label = "split"
    }
}

open class MLCScatterLayer: MLCLayer {
    public let dimension: Int
    public let reductionType: MLCReductionType

    public init?(dimension: Int, reductionType: MLCReductionType) {
        self.dimension = dimension
        self.reductionType = reductionType
        super.init()
        label = "scatter"
    }
}

open class MLCReductionLayer: MLCLayer {
    public let reductionType: MLCReductionType
    public let dimension: Int
    public let dimensions: [Int]

    public convenience init?(reductionType: MLCReductionType, dimension: Int) {
        self.init(reductionType: reductionType, dimensions: [dimension])
    }

    public init?(reductionType: MLCReductionType, dimensions: [Int]) {
        guard !dimensions.isEmpty else { return nil }
        self.reductionType = reductionType
        self.dimension = dimensions[0]
        self.dimensions = dimensions
        super.init()
        label = "reduction"
    }
}

open class MLCPaddingLayer: MLCLayer {
    public let paddingLeft: Int
    public let paddingRight: Int
    public let paddingTop: Int
    public let paddingBottom: Int
    public let paddingType: MLCPaddingType
    public let constantValue: Float

    public convenience init(zeroPadding: [Int]) {
        let pads = MLCPaddingLayer.unpack(zeroPadding)
        self.init(
            left: pads.0,
            right: pads.1,
            top: pads.2,
            bottom: pads.3,
            type: .zero,
            constantValue: 0
        )
    }

    public convenience init(reflectionPadding: [Int]) {
        let pads = MLCPaddingLayer.unpack(reflectionPadding)
        self.init(
            left: pads.0,
            right: pads.1,
            top: pads.2,
            bottom: pads.3,
            type: .reflect,
            constantValue: 0
        )
    }

    public convenience init(symmetricPadding: [Int]) {
        let pads = MLCPaddingLayer.unpack(symmetricPadding)
        self.init(
            left: pads.0,
            right: pads.1,
            top: pads.2,
            bottom: pads.3,
            type: .symmetric,
            constantValue: 0
        )
    }

    public convenience init(constantPadding: [Int], constantValue: Float) {
        let pads = MLCPaddingLayer.unpack(constantPadding)
        self.init(
            left: pads.0,
            right: pads.1,
            top: pads.2,
            bottom: pads.3,
            type: .constant,
            constantValue: constantValue
        )
    }

    init(left: Int, right: Int, top: Int, bottom: Int, type: MLCPaddingType, constantValue: Float) {
        self.paddingLeft = left
        self.paddingRight = right
        self.paddingTop = top
        self.paddingBottom = bottom
        self.paddingType = type
        self.constantValue = constantValue
        super.init()
        label = "padding"
    }

    static func unpack(_ values: [Int]) -> (Int, Int, Int, Int) {
        switch values.count {
        case 1:
            return (values[0], values[0], values[0], values[0])
        case 2:
            return (values[1], values[1], values[0], values[0])
        case 4:
            return (values[0], values[1], values[2], values[3])
        default:
            return (0, 0, 0, 0)
        }
    }
}

open class MLCUpsampleLayer: MLCLayer {
    public let shape: [Int]
    public let sampleMode: MLCSampleMode
    public let alignsCorners: Bool

    public convenience init?(shape: [Int]) {
        self.init(shape: shape, sampleMode: .nearest, alignsCorners: false)
    }

    public init?(shape: [Int], sampleMode: MLCSampleMode, alignsCorners: Bool) {
        guard !shape.isEmpty else { return nil }
        self.shape = shape
        self.sampleMode = sampleMode
        self.alignsCorners = alignsCorners
        super.init()
        label = "upsample"
    }
}

open class MLCPoolingLayer: MLCLayer {
    public let descriptor: MLCPoolingDescriptor

    public init(descriptor: MLCPoolingDescriptor) {
        self.descriptor = descriptor
        super.init()
        label = "pooling"
    }
}

open class MLCMatMulLayer: MLCLayer {
    public let descriptor: MLCMatMulDescriptor

    public init?(descriptor: MLCMatMulDescriptor) {
        self.descriptor = descriptor
        super.init()
        label = "matmul"
    }
}
