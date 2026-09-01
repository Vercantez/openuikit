import Foundation
#if canImport(simd)
import simd
#endif

public final class SCNMaterialProperty: NSObject, SCNAnimatable {
    public var contents: Any?
    public var contentsTransform = SCNMatrix4Identity
    public var intensity: CGFloat = 1
    public var magnificationFilter = SCNFilterMode.linear
    public var minificationFilter = SCNFilterMode.linear
    public var mipFilter = SCNFilterMode.nearest
    public var wrapS = SCNWrapMode.clamp
    public var wrapT = SCNWrapMode.clamp
    public var mappingChannel = 0
    public var maxAnisotropy: CGFloat = 1
    public var textureComponents = SCNColorMask.all
    public var borderColor: Any?
    var _animationPlayers: [String: SCNAnimationPlayer] = [:]

    public convenience init(contents: Any) {
        self.init()
        self.contents = contents
    }

    public override init() {
        super.init()
    }

    public required init?(coder: NSCoder) { return nil }

    public var animationKeys: [String] { Array(_animationPlayers.keys) }
    public func addAnimation(_ animation: any SCNAnimationProtocol, forKey key: String?) {
        _ = animation
        _animationPlayers[key ?? UUID().uuidString] = SCNAnimationPlayer(animation: SCNAnimation())
    }
    public func addAnimationPlayer(_ player: SCNAnimationPlayer, forKey key: String?) {
        _animationPlayers[key ?? UUID().uuidString] = player
    }
    public func animationPlayer(forKey key: String) -> SCNAnimationPlayer? { _animationPlayers[key] }
    public func isAnimationPaused(forKey key: String) -> Bool { _animationPlayers[key]?.paused ?? false }
    public func pauseAnimation(forKey key: String) { _animationPlayers[key]?.paused = true }
    public func removeAllAnimations() { _animationPlayers.removeAll() }
    public func removeAllAnimations(withBlendOutDuration duration: CGFloat) {
        _ = duration
        _animationPlayers.removeAll()
    }
    public func removeAnimation(forKey key: String) { _animationPlayers.removeValue(forKey: key) }
    public func removeAnimation(forKey key: String, blendOutDuration duration: CGFloat) {
        _ = duration
        _animationPlayers.removeValue(forKey: key)
    }
    public func removeAnimation(forKey key: String, fadeOutDuration duration: CGFloat) {
        _ = duration
        _animationPlayers.removeValue(forKey: key)
    }
    public func resumeAnimation(forKey key: String) { _animationPlayers[key]?.paused = false }
    public func setAnimationSpeed(_ speed: CGFloat, forKey key: String) { _animationPlayers[key]?.speed = speed }
}

public final class SCNMaterial: NSObject, SCNAnimatable, SCNShadable {
    public struct LightingModel: RawRepresentable, Hashable, Sendable {
        public let rawValue: String
        public init(rawValue: String) { self.rawValue = rawValue }

        public static let constant = LightingModel(rawValue: "constant")
        public static let lambert = LightingModel(rawValue: "lambert")
        public static let blinn = LightingModel(rawValue: "blinn")
        public static let phong = LightingModel(rawValue: "phong")
        public static let physicallyBased = LightingModel(rawValue: "physicallyBased")
        public static let shadowOnly = LightingModel(rawValue: "shadowOnly")
    }

    public var name: String?
    public let diffuse = SCNMaterialProperty()
    public let ambient = SCNMaterialProperty()
    public let specular = SCNMaterialProperty()
    public let emission = SCNMaterialProperty()
    public let transparent = SCNMaterialProperty()
    public let reflective = SCNMaterialProperty()
    public let multiply = SCNMaterialProperty()
    public let normal = SCNMaterialProperty()
    public let displacement = SCNMaterialProperty()
    public let ambientOcclusion = SCNMaterialProperty()
    public let selfIllumination = SCNMaterialProperty()
    public let metalness = SCNMaterialProperty()
    public let roughness = SCNMaterialProperty()
    public let clearCoat = SCNMaterialProperty()
    public let clearCoatNormal = SCNMaterialProperty()
    public let clearCoatRoughness = SCNMaterialProperty()
    public var lightingModel = LightingModel.blinn
    public var shininess: CGFloat = 1
    public var transparency: CGFloat = 1
    public var transparencyMode = SCNTransparencyMode.aOne
    public var fresnelExponent: CGFloat = 0
    public var blendMode = SCNBlendMode.alpha
    public var cullMode = SCNCullMode.back
    public var fillMode = SCNFillMode.fill
    public var isDoubleSided = false
    public var isLitPerPixel = true
    public var locksAmbientWithDiffuse = true
    public var writesToDepthBuffer = true
    public var readsFromDepthBuffer = true
    public var colorBufferWriteMask = SCNColorMask.all
    var _animationPlayers: [String: SCNAnimationPlayer] = [:]

