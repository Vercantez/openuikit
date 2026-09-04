import Foundation

private var _blasThreading = BLAS_THREADING_MULTI_THREADED

public func BLASGetThreading() -> BLAS_THREADING {
    _blasThreading
}

@discardableResult
public func BLASSetThreading(_ threading: BLAS_THREADING) -> Int32 {
    if threading.rawValue >= BLAS_THREADING_MAX_OPTIONS.rawValue {
        return -1
    }
    _blasThreading = threading
    return 0
}

@discardableResult
public func saxpy_(
    _ n: UnsafeMutablePointer<Int32>!,
    _ da: UnsafeMutablePointer<Float>!,
    _ sx: UnsafeMutablePointer<Float>!,
    _ incx: UnsafeMutablePointer<Int32>!,
    _ sy: UnsafeMutablePointer<Float>!,
    _ incy: UnsafeMutablePointer<Int32>!
) -> Int32 {
    guard let n, let da, let sx, let incx, let sy, let incy else { return -1 }
    let count = Int(n.pointee)
    let a = da.pointee
    let ix = Int(incx.pointee)
    let iy = Int(incy.pointee)
    guard count > 0, ix != 0, iy != 0 else { return 0 }
    var xi = 0
    var yi = 0
    for _ in 0..<count {
        sy[yi] += a * sx[xi]
        xi += ix
        yi += iy
    }
    return 0
}

@discardableResult
public func daxpy_(
    _ n: UnsafeMutablePointer<Int32>!,
    _ da: UnsafeMutablePointer<Double>!,
    _ dx: UnsafeMutablePointer<Double>!,
    _ incx: UnsafeMutablePointer<Int32>!,
    _ dy: UnsafeMutablePointer<Double>!,
    _ incy: UnsafeMutablePointer<Int32>!
) -> Int32 {
    guard let n, let da, let dx, let incx, let dy, let incy else { return -1 }
    let count = Int(n.pointee)
    let a = da.pointee
    let ix = Int(incx.pointee)
    let iy = Int(incy.pointee)
    guard count > 0, ix != 0, iy != 0 else { return 0 }
    var xi = 0
    var yi = 0
    for _ in 0..<count {
        dy[yi] += a * dx[xi]
        xi += ix
        yi += iy
    }
    return 0
}

public func sdot_(
    _ n: UnsafeMutablePointer<Int32>!,
    _ sx: UnsafeMutablePointer<Float>!,
    _ incx: UnsafeMutablePointer<Int32>!,
    _ sy: UnsafeMutablePointer<Float>!,
    _ incy: UnsafeMutablePointer<Int32>!
) -> Double {
    guard let n, let sx, let incx, let sy, let incy else { return 0 }
    let count = Int(n.pointee)
    let ix = Int(incx.pointee)
    let iy = Int(incy.pointee)
    guard count > 0, ix != 0, iy != 0 else { return 0 }
    var sum: Double = 0
    var xi = 0
    var yi = 0
    for _ in 0..<count {
        sum += Double(sx[xi]) * Double(sy[yi])
        xi += ix
        yi += iy
    }
    return sum
}

public func ddot_(
    _ n: UnsafeMutablePointer<Int32>!,
    _ dx: UnsafeMutablePointer<Double>!,
    _ incx: UnsafeMutablePointer<Int32>!,
    _ dy: UnsafeMutablePointer<Double>!,
    _ incy: UnsafeMutablePointer<Int32>!
) -> Double {
    guard let n, let dx, let incx, let dy, let incy else { return 0 }
    let count = Int(n.pointee)
    let ix = Int(incx.pointee)
    let iy = Int(incy.pointee)
    guard count > 0, ix != 0, iy != 0 else { return 0 }
    var sum: Double = 0
    var xi = 0
    var yi = 0
    for _ in 0..<count {
        sum += dx[xi] * dy[yi]
        xi += ix
        yi += iy
    }
    return sum
}

