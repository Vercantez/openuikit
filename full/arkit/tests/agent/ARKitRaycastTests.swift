import Foundation
import ARKit

func testRaycastQueryConstruction() {
    let query = ARRaycastQuery(
        origin: simd_float3(0, 0, 0),
        direction: simd_float3(0, -1, 0),
        allowing: .existingPlaneGeometry,
        alignment: .horizontal
    )
    arkitRequire(query.target == .existingPlaneGeometry, "target")
    arkitRequire(query.targetAlignment == .horizontal, "alignment")
    arkitRequire(query.origin.y == 0, "origin")
    arkitRequire(query.direction.y == -1, "direction")
    let alias = ARRaycastQuery(
        origin: query.origin,
        direction: query.direction,
        allowingTarget: .estimatedPlane,
        alignment: .any
    )
    arkitRequire(alias.target == .estimatedPlane, "allowingTarget")
}

func testSessionRaycastAgainstSimulatedPlane() {
    let plane = arkitMakeHorizontalPlane()
    let session = ARSession()
    session.add(anchor: plane)
    let hitQuery = ARRaycastQuery(
        origin: simd_float3(0, 1, 0),
        direction: simd_float3(0, -1, 0),
        allowing: .existingPlaneGeometry,
        alignment: .horizontal
    )
    let hits = session.raycast(hitQuery)
    arkitRequire(hits.count == 1, "one hit")
    arkitRequire(arkitAlmostEqual(hits[0].worldTransform.columns.3.y, 0), "y=0")
    arkitRequire(hits[0].target == .existingPlaneGeometry, "result target")
    arkitRequire(hits[0].targetAlignment == .horizontal, "result alignment")
    arkitRequire(hits[0].anchor?.identifier == plane.identifier, "anchor")
    _ = hits[0].worldTransform

    let miss = ARRaycastQuery(
        origin: simd_float3(10, 1, 10),
        direction: simd_float3(0, -1, 0),
        allowing: .existingPlaneGeometry,
        alignment: .horizontal
    )
    arkitRequire(session.raycast(miss).isEmpty, "outside extent")

    let infinite = ARRaycastQuery(
        origin: simd_float3(10, 1, 10),
        direction: simd_float3(0, -1, 0),
        allowing: .existingPlaneInfinite,
        alignment: .horizontal
    )
    arkitRequire(!session.raycast(infinite).isEmpty, "infinite plane")

    let estimated = ARRaycastQuery(
        origin: simd_float3(0, 2, 0),
        direction: simd_float3(0, -1, 0),
        allowing: .estimatedPlane,
        alignment: .horizontal
    )
    arkitRequire(session.raycast(estimated).contains { $0.target == .estimatedPlane }, "estimated y=0")
}

func testTrackedRaycastLifecycle() {
    ARKitTestHook.removeSimulatedDevice()
    let idle = ARSession()
    let query = ARRaycastQuery(
        origin: simd_float3(0, 1, 0),
        direction: simd_float3(0, -1, 0),
        allowing: .existingPlaneGeometry,
        alignment: .horizontal
    )
    arkitRequire(idle.trackedRaycast(query, updateHandler: { _ in }) == nil, "nil when not running")

    ARKitTestHook.installSimulatedDevice()
    defer { ARKitTestHook.removeSimulatedDevice() }
    let session = ARSession()
    session.run(ARWorldTrackingConfiguration())
    var trackedResults: [[ARRaycastResult]] = []
    let tracked = session.trackedRaycast(query) { trackedResults.append($0) }
    arkitRequire(tracked != nil, "tracked while running")
    arkitRequire(!trackedResults.isEmpty, "handler fired")
    tracked?.stopTracking()
    session.pause()
    arkitRequire(session.trackedRaycast(query, updateHandler: { _ in }) == nil, "nil when paused")
}

func testFrameHitTestResultTypes() {
    let camera = ARCamera(
        trackingState: .normal,
        transform: ARSimulatedCameraDefaults.transform,
        imageResolution: CGSize(width: 640, height: 480),
        intrinsics: ARSimulatedCameraDefaults.intrinsics
    )
    let plane = arkitMakeHorizontalPlane()
    let frame = ARFrame(anchors: [plane], camera: camera, timestamp: 1)
    let extentHits = frame.hitTest(
        CGPoint(x: 0.5, y: 0.5),
        types: [.existingPlaneUsingExtent, .existingPlaneUsingGeometry, .existingPlane]
    )
    _ = extentHits
    let estimated = frame.hitTest(
        CGPoint(x: 0.5, y: 0.5),
        types: [.estimatedHorizontalPlane, .estimatedVerticalPlane, .featurePoint]
    )
    _ = estimated
    if let hit = extentHits.first {
        _ = hit.type
        _ = hit.distance
        _ = hit.localTransform
        _ = hit.worldTransform
        _ = hit.anchor
    }
}
