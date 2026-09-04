# Portable QuickLook

This directory owns the portable `QuickLook` framework and its
`_QuickLook_SwiftUI` cross-import overlay.

The Linux host module (`quicklook_guest_sources.txt`) compiles with Foundation
only. It implements the Apple-shaped preview item, editing-mode enum, AR item,
preview controller data source/delegate (Foundation methods), file-preview
request, file-URL reply, scene-activation configuration, and the previewing
controller contract as fail-closed throwing defaults.

On OpenUIKit, `QLPreviewController` remains a `UIViewController` that renders
local PNG/JPEG files and a truthful metadata fallback. Proprietary preview
generators and editing stay disabled. Hosts may replace presentation through
the `OpenUIKitHost` SPI.

Still deferred on the isolated host: SwiftUI `quickLookPreview` overloads (the
overlay is a separate guest and imports SwiftUI), UIKit transition
frame/image/view delegate methods, UniformTypeIdentifiers-typed attachment
API, and CoreGraphics/PDFKit reply initializers. Those types are not declared
host dependencies, and this lane does not publish public lookalikes for them.

No app, package, or vendor source is patched.
