import Foundation

// MARK: - Sparse subfactor views, refactor, transpose, inertia (dense-backed)
//
// A Linux `SparseOpaqueSubfactor_Float/Double` is a non-owning view: its
// `factor` field aliases the parent factorization's retained CSC clone (the
// same aliasing rule `SparseRetain` uses). `SparseCleanup` on a subfactor is
// therefore a no-op; clean up the parent factorization exactly once and never
// use the subfactor afterwards.
//
// Divergence from Apple (pinned in scratch/oracle-2026-09-14/
// sparse-subfactor-2026-09-15.txt): on macOS 26.1 `SparseCreateSubfactor` and
// the structure-only `SparseFactor` trap unless the factorization comes from a
// fuller two-phase path, and subfactor multiply applies Apple's triangular
// extraction (L/D/...). The Linux path cannot observe that extraction, so
// subfactor multiply/solve apply the FULL stored matrix regardless of the
// `contents` selector. `SparseRefactor` replaces the stored clone,
// `SparseUpdateFactor` performs a full refactor with `Update` treated as the
// complete replacement matrix, and `SparseGetTranspose` returns freshly owned
// storage the caller must `SparseCleanup`.

func _sparseSubfactorMatrixFloat(_ sub: SparseOpaqueSubfactor_Float) -> SparseMatrix_Float? {
    _sparseMatrixFromFactorFloat(sub.factor)
}

func _sparseSubfactorMatrixDouble(_ sub: SparseOpaqueSubfactor_Double) -> SparseMatrix_Double? {
    _sparseMatrixFromFactorDouble(sub.factor)
}

func _sparseCreateSubfactorFloat(
    _ kind: SparseSubfactor_t,
    _ fact: SparseOpaqueFactorization_Float
) -> SparseOpaqueSubfactor_Float {
    var sub = SparseOpaqueSubfactor_Float()
    sub.contents = kind
    sub.attributes = fact.attributes
    sub.factor = fact
    return sub
}

func _sparseCreateSubfactorDouble(
    _ kind: SparseSubfactor_t,
    _ fact: SparseOpaqueFactorization_Double
) -> SparseOpaqueSubfactor_Double {
    var sub = SparseOpaqueSubfactor_Double()
    sub.contents = kind
    sub.attributes = fact.attributes
    sub.factor = fact
    return sub
}

func _sparseSubfactorMultiplyMatrixFloat(
    _ sub: SparseOpaqueSubfactor_Float,
    _ X: DenseMatrix_Float,
    _ Y: DenseMatrix_Float
) {
    guard let A = _sparseSubfactorMatrixFloat(sub) else { return }
    _sparseCSCMultiplyMatrix(structure: A.structure, data: A.data, x: X, y: Y, alpha: 1, add: false)
}

func _sparseSubfactorMultiplyVectorFloat(
    _ sub: SparseOpaqueSubfactor_Float,
    _ x: DenseVector_Float,
    _ y: DenseVector_Float
) {
    guard let A = _sparseSubfactorMatrixFloat(sub) else { return }
    _sparseCSCMultiplyVector(structure: A.structure, data: A.data, x: x.data, y: y.data, alpha: 1, add: false)
}

func _sparseSubfactorMultiplyMatrixDouble(
    _ sub: SparseOpaqueSubfactor_Double,
    _ X: DenseMatrix_Double,
    _ Y: DenseMatrix_Double
) {
    guard let A = _sparseSubfactorMatrixDouble(sub) else { return }
    _sparseCSCMultiplyMatrixD(structure: A.structure, data: A.data, x: X, y: Y, alpha: 1, add: false)
}

func _sparseSubfactorMultiplyVectorDouble(
    _ sub: SparseOpaqueSubfactor_Double,
    _ x: DenseVector_Double,
    _ y: DenseVector_Double
) {
    guard let A = _sparseSubfactorMatrixDouble(sub) else { return }
    _sparseCSCMultiplyVector(structure: A.structure, data: A.data, x: x.data, y: y.data, alpha: 1, add: false)
}

func _sparseSubfactorMultiplyInPlaceMatrixFloat(_ sub: SparseOpaqueSubfactor_Float, _ XY: DenseMatrix_Float) {
    guard let A = _sparseSubfactorMatrixFloat(sub) else { return }
    let n = Int(XY.rowCount)
    let k = Int(XY.columnCount)
    let stride = Int(XY.columnStride)
    let count = max(stride * k, n * k)
    if n <= 0 || k <= 0 || count <= 0 { return }
    var copy = [Float](repeating: 0, count: count)
    copy.withUnsafeMutableBufferPointer { bp in
        bp.baseAddress!.update(from: XY.data, count: count)
        let X = DenseMatrix_Float(
            rowCount: XY.rowCount,
            columnCount: XY.columnCount,
            columnStride: XY.columnStride,
            attributes: XY.attributes,
            data: bp.baseAddress!
        )
        _sparseCSCMultiplyMatrix(structure: A.structure, data: A.data, x: X, y: XY, alpha: 1, add: false)
    }
}

