import Accelerate
import Foundation

// Subfactor coverage uses A = [[2,1],[0,3]] (COO rows [0,0,1], cols [0,1,1],
// vals [2,1,3]). The Linux subfactor is a non-owning view of the parent
// factorization's stored clone and applies the FULL matrix regardless of the
// `contents` selector (documented divergence from Apple's triangular
// extraction; see scratch/oracle-2026-09-14/sparse-subfactor-2026-09-15.txt).

func testSparseSubfactorMultiplyFloat() {
    var rows: [Int32] = [0, 0, 1]
    var cols: [Int32] = [0, 1, 1]
    var vals: [Float] = [2, 1, 3]
    let A = SparseConvertFromCoordinate(2, 2, 3, 1, SparseAttributes_t(), &rows, &cols, &vals)
    let fact = SparseFactor(SparseFactorizationLU, A)
    let sub = SparseCreateSubfactor(SparseSubfactorL, fact)
    precondition(sub.contents == SparseSubfactorL)
    var xdata: [Float] = [1, 1]
    var ydata: [Float] = [0, 0]
    SparseMultiply(sub, DenseVector_Float(count: 2, data: &xdata), DenseVector_Float(count: 2, data: &ydata))
    precondition(abs(ydata[0] - 3) < 0.0001 && abs(ydata[1] - 3) < 0.0001)
    var workspace = [UInt8](repeating: 0, count: 8)
    var yws: [Float] = [0, 0]
    workspace.withUnsafeMutableBytes { raw in
        SparseMultiply(sub, DenseVector_Float(count: 2, data: &xdata), DenseVector_Float(count: 2, data: &yws), raw.baseAddress!)
    }
    precondition(abs(yws[0] - 3) < 0.0001 && abs(yws[1] - 3) < 0.0001)
    var xyb: [Float] = [1, 1]
    SparseMultiply(sub, DenseVector_Float(count: 2, data: &xyb))
    precondition(abs(xyb[0] - 3) < 0.0001 && abs(xyb[1] - 3) < 0.0001)
    var xyw: [Float] = [1, 1]
    workspace.withUnsafeMutableBytes { raw in
        SparseMultiply(sub, DenseVector_Float(count: 2, data: &xyw), raw.baseAddress!)
    }
    precondition(abs(xyw[0] - 3) < 0.0001 && abs(xyw[1] - 3) < 0.0001)
    var xm: [Float] = [1, 1]
    var ym: [Float] = [0, 0]
    SparseMultiply(
        sub,
        DenseMatrix_Float(rowCount: 2, columnCount: 1, columnStride: 2, attributes: SparseAttributes_t(), data: &xm),
        DenseMatrix_Float(rowCount: 2, columnCount: 1, columnStride: 2, attributes: SparseAttributes_t(), data: &ym)
    )
    precondition(abs(ym[0] - 3) < 0.0001 && abs(ym[1] - 3) < 0.0001)
    var ymw: [Float] = [0, 0]
    workspace.withUnsafeMutableBytes { raw in
        SparseMultiply(
            sub,
            DenseMatrix_Float(rowCount: 2, columnCount: 1, columnStride: 2, attributes: SparseAttributes_t(), data: &xm),
            DenseMatrix_Float(rowCount: 2, columnCount: 1, columnStride: 2, attributes: SparseAttributes_t(), data: &ymw),
            raw.baseAddress!
        )
    }
    precondition(abs(ymw[0] - 3) < 0.0001 && abs(ymw[1] - 3) < 0.0001)
    var xymb: [Float] = [1, 1]
    SparseMultiply(sub, DenseMatrix_Float(rowCount: 2, columnCount: 1, columnStride: 2, attributes: SparseAttributes_t(), data: &xymb))
    precondition(abs(xymb[0] - 3) < 0.0001 && abs(xymb[1] - 3) < 0.0001)
    var xymw: [Float] = [1, 1]
    workspace.withUnsafeMutableBytes { raw in
        SparseMultiply(sub, DenseMatrix_Float(rowCount: 2, columnCount: 1, columnStride: 2, attributes: SparseAttributes_t(), data: &xymw), raw.baseAddress!)
    }
    precondition(abs(xymw[0] - 3) < 0.0001 && abs(xymw[1] - 3) < 0.0001)
    SparseCleanup(sub)
    SparseCleanup(fact)
    SparseCleanup(A)
}

