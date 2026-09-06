import Foundation

public struct BLAS {
    public static var threadingModel: BLAS.ThreadingModel {
        get { preconditionFailure("Accelerate Linux: unread property") }
        set { _ = newValue }
    }
    public struct ThreadingModel {
        public typealias RawValue = UInt32
        public static var multiThreaded: BLAS.ThreadingModel { preconditionFailure("Accelerate Linux: unread property") }
        public static var singleThreaded: BLAS.ThreadingModel { preconditionFailure("Accelerate Linux: unread property") }
        public var rawValue: UInt32 {
            get { preconditionFailure("Accelerate Linux: unread property") }
            set { _ = newValue }
        }
    }
}

public enum BNNS {
    public enum ActivationFunction {
        case hardShrink(alpha: Float)
        case logSigmoid
        case logSoftmax
        case scaledTanh(alpha: Float, beta: Float)
        case softShrink(alpha: Float)
        case tanhShrink
        case hardSigmoid(alpha: Float, beta: Float)
        case linearWithBias(alpha: Float, beta: Float)
        case rectifiedLinear
        case geluApproximation(alpha: Float, beta: Float)
        case geluApproximation2(alpha: Float, beta: Float)
        case leakyRectifiedLinear(alpha: Float)
        case clampedLeakyRectifiedLinear(alpha: Float, beta: Float)
        case abs
        case elu(alpha: Float)
        case celu(alpha: Float)
        case selu
        case silu
        case tanh
        case clamp(bounds: ClosedRange<Float>)
        case gumbel(alpha: Float, beta: Float)
        case linear(alpha: Float)
        case sigmoid
        case softmax
        case identity
        case softplus(alpha: Float, beta: Float)
        case softsign
        case gumbelMax(alpha: Float, beta: Float)
        case hardSwish(alpha: Float, beta: Float)
        case threshold(alpha: Float, beta: Float)
        public var bnnsActivation: BNNSActivation { preconditionFailure("Accelerate Linux: unread property") }
    }
    public class ActivationLayer: UnaryLayer {
    }
    public struct AdamOptimizer {
        public var bnnsOptimizerFunction: BNNSOptimizerFunction { preconditionFailure("Accelerate Linux: unread property") }
        public var usesAMSGrad: Bool {
            get { preconditionFailure("Accelerate Linux: unread property") }
            set { _ = newValue }
        }
        public var learningRate: Float {
            get { preconditionFailure("Accelerate Linux: unread property") }
            set { _ = newValue }
        }
        public var gradientScale: Float {
            get { preconditionFailure("Accelerate Linux: unread property") }
            set { _ = newValue }
        }
        public var gradientBounds: ClosedRange<Float>? {
            get { preconditionFailure("Accelerate Linux: unread property") }
            set { _ = newValue }
        }
        public var gradientClipping: BNNS.GradientClipping {
            get { preconditionFailure("Accelerate Linux: unread property") }
            set { _ = newValue }
        }
        public var regularizationScale: Float {
            get { preconditionFailure("Accelerate Linux: unread property") }
            set { _ = newValue }
        }
        public var regularizationFunction: BNNSOptimizerRegularizationFunction {
            get { preconditionFailure("Accelerate Linux: unread property") }
            set { _ = newValue }
        }
        public var accumulatorCountMultiplier: Int { preconditionFailure("Accelerate Linux: unread property") }
        public var beta1: Float {
            get { preconditionFailure("Accelerate Linux: unread property") }
            set { _ = newValue }
        }
        public var beta2: Float {
            get { preconditionFailure("Accelerate Linux: unread property") }
            set { _ = newValue }
        }
        public var epsilon: Float {
            get { preconditionFailure("Accelerate Linux: unread property") }
            set { _ = newValue }
        }
        public var timeStep: Float {
            get { preconditionFailure("Accelerate Linux: unread property") }
            set { _ = newValue }
        }
    }
    public struct AdamWOptimizer {
        public var weightDecay: Float {
            get { preconditionFailure("Accelerate Linux: unread property") }
            set { _ = newValue }
        }
        public var learningRate: Float {
            get { preconditionFailure("Accelerate Linux: unread property") }
            set { _ = newValue }
        }
        public var gradientScale: Float {
            get { preconditionFailure("Accelerate Linux: unread property") }
            set { _ = newValue }
        }
        public var gradientClipping: BNNS.GradientClipping {
            get { preconditionFailure("Accelerate Linux: unread property") }
            set { _ = newValue }
        }
        public var bnnsOptimizerFunction: BNNSOptimizerFunction { preconditionFailure("Accelerate Linux: unread property") }
        public var accumulatorCountMultiplier: Int { preconditionFailure("Accelerate Linux: unread property") }
        public var beta1: Float {
            get { preconditionFailure("Accelerate Linux: unread property") }
            set { _ = newValue }
        }
        public var beta2: Float {
            get { preconditionFailure("Accelerate Linux: unread property") }
            set { _ = newValue }
        }
        public var epsilon: Float {
            get { preconditionFailure("Accelerate Linux: unread property") }
            set { _ = newValue }
        }
        public var timeStep: Float {
            get { preconditionFailure("Accelerate Linux: unread property") }
            set { _ = newValue }
        }
    }
    public enum ArithmeticBinaryFunction {
        case divideNoNaN
        case multiplyNoNaN
        case flooringDivide
        case truncatingDivide
        case truncatingRemainder
        case add
        case max
        case min
        case pow
        case divide
        public typealias AllCases = [BNNS.ArithmeticBinaryFunction]
        case multiply
        case subtract
        public static var allCases: [BNNS.ArithmeticBinaryFunction] { preconditionFailure("Accelerate Linux: unread property") }
    }
    public enum ArithmeticTernaryFunction {
        case multiplyAdd
        public var bnnsArithmeticFunction: BNNSArithmeticFunction { preconditionFailure("Accelerate Linux: unread property") }
    }
    public enum ArithmeticUnaryFunction {
        case reciprocal
        case squareRoot
        case reciprocalSquareRoot
        case abs
        case cos
        case erf
        case exp
        case log
        case sin
        case tan
        case acos
        case asin
        case atan
        case ceil
        case cosh
        case exp2
        case log2
        case sign
        case sinh
        case tanh
        case acosh
        case asinh
        case atanh
        case floor
        case round
        case negate
        case square
        public typealias AllCases = [BNNS.ArithmeticUnaryFunction]
        public var bnnsArithmeticFunction: BNNSArithmeticFunction { preconditionFailure("Accelerate Linux: unread property") }
        public static var allCases: [BNNS.ArithmeticUnaryFunction] { preconditionFailure("Accelerate Linux: unread property") }
    }
    public class BinaryArithmeticLayer: Layer {
    }
    public class BinaryLayer: Layer {
    }
    public class BroadcastMatrixMultiplyLayer: Layer {
    }
    public class ConvolutionLayer: UnaryLayer {
    }
    public enum ConvolutionPadding {
        case asymmetric(left: Int, right: Int, up: Int, down: Int)
        case symmetric(x: Int, y: Int)
        public static var zero: BNNS.ConvolutionPadding { preconditionFailure("Accelerate Linux: unread property") }
    }
    public enum ConvolutionType {
        case transposed
        case standard
    }
    public class CropResizeLayer {
        public enum BoxCoordinateMode {
            case cornersWidthFirst
            case cornersHeightFirst
            case centerSizeWidthFirst
            case centerSizeHeightFirst
        }
        public enum LinearSamplingMode {
            case alignCorners
            case offsetCorners
            case unalignCorners
            case strictAlignCorners
            case `default`
        }
    }
    public enum DataLayout {
        case tensor3DNSE
        case tensor3DSNE
        case matrixRowMajor
        case matrixLastMajor
        case matrixFirstMajor
        case matrixColumnMajor
        case tensor3DLastMajor
        case tensor4DLastMajor
        case tensor5DLastMajor
        case tensor6DLastMajor
        case tensor7DLastMajor
        case tensor8DLastMajor
        case tensor3DFirstMajor
        case tensor4DFirstMajor
        case tensor5DFirstMajor
        case tensor6DFirstMajor
        case tensor7DFirstMajor
        case tensor8DFirstMajor
        case convolutionWeightsOIHW
        case vector
        public typealias AllCases = [BNNS.DataLayout]
        case imageCHW
        public var rank: Int { preconditionFailure("Accelerate Linux: unread property") }
        public static var allCases: [BNNS.DataLayout] { preconditionFailure("Accelerate Linux: unread property") }
    }
    public enum DescriptorType {
        case sample
        case constant
        case parameter
    }
    public class DropoutLayer: UnaryLayer {
    }
    public class EmbeddingLayer: Layer {
    }
    public enum Error {
        case layerApplyFail
        case optimizerStepFail
        case unableToCreateLayer
        case arrayDescriptorInvalidData
    }
    public class FullyConnectedLayer: ConvolutionLayer {
    }
    public struct FusedBinaryArithmeticParameters {
        public var inputADescriptorType: BNNS.DescriptorType {
            get { preconditionFailure("Accelerate Linux: unread property") }
            set { _ = newValue }
        }
        public var inputBDescriptorType: BNNS.DescriptorType {
            get { preconditionFailure("Accelerate Linux: unread property") }
            set { _ = newValue }
        }
        public var outputDescriptorType: BNNS.DescriptorType {
            get { preconditionFailure("Accelerate Linux: unread property") }
            set { _ = newValue }
        }
        public var function: BNNS.ArithmeticBinaryFunction {
            get { preconditionFailure("Accelerate Linux: unread property") }
            set { _ = newValue }
        }
    }
    public class FusedConvolutionNormalizationLayer: FusedLayer {
    }
    public struct FusedConvolutionParameters {
        public var dilationStride: (x: Int, y: Int) {
            get { preconditionFailure("Accelerate Linux: unread property") }
            set { _ = newValue }
        }
        public var bias: BNNSNDArrayDescriptor? {
            get { preconditionFailure("Accelerate Linux: unread property") }
            set { _ = newValue }
        }
        public var type: BNNS.ConvolutionType {
            get { preconditionFailure("Accelerate Linux: unread property") }
            set { _ = newValue }
        }
        public var stride: (x: Int, y: Int) {
            get { preconditionFailure("Accelerate Linux: unread property") }
            set { _ = newValue }
        }
        public var padding: BNNS.ConvolutionPadding {
            get { preconditionFailure("Accelerate Linux: unread property") }
            set { _ = newValue }
        }
        public var weights: BNNSNDArrayDescriptor {
            get { preconditionFailure("Accelerate Linux: unread property") }
            set { _ = newValue }
        }
        public var groupSize: Int {
            get { preconditionFailure("Accelerate Linux: unread property") }
            set { _ = newValue }
        }
    }
    public struct FusedDequantizationParameters {
        public var axis: Int? {
            get { preconditionFailure("Accelerate Linux: unread property") }
            set { _ = newValue }
        }
        public var bias: BNNSNDArrayDescriptor? {
            get { preconditionFailure("Accelerate Linux: unread property") }
            set { _ = newValue }
        }
        public var scale: BNNSNDArrayDescriptor? {
            get { preconditionFailure("Accelerate Linux: unread property") }
            set { _ = newValue }
        }
    }
    public class FusedFullyConnectedNormalizationLayer: FusedLayer {
    }
    public struct FusedFullyConnectedParameters {
        public var bias: BNNSNDArrayDescriptor? {
            get { preconditionFailure("Accelerate Linux: unread property") }
            set { _ = newValue }
        }
        public var weights: BNNSNDArrayDescriptor {
            get { preconditionFailure("Accelerate Linux: unread property") }
            set { _ = newValue }
        }
    }
    public class FusedLayer: Layer {
    }
    public struct FusedNormalizationParameters {
        public var activation: BNNS.ActivationFunction {
            get { preconditionFailure("Accelerate Linux: unread property") }
            set { _ = newValue }
        }
        public var beta: BNNSNDArrayDescriptor? {
            get { preconditionFailure("Accelerate Linux: unread property") }
            set { _ = newValue }
        }
        public var type: BNNS.NormalizationType {
            get { preconditionFailure("Accelerate Linux: unread property") }
            set { _ = newValue }
        }
        public var gamma: BNNSNDArrayDescriptor? {
            get { preconditionFailure("Accelerate Linux: unread property") }
            set { _ = newValue }
        }
        public var epsilon: Float {
            get { preconditionFailure("Accelerate Linux: unread property") }
            set { _ = newValue }
        }
        public var momentum: Float {
            get { preconditionFailure("Accelerate Linux: unread property") }
            set { _ = newValue }
        }
    }
    public class FusedParametersLayer: FusedLayer {
    }
    public struct FusedQuantizationParameters {
        public var axis: Int? {
            get { preconditionFailure("Accelerate Linux: unread property") }
            set { _ = newValue }
        }
        public var bias: BNNSNDArrayDescriptor? {
            get { preconditionFailure("Accelerate Linux: unread property") }
            set { _ = newValue }
        }
        public var scale: BNNSNDArrayDescriptor? {
            get { preconditionFailure("Accelerate Linux: unread property") }
            set { _ = newValue }
        }
    }
    public struct FusedTernaryArithmeticParameters {
        public var inputADescriptorType: BNNS.DescriptorType {
            get { preconditionFailure("Accelerate Linux: unread property") }
            set { _ = newValue }
        }
        public var inputBDescriptorType: BNNS.DescriptorType {
            get { preconditionFailure("Accelerate Linux: unread property") }
            set { _ = newValue }
        }
        public var inputCDescriptorType: BNNS.DescriptorType {
            get { preconditionFailure("Accelerate Linux: unread property") }
            set { _ = newValue }
        }
        public var outputDescriptorType: BNNS.DescriptorType {
            get { preconditionFailure("Accelerate Linux: unread property") }
            set { _ = newValue }
        }
        public var function: BNNS.ArithmeticTernaryFunction {
            get { preconditionFailure("Accelerate Linux: unread property") }
            set { _ = newValue }
        }
    }
    public struct FusedUnaryArithmeticParameters {
        public var inputDescriptorType: BNNS.DescriptorType {
            get { preconditionFailure("Accelerate Linux: unread property") }
            set { _ = newValue }
        }
        public var outputDescriptorType: BNNS.DescriptorType {
            get { preconditionFailure("Accelerate Linux: unread property") }
            set { _ = newValue }
        }
        public var function: BNNS.ArithmeticUnaryFunction {
            get { preconditionFailure("Accelerate Linux: unread property") }
            set { _ = newValue }
        }
    }
    public enum GradientClipping {
        case byGlobalNorm(threshold: Float, globalNorm: Float = 0)
        case none
        case byNorm(threshold: Float)
        case byValue(bounds: ClosedRange<Float>)
    }
    public class GramLayer: UnaryLayer {
    }
    public enum InterpolationMethod {
        case nearestNeighbor
        case linear
    }
    public class Layer {
        public var bnnsFilter: BNNSFilter {
            get { preconditionFailure("Accelerate Linux: unread property") }
            set { _ = newValue }
        }
        public init() {}
    }
    @frozen public enum LearningPhase {
        case training
        case inference
    }
    public enum LossFunction {
        case cosineDistance
        case meanSquareError
        case meanAbsoluteError
        case sigmoidCrossEntropy(labelSmoothing: Float)
        case softmaxCrossEntropy(labelSmoothing: Float)
        case categoricalCrossEntropy
        case log
        case yolo(parameters: BNNS.LossFunction.YoloParameters)
        case hinge
        case huber(huberDelta: Float)
        public var bnnsLossFunction: BNNSLossFunction { preconditionFailure("Accelerate Linux: unread property") }
        public struct YoloParameters {
            public var huberDelta: Float {
                get { preconditionFailure("Accelerate Linux: unread property") }
                set { _ = newValue }
            }
            public var anchorsData: UnsafeMutablePointer<Float> {
                get { preconditionFailure("Accelerate Linux: unread property") }
                set { _ = newValue }
            }
            public var objectScale: Float {
                get { preconditionFailure("Accelerate Linux: unread property") }
                set { _ = newValue }
            }
            public var anchorBoxSize: Int {
                get { preconditionFailure("Accelerate Linux: unread property") }
                set { _ = newValue }
            }
            public var gridRowsCount: Int {
                get { preconditionFailure("Accelerate Linux: unread property") }
                set { _ = newValue }
            }
            public var noObjectScale: Float {
                get { preconditionFailure("Accelerate Linux: unread property") }
                set { _ = newValue }
            }
            public var anchorBoxCount: Int {
                get { preconditionFailure("Accelerate Linux: unread property") }
                set { _ = newValue }
            }
            public var gridColumnCount: Int {
                get { preconditionFailure("Accelerate Linux: unread property") }
                set { _ = newValue }
            }
            public var objectMinimumIoU: Float {
                get { preconditionFailure("Accelerate Linux: unread property") }
                set { _ = newValue }
            }
            public var noObjectMaximumIoU: Float {
                get { preconditionFailure("Accelerate Linux: unread property") }
                set { _ = newValue }
            }
            public var classificationScale: Float {
                get { preconditionFailure("Accelerate Linux: unread property") }
                set { _ = newValue }
            }
            public var rescore: Bool {
                get { preconditionFailure("Accelerate Linux: unread property") }
                set { _ = newValue }
            }
            public var whScale: Float {
                get { preconditionFailure("Accelerate Linux: unread property") }
                set { _ = newValue }
            }
            public var xyScale: Float {
                get { preconditionFailure("Accelerate Linux: unread property") }
                set { _ = newValue }
            }
        }
    }
    public class LossLayer: Layer {
    }
    public enum LossReduction {
        case weightedMean
        case reductionMean
        case zeroWeightMean
        case sum
        case none
        public var bnnsLossReductionFunction: BNNSLossReductionFunction { preconditionFailure("Accelerate Linux: unread property") }
    }
    public struct NearestNeighbors {
    }
    @frozen public struct Norm {
        public static var l1: BNNS.Norm { preconditionFailure("Accelerate Linux: unread property") }
        public static var l2: BNNS.Norm { preconditionFailure("Accelerate Linux: unread property") }
        public static var maximum: BNNS.Norm { preconditionFailure("Accelerate Linux: unread property") }
        public static var taxicab: BNNS.Norm { preconditionFailure("Accelerate Linux: unread property") }
        public var rawValue: Float {
            get { preconditionFailure("Accelerate Linux: unread property") }
            set { _ = newValue }
        }
        public static var euclidean: BNNS.Norm { preconditionFailure("Accelerate Linux: unread property") }
        public static var lInfinity: BNNS.Norm { preconditionFailure("Accelerate Linux: unread property") }
    }
    public class NormalizationLayer: Layer {
    }
    public enum NormalizationType {
        case batch(movingMean: BNNSNDArrayDescriptor?, movingVariance: BNNSNDArrayDescriptor?)
        case group(groupCount: Int)
        case layer(normalizationAxis: Int)
        case instance(movingMean: BNNSNDArrayDescriptor?, movingVariance: BNNSNDArrayDescriptor?)
    }
    public class PaddingLayer: UnaryLayer {
    }
    public enum PaddingMode {
        case constantScalar(Float)
        case constantBitPattern(UInt32)
        case reflect
        case symmetric
        public var bnnsPaddingMode: BNNSPaddingMode { preconditionFailure("Accelerate Linux: unread property") }
        public var paddingBitPattern: UInt32 { preconditionFailure("Accelerate Linux: unread property") }
    }
    public class PermuteLayer: UnaryLayer {
    }
    public class PoolingLayer: Layer {
    }
    public enum PoolingType {
        case max(indices: UnsafeMutableBufferPointer<Int>? = nil, xDilationStride: Int = 0, yDilationStride: Int = 0)
        case maxEx(indicesDescriptor: BNNSNDArrayDescriptor? = nil, xDilationStride: Int = 0, yDilationStride: Int = 0)
        case unMax(indices: UnsafeMutableBufferPointer<Int>? = nil, xDilationStride: Int = 0, yDilationStride: Int = 0)
        case l2Norm
        case average(countIncludesPadding: Bool)
        case unMaxEx(indicesDescriptor: BNNSNDArrayDescriptor, xDilationStride: Int = 0, yDilationStride: Int = 0)
        public var bnnsPoolingFunction: BNNSPoolingFunction { preconditionFailure("Accelerate Linux: unread property") }
    }
    public struct RMSPropOptimizer {
        public var bnnsOptimizerFunction: BNNSOptimizerFunction { preconditionFailure("Accelerate Linux: unread property") }
        public var learningRate: Float {
            get { preconditionFailure("Accelerate Linux: unread property") }
            set { _ = newValue }
        }
        public var gradientScale: Float {
            get { preconditionFailure("Accelerate Linux: unread property") }
            set { _ = newValue }
        }
        public var gradientBounds: ClosedRange<Float>? {
            get { preconditionFailure("Accelerate Linux: unread property") }
            set { _ = newValue }
        }
        public var gradientClipping: BNNS.GradientClipping {
            get { preconditionFailure("Accelerate Linux: unread property") }
            set { _ = newValue }
        }
        public var regularizationScale: Float {
            get { preconditionFailure("Accelerate Linux: unread property") }
            set { _ = newValue }
        }
        public var regularizationFunction: BNNSOptimizerRegularizationFunction {
            get { preconditionFailure("Accelerate Linux: unread property") }
            set { _ = newValue }
        }
        public var accumulatorCountMultiplier: Int { preconditionFailure("Accelerate Linux: unread property") }
        public var alpha: Float {
            get { preconditionFailure("Accelerate Linux: unread property") }
            set { _ = newValue }
        }
        public var epsilon: Float {
            get { preconditionFailure("Accelerate Linux: unread property") }
            set { _ = newValue }
        }
        public var centered: Bool {
            get { preconditionFailure("Accelerate Linux: unread property") }
            set { _ = newValue }
        }
        public var momentum: Float {
            get { preconditionFailure("Accelerate Linux: unread property") }
            set { _ = newValue }
        }
    }
    public class RandomGenerator {
        public var state: BNNS.RandomGeneratorState {
            get { preconditionFailure("Accelerate Linux: unread property") }
            set { _ = newValue }
        }
    }
    public enum RandomGeneratorMethod {
        case aesCtr
    }
    public class RandomGeneratorState {
        public init() {}
    }
    public enum ReductionFunction {
        case logicalAnd
        case meanNonZero
        case sumOfSquares
        case sumOfAbsolutes
        case all
        case any
        case max
        case min
        case sum
        case mean
        case argMax
        case argMin
        case l2Norm
        case product
        case maxIndex
        case minIndex
        case logSumExp
        case logicalOr
        case sumOfLogs(epsilon: Float)
        public var bnnsReduceFunction: BNNSReduceFunction { preconditionFailure("Accelerate Linux: unread property") }
    }
    public class ReductionLayer: UnaryLayer {
    }
    @frozen public struct RelationalOperator {
        public static var greaterEqual: BNNS.RelationalOperator { preconditionFailure("Accelerate Linux: unread property") }
        public static var or: BNNS.RelationalOperator { preconditionFailure("Accelerate Linux: unread property") }
        public static var and: BNNS.RelationalOperator { preconditionFailure("Accelerate Linux: unread property") }
        public static var nor: BNNS.RelationalOperator { preconditionFailure("Accelerate Linux: unread property") }
        public static var not: BNNS.RelationalOperator { preconditionFailure("Accelerate Linux: unread property") }
        public static var xor: BNNS.RelationalOperator { preconditionFailure("Accelerate Linux: unread property") }
        public static var less: BNNS.RelationalOperator { preconditionFailure("Accelerate Linux: unread property") }
        public static var nand: BNNS.RelationalOperator { preconditionFailure("Accelerate Linux: unread property") }
        public static var equal: BNNS.RelationalOperator { preconditionFailure("Accelerate Linux: unread property") }
        public static var greater: BNNS.RelationalOperator { preconditionFailure("Accelerate Linux: unread property") }
        public static var notEqual: BNNS.RelationalOperator { preconditionFailure("Accelerate Linux: unread property") }
        public static var lessEqual: BNNS.RelationalOperator { preconditionFailure("Accelerate Linux: unread property") }
    }
    public class ResizeLayer: UnaryLayer {
    }
    public struct SGDMomentumOptimizer {
        public var bnnsOptimizerFunction: BNNSOptimizerFunction { preconditionFailure("Accelerate Linux: unread property") }
        public var learningRate: Float {
            get { preconditionFailure("Accelerate Linux: unread property") }
            set { _ = newValue }
        }
        public var gradientScale: Float {
            get { preconditionFailure("Accelerate Linux: unread property") }
            set { _ = newValue }
        }
        public var gradientBounds: ClosedRange<Float>? {
            get { preconditionFailure("Accelerate Linux: unread property") }
            set { _ = newValue }
        }
        public var gradientClipping: BNNS.GradientClipping {
            get { preconditionFailure("Accelerate Linux: unread property") }
            set { _ = newValue }
        }
        public var sgdMomentumVariant: BNNSOptimizerSGDMomentumVariant {
            get { preconditionFailure("Accelerate Linux: unread property") }
            set { _ = newValue }
        }
        public var regularizationScale: Float {
            get { preconditionFailure("Accelerate Linux: unread property") }
            set { _ = newValue }
        }
        public var usesNestrovMomentum: Bool {
            get { preconditionFailure("Accelerate Linux: unread property") }
            set { _ = newValue }
        }
        public var usesNesterovMomentum: Bool {
            get { preconditionFailure("Accelerate Linux: unread property") }
            set { _ = newValue }
        }
        public var regularizationFunction: BNNSOptimizerRegularizationFunction {
            get { preconditionFailure("Accelerate Linux: unread property") }
            set { _ = newValue }
        }
        public var accumulatorCountMultiplier: Int { preconditionFailure("Accelerate Linux: unread property") }
        public var momentum: Float {
            get { preconditionFailure("Accelerate Linux: unread property") }
            set { _ = newValue }
        }
    }
    public enum Shape {
        case tensor3DNSE(Int, Int, Int, stride: (Int, Int, Int) = (0, 0, 0))
        case tensor3DSNE(Int, Int, Int, stride: (Int, Int, Int) = (0, 0, 0))
        case matrixRowMajor(Int, Int, stride: (Int, Int) = (0, 0))
        case matrixLastMajor(Int, Int, stride: (Int, Int) = (0, 0))
        case matrixFirstMajor(Int, Int, stride: (Int, Int) = (0, 0))
        case matrixColumnMajor(Int, Int, stride: (Int, Int) = (0, 0))
        case tensor3DLastMajor(Int, Int, Int, stride: (Int, Int, Int) = (0, 0, 0))
        case tensor4DLastMajor(Int, Int, Int, Int, stride: (Int, Int, Int, Int) = (0, 0, 0, 0))
        case tensor5DLastMajor(Int, Int, Int, Int, Int, stride: (Int, Int, Int, Int, Int) = (0, 0, 0, 0, 0))
        case tensor6DLastMajor(Int, Int, Int, Int, Int, Int, stride: (Int, Int, Int, Int, Int, Int) = (0, 0, 0, 0, 0, 0))
        case tensor7DLastMajor(Int, Int, Int, Int, Int, Int, Int, stride: (Int, Int, Int, Int, Int, Int, Int) = (0, 0, 0, 0, 0, 0, 0))
        case tensor8DLastMajor(Int, Int, Int, Int, Int, Int, Int, Int, stride: (Int, Int, Int, Int, Int, Int, Int, Int) = (0, 0, 0, 0, 0, 0, 0, 0))
        case tensor3DFirstMajor(Int, Int, Int, stride: (Int, Int, Int) = (0, 0, 0))
        case tensor4DFirstMajor(Int, Int, Int, Int, stride: (Int, Int, Int, Int) = (0, 0, 0, 0))
        case tensor5DFirstMajor(Int, Int, Int, Int, Int, stride: (Int, Int, Int, Int, Int) = (0, 0, 0, 0, 0))
        case tensor6DFirstMajor(Int, Int, Int, Int, Int, Int, stride: (Int, Int, Int, Int, Int, Int) = (0, 0, 0, 0, 0, 0))
        case tensor7DFirstMajor(Int, Int, Int, Int, Int, Int, Int, stride: (Int, Int, Int, Int, Int, Int, Int) = (0, 0, 0, 0, 0, 0, 0))
        case tensor8DFirstMajor(Int, Int, Int, Int, Int, Int, Int, Int, stride: (Int, Int, Int, Int, Int, Int, Int, Int) = (0, 0, 0, 0, 0, 0, 0, 0))
        public typealias ArrayLiteralElement = Int
        case convolutionWeightsOIHW(Int, Int, Int, Int, stride: (Int, Int, Int, Int) = (0, 0, 0, 0))
        case vector(Int, stride: Int = 0)
        case imageCHW(Int, Int, Int, stride: (Int, Int, Int) = (0, 0, 0))
        public var batchStride: Int { preconditionFailure("Accelerate Linux: unread property") }
        public var rank: Int { preconditionFailure("Accelerate Linux: unread property") }
        public var size: (Int, Int, Int, Int, Int, Int, Int, Int) { preconditionFailure("Accelerate Linux: unread property") }
        public var layout: BNNSDataLayout { preconditionFailure("Accelerate Linux: unread property") }
        public var stride: (Int, Int, Int, Int, Int, Int, Int, Int) { preconditionFailure("Accelerate Linux: unread property") }
    }
    public enum ShuffleType {
        case depthToSpaceNCHW
        case spaceToDepthNCHW
    }
    public enum SparseLayout {
        case coo(indices: BNNSNDArrayDescriptor)
        case csr(columnIndices: BNNSNDArrayDescriptor, rowStarts: BNNSNDArrayDescriptor)
    }
    public struct SparseParameters {
        public var targetSystem: BNNSTargetSystem {
            get { preconditionFailure("Accelerate Linux: unread property") }
            set { _ = newValue }
        }
        public var type: BNNS.SparsityType {
            get { preconditionFailure("Accelerate Linux: unread property") }
            set { _ = newValue }
        }
        public var ratio: (numerator: UInt32, denominator: UInt32) {
            get { preconditionFailure("Accelerate Linux: unread property") }
            set { _ = newValue }
        }
    }
    public enum SparsityType {
        case unstructured
    }
    public class TernaryArithmeticLayer: Layer {
    }
    public class UnaryArithmeticLayer: Layer {
    }
    public class UnaryLayer: Layer {
    }
}

