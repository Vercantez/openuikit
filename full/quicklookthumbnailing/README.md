# QuickLookThumbnailing (Linux starting point)

This directory is a clean-room Linux starting point for Apple's public
`QuickLookThumbnailing` module, seeded from the Xcode 26.1 iPhoneOS 26.1
symbol graph, API digester, and TBD exports. It is not wired into the shared
guest package; that integration is a later central-review step.

## What is real

- `QLThumbnailErrorDomain` is the string `QLThumbnailErrorDomain`, matching
  the pinned `dotnet/macios` `[ErrorDomain]` annotation and Apple NSError logs.
- `QLThumbnailError.Code` raw values are `generationFailed = 0` through
  `requestCancelled = 5`.
- `QLThumbnailGenerator.Request.RepresentationTypes` is an `OptionSet` with
  `icon = 1 << 0`, `lowQualityThumbnail = 1 << 1`, `thumbnail = 1 << 2`, and
  `all = UInt.max`.
- `QLThumbnailRepresentation.RepresentationType` is `icon = 0`,
  `lowQualityThumbnail = 1`, `thumbnail = 2`.
- `QLThumbnailGenerator.Request` stores the caller-supplied file URL, size,
  scale, and representation types. `iconMode` and `minimumDimension` are
  mutable stored properties.
- `QLThumbnailReply` can be constructed from an image file URL or a
  current-context drawing block. `extensionBadge` is get/set.
- `QLFileThumbnailRequest` exposes the documented stored properties through a
  Linux designated initializer (Apple does not publish one).
- Focused tests exercise error identity, option-set algebra, request storage,
  fail-closed generate/save/cancel, and provider/reply construction.

`CGSize` / `CGFloat` / `CGRect` values are Foundation's Linux geometry types.
On a later EC2 integration build they are the real CoreGraphics types.

## Fail-closed boundaries

Linux has no Quick Look daemon, thumbnail cache, or iCloud thumbnail pipeline.
The implementation never fabricates a `QLThumbnailRepresentation` and never
writes a destination image file.

- `generateBestRepresentation` throws / callbacks `QLThumbnailError.generationFailed`.
- `generateRepresentations` invokes the optional update handler once with a nil
  representation and `generationFailed` (or `requestCancelled` after `cancel`).
- `saveBestRepresentation(for:to:contentType:)` throws the same errors and
  does not create the destination URL.
- `QLThumbnailProvider.provideThumbnail` reports `generationFailed`.
- `Request.init(coder:)` returns `nil`; encoding writes no archive.
- Current-context drawing blocks are stored and never invoked.

## Deferred

These signatures require dependency-owned types that the isolated host compile
does not provide, and substituting a local lookalike is forbidden:

- `Request.contentType: UTType!`
- `saveBestRepresentation(for:to:as:)` taking `UTType`
- `QLThumbnailReply` drawing initializers taking `CGContext`
- `QLThumbnailRepresentation.cgImage` / `uiImage`

`QLThumbnailRepresentation.type` and `contentRect` are declared but not
constructible from public API because generation never succeeds.

TBD-only Swift overlays (`ThumbnailProvider`, `ThumbnailExtension`,
`ThumbnailRequest`) and private ObjC cache/service classes are out of the
exact public-ID census and are not implemented here.
