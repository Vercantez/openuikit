import Foundation

open class MDLTransform: NSObject, MDLTransformComponent, NSCopying {
    public var resetsTransform: Bool = true
    public var translation: SIMD3<Float> = SIMD3()
    public var rotation: SIMD3<Float> = SIMD3()
    public var scale: SIMD3<Float> = SIMD3(1, 1, 1)
    public var shear: SIMD3<Float> = SIMD3()
    private var timed: [TimeInterval: matrix_float4x4] = [:]

    public var keyTimes: [NSNumber] {
        timed.keys.sorted().map { NSNumber(value: $0) }
    }

    public var minimumTime: TimeInterval { timed.keys.min() ?? 0 }
    public var maximumTime: TimeInterval { timed.keys.max() ?? 0 }

    public var matrix: matrix_float4x4 {
        get { localTransform(atTime: 0) }
        set { setLocalTransform(newValue) }
    }

    public override init() {
        super.init()
    }

    public convenience init(identity: ()) {
        self.init()
        setIdentity()
        _ = identity
    }

    public convenience init(matrix: matrix_float4x4) {
        self.init(matrix: matrix, resetsTransform: true)
    }

    public convenience init(matrix: matrix_float4x4, resetsTransform: Bool) {
        self.init()
        self.resetsTransform = resetsTransform
        setLocalTransform(matrix)
    }

    public convenience init(transformComponent component: any MDLTransformComponent) {
        self.init(transformComponent: component, resetsTransform: component.resetsTransform)
    }

    public convenience init(transformComponent component: any MDLTransformComponent, resetsTransform: Bool) {
        self.init()
        self.resetsTransform = resetsTransform
        setLocalTransform(component.matrix)
    }

    public func setIdentity() {
        translation = SIMD3()
        rotation = SIMD3()
        scale = SIMD3(1, 1, 1)
        shear = SIMD3()
        timed.removeAll()
    }

    public func localTransform(atTime time: TimeInterval) -> matrix_float4x4 {
        if let exact = timed[time] { return exact }
        if let nearest = timed.keys.sorted().last(where: { $0 <= time }), let matrix = timed[nearest] {
            return matrix
        }
        return mdlTRS(translation, rotation, scale)
    }

    public func setLocalTransform(_ transform: matrix_float4x4) {
        setLocalTransform(transform, forTime: 0)
    }

    public func setLocalTransform(_ transform: matrix_float4x4, forTime time: TimeInterval) {
        timed[time] = transform
        translation = SIMD3(transform.columns.3.x, transform.columns.3.y, transform.columns.3.z)
        scale = SIMD3(
            simd_length(SIMD3(transform.columns.0.x, transform.columns.0.y, transform.columns.0.z)),
            simd_length(SIMD3(transform.columns.1.x, transform.columns.1.y, transform.columns.1.z)),
            simd_length(SIMD3(transform.columns.2.x, transform.columns.2.y, transform.columns.2.z))
        )
    }

    public func setTranslation(_ translation: SIMD3<Float>, forTime time: TimeInterval) {
        self.translation = translation
        timed[time] = mdlTRS(self.translation, rotation, scale)
    }

    public func setRotation(_ rotation: SIMD3<Float>, forTime time: TimeInterval) {
        self.rotation = rotation
        timed[time] = mdlTRS(translation, self.rotation, scale)
    }

    public func setScale(_ scale: SIMD3<Float>, forTime time: TimeInterval) {
        self.scale = scale
        timed[time] = mdlTRS(translation, rotation, self.scale)
    }

    public func setShear(_ shear: SIMD3<Float>, forTime time: TimeInterval) {
        self.shear = shear
        timed[time] = mdlTRS(translation, rotation, scale)
    }

    public func setMatrix(_ matrix: matrix_float4x4, forTime time: TimeInterval) {
        setLocalTransform(matrix, forTime: time)
    }

    public func translation(atTime time: TimeInterval) -> SIMD3<Float> {
        let m = localTransform(atTime: time)
        return SIMD3(m.columns.3.x, m.columns.3.y, m.columns.3.z)
    }

    public func rotation(atTime time: TimeInterval) -> SIMD3<Float> {
        _ = time
        return rotation
    }

    public func rotationMatrix(atTime time: TimeInterval) -> matrix_float4x4 {
        mdlRotationMatrixXYZ(rotation(atTime: time))
    }

    public func scale(atTime time: TimeInterval) -> SIMD3<Float> {
        let m = localTransform(atTime: time)
        return SIMD3(
            simd_length(SIMD3(m.columns.0.x, m.columns.0.y, m.columns.0.z)),
            simd_length(SIMD3(m.columns.1.x, m.columns.1.y, m.columns.1.z)),
            simd_length(SIMD3(m.columns.2.x, m.columns.2.y, m.columns.2.z))
        )
    }

    public func shear(atTime time: TimeInterval) -> SIMD3<Float> {
        _ = time
        return shear
    }

