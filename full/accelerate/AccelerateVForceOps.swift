import Foundation

extension vForce {
    private static func mapUnary<U, V>(_ vector: U, _ result: inout V, _ transform: (U.Element) -> V.Element)
    where U: AccelerateBuffer, V: AccelerateMutableBuffer {
        vector.withUnsafeBufferPointer { src in
            result.withUnsafeMutableBufferPointer { dest in
                let n = min(src.count, dest.count)
                for i in 0..<n { dest[i] = transform(src[i]) }
            }
        }
    }

    private static func mapBinary<A, B, O>(_ a: A, _ b: B, _ result: inout O, _ combine: (A.Element, B.Element) -> O.Element)
    where A: AccelerateBuffer, B: AccelerateBuffer, O: AccelerateMutableBuffer {
        a.withUnsafeBufferPointer { av in
            b.withUnsafeBufferPointer { bv in
                result.withUnsafeMutableBufferPointer { dest in
                    let n = min(av.count, min(bv.count, dest.count))
                    for i in 0..<n { dest[i] = combine(av[i], bv[i]) }
                }
            }
        }
    }

    public static func reciprocal<U, V>(_ vector: U, result: inout V) where U: AccelerateBuffer, V: AccelerateMutableBuffer, U.Element == Double, V.Element == Double {
        mapUnary(vector, &result, { 1 / $0 })
    }

    public static func reciprocal<U, V>(_ vector: U, result: inout V) where U: AccelerateBuffer, V: AccelerateMutableBuffer, U.Element == Float, V.Element == Float {
        mapUnary(vector, &result, { 1 / $0 })
    }

    public static func reciprocal<U>(_ vector: U) -> [Double] where U: AccelerateBuffer, U.Element == Double {
        var result = [Double](repeating: 0, count: vector.count)
        reciprocal(vector, result: &result)
        return result
    }

    public static func reciprocal<U>(_ vector: U) -> [Float] where U: AccelerateBuffer, U.Element == Float {
        var result = [Float](repeating: 0, count: vector.count)
        reciprocal(vector, result: &result)
        return result
    }

    public static func nearestInteger<U, V>(_ vector: U, result: inout V) where U: AccelerateBuffer, V: AccelerateMutableBuffer, U.Element == Double, V.Element == Double {
        mapUnary(vector, &result, { $0.rounded(.toNearestOrEven) })
    }

    public static func nearestInteger<U, V>(_ vector: U, result: inout V) where U: AccelerateBuffer, V: AccelerateMutableBuffer, U.Element == Float, V.Element == Float {
        mapUnary(vector, &result, { $0.rounded(.toNearestOrEven) })
    }

    public static func nearestInteger<U>(_ vector: U) -> [Double] where U: AccelerateBuffer, U.Element == Double {
        var result = [Double](repeating: 0, count: vector.count)
        nearestInteger(vector, result: &result)
        return result
    }

    public static func nearestInteger<U>(_ vector: U) -> [Float] where U: AccelerateBuffer, U.Element == Float {
        var result = [Float](repeating: 0, count: vector.count)
        nearestInteger(vector, result: &result)
        return result
    }

    public static func truncatingRemainder<T, U, V>(dividends: T, divisors: U, result: inout V) where T: AccelerateBuffer, U: AccelerateBuffer, V: AccelerateMutableBuffer, T.Element == Double, U.Element == Double, V.Element == Double {
        mapBinary(dividends, divisors, &result, { $0.truncatingRemainder(dividingBy: $1) })
    }

    public static func truncatingRemainder<T, U, V>(dividends: T, divisors: U, result: inout V) where T: AccelerateBuffer, U: AccelerateBuffer, V: AccelerateMutableBuffer, T.Element == Float, U.Element == Float, V.Element == Float {
        mapBinary(dividends, divisors, &result, { $0.truncatingRemainder(dividingBy: $1) })
    }

    public static func truncatingRemainder<U, V>(dividends: U, divisors: V) -> [Double] where U: AccelerateBuffer, V: AccelerateMutableBuffer, U.Element == Double, V.Element == Double {
        var result = [Double](repeating: 0, count: dividends.count)
        truncatingRemainder(dividends: dividends, divisors: divisors, result: &result)
        return result
    }

    public static func truncatingRemainder<U, V>(dividends: U, divisors: V) -> [Float] where U: AccelerateBuffer, V: AccelerateMutableBuffer, U.Element == Float, V.Element == Float {
        var result = [Float](repeating: 0, count: dividends.count)
        truncatingRemainder(dividends: dividends, divisors: divisors, result: &result)
        return result
    }