@discardableResult
public func sscal_(
    _ n: UnsafeMutablePointer<Int32>!,
    _ da: UnsafeMutablePointer<Float>!,
    _ sx: UnsafeMutablePointer<Float>!,
    _ incx: UnsafeMutablePointer<Int32>!
) -> Int32 {
    guard let n, let da, let sx, let incx else { return -1 }
    let count = Int(n.pointee)
    let a = da.pointee
    let ix = Int(incx.pointee)
    guard count > 0, ix != 0 else { return 0 }
    var i = 0
    for _ in 0..<count {
        sx[i] *= a
        i += ix
    }
    return 0
}

@discardableResult
public func dscal_(
    _ n: UnsafeMutablePointer<Int32>!,
    _ da: UnsafeMutablePointer<Double>!,
    _ dx: UnsafeMutablePointer<Double>!,
    _ incx: UnsafeMutablePointer<Int32>!
) -> Int32 {
    guard let n, let da, let dx, let incx else { return -1 }
    let count = Int(n.pointee)
    let a = da.pointee
    let ix = Int(incx.pointee)
    guard count > 0, ix != 0 else { return 0 }
    var i = 0
    for _ in 0..<count {
        dx[i] *= a
        i += ix
    }
    return 0
}

public func sasum_(
    _ n: UnsafeMutablePointer<Int32>!,
    _ sx: UnsafeMutablePointer<Float>!,
    _ incx: UnsafeMutablePointer<Int32>!
) -> Double {
    guard let n, let sx, let incx else { return 0 }
    let count = Int(n.pointee)
    let ix = Int(incx.pointee)
    guard count > 0, ix != 0 else { return 0 }
    var sum: Double = 0
    var i = 0
    for _ in 0..<count {
        sum += Double(abs(sx[i]))
        i += ix
    }
    return sum
}

public func dasum_(
    _ n: UnsafeMutablePointer<Int32>!,
    _ dx: UnsafeMutablePointer<Double>!,
    _ incx: UnsafeMutablePointer<Int32>!
) -> Double {
    guard let n, let dx, let incx else { return 0 }
    let count = Int(n.pointee)
    let ix = Int(incx.pointee)
    guard count > 0, ix != 0 else { return 0 }
    var sum: Double = 0
    var i = 0
    for _ in 0..<count {
        sum += abs(dx[i])
        i += ix
    }
    return sum
}

@discardableResult
public func scopy_(
    _ n: UnsafeMutablePointer<Int32>!,
    _ sx: UnsafeMutablePointer<Float>!,
    _ incx: UnsafeMutablePointer<Int32>!,
    _ sy: UnsafeMutablePointer<Float>!,
    _ incy: UnsafeMutablePointer<Int32>!
) -> Int32 {
    guard let n, let sx, let incx, let sy, let incy else { return -1 }
    let count = Int(n.pointee)
    let ix = Int(incx.pointee)
    let iy = Int(incy.pointee)
    guard count > 0, ix != 0, iy != 0 else { return 0 }
    var xi = 0
    var yi = 0
    for _ in 0..<count {
        sy[yi] = sx[xi]
        xi += ix
        yi += iy
    }
    return 0
}

@discardableResult
public func dcopy_(
    _ n: UnsafeMutablePointer<Int32>!,
    _ dx: UnsafeMutablePointer<Double>!,
    _ incx: UnsafeMutablePointer<Int32>!,
    _ dy: UnsafeMutablePointer<Double>!,
    _ incy: UnsafeMutablePointer<Int32>!
) -> Int32 {
    guard let n, let dx, let incx, let dy, let incy else { return -1 }
    let count = Int(n.pointee)
    let ix = Int(incx.pointee)
    let iy = Int(incy.pointee)
    guard count > 0, ix != 0, iy != 0 else { return 0 }
    var xi = 0
    var yi = 0
    for _ in 0..<count {
        dy[yi] = dx[xi]
        xi += ix
        yi += iy
    }
    return 0
}

