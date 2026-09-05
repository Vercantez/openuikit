import Foundation

open class SKKeyframeSequence: NSObject, NSSecureCoding, NSCopying {
    public var interpolationMode: SKInterpolationMode = .linear
    public var repeatMode: SKRepeatMode = .clamp
    var times: [CGFloat] = []
    var values: [Any] = []

    public override init() { super.init() }

    public convenience init(capacity numItems: UInt) {
        self.init()
        times.reserveCapacity(Int(numItems))
        values.reserveCapacity(Int(numItems))
    }

    public init(keyframeValues values: [Any], times: [NSNumber]) {
        self.values = values
        self.times = times.map { CGFloat($0.doubleValue) }
        super.init()
    }

    public required init?(coder: NSCoder) {
        interpolationMode = SKInterpolationMode(rawValue: coder.decodeInteger(forKey: "interp")) ?? .linear
        super.init()
    }

    public func encode(with coder: NSCoder) {
        coder.encode(interpolationMode.rawValue, forKey: "interp")
    }

    public static var supportsSecureCoding: Bool { true }
    public func copy(with zone: NSZone? = nil) -> Any {
        let copy = SKKeyframeSequence(keyframeValues: values, times: times.map { NSNumber(value: Double($0)) })
        copy.interpolationMode = interpolationMode
        copy.repeatMode = repeatMode
        return copy
    }

    public func count() -> UInt { UInt(values.count) }

    public func addKeyframeValue(_ value: Any, time: CGFloat) {
        times.append(time)
        values.append(value)
    }

    public func removeLastKeyframe() {
        _ = times.popLast()
        _ = values.popLast()
    }

    public func removeKeyframe(at index: UInt) {
        let i = Int(index)
        guard times.indices.contains(i) else { return }
        times.remove(at: i)
        values.remove(at: i)
    }

    public func setKeyframeValue(_ value: Any, for index: UInt) {
        let i = Int(index)
        guard values.indices.contains(i) else { return }
        values[i] = value
    }

    public func setKeyframeTime(_ time: CGFloat, for index: UInt) {
        let i = Int(index)
        guard times.indices.contains(i) else { return }
        times[i] = time
    }

    public func setKeyframeValue(_ value: Any, time: CGFloat, for index: UInt) {
        setKeyframeValue(value, for: index)
        setKeyframeTime(time, for: index)
    }

    public func getKeyframeValue(for index: UInt) -> Any {
        values[Int(index)]
    }

    public func getKeyframeTime(for index: UInt) -> CGFloat {
        times[Int(index)]
    }

    public func sample(atTime time: CGFloat) -> Any? {
        guard !times.isEmpty else { return nil }
        var t = time
        let last = times.last ?? 0
        if t > last {
            switch repeatMode {
            case .clamp:
                t = last
            case .loop:
                if last > 0 { t = time.truncatingRemainder(dividingBy: last) }
            }
        }
        if t <= times[0] { return values[0] }
        for i in 1..<times.count {
            if t <= times[i] {
                let span = times[i] - times[i - 1]
                let u = span == 0 ? 1 : (t - times[i - 1]) / span
                switch interpolationMode {
                case .step:
                    return values[i - 1]
                case .linear, .spline:
                    return sk_mixKeyframe(values[i - 1], values[i], u)
                }
            }
        }
        return values.last
    }
}

func sk_mixKeyframe(_ a: Any, _ b: Any, _ t: CGFloat) -> Any {
    if let af = a as? CGFloat, let bf = b as? CGFloat {
        return sk_lerp(af, bf, t)
    }
    if let af = a as? Float, let bf = b as? Float {
        return Float(sk_lerp(CGFloat(af), CGFloat(bf), t))
    }
    if let af = a as? NSNumber, let bf = b as? NSNumber {
        return NSNumber(value: Double(sk_lerp(CGFloat(af.doubleValue), CGFloat(bf.doubleValue), t)))
    }
    return t < 1 ? a : b
}