    public static func cos<U, V>(_ vector: U, result: inout V) where U: AccelerateBuffer, V: AccelerateMutableBuffer, U.Element == Double, V.Element == Double {
        mapUnary(vector, &result, Foundation.cos)
    }

    public static func cos<U, V>(_ vector: U, result: inout V) where U: AccelerateBuffer, V: AccelerateMutableBuffer, U.Element == Float, V.Element == Float {
        mapUnary(vector, &result, Foundation.cos)
    }

    public static func cos<U>(_ vector: U) -> [Double] where U: AccelerateBuffer, U.Element == Double {
        var result = [Double](repeating: 0, count: vector.count)
        cos(vector, result: &result)
        return result
    }

    public static func cos<U>(_ vector: U) -> [Float] where U: AccelerateBuffer, U.Element == Float {
        var result = [Float](repeating: 0, count: vector.count)
        cos(vector, result: &result)
        return result
    }

    public static func exp<U, V>(_ vector: U, result: inout V) where U: AccelerateBuffer, V: AccelerateMutableBuffer, U.Element == Double, V.Element == Double {
        mapUnary(vector, &result, Foundation.exp)
    }

    public static func exp<U, V>(_ vector: U, result: inout V) where U: AccelerateBuffer, V: AccelerateMutableBuffer, U.Element == Float, V.Element == Float {
        mapUnary(vector, &result, Foundation.exp)
    }

    public static func exp<U>(_ vector: U) -> [Double] where U: AccelerateBuffer, U.Element == Double {
        var result = [Double](repeating: 0, count: vector.count)
        exp(vector, result: &result)
        return result
    }

    public static func exp<U>(_ vector: U) -> [Float] where U: AccelerateBuffer, U.Element == Float {
        var result = [Float](repeating: 0, count: vector.count)
        exp(vector, result: &result)
        return result
    }

    public static func log<U, V>(_ vector: U, result: inout V) where U: AccelerateBuffer, V: AccelerateMutableBuffer, U.Element == Double, V.Element == Double {
        mapUnary(vector, &result, Foundation.log)
    }

    public static func log<U, V>(_ vector: U, result: inout V) where U: AccelerateBuffer, V: AccelerateMutableBuffer, U.Element == Float, V.Element == Float {
        mapUnary(vector, &result, Foundation.log)
    }

    public static func log<U>(_ vector: U) -> [Double] where U: AccelerateBuffer, U.Element == Double {
        var result = [Double](repeating: 0, count: vector.count)
        log(vector, result: &result)
        return result
    }

    public static func log<U>(_ vector: U) -> [Float] where U: AccelerateBuffer, U.Element == Float {
        var result = [Float](repeating: 0, count: vector.count)
        log(vector, result: &result)
        return result
    }

    public static func pow<T, U, V>(bases: T, exponents: U, result: inout V) where T: AccelerateBuffer, U: AccelerateBuffer, V: AccelerateMutableBuffer, T.Element == Double, U.Element == Double, V.Element == Double {
        mapBinary(bases, exponents, &result, Foundation.pow)
    }

    public static func pow<T, U, V>(bases: T, exponents: U, result: inout V) where T: AccelerateBuffer, U: AccelerateBuffer, V: AccelerateMutableBuffer, T.Element == Float, U.Element == Float, V.Element == Float {
        mapBinary(bases, exponents, &result, Foundation.pow)
    }

    public static func pow<U, V>(bases: U, exponents: V) -> [Double] where U: AccelerateBuffer, V: AccelerateMutableBuffer, U.Element == Double, V.Element == Double {
        var result = [Double](repeating: 0, count: bases.count)
        pow(bases: bases, exponents: exponents, result: &result)
        return result
    }

    public static func pow<U, V>(bases: U, exponents: V) -> [Float] where U: AccelerateBuffer, V: AccelerateMutableBuffer, U.Element == Float, V.Element == Float {
        var result = [Float](repeating: 0, count: bases.count)
        pow(bases: bases, exponents: exponents, result: &result)
        return result
    }

    public static func sin<U, V>(_ vector: U, result: inout V) where U: AccelerateBuffer, V: AccelerateMutableBuffer, U.Element == Double, V.Element == Double {
        mapUnary(vector, &result, Foundation.sin)
    }

    public static func sin<U, V>(_ vector: U, result: inout V) where U: AccelerateBuffer, V: AccelerateMutableBuffer, U.Element == Float, V.Element == Float {
        mapUnary(vector, &result, Foundation.sin)
    }

    public static func sin<U>(_ vector: U) -> [Double] where U: AccelerateBuffer, U.Element == Double {
        var result = [Double](repeating: 0, count: vector.count)
        sin(vector, result: &result)
        return result
    }

