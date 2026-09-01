import Dispatch
import Foundation

public typealias GLKTextureLoaderCallback = (GLKTextureInfo?, (any Error)?) -> Void

open class GLKTextureInfo: NSObject {
    open private(set) var name: GLuint = 0
    open private(set) var target: GLenum = GL_TEXTURE_2D
    open private(set) var width: GLuint = 0
    open private(set) var height: GLuint = 0
    open private(set) var depth: GLuint = 0
    open private(set) var alphaState: GLKTextureInfoAlphaState = .none
    open private(set) var textureOrigin: GLKTextureInfoOrigin = .unknown
    open private(set) var containsMipmaps: Bool = false
    open private(set) var mimapLevelCount: GLuint = 0
    open private(set) var arrayLength: GLuint = 0
}

private func glkTextureLoaderUnavailable() -> GLKTextureLoaderError {
    GLKTextureLoaderError(
        .invalidEAGLContext,
        userInfo: [
            NSLocalizedDescriptionKey: "GLKTextureLoader requires an EAGL/OpenGL ES context, which Linux GLKit does not provide.",
            GLKTextureLoaderErrorKey: NSNumber(value: GLKTextureLoaderError.Code.invalidEAGLContext.rawValue),
        ]
    )
}

open class GLKTextureLoader: NSObject {
    public let sharegroup: EAGLSharegroup

    public init(sharegroup: EAGLSharegroup) {
        self.sharegroup = sharegroup
        super.init()
    }

    open class func texture(withContentsOfFile path: String, options: [String: NSNumber]? = nil) throws -> GLKTextureInfo {
        _ = path
        _ = options
        throw glkTextureLoaderUnavailable()
    }

    open class func texture(withContentsOf url: URL, options: [String: NSNumber]? = nil) throws -> GLKTextureInfo {
        _ = url
        _ = options
        throw glkTextureLoaderUnavailable()
    }

    open class func texture(withContentsOf data: Data, options: [String: NSNumber]? = nil) throws -> GLKTextureInfo {
        _ = data
        _ = options
        throw glkTextureLoaderUnavailable()
    }

    open class func texture(with cgImage: CGImage, options: [String: NSNumber]? = nil) throws -> GLKTextureInfo {
        _ = cgImage
        _ = options
        throw glkTextureLoaderUnavailable()
    }

    open class func texture(
        withName name: String,
        scaleFactor: CGFloat,
        bundle: Bundle?,
        options: [String: NSNumber]? = nil
    ) throws -> GLKTextureInfo {
        _ = name
        _ = scaleFactor
        _ = bundle
        _ = options
        throw glkTextureLoaderUnavailable()
    }

    open class func cubeMap(withContentsOfFile path: String, options: [String: NSNumber]? = nil) throws -> GLKTextureInfo {
        _ = path
        _ = options
        throw glkTextureLoaderUnavailable()
    }

    open class func cubeMap(withContentsOfFiles paths: [Any], options: [String: NSNumber]? = nil) throws -> GLKTextureInfo {
        _ = paths
        _ = options
        throw glkTextureLoaderUnavailable()
    }

    open class func cubeMap(withContentsOf url: URL, options: [String: NSNumber]? = nil) throws -> GLKTextureInfo {
        _ = url
        _ = options
        throw glkTextureLoaderUnavailable()
    }

    open func texture(withContentsOfFile path: String, options: [String: NSNumber]? = nil, queue: dispatch_queue_t?) async throws -> GLKTextureInfo {
        _ = queue
        return try Self.texture(withContentsOfFile: path, options: options)
    }

    open func texture(withContentsOf url: URL, options: [String: NSNumber]? = nil, queue: dispatch_queue_t?) async throws -> GLKTextureInfo {
        _ = queue
        return try Self.texture(withContentsOf: url, options: options)
    }

    open func texture(withContentsOf data: Data, options: [String: NSNumber]? = nil, queue: dispatch_queue_t?) async throws -> GLKTextureInfo {
        _ = queue
        return try Self.texture(withContentsOf: data, options: options)
    }

    open func texture(with cgImage: CGImage, options: [String: NSNumber]? = nil, queue: dispatch_queue_t?) async throws -> GLKTextureInfo {
        _ = queue
        return try Self.texture(with: cgImage, options: options)
    }

    open func texture(
        withName name: String,
        scaleFactor: CGFloat,
        bundle: Bundle?,
        options: [String: NSNumber]? = nil,
        queue: dispatch_queue_t?
    ) async throws -> GLKTextureInfo {
        _ = queue
        return try Self.texture(withName: name, scaleFactor: scaleFactor, bundle: bundle, options: options)
    }

    open func cubeMap(withContentsOfFile path: String, options: [String: NSNumber]? = nil, queue: dispatch_queue_t?) async throws -> GLKTextureInfo {
        _ = queue
        return try Self.cubeMap(withContentsOfFile: path, options: options)
    }

    open func cubeMap(withContentsOfFiles paths: [Any], options: [String: NSNumber]? = nil, queue: dispatch_queue_t?) async throws -> GLKTextureInfo {
        _ = queue
        return try Self.cubeMap(withContentsOfFiles: paths, options: options)
    }

    open func cubeMap(withContentsOf url: URL, options: [String: NSNumber]? = nil, queue: dispatch_queue_t?) async throws -> GLKTextureInfo {
        _ = queue
        return try Self.cubeMap(withContentsOf: url, options: options)
    }
}
