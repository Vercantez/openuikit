import Accelerate
import Foundation

// Fail-closed complex sparse coverage: every complex overload below is an
// explicit Linux stub (empty body, default value, or parameter-error status).
// These tests pin that behavior without inventing Apple numerics.

func testSparseComplexCleanupRetain() {
    let mcd = SparseMatrix_Complex_Double()
    let mcf = SparseMatrix_Complex_Float()
    SparseCleanup(mcd)
    SparseCleanup(mcf)
    let fcd = SparseOpaqueFactorization_Complex_Double()
    let fcf = SparseOpaqueFactorization_Complex_Float()
    SparseCleanup(fcd)
    SparseCleanup(fcf)
    let pcd = SparseOpaquePreconditioner_Complex_Double()
    let pcf = SparseOpaquePreconditioner_Complex_Float()
    SparseCleanup(pcd)
    SparseCleanup(pcf)
    let scd = SparseOpaqueSubfactor_Complex_Double()
    let scf = SparseOpaqueSubfactor_Complex_Float()
    SparseCleanup(scd)
    SparseCleanup(scf)
    _ = SparseRetain(fcd)
    _ = SparseRetain(fcf)
    _ = SparseRetain(scd)
    _ = SparseRetain(scf)
    precondition(mcd.structure.rowCount == 0)
    precondition(mcf.structure.rowCount == 0)
    precondition(fcd.status.rawValue == 0)
    precondition(scd.contents.rawValue == 0)
}

func testSparseComplexFactorCreate() {
    let kind = SparseFactorization_t(rawValue: 0)
    let symOpts = SparseSymbolicFactorOptions()
    let numOpts = SparseNumericFactorOptions()
    let structure = SparseMatrixStructureComplex()
    let attributes = SparseAttributesComplex_t()
    precondition(structure.rowCount == 0)
    precondition(attributes.transpose == false)
    _ = SparseFactor(kind, SparseMatrixStructureComplex())
    _ = SparseFactor(kind, SparseMatrixStructureComplex(), symOpts)
    _ = SparseFactor(kind, SparseMatrix_Complex_Double())
    _ = SparseFactor(kind, SparseMatrix_Complex_Double(), symOpts, numOpts)
    _ = SparseFactor(kind, SparseMatrix_Complex_Float())
    _ = SparseFactor(kind, SparseMatrix_Complex_Float(), symOpts, numOpts)
    let sym = SparseOpaqueSymbolicFactorization()
    _ = SparseFactor(sym, SparseMatrix_Complex_Double())
    _ = SparseFactor(sym, SparseMatrix_Complex_Double(), numOpts)
    _ = SparseFactor(sym, SparseMatrix_Complex_Double(), numOpts, nil, nil)
    _ = SparseFactor(sym, SparseMatrix_Complex_Float())
    _ = SparseFactor(sym, SparseMatrix_Complex_Float(), numOpts)
    _ = SparseFactor(sym, SparseMatrix_Complex_Float(), numOpts, nil, nil)
    let preKind = SparsePreconditioner_t(rawValue: 0)
    _ = SparseCreatePreconditioner(preKind, SparseMatrix_Complex_Double())
    _ = SparseCreatePreconditioner(preKind, SparseMatrix_Complex_Float())
    let subKind = SparseSubfactor_t(rawValue: 0)
    _ = SparseCreateSubfactor(subKind, SparseOpaqueFactorization_Complex_Double())
    _ = SparseCreateSubfactor(subKind, SparseOpaqueFactorization_Complex_Float())
}

