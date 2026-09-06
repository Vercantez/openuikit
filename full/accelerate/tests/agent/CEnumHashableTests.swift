import Accelerate
import Foundation

func _accHashProbe<T: Hashable>(_ a: T, _ b: T) {
    precondition(a == a)
    precondition(a != b)
    var hasher = Hasher()
    a.hash(into: &hasher)
    b.hash(into: &hasher)
    _ = hasher.finalize()
    _ = a.hashValue
    _ = b.hashValue
}
func testCEnumHashableBLAS() {
    _accHashProbe(BLAS_THREADING(rawValue: 1), BLAS_THREADING(rawValue: 2))
    _accHashProbe(CBLAS_DIAG(rawValue: 1), CBLAS_DIAG(rawValue: 2))
    _accHashProbe(CBLAS_ORDER(rawValue: 1), CBLAS_ORDER(rawValue: 2))
    _accHashProbe(CBLAS_SIDE(rawValue: 1), CBLAS_SIDE(rawValue: 2))
    _accHashProbe(CBLAS_TRANSPOSE(rawValue: 1), CBLAS_TRANSPOSE(rawValue: 2))
    _accHashProbe(CBLAS_UPLO(rawValue: 1), CBLAS_UPLO(rawValue: 2))
}

func testCEnumHashableVDSPC() {
    _accHashProbe(vDSP_DCT_Type.II, vDSP_DCT_Type.III)
    _accHashProbe(vDSP_DFT_Direction.FORWARD, vDSP_DFT_Direction.INVERSE)
    _accHashProbe(vDSP_DFT_RealtoComplex.interleaved_ComplextoComplex, vDSP_DFT_RealtoComplex.interleaved_RealtoComplex)
}

func testCEnumHashableBNNS0() {
    _accHashProbe(BNNSActivationFunction(rawValue: 1), BNNSActivationFunction(rawValue: 2))
    _accHashProbe(BNNSArithmeticFunction(rawValue: 1), BNNSArithmeticFunction(rawValue: 2))
    _accHashProbe(BNNSBoxCoordinateMode(rawValue: 1), BNNSBoxCoordinateMode(rawValue: 2))
    _accHashProbe(BNNSDataLayout(rawValue: 1), BNNSDataLayout(rawValue: 2))
    _accHashProbe(BNNSDataType(rawValue: 1), BNNSDataType(rawValue: 2))
    _accHashProbe(BNNSDescriptorType(rawValue: 1), BNNSDescriptorType(rawValue: 2))
    _accHashProbe(BNNSEmbeddingFlags(rawValue: 1), BNNSEmbeddingFlags(rawValue: 2))
    _accHashProbe(BNNSFilterType(rawValue: 1), BNNSFilterType(rawValue: 2))
    _accHashProbe(BNNSFlags(rawValue: 1), BNNSFlags(rawValue: 2))
    _accHashProbe(BNNSGraphArgumentIntent(rawValue: 1), BNNSGraphArgumentIntent(rawValue: 2))
    _accHashProbe(BNNSGraphArgumentType(rawValue: 1), BNNSGraphArgumentType(rawValue: 2))
    _accHashProbe(BNNSGraphMessageLevel(rawValue: 1), BNNSGraphMessageLevel(rawValue: 2))
    _accHashProbe(BNNSGraphOptimizationPreference(rawValue: 1), BNNSGraphOptimizationPreference(rawValue: 2))
    _accHashProbe(BNNSInterpolationMethod(rawValue: 1), BNNSInterpolationMethod(rawValue: 2))
    _accHashProbe(BNNSLayerFlags(rawValue: 1), BNNSLayerFlags(rawValue: 2))
    _accHashProbe(BNNSLinearSamplingMode(rawValue: 1), BNNSLinearSamplingMode(rawValue: 2))
    _accHashProbe(BNNSLossFunction(rawValue: 1), BNNSLossFunction(rawValue: 2))
}

