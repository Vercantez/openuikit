import Foundation

/// Linux SparseBLAS (`sparse_*`) starting point. Float and Double COO matrices
/// are real. Complex constructors return `nil` (no complex sparse runtime).
/// Status `0` is success; `-1` is illegal/fail-closed. Named `SPARSE_*` status
/// macros remain sequential placeholders and are not used as Apple values.

private let _sparseOK = sparse_status(rawValue: 0)
private let _sparseBad = sparse_status(rawValue: -1)

final class _SparseHostMatrix {
    enum Scalar {
        case float
        case double
    }
    let scalar: Scalar
    var rows: Int
    var cols: Int
    var committed = false
    var floats: [(Int64, Int64, Float)] = []
    var doubles: [(Int64, Int64, Double)] = []
    var blockRow = 1
    var blockCol = 1
    var property = 0

    init(scalar: Scalar, rows: Int, cols: Int) {
        self.scalar = scalar
        self.rows = rows
        self.cols = cols
    }
}

private func _sparseRetain(_ matrix: _SparseHostMatrix) -> OpaquePointer {
    OpaquePointer(Unmanaged.passRetained(matrix).toOpaque())
}

private func _sparseFromOpaque(_ pointer: OpaquePointer?) -> _SparseHostMatrix? {
    guard let pointer else { return nil }
    return Unmanaged<_SparseHostMatrix>.fromOpaque(UnsafeRawPointer(pointer)).takeUnretainedValue()
}

private func _sparseFromRaw(_ pointer: UnsafeMutableRawPointer?) -> _SparseHostMatrix? {
    guard let pointer else { return nil }
    return Unmanaged<_SparseHostMatrix>.fromOpaque(pointer).takeUnretainedValue()
}

private func _sparseRelease(_ pointer: UnsafeMutableRawPointer?) -> sparse_status {
    guard let pointer else { return _sparseBad }
    Unmanaged<_SparseHostMatrix>.fromOpaque(pointer).release()
    return _sparseOK
}

@discardableResult
public func sparse_matrix_create_float(_ M: sparse_dimension, _ N: sparse_dimension) -> sparse_matrix_float! {
    guard M > 0, N > 0 else { return nil }
    return _sparseRetain(_SparseHostMatrix(scalar: .float, rows: Int(M), cols: Int(N)))
}

@discardableResult
public func sparse_matrix_create_double(_ M: sparse_dimension, _ N: sparse_dimension) -> sparse_matrix_double! {
    guard M > 0, N > 0 else { return nil }
    return _sparseRetain(_SparseHostMatrix(scalar: .double, rows: Int(M), cols: Int(N)))
}

@discardableResult
public func sparse_matrix_create_float_complex(_ M: sparse_dimension, _ N: sparse_dimension) -> sparse_matrix_float_complex! {
    _ = M; _ = N
    return nil
}

@discardableResult
public func sparse_matrix_create_double_complex(_ M: sparse_dimension, _ N: sparse_dimension) -> sparse_matrix_double_complex! {
    _ = M; _ = N
    return nil
}

@discardableResult
public func sparse_matrix_block_create_float(
    _ Mb: sparse_dimension, _ Nb: sparse_dimension, _ k: sparse_dimension, _ l: sparse_dimension
) -> sparse_matrix_float! {
    guard let matrix = sparse_matrix_create_float(Mb * k, Nb * l) else { return nil }
    if let host = _sparseFromOpaque(matrix) {
        host.blockRow = Int(k)
        host.blockCol = Int(l)
    }
    return matrix
}

@discardableResult
public func sparse_matrix_block_create_double(
    _ Mb: sparse_dimension, _ Nb: sparse_dimension, _ k: sparse_dimension, _ l: sparse_dimension
) -> sparse_matrix_double! {
    guard let matrix = sparse_matrix_create_double(Mb * k, Nb * l) else { return nil }
    if let host = _sparseFromOpaque(matrix) {
        host.blockRow = Int(k)
        host.blockCol = Int(l)
    }
    return matrix
}

@discardableResult
public func sparse_matrix_block_create_float_complex(
    _ Mb: sparse_dimension, _ Nb: sparse_dimension, _ k: sparse_dimension, _ l: sparse_dimension
) -> sparse_matrix_float_complex! {
    _ = Mb; _ = Nb; _ = k; _ = l
    return nil
}

@discardableResult
public func sparse_matrix_block_create_double_complex(
    _ Mb: sparse_dimension, _ Nb: sparse_dimension, _ k: sparse_dimension, _ l: sparse_dimension
) -> sparse_matrix_double_complex! {
    _ = Mb; _ = Nb; _ = k; _ = l
    return nil
}

@discardableResult
public func sparse_matrix_variable_block_create_float(
    _ Mb: sparse_dimension, _ Nb: sparse_dimension,
    _ K: UnsafePointer<sparse_dimension>!, _ L: UnsafePointer<sparse_dimension>!
) -> sparse_matrix_float! {
    guard Mb > 0, Nb > 0, let K, let L else { return nil }
    var rows = 0
    var cols = 0
    for i in 0..<Int(Mb) { rows += Int(K[i]) }
    for j in 0..<Int(Nb) { cols += Int(L[j]) }
    return sparse_matrix_create_float(sparse_dimension(rows), sparse_dimension(cols))
}

@discardableResult
public func sparse_matrix_variable_block_create_double(
    _ Mb: sparse_dimension, _ Nb: sparse_dimension,
    _ K: UnsafePointer<sparse_dimension>!, _ L: UnsafePointer<sparse_dimension>!
) -> sparse_matrix_double! {
    guard Mb > 0, Nb > 0, let K, let L else { return nil }
    var rows = 0
    var cols = 0
    for i in 0..<Int(Mb) { rows += Int(K[i]) }
    for j in 0..<Int(Nb) { cols += Int(L[j]) }
    return sparse_matrix_create_double(sparse_dimension(rows), sparse_dimension(cols))
}

@discardableResult
public func sparse_matrix_variable_block_create_float_complex(
    _ Mb: sparse_dimension, _ Nb: sparse_dimension,
    _ K: UnsafePointer<sparse_dimension>!, _ L: UnsafePointer<sparse_dimension>!
) -> sparse_matrix_float_complex! {
    _ = Mb; _ = Nb; _ = K; _ = L
    return nil
}

@discardableResult
public func sparse_matrix_variable_block_create_double_complex(
    _ Mb: sparse_dimension, _ Nb: sparse_dimension,
    _ K: UnsafePointer<sparse_dimension>!, _ L: UnsafePointer<sparse_dimension>!
) -> sparse_matrix_double_complex! {
    _ = Mb; _ = Nb; _ = K; _ = L
    return nil
}

@discardableResult
public func sparse_commit(_ A: UnsafeMutableRawPointer!) -> sparse_status {
    guard let host = _sparseFromRaw(A) else { return _sparseBad }
    host.committed = true
    return _sparseOK
}

