import Foundation

extension vDSP {
    public static func add<T, U, V>(_ vectorA: T, _ vectorB: U, result: inout V) where T: AccelerateBuffer, U: AccelerateBuffer, V: AccelerateMutableBuffer, T.Element == Float, U.Element == Float, V.Element == Float
    {
        _AccelerateNumeric.zip3(vectorA, vectorB, &result, +)
    }

    public static func add<T, U>(_ vectorA: T, _ vectorB: U) -> [Float] where T: AccelerateBuffer, U: AccelerateBuffer, T.Element == Float, U.Element == Float
    {
        var result = [Float](repeating: 0, count: vectorA.count)
            add(vectorA, vectorB, result: &result)
            return result
    }

    public static func add<U, V>(_ scalar: Float, _ vector: U, result: inout V) where U: AccelerateBuffer, V: AccelerateMutableBuffer, U.Element == Float, V.Element == Float
    {
        _AccelerateNumeric.map(vector, &result) { $0 + scalar }
    }

    public static func add<U>(_ scalar: Float, _ vector: U) -> [Float] where U: AccelerateBuffer, U.Element == Float
    {
        var result = [Float](repeating: 0, count: vector.count)
            add(scalar, vector, result: &result)
            return result
    }

    public static func subtract<T, U, V>(_ vectorA: T, _ vectorB: U, result: inout V) where T: AccelerateBuffer, U: AccelerateBuffer, V: AccelerateMutableBuffer, T.Element == Float, U.Element == Float, V.Element == Float
    {
        _AccelerateNumeric.zip3(vectorA, vectorB, &result, -)
    }

    public static func subtract<T, U>(_ vectorA: T, _ vectorB: U) -> [Float] where T: AccelerateBuffer, U: AccelerateBuffer, T.Element == Float, U.Element == Float
    {
        var result = [Float](repeating: 0, count: vectorA.count)
            subtract(vectorA, vectorB, result: &result)
            return result
    }

    public static func multiply<T, U, V>(_ vectorA: T, _ vectorB: U, result: inout V) where T: AccelerateBuffer, U: AccelerateBuffer, V: AccelerateMutableBuffer, T.Element == Float, U.Element == Float, V.Element == Float
    {
        _AccelerateNumeric.zip3(vectorA, vectorB, &result, *)
    }

    public static func multiply<T, U>(_ vectorA: T, _ vectorB: U) -> [Float] where T: AccelerateBuffer, U: AccelerateBuffer, T.Element == Float, U.Element == Float
    {
        var result = [Float](repeating: 0, count: vectorA.count)
            multiply(vectorA, vectorB, result: &result)
            return result
    }

    public static func multiply<U, V>(_ scalar: Float, _ vector: U, result: inout V) where U: AccelerateBuffer, V: AccelerateMutableBuffer, U.Element == Float, V.Element == Float
    {
        _AccelerateNumeric.map(vector, &result) { $0 * scalar }
    }

    public static func multiply<U>(_ scalar: Float, _ vector: U) -> [Float] where U: AccelerateBuffer, U.Element == Float
    {
        var result = [Float](repeating: 0, count: vector.count)
            multiply(scalar, vector, result: &result)
            return result
    }

    public static func divide<T, U, V>(_ vectorA: T, _ vectorB: U, result: inout V) where T: AccelerateBuffer, U: AccelerateBuffer, V: AccelerateMutableBuffer, T.Element == Float, U.Element == Float, V.Element == Float
    {
        _AccelerateNumeric.zip3(vectorA, vectorB, &result, /)
    }

    public static func divide<T, U>(_ vectorA: T, _ vectorB: U) -> [Float] where T: AccelerateBuffer, U: AccelerateBuffer, T.Element == Float, U.Element == Float
    {
        var result = [Float](repeating: 0, count: vectorA.count)
            divide(vectorA, vectorB, result: &result)
            return result
    }

    public static func addSubtract<S, T, U, V>(_ vectorA: S, _ vectorB: T, addResult: inout U, subtractResult: inout V) where S: AccelerateBuffer, T: AccelerateBuffer, U: AccelerateMutableBuffer, V: AccelerateMutableBuffer, S.Element == Float, T.Element == Float, U.Element == Float, V.Element == Float
    {
        add(vectorA, vectorB, result: &addResult)
            subtract(vectorA, vectorB, result: &subtractResult)
    }

    public static func multiply<T, U, V>(addition: (a: T, b: U), _ scalar: Float, result: inout V) where T: AccelerateBuffer, U: AccelerateBuffer, V: AccelerateMutableBuffer, T.Element == Float, U.Element == Float, V.Element == Float
    {
        _AccelerateNumeric.zip3(addition.a, addition.b, &result) { ($0 + $1) * scalar }
    }

    public static func multiply<T, U>(addition: (a: T, b: U), _ scalar: Float) -> [Float] where T: AccelerateBuffer, U: AccelerateBuffer, T.Element == Float, U.Element == Float
    {
        var result = [Float](repeating: 0, count: addition.a.count)
            multiply(addition: addition, scalar, result: &result)
            return result
    }

    public static func multiply<T, U, V>(subtraction: (a: T, b: U), _ scalar: Float, result: inout V) where T: AccelerateBuffer, U: AccelerateBuffer, V: AccelerateMutableBuffer, T.Element == Float, U.Element == Float, V.Element == Float
    {
        _AccelerateNumeric.zip3(subtraction.a, subtraction.b, &result) { ($0 - $1) * scalar }
    }

    public static func multiply<T, U>(subtraction: (a: T, b: U), _ scalar: Float) -> [Float] where T: AccelerateBuffer, U: AccelerateBuffer, T.Element == Float, U.Element == Float
    {
        var result = [Float](repeating: 0, count: subtraction.a.count)
            multiply(subtraction: subtraction, scalar, result: &result)
            return result
    }

    public static func add<T, U, V>(multiplication: (a: T, b: Float), _ vector: U, result: inout V) where T: AccelerateBuffer, U: AccelerateBuffer, V: AccelerateMutableBuffer, T.Element == Float, U.Element == Float, V.Element == Float
    {
        _AccelerateNumeric.zip3(multiplication.a, vector, &result) { $0 * multiplication.b + $1 }
    }

    public static func add<T, U>(multiplication: (a: T, b: Float), _ vector: U) -> [Float] where T: AccelerateBuffer, U: AccelerateBuffer, T.Element == Float, U.Element == Float
    {
        var result = [Float](repeating: 0, count: multiplication.a.count)
            add(multiplication: multiplication, vector, result: &result)
            return result
    }

    public static func add<U, V>(multiplication: (a: U, b: Float), _ scalar: Float, result: inout V) where U: AccelerateBuffer, V: AccelerateMutableBuffer, U.Element == Float, V.Element == Float
    {
        _AccelerateNumeric.map(multiplication.a, &result) { $0 * multiplication.b + scalar }
    }

    public static func add<U>(multiplication: (a: U, b: Float), _ scalar: Float) -> [Float] where U: AccelerateBuffer, U.Element == Float
    {
        var result = [Float](repeating: 0, count: multiplication.a.count)
            add(multiplication: multiplication, scalar, result: &result)
            return result
    }

    public static func add<T, U, V>(multiplication multiplicationAB: (a: T, b: Float), multiplication multiplicationCD: (c: U, d: Float), result: inout V) where T: AccelerateBuffer, U: AccelerateBuffer, V: AccelerateMutableBuffer, T.Element == Float, U.Element == Float, V.Element == Float
    {
        _AccelerateNumeric.zip3(multiplicationAB.a, multiplicationCD.c, &result) { $0 * multiplicationAB.b + $1 * multiplicationCD.d }
    }

    public static func add<T, U>(multiplication multiplicationAB: (a: T, b: Float), multiplication multiplicationCD: (c: U, d: Float)) -> [Float] where T: AccelerateBuffer, U: AccelerateBuffer, T.Element == Float, U.Element == Float
    {
        var result = [Float](repeating: 0, count: multiplicationAB.a.count)
            add(multiplication: multiplicationAB, multiplication: multiplicationCD, result: &result)
            return result
    }

    public static func hypot<T, U, V>(_ vectorA: T, _ vectorB: U, result: inout V) where T: AccelerateBuffer, U: AccelerateBuffer, V: AccelerateMutableBuffer, T.Element == Float, U.Element == Float, V.Element == Float
    {
        _AccelerateNumeric.zip3(vectorA, vectorB, &result) { Foundation.hypot($0, $1) }
    }

    public static func hypot<T, U>(_ vectorA: T, _ vectorB: U) -> [Float] where T: AccelerateBuffer, U: AccelerateBuffer, T.Element == Float, U.Element == Float
    {
        var result = [Float](repeating: 0, count: vectorA.count)
            hypot(vectorA, vectorB, result: &result)
            return result
    }

    public static func dot<T, U>(_ vectorA: T, _ vectorB: U) -> Float where T: AccelerateBuffer, U: AccelerateBuffer, T.Element == Float, U.Element == Float
    {
        vectorA.withUnsafeBufferPointer { a in
                vectorB.withUnsafeBufferPointer { b in
                    let n = min(a.count, b.count)
                    var s: Float = 0
                    for i in 0..<n { s += a[i] * b[i] }
                    return s
                }
            }
    }

    public static func sum<U>(_ vector: U) -> Float where U: AccelerateBuffer, U.Element == Float
    {
        vector.withUnsafeBufferPointer { $0.reduce(0, +) }
    }

    public static func mean<U>(_ vector: U) -> Float where U: AccelerateBuffer, U.Element == Float
    {
        let n = vector.count
            if n == 0 { return 0 }
            return sum(vector) / Float(n)
    }

    public static func meanSquare<U>(_ vector: U) -> Float where U: AccelerateBuffer, U.Element == Float
    {
        vector.withUnsafeBufferPointer { buf in
                if buf.isEmpty { return 0 }
                var s: Float = 0
                for v in buf { s += v * v }
                return s / Float(buf.count)
            }
    }

    public static func meanMagnitude<U>(_ vector: U) -> Float where U: AccelerateBuffer, U.Element == Float
    {
        vector.withUnsafeBufferPointer { buf in
                if buf.isEmpty { return 0 }
                var s: Float = 0
                for v in buf { s += abs(v) }
                return s / Float(buf.count)
            }
    }

    public static func sumOfSquares<U>(_ vector: U) -> Float where U: AccelerateBuffer, U.Element == Float
    {
        vector.withUnsafeBufferPointer { buf in
                var s: Float = 0
                for v in buf { s += v * v }
                return s
            }
    }

