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

func _symElem<T: BinaryFloatingPoint>(
    _ a: UnsafePointer<T>,
    i: Int,
    j: Int,
    lda: Int,
    upper: Bool
) -> T {
    if upper { return a[max(i, j) * lda + min(i, j)] }
    return a[min(i, j) * lda + max(i, j)]
}

func _triRealA<T: BinaryFloatingPoint>(
    _ a: UnsafePointer<T>,
    row: Int,
    col: Int,
    lda: Int,
    upper: Bool,
    unit: Bool,
    doTrans: Bool
) -> T {
    let r = doTrans ? col : row
    let c = doTrans ? row : col
    if r == c && unit { return 1 }
    let inTriangle = upper ? (r <= c) : (r >= c)
    if !inTriangle { return 0 }
    return a[c * lda + r]
}

func _symm<T: BinaryFloatingPoint>(
    side: CChar,
    uplo: CChar,
    m: Int,
    n: Int,
    alpha: T,
    a: UnsafePointer<T>,
    lda: Int,
    b: UnsafePointer<T>,
    ldb: Int,
    beta: T,
    c: UnsafeMutablePointer<T>,
    ldc: Int
) -> Int32 {
    guard m > 0, n > 0, lda > 0, ldb >= m, ldc >= m else { return 0 }
    let left = _isLeft(side)
    let upper = _isUpper(uplo)
    let aDim = left ? m : n
    guard lda >= aDim else { return 0 }
    for j in 0..<n {
        for i in 0..<m {
            var sum: T = 0
            if left {
                for p in 0..<m {
                    sum += _symElem(a, i: i, j: p, lda: lda, upper: upper) * b[j * ldb + p]
                }
            } else {
                for p in 0..<n {
                    sum += b[p * ldb + i] * _symElem(a, i: p, j: j, lda: lda, upper: upper)
                }
            }
            let idx = j * ldc + i
            c[idx] = alpha * sum + beta * c[idx]
        }
    }
    return 0
}

func _syr2<T: BinaryFloatingPoint>(
    uplo: CChar,
    n: Int,
    alpha: T,
    x: UnsafePointer<T>,
    incx: Int,
    y: UnsafePointer<T>,
    incy: Int,
    a: UnsafeMutablePointer<T>,
    lda: Int
) -> Int32 {
    guard n > 0, lda >= n, incx != 0, incy != 0 else { return 0 }
    let upper = _isUpper(uplo)
    for j in 0..<n {
        let xj = x[j * incx]
        let yj = y[j * incy]
        let iStart = upper ? 0 : j
        let iEnd = upper ? j : n - 1
        var i = iStart
        while i <= iEnd {
            a[j * lda + i] += alpha * (x[i * incx] * yj + y[i * incy] * xj)
            i += 1
        }
    }
    return 0
}

func _syr2k<T: BinaryFloatingPoint>(
    uplo: CChar,
    trans: CChar,
    n: Int,
    k: Int,
    alpha: T,
    a: UnsafePointer<T>,
    lda: Int,
    b: UnsafePointer<T>,
    ldb: Int,
    beta: T,
    c: UnsafeMutablePointer<T>,
    ldc: Int
) -> Int32 {
    guard n > 0, k >= 0, ldc >= n, lda > 0, ldb > 0 else { return 0 }
    let upper = _isUpper(uplo)
    let doTrans = _isTrans(trans)
    for j in 0..<n {
        for i in 0..<n {
            if upper && i > j { continue }
            if !upper && i < j { continue }
            var sum: T = 0
            for p in 0..<k {
                let ai: T = doTrans ? a[i * lda + p] : a[p * lda + i]
                let bi: T = doTrans ? b[i * ldb + p] : b[p * ldb + i]
                let aj: T = doTrans ? a[j * lda + p] : a[p * lda + j]
                let bj: T = doTrans ? b[j * ldb + p] : b[p * ldb + j]
                sum += ai * bj + bi * aj
            }
            let idx = j * ldc + i
            c[idx] = alpha * sum + beta * c[idx]
        }
    }
    return 0
}

