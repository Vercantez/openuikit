import Foundation
import SceneKit

func testLightStores() {
    let light = SCNLight()
    light.type = .spot
    light.spotOuterAngle = 60
    light.spotInnerAngle = 0
    light.intensity = 500
    light.color = SCNVector3(1, 1, 1)
    light.temperature = 6500
    light.castsShadow = false
    light.shadowRadius = 3
    light.shadowMode = .forward
    light.shadowBias = 1
    light.zNear = 1
    light.zFar = 100
    light.attenuationStartDistance = 0
    light.attenuationEndDistance = 0
    light.attenuationFalloffExponent = 2
    light.areaType = .rectangle
    light.probeType = .irradiance
    light.probeUpdateType = .never
    light.areaExtents = SIMD3<Float>(2, 1, 0)
    light.parallaxCenterOffset = SIMD3<Float>()
    light.parallaxExtentsFactor = SIMD3<Float>(1, 1, 1)
    light.probeExtents = SIMD3<Float>()
    light.probeOffset = SIMD3<Float>()
    light.categoryBitMask = 1
    light.name = "light"
    _ = light.gobo
    _ = light.probeEnvironment
    _ = light.sphericalHarmonicsCoefficients
    precondition(light.spotOuterAngle == 60)
    precondition(abs(light.areaExtents.x - 2) < 1e-4)
}

func testLightShadowAndAreaStores() {
    let light = SCNLight()
    light.iesProfileURL = URL(fileURLWithPath: "/tmp/missing.ies")
    light.areaPolygonVertices = []
    light.automaticallyAdjustsShadowProjection = false
    light.doubleSided = true
    light.drawsArea = true
    light.forcesBackFaceCasters = true
    light.maximumShadowDistance = 50
    light.parallaxCorrectionEnabled = true
    light.sampleDistributedShadowMaps = true
    light.shadowCascadeCount = 3
    light.shadowCascadeSplittingFactor = 0.4
    light.shadowColor = SCNVector4(0, 0, 0, 1)
    light.shadowMapSize = CGSize(width: 512, height: 512)
    light.shadowSampleCount = 8
    precondition(light.doubleSided)
    precondition(light.drawsArea)
    precondition(light.forcesBackFaceCasters)
    precondition(light.shadowCascadeCount == 3)
    precondition(light.iesProfileURL?.path.hasSuffix("missing.ies") == true)
}