    public static func sumOfMagnitudes<U>(_ vector: U) -> Float where U: AccelerateBuffer, U.Element == Float
    {
        vector.withUnsafeBufferPointer { buf in
                var s: Float = 0
                for v in buf { s += abs(v) }
                return s
            }
    }

    public static func rootMeanSquare<U>(_ vector: U) -> Float where U: AccelerateBuffer, U.Element == Float
    {
        Foundation.sqrt(meanSquare(vector))
    }

    public static func maximum<U>(_ vector: U) -> Float where U: AccelerateBuffer, U.Element == Float
    {
        vector.withUnsafeBufferPointer { $0.max() ?? -.infinity }
    }

    public static func minimum<U>(_ vector: U) -> Float where U: AccelerateBuffer, U.Element == Float
    {
        vector.withUnsafeBufferPointer { $0.min() ?? .infinity }
    }

    public static func maximumMagnitude<U>(_ vector: U) -> Float where U: AccelerateBuffer, U.Element == Float
    {
        vector.withUnsafeBufferPointer { buf in
                var m: Float = 0
                for v in buf { m = max(m, abs(v)) }
                return m
            }
    }

    public static func indexOfMaximum<U>(_ vector: U) -> (index: Int, value: Float) where U: AccelerateBuffer, U.Element == Float
    {
        vector.withUnsafeBufferPointer { buf in
                precondition(!buf.isEmpty)
                var idx = 0
                var best = buf[0]
                for i in 1..<buf.count where buf[i] > best { best = buf[i]; idx = i }
                return (idx, best)
            }
    }

    public static func indexOfMinimum<U>(_ vector: U) -> (index: Int, value: Float) where U: AccelerateBuffer, U.Element == Float
    {
        vector.withUnsafeBufferPointer { buf in
                precondition(!buf.isEmpty)
                var idx = 0
                var best = buf[0]
                for i in 1..<buf.count where buf[i] < best { best = buf[i]; idx = i }
                return (idx, best)
            }
    }

    public static func indexOfMaximumMagnitude<U>(_ vector: U) -> (index: Int, value: Float) where U: AccelerateBuffer, U.Element == Float
    {
        vector.withUnsafeBufferPointer { buf in
                precondition(!buf.isEmpty)
                var idx = 0
                var best = abs(buf[0])
                for i in 1..<buf.count where abs(buf[i]) > best { best = abs(buf[i]); idx = i }
                return (idx, buf[idx])
            }
    }

    public static func standardDeviation(_ vector: some AccelerateMutableBuffer<Float>) -> Float
    {
        let n = vector.count
            if n < 2 { return 0 }
            let mu = mean(vector)
            var acc: Float = 0
            vector.withUnsafeBufferPointer { buf in
                for v in buf { let d = v - mu; acc += d * d }
            }
            return Foundation.sqrt(acc / Float(n))
    }

    public static func sumAndSumOfSquares<U>(_ vector: U) -> (elementsSum: Float, squaresSum: Float) where U: AccelerateBuffer, U.Element == Float
    {
        (sum(vector), sumOfSquares(vector))
    }

    public static func countZeroCrossings<U>(_ vector: U) -> UInt where U: AccelerateBuffer, U.Element == Float
    {
        vector.withUnsafeBufferPointer { buf in
                guard buf.count >= 2 else { return 0 }
                var n: UInt = 0
                for i in 1..<buf.count {
                    if buf[i - 1] == 0 { continue }
                    if (buf[i - 1] > 0) != (buf[i] > 0) && buf[i] != 0 { n += 1 }
                }
                return n
            }
    }

    public static func distanceSquared<T, U>(_ vectorA: T, _ vectorB: U) -> Float where T: AccelerateBuffer, U: AccelerateBuffer, T.Element == Float, U.Element == Float
    {
        vectorA.withUnsafeBufferPointer { a in
                vectorB.withUnsafeBufferPointer { b in
                    let n = min(a.count, b.count)
                    var s: Float = 0
                    for i in 0..<n { let d = a[i] - b[i]; s += d * d }
                    return s
                }
            }
    }

    public static func absolute<U, V>(_ vector: U, result: inout V) where U: AccelerateBuffer, V: AccelerateMutableBuffer, U.Element == Float, V.Element == Float
    {
        _AccelerateNumeric.map(vector, &result, abs)
    }

    public static func absolute<U>(_ vector: U) -> [Float] where U: AccelerateBuffer, U.Element == Float
    {
        var result = [Float](repeating: 0, count: vector.count)
            absolute(vector, result: &result)
            return result
    }

    public static func negative<U, V>(_ vector: U, result: inout V) where U: AccelerateBuffer, V: AccelerateMutableBuffer, U.Element == Float, V.Element == Float
    {
        _AccelerateNumeric.map(vector, &result) { -$0 }
    }

    public static func negative<U>(_ vector: U) -> [Float] where U: AccelerateBuffer, U.Element == Float
    {
        var result = [Float](repeating: 0, count: vector.count)
            negative(vector, result: &result)
            return result
    }

    public static func square<U, V>(_ vector: U, result: inout V) where U: AccelerateBuffer, V: AccelerateMutableBuffer, U.Element == Float, V.Element == Float
    {
        _AccelerateNumeric.map(vector, &result) { $0 * $0 }
    }

    public static func square<U>(_ vector: U) -> [Float] where U: AccelerateBuffer, U.Element == Float
    {
        var result = [Float](repeating: 0, count: vector.count)
            square(vector, result: &result)
            return result
    }

    public static func signedSquare<U, V>(_ vector: U, result: inout V) where U: AccelerateBuffer, V: AccelerateMutableBuffer, U.Element == Float, V.Element == Float
    {
        _AccelerateNumeric.map(vector, &result) { $0 * abs($0) }
    }

    public static func signedSquare<U>(_ vector: U) -> [Float] where U: AccelerateBuffer, U.Element == Float
    {
        var result = [Float](repeating: 0, count: vector.count)
            signedSquare(vector, result: &result)
            return result
    }

    public static func negativeAbsolute<U, V>(_ vector: U, result: inout V) where U: AccelerateBuffer, V: AccelerateMutableBuffer, U.Element == Float, V.Element == Float
    {
        _AccelerateNumeric.map(vector, &result) { -abs($0) }
    }

    public static func negativeAbsolute<U>(_ vector: U) -> [Float] where U: AccelerateBuffer, U.Element == Float
    {
        var result = [Float](repeating: 0, count: vector.count)
            negativeAbsolute(vector, result: &result)
            return result
    }

    public static func trunc<U, V>(_ vector: U, result: inout V) where U: AccelerateBuffer, V: AccelerateMutableBuffer, U.Element == Float, V.Element == Float
    {
        _AccelerateNumeric.map(vector, &result) { $0.rounded(.towardZero) }
    }

    public static func trunc<U>(_ vector: U) -> [Float] where U: AccelerateBuffer, U.Element == Float
    {
        var result = [Float](repeating: 0, count: vector.count)
            trunc(vector, result: &result)
            return result
    }

    public static func fill<V>(_ vector: inout V, with value: Float) where V: AccelerateMutableBuffer, V.Element == Float
    {
        vector.withUnsafeMutableBufferPointer { dest in
                for i in dest.indices { dest[i] = value }
            }
    }

    public static func clear<V>(_ vector: inout V) where V: AccelerateMutableBuffer, V.Element == Float
    {
        fill(&vector, with: 0)
    }

    public static func reverse<V>(_ vector: inout V) where V: AccelerateMutableBuffer, V.Element == Float
    {
        vector.withUnsafeMutableBufferPointer { dest in
                var i = 0
                var j = dest.count - 1
                while i < j {
                    let t = dest[i]; dest[i] = dest[j]; dest[j] = t
                    i += 1; j -= 1
                }
            }
    }

    public static func swapElements<T, U>(_ vectorA: inout T, _ vectorB: inout U) where T: AccelerateMutableBuffer, U: AccelerateMutableBuffer, T.Element == Float, U.Element == Float
    {
        vectorA.withUnsafeMutableBufferPointer { a in
                vectorB.withUnsafeMutableBufferPointer { b in
                    let n = min(a.count, b.count)
                    for i in 0..<n { let t = a[i]; a[i] = b[i]; b[i] = t }
                }
            }
    }

    public static func clip<U, V>(_ vector: U, to bounds: ClosedRange<Float>, result: inout V) where U: AccelerateBuffer, V: AccelerateMutableBuffer, U.Element == Float, V.Element == Float
    {
        _AccelerateNumeric.map(vector, &result) { min(max($0, bounds.lowerBound), bounds.upperBound) }
    }

    public static func clip<U>(_ vector: U, to bounds: ClosedRange<Float>) -> [Float] where U: AccelerateBuffer, U.Element == Float
    {
        var result = [Float](repeating: 0, count: vector.count)
            clip(vector, to: bounds, result: &result)
            return result
    }

    public static func invertedClip<U, V>(_ vector: U, to bounds: ClosedRange<Float>, result: inout V) where U: AccelerateBuffer, V: AccelerateMutableBuffer, U.Element == Float, V.Element == Float
    {
        _AccelerateNumeric.map(vector, &result) { v in
                if v > bounds.lowerBound && v < bounds.upperBound { return 0 }
                return v
            }
    }

    public static func invertedClip<U>(_ vector: U, to bounds: ClosedRange<Float>) -> [Float] where U: AccelerateBuffer, U.Element == Float
    {
        var result = [Float](repeating: 0, count: vector.count)
            invertedClip(vector, to: bounds, result: &result)
            return result
    }

    public static func limit<U, V>(_ vector: U, limit: Float, withOutputLimitedTo outputLimit: Float, result: inout V) where U: AccelerateBuffer, V: AccelerateMutableBuffer, U.Element == Float, V.Element == Float
    {
        _AccelerateNumeric.map(vector, &result) { abs($0) > abs(limit) ? ($0 < 0 ? -outputLimit : outputLimit) : $0 }
    }

    public static func limit<U>(_ vector: U, limit: Float, withOutputLimitedTo outputLimit: Float) -> [Float] where U: AccelerateBuffer, U.Element == Float
    {
        var result = [Float](repeating: 0, count: vector.count)
            vDSP.limit(vector, limit: limit, withOutputLimitedTo: outputLimit, result: &result)
            return result
    }

    public static func threshold<U, V>(_ vector: U, to lowerBound: Float, with rule: vDSP.ThresholdRule<Float>, result: inout V) where U: AccelerateBuffer, V: AccelerateMutableBuffer, U.Element == Float, V.Element == Float
    {
        _AccelerateNumeric.map(vector, &result) { v in
                if v >= lowerBound { return v }
                switch rule {
                case .clampToThreshold: return lowerBound
                case .zeroFill: return 0
                case .signedConstant(let c): return v < 0 ? -c : c
                }
            }
    }

