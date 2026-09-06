import Foundation
#if canImport(Glibc)
import Glibc
#endif

enum GLESDetached {
    private static let key = "OpenUIKit.OpenGLES.detachedError"

    static func record(_ error: GLenum) {
        if Thread.current.threadDictionary[key] == nil {
            Thread.current.threadDictionary[key] = NSNumber(value: error)
        }
    }

    static func take() -> GLenum {
        let value = (Thread.current.threadDictionary[key] as? NSNumber)?.uint32Value ?? 0
        Thread.current.threadDictionary[key] = nil
        return value
    }
}

func glesForward(_ body: (GLESState) -> Void) {
    guard let state = EAGLContext.tlsCurrent?.state else {
        GLESDetached.record(glEnum(GL_INVALID_OPERATION))
        return
    }
    body(state)
}

func glesForwardRet<T>(_ fallback: T, _ body: (GLESState) -> T) -> T {
    guard let state = EAGLContext.tlsCurrent?.state else {
        GLESDetached.record(glEnum(GL_INVALID_OPERATION))
        return fallback
    }
    return body(state)
}

public func glGetError() -> GLenum {
    if let state = EAGLContext.tlsCurrent?.state {
        let detached = GLESDetached.take()
        if detached != 0 {
            return detached
        }
        return state.takeError()
    }
    let detached = GLESDetached.take()
    return detached == 0 ? glEnum(GL_INVALID_OPERATION) : detached
}

private struct Mat4 {
    var m: [GLfloat]

    static let identity = Mat4(m: [
        1, 0, 0, 0,
        0, 1, 0, 0,
        0, 0, 1, 0,
        0, 0, 0, 1,
    ])

    static func multiply(_ a: Mat4, _ b: Mat4) -> Mat4 {
        var out = [GLfloat](repeating: 0, count: 16)
        for col in 0..<4 {
            for row in 0..<4 {
                var sum: GLfloat = 0
                for k in 0..<4 {
                    sum += a.m[k * 4 + row] * b.m[col * 4 + k]
                }
                out[col * 4 + row] = sum
            }
        }
        return Mat4(m: out)
    }

    static func translation(_ x: GLfloat, _ y: GLfloat, _ z: GLfloat) -> Mat4 {
        var r = identity
        r.m[12] = x
        r.m[13] = y
        r.m[14] = z
        return r
    }

    static func scale(_ x: GLfloat, _ y: GLfloat, _ z: GLfloat) -> Mat4 {
        var r = identity
        r.m[0] = x
        r.m[5] = y
        r.m[10] = z
        return r
    }

    static func rotation(degrees: GLfloat, x: GLfloat, y: GLfloat, z: GLfloat) -> Mat4 {
        let len = (x * x + y * y + z * z).squareRoot()
        let nx = len == 0 ? 0 : x / len
        let ny = len == 0 ? 0 : y / len
        let nz = len == 0 ? 0 : z / len
        let rad = degrees * GLfloat.pi / 180
        let c = GLfloat(cos(Double(rad)))
        let s = GLfloat(sin(Double(rad)))
        let c1 = 1 - c
        return Mat4(m: [
            nx * nx * c1 + c, ny * nx * c1 + nz * s, nx * nz * c1 - ny * s, 0,
            nx * ny * c1 - nz * s, ny * ny * c1 + c, ny * nz * c1 + nx * s, 0,
            nx * nz * c1 + ny * s, ny * nz * c1 - nx * s, nz * nz * c1 + c, 0,
            0, 0, 0, 1,
        ])
    }

    static func frustum(
        _ l: GLfloat, _ r: GLfloat, _ b: GLfloat, _ t: GLfloat, _ n: GLfloat, _ f: GLfloat
    ) -> Mat4? {
        if n <= 0 || f <= 0 || l == r || b == t || n == f {
            return nil
        }
        return Mat4(m: [
            (2 * n) / (r - l), 0, 0, 0,
            0, (2 * n) / (t - b), 0, 0,
            (r + l) / (r - l), (t + b) / (t - b), -(f + n) / (f - n), -1,
            0, 0, (-2 * f * n) / (f - n), 0,
        ])
    }

    static func ortho(
        _ l: GLfloat, _ r: GLfloat, _ b: GLfloat, _ t: GLfloat, _ n: GLfloat, _ f: GLfloat
    ) -> Mat4? {
        if l == r || b == t || n == f {
            return nil
        }
        return Mat4(m: [
            2 / (r - l), 0, 0, 0,
            0, 2 / (t - b), 0, 0,
            0, 0, -2 / (f - n), 0,
            -(r + l) / (r - l), -(t + b) / (t - b), -(f + n) / (f - n), 1,
        ])
    }
}

private func fixedToFloat(_ value: GLfixed) -> GLfloat {
    GLfloat(value) / 65536.0
}

private final class NameSet {
    private var next: GLuint = 1
    private var live: Set<GLuint> = []

    func generate(_ n: GLsizei, _ ids: UnsafeMutablePointer<GLuint>?) {
        guard n >= 0, let ids else { return }
        if n == 0 { return }
        for i in 0..<Int(n) {
            let name = next
            next += 1
            live.insert(name)
            ids[i] = name
        }
    }

    func remove(_ n: GLsizei, _ ids: UnsafePointer<GLuint>?) {
        guard n >= 0, let ids else { return }
        for i in 0..<Int(n) {
            live.remove(ids[i])
        }
    }

    func contains(_ id: GLuint) -> Bool {
        id != 0 && live.contains(id)
    }

    func ensure(_ id: GLuint) {
        if id != 0 {
            live.insert(id)
            if id >= next {
                next = id + 1
            }
        }
    }
}

private final class BufferObject {
    var storage: UnsafeMutablePointer<UInt8>?
    var count: Int = 0
    var usage: GLenum = 0
    var mapped: Bool = false

    deinit {
        storage?.deallocate()
    }

    func resize(_ size: Int) {
        storage?.deallocate()
        storage = nil
        count = size
        if size > 0 {
            let pointer = UnsafeMutablePointer<UInt8>.allocate(capacity: size)
            pointer.initialize(repeating: 0, count: size)
            storage = pointer
        }
    }
}

private struct TextureObject {
    var minFilter: GLint = GL_NEAREST_MIPMAP_LINEAR
    var magFilter: GLint = GL_LINEAR
    var wrapS: GLint = GL_REPEAT
    var wrapT: GLint = GL_REPEAT
    var width: GLsizei = 0
    var height: GLsizei = 0
    var format: GLenum = 0
}

private struct ShaderObject {
    var type: GLenum
    var source: String = ""
    var deleted: Bool = false
}

private struct ProgramObject {
    var shaders: Set<GLuint> = []
    var linked: Bool = false
    var infoLog: String = "GLSL linker unavailable on this Linux host; link is fail-closed."
}

private struct FramebufferObject {
    var colorTexture: GLuint = 0
    var colorRenderbuffer: GLuint = 0
    var depthRenderbuffer: GLuint = 0
    var stencilRenderbuffer: GLuint = 0
}

private struct RenderbufferObject {
    var internalFormat: GLenum = 0
    var width: GLsizei = 0
    var height: GLsizei = 0
}

private struct SyncObject {
    var condition: GLenum
}

final class GLESState: GLESCommands {
    let api: EAGLRenderingAPI
    private var error: GLenum = 0
    private var enabled: Set<GLenum> = []
    private var clientEnabled: Set<GLenum> = []
    private var hints: [GLenum: GLenum] = [:]

    private var viewport: (GLint, GLint, GLsizei, GLsizei) = (0, 0, 1, 1)
    private var scissor: (GLint, GLint, GLsizei, GLsizei) = (0, 0, 1, 1)
    private var clearColor: (GLfloat, GLfloat, GLfloat, GLfloat) = (0, 0, 0, 0)
    private var clearDepth: GLfloat = 1
    private var clearStencil: GLint = 0
    private var colorMask: (GLboolean, GLboolean, GLboolean, GLboolean) = (1, 1, 1, 1)
    private var depthMask: GLboolean = 1
    private var stencilMaskFront: GLuint = 0xFFFF_FFFF
    private var stencilMaskBack: GLuint = 0xFFFF_FFFF

    private var blendSrcRGB: GLenum = 1
    private var blendDstRGB: GLenum = 0
    private var blendSrcAlpha: GLenum = 1
    private var blendDstAlpha: GLenum = 0
    private var blendEqRGB: GLenum = 0x8006
    private var blendEqAlpha: GLenum = 0x8006
    private var blendColor: (GLfloat, GLfloat, GLfloat, GLfloat) = (0, 0, 0, 0)

