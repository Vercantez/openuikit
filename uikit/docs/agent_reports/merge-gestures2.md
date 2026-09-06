# Merge gestures guest route after Focus

Merge-only integration of `origin/agent/gestures-guest-route` (`05195b69`)
onto the supplied current `origin/main` (`5f17fd1a`), including Focus
(`71c8fc1e`). No new fidelity rule or oracle constant.

## Resolution

- `NSItemProvider.swift`: one conditional import block retains Focus's
  `ObjectiveC.NSObject` guest import plus the incoming explicit Foundation
  NSObject import and FoundationEssentials.URL. Darwin uses Foundation's
  provider and existing image/color helpers; Linux retains the locked
  representation store and callback queue plus the drag `_canLoad` / `_load`
  and file-URL initializer. The Foundation-hidden guest keeps the incoming
  process-local provider. The resolved file is identical to `05195b69`:
  its import block already includes main's only independent edit.
- `FocusLaunchCompat.swift`: removed the duplicate placeholder drag/drop
  declarations and the two no-op `UIView.addInteraction` overloads. Focus's
  URLBar and BrowserViewController now compile against the shared measured
  family in `UIDragDrop.swift`; its interaction registration is retained.
  All other Focus compatibility additions remain unchanged. The initial
  unresolved consolidation build diagnosed duplicate `UIDropProposal` and
  ambiguous drag/drop types; the resolved build has no such errors.
- `docs/REAL_APP_TEST.md`: union of the measurement rows, keeping the newer
  Focus entries before the earlier gestures guest-route entry. Verified all
  132 main rows and all 129 incoming rows survive verbatim. This report's
  validation row is added at the top.
- Gesture, drag/drop, pasteboard, and provider behavior comes from the
  incoming reports `uikit-gestures-dnd.md` and `merge-gestures.md`.
  GestureProbe, iPhone SE 2x / iOS 26.1 remains unchanged: pinch activation
  10 pt / hysteresis 8 pt (110/108 scale); rotation activation 10 degrees /
  hysteresis 5 degrees (0.087266465 radians at 10 degrees); drag lift
  0.325 seconds / 10 pt.

## Validation

- Focused tests: 42/42, zero failures (Pinch 5, Rotation 1, Hover 1,
  ScreenEdge 2, DragDrop 8, ValueTypeTail 15, Pasteboard 10).
- `swift build --target Blockzilla`: zero errors, complete in 1.18 s
  after the test-bundle build.
- Foundation-hidden guest: `GUEST_ROUTE_COMPILE_OK openuikit=139
  opencoregraphics=12`, `GUEST_ROUTE_CHECK_OK elapsed=74s`.

| Measurement | Main `5f17fd1a` | Merged tree |
|---|---|---|
| Catalyst | 124/124 scenes | 124/124; 178/178 PNGs pixel-identical to main |
| Fresh iOS 26.1 suite, private SE 2x / iPhone 16 3x | 112/113 | 112/113; 113/113 PNGs pixel-identical to main |
| Sole iOS miss: `corner_radius` | 99.411 | 99.411 |
| Real-app renders at iOS scale 3 | 15 PNGs | 15/15 pixel-identical to main |

The full iOS suite was captured fresh with `SIM_DEVICE_SUFFIX=-merge-gestures2`,
then replayed with `SKIP_CAPTURE=1`. Main was exported from git to a separate
`/tmp` build and rendered against those same goldens. Pixel identity above
means equality of every RGBA array, not just the aggregate pass count.

Real-app scores (unchanged): history **99.137**, settings light **98.535**,
settings dark **98.548**, storage **99.469**, settings XS **98.639**,
XXXL **98.133**, AX1 **97.516**, settings iPad **99.650**, Focus settings
**82.170**, history iPad **99.860**, storage iPad **99.734**, Hackers feed
**85.393**. All 12 operator floors hold. Focus home, Ledger, and Focus
browser have no simulator golden in `/tmp/golden_realapp_ios`; their output
PNGs are nevertheless pixel-identical to main. They are not counted as
oracle passes.

Linux `swift:6.2-noble`, clean copy excluding `.build` / `Package.resolved`:
`openrender` release **264.63 s**, `ConformanceApps` release **4.12 s**,
`OpenUIKitTests` debug **25.60 s**, all exit 0.

## Operator check

From the disposable monorepo root `/tmp/merge-gestures2-operator`:

```sh
CHECK_ONLY=1 uikit/scripts/agent_merge.sh agent/merge-gestures2
```

**Exit 0: `checks passed (CHECK_ONLY)`.** The script is byte-for-byte the
repository's script; no skipped checks, ALLOW_DROP, or widened scope.

The operator's local main was `009fa373`, behind the supplied baseline by
an already-landed Photos commit. The disposable clone set its local main
to the supplied `origin/main` (`5f17fd1a`) and checked the committed branch
`908a5493` in the script's fresh merged worktree. This prevents that existing
Photos commit from being misattributed to this merge; the operator's main
worktree was untouched. Only the report and fidelity row were finalized
after this check; the checked source/test/package tree is unchanged.

- Scope and conflict-free trial merge passed.
- Clean macOS release `openrender`: **170.07 s**; Catalyst **124/124**.
- Guest route: **139+12 files**, **54 s**, both success markers.
- Clean full test-bundle build: **29.91 s**, exit 0.
- All **12** real-app floors held at the scores above.
- Conformance: **707** graded frame scores, **0** changes against the
  scoreboard, no dropped frames or regression exceptions.
- Linux release `openrender`: **179.62 s**. The second fresh-container
  `openrender` + `ConformanceApps` + `OpenUIKitTests` chain also exited 0.
- This script version does not invoke `ios_suite.sh`; the fresh capture
  and same-golden main comparison above supply that required check.

No new measurement rule, golden edits, pin changes, or changes outside
`uikit/`. No `Package.resolved` or probe app bundles committed. No PR.


Logs and captures are under `/tmp/merge-gestures2-*.log`,
`/tmp/suite-merge-gestures2`, `/tmp/gate-merge-gestures2`,
`/tmp/app-merge-gestures2`, and `/tmp/guest-route-merge-gestures2`.
