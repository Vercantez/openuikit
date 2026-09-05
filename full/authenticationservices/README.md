# AuthenticationServices (Linux starting point)

This directory is a clean-room Linux starting point for Apple's public
`AuthenticationServices` module, seeded from the Xcode 26.1 iPhoneOS 26.1
symbol graph, API digester, TBD exports, and pinned `dotnet/macios`
annotations. It is not wired into the shared guest package; that integration
is a later central-review step.

The isolated host compile imports **Foundation only**. There is no UIKit,
SwiftUI, CryptoKit, or FoundationNetworking module on this Linux gate.

Coverage for this pass: **1248 implemented / 0 declared / 848 deferred**
of 2096 public precise IDs. The
`ASWebAuthenticationSession`, `ASAuthorizationController`,
`ASAuthorizationAppleIDProvider` / `Request` / `Credential`, and
`ASAuthorizationError` families are nondeferred (SSO
`authenticatedResponse` stays deferred: it is `HTTPURLResponse`).

## What is real

- `ASWebAuthenticationSessionErrorDomain` is
  `com.apple.AuthenticationServices.WebAuthenticationSession`, matching the
  pinned macios `[ErrorDomain]` annotation and the existing IceCubes host
  oracle. Codes are `canceledLogin = 1`, `presentationContextNotProvided = 2`,
  `presentationContextInvalid = 3` (Apple
  `ASWebAuthenticationSessionError.Code`).
- `ASAuthorizationError` codes `unknown = 1000` through
  `deviceNotConfiguredForPasskeyCreation = 1010`, `ASExtensionError` codes
  `failed = 0`, `userCanceled = 1`, `userInteractionRequired = 100`,
  `credentialIdentityNotFound = 101`, `matchedExcludedCredential = 102`, and
  `ASCredentialIdentityStoreError` codes `internalError = 0`,
  `storeDisabled = 1`, `storeBusy = 2` follow the pinned macios bindings.
  Domain strings for authorization / extension / identity-store errors are
  the C identifier names until an Apple oracle records the NSError domain
  bytes.
- `ASCOSEAlgorithmIdentifier.ES256 = -7` and
  `ASCOSEEllipticCurveIdentifier.P256 = 1` match the COSE / macios values.
- `ASAuthorizationAppleIDButton.Style` is `white = 0`, `whiteOutline = 1`,
  `black = 2`. `ButtonType` is `signIn = 0`, `continue = 1`, `signUp = 2`.
  The type is declared as an `NSObject` value store (type/style/`cornerRadius`).
  Darwin is a `UIControl`; Linux does not draw the button.
- `ASAuthorizationAppleIDProvider.CredentialState` is `revoked = 0`,
  `authorized = 1`, `notFound = 2`, `transferred = 3`.
  `credentialState(forUserID:)` and `getCredentialState(forUserID:completion:)`
  both return `.notFound`.
- `ASPresentationAnchor` is `NSObject` on Linux. Darwin's iPhoneOS graph is
  `typealias ASPresentationAnchor = UIWindow`. Presentation-context protocols
  compile and store a weak provider; they never present a sheet.
- `ASWebAuthenticationSession.start()`:
  1. Returns immediately; the completion runs later on
     `org.openuikit.AuthenticationServices.host-callback`.
  2. With no `presentationContextProvider`, completes with
     `.presentationContextNotProvided` (Apple
     `ASWebAuthenticationSessionError.Code.presentationContextNotProvided`).
  3. With a provider and `@_spi(OpenUIKitHost) _testCallbackURL` set, delivers
     that URL if `Callback.matchesURL` accepts it.
  4. With a provider, no test hook, and no portable host, completes with
     `.canceledLogin`.
  5. `Callback.customScheme` matches `url.scheme` case-insensitively;
     `Callback.https(host:path:)` matches scheme `https`, host
     case-insensitively, and path equal-or-prefix.
- `ASAuthorizationController.performRequests` completes after return on the
  host-callback queue with `.unknown` when `authorizationRequests` is empty
  and `.notHandled` otherwise, unless `@_spi(OpenUIKitHost)
  _testAuthorization` supplies an `ASAuthorization`.
- `ASCredentialIdentityStore` reports `isEnabled = false` and every save /
  remove / replace throws or callbacks `storeDisabled`.
- `ASAccountAuthenticationModificationController.perform` fail-closes through
  the delegate with `ASAuthorizationError.notHandled`.
- Credential import/export managers throw `credentialImport` /
  `credentialExport`. Codable round-trips prove the Linux overlay keys, not
  Apple's on-the-wire format.
- String newtypes (`ASAuthorization.OpenIDOperation`, attestation kind,
  resident-key / user-verification preference, scopes) use the C identifier
  name as the `rawValue` placeholder until an Apple oracle records the NSString
  payload.

`CGFloat` values on `ASAuthorizationAppleIDButton` are Foundation's Linux
geometry type.

## Fail-closed boundaries

Linux has no Apple ID daemon, passkey authenticator, credential-provider
extension host, Safari web-auth session, or Sign in with Apple UI.

- Identity-store mutations never persist. `credentialIdentities` returns `[]`.
- `ASSettingsHelper` reports `notInteractive` / `false` and does not open
  Settings.
- Credential-provider extension `complete*` helpers return `false`.
- `ASAuthorizationWebBrowserPublicKeyCredentialManager` reports
  `isDeviceConfiguredForPasskeys = false` and `AuthorizationState.denied`.
- Platform / security-key public-key requests store challenge, relying-party,
  userID, and name; `performRequests` still fail-closes unless a test hook
  supplies a credential.

## Deferred

- The entire SwiftUI `SignInWithAppleButton` / `AuthorizationController` /
  `EnvironmentValues` overlay (`_AuthenticationServices_SwiftUI`). The overlay
  source `AuthenticationServicesSwiftUI.swift` is not in the Linux guest
  manifest.
- UIKit `UIViewController` subclasses (`ASCredentialProviderViewController`,
  `ASAccountAuthenticationModificationViewController`).
- CryptoKit `SymmetricKey` members on PRF assertion/registration outputs.
- FoundationNetworking `HTTPURLResponse` members (`authenticatedResponse`,
  `httpResponse`, `complete(httpResponse:httpBody:)`).
- WebKit / Safari web-browser public-key provider overlays.
- Apple NSString payloads for typed constants; Linux stores C-identifier
  placeholders.
- Apple's credential-exchange wire format, daemon queues, and entitlement
  prompts.

See `oracle-questions.tsv` for the central Apple-oracle queue.

`tests/agent/AuthenticationServicesLoadSmoke.swift` is the schema-v2 load
marker (`AUTHENTICATIONSERVICES_AGENT_RUNTIME_OK`). Focused checks live in
`tests/agent/*Tests.swift`. `tests/agent/AuthenticationServicesRuntime.swift`
is an extra host-SPI probe and is not compiled by the sealed gate.
`tests/agent/AuthenticationServicesDependencyIdentity.swift` is prepared for a
later clean EC2 run that builds guest Foundation first.

Run `bash tests/acceptance/test_host.sh` from this directory. Keep generated
products out of the tree.
