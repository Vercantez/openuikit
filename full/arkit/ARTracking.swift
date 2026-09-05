import Foundation

open class ARCamera: NSObject, NSCopying {
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

    public private(set) var trackingState: TrackingState
    public private(set) var transform: simd_float4x4
    public private(set) var exposureDuration: TimeInterval
    public private(set) var exposureOffset: Float
    public private(set) var imageResolution: CGSize
    public private(set) var intrinsics: simd_float3x3

    public var eulerAngles: simd_float3 {
        // ZYX extraction from the camera's world rotation (pitch, yaw, roll).
        let r = transform
        let pitch = asin(-r.columns.2.y)
        let yaw = atan2(r.columns.2.x, r.columns.2.z)
        let roll = atan2(r.columns.0.y, r.columns.1.y)
        return simd_float3(pitch, yaw, roll)
    }

    public var projectionMatrix: simd_float4x4 {
        projectionMatrix(
            for: .landscapeRight,
            viewportSize: imageResolution,
            zNear: 0.001,
            zFar: 1000
        )
    }

    public override init() {
        self.trackingState = .notAvailable
        self.transform = .identity
        self.exposureDuration = 0
        self.exposureOffset = 0
        self.imageResolution = .zero
        self.intrinsics = simd_float3x3()
        super.init()
    }

    public init(
        trackingState: TrackingState,
        transform: simd_float4x4,
        imageResolution: CGSize,
        intrinsics: simd_float3x3,
        exposureDuration: TimeInterval = 0,
        exposureOffset: Float = 0
    ) {
        self.trackingState = trackingState
        self.transform = transform
        self.imageResolution = imageResolution
        self.intrinsics = intrinsics
        self.exposureDuration = exposureDuration
        self.exposureOffset = exposureOffset
        super.init()
    }

    public func copy(with zone: NSZone? = nil) -> Any {
        _ = zone
        return ARCamera(
            trackingState: trackingState,
            transform: transform,
            imageResolution: imageResolution,
            intrinsics: intrinsics,
            exposureDuration: exposureDuration,
            exposureOffset: exposureOffset
        )
    }

    /// Pinhole OpenGL-style projection from camera intrinsics, then a Z-axis
    /// orientation rotation. Viewport aspect is applied as an X/Y scale so the
    /// image plane fills `viewportSize` without stretching.
    ///
    /// Column 0: `(2 fx / w, 0, 0, 0)`
    /// Column 1: `(0, 2 fy / h, 0, 0)`
    /// Column 2: `(1 - 2 cx / w, 2 cy / h - 1, -(f+n)/(f-n), -1)`
    /// Column 3: `(0, 0, -2 f n / (f-n), 0)`
    public func projectionMatrix(
        for orientation: UIInterfaceOrientation,
        viewportSize: CGSize,
        zNear: CGFloat,
        zFar: CGFloat
    ) -> simd_float4x4 {
        let width = Float(imageResolution.width == 0 ? viewportSize.width : imageResolution.width)
        let height = Float(imageResolution.height == 0 ? viewportSize.height : imageResolution.height)
        let fx = intrinsics.columns.0.x == 0 ? width : intrinsics.columns.0.x
        let fy = intrinsics.columns.1.y == 0 ? height : intrinsics.columns.1.y
        let cx = intrinsics.columns.2.x == 0 ? width / 2 : intrinsics.columns.2.x
        let cy = intrinsics.columns.2.y == 0 ? height / 2 : intrinsics.columns.2.y
        let near = Float(zNear)
        let far = Float(zFar)
        let denom = far - near
        let pinhole = simd_float4x4(
            columns: (
                simd_float4(2 * fx / max(width, 1), 0, 0, 0),
                simd_float4(0, 2 * fy / max(height, 1), 0, 0),
                simd_float4(
                    1 - 2 * cx / max(width, 1),
                    2 * cy / max(height, 1) - 1,
                    denom == 0 ? 0 : -(far + near) / denom,
                    -1
                ),
                simd_float4(0, 0, denom == 0 ? 0 : -2 * far * near / denom, 0)
            )
        )
        var aspect = simd_float4x4.identity
        let imageAspect = width / max(height, 1)
        let viewW = Float(viewportSize.width == 0 ? CGFloat(width) : viewportSize.width)
        let viewH = Float(viewportSize.height == 0 ? CGFloat(height) : viewportSize.height)
        let viewAspect = viewW / max(viewH, 1)
        if viewAspect > 0, imageAspect > 0 {
            let scale = imageAspect / viewAspect
            if scale > 1 {
                aspect.columns.0.x = 1 / scale
            } else if scale < 1 {
                aspect.columns.1.y = scale
            }
        }
        return arkitInterfaceOrientationRotation(orientation) * aspect * pinhole
    }

