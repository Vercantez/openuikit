# Focus package Mach-O guest proof

This successor extends the accepted Focus SwiftUI onboarding guest from its
12-file runtime slice to a measured cross-target SwiftPM package graph. It
emits real arm64 Mach-O objects and dylibs from the unchanged source counts
listed below:

| Target | Revision | Upstream Swift files | Compiled |
| --- | --- | ---: | ---: |
| OpenUIKit | `8f98af2e53af566923de6616f3629bec0661aa8c` | 101 | 101 |
| SnapKit | `e74fe2a978d1216c3602b129447c7301573cc2d8` | 37 | 36 |
| Focus DesignSystem | `a2832521c1daa0c23419c73705ae043ed60c9791` | 7 | 7 |
| Focus Widget | same Focus revision | 2 | 2 |
| Focus Onboarding | same Focus revision | 21 | 21 |
| Focus Licenses | same Focus revision | 2 | 2 |

The OpenUIKit commit above has exact tree
`a8b809d35b52ef317517914922392f395a8da59c`; all three Focus guest scripts
require that clean commit/tree before and after their gates.

The shared substrate remains pinned to swift-foundation
`c6793ef0c19c2cbaeba5a0e52078f129afc7dcfc`, swift-collections
`9bf03ff58ce34478e66aaee630e491823326fd06`, and OpenCombine
`1c6f02c7ed8140c0ba7a783aaddb6e0685a0037b`. Their existing fail-closed
commit, Git-tree, selected-input, and artifact attestations run before the
package targets are compiled.

The build discovers each source set directly in its clean pinned checkout,
sorts the exact paths, writes `path<TAB>sha256` manifests, and requires both
the reviewed count and whole-manifest digest before and after compilation and
execution. It never copies, patches, overlays, conditionally rewrites, or
generates application/dependency source. Project-owned Swift files provide the
guest harness and explicit resource-build support; they are compiled alongside
the unchanged source sets and are separately identified and hashed.

SnapKit's sole exclusion is the exact unchanged
`Sources/Debugging.swift` (`sha256`
`6af70d54a6e6fb112d87f8adb93caead0bc2afc472e4bbb04347bf591be3b3e3`).
That file overrides an NSObject-inherited ObjC-dynamic `description` from an
extension and dynamically calls `description()` on `AnyObject.Type`. Current
OpenUIKit has neither an NSObject inheritance root nor that ObjC metatype
dispatch surface; its Swift-declared `NSLayoutConstraint.description` cannot
legally be overridden from an extension. The build requires exactly 37
upstream files, exactly this one exclusion, its exact hash and reason, and
records a separate exclusion ledger before and after the run. It does not
claim complete SnapKit source emission. `Debugging.swift` supplies diagnostic
text, while the compiled 36-file set contains the constraint/DSL behavior
exercised here.

## Foundation and provider boundary

The literal `Foundation` guest module re-exports the pinned
`FoundationEssentials` value types and the pinned literal `Combine` module.
It does not declare replacement `URL`, `Data`, `PropertyListDecoder`,
`Published`, `Bundle`, or `NSCoder` identities. `Bundle` and `NSCoder` remain
type aliases to the exact OpenUIKit identities against which OpenUIKit was
compiled. UIKit owns Bundle discovery and resource lookup; the Foundation
umbrella does not duplicate those implementations.

The one additional Foundation surface is a bounded `NSMutableSet` needed by
the compiled unchanged SnapKit sources. Hashable set values use their declared
equality and hash; non-Hashable class instances use object identity. Both are
retained by the value store, while non-Hashable value types are rejected rather
than given an invented equality rule. A Mach-O runtime probe checks identity
insertion and removal, Hashable equality, first-object retention, and the real
SnapKit associated-object constraint lifecycle.

OpenCombine stays at
`1c6f02c7ed8140c0ba7a783aaddb6e0685a0037b`; its reviewed artifacts and helper
patch are still byte-pinned by the accepted onboarding build. The complete
Onboarding target then verifies that a file importing only Foundation sees
the same `@Published` implementation as files importing Combine directly.
Both fresh guest module caches explicitly compile the SDK's textual `Swift`
module first, avoiding dependence on a leftover cache or a prior failed nested
`_Concurrency` import.

## Resource-accessor provenance

The resource graph is derived fail-closed from the exact pinned manifests, not
from the presence of a `Bundle.module` spelling. A reviewed Apple SwiftPM 6.2.1
oracle produces accessors for exactly two targets: Focus `Licenses`, named
`Focus_Licenses.bundle`, and SnapKit, named `SnapKit_SnapKit.bundle`. The exact
Focus `Package.swift` declares no resources for `DesignSystem`, `Widget`, or
`Onboarding`; SwiftPM generates no accessor for those targets and compiles them
with `SWIFT_MODULE_RESOURCE_BUNDLE_UNAVAILABLE`.

The oracle gate hash-pins Focus `Package.swift`, Focus `Package.resolved`,
SnapKit `Package.swift`, SnapKit's privacy manifest, and normalized copies of
both Apple-generated accessors. The reviewed normalization replaces the one
absolute build-directory fallback with `<BUILD_PATH>` and appends one terminal
LF for the repository text fixture; both transformations and the resulting
exact bytes are attested. It reparses every declared resource rule, requires the
generated set and availability flags above, verifies the exact SnapKit 5.7.0
revision, and scans every relevant unchanged Swift source for conditional
branches on `SWIFT_PACKAGE` or the resource-availability defines. There are no
such branches. The direct `swiftc` build therefore supplies none of those
SwiftPM-only defines rather than adding inert ambient configuration.

