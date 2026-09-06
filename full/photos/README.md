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

`PHPhotosErrorDomain` is `"PHPhotosErrorDomain"`. The deprecated
`PHPhotosErrorInvalid`, `PHPhotosError.invalid`, and `PHPhotosError.Code.invalid`
spellings all alias `.internalError` / -1, measured on iOS 26.1. Info-dictionary
keys are the C identifiers until an Apple oracle records payloads.

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

At the end of that pass, the remaining `declared` rows were Foundation `Sequence.compare` /
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

### Depth pass local repair 2026-09-06 (wave 18)

Branch `agent/fw-photos-r` was based on current `origin/main` at `8332a8f2`.
The requested Cursor head `042e60d1` was already merged into main by
`5f17fd1a`; merging both refs reported "Already up to date" and required no
conflict resolution. `/tmp/fw_merge_gate-photos.log` contained no `error:` or
`REFUSING` lines and ended in `FRAMEWORK_FANOUT_HOST_OK module=Photos`.
An unchanged-tree rerun in the operator's `uikit-linux` container also passed.
The earlier refusal therefore could not be reproduced from the supplied log
and current refs.

This repair closes a remaining evidence gap without changing product code:

- `PhotosFormattingTests.swift#testPersistentChangeFormattedStyle` calls the
  real Foundation `Sequence.formatted(_:)` overlay on
  `PHPersistentChangeFetchResult`. A custom `FormatStyle` reads inserted asset
  counts from actual local transactions: empty results yield `[]`, one
  transaction yields `[1]`, and two transactions yield `[1, 2]`. A supplied
  multiplier of 10 yields `[10, 20]`; repeated formatting and previously fetched
  snapshots retain their results. The test resets its own store, uses the
  synchronous authorization SPI, and cleans up with `defer`; it has no task,
  callback wait, or dependence on another test.
- `testPersistentChangeSortedUsingComparators` replaces broad sequence-test
  citations for both Foundation `sorted(using:)` overloads. It checks forward
  and reverse sorting of transaction sizes `[2, 1, 2]`, tied elements, an empty
  comparator array, and preservation of the input sequence. The prior cited
  test exercised `sorted(by:)` but did not call either `sorted(using:)` overload.
- The compiler-synthesized `Sequence.compare(_:_:)` row is `not-applicable`.
  Its sealed graph signature requires `Element: SortComparator`, whereas
  `Element` is `PHPersistentChange`. The API crosswalk records the overlay as
  unmatched, and the digester records the concrete Photos element type. An
  isolated Linux Swift 6.2.4 typecheck of `result.compare(1, 2)` rejects the call
  because `PHPersistentChange` does not conform to `SortComparator`. No
  framework-local conformance or replacement Foundation type was added.

| status | current main | local repair |
| --- | ---: | ---: |
| implemented | 748 | 749 |
| declared | 2 | 0 |
| deferred | 37 | 37 |
| unavailable | 0 | 0 |
| not-applicable | 0 | 1 |

All 748 previously implemented IDs are retained. The gain over
current main is **+1 implemented**, with 55 distinct cited synchronous,
no-argument tests (previously 53). The largest citation group remains the
96-row error-code table (12.82% of 749); the largest non-table group is the
52-row on-disk-library test (6.94%), below the 40% limit. The sole
`not-applicable` ID is explicitly `::SYNTHESIZED::`.

Validation uses the unmodified sealed acceptance script and shared validators,
copied with Photos to `/gate-codex-photos` in `uikit-linux` (Swift 6.2.4,
`aarch64-unknown-linux-gnu`). Both baseline and repaired trees end with
`PHOTOS_AGENT_RUNTIME_OK` and
`FRAMEWORK_FANOUT_HOST_OK module=Photos dylib=libPhotos.dylib`.
Both new tests also pass twice consecutively in an independent runner.
Local logs: `/tmp/fw-photos-r-baseline.log`, `/tmp/fw-photos-r-repaired.log`,
`/tmp/fw-photos-r-formatting.log`, and `/tmp/fw-photos-r-comparator.log`.

### Depth pass follow-up 2026-09-06 (wave 18, current main)

