// Linux starting point for Apple's public MetalKit module.
//
// Isolated host compilation imports the real Metal / UIKit / CoreGraphics
// module names. On this VM those modules are a local fail-closed software
// Metal substrate plus a minimal UIView/CGImage surface; they are not vendored
// into this lane. ModelIO is not on main, so mesh conversion stays deferred.
// ImageIO is present as source but is not an importable module here, so
// texture decode is fail-closed rather than a fabricated GPU upload.

import Foundation

public struct MTKModelError: RawRepresentable, Hashable, Equatable, Sendable {
    public let rawValue: String

    public init(rawValue: String) {
        self.rawValue = rawValue
    }

    public static let domain = MTKModelError(rawValue: "MTKModelErrorDomain")
    public static let key = MTKModelError(rawValue: "MTKModelErrorKey")
}

enum MetalKitTextureCompletion {
    static let queue = DispatchQueue(label: "MetalKit.MTKTextureLoader.completion")

    static func hop(_ body: @escaping @Sendable () -> Void) {
        queue.async(execute: body)
    }
}

@_spi(OpenUIKitHost)
public enum MetalKitHostControl {
    public static func enqueueTextureCompletionProbe(_ body: @escaping @Sendable () -> Void) {
        MetalKitTextureCompletion.hop(body)
    }
}