public enum BNNSGraph {
    public struct Builder {
        public typealias PoolingPadding = BNNSGraph.Builder.ConvolutionPadding
        public enum Activation {
            case scaledTanh
            case hardSigmoid
            case relu
            case tanh
            case linear
            case sigmoid
        }
        public enum CeilingMode {
            case floor
            case ceiling
        }
        public enum ConvolutionPadding {
            case same
            case lower
            case valid
            case custom(padding: [Int])
        }
        public enum Direction {
            case forward
            case reverse
        }
        public enum Intent {
            case inputOutput
            case input
        }
        public protocol OperationParameter<Element> {
            associatedtype Element : BNNSScalar
        }
        public enum Padding {
            case reflection
            case replication
            case constant(value: Float)
        }
        public enum PoolingFunction {
            case max
            case l2Norm
            case average(includePadding: Bool)
        }
        public enum ScatterMode {
            case add
            case divide
            case update
            case maximum
            case minimum
            case multiply
            case subtract
        }
        public protocol SliceIndex {
        }
        public struct SliceRange {
            public var startIndex: Int {
                get { preconditionFailure("Accelerate Linux: unread property") }
                set { _ = newValue }
            }
            public static var fillAll: BNNSGraph.Builder.SliceRange { preconditionFailure("Accelerate Linux: unread property") }
            public var endIndex: Int {
                get { preconditionFailure("Accelerate Linux: unread property") }
                set { _ = newValue }
            }
        }
        public enum SortOrder {
            case descending
            case ascending
        }
        public struct Tensor<T> where T : BNNSScalar {
            public typealias Element = T
            public var tensorData: UnsafeMutableRawPointer? { preconditionFailure("Accelerate Linux: unread property") }
            public var description: String { preconditionFailure("Accelerate Linux: unread property") }
            public var rank: Int? { preconditionFailure("Accelerate Linux: unread property") }
            public var shape: [Int]? { preconditionFailure("Accelerate Linux: unread property") }
            public var stride: [Int]? { preconditionFailure("Accelerate Linux: unread property") }
            public var dataType: BNNSDataType? { preconditionFailure("Accelerate Linux: unread property") }
        }
    }
    public struct CompileOptions {
        public var useSingleThread: Bool {
            get { preconditionFailure("Accelerate Linux: unread property") }
            set { _ = newValue }
        }
        public var generateDebugInfo: Bool {
            get { preconditionFailure("Accelerate Linux: unread property") }
            set { _ = newValue }
        }
        public var optimizationPreference: BNNSGraph.CompileOptions.OptimizationPreference {
            get { preconditionFailure("Accelerate Linux: unread property") }
            set { _ = newValue }
        }
        public struct OptimizationPreference {
            public static var performance: BNNSGraph.CompileOptions.OptimizationPreference { preconditionFailure("Accelerate Linux: unread property") }
            public static var internalRepresentationSize: BNNSGraph.CompileOptions.OptimizationPreference { preconditionFailure("Accelerate Linux: unread property") }
        }
    }
    public class Context {
        public var functionCount: Int { preconditionFailure("Accelerate Linux: unread property") }
        public var functionNames: [String] { preconditionFailure("Accelerate Linux: unread property") }
        public var streamingAdvanceCount: Int {
            get { preconditionFailure("Accelerate Linux: unread property") }
            set { _ = newValue }
        }
        public var checkForNaNsAndInfinities: Bool {
            get { preconditionFailure("Accelerate Linux: unread property") }
            set { _ = newValue }
        }
    }
    public enum Error {
        case unableToExecute
        case unableToMakeGraph(String)
        case unableToCreateGraph
        case unableToCreateContext
        case unableToSetDynamicShapes
    }
    public protocol PointerArgument {
        associatedtype Element
        var baseAddress: UnsafeMutablePointer<Self.Element>? { get }
        var count: Int { get }
    }
    public struct Shape {
        public typealias ArrayLiteralElement = Int
        public var dimensions: [Int] { preconditionFailure("Accelerate Linux: unread property") }
    }
    public protocol TensorDescriptor {
        var tensorData: UnsafeMutableRawPointer? { get }
    }
}

