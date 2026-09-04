import Foundation

extension vDSP {
    public static func add<T, U, V>(
        _ vectorA: T,
        _ vectorB: U,
        result: inout V
    ) where T: AccelerateBuffer, U: AccelerateBuffer, V: AccelerateMutableBuffer,
        T.Element == Float, U.Element == Float, V.Element == Float
    {
        vectorA.withUnsafeBufferPointer { a in
            vectorB.withUnsafeBufferPointer { b in
                result.withUnsafeMutableBufferPointer { out in
                    let n = min(a.count, min(b.count, out.count))
                    for i in 0..<n {
                        out[i] = a[i] + b[i]
                    }
                }
            }
        }
    }

    public static func add<T, U, V>(
        _ vectorA: T,
        _ vectorB: U,
        result: inout V
    ) where T: AccelerateBuffer, U: AccelerateBuffer, V: AccelerateMutableBuffer,
        T.Element == Double, U.Element == Double, V.Element == Double
    {
        vectorA.withUnsafeBufferPointer { a in
            vectorB.withUnsafeBufferPointer { b in
                result.withUnsafeMutableBufferPointer { out in
                    let n = min(a.count, min(b.count, out.count))
                    for i in 0..<n {
                        out[i] = a[i] + b[i]
                    }
                }
            }
        }
    }

    public static func add<T, U>(_ vectorA: T, _ vectorB: U) -> [Float]
    where T: AccelerateBuffer, U: AccelerateBuffer, T.Element == Float, U.Element == Float {
        var result = [Float](repeating: 0, count: vectorA.count)
        add(vectorA, vectorB, result: &result)
        return result
    }

    public static func add<T, U>(_ vectorA: T, _ vectorB: U) -> [Double]
    where T: AccelerateBuffer, U: AccelerateBuffer, T.Element == Double, U.Element == Double {
        var result = [Double](repeating: 0, count: vectorA.count)
        add(vectorA, vectorB, result: &result)
        return result
    }

    public static func subtract<T, U, V>(
        _ vectorA: T,
        _ vectorB: U,
        result: inout V
    ) where T: AccelerateBuffer, U: AccelerateBuffer, V: AccelerateMutableBuffer,
        T.Element == Float, U.Element == Float, V.Element == Float
    {
        vectorA.withUnsafeBufferPointer { a in
            vectorB.withUnsafeBufferPointer { b in
                result.withUnsafeMutableBufferPointer { out in
                    let n = min(a.count, min(b.count, out.count))
                    for i in 0..<n {
                        out[i] = a[i] - b[i]
                    }
                }
            }
        }
    }

    public static func subtract<T, U, V>(
        _ vectorA: T,
        _ vectorB: U,
        result: inout V
    ) where T: AccelerateBuffer, U: AccelerateBuffer, V: AccelerateMutableBuffer,
        T.Element == Double, U.Element == Double, V.Element == Double
    {
        vectorA.withUnsafeBufferPointer { a in
            vectorB.withUnsafeBufferPointer { b in
                result.withUnsafeMutableBufferPointer { out in
                    let n = min(a.count, min(b.count, out.count))
                    for i in 0..<n {
                        out[i] = a[i] - b[i]
                    }
                }
            }
        }
    }

    public static func multiply<T, U, V>(
        _ vectorA: T,
        _ vectorB: U,
        result: inout V
    ) where T: AccelerateBuffer, U: AccelerateBuffer, V: AccelerateMutableBuffer,
        T.Element == Float, U.Element == Float, V.Element == Float
    {
        vectorA.withUnsafeBufferPointer { a in
            vectorB.withUnsafeBufferPointer { b in
                result.withUnsafeMutableBufferPointer { out in
                    let n = min(a.count, min(b.count, out.count))
                    for i in 0..<n {
                        out[i] = a[i] * b[i]
                    }
                }
            }
        }
    }

    public static func multiply<T, U, V>(
        _ vectorA: T,
        _ vectorB: U,
        result: inout V
    ) where T: AccelerateBuffer, U: AccelerateBuffer, V: AccelerateMutableBuffer,
        T.Element == Double, U.Element == Double, V.Element == Double
    {
        vectorA.withUnsafeBufferPointer { a in
            vectorB.withUnsafeBufferPointer { b in
                result.withUnsafeMutableBufferPointer { out in
                    let n = min(a.count, min(b.count, out.count))
                    for i in 0..<n {
                        out[i] = a[i] * b[i]
                    }
                }
            }
        }
    }

    public static func multiply<T, U>(_ vectorA: T, _ vectorB: U) -> [Float]
    where T: AccelerateBuffer, U: AccelerateBuffer, T.Element == Float, U.Element == Float {
        var result = [Float](repeating: 0, count: vectorA.count)
        multiply(vectorA, vectorB, result: &result)
        return result
    }

    public static func divide<T, U, V>(
        _ vectorA: T,
        _ vectorB: U,
        result: inout V
    ) where T: AccelerateBuffer, U: AccelerateBuffer, V: AccelerateMutableBuffer,
        T.Element == Float, U.Element == Float, V.Element == Float
    {
        vectorA.withUnsafeBufferPointer { a in
            vectorB.withUnsafeBufferPointer { b in
                result.withUnsafeMutableBufferPointer { out in
                    let n = min(a.count, min(b.count, out.count))
                    for i in 0..<n {
                        out[i] = a[i] / b[i]
                    }
                }
            }
        }
    }

