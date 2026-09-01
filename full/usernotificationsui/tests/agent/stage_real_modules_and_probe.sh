#!/usr/bin/env bash
# Stage real Foundation/UIKit/UserNotifications modules, build UserNotificationsUI
# with no fallback branch, then run identity and existential-dispatch probes.
set -euo pipefail

die() {
    printf 'USERNOTIFICATIONSUI_STAGED_GATE_REFUSING: %s\n' "$*" >&2
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

command -v python3 >/dev/null 2>&1 || die 'python3 is unavailable'
command -v swiftc >/dev/null 2>&1 || die 'swiftc is unavailable'

mapfile -t SOURCES < "$FRAMEWORK_ROOT/usernotificationsui_guest_sources.txt"
SOURCE_PATHS=()
for relative in "${SOURCES[@]}"; do
    SOURCE_PATHS+=("$REPO_ROOT/$relative")
done

STAGE=$(mktemp -d "${TMPDIR:-/tmp}/usernotificationsui-staged.XXXXXX") \
    || die 'cannot create staging directory'
cleanup() {
    rm -rf -- "$STAGE"
}
trap cleanup EXIT HUP INT TERM

swiftc -warnings-as-errors -parse-as-library -emit-library -emit-module \
    -module-name StagedFoundation \
    -emit-module-path "$STAGE/StagedFoundation.swiftmodule" \
    -o "$STAGE/libStagedFoundation.dylib" \
    "$SCRIPT_DIR/fixtures/StagedFoundation.swift"

swiftc -warnings-as-errors -parse-as-library -emit-library -emit-module \
    -module-name UIKit \
    -I "$STAGE" \
    -emit-module-path "$STAGE/UIKit.swiftmodule" \
    -o "$STAGE/libUIKit.dylib" \
    "$SCRIPT_DIR/fixtures/StagedUIKit.swift" \
    "$STAGE/libStagedFoundation.dylib"

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
    "$STAGE/libStagedFoundation.dylib"

test -s "$STAGE/libUserNotificationsUI.dylib" \
    || die 'staged libUserNotificationsUI.dylib was not produced'

cat > "$STAGE/RejectUserNotificationsUITypes.swift" << 'EOF'
import UserNotificationsUI
let _color: UserNotificationsUI.UIColor? = nil
let _notification: UserNotificationsUI.UNNotification? = nil
let _context: UserNotificationsUI.NSExtensionContext? = nil
EOF
if swiftc -typecheck -I "$STAGE" "$STAGE/RejectUserNotificationsUITypes.swift" \
    >"$STAGE/reject.log" 2>&1; then
    die 'UserNotificationsUI still exports UIColor/UNNotification/NSExtensionContext'
fi
grep -Eq 'UIColor|UNNotification|NSExtensionContext' "$STAGE/reject.log" \
    || die 'negative identity compile did not mention the rejected types'

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
print("USERNOTIFICATIONSUI_INTERFACE_IDENTITY_OK")
PY

swiftc -warnings-as-errors -parse-as-library -I "$STAGE" \
    "$SCRIPT_DIR/UserNotificationsUIIdentityConsumer.swift" \
    "$STAGE/libUserNotificationsUI.dylib" \
    "$STAGE/libUIKit.dylib" \
    "$STAGE/libUserNotifications.dylib" \
    "$STAGE/libStagedFoundation.dylib" \
    -o "$STAGE/identity-consumer"

swiftc -warnings-as-errors -parse-as-library -I "$STAGE" \
    "$SCRIPT_DIR/UserNotificationsUIExistentialDispatch.swift" \
    "$STAGE/libUserNotificationsUI.dylib" \
    "$STAGE/libUIKit.dylib" \
    "$STAGE/libUserNotifications.dylib" \
    "$STAGE/libStagedFoundation.dylib" \
    -o "$STAGE/existential-dispatch"

export LD_LIBRARY_PATH="$STAGE${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}"
identity_output=$("$STAGE/identity-consumer")
printf '%s\n' "$identity_output"
printf '%s\n' "$identity_output" | grep -Fqx -- 'USERNOTIFICATIONSUI_IDENTITY_CONSUMER_OK' \
    || die 'identity consumer marker missing'

dispatch_output=$("$STAGE/existential-dispatch")
printf '%s\n' "$dispatch_output"
printf '%s\n' "$dispatch_output" | grep -Fqx -- 'USERNOTIFICATIONSUI_EXISTENTIAL_DISPATCH_OK' \
    || die 'existential dispatch marker missing'

printf 'USERNOTIFICATIONSUI_STAGED_HOST_OK dylib=libUserNotificationsUI.dylib fallback=inactive\n'
