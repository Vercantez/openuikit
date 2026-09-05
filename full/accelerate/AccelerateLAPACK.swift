import Foundation

/// Column-major LAPACK-style solvers used by the corpus (sgesv/dgesv, sgetrf, sposv, sgels).
@discardableResult
public func sgetrf_(
    _ m: UnsafeMutablePointer<Int32>!,
    _ n: UnsafeMutablePointer<Int32>!,
    _ a: UnsafeMutablePointer<Float>!,
    _ lda: UnsafeMutablePointer<Int32>!,
    _ ipiv: UnsafeMutablePointer<Int32>!,
    _ info: UnsafeMutablePointer<Int32>!
) -> Int32 {
    guard let m, let n, let a, let lda, let ipiv, let info else { return -1 }
    let rc = _getrf(m: Int(m.pointee), n: Int(n.pointee), a: a, lda: Int(lda.pointee), ipiv: ipiv)
    info.pointee = rc
    return rc
}

@discardableResult
public func dgetrf_(
    _ m: UnsafeMutablePointer<Int32>!,
    _ n: UnsafeMutablePointer<Int32>!,
    _ a: UnsafeMutablePointer<Double>!,
    _ lda: UnsafeMutablePointer<Int32>!,
    _ ipiv: UnsafeMutablePointer<Int32>!,
    _ info: UnsafeMutablePointer<Int32>!
) -> Int32 {
    guard let m, let n, let a, let lda, let ipiv, let info else { return -1 }
    let rc = _getrf(m: Int(m.pointee), n: Int(n.pointee), a: a, lda: Int(lda.pointee), ipiv: ipiv)
    info.pointee = rc
    return rc
}

@discardableResult
public func sgesv_(
    _ n: UnsafeMutablePointer<Int32>!,
    _ nrhs: UnsafeMutablePointer<Int32>!,
    _ a: UnsafeMutablePointer<Float>!,
    _ lda: UnsafeMutablePointer<Int32>!,
    _ ipiv: UnsafeMutablePointer<Int32>!,
    _ b: UnsafeMutablePointer<Float>!,
    _ ldb: UnsafeMutablePointer<Int32>!,
    _ info: UnsafeMutablePointer<Int32>!
) -> Int32 {
    guard let n, let nrhs, let a, let lda, let ipiv, let b, let ldb, let info else { return -1 }
    let rc = _gesv(n: Int(n.pointee), nrhs: Int(nrhs.pointee), a: a, lda: Int(lda.pointee), ipiv: ipiv, b: b, ldb: Int(ldb.pointee))
    info.pointee = rc
    return rc
}

@discardableResult
public func dgesv_(
    _ n: UnsafeMutablePointer<Int32>!,
    _ nrhs: UnsafeMutablePointer<Int32>!,
    _ a: UnsafeMutablePointer<Double>!,
    _ lda: UnsafeMutablePointer<Int32>!,
    _ ipiv: UnsafeMutablePointer<Int32>!,
    _ b: UnsafeMutablePointer<Double>!,
    _ ldb: UnsafeMutablePointer<Int32>!,
    _ info: UnsafeMutablePointer<Int32>!
) -> Int32 {
    guard let n, let nrhs, let a, let lda, let ipiv, let b, let ldb, let info else { return -1 }
    let rc = _gesv(n: Int(n.pointee), nrhs: Int(nrhs.pointee), a: a, lda: Int(lda.pointee), ipiv: ipiv, b: b, ldb: Int(ldb.pointee))
    info.pointee = rc
    return rc
}

@discardableResult
public func sposv_(
    _ uplo: UnsafeMutablePointer<CChar>!,
    _ n: UnsafeMutablePointer<Int32>!,
    _ nrhs: UnsafeMutablePointer<Int32>!,
    _ a: UnsafeMutablePointer<Float>!,
    _ lda: UnsafeMutablePointer<Int32>!,
    _ b: UnsafeMutablePointer<Float>!,
    _ ldb: UnsafeMutablePointer<Int32>!,
    _ info: UnsafeMutablePointer<Int32>!
) -> Int32 {
    guard let n, let nrhs, let a, let lda, let b, let ldb, let info else { return -1 }
    _ = uplo
    let rc = _posv(n: Int(n.pointee), nrhs: Int(nrhs.pointee), a: a, lda: Int(lda.pointee), b: b, ldb: Int(ldb.pointee))
    info.pointee = rc
    return rc
}

@discardableResult
public func sgels_(
    _ trans: UnsafeMutablePointer<CChar>!,
    _ m: UnsafeMutablePointer<Int32>!,
    _ n: UnsafeMutablePointer<Int32>!,
    _ nrhs: UnsafeMutablePointer<Int32>!,
    _ a: UnsafeMutablePointer<Float>!,
    _ lda: UnsafeMutablePointer<Int32>!,
    _ b: UnsafeMutablePointer<Float>!,
    _ ldb: UnsafeMutablePointer<Int32>!,
    _ work: UnsafeMutablePointer<Float>!,
    _ lwork: UnsafeMutablePointer<Int32>!,
    _ info: UnsafeMutablePointer<Int32>!
) -> Int32 {
    guard let trans, let m, let n, let nrhs, let a, let lda, let b, let ldb, let info else { return -1 }
    _ = work
    _ = lwork
    let rc = _gels(trans: trans.pointee, m: Int(m.pointee), n: Int(n.pointee), nrhs: Int(nrhs.pointee), a: a, lda: Int(lda.pointee), b: b, ldb: Int(ldb.pointee))
    info.pointee = rc
    return rc
}

