import Accelerate
import Foundation

func testOverlayHashableBNNS0() {
    _accHashProbe(BNNS.DataLayout.vector, BNNS.DataLayout.imageCHW)
    _accHashProbe(BNNS.ShuffleType.depthToSpaceNCHW, BNNS.ShuffleType.spaceToDepthNCHW)
    let unstructured = BNNS.SparsityType.unstructured
    precondition(unstructured == BNNS.SparsityType.unstructured)
    var hasher = Hasher()
    unstructured.hash(into: &hasher)
    _ = unstructured.hashValue
    _accHashProbe(BNNS.LearningPhase.training, BNNS.LearningPhase.inference)
    _accHashProbe(BNNS.LossReduction.none, BNNS.LossReduction.sum)
    _accHashProbe(BNNS.DescriptorType.sample, BNNS.DescriptorType.parameter)
    _accHashProbe(BNNS.ConvolutionType.standard, BNNS.ConvolutionType.transposed)
    _accHashProbe(BNNS.CropResizeLayer.BoxCoordinateMode.cornersWidthFirst, BNNS.CropResizeLayer.BoxCoordinateMode.cornersHeightFirst)
    _accHashProbe(BNNS.CropResizeLayer.LinearSamplingMode.alignCorners, BNNS.CropResizeLayer.LinearSamplingMode.offsetCorners)
    _accHashProbe(BNNS.InterpolationMethod.nearestNeighbor, BNNS.InterpolationMethod.linear)
    let aes = BNNS.RandomGeneratorMethod.aesCtr
    precondition(aes == BNNS.RandomGeneratorMethod.aesCtr)
    var rh = Hasher()
    aes.hash(into: &rh)
    _ = aes.hashValue
    _accHashProbe(BNNS.ArithmeticUnaryFunction.sin, BNNS.ArithmeticUnaryFunction.cos)
    _accHashProbe(BNNS.ArithmeticBinaryFunction.add, BNNS.ArithmeticBinaryFunction.multiply)
    precondition(BNNS.ArithmeticTernaryFunction.multiplyAdd == BNNS.ArithmeticTernaryFunction.multiplyAdd)
    var th = Hasher(); BNNS.ArithmeticTernaryFunction.multiplyAdd.hash(into: &th); _ = BNNS.ArithmeticTernaryFunction.multiplyAdd.hashValue
}

func testOverlayHashableBNNSErrorNorm() {
    _accHashProbe(BNNS.Error.layerApplyFail, BNNS.Error.optimizerStepFail)
    _ = BNNS.Error.unableToCreateLayer.localizedDescription
    _ = BNNS.Error.arrayDescriptorInvalidData.errorDescription
    _accHashProbe(BNNS.Norm.l1, BNNS.Norm.l2)
    precondition(BNNS.Norm.taxicab == BNNS.Norm.l1)
    precondition(BNNS.Norm.euclidean == BNNS.Norm.l2)
    precondition(BNNS.Norm.lInfinity == BNNS.Norm.maximum)
    _accHashProbe(BNNS.Norm.maximum, BNNS.Norm.l1)
}

func testOverlayHashableVDSP() {
    _accHashProbe(vDSP.RoundingMode.towardZero, vDSP.RoundingMode.towardNearestInteger)
    _accHashProbe(vDSP.WindowSequence.hamming, vDSP.WindowSequence.blackman)
    _accHashProbe(vDSP.IntegrationRule.simpson, vDSP.IntegrationRule.trapezoidal)
    _accHashProbe(vDSP.DCTTransformType.II, vDSP.DCTTransformType.III)
    _accHashProbe(vDSP.DFTTransformType.complexReal, vDSP.DFTTransformType.complexComplex)
    _accHashProbe(vDSP.FourierTransformDirection.forward, vDSP.FourierTransformDirection.inverse)
    _accHashProbe(vDSP.Radix.radix2, vDSP.Radix.radix3)
    _accHashProbe(vDSP.SortOrder.ascending, vDSP.SortOrder.descending)
    _accHashProbe(AccelerateMatrixOrder.rowMajor, AccelerateMatrixOrder.columnMajor)
    let err = vDSP.DFTError.invalidInterleavedCount(count: 3)
    _ = err.errorDescription
    _accHashProbe(err, vDSP.DFTError.invalidSplitComplexCount(count: 4, transformType: .complexReal))
}

