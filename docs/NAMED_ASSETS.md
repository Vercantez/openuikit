# Named bundle assets

OpenUIKit exposes the UIKit source spellings

```swift
UIImage(named: name, in: bundle, compatibleWith: traits)
UIColor(named: name, in: bundle, compatibleWith: traits)
```

without claiming Apple's private asset-catalog runtime.

## Supported subset

- `UIImage` searches the selected bundle's resource root for loose PNG/JPEG
  files. It honors `@2x`/`@3x` suffixes and uses
  `traitCollection.displayScale` to choose the preferred scale.
- `UIColor` reads raw, uncompiled `<name>.colorset/Contents.json` files at the
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

OpenUIKit does not currently decode compiled `Assets.car` files. Named images
also do not decode vector PDF or SVG files and do not select appearance, idiom,
gamut, localization, or rendering-intent variants. Named colors reject
Display-P3 data instead of treating it as sRGB; high-contrast, idiom, and gamut
variants are not selected. The catalog search is intentionally bounded to the
four layouts above rather than recursively walking arbitrary bundle contents.

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

Its `Assets.xcassets` image members do **not** fit the image subset: at the
pinned revision the 24 names force-unwrapped by `UIImage+AppImages.swift` map to
image sets whose 44 payload files are PDF (42) or SVG (2). Adding the overload
removes the source/type-check boundary, but those force unwraps will still fail
at runtime until the build pipeline rasterizes the vector catalog members or
OpenUIKit gains a vector/compiled-catalog decoder. A green DesignSystem module
therefore is not evidence that Focus's images can render yet.
