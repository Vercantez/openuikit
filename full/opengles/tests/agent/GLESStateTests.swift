import OpenGLES

func testGLESErrorStickyAndClear() {
    ogWithContext {
        _ = glGetError()
        glDrawArrays(glEnum(GL_TRIANGLES), 0, 3)
        ogRequire(glGetError() == glEnum(GL_INVALID_OPERATION), "draw fail-closed")
        ogRequire(glGetError() == glEnum(GL_NO_ERROR), "error cleared")
    }
}

func testGLESEnableDisableRoundTrip() {
    ogWithContext {
        _ = glGetError()
        glDisable(glEnum(GL_BLEND))
        ogRequire(glIsEnabled(glEnum(GL_BLEND)) == 0, "blend off")
        glEnable(glEnum(GL_BLEND))
        ogRequire(glIsEnabled(glEnum(GL_BLEND)) == 1, "blend on")
        glDisable(glEnum(GL_BLEND))
        ogRequire(glIsEnabled(glEnum(GL_BLEND)) == 0, "blend off again")
        ogRequire(glGetError() == glEnum(GL_NO_ERROR), "enable error")
    }
}

func testGLESViewportAndClearColor() {
    ogWithContext {
        _ = glGetError()
        glViewport(10, 20, 320, 240)
        var vp: [GLint] = [0, 0, 0, 0]
        vp.withUnsafeMutableBufferPointer { glGetIntegerv(glEnum(GL_VIEWPORT), $0.baseAddress) }
        ogRequire(vp[0] == 10 && vp[1] == 20 && vp[2] == 320 && vp[3] == 240, "viewport")
        glClearColor(0.25, 0.5, 0.75, 1)
        var color: [GLfloat] = [0, 0, 0, 0]
        color.withUnsafeMutableBufferPointer { glGetFloatv(glEnum(GL_COLOR_CLEAR_VALUE), $0.baseAddress) }
        ogRequire(color[0] == 0.25 && color[3] == 1, "clear color")
        glViewport(-1, 0, -4, 1)
        ogRequire(glGetError() == glEnum(GL_INVALID_VALUE), "negative viewport")
    }
}

func testGLESBufferDataRoundTrip() {
    ogWithContext {
        _ = glGetError()
        var name: GLuint = 0
        glGenBuffers(1, &name)
        ogRequire(name != 0, "buffer name")
        ogRequire(glIsBuffer(name) == 1, "is buffer")
        glBindBuffer(glEnum(GL_ARRAY_BUFFER), name)
        let payload: [GLfloat] = [1, 2, 3, 4]
        payload.withUnsafeBytes { raw in
            glBufferData(glEnum(GL_ARRAY_BUFFER), raw.count, raw.baseAddress, glEnum(GL_STATIC_DRAW))
        }
        var size: GLint = 0
        glGetBufferParameteriv(glEnum(GL_ARRAY_BUFFER), glEnum(GL_BUFFER_SIZE), &size)
        ogRequire(size == 16, "buffer size")
        var mapped = glMapBufferRange(glEnum(GL_ARRAY_BUFFER), 0, 16, 0)
        ogRequire(mapped != nil, "map")
        let floats = mapped!.assumingMemoryBound(to: GLfloat.self)
        ogRequire(floats[0] == 1 && floats[3] == 4, "mapped bytes")
        floats[1] = 9
        ogRequire(glUnmapBuffer(glEnum(GL_ARRAY_BUFFER)) == 1, "unmap")
        mapped = glMapBufferRange(glEnum(GL_ARRAY_BUFFER), 0, 16, 0)
        ogRequire(mapped!.assumingMemoryBound(to: GLfloat.self)[1] == 9, "edit persisted")
        _ = glUnmapBuffer(glEnum(GL_ARRAY_BUFFER))
        glDeleteBuffers(1, &name)
        ogRequire(glGetError() == glEnum(GL_NO_ERROR), "buffer path")
    }
}

