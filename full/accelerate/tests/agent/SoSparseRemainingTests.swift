import Accelerate
import Foundation

// Remaining sparse/BLAS/quadrature value types: RawRepresentable round-trips
// with Apple-measured values, plus struct default and memberwise inits.
// The `rawValues` plural accessor and the closure-based convenience inits have
// no Linux declaration, so those rows stay deferred.

func testSoSparseRemRawValues() {
    _ = sparse_norm.self
    precondition(SPARSE_NORM_ONE.rawValue == 171)
    precondition(SPARSE_NORM_TWO.rawValue == 173)
    precondition(SPARSE_NORM_INF.rawValue == 175)
    precondition(SPARSE_NORM_R1.rawValue == 179)
    precondition(sparse_norm(rawValue: 171) == SPARSE_NORM_ONE)
    precondition(sparse_norm(179) == SPARSE_NORM_R1)
    _ = SparseKind_t.self
    precondition(SparseOrdinary.rawValue == 0)
    precondition(SparseTriangular.rawValue == 1)
    precondition(SparseUnitTriangular.rawValue == 2)
    precondition(SparseSymmetric.rawValue == 3)
    precondition(SparseHermitian.rawValue == 7)
    precondition(SparseKind_t(rawValue: 7) == SparseHermitian)
    _ = SparseOrder_t.self
    precondition(SparseOrderDefault.rawValue == 0)
    precondition(SparseOrderUser.rawValue == 1)
    precondition(SparseOrderAMD.rawValue == 2)
    precondition(SparseOrderMetis.rawValue == 3)
    precondition(SparseOrderCOLAMD.rawValue == 4)
    precondition(SparseOrderMTMetis.rawValue == 5)
    precondition(SparseOrder_t(3) == SparseOrderMetis)
    _ = sparse_status.self
    precondition(sparse_status(rawValue: 0) == SPARSE_SUCCESS)
    _ = SparseStatus_t.self
    precondition(SparseStatusOK.rawValue == 0)
    precondition(SparseFactorizationFailed.rawValue == -1)
    precondition(SparseMatrixIsSingular.rawValue == -2)
    precondition(SparseInternalError.rawValue == -3)
    precondition(SparseParameterError.rawValue == -4)
    precondition(SparseStatusReleased.rawValue == -2147483647)
    precondition(SparseStatus_t(-4) == SparseParameterError)
    _ = SparseUpdate_t.self
    precondition(SparseUpdatePartialRefactor.rawValue == 0)
    precondition(SparseUpdate_t(rawValue: 0) == SparseUpdatePartialRefactor)
    _ = SparseScaling_t.self
    precondition(SparseScalingDefault.rawValue == 0)
    precondition(SparseScalingUser.rawValue == 1)
    precondition(SparseScalingEquilibriationInf.rawValue == 2)
    precondition(SparseScalingHungarianScalingOnly.rawValue == 3)
    precondition(SparseScalingHungarianScalingAndOrdering.rawValue == 4)
    _ = SparseTriangle_t.self
    precondition(SparseUpperTriangle.rawValue == 0)
    precondition(SparseLowerTriangle.rawValue == 1)
    precondition(SparseTriangle_t(1) == SparseLowerTriangle)
    _ = SparseSubfactor_t.self
    precondition(SparseSubfactorInvalid.rawValue == 0)
    precondition(SparseSubfactorP.rawValue == 1)
    precondition(SparseSubfactorS.rawValue == 2)
    precondition(SparseSubfactorL.rawValue == 3)
    precondition(SparseSubfactorD.rawValue == 4)
    precondition(SparseSubfactorPLPS.rawValue == 5)
    precondition(SparseSubfactorQ.rawValue == 6)
    precondition(SparseSubfactorR.rawValue == 7)
    precondition(SparseSubfactorRP.rawValue == 8)
    precondition(SparseSubfactorSr.rawValue == 9)
    precondition(SparseSubfactorSc.rawValue == 10)
    _ = SparseGMRESVariant_t.self
    precondition(SparseVariantDQGMRES.rawValue == 0)
    precondition(SparseVariantGMRES.rawValue == 1)
    precondition(SparseVariantFGMRES.rawValue == 2)
    _ = SparsePreconditioner_t.self
    precondition(SparsePreconditionerNone.rawValue == 0)
    precondition(SparsePreconditionerUser.rawValue == 1)
    precondition(SparsePreconditionerDiagonal.rawValue == 2)
    precondition(SparsePreconditionerDiagScaling.rawValue == 3)
    _ = sparse_matrix_property.self
    precondition(SPARSE_UPPER_TRIANGULAR.rawValue == 1)
    precondition(SPARSE_LOWER_TRIANGULAR.rawValue == 2)
    precondition(SPARSE_UPPER_SYMMETRIC.rawValue == 4)
    precondition(SPARSE_LOWER_SYMMETRIC.rawValue == 8)
    _ = SparseIterativeStatus_t.self
    precondition(SparseIterativeConverged.rawValue == 0)
    precondition(SparseIterativeMaxIterations.rawValue == 1)
    precondition(SparseIterativeIllConditioned.rawValue == -2)
    precondition(SparseIterativeParameterError.rawValue == -1)
    precondition(SparseIterativeInternalError.rawValue == -99)
    _ = SparseLSMRConvergenceTest_t.self
    precondition(SparseLSMRCTDefault.rawValue == 0)
    precondition(SparseLSMRCTFongSaunders.rawValue == 1)
    precondition(SparseLSMRConvergenceTest_t(1) == SparseLSMRCTFongSaunders)
}