    private var cullFaceMode: GLenum = 0x0405
    private var frontFace: GLenum = 0x0901
    private var depthFuncValue: GLenum = 0x0201
    private var depthRange: (GLfloat, GLfloat) = (0, 1)
    private var lineWidth: GLfloat = 1
    private var polygonOffsetFactor: GLfloat = 0
    private var polygonOffsetUnits: GLfloat = 0
    private var sampleCoverageValue: GLfloat = 1
    private var sampleCoverageInvert: GLboolean = 0
    private var unpackAlignment: GLint = 4
    private var packAlignment: GLint = 4

    private var activeTex: GLenum = 0x84C0
    private var currentProgram: GLuint = 0
    private var arrayBuffer: GLuint = 0
    private var elementBuffer: GLuint = 0
    private var framebuffer: GLuint = 0
    private var renderbuffer: GLuint = 0
    private var vertexArray: GLuint = 0
    private var sampler: GLuint = 0
    private var transformFeedback: GLuint = 0
    private var boundTextures: [GLenum: GLuint] = [:]

    private var attribEnabled: Set<GLuint> = []
    private var currentColor: (GLfloat, GLfloat, GLfloat, GLfloat) = (1, 1, 1, 1)
    private var currentNormal: (GLfloat, GLfloat, GLfloat) = (0, 0, 1)

    private var matrixMode: GLenum = 0x1700
    private var modelview: [Mat4] = [.identity]
    private var projection: [Mat4] = [.identity]
    private var textureStack: [Mat4] = [.identity]

    private let buffers = NameSet()
    private let textures = NameSet()
    private let shaders = NameSet()
    private let programs = NameSet()
    private let framebuffers = NameSet()
    private let renderbuffers = NameSet()
    private let vertexArrays = NameSet()
    private let queries = NameSet()
    private let samplers = NameSet()
    private let transformFeedbacks = NameSet()
    private var bufferObjects: [GLuint: BufferObject] = [:]
    private var textureObjects: [GLuint: TextureObject] = [:]
    private var shaderObjects: [GLuint: ShaderObject] = [:]
    private var programObjects: [GLuint: ProgramObject] = [:]
    private var framebufferObjects: [GLuint: FramebufferObject] = [:]
    private var renderbufferObjects: [GLuint: RenderbufferObject] = [:]
    private var syncObjects: [UnsafeMutableRawPointer: SyncObject] = [:]
    private var nextShader: GLuint = 1
    private var nextProgram: GLuint = 1

    private let vendorPtr: UnsafePointer<GLubyte>
    private let rendererPtr: UnsafePointer<GLubyte>
    private let versionPtr: UnsafePointer<GLubyte>
    private let shadingPtr: UnsafePointer<GLubyte>
    private let extensionsPtr: UnsafePointer<GLubyte>

    static let maxTextureSize: GLint = 2048
    static let maxLights: GLint = 8
    static let maxClipPlanes: GLint = 1
    static let maxModelviewStack: GLint = 16
    static let maxProjectionStack: GLint = 2
    static let maxTextureStack: GLint = 2
    static let maxVertexAttribs: GLint = 8
    static let maxTextureUnits: GLint = 8

    init(api: EAGLRenderingAPI) {
        self.api = api
        func intern(_ text: String) -> UnsafePointer<GLubyte> {
            let bytes = Array(text.utf8) + [0]
            let pointer = UnsafeMutablePointer<GLubyte>.allocate(capacity: bytes.count)
            pointer.initialize(from: bytes, count: bytes.count)
            return UnsafePointer(pointer)
        }
        vendorPtr = intern("OpenUIKit")
        rendererPtr = intern("OpenUIKit software GLES")
        versionPtr = intern("OpenGL ES 2.0 OpenUIKit")
        shadingPtr = intern("OpenGL ES GLSL ES 1.00 OpenUIKit")
        extensionsPtr = intern("")
        blendSrcRGB = glEnum(GL_ONE)
        blendDstRGB = glEnum(GL_ZERO)
        blendSrcAlpha = glEnum(GL_ONE)
        blendDstAlpha = glEnum(GL_ZERO)
        blendEqRGB = glEnum(GL_FUNC_ADD)
        blendEqAlpha = glEnum(GL_FUNC_ADD)
        cullFaceMode = glEnum(GL_BACK)
        frontFace = glEnum(GL_CCW)
        depthFuncValue = glEnum(GL_LESS)
        activeTex = glEnum(GL_TEXTURE0)
        matrixMode = glEnum(GL_MODELVIEW)
    }

    func unimplemented() {
        setError(glEnum(GL_INVALID_OPERATION))
    }

    func setError(_ value: GLenum) {
        if error == 0 {
            error = value
        }
    }

    func takeError() -> GLenum {
        let value = error
        error = 0
        return value
    }

    private func currentStack() -> [Mat4] {
        switch matrixMode {
        case glEnum(GL_PROJECTION): return projection
        case glEnum(GL_TEXTURE): return textureStack
        default: return modelview
        }
    }

    private func setCurrentStack(_ stack: [Mat4]) {
        switch matrixMode {
        case glEnum(GL_PROJECTION): projection = stack
        case glEnum(GL_TEXTURE): textureStack = stack
        default: modelview = stack
        }
    }

    private func maxStack() -> Int {
        switch matrixMode {
        case glEnum(GL_PROJECTION): return Int(Self.maxProjectionStack)
        case glEnum(GL_TEXTURE): return Int(Self.maxTextureStack)
        default: return Int(Self.maxModelviewStack)
        }
    }

    private func multiplyCurrent(_ matrix: Mat4) {
        var stack = currentStack()
        stack[stack.count - 1] = Mat4.multiply(stack[stack.count - 1], matrix)
        setCurrentStack(stack)
    }

    // MARK: Enable / viewport / clear

    func glEnable(_ cap: GLenum) {
        enabled.insert(cap)
    }

    func glDisable(_ cap: GLenum) {
        enabled.remove(cap)
    }

    func glIsEnabled(_ cap: GLenum) -> GLboolean {
        enabled.contains(cap) ? 1 : 0
    }

    func glEnableClientState(_ array: GLenum) {
        clientEnabled.insert(array)
    }

    func glDisableClientState(_ array: GLenum) {
        clientEnabled.remove(array)
    }

    func glHint(_ target: GLenum, _ mode: GLenum) {
        hints[target] = mode
    }

    func glViewport(_ x: GLint, _ y: GLint, _ width: GLsizei, _ height: GLsizei) {
        if width < 0 || height < 0 {
            setError(glEnum(GL_INVALID_VALUE))
            return
        }
        viewport = (x, y, width, height)
    }

    func glScissor(_ x: GLint, _ y: GLint, _ width: GLsizei, _ height: GLsizei) {
        if width < 0 || height < 0 {
            setError(glEnum(GL_INVALID_VALUE))
            return
        }
        scissor = (x, y, width, height)
    }

    func glClearColor(_ red: GLfloat, _ green: GLfloat, _ blue: GLfloat, _ alpha: GLfloat) {
        clearColor = (red, green, blue, alpha)
    }

    func glClearColorx(_ red: GLclampx, _ green: GLclampx, _ blue: GLclampx, _ alpha: GLclampx) {
        glClearColor(fixedToFloat(red), fixedToFloat(green), fixedToFloat(blue), fixedToFloat(alpha))
    }

    func glClearDepthf(_ depth: GLclampf) {
        clearDepth = depth
    }

    func glClearDepthx(_ depth: GLclampx) {
        glClearDepthf(fixedToFloat(depth))
    }

    func glClearStencil(_ s: GLint) {
        clearStencil = s
    }

    func glClear(_ mask: GLbitfield) {
        _ = mask
        if framebuffer == 0 {
            setError(glEnum(GL_INVALID_FRAMEBUFFER_OPERATION))
        }
    }

    func glColorMask(_ red: GLboolean, _ green: GLboolean, _ blue: GLboolean, _ alpha: GLboolean) {
        colorMask = (red, green, blue, alpha)
    }

    func glDepthMask(_ flag: GLboolean) {
        depthMask = flag
    }

    func glStencilMask(_ mask: GLuint) {
        stencilMaskFront = mask
        stencilMaskBack = mask
    }

    func glStencilMaskSeparate(_ face: GLenum, _ mask: GLuint) {
        if face == glEnum(GL_FRONT) || face == glEnum(GL_FRONT_AND_BACK) {
            stencilMaskFront = mask
        }
        if face == glEnum(GL_BACK) || face == glEnum(GL_FRONT_AND_BACK) {
            stencilMaskBack = mask
        }
    }

    func glBlendFunc(_ sfactor: GLenum, _ dfactor: GLenum) {
        glBlendFuncSeparate(sfactor, dfactor, sfactor, dfactor)
    }

    func glBlendFuncSeparate(
        _ srcRGB: GLenum, _ dstRGB: GLenum, _ srcAlpha: GLenum, _ dstAlpha: GLenum
    ) {
        blendSrcRGB = srcRGB
        blendDstRGB = dstRGB
        blendSrcAlpha = srcAlpha
        blendDstAlpha = dstAlpha
    }

