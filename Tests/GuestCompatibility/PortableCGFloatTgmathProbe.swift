// Compile this client with Foundation absent. It proves the public
// CoreGraphics-shaped CGFloat overloads are visible from another module, not
// merely callable inside OpenCoreGraphics' implementation file.
import OpenCoreGraphics

public func portableCGFloatUnaryTgmath(_ x: CGFloat) -> [CGFloat] {
    [
        acos(x), cos(x), sin(x), asin(x), atan(x), tan(x),
        acosh(x), asinh(x), atanh(x), cosh(x), sinh(x), tanh(x),
        exp(x), exp2(x), expm1(x), log(x), log10(x), log2(x),
        log1p(x), logb(x), cbrt(x), erf(x), erfc(x), tgamma(x),
        nearbyint(x), rint(x),
    ]
}

public func portableCGFloatBinaryTgmath(
    _ x: CGFloat,
    _ y: CGFloat
) -> [CGFloat] {
    [
        atan2(x, y), hypot(x, y), pow(x, y), copysign(x, y),
        nextafter(x, y), fdim(x, y), fmax(x, y), fmin(x, y),
    ]
}

public func portableCGFloatDecompositions(
    _ x: CGFloat,
    _ y: CGFloat
) -> (CGFloat, CGFloat, CGFloat, Int, CGFloat, Int, CGFloat, Int) {
    let (integer, fraction) = modf(x)
    let (normalized, exponent) = frexp(x)
    let (remainder, quotient) = remquo(x, y)
    return (
        integer,
        fraction,
        ldexp(x, 2),
        ilogb(x),
        normalized,
        exponent,
        remainder + scalbn(x, 2),
        quotient
    )
}
