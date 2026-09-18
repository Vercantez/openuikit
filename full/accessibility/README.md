# Accessibility (Linux starting point)

This directory is a fail-closed portable `Accessibility` module for the
OpenUIKit Linux platform. It reconstructs the public Xcode 26.1 iPhoneOS
Swift surface from the sealed symbol graph. It is not wired into the shared
guest package; that integration is a separate central review step.

Coverage: **511 implemented / 9 declared / 0 deferred / 520 total**
(above the leaf-full floor of 416).

## What is real

- `AXFeatureOverrideSessionError` / `AXFeatureOverrideSessionErrorDomain` /
  `Code` with the NS_ERROR_ENUM integers corroborated by pinned dotnet-macios
  (`undefined = 0` … `overrideNotFoundForUUID = 3`). Typed construction,
  `userInfo`, equality, hashing, `NSError` bridging, and `~=` matching are
  exercised.
- Chart, series, axis, and data-point descriptors store and copy their
  fields. Numeric axes keep `ClosedRange` + gridlines + a value-description
  closure. `AXDataPoint.Value` number/category cases convert into
  `AXDataPointValue`.
- MathML-shaped expression trees (`AXMathExpression*` including the Apple
  `denimonatorExpression` spelling) retain the children passed to `init`.
- `AXCustomContent` constructs from String or `NSAttributedString`, copies,
  and round-trips through `NSSecureCoding`.
- `AXBrailleMap` stores per-point heights and dimensions; `NSSecureCoding`
  round-trips that map.
- AttributedString `AttributeScopes.AccessibilityAttributes` keys apply,
  encode, and decode through Foundation's attribute machinery.
- `AXLiveAudioGraph` tracks a local start/stop/update state machine without
  emitting audio.
- Option sets (`AXFeatureOverrideSession.Options`, `AXMFiHearingDevice.Ear`)
  implement the documented bit layouts and standard `OptionSet` algebra.

## Fail-closed boundaries

Linux has no Accessibility daemon, MFi hearing hardware, Settings.app,
feature-override entitlement, VoiceOver/Switch Control process, Apple
liblouis braille catalog, or CoreGraphics color/image pipeline.

- `AXFeatureOverrideSessionManager.beginOverrideSession` throws
  `appNotEntitled`. `end(_:)` throws `overrideNotFoundForUUID`.
- Hearing queries return an empty ear mask and an empty UUID list.
  `supportsBidirectionalStreaming()` is `false`.
- Settings booleans are `false`. `openSettings(for:)` is declared (async
  throws; the sealed runner has no run loop) and fail-closes.
- `AXNameFromColor` returns `""`. `AXBrailleMap.present` is a no-op.
- Braille catalog queries return empty/nil. Translators return an empty
  result string rather than inventing a liblouis mapping.
- `AccessibilityNotification.post()` returns immediately and does not
  claim assistive-technology delivery.
- `AccessibilityRequest.current` is `nil`.

## Depth pass 2026-09

Fresh seed: no prior implemented/declared split. After this pass:
**510 implemented / 10 declared / 0 deferred**.

Declared rows are `openSettings(for:)` (async; no run loop) and the nine
uninhabited attribute-key `description` getters.

## Wave 10 recount 2026-09-15

Before: **510 implemented / 10 declared / 0 deferred / 520 total**.
After: **510 implemented / 10 declared / 0 deferred / 520 total** (no change).
All 10 declared rows were re-examined and none can convert under the sealed
runner rules: `openSettings(for:)` is async throws and cited tests must be
synchronous with no `await`, and each `description` getter is an instance
member of a caseless (uninhabited) attribute-key enum, so no test can
construct a value that calls it. Product sources still compile clean with
`swiftc -warnings-as-errors`.

Top-5 implemented evidence distribution:

| Citations | Evidence |
| ---: | --- |
| 19 | `AccessibilityOptionSetTests.swift#testFeatureOverrideOptionsAlgebra` |
| 19 | `AccessibilityOptionSetTests.swift#testHearingEarAlgebra` |
| 17 | `AccessibilitySettingsTests.swift#testSettingsFailClosedDefaults` |
| 17 | `AccessibilityAttributeTests.swift#testAccessibilityAttributeScope` |
| 17 | `AccessibilityEnumTests.swift#testTextualContextRawValues` |

Option-set algebra tests cover protocol methods on a single OptionSet type.
`testTextualContextRawValues` is a table-driven enum-member test. No
non-enum/option-set test exceeds 40% of remaining implemented rows
(largest remaining family is well under the cap).

The sealed host gate was run as `bash full/accessibility/tests/acceptance/test_host.sh`
and ended:

```
FRAMEWORK_FANOUT_DELIVERABLE_OK module=Accessibility lane=leaf-full symbols=520
FRAMEWORK_FANOUT_REFERENCE_OK
ACCESSIBILITY_AGENT_RUNTIME_OK
FRAMEWORK_FANOUT_HOST_OK module=Accessibility dylib=libAccessibility.dylib
```

`swiftc --version` is Swift 6.2.4 targeting `x86_64-unknown-linux-gnu`.
`.cursor/verify-cloud-environment.sh` does not print
`CURSOR_SWIFT_ENVIRONMENT_OK swift=6.2.4 target=linux products=clean` on this
snapshot (`scratch/ladder-corpus/focus-ios` is missing). That campaign token
is the host-inventory stamp; the sealed framework gate prints the four lines
above.

## Wave 11 recount 2026-09-15

