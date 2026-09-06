@_exported import Foundation

/// Linux starting point for Apple's public `ThreadNetwork` module.
///
/// `THCredentials` property storage, `channel` mutation, and `NSSecureCoding`
/// round-trips are real. There is no Thread radio, Thread daemon, Border
/// Agent, or `com.apple.developer.networking.manage-thread-network-credentials`
/// entitlement on Linux: every `THClient` store/retrieve/delete path fail-
/// closes, and preferred-network queries report `false`. See `README.md`.
enum ThreadNetworkModuleMarker {
    static let name = "ThreadNetwork"
}

/// Fail-closed errors for Linux `ThreadNetwork`.
///
/// Apple's NSError domain and integer codes are not in the pinned public
/// graph or API-digester dump. This is a local Swift error, not a Darwin
/// overlay. See `oracle-questions.tsv`.
public struct ThreadNetworkError: Error, Equatable, Hashable, Sendable, LocalizedError {
    public enum Code: Equatable, Hashable, Sendable {
        /// No Thread daemon, radio, Border Agent, or manage-credentials
        /// entitlement is available.
        case unavailable
    }

    public var code: Code

    public static let unavailable = ThreadNetworkError(code: .unavailable)

    public var errorDescription: String? {
        switch code {
        case .unavailable:
            return "Thread Network credentials are unavailable on this platform."
        }
    }
}

func threadNetworkUnavailable() -> ThreadNetworkError {
    .unavailable
}

func threadNetworkThrowUnavailable() throws -> Never {
    throw ThreadNetworkError.unavailable
}

/// Linux host-test control. Hidden from ordinary `import ThreadNetwork`
/// clients and not part of Apple's public ThreadNetwork surface.
@_spi(OpenUIKitHost)
public enum ThreadNetworkHostControl {
    public static var linuxUnavailableError: ThreadNetworkError { .unavailable }

    /// Synchronous twin of `THClient.allCredentials()`. The async method
    /// never suspends; it always throws this error.
    public static func allCredentialsSync(_ client: THClient) throws -> Set<THCredentials> {
        try client.linuxAllCredentials()
    }

    public static func allActiveCredentialsSync(
        _ client: THClient
    ) throws -> Set<THCredentials> {
        try client.linuxAllActiveCredentials()
    }

    public static func preferredCredentialsSync(_ client: THClient) throws -> THCredentials {
        try client.linuxPreferredCredentials()
    }

    public static func credentialsSync(
        forBorderAgentID borderAgentID: Data,
        client: THClient
    ) throws -> THCredentials {
        try client.linuxCredentials(forBorderAgentID: borderAgentID)
    }

    public static func credentialsSync(
        forExtendedPANID extendedPANID: Data,
        client: THClient
    ) throws -> THCredentials {
        try client.linuxCredentials(forExtendedPANID: extendedPANID)
    }

    public static func storeCredentialsSync(
        forBorderAgent borderAgentID: Data,
        activeOperationalDataSet: Data,
        client: THClient
    ) throws {
        try client.linuxStoreCredentials(
            forBorderAgent: borderAgentID,
            activeOperationalDataSet: activeOperationalDataSet
        )
    }

    public static func deleteCredentialsSync(
        forBorderAgent borderAgentID: Data,
        client: THClient
    ) throws {
        try client.linuxDeleteCredentials(forBorderAgent: borderAgentID)
    }

    public static func isPreferredAvailableSync(_ client: THClient) -> Bool {
        client.linuxIsPreferredAvailable()
    }
}