func testSparseComplexMultiply() {
    let aCD = SparseMatrix_Complex_Double()
    let xCD = DenseMatrix_Complex_Double()
    let yCD = DenseMatrix_Complex_Double()
    SparseMultiply(aCD, xCD, yCD)
    let vCD = DenseVector_Complex_Double()
    let wCD = DenseVector_Complex_Double()
    SparseMultiply(aCD, vCD, wCD)
    let aCF = SparseMatrix_Complex_Float()
    let xCF = DenseMatrix_Complex_Float()
    let yCF = DenseMatrix_Complex_Float()
    SparseMultiply(aCF, xCF, yCF)
    let vCF = DenseVector_Complex_Float()
    let wCF = DenseVector_Complex_Float()
    SparseMultiply(aCF, vCF, wCF)
    SparseMultiplyAdd(aCD, xCD, yCD)
    SparseMultiplyAdd(aCD, vCD, wCD)
    SparseMultiplyAdd(aCF, xCF, yCF)
    SparseMultiplyAdd(aCF, vCF, wCF)
    let ws = UnsafeMutableRawPointer.allocate(byteCount: 16, alignment: 8)
    defer { ws.deallocate() }
    let subCD = SparseOpaqueSubfactor_Complex_Double()
    SparseMultiply(subCD, xCD)
    SparseMultiply(subCD, xCD, ws)
    SparseMultiply(subCD, xCD, yCD)
    SparseMultiply(subCD, xCD, yCD, ws)
    SparseMultiply(subCD, vCD)
    SparseMultiply(subCD, vCD, ws)
    SparseMultiply(subCD, vCD, wCD)
    SparseMultiply(subCD, vCD, wCD, ws)
    let subCF = SparseOpaqueSubfactor_Complex_Float()
    SparseMultiply(subCF, xCF)
    SparseMultiply(subCF, xCF, ws)
    SparseMultiply(subCF, xCF, yCF)
    SparseMultiply(subCF, xCF, yCF, ws)
    SparseMultiply(subCF, vCF)
    SparseMultiply(subCF, vCF, ws)
    SparseMultiply(subCF, vCF, wCF)
    SparseMultiply(subCF, vCF, wCF, ws)
    precondition(xCD.rowCount == 0)
    precondition(vCF.count == 0)
}

func testSparseComplexSolve() {
    let fcd = SparseOpaqueFactorization_Complex_Double()
    let mCD = DenseMatrix_Complex_Double()
    let nCD = DenseMatrix_Complex_Double()
    SparseSolve(fcd, mCD)
    let ws = UnsafeMutableRawPointer.allocate(byteCount: 16, alignment: 8)
    defer { ws.deallocate() }
    SparseSolve(fcd, mCD, ws)
    SparseSolve(fcd, mCD, nCD)
    SparseSolve(fcd, mCD, nCD, ws)
    let vCD = DenseVector_Complex_Double()
    let wCD = DenseVector_Complex_Double()
    SparseSolve(fcd, vCD)
    SparseSolve(fcd, vCD, ws)
    SparseSolve(fcd, vCD, wCD)
    SparseSolve(fcd, vCD, wCD, ws)
    let fcf = SparseOpaqueFactorization_Complex_Float()
    let mCF = DenseMatrix_Complex_Float()
    let nCF = DenseMatrix_Complex_Float()
    SparseSolve(fcf, mCF)
    SparseSolve(fcf, mCF, ws)
    SparseSolve(fcf, mCF, nCF)
    SparseSolve(fcf, mCF, nCF, ws)
    let vCF = DenseVector_Complex_Float()
    let wCF = DenseVector_Complex_Float()
    SparseSolve(fcf, vCF)
    SparseSolve(fcf, vCF, ws)
    SparseSolve(fcf, vCF, wCF)
    SparseSolve(fcf, vCF, wCF, ws)
    let scd = SparseOpaqueSubfactor_Complex_Double()
    SparseSolve(scd, mCD)
    SparseSolve(scd, mCD, ws)
    SparseSolve(scd, mCD, nCD)
    SparseSolve(scd, mCD, nCD, ws)
    SparseSolve(scd, vCD)
    SparseSolve(scd, vCD, ws)
    SparseSolve(scd, vCD, wCD)
    SparseSolve(scd, vCD, wCD, ws)
    let scf = SparseOpaqueSubfactor_Complex_Float()
    SparseSolve(scf, mCF)
    SparseSolve(scf, mCF, ws)
    SparseSolve(scf, mCF, nCF)
    SparseSolve(scf, mCF, nCF, ws)
    SparseSolve(scf, vCF)
    SparseSolve(scf, vCF, ws)
    SparseSolve(scf, vCF, wCF)
    SparseSolve(scf, vCF, wCF, ws)
}

