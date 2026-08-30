# Cold core guest package

`build_core_guest_package.sh` is the reusable platform half of the untouched
application pipeline. It rebuilds the production ARM64 Mach-O substrate from
cold inputs and publishes one relocatable package. The Xcode-project planner
and app executor consume that package; they do not reproduce framework build
logic.

This is production code, not a mock SDK. The package contains the target
modules and dylibs for FoundationEssentials, OpenCoreGraphics, OpenUIKit,
OpenCombine, Combine, SwiftUI, the app-facing Foundation facade, and final
Foundation-visible UIKit. It also contains C module headers, CQuartz, the SDK,
the attested machorun guest-root closure, OpenUIKit's complete resource tree,
and the two pinned DejaVu fonts used by the proven Linux path.

## Container entry point

Run the builder inside the pinned Linux/aarch64 image:

```sh
bash full/frameworks/build_core_guest_package.sh \
  --output-root /w/build/core-package-NEW \
  --expected-support-commit 40_LOWERCASE_HEX \
  --expected-support-tree 40_LOWERCASE_HEX \
  --uikit-checkout /uikit \
  --expected-uikit-commit 40_LOWERCASE_HEX \
  --expected-uikit-tree 40_LOWERCASE_HEX
```

`--output-root` must be a nonexistent direct child of `/w/build`. Exact support
and UIKit commit/tree values are required inputs, not provenance inferred after
the fact. Both source checkouts are bracketed for commit/tree and cleanliness;
the support commit must also descend from the accepted Foundation substrate.

The Foundation facade source list is mandatory and defaults to
`full/foundation/foundation_guest_sources.txt`. Its eight LF-terminated lines
are validated for exact order, identity, regular-file topology, and content
hash before and after the build. A different path can be supplied with
`--foundation-sources-manifest`, but it must satisfy that same exact contract.

The semantic build order is deliberate:

1. Rebuild FoundationEssentials, OpenCoreGraphics, and OpenUIKit with the
   Foundation umbrella hidden.
2. Exercise the literal early UIKit/identity production gate; this is not the
   final app-facing UIKit module.
3. Build OpenCombine, Combine, and dependency-light SwiftUI.
4. Compile the ordered app-facing Foundation facade.
5. Compile final UIKit after Foundation exists, then prove cross-import
   Notification, NotificationCenter, and OperationQueue identity.
6. Link the reusable dylibs and run the package's Mach-O closure/resource/font
   probe through the packaged machorun root.

FoundationEssentials' dylib includes both the upstream cshim `uuid.o` and the
project compatibility `uuid_compat.o`; the latter must not be dropped merely
because a small dead-stripped probe happens not to reference it.

## Output contract

The package is self-contained under these directories:

```text
sdk/                 copied compile sysroot
modules/             target Swift modules
lib/                 reusable ARM64 Mach-O dylibs
include/             C module maps and headers
objects/             optional executable-layer objects
resources/OpenUIKit/ exact runtime JSON/resources plus fonts/
guest-root/          machorun plus its attested runtime closure
probe/               independently runnable package probe
attestation/         provenance, exhaustive inventories, hashes, runtime log
```

`attestation/core-package.json` is authoritative. Its stable consumer schema
has:

- `classification: "open-uikit-core-guest-package"` and `format_version: 1`;
- `target.triple: "arm64-apple-macos15.0"`;
- exactly the `sdk`, `modules`, `libraries`, `includes`, `objects`,
  `resources`, and `guest_root` path keys;
- package-root-relative `swift_compile_arguments` and
  `executable_link_arguments` arrays;
- SHA-256 and byte size for every declared product, every library, and every
  file below `resources/OpenUIKit`;
- exact tree/provenance manifests and logical OpenUIKit resource/font paths;
- a nullable bounded `preview` record.

The argument arrays are evaluated with the package root as the current working
directory. No absolute build path is permitted. The parallel `.rsp` files are
NUL-delimited UTF-8 for diagnostics only; consumers use the JSON arrays. Verify
any moved package with:

