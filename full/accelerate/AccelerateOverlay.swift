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
    }
    public enum DCTTransformType {
        case II
        case IV
        case III
        public typealias AllCases = [vDSP.DCTTransformType]
        public var dctType: vDSP_DCT_Type { preconditionFailure("Accelerate Linux: unread property") }
        public nonisolated static var allCases: [vDSP.DCTTransformType] { preconditionFailure("Accelerate Linux: unread property") }
    }
    public class DFT<T> where T : vDSP_FloatingPointDiscreteFourierTransformable {
    }
    public struct DFTDoublePrecisionInterleavedFunctions {
    }
    public struct DFTDoublePrecisionSplitComplexFunctions {
    }
    public enum DFTError {
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
    }
    public class FFT<T> where T : vDSP_FourierTransformable {
    }
    public class FFT2D<T>: FFT<T> where T : vDSP_FourierTransformable {
    }
    public enum FourierTransformDirection {
        case forward
        case inverse
        public var dftDirection: vDSP_DFT_Direction { preconditionFailure("Accelerate Linux: unread property") }
        public var fftDirection: FFTDirection { preconditionFailure("Accelerate Linux: unread property") }
    }
    public enum IntegrationRule {
        case runningSum
        case trapezoidal
        case simpson
    }
    public enum Radix {
        case radix2
        case radix3
        case radix5
        public var fftRadix: FFTRadix { preconditionFailure("Accelerate Linux: unread property") }
    }
    public enum RoundingMode {
        case towardZero
        case towardNearestInteger
    }
    public enum SortOrder {
        case descending
        public typealias RawValue = Int32
        case ascending
        public var rawValue: Int32 { preconditionFailure("Accelerate Linux: unread property") }
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
    public enum WindowSequence {
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
        public static var gaussian1Dx3: [Float] { preconditionFailure("Accelerate Linux: unread property") }
        public static var gaussian1Dx5: [Float] { preconditionFailure("Accelerate Linux: unread property") }
        public static var gaussian1Dx7: [Float] { preconditionFailure("Accelerate Linux: unread property") }
    }
    public struct ConvolutionKernel2D<ComponentType> {
        public var width: vImagePixelCount {
            get { preconditionFailure("Accelerate Linux: unread property") }
            set { _ = newValue }
        }
        public var height: vImagePixelCount {
            get { preconditionFailure("Accelerate Linux: unread property") }
            set { _ = newValue }
        }
        public var values: [ComponentType] {
            get { preconditionFailure("Accelerate Linux: unread property") }
            set { _ = newValue }
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
    public enum Error {
        case memoryAllocationError
        case noError
        case invalidImageFormat
        case invalidImageObject
        case internalError
        case invalidOffset_X
        case invalidOffset_Y
        case invalidRowBytes
        case unknownFlagsBit
        case invalidEdgeStyle
        case invalidParameter
        case colorSyncIsAbsent
        case coreVideoIsAbsent
        case invalidKernelSize
        case bufferSizeMismatch
        case nullPointerArgument
        case invalidCVImageFormat
        case unsupportedConversion
        case roiLargerThanInputBuffer
        case outOfPlaceOperationRequired
        public typealias RawValue = Int
        public var rawValue: Int { preconditionFailure("Accelerate Linux: unread property") }
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
        public static var channelCount: Int { preconditionFailure("Accelerate Linux: unread property") }
        public static var bitCountPerPixel: Int { preconditionFailure("Accelerate Linux: unread property") }
    }
    public struct Interleaved16Fx4 {
        public typealias ComponentType = Pixel_16F
        public static var channelCount: Int { preconditionFailure("Accelerate Linux: unread property") }
        public static var bitCountPerPixel: Int { preconditionFailure("Accelerate Linux: unread property") }
        public static var bitCountPerComponent: Int { preconditionFailure("Accelerate Linux: unread property") }
    }
    public struct Interleaved16Ux2 {
        public typealias ComponentType = Pixel_16U
        public static var channelCount: Int { preconditionFailure("Accelerate Linux: unread property") }
        public static var bitCountPerPixel: Int { preconditionFailure("Accelerate Linux: unread property") }
        public static var bitCountPerComponent: Int { preconditionFailure("Accelerate Linux: unread property") }
    }
    public struct Interleaved16Ux4 {
        public typealias ComponentType = Pixel_16U
        public static var channelCount: Int { preconditionFailure("Accelerate Linux: unread property") }
        public static var bitCountPerPixel: Int { preconditionFailure("Accelerate Linux: unread property") }
        public static var bitCountPerComponent: Int { preconditionFailure("Accelerate Linux: unread property") }
    }
    public struct Interleaved8x2 {
        public typealias ComponentType = Pixel_8
        public static var channelCount: Int { preconditionFailure("Accelerate Linux: unread property") }
        public static var bitCountPerPixel: Int { preconditionFailure("Accelerate Linux: unread property") }
    }
    public struct Interleaved8x3 {
        public typealias ComponentType = Pixel_8
        public static var channelCount: Int { preconditionFailure("Accelerate Linux: unread property") }
        public static var bitCountPerPixel: Int { preconditionFailure("Accelerate Linux: unread property") }
        public static var bitCountPerComponent: Int { preconditionFailure("Accelerate Linux: unread property") }
    }
    public struct Interleaved8x4 {
        public typealias ComponentType = Pixel_8
        public static var channelCount: Int { preconditionFailure("Accelerate Linux: unread property") }
        public static var bitCountPerPixel: Int { preconditionFailure("Accelerate Linux: unread property") }
        public static var bitCountPerComponent: Int { preconditionFailure("Accelerate Linux: unread property") }
    }
    public struct InterleavedFx2 {
        public typealias ComponentType = Pixel_F
        public static var channelCount: Int { preconditionFailure("Accelerate Linux: unread property") }
        public static var bitCountPerPixel: Int { preconditionFailure("Accelerate Linux: unread property") }
    }
    public struct InterleavedFx3 {
        public typealias ComponentType = Pixel_F
        public static var channelCount: Int { preconditionFailure("Accelerate Linux: unread property") }
        public static var bitCountPerPixel: Int { preconditionFailure("Accelerate Linux: unread property") }
        public static var bitCountPerComponent: Int { preconditionFailure("Accelerate Linux: unread property") }
    }
    public struct InterleavedFx4 {
        public typealias ComponentType = Pixel_F
        public static var channelCount: Int { preconditionFailure("Accelerate Linux: unread property") }
        public static var bitCountPerPixel: Int { preconditionFailure("Accelerate Linux: unread property") }
        public static var bitCountPerComponent: Int { preconditionFailure("Accelerate Linux: unread property") }
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
    public struct Options {
        public typealias ArrayLiteralElement = vImage.Options
        public typealias Element = vImage.Options
        public typealias RawValue = vImage_Flags
        public static var doNotClamp: vImage.Options { preconditionFailure("Accelerate Linux: unread property") }
        public static var hdrContent: vImage.Options { preconditionFailure("Accelerate Linux: unread property") }
        public static var noAllocate: vImage.Options { preconditionFailure("Accelerate Linux: unread property") }
        public static var copyInPlace: vImage.Options { preconditionFailure("Accelerate Linux: unread property") }
        public static var imageExtend: vImage.Options { preconditionFailure("Accelerate Linux: unread property") }
        public static var truncateKernel: vImage.Options { preconditionFailure("Accelerate Linux: unread property") }
        public static var getTempBufferSize: vImage.Options { preconditionFailure("Accelerate Linux: unread property") }
        public static var backgroundColorFill: vImage.Options { preconditionFailure("Accelerate Linux: unread property") }
        public static var leaveAlphaUnchanged: vImage.Options { preconditionFailure("Accelerate Linux: unread property") }
        public static var highQualityResampling: vImage.Options { preconditionFailure("Accelerate Linux: unread property") }
        public static var printDiagnosticsToConsole: vImage.Options { preconditionFailure("Accelerate Linux: unread property") }
        public var flags: vImage_Flags { preconditionFailure("Accelerate Linux: unread property") }
        public static var noFlags: vImage.Options { preconditionFailure("Accelerate Linux: unread property") }
        public var rawValue: vImage_Flags {
            get { preconditionFailure("Accelerate Linux: unread property") }
            set { _ = newValue }
        }
        public static var doNotTile: vImage.Options { preconditionFailure("Accelerate Linux: unread property") }
    }
    public struct PixelBuffer<Format> where Format : PixelFormat {
        public typealias Element = Format.ComponentType
        public typealias HistogramFFF = (binCount: Int, [vImagePixelCount], [vImagePixelCount], [vImagePixelCount])
        public typealias HistogramFFFF = (binCount: Int, [vImagePixelCount], [vImagePixelCount], [vImagePixelCount], [vImagePixelCount])
        public typealias Histogram888 = ([vImagePixelCount], [vImagePixelCount], [vImagePixelCount])
        public typealias Histogram8888 = ([vImagePixelCount], [vImagePixelCount], [vImagePixelCount], [vImagePixelCount])
        public var size: vImage.Size { preconditionFailure("Accelerate Linux: unread property") }
        public var width: Int { preconditionFailure("Accelerate Linux: unread property") }
        public var height: Int { preconditionFailure("Accelerate Linux: unread property") }
        public var byteCountPerPixel: Int { preconditionFailure("Accelerate Linux: unread property") }
        public var bytesPerRow: Int { preconditionFailure("Accelerate Linux: unread property") }
        public var columnCount: Int { preconditionFailure("Accelerate Linux: unread property") }
        public var channelCount: Int { preconditionFailure("Accelerate Linux: unread property") }
        public var leadingDimension: Int { preconditionFailure("Accelerate Linux: unread property") }
        public var accelerateMatrixOrder: AccelerateMatrixOrder { preconditionFailure("Accelerate Linux: unread property") }
        public var array: [Format.ComponentType] { preconditionFailure("Accelerate Linux: unread property") }
        public var count: Int { preconditionFailure("Accelerate Linux: unread property") }
        public var rowCount: Int { preconditionFailure("Accelerate Linux: unread property") }
        public var rowStride: Int { preconditionFailure("Accelerate Linux: unread property") }
    }
    public struct Planar16F {
        public typealias ComponentType = Pixel_16F
        public static var channelCount: Int { preconditionFailure("Accelerate Linux: unread property") }
        public static var bitCountPerPixel: Int { preconditionFailure("Accelerate Linux: unread property") }
        public static var bitCountPerComponent: Int { preconditionFailure("Accelerate Linux: unread property") }
    }
    public struct Planar16U {
        public typealias ComponentType = Pixel_16U
        public static var channelCount: Int { preconditionFailure("Accelerate Linux: unread property") }
        public static var bitCountPerPixel: Int { preconditionFailure("Accelerate Linux: unread property") }
    }
    public struct Planar8 {
        public typealias ComponentType = Pixel_8
        public static var channelCount: Int { preconditionFailure("Accelerate Linux: unread property") }
        public static var bitCountPerPixel: Int { preconditionFailure("Accelerate Linux: unread property") }
        public static var bitCountPerComponent: Int { preconditionFailure("Accelerate Linux: unread property") }
    }
    public struct Planar8x2 {
        public typealias ComponentType = Pixel_8
        public typealias PlanarPixelFormat = vImage.Planar8
        public static var planeCount: Int { preconditionFailure("Accelerate Linux: unread property") }
        public static var bitCountPerPlanarPixel: Int { preconditionFailure("Accelerate Linux: unread property") }
    }
    public struct Planar8x3 {
        public typealias ComponentType = Pixel_8
        public typealias PlanarPixelFormat = vImage.Planar8
        public static var planeCount: Int { preconditionFailure("Accelerate Linux: unread property") }
        public static var bitCountPerPlanarPixel: Int { preconditionFailure("Accelerate Linux: unread property") }
    }
    public struct Planar8x4 {
        public typealias ComponentType = Pixel_8
        public typealias PlanarPixelFormat = vImage.Planar8
        public static var planeCount: Int { preconditionFailure("Accelerate Linux: unread property") }
        public static var bitCountPerPlanarPixel: Int { preconditionFailure("Accelerate Linux: unread property") }
    }
    public struct PlanarF {
        public typealias ComponentType = Pixel_F
        public static var channelCount: Int { preconditionFailure("Accelerate Linux: unread property") }
        public static var bitCountPerPixel: Int { preconditionFailure("Accelerate Linux: unread property") }
        public static var bitCountPerComponent: Int { preconditionFailure("Accelerate Linux: unread property") }
    }
    public struct PlanarFx2 {
        public typealias PlanarPixelFormat = vImage.PlanarF
        public typealias ComponentType = Pixel_F
        public static var bitCountPerPlanarPixel: Int { preconditionFailure("Accelerate Linux: unread property") }
        public static var planeCount: Int { preconditionFailure("Accelerate Linux: unread property") }
    }
    public struct PlanarFx3 {
        public typealias PlanarPixelFormat = vImage.PlanarF
        public typealias ComponentType = Pixel_F
        public static var bitCountPerPlanarPixel: Int { preconditionFailure("Accelerate Linux: unread property") }
        public static var planeCount: Int { preconditionFailure("Accelerate Linux: unread property") }
    }
    public struct PlanarFx4 {
        public typealias PlanarPixelFormat = vImage.PlanarF
        public typealias ComponentType = Pixel_F
        public static var bitCountPerPlanarPixel: Int { preconditionFailure("Accelerate Linux: unread property") }
        public static var planeCount: Int { preconditionFailure("Accelerate Linux: unread property") }
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
    public struct Size {
        public var width: Int {
            get { preconditionFailure("Accelerate Linux: unread property") }
            set { _ = newValue }
        }
        public var height: Int {
            get { preconditionFailure("Accelerate Linux: unread property") }
            set { _ = newValue }
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
