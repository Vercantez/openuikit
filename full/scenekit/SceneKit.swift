import Foundation

// MARK: - Error domain and keys (string identities are public names)

public let SCNErrorDomain = "SCNErrorDomain"
public let SCNDetailedErrorsKey = "SCNDetailedErrorsKey"
public let SCNConsistencyElementIDErrorKey = "SCNConsistencyElementIDErrorKey"
public let SCNConsistencyElementTypeErrorKey = "SCNConsistencyElementTypeErrorKey"
public let SCNConsistencyLineNumberErrorKey = "SCNConsistencyLineNumberErrorKey"

/// Linux sequential fallbacks. Apple numeric ABI is unobserved.
public let SCNConsistencyInvalidArgumentError: Int = 1001
public let SCNConsistencyInvalidCountError: Int = 1002
public let SCNConsistencyInvalidURIError: Int = 1003
public let SCNConsistencyMissingAttributeError: Int = 1004
public let SCNConsistencyMissingElementError: Int = 1005
public let SCNConsistencyXMLSchemaValidationError: Int = 1006
public let SCNProgramCompilationError: Int = 2001

public let SCNModelTransform = "SCNModelTransform"
public let SCNModelViewTransform = "SCNModelViewTransform"
public let SCNModelViewProjectionTransform = "SCNModelViewProjectionTransform"
public let SCNNormalTransform = "SCNNormalTransform"
public let SCNProjectionTransform = "SCNProjectionTransform"
public let SCNViewTransform = "SCNViewTransform"
public let SCNProgramMappingChannelKey = "SCNProgramMappingChannelKey"
public let SCNSceneExportDestinationURL = "SCNSceneExportDestinationURL"

public let SCNSceneSourceAssetAuthorKey = "SCNSceneSourceAssetAuthorKey"
public let SCNSceneSourceAssetAuthoringToolKey = "SCNSceneSourceAssetAuthoringToolKey"
public let SCNSceneSourceAssetContributorsKey = "SCNSceneSourceAssetContributorsKey"
public let SCNSceneSourceAssetCreatedDateKey = "SCNSceneSourceAssetCreatedDateKey"
public let SCNSceneSourceAssetModifiedDateKey = "SCNSceneSourceAssetModifiedDateKey"
public let SCNSceneSourceAssetUnitKey = "SCNSceneSourceAssetUnitKey"
public let SCNSceneSourceAssetUnitMeterKey = "SCNSceneSourceAssetUnitMeterKey"
public let SCNSceneSourceAssetUnitNameKey = "SCNSceneSourceAssetUnitNameKey"
public let SCNSceneSourceAssetUpAxisKey = "SCNSceneSourceAssetUpAxisKey"

/// Isolated Linux host has no Metal/OpenGL renderer; both compile-time flags are 0.
public let SCN_ENABLE_METAL: Int32 = 0
public let SCN_ENABLE_OPENGL: Int32 = 0

public typealias SCNActionTimingFunction = (Float) -> Float
public typealias SCNQuaternion = SCNVector4
public typealias SCNAnimationDidStartBlock = (SCNAnimation, any SCNAnimatable) -> Void
public typealias SCNAnimationDidStopBlock = (SCNAnimation, any SCNAnimatable, Bool) -> Void
public typealias SCNAnimationEventBlock = (any SCNAnimationProtocol, Any, Bool) -> Void
public typealias SCNBindingBlock = (UInt32, UInt32, SCNNode?, SCNRenderer) -> Void
public typealias SCNBufferBindingBlock = (any SCNBufferStream, SCNNode, any SCNShadable, SCNRenderer) -> Void
public typealias SCNFieldForceEvaluator = (SCNVector3, SCNVector3, Float, Float, TimeInterval) -> SCNVector3
public typealias SCNParticleEventBlock = (
    UnsafeMutablePointer<UnsafeMutableRawPointer>,
    UnsafeMutablePointer<Int>,
    UnsafeMutablePointer<UInt32>?,
    Int
) -> Void
public typealias SCNParticleModifierBlock = (
    UnsafeMutablePointer<UnsafeMutableRawPointer>,
    UnsafeMutablePointer<Int>,
    Int,
    Int,
    Float
) -> Void
public typealias SCNSceneExportProgressHandler = (Float, (any Error)?, UnsafeMutablePointer<ObjCBool>) -> Void
public typealias SCNSceneSourceStatusHandler = (
    Float,
    SCNSceneSourceStatus,
    (any Error)?,
    UnsafeMutablePointer<ObjCBool>
) -> Void

// MARK: - Enums (Apple NS_ENUM sequential values from public headers)