    public func copy(with zone: NSZone? = nil) -> Any {
        let clone = MDLTransform()
        clone.translation = translation
        clone.rotation = rotation
        clone.scale = scale
        clone.shear = shear
        clone.resetsTransform = resetsTransform
        clone.timed = timed
        return clone
    }
}

open class MDLTransformOpBase: NSObject, MDLTransformOp {
    public var name: String
    var inverse: Bool

    init(name: String, inverse: Bool) {
        self.name = name
        self.inverse = inverse
        super.init()
    }

    public func isInverseOp() -> Bool { inverse }

    public func float4x4(atTime time: TimeInterval) -> matrix_float4x4 {
        _ = time
        return .identity
    }

    public func double4x4(atTime time: TimeInterval) -> matrix_double4x4 {
        mdlFloatToDouble(float4x4(atTime: time))
    }
}

public class MDLTransformTranslateOp: MDLTransformOpBase {
    public let animatedValue = MDLAnimatedVector3()

    public override func float4x4(atTime time: TimeInterval) -> matrix_float4x4 {
        let t = animatedValue.float3Value(atTime: time)
        return mdlTranslationMatrix(inverse ? -t : t)
    }
}

public class MDLTransformScaleOp: MDLTransformOpBase {
    public let animatedValue = MDLAnimatedVector3()

    public override func float4x4(atTime time: TimeInterval) -> matrix_float4x4 {
        var s = animatedValue.float3Value(atTime: time)
        if inverse {
            s = SIMD3(
                s.x == 0 ? 0 : 1 / s.x,
                s.y == 0 ? 0 : 1 / s.y,
                s.z == 0 ? 0 : 1 / s.z
            )
        }
        return mdlScaleMatrix(s == SIMD3<Float>() ? SIMD3(1, 1, 1) : s)
    }
}

public class MDLTransformRotateOp: MDLTransformOpBase {
    public let animatedValue = MDLAnimatedVector3()
    var order: MDLTransformOpRotationOrder = .xyz

    public override func float4x4(atTime time: TimeInterval) -> matrix_float4x4 {
        let r = animatedValue.float3Value(atTime: time)
        _ = order
        let matrix = mdlRotationMatrixXYZ(inverse ? -r : r)
        return matrix
    }
}

public class MDLTransformRotateXOp: MDLTransformOpBase {
    public let animatedValue = MDLAnimatedScalar()

    public override func float4x4(atTime time: TimeInterval) -> matrix_float4x4 {
        let angle = animatedValue.floatValue(atTime: time)
        return mdlRotationMatrixXYZ(SIMD3(inverse ? -angle : angle, 0, 0))
    }
}

public class MDLTransformRotateYOp: MDLTransformOpBase {
    public let animatedValue = MDLAnimatedScalar()

    public override func float4x4(atTime time: TimeInterval) -> matrix_float4x4 {
        let angle = animatedValue.floatValue(atTime: time)
        return mdlRotationMatrixXYZ(SIMD3(0, inverse ? -angle : angle, 0))
    }
}

public class MDLTransformRotateZOp: MDLTransformOpBase {
    public let animatedValue = MDLAnimatedScalar()

    public override func float4x4(atTime time: TimeInterval) -> matrix_float4x4 {
        let angle = animatedValue.floatValue(atTime: time)
        return mdlRotationMatrixXYZ(SIMD3(0, 0, inverse ? -angle : angle))
    }
}

public class MDLTransformOrientOp: MDLTransformOpBase {
    public let animatedValue = MDLAnimatedQuaternion()

    public override func float4x4(atTime time: TimeInterval) -> matrix_float4x4 {
        let q = animatedValue.floatQuaternionValue(atTime: time)
        let v = q.vector
        let x = v.x, y = v.y, z = v.z, w = v.w
        let xx = x * x, yy = y * y, zz = z * z
        let xy = x * y, xz = x * z, yz = y * z
        let wx = w * x, wy = w * y, wz = w * z
        return matrix_float4x4(columns: (
            SIMD4(1 - 2 * (yy + zz), 2 * (xy + wz), 2 * (xz - wy), 0),
            SIMD4(2 * (xy - wz), 1 - 2 * (xx + zz), 2 * (yz + wx), 0),
            SIMD4(2 * (xz + wy), 2 * (yz - wx), 1 - 2 * (xx + yy), 0),
            SIMD4(Float(0), 0, 0, 1)
        ))
    }
}

public class MDLTransformMatrixOp: MDLTransformOpBase {
    public let animatedValue = MDLAnimatedMatrix4x4()

    public override func float4x4(atTime time: TimeInterval) -> matrix_float4x4 {
        animatedValue.float4x4Value(atTime: time)
    }
}

public class MDLTransformStack: NSObject, MDLTransformComponent, NSCopying {
    public var resetsTransform: Bool = true
    public private(set) var transformOps: [any MDLTransformOp] = []
    private var named = [String: MDLAnimatedValue]()

