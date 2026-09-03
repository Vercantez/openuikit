# machorun x86_64 PHASE 2

One operator command on a provisioned x86_64 Ubuntu 24.04 host (clang-18/lld-18,
Swift 6.2.4, docker, tree already staged at
`/opt/openuikit/x86-verify/openuikit` with
`scratch/{ladder-corpus/focus-ios, swift-foundation, swift-collections,
opencombine-core-durable-20260828-r2, sysroot_fe4, mrroot_full,
modcache_swiftui_guest}` — note `sysroot_fe4` / `mrroot_full` hold **arm64**
artifacts):

```bash
bash scripts/x86/phase2.sh /opt/openuikit/x86-verify/openuikit
```

Idempotent. Prints `ENV_PREPARE <name> satisfied|cold-built|CANNOT_<MARKER>`
lines and a final `RUNG_SCOREBOARD` whose denominators are the committed
runners':

- a: `foundation-macho/tests/ud_guest_runner.swift` — 14 `check()` calls;
  `run_ud_guest.sh` / `run_ud_persist.sh`
- b: Focus widget + onboarding source-preservation + `otool $OTOOL_CPU` from
  `full/swiftui/build_focus_{widget,onboarding}_guest.sh`
- c: `windows=1 turns=3 paced=true` from
  `full/xcodeplan/build_and_run_reminder_scene_guest.sh`

Exit 2 if any CANNOT. Never overwrites `scratch/sysroot_fe4`,
`scratch/mrroot_full`, or `opencombine-…/export/`. x86 outputs land **beside**
those trees (`sysroot_fe4-x86_64`, `mrroot_full-x86_64`, `export-x86_64/`).

Do not edit `machorun/` in this phase: `EXPECTED_INREPO_MACHORUN_TREE` is a
Focus/full-build attestation pin.

## Measure first: libswiftCore-for-x86

This is the likeliest hard wall. The runner measures it before any later Swift
guest work:

- `swiftcore-macho/artifacts/swift-macosx/` ships **arm64**
  `libswiftCore.dylib` and `Swift.swiftmodule/arm64-apple-macos.*` plus the
  **x86_64 sibling** at `swift-macosx/x86_64/` (sha256 in
  `artifacts/x86_64.manifest.json`). `_Concurrency` for x86_64 is still the
  BUILD_LOG §16 / libdispatch wall.
- stdlib source is not in this tree (`swiftcore-macho/swift`, `scratch/swift`,
  `/opt/swift-source` all absent; no CMakeLists)
- `swiftcore-macho/scripts/configure.sh` used to hardcode
  `SWIFT_HOST_VARIANT_ARCH=aarch64` / `SWIFT_SDK_OSX_ARCHITECTURES=arm64`.
  That is now `scripts/guest_arch.inc` (`SWIFTCORE_DARWIN_ARCH`); the arm64
  argv is still the default on an aarch64 host. The x86_64 slice lives at
  `artifacts/swift-macosx/x86_64/` beside arm64. See `docs/X86_64.md`.
- `swiftc -target x86_64-apple-macos15.0 -sdk scratch/sysroot_fe4` fails:
  `could not find module '_Concurrency' for target 'x86_64-apple-macos'; found: arm64-apple-macos`

Cross-building libswiftCore is the CMake+Ninja stdlib-only recipe in
`swiftcore-macho/docs/BUILD_LOG.md`, historically on a Graviton box against a
full swift.org 6.2.4 checkout. **Do not stage the arm64 dylib under an x86
name.** The x86_64 `libswiftCore.dylib` + `Swift.swiftmodule` now sit beside
arm64; `_Concurrency` is still the BUILD_LOG §16 wall. Without that overlay,
rungs a/b/c that `import _Concurrency` still CANNOT. clang-18 can still emit
x86_64 Mach-O against sysroot headers (loader, darwin, objc4, quartz, `.tbd`,
cshims).

The configure hardcoding is gone: `swiftcore-macho/scripts/guest_arch.inc`
keeps the arm64 argv as `SWIFTCORE_DARWIN_ARCH=arm64` and selects x86_64 on
this host. One-command recipe: `docs/X86_64.md` §3:

```bash
NINJA_JOBS=16 SWIFTCORE_DARWIN_ARCH=x86_64 SWIFTCORE_OVERLAYS=1 \
  SWIFTCORE_BUILD_DISPATCH=1 SWIFT_TOOLCHAIN=/opt/swift \
  bash swiftcore-macho/scripts/build_stdlib.sh
```

## In-VM (this Cursor x86_64 VM) vs operator host