func testSparseSubfactorMultiplyDouble() {
    var rows: [Int32] = [0, 0, 1]
    var cols: [Int32] = [0, 1, 1]
    var vals: [Double] = [2, 1, 3]
    let A = SparseConvertFromCoordinate(2, 2, 3, 1, SparseAttributes_t(), &rows, &cols, &vals)
    let fact = SparseFactor(SparseFactorizationLU, A)
    let sub = SparseCreateSubfactor(SparseSubfactorL, fact)
    precondition(sub.contents == SparseSubfactorL)
    var xdata: [Double] = [1, 1]
    var ydata: [Double] = [0, 0]
    SparseMultiply(sub, DenseVector_Double(count: 2, data: &xdata), DenseVector_Double(count: 2, data: &ydata))
    precondition(abs(ydata[0] - 3) < 1e-12 && abs(ydata[1] - 3) < 1e-12)
    var workspace = [UInt8](repeating: 0, count: 8)
    var yws: [Double] = [0, 0]
    workspace.withUnsafeMutableBytes { raw in
        SparseMultiply(sub, DenseVector_Double(count: 2, data: &xdata), DenseVector_Double(count: 2, data: &yws), raw.baseAddress!)
    }
    precondition(abs(yws[0] - 3) < 1e-12 && abs(yws[1] - 3) < 1e-12)
    var xyb: [Double] = [1, 1]
    SparseMultiply(sub, DenseVector_Double(count: 2, data: &xyb))
    precondition(abs(xyb[0] - 3) < 1e-12 && abs(xyb[1] - 3) < 1e-12)
    var xyw: [Double] = [1, 1]
    workspace.withUnsafeMutableBytes { raw in
        SparseMultiply(sub, DenseVector_Double(count: 2, data: &xyw), raw.baseAddress!)
    }
    precondition(abs(xyw[0] - 3) < 1e-12 && abs(xyw[1] - 3) < 1e-12)
    var xm: [Double] = [1, 1]
    var ym: [Double] = [0, 0]
    SparseMultiply(
        sub,
        DenseMatrix_Double(rowCount: 2, columnCount: 1, columnStride: 2, attributes: SparseAttributes_t(), data: &xm),
        DenseMatrix_Double(rowCount: 2, columnCount: 1, columnStride: 2, attributes: SparseAttributes_t(), data: &ym)
    )
    precondition(abs(ym[0] - 3) < 1e-12 && abs(ym[1] - 3) < 1e-12)
    var ymw: [Double] = [0, 0]
    workspace.withUnsafeMutableBytes { raw in
        SparseMultiply(
            sub,
            DenseMatrix_Double(rowCount: 2, columnCount: 1, columnStride: 2, attributes: SparseAttributes_t(), data: &xm),
            DenseMatrix_Double(rowCount: 2, columnCount: 1, columnStride: 2, attributes: SparseAttributes_t(), data: &ymw),
            raw.baseAddress!
        )
    }
    precondition(abs(ymw[0] - 3) < 1e-12 && abs(ymw[1] - 3) < 1e-12)
    var xymb: [Double] = [1, 1]
    SparseMultiply(sub, DenseMatrix_Double(rowCount: 2, columnCount: 1, columnStride: 2, attributes: SparseAttributes_t(), data: &xymb))
    precondition(abs(xymb[0] - 3) < 1e-12 && abs(xymb[1] - 3) < 1e-12)
    var xymw: [Double] = [1, 1]
    workspace.withUnsafeMutableBytes { raw in
        SparseMultiply(sub, DenseMatrix_Double(rowCount: 2, columnCount: 1, columnStride: 2, attributes: SparseAttributes_t(), data: &xymw), raw.baseAddress!)
    }
    precondition(abs(xymw[0] - 3) < 1e-12 && abs(xymw[1] - 3) < 1e-12)
    SparseCleanup(sub)
    SparseCleanup(fact)
    SparseCleanup(A)
}