    func glBlendFuncSeparateOES(
        _ srcRGB: GLenum, _ dstRGB: GLenum, _ srcAlpha: GLenum, _ dstAlpha: GLenum
    ) {
        glBlendFuncSeparate(srcRGB, dstRGB, srcAlpha, dstAlpha)
    }

    func glBlendEquation(_ mode: GLenum) {
        glBlendEquationSeparate(mode, mode)
    }

    func glBlendEquationOES(_ mode: GLenum) {
        glBlendEquation(mode)
    }

    func glBlendEquationSeparate(_ modeRGB: GLenum, _ modeAlpha: GLenum) {
        blendEqRGB = modeRGB
        blendEqAlpha = modeAlpha
    }

    func glBlendEquationSeparateOES(_ modeRGB: GLenum, _ modeAlpha: GLenum) {
        glBlendEquationSeparate(modeRGB, modeAlpha)
    }

    func glBlendColor(_ red: GLfloat, _ green: GLfloat, _ blue: GLfloat, _ alpha: GLfloat) {
        blendColor = (red, green, blue, alpha)
    }

    func glCullFace(_ mode: GLenum) {
        cullFaceMode = mode
    }

    func glFrontFace(_ mode: GLenum) {
        frontFace = mode
    }

    func glDepthFunc(_ `func`: GLenum) {
        depthFuncValue = `func`
    }

    func glDepthRangef(_ n: GLclampf, _ f: GLclampf) {
        depthRange = (n, f)
    }

    func glDepthRangex(_ n: GLclampx, _ f: GLclampx) {
        glDepthRangef(fixedToFloat(n), fixedToFloat(f))
    }

    func glLineWidth(_ width: GLfloat) {
        if width <= 0 {
            setError(glEnum(GL_INVALID_VALUE))
            return
        }
        lineWidth = width
    }

    func glPolygonOffset(_ factor: GLfloat, _ units: GLfloat) {
        polygonOffsetFactor = factor
        polygonOffsetUnits = units
    }

    func glSampleCoverage(_ value: GLclampf, _ invert: GLboolean) {
        sampleCoverageValue = value
        sampleCoverageInvert = invert
    }

    func glSampleCoveragex(_ value: GLclampx, _ invert: GLboolean) {
        glSampleCoverage(fixedToFloat(value), invert)
    }

    func glPixelStorei(_ pname: GLenum, _ param: GLint) {
        switch pname {
        case glEnum(GL_UNPACK_ALIGNMENT): unpackAlignment = param
        case glEnum(GL_PACK_ALIGNMENT): packAlignment = param
        default: setError(glEnum(GL_INVALID_ENUM))
        }
    }

    func glPixelStoref(_ pname: GLenum, _ param: GLfloat) {
        glPixelStorei(pname, GLint(param))
    }

    // MARK: Gets

    func glGetIntegerv(_ pname: GLenum, _ params: UnsafeMutablePointer<GLint>!) {
        guard let params else { return }
        switch pname {
        case glEnum(GL_VIEWPORT):
            params[0] = viewport.0; params[1] = viewport.1
            params[2] = viewport.2; params[3] = viewport.3
        case glEnum(GL_SCISSOR_BOX):
            params[0] = scissor.0; params[1] = scissor.1
            params[2] = scissor.2; params[3] = scissor.3
        case glEnum(GL_MAX_TEXTURE_SIZE), glEnum(GL_MAX_RENDERBUFFER_SIZE):
            params.pointee = Self.maxTextureSize
        case glEnum(GL_MAX_LIGHTS): params.pointee = Self.maxLights
        case glEnum(GL_MAX_CLIP_PLANES): params.pointee = Self.maxClipPlanes
        case glEnum(GL_MAX_MODELVIEW_STACK_DEPTH): params.pointee = Self.maxModelviewStack
        case glEnum(GL_MAX_PROJECTION_STACK_DEPTH): params.pointee = Self.maxProjectionStack
        case glEnum(GL_MAX_TEXTURE_STACK_DEPTH): params.pointee = Self.maxTextureStack
        case glEnum(GL_MAX_VERTEX_ATTRIBS): params.pointee = Self.maxVertexAttribs
        case glEnum(GL_MAX_TEXTURE_UNITS), glEnum(GL_MAX_TEXTURE_IMAGE_UNITS),
             glEnum(GL_MAX_COMBINED_TEXTURE_IMAGE_UNITS):
            params.pointee = Self.maxTextureUnits
        case glEnum(GL_NUM_COMPRESSED_TEXTURE_FORMATS): params.pointee = 0
        case glEnum(GL_CURRENT_PROGRAM): params.pointee = GLint(currentProgram)
        case glEnum(GL_ARRAY_BUFFER_BINDING): params.pointee = GLint(arrayBuffer)
        case glEnum(GL_ELEMENT_ARRAY_BUFFER_BINDING): params.pointee = GLint(elementBuffer)
        case glEnum(GL_FRAMEBUFFER_BINDING), glEnum(GL_FRAMEBUFFER_BINDING_OES):
            params.pointee = GLint(framebuffer)
        case glEnum(GL_RENDERBUFFER_BINDING), glEnum(GL_RENDERBUFFER_BINDING_OES):
            params.pointee = GLint(renderbuffer)
        case glEnum(GL_VERTEX_ARRAY_BINDING), glEnum(GL_VERTEX_ARRAY_BINDING_OES):
            params.pointee = GLint(vertexArray)
        case glEnum(GL_ACTIVE_TEXTURE): params.pointee = GLint(bitPattern: activeTex)
        case glEnum(GL_MATRIX_MODE): params.pointee = GLint(bitPattern: matrixMode)
        case glEnum(GL_MODELVIEW_STACK_DEPTH): params.pointee = GLint(modelview.count)
        case glEnum(GL_PROJECTION_STACK_DEPTH): params.pointee = GLint(projection.count)
        case glEnum(GL_TEXTURE_STACK_DEPTH): params.pointee = GLint(textureStack.count)
        case glEnum(GL_UNPACK_ALIGNMENT): params.pointee = unpackAlignment
        case glEnum(GL_PACK_ALIGNMENT): params.pointee = packAlignment
        case glEnum(GL_CULL_FACE_MODE): params.pointee = GLint(bitPattern: cullFaceMode)
        case glEnum(GL_FRONT_FACE): params.pointee = GLint(bitPattern: frontFace)
        case glEnum(GL_DEPTH_FUNC): params.pointee = GLint(bitPattern: depthFuncValue)
        case glEnum(GL_BLEND_SRC_RGB): params.pointee = GLint(bitPattern: blendSrcRGB)
        case glEnum(GL_BLEND_DST_RGB): params.pointee = GLint(bitPattern: blendDstRGB)
        case glEnum(GL_STENCIL_WRITEMASK): params.pointee = GLint(bitPattern: stencilMaskFront)
        default:
            setError(glEnum(GL_INVALID_ENUM))
        }
    }

    func glGetFloatv(_ pname: GLenum, _ params: UnsafeMutablePointer<GLfloat>!) {
        guard let params else { return }
        switch pname {
        case glEnum(GL_COLOR_CLEAR_VALUE):
            params[0] = clearColor.0; params[1] = clearColor.1
            params[2] = clearColor.2; params[3] = clearColor.3
        case glEnum(GL_DEPTH_CLEAR_VALUE): params.pointee = clearDepth
        case glEnum(GL_LINE_WIDTH): params.pointee = lineWidth
        case glEnum(GL_DEPTH_RANGE):
            params[0] = depthRange.0; params[1] = depthRange.1
        case glEnum(GL_MODELVIEW_MATRIX):
            for i in 0..<16 { params[i] = modelview.last!.m[i] }
        case glEnum(GL_PROJECTION_MATRIX):
            for i in 0..<16 { params[i] = projection.last!.m[i] }
        case glEnum(GL_TEXTURE_MATRIX):
            for i in 0..<16 { params[i] = textureStack.last!.m[i] }
        case glEnum(GL_CURRENT_COLOR):
            params[0] = currentColor.0; params[1] = currentColor.1
            params[2] = currentColor.2; params[3] = currentColor.3
        case glEnum(GL_ALIASED_LINE_WIDTH_RANGE), glEnum(GL_ALIASED_POINT_SIZE_RANGE):
            params[0] = 1; params[1] = 1
        default:
            var ints = [GLint](repeating: 0, count: 16)
            ints.withUnsafeMutableBufferPointer { glGetIntegerv(pname, $0.baseAddress) }
            params.pointee = GLfloat(ints[0])
        }
    }

