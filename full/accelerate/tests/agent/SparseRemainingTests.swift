import Accelerate
import Foundation

// Remaining fail-closed sparse C entry points: complex coordinate conversion,
// opaque conversion, complex inertia, and the 8 SparseIterate overloads.
// All are explicit Linux stubs (empty body, default value, or zero status).

func testSparseRemConvert() {
    let attrs = SparseAttributesComplex_t()
    let rows: [Int32] = [0]
    let cols: [Int32] = [0]
    rows.withUnsafeBufferPointer { rbp in
        cols.withUnsafeBufferPointer { cbp in
            let data = OpaquePointer(bitPattern: 1)!
            var storage: [UInt8] = [0, 0, 0, 0, 0, 0, 0, 0]
            var workspace: [UInt8] = [0, 0, 0, 0, 0, 0, 0, 0]
            storage.withUnsafeMutableBytes { stp in
                workspace.withUnsafeMutableBytes { wkp in
                    let mD: SparseMatrix_Complex_Double = SparseConvertFromCoordinate(1, 1, 1, 1, attrs, rbp.baseAddress!, cbp.baseAddress!, data)
                    precondition(mD.structure.rowCount == 0)
                    let mDw: SparseMatrix_Complex_Double = SparseConvertFromCoordinate(1, 1, 1, 1, attrs, rbp.baseAddress!, cbp.baseAddress!, data, stp.baseAddress!, wkp.baseAddress!)
                    precondition(mDw.structure.rowCount == 0)
                    let mF: SparseMatrix_Complex_Float = SparseConvertFromCoordinate(1, 1, 1, 1, attrs, rbp.baseAddress!, cbp.baseAddress!, data)
                    precondition(mF.structure.rowCount == 0)
                    let mFw: SparseMatrix_Complex_Float = SparseConvertFromCoordinate(1, 1, 1, 1, attrs, rbp.baseAddress!, cbp.baseAddress!, data, stp.baseAddress!, wkp.baseAddress!)
                    precondition(mFw.structure.rowCount == 0)
                }
            }
        }
    }
    let opaqueD: sparse_matrix_double = OpaquePointer(bitPattern: 4)!
    let opaqueDC: sparse_matrix_double_complex = OpaquePointer(bitPattern: 5)!
    let opaqueF: sparse_matrix_float = OpaquePointer(bitPattern: 6)!
    let opaqueFC: sparse_matrix_float_complex = OpaquePointer(bitPattern: 7)!
    let backD: SparseMatrix_Double = SparseConvertFromOpaque(opaqueD)
    precondition(backD.structure.rowCount == 0)
    let backDC: SparseMatrix_Complex_Double = SparseConvertFromOpaque(opaqueDC)
    precondition(backDC.structure.rowCount == 0)
    let backF: SparseMatrix_Float = SparseConvertFromOpaque(opaqueF)
    precondition(backF.structure.rowCount == 0)
    let backFC: SparseMatrix_Complex_Float = SparseConvertFromOpaque(opaqueFC)
    precondition(backFC.structure.rowCount == 0)
}

func testSparseRemIterateInertia() {
    var pos: Int32 = -1
    var zer: Int32 = -1
    var neg: Int32 = -1
    let fcd = SparseOpaqueFactorization_Complex_Double()
    let fcf = SparseOpaqueFactorization_Complex_Float()
    precondition(SparseGetInertia(fcd, &pos, &zer, &neg) == 0)
    precondition(SparseGetInertia(fcf, &pos, &zer, &neg) == 0)
    let method = SparseIterativeMethod()
    let converged = false
    var state: [UInt8] = [0, 0, 0, 0]
    withUnsafePointer(to: converged) { cvp in
        state.withUnsafeMutableBytes { stp in
            let bCD = DenseMatrix_Complex_Double()
            let rCD = DenseMatrix_Complex_Double()
            let xCD = DenseMatrix_Complex_Double()
            SparseIterate(method, 0, cvp, stp.baseAddress!, { _, _, _, _ in }, bCD, rCD, xCD)
            SparseIterate(method, 0, cvp, stp.baseAddress!, { _, _, _, _ in }, bCD, rCD, xCD, SparseOpaquePreconditioner_Complex_Double())
            let bCF = DenseMatrix_Complex_Float()
            let rCF = DenseMatrix_Complex_Float()
            let xCF = DenseMatrix_Complex_Float()
            SparseIterate(method, 0, cvp, stp.baseAddress!, { _, _, _, _ in }, bCF, rCF, xCF)
            SparseIterate(method, 0, cvp, stp.baseAddress!, { _, _, _, _ in }, bCF, rCF, xCF, SparseOpaquePreconditioner_Complex_Float())
            let bD = DenseMatrix_Double()
            let rD = DenseMatrix_Double()
            let xD = DenseMatrix_Double()
            SparseIterate(method, 0, cvp, stp.baseAddress!, { _, _, _, _ in }, bD, rD, xD)
            SparseIterate(method, 0, cvp, stp.baseAddress!, { _, _, _, _ in }, bD, rD, xD, SparseOpaquePreconditioner_Double())
            let bF = DenseMatrix_Float()
            let rF = DenseMatrix_Float()
            let xF = DenseMatrix_Float()
            SparseIterate(method, 0, cvp, stp.baseAddress!, { _, _, _, _ in }, bF, rF, xF)
            SparseIterate(method, 0, cvp, stp.baseAddress!, { _, _, _, _ in }, bF, rF, xF, SparseOpaquePreconditioner_Float())
        }
    }
}