func testSparseSubfactorSolveFloat() {
    var rows: [Int32] = [0, 0, 1]
    var cols: [Int32] = [0, 1, 1]
    var vals: [Float] = [2, 1, 3]
    let A = SparseConvertFromCoordinate(2, 2, 3, 1, SparseAttributes_t(), &rows, &cols, &vals)
    let fact = SparseFactor(SparseFactorizationLU, A)
    let sub = SparseCreateSubfactor(SparseSubfactorL, fact)
    // A x = [3,3] -> x = [1,1]
    var bdata: [Float] = [3, 3]
    var xdata: [Float] = [0, 0]
    SparseSolve(sub, DenseVector_Float(count: 2, data: &bdata), DenseVector_Float(count: 2, data: &xdata))
    precondition(abs(xdata[0] - 1) < 0.0001 && abs(xdata[1] - 1) < 0.0001)
    var workspace = [UInt8](repeating: 0, count: 8)
    var xws: [Float] = [0, 0]
    workspace.withUnsafeMutableBytes { raw in
        SparseSolve(sub, DenseVector_Float(count: 2, data: &bdata), DenseVector_Float(count: 2, data: &xws), raw.baseAddress!)
    }
    precondition(abs(xws[0] - 1) < 0.0001 && abs(xws[1] - 1) < 0.0001)
    var xb: [Float] = [3, 3]
    SparseSolve(sub, DenseVector_Float(count: 2, data: &xb))
    precondition(abs(xb[0] - 1) < 0.0001 && abs(xb[1] - 1) < 0.0001)
    var xbw: [Float] = [3, 3]
    workspace.withUnsafeMutableBytes { raw in
        SparseSolve(sub, DenseVector_Float(count: 2, data: &xbw), raw.baseAddress!)
    }
    precondition(abs(xbw[0] - 1) < 0.0001 && abs(xbw[1] - 1) < 0.0001)
    var bm: [Float] = [3, 3]
    var xm: [Float] = [0, 0]
    SparseSolve(
        sub,
        DenseMatrix_Float(rowCount: 2, columnCount: 1, columnStride: 2, attributes: SparseAttributes_t(), data: &bm),
        DenseMatrix_Float(rowCount: 2, columnCount: 1, columnStride: 2, attributes: SparseAttributes_t(), data: &xm)
    )
    precondition(abs(xm[0] - 1) < 0.0001 && abs(xm[1] - 1) < 0.0001)
    var xmw: [Float] = [0, 0]
    workspace.withUnsafeMutableBytes { raw in
        SparseSolve(
            sub,
            DenseMatrix_Float(rowCount: 2, columnCount: 1, columnStride: 2, attributes: SparseAttributes_t(), data: &bm),
            DenseMatrix_Float(rowCount: 2, columnCount: 1, columnStride: 2, attributes: SparseAttributes_t(), data: &xmw),
            raw.baseAddress!
        )
    }
    precondition(abs(xmw[0] - 1) < 0.0001 && abs(xmw[1] - 1) < 0.0001)
    var xbm: [Float] = [3, 3]
    SparseSolve(sub, DenseMatrix_Float(rowCount: 2, columnCount: 1, columnStride: 2, attributes: SparseAttributes_t(), data: &xbm))
    precondition(abs(xbm[0] - 1) < 0.0001 && abs(xbm[1] - 1) < 0.0001)
    var xbmw: [Float] = [3, 3]
    workspace.withUnsafeMutableBytes { raw in
        SparseSolve(sub, DenseMatrix_Float(rowCount: 2, columnCount: 1, columnStride: 2, attributes: SparseAttributes_t(), data: &xbmw), raw.baseAddress!)
    }
    precondition(abs(xbmw[0] - 1) < 0.0001 && abs(xbmw[1] - 1) < 0.0001)
    SparseCleanup(sub)
    SparseCleanup(fact)
    SparseCleanup(A)
}

