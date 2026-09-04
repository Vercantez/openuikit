# PhotosUI (Linux starting point)

This directory is a clean-room Linux starting point for Apple's public
`PhotosUI` module, seeded from the Xcode 26.1 iPhoneOS 26.1 symbol graph,
API digester, TBD exports, and pinned `dotnet/macios` bindings. It is not
wired into the shared guest package; that integration is a later
central-review step.

Unchanged application source continues to import `PhotosUI`. Linux has no
Photos library, no system picker UI, and no Live Photo playback engine.
Picker configuration and filter values are real; presentation, playback,
limited-library UI, and iCloud shared-album posting fail closed.

## What is real

- `PHPickerMode` is `.default` (0) and `.compact` (1), matching pinned
  macios `PHPickerMode`.
- `PHPickerFilter` stores the public catalog (`images`, `videos`,
  `livePhotos`, `bursts`, `panoramas`, `screenshots`, `depthEffectPhotos`,
  `spatialMedia`, `cinematicVideos`, `slomoVideos`, `timelapseVideos`,
  `screenRecordings`) plus `any` / `all` / `not` / `playbackStyle`.
  Host SPI `_matches` classifies portable `UTType` values; it is not
  Apple's Photos-library asset classifier.
- `PHPickerConfiguration` keeps selection limit (portable default 1),
  filter, preselected identifiers, mode, nested
  `AssetRepresentationMode` / `Selection`, `disabledCapabilities`, and
  `edgesWithoutContentMargins`. `Update` is a value snapshot for
  `updatePicker(using:)`.
- ObjC overlay enums `PHPickerConfigurationAssetRepresentationMode`
  (`automatic=0`, `current=1`, `compatible=2`) and
  `PHPickerConfigurationSelection` (`default=0`, `ordered=1`,
  `continuous=2`, `continuousAndOrdered=3`) use pinned macios raw values.
- `PHPickerCapabilities` and `PHLivePhotoBadgeOptions` are OptionSets
  with pinned macios bit values. `PHLivePhotoViewPlaybackStyle` is
  `undefined=0`, `full=1`, `hint=2`.
- `PHPickerResult` holds an `NSItemProvider` lookalike and optional
  asset identifier.
- `PhotosPickerItem` stores an identifier and optional typed
  transferables installed through `@_spi(OpenUIKitHost)`. Completion
  `loadTransferable` finishes synchronously; the `async` overload is not
  invoked by the sealed host runner.
- `PhotosPicker`, `PhotosPickerStyle`, and
  `PhotosPickerSelectionBehavior` construct without presenting UI.

## Fail-closed boundaries

- `PHPickerViewController` stores configuration and ignores
  deselect/move/scroll/zoom/update. There is no picker chrome.
- `PHLivePhotoView.startPlayback` / `stopPlayback` are no-ops.
  `livePhotoBadgeImage` returns an empty `UIImage` lookalike, not Apple
  badge artwork.
- `PHPhotoLibrary.presentLimitedLibraryPicker` does not present UI and
  reports an empty identifier list.
- `postToPhotosSharedAlbumSheet` dismisses immediately with
  `PhotosUIUnavailable.linuxHost`.
- `View.photosPicker` modifiers are identity functions on Linux. The
  Darwin overlay in `PhotosUISwiftUI.swift` still hosts the original
  IceCubes presentation SPI; it is not part of the isolated guest
  manifest.
- SwiftUI.View members synthesized onto `PhotosPicker` are identity
  no-ops in `PhotosUIViewSurface.swift`. They compile; they do not
  implement Apple layout, accessibility, or navigation.

## Lookalikes

Isolated host sources import Foundation only. Types owned by Photos,
UIKit, UniformTypeIdentifiers, CoreTransferable, and SwiftUI are
module-local stand-ins in `PhotosUILookalikes.swift`, compiled only when
those modules are absent. `tests/agent/PhotosUIDependencyIdentity.swift`
imports the real `PhotosUI` and `Foundation` modules for the later EC2
build and must not be used to justify public substitutes for
Foundation-owned types.

## Existing Darwin host gate

The combined PhotosUI + SwiftUI overlay script remains:

```sh
bash full/photosui/tests/test_photosui_host.sh
```

That script typechecks against an iPhoneOS SDK and a pinned IceCubes
checkout; it is Darwin-only. The wave-5 Linux deliverable gate is
`tests/acceptance/test_host.sh`.
