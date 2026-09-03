import Foundation

open class SCNMaterialProperty: NSObject, NSSecureCoding {
    public var contents: Any?
    public var contentsTransform: SCNMatrix4
    public var intensity: CGFloat
    public var magnificationFilter: SCNFilterMode
    public var minificationFilter: SCNFilterMode
    public var mipFilter: SCNFilterMode
    public var wrapS: SCNWrapMode
    public var wrapT: SCNWrapMode
    public var mappingChannel: Int
    public var maxAnisotropy: CGFloat
    public var borderColor: Any?
    public var textureComponents: SCNColorMask

    public override init() {
        contentsTransform = SCNMatrix4Identity
        intensity = 1
        magnificationFilter = .linear
        minificationFilter = .linear
        mipFilter = .nearest
        wrapS = .clamp
        wrapT = .clamp
        mappingChannel = 0
        maxAnisotropy = 1
        textureComponents = .all
        super.init()
    }

    public convenience init(contents: Any) {
        self.init()
        self.contents = contents
    }

    public static var supportsSecureCoding: Bool { true }
    public required init?(coder: NSCoder) { return nil }
    public func encode(with coder: NSCoder) {}

    public class func precomputedLightingEnvironmentContents(with data: Data) throws -> Any {
        _ = data
        throw NSError(domain: SCNErrorDomain, code: -1, userInfo: [
            NSLocalizedDescriptionKey: "precomputed lighting environments are unavailable"
        ])
    }

    public class func precomputedLightingEnvironmentContents(with url: URL) throws -> Any {
        _ = url
        throw NSError(domain: SCNErrorDomain, code: -1, userInfo: [
            NSLocalizedDescriptionKey: "precomputed lighting environments are unavailable"
        ])
    }
}

open class SCNMaterial: NSObject, NSCopying, NSSecureCoding, SCNAnimatable, SCNShadable {
    public struct LightingModel: RawRepresentable, Hashable, Sendable {
        public var rawValue: String
        public init(rawValue: String) { self.rawValue = rawValue }
        public static let phong = LightingModel(rawValue: "phong")
        public static let blinn = LightingModel(rawValue: "blinn")
        public static let lambert = LightingModel(rawValue: "lambert")
        public static let constant = LightingModel(rawValue: "constant")
        public static let physicallyBased = LightingModel(rawValue: "physicallyBased")
        public static let shadowOnly = LightingModel(rawValue: "shadowOnly")
    }

    public var name: String?
    public var lightingModel: LightingModel
    public var blendMode: SCNBlendMode
    public var transparencyMode: SCNTransparencyMode
    public var fillsModeStorage: SCNFillMode
    public var cullMode: SCNCullMode
    public var isDoubleSided: Bool
    public var isLitPerPixel: Bool
    public var locksAmbientWithDiffuse: Bool
    public var readsFromDepthBuffer: Bool
    public var writesToDepthBuffer: Bool
    public var shininess: CGFloat
    public var transparency: CGFloat
    public var fresnelExponent: CGFloat
    public var colorBufferWriteMask: SCNColorMask
    public let diffuse: SCNMaterialProperty
    public let ambient: SCNMaterialProperty
    public let specular: SCNMaterialProperty
    public let emission: SCNMaterialProperty
    public let transparent: SCNMaterialProperty
    public let reflective: SCNMaterialProperty
    public let multiply: SCNMaterialProperty
    public let normal: SCNMaterialProperty
    public let displacement: SCNMaterialProperty
    public let ambientOcclusion: SCNMaterialProperty
    public let selfIllumination: SCNMaterialProperty
    public let metalness: SCNMaterialProperty
    public let roughness: SCNMaterialProperty
    public let clearCoat: SCNMaterialProperty
    public let clearCoatRoughness: SCNMaterialProperty
    public let clearCoatNormal: SCNMaterialProperty
    public var program: SCNProgram?
    public var shaderModifiers: [SCNShaderModifierEntryPoint: String]?
    public var minimumLanguageVersion: NSNumber?
    var _animationPlayers: [String: SCNAnimationPlayer] = [:]

