# Brief: close one iOS-fidelity gap in OpenUIKit against the real iOS oracle

You are working in a git worktree of the `openuikit` monorepo on your own
branch. The port lives in `uikit/` (Swift package: OpenUIKit, the
`openrender` CLI, the vendored quartz in `uikit/Sources/CQuartz`). Work
from `uikit/` for every command below. Your task is ONE scene family or ONE
probe question, named at the end of this brief. Everything else is out of
scope.

## What "done" means

A branch pushed to `origin` with one or a few commits that make the named
scenes match real iOS 26.1 better, each commit carrying the measurement it
came from, plus a short report (in the final commit message or a
`REPORT.md` at the worktree root) with the before/after numbers and what
was measured. Do not open a pull request; the operator merges and advances
the vendor pin. The report file, if you write one, goes to
`uikit/docs/agent_reports/<branch-name>.md` — a `REPORT.md` at the worktree
root is outside `uikit/` and the merge path refuses the branch. Do NOT touch `scripts/vendor_pins.sh`, `env/`, or
`scripts/env/` — pin advances are the operator's job.

## The loop (read `docs/ORACLE_FLOW.md` first)

1. `scripts/oracle_flow.sh /tmp/flow-$AGENT <scenes>` captures the scenes on
   the real iOS simulator, renders them with the port under the iOS cut,
   compares, and writes `/tmp/flow-$AGENT/report/<scene>/` — `sheet.png`
   (golden left, ours right), `diff.png`, the two layout dumps,
   `report.txt`. Your simulator devices are private (`SIM_DEVICE_SUFFIX` is
   set in your environment); never touch other devices.
2. Read the frames before the pixels. `golden.layout.json` has every real
   view with absolute frames; ours has parent-relative frames and paths.
3. When the report does not explain a difference, write a PROBE scene that
   isolates one variable, capture it with
   `scripts/render_sim_scenes.sh <out> <probe.json>` (`SIM_DEVICE=2x` for a
   2x scene), and read the rule off the capture with a few lines of Python
   (PIL + numpy are installed). Keep probe files in `/tmp`, not the repo,
   unless they become a fixture scene.
4. Change ONE rule at a time, guarded by the iOS cut
   (`OpenUIKitRuntime.systemFontCut == .iOS`, `UITableView.isIOSChrome`,
   the `QZLayerSet*Model` platform switches in quartz). Cite the
   measurement in a comment next to the rule: scene/probe, device, numbers.
5. Verify before every commit:
   - the named scenes: `SKIP_CAPTURE=1 scripts/oracle_flow.sh /tmp/flow-$AGENT <scenes>`
   - the whole iOS suite against fresh goldens once at the end:
     `scripts/ios_suite.sh /tmp/suite-$AGENT` (~12 min; it must not drop
     any scene that passed before your change — `git stash` to compare)
   - the Catalyst gate, which must not lose a scene (its total grows as
     scenes are added; `git stash` to compare when in doubt):
     `swift build -c release --product openrender && ./.build/release/openrender render /tmp/gate-$AGENT fixtures/scenes/*.json && python3 Tools/compare/compare.py --out /tmp/gate-$AGENT | tail -1`
   - the real-app screens, which must not drop:
     `OPENUIKIT_REALAPP_SCALE=3 OPENUIKIT_FORCE_IOS=1 ./.build/release/openrender realapp /tmp/app-$AGENT && python3 Tools/compare/compare_realapp.py --golden /tmp/golden_realapp_ios --out /tmp/app-$AGENT --scale 3`
     (regenerate the goldens with `scripts/realapp_probe_sim.sh /tmp/golden_realapp_ios` if the directory is missing)
   - the unit tests near what you changed: `swift test --filter <Names>`
   - a Linux build: `docker run --rm -v "$PWD":/src:ro swift:6.2-noble bash -c 'cp -r /src /work && cd /work && swift build -c release --product openrender 2>&1 | tail -3'`
     (Linux Swift 6.2.4 refuses some expressions Apple's compiler accepts,
     and treats default-argument literals in files without
     `import Foundation` as errors).
