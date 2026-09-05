# The fidelity hill-climb

A repeatable loop that raises OpenUIKit's fidelity to real iOS with several
agents at once, and leaves a measurable trail. One round:

```
scripts/hillclimb.sh 3            # score, pick the worst three families, launch agents
...                               # agents push agent/hc-<family> branches
scripts/agent_merge.sh agent/hc-x # operator: check + merge + pin, per branch
git add scoreboard && git commit  # the round's scoreboard, for the history
```

## The metric

`scoreboard/latest.{json,md}` (written by `scripts/scoreboard.py`) holds
every row the climb sees, worst first:

- the iOS scene suite (scripts/ios_suite.sh: every static fixture scene
  captured with real UIKit on the right simulator device, rendered by the
  port under the iOS cut, compared with straight-alpha goldens);
- the real-app screens (Pocket Casts, unmodified source, rendered at 3x);
- the Catalyst gate count (the regression oracle; must never drop);
- conformance apps (see below), one row per scripted capture.

A row is `pass` at or above its category bar, `fail` below it, or `open`
when it is below the bar but its difference has been measured and written
up as not modellable yet (`scoreboard/open.txt`, one scene per line with
the reason). The climb only assigns `fail` rows.

## What is climbed, in order of leverage

1. **Scenes** find rendering rules cheaply (one variable each).
2. **Conformance apps** are small UIKit apps we write the way real apps are
   written — Auto Layout, view controllers, xib cells, UserDefaults — with a
   scripted interaction and capture times. The same source is compiled into
   a simulator probe (real UIKit) and into openhost (the port); both replay
   the script on a shared 60 Hz frame clock (`ConformanceClock`: confprobe
   is a CADisplayLink, openhost steps `animationTime` by `frame / 60`) and
   dump frames and presentation geometry at the same frame index.
   They cover lifecycle and interaction, which scenes cannot:
   navigation flows, table editing, forms and keyboards, collection layouts,
   modal flows, settings at every Dynamic Type size and in dark mode.
   `scripts/conformance_flow.sh <workdir> <app>` runs one in light;
   `scripts/conformance_flow.sh <workdir> <app> --dark` replays the same
   script with `overrideUserInterfaceStyle = .dark` on the window before
   the first capture and suffixes capture names `.dark`. A `"style"` field
   in script.json is honoured by both confprobe and openhost.
   `scripts/conformance_flow.sh <workdir> <app> --rtl` pins
   `UIView.appearance().semanticContentAttribute = .forceRightToLeft` and
   the window before the first capture (window-only does not propagate;
   appearance stamps the tree — /tmp/rtlprobe, iPhone SE 2x / iOS 26.1)
   and suffixes capture names `.rtl`. A `"direction"` field in script.json
   is honoured the same way. The round scores `/tmp/hc-conformance-<App>`,
   `/tmp/hc-conformance-<App>-dark` and `/tmp/hc-conformance-<App>-rtl`.

   Adding an app is one directory (`Sources/ConformanceApps/<Name>/` with
   `<Name>App.swift` exposing `windowSize` / `makeRoot()` / `perform(_:)`,
   a `script.json`, and one `ConformanceApps.register` line) plus
   `scripts/gen_conformance_registry.sh`. openhost, confprobe and
   Package.swift's script.json exclude list all read that generated
   table; there is no fifth-place hand registration.
3. **Real open-source apps** are the exam: one vendored screen at a time,
   whose failures choose the next runtime surface (nib loading, UserDefaults,
   asset catalogs, URLSession) — see `docs/REAL_APP_TEST.md`.

Linux is held to byte-identity with the macOS render of the same source
(`scripts/linux_realapp_verify.sh`, the arm64/x86 authorities), so the
Mac-vs-Linux comparison is a build check, not a fidelity question; fidelity
is always measured against the iOS simulator. The simulator goldens live in
`/tmp` on the Mac that captured them; `goldens/ios/` is the committed copy
(`scripts/goldens_snapshot.sh` / `scripts/goldens_restore.sh`) so a Linux
agent can grade `SKIP_CAPTURE=1` without a simulator. `hillclimb.sh` and
`agent_merge.sh` restore that snapshot when `/tmp` has none.

## Rules the loop depends on

- Never edit a golden to pass. Goldens are captures; the Catalyst goldens
  are a different oracle and stay exact.
- One measured rule per change, guarded by the iOS cut, with the
  measurement in the code comment and a row in `docs/REAL_APP_TEST.md`.
- Agents push branches; the operator merges through
  `scripts/agent_merge.sh` (scope, gate, real-app floors, Linux build, pin).
- Capture hazards are real: one SimScene process per sheet or alert, scale-2
  scenes on the SE, straight-alpha goldens (`docs/ORACLE_FLOW.md`).
- An unmodellable difference goes to `scoreboard/open.txt` with its
  samples, never to a fudge factor.

## What a round actually reads (the false greens it has had)

- `scripts/hillclimb.sh N` recaptures the iOS suite AND every app under
  `Sources/ConformanceApps/` into `/tmp/hc-conformance-<App>` (light),
  `/tmp/hc-conformance-<App>-dark` (window style dark), and
  `/tmp/hc-conformance-<App>-rtl` (appearance + window forceRightToLeft) —
  its own directories. `/tmp/conformance-<App>` belongs to the agents; rounds 3–6
  once scored reports agents had left there and fanned out on rows the
  merged code had already fixed. The board stamps each app's capture time
  (`conformance captured:` line); a time older than the head is stale.
- Only apps registered in the tree are scored: an agent's in-progress app
  also lives in `/tmp`, and round 7 launched two agents on half-built ones.
- `PICK_ONLY=1` scores and writes the task file without launching agents —
  use it when a wave already owns the failing rows.
- Grade a merge by the commit count the script prints (`N commit(s) over
  main`); `cursor-agent --worktree` leaves a local base branch with the
  agent's bare name at the starting commit, and a bare-name merge once
  checked main against itself.
- A branch behind main is re-resolved in a temp worktree (merge main into
  it; fidelity table keep-both; scoreboard from main; `Registry.swift`
  regenerated by `scripts/gen_conformance_registry.sh`; a root `REPORT.md`
  moved under `docs/agent_reports/`), pushed as `agent/<name>-merged`, and
  then handed to `scripts/agent_merge.sh`. Do not touch `uikit/` while the
  script runs: the vendor-tree attestation hashes the working tree.
- The merge check re-renders every conformance app against the last
  round's goldens (`/tmp/hc-conformance-<App>`) and refuses a drop: a
  passing row must stay at its bar, a failing one may not lose 0.5. A
  branch that changes the PROBE (how a frame is named, what is dumped)
  invalidates those goldens for its app — run it with
  `RECAPTURE_APPS="Pager"` so the goldens are captured again with the
  merged tree's probe before grading; and refresh the round's goldens
  (`PICK_ONLY=1 scripts/hillclimb.sh N`) after such a merge lands, or every
  later branch is graded against stale goldens. When `/tmp` has none, the
  merge check restores `goldens/ios/` and prints that it did.
- Housekeeping after each wave: finished agents' simulator devices
  (`xcrun simctl delete`) and worktrees (`git worktree remove --force`);
  58 devices and 50 worktrees once filled the disk.