@discardableResult
public func sparse_matrix_destroy(_ A: UnsafeMutableRawPointer!) -> sparse_status {
    _sparseRelease(A)
}

@discardableResult
public func sparse_insert_entry_float(
    _ A: sparse_matrix_float!, _ val: Float, _ i: sparse_index, _ j: sparse_index
) -> sparse_status {
    guard let host = _sparseFromOpaque(A), host.scalar == .float, !host.committed else { return _sparseBad }
    guard i >= 0, j >= 0, i < host.rows, j < host.cols else { return _sparseBad }
    host.floats.append((i, j, val))
    return _sparseOK
}

@discardableResult
public func sparse_insert_entry_double(
    _ A: sparse_matrix_double!, _ val: Double, _ i: sparse_index, _ j: sparse_index
) -> sparse_status {
    guard let host = _sparseFromOpaque(A), host.scalar == .double, !host.committed else { return _sparseBad }
    guard i >= 0, j >= 0, i < host.rows, j < host.cols else { return _sparseBad }
    host.doubles.append((i, j, val))
    return _sparseOK
}

@discardableResult
public func sparse_insert_entries_float(
    _ A: sparse_matrix_float!, _ N: sparse_dimension,
    _ val: UnsafePointer<Float>!, _ indx: UnsafePointer<sparse_index>!, _ jndx: UnsafePointer<sparse_index>!
) -> sparse_status {
    guard let val, let indx, let jndx else { return _sparseBad }
    for k in 0..<Int(N) {
        if sparse_insert_entry_float(A, val[k], indx[k], jndx[k]) != _sparseOK { return _sparseBad }
    }
    return _sparseOK
}

@discardableResult
public func sparse_insert_entries_double(
    _ A: sparse_matrix_double!, _ N: sparse_dimension,
    _ val: UnsafePointer<Double>!, _ indx: UnsafePointer<sparse_index>!, _ jndx: UnsafePointer<sparse_index>!
) -> sparse_status {
    guard let val, let indx, let jndx else { return _sparseBad }
    for k in 0..<Int(N) {
        if sparse_insert_entry_double(A, val[k], indx[k], jndx[k]) != _sparseOK { return _sparseBad }
    }
    return _sparseOK
}

@discardableResult
public func sparse_insert_entries_float_complex(
    _ A: sparse_matrix_float_complex!, _ N: sparse_dimension,
    _ val: OpaquePointer!, _ indx: UnsafePointer<sparse_index>!, _ jndx: UnsafePointer<sparse_index>!
) -> sparse_status {
    _ = A; _ = N; _ = val; _ = indx; _ = jndx
    return _sparseBad
}

@discardableResult
public func sparse_insert_entries_double_complex(
    _ A: sparse_matrix_double_complex!, _ N: sparse_dimension,
    _ val: OpaquePointer!, _ indx: UnsafePointer<sparse_index>!, _ jndx: UnsafePointer<sparse_index>!
) -> sparse_status {
    _ = A; _ = N; _ = val; _ = indx; _ = jndx
    return _sparseBad
}

@discardableResult
public func sparse_insert_col_float(
    _ A: sparse_matrix_float!, _ j: sparse_index, _ nz: sparse_dimension,
    _ val: UnsafePointer<Float>!, _ indx: UnsafePointer<sparse_index>!
) -> sparse_status {
    guard let val, let indx else { return _sparseBad }
    for k in 0..<Int(nz) {
        if sparse_insert_entry_float(A, val[k], indx[k], j) != _sparseOK { return _sparseBad }
    }
    return _sparseOK
}

@discardableResult
public func sparse_insert_col_double(
    _ A: sparse_matrix_double!, _ j: sparse_index, _ nz: sparse_dimension,
    _ val: UnsafePointer<Double>!, _ indx: UnsafePointer<sparse_index>!
) -> sparse_status {
    guard let val, let indx else { return _sparseBad }
    for k in 0..<Int(nz) {
        if sparse_insert_entry_double(A, val[k], indx[k], j) != _sparseOK { return _sparseBad }
    }
    return _sparseOK
}

@discardableResult
public func sparse_insert_col_float_complex(
    _ A: sparse_matrix_float_complex!, _ j: sparse_index, _ nz: sparse_dimension,
    _ val: OpaquePointer!, _ indx: UnsafePointer<sparse_index>!
) -> sparse_status {
    _ = A; _ = j; _ = nz; _ = val; _ = indx
    return _sparseBad
}

@discardableResult
public func sparse_insert_col_double_complex(
    _ A: sparse_matrix_double_complex!, _ j: sparse_index, _ nz: sparse_dimension,
    _ val: OpaquePointer!, _ indx: UnsafePointer<sparse_index>!
) -> sparse_status {
    _ = A; _ = j; _ = nz; _ = val; _ = indx
    return _sparseBad
}

@discardableResult
public func sparse_insert_row_float(
    _ A: sparse_matrix_float!, _ i: sparse_index, _ nz: sparse_dimension,
    _ val: UnsafePointer<Float>!, _ jndx: UnsafePointer<sparse_index>!
) -> sparse_status {
    guard let val, let jndx else { return _sparseBad }
    for k in 0..<Int(nz) {
        if sparse_insert_entry_float(A, val[k], i, jndx[k]) != _sparseOK { return _sparseBad }
    }
    return _sparseOK
}

@discardableResult
public func sparse_insert_row_double(
    _ A: sparse_matrix_double!, _ i: sparse_index, _ nz: sparse_dimension,
    _ val: UnsafePointer<Double>!, _ jndx: UnsafePointer<sparse_index>!
) -> sparse_status {
    guard let val, let jndx else { return _sparseBad }
    for k in 0..<Int(nz) {
        if sparse_insert_entry_double(A, val[k], i, jndx[k]) != _sparseOK { return _sparseBad }
    }
    return _sparseOK
}

@discardableResult
public func sparse_insert_row_float_complex(
    _ A: sparse_matrix_float_complex!, _ i: sparse_index, _ nz: sparse_dimension,
    _ val: OpaquePointer!, _ jndx: UnsafePointer<sparse_index>!
) -> sparse_status {
    _ = A; _ = i; _ = nz; _ = val; _ = jndx
    return _sparseBad
}

@discardableResult
public func sparse_insert_row_double_complex(
    _ A: sparse_matrix_double_complex!, _ i: sparse_index, _ nz: sparse_dimension,
    _ val: OpaquePointer!, _ jndx: UnsafePointer<sparse_index>!
) -> sparse_status {
    _ = A; _ = i; _ = nz; _ = val; _ = jndx
    return _sparseBad
}

@discardableResult
public func sparse_insert_block_float(
    _ A: sparse_matrix_float!, _ val: UnsafePointer<Float>!,
    _ row_stride: sparse_dimension, _ col_stride: sparse_dimension,
    _ bi: sparse_index, _ bj: sparse_index
) -> sparse_status {
    guard let host = _sparseFromOpaque(A), let val, host.scalar == .float else { return _sparseBad }
    let br = host.blockRow
    let bc = host.blockCol
    let rs = max(Int(row_stride), 1)
    _ = col_stride
    for r in 0..<br {
        for c in 0..<bc {
            let v = val[r * rs + c]
            if sparse_insert_entry_float(A, v, bi * Int64(br) + Int64(r), bj * Int64(bc) + Int64(c)) != _sparseOK {
                return _sparseBad
            }
        }
    }
    return _sparseOK
}