    public var fillMode: SCNFillMode {
        get { fillsModeStorage }
        set { fillsModeStorage = newValue }
    }

    public override init() {
        lightingModel = .blinn
        blendMode = .alpha
        transparencyMode = .default
        fillsModeStorage = .fill
        cullMode = .back
        isDoubleSided = false
        isLitPerPixel = true
        locksAmbientWithDiffuse = true
        readsFromDepthBuffer = true
        writesToDepthBuffer = true
        shininess = 1
        transparency = 1
        fresnelExponent = 0
        colorBufferWriteMask = .all
        diffuse = SCNMaterialProperty()
        ambient = SCNMaterialProperty()
        specular = SCNMaterialProperty()
        emission = SCNMaterialProperty()
        transparent = SCNMaterialProperty()
        reflective = SCNMaterialProperty()
        multiply = SCNMaterialProperty()
        normal = SCNMaterialProperty()
        displacement = SCNMaterialProperty()
        ambientOcclusion = SCNMaterialProperty()
        selfIllumination = SCNMaterialProperty()
        metalness = SCNMaterialProperty()
        roughness = SCNMaterialProperty()
        clearCoat = SCNMaterialProperty()
        clearCoatRoughness = SCNMaterialProperty()
        clearCoatNormal = SCNMaterialProperty()
        super.init()
    }

    public func handleBinding(ofSymbol symbol: String, handler block: SCNBindingBlock?) {}
    public func handleUnbinding(ofSymbol symbol: String, handler block: SCNBindingBlock?) {}

    public func copy(with zone: NSZone? = nil) -> Any {
        let copy = SCNMaterial()
        copy.name = name
        copy.lightingModel = lightingModel
        copy.diffuse.contents = diffuse.contents
        copy.transparency = transparency
        return copy
    }

    public var animationKeys: [String] { Array(_animationPlayers.keys) }
    public func addAnimation(_ animation: any SCNAnimationProtocol, forKey key: String?) {
        addAnimationPlayer(SCNAnimationPlayer(animation: animation as? SCNAnimation ?? SCNAnimation()), forKey: key)
    }
    public func addAnimationPlayer(_ player: SCNAnimationPlayer, forKey key: String?) {
        _animationPlayers[key ?? UUID().uuidString] = player
    }
    public func animationPlayer(forKey key: String) -> SCNAnimationPlayer? { _animationPlayers[key] }
    public func removeAllAnimations() { _animationPlayers.removeAll() }
    public func removeAllAnimations(withBlendOutDuration duration: CGFloat) { _animationPlayers.removeAll() }
    public func removeAnimation(forKey key: String) { _animationPlayers.removeValue(forKey: key) }
    public func removeAnimation(forKey key: String, blendOutDuration duration: CGFloat) { _animationPlayers.removeValue(forKey: key) }
    public func removeAnimation(forKey key: String, fadeOutDuration duration: CGFloat) { _animationPlayers.removeValue(forKey: key) }
    public func isAnimationPaused(forKey key: String) -> Bool { _animationPlayers[key]?.paused ?? false }
    public func pauseAnimation(forKey key: String) { _animationPlayers[key]?.paused = true }
    public func resumeAnimation(forKey key: String) { _animationPlayers[key]?.paused = false }
    public func setAnimationSpeed(_ speed: CGFloat, forKey key: String) { _animationPlayers[key]?.speed = speed }

    public static var supportsSecureCoding: Bool { true }
    public required init?(coder: NSCoder) { return nil }
    public func encode(with coder: NSCoder) {}
}

