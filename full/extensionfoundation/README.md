# ExtensionFoundation (Linux starting point)

This directory is a fail-closed portable `ExtensionFoundation` module for the
OpenUIKit Linux platform, seeded from the Xcode 26.1 iPhoneOS public surface
(81 exact IDs). Isolated host compilation produces
`libExtensionFoundation.dylib` with Foundation only.

Linux has no `appex` runtime, extension catalog, NSXPC listener, or host
entitlement. `AppExtension.main()` and `AppExtensionProcess` construction
never report a launched extension.

## What is real

- `AppExtensionPoint.Name`, `Identifier`, `UserInterface`, `EnhancedSecurity`,
  and `Scope` / `Restriction` store their documented fields. `UserInterface()`
  and `EnhancedSecurity()` default to `true`. `Scope()` defaults to
  `.application`.
- `AppExtensionPoint.Definition.buildBlock` is a parameter-pack result builder.
  It produces a process-local point whose `id` is the name string and records
  UI / enhanced-security / scope attributes. Definitions are registered for
  later `init(identifier:)` lookup.
- `AppExtensionPoint.Bind.buildBlock` produces a point from an identifier.
  System names become `id` as-is. `Identifier(host:name:)` composes
  `"<host>/<name>"`.
- `init(identifier:)` looks up process-local definitions. Empty strings throw
  `unspecifiedAppExtensionPointName`. Unknown names throw
  `invalidAppExtensionPoint`.
- `AppExtensionPoint.Error` cases are constructible. `localizedDescription`
  is the Foundation overlay.
- `AppExtensionIdentity` is `Hashable` / `Identifiable`. Darwin does not
  expose a public initializer; tests construct it through
  `@_spi(OpenUIKitHost)`.
- `ConnectionHandler` stores `onConnection` and `onSessionRequest` closures.
  `accept(connection:)` calls the Foundation-XPC closure, or returns `false`
  for a session-only handler.
- `AppExtensionPoint.Monitor.init()` reports empty `identities` and a `State`
  of zero disabled / unapproved counts. Equality and hashing of those value
  types are process-local.

## Fail-closed boundaries

- `AppExtension.main()` always throws
  `ExtensionFoundationHostError.extensionProcessUnavailable`
  (`ExtensionFoundation.Linux` / code 1).
- `AppExtensionProcess.init(configuration:)` always throws
  `processUnavailable` (code 2). It never finds or creates an appex process.
- `makeXPCConnection()` / `makeXPCSession()` always throw `xpcUnavailable`
  (code 3), including on host-SPI unlaunched handles.
- `invalidate()` sets a local flag only. It is not Apple process teardown.
- Monitor `identities` stays empty. Linux never discovers, approves, or
  disables real extensions.
- Isolated-host `NSXPCConnection`, `XPCSession`, and `XPCListener` are
  lookalikes so signatures type-check. They are not Darwin XPC types.

## Depth pass 2026-09

This is a fresh seed: 81 exact public identifiers, floor 65 nondeferred.

Coverage after this pass: **77 implemented / 4 declared / 0 deferred /
0 unavailable / 0 not-applicable**.

Top-5 `implemented` evidence distribution:

1. `AppExtensionPointErrorTests.swift#testAppExtensionPointErrorCases` — 6 rows (enum table)
2. `AppExtensionPointAttributeTests.swift#testScopeRestrictionEnumCases` — 4 rows (enum table)
3. `AppExtensionProtocolTests.swift#testAppExtensionInitAndConfiguration` — 3 rows (4.5% of remaining)
4. `AppExtensionPointValueTests.swift#testAppExtensionPointEqualityAndInequality` — 3 rows
5. `AppExtensionPointMonitorTests.swift#testMonitorInitHasEmptyIdentities` — 3 rows

`testAppExtensionPointErrorCases` and `testScopeRestrictionEnumCases` are
table-driven enum-member tests. No other single test is cited by more than
40% of the remaining implemented rows.

The four `declared` rows are async `Monitor` add/remove/init and async
`AppExtensionProcess.init` — the sealed runner cannot `await`.

## Tests

`tests/agent/ExtensionFoundationLoadSmoke.swift` is the schema-v2 load
marker. `tests/agent/*Tests.swift` holds the sealed focused tests.
`tests/agent/ExtensionFoundationDependencyIdentity.swift` is prepared for
a future clean EC2 run that builds guest Foundation first.

Run `bash full/extensionfoundation/tests/acceptance/test_host.sh` from the
repository root. Keep generated products out of the tree.

The sealed host gate ended:

```
CURSOR_SWIFT_ENVIRONMENT_OK swift=6.2.4 target=linux products=clean
FRAMEWORK_FANOUT_DELIVERABLE_OK module=ExtensionFoundation lane=leaf-full symbols=81
FRAMEWORK_FANOUT_REFERENCE_OK
EXTENSIONFOUNDATION_AGENT_RUNTIME_OK
FRAMEWORK_FANOUT_HOST_OK module=ExtensionFoundation dylib=libExtensionFoundation.dylib
```

The campaign inventory stamp `CURSOR_SWIFT_ENVIRONMENT_OK swift=6.2.4 target=linux products=clean` is a host-inventory token. `.cursor/verify-cloud-environment.sh` on this snapshot fails earlier (`missing corpus checkout: scratch/ladder-corpus/focus-ios`; Cursor Build `bld-20260906-253cd433-7a30-4d11-aad2-8b209b7b2d21` vs seed `bld-20260901-d3266600-d87b-438f-94c1-d1aa48036e87`). `swiftc` is Swift 6.2.4 / linux and the sealed gate compiled with a clean product tree.

## Still open

See `oracle-questions.tsv` for Darwin `main()` blocking, identifier lookup
errors, Definition host-bundle requirements, Bind `id` bytes, process/XPC
NSError codes, Monitor publication queues, and XPC `Decision` factories.
