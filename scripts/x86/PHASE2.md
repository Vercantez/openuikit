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
`scratch/mrroot`, `scratch/mrroot_fe`, `scratch/mrroot_full`, or
`opencombine-…/export/`. x86 outputs land **beside** those trees
(`sysroot_fe4-x86_64`, `mrroot-x86_64`, `mrroot_fe-x86_64`,
`mrroot_full-x86_64`, `export-x86_64/`).

Operator restage of real inputs (Focus_Widget.bundle + Reminder inventory)
then this runner:

```bash
bash x86_stage_inputs_phase2.sh
```

(`x86_stage_inputs_phase2.sh` lives on the operator box; it sets
`FOCUS_WIDGET_BUNDLE` and invokes `bash scripts/x86/phase2.sh`.)

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
| rung a `run_ud_guest.sh` | `ud-guest-x86` links `scratch/ud-guest-x86_64/bin/ud_guest` through `link_ud_guest.sh` (tbd-first). Runtime still needs the nine overlay dylibs at load. Missing CF objects: `CANNOT_UD_GUEST_LIBCFTEST file=libCFTest.dylib`. | smoke 14/14 + persist under the ported loader once overlays land |
| rung b Focus widget + onboarding | scripts retargeted; `NEEDS_X86_OPENCOMBINE` resolved by `export-x86_64/` (arm64 SHA untouched) | same gates under the ported loader |
| rung c Reminder scene | inner script no longer refuses x86-on-x86; still needs Reminder 22-source inventory | one `UIWindow` + three paced turns |

Static tests: `bash scripts/x86/test_phase2.sh`.

## Closing the PR #7 walls (without rewriting arm64 pins)

1. Linux sysroot sibling: `scripts/x86/stage_fe_sysroot.sh` writes
   `scratch/sysroot_fe4-x86_64` only. Copies textual Darwin overlays from the
   arm64 sysroot when present; refuses arm64 dylibs. After the ObjectiveC
   `module.modulemap` it runs `machorun/scripts/gen_darwin_modulemap.py` against
   the x86 sysroot (Linux fallback: copy **everything the arm64 generator wrote**
   — Darwin-family maps **and** `usr/include/_modules/*.h` and any other file
   that names the generator; enumerate from the arm64 sysroot, do not hard-code
   the 44 shim names). After restage, every `header "…"` path in every staged
   modulemap must resolve; otherwise `CANNOT_DARWIN_MODULEMAP_HEADERS` with
   `missing=`. The FileManager/sdk-gap measurement set (`complex.h`, `sysdir.h`,
   `sys/xattr.h`, `copyfile.h`, `removefile.h`, `fts.h`, `pwd.h`, `grp.h`,
   `sys/utsname.h`, `sys/quota.h`) is a **shared list** in
   `full/foundation/fe_sysroot_measurement_headers.txt` — both stagers read it;
   neither duplicates the literal. x86 `stage_absent`s missing members from
   arm64 `scratch/sysroot_fe4` (same rule as `_modules`). `vm_copy` is appended
   to `mach/vm_map.h` by the shared helper, not copied as a file. After restage
   every path in that list must exist in the x86 sysroot; otherwise
   `CANNOT_FE_MEASUREMENT_HEADERS` with `missing=` (the operator's 14 FE errors
   were all `removefile.h`). Apple's Darwin overlay is textual `.swiftinterface` (no prebuilt
   `.swiftmodule` on the arm64 sysroot). Arm64 compiles that interface with
   Swift 6.2.4; the 6.2.1-vs-6.2.4 "SDK is not supported" line is the fallback
   when Clang Darwin fails (missing maps or missing `_modules` headers), not a
   flag. x86 takes the same compile-the-interface path. Idempotency keys on
   input shas (artifact, generator, overlay text, **measurement-header list**)
   written to `.phase2-stage-inputs`
   (recipe `stage_fe_sysroot_x86.4`); a sysroot staged before those inputs
   existed is restaged, and the CANNOT/cold-built line names which input
   changed. Apple's `os.swiftmodule` is not copied (FE uses
   `full/foundation/os-module`).
   `build_fe.sh` is Swift-only on both arches. Arm64 compiles
   `full/foundation/removefile_compat.c` in `full/scripts/build_full.sh` and
   links `removefile_compat.o` with `FoundationEssentials.o`. The x86 runner
   compiles that same `.c` (same clang argv) into
   `build/full-x86_64/foundation/essentials/removefile_compat.o` after a
   successful `build_fe.sh`. Darwin userland already `EXPORT`s
   `copyfile`/`fcopyfile`, `fts_*`, xattr, `getgrnam_r`, `uname`, `quotactl`
   (and stub `removefile*`; the `.o` wins at link). Next operator **link** of
   FE is still expected to miss, unless `fm_unimplemented.o` / `uuid_compat.o`
   are also in the link (arm64 `build_full.sh` compiles both; phase2 does not):
   `chflags`, `confstr`, `fchmod`, `getattrlist`, `link`, `mktemp`,
   `sysctlbyname`, `utimes`, `uuid_generate_random`, `uuid_parse`,
   `uuid_unparse_upper`. `vm_copy` is in machorun `darwin/src/mach.c` (should
   resolve from x86 libSystem). Confirm or refute that list on the next rerun.
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
4. `build_full.sh` defaults `BASE_RUNTIME_SOURCE` / `FE_RUNTIME_SOURCE` to
   `scratch/mrroot${FULL_OUT_SUFFIX}` and `scratch/mrroot_fe${FULL_OUT_SUFFIX}`
   (empty suffix = historical arm64 paths). phase2 stages `scratch/mrroot-x86_64`
   (x86 ELF loader + x86 darwin userland + x86 `libswiftCore` from
   `swiftcore-macho/artifacts/swift-macosx/x86_64/`) the same role as arm64
   `scratch/mrroot`. FE overlays are staged into `scratch/mrroot_fe-x86_64`
   from that artifacts directory (or `$HOME/work/build/lib/swift/macosx/x86_64`)
   when the dylibs exist as X86_64 Mach-O; otherwise
   `CANNOT_X86_OVERLAYS_NOT_BUILT missing=libswiftDarwin.dylib,…` listing the
   nine `FE_OVERLAYS` names. `scripts/stage_swift_runtime.sh` stays macOS-only
   and is not used on this host. `build_full.sh` / mrroot refuse to copy an
   arm64 `libswiftCore.dylib` into an x86-named root (`require_macho_cpu`).
