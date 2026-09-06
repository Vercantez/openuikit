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
    cam.usesOrthographicProjection = false
    cam.fieldOfView = 90
    cam.zNear = 1
    cam.zFar = 100
    let persp2 = cam.projectionTransform(withViewportSize: CGSize(width: 100, height: 100))
    let n: Float = 1
    let far: Float = 100
    let expectedM33 = -(far + n) / (far - n)
    let expectedM43 = -2 * far * n / (far - n)
    precondition(abs(persp2.m33 - expectedM33) < 1e-4)
    precondition(abs(persp2.m43 - expectedM43) < 1e-4)
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

func testCameraPostProcessStores() {
    let cam = SCNCamera()
    cam.bloomIterationCount = 3
    cam.bloomIterationSpread = 0.5
    cam.colorFringeIntensity = 0.2
    cam.colorFringeStrength = 0.1
    cam.exposureAdaptationBrighteningSpeedFactor = 0.8
    cam.exposureAdaptationDarkeningSpeedFactor = 0.4
    cam.focalBlurRadius = 2
    cam.focalBlurSampleCount = 5
    cam.focalDistance = 8
    cam.focalSize = 1
    cam.grainIsColored = true
    cam.grainScale = 2
    cam.screenSpaceAmbientOcclusionBias = 0.1
    cam.screenSpaceAmbientOcclusionDepthThreshold = 0.5
    cam.screenSpaceAmbientOcclusionNormalThreshold = 0.2
    cam.screenSpaceAmbientOcclusionRadius = 4
    cam.vignettingPower = 1.5
    cam.whiteBalanceTint = 0.3
    precondition(cam.bloomIterationCount == 3)
    precondition(abs(Float(cam.bloomIterationSpread) - 0.5) < 1e-4)
    precondition(cam.grainIsColored)
    precondition(cam.focalBlurSampleCount == 5)
    precondition(abs(Float(cam.whiteBalanceTint) - 0.3) < 1e-4)
}
