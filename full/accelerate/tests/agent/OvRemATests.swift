import Accelerate
import Foundation

// Swift overlay remainder A: buffer/matrix protocols, pixel-format protocols,
// vDSP/BLAS/BNNS overlay types, optimizer and loss-parameter structs.
// Trap-on-read properties are referenced by keypath only; fail-closed BNNS
// layer inits and graph apply methods keep their deferred rows.

func testOvRemAMatrixOrder() {
    _ = AccelerateMatrixOrder.self
    _ = AccelerateMatrixOrder.RawValue.self
    precondition(AccelerateMatrixOrder.RawValue.self == Int.self)
    precondition(AccelerateMatrixOrder(rawValue: 0) == .rowMajor)
    precondition(AccelerateMatrixOrder(rawValue: 1) == .columnMajor)
    precondition(AccelerateMatrixOrder.rowMajor.rawValue == 0)
    precondition(AccelerateMatrixOrder.columnMajor.rawValue == 1)
}

func testOvRemABufferProtocols() {
    _ = (any AccelerateBuffer).self
    _ = (any AccelerateMutableBuffer).self
    _ = Array<Float>.Element.self
    precondition(Array<Float>.Element.self == Float.self)
    let floats: [Float] = [1, 2, 3]
    precondition(floats.count == 3)
    precondition(floats.withUnsafeBufferPointer { $0.count } == 3)
    var mut: [Float] = [1, 2]
    mut.withUnsafeMutableBufferPointer { $0[0] = 9 }
    precondition(mut[0] == 9)
    _ = Array<Float>.self
}

func testOvRemAMatrixBuffers() {
    _ = (any AccelerateMatrixBuffer).self
    _ = (any AccelerateMutableMatrixBuffer).self
    struct TinyMatrixRemA: AccelerateMatrixBuffer, AccelerateMutableMatrixBuffer {
        typealias Element = Float
        var rowCount: Int { 2 }
        var columnCount: Int { 2 }
        var leadingDimension: Int { 2 }
        var accelerateMatrixOrder: AccelerateMatrixOrder { .rowMajor }
        var storage: [Float] = [1, 2, 3, 4]
        func withUnsafeBufferPointer<R>(_ body: (UnsafeBufferPointer<Float>) throws -> R) rethrows -> R {
            try storage.withUnsafeBufferPointer(body)
        }
        mutating func withUnsafeMutableBufferPointer<R>(_ body: (inout UnsafeMutableBufferPointer<Float>) throws -> R) rethrows -> R {
            try storage.withUnsafeMutableBufferPointer(body)
        }
    }
    var tiny = TinyMatrixRemA()
    _ = TinyMatrixRemA.Element.self
    precondition(tiny.rowCount == 2 && tiny.columnCount == 2)
    precondition(tiny.leadingDimension == 2)
    precondition(tiny.accelerateMatrixOrder == .rowMajor)
    precondition(tiny.withUnsafeBufferPointer { $0.count } == 4)
    tiny.withUnsafeMutableBufferPointer { $0[0] = 7 }
    precondition(tiny.storage[0] == 7)
}

func testOvRemAPixelScalar() {
    _ = (any BNNSScalar).self
    _ = Float.bnnsDataType
    precondition(Float.bnnsDataType == BNNSDataTypeFloat32)
    precondition(Int8.bnnsDataType == BNNSDataTypeInt8)
    _ = (any PixelFormat).self
    _ = vImage.Planar8.ComponentType.self
    precondition(vImage.Planar8.ComponentType.self == Pixel_8.self)
    _ = (any StaticPixelFormat).self
    precondition(vImage.Planar8.bitCountPerPixel == 8)
    precondition(vImage.Planar8.channelCount == 1)
    _ = (any SinglePlanePixelFormat).self
    _ = (any InitializableFromCGImage).self
    precondition(vImage.Planar8.bitCountPerComponent == 8)
    _ = (any MultiplePlanePixelFormat).self
    precondition(vImage.Planar8x2.bitCountPerPlanarPixel == 8)
    _ = vImage.Planar8x2.PlanarPixelFormat.self
    precondition(vImage.Planar8x2.planeCount == 2)
    _ = (any FusableLayerParameters).self
    _ = (any BNNSOptimizer).self
    _ = \BNNS.AdamOptimizer.bnnsOptimizerFunction
    _ = \BNNS.AdamOptimizer.accumulatorCountMultiplier
}

