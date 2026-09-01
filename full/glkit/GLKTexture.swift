import Dispatch
import Foundation
#if canImport(CoreGraphics)
import CoreGraphics
#endif
#if canImport(OpenGLES)
import OpenGLES
#endif

public typealias GLKTextureLoaderCallback = (GLKTextureInfo?, (any Error)?) -> Void

open class GLKTextureInfo: NSObject {
#if canImport(OpenGLES)
    open private(set) var name: GLuint = 0
    open private(set) var target: GLenum = 0
    open private(set) var width: GLuint = 0
    open private(set) var height: GLuint = 0
    open private(set) var depth: GLuint = 0
    open private(set) var mimapLevelCount: GLuint = 0
    open private(set) var arrayLength: GLuint = 0
#else
    open private(set) var name: UInt32 = 0
    open private(set) var target: UInt32 = 0
    open private(set) var width: UInt32 = 0
    open private(set) var height: UInt32 = 0
    open private(set) var depth: UInt32 = 0
    open private(set) var mimapLevelCount: UInt32 = 0
    open private(set) var arrayLength: UInt32 = 0
#endif
    open private(set) var alphaState: GLKTextureInfoAlphaState = .none
    open private(set) var textureOrigin: GLKTextureInfoOrigin = .unknown
    open private(set) var containsMipmaps: Bool = false
}

private final class GLKTextureCallbackOnce: @unchecked Sendable {
    private let lock = NSLock()
    private var consumed = false

    func run(_ body: () -> Void) {
        lock.lock()
        let first = !consumed
        consumed = true
        lock.unlock()
        if first {
            body()
        }
    }
}

open class GLKTextureLoader: NSObject {
#if canImport(OpenGLES)
    public let sharegroup: EAGLSharegroup

    public init(sharegroup: EAGLSharegroup) {
        self.sharegroup = sharegroup
        super.init()
    }
#else
    @_spi(OpenUIKitHost)
    public override init() {
        super.init()
    }
#endif

    private func unavailableTextureError() -> GLKTextureLoaderError {
        GLKTextureLoaderError(.invalidEAGLContext)
    }

    /// Deliver `handler` exactly once, asynchronously, on `queue` when provided.
    /// A nil queue uses a host global queue; that default is not claimed as Apple's.
    private func completeOnce(
        queue: DispatchQueue?,
        handler: @escaping GLKTextureLoaderCallback
    ) {
        let error = unavailableTextureError()
        let once = GLKTextureCallbackOnce()
        let delivery = queue ?? DispatchQueue.global(qos: .userInitiated)
        delivery.async {
            once.run {
                handler(nil, error)
            }
        }
    }

    open class func texture(withContentsOfFile path: String, options: [String: NSNumber]? = nil) throws -> GLKTextureInfo {
        _ = path
        _ = options
        throw GLKTextureLoaderError(.invalidEAGLContext)
    }

    open class func texture(withContentsOf url: URL, options: [String: NSNumber]? = nil) throws -> GLKTextureInfo {
        _ = url
        _ = options
        throw GLKTextureLoaderError(.invalidEAGLContext)
    }

    open class func texture(withContentsOf data: Data, options: [String: NSNumber]? = nil) throws -> GLKTextureInfo {
        _ = data
        _ = options
        throw GLKTextureLoaderError(.invalidEAGLContext)
    }

    open class func cubeMap(withContentsOfFile path: String, options: [String: NSNumber]? = nil) throws -> GLKTextureInfo {
        _ = path
        _ = options
        throw GLKTextureLoaderError(.invalidEAGLContext)
    }

    open class func cubeMap(withContentsOfFiles paths: [Any], options: [String: NSNumber]? = nil) throws -> GLKTextureInfo {
        _ = paths
        _ = options
        throw GLKTextureLoaderError(.invalidEAGLContext)
    }

    open class func cubeMap(withContentsOf url: URL, options: [String: NSNumber]? = nil) throws -> GLKTextureInfo {
        _ = url
        _ = options
        throw GLKTextureLoaderError(.invalidEAGLContext)
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
        throw GLKTextureLoaderError(.invalidEAGLContext)
    }

#if canImport(CoreGraphics)
    open class func texture(with cgImage: CGImage, options: [String: NSNumber]? = nil) throws -> GLKTextureInfo {
        _ = cgImage
        _ = options
        throw GLKTextureLoaderError(.invalidEAGLContext)
    }
#endif

    open func texture(
        withContentsOfFile path: String,
        options: [String: NSNumber]? = nil,
        queue: DispatchQueue?,
        completionHandler: @escaping GLKTextureLoaderCallback
    ) {
        _ = path
        _ = options
        completeOnce(queue: queue, handler: completionHandler)
    }

    open func texture(
        withContentsOf url: URL,
        options: [String: NSNumber]? = nil,
        queue: DispatchQueue?,
        completionHandler: @escaping GLKTextureLoaderCallback
    ) {
        _ = url
        _ = options
        completeOnce(queue: queue, handler: completionHandler)
    }

    open func texture(
        withContentsOf data: Data,
        options: [String: NSNumber]? = nil,
        queue: DispatchQueue?,
        completionHandler: @escaping GLKTextureLoaderCallback
    ) {
        _ = data
        _ = options
        completeOnce(queue: queue, handler: completionHandler)
    }

    open func texture(
        withName name: String,
        scaleFactor: CGFloat,
        bundle: Bundle?,
        options: [String: NSNumber]? = nil,
        queue: DispatchQueue?,
        completionHandler: @escaping GLKTextureLoaderCallback
    ) {
        _ = name
        _ = scaleFactor
        _ = bundle
        _ = options
        completeOnce(queue: queue, handler: completionHandler)
    }

    open func cubeMap(
        withContentsOfFile path: String,
        options: [String: NSNumber]? = nil,
        queue: DispatchQueue?,
        completionHandler: @escaping GLKTextureLoaderCallback
    ) {
        _ = path
        _ = options
        completeOnce(queue: queue, handler: completionHandler)
    }

    open func cubeMap(
        withContentsOfFiles paths: [Any],
        options: [String: NSNumber]? = nil,
        queue: DispatchQueue?,
        completionHandler: @escaping GLKTextureLoaderCallback
    ) {
        _ = paths
        _ = options
        completeOnce(queue: queue, handler: completionHandler)
    }

    open func cubeMap(
        withContentsOf url: URL,
        options: [String: NSNumber]? = nil,
        queue: DispatchQueue?,
        completionHandler: @escaping GLKTextureLoaderCallback
    ) {
        _ = url
        _ = options
        completeOnce(queue: queue, handler: completionHandler)
    }

#if canImport(CoreGraphics)
    open func texture(
        with cgImage: CGImage,
        options: [String: NSNumber]? = nil,
        queue: DispatchQueue?,
        completionHandler: @escaping GLKTextureLoaderCallback
    ) {
        _ = cgImage
        _ = options
        completeOnce(queue: queue, handler: completionHandler)
    }
#endif
}
