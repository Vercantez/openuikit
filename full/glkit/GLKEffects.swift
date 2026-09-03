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
    /// GLES `GLboolean` width. Apple default RGBA values are unobserved.
    open var enabled: UInt8 = 0
    open var position: GLKVector4 = GLKVector4Make(0, 0, 0, 0)
    open var ambientColor: GLKVector4 = GLKVector4Make(0, 0, 0, 0)
    open var diffuseColor: GLKVector4 = GLKVector4Make(0, 0, 0, 0)
    open var specularColor: GLKVector4 = GLKVector4Make(0, 0, 0, 0)
    open var spotDirection: GLKVector3 = GLKVector3Make(0, 0, 0)
    open var spotExponent: Float = 0
    open var spotCutoff: Float = 0
    open var constantAttenuation: Float = 0
    open var linearAttenuation: Float = 0
    open var quadraticAttenuation: Float = 0
    open var transform: GLKEffectPropertyTransform = GLKEffectPropertyTransform()
}

open class GLKEffectPropertyMaterial: GLKEffectProperty {
    open var ambientColor: GLKVector4 = GLKVector4Make(0, 0, 0, 0)
    open var diffuseColor: GLKVector4 = GLKVector4Make(0, 0, 0, 0)
    open var specularColor: GLKVector4 = GLKVector4Make(0, 0, 0, 0)
    open var emissiveColor: GLKVector4 = GLKVector4Make(0, 0, 0, 0)
    open var shininess: Float = 0
}

open class GLKEffectPropertyTexture: GLKEffectProperty {
    open var enabled: UInt8 = 0
    open var name: UInt32 = 0
    open var target: GLKTextureTarget = .target2D
    open var envMode: GLKTextureEnvMode = .replace
}

open class GLKEffectPropertyFog: GLKEffectProperty {
    open var enabled: UInt8 = 0
    open var mode: Int32 = 0
    open var color: GLKVector4 = GLKVector4Make(0, 0, 0, 0)
    open var density: Float = 0
    open var start: Float = 0
    open var end: Float = 0
}

open class GLKBaseEffect: NSObject, GLKNamedEffect {
    open var colorMaterialEnabled: UInt8 = 0
    open var lightModelTwoSided: UInt8 = 0
    open var useConstantColor: UInt8 = 0
    open var lightingType: GLKLightingType = .perVertex
    open var lightModelAmbientColor: GLKVector4 = GLKVector4Make(0, 0, 0, 0)
    open var constantColor: GLKVector4 = GLKVector4Make(0, 0, 0, 0)
    open var label: String?
    open var textureOrder: [GLKEffectPropertyTexture]?

    public let transform = GLKEffectPropertyTransform()
    public let light0 = GLKEffectPropertyLight()
    public let light1 = GLKEffectPropertyLight()
    public let light2 = GLKEffectPropertyLight()
    public let material = GLKEffectPropertyMaterial()
    public let texture2d0 = GLKEffectPropertyTexture()
    public let texture2d1 = GLKEffectPropertyTexture()
    public let fog = GLKEffectPropertyFog()

    /// No GLKit shader compiler or current EAGL context is available here.
    open func prepareToDraw() {}
}

open class GLKReflectionMapEffect: GLKBaseEffect {
    open var matrix: GLKMatrix3 = GLKMatrix3Identity
    public let textureCubeMap = GLKEffectPropertyTexture()

    open override func prepareToDraw() {}
}

open class GLKSkyboxEffect: NSObject, GLKNamedEffect {
    open var center: GLKVector3 = GLKVector3Make(0, 0, 0)
    open var xSize: Float = 0
    open var ySize: Float = 0
    open var zSize: Float = 0
    open var label: String?
    public let transform = GLKEffectPropertyTransform()
    public let textureCubeMap = GLKEffectPropertyTexture()

    open func prepareToDraw() {}

    open func draw() {}
}
