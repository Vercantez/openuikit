import Accelerate
import Foundation

// Swift overlay remainder C: vDSP transform types, vImage structural types,
// BNNSGraph structural protocols, and scalar overlay witnesses. Trap-on-read
// state is referenced by keypath, closure-over-existential, or local
// conformers; BNNS graph-node methods and CoreGraphics-gated inits keep
// their deferred rows.

func testOvRemCBatch0() {
    _ = vDSP.ThresholdRule<Float>.self
    _ = vDSP.ThresholdRule<Float>.clampToThreshold
    _ = vDSP.ThresholdRule<Float>.signedConstant(1)
    _ = vDSP.ThresholdRule<Float>.zeroFill
    _ = vDSP.ThresholdRule<Double>.self
    _ = vDSP.ThresholdRule<Double>.clampToThreshold
    _ = vDSP.WindowSequence.self
    _ = vDSP.WindowSequence.hanningNormalized
    _ = vDSP.WindowSequence.hanningDenormalized
    _ = vDSP.WindowSequence.hamming
    _ = vDSP.WindowSequence.blackman
    _ = vDSP.IntegrationRule.self
    _ = vDSP.IntegrationRule.runningSum
    _ = vDSP.IntegrationRule.trapezoidal
    _ = vDSP.IntegrationRule.simpson
    _ = vDSP.DCTTransformType.self
    _ = vDSP.DCTTransformType.II
    _ = vDSP.DCTTransformType.III
    _ = vDSP.DCTTransformType.IV
    _ = vDSP.DCTTransformType.AllCases.self
    precondition(vDSP.DCTTransformType.II.dctType == .II)
    precondition(vDSP.DCTTransformType.III.dctType == .III)
    precondition(vDSP.DCTTransformType.IV.dctType == .IV)
    precondition(vDSP.DCTTransformType.allCases.count == 3)
    _ = vDSP.DFTTransformType.self
    _ = vDSP.DFTTransformType.complexReal
    _ = vDSP.DFTTransformType.complexComplex
    _ = vDSP.VectorizableFloat.self
    _ = vDSP.VectorizableFloat.Scalar.self
    precondition(vDSP.VectorizableFloat.Scalar.self == Float.self)
    _ = vDSP.VectorizableDouble.self
    _ = vDSP.VectorizableDouble.Scalar.self
    precondition(vDSP.VectorizableDouble.Scalar.self == Double.self)
    _ = vDSP.DiscreteFourierTransform<Float>.self
    _ = vDSP.FourierTransformDirection.self
    _ = vDSP.FourierTransformDirection.forward
    _ = vDSP.FourierTransformDirection.inverse
    _ = vDSP.FourierTransformDirection.forward.dftDirection
    _ = vDSP.FourierTransformDirection.inverse.dftDirection
    precondition(vDSP.FourierTransformDirection.forward.fftDirection == FFTDirection(FFT_FORWARD))
    precondition(vDSP.FourierTransformDirection.inverse.fftDirection == FFTDirection(FFT_INVERSE))
    _ = vDSP.DFTDoublePrecisionInterleavedFunctions.self
    _ = vDSP.DFTSinglePrecisionInterleavedFunctions.self
    _ = vDSP.DCT.self
    _ = vDSP.DFT<Float>.self
    _ = vDSP.FFT<DSPSplitComplex>.self
    _ = vDSP.FFT2D<DSPSplitComplex>.self
    _ = vDSP.Radix.self
    _ = vDSP.Radix.radix2
    _ = vDSP.Radix.radix3
    _ = vDSP.Radix.radix5
    precondition(vDSP.Radix.radix2.fftRadix == FFTRadix(FFT_RADIX2))
    _ = vDSP.DFTError.self
    _ = vDSP.DFTError.invalidInterleavedCount(count: 3)
    _ = vDSP.DFTError.invalidSplitComplexCount(count: 3, transformType: .complexComplex)
    _ = vDSP.SortOrder.self
    _ = vDSP.SortOrder.ascending
    _ = vDSP.SortOrder.descending
    _ = vDSP.SortOrder.RawValue.self
    _ = vDSP.SortOrder(rawValue: 1)
    _ = vDSP.SortOrder(rawValue: -1)
    precondition(vDSP.SortOrder.ascending.rawValue == 1)
    precondition(vDSP.SortOrder.descending.rawValue == -1)
    _ = vForce.self
}

