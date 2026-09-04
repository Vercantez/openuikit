import Foundation

extension vForce {
    public static func exp<U, V>(_ vector: U, result: inout V)
    where U: AccelerateBuffer, V: AccelerateMutableBuffer, U.Element == Float, V.Element == Float {
        map(vector, &result, Foundation.exp)
    }

    public static func exp<U, V>(_ vector: U, result: inout V)
    where U: AccelerateBuffer, V: AccelerateMutableBuffer, U.Element == Double, V.Element == Double {
        map(vector, &result, Foundation.exp)
    }

    public static func exp<U>(_ vector: U) -> [Float]
    where U: AccelerateBuffer, U.Element == Float {
        var result = [Float](repeating: 0, count: vector.count)
        exp(vector, result: &result)
        return result
    }

    public static func exp<U>(_ vector: U) -> [Double]
    where U: AccelerateBuffer, U.Element == Double {
        var result = [Double](repeating: 0, count: vector.count)
        exp(vector, result: &result)
        return result
    }

    public static func log<U, V>(_ vector: U, result: inout V)
    where U: AccelerateBuffer, V: AccelerateMutableBuffer, U.Element == Float, V.Element == Float {
        map(vector, &result, Foundation.log)
    }

    public static func log<U, V>(_ vector: U, result: inout V)
    where U: AccelerateBuffer, V: AccelerateMutableBuffer, U.Element == Double, V.Element == Double {
        map(vector, &result, Foundation.log)
    }

    public static func log<U>(_ vector: U) -> [Float]
    where U: AccelerateBuffer, U.Element == Float {
        var result = [Float](repeating: 0, count: vector.count)
        log(vector, result: &result)
        return result
    }

    public static func sin<U, V>(_ vector: U, result: inout V)
    where U: AccelerateBuffer, V: AccelerateMutableBuffer, U.Element == Float, V.Element == Float {
        map(vector, &result, Foundation.sin)
    }

    public static func sin<U, V>(_ vector: U, result: inout V)
    where U: AccelerateBuffer, V: AccelerateMutableBuffer, U.Element == Double, V.Element == Double {
        map(vector, &result, Foundation.sin)
    }

    public static func sin<U>(_ vector: U) -> [Float]
    where U: AccelerateBuffer, U.Element == Float {
        var result = [Float](repeating: 0, count: vector.count)
        sin(vector, result: &result)
        return result
    }

    public static func cos<U, V>(_ vector: U, result: inout V)
    where U: AccelerateBuffer, V: AccelerateMutableBuffer, U.Element == Float, V.Element == Float {
        map(vector, &result, Foundation.cos)
    }

    public static func cos<U, V>(_ vector: U, result: inout V)
    where U: AccelerateBuffer, V: AccelerateMutableBuffer, U.Element == Double, V.Element == Double {
        map(vector, &result, Foundation.cos)
    }

    public static func cos<U>(_ vector: U) -> [Float]
    where U: AccelerateBuffer, U.Element == Float {
        var result = [Float](repeating: 0, count: vector.count)
        cos(vector, result: &result)
        return result
    }

    public static func sqrt<U, V>(_ vector: U, result: inout V)
    where U: AccelerateBuffer, V: AccelerateMutableBuffer, U.Element == Float, V.Element == Float {
        map(vector, &result, Foundation.sqrt)
    }

    public static func sqrt<U, V>(_ vector: U, result: inout V)
    where U: AccelerateBuffer, V: AccelerateMutableBuffer, U.Element == Double, V.Element == Double {
        map(vector, &result, Foundation.sqrt)
    }

    public static func sqrt<U>(_ vector: U) -> [Float]
    where U: AccelerateBuffer, U.Element == Float {
        var result = [Float](repeating: 0, count: vector.count)
        sqrt(vector, result: &result)
        return result
    }

    public static func reciprocal<U, V>(_ vector: U, result: inout V)
    where U: AccelerateBuffer, V: AccelerateMutableBuffer, U.Element == Float, V.Element == Float {
        map(vector, &result) { 1 / $0 }
    }

    public static func abs<U, V>(_ vector: U, result: inout V)
    where U: AccelerateBuffer, V: AccelerateMutableBuffer, U.Element == Float, V.Element == Float {
        map(vector, &result) { $0 < 0 ? -$0 : $0 }
    }

    public static func floor<U, V>(_ vector: U, result: inout V)
    where U: AccelerateBuffer, V: AccelerateMutableBuffer, U.Element == Float, V.Element == Float {
        map(vector, &result, Foundation.floor)
    }

    public static func ceil<U, V>(_ vector: U, result: inout V)
    where U: AccelerateBuffer, V: AccelerateMutableBuffer, U.Element == Float, V.Element == Float {
        map(vector, &result, Foundation.ceil)
    }

    private static func map<U, V, T>(
        _ vector: U,
        _ result: inout V,
        _ transform: (T) -> T
    ) where U: AccelerateBuffer, V: AccelerateMutableBuffer, U.Element == T, V.Element == T {
        vector.withUnsafeBufferPointer { src in
            result.withUnsafeMutableBufferPointer { dest in
                let n = min(src.count, dest.count)
                for i in 0..<n {
                    dest[i] = transform(src[i])
                }
            }
        }
    }
}
