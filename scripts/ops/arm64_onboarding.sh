#!/bin/bash
# On-box arm64 onboarding gate. Runs INSIDE the checked-out tree after
# run_box.sh's document fetched the bundle and checked out the sha. The gate
# takes the normalized-bundles DIRECTORY staged on the box
# (/tmp/focus-widget-res.*/output/bundles), not a single bundle.
set -u
export HOME=${HOME:-/root}
export PATH=/opt/swift624/usr/bin:/usr/local/bin:/usr/bin:/bin
TREE=${1:-$(pwd)}
cd "$TREE" || exit 2
W=$(dirname "$TREE")
echo "checked out $(git rev-parse HEAD)"
P2=$(ls -d /tmp/focus-widget-res.* 2>/dev/null | head -1); D="$P2/output/bundles"
[ -d "$D" ] || { echo "GATE_ONBOARDING_FAIL rc=2 (no staged bundles dir under /tmp/focus-widget-res.*)"; exit 2; }
if bash full/swiftui/build_focus_onboarding_guest.sh "$D" > "$W/onboarding-gate.log" 2>&1; then echo GATE_ONBOARDING_PASS; else echo "GATE_ONBOARDING_FAIL rc=$?"; fi
grep -vE 'warning:|^ *[0-9]+ \||^ *\|' "$W/onboarding-gate.log" | grep -E 'PASS|FAIL|refus|error:|machorun|cannot|CANNOT|png|^==|guest:' | tail -30 | cut -c1-240