func _sparseSubfactorMultiplyInPlaceVectorFloat(_ sub: SparseOpaqueSubfactor_Float, _ xy: DenseVector_Float) {
    guard let A = _sparseSubfactorMatrixFloat(sub) else { return }
    let n = Int(xy.count)
    if n <= 0 { return }
    var copy = [Float](repeating: 0, count: n)
    copy.withUnsafeMutableBufferPointer { bp in
        bp.baseAddress!.update(from: xy.data, count: n)
        let x = DenseVector_Float(count: xy.count, data: bp.baseAddress!)
        _sparseCSCMultiplyVector(structure: A.structure, data: A.data, x: x.data, y: xy.data, alpha: 1, add: false)
    }
}

func _sparseSubfactorMultiplyInPlaceMatrixDouble(_ sub: SparseOpaqueSubfactor_Double, _ XY: DenseMatrix_Double) {
    guard let A = _sparseSubfactorMatrixDouble(sub) else { return }
    let n = Int(XY.rowCount)
    let k = Int(XY.columnCount)
    let stride = Int(XY.columnStride)
    let count = max(stride * k, n * k)
    if n <= 0 || k <= 0 || count <= 0 { return }
    var copy = [Double](repeating: 0, count: count)
    copy.withUnsafeMutableBufferPointer { bp in
        bp.baseAddress!.update(from: XY.data, count: count)
        let X = DenseMatrix_Double(
            rowCount: XY.rowCount,
            columnCount: XY.columnCount,
            columnStride: XY.columnStride,
            attributes: XY.attributes,
            data: bp.baseAddress!
        )
        _sparseCSCMultiplyMatrixD(structure: A.structure, data: A.data, x: X, y: XY, alpha: 1, add: false)
    }
}

func _sparseSubfactorMultiplyInPlaceVectorDouble(_ sub: SparseOpaqueSubfactor_Double, _ xy: DenseVector_Double) {
    guard let A = _sparseSubfactorMatrixDouble(sub) else { return }
    let n = Int(xy.count)
    if n <= 0 { return }
    var copy = [Double](repeating: 0, count: n)
    copy.withUnsafeMutableBufferPointer { bp in
        bp.baseAddress!.update(from: xy.data, count: n)
        let x = DenseVector_Double(count: xy.count, data: bp.baseAddress!)
        _sparseCSCMultiplyVector(structure: A.structure, data: A.data, x: x.data, y: xy.data, alpha: 1, add: false)
    }
}

// MARK: - Refactor (clone-then-release so self-refactor is safe)

func _sparseRefactorFloat(
    _ Matrix: SparseMatrix_Float,
    _ Factorization: UnsafeMutablePointer<SparseOpaqueFactorization_Float>
) {
    let fresh = _sparseFactorFloat(Matrix)
    _sparseReleaseFactorFloat(Factorization.pointee)
    Factorization.pointee = fresh
}

func _sparseRefactorDouble(
    _ Matrix: SparseMatrix_Double,
    _ Factorization: UnsafeMutablePointer<SparseOpaqueFactorization_Double>
) {
    let fresh = _sparseFactorDouble(Matrix)
    _sparseReleaseFactorDouble(Factorization.pointee)
    Factorization.pointee = fresh
}

// MARK: - CSC transpose of the logical matrix (freshly owned storage)

func _sparseTransposeCSC<T: BinaryFloatingPoint>(
    rows: Int,
    cols: Int,
    dense: [T]
) -> (columnStarts: UnsafeMutablePointer<Int>, rowIndices: UnsafeMutablePointer<Int32>, values: UnsafeMutablePointer<T>) {
    var counts = [Int](repeating: 0, count: rows)
    for r in 0..<rows {
        for c in 0..<cols {
            if dense[c * rows + r] != 0 { counts[r] += 1 }
        }
    }
    let colStarts = UnsafeMutablePointer<Int>.allocate(capacity: rows + 1)
    colStarts[0] = 0
    for r in 0..<rows { colStarts[r + 1] = colStarts[r] + counts[r] }
    let nnz = colStarts[rows]
    let rowIndices = UnsafeMutablePointer<Int32>.allocate(capacity: max(nnz, 1))
    let values = UnsafeMutablePointer<T>.allocate(capacity: max(nnz, 1))
    var next = [Int](repeating: 0, count: rows + 1)
    for r in 0...rows { next[r] = colStarts[r] }
    for c in 0..<cols {
        for r in 0..<rows {
            let v = dense[c * rows + r]
            if v != 0 {
                let dest = next[r]
                rowIndices[dest] = Int32(c)
                values[dest] = v
                next[r] = dest + 1
            }
        }
    }
    return (colStarts, rowIndices, values)
}