open class SCNLight: NSObject, NSCopying, NSSecureCoding, SCNAnimatable {
    public struct LightType: RawRepresentable, Hashable, Sendable {
        public var rawValue: String
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
    public var type: LightType
    public var color: Any
    public var intensity: CGFloat
    public var temperature: CGFloat
    public var categoryBitMask: Int
    public var castsShadow: Bool
    public var shadowRadius: CGFloat
    public var shadowColor: Any
    public var shadowMapSize: CGSize
    public var shadowSampleCount: Int
    public var shadowMode: SCNShadowMode
    public var shadowBias: CGFloat
    public var automaticallyAdjustsShadowProjection: Bool
    public var maximumShadowDistance: CGFloat
    public var forcesBackFaceCasters: Bool
    public var sampleDistributedShadowMaps: Bool
    public var shadowCascadeCount: Int
    public var shadowCascadeSplittingFactor: CGFloat
    public var orthographicScale: CGFloat
    public var zNear: CGFloat
    public var zFar: CGFloat
    public var attenuationStartDistance: CGFloat
    public var attenuationEndDistance: CGFloat
    public var attenuationFalloffExponent: CGFloat
    public var spotInnerAngle: CGFloat
    public var spotOuterAngle: CGFloat
    public var gobo: SCNMaterialProperty?
    public var iesProfileURL: URL?
    public var areaType: SCNLightAreaType
    public var doubleSided: Bool
    public var drawsArea: Bool
    public var probeType: SCNLightProbeType
    public var probeUpdateType: SCNLightProbeUpdateType
    public var parallaxCorrectionEnabled: Bool
    public var probeEnvironment: SCNMaterialProperty?
    public var areaPolygonVertices: [NSValue]?
    public var sphericalHarmonicsCoefficients: Data
    var _animationPlayers: [String: SCNAnimationPlayer] = [:]

    public override init() {
        type = .omni
        color = SCNVector3(x: 1, y: 1, z: 1)
        intensity = 1000
        temperature = 6500
        categoryBitMask = 1
        castsShadow = false
        shadowRadius = 3
        shadowColor = SCNVector4(x: 0, y: 0, z: 0, w: 1)
        shadowMapSize = CGSize(width: 1024, height: 1024)
        shadowSampleCount = 0
        shadowMode = .forward
        shadowBias = 1
        automaticallyAdjustsShadowProjection = true
        maximumShadowDistance = 100
        forcesBackFaceCasters = false
        sampleDistributedShadowMaps = false
        shadowCascadeCount = 1
        shadowCascadeSplittingFactor = 0.15
        orthographicScale = 1
        zNear = 1
        zFar = 100
        attenuationStartDistance = 0
        attenuationEndDistance = 0
        attenuationFalloffExponent = 2
        spotInnerAngle = 0
        spotOuterAngle = 45
        areaType = .rectangle
        doubleSided = false
        drawsArea = false
        probeType = .irradiance
        probeUpdateType = .never
        parallaxCorrectionEnabled = false
        sphericalHarmonicsCoefficients = Data()
        super.init()
        gobo = SCNMaterialProperty()
        probeEnvironment = SCNMaterialProperty()
    }

    public func copy(with zone: NSZone? = nil) -> Any {
        let copy = SCNLight()
        copy.type = type
        copy.intensity = intensity
        copy.color = color
        return copy
    }

    public var animationKeys: [String] { Array(_animationPlayers.keys) }
    public func addAnimation(_ animation: any SCNAnimationProtocol, forKey key: String?) {
        addAnimationPlayer(SCNAnimationPlayer(animation: animation as? SCNAnimation ?? SCNAnimation()), forKey: key)
    }
    public func addAnimationPlayer(_ player: SCNAnimationPlayer, forKey key: String?) {
        _animationPlayers[key ?? UUID().uuidString] = player
    }
    public func animationPlayer(forKey key: String) -> SCNAnimationPlayer? { _animationPlayers[key] }
    public func removeAllAnimations() { _animationPlayers.removeAll() }
    public func removeAllAnimations(withBlendOutDuration duration: CGFloat) { _animationPlayers.removeAll() }
    public func removeAnimation(forKey key: String) { _animationPlayers.removeValue(forKey: key) }
    public func removeAnimation(forKey key: String, blendOutDuration duration: CGFloat) { _animationPlayers.removeValue(forKey: key) }
    public func removeAnimation(forKey key: String, fadeOutDuration duration: CGFloat) { _animationPlayers.removeValue(forKey: key) }
    public func isAnimationPaused(forKey key: String) -> Bool { _animationPlayers[key]?.paused ?? false }
    public func pauseAnimation(forKey key: String) { _animationPlayers[key]?.paused = true }
    public func resumeAnimation(forKey key: String) { _animationPlayers[key]?.paused = false }
    public func setAnimationSpeed(_ speed: CGFloat, forKey key: String) { _animationPlayers[key]?.speed = speed }

