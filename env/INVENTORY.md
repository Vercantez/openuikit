# Verification environment contract inventory

Measured 2026-09-02 on this branch after consuming PR #3
(`391d335` — Cursor cloud corpus + Mach-O products + `CURSOR_ENV_CANNOT_*`).

This file is the **first increment**: where environment knowledge currently
lives, with `file:line`. No behavior change. The gates and their refusals stay
exactly where they are until later commits move the *data* into
`env/contract.json` and materialize it with `scripts/env/prepare.py`.

**Scan denominator (34 primary files, this commit):**

| kind | hits | files |
|---|---:|---:|
| checkout pins (`EXPECTED_*` commit/tree) | 80 | 6 |
| product / `libswiftCore` hash | 56 | 8 |
| `CURSOR_ENV_CANNOT_*` markers | 17 | 4 |
| `safe.directory` | 3 | 2 |
| mode `0700` | 9 | 2 |
| ancestor-trust | 5 | 3 |
| `mktemp` | 12 | 8 |
| `mrroot` / `mrroot_fe` | 11 | 5 |
| `sysroot_fe4` / `libSystem.tbd` | 47 | 11 |
| machorun loader | 35 | 11 |
| poppler / pdftocairo | 8 | 1 |
| `clang-18` alias | 48 | 8 |
| in-repo vendor pin | 47 | 8 |

Those 34 files are the **environment** surface. Hundreds of additional
`EXPECTED_*` hashes in `full/*/tests/test_*_host.sh` are **gate product**
pins (app-source identity), not host/sysroot/checkout environment. They are
out of scope for the contract file except where a gate also demands an
environment row below.

The 14 sequential refusals measured on the ARM64 EC2 authority while bringing
up `full/swiftui/build_focus_widget_guest.sh` map onto this inventory 1:1
(every refusal was correct; none was discoverable without running):

| # | refusal | lives at |
|---:|---|---|
| 1 | git dubious-ownership | `scripts/vendor_tree.sh:26,56,66` (`git -C` without `-c safe.directory`); `full/swiftui/build_focus_widget_guest.sh:211`; `full/foundation/pinned_inputs.pl:59-61` |
| 2 | 0700 proof parent | `full/focus-ios/onboarding_uikit_proof.py:858-860`; `full/focus-ios/onboarding_resources_proof.py:666`; `uikit/scripts/prove_focus_widget_swiftui_runtime.sh:150` |
| 3 | ancestor-trust | `full/focus-ios/onboarding_uikit_proof.py:863-882`; `full/swiftui/focus_widget_guest_attest.pl:235`; `full/swiftui/test_focus_widget_guest_adversarial.sh:173-179` |
| 4 | mktemp root | `full/swiftui/build_focus_widget_guest.sh:136,159,295,1069` (`mktemp` under `$FULL`); `full/frameworks/run_core_guest_package_docker.sh:256` |
| 5 | missing machorun loader | `full/scripts/build_full.sh:221-236`; `full/swiftui/build_focus_widget_guest.sh:278-284`; `full/frameworks/build_core_guest_package.sh:582` |
| 6 | missing `scratch/swift-collections` | `.cursor/scratch-corpus-pins.json:23-29`; `full/foundation/pinned_inputs.pl:29-37`; `full/scripts/build_full.sh:81-82` |
| 7 | missing `darwin/usr/lib/swift/libswiftCore.dylib` sha `dd01686e…` | `swiftcore-macho/artifacts/swift-macosx/arm64/libswiftCore.dylib` (content); `full/oracle-opencombine/policy.json:92,128`; `full/scripts/stage_swift_core_runtime.py:96-101`; `full/scripts/build_full.sh:211-309` |
| 8 | missing `scratch/mrroot` + `mrroot_fe` | `full/scripts/build_full.sh:47-48,270-340`; `full/foundation/stage_swift_overlays.sh:40-49`; `full/frameworks/run_core_guest_package_docker.sh:260-267` |
| 9 | stale `sysroot_fe4` `libSystem.tbd` | `full/foundation/stage_fe_sysroot.sh:1-23,41-44`; `machorun/scripts/gen_tbd.sh` CHECK 1; `.cursor/install-built-products.sh:72-83`; `full/swiftui/build_focus_widget_guest.sh:417` |
| 10 | stale in-repo pin | `scripts/vendor_pins.sh:8-9` vs live `HEAD:uikit` / `HEAD:machorun` (see §Drift) |
| 11 | missing OpenCombine export artifacts | `.cursor/install-built-products.sh:181-184`; `full/swiftui/build_focus_widget_guest.sh:226-243` |
| 12 | missing FE sysroot | `full/scripts/build_full.sh:68-70`; `full/foundation/stage_fe_sysroot.sh` (macOS-only) |
| 13 | clang alias / toolchain | `.cursor/install-built-products.sh:27-30`; `.cursor/verify-cloud-environment.sh:49-78`; `harness/Dockerfile:10-21` |
| 14 | then a genuine code bug | (not environment; out of scope) |