public enum SCNActionTimingMode: Int, Sendable, Hashable {
    case linear = 0
    case easeIn = 1
    case easeOut = 2
    case easeInEaseOut = 3
}

public enum SCNAntialiasingMode: UInt, Sendable, Hashable {
    case none = 0
    case multisampling2X = 1
    case multisampling4X = 2
}

public enum SCNBlendMode: Int, Sendable, Hashable {
    case alpha = 0
    case add = 1
    case subtract = 2
    case multiply = 3
    case screen = 4
    case replace = 5
    case max = 6
}

public enum SCNBufferFrequency: Int, Sendable, Hashable {
    case perFrame = 0
    case perNode = 1
    case perShadable = 2
}

public enum SCNCameraProjectionDirection: Int, Sendable, Hashable {
    case vertical = 0
    case horizontal = 1
}

public enum SCNChamferMode: Int, Sendable, Hashable {
    case both = 0
    case front = 1
    case back = 2
}

public enum SCNCullMode: Int, Sendable, Hashable {
    case back = 0
    case front = 1
}

public enum SCNFillMode: Int, Sendable, Hashable {
    case fill = 0
    case lines = 1
}

public enum SCNFilterMode: Int, Sendable, Hashable {
    case none = 0
    case nearest = 1
    case linear = 2
}

public enum SCNGeometryPrimitiveType: Int, Sendable, Hashable {
    case triangles = 0
    case triangleStrip = 1
    case line = 2
    case point = 3
    case polygon = 4
}

public enum SCNHitTestSearchMode: Int, Sendable, Hashable {
    case closest = 0
    case all = 1
    case any = 2
}

public enum SCNInteractionMode: Int, Sendable, Hashable {
    case fly = 0
    case orbitTurntable = 1
    case orbitAngleMapping = 2
    case orbitCenteredArcball = 3
    case orbitArcball = 4
    case pan = 5
    case truck = 6
}

public enum SCNLightAreaType: Int, Sendable, Hashable {
    case rectangle = 0
    case polygon = 1
}

public enum SCNLightProbeType: Int, Sendable, Hashable {
    case irradiance = 0
    case radiance = 1
}

public enum SCNLightProbeUpdateType: Int, Sendable, Hashable {
    case never = 0
    case realtime = 1
}

public enum SCNMorpherCalculationMode: Int, Sendable, Hashable {
    case normalized = 0
    case additive = 1
}

public enum SCNMovabilityHint: Int, Sendable, Hashable {
    case fixed = 0
    case movable = 1
}

public enum SCNNodeFocusBehavior: Int, Sendable, Hashable {
    case none = 0
    case occluding = 1
    case focusable = 2
}

public enum SCNParticleBirthDirection: Int, Sendable, Hashable {
    case constant = 0
    case surfaceNormal = 1
    case random = 2
}

public enum SCNParticleBirthLocation: Int, Sendable, Hashable {
    case surface = 0
    case volume = 1
    case vertex = 2
}

public enum SCNParticleBlendMode: Int, Sendable, Hashable {
    case additive = 0
    case subtract = 1
    case multiply = 2
    case screen = 3
    case alpha = 4
    case replace = 5
}

public enum SCNParticleEvent: Int, Sendable, Hashable {
    case birth = 0
    case death = 1
    case collision = 2
}

public enum SCNParticleImageSequenceAnimationMode: Int, Sendable, Hashable {
    case `repeat` = 0
    case clamp = 1
    case autoReverse = 2
}

public enum SCNParticleInputMode: Int, Sendable, Hashable {
    case overLife = 0
    case overDistance = 1
    case overOtherProperty = 2
}

public enum SCNParticleModifierStage: Int, Sendable, Hashable {
    case preDynamics = 0
    case postDynamics = 1
    case preCollision = 2
    case postCollision = 3
}

public enum SCNParticleOrientationMode: Int, Sendable, Hashable {
    case billboardScreenAligned = 0
    case billboardViewAligned = 1
    case free = 2
    case billboardYAligned = 3
}

public enum SCNParticleSortingMode: Int, Sendable, Hashable {
    case none = 0
    case projectedDepth = 1
    case distance = 2
    case oldestFirst = 3
    case youngestFirst = 4
}

public enum SCNPhysicsBodyType: Int, Sendable, Hashable {
    case `static` = 0
    case dynamic = 1
    case kinematic = 2
}

public enum SCNPhysicsFieldScope: Int, Sendable, Hashable {
    case insideExtent = 0
    case outsideExtent = 1
}

public enum SCNReferenceLoadingPolicy: Int, Sendable, Hashable {
    case immediate = 0
    case onDemand = 1
}

public enum SCNRenderingAPI: UInt, Sendable, Hashable {
    case metal = 0
    case openGLES2 = 1
}

