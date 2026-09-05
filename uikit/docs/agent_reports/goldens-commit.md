# Committed iOS goldens so a Linux agent can grade without a simulator

A Linux box cannot capture against the iOS 26.1 simulator, and until this
round every golden lived only in `/tmp` on the Mac that ran the last
hill-climb (`/tmp/ios_suite/golden_ios`, `/tmp/golden_realapp_ios`,
`/tmp/hc-conformance-<App>[-dark|-ipad|-rtl|-ax1]/golden`). This round
snapshots those sets into `goldens/ios/` and restores them to the paths
the flows already expect.

No rendering rule changed. Catalyst stays **124/124**. The iOS suite stays
**112/113** (the known `corner_radius` open at 99.411). Real-app floors
do not drop.

## What was on disk (this Mac, 2026-09-05)

`scripts/goldens_snapshot.sh` read every golden set that was actually
present, hashed every file, and recorded device + capture time off the
layout dumps / mtimes (not guessed):

| set | png | captured (UTC) | device |
|---|---|---|---|
| `ios_suite` | 113 | 06:18 | iPhone SE 2x + iPhone 16 3x |
| `golden_realapp_ios` | 59 | 03:31 | iPhone 16 3x + iPad (A16) 2x (+ xs/xxxl/ax1) |
| 7 apps × light | 64 | 06:19–06:27 | iPhone SE 2x |
| 7 apps × dark | 64 | 06:20–06:27 | iPhone SE 2x |
| 7 apps × ipad | 64 | 06:19–06:27 | iPad (A16) 2x |
| rtl: Forms, NavFlow, TableEditor | 21 | 06:28–06:29 | iPhone SE 2x |
| ax1: Feed, Forms, TableEditor | 21 | 06:19–06:21 | iPhone SE 2x |

**29 sets, 406 PNG + 359 layout dumps, 765 files, 36 MB.** Manifest
`goldens/ios/manifest.json` carries `head` `4901188a`, per-set `device` /
`captured`, dest path, and sha256 per file. rtl and ax1 are committed even
though `hillclimb.sh` does not recapture them every round — they were on
disk today.

`scripts/goldens_restore.sh` copies a set back to its dest only when that
path is empty (`FORCE=1` overwrites) and verifies sha256. On this Mac with
a full `/tmp`: `goldens_restore: /tmp already has all 29 committed set(s);
not replacing`. After deleting `hc-conformance-Feed-ax1/golden`, restore
refilled 12 files and `sha256_ok True`.

## Flow wiring

- `ios_suite.sh` always writes the 2x/3x scene split (SKIP_CAPTURE used to
  require leftover `$WORK/scenes` from a previous capture). Empty
  `$GOLD` restores `goldens/ios/ios_suite`.
- `conformance_flow.sh` SKIP_CAPTURE with an empty `$OUT/golden` restores
  `hc-conformance-<App>[-ipad][-dark]`.
- `hillclimb.sh` and `agent_merge.sh` call restore at the start of scoring
  / merge checks and print the restore line, so a SKIP_CAPTURE round off
  the pin is visible.

## Linux proof (`swift:6.2-noble`, no simulator)

Clean copy of this tree inside `docker run --rm -v … swift:6.2-noble`.
Container `/tmp` was empty. Restore printed:

```
goldens_restore: /tmp had none; restored 29 set(s) from committed goldens/ios (head 4901188a)
  verified sha256 for 765 file(s)
```

Then `openrender` + `openhost` built (Swift 6.2.4), real-app screens
rendered with `OPENUIKIT_FORCE_IOS=1 OPENUIKIT_REALAPP_SCALE=3`, and
`SKIP_CAPTURE=1 scripts/conformance_flow.sh … NavFlow` graded against the
restored goldens. SF fonts mounted at `OPENUIKIT_FONT_DIR` (same as
`scripts/linux_realapp_verify.sh`).

### Real-app scores (Mac = Linux to three decimals)

| screen | Mac | Linux |
|---|---|---|
| `realapp_history_light` | 99.137 | 99.137 |
| `realapp_settings_light` | 98.535 | 98.535 |
| `realapp_settings_dark` | 98.548 | 98.548 |
| `realapp_storage_light` | 99.469 | 99.469 |
| `realapp_settings_light_xs` | 98.639 | 98.639 |
| `realapp_settings_light_xxxl` | 98.133 | 98.133 |
| `realapp_settings_light_ax1` | 97.516 | 97.516 |
| `realapp_settings_light_ipad` | 99.511 | 99.511 |
| `realapp_focus_settings_light` | 82.192 | 82.192 |
| `realapp_history_light_ipad` | 99.760 | 99.760 |
| `realapp_storage_light_ipad` | 99.689 | 99.689 |
| `realapp_hackers_feed_light` | 85.393 | 85.393 |

PNG byte-identity Mac vs Linux: **12/12**.

### NavFlow SKIP_CAPTURE (Mac = Linux to three decimals)

| capture | Mac | Linux |
|---|---|---|
| t200 | 99.622 | 99.622 |
| t1200 | 99.248 | 99.248 |
| t2100 | 99.622 | 99.622 |
| t3000 | 98.196 | 98.196 |
| t3900 | 98.796 | 98.796 |
| t4800 | 98.731 | 98.731 |

Mean **99.036**, worst **98.196**. Ours PNG byte-identity Mac vs Linux:
**6/6**.

## Gates

- Catalyst `compare.py --out /tmp/gate-goldens-commit`: **124/124**.
- `SKIP_CAPTURE=1 scripts/ios_suite.sh /tmp/suite-goldens-commit`:
  **112/113**, fail is `corner_radius` 99.411 (open).
- Real-app floors held (table above).
- Linux `swift:6.2-noble` openrender + openhost green. No
  `Package.resolved` committed. Nothing outside `uikit/`.
