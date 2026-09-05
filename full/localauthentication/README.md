# LocalAuthentication (Linux starting point)

This directory is a clean-room Linux starting point for Apple's public
`LocalAuthentication` module, seeded from the Xcode 26.1 iPhoneOS 26.1
symbol graph, API digester, TBD exports, and the pinned `dotnet/macios`
bindings. It is not wired into the shared guest package; that integration
is a later central-review step.

Linux has no Secure Enclave, biometric sensor, companion device, or
authentication daemon. Evaluation never invents hardware success.

## What was measured (2026-09-05)

Mac probe `/tmp/la-oracle.swift` against SDK LocalAuthentication
(Xcode 26.1 / macOS 26.0):

| symbol | value |
|---|---|
| `LAErrorDomain` | `com.apple.LocalAuthentication` |
| `kLAErrorDomain` | `com.apple.LocalAuthentication` |
| `LATouchIDAuthenticationMaximumAllowableReuseDuration` | `300.0` |
| default `touchIDAuthenticationAllowableReuseDuration` | `0.0` |
| assigning `10000` to the reuse property | reads back `10000.0` (not clamped on set) |
| `LABiometryType` raw values | none 0, touchID 1, faceID 2, opticID 4 |
| `LARight.State` raw values | unknown 0, authorizing 1, authorized 2, notAuthorized 3 |

`LAPublicDefines.h` (same SDK, not vendored) corroborates the domain string
(`#define kLAErrorDomain "com.apple.LocalAuthentication"`), error codes
(`-1` … `-11`, `-1004`), policy numbers `1…5`, and the 5-minute reuse
bound documented on `LAContext.h`.

`docker exec uikit-linux`: Linux Swift 6.2.4 Foundation has no
`NSErrorPointer` typealias. The overlay keeps
`UnsafeMutablePointer<LAError?>?` so in-tree guests (`var authError: LAError?`)
compile.

## What is real

- `LAError` is a `@frozen` `Foundation._BridgedStoredNSError` wrapper.
  `LAError.Code` matches the API-digester overlay: `touchID*` cases are the
  enum elements; `biometry*` names are static aliases with the same raw
  values.
- `LAPolicy`, `LABiometryType`, `LACompanionType`, `LACredentialType`,
  `LAAccessControlOperation`, `LARight.State`, and matching `kLA*` `Int32`
  macros.
- `LAContext` is a mutable request object.
  - `biometryType` is always `.none`.
  - `canEvaluatePolicy` is synchronous: biometric policies →
    `biometryNotAvailable`; `deviceOwnerAuthentication` → `passcodeNotSet`
    unless `LocalAuthenticationTestHook.setSimulatedDevicePasscodeEnabled(true)`;
    companion policies → `companionNotAvailable`.
  - `evaluatePolicy` (completion and async) delivers the same errors on the
    private serial queue `LocalAuthentication.reply` (Apple: LAContext.h,
    non-inline). Empty `localizedReason` traps (Apple: NSInvalidArgumentException).
  - `invalidate()` cancels in-flight evaluations with `appCancel`; later
    calls fail with `invalidContext` (LAContext.h).
  - `interactionNotAllowed` → `notInteractive` (LAContext.h).
  - `evaluatedPolicyDomainState` stays nil (no successful biometric evaluation).
  - Application-password credentials are stored on the context instance.
    Smart-card PIN never sets.
- `LARight` follows the documented state order in LARight.h:
  `unknown → authorizing → authorized | notAuthorized`. Default / passcode
  fallback rights honor the simulated-passcode hook; biometry-only rights
  stay `biometryNotAvailable`.
- `LARightStore.shared` is an in-memory store on Linux (save / load / remove
  round-trip in-process). `LAPublicKey.exportBytes` and unauthorized
  `LASecret.loadData` fail closed with `invalidContext` (no Secure Enclave).
- `LAEnvironment.currentUser` reports a non-usable biometry mechanism and
  an unset user password. Observer callbacks never fire.

`canImport(Combine)` still `@_exported import Combine` when that module is
present (guest package). Isolated host compilation imports Foundation only.

## Fail-closed boundaries

- No biometric or companion evaluation succeeds.
- `LocalAuthenticationTestHook` is a documented Linux test hook, not an
  Apple API. It only simulates a device passcode.
- Completions hop onto `LocalAuthentication.reply` with `async`, never
  `sync`. Nested calls enqueue behind the running handler.

## Deferred (13 identifiers)

- `LAContext.evaluateAccessControl` and every `SecKeyAlgorithm` member on
  `LAPrivateKey` / `LAPublicKey`: Security is not a declared dependency, and
  a public lookalike is forbidden.
- `objectWillChange` / `ObjectWillChangePublisher`: Combine is not a declared
  dependency on the isolated host.

`LAAuthenticationView` is not in the iPhoneOS 26.1 `LocalAuthentication`
public surface (247 IDs). It is likely `LocalAuthenticationEmbeddedUI` /
SwiftUI; see `oracle-questions.tsv`.

Coverage: 234 implemented / 13 deferred / 0 declared.