    public func viewMatrix(for orientation: UIInterfaceOrientation) -> simd_float4x4 {
        arkitInterfaceOrientationRotation(orientation) * transform.rigidInverse()
    }

    public func projectPoint(
        _ point: simd_float3,
        orientation: UIInterfaceOrientation,
        viewportSize: CGSize
    ) -> CGPoint {
        let view = viewMatrix(for: orientation)
        let projection = projectionMatrix(
            for: orientation,
            viewportSize: viewportSize,
            zNear: 0.001,
            zFar: 1000
        )
        let clip = projection * (view * simd_float4(point.x, point.y, point.z, 1))
        guard clip.w != 0 else { return .zero }
        let ndcX = clip.x / clip.w
        let ndcY = clip.y / clip.w
        return CGPoint(
            x: CGFloat((ndcX + 1) * 0.5) * viewportSize.width,
            y: CGFloat((1 - ndcY) * 0.5) * viewportSize.height
        )
    }

    public func unprojectPoint(
        _ point: CGPoint,
        ontoPlane planeTransform: simd_float4x4,
        orientation: UIInterfaceOrientation,
        viewportSize: CGSize
    ) -> simd_float3? {
        let query = ray(from: point, orientation: orientation, viewportSize: viewportSize)
        let origin = planeTransform.transformPoint(simd_float3(repeating: 0))
        let normal = arkitNormalize(planeTransform.transformDirection(simd_float3(0, 1, 0)))
        return arkitRayPlaneIntersection(
            origin: query.origin,
            direction: query.direction,
            planePoint: origin,
            planeNormal: normal
        )
    }

    func ray(
        from point: CGPoint,
        orientation: UIInterfaceOrientation,
        viewportSize: CGSize
    ) -> (origin: simd_float3, direction: simd_float3) {
        let width = max(imageResolution.width, 1)
        let height = max(imageResolution.height, 1)
        let fx = intrinsics.columns.0.x == 0 ? Float(width) : intrinsics.columns.0.x
        let fy = intrinsics.columns.1.y == 0 ? Float(height) : intrinsics.columns.1.y
        let cx = intrinsics.columns.2.x == 0 ? Float(width) / 2 : intrinsics.columns.2.x
        let cy = intrinsics.columns.2.y == 0 ? Float(height) / 2 : intrinsics.columns.2.y
        let px = Float(point.x) * Float(width)
        let py = Float(point.y) * Float(height)
        let cameraDirection = arkitNormalize(
            simd_float3((px - cx) / fx, (cy - py) / fy, -1)
        )
        let rotated = arkitInterfaceOrientationRotation(orientation).transformDirection(cameraDirection)
        let origin = transform.transformPoint(simd_float3(repeating: 0))
        let direction = arkitNormalize(transform.transformDirection(rotated))
        _ = viewportSize
        return (origin, direction)
    }
}

