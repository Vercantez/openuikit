# AdServices (Linux starting point)

This directory is a fail-closed portable `AdServices` module for the OpenUIKit
Linux platform. It extends the in-tree attribution starting point (observed
error domain and codes, `attributionToken()` never fabricates a token) to the
sealed Xcode 26.1 iPhoneOS public seed. It is not wired into the shared guest
package; that integration is a separate review step.

Isolated host compilation produces `libAdServices.dylib` with Foundation only.

## What is real

- `AAAttributionErrorDomain` is `com.apple.ap.adservices.attributionError`,
  matching the 2026-09-01 Apple interface oracle in
  `tests/adservices-interface-apple-2026-09-01.txt`.
- `AAAttributionError.Code` raw values are `networkError = 1`,
  `internalError = 2`, `platformNotSupported = 3` (pinned `dotnet/macios`
  `[Native]` cases and the same Apple oracle). Unknown raw values return `nil`.
- `AAAttributionError` is a `@frozen` `Foundation._BridgedStoredNSError`
  wrapper. Static `networkError` / `internalError` / `platformNotSupported`
  shortcuts and `errorDomain` match the Clang-importer overlay.
- `AAAttribution.attributionToken()` throws
  `AAAttributionError.platformNotSupported` with a host localized description.
  Linux never returns a token.

The existing guest probes (`tests/AdServicesGuestRuntime.swift`,
`tests/AdServicesInterfaceOracle.swift`) remain source-compatible.

## Fail-closed boundaries

Linux has no Apple Ads attribution daemon, App Store receipt, SKAdNetwork
identity, or `kAAAttributionXPCMachServiceName` service.

- `attributionToken()` never succeeds.
- Darwin token format, retry/network mapping, and simulator-versus-device
  error selection are unobserved.
- `AAAttributionResult` is exported by the TBD but is not in the public Swift
  symbol graph, so it is not declared here.
- `localizedDescription` is Foundation's NSError wording, not an Apple copy
  string.

## Tests

`tests/agent/AdServicesLoadSmoke.swift` is the schema-v2 load marker.
`tests/agent/AdServicesTests.swift` holds the sealed focused tests.
`tests/agent/AdServicesRuntime.swift` is a standalone probe
(`ADSERVICES_AGENT_RUNTIME_OK`).
`tests/agent/AdServicesDependencyIdentity.swift` is prepared for a future
clean EC2 run that builds guest Foundation first.

Run `bash tests/acceptance/test_host.sh` from this directory. Keep generated
products out of the tree.
