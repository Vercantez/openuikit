# SwiftUI app lifecycle

OpenUIKit's literal `SwiftUI` module owns the application entry surface used
by modern, untouched iOS applications:

- `App`, including the default `static main()` inherited by an `@main struct`;
- `Scene` and `SceneBuilder`, including conditionals, loops, and multiple
  scenes;
- `WindowGroup`, with both untitled and titled initializers; and
- `UIApplicationDelegateAdaptor` for an `NSObject`-backed
  `UIApplicationDelegate`.

These are runtime APIs, not declarations that merely satisfy the compiler.
The default `App.main()` creates the app value (and therefore its delegate
adaptor), launches `UIApplication.shared`, evaluates the scene tree, and
connects one real `UIWindowScene` per `WindowGroup`. Each scene owns a real
`UIWindow`; its root is a `UIHostingController` that evaluates and lays out the
existing OpenSwiftUI view graph. The windows are made visible, receive an
appearance transition, and the application and scenes enter the active state.
The returned framework-internal session retains the app value, adaptor,
scenes, delegates, windows, and hosting controllers for process lifetime.

Before constructing application code, the production default main also calls
`OpenUIKitRuntime.configureApplicationBundleResources(at:)`. That method
validates the packaged color table, font metrics, and fonts, binds image and
font lookup to the relocatable `.app` resource directory, probes the once-only
font table after the binding, and clears the named-image cache. It fails closed
if a required resource is absent.

The portable Xcode-project planner must treat this lifecycle differently from
UIKit's generated scene bootstrap. A top-level `@main struct` directly
conforming to `App` already has a main witness, so tooling records and verifies
that source but emits no competing `static main()`. UIKit delegate applications
continue to use the generated scene bootstrap and external paced host loop.

## Verification

`SwiftUIAppLifecycleTests` verifies the inherited main witness, conditional and
array scene construction, delegate launch callbacks, multi-window scene
connection, activation, visibility, and concrete hosted text hierarchies. Run
the Apple source-shape oracle with:

```sh
scripts/swiftui_app_lifecycle_oracle.sh
```

The oracle typechecks the same `@main App`, delegate adaptor, and two-window
composition against the pinned iOS 26 simulator SDK. It does not enter the
application runtime.

Current deliberate boundary: `WindowGroup` creates an independent window for
each declaration, but restoration, document groups, menu commands, and scene
phase/environment propagation are later lifecycle slices.