@discardableResult
public func sparse_insert_block_double(
    _ A: sparse_matrix_double!, _ val: UnsafePointer<Double>!,
    _ row_stride: sparse_dimension, _ col_stride: sparse_dimension,
    _ bi: sparse_index, _ bj: sparse_index
) -> sparse_status {
    guard let host = _sparseFromOpaque(A), let val, host.scalar == .double else { return _sparseBad }
    let br = host.blockRow
    let bc = host.blockCol
    let rs = max(Int(row_stride), 1)
    _ = col_stride
    for r in 0..<br {
        for c in 0..<bc {
            let v = val[r * rs + c]
            if sparse_insert_entry_double(A, v, bi * Int64(br) + Int64(r), bj * Int64(bc) + Int64(c)) != _sparseOK {
                return _sparseBad
            }
        }
    }
    return _sparseOK
}

@discardableResult
public func sparse_insert_block_float_complex(
    _ A: sparse_matrix_float_complex!, _ val: OpaquePointer!,
    _ row_stride: sparse_dimension, _ col_stride: sparse_dimension,
    _ bi: sparse_index, _ bj: sparse_index
) -> sparse_status {
    _ = A; _ = val; _ = row_stride; _ = col_stride; _ = bi; _ = bj
    return _sparseBad
}

@discardableResult
public func sparse_insert_block_double_complex(
    _ A: sparse_matrix_double_complex!, _ val: OpaquePointer!,
    _ row_stride: sparse_dimension, _ col_stride: sparse_dimension,
    _ bi: sparse_index, _ bj: sparse_index
) -> sparse_status {
    _ = A; _ = val; _ = row_stride; _ = col_stride; _ = bi; _ = bj
    return _sparseBad
}

@discardableResult
public func sparse_get_matrix_number_of_rows(_ A: UnsafeMutableRawPointer!) -> sparse_dimension {
    sparse_dimension(_sparseFromRaw(A)?.rows ?? 0)
}

@discardableResult
public func sparse_get_matrix_number_of_columns(_ A: UnsafeMutableRawPointer!) -> sparse_dimension {
    sparse_dimension(_sparseFromRaw(A)?.cols ?? 0)
}

@discardableResult
public func sparse_get_matrix_nonzero_count(_ A: UnsafeMutableRawPointer!) -> Int {
    guard let host = _sparseFromRaw(A) else { return 0 }
    return host.scalar == .float ? host.floats.count : host.doubles.count
}

@discardableResult
public func sparse_get_matrix_nonzero_count_for_column(_ A: UnsafeMutableRawPointer!, _ j: sparse_index) -> Int {
    guard let host = _sparseFromRaw(A) else { return 0 }
    if host.scalar == .float { return host.floats.filter { $0.1 == j }.count }
    return host.doubles.filter { $0.1 == j }.count
}

@discardableResult
public func sparse_get_matrix_nonzero_count_for_row(_ A: UnsafeMutableRawPointer!, _ i: sparse_index) -> Int {
    guard let host = _sparseFromRaw(A) else { return 0 }
    if host.scalar == .float { return host.floats.filter { $0.0 == i }.count }
    return host.doubles.filter { $0.0 == i }.count
}

@discardableResult
public func sparse_get_block_dimension_for_col(_ A: UnsafeMutableRawPointer!, _ j: sparse_index) -> Int {
    _ = j
    return _sparseFromRaw(A)?.blockCol ?? 0
}

@discardableResult
public func sparse_get_block_dimension_for_row(_ A: UnsafeMutableRawPointer!, _ i: sparse_index) -> Int {
    _ = i
    return _sparseFromRaw(A)?.blockRow ?? 0
}

@discardableResult
public func sparse_get_matrix_property(_ A: UnsafeMutableRawPointer!, _ pname: sparse_matrix_property) -> Int {
    _ = pname
    return _sparseFromRaw(A)?.property ?? 0
}

@discardableResult
public func sparse_set_matrix_property(_ A: UnsafeMutableRawPointer!, _ pname: sparse_matrix_property) -> sparse_status {
    guard let host = _sparseFromRaw(A) else { return _sparseBad }
    host.property = Int(pname.rawValue)
    return _sparseOK
}

@discardableResult
public func sparse_matrix_vector_product_dense_float(
    _ transa: CBLAS_TRANSPOSE, _ alpha: Float, _ A: sparse_matrix_float!,
    _ x: UnsafePointer<Float>!, _ incx: sparse_stride,
    _ y: UnsafeMutablePointer<Float>!, _ incy: sparse_stride
) -> sparse_status {
    guard let host = _sparseFromOpaque(A), let x, let y, host.scalar == .float else { return _sparseBad }
    let ix = max(Int(incx), 1)
    let iy = max(Int(incy), 1)
    let transpose = transa.rawValue != CblasNoTrans.rawValue
    let outN = transpose ? host.cols : host.rows
    for i in 0..<outN { y[i * iy] = 0 }
    for (r, c, v) in host.floats {
        let rr = Int(r)
        let cc = Int(c)
        if transpose {
            y[cc * iy] += alpha * v * x[rr * ix]
        } else {
            y[rr * iy] += alpha * v * x[cc * ix]
        }
    }
    return _sparseOK
}

@discardableResult
public func sparse_matrix_vector_product_dense_double(
    _ transa: CBLAS_TRANSPOSE, _ alpha: Double, _ A: sparse_matrix_double!,
    _ x: UnsafePointer<Double>!, _ incx: sparse_stride,
    _ y: UnsafeMutablePointer<Double>!, _ incy: sparse_stride
) -> sparse_status {
    guard let host = _sparseFromOpaque(A), let x, let y, host.scalar == .double else { return _sparseBad }
    let ix = max(Int(incx), 1)
    let iy = max(Int(incy), 1)
    let transpose = transa.rawValue != CblasNoTrans.rawValue
    let outN = transpose ? host.cols : host.rows
    for i in 0..<outN { y[i * iy] = 0 }
    for (r, c, v) in host.doubles {
        let rr = Int(r)
        let cc = Int(c)
        if transpose {
            y[cc * iy] += alpha * v * x[rr * ix]
        } else {
            y[rr * iy] += alpha * v * x[cc * ix]
        }
    }
    return _sparseOK
}

