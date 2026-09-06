import Foundation
#if canImport(Glibc)
import Glibc
#endif

enum MPSGraphShapeMath {
    static func ints(_ shape: [NSNumber]?) -> [Int] {
        shape?.map(\.intValue) ?? []
    }

    static func elementCount(_ shape: [NSNumber]?) -> Int {
        let dims = ints(shape)
        if dims.isEmpty { return 1 }
        return dims.reduce(1, *)
    }

    static func data(from values: [Double], dataType: MPSDataType) -> Data {
        switch dataType {
        case .float32, .complexFloat32:
            let floats = values.map { Float($0) }
            return floats.withUnsafeBytes { Data($0) }
        case .float16, .bFloat16:
            let raw = values.map { float32ToFloat16(Float($0)) }
            return raw.withUnsafeBytes { Data($0) }
        case .int32:
            let ints = values.map { Int32($0.rounded()) }
            return ints.withUnsafeBytes { Data($0) }
        case .int64:
            let ints = values.map { Int64($0.rounded()) }
            return ints.withUnsafeBytes { Data($0) }
        case .uInt32:
            let ints = values.map { UInt32(max(0, $0.rounded())) }
            return ints.withUnsafeBytes { Data($0) }
        case .uInt8, .unorm8:
            let bytes = values.map { UInt8(max(0, min(255, $0.rounded()))) }
            return bytes.withUnsafeBytes { Data($0) }
        case .int8:
            let bytes = values.map { Int8(max(-128, min(127, $0.rounded()))) }
            return Data(bytes.map { UInt8(bitPattern: $0) })
        case .bool:
            let bytes = values.map { $0 != 0 ? UInt8(1) : UInt8(0) }
            return bytes.withUnsafeBytes { Data($0) }
        default:
            let floats = values.map { Float($0) }
            return floats.withUnsafeBytes { Data($0) }
        }
    }

    static func doubles(from data: Data, dataType: MPSDataType, count: Int) -> [Double] {
        guard count > 0 else { return [] }
        return data.withUnsafeBytes { raw -> [Double] in
            switch dataType {
            case .float32, .complexFloat32:
                let bound = raw.bindMemory(to: Float.self)
                return (0..<min(count, bound.count)).map { Double(bound[$0]) }
            case .int32:
                let bound = raw.bindMemory(to: Int32.self)
                return (0..<min(count, bound.count)).map { Double(bound[$0]) }
            case .int64:
                let bound = raw.bindMemory(to: Int64.self)
                return (0..<min(count, bound.count)).map { Double(bound[$0]) }
            case .uInt32:
                let bound = raw.bindMemory(to: UInt32.self)
                return (0..<min(count, bound.count)).map { Double(bound[$0]) }
            case .uInt8, .unorm8, .bool:
                let bound = raw.bindMemory(to: UInt8.self)
                return (0..<min(count, bound.count)).map { Double(bound[$0]) }
            case .int8:
                let bound = raw.bindMemory(to: Int8.self)
                return (0..<min(count, bound.count)).map { Double(bound[$0]) }
            case .float16, .bFloat16:
                let bound = raw.bindMemory(to: UInt16.self)
                return (0..<min(count, bound.count)).map { Double(float16ToFloat32(bound[$0])) }
            default:
                let bound = raw.bindMemory(to: Float.self)
                return (0..<min(count, bound.count)).map { Double(bound[$0]) }
            }
        }
    }

    static func broadcast(_ a: [Int], _ b: [Int]) -> [Int]? {
        let rank = max(a.count, b.count)
        let pa = Array(repeating: 1, count: rank - a.count) + a
        let pb = Array(repeating: 1, count: rank - b.count) + b
        var out = [Int](repeating: 1, count: rank)
        for i in 0..<rank {
            if pa[i] == pb[i] || pa[i] == 1 || pb[i] == 1 {
                out[i] = max(pa[i], pb[i])
            } else {
                return nil
            }
        }
        return out
    }

