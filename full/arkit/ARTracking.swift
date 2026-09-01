import Foundation

open class ARCamera: NSObject {
    @frozen public enum TrackingState: Equatable, Sendable {
        case notAvailable
        case limited(Reason)
        case normal

        public enum Reason: Equatable, Hashable, Sendable {
            case initializing
            case relocalizing
            case excessiveMotion
            case insufficientFeatures
        }
    }

    public var trackingState: TrackingState { .notAvailable }
    public var transform: simd_float4x4 { .identity }
    public var eulerAngles: simd_float3 { simd_float3(repeating: 0) }
    public var exposureDuration: TimeInterval { 0 }
    public var exposureOffset: Float { 0 }
    public var imageResolution: CGSize { .zero }
    public var intrinsics: simd_float3x3 { simd_float3x3() }
    public var projectionMatrix: simd_float4x4 { .identity }
}

open class ARFrame: NSObject {
    public enum SegmentationClass: UInt8, Hashable, Sendable {
        case none = 0
        case person = 1
    }

    public enum WorldMappingStatus: Int, Hashable, Sendable {
        case notAvailable = 0
        case limited = 1
        case extending = 2
        case mapped = 3
    }

    public var anchors: [ARAnchor] { _anchors }
    public var camera: ARCamera { _camera }
    public var cameraGrainIntensity: Float { 0 }
    public var capturedDepthDataTimestamp: TimeInterval { 0 }
    public var detectedBody: ARBody2D? { nil }
    public var exifData: [String: Any] { [:] }
    public var geoTrackingStatus: ARGeoTrackingStatus? { nil }
    public var lightEstimate: ARLightEstimate? { nil }
    public var rawFeaturePoints: ARPointCloud? { nil }
    public var sceneDepth: ARDepthData? { nil }
    public var smoothedSceneDepth: ARDepthData? { nil }
    public var timestamp: TimeInterval { _timestamp }
    public var worldMappingStatus: WorldMappingStatus { .notAvailable }

    private let _anchors: [ARAnchor]
    private let _camera: ARCamera
    private let _timestamp: TimeInterval

    public init(anchors: [ARAnchor] = [], camera: ARCamera = ARCamera(), timestamp: TimeInterval = 0) {
        self._anchors = anchors
        self._camera = camera
        self._timestamp = timestamp
        super.init()
    }

    public func hitTest(_ point: CGPoint, types: ARHitTestResult.ResultType) -> [ARHitTestResult] {
        _ = (point, types)
        return []
    }

    public func raycastQuery(
        from point: CGPoint,
        allowing target: ARRaycastQuery.Target,
        alignment: ARRaycastQuery.TargetAlignment
    ) -> ARRaycastQuery {
        _ = point
        return ARRaycastQuery(
            origin: simd_float3(repeating: 0),
            direction: simd_float3(0, 0, -1),
            allowing: target,
            alignment: alignment
        )
    }
}

open class ARHitTestResult: NSObject {
    public struct ResultType: OptionSet, Hashable, Sendable {
        public let rawValue: UInt

        public init(rawValue: UInt) {
            self.rawValue = rawValue
        }

        public static let featurePoint = ResultType(rawValue: 1 << 0)
        public static let estimatedHorizontalPlane = ResultType(rawValue: 1 << 1)
        public static let estimatedVerticalPlane = ResultType(rawValue: 1 << 2)
        public static let existingPlane = ResultType(rawValue: 1 << 3)
        public static let existingPlaneUsingExtent = ResultType(rawValue: 1 << 4)
        public static let existingPlaneUsingGeometry = ResultType(rawValue: 1 << 5)
    }

    public var type: ResultType { _type }
    public var distance: CGFloat { _distance }
    public var localTransform: simd_float4x4 { _localTransform }
    public var worldTransform: simd_float4x4 { _worldTransform }
    public var anchor: ARAnchor? { _anchor }

    private let _type: ResultType
    private let _distance: CGFloat
    private let _localTransform: simd_float4x4
    private let _worldTransform: simd_float4x4
    private let _anchor: ARAnchor?

    init(
        type: ResultType,
        distance: CGFloat,
        localTransform: simd_float4x4,
        worldTransform: simd_float4x4,
        anchor: ARAnchor?
    ) {
        self._type = type
        self._distance = distance
        self._localTransform = localTransform
        self._worldTransform = worldTransform
        self._anchor = anchor
        super.init()
    }
}

open class ARRaycastQuery: NSObject {
    public enum Target: Int, Hashable, Sendable {
        case existingPlaneInfinite = 0
        case existingPlaneGeometry = 1
        case estimatedPlane = 2
    }