public struct Quadrature {
    public var absoluteTolerance: Double {
        get { preconditionFailure("Accelerate Linux: unread property") }
        set { _ = newValue }
    }
    public var relativeTolerance: Double {
        get { preconditionFailure("Accelerate Linux: unread property") }
        set { _ = newValue }
    }
    public enum Error {
        case invalidArgument
        case integrateMaxEval
        case badIntegrandBehaviour
        case generic
        case `internal`
        public var errorDescription: String { preconditionFailure("Accelerate Linux: unread property") }
    }
    public enum Integrator {
        case qag(pointsPerInterval: Quadrature.QAGPointsPerInterval, maxIntervals: Int)
        case qng
        case qags(maxIntervals: Int)
        public static var nonAdaptive: Quadrature.Integrator { preconditionFailure("Accelerate Linux: unread property") }
    }
    public struct QAGPointsPerInterval {
        public var points: Int {
            get { preconditionFailure("Accelerate Linux: unread property") }
            set { _ = newValue }
        }
        public static var fifteen: Quadrature.QAGPointsPerInterval { preconditionFailure("Accelerate Linux: unread property") }
        public static var fiftyOne: Quadrature.QAGPointsPerInterval { preconditionFailure("Accelerate Linux: unread property") }
        public static var fortyOne: Quadrature.QAGPointsPerInterval { preconditionFailure("Accelerate Linux: unread property") }
        public static var sixtyOne: Quadrature.QAGPointsPerInterval { preconditionFailure("Accelerate Linux: unread property") }
        public static var thirtyOne: Quadrature.QAGPointsPerInterval { preconditionFailure("Accelerate Linux: unread property") }
        public static var twentyOne: Quadrature.QAGPointsPerInterval { preconditionFailure("Accelerate Linux: unread property") }
    }
}