func testSoSparseRemAliasRawValues() {
    _ = CBLAS_DIAG.self
    precondition(CBLAS_DIAG(rawValue: 131) == CblasNonUnit)
    precondition(CBLAS_DIAG(132) == CblasUnit)
    _ = CBLAS_SIDE.self
    precondition(CBLAS_SIDE(rawValue: 141) == CblasLeft)
    precondition(CBLAS_SIDE(142) == CblasRight)
    _ = CBLAS_UPLO.self
    precondition(CBLAS_UPLO(rawValue: 121) == CblasUpper)
    _ = CBLAS_ORDER.self
    precondition(CBLAS_ORDER(101) == CblasRowMajor)
    precondition(CBLAS_ORDER(rawValue: 102) == CblasColMajor)
    _ = BLAS_THREADING.self
    precondition(BLAS_THREADING(1) == BLAS_THREADING_SINGLE_THREADED)
    _ = CBLAS_TRANSPOSE.self
    precondition(CBLAS_TRANSPOSE(rawValue: 114) == AtlasConj)
    _ = quadrature_status.self
    precondition(quadrature_status(rawValue: -2) == QUADRATURE_INVALID_ARG_ERROR)
    _ = quadrature_integrator.self
    precondition(quadrature_integrator(2) == QUADRATURE_INTEGRATE_QAGS)
    _ = vDSP_DFT_RealtoComplex.self
    precondition(vDSP_DFT_RealtoComplex(rawValue: 0) == .interleaved_ComplextoComplex)
    precondition(vDSP_DFT_RealtoComplex(rawValue: 1) == .interleaved_RealtoComplex)
    precondition(vDSP_DFT_RealtoComplex(rawValue: 7) == nil)
}