5. Widget env-prepare inherits `FULL_OUT_SUFFIX` from `guest_arch.inc`.
   `sysroot_fe4` / `mrroot_full` / `mrroot-base-runtime` resolve the suffixed
   trees. `tbd-stubs` tries `machorun/scripts/gen_tbd.sh` (host-independent);
   it never emits `CURSOR_ENV_CANNOT_GENERATE_TBD` because `uname` is x86_64.
   `opencombine-export` accepts `export-x86_64/RESULT.txt` from the real
   `scripts/x86/build_opencombine.sh` build — it does not pin the arm64 RESULT
   SHA and does not invent a RESULT.txt.
6. `os-module-x86` runs `full/foundation/build_os_module.sh` with
   `TARGET=x86_64-apple-macos15.0` and `OUT=build/full-x86_64/foundation/os`
   (beside arm64 `scratch/fe4_os`). `build_fe.sh` gets `OSMOD` so
   `Calendar.swift:14 import os` resolves. Before that compile, `ENV_PREPARE
   fe-imports` probes Darwin/os/Swift/_Builtin_float/_StringProcessing/_Concurrency
   (required) and Synchronization (optional/`canImport`) in the x86 sysroot
   and refuses in one line if any required module is absent.
7. Module cache: one canonical path per target, `scratch/modcache_fe4-x86_64`
   (beside arm64 `scratch/modcache_fe4`). `phase2` resolves `W` with `pwd -P`
   and the cache with `realpath -P`, prints
   `ENV_PREPARE module-cache satisfied path=…`, and passes that `MC` into
   every x86 `swiftc` (os-module, collections, FE, OpenCombine). Mixing `/w`
   and `$W` spellings of the same cache makes clang report
   `_DarwinFoundation2` defined in both `.pcm` paths (host-w-layout's
   `ln -sfn $W /w` is the same inode).
8. Guest harness fonts still open `/w/build/swiftui-guest/fonts`. The widget
   script stages fonts there and under `$W/build/swiftui-guest/fonts`; phase2
   tries `ln -sfn $W /w` and CANNOT if it cannot. Compiler argv never uses
   the `/w` spelling for `-module-cache-path`.
9. `ud-guest-x86` produces the x86_64 `#87` guest binary through
   foundation-macho's committed pipeline rather than asking the operator to
   hand-stage it. Work tree is `scratch/ud-guest-x86_64` (never unsuffixed
   `scratch/ud-guest`). FE objects are **reused** from
   `build/full-x86_64/foundation` (same `build_fe.sh` / collections / os /
   cshims argv phase2 already ran) and staged into that tree's `$W/fe` the
   way `stage_fe_guest.sh` laid out the arm64 #87 container. Port + runner
   compile use `build_ud_score_guest.sh`'s argv (`COMPILE_TRIPLE` macos15,
   `-O -wmo`, `CFPreferencesMinimal`) plus the `_FoundationCShims` clang
   module map every FE consumer needs (`build_url_runner.sh`). Compiler
   output is written to `scratch/ud-guest-x86_64/fe/UserDefaultsGuest.swiftc.log`
   (runner: `fe/runner.swiftc.log`); the CANNOT line names `log=` that path
   instead of inlining swiftc text. Link is **only**
   `foundation-macho/scripts/link_ud_guest.sh` (macos13 `TRIPLE`, tbd-first
   `-L` order). `fm_unimplemented.o` is compiled once into essentials/ with
   `build_full.sh`'s clang argv. `libswiftcompat.dylib` comes from an existing
   x86 Mach-O or `swiftcore-macho/scripts/build_compat.sh`. `libCFTest.dylib`
   has no committed x86 object recipe (`/work/cfobjc` is shell-history only);
   missing it is `CANNOT_UD_GUEST_LIBCFTEST file=libCFTest.dylib`. Any other
   missing piece is `CANNOT_UD_GUEST_<FILE> file=<basename>`. On success the
   binary is exported as `UD_GUEST_BIN` for rung a, with
   `bin/ud_guest.otool.txt` (`MH_MAGIC_64 X86_64` + expected loads). Overlay
   dylibs are not required at link time; rung a still needs them at load.
