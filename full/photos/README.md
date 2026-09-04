# Photos

Linux starting point for Apple's public `Photos` module, reconstructed from
the pinned Xcode 26.1 iPhoneOS symbol graph, API digester, and the existing
portable host runtime. This directory is not wired into the shared guest
package. A passing isolated host gate is not integrated Linux success.

## What is real

The public Swift surface compiles to `libPhotos.dylib` with Foundation only.

The original portable runtime is preserved:

- `PHPhotoLibrary.authorizationStatus(for:)` starts `.notDetermined` and
  fail-closes `requestAuthorization(for:)` to `.denied` unless a host SPI
  handler is installed.
- `PHAsset.fetchAssets(with:options:)` returns host-installed assets only when
  status is `.authorized` or `.limited`. Fetch limit is applied. Darwin still
  honors `NSSortDescriptor(key: "creationDate")`; Linux uses
  `@_spi(OpenUIKitHost) hostSortsByCreationDateAscending` because KVC
  `NSSortDescriptor.key` is unavailable in swift-corelibs-foundation.
- `PHImageManager` returns the host-installed `Data` / `UIImage` immediately
  and issues monotonic request IDs. This is the existing Ice Cubes consumer
  contract, not Apple PhotoKit callback timing.

Also compiling on Linux:

- Enums and option sets with macios-corroborated raw values
  (`PHAuthorizationStatus`, `PHAccessLevel`, collection/resource types,
  `PHPhotosError.Code`, and the rest of the declared integer surface).
- In-memory collections, placeholders, change-request objects, adjustment
  data, editing input/output shells, live-photo request options, caching
  manager no-ops, cloud-identifier fail-closed maps, and an empty
  `PHPersistentChangeFetchResult` sequence.

`PHPhotosErrorDomain` is `"PHPhotosErrorDomain"`, matching the pinned
dotnet/macios `[ErrorDomain]`. Info-dictionary keys are declared as their C
identifiers until an Apple oracle records payloads.

## Fail-closed boundaries

Linux has no `photolibraryd`, TCC prompt, iCloud Photos, or UIKit image
pipeline.

- Unauthorized fetches are empty.
- `performChanges` / `performChangesAndWait` throw `PHPhotosError.changeNotSupported`.
- Cloud identifier maps return `.identifierNotFound`.
- Persistent-change fetch throws `.persistentChangeDetailsUnavailable`.
- Resource data completion reports `.missingResource`.
- Live Photo request handlers return `nil` plus `PHImageErrorKey`.
- Change observers can be registered; the library never posts Apple changes.

On Darwin, `UIImage` and `CGImagePropertyOrientation` come from UIKit/ImageIO.
On the isolated Linux host those names are module-local lookalikes so the
existing `requestImage` / `requestImageDataAndOrientation` signatures still
compile. They are not UIKit or ImageIO identity. Real dependency identity is
the future EC2 probe in `tests/agent/PhotosDependencyIdentity.swift`.

## Still deferred

Members that require `UTType`, `CLLocation`, `CIImage`, `CMTime`, `AVAsset` /
`AVPlayerItem`, `URLRequest`, `NSFastEnumeration`, `AppExtension`, or Combine
are omitted from this compile. `PHPhotosError.invalid` has no established raw
value in the pinned bindings.

See `oracle-questions.tsv` for callback timing, TCC prompting, info-key
payloads, and Darwin `performChanges` error mapping.

Run `bash tests/acceptance/test_host.sh` from this directory. Keep generated
products out of the tree.