func arkitRayPlaneIntersection(
    origin: simd_float3,
    direction: simd_float3,
    planePoint: simd_float3,
    planeNormal: simd_float3
) -> simd_float3? {
    let denom = arkitDot(planeNormal, direction)
    guard abs(denom) > 1e-6 else { return nil }
    let t = arkitDot(planeNormal, simd_float3(
        planePoint.x - origin.x,
        planePoint.y - origin.y,
        planePoint.z - origin.z
    )) / denom
    guard t >= 0 else { return nil }
    return simd_float3(
        origin.x + direction.x * t,
        origin.y + direction.y * t,
        origin.z + direction.z * t
    )
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
    public var camera: ARCamera { (_camera.copy() as? ARCamera) ?? _camera }
    public var cameraGrainIntensity: Float { _cameraGrainIntensity }
    public var cameraGrainTexture: (any MTLTexture)? { nil }
    public var capturedDepthData: AVDepthData? { nil }
    public var capturedDepthDataTimestamp: TimeInterval { 0 }
    public var capturedImage: CVPixelBuffer { _capturedImage }
    public var detectedBody: ARBody2D? { nil }
    public var estimatedDepthData: CVPixelBuffer? { nil }
    public var exifData: [String: Any] { [:] }
    public var geoTrackingStatus: ARGeoTrackingStatus? { _geoTrackingStatus }
    public var lightEstimate: ARLightEstimate? { _lightEstimate }
    public var rawFeaturePoints: ARPointCloud? { _rawFeaturePoints }
    public var sceneDepth: ARDepthData? { nil }
    public var segmentationBuffer: CVPixelBuffer? { nil }
    public var smoothedSceneDepth: ARDepthData? { nil }
    public var timestamp: TimeInterval { _timestamp }
    public var worldMappingStatus: WorldMappingStatus { _worldMappingStatus }

    private let _anchors: [ARAnchor]
    private let _camera: ARCamera
    private let _timestamp: TimeInterval
    private let _capturedImage: CVPixelBuffer
    private let _lightEstimate: ARLightEstimate?
    private let _rawFeaturePoints: ARPointCloud?
    private let _geoTrackingStatus: ARGeoTrackingStatus?
    private let _cameraGrainIntensity: Float
    private let _worldMappingStatus: WorldMappingStatus

    public init(anchors: [ARAnchor] = [], camera: ARCamera = ARCamera(), timestamp: TimeInterval = 0) {
        self._anchors = anchors
        self._camera = camera
        self._timestamp = timestamp
        self._capturedImage = CVPixelBuffer(
            width: Int(camera.imageResolution.width),
            height: Int(camera.imageResolution.height)
        )
        self._lightEstimate = nil
        self._rawFeaturePoints = nil
        self._geoTrackingStatus = nil
        self._cameraGrainIntensity = 0
        self._worldMappingStatus = .notAvailable
        super.init()
    }

    init(
        anchors: [ARAnchor],
        camera: ARCamera,
        timestamp: TimeInterval,
        lightEstimate: ARLightEstimate?,
        rawFeaturePoints: ARPointCloud?,
        geoTrackingStatus: ARGeoTrackingStatus?,
        worldMappingStatus: WorldMappingStatus
    ) {
        self._anchors = anchors
        self._camera = camera
        self._timestamp = timestamp
        self._capturedImage = CVPixelBuffer(
            width: Int(camera.imageResolution.width),
            height: Int(camera.imageResolution.height)
        )
        self._lightEstimate = lightEstimate
        self._rawFeaturePoints = rawFeaturePoints
        self._geoTrackingStatus = geoTrackingStatus
        self._cameraGrainIntensity = 0
        self._worldMappingStatus = worldMappingStatus
        super.init()
    }

    public func displayTransform(
        for orientation: UIInterfaceOrientation,
        viewportSize: CGSize
    ) -> CGAffineTransform {
        _ = viewportSize
        switch orientation {
        case .portrait:
            return CGAffineTransform(rotationAngle: -.pi / 2)
        case .portraitUpsideDown:
            return CGAffineTransform(rotationAngle: .pi / 2)
        case .landscapeLeft:
            return CGAffineTransform(rotationAngle: .pi)
        case .landscapeRight, .unknown:
            return .identity
        }
    }

    public func hitTest(_ point: CGPoint, types: ARHitTestResult.ResultType) -> [ARHitTestResult] {
        let ray = camera.ray(from: point, orientation: .landscapeRight, viewportSize: camera.imageResolution)
        return arkitHitTest(
            origin: ray.origin,
            direction: ray.direction,
            types: types,
            anchors: anchors,
            featurePoints: rawFeaturePoints
        )
    }

    public func raycastQuery(
        from point: CGPoint,
        allowing target: ARRaycastQuery.Target,
        alignment: ARRaycastQuery.TargetAlignment
    ) -> ARRaycastQuery {
        let ray = camera.ray(from: point, orientation: .landscapeRight, viewportSize: camera.imageResolution)
        return ARRaycastQuery(
            origin: ray.origin,
            direction: ray.direction,
            allowing: target,
            alignment: alignment
        )
    }
}

