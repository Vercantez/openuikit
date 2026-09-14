import Foundation

func _packIndex(upper: Bool, n: Int, row: Int, col: Int) -> Int {
    if upper {
        return row + col * (col + 1) / 2
    }
    return row + col * (2 * n - col - 1) / 2
}

func _packedHermitianElem<T: BinaryFloatingPoint>(
    _ ap: UnsafeRawPointer,
    i: Int,
    j: Int,
    n: Int,
    upper: Bool
) -> _Cplx<T> {
    if i == j {
        let v: _Cplx<T> = _cplxLoad(ap, _packIndex(upper: upper, n: n, row: i, col: j))
        return _Cplx(re: v.re, im: 0)
    }
    if upper {
        if i <= j { return _cplxLoad(ap, _packIndex(upper: true, n: n, row: i, col: j)) }
        return _cplxLoad(ap, _packIndex(upper: true, n: n, row: j, col: i)).conjugate()
    }
    if i >= j { return _cplxLoad(ap, _packIndex(upper: false, n: n, row: i, col: j)) }
    return _cplxLoad(ap, _packIndex(upper: false, n: n, row: j, col: i)).conjugate()
}

func _packedTriOpA<T: BinaryFloatingPoint>(
    _ ap: UnsafeRawPointer,
    row: Int,
    col: Int,
    n: Int,
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
    var v: _Cplx<T> = _cplxLoad(ap, _packIndex(upper: upper, n: n, row: r, col: c))
    if doConj { v = v.conjugate() }
    return v
}

func _bandLoad<T: BinaryFloatingPoint>(
    _ a: UnsafeRawPointer,
    i: Int,
    j: Int,
    m: Int,
    n: Int,
    kl: Int,
    ku: Int,
    lda: Int
) -> _Cplx<T> {
    if i < 0 || j < 0 || i >= m || j >= n { return .zero }
    if i < j - ku || i > j + kl { return .zero }
    let row = ku + i - j
    if row < 0 || row >= lda { return .zero }
    return _cplxLoad(a, j * lda + row)
}

func _hbandElem<T: BinaryFloatingPoint>(
    _ a: UnsafeRawPointer,
    i: Int,
    j: Int,
    k: Int,
    lda: Int,
    upper: Bool
) -> _Cplx<T> {
    let lo = min(i, j)
    let hi = max(i, j)
    if hi - lo > k { return .zero }
    if i == j {
        let row = upper ? k : 0
        let v: _Cplx<T> = _cplxLoad(a, j * lda + row)
        return _Cplx(re: v.re, im: 0)
    }
    if upper {
        if i <= j { return _cplxLoad(a, j * lda + (k + i - j)) }
        return _cplxLoad(a, i * lda + (k + j - i)).conjugate()
    }
    if i >= j { return _cplxLoad(a, j * lda + (i - j)) }
    return _cplxLoad(a, i * lda + (j - i)).conjugate()
}

func _tbandOpA<T: BinaryFloatingPoint>(
    _ a: UnsafeRawPointer,
    row: Int,
    col: Int,
    k: Int,
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
    if abs(r - c) > k { return .zero }
    let bandRow = upper ? (k + r - c) : (r - c)
    if bandRow < 0 || bandRow >= lda { return .zero }
    var v: _Cplx<T> = _cplxLoad(a, c * lda + bandRow)
    if doConj { v = v.conjugate() }
    return v
}

func _chpmv<T: BinaryFloatingPoint>(
    uplo: CChar,
    n: Int,
    alpha: _Cplx<T>,
    ap: UnsafeRawPointer,
    x: UnsafeRawPointer,
    incx: Int,
    beta: _Cplx<T>,
    y: UnsafeMutableRawPointer,
    incy: Int
) -> Int32 {
    guard n > 0, incx != 0, incy != 0 else { return 0 }
    let upper = _isUpper(uplo)
    var yi = 0
    for i in 0..<n {
        var sum = _Cplx<T>.zero
        var xj = 0
        for j in 0..<n {
            let aij: _Cplx<T> = _packedHermitianElem(ap, i: i, j: j, n: n, upper: upper)
            sum = sum + aij * _cplxLoad(x, xj)
            xj += incx
        }
        let yv: _Cplx<T> = _cplxLoad(y, yi)
        _cplxStore(y, yi, alpha * sum + beta * yv)
        yi += incy
    }
    return 0
}

