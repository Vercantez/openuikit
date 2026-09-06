import Foundation

public enum MLCActivationType: Int32, Hashable, Sendable {
    case none = 0
    case relu = 1
    case linear = 2
    case sigmoid = 3
    case hardSigmoid = 4
    case tanh = 5
    case absolute = 6
    case softPlus = 7
    case softSign = 8
    case elu = 9
    case relun = 10
    case logSigmoid = 11
    case selu = 12
    case celu = 13
    case hardShrink = 14
    case softShrink = 15
    case tanhShrink = 16
    case threshold = 17
    case gelu = 18
    case hardSwish = 19
    case clamp = 20

    public var debugDescription: String {
        String(describing: self)
    }
}

public enum MLCArithmeticOperation: Int32, Hashable, Sendable {
    case add = 0
    case subtract = 1
    case multiply = 2
    case divide = 3
    case floor = 4
    case round = 5
    case ceil = 6
    case sqrt = 7
    case rsqrt = 8
    case sin = 9
    case cos = 10
    case tan = 11
    case asin = 12
    case acos = 13
    case atan = 14
    case sinh = 15
    case cosh = 16
    case tanh = 17
    case asinh = 18
    case acosh = 19
    case atanh = 20
    case pow = 21
    case exp = 22
    case exp2 = 23
    case log = 24
    case log2 = 25
    case multiplyNoNaN = 26
    case divideNoNaN = 27
    case min = 28
    case max = 29

    public var debugDescription: String {
        String(describing: self)
    }
}

public enum MLCComparisonOperation: Int32, Hashable, Sendable {
    case equal = 0
    case notEqual = 1
    case less = 2
    case greater = 3
    case lessOrEqual = 4
    case greaterOrEqual = 5
    case logicalAND = 6
    case logicalOR = 7
    case logicalNOT = 8
    case logicalNAND = 9
    case logicalNOR = 10
    case logicalXOR = 11

    public var debugDescription: String {
        String(describing: self)
    }
}

public enum MLCConvolutionType: Int32, Hashable, Sendable {
    case standard = 0
    case transposed = 1
    case depthwise = 2

    public var debugDescription: String {
        String(describing: self)
    }
}

public enum MLCDataType: Int32, Hashable, Sendable {
    case float32 = 1
    case float16 = 3
    case boolean = 4
    case int64 = 5
    case int32 = 7
    case int8 = 8
    case uint8 = 9
}

public enum MLCDeviceType: Int32, Hashable, Sendable {
    case cpu = 0
    case gpu = 1
    case any = 2
    case ane = 3
}

public struct MLCExecutionOptions: OptionSet, Sendable {
    public let rawValue: UInt64

    public init(rawValue: UInt64) {
        self.rawValue = rawValue
    }

    public static let skipWritingInputDataToDevice = MLCExecutionOptions(rawValue: 0x1)
    public static let synchronous = MLCExecutionOptions(rawValue: 0x2)
    public static let profiling = MLCExecutionOptions(rawValue: 0x4)
    public static let forwardForInference = MLCExecutionOptions(rawValue: 0x8)
    public static let perLayerProfiling = MLCExecutionOptions(rawValue: 0x10)
}

public enum MLCGradientClippingType: Int32, Hashable, Sendable {
    case byValue = 0
    case byNorm = 1
    case byGlobalNorm = 2

    public var debugDescription: String {
        String(describing: self)
    }
}

public struct MLCGraphCompilationOptions: OptionSet, Sendable {
    public let rawValue: UInt64

    public init(rawValue: UInt64) {
        self.rawValue = rawValue
    }

    public static let debugLayers = MLCGraphCompilationOptions(rawValue: 0x1)
    public static let disableLayerFusion = MLCGraphCompilationOptions(rawValue: 0x2)
    public static let linkGraphs = MLCGraphCompilationOptions(rawValue: 0x4)
    public static let computeAllGradients = MLCGraphCompilationOptions(rawValue: 0x8)
}

public enum MLCLSTMResultMode: UInt64, Hashable, Sendable {
    case output = 0
    case outputAndStates = 1

    public var debugDescription: String {
        String(describing: self)
    }
}

public enum MLCLossType: Int32, Hashable, Sendable {
    case meanAbsoluteError = 0
    case meanSquaredError = 1
    case softmaxCrossEntropy = 2
    case sigmoidCrossEntropy = 3
    case categoricalCrossEntropy = 4
    case hinge = 5
    case huber = 6
    case cosineDistance = 7
    case log = 8

    public var debugDescription: String {
        String(describing: self)
    }
}

public enum MLCPaddingType: Int32, Hashable, Sendable {
    case zero = 0
    case reflect = 1
    case symmetric = 2
    case constant = 3

    public var debugDescription: String {
        String(describing: self)
    }
}

public enum MLCRandomInitializerType: Int32, Hashable, Sendable {
    case uniform = 1
    case glorotUniform = 2
    case xavier = 3
}

public enum MLCReductionType: Int32, Hashable, Sendable {
    case none = 0
    case sum = 1
    case mean = 2
    case max = 3
    case min = 4
    case argMax = 5
    case argMin = 6
    case l1Norm = 7
    case any = 8
    case all = 9

    public var debugDescription: String {
        String(describing: self)
    }
}

public enum MLCRegularizationType: Int32, Hashable, Sendable {
    case none = 0
    case l1 = 1
    case l2 = 2
}

public enum MLCSampleMode: Int32, Hashable, Sendable {
    case nearest = 0
    case linear = 1

