# Campaign ios26.1-fwseed-r1 (2026-09-01) — operator records

Recovered from the operator's working directory (Documents/Codex/2026-08-31/new-chat).

- `cursor-framework-fanout-wave{1,2,3}-state.json` — the 25+24+22 framework
  agents (grok-4.6, effort=high, fast=false) that produced the
  openuikit-linux-platform `cursor/port-*` PRs; per-framework agent IDs, URLs,
  branches, PR links.
- `cursor-framework-repair*-state.json` — six follow-up repair waves keyed to
  PR ranges.
- `ec2_*.json` / `ec2_import_core_cold_20260901.sh` — SSM run parameters for
  the ARM64 authority box `OpenUIKit-Linux-Builder` (i-00da4d9ca172eb1ff,
  m8g.4xlarge, stopped 2026-09-02): core-cold package import with full
  hash/commit attestation, DTS/KVC support-fix builds, and the Hackers
  (`Hackers2.app`) portable-application smoke + external verify
  (PORTABLE_APPLICATION_GUEST_OK / HOST_ACTIVE windows=1 / LOOP_OK turns=3).

PROVENANCE WARNING: the support/uikit commits these runs pin
(support d2f98a9c + 44bd5af2, uikit 0315f997) exist ONLY in checkouts on the
stopped EC2 instance — they are in no local repo and not on GitHub. The
exact trees behind the recorded Hackers smoke evidence are recoverable only
while that instance's EBS volume exists.