    func glGetBooleanv(_ pname: GLenum, _ params: UnsafeMutablePointer<GLboolean>!) {
        guard let params else { return }
        switch pname {
        case glEnum(GL_COLOR_WRITEMASK):
            params[0] = colorMask.0; params[1] = colorMask.1
            params[2] = colorMask.2; params[3] = colorMask.3
        case glEnum(GL_DEPTH_WRITEMASK): params.pointee = depthMask
        default:
            var ints = [GLint](repeating: 0, count: 4)
            ints.withUnsafeMutableBufferPointer { glGetIntegerv(pname, $0.baseAddress) }
            params.pointee = ints[0] == 0 ? 0 : 1
        }
    }

    func glGetFixedv(_ pname: GLenum, _ params: UnsafeMutablePointer<GLfixed>!) {
        guard let params else { return }
        var floats = [GLfloat](repeating: 0, count: 16)
        floats.withUnsafeMutableBufferPointer { glGetFloatv(pname, $0.baseAddress) }
        params.pointee = GLfixed(floats[0] * 65536.0)
    }

    func glGetString(_ name: GLenum) -> UnsafePointer<GLubyte>! {
        switch name {
        case glEnum(GL_VENDOR): return vendorPtr
        case glEnum(GL_RENDERER): return rendererPtr
        case glEnum(GL_VERSION): return versionPtr
        case glEnum(GL_SHADING_LANGUAGE_VERSION): return shadingPtr
        case glEnum(GL_EXTENSIONS): return extensionsPtr
        default:
            setError(glEnum(GL_INVALID_ENUM))
            return nil
        }
    }

    func glGetStringi(_ name: GLenum, _ index: GLuint) -> UnsafePointer<GLubyte>! {
        _ = name
        _ = index
        setError(glEnum(GL_INVALID_VALUE))
        return nil
    }

    // MARK: Textures / buffers / names

    func glActiveTexture(_ texture: GLenum) {
        activeTex = texture
    }

    func glClientActiveTexture(_ texture: GLenum) {
        _ = texture
    }

    func glGenTextures(_ n: GLsizei, _ textures: UnsafeMutablePointer<GLuint>!) {
        self.textures.generate(n, textures)
    }

    func glDeleteTextures(_ n: GLsizei, _ textures: UnsafePointer<GLuint>!) {
        self.textures.remove(n, textures)
    }

    func glBindTexture(_ target: GLenum, _ texture: GLuint) {
        self.textures.ensure(texture)
        boundTextures[target] = texture
        if texture != 0 {
            textureObjects[texture] = textureObjects[texture] ?? TextureObject()
        }
    }

    func glIsTexture(_ texture: GLuint) -> GLboolean {
        self.textures.contains(texture) ? 1 : 0
    }

    func glTexParameteri(_ target: GLenum, _ pname: GLenum, _ param: GLint) {
        let name = boundTextures[target] ?? 0
        guard name != 0, var object = textureObjects[name] else { return }
        switch pname {
        case glEnum(GL_TEXTURE_MIN_FILTER): object.minFilter = param
        case glEnum(GL_TEXTURE_MAG_FILTER): object.magFilter = param
        case glEnum(GL_TEXTURE_WRAP_S): object.wrapS = param
        case glEnum(GL_TEXTURE_WRAP_T): object.wrapT = param
        default: setError(glEnum(GL_INVALID_ENUM)); return
        }
        textureObjects[name] = object
    }

    func glTexParameterf(_ target: GLenum, _ pname: GLenum, _ param: GLfloat) {
        glTexParameteri(target, pname, GLint(param))
    }

    func glTexParameterx(_ target: GLenum, _ pname: GLenum, _ param: GLfixed) {
        glTexParameteri(target, pname, param)
    }

    func glTexParameteriv(_ target: GLenum, _ pname: GLenum, _ params: UnsafePointer<GLint>!) {
        guard let params else { return }
        glTexParameteri(target, pname, params.pointee)
    }

    func glTexParameterfv(_ target: GLenum, _ pname: GLenum, _ params: UnsafePointer<GLfloat>!) {
        guard let params else { return }
        glTexParameterf(target, pname, params.pointee)
    }

    func glTexParameterxv(_ target: GLenum, _ pname: GLenum, _ params: UnsafePointer<GLfixed>!) {
        guard let params else { return }
        glTexParameterx(target, pname, params.pointee)
    }

    func glGetTexParameteriv(_ target: GLenum, _ pname: GLenum, _ params: UnsafeMutablePointer<GLint>!) {
        guard let params else { return }
        let name = boundTextures[target] ?? 0
        let object = textureObjects[name]
        switch pname {
        case glEnum(GL_TEXTURE_MIN_FILTER): params.pointee = object?.minFilter ?? GL_NEAREST_MIPMAP_LINEAR
        case glEnum(GL_TEXTURE_MAG_FILTER): params.pointee = object?.magFilter ?? GL_LINEAR
        case glEnum(GL_TEXTURE_WRAP_S): params.pointee = object?.wrapS ?? GL_REPEAT
        case glEnum(GL_TEXTURE_WRAP_T): params.pointee = object?.wrapT ?? GL_REPEAT
        default: setError(glEnum(GL_INVALID_ENUM))
        }
    }

    func glGetTexParameterfv(_ target: GLenum, _ pname: GLenum, _ params: UnsafeMutablePointer<GLfloat>!) {
        guard let params else { return }
        var value: GLint = 0
        glGetTexParameteriv(target, pname, &value)
        params.pointee = GLfloat(value)
    }

    func glTexImage2D(
        _ target: GLenum, _ level: GLint, _ internalformat: GLint,
        _ width: GLsizei, _ height: GLsizei, _ border: GLint,
        _ format: GLenum, _ type: GLenum, _ pixels: UnsafeRawPointer!
    ) {
        _ = level
        _ = type
        _ = pixels
        if border != 0 || width < 0 || height < 0 {
            setError(glEnum(GL_INVALID_VALUE))
            return
        }
        let name = boundTextures[target] ?? 0
        guard name != 0 else { return }
        var object = textureObjects[name] ?? TextureObject()
        object.width = width
        object.height = height
        object.format = GLenum(bitPattern: internalformat)
        if format != 0 {
            object.format = format
        }
        textureObjects[name] = object
    }

    func glTexSubImage2D(
        _ target: GLenum, _ level: GLint, _ xoffset: GLint, _ yoffset: GLint,
        _ width: GLsizei, _ height: GLsizei, _ format: GLenum, _ type: GLenum,
        _ pixels: UnsafeRawPointer!
    ) {
        _ = (target, level, xoffset, yoffset, width, height, format, type, pixels)
    }

    func glGenerateMipmap(_ target: GLenum) {
        _ = target
    }

    func glGenerateMipmapOES(_ target: GLenum) {
        glGenerateMipmap(target)
    }

    func glGenBuffers(_ n: GLsizei, _ buffers: UnsafeMutablePointer<GLuint>!) {
        self.buffers.generate(n, buffers)
    }

    func glDeleteBuffers(_ n: GLsizei, _ buffers: UnsafePointer<GLuint>!) {
        self.buffers.remove(n, buffers)
    }

    func glBindBuffer(_ target: GLenum, _ buffer: GLuint) {
        self.buffers.ensure(buffer)
        if target == glEnum(GL_ELEMENT_ARRAY_BUFFER) {
            elementBuffer = buffer
        } else {
            arrayBuffer = buffer
        }
        if buffer != 0 {
            bufferObjects[buffer] = bufferObjects[buffer] ?? BufferObject()
        }
    }

    func glIsBuffer(_ buffer: GLuint) -> GLboolean {
        self.buffers.contains(buffer) ? 1 : 0
    }

    private func boundBuffer(_ target: GLenum) -> GLuint {
        target == glEnum(GL_ELEMENT_ARRAY_BUFFER) ? elementBuffer : arrayBuffer
    }

    func glBufferData(
        _ target: GLenum, _ size: GLsizeiptr, _ data: UnsafeRawPointer!, _ usage: GLenum
    ) {
        if size < 0 {
            setError(glEnum(GL_INVALID_VALUE))
            return
        }
        let name = boundBuffer(target)
        guard name != 0 else {
            setError(glEnum(GL_INVALID_OPERATION))
            return
        }
        let object = bufferObjects[name] ?? BufferObject()
        object.usage = usage
        object.resize(size)
        if let data, size > 0, let dest = object.storage {
            dest.update(from: data.assumingMemoryBound(to: UInt8.self), count: size)
        }
        bufferObjects[name] = object
    }

    func glBufferSubData(
        _ target: GLenum, _ offset: GLintptr, _ size: GLsizeiptr, _ data: UnsafeRawPointer!
    ) {
        let name = boundBuffer(target)
        guard name != 0, let object = bufferObjects[name] else {
            setError(glEnum(GL_INVALID_OPERATION))
            return
        }
        if offset < 0 || size < 0 || offset + size > object.count {
            setError(glEnum(GL_INVALID_VALUE))
            return
        }
        if let data, size > 0, let dest = object.storage {
            dest.advanced(by: offset).update(
                from: data.assumingMemoryBound(to: UInt8.self), count: size
            )
        }
    }

