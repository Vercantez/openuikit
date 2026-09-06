import Foundation

extension vDSP {
    public static func copy<U>(_ vector: U) -> [Float] where U: AccelerateBuffer, U.Element == Float {
        var result = [Float](repeating: 0, count: vector.count)
        vector.withUnsafeBufferPointer { src in
            for i in 0..<src.count { result[i] = src[i] }
        }
        return result
    }

    public static func copy<U>(_ vector: U) -> [Double] where U: AccelerateBuffer, U.Element == Double {
        var result = [Double](repeating: 0, count: vector.count)
        vector.withUnsafeBufferPointer { src in
            for i in 0..<src.count { result[i] = src[i] }
        }
        return result
    }

    public static func window<T>(ofType: T.Type, usingSequence sequence: vDSP.WindowSequence, count: Int, isHalfWindow: Bool) -> [T] where T: vDSP_FloatingPointGeneratable {
        _ = ofType
        if T.self == Float.self {
            var result = [Float](repeating: 0, count: count)
            formWindow(usingSequence: sequence, result: &result, isHalfWindow: isHalfWindow)
            return result as! [T]
        }
        var result = [Double](repeating: 0, count: count)
        formWindow(usingSequence: sequence, result: &result, isHalfWindow: isHalfWindow)
        return result as! [T]
    }

    public static func polarToRectangular<U>(_ polarCoordinates: U) -> [Float] where U: AccelerateBuffer, U.Element == Float {
        var out = [Float](repeating: 0, count: polarCoordinates.count)
        polarCoordinates.withUnsafeBufferPointer { src in
            let n = src.count / 2
            for i in 0..<n {
                let rho = src[i]
                let theta = src[i + n]
                out[i] = rho * Foundation.cos(theta)
                out[i + n] = rho * Foundation.sin(theta)
            }
        }
        return out
    }

    public static func polarToRectangular<U>(_ polarCoordinates: U) -> [Double] where U: AccelerateBuffer, U.Element == Double {
        var out = [Double](repeating: 0, count: polarCoordinates.count)
        polarCoordinates.withUnsafeBufferPointer { src in
            let n = src.count / 2
            for i in 0..<n {
                let rho = src[i]
                let theta = src[i + n]
                out[i] = rho * Foundation.cos(theta)
                out[i + n] = rho * Foundation.sin(theta)
            }
        }
        return out
    }

    public static func rectangularToPolar<U>(_ rectangularCoordinates: U) -> [Float] where U: AccelerateBuffer, U.Element == Float {
        var out = [Float](repeating: 0, count: rectangularCoordinates.count)
        rectangularCoordinates.withUnsafeBufferPointer { src in
            let n = src.count / 2
            for i in 0..<n {
                let x = src[i]
                let y = src[i + n]
                out[i] = Foundation.sqrt(x * x + y * y)
                out[i + n] = Foundation.atan2(y, x)
            }
        }
        return out
    }

    public static func rectangularToPolar<U>(_ rectangularCoordinates: U) -> [Double] where U: AccelerateBuffer, U.Element == Double {
        var out = [Double](repeating: 0, count: rectangularCoordinates.count)
        rectangularCoordinates.withUnsafeBufferPointer { src in
            let n = src.count / 2
            for i in 0..<n {
                let x = src[i]
                let y = src[i + n]
                out[i] = Foundation.sqrt(x * x + y * y)
                out[i + n] = Foundation.atan2(y, x)
            }
        }
        return out
    }

    public static func taperedMerge<T, U, V>(_ vectorA: T, _ vectorB: U, result: inout V)
    where T: AccelerateBuffer, U: AccelerateBuffer, V: AccelerateMutableBuffer, T.Element == Float, U.Element == Float, V.Element == Float {
        vectorA.withUnsafeBufferPointer { a in
            vectorB.withUnsafeBufferPointer { b in
                result.withUnsafeMutableBufferPointer { dest in
                    let n = min(a.count, min(b.count, dest.count))
                    let denom = Float(max(n - 1, 1))
                    for i in 0..<n {
                        let t = Float(i) / denom
                        dest[i] = a[i] * (1 - t) + b[i] * t
                    }
                }
            }
        }
    }

    public static func taperedMerge<T, U>(_ vectorA: T, _ vectorB: U) -> [Float]
    where T: AccelerateBuffer, U: AccelerateBuffer, T.Element == Float, U.Element == Float {
        var result = [Float](repeating: 0, count: vectorA.count)
        taperedMerge(vectorA, vectorB, result: &result)
        return result
    }

