import Foundation
@_spi(OpenUIKitHost) import GLKit

func glkCheck(_ condition: Bool, _ message: String) {
    precondition(condition, message)
}

func glkNear(_ a: Float, _ b: Float, eps: Float = 1e-4) -> Bool {
    abs(a - b) < eps
}

func glkVec2Near(_ a: GLKVector2, _ b: GLKVector2, eps: Float = 1e-4) -> Bool {
    glkNear(a.x, b.x, eps: eps) && glkNear(a.y, b.y, eps: eps)
}

func glkVec3Near(_ a: GLKVector3, _ b: GLKVector3, eps: Float = 1e-4) -> Bool {
    glkNear(a.x, b.x, eps: eps) && glkNear(a.y, b.y, eps: eps) && glkNear(a.z, b.z, eps: eps)
}

func glkVec4Near(_ a: GLKVector4, _ b: GLKVector4, eps: Float = 1e-4) -> Bool {
    glkNear(a.x, b.x, eps: eps)
        && glkNear(a.y, b.y, eps: eps)
        && glkNear(a.z, b.z, eps: eps)
        && glkNear(a.w, b.w, eps: eps)
}

func glkQuatNear(_ a: GLKQuaternion, _ b: GLKQuaternion, eps: Float = 1e-4) -> Bool {
    glkNear(a.x, b.x, eps: eps)
        && glkNear(a.y, b.y, eps: eps)
        && glkNear(a.z, b.z, eps: eps)
        && glkNear(a.w, b.w, eps: eps)
}

func glkHashAndRaw<T: Hashable & RawRepresentable>(_ value: T, expected: T.RawValue)
where T.RawValue: Equatable {
    glkCheck(value.rawValue == expected, "rawValue \(expected)")
    glkCheck(T(rawValue: expected) == value, "rawValue init \(expected)")
    glkCheck(T(rawValue: expected) != nil, "rawValue init non-nil")
    var hasher = Hasher()
    value.hash(into: &hasher)
    _ = value.hashValue
}

func testGLKFogMode() {
    glkCheck(GLKFogMode.exp != .exp2, "GLKFogMode !=")
    glkCheck(GLKFogMode.linear != .exp, "GLKFogMode linear !=")
    glkHashAndRaw(GLKFogMode.exp, expected: 0)
    glkHashAndRaw(GLKFogMode.exp2, expected: 1)
    glkHashAndRaw(GLKFogMode.linear, expected: 2)
}

func testGLKLightingType() {
    glkCheck(GLKLightingType.perVertex != .perPixel, "GLKLightingType !=")
    glkHashAndRaw(GLKLightingType.perVertex, expected: 0)
    glkHashAndRaw(GLKLightingType.perPixel, expected: 1)
}

func testGLKTextureEnvMode() {
    glkCheck(GLKTextureEnvMode.replace != .modulate, "GLKTextureEnvMode !=")
    glkCheck(GLKTextureEnvMode.decal != .replace, "GLKTextureEnvMode decal")
    glkHashAndRaw(GLKTextureEnvMode.replace, expected: 0)
    glkHashAndRaw(GLKTextureEnvMode.modulate, expected: 1)
    glkHashAndRaw(GLKTextureEnvMode.decal, expected: 2)
}

func testGLKTextureInfoAlphaState() {
    glkCheck(GLKTextureInfoAlphaState.none != .premultiplied, "alpha state !=")
    glkHashAndRaw(GLKTextureInfoAlphaState.none, expected: 0)
    glkHashAndRaw(GLKTextureInfoAlphaState.nonPremultiplied, expected: 1)
    glkHashAndRaw(GLKTextureInfoAlphaState.premultiplied, expected: 2)
}

func testGLKTextureInfoOrigin() {
    glkCheck(GLKTextureInfoOrigin.unknown != .topLeft, "origin !=")
    glkHashAndRaw(GLKTextureInfoOrigin.unknown, expected: 0)
    glkHashAndRaw(GLKTextureInfoOrigin.topLeft, expected: 1)
    glkHashAndRaw(GLKTextureInfoOrigin.bottomLeft, expected: 2)
}

func testGLKTextureTarget() {
    glkCheck(GLKTextureTarget.target2D != .targetCubeMap, "target !=")
    glkHashAndRaw(GLKTextureTarget.target2D, expected: 0x0DE1)
    glkHashAndRaw(GLKTextureTarget.targetCubeMap, expected: 0x8513)
    glkHashAndRaw(GLKTextureTarget.targetCt, expected: 2)
}

func testGLKVertexAttrib() {
    glkCheck(GLKVertexAttrib.position != .normal, "attrib !=")
    glkHashAndRaw(GLKVertexAttrib.position, expected: 0)
    glkHashAndRaw(GLKVertexAttrib.normal, expected: 1)
    glkHashAndRaw(GLKVertexAttrib.color, expected: 2)
    glkHashAndRaw(GLKVertexAttrib.texCoord0, expected: 3)
    glkHashAndRaw(GLKVertexAttrib.texCoord1, expected: 4)
}

func testGLKViewDrawableColorFormat() {
    glkCheck(GLKViewDrawableColorFormat.RGBA8888 != .RGB565, "color format !=")
    glkHashAndRaw(GLKViewDrawableColorFormat.RGBA8888, expected: 0)
    glkHashAndRaw(GLKViewDrawableColorFormat.RGB565, expected: 1)
    glkHashAndRaw(GLKViewDrawableColorFormat.SRGBA8888, expected: 2)
}

func testGLKViewDrawableDepthFormat() {
    glkCheck(GLKViewDrawableDepthFormat.formatNone != .format16, "depth !=")
    glkHashAndRaw(GLKViewDrawableDepthFormat.formatNone, expected: 0)
    glkHashAndRaw(GLKViewDrawableDepthFormat.format16, expected: 1)
    glkHashAndRaw(GLKViewDrawableDepthFormat.format24, expected: 2)
}

func testGLKViewDrawableMultisample() {
    glkCheck(GLKViewDrawableMultisample.multisampleNone != .multisample4X, "msaa !=")
    glkHashAndRaw(GLKViewDrawableMultisample.multisampleNone, expected: 0)
    glkHashAndRaw(GLKViewDrawableMultisample.multisample4X, expected: 1)
}

func testGLKViewDrawableStencilFormat() {
    glkCheck(GLKViewDrawableStencilFormat.formatNone != .format8, "stencil !=")
    glkHashAndRaw(GLKViewDrawableStencilFormat.formatNone, expected: 0)
    glkHashAndRaw(GLKViewDrawableStencilFormat.format8, expected: 1)
}