For Licenses and SnapKit, the portable project-owned accessors preserve the
generated primary lookup relative to `Bundle.main.bundleURL` and deliberately
omit the machine-specific build-directory fallback. The corresponding flat
bundles are staged as direct children of each main app bundle. For the three
undeclared Focus resource targets, the project-owned files are explicitly
compatibility repair for this port build, not generated or SwiftPM-equivalent
accessors: Widget and Onboarding consume reviewed normalized bundles, while
DesignSystem is compile/link-only and its `Bundle.module` traps if evaluated.
The provenance transcript is checked before and after execution and is part of
the artifact ledger.

## Runtime gates

`FocusPackageRuntimeProbe.swift` runs beneath machorun and checks:

1. main app, flat resource, and dynamically loaded framework Bundle roots;
   the provider launches through the executable's absolute staged path so
   dyld identity and filesystem reachability agree, then resolves a
   content-pinned marker beneath its `Resources` directory;
2. exact two-argument named-resource success and missing-file failure;
3. both unchanged Focus onboarding event handlers, their `@Published` route
   transitions, persistence callbacks, and duplicate suppression;
4. unchanged SnapKit creating and removing a real OpenUIKit constraint;
5. `NSMutableSet` equality, identity, and retention behavior used underneath
   that lifecycle.

The preserved onboarding proof also stages its normalized resource bundle
beside the guest executable, requires the compatibility `Bundle.module`
support to report that exact bundle/resource root, and evaluates the unchanged
`Color.actionButton` declaration through it. Its normalized Widget bundle is
likewise adjacent and explicitly asserted before the unchanged gradient/image
declarations run. The standalone Widget gate additionally mounts and renders
the exact `SearchWidgetView`, proving named-color and image I/O with pixel
checks rather than treating lazy SwiftUI values as resource reads.

DesignSystem's seven exact sources compile and link, but its separate resource
tree is not declared by the pinned manifest, staged, or claimed by this bounded
gate. Its compatibility `Bundle.module` support is a pure fail-closed trap; it
does not invent a bundle name or silently substitute `Bundle.main`. The support
bytes are recorded in the artifact ledger.

`FocusLicensesGuestMain.swift` compiles both unchanged Focus Licenses files,
stages the exact two declared plist resources inside the adjacent flat
`Focus_Licenses.bundle`, and asserts `Bundle.module` reports that exact bundle
and resource root, both named lookups, and missing-resource failure. It then
decodes through pinned FoundationEssentials, mounts the exact
`LicenseListView`, requires exactly the eight rendered navigation rows,
injects a real touch into the first row, and requires a navigation-controller
push. A separate launch removes the adjacent bundle while placing byte-exact
plist decoys loose in both the app's `Contents/Resources` and the current
directory; it must fail in the accessor without reaching the success marker.
The raw Swift crash stderr is retained for inspection but is not hashed as a
reproducible artifact because its backtrace contains ASLR-dependent addresses.
Instead, a normalized record requires the exact SIGTRAP/shell-status pair,
fatal message with a symbolic missing-app root, absent adjacent-bundle
topology, both exact loose-decoy locations, and absence of the success marker;
that stable record is what the artifact ledger hashes.

The package probe likewise stages `SnapKit_SnapKit.bundle` as a direct child of
its app, checks its exact one-file topology and privacy-manifest bytes, and
requires the generated-primary bundle/root/resource lookups plus a missing
lookup before exercising the unchanged 36-source constraint lifecycle.

Both new executables have their complete Mach-O load closures resolved and
content-hashed before execution, then resolved again afterward. Every image
must remain a regular, non-symlink file beneath the declared package or guest
root; the pre/post closure manifests must be byte-identical.

Before these new gates run, the script reruns the already accepted exact
12-source Focus onboarding interaction path. This prevents broader module
emission from replacing the existing touch, host-turn, URL-open, dismissal,
UUID, resource, and telemetry proof with a weaker compile-only claim.

## Reproduce

Both build scripts require the literal exact landed OpenUIKit commit shown
above. Environment variables cannot override this provenance boundary.

```bash
docker run --rm --platform linux/arm64 \
  -v "$PWD":/w \
  -v /path/to/exact-uikit:/uikit:ro \
  -v /path/to/machorun:/machorun:ro \
  -v "$RESOURCE_PROOF/output/bundles":/focus-resources:ro \
  -w /w swift-macho-spike:noble \
  bash full/swiftui/build_focus_package_guest.sh /focus-resources
```

The build also requires the already pinned `scratch/swift-foundation`,
`scratch/swift-collections`, OpenCombine export, Focus checkout, SnapKit
checkout, sysroot, and guest roots used by the accepted proof. Derived output
is confined to the gitignored `build` and `scratch` trees: the full substrate
and two guest output directories are rebuilt, as are the private guest roots
and Swift module caches. All pinned source checkouts are verified before and
after the run and must remain clean.

## Honesty limits

This proves the full 21-source Onboarding module emits and selected production
handler/constraint semantics execute; it does not execute every controller,
preview, tooltip, or DesignSystem asset declaration. In particular,
DesignSystem resource behavior is not claimed. The exact Licenses target does
execute its bundle lookup, plist decode, list construction, row rendering,
touch, and navigation path. This remains a bounded Focus package runtime, not
the whole Focus application, a general SwiftPM implementation, broad
Foundation API coverage, or a claim that arbitrary SwiftUI source works.