    public static func threshold<U>(_ vector: U, to lowerBound: Float, with rule: vDSP.ThresholdRule<Float>) -> [Float] where U: AccelerateBuffer, U.Element == Float
    {
        var result = [Float](repeating: 0, count: vector.count)
            threshold(vector, to: lowerBound, with: rule, result: &result)
            return result
    }

    public static func formWindow<V>(usingSequence sequence: vDSP.WindowSequence, result: inout V, isHalfWindow: Bool) where V: AccelerateMutableBuffer, V.Element == Float
    {
        result.withUnsafeMutableBufferPointer { dest in
                let n = dest.count
                guard n > 0 else { return }
                let full = isHalfWindow ? (n - 1) * 2 : (n - 1)
                for i in 0..<n {
                    let x = Float(i) / Float(max(full, 1))
                    let w: Float
                    switch sequence {
                    case .hanningNormalized:
                        w = 0.5 - 0.5 * Foundation.cos(2 * Float.pi * x)
                    case .hanningDenormalized:
                        w = 0.5 - 0.5 * Foundation.cos(2 * Float.pi * x)
                    case .hamming:
                        w = 0.54 - 0.46 * Foundation.cos(2 * Float.pi * x)
                    case .blackman:
                        w = 0.42 - 0.5 * Foundation.cos(2 * Float.pi * x) + 0.08 * Foundation.cos(4 * Float.pi * x)
                    }
                    dest[i] = w
                }
            }
    }

    public static func formRamp<V>(withInitialValue start: Float, increment: Float, result: inout V) where V: AccelerateMutableBuffer, V.Element == Float
    {
        result.withUnsafeMutableBufferPointer { dest in
                var v = start
                for i in dest.indices { dest[i] = v; v += increment }
            }
    }

    public static func ramp<U>(withInitialValue start: inout Float, multiplyingBy multipliers: U, increment: Float) -> [Float] where U: AccelerateBuffer, U.Element == Float
    {
        var out = [Float](repeating: 0, count: multipliers.count)
            multipliers.withUnsafeBufferPointer { m in
                var v = start
                for i in 0..<m.count { out[i] = v * m[i]; v += increment }
                start = v
            }
            return out
    }

    public static func convolve<T, U, V>(_ vector: T, withKernel kernel: U, result: inout V) where T: AccelerateBuffer, U: AccelerateBuffer, V: AccelerateMutableBuffer, T.Element == Float, U.Element == Float, V.Element == Float
    {
        vector.withUnsafeBufferPointer { src in
                kernel.withUnsafeBufferPointer { k in
                    result.withUnsafeMutableBufferPointer { dest in
                        let outN = min(dest.count, max(0, src.count - k.count + 1))
                        for i in 0..<outN {
                            var s: Float = 0
                            for j in 0..<k.count { s += src[i + j] * k[j] }
                            dest[i] = s
                        }
                    }
                }
            }
    }

    public static func convolve<T, U>(_ vector: T, withKernel kernel: U) -> [Float] where T: AccelerateBuffer, U: AccelerateBuffer, T.Element == Float, U.Element == Float
    {
        let n = max(0, vector.count - kernel.count + 1)
            var result = [Float](repeating: 0, count: n)
            convolve(vector, withKernel: kernel, result: &result)
            return result
    }

    public static func correlate<T, U, V>(_ vector: T, withKernel kernel: U, result: inout V) where T: AccelerateBuffer, U: AccelerateBuffer, V: AccelerateMutableBuffer, T.Element == Float, U.Element == Float, V.Element == Float
    {
        vector.withUnsafeBufferPointer { src in
                kernel.withUnsafeBufferPointer { k in
                    result.withUnsafeMutableBufferPointer { dest in
                        let outN = min(dest.count, max(0, src.count - k.count + 1))
                        for i in 0..<outN {
                            var s: Float = 0
                            for j in 0..<k.count { s += src[i + j] * k[k.count - 1 - j] }
                            dest[i] = s
                        }
                    }
                }
            }
    }

    public static func correlate<T, U>(_ vector: T, withKernel kernel: U) -> [Float] where T: AccelerateBuffer, U: AccelerateBuffer, T.Element == Float, U.Element == Float
    {
        let n = max(0, vector.count - kernel.count + 1)
            var result = [Float](repeating: 0, count: n)
            correlate(vector, withKernel: kernel, result: &result)
            return result
    }

    public static func convolve<T, U, V>(_ vector: T, rowCount: Int, columnCount: Int, withKernel kernel: U, kernelRowCount: Int, kernelColumnCount: Int, result: inout V) where T: AccelerateBuffer, U: AccelerateBuffer, V: AccelerateMutableBuffer, T.Element == Float, U.Element == Float, V.Element == Float
    {
        vector.withUnsafeBufferPointer { src in
                kernel.withUnsafeBufferPointer { k in
                    result.withUnsafeMutableBufferPointer { dest in
                        let outRows = max(0, rowCount - kernelRowCount + 1)
                        let outCols = max(0, columnCount - kernelColumnCount + 1)
                        for r in 0..<outRows {
                            for c in 0..<outCols {
                                var s: Float = 0
                                for kr in 0..<kernelRowCount {
                                    for kc in 0..<kernelColumnCount {
                                        s += src[(r + kr) * columnCount + (c + kc)] * k[kr * kernelColumnCount + kc]
                                    }
                                }
                                dest[r * outCols + c] = s
                            }
                        }
                    }
                }
            }
    }

    public static func convolve<T, U>(_ vector: T, rowCount: Int, columnCount: Int, withKernel kernel: U, kernelRowCount: Int, kernelColumnCount: Int) -> [Float] where T: AccelerateBuffer, U: AccelerateBuffer, T.Element == Float, U.Element == Float
    {
        let outRows = max(0, rowCount - kernelRowCount + 1)
            let outCols = max(0, columnCount - kernelColumnCount + 1)
            var result = [Float](repeating: 0, count: outRows * outCols)
            convolve(vector, rowCount: rowCount, columnCount: columnCount, withKernel: kernel, kernelRowCount: kernelRowCount, kernelColumnCount: kernelColumnCount, result: &result)
            return result
    }

    public static func convolve<T, U, V>(_ vector: T, rowCount: Int, columnCount: Int, with3x3Kernel kernel: U, result: inout V) where T: AccelerateBuffer, U: AccelerateBuffer, V: AccelerateMutableBuffer, T.Element == Float, U.Element == Float, V.Element == Float
    {
        convolve(vector, rowCount: rowCount, columnCount: columnCount, withKernel: kernel, kernelRowCount: 3, kernelColumnCount: 3, result: &result)
    }

    public static func convolve<T, U>(_ vector: T, rowCount: Int, columnCount: Int, with3x3Kernel kernel: U) -> [Float] where T: AccelerateBuffer, U: AccelerateBuffer, T.Element == Float, U.Element == Float
    {
        convolve(vector, rowCount: rowCount, columnCount: columnCount, withKernel: kernel, kernelRowCount: 3, kernelColumnCount: 3)
    }

    public static func convolve<T, U, V>(_ vector: T, rowCount: Int, columnCount: Int, with5x5Kernel kernel: U, result: inout V) where T: AccelerateBuffer, U: AccelerateBuffer, V: AccelerateMutableBuffer, T.Element == Float, U.Element == Float, V.Element == Float
    {
        convolve(vector, rowCount: rowCount, columnCount: columnCount, withKernel: kernel, kernelRowCount: 5, kernelColumnCount: 5, result: &result)
    }

    public static func convolve<T, U>(_ vector: T, rowCount: Int, columnCount: Int, with5x5Kernel kernel: U) -> [Float] where T: AccelerateBuffer, U: AccelerateBuffer, T.Element == Float, U.Element == Float
    {
        convolve(vector, rowCount: rowCount, columnCount: columnCount, withKernel: kernel, kernelRowCount: 5, kernelColumnCount: 5)
    }

    public static func slidingWindowSum<U, V>(_ vector: U, usingWindowLength windowLength: Int, result: inout V) where U: AccelerateBuffer, V: AccelerateMutableBuffer, U.Element == Float, V.Element == Float
    {
        vector.withUnsafeBufferPointer { src in
                result.withUnsafeMutableBufferPointer { dest in
                    let w = max(windowLength, 1)
                    let outN = min(dest.count, max(0, src.count - w + 1))
                    for i in 0..<outN {
                        var s: Float = 0
                        for j in 0..<w { s += src[i + j] }
                        dest[i] = s
                    }
                }
            }
    }

    public static func slidingWindowSum<U>(_ vector: U, usingWindowLength windowLength: Int) -> [Float] where U: AccelerateBuffer, U.Element == Float
    {
        let n = max(0, vector.count - max(windowLength, 1) + 1)
            var result = [Float](repeating: 0, count: n)
            slidingWindowSum(vector, usingWindowLength: windowLength, result: &result)
            return result
    }

    public static func downsample<T, U, V>(_ vector: T, decimationFactor: Int, filter: U, result: inout V) where T: AccelerateBuffer, U: AccelerateBuffer, V: AccelerateMutableBuffer, T.Element == Float, U.Element == Float, V.Element == Float
    {
        let factor = max(decimationFactor, 1)
            vector.withUnsafeBufferPointer { src in
                filter.withUnsafeBufferPointer { k in
                    result.withUnsafeMutableBufferPointer { dest in
                        var di = 0
                        var i = 0
                        while i + k.count <= src.count && di < dest.count {
                            var s: Float = 0
                            for j in 0..<k.count { s += src[i + j] * k[j] }
                            dest[di] = s
                            di += 1
                            i += factor
                        }
                    }
                }
            }
    }

    public static func downsample<T, U>(_ vector: T, decimationFactor: Int, filter: U) -> [Float] where T: AccelerateBuffer, U: AccelerateBuffer, T.Element == Float, U.Element == Float
    {
        let factor = max(decimationFactor, 1)
            let n = max(0, (vector.count - filter.count) / factor + 1)
            var result = [Float](repeating: 0, count: n)
            downsample(vector, decimationFactor: decimationFactor, filter: filter, result: &result)
            return result
    }

    public static func linearInterpolate<T, U>(_ vectorA: T, _ vectorB: U, using interpolationConstant: Float) -> [Float] where T: AccelerateBuffer, U: AccelerateBuffer, T.Element == Float, U.Element == Float
    {
        var result = [Float](repeating: 0, count: vectorA.count)
            linearInterpolate(vectorA, vectorB, using: interpolationConstant, result: &result)
            return result
    }

