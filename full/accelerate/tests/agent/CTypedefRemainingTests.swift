import Accelerate
import Foundation

// Remaining C typedef aliases: each typealias is referenced by name and, where
// the aliased type is directly constructible, pinned with a default value.

func testCTypedefRemBLASBNNS() {
    _ = BLASParamErrorProc.self
    let allocFn: BNNSAlloc = { _, _, _ in return 0 }
    _ = allocFn(nil, 0, 0)
    _ = BNNSFilter.self
    let freeFn: BNNSFree = { _ in }
    _ = freeFn
    _ = BNNSNearestNeighbors.self
    _ = BNNSRandomGenerator.self
    _ = COMPLEX.self
    precondition(COMPLEX.self == DSPComplex.self)
    _ = COMPLEX_SPLIT.self
    precondition(COMPLEX_SPLIT.self == DSPSplitComplex.self)
    _ = DOUBLE_COMPLEX.self
    precondition(DOUBLE_COMPLEX.self == DSPDoubleComplex.self)
    _ = DOUBLE_COMPLEX_SPLIT.self
    precondition(DOUBLE_COMPLEX_SPLIT.self == DSPDoubleSplitComplex.self)
    _ = FFTDirection.self
    let fftDir: FFTDirection = 1
    precondition(fftDir == FFT_FORWARD)
    _ = FFTRadix.self
    let fftRadix: FFTRadix = 0
    precondition(fftRadix == FFT_RADIX2)
    _ = FFTSetup.self
    _ = FFTSetupD.self
    _ = GammaFunction.self
    _ = bnns_graph_compile_message_fn_t.self
    _ = bnns_graph_execute_message_fn_t.self
    _ = bnns_graph_free_all_fn_t.self
    _ = bnns_graph_realloc_fn_t.self
}

func testCTypedefRemPixels() {
    _ = Pixel_8.self
    precondition(Pixel_8.self == UInt8.self)
    _ = Pixel_88.self
    let p88: Pixel_88 = (1, 2)
    precondition(p88.0 == 1 && p88.1 == 2)
    _ = Pixel_8888.self
    let p8888: Pixel_8888 = (1, 2, 3, 4)
    precondition(p8888.3 == 4)
    _ = Pixel_16F.self
    _ = Pixel_16F16F.self
    _ = Pixel_16Q12.self
    precondition(Pixel_16Q12.self == Int16.self)
    _ = Pixel_16S.self
    _ = Pixel_16S16S.self
    _ = Pixel_16U.self
    precondition(Pixel_16U.self == UInt16.self)
    _ = Pixel_16U16U.self
    _ = Pixel_32U.self
    precondition(Pixel_32U.self == UInt32.self)
    _ = Pixel_ARGB_16F.self
    let argb16f: Pixel_ARGB_16F = (1, 2, 3, 4)
    precondition(argb16f.0 == 1)
    _ = Pixel_ARGB_16S.self
    _ = Pixel_ARGB_16U.self
    _ = Pixel_F.self
    precondition(Pixel_F.self == Float.self)
    _ = Pixel_FF.self
    let pff: Pixel_FF = (1.5, 2.5)
    precondition(pff.0 == 1.5)
    _ = Pixel_FFFF.self
    _ = ResamplingFilter.self
    _ = vImageBufferTypeCode.self
    let typeCode: vImageBufferTypeCode = 0
    precondition(typeCode == 0)
    _ = vImageCVImageFormatError.self
    _ = vImageMatrixType.self
    _ = vImage_Error.self
    precondition(vImage_Error.self == Int.self)
    _ = vImage_MultidimensionalTable.self
    _ = vImage_WarpInterpolation.self
}

func testCTypedefRemLAVDSP() {
    _ = la_attribute_t.self
    _ = la_count_t.self
    precondition(la_count_t.self == UInt.self)
    _ = la_deallocator_t.self
    let dealloc: la_deallocator_t = { _ in }
    _ = dealloc
    _ = la_hint_t.self
    _ = la_index_t.self
    precondition(la_index_t.self == Int.self)
    _ = la_norm_t.self
    _ = la_object_t.self
    _ = la_scalar_type_t.self
    _ = la_status_t.self
    precondition(la_status_t.self == Int.self)
    _ = quadrature_function_array.self
    _ = sparse_dimension.self
    precondition(sparse_dimension.self == UInt64.self)
    _ = sparse_index.self
    _ = sparse_matrix_double.self
    _ = sparse_matrix_double_complex.self
    _ = sparse_matrix_float.self
    _ = sparse_matrix_float_complex.self
    _ = sparse_stride.self
    precondition(sparse_stride.self == Int64.self)
    _ = vBool32.self
    precondition(vBool32(1, 0, 1, 0)[0] == 1)
    _ = vDSP_DFT_Interleaved_Setup.self
    _ = vDSP_DFT_Interleaved_SetupD.self
    _ = vDSP_DFT_Setup.self
    _ = vDSP_DFT_SetupD.self
    _ = vDSP_Length.self
    precondition(vDSP_Length.self == UInt.self)
    _ = vDSP_Stride.self
    precondition(vDSP_Stride.self == Int.self)
    _ = vDSP_biquad_Setup.self
    _ = vDSP_biquad_SetupD.self
    _ = vDSP_biquadm_Setup.self
    _ = vDSP_biquadm_SetupD.self
    _ = vDouble.self
    precondition(vDouble.self == SIMD2<Double>.self)
    _ = vFloat.self
    precondition(vFloat(1, 2, 3, 4)[3] == 4)
    _ = vFloatPacked.self
    _ = vSInt8.self
    _ = vSInt16.self
    _ = vSInt32.self
    _ = vSInt64.self
    _ = vUInt8.self
    precondition(vUInt8(repeating: 7)[15] == 7)
    _ = vUInt16.self
    _ = vUInt32.self
    _ = vUInt64.self
}