    public static var supportsSecureCoding: Bool { true }
    public required init?(coder: NSCoder) { return nil }
    public func encode(with coder: NSCoder) {}
}

open class SCNCamera: NSObject, NSCopying, NSSecureCoding, SCNAnimatable, SCNTechniqueSupport {
    public var name: String?
    public var fieldOfView: CGFloat
    public var focalLength: CGFloat
    public var sensorHeight: CGFloat
    public var zNear: Double
    public var zFar: Double
    public var automaticallyAdjustsZRange: Bool
    public var usesOrthographicProjection: Bool
    public var orthographicScale: Double
    public var projectionDirection: SCNCameraProjectionDirection
    public var projectionTransform: SCNMatrix4
    public var categoryBitMask: Int
    public var wantsHDR: Bool
    public var wantsExposureAdaptation: Bool
    public var exposureOffset: CGFloat
    public var averageGray: CGFloat
    public var whitePoint: CGFloat
    public var minimumExposure: CGFloat
    public var maximumExposure: CGFloat
    public var exposureAdaptationBrighteningSpeedFactor: CGFloat
    public var exposureAdaptationDarkeningSpeedFactor: CGFloat
    public var contrast: CGFloat
    public var saturation: CGFloat
    public var colorGrading: SCNMaterialProperty
    public var bloomIntensity: CGFloat
    public var bloomThreshold: CGFloat
    public var bloomBlurRadius: CGFloat
    public var bloomIterationCount: Int
    public var bloomIterationSpread: CGFloat
    public var vignettingIntensity: CGFloat
    public var vignettingPower: CGFloat
    public var colorFringeIntensity: CGFloat
    public var colorFringeStrength: CGFloat
    public var motionBlurIntensity: CGFloat
    public var wantsDepthOfField: Bool
    public var focusDistance: CGFloat
    public var focalDistance: CGFloat
    public var focalSize: CGFloat
    public var focalBlurRadius: CGFloat
    public var focalBlurSampleCount: Int
    public var aperture: CGFloat
    public var apertureBladeCount: Int
    public var fStop: CGFloat
    public var screenSpaceAmbientOcclusionIntensity: CGFloat
    public var screenSpaceAmbientOcclusionRadius: CGFloat
    public var screenSpaceAmbientOcclusionBias: CGFloat
    public var screenSpaceAmbientOcclusionDepthThreshold: CGFloat
    public var screenSpaceAmbientOcclusionNormalThreshold: CGFloat
    public var grainIntensity: CGFloat
    public var grainScale: CGFloat
    public var grainIsColored: Bool
    public var whiteBalanceTemperature: CGFloat
    public var whiteBalanceTint: CGFloat
    public var xFov: Double
    public var yFov: Double
    public var technique: SCNTechnique?
    var _animationPlayers: [String: SCNAnimationPlayer] = [:]