    public static func linearInterpolate<T, U, V>(_ vectorA: T, _ vectorB: U, using interpolationConstant: Float, result: inout V) where T: AccelerateBuffer, U: AccelerateBuffer, V: AccelerateMutableBuffer, T.Element == Float, U.Element == Float, V.Element == Float
    {
        _AccelerateNumeric.zip3(vectorA, vectorB, &result) { $0 + interpolationConstant * ($1 - $0) }
    }

    public static func evaluatePolynomial<U, V>(usingCoefficients coefficients: [Float], withVariables variables: U, result: inout V) where U: AccelerateBuffer, V: AccelerateMutableBuffer, U.Element == Float, V.Element == Float
    {
        variables.withUnsafeBufferPointer { xs in
                result.withUnsafeMutableBufferPointer { dest in
                    let n = min(xs.count, dest.count)
                    for i in 0..<n {
                        var acc: Float = 0
                        for c in coefficients { acc = acc * xs[i] + c }
                        dest[i] = acc
                    }
                }
            }
    }

    public static func evaluatePolynomial<U>(usingCoefficients coefficients: [Float], withVariables variables: U) -> [Float] where U: AccelerateBuffer, U.Element == Float
    {
        var result = [Float](repeating: 0, count: variables.count)
            evaluatePolynomial(usingCoefficients: coefficients, withVariables: variables, result: &result)
            return result
    }

    public static func powerToDecibels<U>(_ power: U, zeroReference: Float) -> [Float] where U: AccelerateBuffer, U.Element == Float
    {
        let z = max(zeroReference, Float.leastNonzeroMagnitude)
            var out = [Float](repeating: 0, count: power.count)
            power.withUnsafeBufferPointer { src in
                for i in 0..<src.count {
                    out[i] = 10 * Foundation.log10(max(src[i], 0) / z)
                }
            }
            return out
    }

    public static func amplitudeToDecibels<U>(_ amplitude: U, zeroReference: Float) -> [Float] where U: AccelerateBuffer, U.Element == Float
    {
        let z = max(zeroReference, Float.leastNonzeroMagnitude)
            var out = [Float](repeating: 0, count: amplitude.count)
            amplitude.withUnsafeBufferPointer { src in
                for i in 0..<src.count {
                    out[i] = 20 * Foundation.log10(abs(src[i]) / z)
                }
            }
            return out
    }

    public static func normalize<U, V>(_ vector: U, result: inout V) -> (mean: Float, standardDeviation: Float) where U: AccelerateBuffer, V: AccelerateMutableBuffer, U.Element == Float, V.Element == Float
    {
        let mu = mean(vector)
            let sd = Foundation.sqrt(max(0, meanSquare(vector) - mu * mu))
            let denom = sd == 0 ? 1 : sd
            _AccelerateNumeric.map(vector, &result) { ($0 - mu) / denom }
            return (mu, sd)
    }

    public static func sort<V>(_ vector: inout V, order: vDSP.SortOrder) where V: AccelerateMutableBuffer, V.Element == Float
    {
        vector.withUnsafeMutableBufferPointer { dest in
                dest.sort(by: order == .ascending ? (<) : (>))
            }
    }

    public static func integrate<U, V>(_ vector: U, using rule: vDSP.IntegrationRule, result: inout V) where U: AccelerateBuffer, V: AccelerateMutableBuffer, U.Element == Float, V.Element == Float
    {
        vector.withUnsafeBufferPointer { src in
                result.withUnsafeMutableBufferPointer { dest in
                    let n = min(src.count, dest.count)
                    var acc: Float = 0
                    for i in 0..<n {
                        switch rule {
                        case .runningSum:
                            acc += src[i]
                            dest[i] = acc
                        case .trapezoidal:
                            if i == 0 { dest[i] = 0 }
                            else { acc += (src[i - 1] + src[i]) / 2; dest[i] = acc }
                        case .simpson:
                            acc += src[i]
                            dest[i] = acc
                        }
                    }
                }
            }
    }

    public static func gather<T, U, V>(_ vector: T, indices: U, result: inout V) where T: AccelerateBuffer, U: AccelerateBuffer, V: AccelerateMutableBuffer, T.Element == Float, U.Element == Float, V.Element == Float
    {
        vector.withUnsafeBufferPointer { src in
                indices.withUnsafeBufferPointer { idx in
                    result.withUnsafeMutableBufferPointer { dest in
                        let n = min(idx.count, dest.count)
                        for i in 0..<n {
                            let j = Int(idx[i])
                            dest[i] = (j >= 0 && j < src.count) ? src[j] : 0
                        }
                    }
                }
            }
    }

    public static func convertElements<U, V>(of source: U, to destination: inout V) where U: AccelerateBuffer, V: AccelerateMutableBuffer, U.Element == Float, V.Element == Float
    {
        _AccelerateNumeric.map(source, &destination) { $0 }
    }

    public static func add<T, U, V>(_ vectorA: T, _ vectorB: U, result: inout V) where T: AccelerateBuffer, U: AccelerateBuffer, V: AccelerateMutableBuffer, T.Element == Double, U.Element == Double, V.Element == Double
    {
        _AccelerateNumeric.zip3(vectorA, vectorB, &result, +)
    }

    public static func add<T, U>(_ vectorA: T, _ vectorB: U) -> [Double] where T: AccelerateBuffer, U: AccelerateBuffer, T.Element == Double, U.Element == Double
    {
        var result = [Double](repeating: 0, count: vectorA.count)
            add(vectorA, vectorB, result: &result)
            return result
    }

    public static func add<U, V>(_ scalar: Double, _ vector: U, result: inout V) where U: AccelerateBuffer, V: AccelerateMutableBuffer, U.Element == Double, V.Element == Double
    {
        _AccelerateNumeric.map(vector, &result) { $0 + scalar }
    }

    public static func add<U>(_ scalar: Double, _ vector: U) -> [Double] where U: AccelerateBuffer, U.Element == Double
    {
        var result = [Double](repeating: 0, count: vector.count)
            add(scalar, vector, result: &result)
            return result
    }

    public static func subtract<T, U, V>(_ vectorA: T, _ vectorB: U, result: inout V) where T: AccelerateBuffer, U: AccelerateBuffer, V: AccelerateMutableBuffer, T.Element == Double, U.Element == Double, V.Element == Double
    {
        _AccelerateNumeric.zip3(vectorA, vectorB, &result, -)
    }

    public static func subtract<T, U>(_ vectorA: T, _ vectorB: U) -> [Double] where T: AccelerateBuffer, U: AccelerateBuffer, T.Element == Double, U.Element == Double
    {
        var result = [Double](repeating: 0, count: vectorA.count)
            subtract(vectorA, vectorB, result: &result)
            return result
    }

    public static func multiply<T, U, V>(_ vectorA: T, _ vectorB: U, result: inout V) where T: AccelerateBuffer, U: AccelerateBuffer, V: AccelerateMutableBuffer, T.Element == Double, U.Element == Double, V.Element == Double
    {
        _AccelerateNumeric.zip3(vectorA, vectorB, &result, *)
    }

    public static func multiply<T, U>(_ vectorA: T, _ vectorB: U) -> [Double] where T: AccelerateBuffer, U: AccelerateBuffer, T.Element == Double, U.Element == Double
    {
        var result = [Double](repeating: 0, count: vectorA.count)
            multiply(vectorA, vectorB, result: &result)
            return result
    }

    public static func multiply<U, V>(_ scalar: Double, _ vector: U, result: inout V) where U: AccelerateBuffer, V: AccelerateMutableBuffer, U.Element == Double, V.Element == Double
    {
        _AccelerateNumeric.map(vector, &result) { $0 * scalar }
    }

    public static func multiply<U>(_ scalar: Double, _ vector: U) -> [Double] where U: AccelerateBuffer, U.Element == Double
    {
        var result = [Double](repeating: 0, count: vector.count)
            multiply(scalar, vector, result: &result)
            return result
    }

    public static func divide<T, U, V>(_ vectorA: T, _ vectorB: U, result: inout V) where T: AccelerateBuffer, U: AccelerateBuffer, V: AccelerateMutableBuffer, T.Element == Double, U.Element == Double, V.Element == Double
    {
        _AccelerateNumeric.zip3(vectorA, vectorB, &result, /)
    }

    public static func divide<T, U>(_ vectorA: T, _ vectorB: U) -> [Double] where T: AccelerateBuffer, U: AccelerateBuffer, T.Element == Double, U.Element == Double
    {
        var result = [Double](repeating: 0, count: vectorA.count)
            divide(vectorA, vectorB, result: &result)
            return result
    }

    public static func addSubtract<S, T, U, V>(_ vectorA: S, _ vectorB: T, addResult: inout U, subtractResult: inout V) where S: AccelerateBuffer, T: AccelerateBuffer, U: AccelerateMutableBuffer, V: AccelerateMutableBuffer, S.Element == Double, T.Element == Double, U.Element == Double, V.Element == Double
    {
        add(vectorA, vectorB, result: &addResult)
            subtract(vectorA, vectorB, result: &subtractResult)
    }

    public static func multiply<T, U, V>(addition: (a: T, b: U), _ scalar: Double, result: inout V) where T: AccelerateBuffer, U: AccelerateBuffer, V: AccelerateMutableBuffer, T.Element == Double, U.Element == Double, V.Element == Double
    {
        _AccelerateNumeric.zip3(addition.a, addition.b, &result) { ($0 + $1) * scalar }
    }

    public static func multiply<T, U>(addition: (a: T, b: U), _ scalar: Double) -> [Double] where T: AccelerateBuffer, U: AccelerateBuffer, T.Element == Double, U.Element == Double
    {
        var result = [Double](repeating: 0, count: addition.a.count)
            multiply(addition: addition, scalar, result: &result)
            return result
    }

    public static func multiply<T, U, V>(subtraction: (a: T, b: U), _ scalar: Double, result: inout V) where T: AccelerateBuffer, U: AccelerateBuffer, V: AccelerateMutableBuffer, T.Element == Double, U.Element == Double, V.Element == Double
    {
        _AccelerateNumeric.zip3(subtraction.a, subtraction.b, &result) { ($0 - $1) * scalar }
    }

    public static func multiply<T, U>(subtraction: (a: T, b: U), _ scalar: Double) -> [Double] where T: AccelerateBuffer, U: AccelerateBuffer, T.Element == Double, U.Element == Double
    {
        var result = [Double](repeating: 0, count: subtraction.a.count)
            multiply(subtraction: subtraction, scalar, result: &result)
            return result
    }

    public static func add<T, U, V>(multiplication: (a: T, b: Double), _ vector: U, result: inout V) where T: AccelerateBuffer, U: AccelerateBuffer, V: AccelerateMutableBuffer, T.Element == Double, U.Element == Double, V.Element == Double
    {
        _AccelerateNumeric.zip3(multiplication.a, vector, &result) { $0 * multiplication.b + $1 }
    }

