# AuthenticationServices (Linux starting point)

This directory is a clean-room Linux starting point for Apple's public
`AuthenticationServices` module, seeded from the Xcode 26.1 iPhoneOS 26.1
symbol graph, API digester, TBD exports, and pinned `dotnet/macios`
annotations. It is not wired into the shared guest package; that integration
is a later central-review step.

The isolated host compile imports **Foundation only**. There is no UIKit,
SwiftUI, CryptoKit, or FoundationNetworking module on this Linux gate.

## What is real

- `ASWebAuthenticationSessionErrorDomain` is
  `com.apple.AuthenticationServices.WebAuthenticationSession`, matching the
  pinned macios `[ErrorDomain]` annotation and the existing IceCubes host
  oracle. Codes are `canceledLogin = 1`, `presentationContextNotProvided = 2`,
  `presentationContextInvalid = 3`.
- `ASAuthorizationError` codes `unknown = 1000` through
  `deviceNotConfiguredForPasskeyCreation = 1010`, `ASExtensionError` codes
  `failed = 0`, `userCanceled = 1`, `userInteractionRequired = 100`,
  `credentialIdentityNotFound = 101`, `matchedExcludedCredential = 102`, and
  `ASCredentialIdentityStoreError` codes `internalError = 0`,
  `storeDisabled = 1`, `storeBusy = 2` follow the pinned macios bindings.
  Domain strings are the C identifier names until an Apple oracle records the
  NSError domain bytes.
- `ASCOSEAlgorithmIdentifier.ES256 = -7` and
  `ASCOSEEllipticCurveIdentifier.P256 = 1` match the COSE / macios values.
- `ASAuthorizationAppleIDButton.Style` is `white = 0`, `whiteOutline = 1`,
  `black = 2`. `ButtonType` is `signIn = 0`, `continue = 1`, `signUp = 2`.
- `ASAuthorizationAppleIDProvider.CredentialState` is `revoked = 0`,
  `authorized = 1`, `notFound = 2`, `transferred = 3`.
- Portable web authentication is host-driven. A host must install
  `AuthenticationServicesPortable._installEventHandler` before the first
  request. Success is only reported when that host returns a matching callback
  URL. Missing host, invalid HTTP(S) URLs, mismatched schemes, concurrent
  requests, and cancellation fail closed with typed errors.
- `ASWebAuthenticationSession.start()` schedules work and returns immediately.
  Completions are delivered exactly once on
  `org.openuikit.AuthenticationServices.host-callback`. That queue label is a
  Linux host control, not Apple's daemon queue.
- `ASCredentialIdentityStore` reports `isEnabled = false` and every save /
  remove / replace throws or callbacks `storeDisabled`.
- `ASAuthorizationController.performRequests` callbacks
  `ASAuthorizationError.notInteractive` after return on the same host-callback
  queue. Linux never invents an Apple ID or passkey assertion.
- Credential import/export managers throw `credentialImport` /
  `credentialExport`. Codable round-trips prove the Linux overlay keys, not
  Apple's on-the-wire format.
- String newtypes (`ASAuthorization.OpenIDOperation`, attestation kind,
  resident-key / user-verification preferences, scopes) use the C identifier
  name as the `rawValue` placeholder until an Apple oracle records the NSString
  payload.

`CGFloat` values on `ASAuthorizationAppleIDButton` are Foundation's Linux
geometry type.

## Fail-closed boundaries

Linux has no Apple ID daemon, passkey authenticator, credential-provider
extension host, Safari web-auth session, or Sign in with Apple UI.

- `ASWebAuthenticationSession` without a configured host completes with
  `presentationContextNotProvided`. HTTPS-only `Callback.https` has no host
  scheme mapping and completes with `presentationContextInvalid`.
- `WebAuthenticationSession.authenticate` uses the same portable boundary.
- Identity-store mutations never persist. `credentialIdentities` returns `[]`.
- `ASSettingsHelper` reports `notInteractive` / `false` and does not open
  Settings.
- Account-modification and credential-provider extension contexts do not
  present UI; presentation helpers callback failure.
- `ASAuthorizationWebBrowserPublicKeyCredentialManager` reports
  `isDeviceConfiguredForPasskeys = false` and `AuthorizationState.denied`.
- `ASAuthorizationAppleIDProvider.credentialState(forUserID:)` returns
  `.notFound`.

## Deferred

- The entire SwiftUI `SignInWithAppleButton` / `AuthorizationController` /
  `EnvironmentValues` overlay (`_AuthenticationServices_SwiftUI`). The overlay
  source `AuthenticationServicesSwiftUI.swift` is not in the Linux guest
  manifest.
- UIKit `ASPresentationAnchor`, view controllers, and presentation-context
  provider protocols.
- CryptoKit `SymmetricKey` members on PRF assertion/registration outputs.
- FoundationNetworking `HTTPURLResponse` members (`authenticatedResponse`,
  `httpResponse`, `complete(httpResponse:httpBody:)`).
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
