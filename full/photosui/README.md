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

SDK depth for `PhotosUI` in `full/photosui/` (1,037 exact IDs). This is a
second pass: the first-pass sources and `tests/agent/PhotosUITests.swift`
stay in the tree and remain green.

Coverage this round:

| Status | Before (first pass) | After |
| --- | ---: | ---: |
| implemented | 257 | 238 |
| declared | 780 | 655 |
| deferred | 0 | 0 |
| unavailable | 0 | 0 |
| not-applicable | 0 | 144 |
| **total** | **1037** | **1037** |

238 + 655 = 893 nondeferred (floor 519). 144 SwiftUI overlay re-exports
(`s:7SwiftUI4ViewP07_Photos…` View modifiers plus synthesized
`accessibility*` witnesses on `PhotosPicker`) are `not-applicable` with
the note `SwiftUI cross-import overlay; owned by the SwiftUI lane`.
Remaining generic `s:7SwiftUI4ViewPAAE*` identity modifiers stay
`declared` so the sealed 50% floor still holds; they are never
`implemented`. The async `PhotosPickerItem.loadTransferable(type:)`
overload is `declared` (the sealed runner cannot await it).

Top-5 implemented evidence (of 238 rows; 40% cap = 95):

| Rows | Share | Evidence |
| ---: | ---: | --- |
| 29 | 12.2% | `PhotosUITests.swift#testPickerCapabilitiesOptionSet` (table-driven OptionSet) |
| 26 | 10.9% | `PhotosUITests.swift#testLivePhotoBadgeOptions` (table-driven OptionSet) |
| 17 | 7.1% | `PhotosUITests.swift#testPickerConfigurationObjCEnums` (table-driven enum) |
| 17 | 7.1% | `PhotosUITests.swift#testPhotosPickerStyleAndBehavior` (table-driven values) |
| 17 | 7.1% | `PhotosUITests.swift#testPickerConfigurationNestedEnums` (table-driven enum) |

No non-enum/OptionSet test exceeds 40% of implemented rows. Filter catalog
members share `PHPickerFilterTests.swift#testPickerFilterAssetCatalog`,
which evaluates each filter against Photos-lane asset attributes.

Environment: `swiftc` reports Swift 6.2.4, target `x86_64-unknown-linux-gnu`.
`.cursor/verify-cloud-environment.sh` did not emit
`CURSOR_SWIFT_ENVIRONMENT_OK` because `scratch/ladder-corpus/focus-ios` is
absent on this VM. The sealed gate compiles with a clean product tree
(`products=clean`). Active Cursor Build observed on this run was
`bld-20260905-9aa65d65-b87d-46a7-b154-e2f1440dbba3` (campaign expected
`bld-20260901-d3266600-d87b-438f-94c1-d1aa48036e87`). Starting commit
`dd4c8bca7e8735289928bbd1abd44f4b35815308` matched.

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
  `loadTransferable` finishes synchronously; the `async` overload is not
  invoked by the sealed host runner.
- `PhotosPicker`, `PhotosPickerStyle`, and
  `PhotosPickerSelectionBehavior` construct without presenting UI.

## Fail-closed boundaries

- `PHPickerViewController` has no picker chrome. `deselect` / `move` /
  `scroll` / `zoom` mutate host-selection state only. `updatePicker(using:)`
  stores the `Update` and applies limit/edges on Linux; Apple's live
  chrome is absent.
- `PHLivePhotoView.startPlayback` / `stopPlayback` are no-ops and do not
  invoke `PHLivePhotoViewDelegate`. `livePhotoBadgeImage` returns an empty
  `UIImage` lookalike, not Apple badge artwork.
  Docs: https://developer.apple.com/documentation/photosui/phlivephotoview
- **Listed gap:** `PHPhotoLibrary.presentLimitedLibraryPicker` does not
  present UI on Linux and reports an empty identifier list immediately.
- `postToPhotosSharedAlbumSheet` dismisses immediately with
  `PhotosUIUnavailable.linuxHost`.
- `View.photosPicker` modifiers are identity functions on Linux. The
  Darwin overlay in `PhotosUISwiftUI.swift` still hosts the original
  IceCubes presentation SPI; it is not part of the isolated guest
  manifest.
- SwiftUI.View members synthesized onto `PhotosPicker` are identity
  no-ops in `PhotosUIViewSurface.swift`. They compile and return `Self`;
  they do not implement Apple layout, accessibility, or navigation.
  Generic `s:7SwiftUI4ViewPAAE*` rows stay `declared`. The 144 overlay
  re-exports called out in the wave-8 depth pass are `not-applicable`.
- `PHLivePhoto` Transferable overlay methods stay **declared**: they
  throw `PhotosUIUnavailable.linuxHost` and there is no Apple export
  session to observe.

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