    public static func add<T, U>(multiplication: (a: T, b: Double), _ vector: U) -> [Double] where T: AccelerateBuffer, U: AccelerateBuffer, T.Element == Double, U.Element == Double
    {
        var result = [Double](repeating: 0, count: multiplication.a.count)
            add(multiplication: multiplication, vector, result: &result)
            return result
    }

    public static func add<U, V>(multiplication: (a: U, b: Double), _ scalar: Double, result: inout V) where U: AccelerateBuffer, V: AccelerateMutableBuffer, U.Element == Double, V.Element == Double
    {
        _AccelerateNumeric.map(multiplication.a, &result) { $0 * multiplication.b + scalar }
    }

    public static func add<U>(multiplication: (a: U, b: Double), _ scalar: Double) -> [Double] where U: AccelerateBuffer, U.Element == Double
    {
        var result = [Double](repeating: 0, count: multiplication.a.count)
            add(multiplication: multiplication, scalar, result: &result)
            return result
    }

    public static func add<T, U, V>(multiplication multiplicationAB: (a: T, b: Double), multiplication multiplicationCD: (c: U, d: Double), result: inout V) where T: AccelerateBuffer, U: AccelerateBuffer, V: AccelerateMutableBuffer, T.Element == Double, U.Element == Double, V.Element == Double
    {
        _AccelerateNumeric.zip3(multiplicationAB.a, multiplicationCD.c, &result) { $0 * multiplicationAB.b + $1 * multiplicationCD.d }
    }

    public static func add<T, U>(multiplication multiplicationAB: (a: T, b: Double), multiplication multiplicationCD: (c: U, d: Double)) -> [Double] where T: AccelerateBuffer, U: AccelerateBuffer, T.Element == Double, U.Element == Double
    {
        var result = [Double](repeating: 0, count: multiplicationAB.a.count)
            add(multiplication: multiplicationAB, multiplication: multiplicationCD, result: &result)
            return result
    }

    public static func hypot<T, U, V>(_ vectorA: T, _ vectorB: U, result: inout V) where T: AccelerateBuffer, U: AccelerateBuffer, V: AccelerateMutableBuffer, T.Element == Double, U.Element == Double, V.Element == Double
    {
        _AccelerateNumeric.zip3(vectorA, vectorB, &result) { Foundation.hypot($0, $1) }
    }

    public static func hypot<T, U>(_ vectorA: T, _ vectorB: U) -> [Double] where T: AccelerateBuffer, U: AccelerateBuffer, T.Element == Double, U.Element == Double
    {
        var result = [Double](repeating: 0, count: vectorA.count)
            hypot(vectorA, vectorB, result: &result)
            return result
    }

    public static func dot<T, U>(_ vectorA: T, _ vectorB: U) -> Double where T: AccelerateBuffer, U: AccelerateBuffer, T.Element == Double, U.Element == Double
    {
        vectorA.withUnsafeBufferPointer { a in
                vectorB.withUnsafeBufferPointer { b in
                    let n = min(a.count, b.count)
                    var s: Double = 0
                    for i in 0..<n { s += a[i] * b[i] }
                    return s
                }
            }
    }

    public static func sum<U>(_ vector: U) -> Double where U: AccelerateBuffer, U.Element == Double
    {
        vector.withUnsafeBufferPointer { $0.reduce(0, +) }
    }

    public static func mean<U>(_ vector: U) -> Double where U: AccelerateBuffer, U.Element == Double
    {
        let n = vector.count
            if n == 0 { return 0 }
            return sum(vector) / Double(n)
    }

    public static func meanSquare<U>(_ vector: U) -> Double where U: AccelerateBuffer, U.Element == Double
    {
        vector.withUnsafeBufferPointer { buf in
                if buf.isEmpty { return 0 }
                var s: Double = 0
                for v in buf { s += v * v }
                return s / Double(buf.count)
            }
    }

    public static func meanMagnitude<U>(_ vector: U) -> Double where U: AccelerateBuffer, U.Element == Double
    {
        vector.withUnsafeBufferPointer { buf in
                if buf.isEmpty { return 0 }
                var s: Double = 0
                for v in buf { s += abs(v) }
                return s / Double(buf.count)
            }
    }

    public static func sumOfSquares<U>(_ vector: U) -> Double where U: AccelerateBuffer, U.Element == Double
    {
        vector.withUnsafeBufferPointer { buf in
                var s: Double = 0
                for v in buf { s += v * v }
                return s
            }
    }

    public static func sumOfMagnitudes<U>(_ vector: U) -> Double where U: AccelerateBuffer, U.Element == Double
    {
        vector.withUnsafeBufferPointer { buf in
                var s: Double = 0
                for v in buf { s += abs(v) }
                return s
            }
    }

    public static func rootMeanSquare<U>(_ vector: U) -> Double where U: AccelerateBuffer, U.Element == Double
    {
        Foundation.sqrt(meanSquare(vector))
    }

    public static func maximum<U>(_ vector: U) -> Double where U: AccelerateBuffer, U.Element == Double
    {
        vector.withUnsafeBufferPointer { $0.max() ?? -.infinity }
    }

    public static func minimum<U>(_ vector: U) -> Double where U: AccelerateBuffer, U.Element == Double
    {
        vector.withUnsafeBufferPointer { $0.min() ?? .infinity }
    }

    public static func maximumMagnitude<U>(_ vector: U) -> Double where U: AccelerateBuffer, U.Element == Double
    {
        vector.withUnsafeBufferPointer { buf in
                var m: Double = 0
                for v in buf { m = max(m, abs(v)) }
                return m
            }
    }

    public static func indexOfMaximum<U>(_ vector: U) -> (index: Int, value: Double) where U: AccelerateBuffer, U.Element == Double
    {
        vector.withUnsafeBufferPointer { buf in
                precondition(!buf.isEmpty)
                var idx = 0
                var best = buf[0]
                for i in 1..<buf.count where buf[i] > best { best = buf[i]; idx = i }
                return (idx, best)
            }
    }

    public static func indexOfMinimum<U>(_ vector: U) -> (index: Int, value: Double) where U: AccelerateBuffer, U.Element == Double
    {
        vector.withUnsafeBufferPointer { buf in
                precondition(!buf.isEmpty)
                var idx = 0
                var best = buf[0]
                for i in 1..<buf.count where buf[i] < best { best = buf[i]; idx = i }
                return (idx, best)
            }
    }

    public static func indexOfMaximumMagnitude<U>(_ vector: U) -> (index: Int, value: Double) where U: AccelerateBuffer, U.Element == Double
    {
        vector.withUnsafeBufferPointer { buf in
                precondition(!buf.isEmpty)
                var idx = 0
                var best = abs(buf[0])
                for i in 1..<buf.count where abs(buf[i]) > best { best = abs(buf[i]); idx = i }
                return (idx, buf[idx])
            }
    }

    public static func standardDeviation(_ vector: some AccelerateMutableBuffer<Double>) -> Double
    {
        let n = vector.count
            if n < 2 { return 0 }
            let mu = mean(vector)
            var acc: Double = 0
            vector.withUnsafeBufferPointer { buf in
                for v in buf { let d = v - mu; acc += d * d }
            }
            return Foundation.sqrt(acc / Double(n))
    }

    public static func sumAndSumOfSquares<U>(_ vector: U) -> (elementsSum: Double, squaresSum: Double) where U: AccelerateBuffer, U.Element == Double
    {
        (sum(vector), sumOfSquares(vector))
    }

    public static func countZeroCrossings<U>(_ vector: U) -> UInt where U: AccelerateBuffer, U.Element == Double
    {
        vector.withUnsafeBufferPointer { buf in
                guard buf.count >= 2 else { return 0 }
                var n: UInt = 0
                for i in 1..<buf.count {
                    if buf[i - 1] == 0 { continue }
                    if (buf[i - 1] > 0) != (buf[i] > 0) && buf[i] != 0 { n += 1 }
                }
                return n
            }
    }

    public static func distanceSquared<T, U>(_ vectorA: T, _ vectorB: U) -> Double where T: AccelerateBuffer, U: AccelerateBuffer, T.Element == Double, U.Element == Double
    {
        vectorA.withUnsafeBufferPointer { a in
                vectorB.withUnsafeBufferPointer { b in
                    let n = min(a.count, b.count)
                    var s: Double = 0
                    for i in 0..<n { let d = a[i] - b[i]; s += d * d }
                    return s
                }
            }
    }

    public static func absolute<U, V>(_ vector: U, result: inout V) where U: AccelerateBuffer, V: AccelerateMutableBuffer, U.Element == Double, V.Element == Double
    {
        _AccelerateNumeric.map(vector, &result, abs)
    }

    public static func absolute<U>(_ vector: U) -> [Double] where U: AccelerateBuffer, U.Element == Double
    {
        var result = [Double](repeating: 0, count: vector.count)
            absolute(vector, result: &result)
            return result
    }

    public static func negative<U, V>(_ vector: U, result: inout V) where U: AccelerateBuffer, V: AccelerateMutableBuffer, U.Element == Double, V.Element == Double
    {
        _AccelerateNumeric.map(vector, &result) { -$0 }
    }

    public static func negative<U>(_ vector: U) -> [Double] where U: AccelerateBuffer, U.Element == Double
    {
        var result = [Double](repeating: 0, count: vector.count)
            negative(vector, result: &result)
            return result
    }

    public static func square<U, V>(_ vector: U, result: inout V) where U: AccelerateBuffer, V: AccelerateMutableBuffer, U.Element == Double, V.Element == Double
    {
        _AccelerateNumeric.map(vector, &result) { $0 * $0 }
    }

    public static func square<U>(_ vector: U) -> [Double] where U: AccelerateBuffer, U.Element == Double
    {
        var result = [Double](repeating: 0, count: vector.count)
            square(vector, result: &result)
            return result
    }

    public static func signedSquare<U, V>(_ vector: U, result: inout V) where U: AccelerateBuffer, V: AccelerateMutableBuffer, U.Element == Double, V.Element == Double
    {
        _AccelerateNumeric.map(vector, &result) { $0 * abs($0) }
    }

    public static func signedSquare<U>(_ vector: U) -> [Double] where U: AccelerateBuffer, U.Element == Double
    {
        var result = [Double](repeating: 0, count: vector.count)
            signedSquare(vector, result: &result)
            return result
    }

    public static func negativeAbsolute<U, V>(_ vector: U, result: inout V) where U: AccelerateBuffer, V: AccelerateMutableBuffer, U.Element == Double, V.Element == Double
    {
        _AccelerateNumeric.map(vector, &result) { -abs($0) }
    }

