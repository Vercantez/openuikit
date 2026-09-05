# PhotosUI SDK depth, second pass (agent/fw-photosui2)

Base: `origin/agent/fw-photosui` (first pass, refused for coverage honesty).
Scope: `full/photosui/` plus this report. No uikit sources, no `reference/`
or `tests/acceptance/` edits, no pin files.

## What was refused

`coverage.tsv` marked **1026** identifiers `implemented`, but **769** of
951 non-enum implemented rows cited one test
(`tests/agent/PhotosUIViewSurfaceTests.swift#testViewSurfaceIdentity`) —
a bulk relabel of the SwiftUI `View`/modifier surface as "identity
implemented". Invented success is worse than a marked gap.
`implemented` evidence must be a focused test of that identifier's
behaviour. Only enum/option-set members may share one table-driven
raw-value test.

## Coverage before / after

| | implemented | declared | deferred | nondeferred |
|---|---:|---:|---:|---:|
| first pass (refused) | 1026 | 11 | 0 | 1037 |
| this pass | **257** | **780** | 0 | 1037 |

Public surface is still 1037 precise IDs. The medium-full floor is 519
nondeferred; 1037 remains well above it.

Every row whose only evidence was `testViewSurfaceIdentity` is `declared`
again with `source:full/photosui/PhotosUIViewSurface.swift#<func>` (the
identity no-op in that file). `PhotosUIViewSurfaceTests.swift` is deleted.

No implemented test is cited by more than 40% of the non-enum implemented
rows (max is 24 / 233 = 10.3%).

## Evidence distribution (top 5 tests by row count)

1. `testPickerCapabilitiesOptionSet` — 29 (OptionSet members + protocol operations; macios raw bits)
2. `testLivePhotoBadgeOptions` — 26 (OptionSet members + protocol operations; macios raw bits)
3. `testPickerConfigurationObjCEnums` — 17 (table-driven `Int` raw values)
4. `testPhotosPickerStyleAndBehavior` — 17
5. `testPickerConfigurationNestedEnums` — 17

28 distinct cited tests. 257 implemented rows.

## Behaviour this pass actually tests

Cited Apple documentation, not a comparison-score search.

1. **PHPickerFilter algebra.** Apple `PHPickerFilter`
   (https://developer.apple.com/documentation/photosui/phpickerfilter-swift.struct):
   `.images` / `.videos` / `.livePhotos` and `any(of:)` / `all(of:)` /
   `not(_:)`. Linux equality is structural: `any(of: [.images, .videos])`
   equals the same-order array and is unequal to the reversed array
   (Apple's composition identity is unobserved; see oracle-questions.tsv).
   Host SPI `_matches` classifies portable `UTType` values (`public.jpeg`
   conforms to `public.image`); it is not Apple's Photos-library asset
   classifier.
2. **PHPickerConfiguration.** Apple
   (https://developer.apple.com/documentation/photosui/phpickerconfiguration-swift.struct
   and `/selectionlimit`): default `selectionLimit` is 1; 0 is stored as
   unlimited (no chrome to enforce the cap). `filter`,
   `preselectedAssetIdentifiers`, `preferredAssetRepresentationMode`
   `.automatic`/`.current`/`.compatible`, `selection`
   `.default`/`.ordered`, `mode`, `disabledCapabilities`, and
   `edgesWithoutContentMargins` round-trip. Nested Swift enums and the
   ObjC overlay raw values (`automatic=0`, `ordered=1`, …) are table-driven
   from pinned macios. `Update` is a value snapshot for
   `updatePicker(using:)`.
3. **PHPickerViewController.** Apple
   (https://developer.apple.com/documentation/photosui/phpickerviewcontroller
   and `/phpickerviewcontrollerdelegate`): stores `configuration` and a
   weak `delegate`. `@_spi(OpenUIKitHost) _enqueueResults` queues results
   for the next `_present()`. `_present()` delivers
   `picker(_:didFinishPicking:)` on the main thread with `[]` (Apple's
   documented cancel / empty selection) unless results were queued;
   queued results are delivered once and cleared. Linux has no picker
   chrome; `deselect` / `move` / `scroll` / `zoom` are no-ops.
   Off-main `DispatchQueue.main.sync` is documented and not invoked by
   the sealed runner (no main run loop).
4. **PHPickerResult.** Apple
   (https://developer.apple.com/documentation/photosui/phpickerresult-swift.struct)
   plus Foundation `NSItemProvider`
   (https://developer.apple.com/documentation/foundation/nsitemprovider):
   `assetIdentifier` and `itemProvider`. Host `_hostResult` registers a
   payload under a portable UTType identifier (`public.jpeg`). Isolated
   `NSItemProvider` implements `registeredTypeIdentifiers`,
   `hasItemConformingToTypeIdentifier` (jpeg conforms to `public.image`),
   `loadDataRepresentation`, `loadFileRepresentation`, and
   `loadObject(ofClass: Data.self)`.
5. **PHLivePhotoView fail-closed.** Apple
   (https://developer.apple.com/documentation/photosui/phlivephotoview):
   `startPlayback` / `stopPlayback` do not invoke the delegate when
   `livePhoto` is nil. `isMuted` and `contentsRect` are stored values.
6. **PhotosPicker / PhotosPickerItem.** `PhotosPickerItem.loadTransferable`
   returns an installed `Transferable` on the completion path (async
   overload uninvoked by the sealed runner). `PhotosPicker` constructors
   typecheck. `View.photosPicker` modifiers remain identity functions
   (no system picker UI).

`photosui_guest_sources.txt` is unchanged (seven sorted product sources).

## Verification

- Isolated Linux `swiftc -warnings-as-errors` of `libPhotosUI.dylib` (7
  guest sources) plus 28 cited tests in `docker exec uikit-linux`
  (Swift 6.2.4): stdout is exactly `PHOTOSUI_AGENT_RUNTIME_OK`.
- Shared deliverable validator is otherwise clean after splitting
  `@_spi(OpenUIKitHost) import PhotosUI` so the identity probe matches
  `^\s*import PhotosUI$`. It still refuses the sealed
  `provenance.generatorSHA256` (`e44f6bde…` in `reference/framework.json`
  vs `e56ee6e7…` on `scripts/framework-fanout/generate_seed_v2.py`). That
  digest is immutable; this branch does not rewrite it. The compile/test
  half of `tests/acceptance/test_host.sh` is green on Linux.

## Open (oracle-questions.tsv)

Unchanged from the first pass, including:

- iOS 26.1 runtime default for `selectionLimit` (Linux uses the documented 1).
- `PHPickerFilter.any(of:)` / `all(of:)` equality order-sensitivity.
- `picker(_:didFinishPicking:)` queue hop on iOS 26.1.
- `NSItemProvider` registering `public.image` in addition to `public.jpeg` /
  `public.heic`, and whether `loadFileRepresentation` deletes the temp file.
- Limited-library completion queue and cancel payload.
- `PhotosPickerItem` async `loadTransferable` executor and missing-representation policy.