    public override init() {
        super.init()
        diffuse.contents = nil
        metalness.contents = NSNumber(value: 0)
        roughness.contents = NSNumber(value: 1)
    }

    public required init?(coder: NSCoder) { return nil }

    public var animationKeys: [String] { Array(_animationPlayers.keys) }
    public func addAnimation(_ animation: any SCNAnimationProtocol, forKey key: String?) {
        _ = animation
        _animationPlayers[key ?? UUID().uuidString] = SCNAnimationPlayer(animation: SCNAnimation())
    }
    public func addAnimationPlayer(_ player: SCNAnimationPlayer, forKey key: String?) {
        _animationPlayers[key ?? UUID().uuidString] = player
    }
    public func animationPlayer(forKey key: String) -> SCNAnimationPlayer? { _animationPlayers[key] }
    public func isAnimationPaused(forKey key: String) -> Bool { _animationPlayers[key]?.paused ?? false }
    public func pauseAnimation(forKey key: String) { _animationPlayers[key]?.paused = true }
    public func removeAllAnimations() { _animationPlayers.removeAll() }
    public func removeAllAnimations(withBlendOutDuration duration: CGFloat) {
        _ = duration
        _animationPlayers.removeAll()
    }
    public func removeAnimation(forKey key: String) { _animationPlayers.removeValue(forKey: key) }
    public func removeAnimation(forKey key: String, blendOutDuration duration: CGFloat) {
        _ = duration
        _animationPlayers.removeValue(forKey: key)
    }
    public func removeAnimation(forKey key: String, fadeOutDuration duration: CGFloat) {
        _ = duration
        _animationPlayers.removeValue(forKey: key)
    }
    public func resumeAnimation(forKey key: String) { _animationPlayers[key]?.paused = false }
    public func setAnimationSpeed(_ speed: CGFloat, forKey key: String) { _animationPlayers[key]?.speed = speed }
}

public final class SCNCamera: NSObject, SCNAnimatable, SCNTechniqueSupport {
    public var name: String?
    public var fieldOfView: CGFloat = 60
    public var focalLength: CGFloat = 50
    public var sensorHeight: CGFloat = 24
    public var zNear: Double = 1
    public var zFar: Double = 100
    public var automaticallyAdjustsZRange = false
    public var usesOrthographicProjection = false
    public var orthographicScale: Double = 1
    public var projectionDirection = SCNCameraProjectionDirection.vertical
    public var projectionTransform = SCNMatrix4Identity
    public var xFov: Double = 0
    public var yFov: Double = 0
    public var categoryBitMask = Int.max
    public var aperture: CGFloat = 0.125
    public var apertureBladeCount = 6
    public var fStop: CGFloat = 5.6
    public var focalDistance: CGFloat = 10
    public var focalSize: CGFloat = 0
    public var focalBlurRadius: CGFloat = 0
    public var focalBlurSampleCount = 0
    public var focusDistance: CGFloat = 2.5
    public var wantsDepthOfField = false
    public var motionBlurIntensity: CGFloat = 0
    public var wantsHDR = false
    public var wantsExposureAdaptation = false
    public var exposureOffset: CGFloat = 0
    public var minimumExposure: CGFloat = -15
    public var maximumExposure: CGFloat = 15
    public var whitePoint: CGFloat = 1
    public var averageGray: CGFloat = 0.18
    public var exposureAdaptationBrighteningSpeedFactor: CGFloat = 0.4
    public var exposureAdaptationDarkeningSpeedFactor: CGFloat = 0.6
    public var bloomIntensity: CGFloat = 0
    public var bloomThreshold: CGFloat = 0.5
    public var bloomBlurRadius: CGFloat = 3
    public var bloomIterationCount = 1
    public var bloomIterationSpread: CGFloat = 0
    public var vignettingPower: CGFloat = 0
    public var vignettingIntensity: CGFloat = 0
    public var colorFringeStrength: CGFloat = 0
    public var colorFringeIntensity: CGFloat = 1
    public var saturation: CGFloat = 1
    public var contrast: CGFloat = 0
    public var grainIntensity: CGFloat = 0
    public var grainScale: CGFloat = 1
    public var grainIsColored = false
    public var whiteBalanceTemperature: CGFloat = 0
    public var whiteBalanceTint: CGFloat = 0
    public var screenSpaceAmbientOcclusionIntensity: CGFloat = 0
    public var screenSpaceAmbientOcclusionRadius: CGFloat = 5
    public var screenSpaceAmbientOcclusionBias: CGFloat = 0.03
    public var screenSpaceAmbientOcclusionDepthThreshold: CGFloat = 0.2
    public var screenSpaceAmbientOcclusionNormalThreshold: CGFloat = 0.3
    public let colorGrading = SCNMaterialProperty()
    var _animationPlayers: [String: SCNAnimationPlayer] = [:]
    var _customProjection = false

