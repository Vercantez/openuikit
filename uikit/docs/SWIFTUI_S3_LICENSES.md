# SwiftUI S3: Focus Licenses

S3 compiles and runs Mozilla Focus's complete `Licenses` SwiftPM target at
revision `a2832521c1daa0c23419c73705ae043ed60c9791`. Both Swift files and both
plist resources remain byte-for-byte unchanged. The only third source in the
target compiler manifest is SwiftPM's generated `Bundle.module` resource
accessor; the runtime probe is a separate executable target.

The added compatibility surface is deliberately bounded to the exact target:

- `List` expands its result-builder/`ForEach` content in stable source order
  into a vertically scrolling OpenUIKit surface with 44-point minimum rows.
- `NavigationLink` owns a full-row `UIControl`, renders a disclosure marker,
  and creates a fresh `UIHostingController` for the destination on every tap.
- a link resolves the enclosing UIKit responder/controller chain and pushes
  through its `UINavigationController`; using it outside a navigation
  controller fails loudly instead of pretending navigation occurred.
- `navigationBarTitle(_:)` is the compatibility spelling of
  `navigationTitle(_:)`. Root navigation metadata configures the hosting
  controller's real `title`/`navigationItem`; the Focus destination therefore
  drives OpenUIKit's real navigation bar. Removing SwiftUI metadata clears
  values still owned by SwiftUI without erasing a title or back-button state
  that the embedding UIKit controller replaced.

`Tests/SwiftUITests/SwiftUILicensesTests.swift` checks list ordering and scroll
geometry, title propagation, disclosure rendering, and a real `UIWindow`
touch sequence that pushes and lays out the titled, scrollable destination.
It also exercises navigation-metadata ownership across root-view rebuilds.

Run the exact-source gate with:

```sh
scripts/prove_focus_licenses_swiftui.sh /path/to/focus-ios/BlockzillaPackage
```

On macOS the gate emits and executes the exact target locally, then repeats it
inside stock `swift:6.2-noble`. It checks the Focus commit and clean status,
the complete input inventory and SHA-256 values, copied bytes after the build,
the exact compiler source manifest, resource-accessor provenance, release
module emission with warnings as errors, and decoding/layout of all eight
license rows. Neither run writes to the Focus checkout.

This is not a claim of general SwiftUI list/navigation compatibility. S3 has
no list styles, selection/editing, lazy or bidirectional collection layout,
navigation paths, split views, search, swipe actions, accessibility synthesis,
or SwiftUI transition coordination. These APIs should continue to be added
only against exact application demand and native behavior probes.