---

## 0. Cloud seed (PR #3) — consume, do not duplicate

PR #3 is already the declarative half for the Cursor x86_64 VM. Later
commits must **call** these scripts, not rewrite them.

| file | lines | what it encodes |
|---|---|---|
| `.cursor/scratch-corpus-pins.json` | 1-38 | 4 public checkouts: name, GitHub URL, commit, tree, dest under `scratch/` + pinned `swift:6.2-noble@sha256:29b983751c605c2d3102d2ab93438c6e0cadf110d9d2aa6e929b6dec9dcb7cbc` |
| `.cursor/clone-pinned-repo.sh` | 1-132 | commit+tree clone; `safe.directory` per dest (75-78); origin guard; reuse-if-valid |
| `.cursor/install-scratch-corpus.sh` | 1-41 | 4/4 corpus; extra `pinned_inputs.pl verify` (32-38) |
| `.cursor/install-built-products.sh` | 1-280 | cold-build darwin/objc4/quartz; stage in-repo `libswiftCore`; honest `CURSOR_ENV_CANNOT_*` (7 markers); tree hashes |
| `.cursor/verify-cloud-environment.sh` | 1-326 | tools, macios evidence, corpus pins, product hashes, `CURSOR_ENV_SUMMARY` |
| `.cursor/cursor-env.sh` | 1-50 | `cursor_env_attest` / `cursor_env_cannot_execute_arm64` / toolchain mode |
| `.cursor/refuse-arm64-execution.sh` | 1-17 | canonical `CURSOR_ENV_CANNOT_EXECUTE_ARM64` (exit 2) |
| `.cursor/attest-cursor-env.sh` | 1-41 | stamp + live fingerprint |
| `.cursor/toolchain-fingerprint.sh` | 1-26 | arch, clang-18, ld64, os, swift line |
| `.cursor/tree-digest.py` | 1-44 | sorted path + sha256 / symlink target |
| `.cursor/environment.json` | 7 | install chain: evidence → corpus → products → verify |
| `.cursor/test-cloud-environment.sh` | 1-188 | 25/25 unit teeth for the above |

`CURSOR_ENV_CANNOT_*` spellings today (17 hits / 4 files):

| marker | defined |
|---|---|
| `CURSOR_ENV_CANNOT_BUILD_LOADER` | `.cursor/install-built-products.sh:46,204` |
| `CURSOR_ENV_CANNOT_GENERATE_TBD` | `:81,205` |
| `CURSOR_ENV_CANNOT_STAGE_MRROOT_LOADER` | `:176,206` |
| `CURSOR_ENV_CANNOT_STAGE_XCODE_DARWIN_OVERLAYS` | `:164,210` |
| `CURSOR_ENV_CANNOT_STAGE_SIMRUNTIME_OVERLAY_DYLIBS` | `:179,211` |
| `CURSOR_ENV_CANNOT_BUILD_OPENCOMBINE_EXPORT` | `:183,214` |
| `CURSOR_ENV_CANNOT_BUILD_MODCACHE_SWIFTUI_GUEST` | `:189,216` |
| `CURSOR_ENV_CANNOT_EXECUTE_ARM64` | `.cursor/refuse-arm64-execution.sh:15`; gates at run step |

`NEEDS_DARWIN_BASELINE` is **not currently emitted** (0 hits). It is the
missing unified name for the Xcode-overlay + simruntime pair above.

---