    public override init() {
        fieldOfView = 60
        focalLength = 50
        sensorHeight = 24
        zNear = 1
        zFar = 100
        automaticallyAdjustsZRange = false
        usesOrthographicProjection = false
        orthographicScale = 1
        projectionDirection = .vertical
        projectionTransform = SCNMatrix4Identity
        categoryBitMask = 1
        wantsHDR = false
        wantsExposureAdaptation = false
        exposureOffset = 0
        averageGray = 0.18
        whitePoint = 1
        minimumExposure = -15
        maximumExposure = 15
        exposureAdaptationBrighteningSpeedFactor = 0.4
        exposureAdaptationDarkeningSpeedFactor = 0.6
        contrast = 0
        saturation = 0
        colorGrading = SCNMaterialProperty()
        bloomIntensity = 0
        bloomThreshold = 1
        bloomBlurRadius = 3
        bloomIterationCount = 1
        bloomIterationSpread = 0
        vignettingIntensity = 0
        vignettingPower = 1
        colorFringeIntensity = 1
        colorFringeStrength = 0
        motionBlurIntensity = 0
        wantsDepthOfField = false
        focusDistance = 2.5
        focalDistance = 10
        focalSize = 0
        focalBlurRadius = 0
        focalBlurSampleCount = 0
        aperture = 0.125
        apertureBladeCount = 6
        fStop = 5.6
        screenSpaceAmbientOcclusionIntensity = 0
        screenSpaceAmbientOcclusionRadius = 5
        screenSpaceAmbientOcclusionBias = 0.03
        screenSpaceAmbientOcclusionDepthThreshold = 0.2
        screenSpaceAmbientOcclusionNormalThreshold = 0.3
        grainIntensity = 0
        grainScale = 1
        grainIsColored = false
        whiteBalanceTemperature = 0
        whiteBalanceTint = 0
        xFov = 0
        yFov = 0
        super.init()
    }

    /// Linux CPU helper. Convention (OpenGL-style, vertical FOV) is unoracle'd;
    /// coverage marks projection-matrix rows declared, not Apple-identical.
    public func projectionTransform(withViewportSize viewportSize: CGSize) -> SCNMatrix4 {
        if usesOrthographicProjection {
            let w = Float(orthographicScale)
            let h: Float
            if viewportSize.width > 0 {
                h = w * Float(viewportSize.height / viewportSize.width)
            } else {
                h = w
            }
            var m = SCNMatrix4Identity
            m.m11 = w == 0 ? 1 : 1 / w
            m.m22 = h == 0 ? 1 : 1 / h
            let zn = Float(zNear)
            let zf = Float(zFar)
            m.m33 = (zf - zn) == 0 ? 1 : -2 / (zf - zn)
            m.m43 = -((zf + zn) / max(zf - zn, 0.0001))
            return m
        }
        return projectionTransform
    }

    public func copy(with zone: NSZone? = nil) -> Any {
        let copy = SCNCamera()
        copy.fieldOfView = fieldOfView
        copy.zNear = zNear
        copy.zFar = zFar
        copy.usesOrthographicProjection = usesOrthographicProjection
        return copy
    }

    public var animationKeys: [String] { Array(_animationPlayers.keys) }
    public func addAnimation(_ animation: any SCNAnimationProtocol, forKey key: String?) {
        addAnimationPlayer(SCNAnimationPlayer(animation: animation as? SCNAnimation ?? SCNAnimation()), forKey: key)
    }
    public func addAnimationPlayer(_ player: SCNAnimationPlayer, forKey key: String?) {
        _animationPlayers[key ?? UUID().uuidString] = player
    }
    public func animationPlayer(forKey key: String) -> SCNAnimationPlayer? { _animationPlayers[key] }
    public func removeAllAnimations() { _animationPlayers.removeAll() }
    public func removeAllAnimations(withBlendOutDuration duration: CGFloat) { _animationPlayers.removeAll() }
    public func removeAnimation(forKey key: String) { _animationPlayers.removeValue(forKey: key) }
    public func removeAnimation(forKey key: String, blendOutDuration duration: CGFloat) { _animationPlayers.removeValue(forKey: key) }
    public func removeAnimation(forKey key: String, fadeOutDuration duration: CGFloat) { _animationPlayers.removeValue(forKey: key) }
    public func isAnimationPaused(forKey key: String) -> Bool { _animationPlayers[key]?.paused ?? false }
    public func pauseAnimation(forKey key: String) { _animationPlayers[key]?.paused = true }
    public func resumeAnimation(forKey key: String) { _animationPlayers[key]?.paused = false }
    public func setAnimationSpeed(_ speed: CGFloat, forKey key: String) { _animationPlayers[key]?.speed = speed }

    public static var supportsSecureCoding: Bool { true }
    public required init?(coder: NSCoder) { return nil }
    public func encode(with coder: NSCoder) {}
}
