#!/bin/zsh
# Reproduce the app-compat census in docs/APP_COMPAT.md.
#
# Regenerates BOTH inputs from source so the measurement is not a stale file:
#   --sdk-types  every @interface/@protocol name in the real UIKit headers
#   --ours       every public UI*/NS*/CA* type OpenUIKit declares
#
# Usage: Tools/apicensus/run.sh <dir-of-app-checkouts> [out.json]
#
# The corpus is not vendored (four large third-party repos). Clone them into
# one directory, one subdirectory per app; the census scans every .swift under
# each. The published numbers used:
#   artsy/eidolon  duckduckgo/iOS  kickstarter/ios-oss  Automattic/pocket-casts-ios
set -e
cd "$(dirname "$0")/../.."

APPS="${1:?usage: run.sh <dir-of-app-checkouts> [out.json]}"
OUT="${2:-Tools/apicensus/census-latest.json}"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

SDK="$(xcrun --sdk macosx --show-sdk-path)/System/iOSSupport/System/Library/Frameworks/UIKit.framework/Headers"
[ -d "$SDK" ] || { echo "no UIKit headers at $SDK (need Xcode with Mac Catalyst)"; exit 1; }

grep -rhoE '^@(interface|protocol)[[:space:]]+[A-Za-z_][A-Za-z0-9_]*' "$SDK" \
  | awk '{print $2}' | sort -u > "$TMP/sdk_types.txt"

grep -rhoE '^[[:space:]]*(public|open)[[:space:]]+(final[[:space:]]+)?(class|struct|enum|protocol|typealias)[[:space:]]+[A-Za-z_][A-Za-z0-9_]*' \
     Sources/OpenUIKit --include='*.swift' \
  | awk '{print $NF}' | sort -u | grep -E '^(UI|NS|CA)' > "$TMP/ours.txt"

echo "UIKit SDK types: $(wc -l < "$TMP/sdk_types.txt")"
echo "OpenUIKit exports: $(wc -l < "$TMP/ours.txt")"

python3 Tools/apicensus/census.py \
  --apps "$APPS" --sdk-types "$TMP/sdk_types.txt" --ours "$TMP/ours.txt" \
  --json "$OUT" --top 30