    public static func sin<U>(_ vector: U) -> [Float] where U: AccelerateBuffer, U.Element == Float {
        var result = [Float](repeating: 0, count: vector.count)
        sin(vector, result: &result)
        return result
    }

    public static func tan<U, V>(_ vector: U, result: inout V) where U: AccelerateBuffer, V: AccelerateMutableBuffer, U.Element == Double, V.Element == Double {
        mapUnary(vector, &result, Foundation.tan)
    }

    public static func tan<U, V>(_ vector: U, result: inout V) where U: AccelerateBuffer, V: AccelerateMutableBuffer, U.Element == Float, V.Element == Float {
        mapUnary(vector, &result, Foundation.tan)
    }

    public static func tan<U>(_ vector: U) -> [Double] where U: AccelerateBuffer, U.Element == Double {
        var result = [Double](repeating: 0, count: vector.count)
        tan(vector, result: &result)
        return result
    }

    public static func tan<U>(_ vector: U) -> [Float] where U: AccelerateBuffer, U.Element == Float {
        var result = [Float](repeating: 0, count: vector.count)
        tan(vector, result: &result)
        return result
    }

    public static func acos<U, V>(_ vector: U, result: inout V) where U: AccelerateBuffer, V: AccelerateMutableBuffer, U.Element == Double, V.Element == Double {
        mapUnary(vector, &result, Foundation.acos)
    }

    public static func acos<U, V>(_ vector: U, result: inout V) where U: AccelerateBuffer, V: AccelerateMutableBuffer, U.Element == Float, V.Element == Float {
        mapUnary(vector, &result, Foundation.acos)
    }

    public static func acos<U>(_ vector: U) -> [Double] where U: AccelerateBuffer, U.Element == Double {
        var result = [Double](repeating: 0, count: vector.count)
        acos(vector, result: &result)
        return result
    }

    public static func acos<U>(_ vector: U) -> [Float] where U: AccelerateBuffer, U.Element == Float {
        var result = [Float](repeating: 0, count: vector.count)
        acos(vector, result: &result)
        return result
    }

    public static func asin<U, V>(_ vector: U, result: inout V) where U: AccelerateBuffer, V: AccelerateMutableBuffer, U.Element == Double, V.Element == Double {
        mapUnary(vector, &result, Foundation.asin)
    }

    public static func asin<U, V>(_ vector: U, result: inout V) where U: AccelerateBuffer, V: AccelerateMutableBuffer, U.Element == Float, V.Element == Float {
        mapUnary(vector, &result, Foundation.asin)
    }

    public static func asin<U>(_ vector: U) -> [Double] where U: AccelerateBuffer, U.Element == Double {
        var result = [Double](repeating: 0, count: vector.count)
        asin(vector, result: &result)
        return result
    }

    public static func asin<U>(_ vector: U) -> [Float] where U: AccelerateBuffer, U.Element == Float {
        var result = [Float](repeating: 0, count: vector.count)
        asin(vector, result: &result)
        return result
    }

    public static func atan<U, V>(_ vector: U, result: inout V) where U: AccelerateBuffer, V: AccelerateMutableBuffer, U.Element == Double, V.Element == Double {
        mapUnary(vector, &result, Foundation.atan)
    }

    public static func atan<U, V>(_ vector: U, result: inout V) where U: AccelerateBuffer, V: AccelerateMutableBuffer, U.Element == Float, V.Element == Float {
        mapUnary(vector, &result, Foundation.atan)
    }

    public static func atan<U>(_ vector: U) -> [Double] where U: AccelerateBuffer, U.Element == Double {
        var result = [Double](repeating: 0, count: vector.count)
        atan(vector, result: &result)
        return result
    }

    public static func atan<U>(_ vector: U) -> [Float] where U: AccelerateBuffer, U.Element == Float {
        var result = [Float](repeating: 0, count: vector.count)
        atan(vector, result: &result)
        return result
    }

    public static func ceil<U, V>(_ vector: U, result: inout V) where U: AccelerateBuffer, V: AccelerateMutableBuffer, U.Element == Double, V.Element == Double {
        mapUnary(vector, &result, Foundation.ceil)
    }

    public static func ceil<U, V>(_ vector: U, result: inout V) where U: AccelerateBuffer, V: AccelerateMutableBuffer, U.Element == Float, V.Element == Float {
        mapUnary(vector, &result, Foundation.ceil)
    }

    public static func ceil<U>(_ vector: U) -> [Double] where U: AccelerateBuffer, U.Element == Double {
        var result = [Double](repeating: 0, count: vector.count)
        ceil(vector, result: &result)
        return result
    }

    public static func ceil<U>(_ vector: U) -> [Float] where U: AccelerateBuffer, U.Element == Float {
        var result = [Float](repeating: 0, count: vector.count)
        ceil(vector, result: &result)
        return result
    }