func _chpr<T: BinaryFloatingPoint>(
    uplo: CChar,
    n: Int,
    alpha: T,
    x: UnsafeRawPointer,
    incx: Int,
    ap: UnsafeMutableRawPointer
) -> Int32 {
    guard n > 0, incx != 0 else { return 0 }
    let upper = _isUpper(uplo)
    for j in 0..<n {
        let xj: _Cplx<T> = _cplxLoad(x, j * incx)
        let xjH = xj.conjugate()
        let iStart = upper ? 0 : j
        let iEnd = upper ? j : n - 1
        var i = iStart
        while i <= iEnd {
            let xi: _Cplx<T> = _cplxLoad(x, i * incx)
            let idx = _packIndex(upper: upper, n: n, row: i, col: j)
            var av: _Cplx<T> = _cplxLoad(ap, idx)
            av = av + (xi * xjH).scaled(alpha)
            if i == j { av.im = 0 }
            _cplxStore(ap, idx, av)
            i += 1
        }
    }
    return 0
}

func _chpr2<T: BinaryFloatingPoint>(
    uplo: CChar,
    n: Int,
    alpha: _Cplx<T>,
    x: UnsafeRawPointer,
    incx: Int,
    y: UnsafeRawPointer,
    incy: Int,
    ap: UnsafeMutableRawPointer
) -> Int32 {
    guard n > 0, incx != 0, incy != 0 else { return 0 }
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
            let idx = _packIndex(upper: upper, n: n, row: i, col: j)
            var av: _Cplx<T> = _cplxLoad(ap, idx)
            av = av + alpha * xi * yj.conjugate() + alphaC * yi * xj.conjugate()
            if i == j { av.im = 0 }
            _cplxStore(ap, idx, av)
            i += 1
        }
    }
    return 0
}

func _ctpmv<T: BinaryFloatingPoint>(
    _: T.Type,
    uplo: CChar,
    trans: CChar,
    diag: CChar,
    n: Int,
    ap: UnsafeRawPointer,
    x: UnsafeMutableRawPointer,
    incx: Int
) -> Int32 {
    guard n > 0, incx != 0 else { return 0 }
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
            sum = sum + _packedTriOpA(ap, row: i, col: j, n: n, upper: upper, unit: unit, doTrans: doTrans, doConj: doConj) * y[j]
        }
        out[i] = sum
    }
    for i in 0..<n { _cplxStore(x, i * incx, out[i]) }
    return 0
}

