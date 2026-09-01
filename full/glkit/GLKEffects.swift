import Foundation

public protocol GLKNamedEffect {
    func prepareToDraw()
}

open class GLKEffectProperty: NSObject {}

open class GLKEffectPropertyTransform: GLKEffectProperty {
    open var modelviewMatrix: GLKMatrix4 = GLKMatrix4Identity
    open var projectionMatrix: GLKMatrix4 = GLKMatrix4Identity

    open var normalMatrix: GLKMatrix3 {
        var invertible = false
        let inverted = GLKMatrix3Invert(GLKMatrix4GetMatrix3(modelviewMatrix), &invertible)
        return invertible ? GLKMatrix3Transpose(inverted) : GLKMatrix3Identity
    }
}

open class GLKEffectPropertyLight: GLKEffectProperty {
    open var enabled: GLboolean = GL_FALSE
    open var position: GLKVector4 = GLKVector4Make(0, 0, 1, 0)
    open var ambientColor: GLKVector4 = GLKVector4Make(0, 0, 0, 1)
    open var diffuseColor: GLKVector4 = GLKVector4Make(1, 1, 1, 1)
    open var specularColor: GLKVector4 = GLKVector4Make(1, 1, 1, 1)
    open var spotDirection: GLKVector3 = GLKVector3Make(0, 0, -1)
    open var spotExponent: GLfloat = 0
    open var spotCutoff: GLfloat = 180
    open var constantAttenuation: GLfloat = 1
    open var linearAttenuation: GLfloat = 0
    open var quadraticAttenuation: GLfloat = 0
    open var transform: GLKEffectPropertyTransform = GLKEffectPropertyTransform()
}

open class GLKEffectPropertyMaterial: GLKEffectProperty {
    open var ambientColor: GLKVector4 = GLKVector4Make(0.2, 0.2, 0.2, 1)
    open var diffuseColor: GLKVector4 = GLKVector4Make(0.8, 0.8, 0.8, 1)
    open var specularColor: GLKVector4 = GLKVector4Make(0, 0, 0, 1)
    open var emissiveColor: GLKVector4 = GLKVector4Make(0, 0, 0, 1)
    open var shininess: GLfloat = 0
}

open class GLKEffectPropertyTexture: GLKEffectProperty {
    open var enabled: GLboolean = GL_FALSE
    open var name: GLuint = 0
    open var target: GLKTextureTarget = .target2D
    open var envMode: GLKTextureEnvMode = .modulate
}

open class GLKEffectPropertyFog: GLKEffectProperty {
    open var enabled: GLboolean = GL_FALSE
    open var mode: GLint = GLKFogMode.exp.rawValue
    open var color: GLKVector4 = GLKVector4Make(0, 0, 0, 0)
    open var density: GLfloat = 1
    open var start: GLfloat = 0
    open var end: GLfloat = 1
}

open class GLKBaseEffect: NSObject, GLKNamedEffect {
    open var colorMaterialEnabled: GLboolean = GL_FALSE
    open var lightModelTwoSided: GLboolean = GL_FALSE
    open var useConstantColor: GLboolean = GL_TRUE
    open var lightingType: GLKLightingType = .perVertex
    open var lightModelAmbientColor: GLKVector4 = GLKVector4Make(0.2, 0.2, 0.2, 1)
    open var constantColor: GLKVector4 = GLKVector4Make(1, 1, 1, 1)
    open var label: String?
    open var textureOrder: [GLKEffectPropertyTexture]?

    public let transform = GLKEffectPropertyTransform()
    public let light0 = GLKEffectPropertyLight()
    public let light1: GLKEffectPropertyLight = {
        let light = GLKEffectPropertyLight()
        light.diffuseColor = GLKVector4Make(0, 0, 0, 1)
        light.specularColor = GLKVector4Make(0, 0, 0, 1)
        return light
    }()
    public let light2: GLKEffectPropertyLight = {
        let light = GLKEffectPropertyLight()
        light.diffuseColor = GLKVector4Make(0, 0, 0, 1)
        light.specularColor = GLKVector4Make(0, 0, 0, 1)
        return light
    }()
    public let material = GLKEffectPropertyMaterial()
    public let texture2d0 = GLKEffectPropertyTexture()
    public let texture2d1 = GLKEffectPropertyTexture()
    public let fog = GLKEffectPropertyFog()

    /// Linux has no GLKit shader compiler or current EAGL context. This is a
    /// documented no-op rather than a fabricated GL program bind.
    open func prepareToDraw() {}
}

open class GLKReflectionMapEffect: GLKBaseEffect {
    open var matrix: GLKMatrix3 = GLKMatrix3Identity
    public let textureCubeMap: GLKEffectPropertyTexture = {
        let texture = GLKEffectPropertyTexture()
        texture.target = .targetCubeMap
        return texture
    }()

    open override func prepareToDraw() {}
}

open class GLKSkyboxEffect: NSObject, GLKNamedEffect {
    open var center: GLKVector3 = GLKVector3Make(0, 0, 0)
    open var xSize: GLfloat = 1
    open var ySize: GLfloat = 1
    open var zSize: GLfloat = 1
    open var label: String?
    public let transform = GLKEffectPropertyTransform()
    public let textureCubeMap: GLKEffectPropertyTexture = {
        let texture = GLKEffectPropertyTexture()
        texture.target = .targetCubeMap
        return texture
    }()

    open func prepareToDraw() {}

    /// No GPU skybox is emitted on Linux.
    open func draw() {}
}
