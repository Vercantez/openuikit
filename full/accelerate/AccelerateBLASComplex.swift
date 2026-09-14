import Foundation

struct _Cplx<T: BinaryFloatingPoint> {
    var re: T
    var im: T

    static var zero: _Cplx { _Cplx(re: 0, im: 0) }

    static func + (lhs: _Cplx, rhs: _Cplx) -> _Cplx {
        _Cplx(re: lhs.re + rhs.re, im: lhs.im + rhs.im)
    }

    static func * (lhs: _Cplx, rhs: _Cplx) -> _Cplx {
        _Cplx(
            re: lhs.re * rhs.re - lhs.im * rhs.im,
            im: lhs.re * rhs.im + lhs.im * rhs.re
        )
    }

    func conjugate() -> _Cplx { _Cplx(re: re, im: -im) }

    func scaled(_ s: T) -> _Cplx { _Cplx(re: re * s, im: im * s) }

    var abs1: T { abs(re) + abs(im) }

    var abs2: T { re * re + im * im }

    var modulus: T { abs2.squareRoot() }

    var isZero: Bool { re == 0 && im == 0 }

    static var one: _Cplx { _Cplx(re: 1, im: 0) }

    static func - (lhs: _Cplx, rhs: _Cplx) -> _Cplx {
        _Cplx(re: lhs.re - rhs.re, im: lhs.im - rhs.im)
    }

    static func / (lhs: _Cplx, rhs: _Cplx) -> _Cplx {
        let den = rhs.re * rhs.re + rhs.im * rhs.im
        return _Cplx(
            re: (lhs.re * rhs.re + lhs.im * rhs.im) / den,
            im: (lhs.im * rhs.re - lhs.re * rhs.im) / den
        )
    }
}

func _cplxLoad<T: BinaryFloatingPoint>(_ pointer: UnsafeRawPointer, _ index: Int) -> _Cplx<T> {
    let base = pointer.assumingMemoryBound(to: T.self)
    return _Cplx(re: base[index * 2], im: base[index * 2 + 1])
}

func _cplxStore<T: BinaryFloatingPoint>(_ pointer: UnsafeMutableRawPointer, _ index: Int, _ value: _Cplx<T>) {
    let base = pointer.assumingMemoryBound(to: T.self)
    base[index * 2] = value.re
    base[index * 2 + 1] = value.im
}

func _isConjTrans(_ ch: CChar) -> Bool {
    ch == 67 || ch == 99
}

func _isUpper(_ ch: CChar) -> Bool {
    ch == 85 || ch == 117
}

func _isUnitDiag(_ ch: CChar) -> Bool {
    ch == 85 || ch == 117
}

func _isLeft(_ ch: CChar) -> Bool {
    ch == 76 || ch == 108
}

func _complexOpA<T: BinaryFloatingPoint>(
    _ a: UnsafeRawPointer,
    i: Int,
    p: Int,
    lda: Int,
    trans: CChar
) -> _Cplx<T> {
    if _isTrans(trans) || _isConjTrans(trans) {
        let value: _Cplx<T> = _cplxLoad(a, i * lda + p)
        return _isConjTrans(trans) ? value.conjugate() : value
    }
    return _cplxLoad(a, p * lda + i)
}

func _complexOpB<T: BinaryFloatingPoint>(
    _ b: UnsafeRawPointer,
    p: Int,
    j: Int,
    ldb: Int,
    trans: CChar
) -> _Cplx<T> {
    if _isTrans(trans) || _isConjTrans(trans) {
        let value: _Cplx<T> = _cplxLoad(b, p * ldb + j)
        return _isConjTrans(trans) ? value.conjugate() : value
    }
    return _cplxLoad(b, j * ldb + p)
}

func _caxpy<T: BinaryFloatingPoint>(
    n: Int,
    alpha: _Cplx<T>,
    x: UnsafeRawPointer,
    incx: Int,
    y: UnsafeMutableRawPointer,
    incy: Int
) {
    guard n > 0, incx != 0, incy != 0 else { return }
    var xi = 0
    var yi = 0
    for _ in 0..<n {
        let xv: _Cplx<T> = _cplxLoad(x, xi)
        let yv: _Cplx<T> = _cplxLoad(y, yi)
        _cplxStore(y, yi, yv + alpha * xv)
        xi += incx
        yi += incy
    }
}

func _ccopy<T: BinaryFloatingPoint>(
    _: T.Type,
    n: Int,
    x: UnsafeRawPointer,
    incx: Int,
    y: UnsafeMutableRawPointer,
    incy: Int
) {
    guard n > 0, incx != 0, incy != 0 else { return }
    var xi = 0
    var yi = 0
    for _ in 0..<n {
        let xv: _Cplx<T> = _cplxLoad(x, xi)
        _cplxStore(y, yi, xv)
        xi += incx
        yi += incy
    }
}

func _cdot<T: BinaryFloatingPoint>(
    n: Int,
    x: UnsafeRawPointer,
    incx: Int,
    y: UnsafeRawPointer,
    incy: Int,
    conjugateX: Bool
) -> _Cplx<T> {
    guard n > 0, incx != 0, incy != 0 else { return .zero }
    var sum = _Cplx<T>.zero
    var xi = 0
    var yi = 0
    for _ in 0..<n {
        let xv: _Cplx<T> = _cplxLoad(x, xi)
        let yv: _Cplx<T> = _cplxLoad(y, yi)
        sum = sum + (conjugateX ? xv.conjugate() : xv) * yv
        xi += incx
        yi += incy
    }
    return sum
}

func _cscal<T: BinaryFloatingPoint>(
    n: Int,
    alpha: _Cplx<T>,
    x: UnsafeMutableRawPointer,
    incx: Int
) {
    guard n > 0, incx != 0 else { return }
    var i = 0
    for _ in 0..<n {
        let xv: _Cplx<T> = _cplxLoad(x, i)
        _cplxStore(x, i, alpha * xv)
        i += incx
    }
}

func _csscal<T: BinaryFloatingPoint>(
    n: Int,
    alpha: T,
    x: UnsafeMutableRawPointer,
    incx: Int
) {
    guard n > 0, incx != 0 else { return }
    var i = 0
    for _ in 0..<n {
        let xv: _Cplx<T> = _cplxLoad(x, i)
        _cplxStore(x, i, xv.scaled(alpha))
        i += incx
    }
}

func _cswap<T: BinaryFloatingPoint>(
    _: T.Type,
    n: Int,
    x: UnsafeMutableRawPointer,
    incx: Int,
    y: UnsafeMutableRawPointer,
    incy: Int
) {
    guard n > 0, incx != 0, incy != 0 else { return }
    var xi = 0
    var yi = 0
    for _ in 0..<n {
        let xv: _Cplx<T> = _cplxLoad(x, xi)
        let yv: _Cplx<T> = _cplxLoad(y, yi)
        _cplxStore(x, xi, yv)
        _cplxStore(y, yi, xv)
        xi += incx
        yi += incy
    }
}

func _casum<T: BinaryFloatingPoint>(
    n: Int,
    x: UnsafeRawPointer,
    incx: Int
) -> T {
    guard n > 0, incx != 0 else { return 0 }
    var sum: T = 0
    var i = 0
    for _ in 0..<n {
        let xv: _Cplx<T> = _cplxLoad(x, i)
        sum += xv.abs1
        i += incx
    }
    return sum
}

func _cnrm2<T: BinaryFloatingPoint>(
    n: Int,
    x: UnsafeRawPointer,
    incx: Int
) -> T {
    guard n > 0, incx != 0 else { return 0 }
    var sum: T = 0
    var i = 0
    for _ in 0..<n {
        let xv: _Cplx<T> = _cplxLoad(x, i)
        sum += xv.abs2
        i += incx
    }
    return sum.squareRoot()
}

func _icamax<T: BinaryFloatingPoint>(
    _: T.Type,
    n: Int,
    x: UnsafeRawPointer,
    incx: Int
) -> Int32 {
    guard n > 0, incx != 0 else { return 0 }
    var best = 0
    var bestAbs: T = _cplxLoad(x, 0).abs1
    var i = incx
    var index = 1
    while index < n {
        let v: T = _cplxLoad(x, i).abs1
        if v > bestAbs {
            bestAbs = v
            best = index
        }
        i += incx
        index += 1
    }
    return Int32(best)
}

func _cgemm<T: BinaryFloatingPoint>(
    transA: CChar,
    transB: CChar,
    m: Int,
    n: Int,
    k: Int,
    alpha: _Cplx<T>,
    a: UnsafeRawPointer,
    lda: Int,
    b: UnsafeRawPointer,
    ldb: Int,
    beta: _Cplx<T>,
    c: UnsafeMutableRawPointer,
    ldc: Int
) -> Int32 {
    guard m >= 0, n >= 0, k >= 0, lda > 0, ldb > 0, ldc > 0 else { return -1 }
    for j in 0..<n {
        for i in 0..<m {
            var sum = _Cplx<T>.zero
            for p in 0..<k {
                let av: _Cplx<T> = _complexOpA(a, i: i, p: p, lda: lda, trans: transA)
                let bv: _Cplx<T> = _complexOpB(b, p: p, j: j, ldb: ldb, trans: transB)
                sum = sum + av * bv
            }
            let idx = j * ldc + i
            let cv: _Cplx<T> = _cplxLoad(c, idx)
            _cplxStore(c, idx, alpha * sum + beta * cv)
        }
    }
    return 0
}

func _cgemv<T: BinaryFloatingPoint>(
    trans: CChar,
    m: Int,
    n: Int,
    alpha: _Cplx<T>,
    a: UnsafeRawPointer,
    lda: Int,
    x: UnsafeRawPointer,
    incx: Int,
    beta: _Cplx<T>,
    y: UnsafeMutableRawPointer,
    incy: Int
) -> Int32 {
    guard m >= 0, n >= 0, lda > 0, incx != 0, incy != 0 else { return -1 }
    let doTrans = _isTrans(trans) || _isConjTrans(trans)
    let outCount = doTrans ? n : m
    let inner = doTrans ? m : n
    var yi = 0
    for i in 0..<outCount {
        var sum = _Cplx<T>.zero
        var xi = 0
        for p in 0..<inner {
            let av: _Cplx<T>
            if doTrans {
                av = _complexOpA(a, i: p, p: i, lda: lda, trans: trans)
            } else {
                av = _complexOpA(a, i: i, p: p, lda: lda, trans: trans)
            }
            let xv: _Cplx<T> = _cplxLoad(x, xi)
            sum = sum + av * xv
            xi += incx
        }
        let yv: _Cplx<T> = _cplxLoad(y, yi)
        _cplxStore(y, yi, alpha * sum + beta * yv)
        yi += incy
    }
    return 0
}

