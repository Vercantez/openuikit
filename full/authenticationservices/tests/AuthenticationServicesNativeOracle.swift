import AuthenticationServices
import Foundation
import SwiftUI

@MainActor
private func compileWebAuthenticationSurface(
    _ session: WebAuthenticationSession,
    url: URL
) async {
    _ = try? await session.authenticate(
        using: url,
        callbackURLScheme: "icecubesapp"
    )
    let _: WebAuthenticationSession.BrowserSession = .shared
    let _: WebAuthenticationSession.BrowserSession = .ephemeral
}

private struct NativeEnvironmentConsumer: View {
    @Environment(\.webAuthenticationSession)
    private var webAuthenticationSession

    var body: some View { EmptyView() }
}

@main
private struct AuthenticationServicesNativeOracle {
    static func main() {
        precondition(
            ASWebAuthenticationSessionError.Code.canceledLogin.rawValue == 1
        )
        precondition(
            ASWebAuthenticationSessionError.Code
                .presentationContextNotProvided.rawValue == 2
        )
        precondition(
            ASWebAuthenticationSessionError.Code
                .presentationContextInvalid.rawValue == 3
        )
        precondition(!ASWebAuthenticationSessionErrorDomain.isEmpty)
        print(
            "AUTHENTICATIONSERVICES_APPLE_OK "
                + "environment=web-session async=scheme-callback "
                + "browser=shared,ephemeral errors=1,2,3"
        )
    }
}