@discardableResult
public func sparse_matrix_product_dense_float(
    _ order: CBLAS_ORDER, _ transa: CBLAS_TRANSPOSE, _ n: sparse_dimension, _ alpha: Float,
    _ A: sparse_matrix_float!, _ B: UnsafePointer<Float>!, _ ldb: sparse_dimension,
    _ C: UnsafeMutablePointer<Float>!, _ ldc: sparse_dimension
) -> sparse_status {
    guard let host = _sparseFromOpaque(A), let B, let C, host.scalar == .float else { return _sparseBad }
    let rhs = Int(n)
    let ldB = max(Int(ldb), 1)
    let ldC = max(Int(ldc), 1)
    let rowMajor = order.rawValue == CblasRowMajor.rawValue
    for k in 0..<rhs {
        var x = [Float](repeating: 0, count: host.cols)
        var y = [Float](repeating: 0, count: host.rows)
        for i in 0..<host.cols {
            x[i] = rowMajor ? B[i * ldB + k] : B[k * ldB + i]
        }
        _ = sparse_matrix_vector_product_dense_float(transa, alpha, A, x, 1, &y, 1)
        for i in 0..<host.rows {
            if rowMajor {
                C[i * ldC + k] = y[i]
            } else {
                C[k * ldC + i] = y[i]
            }
        }
    }
    return _sparseOK
}

@discardableResult
public func sparse_matrix_product_dense_double(
    _ order: CBLAS_ORDER, _ transa: CBLAS_TRANSPOSE, _ n: sparse_dimension, _ alpha: Double,
    _ A: sparse_matrix_double!, _ B: UnsafePointer<Double>!, _ ldb: sparse_dimension,
    _ C: UnsafeMutablePointer<Double>!, _ ldc: sparse_dimension
) -> sparse_status {
    guard let host = _sparseFromOpaque(A), let B, let C, host.scalar == .double else { return _sparseBad }
    let rhs = Int(n)
    let ldB = max(Int(ldb), 1)
    let ldC = max(Int(ldc), 1)
    let rowMajor = order.rawValue == CblasRowMajor.rawValue
    for k in 0..<rhs {
        var x = [Double](repeating: 0, count: host.cols)
        var y = [Double](repeating: 0, count: host.rows)
        for i in 0..<host.cols {
            x[i] = rowMajor ? B[i * ldB + k] : B[k * ldB + i]
        }
        _ = sparse_matrix_vector_product_dense_double(transa, alpha, A, x, 1, &y, 1)
        for i in 0..<host.rows {
            if rowMajor {
                C[i * ldC + k] = y[i]
            } else {
                C[k * ldC + i] = y[i]
            }
        }
    }
    return _sparseOK
}

@discardableResult
public func sparse_matrix_product_sparse_float(
    _ order: CBLAS_ORDER, _ transa: CBLAS_TRANSPOSE, _ alpha: Float,
    _ A: sparse_matrix_float!, _ B: sparse_matrix_float!,
    _ C: UnsafeMutablePointer<Float>!, _ ldc: sparse_dimension
) -> sparse_status {
    guard let a = _sparseFromOpaque(A), let b = _sparseFromOpaque(B), let C else { return _sparseBad }
    _ = a
    let denseB = _sparseDenseFloat(b)
    return sparse_matrix_product_dense_float(
        order, transa, sparse_dimension(b.cols), alpha, A, denseB, sparse_dimension(b.rows), C, ldc
    )
}

@discardableResult
public func sparse_matrix_product_sparse_double(
    _ order: CBLAS_ORDER, _ transa: CBLAS_TRANSPOSE, _ alpha: Double,
    _ A: sparse_matrix_double!, _ B: sparse_matrix_double!,
    _ C: UnsafeMutablePointer<Double>!, _ ldc: sparse_dimension
) -> sparse_status {
    guard let a = _sparseFromOpaque(A), let b = _sparseFromOpaque(B), let C else { return _sparseBad }
    _ = a
    let denseB = _sparseDenseDouble(b)
    return sparse_matrix_product_dense_double(
        order, transa, sparse_dimension(b.cols), alpha, A, denseB, sparse_dimension(b.rows), C, ldc
    )
}

private func _sparseDenseFloat(_ host: _SparseHostMatrix) -> [Float] {
    var dense = [Float](repeating: 0, count: host.rows * host.cols)
    for (r, c, v) in host.floats {
        dense[Int(r) * host.cols + Int(c)] += v
    }
    return dense
}

private func _sparseDenseDouble(_ host: _SparseHostMatrix) -> [Double] {
    var dense = [Double](repeating: 0, count: host.rows * host.cols)
    for (r, c, v) in host.doubles {
        dense[Int(r) * host.cols + Int(c)] += v
    }
    return dense
}

@discardableResult
public func sparse_matrix_trace_float(_ A: sparse_matrix_float!, _ offset: sparse_index) -> Float {
    guard let host = _sparseFromOpaque(A), host.scalar == .float else { return 0 }
    var sum: Float = 0
    for (r, c, v) in host.floats where r + offset == c { sum += v }
    return sum
}

@discardableResult
public func sparse_matrix_trace_double(_ A: sparse_matrix_double!, _ offset: sparse_index) -> Double {
    guard let host = _sparseFromOpaque(A), host.scalar == .double else { return 0 }
    var sum: Double = 0
    for (r, c, v) in host.doubles where r + offset == c { sum += v }
    return sum
}

private func _sparseNormKind(_ norm: sparse_norm) -> Int {
    if norm.rawValue == SPARSE_NORM_ONE.rawValue { return 1 }
    if norm.rawValue == SPARSE_NORM_INF.rawValue { return 3 }
    if norm.rawValue == SPARSE_NORM_TWO.rawValue { return 2 }
    return 1
}

@discardableResult
public func sparse_elementwise_norm_float(_ A: sparse_matrix_float!, _ norm: sparse_norm) -> Float {
    guard let host = _sparseFromOpaque(A), host.scalar == .float else { return 0 }
    let values = host.floats.map { abs($0.2) }
    switch _sparseNormKind(norm) {
    case 3: return values.max() ?? 0
    case 2: return values.reduce(0) { $0 + $1 * $1 }.squareRoot()
    default: return values.reduce(0, +)
    }
}

@discardableResult
public func sparse_elementwise_norm_double(_ A: sparse_matrix_double!, _ norm: sparse_norm) -> Double {
    guard let host = _sparseFromOpaque(A), host.scalar == .double else { return 0 }
    let values = host.doubles.map { abs($0.2) }
    switch _sparseNormKind(norm) {
    case 3: return values.max() ?? 0
    case 2: return values.reduce(0) { $0 + $1 * $1 }.squareRoot()
    default: return values.reduce(0, +)
    }
}

@discardableResult
public func sparse_elementwise_norm_float_complex(_ A: sparse_matrix_float_complex!, _ norm: sparse_norm) -> Float {
    _ = A; _ = norm
    return 0
}

@discardableResult
public func sparse_elementwise_norm_double_complex(_ A: sparse_matrix_double_complex!, _ norm: sparse_norm) -> Double {
    _ = A; _ = norm
    return 0
}

@discardableResult
public func sparse_operator_norm_float(_ A: sparse_matrix_float!, _ norm: sparse_norm) -> Float {
    sparse_elementwise_norm_float(A, norm)
}

