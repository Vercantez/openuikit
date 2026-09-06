import Foundation

/// Linux fail-closed status for BNNS entry points that need a BNNS runtime.
public let BNNSLinuxFailClosedStatus: Int32 = -1

func _bnnsNDArrayCount(_ desc: BNNSNDArrayDescriptor) -> Int {
    let sizes = [
        desc.size.0, desc.size.1, desc.size.2, desc.size.3,
        desc.size.4, desc.size.5, desc.size.6, desc.size.7
    ]
    var count = 1
    var saw = false
    for s in sizes where s > 0 {
        count *= s
        saw = true
    }
    return saw ? count : 0
}

func _bnnsFloatBuffer(_ desc: BNNSNDArrayDescriptor) -> UnsafeMutablePointer<Float>? {
    guard let data = desc.data else { return nil }
    return data.assumingMemoryBound(to: Float.self)
}

func _bnnsCopyFloat(
    dest: inout BNNSNDArrayDescriptor,
    src: BNNSNDArrayDescriptor
) -> Int32 {
    let n = _bnnsNDArrayCount(src)
    guard n > 0, n == _bnnsNDArrayCount(dest) else { return BNNSLinuxFailClosedStatus }
    guard let s = _bnnsFloatBuffer(src), let d = _bnnsFloatBuffer(dest) else {
        return BNNSLinuxFailClosedStatus
    }
    d.update(from: s, count: n)
    return 0
}

func _bnnsClipByValueFloat(
    dest: inout BNNSNDArrayDescriptor,
    src: BNNSNDArrayDescriptor,
    minVal: Float,
    maxVal: Float
) -> Int32 {
    let n = _bnnsNDArrayCount(src)
    guard n > 0, n == _bnnsNDArrayCount(dest) else { return BNNSLinuxFailClosedStatus }
    guard let s = _bnnsFloatBuffer(src), let d = _bnnsFloatBuffer(dest) else {
        return BNNSLinuxFailClosedStatus
    }
    let lo = min(minVal, maxVal)
    let hi = max(minVal, maxVal)
    for i in 0..<n {
        d[i] = min(hi, max(lo, s[i]))
    }
    return 0
}

func _bnnsCompareFloat(
    in0: BNNSNDArrayDescriptor,
    in1: BNNSNDArrayDescriptor,
    op: BNNSRelationalOperator,
    out: inout BNNSNDArrayDescriptor
) -> Int32 {
    let n = _bnnsNDArrayCount(in0)
    guard n > 0, n == _bnnsNDArrayCount(in1), n == _bnnsNDArrayCount(out) else {
        return BNNSLinuxFailClosedStatus
    }
    guard let a = _bnnsFloatBuffer(in0), let b = _bnnsFloatBuffer(in1), let o = _bnnsFloatBuffer(out) else {
        return BNNSLinuxFailClosedStatus
    }
    for i in 0..<n {
        let lhs = a[i]
        let rhs = b[i]
        let ok: Bool
        switch op.rawValue {
        case BNNSRelationalOperatorEqual.rawValue: ok = lhs == rhs
        case BNNSRelationalOperatorNotEqual.rawValue: ok = lhs != rhs
        case BNNSRelationalOperatorGreater.rawValue: ok = lhs > rhs
        case BNNSRelationalOperatorGreaterEqual.rawValue: ok = lhs >= rhs
        case BNNSRelationalOperatorLess.rawValue: ok = lhs < rhs
        case BNNSRelationalOperatorLessEqual.rawValue: ok = lhs <= rhs
        default: return BNNSLinuxFailClosedStatus
        }
        o[i] = ok ? 1 : 0
    }
    return 0
}

func _bnnsMatMulFloat(
    transA: Bool,
    transB: Bool,
    alpha: Float,
    inputA: BNNSNDArrayDescriptor,
    inputB: BNNSNDArrayDescriptor,
    output: BNNSNDArrayDescriptor
) -> Int32 {
    let aRows = inputA.size.0
    let aCols = inputA.size.1
    let bRows = inputB.size.0
    let bCols = inputB.size.1
    let m = transA ? aCols : aRows
    let k = transA ? aRows : aCols
    let k2 = transB ? bCols : bRows
    let n = transB ? bRows : bCols
    if m <= 0 || n <= 0 || k <= 0 || k != k2 { return BNNSLinuxFailClosedStatus }
    if output.size.0 != m || output.size.1 != n { return BNNSLinuxFailClosedStatus }
    guard let a = _bnnsFloatBuffer(inputA),
          let b = _bnnsFloatBuffer(inputB),
          let c = _bnnsFloatBuffer(output) else {
        return BNNSLinuxFailClosedStatus
    }
    func at(_ p: UnsafePointer<Float>, _ row: Int, _ col: Int, _ cols: Int) -> Float {
        p[row * cols + col]
    }
    let aPackedCols = aCols
    let bPackedCols = bCols
    for i in 0..<m {
        for j in 0..<n {
            var acc: Float = 0
            for p in 0..<k {
                let av = transA ? at(a, p, i, aPackedCols) : at(a, i, p, aPackedCols)
                let bv = transB ? at(b, j, p, bPackedCols) : at(b, p, j, bPackedCols)
                acc += av * bv
            }
            c[i * n + j] = alpha * acc
        }
    }
    return 0
}

func _bnnsTransposeFloat(
    dest: inout BNNSNDArrayDescriptor,
    src: BNNSNDArrayDescriptor,
    axis0: Int,
    axis1: Int
) -> Int32 {
    let rows = src.size.0
    let cols = src.size.1
    guard rows > 0, cols > 0 else { return BNNSLinuxFailClosedStatus }
    guard (axis0 == 0 && axis1 == 1) || (axis0 == 1 && axis1 == 0) else {
        return BNNSLinuxFailClosedStatus
    }
    guard dest.size.0 == cols, dest.size.1 == rows else { return BNNSLinuxFailClosedStatus }
    guard let s = _bnnsFloatBuffer(src), let d = _bnnsFloatBuffer(dest) else {
        return BNNSLinuxFailClosedStatus
    }
    for i in 0..<rows {
        for j in 0..<cols {
            d[j * rows + i] = s[i * cols + j]
        }
    }
    return 0
}

func _bnnsTileFloat(
    dest: inout BNNSNDArrayDescriptor,
    src: BNNSNDArrayDescriptor
) -> Int32 {
    let srcN = _bnnsNDArrayCount(src)
    let dstN = _bnnsNDArrayCount(dest)
    guard srcN > 0, dstN > 0, dstN % srcN == 0 else { return BNNSLinuxFailClosedStatus }
    guard let s = _bnnsFloatBuffer(src), let d = _bnnsFloatBuffer(dest) else {
        return BNNSLinuxFailClosedStatus
    }
    let srcRows = max(src.size.0, 1)
    let srcCols = max(src.size.1, 1)
    let dstRows = max(dest.size.0, 1)
    let dstCols = max(dest.size.1, 1)
    if src.size.1 > 0, dest.size.1 > 0, dstRows % srcRows == 0, dstCols % srcCols == 0 {
        for i in 0..<dstRows {
            for j in 0..<dstCols {
                d[i * dstCols + j] = s[(i % srcRows) * srcCols + (j % srcCols)]
            }
        }
        return 0
    }
    for i in 0..<dstN {
        d[i] = s[i % srcN]
    }
    return 0
}