10. `scratch/mrroot-x86_64/host/` is the Linux host runtime boundary
    `build_full.sh` copies (`HOST_RUNTIME_FILES`: libdispatch.so and
    libBlocksRuntime.so from the Swift linux toolchain, **plus** four
    project-built ELF helpers). phase2 resolves the Swift linux lib dir the
    same way `full/dispatch/build_host_bridge.sh` does (`SWIFT_TOOLCHAIN` →
    `/opt/swift624/usr` → `/opt/swift/usr` → swiftc-on-PATH → `/usr`) via
    `full/dispatch/swift_linux_lib.inc`, copies **only** the two toolchain
    names (dereference + require `ELF 64-bit LSB shared object, x86-64`;
    arm64 ELF / Mach-O / text is dropped), then **builds** the four Open*
    helpers for ELF x86_64 through the committed recipes — never copies
    Open* from the linux dir or from an arm64 mrroot:
    `full/dispatch/build_host_bridge.sh` → `libOpenDispatchHost.so`;
    `full/foundationinternationalization/build_host_helper.sh` →
    `libOpenFoundationInternationalizationHost.so`;
    `full/urltransport/build_host_helper.sh` → `libOpenURLTransportHost.so`;
    `full/relativetime/build_host_helper.sh` → `libOpenRelativeTimeHost.so`.
    sha256 lands in `host/SHA256SUMS`. An empty or partial `host/` is
    `CANNOT_X86_HOST_RUNTIME missing=…` on item `mrroot-host-x86` **before**
    rungs b/c invoke `build_full.sh`, and `missing=` names each file that
    could not be copied or built. Not a PR3 `CURSOR_ENV_CANNOT_*` marker.
11. `mrroot-layout-x86` makes `scratch/mrroot-x86_64` **layout-complete by
    contract** with `build_full.sh` (widget/reminder guests call `build_full`
    and read `mrroot_full`, not the base root). Before any rung runs
    `build_full`, phase2 fills then checks every BASE path the consumer
    reads: extensionless `Foundation` / `CoreFoundation` loud-abort stubs
    (`scripts/build_runtime_shims.sh STUBS_ONLY=1`, `x86_64-apple-macos`),
    `libswiftcompat.dylib` (`swiftcore-macho/scripts/build_compat.sh`; never
    the arm64 `artifacts/libswiftcompat.dylib` — x86 unexports the nine
    symbols x86 `libSystem` already defines via
    `sdk/compat/x86_unexported_symbols.txt`; the arm64 artifact stays
    byte-identical because staged arm64 `libSystem` exports none of them), `libswiftCore.dylib` (already
    from `mrroot-base-x86`), `libswift_Concurrency.dylib` /
    `libswiftObjectiveC.dylib` from the x86 overlay search (Apple-SDK
    ObjectiveC is named in `missing=` rather than stubbed). Host ELF files
    and FE overlay dylibs are the same closed sets as `mrroot-host-x86` /
    `mrroot-fe-overlays-x86`. Incomplete layout is
    `CANNOT_X86_MRROOT_LAYOUT missing=…` (leaf names). Not a PR3
    `CURSOR_ENV_CANNOT_*` marker. Rungs b/c wait on `LAYOUT_OK`; rung a does
    not run `build_full`. The ud_guest port/runner argv also takes
    `-I $fe_out/collections` (plus the staged `$ud_w/fe/collections`) so
    swiftc sees `OrderedCollections` / `_RopeModule` the way
    `build_url_runner.sh` / PR #28 put FI search paths on argv.

## Operator-staged Apple x86_64 overlays

`scratch/apple-x86-overlays/` (never committed) holds Apple's own x86_64
Swift overlays extracted on the operator Mac from
`/System/Volumes/Preboot/Cryptexes/OS/System/Library/dyld/dyld_shared_cache_x86_64`
with `ipsw dyld extract`, plus a `PROVENANCE.txt` (macOS build, tool, sha256
per file). phase2 searches it after the swiftcore-macho cross-build dir, so a
cross-built overlay wins when present and the Apple copy fills the four
Apple-SDK overlays (`_DarwinFoundation1/2/3`, `_errno`) that
`stdlib/public/CMakeLists.txt` never builds on Linux. Same standing as the
arm64 CoreSimulator overlays staged by `scripts/stage_swift_runtime.sh`.