    public static func negativeAbsolute<U>(_ vector: U) -> [Double] where U: AccelerateBuffer, U.Element == Double
    {
        var result = [Double](repeating: 0, count: vector.count)
            negativeAbsolute(vector, result: &result)
            return result
    }

    public static func trunc<U, V>(_ vector: U, result: inout V) where U: AccelerateBuffer, V: AccelerateMutableBuffer, U.Element == Double, V.Element == Double
    {
        _AccelerateNumeric.map(vector, &result) { $0.rounded(.towardZero) }
    }

    public static func trunc<U>(_ vector: U) -> [Double] where U: AccelerateBuffer, U.Element == Double
    {
        var result = [Double](repeating: 0, count: vector.count)
            trunc(vector, result: &result)
            return result
    }

    public static func fill<V>(_ vector: inout V, with value: Double) where V: AccelerateMutableBuffer, V.Element == Double
    {
        vector.withUnsafeMutableBufferPointer { dest in
                for i in dest.indices { dest[i] = value }
            }
    }

    public static func clear<V>(_ vector: inout V) where V: AccelerateMutableBuffer, V.Element == Double
    {
        fill(&vector, with: 0)
    }

    public static func reverse<V>(_ vector: inout V) where V: AccelerateMutableBuffer, V.Element == Double
    {
        vector.withUnsafeMutableBufferPointer { dest in
                var i = 0
                var j = dest.count - 1
                while i < j {
                    let t = dest[i]; dest[i] = dest[j]; dest[j] = t
                    i += 1; j -= 1
                }
            }
    }

    public static func swapElements<T, U>(_ vectorA: inout T, _ vectorB: inout U) where T: AccelerateMutableBuffer, U: AccelerateMutableBuffer, T.Element == Double, U.Element == Double
    {
        vectorA.withUnsafeMutableBufferPointer { a in
                vectorB.withUnsafeMutableBufferPointer { b in
                    let n = min(a.count, b.count)
                    for i in 0..<n { let t = a[i]; a[i] = b[i]; b[i] = t }
                }
            }
    }

    public static func clip<U, V>(_ vector: U, to bounds: ClosedRange<Double>, result: inout V) where U: AccelerateBuffer, V: AccelerateMutableBuffer, U.Element == Double, V.Element == Double
    {
        _AccelerateNumeric.map(vector, &result) { min(max($0, bounds.lowerBound), bounds.upperBound) }
    }

    public static func clip<U>(_ vector: U, to bounds: ClosedRange<Double>) -> [Double] where U: AccelerateBuffer, U.Element == Double
    {
        var result = [Double](repeating: 0, count: vector.count)
            clip(vector, to: bounds, result: &result)
            return result
    }

    public static func invertedClip<U, V>(_ vector: U, to bounds: ClosedRange<Double>, result: inout V) where U: AccelerateBuffer, V: AccelerateMutableBuffer, U.Element == Double, V.Element == Double
    {
        _AccelerateNumeric.map(vector, &result) { v in
                if v > bounds.lowerBound && v < bounds.upperBound { return 0 }
                return v
            }
    }

    public static func invertedClip<U>(_ vector: U, to bounds: ClosedRange<Double>) -> [Double] where U: AccelerateBuffer, U.Element == Double
    {
        var result = [Double](repeating: 0, count: vector.count)
            invertedClip(vector, to: bounds, result: &result)
            return result
    }

    public static func limit<U, V>(_ vector: U, limit: Double, withOutputLimitedTo outputLimit: Double, result: inout V) where U: AccelerateBuffer, V: AccelerateMutableBuffer, U.Element == Double, V.Element == Double
    {
        _AccelerateNumeric.map(vector, &result) { abs($0) > abs(limit) ? ($0 < 0 ? -outputLimit : outputLimit) : $0 }
    }

    public static func limit<U>(_ vector: U, limit: Double, withOutputLimitedTo outputLimit: Double) -> [Double] where U: AccelerateBuffer, U.Element == Double
    {
        var result = [Double](repeating: 0, count: vector.count)
            vDSP.limit(vector, limit: limit, withOutputLimitedTo: outputLimit, result: &result)
            return result
    }

    public static func threshold<U, V>(_ vector: U, to lowerBound: Double, with rule: vDSP.ThresholdRule<Double>, result: inout V) where U: AccelerateBuffer, V: AccelerateMutableBuffer, U.Element == Double, V.Element == Double
    {
        _AccelerateNumeric.map(vector, &result) { v in
                if v >= lowerBound { return v }
                switch rule {
                case .clampToThreshold: return lowerBound
                case .zeroFill: return 0
                case .signedConstant(let c): return v < 0 ? -c : c
                }
            }
    }

    public static func threshold<U>(_ vector: U, to lowerBound: Double, with rule: vDSP.ThresholdRule<Double>) -> [Double] where U: AccelerateBuffer, U.Element == Double
    {
        var result = [Double](repeating: 0, count: vector.count)
            threshold(vector, to: lowerBound, with: rule, result: &result)
            return result
    }

    public static func formWindow<V>(usingSequence sequence: vDSP.WindowSequence, result: inout V, isHalfWindow: Bool) where V: AccelerateMutableBuffer, V.Element == Double
    {
        result.withUnsafeMutableBufferPointer { dest in
                let n = dest.count
                guard n > 0 else { return }
                let full = isHalfWindow ? (n - 1) * 2 : (n - 1)
                for i in 0..<n {
                    let x = Double(i) / Double(max(full, 1))
                    let w: Double
                    switch sequence {
                    case .hanningNormalized:
                        w = 0.5 - 0.5 * Foundation.cos(2 * Double.pi * x)
                    case .hanningDenormalized:
                        w = 0.5 - 0.5 * Foundation.cos(2 * Double.pi * x)
                    case .hamming:
                        w = 0.54 - 0.46 * Foundation.cos(2 * Double.pi * x)
                    case .blackman:
                        w = 0.42 - 0.5 * Foundation.cos(2 * Double.pi * x) + 0.08 * Foundation.cos(4 * Double.pi * x)
                    }
                    dest[i] = w
                }
            }
    }

    public static func formRamp<V>(withInitialValue start: Double, increment: Double, result: inout V) where V: AccelerateMutableBuffer, V.Element == Double
    {
        result.withUnsafeMutableBufferPointer { dest in
                var v = start
                for i in dest.indices { dest[i] = v; v += increment }
            }
    }

    public static func ramp<U>(withInitialValue start: inout Double, multiplyingBy multipliers: U, increment: Double) -> [Double] where U: AccelerateBuffer, U.Element == Double
    {
        var out = [Double](repeating: 0, count: multipliers.count)
            multipliers.withUnsafeBufferPointer { m in
                var v = start
                for i in 0..<m.count { out[i] = v * m[i]; v += increment }
                start = v
            }
            return out
    }

    public static func convolve<T, U, V>(_ vector: T, withKernel kernel: U, result: inout V) where T: AccelerateBuffer, U: AccelerateBuffer, V: AccelerateMutableBuffer, T.Element == Double, U.Element == Double, V.Element == Double
    {
        vector.withUnsafeBufferPointer { src in
                kernel.withUnsafeBufferPointer { k in
                    result.withUnsafeMutableBufferPointer { dest in
                        let outN = min(dest.count, max(0, src.count - k.count + 1))
                        for i in 0..<outN {
                            var s: Double = 0
                            for j in 0..<k.count { s += src[i + j] * k[j] }
                            dest[i] = s
                        }
                    }
                }
            }
    }

    public static func convolve<T, U>(_ vector: T, withKernel kernel: U) -> [Double] where T: AccelerateBuffer, U: AccelerateBuffer, T.Element == Double, U.Element == Double
    {
        let n = max(0, vector.count - kernel.count + 1)
            var result = [Double](repeating: 0, count: n)
            convolve(vector, withKernel: kernel, result: &result)
            return result
    }

    public static func correlate<T, U, V>(_ vector: T, withKernel kernel: U, result: inout V) where T: AccelerateBuffer, U: AccelerateBuffer, V: AccelerateMutableBuffer, T.Element == Double, U.Element == Double, V.Element == Double
    {
        vector.withUnsafeBufferPointer { src in
                kernel.withUnsafeBufferPointer { k in
                    result.withUnsafeMutableBufferPointer { dest in
                        let outN = min(dest.count, max(0, src.count - k.count + 1))
                        for i in 0..<outN {
                            var s: Double = 0
                            for j in 0..<k.count { s += src[i + j] * k[k.count - 1 - j] }
                            dest[i] = s
                        }
                    }
                }
            }
    }

    public static func correlate<T, U>(_ vector: T, withKernel kernel: U) -> [Double] where T: AccelerateBuffer, U: AccelerateBuffer, T.Element == Double, U.Element == Double
    {
        let n = max(0, vector.count - kernel.count + 1)
            var result = [Double](repeating: 0, count: n)
            correlate(vector, withKernel: kernel, result: &result)
            return result
    }

    public static func convolve<T, U, V>(_ vector: T, rowCount: Int, columnCount: Int, withKernel kernel: U, kernelRowCount: Int, kernelColumnCount: Int, result: inout V) where T: AccelerateBuffer, U: AccelerateBuffer, V: AccelerateMutableBuffer, T.Element == Double, U.Element == Double, V.Element == Double
    {
        vector.withUnsafeBufferPointer { src in
                kernel.withUnsafeBufferPointer { k in
                    result.withUnsafeMutableBufferPointer { dest in
                        let outRows = max(0, rowCount - kernelRowCount + 1)
                        let outCols = max(0, columnCount - kernelColumnCount + 1)
                        for r in 0..<outRows {
                            for c in 0..<outCols {
                                var s: Double = 0
                                for kr in 0..<kernelRowCount {
                                    for kc in 0..<kernelColumnCount {
                                        s += src[(r + kr) * columnCount + (c + kc)] * k[kr * kernelColumnCount + kc]
                                    }
                                }
                                dest[r * outCols + c] = s
                            }
                        }
                    }
                }
            }
    }

    public static func convolve<T, U>(_ vector: T, rowCount: Int, columnCount: Int, withKernel kernel: U, kernelRowCount: Int, kernelColumnCount: Int) -> [Double] where T: AccelerateBuffer, U: AccelerateBuffer, T.Element == Double, U.Element == Double
    {
        let outRows = max(0, rowCount - kernelRowCount + 1)
            let outCols = max(0, columnCount - kernelColumnCount + 1)
            var result = [Double](repeating: 0, count: outRows * outCols)
            convolve(vector, rowCount: rowCount, columnCount: columnCount, withKernel: kernel, kernelRowCount: kernelRowCount, kernelColumnCount: kernelColumnCount, result: &result)
            return result
    }

