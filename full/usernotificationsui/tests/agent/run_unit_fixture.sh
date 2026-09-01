#!/usr/bin/env bash
# Isolated unit-fixture mode. Compiles lookalike NSExtensionContext and a
# test-owned UIKit module only so the protocol typechecks. Compiles repository
# UserNotifications sources. Does not prove Foundation.NSExtensionContext or
# platform UIKit.UIColor identity.
set -euo pipefail

die() {
    printf 'USERNOTIFICATIONSUI_UNIT_FIXTURE_REFUSING: %s\n' "$*" >&2
    exit 1
}

SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)
FRAMEWORK_ROOT=$(CDPATH= cd -- "$SCRIPT_DIR/../.." && pwd -P)
REPO_ROOT=$(git -C "$FRAMEWORK_ROOT" rev-parse --show-toplevel 2>/dev/null) \
    || die 'framework seed is not inside a Git worktree'

for stale in .build build scratch; do
    [ ! -e "$FRAMEWORK_ROOT/$stale" ] \
        || die "stale product directory exists: $stale"
done

mapfile -t SOURCES < "$FRAMEWORK_ROOT/usernotificationsui_guest_sources.txt"
SOURCE_PATHS=()
for relative in "${SOURCES[@]}"; do
    SOURCE_PATHS+=("$REPO_ROOT/$relative")
done

STAGE=$(mktemp -d "${TMPDIR:-/tmp}/usernotificationsui-unit-fixture.XXXXXX") \
    || die 'cannot create unit-fixture directory'
cleanup() {
    rm -rf -- "$STAGE"
}
trap cleanup EXIT HUP INT TERM

swiftc -warnings-as-errors -parse-as-library -emit-library -emit-module \
    -module-name UnitFixtureFoundation \
    -emit-module-path "$STAGE/UnitFixtureFoundation.swiftmodule" \
    -o "$STAGE/libUnitFixtureFoundation.dylib" \
    "$SCRIPT_DIR/fixtures/UnitFixtureNSExtensionContext.swift"

swiftc -warnings-as-errors -parse-as-library -emit-library -emit-module \
    -module-name UIKit \
    -I "$STAGE" \
    -emit-module-path "$STAGE/UIKit.swiftmodule" \
    -o "$STAGE/libUIKit.dylib" \
    "$SCRIPT_DIR/fixtures/UnitFixtureUIKit.swift" \
    "$STAGE/libUnitFixtureFoundation.dylib"

swiftc -warnings-as-errors -parse-as-library -emit-library -emit-module \
    -module-name UserNotifications \
    -emit-module-path "$STAGE/UserNotifications.swiftmodule" \
    -o "$STAGE/libUserNotifications.dylib" \
    "$REPO_ROOT/full/usernotifications/UserNotifications.swift"

mkdir -p "$STAGE/sg"
swiftc -warnings-as-errors -parse-as-library \
    -emit-library -emit-module \
    -module-name UserNotificationsUI \
    -I "$STAGE" \
    -emit-module-path "$STAGE/UserNotificationsUI.swiftmodule" \
    -emit-symbol-graph -emit-symbol-graph-dir "$STAGE/sg" \
    -o "$STAGE/libUserNotificationsUI.dylib" \
    "${SOURCE_PATHS[@]}" \
    "$STAGE/libUIKit.dylib" \
    "$STAGE/libUserNotifications.dylib" \
    "$STAGE/libUnitFixtureFoundation.dylib"

test -s "$STAGE/libUserNotificationsUI.dylib" \
    || die 'unit-fixture libUserNotificationsUI.dylib was not produced'

python3 -B - "$STAGE" <<'PY'
from pathlib import Path
import json
import sys

stage = Path(sys.argv[1])
owned_titles = {"UIColor", "UNNotification", "NSExtensionContext"}
for graph_path in sorted((stage / "sg").glob("*.json")):
    graph = json.loads(graph_path.read_text(encoding="utf-8"))
    module_name = (graph.get("module") or {}).get("name")
    if module_name != "UserNotificationsUI":
        continue
    for symbol in graph.get("symbols") or []:
        kind = ((symbol.get("kind") or {}).get("identifier")) or ""
        title = ((symbol.get("names") or {}).get("title")) or ""
        if kind in {"swift.class", "swift.struct"} and title in owned_titles:
            precise = ((symbol.get("identifier") or {}).get("precise")) or ""
            raise SystemExit(f"symbol graph defines {title} ({precise})")
print("USERNOTIFICATIONSUI_UNIT_FIXTURE_GRAPH_OK")
PY

swiftc -warnings-as-errors -parse-as-library -I "$STAGE" \
    "$SCRIPT_DIR/UserNotificationsUIExistentialDispatch.swift" \
    "$STAGE/libUserNotificationsUI.dylib" \
    "$STAGE/libUIKit.dylib" \
    "$STAGE/libUserNotifications.dylib" \
    "$STAGE/libUnitFixtureFoundation.dylib" \
    -o "$STAGE/existential-dispatch"

export LD_LIBRARY_PATH="$STAGE${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}"
dispatch_output=$("$STAGE/existential-dispatch")
printf '%s\n' "$dispatch_output"
printf '%s\n' "$dispatch_output" | grep -Fqx -- 'USERNOTIFICATIONSUI_EXISTENTIAL_DISPATCH_OK' \
    || die 'existential dispatch marker missing'

printf 'USERNOTIFICATIONSUI_UNIT_FIXTURE_OK dispatch=existential userNotifications=repository uikit=lookalike nsextensioncontext=lookalike\n'
