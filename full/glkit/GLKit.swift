import CoreFoundation
import Dispatch
import Foundation

/// Linux starting point for Apple's public `GLKit` module.
///
/// Vector, matrix, quaternion, and matrix-stack math follows the public
/// iPhoneOS 26.1 GLKit headers (column-major, matching the inline C). GPU
/// texture upload, shader `prepareToDraw`, drawable binding, and Model I/O
/// mesh upload are fail-closed: they do not fabricate an OpenGL ES context
/// or a successful GPU resource.
///
/// Dependency modules (`OpenGLES`, `UIKit`, `ModelIO`, `CoreGraphics`) are
/// not linked in this isolated compile. Local stand-in types with the same
/// names keep the GLKit signatures source-compatible until those modules
/// are integrated.

public typealias GLboolean = UInt8
public typealias GLbyte = Int8
public typealias GLubyte = UInt8
public typealias GLshort = Int16
public typealias GLushort = UInt16
public typealias GLint = Int32
public typealias GLuint = UInt32
public typealias GLsizei = Int32
public typealias GLenum = UInt32
public typealias GLbitfield = UInt32
public typealias GLfloat = Float
public typealias GLclampf = Float

public let GL_FALSE: GLboolean = 0
public let GL_TRUE: GLboolean = 1

public let GL_BYTE: GLenum = 0x1400
public let GL_UNSIGNED_BYTE: GLenum = 0x1401
public let GL_SHORT: GLenum = 0x1402
public let GL_UNSIGNED_SHORT: GLenum = 0x1403
public let GL_INT: GLenum = 0x1404
public let GL_UNSIGNED_INT: GLenum = 0x1405
public let GL_FLOAT: GLenum = 0x1406
public let GL_HALF_FLOAT: GLenum = 0x140B

public let GL_TEXTURE_2D: GLenum = 0x0DE1
public let GL_TEXTURE_CUBE_MAP: GLenum = 0x8513

public typealias dispatch_queue_t = DispatchQueue
public typealias GLKEffectPropertyPrvPtr = OpaquePointer

public let GLKMatrix3Identity = GLKMatrix3Make(
    1, 0, 0,
    0, 1, 0,
    0, 0, 1
)

public let GLKMatrix4Identity = GLKMatrix4Make(
    1, 0, 0, 0,
    0, 1, 0, 0,
    0, 0, 1, 0,
    0, 0, 0, 1
)

public let GLKQuaternionIdentity = GLKQuaternionMake(0, 0, 0, 1)

public let GLKTextureLoaderApplyPremultiplication = "GLKTextureLoaderApplyPremultiplication"
public let GLKTextureLoaderGenerateMipmaps = "GLKTextureLoaderGenerateMipmaps"
public let GLKTextureLoaderOriginBottomLeft = "GLKTextureLoaderOriginBottomLeft"
public let GLKTextureLoaderGrayscaleAsAlpha = "GLKTextureLoaderGrayscaleAsAlpha"
public let GLKTextureLoaderSRGB = "GLKTextureLoaderSRGB"
public let GLKTextureLoaderErrorDomain = "GLKTextureLoaderErrorDomain"
public let GLKTextureLoaderErrorKey = "GLKTextureLoaderErrorKey"
public let GLKTextureLoaderGLErrorKey = "GLKTextureLoaderGLErrorKey"
public let kGLKModelErrorDomain = "kGLKModelErrorDomain"
public let kGLKModelErrorKey = "kGLKModelErrorKey"

public func NSStringFromGLKVector2(_ vector: GLKVector2) -> String {
    String(format: "{%f, %f}", vector.x, vector.y)
}

public func NSStringFromGLKVector3(_ vector: GLKVector3) -> String {
    String(format: "{%f, %f, %f}", vector.x, vector.y, vector.z)
}

public func NSStringFromGLKVector4(_ vector: GLKVector4) -> String {
    String(format: "{%f, %f, %f, %f}", vector.x, vector.y, vector.z, vector.w)
}

public func NSStringFromGLKQuaternion(_ quaternion: GLKQuaternion) -> String {
    String(format: "{%f, %f, %f, %f}", quaternion.x, quaternion.y, quaternion.z, quaternion.w)
}

public func NSStringFromGLKMatrix2(_ matrix: GLKMatrix2) -> String {
    String(
        format: "{{%f, %f}, {%f, %f}}",
        matrix.m00, matrix.m01, matrix.m10, matrix.m11
    )
}

public func NSStringFromGLKMatrix3(_ matrix: GLKMatrix3) -> String {
    String(
        format: "{{%f, %f, %f}, {%f, %f, %f}, {%f, %f, %f}}",
        matrix.m00, matrix.m01, matrix.m02,
        matrix.m10, matrix.m11, matrix.m12,
        matrix.m20, matrix.m21, matrix.m22
    )
}

public func NSStringFromGLKMatrix4(_ matrix: GLKMatrix4) -> String {
    String(
        format: "{{%f, %f, %f, %f}, {%f, %f, %f, %f}, {%f, %f, %f, %f}, {%f, %f, %f, %f}}",
        matrix.m00, matrix.m01, matrix.m02, matrix.m03,
        matrix.m10, matrix.m11, matrix.m12, matrix.m13,
        matrix.m20, matrix.m21, matrix.m22, matrix.m23,
        matrix.m30, matrix.m31, matrix.m32, matrix.m33
    )
}
