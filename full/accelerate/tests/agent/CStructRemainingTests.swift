import Accelerate
import Foundation

// Remaining C struct types: default values plus representative field reads.
// bnns_graph_argument_t carries only data_ptr_size on Linux (Apple's data_ptr
// and tensor fields need a graph provider), so those two rows stay deferred.

func testCStructRemDense() {
    _ = DenseMatrix_Double.self
    let dmD = DenseMatrix_Double()
    _ = dmD.rowCount
    _ = dmD.columnCount
    _ = dmD.data
    precondition(DenseMatrix_Double().rowCount == 0)
    _ = DenseMatrix_Float.self
    let dmF = DenseMatrix_Float()
    _ = dmF.rowCount
    _ = dmF.columnCount
    _ = dmF.data
    precondition(DenseMatrix_Float().rowCount == 0)
    _ = DenseVector_Double.self
    let dvD = DenseVector_Double()
    _ = dvD.count
    _ = dvD.data
    precondition(DenseVector_Double().count == 0)
    _ = DenseVector_Float.self
    let dvF = DenseVector_Float()
    _ = dvF.count
    _ = dvF.data
    precondition(DenseVector_Float().count == 0)
    _ = BNNSArithmeticUnary.self
    let arith = BNNSArithmeticUnary()
    _ = arith.`in`
    _ = arith.in_type
    _ = arith.out
    _ = arith.out_type
    precondition(BNNSArithmeticUnary().in_type == BNNSDescriptorType(rawValue: 0))
}

func testCStructRemSparse() {
    _ = SparseAttributes_t.self
    let sat = SparseAttributes_t()
    _ = sat.kind
    _ = sat.transpose
    _ = sat.triangle
    precondition(SparseAttributes_t().transpose == false)
    _ = SparseCGOptions.self
    precondition(SparseCGOptions().maxIterations == 0)
    _ = SparseGMRESOptions.self
    precondition(SparseGMRESOptions().nvec == 0)
    _ = SparseIterativeMethod.self
    precondition(SparseIterativeMethod().method == 0)
    _ = SparseLSMROptions.self
    precondition(SparseLSMROptions().maxIterations == 0)
    _ = SparseMatrixStructure.self
    precondition(SparseMatrixStructure().rowCount == 0)
    _ = SparseMatrix_Double.self
    precondition(SparseMatrix_Double().structure.rowCount == 0)
    _ = SparseMatrix_Float.self
    precondition(SparseMatrix_Float().structure.rowCount == 0)
    _ = SparseNumericFactorOptions.self
    precondition(SparseNumericFactorOptions().pivotTolerance == 0)
    _ = SparseOpaqueFactorization_Double.self
    _ = SparseOpaqueFactorization_Double().status
    _ = SparseOpaqueFactorization_Float.self
    _ = SparseOpaqueFactorization_Float().status
    _ = SparseOpaquePreconditioner_Double.self
    _ = SparseOpaquePreconditioner_Float.self
    _ = SparseOpaqueSubfactor_Double.self
    _ = SparseOpaqueSubfactor_Double().contents
    _ = SparseOpaqueSubfactor_Float.self
    _ = SparseOpaqueSubfactor_Float().contents
    _ = SparseOpaqueSymbolicFactorization.self
    precondition(SparseOpaqueSymbolicFactorization().blockSize == 0)
    _ = SparseSymbolicFactorOptions.self
    _ = SparseSymbolicFactorOptions().control
}

func testCStructRemGraphQuad() {
    _ = bnns_graph_argument_t.self
    precondition(bnns_graph_argument_t().data_ptr_size == 0)
    _ = bnns_graph_compile_options_t.self
    precondition(bnns_graph_compile_options_t().size == 0)
    _ = bnns_graph_context_t.self
    precondition(bnns_graph_context_t().size == 0)
    _ = bnns_graph_shape_t.self
    _ = bnns_graph_shape_t().rank
    _ = bnns_graph_t.self
    let bgt = bnns_graph_t(data: nil, size: 0)
    precondition(bgt.data == nil && bgt.size == 0)
    _ = bnns_user_message_data_t.self
    let umd = bnns_user_message_data_t(size: 0, data: nil)
    precondition(umd.size == 0 && umd.data == nil)
    _ = quadrature_integrate_function.self
    let qf = quadrature_integrate_function()
    _ = qf.fun_arg
    qf.fun(nil, 0, UnsafePointer<Double>(bitPattern: 1)!, UnsafeMutablePointer<Double>(bitPattern: 1)!)
    _ = quadrature_integrate_options.self
    let qo = quadrature_integrate_options()
    _ = qo.integrator
    _ = qo.abs_tolerance
    _ = qo.rel_tolerance
    _ = qo.max_intervals
    precondition(quadrature_integrate_options().max_intervals == 0)
    _ = vDSP_int24.self
    let i24 = vDSP_int24(bytes: (1, 2, 3))
    precondition(i24.bytes.0 == 1 && i24.bytes.2 == 3)
    _ = vDSP_uint24.self
    let u24 = vDSP_uint24()
    precondition(u24.bytes == (0, 0, 0))
}
