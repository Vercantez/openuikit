import Foundation
#if canImport(ModelIO)
import ModelIO
#endif
#if canImport(OpenGLES)
import OpenGLES
#endif

#if canImport(ModelIO) && canImport(OpenGLES)
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
    open private(set) var vertexDescriptor: MDLVertexDescriptor

    public init(mesh: MDLMesh) throws {
        self.vertexDescriptor = mesh.vertexDescriptor
        super.init()
        throw NSError(
            domain: kGLKModelErrorDomain,
            code: 1,
            userInfo: [kGLKModelErrorKey: "GLKMesh GPU upload is unavailable in this port"]
        )
    }

    open class func newMeshes(
        from asset: MDLAsset,
        sourceMeshes: AutoreleasingUnsafeMutablePointer<NSArray?>?
    ) throws -> [GLKMesh] {
        _ = asset
        sourceMeshes?.pointee = nil
        throw NSError(
            domain: kGLKModelErrorDomain,
            code: 1,
            userInfo: [kGLKModelErrorKey: "GLKMesh GPU upload is unavailable in this port"]
        )
    }
}

public func GLKVertexAttributeParametersFromModelIO(
    _ vertexFormat: MDLVertexFormat
) -> GLKVertexAttributeParameters {
    _ = vertexFormat
    return GLKVertexAttributeParameters(type: 0, size: 0, normalized: 0)
}
#endif
