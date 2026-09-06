# APP LADDER — pinch / rotation / hover / screen-edge + drag-and-drop

Process-local gesture and drag-and-drop surface for the types that block
route-(b) MID apps (full/ladder/APP_LADDER.md §8 Telegram 34 pinch uses,
ios-oss 9; §4 row 15 drag & drop). No pixel rule changed.

Probe: `/tmp/gestureprobe` (not in the repo). Device: iPhone SE 3rd gen 2x
(`OpenUIKit-2x-uikit-gestures-dnd` UDID `BCD046D3-C186-4C64-9722-A43686FE2B39`),
iOS 26.1. Transcripts in the sim container `Documents/gesture.txt` /
`gesture2.txt`. Two-finger sequences via the existing TwoTouchSynth harness.

## Before

OpenUIKit had tap / pan / long-press and a left/right-only
`UIScreenEdgePanGestureRecognizer` (nav interactive pop). The census types
below were ABSENT (`ours: false` in `full/ladder/uikit-union-2026-09-14.json`).

## Measurements (GestureProbe, SE 2x / iOS 26.1)

### Pinch (`UIPinchGestureRecognizer`)

Header: begins when two touches moved enough; ends when both lifted.

| property | value |
|---|---|
| `delaysTouchesBegan` | false |
| `delaysTouchesEnded` | true |
| `cancelsTouchesInView` | true |
| activation | `\|Δdistance\| ≥ 10` pt (d=8 dist=108 stays `.possible`; d=10 dist=110 → `.began`) |
| hysteresis | 8 pt baked into the baseline (`sign(Δ)`) |
| pinch-out 100→110 | scale = 110/108 = **1.018518519** |
| pinch-in 200→190 | scale = 190/192 = **0.989583333** |
| `set scale` | retargets baseline = currentDistance / newScale (dist 200, set 1, then 250 → **1.25**) |
| location | two-touch centroid (150, 200) for a 100 pt pair on y=200 |
| first velocity | last-step Δscale/Δt: `(110/108 − 1)/0.05 = 0.370370370` |
| one finger | never recognizes |
| one finger remaining | stays continuous; `.ended` when both lifted |

Later iOS velocity samples use a private IIR. No nameable filter fitted every
row without a parameter search — **OPEN**. The port keeps pan's last-step
rule; the first sample matches iOS exactly.

### Rotation (`UIRotationGestureRecognizer`)

| raw rotation | iOS `rotation` | meaning |
|---|---|---|
| 10° | 0.087266465 | 5° (5° hysteresis in the direction of rotation) |
| 45° | 0.698131703 | 40° |
| 90° | 1.483529867 | 85° |
| `set rotation = 0` at 90°, then 135° | 0.785398163 | 45°, no extra hysteresis |

Activation is 10°. A 10° pair reconstructed via cos/sin then re-read via
atan2 is 1 ULP below `10 * π / 180` (0.17453292519943284 vs
0.17453292519943295). The comparison is in degrees so the nameable
threshold stays 10. First velocity is last-step Δ(raw angle)/Δt:
`0.174532925/0.05 = 3.490658504`. Location is the centroid.

### Hover (`UIHoverGestureRecognizer`)

Apple's iOS 26.1 header: on iOS the recognizer is a no-op. Probe:
`zOffset=0`, `altitudeAngle=0`, `rollAngle=0`, stays `.possible` without a
hover source. `UIWindow.sendHover` is the host injection for tests /
iPad-class pointer (possible → began → changed → ended).

### Screen-edge pan

Already present for left/right (nav pop, 20 pt `edgeActivationWidth`). Apple's
`edges` is a `UIRectEdge` mask; top/bottom now use the same 20 pt width and
must lead away from the configured edge.

### Drag lift

| property | value |
|---|---|
| `UIDragInteraction.isEnabledByDefault` | true |
| `_UIDragLiftGestureRecognizer.minimumPressDuration` | **0.325** s |
| `allowableMovement` | **10** pt |

The probe's synthesized hold did not fire `itemsForBeginning` (touch
identity / private lift path). Duration was read off the recognizer
property — that is the named measurement. The session is process-local,
driven by that long-press lift.

Default pan vs pinch: pan wins; pinch does not run (existing exclusion).

