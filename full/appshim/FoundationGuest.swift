// First reusable Foundation umbrella slice for Linux-hosted Mach-O guests.
// FoundationEssentials owns its value types and pinned Combine owns the
// observation identity. OpenUIKit continues to own the archive/bundle
// identities it was compiled against while the complete swift-foundation
// umbrella remains future work.
@_exported import FoundationEssentials
@_exported import Combine
@_exported import OpenCoreGraphics
@_exported import os
import OpenUIKit

/// `isiOSAppOnMac` reports the Apple compatibility environment where an iOS
/// binary is hosted by macOS. Linux-hosted Mach-O guests are neither Catalyst
/// nor iOS-on-Mac, so the platform answer is deterministically false.
public extension ProcessInfo {
    var isiOSAppOnMac: Bool { false }
}

public typealias NSCoder = OpenUIKit.NSCoder
public typealias Bundle = OpenUIKit.Bundle

/// Mutable set storage required by unchanged SnapKit.
///
/// Hashable values use their declared equality/hash semantics, matching
/// NSSet's value behavior. A non-Hashable class is instead keyed by object
/// identity and is retained in the value store. Non-Hashable value types have
/// neither a principled hash nor reference identity and are rejected.
public final class NSMutableSet {
    private enum Key: Hashable {
        case value(AnyHashable)
        case identity(ObjectIdentifier)
    }

    private var storage: [Key: Any] = [:]

    public init() {}

    public var allObjects: [Any] {
        Array(storage.values)
    }

    public func add(_ object: Any) {
        let key = key(for: object)
        if storage[key] == nil {
            storage[key] = object
        }
    }

    public func remove(_ object: Any) {
        storage.removeValue(forKey: key(for: object))
    }

    private func key(for object: Any) -> Key {
        if let value = object as? AnyHashable {
            return .value(value)
        }
        if Mirror(reflecting: object).displayStyle == .class {
            return .identity(ObjectIdentifier(object as AnyObject))
        }
        preconditionFailure(
            "NSMutableSet requires a Hashable value or a class instance"
        )
    }
}

public extension UIApplication {
    func canOpenURL(_ url: URL) -> Bool {
        canOpenURL(url.absoluteString)
    }

    func open(
        _ url: URL,
        options: [OpenExternalURLOptionsKey: Any] = [:],
        completionHandler: ((Bool) -> Void)? = nil
    ) {
        open(
            url.absoluteString,
            options: options,
            completionHandler: completionHandler
        )
    }
}
