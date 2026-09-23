#!/usr/bin/env bash
# MEASUREMENT ONLY: NetNewsWire's guest build frontier on the iOS triple
# (uikit/Tools/nnwguest/README.md). Needs a completed
# scripts/ops/local_guest_verify.sh for TREE (machorun, runtime root, sysroot).
#
#   bash uikit/Tools/nnwguest/run.sh TREE CORPUS CHECKOUTS GENERATED [WORK]
#
# CORPUS     the ladder corpus holding NetNewsWire/ (PINS.txt revision)
# CHECKOUTS  NetNewsWire's SwiftPM checkouts (Xcode's SourcePackages/checkouts)
# GENERATED  files NetNewsWire's build generates (Secrets/SecretKey.swift)
# WORK       default TREE/build/nnwguest
set -euo pipefail
TREE=$(cd "$1" && pwd -P); CORPUS=$2; CHECKOUTS=$3; GENERATED=$4
WORK=${5:-$TREE/build/nnwguest}
HERE=$TREE/uikit/Tools/nnwguest
rm -rf "$WORK"; mkdir -p "$WORK"
# The package, copied (PROVENANCE.json) so the container sees real files.
python3 "$TREE/uikit/Tools/ingest/spm_app_chain.py" \
    "$TREE/uikit/docs/agent_reports/netnewswire-launch-chain.json" --out "$WORK/pkg" \
    --corpus "$CORPUS" --checkouts "$CHECKOUTS" --generated "$GENERATED" --openuikit "$TREE/uikit" --copy
python3 "$HERE/plan.py" "$TREE/uikit/docs/agent_reports/netnewswire-launch-chain.json" \
    "$WORK/pkg" "$WORK" > "$WORK/plan.sh"
# Diagnostic copies: build_full with graph.inc after the Apple-name modules;
# ios_guest.sh pointed at that copy and at this work directory.
anchor=$(grep -n '^build_guest_apple_name_modules$' "$TREE/full/scripts/build_full.sh" | cut -d: -f1)
[ -n "$anchor" ] || { echo "nnwguest: no build_guest_apple_name_modules anchor in build_full.sh" >&2; exit 2; }
sed "${anchor}a . \"\$NNWG_DIR/graph.inc\"" "$TREE/full/scripts/build_full.sh" > "$WORK/build_full_nnwg.sh"
cp "$TREE/full/scripts/guest_arch.inc" "$TREE/full/scripts/guest_arch.py" "$WORK/"
cp "$HERE/graph.inc" "$WORK/graph.inc"
sed -e "s|\"\$TREE/full/iostarget/ios_guest.sh\" --inside|\"$WORK/ios_nnwg.sh\" --inside|" \
    -e "s|bash full/scripts/build_full.sh > \"\$LGI/build_full.log\" 2>&1|NNWG_DIR=$WORK bash \"$WORK/build_full_nnwg.sh\" > \"\$LGI/build_full.log\" 2>\&1; grep NNWG \"\$LGI/build_full.log\"; exit 0|" \
    "$TREE/full/iostarget/ios_guest.sh" > "$WORK/ios_nnwg.sh"
grep -q ios_nnwg.sh "$WORK/ios_nnwg.sh" && grep -q build_full_nnwg.sh "$WORK/ios_nnwg.sh" \
    || { echo "nnwguest: ios_guest.sh no longer has the two lines this rewrites" >&2; exit 2; }
bash "$WORK/ios_nnwg.sh" "$TREE" | tee "$WORK/frontier.txt"
