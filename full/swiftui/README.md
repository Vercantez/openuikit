# Focus SwiftUI source contract and executable guest slices

An OpenUIKit-backed module named exactly `SwiftUI` now compiles, mounts, and
renders Focus code as arm64 Mach-O executables under Linux machorun. The first
proof covers the two-file `Widget` package and deterministic pixels. A second
proof executes the shipping two-page onboarding graph from ten unchanged
Onboarding files plus those two Widget files, including observed-object
invalidation on a host turn, three real touches, URL opening, dismissal,
telemetry order, and the first bounded Foundation umbrella/UUID behavior.

These are deliberately bounded execution slices. The emitted
`SwiftUI.swiftmodule` and `libSwiftUI.dylib` form a reusable arm64 Mach-O
package with sibling OpenUIKit, Foundation, Combine, Widget, and Onboarding
images plus matching compile modules; the Focus executables import framework
symbols instead of defining static copies. The complete state/observation
sources compile into the packaged SwiftUI image with one OpenCombine identity,
and onboarding exercises that observation path at runtime. A separate
package-owned WidgetKit framework now executes timelines and reload state; its
extension presentation host, installation as a system framework, runtime coverage for every Onboarding
controller/preview/tooltip path, and the complete unchanged Focus app remain
later milestones. The package proof now emits and links all 21 unchanged
Onboarding target files; the focused interaction executable still runs the
12-source shipping route described below.
Apple's SwiftUI and Combine binaries are neither available nor linked.

“Apple Foundation is not linked” here means the executables and packaged
dylibs have no direct Apple Foundation/SwiftUI/SwiftUICore load. The
recursively loaded non-Apple Swift substrate does name Foundation and
CoreFoundation paths; the prepared guest root deliberately satisfies them with
project-owned extensionless loud-abort stubs. The executable proof resolves
and hashes that full transitive closure and calls this distinction out rather
than hiding those two known substrate loads.

## Measured pinned boundary

Subject: `mozilla-mobile/focus-ios` commit
`a2832521c1daa0c23419c73705ae043ed60c9791`.

The canonical inventory finds exactly:

- 28 checked-in files with a direct `import SwiftUI`;
- 27 in the main application link closure;
- 9 main `Blockzilla` target files;
- 18 files in linked local Swift-package targets;
- 1 unique `WidgetsExtension` entry file;
- 4 preview-only files which are nevertheless implicit SwiftPM compile inputs;
- a reviewed vocabulary of 30 SwiftUI-shaped type/protocol lexical candidates,
  38 dot-call modifier candidates, and 3 property-wrapper candidates;
- 18 `View`-conformance candidates and 44 exact `some View` token occurrences.

The three app hosting call sites are not the whole boundary. The main target
also contains six Internal Settings view files, while linked `DesignSystem`,
`Licenses`, `Onboarding`, and `Widget` package targets add their own SwiftUI
sources. The Widgets extension is a separate WidgetKit runtime boundary.

The exact per-file hashes, roles, lexical candidate locations, derived visible
module/re-export requirements, and shipping entry routes are in
`focus-swiftui-surface.json` (SHA-256
`5a7486b2c0d626c98ad3a96a58bb242d21ef8594c45efc36f3f5f4f2abe48f71`).

Token locations are exact; ownership is deliberately not inferred from token
spelling. For example, the large UIKit hosting controller has `.bottom` and
`.leading` members, and Combine code has `$name` projections. Those remain
machine-labeled lexical candidates rather than being attributed to SwiftUI or
ViewBuilder. Separately, the contract derives declarations that must be visible
without a direct provider import. That evidence includes `UIImage`,
`UIPasteboard`, and `UserDefaults` in their exact source files.

## Artifacts

- `focus_swiftui_surface.py` attests the Focus Git pin, exact canonical Xcode
  plan, package manifest, PBX project, main-target source phase, implicit local
  package membership, Widgets extension markers, every inspected Git blob, and
  the exact reviewed importer set. It labels ambiguous token/syntax data as
  lexical candidates and derives external module-visibility evidence.