    func glGetBufferParameteriv(
        _ target: GLenum, _ pname: GLenum, _ params: UnsafeMutablePointer<GLint>!
    ) {
        guard let params else { return }
        let name = boundBuffer(target)
        let object = bufferObjects[name]
        switch pname {
        case glEnum(GL_BUFFER_SIZE): params.pointee = GLint(object?.count ?? 0)
        case glEnum(GL_BUFFER_USAGE): params.pointee = GLint(bitPattern: object?.usage ?? 0)
        default: setError(glEnum(GL_INVALID_ENUM))
        }
    }

    func glMapBufferRange(
        _ target: GLenum, _ offset: GLintptr, _ length: GLsizeiptr, _ access: GLbitfield
    ) -> UnsafeMutableRawPointer! {
        _ = access
        let name = boundBuffer(target)
        guard name != 0, let object = bufferObjects[name] else {
            setError(glEnum(GL_INVALID_OPERATION))
            return nil
        }
        if offset < 0 || length < 0 || offset + length > object.count {
            setError(glEnum(GL_INVALID_VALUE))
            return nil
        }
        object.mapped = true
        guard let storage = object.storage else { return nil }
        return UnsafeMutableRawPointer(storage).advanced(by: offset)
    }

    func glMapBufferRangeEXT(
        _ target: GLenum, _ offset: GLintptr, _ length: GLsizeiptr, _ access: GLbitfield
    ) -> UnsafeMutableRawPointer! {
        glMapBufferRange(target, offset, length, access)
    }

    func glMapBufferOES(_ target: GLenum, _ access: GLenum) -> UnsafeMutableRawPointer! {
        let name = boundBuffer(target)
        let size = bufferObjects[name]?.count ?? 0
        return glMapBufferRange(target, 0, size, GLbitfield(access))
    }

    func glUnmapBuffer(_ target: GLenum) -> GLboolean {
        let name = boundBuffer(target)
        guard name != 0, let object = bufferObjects[name], object.mapped else {
            setError(glEnum(GL_INVALID_OPERATION))
            return 0
        }
        object.mapped = false
        return 1
    }

    func glUnmapBufferOES(_ target: GLenum) -> GLboolean {
        glUnmapBuffer(target)
    }

    func glGetBufferPointerv(
        _ target: GLenum, _ pname: GLenum, _ params: UnsafeMutablePointer<UnsafeMutableRawPointer?>!
    ) {
        guard let params else { return }
        let name = boundBuffer(target)
        guard pname == glEnum(GL_BUFFER_MAP_POINTER) || pname == glEnum(GL_BUFFER_MAP_POINTER_OES) else {
            setError(glEnum(GL_INVALID_ENUM))
            return
        }
        if let object = bufferObjects[name], object.mapped {
            params.pointee = UnsafeMutableRawPointer(object.storage)
        } else {
            params.pointee = nil
        }
    }

    func glGetBufferPointervOES(
        _ target: GLenum, _ pname: GLenum, _ params: UnsafeMutablePointer<UnsafeMutableRawPointer?>!
    ) {
        glGetBufferPointerv(target, pname, params)
    }

    // MARK: VAO / FBO / renderbuffer

    func glGenVertexArrays(_ n: GLsizei, _ arrays: UnsafeMutablePointer<GLuint>!) {
        vertexArrays.generate(n, arrays)
    }

    func glGenVertexArraysOES(_ n: GLsizei, _ arrays: UnsafeMutablePointer<GLuint>!) {
        glGenVertexArrays(n, arrays)
    }

    func glDeleteVertexArrays(_ n: GLsizei, _ arrays: UnsafePointer<GLuint>!) {
        vertexArrays.remove(n, arrays)
    }

    func glDeleteVertexArraysOES(_ n: GLsizei, _ arrays: UnsafePointer<GLuint>!) {
        glDeleteVertexArrays(n, arrays)
    }

    func glBindVertexArray(_ array: GLuint) {
        vertexArrays.ensure(array)
        vertexArray = array
    }

    func glBindVertexArrayOES(_ array: GLuint) {
        glBindVertexArray(array)
    }

    func glIsVertexArray(_ array: GLuint) -> GLboolean {
        vertexArrays.contains(array) ? 1 : 0
    }

    func glIsVertexArrayOES(_ array: GLuint) -> GLboolean {
        glIsVertexArray(array)
    }

    func glGenFramebuffers(_ n: GLsizei, _ framebuffers: UnsafeMutablePointer<GLuint>!) {
        self.framebuffers.generate(n, framebuffers)
    }

    func glGenFramebuffersOES(_ n: GLsizei, _ framebuffers: UnsafeMutablePointer<GLuint>!) {
        glGenFramebuffers(n, framebuffers)
    }

    func glDeleteFramebuffers(_ n: GLsizei, _ framebuffers: UnsafePointer<GLuint>!) {
        self.framebuffers.remove(n, framebuffers)
    }

    func glDeleteFramebuffersOES(_ n: GLsizei, _ framebuffers: UnsafePointer<GLuint>!) {
        glDeleteFramebuffers(n, framebuffers)
    }

    func glBindFramebuffer(_ target: GLenum, _ framebuffer: GLuint) {
        _ = target
        self.framebuffers.ensure(framebuffer)
        self.framebuffer = framebuffer
        if framebuffer != 0 {
            framebufferObjects[framebuffer] = framebufferObjects[framebuffer] ?? FramebufferObject()
        }
    }

    func glBindFramebufferOES(_ target: GLenum, _ framebuffer: GLuint) {
        glBindFramebuffer(target, framebuffer)
    }

    func glIsFramebuffer(_ framebuffer: GLuint) -> GLboolean {
        self.framebuffers.contains(framebuffer) ? 1 : 0
    }

    func glIsFramebufferOES(_ framebuffer: GLuint) -> GLboolean {
        glIsFramebuffer(framebuffer)
    }

    func glFramebufferTexture2D(
        _ target: GLenum, _ attachment: GLenum, _ textarget: GLenum,
        _ texture: GLuint, _ level: GLint
    ) {
        _ = (target, textarget, level)
        guard framebuffer != 0 else {
            setError(glEnum(GL_INVALID_OPERATION))
            return
        }
        var object = framebufferObjects[framebuffer] ?? FramebufferObject()
        if attachment == glEnum(GL_COLOR_ATTACHMENT0) || attachment == glEnum(GL_COLOR_ATTACHMENT0_OES) {
            object.colorTexture = texture
        }
        framebufferObjects[framebuffer] = object
    }

    func glFramebufferTexture2DOES(
        _ target: GLenum, _ attachment: GLenum, _ textarget: GLenum,
        _ texture: GLuint, _ level: GLint
    ) {
        glFramebufferTexture2D(target, attachment, textarget, texture, level)
    }

    func glFramebufferRenderbuffer(
        _ target: GLenum, _ attachment: GLenum, _ renderbuffertarget: GLenum,
        _ renderbuffer: GLuint
    ) {
        _ = (target, renderbuffertarget)
        guard framebuffer != 0 else {
            setError(glEnum(GL_INVALID_OPERATION))
            return
        }
        var object = framebufferObjects[framebuffer] ?? FramebufferObject()
        if attachment == glEnum(GL_COLOR_ATTACHMENT0) || attachment == glEnum(GL_COLOR_ATTACHMENT0_OES) {
            object.colorRenderbuffer = renderbuffer
        } else if attachment == glEnum(GL_DEPTH_ATTACHMENT) || attachment == glEnum(GL_DEPTH_ATTACHMENT_OES) {
            object.depthRenderbuffer = renderbuffer
        } else if attachment == glEnum(GL_STENCIL_ATTACHMENT) || attachment == glEnum(GL_STENCIL_ATTACHMENT_OES) {
            object.stencilRenderbuffer = renderbuffer
        }
        framebufferObjects[framebuffer] = object
    }

    func glFramebufferRenderbufferOES(
        _ target: GLenum, _ attachment: GLenum, _ renderbuffertarget: GLenum,
        _ renderbuffer: GLuint
    ) {
        glFramebufferRenderbuffer(target, attachment, renderbuffertarget, renderbuffer)
    }

    func glCheckFramebufferStatus(_ target: GLenum) -> GLenum {
        _ = target
        if framebuffer == 0 {
            return glEnum(GL_FRAMEBUFFER_UNDEFINED)
        }
        let object = framebufferObjects[framebuffer] ?? FramebufferObject()
        if object.colorTexture == 0 && object.colorRenderbuffer == 0 {
            return glEnum(GL_FRAMEBUFFER_INCOMPLETE_MISSING_ATTACHMENT)
        }
        return glEnum(GL_FRAMEBUFFER_COMPLETE)
    }