func _cger<T: BinaryFloatingPoint>(
    m: Int,
    n: Int,
    alpha: _Cplx<T>,
    x: UnsafeRawPointer,
    incx: Int,
    y: UnsafeRawPointer,
    incy: Int,
    a: UnsafeMutableRawPointer,
    lda: Int,
    conjugateY: Bool
) -> Int32 {
    guard m > 0, n > 0, lda >= m, incx != 0, incy != 0 else { return 0 }
    var xi = 0
    for i in 0..<m {
        var yj = 0
        let xv: _Cplx<T> = _cplxLoad(x, xi)
        for j in 0..<n {
            var yv: _Cplx<T> = _cplxLoad(y, yj)
            if conjugateY { yv = yv.conjugate() }
            let idx = j * lda + i
            let av: _Cplx<T> = _cplxLoad(a, idx)
            _cplxStore(a, idx, av + alpha * xv * yv)
            yj += incy
        }
        xi += incx
    }
    return 0
}

func _chemv<T: BinaryFloatingPoint>(
    uplo: CChar,
    n: Int,
    alpha: _Cplx<T>,
    a: UnsafeRawPointer,
    lda: Int,
    x: UnsafeRawPointer,
    incx: Int,
    beta: _Cplx<T>,
    y: UnsafeMutableRawPointer,
    incy: Int
) -> Int32 {
    guard n > 0, lda >= n, incx != 0, incy != 0 else { return 0 }
    let upper = uplo == 85 || uplo == 117
    var yi = 0
    for i in 0..<n {
        var sum = _Cplx<T>.zero
        var xj = 0
        for j in 0..<n {
            let aij: _Cplx<T>
            if upper {
                if i <= j {
                    aij = _cplxLoad(a, j * lda + i)
                } else {
                    aij = _cplxLoad(a, i * lda + j).conjugate()
                }
            } else if i >= j {
                aij = _cplxLoad(a, j * lda + i)
            } else {
                aij = _cplxLoad(a, i * lda + j).conjugate()
            }
            let stored = (i == j) ? _Cplx<T>(re: aij.re, im: 0) : aij
            let xv: _Cplx<T> = _cplxLoad(x, xj)
            sum = sum + stored * xv
            xj += incx
        }
        let yv: _Cplx<T> = _cplxLoad(y, yi)
        _cplxStore(y, yi, alpha * sum + beta * yv)
        yi += incy
    }
    return 0
}

func _hermitianElem<T: BinaryFloatingPoint>(
    _ a: UnsafeRawPointer,
    i: Int,
    j: Int,
    lda: Int,
    upper: Bool
) -> _Cplx<T> {
    if i == j {
        let v: _Cplx<T> = _cplxLoad(a, j * lda + i)
        return _Cplx(re: v.re, im: 0)
    }
    if upper {
        if i <= j { return _cplxLoad(a, j * lda + i) }
        return _cplxLoad(a, i * lda + j).conjugate()
    }
    if i >= j { return _cplxLoad(a, j * lda + i) }
    return _cplxLoad(a, i * lda + j).conjugate()
}

func _symmetricElem<T: BinaryFloatingPoint>(
    _ a: UnsafeRawPointer,
    i: Int,
    j: Int,
    lda: Int,
    upper: Bool
) -> _Cplx<T> {
    if upper {
        return _cplxLoad(a, max(i, j) * lda + min(i, j))
    }
    return _cplxLoad(a, min(i, j) * lda + max(i, j))
}

func _triOpA<T: BinaryFloatingPoint>(
    _ a: UnsafeRawPointer,
    row: Int,
    col: Int,
    lda: Int,
    upper: Bool,
    unit: Bool,
    doTrans: Bool,
    doConj: Bool
) -> _Cplx<T> {
    let r = doTrans ? col : row
    let c = doTrans ? row : col
    if r == c && unit { return .one }
    let inTriangle = upper ? (r <= c) : (r >= c)
    if !inTriangle { return .zero }
    var v: _Cplx<T> = _cplxLoad(a, c * lda + r)
    if doConj { v = v.conjugate() }
    return v
}

func _ctrmv<T: BinaryFloatingPoint>(
    _: T.Type,
    uplo: CChar,
    trans: CChar,
    diag: CChar,
    n: Int,
    a: UnsafeRawPointer,
    lda: Int,
    x: UnsafeMutableRawPointer,
    incx: Int
) -> Int32 {
    guard n > 0, lda >= n, incx != 0 else { return 0 }
    let upper = _isUpper(uplo)
    let unit = _isUnitDiag(diag)
    let doTrans = _isTrans(trans) || _isConjTrans(trans)
    let doConj = _isConjTrans(trans)
    var y = [_Cplx<T>](repeating: .zero, count: n)
    for i in 0..<n { y[i] = _cplxLoad(x, i * incx) }
    var out = [_Cplx<T>](repeating: .zero, count: n)
    for i in 0..<n {
        var sum = _Cplx<T>.zero
        for j in 0..<n {
            sum = sum + _triOpA(a, row: i, col: j, lda: lda, upper: upper, unit: unit, doTrans: doTrans, doConj: doConj) * y[j]
        }
        out[i] = sum
    }
    for i in 0..<n { _cplxStore(x, i * incx, out[i]) }
    return 0
}

func _ctrsv<T: BinaryFloatingPoint>(
    _: T.Type,
    uplo: CChar,
    trans: CChar,
    diag: CChar,
    n: Int,
    a: UnsafeRawPointer,
    lda: Int,
    x: UnsafeMutableRawPointer,
    incx: Int
) -> Int32 {
    guard n > 0, lda >= n, incx != 0 else { return 0 }
    let upper = _isUpper(uplo)
    let unit = _isUnitDiag(diag)
    let doTrans = _isTrans(trans) || _isConjTrans(trans)
    let doConj = _isConjTrans(trans)
    var y = [_Cplx<T>](repeating: .zero, count: n)
    for i in 0..<n { y[i] = _cplxLoad(x, i * incx) }
    func opA(_ row: Int, _ col: Int) -> _Cplx<T> {
        _triOpA(a, row: row, col: col, lda: lda, upper: upper, unit: unit, doTrans: doTrans, doConj: doConj)
    }
    let opUpper = doTrans ? !upper : upper
    if opUpper {
        var i = n - 1
        while i >= 0 {
            var sum = y[i]
            if i + 1 < n {
                for j in (i + 1)..<n { sum = sum - opA(i, j) * y[j] }
            }
            let diagV = opA(i, i)
            if diagV.isZero { return Int32(i + 1) }
            y[i] = sum / diagV
            i -= 1
        }
    } else {
        for i in 0..<n {
            var sum = y[i]
            for j in 0..<i { sum = sum - opA(i, j) * y[j] }
            let diagV = opA(i, i)
            if diagV.isZero { return Int32(i + 1) }
            y[i] = sum / diagV
        }
    }
    for i in 0..<n { _cplxStore(x, i * incx, y[i]) }
    return 0
}

func _ctrmm<T: BinaryFloatingPoint>(
    side: CChar,
    uplo: CChar,
    transa: CChar,
    diag: CChar,
    m: Int,
    n: Int,
    alpha: _Cplx<T>,
    a: UnsafeRawPointer,
    lda: Int,
    b: UnsafeMutableRawPointer,
    ldb: Int
) -> Int32 {
    guard m > 0, n > 0, lda > 0, ldb >= m else { return 0 }
    let left = _isLeft(side)
    let upper = _isUpper(uplo)
    let unit = _isUnitDiag(diag)
    let doTrans = _isTrans(transa) || _isConjTrans(transa)
    let doConj = _isConjTrans(transa)
    let aDim = left ? m : n
    guard lda >= aDim else { return 0 }
    if alpha.isZero {
        for j in 0..<n {
            for i in 0..<m { _cplxStore(b, j * ldb + i, _Cplx<T>.zero) }
        }
        return 0
    }
    var tmp = [_Cplx<T>](repeating: .zero, count: m * n)
    for j in 0..<n {
        for i in 0..<m {
            var sum = _Cplx<T>.zero
            if left {
                for p in 0..<m {
                    let av: _Cplx<T> = _triOpA(a, row: i, col: p, lda: lda, upper: upper, unit: unit, doTrans: doTrans, doConj: doConj)
                    sum = sum + av * _cplxLoad(b, j * ldb + p)
                }
            } else {
                for p in 0..<n {
                    let bv: _Cplx<T> = _cplxLoad(b, p * ldb + i)
                    let av: _Cplx<T> = _triOpA(a, row: p, col: j, lda: lda, upper: upper, unit: unit, doTrans: doTrans, doConj: doConj)
                    sum = sum + bv * av
                }
            }
            tmp[j * m + i] = alpha * sum
        }
    }
    for j in 0..<n {
        for i in 0..<m {
            _cplxStore(b, j * ldb + i, tmp[j * m + i])
        }
    }
    return 0
}

func _ctrsm<T: BinaryFloatingPoint>(
    side: CChar,
    uplo: CChar,
    transa: CChar,
    diag: CChar,
    m: Int,
    n: Int,
    alpha: _Cplx<T>,
    a: UnsafeRawPointer,
    lda: Int,
    b: UnsafeMutableRawPointer,
    ldb: Int
) -> Int32 {
    guard m > 0, n > 0, lda > 0, ldb >= m else { return 0 }
    let left = _isLeft(side)
    let aDim = left ? m : n
    guard lda >= aDim else { return 0 }
    for j in 0..<n {
        for i in 0..<m {
            let idx = j * ldb + i
            _cplxStore(b, idx, alpha * (_cplxLoad(b, idx) as _Cplx<T>))
        }
    }
    if alpha.isZero { return 0 }
    if left {
        var packed = [T](repeating: 0, count: 2 * m)
        for j in 0..<n {
            let info = packed.withUnsafeMutableBufferPointer { buf -> Int32 in
                guard let base = buf.baseAddress else { return -1 }
                let raw = UnsafeMutableRawPointer(base)
                for i in 0..<m {
                    _cplxStore(raw, i, _cplxLoad(b, j * ldb + i) as _Cplx<T>)
                }
                let info = _ctrsv(T.self, uplo: uplo, trans: transa, diag: diag, n: m, a: a, lda: lda, x: raw, incx: 1)
                for i in 0..<m {
                    _cplxStore(b, j * ldb + i, _cplxLoad(raw, i) as _Cplx<T>)
                }
                return info
            }
            if info != 0 { return info }
        }
        return 0
    }
    let upper = _isUpper(uplo)
    let unit = _isUnitDiag(diag)
    let doTrans = _isTrans(transa) || _isConjTrans(transa)
    let doConj = _isConjTrans(transa)
    let opUpper = doTrans ? !upper : upper
    func opA(_ row: Int, _ col: Int) -> _Cplx<T> {
        _triOpA(a, row: row, col: col, lda: lda, upper: upper, unit: unit, doTrans: doTrans, doConj: doConj)
    }
    if opUpper {
        for j in 0..<n {
            let diagV = opA(j, j)
            if diagV.isZero { return Int32(j + 1) }
            for i in 0..<m {
                var sum: _Cplx<T> = _cplxLoad(b, j * ldb + i)
                for p in 0..<j {
                    sum = sum - (_cplxLoad(b, p * ldb + i) as _Cplx<T>) * opA(p, j)
                }
                _cplxStore(b, j * ldb + i, sum / diagV)
            }
        }
    } else {
        var j = n - 1
        while j >= 0 {
            let diagV = opA(j, j)
            if diagV.isZero { return Int32(j + 1) }
            for i in 0..<m {
                var sum: _Cplx<T> = _cplxLoad(b, j * ldb + i)
                if j + 1 < n {
                    for p in (j + 1)..<n {
                        sum = sum - (_cplxLoad(b, p * ldb + i) as _Cplx<T>) * opA(p, j)
                    }
                }
                _cplxStore(b, j * ldb + i, sum / diagV)
            }
            j -= 1
        }
    }
    return 0
}