func _sparseTransposeMatrixFloat(_ src: SparseMatrix_Float) -> SparseMatrix_Float {
    let rows = Int(src.structure.rowCount)
    let cols = Int(src.structure.columnCount)
    var dst = SparseMatrix_Float()
    if rows <= 0 || cols <= 0 { return dst }
    let dense = _sparseCSCToDense(structure: src.structure, data: src.data, rows: rows, cols: cols)
    let parts = _sparseTransposeCSC(rows: rows, cols: cols, dense: dense)
    dst.data.deallocate()
    dst.structure.columnStarts.deallocate()
    dst.structure.rowIndices.deallocate()
    var attr = src.structure.attributes
    attr.transpose = false
    dst.structure.attributes = attr
    dst.structure.blockSize = src.structure.blockSize
    dst.structure.columnCount = src.structure.rowCount
    dst.structure.rowCount = src.structure.columnCount
    dst.structure.columnStarts = parts.columnStarts
    dst.structure.rowIndices = parts.rowIndices
    dst.data = parts.values
    return dst
}

func _sparseTransposeMatrixDouble(_ src: SparseMatrix_Double) -> SparseMatrix_Double {
    let rows = Int(src.structure.rowCount)
    let cols = Int(src.structure.columnCount)
    var dst = SparseMatrix_Double()
    if rows <= 0 || cols <= 0 { return dst }
    let dense = _sparseCSCToDense(structure: src.structure, data: src.data, rows: rows, cols: cols)
    let parts = _sparseTransposeCSC(rows: rows, cols: cols, dense: dense)
    dst.data.deallocate()
    dst.structure.columnStarts.deallocate()
    dst.structure.rowIndices.deallocate()
    var attr = src.structure.attributes
    attr.transpose = false
    dst.structure.attributes = attr
    dst.structure.blockSize = src.structure.blockSize
    dst.structure.columnCount = src.structure.rowCount
    dst.structure.rowCount = src.structure.columnCount
    dst.structure.columnStarts = parts.columnStarts
    dst.structure.rowIndices = parts.rowIndices
    dst.data = parts.values
    return dst
}

func _sparseTransposeFactorFloat(_ fact: SparseOpaqueFactorization_Float) -> SparseOpaqueFactorization_Float {
    guard let A = _sparseMatrixFromFactorFloat(fact) else { return SparseOpaqueFactorization_Float() }
    let t = _sparseTransposeMatrixFloat(A)
    defer { _sparseCleanupFloat(t) }
    return _sparseFactorFloat(t)
}

func _sparseTransposeFactorDouble(_ fact: SparseOpaqueFactorization_Double) -> SparseOpaqueFactorization_Double {
    guard let A = _sparseMatrixFromFactorDouble(fact) else { return SparseOpaqueFactorization_Double() }
    let t = _sparseTransposeMatrixDouble(A)
    defer { _sparseCleanupDouble(t) }
    return _sparseFactorDouble(t)
}

func _sparseTransposeSubfactorFloat(_ sub: SparseOpaqueSubfactor_Float) -> SparseOpaqueSubfactor_Float {
    // Transpose the aliased parent factor, then wrap the fresh factor in a
    // subfactor with the same contents selector. The wrapped factor is freshly
    // owned: callers must `SparseCleanup(result.factor)` (subfactor cleanup
    // itself is a no-op over the non-owning view).
    let t = _sparseTransposeFactorFloat(sub.factor)
    var out = SparseOpaqueSubfactor_Float()
    out.contents = sub.contents
    out.attributes = sub.attributes
    out.factor = t
    return out
}

func _sparseTransposeSubfactorDouble(_ sub: SparseOpaqueSubfactor_Double) -> SparseOpaqueSubfactor_Double {
    let t = _sparseTransposeFactorDouble(sub.factor)
    var out = SparseOpaqueSubfactor_Double()
    out.contents = sub.contents
    out.attributes = sub.attributes
    out.factor = t
    return out
}

// MARK: - Symbolic factorization from a bare structure (pattern only)

