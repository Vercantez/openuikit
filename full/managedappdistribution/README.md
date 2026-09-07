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

The earlier pass established **104 implemented / 1538 declared / 22 deferred /
0 unavailable / 0 not-applicable**.

## Depth pass 2026-09 (wave 8)

Wave 8 exhausted the only remaining non-overlay family,
`ManagedAppLibrary.ManagedApps.AsyncIterator.next`: both async overloads now have
focused, bounded tests for the real fail-closed state machine. Each iterator emits
`.failure(.deviceNotManaged)` once and then ends. The synchronous sealed-test
entry points run the operations on Swift's cooperative executor and use a bounded
`NSCondition` wait; they do not depend on a main queue or run loop.

Before: **104 implemented / 1538 declared / 22 deferred / 0 unavailable /
0 not-applicable**. After: **106 implemented / 1536 declared / 22 deferred /
0 unavailable / 0 not-applicable**. The implemented gain is two identifiers; this
exhausts the two-row `aB7Library` family named by the wave-8 task.

The 1,536 remaining declared rows are synthesized SwiftUI cross-import modifier
occurrences. The wave instruction calls for these to be `not-applicable`, but the
immutable leaf-full validator requires 1,332 `implemented` or `declared` rows and
rejects that required classification (leaving 106). They therefore remain
`declared` pending a central gate/schema resolution; none is relabeled
`implemented`.

Top-5 implemented evidence distribution:

| Citations | Evidence |
| ---: | --- |
| 11 | `ManagedAppTests.swift#testManagedAppStoresMetadata` |
| 7 | `ManagedAppDistributionErrorTests.swift#testErrorCases` |
| 5 | `ManagedContentTests.swift#testOfferStateCases` |
| 4 | `ManagedAppPlatformTests.swift#testManagedAppPlatformCases` |
| 4 | `ManagedAppDistributionErrorTests.swift#testErrorRecoveryFailClosed` |

`testErrorCases` is a table-driven enum-member value test. No non-enum test is
cited by more than 40% of implemented rows.

The sealed host gate is run as
`bash full/managedappdistribution/tests/acceptance/test_host.sh`.