func _chemm<T: BinaryFloatingPoint>(
    side: CChar,
    uplo: CChar,
    m: Int,
    n: Int,
    alpha: _Cplx<T>,
    a: UnsafeRawPointer,
    lda: Int,
    b: UnsafeRawPointer,
    ldb: Int,
    beta: _Cplx<T>,
    c: UnsafeMutableRawPointer,
    ldc: Int
) -> Int32 {
    guard m > 0, n > 0, lda > 0, ldb >= m, ldc >= m else { return 0 }
    let left = _isLeft(side)
    let upper = _isUpper(uplo)
    let aDim = left ? m : n
    guard lda >= aDim else { return 0 }
    for j in 0..<n {
        for i in 0..<m {
            var sum = _Cplx<T>.zero
            if left {
                for p in 0..<m {
                    let av: _Cplx<T> = _hermitianElem(a, i: i, j: p, lda: lda, upper: upper)
                    sum = sum + av * _cplxLoad(b, j * ldb + p)
                }
            } else {
                for p in 0..<n {
                    let bv: _Cplx<T> = _cplxLoad(b, p * ldb + i)
                    let av: _Cplx<T> = _hermitianElem(a, i: p, j: j, lda: lda, upper: upper)
                    sum = sum + bv * av
                }
            }
            let idx = j * ldc + i
            let cv: _Cplx<T> = _cplxLoad(c, idx)
            _cplxStore(c, idx, alpha * sum + beta * cv)
        }
    }
    return 0
}

func _csymm<T: BinaryFloatingPoint>(
    side: CChar,
    uplo: CChar,
    m: Int,
    n: Int,
    alpha: _Cplx<T>,
    a: UnsafeRawPointer,
    lda: Int,
    b: UnsafeRawPointer,
    ldb: Int,
    beta: _Cplx<T>,
    c: UnsafeMutableRawPointer,
    ldc: Int
) -> Int32 {
    guard m > 0, n > 0, lda > 0, ldb >= m, ldc >= m else { return 0 }
    let left = _isLeft(side)
    let upper = _isUpper(uplo)
    let aDim = left ? m : n
    guard lda >= aDim else { return 0 }
    for j in 0..<n {
        for i in 0..<m {
            var sum = _Cplx<T>.zero
            if left {
                for p in 0..<m {
                    let av: _Cplx<T> = _symmetricElem(a, i: i, j: p, lda: lda, upper: upper)
                    sum = sum + av * _cplxLoad(b, j * ldb + p)
                }
            } else {
                for p in 0..<n {
                    let bv: _Cplx<T> = _cplxLoad(b, p * ldb + i)
                    let av: _Cplx<T> = _symmetricElem(a, i: p, j: j, lda: lda, upper: upper)
                    sum = sum + bv * av
                }
            }
            let idx = j * ldc + i
            let cv: _Cplx<T> = _cplxLoad(c, idx)
            _cplxStore(c, idx, alpha * sum + beta * cv)
        }
    }
    return 0
}

func _cher<T: BinaryFloatingPoint>(
    uplo: CChar,
    n: Int,
    alpha: T,
    x: UnsafeRawPointer,
    incx: Int,
    a: UnsafeMutableRawPointer,
    lda: Int
) -> Int32 {
    guard n > 0, lda >= n, incx != 0 else { return 0 }
    let upper = _isUpper(uplo)
    for j in 0..<n {
        let xj: _Cplx<T> = _cplxLoad(x, j * incx)
        let xjH = xj.conjugate()
        let iStart = upper ? 0 : j
        let iEnd = upper ? j : n - 1
        var i = iStart
        while i <= iEnd {
            let xi: _Cplx<T> = _cplxLoad(x, i * incx)
            let idx = j * lda + i
            var av: _Cplx<T> = _cplxLoad(a, idx)
            av = av + (xi * xjH).scaled(alpha)
            if i == j { av.im = 0 }
            _cplxStore(a, idx, av)
            i += 1
        }
    }
    return 0
}

func _cher2<T: BinaryFloatingPoint>(
    uplo: CChar,
    n: Int,
    alpha: _Cplx<T>,
    x: UnsafeRawPointer,
    incx: Int,
    y: UnsafeRawPointer,
    incy: Int,
    a: UnsafeMutableRawPointer,
    lda: Int
) -> Int32 {
    guard n > 0, lda >= n, incx != 0, incy != 0 else { return 0 }
    let upper = _isUpper(uplo)
    let alphaC = alpha.conjugate()
    for j in 0..<n {
        let xj: _Cplx<T> = _cplxLoad(x, j * incx)
        let yj: _Cplx<T> = _cplxLoad(y, j * incy)
        let iStart = upper ? 0 : j
        let iEnd = upper ? j : n - 1
        var i = iStart
        while i <= iEnd {
            let xi: _Cplx<T> = _cplxLoad(x, i * incx)
            let yi: _Cplx<T> = _cplxLoad(y, i * incy)
            let idx = j * lda + i
            var av: _Cplx<T> = _cplxLoad(a, idx)
            av = av + alpha * xi * yj.conjugate() + alphaC * yi * xj.conjugate()
            if i == j { av.im = 0 }
            _cplxStore(a, idx, av)
            i += 1
        }
    }
    return 0
}

func _cherk<T: BinaryFloatingPoint>(
    uplo: CChar,
    trans: CChar,
    n: Int,
    k: Int,
    alpha: T,
    a: UnsafeRawPointer,
    lda: Int,
    beta: T,
    c: UnsafeMutableRawPointer,
    ldc: Int
) -> Int32 {
    guard n > 0, k >= 0, ldc >= n, lda > 0 else { return 0 }
    let upper = _isUpper(uplo)
    let doConjTrans = _isTrans(trans) || _isConjTrans(trans)
    for j in 0..<n {
        for i in 0..<n {
            if upper && i > j { continue }
            if !upper && i < j { continue }
            var sum = _Cplx<T>.zero
            for p in 0..<k {
                if doConjTrans {
                    let ai: _Cplx<T> = _cplxLoad(a, i * lda + p)
                    let aj: _Cplx<T> = _cplxLoad(a, j * lda + p)
                    sum = sum + ai.conjugate() * aj
                } else {
                    let ai: _Cplx<T> = _cplxLoad(a, p * lda + i)
                    let aj: _Cplx<T> = _cplxLoad(a, p * lda + j)
                    sum = sum + ai * aj.conjugate()
                }
            }
            let idx = j * ldc + i
            var cv: _Cplx<T> = _cplxLoad(c, idx)
            cv = sum.scaled(alpha) + cv.scaled(beta)
            if i == j { cv.im = 0 }
            _cplxStore(c, idx, cv)
        }
    }
    return 0
}

func _cher2k<T: BinaryFloatingPoint>(
    uplo: CChar,
    trans: CChar,
    n: Int,
    k: Int,
    alpha: _Cplx<T>,
    a: UnsafeRawPointer,
    lda: Int,
    b: UnsafeRawPointer,
    ldb: Int,
    beta: T,
    c: UnsafeMutableRawPointer,
    ldc: Int
) -> Int32 {
    guard n > 0, k >= 0, ldc >= n, lda > 0, ldb > 0 else { return 0 }
    let upper = _isUpper(uplo)
    let doConjTrans = _isTrans(trans) || _isConjTrans(trans)
    let alphaC = alpha.conjugate()
    for j in 0..<n {
        for i in 0..<n {
            if upper && i > j { continue }
            if !upper && i < j { continue }
            var sum = _Cplx<T>.zero
            for p in 0..<k {
                if doConjTrans {
                    let ai: _Cplx<T> = _cplxLoad(a, i * lda + p)
                    let bi: _Cplx<T> = _cplxLoad(b, i * ldb + p)
                    let aj: _Cplx<T> = _cplxLoad(a, j * lda + p)
                    let bj: _Cplx<T> = _cplxLoad(b, j * ldb + p)
                    sum = sum + alpha * ai.conjugate() * bj + alphaC * bi.conjugate() * aj
                } else {
                    let ai: _Cplx<T> = _cplxLoad(a, p * lda + i)
                    let bi: _Cplx<T> = _cplxLoad(b, p * ldb + i)
                    let aj: _Cplx<T> = _cplxLoad(a, p * lda + j)
                    let bj: _Cplx<T> = _cplxLoad(b, p * ldb + j)
                    sum = sum + alpha * ai * bj.conjugate() + alphaC * bi * aj.conjugate()
                }
            }
            let idx = j * ldc + i
            var cv: _Cplx<T> = _cplxLoad(c, idx)
            cv = sum + cv.scaled(beta)
            if i == j { cv.im = 0 }
            _cplxStore(c, idx, cv)
        }
    }
    return 0
}

func _csyrk<T: BinaryFloatingPoint>(
    uplo: CChar,
    trans: CChar,
    n: Int,
    k: Int,
    alpha: _Cplx<T>,
    a: UnsafeRawPointer,
    lda: Int,
    beta: _Cplx<T>,
    c: UnsafeMutableRawPointer,
    ldc: Int
) -> Int32 {
    guard n > 0, k >= 0, ldc >= n, lda > 0 else { return 0 }
    let upper = _isUpper(uplo)
    let doTrans = _isTrans(trans) || _isConjTrans(trans)
    for j in 0..<n {
        for i in 0..<n {
            if upper && i > j { continue }
            if !upper && i < j { continue }
            var sum = _Cplx<T>.zero
            for p in 0..<k {
                let av: _Cplx<T> = doTrans ? _cplxLoad(a, i * lda + p) : _cplxLoad(a, p * lda + i)
                let bv: _Cplx<T> = doTrans ? _cplxLoad(a, j * lda + p) : _cplxLoad(a, p * lda + j)
                sum = sum + av * bv
            }
            let idx = j * ldc + i
            let cv: _Cplx<T> = _cplxLoad(c, idx)
            _cplxStore(c, idx, alpha * sum + beta * cv)
        }
    }
    return 0
}

