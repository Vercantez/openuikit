import Foundation
import ModelIO

final class TestIrradianceSource: NSObject, MDLLightProbeIrradianceDataSource {
    var boundingBox = MDLAxisAlignedBoundingBox(maxBounds: SIMD3(1, 1, 1), minBounds: SIMD3(-1, -1, -1))
    var sphericalHarmonicsLevel: UInt = 1
    func sphericalHarmonicsCoefficients(atPosition position: SIMD3<Float>) -> Data {
        _ = position
        return Data(count: 12)
    }
}

func testLightBasics() {
    let light = MDLLight()
    light.lightType = .directional
    light.colorSpace = "sRGB"
    mdlCheck(light.lightType == .directional, "type")
    mdlCheck(light.colorSpace == "sRGB", "space")
}

func testPhysicallyPlausibleLight() {
    let light = MDLPhysicallyPlausibleLight()
    light.lumens = 800
    light.innerConeAngle = 10
    light.outerConeAngle = 40
    light.attenuationStartDistance = 1
    light.attenuationEndDistance = 20
    light.setColorByTemperature(5600)
    mdlCheck(light.lightType == .point, "default point")
    mdlCheck(light.lumens == 800, "lumens")
    mdlCheck(light.outerConeAngle == 40, "outer")
}

func testAreaLight() {
    let light = MDLAreaLight()
    light.areaRadius = 2
    light.superEllipticPower = SIMD2(2, 4)
    light.aspect = 1.5
    mdlCheck(light.lightType == .discArea, "disc")
    mdlCheck(light.areaRadius == 2, "radius")
}

func testPhotometricLight() {
    mdlCheck(MDLPhotometricLight(iesProfile: URL(fileURLWithPath: "/no/ies")) == nil, "missing ies")
    mdlCheck(MDLPhotometricLight(IESProfile: URL(fileURLWithPath: "/no/ies")) == nil, "IES missing")
    let directory = mdlTempDir()
    try! FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
    let url = directory.appendingPathComponent("lamp.ies")
    try! Data("IES".utf8).write(to: url)
    let light = MDLPhotometricLight(iesProfile: url)!
    light.generateSphericalHarmonics(fromLight: 2)
    mdlCheck(light.sphericalHarmonicsLevel == 2, "sh level")
    mdlCheck(light.sphericalHarmonicsCoefficients != nil, "sh data")
    light.generateCubemap(fromLight: 8)
    mdlCheck(light.lightCubeMap != nil, "cube")
    let tex = light.generateTexture(4)
    mdlCheck(tex.dimensions.x == 4, "texture")
}

func testLightProbe() {
    let probe = MDLLightProbe(reflectiveTexture: nil, irradianceTexture: nil)
    mdlCheck(probe.lightType == .probe, "type")
    probe.generateSphericalHarmonics(fromIrradiance: 1)
    mdlCheck(probe.sphericalHarmonicsLevel == 1, "level")
    mdlCheck(probe.sphericalHarmonicsCoefficients != nil, "coeffs")
    let transform = MDLTransform()
    let located = MDLLightProbe(
        textureSize: 4,
        forLocation: transform,
        lightsToConsider: [],
        objectsToConsider: [],
        reflectiveCubemap: nil,
        irradianceCubemap: nil
    )
    mdlCheck(located != nil, "located probe")
    mdlCheck(located?.reflectiveTexture != nil, "reflective")
    mdlCheck(located?.irradianceTexture != nil, "irradiance")
}

func testIrradianceDataSource() {
    let source = TestIrradianceSource()
    mdlCheck(source.sphericalHarmonicsLevel == 1, "level")
    source.sphericalHarmonicsLevel = 2
    let data = source.sphericalHarmonicsCoefficients(atPosition: SIMD3())
    mdlCheck(data.count == 12, "coeffs")
    mdlCheck(source.boundingBox.maxBounds.x == 1, "box")
}

func testPlaceLightProbes() {
    let source = TestIrradianceSource()
    let probes = MDLAsset.placeLightProbes(withDensity: 2, heuristic: .uniformGrid, using: source)
    mdlCheck(probes.count == 8, "2^3 probes")
}