    public override init() {
        super.init()
        _refreshProjection(aspect: 1)
    }

    public required init?(coder: NSCoder) { return nil }

    public func projectionTransform(withViewportSize viewportSize: CGSize) -> SCNMatrix4 {
        let aspect = viewportSize.height == 0 ? 1 : Float(viewportSize.width / viewportSize.height)
        return _makeProjection(aspect: aspect)
    }

    func _refreshProjection(aspect: Float) {
        if !_customProjection {
            projectionTransform = _makeProjection(aspect: aspect)
        }
    }

    func _makeProjection(aspect: Float) -> SCNMatrix4 {
        if usesOrthographicProjection {
            return _scnOrthographicMatrix(
                scale: Float(orthographicScale),
                aspect: aspect,
                zNear: Float(zNear),
                zFar: Float(zFar)
            )
        }
        return _scnPerspectiveMatrix(
            fieldOfViewDegrees: Float(fieldOfView),
            aspect: aspect,
            zNear: Float(zNear),
            zFar: Float(zFar),
            vertical: projectionDirection == .vertical
        )
    }

    public var animationKeys: [String] { Array(_animationPlayers.keys) }
    public func addAnimation(_ animation: any SCNAnimationProtocol, forKey key: String?) {
        _ = animation
        _animationPlayers[key ?? UUID().uuidString] = SCNAnimationPlayer(animation: SCNAnimation())
    }
    public func addAnimationPlayer(_ player: SCNAnimationPlayer, forKey key: String?) {
        _animationPlayers[key ?? UUID().uuidString] = player
    }
    public func animationPlayer(forKey key: String) -> SCNAnimationPlayer? { _animationPlayers[key] }
    public func isAnimationPaused(forKey key: String) -> Bool { _animationPlayers[key]?.paused ?? false }
    public func pauseAnimation(forKey key: String) { _animationPlayers[key]?.paused = true }
    public func removeAllAnimations() { _animationPlayers.removeAll() }
    public func removeAllAnimations(withBlendOutDuration duration: CGFloat) {
        _ = duration
        _animationPlayers.removeAll()
    }
    public func removeAnimation(forKey key: String) { _animationPlayers.removeValue(forKey: key) }
    public func removeAnimation(forKey key: String, blendOutDuration duration: CGFloat) {
        _ = duration
        _animationPlayers.removeValue(forKey: key)
    }
    public func removeAnimation(forKey key: String, fadeOutDuration duration: CGFloat) {
        _ = duration
        _animationPlayers.removeValue(forKey: key)
    }
    public func resumeAnimation(forKey key: String) { _animationPlayers[key]?.paused = false }
    public func setAnimationSpeed(_ speed: CGFloat, forKey key: String) { _animationPlayers[key]?.speed = speed }
}

public final class SCNLight: NSObject, SCNAnimatable {
    public struct LightType: RawRepresentable, Hashable, Sendable {
        public let rawValue: String
        public init(rawValue: String) { self.rawValue = rawValue }

        public static let ambient = LightType(rawValue: "ambient")
        public static let omni = LightType(rawValue: "omni")
        public static let directional = LightType(rawValue: "directional")
        public static let spot = LightType(rawValue: "spot")
        public static let IES = LightType(rawValue: "IES")
        public static let probe = LightType(rawValue: "probe")
        public static let area = LightType(rawValue: "area")
    }

