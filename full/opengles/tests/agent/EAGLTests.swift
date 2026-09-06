import CoreFoundation
import OpenGLES

final class AgentDrawable: EAGLDrawable {
    var drawableProperties: [String: Any]?
}

func testEAGLRenderingAPIRawValues() {
    ogRequire(EAGLRenderingAPI.openGLES1.rawValue == 1, "gles1")
    ogRequire(EAGLRenderingAPI.openGLES2.rawValue == 2, "gles2")
    ogRequire(EAGLRenderingAPI.openGLES3.rawValue == 3, "gles3")
    ogRequire(EAGLRenderingAPI(rawValue: 1) == .openGLES1, "init 1")
    ogRequire(EAGLRenderingAPI(rawValue: 2) == .openGLES2, "init 2")
    ogRequire(EAGLRenderingAPI(rawValue: 3) == .openGLES3, "init 3")
    ogRequire(EAGLRenderingAPI(rawValue: 99) == nil, "init unknown")
    ogRequire(EAGLRenderingAPI.openGLES1 != .openGLES2, "!=")
    ogRequire(EAGLRenderingAPI.openGLES2.hashValue == EAGLRenderingAPI.openGLES2.hashValue, "hashValue")
    var hasher = Hasher()
    EAGLRenderingAPI.openGLES3.hash(into: &hasher)
    _ = hasher.finalize()
}

func testEAGLGetVersionAndMacros() {
    ogRequire(EAGL_MAJOR_VERSION == 1, "major")
    ogRequire(EAGL_MINOR_VERSION == 0, "minor")
    var major: UInt32 = 9
    var minor: UInt32 = 9
    EAGLGetVersion(&major, &minor)
    ogRequire(major == 1 && minor == 0, "EAGLGetVersion")
}

func testEAGLStringKeys() {
    ogRequire(kEAGLColorFormatRGB565 == "kEAGLColorFormatRGB565", "rgb565")
    ogRequire(kEAGLColorFormatRGBA8 == "kEAGLColorFormatRGBA8", "rgba8")
    ogRequire(kEAGLColorFormatSRGBA8 == "kEAGLColorFormatSRGBA8", "srgba8")
    ogRequire(kEAGLDrawablePropertyColorFormat == "kEAGLDrawablePropertyColorFormat", "colorFormat")
    ogRequire(kEAGLDrawablePropertyRetainedBacking == "kEAGLDrawablePropertyRetainedBacking", "retained")
}

func testEAGLContextCurrentAndSharegroup() {
    _ = EAGLContext.setCurrent(nil)
    ogRequire(EAGLContext.current() == nil, "no current")
    let gles1 = EAGLContext(api: .openGLES1)
    let gles2 = EAGLContext(api: .openGLES2)
    let gles2b = EAGLContext(API: .openGLES2)
    ogRequire(gles1 != nil && gles2 != nil && gles2b != nil, "inits")
    ogRequire(gles1!.api == .openGLES1, "api 1")
    ogRequire(gles2!.api == .openGLES2, "api 2")
    ogRequire(EAGLContext.setCurrent(gles2), "set 2")
    ogRequire(EAGLContext.current() === gles2, "current 2")
    let shared = EAGLContext(api: .openGLES2, sharegroup: gles2!.sharegroup)
    ogRequire(shared != nil, "same api share")
    ogRequire(shared!.sharegroup === gles2!.sharegroup, "share identity")
    let mismatch = EAGLContext(api: .openGLES1, sharegroup: gles2!.sharegroup)
    ogRequire(mismatch == nil, "api mismatch nil")
    let labeled = gles2!
    labeled.debugLabel = "paint"
    labeled.isMultiThreaded = true
    ogRequire(labeled.debugLabel == "paint", "debugLabel")
    ogRequire(labeled.isMultiThreaded, "multiThreaded")
    labeled.sharegroup.debugLabel = "group"
    ogRequire(labeled.sharegroup.debugLabel == "group", "share debug")
    let viaAPI = EAGLContext(API: .openGLES3, sharegroup: EAGLContext(api: .openGLES3)!.sharegroup)
    ogRequire(viaAPI != nil && viaAPI!.api == .openGLES3, "API sharegroup init")
}

func testEAGLPresentAndDrawableFailClosed() {
    let ctx = EAGLContext(api: .openGLES2)!
    ogRequire(!ctx.presentRenderbuffer(UInt(GL_RENDERBUFFER)), "present")
    ogRequire(!ctx.presentRenderbuffer(UInt(GL_RENDERBUFFER), atTime: 0), "present atTime")
    ogRequire(!ctx.presentRenderbuffer(UInt(GL_RENDERBUFFER), afterMinimumDuration: 1), "present duration")
    let drawable = AgentDrawable()
    drawable.drawableProperties = [kEAGLDrawablePropertyColorFormat: kEAGLColorFormatRGBA8]
    ogRequire(!ctx.renderbufferStorage(UInt(GL_RENDERBUFFER), from: drawable), "storage")
    ogRequire(!ctx.renderbufferStorage(UInt(GL_RENDERBUFFER), from: nil), "storage nil")
}

func testEAGLTexImageIOSurfaceFailClosed() {
    let ctx = EAGLContext(api: .openGLES3)!
    let fake = OpaquePointer(bitPattern: 0x1)!
    ogRequire(
        !ctx.texImageIOSurface(fake, target: UInt(GL_TEXTURE_2D), internalFormat: UInt(GL_RGBA), width: 1, height: 1, format: UInt(GL_RGBA), type: UInt(GL_UNSIGNED_BYTE), plane: 0),
        "iosurface"
    )
}

func testOpenGLESModuleInfo() {
    ogRequire(OpenGLESModuleInfo.moduleName == "OpenGLES", "module")
    ogRequire(OpenGLESModuleInfo.renderer.contains("software"), "renderer")
}
