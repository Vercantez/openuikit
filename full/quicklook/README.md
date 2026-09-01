# Portable QuickLook

This directory owns the portable `QuickLook` framework and its
`_QuickLook_SwiftUI` cross-import overlay. The base framework implements the
Apple-shaped preview item, data source, delegate, controller, and AR item
surface. On OpenUIKit it renders local PNG/JPEG files and a truthful metadata
fallback, while unsupported proprietary preview generators and editing remain
disabled.

The overlay implements both `quickLookPreview` overloads. It synchronizes the
selection binding, validates collection membership, presents through the local
controller when a key-window presenter exists, and otherwise fails closed.
Hosts may replace presentation through the `OpenUIKitHost` SPI. No app,
package, or vendor source is patched.
