import Foundation
import ARKit

func testFramePropertiesAndDisplayTransform() {
    let camera = ARCamera(
        trackingState: .normal,
        transform: ARSimulatedCameraDefaults.transform,
        imageResolution: CGSize(width: 640, height: 480),
        intrinsics: ARSimulatedCameraDefaults.intrinsics
    )
    let frame = ARFrame(anchors: [arkitMakeHorizontalPlane()], camera: camera, timestamp: 1.5)
    arkitRequire(frame.timestamp == 1.5, "timestamp")
    arkitRequire(frame.anchors.count == 1, "anchors")
    _ = frame.camera
    _ = frame.cameraGrainIntensity
    _ = frame.cameraGrainTexture
    _ = frame.capturedDepthData
    _ = frame.capturedDepthDataTimestamp
    _ = frame.capturedImage.width
    _ = frame.detectedBody
    _ = frame.estimatedDepthData
    _ = frame.exifData
    _ = frame.geoTrackingStatus
    _ = frame.lightEstimate
    _ = frame.rawFeaturePoints
    _ = frame.sceneDepth
    _ = frame.segmentationBuffer
    _ = frame.smoothedSceneDepth
    _ = frame.worldMappingStatus
    _ = frame.displayTransform(for: .portrait, viewportSize: CGSize(width: 100, height: 200))
    _ = frame.displayTransform(for: .portraitUpsideDown, viewportSize: .zero)
    _ = frame.displayTransform(for: .landscapeLeft, viewportSize: .zero)
    _ = frame.displayTransform(for: .landscapeRight, viewportSize: .zero)
    _ = frame.displayTransform(for: .unknown, viewportSize: .zero)
    let query = frame.raycastQuery(from: .zero, allowing: .estimatedPlane, alignment: .horizontal)
    let direction = query.direction
    arkitRequire((direction.x * direction.x + direction.y * direction.y + direction.z * direction.z) > 0.8, "unit ray")
    arkitRequire(ARFrame().hitTest(.zero, types: .featurePoint).isEmpty, "empty hit test")
}

func testLightDepthAndMatte() {
    let light = ARLightEstimate(ambientIntensity: 1000, ambientColorTemperature: 6500)
    arkitRequire(light.ambientIntensity == 1000, "intensity")
    arkitRequire(light.ambientColorTemperature == 6500, "temperature")
    let directional = ARDirectionalLightEstimate()
    _ = directional.primaryLightDirection
    _ = directional.primaryLightIntensity
    _ = directional.sphericalHarmonicsCoefficients
    let depth = ARDepthData()
    _ = depth.confidenceMap
    _ = depth.depthMap
    let status = ARGeoTrackingStatus()
    arkitRequire(status.state == .notAvailable, "geo state")
    _ = status.accuracy
    _ = status.stateReason
    status.encode(with: NSKeyedArchiver(requiringSecureCoding: true))
    let matte = ARMatteGenerator(device: ARKitHostMTLDevice(), matteResolution: .full)
    _ = matte.generateMatte(from: ARFrame(), commandBuffer: ARKitHostMTLCommandBuffer())
    _ = matte.generateDilatedDepth(from: ARFrame(), commandBuffer: ARKitHostMTLCommandBuffer())
}
