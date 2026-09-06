import Foundation
import MLCompute

func testActivationTypeRawValues() {
    let cases: [(MLCActivationType, Int32)] = [
        (.none, 0), (.relu, 1), (.linear, 2), (.sigmoid, 3), (.hardSigmoid, 4),
        (.tanh, 5), (.absolute, 6), (.softPlus, 7), (.softSign, 8), (.elu, 9),
        (.relun, 10), (.logSigmoid, 11), (.selu, 12), (.celu, 13), (.hardShrink, 14),
        (.softShrink, 15), (.tanhShrink, 16), (.threshold, 17), (.gelu, 18),
        (.hardSwish, 19), (.clamp, 20),
    ]
    for (value, raw) in cases {
        precondition(value.rawValue == raw)
        precondition(MLCActivationType(rawValue: raw) == value)
        precondition(value.debugDescription.isEmpty == false)
        precondition(value != MLCActivationType(rawValue: raw == 0 ? 1 : 0))
        var hasher = Hasher()
        value.hash(into: &hasher)
        precondition(value.hashValue == value.hashValue)
    }
    precondition(MLCActivationType(rawValue: 99) == nil)
}

func testArithmeticOperationRawValues() {
    let cases: [(MLCArithmeticOperation, Int32)] = [
        (.add, 0), (.subtract, 1), (.multiply, 2), (.divide, 3), (.floor, 4),
        (.round, 5), (.ceil, 6), (.sqrt, 7), (.rsqrt, 8), (.sin, 9), (.cos, 10),
        (.tan, 11), (.asin, 12), (.acos, 13), (.atan, 14), (.sinh, 15), (.cosh, 16),
        (.tanh, 17), (.asinh, 18), (.acosh, 19), (.atanh, 20), (.pow, 21),
        (.exp, 22), (.exp2, 23), (.log, 24), (.log2, 25), (.multiplyNoNaN, 26),
        (.divideNoNaN, 27), (.min, 28), (.max, 29),
    ]
    for (value, raw) in cases {
        precondition(value.rawValue == raw)
        precondition(MLCArithmeticOperation(rawValue: raw) == value)
        precondition(value.debugDescription.isEmpty == false)
        var hasher = Hasher()
        value.hash(into: &hasher)
        precondition(value.hashValue == value.hashValue)
        precondition(value != MLCArithmeticOperation.add || raw == 0)
    }
}

func testComparisonOperationRawValues() {
    let cases: [(MLCComparisonOperation, Int32)] = [
        (.equal, 0), (.notEqual, 1), (.less, 2), (.greater, 3), (.lessOrEqual, 4),
        (.greaterOrEqual, 5), (.logicalAND, 6), (.logicalOR, 7), (.logicalNOT, 8),
        (.logicalNAND, 9), (.logicalNOR, 10), (.logicalXOR, 11),
    ]
    for (value, raw) in cases {
        precondition(value.rawValue == raw)
        precondition(MLCComparisonOperation(rawValue: raw) == value)
        precondition(value.debugDescription.isEmpty == false)
        var hasher = Hasher()
        value.hash(into: &hasher)
        precondition(value.hashValue == value.hashValue)
    }
}

func testConvolutionTypeRawValues() {
    precondition(MLCConvolutionType.standard.rawValue == 0)
    precondition(MLCConvolutionType.transposed.rawValue == 1)
    precondition(MLCConvolutionType.depthwise.rawValue == 2)
    precondition(MLCConvolutionType(rawValue: 1) == .transposed)
    precondition(MLCConvolutionType.standard.debugDescription.isEmpty == false)
    precondition(MLCConvolutionType.standard != .depthwise)
    var hasher = Hasher()
    MLCConvolutionType.standard.hash(into: &hasher)
    precondition(MLCConvolutionType.standard.hashValue == MLCConvolutionType.standard.hashValue)
}

