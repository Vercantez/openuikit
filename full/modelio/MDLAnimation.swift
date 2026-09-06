import Foundation

open class MDLAnimatedValue: NSObject, NSCopying {
    public var interpolation: MDLAnimatedValueInterpolation = .linear
    var sampleTimes: [TimeInterval] = []

    public var keyTimes: [NSNumber] { sampleTimes.map { NSNumber(value: $0) } }
    public var times: [TimeInterval] { sampleTimes }
    public var timeSampleCount: UInt { UInt(sampleTimes.count) }
    public var minimumTime: TimeInterval { sampleTimes.first ?? 0 }
    public var maximumTime: TimeInterval { sampleTimes.last ?? 0 }
    public var precision: MDLDataPrecision { .float }

    public func isAnimated() -> Bool { sampleTimes.count > 1 }

    public func clear() { sampleTimes.removeAll() }

    public func copy(with zone: NSZone? = nil) -> Any {
        let clone = type(of: self).init()
        clone.interpolation = interpolation
        clone.sampleTimes = sampleTimes
        return clone
    }

    func insertTime(_ time: TimeInterval) -> Int {
        if let index = sampleTimes.firstIndex(where: { $0 >= time }) {
            if sampleTimes[index] == time { return index }
            sampleTimes.insert(time, at: index)
            return index
        }
        sampleTimes.append(time)
        return sampleTimes.count - 1
    }

    func interpolationWeight(at time: TimeInterval) -> (Int, Int, Float) {
        guard !sampleTimes.isEmpty else { return (0, 0, 0) }
        if time <= sampleTimes.first! { return (0, 0, 0) }
        if time >= sampleTimes.last! { return (sampleTimes.count - 1, sampleTimes.count - 1, 0) }
        for i in 0..<(sampleTimes.count - 1) {
            if time >= sampleTimes[i] && time <= sampleTimes[i + 1] {
                if interpolation == .constant {
                    return (i, i, 0)
                }
                let span = sampleTimes[i + 1] - sampleTimes[i]
                let t = span <= 0 ? 0 : Float((time - sampleTimes[i]) / span)
                return (i, i + 1, t)
            }
        }
        return (sampleTimes.count - 1, sampleTimes.count - 1, 0)
    }

    public required override init() {
        super.init()
    }
}

public class MDLAnimatedScalar: MDLAnimatedValue {
    private var floats: [Float] = []

    public func setFloat(_ value: Float, atTime time: TimeInterval) {
        let index = insertTime(time)
        if index < floats.count {
            floats[index] = value
        } else {
            floats.append(value)
        }
    }

    public func setDouble(_ value: Double, atTime time: TimeInterval) {
        setFloat(Float(value), atTime: time)
    }

    public func floatValue(atTime time: TimeInterval) -> Float {
        let (a, b, t) = interpolationWeight(at: time)
        guard !floats.isEmpty else { return 0 }
        let va = a < floats.count ? floats[a] : floats.last!
        let vb = b < floats.count ? floats[b] : va
        return va + (vb - va) * t
    }

    public func doubleValue(atTime time: TimeInterval) -> Double {
        Double(floatValue(atTime: time))
    }

    public func reset(floatArray array: [Float], atTimes times: [TimeInterval]) {
        sampleTimes = times
        floats = array
    }

    public func reset(doubleArray array: [Double], atTimes times: [TimeInterval]) {
        reset(floatArray: array.map(Float.init), atTimes: times)
    }

    public var floatArray: [Float] { floats }
    public var doubleArray: [Double] { floats.map(Double.init) }

    public override func clear() {
        super.clear()
        floats.removeAll()
    }
}

public class MDLAnimatedVector2: MDLAnimatedValue {
    private var values: [SIMD2<Float>] = []

    public func setFloat2(_ value: SIMD2<Float>, atTime time: TimeInterval) {
        let index = insertTime(time)
        if index < values.count { values[index] = value } else { values.append(value) }
    }

    public func setDouble2(_ value: SIMD2<Double>, atTime time: TimeInterval) {
        setFloat2(SIMD2(Float(value.x), Float(value.y)), atTime: time)
    }

    public func float2Value(atTime time: TimeInterval) -> SIMD2<Float> {
        let (a, b, t) = interpolationWeight(at: time)
        guard !values.isEmpty else { return SIMD2() }
        let va = a < values.count ? values[a] : values.last!
        let vb = b < values.count ? values[b] : va
        return va + (vb - va) * t
    }

