# Accessibility (Linux starting point)

This directory is a fail-closed portable `Accessibility` module for the
OpenUIKit Linux platform. It reconstructs the public Xcode 26.1 iPhoneOS
Swift surface from the sealed symbol graph. It is not wired into the shared
guest package; that integration is a separate central review step.

Coverage: **510 implemented / 10 declared / 0 deferred / 520 total**
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