func testSparseSubfactorSolveDouble() {
    var rows: [Int32] = [0, 0, 1]
    var cols: [Int32] = [0, 1, 1]
    var vals: [Double] = [2, 1, 3]
    let A = SparseConvertFromCoordinate(2, 2, 3, 1, SparseAttributes_t(), &rows, &cols, &vals)
    let fact = SparseFactor(SparseFactorizationLU, A)
    let sub = SparseCreateSubfactor(SparseSubfactorL, fact)
    var bdata: [Double] = [3, 3]
    var xdata: [Double] = [0, 0]
    SparseSolve(sub, DenseVector_Double(count: 2, data: &bdata), DenseVector_Double(count: 2, data: &xdata))
    precondition(abs(xdata[0] - 1) < 1e-12 && abs(xdata[1] - 1) < 1e-12)
    var workspace = [UInt8](repeating: 0, count: 8)
    var xws: [Double] = [0, 0]
    workspace.withUnsafeMutableBytes { raw in
        SparseSolve(sub, DenseVector_Double(count: 2, data: &bdata), DenseVector_Double(count: 2, data: &xws), raw.baseAddress!)
    }
    precondition(abs(xws[0] - 1) < 1e-12 && abs(xws[1] - 1) < 1e-12)
    var xb: [Double] = [3, 3]
    SparseSolve(sub, DenseVector_Double(count: 2, data: &xb))
    precondition(abs(xb[0] - 1) < 1e-12 && abs(xb[1] - 1) < 1e-12)
    var xbw: [Double] = [3, 3]
    workspace.withUnsafeMutableBytes { raw in
        SparseSolve(sub, DenseVector_Double(count: 2, data: &xbw), raw.baseAddress!)
    }
    precondition(abs(xbw[0] - 1) < 1e-12 && abs(xbw[1] - 1) < 1e-12)
    var bm: [Double] = [3, 3]
    var xm: [Double] = [0, 0]
    SparseSolve(
        sub,
        DenseMatrix_Double(rowCount: 2, columnCount: 1, columnStride: 2, attributes: SparseAttributes_t(), data: &bm),
        DenseMatrix_Double(rowCount: 2, columnCount: 1, columnStride: 2, attributes: SparseAttributes_t(), data: &xm)
    )
    precondition(abs(xm[0] - 1) < 1e-12 && abs(xm[1] - 1) < 1e-12)
    var xmw: [Double] = [0, 0]
    workspace.withUnsafeMutableBytes { raw in
        SparseSolve(
            sub,
            DenseMatrix_Double(rowCount: 2, columnCount: 1, columnStride: 2, attributes: SparseAttributes_t(), data: &bm),
            DenseMatrix_Double(rowCount: 2, columnCount: 1, columnStride: 2, attributes: SparseAttributes_t(), data: &xmw),
            raw.baseAddress!
        )
    }
    precondition(abs(xmw[0] - 1) < 1e-12 && abs(xmw[1] - 1) < 1e-12)
    var xbm: [Double] = [3, 3]
    SparseSolve(sub, DenseMatrix_Double(rowCount: 2, columnCount: 1, columnStride: 2, attributes: SparseAttributes_t(), data: &xbm))
    precondition(abs(xbm[0] - 1) < 1e-12 && abs(xbm[1] - 1) < 1e-12)
    var xbmw: [Double] = [3, 3]
    workspace.withUnsafeMutableBytes { raw in
        SparseSolve(sub, DenseMatrix_Double(rowCount: 2, columnCount: 1, columnStride: 2, attributes: SparseAttributes_t(), data: &xbmw), raw.baseAddress!)
    }
    precondition(abs(xbmw[0] - 1) < 1e-12 && abs(xbmw[1] - 1) < 1e-12)
    SparseCleanup(sub)
    SparseCleanup(fact)
    SparseCleanup(A)
}