func _ctpsv<T: BinaryFloatingPoint>(
    _: T.Type,
    uplo: CChar,
    trans: CChar,
    diag: CChar,
    n: Int,
    ap: UnsafeRawPointer,
    x: UnsafeMutableRawPointer,
    incx: Int
) -> Int32 {
    guard n > 0, incx != 0 else { return 0 }
    let upper = _isUpper(uplo)
    let unit = _isUnitDiag(diag)
    let doTrans = _isTrans(trans) || _isConjTrans(trans)
    let doConj = _isConjTrans(trans)
    var y = [_Cplx<T>](repeating: .zero, count: n)
    for i in 0..<n { y[i] = _cplxLoad(x, i * incx) }
    func opA(_ row: Int, _ col: Int) -> _Cplx<T> {
        _packedTriOpA(ap, row: row, col: col, n: n, upper: upper, unit: unit, doTrans: doTrans, doConj: doConj)
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

func _cgbmv<T: BinaryFloatingPoint>(
    trans: CChar,
    m: Int,
    n: Int,
    kl: Int,
    ku: Int,
    alpha: _Cplx<T>,
    a: UnsafeRawPointer,
    lda: Int,
    x: UnsafeRawPointer,
    incx: Int,
    beta: _Cplx<T>,
    y: UnsafeMutableRawPointer,
    incy: Int
) -> Int32 {
    guard m > 0, n > 0, kl >= 0, ku >= 0, lda > 0, incx != 0, incy != 0 else { return 0 }
    let doTrans = _isTrans(trans) || _isConjTrans(trans)
    let doConj = _isConjTrans(trans)
    let outCount = doTrans ? n : m
    let inner = doTrans ? m : n
    var yi = 0
    for i in 0..<outCount {
        var sum = _Cplx<T>.zero
        var xi = 0
        for p in 0..<inner {
            let av: _Cplx<T>
            if doTrans {
                av = _bandLoad(a, i: p, j: i, m: m, n: n, kl: kl, ku: ku, lda: lda)
            } else {
                av = _bandLoad(a, i: i, j: p, m: m, n: n, kl: kl, ku: ku, lda: lda)
            }
            let stored = doConj ? av.conjugate() : av
            sum = sum + stored * _cplxLoad(x, xi)
            xi += incx
        }
        let yv: _Cplx<T> = _cplxLoad(y, yi)
        _cplxStore(y, yi, alpha * sum + beta * yv)
        yi += incy
    }
    return 0
}

func _chbmv<T: BinaryFloatingPoint>(
    uplo: CChar,
    n: Int,
    k: Int,
    alpha: _Cplx<T>,
    a: UnsafeRawPointer,
    lda: Int,
    x: UnsafeRawPointer,
    incx: Int,
    beta: _Cplx<T>,
    y: UnsafeMutableRawPointer,
    incy: Int
) -> Int32 {
    guard n > 0, k >= 0, lda > 0, incx != 0, incy != 0 else { return 0 }
    let upper = _isUpper(uplo)
    var yi = 0
    for i in 0..<n {
        var sum = _Cplx<T>.zero
        var xj = 0
        for j in 0..<n {
            let aij: _Cplx<T> = _hbandElem(a, i: i, j: j, k: k, lda: lda, upper: upper)
            sum = sum + aij * _cplxLoad(x, xj)
            xj += incx
        }
        let yv: _Cplx<T> = _cplxLoad(y, yi)
        _cplxStore(y, yi, alpha * sum + beta * yv)
        yi += incy
    }
    return 0
}

func _ctbmv<T: BinaryFloatingPoint>(
    _: T.Type,
    uplo: CChar,
    trans: CChar,
    diag: CChar,
    n: Int,
    k: Int,
    a: UnsafeRawPointer,
    lda: Int,
    x: UnsafeMutableRawPointer,
    incx: Int
) -> Int32 {
    guard n > 0, k >= 0, lda > 0, incx != 0 else { return 0 }
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
            sum = sum + _tbandOpA(a, row: i, col: j, k: k, lda: lda, upper: upper, unit: unit, doTrans: doTrans, doConj: doConj) * y[j]
        }
        out[i] = sum
    }
    for i in 0..<n { _cplxStore(x, i * incx, out[i]) }
    return 0
}