    func glCheckFramebufferStatusOES(_ target: GLenum) -> GLenum {
        glCheckFramebufferStatus(target)
    }

    func glGenRenderbuffers(_ n: GLsizei, _ renderbuffers: UnsafeMutablePointer<GLuint>!) {
        self.renderbuffers.generate(n, renderbuffers)
    }

    func glGenRenderbuffersOES(_ n: GLsizei, _ renderbuffers: UnsafeMutablePointer<GLuint>!) {
        glGenRenderbuffers(n, renderbuffers)
    }

    func glDeleteRenderbuffers(_ n: GLsizei, _ renderbuffers: UnsafePointer<GLuint>!) {
        self.renderbuffers.remove(n, renderbuffers)
    }

    func glDeleteRenderbuffersOES(_ n: GLsizei, _ renderbuffers: UnsafePointer<GLuint>!) {
        glDeleteRenderbuffers(n, renderbuffers)
    }

    func glBindRenderbuffer(_ target: GLenum, _ renderbuffer: GLuint) {
        _ = target
        self.renderbuffers.ensure(renderbuffer)
        self.renderbuffer = renderbuffer
        if renderbuffer != 0 {
            renderbufferObjects[renderbuffer] = renderbufferObjects[renderbuffer] ?? RenderbufferObject()
        }
    }

    func glBindRenderbufferOES(_ target: GLenum, _ renderbuffer: GLuint) {
        glBindRenderbuffer(target, renderbuffer)
    }

    func glIsRenderbuffer(_ renderbuffer: GLuint) -> GLboolean {
        self.renderbuffers.contains(renderbuffer) ? 1 : 0
    }

    func glIsRenderbufferOES(_ renderbuffer: GLuint) -> GLboolean {
        glIsRenderbuffer(renderbuffer)
    }

    func glRenderbufferStorage(
        _ target: GLenum, _ internalformat: GLenum, _ width: GLsizei, _ height: GLsizei
    ) {
        _ = target
        if width < 0 || height < 0 {
            setError(glEnum(GL_INVALID_VALUE))
            return
        }
        guard renderbuffer != 0 else {
            setError(glEnum(GL_INVALID_OPERATION))
            return
        }
        renderbufferObjects[renderbuffer] = RenderbufferObject(
            internalFormat: internalformat, width: width, height: height
        )
    }

    func glRenderbufferStorageOES(
        _ target: GLenum, _ internalformat: GLenum, _ width: GLsizei, _ height: GLsizei
    ) {
        glRenderbufferStorage(target, internalformat, width, height)
    }

    func glGetRenderbufferParameteriv(
        _ target: GLenum, _ pname: GLenum, _ params: UnsafeMutablePointer<GLint>!
    ) {
        _ = target
        guard let params else { return }
        let object = renderbufferObjects[renderbuffer]
        switch pname {
        case glEnum(GL_RENDERBUFFER_WIDTH), glEnum(GL_RENDERBUFFER_WIDTH_OES):
            params.pointee = object?.width ?? 0
        case glEnum(GL_RENDERBUFFER_HEIGHT), glEnum(GL_RENDERBUFFER_HEIGHT_OES):
            params.pointee = object?.height ?? 0
        case glEnum(GL_RENDERBUFFER_INTERNAL_FORMAT), glEnum(GL_RENDERBUFFER_INTERNAL_FORMAT_OES):
            params.pointee = GLint(bitPattern: object?.internalFormat ?? 0)
        default:
            setError(glEnum(GL_INVALID_ENUM))
        }
    }

    func glGetRenderbufferParameterivOES(
        _ target: GLenum, _ pname: GLenum, _ params: UnsafeMutablePointer<GLint>!
    ) {
        glGetRenderbufferParameteriv(target, pname, params)
    }

    // MARK: Shaders / programs

    func glCreateShader(_ type: GLenum) -> GLuint {
        if type != glEnum(GL_VERTEX_SHADER) && type != glEnum(GL_FRAGMENT_SHADER) {
            setError(glEnum(GL_INVALID_ENUM))
            return 0
        }
        let name = nextShader
        nextShader += 1
        shaders.ensure(name)
        shaderObjects[name] = ShaderObject(type: type)
        return name
    }

    func glDeleteShader(_ shader: GLuint) {
        shaderObjects[shader]?.deleted = true
    }

    func glIsShader(_ shader: GLuint) -> GLboolean {
        shaderObjects[shader] != nil ? 1 : 0
    }

    func glShaderSource(
        _ shader: GLuint, _ count: GLsizei,
        _ string: UnsafePointer<UnsafePointer<GLchar>?>!,
        _ length: UnsafePointer<GLint>!
    ) {
        guard var object = shaderObjects[shader], let string, count >= 0 else {
            setError(glEnum(GL_INVALID_VALUE))
            return
        }
        var source = ""
        for i in 0..<Int(count) {
            guard let piece = string[i] else { continue }
            if let length, length[i] >= 0 {
                let n = Int(length[i])
                source += String(bytes: UnsafeBufferPointer(start: piece, count: n).map { UInt8(bitPattern: $0) }, encoding: .utf8) ?? ""
            } else {
                source += String(cString: UnsafeRawPointer(piece).assumingMemoryBound(to: CChar.self))
            }
        }
        object.source = source
        shaderObjects[shader] = object
    }

    func glCompileShader(_ shader: GLuint) {
        guard shaderObjects[shader] != nil else {
            setError(glEnum(GL_INVALID_VALUE))
            return
        }
    }

    func glGetShaderiv(_ shader: GLuint, _ pname: GLenum, _ params: UnsafeMutablePointer<GLint>!) {
        guard let params, let object = shaderObjects[shader] else {
            setError(glEnum(GL_INVALID_VALUE))
            return
        }
        switch pname {
        case glEnum(GL_COMPILE_STATUS): params.pointee = GL_FALSE
        case glEnum(GL_SHADER_TYPE): params.pointee = GLint(bitPattern: object.type)
        case glEnum(GL_SHADER_SOURCE_LENGTH): params.pointee = GLint(object.source.utf8.count + 1)
        case glEnum(GL_INFO_LOG_LENGTH):
            params.pointee = GLint("GLSL compiler unavailable on this Linux host.\0".utf8.count)
        case glEnum(GL_DELETE_STATUS): params.pointee = object.deleted ? GL_TRUE : GL_FALSE
        default: setError(glEnum(GL_INVALID_ENUM))
        }
    }

    func glGetShaderInfoLog(
        _ shader: GLuint, _ bufsize: GLsizei, _ length: UnsafeMutablePointer<GLsizei>!,
        _ infolog: UnsafeMutablePointer<GLchar>!
    ) {
        guard shaderObjects[shader] != nil else {
            setError(glEnum(GL_INVALID_VALUE))
            return
        }
        let message = "GLSL compiler unavailable on this Linux host."
        writeCString(message, bufsize: bufsize, length: length, dest: infolog)
    }

    func glGetShaderSource(
        _ shader: GLuint, _ bufsize: GLsizei, _ length: UnsafeMutablePointer<GLsizei>!,
        _ source: UnsafeMutablePointer<GLchar>!
    ) {
        guard let object = shaderObjects[shader] else {
            setError(glEnum(GL_INVALID_VALUE))
            return
        }
        writeCString(object.source, bufsize: bufsize, length: length, dest: source)
    }

    func glCreateProgram() -> GLuint {
        let name = nextProgram
        nextProgram += 1
        programs.ensure(name)
        programObjects[name] = ProgramObject()
        return name
    }

    func glDeleteProgram(_ program: GLuint) {
        programObjects.removeValue(forKey: program)
        if currentProgram == program {
            currentProgram = 0
        }
    }

    func glIsProgram(_ program: GLuint) -> GLboolean {
        programObjects[program] != nil ? 1 : 0
    }

    func glAttachShader(_ program: GLuint, _ shader: GLuint) {
        guard var object = programObjects[program], shaderObjects[shader] != nil else {
            setError(glEnum(GL_INVALID_VALUE))
            return
        }
        object.shaders.insert(shader)
        programObjects[program] = object
    }

    func glDetachShader(_ program: GLuint, _ shader: GLuint) {
        guard var object = programObjects[program] else {
            setError(glEnum(GL_INVALID_VALUE))
            return
        }
        object.shaders.remove(shader)
        programObjects[program] = object
    }

    func glLinkProgram(_ program: GLuint) {
        guard var object = programObjects[program] else {
            setError(glEnum(GL_INVALID_VALUE))
            return
        }
        object.linked = false
        programObjects[program] = object
    }

    func glValidateProgram(_ program: GLuint) {
        guard programObjects[program] != nil else {
            setError(glEnum(GL_INVALID_VALUE))
            return
        }
    }