```sh
python3 full/xcodeplan/core_guest_package.py PACKAGE --emit-summary
python3 full/frameworks/core_package_manifest.py verify \
  --package-root PACKAGE
```

OpenUIKit's source `Resources` tree is copied byte-for-byte to
`resources/OpenUIKit`, with symlinks forbidden and empty directories attested.
The pinned container fonts are then added at
`resources/OpenUIKit/fonts/DejaVuSans.ttf` and
`DejaVuSans-Bold.ttf`. The app materializer copies this directory to
`<App>.app/Contents/Resources/OpenUIKit`; generated host code sets
`OpenUIKitRuntime.resourceRoot` and `fontPaths` to those bundle locations.

## Optional Preview seam

Preview support is strictly all-or-none:

```sh
  --developer-tools-support-module DeveloperToolsSupport.swiftmodule \
  --developer-tools-support-object developertoolsupport.o \
  --preview-macro-plugin OpenUIKitPreviewMacros-tool
```

The builder validates the exact basenames, regular-file topology, plugin
executable bit, native ELF64/AArch64 identity, Swift 6.2.4 toolchain, and all
three hashes. It also records and enforces SwiftSyntax revision
`4799286537280063c85a32f09884cfbca301b1a1`. The host plugin is never
target-linked or copied into the
package. Its package response file contains the literal relocatable token
`${PREVIEW_PLUGIN}#OpenUIKitPreviewMacros`; the actual external plugin path is
used only while building or when explicitly passed to manifest verification.

The target DTS module is added to UIKit/app compile visibility. Its object is
kept separate under `objects/` and named only by
`preview.developer_tools_support_object`. It is intentionally absent from
generic `executable_link_arguments`: the app driver appends it exactly once.
The core runtime probe likewise links it exactly once, leaves its UIKit imports
dynamic, evaluates a retained Preview body, and proves UIKit carries no DTS
dylib dependency. The JSON also publishes the exact compiler evidence flags:

```json
["-Xfrontend", "-dump-macro-expansions"]
```

The app driver captures that compiler stream as
`attestation/app-macro-expansions.stderr`. Successful object emission alone is
not a macro-expansion proof.

## Fresh host replay

`run_core_guest_package_docker.sh` is the host-side cold wrapper. It requires
exact support and UIKit commit/tree pins, a machorun checkout, a new output
path, and a staged-input root containing:

```text
sysroot_fe4/  mrroot/  mrroot_fe/  swift-foundation/
swift-collections/  opencombine-core-durable-20260828-r2/
```

Example shape (the output must not exist):

```sh
bash full/frameworks/run_core_guest_package_docker.sh \
  --support-checkout /path/to/clean/support \
  --expected-support-commit 40_HEX \
  --expected-support-tree 40_HEX \
  --staged-input-root /path/to/canonical/support/scratch \
  --uikit-checkout /path/to/clean/uikit \
  --expected-uikit-commit 40_HEX \
  --expected-uikit-tree 40_HEX \
  --machorun-checkout /path/to/clean/machorun \
  --output-root /path/to/new/core-package
```

The wrapper makes a fresh no-hardlink support clone. That clone and every
source/staged input are mounted read-only. Only unique empty build,
`modcache_full`, and `mrroot_full` directories are mounted writable. It runs
both package validators before atomically publishing the output, preserves a
host/container log with commit/tree and inode preamble, and renames every
failed run or partially published output with `.INVALID-DO-NOT-USE`.

Neither script edits UIKit, application, vendored, machorun, or upstream
Foundation/OpenCombine sources. A package is not complete unless its runtime
probe, closure attestation, JSON verifier, canonical consumer validator, and
`PACKAGE_COMPLETE` marker all agree.

## Static tests

```sh
python3 full/frameworks/test_core_guest_package.py
bash -n full/frameworks/build_core_guest_package.sh
bash -n full/frameworks/run_core_guest_package_docker.sh
bash -n full/scripts/build_full.sh
```

The tests exercise exact Foundation ordering, path/symlink refusal, relocation
to a path containing spaces, Preview placeholder/external-plugin behavior,
DTS ownership, resource/library tamper detection, and the early/final UIKit
ordering hooks.