    public static func cosh<U, V>(_ vector: U, result: inout V) where U: AccelerateBuffer, V: AccelerateMutableBuffer, U.Element == Double, V.Element == Double {
        mapUnary(vector, &result, Foundation.cosh)
    }

    public static func cosh<U, V>(_ vector: U, result: inout V) where U: AccelerateBuffer, V: AccelerateMutableBuffer, U.Element == Float, V.Element == Float {
        mapUnary(vector, &result, Foundation.cosh)
    }

    public static func cosh<U>(_ vector: U) -> [Double] where U: AccelerateBuffer, U.Element == Double {
        var result = [Double](repeating: 0, count: vector.count)
        cosh(vector, result: &result)
        return result
    }

    public static func cosh<U>(_ vector: U) -> [Float] where U: AccelerateBuffer, U.Element == Float {
        var result = [Float](repeating: 0, count: vector.count)
        cosh(vector, result: &result)
        return result
    }

    public static func exp2<U, V>(_ vector: U, result: inout V) where U: AccelerateBuffer, V: AccelerateMutableBuffer, U.Element == Double, V.Element == Double {
        mapUnary(vector, &result, Foundation.exp2)
    }

    public static func exp2<U, V>(_ vector: U, result: inout V) where U: AccelerateBuffer, V: AccelerateMutableBuffer, U.Element == Float, V.Element == Float {
        mapUnary(vector, &result, Foundation.exp2)
    }

    public static func exp2<U>(_ vector: U) -> [Double] where U: AccelerateBuffer, U.Element == Double {
        var result = [Double](repeating: 0, count: vector.count)
        exp2(vector, result: &result)
        return result
    }

    public static func exp2<U>(_ vector: U) -> [Float] where U: AccelerateBuffer, U.Element == Float {
        var result = [Float](repeating: 0, count: vector.count)
        exp2(vector, result: &result)
        return result
    }

    public static func log2<U, V>(_ vector: U, result: inout V) where U: AccelerateBuffer, V: AccelerateMutableBuffer, U.Element == Double, V.Element == Double {
        mapUnary(vector, &result, Foundation.log2)
    }

    public static func log2<U, V>(_ vector: U, result: inout V) where U: AccelerateBuffer, V: AccelerateMutableBuffer, U.Element == Float, V.Element == Float {
        mapUnary(vector, &result, Foundation.log2)
    }

    public static func log2<U>(_ vector: U) -> [Double] where U: AccelerateBuffer, U.Element == Double {
        var result = [Double](repeating: 0, count: vector.count)
        log2(vector, result: &result)
        return result
    }

    public static func log2<U>(_ vector: U) -> [Float] where U: AccelerateBuffer, U.Element == Float {
        var result = [Float](repeating: 0, count: vector.count)
        log2(vector, result: &result)
        return result
    }

    public static func logb<U, V>(_ vector: U, result: inout V) where U: AccelerateBuffer, V: AccelerateMutableBuffer, U.Element == Double, V.Element == Double {
        mapUnary(vector, &result, Foundation.logb)
    }

    public static func logb<U, V>(_ vector: U, result: inout V) where U: AccelerateBuffer, V: AccelerateMutableBuffer, U.Element == Float, V.Element == Float {
        mapUnary(vector, &result, Foundation.logb)
    }

    public static func logb<U>(_ vector: U) -> [Double] where U: AccelerateBuffer, U.Element == Double {
        var result = [Double](repeating: 0, count: vector.count)
        logb(vector, result: &result)
        return result
    }

    public static func logb<U>(_ vector: U) -> [Float] where U: AccelerateBuffer, U.Element == Float {
        var result = [Float](repeating: 0, count: vector.count)
        logb(vector, result: &result)
        return result
    }

    public static func sinh<U, V>(_ vector: U, result: inout V) where U: AccelerateBuffer, V: AccelerateMutableBuffer, U.Element == Double, V.Element == Double {
        mapUnary(vector, &result, Foundation.sinh)
    }

    public static func sinh<U, V>(_ vector: U, result: inout V) where U: AccelerateBuffer, V: AccelerateMutableBuffer, U.Element == Float, V.Element == Float {
        mapUnary(vector, &result, Foundation.sinh)
    }

    public static func sinh<U>(_ vector: U) -> [Double] where U: AccelerateBuffer, U.Element == Double {
        var result = [Double](repeating: 0, count: vector.count)
        sinh(vector, result: &result)
        return result
    }

    public static func sinh<U>(_ vector: U) -> [Float] where U: AccelerateBuffer, U.Element == Float {
        var result = [Float](repeating: 0, count: vector.count)
        sinh(vector, result: &result)
        return result
    }

