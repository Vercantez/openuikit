// Project-owned NSURL reference bridge for the standalone Foundation guest.
//
// FoundationEssentials deliberately builds its portable `_SwiftURL` without
// the Apple-framework-only NSURL bridge.  The Foundation facade owns that
// missing reference identity: it preserves URL relative/base state exactly,
// exposes the normal Foundation reference surface, and installs Swift's real
// `_ObjectiveCBridgeable` conversion rather than requiring app-side casts or
// wrappers.

import FoundationEssentials
import ObjectiveC

/// Decorates value types backed by a Foundation reference type.
///
/// This is the public Foundation protocol Apple uses for URL and its other
/// bridged value types.  The associated reference must participate in the
/// Objective-C object and immutable-copy contracts.
public protocol ReferenceConvertible: CustomStringConvertible,
    CustomDebugStringConvertible, Hashable, _ObjectiveCBridgeable {
    associatedtype ReferenceType: ObjectiveC.NSObject, NSCopying
}

open class NSURL: ObjectiveC.NSObject, NSCopying, @unchecked Sendable {
    internal let _foundationGuestURL: URL

    internal init(_foundationGuestURL url: URL) {
        _foundationGuestURL = url
        super.init()
    }

    @available(*, unavailable, message: "use a URL initializer")
    public override init() {
        preconditionFailure("NSURL requires a URL value")
    }

    public convenience init?(string URLString: String) {
        self.init(string: URLString, relativeTo: nil)
    }

    public init?(string URLString: String, relativeTo baseURL: URL?) {
        guard let url = URL(string: URLString, relativeTo: baseURL) else {
            return nil
        }
        _foundationGuestURL = url
        super.init()
    }

    public init(
        fileURLWithPath path: String,
        isDirectory: Bool,
        relativeTo baseURL: URL?
    ) {
        _foundationGuestURL = URL(
            fileURLWithPath: path,
            isDirectory: isDirectory,
            relativeTo: baseURL
        )
        super.init()
    }

    public convenience init(
        fileURLWithPath path: String,
        relativeTo baseURL: URL?
    ) {
        self.init(
            fileURLWithPath: path,
            isDirectory: path.hasSuffix("/"),
            relativeTo: baseURL
        )
    }

    public convenience init(fileURLWithPath path: String, isDirectory: Bool) {
        self.init(
            fileURLWithPath: path,
            isDirectory: isDirectory,
            relativeTo: nil
        )
    }

    public convenience init(fileURLWithPath path: String) {
        self.init(fileURLWithPath: path, relativeTo: nil)
    }

    public convenience init(
        fileURLWithFileSystemRepresentation path: UnsafePointer<CChar>,
        isDirectory: Bool,
        relativeTo baseURL: URL?
    ) {
        self.init(
            fileURLWithPath: String(cString: path),
            isDirectory: isDirectory,
            relativeTo: baseURL
        )
    }

    public init(dataRepresentation data: Data, relativeTo baseURL: URL?) {
        guard let url = URL(dataRepresentation: data, relativeTo: baseURL) else {
            preconditionFailure("NSURL data representation is not a legal URL")
        }
        _foundationGuestURL = url
        super.init()
    }

    open var absoluteString: String? { _foundationGuestURL.absoluteString }
    open var relativeString: String { _foundationGuestURL.relativeString }
    open var baseURL: URL? { _foundationGuestURL.baseURL }
    open var absoluteURL: URL? { _foundationGuestURL.absoluteURL }
    open var dataRepresentation: Data { _foundationGuestURL.dataRepresentation }

    open var scheme: String? { _foundationGuestURL.scheme }
    open var host: String? { _foundationGuestURL.host }
    open var port: NSNumber? {
        _foundationGuestURL.port.map { NSNumber(value: $0) }
    }
    open var user: String? { _foundationGuestURL.user }
    open var password: String? { _foundationGuestURL.password }
    open var path: String? { _foundationGuestURL.path }
    open var query: String? { _foundationGuestURL.query }
    open var fragment: String? { _foundationGuestURL.fragment }
    open var relativePath: String? { _foundationGuestURL.relativePath }
    open var isFileURL: Bool { _foundationGuestURL.isFileURL }
    open var hasDirectoryPath: Bool { _foundationGuestURL.hasDirectoryPath }
    open var pathComponents: [String]? { _foundationGuestURL.pathComponents }
    open var lastPathComponent: String? { _foundationGuestURL.lastPathComponent }
    open var pathExtension: String? { _foundationGuestURL.pathExtension }

    open override var hash: Int { _foundationGuestURL.hashValue }

    open override func isEqual(_ object: Any?) -> Bool {
        guard let other = object as? NSURL else { return false }
        return _foundationGuestURL == other._foundationGuestURL
    }

    open var description: String {
        if relativeString != _foundationGuestURL.absoluteString,
           let baseURL {
            return "\(relativeString) -- \(baseURL)"
        }
        return _foundationGuestURL.absoluteString
    }

    open var debugDescription: String { description }

    open func copy(with zone: NSZone? = nil) -> Any {
        _ = zone
        return self
    }

    open override func copy() -> Any { copy(with: nil) }
}

extension URL: @retroactive ReferenceConvertible,
    @retroactive _ObjectiveCBridgeable {
    public typealias ReferenceType = NSURL
    public typealias _ObjectiveCType = NSURL

    @_semantics("convertToObjectiveC")
    public func _bridgeToObjectiveC() -> NSURL {
        NSURL(_foundationGuestURL: self)
    }

    public static func _forceBridgeFromObjectiveC(
        _ source: NSURL,
        result: inout URL?
    ) {
        result = source._foundationGuestURL
    }

    public static func _conditionallyBridgeFromObjectiveC(
        _ source: NSURL,
        result: inout URL?
    ) -> Bool {
        result = source._foundationGuestURL
        return true
    }

    @_effects(readonly)
    public static func _unconditionallyBridgeFromObjectiveC(
        _ source: NSURL?
    ) -> URL {
        source!._foundationGuestURL
    }
}

extension NSURL: _HasCustomAnyHashableRepresentation {
    @nonobjc
    public func _toCustomAnyHashable() -> AnyHashable? {
        AnyHashable(_foundationGuestURL)
    }
}
