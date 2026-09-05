import Dispatch
import Foundation

public protocol ARSessionObserver: AnyObject {
    func session(_ session: ARSession, cameraDidChangeTrackingState camera: ARCamera)
    func session(_ session: ARSession, didChange geoTrackingStatus: ARGeoTrackingStatus)
    func session(_ session: ARSession, didFailWithError error: any Error)
    func session(_ session: ARSession, didOutputCollaborationData data: ARSession.CollaborationData)
    func session(_ session: ARSession, didOutputAudioSampleBuffer audioSampleBuffer: CMSampleBuffer)
    func sessionInterruptionEnded(_ session: ARSession)
    func sessionShouldAttemptRelocalization(_ session: ARSession) -> Bool
    func sessionWasInterrupted(_ session: ARSession)
}

public extension ARSessionObserver {
    func session(_ session: ARSession, cameraDidChangeTrackingState camera: ARCamera) {
        _ = (session, camera)
    }

    func session(_ session: ARSession, didChange geoTrackingStatus: ARGeoTrackingStatus) {
        _ = (session, geoTrackingStatus)
    }

    func session(_ session: ARSession, didFailWithError error: any Error) {
        _ = (session, error)
    }

    func session(_ session: ARSession, didOutputCollaborationData data: ARSession.CollaborationData) {
        _ = (session, data)
    }

    func session(_ session: ARSession, didOutputAudioSampleBuffer audioSampleBuffer: CMSampleBuffer) {
        _ = (session, audioSampleBuffer)
    }

    func sessionInterruptionEnded(_ session: ARSession) {
        _ = session
    }

    func sessionShouldAttemptRelocalization(_ session: ARSession) -> Bool {
        _ = session
        return false
    }

    func sessionWasInterrupted(_ session: ARSession) {
        _ = session
    }
}

public protocol ARSessionDelegate: ARSessionObserver {
    func session(_ session: ARSession, didAdd anchors: [ARAnchor])
    func session(_ session: ARSession, didRemove anchors: [ARAnchor])
    func session(_ session: ARSession, didUpdate anchors: [ARAnchor])
    func session(_ session: ARSession, didUpdate frame: ARFrame)
}

public extension ARSessionDelegate {
    func session(_ session: ARSession, didAdd anchors: [ARAnchor]) {
        _ = (session, anchors)
    }

    func session(_ session: ARSession, didRemove anchors: [ARAnchor]) {
        _ = (session, anchors)
    }

    func session(_ session: ARSession, didUpdate anchors: [ARAnchor]) {
        _ = (session, anchors)
    }

    func session(_ session: ARSession, didUpdate frame: ARFrame) {
        _ = (session, frame)
    }
}

public protocol ARSessionProviding: AnyObject {
    var session: ARSession { get }
}

/// Documented simulated frame source. Produces one deterministic frame per
/// `ARSession.run` / `add` / `remove` while a test hook device is installed.
/// Camera pose, intrinsics, and a single horizontal plane are fixed; they are
/// not a live IMU/LiDAR stream.
enum ARSimulatedFrameSource {
    static let planeIdentifier = UUID(uuidString: "AAAAAAAA-BBBB-CCCC-DDDD-EEEEEEEEEEEE")!

    static func makePlane(worldOrigin: simd_float4x4, sessionIdentifier: UUID) -> ARPlaneAnchor {
        let transform = worldOrigin
        return ARPlaneAnchor(
            transform: transform,
            alignment: .horizontal,
            center: simd_float3(repeating: 0),
            extent: ARSimulatedCameraDefaults.planeExtent,
            classification: .none(.undetermined),
            isTracked: true,
            identifier: planeIdentifier,
            sessionIdentifier: sessionIdentifier
        )
    }

    static func makeCamera(worldOrigin: simd_float4x4) -> ARCamera {
        ARCamera(
            trackingState: .normal,
            transform: worldOrigin * ARSimulatedCameraDefaults.transform,
            imageResolution: ARSimulatedCameraDefaults.imageResolution,
            intrinsics: ARSimulatedCameraDefaults.intrinsics,
            exposureDuration: 1.0 / 60.0,
            exposureOffset: 0
        )
    }

    static func makeFrame(
        anchors: [ARAnchor],
        worldOrigin: simd_float4x4,
        timestamp: TimeInterval
    ) -> ARFrame {
        let camera = makeCamera(worldOrigin: worldOrigin)
        let points = [
            simd_float3(0, 0, 0),
            simd_float3(0.25, 0, 0),
            simd_float3(-0.25, 0, 0.1),
        ]
        return ARFrame(
            anchors: anchors,
            camera: camera,
            timestamp: timestamp,
            lightEstimate: ARLightEstimate(ambientIntensity: 1000, ambientColorTemperature: 6500),
            rawFeaturePoints: ARPointCloud(points: points, identifiers: [1, 2, 3]),
            geoTrackingStatus: ARGeoTrackingStatus(),
            worldMappingStatus: .limited
        )
    }
}

