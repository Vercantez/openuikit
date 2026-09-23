#!/usr/bin/env bash
# Mach-O guest check of the storyboard / NIB runtime: machorun + objc4 on
# Linux (arm64 container), the route real apps take.
#
#   bash uikit/scripts/nib_guest_probe.sh [TREE]
#
# The probe is uikit/Tools/guestprobes/NibGuestProbe.probe.sh: build_full.sh
# builds it and the guest verifier runs it (Tools/guestprobes/README.md), so
# this is scripts/ops/local_guest_verify.sh plus a filter for its line:
# NIB_GUEST_RUNTIME_OK when the archived custom classes were found by name in
# objc4, built through init(coder:), their outlets connected, the embed segue
# performed (with the app's prepare(for:sender:) override) and an archived
# button action delivered.
set -euo pipefail
HERE=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)
TREE=${1:-$(cd "$HERE/../.." && pwd -P)}
MAIN=$(dirname "$(cd "$TREE" && cd "$(git rev-parse --git-common-dir)" && pwd -P)")
LOG=$TREE/build/nib_guest_probe.log
mkdir -p "$TREE/build"
bash "$MAIN/scripts/ops/local_guest_verify.sh" "$TREE" > "$LOG" 2>&1 || true
grep -E 'NIB_GUEST_|extra guest probe|REAL-APP SCREEN VERIFIED' "$LOG" || true
grep -q '^NIB_GUEST_RUNTIME_OK ' "$LOG"