func arkitHitTest(
    origin: simd_float3,
    direction: simd_float3,
    types: ARHitTestResult.ResultType,
    anchors: [ARAnchor],
    featurePoints: ARPointCloud?
) -> [ARHitTestResult] {
    var results: [ARHitTestResult] = []
    let dir = arkitNormalize(direction)

    if types.contains(.existingPlane)
        || types.contains(.existingPlaneUsingExtent)
        || types.contains(.existingPlaneUsingGeometry)
    {
        for anchor in anchors {
            guard let plane = anchor as? ARPlaneAnchor else { continue }
            let worldPoint = plane.transform.transformPoint(plane.center)
            let normal = arkitNormalize(
                plane.transform.transformDirection(
                    plane.alignment == .vertical ? simd_float3(0, 0, 1) : simd_float3(0, 1, 0)
                )
            )
            guard let hit = arkitRayPlaneIntersection(
                origin: origin,
                direction: dir,
                planePoint: worldPoint,
                planeNormal: normal
            ) else { continue }
            let local = plane.transform.rigidInverse().transformPoint(hit)
            let insideExtent =
                abs(local.x - plane.center.x) <= plane.extent.x / 2 + 1e-5
                && abs(local.z - plane.center.z) <= plane.extent.z / 2 + 1e-5
            if types.contains(.existingPlaneUsingExtent) || types.contains(.existingPlaneUsingGeometry) {
                guard insideExtent else { continue }
            }
            let resultType: ARHitTestResult.ResultType
            if types.contains(.existingPlaneUsingGeometry), insideExtent {
                resultType = .existingPlaneUsingGeometry
            } else if types.contains(.existingPlaneUsingExtent), insideExtent {
                resultType = .existingPlaneUsingExtent
            } else {
                resultType = .existingPlane
            }
            let distance = CGFloat(arkitLength(simd_float3(
                hit.x - origin.x, hit.y - origin.y, hit.z - origin.z
            )))
            var world = simd_float4x4.identity
            world.columns.3 = simd_float4(hit.x, hit.y, hit.z, 1)
            var localTransform = simd_float4x4.identity
            localTransform.columns.3 = simd_float4(local.x, local.y, local.z, 1)
            results.append(
                ARHitTestResult(
                    type: resultType,
                    distance: distance,
                    localTransform: localTransform,
                    worldTransform: world,
                    anchor: plane
                )
            )
        }
    }

    if types.contains(.estimatedHorizontalPlane) {
        if let hit = arkitRayPlaneIntersection(
            origin: origin,
            direction: dir,
            planePoint: simd_float3(repeating: 0),
            planeNormal: simd_float3(0, 1, 0)
        ) {
            let distance = CGFloat(arkitLength(simd_float3(
                hit.x - origin.x, hit.y - origin.y, hit.z - origin.z
            )))
            var world = simd_float4x4.identity
            world.columns.3 = simd_float4(hit.x, hit.y, hit.z, 1)
            results.append(
                ARHitTestResult(
                    type: .estimatedHorizontalPlane,
                    distance: distance,
                    localTransform: world,
                    worldTransform: world,
                    anchor: nil
                )
            )
        }
    }

    if types.contains(.estimatedVerticalPlane) {
        if let hit = arkitRayPlaneIntersection(
            origin: origin,
            direction: dir,
            planePoint: simd_float3(repeating: 0),
            planeNormal: simd_float3(0, 0, 1)
        ) {
            let distance = CGFloat(arkitLength(simd_float3(
                hit.x - origin.x, hit.y - origin.y, hit.z - origin.z
            )))
            var world = simd_float4x4.identity
            world.columns.3 = simd_float4(hit.x, hit.y, hit.z, 1)
            results.append(
                ARHitTestResult(
                    type: .estimatedVerticalPlane,
                    distance: distance,
                    localTransform: world,
                    worldTransform: world,
                    anchor: nil
                )
            )
        }
    }

    if types.contains(.featurePoint), let cloud = featurePoints {
        var best: (simd_float3, Float)?
        for point in cloud.points {
            let toPoint = simd_float3(point.x - origin.x, point.y - origin.y, point.z - origin.z)
            let t = arkitDot(toPoint, dir)
            guard t >= 0 else { continue }
            let closest = simd_float3(
                origin.x + dir.x * t,
                origin.y + dir.y * t,
                origin.z + dir.z * t
            )
            let lateral = arkitLength(simd_float3(
                point.x - closest.x, point.y - closest.y, point.z - closest.z
            ))
            if lateral < 0.05, best == nil || t < best!.1 {
                best = (point, t)
            }
        }
        if let best {
            var world = simd_float4x4.identity
            world.columns.3 = simd_float4(best.0.x, best.0.y, best.0.z, 1)
            results.append(
                ARHitTestResult(
                    type: .featurePoint,
                    distance: CGFloat(best.1),
                    localTransform: world,
                    worldTransform: world,
                    anchor: nil
                )
            )
        }
    }

    return results.sorted { $0.distance < $1.distance }
}