    func glGetProgramiv(_ program: GLuint, _ pname: GLenum, _ params: UnsafeMutablePointer<GLint>!) {
        guard let params, let object = programObjects[program] else {
            setError(glEnum(GL_INVALID_VALUE))
            return
        }
        switch pname {
        case glEnum(GL_LINK_STATUS), glEnum(GL_VALIDATE_STATUS): params.pointee = GL_FALSE
        case glEnum(GL_ATTACHED_SHADERS): params.pointee = GLint(object.shaders.count)
        case glEnum(GL_INFO_LOG_LENGTH): params.pointee = GLint(object.infoLog.utf8.count + 1)
        case glEnum(GL_ACTIVE_ATTRIBUTES), glEnum(GL_ACTIVE_UNIFORMS): params.pointee = 0
        default: setError(glEnum(GL_INVALID_ENUM))
        }
    }

    func glGetProgramInfoLog(
        _ program: GLuint, _ bufsize: GLsizei, _ length: UnsafeMutablePointer<GLsizei>!,
        _ infolog: UnsafeMutablePointer<GLchar>!
    ) {
        guard let object = programObjects[program] else {
            setError(glEnum(GL_INVALID_VALUE))
            return
        }
        writeCString(object.infoLog, bufsize: bufsize, length: length, dest: infolog)
    }

    func glGetAttachedShaders(
        _ program: GLuint, _ maxcount: GLsizei, _ count: UnsafeMutablePointer<GLsizei>!,
        _ shaders: UnsafeMutablePointer<GLuint>!
    ) {
        guard let object = programObjects[program] else {
            setError(glEnum(GL_INVALID_VALUE))
            return
        }
        let ids = Array(object.shaders)
        let n = min(Int(maxcount), ids.count)
        if let shaders {
            for i in 0..<n { shaders[i] = ids[i] }
        }
        count?.pointee = GLsizei(n)
    }

    func glUseProgram(_ program: GLuint) {
        if program != 0 && programObjects[program] == nil {
            setError(glEnum(GL_INVALID_VALUE))
            return
        }
        currentProgram = program
    }

    func glGetAttribLocation(_ program: GLuint, _ name: UnsafePointer<GLchar>!) -> Int32 {
        _ = name
        guard programObjects[program] != nil else {
            setError(glEnum(GL_INVALID_VALUE))
            return -1
        }
        return -1
    }

    func glGetUniformLocation(_ program: GLuint, _ name: UnsafePointer<GLchar>!) -> Int32 {
        _ = name
        guard programObjects[program] != nil else {
            setError(glEnum(GL_INVALID_VALUE))
            return -1
        }
        return -1
    }

    func glBindAttribLocation(_ program: GLuint, _ index: GLuint, _ name: UnsafePointer<GLchar>!) {
        _ = (index, name)
        if programObjects[program] == nil {
            setError(glEnum(GL_INVALID_VALUE))
        }
    }

    func glEnableVertexAttribArray(_ index: GLuint) {
        attribEnabled.insert(index)
    }

    func glDisableVertexAttribArray(_ index: GLuint) {
        attribEnabled.remove(index)
    }

    func glVertexAttribPointer(
        _ indx: GLuint, _ size: GLint, _ type: GLenum, _ normalized: GLboolean,
        _ stride: GLsizei, _ ptr: UnsafeRawPointer!
    ) {
        _ = (indx, size, type, normalized, stride, ptr)
    }

    func glGetVertexAttribiv(_ index: GLuint, _ pname: GLenum, _ params: UnsafeMutablePointer<GLint>!) {
        guard let params else { return }
        if pname == glEnum(GL_VERTEX_ATTRIB_ARRAY_ENABLED) {
            params.pointee = attribEnabled.contains(index) ? 1 : 0
        } else {
            params.pointee = 0
        }
    }

    func glGetVertexAttribfv(_ index: GLuint, _ pname: GLenum, _ params: UnsafeMutablePointer<GLfloat>!) {
        guard let params else { return }
        var value: GLint = 0
        glGetVertexAttribiv(index, pname, &value)
        params.pointee = GLfloat(value)
    }

    func glGetVertexAttribPointerv(
        _ index: GLuint, _ pname: GLenum, _ pointer: UnsafeMutablePointer<UnsafeMutableRawPointer?>!
    ) {
        _ = (index, pname)
        pointer?.pointee = nil
    }

    func glDrawArrays(_ mode: GLenum, _ first: GLint, _ count: GLsizei) {
        _ = (mode, first, count)
        setError(glEnum(GL_INVALID_OPERATION))
    }

    func glDrawElements(_ mode: GLenum, _ count: GLsizei, _ type: GLenum, _ indices: UnsafeRawPointer!) {
        _ = (mode, count, type, indices)
        setError(glEnum(GL_INVALID_OPERATION))
    }

    func glFinish() {}
    func glFlush() {}

    func glReadPixels(
        _ x: GLint, _ y: GLint, _ width: GLsizei, _ height: GLsizei,
        _ format: GLenum, _ type: GLenum, _ pixels: UnsafeMutableRawPointer!
    ) {
        _ = (x, y, width, height, format, type, pixels)
        setError(glEnum(GL_INVALID_OPERATION))
    }

    // MARK: Queries / samplers / transform feedback / sync

    func glGenQueries(_ n: GLsizei, _ ids: UnsafeMutablePointer<GLuint>!) { queries.generate(n, ids) }
    func glDeleteQueries(_ n: GLsizei, _ ids: UnsafePointer<GLuint>!) { queries.remove(n, ids) }
    func glIsQuery(_ id: GLuint) -> GLboolean { queries.contains(id) ? 1 : 0 }
    func glBeginQuery(_ target: GLenum, _ id: GLuint) { _ = (target, id) }
    func glEndQuery(_ target: GLenum) { _ = target }

    func glGenSamplers(_ count: GLsizei, _ samplers: UnsafeMutablePointer<GLuint>!) {
        self.samplers.generate(count, samplers)
    }
    func glDeleteSamplers(_ count: GLsizei, _ samplers: UnsafePointer<GLuint>!) {
        self.samplers.remove(count, samplers)
    }
    func glBindSampler(_ unit: GLuint, _ sampler: GLuint) {
        _ = unit
        self.samplers.ensure(sampler)
        self.sampler = sampler
    }
    func glIsSampler(_ sampler: GLuint) -> GLboolean { samplers.contains(sampler) ? 1 : 0 }

    func glGenTransformFeedbacks(_ n: GLsizei, _ ids: UnsafeMutablePointer<GLuint>!) {
        transformFeedbacks.generate(n, ids)
    }
    func glDeleteTransformFeedbacks(_ n: GLsizei, _ ids: UnsafePointer<GLuint>!) {
        transformFeedbacks.remove(n, ids)
    }
    func glBindTransformFeedback(_ target: GLenum, _ id: GLuint) {
        _ = target
        transformFeedbacks.ensure(id)
        transformFeedback = id
    }
    func glIsTransformFeedback(_ id: GLuint) -> GLboolean { transformFeedbacks.contains(id) ? 1 : 0 }

    func glFenceSync(_ condition: GLenum, _ flags: GLbitfield) -> GLsync! {
        _ = flags
        let pointer = UnsafeMutablePointer<UInt8>.allocate(capacity: 1)
        pointer.initialize(to: 1)
        syncObjects[UnsafeMutableRawPointer(pointer)] = SyncObject(condition: condition)
        return OpaquePointer(pointer)
    }

    func glFenceSyncAPPLE(_ condition: GLenum, _ flags: GLbitfield) -> GLsync! {
        glFenceSync(condition, flags)
    }

    func glDeleteSync(_ sync: GLsync!) {
        guard let sync else { return }
        let pointer = UnsafeMutableRawPointer(sync)
        if syncObjects.removeValue(forKey: pointer) != nil {
            pointer.assumingMemoryBound(to: UInt8.self).deallocate()
        }
    }

    func glDeleteSyncAPPLE(_ sync: GLsync!) { glDeleteSync(sync) }

    func glIsSync(_ sync: GLsync!) -> GLboolean {
        guard let sync else { return 0 }
        return syncObjects[UnsafeMutableRawPointer(sync)] != nil ? 1 : 0
    }

    func glIsSyncAPPLE(_ sync: GLsync!) -> GLboolean { glIsSync(sync) }

    func glClientWaitSync(_ sync: GLsync!, _ flags: GLbitfield, _ timeout: GLuint64) -> GLenum {
        _ = (flags, timeout)
        guard glIsSync(sync) != 0 else {
            setError(glEnum(GL_INVALID_VALUE))
            return glEnum(GL_WAIT_FAILED)
        }
        return glEnum(GL_ALREADY_SIGNALED)
    }