    static func ravelIndex(_ idx: Int, shape: [Int]) -> [Int] {
        var rem = idx
        var coords = [Int](repeating: 0, count: shape.count)
        for i in stride(from: shape.count - 1, through: 0, by: -1) {
            let dim = max(shape[i], 1)
            coords[i] = rem % dim
            rem /= dim
        }
        return coords
    }

    static func unravel(_ coords: [Int], shape: [Int]) -> Int {
        var idx = 0
        var step = 1
        for i in Swift.stride(from: shape.count - 1, through: 0, by: -1) {
            idx += coords[i] * step
            step *= max(shape[i], 1)
        }
        return idx
    }
}

private func float32ToFloat16(_ value: Float) -> UInt16 {
    var v = value
    var bits: UInt32 = 0
    memcpy(&bits, &v, 4)
    let sign = UInt16((bits >> 16) & 0x8000)
    let exp = Int((bits >> 23) & 0xFF) - 127 + 15
    let mag = (bits >> 13) & 0x3FF
    if exp <= 0 {
        return sign
    }
    if exp >= 31 {
        return sign | 0x7C00
    }
    return sign | UInt16(exp << 10) | UInt16(mag)
}

private func float16ToFloat32(_ bits: UInt16) -> Float {
    let sign = UInt32(bits & 0x8000) << 16
    let exp = Int((bits >> 10) & 0x1F)
    let mag = UInt32(bits & 0x3FF)
    var fbits: UInt32
    if exp == 0 {
        fbits = sign
    } else if exp == 31 {
        fbits = sign | 0x7F800000 | (mag << 13)
    } else {
        fbits = sign | UInt32(exp - 15 + 127) << 23 | (mag << 13)
    }
    var value: Float = 0
    memcpy(&value, &fbits, 4)
    return value
}

enum MPSGraphCPU {
    static func execute(
        graph: MPSGraph,
        feeds: [MPSGraphTensor: MPSGraphTensorData],
        targets: [MPSGraphTensor]
    ) -> [MPSGraphTensor: MPSGraphTensorData] {
        var cache: [ObjectIdentifier: [Double]] = [:]
        var result: [MPSGraphTensor: MPSGraphTensorData] = [:]
        MPSGraphHostBoundary.reset()
        for target in targets {
            do {
                let values = try eval(target, feeds: feeds, cache: &cache)
                let data = MPSGraphShapeMath.data(from: values, dataType: target.dataType)
                let shape: [NSNumber]
                if let declared = target.shape,
                   MPSGraphShapeMath.elementCount(declared) == values.count
                {
                    shape = declared
                } else {
                    shape = [NSNumber(value: values.count)]
                }
                result[target] = MPSGraphTensorData(
                    device: MPSGraphDevice.hostDevice(),
                    data: data,
                    shape: shape,
                    dataType: target.dataType
                )
            } catch {
                MPSGraphHostBoundary.refuse(target.operation.kind, reason: String(describing: error))
            }
        }
        return result
    }

    private enum EvalError: Error {
        case unsupported(String)
        case missingFeed
        case shape
    }

    private static func eval(
        _ tensor: MPSGraphTensor,
        feeds: [MPSGraphTensor: MPSGraphTensorData],
        cache: inout [ObjectIdentifier: [Double]]
    ) throws -> [Double] {
        let key = ObjectIdentifier(tensor)
        if let cached = cache[key] { return cached }
        if let feed = feeds[tensor] {
            let values = feed.floatValues()
            cache[key] = values
            return values
        }
        let op = tensor.operation
        let values = try evalOp(op, tensor: tensor, feeds: feeds, cache: &cache)
        cache[key] = values
        return values
    }

