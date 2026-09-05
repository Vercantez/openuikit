# Photos on-disk library (`agent/fw-photos`)

SDK depth for `full/photos/` (787 public IDs). Before this branch: **161
implemented / 578 declared / 48 deferred**. After: **597 implemented /
142 declared / 48 deferred**.

## What was measured

Isolated Linux host compile of `libPhotos.dylib` (`swift:6.2-noble`,
`-warnings-as-errors`) plus the 32 coverage-cited agent tests. Stdout was
only `PHOTOS_AGENT_RUNTIME_OK`. Darwin `swiftc` of the same tests also prints
that marker. Linux `swift:6.2-noble` `openrender` release build completed
in 184.20s (no uikit render rule in this branch).

`bash tests/acceptance/test_host.sh` still refuses before compile: the
immutable Photos seed `generatorSHA256` is
`e44f6bde16e79ca2275fd7b518384d4c2b860d3e5b9293e68770a53eb118923c` while
today's `scripts/framework-fanout/generate_seed_v2.py` is
`e56ee6e70b5464f6e1d76679652d670222bf6200daf198d2f4c6aea67d7421e6`. That
mismatch is pre-existing on this pin (same as other e44-seeded
frameworks). The seed and the generator are outside this branch's edit
set.

- Embedded 1×1 sRGB PNG: IHDR bytes 16..<24 are width **1**, height **1**.
  `creationRequestForAssetFromImage(atFileURL:)` of that file yields
  `pixelWidth == 1`, `pixelHeight == 1`, and
  `requestImageDataAndOrientation` returns the same bytes.
- Missing file `/tmp/missing.jpg` still returns `nil` from
  `creationRequestForAssetFromImage(atFileURL:)` (existing test).
- Unauthorized `performChangesAndWait` throws
  `PHPhotosError.accessUserDenied` (status `.notDetermined`). With the
  documented `_installAuthorizationHandler` hook returning `.authorized`,
  creates/deletes persist under `Documents/OpenUIKitPhotoLibrary`.
- `requestAuthorization(for:handler:)` delivers on serial queue
  `org.openuikit.Photos.host-callback`. A second request after
  `.authorized` short-circuits to `.authorized`.
- Favorites smart album count is **1** after `PHAssetChangeRequest.isFavorite
  = true`. Recents (`smartAlbumUserLibrary`) contains host-installed and
  created user-library assets. **21** documented smart-album subtypes are
  returned for `fetchAssetCollections(with: .smartAlbum, subtype: .any)`.
- `PHFetchResultChangeDetails` for a fetch taken before one insert has
  `insertedObjects.count == 1` and `hasIncrementalChanges == true`.
- Equality of `PHObject` / `PHFetchResult.contains` is by
  `localIdentifier` (disk reload is a new instance).

## Rule

Real on-disk library under the documents directory; fail-closed where the
system library is meant (no TCC, no ImageIO on the isolated host, Live
Photo nil + error). iOS-cut rendering is untouched.

## Open

- Darwin `performChangesAndWait` error for unauthorized callers.
- Runtime CFString values of `PHImage*Key`.
- Recently Added / Selfies / Long Exposure / RAW membership.
- `PHAsset.location` stays deferred (`CLLocation` is not a Photos
  dependency).