    public static func sqrt<U, V>(_ vector: U, result: inout V) where U: AccelerateBuffer, V: AccelerateMutableBuffer, U.Element == Double, V.Element == Double {
        mapUnary(vector, &result, Foundation.sqrt)
    }

    public static func sqrt<U, V>(_ vector: U, result: inout V) where U: AccelerateBuffer, V: AccelerateMutableBuffer, U.Element == Float, V.Element == Float {
        mapUnary(vector, &result, Foundation.sqrt)
    }

    public static func sqrt<U>(_ vector: U) -> [Double] where U: AccelerateBuffer, U.Element == Double {
        var result = [Double](repeating: 0, count: vector.count)
        sqrt(vector, result: &result)
        return result
    }

    public static func sqrt<U>(_ vector: U) -> [Float] where U: AccelerateBuffer, U.Element == Float {
        var result = [Float](repeating: 0, count: vector.count)
        sqrt(vector, result: &result)
        return result
    }

    public static func tanh<U, V>(_ vector: U, result: inout V) where U: AccelerateBuffer, V: AccelerateMutableBuffer, U.Element == Double, V.Element == Double {
        mapUnary(vector, &result, Foundation.tanh)
    }

    public static func tanh<U, V>(_ vector: U, result: inout V) where U: AccelerateBuffer, V: AccelerateMutableBuffer, U.Element == Float, V.Element == Float {
        mapUnary(vector, &result, Foundation.tanh)
    }

    public static func tanh<U>(_ vector: U) -> [Double] where U: AccelerateBuffer, U.Element == Double {
        var result = [Double](repeating: 0, count: vector.count)
        tanh(vector, result: &result)
        return result
    }

    public static func tanh<U>(_ vector: U) -> [Float] where U: AccelerateBuffer, U.Element == Float {
        var result = [Float](repeating: 0, count: vector.count)
        tanh(vector, result: &result)
        return result
    }

    public static func acosh<U, V>(_ vector: U, result: inout V) where U: AccelerateBuffer, V: AccelerateMutableBuffer, U.Element == Double, V.Element == Double {
        mapUnary(vector, &result, Foundation.acosh)
    }

    public static func acosh<U, V>(_ vector: U, result: inout V) where U: AccelerateBuffer, V: AccelerateMutableBuffer, U.Element == Float, V.Element == Float {
        mapUnary(vector, &result, Foundation.acosh)
    }

    public static func acosh<U>(_ vector: U) -> [Double] where U: AccelerateBuffer, U.Element == Double {
        var result = [Double](repeating: 0, count: vector.count)
        acosh(vector, result: &result)
        return result
    }

    public static func acosh<U>(_ vector: U) -> [Float] where U: AccelerateBuffer, U.Element == Float {
        var result = [Float](repeating: 0, count: vector.count)
        acosh(vector, result: &result)
        return result
    }

    public static func asinh<U, V>(_ vector: U, result: inout V) where U: AccelerateBuffer, V: AccelerateMutableBuffer, U.Element == Double, V.Element == Double {
        mapUnary(vector, &result, Foundation.asinh)
    }

    public static func asinh<U, V>(_ vector: U, result: inout V) where U: AccelerateBuffer, V: AccelerateMutableBuffer, U.Element == Float, V.Element == Float {
        mapUnary(vector, &result, Foundation.asinh)
    }

    public static func asinh<U>(_ vector: U) -> [Double] where U: AccelerateBuffer, U.Element == Double {
        var result = [Double](repeating: 0, count: vector.count)
        asinh(vector, result: &result)
        return result
    }

    public static func asinh<U>(_ vector: U) -> [Float] where U: AccelerateBuffer, U.Element == Float {
        var result = [Float](repeating: 0, count: vector.count)
        asinh(vector, result: &result)
        return result
    }

    public static func atan2<T, U, V>(x: T, y: U, result: inout V) where T: AccelerateBuffer, U: AccelerateBuffer, V: AccelerateMutableBuffer, T.Element == Double, U.Element == Double, V.Element == Double {
        mapBinary(y, x, &result, Foundation.atan2)
    }

    public static func atan2<T, U, V>(x: T, y: U, result: inout V) where T: AccelerateBuffer, U: AccelerateBuffer, V: AccelerateMutableBuffer, T.Element == Float, U.Element == Float, V.Element == Float {
        mapBinary(y, x, &result, Foundation.atan2)
    }

    public static func atan2<U, V>(x: U, y: V) -> [Double] where U: AccelerateBuffer, V: AccelerateMutableBuffer, U.Element == Double, V.Element == Double {
        var result = [Double](repeating: 0, count: x.count)
        atan2(x: x, y: y, result: &result)
        return result
    }

