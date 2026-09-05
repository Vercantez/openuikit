import Dispatch
import Foundation
import ARKit

func arkitRequire(_ condition: Bool, _ message: String) {
    if !condition {
        fatalError(message)
    }
}

func arkitAlmostEqual(_ a: Float, _ b: Float, eps: Float = 1e-4) -> Bool {
    abs(a - b) < eps
}

func arkitWait(_ work: (@escaping () -> Void) -> Void) {
    let lock = DispatchSemaphore(value: 0)
    var finished = false
    work {
        finished = true
        lock.signal()
    }
    arkitRequire(lock.wait(timeout: .now() + 5) == .success && finished, "callback timed out")
}

func arkitAwaitError(_ work: @escaping () async throws -> Void) -> Error {
    let lock = DispatchSemaphore(value: 0)
    var caught: Error?
    Task {
        do {
            try await work()
        } catch {
            caught = error
        }
        lock.signal()
    }
    arkitRequire(lock.wait(timeout: .now() + 5) == .success, "async timed out")
    guard let caught else {
        fatalError("expected thrown error")
    }
    return caught
}

final class ARKitSessionProbe: NSObject, ARSessionDelegate {
    var failures: [ARError.Code] = []
    var frames: [ARFrame] = []
    var added: [[ARAnchor]] = []
    var updated: [[ARAnchor]] = []
    var removed: [[ARAnchor]] = []
    var trackingStates: [ARCamera.TrackingState] = []
    var order: [String] = []

    func session(_ session: ARSession, didFailWithError error: any Error) {
        _ = session
        if let error = error as? ARError {
            failures.append(error.code)
        }
        order.append("fail")
    }

    func session(_ session: ARSession, didUpdate frame: ARFrame) {
        _ = session
        frames.append(frame)
        order.append("frame")
    }

    func session(_ session: ARSession, didAdd anchors: [ARAnchor]) {
        _ = session
        added.append(anchors)
        order.append("add")
    }

    func session(_ session: ARSession, didUpdate anchors: [ARAnchor]) {
        _ = session
        updated.append(anchors)
        order.append("update")
    }

    func session(_ session: ARSession, didRemove anchors: [ARAnchor]) {
        _ = session
        removed.append(anchors)
        order.append("remove")
    }

    func session(_ session: ARSession, cameraDidChangeTrackingState camera: ARCamera) {
        _ = session
        trackingStates.append(camera.trackingState)
        order.append("tracking")
    }
}

final class EmptySessionDelegate: NSObject, ARSessionDelegate {}
final class EmptySCNViewDelegate: NSObject, ARSCNViewDelegate {}
final class EmptySKViewDelegate: NSObject, ARSKViewDelegate {}
final class EmptyCoachingDelegate: NSObject, ARCoachingOverlayViewDelegate {}
final class DummySceneRenderer: NSObject, SCNSceneRenderer {}

func arkitMakeHorizontalPlane(
    extent: simd_float3 = simd_float3(2, 0, 2),
    classification: ARPlaneAnchor.Classification = .floor
) -> ARPlaneAnchor {
    ARPlaneAnchor(
        transform: .identity,
        alignment: .horizontal,
        center: simd_float3(repeating: 0),
        extent: extent,
        classification: classification,
        isTracked: true,
        identifier: UUID(),
        sessionIdentifier: UUID()
    )
}