    public static func divide<T, U, V>(
        _ vectorA: T,
        _ vectorB: U,
        result: inout V
    ) where T: AccelerateBuffer, U: AccelerateBuffer, V: AccelerateMutableBuffer,
        T.Element == Double, U.Element == Double, V.Element == Double
    {
        vectorA.withUnsafeBufferPointer { a in
            vectorB.withUnsafeBufferPointer { b in
                result.withUnsafeMutableBufferPointer { out in
                    let n = min(a.count, min(b.count, out.count))
                    for i in 0..<n {
                        out[i] = a[i] / b[i]
                    }
                }
            }
        }
    }

    public static func dot<T, U>(_ vectorA: T, _ vectorB: U) -> Float
    where T: AccelerateBuffer, U: AccelerateBuffer, T.Element == Float, U.Element == Float {
        vectorA.withUnsafeBufferPointer { a in
            vectorB.withUnsafeBufferPointer { b in
                let n = min(a.count, b.count)
                var sum: Float = 0
                for i in 0..<n {
                    sum += a[i] * b[i]
                }
                return sum
            }
        }
    }

    public static func dot<T, U>(_ vectorA: T, _ vectorB: U) -> Double
    where T: AccelerateBuffer, U: AccelerateBuffer, T.Element == Double, U.Element == Double {
        vectorA.withUnsafeBufferPointer { a in
            vectorB.withUnsafeBufferPointer { b in
                let n = min(a.count, b.count)
                var sum: Double = 0
                for i in 0..<n {
                    sum += a[i] * b[i]
                }
                return sum
            }
        }
    }

    public static func sum<U>(_ vector: U) -> Float
    where U: AccelerateBuffer, U.Element == Float {
        vector.withUnsafeBufferPointer { buf in
            buf.reduce(0, +)
        }
    }

    public static func sum<U>(_ vector: U) -> Double
    where U: AccelerateBuffer, U.Element == Double {
        vector.withUnsafeBufferPointer { buf in
            buf.reduce(0, +)
        }
    }

    public static func maximum<U>(_ vector: U) -> Float
    where U: AccelerateBuffer, U.Element == Float {
        vector.withUnsafeBufferPointer { buf in
            buf.max() ?? -.infinity
        }
    }

    public static func maximum<U>(_ vector: U) -> Double
    where U: AccelerateBuffer, U.Element == Double {
        vector.withUnsafeBufferPointer { buf in
            buf.max() ?? -.infinity
        }
    }

    public static func minimum<U>(_ vector: U) -> Float
    where U: AccelerateBuffer, U.Element == Float {
        vector.withUnsafeBufferPointer { buf in
            buf.min() ?? .infinity
        }
    }

    public static func minimum<U>(_ vector: U) -> Double
    where U: AccelerateBuffer, U.Element == Double {
        vector.withUnsafeBufferPointer { buf in
            buf.min() ?? .infinity
        }
    }

    public static func absolute<U, V>(_ vector: U, result: inout V)
    where U: AccelerateBuffer, V: AccelerateMutableBuffer, U.Element == Float, V.Element == Float {
        vector.withUnsafeBufferPointer { src in
            result.withUnsafeMutableBufferPointer { dest in
                let n = min(src.count, dest.count)
                for i in 0..<n {
                    dest[i] = abs(src[i])
                }
            }
        }
    }

    public static func negative<U, V>(_ vector: U, result: inout V)
    where U: AccelerateBuffer, V: AccelerateMutableBuffer, U.Element == Float, V.Element == Float {
        vector.withUnsafeBufferPointer { src in
            result.withUnsafeMutableBufferPointer { dest in
                let n = min(src.count, dest.count)
                for i in 0..<n {
                    dest[i] = -src[i]
                }
            }
        }
    }

    public static func square<U, V>(_ vector: U, result: inout V)
    where U: AccelerateBuffer, V: AccelerateMutableBuffer, U.Element == Float, V.Element == Float {
        vector.withUnsafeBufferPointer { src in
            result.withUnsafeMutableBufferPointer { dest in
                let n = min(src.count, dest.count)
                for i in 0..<n {
                    dest[i] = src[i] * src[i]
                }
            }
        }
    }

    public static func fill<V>(_ vector: inout V, with value: Float)
    where V: AccelerateMutableBuffer, V.Element == Float {
        vector.withUnsafeMutableBufferPointer { dest in
            for i in dest.indices {
                dest[i] = value
            }
        }
    }

    public static func fill<V>(_ vector: inout V, with value: Double)
    where V: AccelerateMutableBuffer, V.Element == Double {
        vector.withUnsafeMutableBufferPointer { dest in
            for i in dest.indices {
                dest[i] = value
            }
        }
    }

    public static func clear<V>(_ vector: inout V)
    where V: AccelerateMutableBuffer, V.Element == Float {
        fill(&vector, with: 0)
    }
}