## Rule

Pinch / rotation / hover / screen-edge live on the existing
`UIGestureRecognizer` state machine (possible → began → changed →
ended/cancelled). Constants are the measured values above, cited next to
the rule. Drag & drop is a process-local `_UIDragSessionImpl` driven by a
0.325 s / 10 pt long-press; table and collection `dragDelegate` /
`dropDelegate` fire in documented order with coordinators that implement
`drop(_:toRowAt:)` / `toItemAt:` / `intoRowAt:` / `intoItemAt:` /
`to:` / placeholder commit+delete. Previews are stored as data (no live
lift composite).

`NSItemProvider` is declared in `uikit/Sources` (APP LADDER §4 row 6:
13 apps / 103 uses). Darwin / guest: `typealias` to Foundation's type.
Linux: in-process class (corelibs has no `NSItemProvider`). No addition to
`foundation_guest_sources.txt`. No `_StringProcessing`.

## 20-app use-site counts unblocked

`full/ladder/uikit-union-2026-09-14.json` (`ours` was false; types now exist
in `uikit/Sources`):

| type | apps | uses |
|---|---|---|
| `NSItemProvider` | 13 | 103 |
| `UIPinchGestureRecognizer` | 7 | 64 |
| `UIDropSession` | 8 | 61 |
| `UIDropInteraction` | 6 | 48 |
| `UIDragItem` | 7 | 41 |
| `UICollectionViewDropProposal` | 5 | 33 |
| `UIDragSession` | 7 | 27 |
| `UIScreenEdgePanGestureRecognizer` | 9 | 26 (already ours; top/bottom added) |
| `UIDropProposal` | 5 | 19 |
| `UIRotationGestureRecognizer` | 1 | 16 |
| `UICollectionViewDropCoordinator` | 5 | 14 |
| `UICollectionViewDropDelegate` | 5 | 10 |
| `UICollectionViewDragDelegate` | 5 | 10 |
| `UIDragInteraction` | 4 | 10 |
| `UIDropInteractionDelegate` | 6 | 10 |
| `UIDragPreviewParameters` | 3 | 9 |
| `UIDragInteractionDelegate` | 3 | 4 |
| `UIDragPreview` | 2 | 3 |
| `UITableViewDragDelegate` | 2 | 3 |
| `UITableViewDropProposal` | 1 | 3 |
| `UITableViewDropDelegate` | 2 | 2 |
| `UITableViewDropCoordinator` | 2 | 2 |
| `UIPasteConfiguration` | 1 | 1 |
| `UIHoverGestureRecognizer` | — | not in the 20-app union (header no-op on iPhone) |
| `UITargetedDragPreview` / `UIDragPreviewTarget` | — | not in the union; required by the family |

Telegram 34 + ios-oss 9 pinch uses, and the §4 row 15 drag cluster (~230
uses), now compile against OpenUIKit.

## Before / after (gates)

| gate | before | after |
|---|---|---|
| Catalyst | 124/124 | **124/124** |
| iOS suite | 112/113 (`corner_radius`) | **112/113** (`corner_radius`) — see suite log |
| real-app floors | 99.137 / 98.535 / 98.548 / 99.469 / 98.639 / 98.133 / 97.516 / 99.65 / 82.17 / 99.86 / 99.734 / 85.393 | held exactly |
| Linux `swift:6.2-noble` openrender | green | green (218.57 s) |
| unit tests | — | Pinch 5, Rotation 1, Hover 1, ScreenEdge 2, DragDrop 8, plus existing tap/pan/long-press/pointer |

No `Package.resolved`. No `foundation_guest_sources.txt`. Guest Darwin sees
one `NSItemProvider` identity.

## Open questions (not invented)

- iOS pinch/rotation velocity IIR after the first sample — samples recorded,
  no nameable filter that fitted every row.
- Drag lift did not fire through TwoTouchSynth; 0.325 s came from
  `_UIDragLiftGestureRecognizer.minimumPressDuration`.
- Hover on iPhone is a documented no-op; `sendHover` is host injection.
- Previews are data only (no live lift composite).
- `UISwipeGestureRecognizer` (10 apps / 54) stays ABSENT — out of scope.
