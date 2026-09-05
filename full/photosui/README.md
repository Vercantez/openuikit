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

Coverage this round: **257 implemented / 780 declared / 1037 total**
(first pass claimed 1026 implemented / 11 declared). 769 synthesized
SwiftUI.View members on `PhotosPicker` are `declared` again: a bulk
identity test is not evidence of that identifier's behaviour. The
PHPickerConfiguration, PHPickerFilter, PHPickerViewController,
PHPickerResult, and PHPickerConfiguration.Update families stay
implemented with focused tests.

## What is real

- `PHPickerMode` is `.default` (0) and `.compact` (1), matching pinned
  macios `PHPickerMode`.
- `PHPickerFilter` stores the public catalog (`images`, `videos`,
  `livePhotos`, `bursts`, `panoramas`, `screenshots`, `depthEffectPhotos`,
  `spatialMedia`, `cinematicVideos`, `slomoVideos`, `timelapseVideos`,
  `screenRecordings`) plus `any` / `all` / `not` / `playbackStyle`.
  Equality is structural (composed `any`/`all` arrays are order-sensitive).
  Host SPI `_matches` classifies portable `UTType` values; it is not
  Apple's Photos-library asset classifier.
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
  `@_spi(OpenUIKitHost) _present()` simulates presentation: it returns
  after delivering `picker(_:didFinishPicking:)` on the main thread with
  an empty selection, or with results previously passed to
  `_enqueueResults`. There is no picker chrome.
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
  `scroll` / `zoom` are no-ops. `updatePicker(using:)` stores the `Update`
  for host observation only.
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
  Coverage lists them `declared`, not `implemented`.
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