    public func double2Value(atTime time: TimeInterval) -> SIMD2<Double> {
        let v = float2Value(atTime: time)
        return SIMD2(Double(v.x), Double(v.y))
    }

    public func reset(float2Array array: [SIMD2<Float>], atTimes times: [TimeInterval]) {
        sampleTimes = times
        values = array
    }

    public func reset(double2Array array: [SIMD2<Double>], atTimes times: [TimeInterval]) {
        reset(float2Array: array.map { SIMD2(Float($0.x), Float($0.y)) }, atTimes: times)
    }

    public var float2Array: [SIMD2<Float>] { values }
    public var double2Array: [SIMD2<Double>] { values.map { SIMD2(Double($0.x), Double($0.y)) } }
}

public class MDLAnimatedVector3: MDLAnimatedValue {
    private var values: [SIMD3<Float>] = []

    public func setFloat3(_ value: SIMD3<Float>, atTime time: TimeInterval) {
        let index = insertTime(time)
        if index < values.count { values[index] = value } else { values.append(value) }
    }

    public func setDouble3(_ value: SIMD3<Double>, atTime time: TimeInterval) {
        setFloat3(SIMD3(Float(value.x), Float(value.y), Float(value.z)), atTime: time)
    }

    public func float3Value(atTime time: TimeInterval) -> SIMD3<Float> {
        let (a, b, t) = interpolationWeight(at: time)
        guard !values.isEmpty else { return SIMD3() }
        let va = a < values.count ? values[a] : values.last!
        let vb = b < values.count ? values[b] : va
        return va + (vb - va) * t
    }

    public func double3Value(atTime time: TimeInterval) -> SIMD3<Double> {
        let v = float3Value(atTime: time)
        return SIMD3(Double(v.x), Double(v.y), Double(v.z))
    }

    public func reset(float3Array array: [SIMD3<Float>], atTimes times: [TimeInterval]) {
        sampleTimes = times
        values = array
    }

    public func reset(double3Array array: [SIMD3<Double>], atTimes times: [TimeInterval]) {
        reset(float3Array: array.map { SIMD3(Float($0.x), Float($0.y), Float($0.z)) }, atTimes: times)
    }

    public var float3Array: [SIMD3<Float>] { values }
    public var double3Array: [SIMD3<Double>] { values.map { SIMD3(Double($0.x), Double($0.y), Double($0.z)) } }
}

public class MDLAnimatedVector4: MDLAnimatedValue {
    private var values: [SIMD4<Float>] = []

    public func setFloat4(_ value: SIMD4<Float>, atTime time: TimeInterval) {
        let index = insertTime(time)
        if index < values.count { values[index] = value } else { values.append(value) }
    }

    public func setDouble4(_ value: SIMD4<Double>, atTime time: TimeInterval) {
        setFloat4(SIMD4(Float(value.x), Float(value.y), Float(value.z), Float(value.w)), atTime: time)
    }

    public func float4Value(atTime time: TimeInterval) -> SIMD4<Float> {
        let (a, b, t) = interpolationWeight(at: time)
        guard !values.isEmpty else { return SIMD4() }
        let va = a < values.count ? values[a] : values.last!
        let vb = b < values.count ? values[b] : va
        return va + (vb - va) * t
    }

    public func double4Value(atTime time: TimeInterval) -> SIMD4<Double> {
        let v = float4Value(atTime: time)
        return SIMD4(Double(v.x), Double(v.y), Double(v.z), Double(v.w))
    }

    public func reset(float4Array array: [SIMD4<Float>], atTimes times: [TimeInterval]) {
        sampleTimes = times
        values = array
    }

    public func reset(double4Array array: [SIMD4<Double>], atTimes times: [TimeInterval]) {
        reset(float4Array: array.map { SIMD4(Float($0.x), Float($0.y), Float($0.z), Float($0.w)) }, atTimes: times)
    }

    public var float4Array: [SIMD4<Float>] { values }
    public var double4Array: [SIMD4<Double>] { values.map { SIMD4(Double($0.x), Double($0.y), Double($0.z), Double($0.w)) } }
}

public class MDLAnimatedQuaternion: MDLAnimatedValue {
    private var values: [simd_quatf] = []

