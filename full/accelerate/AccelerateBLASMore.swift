import Foundation

public func cblas_sdot(
    _ n: Int32,
    _ x: UnsafePointer<Float>!,
    _ incx: Int32,
    _ y: UnsafePointer<Float>!,
    _ incy: Int32
) -> Float {
    guard let x, let y else { return 0 }
    var nn = n
    var ix = incx
    var iy = incy
    var xx = Array(UnsafeBufferPointer(start: x, count: max(1, Int(n) * max(1, Int(abs(incx))))))
    var yy = Array(UnsafeBufferPointer(start: y, count: max(1, Int(n) * max(1, Int(abs(incy))))))
    return Float(sdot_(&nn, &xx, &ix, &yy, &iy))
}

public func cblas_sgemv(
    _ order: CBLAS_ORDER,
    _ trans: CBLAS_TRANSPOSE,
    _ m: Int32,
    _ n: Int32,
    _ alpha: Float,
    _ a: UnsafePointer<Float>!,
    _ lda: Int32,
    _ x: UnsafePointer<Float>!,
    _ incx: Int32,
    _ beta: Float,
    _ y: UnsafeMutablePointer<Float>!,
    _ incy: Int32
) {
    guard let a, let x, let y else { return }
    var t: CChar = trans.rawValue == CblasNoTrans.rawValue ? 78 : 84
    if order.rawValue == CblasRowMajor.rawValue {
        t = t == 78 ? 84 : 78
        var mm = n
        var nn = m
        var al = alpha
        var be = beta
        var ld = lda
        var ix = incx
        var iy = incy
        var aa = Array(UnsafeBufferPointer(start: a, count: max(1, Int(m) * Int(max(lda, n)))))
        var xx = Array(UnsafeBufferPointer(start: x, count: max(1, Int(max(m, n)) * max(1, Int(abs(incx))))))
        _ = sgemv_(&t, &mm, &nn, &al, &aa, &ld, &xx, &ix, &be, y, &iy)
        return
    }
    var mm = m
    var nn = n
    var al = alpha
    var be = beta
    var ld = lda
    var ix = incx
    var iy = incy
    var aa = Array(UnsafeBufferPointer(start: a, count: max(1, Int(lda) * Int(max(m, n)))))
    var xx = Array(UnsafeBufferPointer(start: x, count: max(1, Int(max(m, n)) * max(1, Int(abs(incx))))))
    _ = sgemv_(&t, &mm, &nn, &al, &aa, &ld, &xx, &ix, &be, y, &iy)
}

func _rot<T: BinaryFloatingPoint>(
    n: Int,
    x: UnsafeMutablePointer<T>,
    incx: Int,
    y: UnsafeMutablePointer<T>,
    incy: Int,
    c: T,
    s: T
) -> Int32 {
    guard n > 0, incx != 0, incy != 0 else { return 0 }
    var xi = 0
    var yi = 0
    for _ in 0..<n {
        let xv = x[xi]
        let yv = y[yi]
        x[xi] = c * xv + s * yv
        y[yi] = c * yv - s * xv
        xi += incx
        yi += incy
    }
    return 0
}

func _trsv<T: BinaryFloatingPoint>(
    uplo: CChar,
    trans: CChar,
    diag: CChar,
    n: Int,
    a: UnsafePointer<T>,
    lda: Int,
    x: UnsafeMutablePointer<T>,
    incx: Int
) -> Int32 {
    guard n > 0, lda >= n, incx != 0 else { return 0 }
    let upper = uplo == 85 || uplo == 117
    let unit = diag == 85 || diag == 117
    let doTrans = _isTrans(trans)
    func aAt(_ row: Int, _ col: Int) -> T { a[col * lda + row] }
    if !doTrans {
        if upper {
            var i = n - 1
            while i >= 0 {
                var sum = x[i * incx]
                if i + 1 < n {
                    for j in (i + 1)..<n { sum -= aAt(i, j) * x[j * incx] }
                }
                let diagV: T = unit ? 1 : aAt(i, i)
                if diagV == 0 { return Int32(i + 1) }
                x[i * incx] = sum / diagV
                i -= 1
            }
        } else {
            for i in 0..<n {
                var sum = x[i * incx]
                for j in 0..<i { sum -= aAt(i, j) * x[j * incx] }
                let diagV: T = unit ? 1 : aAt(i, i)
                if diagV == 0 { return Int32(i + 1) }
                x[i * incx] = sum / diagV
            }
        }
    } else {
        if upper {
            for i in 0..<n {
                var sum = x[i * incx]
                for j in 0..<i { sum -= aAt(j, i) * x[j * incx] }
                let diagV: T = unit ? 1 : aAt(i, i)
                if diagV == 0 { return Int32(i + 1) }
                x[i * incx] = sum / diagV
            }
        } else {
            var i = n - 1
            while i >= 0 {
                var sum = x[i * incx]
                if i + 1 < n {
                    for j in (i + 1)..<n { sum -= aAt(j, i) * x[j * incx] }
                }
                let diagV: T = unit ? 1 : aAt(i, i)
                if diagV == 0 { return Int32(i + 1) }
                x[i * incx] = sum / diagV
                i -= 1
            }
        }
    }
    return 0
}

