#!/bin/bash
# Compile-only patches to fetched pod sources that Swift 6.2.1 (Xcode 26.1)
# rejects in Swift 4 mode. Each is behavior-identical. The app's own sources
# are never patched.
set -euo pipefail
R="$(cd "$(dirname "$0")" && pwd)"   # this recipe dir (inputs, committed)
G="${EIDOLON_GOLDEN_WORK:?set EIDOLON_GOLDEN_WORK to a scratch dir}"   # outputs
P=$G/work/eidolon/Pods

# P1 RxCocoa 4.1.2 iOS/DataSources: the SequenceWrapper subclass declares
# `typealias Element = S`, which the current compiler lets shadow the inherited
# CellFactory's Element, so its pass-through `override init(cellFactory:)`
# (body: super.init(cellFactory:)) "does not override". Deleting that redundant
# override makes the subclass inherit the identical designated initializer
# (verified with a minimal repro, scratchpad/golden/repro/).
# The SAME patch files the port's EidolonSourceOverlay plugin applies
# (uikit/Sources/EidolonDependencies/overlays/, README there), so both builds
# compile identical source.
OV="$R/../../../../../Sources/EidolonDependencies/overlays"
for f in RxTableViewReactiveArrayDataSource RxCollectionViewReactiveArrayDataSource; do
  (cd "$P/RxCocoa" && patch -s -p1 -N -i "$OV/$f.swift.patch")
done
echo "patches applied"