    public var debugDescription: String {
        String(describing: self)
    }
}

public enum MLCSoftmaxOperation: Int32, Hashable, Sendable {
    case softmax = 0
    case logSoftmax = 1

    public var debugDescription: String {
        String(describing: self)
    }
}

public enum MLCPoolingType: Equatable, Sendable {
    case max
    case l2Norm
    case average(countIncludesPadding: Bool = false)

    public var debugDescription: String {
        switch self {
        case .max: return "max"
        case .l2Norm: return "l2Norm"
        case .average(let includes):
            return "average(countIncludesPadding: \(includes))"
        }
    }
}

public enum MLCPaddingPolicy: Equatable, Sendable {
    case same
    case valid
    case sized(y: Int, x: Int)

    public var debugDescription: String {
        switch self {
        case .same: return "same"
        case .valid: return "valid"
        case .sized(let y, let x): return "sized(y: \(y), x: \(x))"
        }
    }
}

enum MLCActivationDefaults {
    static let seluA: Float = 1.6732632
    static let seluB: Float = 1.050701

    static func parameters(for type: MLCActivationType) -> (Float, Float, Float) {
        switch type {
        case .none, .relu, .sigmoid, .tanh, .absolute, .softSign, .logSigmoid, .tanhShrink, .gelu, .hardSwish:
            return (0, 0, 0)
        case .linear:
            return (1, 0, 0)
        case .hardSigmoid:
            return (0.2, 0.5, 0)
        case .softPlus:
            return (1, 0, 0)
        case .elu, .celu:
            return (1, 0, 0)
        case .relun:
            return (6, 0, 0)
        case .selu:
            return (seluA, seluB, 0)
        case .hardShrink, .softShrink:
            return (0.5, 0, 0)
        case .threshold:
            return (0, 0, 0)
        case .clamp:
            return (0, 1, 0)
        }
    }
}

func mlcApplyActivation(type: MLCActivationType, a: Float, b: Float, c: Float, x: Float) -> Float {
    switch type {
    case .none:
        return x
    case .relu:
        return x > 0 ? x : a * x
    case .linear:
        return a * x + b
    case .sigmoid:
        return 1 / (1 + exp(-x))
    case .hardSigmoid:
        return min(max(a * x + b, 0), 1)
    case .tanh:
        return Foundation.tanh(x)
    case .absolute:
        return abs(x)
    case .softPlus:
        return a == 0 ? max(x, 0) : (1 / a) * log(1 + exp(a * x))
    case .softSign:
        return x / (1 + abs(x))
    case .elu:
        return x > 0 ? x : a * (exp(x) - 1)
    case .relun:
        return min(a, max(b, x))
    case .logSigmoid:
        return -log(1 + exp(-x))
    case .selu:
        return x > 0 ? b * x : b * a * (exp(x) - 1)
    case .celu:
        let denom = a == 0 ? 1 : a
        return x >= 0 ? x : denom * (exp(x / denom) - 1)
    case .hardShrink:
        return abs(x) > a ? x : 0
    case .softShrink:
        if x > a { return x - a }
        if x < -a { return x + a }
        return 0
    case .tanhShrink:
        return x - Foundation.tanh(x)
    case .threshold:
        return x > a ? x : b
    case .gelu:
        return 0.5 * x * (1 + Foundation.tanh(0.79788456 * (x + 0.044715 * x * x * x)))
    case .hardSwish:
        return x * min(max(x + 3, 0), 6) / 6
    case .clamp:
        return min(max(x, a), b)
    }
}

func mlcApplyArithmetic(_ op: MLCArithmeticOperation, lhs: Float, rhs: Float) -> Float {
    switch op {
    case .add: return lhs + rhs
    case .subtract: return lhs - rhs
    case .multiply: return lhs * rhs
    case .divide: return rhs == 0 ? Float.nan : lhs / rhs
    case .floor: return Foundation.floor(lhs)
    case .round: return Foundation.round(lhs)
    case .ceil: return Foundation.ceil(lhs)
    case .sqrt: return Foundation.sqrt(lhs)
    case .rsqrt: return lhs == 0 ? Float.infinity : 1 / Foundation.sqrt(lhs)
    case .sin: return Foundation.sin(lhs)
    case .cos: return Foundation.cos(lhs)
    case .tan: return Foundation.tan(lhs)
    case .asin: return Foundation.asin(lhs)
    case .acos: return Foundation.acos(lhs)
    case .atan: return Foundation.atan(lhs)
    case .sinh: return Foundation.sinh(lhs)
    case .cosh: return Foundation.cosh(lhs)
    case .tanh: return Foundation.tanh(lhs)
    case .asinh: return Foundation.asinh(lhs)
    case .acosh: return Foundation.acosh(lhs)
    case .atanh: return Foundation.atanh(lhs)
    case .pow: return Foundation.pow(lhs, rhs)
    case .exp: return Foundation.exp(lhs)
    case .exp2: return Foundation.exp2(lhs)
    case .log: return Foundation.log(lhs)
    case .log2: return Foundation.log2(lhs)
    case .multiplyNoNaN:
        if lhs.isNaN || rhs.isNaN { return 0 }
        return lhs * rhs
    case .divideNoNaN:
        if rhs == 0 || lhs.isNaN || rhs.isNaN { return 0 }
        return lhs / rhs
    case .min: return Swift.min(lhs, rhs)
    case .max: return Swift.max(lhs, rhs)
    }
}
