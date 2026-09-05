import Foundation

public func cblas_sgemm(
    _ order: CBLAS_ORDER,
    _ transA: CBLAS_TRANSPOSE,
    _ transB: CBLAS_TRANSPOSE,
    _ m: Int32,
    _ n: Int32,
    _ k: Int32,
    _ alpha: Float,
    _ a: UnsafePointer<Float>!,
    _ lda: Int32,
    _ b: UnsafePointer<Float>!,
    _ ldb: Int32,
    _ beta: Float,
    _ c: UnsafeMutablePointer<Float>!,
    _ ldc: Int32
) {
    guard let a, let b, let c else { return }
    let ta: CChar = transA.rawValue == CblasNoTrans.rawValue ? 78 : 84
    let tb: CChar = transB.rawValue == CblasNoTrans.rawValue ? 78 : 84
    if order.rawValue == CblasColMajor.rawValue {
        _ = _gemm(
            transA: ta, transB: tb,
            m: Int(m), n: Int(n), k: Int(k),
            alpha: alpha, a: UnsafeMutablePointer(mutating: a), lda: Int(lda),
            b: UnsafeMutablePointer(mutating: b), ldb: Int(ldb),
            beta: beta, c: c, ldc: Int(ldc)
        )
    } else {
        _ = _gemm(
            transA: tb, transB: ta,
            m: Int(n), n: Int(m), k: Int(k),
            alpha: alpha, a: UnsafeMutablePointer(mutating: b), lda: Int(ldb),
            b: UnsafeMutablePointer(mutating: a), ldb: Int(lda),
            beta: beta, c: c, ldc: Int(ldc)
        )
    }
}

public func cblas_dgemm(
    _ order: CBLAS_ORDER,
    _ transA: CBLAS_TRANSPOSE,
    _ transB: CBLAS_TRANSPOSE,
    _ m: Int32,
    _ n: Int32,
    _ k: Int32,
    _ alpha: Double,
    _ a: UnsafePointer<Double>!,
    _ lda: Int32,
    _ b: UnsafePointer<Double>!,
    _ ldb: Int32,
    _ beta: Double,
    _ c: UnsafeMutablePointer<Double>!,
    _ ldc: Int32
) {
    guard let a, let b, let c else { return }
    let ta: CChar = transA.rawValue == CblasNoTrans.rawValue ? 78 : 84
    let tb: CChar = transB.rawValue == CblasNoTrans.rawValue ? 78 : 84
    if order.rawValue == CblasColMajor.rawValue {
        _ = _gemm(
            transA: ta, transB: tb,
            m: Int(m), n: Int(n), k: Int(k),
            alpha: alpha, a: UnsafeMutablePointer(mutating: a), lda: Int(lda),
            b: UnsafeMutablePointer(mutating: b), ldb: Int(ldb),
            beta: beta, c: c, ldc: Int(ldc)
        )
    } else {
        _ = _gemm(
            transA: tb, transB: ta,
            m: Int(n), n: Int(m), k: Int(k),
            alpha: alpha, a: UnsafeMutablePointer(mutating: b), lda: Int(ldb),
            b: UnsafeMutablePointer(mutating: a), ldb: Int(lda),
            beta: beta, c: c, ldc: Int(ldc)
        )
    }
}

public func cblas_saxpy(_ n: Int32, _ a: Float, _ x: UnsafePointer<Float>!, _ incx: Int32, _ y: UnsafeMutablePointer<Float>!, _ incy: Int32) {
    guard let x, let y else { return }
    var nn = n
    var aa = a
    var ix = incx
    var iy = incy
    var xx = Array(UnsafeBufferPointer(start: x, count: max(1, Int(n) * max(1, Int(abs(incx))))))
    _ = saxpy_(&nn, &aa, &xx, &ix, y, &iy)
}

public func cblas_daxpy(_ n: Int32, _ a: Double, _ x: UnsafePointer<Double>!, _ incx: Int32, _ y: UnsafeMutablePointer<Double>!, _ incy: Int32) {
    guard let x, let y else { return }
    var nn = n
    var aa = a
    var ix = incx
    var iy = incy
    var xx = Array(UnsafeBufferPointer(start: x, count: max(1, Int(n) * max(1, Int(abs(incx))))))
    _ = daxpy_(&nn, &aa, &xx, &ix, y, &iy)
}

func _isTrans(_ ch: CChar) -> Bool {
    ch == 84 || ch == 116
}

func _gemm<T: BinaryFloatingPoint>(
    transA: CChar,
    transB: CChar,
    m: Int,
    n: Int,
    k: Int,
    alpha: T,
    a: UnsafeMutablePointer<T>,
    lda: Int,
    b: UnsafeMutablePointer<T>,
    ldb: Int,
    beta: T,
    c: UnsafeMutablePointer<T>,
    ldc: Int
) -> Int32 {
    guard m >= 0, n >= 0, k >= 0, lda > 0, ldb > 0, ldc > 0 else { return -1 }
    let ta = _isTrans(transA)
    let tb = _isTrans(transB)
    for j in 0..<n {
        for i in 0..<m {
            var sum: T = 0
            for p in 0..<k {
                let av: T = ta ? a[i * lda + p] : a[p * lda + i]
                let bv: T = tb ? b[p * ldb + j] : b[j * ldb + p]
                sum += av * bv
            }
            let idx = j * ldc + i
            c[idx] = alpha * sum + beta * c[idx]
        }
    }
    return 0
}

func _gemv<T: BinaryFloatingPoint>(
    trans: CChar,
    m: Int,
    n: Int,
    alpha: T,
    a: UnsafeMutablePointer<T>,
    lda: Int,
    x: UnsafeMutablePointer<T>,
    incx: Int,
    beta: T,
    y: UnsafeMutablePointer<T>,
    incy: Int
) -> Int32 {
    let doTrans = _isTrans(trans)
    let outCount = doTrans ? n : m
    let inner = doTrans ? m : n
    var yi = 0
    for i in 0..<outCount {
        var sum: T = 0
        var xi = 0
        for j in 0..<inner {
            let av: T = doTrans ? a[i * lda + j] : a[j * lda + i]
            sum += av * x[xi]
            xi += incx
        }
        y[yi] = alpha * sum + beta * y[yi]
        yi += incy
    }
    return 0
}
