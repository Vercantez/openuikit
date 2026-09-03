import CoreGraphics
import Foundation
import Metal

open class MTKTextureLoader: NSObject, @unchecked Sendable {
    public struct Error: RawRepresentable, Hashable, Equatable, Sendable {
        public let rawValue: String

        public init(rawValue: String) {
            self.rawValue = rawValue
        }

        public static let domain = Error(rawValue: "MTKTextureLoaderErrorDomain")
        public static let key = Error(rawValue: "MTKTextureLoaderErrorKey")
    }

    public struct Option: RawRepresentable, Hashable, Equatable, Sendable {
        public let rawValue: String

        public init(rawValue: String) {
            self.rawValue = rawValue
        }

        public static let allocateMipmaps = Option(rawValue: "MTKTextureLoaderOptionAllocateMipmaps")
        public static let generateMipmaps = Option(rawValue: "MTKTextureLoaderOptionGenerateMipmaps")
        public static let SRGB = Option(rawValue: "MTKTextureLoaderOptionSRGB")
        public static let textureUsage = Option(rawValue: "MTKTextureLoaderOptionTextureUsage")
        public static let textureCPUCacheMode = Option(rawValue: "MTKTextureLoaderOptionTextureCPUCacheMode")
        public static let textureStorageMode = Option(rawValue: "MTKTextureLoaderOptionTextureStorageMode")
        public static let cubeLayout = Option(rawValue: "MTKTextureLoaderOptionCubeLayout")
        public static let origin = Option(rawValue: "MTKTextureLoaderOptionOrigin")
        public static let loadAsArray = Option(rawValue: "MTKTextureLoaderOptionLoadAsArray")
    }

    public struct Origin: RawRepresentable, Hashable, Equatable, Sendable {
        public let rawValue: String

        public init(rawValue: String) {
            self.rawValue = rawValue
        }

        public static let topLeft = Origin(rawValue: "MTKTextureLoaderOriginTopLeft")
        public static let bottomLeft = Origin(rawValue: "MTKTextureLoaderOriginBottomLeft")
        public static let flippedVertically = Origin(rawValue: "MTKTextureLoaderOriginFlippedVertically")
    }

    public struct CubeLayout: RawRepresentable, Hashable, Equatable, Sendable {
        public let rawValue: String

        public init(rawValue: String) {
            self.rawValue = rawValue
        }

        public static let vertical = CubeLayout(rawValue: "MTKTextureLoaderCubeLayoutVertical")
    }

    public typealias Callback = ((any MTLTexture)?, (any Swift.Error)?) -> Void
    public typealias ArrayCallback = ([any MTLTexture], (any Swift.Error)?) -> Void

    public let device: any MTLDevice

    public init(device: any MTLDevice) {
        self.device = device
        super.init()
    }

    public func newTexture(
        cgImage: CGImage,
        options: [MTKTextureLoader.Option: Any]? = nil
    ) throws -> any MTLTexture {
        _ = (cgImage, options)
        throw failClosedError("CGImage texture upload needs ImageIO plus a GPU texture path")
    }

    public func newTexture(
        cgImage: CGImage,
        options: [MTKTextureLoader.Option: Any]? = nil
    ) async throws -> any MTLTexture {
        _ = (cgImage, options)
        try await hopFailClosed("CGImage texture upload needs ImageIO plus a GPU texture path")
    }

    public func newTexture(
        URL: URL,
        options: [MTKTextureLoader.Option: Any]? = nil
    ) throws -> any MTLTexture {
        _ = (URL, options)
        throw failClosedError("URL texture decode needs ImageIO; this Linux starting point is fail-closed")
    }

    public func newTexture(
        URL: URL,
        options: [MTKTextureLoader.Option: Any]? = nil
    ) async throws -> any MTLTexture {
        _ = (URL, options)
        try await hopFailClosed("URL texture decode needs ImageIO; this Linux starting point is fail-closed")
    }

    public func newTexture(
        data: Data,
        options: [MTKTextureLoader.Option: Any]? = nil
    ) throws -> any MTLTexture {
        _ = (data, options)
        throw failClosedError("Data texture decode needs ImageIO; this Linux starting point is fail-closed")
    }

    public func newTexture(
        data: Data,
        options: [MTKTextureLoader.Option: Any]? = nil
    ) async throws -> any MTLTexture {
        _ = (data, options)
        try await hopFailClosed("Data texture decode needs ImageIO; this Linux starting point is fail-closed")
    }

    public func newTexture(
        name: String,
        scaleFactor: CGFloat,
        bundle: Bundle?,
        options: [MTKTextureLoader.Option: Any]? = nil
    ) throws -> any MTLTexture {
        _ = (name, scaleFactor, bundle, options)
        throw failClosedError("Named asset textures are unavailable without ImageIO and an asset catalog host")
    }

    public func newTexture(
        name: String,
        scaleFactor: CGFloat,
        bundle: Bundle?,
        options: [MTKTextureLoader.Option: Any]? = nil
    ) async throws -> any MTLTexture {
        _ = (name, scaleFactor, bundle, options)
        try await hopFailClosed("Named asset textures are unavailable without ImageIO and an asset catalog host")
    }

    public func newTextures(
        URLs: [URL],
        options: [MTKTextureLoader.Option: Any]? = nil
    ) async throws -> [any MTLTexture] {
        _ = (URLs, options)
        try await hopFailClosed("URL array texture decode needs ImageIO; this Linux starting point is fail-closed")
    }

    public func newTextures(
        URLs: [URL],
        options: [MTKTextureLoader.Option: Any]? = nil,
        error outError: UnsafeMutablePointer<NSError?>?
    ) -> [any MTLTexture] {
        do {
            _ = (URLs, options)
            throw failClosedError(
                "URL array texture decode needs ImageIO; this Linux starting point is fail-closed"
            )
        } catch let nsError as NSError {
            outError?.pointee = nsError
            return []
        } catch {
            outError?.pointee = failClosedError("URL array texture decode needs ImageIO")
            return []
        }
    }

    public func newTextures(
        names: [String],
        scaleFactor: CGFloat,
        bundle: Bundle?,
        options: [MTKTextureLoader.Option: Any]? = nil
    ) async throws -> [any MTLTexture] {
        _ = (names, scaleFactor, bundle, options)
        try await hopFailClosed("Named asset textures are unavailable without ImageIO and an asset catalog host")
    }

    private func hopFailClosed(_ message: String) async throws -> Never {
        let text = message
        do {
            try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Swift.Error>) in
                MetalKitTextureCompletion.hop {
                    continuation.resume(throwing: self.failClosedError(text))
                }
            }
        } catch {
            throw error
        }
        throw failClosedError(text)
    }

    private func failClosedError(_ message: String) -> NSError {
        NSError(
            domain: MTKTextureLoader.Error.domain.rawValue,
            code: 0,
            userInfo: [
                NSLocalizedDescriptionKey: message,
                MTKTextureLoader.Error.key.rawValue: message,
            ]
        )
    }
}