func arkitRaycast(
    query: ARRaycastQuery,
    anchors: [ARAnchor]
) -> [ARRaycastResult] {
    let dir = arkitNormalize(query.direction)
    var results: [ARRaycastResult] = []

    func consider(plane: ARPlaneAnchor, alignment: ARRaycastQuery.TargetAlignment) {
        if query.targetAlignment != .any, query.targetAlignment != alignment {
            return
        }
        let worldPoint = plane.transform.transformPoint(plane.center)
        let normal = arkitNormalize(
            plane.transform.transformDirection(
                plane.alignment == .vertical ? simd_float3(0, 0, 1) : simd_float3(0, 1, 0)
            )
        )
        guard let hit = arkitRayPlaneIntersection(
            origin: query.origin,
            direction: dir,
            planePoint: worldPoint,
            planeNormal: normal
        ) else { return }
        let local = plane.transform.rigidInverse().transformPoint(hit)
        let inside =
            abs(local.x - plane.center.x) <= plane.extent.x / 2 + 1e-5
            && abs(local.z - plane.center.z) <= plane.extent.z / 2 + 1e-5
        switch query.target {
        case .existingPlaneGeometry, .existingPlaneInfinite:
            if query.target == .existingPlaneGeometry, !inside { return }
        case .estimatedPlane:
            break
        }
        var world = simd_float4x4.identity
        world.columns.3 = simd_float4(hit.x, hit.y, hit.z, 1)
        results.append(
            ARRaycastResult(
                worldTransform: world,
                target: query.target,
                targetAlignment: alignment,
                anchor: plane
            )
        )
    }

    for anchor in anchors {
        guard let plane = anchor as? ARPlaneAnchor else { continue }
        let alignment: ARRaycastQuery.TargetAlignment =
            plane.alignment == .vertical ? .vertical : .horizontal
        consider(plane: plane, alignment: alignment)
    }

    if query.target == .estimatedPlane {
        let wantsHorizontal = query.targetAlignment != .vertical
        let wantsVertical = query.targetAlignment != .horizontal
        if wantsHorizontal,
           let hit = arkitRayPlaneIntersection(
            origin: query.origin,
            direction: dir,
            planePoint: simd_float3(repeating: 0),
            planeNormal: simd_float3(0, 1, 0)
           )
        {
            var world = simd_float4x4.identity
            world.columns.3 = simd_float4(hit.x, hit.y, hit.z, 1)
            results.append(
                ARRaycastResult(
                    worldTransform: world,
                    target: .estimatedPlane,
                    targetAlignment: .horizontal,
                    anchor: nil
                )
            )
        }
        if wantsVertical,
           let hit = arkitRayPlaneIntersection(
            origin: query.origin,
            direction: dir,
            planePoint: simd_float3(repeating: 0),
            planeNormal: simd_float3(0, 0, 1)
           )
        {
            var world = simd_float4x4.identity
            world.columns.3 = simd_float4(hit.x, hit.y, hit.z, 1)
            results.append(
                ARRaycastResult(
                    worldTransform: world,
                    target: .estimatedPlane,
                    targetAlignment: .vertical,
                    anchor: nil
                )
            )
        }
    }

    return results
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

    public init(ambientIntensity: CGFloat = 0, ambientColorTemperature: CGFloat = 0) {
        self._ambientIntensity = ambientIntensity
        self._ambientColorTemperature = ambientColorTemperature
        super.init()
    }
}

