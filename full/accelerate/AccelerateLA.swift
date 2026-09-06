import Foundation

/// Linux LinearAlgebra (`la_*`) starting point. Objects store dense row-major
/// Float or Double values and evaluate eagerly. Status `0` is success
/// (`LA_SUCCESS`). Other `LA_*` macros remain sequential placeholders and are
/// not used as Apple enumerator values.

private let _laSuccess: la_status_t = 0
private let _laError: la_status_t = 1

private func _laBox(_ object: la_object_t) -> _OpenUIKitLAObject? {
    object as? _OpenUIKitLAObject
}

private func _laEmpty(_ status: la_status_t = _laError) -> _OpenUIKitLAObject {
    let obj = _OpenUIKitLAObject()
    obj.status = status
    return obj
}

private func _laIndex(_ row: Int, _ col: Int, cols: Int) -> Int {
    row * cols + col
}

private func _laMaterializeFloat(_ obj: _OpenUIKitLAObject, rows: Int, cols: Int) -> [Float]? {
    switch obj.kind {
    case .float:
        guard obj.rows == rows, obj.cols == cols, obj.floats.count == rows * cols else { return nil }
        return obj.floats
    case .splatFloat:
        return [Float](repeating: obj.splatF, count: rows * cols)
    case .double, .splatDouble, .empty:
        return nil
    }
}

private func _laMaterializeDouble(_ obj: _OpenUIKitLAObject, rows: Int, cols: Int) -> [Double]? {
    switch obj.kind {
    case .double:
        guard obj.rows == rows, obj.cols == cols, obj.doubles.count == rows * cols else { return nil }
        return obj.doubles
    case .splatDouble:
        return [Double](repeating: obj.splatD, count: rows * cols)
    case .float, .splatFloat, .empty:
        return nil
    }
}

private func _laFromFloat(_ values: [Float], rows: Int, cols: Int, attributes: la_attribute_t = 0) -> _OpenUIKitLAObject {
    let obj = _OpenUIKitLAObject()
    obj.kind = .float
    obj.rows = rows
    obj.cols = cols
    obj.floats = values
    obj.status = _laSuccess
    obj.attributes = attributes
    return obj
}

private func _laFromDouble(_ values: [Double], rows: Int, cols: Int, attributes: la_attribute_t = 0) -> _OpenUIKitLAObject {
    let obj = _OpenUIKitLAObject()
    obj.kind = .double
    obj.rows = rows
    obj.cols = cols
    obj.doubles = values
    obj.status = _laSuccess
    obj.attributes = attributes
    return obj
}

private func _laIsDoubleScalar(_ type: la_scalar_type_t) -> Bool {
    // Apple LA.h documents FLOAT=0, DOUBLE=1. Named LA_SCALAR_TYPE_* macros in
    // this tree remain sequential placeholders and are not used as discriminants.
    type == 1
}

private func _laNormKind(_ norm: la_norm_t) -> Int {
    // Apple LA.h documents L1=1, L2=2, LINF=3.
    if norm == 1 { return 1 }
    if norm == 3 { return 3 }
    return 2
}

public func la_add_attributes(_ object: la_object_t, _ attributes: la_attribute_t) {
    guard let box = _laBox(object) else { return }
    box.attributes |= attributes
}

public func la_remove_attributes(_ object: la_object_t, _ attributes: la_attribute_t) {
    guard let box = _laBox(object) else { return }
    box.attributes &= ~attributes
}

@discardableResult
public func la_retain(_ object: la_object_t) -> la_object_t {
    object
}

public func la_release(_ object: la_object_t) {
    _ = object
}

@discardableResult
public func la_status(_ object: la_object_t) -> la_status_t {
    _laBox(object)?.status ?? _laError
}

@discardableResult
public func la_matrix_rows(_ matrix: la_object_t) -> la_count_t {
    la_count_t(_laBox(matrix)?.rows ?? 0)
}

@discardableResult
public func la_matrix_cols(_ matrix: la_object_t) -> la_count_t {
    la_count_t(_laBox(matrix)?.cols ?? 0)
}

@discardableResult
public func la_vector_length(_ vector: la_object_t) -> la_count_t {
    guard let box = _laBox(vector) else { return 0 }
    if box.rows == 1 { return la_count_t(box.cols) }
    if box.cols == 1 { return la_count_t(box.rows) }
    return la_count_t(max(box.rows, box.cols))
}