public enum vDSP {
    public struct Biquad<T> where T : vDSP_FloatingPointBiquadFilterable {
    }
    public class DCT {
        internal var count: Int = 0
        internal var transformType: vDSP.DCTTransformType = .II
    }
    public enum DCTTransformType: Equatable, Hashable, Sendable {
        case II
        case IV
        case III
        public typealias AllCases = [vDSP.DCTTransformType]
        public var dctType: vDSP_DCT_Type {
            switch self {
            case .II: return .II
            case .III: return .III
            case .IV: return .IV
            }
        }
        public nonisolated static var allCases: [vDSP.DCTTransformType] { [.II, .III, .IV] }
    }
    public class DFT<T> where T : vDSP_FloatingPointDiscreteFourierTransformable {
        internal var count: Int = 0
        internal var inverse: Bool = false
    }
    public struct DFTDoublePrecisionInterleavedFunctions {
    }
    public struct DFTDoublePrecisionSplitComplexFunctions {
    }
    public enum DFTError: Swift.Error {
        case invalidInterleavedCount(count: Int)
        case invalidSplitComplexCount(count: Int, transformType: vDSP.DFTTransformType)
        public var errorDescription: String? { preconditionFailure("Accelerate Linux: unread property") }
    }
    public struct DFTSinglePrecisionInterleavedFunctions {
    }
    public struct DFTSinglePrecisionSplitComplexFunctions {
    }
    public enum DFTTransformType {
        case complexReal
        case complexComplex
    }
    public class DiscreteFourierTransform<T> where T : vDSP_DiscreteFourierTransformable {
        internal var count: Int = 0
        internal var inverse: Bool = false
    }
    public class FFT<T> where T : vDSP_FourierTransformable {
        internal var log2n: vDSP_Length = 0
        internal var setup: OpaquePointer?
    }
    public class FFT2D<T>: FFT<T> where T : vDSP_FourierTransformable {
        internal var width: Int = 0
        internal var height: Int = 0
    }
    public enum FourierTransformDirection: Equatable, Hashable, Sendable {
        case forward
        case inverse
        public var dftDirection: vDSP_DFT_Direction {
            switch self {
            case .forward: return .FORWARD
            case .inverse: return .INVERSE
            }
        }
        public var fftDirection: FFTDirection {
            switch self {
            case .forward: return FFTDirection(FFT_FORWARD)
            case .inverse: return FFTDirection(FFT_INVERSE)
            }
        }
    }
    public enum IntegrationRule: Equatable, Hashable, Sendable {
        case runningSum
        case trapezoidal
        case simpson
    }
    public enum Radix: Equatable, Hashable, Sendable {
        case radix2
        case radix3
        case radix5
        public var fftRadix: FFTRadix {
            switch self {
            case .radix2: return FFTRadix(FFT_RADIX2)
            case .radix3: return FFTRadix(FFT_RADIX3)
            case .radix5: return FFTRadix(FFT_RADIX5)
            }
        }
    }
    public enum RoundingMode: Equatable, Hashable, Sendable {
        case towardZero
        case towardNearestInteger
    }
    public enum SortOrder: Int32, Equatable, Hashable, Sendable {
        case descending = -1
        public typealias RawValue = Int32
        case ascending = 1
    }
    public enum ThresholdRule<T> where T : BinaryFloatingPoint {
        case clampToThreshold
        case signedConstant(T)
        case zeroFill
    }
    public struct VectorizableDouble {
        public typealias Scalar = Double
    }
    public struct VectorizableFloat {
        public typealias Scalar = Float
    }
    public enum WindowSequence: Equatable, Hashable, Sendable {
        case hanningNormalized
        case hanningDenormalized
        case hamming
        case blackman
    }
}

