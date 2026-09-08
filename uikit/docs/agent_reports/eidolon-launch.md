# Eidolon launch rung — measured work in progress

Date: 2026-09-07. Branch: `agent/eidolon-launch`. Route (b): Apple toolchain → Mach-O guest → machorun.

Corpus: artsy/eidolon commit `44486ed9149f16b3eb3a5e687f99ae078309f4fe`, tree `0ed18d46bbf1dfec16eb83b1df129eeeb48fa0c4`. The corpus lock and clone helper verify both identities. The source checkout remains clean. No vendor pin is changed.

## Step 1: pinned ingest

The PBX application target is **Kiosk**, with **109 present Swift files, 3 Objective-C files, 4 headers, 0 missing Swift files**. The ladder's 159 Swift files include 50 test files. The raw ingest records **1 CocoaPods gap, 31 imports, 30 unprovided modules**. These are import inventory counts, not semantic compiler errors.

`Tools/ingest/xcodeproj_to_package.py` now accepts `--library --module-name Eidolon` so target selection and module identity are independent. It emits a separate Swift/Clang diagnostic library package under `Sources/Eidolon`; every one of the **116 upstream source/header files is byte-identical**, including `@UIApplicationMain`. It does not insert an incomplete app target into the default renderer graph. A separate entry-point adapter/link arrangement still has to be validated before the library can launch. Source hashes and commit/tree are carried in `Sources/Eidolon/PROVENANCE.json`; upstream MIT license is in `THIRD_PARTY_LICENSES/Eidolon-MIT.txt`.

Apple Swift 6.2.1 `-frontend -parse -swift-version 4 -module-name Eidolon` on all **109** app Swift files returns **0**. This proves syntax parsing, not type-checking or linking.

Reproduce from `uikit/`:

```sh
bash ../.cursor/clone-pinned-repo.sh --lock ../.cursor/scratch-corpus-pins.json --id eidolon --repo-root ..
python3 Tools/ingest/xcodeproj_to_package.py ../scratch/ladder-corpus/eidolon/Kiosk.xcodeproj --target Kiosk --allow-gaps --library --module-name Eidolon --out /tmp/eidolon-launch-library
python3 -m unittest discover -s Tools/ingest -p 'test*.py'
```

Ingest fixture checks: **21 passed / 20 corpus-dependent skipped** (41 discovered). With the shared external full corpus supplied, **39/41 pass**; two existing Pocket Casts assertions still expect pre-Simplenote behavior (AutomatticTracks missing and the old mixed-source refusal). Those unrelated expectations are unchanged by this work.

## Blocker table

| blocker | measured state |
|---|---|
| CocoaPods build graph | Fresh Xcode simulator build exits 65 at absent `Pods-Kiosk.debug.xcconfig`; resolver investigation continues. |
| Dependency identity | `Podfile` requests Stripe 14.0.1; the committed lock says 12.1.0. No silent upgrade or invented matching pin. |
| NIB runtime | All 3 Interface Builder inputs compile; custom-class/outlet runtime loading and first screen remain unproven. |
| Services | Empty API keys select upstream bundled sample responses; unavailable services must refuse before delegate initialization. |
| App compile / guest / first-screen oracle | Not reached in step 1. Score **N/A → N/A**. |

Further step measurements and final regression/merge proof will be appended before pushing.
