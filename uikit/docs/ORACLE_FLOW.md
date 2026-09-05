# The oracle flow

How a fidelity gap in OpenUIKit's iOS rendering gets found, measured and
closed — the loop every fidelity round of 2026-09-04 ran, packaged so that
one person or one agent can run it on one scene family without the rest
of the project in their head.

The iOS 26.1 simulator is the oracle. Nothing is modelled from memory or
from the Catalyst goldens; every rule the port carries for the iOS cut was
read off a capture, and the capture is kept next to the rule (the tables in
`docs/REAL_APP_TEST.md`).

## One command

```
scripts/oracle_flow.sh /tmp/flow tableview_grouped navbar_large
```

captures the scenes with real UIKit on the right simulator device, renders
them with OpenUIKit under the iOS cut, compares, and writes
`/tmp/flow/report/<scene>/` with `sheet.png` (golden left, ours right),
`diff.png`, both PNGs, both layout dumps and `report.txt` (score, largest
wrong region, structural notes, per-view frame differences).

`SIM_DEVICE_SUFFIX=-mine` gives the run its own simulator devices, so
several flows can run at once. `SKIP_CAPTURE=1` reuses the goldens. When
`/tmp` has none (a Linux agent, or a wiped Mac), `scripts/goldens_restore.sh`
copies the committed snapshot in `goldens/ios/` back to the `/tmp` paths
the suite, the real-app compare, and `conformance_flow.sh` expect;
`scripts/goldens_snapshot.sh` is how a Mac with a fresh capture writes that
snapshot. `hillclimb.sh` and `agent_merge.sh` restore on their own when
`/tmp` is empty and say so in their output.

The whole suite is `scripts/ios_suite.sh` (98 scenes, ~12 minutes with the
capture, ~2 minutes with `SKIP_CAPTURE=1`); the Catalyst regression gate is
`openrender render <out> fixtures/scenes/*.json` + `Tools/compare/compare.py
--out <out>` and must stay 109/109; the real-app screens are
`OPENUIKIT_REALAPP_SCALE=3 OPENUIKIT_FORCE_IOS=1 openrender realapp <out>` +
`Tools/compare/compare_realapp.py --golden /tmp/golden_realapp_ios --out <out>
--scale 3` (goldens from `scripts/realapp_probe_sim.sh`).

## The loop

1. **Read the report, not the score.** `sheet.png` side by side, then the
   layout dumps: `golden.layout.json` lists every real view with its
   absolute frame; `ours.layout.json` lists ours with parent-relative
   frames and paths. A 4 pt shift in a frame explains a 5 % pixel score;
   chase frames before pixels.
2. **Measure, then model.** When the report does not say why, write a
   probe scene that isolates the one variable (five image widths in a
   bar; views at every sixth of a point; a pen sweep through a label) and
   capture it with `scripts/render_sim_scenes.sh <out> <probe.json>` on the
   right device (`SIM_DEVICE=2x` for the SE). Read the numbers off the
   capture with a few lines of Python. The rule is whatever fits every
   sample; if no rule fits, capture more samples — do not average.
3. **One rule per change**, guarded by the iOS cut
   (`OpenUIKitRuntime.systemFontCut == .iOS`, `UITableView.isIOSChrome`,
   the quartz platform models). The Catalyst goldens are a different
   oracle and stay exact; never edit a golden to make a comparison pass.
4. **Verify before pushing**: the changed scenes with the flow, the suite
   with `SKIP_CAPTURE=1`, the Catalyst gate, the real-app screens, the
   relevant unit tests (`swift test --filter ...`), and a Linux build in
   the `uikit-linux` container (Linux Swift 6.2.4 refuses expressions
   Apple's 6.2.1 accepts, and treats default-argument literals in files
   without `import Foundation` as errors).
5. **Record the measurement** in `docs/REAL_APP_TEST.md` (the fidelity
   table) and in the code comment next to the rule, with the scene or probe
   it came from and the numbers.

## Capture hazards (all measured)

- A SimScene process that has shown an alert or a sheet loses the glass
  materials (bar platters, the sheet grabber and the 12 pt it adds) for
  everything it captures afterwards: one process per sheet/alert scene.
- A 3x device captured at scale 2 resamples every edge and quantises text
  on the union of the two grids: capture scale-2 scenes on the SE.
- `preferredRange = .standard` drops private materials; `.extended` keeps
  them but hands back premultiplied, P3-tagged bitmaps for some scenes —
  SimScene re-encodes every capture as straight-alpha untagged sRGB, and
  `compare.py --golden-straight-alpha` must be told so.
- A dismissed alert dims tint colours for the rest of the process
  (`tintAdjustmentMode = .normal` on the wrapper).
- Dump layout AFTER the capture, from the window for modal scenes; a dump
  taken before the wrapper joins the window is a plausible lie.
- A non-window capture of fractional-origin rounded views shows 50 %
  top rows; the real window floors every edge. Measure window behaviour in
  a window scene.

## Adding a scene

A scene is a JSON file in `fixtures/scenes/` (spec: `docs/SCENES.md`).
Keep it small and about one thing; give it `"ios": true` if it is bar
chrome, `"window": true` if it needs a real window, `"modal"`/`"alert"`
for presentations. Run the flow on it, then add it to the suite's Catalyst
goldens with `scripts/regen_goldens.sh` (that is the regression gate; the
iOS suite regenerates its own goldens every run).

## Fan-out

`scripts/agent_fanout.sh tasks.txt` runs one local Cursor agent
(`cursor-agent -p`) per task line, each in its own git worktree and branch
with its own simulator devices, with `docs/AGENT_BRIEF_ORACLE.md` as the
brief. Tasks are one scene family or one probe question each. Agents push
branches; a human (or the operator agent) merges, advances the vendor pin
(`scripts/vendor_pins.sh`, `env/contract.json`, `scripts/env/test_contract.py`)
and runs the Linux authorities — `scripts/agent_merge.sh <branch>` does the
checks (scope, gate, real-app floors, Linux build), the merge and the pin
advance in one go; `CHECK_ONLY=1` stops before the merge.
