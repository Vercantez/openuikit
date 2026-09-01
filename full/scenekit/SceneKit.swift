import Foundation
import Dispatch

/// Portable SceneKit starting point for Linux. The scene graph, transforms,
/// primitive geometry, materials, actions, and camera math are real CPU
/// behavior. GPU rendering, Metal, physics simulation, asset decoding, and
/// SwiftUI `SceneView` remain fail-closed.

public typealias SCNFloat = Float
public typealias SCNQuaternion = SCNVector4
public typealias SCNActionTimingFunction = (Float) -> Float
public typealias SCNAnimationDidStartBlock = (SCNAnimation, any SCNAnimatable) -> Void
public typealias SCNAnimationDidStopBlock = (SCNAnimation, any SCNAnimatable, Bool) -> Void
public typealias SCNAnimationEventBlock = (any SCNAnimationProtocol, Any, Bool) -> Void
public typealias SCNFieldForceEvaluator = (SCNVector3, SCNVector3, Float, Float, TimeInterval) -> SCNVector3
public typealias SCNSceneExportProgressHandler = (Float, (any Error)?, UnsafeMutablePointer<ObjCBool>) -> Void
public typealias SCNSceneSourceStatusHandler = (Float, SCNSceneSourceStatus, (any Error)?, UnsafeMutablePointer<ObjCBool>) -> Void
public typealias dispatch_queue_t = DispatchQueue

/// Linux stand-ins for the Darwin `simd` module names used by SceneKit.
public typealias simd_float3 = SIMD3<Float>
public typealias simd_float4 = SIMD4<Float>

public struct simd_quatf: Equatable, Sendable {
    public var vector: SIMD4<Float>

    public init(_ vector: SIMD4<Float>) {
        self.vector = vector
    }

    public init(ix: Float, iy: Float, iz: Float, r: Float) {
        vector = SIMD4(ix, iy, iz, r)
    }

    public static var identity: simd_quatf {
        simd_quatf(ix: 0, iy: 0, iz: 0, r: 1)
    }
}

public struct simd_float4x4: Equatable, Sendable {
    public var columns: (SIMD4<Float>, SIMD4<Float>, SIMD4<Float>, SIMD4<Float>)

    public init(columns: (SIMD4<Float>, SIMD4<Float>, SIMD4<Float>, SIMD4<Float>)) {
        self.columns = columns
    }

    public static var identity: simd_float4x4 {
        simd_float4x4(
            columns: (
                SIMD4(1, 0, 0, 0),
                SIMD4(0, 1, 0, 0),
                SIMD4(0, 0, 1, 0),
                SIMD4(0, 0, 0, 1)
            )
        )
    }

    public static func == (lhs: simd_float4x4, rhs: simd_float4x4) -> Bool {
        lhs.columns.0 == rhs.columns.0
            && lhs.columns.1 == rhs.columns.1
            && lhs.columns.2 == rhs.columns.2
            && lhs.columns.3 == rhs.columns.3
    }
}

public let SCNErrorDomain = "com.apple.scenekit.error"
public let SCNDetailedErrorsKey = "SCNDetailedErrorsKey"
public let SCNConsistencyElementIDErrorKey = "SCNConsistencyElementIDErrorKey"
public let SCNConsistencyElementTypeErrorKey = "SCNConsistencyElementTypeErrorKey"
public let SCNConsistencyLineNumberErrorKey = "SCNConsistencyLineNumberErrorKey"

public let SCNConsistencyInvalidArgumentError = 1
public let SCNConsistencyInvalidCountError = 2
public let SCNConsistencyInvalidURIError = 3
public let SCNConsistencyMissingAttributeError = 4
public let SCNConsistencyMissingElementError = 5
public let SCNConsistencyXMLSchemaValidationError = 6
public let SCNProgramCompilationError = 7

public let SCNModelTransform = "SCNModelTransform"
public let SCNViewTransform = "SCNViewTransform"
public let SCNProjectionTransform = "SCNProjectionTransform"
public let SCNNormalTransform = "SCNNormalTransform"
public let SCNModelViewTransform = "SCNModelViewTransform"
public let SCNModelViewProjectionTransform = "SCNModelViewProjectionTransform"
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

public let SCN_ENABLE_METAL: Int32 = 0
public let SCN_ENABLE_OPENGL: Int32 = 0

public enum SCNSceneIOError: Error, Equatable, Sendable {
    case unavailableOnLinux
    case exportUnsupported
    case missingAsset
}

public protocol SCNBoundingVolume: NSObjectProtocol {
    var boundingBox: (min: SCNVector3, max: SCNVector3) { get set }
    var boundingSphere: (center: SCNVector3, radius: Float) { get }
}

public protocol SCNActionable: NSObjectProtocol {
    var actionKeys: [String] { get }
    var hasActions: Bool { get }
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
    func isAnimationPaused(forKey key: String) -> Bool
    func pauseAnimation(forKey key: String)
    func removeAllAnimations()
    func removeAllAnimations(withBlendOutDuration duration: CGFloat)
    func removeAnimation(forKey key: String)
    func removeAnimation(forKey key: String, blendOutDuration duration: CGFloat)
    func removeAnimation(forKey key: String, fadeOutDuration duration: CGFloat)
    func resumeAnimation(forKey key: String)
    func setAnimationSpeed(_ speed: CGFloat, forKey key: String)
}

public protocol SCNAnimationProtocol: NSObjectProtocol {}

public protocol SCNNodeRendererDelegate: NSObjectProtocol {}
public protocol SCNPhysicsContactDelegate: NSObjectProtocol {}
public protocol SCNSceneExportDelegate: NSObjectProtocol {}
public protocol SCNSceneRendererDelegate: NSObjectProtocol {}
public protocol SCNAvoidOccluderConstraintDelegate: NSObjectProtocol {}
public protocol SCNCameraControllerDelegate: NSObjectProtocol {}
public protocol SCNProgramDelegate: NSObjectProtocol {}
public protocol SCNCameraControlConfiguration: NSObjectProtocol {}

public protocol SCNShadable: NSObjectProtocol {}
public protocol SCNTechniqueSupport: NSObjectProtocol {}
public protocol SCNBufferStream: NSObjectProtocol {}

/// CPU-side clock used by tests and hosts that do not have a SceneKit view.
public func _openUIKitAdvanceScene(_ scene: SCNScene, deltaTime: TimeInterval) {
    scene.rootNode._openUIKitAdvance(deltaTime: deltaTime)
}