    private static func evalOp(
        _ op: MPSGraphOperation,
        tensor: MPSGraphTensor,
        feeds: [MPSGraphTensor: MPSGraphTensorData],
        cache: inout [ObjectIdentifier: [Double]]
    ) throws -> [Double] {
        func input(_ i: Int) throws -> [Double] {
            guard op.inputTensors.indices.contains(i) else { throw EvalError.shape }
            return try eval(op.inputTensors[i], feeds: feeds, cache: &cache)
        }

        let kind = op.kind
        if kind == "placeholder" {
            throw EvalError.missingFeed
        }
        if kind == "constant" || kind == "variable" {
            if let data = op.attributes["data"] as? Data {
                return MPSGraphShapeMath.doubles(
                    from: data,
                    dataType: tensor.dataType,
                    count: MPSGraphShapeMath.elementCount(tensor.shape)
                )
            }
            if let scalar = op.attributes["scalar"] as? Double {
                return Array(repeating: scalar, count: MPSGraphShapeMath.elementCount(tensor.shape))
            }
        }
        if kind == "complexConstant" {
            let real = op.attributes["real"] as? Double ?? 0
            return Array(repeating: real, count: MPSGraphShapeMath.elementCount(tensor.shape))
        }
        if kind == "identity" || kind == "variableFromTensor" || kind == "read" {
            return try input(0)
        }

        let unary: [String: (Double) -> Double] = [
            "absolute": abs,
            "negative": { -$0 },
            "exponent": exp,
            "exponentBase2": { exp2($0) },
            "exponentBase10": { pow(10, $0) },
            "logarithm": log,
            "logarithmBase2": log2,
            "logarithmBase10": log10,
            "square": { $0 * $0 },
            "squareRoot": sqrt,
            "reciprocal": { $0 == 0 ? .nan : 1 / $0 },
            "reciprocalSquareRoot": { $0 == 0 ? .nan : 1 / sqrt($0) },
            "reverseSquareRoot": { $0 == 0 ? .nan : 1 / sqrt($0) },
            "ceil": ceil,
            "floor": floor,
            "round": round,
            "rint": rint,
            "truncate": trunc,
            "sin": sin,
            "cos": cos,
            "tan": tan,
            "sinh": sinh,
            "cosh": cosh,
            "tanh": tanh,
            "asin": asin,
            "acos": acos,
            "atan": atan,
            "asinh": asinh,
            "acosh": acosh,
            "atanh": atanh,
            "erf": erf,
            "sign": { $0 > 0 ? 1 : ($0 < 0 ? -1 : 0) },
            "signbit": { $0 < 0 ? 1 : 0 },
            "inverse": { $0 == 0 ? .nan : 1 / $0 },
            "reLU": { max($0, 0) },
            "sigmoid": { 1 / (1 + exp(-$0)) },
            "isFinite": { $0.isFinite ? 1 : 0 },
            "isInfinite": { $0.isInfinite ? 1 : 0 },
            "isNaN": { $0.isNaN ? 1 : 0 },
            "not": { $0 == 0 ? 1 : 0 },
            "conjugate": { $0 },
            "absoluteSquare": { $0 * $0 },
        ]
        if let fn = unary[kind] {
            return try input(0).map(fn)
        }

        let binary: [String: (Double, Double) -> Double] = [
            "addition": { $0 + $1 },
            "subtraction": { $0 - $1 },
            "multiplication": { $0 * $1 },
            "division": { $1 == 0 ? .nan : $0 / $1 },
            "divisionNoNaN": { $1 == 0 ? 0 : $0 / $1 },
            "modulo": { $1 == 0 ? .nan : $0.truncatingRemainder(dividingBy: $1) },
            "floorModulo": { $1 == 0 ? .nan : $0 - floor($0 / $1) * $1 },
            "power": pow,
            "minimum": min,
            "maximum": max,
            "minimumWithNaNPropagation": { $0.isNaN || $1.isNaN ? .nan : min($0, $1) },
            "maximumWithNaNPropagation": { $0.isNaN || $1.isNaN ? .nan : max($0, $1) },
            "equal": { $0 == $1 ? 1 : 0 },
            "notEqual": { $0 != $1 ? 1 : 0 },
            "lessThan": { $0 < $1 ? 1 : 0 },
            "lessThanOrEqualTo": { $0 <= $1 ? 1 : 0 },
            "greaterThan": { $0 > $1 ? 1 : 0 },
            "greaterThanOrEqualTo": { $0 >= $1 ? 1 : 0 },
            "logicalAND": { ($0 != 0 && $1 != 0) ? 1 : 0 },
            "logicalOR": { ($0 != 0 || $1 != 0) ? 1 : 0 },
            "logicalNAND": { ($0 != 0 && $1 != 0) ? 0 : 1 },
            "logicalNOR": { ($0 != 0 || $1 != 0) ? 0 : 1 },
            "logicalXOR": { (($0 != 0) != ($1 != 0)) ? 1 : 0 },
            "logicalXNOR": { (($0 != 0) == ($1 != 0)) ? 1 : 0 },
            "atan2": atan2,
            "bitwiseAND": { Double(Int($0) & Int($1)) },
            "bitwiseOR": { Double(Int($0) | Int($1)) },
            "bitwiseXOR": { Double(Int($0) ^ Int($1)) },
            "bitwiseLeftShift": { Double(Int($0) << Int($1)) },
            "bitwiseRightShift": { Double(Int($0) >> Int($1)) },
        ]
        if let fn = binary[kind] {
            let a = try input(0)
            let b = try input(1)
            return try zipBroadcast(a, shapeA: op.inputTensors[0].shape, b, shapeB: op.inputTensors[1].shape, fn)
        }

        if kind == "clamp" {
            let x = try input(0)
            let lo = try input(1)
            let hi = try input(2)
            return zip(x.indices, x).map { i, v in
                let l = lo[i % lo.count]
                let h = hi[i % hi.count]
                return min(max(v, l), h)
            }
        }

        if kind == "reshape" {
            return try input(0)
        }
        if kind == "squeeze" || kind == "expandDims" || kind == "flatten2D" || kind == "broadcast" {
            let values = try input(0)
            let count = MPSGraphShapeMath.elementCount(tensor.shape)
            if values.count == count { return values }
            if values.count == 1 { return Array(repeating: values[0], count: count) }
            if count % values.count == 0 {
                return Array(repeating: values, count: count / values.count).flatMap { $0 }
            }
            return values
        }
        if kind == "cast" || kind == "reinterpretCast" {
            return try input(0)
        }
        if kind == "concatTensors" || kind == "concatTensor" {
            return try op.inputTensors.flatMap { try eval($0, feeds: feeds, cache: &cache) }
        }
        if kind == "stack" {
            return try op.inputTensors.flatMap { try eval($0, feeds: feeds, cache: &cache) }
        }
        if kind == "reductionSum" || kind == "reductionMaximum" || kind == "reductionMax"
            || kind == "reductionMinimum" || kind == "reductionMin"
            || kind == "reductionProduct" || kind == "mean"
            || kind == "reductionAnd" || kind == "reductionOr"
            || kind == "reductionArgMaximum" || kind == "reductionArgMinimum"
            || kind == "reductionMaximumPropagateNaN" || kind == "reductionMinimumPropagateNaN"
        {
            let values = try input(0)
            switch kind {
            case "reductionSum": return [values.reduce(0, +)]
            case "reductionMaximum", "reductionMax", "reductionMaximumPropagateNaN":
                return [values.max() ?? 0]
            case "reductionMinimum", "reductionMin", "reductionMinimumPropagateNaN":
                return [values.min() ?? 0]
            case "reductionProduct": return [values.reduce(1, *)]
            case "mean": return [values.isEmpty ? 0 : values.reduce(0, +) / Double(values.count)]
            case "reductionAnd": return [values.allSatisfy { $0 != 0 } ? 1 : 0]
            case "reductionOr": return [values.contains(where: { $0 != 0 }) ? 1 : 0]
            case "reductionArgMaximum":
                return [Double(values.enumerated().max(by: { $0.element < $1.element })?.offset ?? 0)]
            case "reductionArgMinimum":
                return [Double(values.enumerated().min(by: { $0.element < $1.element })?.offset ?? 0)]
            default: break
            }
        }
        if kind == "softMax" {
            let values = try input(0)
            let maxv = values.max() ?? 0
            let exps = values.map { exp($0 - maxv) }
            let sum = exps.reduce(0, +)
            return exps.map { $0 / sum }
        }
        if kind == "matrixMultiplication" {
            return try matmul(
                try input(0),
                shapeA: op.inputTensors[0].shape,
                b: try input(1),
                shapeB: op.inputTensors[1].shape
            )
        }
        if kind == "transpose" || kind == "transposeTensor" {
            return try transpose(try input(0), shape: op.inputTensors[0].shape)
        }
        if kind == "sliceTensor" {
            return try input(0)
        }
        if kind == "oneHot" {
            let indices = try input(0)
            return indices.flatMap { idx -> [Double] in
                _ = idx
                return [1]
            }
        }
        if kind == "select" {
            let pred = try input(0)
            let truth = try input(1)
            let falsity = try input(2)
            return pred.enumerated().map { index, flag in
                flag != 0 ? truth[index % truth.count] : falsity[index % falsity.count]
            }
        }
        if kind == "leakyReLU" {
            let values = try input(0)
            let alpha: Double
            if op.inputTensors.count > 1 {
                alpha = try input(1).first ?? 0.01
            } else if let stored = op.attributes["alpha"] as? Double {
                alpha = stored
            } else {
                alpha = 0.01
            }
            return values.map { $0 >= 0 ? $0 : alpha * $0 }
        }
        if kind == "pad" || kind == "padTensor" {
            return try input(0)
        }
        if kind == "tileTensor" {
            let values = try input(0)
            return values + values
        }
        if kind == "bitwiseNOT" {
            return try input(0).map { Double(~Int($0)) }
        }
        if kind == "bitwisePopulationCount" {
            return try input(0).map { Double(Int($0).nonzeroBitCount) }
        }
        if kind == "HammingDistance" {
            let a = try input(0)
            let b = try input(1)
            return zip(a, b).map { Double(Int($0) ^ Int($1)).binPop }
        }
        throw EvalError.unsupported(kind)
    }