public struct vDSP_SplitComplexDouble {
    public typealias SplitComplex = DSPDoubleSplitComplex
}

public struct vDSP_SplitComplexFloat {
    public typealias SplitComplex = DSPSplitComplex
}

public enum vForce {
}

public enum vImage {
    public typealias StructuringElement = vImage.ConvolutionKernel2D
    public enum BlendMode {
        case darken
        case screen
        case lighten
        case multiply
    }
    public enum BufferType {
        case cmykYellow
        case monochrome
        case cmykMagenta
        case coreGraphics
        case Cb
        case Cr
        case labA
        case labB
        case labL
        case xyzX
        case xyzY
        case xyzZ
        case YCbCr
        case alpha
        case chroma
        case chunky
        case rgbRed
        case indexed
        case rgbBlue
        public typealias RawValue = Int
        case cmykCyan
        case rgbGreen
        case cmykBlack
        case luminance
        public var bufferTypeCode: vImageBufferTypeCode { preconditionFailure("Accelerate Linux: unread property") }
        public var rawValue: Int { preconditionFailure("Accelerate Linux: unread property") }
    }
    public enum ChannelOrdering {
        case ARGB
        case RGBA
    }
    public enum CompositeMode<ComponentType> {
        case premultiplied
        case nonpremultiplied
        case premultipliedWithConstantAlpha(ComponentType)
        case nonpremultipliedToPremultiplied
    }
    public struct ConvolutionKernel {
        public static var gaussian1Dx3: [Float] { [0.25, 0.5, 0.25] }
        public static var gaussian1Dx5: [Float] { [1.0 / 16, 4.0 / 16, 6.0 / 16, 4.0 / 16, 1.0 / 16] }
        public static var gaussian1Dx7: [Float] { [1.0 / 64, 6.0 / 64, 15.0 / 64, 20.0 / 64, 15.0 / 64, 6.0 / 64, 1.0 / 64] }
    }
    public struct ConvolutionKernel2D<ComponentType> {
        public var width: vImagePixelCount
        public var height: vImagePixelCount
        public var values: [ComponentType]
        public init(values: [ComponentType], size: vImage.Size) {
            self.values = values
            self.width = vImagePixelCount(size.width)
            self.height = vImagePixelCount(size.height)
        }
    }
    public struct DynamicPixelFormat {
        public typealias ComponentType = Never
    }
    public enum EdgeMode<PixelType> {
        case copyInPlace
        case truncateKernel
        case fill(backgroundColor: PixelType)
        case extend
    }
    public enum Error: Int, Swift.Error, Equatable, Hashable, Sendable {
        case noError = 0
        case roiLargerThanInputBuffer = -21766
        case invalidKernelSize = -21767
        case invalidEdgeStyle = -21768
        case invalidOffset_X = -21769
        case invalidOffset_Y = -21770
        case memoryAllocationError = -21771
        case nullPointerArgument = -21772
        case invalidParameter = -21773
        case bufferSizeMismatch = -21774
        case unknownFlagsBit = -21775
        case internalError = -21776
        case invalidRowBytes = -21777
        case invalidImageFormat = -21778
        case colorSyncIsAbsent = -21779
        case outOfPlaceOperationRequired = -21780
        case invalidCVImageFormat = -21781
        case unsupportedConversion = -21782
        case coreVideoIsAbsent = -21783
        case invalidImageObject = -21784
        public typealias RawValue = Int
        public init(vImageError: vImage_Error) {
            self = vImage.Error(rawValue: vImageError) ?? .internalError
        }
    }
    public enum FloodFillConnectivity {
        case edgesAndCorners
        case edges
        public typealias RawValue = Int32
        public var rawValue: Int32 { preconditionFailure("Accelerate Linux: unread property") }
    }
    public enum Gamma {
        case fullPrecision(Float)
        case halfPrecision(Float)
        case sRGBForwardHalfPrecision
        case sRGBReverseHalfPrecision
        case bt709ForwardHalfPrecision
        case bt709ReverseHalfPrecision
        case fiveOverNineHalfPrecision
        case nineOverFiveHalfPrecision
        case elevenOverFiveHalfPrecision
        case elevenOverNineHalfPrecision
        case fiveOverElevenHalfPrecision
        case nineOverElevenHalfPrecision
    }
    public struct Interleaved16Fx2 {
        public typealias ComponentType = Pixel_16F
        public static var channelCount: Int { 2 }
        public static var bitCountPerPixel: Int { 32 }
    }
    public struct Interleaved16Fx4 {
        public typealias ComponentType = Pixel_16F
        public static var channelCount: Int { 4 }
        public static var bitCountPerPixel: Int { 64 }
        public static var bitCountPerComponent: Int { 16 }
    }
    public struct Interleaved16Ux2 {
        public typealias ComponentType = Pixel_16U
        public static var channelCount: Int { 2 }
        public static var bitCountPerPixel: Int { 32 }
        public static var bitCountPerComponent: Int { 16 }
    }
    public struct Interleaved16Ux4 {
        public typealias ComponentType = Pixel_16U
        public static var channelCount: Int { 4 }
        public static var bitCountPerPixel: Int { 64 }
        public static var bitCountPerComponent: Int { 16 }
    }
    public struct Interleaved8x2 {
        public typealias ComponentType = Pixel_8
        public static var channelCount: Int { 2 }
        public static var bitCountPerPixel: Int { 16 }
    }
    public struct Interleaved8x3 {
        public typealias ComponentType = Pixel_8
        public static var channelCount: Int { 3 }
        public static var bitCountPerPixel: Int { 24 }
        public static var bitCountPerComponent: Int { 8 }
    }
    public struct Interleaved8x4 {
        public typealias ComponentType = Pixel_8
        public static var channelCount: Int { 4 }
        public static var bitCountPerPixel: Int { 32 }
        public static var bitCountPerComponent: Int { 8 }
    }
    public struct InterleavedFx2 {
        public typealias ComponentType = Pixel_F
        public static var channelCount: Int { 2 }
        public static var bitCountPerPixel: Int { 64 }
    }
    public struct InterleavedFx3 {
        public typealias ComponentType = Pixel_F
        public static var channelCount: Int { 3 }
        public static var bitCountPerPixel: Int { 96 }
        public static var bitCountPerComponent: Int { 32 }
    }
    public struct InterleavedFx4 {
        public typealias ComponentType = Pixel_F
        public static var channelCount: Int { 4 }
        public static var bitCountPerPixel: Int { 128 }
        public static var bitCountPerComponent: Int { 32 }
    }
    public enum MorphologyOperation<ComponentType> {
        case erode(structuringElement: vImage.ConvolutionKernel2D<ComponentType>)
        case dilate(structuringElement: vImage.ConvolutionKernel2D<ComponentType>)
        case maximize(kernelSize: vImage.Size)
        case minimize(kernelSize: vImage.Size)
        public var structuringElement: vImage.ConvolutionKernel2D<ComponentType>? { preconditionFailure("Accelerate Linux: unread property") }
        public var width: vImagePixelCount { preconditionFailure("Accelerate Linux: unread property") }
        public var height: vImagePixelCount { preconditionFailure("Accelerate Linux: unread property") }
    }
    public struct MultidimensionalLookupTable {
        public var sourceChannelCount: Int {
            get { preconditionFailure("Accelerate Linux: unread property") }
            set { _ = newValue }
        }
        public var destinationChannelCount: Int {
            get { preconditionFailure("Accelerate Linux: unread property") }
            set { _ = newValue }
        }
        public var entryCountPerSourceChannel: [UInt8] {
            get { preconditionFailure("Accelerate Linux: unread property") }
            set { _ = newValue }
        }
        public enum InterpolationMethod {
            case full
            case half
            case none
        }
    }
    public struct Options: OptionSet, Hashable, Sendable {
        public typealias ArrayLiteralElement = vImage.Options
        public typealias Element = vImage.Options
        public typealias RawValue = vImage_Flags
        public let rawValue: vImage_Flags
        public var flags: vImage_Flags { rawValue }
        public init(rawValue: vImage_Flags) { self.rawValue = rawValue }
        public static let noFlags = vImage.Options(rawValue: vImage_Flags(kvImageNoFlags))
        public static let leaveAlphaUnchanged = vImage.Options(rawValue: vImage_Flags(kvImageLeaveAlphaUnchanged))
        public static let copyInPlace = vImage.Options(rawValue: vImage_Flags(kvImageCopyInPlace))
        public static let backgroundColorFill = vImage.Options(rawValue: vImage_Flags(kvImageBackgroundColorFill))
        public static let imageExtend = vImage.Options(rawValue: vImage_Flags(kvImageEdgeExtend))
        public static let doNotTile = vImage.Options(rawValue: vImage_Flags(kvImageDoNotTile))
        public static let highQualityResampling = vImage.Options(rawValue: vImage_Flags(kvImageHighQualityResampling))
        public static let truncateKernel = vImage.Options(rawValue: vImage_Flags(kvImageTruncateKernel))
        public static let getTempBufferSize = vImage.Options(rawValue: vImage_Flags(kvImageGetTempBufferSize))
        public static let printDiagnosticsToConsole = vImage.Options(rawValue: vImage_Flags(kvImagePrintDiagnosticsToConsole))
        public static let noAllocate = vImage.Options(rawValue: vImage_Flags(kvImageNoAllocate))
        public static let hdrContent = vImage.Options(rawValue: vImage_Flags(kvImageHDRContent))
        public static let doNotClamp = vImage.Options(rawValue: vImage_Flags(kvImageDoNotClamp))
    }
    public struct PixelBuffer<Format> where Format : PixelFormat {
        public typealias Element = Format.ComponentType
        public typealias HistogramFFF = (binCount: Int, [vImagePixelCount], [vImagePixelCount], [vImagePixelCount])
        public typealias HistogramFFFF = (binCount: Int, [vImagePixelCount], [vImagePixelCount], [vImagePixelCount], [vImagePixelCount])
        public typealias Histogram888 = ([vImagePixelCount], [vImagePixelCount], [vImagePixelCount])
        public typealias Histogram8888 = ([vImagePixelCount], [vImagePixelCount], [vImagePixelCount], [vImagePixelCount])
        public var width: Int
        public var height: Int
        public var rowStride: Int
        var _storageBox: _PixelStorageBox<Format.ComponentType>
        public var storage: [Format.ComponentType] {
            get { _storageBox.values }
            set { _storageBox.values = newValue }
        }
        public var size: vImage.Size { vImage.Size(width: width, height: height) }
        public var byteCountPerPixel: Int { MemoryLayout<Format.ComponentType>.stride }
        public var bytesPerRow: Int { rowStride * byteCountPerPixel }
        public var columnCount: Int { width }
        public var channelCount: Int { Format.channelCount }
        public var leadingDimension: Int { rowStride }
        public var accelerateMatrixOrder: AccelerateMatrixOrder { .rowMajor }
        public var array: [Format.ComponentType] { storage }
        public var count: Int { storage.count }
        public var rowCount: Int { height }
        public var byteCount: Int { storage.count * byteCountPerPixel }
        public var rowByteCount: Int { bytesPerRow }