open class SKEmitterNode: SKNode {
    public var particleTexture: SKTexture?
    public var particleBlendMode: SKBlendMode = .alpha
    public var particleColor: SKColor = .white
    public var particleColorBlendFactor: CGFloat = 1
    public var particleColorRedRange: CGFloat = 0
    public var particleColorGreenRange: CGFloat = 0
    public var particleColorBlueRange: CGFloat = 0
    public var particleColorAlphaRange: CGFloat = 0
    public var particleColorRedSpeed: CGFloat = 0
    public var particleColorGreenSpeed: CGFloat = 0
    public var particleColorBlueSpeed: CGFloat = 0
    public var particleColorAlphaSpeed: CGFloat = 0
    public var particleColorBlendFactorRange: CGFloat = 0
    public var particleColorBlendFactorSpeed: CGFloat = 0
    public var particleColorSequence: SKKeyframeSequence?
    public var particleColorBlendFactorSequence: SKKeyframeSequence?
    public var particlePosition: CGPoint = .zero
    public var particlePositionRange: CGVector = CGVector()
    public var particleSpeed: CGFloat = 0
    public var particleSpeedRange: CGFloat = 0
    public var emissionAngle: CGFloat = 0
    public var emissionAngleRange: CGFloat = 0
    public var xAcceleration: CGFloat = 0
    public var yAcceleration: CGFloat = 0
    public var particleBirthRate: CGFloat = 0
    public var numParticlesToEmit: UInt = 0
    public var particleLifetime: CGFloat = 0
    public var particleLifetimeRange: CGFloat = 0
    public var particleRotation: CGFloat = 0
    public var particleRotationRange: CGFloat = 0
    public var particleRotationSpeed: CGFloat = 0
    public var particleSize: CGSize = CGSize(width: 1, height: 1)
    public var particleScale: CGFloat = 1
    public var particleScaleRange: CGFloat = 0
    public var particleScaleSpeed: CGFloat = 0
    public var particleScaleSequence: SKKeyframeSequence?
    public var particleAlpha: CGFloat = 1
    public var particleAlphaRange: CGFloat = 0
    public var particleAlphaSpeed: CGFloat = 0
    public var particleAlphaSequence: SKKeyframeSequence?
    public var particleAction: SKAction?
    public var fieldBitMask: UInt32 = 0
    public var particleZPosition: CGFloat = 0
    public var particleZPositionRange: CGFloat = 0
    public var particleZPositionSpeed: CGFloat = 0
    public var particleRenderOrder: SKParticleRenderOrder = .dontCare
    public var shader: SKShader?
    public weak var targetNode: SKNode?
    var _simTime: TimeInterval = 0

    public override init() { super.init() }
    public required init?(coder: NSCoder) { super.init(coder: coder) }

    public func advanceSimulationTime(_ sec: TimeInterval) {
        _simTime += max(0, sec)
    }

    public func resetSimulation() {
        _simTime = 0
    }
}

open class SKFieldNode: SKNode {
    public var isEnabled: Bool = true
    public var isExclusive: Bool = false
    public var strength: Float = 1
    public var falloff: Float = 0
    public var minimumRadius: Float = 0
    public var categoryBitMask: UInt32 = 0xFFFF_FFFF
    public var smoothness: Float = 0
    public var animationSpeed: Float = 0
    public var direction: vector_float3 = SIMD3<Float>(0, -1, 0)
    public var region: SKRegion?
    public var texture: SKTexture?
    var evaluator: SKFieldForceEvaluator?
    var fieldKind: String = "radial"

    public override init() { super.init() }
    public required init?(coder: NSCoder) { super.init(coder: coder) }

    public class func dragField() -> SKFieldNode {
        let n = SKFieldNode(); n.fieldKind = "drag"; return n
    }
    public class func electricField() -> SKFieldNode {
        let n = SKFieldNode(); n.fieldKind = "electric"; return n
    }
    public class func magneticField() -> SKFieldNode {
        let n = SKFieldNode(); n.fieldKind = "magnetic"; return n
    }
    public class func radialGravityField() -> SKFieldNode {
        let n = SKFieldNode(); n.fieldKind = "radial"; return n
    }
    public class func springField() -> SKFieldNode {
        let n = SKFieldNode(); n.fieldKind = "spring"; return n
    }
    public class func vortexField() -> SKFieldNode {
        let n = SKFieldNode(); n.fieldKind = "vortex"; return n
    }
    public class func linearGravityField(withVector direction: vector_float3) -> SKFieldNode {
        let n = SKFieldNode(); n.fieldKind = "linear"; n.direction = direction; return n
    }
    public class func velocityField(withVector direction: vector_float3) -> SKFieldNode {
        let n = SKFieldNode(); n.fieldKind = "velocity"; n.direction = direction; return n
    }
    public class func velocityField(with velocityTexture: SKTexture) -> SKFieldNode {
        let n = SKFieldNode(); n.fieldKind = "velocityTex"; n.texture = velocityTexture; return n
    }
    public class func noiseField(withSmoothness smoothness: CGFloat, animationSpeed speed: CGFloat) -> SKFieldNode {
        let n = SKFieldNode(); n.fieldKind = "noise"; n.smoothness = Float(smoothness); n.animationSpeed = Float(speed); return n
    }
    public class func turbulenceField(withSmoothness smoothness: CGFloat, animationSpeed speed: CGFloat) -> SKFieldNode {
        let n = SKFieldNode(); n.fieldKind = "turbulence"; n.smoothness = Float(smoothness); n.animationSpeed = Float(speed); return n
    }
    public class func customField(evaluationBlock block: @escaping SKFieldForceEvaluator) -> SKFieldNode {
        let n = SKFieldNode(); n.fieldKind = "custom"; n.evaluator = block; return n
    }

