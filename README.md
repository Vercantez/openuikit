# OpenUIKit monorepo

Everything needed to build and run real iOS apps on Linux, in one repository:

| Directory | What it is |
| --- | --- |
| `/` (root: `full/`, `scripts/`, `slice/`, `spike/`, `harness/`, `docs/`) | The platform/integration lineage (formerly `swift-macho-linux` / `openuikit-linux-platform`): framework fan-out, app pipelines, packaging, attestation, Cursor cloud-agent infra |
| `uikit/` | OpenUIKit + SwiftUI + Combine + the render stack, oracle-validated against real UIKit (109-scene golden suite) |
| `machorun/` | The Mach-O loader for Linux/arm64 with its own Darwin→glibc libSystem |
| `foundation-macho/` | The Foundation port: NS* over our CoreFoundation + the FoundationEssentials overlay |
| `swiftcore-macho/` | libswiftCore cross-built on Linux as a Darwin Mach-O |
| `quartz/` | Portable CoreGraphics + CoreAnimation (CQuartz backend) |
| `objc4-linux/` | RETIRED: Apple objc4 on Linux/ELF (superseded — machorun builds objc4 as Mach-O) |

Each imported directory keeps its complete git history (subtree merges). The
platform lineage's original README follows.

---

# swift-macho-linux

A decisive spike: **can a Linux-hosted Swift toolchain build a Mach-O dylib for
`arm64-apple-macos`**, so Swift — eventually OpenUIKit — can join the
[machorun](../machorun) stack?

Yes. Trivial Swift, `@objc` classes with `#selector`, generics, collections,
closures and `async` all compile and link to arm64 Mach-O on Linux with
`swift:6.2-noble` + `ld64.lld-18`, and produce byte-identical output to an
Apple-built oracle. The trivial case also runs under machorun. Anything that
touches the Swift runtime stops at one missing artifact: `libswiftCore.dylib`
does not exist as a file on either operating system.

**Read [`docs/SPIKE.md`](docs/SPIKE.md)** — the ladder, what is staged, the two
loud failures found on the way, and the recommendation.

The production Xcode-project path is documented in
[`docs/LOCAL_SWIFT_PACKAGE_GRAPH.md`](docs/LOCAL_SWIFT_PACKAGE_GRAPH.md) and
[`docs/REMOTE_SWIFT_PACKAGE_MATERIALIZATION.md`](docs/REMOTE_SWIFT_PACKAGE_MATERIALIZATION.md).
It freezes local and exact remote Swift-package targets into real module/object
boundaries without changing application or vendor source.

Everything under `scratch/` and `build/` is generated and gitignored;
`scripts/stage_darwin_swift.sh` and `scripts/stage_objc_module.sh` rebuild the
one Apple dependency (15 MB, almost all of it textual `.swiftinterface`).
This repository reads `~/machorun` and never writes into it.
