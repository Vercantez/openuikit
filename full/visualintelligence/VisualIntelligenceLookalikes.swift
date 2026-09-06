@_exported import Foundation

// Module-local stand-ins for types owned by undeclared modules (AppIntents,
// CoreVideo) and for Foundation.LocalizedStringResource, which is absent from
// this Linux swift-corelibs Foundation. They compile only when those Apple
// modules are missing. They are not Linux ports of those frameworks and are
// not declared dependencies of this seed (Foundation only).

#if !canImport(CoreVideo)
/// Stand-in for `CoreVideo.CVReadOnlyPixelBuffer`. Visual Intelligence never
/// supplies a camera-scene buffer on this Linux host.
public final class CVReadOnlyPixelBuffer: @unchecked Sendable {
    init() {}
}
#endif

#if !canImport(AppIntents)
/// Stand-in for `AppIntents.ResolverSpecification`. Linux has no App Intents
/// resolver runtime.
public protocol ResolverSpecification: Sendable {
    var linuxUnavailableToken: String { get }
}

/// Empty resolver used by `SemanticContentDescriptor.defaultResolverSpecification`.
public struct VisualIntelligenceUnavailableResolverSpecification: ResolverSpecification, Equatable, Hashable, Sendable {
    public static let linuxUnavailableToken = "VisualIntelligence.unavailableResolver"

    public var linuxUnavailableToken: String {
        Self.linuxUnavailableToken
    }

    public init() {}
}

/// Stand-in for `AppIntents.DisplayRepresentation`. Stores a Linux-host title
/// only; Darwin image/subtitle payloads are unobserved.
public struct DisplayRepresentation: Equatable, Hashable, Sendable {
    public var title: String

    public init(title: String) {
        self.title = title
    }
}

/// Stand-in for `AppIntents.TypeDisplayRepresentation`. Stores a Linux-host
/// type name only; Darwin localization is unobserved.
public struct TypeDisplayRepresentation: Equatable, Hashable, Sendable {
    public var name: String

    public init(name: String) {
        self.name = name
    }
}
#endif

/// Stand-in for `Foundation.LocalizedStringResource` on this Linux Foundation.
/// Darwin's resource catalog, table, and locale payloads are unobserved.
public struct LocalizedStringResource: ExpressibleByStringLiteral, Equatable, Hashable, Sendable {
    public let key: String

    public init(_ key: String) {
        self.key = key
    }

    public init(stringLiteral value: String) {
        self.key = value
    }
}

/// Linux fail-closed error when Apple Visual Intelligence (ML scene, App
/// Intents entity conversion, or camera buffer) is required. Domain and code
/// are this overlay, not a documented Apple `NSError` payload.
public let VisualIntelligenceLinuxUnavailableErrorDomain =
    "VisualIntelligence.LinuxUnavailable"

public struct VisualIntelligenceLinuxUnavailableError: Error, CustomNSError, Equatable, Hashable, Sendable {
    public static var errorDomain: String { VisualIntelligenceLinuxUnavailableErrorDomain }
    public var errorCode: Int { 1 }
    public var operation: String

    public var errorUserInfo: [String: Any] {
        [NSLocalizedDescriptionKey: Self.localizedReason(operation: operation)]
    }

    public static func localizedReason(operation: String) -> String {
        "Visual Intelligence has no Apple ML scene, App Intents resolver, or camera buffer on this Linux host (\(operation))"
    }

    public init(operation: String) {
        self.operation = operation
    }
}