    public static func taperedMerge<T, U, V>(_ vectorA: T, _ vectorB: U, result: inout V)
    where T: AccelerateBuffer, U: AccelerateBuffer, V: AccelerateMutableBuffer, T.Element == Double, U.Element == Double, V.Element == Double {
        vectorA.withUnsafeBufferPointer { a in
            vectorB.withUnsafeBufferPointer { b in
                result.withUnsafeMutableBufferPointer { dest in
                    let n = min(a.count, min(b.count, dest.count))
                    let denom = Double(max(n - 1, 1))
                    for i in 0..<n {
                        let t = Double(i) / denom
                        dest[i] = a[i] * (1 - t) + b[i] * t
                    }
                }
            }
        }
    }

    public static func taperedMerge<T, U>(_ vectorA: T, _ vectorB: U) -> [Double]
    where T: AccelerateBuffer, U: AccelerateBuffer, T.Element == Double, U.Element == Double {
        var result = [Double](repeating: 0, count: vectorA.count)
        taperedMerge(vectorA, vectorB, result: &result)
        return result
    }

    public static func compress<T, U, V>(_ vector: T, gatingVector: U, threshold: Float, result: inout V)
    where T: AccelerateBuffer, U: AccelerateBuffer, V: AccelerateMutableBuffer, T.Element == Float, U.Element == Float, V.Element == Float {
        vector.withUnsafeBufferPointer { src in
            gatingVector.withUnsafeBufferPointer { gate in
                result.withUnsafeMutableBufferPointer { dest in
                    var o = 0
                    let n = min(src.count, gate.count)
                    for i in 0..<n where gate[i] >= threshold && o < dest.count {
                        dest[o] = src[i]
                        o += 1
                    }
                }
            }
        }
    }

    public static func compress<T, U>(_ vector: T, gatingVector: U, threshold: Float) -> [Float]
    where T: AccelerateBuffer, U: AccelerateBuffer, T.Element == Float, U.Element == Float {
        var tmp = [Float](repeating: 0, count: vector.count)
        compress(vector, gatingVector: gatingVector, threshold: threshold, result: &tmp)
        return tmp
    }

    public static func compress<T, U, V>(_ vector: T, gatingVector: U, threshold: Double, result: inout V)
    where T: AccelerateBuffer, U: AccelerateBuffer, V: AccelerateMutableBuffer, T.Element == Double, U.Element == Double, V.Element == Double {
        vector.withUnsafeBufferPointer { src in
            gatingVector.withUnsafeBufferPointer { gate in
                result.withUnsafeMutableBufferPointer { dest in
                    var o = 0
                    let n = min(src.count, gate.count)
                    for i in 0..<n where gate[i] >= threshold && o < dest.count {
                        dest[o] = src[i]
                        o += 1
                    }
                }
            }
        }
    }

    public static func compress<T, U>(_ vector: T, gatingVector: U, threshold: Double) -> [Double]
    where T: AccelerateBuffer, U: AccelerateBuffer, T.Element == Double, U.Element == Double {
        var tmp = [Double](repeating: 0, count: vector.count)
        compress(vector, gatingVector: gatingVector, threshold: threshold, result: &tmp)
        return tmp
    }

    public static func twoPoleTwoZeroFilter<U, V>(_ source: U, coefficients: (Float, Float, Float, Float, Float), result: inout V)
    where U: AccelerateBuffer, V: AccelerateMutableBuffer, U.Element == Float, V.Element == Float {
        let (b0, b1, b2, a1, a2) = coefficients
        source.withUnsafeBufferPointer { src in
            result.withUnsafeMutableBufferPointer { dest in
                var x1: Float = 0
                var x2: Float = 0
                var y1: Float = 0
                var y2: Float = 0
                let n = min(src.count, dest.count)
                for i in 0..<n {
                    let x0 = src[i]
                    let y0 = b0 * x0 + b1 * x1 + b2 * x2 - a1 * y1 - a2 * y2
                    dest[i] = y0
                    x2 = x1
                    x1 = x0
                    y2 = y1
                    y1 = y0
                }
            }
        }
    }

    public static func twoPoleTwoZeroFilter<U>(_ source: U, coefficients: (Float, Float, Float, Float, Float)) -> [Float]
    where U: AccelerateBuffer, U.Element == Float {
        var result = [Float](repeating: 0, count: source.count)
        twoPoleTwoZeroFilter(source, coefficients: coefficients, result: &result)
        return result
    }