@discardableResult
public func la_matrix_from_float_buffer(
    _ buffer: UnsafePointer<Float>,
    _ matrix_rows: la_count_t,
    _ matrix_cols: la_count_t,
    _ matrix_row_stride: la_count_t,
    _ matrix_hint: la_hint_t,
    _ attributes: la_attribute_t
) -> la_object_t {
    _ = matrix_hint
    let rows = Int(matrix_rows)
    let cols = Int(matrix_cols)
    let stride = max(Int(matrix_row_stride), cols)
    guard rows > 0, cols > 0 else { return _laEmpty() }
    var values = [Float](repeating: 0, count: rows * cols)
    for r in 0..<rows {
        for c in 0..<cols {
            values[_laIndex(r, c, cols: cols)] = buffer[r * stride + c]
        }
    }
    return _laFromFloat(values, rows: rows, cols: cols, attributes: attributes)
}

@discardableResult
public func la_matrix_from_float_buffer_nocopy(
    _ buffer: UnsafeMutablePointer<Float>,
    _ matrix_rows: la_count_t,
    _ matrix_cols: la_count_t,
    _ matrix_row_stride: la_count_t,
    _ matrix_hint: la_hint_t,
    _ deallocator: la_deallocator_t?,
    _ attributes: la_attribute_t
) -> la_object_t {
    _ = deallocator
    return la_matrix_from_float_buffer(buffer, matrix_rows, matrix_cols, matrix_row_stride, matrix_hint, attributes)
}

@discardableResult
public func la_matrix_from_double_buffer(
    _ buffer: UnsafePointer<Double>,
    _ matrix_rows: la_count_t,
    _ matrix_cols: la_count_t,
    _ matrix_row_stride: la_count_t,
    _ matrix_hint: la_hint_t,
    _ attributes: la_attribute_t
) -> la_object_t {
    _ = matrix_hint
    let rows = Int(matrix_rows)
    let cols = Int(matrix_cols)
    let stride = max(Int(matrix_row_stride), cols)
    guard rows > 0, cols > 0 else { return _laEmpty() }
    var values = [Double](repeating: 0, count: rows * cols)
    for r in 0..<rows {
        for c in 0..<cols {
            values[_laIndex(r, c, cols: cols)] = buffer[r * stride + c]
        }
    }
    return _laFromDouble(values, rows: rows, cols: cols, attributes: attributes)
}

@discardableResult
public func la_matrix_from_double_buffer_nocopy(
    _ buffer: UnsafeMutablePointer<Double>,
    _ matrix_rows: la_count_t,
    _ matrix_cols: la_count_t,
    _ matrix_row_stride: la_count_t,
    _ matrix_hint: la_hint_t,
    _ deallocator: la_deallocator_t?,
    _ attributes: la_attribute_t
) -> la_object_t {
    _ = deallocator
    return la_matrix_from_double_buffer(buffer, matrix_rows, matrix_cols, matrix_row_stride, matrix_hint, attributes)
}

@discardableResult
public func la_matrix_to_float_buffer(
    _ buffer: UnsafeMutablePointer<Float>,
    _ buffer_row_stride: la_count_t,
    _ matrix: la_object_t
) -> la_status_t {
    guard let box = _laBox(matrix), box.status == _laSuccess else { return _laError }
    let rows = box.rows
    let cols = box.cols
    let stride = max(Int(buffer_row_stride), cols)
    guard let values = _laMaterializeFloat(box, rows: rows, cols: cols) else { return _laError }
    for r in 0..<rows {
        for c in 0..<cols {
            buffer[r * stride + c] = values[_laIndex(r, c, cols: cols)]
        }
    }
    return _laSuccess
}

@discardableResult
public func la_matrix_to_double_buffer(
    _ buffer: UnsafeMutablePointer<Double>,
    _ buffer_row_stride: la_count_t,
    _ matrix: la_object_t
) -> la_status_t {
    guard let box = _laBox(matrix), box.status == _laSuccess else { return _laError }
    let rows = box.rows
    let cols = box.cols
    let stride = max(Int(buffer_row_stride), cols)
    guard let values = _laMaterializeDouble(box, rows: rows, cols: cols) else { return _laError }
    for r in 0..<rows {
        for c in 0..<cols {
            buffer[r * stride + c] = values[_laIndex(r, c, cols: cols)]
        }
    }
    return _laSuccess
}