- `focus-swiftui-surface.json` is the canonical machine-readable compile
  contract.
- `ROADMAP.md` separates compile, runtime-semantic, and renderer/host gates and
  defines staged acceptance criteria.
- `FOCUS_WIDGET_GUEST.md`, `build_focus_widget_guest.sh`, and the separately
  labelled compatibility resource support and harness reproduce the exact
  unchanged Focus widget as a Linux Mach-O guest. The pinned package manifest
  does not declare Widget resources, so this support is not claimed to be
  SwiftPM-generated.
- `FOCUS_ONBOARDING_GUEST.md`, `build_focus_onboarding_guest.sh`, the bounded
  Foundation umbrella/UUID substrate, and separately labelled build support
  reproduce the exact unchanged shipping onboarding route as a Linux guest.
- `donor-lock.json` pins six permissively licensed reference implementations.
- `test_focus_swiftui_surface.py` checks regeneration, denominators, critical
  API families, generated-source limits, tokenizer behavior, first-slice
  identity, and donor-lock shape. `test_focus_widget_guest.py` adds static
  regression teeth around the dylib packaging and executable proof boundary,
  including non-prefix Swift ABI ownership. The isolated-only
  `test_focus_widget_guest_adversarial.sh` mutates every reviewed resume/cache
  boundary, including a symlinked runtime ancestor, and requires each dirty
  resume to fail before guest success. `test_focus_onboarding_guest.py` guards
  the exact 12-source, nine-dylib, interaction, Foundation, and UUID boundary.

## Reproduce

From the `swift-macho-linux` repository root:

```sh
python3 full/swiftui/focus_swiftui_surface.py \
  --check full/swiftui/focus-swiftui-surface.json

python3 -m unittest discover \
  -s full/swiftui -p 'test_*.py' -v
```

The local contract suite includes inventory and both executable-proof boundary
suites. Expected result at the reviewed pin ends with:

```text
SWIFTUI CONTRACT OK sha256=5a7486b2c0d626c98ad3a96a58bb242d21ef8594c45efc36f3f5f4f2abe48f71
OK
```

Regeneration is explicit:

```sh
python3 full/swiftui/focus_swiftui_surface.py \
  --output full/swiftui/focus-swiftui-surface.json
```

The generator compares worktree bytes to the pinned Git blobs. It refuses a
different Focus revision, altered source, altered canonical Xcode plan,
manifest/project drift, a changed importer set, or canonical-byte drift.
Git inspection uses absolute `/usr/bin/git`, disables replacement objects and
global/system configuration, and supplies a fixed environment, so ambient Git
redirection or `PATH` cannot change the attested subject.

## Smallest executable target

The first runtime slice is the exact Focus `Widget` package:

```text
BlockzillaPackage/Sources/Widget/Assets.swift
BlockzillaPackage/Sources/Widget/SearchWidgetView.swift
```

It is already in the app's link closure through Onboarding and gives a compact
but real render: nested stacks, text, images, a gradient, optional background,
rounded clipping, layout/font/paint modifiers, and package assets. A new test
harness may instantiate this public view; the two Focus files themselves must
remain byte-identical.

This slice is not complete merely when it typechecks. The committed guest proof
meets the `ROADMAP.md` execution gates with an OpenUIKit
`UIHostingController`, exact resource staging, no Apple SwiftUI load command,
a linked Mach-O guest running under Linux machorun, a checked mounted view
hierarchy, and deterministic pixel probes. See `FOCUS_WIDGET_GUEST.md` for the
reproduction command, exact dylib/linkage gates, and explicit limits.

## Donor evidence

The local survey used these commands for already-cloned candidates:

```sh
git -C scratch/swiftui-candidates/NAME rev-parse HEAD
git -C scratch/swiftui-candidates/NAME remote get-url origin
git -C scratch/swiftui-candidates/NAME show -s \
  --format='%ad %s' --date=iso-strict HEAD
shasum -a 256 scratch/swiftui-candidates/NAME/LICENSE
```

SwiftCrossUI was checked at the remote HEAD and cloned to a fresh temporary
directory for the same license inspection:

```sh
git ls-remote https://github.com/stackotter/swift-cross-ui.git HEAD
git clone https://github.com/stackotter/swift-cross-ui.git /tmp/swiftcrossui/repo
git -C /tmp/swiftcrossui/repo checkout \
  b835ea76f35cfcda1c60de72af484aa0b5963041
```

Observed pins and licenses:

| Repository | Revision | License | LICENSE SHA-256 |
| --- | --- | --- | --- |
| OpenSwiftUI | `4373df0d44e7a26003fcd4cd15a52ebc61415208` | MIT | `e3976a926431bd88d2ababcf89764f4ae5b6e7da9be4cda979dc1e50d05f2586` |
| Tokamak | `e0d8e9db462938610337327ade58161aa3b698ac` | Apache-2.0 | `385ee68d169ba712fc7e6230def0ea979d812d0d69f2f985a3512d1e858a5804` |
| AltSwiftUI | `1e83580f3003bb6b5fd01a15f7719c037ca0f39f` | MIT | `c6728f560792a4594805683ce03d84cabea3c7e8c3209f5f83ab8e99cbe116a6` |
| SwiftCrossUI | `b835ea76f35cfcda1c60de72af484aa0b5963041` | MIT | `3c25f31e07a5c2136c56fdacb988ddf589d0b0bf2a0a2a8ee8c703d8d2bbb03f` |
| SwiftOpenUI | `8100d9ca2f46b0f2a9251c33afd466c166939229` | MIT | `69b0c5b2bca1c0d0c92f883eb5e6c830541fa365229d9533150ff779da1b678c` |
| QuillUI | `006b072e38158a15ff39554d6acde2b839a964ab` | Apache-2.0 | `567c1d9c9e13c9696efc29e90eb8d1345e24f7c93ef54f674952c307dd1d8d73` |

These are reference pins, not dependencies. In particular:

- AltSwiftUI documents that its `View` contract is not interchangeable with
  SwiftUI and assumes Apple's UIKit.
- Tokamak and SwiftCrossUI require different import/module contracts.
- OpenSwiftUI has a much larger private-framework/core dependency graph and no
  OpenUIKit guest renderer.
- SwiftOpenUI has useful cross-platform graph/layout/backend machinery but no
  OpenUIKit hosting boundary and is not named `SwiftUI`.
- QuillUI already exposes a product named `SwiftUI` and contains useful
  re-export and UIKit-hosting shapes, but its SwiftOpenUI plus AppKit/UIKit plus
  GTK/Qt graph is a different runtime from this project's OpenUIKit Mach-O
  substrate.

The port can selectively adapt permissively licensed implementation ideas or
files with exact provenance. It must not create a second UIKit, Combine, or
Foundation identity.

## Honesty limits

- This is a checked-in source and conservative lexical-candidate inventory, not
  an ABI dump or compiler name-resolution trace. Exact token locations do not
  prove that a member receiver, projected value, conditional, or conformance is
  owned or lowered by SwiftUI.
- Two main-target source references are generated. Their accepted hashes and
  reviewed lack of `SwiftUI` imports are linked to the existing generated-source
  provenance. The historical Xcode 14.2 `EraseIntent.swift` bytes remain
  unresolved and are called out in the canonical JSON.
- `Preview Files` are compile inputs because the pinned Swift package does not
  exclude them. Their presence does not make preview rendering a shipping
  runtime requirement.
- No Focus file, OpenUIKit file, app overlay, SwiftUI implementation, dylib,
  Linux guest, or renderer was created by this inventory work.
