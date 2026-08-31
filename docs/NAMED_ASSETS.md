# Named bundle assets

OpenUIKit exposes the UIKit source spellings

```swift
UIImage(named: name, in: bundle, compatibleWith: traits)
UIColor(named: name, in: bundle, compatibleWith: traits)
```

without depending on Apple's private asset-catalog runtime.

## Supported subset

- A Linux application packager may materialize source `.xcassets` as
  `OpenUIKit/AssetCatalogs/index.json` plus content-addressed resources. Named
  images resolve indexed PNG/JPG/JPEG image sets by exact idiom then
  `universal`, exact appearance then `any`, and exact scale then largest below,
  smallest above, and finally scaleless. Template/original rendering intent is
  retained. `OpenUIKitRuntime.assetCatalogIdiom` defaults to `.phone` and is
  host-configurable without an actor hop through `UIDevice.current`.
- Indexed colors preserve light/dark behavior. sRGB and extended-sRGB use
  native components, Display-P3 uses the indexer's measured sRGB conversion,
  and gray-gamma-22 replicates native white into RGB. Explicit iOS platform
  entries beat unqualified entries; other platforms are refused.
- Only when a name is absent from every valid index does `UIImage` search for
  loose PNG/JPEG files, honoring `@2x`/`@3x`, or `UIColor` read a raw,
  uncompiled `<name>.colorset/Contents.json` file at the
  resource root or inside `Colors.xcassets`, `Assets.xcassets`, or
  `Media.xcassets`. Universal sRGB components may be decimal strings, JSON
  numbers, or Xcode's `0xNN` strings. Default and luminosity light/dark entries
  produce a dynamic color.
- An explicit bundle is isolated. A miss does not fall through to another
  bundle or to `OpenUIKitRuntime.imageSearchPaths`. Relative subdirectory names
  are allowed, but absolute paths and empty, `.` or `..` path components are
  rejected.
- When OpenUIKit is compiled with Foundation hidden, its Bundle stand-in has
  no filesystem metadata. Both overloads then search the host-supplied
  `OpenUIKitRuntime.imageSearchPaths` roots instead.

## Deliberate limitations

OpenUIKit does not decode compiled `Assets.car`, vector PDF/SVG, app-icon,
symbol, or data-set payloads. Indexed image resizing, screen-width,
language-direction, and height-class qualifiers remain fail-closed until their
runtime semantics exist. System-color references, tinted-only colors, malformed
indexes, missing/mismatched payloads, and unsafe paths return `nil`; they never
silently pick a loose or raw resource with the same name. High-contrast,
localization, and display-gamut selection are not modeled. Legacy raw-catalog
search is intentionally bounded to the four layouts above rather than
recursively walking arbitrary bundle contents.

These limitations are observable: unsupported or missing resources make the
failable initializer return `nil`.

## Pinned Focus boundary

The pinned Focus `DesignSystem` source uses exactly these overloads. Its raw
`Colors.xcassets` has 39 color sets: all entries are universal sRGB strings and
16 sets add a luminosity-dark entry. They fit the supported color subset if the
Linux build copies that directory uncompiled into the generated resource
bundle.

The pinned `Package.swift` does not declare either DesignSystem catalog as a
resource. Vanilla SwiftPM therefore neither synthesizes `Bundle.module` nor
copies the catalogs. A Linux Xcode-project builder must add those pinned
resource inputs explicitly; this API does not manufacture a resource bundle.

Its `Assets.xcassets` image members still do **not** fit the runtime subset: at
the pinned revision the 24 names force-unwrapped by `UIImage+AppImages.swift`
map to image sets whose 44 payload files are PDF (42) or SVG (2). Those force
unwraps fail until the build pipeline rasterizes vector members or OpenUIKit
gains a vector decoder. A green DesignSystem module therefore is not evidence
that Focus's images can render yet.