func testOvRemAvDSPProtocols() {
    _ = (any vDSP_IntegerConvertable).self
    _ = Float.init(3)
    _ = (any vDSP_FloatingPointConvertable).self
    _ = Double.init(7)
    _ = (any vDSP_FloatingPointGeneratable).self
    _ = (any vDSP_FourierTransformable).self
    _ = DSPSplitComplex.FFTFunctions.self
    precondition(DSPSplitComplex.FFTFunctions.self == vDSP_SplitComplexFloat.self)
    _ = (any vDSP_DiscreteFourierTransformable).self
    _ = Float.DiscreteFourierTransformFunctions.self
    precondition(Float.DiscreteFourierTransformFunctions.self == vDSP.DFTSinglePrecisionSplitComplexFunctions.self)
    _ = (any vDSP_FloatingPointBiquadFilterable).self
    _ = Float.BiquadFunctions.self
    _ = Double.BiquadFunctions.self
    _ = (any vDSP_DiscreteTransformLifecycleFunctions).self
    _ = (any vDSP_FloatingPointDiscreteFourierTransformable).self
    _ = Float.DFTFunctions.self
    _ = Double.DFTFunctions.self
    _ = (any vDSP_DFTFunctions).self
    _ = (any vDSP_BiquadFunctions).self
    _ = (any vDSP_FourierTransformFunctions).self
    _ = vDSP_SplitComplexDouble.SplitComplex.self
    precondition(vDSP_SplitComplexFloat.SplitComplex.self == DSPSplitComplex.self)
}

func testOvRemABLAS() {
    _ = BLAS.self
    _ = BLAS.ThreadingModel.self
    _ = BNNS.DataLayout.self
    _ = BNNS.DataLayout.AllCases.self
    precondition(BNNS.DataLayout.AllCases.self == [BNNS.DataLayout].self)
}

func testOvRemABNNSLayers() {
    _ = BNNS.FusedLayer.self
    _ = BNNS.FusedLayer()
    _ = BNNS.UnaryLayer.self
    _ = BNNS.UnaryLayer()
    _ = BNNS.BinaryLayer.self
    _ = BNNS.BinaryLayer()
    _ = BNNS.ResizeLayer.self
    _ = BNNS.ResizeLayer()
    _ = BNNS.DropoutLayer.self
    _ = BNNS.DropoutLayer()
    _ = BNNS.PaddingLayer.self
    _ = BNNS.PaddingLayer()
    _ = BNNS.PermuteLayer.self
    _ = BNNS.PermuteLayer()
    _ = BNNS.PoolingLayer.self
    _ = BNNS.PoolingLayer()
    _ = BNNS.PaddingMode.reflect
    _ = BNNS.PaddingMode.constantScalar(0.25)
    _ = \BNNS.PaddingMode.bnnsPaddingMode
    _ = \BNNS.PaddingMode.paddingBitPattern
    _ = BNNS.PoolingType.l2Norm
    _ = BNNS.PoolingType.average(countIncludesPadding: true)
    _ = \BNNS.PoolingType.bnnsPoolingFunction
    _ = BNNS.LossFunction.huber(huberDelta: 0.5)
    _ = BNNS.LossFunction.cosineDistance
    _ = \BNNS.LossFunction.bnnsLossFunction
    _ = BNNS.LossReduction.sum
    _ = BNNS.LossReduction.none
    _ = \BNNS.LossReduction.bnnsLossReductionFunction
    _ = BNNS.SparseLayout.self
}

func testOvRemAAdamOptimizer() {
    _ = BNNS.AdamOptimizer.self
    var opt = BNNS.AdamOptimizer()
    opt.usesAMSGrad = true
    opt.learningRate = 0.001
    opt.gradientScale = 1.0
    opt.gradientBounds = 0.0...1.0
    opt.gradientClipping = .none
    opt.regularizationScale = 0.0001
    opt.regularizationFunction = BNNSOptimizerRegularizationL1
    opt.timeStep = 2.0
    _ = \BNNS.AdamOptimizer.bnnsOptimizerFunction
    _ = \BNNS.AdamOptimizer.accumulatorCountMultiplier
    _ = \BNNS.AdamOptimizer.usesAMSGrad
    _ = \BNNS.AdamOptimizer.learningRate
    _ = \BNNS.AdamOptimizer.gradientScale
    _ = \BNNS.AdamOptimizer.gradientBounds
    _ = \BNNS.AdamOptimizer.gradientClipping
    _ = \BNNS.AdamOptimizer.regularizationScale
    _ = \BNNS.AdamOptimizer.regularizationFunction
    _ = \BNNS.AdamOptimizer.timeStep
    var opt2 = BNNS.AdamOptimizer()
    opt2.usesAMSGrad = false
    _ = opt
    _ = opt2
}

