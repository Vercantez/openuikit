# SwiftUI S1: Focus static widget

OpenUIKit now exports a package product and public module literally named
`SwiftUI`.  The S1 surface is the exact stateless composition vocabulary used
by the pinned Focus files `Widget/Assets.swift` and
`Widget/SearchWidgetView.swift`.

The application sources are not patched, rewritten, or overlaid.  The proof
script copies the two files byte-for-byte into a temporary SwiftPM target and
lets SwiftPM generate the ordinary `Bundle.module` resource accessor.  Their
pinned SHA-256 values are:

- `Assets.swift`: `efac8d1c98b562374e54eea7540b4201523db670a6353eff8f0a0273d294526e`
- `SearchWidgetView.swift`: `721669388a4556e1609f580ed87d6065b63981770e71b0f77db292767b05f6c2`

Run the proof with:

```sh
scripts/prove_focus_widget_swiftui.sh \
  /path/to/focus-ios/focus-ios/BlockzillaPackage
```

## What renders

`UIHostingController` evaluates an app-defined `View.body` into an internal
node tree, then lays it out as real OpenUIKit views.  The implemented static
path includes:

- `VStack`, `HStack`, `Spacer`, `Text`, and `Image`;
- `ViewBuilder` blocks with zero through three children, optionals,
  conditionals, and arrays;
- `Font.headline`, medium weight, minimum scale factor, and foreground color;
- fixed frames, edge padding, optional backgrounds, preview-layout syntax,
  and rounded clipping;
- named colors, named loose raster images, the `magnifyingglass` system
  symbol, and axial `LinearGradient` backgrounds; and
- root-view replacement on an existing `UIHostingController`.

Named colors and images delegate to OpenUIKit's existing bundle lookup.  That
means normalized loose resources work; Apple's compiled `Assets.car` format
is not being claimed.  The focused tests validate the generated OpenUIKit
hierarchy and frames, named-image loading, root mutation, clipping, and two
byte-identical renders of the same 135-by-135 widget.

The implementation nominals use `_Open...` ABI names with public SwiftUI
typealiases.  This preserves source spellings while avoiding collisions with
new Apple SDKs whose `SwiftUICore` declarations are annotated as historically
defined in the `SwiftUI` ABI namespace.  It has no effect on unchanged client
source: `import SwiftUI`, `View`, `Text`, and `UIHostingController` retain
their original spellings.

## Boundaries

S1 does not implement SwiftUI state or bindings, controls, lists, navigation,
environment/property wrappers, animations, arbitrary shapes, general SF
Symbols, preview tooling, or the full SwiftUI layout algorithm.  The preview
modifier is compile-compatible metadata; it does not launch an Xcode preview.
Only `magnifyingglass` has a portable system-symbol drawing today.

The current exact-source proof emits a host module.  The renderer tests execute
on the development host against OpenUIKit.  Neither result alone proves a
linked Focus application or a SwiftUI Mach-O guest running on Linux; those are
separate integration gates.

The SwiftUI implementation imports Foundation only when it is available and
otherwise uses OpenUIKit's portable geometry, `Bundle`, and `NSCoder`
identities.  This keeps the module eligible for the Foundation-hidden Mach-O
guest graph; the separate guest integration gate must still prove that path.