func _csyr2k<T: BinaryFloatingPoint>(
    uplo: CChar,
    trans: CChar,
    n: Int,
    k: Int,
    alpha: _Cplx<T>,
    a: UnsafeRawPointer,
    lda: Int,
    b: UnsafeRawPointer,
    ldb: Int,
    beta: _Cplx<T>,
    c: UnsafeMutableRawPointer,
    ldc: Int
) -> Int32 {
    guard n > 0, k >= 0, ldc >= n, lda > 0, ldb > 0 else { return 0 }
    let upper = _isUpper(uplo)
    let doTrans = _isTrans(trans) || _isConjTrans(trans)
    for j in 0..<n {
        for i in 0..<n {
            if upper && i > j { continue }
            if !upper && i < j { continue }
            var sum = _Cplx<T>.zero
            for p in 0..<k {
                let ai: _Cplx<T> = doTrans ? _cplxLoad(a, i * lda + p) : _cplxLoad(a, p * lda + i)
                let bi: _Cplx<T> = doTrans ? _cplxLoad(b, i * ldb + p) : _cplxLoad(b, p * ldb + i)
                let aj: _Cplx<T> = doTrans ? _cplxLoad(a, j * lda + p) : _cplxLoad(a, p * lda + j)
                let bj: _Cplx<T> = doTrans ? _cplxLoad(b, j * ldb + p) : _cplxLoad(b, p * ldb + j)
                sum = sum + ai * bj + bi * aj
            }
            let idx = j * ldc + i
            let cv: _Cplx<T> = _cplxLoad(c, idx)
            _cplxStore(c, idx, alpha * sum + beta * cv)
        }
    }
    return 0
}

func _crotg<T: BinaryFloatingPoint>(
    ca: UnsafeMutableRawPointer,
    cb: UnsafeRawPointer,
    c: UnsafeMutablePointer<T>,
    s: UnsafeMutableRawPointer
) -> Int32 {
    let a: _Cplx<T> = _cplxLoad(ca, 0)
    let b: _Cplx<T> = _cplxLoad(cb, 0)
    let absA = a.modulus
    if absA == 0 {
        c.pointee = 0
        _cplxStore(s, 0, _Cplx<T>.one)
        _cplxStore(ca, 0, b)
        return 0
    }
    let absB = b.modulus
    let scale = absA + absB
    let norm = scale * ((absA / scale) * (absA / scale) + (absB / scale) * (absB / scale)).squareRoot()
    let alpha = _Cplx<T>(re: a.re / absA, im: a.im / absA)
    c.pointee = absA / norm
    _cplxStore(s, 0, alpha * b.conjugate().scaled(1 / norm))
    _cplxStore(ca, 0, alpha.scaled(norm))
    return 0
}

func _csrot<T: BinaryFloatingPoint>(
    n: Int,
    x: UnsafeMutableRawPointer,
    incx: Int,
    y: UnsafeMutableRawPointer,
    incy: Int,
    c: T,
    s: T
) -> Int32 {
    guard n > 0, incx != 0, incy != 0 else { return 0 }
    var xi = 0
    var yi = 0
    for _ in 0..<n {
        let xv: _Cplx<T> = _cplxLoad(x, xi)
        let yv: _Cplx<T> = _cplxLoad(y, yi)
        _cplxStore(x, xi, xv.scaled(c) + yv.scaled(s))
        _cplxStore(y, yi, yv.scaled(c) - xv.scaled(s))
        xi += incx
        yi += incy
    }
    return 0
}

@discardableResult
public func caxpy_(
    _ n: UnsafeMutablePointer<Int32>!,
    _ ca: UnsafeMutableRawPointer!,
    _ cx: UnsafeMutableRawPointer!,
    _ incx: UnsafeMutablePointer<Int32>!,
    _ cy: UnsafeMutableRawPointer!,
    _ incy: UnsafeMutablePointer<Int32>!
) -> Int32 {
    guard let n, let ca, let cx, let incx, let cy, let incy else { return -1 }
    _caxpy(n: Int(n.pointee), alpha: _cplxLoad(ca, 0) as _Cplx<Float>, x: cx, incx: Int(incx.pointee), y: cy, incy: Int(incy.pointee))
    return 0
}

@discardableResult
public func ccopy_(
    _ n: UnsafeMutablePointer<Int32>!,
    _ cx: UnsafeMutableRawPointer!,
    _ incx: UnsafeMutablePointer<Int32>!,
    _ cy: UnsafeMutableRawPointer!,
    _ incy: UnsafeMutablePointer<Int32>!
) -> Int32 {
    guard let n, let cx, let incx, let cy, let incy else { return -1 }
    _ccopy(Float.self, n: Int(n.pointee), x: cx, incx: Int(incx.pointee), y: cy, incy: Int(incy.pointee))
    return 0
}

public func cdotc_(
    _ ret_val: UnsafeMutableRawPointer!,
    _ n: UnsafeMutablePointer<Int32>!,
    _ cx: UnsafeMutableRawPointer!,
    _ incx: UnsafeMutablePointer<Int32>!,
    _ cy: UnsafeMutableRawPointer!,
    _ incy: UnsafeMutablePointer<Int32>!
) {
    guard let ret_val, let n, let cx, let incx, let cy, let incy else { return }
    let sum: _Cplx<Float> = _cdot(n: Int(n.pointee), x: cx, incx: Int(incx.pointee), y: cy, incy: Int(incy.pointee), conjugateX: true)
    _cplxStore(ret_val, 0, sum)
}

public func cdotu_(
    _ ret_val: UnsafeMutableRawPointer!,
    _ n: UnsafeMutablePointer<Int32>!,
    _ cx: UnsafeMutableRawPointer!,
    _ incx: UnsafeMutablePointer<Int32>!,
    _ cy: UnsafeMutableRawPointer!,
    _ incy: UnsafeMutablePointer<Int32>!
) {
    guard let ret_val, let n, let cx, let incx, let cy, let incy else { return }
    let sum: _Cplx<Float> = _cdot(n: Int(n.pointee), x: cx, incx: Int(incx.pointee), y: cy, incy: Int(incy.pointee), conjugateX: false)
    _cplxStore(ret_val, 0, sum)
}

@discardableResult
public func cscal_(
    _ n: UnsafeMutablePointer<Int32>!,
    _ ca: UnsafeMutableRawPointer!,
    _ cx: UnsafeMutableRawPointer!,
    _ incx: UnsafeMutablePointer<Int32>!
) -> Int32 {
    guard let n, let ca, let cx, let incx else { return -1 }
    _cscal(n: Int(n.pointee), alpha: _cplxLoad(ca, 0) as _Cplx<Float>, x: cx, incx: Int(incx.pointee))
    return 0
}

@discardableResult
public func csscal_(
    _ n: UnsafeMutablePointer<Int32>!,
    _ sa: UnsafeMutablePointer<Float>!,
    _ cx: UnsafeMutableRawPointer!,
    _ incx: UnsafeMutablePointer<Int32>!
) -> Int32 {
    guard let n, let sa, let cx, let incx else { return -1 }
    _csscal(n: Int(n.pointee), alpha: sa.pointee, x: cx, incx: Int(incx.pointee))
    return 0
}

@discardableResult
public func cswap_(
    _ n: UnsafeMutablePointer<Int32>!,
    _ cx: UnsafeMutableRawPointer!,
    _ incx: UnsafeMutablePointer<Int32>!,
    _ cy: UnsafeMutableRawPointer!,
    _ incy: UnsafeMutablePointer<Int32>!
) -> Int32 {
    guard let n, let cx, let incx, let cy, let incy else { return -1 }
    _cswap(Float.self, n: Int(n.pointee), x: cx, incx: Int(incx.pointee), y: cy, incy: Int(incy.pointee))
    return 0
}

@discardableResult
public func scasum_(
    _ n: UnsafeMutablePointer<Int32>!,
    _ cx: UnsafeMutableRawPointer!,
    _ incx: UnsafeMutablePointer<Int32>!
) -> Double {
    guard let n, let cx, let incx else { return 0 }
    return Double(_casum(n: Int(n.pointee), x: cx, incx: Int(incx.pointee)) as Float)
}

@discardableResult
public func scnrm2_(
    _ n: UnsafeMutablePointer<Int32>!,
    _ cx: UnsafeMutableRawPointer!,
    _ incx: UnsafeMutablePointer<Int32>!
) -> Double {
    guard let n, let cx, let incx else { return 0 }
    return Double(_cnrm2(n: Int(n.pointee), x: cx, incx: Int(incx.pointee)) as Float)
}

@discardableResult
public func icamax_(
    _ n: UnsafeMutablePointer<Int32>!,
    _ cx: UnsafeMutableRawPointer!,
    _ incx: UnsafeMutablePointer<Int32>!
) -> Int32 {
    guard let n, let cx, let incx else { return 0 }
    return _icamax(Float.self, n: Int(n.pointee), x: cx, incx: Int(incx.pointee))
}

@discardableResult
public func cgemm_(
    _ transa: UnsafeMutablePointer<CChar>!,
    _ transb: UnsafeMutablePointer<CChar>!,
    _ m: UnsafeMutablePointer<Int32>!,
    _ n: UnsafeMutablePointer<Int32>!,
    _ k: UnsafeMutablePointer<Int32>!,
    _ alpha: UnsafeMutableRawPointer!,
    _ a: UnsafeMutableRawPointer!,
    _ lda: UnsafeMutablePointer<Int32>!,
    _ b: UnsafeMutableRawPointer!,
    _ ldb: UnsafeMutablePointer<Int32>!,
    _ beta: UnsafeMutableRawPointer!,
    _ c__: UnsafeMutableRawPointer!,
    _ ldc: UnsafeMutablePointer<Int32>!
) -> Int32 {
    guard let transa, let transb, let m, let n, let k, let alpha, let a, let lda, let b, let ldb, let beta, let c__, let ldc else { return -1 }
    return _cgemm(
        transA: transa.pointee, transB: transb.pointee,
        m: Int(m.pointee), n: Int(n.pointee), k: Int(k.pointee),
        alpha: _cplxLoad(alpha, 0) as _Cplx<Float>, a: a, lda: Int(lda.pointee),
        b: b, ldb: Int(ldb.pointee),
        beta: _cplxLoad(beta, 0) as _Cplx<Float>, c: c__, ldc: Int(ldc.pointee)
    )
}

@discardableResult
public func cgemv_(
    _ trans: UnsafeMutablePointer<CChar>!,
    _ m: UnsafeMutablePointer<Int32>!,
    _ n: UnsafeMutablePointer<Int32>!,
    _ alpha: UnsafeMutableRawPointer!,
    _ a: UnsafeMutableRawPointer!,
    _ lda: UnsafeMutablePointer<Int32>!,
    _ x: UnsafeMutableRawPointer!,
    _ incx: UnsafeMutablePointer<Int32>!,
    _ beta: UnsafeMutableRawPointer!,
    _ y: UnsafeMutableRawPointer!,
    _ incy: UnsafeMutablePointer<Int32>!
) -> Int32 {
    guard let trans, let m, let n, let alpha, let a, let lda, let x, let incx, let beta, let y, let incy else { return -1 }
    return _cgemv(
        trans: trans.pointee, m: Int(m.pointee), n: Int(n.pointee),
        alpha: _cplxLoad(alpha, 0) as _Cplx<Float>, a: a, lda: Int(lda.pointee),
        x: x, incx: Int(incx.pointee),
        beta: _cplxLoad(beta, 0) as _Cplx<Float>, y: y, incy: Int(incy.pointee)
    )
}

