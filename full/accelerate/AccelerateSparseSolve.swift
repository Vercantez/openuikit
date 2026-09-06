import Foundation

/// Dense Gaussian elimination for small CSC sparse systems (column-major).
func _sparseCSCToDense<T: BinaryFloatingPoint>(
    structure: SparseMatrixStructure,
    data: UnsafePointer<T>,
    rows: Int,
    cols: Int
) -> [T] {
    var dense = [T](repeating: 0, count: max(rows * cols, 1))
    let transpose = structure.attributes.transpose
    for j in 0..<Int(structure.columnCount) {
        let start = structure.columnStarts[j]
        let end = structure.columnStarts[j + 1]
        if start < 0 || end < start { continue }
        for p in start..<end {
            let row = Int(structure.rowIndices[p])
            if row < 0 { continue }
            let value = data[p]
            if transpose {
                if j < rows && row < cols {
                    dense[row * rows + j] += value
                }
            } else if row < rows && j < cols {
                dense[j * rows + row] += value
            }
        }
    }
    return dense
}

func _denseGESolve<T: BinaryFloatingPoint>(
    n: Int,
    a: inout [T],
    b: UnsafePointer<T>,
    x: UnsafeMutablePointer<T>,
    nrhs: Int,
    ldb: Int,
    lda: Int
) -> SparseIterativeStatus_t {
    if n <= 0 { return SparseIterativeParameterError }
    var lu = a
    var ipiv = [Int](repeating: 0, count: n)
    for i in 0..<n {
        var pivot = i
        var best = abs(lu[i * lda + i])
        for r in (i + 1)..<n {
            let v = abs(lu[i * lda + r])
            if v > best {
                best = v
                pivot = r
            }
        }
        if best == 0 { return SparseIterativeIllConditioned }
        ipiv[i] = pivot
        if pivot != i {
            for c in 0..<n {
                let t = lu[c * lda + i]
                lu[c * lda + i] = lu[c * lda + pivot]
                lu[c * lda + pivot] = t
            }
        }
        let diag = lu[i * lda + i]
        for r in (i + 1)..<n {
            lu[i * lda + r] /= diag
            let lik = lu[i * lda + r]
            for c in (i + 1)..<n {
                lu[c * lda + r] -= lik * lu[c * lda + i]
            }
        }
    }
    for rhs in 0..<nrhs {
        var y = [T](repeating: 0, count: n)
        for r in 0..<n { y[r] = b[rhs * ldb + r] }
        for i in 0..<n {
            let p = ipiv[i]
            if p != i { y.swapAt(i, p) }
        }
        for i in 0..<n {
            var s = y[i]
            for k in 0..<i { s -= lu[k * lda + i] * y[k] }
            y[i] = s
        }
        for i in stride(from: n - 1, through: 0, by: -1) {
            var s = y[i]
            for k in (i + 1)..<n { s -= lu[k * lda + i] * y[k] }
            y[i] = s / lu[i * lda + i]
        }
        for r in 0..<n { x[rhs * ldb + r] = y[r] }
    }
    _ = a
    return SparseIterativeConverged
}

func _sparseSolveVectorFloat(
    _ A: SparseMatrix_Float,
    _ b: DenseVector_Float,
    _ x: DenseVector_Float
) -> SparseIterativeStatus_t {
    let n = Int(A.structure.rowCount)
    let cols = Int(A.structure.columnCount)
    if n <= 0 || n != cols || n != Int(b.count) || n != Int(x.count) {
        return SparseIterativeParameterError
    }
    var dense = _sparseCSCToDense(structure: A.structure, data: A.data, rows: n, cols: cols)
    return _denseGESolve(n: n, a: &dense, b: b.data, x: x.data, nrhs: 1, ldb: n, lda: n)
}

func _sparseSolveVectorDouble(
    _ A: SparseMatrix_Double,
    _ b: DenseVector_Double,
    _ x: DenseVector_Double
) -> SparseIterativeStatus_t {
    let n = Int(A.structure.rowCount)
    let cols = Int(A.structure.columnCount)
    if n <= 0 || n != cols || n != Int(b.count) || n != Int(x.count) {
        return SparseIterativeParameterError
    }
    var dense = _sparseCSCToDense(structure: A.structure, data: A.data, rows: n, cols: cols)
    return _denseGESolve(n: n, a: &dense, b: b.data, x: x.data, nrhs: 1, ldb: n, lda: n)
}