func testSparseRefactorUpdateFloatDouble() {
    var workspace = [UInt8](repeating: 0, count: 8)
    let nf = SparseNumericFactorOptions()
    // Float: factor diag(2,3), refactor to diag(4,5) through every overload.
    var rowsF: [Int32] = [0, 1]
    var colsF: [Int32] = [0, 1]
    var valsF: [Float] = [2, 3]
    let oldF = SparseConvertFromCoordinate(2, 2, 2, 1, SparseAttributes_t(), &rowsF, &colsF, &valsF)
    var newValsF: [Float] = [4, 5]
    let newF = SparseConvertFromCoordinate(2, 2, 2, 1, SparseAttributes_t(), &rowsF, &colsF, &newValsF)
    var factF = SparseFactor(SparseFactorizationLU, oldF)
    SparseRefactor(newF, &factF)
    SparseRefactor(newF, &factF, nf)
    workspace.withUnsafeMutableBytes { raw in
        SparseRefactor(newF, &factF, nf, raw.baseAddress!)
        SparseRefactor(newF, &factF, raw.baseAddress!)
    }
    var bF: [Float] = [8, 10]
    var xF: [Float] = [0, 0]
    SparseSolve(factF, DenseVector_Float(count: 2, data: &bF), DenseVector_Float(count: 2, data: &xF))
    precondition(abs(xF[0] - 2) < 0.0001 && abs(xF[1] - 2) < 0.0001)
    var updValsF: [Float] = [8, 10]
    let updF = SparseConvertFromCoordinate(2, 2, 2, 1, SparseAttributes_t(), &rowsF, &colsF, &updValsF)
    var updIdx: [Int32] = [0, 1]
    SparseUpdateFactor(SparseUpdatePartialRefactor, &factF, 2, &updIdx, updF)
    var bF2: [Float] = [16, 30]
    var xF2: [Float] = [0, 0]
    SparseSolve(factF, DenseVector_Float(count: 2, data: &bF2), DenseVector_Float(count: 2, data: &xF2))
    precondition(abs(xF2[0] - 2) < 0.0001 && abs(xF2[1] - 3) < 0.0001)
    SparseCleanup(factF)
    SparseCleanup(updF)
    SparseCleanup(newF)
    SparseCleanup(oldF)
    // Double: same shape with diag(3,5) -> diag(7,11) -> update diag(7,11).
    var rowsD: [Int32] = [0, 1]
    var colsD: [Int32] = [0, 1]
    var valsD: [Double] = [3, 5]
    let oldD = SparseConvertFromCoordinate(2, 2, 2, 1, SparseAttributes_t(), &rowsD, &colsD, &valsD)
    var newValsD: [Double] = [7, 11]
    let newD = SparseConvertFromCoordinate(2, 2, 2, 1, SparseAttributes_t(), &rowsD, &colsD, &newValsD)
    var factD = SparseFactor(SparseFactorizationLU, oldD)
    SparseRefactor(newD, &factD)
    SparseRefactor(newD, &factD, nf)
    workspace.withUnsafeMutableBytes { raw in
        SparseRefactor(newD, &factD, nf, raw.baseAddress!)
        SparseRefactor(newD, &factD, raw.baseAddress!)
    }
    var bD: [Double] = [14, 33]
    var xD: [Double] = [0, 0]
    SparseSolve(factD, DenseVector_Double(count: 2, data: &bD), DenseVector_Double(count: 2, data: &xD))
    precondition(abs(xD[0] - 2) < 1e-12 && abs(xD[1] - 3) < 1e-12)
    var updValsD: [Double] = [21, 22]
    let updD = SparseConvertFromCoordinate(2, 2, 2, 1, SparseAttributes_t(), &rowsD, &colsD, &updValsD)
    SparseUpdateFactor(SparseUpdatePartialRefactor, &factD, 2, &updIdx, updD)
    var bD2: [Double] = [42, 66]
    var xD2: [Double] = [0, 0]
    SparseSolve(factD, DenseVector_Double(count: 2, data: &bD2), DenseVector_Double(count: 2, data: &xD2))
    precondition(abs(xD2[0] - 2) < 1e-12 && abs(xD2[1] - 3) < 1e-12)
    SparseCleanup(factD)
    SparseCleanup(updD)
    SparseCleanup(newD)
    SparseCleanup(oldD)
}