func testOverlayHashableVImage() {
    _accHashProbe(vImage.ReflectionAxis.horizontal, vImage.ReflectionAxis.vertical)
    _accHashProbe(vImage.ShearDirection.horizontal, vImage.ShearDirection.vertical)
    _accHashProbe(vImage.ChannelOrdering.ARGB, vImage.ChannelOrdering.RGBA)
    _accHashProbe(vImage.BlendMode.darken, vImage.BlendMode.screen)
    _accHashProbe(vImage.BufferType.alpha, vImage.BufferType.chroma)
    _accHashProbe(vImage.FloodFillConnectivity.edges, vImage.FloodFillConnectivity.edgesAndCorners)
    _accHashProbe(vImage.MultidimensionalLookupTable.InterpolationMethod.full, vImage.MultidimensionalLookupTable.InterpolationMethod.half)
    _accHashProbe(vImage.Size(width: 1, height: 2), vImage.Size(width: 3, height: 4))
}

func testOverlayHashableBNNSGraph() {
    _accHashProbe(BNNSGraph.Builder.Activation.relu, BNNSGraph.Builder.Activation.tanh)
    _accHashProbe(BNNSGraph.Builder.CeilingMode.floor, BNNSGraph.Builder.CeilingMode.ceiling)
    _accHashProbe(BNNSGraph.Builder.ScatterMode.add, BNNSGraph.Builder.ScatterMode.multiply)
    _accHashProbe(BNNSGraph.Builder.PoolingFunction.max, BNNSGraph.Builder.PoolingFunction.l2Norm)
    _accHashProbe(BNNSGraph.Builder.ConvolutionPadding.same, BNNSGraph.Builder.ConvolutionPadding.valid)
    _accHashProbe(BNNSGraph.Builder.Intent.input, BNNSGraph.Builder.Intent.inputOutput)
    _accHashProbe(BNNSGraph.Builder.Padding.reflection, BNNSGraph.Builder.Padding.replication)
    _accHashProbe(BNNSGraph.Builder.Direction.forward, BNNSGraph.Builder.Direction.reverse)
    _accHashProbe(BNNSGraph.Builder.SortOrder.ascending, BNNSGraph.Builder.SortOrder.descending)
    _accHashProbe(BNNSGraph.Builder.SliceRange.fillAll, BNNSGraph.Builder.SliceRange(startIndex: 1, endIndex: 2))
    _accHashProbe(BNNSGraph.CompileOptions.OptimizationPreference.performance, BNNSGraph.CompileOptions.OptimizationPreference.internalRepresentationSize)
    var opts = BNNSGraph.CompileOptions(useSingleThread: true, generateDebugInfo: true, optimizationPreference: .performance)
    precondition(opts.useSingleThread)
    precondition(opts.generateDebugInfo)
    opts.useSingleThread = false
    opts.generateDebugInfo = false
    opts.optimizationPreference = .internalRepresentationSize
    precondition(opts.optimizationPreference == .internalRepresentationSize)
    _accHashProbe(BNNSGraph.Error.unableToCreateContext, BNNSGraph.Error.unableToExecute)
}

func testBLASThreadingModel() {
    let original = BLAS.threadingModel
    BLAS.threadingModel = .singleThreaded
    precondition(BLAS.threadingModel == .singleThreaded)
    BLAS.threadingModel = .multiThreaded
    precondition(BLAS.threadingModel == .multiThreaded)
    BLAS.threadingModel = original
}