Before: **510 implemented / 10 declared / 0 deferred / 520 total**.
After: **510 implemented / 10 declared / 0 deferred / 520 total** (no change).
All 10 declared rows were re-examined against the sealed-runner rules and
none can convert. `So21AccessibilitySettingsV0A0E04openB03forySo17AXSettingsFeatureV_tYaKFZ`
is `static func openSettings(for:) async throws` (mangled `tYaKFZ`, confirmed
in `reference/api-digester.json`), so no synchronous `func test*()` without
`await` can call it. Each of the nine
`s:10Foundation19AttributedStringKeyPAAE11descriptionSSvp::SYNTHESIZED` rows
is the instance `description` getter of a caseless (uninhabited)
attribute-key enum (`TextCustom/IPANotation/HeadingLevel/AdjustedPitch/
TextualContext/QueueAnnouncement/IncludesPunctuation/AnnouncementPriority/
SpellOut`); no value can be constructed in safe Swift, so no test can invoke
the getter (forging one via `unsafeBitCast` would be UB, not behavioral
evidence). The overlay override does not apply: this lane has no SwiftUI
View-modifier or `not-applicable` rows. Deferred stays at 0; every
unavailable behavior remains honestly fail-closed.

Top-5 implemented evidence distribution (unchanged):

| Citations | Evidence |
| ---: | --- |
| 19 | `AccessibilityOptionSetTests.swift#testFeatureOverrideOptionsAlgebra` |
| 19 | `AccessibilityOptionSetTests.swift#testHearingEarAlgebra` |
| 17 | `AccessibilitySettingsTests.swift#testSettingsFailClosedDefaults` |
| 17 | `AccessibilityAttributeTests.swift#testAccessibilityAttributeScope` |
| 17 | `AccessibilityEnumTests.swift#testTextualContextRawValues` |

Product sources and all 62 cited test functions still compile clean with
`swiftc -warnings-as-errors`; the 62-test runner emits only
`ACCESSIBILITY_AGENT_RUNTIME_OK` (verified with a Darwin-adapted runner;
the committed `test_host.sh` generates a Glibc runner for the Linux sealed
host). The shared deliverable validator currently refuses inside this
isolated worktree for an out-of-lane reason: it requires
`full/framework-roadmap/framework-roadmap.json` at the repo root, which the
worktree does not contain (present in the main checkout). No files outside
`full/accessibility/` were touched.

Local toolchain: Apple Swift 6.2.1 targeting `arm64-apple-macosx26.0`.

## Wave 12 recount 2026-09-15

Before: **510 implemented / 10 declared / 0 deferred / 520 total**.
After: **510 implemented / 10 declared / 0 deferred / 520 total** (no change).
All 10 declared rows were re-examined against the sealed-runner rules and
none can convert. `So21AccessibilitySettingsV0A0E04openB03forySo17AXSettingsFeatureV_tYaKFZ`
is `static func openSettings(for:) async throws` (confirmed in
`reference/api-digester.json` and `AXSettings.swift`), so no synchronous
`func test*()` without `await` can call it. Each of the nine
`s:10Foundation19AttributedStringKeyPAAE11descriptionSSvp::SYNTHESIZED` rows
is the instance `description` getter of a caseless (uninhabited)
attribute-key enum; no value can be constructed in safe Swift, so no test
can invoke the getter, and the contract explicitly forbids converting
stdlib/Foundation protocol witnesses. The overlay override does not apply:
this lane has zero `not-applicable` rows and no SwiftUI View-modifier rows.
Deferred stays at 0; every unavailable behavior remains honestly fail-closed.

Top evidence citation is 19/510 rows (3.7%), far under the 40% cap.
Product sources and all 62 cited test functions still compile clean with
`swiftc -warnings-as-errors`; the 62-test Darwin-adapted runner emits only
`ACCESSIBILITY_AGENT_RUNTIME_OK`. The sealed `test_host.sh` still refuses
inside this isolated worktree for the same out-of-lane reason as wave 11:
it requires `full/framework-roadmap/framework-roadmap.json` at the repo
root, which the worktree does not contain. No files outside
`full/accessibility/` were touched; the only file changed in wave 12 is
this README recount.

## Wave 13 recount 2026-09-18

Before: **510 implemented / 10 declared / 0 deferred / 520 total**.
After: **511 implemented / 9 declared / 0 deferred / 520 total** (+1).
The sealed runner is now `@main async` and awaits `func test*() async`, so
the one async-shaped leftover converts: `openSettings(for:)` throws
fail-closed immediately in-process (no daemon, no suspension, no
RunLoop/DispatchQueue/semaphores), and new async test
`AccessibilitySettingsTests.swift#testOpenSettingsFailClosed` calls it via
`try? await` plus `try await` in `do/catch` and asserts the throw.
The remaining 9 declared rows are the `AttributedStringKey.description`
getters of caseless (uninhabited) attribute-key enums: no value can be
constructed in safe Swift, so no test can invoke them, and the contract
explicitly forbids converting stdlib/Foundation protocol witnesses. The
overlay override does not apply (zero `not-applicable` rows, no SwiftUI
View-modifier rows). Deferred stays at 0.

Top evidence citation is 19/511 rows (3.7%), far under the 40% cap; the
new test is cited once. Product sources and all 63 test functions compile
clean with `swiftc -warnings-as-errors`; a Darwin-adapted async runner
invoking all 63 tests emits only `ACCESSIBILITY_AGENT_RUNTIME_OK` well
under the 120s timeout. Local toolchain: Apple Swift 6.2.1 targeting
`arm64-apple-macosx26.0`.