## 1. Required checkouts

| id | URL | commit | tree | dest | demanded by (file:line) |
|---|---|---|---|---|---|
| focus-ios | `https://github.com/mozilla-mobile/focus-ios.git` | `a2832521…9791` | `065d8e37…1d7e` | `scratch/ladder-corpus/focus-ios` | `.cursor/scratch-corpus-pins.json:10-15`; `full/swiftui/build_focus_widget_guest.sh:15,55,211` |
| swift-foundation | `https://github.com/apple/swift-foundation.git` | `c6793ef0…dcfc` | `46517986…1486` | `scratch/swift-foundation` | pins.json:17-21; `full/foundation/pinned_inputs.pl:18-27`; `full/frameworks/build_core_guest_package.sh:283-284,704` |
| swift-collections | `https://github.com/apple/swift-collections.git` | `9bf03ff5…fd06` | `5e4de96f…3c27` | `scratch/swift-collections` | pins.json:23-29; `pinned_inputs.pl:29-37`; `build_core_guest_package.sh:290-291,707` |
| opencombine | `https://github.com/OpenCombine/OpenCombine.git` | `1c6f02c7…037b` | `66a9d91e…594a` | `scratch/opencombine-core-durable-20260828-r2/source` | pins.json:31-36; `build_core_guest_package.sh:292-293,708`; widget `:30-33` |
| swift-foundation-icu | `https://github.com/apple/swift-foundation-icu.git` (implied; **not** in pins.json) | `87dbab99…b39a` | `823a4a2a…fd39` | `scratch/swift-foundation-icu` | `build_core_guest_package.sh:285-286,705-706`; `full/xcodeplan/build_true_ios_platform_frameworks.sh:110-117` |
| dotnet-macios | `https://github.com/dotnet/macios.git` | `cd624873…0e79` | (sparse `src`) | `/opt/openuikit-evidence/dotnet-macios` | `full/framework-fanout/external-evidence-sources.json:31-42`; `.cursor/verify-cloud-environment.sh:82-148` |
| uikit (in-repo) | subtree `HEAD:uikit` | — | `scripts/vendor_pins.sh:8` `719f6bcf…5a959` | `uikit/` | `scripts/vendor_tree.sh:40-73`; widget `:198`; `build_full.sh:209` |
| machorun (in-repo) | subtree `HEAD:machorun` | — | `scripts/vendor_pins.sh:9` `42d42ace…f70c8` | `machorun/` | widget `:200`; `build_full.sh:210`; `build_core_guest_package.sh:294,699` |

**Drift, measured this commit (do not paper over):**

```
vendor_pins.sh  HEAD:uikit = 719f6bcfe2a8e467426f30c91390d9c605f5a959
live            HEAD:uikit = bd3eef4d230903199edc6e8aa62538177b25785f
docs/tests still cite      8ce87c1aef592553336aadf9101ec2bb4ebe6aaa
vendor_pins.sh  HEAD:machorun = 42d42ace9c6ff7a4ae7c25c3a8e466f82d5f70c8
live            HEAD:machorun = 80228dcf3c743af1bfd877bf8b556b97cdc48b0e
```

`scripts/vendor_pins.sh:3` forbids editing pins to hide a failing proof. The
preparer must **report** this as unsatisfied, not advance the pin.

**Dangerous duplicate:** `full/foundation/fetch_sources.sh:39-40` clones by
**tag** (`release/6.2.2`, `1.1.3`), not commit+tree. That is the class of
error `pinned_inputs.pl` exists to refuse. Do not teach the preparer this
script.

---

## 2. Required built products