    public func setFloatQuaternion(_ value: simd_quatf, atTime time: TimeInterval) {
        let index = insertTime(time)
        if index < values.count { values[index] = value } else { values.append(value) }
    }

    public func setDoubleQuaternion(_ value: simd_quatd, atTime time: TimeInterval) {
        setFloatQuaternion(
            simd_quatf(ix: Float(value.vector.x), iy: Float(value.vector.y), iz: Float(value.vector.z), r: Float(value.vector.w)),
            atTime: time
        )
    }

    public func floatQuaternionValue(atTime time: TimeInterval) -> simd_quatf {
        let (a, b, t) = interpolationWeight(at: time)
        guard !values.isEmpty else { return .identity }
        let va = a < values.count ? values[a] : values.last!
        let vb = b < values.count ? values[b] : va
        return t == 0 ? va : mdlSlerp(va, vb, t)
    }

    public func doubleQuaternionValue(atTime time: TimeInterval) -> simd_quatd {
        let q = floatQuaternionValue(atTime: time)
        return simd_quatd(ix: Double(q.vector.x), iy: Double(q.vector.y), iz: Double(q.vector.z), r: Double(q.vector.w))
    }

    public func reset(floatQuaternionArray array: [simd_quatf], atTimes times: [TimeInterval]) {
        sampleTimes = times
        values = array
    }

    public func reset(doubleQuaternionArray array: [simd_quatd], atTimes times: [TimeInterval]) {
        reset(
            floatQuaternionArray: array.map {
                simd_quatf(ix: Float($0.vector.x), iy: Float($0.vector.y), iz: Float($0.vector.z), r: Float($0.vector.w))
            },
            atTimes: times
        )
    }

    public var floatQuaternionArray: [simd_quatf] { values }
    public var doubleQuaternionArray: [simd_quatd] {
        values.map { simd_quatd(ix: Double($0.vector.x), iy: Double($0.vector.y), iz: Double($0.vector.z), r: Double($0.vector.w)) }
    }
}

public class MDLAnimatedMatrix4x4: MDLAnimatedValue {
    private var values: [matrix_float4x4] = []

    public func setFloat4x4(_ value: matrix_float4x4, atTime time: TimeInterval) {
        let index = insertTime(time)
        if index < values.count { values[index] = value } else { values.append(value) }
    }

    public func setDouble4x4(_ value: matrix_double4x4, atTime time: TimeInterval) {
        setFloat4x4(mdlDoubleToFloat(value), atTime: time)
    }

    public func float4x4Value(atTime time: TimeInterval) -> matrix_float4x4 {
        let (a, _, _) = interpolationWeight(at: time)
        guard !values.isEmpty else { return .identity }
        return a < values.count ? values[a] : values.last!
    }

    public func double4x4Value(atTime time: TimeInterval) -> matrix_double4x4 {
        mdlFloatToDouble(float4x4Value(atTime: time))
    }

    public func reset(float4x4Array array: [float4x4], atTimes times: [TimeInterval]) {
        sampleTimes = times
        values = array
    }

    public func reset(double4Array array: [double4x4], atTimes times: [TimeInterval]) {
        reset(float4x4Array: array.map(mdlDoubleToFloat), atTimes: times)
    }

    public var float4x4Array: [float4x4] { values }
    public var double4x4Array: [double4x4] { values.map(mdlFloatToDouble) }
}

public class MDLAnimatedScalarArray: MDLAnimatedValue {
    public private(set) var elementCount: UInt
    private var frames: [TimeInterval: [Float]] = [:]

    public init(elementCount arrayElementCount: UInt) {
        self.elementCount = arrayElementCount
        super.init()
    }

    public required init() {
        self.elementCount = 0
        super.init()
    }

    public func set(floatArray array: [Float], atTime time: TimeInterval) {
        _ = insertTime(time)
        frames[time] = array
        elementCount = UInt(array.count)
    }

    public func set(doubleArray array: [Double], atTime time: TimeInterval) {
        set(floatArray: array.map(Float.init), atTime: time)
    }

    public func floatArray(atTime time: TimeInterval) -> [Float] {
        if let exact = frames[time] { return exact }
        let (a, b, t) = interpolationWeight(at: time)
        let ta = a < sampleTimes.count ? sampleTimes[a] : time
        let tb = b < sampleTimes.count ? sampleTimes[b] : ta
        let va = frames[ta] ?? Array(repeating: 0, count: Int(elementCount))
        let vb = frames[tb] ?? va
        return zip(va, vb).map { $0 + ($1 - $0) * t }
    }