    func _evaluate(at position: vector_float3) -> vector_float3 {
        if let evaluator {
            return evaluator(position, SIMD3<Float>(0, 0, 0), 1, strength, 0)
        }
        switch fieldKind {
        case "linear", "velocity":
            return direction * strength
        case "radial":
            let dx = position.x
            let dy = position.y
            let dz = position.z
            let len = max(0.0001, sqrt(dx * dx + dy * dy + dz * dz))
            return SIMD3<Float>(-dx / len, -dy / len, -dz / len) * strength
        default:
            return SIMD3<Float>(0, 0, 0)
        }
    }
}

open class SKLightNode: SKNode {
    public var isEnabled: Bool = true
    public var categoryBitMask: UInt32 = 1
    public var falloff: CGFloat = 1
    public var ambientColor: SKColor = .black
    public var lightColor: SKColor = .white
    public var shadowColor: SKColor = SKColor(white: 0, alpha: 0.5)
}

open class SKCropNode: SKNode {
    public var maskNode: SKNode?
}

open class SKEffectNode: SKNode {
    public var shouldEnableEffects: Bool = false
    public var shouldCenterFilter: Bool = true
    public var shouldRasterize: Bool = false
    public var blendMode: SKBlendMode = .alpha
    public var shader: SKShader?
}

open class SKAudioNode: SKNode {
    public var autoplayLooped: Bool = true
    public var isPositional: Bool = true
    var _url: URL?

    public override init() { super.init() }
    public required init?(coder: NSCoder) { super.init(coder: coder) }

    public convenience init(fileNamed name: String) {
        self.init(url: URL(fileURLWithPath: name))
    }

    public convenience init(url: URL) {
        self.init()
        _url = url
    }

    public convenience init(URL url: URL) {
        self.init(url: url)
    }
}

open class SKVideoNode: SKNode {
    public var size: CGSize = CGSize(width: 1, height: 1)
    public var anchorPoint: CGPoint = CGPoint(x: 0.5, y: 0.5)
    var playing = false
    var _url: URL?

    public override init() { super.init() }
    public required init?(coder: NSCoder) { super.init(coder: coder) }

    public init(url: URL) {
        _url = url
        super.init()
    }

    public convenience init(URL url: URL) { self.init(url: url) }
    public convenience init(videoURL url: URL) { self.init(url: url) }

    public init(fileNamed videoFile: String) {
        _url = URL(fileURLWithPath: videoFile)
        super.init()
    }

    public convenience init(videoFileNamed videoFile: String) {
        self.init(fileNamed: videoFile)
    }

    public func play() { playing = true }
    public func pause() { playing = false }
}

open class SKReferenceNode: SKNode {
    var _url: URL?
    var resolved: SKNode?

    public override init() { super.init() }
    public required init?(coder: NSCoder) { super.init(coder: coder) }

    public convenience init(fileNamed fileName: String) {
        self.init()
        _url = URL(fileURLWithPath: fileName)
    }

    public convenience init(url referenceURL: URL) {
        self.init()
        _url = referenceURL
    }

    public convenience init(URL referenceURL: URL) {
        self.init(url: referenceURL)
    }

    public func resolve() {
        resolved = nil
        didLoad(nil)
    }

    open func didLoad(_ node: SKNode?) {
        resolved = node
    }
}

open class SKTransformNode: SKNode {
    public var xRotation: CGFloat = 0
    public var yRotation: CGFloat = 0
    var _quat = simd_quatf()
    var _matrix = matrix_float3x3()

    public func eulerAngles() -> vector_float3 {
        SIMD3<Float>(Float(xRotation), Float(yRotation), Float(zRotation))
    }

    public func setEulerAngles(_ euler: vector_float3) {
        xRotation = CGFloat(euler.x)
        yRotation = CGFloat(euler.y)
        zRotation = CGFloat(euler.z)
    }

    public func quaternion() -> simd_quatf { _quat }

    public func setQuaternion(_ quaternion: simd_quatf) {
        _quat = quaternion
    }

    public func rotationMatrix() -> matrix_float3x3 { _matrix }

    public func setRotationMatrix(_ rotationMatrix: matrix_float3x3) {
        _matrix = rotationMatrix
    }
}

open class SK3DNode: SKNode {
    public var viewportSize: CGSize
    public var sceneTime: TimeInterval = 0
    public var loops: Bool = true
    public var isPlaying: Bool = false
    public var autoenablesDefaultLighting: Bool = false

    public init(viewportSize: CGSize) {
        self.viewportSize = viewportSize
        super.init()
    }

    public required init?(coder: NSCoder) {
        viewportSize = CGSize(width: 1, height: 1)
        super.init(coder: coder)
    }

    public func projectPoint(_ point: vector_float3) -> vector_float3 { point }
    public func unprojectPoint(_ point: vector_float3) -> vector_float3 { point }
}
