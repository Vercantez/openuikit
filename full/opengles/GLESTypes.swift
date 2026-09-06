/// Khronos GLES scalar types from the public `gltypes.h` overlay.

public typealias GLbitfield = UInt32
public typealias GLboolean = UInt8
public typealias GLbyte = Int8
public typealias GLchar = CChar
public typealias GLclampf = Float
public typealias GLclampx = Int32
public typealias GLenum = UInt32
public typealias GLfixed = Int32
public typealias GLfloat = Float
public typealias GLhalf = UInt16
public typealias GLint = Int32
public typealias GLint64 = Int64
public typealias GLintptr = Int
public typealias GLshort = Int16
public typealias GLsizei = Int32
public typealias GLsizeiptr = Int
public typealias GLsync = OpaquePointer
public typealias GLubyte = UInt8
public typealias GLuint = UInt32
public typealias GLuint64 = UInt64
public typealias GLushort = UInt16

/// C `IOSurfaceRef` as an opaque pointer. `IOSurface.framework` is not a declared
/// OpenGLES dependency on this isolated host; texturing from a surface fail-closes.
public typealias IOSurfaceRef = OpaquePointer

func glEnum(_ token: Int32) -> GLenum {
    GLenum(bitPattern: token)
}

func glBool(_ token: Int32) -> GLboolean {
    token == 0 ? 0 : 1
}