@discardableResult
public func la_vector_to_float_buffer(
    _ buffer: UnsafeMutablePointer<Float>,
    _ buffer_stride: la_index_t,
    _ vector: la_object_t
) -> la_status_t {
    guard let box = _laBox(vector), box.status == _laSuccess else { return _laError }
    let n = Int(la_vector_length(vector))
    let stride = max(Int(buffer_stride), 1)
    guard let values = _laMaterializeFloat(box, rows: box.rows, cols: box.cols) else { return _laError }
    for i in 0..<n {
        buffer[i * stride] = values[i]
    }
    return _laSuccess
}

@discardableResult
public func la_vector_to_double_buffer(
    _ buffer: UnsafeMutablePointer<Double>,
    _ buffer_stride: la_index_t,
    _ vector: la_object_t
) -> la_status_t {
    guard let box = _laBox(vector), box.status == _laSuccess else { return _laError }
    let n = Int(la_vector_length(vector))
    let stride = max(Int(buffer_stride), 1)
    guard let values = _laMaterializeDouble(box, rows: box.rows, cols: box.cols) else { return _laError }
    for i in 0..<n {
        buffer[i * stride] = values[i]
    }
    return _laSuccess
}

@discardableResult
public func la_splat_from_float(_ scalar_value: Float, _ attributes: la_attribute_t) -> la_object_t {
    let obj = _OpenUIKitLAObject()
    obj.kind = .splatFloat
    obj.splatF = scalar_value
    obj.attributes = attributes
    obj.status = _laSuccess
    return obj
}

@discardableResult
public func la_splat_from_double(_ scalar_value: Double, _ attributes: la_attribute_t) -> la_object_t {
    let obj = _OpenUIKitLAObject()
    obj.kind = .splatDouble
    obj.splatD = scalar_value
    obj.attributes = attributes
    obj.status = _laSuccess
    return obj
}

@discardableResult
public func la_splat_from_matrix_element(
    _ matrix: la_object_t,
    _ matrix_row: la_index_t,
    _ matrix_col: la_index_t
) -> la_object_t {
    guard let box = _laBox(matrix) else { return _laEmpty() }
    let r = Int(matrix_row)
    let c = Int(matrix_col)
    guard r >= 0, c >= 0, r < box.rows, c < box.cols else { return _laEmpty() }
    switch box.kind {
    case .float:
        return la_splat_from_float(box.floats[_laIndex(r, c, cols: box.cols)], box.attributes)
    case .double:
        return la_splat_from_double(box.doubles[_laIndex(r, c, cols: box.cols)], box.attributes)
    case .splatFloat:
        return la_splat_from_float(box.splatF, box.attributes)
    case .splatDouble:
        return la_splat_from_double(box.splatD, box.attributes)
    case .empty:
        return _laEmpty()
    }
}

@discardableResult
public func la_splat_from_vector_element(_ vector: la_object_t, _ vector_index: la_index_t) -> la_object_t {
    guard let box = _laBox(vector) else { return _laEmpty() }
    let i = Int(vector_index)
    let n = Int(la_vector_length(vector))
    guard i >= 0, i < n else { return _laEmpty() }
    switch box.kind {
    case .float:
        return la_splat_from_float(box.floats[i], box.attributes)
    case .double:
        return la_splat_from_double(box.doubles[i], box.attributes)
    case .splatFloat:
        return la_splat_from_float(box.splatF, box.attributes)
    case .splatDouble:
        return la_splat_from_double(box.splatD, box.attributes)
    case .empty:
        return _laEmpty()
    }
}

@discardableResult
public func la_identity_matrix(
    _ matrix_size: la_count_t,
    _ scalar_type: la_scalar_type_t,
    _ attributes: la_attribute_t
) -> la_object_t {
    let n = Int(matrix_size)
    guard n > 0 else { return _laEmpty() }
    if _laIsDoubleScalar(scalar_type) {
        var values = [Double](repeating: 0, count: n * n)
        for i in 0..<n { values[_laIndex(i, i, cols: n)] = 1 }
        return _laFromDouble(values, rows: n, cols: n, attributes: attributes)
    }
    var values = [Float](repeating: 0, count: n * n)
    for i in 0..<n { values[_laIndex(i, i, cols: n)] = 1 }
    return _laFromFloat(values, rows: n, cols: n, attributes: attributes)
}