    public static func twoPoleTwoZeroFilter<U, V>(_ source: U, coefficients: (Double, Double, Double, Double, Double), result: inout V)
    where U: AccelerateBuffer, V: AccelerateMutableBuffer, U.Element == Double, V.Element == Double {
        let (b0, b1, b2, a1, a2) = coefficients
        source.withUnsafeBufferPointer { src in
            result.withUnsafeMutableBufferPointer { dest in
                var x1: Double = 0
                var x2: Double = 0
                var y1: Double = 0
                var y2: Double = 0
                let n = min(src.count, dest.count)
                for i in 0..<n {
                    let x0 = src[i]
                    let y0 = b0 * x0 + b1 * x1 + b2 * x2 - a1 * y1 - a2 * y2
                    dest[i] = y0
                    x2 = x1
                    x1 = x0
                    y2 = y1
                    y1 = y0
                }
            }
        }
    }

    public static func twoPoleTwoZeroFilter<U>(_ source: U, coefficients: (Double, Double, Double, Double, Double)) -> [Double]
    where U: AccelerateBuffer, U.Element == Double {
        var result = [Double](repeating: 0, count: source.count)
        twoPoleTwoZeroFilter(source, coefficients: coefficients, result: &result)
        return result
    }

    public static func phase<V>(_ splitComplex: DSPSplitComplex, result: inout V)
    where V: AccelerateMutableBuffer, V.Element == Float {
        result.withUnsafeMutableBufferPointer { dest in
            for i in dest.indices {
                dest[i] = Foundation.atan2(splitComplex.imagp[i], splitComplex.realp[i])
            }
        }
    }

    public static func phase<V>(_ splitComplex: DSPDoubleSplitComplex, result: inout V)
    where V: AccelerateMutableBuffer, V.Element == Double {
        result.withUnsafeMutableBufferPointer { dest in
            for i in dest.indices {
                dest[i] = Foundation.atan2(splitComplex.imagp[i], splitComplex.realp[i])
            }
        }
    }

    public static func integerToFloatingPoint<T, U>(_ vector: T, floatingPointType: U.Type) -> [U]
    where T: AccelerateBuffer, U: vDSP_FloatingPointConvertable, T.Element == Int8 {
        _ = floatingPointType
        var out: [U] = []
        vector.withUnsafeBufferPointer { src in
            out = src.map { U($0) }
        }
        return out
    }

    public static func integerToFloatingPoint<T, U>(_ vector: T, floatingPointType: U.Type) -> [U]
    where T: AccelerateBuffer, U: vDSP_FloatingPointConvertable, T.Element == Int16 {
        _ = floatingPointType
        var out: [U] = []
        vector.withUnsafeBufferPointer { src in
            out = src.map { U($0) }
        }
        return out
    }

    public static func integerToFloatingPoint<T, U>(_ vector: T, floatingPointType: U.Type) -> [U]
    where T: AccelerateBuffer, U: vDSP_FloatingPointConvertable, T.Element == Int32 {
        _ = floatingPointType
        var out: [U] = []
        vector.withUnsafeBufferPointer { src in
            out = src.map { U($0) }
        }
        return out
    }

    public static func integerToFloatingPoint<T, U>(_ vector: T, floatingPointType: U.Type) -> [U]
    where T: AccelerateBuffer, U: vDSP_FloatingPointConvertable, T.Element == UInt8 {
        _ = floatingPointType
        var out: [U] = []
        vector.withUnsafeBufferPointer { src in
            out = src.map { U($0) }
        }
        return out
    }

    public static func integerToFloatingPoint<T, U>(_ vector: T, floatingPointType: U.Type) -> [U]
    where T: AccelerateBuffer, U: vDSP_FloatingPointConvertable, T.Element == UInt16 {
        _ = floatingPointType
        var out: [U] = []
        vector.withUnsafeBufferPointer { src in
            out = src.map { U($0) }
        }
        return out
    }

    public static func integerToFloatingPoint<T, U>(_ vector: T, floatingPointType: U.Type) -> [U]
    where T: AccelerateBuffer, U: vDSP_FloatingPointConvertable, T.Element == UInt32 {
        _ = floatingPointType
        var out: [U] = []
        vector.withUnsafeBufferPointer { src in
            out = src.map { U($0) }
        }
        return out
    }

    public static func floatingPointToInteger<T, U>(_ vector: T, integerType: U.Type, rounding: vDSP.RoundingMode) -> [U]
    where T: AccelerateBuffer, U: vDSP_IntegerConvertable, T.Element == Float {
        _ = integerType
        var out: [U] = []
        vector.withUnsafeBufferPointer { src in
            out = src.map { value in
                let r = rounding == .towardZero ? value.rounded(.towardZero) : value.rounded(.toNearestOrEven)
                return U(r)
            }
        }
        return out
    }

