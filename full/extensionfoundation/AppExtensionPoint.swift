import Foundation
import Observation

enum AppExtensionPointRegistry {
    private static let lock = NSLock()
    private static var points: [String: AppExtensionPoint] = [:]

    static func register(_ point: AppExtensionPoint) {
        lock.lock()
        points[point.id] = point
        lock.unlock()
    }

    static func lookup(_ identifier: String) -> AppExtensionPoint? {
        lock.lock()
        defer { lock.unlock() }
        return points[identifier]
    }
}

/// A type you use to declare your host app’s extension points and bind to them
/// from app extensions.
public struct AppExtensionPoint: Hashable, Identifiable, Sendable, ExtensionPointDefining {
    public typealias ID = String

    /// Error codes for monitor-related requests.
    public enum Error: Swift.Error, Sendable {
        /// An error that indicates the specified extension point is unknown.
        case unspecifiedAppExtensionPointName
        /// An error that indicates the definition of an extension point in an unsupported target.
        case hostMustBeApplicationOrAppExtension
        /// An error that indicates the host app is missing its bundle identifier.
        case hostMustHaveBundleIdentifier
        /// An error that indicates an attempt to define an extension point outside an app.
        case hostMustDefineAppExtensionPoint(String)
        /// An error that indicates an attempt to bind to an unknown extension point.
        case invalidAppExtensionPoint
    }

    /// An interface that marks a type as an extension point attribute.
    public protocol Attribute {}

    /// A type that defines the name of an extension point.
    public struct Name: Sendable {
        let value: String

        public init(_ value: StaticString) {
            self.value = extensionFoundationString(value)
        }

        @_spi(OpenUIKitHost)
        public var host_value: String { value }
    }

    /// The details of an extension point that your app extension supports.
    public struct Identifier: Sendable {
        let hostBundle: String?
        let pointName: String

        /// Creates an identifier for binding to a system-defined extension point.
        public init(_ value: StaticString) {
            self.hostBundle = nil
            self.pointName = extensionFoundationString(value)
        }

        /// Creates an identifier for binding to a host app's extension point.
        public init(host bundleIdentifier: StaticString, name: StaticString) {
            self.hostBundle = extensionFoundationString(bundleIdentifier)
            self.pointName = extensionFoundationString(name)
        }

        var composedID: String {
            if let hostBundle {
                return "\(hostBundle)/\(pointName)"
            }
            return pointName
        }

        @_spi(OpenUIKitHost)
        public var host_bundleIdentifier: String? { hostBundle }

        @_spi(OpenUIKitHost)
        public var host_pointName: String { pointName }
    }

    /// A type that regulates which app extensions may access an extension point.
    public struct Scope: Attribute, Sendable {
        /// A type that indicates which app extensions may bind to a host app.
        public enum Restriction: Equatable, Hashable, Sendable {
            /// Requires an app extension to reside inside the same app to which it is binding.
            case application
            /// Allows app extensions in any app to bind to the host app.
            case none
        }

        let restriction: Restriction

        public init(restriction: Restriction = .application) {
            self.restriction = restriction
        }

        @_spi(OpenUIKitHost)
        public var host_restriction: Restriction { restriction }
    }

    /// A type that indicates whether the extension point displays UI from an app extension.
    public struct UserInterface: Attribute, Sendable {
        public let value: Bool

        public init(_ value: Bool = true) {
            self.value = value
        }
    }

    /// A type that indicates whether an extension point requires extra security.
    public struct EnhancedSecurity: Attribute, Sendable {
        let value: Bool

        public init(_ value: Bool = true) {
            self.value = value
        }

        @_spi(OpenUIKitHost)
        public var host_value: Bool { value }
    }

    /// A result builder a host app uses to declare the extension points it supports.
    @resultBuilder
    public struct Definition {
        public static func buildBlock<each T>(
            _ name: AppExtensionPoint.Name,
            _ attributes: repeat each T
        ) -> AppExtensionPoint where repeat each T: AppExtensionPoint.Attribute {
            var userInterface = false
            var enhancedSecurity = false
            var restriction = Scope.Restriction.application
            for item in repeat each attributes {
                if let interface = item as? UserInterface {
                    userInterface = interface.value
                } else if let security = item as? EnhancedSecurity {
                    enhancedSecurity = security.value
                } else if let scope = item as? Scope {
                    restriction = scope.restriction
                }
            }
            let point = AppExtensionPoint(
                id: name.value,
                userInterface: userInterface,
                enhancedSecurity: enhancedSecurity,
                restriction: restriction
            )
            AppExtensionPointRegistry.register(point)
            return point
        }
    }

    /// A result builder that binds an app extension to a host extension point.
    @resultBuilder
    public struct Bind {
        public static func buildBlock(_ identifier: Identifier) -> AppExtensionPoint {
            AppExtensionPoint(
                id: identifier.composedID,
                userInterface: false,
                enhancedSecurity: false,
                restriction: .application
            )
        }
    }

    public let id: String
    let userInterface: Bool
    let enhancedSecurity: Bool
    let restriction: Scope.Restriction

