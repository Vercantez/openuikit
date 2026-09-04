# LocalAuthentication (Linux starting point)

This directory is a clean-room Linux starting point for Apple's public
`LocalAuthentication` module, seeded from the Xcode 26.1 iPhoneOS 26.1
symbol graph, API digester, TBD exports, and the pinned `dotnet/macios`
bindings. It is not wired into the shared guest package; that integration
is a later central-review step.

The original lane's fail-closed `LAContext` is preserved and extended: Linux
has no Secure Enclave, biometry sensor, or authentication daemon, so
evaluation never succeeds.

## What is real

- `LAError` is a `@frozen` `Foundation._BridgedStoredNSError` wrapper around a
  stored `NSError`. `LAError.Code` matches the API-digester overlay: the
  `touchID*` cases are the enum elements; `biometry*` names are static aliases
  with the same raw values. Raw values come from the pinned macios `LAStatus`
  enum (`authenticationFailed = -1` … `companionNotAvailable = -11`,
  `notInteractive = -1004`).
- `LAErrorDomain` / `kLAErrorDomain` use the C identifier as process-local
  identity. Apple's binary NSError string payload is unconfirmed.
- `LAPolicy`, `LABiometryType` (including `opticID = 4` and `LABiometryNone`),
  `LACompanionType` (`mac = 2`, `vision = 4`), `LACredentialType`
  (`smartCardPIN = -3`), `LAAccessControlOperation`, and `LARight.State` use
  the macios explicit raw values. Matching `kLA*` `Int32` macros are declared.
- `LAContext` remains a mutable request object. `canEvaluatePolicy` and both
  the completion-handler and `async` `evaluatePolicy` overlays fail closed
  with `biometryNotAvailable`, or `invalidContext` after `invalidate()`.
  Linux Foundation has no `NSErrorPointer`; the existing
  `UnsafeMutablePointer<LAError?>?` out-pointer is kept so in-tree guests
  (`var authError: LAError?`) keep compiling.
- Application-password credentials are stored on the context instance only.
  Smart-card PIN never sets. Domain state, environment mechanisms, and
  `LARight` / `LARightStore` APIs exist as fail-closed in-memory objects.

`canImport(Combine)` still `@_exported import Combine` when that module is
present (guest package). Isolated host compilation imports Foundation only.

## Fail-closed boundaries

- Policy evaluation never returns success and never presents UI.
- `LARight.authorize` / `checkCanAuthorize` and `LARightStore` save/load/remove
  paths fail with `biometryNotAvailable`. They do not persist secrets.
- `LAEnvironment.currentUser` reports a non-usable biometry mechanism
  (`biometryType == .none`, not enrolled) and an unset user password. No
  companion devices. Observer callbacks never fire: environment state does
  not change on Linux.
- `LAPublicKey.exportBytes` and `LASecret.loadData` complete with
  `biometryNotAvailable`. Completions run synchronously; that timing is a
  Linux host choice, not an Apple observation.

## Deferred

- `LAContext.evaluateAccessControl` and every `SecKeyAlgorithm` member on
  `LAPrivateKey` / `LAPublicKey`: Security is not a declared dependency, and
  a public lookalike is forbidden.
- `objectWillChange` / `ObjectWillChangePublisher`: Combine is not a declared
  dependency on the isolated host.
- `LATouchIDAuthenticationMaximumAllowableReuseDuration`: the graph records
  the symbol, not the numeric payload.

See `oracle-questions.tsv` for questions that need a central Apple-oracle probe.
