# gate-speed — agent_merge.sh: committed goldens, faster, no weaker (2026-09-22)

Branch `agent/gate-speed`. Every file touched is under `uikit/`, so no
ALLOW_PATHS is needed. The guest-verify speedups (part B) are on their own
branch, `agent/gate-speed-guest`, which touches `full/scripts/build_full.sh` and
`scripts/ops/local_guest_verify.sh` and is merged separately.

## What changed

**1. Goldens come from the merged tree, not from /tmp.**
- The conformance and real-app goldens are copied from `goldens/ios` in the merged
  worktree, and every file's sha256 is checked against `manifest.json`.
- The shared, mutable `/tmp/hc-conformance-*` captures are never read or written.
  On 2026-09-22 they were overwritten with the Sep 5 snapshot, and every Forms and
  Tabs row read as a drop.
- `GATE_GOLDENS=tmp` keeps the old route for in-flight branches. It refuses exactly
  what the old gate refused, plus golden_sha mismatches.

Before any render, each committed set is refused (exit 9) in these cases. Every
refusal prints the command that fixes it:
- **GOLDEN SNAPSHOT CORRUPT**: a file does not match `manifest.json`.
- **STALE GOLDENS**: `Sources/ConformanceApps/<App>` changed after the capture.
  `golden/provenance.json` settles this by content hash. Older sets fall back to
  comparing the manifest capture time against the newest non-merge author date on
  that path.
- **BOARD-GOLDEN MISMATCH**: the board has a different frame set for the set, or a
  board row's `golden_sha` differs from the committed PNG.
- Probe changes are reported, not refused.

`ALLOW_STALE_GOLDENS="<set or App> …"` is the stopgap:
- The named sets are rendered and each row is printed as `ALLOWED STALE (not
  graded)` next to its board value. The merge commit message lists them.
- An entry must name a set that is actually stale, mismatched or not yet pinned.
  Naming a pinned, fresh set is refused, so the stopgap cannot outlive the fix.

**2. Board rows are pinned to their golden.**
- `scoreboard.py` writes `golden_sha` on every conformance row.
- `--refresh-conformance DIR…` replaces only those sets' rows and prints the old
  board score next to the new one.
- `scripts/refresh_conformance_goldens.sh <App> [axes]` does the whole refresh in
  one step:
  - captures serially under `/tmp/conformance_sim.lock`;
  - writes `provenance.json`;
  - retries a short capture up to 3 times and never writes one;
  - replaces `goldens/ios/<set>` and only those manifest entries (format kept:
    indent=1, no trailing newline);
  - regrades those board rows and flags any row that drops more than 0.5.
- Pinning is what absorbs mid-fling capture noise. Pager-ipad t1800 gave 94.50 and
  then 98.17 on two back-to-back captures.

**3. Short sets fail.** `conformance_flow.sh` now exits 4 with a `SHORT CAPTURE`
line when a script capture has no golden or no render. Before, a loaded or broken
simulator produced 3 of 7 frames and the flow exited 0, scoring the rest 0.0. The
gate keeps its single recapture retry, and otherwise refuses with `CONFORMANCE FLOW
SHORT`.

**4. Speed.** None of this skips a check; each stage keeps its exit code and its
place in the verdict order.
- **No lock for CHECK_ONLY.** CHECK_ONLY runs take no lock and each gets its own
  scratch root (`/tmp/agent_gate.XXXXXX`, or `GATE_SCRATCH`). Real merges hold
  `/tmp/agent_merge.lock` for the whole run, as before.
- **Stale roots are reaped by owner pid.** The old reaper could delete a live
  run's worktree once runs became concurrent.
