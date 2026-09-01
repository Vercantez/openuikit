import Foundation

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
}

public enum SCNWrapMode: Int, Sendable, Hashable {
    case clamp = 1
    case `repeat` = 2
    case clampToBorder = 3
    case mirror = 4
}

public struct SCNBillboardAxis: OptionSet, Hashable, Sendable {
    public let rawValue: UInt

    public init(rawValue: UInt) {
        self.rawValue = rawValue
    }

    public static let X = SCNBillboardAxis(rawValue: 1 << 0)
    public static let Y = SCNBillboardAxis(rawValue: 1 << 1)
    public static let Z = SCNBillboardAxis(rawValue: 1 << 2)
    public static let all: SCNBillboardAxis = [.X, .Y, .Z]
}

/// Color-channel mask cases compile, but the raw bit positions are not
/// oracle-attested. Do not treat these values as ABI-stable.
public struct SCNColorMask: OptionSet, Hashable, Sendable {
    public let rawValue: Int

    public init(rawValue: Int) {
        self.rawValue = rawValue
    }

    public static let red = SCNColorMask(rawValue: 1 << 3)
    public static let green = SCNColorMask(rawValue: 1 << 2)
    public static let blue = SCNColorMask(rawValue: 1 << 1)
    public static let alpha = SCNColorMask(rawValue: 1 << 0)
    public static let all: SCNColorMask = [.red, .green, .blue, .alpha]
}

public struct SCNDebugOptions: OptionSet, Hashable, Sendable {
    public let rawValue: UInt

    public init(rawValue: UInt) {
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

public struct SCNPhysicsCollisionCategory: OptionSet, Hashable, Sendable {
    public let rawValue: UInt

    public init(rawValue: UInt) {
        self.rawValue = rawValue
    }

    public static let `default` = SCNPhysicsCollisionCategory(rawValue: 1 << 0)
    public static let `static` = SCNPhysicsCollisionCategory(rawValue: 1 << 1)
    public static let all = SCNPhysicsCollisionCategory(rawValue: UInt.max)
}

public struct SCNHitTestOption: RawRepresentable, Hashable, Sendable {
    public let rawValue: String
    public init(rawValue: String) { self.rawValue = rawValue }

    public static let backFaceCulling = SCNHitTestOption(rawValue: "backFaceCulling")
    public static let boundingBoxOnly = SCNHitTestOption(rawValue: "boundingBoxOnly")
    public static let clipToZRange = SCNHitTestOption(rawValue: "clipToZRange")
    public static let firstFoundOnly = SCNHitTestOption(rawValue: "firstFoundOnly")
    public static let ignoreChildNodes = SCNHitTestOption(rawValue: "ignoreChildNodes")
    public static let ignoreHiddenNodes = SCNHitTestOption(rawValue: "ignoreHiddenNodes")
    public static let categoryBitMask = SCNHitTestOption(rawValue: "categoryBitMask")
    public static let ignoreLightArea = SCNHitTestOption(rawValue: "ignoreLightArea")
    public static let searchMode = SCNHitTestOption(rawValue: "searchMode")
    public static let rootNode = SCNHitTestOption(rawValue: "rootNode")
    public static let sortResults = SCNHitTestOption(rawValue: "sortResults")
}

public struct SCNShaderModifierEntryPoint: RawRepresentable, Hashable, Sendable {
    public let rawValue: String
    public init(rawValue: String) { self.rawValue = rawValue }

    public static let geometry = SCNShaderModifierEntryPoint(rawValue: "geometry")
    public static let surface = SCNShaderModifierEntryPoint(rawValue: "surface")
    public static let lightingModel = SCNShaderModifierEntryPoint(rawValue: "lightingModel")
    public static let fragment = SCNShaderModifierEntryPoint(rawValue: "fragment")
}