@discardableResult
public func cgeru_(
    _ m: UnsafeMutablePointer<Int32>!,
    _ n: UnsafeMutablePointer<Int32>!,
    _ alpha: UnsafeMutableRawPointer!,
    _ x: UnsafeMutableRawPointer!,
    _ incx: UnsafeMutablePointer<Int32>!,
    _ y: UnsafeMutableRawPointer!,
    _ incy: UnsafeMutablePointer<Int32>!,
    _ a: UnsafeMutableRawPointer!,
    _ lda: UnsafeMutablePointer<Int32>!
) -> Int32 {
    guard let m, let n, let alpha, let x, let incx, let y, let incy, let a, let lda else { return -1 }
    return _cger(
        m: Int(m.pointee), n: Int(n.pointee),
        alpha: _cplxLoad(alpha, 0) as _Cplx<Float>,
        x: x, incx: Int(incx.pointee), y: y, incy: Int(incy.pointee),
        a: a, lda: Int(lda.pointee), conjugateY: false
    )
}

@discardableResult
public func cgerc_(
    _ m: UnsafeMutablePointer<Int32>!,
    _ n: UnsafeMutablePointer<Int32>!,
    _ alpha: UnsafeMutableRawPointer!,
    _ x: UnsafeMutableRawPointer!,
    _ incx: UnsafeMutablePointer<Int32>!,
    _ y: UnsafeMutableRawPointer!,
    _ incy: UnsafeMutablePointer<Int32>!,
    _ a: UnsafeMutableRawPointer!,
    _ lda: UnsafeMutablePointer<Int32>!
) -> Int32 {
    guard let m, let n, let alpha, let x, let incx, let y, let incy, let a, let lda else { return -1 }
    return _cger(
        m: Int(m.pointee), n: Int(n.pointee),
        alpha: _cplxLoad(alpha, 0) as _Cplx<Float>,
        x: x, incx: Int(incx.pointee), y: y, incy: Int(incy.pointee),
        a: a, lda: Int(lda.pointee), conjugateY: true
    )
}

@discardableResult
public func chemv_(
    _ uplo: UnsafeMutablePointer<CChar>!,
    _ n: UnsafeMutablePointer<Int32>!,
    _ alpha: UnsafeMutableRawPointer!,
    _ a: UnsafeMutableRawPointer!,
    _ lda: UnsafeMutablePointer<Int32>!,
    _ x: UnsafeMutableRawPointer!,
    _ incx: UnsafeMutablePointer<Int32>!,
    _ beta: UnsafeMutableRawPointer!,
    _ y: UnsafeMutableRawPointer!,
    _ incy: UnsafeMutablePointer<Int32>!
) -> Int32 {
    guard let uplo, let n, let alpha, let a, let lda, let x, let incx, let beta, let y, let incy else { return -1 }
    return _chemv(
        uplo: uplo.pointee, n: Int(n.pointee),
        alpha: _cplxLoad(alpha, 0) as _Cplx<Float>, a: a, lda: Int(lda.pointee),
        x: x, incx: Int(incx.pointee),
        beta: _cplxLoad(beta, 0) as _Cplx<Float>, y: y, incy: Int(incy.pointee)
    )
}

@discardableResult
public func zaxpy_(
    _ n: UnsafeMutablePointer<Int32>!,
    _ ca: UnsafeMutableRawPointer!,
    _ cx: UnsafeMutableRawPointer!,
    _ incx: UnsafeMutablePointer<Int32>!,
    _ cy: UnsafeMutableRawPointer!,
    _ incy: UnsafeMutablePointer<Int32>!
) -> Int32 {
    guard let n, let ca, let cx, let incx, let cy, let incy else { return -1 }
    _caxpy(n: Int(n.pointee), alpha: _cplxLoad(ca, 0) as _Cplx<Double>, x: cx, incx: Int(incx.pointee), y: cy, incy: Int(incy.pointee))
    return 0
}

@discardableResult
public func zcopy_(
    _ n: UnsafeMutablePointer<Int32>!,
    _ cx: UnsafeMutableRawPointer!,
    _ incx: UnsafeMutablePointer<Int32>!,
    _ cy: UnsafeMutableRawPointer!,
    _ incy: UnsafeMutablePointer<Int32>!
) -> Int32 {
    guard let n, let cx, let incx, let cy, let incy else { return -1 }
    _ccopy(Double.self, n: Int(n.pointee), x: cx, incx: Int(incx.pointee), y: cy, incy: Int(incy.pointee))
    return 0
}

public func zdotc_(
    _ ret_val: UnsafeMutableRawPointer!,
    _ n: UnsafeMutablePointer<Int32>!,
    _ cx: UnsafeMutableRawPointer!,
    _ incx: UnsafeMutablePointer<Int32>!,
    _ cy: UnsafeMutableRawPointer!,
    _ incy: UnsafeMutablePointer<Int32>!
) {
    guard let ret_val, let n, let cx, let incx, let cy, let incy else { return }
    let sum: _Cplx<Double> = _cdot(n: Int(n.pointee), x: cx, incx: Int(incx.pointee), y: cy, incy: Int(incy.pointee), conjugateX: true)
    _cplxStore(ret_val, 0, sum)
}

public func zdotu_(
    _ ret_val: UnsafeMutableRawPointer!,
    _ n: UnsafeMutablePointer<Int32>!,
    _ cx: UnsafeMutableRawPointer!,
    _ incx: UnsafeMutablePointer<Int32>!,
    _ cy: UnsafeMutableRawPointer!,
    _ incy: UnsafeMutablePointer<Int32>!
) {
    guard let ret_val, let n, let cx, let incx, let cy, let incy else { return }
    let sum: _Cplx<Double> = _cdot(n: Int(n.pointee), x: cx, incx: Int(incx.pointee), y: cy, incy: Int(incy.pointee), conjugateX: false)
    _cplxStore(ret_val, 0, sum)
}

@discardableResult
public func zscal_(
    _ n: UnsafeMutablePointer<Int32>!,
    _ ca: UnsafeMutableRawPointer!,
    _ cx: UnsafeMutableRawPointer!,
    _ incx: UnsafeMutablePointer<Int32>!
) -> Int32 {
    guard let n, let ca, let cx, let incx else { return -1 }
    _cscal(n: Int(n.pointee), alpha: _cplxLoad(ca, 0) as _Cplx<Double>, x: cx, incx: Int(incx.pointee))
    return 0
}

@discardableResult
public func zdscal_(
    _ n: UnsafeMutablePointer<Int32>!,
    _ sa: UnsafeMutablePointer<Double>!,
    _ cx: UnsafeMutableRawPointer!,
    _ incx: UnsafeMutablePointer<Int32>!
) -> Int32 {
    guard let n, let sa, let cx, let incx else { return -1 }
    _csscal(n: Int(n.pointee), alpha: sa.pointee, x: cx, incx: Int(incx.pointee))
    return 0
}

@discardableResult
public func zswap_(
    _ n: UnsafeMutablePointer<Int32>!,
    _ cx: UnsafeMutableRawPointer!,
    _ incx: UnsafeMutablePointer<Int32>!,
    _ cy: UnsafeMutableRawPointer!,
    _ incy: UnsafeMutablePointer<Int32>!
) -> Int32 {
    guard let n, let cx, let incx, let cy, let incy else { return -1 }
    _cswap(Double.self, n: Int(n.pointee), x: cx, incx: Int(incx.pointee), y: cy, incy: Int(incy.pointee))
    return 0
}

@discardableResult
public func dzasum_(
    _ n: UnsafeMutablePointer<Int32>!,
    _ cx: UnsafeMutableRawPointer!,
    _ incx: UnsafeMutablePointer<Int32>!
) -> Double {
    guard let n, let cx, let incx else { return 0 }
    return _casum(n: Int(n.pointee), x: cx, incx: Int(incx.pointee)) as Double
}

@discardableResult
public func dznrm2_(
    _ n: UnsafeMutablePointer<Int32>!,
    _ cx: UnsafeMutableRawPointer!,
    _ incx: UnsafeMutablePointer<Int32>!
) -> Double {
    guard let n, let cx, let incx else { return 0 }
    return _cnrm2(n: Int(n.pointee), x: cx, incx: Int(incx.pointee)) as Double
}

@discardableResult
public func izamax_(
    _ n: UnsafeMutablePointer<Int32>!,
    _ cx: UnsafeMutableRawPointer!,
    _ incx: UnsafeMutablePointer<Int32>!
) -> Int32 {
    guard let n, let cx, let incx else { return 0 }
    return _icamax(Double.self, n: Int(n.pointee), x: cx, incx: Int(incx.pointee))
}

@discardableResult
public func zgemm_(
    _ transa: UnsafeMutablePointer<CChar>!,
    _ transb: UnsafeMutablePointer<CChar>!,
    _ m: UnsafeMutablePointer<Int32>!,
    _ n: UnsafeMutablePointer<Int32>!,
    _ k: UnsafeMutablePointer<Int32>!,
    _ alpha: UnsafeMutableRawPointer!,
    _ a: UnsafeMutableRawPointer!,
    _ lda: UnsafeMutablePointer<Int32>!,
    _ b: UnsafeMutableRawPointer!,
    _ ldb: UnsafeMutablePointer<Int32>!,
    _ beta: UnsafeMutableRawPointer!,
    _ c__: UnsafeMutableRawPointer!,
    _ ldc: UnsafeMutablePointer<Int32>!
) -> Int32 {
    guard let transa, let transb, let m, let n, let k, let alpha, let a, let lda, let b, let ldb, let beta, let c__, let ldc else { return -1 }
    return _cgemm(
        transA: transa.pointee, transB: transb.pointee,
        m: Int(m.pointee), n: Int(n.pointee), k: Int(k.pointee),
        alpha: _cplxLoad(alpha, 0) as _Cplx<Double>, a: a, lda: Int(lda.pointee),
        b: b, ldb: Int(ldb.pointee),
        beta: _cplxLoad(beta, 0) as _Cplx<Double>, c: c__, ldc: Int(ldc.pointee)
    )
}

@discardableResult
public func zgemv_(
    _ trans: UnsafeMutablePointer<CChar>!,
    _ m: UnsafeMutablePointer<Int32>!,
    _ n: UnsafeMutablePointer<Int32>!,
    _ alpha: UnsafeMutableRawPointer!,
    _ a: UnsafeMutableRawPointer!,
    _ lda: UnsafeMutablePointer<Int32>!,
    _ x: UnsafeMutableRawPointer!,
    _ incx: UnsafeMutablePointer<Int32>!,
    _ beta: UnsafeMutableRawPointer!,
    _ y: UnsafeMutableRawPointer!,
    _ incy: UnsafeMutablePointer<Int32>!
) -> Int32 {
    guard let trans, let m, let n, let alpha, let a, let lda, let x, let incx, let beta, let y, let incy else { return -1 }
    return _cgemv(
        trans: trans.pointee, m: Int(m.pointee), n: Int(n.pointee),
        alpha: _cplxLoad(alpha, 0) as _Cplx<Double>, a: a, lda: Int(lda.pointee),
        x: x, incx: Int(incx.pointee),
        beta: _cplxLoad(beta, 0) as _Cplx<Double>, y: y, incy: Int(incy.pointee)
    )
}