open class ARDirectionalLightEstimate: ARLightEstimate {
    public var primaryLightDirection: simd_float3 { simd_float3(0, -1, 0) }
    public var primaryLightIntensity: CGFloat { 0 }
    public var sphericalHarmonicsCoefficients: Data { Data(count: 27 * MemoryLayout<Float>.size) }
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
        let count = coder.decodeInteger(forKey: "count")
        var points: [simd_float3] = []
        var identifiers: [UInt64] = []
        for index in 0..<count {
            points.append(
                simd_float3(
                    coder.decodeFloat(forKey: "px.\(index)"),
                    coder.decodeFloat(forKey: "py.\(index)"),
                    coder.decodeFloat(forKey: "pz.\(index)")
                )
            )
            identifiers.append(UInt64(bitPattern: coder.decodeInt64(forKey: "id.\(index)")))
        }
        self._points = points
        self._identifiers = identifiers
        super.init()
    }

    public func encode(with coder: NSCoder) {
        coder.encode(points.count, forKey: "count")
        for (index, point) in points.enumerated() {
            coder.encode(point.x, forKey: "px.\(index)")
            coder.encode(point.y, forKey: "py.\(index)")
            coder.encode(point.z, forKey: "pz.\(index)")
            coder.encode(
                Int64(bitPattern: identifiers.indices.contains(index) ? identifiers[index] : 0),
                forKey: "id.\(index)"
            )
        }
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

    public var state: State { _state }
    public var accuracy: Accuracy { _accuracy }
    public var stateReason: StateReason { _stateReason }

    private let _state: State
    private let _accuracy: Accuracy
    private let _stateReason: StateReason

    public static var supportsSecureCoding: Bool { true }

    public override init() {
        self._state = .notAvailable
        self._accuracy = .undetermined
        self._stateReason = .notAvailableAtLocation
        super.init()
    }

    init(state: State, accuracy: Accuracy, stateReason: StateReason) {
        self._state = state
        self._accuracy = accuracy
        self._stateReason = stateReason
        super.init()
    }

    public required init?(coder: NSCoder) {
        self._state = State(rawValue: coder.decodeInteger(forKey: "state")) ?? .notAvailable
        self._accuracy = Accuracy(rawValue: coder.decodeInteger(forKey: "accuracy")) ?? .undetermined
        self._stateReason = StateReason(rawValue: coder.decodeInteger(forKey: "reason")) ?? .notAvailableAtLocation
        super.init()
    }

    public func encode(with coder: NSCoder) {
        coder.encode(state.rawValue, forKey: "state")
        coder.encode(accuracy.rawValue, forKey: "accuracy")
        coder.encode(stateReason.rawValue, forKey: "reason")
    }
}

open class ARDepthData: NSObject {
    public var confidenceMap: CVPixelBuffer? { nil }
    public var depthMap: CVPixelBuffer { CVPixelBuffer() }
}

open class ARMatteGenerator: NSObject {
    public enum Resolution: Int, Hashable, Sendable {
        case full = 0
        case half = 1
    }

    public init(device: any MTLDevice, matteResolution: Resolution) {
        _ = (device, matteResolution)
        super.init()
    }

    public func generateDilatedDepth(from frame: ARFrame, commandBuffer: any MTLCommandBuffer) -> any MTLTexture {
        _ = (frame, commandBuffer)
        return ARKitHostMTLTexture()
    }

    public func generateMatte(from frame: ARFrame, commandBuffer: any MTLCommandBuffer) -> any MTLTexture {
        _ = (frame, commandBuffer)
        return ARKitHostMTLTexture()
    }
}