func _trmm<T: BinaryFloatingPoint>(
    side: CChar,
    uplo: CChar,
    transa: CChar,
    diag: CChar,
    m: Int,
    n: Int,
    alpha: T,
    a: UnsafePointer<T>,
    lda: Int,
    b: UnsafeMutablePointer<T>,
    ldb: Int
) -> Int32 {
    guard m > 0, n > 0, lda > 0, ldb >= m else { return 0 }
    let left = _isLeft(side)
    let upper = _isUpper(uplo)
    let unit = _isUnitDiag(diag)
    let doTrans = _isTrans(transa)
    let aDim = left ? m : n
    guard lda >= aDim else { return 0 }
    if alpha == 0 {
        for j in 0..<n {
            for i in 0..<m { b[j * ldb + i] = 0 }
        }
        return 0
    }
    var tmp = [T](repeating: 0, count: m * n)
    for j in 0..<n {
        for i in 0..<m {
            var sum: T = 0
            if left {
                for p in 0..<m {
                    sum += _triRealA(a, row: i, col: p, lda: lda, upper: upper, unit: unit, doTrans: doTrans) * b[j * ldb + p]
                }
            } else {
                for p in 0..<n {
                    sum += b[p * ldb + i] * _triRealA(a, row: p, col: j, lda: lda, upper: upper, unit: unit, doTrans: doTrans)
                }
            }
            tmp[j * m + i] = alpha * sum
        }
    }
    for j in 0..<n {
        for i in 0..<m {
            b[j * ldb + i] = tmp[j * m + i]
        }
    }
    return 0
}

func _trsm<T: BinaryFloatingPoint>(
    side: CChar,
    uplo: CChar,
    transa: CChar,
    diag: CChar,
    m: Int,
    n: Int,
    alpha: T,
    a: UnsafePointer<T>,
    lda: Int,
    b: UnsafeMutablePointer<T>,
    ldb: Int
) -> Int32 {
    guard m > 0, n > 0, lda > 0, ldb >= m else { return 0 }
    let left = _isLeft(side)
    let aDim = left ? m : n
    guard lda >= aDim else { return 0 }
    for j in 0..<n {
        for i in 0..<m {
            b[j * ldb + i] *= alpha
        }
    }
    if alpha == 0 { return 0 }
    if left {
        for j in 0..<n {
            let info = _trsv(uplo: uplo, trans: transa, diag: diag, n: m, a: a, lda: lda, x: b + j * ldb, incx: 1)
            if info != 0 { return info }
        }
        return 0
    }
    let upper = _isUpper(uplo)
    let unit = _isUnitDiag(diag)
    let doTrans = _isTrans(transa)
    let opUpper = doTrans ? !upper : upper
    func opA(_ row: Int, _ col: Int) -> T {
        _triRealA(a, row: row, col: col, lda: lda, upper: upper, unit: unit, doTrans: doTrans)
    }
    if opUpper {
        for j in 0..<n {
            let diagV = opA(j, j)
            if diagV == 0 { return Int32(j + 1) }
            for i in 0..<m {
                var sum = b[j * ldb + i]
                for p in 0..<j {
                    sum -= b[p * ldb + i] * opA(p, j)
                }
                b[j * ldb + i] = sum / diagV
            }
        }
    } else {
        var j = n - 1
        while j >= 0 {
            let diagV = opA(j, j)
            if diagV == 0 { return Int32(j + 1) }
            for i in 0..<m {
                var sum = b[j * ldb + i]
                if j + 1 < n {
                    for p in (j + 1)..<n {
                        sum -= b[p * ldb + i] * opA(p, j)
                    }
                }
                b[j * ldb + i] = sum / diagV
            }
            j -= 1
        }
    }
    return 0
}