| step | in-VM (compile/link) | operator host (execution) |
|---|---|---|
| measure libswiftCore-x86 | yes — reports the wall | same measurement; pass only if an x86 slice is present |
| `build.sh` loader + darwin + tbd | yes | same |
| `build_objc4.sh` / `build_quartz.sh` | yes — unblocks the `objc` fixture | same |
| `scripts/x86/stage_fe_sysroot.sh` | headers + x86 dylibs + Darwin family modulemaps + x86 `libswiftCore`/`Swift.swiftmodule`/`_Builtin_float` into `usr/lib/swift`; restages when input shas change; `CANNOT_STAGE_XCODE_DARWIN_OVERLAYS` unless textual Darwin overlays exist in the arm64 `sysroot_fe4` | same |
| FoundationEssentials / collections / OpenCombine / `build_full.sh` | x86 `libswiftCore` + `Swift.swiftmodule` are in artifacts; `_Concurrency` overlay is not (libdispatch wall). `os-module-x86` is built into `build/full-x86_64/foundation/os` before `build_fe.sh`. `fe-imports` names missing `_Concurrency`/`_StringProcessing`/… instead of compiling 202 files | needs x86 libswiftCore + `_Concurrency` + `_StringProcessing` + Darwin overlays + os-module |
| rung a `run_ud_guest.sh` | cannot run a real FE guest without x86 libswiftCore + named MACHORUN_ROOT + `ud_guest` binary | smoke 14/14 + persist under the ported loader |
| rung b Focus widget + onboarding | scripts retargeted; `NEEDS_X86_OPENCOMBINE` resolved by `export-x86_64/` (arm64 SHA untouched) | same gates under the ported loader |
| rung c Reminder scene | inner script no longer refuses x86-on-x86; still needs Reminder 22-source inventory | one `UIWindow` + three paced turns |

Static tests: `bash scripts/x86/test_phase2.sh`.

## Closing the PR #7 walls (without rewriting arm64 pins)

1. Linux sysroot sibling: `scripts/x86/stage_fe_sysroot.sh` writes
   `scratch/sysroot_fe4-x86_64` only. Copies textual Darwin overlays from the
   arm64 sysroot when present; refuses arm64 dylibs. After the ObjectiveC
   `module.modulemap` it runs `machorun/scripts/gen_darwin_modulemap.py` against
   the x86 sysroot (Linux fallback: copy the pruned Darwin-family maps from the
   arm64 sysroot) and stages `libswiftCore.dylib`, `Swift.swiftmodule/x86_64-apple-macos.*`,
   and `_Builtin_float.swiftmodule/x86_64-apple-macos.*` into
   `usr/lib/swift`. Idempotency keys on input shas (artifact, generator,
   overlay text) written to `.phase2-stage-inputs`; a sysroot staged before
   those inputs existed is restaged, and the CANNOT/cold-built line names
   which input changed. Apple's `os.swiftmodule` is not copied (FE uses
   `full/foundation/os-module`).
2. OpenCombine: `scripts/x86/build_opencombine.sh` writes `export-x86_64/`.
   Source hashes from `policy.json` still apply. Object SHAs stay the arm64
   durable pin in `export/`. Focus/core-package scripts hash those objects
   only when `ARCH=arm64`; on x86 they require `MH_MAGIC_64 X86_64` instead of
   rewriting the SHA (`NEEDS_X86_OPENCOMBINE` until the x86 `.o` exists).
3. Focus pin `a2832521c1daa0c23419c73705ae043ed60c9791` is checked, not
   rewritten. The probe resolves `git rev-parse --show-toplevel` from
   `scratch/ladder-corpus/focus-ios/focus-ios` (app subtree; git root is the
   parent) with explicit `safe.directory` on that path and its parents, and
   a CANNOT line always names `expected=` and `observed=` (plus `git_error=`
   if git itself failed). Normalized bundles come from the committed
   `onboarding_resources_proof.py` or `FOCUS_WIDGET_BUNDLE`.
4. `build_full.sh` / mrroot refuse to copy an arm64 `libswiftCore.dylib` into
   an x86-named root (`require_macho_cpu`).
5. `os-module-x86` runs `full/foundation/build_os_module.sh` with
   `TARGET=x86_64-apple-macos15.0` and `OUT=build/full-x86_64/foundation/os`
   (beside arm64 `scratch/fe4_os`). `build_fe.sh` gets `OSMOD` so
   `Calendar.swift:14 import os` resolves. Before that compile, `ENV_PREPARE
   fe-imports` probes Darwin/os/Swift/_Builtin_float/_StringProcessing/_Concurrency
   (required) and Synchronization (optional/`canImport`) in the x86 sysroot
   and refuses in one line if any required module is absent.
6. Guest harness fonts still open `/w/build/swiftui-guest/fonts`. The widget
   script stages fonts there and under `$W/build/swiftui-guest/fonts`; phase2
   tries `ln -sfn $W /w` and CANNOT if it cannot.
