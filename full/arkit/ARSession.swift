import Dispatch
import Foundation

public protocol ARSessionObserver: AnyObject {
    func session(_ session: ARSession, cameraDidChangeTrackingState camera: ARCamera)
    func session(_ session: ARSession, didChange geoTrackingStatus: ARGeoTrackingStatus)
    func session(_ session: ARSession, didFailWithError error: any Error)
    func session(_ session: ARSession, didOutputCollaborationData data: ARSession.CollaborationData)
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

        init(priority: Priority) {
            self._priority = priority
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

    public let identifier = UUID()
    public private(set) var configuration: ARConfiguration?
    public private(set) var currentFrame: ARFrame?
    public weak var delegate: (any ARSessionDelegate)?
    public var delegateQueue: DispatchQueue?

    private var anchors: [UUID: ARAnchor] = [:]

    public override init() {
        super.init()
    }

    public func run(_ configuration: ARConfiguration, options: RunOptions = []) {
        if options.contains(.removeExistingAnchors) {
            anchors.removeAll()
        }
        self.configuration = configuration.copy() as? ARConfiguration
        currentFrame = nil
        notifyFailure(arkitUnsupportedConfigurationError())
    }

    public func pause() {
        currentFrame = nil
    }

    public func add(anchor: ARAnchor) {
        anchors[anchor.identifier] = anchor
    }

    public func remove(anchor: ARAnchor) {
        anchors.removeValue(forKey: anchor.identifier)
    }

    public func raycast(_ query: ARRaycastQuery) -> [ARRaycastResult] {
        _ = query
        return []
    }

    public func trackedRaycast(
        _ query: ARRaycastQuery,
        updateHandler: @escaping ([ARRaycastResult]) -> Void
    ) -> ARTrackedRaycast? {
        _ = (query, updateHandler)
        return nil
    }

    public func setWorldOrigin(relativeTransform: simd_float4x4) {
        _ = relativeTransform
    }

    public func update(with collaborationData: CollaborationData) {
        _ = collaborationData
    }

    public func captureHighResolutionFrame(
        completion: @escaping (ARFrame?, (any Error)?) -> Void
    ) {
        complete(completion, ARFrame?.none, arkitUnsupportedConfigurationError())
    }

    public func currentWorldMap() async throws -> ARWorldMap {
        throw arkitUnsupportedConfigurationError()
    }

    public func createReferenceObject(
        transform: simd_float4x4,
        center: simd_float3,
        extent: simd_float3
    ) async throws -> ARReferenceObject {
        _ = (transform, center, extent)
        throw arkitUnsupportedConfigurationError()
    }

    private func notifyFailure(_ error: ARError) {
        let delegate = self.delegate
        let work = { delegate?.session(self, didFailWithError: error) }
        if let delegateQueue {
            delegateQueue.sync(execute: work)
        } else {
            work()
        }
    }

    private func complete<Value>(
        _ completion: @escaping (Value?, (any Error)?) -> Void,
        _ value: Value?,
        _ error: (any Error)?
    ) {
        let work = { completion(value, error) }
        if let delegateQueue {
            delegateQueue.sync(execute: work)
        } else {
            work()
        }
    }
}

open class ARTrackedRaycast: NSObject {
    public func stopTracking() {}
}
