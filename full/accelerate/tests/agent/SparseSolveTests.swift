import Accelerate
import Foundation

func testSparseSolveFloatVector() {
    var rows: [Int32] = [0, 1]
    var cols: [Int32] = [0, 1]
    var vals: [Float] = [2, 4]
    let A = SparseConvertFromCoordinate(2, 2, 2, 1, SparseAttributes_t(), &rows, &cols, &vals)
    var bdata: [Float] = [2, 8]
    var xdata: [Float] = [0, 0]
    let b = DenseVector_Float(count: 2, data: &bdata)
    let x = DenseVector_Float(count: 2, data: &xdata)
    let method = SparseConjugateGradient()
    precondition(method.method == 1)
    let status = SparseSolve(method, A, b, x)
    precondition(status == SparseIterativeConverged)
    precondition(abs(xdata[0] - 1) < 0.0001)
    precondition(abs(xdata[1] - 2) < 0.0001)
    var x2 = xdata
    let x2v = DenseVector_Float(count: 2, data: &x2)
    _ = SparseSolve(method, A, b, x2v, SparsePreconditionerNone)
    _ = SparseSolve(method, A, b, x2v, SparseOpaquePreconditioner_Float())
    _ = SparseConjugateGradient(SparseCGOptions())
    SparseCleanup(A)
}

func testSparseSolveDoubleVector() {
    var rows: [Int32] = [0, 1]
    var cols: [Int32] = [0, 1]
    var vals: [Double] = [3, 5]
    let A = SparseConvertFromCoordinate(2, 2, 2, 1, SparseAttributes_t(), &rows, &cols, &vals)
    var bdata: [Double] = [6, 10]
    var xdata: [Double] = [0, 0]
    let b = DenseVector_Double(count: 2, data: &bdata)
    let x = DenseVector_Double(count: 2, data: &xdata)
    let status = SparseSolve(SparseConjugateGradient(), A, b, x)
    precondition(status == SparseIterativeConverged)
    precondition(abs(xdata[0] - 2) < 1e-12)
    precondition(abs(xdata[1] - 2) < 1e-12)
    _ = SparseSolve(SparseConjugateGradient(), A, b, x, SparsePreconditionerNone)
    _ = SparseSolve(SparseConjugateGradient(), A, b, x, SparseOpaquePreconditioner_Double())
    SparseCleanup(A)
}

func testSparseSolveFloatMatrix() {
    var rows: [Int32] = [0, 1]
    var cols: [Int32] = [0, 1]
    var vals: [Float] = [2, 2]
    let A = SparseConvertFromCoordinate(2, 2, 2, 1, SparseAttributes_t(), &rows, &cols, &vals)
    var bdata: [Float] = [2, 4, 4, 8]
    var xdata: [Float] = [0, 0, 0, 0]
    let B = DenseMatrix_Float(rowCount: 2, columnCount: 2, columnStride: 2, attributes: SparseAttributes_t(), data: &bdata)
    let X = DenseMatrix_Float(rowCount: 2, columnCount: 2, columnStride: 2, attributes: SparseAttributes_t(), data: &xdata)
    let status = SparseSolve(SparseConjugateGradient(), A, B, X)
    precondition(status == SparseIterativeConverged)
    precondition(abs(xdata[0] - 1) < 0.0001)
    precondition(abs(xdata[1] - 2) < 0.0001)
    _ = SparseSolve(SparseConjugateGradient(), A, B, X, SparsePreconditionerNone)
    _ = SparseSolve(SparseConjugateGradient(), A, B, X, SparseOpaquePreconditioner_Float())
    SparseCleanup(A)
}

func testSparseSolveDoubleMatrix() {
    var rows: [Int32] = [0, 1]
    var cols: [Int32] = [0, 1]
    var vals: [Double] = [2, 2]
    let A = SparseConvertFromCoordinate(2, 2, 2, 1, SparseAttributes_t(), &rows, &cols, &vals)
    var bdata: [Double] = [2, 6]
    var xdata: [Double] = [0, 0]
    let B = DenseMatrix_Double(rowCount: 2, columnCount: 1, columnStride: 2, attributes: SparseAttributes_t(), data: &bdata)
    let X = DenseMatrix_Double(rowCount: 2, columnCount: 1, columnStride: 2, attributes: SparseAttributes_t(), data: &xdata)
    let status = SparseSolve(SparseConjugateGradient(), A, B, X)
    precondition(status == SparseIterativeConverged)
    precondition(abs(xdata[0] - 1) < 1e-12)
    precondition(abs(xdata[1] - 3) < 1e-12)
    _ = SparseSolve(SparseConjugateGradient(), A, B, X, SparsePreconditionerNone)
    _ = SparseSolve(SparseConjugateGradient(), A, B, X, SparseOpaquePreconditioner_Double())
    SparseCleanup(A)
}

