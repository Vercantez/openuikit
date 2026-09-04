@_exported import AuthenticationServices
@_spi(OpenUIKitHost) import AuthenticationServices
import Foundation
import SwiftUI

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
