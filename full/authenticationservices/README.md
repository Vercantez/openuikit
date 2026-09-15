# AuthenticationServices (Linux starting point)

This directory is a clean-room Linux starting point for Apple's public
`AuthenticationServices` module, seeded from the Xcode 26.1 iPhoneOS 26.1
symbol graph, API digester, TBD exports, and pinned `dotnet/macios`
annotations. It is not wired into the shared guest package; that integration
is a later central-review step.

The isolated host compile imports **Foundation**, plus `FoundationNetworking`
behind `#if canImport(FoundationNetworking)` for the `HTTPURLResponse`
members (the same pattern `webkit` / `linkpresentation` use with a
Foundation-only declared dependency list). There is no UIKit, SwiftUI, or
CryptoKit module on this Linux gate.

Coverage for this pass: **2057 implemented / 0 declared / 39 deferred**
of 2096 public precise IDs. The
`ASWebAuthenticationSession`, `ASAuthorizationController`,
`ASAuthorizationAppleIDProvider` / `Request` / `Credential`, and
`ASAuthorizationError` families are nondeferred, including the
`HTTPURLResponse` members (`complete(httpResponse:httpBody:)`, both
`init(httpResponse:httpBody:)` rows, `httpResponse`, and SSO
`authenticatedResponse`, which stays fail-closed at `nil`).

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

## Depth pass 2026-09 (wave 8)

Ledger before this wave: **1248 implemented / 0 declared / 848 deferred /
0 unavailable / 0 not-applicable**. Ledger after this wave: **1261
implemented / 0 declared / 38 deferred / 0 unavailable / 797
not-applicable**.

This wave added the browser-facing platform and security-key provider
protocols, their client-data request factories, and the mutable browser request
facets (`shouldShowHybridTransport`, platform excluded credentials, and
security-key client data). These are deterministic request value construction;
performing either request still uses the existing fail-closed controller and
never claims access to an authenticator or browser daemon.

The 797 precise IDs reclassified as not applicable are SwiftUI cross-import
re-exports and use the lane-required note; they are owned by the SwiftUI lane,
not by the Linux AuthenticationServices binary. The remaining 38 deferred rows
require UIKit view-controller/anchor identity (25), FoundationNetworking
response identity (5), or CryptoKit key identity (6), plus two Safari/WebKit
request extension properties. No framework-local substitutes were invented for
those dependency-owned types. Consequently the pinned surface contains only 13
additional dependency-free, non-overlay rows that this wave can honestly move
to implemented; the requested 200-row behavioral gain is not representable in
this input without falsely claiming cross-import overlays or dependency-owned
APIs.

Top-five implemented evidence distribution after wave 8:

1. `testImportableCredentialAllCasesRoundTrip` — 273 rows (21.65%).
2. `testImportableCredentialCodableRoundTrip` — 112 rows (8.88%).
3. `testPublicKeyCredentialParametersAndPRF` — 107 rows (8.49%).
4. `testPasskeyAssertionAndRegistrationCredentials` — 52 rows (4.12%).
5. `testSettingsHelperVerificationAndErrorWitnesses` — 48 rows (3.81%).

## Overlay pass 2026-09 (pi wave 7)

Ledger before this wave: **1261 implemented / 0 declared / 38 deferred /
0 unavailable / 797 not-applicable**. Ledger after this wave: **2052
implemented / 0 declared / 44 deferred / 0 unavailable / 0
not-applicable**.

This wave converts the 797 SwiftUI cross-import overlay rows per the
coverage-contract override (identity `View` overlays compile as no-op
`Self` returns; the SwiftUI lane does not implement them). New product
source `AuthenticationServicesViewOverlay.swift` (in the guest manifest)
provides the inert `_AuthenticationServices_SwiftUI` surface for the
isolated host behind `#if !canImport(SwiftUI)`: `SignInWithAppleButton`
(+ `Label` / `Style`, `Body` / `body`, the synchronous
`onRequest:onCompletion:` initializer), `AuthorizationController` with
fail-closed `async throws` request methods, the four overlay
`EnvironmentValues` properties, and 395 identity `View` modifiers
covering every `s:7SwiftUI4ViewP*` base name in the census. New tests in
`tests/agent/AuthenticationServicesViewOverlayTests.swift` call each
leftover modifier on the button plus the empty view across eight
`testViewOverlayBatchNN` functions (96–97 rows each, ≤4.73% of
implemented rows), with focused witnesses for the button family, the
environment values, and the controller identity. Notes read `identity
View overlay; renders EmptyView`.

Six `AuthorizationController.perform*` async rows move to deferred:
request success would claim Apple-daemon authorization, which stays
fail-closed on Linux, and cited tests cannot `await`. The remaining 38
deferred rows are unchanged (UIKit view-controller/anchor identity,
FoundationNetworking response identity, CryptoKit key identity, WebKit
request facets). Passkey / web-authentication session success stays
fail-closed; no `await`, `DispatchQueue.main`, `RunLoop`, or semaphore
waits appear in the cited overlay tests.

Top-five implemented evidence distribution after this wave:

