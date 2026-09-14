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
