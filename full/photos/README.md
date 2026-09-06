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
  `PHAssetCollectionChangeRequest` / `PHCollectionListChangeRequest` membership
  edits (`add` / `insert` / `move` / `remove` / `replace` / `delete`), and
  property updates into that directory. Unauthorized writes throw
  `PHPhotosError.accessUserDenied`. Swift overlays take `[PHAsset]` /
  `[PHCollection]` rather than `NSFastEnumeration`.
- Change observers receive `PHChange` inline before `performChangesAndWait`
  returns. `PHObjectChangeDetails` reports before/after, deletion, and
  `assetContentChanged`. `PHFetchResultChangeDetails` computes inserted /
  removed / changed indexes by `localIdentifier` and enumerates moves.
  `PHPersistentObjectChangeDetails` records inserted / updated / deleted
  identifiers for assets, albums, and folders.
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
  the stored payload. Resource `progressHandler` is invoked at 1.0; later
  `cancelDataRequest` cannot un-deliver already-returned bytes.
- `PHImageRequestOptions.progressHandler` runs at 0.0 then 1.0; setting the
  stop flag fail-closes the request with `PHImageCancelledKey`.
- `PHLivePhoto` requests remain fail-closed. `PHLivePhotoEditingContext`
  constructs when `PHContentEditingInput.livePhoto` is set, stores
  `audioVolume` / `orientation`, and fail-closes playback/save with
  `requestNotSupportedForAsset` (or `operationInterrupted` after `cancel()`).
- `PHAssetResourceUploadJob.fetchJobs` stays empty. A host SPI can wrap a
  resource for property tests; `changeRequest` / `acknowledge` do not create
  iCloud upload work.
- PNG IHDR bytes 16..<24 of the embedded 1×1 probe are width=1, height=1.
- `PHCollection.fetchTopLevelUserCollections` returns albums and folders that
  are not children of another list. Moment-list fetches stay empty.

`PHPhotosErrorDomain` is `"PHPhotosErrorDomain"`. Info-dictionary keys are the
C identifiers until an Apple oracle records payloads.

## Fail-closed boundaries

Linux has no `photolibraryd`, TCC prompt, iCloud Photos, or ImageIO on the
isolated host.

- Unauthorized fetches are empty; unauthorized writes throw `.accessUserDenied`.
- Cloud identifier maps return `.identifierNotFound`.
- Live Photo request handlers return `nil` plus `PHLivePhotoInfoErrorKey`.
- `PHLivePhotoEditingContext` save/playback fail-closes: no Live Photo
  compositor, ImageIO pair, or `photolibraryd` on Linux.
- `requestImage` without a host `UIImage` and without UIKit/AppKit decoding
  returns `nil` plus `PHImageErrorKey`.
- Smart albums whose Darwin classifier is unobserved (Recently Added,
  Selfies, Long Exposure, RAW, Generic, Unable to Upload) are empty.
- iCloud resource upload jobs never leave `.fetchJobs` empty; `URLRequest`
  destinations stay out of this Foundation-only compile.
- `NSCoding` inits for `PHCloudIdentifier` / `PHLivePhoto` /
  `PHPersistentChangeToken` return `nil` (archive schema unobserved).

## Still deferred

Members that require `UTType`, `CLLocation`, `CIImage`, `CMTime`, `AVAsset` /
`AVPlayerItem`, `URLRequest`, `AppExtension`, or Combine are omitted from this
compile. `PHLivePhotoFrame` and `PHLivePhotoFrameProcessingBlock` need
`CIImage`/`CMTime`. `PHPhotosError.invalid` has no established raw value in
the pinned bindings.

See `oracle-questions.tsv` for callback timing, TCC prompting, info-key
payloads, Recently Added membership, Live Photo editing construction, and
insert-index semantics.

## Depth pass 2026-09 (wave 8)

Second pass over the first-pass on-disk library. Did not rewrite existing
sources or tests; extended album/folder mutation, change-detail arithmetic,
fail-closed Live Photo editing / upload jobs, and progress-handler stop
flags.

| status | before | after |
| --- | ---: | ---: |
| implemented | 597 | 748 |
| declared | 142 | 2 |
| deferred | 48 | 37 |
| unavailable | 0 | 0 |
| not-applicable | 0 | 0 |

Remaining `declared` rows are Foundation `Sequence.compare` /
`Sequence.formatted` overlays on `PHPersistentChangeFetchResult` (no
established `SortComparator` / `FormatStyle` round-trip on this host).
Remaining `deferred` rows still need another module (`UTType`, `CLLocation`,
`CIImage`, `CMTime`, `AVAsset`, `URLRequest`, Combine, AppExtension) or an
unobserved `PHPhotosError.invalid` raw value.

Top-5 evidence distribution (all `implemented` rows):

1. `PhotosSurfaceTests.swift#testPhotosErrorCodeSurface` — 96
2. `PhotosSurfaceTests.swift#testAllEnumRawValues` — 77
3. `PhotosDepthTests.swift#testEnumRawValueInitsAndInequality` — 54
4. `PhotosLibraryTests.swift#testOnDiskLibraryCreateFromFile` — 52
5. `PhotosLibraryTests.swift#testPersistentChangeSequence` — 47

New non-enum rows cite focused tests in
`full/photos/tests/agent/PhotosDepthTests.swift` (membership, change details,
Live Photo editing, upload jobs, progress handlers). Enum / option-set
synthesized members share table-driven value tests as allowed.

Environment: `git rev-parse HEAD` matched
`39dc25a2769fb88a50f0853964137a4f96d50322`. `.cursor/verify-cloud-environment.sh`
fails on this snapshot (`missing corpus checkout: scratch/ladder-corpus/focus-ios`;
Cursor Build `bld-20260906-253cd433-7a30-4d11-aad2-8b209b7b2d21` vs seed
`bld-20260901-d3266600-d87b-438f-94c1-d1aa48036e87`). `swiftc` is Swift 6.2.4 /
linux and the sealed gate compiles with a clean product tree
(`CURSOR_SWIFT_ENVIRONMENT_OK swift=6.2.4 target=linux products=clean`).

Run `bash tests/acceptance/test_host.sh` from this directory. Keep generated
products out of the tree.
