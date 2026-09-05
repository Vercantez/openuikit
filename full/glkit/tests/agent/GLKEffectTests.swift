import Foundation
import GLKit

func testGLKBaseEffectStorage() {
    let effect = GLKBaseEffect()
    effect.useConstantColor = 1
    effect.constantColor = GLKVector4Make(0.1, 0.2, 0.3, 1)
    glkCheck(effect.useConstantColor == 1, "useConstantColor")
    glkCheck(effect.constantColor.y == 0.2, "constantColor")
    effect.colorMaterialEnabled = 1
    effect.lightModelTwoSided = 1
    effect.label = "base"
    glkCheck(effect.colorMaterialEnabled == 1, "colorMaterialEnabled")
    glkCheck(effect.lightModelTwoSided == 1, "lightModelTwoSided")
    glkCheck(effect.label == "base", "label")
    effect.lightingType = .perPixel
    glkCheck(effect.lightingType == .perPixel, "lightingType")
    effect.lightModelAmbientColor = GLKVector4Make(0.2, 0.2, 0.2, 1)
    glkCheck(effect.lightModelAmbientColor.x == 0.2, "lightModelAmbientColor")
    effect.transform.modelviewMatrix = GLKMatrix4MakeTranslation(0, 1, 0)
    glkCheck(effect.transform.modelviewMatrix.m31 == 1, "modelviewMatrix")
    effect.transform.projectionMatrix = GLKMatrix4MakeOrtho(-1, 1, -1, 1, -1, 1)
    glkCheck(effect.transform.projectionMatrix.m00 == 1, "projectionMatrix")
    let normal = effect.transform.normalMatrix
    glkCheck(normal.m00 == 1 && normal.m11 == 1 && normal.m22 == 1, "normalMatrix")
    _ = GLKEffectProperty()
}

func testGLKEffectLights() {
    let effect = GLKBaseEffect()
    effect.light0.enabled = 1
    effect.light0.position = GLKVector4Make(1, 2, 3, 1)
    glkCheck(effect.light0.enabled == 1, "light0.enabled")
    glkCheck(effect.light0.position.z == 3, "light0.position")
    effect.light1.diffuseColor = GLKVector4Make(0.5, 0.25, 0.125, 1)
    glkCheck(effect.light1.diffuseColor.x == 0.5, "light1.diffuseColor")
    effect.light2.ambientColor = GLKVector4Make(0.1, 0, 0, 1)
    effect.light2.specularColor = GLKVector4Make(1, 1, 1, 1)
    effect.light2.spotDirection = GLKVector3Make(0, -1, 0)
    effect.light2.spotExponent = 4
    effect.light2.spotCutoff = 45
    effect.light2.constantAttenuation = 1
    effect.light2.linearAttenuation = 0.1
    effect.light2.quadraticAttenuation = 0.01
    effect.light2.transform.modelviewMatrix = GLKMatrix4Identity
    glkCheck(effect.light2.ambientColor.x == 0.1, "light2.ambient")
    glkCheck(effect.light2.specularColor.y == 1, "light2.specular")
    glkCheck(effect.light2.spotDirection.y == -1, "spotDirection")
    glkCheck(effect.light2.spotExponent == 4, "spotExponent")
    glkCheck(effect.light2.spotCutoff == 45, "spotCutoff")
    glkCheck(effect.light2.constantAttenuation == 1, "const att")
    glkCheck(effect.light2.linearAttenuation == 0.1, "lin att")
    glkCheck(effect.light2.quadraticAttenuation == 0.01, "quad att")
    glkCheck(effect.light2.transform.modelviewMatrix.m00 == 1, "light transform")
}

func testGLKEffectMaterialFogTexture() {
    let effect = GLKBaseEffect()
    effect.material.shininess = 32
    effect.material.ambientColor = GLKVector4Make(0.2, 0, 0, 1)
    effect.material.diffuseColor = GLKVector4Make(0.3, 0, 0, 1)
    effect.material.specularColor = GLKVector4Make(0.4, 0, 0, 1)
    effect.material.emissiveColor = GLKVector4Make(0.5, 0, 0, 1)
    glkCheck(effect.material.shininess == 32, "shininess")
    glkCheck(effect.material.ambientColor.x == 0.2, "material ambient")
    glkCheck(effect.material.diffuseColor.x == 0.3, "material diffuse")
    glkCheck(effect.material.specularColor.x == 0.4, "material specular")
    glkCheck(effect.material.emissiveColor.x == 0.5, "material emissive")
    effect.fog.enabled = 1
    effect.fog.density = 0.25
    effect.fog.mode = GLKFogMode.exp2.rawValue
    effect.fog.start = 1
    effect.fog.end = 10
    effect.fog.color = GLKVector4Make(0.1, 0.1, 0.1, 1)
    glkCheck(effect.fog.enabled == 1 && effect.fog.density == 0.25, "fog")
    glkCheck(effect.fog.mode == GLKFogMode.exp2.rawValue, "fog.mode")
    glkCheck(effect.fog.start == 1 && effect.fog.end == 10, "fog range")
    glkCheck(effect.fog.color.x == 0.1, "fog.color")
    effect.texture2d0.enabled = 1
    effect.texture2d0.target = .target2D
    effect.texture2d0.name = 7
    effect.texture2d0.envMode = .modulate
    glkCheck(effect.texture2d0.enabled == 1, "texture2d0.enabled")
    glkCheck(effect.texture2d0.name == 7, "texture2d0.name")
    glkCheck(effect.texture2d0.envMode == .modulate, "envMode")
    effect.texture2d1.enabled = 1
    effect.texture2d1.target = .target2D
    glkCheck(effect.texture2d1.enabled == 1, "texture2d1")
    effect.textureOrder = [effect.texture2d0, effect.texture2d1]
    glkCheck(effect.textureOrder?.count == 2, "textureOrder")
}

func testGLKSkyboxEffect() {
    let skybox = GLKSkyboxEffect()
    skybox.xSize = 4
    skybox.ySize = 5
    skybox.zSize = 6
    skybox.center = GLKVector3Make(1, 2, 3)
    skybox.label = "sky"
    skybox.textureCubeMap.enabled = 1
    skybox.textureCubeMap.target = .targetCubeMap
    skybox.transform.projectionMatrix = GLKMatrix4Identity
    glkCheck(skybox.xSize == 4 && skybox.ySize == 5 && skybox.zSize == 6, "size")
    glkCheck(skybox.center.y == 2, "center")
    glkCheck(skybox.label == "sky", "label")
    glkCheck(skybox.textureCubeMap.target == .targetCubeMap, "cube map")
    glkCheck(skybox.transform.projectionMatrix.m00 == 1, "transform")
    skybox.prepareToDraw()
    skybox.draw()
}

func testGLKReflectionMapEffect() {
    let reflection = GLKReflectionMapEffect()
    reflection.matrix = GLKMatrix3Identity
    reflection.textureCubeMap.enabled = 1
    reflection.prepareToDraw()
    glkCheck(reflection.matrix.m00 == 1, "matrix")
    glkCheck(reflection.textureCubeMap.enabled == 1, "textureCubeMap")
}

func testGLKNamedEffectPrepareToDraw() {
    let effect: any GLKNamedEffect = GLKBaseEffect()
    effect.prepareToDraw()
    let sky: any GLKNamedEffect = GLKSkyboxEffect()
    sky.prepareToDraw()
    GLKBaseEffect().prepareToDraw()
    GLKReflectionMapEffect().prepareToDraw()
}