@discardableResult
public func la_matrix_from_splat(_ splat: la_object_t, _ matrix_rows: la_count_t, _ matrix_cols: la_count_t) -> la_object_t {
    guard let box = _laBox(splat) else { return _laEmpty() }
    let rows = Int(matrix_rows)
    let cols = Int(matrix_cols)
    guard rows > 0, cols > 0 else { return _laEmpty() }
    switch box.kind {
    case .splatFloat, .float:
        let v = box.kind == .splatFloat ? box.splatF : (box.floats.first ?? 0)
        return _laFromFloat([Float](repeating: v, count: rows * cols), rows: rows, cols: cols, attributes: box.attributes)
    case .splatDouble, .double:
        let v = box.kind == .splatDouble ? box.splatD : (box.doubles.first ?? 0)
        return _laFromDouble([Double](repeating: v, count: rows * cols), rows: rows, cols: cols, attributes: box.attributes)
    case .empty:
        return _laEmpty()
    }
}

@discardableResult
public func la_vector_from_splat(_ splat: la_object_t, _ vector_length: la_count_t) -> la_object_t {
    la_matrix_from_splat(splat, vector_length, 1)
}

@discardableResult
public func la_sum(_ obj_left: la_object_t, _ obj_right: la_object_t) -> la_object_t {
    _laZip(obj_left, obj_right, +)
}

@discardableResult
public func la_difference(_ obj_left: la_object_t, _ obj_right: la_object_t) -> la_object_t {
    _laZip(obj_left, obj_right, -)
}

@discardableResult
public func la_elementwise_product(_ obj_left: la_object_t, _ obj_right: la_object_t) -> la_object_t {
    _laZip(obj_left, obj_right, *)
}

private func _laZip(
    _ leftObj: la_object_t,
    _ rightObj: la_object_t,
    _ op: (Double, Double) -> Double
) -> la_object_t {
    guard let left = _laBox(leftObj), let right = _laBox(rightObj) else { return _laEmpty() }
    let rows = max(left.rows, right.rows)
    let cols = max(left.cols, right.cols)
    let useRows = rows == 0 ? 1 : rows
    let useCols = cols == 0 ? 1 : cols
    if left.kind == .double || left.kind == .splatDouble || right.kind == .double || right.kind == .splatDouble {
        guard let a = _laMaterializeDouble(left, rows: useRows, cols: useCols),
              let b = _laMaterializeDouble(right, rows: useRows, cols: useCols) else { return _laEmpty() }
        var out = [Double](repeating: 0, count: a.count)
        for i in 0..<a.count { out[i] = op(a[i], b[i]) }
        return _laFromDouble(out, rows: useRows, cols: useCols, attributes: left.attributes)
    }
    guard let a = _laMaterializeFloat(left, rows: useRows, cols: useCols),
          let b = _laMaterializeFloat(right, rows: useRows, cols: useCols) else { return _laEmpty() }
    var out = [Float](repeating: 0, count: a.count)
    for i in 0..<a.count { out[i] = Float(op(Double(a[i]), Double(b[i]))) }
    return _laFromFloat(out, rows: useRows, cols: useCols, attributes: left.attributes)
}

@discardableResult
public func la_scale_with_float(_ matrix: la_object_t, _ scalar: Float) -> la_object_t {
    guard let box = _laBox(matrix) else { return _laEmpty() }
    switch box.kind {
    case .float:
        return _laFromFloat(box.floats.map { $0 * scalar }, rows: box.rows, cols: box.cols, attributes: box.attributes)
    case .splatFloat:
        return la_splat_from_float(box.splatF * scalar, box.attributes)
    case .double:
        return _laFromDouble(box.doubles.map { $0 * Double(scalar) }, rows: box.rows, cols: box.cols, attributes: box.attributes)
    case .splatDouble:
        return la_splat_from_double(box.splatD * Double(scalar), box.attributes)
    case .empty:
        return _laEmpty()
    }
}

