import Accelerate
import Foundation

// Subfactor transpose: A = [[2,1],[0,3]] (COO rows [0,0,1], cols [0,1,1],
// vals [2,1,3]). The transposed view wraps a freshly factored T = [[2,0],[1,3]]
// with the same contents selector; T*[1,1] = [2,4] and solving T x = [2,4]
// gives [1,1]. The wrapped factor is freshly owned: clean up result.factor
// (subfactor cleanup itself is a no-op over the non-owning view).

func testSparseSubfactorTranspose() {
    var rowsF: [Int32] = [0, 0, 1]
    var colsF: [Int32] = [0, 1, 1]
    var valsF: [Float] = [2, 1, 3]
    let A = SparseConvertFromCoordinate(2, 2, 3, 1, SparseAttributes_t(), &rowsF, &colsF, &valsF)
    let factF = SparseFactor(SparseFactorizationLU, A)
    let subF = SparseCreateSubfactor(SparseSubfactorL, factF)
    let tSubF = SparseGetTranspose(subF)
    precondition(tSubF.contents == SparseSubfactorL)
    var xF: [Float] = [1, 1]
    var yF: [Float] = [0, 0]
    SparseMultiply(tSubF, DenseVector_Float(count: 2, data: &xF), DenseVector_Float(count: 2, data: &yF))
    precondition(abs(yF[0] - 2) < 0.0001 && abs(yF[1] - 4) < 0.0001)
    var bF: [Float] = [2, 4]
    var sF: [Float] = [0, 0]
    SparseSolve(tSubF, DenseVector_Float(count: 2, data: &bF), DenseVector_Float(count: 2, data: &sF))
    precondition(abs(sF[0] - 1) < 0.0001 && abs(sF[1] - 1) < 0.0001)
    SparseCleanup(tSubF)
    SparseCleanup(tSubF.factor)
    SparseCleanup(subF)
    SparseCleanup(factF)
    SparseCleanup(A)
    var rowsD: [Int32] = [0, 0, 1]
    var colsD: [Int32] = [0, 1, 1]
    var valsD: [Double] = [2, 1, 3]
    let AD = SparseConvertFromCoordinate(2, 2, 3, 1, SparseAttributes_t(), &rowsD, &colsD, &valsD)
    let factD = SparseFactor(SparseFactorizationLU, AD)
    let subD = SparseCreateSubfactor(SparseSubfactorL, factD)
    let tSubD = SparseGetTranspose(subD)
    precondition(tSubD.contents == SparseSubfactorL)
    var xD: [Double] = [1, 1]
    var yD: [Double] = [0, 0]
    SparseMultiply(tSubD, DenseVector_Double(count: 2, data: &xD), DenseVector_Double(count: 2, data: &yD))
    precondition(abs(yD[0] - 2) < 1e-12 && abs(yD[1] - 4) < 1e-12)
    var bD: [Double] = [2, 4]
    var sD: [Double] = [0, 0]
    SparseSolve(tSubD, DenseVector_Double(count: 2, data: &bD), DenseVector_Double(count: 2, data: &sD))
    precondition(abs(sD[0] - 1) < 1e-12 && abs(sD[1] - 1) < 1e-12)
    SparseCleanup(tSubD)
    SparseCleanup(tSubD.factor)
    SparseCleanup(subD)
    SparseCleanup(factD)
    SparseCleanup(AD)
}