    init(
        id: String,
        userInterface: Bool,
        enhancedSecurity: Bool,
        restriction: Scope.Restriction
    ) {
        self.id = id
        self.userInterface = userInterface
        self.enhancedSecurity = enhancedSecurity
        self.restriction = restriction
    }

    /// Initializes the type by looking up a process-local definition.
    ///
    /// Linux has no system extension catalog. An empty identifier throws
    /// `unspecifiedAppExtensionPointName`. A name that was never produced by
    /// `Definition.buildBlock` throws `invalidAppExtensionPoint`.
    public init(identifier: StaticString) throws {
        let text = extensionFoundationString(identifier)
        if text.isEmpty {
            throw Error.unspecifiedAppExtensionPointName
        }
        guard let existing = AppExtensionPointRegistry.lookup(text) else {
            throw Error.invalidAppExtensionPoint
        }
        self = existing
    }

    public static func == (lhs: AppExtensionPoint, rhs: AppExtensionPoint) -> Bool {
        lhs.id == rhs.id
            && lhs.userInterface == rhs.userInterface
            && lhs.enhancedSecurity == rhs.enhancedSecurity
            && lhs.restriction == rhs.restriction
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
        hasher.combine(userInterface)
        hasher.combine(enhancedSecurity)
        hasher.combine(restriction)
    }

    @_spi(OpenUIKitHost)
    public var host_userInterface: Bool { userInterface }

    @_spi(OpenUIKitHost)
    public var host_enhancedSecurity: Bool { enhancedSecurity }

    @_spi(OpenUIKitHost)
    public var host_restriction: Scope.Restriction { restriction }
}

extension AppExtensionPoint.Error: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case .unspecifiedAppExtensionPointName:
            return "Unspecified app extension point name."
        case .hostMustBeApplicationOrAppExtension:
            return "Host must be an application or app extension."
        case .hostMustHaveBundleIdentifier:
            return "Host must have a bundle identifier."
        case .hostMustDefineAppExtensionPoint(let name):
            return "Host must define app extension point \(name)."
        case .invalidAppExtensionPoint:
            return "Invalid app extension point."
        }
    }
}

extension AppExtensionPoint {
    /// A type you use to discover the app extensions available for your host app to use.
    ///
    /// Linux never enumerates appexes. A fresh monitor reports empty identities
    /// and zero disabled/unapproved counts. Async add/remove record the point
    /// locally and still never invent identities.
    public final class Monitor: Observable, @unchecked Sendable {
        /// A snapshot of a monitor's state information.
        public struct State: Equatable, Sendable {
            public let identities: [AppExtensionIdentity]
            public let unapprovedCount: Int
            public let disabledCount: Int

            init(
                identities: [AppExtensionIdentity],
                unapprovedCount: Int,
                disabledCount: Int
            ) {
                self.identities = identities
                self.unapprovedCount = unapprovedCount
                self.disabledCount = disabledCount
            }

            @_spi(OpenUIKitHost)
            public init(
                hostIdentities identities: [AppExtensionIdentity],
                unapprovedCount: Int,
                disabledCount: Int
            ) {
                self.init(
                    identities: identities,
                    unapprovedCount: unapprovedCount,
                    disabledCount: disabledCount
                )
            }

            public static func == (a: State, b: State) -> Bool {
                a.identities == b.identities
                    && a.unapprovedCount == b.unapprovedCount
                    && a.disabledCount == b.disabledCount
            }
        }

        private let lock = NSLock()
        private var trackedIDs: Set<String> = []

        /// Creates a new monitor without any extension points.
        public init() {}

        /// Creates a new monitor and configures it with the specified extension point.
        public convenience init(appExtensionPoint: AppExtensionPoint) async throws {
            self.init()
            try await addAppExtensionPoint(appExtensionPoint)
        }

        /// Begins tracking app extensions that support the specified extension point.
        ///
        /// Linux records the point and leaves `identities` empty.
        public func addAppExtensionPoint(_ appExtensionPoint: AppExtensionPoint) async throws {
            record(appExtensionPoint.id)
        }

        /// Removes the specified extension point and stops tracking.
        public func removeAppExtensionPoint(_ appExtensionPoint: AppExtensionPoint) async throws {
            forget(appExtensionPoint.id)
        }

        private func record(_ id: String) {
            lock.lock()
            trackedIDs.insert(id)
            lock.unlock()
        }

        private func forget(_ id: String) {
            lock.lock()
            trackedIDs.remove(id)
            lock.unlock()
        }

        /// The app extensions currently available to use. Always empty on Linux.
        public var identities: [AppExtensionIdentity] {
            []
        }

        /// The current details about available, disabled, and unapproved extensions.
        public var state: State {
            State(identities: identities, unapprovedCount: 0, disabledCount: 0)
        }

        @_spi(OpenUIKitHost)
        public var host_trackedCount: Int {
            lock.lock()
            defer { lock.unlock() }
            return trackedIDs.count
        }
    }
}
