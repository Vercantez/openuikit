import Foundation

public final class BEMediaEnvironment: NSObject, @unchecked Sendable {
    public let webPageURL: URL?
    public private(set) var isActive = false

    public init(webPage url: URL) {
        webPageURL = url
        super.init()
    }

    public init(xpcRepresentation: xpc_object_t) throws {
        _ = xpcRepresentation
        webPageURL = nil
        super.init()
        throw BrowserEngineKitHostError.mediaSessionUnavailable
    }

    public func createXPCRepresentation() -> xpc_object_t {
        BEHostXPCObject()
    }

    public func activate() throws {
        throw BrowserEngineKitHostError.mediaSessionUnavailable
    }

    public func suspend() throws {
        throw BrowserEngineKitHostError.mediaSessionUnavailable
    }

    public func makeCaptureSession() throws -> AVCaptureSession {
        throw BrowserEngineKitHostError.mediaSessionUnavailable
    }
}

public struct MediaEnvironment: Equatable {
    public let webPageURL: URL?
    public private(set) var isActive = false

    public init(webPage url: URL) {
        webPageURL = url
    }

    public init(xpcRepresentation: xpc_object_t) throws {
        _ = xpcRepresentation
        throw BrowserEngineKitHostError.mediaSessionUnavailable
    }

    public func createXPCRepresentation() -> xpc_object_t {
        BEHostXPCObject()
    }

    public func activate() throws {
        throw BrowserEngineKitHostError.mediaSessionUnavailable
    }

    public func suspend() throws {
        throw BrowserEngineKitHostError.mediaSessionUnavailable
    }

    public func makeCaptureSession() throws -> AVCaptureSession {
        throw BrowserEngineKitHostError.mediaSessionUnavailable
    }
}