@discardableResult
public func sparse_operator_norm_double(_ A: sparse_matrix_double!, _ norm: sparse_norm) -> Double {
    sparse_elementwise_norm_double(A, norm)
}

@discardableResult
public func sparse_operator_norm_float_complex(_ A: sparse_matrix_float_complex!, _ norm: sparse_norm) -> Float {
    _ = A; _ = norm
    return 0
}

@discardableResult
public func sparse_operator_norm_double_complex(_ A: sparse_matrix_double_complex!, _ norm: sparse_norm) -> Double {
    _ = A; _ = norm
    return 0
}

@discardableResult
public func sparse_inner_product_dense_float(
    _ nz: sparse_dimension, _ x: UnsafePointer<Float>!, _ indx: UnsafePointer<sparse_index>!,
    _ y: UnsafePointer<Float>!, _ incy: sparse_stride
) -> Float {
    guard let x, let indx, let y else { return 0 }
    let iy = max(Int(incy), 1)
    var s: Float = 0
    for k in 0..<Int(nz) {
        s += x[k] * y[Int(indx[k]) * iy]
    }
    return s
}

@discardableResult
public func sparse_inner_product_dense_double(
    _ nz: sparse_dimension, _ x: UnsafePointer<Double>!, _ indx: UnsafePointer<sparse_index>!,
    _ y: UnsafePointer<Double>!, _ incy: sparse_stride
) -> Double {
    guard let x, let indx, let y else { return 0 }
    let iy = max(Int(incy), 1)
    var s: Double = 0
    for k in 0..<Int(nz) {
        s += x[k] * y[Int(indx[k]) * iy]
    }
    return s
}

@discardableResult
public func sparse_inner_product_sparse_float(
    _ nzx: sparse_dimension, _ nzy: sparse_dimension,
    _ x: UnsafePointer<Float>!, _ indx: UnsafePointer<sparse_index>!,
    _ y: UnsafePointer<Float>!, _ indy: UnsafePointer<sparse_index>!
) -> Float {
    guard let x, let indx, let y, let indy else { return 0 }
    var map: [Int64: Float] = [:]
    for k in 0..<Int(nzx) { map[indx[k], default: 0] += x[k] }
    var s: Float = 0
    for k in 0..<Int(nzy) { s += (map[indy[k]] ?? 0) * y[k] }
    return s
}

@discardableResult
public func sparse_inner_product_sparse_double(
    _ nzx: sparse_dimension, _ nzy: sparse_dimension,
    _ x: UnsafePointer<Double>!, _ indx: UnsafePointer<sparse_index>!,
    _ y: UnsafePointer<Double>!, _ indy: UnsafePointer<sparse_index>!
) -> Double {
    guard let x, let indx, let y, let indy else { return 0 }
    var map: [Int64: Double] = [:]
    for k in 0..<Int(nzx) { map[indx[k], default: 0] += x[k] }
    var s: Double = 0
    for k in 0..<Int(nzy) { s += (map[indy[k]] ?? 0) * y[k] }
    return s
}

@discardableResult
public func sparse_get_vector_nonzero_count_float(
    _ N: sparse_dimension, _ x: UnsafePointer<Float>!, _ incx: sparse_stride
) -> Int {
    guard let x else { return 0 }
    let ix = max(Int(incx), 1)
    var n = 0
    for i in 0..<Int(N) where x[i * ix] != 0 { n += 1 }
    return n
}

@discardableResult
public func sparse_get_vector_nonzero_count_double(
    _ N: sparse_dimension, _ x: UnsafePointer<Double>!, _ incx: sparse_stride
) -> Int {
    guard let x else { return 0 }
    let ix = max(Int(incx), 1)
    var n = 0
    for i in 0..<Int(N) where x[i * ix] != 0 { n += 1 }
    return n
}

@discardableResult
public func sparse_get_vector_nonzero_count_float_complex(
    _ N: sparse_dimension, _ x: OpaquePointer!, _ incx: sparse_stride
) -> Int {
    _ = N; _ = x; _ = incx
    return 0
}

@discardableResult
public func sparse_get_vector_nonzero_count_double_complex(
    _ N: sparse_dimension, _ x: OpaquePointer!, _ incx: sparse_stride
) -> Int {
    _ = N; _ = x; _ = incx
    return 0
}

@discardableResult
public func sparse_pack_vector_float(
    _ N: sparse_dimension, _ nz: sparse_dimension, _ x: UnsafePointer<Float>!, _ incx: sparse_stride,
    _ y: UnsafeMutablePointer<Float>!, _ indy: UnsafeMutablePointer<sparse_index>!
) -> Int {
    guard let x, let y, let indy else { return 0 }
    let ix = max(Int(incx), 1)
    var count = 0
    for i in 0..<Int(N) where x[i * ix] != 0 && count < Int(nz) {
        y[count] = x[i * ix]
        indy[count] = sparse_index(i)
        count += 1
    }
    return count
}

@discardableResult
public func sparse_pack_vector_double(
    _ N: sparse_dimension, _ nz: sparse_dimension, _ x: UnsafePointer<Double>!, _ incx: sparse_stride,
    _ y: UnsafeMutablePointer<Double>!, _ indy: UnsafeMutablePointer<sparse_index>!
) -> Int {
    guard let x, let y, let indy else { return 0 }
    let ix = max(Int(incx), 1)
    var count = 0
    for i in 0..<Int(N) where x[i * ix] != 0 && count < Int(nz) {
        y[count] = x[i * ix]
        indy[count] = sparse_index(i)
        count += 1
    }
    return count
}

@discardableResult
public func sparse_pack_vector_float_complex(
    _ N: sparse_dimension, _ nz: sparse_dimension, _ x: OpaquePointer!, _ incx: sparse_stride,
    _ y: OpaquePointer!, _ indy: UnsafeMutablePointer<sparse_index>!
) -> Int {
    _ = N; _ = nz; _ = x; _ = incx; _ = y; _ = indy
    return 0
}

@discardableResult
public func sparse_pack_vector_double_complex(
    _ N: sparse_dimension, _ nz: sparse_dimension, _ x: OpaquePointer!, _ incx: sparse_stride,
    _ y: OpaquePointer!, _ indy: UnsafeMutablePointer<sparse_index>!
) -> Int {
    _ = N; _ = nz; _ = x; _ = incx; _ = y; _ = indy
    return 0
}

public func sparse_unpack_vector_float(
    _ N: sparse_dimension, _ nz: sparse_dimension, _ zero: Bool,
    _ x: UnsafePointer<Float>!, _ indx: UnsafePointer<sparse_index>!,
    _ y: UnsafeMutablePointer<Float>!, _ incy: sparse_stride
) {
    guard let x, let indx, let y else { return }
    let iy = max(Int(incy), 1)
    if zero {
        for i in 0..<Int(N) { y[i * iy] = 0 }
    }
    for k in 0..<Int(nz) {
        y[Int(indx[k]) * iy] = x[k]
    }
}