    public func doubleArray(atTime time: TimeInterval) -> [Double] {
        floatArray(atTime: time).map(Double.init)
    }

    public func reset(floatArray array: [Float], atTimes times: [TimeInterval]) {
        sampleTimes = times
        frames = Dictionary(uniqueKeysWithValues: times.map { ($0, array) })
        elementCount = UInt(array.count)
    }

    public func reset(doubleArray array: [Double], atTimes times: [TimeInterval]) {
        reset(floatArray: array.map(Float.init), atTimes: times)
    }

    public var floatArray: [Float] { floatArray(atTime: maximumTime) }
    public var doubleArray: [Double] { floatArray.map(Double.init) }
}

public class MDLAnimatedVector3Array: MDLAnimatedValue {
    public private(set) var elementCount: UInt
    private var frames: [TimeInterval: [SIMD3<Float>]] = [:]

    public init(elementCount arrayElementCount: UInt) {
        self.elementCount = arrayElementCount
        super.init()
    }

    public required init() {
        self.elementCount = 0
        super.init()
    }

    public func set(float3Array array: [SIMD3<Float>], atTime time: TimeInterval) {
        _ = insertTime(time)
        frames[time] = array
        elementCount = UInt(array.count)
    }

    public func set(double3Array array: [SIMD3<Double>], atTime time: TimeInterval) {
        set(float3Array: array.map { SIMD3(Float($0.x), Float($0.y), Float($0.z)) }, atTime: time)
    }

    public func float3Array(atTime time: TimeInterval) -> [SIMD3<Float>] {
        if let exact = frames[time] { return exact }
        let (a, _, _) = interpolationWeight(at: time)
        let ta = a < sampleTimes.count ? sampleTimes[a] : time
        return frames[ta] ?? []
    }

    public func double3Array(atTime time: TimeInterval) -> [SIMD3<Double>] {
        float3Array(atTime: time).map { SIMD3(Double($0.x), Double($0.y), Double($0.z)) }
    }

    public func reset(float3Array array: [SIMD3<Float>], atTimes times: [TimeInterval]) {
        sampleTimes = times
        frames = Dictionary(uniqueKeysWithValues: times.map { ($0, array) })
        elementCount = UInt(array.count)
    }

    public func reset(double3Array array: [SIMD3<Double>], atTimes times: [TimeInterval]) {
        reset(float3Array: array.map { SIMD3(Float($0.x), Float($0.y), Float($0.z)) }, atTimes: times)
    }

    public var float3Array: [SIMD3<Float>] { float3Array(atTime: maximumTime) }
    public var double3Array: [SIMD3<Double>] { double3Array(atTime: maximumTime) }
}

public class MDLAnimatedQuaternionArray: MDLAnimatedValue {
    public private(set) var elementCount: UInt
    private var frames: [TimeInterval: [simd_quatf]] = [:]

    public init(elementCount arrayElementCount: UInt) {
        self.elementCount = arrayElementCount
        super.init()
    }

    public required init() {
        self.elementCount = 0
        super.init()
    }

    public func set(floatQuaternionArray array: [simd_quatf], atTime time: TimeInterval) {
        _ = insertTime(time)
        frames[time] = array
        elementCount = UInt(array.count)
    }

    public func set(doubleQuaternionArray array: [simd_quatd], atTime time: TimeInterval) {
        set(
            floatQuaternionArray: array.map {
                simd_quatf(ix: Float($0.vector.x), iy: Float($0.vector.y), iz: Float($0.vector.z), r: Float($0.vector.w))
            },
            atTime: time
        )
    }

    public func floatQuaternionArray(atTime time: TimeInterval) -> [simd_quatf] {
        if let exact = frames[time] { return exact }
        let (a, _, _) = interpolationWeight(at: time)
        let ta = a < sampleTimes.count ? sampleTimes[a] : time
        return frames[ta] ?? []
    }

    public func doubleQuaternionArray(atTime time: TimeInterval) -> [simd_quatd] {
        floatQuaternionArray(atTime: time).map {
            simd_quatd(ix: Double($0.vector.x), iy: Double($0.vector.y), iz: Double($0.vector.z), r: Double($0.vector.w))
        }
    }