func _sparseSolveMatrixFloat(
    _ A: SparseMatrix_Float,
    _ B: DenseMatrix_Float,
    _ X: DenseMatrix_Float
) -> SparseIterativeStatus_t {
    let n = Int(A.structure.rowCount)
    let cols = Int(A.structure.columnCount)
    let nrhs = Int(B.columnCount)
    if n <= 0 || n != cols || n != Int(B.rowCount) || n != Int(X.rowCount) || nrhs != Int(X.columnCount) {
        return SparseIterativeParameterError
    }
    var dense = _sparseCSCToDense(structure: A.structure, data: A.data, rows: n, cols: cols)
    return _denseGESolve(
        n: n,
        a: &dense,
        b: B.data,
        x: X.data,
        nrhs: nrhs,
        ldb: Int(B.columnStride),
        lda: n
    )
}

func _sparseSolveMatrixDouble(
    _ A: SparseMatrix_Double,
    _ B: DenseMatrix_Double,
    _ X: DenseMatrix_Double
) -> SparseIterativeStatus_t {
    let n = Int(A.structure.rowCount)
    let cols = Int(A.structure.columnCount)
    let nrhs = Int(B.columnCount)
    if n <= 0 || n != cols || n != Int(B.rowCount) || n != Int(X.rowCount) || nrhs != Int(X.columnCount) {
        return SparseIterativeParameterError
    }
    var dense = _sparseCSCToDense(structure: A.structure, data: A.data, rows: n, cols: cols)
    return _denseGESolve(
        n: n,
        a: &dense,
        b: B.data,
        x: X.data,
        nrhs: nrhs,
        ldb: Int(B.columnStride),
        lda: n
    )
}

func _sparseSolveApplyVectorFloat(
    _ apply: (Bool, CBLAS_TRANSPOSE, DenseVector_Float, DenseVector_Float) -> Void,
    _ b: DenseVector_Float,
    _ x: DenseVector_Float
) -> SparseIterativeStatus_t {
    let n = Int(b.count)
    if n <= 0 || n != Int(x.count) { return SparseIterativeParameterError }
    var dense = [Float](repeating: 0, count: n * n)
    var unit = [Float](repeating: 0, count: n)
    var col = [Float](repeating: 0, count: n)
    for j in 0..<n {
        for i in 0..<n { unit[i] = 0 }
        unit[j] = 1
        unit.withUnsafeMutableBufferPointer { u in
            col.withUnsafeMutableBufferPointer { c in
                let xv = DenseVector_Float(count: Int32(n), data: u.baseAddress!)
                let yv = DenseVector_Float(count: Int32(n), data: c.baseAddress!)
                apply(false, CblasNoTrans, xv, yv)
            }
        }
        for i in 0..<n { dense[j * n + i] = col[i] }
    }
    return _denseGESolve(n: n, a: &dense, b: b.data, x: x.data, nrhs: 1, ldb: n, lda: n)
}

func _sparseSolveApplyVectorDouble(
    _ apply: (Bool, CBLAS_TRANSPOSE, DenseVector_Double, DenseVector_Double) -> Void,
    _ b: DenseVector_Double,
    _ x: DenseVector_Double
) -> SparseIterativeStatus_t {
    let n = Int(b.count)
    if n <= 0 || n != Int(x.count) { return SparseIterativeParameterError }
    var dense = [Double](repeating: 0, count: n * n)
    var unit = [Double](repeating: 0, count: n)
    var col = [Double](repeating: 0, count: n)
    for j in 0..<n {
        for i in 0..<n { unit[i] = 0 }
        unit[j] = 1
        unit.withUnsafeMutableBufferPointer { u in
            col.withUnsafeMutableBufferPointer { c in
                let xv = DenseVector_Double(count: Int32(n), data: u.baseAddress!)
                let yv = DenseVector_Double(count: Int32(n), data: c.baseAddress!)
                apply(false, CblasNoTrans, xv, yv)
            }
        }
        for i in 0..<n { dense[j * n + i] = col[i] }
    }
    return _denseGESolve(n: n, a: &dense, b: b.data, x: x.data, nrhs: 1, ldb: n, lda: n)
}