public func sparse_unpack_vector_double(
    _ N: sparse_dimension, _ nz: sparse_dimension, _ zero: Bool,
    _ x: UnsafePointer<Double>!, _ indx: UnsafePointer<sparse_index>!,
    _ y: UnsafeMutablePointer<Double>!, _ incy: sparse_stride
) {
    guard let x, let indx, let y else { return }
    let iy = max(Int(incy), 1)
    if zero {
        for i in 0..<Int(N) { y[i * iy] = 0 }
    }
    for k in 0..<Int(nz) {
        y[Int(indx[k]) * iy] = x[k]
    }
}

public func sparse_unpack_vector_float_complex(
    _ N: sparse_dimension, _ nz: sparse_dimension, _ zero: Bool,
    _ x: OpaquePointer!, _ indx: UnsafePointer<sparse_index>!,
    _ y: OpaquePointer!, _ incy: sparse_stride
) {
    _ = N; _ = nz; _ = zero; _ = x; _ = indx; _ = y; _ = incy
}

public func sparse_unpack_vector_double_complex(
    _ N: sparse_dimension, _ nz: sparse_dimension, _ zero: Bool,
    _ x: OpaquePointer!, _ indx: UnsafePointer<sparse_index>!,
    _ y: OpaquePointer!, _ incy: sparse_stride
) {
    _ = N; _ = nz; _ = zero; _ = x; _ = indx; _ = y; _ = incy
}

public func sparse_vector_add_with_scale_dense_float(
    _ nz: sparse_dimension, _ alpha: Float, _ x: UnsafePointer<Float>!,
    _ indx: UnsafePointer<sparse_index>!, _ y: UnsafeMutablePointer<Float>!, _ incy: sparse_stride
) {
    guard let x, let indx, let y else { return }
    let iy = max(Int(incy), 1)
    for k in 0..<Int(nz) {
        y[Int(indx[k]) * iy] += alpha * x[k]
    }
}

public func sparse_vector_add_with_scale_dense_double(
    _ nz: sparse_dimension, _ alpha: Double, _ x: UnsafePointer<Double>!,
    _ indx: UnsafePointer<sparse_index>!, _ y: UnsafeMutablePointer<Double>!, _ incy: sparse_stride
) {
    guard let x, let indx, let y else { return }
    let iy = max(Int(incy), 1)
    for k in 0..<Int(nz) {
        y[Int(indx[k]) * iy] += alpha * x[k]
    }
}

@discardableResult
public func sparse_vector_norm_float(
    _ nz: sparse_dimension, _ x: UnsafePointer<Float>!, _ indx: UnsafePointer<sparse_index>!, _ norm: sparse_norm
) -> Float {
    _ = indx
    guard let x else { return 0 }
    let values = (0..<Int(nz)).map { abs(x[$0]) }
    switch _sparseNormKind(norm) {
    case 3: return values.max() ?? 0
    case 2: return values.reduce(0) { $0 + $1 * $1 }.squareRoot()
    default: return values.reduce(0, +)
    }
}

@discardableResult
public func sparse_vector_norm_double(
    _ nz: sparse_dimension, _ x: UnsafePointer<Double>!, _ indx: UnsafePointer<sparse_index>!, _ norm: sparse_norm
) -> Double {
    _ = indx
    guard let x else { return 0 }
    let values = (0..<Int(nz)).map { abs(x[$0]) }
    switch _sparseNormKind(norm) {
    case 3: return values.max() ?? 0
    case 2: return values.reduce(0) { $0 + $1 * $1 }.squareRoot()
    default: return values.reduce(0, +)
    }
}

@discardableResult
public func sparse_vector_norm_float_complex(
    _ nz: sparse_dimension, _ x: OpaquePointer!, _ indx: UnsafePointer<sparse_index>!, _ norm: sparse_norm
) -> Float {
    _ = nz; _ = x; _ = indx; _ = norm
    return 0
}

@discardableResult
public func sparse_vector_norm_double_complex(
    _ nz: sparse_dimension, _ x: OpaquePointer!, _ indx: UnsafePointer<sparse_index>!, _ norm: sparse_norm
) -> Double {
    _ = nz; _ = x; _ = indx; _ = norm
    return 0
}

@discardableResult
public func sparse_extract_sparse_row_float(
    _ A: sparse_matrix_float!, _ row: sparse_index, _ column_start: sparse_index,
    _ column_end: UnsafeMutablePointer<sparse_index>!, _ nz: sparse_dimension,
    _ val: UnsafeMutablePointer<Float>!, _ jndx: UnsafeMutablePointer<sparse_index>!
) -> sparse_status {
    guard let host = _sparseFromOpaque(A), let val, let jndx, host.scalar == .float else { return _sparseBad }
    let matches = host.floats.filter { $0.0 == row && $0.1 >= column_start }.prefix(Int(nz))
    var k = 0
    var last = column_start
    for (_, c, v) in matches {
        val[k] = v
        jndx[k] = c
        last = c + 1
        k += 1
    }
    column_end?.pointee = last
    return _sparseOK
}

@discardableResult
public func sparse_extract_sparse_row_double(
    _ A: sparse_matrix_double!, _ row: sparse_index, _ column_start: sparse_index,
    _ column_end: UnsafeMutablePointer<sparse_index>!, _ nz: sparse_dimension,
    _ val: UnsafeMutablePointer<Double>!, _ jndx: UnsafeMutablePointer<sparse_index>!
) -> sparse_status {
    guard let host = _sparseFromOpaque(A), let val, let jndx, host.scalar == .double else { return _sparseBad }
    let matches = host.doubles.filter { $0.0 == row && $0.1 >= column_start }.prefix(Int(nz))
    var k = 0
    var last = column_start
    for (_, c, v) in matches {
        val[k] = v
        jndx[k] = c
        last = c + 1
        k += 1
    }
    column_end?.pointee = last
    return _sparseOK
}

@discardableResult
public func sparse_extract_sparse_row_float_complex(
    _ A: sparse_matrix_float_complex!, _ row: sparse_index, _ column_start: sparse_index,
    _ column_end: UnsafeMutablePointer<sparse_index>!, _ nz: sparse_dimension,
    _ val: OpaquePointer!, _ jndx: UnsafeMutablePointer<sparse_index>!
) -> sparse_status {
    _ = A; _ = row; _ = column_start; _ = column_end; _ = nz; _ = val; _ = jndx
    return _sparseBad
}

@discardableResult
public func sparse_extract_sparse_row_double_complex(
    _ A: sparse_matrix_double_complex!, _ row: sparse_index, _ column_start: sparse_index,
    _ column_end: UnsafeMutablePointer<sparse_index>!, _ nz: sparse_dimension,
    _ val: OpaquePointer!, _ jndx: UnsafeMutablePointer<sparse_index>!
) -> sparse_status {
    _ = A; _ = row; _ = column_start; _ = column_end; _ = nz; _ = val; _ = jndx
    return _sparseBad
}

