#if canImport(OpenGLES)
@_exported import OpenGLES
#endif
import CoreFoundation
import Foundation

/// Linux starting point for Apple's public `GLKit` module.
///
/// Vector, matrix, quaternion, and matrix-stack math follows the public
/// iPhoneOS 26.1 GLKit headers (column-major, matching the inline C). This
/// isolated compile can import Foundation only. Guest `OpenGLES`, `UIKit`,
/// `ModelIO`, and `CoreGraphics` modules are not on the search path, and
/// GLKit does not define lookalike `EAGL*`, `UIView`, `CGImage`, `UIImage`,
/// or `MDL*` types. View, texture-upload, and mesh-upload APIs that name
/// those nominal types are compiled only when the real modules are
/// importable (`#if canImport`).
///
/// GLES C typedef names (`GLboolean`, `GLfloat`, `GL_TEXTURE_2D`, …) are
/// not redeclared here. When OpenGLES is importable it is re-exported;
/// otherwise CPU-side storage uses the same C widths (`UInt8`, `Float`,
/// `Int32`, `UInt32`).

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

/// Identifier-as-string constants. Exact Apple NSString payloads are unobserved.
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