func testSparseComplexRefactorTranspose() {
    let numOpts = SparseNumericFactorOptions()
    let ws = UnsafeMutableRawPointer.allocate(byteCount: 16, alignment: 8)
    defer { ws.deallocate() }
    var fcd = SparseOpaqueFactorization_Complex_Double()
    SparseRefactor(SparseMatrix_Complex_Double(), &fcd)
    SparseRefactor(SparseMatrix_Complex_Double(), &fcd, numOpts)
    SparseRefactor(SparseMatrix_Complex_Double(), &fcd, numOpts, ws)
    SparseRefactor(SparseMatrix_Complex_Double(), &fcd, ws)
    var fcf = SparseOpaqueFactorization_Complex_Float()
    SparseRefactor(SparseMatrix_Complex_Float(), &fcf)
    SparseRefactor(SparseMatrix_Complex_Float(), &fcf, numOpts)
    SparseRefactor(SparseMatrix_Complex_Float(), &fcf, numOpts, ws)
    SparseRefactor(SparseMatrix_Complex_Float(), &fcf, ws)
    _ = SparseGetTranspose(SparseMatrix_Complex_Double())
    _ = SparseGetTranspose(SparseMatrix_Complex_Float())
    _ = SparseGetTranspose(fcd)
    _ = SparseGetTranspose(fcf)
    _ = SparseGetTranspose(SparseOpaqueSubfactor_Complex_Double())
    _ = SparseGetTranspose(SparseOpaqueSubfactor_Complex_Float())
    _ = SparseGetConjugateTranspose(SparseMatrix_Complex_Double())
    _ = SparseGetConjugateTranspose(SparseMatrix_Complex_Float())
    _ = SparseGetConjugateTranspose(fcd)
    _ = SparseGetConjugateTranspose(fcf)
    _ = SparseGetConjugateTranspose(SparseOpaqueSubfactor_Complex_Double())
    _ = SparseGetConjugateTranspose(SparseOpaqueSubfactor_Complex_Float())
    let idx: [Int32] = [0]
    SparseUpdateFactor(SparseUpdate_t(rawValue: 0), &fcd, 0, idx, SparseMatrix_Complex_Double())
    SparseUpdateFactor(SparseUpdate_t(rawValue: 0), &fcf, 0, idx, SparseMatrix_Complex_Float())
    let method = SparseIterativeMethod()
    precondition(SparseGetStateSize_Complex_Double(method, false, 0, 0, 0) == 0)
    precondition(SparseGetStateSize_Complex_Float(method, false, 0, 0, 0) == 0)
}