open class ARSession: NSObject {
    public struct RunOptions: OptionSet, Hashable, Sendable {
        public let rawValue: UInt

        public init(rawValue: UInt) {
            self.rawValue = rawValue
        }

        public static let resetTracking = RunOptions(rawValue: 1 << 0)
        public static let removeExistingAnchors = RunOptions(rawValue: 1 << 1)
        public static let stopTrackedRaycasts = RunOptions(rawValue: 1 << 2)
        public static let resetSceneReconstruction = RunOptions(rawValue: 1 << 3)
    }

    open class CollaborationData: NSObject, NSSecureCoding {
        public enum Priority: Int, Hashable, Sendable {
            case critical = 0
            case optional = 1
        }

        public var priority: Priority { _priority }
        private let _priority: Priority

        public static var supportsSecureCoding: Bool { true }

        public init(priority: Priority) {
            self._priority = priority
            super.init()
        }

        public required init?(coder: NSCoder) {
            guard coder.containsValue(forKey: "priority"),
                  let priority = Priority(rawValue: coder.decodeInteger(forKey: "priority"))
            else { return nil }
            self._priority = priority
            super.init()
        }

        public func encode(with coder: NSCoder) {
            coder.encode(priority.rawValue, forKey: "priority")
        }
    }

    public let identifier = UUID()
    public private(set) var configuration: ARConfiguration?
    public private(set) var currentFrame: ARFrame?
    public weak var delegate: (any ARSessionDelegate)?
    public var delegateQueue: DispatchQueue?

    private var userAnchors: [UUID: ARAnchor] = [:]
    private var detectedAnchors: [UUID: ARAnchor] = [:]
    private var previousAnchorIDs: Set<UUID> = []
    private var lastAnchorsByID: [UUID: ARAnchor] = [:]
    private var running = false
    private var worldOrigin = simd_float4x4.identity
    private var frameIndex: Int = 0
    private var lastTrackingState: ARCamera.TrackingState = .notAvailable

    public override init() {
        super.init()
    }

    public func run(_ configuration: ARConfiguration, options: RunOptions = []) {
        if options.contains(.removeExistingAnchors) {
            userAnchors.removeAll()
            detectedAnchors.removeAll()
            previousAnchorIDs.removeAll()
            lastAnchorsByID.removeAll()
        }
        if options.contains(.resetTracking) {
            worldOrigin = .identity
        }
        if options.contains(.stopTrackedRaycasts) {
            // Tracked raycasts are one-shot on this host; nothing to stop.
        }
        self.configuration = configuration.copy() as? ARConfiguration

        let configurationType = type(of: configuration)
        if !configurationType.isSupported {
            running = false
            currentFrame = nil
            notifyFailure(arkitUnsupportedConfigurationError())
            return
        }
        if !ARKitTestHook.isCameraAuthorized {
            running = false
            currentFrame = nil
            notifyFailure(arkitCameraUnauthorizedError())
            return
        }

        running = true
        emitFrame(initial: true)
    }

    public func pause() {
        running = false
    }

    public func add(anchor: ARAnchor) {
        let copy = (anchor.copy() as? ARAnchor) ?? ARAnchor(anchor: anchor)
        copy.applySessionIdentifier(identifier)
        userAnchors[copy.identifier] = copy
        if running {
            emitFrame(initial: false)
        }
    }

    public func remove(anchor: ARAnchor) {
        userAnchors.removeValue(forKey: anchor.identifier)
        if running {
            emitFrame(initial: false)
        }
    }

    public func raycast(_ query: ARRaycastQuery) -> [ARRaycastResult] {
        let anchors = currentFrame?.anchors ?? (Array(detectedAnchors.values) + Array(userAnchors.values))
        return arkitRaycast(query: query, anchors: anchors)
    }

    public func trackedRaycast(
        _ query: ARRaycastQuery,
        updateHandler: @escaping ([ARRaycastResult]) -> Void
    ) -> ARTrackedRaycast? {
        guard running else { return nil }
        let results = raycast(query)
        let tracked = ARTrackedRaycast()
        notify {
            if !tracked.isStopped {
                updateHandler(results)
            }
        }
        return tracked
    }

    public func setWorldOrigin(relativeTransform: simd_float4x4) {
        worldOrigin = relativeTransform * worldOrigin
        if running {
            emitFrame(initial: false)
        }
    }

    public func update(with collaborationData: CollaborationData) {
        _ = collaborationData
    }

    public func captureHighResolutionFrame(
        completion: @escaping (ARFrame?, (any Error)?) -> Void
    ) {
        complete(completion, ARFrame?.none, arkitUnsupportedConfigurationError())
    }