    func glClientWaitSyncAPPLE(_ sync: GLsync!, _ flags: GLbitfield, _ timeout: GLuint64) -> GLenum {
        glClientWaitSync(sync, flags, timeout)
    }

    func glWaitSync(_ sync: GLsync!, _ flags: GLbitfield, _ timeout: GLuint64) {
        _ = glClientWaitSync(sync, flags, timeout)
    }

    func glWaitSyncAPPLE(_ sync: GLsync!, _ flags: GLbitfield, _ timeout: GLuint64) {
        glWaitSync(sync, flags, timeout)
    }

    func glGetSynciv(
        _ sync: GLsync!, _ pname: GLenum, _ bufSize: GLsizei, _ length: UnsafeMutablePointer<GLsizei>!,
        _ values: UnsafeMutablePointer<GLint>!
    ) {
        guard glIsSync(sync) != 0, let values else {
            setError(glEnum(GL_INVALID_VALUE))
            return
        }
        if bufSize < 1 { return }
        switch pname {
        case glEnum(GL_SYNC_STATUS), glEnum(GL_SYNC_STATUS_APPLE):
            values.pointee = GL_SIGNALED
        case glEnum(GL_OBJECT_TYPE), glEnum(GL_OBJECT_TYPE_APPLE):
            values.pointee = GL_SYNC_FENCE
        default:
            values.pointee = 0
        }
        length?.pointee = 1
    }

    func glGetSyncivAPPLE(
        _ sync: GLsync!, _ pname: GLenum, _ bufSize: GLsizei, _ length: UnsafeMutablePointer<GLsizei>!,
        _ values: UnsafeMutablePointer<GLint>!
    ) {
        glGetSynciv(sync, pname, bufSize, length, values)
    }

    // MARK: ES1 matrix / color

    func glMatrixMode(_ mode: GLenum) {
        matrixMode = mode
    }

    func glLoadIdentity() {
        var stack = currentStack()
        stack[stack.count - 1] = .identity
        setCurrentStack(stack)
    }

    func glLoadMatrixf(_ m: UnsafePointer<GLfloat>!) {
        guard let m else { return }
        var stack = currentStack()
        stack[stack.count - 1] = Mat4(m: (0..<16).map { m[$0] })
        setCurrentStack(stack)
    }

    func glLoadMatrixx(_ m: UnsafePointer<GLfixed>!) {
        guard let m else { return }
        var values = [GLfloat](repeating: 0, count: 16)
        for i in 0..<16 { values[i] = fixedToFloat(m[i]) }
        values.withUnsafeBufferPointer { glLoadMatrixf($0.baseAddress) }
    }

    func glMultMatrixf(_ m: UnsafePointer<GLfloat>!) {
        guard let m else { return }
        multiplyCurrent(Mat4(m: (0..<16).map { m[$0] }))
    }

    func glMultMatrixx(_ m: UnsafePointer<GLfixed>!) {
        guard let m else { return }
        var values = [GLfloat](repeating: 0, count: 16)
        for i in 0..<16 { values[i] = fixedToFloat(m[i]) }
        values.withUnsafeBufferPointer { glMultMatrixf($0.baseAddress) }
    }

    func glPushMatrix() {
        var stack = currentStack()
        if stack.count >= maxStack() {
            setError(glEnum(GL_STACK_OVERFLOW))
            return
        }
        stack.append(stack.last!)
        setCurrentStack(stack)
    }

    func glPopMatrix() {
        var stack = currentStack()
        if stack.count <= 1 {
            setError(glEnum(GL_STACK_UNDERFLOW))
            return
        }
        stack.removeLast()
        setCurrentStack(stack)
    }

    func glTranslatef(_ x: GLfloat, _ y: GLfloat, _ z: GLfloat) {
        multiplyCurrent(.translation(x, y, z))
    }

    func glTranslatex(_ x: GLfixed, _ y: GLfixed, _ z: GLfixed) {
        glTranslatef(fixedToFloat(x), fixedToFloat(y), fixedToFloat(z))
    }

    func glScalef(_ x: GLfloat, _ y: GLfloat, _ z: GLfloat) {
        multiplyCurrent(.scale(x, y, z))
    }

    func glScalex(_ x: GLfixed, _ y: GLfixed, _ z: GLfixed) {
        glScalef(fixedToFloat(x), fixedToFloat(y), fixedToFloat(z))
    }

    func glRotatef(_ angle: GLfloat, _ x: GLfloat, _ y: GLfloat, _ z: GLfloat) {
        multiplyCurrent(.rotation(degrees: angle, x: x, y: y, z: z))
    }

    func glRotatex(_ angle: GLfixed, _ x: GLfixed, _ y: GLfixed, _ z: GLfixed) {
        glRotatef(fixedToFloat(angle), fixedToFloat(x), fixedToFloat(y), fixedToFloat(z))
    }

    func glFrustumf(
        _ left: GLfloat, _ right: GLfloat, _ bottom: GLfloat, _ top: GLfloat,
        _ zNear: GLfloat, _ zFar: GLfloat
    ) {
        guard let matrix = Mat4.frustum(left, right, bottom, top, zNear, zFar) else {
            setError(glEnum(GL_INVALID_VALUE))
            return
        }
        multiplyCurrent(matrix)
    }

    func glFrustumx(
        _ left: GLfixed, _ right: GLfixed, _ bottom: GLfixed, _ top: GLfixed,
        _ zNear: GLfixed, _ zFar: GLfixed
    ) {
        glFrustumf(
            fixedToFloat(left), fixedToFloat(right), fixedToFloat(bottom),
            fixedToFloat(top), fixedToFloat(zNear), fixedToFloat(zFar)
        )
    }

    func glOrthof(
        _ left: GLfloat, _ right: GLfloat, _ bottom: GLfloat, _ top: GLfloat,
        _ zNear: GLfloat, _ zFar: GLfloat
    ) {
        guard let matrix = Mat4.ortho(left, right, bottom, top, zNear, zFar) else {
            setError(glEnum(GL_INVALID_VALUE))
            return
        }
        multiplyCurrent(matrix)
    }

    func glOrthox(
        _ left: GLfixed, _ right: GLfixed, _ bottom: GLfixed, _ top: GLfixed,
        _ zNear: GLfixed, _ zFar: GLfixed
    ) {
        glOrthof(
            fixedToFloat(left), fixedToFloat(right), fixedToFloat(bottom),
            fixedToFloat(top), fixedToFloat(zNear), fixedToFloat(zFar)
        )
    }

    func glColor4f(_ red: GLfloat, _ green: GLfloat, _ blue: GLfloat, _ alpha: GLfloat) {
        currentColor = (red, green, blue, alpha)
    }

    func glColor4ub(_ red: GLubyte, _ green: GLubyte, _ blue: GLubyte, _ alpha: GLubyte) {
        glColor4f(GLfloat(red) / 255, GLfloat(green) / 255, GLfloat(blue) / 255, GLfloat(alpha) / 255)
    }

    func glColor4x(_ red: GLfixed, _ green: GLfixed, _ blue: GLfixed, _ alpha: GLfixed) {
        glColor4f(fixedToFloat(red), fixedToFloat(green), fixedToFloat(blue), fixedToFloat(alpha))
    }

    func glNormal3f(_ nx: GLfloat, _ ny: GLfloat, _ nz: GLfloat) {
        currentNormal = (nx, ny, nz)
    }

    func glNormal3x(_ nx: GLfixed, _ ny: GLfixed, _ nz: GLfixed) {
        glNormal3f(fixedToFloat(nx), fixedToFloat(ny), fixedToFloat(nz))
    }

    func glVertexPointer(_ size: GLint, _ type: GLenum, _ stride: GLsizei, _ pointer: UnsafeRawPointer!) {
        _ = (size, type, stride, pointer)
    }

    func glColorPointer(_ size: GLint, _ type: GLenum, _ stride: GLsizei, _ pointer: UnsafeRawPointer!) {
        _ = (size, type, stride, pointer)
    }

    func glNormalPointer(_ type: GLenum, _ stride: GLsizei, _ pointer: UnsafeRawPointer!) {
        _ = (type, stride, pointer)
    }

    func glTexCoordPointer(_ size: GLint, _ type: GLenum, _ stride: GLsizei, _ pointer: UnsafeRawPointer!) {
        _ = (size, type, stride, pointer)
    }
}

private func writeCString(
    _ text: String,
    bufsize: GLsizei,
    length: UnsafeMutablePointer<GLsizei>?,
    dest: UnsafeMutablePointer<GLchar>?
) {
    let bytes = Array(text.utf8)
    let n = max(0, Int(bufsize) - 1)
    let copied = min(n, bytes.count)
    if let dest, bufsize > 0 {
        for i in 0..<copied {
            dest[i] = GLchar(bitPattern: bytes[i])
        }
        dest[copied] = 0
    }
    length?.pointee = GLsizei(copied)
}