    public static func atan2<U, V>(x: U, y: V) -> [Float] where U: AccelerateBuffer, V: AccelerateMutableBuffer, U.Element == Float, V.Element == Float {
        var result = [Float](repeating: 0, count: x.count)
        atan2(x: x, y: y, result: &result)
        return result
    }

    public static func atanh<U, V>(_ vector: U, result: inout V) where U: AccelerateBuffer, V: AccelerateMutableBuffer, U.Element == Double, V.Element == Double {
        mapUnary(vector, &result, Foundation.atanh)
    }

    public static func atanh<U, V>(_ vector: U, result: inout V) where U: AccelerateBuffer, V: AccelerateMutableBuffer, U.Element == Float, V.Element == Float {
        mapUnary(vector, &result, Foundation.atanh)
    }

    public static func atanh<U>(_ vector: U) -> [Double] where U: AccelerateBuffer, U.Element == Double {
        var result = [Double](repeating: 0, count: vector.count)
        atanh(vector, result: &result)
        return result
    }

    public static func atanh<U>(_ vector: U) -> [Float] where U: AccelerateBuffer, U.Element == Float {
        var result = [Float](repeating: 0, count: vector.count)
        atanh(vector, result: &result)
        return result
    }

    public static func cosPi<U, V>(_ vector: U, result: inout V) where U: AccelerateBuffer, V: AccelerateMutableBuffer, U.Element == Double, V.Element == Double {
        mapUnary(vector, &result, { Foundation.cos($0 * .pi) })
    }

    public static func cosPi<U, V>(_ vector: U, result: inout V) where U: AccelerateBuffer, V: AccelerateMutableBuffer, U.Element == Float, V.Element == Float {
        mapUnary(vector, &result, { Foundation.cos($0 * .pi) })
    }

    public static func cosPi<U>(_ vector: U) -> [Double] where U: AccelerateBuffer, U.Element == Double {
        var result = [Double](repeating: 0, count: vector.count)
        cosPi(vector, result: &result)
        return result
    }

    public static func cosPi<U>(_ vector: U) -> [Float] where U: AccelerateBuffer, U.Element == Float {
        var result = [Float](repeating: 0, count: vector.count)
        cosPi(vector, result: &result)
        return result
    }

    public static func expm1<U, V>(_ vector: U, result: inout V) where U: AccelerateBuffer, V: AccelerateMutableBuffer, U.Element == Double, V.Element == Double {
        mapUnary(vector, &result, Foundation.expm1)
    }

    public static func expm1<U, V>(_ vector: U, result: inout V) where U: AccelerateBuffer, V: AccelerateMutableBuffer, U.Element == Float, V.Element == Float {
        mapUnary(vector, &result, Foundation.expm1)
    }

    public static func expm1<U>(_ vector: U) -> [Double] where U: AccelerateBuffer, U.Element == Double {
        var result = [Double](repeating: 0, count: vector.count)
        expm1(vector, result: &result)
        return result
    }

    public static func expm1<U>(_ vector: U) -> [Float] where U: AccelerateBuffer, U.Element == Float {
        var result = [Float](repeating: 0, count: vector.count)
        expm1(vector, result: &result)
        return result
    }

    public static func floor<U, V>(_ vector: U, result: inout V) where U: AccelerateBuffer, V: AccelerateMutableBuffer, U.Element == Double, V.Element == Double {
        mapUnary(vector, &result, Foundation.floor)
    }

    public static func floor<U, V>(_ vector: U, result: inout V) where U: AccelerateBuffer, V: AccelerateMutableBuffer, U.Element == Float, V.Element == Float {
        mapUnary(vector, &result, Foundation.floor)
    }

    public static func floor<U>(_ vector: U) -> [Double] where U: AccelerateBuffer, U.Element == Double {
        var result = [Double](repeating: 0, count: vector.count)
        floor(vector, result: &result)
        return result
    }

    public static func floor<U>(_ vector: U) -> [Float] where U: AccelerateBuffer, U.Element == Float {
        var result = [Float](repeating: 0, count: vector.count)
        floor(vector, result: &result)
        return result
    }

    public static func log10<U, V>(_ vector: U, result: inout V) where U: AccelerateBuffer, V: AccelerateMutableBuffer, U.Element == Double, V.Element == Double {
        mapUnary(vector, &result, Foundation.log10)
    }

    public static func log10<U, V>(_ vector: U, result: inout V) where U: AccelerateBuffer, V: AccelerateMutableBuffer, U.Element == Float, V.Element == Float {
        mapUnary(vector, &result, Foundation.log10)
    }