func _ctbsv<T: BinaryFloatingPoint>(
    _: T.Type,
    uplo: CChar,
    trans: CChar,
    diag: CChar,
    n: Int,
    k: Int,
    a: UnsafeRawPointer,
    lda: Int,
    x: UnsafeMutableRawPointer,
    incx: Int
) -> Int32 {
    guard n > 0, k >= 0, lda > 0, incx != 0 else { return 0 }
    let upper = _isUpper(uplo)
    let unit = _isUnitDiag(diag)
    let doTrans = _isTrans(trans) || _isConjTrans(trans)
    let doConj = _isConjTrans(trans)
    var y = [_Cplx<T>](repeating: .zero, count: n)
    for i in 0..<n { y[i] = _cplxLoad(x, i * incx) }
    func opA(_ row: Int, _ col: Int) -> _Cplx<T> {
        _tbandOpA(a, row: row, col: col, k: k, lda: lda, upper: upper, unit: unit, doTrans: doTrans, doConj: doConj)
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

@discardableResult
public func chpmv_(
    _ uplo: UnsafeMutablePointer<CChar>!,
    _ n: UnsafeMutablePointer<Int32>!,
    _ alpha: UnsafeMutableRawPointer!,
    _ ap: UnsafeMutableRawPointer!,
    _ x: UnsafeMutableRawPointer!,
    _ incx: UnsafeMutablePointer<Int32>!,
    _ beta: UnsafeMutableRawPointer!,
    _ y: UnsafeMutableRawPointer!,
    _ incy: UnsafeMutablePointer<Int32>!
) -> Int32 {
    guard let uplo, let n, let alpha, let ap, let x, let incx, let beta, let y, let incy else { return -1 }
    return _chpmv(
        uplo: uplo.pointee, n: Int(n.pointee),
        alpha: _cplxLoad(alpha, 0) as _Cplx<Float>, ap: ap,
        x: x, incx: Int(incx.pointee),
        beta: _cplxLoad(beta, 0) as _Cplx<Float>, y: y, incy: Int(incy.pointee)
    )
}

@discardableResult
public func chpr_(
    _ uplo: UnsafeMutablePointer<CChar>!,
    _ n: UnsafeMutablePointer<Int32>!,
    _ alpha: UnsafeMutablePointer<Float>!,
    _ x: UnsafeMutableRawPointer!,
    _ incx: UnsafeMutablePointer<Int32>!,
    _ ap: UnsafeMutableRawPointer!
) -> Int32 {
    guard let uplo, let n, let alpha, let x, let incx, let ap else { return -1 }
    return _chpr(uplo: uplo.pointee, n: Int(n.pointee), alpha: alpha.pointee, x: x, incx: Int(incx.pointee), ap: ap)
}

@discardableResult
public func chpr2_(
    _ uplo: UnsafeMutablePointer<CChar>!,
    _ n: UnsafeMutablePointer<Int32>!,
    _ alpha: UnsafeMutableRawPointer!,
    _ x: UnsafeMutableRawPointer!,
    _ incx: UnsafeMutablePointer<Int32>!,
    _ y: UnsafeMutableRawPointer!,
    _ incy: UnsafeMutablePointer<Int32>!,
    _ ap: UnsafeMutableRawPointer!
) -> Int32 {
    guard let uplo, let n, let alpha, let x, let incx, let y, let incy, let ap else { return -1 }
    return _chpr2(
        uplo: uplo.pointee, n: Int(n.pointee), alpha: _cplxLoad(alpha, 0) as _Cplx<Float>,
        x: x, incx: Int(incx.pointee), y: y, incy: Int(incy.pointee), ap: ap
    )
}

@discardableResult
public func ctpmv_(
    _ uplo: UnsafeMutablePointer<CChar>!,
    _ trans: UnsafeMutablePointer<CChar>!,
    _ diag: UnsafeMutablePointer<CChar>!,
    _ n: UnsafeMutablePointer<Int32>!,
    _ ap: UnsafeMutableRawPointer!,
    _ x: UnsafeMutableRawPointer!,
    _ incx: UnsafeMutablePointer<Int32>!
) -> Int32 {
    guard let uplo, let trans, let diag, let n, let ap, let x, let incx else { return -1 }
    return _ctpmv(Float.self, uplo: uplo.pointee, trans: trans.pointee, diag: diag.pointee, n: Int(n.pointee), ap: ap, x: x, incx: Int(incx.pointee))
}

@discardableResult
public func ctpsv_(
    _ uplo: UnsafeMutablePointer<CChar>!,
    _ trans: UnsafeMutablePointer<CChar>!,
    _ diag: UnsafeMutablePointer<CChar>!,
    _ n: UnsafeMutablePointer<Int32>!,
    _ ap: UnsafeMutableRawPointer!,
    _ x: UnsafeMutableRawPointer!,
    _ incx: UnsafeMutablePointer<Int32>!
) -> Int32 {
    guard let uplo, let trans, let diag, let n, let ap, let x, let incx else { return -1 }
    return _ctpsv(Float.self, uplo: uplo.pointee, trans: trans.pointee, diag: diag.pointee, n: Int(n.pointee), ap: ap, x: x, incx: Int(incx.pointee))
}

@discardableResult
public func cgbmv_(
    _ trans: UnsafeMutablePointer<CChar>!,
    _ m: UnsafeMutablePointer<Int32>!,
    _ n: UnsafeMutablePointer<Int32>!,
    _ kl: UnsafeMutablePointer<Int32>!,
    _ ku: UnsafeMutablePointer<Int32>!,
    _ alpha: UnsafeMutableRawPointer!,
    _ a: UnsafeMutableRawPointer!,
    _ lda: UnsafeMutablePointer<Int32>!,
    _ x: UnsafeMutableRawPointer!,
    _ incx: UnsafeMutablePointer<Int32>!,
    _ beta: UnsafeMutableRawPointer!,
    _ y: UnsafeMutableRawPointer!,
    _ incy: UnsafeMutablePointer<Int32>!
) -> Int32 {
    guard let trans, let m, let n, let kl, let ku, let alpha, let a, let lda, let x, let incx, let beta, let y, let incy else { return -1 }
    return _cgbmv(
        trans: trans.pointee, m: Int(m.pointee), n: Int(n.pointee), kl: Int(kl.pointee), ku: Int(ku.pointee),
        alpha: _cplxLoad(alpha, 0) as _Cplx<Float>, a: a, lda: Int(lda.pointee),
        x: x, incx: Int(incx.pointee),
        beta: _cplxLoad(beta, 0) as _Cplx<Float>, y: y, incy: Int(incy.pointee)
    )
}

@discardableResult
public func chbmv_(
    _ uplo: UnsafeMutablePointer<CChar>!,
    _ n: UnsafeMutablePointer<Int32>!,
    _ k: UnsafeMutablePointer<Int32>!,
    _ alpha: UnsafeMutableRawPointer!,
    _ a: UnsafeMutableRawPointer!,
    _ lda: UnsafeMutablePointer<Int32>!,
    _ x: UnsafeMutableRawPointer!,
    _ incx: UnsafeMutablePointer<Int32>!,
    _ beta: UnsafeMutableRawPointer!,
    _ y: UnsafeMutableRawPointer!,
    _ incy: UnsafeMutablePointer<Int32>!
) -> Int32 {
    guard let uplo, let n, let k, let alpha, let a, let lda, let x, let incx, let beta, let y, let incy else { return -1 }
    return _chbmv(
        uplo: uplo.pointee, n: Int(n.pointee), k: Int(k.pointee),
        alpha: _cplxLoad(alpha, 0) as _Cplx<Float>, a: a, lda: Int(lda.pointee),
        x: x, incx: Int(incx.pointee),
        beta: _cplxLoad(beta, 0) as _Cplx<Float>, y: y, incy: Int(incy.pointee)
    )
}

@discardableResult
public func ctbmv_(
    _ uplo: UnsafeMutablePointer<CChar>!,
    _ trans: UnsafeMutablePointer<CChar>!,
    _ diag: UnsafeMutablePointer<CChar>!,
    _ n: UnsafeMutablePointer<Int32>!,
    _ k: UnsafeMutablePointer<Int32>!,
    _ a: UnsafeMutableRawPointer!,
    _ lda: UnsafeMutablePointer<Int32>!,
    _ x: UnsafeMutableRawPointer!,
    _ incx: UnsafeMutablePointer<Int32>!
) -> Int32 {
    guard let uplo, let trans, let diag, let n, let k, let a, let lda, let x, let incx else { return -1 }
    return _ctbmv(
        Float.self, uplo: uplo.pointee, trans: trans.pointee, diag: diag.pointee,
        n: Int(n.pointee), k: Int(k.pointee), a: a, lda: Int(lda.pointee), x: x, incx: Int(incx.pointee)
    )
}

@discardableResult
public func ctbsv_(
    _ uplo: UnsafeMutablePointer<CChar>!,
    _ trans: UnsafeMutablePointer<CChar>!,
    _ diag: UnsafeMutablePointer<CChar>!,
    _ n: UnsafeMutablePointer<Int32>!,
    _ k: UnsafeMutablePointer<Int32>!,
    _ a: UnsafeMutableRawPointer!,
    _ lda: UnsafeMutablePointer<Int32>!,
    _ x: UnsafeMutableRawPointer!,
    _ incx: UnsafeMutablePointer<Int32>!
) -> Int32 {
    guard let uplo, let trans, let diag, let n, let k, let a, let lda, let x, let incx else { return -1 }
    return _ctbsv(
        Float.self, uplo: uplo.pointee, trans: trans.pointee, diag: diag.pointee,
        n: Int(n.pointee), k: Int(k.pointee), a: a, lda: Int(lda.pointee), x: x, incx: Int(incx.pointee)
    )
}

@discardableResult
public func zhpmv_(
    _ uplo: UnsafeMutablePointer<CChar>!,
    _ n: UnsafeMutablePointer<Int32>!,
    _ alpha: UnsafeMutableRawPointer!,
    _ ap: UnsafeMutableRawPointer!,
    _ x: UnsafeMutableRawPointer!,
    _ incx: UnsafeMutablePointer<Int32>!,
    _ beta: UnsafeMutableRawPointer!,
    _ y: UnsafeMutableRawPointer!,
    _ incy: UnsafeMutablePointer<Int32>!
) -> Int32 {
    guard let uplo, let n, let alpha, let ap, let x, let incx, let beta, let y, let incy else { return -1 }
    return _chpmv(
        uplo: uplo.pointee, n: Int(n.pointee),
        alpha: _cplxLoad(alpha, 0) as _Cplx<Double>, ap: ap,
        x: x, incx: Int(incx.pointee),
        beta: _cplxLoad(beta, 0) as _Cplx<Double>, y: y, incy: Int(incy.pointee)
    )
}

@discardableResult
public func zhpr_(
    _ uplo: UnsafeMutablePointer<CChar>!,
    _ n: UnsafeMutablePointer<Int32>!,
    _ alpha: UnsafeMutablePointer<Double>!,
    _ x: UnsafeMutableRawPointer!,
    _ incx: UnsafeMutablePointer<Int32>!,
    _ ap: UnsafeMutableRawPointer!
) -> Int32 {
    guard let uplo, let n, let alpha, let x, let incx, let ap else { return -1 }
    return _chpr(uplo: uplo.pointee, n: Int(n.pointee), alpha: alpha.pointee, x: x, incx: Int(incx.pointee), ap: ap)
}

@discardableResult
public func zhpr2_(
    _ uplo: UnsafeMutablePointer<CChar>!,
    _ n: UnsafeMutablePointer<Int32>!,
    _ alpha: UnsafeMutableRawPointer!,
    _ x: UnsafeMutableRawPointer!,
    _ incx: UnsafeMutablePointer<Int32>!,
    _ y: UnsafeMutableRawPointer!,
    _ incy: UnsafeMutablePointer<Int32>!,
    _ ap: UnsafeMutableRawPointer!
) -> Int32 {
    guard let uplo, let n, let alpha, let x, let incx, let y, let incy, let ap else { return -1 }
    return _chpr2(
        uplo: uplo.pointee, n: Int(n.pointee), alpha: _cplxLoad(alpha, 0) as _Cplx<Double>,
        x: x, incx: Int(incx.pointee), y: y, incy: Int(incy.pointee), ap: ap
    )
}

@discardableResult
public func ztpmv_(
    _ uplo: UnsafeMutablePointer<CChar>!,
    _ trans: UnsafeMutablePointer<CChar>!,
    _ diag: UnsafeMutablePointer<CChar>!,
    _ n: UnsafeMutablePointer<Int32>!,
    _ ap: UnsafeMutableRawPointer!,
    _ x: UnsafeMutableRawPointer!,
    _ incx: UnsafeMutablePointer<Int32>!
) -> Int32 {
    guard let uplo, let trans, let diag, let n, let ap, let x, let incx else { return -1 }
    return _ctpmv(Double.self, uplo: uplo.pointee, trans: trans.pointee, diag: diag.pointee, n: Int(n.pointee), ap: ap, x: x, incx: Int(incx.pointee))
}

@discardableResult
public func ztpsv_(
    _ uplo: UnsafeMutablePointer<CChar>!,
    _ trans: UnsafeMutablePointer<CChar>!,
    _ diag: UnsafeMutablePointer<CChar>!,
    _ n: UnsafeMutablePointer<Int32>!,
    _ ap: UnsafeMutableRawPointer!,
    _ x: UnsafeMutableRawPointer!,
    _ incx: UnsafeMutablePointer<Int32>!
) -> Int32 {
    guard let uplo, let trans, let diag, let n, let ap, let x, let incx else { return -1 }
    return _ctpsv(Double.self, uplo: uplo.pointee, trans: trans.pointee, diag: diag.pointee, n: Int(n.pointee), ap: ap, x: x, incx: Int(incx.pointee))
}

@discardableResult
public func zgbmv_(
    _ trans: UnsafeMutablePointer<CChar>!,
    _ m: UnsafeMutablePointer<Int32>!,
    _ n: UnsafeMutablePointer<Int32>!,
    _ kl: UnsafeMutablePointer<Int32>!,
    _ ku: UnsafeMutablePointer<Int32>!,
    _ alpha: UnsafeMutableRawPointer!,
    _ a: UnsafeMutableRawPointer!,
    _ lda: UnsafeMutablePointer<Int32>!,
    _ x: UnsafeMutableRawPointer!,
    _ incx: UnsafeMutablePointer<Int32>!,
    _ beta: UnsafeMutableRawPointer!,
    _ y: UnsafeMutableRawPointer!,
    _ incy: UnsafeMutablePointer<Int32>!
) -> Int32 {
    guard let trans, let m, let n, let kl, let ku, let alpha, let a, let lda, let x, let incx, let beta, let y, let incy else { return -1 }
    return _cgbmv(
        trans: trans.pointee, m: Int(m.pointee), n: Int(n.pointee), kl: Int(kl.pointee), ku: Int(ku.pointee),
        alpha: _cplxLoad(alpha, 0) as _Cplx<Double>, a: a, lda: Int(lda.pointee),
        x: x, incx: Int(incx.pointee),
        beta: _cplxLoad(beta, 0) as _Cplx<Double>, y: y, incy: Int(incy.pointee)
    )
}

@discardableResult
public func zhbmv_(
    _ uplo: UnsafeMutablePointer<CChar>!,
    _ n: UnsafeMutablePointer<Int32>!,
    _ k: UnsafeMutablePointer<Int32>!,
    _ alpha: UnsafeMutableRawPointer!,
    _ a: UnsafeMutableRawPointer!,
    _ lda: UnsafeMutablePointer<Int32>!,
    _ x: UnsafeMutableRawPointer!,
    _ incx: UnsafeMutablePointer<Int32>!,
    _ beta: UnsafeMutableRawPointer!,
    _ y: UnsafeMutableRawPointer!,
    _ incy: UnsafeMutablePointer<Int32>!
) -> Int32 {
    guard let uplo, let n, let k, let alpha, let a, let lda, let x, let incx, let beta, let y, let incy else { return -1 }
    return _chbmv(
        uplo: uplo.pointee, n: Int(n.pointee), k: Int(k.pointee),
        alpha: _cplxLoad(alpha, 0) as _Cplx<Double>, a: a, lda: Int(lda.pointee),
        x: x, incx: Int(incx.pointee),
        beta: _cplxLoad(beta, 0) as _Cplx<Double>, y: y, incy: Int(incy.pointee)
    )
}

@discardableResult
public func ztbmv_(
    _ uplo: UnsafeMutablePointer<CChar>!,
    _ trans: UnsafeMutablePointer<CChar>!,
    _ diag: UnsafeMutablePointer<CChar>!,
    _ n: UnsafeMutablePointer<Int32>!,
    _ k: UnsafeMutablePointer<Int32>!,
    _ a: UnsafeMutableRawPointer!,
    _ lda: UnsafeMutablePointer<Int32>!,
    _ x: UnsafeMutableRawPointer!,
    _ incx: UnsafeMutablePointer<Int32>!
) -> Int32 {
    guard let uplo, let trans, let diag, let n, let k, let a, let lda, let x, let incx else { return -1 }
    return _ctbmv(
        Double.self, uplo: uplo.pointee, trans: trans.pointee, diag: diag.pointee,
        n: Int(n.pointee), k: Int(k.pointee), a: a, lda: Int(lda.pointee), x: x, incx: Int(incx.pointee)
    )
}

@discardableResult
public func ztbsv_(
    _ uplo: UnsafeMutablePointer<CChar>!,
    _ trans: UnsafeMutablePointer<CChar>!,
    _ diag: UnsafeMutablePointer<CChar>!,
    _ n: UnsafeMutablePointer<Int32>!,
    _ k: UnsafeMutablePointer<Int32>!,
    _ a: UnsafeMutableRawPointer!,
    _ lda: UnsafeMutablePointer<Int32>!,
    _ x: UnsafeMutableRawPointer!,
    _ incx: UnsafeMutablePointer<Int32>!
) -> Int32 {
    guard let uplo, let trans, let diag, let n, let k, let a, let lda, let x, let incx else { return -1 }
    return _ctbsv(
        Double.self, uplo: uplo.pointee, trans: trans.pointee, diag: diag.pointee,
        n: Int(n.pointee), k: Int(k.pointee), a: a, lda: Int(lda.pointee), x: x, incx: Int(incx.pointee)
    )
}
