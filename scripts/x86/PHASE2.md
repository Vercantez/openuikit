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
| rung a `run_ud_guest.sh` | `ud-guest-x86` links `scratch/ud-guest-x86_64/bin/ud_guest` through `link_ud_guest.sh` (tbd-first). Runtime still needs the nine overlay dylibs at load. CF objects: `build_cfobjc.sh` then `build_cftest_harness.sh`. Missing CF sources or a failed link: `CANNOT_UD_GUEST_LIBCFTEST file=libCFTest.dylib`. | smoke 14/14 + persist under the ported loader once overlays land |
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
   (recipe `stage_fe_sysroot_x86.6`); a sysroot staged before those inputs
   existed is restaged, and the CANNOT/cold-built line names which input
   changed. Apple's `os.swiftmodule` is not copied (FE uses
   `full/foundation/os-module`).
   Operator note (rung c at 2732eb22): ipsw-extracted Apple overlay dylibs can
   keep dyld-cache `__DATA_CONST` vmaddrs that are not 4096-page aligned; the
   loader then refuses them. Standalone extraction is the operator's job; this
   tree has no committed rebase/rebuild of those Apple copies.
   The x86 sysroot's `usr/lib` `.tbd` set is generated from the **x86 darwin
   tree** by `machorun/scripts/gen_tbd.sh` (never copied from the arm64
   sysroot). `gen_tbd` emits Apple unsuffixed aliases (`libobjc.tbd` →
   `libobjc.A.tbd`); `-lobjc` looks for that name. Overlay `.tbd` files under
   `usr/lib/swift` are generated by `scripts/x86/gen_swift_tbd.sh` from the x86
   overlay dylibs (tapi-v4 / `x86_64-macos`, objc-classes / weak /
   reexported-libraries). The durable set is **libswiftCore plus twelve
   overlays** (nine FE + `_Concurrency` + ObjectiveC + Observation): each needs
   a named `.tbd` under `$SYS/usr/lib/swift` (the widget gate `lstat`s those
   paths; a dylib stand-in does not satisfy
   `focus_widget_guest_attest`) **and** the dylib in both `mrroot-x86_64` and
   `mrroot_fe-x86_64`. Sources: cross-built artifacts first (the five SDK
   overlays `_DarwinFoundation*` / `_errno` / ObjectiveC are built by
   `overlay_build_xcode_shells`, not Apple dyld-cache copies). Round-trip: every defined-external symbol of the
   dylib appears in the `.tbd`, every `LC_REEXPORT_DYLIB` is recorded
   (`bash scripts/x86/test_gen_swift_tbd.sh`). The stamp records `tbd-set` (arm64
   inventory of `usr/lib` + `usr/lib/swift` `.tbd` names) and
   `tbd-darwin-dylibs`. Before `build_full` runs, `sysroot-tbds-x86` requires
   the **consumer** `.tbd` set (`build_full.sh` `-lSystem`/`-lobjc`/`libquartz`,
   widget/onboarding `expected_*_inputs` / `expected_*_loads`,
   `focus_widget_guest_attest.pl`, `link_ud_guest.sh`) — darwin aliases +
   libquartz + libswiftCore + the twelve overlays — each naming `x86_64-macos`
   (`CANNOT_X86_SYSROOT_TBDS`). Extra Apple-SDK `.tbd` names in the arm64
   sysroot (ARKit, AppKit, AVFoundation, …) are a printed **NOTE**, never a
   CANNOT; there is no x86 dylib for them and nothing links them. An
   `arm64-macos` `.tbd` staged into the x86 sysroot is still `WRONG_TARGET`.
   Acceptance: `render_full.o`'s undefined
   `_objc_sync_exit` / `_objc_sync_enter` / associated-object /
   `_objc_opt_self` / `_objc_getClass*` / `__objc_empty_cache` are in the
   staged `libobjc.tbd`. Rung logs `2>&1 | tee` so `build_full` ld64 stderr
   is in `scratch/phase2-rung-b-widget.log` (not only `phase2f.log`).
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
   `-L` order, clang-18, `-nostdlib`). stdout+stderr land in
   `scratch/ud-guest-x86_64/link_ud_guest.log`; a failed link is
   `CANNOT_UD_GUEST_UD_GUEST file=ud_guest` naming `log=` that path (same
   spill as the swiftc logs — do not flatten ld64 onto the CANNOT line).
   `collections/_RopeModule.o` and `fe/_RopeModule.o` are the same object;
   the linker takes one, never both. `fm_unimplemented.o` is compiled once into essentials/ with
   `build_full.sh`'s clang argv. `libswiftcompat.dylib` comes from an existing
   x86 Mach-O or `swiftcore-macho/scripts/build_compat.sh`. `libCFTest.dylib`
   comes from `foundation-macho/scripts/build_cfobjc.sh` (objects under
   `$ud_w/cfobjc/obj`, recipe id `cfobjc.1`) then
   `foundation-macho/scripts/build_cftest_harness.sh` (the only CF linker).
   CoreFoundation sources are the env/contract.json checkout
   `swift-corelibs-foundation` (`f3a7a343`, tree `2f9136f2`, tagged
   `swift-6.2.4-RELEASE`, `demanded_by ud-guest-x86`). `ud-guest-x86` fetches
   that commit into `scratch/ud-guest-x86_64/cf` and refuses if `HEAD^{tree}`
   differs, naming the commit. The recipe compiles only
   `Sources/CoreFoundation`. ICU headers come from env/contract.json
   `swift-foundation-icu` (`87dbab99`, tree `823a4a2a`, `demanded_by
   ud-guest-x86`); without them `CFString.c` does not compile. A failed
   fetch/compile is `CANNOT_UD_GUEST_LIBCFTEST file=libCFTest.dylib`. The
   harness then derives the stub set and compares it to
   `docs/cf-census/cftest-stub-func-active.txt` / `cftest-stub-data.txt`
   (218 func + 2 data, `libCFTest relinked (220 stubbed)`). A mismatch is
   its own line `ENV_PREPARE cftest-stubs CANNOT_CFTEST_STUBS
   reason=count=N first=a,b,c,d,e …` and ud-guest does **not** link.
   Will not invent a stub dylib. `UD_CFTEST_DYLIB=` still stages a provided
   x86 dylib when no leftover stub lists are next to the work tree.
   After a successful link, before `run_ud_guest.sh`, phase2 copies
   `scratch/ud-guest-x86_64/lib/libCFTest.dylib` into
   `scratch/mrroot_full-x86_64/darwin/usr/lib/libCFTest.dylib` (the arm64
   analogue is `build_cftest_harness.sh` copying into `$W/root` when that
   directory exists; `full/scripts/build_full.sh` does **not** stage
   libCFTest). Prints `ENV_PREPARE libCFTest-run-root … path=… sha256=…`.
   Never copies onto the CoreFoundation.framework slot (byte-identical
   copy there is the duplicate-image refusal in `run_ud_guest.sh`).
   Then `ud-guest-dispatch` reuses the Reminder/Focus Linux Dispatch host
   bridge (`full/dispatch/build_host_bridge.sh` → `libOpenDispatchHost.so`,
   already built into `scratch/mrroot-x86_64/host/` when
   `mrroot-host-x86` ran) and links the Darwin facade
   (`OpenDispatchBridge.c`, LC_ID `/usr/lib/libOpenDispatch.dylib`).
   Prints `ENV_PREPARE ud-guest-dispatch … bridge=… runtime=… sha256=…`.
   `run_ud_guest.sh` / `run_ud_persist.sh` take `DISPATCH_HOST` (Reminder
   name; `OPENUI_DISPATCH_HOST` is an alias) and `DISPATCH_DARWIN`,
   `LD_PRELOAD` the bridge, and clone the named root to `$W/runroot`
   rather than mutating `mrroot_full`. The Darwin image sits at
   `runroot/darwin/usr/lib/libOpenDispatch.dylib` because libCFTest's
   `_dispatch_*` binds are **flat** (`-undefined dynamic_lookup`,
   libSystem.B does not re-export libdispatch) and libCFTest itself is
   `is_runtime` (`/usr/lib/libCFTest.dylib`), so `host_lookup` resolves
   them against the preloaded Linux libdispatch; the facade's
   `_glibc_openui_dispatch_host_v1_*` binds use the same gate.
   Without those variables the runners are the #87 container path
   (`MACHORUN_ROOT=$ROOT "$MRUN" "$BIN"`, default
   `MRUN=/stage/machorun-bin`). The `== binary` line prints
   `loader=$MRUN sha256=…` of the file about to be exec'd. Before rung a,
   phase2 copies `$MACHORUN/build/machorun` onto `$MRROOT/machorun` when
   newer (the same `-nt` rule `build_full.sh` uses for rungs b/c); the
   mrroot-x86 "satisfied" path otherwise leaves a stale loader in place.
   `link_ud_guest.sh` stays the only ud_guest linker. Any other
   missing piece is `CANNOT_UD_GUEST_<FILE> file=<basename>`. On success the
   binary is exported as `UD_GUEST_BIN` for rung a, with
   `bin/ud_guest.otool.txt` (`MH_MAGIC_64 X86_64` + expected loads). Overlay
   dylibs are not required at link time; rung a still needs them at load.
   The scoreboard guest is the same pipeline through the committed
   `foundation-macho/scripts/build_ud_score_guest.sh`: same FE objects,
   libCFTest, libswiftcompat, x86 tbds, clang-18, `-nostdlib`, one
   `_RopeModule.o`. Output is `scratch/ud-guest-x86_64/bin/ud_score_guest`
   with `ud_score_guest.otool.txt` beside it. The golden is the carried
   `full/oracle-userdefaults/darwin-golden-2026-08-28.txt` embedded by
   `gen_guest_golden.py` (the arm64 recipe still requires a pre-staged
   `$W/oracle/GuestGolden.swift`; no-arg argv is unchanged). Stamp is
   `bin/ud_score_guest.inputs` (object shas + libCFTest sha + link argv);
   reuse only on match. Prints `ENV_PREPARE ud-score-guest
   cold-built|satisfied`. Rung a then runs `run_ud_persist.sh` (already
   wired, success bar unchanged) and reports that script's `GUEST
   SCOREBOARD` / `PORT: scored` denominators. Absent binary is still
   `CANNOT_UD_SCOREBOARD` — persist is not faked.
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
    byte-identical because staged arm64 `libSystem` exports none of them),     `libswiftCore.dylib` (already
    from `mrroot-base-x86`), and the **twelve** overlay dylibs
    (`phase2_twelve_overlay_names`: nine FE + `libswift_Concurrency.dylib` /
    `libswiftObjectiveC.dylib` / `libswiftObservation.dylib`) in both
    `mrroot-x86_64` and `mrroot_fe-x86_64`, then **restages the same twelve
    into the run root** `scratch/mrroot_full-x86_64` (always overwrite from
    artifacts; a dest that is already an x86 Mach-O is not kept — that skip
    is how `libswiftObjectiveC` stayed the Apple dyld-cache extract while
    Darwin / `_errno` / `_Concurrency` came from artifacts). ObjectiveC /
    `_DarwinFoundation*` / `_errno` come from
    `swiftcore-macho/artifacts/swift-macosx/x86_64` (in-tree shells).
    A dyld-cache extract (no `LC_DYLD_INFO`, no `LC_DYLD_CHAINED_FIXUPS`)
    is `CANNOT_STAGE_CACHE_EXTRACT name=… src=…`, not staged. End of
    staging prints one `OVERLAY_PROVENANCE name=… srcdir=… sha256=… fixups=dyld_info|chained`
    line per overlay (`llvm-objdump --macho --private-headers`). Host ELF files
    are the same closed set as `mrroot-host-x86`. Incomplete layout is
    `CANNOT_X86_MRROOT_LAYOUT missing=…` (leaf names). Not a PR3
    `CURSOR_ENV_CANNOT_*` marker. Rungs b/c wait on `LAYOUT_OK`; rung a does
    not run `build_full`. The ud_guest port/runner argv also takes
    `-I $fe_out/collections` (plus the staged `$ud_w/fe/collections`) so
    swiftc sees `OrderedCollections` / `_RopeModule` the way
    `build_url_runner.sh` / PR #28 put FI search paths on argv.

## Operator-staged Apple x86_64 overlays (dead end)

`scratch/apple-x86-overlays/` used to hold Apple's x86_64 Swift overlays
extracted from the dyld shared cache. Those binaries carry **no**
`LC_DYLD_INFO` and **no** `LC_DYLD_CHAINED_FIXUPS` (only
`LC_DYLD_EXPORTS_TRIE`); rebases and binds were resolved in-cache and
stripped. They cannot be loaded. `_DarwinFoundation1/2/3`, `_errno`, and
`ObjectiveC` are built from in-tree `.swiftinterface` / re-export shells
and `overlays/ObjectiveC.swift` (`overlay_build_xcode_shells`) and staged
in `swiftcore-macho/artifacts/swift-macosx/x86_64`. Staging into a run
root refuses a cache extract (`CANNOT_STAGE_CACHE_EXTRACT`) rather than
falling back to `scratch/apple-x86-overlays`.