    public static func log10<U>(_ vector: U) -> [Double] where U: AccelerateBuffer, U.Element == Double {
        var result = [Double](repeating: 0, count: vector.count)
        log10(vector, result: &result)
        return result
    }

    public static func log10<U>(_ vector: U) -> [Float] where U: AccelerateBuffer, U.Element == Float {
        var result = [Float](repeating: 0, count: vector.count)
        log10(vector, result: &result)
        return result
    }

    public static func log1p<U, V>(_ vector: U, result: inout V) where U: AccelerateBuffer, V: AccelerateMutableBuffer, U.Element == Double, V.Element == Double {
        mapUnary(vector, &result, Foundation.log1p)
    }

    public static func log1p<U, V>(_ vector: U, result: inout V) where U: AccelerateBuffer, V: AccelerateMutableBuffer, U.Element == Float, V.Element == Float {
        mapUnary(vector, &result, Foundation.log1p)
    }

    public static func log1p<U>(_ vector: U) -> [Double] where U: AccelerateBuffer, U.Element == Double {
        var result = [Double](repeating: 0, count: vector.count)
        log1p(vector, result: &result)
        return result
    }

    public static func log1p<U>(_ vector: U) -> [Float] where U: AccelerateBuffer, U.Element == Float {
        var result = [Float](repeating: 0, count: vector.count)
        log1p(vector, result: &result)
        return result
    }

    public static func rsqrt<U, V>(_ vector: U, result: inout V) where U: AccelerateBuffer, V: AccelerateMutableBuffer, U.Element == Double, V.Element == Double {
        mapUnary(vector, &result, { 1 / Foundation.sqrt($0) })
    }

    public static func rsqrt<U, V>(_ vector: U, result: inout V) where U: AccelerateBuffer, V: AccelerateMutableBuffer, U.Element == Float, V.Element == Float {
        mapUnary(vector, &result, { 1 / Foundation.sqrt($0) })
    }

    public static func rsqrt<U>(_ vector: U) -> [Double] where U: AccelerateBuffer, U.Element == Double {
        var result = [Double](repeating: 0, count: vector.count)
        rsqrt(vector, result: &result)
        return result
    }

    public static func rsqrt<U>(_ vector: U) -> [Float] where U: AccelerateBuffer, U.Element == Float {
        var result = [Float](repeating: 0, count: vector.count)
        rsqrt(vector, result: &result)
        return result
    }

    public static func sinPi<U, V>(_ vector: U, result: inout V) where U: AccelerateBuffer, V: AccelerateMutableBuffer, U.Element == Double, V.Element == Double {
        mapUnary(vector, &result, { Foundation.sin($0 * .pi) })
    }

    public static func sinPi<U, V>(_ vector: U, result: inout V) where U: AccelerateBuffer, V: AccelerateMutableBuffer, U.Element == Float, V.Element == Float {
        mapUnary(vector, &result, { Foundation.sin($0 * .pi) })
    }

    public static func sinPi<U>(_ vector: U) -> [Double] where U: AccelerateBuffer, U.Element == Double {
        var result = [Double](repeating: 0, count: vector.count)
        sinPi(vector, result: &result)
        return result
    }

    public static func sinPi<U>(_ vector: U) -> [Float] where U: AccelerateBuffer, U.Element == Float {
        var result = [Float](repeating: 0, count: vector.count)
        sinPi(vector, result: &result)
        return result
    }

    public static func tanPi<U, V>(_ vector: U, result: inout V) where U: AccelerateBuffer, V: AccelerateMutableBuffer, U.Element == Double, V.Element == Double {
        mapUnary(vector, &result, { Foundation.tan($0 * .pi) })
    }

    public static func tanPi<U, V>(_ vector: U, result: inout V) where U: AccelerateBuffer, V: AccelerateMutableBuffer, U.Element == Float, V.Element == Float {
        mapUnary(vector, &result, { Foundation.tan($0 * .pi) })
    }

    public static func tanPi<U>(_ vector: U) -> [Double] where U: AccelerateBuffer, U.Element == Double {
        var result = [Double](repeating: 0, count: vector.count)
        tanPi(vector, result: &result)
        return result
    }

    public static func tanPi<U>(_ vector: U) -> [Float] where U: AccelerateBuffer, U.Element == Float {
        var result = [Float](repeating: 0, count: vector.count)
        tanPi(vector, result: &result)
        return result
    }

    public static func trunc<U, V>(_ vector: U, result: inout V) where U: AccelerateBuffer, V: AccelerateMutableBuffer, U.Element == Double, V.Element == Double {
        mapUnary(vector, &result, Foundation.trunc)
    }

