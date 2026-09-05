import Foundation
import ARKit

func testSessionRunFailsClosedWithoutDevice() {
    ARKitTestHook.removeSimulatedDevice()
    let session = ARSession()
    let probe = ARKitSessionProbe()
    session.delegate = probe
    arkitRequire(session.identifier != UUID(uuidString: "00000000-0000-0000-0000-000000000000"), "identifier")
    arkitRequire(session.currentFrame == nil, "no fabricated frame")
    let named = ARAnchor(name: "artwork", transform: .identity)
    session.add(anchor: named)
    session.remove(anchor: named)
    session.add(anchor: named)
    session.setWorldOrigin(relativeTransform: .identity)
    session.run(ARWorldTrackingConfiguration(), options: [.resetTracking, .removeExistingAnchors])
    arkitRequire(probe.failures == [.unsupportedConfiguration], "unsupportedConfiguration")
    arkitRequire(session.configuration != nil, "requested configuration retained")
    arkitRequire(session.currentFrame == nil, "run does not invent a frame")
    session.pause()
}

func testSessionCameraUnauthorized() {
    ARKitTestHook.removeSimulatedDevice()
    ARKitTestHook.installSimulatedDevice(cameraAuthorized: false)
    defer { ARKitTestHook.removeSimulatedDevice() }
    let session = ARSession()
    let probe = ARKitSessionProbe()
    session.delegate = probe
    session.run(ARWorldTrackingConfiguration())
    arkitRequire(probe.failures == [.cameraUnauthorized], "cameraUnauthorized")
    arkitRequire(session.currentFrame == nil, "no frame when unauthorized")
}

func testSessionSimulatedRunAndDelegateOrder() {
    ARKitTestHook.removeSimulatedDevice()
    ARKitTestHook.installSimulatedDevice()
    defer { ARKitTestHook.removeSimulatedDevice() }

    let world = ARWorldTrackingConfiguration()
    world.planeDetection = [.horizontal]
    world.isLightEstimationEnabled = true
    let session = ARSession()
    let probe = ARKitSessionProbe()
    session.delegate = probe
    session.run(world, options: [.resetTracking, .removeExistingAnchors])
    arkitRequire(probe.failures.isEmpty, "simulated run succeeds")
    arkitRequire(session.currentFrame != nil, "currentFrame")
    arkitRequire(session.currentFrame!.camera.trackingState == .normal, "tracking")
    arkitRequire(session.currentFrame!.anchors.contains { $0 is ARPlaneAnchor }, "plane added")
    arkitRequire(probe.order.first == "frame", "frame first")
    arkitRequire(probe.order.contains("add"), "didAdd")
    arkitRequire(probe.trackingStates.contains(.normal), "tracking callback")
    arkitRequire(session.currentFrame!.lightEstimate?.ambientIntensity == 1000, "light")
    arkitRequire(session.configuration === world || session.configuration != nil, "configuration")
    _ = session.delegateQueue
}

func testSessionAddRemoveAnchorsAndPause() {
    ARKitTestHook.removeSimulatedDevice()
    ARKitTestHook.installSimulatedDevice()
    defer { ARKitTestHook.removeSimulatedDevice() }

    let session = ARSession()
    let probe = ARKitSessionProbe()
    session.delegate = probe
    session.run(ARWorldTrackingConfiguration())
    let later = ARAnchor(name: "later", transform: .identity)
    session.add(anchor: later)
    arkitRequire(session.currentFrame!.anchors.contains { $0.name == "later" }, "user anchor")
    session.remove(anchor: later)
    arkitRequire(!session.currentFrame!.anchors.contains { $0.name == "later" }, "removed")
    arkitRequire(probe.removed.contains { $0.contains { $0.name == "later" } }, "didRemove")
    session.setWorldOrigin(relativeTransform: simd_float4x4.translation(simd_float3(1, 0, 0)))
    arkitRequire(session.currentFrame != nil, "frame after origin")
    session.pause()
    arkitRequire(session.currentFrame != nil, "pause keeps last frame")
}

func testSessionCollaborationUpdate() {
    let session = ARSession()
    let data = ARSession.CollaborationData(priority: .optional)
    arkitRequire(data.priority == .optional, "priority")
    session.update(with: ARSession.CollaborationData(priority: .critical))
    arkitRequire(ARSession.CollaborationData.supportsSecureCoding, "secure coding")
}

func testSessionObserverDefaultMethods() {
    let session = ARSession()
    let empty = EmptySessionDelegate()
    empty.session(session, cameraDidChangeTrackingState: ARCamera())
    empty.session(session, didChange: ARGeoTrackingStatus())
    empty.session(session, didFailWithError: ARError(.requestFailed))
    empty.session(session, didOutputCollaborationData: ARSession.CollaborationData(priority: .optional))
    empty.session(session, didOutputAudioSampleBuffer: CMSampleBuffer())
    empty.sessionInterruptionEnded(session)
    arkitRequire(!empty.sessionShouldAttemptRelocalization(session), "relocalization default")
    empty.sessionWasInterrupted(session)
    empty.session(session, didAdd: [])
    empty.session(session, didRemove: [])
    empty.session(session, didUpdate: [ARAnchor]())
    empty.session(session, didUpdate: ARFrame())
}
