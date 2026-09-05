import Foundation
import ARKit

func testCameraProjectionAndViewMatrix() {
    let camera = ARCamera(
        trackingState: .normal,
        transform: .identity,
        imageResolution: CGSize(width: 640, height: 480),
        intrinsics: ARSimulatedCameraDefaults.intrinsics
    )
    arkitRequire(camera.imageResolution.width == 640, "width")
    arkitRequire(arkitAlmostEqual(camera.intrinsics.columns.0.x, 640), "fx")
    arkitRequire(arkitAlmostEqual(camera.intrinsics.columns.2.x, 320), "cx")
    let projection = camera.projectionMatrix(
        for: UIInterfaceOrientation.landscapeRight,
        viewportSize: CGSize(width: 640, height: 480),
        zNear: 0.001,
        zFar: 1000
    )
    arkitRequire(arkitAlmostEqual(projection.columns.0.x, 2), "m00")
    arkitRequire(arkitAlmostEqual(projection.columns.1.y, 2 * 640 / 480), "m11")
    arkitRequire(arkitAlmostEqual(projection.columns.2.x, 1 - 2 * 320 / 640), "m20")
    arkitRequire(arkitAlmostEqual(projection.columns.2.y, 2 * 240 / 480 - 1), "m21")
    arkitRequire(arkitAlmostEqual(projection.columns.2.w, -1), "m23")
    let near: Float = 0.001
    let far: Float = 1000
    arkitRequire(arkitAlmostEqual(projection.columns.2.z, -(far + near) / (far - near)), "m22")
    arkitRequire(arkitAlmostEqual(projection.columns.3.z, -2 * far * near / (far - near)), "m32")
    arkitRequire(camera.viewMatrix(for: UIInterfaceOrientation.landscapeRight) == simd_float4x4.identity, "identity view")
    let portraitView = camera.viewMatrix(for: UIInterfaceOrientation.portrait)
    arkitRequire(arkitAlmostEqual(portraitView.columns.0.x, 0), "portrait X")
    _ = camera.eulerAngles
    _ = camera.projectionMatrix
    _ = camera.exposureDuration
    _ = camera.exposureOffset
    _ = camera.transform
    _ = camera.trackingState
    let projected = camera.projectPoint(
        simd_float3(0, 0, -1),
        orientation: UIInterfaceOrientation.landscapeRight,
        viewportSize: CGSize(width: 640, height: 480)
    )
    arkitRequire(projected.x > 0 && projected.y > 0, "projectPoint")
    _ = camera.unprojectPoint(
        CGPoint(x: 0.5, y: 0.5),
        ontoPlane: simd_float4x4.identity,
        orientation: UIInterfaceOrientation.landscapeRight,
        viewportSize: CGSize(width: 640, height: 480)
    )
    _ = camera.viewMatrix(for: .portraitUpsideDown)
    _ = camera.viewMatrix(for: .landscapeLeft)
    _ = camera.viewMatrix(for: .unknown)
    _ = (camera.copy() as! ARCamera).trackingState
    arkitRequire(ARCamera().trackingState == .notAvailable, "default camera")
}
