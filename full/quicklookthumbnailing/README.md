# QuickLookThumbnailing (Linux starting point)

This directory is a clean-room Linux starting point for Apple's public
`QuickLookThumbnailing` module, seeded from the Xcode 26.1 iPhoneOS 26.1
symbol graph, API digester, and TBD exports. It is not wired into the shared
guest package; that integration is a later central-review step.

## What is real

- `QLThumbnailErrorDomain` is the string `QLThumbnailErrorDomain`, matching
  the pinned `dotnet/macios` `[ErrorDomain]` annotation and Apple NSError logs.
- `QLThumbnailError` is a `@frozen` `Foundation._BridgedStoredNSError` wrapper
  around a stored `NSError`. `QLThumbnailError.Code` conforms to
  `Foundation._ErrorCodeProtocol` with `_ErrorType = QLThumbnailError`. Raw
  values are `generationFailed = 0` through `requestCancelled = 5`.
- `QLThumbnailGenerator.Request.RepresentationTypes` is an `OptionSet` with
  `icon = 1 << 0`, `lowQualityThumbnail = 1 << 1`, `thumbnail = 1 << 2`, and
  `all = UInt.max`.
- `QLThumbnailRepresentation.RepresentationType` is `icon = 0`,
  `lowQualityThumbnail = 1`, `thumbnail = 2`.
- `QLThumbnailGenerator.Request` is a public typealias of the top-level
  `QLThumbnailGenerationRequest` class so Linux `NSKeyedArchiver` can name a
  non-nested type (`NSStringFromClass` traps on nested classes). The explicit
  `@objc(QLThumbnailGenerationRequest)` name is applied only when
  `canImport(ObjectiveC)`. `NSSecureCoding` round-trips overlay fields
  (file URL, size, scale, representation flags, iconMode, minimumDimension)
  and rejects malformed payloads. `contentType` is not archived.
- `QLThumbnailRepresentation.init()` is public. iOS 26.1 observed
  `type == .icon` and `contentRect == .zero` for that initializer.
- `QLFileThumbnailRequest.init()` is the inherited public initializer iOS
  accepts. Properties are fail-closed placeholders until an extension host
  exists. The graph-absent `init(fileURL:maximumSize:minimumSize:scale:)` is
  not public; tests that need populated values use an internal SPI fixture.
- `QLThumbnailReply` can be constructed from an image file URL or a
  current-context drawing block. `extensionBadge` is get/set.
- Generator completion/update APIs return before their callbacks run. Linux
  delivers those callbacks asynchronously, exactly once, on the documented
  serial queue `com.apple.quicklookthumbnailing.QLThumbnailGenerator.callback`.
- `cancel(_:)` before generation is a no-op. Only in-flight operations owned
  by that generator for that request instance can become `requestCancelled`.
  Terminal delivery removes operation state.

`CGSize` / `CGFloat` / `CGRect` values are Foundation's Linux geometry types.
On a later EC2 integration build they are the real CoreGraphics types.

## Fail-closed boundaries

Linux has no Quick Look daemon, thumbnail cache, or iCloud thumbnail pipeline.
The implementation never fabricates thumbnail pixels and never writes a
destination image file.

- `generateBestRepresentation` throws / callbacks `QLThumbnailError.generationFailed`
  unless this generator cancelled the matching in-flight operation.
- `generateRepresentations` invokes the optional update handler once after
  return with a nil representation, the highest requested type, and
  `generationFailed` (or `requestCancelled` for an in-flight cancel).
- `saveBestRepresentation(for:to:contentType:)` throws the same errors and
  does not create the destination URL.
- `QLThumbnailProvider.provideThumbnail` reports `generationFailed`
  synchronously. That timing was not measured on iOS 26.1 (only generator
  completion APIs were); do not treat it as Apple's provider contract.
- `Request.init(coder:)` returns `nil` for missing keys, non-file URLs,
  non-finite geometry, or an unknown archive version; encoding writes the
  overlay keyed archive rather than an empty payload.
- Current-context drawing blocks are stored and never invoked.

## Deferred

These signatures require dependency-owned types that the isolated host compile
does not provide, and substituting a local lookalike is forbidden:

- `Request.contentType: UTType!`
- `saveBestRepresentation(for:to:as:)` taking `UTType`
- `QLThumbnailReply` drawing initializers taking `CGContext`
- `QLThumbnailRepresentation.cgImage` / `uiImage`

When those modules can be imported, the overlay declares the canonical
signatures. `cgImage` / `uiImage` still cannot return real pixels without a
thumbnail backend; the identity probe emits UNAVAILABLE rather than a false
success. `CoreTransferable` and `ExtensionFoundation` are imported for the
seeded dependency list but do not participate in any exposed QuickLookThumbnailing
type.

TBD-only Swift overlays (`ThumbnailProvider`, `ThumbnailExtension`,
`ThumbnailRequest`) and private ObjC cache/service classes are out of the
exact public-ID census and are not implemented here.