| path | producer | pin | demanded by |
|---|---|---|---|
| `machorun/build/machorun` | `machorun/scripts/build.sh` loader | cold-build; aarch64 ELF; **cannot** on x86_64 (`tlv_asm.S`) | `build_full.sh:221`; widget `:283`; `build_core_guest_package.sh:582`; `.cursor/install-built-products.sh:32-51` |
| `machorun/darwin/usr/lib/{libSystem.B,libc++.1,libc++abi,libobjc.A,libquartz,libswiftcompat}.dylib` | `machorun/scripts/build.sh` darwin + `build_objc4.sh` + `build_quartz.sh` | cold-build arm64 Mach-O via `clang-18 -target arm64-apple-macos11` | install-built-products.sh:53-97 |
| `scratch/sysroot_fe4` | macOS: `full/foundation/stage_fe_sysroot.sh`; Linux subset: install-built-products.sh:99-164 | tree hash recorded in `scratch/.cursor-built-products.json`; Xcode overlays CANNOT on Linux | `build_full.sh:40,68`; widget `:21` |
| `scratch/mrroot_full` | `full/scripts/build_full.sh:202-364` + `scripts/require_fresh_root.sh` | manifest kinds copy/renamed/umbrella/staged; loader copy only on aarch64 | widget `:22`; `build_full.sh:43` |
| `scratch/modcache_swiftui_guest` | Focus SwiftUI guest compile | **do not create empty**; CANNOT without full FE sysroot | install-built-products.sh:186-190; widget `:23` |
| `scratch/opencombine-core-durable-20260828-r2/export/artifacts` | `full/oracle-opencombine/build_and_run.sh` (run under machorun) | object/module/doc hashes in widget `:75-83` | widget `:226-231` |
| `sdk/usr/lib/*.tbd` | `machorun/scripts/gen_tbd.sh` | CHECK 1 requires loader export table; empty `.tbd` is a linker lie | install-built-products.sh:72-83,192-199 |

---

## 3. Required staged externals

| path | source | sha256 | demanded by |
|---|---|---|---|
| `machorun/darwin/usr/lib/swift/libswiftCore.dylib` | `swiftcore-macho/artifacts/swift-macosx/arm64/libswiftCore.dylib` via `machorun/scripts/stage_swiftcore.sh` | `dd01686e06c81a21755bb864b43dad446c011e6c60c6b387b3b332c0a12708cb` | `full/oracle-opencombine/policy.json:92,128`; `full/scripts/stage_swift_core_runtime.py`; core package `--expected-machorun-swift-core-sha256` |
| `scratch/mrroot/darwin/usr/lib/swift/*.dylib` except libswiftCore | spike base runtime (`scratch/mrroot`) | byte-identical copy | `build_full.sh:47,270-301` |
| `scratch/mrroot_fe/darwin/usr/lib/swift/libswift{Darwin,Synchronization,_Builtin_float,_DarwinFoundation{1,2,3},_RegexParser,_StringProcessing,_errno}.dylib` | iOS CoreSimulator runtime via `full/foundation/stage_swift_overlays.sh` (**macOS only**) | recorded in that root's `.manifest` staged rows | `build_full.sh:48,317-340` |
| `scratch/mrroot/host/{libdispatch,libBlocksRuntime}.so` | `/usr/lib/swift/linux/` | `39e502b3…` / `47a4f774…` (`build_core_guest_package.sh:402-405,2457-2459`) | `build_full.sh:346-364` |
| `/usr/share/fonts/truetype/dejavu/DejaVuSans{,-Bold}.ttf` | distro fonts | `ae7b7855…` / `5c1247ac…` | widget `:71-74,224-225` |
| poppler `pdftocairo` | Homebrew 25.04.0 or Ubuntu noble `poppler-utils=24.02.0-1ubuntu9.9` | profile table `onboarding_resources_proof.py:164-183` | resource-bundle producer for the widget gate input |

---

## 4. Host requirements

