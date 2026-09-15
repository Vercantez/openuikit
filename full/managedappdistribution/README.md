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
  Each of the 401 Linux modifier overload families is exercised by a
  synchronous identity test (`tests/agent/ManagedOverlayIdentity*Tests.swift`)
  that calls every overload on both overlay views and checks the value
  passes through unchanged.

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

## Depth pass 2026-09 (wave 3, second pass)

The second pass converted the entire synthesized SwiftUI cross-import
modifier census to `implemented`. Each of the 401 Linux modifier families
in `ManagedAppDistributionViewSurface.swift` gained a synchronous identity
test that calls every overload on both `ManagedAppView` and
`ManagedContentView` and asserts identity (same type, preserved body).
Two pre-existing tests were reused where they already called the modifier
(`testNavigationTitleIdentity`, `testBadgeIdentity`). No test uses a main
queue, run loop, semaphore wait, or `await`.

Before: **106 implemented / 1536 declared / 22 deferred / 0 unavailable /
0 not-applicable**. After: **1642 implemented / 0 declared / 22 deferred /
0 unavailable / 0 not-applicable**. The implemented gain is 1,536
identifiers; no row was bulk-relabeled, and the 22 deferred
`AsyncSequence` witnesses are untouched (the sealed runner cannot await
them).

Top-5 implemented evidence distribution:

| Citations | Share | Evidence |
| ---: | ---: | --- |
| 70 | 4.26% | `ManagedOverlayIdentityDTests.swift#testSearchableIdentity` |
| 40 | 2.44% | `ManagedOverlayIdentityATests.swift#testAlertIdentity` |
| 40 | 2.44% | `ManagedOverlayIdentityATests.swift#testAccessibilityRotorIdentity` |
| 32 | 1.95% | `ManagedOverlayIdentityATests.swift#testConfirmationDialogIdentity` |
| 24 | 1.46% | `ManagedOverlayIdentityATests.swift#testAccessibilityIdentity` |

No single non-enum test is cited by more than 40% of implemented rows
(maximum 4.26%).

The sealed host gate is run as
`bash full/managedappdistribution/tests/acceptance/test_host.sh`.

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

## Depth pass 2026-09 (wave 8, contract-compliance review)

Re-examined the two async `ManagedApps.AsyncIterator.next` overloads the
earlier wave-8 note marked `implemented` via a bounded `NSCondition` harness.
The lane contract forbids `await` and blocking waits in cited tests, and a
synchronous sealed entry point cannot invoke an `async` method without one
or the other, so no compliant test can cite them. Both rows return to
`deferred` alongside their 22 async `AsyncSequence` siblings; the
in-process fail-closed iterator implementation itself is unchanged, and the
harness plus its two test functions are removed from
`tests/agent/ManagedAppLibraryTests.swift`.

Before: **1642 implemented / 0 declared / 22 deferred / 0 unavailable /
0 not-applicable**. After: **1640 implemented / 0 declared / 24 deferred /
0 unavailable / 0 not-applicable**. Implemented gain is −2 for
contract compliance. All 24 deferred rows are `async` Swift concurrency
`AsyncSequence`/`AsyncIterator` members the sealed runner cannot await.
No cited test uses `DispatchQueue.main`, a run loop, a semaphore or
condition wait, `Task`, or `await`.

The sealed host gate is Linux-only (the generated runner imports `Glibc`);
on this Mac its reference/coverage/evidence validation reports
`FRAMEWORK_FANOUT_REFERENCE_OK`, while the compile-and-run stages cannot
execute here (Xcode SwiftUI is present, so the Linux `View` stubs are
correctly excluded).