func testSparseSolveApplyOperatorFloat() {
    var bdata: [Float] = [4, 6]
    var xdata: [Float] = [0, 0]
    let b = DenseVector_Float(count: 2, data: &bdata)
    let x = DenseVector_Float(count: 2, data: &xdata)
    let status = SparseSolve(SparseConjugateGradient(), { _, _, src, dst in
        dst.data[0] = 2 * src.data[0]
        dst.data[1] = 3 * src.data[1]
    }, b, x)
    precondition(status == SparseIterativeConverged)
    precondition(abs(xdata[0] - 2) < 0.0001)
    precondition(abs(xdata[1] - 2) < 0.0001)
    _ = SparseSolve(SparseConjugateGradient(), { _, _, src, dst in
        dst.data[0] = src.data[0]
        dst.data[1] = src.data[1]
    }, b, x, SparseOpaquePreconditioner_Float())
}

func testSparseSolveApplyOperatorDouble() {
    var bdata: [Double] = [10, 20]
    var xdata: [Double] = [0, 0]
    let b = DenseVector_Double(count: 2, data: &bdata)
    let x = DenseVector_Double(count: 2, data: &xdata)
    let status = SparseSolve(SparseConjugateGradient(), { _, _, src, dst in
        dst.data[0] = 5 * src.data[0]
        dst.data[1] = 10 * src.data[1]
    }, b, x)
    precondition(status == SparseIterativeConverged)
    precondition(abs(xdata[0] - 2) < 1e-12)
    precondition(abs(xdata[1] - 2) < 1e-12)
}

func testSparseSolveApplyOperatorFloatMatrix() {
    var bdata: [Float] = [2, 4]
    var xdata: [Float] = [0, 0]
    let B = DenseMatrix_Float(rowCount: 2, columnCount: 1, columnStride: 2, attributes: SparseAttributes_t(), data: &bdata)
    let X = DenseMatrix_Float(rowCount: 2, columnCount: 1, columnStride: 2, attributes: SparseAttributes_t(), data: &xdata)
    let status = SparseSolve(SparseConjugateGradient(), { _, _, src, dst in
        let n = Int(src.rowCount)
        let k = Int(src.columnCount)
        for c in 0..<k {
            for r in 0..<n {
                dst.data[c * Int(dst.columnStride) + r] = 2 * src.data[c * Int(src.columnStride) + r]
            }
        }
    }, B, X)
    precondition(status == SparseIterativeConverged)
    precondition(abs(xdata[0] - 1) < 0.0001)
    _ = SparseSolve(SparseConjugateGradient(), { _, _, src, dst in
        dst.data[0] = src.data[0]
        dst.data[1] = src.data[1]
    }, B, X, SparseOpaquePreconditioner_Float())
}

func testSparseSolveApplyOperatorDoubleMatrix() {
    var bdata: [Double] = [6, 9]
    var xdata: [Double] = [0, 0]
    let B = DenseMatrix_Double(rowCount: 2, columnCount: 1, columnStride: 2, attributes: SparseAttributes_t(), data: &bdata)
    let X = DenseMatrix_Double(rowCount: 2, columnCount: 1, columnStride: 2, attributes: SparseAttributes_t(), data: &xdata)
    let status = SparseSolve(SparseConjugateGradient(), { _, _, src, dst in
        dst.data[0] = 3 * src.data[0]
        dst.data[1] = 3 * src.data[1]
    }, B, X)
    precondition(status == SparseIterativeConverged)
    precondition(abs(xdata[0] - 2) < 1e-12)
    _ = SparseSolve(SparseConjugateGradient(), { _, _, src, dst in
        dst.data[0] = src.data[0]
        dst.data[1] = src.data[1]
    }, B, X, SparseOpaquePreconditioner_Double())
}