@discardableResult
public func la_scale_with_double(_ matrix: la_object_t, _ scalar: Double) -> la_object_t {
    guard let box = _laBox(matrix) else { return _laEmpty() }
    switch box.kind {
    case .double:
        return _laFromDouble(box.doubles.map { $0 * scalar }, rows: box.rows, cols: box.cols, attributes: box.attributes)
    case .splatDouble:
        return la_splat_from_double(box.splatD * scalar, box.attributes)
    case .float:
        return _laFromFloat(box.floats.map { $0 * Float(scalar) }, rows: box.rows, cols: box.cols, attributes: box.attributes)
    case .splatFloat:
        return la_splat_from_float(box.splatF * Float(scalar), box.attributes)
    case .empty:
        return _laEmpty()
    }
}

@discardableResult
public func la_transpose(_ matrix: la_object_t) -> la_object_t {
    guard let box = _laBox(matrix), box.rows > 0, box.cols > 0 else { return _laEmpty() }
    if box.kind == .double {
        var out = [Double](repeating: 0, count: box.rows * box.cols)
        for r in 0..<box.rows {
            for c in 0..<box.cols {
                out[_laIndex(c, r, cols: box.rows)] = box.doubles[_laIndex(r, c, cols: box.cols)]
            }
        }
        return _laFromDouble(out, rows: box.cols, cols: box.rows, attributes: box.attributes)
    }
    var out = [Float](repeating: 0, count: box.rows * box.cols)
    for r in 0..<box.rows {
        for c in 0..<box.cols {
            out[_laIndex(c, r, cols: box.rows)] = box.floats[_laIndex(r, c, cols: box.cols)]
        }
    }
    return _laFromFloat(out, rows: box.cols, cols: box.rows, attributes: box.attributes)
}

@discardableResult
public func la_matrix_product(_ matrix_left: la_object_t, _ matrix_right: la_object_t) -> la_object_t {
    guard let a = _laBox(matrix_left), let b = _laBox(matrix_right) else { return _laEmpty() }
    guard a.cols == b.rows, a.rows > 0, b.cols > 0 else { return _laEmpty() }
    if a.kind == .double || b.kind == .double {
        guard let av = _laMaterializeDouble(a, rows: a.rows, cols: a.cols),
              let bv = _laMaterializeDouble(b, rows: b.rows, cols: b.cols) else { return _laEmpty() }
        var out = [Double](repeating: 0, count: a.rows * b.cols)
        for i in 0..<a.rows {
            for j in 0..<b.cols {
                var s: Double = 0
                for k in 0..<a.cols {
                    s += av[_laIndex(i, k, cols: a.cols)] * bv[_laIndex(k, j, cols: b.cols)]
                }
                out[_laIndex(i, j, cols: b.cols)] = s
            }
        }
        return _laFromDouble(out, rows: a.rows, cols: b.cols, attributes: a.attributes)
    }
    guard let av = _laMaterializeFloat(a, rows: a.rows, cols: a.cols),
          let bv = _laMaterializeFloat(b, rows: b.rows, cols: b.cols) else { return _laEmpty() }
    var out = [Float](repeating: 0, count: a.rows * b.cols)
    for i in 0..<a.rows {
        for j in 0..<b.cols {
            var s: Float = 0
            for k in 0..<a.cols {
                s += av[_laIndex(i, k, cols: a.cols)] * bv[_laIndex(k, j, cols: b.cols)]
            }
            out[_laIndex(i, j, cols: b.cols)] = s
        }
    }
    return _laFromFloat(out, rows: a.rows, cols: b.cols, attributes: a.attributes)
}

@discardableResult
public func la_inner_product(_ vector_left: la_object_t, _ vector_right: la_object_t) -> la_object_t {
    guard let a = _laBox(vector_left), let b = _laBox(vector_right) else { return _laEmpty() }
    let n = Int(la_vector_length(vector_left))
    guard n == Int(la_vector_length(vector_right)), n > 0 else { return _laEmpty() }
    if a.kind == .double || b.kind == .double {
        guard let av = _laMaterializeDouble(a, rows: a.rows, cols: a.cols),
              let bv = _laMaterializeDouble(b, rows: b.rows, cols: b.cols) else { return _laEmpty() }
        var s: Double = 0
        for i in 0..<n { s += av[i] * bv[i] }
        return _laFromDouble([s], rows: 1, cols: 1, attributes: a.attributes)
    }
    guard let av = _laMaterializeFloat(a, rows: a.rows, cols: a.cols),
          let bv = _laMaterializeFloat(b, rows: b.rows, cols: b.cols) else { return _laEmpty() }
    var s: Float = 0
    for i in 0..<n { s += av[i] * bv[i] }
    return _laFromFloat([s], rows: 1, cols: 1, attributes: a.attributes)
}