private func _swapRows<T>(_ a: UnsafeMutablePointer<T>, _ lda: Int, _ n: Int, _ r1: Int, _ r2: Int) {
    guard r1 != r2 else { return }
    for c in 0..<n {
        let t = a[c * lda + r1]
        a[c * lda + r1] = a[c * lda + r2]
        a[c * lda + r2] = t
    }
}

private func _getrf<T: BinaryFloatingPoint>(
    m: Int,
    n: Int,
    a: UnsafeMutablePointer<T>,
    lda: Int,
    ipiv: UnsafeMutablePointer<Int32>
) -> Int32 {
    let k = min(m, n)
    for i in 0..<k {
        var pivot = i
        var best = abs(a[i * lda + i])
        for r in (i + 1)..<m {
            let v = abs(a[i * lda + r])
            if v > best {
                best = v
                pivot = r
            }
        }
        if best == 0 { return Int32(i + 1) }
        ipiv[i] = Int32(pivot + 1)
        _swapRows(a, lda, n, i, pivot)
        let diag = a[i * lda + i]
        for r in (i + 1)..<m {
            a[i * lda + r] /= diag
            let lik = a[i * lda + r]
            for c in (i + 1)..<n {
                a[c * lda + r] -= lik * a[c * lda + i]
            }
        }
    }
    return 0
}

private func _gesv<T: BinaryFloatingPoint>(
    n: Int,
    nrhs: Int,
    a: UnsafeMutablePointer<T>,
    lda: Int,
    ipiv: UnsafeMutablePointer<Int32>,
    b: UnsafeMutablePointer<T>,
    ldb: Int
) -> Int32 {
    let rc = _getrf(m: n, n: n, a: a, lda: lda, ipiv: ipiv)
    if rc != 0 { return rc }
    for i in 0..<n {
        let piv = Int(ipiv[i]) - 1
        if piv != i {
            for rhs in 0..<nrhs {
                let t = b[rhs * ldb + i]
                b[rhs * ldb + i] = b[rhs * ldb + piv]
                b[rhs * ldb + piv] = t
            }
        }
        for r in (i + 1)..<n {
            let lik = a[i * lda + r]
            for rhs in 0..<nrhs {
                b[rhs * ldb + r] -= lik * b[rhs * ldb + i]
            }
        }
    }
    for i in stride(from: n - 1, through: 0, by: -1) {
        let diag = a[i * lda + i]
        if diag == 0 { return Int32(i + 1) }
        for rhs in 0..<nrhs {
            var sum = b[rhs * ldb + i]
            for c in (i + 1)..<n {
                sum -= a[c * lda + i] * b[rhs * ldb + c]
            }
            b[rhs * ldb + i] = sum / diag
        }
    }
    return 0
}

private func _posv<T: BinaryFloatingPoint>(
    n: Int,
    nrhs: Int,
    a: UnsafeMutablePointer<T>,
    lda: Int,
    b: UnsafeMutablePointer<T>,
    ldb: Int
) -> Int32 {
    for i in 0..<n {
        var diag = a[i * lda + i]
        for k in 0..<i {
            diag -= a[i * lda + k] * a[i * lda + k]
        }
        if diag <= 0 { return Int32(i + 1) }
        let s = diag.squareRoot()
        a[i * lda + i] = s
        for j in (i + 1)..<n {
            var v = a[i * lda + j]
            for k in 0..<i {
                v -= a[i * lda + k] * a[j * lda + k]
            }
            a[i * lda + j] = v / s
        }
    }
    for rhs in 0..<nrhs {
        for i in 0..<n {
            var s = b[rhs * ldb + i]
            for k in 0..<i {
                s -= a[i * lda + k] * b[rhs * ldb + k]
            }
            b[rhs * ldb + i] = s / a[i * lda + i]
        }
        for i in stride(from: n - 1, through: 0, by: -1) {
            var s = b[rhs * ldb + i]
            for k in (i + 1)..<n {
                s -= a[i * lda + k] * b[rhs * ldb + k]
            }
            b[rhs * ldb + i] = s / a[i * lda + i]
        }
    }
    return 0
}

private func _gels<T: BinaryFloatingPoint>(
    trans: CChar,
    m: Int,
    n: Int,
    nrhs: Int,
    a: UnsafeMutablePointer<T>,
    lda: Int,
    b: UnsafeMutablePointer<T>,
    ldb: Int
) -> Int32 {
    _ = trans
    guard m >= n else { return -1 }
    var ata = [T](repeating: 0, count: n * n)
    var atb = [T](repeating: 0, count: n * nrhs)
    for i in 0..<n {
        for j in 0..<n {
            var s: T = 0
            for r in 0..<m {
                s += a[i * lda + r] * a[j * lda + r]
            }
            ata[j * n + i] = s
        }
        for rhs in 0..<nrhs {
            var s: T = 0
            for r in 0..<m {
                s += a[i * lda + r] * b[rhs * ldb + r]
            }
            atb[rhs * n + i] = s
        }
    }
    var ipiv = [Int32](repeating: 0, count: n)
    let rc = ata.withUnsafeMutableBufferPointer { ap in
        atb.withUnsafeMutableBufferPointer { bp in
            ipiv.withUnsafeMutableBufferPointer { ip in
                _gesv(n: n, nrhs: nrhs, a: ap.baseAddress!, lda: n, ipiv: ip.baseAddress!, b: bp.baseAddress!, ldb: n)
            }
        }
    }
    if rc == 0 {
        for rhs in 0..<nrhs {
            for i in 0..<n {
                b[rhs * ldb + i] = atb[rhs * n + i]
            }
        }
    }
    return rc
}