func testGLESTextureBindAndParameter() {
    ogWithContext {
        _ = glGetError()
        var name: GLuint = 0
        glGenTextures(1, &name)
        glBindTexture(glEnum(GL_TEXTURE_2D), name)
        glTexParameteri(glEnum(GL_TEXTURE_2D), glEnum(GL_TEXTURE_MIN_FILTER), GL_NEAREST)
        glTexParameteri(glEnum(GL_TEXTURE_2D), glEnum(GL_TEXTURE_WRAP_S), GL_CLAMP_TO_EDGE)
        var filter: GLint = 0
        glGetTexParameteriv(glEnum(GL_TEXTURE_2D), glEnum(GL_TEXTURE_MIN_FILTER), &filter)
        ogRequire(filter == GL_NEAREST, "min filter")
        glTexImage2D(glEnum(GL_TEXTURE_2D), 0, GL_RGBA, 8, 4, 0, glEnum(GL_RGBA), glEnum(GL_UNSIGNED_BYTE), nil)
        ogRequire(glIsTexture(name) == 1, "is texture")
        glDeleteTextures(1, &name)
        ogRequire(glGetError() == glEnum(GL_NO_ERROR), "texture path")
    }
}

func testGLESFramebufferIncompleteThenComplete() {
    ogWithContext {
        _ = glGetError()
        ogRequire(glCheckFramebufferStatus(glEnum(GL_FRAMEBUFFER)) == glEnum(GL_FRAMEBUFFER_UNDEFINED), "default fb")
        var fbo: GLuint = 0
        var rbo: GLuint = 0
        glGenFramebuffers(1, &fbo)
        glGenRenderbuffers(1, &rbo)
        glBindFramebuffer(glEnum(GL_FRAMEBUFFER), fbo)
        ogRequire(glCheckFramebufferStatus(glEnum(GL_FRAMEBUFFER)) == glEnum(GL_FRAMEBUFFER_INCOMPLETE_MISSING_ATTACHMENT), "missing")
        glBindRenderbuffer(glEnum(GL_RENDERBUFFER), rbo)
        glRenderbufferStorage(glEnum(GL_RENDERBUFFER), glEnum(GL_RGBA8), 16, 16)
        var width: GLint = 0
        glGetRenderbufferParameteriv(glEnum(GL_RENDERBUFFER), glEnum(GL_RENDERBUFFER_WIDTH), &width)
        ogRequire(width == 16, "rbo width")
        glFramebufferRenderbuffer(glEnum(GL_FRAMEBUFFER), glEnum(GL_COLOR_ATTACHMENT0), glEnum(GL_RENDERBUFFER), rbo)
        ogRequire(glCheckFramebufferStatus(glEnum(GL_FRAMEBUFFER)) == glEnum(GL_FRAMEBUFFER_COMPLETE), "complete")
        glDeleteFramebuffers(1, &fbo)
        glDeleteRenderbuffers(1, &rbo)
        ogRequire(glGetError() == glEnum(GL_NO_ERROR), "fbo path")
    }
}

func testGLESShaderCompileFailClosed() {
    ogWithContext {
        _ = glGetError()
        let shader = glCreateShader(glEnum(GL_VERTEX_SHADER))
        ogRequire(shader != 0, "shader id")
        var source: [GLchar] = Array("void main() {}\0".utf8).map { GLchar(bitPattern: $0) }
        source.withUnsafeMutableBufferPointer { buf in
            var ptr: UnsafePointer<GLchar>? = UnsafePointer(buf.baseAddress)
            withUnsafePointer(to: &ptr) { ptrPtr in
                glShaderSource(shader, 1, ptrPtr, nil)
            }
        }
        glCompileShader(shader)
        var status: GLint = 1
        glGetShaderiv(shader, glEnum(GL_COMPILE_STATUS), &status)
        ogRequire(status == GL_FALSE, "compile fail-closed")
        let program = glCreateProgram()
        glAttachShader(program, shader)
        glLinkProgram(program)
        var linked: GLint = 1
        glGetProgramiv(program, glEnum(GL_LINK_STATUS), &linked)
        ogRequire(linked == GL_FALSE, "link fail-closed")
        ogRequire(glGetAttribLocation(program, "position") == -1, "attrib")
        ogRequire(glGetUniformLocation(program, "mvp") == -1, "uniform")
        glDeleteShader(shader)
        glDeleteProgram(program)
    }
}