func testSoSparseRemStructs() {
    _ = SparseCGOptions.self
    precondition(SparseCGOptions().atol == 0)
    _ = SparseLSMROptions.self
    precondition(SparseLSMROptions().lambda == 0)
    _ = SparseGMRESOptions.self
    precondition(SparseGMRESOptions().maxIterations == 0)
    _ = SparseIterativeMethod.self
    let iterMethod = SparseIterativeMethod()
    precondition(iterMethod.method == 0 && iterMethod.options == 0)
    _ = SparseAttributes_t.self
    precondition(SparseAttributes_t().kind == SparseOrdinary)
    _ = SparseNumericFactorOptions.self
    let numOpts = SparseNumericFactorOptions(control: SparseDefaultControl, scalingMethod: SparseScalingDefault, scaling: nil, pivotTolerance: 0.5, zeroTolerance: 0.25)
    precondition(numOpts.pivotTolerance == 0.5 && numOpts.zeroTolerance == 0.25)
    precondition(SparseNumericFactorOptions().scaling == nil)
    _ = SparseOpaqueSubfactor_Float.self
    let subF = SparseOpaqueSubfactor_Float(attributes: SparseAttributes_t(), contents: SparseSubfactorInvalid, factor: SparseOpaqueFactorization_Float(), workspaceRequiredStatic: 0, workspaceRequiredPerRHS: 0)
    precondition(subF.contents == SparseSubfactorInvalid)
    precondition(SparseOpaqueSubfactor_Float().contents == SparseSubfactorInvalid)
    _ = SparseOpaqueSubfactor_Double.self
    let subD = SparseOpaqueSubfactor_Double(attributes: SparseAttributes_t(), contents: SparseSubfactorL, factor: SparseOpaqueFactorization_Double(), workspaceRequiredStatic: 0, workspaceRequiredPerRHS: 0)
    precondition(subD.contents == SparseSubfactorL)
    precondition(SparseOpaqueSubfactor_Double().contents == SparseSubfactorInvalid)
    _ = SparseOpaqueFactorization_Float.self
    let facF = SparseOpaqueFactorization_Float(status: SparseStatusOK, attributes: SparseAttributes_t(), symbolicFactorization: SparseOpaqueSymbolicFactorization(), userFactorStorage: false, numericFactorization: nil, solveWorkspaceRequiredStatic: 0, solveWorkspaceRequiredPerRHS: 0)
    precondition(facF.status == SparseStatusOK)
    precondition(SparseOpaqueFactorization_Float().status == SparseStatusOK)
    _ = SparseOpaqueFactorization_Double.self
    let facD = SparseOpaqueFactorization_Double(status: SparseStatusOK, attributes: SparseAttributes_t(), symbolicFactorization: SparseOpaqueSymbolicFactorization(), userFactorStorage: false, numericFactorization: nil, solveWorkspaceRequiredStatic: 0, solveWorkspaceRequiredPerRHS: 0)
    precondition(facD.status == SparseStatusOK)
    precondition(SparseOpaqueFactorization_Double().status == SparseStatusOK)
    _ = SparseOpaquePreconditioner_Float.self
    var preMemF: [UInt8] = [0]
    preMemF.withUnsafeMutableBytes { mb in
        let preF = SparseOpaquePreconditioner_Float(type: SparsePreconditionerNone, mem: mb.baseAddress!, apply: { _, _, _, _ in })
        precondition(preF.type == SparsePreconditionerNone)
    }
    _ = SparseOpaquePreconditioner_Double.self
    var preMemD: [UInt8] = [0]
    preMemD.withUnsafeMutableBytes { mb in
        let preD = SparseOpaquePreconditioner_Double(type: SparsePreconditionerDiagonal, mem: mb.baseAddress!, apply: { _, _, _, _ in })
        precondition(preD.type == SparsePreconditionerDiagonal)
    }
    _ = SparseOpaqueSymbolicFactorization.self
    let sym = SparseOpaqueSymbolicFactorization(status: SparseStatusOK, rowCount: 2, columnCount: 2, attributes: SparseAttributes_t(), blockSize: 1, type: SparseFactorization_t(rawValue: 80), factorization: nil, workspaceSize_Float: 0, workspaceSize_Double: 0, factorSize_Float: 0, factorSize_Double: 0)
    precondition(sym.rowCount == 2 && sym.blockSize == 1)
    precondition(SparseOpaqueSymbolicFactorization().rowCount == 0)
    _ = vDSP_int24.self
    precondition(vDSP_int24().bytes == (0, 0, 0))
    precondition(vDSP_int24(bytes: (1, 2, 3)).bytes.1 == 2)
    _ = vDSP_uint24.self
    precondition(vDSP_uint24().bytes == (0, 0, 0))
    precondition(vDSP_uint24(bytes: (4, 5, 6)).bytes.2 == 6)
    _ = quadrature_integrate_options.self
    let qopt = quadrature_integrate_options(integrator: QUADRATURE_INTEGRATE_QAGS, abs_tolerance: 1e-6, rel_tolerance: 1e-6, qag_points_per_interval: 15, max_intervals: 10)
    precondition(qopt.max_intervals == 10 && qopt.qag_points_per_interval == 15)
    precondition(quadrature_integrate_options().integrator == QUADRATURE_INTEGRATE_QNG)
    _ = quadrature_integrate_function.self
    let qfun = quadrature_integrate_function(fun: { _, _, _, _ in }, fun_arg: nil)
    precondition(qfun.fun_arg == nil)
}