    public static func convolve<T, U, V>(_ vector: T, rowCount: Int, columnCount: Int, with3x3Kernel kernel: U, result: inout V) where T: AccelerateBuffer, U: AccelerateBuffer, V: AccelerateMutableBuffer, T.Element == Double, U.Element == Double, V.Element == Double
    {
        convolve(vector, rowCount: rowCount, columnCount: columnCount, withKernel: kernel, kernelRowCount: 3, kernelColumnCount: 3, result: &result)
    }

    public static func convolve<T, U>(_ vector: T, rowCount: Int, columnCount: Int, with3x3Kernel kernel: U) -> [Double] where T: AccelerateBuffer, U: AccelerateBuffer, T.Element == Double, U.Element == Double
    {
        convolve(vector, rowCount: rowCount, columnCount: columnCount, withKernel: kernel, kernelRowCount: 3, kernelColumnCount: 3)
    }

    public static func convolve<T, U, V>(_ vector: T, rowCount: Int, columnCount: Int, with5x5Kernel kernel: U, result: inout V) where T: AccelerateBuffer, U: AccelerateBuffer, V: AccelerateMutableBuffer, T.Element == Double, U.Element == Double, V.Element == Double
    {
        convolve(vector, rowCount: rowCount, columnCount: columnCount, withKernel: kernel, kernelRowCount: 5, kernelColumnCount: 5, result: &result)
    }

    public static func convolve<T, U>(_ vector: T, rowCount: Int, columnCount: Int, with5x5Kernel kernel: U) -> [Double] where T: AccelerateBuffer, U: AccelerateBuffer, T.Element == Double, U.Element == Double
    {
        convolve(vector, rowCount: rowCount, columnCount: columnCount, withKernel: kernel, kernelRowCount: 5, kernelColumnCount: 5)
    }

    public static func slidingWindowSum<U, V>(_ vector: U, usingWindowLength windowLength: Int, result: inout V) where U: AccelerateBuffer, V: AccelerateMutableBuffer, U.Element == Double, V.Element == Double
    {
        vector.withUnsafeBufferPointer { src in
                result.withUnsafeMutableBufferPointer { dest in
                    let w = max(windowLength, 1)
                    let outN = min(dest.count, max(0, src.count - w + 1))
                    for i in 0..<outN {
                        var s: Double = 0
                        for j in 0..<w { s += src[i + j] }
                        dest[i] = s
                    }
                }
            }
    }

    public static func slidingWindowSum<U>(_ vector: U, usingWindowLength windowLength: Int) -> [Double] where U: AccelerateBuffer, U.Element == Double
    {
        let n = max(0, vector.count - max(windowLength, 1) + 1)
            var result = [Double](repeating: 0, count: n)
            slidingWindowSum(vector, usingWindowLength: windowLength, result: &result)
            return result
    }

    public static func downsample<T, U, V>(_ vector: T, decimationFactor: Int, filter: U, result: inout V) where T: AccelerateBuffer, U: AccelerateBuffer, V: AccelerateMutableBuffer, T.Element == Double, U.Element == Double, V.Element == Double
    {
        let factor = max(decimationFactor, 1)
            vector.withUnsafeBufferPointer { src in
                filter.withUnsafeBufferPointer { k in
                    result.withUnsafeMutableBufferPointer { dest in
                        var di = 0
                        var i = 0
                        while i + k.count <= src.count && di < dest.count {
                            var s: Double = 0
                            for j in 0..<k.count { s += src[i + j] * k[j] }
                            dest[di] = s
                            di += 1
                            i += factor
                        }
                    }
                }
            }
    }

    public static func downsample<T, U>(_ vector: T, decimationFactor: Int, filter: U) -> [Double] where T: AccelerateBuffer, U: AccelerateBuffer, T.Element == Double, U.Element == Double
    {
        let factor = max(decimationFactor, 1)
            let n = max(0, (vector.count - filter.count) / factor + 1)
            var result = [Double](repeating: 0, count: n)
            downsample(vector, decimationFactor: decimationFactor, filter: filter, result: &result)
            return result
    }

    public static func linearInterpolate<T, U>(_ vectorA: T, _ vectorB: U, using interpolationConstant: Double) -> [Double] where T: AccelerateBuffer, U: AccelerateBuffer, T.Element == Double, U.Element == Double
    {
        var result = [Double](repeating: 0, count: vectorA.count)
            linearInterpolate(vectorA, vectorB, using: interpolationConstant, result: &result)
            return result
    }

    public static func linearInterpolate<T, U, V>(_ vectorA: T, _ vectorB: U, using interpolationConstant: Double, result: inout V) where T: AccelerateBuffer, U: AccelerateBuffer, V: AccelerateMutableBuffer, T.Element == Double, U.Element == Double, V.Element == Double
    {
        _AccelerateNumeric.zip3(vectorA, vectorB, &result) { $0 + interpolationConstant * ($1 - $0) }
    }

    public static func evaluatePolynomial<U, V>(usingCoefficients coefficients: [Double], withVariables variables: U, result: inout V) where U: AccelerateBuffer, V: AccelerateMutableBuffer, U.Element == Double, V.Element == Double
    {
        variables.withUnsafeBufferPointer { xs in
                result.withUnsafeMutableBufferPointer { dest in
                    let n = min(xs.count, dest.count)
                    for i in 0..<n {
                        var acc: Double = 0
                        for c in coefficients { acc = acc * xs[i] + c }
                        dest[i] = acc
                    }
                }
            }
    }

    public static func evaluatePolynomial<U>(usingCoefficients coefficients: [Double], withVariables variables: U) -> [Double] where U: AccelerateBuffer, U.Element == Double
    {
        var result = [Double](repeating: 0, count: variables.count)
            evaluatePolynomial(usingCoefficients: coefficients, withVariables: variables, result: &result)
            return result
    }

    public static func powerToDecibels<U>(_ power: U, zeroReference: Double) -> [Double] where U: AccelerateBuffer, U.Element == Double
    {
        let z = max(zeroReference, Double.leastNonzeroMagnitude)
            var out = [Double](repeating: 0, count: power.count)
            power.withUnsafeBufferPointer { src in
                for i in 0..<src.count {
                    out[i] = 10 * Foundation.log10(max(src[i], 0) / z)
                }
            }
            return out
    }

    public static func amplitudeToDecibels<U>(_ amplitude: U, zeroReference: Double) -> [Double] where U: AccelerateBuffer, U.Element == Double
    {
        let z = max(zeroReference, Double.leastNonzeroMagnitude)
            var out = [Double](repeating: 0, count: amplitude.count)
            amplitude.withUnsafeBufferPointer { src in
                for i in 0..<src.count {
                    out[i] = 20 * Foundation.log10(abs(src[i]) / z)
                }
            }
            return out
    }

    public static func normalize<U, V>(_ vector: U, result: inout V) -> (mean: Double, standardDeviation: Double) where U: AccelerateBuffer, V: AccelerateMutableBuffer, U.Element == Double, V.Element == Double
    {
        let mu = mean(vector)
            let sd = Foundation.sqrt(max(0, meanSquare(vector) - mu * mu))
            let denom = sd == 0 ? 1 : sd
            _AccelerateNumeric.map(vector, &result) { ($0 - mu) / denom }
            return (mu, sd)
    }

    public static func sort<V>(_ vector: inout V, order: vDSP.SortOrder) where V: AccelerateMutableBuffer, V.Element == Double
    {
        vector.withUnsafeMutableBufferPointer { dest in
                dest.sort(by: order == .ascending ? (<) : (>))
            }
    }

    public static func integrate<U, V>(_ vector: U, using rule: vDSP.IntegrationRule, result: inout V) where U: AccelerateBuffer, V: AccelerateMutableBuffer, U.Element == Double, V.Element == Double
    {
        vector.withUnsafeBufferPointer { src in
                result.withUnsafeMutableBufferPointer { dest in
                    let n = min(src.count, dest.count)
                    var acc: Double = 0
                    for i in 0..<n {
                        switch rule {
                        case .runningSum:
                            acc += src[i]
                            dest[i] = acc
                        case .trapezoidal:
                            if i == 0 { dest[i] = 0 }
                            else { acc += (src[i - 1] + src[i]) / 2; dest[i] = acc }
                        case .simpson:
                            acc += src[i]
                            dest[i] = acc
                        }
                    }
                }
            }
    }

    public static func gather<T, U, V>(_ vector: T, indices: U, result: inout V) where T: AccelerateBuffer, U: AccelerateBuffer, V: AccelerateMutableBuffer, T.Element == Double, U.Element == Double, V.Element == Double
    {
        vector.withUnsafeBufferPointer { src in
                indices.withUnsafeBufferPointer { idx in
                    result.withUnsafeMutableBufferPointer { dest in
                        let n = min(idx.count, dest.count)
                        for i in 0..<n {
                            let j = Int(idx[i])
                            dest[i] = (j >= 0 && j < src.count) ? src[j] : 0
                        }
                    }
                }
            }
    }

    public static func convertElements<U, V>(of source: U, to destination: inout V) where U: AccelerateBuffer, V: AccelerateMutableBuffer, U.Element == Double, V.Element == Double
    {
        _AccelerateNumeric.map(source, &destination) { $0 }
    }

    public static func doubleToFloat<U>(_ source: U) -> [Float] where U: AccelerateBuffer, U.Element == Double
    {
        source.withUnsafeBufferPointer { $0.map { Float($0) } }
    }

    public static func floatToDouble<U>(_ source: U) -> [Double] where U: AccelerateBuffer, U.Element == Float
    {
        source.withUnsafeBufferPointer { $0.map { Double($0) } }
    }

    public static func convertElements<U, V>(of source: U, to destination: inout V) where U: AccelerateBuffer, V: AccelerateMutableBuffer, U.Element == Double, V.Element == Float
    {
        _AccelerateNumeric.map(source, &destination) { Float($0) }
    }

    public static func convertElements<U, V>(of source: U, to destination: inout V) where U: AccelerateBuffer, V: AccelerateMutableBuffer, U.Element == Float, V.Element == Double
    {
        _AccelerateNumeric.map(source, &destination) { Double($0) }
    }

    public static func convertElements<U, V>(of source: U, to destination: inout V) where U: AccelerateBuffer, V: AccelerateMutableBuffer, U.Element == Int8, V.Element == Float
    {
        _AccelerateNumeric.map(source, &destination) { Float($0) }
    }