func testDataTypeRawValues() {
    precondition(MLCDataType.float32.rawValue == 1)
    precondition(MLCDataType.float16.rawValue == 3)
    precondition(MLCDataType.boolean.rawValue == 4)
    precondition(MLCDataType.int64.rawValue == 5)
    precondition(MLCDataType.int32.rawValue == 7)
    precondition(MLCDataType.int8.rawValue == 8)
    precondition(MLCDataType.uint8.rawValue == 9)
    precondition(MLCDataType(rawValue: 1) == .float32)
    precondition(MLCDataType(rawValue: 2) == nil)
    precondition(MLCDataType.float32 != .int32)
    var hasher = Hasher()
    MLCDataType.float32.hash(into: &hasher)
    precondition(MLCDataType.float32.hashValue == MLCDataType.float32.hashValue)
}

func testDeviceTypeRawValues() {
    precondition(MLCDeviceType.cpu.rawValue == 0)
    precondition(MLCDeviceType.gpu.rawValue == 1)
    precondition(MLCDeviceType.any.rawValue == 2)
    precondition(MLCDeviceType.ane.rawValue == 3)
    precondition(MLCDeviceType(rawValue: 3) == .ane)
    precondition(MLCDeviceType.cpu != .gpu)
    var hasher = Hasher()
    MLCDeviceType.cpu.hash(into: &hasher)
    precondition(MLCDeviceType.cpu.hashValue == MLCDeviceType.cpu.hashValue)
}

func testGradientClippingTypeRawValues() {
    precondition(MLCGradientClippingType.byValue.rawValue == 0)
    precondition(MLCGradientClippingType.byNorm.rawValue == 1)
    precondition(MLCGradientClippingType.byGlobalNorm.rawValue == 2)
    precondition(MLCGradientClippingType(rawValue: 1) == .byNorm)
    precondition(MLCGradientClippingType.byValue.debugDescription.isEmpty == false)
    precondition(MLCGradientClippingType.byValue != .byNorm)
    var hasher = Hasher()
    MLCGradientClippingType.byValue.hash(into: &hasher)
    precondition(MLCGradientClippingType.byValue.hashValue == MLCGradientClippingType.byValue.hashValue)
}

func testLSTMResultModeRawValues() {
    precondition(MLCLSTMResultMode.output.rawValue == 0)
    precondition(MLCLSTMResultMode.outputAndStates.rawValue == 1)
    precondition(MLCLSTMResultMode(rawValue: 1) == .outputAndStates)
    precondition(MLCLSTMResultMode.output.debugDescription.isEmpty == false)
    precondition(MLCLSTMResultMode.output != .outputAndStates)
    var hasher = Hasher()
    MLCLSTMResultMode.output.hash(into: &hasher)
    precondition(MLCLSTMResultMode.output.hashValue == MLCLSTMResultMode.output.hashValue)
}

func testLossTypeRawValues() {
    let cases: [(MLCLossType, Int32)] = [
        (.meanAbsoluteError, 0), (.meanSquaredError, 1), (.softmaxCrossEntropy, 2),
        (.sigmoidCrossEntropy, 3), (.categoricalCrossEntropy, 4), (.hinge, 5),
        (.huber, 6), (.cosineDistance, 7), (.log, 8),
    ]
    for (value, raw) in cases {
        precondition(value.rawValue == raw)
        precondition(MLCLossType(rawValue: raw) == value)
        precondition(value.debugDescription.isEmpty == false)
        var hasher = Hasher()
        value.hash(into: &hasher)
        precondition(value.hashValue == value.hashValue)
    }
    precondition(MLCLossType.hinge != .huber)
}

func testPaddingTypeRawValues() {
    precondition(MLCPaddingType.zero.rawValue == 0)
    precondition(MLCPaddingType.reflect.rawValue == 1)
    precondition(MLCPaddingType.symmetric.rawValue == 2)
    precondition(MLCPaddingType.constant.rawValue == 3)
    precondition(MLCPaddingType(rawValue: 2) == .symmetric)
    precondition(MLCPaddingType.zero.debugDescription.isEmpty == false)
    precondition(MLCPaddingType.zero != .constant)
    var hasher = Hasher()
    MLCPaddingType.zero.hash(into: &hasher)
    precondition(MLCPaddingType.zero.hashValue == MLCPaddingType.zero.hashValue)
}