@discardableResult
public func zgeru_(
    _ m: UnsafeMutablePointer<Int32>!,
    _ n: UnsafeMutablePointer<Int32>!,
    _ alpha: UnsafeMutableRawPointer!,
    _ x: UnsafeMutableRawPointer!,
    _ incx: UnsafeMutablePointer<Int32>!,
    _ y: UnsafeMutableRawPointer!,
    _ incy: UnsafeMutablePointer<Int32>!,
    _ a: UnsafeMutableRawPointer!,
    _ lda: UnsafeMutablePointer<Int32>!
) -> Int32 {
    guard let m, let n, let alpha, let x, let incx, let y, let incy, let a, let lda else { return -1 }
    return _cger(
        m: Int(m.pointee), n: Int(n.pointee),
        alpha: _cplxLoad(alpha, 0) as _Cplx<Double>,
        x: x, incx: Int(incx.pointee), y: y, incy: Int(incy.pointee),
        a: a, lda: Int(lda.pointee), conjugateY: false
    )
}

@discardableResult
public func zgerc_(
    _ m: UnsafeMutablePointer<Int32>!,
    _ n: UnsafeMutablePointer<Int32>!,
    _ alpha: UnsafeMutableRawPointer!,
    _ x: UnsafeMutableRawPointer!,
    _ incx: UnsafeMutablePointer<Int32>!,
    _ y: UnsafeMutableRawPointer!,
    _ incy: UnsafeMutablePointer<Int32>!,
    _ a: UnsafeMutableRawPointer!,
    _ lda: UnsafeMutablePointer<Int32>!
) -> Int32 {
    guard let m, let n, let alpha, let x, let incx, let y, let incy, let a, let lda else { return -1 }
    return _cger(
        m: Int(m.pointee), n: Int(n.pointee),
        alpha: _cplxLoad(alpha, 0) as _Cplx<Double>,
        x: x, incx: Int(incx.pointee), y: y, incy: Int(incy.pointee),
        a: a, lda: Int(lda.pointee), conjugateY: true
    )
}

@discardableResult
public func zhemv_(
    _ uplo: UnsafeMutablePointer<CChar>!,
    _ n: UnsafeMutablePointer<Int32>!,
    _ alpha: UnsafeMutableRawPointer!,
    _ a: UnsafeMutableRawPointer!,
    _ lda: UnsafeMutablePointer<Int32>!,
    _ x: UnsafeMutableRawPointer!,
    _ incx: UnsafeMutablePointer<Int32>!,
    _ beta: UnsafeMutableRawPointer!,
    _ y: UnsafeMutableRawPointer!,
    _ incy: UnsafeMutablePointer<Int32>!
) -> Int32 {
    guard let uplo, let n, let alpha, let a, let lda, let x, let incx, let beta, let y, let incy else { return -1 }
    return _chemv(
        uplo: uplo.pointee, n: Int(n.pointee),
        alpha: _cplxLoad(alpha, 0) as _Cplx<Double>, a: a, lda: Int(lda.pointee),
        x: x, incx: Int(incx.pointee),
        beta: _cplxLoad(beta, 0) as _Cplx<Double>, y: y, incy: Int(incy.pointee)
    )
}

@discardableResult
public func ctrmv_(
    _ uplo: UnsafeMutablePointer<CChar>!,
    _ trans: UnsafeMutablePointer<CChar>!,
    _ diag: UnsafeMutablePointer<CChar>!,
    _ n: UnsafeMutablePointer<Int32>!,
    _ a: UnsafeMutableRawPointer!,
    _ lda: UnsafeMutablePointer<Int32>!,
    _ x: UnsafeMutableRawPointer!,
    _ incx: UnsafeMutablePointer<Int32>!
) -> Int32 {
    guard let uplo, let trans, let diag, let n, let a, let lda, let x, let incx else { return -1 }
    return _ctrmv(Float.self, uplo: uplo.pointee, trans: trans.pointee, diag: diag.pointee, n: Int(n.pointee), a: a, lda: Int(lda.pointee), x: x, incx: Int(incx.pointee))
}

@discardableResult
public func ctrsv_(
    _ uplo: UnsafeMutablePointer<CChar>!,
    _ trans: UnsafeMutablePointer<CChar>!,
    _ diag: UnsafeMutablePointer<CChar>!,
    _ n: UnsafeMutablePointer<Int32>!,
    _ a: UnsafeMutableRawPointer!,
    _ lda: UnsafeMutablePointer<Int32>!,
    _ x: UnsafeMutableRawPointer!,
    _ incx: UnsafeMutablePointer<Int32>!
) -> Int32 {
    guard let uplo, let trans, let diag, let n, let a, let lda, let x, let incx else { return -1 }
    return _ctrsv(Float.self, uplo: uplo.pointee, trans: trans.pointee, diag: diag.pointee, n: Int(n.pointee), a: a, lda: Int(lda.pointee), x: x, incx: Int(incx.pointee))
}

@discardableResult
public func ctrmm_(
    _ side: UnsafeMutablePointer<CChar>!,
    _ uplo: UnsafeMutablePointer<CChar>!,
    _ transa: UnsafeMutablePointer<CChar>!,
    _ diag: UnsafeMutablePointer<CChar>!,
    _ m: UnsafeMutablePointer<Int32>!,
    _ n: UnsafeMutablePointer<Int32>!,
    _ alpha: UnsafeMutableRawPointer!,
    _ a: UnsafeMutableRawPointer!,
    _ lda: UnsafeMutablePointer<Int32>!,
    _ b: UnsafeMutableRawPointer!,
    _ ldb: UnsafeMutablePointer<Int32>!
) -> Int32 {
    guard let side, let uplo, let transa, let diag, let m, let n, let alpha, let a, let lda, let b, let ldb else { return -1 }
    return _ctrmm(
        side: side.pointee, uplo: uplo.pointee, transa: transa.pointee, diag: diag.pointee,
        m: Int(m.pointee), n: Int(n.pointee), alpha: _cplxLoad(alpha, 0) as _Cplx<Float>,
        a: a, lda: Int(lda.pointee), b: b, ldb: Int(ldb.pointee)
    )
}

@discardableResult
public func ctrsm_(
    _ side: UnsafeMutablePointer<CChar>!,
    _ uplo: UnsafeMutablePointer<CChar>!,
    _ transa: UnsafeMutablePointer<CChar>!,
    _ diag: UnsafeMutablePointer<CChar>!,
    _ m: UnsafeMutablePointer<Int32>!,
    _ n: UnsafeMutablePointer<Int32>!,
    _ alpha: UnsafeMutableRawPointer!,
    _ a: UnsafeMutableRawPointer!,
    _ lda: UnsafeMutablePointer<Int32>!,
    _ b: UnsafeMutableRawPointer!,
    _ ldb: UnsafeMutablePointer<Int32>!
) -> Int32 {
    guard let side, let uplo, let transa, let diag, let m, let n, let alpha, let a, let lda, let b, let ldb else { return -1 }
    return _ctrsm(
        side: side.pointee, uplo: uplo.pointee, transa: transa.pointee, diag: diag.pointee,
        m: Int(m.pointee), n: Int(n.pointee), alpha: _cplxLoad(alpha, 0) as _Cplx<Float>,
        a: a, lda: Int(lda.pointee), b: b, ldb: Int(ldb.pointee)
    )
}

@discardableResult
public func chemm_(
    _ side: UnsafeMutablePointer<CChar>!,
    _ uplo: UnsafeMutablePointer<CChar>!,
    _ m: UnsafeMutablePointer<Int32>!,
    _ n: UnsafeMutablePointer<Int32>!,
    _ alpha: UnsafeMutableRawPointer!,
    _ a: UnsafeMutableRawPointer!,
    _ lda: UnsafeMutablePointer<Int32>!,
    _ b: UnsafeMutableRawPointer!,
    _ ldb: UnsafeMutablePointer<Int32>!,
    _ beta: UnsafeMutableRawPointer!,
    _ c__: UnsafeMutableRawPointer!,
    _ ldc: UnsafeMutablePointer<Int32>!
) -> Int32 {
    guard let side, let uplo, let m, let n, let alpha, let a, let lda, let b, let ldb, let beta, let c__, let ldc else { return -1 }
    return _chemm(
        side: side.pointee, uplo: uplo.pointee, m: Int(m.pointee), n: Int(n.pointee),
        alpha: _cplxLoad(alpha, 0) as _Cplx<Float>, a: a, lda: Int(lda.pointee),
        b: b, ldb: Int(ldb.pointee), beta: _cplxLoad(beta, 0) as _Cplx<Float>,
        c: c__, ldc: Int(ldc.pointee)
    )
}

@discardableResult
public func cher_(
    _ uplo: UnsafeMutablePointer<CChar>!,
    _ n: UnsafeMutablePointer<Int32>!,
    _ alpha: UnsafeMutablePointer<Float>!,
    _ x: UnsafeMutableRawPointer!,
    _ incx: UnsafeMutablePointer<Int32>!,
    _ a: UnsafeMutableRawPointer!,
    _ lda: UnsafeMutablePointer<Int32>!
) -> Int32 {
    guard let uplo, let n, let alpha, let x, let incx, let a, let lda else { return -1 }
    return _cher(uplo: uplo.pointee, n: Int(n.pointee), alpha: alpha.pointee, x: x, incx: Int(incx.pointee), a: a, lda: Int(lda.pointee))
}

@discardableResult
public func cherk_(
    _ uplo: UnsafeMutablePointer<CChar>!,
    _ trans: UnsafeMutablePointer<CChar>!,
    _ n: UnsafeMutablePointer<Int32>!,
    _ k: UnsafeMutablePointer<Int32>!,
    _ alpha: UnsafeMutablePointer<Float>!,
    _ a: UnsafeMutableRawPointer!,
    _ lda: UnsafeMutablePointer<Int32>!,
    _ beta: UnsafeMutablePointer<Float>!,
    _ c__: UnsafeMutableRawPointer!,
    _ ldc: UnsafeMutablePointer<Int32>!
) -> Int32 {
    guard let uplo, let trans, let n, let k, let alpha, let a, let lda, let beta, let c__, let ldc else { return -1 }
    return _cherk(
        uplo: uplo.pointee, trans: trans.pointee, n: Int(n.pointee), k: Int(k.pointee),
        alpha: alpha.pointee, a: a, lda: Int(lda.pointee), beta: beta.pointee, c: c__, ldc: Int(ldc.pointee)
    )
}