@discardableResult
public func sswap_(
    _ n: UnsafeMutablePointer<Int32>!,
    _ sx: UnsafeMutablePointer<Float>!,
    _ incx: UnsafeMutablePointer<Int32>!,
    _ sy: UnsafeMutablePointer<Float>!,
    _ incy: UnsafeMutablePointer<Int32>!
) -> Int32 {
    guard let n, let sx, let incx, let sy, let incy else { return -1 }
    let count = Int(n.pointee)
    let ix = Int(incx.pointee)
    let iy = Int(incy.pointee)
    guard count > 0, ix != 0, iy != 0 else { return 0 }
    var xi = 0
    var yi = 0
    for _ in 0..<count {
        let tmp = sx[xi]
        sx[xi] = sy[yi]
        sy[yi] = tmp
        xi += ix
        yi += iy
    }
    return 0
}

@discardableResult
public func dswap_(
    _ n: UnsafeMutablePointer<Int32>!,
    _ dx: UnsafeMutablePointer<Double>!,
    _ incx: UnsafeMutablePointer<Int32>!,
    _ dy: UnsafeMutablePointer<Double>!,
    _ incy: UnsafeMutablePointer<Int32>!
) -> Int32 {
    guard let n, let dx, let incx, let dy, let incy else { return -1 }
    let count = Int(n.pointee)
    let ix = Int(incx.pointee)
    let iy = Int(incy.pointee)
    guard count > 0, ix != 0, iy != 0 else { return 0 }
    var xi = 0
    var yi = 0
    for _ in 0..<count {
        let tmp = dx[xi]
        dx[xi] = dy[yi]
        dy[yi] = tmp
        xi += ix
        yi += iy
    }
    return 0
}

public func snrm2_(
    _ n: UnsafeMutablePointer<Int32>!,
    _ x: UnsafeMutablePointer<Float>!,
    _ incx: UnsafeMutablePointer<Int32>!
) -> Double {
    guard let n, let x, let incx else { return 0 }
    let count = Int(n.pointee)
    let ix = Int(incx.pointee)
    guard count > 0, ix != 0 else { return 0 }
    var sum: Double = 0
    var i = 0
    for _ in 0..<count {
        let v = Double(x[i])
        sum += v * v
        i += ix
    }
    return sum.squareRoot()
}

public func dnrm2_(
    _ n: UnsafeMutablePointer<Int32>!,
    _ x: UnsafeMutablePointer<Double>!,
    _ incx: UnsafeMutablePointer<Int32>!
) -> Double {
    guard let n, let x, let incx else { return 0 }
    let count = Int(n.pointee)
    let ix = Int(incx.pointee)
    guard count > 0, ix != 0 else { return 0 }
    var sum: Double = 0
    var i = 0
    for _ in 0..<count {
        sum += x[i] * x[i]
        i += ix
    }
    return sum.squareRoot()
}

public func isamax_(
    _ n: UnsafeMutablePointer<Int32>!,
    _ sx: UnsafeMutablePointer<Float>!,
    _ incx: UnsafeMutablePointer<Int32>!
) -> Int32 {
    guard let n, let sx, let incx else { return 0 }
    let count = Int(n.pointee)
    let ix = Int(incx.pointee)
    guard count > 0, ix != 0 else { return 0 }
    var best = 0
    var bestAbs = abs(sx[0])
    var i = ix
    var index = 1
    while index < count {
        let v = abs(sx[i])
        if v > bestAbs {
            bestAbs = v
            best = index
        }
        i += ix
        index += 1
    }
    return Int32(best + 1)
}

public func idamax_(
    _ n: UnsafeMutablePointer<Int32>!,
    _ dx: UnsafeMutablePointer<Double>!,
    _ incx: UnsafeMutablePointer<Int32>!
) -> Int32 {
    guard let n, let dx, let incx else { return 0 }
    let count = Int(n.pointee)
    let ix = Int(incx.pointee)
    guard count > 0, ix != 0 else { return 0 }
    var best = 0
    var bestAbs = abs(dx[0])
    var i = ix
    var index = 1
    while index < count {
        let v = abs(dx[i])
        if v > bestAbs {
            bestAbs = v
            best = index
        }
        i += ix
        index += 1
    }
    return Int32(best + 1)
}
