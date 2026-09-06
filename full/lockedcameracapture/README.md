# LockedCameraCapture (Linux starting point)

Leaf-full starting implementation of Apple's public `LockedCameraCapture`
surface for Linux. The module is `LockedCameraCapture`; the host gate produces
`libLockedCameraCapture.dylib`.

This directory is a clean-room Linux starting point seeded from the Xcode 26.1
iPhoneOS 26.1 symbol graph, API digester, TBD exports, and pinned
`dotnet/macios` bindings (which have no LockedCameraCapture sources). It is
not wired into the shared guest package; that integration is a later
central-review step.

## Depth pass 2026-09

SDK depth for `LockedCameraCapture` in `full/lockedcameracapture/` (43 exact
IDs). This is a fresh seed: owned types, error discriminators, the session
working directory, the manager URL list, and appearance-delay depth are
implemented with focused tests. Enum cases share one table-driven case test
per enum; every other implemented identifier has its own test.

Coverage this round: **43 implemented / 0 declared / 43 total**
(43 nondeferred, floor 35). No non-enum test is cited by more than 1
implemented row (2.7% of the 37 non-enum-member implemented rows). Enum
cases share table-driven tests (`ApplicationLaunchError` 3 rows,
`SessionContentUpdate` 3 rows).

Top-5 implemented evidence (of 43 rows; 40% cap of remaining non-enum rows = 14):

| Rows | Share | Evidence |
| ---: | ---: | --- |
| 3 | 7.0% | `ApplicationLaunchErrorTests.swift#testApplicationLaunchErrorCases` (table-driven enum cases) |
| 3 | 7.0% | `LockedCameraCaptureManagerTests.swift#testSessionContentUpdateCases` (table-driven enum cases) |
| 1 | 2.3% | `NSUserActivityTypeTests.swift#testNSUserActivityTypeLockedCameraCapture` |
| 1 | 2.3% | `ApplicationLaunchErrorTests.swift#testApplicationLaunchErrorType` |
| 1 | 2.3% | 35 other focused tests, one identifier each |

Environment: `swiftc` reports Swift 6.2.4, target `x86_64-unknown-linux-gnu`.
`.cursor/verify-cloud-environment.sh` did not emit
`CURSOR_SWIFT_ENVIRONMENT_OK` because `scratch/ladder-corpus/focus-ios` is
absent on this VM. The sealed gate compiles with a clean product tree
(`products=clean`). Active Cursor Build observed on this run was
`bld-20260906-253cd433-7a30-4d11-aad2-8b209b7b2d21` (campaign expected
`bld-20260901-d3266600-d87b-438f-94c1-d1aa48036e87`). Starting commit
`343270ce44481a5ae11b87a6e0713e396ada1ef2` matched.

`origin/agent/fw-lockedcameracapture` did not exist; this pass publishes that
branch from the Cursor-created work branch.

`bash full/lockedcameracapture/tests/acceptance/test_host.sh` ended:

```
FRAMEWORK_FANOUT_DELIVERABLE_OK module=LockedCameraCapture lane=leaf-full symbols=43
FRAMEWORK_FANOUT_REFERENCE_OK
LOCKEDCAMERACAPTURE_AGENT_RUNTIME_OK
FRAMEWORK_FANOUT_HOST_OK module=LockedCameraCapture dylib=libLockedCameraCapture.dylib
```

The campaign inventory stamp `CURSOR_SWIFT_ENVIRONMENT_OK swift=6.2.4 target=linux products=clean` is a host-inventory token, not printed by the sealed framework gate. `swiftc` is Swift 6.2.4 / linux and the gate compiled with a clean product tree.

### What is real

- `NSUserActivityTypeLockedCameraCapture` is a stable nonempty string. Linux
  uses the constant name as the payload so `NSUserActivity(activityType:)`
  round-trips. Apple's bytes are unobserved.
- `LockedCameraCaptureSession.ApplicationLaunchError` cases are `.unknown`,
  `.applicationNotFound`, then `.authenticationFailed` (API-digester order).
  `errorCode` is 0 / 1 / 2. `errorDomain` is
  `"LockedCameraCaptureSession.ApplicationLaunchError"`. `failureReason`
  returns the public doc-comment summaries. Synthesized `LocalizedError`
  `errorDescription` / `helpAnchor` / `recoverySuggestion` stay `nil`.
- `LockedCameraCaptureSession.sessionContentURL` is a unique temporary
  directory. `invalidateSessionContent()` deletes children and keeps the
  directory.
- `openApplication(for:)` records the activity type and always throws
  `.unknown`. It does not unlock a device or launch an app.
- `LockedCameraCaptureManager.shared` is a process-local singleton.
  `sessionContentURLs` starts empty. `invalidateSessionContent(at:)` ignores
  URLs that are not in the list (documented) and removes owned URLs.
- `beginDelayingAppearance()` / `endDelayingAppearance()` maintain a clamped
  delay depth. They do not delay UI.
- `LockedCameraCaptureUIScene` stores the content closure and a process-local
  session. `body` is a leaf host scene that does not present camera UI.

### Fail-closed boundaries

- No Lock Screen camera extension, Control Center capture button, or PhotoKit
  ingest.
- No containing-app handoff, lock-screen authentication sheet, or `appex`
  process.
- Isolated-host `openApplication` / `invalidateSessionContent` are
  synchronous `throws` (Apple USRs are `async throws`) so the no-run-loop
  runner can call them.
- Isolated-host `NSUserActivity` / `View` / `AppExtension` /
  `AppExtensionScene` / `AppExtensionSceneConfiguration` names exist only
  when Foundation Darwin / SwiftUI / ExtensionFoundation / ExtensionKit
  cannot be imported. They are not those modules' ABI.
- Darwin `@MainActor` on extension types is omitted so the host gate can
  call them synchronously.
- TBD-only SPI (`hasActiveSession`, `urlsToOpen`,
  `openApplicationAfterTransitionCompletion`,
  `applicationDidCompleteTransition`) is not published; it is not in the
  43-ID public surface.
