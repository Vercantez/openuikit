# BrowserEngineKit

Linux starting point for Apple's public `BrowserEngineKit` module, reconstructed
from the pinned Xcode 26.1 iPhoneOS 26.1 symbol graph, API digester, and the
read-only `dotnet/macios` BrowserEngineKit bindings. This directory is not wired
into the shared guest package. A passing isolated host gate is not integrated
Linux success with helper extension processes, `libxpc`, GPU layers, or
Live Activity download monitoring.

## Depth pass 2026-09

This is a fresh seed: 511 exact public identifiers, floor 256 nondeferred.

Coverage after this pass: **506 implemented / 5 declared / 0 deferred /
0 unavailable / 0 not-applicable**.

## Wave 11 re-examination 2026-09-15

Before: 506 implemented / 5 declared / 0 deferred / 0 n-a of 511.
After: 506 implemented / 5 declared / 0 deferred / 0 n-a of 511
(implemented gain 0). The 5 declared rows were rechecked against
`reference/api-digester.json`: all five carry async mangling (`YaKF` —
`BEDownloadMonitor.beginMonitoring()`, `resumeMonitoring(placeholderURL:)`,
and the three process `init(bundleIdentifier:onInterruption:)`), so the
sealed synchronous runner cannot cite them as implemented without `await`
(contract forbids `await`/semaphores in cited tests), and success paths
need a Live Activity daemon / helper appex + libxpc, so they stay
fail-closed `declared`. Zero deferred, unavailable, or not-applicable rows,
and no SwiftUI View-overlay rows, so the overlay OVERRIDE has nothing to
apply. The sealed host gate was invoked but refuses before compiling: the
shared deliverable validator requires
`full/framework-roadmap/framework-roadmap.json`, which is absent from this
isolated worktree (only `browserenginekit`, `familycontrols`, and
`framework-fanout` are present) — a worktree-environment limitation, not a
framework defect; product sources are unchanged.

## Wave 10 re-examination 2026-09-15

Before: 506 implemented / 5 declared / 0 deferred / 0 n-a of 511.
After: 506 implemented / 5 declared / 0 deferred / 0 n-a of 511
(implemented gain 0). The 5 declared rows were rechecked against
`reference/public-surface.tsv` and `reference/api-digester.json`: all five
are genuinely `async throws` on Apple (`BEDownloadMonitor.beginMonitoring()`,
`resumeMonitoring(placeholderURL:)`, and the three process
`init(bundleIdentifier:onInterruption:)`), so the sealed synchronous runner
cannot cite them as implemented without `await`, and restating them with
sync/completion-handler shapes would falsify the Apple signatures. Success
paths also need a Live Activity daemon / helper appex + libxpc, so they stay
fail-closed `declared`. Zero deferred and zero not-applicable rows, so there
is nothing else to convert.

The 14 completion-handler rows (`BETextInput` selection/editing methods and
`BEScrollViewDelegate.scrollView(_:handle:completion:)`) moved from declared
to implemented: the Apple symbol graph declares them with completion
closures, not Swift `async`, so the port now matches that shape and each
completion runs synchronously fail-closed on the caller's thread. The 5
remaining declared rows are genuinely `async throws` on Apple
(`BEDownloadMonitor.beginMonitoring()`, `resumeMonitoring(placeholderURL:)`,
and the three process `init(bundleIdentifier:onInterruption:)`), which the
sealed synchronous test runner cannot invoke.

Top-5 evidence distribution (share of the 506 implemented rows):

1. `BEOptionSetTests.swift#testBEAccessibilityContainerTypeAlgebra` — 21 (4.3%, option-set algebra)
2. `BEOptionSetTests.swift#testBESelectionFlagsAlgebra` — 21 (4.3%, option-set algebra)
3. `BEOptionSetTests.swift#testBETextDocumentRequestOptionsAlgebra` — 21 (4.3%, option-set algebra)
4. `BEOptionSetTests.swift#testBETextReplacementOptionsAlgebra` — 21 (4.3%, option-set algebra)
5. `BEInteractionTests.swift#testBETextInteractionRecordsHostActions` — 17 (3.5%)

No non-enum/option-set-member test is cited by more than 40% of the remaining
implemented rows.

## What is real