- **Background stages.** Once the merged tree exists, three stages start in the
  background, and each is joined where the serial gate ran it:
  - the Linux docker build: one container instead of two, fed the merged tree by
    `git archive` instead of a copy of the worktree with its macOS `.build`;
  - the guest library route;
  - the test-bundle debug build (its own `--scratch-path`, so it doesn't wait on
    SwiftPM's lock).
- **Build openhost once.** openhost is built once, in the background during the
  Catalyst gate; `CONFORMANCE_PREBUILT=1` skips the 27 no-op rebuilds.
- **Parallel replays.** SKIP_CAPTURE replays run `GATE_JOBS` (default 4) at a
  time. Recaptures stay serial under the simulator lock. Each replay runs openhost
  under its own name (`CONFORMANCE_HOST_BIN`), which isolates its UserDefaults (see
  below).
- **Compare once.** The Catalyst and real-app compares run once instead of twice.
- **Verdict reuse.** A passing CHECK_ONLY run writes a stamp under
  `/tmp/agent_gate_state/verdicts/<key>`. The key covers:
  - the merged tree id (`git merge-tree --write-tree main <branch>`, checked
    against the worktree's `write-tree`);
  - the gate script's sha;
  - ALLOW_DROP, ALLOW_STALE_GOLDENS, ALLOW_PATHS, RECAPTURE_APPS, GATE_GOLDENS and
    GATE_WARM;
  - `swift --version`, the swift:6.2-noble and swift-macho-spike image ids, and
    the guest FoundationEssentials module;
  - the /tmp captures, in tmp mode only.

  How the stamp is used:
  - A real merge (or CHECK_ONLY with `REUSE_VERDICT=1`) with the same key within
    24 h (`GATE_VERDICT_TTL_H`) prints `VERDICT REUSED` with the stamp's details.
  - `FORCE_RECHECK=1` reruns everything.
  - Runs with RECAPTURE_APPS never stamp.
  - New check: the real merge refuses if origin/main moved `uikit/` after the
    check. The old gate would have merged a combination it never checked.
- **GATE_WARM=1 (OFF).** A persistent SwiftPM scratch directory per slot plus a
  docker volume for the Linux `.build`. See the warm-caches section below.
- `GATE_SERIAL=1` runs everything in the old one-at-a-time order, for
  comparisons.

**5. Bugs found on the way**
- **UserDefaults leak between replays.** openhost links Foundation, so a
  conformance app's `UserDefaults.standard` is the CFPreferences domain
  "openhost", shared by every process. NavFlow resets its switch at launch and
  sets it at t3.3, and one replay's write reached another. With 8 concurrent
  NavFlow `--dark` replays, 10 of 24 drew the switch on at t3000. The first
  parallel gate refused NavFlow t3000/t3900.dark (98.29 < 98.83) because of it.
  With a per-replay name, 24 of 24 matched. Any concurrent openhost runs (other
  agents, hillclimb) have been exposed to this.
- **Exit code clobbered.** The old EXIT trap turned a CONFORMANCE DROPPED (exit 9)
  into exit 128, measured on the baseline run. The trap now keeps the verdict's
  code, and INT/TERM exit with 130.
- **Missing manifest entries.** `golden_realapp_ios` has three focus_browser files
  that are not in `manifest.json`. They are reported, not refused.

## Timings (CHECK_ONLY, agent/conformance-sim-exclude or agent/gate-speed, cold: fresh worktree, no build cache)

| run | wall | release build | Catalyst | guest route | test bundle | real app | 27 conformance sets | Linux |
|---|---|---|---|---|---|---|---|---|
| baseline (old stages, serial; only the scratch-root change) | **1316 s** to the conformance verdict (refused; Linux not reached) | 606 s | 53 s | 180 s | 126 s | 65 s | 263 s | not run; est. ≥ 650 s |
| + background stages + parallel replays (par1) | 504 s (refused: UserDefaults leak) | ~380 s | 20 s | bg 166 s | bg 122 s | 20 s | 72 s | bg, done at +454 s |
| + per-replay openhost name (par2, final) | **506 s, passed** | ~395 s | 20 s | bg 196 s | bg 107 s | 15 s | 70 s | bg, done at +460 s |
| verdict reuse (same merged tree and knobs) | **2 s** | – | – | – | – | – | – | – |

Notes on the numbers:
- Other agents were compiling the whole time, so the numbers are noisy. The two
  release builds (606 s vs ~390 s) differ by load alone.
- The critical path is now the release build plus the conformance replays. The
  Linux container finishes a few seconds before the replays.
- The old Linux stage built openrender cold twice, in two containers, after
  copying a GB-sized `.build`. That estimate comes from the 325–363 s single cold
  openrender build measured in the new container, plus the copy. It is an
  estimate, not a measurement.

## Equivalence

`cmp` of the baseline (serial, /tmp goldens, merged tree main + conformance-sim-exclude) against par2 (parallel, committed goldens, merged tree main + gate-speed; the renders come from the same code):

```
catalyst      317/317 PNGs byte-identical
realapp        15/15  PNGs byte-identical
conf-ours     244/244 PNGs byte-identical
conf-summary   26/27 identical — the one that differs is Pager-ipad, whose goldens were refreshed on purpose
```

Before the UserDefaults fix, par1 differed in exactly two PNGs (NavFlow t3000/t3900.dark). Across all three runs the Catalyst gate was 124/124, every real-app floor held, and the guest route and test bundle passed.

## Refreshed sets (refresh_conformance_goldens.sh, on this branch)

**Pager-ipad**: 17/17 frames, pinned. Board vs new:

| row | board | new |
|---|---|---|
| t500 | 99.974 | 98.164 (golden PNG changed: capture noise) |
| t3267 | 99.979 | 99.123 (golden PNG changed) |
| t3133 | 99.961 | **99.308** |
| the other 14 rows | | within ±0.02 |

t3133 is a real render change since the Sep 6 board. Its golden is byte-identical, it is still above the 97.5 bar, and the cause is not yet bisected. It is recorded in `docs/KNOWN_GAPS.md`.

**Forms base and Tabs base**: the capture came back short on all 3 attempts (golden 3/7 and 6/8), so nothing was written. The probe-keyboard agent owns this. Every Forms and Tabs axis is carried by `ALLOW_STALE_GOLDENS="Forms Tabs"`: those rows are reported, not graded. Tabs is flagged STALE because its source changed after capture. The Forms and Tabs rows are not yet pinned. TableEditor comes from the merged agent/conformance-sim-exclude (d5bb95c8: 10 frames, matching the board).

## Warm caches (GATE_WARM): OFF, not proven

What it does:
- It keeps a per-slot SwiftPM scratch directory (`~/Library/Caches/agent_gate/<toolchain>/slot-N`, 4 slots, each locked by pid) and a docker volume for the Linux `.build`.
- The worktree path is new on every run, so every uikit module compiles from scratch. Only the dependency checkouts and their products (swift-syntax, OpenCombine) are reused.

What has not been done:
- The two-commit warm-vs-cold byte comparison that the task asks for, one of them crossing agent/simplenote-objc-core, did not fit before the coordinator's hand-back. `GATE_WARM` has not been run end to end.
- Leave it off until someone runs cold and warm on main and on main + simplenote-objc-core, and `cmp` shows identical Catalyst, real-app and conformance outputs.

## Other waits removed or found (C)

- `uikit/.gitignore` now ignores `/Package.resolved` and `.build-tests/`. SwiftPM rewrites `Package.resolved` on every build, which dirtied the tree, and a committed one is refused.
- `conformance_flow.sh` rebuilt openhost for every set. It now skips the build when `CONFORMANCE_PREBUILT=1`.
- The Linux stage copied the macOS `.build` into the container and ran two cold containers. It is now one container fed by `git archive`.
- `guest_route_check.sh` left a `/tmp/guest-route-check-$$` directory behind on every run. It now writes into the scratch root.
- Not done:
  - Parallelising the 37 serial CQuartz clang compiles in `guest_route_check.sh`. It is off the critical path now.
  - Pointing hillclimb and other concurrent openhost users at `CONFORMANCE_HOST_BIN`, which is recommended.

## Operator: merging this branch

Until this branch lands, main's gate is the old script. It reads /tmp and would refuse the stale Forms and Tabs sets as drops. So run this branch's gate from the main checkout under another name:

```
cd /Users/miguelsalinas/openuikit
git fetch origin && git show origin/agent/gate-speed:uikit/scripts/agent_merge.sh > uikit/scripts/agent_merge_next.sh
ALLOW_STALE_GOLDENS="Forms Tabs" bash uikit/scripts/agent_merge_next.sh gate-speed
rm uikit/scripts/agent_merge_next.sh
```

No ALLOW_PATHS is needed. The merge commit will list the allowed stale sets.

## Risks

- **Machine load.** Parallel replays and background builds raise the machine's load. Captures are the load-sensitive step, and they stay serial. Replays are deterministic once isolated: 24/24 matched under 8-way load. `GATE_JOBS=1` and `GATE_SERIAL=1` are there if a doubt comes up.
- **Legacy staleness heuristic.** For sets without `provenance.json`, staleness is judged by author dates. It missed Forms, whose probe environment changed. Only a `golden_sha` pin on the board catches that, and pins arrive with each refresh.
- **Verdict stamps.** Stamps live in /tmp and can be forged by any local process, which is the same trust model as the old /tmp captures. The key has no host-image fingerprint beyond the listed image ids.
- **Other openhost users.** Anything that runs openhost concurrently without `CONFORMANCE_HOST_BIN` still shares the "openhost" defaults domain.