func testSparseSolveComplexFailClosed() {
    let method = SparseConjugateGradient()
    let statusM = SparseSolve(method, SparseMatrix_Complex_Float(), DenseMatrix_Complex_Float(), DenseMatrix_Complex_Float())
    precondition(statusM == SparseIterativeParameterError)
    _ = SparseSolve(method, SparseMatrix_Complex_Float(), DenseMatrix_Complex_Float(), DenseMatrix_Complex_Float(), SparsePreconditionerNone)
    _ = SparseSolve(method, SparseMatrix_Complex_Float(), DenseMatrix_Complex_Float(), DenseMatrix_Complex_Float(), SparseOpaquePreconditioner_Complex_Float())
    _ = SparseSolve(method, SparseMatrix_Complex_Float(), DenseVector_Complex_Float(), DenseVector_Complex_Float())
    _ = SparseSolve(method, SparseMatrix_Complex_Float(), DenseVector_Complex_Float(), DenseVector_Complex_Float(), SparsePreconditionerNone)
    _ = SparseSolve(method, SparseMatrix_Complex_Float(), DenseVector_Complex_Float(), DenseVector_Complex_Float(), SparseOpaquePreconditioner_Complex_Float())
    _ = SparseSolve(method, SparseMatrix_Complex_Double(), DenseMatrix_Complex_Double(), DenseMatrix_Complex_Double())
    _ = SparseSolve(method, SparseMatrix_Complex_Double(), DenseMatrix_Complex_Double(), DenseMatrix_Complex_Double(), SparsePreconditionerNone)
    _ = SparseSolve(method, SparseMatrix_Complex_Double(), DenseMatrix_Complex_Double(), DenseMatrix_Complex_Double(), SparseOpaquePreconditioner_Complex_Double())
    _ = SparseSolve(method, SparseMatrix_Complex_Double(), DenseVector_Complex_Double(), DenseVector_Complex_Double())
    _ = SparseSolve(method, SparseMatrix_Complex_Double(), DenseVector_Complex_Double(), DenseVector_Complex_Double(), SparsePreconditionerNone)
    _ = SparseSolve(method, SparseMatrix_Complex_Double(), DenseVector_Complex_Double(), DenseVector_Complex_Double(), SparseOpaquePreconditioner_Complex_Double())
    _ = SparseSolve(method, { _, _, _, _ in }, DenseMatrix_Complex_Float(), DenseMatrix_Complex_Float())
    _ = SparseSolve(method, { _, _, _, _ in }, DenseMatrix_Complex_Float(), DenseMatrix_Complex_Float(), SparseOpaquePreconditioner_Complex_Float())
    _ = SparseSolve(method, { _, _, _, _ in }, DenseVector_Complex_Float(), DenseVector_Complex_Float())
    _ = SparseSolve(method, { _, _, _, _ in }, DenseVector_Complex_Float(), DenseVector_Complex_Float(), SparseOpaquePreconditioner_Complex_Float())
    _ = SparseSolve(method, { _, _, _, _ in }, DenseMatrix_Complex_Double(), DenseMatrix_Complex_Double())
    _ = SparseSolve(method, { _, _, _, _ in }, DenseMatrix_Complex_Double(), DenseMatrix_Complex_Double(), SparseOpaquePreconditioner_Complex_Double())
    _ = SparseSolve(method, { _, _, _, _ in }, DenseVector_Complex_Double(), DenseVector_Complex_Double())
    _ = SparseSolve(method, { _, _, _, _ in }, DenseVector_Complex_Double(), DenseVector_Complex_Double(), SparseOpaquePreconditioner_Complex_Double())
}

func testSparseFactorSolveFloatVector() {
    var rows: [Int32] = [0, 1]
    var cols: [Int32] = [0, 1]
    var vals: [Float] = [2, 4]
    let A = SparseConvertFromCoordinate(2, 2, 2, 1, SparseAttributes_t(), &rows, &cols, &vals)
    let fact = SparseFactor(SparseFactorizationLU, A)
    var bdata: [Float] = [2, 8]
    var xdata: [Float] = [0, 0]
    let b = DenseVector_Float(count: 2, data: &bdata)
    let x = DenseVector_Float(count: 2, data: &xdata)
    SparseSolve(fact, b, x)
    precondition(abs(xdata[0] - 1) < 0.0001)
    precondition(abs(xdata[1] - 2) < 0.0001)
    var workspace = [UInt8](repeating: 0, count: 8)
    workspace.withUnsafeMutableBytes { raw in
        SparseSolve(fact, b, x, raw.baseAddress!)
    }
    var xb = bdata
    let xbv = DenseVector_Float(count: 2, data: &xb)
    SparseSolve(fact, xbv)
    precondition(abs(xb[0] - 1) < 0.0001)
    workspace.withUnsafeMutableBytes { raw in
        SparseSolve(fact, xbv, raw.baseAddress!)
    }
    SparseCleanup(fact)
    SparseCleanup(A)
}

func testSparseFactorSolveDoubleVector() {
    var rows: [Int32] = [0, 1]
    var cols: [Int32] = [0, 1]
    var vals: [Double] = [3, 5]
    let A = SparseConvertFromCoordinate(2, 2, 2, 1, SparseAttributes_t(), &rows, &cols, &vals)
    let fact = SparseFactor(SparseFactorizationLU, A)
    var bdata: [Double] = [6, 10]
    var xdata: [Double] = [0, 0]
    SparseSolve(fact, DenseVector_Double(count: 2, data: &bdata), DenseVector_Double(count: 2, data: &xdata))
    precondition(abs(xdata[0] - 2) < 1e-12)
    precondition(abs(xdata[1] - 2) < 1e-12)
    var workspace = [UInt8](repeating: 0, count: 8)
    workspace.withUnsafeMutableBytes { raw in
        SparseSolve(fact, DenseVector_Double(count: 2, data: &bdata), DenseVector_Double(count: 2, data: &xdata), raw.baseAddress!)
        SparseSolve(fact, DenseVector_Double(count: 2, data: &xdata), raw.baseAddress!)
    }
    SparseCleanup(fact)
    SparseCleanup(A)
}