func testSparseComplexStructInits() {
    let dataPtr = OpaquePointer(bitPattern: 1)!
    let cAttrs = SparseAttributesComplex_t()
    _ = cAttrs
    let dmCD = DenseMatrix_Complex_Double(
        rowCount: 2, columnCount: 2, columnStride: 2, attributes: cAttrs, data: dataPtr
    )
    precondition(dmCD.rowCount == 2)
    let dmCF = DenseMatrix_Complex_Float(
        rowCount: 2, columnCount: 2, columnStride: 2, attributes: cAttrs, data: dataPtr
    )
    precondition(dmCF.columnCount == 2)
    let dvCD = DenseVector_Complex_Double(count: 2, data: dataPtr)
    precondition(dvCD.count == 2)
    let dvCF = DenseVector_Complex_Float(count: 2, data: dataPtr)
    precondition(dvCF.count == 2)
    let starts = UnsafeMutablePointer<Int>.allocate(capacity: 1)
    let indices = UnsafeMutablePointer<Int32>.allocate(capacity: 1)
    starts.initialize(to: 0)
    indices.initialize(to: 0)
    let structure = SparseMatrixStructureComplex(
        rowCount: 1, columnCount: 1, columnStarts: starts, rowIndices: indices,
        attributes: cAttrs, blockSize: 1
    )
    precondition(structure.rowCount == 1)
    precondition(structure.blockSize == 1)
    let smCD = SparseMatrix_Complex_Double(structure: structure, data: dataPtr)
    _ = smCD
    let smCF = SparseMatrix_Complex_Float(structure: structure, data: dataPtr)
    _ = smCF
    let fcd = SparseOpaqueFactorization_Complex_Double(
        status: SparseStatus_t(rawValue: 0), attributes: cAttrs,
        symbolicFactorization: SparseOpaqueSymbolicFactorization(),
        userFactorStorage: false, numericFactorization: nil,
        solveWorkspaceRequiredStatic: 0, solveWorkspaceRequiredPerRHS: 0
    )
    precondition(fcd.status.rawValue == 0)
    _ = SparseOpaqueFactorization_Complex_Double()
    let fcf = SparseOpaqueFactorization_Complex_Float(
        status: SparseStatus_t(rawValue: 0), attributes: cAttrs,
        symbolicFactorization: SparseOpaqueSymbolicFactorization(),
        userFactorStorage: false, numericFactorization: nil,
        solveWorkspaceRequiredStatic: 0, solveWorkspaceRequiredPerRHS: 0
    )
    _ = fcf
    _ = SparseOpaqueSubfactor_Complex_Double(
        attributes: cAttrs, contents: SparseSubfactor_t(rawValue: 0), factor: fcd,
        workspaceRequiredStatic: 0, workspaceRequiredPerRHS: 0
    )
    _ = SparseOpaqueSubfactor_Complex_Double()
    _ = SparseOpaqueSubfactor_Complex_Float(
        attributes: cAttrs, contents: SparseSubfactor_t(rawValue: 0), factor: fcf,
        workspaceRequiredStatic: 0, workspaceRequiredPerRHS: 0
    )
    _ = SparseOpaqueSubfactor_Complex_Float()
    let mem = UnsafeMutableRawPointer.allocate(byteCount: 16, alignment: 8)
    defer { mem.deallocate() }
    _ = SparseOpaquePreconditioner_Complex_Double(
        type: SparsePreconditioner_t(rawValue: 0), mem: mem, apply: { _, _, _, _ in }
    )
    _ = SparseOpaquePreconditioner_Complex_Float(
        type: SparsePreconditioner_t(rawValue: 0), mem: mem, apply: { _, _, _, _ in }
    )
    var rpF: [Float] = [0, 0]
    var ipF: [Float] = [0, 0]
    _ = DSPSplitComplex(fromInputArray: [1, 2, 3, 4], realParts: &rpF, imaginaryParts: &ipF)
    precondition(rpF == [1, 3])
    precondition(ipF == [2, 4])
    var rpD: [Double] = [0, 0]
    var ipD: [Double] = [0, 0]
    _ = DSPDoubleSplitComplex(fromInputArray: [1, 2, 3, 4], realParts: &rpD, imaginaryParts: &ipD)
    precondition(rpD == [1, 3])
    precondition(ipD == [2, 4])
    let srp = UnsafeMutablePointer<Double>.allocate(capacity: 1)
    let sip = UnsafeMutablePointer<Double>.allocate(capacity: 1)
    srp.initialize(to: 1.5)
    sip.initialize(to: -2.5)
    let dsc = DSPDoubleSplitComplex(realp: srp, imagp: sip)
    precondition(dsc.realp.pointee == 1.5)
    precondition(dsc.imagp.pointee == -2.5)
    srp.deinitialize(count: 1)
    sip.deinitialize(count: 1)
    srp.deallocate()
    sip.deallocate()
    _ = vDSP_SplitComplexFloat()
    _ = vDSP_SplitComplexDouble()
    precondition(vDSP_SplitComplexFloat.SplitComplex.self == DSPSplitComplex.self)
    precondition(vDSP_SplitComplexDouble.SplitComplex.self == DSPDoubleSplitComplex.self)
    _ = vDSP.DFTSinglePrecisionSplitComplexFunctions()
    _ = vDSP.DFTDoublePrecisionSplitComplexFunctions()
    precondition(
        DSPComplex.DiscreteFourierTransformFunctions.self
            == vDSP.DFTSinglePrecisionInterleavedFunctions.self
    )
    precondition(
        DSPDoubleComplex.DiscreteFourierTransformFunctions.self
            == vDSP.DFTDoublePrecisionInterleavedFunctions.self
    )
    precondition(DSPSplitComplex.FFTFunctions.self == vDSP_SplitComplexFloat.self)
    precondition(DSPDoubleSplitComplex.FFTFunctions.self == vDSP_SplitComplexDouble.self)
    starts.deinitialize(count: 1)
    indices.deinitialize(count: 1)
    starts.deallocate()
    indices.deallocate()
}
