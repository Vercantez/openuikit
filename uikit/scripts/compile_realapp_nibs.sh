#!/bin/zsh
# Compile the pocket-casts xibs the real-app harness needs into the NIBArchive
# files OpenUIKit's UINib reads (fixtures/realapp/nibs/).
#
# `UINib` loads the COMPILED artefact, which is what ships in an app bundle;
# the xib XML never reaches a device. So the fixtures are `ibtool --compile`
# output, and this script is how they are regenerated — the same relationship
# fixtures/realapp/assets has with the app's asset catalog.
#
#   scripts/compile_realapp_nibs.sh [path-to-pocket-casts-ios]
#
# The corpus is not vendored (docs/REAL_APP_TEST.md "Reproducing"); pass its
# path or set POCKET_CASTS. Requires Xcode's ibtool (macOS only) — hence the
# checked-in fixtures, so the Linux build and CI need neither.
set -e
cd "$(dirname "$0")/.."

CORPUS=${1:-${POCKET_CASTS:-../scratch/ladder-corpus/pocket-casts-ios}}
if [[ ! -d "$CORPUS/podcasts" ]]; then
  echo "compile_realapp_nibs: no pocket-casts checkout at $CORPUS" >&2
  echo "usage: scripts/compile_realapp_nibs.sh <path-to-pocket-casts-ios>" >&2
  exit 1
fi

OUT=fixtures/realapp/nibs
mkdir -p "$OUT"

# SwitchCell / DisclosureCell are the two cells every small settings screen
# registers; StorageAndDataUseViewController.xib is the screen itself (its
# `settingsTable` and `view` are File's-Owner outlets).
for name in SwitchCell DisclosureCell StorageAndDataUseViewController; do
  src="$CORPUS/podcasts/$name.xib"
  [[ -f "$src" ]] || { echo "compile_realapp_nibs: missing $src" >&2; exit 1; }
  xcrun ibtool --compile "$OUT/$name.nib" "$src"
  echo "  $OUT/$name.nib  ($(wc -c < "$OUT/$name.nib" | tr -d ' ') bytes)"
done

echo "compiled from $CORPUS/podcasts"
