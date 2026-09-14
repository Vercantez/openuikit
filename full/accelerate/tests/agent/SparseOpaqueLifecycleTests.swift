import Accelerate
import Foundation

func testSparseOpaqueCleanupRetain() {
    // Float/Double opaque objects are plain Swift value types holding at most
    // a sentinel pointer, so cleanup is a no-op and retain is the identity.
    var sym = SparseOpaqueSymbolicFactorization(
        status: SparseStatus_t(rawValue: 0),
        rowCount: 2,
        columnCount: 2,
        attributes: SparseAttributes_t(),
        blockSize: 1,
        type: SparseFactorization_t(rawValue: 0),
        factorization: nil,
        workspaceSize_Float: 0,
        workspaceSize_Double: 0,
        factorSize_Float: 0,
        factorSize_Double: 0
    )
    let keptSym = SparseRetain(sym)
    precondition(keptSym.rowCount == 2)
    precondition(keptSym.columnCount == 2)
    precondition(keptSym.blockSize == 1)
    SparseCleanup(sym)
    sym = keptSym
    SparseCleanup(sym)

    // No SparseRetain overload takes a preconditioner; cleanup is a no-op.
    let preD = SparseOpaquePreconditioner_Double()
    let preF = SparseOpaquePreconditioner_Float()
    SparseCleanup(preD)
    SparseCleanup(preF)

    var subD = SparseOpaqueSubfactor_Double()
    var subF = SparseOpaqueSubfactor_Float()
    subD.workspaceRequiredStatic = 7
    subF.workspaceRequiredPerRHS = 9
    let keptSubD = SparseRetain(subD)
    let keptSubF = SparseRetain(subF)
    precondition(keptSubD.workspaceRequiredStatic == 7)
    precondition(keptSubF.workspaceRequiredPerRHS == 9)
    SparseCleanup(subD)
    SparseCleanup(subF)
    subD = keptSubD
    subF = keptSubF
    SparseCleanup(subD)
    SparseCleanup(subF)

    // Retain a real dense-backed factorization: the returned value must carry
    // the same status as the input (value-type identity, shared storage).
    var frows: [Int32] = [0, 1]
    var fcols: [Int32] = [0, 1]
    var fvals: [Float] = [2, 4]
    let fmat = SparseConvertFromCoordinate(2, 2, 2, 1, SparseAttributes_t(), &frows, &fcols, &fvals)
    let factF = SparseFactor(SparseFactorizationLU, fmat)
    let keptFactF = SparseRetain(factF)
    precondition(keptFactF.status == factF.status)
    var drows: [Int32] = [0, 1]
    var dcols: [Int32] = [0, 1]
    var dvals: [Double] = [3, 5]
    let dmat = SparseConvertFromCoordinate(2, 2, 2, 1, SparseAttributes_t(), &drows, &dcols, &dvals)
    let factD = SparseFactor(SparseFactorizationLU, dmat)
    let keptFactD = SparseRetain(factD)
    precondition(keptFactD.status == factD.status)
    SparseCleanup(fmat)
    SparseCleanup(dmat)
}

func testXerblaHandler() {
    // BLAS parameter-error handler: the Linux port has no stderr abort, so it
    // records nothing and returns 0.
    var info: Int32 = -3
    var name: [CChar] = [115, 103, 101, 109, 109, 0]
    let rc = name.withUnsafeMutableBufferPointer { nb in
        withUnsafeMutablePointer(to: &info) { ip in xerbla_(nb.baseAddress, ip) }
    }
    precondition(rc == 0)
    precondition(info == -3)
}