    public func reset(floatQuaternionArray array: [simd_quatf], atTimes times: [TimeInterval]) {
        sampleTimes = times
        frames = Dictionary(uniqueKeysWithValues: times.map { ($0, array) })
        elementCount = UInt(array.count)
    }

    public func reset(doubleQuaternionArray array: [simd_quatd], atTimes times: [TimeInterval]) {
        reset(
            floatQuaternionArray: array.map {
                simd_quatf(ix: Float($0.vector.x), iy: Float($0.vector.y), iz: Float($0.vector.z), r: Float($0.vector.w))
            },
            atTimes: times
        )
    }

    public var floatQuaternionArray: [simd_quatf] { floatQuaternionArray(atTime: maximumTime) }
    public var doubleQuaternionArray: [simd_quatd] { doubleQuaternionArray(atTime: maximumTime) }
}

public class MDLMatrix4x4Array: NSObject, NSCopying {
    public private(set) var elementCount: UInt
    public private(set) var precision: MDLDataPrecision = .float
    public var float4x4Array: [float4x4]
    public var double4x4Array: [double4x4] {
        get { float4x4Array.map(mdlFloatToDouble) }
        set {
            float4x4Array = newValue.map(mdlDoubleToFloat)
            precision = .double
            elementCount = UInt(newValue.count)
        }
    }

    public init(elementCount arrayElementCount: UInt) {
        self.elementCount = arrayElementCount
        self.float4x4Array = Array(repeating: .identity, count: Int(arrayElementCount))
        super.init()
    }

    public func clear() {
        float4x4Array = Array(repeating: .identity, count: Int(elementCount))
        precision = .float
    }

    public func copy(with zone: NSZone? = nil) -> Any {
        let clone = MDLMatrix4x4Array(elementCount: elementCount)
        clone.float4x4Array = float4x4Array
        clone.precision = precision
        return clone
    }
}

public class MDLSkeleton: MDLObject, NSCopying {
    public private(set) var jointPaths: [String]
    public let jointBindTransforms: MDLMatrix4x4Array
    public let jointRestTransforms: MDLMatrix4x4Array

    public init(name: String, jointPaths: [String]) {
        self.jointPaths = jointPaths
        self.jointBindTransforms = MDLMatrix4x4Array(elementCount: UInt(jointPaths.count))
        self.jointRestTransforms = MDLMatrix4x4Array(elementCount: UInt(jointPaths.count))
        super.init()
        self.name = name
    }

    public func copy(with zone: NSZone? = nil) -> Any {
        let clone = MDLSkeleton(name: name, jointPaths: jointPaths)
        clone.jointBindTransforms.float4x4Array = jointBindTransforms.float4x4Array
        clone.jointRestTransforms.float4x4Array = jointRestTransforms.float4x4Array
        return clone
    }
}

public class MDLPackedJointAnimation: MDLObject, NSCopying, MDLJointAnimation {
    public private(set) var jointPaths: [String]
    public let translations: MDLAnimatedVector3Array
    public let rotations: MDLAnimatedQuaternionArray
    public let scales: MDLAnimatedVector3Array

    public init(name: String, jointPaths: [String]) {
        self.jointPaths = jointPaths
        self.translations = MDLAnimatedVector3Array(elementCount: UInt(jointPaths.count))
        self.rotations = MDLAnimatedQuaternionArray(elementCount: UInt(jointPaths.count))
        self.scales = MDLAnimatedVector3Array(elementCount: UInt(jointPaths.count))
        super.init()
        self.name = name
    }

    public func copy(with zone: NSZone? = nil) -> Any {
        MDLPackedJointAnimation(name: name, jointPaths: jointPaths)
    }
}

public class MDLAnimationBindComponent: NSObject, MDLComponent, NSCopying {
    public var skeleton: MDLSkeleton?
    public var jointAnimation: (any MDLJointAnimation)?
    public var jointPaths: [String]?
    public var geometryBindTransform: matrix_double4x4 = .identity

    public func copy(with zone: NSZone? = nil) -> Any {
        let clone = MDLAnimationBindComponent()
        clone.skeleton = skeleton
        clone.jointAnimation = jointAnimation
        clone.jointPaths = jointPaths
        clone.geometryBindTransform = geometryBindTransform
        return clone
    }
}