@discardableResult
public func cher2_(
    _ uplo: UnsafeMutablePointer<CChar>!,
    _ n: UnsafeMutablePointer<Int32>!,
    _ alpha: UnsafeMutableRawPointer!,
    _ x: UnsafeMutableRawPointer!,
    _ incx: UnsafeMutablePointer<Int32>!,
    _ y: UnsafeMutableRawPointer!,
    _ incy: UnsafeMutablePointer<Int32>!,
    _ a: UnsafeMutableRawPointer!,
    _ lda: UnsafeMutablePointer<Int32>!
) -> Int32 {
    guard let uplo, let n, let alpha, let x, let incx, let y, let incy, let a, let lda else { return -1 }
    return _cher2(
        uplo: uplo.pointee, n: Int(n.pointee), alpha: _cplxLoad(alpha, 0) as _Cplx<Float>,
        x: x, incx: Int(incx.pointee), y: y, incy: Int(incy.pointee), a: a, lda: Int(lda.pointee)
    )
}

@discardableResult
public func cher2k_(
    _ uplo: UnsafeMutablePointer<CChar>!,
    _ trans: UnsafeMutablePointer<CChar>!,
    _ n: UnsafeMutablePointer<Int32>!,
    _ k: UnsafeMutablePointer<Int32>!,
    _ alpha: UnsafeMutableRawPointer!,
    _ a: UnsafeMutableRawPointer!,
    _ lda: UnsafeMutablePointer<Int32>!,
    _ b: UnsafeMutableRawPointer!,
    _ ldb: UnsafeMutablePointer<Int32>!,
    _ beta: UnsafeMutablePointer<Float>!,
    _ c__: UnsafeMutableRawPointer!,
    _ ldc: UnsafeMutablePointer<Int32>!
) -> Int32 {
    guard let uplo, let trans, let n, let k, let alpha, let a, let lda, let b, let ldb, let beta, let c__, let ldc else { return -1 }
    return _cher2k(
        uplo: uplo.pointee, trans: trans.pointee, n: Int(n.pointee), k: Int(k.pointee),
        alpha: _cplxLoad(alpha, 0) as _Cplx<Float>, a: a, lda: Int(lda.pointee),
        b: b, ldb: Int(ldb.pointee), beta: beta.pointee, c: c__, ldc: Int(ldc.pointee)
    )
}

@discardableResult
public func csymm_(
    _ side: UnsafeMutablePointer<CChar>!,
    _ uplo: UnsafeMutablePointer<CChar>!,
    _ m: UnsafeMutablePointer<Int32>!,
    _ n: UnsafeMutablePointer<Int32>!,
    _ alpha: UnsafeMutableRawPointer!,
    _ a: UnsafeMutableRawPointer!,
    _ lda: UnsafeMutablePointer<Int32>!,
    _ b: UnsafeMutableRawPointer!,
    _ ldb: UnsafeMutablePointer<Int32>!,
    _ beta: UnsafeMutableRawPointer!,
    _ c__: UnsafeMutableRawPointer!,
    _ ldc: UnsafeMutablePointer<Int32>!
) -> Int32 {
    guard let side, let uplo, let m, let n, let alpha, let a, let lda, let b, let ldb, let beta, let c__, let ldc else { return -1 }
    return _csymm(
        side: side.pointee, uplo: uplo.pointee, m: Int(m.pointee), n: Int(n.pointee),
        alpha: _cplxLoad(alpha, 0) as _Cplx<Float>, a: a, lda: Int(lda.pointee),
        b: b, ldb: Int(ldb.pointee), beta: _cplxLoad(beta, 0) as _Cplx<Float>,
        c: c__, ldc: Int(ldc.pointee)
    )
}

@discardableResult
public func csyrk_(
    _ uplo: UnsafeMutablePointer<CChar>!,
    _ trans: UnsafeMutablePointer<CChar>!,
    _ n: UnsafeMutablePointer<Int32>!,
    _ k: UnsafeMutablePointer<Int32>!,
    _ alpha: UnsafeMutableRawPointer!,
    _ a: UnsafeMutableRawPointer!,
    _ lda: UnsafeMutablePointer<Int32>!,
    _ beta: UnsafeMutableRawPointer!,
    _ c__: UnsafeMutableRawPointer!,
    _ ldc: UnsafeMutablePointer<Int32>!
) -> Int32 {
    guard let uplo, let trans, let n, let k, let alpha, let a, let lda, let beta, let c__, let ldc else { return -1 }
    return _csyrk(
        uplo: uplo.pointee, trans: trans.pointee, n: Int(n.pointee), k: Int(k.pointee),
        alpha: _cplxLoad(alpha, 0) as _Cplx<Float>, a: a, lda: Int(lda.pointee),
        beta: _cplxLoad(beta, 0) as _Cplx<Float>, c: c__, ldc: Int(ldc.pointee)
    )
}

@discardableResult
public func csyr2k_(
    _ uplo: UnsafeMutablePointer<CChar>!,
    _ trans: UnsafeMutablePointer<CChar>!,
    _ n: UnsafeMutablePointer<Int32>!,
    _ k: UnsafeMutablePointer<Int32>!,
    _ alpha: UnsafeMutableRawPointer!,
    _ a: UnsafeMutableRawPointer!,
    _ lda: UnsafeMutablePointer<Int32>!,
    _ b: UnsafeMutableRawPointer!,
    _ ldb: UnsafeMutablePointer<Int32>!,
    _ beta: UnsafeMutableRawPointer!,
    _ c__: UnsafeMutableRawPointer!,
    _ ldc: UnsafeMutablePointer<Int32>!
) -> Int32 {
    guard let uplo, let trans, let n, let k, let alpha, let a, let lda, let b, let ldb, let beta, let c__, let ldc else { return -1 }
    return _csyr2k(
        uplo: uplo.pointee, trans: trans.pointee, n: Int(n.pointee), k: Int(k.pointee),
        alpha: _cplxLoad(alpha, 0) as _Cplx<Float>, a: a, lda: Int(lda.pointee),
        b: b, ldb: Int(ldb.pointee), beta: _cplxLoad(beta, 0) as _Cplx<Float>,
        c: c__, ldc: Int(ldc.pointee)
    )
}

@discardableResult
public func crotg_(
    _ ca: UnsafeMutableRawPointer!,
    _ cb: UnsafeMutableRawPointer!,
    _ c: UnsafeMutablePointer<Float>!,
    _ cs: UnsafeMutableRawPointer!
) -> Int32 {
    guard let ca, let cb, let c, let cs else { return -1 }
    return _crotg(ca: ca, cb: cb, c: c, s: cs)
}

@discardableResult
public func csrot_(
    _ n: UnsafeMutablePointer<Int32>!,
    _ cx: UnsafeMutableRawPointer!,
    _ incx: UnsafeMutablePointer<Int32>!,
    _ cy: UnsafeMutableRawPointer!,
    _ incy: UnsafeMutablePointer<Int32>!,
    _ c: UnsafeMutablePointer<Float>!,
    _ s: UnsafeMutablePointer<Float>!
) -> Int32 {
    guard let n, let cx, let incx, let cy, let incy, let c, let s else { return -1 }
    return _csrot(n: Int(n.pointee), x: cx, incx: Int(incx.pointee), y: cy, incy: Int(incy.pointee), c: c.pointee, s: s.pointee)
}

@discardableResult
public func ztrmv_(
    _ uplo: UnsafeMutablePointer<CChar>!,
    _ trans: UnsafeMutablePointer<CChar>!,
    _ diag: UnsafeMutablePointer<CChar>!,
    _ n: UnsafeMutablePointer<Int32>!,
    _ a: UnsafeMutableRawPointer!,
    _ lda: UnsafeMutablePointer<Int32>!,
    _ x: UnsafeMutableRawPointer!,
    _ incx: UnsafeMutablePointer<Int32>!
) -> Int32 {
    guard let uplo, let trans, let diag, let n, let a, let lda, let x, let incx else { return -1 }
    return _ctrmv(Double.self, uplo: uplo.pointee, trans: trans.pointee, diag: diag.pointee, n: Int(n.pointee), a: a, lda: Int(lda.pointee), x: x, incx: Int(incx.pointee))
}

@discardableResult
public func ztrsv_(
    _ uplo: UnsafeMutablePointer<CChar>!,
    _ trans: UnsafeMutablePointer<CChar>!,
    _ diag: UnsafeMutablePointer<CChar>!,
    _ n: UnsafeMutablePointer<Int32>!,
    _ a: UnsafeMutableRawPointer!,
    _ lda: UnsafeMutablePointer<Int32>!,
    _ x: UnsafeMutableRawPointer!,
    _ incx: UnsafeMutablePointer<Int32>!
) -> Int32 {
    guard let uplo, let trans, let diag, let n, let a, let lda, let x, let incx else { return -1 }
    return _ctrsv(Double.self, uplo: uplo.pointee, trans: trans.pointee, diag: diag.pointee, n: Int(n.pointee), a: a, lda: Int(lda.pointee), x: x, incx: Int(incx.pointee))
}

@discardableResult
public func ztrmm_(
    _ side: UnsafeMutablePointer<CChar>!,
    _ uplo: UnsafeMutablePointer<CChar>!,
    _ transa: UnsafeMutablePointer<CChar>!,
    _ diag: UnsafeMutablePointer<CChar>!,
    _ m: UnsafeMutablePointer<Int32>!,
    _ n: UnsafeMutablePointer<Int32>!,
    _ alpha: UnsafeMutableRawPointer!,
    _ a: UnsafeMutableRawPointer!,
    _ lda: UnsafeMutablePointer<Int32>!,
    _ b: UnsafeMutableRawPointer!,
    _ ldb: UnsafeMutablePointer<Int32>!
) -> Int32 {
    guard let side, let uplo, let transa, let diag, let m, let n, let alpha, let a, let lda, let b, let ldb else { return -1 }
    return _ctrmm(
        side: side.pointee, uplo: uplo.pointee, transa: transa.pointee, diag: diag.pointee,
        m: Int(m.pointee), n: Int(n.pointee), alpha: _cplxLoad(alpha, 0) as _Cplx<Double>,
        a: a, lda: Int(lda.pointee), b: b, ldb: Int(ldb.pointee)
    )
}

@discardableResult
public func ztrsm_(
    _ side: UnsafeMutablePointer<CChar>!,
    _ uplo: UnsafeMutablePointer<CChar>!,
    _ transa: UnsafeMutablePointer<CChar>!,
    _ diag: UnsafeMutablePointer<CChar>!,
    _ m: UnsafeMutablePointer<Int32>!,
    _ n: UnsafeMutablePointer<Int32>!,
    _ alpha: UnsafeMutableRawPointer!,
    _ a: UnsafeMutableRawPointer!,
    _ lda: UnsafeMutablePointer<Int32>!,
    _ b: UnsafeMutableRawPointer!,
    _ ldb: UnsafeMutablePointer<Int32>!
) -> Int32 {
    guard let side, let uplo, let transa, let diag, let m, let n, let alpha, let a, let lda, let b, let ldb else { return -1 }
    return _ctrsm(
        side: side.pointee, uplo: uplo.pointee, transa: transa.pointee, diag: diag.pointee,
        m: Int(m.pointee), n: Int(n.pointee), alpha: _cplxLoad(alpha, 0) as _Cplx<Double>,
        a: a, lda: Int(lda.pointee), b: b, ldb: Int(ldb.pointee)
    )
}