    public var name: String?
    public var type = LightType.omni
    public var color: Any = NSNumber(value: 1)
    public var temperature: CGFloat = 6500
    public var intensity: CGFloat = 1000
    public var categoryBitMask = Int.max
    public var castsShadow = false
    public var shadowRadius: CGFloat = 3
    public var shadowColor: Any = NSNumber(value: 0)
    public var shadowMapSize = CGSize(width: 0, height: 0)
    public var shadowSampleCount = 0
    public var shadowMode = SCNShadowMode.forward
    public var shadowBias: CGFloat = 1
    public var automaticallyAdjustsShadowProjection = true
    public var maximumShadowDistance: CGFloat = 100
    public var forcesBackFaceCasters = false
    public var sampleDistributedShadowMaps = false
    public var shadowCascadeCount = 1
    public var shadowCascadeSplittingFactor: CGFloat = 0.15
    public var orthographicScale: CGFloat = 1
    public var zNear: CGFloat = 1
    public var zFar: CGFloat = 100
    public var attenuationStartDistance: CGFloat = 0
    public var attenuationEndDistance: CGFloat = 0
    public var attenuationFalloffExponent: CGFloat = 2
    public var spotInnerAngle: CGFloat = 0
    public var spotOuterAngle: CGFloat = 45
    public var gobo: SCNMaterialProperty?
    public var iesProfileURL: URL?
    public var areaType = SCNLightAreaType.rectangle
#if canImport(simd)
    public var areaExtents: simd_float3 = simd_float3(1, 1, 0)
#endif
    public var areaPolygonVertices: [NSValue]?
    public var doubleSided = false
    public var drawsArea = true
    public var probeType = SCNLightProbeType.irradiance
    public var probeUpdateType = SCNLightProbeUpdateType.never
#if canImport(simd)
    public var probeExtents: simd_float3 = simd_float3(1, 1, 1)
    public var probeOffset: simd_float3 = simd_float3(0, 0, 0)
#endif
    public var probeEnvironment: SCNMaterialProperty?
    public var parallaxCorrectionEnabled = false
#if canImport(simd)
    public var parallaxExtentsFactor: simd_float3 = simd_float3(1, 1, 1)
    public var parallaxCenterOffset: simd_float3 = simd_float3(0, 0, 0)
#endif
    public var sphericalHarmonicsCoefficients = Data()
    var _animationPlayers: [String: SCNAnimationPlayer] = [:]

    public override init() { super.init() }
    public required init?(coder: NSCoder) { return nil }

    public var animationKeys: [String] { Array(_animationPlayers.keys) }
    public func addAnimation(_ animation: any SCNAnimationProtocol, forKey key: String?) {
        _ = animation
        _animationPlayers[key ?? UUID().uuidString] = SCNAnimationPlayer(animation: SCNAnimation())
    }
    public func addAnimationPlayer(_ player: SCNAnimationPlayer, forKey key: String?) {
        _animationPlayers[key ?? UUID().uuidString] = player
    }
    public func animationPlayer(forKey key: String) -> SCNAnimationPlayer? { _animationPlayers[key] }
    public func isAnimationPaused(forKey key: String) -> Bool { _animationPlayers[key]?.paused ?? false }
    public func pauseAnimation(forKey key: String) { _animationPlayers[key]?.paused = true }
    public func removeAllAnimations() { _animationPlayers.removeAll() }
    public func removeAllAnimations(withBlendOutDuration duration: CGFloat) {
        _ = duration
        _animationPlayers.removeAll()
    }
    public func removeAnimation(forKey key: String) { _animationPlayers.removeValue(forKey: key) }
    public func removeAnimation(forKey key: String, blendOutDuration duration: CGFloat) {
        _ = duration
        _animationPlayers.removeValue(forKey: key)
    }
    public func removeAnimation(forKey key: String, fadeOutDuration duration: CGFloat) {
        _ = duration
        _animationPlayers.removeValue(forKey: key)
    }
    public func resumeAnimation(forKey key: String) { _animationPlayers[key]?.paused = false }
    public func setAnimationSpeed(_ speed: CGFloat, forKey key: String) { _animationPlayers[key]?.speed = speed }
}