func testOvRemCBatch1() {
    _ = vImage.BufferType.self
    _ = vImage.BufferType.RawValue.self
    _ = \vImage.BufferType.bufferTypeCode
    _ = \vImage.BufferType.rawValue
    _ = vImage.BufferType.chunky
    let kernOvRemC = vImage.ConvolutionKernel2D<UInt8>(
        values: [1, 2, 3, 4], size: vImage.Size(width: 2, height: 2))
    _ = vImage.MorphologyOperation<UInt8>.erode(structuringElement: kernOvRemC)
    _ = vImage.MorphologyOperation<UInt8>.dilate(structuringElement: kernOvRemC)
    _ = \vImage.MorphologyOperation<UInt8>.structuringElement
    _ = \vImage.MorphologyOperation<UInt8>.width
    _ = \vImage.MorphologyOperation<UInt8>.height
    _ = vImage.FloodFillConnectivity.RawValue.self
    _ = vImage.FloodFillConnectivity.edges
    _ = vImage.FloodFillConnectivity.edgesAndCorners
    _ = \vImage.FloodFillConnectivity.rawValue
    var mdTable = vImage.MultidimensionalLookupTable()
    mdTable.sourceChannelCount = 1
    mdTable.destinationChannelCount = 1
    mdTable.entryCountPerSourceChannel = [2]
    _ = \vImage.MultidimensionalLookupTable.sourceChannelCount
    _ = \vImage.MultidimensionalLookupTable.destinationChannelCount
    _ = \vImage.MultidimensionalLookupTable.entryCountPerSourceChannel
    _ = mdTable
    _ = (any BNNSGraph.PointerArgument).self
    struct PARemC: BNNSGraph.PointerArgument {
        typealias Element = Float
        var baseAddress: UnsafeMutablePointer<Float>? { nil }
        var count: Int { 0 }
    }
    _ = PARemC.Element.self
    let paRem = PARemC()
    precondition(paRem.count == 0)
    _ = { (x: any BNNSGraph.PointerArgument) -> Int in x.count }
    _ = BNNSGraph.TensorDescriptor.self
    _ = { (x: any BNNSGraph.TensorDescriptor) -> UnsafeMutableRawPointer? in x.tensorData }
    _ = BNNSGraph.Shape.ArrayLiteralElement.self
    let shapeOvRemC: BNNSGraph.Shape = [2, 3]
    precondition(shapeOvRemC.dimensions == [2, 3])
    _ = BNNSGraph.Builder.SliceIndex.self
    _ = (any BNNSGraph.Builder.SliceIndex).self
    let sliceOvRemC = BNNSGraph.Builder.SliceRange(startIndex: 0, endIndex: 4)
    precondition(sliceOvRemC.startIndex == 0)
    precondition(sliceOvRemC.endIndex == 4)
    _ = BNNSGraph.Builder.SliceRange.fillAll
    _ = BNNSGraph.Builder.PoolingPadding.self
    _ = (any BNNSGraph.Builder.OperationParameter).self
    struct OPRRemC: BNNSGraph.Builder.OperationParameter {
        typealias Element = Float
    }
    _ = OPRRemC.Element.self
    _ = BNNSGraph.Builder.Tensor<Float>.self
    _ = BNNSGraph.Builder.Tensor<Float>.Element.self
    _ = BNNSGraph.Builder.Tensor<Double>.Element.self
    _ = \BNNSGraph.Builder.Tensor<Float>.tensorData
    _ = \BNNSGraph.Builder.Tensor<Float>.description
    _ = \BNNSGraph.Builder.Tensor<Float>.dataType
}

func testOvRemCBatch2() {
    _ = Double.DFTFunctions.self
    _ = Double.BiquadFunctions.self
    _ = Double.DiscreteFourierTransformFunctions.self
    _ = Float.DFTFunctions.self
    _ = Float.bnnsDataType
    precondition(Float.bnnsDataType == BNNSDataTypeFloat32)
    _ = Float.BiquadFunctions.self
    _ = Float.DiscreteFourierTransformFunctions.self
    _ = Float.Element.self
    precondition(Float.Element.self == Float.self)
    _ = Int8.bnnsDataType
    _ = Int16.bnnsDataType
    _ = Int32.bnnsDataType
    _ = Int64.bnnsDataType
    _ = UInt8.bnnsDataType
    _ = UInt16.bnnsDataType
    _ = UInt32.bnnsDataType
    _ = UInt64.bnnsDataType
    _ = Float16.bnnsDataType
    precondition(Float16.bnnsDataType == BNNSDataTypeFloat16)
    _ = Float16.Element.self
}
