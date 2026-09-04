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
   the script and dump frames and presentation geometry at the same times.
   They cover lifecycle and interaction, which scenes cannot:
   navigation flows, table editing, forms and keyboards, collection layouts,
   modal flows, settings at every Dynamic Type size and in dark mode.
   `scripts/conformance_flow.sh <workdir> <app>` runs one; its
   `summary.json` feeds the scoreboard.

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
is always measured against the iOS simulator.

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