    public static func convertElements<U, V>(of source: U, to destination: inout V, rounding: vDSP.RoundingMode) where U: AccelerateBuffer, V: AccelerateMutableBuffer, U.Element == Float, V.Element == Int8
    {
        _AccelerateNumeric.map(source, &destination) { v in
                let r: Float = rounding == .towardZero ? v.rounded(.towardZero) : v.rounded(.toNearestOrEven)
                return Int8(clamping: Int(r))
            }
    }

    public static func convertElements<U, V>(of source: U, to destination: inout V) where U: AccelerateBuffer, V: AccelerateMutableBuffer, U.Element == Int8, V.Element == Double
    {
        _AccelerateNumeric.map(source, &destination) { Double($0) }
    }

    public static func convertElements<U, V>(of source: U, to destination: inout V, rounding: vDSP.RoundingMode) where U: AccelerateBuffer, V: AccelerateMutableBuffer, U.Element == Double, V.Element == Int8
    {
        _AccelerateNumeric.map(source, &destination) { v in
                let r: Double = rounding == .towardZero ? v.rounded(.towardZero) : v.rounded(.toNearestOrEven)
                return Int8(clamping: Int(r))
            }
    }

    public static func convertElements<U, V>(of source: U, to destination: inout V) where U: AccelerateBuffer, V: AccelerateMutableBuffer, U.Element == Int16, V.Element == Float
    {
        _AccelerateNumeric.map(source, &destination) { Float($0) }
    }

    public static func convertElements<U, V>(of source: U, to destination: inout V, rounding: vDSP.RoundingMode) where U: AccelerateBuffer, V: AccelerateMutableBuffer, U.Element == Float, V.Element == Int16
    {
        _AccelerateNumeric.map(source, &destination) { v in
                let r: Float = rounding == .towardZero ? v.rounded(.towardZero) : v.rounded(.toNearestOrEven)
                return Int16(clamping: Int(r))
            }
    }

    public static func convertElements<U, V>(of source: U, to destination: inout V) where U: AccelerateBuffer, V: AccelerateMutableBuffer, U.Element == Int16, V.Element == Double
    {
        _AccelerateNumeric.map(source, &destination) { Double($0) }
    }

    public static func convertElements<U, V>(of source: U, to destination: inout V, rounding: vDSP.RoundingMode) where U: AccelerateBuffer, V: AccelerateMutableBuffer, U.Element == Double, V.Element == Int16
    {
        _AccelerateNumeric.map(source, &destination) { v in
                let r: Double = rounding == .towardZero ? v.rounded(.towardZero) : v.rounded(.toNearestOrEven)
                return Int16(clamping: Int(r))
            }
    }

    public static func convertElements<U, V>(of source: U, to destination: inout V) where U: AccelerateBuffer, V: AccelerateMutableBuffer, U.Element == Int32, V.Element == Float
    {
        _AccelerateNumeric.map(source, &destination) { Float($0) }
    }

    public static func convertElements<U, V>(of source: U, to destination: inout V, rounding: vDSP.RoundingMode) where U: AccelerateBuffer, V: AccelerateMutableBuffer, U.Element == Float, V.Element == Int32
    {
        _AccelerateNumeric.map(source, &destination) { v in
                let r: Float = rounding == .towardZero ? v.rounded(.towardZero) : v.rounded(.toNearestOrEven)
                return Int32(clamping: Int(r))
            }
    }

    public static func convertElements<U, V>(of source: U, to destination: inout V) where U: AccelerateBuffer, V: AccelerateMutableBuffer, U.Element == Int32, V.Element == Double
    {
        _AccelerateNumeric.map(source, &destination) { Double($0) }
    }

    public static func convertElements<U, V>(of source: U, to destination: inout V, rounding: vDSP.RoundingMode) where U: AccelerateBuffer, V: AccelerateMutableBuffer, U.Element == Double, V.Element == Int32
    {
        _AccelerateNumeric.map(source, &destination) { v in
                let r: Double = rounding == .towardZero ? v.rounded(.towardZero) : v.rounded(.toNearestOrEven)
                return Int32(clamping: Int(r))
            }
    }

    public static func convertElements<U, V>(of source: U, to destination: inout V) where U: AccelerateBuffer, V: AccelerateMutableBuffer, U.Element == UInt8, V.Element == Float
    {
        _AccelerateNumeric.map(source, &destination) { Float($0) }
    }

    public static func convertElements<U, V>(of source: U, to destination: inout V, rounding: vDSP.RoundingMode) where U: AccelerateBuffer, V: AccelerateMutableBuffer, U.Element == Float, V.Element == UInt8
    {
        _AccelerateNumeric.map(source, &destination) { v in
                let r: Float = rounding == .towardZero ? v.rounded(.towardZero) : v.rounded(.toNearestOrEven)
                return UInt8(clamping: Int(r))
            }
    }

    public static func convertElements<U, V>(of source: U, to destination: inout V) where U: AccelerateBuffer, V: AccelerateMutableBuffer, U.Element == UInt8, V.Element == Double
    {
        _AccelerateNumeric.map(source, &destination) { Double($0) }
    }

    public static func convertElements<U, V>(of source: U, to destination: inout V, rounding: vDSP.RoundingMode) where U: AccelerateBuffer, V: AccelerateMutableBuffer, U.Element == Double, V.Element == UInt8
    {
        _AccelerateNumeric.map(source, &destination) { v in
                let r: Double = rounding == .towardZero ? v.rounded(.towardZero) : v.rounded(.toNearestOrEven)
                return UInt8(clamping: Int(r))
            }
    }

    public static func convertElements<U, V>(of source: U, to destination: inout V) where U: AccelerateBuffer, V: AccelerateMutableBuffer, U.Element == UInt16, V.Element == Float
    {
        _AccelerateNumeric.map(source, &destination) { Float($0) }
    }

    public static func convertElements<U, V>(of source: U, to destination: inout V, rounding: vDSP.RoundingMode) where U: AccelerateBuffer, V: AccelerateMutableBuffer, U.Element == Float, V.Element == UInt16
    {
        _AccelerateNumeric.map(source, &destination) { v in
                let r: Float = rounding == .towardZero ? v.rounded(.towardZero) : v.rounded(.toNearestOrEven)
                return UInt16(clamping: Int(r))
            }
    }

    public static func convertElements<U, V>(of source: U, to destination: inout V) where U: AccelerateBuffer, V: AccelerateMutableBuffer, U.Element == UInt16, V.Element == Double
    {
        _AccelerateNumeric.map(source, &destination) { Double($0) }
    }

    public static func convertElements<U, V>(of source: U, to destination: inout V, rounding: vDSP.RoundingMode) where U: AccelerateBuffer, V: AccelerateMutableBuffer, U.Element == Double, V.Element == UInt16
    {
        _AccelerateNumeric.map(source, &destination) { v in
                let r: Double = rounding == .towardZero ? v.rounded(.towardZero) : v.rounded(.toNearestOrEven)
                return UInt16(clamping: Int(r))
            }
    }

    public static func convertElements<U, V>(of source: U, to destination: inout V) where U: AccelerateBuffer, V: AccelerateMutableBuffer, U.Element == UInt32, V.Element == Float
    {
        _AccelerateNumeric.map(source, &destination) { Float($0) }
    }

    public static func convertElements<U, V>(of source: U, to destination: inout V, rounding: vDSP.RoundingMode) where U: AccelerateBuffer, V: AccelerateMutableBuffer, U.Element == Float, V.Element == UInt32
    {
        _AccelerateNumeric.map(source, &destination) { v in
                let r: Float = rounding == .towardZero ? v.rounded(.towardZero) : v.rounded(.toNearestOrEven)
                return UInt32(clamping: Int(r))
            }
    }

    public static func convertElements<U, V>(of source: U, to destination: inout V) where U: AccelerateBuffer, V: AccelerateMutableBuffer, U.Element == UInt32, V.Element == Double
    {
        _AccelerateNumeric.map(source, &destination) { Double($0) }
    }

    public static func convertElements<U, V>(of source: U, to destination: inout V, rounding: vDSP.RoundingMode) where U: AccelerateBuffer, V: AccelerateMutableBuffer, U.Element == Double, V.Element == UInt32
    {
        _AccelerateNumeric.map(source, &destination) { v in
                let r: Double = rounding == .towardZero ? v.rounded(.towardZero) : v.rounded(.toNearestOrEven)
                return UInt32(clamping: Int(r))
            }
    }

    public static func multiply(_ splitComplexA: DSPSplitComplex, by splitComplexB: DSPSplitComplex, count: Int, useConjugate: Bool, result: inout DSPSplitComplex)
    {
        for i in 0..<count {
                let ar = splitComplexA.realp[i], ai = splitComplexA.imagp[i]
                let br = splitComplexB.realp[i], bi = useConjugate ? -splitComplexB.imagp[i] : splitComplexB.imagp[i]
                result.realp[i] = ar * br - ai * bi
                result.imagp[i] = ar * bi + ai * br
            }
    }

    public static func multiply(_ splitComplexA: DSPDoubleSplitComplex, by splitComplexB: DSPDoubleSplitComplex, count: Int, useConjugate: Bool, result: inout DSPDoubleSplitComplex)
    {
        for i in 0..<count {
                let ar = splitComplexA.realp[i], ai = splitComplexA.imagp[i]
                let br = splitComplexB.realp[i], bi = useConjugate ? -splitComplexB.imagp[i] : splitComplexB.imagp[i]
                result.realp[i] = ar * br - ai * bi
                result.imagp[i] = ar * bi + ai * br
            }
    }

    public static func squareMagnitudes<V>(_ splitComplex: DSPSplitComplex, result: inout V) where V: AccelerateMutableBuffer, V.Element == Float
    {
        result.withUnsafeMutableBufferPointer { dest in
                let n = min(dest.count, Int.max)
                for i in 0..<n {
                    let r = splitComplex.realp[i], im = splitComplex.imagp[i]
                    dest[i] = r * r + im * im
                }
            }
    }

    public static func squareMagnitudes<V>(_ splitComplex: DSPDoubleSplitComplex, result: inout V) where V: AccelerateMutableBuffer, V.Element == Double
    {
        result.withUnsafeMutableBufferPointer { dest in
                for i in dest.indices {
                    let r = splitComplex.realp[i], im = splitComplex.imagp[i]
                    dest[i] = r * r + im * im
                }
            }
    }

    public static func conjugate(_ splitComplex: inout DSPSplitComplex, count: Int)
    {
        for i in 0..<count { splitComplex.imagp[i] = -splitComplex.imagp[i] }
    }

    public static func conjugate(_ splitComplex: inout DSPDoubleSplitComplex, count: Int)
    {
        for i in 0..<count { splitComplex.imagp[i] = -splitComplex.imagp[i] }
    }

}
