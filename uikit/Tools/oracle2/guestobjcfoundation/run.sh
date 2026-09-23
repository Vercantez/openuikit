#!/bin/zsh
# guestobjcfoundation -- the Apple side of GuestObjCFoundationProbe.
#
# Builds scenario/*.m, NetNewsWire's unmodified RSDatabaseObjC (from the pinned
# ladder corpus, checked against full/objcfoundation/rsdatabaseobjc.sha256) and
# main.swift for the iOS 26.1 simulator against Apple's Foundation and
# libsqlite3, runs it in a throwaway iPhone 16 holding /tmp/conformance_sim.lock,
# deletes the device, and writes transcript-ios26.1.txt.
#
#   LADDER_CORPUS=/path/to/ladder-corpus zsh run.sh
set -eu
D=${0:A:h}
REPO=${D:h:h:h:h}
COMMON=$(git -C "$REPO" rev-parse --path-format=absolute --git-common-dir)
CORPUS=${LADDER_CORPUS:-${COMMON:h}/scratch/ladder-corpus}
NNW=$CORPUS/NetNewsWire
(cd "$NNW" && shasum -a 256 -c --quiet "$REPO/full/objcfoundation/rsdatabaseobjc.sha256")
RSDB=$NNW/Modules/RSDatabase/Sources/RSDatabaseObjC
SDK=$(xcrun --sdk iphonesimulator --show-sdk-path)
OUT=${OUT:-/tmp/guestobjcfoundation}
rm -rf "$OUT"
mkdir -p "$OUT/maps/OFScenario" "$OUT/maps/RSDatabaseObjC"
cat > "$OUT/maps/OFScenario/module.modulemap" <<EOF
module OFScenario { header "$D/scenario/include/OFScenario.h" export * }
EOF
cat > "$OUT/maps/RSDatabaseObjC/module.modulemap" <<EOF
module RSDatabaseObjC { umbrella header "$RSDB/include/RSDatabaseObjC.h" export * }
EOF
T=(-target arm64-apple-ios26.1-simulator -isysroot "$SDK")
objs=()
for f in "$D"/scenario/*.m "$RSDB"/*.m; do
    o="$OUT/$(basename "$f" .m).o"
    xcrun --sdk iphonesimulator clang "${T[@]}" -fobjc-arc -fmodules -fmodules-cache-path="$OUT/mc" \
        -I "$D/scenario/include" -I "$RSDB/include" -I "$RSDB" -c "$f" -o "$o"
    objs+=("$o")
done
xcrun --sdk iphonesimulator swiftc -target arm64-apple-ios26.1-simulator -sdk "$SDK" \
    -Xcc -fmodule-map-file="$OUT/maps/OFScenario/module.modulemap" -Xcc -I"$D/scenario/include" \
    -Xcc -fmodule-map-file="$OUT/maps/RSDatabaseObjC/module.modulemap" -Xcc -I"$RSDB/include" -Xcc -I"$RSDB" \
    -module-cache-path "$OUT/mc" "$D/main.swift" "${objs[@]}" -lsqlite3 -o "$OUT/guestobjcfoundation"
source "$D/../sim_lock.zsh"
sim_lock_acquire
DEV=$(xcrun simctl create "iPhone 16-guestobjcfoundation" "iPhone 16" com.apple.CoreSimulator.SimRuntime.iOS-26-1)
trap 'xcrun simctl shutdown "$DEV" >/dev/null 2>&1; xcrun simctl delete "$DEV" >/dev/null 2>&1; sim_lock_release' EXIT
timeout 180 xcrun simctl boot "$DEV"
timeout 180 xcrun simctl bootstatus "$DEV" -b >/dev/null 2>&1
timeout 60 xcrun simctl spawn "$DEV" "$OUT/guestobjcfoundation" > "$D/transcript-ios26.1.txt"
cat "$D/transcript-ios26.1.txt"