@discardableResult
public func sparse_extract_sparse_column_float(
    _ A: sparse_matrix_float!, _ column: sparse_index, _ row_start: sparse_index,
    _ row_end: UnsafeMutablePointer<sparse_index>!, _ nz: sparse_dimension,
    _ val: UnsafeMutablePointer<Float>!, _ indx: UnsafeMutablePointer<sparse_index>!
) -> sparse_status {
    guard let host = _sparseFromOpaque(A), let val, let indx, host.scalar == .float else { return _sparseBad }
    let matches = host.floats.filter { $0.1 == column && $0.0 >= row_start }.prefix(Int(nz))
    var k = 0
    var last = row_start
    for (r, _, v) in matches {
        val[k] = v
        indx[k] = r
        last = r + 1
        k += 1
    }
    row_end?.pointee = last
    return _sparseOK
}

@discardableResult
public func sparse_extract_sparse_column_double(
    _ A: sparse_matrix_double!, _ column: sparse_index, _ row_start: sparse_index,
    _ row_end: UnsafeMutablePointer<sparse_index>!, _ nz: sparse_dimension,
    _ val: UnsafeMutablePointer<Double>!, _ indx: UnsafeMutablePointer<sparse_index>!
) -> sparse_status {
    guard let host = _sparseFromOpaque(A), let val, let indx, host.scalar == .double else { return _sparseBad }
    let matches = host.doubles.filter { $0.1 == column && $0.0 >= row_start }.prefix(Int(nz))
    var k = 0
    var last = row_start
    for (r, _, v) in matches {
        val[k] = v
        indx[k] = r
        last = r + 1
        k += 1
    }
    row_end?.pointee = last
    return _sparseOK
}

@discardableResult
public func sparse_extract_sparse_column_float_complex(
    _ A: sparse_matrix_float_complex!, _ column: sparse_index, _ row_start: sparse_index,
    _ row_end: UnsafeMutablePointer<sparse_index>!, _ nz: sparse_dimension,
    _ val: OpaquePointer!, _ indx: UnsafeMutablePointer<sparse_index>!
) -> sparse_status {
    _ = A; _ = column; _ = row_start; _ = row_end; _ = nz; _ = val; _ = indx
    return _sparseBad
}

@discardableResult
public func sparse_extract_sparse_column_double_complex(
    _ A: sparse_matrix_double_complex!, _ column: sparse_index, _ row_start: sparse_index,
    _ row_end: UnsafeMutablePointer<sparse_index>!, _ nz: sparse_dimension,
    _ val: OpaquePointer!, _ indx: UnsafeMutablePointer<sparse_index>!
) -> sparse_status {
    _ = A; _ = column; _ = row_start; _ = row_end; _ = nz; _ = val; _ = indx
    return _sparseBad
}

@discardableResult
public func sparse_extract_block_float(
    _ A: sparse_matrix_float!, _ bi: sparse_index, _ bj: sparse_index,
    _ row_stride: sparse_dimension, _ col_stride: sparse_dimension, _ val: UnsafeMutablePointer<Float>!
) -> sparse_status {
    guard let host = _sparseFromOpaque(A), let val, host.scalar == .float else { return _sparseBad }
    let br = host.blockRow
    let bc = host.blockCol
    let rs = max(Int(row_stride), 1)
    _ = col_stride
    for r in 0..<br {
        for c in 0..<bc { val[r * rs + c] = 0 }
    }
    for (row, col, v) in host.floats {
        let r0 = bi * Int64(br)
        let c0 = bj * Int64(bc)
        if row >= r0, row < r0 + Int64(br), col >= c0, col < c0 + Int64(bc) {
            val[Int(row - r0) * rs + Int(col - c0)] = v
        }
    }
    return _sparseOK
}

@discardableResult
public func sparse_extract_block_double(
    _ A: sparse_matrix_double!, _ bi: sparse_index, _ bj: sparse_index,
    _ row_stride: sparse_dimension, _ col_stride: sparse_dimension, _ val: UnsafeMutablePointer<Double>!
) -> sparse_status {
    guard let host = _sparseFromOpaque(A), let val, host.scalar == .double else { return _sparseBad }
    let br = host.blockRow
    let bc = host.blockCol
    let rs = max(Int(row_stride), 1)
    _ = col_stride
    for r in 0..<br {
        for c in 0..<bc { val[r * rs + c] = 0 }
    }
    for (row, col, v) in host.doubles {
        let r0 = bi * Int64(br)
        let c0 = bj * Int64(bc)
        if row >= r0, row < r0 + Int64(br), col >= c0, col < c0 + Int64(bc) {
            val[Int(row - r0) * rs + Int(col - c0)] = v
        }
    }
    return _sparseOK
}

@discardableResult
public func sparse_extract_block_float_complex(
    _ A: sparse_matrix_float_complex!, _ bi: sparse_index, _ bj: sparse_index,
    _ row_stride: sparse_dimension, _ col_stride: sparse_dimension, _ val: OpaquePointer!
) -> sparse_status {
    _ = A; _ = bi; _ = bj; _ = row_stride; _ = col_stride; _ = val
    return _sparseBad
}

@discardableResult
public func sparse_extract_block_double_complex(
    _ A: sparse_matrix_double_complex!, _ bi: sparse_index, _ bj: sparse_index,
    _ row_stride: sparse_dimension, _ col_stride: sparse_dimension, _ val: OpaquePointer!
) -> sparse_status {
    _ = A; _ = bi; _ = bj; _ = row_stride; _ = col_stride; _ = val
    return _sparseBad
}

@discardableResult
public func sparse_permute_rows_float(_ A: sparse_matrix_float!, _ perm: UnsafePointer<sparse_index>!) -> sparse_status {
    guard let host = _sparseFromOpaque(A), let perm, host.scalar == .float else { return _sparseBad }
    host.floats = host.floats.map { (perm[Int($0.0)], $0.1, $0.2) }
    return _sparseOK
}

@discardableResult
public func sparse_permute_rows_double(_ A: sparse_matrix_double!, _ perm: UnsafePointer<sparse_index>!) -> sparse_status {
    guard let host = _sparseFromOpaque(A), let perm, host.scalar == .double else { return _sparseBad }
    host.doubles = host.doubles.map { (perm[Int($0.0)], $0.1, $0.2) }
    return _sparseOK
}

@discardableResult
public func sparse_permute_cols_float(_ A: sparse_matrix_float!, _ perm: UnsafePointer<sparse_index>!) -> sparse_status {
    guard let host = _sparseFromOpaque(A), let perm, host.scalar == .float else { return _sparseBad }
    host.floats = host.floats.map { ($0.0, perm[Int($0.1)], $0.2) }
    return _sparseOK
}

@discardableResult
public func sparse_permute_cols_double(_ A: sparse_matrix_double!, _ perm: UnsafePointer<sparse_index>!) -> sparse_status {
    guard let host = _sparseFromOpaque(A), let perm, host.scalar == .double else { return _sparseBad }
    host.doubles = host.doubles.map { ($0.0, perm[Int($0.1)], $0.2) }
    return _sparseOK
}

