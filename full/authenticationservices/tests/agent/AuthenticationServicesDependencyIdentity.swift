@_spi(OpenUIKitHost) import AuthenticationServices
import Foundation

// Future clean EC2 dependency-identity client. Isolated host-gate success
// against toolchain Foundation is not integrated guest-Foundation success.
//
// Expected EC2 steps (no local Docker):
// 1. Build the actual guest Foundation module and `libFoundation.dylib`.
// 2. Build AuthenticationServices with that Foundation on `-I` / `-L`.
// 3. Link this file as a client that `import`s AuthenticationServices and Foundation.
// 4. Run with `LD_LIBRARY_PATH` covering both dylibs.
// 5. Confirm `AUTHENTICATIONSERVICES_DEPENDENCY_IDENTITY_OK` and that
//    `libAuthenticationServices.dylib` was loaded.

func authenticationServicesDependencyIdentityProbe() {
    let login = URL(string: "https://social.example/oauth/authorize")!
    precondition(login.scheme == "https")

    let error = ASWebAuthenticationSessionError(
        .presentationContextInvalid,
        reason: "identity-probe"
    )
    let nsError = error._nsError
    precondition(type(of: nsError) == NSError.self)
    precondition(!String(reflecting: type(of: nsError)).hasPrefix("AuthenticationServices."))
    precondition(nsError.domain == ASWebAuthenticationSessionErrorDomain)
    precondition(nsError.userInfo[NSLocalizedDescriptionKey] as? String == "identity-probe")

    let data = Data("identity".utf8)
    let password = ASPasswordCredential(user: "lane", password: "secret")
    precondition(password.user == "lane")
    _ = data

    let notification = ASAuthorizationAppleIDProvider.credentialRevokedNotification
    precondition(notification.rawValue == ASAuthorizationAppleIDProviderCredentialRevokedNotification.rawValue)

    let service = ASCredentialServiceIdentifier(identifier: "example.com", type: .domain)
    precondition(service.identifier == "example.com")

    _ = AuthenticationServicesHostCallback.queue
}

#if AS_IDENTITY_MAIN
authenticationServicesDependencyIdentityProbe()
print("AUTHENTICATIONSERVICES_DEPENDENCY_IDENTITY_OK")
#endif
