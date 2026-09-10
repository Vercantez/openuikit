# OpenUIKit — run real iOS apps on Linux

This repository builds and runs **unmodified source from shipping open-source
iOS apps on Linux**, and grades the result pixel-for-pixel against a real
iPhone running iOS 26.1.

Not a simulator, not a re-skin, not a screenshot diff of something similar: the
app's own Swift files are compiled against a port of UIKit / SwiftUI /
Foundation / CoreGraphics / CoreAnimation, rendered headlessly on Linux, and
compared against a capture taken from Apple's own frameworks on the device the
golden names.

```
   iOS app source (unmodified)
              │
              ├── native route ──►  Linux ELF binary  ─────────────┐
              │                     (Swift-only apps)              │
              │                                                    ├──►  rendered
              └── guest route  ──►  Mach-O binary  ──► machorun ───┘      screen,
                                    (apps needing ObjC interop)           scored vs iOS
```

---

## What is proven today

| Claim | Where the evidence lives |
| --- | --- |
| A real UIKit app screen compiles **as written** and renders identically on Linux and macOS, byte for byte | `uikit/docs/REAL_APP_TEST.md` — 99.3 % of the vendored source untouched, and the 4 changed lines are named and explained |
| A whole real app (Mozilla **Focus**, the `Blockzilla` target, 129 upstream Swift files, never patched) launches and renders on Linux | `uikit/docs/agent_reports/focus-launch.md` |
| 15 real-app screens render on the Linux guest and match their pinned images byte for byte on every run | `uikit/scripts/linux_guest_realapp_verify.sh` → `REAL-APP SCREEN VERIFIED ON LINUX` |
| Fidelity is measured against **real iOS captures**, never against our own output | `uikit/goldens/ios/`, `uikit/Tools/compare/compare_realapp.py` |
| 832 scored rows (707 of them conformance), Catalyst suite 124/124 | `uikit/scoreboard/latest.json` |
| 20 open-source iOS apps measured for what actually blocks them; 7 of the 9 nearest now have **zero** blocking UIKit rows | `full/ladder/APP_LADDER.md` §9.6 |

Every number here is reproducible by a command in this repo. Where something is
*not* proven, the reports say so under a "walls" or "open" heading. That
convention is deliberate and load-bearing.

---

## Quick start

**Requirements:** Docker. The clone is small, but the pinned app corpus is
about 3.5 GB and the build products add several more, so give it room. An Apple
machine is needed only to *capture new golden images*, never to run what is
already here.

```bash
git clone git@github.com:Vercantez/openuikit.git
cd openuikit

# 1. One-time environment: pinned corpus, static evidence, prebuilt products.
bash .cursor/install.sh

# 2. Render the real-app screens on Linux and byte-compare them.
cd uikit && bash scripts/linux_realapp_verify.sh
```

The second command prints `REAL-APP SCREEN VERIFIED ON LINUX` when the Linux
render matches screen for screen. It builds the port, builds the app source,
renders headless, replays a recorded interaction script against the live
screen, and diffs both sets.

To score a screen against the real iOS golden instead of against the pin:

```bash
cd uikit
OPENUIKIT_REALAPP_SCALE=3 .build/release/openrender realapp /tmp/out fixtures/realapp/assets
python3 Tools/compare/compare_realapp.py \
    --golden goldens/ios/golden_realapp_ios --out /tmp/out \
    --scale 3 --golden-straight-alpha
```

The passing bar for a real-app screen is **97.5**.

---

## The two routes, and which one an app needs

**Native route (Linux ELF).** The app's Swift is recompiled by the Linux Swift
compiler against OpenUIKit and linked as an ordinary Linux binary. Fastest and
simplest. It works for apps whose code and dependencies avoid Objective-C
dynamism, because the Linux compiler rejects `#selector` and `@objc` before
OpenUIKit is ever consulted. Verified by `uikit/scripts/linux_realapp_verify.sh`.

