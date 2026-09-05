# Portable QuickLook

This directory owns the portable `QuickLook` framework and its
`_QuickLook_SwiftUI` cross-import overlay.

The Linux host module (`quicklook_guest_sources.txt`) compiles with Foundation
only. It implements the Apple-shaped preview item, editing-mode enum, AR item,
preview controller data source/delegate (including transition frame/image/view
defaults), file-preview request, file-URL and generator replies, scene-activation
configuration, and the previewing controller contract as fail-closed
`CocoaError.featureUnsupported` defaults.

`QLPreviewController.canPreview(_:)` accepts an existing file URL whose type
matches the documented Quick Look list: images, PDF, `public.text` (including
RTF/HTML/CSV), audiovisual content, ZIP, USDZ, plus Office/iWork filename
extras that the current UniformTypeIdentifiers port does not register. Unknown
types and missing paths fail closed.

On OpenUIKit, `QLPreviewController` remains a `UIViewController` that sets
`navigationItem.title` from `previewItemTitle` (falling back to the last path
component) and renders local images via `UIImage`, PDF via PDFKit when that
module is importable, and text via `UITextView`. Other types show a metadata
fallback. Proprietary preview generators and editing stay disabled. Hosts may
replace presentation through the `OpenUIKitHost` SPI.

SwiftUI `quickLookPreview` overloads are declared behind `canImport(SwiftUI)`
and live in the overlay guest as well. The Foundation host gate does not compile
SwiftUI.

No app, package, or vendor source is patched.

## Depth pass 2026-09

SDK depth for the 63 precise IDs: 61 implemented, 2 declared, 0 deferred.

Implemented this pass:

- `QLPreviewController` data source (`numberOfPreviewItems` /
  `previewItem(at:)`), `currentPreviewItemIndex` / `currentPreviewItem`,
  `reloadData` / `refreshCurrentPreviewItem`.
- Delegate: `previewController(_:frameFor:inSourceView:)` (Linux
  `UnsafeMutablePointer<UIView?>`, default `.zero`),
  `transitionImageFor` (default `nil`, writes `.zero` into `contentRect`),
  `transitionViewFor` (default `nil`), `shouldOpen`, `editingModeFor`
  (`.disabled`), `didUpdateContentsOf`, `didSaveEditedCopyOf`.
- `canPreview(_:)` by UTType from the port's UniformTypeIdentifiers identifiers
  (host stand-in when that module is absent): images, PDF, text, CSV, ZIP,
  USDZ, audiovisual, plus documented Office/iWork extras.
- Presentation: UIKit guest is a `UIViewController` with the item title on
  `navigationItem` and content via `UIImage` / PDFKit / `UITextView` where
  those modules are available. SPI `_previewTitle` / `_previewKind` are tested
  on the Foundation host.
- `QLPreviewItem` (`previewItemURL` / `previewItemTitle`) with `NSURL`
  conformance; `QLPreviewItemEditingMode`.
- `QLPreviewingController` / `QLPreviewProvider`:
  `preparePreviewOfFile` / `preparePreviewOfSearchableItem` / `providePreview`
  fail closed with `CocoaError.featureUnsupported`.
- `QLPreviewReply` / `QLFilePreviewRequest` / `QLPreviewReplyAttachment`
  (`init(data:contentType:)`). Generator reply initializers store arguments and
  do not invoke drawing/data/PDF closures.

Fail-closed boundaries:

- No Quick Look daemon, generator, or Spotlight preview pipeline.
- Generator closures are stored, never called.
- Unknown UTIs and missing files: `canPreview` is false.
- Editing stays disabled.

SE 2x chrome measurement: **listed gap**. This worktree has no
`QLPreviewController` probe scene in UIKit's conformance/oracle flow
(`uikit/scripts/conformance_flow.sh` and Present/scene apps do not present
Quick Look). No layout dump was taken. Linux therefore does not claim nav-bar
height, title font, close-control metrics, or content insets. `navigationItem.title`
and `view.bounds` filling are the portable starting point.

Unresolved behavioral questions remain in `oracle-questions.tsv` (Apple
`canPreview` generator coverage, unimplemented-delegate `shouldOpen` default,
reply title/encoding defaults, `providePreview` queue and NSError payload,
SwiftUI presentation timing, scene activation, reload retention, and SE 2x
chrome).