func _sparseSolveApplyMatrixFloat(
    _ apply: (Bool, CBLAS_TRANSPOSE, DenseMatrix_Float, DenseMatrix_Float) -> Void,
    _ B: DenseMatrix_Float,
    _ X: DenseMatrix_Float
) -> SparseIterativeStatus_t {
    let n = Int(B.rowCount)
    let nrhs = Int(B.columnCount)
    if n <= 0 || n != Int(X.rowCount) || nrhs != Int(X.columnCount) {
        return SparseIterativeParameterError
    }
    var dense = [Float](repeating: 0, count: n * n)
    var identCol = [Float](repeating: 0, count: n)
    var outCol = [Float](repeating: 0, count: n)
    for j in 0..<n {
        for i in 0..<n { identCol[i] = 0 }
        identCol[j] = 1
        identCol.withUnsafeMutableBufferPointer { ip in
            outCol.withUnsafeMutableBufferPointer { op in
                let I = DenseMatrix_Float(
                    rowCount: Int32(n),
                    columnCount: 1,
                    columnStride: Int32(n),
                    attributes: SparseAttributes_t(),
                    data: ip.baseAddress!
                )
                let Y = DenseMatrix_Float(
                    rowCount: Int32(n),
                    columnCount: 1,
                    columnStride: Int32(n),
                    attributes: SparseAttributes_t(),
                    data: op.baseAddress!
                )
                apply(false, CblasNoTrans, I, Y)
            }
        }
        for i in 0..<n { dense[j * n + i] = outCol[i] }
    }
    return _denseGESolve(
        n: n,
        a: &dense,
        b: B.data,
        x: X.data,
        nrhs: nrhs,
        ldb: Int(B.columnStride),
        lda: n
    )
}

func _sparseSolveApplyMatrixDouble(
    _ apply: (Bool, CBLAS_TRANSPOSE, DenseMatrix_Double, DenseMatrix_Double) -> Void,
    _ B: DenseMatrix_Double,
    _ X: DenseMatrix_Double
) -> SparseIterativeStatus_t {
    let n = Int(B.rowCount)
    let nrhs = Int(B.columnCount)
    if n <= 0 || n != Int(X.rowCount) || nrhs != Int(X.columnCount) {
        return SparseIterativeParameterError
    }
    var dense = [Double](repeating: 0, count: n * n)
    var identCol = [Double](repeating: 0, count: n)
    var outCol = [Double](repeating: 0, count: n)
    for j in 0..<n {
        for i in 0..<n { identCol[i] = 0 }
        identCol[j] = 1
        identCol.withUnsafeMutableBufferPointer { ip in
            outCol.withUnsafeMutableBufferPointer { op in
                let I = DenseMatrix_Double(
                    rowCount: Int32(n),
                    columnCount: 1,
                    columnStride: Int32(n),
                    attributes: SparseAttributes_t(),
                    data: ip.baseAddress!
                )
                let Y = DenseMatrix_Double(
                    rowCount: Int32(n),
                    columnCount: 1,
                    columnStride: Int32(n),
                    attributes: SparseAttributes_t(),
                    data: op.baseAddress!
                )
                apply(false, CblasNoTrans, I, Y)
            }
        }
        for i in 0..<n { dense[j * n + i] = outCol[i] }
    }
    return _denseGESolve(
        n: n,
        a: &dense,
        b: B.data,
        x: X.data,
        nrhs: nrhs,
        ldb: Int(B.columnStride),
        lda: n
    )
}

final class _SparseFactorBoxFloat {
    var matrix: SparseMatrix_Float
    init(_ matrix: SparseMatrix_Float) { self.matrix = matrix }
    deinit { _sparseCleanupFloat(matrix) }
}

final class _SparseFactorBoxDouble {
    var matrix: SparseMatrix_Double
    init(_ matrix: SparseMatrix_Double) { self.matrix = matrix }
    deinit { _sparseCleanupDouble(matrix) }
}

func _sparseCloneMatrixFloat(_ src: SparseMatrix_Float) -> SparseMatrix_Float {
    let cols = Int(src.structure.columnCount)
    let nnz = cols >= 0 ? src.structure.columnStarts[cols] : 0
    var dst = SparseMatrix_Float()
    dst.data.deallocate()
    dst.structure.columnStarts.deallocate()
    dst.structure.rowIndices.deallocate()
    dst.structure.columnCount = src.structure.columnCount
    dst.structure.rowCount = src.structure.rowCount
    dst.structure.attributes = src.structure.attributes
    dst.structure.blockSize = src.structure.blockSize
    dst.structure.columnStarts = UnsafeMutablePointer<Int>.allocate(capacity: max(cols + 1, 1))
    dst.structure.rowIndices = UnsafeMutablePointer<Int32>.allocate(capacity: max(nnz, 1))
    dst.data = UnsafeMutablePointer<Float>.allocate(capacity: max(nnz, 1))
    if cols >= 0 {
        dst.structure.columnStarts.update(from: src.structure.columnStarts, count: cols + 1)
    }
    if nnz > 0 {
        dst.structure.rowIndices.update(from: src.structure.rowIndices, count: nnz)
        dst.data.update(from: src.data, count: nnz)
    }
    return dst
}