    public var keyTimes: [NSNumber] {
        let times = transformOps.compactMap { op -> [NSNumber]? in
            if let translate = op as? MDLTransformTranslateOp { return translate.animatedValue.keyTimes }
            if let scale = op as? MDLTransformScaleOp { return scale.animatedValue.keyTimes }
            if let rotate = op as? MDLTransformRotateOp { return rotate.animatedValue.keyTimes }
            if let rx = op as? MDLTransformRotateXOp { return rx.animatedValue.keyTimes }
            if let ry = op as? MDLTransformRotateYOp { return ry.animatedValue.keyTimes }
            if let rz = op as? MDLTransformRotateZOp { return rz.animatedValue.keyTimes }
            if let orient = op as? MDLTransformOrientOp { return orient.animatedValue.keyTimes }
            if let matrix = op as? MDLTransformMatrixOp { return matrix.animatedValue.keyTimes }
            return nil
        }.flatMap { $0 }
        return Array(Set(times)).sorted { $0.doubleValue < $1.doubleValue }
    }

    public var minimumTime: TimeInterval { keyTimes.first?.doubleValue ?? 0 }
    public var maximumTime: TimeInterval { keyTimes.last?.doubleValue ?? 0 }

    public var matrix: matrix_float4x4 {
        get { float4x4(atTime: 0) }
        set { addMatrixOp("matrix", inverse: false).animatedValue.setFloat4x4(newValue, atTime: 0) }
    }

    public func localTransform(atTime time: TimeInterval) -> matrix_float4x4 {
        float4x4(atTime: time)
    }

    public func setLocalTransform(_ transform: matrix_float4x4) {
        matrix = transform
    }

    public func setLocalTransform(_ transform: matrix_float4x4, forTime time: TimeInterval) {
        addMatrixOp("matrix", inverse: false).animatedValue.setFloat4x4(transform, atTime: time)
    }

    public func count() -> UInt { UInt(transformOps.count) }

    public func animatedValue(withName name: String) -> MDLAnimatedValue {
        named[name] ?? MDLAnimatedValue()
    }

    public func addTranslateOp(_ animatedValueName: String, inverse: Bool) -> MDLTransformTranslateOp {
        let op = MDLTransformTranslateOp(name: animatedValueName, inverse: inverse)
        transformOps.append(op)
        named[animatedValueName] = op.animatedValue
        return op
    }

    public func addScaleOp(_ animatedValueName: String, inverse: Bool) -> MDLTransformScaleOp {
        let op = MDLTransformScaleOp(name: animatedValueName, inverse: inverse)
        transformOps.append(op)
        named[animatedValueName] = op.animatedValue
        return op
    }

    public func addRotateOp(_ animatedValueName: String, order: MDLTransformOpRotationOrder, inverse: Bool) -> MDLTransformRotateOp {
        let op = MDLTransformRotateOp(name: animatedValueName, inverse: inverse)
        op.order = order
        transformOps.append(op)
        named[animatedValueName] = op.animatedValue
        return op
    }

    public func addRotateXOp(_ animatedValueName: String, inverse: Bool) -> MDLTransformRotateXOp {
        let op = MDLTransformRotateXOp(name: animatedValueName, inverse: inverse)
        transformOps.append(op)
        named[animatedValueName] = op.animatedValue
        return op
    }

    public func addRotateYOp(_ animatedValueName: String, inverse: Bool) -> MDLTransformRotateYOp {
        let op = MDLTransformRotateYOp(name: animatedValueName, inverse: inverse)
        transformOps.append(op)
        named[animatedValueName] = op.animatedValue
        return op
    }

    public func addRotateZOp(_ animatedValueName: String, inverse: Bool) -> MDLTransformRotateZOp {
        let op = MDLTransformRotateZOp(name: animatedValueName, inverse: inverse)
        transformOps.append(op)
        named[animatedValueName] = op.animatedValue
        return op
    }

    public func addOrientOp(_ animatedValueName: String, inverse: Bool) -> MDLTransformOrientOp {
        let op = MDLTransformOrientOp(name: animatedValueName, inverse: inverse)
        transformOps.append(op)
        named[animatedValueName] = op.animatedValue
        return op
    }

    public func addMatrixOp(_ animatedValueName: String, inverse: Bool) -> MDLTransformMatrixOp {
        let op = MDLTransformMatrixOp(name: animatedValueName, inverse: inverse)
        transformOps.append(op)
        named[animatedValueName] = op.animatedValue
        return op
    }

    public func float4x4(atTime time: TimeInterval) -> matrix_float4x4 {
        var result = matrix_float4x4.identity
        for op in transformOps {
            result = mdlMul(result, op.float4x4(atTime: time))
        }
        return result
    }

    public func double4x4(atTime time: TimeInterval) -> matrix_double4x4 {
        mdlFloatToDouble(float4x4(atTime: time))
    }

    public func copy(with zone: NSZone? = nil) -> Any {
        let clone = MDLTransformStack()
        clone.resetsTransform = resetsTransform
        clone.transformOps = transformOps
        clone.named = named
        return clone
    }
}