func testSparseGetTransposeFloatDouble() {
    var rowsF: [Int32] = [0, 0, 1]
    var colsF: [Int32] = [0, 1, 1]
    var valsF: [Float] = [2, 1, 3]
    let A = SparseConvertFromCoordinate(2, 2, 3, 1, SparseAttributes_t(), &rowsF, &colsF, &valsF)
    // T = [[2,0],[1,3]]; T*[1,1] = [2,4] (matches the macOS 26.1 oracle).
    let T = SparseGetTranspose(A)
    precondition(T.structure.rowCount == 2 && T.structure.columnCount == 2)
    var xF: [Float] = [1, 1]
    var yF: [Float] = [0, 0]
    SparseMultiply(T, DenseVector_Float(count: 2, data: &xF), DenseVector_Float(count: 2, data: &yF))
    precondition(abs(yF[0] - 2) < 0.0001 && abs(yF[1] - 4) < 0.0001)
    let factF = SparseFactor(SparseFactorizationLU, A)
    let fT = SparseGetTranspose(factF)
    var bF: [Float] = [2, 4]
    var xT: [Float] = [0, 0]
    SparseSolve(fT, DenseVector_Float(count: 2, data: &bF), DenseVector_Float(count: 2, data: &xT))
    precondition(abs(xT[0] - 1) < 0.0001 && abs(xT[1] - 1) < 0.0001)
    SparseCleanup(fT)
    SparseCleanup(factF)
    SparseCleanup(T)
    SparseCleanup(A)
    var rowsD: [Int32] = [0, 0, 1]
    var colsD: [Int32] = [0, 1, 1]
    var valsD: [Double] = [2, 1, 3]
    let AD = SparseConvertFromCoordinate(2, 2, 3, 1, SparseAttributes_t(), &rowsD, &colsD, &valsD)
    let TD = SparseGetTranspose(AD)
    var xD: [Double] = [1, 1]
    var yD: [Double] = [0, 0]
    SparseMultiply(TD, DenseVector_Double(count: 2, data: &xD), DenseVector_Double(count: 2, data: &yD))
    precondition(abs(yD[0] - 2) < 1e-12 && abs(yD[1] - 4) < 1e-12)
    let factD = SparseFactor(SparseFactorizationLU, AD)
    let fTD = SparseGetTranspose(factD)
    var bD: [Double] = [2, 4]
    var xTD: [Double] = [0, 0]
    SparseSolve(fTD, DenseVector_Double(count: 2, data: &bD), DenseVector_Double(count: 2, data: &xTD))
    precondition(abs(xTD[0] - 1) < 1e-12 && abs(xTD[1] - 1) < 1e-12)
    SparseCleanup(fTD)
    SparseCleanup(factD)
    SparseCleanup(TD)
    SparseCleanup(AD)
}