At task start, `origin/main` at `58292232` already included Cursor head `042e60d1`
and the preceding local repair `883ca742` (merged by `e73c567a`). Both requested
merges report "Already up to date"; no conflicting rows or tests were removed.
The supplied `/tmp/fw_merge_gate-photos.log` already ends in
`FRAMEWORK_FANOUT_HOST_OK module=Photos`. The refusal is not reproducible on
these refs. Before committing, the branch fast-forwarded to newer main
`c1973365`; Photos and all copied gate inputs are unchanged between these main
commits. An unchanged baseline rerun passes in the operator's `uikit-linux`
container, so this follow-up adds a measured gain over that current main.

The remaining invalid-error question is resolved by a real Apple Photos probe
on a private iPhone 17 simulator, iOS 26.1 (23B86), device name
`OpenUIKit-PhotosError-fw-photos-r`. Results:

```text
PHPhotosErrorInvalid=-1
PHPhotosError.invalid=-1
PHPhotosError.Code.invalid=-1
aliasEqual=true
roundTrip=true
```

The aliases and raw-value round trip also agree on macOS 26.5.2 (25F84).
Apple Swift 6.2.1 SDK diagnostics identify the legacy constant's iOS 14 /
macOS 11 deprecation and the two properties' iOS 15 / macOS 12 deprecation;
the port carries those platform deprecations and rename spellings.

Declaration facts: `reference/public-surface.tsv` identifies the global as
`let PHPhotosErrorInvalid: Int` (`c:@PHPhotosErrorInvalidDeprecated`) and both
properties as static `PHPhotosError.Code` getters. The sealed digester has
both deprecated static `invalid` properties, owned by Photos, with enum USR
`c:@E@PHPhotosError@PHPhotosErrorInvalid`; the Swift overlay IDs and legacy
global have unmatched exact-ID crosswalk entries. The graph establishes their
spellings and signatures; the runtime probe establishes the -1 alias value.
No new dependency, enum raw-value case, or error-domain behavior is introduced.

Each newly implemented ID cites its own synchronous no-argument function in
`tests/agent/PhotosInvalidErrorTests.swift`:

- `testInvalidErrorLegacyConstant`: global Int value -1 and raw-value lookup.
- `testInvalidErrorOverlayAlias`: outer static property, equality with
  `.internalError`, and error construction.
- `testInvalidErrorCodeAlias`: nested property, raw-value round trip, hash/set
  identity, and NSError pattern matching with a mismatched-domain control.

The exact three test functions compile against Apple Photos and pass twice on
iOS 26.1 (`PHOTOS_INVALID_ERROR_ORACLE_OK tests=3 repetitions=2`). These are
pure value tests with no store, authorization, asynchronous work, or waits.

| status | main `c1973365` | follow-up |
| --- | ---: | ---: |
| implemented | 749 | 752 |
| declared | 0 | 0 |
| deferred | 37 | 34 |
| unavailable | 0 | 0 |
| not-applicable | 1 | 1 |

The gain is **+3 implemented**; all 749 previously implemented IDs are retained.
There are 58 distinct cited tests (previously 55). The largest citation group
is still the 96-row error table (12.77%); the largest non-table group remains
52 rows (6.91%), below 40%. The sole `not-applicable` row is unchanged and
explicitly compiler-`SYNTHESIZED`.

Validation: baseline and repaired trees both pass the unmodified sealed host
gate in `/gate-codex-photos`, copied with the current shared validators, on
`uikit-linux` (Swift 6.2.4, `aarch64-unknown-linux-gnu`). The gate compiles product
and test sources with warnings as errors, loads `libPhotos.dylib`, and ends
with `PHOTOS_AGENT_RUNTIME_OK` and `FRAMEWORK_FANOUT_HOST_OK module=Photos`.
A separate runner invokes each of all 58 cited tests in its own process, twice
consecutively, with a 20-second process timeout; all 116 invocations pass.
Existing asynchronous-API tests expose synchronous test entry points and use
bounded waits; none hangs. No sealed inputs, acceptance scripts, shared files,
or vendor pins changed. All branch changes stay under `full/photos/`.

Local evidence logs: `/tmp/fw-photos-r-baseline-current.log`,
`/tmp/fw-photos-r-invalid-ios.log`, `/tmp/fw-photos-r-invalid-tests-ios.log`,
`/tmp/fw-photos-r-invalid-gate.log`, `/tmp/fw-photos-r-final-gate.log`, and
`/tmp/fw-photos-r-independent.log`.
The temporary oracle is `/tmp/fw-photos-r-invalid-oracle.swift`; the committed
three-test source above is the reproducible behavioral oracle fixture.