func _sparseCloneMatrixDouble(_ src: SparseMatrix_Double) -> SparseMatrix_Double {
    let cols = Int(src.structure.columnCount)
    let nnz = cols >= 0 ? src.structure.columnStarts[cols] : 0
    var dst = SparseMatrix_Double()
    dst.data.deallocate()
    dst.structure.columnStarts.deallocate()
    dst.structure.rowIndices.deallocate()
    dst.structure.columnCount = src.structure.columnCount
    dst.structure.rowCount = src.structure.rowCount
    dst.structure.attributes = src.structure.attributes
    dst.structure.blockSize = src.structure.blockSize
    dst.structure.columnStarts = UnsafeMutablePointer<Int>.allocate(capacity: max(cols + 1, 1))
    dst.structure.rowIndices = UnsafeMutablePointer<Int32>.allocate(capacity: max(nnz, 1))
    dst.data = UnsafeMutablePointer<Double>.allocate(capacity: max(nnz, 1))
    if cols >= 0 {
        dst.structure.columnStarts.update(from: src.structure.columnStarts, count: cols + 1)
    }
    if nnz > 0 {
        dst.structure.rowIndices.update(from: src.structure.rowIndices, count: nnz)
        dst.data.update(from: src.data, count: nnz)
    }
    return dst
}

func _sparseFactorFloat(_ Matrix: SparseMatrix_Float) -> SparseOpaqueFactorization_Float {
    var fact = SparseOpaqueFactorization_Float()
    let box = _SparseFactorBoxFloat(_sparseCloneMatrixFloat(Matrix))
    fact.numericFactorization = Unmanaged.passRetained(box).toOpaque()
    fact.attributes = Matrix.structure.attributes
    fact.status = SparseStatusOK
    return fact
}

func _sparseFactorDouble(_ Matrix: SparseMatrix_Double) -> SparseOpaqueFactorization_Double {
    var fact = SparseOpaqueFactorization_Double()
    let box = _SparseFactorBoxDouble(_sparseCloneMatrixDouble(Matrix))
    fact.numericFactorization = Unmanaged.passRetained(box).toOpaque()
    fact.attributes = Matrix.structure.attributes
    fact.status = SparseStatusOK
    return fact
}

func _sparseReleaseFactorFloat(_ fact: SparseOpaqueFactorization_Float) {
    if let ptr = fact.numericFactorization {
        Unmanaged<_SparseFactorBoxFloat>.fromOpaque(ptr).release()
    }
}

func _sparseReleaseFactorDouble(_ fact: SparseOpaqueFactorization_Double) {
    if let ptr = fact.numericFactorization {
        Unmanaged<_SparseFactorBoxDouble>.fromOpaque(ptr).release()
    }
}

func _sparseMatrixFromFactorFloat(_ fact: SparseOpaqueFactorization_Float) -> SparseMatrix_Float? {
    guard let ptr = fact.numericFactorization else { return nil }
    return Unmanaged<_SparseFactorBoxFloat>.fromOpaque(ptr).takeUnretainedValue().matrix
}

func _sparseMatrixFromFactorDouble(_ fact: SparseOpaqueFactorization_Double) -> SparseMatrix_Double? {
    guard let ptr = fact.numericFactorization else { return nil }
    return Unmanaged<_SparseFactorBoxDouble>.fromOpaque(ptr).takeUnretainedValue().matrix
}

@discardableResult
func _sparseSolveFactoredVectorFloat(
    _ fact: SparseOpaqueFactorization_Float,
    _ b: DenseVector_Float,
    _ x: DenseVector_Float
) -> SparseIterativeStatus_t {
    guard let A = _sparseMatrixFromFactorFloat(fact) else { return SparseIterativeParameterError }
    return _sparseSolveVectorFloat(A, b, x)
}