**Guest route (Mach-O under machorun).** The app is built as an `arm64-apple-*`
Mach-O — on Linux by the cross-toolchain, or on a Mac by Xcode — and executed on
Linux by `machorun`, our Mach-O loader, on top of Apple's own Swift runtime
rebuilt as Mach-O plus a Darwin-to-glibc `libSystem`. This route keeps full
Objective-C interop, so `#selector`, KVO, nib-shaped code and the ObjC runtime
all work. Verified by `uikit/scripts/linux_guest_realapp_verify.sh`.

`full/ladder/APP_LADDER.md` scores 20 real apps under both routes and says, per
app, exactly which types and how many call sites stand between it and running.

Building a guest tree from scratch:

```bash
cd machorun
bash scripts/build.sh            # loader + Darwin dylibs + .tbd stubs
bash scripts/build.sh objc4      # Apple's objc4 as a Mach-O dylib
bash scripts/build.sh quartz     # CoreGraphics + CoreAnimation
bash scripts/build.sh tbd
bash scripts/stage_swiftcore.sh ../swiftcore-macho/artifacts
cd .. && bash full/scripts/build_full.sh          # the app guest itself
```

---

## Bringing your own app

1. **Measure it first.** `full/ladder/` is the instrument: it walks an app's
   real file set, resolves its dependency closure, and reports which UIKit and
   Foundation types are *blocking* (a stub would draw a wrong screen) versus
   *stub-able*. `full/ladder/target_scope.py` restricts the walk to one Xcode
   target, so macOS-only code in a shared repo does not count against an iOS app.
2. **Ingest it.** `uikit/Tools/ingest/` turns an `.xcodeproj` into a Swift
   package graph — `xcodeproj_to_package.py` for a single target,
   `spm_app_chain.py` for an app that is really a stack of local packages —
   without editing a line of app source.
3. **Close the rows it names.** Every closed row in this repo has the same
   shape: measure the behaviour on a real device or simulator with a probe under
   `uikit/Tools/oracle2/`, commit the transcript, implement against the measured
   numbers, and add a test that fails before and passes after. There are roughly
   a hundred worked examples in `uikit/docs/agent_reports/`.

**The rule this project runs on: an oracle is a real Apple capture.** Not
documentation, not another reimplementation, not our own previous output.
`uikit/docs/KNOWN_GAPS.md` and the agent reports exist because that rule was
learned the hard way.

---

## Repository map

| Directory | What it is |
| --- | --- |
| `uikit/` | OpenUIKit, SwiftUI, Combine and the render stack; the scoreboard, goldens, probes and agent reports |
| `machorun/` | Mach-O loader for Linux with its own Darwin-to-glibc `libSystem`, plus objc4 and Quartz as Mach-O dylibs |
| `swiftcore-macho/` | Apple's Swift standard library cross-built on Linux as a Darwin Mach-O |
| `foundation-macho/` | The Foundation port: `NS*` over our CoreFoundation, plus the FoundationEssentials overlay |
| `quartz/` | Portable CoreGraphics + CoreAnimation (the CQuartz backend) |
| `full/` | Platform integration: the app guest build, the SDK framework ports, and `full/ladder/` (the 20-app measurement) |
| `scripts/`, `harness/`, `docs/` | Platform lineage, runtime notes, and the original spike write-up in `docs/SPIKE.md` |
| `objc4-linux/` | Retired: objc4 on Linux/ELF, superseded by the Mach-O build under `machorun/` |

Each imported directory keeps its complete git history through subtree merges.
Everything under `scratch/` and `build/` is generated and gitignored.

---

## How changes are verified

Nothing lands on `main` without passing `uikit/scripts/agent_merge.sh`, which
refuses any drop on the conformance board, any regression in the real-app
floors, and any change to the pinned vendor trees. Landed heads are then
re-checked on three independent authorities — an arm64 Linux box, an x86_64
Linux box, and a local container — before the next change goes in.

Start with `uikit/docs/REAL_APP_TEST.md` for what was proven and what was not,
and `full/ladder/APP_LADDER.md` for how far the next twenty apps are.
