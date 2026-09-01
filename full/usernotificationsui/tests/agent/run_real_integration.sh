#!/usr/bin/env bash
# Real-integration probe. Consumes platform Foundation, UIKit, and
# UserNotifications modules/dylibs. Succeeds only if the client compiles
# `let _: Foundation.NSExtensionContext = context`, passes UIKit.UIColor and
# UserNotifications.UNNotification through the protocol, links
# libUserNotificationsUI.dylib, and emits USERNOTIFICATIONSUI_REAL_INTEGRATION_OK.
# Does not build or import unit-fixture lookalikes.
set -euo pipefail

die() {
    printf 'USERNOTIFICATIONSUI_REAL_INTEGRATION_REFUSING: %s\n' "$*" >&2
    exit 1
}

SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)
FRAMEWORK_ROOT=$(CDPATH= cd -- "$SCRIPT_DIR/../.." && pwd -P)
REPO_ROOT=$(git -C "$FRAMEWORK_ROOT" rev-parse --show-toplevel 2>/dev/null) \
    || die 'framework seed is not inside a Git worktree'

STAGE=$(mktemp -d "${TMPDIR:-/tmp}/usernotificationsui-real-integration.XXXXXX") \
    || die 'cannot create real-integration directory'
cleanup() {
    rm -rf -- "$STAGE"
}
trap cleanup EXIT HUP INT TERM

cat > "$STAGE/ProbeFoundationNSExtensionContext.swift" << 'EOF'
import Foundation

@main
enum ProbeFoundationNSExtensionContext {
    static func main() {
        let _: Foundation.NSExtensionContext.Type = NSExtensionContext.self
        print("FOUNDATION_NSEXTENSIONCONTEXT_PRESENT")
    }
}
EOF

if ! swiftc -warnings-as-errors -parse-as-library \
    "$STAGE/ProbeFoundationNSExtensionContext.swift" \
    -o "$STAGE/probe-foundation-nsextensioncontext" \
    >"$STAGE/probe-foundation.log" 2>&1; then
    printf 'USERNOTIFICATIONSUI_REAL_INTEGRATION_BLOCKED missing=Foundation.NSExtensionContext\n'
    printf 'USERNOTIFICATIONSUI_REAL_INTEGRATION_BLOCKER_DETAIL toolchain Foundation has no NSExtensionContext; UserNotificationsUI will not invent a second universe\n'
    exit 0
fi

"$STAGE/probe-foundation-nsextensioncontext" \
    | grep -Fqx -- 'FOUNDATION_NSEXTENSIONCONTEXT_PRESENT' \
    || die 'Foundation.NSExtensionContext probe did not run'

PLATFORM_ROOT=${USERNOTIFICATIONSUI_PLATFORM_ROOT:-}
if [ -z "$PLATFORM_ROOT" ]; then
    for candidate in \
        "${OPENUIKIT_STAGE:-}" \
        "$REPO_ROOT/scratch/core-guest" \
        "$REPO_ROOT/scratch/guest-stage"
    do
        if [ -n "$candidate" ] && [ -d "$candidate/modules" ] && [ -d "$candidate/lib" ]; then
            PLATFORM_ROOT=$candidate
            break
        fi
    done
fi

[ -n "$PLATFORM_ROOT" ] || {
    printf 'USERNOTIFICATIONSUI_REAL_INTEGRATION_BLOCKED missing=platform UIKit,UserNotifications dylibs\n'
    printf 'USERNOTIFICATIONSUI_REAL_INTEGRATION_BLOCKER_DETAIL Foundation.NSExtensionContext is present but no platform UIKit/UserNotifications stage was found; set USERNOTIFICATIONSUI_PLATFORM_ROOT\n'
    exit 0
}

for required in \
    "$PLATFORM_ROOT/modules/UIKit.swiftmodule" \
    "$PLATFORM_ROOT/modules/UserNotifications.swiftmodule" \
    "$PLATFORM_ROOT/lib/libUIKit.dylib" \
    "$PLATFORM_ROOT/lib/libUserNotifications.dylib"
do
    [ -e "$required" ] || {
        printf 'USERNOTIFICATIONSUI_REAL_INTEGRATION_BLOCKED missing=%s\n' "$required"
        exit 0
    }
done

mapfile -t SOURCES < "$FRAMEWORK_ROOT/usernotificationsui_guest_sources.txt"
SOURCE_PATHS=()
for relative in "${SOURCES[@]}"; do
    SOURCE_PATHS+=("$REPO_ROOT/$relative")
done

INCLUDE=(-I "$PLATFORM_ROOT/modules")
LIBS=(
    "$PLATFORM_ROOT/lib/libUIKit.dylib"
    "$PLATFORM_ROOT/lib/libUserNotifications.dylib"
)
if [ -e "$PLATFORM_ROOT/lib/libFoundation.dylib" ]; then
    LIBS+=("$PLATFORM_ROOT/lib/libFoundation.dylib")
    INCLUDE+=(-I "$PLATFORM_ROOT/modules")
fi

# Rebuild UserNotificationsUI against the platform modules (no unit-fixture).
mkdir -p "$STAGE/sg"
swiftc -warnings-as-errors -parse-as-library \
    -emit-library -emit-module \
    -module-name UserNotificationsUI \
    "${INCLUDE[@]}" \
    -emit-module-path "$STAGE/UserNotificationsUI.swiftmodule" \
    -emit-symbol-graph -emit-symbol-graph-dir "$STAGE/sg" \
    -o "$STAGE/libUserNotificationsUI.dylib" \
    "${SOURCE_PATHS[@]}" \
    "${LIBS[@]}"

python3 -B - "$STAGE" <<'PY'
from pathlib import Path
import json
import sys

stage = Path(sys.argv[1])
owned_titles = {"UIColor", "UNNotification", "NSExtensionContext"}
for graph_path in sorted((stage / "sg").glob("*.json")):
    graph = json.loads(graph_path.read_text(encoding="utf-8"))
    if (graph.get("module") or {}).get("name") != "UserNotificationsUI":
        continue
    for symbol in graph.get("symbols") or []:
        kind = ((symbol.get("kind") or {}).get("identifier")) or ""
        title = ((symbol.get("names") or {}).get("title")) or ""
        if kind in {"swift.class", "swift.struct"} and title in owned_titles:
            raise SystemExit(f"symbol graph defines {title}")
print("USERNOTIFICATIONSUI_REAL_INTEGRATION_GRAPH_OK")
PY

swiftc -warnings-as-errors -parse-as-library \
    "${INCLUDE[@]}" -I "$STAGE" \
    "$SCRIPT_DIR/UserNotificationsUIRealIntegration.swift" \
    "$STAGE/libUserNotificationsUI.dylib" \
    "${LIBS[@]}" \
    -o "$STAGE/real-integration"

export LD_LIBRARY_PATH="$STAGE:$PLATFORM_ROOT/lib${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}"
output=$("$STAGE/real-integration")
printf '%s\n' "$output"
printf '%s\n' "$output" | grep -Fqx -- 'USERNOTIFICATIONSUI_REAL_INTEGRATION_OK' \
    || die 'real-integration marker missing'
printf 'USERNOTIFICATIONSUI_REAL_INTEGRATION_OK dylib=libUserNotificationsUI.dylib\n'