func testGLESMatrixIdentityTranslate() {
    ogWithContext {
        _ = glGetError()
        glMatrixMode(glEnum(GL_MODELVIEW))
        glLoadIdentity()
        glTranslatef(2, 3, 4)
        var m = [GLfloat](repeating: 0, count: 16)
        m.withUnsafeMutableBufferPointer { glGetFloatv(glEnum(GL_MODELVIEW_MATRIX), $0.baseAddress) }
        ogRequire(m[0] == 1 && m[5] == 1 && m[10] == 1 && m[15] == 1, "diag")
        ogRequire(m[12] == 2 && m[13] == 3 && m[14] == 4, "translation")
        glPushMatrix()
        glScalef(2, 2, 2)
        glPopMatrix()
        m.withUnsafeMutableBufferPointer { glGetFloatv(glEnum(GL_MODELVIEW_MATRIX), $0.baseAddress) }
        ogRequire(m[12] == 2 && m[0] == 1, "pop restored")
        for _ in 0..<32 { glPushMatrix() }
        ogRequire(glGetError() == glEnum(GL_STACK_OVERFLOW), "overflow")
        _ = glGetError()
        glMatrixMode(glEnum(GL_PROJECTION))
        glLoadIdentity()
        glPopMatrix()
        ogRequire(glGetError() == glEnum(GL_STACK_UNDERFLOW), "underflow")
    }
}

func testGLESGetStringAndLimits() {
    ogWithContext {
        _ = glGetError()
        let vendor = String(cString: glGetString(glEnum(GL_VENDOR)))
        ogRequire(vendor == "OpenUIKit", "vendor")
        let renderer = String(cString: glGetString(glEnum(GL_RENDERER)))
        ogRequire(renderer.contains("software"), "renderer")
        var maxSize: GLint = 0
        glGetIntegerv(glEnum(GL_MAX_TEXTURE_SIZE), &maxSize)
        ogRequire(maxSize == 2048, "software max texture")
        var lights: GLint = 0
        glGetIntegerv(glEnum(GL_MAX_LIGHTS), &lights)
        ogRequire(lights == 8, "spec min lights")
        ogRequire(glGetString(0x9999) == nil, "bad getString")
        ogRequire(glGetError() == glEnum(GL_INVALID_ENUM), "invalid enum")
    }
}

func testGLESSyncAlreadySignaled() {
    ogWithContext {
        _ = glGetError()
        let sync = glFenceSync(glEnum(GL_SYNC_GPU_COMMANDS_COMPLETE), 0)
        ogRequire(sync != nil, "cpu fence")
        ogRequire(glIsSync(sync) == 1, "is sync")
        ogRequire(glClientWaitSync(sync, 0, 0) == glEnum(GL_ALREADY_SIGNALED), "signaled")
        var status: GLint = 0
        glGetSynciv(sync, glEnum(GL_SYNC_STATUS), 1, nil, &status)
        ogRequire(status == GL_SIGNALED, "sync status")
        glDeleteSync(sync)
        ogRequire(glIsSync(sync) == 0, "deleted")
    }
}

func testGLESNoContextRecordsInvalidOperation() {
    _ = EAGLContext.setCurrent(nil)
    glEnable(glEnum(GL_BLEND))
    ogRequire(glGetError() == glEnum(GL_INVALID_OPERATION), "no context")
    ogRequire(glGetError() == glEnum(GL_INVALID_OPERATION), "still no context")
}

func testGLESColor4fGet() {
    ogWithContext {
        _ = glGetError()
        glColor4f(0.1, 0.2, 0.3, 0.4)
        var color = [GLfloat](repeating: 0, count: 4)
        color.withUnsafeMutableBufferPointer { glGetFloatv(glEnum(GL_CURRENT_COLOR), $0.baseAddress) }
        ogRequire(abs(color[0] - 0.1) < 0.0001 && abs(color[3] - 0.4) < 0.0001, "current color")
        glColor4ub(255, 0, 0, 128)
        color.withUnsafeMutableBufferPointer { glGetFloatv(glEnum(GL_CURRENT_COLOR), $0.baseAddress) }
        ogRequire(color[0] == 1 && color[1] == 0, "ubyte color")
    }
}