public enum SCNSceneSourceStatus: Int, Sendable, Hashable {
    case error = 0
    case parsing = 1
    case validating = 2
    case processing = 3
    case complete = 4
}

public enum SCNShadowMode: Int, Sendable, Hashable {
    case forward = 0
    case deferred = 1
    case modulated = 2
}

public enum SCNTessellationSmoothingMode: Int, Sendable, Hashable {
    case none = 0
    case pnTriangles = 1
    case phong = 2
}

public enum SCNTransparencyMode: Int, Sendable, Hashable {
    case aOne = 0
    case rgbZero = 1
    case singleLayer = 2
    case dualLayer = 3

    public static var `default`: SCNTransparencyMode { .aOne }
}

public enum SCNWrapMode: Int, Sendable, Hashable {
    case clamp = 0
    case `repeat` = 1
    case clampToBorder = 2
    case mirror = 3
}

// MARK: - Option sets

public struct SCNBillboardAxis: OptionSet, Sendable, Hashable {
    public let rawValue: UInt

    public init(rawValue: UInt) {
        self.rawValue = rawValue
    }

    public static let X = SCNBillboardAxis(rawValue: 1 << 0)
    public static let Y = SCNBillboardAxis(rawValue: 1 << 1)
    public static let Z = SCNBillboardAxis(rawValue: 1 << 2)
    public static let all: SCNBillboardAxis = [.X, .Y, .Z]
}

/// Color-mask bits are Linux-local placeholders. Apple raw values are unobserved
/// (see oracle-questions.tsv); do not treat these as Darwin ABI.
public struct SCNColorMask: OptionSet, Sendable, Hashable {
    public let rawValue: Int

    public init(rawValue: Int) {
        self.rawValue = rawValue
    }

    public static let alpha = SCNColorMask(rawValue: 1 << 0)
    public static let blue = SCNColorMask(rawValue: 1 << 1)
    public static let green = SCNColorMask(rawValue: 1 << 2)
    public static let red = SCNColorMask(rawValue: 1 << 3)
    public static let all: SCNColorMask = [.red, .green, .blue, .alpha]
}

public struct SCNDebugOptions: OptionSet, Sendable, Hashable {
    public let rawValue: Int

    public init(rawValue: Int) {
        self.rawValue = rawValue
    }

    public static let showPhysicsShapes = SCNDebugOptions(rawValue: 1 << 0)
    public static let showBoundingBoxes = SCNDebugOptions(rawValue: 1 << 1)
    public static let showLightInfluences = SCNDebugOptions(rawValue: 1 << 2)
    public static let showLightExtents = SCNDebugOptions(rawValue: 1 << 3)
    public static let showPhysicsFields = SCNDebugOptions(rawValue: 1 << 4)
    public static let showWireframe = SCNDebugOptions(rawValue: 1 << 5)
    public static let renderAsWireframe = SCNDebugOptions(rawValue: 1 << 6)
    public static let showSkeletons = SCNDebugOptions(rawValue: 1 << 7)
    public static let showCreases = SCNDebugOptions(rawValue: 1 << 8)
    public static let showConstraints = SCNDebugOptions(rawValue: 1 << 9)
    public static let showCameras = SCNDebugOptions(rawValue: 1 << 10)
}

public struct SCNPhysicsCollisionCategory: OptionSet, Sendable, Hashable {
    public let rawValue: Int

    public init(rawValue: Int) {
        self.rawValue = rawValue
    }

    public static let `default` = SCNPhysicsCollisionCategory(rawValue: 1 << 0)
    public static let `static` = SCNPhysicsCollisionCategory(rawValue: 1 << 1)
    public static let all = SCNPhysicsCollisionCategory(rawValue: .max)
}

public struct SCNHitTestOption: RawRepresentable, Hashable, Sendable {
    public var rawValue: String

    public init(rawValue: String) {
        self.rawValue = rawValue
    }

    public static let backFaceCulling = SCNHitTestOption(rawValue: "SCNHitTestBackFaceCullingKey")
    public static let boundingBoxOnly = SCNHitTestOption(rawValue: "SCNHitTestBoundingBoxOnlyKey")
    public static let clipToZRange = SCNHitTestOption(rawValue: "SCNHitTestClipToZRangeKey")
    public static let firstFoundOnly = SCNHitTestOption(rawValue: "SCNHitTestFirstFoundOnlyKey")
    public static let ignoreChildNodes = SCNHitTestOption(rawValue: "SCNHitTestIgnoreChildNodesKey")
    public static let ignoreHiddenNodes = SCNHitTestOption(rawValue: "SCNHitTestIgnoreHiddenNodesKey")
    public static let categoryBitMask = SCNHitTestOption(rawValue: "SCNHitTestOptionCategoryBitMask")
    public static let ignoreLightArea = SCNHitTestOption(rawValue: "SCNHitTestOptionIgnoreLightArea")
    public static let searchMode = SCNHitTestOption(rawValue: "SCNHitTestOptionSearchMode")
    public static let rootNode = SCNHitTestOption(rawValue: "SCNHitTestRootNodeKey")
    public static let sortResults = SCNHitTestOption(rawValue: "SCNHitTestSortResultsKey")
}

