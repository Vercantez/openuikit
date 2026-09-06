import CoreFoundation
import OpenGLES

func openGLESDependencyIdentityProbe() {
    var major: UInt32 = 0
    var minor: UInt32 = 0
    EAGLGetVersion(&major, &minor)
    _ = CFTimeInterval(0)
    if let ctx = EAGLContext(api: .openGLES2) {
        _ = ctx.presentRenderbuffer(1, atTime: CFTimeInterval(0))
        _ = ctx.presentRenderbuffer(1, afterMinimumDuration: CFTimeInterval(0))
    }
}

#if OPENGLES_IDENTITY_MAIN
openGLESDependencyIdentityProbe()
print("OPENGLES_DEPENDENCY_IDENTITY_OK")
#endif
