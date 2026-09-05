// Linux starting point for Apple's public MetalKit module.
//
// Isolated host compilation uses toolchain Foundation only. Metal, UIKit,
// CoreGraphics, QuartzCore, and ModelIO types that appear in public
// signatures are module-local lookalikes. Texture decode is fail-closed.
// Mesh conversion copies ModelIO buffers into software MTLBuffers.

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
