# PhotosUI (Linux starting point)

This directory is a clean-room Linux starting point for Apple's public
`PhotosUI` module, seeded from the Xcode 26.1 iPhoneOS 26.1 symbol graph,
API digester, TBD exports, and pinned `dotnet/macios` bindings. It is not
wired into the shared guest package; that integration is a later
central-review step.

Unchanged application source continues to import `PhotosUI`. Linux has no
Photos library, no system picker UI, and no Live Photo playback engine.
Picker configuration, filters, results, and the picker-delegate hook are
real; playback, limited-library UI, and iCloud shared-album posting fail
closed.

## Depth pass 2026-09 (wave 8)

SDK depth for `PhotosUI` in `full/photosui/` covers all 1,037 exact IDs.
This next-pass audit began from the supplied ledger and preserved all existing
behavior and focused synchronous tests.

| Status | Before | After |
| --- | ---: | ---: |
| implemented | 259 | 259 |
| declared | 634 | 634 |
| deferred | 0 | 0 |
| unavailable | 0 | 0 |
| not-applicable | 144 | 144 |
| **total** | **1037** | **1037** |

All 634 remaining declared IDs are precise `s:7SwiftUI4ViewPAAE…` synthesized
`View` members on `_PhotosUI_SwiftUI.PhotosPicker`; every non-overlay identifier
is already implemented. This exhausts the remaining non-overlay families, so
the honest implemented gain is 0. These inherited declarations remain in the
ledger because the sealed medium-full gate requires 519 implemented-or-declared
IDs, while only 259 IDs are non-overlay. They are not claimed as implemented
behavior. This seed/gate conflict remains an unresolved central-review question;
relabeling them as implemented would fabricate PhotosUI-owned behavior.

Top-5 implemented evidence distribution (259 rows; 40% cap = 103 rows):

| Rows | Share | Evidence |
| ---: | ---: | --- |
| 29 | 11.2% | `PhotosUITests.swift#testPickerCapabilitiesOptionSet` (table-driven OptionSet) |
| 26 | 10.0% | `PhotosUITests.swift#testLivePhotoBadgeOptions` (table-driven OptionSet) |
| 17 | 6.6% | `PhotosUITests.swift#testPickerConfigurationObjCEnums` (table-driven enum) |
| 17 | 6.6% | `PhotosUITests.swift#testPhotosPickerStyleAndBehavior` (table-driven values) |
| 17 | 6.6% | `PhotosUITests.swift#testPickerConfigurationNestedEnums` (table-driven enum) |

No test supplies more than 40% of implemented evidence. Apple-service, Photos
library, picker chrome, and Live Photo playback behavior remains explicitly
fail-closed as documented below; no unavailable row is used as a substitute.
The verified environment emitted the required Swift 6.2.4 Linux scratch-corpus
marker at starting commit `08da4b0127920d2a794d74490b5a0e8faed63584`.

## What is real

- `PHPickerMode` is `.default` (0) and `.compact` (1), matching pinned
  macios `PHPickerMode`.
- `PHPickerFilter` stores the public catalog (`images`, `videos`,
  `livePhotos`, `bursts`, `panoramas`, `screenshots`, `depthEffectPhotos`,
  `spatialMedia`, `cinematicVideos`, `slomoVideos`, `timelapseVideos`,
  `screenRecordings`) plus `any` / `all` / `not` / `playbackStyle`.
  Equality is structural (composed `any`/`all` arrays are order-sensitive).
  Host SPI `_matches` has two overloads: portable `UTType` values, and
  `PHPickerHostAsset` Photos-lane attributes (`mediaKind`, live/screenshot/
  panorama/burst/depth/spatial/cinematic/slomo/timelapse/screen-recording
  flags, `playbackStyle`). `images` matches `mediaKind == .image` (including
  live photos); `livePhotos` requires `isLivePhoto`. The classifier is not
  Apple's Photos-library detector.
  Docs: https://developer.apple.com/documentation/photosui/phpickerfilter-swift.struct