6. Record the measurement as a row in the fidelity table of
   `docs/REAL_APP_TEST.md` (newest row on top, same format as the others).

## Rules that are not negotiable

- Never edit a golden PNG or layout dump to make a comparison pass. The
  Catalyst goldens in `golden/` are a different oracle (macOS) and stay
  exact: a change that improves iOS must not change a Catalyst render
  unless the rule is guarded by the iOS cut.
- Never model from memory. If you cannot measure it, write it up as an
  open question in the report instead of guessing.
- Every constant in a rule must be read off a sample and be nameable
  (a frame, a coverage value, a ratio of two measurements). A parameter
  search that targets the comparison score is not a measurement — a branch
  that lands exactly on a bar that way is rejected. When no rule fits every
  sample, add the scene to `scoreboard/open.txt` with the samples.
- Guest-route Foundation (UPDATED after the guest app path landed): the
  Linux-hosted arm64-apple-macos guest now compiles the real-app harness
  against the core guest package's Foundation — DateFormatter,
  NumberFormatter, ISO8601DateFormatter, DateComponentsFormatter,
  JSONSerialization, NSRegularExpression, URLSession, ByteCountFormatter
  all exist there (carried Darwin goldens under full/foundation/tests) —
  plus SwiftUI and Combine, and app stub modules under
  `Sources/RealAppProbe/*Modules/`. The old rule "no DateFormatter & co."
  is gone; what remains true: no `_StringProcessing` algorithms in
  library sources (the widget gate pins the load list), and every new
  Foundation family needs a carried golden before it is trusted.
- Adding a file to `full/foundation/foundation_guest_sources.txt` moves
  FIVE pins the operator bumps: core package EXPECTED_FOUNDATION_SOURCE_COUNT,
  the guest test's `sources=N`, the onboarding guest's `-eq N` and `-eq N-1`,
  and the StringProcessing undefined-count per builder.
- The guest links only the dylibs the Focus widget gate pins. Any String
  algorithm that lives in `_StringProcessing` — `contains("…")` with a
  String argument, `ranges(of:)`, `firstRange(of:)`, `replacing(_:with:)`,
  `split(separator: "…")` with a String, `trimmingPrefix`, any `Regex` or
  `#/…/#` literal — resolves to that library on the guest (the port's
  Foundation has no `StringProtocol.contains`), adds
  `libswift_StringProcessing.dylib` to the load list and fails GATE_B on
  both authorities (measured at 54be0035). Use `hasPrefix`/`hasSuffix`, a
  Character (`contains("\\")` is fine), `split(separator: Character)`, or
  a small index scan.
- One SimScene process per sheet/alert scene; capture scale-2 scenes on
  the SE; compare simulator goldens with `--golden-straight-alpha`. The
  capture hazards in `docs/ORACLE_FLOW.md` are all real and all measured.
- Do not touch anything outside `uikit/` in your worktree — do not delete
  sibling directories to speed a build, do not run `scripts/vendor_pins.sh`
  or `scripts/env/*`, do not edit `env/contract.json`. A branch that changes
  or deletes files outside `uikit/` is refused unread. Do not commit `.env`,
  `Package.resolved`, probe `.app` bundles or anything under `/tmp`.
- Commit messages: what was measured, the rule, the numbers before/after.
  End every commit message with a `Co-Authored-By:` line naming the model
  you are.
- If the build breaks on Linux or the gate drops, fix it or revert before
  pushing. Never push red.

- A scratch app you write for a measurement gets its OWN name under
  `Sources/ConformanceApps/` (e.g. `Keyboard/`), never the name of an app
  another branch may add: two agents once both created `Notes/` and the
  merge had to drop one.
- Two agents adding AXES to the harness in the same wave collide in the
  same ten files (ConformanceClock, openhost AppMode/ConformanceMode/main,
  confprobe, conformance_flow.sh, conformance_probe_sim.sh, hillclimb.sh,
  agent_merge.sh, scoreboard.py); if your task adds an axis, base your
  branch on the previous axis branch when the brief names one.
- Never `pgrep -f` a pattern that appears in your own command line when
  waiting for a process to finish: the waiter matches itself and never ends.

## Your task