    public static func trunc<U, V>(_ vector: U, result: inout V) where U: AccelerateBuffer, V: AccelerateMutableBuffer, U.Element == Float, V.Element == Float {
        mapUnary(vector, &result, Foundation.trunc)
    }

    public static func trunc<U>(_ vector: U) -> [Double] where U: AccelerateBuffer, U.Element == Double {
        var result = [Double](repeating: 0, count: vector.count)
        trunc(vector, result: &result)
        return result
    }

    public static func trunc<U>(_ vector: U) -> [Float] where U: AccelerateBuffer, U.Element == Float {
        var result = [Float](repeating: 0, count: vector.count)
        trunc(vector, result: &result)
        return result
    }

    public static func sincos<T, U, V>(_ vector: T, sinResult: inout U, cosResult: inout V) where T: AccelerateBuffer, U: AccelerateMutableBuffer, V: AccelerateMutableBuffer, T.Element == Double, U.Element == Double, V.Element == Double {
        vector.withUnsafeBufferPointer { src in
            sinResult.withUnsafeMutableBufferPointer { s in
                cosResult.withUnsafeMutableBufferPointer { c in
                    let n = min(src.count, min(s.count, c.count))
                    for i in 0..<n {
                        s[i] = Foundation.sin(src[i])
                        c[i] = Foundation.cos(src[i])
                    }
                }
            }
        }
    }

    public static func sincos<T, U, V>(_ vector: T, sinResult: inout U, cosResult: inout V) where T: AccelerateBuffer, U: AccelerateMutableBuffer, V: AccelerateMutableBuffer, T.Element == Float, U.Element == Float, V.Element == Float {
        vector.withUnsafeBufferPointer { src in
            sinResult.withUnsafeMutableBufferPointer { s in
                cosResult.withUnsafeMutableBufferPointer { c in
                    let n = min(src.count, min(s.count, c.count))
                    for i in 0..<n {
                        s[i] = Foundation.sin(src[i])
                        c[i] = Foundation.cos(src[i])
                    }
                }
            }
        }
    }

    public static func copysign<T, U, V>(magnitudes: T, signs: U, result: inout V) where T: AccelerateBuffer, U: AccelerateBuffer, V: AccelerateMutableBuffer, T.Element == Double, U.Element == Double, V.Element == Double {
        mapBinary(magnitudes, signs, &result, Foundation.copysign)
    }

    public static func copysign<T, U, V>(magnitudes: T, signs: U, result: inout V) where T: AccelerateBuffer, U: AccelerateBuffer, V: AccelerateMutableBuffer, T.Element == Float, U.Element == Float, V.Element == Float {
        mapBinary(magnitudes, signs, &result, Foundation.copysign)
    }

    public static func copysign<U, V>(magnitudes: U, signs: V) -> [Double] where U: AccelerateBuffer, V: AccelerateMutableBuffer, U.Element == Double, V.Element == Double {
        var result = [Double](repeating: 0, count: magnitudes.count)
        copysign(magnitudes: magnitudes, signs: signs, result: &result)
        return result
    }

    public static func copysign<U, V>(magnitudes: U, signs: V) -> [Float] where U: AccelerateBuffer, V: AccelerateMutableBuffer, U.Element == Float, V.Element == Float {
        var result = [Float](repeating: 0, count: magnitudes.count)
        copysign(magnitudes: magnitudes, signs: signs, result: &result)
        return result
    }

    public static func remainder<T, U, V>(dividends: T, divisors: U, result: inout V) where T: AccelerateBuffer, U: AccelerateBuffer, V: AccelerateMutableBuffer, T.Element == Double, U.Element == Double, V.Element == Double {
        mapBinary(dividends, divisors, &result, Foundation.remainder)
    }

    public static func remainder<T, U, V>(dividends: T, divisors: U, result: inout V) where T: AccelerateBuffer, U: AccelerateBuffer, V: AccelerateMutableBuffer, T.Element == Float, U.Element == Float, V.Element == Float {
        mapBinary(dividends, divisors, &result, Foundation.remainder)
    }

    public static func remainder<U, V>(dividends: U, divisors: V) -> [Double] where U: AccelerateBuffer, V: AccelerateMutableBuffer, U.Element == Double, V.Element == Double {
        var result = [Double](repeating: 0, count: dividends.count)
        remainder(dividends: dividends, divisors: divisors, result: &result)
        return result
    }

    public static func remainder<U, V>(dividends: U, divisors: V) -> [Float] where U: AccelerateBuffer, V: AccelerateMutableBuffer, U.Element == Float, V.Element == Float {
        var result = [Float](repeating: 0, count: dividends.count)
        remainder(dividends: dividends, divisors: divisors, result: &result)
        return result
    }

}
