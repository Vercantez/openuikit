import AuthenticationServices
import Foundation
import SwiftUI

@MainActor
private struct IceCubesAddAccountAuthenticationProbe: View {
    @Environment(\.webAuthenticationSession)
    private var webAuthenticationSession

    var body: some View { EmptyView() }

    private func signIn(oauthURL: URL) async -> URL? {
        try? await webAuthenticationSession.authenticate(
            using: oauthURL,
            callbackURLScheme: "icecubesapp"
        )
    }
}