| requirement | where |
|---|---|
| arch: x86_64 = compile/link/static only; aarch64/arm64 = execution authority; Darwin = macOS oracle local-only | `.cursor/refuse-arm64-execution.sh`; `cursor-env.sh:22-29`; PR #3 proof split |
| toolchain: Swift 6.2.4 linux, LLVM/clang-18, `ld64.lld-18`; image `swift:6.2-noble@sha256:29b983751c605c2d3102d2ab93438c6e0cadf110d9d2aa6e929b6dec9dcb7cbc` | `harness/Dockerfile:10`; `.cursor/scratch-corpus-pins.json:3-7`; `verify-cloud-environment.sh:267-271` |
| `clang` on PATH is Swift's clang 17 — Darwin/objc4/quartz **must** use `CC=clang-18` / `DARWIN_CLANG=clang-18` | `install-built-products.sh:27-30` |
| unversioned `llvm-nm`/`llvm-otool`/`llvm-objdump` must resolve to `*-18` | `verify-cloud-environment.sh:62-78` |
| tools: swift, swiftc, clang{,++, -18}, ld64.lld{,-18}, llvm-{nm,otool,objdump}{,-18}, perl, patch, jq, sha256sum, shasum, cmp, file, git, python3, pkg-config | `verify-cloud-environment.sh:49-59` |
| core-guest extra: readelf, ldd, curl-config, find, sort | `build_core_guest_package.sh:568-572` |
| zstd | campaign transfer scripts (`ops/campaigns/2026-09-01-fwseed-r1/ec2_import_core_cold_20260901.sh:42`) |
| poppler/pdftocairo | `onboarding_resources_proof.py:164-183` |
| fingerprint | `.cursor/toolchain-fingerprint.sh` hashed into `scratch/.cursor-env-attestation.json` |

---

## 5. Filesystem preconditions

| rule | where | meaning |
|---|---|---|
| git `safe.directory` for every checkout git will touch | `.cursor/clone-pinned-repo.sh:75-78`; **absent** from `scripts/vendor_tree.sh` and the Focus/core gates | without it, git prints dubious-ownership and the gate never starts |
| proof output parent: euid-owned, mode `0700` | `onboarding_uikit_proof.py:855-860`; `onboarding_resources_proof.py:666` | world-writable `/tmp` is not a proof parent |
| ancestor trust: owner in `{0, euid}`; no group/other write unless sticky+protected child; no extended ACL | `onboarding_uikit_proof.py:863-882` | |
| proof root itself mode `0700` | `onboarding_uikit_proof.py:1068-1071` | |
| mktemp dest must be a real directory (Focus uses `$FULL/.focus-widget-*.XXXXXX`) | widget `:136,159,295,1069` | `$W/build/full` must exist before those calls |
| macios evidence parent `root:root:755`; evidence tree root-owned, not writable, no symlinks | `verify-cloud-environment.sh:133-148` | |
| no symlink in resource/input trees | widget `:245-250`; `core_package_manifest.py:221-248` | |
| `require_fresh_root.sh` refuses vacuous greens (0 graded files) and prints denominators | `scripts/require_fresh_root.sh:266-341` | |

---

## 6. Hash / ledger logic still in shell (migrate next)

`full/frameworks/build_core_guest_package.sh` is 7210 lines. Python already
owns package manifests (`full/frameworks/core_package_manifest.py`, 1948
lines: `sha256_file`, `require_regular_no_link`, inventory, write/verify).
The **shell still duplicates** the data plane:

| function | lines | job |
|---|---|---|
| `hash_file` | 630 | `sha256sum` |
| `require_hash` | 644-649 | regular-file + hash or `core_guest_package: REFUSING --` |
| `assert_clean_commit` | 651-663 | commit+tree+dirty |
| `assert_exact_swift_set` | 665-681 | Git vs physical Swift set |
| baked `EXPECTED_*` | 243-409 | checkout pins, plugin hashes, OpenCombine hashes, fonts, host `.so` |
| `require_hash` call sites | 700+ … 7144 | pre/post attestation |

`full/swiftui/build_focus_widget_guest.sh:85-105` has a **second**
`hash_file` / `require_hash` / `tree_digest` with **different refusal text**
(`focus_widget_guest: $label drifted` vs `core_guest_package: REFUSING --
$label hash`). Unifying the implementation must keep both texts.

`full/scripts/build_full.sh` and `scripts/require_fresh_root.sh` are further
ledger copies (manifest kinds, sha256, denominators).

---

## 7. What later increments must not do

- Do not touch `machorun/src` or `machorun/darwin` (other agents).
- Do not touch any x86_64 port surface.
- Do not rewrite `.cursor/*` from PR #3; call them.
- Do not change a hash, marker spelling, or refusal string without saying why.
- Do not advance `scripts/vendor_pins.sh` to match live `HEAD:uikit`.
- Do not teach the preparer `fetch_sources.sh` tag clones.
- Do not invent empty `.tbd` files or empty `modcache_swiftui_guest`.
- Print denominators on every summary line (`satisfied/cold-built/staged/CANNOT`).
