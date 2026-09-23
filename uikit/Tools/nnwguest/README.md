# NetNewsWire guest frontier (measurement only)

`run.sh` builds NetNewsWire's unmodified module chain
(`docs/agent_reports/netnewswire-launch-chain.json`) for the Linux Mach-O
guest on the iOS triple and prints one line per target:

```
NNWG <target> OK
NNWG <target> FAILED errors=<n> first=<first diagnostic>
NNWG <target> OK|FAILED kind=clang sources=<n> errors=<n>
```

Once every target builds, the NetNewsWire executable is linked (`NNWG_LINK`)
and `NetNewsWire.app` is staged with `stage_bundle.py`. Nothing is run yet.
The script builds for real, with no
allow-errors. A failing module is compiled a second time with allow-errors,
so the modules after it are still measured against an interface. It is the
Swift-guest counterpart of the simulator route's chain census, and it stops
at the same place a real guest build would.

How it runs:
- A diagnostic copy of `full/scripts/build_full.sh` sources `graph.inc`
  right after the guest Apple-name modules (CoreGraphics, Security). That is
  where `compile_app_module`, `compile_app_objc`, `compile_app_c` and
  `OBJC_SWIFT_FLAGS` exist.
- A copy of `full/iostarget/ios_guest.sh` runs the diagnostic build inside
  the guest container.
- `build_full.sh` refuses a dirty `uikit/`, so commit before running.

`plan.py` turns the chain spec into the build lines:
- C and Objective-C targets: each `.c` / `.m` file is compiled, and a Clang
  module map is written over the public headers.
- Swift targets: the target's upcoming features and defines are applied, and
  the Clang maps of the C/ObjC targets are passed in.
- A SwiftPM `resources:` target gets Xcode 26.1's `Bundle.module` accessor
  (`full/xcodeplan/swiftpm_resource_accessor.py`, stem
  `<Package>_<Target>`) and a copied `<stem>.bundle`.

```sh
bash uikit/Tools/nnwguest/run.sh TREE CORPUS CHECKOUTS GENERATED [WORK]
```