public struct SCNShaderModifierEntryPoint: RawRepresentable, Hashable, Sendable {
    public var rawValue: String

    public init(rawValue: String) {
        self.rawValue = rawValue
    }

    public static let geometry = SCNShaderModifierEntryPoint(rawValue: "SCNShaderModifierEntryPointGeometry")
    public static let surface = SCNShaderModifierEntryPoint(rawValue: "SCNShaderModifierEntryPointSurface")
    public static let lightingModel = SCNShaderModifierEntryPoint(rawValue: "SCNShaderModifierEntryPointLightingModel")
    public static let fragment = SCNShaderModifierEntryPoint(rawValue: "SCNShaderModifierEntryPointFragment")
}

public protocol SCNActionable: NSObjectProtocol {
    var hasActions: Bool { get }
    var actionKeys: [String] { get }
    func action(forKey key: String) -> SCNAction?
    func removeAction(forKey key: String)
    func removeAllActions()
    func runAction(_ action: SCNAction)
    func runAction(_ action: SCNAction) async
    func runAction(_ action: SCNAction, forKey key: String?)
    func runAction(_ action: SCNAction, forKey key: String?) async
}

public protocol SCNAnimatable: NSObjectProtocol {
    var animationKeys: [String] { get }
    func addAnimation(_ animation: any SCNAnimationProtocol, forKey key: String?)
    func addAnimationPlayer(_ player: SCNAnimationPlayer, forKey key: String?)
    func animationPlayer(forKey key: String) -> SCNAnimationPlayer?
    func removeAllAnimations()
    func removeAllAnimations(withBlendOutDuration duration: CGFloat)
    func removeAnimation(forKey key: String)
    func removeAnimation(forKey key: String, blendOutDuration duration: CGFloat)
    func removeAnimation(forKey key: String, fadeOutDuration duration: CGFloat)
    func isAnimationPaused(forKey key: String) -> Bool
    func pauseAnimation(forKey key: String)
    func resumeAnimation(forKey key: String)
    func setAnimationSpeed(_ speed: CGFloat, forKey key: String)
}

public protocol SCNAnimationProtocol: NSObjectProtocol {}

public protocol SCNBufferStream: NSObjectProtocol {
    func writeBytes(_ bytes: UnsafeRawPointer, count: Int)
}

public protocol SCNBoundingVolume: NSObjectProtocol {
    var boundingBox: (min: SCNVector3, max: SCNVector3) { get set }
    var boundingSphere: (center: SCNVector3, radius: Float) { get }
}

public protocol SCNShadable: NSObjectProtocol {
    var program: SCNProgram? { get set }
    var shaderModifiers: [SCNShaderModifierEntryPoint: String]? { get set }
    var minimumLanguageVersion: NSNumber? { get set }
    func handleBinding(ofSymbol symbol: String, handler block: SCNBindingBlock?)
    func handleUnbinding(ofSymbol symbol: String, handler block: SCNBindingBlock?)
}

public protocol SCNTechniqueSupport: NSObjectProtocol {
    var technique: SCNTechnique? { get set }
}

public protocol SCNProgramDelegate: NSObjectProtocol {}
public protocol SCNPhysicsContactDelegate: NSObjectProtocol {}
public protocol SCNSceneExportDelegate: NSObjectProtocol {}
public protocol SCNSceneRendererDelegate: NSObjectProtocol {}
public protocol SCNNodeRendererDelegate: NSObjectProtocol {}
public protocol SCNCameraControllerDelegate: NSObjectProtocol {
    func cameraInertiaDidEnd(for cameraController: SCNCameraController)
    func cameraInertiaWillStart(for cameraController: SCNCameraController)
}
public protocol SCNAvoidOccluderConstraintDelegate: NSObjectProtocol {
    func avoidOccluderConstraint(_ constraint: SCNAvoidOccluderConstraint, didAvoidOccluder occluder: SCNNode, for node: SCNNode)
    func avoidOccluderConstraint(_ constraint: SCNAvoidOccluderConstraint, shouldAvoidOccluder occluder: SCNNode, for node: SCNNode) -> Bool
}
public protocol SCNCameraControlConfiguration: NSObjectProtocol {}