- Enumerations `BEAccessibilityPressedState`, `BEGestureType`,
  `BEKeyModifierFlags`, `BEKeyEntry.KeyPressState`,
  `BEScrollViewScrollUpdate.Phase`, and `BESelectionTouchPhase` use the
  pinned macios raw values (`undefined = 0` … `mixed = 3`, `loupe = 0` /
  `forceTouch = 15` with documented gaps, `down = 1` / `up = 2`,
  sequential scroll and selection-touch phases).
- Option sets `BEAccessibilityContainerType`, `BESelectionFlags`,
  `BETextReplacementOptions`, and `BETextDocumentRequest.Options` use the
  documented bit positions (`landmark = 1<<0` … `descriptionList = 1<<11`,
  `wordIsNearTap = 1<<0`, `addUnderline = 1<<0`, `text = 1<<0` /
  `markedTextRects = 1<<5` / `autocorrectedRanges = 1<<7`).
- `BEDirectionalTextRange` stores offset/length; `init()` is `(0, 0)`.
- `BETextDocumentContext` stores string and attributed snapshots, appends
  text rects, and round-trips `autocorrectedRanges`.
- `BETextSuggestion` / `BETextAlternatives` / `BEKeyEntry` /
  `BEKeyEntryContext` store constructor fields. Boolean flags on the context
  default to `false` and are settable.
- `BEWebAppManifest.init?(jsonData:manifestURL:)` succeeds only for JSON
  objects and preserves the original bytes and URL.
- `RestrictedSandboxRevision` is `Comparable` with `revision1 < revision2`
  and `allCases == [.revision1, .revision2]`.
- `ProcessCapability.Grant` uses reference semantics: `isValid` starts true
  and `invalidate()` clears it.
- `NSObject` browser-accessibility properties are process-local: insert/
  delete text at the cursor, selected range, pressed state, and container
  type round-trip. Line-position queries return `NSNotFound`.
- `BETextInteraction` records host actions without presenting UI.
- `BETextInput` completion-handler methods (`adjustSelection`,
  `handleKeyEntry`, `insertTextPlaceholder`, `moveSelection`, `remove`,
  `replaceText`, `requestDocumentContext`, `requestTextRects`,
  `selectPosition`, `selectText`, `updateSelection`) and
  `BEScrollViewDelegate.scrollView(_:handle:completion:)` invoke their
  completion synchronously with fail-closed values (`false`, `[]`, empty
  context, or the passed-through entry).

## Fail-closed boundaries

Linux has no browser-engine helper appex, `libxpc`, mach ports, GPU layer
hierarchy, `AVCaptureSession` sandbox, or Live Activity download daemon.

- `WebContentProcess` / `NetworkingProcess` / `RenderingProcess`
  `makeLibXPCConnection` and `grantCapability` throw
  `BrowserEngineKitHostError.processUnavailable` or `.xpcUnavailable`.
  Async process inits and download-monitor async methods are declared,
  not run: they are `async throws` on Apple and the sealed runner has
  no run loop.
- `LayerHierarchy.init()` and handle/coordinator port/XPC inits throw
  `.layerHierarchyUnavailable`. `encode(_:)` does not invent a mach port.
- `MediaEnvironment.activate` / `suspend` / `makeCaptureSession` throw
  `.mediaSessionUnavailable`.
- `BEDownloadMonitor.createAccessToken()` returns `nil`.
  `useDownloadsFolder` invokes the handler synchronously with `nil`.
- `BEContextMenuConfiguration.fulfill(using:)` returns `false`.
- Extension configuration `accept(connection:)` returns `false`.
- `BEAccessibility` trait/notification constants are host-local bits, not
  claimed Darwin `UIAccessibility` values.

Private TBD types are not part of this module.

## Still open

See `oracle-questions.tsv` for Darwin trait/notification bits, KeyModifierFlags
OptionSet vs enum, process interruption callback timing, layer/download NSError
domains, web-app manifest schema validation, and text-request defaults.

The campaign inventory stamp `CURSOR_SWIFT_ENVIRONMENT_OK swift=6.2.4 target=linux products=clean`
is a host-inventory token. `.cursor/verify-cloud-environment.sh` on this
snapshot fails earlier (`missing corpus checkout: scratch/ladder-corpus/focus-ios`;
Cursor Build `bld-20260906-253cd433-7a30-4d11-aad2-8b209b7b2d21` vs seed
`bld-20260901-d3266600-d87b-438f-94c1-d1aa48036e87`). `swiftc` is Swift 6.2.4 /
linux and the sealed gate compiles with a clean product tree.
