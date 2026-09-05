# Photos

Linux starting point for Apple's public `Photos` module, reconstructed from
the pinned Xcode 26.1 iPhoneOS symbol graph, API digester, and a real
on-disk library under the process documents directory.

## What is real

The public Swift surface compiles to `libPhotos.dylib` with Foundation only.

On-disk library (`Documents/OpenUIKitPhotoLibrary`):

- `PHPhotoLibrary.shared()`, `authorizationStatus(for:)` starts `.notDetermined`.
- Documented test hook `PHPhotoLibraryPortable._installAuthorizationHandler`
  drives `.notDetermined` → `.authorized` / `.denied` / `.limited`. Without it,
  `requestAuthorization(for:)` fail-closes to `.denied`. Already-determined
  statuses short-circuit. The completion-handler overlay is delivered on the
  serial queue `org.openuikit.Photos.host-callback`.
- `performChanges` / `performChangesAndWait` apply
  `PHAssetChangeRequest.creationRequestForAsset(from:)`,
  `creationRequestForAssetFromImage(atFileURL:)` (nil if the file is missing),
  `PHAssetCollectionChangeRequest`, `deleteAssets`, and property updates into
  that directory. Unauthorized writes throw `PHPhotosError.accessUserDenied`.
- Change observers receive `PHChange`. `PHFetchResultChangeDetails` computes
  inserted / removed / changed indexes by `localIdentifier`.
- `PHAsset.fetchAssets(with:options:)`, `fetchAssets(withLocalIdentifiers:)`,
  `fetchAssets(in:)` honor `PHFetchOptions` `predicate` (documented keys via
  `NSPredicate` over an `NSDictionary` on Darwin). Linux corelibs has no
  `NSPredicate(format:)` / `NSSortDescriptor.key`; the isolated host uses the
  documented SPI `hostPredicateEvaluates` and `hostSortsByCreationDateAscending`
  instead. `fetchLimit` and `includeHiddenAssets` apply on both.
- Smart-album subtypes exist. Membership that can be decided from stored
  fields (Recents, Favorites, Videos, Hidden, Live Photos, Screenshots, …)
  is live; subtypes that need unobserved Darwin classifiers stay empty.
- `PHImageManager.requestImageDataAndOrientation` returns on-disk bytes and
  the C-identifier info keys. `requestImage` decodes through UIKit/AppKit
  `UIImage(data:)` when that module is imported; on the isolated Linux host
  it fail-closes with `PHImageErrorKey` unless a host-installed `UIImage` is
  present (Ice Cubes contract). Delivery is inline (same contract).
- `PHAssetResource` / `PHAssetResourceManager.requestData` / `writeData` read
  the stored payload. `PHLivePhoto` requests remain fail-closed.
- PNG IHDR bytes 16..<24 of the embedded 1×1 probe are width=1, height=1.

`PHPhotosErrorDomain` is `"PHPhotosErrorDomain"`. Info-dictionary keys are the
C identifiers until an Apple oracle records payloads.

## Fail-closed boundaries

Linux has no `photolibraryd`, TCC prompt, iCloud Photos, or ImageIO on the
isolated host.

- Unauthorized fetches are empty; unauthorized writes throw `.accessUserDenied`.
- Cloud identifier maps return `.identifierNotFound`.
- Live Photo request handlers return `nil` plus `PHLivePhotoInfoErrorKey`.
- `requestImage` without a host `UIImage` and without UIKit/AppKit decoding
  returns `nil` plus `PHImageErrorKey`.
- Smart albums whose Darwin classifier is unobserved (Recently Added,
  Selfies, Long Exposure, RAW, Generic, Unable to Upload) are empty.

## Still deferred

Members that require `UTType`, `CLLocation`, `CIImage`, `CMTime`, `AVAsset` /
`AVPlayerItem`, `URLRequest`, `NSFastEnumeration`, `AppExtension`, or Combine
are omitted from this compile. `PHPhotosError.invalid` has no established raw
value in the pinned bindings.

See `oracle-questions.tsv` for callback timing, TCC prompting, info-key
payloads, and Recently Added membership.

Run `bash tests/acceptance/test_host.sh` from this directory. Keep generated
products out of the tree.