func _symv<T: BinaryFloatingPoint>(
    uplo: CChar,
    n: Int,
    alpha: T,
    a: UnsafePointer<T>,
    lda: Int,
    x: UnsafePointer<T>,
    incx: Int,
    beta: T,
    y: UnsafeMutablePointer<T>,
    incy: Int
) -> Int32 {
    guard n > 0, lda >= n else { return 0 }
    let upper = uplo == 85 || uplo == 117
    for i in 0..<n {
        y[i * incy] = beta * y[i * incy]
    }
    func aij(_ i: Int, _ j: Int) -> T {
        if upper {
            return a[max(i, j) * lda + min(i, j)]
        }
        return a[min(i, j) * lda + max(i, j)]
    }
    for i in 0..<n {
        var sum: T = 0
        for j in 0..<n {
            sum += aij(i, j) * x[j * incx]
        }
        y[i * incy] += alpha * sum
    }
    return 0
}

func _rotg<T: BinaryFloatingPoint>(
    a: inout T,
    b: inout T,
    c: inout T,
    s: inout T
) -> Int32 {
    let absA = abs(a)
    let absB = abs(b)
    let scale = absA + absB
    if scale == 0 {
        c = 1
        s = 0
        a = 0
        b = 0
        return 0
    }
    let roe: T = absA > absB ? a : b
    let as_ = a / scale
    let bs = b / scale
    var r = scale * (as_ * as_ + bs * bs).squareRoot()
    if roe < 0 { r = -r }
    c = a / r
    s = b / r
    var z: T = 1
    if absA > absB {
        z = s
    } else if c != 0 {
        z = 1 / c
    }
    a = r
    b = z
    return 0
}

func _syr<T: BinaryFloatingPoint>(
    uplo: CChar,
    n: Int,
    alpha: T,
    x: UnsafePointer<T>,
    incx: Int,
    a: UnsafeMutablePointer<T>,
    lda: Int
) -> Int32 {
    guard n > 0, lda >= n, incx != 0 else { return 0 }
    let upper = uplo == 85 || uplo == 117
    for j in 0..<n {
        let xj = x[j * incx]
        if xj == 0 { continue }
        if upper {
            for i in 0...j {
                a[j * lda + i] += alpha * x[i * incx] * xj
            }
        } else {
            for i in j..<n {
                a[j * lda + i] += alpha * x[i * incx] * xj
            }
        }
    }
    return 0
}

func _trmv<T: BinaryFloatingPoint>(
    uplo: CChar,
    trans: CChar,
    diag: CChar,
    n: Int,
    a: UnsafePointer<T>,
    lda: Int,
    x: UnsafeMutablePointer<T>,
    incx: Int
) -> Int32 {
    guard n > 0, lda >= n, incx != 0 else { return 0 }
    let upper = uplo == 85 || uplo == 117
    let unit = diag == 85 || diag == 117
    let doTrans = _isTrans(trans)
    func aAt(_ row: Int, _ col: Int) -> T { a[col * lda + row] }
    var y = [T](repeating: 0, count: n)
    for i in 0..<n { y[i] = x[i * incx] }
    var out = [T](repeating: 0, count: n)
    for i in 0..<n {
        var sum: T = 0
        for j in 0..<n {
            let row = doTrans ? j : i
            let col = doTrans ? i : j
            let inTriangle = upper ? (row <= col) : (row >= col)
            if !inTriangle { continue }
            let aij: T = (row == col && unit) ? 1 : aAt(row, col)
            sum += aij * y[j]
        }
        out[i] = sum
    }
    for i in 0..<n { x[i * incx] = out[i] }
    return 0
}

func _syrk<T: BinaryFloatingPoint>(
    uplo: CChar,
    trans: CChar,
    n: Int,
    k: Int,
    alpha: T,
    a: UnsafePointer<T>,
    lda: Int,
    beta: T,
    c: UnsafeMutablePointer<T>,
    ldc: Int
) -> Int32 {
    guard n >= 0, k >= 0, ldc >= n else { return 0 }
    let upper = uplo == 85 || uplo == 117
    let doTrans = _isTrans(trans)
    for j in 0..<n {
        for i in 0..<n {
            if upper && i > j { continue }
            if !upper && i < j { continue }
            var sum: T = 0
            for p in 0..<k {
                let av: T = doTrans ? a[i * lda + p] : a[p * lda + i]
                let bv: T = doTrans ? a[j * lda + p] : a[p * lda + j]
                sum += av * bv
            }
            c[j * ldc + i] = alpha * sum + beta * c[j * ldc + i]
        }
    }
    return 0
}