func testRandomInitializerTypeRawValues() {
    precondition(MLCRandomInitializerType.uniform.rawValue == 1)
    precondition(MLCRandomInitializerType.glorotUniform.rawValue == 2)
    precondition(MLCRandomInitializerType.xavier.rawValue == 3)
    precondition(MLCRandomInitializerType(rawValue: 0) == nil)
    precondition(MLCRandomInitializerType.uniform != .xavier)
    var hasher = Hasher()
    MLCRandomInitializerType.uniform.hash(into: &hasher)
    precondition(MLCRandomInitializerType.uniform.hashValue == MLCRandomInitializerType.uniform.hashValue)
}

func testReductionTypeRawValues() {
    let cases: [(MLCReductionType, Int32)] = [
        (.none, 0), (.sum, 1), (.mean, 2), (.max, 3), (.min, 4),
        (.argMax, 5), (.argMin, 6), (.l1Norm, 7), (.any, 8), (.all, 9),
    ]
    for (value, raw) in cases {
        precondition(value.rawValue == raw)
        precondition(MLCReductionType(rawValue: raw) == value)
        precondition(value.debugDescription.isEmpty == false)
        var hasher = Hasher()
        value.hash(into: &hasher)
        precondition(value.hashValue == value.hashValue)
    }
    precondition(MLCReductionType.sum != .mean)
}

func testRegularizationTypeRawValues() {
    precondition(MLCRegularizationType.none.rawValue == 0)
    precondition(MLCRegularizationType.l1.rawValue == 1)
    precondition(MLCRegularizationType.l2.rawValue == 2)
    precondition(MLCRegularizationType(rawValue: 1) == .l1)
    precondition(MLCRegularizationType.none != .l2)
    var hasher = Hasher()
    MLCRegularizationType.l1.hash(into: &hasher)
    precondition(MLCRegularizationType.l1.hashValue == MLCRegularizationType.l1.hashValue)
}

func testSampleModeRawValues() {
    precondition(MLCSampleMode.nearest.rawValue == 0)
    precondition(MLCSampleMode.linear.rawValue == 1)
    precondition(MLCSampleMode(rawValue: 1) == .linear)
    precondition(MLCSampleMode.nearest.debugDescription.isEmpty == false)
    precondition(MLCSampleMode.nearest != .linear)
    var hasher = Hasher()
    MLCSampleMode.nearest.hash(into: &hasher)
    precondition(MLCSampleMode.nearest.hashValue == MLCSampleMode.nearest.hashValue)
}

func testSoftmaxOperationRawValues() {
    precondition(MLCSoftmaxOperation.softmax.rawValue == 0)
    precondition(MLCSoftmaxOperation.logSoftmax.rawValue == 1)
    precondition(MLCSoftmaxOperation(rawValue: 1) == .logSoftmax)
    precondition(MLCSoftmaxOperation.softmax.debugDescription.isEmpty == false)
    precondition(MLCSoftmaxOperation.softmax != .logSoftmax)
    var hasher = Hasher()
    MLCSoftmaxOperation.softmax.hash(into: &hasher)
    precondition(MLCSoftmaxOperation.softmax.hashValue == MLCSoftmaxOperation.softmax.hashValue)
}

func testPoolingTypeCases() {
    precondition(MLCPoolingType.max.debugDescription == "max")
    precondition(MLCPoolingType.l2Norm.debugDescription.contains("l2"))
    let average = MLCPoolingType.average(countIncludesPadding: true)
    precondition(average == .average(countIncludesPadding: true))
    precondition(MLCPoolingType.average(countIncludesPadding: false) != average)
}

func testPaddingPolicyCases() {
    precondition(MLCPaddingPolicy.same.debugDescription == "same")
    precondition(MLCPaddingPolicy.valid.debugDescription == "valid")
    precondition(MLCPaddingPolicy.sized(y: 2, x: 3) == .sized(y: 2, x: 3))
    precondition(MLCPaddingPolicy.sized(y: 1, x: 1).debugDescription.contains("1"))
}
