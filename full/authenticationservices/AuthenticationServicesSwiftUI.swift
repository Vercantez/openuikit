@_exported import AuthenticationServices
@_spi(OpenUIKitHost) import AuthenticationServices
import Foundation
import SwiftUI

@available(iOS 16.4, macOS 13.3, watchOS 9.4, tvOS 16.4, *)
@MainActor
public struct WebAuthenticationSession: Sendable {
    public struct BrowserSession: Sendable {
        fileprivate enum Storage: UInt8, Sendable {
            case shared
            case ephemeral
        }

        fileprivate let storage: Storage

        public static var ephemeral: BrowserSession {
            BrowserSession(storage: .ephemeral)
        }

        public static var shared: BrowserSession {
            BrowserSession(storage: .shared)
        }
    }

    nonisolated fileprivate init() {}

    public func authenticate(
        using url: URL,
        callbackURLScheme: String,
        preferredBrowserSession: BrowserSession? = nil
    ) async throws -> URL {
        try await AuthenticationServicesPortable._authenticate(
            using: url,
            callbackURLScheme: callbackURLScheme,
            prefersEphemeralBrowserSession:
                preferredBrowserSession?.storage == .ephemeral
        )
    }
}

@available(iOS 16.4, macOS 13.3, watchOS 9.4, tvOS 16.4, *)
private enum _PortableWebAuthenticationSessionKey: EnvironmentKey {
    static let defaultValue = WebAuthenticationSession()
}

public extension EnvironmentValues {
    @available(iOS 16.4, macOS 13.3, watchOS 9.4, tvOS 16.4, *)
    var webAuthenticationSession: WebAuthenticationSession {
        self[_PortableWebAuthenticationSessionKey.self]
    }
}
