# ManagedAppDistribution (Linux starting point)

This directory is a clean-room Linux starting point for Apple's public
`ManagedAppDistribution` module, seeded from the Xcode 26.1 iPhoneOS 26.1
symbol graph, API digester, TBD exports, and corpus metadata. It is not
wired into the shared guest package; that integration is a later
central-review step.

Linux has no MDM client, no managed-app distribution daemon, and no App
Store / marketplace artwork CDN. Catalog refresh and install never report
Apple service success.

## What is real

- `Platform` and nested `ManagedApp.Platform` with `iOS` / `macOS` /
  `visionOS` and `description` equal to those names. They are distinct
  types: `ManagedApp.platform` is the module-level `Platform`.
- `ManagedApp` stores documented metadata (`name`, `subtitle`, `seller`,
  `genres`, `description`, `languages`, `requirements`, `version`,
  `releaseDate`, `releaseNotes`, `contentRating`, URL fields, `fileSize`,
  `copyright`). Equality and hashing cover those fields. `id` /
  `ManagedApp.ID` is the host bundle identifier.
- `iconURL(fitting:)` / `screenshotURLs(fitting:)` return a host-installed
  URL list for an exact `CGSize` key, otherwise `nil` / `[]`.
- `ManagedAppDistributionError` has the six digester-ordered cases with
  graph documentation strings. Recovery APIs fail closed (`false`, empty
  options). Linux Codable uses a `linuxCase` key.
- `ManagedAppLibrary.currentDistributor` is a process-local singleton.
  `_catalogSnapshot()` is `.failure(.deviceNotManaged)`.
- `ManagedContentStyle` (`header` / `compact` / `automatic`) and
  `ManagedContentOfferState` (`installing(progress:)`, `notInstalled`,
  `neverInstalled`, `noninteractive`, `custom(title:)`, `installed`).
- `ManagedAppView` stores the app and renders `Text(app.name)`.
  `ManagedContentView` stores labels, offer state, optional action, and
  returns the supplied icon as `body`.
- `managedContentStyle(_:)` records the style and returns `self`.
- Synthesized SwiftUI `View` modifiers compile as identity no-ops.

`tests/agent/ManagedAppDistributionLoadSmoke.swift` is the schema-v2
import marker. The sealed gate derives its runner from `implemented`
coverage.

## Fail-closed boundaries

- No MDM catalog, install, license, or artwork CDN.
- Unmanaged Linux: library snapshot is `deviceNotManaged`.
- Icon/screenshot APIs do not invent URLs.
- `attemptRecovery` always returns `false`.
- Overlay views do not present Apple offer chrome.
- Swift concurrency `AsyncSequence` witnesses on `ManagedApps` are
  **deferred**: the sealed runner cannot await.

## Depth pass 2026-09

Fresh seed: no prior implemented/declared split. After this pass:
**104 implemented / 1538 declared / 22 deferred**.

Nondeferred count 1642, above the leaf-full floor of 1332.

Top-5 implemented evidence distribution:

| Citations | Evidence |
| ---: | --- |
| 11 | `ManagedAppTests.swift#testManagedAppStoresMetadata` |
| 7 | `ManagedAppDistributionErrorTests.swift#testErrorCases` |
| 5 | `ManagedContentTests.swift#testOfferStateCases` |
| 4 | `ManagedAppPlatformTests.swift#testManagedAppPlatformCases` |
| 4 | `ManagedAppDistributionErrorTests.swift#testErrorRecoveryFailClosed` |

`testErrorCases` is a table-driven enum-member value test.
`testOfferStateCases` / `testManagedAppPlatformCases` cover enum-like
static members. No non-enum test exceeds 40% of implemented rows.

The sealed host gate was run as
`bash full/managedappdistribution/tests/acceptance/test_host.sh`.

Environment: `swiftc` reports Swift 6.2.4, target `x86_64-unknown-linux-gnu`.
`.cursor/verify-cloud-environment.sh` does not print
`CURSOR_SWIFT_ENVIRONMENT_OK swift=6.2.4 target=linux products=clean`
on this snapshot (`scratch/ladder-corpus/focus-ios` is missing; Cursor
Build `bld-20260906-253cd433-7a30-4d11-aad2-8b209b7b2d21` vs campaign
seed `bld-20260901-d3266600-d87b-438f-94c1-d1aa48036e87`). The sealed
framework gate compiles with a clean product tree (`products=clean`).
