import Foundation
import ModelIO

func testCameraProjection() {
    let camera = MDLCamera()
    camera.projection = .perspective
    camera.fieldOfView = 60
    camera.sensorAspect = 1.5
    let perspective = camera.projectionMatrix
    mdlCheck(perspective.columns.0.x != 0, "persp x")
    camera.projection = .orthographic
    let ortho = camera.projectionMatrix
    mdlCheck(ortho.columns.3.w == 1, "ortho w")
}

func testCameraLookAndRay() {
    let camera = MDLCamera()
    camera.look(at: SIMD3(0, 0, 0), from: SIMD3(0, 0, 5))
    mdlCheck(camera.transform != nil, "look from")
    camera.look(at: SIMD3(0, 0, -1))
    let box = MDLAxisAlignedBoundingBox(maxBounds: SIMD3(1, 1, 1), minBounds: SIMD3(-1, -1, -1))
    camera.frameBoundingBox(box, setNearAndFar: true)
    mdlCheck(camera.farVisibilityDistance > camera.nearVisibilityDistance, "framed")
    let ray = camera.ray(to: SIMD2<Int32>(50, 50), forViewPort: SIMD2<Int32>(100, 100))
    let rayLength = sqrt(ray.x * ray.x + ray.y * ray.y + ray.z * ray.z)
    mdlCheck(rayLength > 0, "ray")
    camera.apertureBladeCount = 6
    let kernel = camera.bokehKernel(withSize: SIMD2<Int32>(16, 16))
    mdlCheck(kernel.dimensions.x == 16, "bokeh")
}

func testCameraProperties() {
    let camera = MDLCamera()
    camera.nearVisibilityDistance = 0.2
    camera.farVisibilityDistance = 500
    camera.fieldOfView = 45
    camera.focalLength = 35
    camera.focusDistance = 3
    camera.fStop = 2.8
    camera.apertureBladeCount = 7
    camera.maximumCircleOfConfusion = 0.1
    camera.shutterOpenInterval = 0.01
    camera.barrelDistortion = 0.1
    camera.opticalVignetting = 0.2
    camera.chromaticAberration = 0.05
    camera.fisheyeDistortion = 0
    camera.worldToMetersConversionScale = 1
    camera.sensorVerticalAperture = 24
    camera.sensorAspect = 1.77
    camera.sensorEnlargement = SIMD2(1, 1)
    camera.sensorShift = SIMD2(0, 0)
    camera.flash = SIMD3(1, 1, 1)
    camera.exposure = SIMD3(1, 1, 1)
    camera.exposureCompression = SIMD2(1, 0)
    mdlCheck(camera.focalLength == 35, "focal")
    mdlCheck(camera.fStop == 2.8, "fstop")
    mdlCheck(camera.sensorAspect == 1.77, "aspect")
}

func testStereoscopicCamera() {
    let camera = MDLStereoscopicCamera()
    camera.interPupillaryDistance = 65
    camera.overlap = 0.1
    camera.leftVergence = 0.01
    camera.rightVergence = -0.01
    _ = camera.leftViewMatrix
    _ = camera.rightViewMatrix
    _ = camera.leftProjectionMatrix
    _ = camera.rightProjectionMatrix
    mdlCheck(camera.interPupillaryDistance == 65, "ipd")
    mdlCheck(camera.overlap == 0.1, "overlap")
}