@discardableResult
public func zhemm_(
    _ side: UnsafeMutablePointer<CChar>!,
    _ uplo: UnsafeMutablePointer<CChar>!,
    _ m: UnsafeMutablePointer<Int32>!,
    _ n: UnsafeMutablePointer<Int32>!,
    _ alpha: UnsafeMutableRawPointer!,
    _ a: UnsafeMutableRawPointer!,
    _ lda: UnsafeMutablePointer<Int32>!,
    _ b: UnsafeMutableRawPointer!,
    _ ldb: UnsafeMutablePointer<Int32>!,
    _ beta: UnsafeMutableRawPointer!,
    _ c__: UnsafeMutableRawPointer!,
    _ ldc: UnsafeMutablePointer<Int32>!
) -> Int32 {
    guard let side, let uplo, let m, let n, let alpha, let a, let lda, let b, let ldb, let beta, let c__, let ldc else { return -1 }
    return _chemm(
        side: side.pointee, uplo: uplo.pointee, m: Int(m.pointee), n: Int(n.pointee),
        alpha: _cplxLoad(alpha, 0) as _Cplx<Double>, a: a, lda: Int(lda.pointee),
        b: b, ldb: Int(ldb.pointee), beta: _cplxLoad(beta, 0) as _Cplx<Double>,
        c: c__, ldc: Int(ldc.pointee)
    )
}

@discardableResult
public func zher_(
    _ uplo: UnsafeMutablePointer<CChar>!,
    _ n: UnsafeMutablePointer<Int32>!,
    _ alpha: UnsafeMutablePointer<Double>!,
    _ x: UnsafeMutableRawPointer!,
    _ incx: UnsafeMutablePointer<Int32>!,
    _ a: UnsafeMutableRawPointer!,
    _ lda: UnsafeMutablePointer<Int32>!
) -> Int32 {
    guard let uplo, let n, let alpha, let x, let incx, let a, let lda else { return -1 }
    return _cher(uplo: uplo.pointee, n: Int(n.pointee), alpha: alpha.pointee, x: x, incx: Int(incx.pointee), a: a, lda: Int(lda.pointee))
}

@discardableResult
public func zherk_(
    _ uplo: UnsafeMutablePointer<CChar>!,
    _ trans: UnsafeMutablePointer<CChar>!,
    _ n: UnsafeMutablePointer<Int32>!,
    _ k: UnsafeMutablePointer<Int32>!,
    _ alpha: UnsafeMutablePointer<Double>!,
    _ a: UnsafeMutableRawPointer!,
    _ lda: UnsafeMutablePointer<Int32>!,
    _ beta: UnsafeMutablePointer<Double>!,
    _ c__: UnsafeMutableRawPointer!,
    _ ldc: UnsafeMutablePointer<Int32>!
) -> Int32 {
    guard let uplo, let trans, let n, let k, let alpha, let a, let lda, let beta, let c__, let ldc else { return -1 }
    return _cherk(
        uplo: uplo.pointee, trans: trans.pointee, n: Int(n.pointee), k: Int(k.pointee),
        alpha: alpha.pointee, a: a, lda: Int(lda.pointee), beta: beta.pointee, c: c__, ldc: Int(ldc.pointee)
    )
}

@discardableResult
public func zher2_(
    _ uplo: UnsafeMutablePointer<CChar>!,
    _ n: UnsafeMutablePointer<Int32>!,
    _ alpha: UnsafeMutableRawPointer!,
    _ x: UnsafeMutableRawPointer!,
    _ incx: UnsafeMutablePointer<Int32>!,
    _ y: UnsafeMutableRawPointer!,
    _ incy: UnsafeMutablePointer<Int32>!,
    _ a: UnsafeMutableRawPointer!,
    _ lda: UnsafeMutablePointer<Int32>!
) -> Int32 {
    guard let uplo, let n, let alpha, let x, let incx, let y, let incy, let a, let lda else { return -1 }
    return _cher2(
        uplo: uplo.pointee, n: Int(n.pointee), alpha: _cplxLoad(alpha, 0) as _Cplx<Double>,
        x: x, incx: Int(incx.pointee), y: y, incy: Int(incy.pointee), a: a, lda: Int(lda.pointee)
    )
}

@discardableResult
public func zher2k_(
    _ uplo: UnsafeMutablePointer<CChar>!,
    _ trans: UnsafeMutablePointer<CChar>!,
    _ n: UnsafeMutablePointer<Int32>!,
    _ k: UnsafeMutablePointer<Int32>!,
    _ alpha: UnsafeMutableRawPointer!,
    _ a: UnsafeMutableRawPointer!,
    _ lda: UnsafeMutablePointer<Int32>!,
    _ b: UnsafeMutableRawPointer!,
    _ ldb: UnsafeMutablePointer<Int32>!,
    _ beta: UnsafeMutablePointer<Double>!,
    _ c__: UnsafeMutableRawPointer!,
    _ ldc: UnsafeMutablePointer<Int32>!
) -> Int32 {
    guard let uplo, let trans, let n, let k, let alpha, let a, let lda, let b, let ldb, let beta, let c__, let ldc else { return -1 }
    return _cher2k(
        uplo: uplo.pointee, trans: trans.pointee, n: Int(n.pointee), k: Int(k.pointee),
        alpha: _cplxLoad(alpha, 0) as _Cplx<Double>, a: a, lda: Int(lda.pointee),
        b: b, ldb: Int(ldb.pointee), beta: beta.pointee, c: c__, ldc: Int(ldc.pointee)
    )
}

@discardableResult
public func zsymm_(
    _ side: UnsafeMutablePointer<CChar>!,
    _ uplo: UnsafeMutablePointer<CChar>!,
    _ m: UnsafeMutablePointer<Int32>!,
    _ n: UnsafeMutablePointer<Int32>!,
    _ alpha: UnsafeMutableRawPointer!,
    _ a: UnsafeMutableRawPointer!,
    _ lda: UnsafeMutablePointer<Int32>!,
    _ b: UnsafeMutableRawPointer!,
    _ ldb: UnsafeMutablePointer<Int32>!,
    _ beta: UnsafeMutableRawPointer!,
    _ c__: UnsafeMutableRawPointer!,
    _ ldc: UnsafeMutablePointer<Int32>!
) -> Int32 {
    guard let side, let uplo, let m, let n, let alpha, let a, let lda, let b, let ldb, let beta, let c__, let ldc else { return -1 }
    return _csymm(
        side: side.pointee, uplo: uplo.pointee, m: Int(m.pointee), n: Int(n.pointee),
        alpha: _cplxLoad(alpha, 0) as _Cplx<Double>, a: a, lda: Int(lda.pointee),
        b: b, ldb: Int(ldb.pointee), beta: _cplxLoad(beta, 0) as _Cplx<Double>,
        c: c__, ldc: Int(ldc.pointee)
    )
}

@discardableResult
public func zsyrk_(
    _ uplo: UnsafeMutablePointer<CChar>!,
    _ trans: UnsafeMutablePointer<CChar>!,
    _ n: UnsafeMutablePointer<Int32>!,
    _ k: UnsafeMutablePointer<Int32>!,
    _ alpha: UnsafeMutableRawPointer!,
    _ a: UnsafeMutableRawPointer!,
    _ lda: UnsafeMutablePointer<Int32>!,
    _ beta: UnsafeMutableRawPointer!,
    _ c__: UnsafeMutableRawPointer!,
    _ ldc: UnsafeMutablePointer<Int32>!
) -> Int32 {
    guard let uplo, let trans, let n, let k, let alpha, let a, let lda, let beta, let c__, let ldc else { return -1 }
    return _csyrk(
        uplo: uplo.pointee, trans: trans.pointee, n: Int(n.pointee), k: Int(k.pointee),
        alpha: _cplxLoad(alpha, 0) as _Cplx<Double>, a: a, lda: Int(lda.pointee),
        beta: _cplxLoad(beta, 0) as _Cplx<Double>, c: c__, ldc: Int(ldc.pointee)
    )
}

@discardableResult
public func zsyr2k_(
    _ uplo: UnsafeMutablePointer<CChar>!,
    _ trans: UnsafeMutablePointer<CChar>!,
    _ n: UnsafeMutablePointer<Int32>!,
    _ k: UnsafeMutablePointer<Int32>!,
    _ alpha: UnsafeMutableRawPointer!,
    _ a: UnsafeMutableRawPointer!,
    _ lda: UnsafeMutablePointer<Int32>!,
    _ b: UnsafeMutableRawPointer!,
    _ ldb: UnsafeMutablePointer<Int32>!,
    _ beta: UnsafeMutableRawPointer!,
    _ c__: UnsafeMutableRawPointer!,
    _ ldc: UnsafeMutablePointer<Int32>!
) -> Int32 {
    guard let uplo, let trans, let n, let k, let alpha, let a, let lda, let b, let ldb, let beta, let c__, let ldc else { return -1 }
    return _csyr2k(
        uplo: uplo.pointee, trans: trans.pointee, n: Int(n.pointee), k: Int(k.pointee),
        alpha: _cplxLoad(alpha, 0) as _Cplx<Double>, a: a, lda: Int(lda.pointee),
        b: b, ldb: Int(ldb.pointee), beta: _cplxLoad(beta, 0) as _Cplx<Double>,
        c: c__, ldc: Int(ldc.pointee)
    )
}

@discardableResult
public func zrotg_(
    _ ca: UnsafeMutableRawPointer!,
    _ cb: UnsafeMutableRawPointer!,
    _ c: UnsafeMutablePointer<Double>!,
    _ cs: UnsafeMutableRawPointer!
) -> Int32 {
    guard let ca, let cb, let c, let cs else { return -1 }
    return _crotg(ca: ca, cb: cb, c: c, s: cs)
}

@discardableResult
public func zdrot_(
    _ n: UnsafeMutablePointer<Int32>!,
    _ cx: UnsafeMutableRawPointer!,
    _ incx: UnsafeMutablePointer<Int32>!,
    _ cy: UnsafeMutableRawPointer!,
    _ incy: UnsafeMutablePointer<Int32>!,
    _ c: UnsafeMutablePointer<Double>!,
    _ s: UnsafeMutablePointer<Double>!
) -> Int32 {
    guard let n, let cx, let incx, let cy, let incy, let c, let s else { return -1 }
    return _csrot(n: Int(n.pointee), x: cx, incx: Int(incx.pointee), y: cy, incy: Int(incy.pointee), c: c.pointee, s: s.pointee)
}