func testSparseFactorSolveFloatMatrix() {
    var rows: [Int32] = [0, 1]
    var cols: [Int32] = [0, 1]
    var vals: [Float] = [2, 2]
    let A = SparseConvertFromCoordinate(2, 2, 2, 1, SparseAttributes_t(), &rows, &cols, &vals)
    let options = SparseSymbolicFactorOptions()
    let nf = SparseNumericFactorOptions()
    let fact = SparseFactor(SparseFactorizationLU, A, options, nf)
    var bdata: [Float] = [2, 4, 4, 8]
    var xdata: [Float] = [0, 0, 0, 0]
    let B = DenseMatrix_Float(rowCount: 2, columnCount: 2, columnStride: 2, attributes: SparseAttributes_t(), data: &bdata)
    let X = DenseMatrix_Float(rowCount: 2, columnCount: 2, columnStride: 2, attributes: SparseAttributes_t(), data: &xdata)
    SparseSolve(fact, B, X)
    precondition(abs(xdata[0] - 1) < 0.0001)
    precondition(abs(xdata[1] - 2) < 0.0001)
    var workspace = [UInt8](repeating: 0, count: 8)
    workspace.withUnsafeMutableBytes { raw in
        SparseSolve(fact, B, X, raw.baseAddress!)
    }
    var xb = bdata
    let XB = DenseMatrix_Float(rowCount: 2, columnCount: 2, columnStride: 2, attributes: SparseAttributes_t(), data: &xb)
    SparseSolve(fact, XB)
    workspace.withUnsafeMutableBytes { raw in
        SparseSolve(fact, XB, raw.baseAddress!)
    }
    let symbolic = SparseOpaqueSymbolicFactorization()
    let fact2 = SparseFactor(symbolic, A)
    SparseCleanup(fact2)
    let fact3 = SparseFactor(symbolic, A, nf)
    SparseCleanup(fact3)
    workspace.withUnsafeMutableBytes { raw in
        let fact4 = SparseFactor(symbolic, A, nf, raw.baseAddress, raw.baseAddress)
        SparseCleanup(fact4)
    }
    SparseCleanup(fact)
    SparseCleanup(A)
}

func testSparseFactorSolveDoubleMatrix() {
    var rows: [Int32] = [0, 1]
    var cols: [Int32] = [0, 1]
    var vals: [Double] = [2, 2]
    let A = SparseConvertFromCoordinate(2, 2, 2, 1, SparseAttributes_t(), &rows, &cols, &vals)
    let options = SparseSymbolicFactorOptions()
    let nf = SparseNumericFactorOptions()
    let fact = SparseFactor(SparseFactorizationLU, A, options, nf)
    var bdata: [Double] = [2, 6]
    var xdata: [Double] = [0, 0]
    let B = DenseMatrix_Double(rowCount: 2, columnCount: 1, columnStride: 2, attributes: SparseAttributes_t(), data: &bdata)
    let X = DenseMatrix_Double(rowCount: 2, columnCount: 1, columnStride: 2, attributes: SparseAttributes_t(), data: &xdata)
    SparseSolve(fact, B, X)
    precondition(abs(xdata[0] - 1) < 1e-12)
    precondition(abs(xdata[1] - 3) < 1e-12)
    var workspace = [UInt8](repeating: 0, count: 8)
    workspace.withUnsafeMutableBytes { raw in
        SparseSolve(fact, B, X, raw.baseAddress!)
        SparseSolve(fact, X, raw.baseAddress!)
    }
    let symbolic = SparseOpaqueSymbolicFactorization()
    SparseCleanup(SparseFactor(symbolic, A))
    SparseCleanup(SparseFactor(symbolic, A, nf))
    workspace.withUnsafeMutableBytes { raw in
        SparseCleanup(SparseFactor(symbolic, A, nf, raw.baseAddress, raw.baseAddress))
    }
    SparseCleanup(fact)
    SparseCleanup(A)
}

func testSparseGMRESAndLSMRMethods() {
    let gmres = SparseGMRES()
    precondition(gmres.method == 2)
    _ = SparseGMRES(SparseGMRESOptions())
    let lsmr = SparseLSMR()
    precondition(lsmr.method == 3)
    _ = SparseLSMR(SparseLSMROptions())
}