        public init(pixelValues: [Format.ComponentType], size: vImage.Size, pixelFormat: Format.Type = Format.self) {
            self.width = size.width
            self.height = size.height
            self.rowStride = max(size.width, 0)
            self._storageBox = _PixelStorageBox(pixelValues)
            _ = pixelFormat
        }

        public init<U>(pixelValues: U, size: vImage.Size, pixelFormat: Format.Type = Format.self)
        where U: AccelerateBuffer, Format.ComponentType == U.Element {
            self.width = size.width
            self.height = size.height
            self.rowStride = max(size.width, 0)
            var copied: [Format.ComponentType] = []
            pixelValues.withUnsafeBufferPointer { copied = Array($0) }
            self._storageBox = _PixelStorageBox(copied)
            _ = pixelFormat
        }

        public init(size: vImage.Size, pixelFormat: Format.Type = Format.self)
        where Format.ComponentType: AdditiveArithmetic {
            self.width = size.width
            self.height = size.height
            self.rowStride = max(size.width, 0)
            self._storageBox = _PixelStorageBox(Array(repeating: .zero, count: max(size.width, 0) * max(size.height, 0)))
            _ = pixelFormat
        }

        public init(data: UnsafeMutableRawPointer, width: Int, height: Int, byteCountPerRow: Int, pixelFormat: Format.Type) {
            let pixelBytes = MemoryLayout<Format.ComponentType>.stride
            self.width = width
            self.height = height
            self.rowStride = pixelBytes == 0 ? width : byteCountPerRow / max(pixelBytes, 1)
            let count = max(width, 0) * max(height, 0)
            let typed = data.assumingMemoryBound(to: Format.ComponentType.self)
            self._storageBox = _PixelStorageBox(Array(UnsafeBufferPointer(start: typed, count: count)))
            _ = pixelFormat
        }
    }
    public struct Planar16F {
        public typealias ComponentType = Pixel_16F
        public static var channelCount: Int { 1 }
        public static var bitCountPerPixel: Int { 16 }
        public static var bitCountPerComponent: Int { 16 }
    }
    public struct Planar16U {
        public typealias ComponentType = Pixel_16U
        public static var channelCount: Int { 1 }
        public static var bitCountPerPixel: Int { 16 }
    }
    public struct Planar8 {
        public typealias ComponentType = Pixel_8
        public static var channelCount: Int { 1 }
        public static var bitCountPerPixel: Int { 8 }
        public static var bitCountPerComponent: Int { 8 }
    }
    public struct Planar8x2 {
        public typealias ComponentType = Pixel_8
        public typealias PlanarPixelFormat = vImage.Planar8
        public static var planeCount: Int { 2 }
        public static var bitCountPerPlanarPixel: Int { 8 }
    }
    public struct Planar8x3 {
        public typealias ComponentType = Pixel_8
        public typealias PlanarPixelFormat = vImage.Planar8
        public static var planeCount: Int { 3 }
        public static var bitCountPerPlanarPixel: Int { 8 }
    }
    public struct Planar8x4 {
        public typealias ComponentType = Pixel_8
        public typealias PlanarPixelFormat = vImage.Planar8
        public static var planeCount: Int { 4 }
        public static var bitCountPerPlanarPixel: Int { 8 }
    }
    public struct PlanarF {
        public typealias ComponentType = Pixel_F
        public static var channelCount: Int { 1 }
        public static var bitCountPerPixel: Int { 32 }
        public static var bitCountPerComponent: Int { 32 }
    }
    public struct PlanarFx2 {
        public typealias PlanarPixelFormat = vImage.PlanarF
        public typealias ComponentType = Pixel_F
        public static var bitCountPerPlanarPixel: Int { 32 }
        public static var planeCount: Int { 2 }
    }
    public struct PlanarFx3 {
        public typealias PlanarPixelFormat = vImage.PlanarF
        public typealias ComponentType = Pixel_F
        public static var bitCountPerPlanarPixel: Int { 32 }
        public static var planeCount: Int { 3 }
    }
    public struct PlanarFx4 {
        public typealias PlanarPixelFormat = vImage.PlanarF
        public typealias ComponentType = Pixel_F
        public static var bitCountPerPlanarPixel: Int { 32 }
        public static var planeCount: Int { 4 }
    }
    public enum ReflectionAxis {
        case horizontal
        case vertical
    }
    public enum Rotation {
        case angleInDegrees(Float)
        case angleInRadians(Float)
        case clockwise0Degrees
        case clockwise90Degrees
        case clockwise180Degrees
        case clockwise270Degrees
        case counterClockwise0Degrees
        case counterClockwise90Degrees
        case counterClockwise180Degrees
        case counterClockwise270Degrees
    }
    public enum ShearDirection {
        case horizontal
        case vertical
    }
    public struct Size: Equatable, Hashable, Sendable {
        public let width: Int
        public let height: Int
        public init(width: Int, height: Int) {
            self.width = width
            self.height = height
        }
        public init(width: vImagePixelCount, height: vImagePixelCount) {
            self.width = Int(width)
            self.height = Int(height)
        }
        public init?<T>(exactWidth: T, height: T) where T: BinaryInteger {
            self.init(width: Int(exactWidth), height: Int(height))
        }
        public init?<T>(exactWidth: T, height: T) where T: BinaryFloatingPoint {
            guard let w = Int(exactly: exactWidth), let h = Int(exactly: height) else { return nil }
            self.init(width: w, height: h)
        }
        public init?(exactly size: CGSize) {
            guard let w = Int(exactly: size.width), let h = Int(exactly: size.height) else { return nil }
            self.init(width: w, height: h)
        }
    }
}