func _rotm<T: BinaryFloatingPoint>(
    n: Int,
    x: UnsafeMutablePointer<T>,
    incx: Int,
    y: UnsafeMutablePointer<T>,
    incy: Int,
    param: UnsafePointer<T>
) -> Int32 {
    guard n > 0, incx != 0, incy != 0 else { return 0 }
    let flag = param[0]
    if flag + 2 == 0 { return 0 }
    let h11: T
    let h12: T
    let h21: T
    let h22: T
    if flag < 0 {
        h11 = param[1]
        h21 = param[2]
        h12 = param[3]
        h22 = param[4]
    } else if flag == 0 {
        h11 = 1
        h21 = param[2]
        h12 = param[3]
        h22 = 1
    } else {
        h11 = param[1]
        h21 = -1
        h12 = 1
        h22 = param[4]
    }
    var xi = 0
    var yi = 0
    for _ in 0..<n {
        let xv = x[xi]
        let yv = y[yi]
        x[xi] = h11 * xv + h12 * yv
        y[yi] = h21 * xv + h22 * yv
        xi += incx
        yi += incy
    }
    return 0
}

func _rotmg<T: BinaryFloatingPoint>(
    d1: inout T,
    d2: inout T,
    x1: inout T,
    y1: T,
    param: UnsafeMutablePointer<T>
) -> Int32 {
    let gam: T = 4096
    let gamsq = gam * gam
    let rgamsq = 1 / gamsq
    var flag: T = -1
    var h11: T = 0
    var h12: T = 0
    var h21: T = 0
    var h22: T = 0
    if d1 < 0 {
        d1 = 0
        d2 = 0
        x1 = 0
        param[0] = -1
        param[1] = 0
        param[2] = 0
        param[3] = 0
        param[4] = 0
        return 0
    }
    if d2 == 0 || y1 == 0 {
        param[0] = -2
        param[1] = 0
        param[2] = 0
        param[3] = 0
        param[4] = 0
        return 0
    }
    if (d1 == 0 || x1 == 0) && d2 > 0 {
        flag = 1
        h12 = 1
        h21 = -1
        x1 = y1
        swap(&d1, &d2)
    } else {
        let p1 = d1 * x1
        let p2 = d2 * y1
        let q1 = p1 * x1
        let q2 = p2 * y1
        if abs(q1) > abs(q2) {
            h21 = -y1 / x1
            h12 = p2 / p1
            let u = 1 - h12 * h21
            if u <= 0 {
                d1 = 0
                d2 = 0
                x1 = 0
                param[0] = -1
                param[1] = 0
                param[2] = 0
                param[3] = 0
                param[4] = 0
                return 0
            }
            flag = 0
            h11 = 1
            h22 = 1
            d1 /= u
            d2 /= u
            x1 *= u
        } else {
            if q2 < 0 {
                d1 = 0
                d2 = 0
                x1 = 0
                param[0] = -1
                param[1] = 0
                param[2] = 0
                param[3] = 0
                param[4] = 0
                return 0
            }
            flag = 1
            h21 = -1
            h12 = 1
            h11 = p1 / p2
            h22 = x1 / y1
            let u = 1 + h11 * h22
            let nd1 = d2 / u
            d2 = d1 / u
            d1 = nd1
            x1 = y1 * u
        }
    }
    while d1 <= rgamsq && d1 != 0 {
        flag = -1
        d1 = (d1 * gam) * gam
        x1 /= gam
        h11 /= gam
        h12 /= gam
    }
    while d1 > gamsq {
        flag = -1
        d1 = (d1 / gam) / gam
        x1 *= gam
        h11 *= gam
        h12 *= gam
    }
    while abs(d2) <= rgamsq && d2 != 0 {
        flag = -1
        d2 = (d2 * gam) * gam
        h21 /= gam
        h22 /= gam
    }
    while abs(d2) > gamsq {
        flag = -1
        d2 = (d2 / gam) / gam
        h21 *= gam
        h22 *= gam
    }
    param[0] = flag
    if flag < 0 {
        param[1] = h11
        param[2] = h21
        param[3] = h12
        param[4] = h22
    } else if flag == 0 {
        param[1] = 0
        param[2] = h21
        param[3] = h12
        param[4] = 0
    } else {
        param[1] = h11
        param[2] = 0
        param[3] = 0
        param[4] = h22
    }
    return 0
}
