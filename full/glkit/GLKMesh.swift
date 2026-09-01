import Foundation

public struct GLKModelError: Error, CustomNSError, Hashable, Equatable, @unchecked Sendable {
    public enum Code: Int, Hashable, Sendable {
        case gpuUnavailable = 1
    }

    public let code: Code
    public let userInfo: [String: Any]

    public init(_ code: Code, userInfo: [String: Any] = [:]) {
        self.code = code
        self.userInfo = userInfo
    }

    public static var errorDomain: String { kGLKModelErrorDomain }
    public var errorCode: Int { code.rawValue }
    public var errorUserInfo: [String: Any] { userInfo }

    public static func == (lhs: GLKModelError, rhs: GLKModelError) -> Bool {
        lhs.code == rhs.code
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(code)
    }
}

private func glkModelUnavailable() -> GLKModelError {
    GLKModelError(
        .gpuUnavailable,
        userInfo: [
            NSLocalizedDescriptionKey: "GLKMesh requires OpenGL buffer objects, which Linux GLKit does not provide.",
            kGLKModelErrorKey: NSNumber(value: GLKModelError.Code.gpuUnavailable.rawValue),
        ]
    )
}

open class GLKMeshBufferAllocator: NSObject {}

open class GLKMeshBuffer: NSObject {
    open private(set) var length: Int = 0
    open private(set) var offset: Int = 0
    open private(set) var glBufferName: GLuint = 0
    open private(set) var type: MDLMeshBufferType = .vertex
    public let allocator = GLKMeshBufferAllocator()

    open func zone() -> (any MDLMeshBufferZone)? { nil }
}

open class GLKSubmesh: NSObject {
    open private(set) var type: GLenum = 0
    open private(set) var mode: GLenum = 0
    open private(set) var elementCount: GLsizei = 0
    open private(set) var name: String = ""
    public let elementBuffer = GLKMeshBuffer()
    public weak var mesh: GLKMesh?
}

open class GLKMesh: NSObject {
    open private(set) var name: String = ""
    open private(set) var vertexCount: Int = 0
    open private(set) var vertexBuffers: [GLKMeshBuffer] = []
    open private(set) var submeshes: [GLKSubmesh] = []
    open private(set) var vertexDescriptor = MDLVertexDescriptor()

    public init(mesh: MDLMesh) throws {
        super.init()
        _ = mesh
        throw glkModelUnavailable()
    }

    open class func newMeshes(
        from asset: MDLAsset,
        sourceMeshes: UnsafeMutablePointer<NSArray?>?
    ) throws -> [GLKMesh] {
        _ = asset
        sourceMeshes?.pointee = nil
        throw glkModelUnavailable()
    }
}

public func GLKVertexAttributeParametersFromModelIO(_ vertexFormat: MDLVertexFormat) -> GLKVertexAttributeParameters {
    let packed = (vertexFormat.rawValue & MDLVertexFormat.packedBit.rawValue) != 0
    let bits = vertexFormat.rawValue & ~MDLVertexFormat.packedBit.rawValue
    let family = bits & 0xFFFF0000
    let size = GLint(bits & 0xF)
    if size == 0 || vertexFormat == .invalid {
        return GLKVertexAttributeParameters(type: 0, size: 0, normalized: GL_FALSE)
    }

    let normalized: GLboolean
    let type: GLenum
    switch family {
    case MDLVertexFormat.uCharBits.rawValue:
        type = GL_UNSIGNED_BYTE
        normalized = GL_FALSE
    case MDLVertexFormat.charBits.rawValue:
        type = GL_BYTE
        normalized = GL_FALSE
    case MDLVertexFormat.uCharNormalizedBits.rawValue:
        type = GL_UNSIGNED_BYTE
        normalized = GL_TRUE
    case MDLVertexFormat.charNormalizedBits.rawValue:
        type = GL_BYTE
        normalized = GL_TRUE
    case MDLVertexFormat.uShortBits.rawValue:
        type = GL_UNSIGNED_SHORT
        normalized = GL_FALSE
    case MDLVertexFormat.shortBits.rawValue:
        type = GL_SHORT
        normalized = GL_FALSE
    case MDLVertexFormat.uShortNormalizedBits.rawValue:
        type = GL_UNSIGNED_SHORT
        normalized = GL_TRUE
    case MDLVertexFormat.shortNormalizedBits.rawValue:
        type = GL_SHORT
        normalized = GL_TRUE
    case MDLVertexFormat.uIntBits.rawValue:
        type = GL_UNSIGNED_INT
        normalized = GL_FALSE
    case MDLVertexFormat.intBits.rawValue:
        type = GL_INT
        normalized = GL_FALSE
    case MDLVertexFormat.halfBits.rawValue:
        type = GL_HALF_FLOAT
        normalized = GL_FALSE
    case MDLVertexFormat.floatBits.rawValue:
        type = GL_FLOAT
        normalized = GL_FALSE
    default:
        return GLKVertexAttributeParameters(type: 0, size: 0, normalized: GL_FALSE)
    }

    _ = packed
    return GLKVertexAttributeParameters(type: type, size: size, normalized: normalized)
}