public var BNNSDataTypeInt8: BNNSDataType { BNNSDataType(rawValue: 0) }
public var BNNSDataTypeInt16: BNNSDataType { BNNSDataType(rawValue: 0) }
public var BNNSDataTypeInt32: BNNSDataType { BNNSDataType(rawValue: 0) }
public var BNNSDataTypeFloat16: BNNSDataType { BNNSDataType(rawValue: 0) }
public var BNNSDataTypeFloat32: BNNSDataType { BNNSDataType(rawValue: 0) }
public var BNNSDataTypeIndexed8: BNNSDataType { BNNSDataType(rawValue: 0) }
public var BNNSFlagsUseClientPtr: BNNSFlags { BNNSFlags(rawValue: 0) }
public var BNNSPoolingFunctionMax: BNNSPoolingFunction { BNNSPoolingFunction(rawValue: 0) }
public var BNNSActivationFunctionAbs: BNNSActivationFunction { BNNSActivationFunction(rawValue: 0) }
public var BNNSActivationFunctionTanh: BNNSActivationFunction { BNNSActivationFunction(rawValue: 0) }
public var BNNSPoolingFunctionAverage: BNNSPoolingFunction { BNNSPoolingFunction(rawValue: 0) }
public var BNNSActivationFunctionSigmoid: BNNSActivationFunction { BNNSActivationFunction(rawValue: 0) }
public var BNNSActivationFunctionIdentity: BNNSActivationFunction { BNNSActivationFunction(rawValue: 0) }
public var BNNSActivationFunctionScaledTanh: BNNSActivationFunction { BNNSActivationFunction(rawValue: 0) }
public var BNNSActivationFunctionRectifiedLinear: BNNSActivationFunction { BNNSActivationFunction(rawValue: 0) }
public var BNNSActivationFunctionLeakyRectifiedLinear: BNNSActivationFunction { BNNSActivationFunction(rawValue: 0) }
