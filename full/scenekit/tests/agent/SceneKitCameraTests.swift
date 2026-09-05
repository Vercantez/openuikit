import Foundation
import SceneKit

func testCameraProjection() {
    let cam = SCNCamera()
    cam.fieldOfView = 90
    cam.zNear = 1
    cam.zFar = 100
    let persp = cam.projectionTransform(withViewportSize: CGSize(width: 100, height: 100))
    let f = 1 / tan(Float.pi / 4)
    precondition(abs(persp.m11 - f) < 1e-4)
    precondition(abs(persp.m22 - f) < 1e-4)
    precondition(abs(persp.m34 + 1) < 1e-4)
    cam.usesOrthographicProjection = true
    cam.orthographicScale = 2
    let ortho = cam.projectionTransform(withViewportSize: CGSize(width: 200, height: 100))
    precondition(abs(ortho.m11 - 0.25) < 1e-4)
    precondition(abs(ortho.m22 - 0.5) < 1e-4)
}

func testCameraStores() {
    let cam = SCNCamera()
    cam.wantsHDR = true
    cam.fStop = 2.8
    cam.focalLength = 50
    cam.sensorHeight = 24
    cam.automaticallyAdjustsZRange = false
    cam.projectionDirection = .vertical
    cam.wantsExposureAdaptation = false
    cam.exposureOffset = 0
    cam.averageGray = 0.18
    cam.whitePoint = 1
    cam.minimumExposure = -15
    cam.maximumExposure = 15
    cam.contrast = 0
    cam.saturation = 0
    cam.bloomIntensity = 0
    cam.bloomThreshold = 1
    cam.bloomBlurRadius = 3
    cam.vignettingIntensity = 0
    cam.motionBlurIntensity = 0
    cam.wantsDepthOfField = false
    cam.focusDistance = 2.5
    cam.aperture = 0.125
    cam.apertureBladeCount = 6
    cam.screenSpaceAmbientOcclusionIntensity = 0
    cam.grainIntensity = 0
    cam.whiteBalanceTemperature = 0
    cam.xFov = 0
    cam.yFov = 0
    cam.categoryBitMask = 1
    cam.name = "cam"
    _ = cam.colorGrading
    _ = cam.projectionTransform
    precondition(cam.wantsHDR)
}