    public static func floatingPointToInteger<T, U>(_ vector: T, integerType: U.Type, rounding: vDSP.RoundingMode) -> [U]
    where T: AccelerateBuffer, U: vDSP_IntegerConvertable, T.Element == Double {
        _ = integerType
        var out: [U] = []
        vector.withUnsafeBufferPointer { src in
            out = src.map { value in
                let r = rounding == .towardZero ? value.rounded(.towardZero) : value.rounded(.toNearestOrEven)
                return U(r)
            }
        }
        return out
    }

    public static func float16ToFloat<U>(_ source: U) -> [Float] where U: AccelerateBuffer, U.Element == Float16 {
        var out = [Float](repeating: 0, count: source.count)
        source.withUnsafeBufferPointer { src in
            for i in 0..<src.count { out[i] = Float(src[i]) }
        }
        return out
    }

    public static func floatToFloat16<U>(_ source: U) -> [Float16] where U: AccelerateBuffer, U.Element == Float {
        var out = [Float16](repeating: 0, count: source.count)
        source.withUnsafeBufferPointer { src in
            for i in 0..<src.count { out[i] = Float16(src[i]) }
        }
        return out
    }

    public static func stereoRamp<U>(
        withInitialValue initialValue: inout Float,
        multiplyingBy multiplierOne: U,
        _ multiplierTwo: U,
        increment: Float
    ) -> (firstOutput: [Float], secondOutput: [Float])
    where U: AccelerateBuffer, U.Element == Float {
        let n = multiplierOne.count
        var first = [Float](repeating: 0, count: n)
        var second = [Float](repeating: 0, count: n)
        formStereoRamp(
            withInitialValue: &initialValue,
            multiplyingBy: multiplierOne,
            multiplierTwo,
            increment: increment,
            results: &first,
            &second
        )
        return (first, second)
    }

    public static func stereoRamp<U>(
        withInitialValue initialValue: inout Double,
        multiplyingBy multiplierOne: U,
        _ multiplierTwo: U,
        increment: Double
    ) -> (firstOutput: [Double], secondOutput: [Double])
    where U: AccelerateBuffer, U.Element == Double {
        let n = multiplierOne.count
        var first = [Double](repeating: 0, count: n)
        var second = [Double](repeating: 0, count: n)
        formStereoRamp(
            withInitialValue: &initialValue,
            multiplyingBy: multiplierOne,
            multiplierTwo,
            increment: increment,
            results: &first,
            &second
        )
        return (first, second)
    }

    public static func formStereoRamp<U, V>(
        withInitialValue initialValue: inout Float,
        multiplyingBy multiplierOne: U,
        _ multiplierTwo: U,
        increment: Float,
        results resultOne: inout V,
        _ resultTwo: inout V
    ) where U: AccelerateBuffer, V: AccelerateMutableBuffer, U.Element == Float, V.Element == Float {
        multiplierOne.withUnsafeBufferPointer { m1 in
            multiplierTwo.withUnsafeBufferPointer { m2 in
                resultOne.withUnsafeMutableBufferPointer { r1 in
                    resultTwo.withUnsafeMutableBufferPointer { r2 in
                        let n = min(m1.count, min(m2.count, min(r1.count, r2.count)))
                        var value = initialValue
                        for i in 0..<n {
                            r1[i] = value * m1[i]
                            r2[i] = value * m2[i]
                            value += increment
                        }
                        initialValue = value
                    }
                }
            }
        }
    }

    public static func formStereoRamp<U, V>(
        withInitialValue initialValue: inout Double,
        multiplyingBy multiplierOne: U,
        _ multiplierTwo: U,
        increment: Double,
        results resultOne: inout V,
        _ resultTwo: inout V
    ) where U: AccelerateBuffer, V: AccelerateMutableBuffer, U.Element == Double, V.Element == Double {
        multiplierOne.withUnsafeBufferPointer { m1 in
            multiplierTwo.withUnsafeBufferPointer { m2 in
                resultOne.withUnsafeMutableBufferPointer { r1 in
                    resultTwo.withUnsafeMutableBufferPointer { r2 in
                        let n = min(m1.count, min(m2.count, min(r1.count, r2.count)))
                        var value = initialValue
                        for i in 0..<n {
                            r1[i] = value * m1[i]
                            r2[i] = value * m2[i]
                            value += increment
                        }
                        initialValue = value
                    }
                }
            }
        }
    }
}