- `PHPickerConfiguration` keeps selection limit (portable default 1,
  matching Apple's documented default), filter, preselected identifiers,
  mode, nested `AssetRepresentationMode` / `Selection`,
  `disabledCapabilities`, and `edgesWithoutContentMargins`. `Update` is a
  value snapshot for `updatePicker(using:)`.
  Docs: https://developer.apple.com/documentation/photosui/phpickerconfiguration-swift.struct
- ObjC overlay enums `PHPickerConfigurationAssetRepresentationMode`
  (`automatic=0`, `current=1`, `compatible=2`) and
  `PHPickerConfigurationSelection` (`default=0`, `ordered=1`,
  `continuous=2`, `continuousAndOrdered=3`) use pinned macios raw values.
- `PHPickerCapabilities` and `PHLivePhotoBadgeOptions` are OptionSets
  with pinned macios bit values. `PHLivePhotoViewPlaybackStyle` is
  `undefined=0`, `full=1`, `hint=2`.
- `PHPickerResult` holds an `NSItemProvider` and optional asset
  identifier. `@_spi(OpenUIKitHost) _hostResult` registers a payload under a
  portable UTType identifier (`public.jpeg` / `public.image` /
  `public.movie`). Isolated-host `NSItemProvider` implements
  `registeredTypeIdentifiers`, `hasItemConformingToTypeIdentifier`,
  `registerDataRepresentation`, `loadDataRepresentation`,
  `loadFileRepresentation`, and `loadObject(ofClass: Data.self)`.
  Docs: https://developer.apple.com/documentation/photosui/phpickerresult-swift.struct
  and https://developer.apple.com/documentation/foundation/nsitemprovider
- `PHPickerViewController` stores configuration and a weak delegate.
  `@_spi(OpenUIKitHost) _installLibrary` installs a portable Photos-lane
  catalog; `_hostSelect` appends matching identifiers honoring
  `selectionLimit` (`0` = unlimited) and `filter`. Preselected identifiers
  that are missing or fail the filter are dropped. `deselectAssets` and
  `moveAsset` mutate that host selection; `updatePicker(using:)` applies
  `Update.selectionLimit` / `edgesWithoutContentMargins` (Linux truncates
  selection when the new limit is smaller). `scrollToInitialPosition` /
  `zoomIn` / `zoomOut` are host-observable counters, not picker chrome.
  `@_spi(OpenUIKitHost) _present()` delivers `picker(_:didFinishPicking:)`
  on the main thread with `_enqueueResults` if queued, else `PHPickerResult`
  values for the current selection (empty array = cancel).
  Docs: https://developer.apple.com/documentation/photosui/phpickerviewcontroller
- `PHContentEditingController` is a real protocol; a host stub can be
  messaged. There is no Photos extension session.
  Docs: https://developer.apple.com/documentation/photosui/phcontenteditingcontroller
- `PhotosPickerItem` stores an identifier and optional typed
  transferables installed through `@_spi(OpenUIKitHost)`. Completion
  `loadTransferable` finishes synchronously. The typed
  `loadTransferable(type:)` overload is **throws** on the isolated host
  so a sealed-runner test can call it; Apple's method is `async throws`
  (oracle-questions.tsv). Darwin `PhotosUISwiftUI.swift` still declares
  the async overlay and is not in the isolated guest manifest.
- `PhotosPicker` stores maxSelectionCount, selectionBehavior, filter,
  encoding, library flag, style, accessory visibility/edges, and
  disabledCapabilities. `photosPickerStyle` /
  `photosPickerAccessoryVisibility` /
  `photosPickerDisabledCapabilities` copy-and-set those fields.
  `photosPicker(isPresented:)` overlays on `PhotosPicker` record the
  presentation filter/limit/library rather than returning identity.
  `PhotosPickerStyle` and `PhotosPickerSelectionBehavior` are value
  types. There is no picker chrome.

## Fail-closed boundaries

- `PHPickerViewController` has no picker chrome. `deselect` / `move` /
  `scroll` / `zoom` mutate host-selection state only. `updatePicker(using:)`
  stores the `Update` and applies limit/edges on Linux; Apple's live
  chrome is absent.
- `PHLivePhotoView.startPlayback` / `stopPlayback` record the requested
  style for host observation and do not invoke `PHLivePhotoViewDelegate`.
  `livePhotoBadgeImage` returns an empty `UIImage` lookalike, not Apple
  badge artwork.
  Docs: https://developer.apple.com/documentation/photosui/phlivephotoview
- **Listed gap:** `PHPhotoLibrary.presentLimitedLibraryPicker` does not
  present UI on Linux and reports an empty identifier list immediately.
- `postToPhotosSharedAlbumSheet` dismisses immediately with
  `PhotosUIUnavailable.linuxHost`.
- `View.photosPicker` modifiers on arbitrary `View` values are identity
  functions on Linux. The same-named overlays on `PhotosPicker` store
  presentation config. The Darwin overlay in `PhotosUISwiftUI.swift`
  still hosts the original IceCubes presentation SPI; it is not part of
  the isolated guest manifest.
- SwiftUI.View members synthesized onto `PhotosPicker` are identity
  no-ops in `PhotosUIViewSurface.swift`. They compile and return `Self`;
  they do not implement Apple layout, accessibility, or navigation.
  Generic `s:7SwiftUI4ViewPAAE*` rows stay `declared`. The 144 overlay
  re-exports called out in the wave-8 depth pass are `not-applicable`.
- `PHLivePhoto` Transferable overlay methods throw
  `PhotosUIUnavailable.linuxHost` inline (Linux has no export session).
  Apple's Transferable API is async; the isolated host uses `throws`
  so tests stay synchronous.

## Lookalikes

Isolated host sources import Foundation only. Types owned by Photos,
UIKit, UniformTypeIdentifiers, CoreTransferable, and SwiftUI are
module-local stand-ins in `PhotosUILookalikes.swift`, compiled only when
those modules are absent. The Linux `NSItemProvider` lookalike exists
because swift-corelibs-foundation does not vend the class; the later
guest must use the port's Foundation type rather than this stand-in.
`tests/agent/PhotosUIDependencyIdentity.swift` imports the real
`PhotosUI` and `Foundation` modules for the later EC2 build and must not
be used to justify public substitutes for Foundation-owned types.

## Existing Darwin host gate

The combined PhotosUI + SwiftUI overlay script remains:

```sh
bash full/photosui/tests/test_photosui_host.sh
```

That script typechecks against an iPhoneOS SDK and a pinned IceCubes
checkout; it is Darwin-only. The wave-5 Linux deliverable gate is
`tests/acceptance/test_host.sh`.
