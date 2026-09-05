import Accelerate
import Foundation

func testBNNSEnumCases() {
    let activations: [BNNS.ActivationFunction] = [
        .hardShrink(alpha: 1), .logSigmoid, .logSoftmax, .scaledTanh(alpha: 1, beta: 1),
        .softShrink(alpha: 1), .tanhShrink, .hardSigmoid(alpha: 1, beta: 1),
        .linearWithBias(alpha: 1, beta: 1), .rectifiedLinear, .geluApproximation(alpha: 1, beta: 1),
        .geluApproximation2(alpha: 1, beta: 1), .leakyRectifiedLinear(alpha: 0.1),
        .clampedLeakyRectifiedLinear(alpha: 0.1, beta: 1), .abs, .elu(alpha: 1), .celu(alpha: 1),
        .selu, .silu, .tanh, .clamp(bounds: 0...1), .gumbel(alpha: 1, beta: 1), .linear(alpha: 1),
        .sigmoid, .softmax, .identity, .softplus(alpha: 1, beta: 1), .softsign,
        .gumbelMax(alpha: 1, beta: 1), .hardSwish(alpha: 1, beta: 1), .threshold(alpha: 1, beta: 1)
    ]
    precondition(activations.count == 30)
    _ = BNNS.ArithmeticBinaryFunction.add
    _ = BNNS.ArithmeticBinaryFunction.subtract
    _ = BNNS.ArithmeticBinaryFunction.multiply
    _ = BNNS.ArithmeticBinaryFunction.divide
    _ = BNNS.ArithmeticBinaryFunction.max
    _ = BNNS.ArithmeticBinaryFunction.min
    _ = BNNS.ArithmeticBinaryFunction.pow
    _ = BNNS.ArithmeticBinaryFunction.divideNoNaN
    _ = BNNS.ArithmeticBinaryFunction.multiplyNoNaN
    _ = BNNS.ArithmeticBinaryFunction.flooringDivide
    _ = BNNS.ArithmeticBinaryFunction.truncatingDivide
    _ = BNNS.ArithmeticBinaryFunction.truncatingRemainder
    _ = BNNS.ArithmeticTernaryFunction.multiplyAdd
    _ = BNNS.ArithmeticUnaryFunction.reciprocal
    _ = BNNS.ArithmeticUnaryFunction.squareRoot
    _ = BNNS.ArithmeticUnaryFunction.reciprocalSquareRoot
    _ = BNNS.ArithmeticUnaryFunction.abs
    _ = BNNS.ArithmeticUnaryFunction.cos
    _ = BNNS.ArithmeticUnaryFunction.erf
    _ = BNNS.ArithmeticUnaryFunction.exp
    _ = BNNS.ArithmeticUnaryFunction.log
    _ = BNNS.ArithmeticUnaryFunction.sin
    _ = BNNS.ArithmeticUnaryFunction.tan
    _ = BNNS.ArithmeticUnaryFunction.acos
    _ = BNNS.ArithmeticUnaryFunction.asin
    _ = BNNS.ArithmeticUnaryFunction.atan
    _ = BNNS.ArithmeticUnaryFunction.ceil
    _ = BNNS.ArithmeticUnaryFunction.cosh
    _ = BNNS.ArithmeticUnaryFunction.exp2
    _ = BNNS.ArithmeticUnaryFunction.log2
    _ = BNNS.ArithmeticUnaryFunction.sign
    _ = BNNS.ArithmeticUnaryFunction.sinh
    _ = BNNS.ArithmeticUnaryFunction.tanh
    _ = BNNS.ArithmeticUnaryFunction.acosh
    _ = BNNS.ArithmeticUnaryFunction.asinh
    _ = BNNS.ArithmeticUnaryFunction.atanh
    _ = BNNS.ArithmeticUnaryFunction.floor
    _ = BNNS.ArithmeticUnaryFunction.round
    _ = BNNS.ArithmeticUnaryFunction.negate
    _ = BNNS.ArithmeticUnaryFunction.square
    _ = BNNS.ConvolutionPadding.asymmetric(left: 0, right: 0, up: 0, down: 0)
    _ = BNNS.ConvolutionPadding.symmetric(x: 0, y: 0)
    _ = BNNS.ConvolutionType.transposed
    _ = BNNS.ConvolutionType.standard
    _ = BNNS.CropResizeLayer.BoxCoordinateMode.cornersWidthFirst
    _ = BNNS.CropResizeLayer.BoxCoordinateMode.cornersHeightFirst
    _ = BNNS.CropResizeLayer.BoxCoordinateMode.centerSizeWidthFirst
    _ = BNNS.CropResizeLayer.BoxCoordinateMode.centerSizeHeightFirst
    _ = BNNS.CropResizeLayer.LinearSamplingMode.alignCorners
    _ = BNNS.CropResizeLayer.LinearSamplingMode.offsetCorners
    _ = BNNS.CropResizeLayer.LinearSamplingMode.unalignCorners
    _ = BNNS.CropResizeLayer.LinearSamplingMode.strictAlignCorners
    _ = BNNS.CropResizeLayer.LinearSamplingMode.default
    _ = BNNS.DataLayout.vector
    _ = BNNS.DataLayout.imageCHW
    _ = BNNS.DataLayout.matrixRowMajor
    _ = BNNS.DataLayout.matrixColumnMajor
    _ = BNNS.DescriptorType.sample
    _ = BNNS.DescriptorType.constant
    _ = BNNS.DescriptorType.parameter
    _ = BNNS.Error.layerApplyFail
    _ = BNNS.Error.optimizerStepFail
    _ = BNNS.Error.unableToCreateLayer
    _ = BNNS.Error.arrayDescriptorInvalidData
    _ = AccelerateMatrixOrder.rowMajor
    _ = AccelerateMatrixOrder.columnMajor
    _ = Quadrature.Error.invalidArgument
    _ = Quadrature.Error.integrateMaxEval
    _ = Quadrature.Error.badIntegrandBehaviour
    _ = Quadrature.Error.generic
    _ = Quadrature.Error.internal
    _ = Quadrature.Integrator.qng
    _ = BNNSGraph.Error.unableToExecute
    _ = BNNSGraph.Error.unableToCreateGraph
    _ = BNNSGraph.Error.unableToCreateContext
    _ = BNNSGraph.Error.unableToSetDynamicShapes
    _ = vImage.BlendMode.darken
    _ = vImage.BlendMode.screen
    _ = vImage.BlendMode.lighten
    _ = vImage.BlendMode.multiply
    _ = vImage.ChannelOrdering.ARGB
    _ = vImage.ChannelOrdering.RGBA
    _ = vImage.FloodFillConnectivity.edges
    _ = vImage.FloodFillConnectivity.edgesAndCorners
    _ = vImage.Gamma.sRGBForwardHalfPrecision
    _ = vImage.Gamma.sRGBReverseHalfPrecision
    _ = vImage.Gamma.bt709ForwardHalfPrecision
    _ = vImage.Gamma.bt709ReverseHalfPrecision
    _ = vImage.ReflectionAxis.horizontal
    _ = vImage.ReflectionAxis.vertical
    _ = vImage.ShearDirection.horizontal
    _ = vImage.ShearDirection.vertical
    _ = vImage.Rotation.clockwise0Degrees
    _ = vImage.Rotation.clockwise90Degrees
    _ = vImage.Rotation.clockwise180Degrees
    _ = vImage.Rotation.clockwise270Degrees
    _ = vImage.BufferType.alpha
    _ = vImage.BufferType.rgbRed
    _ = BNNS.DataLayout.tensor3DNSE
    _ = BNNS.DataLayout.tensor3DSNE
    _ = BNNS.DataLayout.matrixLastMajor
    _ = BNNS.DataLayout.matrixFirstMajor
    _ = BNNS.DataLayout.tensor3DLastMajor
    _ = BNNS.DataLayout.tensor4DLastMajor
    _ = BNNS.DataLayout.tensor5DLastMajor
    _ = BNNS.DataLayout.tensor6DLastMajor
    _ = BNNS.DataLayout.tensor7DLastMajor
    _ = BNNS.DataLayout.tensor8DLastMajor
    _ = BNNS.DataLayout.tensor3DFirstMajor
    _ = BNNS.DataLayout.tensor4DFirstMajor
    _ = BNNS.DataLayout.tensor5DFirstMajor
    _ = BNNS.DataLayout.tensor6DFirstMajor
    _ = BNNS.DataLayout.tensor7DFirstMajor
    _ = BNNS.DataLayout.tensor8DFirstMajor
    _ = BNNS.DataLayout.convolutionWeightsOIHW
    _ = BNNS.Shape.vector(4)
    _ = BNNS.Shape.imageCHW(1, 2, 3)
    _ = BNNS.Shape.matrixRowMajor(2, 2)
    _ = BNNS.Shape.matrixColumnMajor(2, 2)
    _ = BNNS.Shape.matrixLastMajor(2, 2)
    _ = BNNS.Shape.matrixFirstMajor(2, 2)
    _ = BNNS.Shape.tensor3DNSE(1, 2, 3)
    _ = BNNS.Shape.tensor3DSNE(1, 2, 3)
    _ = BNNS.ShuffleType.depthToSpaceNCHW
    _ = BNNS.ShuffleType.spaceToDepthNCHW
    _ = BNNS.SparsityType.unstructured
    _ = BNNS.GradientClipping.none
    _ = BNNS.GradientClipping.byNorm(threshold: 1)
    _ = BNNS.GradientClipping.byValue(bounds: 0...1)
    _ = BNNS.InterpolationMethod.nearestNeighbor
    _ = BNNS.InterpolationMethod.linear
    _ = BNNS.LearningPhase.training
    _ = BNNS.LearningPhase.inference
    _ = BNNS.LossFunction.cosineDistance
    _ = BNNS.LossFunction.meanSquareError
    _ = BNNS.LossFunction.hinge
    _ = BNNS.LossReduction.none
    _ = BNNS.LossReduction.sum
    _ = BNNS.NormalizationType.group(groupCount: 1)
    _ = BNNS.PaddingMode.reflect
    _ = BNNS.PaddingMode.symmetric
    _ = BNNS.PoolingType.max(indices: nil)
    _ = BNNS.ReductionFunction.max
    _ = BNNS.ReductionFunction.min
    _ = BNNS.ReductionFunction.sum
    _ = BNNS.ReductionFunction.mean
    _ = BNNSGraph.Builder.Activation.relu
    _ = BNNSGraph.Builder.Activation.sigmoid
    _ = BNNSGraph.Builder.PoolingFunction.l2Norm
    _ = BNNSGraph.Error.unableToMakeGraph("x")
    _ = vImage.BufferType.cmykYellow
    _ = vImage.BufferType.monochrome
    _ = vImage.BufferType.cmykMagenta
    _ = vImage.BufferType.coreGraphics
    _ = vImage.BufferType.Cb
    _ = vImage.BufferType.Cr
    _ = vImage.BufferType.labA
    _ = vImage.BufferType.labB
    _ = vImage.BufferType.labL
    _ = vImage.BufferType.xyzX
    _ = vImage.BufferType.xyzY
    _ = vImage.BufferType.xyzZ
    _ = vImage.BufferType.YCbCr
    _ = vImage.BufferType.chroma
    _ = vImage.BufferType.chunky
    _ = vImage.BufferType.indexed
    _ = vImage.BufferType.rgbBlue
    _ = vImage.BufferType.cmykCyan
    _ = vImage.BufferType.rgbGreen
    _ = vImage.BufferType.cmykBlack
    _ = vImage.BufferType.luminance
    _ = vImage.Gamma.fullPrecision(2.2)
    _ = vImage.Gamma.halfPrecision(2.2)
    _ = vImage.Gamma.fiveOverNineHalfPrecision
    _ = vImage.MultidimensionalLookupTable.InterpolationMethod.full
    _ = vImage.Rotation.angleInDegrees(90)
    _ = vImage.Rotation.angleInRadians(1)
    _ = vImage.Rotation.counterClockwise90Degrees
    _ = vImage.CompositeMode<UInt8>.premultiplied
    _ = vImage.EdgeMode<UInt8>.extend
    _ = vImage.EdgeMode<UInt8>.copyInPlace
    _ = vImage.EdgeMode<UInt8>.truncateKernel
    _ = vImage.MorphologyOperation<UInt8>.maximize(kernelSize: vImage.Size(width: 3, height: 3))
    _ = Quadrature.Integrator.qags(maxIntervals: 1)
}

func testEquatableHashable() {
    precondition(vImage.Error.noError == vImage.Error.noError)
    precondition(vImage.Error.noError != vImage.Error.invalidParameter)
    _ = vImage.Error.noError.hashValue
    var hasher = Hasher()
    vImage.Error.noError.hash(into: &hasher)
    precondition(vDSP.Radix.radix2 == .radix2)
    precondition(vDSP.SortOrder.ascending != .descending)
    precondition(vImage.Options.noFlags != .imageExtend)
    precondition(CblasRowMajor == CblasRowMajor)
    precondition(BLAS_THREADING_MULTI_THREADED != BLAS_THREADING_SINGLE_THREADED)
}