@discardableResult
func _sparseSolveFactoredVectorDouble(
    _ fact: SparseOpaqueFactorization_Double,
    _ b: DenseVector_Double,
    _ x: DenseVector_Double
) -> SparseIterativeStatus_t {
    guard let A = _sparseMatrixFromFactorDouble(fact) else { return SparseIterativeParameterError }
    return _sparseSolveVectorDouble(A, b, x)
}

@discardableResult
func _sparseSolveFactoredMatrixFloat(
    _ fact: SparseOpaqueFactorization_Float,
    _ B: DenseMatrix_Float,
    _ X: DenseMatrix_Float
) -> SparseIterativeStatus_t {
    guard let A = _sparseMatrixFromFactorFloat(fact) else { return SparseIterativeParameterError }
    return _sparseSolveMatrixFloat(A, B, X)
}

@discardableResult
func _sparseSolveFactoredMatrixDouble(
    _ fact: SparseOpaqueFactorization_Double,
    _ B: DenseMatrix_Double,
    _ X: DenseMatrix_Double
) -> SparseIterativeStatus_t {
    guard let A = _sparseMatrixFromFactorDouble(fact) else { return SparseIterativeParameterError }
    return _sparseSolveMatrixDouble(A, B, X)
}

func _sparseSolveFactoredInPlaceVectorFloat(
    _ fact: SparseOpaqueFactorization_Float,
    _ xb: DenseVector_Float
) {
    let n = Int(xb.count)
    var copy = [Float](repeating: 0, count: max(n, 1))
    if n > 0 {
        copy.withUnsafeMutableBufferPointer { bp in
            bp.baseAddress!.update(from: xb.data, count: n)
        }
    }
    copy.withUnsafeMutableBufferPointer { bp in
        let b = DenseVector_Float(count: xb.count, data: bp.baseAddress!)
        _ = _sparseSolveFactoredVectorFloat(fact, b, xb)
    }
}

func _sparseSolveFactoredInPlaceVectorDouble(
    _ fact: SparseOpaqueFactorization_Double,
    _ xb: DenseVector_Double
) {
    let n = Int(xb.count)
    var copy = [Double](repeating: 0, count: max(n, 1))
    if n > 0 {
        copy.withUnsafeMutableBufferPointer { bp in
            bp.baseAddress!.update(from: xb.data, count: n)
        }
    }
    copy.withUnsafeMutableBufferPointer { bp in
        let b = DenseVector_Double(count: xb.count, data: bp.baseAddress!)
        _ = _sparseSolveFactoredVectorDouble(fact, b, xb)
    }
}

func _sparseSolveFactoredInPlaceMatrixFloat(
    _ fact: SparseOpaqueFactorization_Float,
    _ XB: DenseMatrix_Float
) {
    let n = Int(XB.rowCount)
    let k = Int(XB.columnCount)
    let stride = Int(XB.columnStride)
    let count = max(stride * k, n * k)
    var copy = [Float](repeating: 0, count: max(count, 1))
    if count > 0 {
        copy.withUnsafeMutableBufferPointer { bp in
            bp.baseAddress!.update(from: XB.data, count: count)
        }
    }
    copy.withUnsafeMutableBufferPointer { bp in
        let B = DenseMatrix_Float(
            rowCount: XB.rowCount,
            columnCount: XB.columnCount,
            columnStride: XB.columnStride,
            attributes: XB.attributes,
            data: bp.baseAddress!
        )
        _ = _sparseSolveFactoredMatrixFloat(fact, B, XB)
    }
}

func _sparseSolveFactoredInPlaceMatrixDouble(
    _ fact: SparseOpaqueFactorization_Double,
    _ XB: DenseMatrix_Double
) {
    let n = Int(XB.rowCount)
    let k = Int(XB.columnCount)
    let stride = Int(XB.columnStride)
    let count = max(stride * k, n * k)
    var copy = [Double](repeating: 0, count: max(count, 1))
    if count > 0 {
        copy.withUnsafeMutableBufferPointer { bp in
            bp.baseAddress!.update(from: XB.data, count: count)
        }
    }
    copy.withUnsafeMutableBufferPointer { bp in
        let B = DenseMatrix_Double(
            rowCount: XB.rowCount,
            columnCount: XB.columnCount,
            columnStride: XB.columnStride,
            attributes: XB.attributes,
            data: bp.baseAddress!
        )
        _ = _sparseSolveFactoredMatrixDouble(fact, B, XB)
    }
}