@discardableResult
public func la_outer_product(_ vector_left: la_object_t, _ vector_right: la_object_t) -> la_object_t {
    guard let a = _laBox(vector_left), let b = _laBox(vector_right) else { return _laEmpty() }
    let m = Int(la_vector_length(vector_left))
    let n = Int(la_vector_length(vector_right))
    guard m > 0, n > 0 else { return _laEmpty() }
    if a.kind == .double || b.kind == .double {
        guard let av = _laMaterializeDouble(a, rows: a.rows, cols: a.cols),
              let bv = _laMaterializeDouble(b, rows: b.rows, cols: b.cols) else { return _laEmpty() }
        var out = [Double](repeating: 0, count: m * n)
        for i in 0..<m {
            for j in 0..<n {
                out[_laIndex(i, j, cols: n)] = av[i] * bv[j]
            }
        }
        return _laFromDouble(out, rows: m, cols: n, attributes: a.attributes)
    }
    guard let av = _laMaterializeFloat(a, rows: a.rows, cols: a.cols),
          let bv = _laMaterializeFloat(b, rows: b.rows, cols: b.cols) else { return _laEmpty() }
    var out = [Float](repeating: 0, count: m * n)
    for i in 0..<m {
        for j in 0..<n {
            out[_laIndex(i, j, cols: n)] = av[i] * bv[j]
        }
    }
    return _laFromFloat(out, rows: m, cols: n, attributes: a.attributes)
}

@discardableResult
public func la_vector_from_matrix_row(_ matrix: la_object_t, _ matrix_row: la_count_t) -> la_object_t {
    guard let box = _laBox(matrix) else { return _laEmpty() }
    let r = Int(matrix_row)
    guard r >= 0, r < box.rows else { return _laEmpty() }
    if box.kind == .double {
        let slice = Array(box.doubles[r * box.cols ..< (r + 1) * box.cols])
        return _laFromDouble(slice, rows: 1, cols: box.cols, attributes: box.attributes)
    }
    let slice = Array(box.floats[r * box.cols ..< (r + 1) * box.cols])
    return _laFromFloat(slice, rows: 1, cols: box.cols, attributes: box.attributes)
}

@discardableResult
public func la_vector_from_matrix_col(_ matrix: la_object_t, _ matrix_col: la_count_t) -> la_object_t {
    guard let box = _laBox(matrix) else { return _laEmpty() }
    let c = Int(matrix_col)
    guard c >= 0, c < box.cols else { return _laEmpty() }
    if box.kind == .double {
        var out = [Double](repeating: 0, count: box.rows)
        for r in 0..<box.rows { out[r] = box.doubles[_laIndex(r, c, cols: box.cols)] }
        return _laFromDouble(out, rows: box.rows, cols: 1, attributes: box.attributes)
    }
    var out = [Float](repeating: 0, count: box.rows)
    for r in 0..<box.rows { out[r] = box.floats[_laIndex(r, c, cols: box.cols)] }
    return _laFromFloat(out, rows: box.rows, cols: 1, attributes: box.attributes)
}

@discardableResult
public func la_vector_from_matrix_diagonal(_ matrix: la_object_t, _ matrix_diagonal: la_index_t) -> la_object_t {
    guard let box = _laBox(matrix) else { return _laEmpty() }
    let offset = Int(matrix_diagonal)
    var floats: [Float] = []
    var doubles: [Double] = []
    if offset >= 0 {
        let n = min(box.rows, box.cols - offset)
        guard n > 0 else { return _laEmpty() }
        for i in 0..<n {
            if box.kind == .double {
                doubles.append(box.doubles[_laIndex(i, i + offset, cols: box.cols)])
            } else {
                floats.append(box.floats[_laIndex(i, i + offset, cols: box.cols)])
            }
        }
        if box.kind == .double {
            return _laFromDouble(doubles, rows: n, cols: 1, attributes: box.attributes)
        }
        return _laFromFloat(floats, rows: n, cols: 1, attributes: box.attributes)
    }
    let n = min(box.cols, box.rows + offset)
    guard n > 0 else { return _laEmpty() }
    for i in 0..<n {
        if box.kind == .double {
            doubles.append(box.doubles[_laIndex(i - offset, i, cols: box.cols)])
        } else {
            floats.append(box.floats[_laIndex(i - offset, i, cols: box.cols)])
        }
    }
    if box.kind == .double {
        return _laFromDouble(doubles, rows: n, cols: 1, attributes: box.attributes)
    }
    return _laFromFloat(floats, rows: n, cols: 1, attributes: box.attributes)
}

