import OpenGLES

func ogRequire(_ condition: Bool, _ message: String) {
    precondition(condition, message)
}

func glEnum(_ token: Int32) -> GLenum {
    GLenum(bitPattern: token)
}

func ogWithContext(_ body: () -> Void) {
    let previous = EAGLContext.current()
    let context = EAGLContext(api: .openGLES2)
    ogRequire(context != nil, "EAGLContext software init")
    ogRequire(EAGLContext.setCurrent(context), "setCurrent")
    body()
    _ = EAGLContext.setCurrent(previous)
}
