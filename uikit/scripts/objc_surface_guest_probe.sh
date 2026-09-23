#!/usr/bin/env bash
# Mach-O guest check of the Objective-C surface (docs/agent_reports/
# objc-surface.md): an Objective-C category on UIFont and an Objective-C
# CALayer subclass, compiled by clang against OpenUIKit's generated header
# and run under machorun + objc4 on Linux (arm64 container).
#
#   bash uikit/scripts/objc_surface_guest_probe.sh [TREE]
#
# The probe is uikit/Tools/guestprobes/ObjCSurfaceGuestProbe.probe.sh:
# build_full.sh builds it and the guest verifier runs it against
# Tools/oracle2/objcsurfaceprobe/transcript-guest-ios26.1.txt, the same
# scenario variant run on the iOS 26.1 simulator (Tools/guestprobes/README.md).
# This is scripts/ops/local_guest_verify.sh plus a filter for its line:
# OBJC_SURFACE_GUEST_OK on an exact match.
set -euo pipefail
HERE=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)
TREE=${1:-$(cd "$HERE/../.." && pwd -P)}
MAIN=$(dirname "$(cd "$TREE" && cd "$(git rev-parse --git-common-dir)" && pwd -P)")
LOG=$TREE/build/objc_surface_guest_probe.log
mkdir -p "$TREE/build"
bash "$MAIN/scripts/ops/local_guest_verify.sh" "$TREE" > "$LOG" 2>&1 || true
grep -E 'OBJC_SURFACE_GUEST|extra guest probe|REAL-APP SCREEN VERIFIED' "$LOG" || true
grep -q '^OBJC_SURFACE_GUEST_OK ' "$LOG"