@discardableResult
public func la_diagonal_matrix_from_vector(_ vector: la_object_t, _ matrix_diagonal: la_index_t) -> la_object_t {
    guard let box = _laBox(vector) else { return _laEmpty() }
    let n = Int(la_vector_length(vector))
    let offset = Int(matrix_diagonal)
    let dim = n + abs(offset)
    guard dim > 0 else { return _laEmpty() }
    if box.kind == .double {
        var out = [Double](repeating: 0, count: dim * dim)
        for i in 0..<n {
            let r = offset >= 0 ? i : i - offset
            let c = offset >= 0 ? i + offset : i
            if r >= 0, c >= 0, r < dim, c < dim {
                out[_laIndex(r, c, cols: dim)] = box.doubles[i]
            }
        }
        return _laFromDouble(out, rows: dim, cols: dim, attributes: box.attributes)
    }
    var out = [Float](repeating: 0, count: dim * dim)
    for i in 0..<n {
        let r = offset >= 0 ? i : i - offset
        let c = offset >= 0 ? i + offset : i
        if r >= 0, c >= 0, r < dim, c < dim {
            out[_laIndex(r, c, cols: dim)] = box.floats[i]
        }
    }
    return _laFromFloat(out, rows: dim, cols: dim, attributes: box.attributes)
}

@discardableResult
public func la_matrix_slice(
    _ matrix: la_object_t,
    _ matrix_first_row: la_index_t,
    _ matrix_first_col: la_index_t,
    _ matrix_row_stride: la_index_t,
    _ matrix_col_stride: la_index_t,
    _ slice_rows: la_count_t,
    _ slice_cols: la_count_t
) -> la_object_t {
    guard let box = _laBox(matrix) else { return _laEmpty() }
    let rows = Int(slice_rows)
    let cols = Int(slice_cols)
    let rs = Int(matrix_row_stride) == 0 ? 1 : Int(matrix_row_stride)
    let cs = Int(matrix_col_stride) == 0 ? 1 : Int(matrix_col_stride)
    guard rows > 0, cols > 0 else { return _laEmpty() }
    var floats: [Float] = []
    var doubles: [Double] = []
    for i in 0..<rows {
        for j in 0..<cols {
            let r = Int(matrix_first_row) + i * rs
            let c = Int(matrix_first_col) + j * cs
            guard r >= 0, c >= 0, r < box.rows, c < box.cols else { return _laEmpty() }
            if box.kind == .double {
                doubles.append(box.doubles[_laIndex(r, c, cols: box.cols)])
            } else {
                floats.append(box.floats[_laIndex(r, c, cols: box.cols)])
            }
        }
    }
    if box.kind == .double {
        return _laFromDouble(doubles, rows: rows, cols: cols, attributes: box.attributes)
    }
    return _laFromFloat(floats, rows: rows, cols: cols, attributes: box.attributes)
}

@discardableResult
public func la_vector_slice(
    _ vector: la_object_t,
    _ vector_first: la_index_t,
    _ vector_stride: la_index_t,
    _ slice_length: la_count_t
) -> la_object_t {
    guard let box = _laBox(vector) else { return _laEmpty() }
    let n = Int(slice_length)
    let stride = Int(vector_stride) == 0 ? 1 : Int(vector_stride)
    let total = Int(la_vector_length(vector))
    guard n > 0 else { return _laEmpty() }
    var floats: [Float] = []
    var doubles: [Double] = []
    for i in 0..<n {
        let idx = Int(vector_first) + i * stride
        guard idx >= 0, idx < total else { return _laEmpty() }
        if box.kind == .double {
            doubles.append(box.doubles[idx])
        } else {
            floats.append(box.floats[idx])
        }
    }
    if box.kind == .double {
        return _laFromDouble(doubles, rows: n, cols: 1, attributes: box.attributes)
    }
    return _laFromFloat(floats, rows: n, cols: 1, attributes: box.attributes)
}