@discardableResult
public func sparse_permute_rows_float_complex(_ A: sparse_matrix_float_complex!, _ perm: UnsafePointer<sparse_index>!) -> sparse_status {
    _ = A; _ = perm
    return _sparseBad
}

@discardableResult
public func sparse_permute_rows_double_complex(_ A: sparse_matrix_double_complex!, _ perm: UnsafePointer<sparse_index>!) -> sparse_status {
    _ = A; _ = perm
    return _sparseBad
}

@discardableResult
public func sparse_permute_cols_float_complex(_ A: sparse_matrix_float_complex!, _ perm: UnsafePointer<sparse_index>!) -> sparse_status {
    _ = A; _ = perm
    return _sparseBad
}

@discardableResult
public func sparse_permute_cols_double_complex(_ A: sparse_matrix_double_complex!, _ perm: UnsafePointer<sparse_index>!) -> sparse_status {
    _ = A; _ = perm
    return _sparseBad
}

@discardableResult
public func sparse_outer_product_dense_float(
    _ M: sparse_dimension, _ N: sparse_dimension, _ nz: sparse_dimension, _ alpha: Float,
    _ x: UnsafePointer<Float>!, _ incx: sparse_stride, _ y: UnsafePointer<Float>!,
    _ indy: UnsafePointer<sparse_index>!, _ C: UnsafeMutablePointer<sparse_matrix_float?>!
) -> sparse_status {
    guard let x, let y, let indy, let C else { return _sparseBad }
    guard let matrix = sparse_matrix_create_float(M, N) else { return _sparseBad }
    let ix = max(Int(incx), 1)
    for k in 0..<Int(nz) {
        let j = indy[k]
        for i in 0..<Int(M) {
            _ = sparse_insert_entry_float(matrix, alpha * x[i * ix] * y[k], sparse_index(i), j)
        }
    }
    _ = sparse_commit(UnsafeMutableRawPointer(matrix))
    C.pointee = matrix
    return _sparseOK
}

@discardableResult
public func sparse_outer_product_dense_double(
    _ M: sparse_dimension, _ N: sparse_dimension, _ nz: sparse_dimension, _ alpha: Double,
    _ x: UnsafePointer<Double>!, _ incx: sparse_stride, _ y: UnsafePointer<Double>!,
    _ indy: UnsafePointer<sparse_index>!, _ C: UnsafeMutablePointer<sparse_matrix_double?>!
) -> sparse_status {
    guard let x, let y, let indy, let C else { return _sparseBad }
    guard let matrix = sparse_matrix_create_double(M, N) else { return _sparseBad }
    let ix = max(Int(incx), 1)
    for k in 0..<Int(nz) {
        let j = indy[k]
        for i in 0..<Int(M) {
            _ = sparse_insert_entry_double(matrix, alpha * x[i * ix] * y[k], sparse_index(i), j)
        }
    }
    _ = sparse_commit(UnsafeMutableRawPointer(matrix))
    C.pointee = matrix
    return _sparseOK
}

@discardableResult
public func sparse_matrix_triangular_solve_dense_float(
    _ order: CBLAS_ORDER, _ transt: CBLAS_TRANSPOSE, _ nrhs: sparse_dimension, _ alpha: Float,
    _ T: sparse_matrix_float!, _ B: UnsafeMutablePointer<Float>!, _ ldb: sparse_dimension
) -> sparse_status {
    guard let host = _sparseFromOpaque(T), let B, host.scalar == .float, host.rows == host.cols else { return _sparseBad }
    _ = order; _ = transt
    let n = host.rows
    let rhs = Int(nrhs)
    let ld = max(Int(ldb), n)
    var dense = [Float](repeating: 0, count: n * n)
    for (r, c, v) in host.floats { dense[Int(r) * n + Int(c)] = v }
    for k in 0..<rhs {
        var x = (0..<n).map { B[$0 + k * ld] * alpha }
        for i in 0..<n {
            var s = x[i]
            for j in 0..<i { s -= dense[i * n + j] * x[j] }
            let diag = dense[i * n + i]
            if diag == 0 { return _sparseBad }
            x[i] = s / diag
        }
        for i in 0..<n { B[i + k * ld] = x[i] }
    }
    return _sparseOK
}

@discardableResult
public func sparse_matrix_triangular_solve_dense_double(
    _ order: CBLAS_ORDER, _ transt: CBLAS_TRANSPOSE, _ nrhs: sparse_dimension, _ alpha: Double,
    _ T: sparse_matrix_double!, _ B: UnsafeMutablePointer<Double>!, _ ldb: sparse_dimension
) -> sparse_status {
    guard let host = _sparseFromOpaque(T), let B, host.scalar == .double, host.rows == host.cols else { return _sparseBad }
    _ = order; _ = transt
    let n = host.rows
    let rhs = Int(nrhs)
    let ld = max(Int(ldb), n)
    var dense = [Double](repeating: 0, count: n * n)
    for (r, c, v) in host.doubles { dense[Int(r) * n + Int(c)] = v }
    for k in 0..<rhs {
        var x = (0..<n).map { B[$0 + k * ld] * alpha }
        for i in 0..<n {
            var s = x[i]
            for j in 0..<i { s -= dense[i * n + j] * x[j] }
            let diag = dense[i * n + i]
            if diag == 0 { return _sparseBad }
            x[i] = s / diag
        }
        for i in 0..<n { B[i + k * ld] = x[i] }
    }
    return _sparseOK
}

@discardableResult
public func sparse_vector_triangular_solve_dense_float(
    _ transt: CBLAS_TRANSPOSE, _ alpha: Float, _ T: sparse_matrix_float!,
    _ x: UnsafeMutablePointer<Float>!, _ incx: sparse_stride
) -> sparse_status {
    guard let x else { return _sparseBad }
    let n = _sparseFromOpaque(T)?.rows ?? 0
    var dense = [Float](repeating: 0, count: max(n, 1))
    let ix = max(Int(incx), 1)
    for i in 0..<n { dense[i] = x[i * ix] }
    let status = sparse_matrix_triangular_solve_dense_float(CblasColMajor, transt, 1, alpha, T, &dense, sparse_dimension(n))
    for i in 0..<n { x[i * ix] = dense[i] }
    return status
}

@discardableResult
public func sparse_vector_triangular_solve_dense_double(
    _ transt: CBLAS_TRANSPOSE, _ alpha: Double, _ T: sparse_matrix_double!,
    _ x: UnsafeMutablePointer<Double>!, _ incx: sparse_stride
) -> sparse_status {
    guard let x else { return _sparseBad }
    let n = _sparseFromOpaque(T)?.rows ?? 0
    var dense = [Double](repeating: 0, count: max(n, 1))
    let ix = max(Int(incx), 1)
    for i in 0..<n { dense[i] = x[i * ix] }
    let status = sparse_matrix_triangular_solve_dense_double(CblasColMajor, transt, 1, alpha, T, &dense, sparse_dimension(n))
    for i in 0..<n { x[i * ix] = dense[i] }
    return status
}