    public func captureHighResolutionFrame(
        using photoSettings: AVCapturePhotoSettings?
    ) async throws -> ARFrame {
        _ = photoSettings
        throw arkitUnsupportedConfigurationError()
    }

    public func getCurrentWorldMap(
        completionHandler: @escaping (ARWorldMap?, (any Error)?) -> Void
    ) {
        if running {
            complete(completionHandler, ARWorldMap?.none, arkitInvalidWorldMapError())
        } else {
            complete(completionHandler, ARWorldMap?.none, arkitUnsupportedConfigurationError())
        }
    }

    public func currentWorldMap() async throws -> ARWorldMap {
        try await withCheckedThrowingContinuation { continuation in
            getCurrentWorldMap { map, error in
                if let map {
                    continuation.resume(returning: map)
                } else {
                    continuation.resume(throwing: error ?? arkitUnsupportedConfigurationError())
                }
            }
        }
    }

    public func createReferenceObject(
        transform: simd_float4x4,
        center: simd_float3,
        extent: simd_float3
    ) async throws -> ARReferenceObject {
        _ = (transform, center, extent)
        throw arkitUnsupportedConfigurationError()
    }

    public func geoLocation(forPoint position: simd_float3) async throws -> (CLLocationCoordinate2D, CLLocationDistance) {
        _ = position
        throw ARError(.geoTrackingNotAvailableAtLocation)
    }

    private func emitFrame(initial: Bool) {
        frameIndex += 1
        let timestamp = TimeInterval(frameIndex) / 60.0
        for (_, anchor) in userAnchors {
            anchor.applySessionIdentifier(self.identifier)
        }
        var anchors = Array(userAnchors.values)
        if shouldDetectPlanes {
            let plane = ARSimulatedFrameSource.makePlane(
                worldOrigin: worldOrigin,
                sessionIdentifier: identifier
            )
            detectedAnchors[plane.identifier] = plane
            anchors.append(plane)
        }

        let frame = ARSimulatedFrameSource.makeFrame(
            anchors: anchors,
            worldOrigin: worldOrigin,
            timestamp: timestamp
        )
        currentFrame = frame

        let currentIDs = Set(anchors.map(\.identifier))
        let added = anchors.filter { !previousAnchorIDs.contains($0.identifier) }
        let removedIDs = previousAnchorIDs.subtracting(currentIDs)
        let removedAnchors = removedIDs.compactMap { lastAnchorsByID[$0] }
        let updated = anchors.filter { previousAnchorIDs.contains($0.identifier) }
        previousAnchorIDs = currentIDs
        lastAnchorsByID = Dictionary(uniqueKeysWithValues: anchors.map { ($0.identifier, $0) })

        // Documented callback order for each simulated frame:
        // 1. session(_:didUpdate:) with the ARFrame
        // 2. session(_:didAdd:)
        // 3. session(_:didUpdate:) with updated anchors
        // 4. session(_:didRemove:)
        notify {
            let delegate = self.delegate
            delegate?.session(self, didUpdate: frame)
            if !added.isEmpty {
                delegate?.session(self, didAdd: added)
            }
            if !updated.isEmpty, !initial {
                delegate?.session(self, didUpdate: updated)
            }
            if !removedAnchors.isEmpty {
                delegate?.session(self, didRemove: removedAnchors)
            }
            if self.lastTrackingState != frame.camera.trackingState {
                self.lastTrackingState = frame.camera.trackingState
                delegate?.session(self, cameraDidChangeTrackingState: frame.camera)
            }
        }
    }

    private var shouldDetectPlanes: Bool {
        if let world = configuration as? ARWorldTrackingConfiguration {
            return world.planeDetection.contains(.horizontal) || world.planeDetection.contains(.vertical)
        }
        if let body = configuration as? ARBodyTrackingConfiguration {
            return !body.planeDetection.isEmpty
        }
        if let positional = configuration as? ARPositionalTrackingConfiguration {
            return !positional.planeDetection.isEmpty
        }
        if let geo = configuration as? ARGeoTrackingConfiguration {
            return !geo.planeDetection.isEmpty
        }
        return false
    }

    private func notifyFailure(_ error: ARError) {
        notify {
            self.delegate?.session(self, didFailWithError: error)
        }
    }

    private func notify(_ body: @escaping () -> Void) {
        if let delegateQueue {
            delegateQueue.sync(execute: body)
        } else {
            body()
        }
    }

    private func complete<Value>(
        _ completion: @escaping (Value?, (any Error)?) -> Void,
        _ value: Value?,
        _ error: (any Error)?
    ) {
        notify { completion(value, error) }
    }
}

open class ARTrackedRaycast: NSObject {
    fileprivate var isStopped = false

    public func stopTracking() {
        isStopped = true
    }
}