func testCEnumHashableBNNS1() {
    _accHashProbe(BNNSLossReductionFunction(rawValue: 1), BNNSLossReductionFunction(rawValue: 2))
    _accHashProbe(BNNSNDArrayFlags(rawValue: 1), BNNSNDArrayFlags(rawValue: 2))
    _accHashProbe(BNNSNormType(rawValue: 1), BNNSNormType(rawValue: 2))
    _accHashProbe(BNNSOptimizerClippingFunction(rawValue: 1), BNNSOptimizerClippingFunction(rawValue: 2))
    _accHashProbe(BNNSOptimizerFunction(rawValue: 1), BNNSOptimizerFunction(rawValue: 2))
    _accHashProbe(BNNSOptimizerRegularizationFunction(rawValue: 1), BNNSOptimizerRegularizationFunction(rawValue: 2))
    _accHashProbe(BNNSOptimizerSGDMomentumVariant(rawValue: 1), BNNSOptimizerSGDMomentumVariant(rawValue: 2))
    _accHashProbe(BNNSPaddingMode(rawValue: 1), BNNSPaddingMode(rawValue: 2))
    _accHashProbe(BNNSPointerSpecifier(rawValue: 1), BNNSPointerSpecifier(rawValue: 2))
    _accHashProbe(BNNSPoolingFunction(rawValue: 1), BNNSPoolingFunction(rawValue: 2))
    _accHashProbe(BNNSQuantizerFunction(rawValue: 1), BNNSQuantizerFunction(rawValue: 2))
    _accHashProbe(BNNSRandomGeneratorMethod(rawValue: 1), BNNSRandomGeneratorMethod(rawValue: 2))
    _accHashProbe(BNNSReduceFunction(rawValue: 1), BNNSReduceFunction(rawValue: 2))
    _accHashProbe(BNNSRelationalOperator(rawValue: 1), BNNSRelationalOperator(rawValue: 2))
    _accHashProbe(BNNSShuffleType(rawValue: 1), BNNSShuffleType(rawValue: 2))
    _accHashProbe(BNNSSparsityType(rawValue: 1), BNNSSparsityType(rawValue: 2))
    _accHashProbe(BNNSTargetSystem(rawValue: 1), BNNSTargetSystem(rawValue: 2))
}

func testCEnumHashableSparse() {
    _accHashProbe(SparseControl_t(rawValue: 1), SparseControl_t(rawValue: 2))
    _accHashProbe(SparseFactorization_t(rawValue: 1), SparseFactorization_t(rawValue: 2))
    _accHashProbe(SparseGMRESVariant_t(rawValue: 1), SparseGMRESVariant_t(rawValue: 2))
    _accHashProbe(SparseIterativeStatus_t(rawValue: 1), SparseIterativeStatus_t(rawValue: 2))
    _accHashProbe(SparseKind_t(rawValue: 1), SparseKind_t(rawValue: 2))
    _accHashProbe(SparseLSMRConvergenceTest_t(rawValue: 1), SparseLSMRConvergenceTest_t(rawValue: 2))
    _accHashProbe(SparseOrder_t(rawValue: 1), SparseOrder_t(rawValue: 2))
    _accHashProbe(SparsePreconditioner_t(rawValue: 1), SparsePreconditioner_t(rawValue: 2))
    _accHashProbe(SparseScaling_t(rawValue: 1), SparseScaling_t(rawValue: 2))
    _accHashProbe(SparseStatus_t(rawValue: 1), SparseStatus_t(rawValue: 2))
    _accHashProbe(SparseSubfactor_t(rawValue: 1), SparseSubfactor_t(rawValue: 2))
    _accHashProbe(SparseTriangle_t(rawValue: 1), SparseTriangle_t(rawValue: 2))
    _accHashProbe(SparseUpdate_t(rawValue: 1), SparseUpdate_t(rawValue: 2))
    _accHashProbe(sparse_matrix_property(rawValue: 1), sparse_matrix_property(rawValue: 2))
    _accHashProbe(sparse_norm(rawValue: 1), sparse_norm(rawValue: 2))
    _accHashProbe(sparse_status(rawValue: 1), sparse_status(rawValue: 2))
}

func testCEnumHashableMisc() {
    _accHashProbe(quadrature_integrator(rawValue: 1), quadrature_integrator(rawValue: 2))
    _accHashProbe(quadrature_status(rawValue: 1), quadrature_status(rawValue: 2))
    _accHashProbe(vImageARGBType(rawValue: 1), vImageARGBType(rawValue: 2))
    _accHashProbe(vImageMDTableUsageHint(rawValue: 1), vImageMDTableUsageHint(rawValue: 2))
    _accHashProbe(vImageYpCbCrType(rawValue: 1), vImageYpCbCrType(rawValue: 2))
    _accHashProbe(vImage_InterpolationMethod(rawValue: 1), vImage_InterpolationMethod(rawValue: 2))
}

