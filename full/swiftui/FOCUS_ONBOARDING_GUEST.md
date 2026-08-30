# Focus SwiftUI onboarding Mach-O guest proof

This proof runs Focus's shipping two-page SwiftUI onboarding path as an arm64
Mach-O guest on Linux. It compiles 12 pinned Focus files directly from the
clean `a2832521c1daa0c23419c73705ae043ed60c9791` checkout: the two `Widget`
files plus the ten files that define the production onboarding views, model,
design-system accessors, and `PortraitHostingController`. No Focus source is
copied, patched, overlaid, generated, or conditionally rewritten.
The framework side is pinned independently to clean OpenUIKit commit
`62dea0d97a3b9074e5c016820492bd0656b9a35a`, tree
`3dfd6024557632949c9a5036522871a36d4a0cf0`, before and after the build/run.

The project-owned harness mounts the exact `OnboardingView` through Focus's
exact `PortraitHostingController`. It finds controls through the mounted
OpenUIKit hierarchy and sends three real began/ended touch pairs. The checked
route is:

1. mount the first page and observe `getStartedAppeared`;
2. tap **Get Started**, verify the published mutation does not render in the
   same call stack, advance one host turn, and observe the second page;
3. tap **Set as Default Browser** and verify Foundation's `URL` reaches the
   OpenUIKit application hook;
4. tap **Skip** and verify the exact dismissal closure and telemetry order.

The runtime also exercises FoundationEssentials' public `UUID` round trip and
a C probe covering every raw UUID operation supplied by this port: clear,
null, compare, copy, strict parse with unchanged output on failure, lower and
upper formatting, random/version-4 generation, and time/version-1 generation.
The same probe links directly against macOS libSystem as a native behavior
oracle; this caught and fixed the otherwise easy-to-miss fact that Darwin's
plain `uuid_unparse` uses uppercase output.

## Provider boundary

The executable consumes nine independently loadable sibling dylibs:

| Image | Role |
| --- | --- |
| `libFoundationEssentials.dylib` | Open-source Foundation value types and raw Darwin UUID substrate |
| `libOpenCoreGraphics.dylib` | Project CoreGraphics-compatible value/paint surface |
| `libOpenUIKit.dylib` | The single UI type, layout, event, and renderer identity |
| `libFoundation.dylib` | Bounded umbrella for FoundationEssentials plus OpenUIKit `Bundle`/`NSCoder` identities and the `URL` bridge |
| `libOpenCombine.dylib` | The single observation implementation |
| `libCombine.dylib` | Literal Combine module/re-export boundary |
| `libSwiftUI.dylib` | Declarative graph, host-turn invalidation, and OpenUIKit renderer |
| `libWidget.dylib` | Exact unchanged Focus widget support used by onboarding |
| `libOnboarding.dylib` | Exact unchanged Focus onboarding runtime slice |

Every dylib is checked as arm64 Mach-O with its exact `@rpath` install name.
The recursive load closure is resolved beneath the declared package and guest
root before execution. Foundation deliberately has an ordinary dependency on
FoundationEssentials while its Swift source re-exports that module. Using an
`LC_REEXPORT_DYLIB` linker flag here creates duplicate normal/re-export loads
with the current `ld64.lld` and changes Swift symbol ordinals under machorun;
the source-level export preserves client visibility without that malformed
provider graph.

The project-owned `FocusOnboardingBundle.generated.swift` file is compatibility
build support for this port, not a generated or SwiftPM-equivalent accessor.
The exact pinned Focus `Package.swift` declares no Onboarding resources, so
Apple SwiftPM 6.2.1 generates no accessor and defines
`SWIFT_MODULE_RESOURCE_BUNDLE_UNAVAILABLE`; the unchanged source nevertheless
contains `Bundle.module` asset spellings. The port stages the reviewed exact
normalized `Focus_Onboarding.bundle` beside the guest executable and resolves
it relative to `Bundle.main`; the runtime gate asserts that exact bundle and
resource root, then evaluates unchanged `Color.actionButton` and `Image.logo`
through it and requires a direct same-bundle `UIImage` lookup to be non-nil.
The Widget target receives the same explicit treatment for its adjacent
`Focus_Widget.bundle`, unchanged named-gradient declarations, and logo image;
neither target relies on the process-global image-search fallback.
The ordered production Foundation source set is owned by
`full/foundation/foundation_guest_sources.txt`; the build validates and
consumes that manifest rather than duplicating its entries. `FoundationGuest.swift`,
`FocusOnboardingGuestMain.swift`, and `FocusOnboardingUUIDProbe.c` are port and
test code, not application source. Normalized resource bundles are supplied by
the existing pinned Focus resource proof and are checked for exact topology and
content digests before and after execution.

## Reproduce

Run from the `swift-macho-linux` repository root after producing the normalized
Focus resource bundles described by `full/focus-ios/onboarding_resources_proof.py`:

```bash
docker run --rm \
  -v "$PWD":/w \
  -v /Users/miguelsalinas/uikit:/uikit:ro \
  -v /Users/miguelsalinas/machorun:/machorun:ro \
  -v "$RESOURCE_PROOF/output/bundles":/focus-resources:ro \
  -w /w swift-macho-spike:noble \
  bash full/swiftui/build_focus_onboarding_guest.sh /focus-resources
```

The script rebuilds the production FoundationEssentials/OpenUIKit substrate,
hash-pins Focus, all 12 compiled source files, both resource trees,
OpenCombine artifacts, and open-font bytes, packages the nine dylibs, audits
the transitive runtime closure, runs under machorun, and requires this exact
terminal marker:

```text
FOCUS_ONBOARDING_MACHO_GUEST_OK sources=12 pages=2 touches=3 uuid=full telemetry=getStartedAppeared,getStartedButtonTapped,defaultBrowserAppeared,defaultBrowserSettingsTapped,defaultBrowserSkip
```

Derived output is confined to `build/focus-onboarding-guest/` and the normal
`build/full` production build directory.

On macOS, run the raw compatibility oracle without the port implementation:

```bash
oracle_dir=$(mktemp -d /private/tmp/open-uuid-native-oracle.XXXXXX)
clang -std=c11 -Wall -Wextra -Werror \
  -DOPEN_FOCUS_UUID_COMPAT_STANDALONE=1 \
  full/swiftui/FocusOnboardingUUIDProbe.c \
  -o "$oracle_dir/uuid_oracle"
"$oracle_dir/uuid_oracle"
```

## Honesty limits

This closes a runtime-semantic sub-gate of roadmap S2, not all of S2. The full
Onboarding package contains 21 Swift files. This executable includes the ten
shipping SwiftUI/onboarding files needed by the checked route plus the two
Widget files; handler, tooltip, legacy controller, and preview files remain
outside this focused runtime image. The separate package proof now emits and
links all 21 unchanged Onboarding sources, including the two
Objective-C-interoperable files that formerly triggered a stock Swift 6.2
Linux IRGen crash. It executes selected handler and constraint semantics, not
every emitted route. This is not a complete Focus application, a WidgetKit
extension, an Apple framework implementation, or broad SwiftUI API coverage
beyond the measured path.