    public enum TargetAlignment: Int, Hashable, Sendable {
        case any = 0
        case horizontal = 1
        case vertical = 2
    }

    public var origin: simd_float3 { _origin }
    public var direction: simd_float3 { _direction }
    public var target: Target { _target }
    public var targetAlignment: TargetAlignment { _targetAlignment }

    private let _origin: simd_float3
    private let _direction: simd_float3
    private let _target: Target
    private let _targetAlignment: TargetAlignment

    public init(
        origin: simd_float3,
        direction: simd_float3,
        allowing target: Target,
        alignment: TargetAlignment
    ) {
        self._origin = origin
        self._direction = direction
        self._target = target
        self._targetAlignment = alignment
        super.init()
    }

    public init(
        origin: simd_float3,
        direction: simd_float3,
        allowingTarget target: Target,
        alignment: TargetAlignment
    ) {
        self._origin = origin
        self._direction = direction
        self._target = target
        self._targetAlignment = alignment
        super.init()
    }
}

open class ARRaycastResult: NSObject {
    public var worldTransform: simd_float4x4 { _worldTransform }
    public var target: ARRaycastQuery.Target { _target }
    public var targetAlignment: ARRaycastQuery.TargetAlignment { _targetAlignment }
    public var anchor: ARAnchor? { _anchor }

    private let _worldTransform: simd_float4x4
    private let _target: ARRaycastQuery.Target
    private let _targetAlignment: ARRaycastQuery.TargetAlignment
    private let _anchor: ARAnchor?

    init(
        worldTransform: simd_float4x4,
        target: ARRaycastQuery.Target,
        targetAlignment: ARRaycastQuery.TargetAlignment,
        anchor: ARAnchor?
    ) {
        self._worldTransform = worldTransform
        self._target = target
        self._targetAlignment = targetAlignment
        self._anchor = anchor
        super.init()
    }
}

open class ARLightEstimate: NSObject {
    public var ambientIntensity: CGFloat { _ambientIntensity }
    public var ambientColorTemperature: CGFloat { _ambientColorTemperature }

    private let _ambientIntensity: CGFloat
    private let _ambientColorTemperature: CGFloat

    init(ambientIntensity: CGFloat = 0, ambientColorTemperature: CGFloat = 0) {
        self._ambientIntensity = ambientIntensity
        self._ambientColorTemperature = ambientColorTemperature
        super.init()
    }
}

open class ARDirectionalLightEstimate: ARLightEstimate {
    public var primaryLightDirection: simd_float3 { simd_float3(0, -1, 0) }
    public var primaryLightIntensity: CGFloat { 0 }
    public var sphericalHarmonicsCoefficients: Data { Data() }
}

open class ARPointCloud: NSObject, NSSecureCoding {
    public var count: Int { points.count }
    public var points: [simd_float3] { _points }
    public var identifiers: [UInt64] { _identifiers }

    private let _points: [simd_float3]
    private let _identifiers: [UInt64]

    public static var supportsSecureCoding: Bool { true }

    init(points: [simd_float3] = [], identifiers: [UInt64] = []) {
        self._points = points
        self._identifiers = identifiers
        super.init()
    }

    public required init?(coder: NSCoder) {
        _ = coder
        return nil
    }

    public func encode(with coder: NSCoder) {
        _ = coder
    }
}

open class ARGeoTrackingStatus: NSObject, NSSecureCoding {
    public enum State: Int, Hashable, Sendable {
        case notAvailable = 0
        case initializing = 1
        case localizing = 2
        case localized = 3
    }

    public enum Accuracy: Int, Hashable, Sendable {
        case undetermined = 0
        case low = 1
        case medium = 2
        case high = 3
    }

    public enum StateReason: Int, Hashable, Sendable {
        case none = 0
        case notAvailableAtLocation = 1
        case needLocationPermissions = 2
        case worldTrackingUnstable = 3
        case waitingForLocation = 4
        case waitingForAvailabilityCheck = 5
        case geoDataNotLoaded = 6
        case devicePointedTooLow = 7
        case visualLocalizationFailed = 8
    }

    public var state: State { .notAvailable }
    public var accuracy: Accuracy { .undetermined }
    public var stateReason: StateReason { .notAvailableAtLocation }

    public static var supportsSecureCoding: Bool { true }

    public override init() {
        super.init()
    }

    public required init?(coder: NSCoder) {
        _ = coder
        return nil
    }

    public func encode(with coder: NSCoder) {
        _ = coder
    }
}

open class ARDepthData: NSObject {}

open class ARMatteGenerator: NSObject {
    public enum Resolution: Int, Hashable, Sendable {
        case full = 0
        case half = 1
    }
}
