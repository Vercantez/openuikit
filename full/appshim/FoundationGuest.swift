// First reusable Foundation umbrella slice for Linux-hosted Mach-O guests.
// FoundationEssentials owns its value types and pinned Combine owns the
// observation identity. OpenUIKit continues to own the archive/bundle
// identities it was compiled against while the complete swift-foundation
// umbrella remains future work.
@_exported import FoundationEssentials
@_exported import FoundationInternationalization
@_exported import Combine
@_exported import Dispatch
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

// Foundation-visible adapters for the hidden UIKit guest boundary.
import ObjectiveC
import Darwin

public typealias NSMutableURLRequest = URLRequest
public typealias NSKeyValueChangeKey = OpenUIKit.NSKeyValueChangeKey

public extension FileManager {
    func fileExists(atPath path: String, isDirectory: UnsafeMutablePointer<ObjCBool>?) -> Bool {
        var directory = false
        let exists = fileExists(atPath: path, isDirectory: &directory)
        isDirectory?.pointee = ObjCBool(directory)
        return exists
    }
}
public func NSTemporaryDirectory() -> String {
    let path = getenv("TMPDIR").map { String(cString: $0) }.flatMap { $0.isEmpty ? nil : $0 } ?? "/tmp"
    return path.hasSuffix("/") ? path : path + "/"
}
public func NSSearchPathForDirectoriesInDomains(_ directory: FileManager.SearchPathDirectory,
    _ domainMask: FileManager.SearchPathDomainMask, _ expandTilde: Bool) -> [String] {
    if domainMask == .userDomainMask {
        let suffix: String
        switch directory {
        case .cachesDirectory: suffix = "/Library/Caches"
        case .libraryDirectory: suffix = "/Library"
        case .applicationSupportDirectory: suffix = "/Library/Application Support"
        case .documentDirectory: suffix = "/Documents"
        default: return []
        }
        let home = getenv("CFFIXED_USER_HOME") ?? getenv("HOME")
        guard let home else { return [] }
        return [(expandTilde ? String(cString: home) : "~") + suffix]
    }
    return []
}
public extension FileManager {
    func urls(for directory: SearchPathDirectory, in domainMask: SearchPathDomainMask) -> [URL] {
        NSSearchPathForDirectoriesInDomains(directory, domainMask, true).map {
            URL(fileURLWithPath: $0, isDirectory: true)
        }
    }
}
public extension OpenUIKit.NSRange {
    init(_ range: Range<String.Index>, in string: String) {
        self.init(location: range.lowerBound.utf16Offset(in: string),
                  length: range.upperBound.utf16Offset(in: string) - range.lowerBound.utf16Offset(in: string))
    }
}
public extension Substring {
    func replacingOccurrences(of target: String, with replacement: String) -> String {
        String(self).replacingOccurrences(of: target, with: replacement)
    }
}
public extension UIPasteboard {
    var url: URL? {
        get { urls?.first }
        set { urls = newValue.map { [$0] } }
    }
    var urls: [URL]? {
        get { items.compactMap { ($0["public.url"] as? String).flatMap(URL.init(string:)) } }
        set { items = (newValue ?? []).map { ["public.url": $0.absoluteString] } }
    }
}
public enum CFNetworkErrors: Int { case cfurlErrorCancelled = -999 }
public func CFURLCreateStringByReplacingPercentEscapes(_ allocator: CFAllocator?,
    _ original: CFString, _ leaveEscaped: CFString) -> CFString {
    precondition(allocator == nil && leaveEscaped.isEmpty,
                 "guest percent decoding supports the default allocator and no exclusions")
    return original.removingPercentEncoding ?? original
}
public extension NSObject {
    func perform(_ selector: Selector, with object: Any?, afterDelay delay: TimeInterval) {
        Timer.scheduledTimer(withTimeInterval: delay, repeats: false) { [self] _ in
            _ = perform(selector, with: object)
        }
    }
}
open class NSValue: NSObject {
    public let cgRectValue: CGRect
    public init(cgRect: CGRect) { cgRectValue = cgRect; super.init() }
}
public enum NSKeyedArchiver {
    public static func archivedData(withRootObject root: Any, requiringSecureCoding: Bool) throws -> Data {
        throw NSError(domain: NSCocoaErrorDomain, code: 4866,
                      userInfo: [NSLocalizedDescriptionKey: "Guest keyed archive persistence is unavailable"])
    }
}
public enum NSKeyedUnarchiver {
    public static func unarchiveTopLevelObjectWithData(_ data: Data) throws -> Any? {
        throw NSError(domain: NSCocoaErrorDomain, code: 4864,
                      userInfo: [NSLocalizedDescriptionKey: "Guest keyed archive persistence is unavailable"])
    }
}

public func os_log(_ message: StaticString, log: OSLog, type: OSLogType, _ argument: String) {
    // Logging stays on the guest console; no Apple os logging service exists.
    print(argument)
}
public extension NSItemProvider {
    convenience init?(contentsOf url: URL) {
        // File-backed drag representations are unavailable on the guest.
        return nil
    }
}