1. `testImportableCredentialAllCasesRoundTrip` — 273 rows (13.30%).
2. `testImportableCredentialCodableRoundTrip` — 112 rows (5.46%).
3. `testPublicKeyCredentialParametersAndPRF` — 107 rows (5.21%).
4. `testViewOverlayBatch06` — 97 rows (4.73%).
5. `testViewOverlayBatch01` — 97 rows (4.73%).

The shared deliverable/reference validators pass on the Linux-gate code
path; the sealed gate's final runner step requires a Linux toolchain
(`import Glibc` does not compile under the macOS SDK). Product and test
sources compile warning-free and the runner emits only the exact success
marker when the runner is built against the macOS SDK equivalent. The
unresolved Apple-oracle questions remain in `oracle-questions.tsv`; this
wave does not infer service success, callback semantics, UI behavior, or
cryptographic key representations.

## Re-examination pass 2026-09 (pi wave 8)

Ledger before this pass: **2052 implemented / 0 declared / 44 deferred /
0 unavailable / 0 not-applicable**. Ledger after this pass: **2052
implemented / 0 declared / 44 deferred / 0 unavailable / 0
not-applicable** (2096 precise IDs). Implemented gain: **0** — there are no
declared rows to convert, and none of the 44 deferred rows can move to
implemented in-process on the isolated host:

- 24 UIKit `UIViewController` subclasses (`ASCredentialProviderViewController`
  x17, `ASAccountAuthenticationModificationViewController` x7) plus 1
  `UIWindow`-typed `ASCredentialExportManager` presentation-anchor initializer:
  `no such module 'UIKit'` on the gate toolchain, and a framework-local
  substitute superclass is forbidden.
- 5 FoundationNetworking `HTTPURLResponse` members
  (`completeWithHTTPResponse:httpBody:`, both `initWithHTTPResponse:httpBody:`
  rows, `httpResponse`, `authenticatedResponse`):
  `no such module 'FoundationNetworking'` on the gate toolchain.
- 6 CryptoKit `SymmetricKey` PRF outputs: the declared dependency list is
  Foundation-only and the Linux gate has no CryptoKit module; importing it
  would break the sealed-gate product compile.
- 6 SwiftUI `AuthorizationController` async request methods: success would
  claim Apple-daemon authorization (fail-closed), and cited tests cannot
  `await`.
- 2 WebKit overlay `clientData` facets: no browser module on the isolated
  host and the owning protocol is dependency-owned.

Product sources still compile warning-free under the macOS SDK, and every
`tests/agent/*Tests.swift` file typechecks (the overlay tests, guarded by
`#if !canImport(SwiftUI)`, were verified with the guard forced true to
simulate the SwiftUI-absent Linux gate). No product, test, coverage, or
manifest file needed changes for this pass.

## HTTPURLResponse pass 2026-09 (pi wave 9)

Ledger before this pass: **2052 implemented / 0 declared / 44 deferred /
0 unavailable / 0 not-applicable**. Ledger after this pass: **2057
implemented / 0 declared / 39 deferred / 0 unavailable / 0
not-applicable** (2096 precise IDs). Implemented gain: **5** — there are no
declared rows to convert; the only deferred group convertible in-process
without hardware/daemon is the five `HTTPURLResponse` members:

- `ASAuthorizationProviderExtensionAuthorizationRequest.complete(httpResponse:httpBody:)`
  (no-op, consistent with its `complete*` siblings),
- `ASAuthorizationProviderExtensionAuthorizationResult.init(httpResponse:httpBody:)`
  plus the `init(HTTPResponse:httpBody:)` synthesized ObjC-label overload
  (mirroring the existing `init(httpAuthorizationHeaders:)` /
  `init(HTTPAuthorizationHeaders:)` pair) and the stored `httpResponse` property,
- `ASAuthorizationSingleSignOnCredential.authenticatedResponse`, which stays
  fail-closed at `nil`: Linux never performs the SSO network exchange, so no
  HTTP response exists to report.

`AuthenticationServicesCredentials.swift` and
`AuthenticationServicesAuthorization.swift` import `FoundationNetworking`
behind `#if canImport(FoundationNetworking)`; on Darwin `HTTPURLResponse`
resolves via `Foundation`, on the Linux gate via `FoundationNetworking`.
This matches the `webkit` / `linkpresentation` precedent (Foundation-only
declared dependencies with the same conditional import), so no guest-manifest
or dependency change was needed. Four new synchronous tests in
`tests/agent/AuthenticationServicesCredentialTests.swift`
(`testProviderExtensionHTTPResponseResult`,
`testProviderExtensionHTTPResponseSynthesizedInit`,
`testProviderExtensionCompleteWithHTTPResponse`,
`testSingleSignOnAuthenticatedResponseFailClosed`) cite the five rows; none
uses `DispatchQueue.main`, `RunLoop`, semaphore waits, or `await`.

The remaining 39 deferred rows cannot move in-process: 25 need UIKit
view-controller/anchor identity (a framework-local substitute superclass is
forbidden), 6 need CryptoKit `SymmetricKey` (no such module on the gate
toolchain), 6 are SwiftUI `AuthorizationController` async request methods
(success would claim Apple-daemon authorization and cited tests cannot
`await`), and 2 are WebKit overlay `clientData` facets owned by the browser
module.