func testSparseSymbolicStateSize() {
    var rows: [Int32] = [0, 1]
    var cols: [Int32] = [0, 1]
    var vals: [Float] = [2, 3]
    let A = SparseConvertFromCoordinate(2, 2, 2, 1, SparseAttributes_t(), &rows, &cols, &vals)
    let sym1 = SparseFactor(SparseFactorizationLU, A.structure)
    precondition(sym1.rowCount == 2 && sym1.columnCount == 2)
    precondition(sym1.type == SparseFactorizationLU && sym1.status == SparseStatusOK)
    let sym2 = SparseFactor(SparseFactorizationLU, A.structure, SparseSymbolicFactorOptions())
    precondition(sym2.rowCount == 2 && sym2.columnCount == 2)
    precondition(sym2.type == SparseFactorizationLU && sym2.status == SparseStatusOK)
    // The Linux dense path keeps no iterate state (Apple reports 20 bytes).
    let sF = SparseGetStateSize_Float(SparseConjugateGradient(), false, 2, 2, 1)
    precondition(sF == 0)
    let sD = SparseGetStateSize_Double(SparseConjugateGradient(), true, 2, 2, 1)
    precondition(sD == 0)
    SparseCleanup(sym1)
    SparseCleanup(sym2)
    SparseCleanup(A)
}

func testSparseInertiaFloatDouble() {
    var rowsF: [Int32] = [0, 1]
    var colsF: [Int32] = [0, 1]
    var valsF: [Float] = [2, -3]
    let S = SparseConvertFromCoordinate(2, 2, 2, 1, SparseAttributes_t(), &rowsF, &colsF, &valsF)
    let factF = SparseFactor(SparseFactorizationLDLT, S)
    var pF: Int32 = -1
    var zF: Int32 = -1
    var nF: Int32 = -1
    let stF = SparseGetInertia(factF, &pF, &zF, &nF)
    precondition(stF == 0 && pF == 1 && zF == 0 && nF == 1)
    SparseCleanup(factF)
    SparseCleanup(S)
    var rowsD: [Int32] = [0, 0, 1, 1]
    var colsD: [Int32] = [0, 1, 0, 1]
    var valsD: [Double] = [4, 1, 1, 3]
    let SD = SparseConvertFromCoordinate(2, 2, 4, 1, SparseAttributes_t(), &rowsD, &colsD, &valsD)
    let factD = SparseFactor(SparseFactorizationLDLT, SD)
    var pD: Int32 = -1
    var zD: Int32 = -1
    var nD: Int32 = -1
    let stD = SparseGetInertia(factD, &pD, &zD, &nD)
    precondition(stD == 0 && pD == 2 && zD == 0 && nD == 0)
    SparseCleanup(factD)
    SparseCleanup(SD)
}

func testSparseSubfactorPreconditionerLifecycle() {
    var rowsF: [Int32] = [0, 1]
    var colsF: [Int32] = [0, 1]
    var valsF: [Float] = [2, 3]
    let AF = SparseConvertFromCoordinate(2, 2, 2, 1, SparseAttributes_t(), &rowsF, &colsF, &valsF)
    let factF = SparseFactor(SparseFactorizationLU, AF)
    let subF = SparseCreateSubfactor(SparseSubfactorL, factF)
    precondition(subF.contents == SparseSubfactorL)
    let preF = SparseCreatePreconditioner(SparsePreconditionerDiagonal, AF)
    precondition(preF.type == SparsePreconditionerDiagonal)
    SparseCleanup(subF)
    SparseCleanup(preF)
    SparseCleanup(factF)
    SparseCleanup(AF)
    var rowsD: [Int32] = [0, 1]
    var colsD: [Int32] = [0, 1]
    var valsD: [Double] = [2, 3]
    let AD = SparseConvertFromCoordinate(2, 2, 2, 1, SparseAttributes_t(), &rowsD, &colsD, &valsD)
    let factD = SparseFactor(SparseFactorizationLU, AD)
    let subD = SparseCreateSubfactor(SparseSubfactorD, factD)
    precondition(subD.contents == SparseSubfactorD)
    let preD = SparseCreatePreconditioner(SparsePreconditionerDiagonal, AD)
    precondition(preD.type == SparsePreconditionerDiagonal)
    SparseCleanup(subD)
    SparseCleanup(preD)
    SparseCleanup(factD)
    SparseCleanup(AD)
}