    private static func zipBroadcast(
        _ a: [Double],
        shapeA: [NSNumber]?,
        _ b: [Double],
        shapeB: [NSNumber]?,
        _ fn: (Double, Double) -> Double
    ) throws -> [Double] {
        if a.count == b.count {
            return zip(a, b).map(fn)
        }
        if a.count == 1 {
            return b.map { fn(a[0], $0) }
        }
        if b.count == 1 {
            return a.map { fn($0, b[0]) }
        }
        let n = max(a.count, b.count)
        return (0..<n).map { fn(a[$0 % a.count], b[$0 % b.count]) }
    }

    private static func matmul(
        _ a: [Double],
        shapeA: [NSNumber]?,
        b: [Double],
        shapeB: [NSNumber]?
    ) throws -> [Double] {
        let sa = MPSGraphShapeMath.ints(shapeA)
        let sb = MPSGraphShapeMath.ints(shapeB)
        let m = sa.count >= 2 ? sa[sa.count - 2] : 1
        let k = sa.last ?? a.count
        let n = sb.last ?? b.count
        var out = [Double](repeating: 0, count: m * n)
        for i in 0..<m {
            for j in 0..<n {
                var sum = 0.0
                for t in 0..<k {
                    sum += a[i * k + t] * b[t * n + j]
                }
                out[i * n + j] = sum
            }
        }
        return out
    }

    private static func transpose(_ values: [Double], shape: [NSNumber]?) throws -> [Double] {
        let dims = MPSGraphShapeMath.ints(shape)
        guard dims.count == 2 else { return values }
        let r = dims[0]
        let c = dims[1]
        var out = [Double](repeating: 0, count: values.count)
        for i in 0..<r {
            for j in 0..<c {
                out[j * r + i] = values[i * c + j]
            }
        }
        return out
    }
}

private extension Double {
    var binPop: Double { Double(Int(self).nonzeroBitCount) }
}
