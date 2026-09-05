import Foundation
import SceneKit

func testMaterialLightingAndBlend() {
    let mat = SCNMaterial()
    mat.lightingModel = .phong
    mat.isDoubleSided = true
    mat.blendMode = .add
    mat.transparency = 0.5
    mat.shininess = 32
    mat.cullMode = .back
    mat.fillMode = .fill
    mat.transparencyMode = .aOne
    mat.locksAmbientWithDiffuse = false
    mat.isLitPerPixel = true
    mat.readsFromDepthBuffer = true
    mat.writesToDepthBuffer = true
    mat.fresnelExponent = 0
    mat.diffuse.contents = SCNVector3(1, 0, 0)
    mat.specular.contents = SCNVector3(1, 1, 1)
    mat.ambient.contents = SCNVector3Zero
    mat.emission.contents = SCNVector3Zero
    mat.transparent.contents = SCNVector4(1, 1, 1, 1)
    mat.reflective.contents = SCNVector3Zero
    mat.multiply.contents = SCNVector3(1, 1, 1)
    mat.normal.contents = SCNVector3(0, 0, 1)
    mat.metalness.contents = 0
    mat.roughness.contents = 1
    precondition(mat.isDoubleSided && mat.blendMode == .add)
    _ = mat.selfIllumination
    _ = mat.ambientOcclusion
    _ = mat.displacement
    _ = mat.clearCoat
    _ = mat.clearCoatRoughness
    _ = mat.clearCoatNormal
    let prop = SCNMaterialProperty(contents: SCNVector3(1, 0, 0))
    prop.intensity = 1
    prop.magnificationFilter = .linear
    prop.minificationFilter = .linear
    prop.mipFilter = .nearest
    prop.wrapS = .clamp
    prop.wrapT = .`repeat`
    prop.mappingChannel = 0
    prop.maxAnisotropy = 1
    _ = prop.contentsTransform
    _ = prop.textureComponents
}