@discardableResult
public func la_norm_as_float(_ vector: la_object_t, _ vector_norm: la_norm_t) -> Float {
    Float(la_norm_as_double(vector, vector_norm))
}

@discardableResult
public func la_norm_as_double(_ vector: la_object_t, _ vector_norm: la_norm_t) -> Double {
    guard let box = _laBox(vector) else { return 0 }
    let n = Int(la_vector_length(vector))
    guard n > 0 else { return 0 }
    let kind = _laNormKind(vector_norm)
    let values: [Double]
    if box.kind == .double {
        values = Array(box.doubles.prefix(n))
    } else {
        values = box.floats.prefix(n).map { Double($0) }
    }
    switch kind {
    case 1:
        return values.reduce(0) { $0 + abs($1) }
    case 3:
        return values.map { abs($0) }.max() ?? 0
    default:
        return (values.reduce(0) { $0 + $1 * $1 }).squareRoot()
    }
}

@discardableResult
public func la_normalized_vector(_ vector: la_object_t, _ vector_norm: la_norm_t) -> la_object_t {
    let nrm = la_norm_as_double(vector, vector_norm)
    guard nrm > 0 else { return _laEmpty() }
    return la_scale_with_double(vector, 1 / nrm)
}

@discardableResult
public func la_solve(_ matrix_system: la_object_t, _ obj_rhs: la_object_t) -> la_object_t {
    guard let a = _laBox(matrix_system), let b = _laBox(obj_rhs) else { return _laEmpty() }
    guard a.rows == a.cols, a.rows > 0, b.rows == a.rows else { return _laEmpty() }
    let n = a.rows
    let nrhs = b.cols
    if a.kind == .double || b.kind == .double {
        guard var av = _laMaterializeDouble(a, rows: n, cols: n),
              var bv = _laMaterializeDouble(b, rows: n, cols: nrhs) else { return _laEmpty() }
        let rc = _laGesvRowMajor(n: n, nrhs: nrhs, a: &av, b: &bv)
        if rc != 0 { return _laEmpty() }
        return _laFromDouble(bv, rows: n, cols: nrhs, attributes: a.attributes)
    }
    guard var av = _laMaterializeFloat(a, rows: n, cols: n),
          var bv = _laMaterializeFloat(b, rows: n, cols: nrhs) else { return _laEmpty() }
    let rc = _laGesvRowMajor(n: n, nrhs: nrhs, a: &av, b: &bv)
    if rc != 0 { return _laEmpty() }
    return _laFromFloat(bv, rows: n, cols: nrhs, attributes: a.attributes)
}

private func _laGesvRowMajor<T: BinaryFloatingPoint>(n: Int, nrhs: Int, a: inout [T], b: inout [T]) -> Int {
    for k in 0..<n {
        var pivot = k
        var best = abs(a[k * n + k])
        for r in (k + 1)..<n {
            let v = abs(a[r * n + k])
            if v > best {
                best = v
                pivot = r
            }
        }
        if best == 0 { return 1 }
        if pivot != k {
            for c in 0..<n {
                a.swapAt(k * n + c, pivot * n + c)
            }
            for c in 0..<nrhs {
                b.swapAt(k * nrhs + c, pivot * nrhs + c)
            }
        }
        let diag = a[k * n + k]
        for r in (k + 1)..<n {
            let factor = a[r * n + k] / diag
            a[r * n + k] = 0
            for c in (k + 1)..<n {
                a[r * n + c] -= factor * a[k * n + c]
            }
            for c in 0..<nrhs {
                b[r * nrhs + c] -= factor * b[k * nrhs + c]
            }
        }
    }
    for k in stride(from: n - 1, through: 0, by: -1) {
        let diag = a[k * n + k]
        if diag == 0 { return 1 }
        for c in 0..<nrhs {
            var s = b[k * nrhs + c]
            for j in (k + 1)..<n {
                s -= a[k * n + j] * b[j * nrhs + c]
            }
            b[k * nrhs + c] = s / diag
        }
    }
    return 0
}
