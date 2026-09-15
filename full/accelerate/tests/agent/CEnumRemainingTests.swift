import Accelerate
import Foundation

// Remaining C enum/struct-wrapper types: RawRepresentable BLAS/CBLAS threading
// and transpose wrappers, vDSP DFT direction enum, quadrature/sparse status
// wrappers, kvImage matrix constants, and the la_object protocol.

func testCEnumRemBLAS() {
    _ = BLAS_THREADING.self
    precondition(BLAS_THREADING_MULTI_THREADED.rawValue == 0)
    precondition(BLAS_THREADING_SINGLE_THREADED.rawValue == 1)
    precondition(BLAS_THREADING_MAX_OPTIONS.rawValue == 2)
    precondition(BLAS_THREADING(rawValue: 0) == BLAS_THREADING_MULTI_THREADED)
    _ = CBLAS_DIAG.self
    precondition(CblasNonUnit.rawValue == 131)
    precondition(CblasUnit.rawValue == 132)
    precondition(CBLAS_DIAG(rawValue: 132) == CblasUnit)
    _ = CBLAS_ORDER.self
    precondition(CblasRowMajor.rawValue == 101)
    precondition(CblasColMajor.rawValue == 102)
    _ = CBLAS_SIDE.self
    precondition(CblasLeft.rawValue == 141)
    precondition(CblasRight.rawValue == 142)
    _ = CBLAS_TRANSPOSE.self
    precondition(CblasNoTrans.rawValue == 111)
    precondition(CblasTrans.rawValue == 112)
    precondition(CblasConjTrans.rawValue == 113)
    precondition(AtlasConj.rawValue == 114)
    _ = CBLAS_UPLO.self
    precondition(CblasUpper.rawValue == 121)
    precondition(CblasLower.rawValue == 122)
    precondition(CBLAS_UPLO(rawValue: 121) == CblasUpper)
}

func testCEnumRemDFTStatus() {
    _ = vDSP_DFT_RealtoComplex.self
    precondition(vDSP_DFT_RealtoComplex.interleaved_ComplextoComplex.rawValue == 0)
    precondition(vDSP_DFT_RealtoComplex.interleaved_RealtoComplex.rawValue == 1)
    _ = quadrature_integrator.self
    precondition(QUADRATURE_INTEGRATE_QNG.rawValue == 0)
    precondition(QUADRATURE_INTEGRATE_QAG.rawValue == 1)
    precondition(QUADRATURE_INTEGRATE_QAGS.rawValue == 2)
    precondition(quadrature_integrator(rawValue: 1) == QUADRATURE_INTEGRATE_QAG)
    _ = quadrature_status.self
    precondition(QUADRATURE_SUCCESS.rawValue == 0)
    precondition(QUADRATURE_ERROR.rawValue == -1)
    precondition(QUADRATURE_INVALID_ARG_ERROR.rawValue == -2)
    precondition(QUADRATURE_ALLOC_ERROR.rawValue == -3)
    precondition(QUADRATURE_INTERNAL_ERROR.rawValue == -99)
    precondition(QUADRATURE_INTEGRATE_MAX_EVAL_ERROR.rawValue == -101)
    precondition(QUADRATURE_INTEGRATE_BAD_BEHAVIOUR_ERROR.rawValue == -102)
    _ = sparse_status.self
    precondition(SPARSE_SUCCESS.rawValue == 0)
    precondition(SPARSE_ILLEGAL_PARAMETER.rawValue == -1000)
    precondition(SPARSE_CANNOT_SET_PROPERTY.rawValue == -1001)
    precondition(SPARSE_SYSTEM_ERROR.rawValue == -1002)
    precondition(sparse_status(rawValue: -1000) == SPARSE_ILLEGAL_PARAMETER)
}

func testCEnumRemKVImageLA() {
    precondition(kvImageDecodeArray_16Q12Format == 64)
    precondition(kvImage_ARGBToYpCbCrMatrix_ITU_R_601_4 == 65)
    precondition(kvImage_ARGBToYpCbCrMatrix_ITU_R_709_2 == 66)
    precondition(kvImage_YpCbCrToARGBMatrix_ITU_R_601_4 == 67)
    precondition(kvImage_YpCbCrToARGBMatrix_ITU_R_709_2 == 68)
    _ = OS_la_object.self
    _ = la_object_t.self
    let obj: any OS_la_object = _OpenUIKitLAObject()
    let anyObj: la_object_t = obj
    _ = anyObj
}