func _sparseSymbolicFromStructure(
    _ type: SparseFactorization_t,
    _ structure: SparseMatrixStructure
) -> SparseOpaqueSymbolicFactorization {
    var sym = SparseOpaqueSymbolicFactorization()
    sym.type = type
    sym.rowCount = structure.rowCount
    sym.columnCount = structure.columnCount
    sym.blockSize = structure.blockSize
    sym.attributes = structure.attributes
    sym.status = SparseStatusOK
    return sym
}

// MARK: - Inertia of a symmetric factorization via cyclic Jacobi eigenvalues
//
// Returns 0 and stores positive/zero/negative eigenvalue counts. Returns 1
// without touching the counts when the stored matrix is missing, non-square,
// or asymmetric beyond tolerance. Jacobi iteration is bounded (100 sweeps) so
// this always terminates.

func _sparseJacobiEigenvalues(_ a: [Double], n: Int) -> [Double] {
    var v = a
    if n <= 1 { return v }
    for _ in 0..<100 {
        var off = 0.0
        for i in 0..<n {
            for j in (i + 1)..<n { off += v[j * n + i] * v[j * n + i] }
        }
        if off == 0 { break }
        for p in 0..<(n - 1) {
            for q in (p + 1)..<n {
                let apq = v[q * n + p]
                if apq == 0 { continue }
                let app = v[p * n + p]
                let aqq = v[q * n + q]
                let theta = (aqq - app) / (2 * apq)
                let t = (theta >= 0 ? 1.0 : -1.0) / (abs(theta) + (theta * theta + 1).squareRoot())
                let c = 1 / (t * t + 1).squareRoot()
                let s = t * c
                for k in 0..<n {
                    if k != p && k != q {
                        let akp = v[p * n + k]
                        let akq = v[q * n + k]
                        v[p * n + k] = c * akp - s * akq
                        v[q * n + k] = s * akp + c * akq
                        v[k * n + p] = v[p * n + k]
                        v[k * n + q] = v[q * n + k]
                    }
                }
                v[p * n + p] = c * c * app - 2 * s * c * apq + s * s * aqq
                v[q * n + q] = s * s * app + 2 * s * c * apq + c * c * aqq
                v[p * n + q] = 0
                v[q * n + p] = 0
            }
        }
    }
    return (0..<n).map { v[$0 * n + $0] }
}

func _sparseInertiaDense(
    _ dense: [Double],
    n: Int,
    _ pos: UnsafeMutablePointer<Int32>,
    _ zero: UnsafeMutablePointer<Int32>,
    _ neg: UnsafeMutablePointer<Int32>
) -> Int32 {
    var scale = 0.0
    for v in dense { scale = max(scale, abs(v)) }
    if scale == 0 {
        pos.pointee = 0
        zero.pointee = Int32(n)
        neg.pointee = 0
        return 0
    }
    for i in 0..<n {
        for j in 0..<n {
            if abs(dense[j * n + i] - dense[i * n + j]) > 1e-6 * scale { return 1 }
        }
    }
    let eig = _sparseJacobiEigenvalues(dense, n: n)
    var p = 0
    var z = 0
    var g = 0
    for e in eig {
        if abs(e) <= 1e-9 * scale { z += 1 } else if e > 0 { p += 1 } else { g += 1 }
    }
    pos.pointee = Int32(p)
    zero.pointee = Int32(z)
    neg.pointee = Int32(g)
    return 0
}

func _sparseInertiaFloat(
    _ fact: SparseOpaqueFactorization_Float,
    _ pos: UnsafeMutablePointer<Int32>,
    _ zero: UnsafeMutablePointer<Int32>,
    _ neg: UnsafeMutablePointer<Int32>
) -> Int32 {
    guard let A = _sparseMatrixFromFactorFloat(fact) else { return 1 }
    let n = Int(A.structure.rowCount)
    if n <= 0 || n != Int(A.structure.columnCount) { return 1 }
    let dense = _sparseCSCToDense(structure: A.structure, data: A.data, rows: n, cols: n).map { Double($0) }
    return _sparseInertiaDense(dense, n: n, pos, zero, neg)
}

func _sparseInertiaDouble(
    _ fact: SparseOpaqueFactorization_Double,
    _ pos: UnsafeMutablePointer<Int32>,
    _ zero: UnsafeMutablePointer<Int32>,
    _ neg: UnsafeMutablePointer<Int32>
) -> Int32 {
    guard let A = _sparseMatrixFromFactorDouble(fact) else { return 1 }
    let n = Int(A.structure.rowCount)
    if n <= 0 || n != Int(A.structure.columnCount) { return 1 }
    let dense = _sparseCSCToDense(structure: A.structure, data: A.data, rows: n, cols: n)
    return _sparseInertiaDense(dense, n: n, pos, zero, neg)
}
