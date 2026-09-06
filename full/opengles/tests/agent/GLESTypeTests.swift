import OpenGLES

func testGLESTypealiases() {
    ogRequire(MemoryLayout<GLbitfield>.size == MemoryLayout<UInt32>.size, "GLbitfield")
    ogRequire(MemoryLayout<GLboolean>.size == MemoryLayout<UInt8>.size, "GLboolean")
    ogRequire(MemoryLayout<GLbyte>.size == MemoryLayout<Int8>.size, "GLbyte")
    ogRequire(MemoryLayout<GLchar>.size == MemoryLayout<CChar>.size, "GLchar")
    ogRequire(MemoryLayout<GLclampf>.size == MemoryLayout<Float>.size, "GLclampf")
    ogRequire(MemoryLayout<GLclampx>.size == MemoryLayout<Int32>.size, "GLclampx")
    ogRequire(MemoryLayout<GLenum>.size == MemoryLayout<UInt32>.size, "GLenum")
    ogRequire(MemoryLayout<GLfixed>.size == MemoryLayout<Int32>.size, "GLfixed")
    ogRequire(MemoryLayout<GLfloat>.size == MemoryLayout<Float>.size, "GLfloat")
    ogRequire(MemoryLayout<GLhalf>.size == MemoryLayout<UInt16>.size, "GLhalf")
    ogRequire(MemoryLayout<GLint>.size == MemoryLayout<Int32>.size, "GLint")
    ogRequire(MemoryLayout<GLint64>.size == MemoryLayout<Int64>.size, "GLint64")
    ogRequire(MemoryLayout<GLintptr>.size == MemoryLayout<Int>.size, "GLintptr")
    ogRequire(MemoryLayout<GLshort>.size == MemoryLayout<Int16>.size, "GLshort")
    ogRequire(MemoryLayout<GLsizei>.size == MemoryLayout<Int32>.size, "GLsizei")
    ogRequire(MemoryLayout<GLsizeiptr>.size == MemoryLayout<Int>.size, "GLsizeiptr")
    ogRequire(MemoryLayout<GLsync>.size == MemoryLayout<OpaquePointer>.size, "GLsync")
    ogRequire(MemoryLayout<GLubyte>.size == MemoryLayout<UInt8>.size, "GLubyte")
    ogRequire(MemoryLayout<GLuint>.size == MemoryLayout<UInt32>.size, "GLuint")
    ogRequire(MemoryLayout<GLuint64>.size == MemoryLayout<UInt64>.size, "GLuint64")
    ogRequire(MemoryLayout<GLushort>.size == MemoryLayout<UInt16>.size, "GLushort")
}