func testOvRemAYoloParameters() {
    _ = BNNS.LossFunction.YoloParameters.self
    var params = BNNS.LossFunction.YoloParameters()
    params.huberDelta = 0.5
    params.objectScale = 1.0
    params.anchorBoxSize = 3
    params.gridRowsCount = 13
    params.noObjectScale = 0.5
    params.anchorBoxCount = 5
    params.gridColumnCount = 13
    params.objectMinimumIoU = 0.5
    params.noObjectMaximumIoU = 0.4
    params.classificationScale = 1.0
    params.whScale = 1.0
    params.xyScale = 1.0
    let anchors = UnsafeMutablePointer<Float>.allocate(capacity: 2)
    anchors[0] = 0.5
    anchors[1] = 1.5
    params.anchorsData = anchors
    _ = BNNS.LossFunction.yolo(parameters: params)
    anchors.deallocate()
    _ = \BNNS.LossFunction.YoloParameters.huberDelta
    _ = \BNNS.LossFunction.YoloParameters.anchorsData
    _ = \BNNS.LossFunction.YoloParameters.objectScale
    _ = \BNNS.LossFunction.YoloParameters.anchorBoxSize
    _ = \BNNS.LossFunction.YoloParameters.gridRowsCount
    _ = \BNNS.LossFunction.YoloParameters.noObjectScale
    _ = \BNNS.LossFunction.YoloParameters.anchorBoxCount
    _ = \BNNS.LossFunction.YoloParameters.gridColumnCount
    _ = \BNNS.LossFunction.YoloParameters.objectMinimumIoU
    _ = \BNNS.LossFunction.YoloParameters.noObjectMaximumIoU
    _ = \BNNS.LossFunction.YoloParameters.classificationScale
    _ = \BNNS.LossFunction.YoloParameters.whScale
    _ = \BNNS.LossFunction.YoloParameters.xyScale
    _ = params
}

func testOvRemAStatics() {
    _ = BNNSDataTypeInt8
    _ = BNNSDataTypeInt8.rawValue
    _ = BNNSDataTypeInt16
    _ = BNNSDataTypeInt16.rawValue
    _ = BNNSDataTypeInt32
    _ = BNNSDataTypeInt32.rawValue
    _ = BNNSDataTypeFloat16
    _ = BNNSDataTypeFloat16.rawValue
    _ = BNNSDataTypeIndexed8
    _ = BNNSDataTypeIndexed8.rawValue
    _ = BNNSFlagsUseClientPtr
    _ = BNNSFlagsUseClientPtr.rawValue
    _ = BNNSPoolingFunctionMax
    _ = BNNSPoolingFunctionMax.rawValue
    _ = BNNSActivationFunctionAbs
    _ = BNNSActivationFunctionAbs.rawValue
    _ = BNNSActivationFunctionTanh
    _ = BNNSActivationFunctionTanh.rawValue
    _ = BNNSPoolingFunctionAverage
    _ = BNNSPoolingFunctionAverage.rawValue
    _ = BNNSActivationFunctionSigmoid
    _ = BNNSActivationFunctionSigmoid.rawValue
    _ = BNNSActivationFunctionIdentity
    _ = BNNSActivationFunctionIdentity.rawValue
    _ = BNNSActivationFunctionScaledTanh
    _ = BNNSActivationFunctionScaledTanh.rawValue
    _ = BNNSActivationFunctionRectifiedLinear
    _ = BNNSActivationFunctionRectifiedLinear.rawValue
    _ = BNNSActivationFunctionLeakyRectifiedLinear
    _ = BNNSActivationFunctionLeakyRectifiedLinear.rawValue
    _ = BNNSOptimizerRegularizationL1
}

func testOvRemAQuadrature() {
    _ = Quadrature.self
    _ = Quadrature.Integrator.self
    _ = QUADRATURE_INTEGRATE_QNG
    _ = Quadrature.QAGPointsPerInterval.self
    _ = Quadrature.Error.self
    _ = QUADRATURE_SUCCESS
}
