#!/usr/bin/env bash
# Isolated unit-fixture mode. Compiles a test-owned UIKit module so the protocol
# typechecks, plus repository UserNotifications. Probes Foundation.NSExtensionContext
# first: if present, omit the lookalike context so the product extends
# Foundation.NSExtensionContext. If absent, compile UnitFixtureFoundation as a
# clearly isolated test-only context and pass
# USERNOTIFICATIONSUI_UNIT_FIXTURE_LOOKALIKE_CONTEXT. Does not name a module
# Foundation and does not prove platform UIKit.UIColor identity.
set -euo pipefail

die() {
    printf 'USERNOTIFICATIONSUI_UNIT_FIXTURE_REFUSING: %s\n' "$*" >&2
    exit 1
}

refuse_ambiguous() {
    local log=$1
    if grep -Eqi 'ambiguous(ly)?[[:space:]]+(type|for type)|NSExtensionContext.*ambiguous|ambiguous.*NSExtensionContext' "$log"; then
        cat "$log" >&2
        die 'ambiguous NSExtensionContext diagnostic'
    fi
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

# Darwin Foundation's CGRect has no `.zero`. Keep the portable initializer.
if grep -nE -- 'CGRect\.zero|[[:space:]]==[[:space:]]*\.zero|[[:space:]]\{[[:space:]]*\.zero[[:space:]]*\}' \
    "${SOURCE_PATHS[@]}" \
    "$SCRIPT_DIR/UserNotificationsUIExistentialDispatch.swift"; then
    die 'CGRect.zero is not portable; use CGRect(x:y:width:height:)'
fi

STAGE=$(mktemp -d "${TMPDIR:-/tmp}/usernotificationsui-unit-fixture.XXXXXX") \
    || die 'cannot create unit-fixture directory'
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

CONTEXT_KIND=lookalike
if swiftc -warnings-as-errors -parse-as-library \
    "$STAGE/ProbeFoundationNSExtensionContext.swift" \
    -o "$STAGE/probe-foundation-nsextensioncontext" \
    >"$STAGE/probe-foundation.log" 2>&1; then
    "$STAGE/probe-foundation-nsextensioncontext" \
        | grep -Fqx -- 'FOUNDATION_NSEXTENSIONCONTEXT_PRESENT' \
        || die 'Foundation.NSExtensionContext probe did not run'
    CONTEXT_KIND=foundation
else
    refuse_ambiguous "$STAGE/probe-foundation.log"
    swiftc -warnings-as-errors -parse-as-library -emit-library -emit-module \
        -module-name UnitFixtureFoundation \
        -emit-module-path "$STAGE/UnitFixtureFoundation.swiftmodule" \
        -o "$STAGE/libUnitFixtureFoundation.dylib" \
        "$SCRIPT_DIR/fixtures/UnitFixtureNSExtensionContext.swift"
fi

UIKIT_CMD=(
    swiftc -warnings-as-errors -parse-as-library -emit-library -emit-module
    -module-name UIKit
    -I "$STAGE"
    -emit-module-path "$STAGE/UIKit.swiftmodule"
    -o "$STAGE/libUIKit.dylib"
    "$SCRIPT_DIR/fixtures/UnitFixtureUIKit.swift"
)
PRODUCT_CMD=(
    swiftc -warnings-as-errors -parse-as-library
    -emit-library -emit-module
    -module-name UserNotificationsUI
    -I "$STAGE"
    -emit-module-path "$STAGE/UserNotificationsUI.swiftmodule"
    -emit-symbol-graph -emit-symbol-graph-dir "$STAGE/sg"
    -o "$STAGE/libUserNotificationsUI.dylib"
    "${SOURCE_PATHS[@]}"
    "$STAGE/libUIKit.dylib"
    "$STAGE/libUserNotifications.dylib"
)
DISPATCH_CMD=(
    swiftc -warnings-as-errors -parse-as-library -I "$STAGE"
    "$SCRIPT_DIR/UserNotificationsUIExistentialDispatch.swift"
    "$STAGE/libUserNotificationsUI.dylib"
    "$STAGE/libUIKit.dylib"
    "$STAGE/libUserNotifications.dylib"
    -o "$STAGE/existential-dispatch"
)

if [ "$CONTEXT_KIND" = lookalike ]; then
    UIKIT_CMD+=("$STAGE/libUnitFixtureFoundation.dylib")
    PRODUCT_CMD+=(
        -D USERNOTIFICATIONSUI_UNIT_FIXTURE_LOOKALIKE_CONTEXT
        "$STAGE/libUnitFixtureFoundation.dylib"
    )
    DISPATCH_CMD+=("$STAGE/libUnitFixtureFoundation.dylib")
    [ -e "$STAGE/UnitFixtureFoundation.swiftmodule" ] \
        || die 'lookalike UnitFixtureFoundation.swiftmodule was not produced'
    [ -e "$STAGE/libUnitFixtureFoundation.dylib" ] \
        || die 'lookalike libUnitFixtureFoundation.dylib was not produced'
else
    [ ! -e "$STAGE/UnitFixtureFoundation.swiftmodule" ] \
        || die 'UnitFixtureFoundation.swiftmodule must be omitted when Foundation.NSExtensionContext exists'
    [ ! -e "$STAGE/libUnitFixtureFoundation.dylib" ] \
        || die 'libUnitFixtureFoundation.dylib must be omitted when Foundation.NSExtensionContext exists'
fi

"${UIKIT_CMD[@]}"

swiftc -warnings-as-errors -parse-as-library -emit-library -emit-module \
    -module-name UserNotifications \
    -emit-module-path "$STAGE/UserNotifications.swiftmodule" \
    -o "$STAGE/libUserNotifications.dylib" \
    "$REPO_ROOT/full/usernotifications/UserNotifications.swift"

mkdir -p "$STAGE/sg"
if ! "${PRODUCT_CMD[@]}" >"$STAGE/product-compile.log" 2>&1; then
    cat "$STAGE/product-compile.log" >&2
    refuse_ambiguous "$STAGE/product-compile.log"
    die 'UserNotificationsUI unit-fixture compile failed'
fi
refuse_ambiguous "$STAGE/product-compile.log"

if [ "$CONTEXT_KIND" = foundation ]; then
    [ ! -e "$STAGE/UnitFixtureFoundation.swiftmodule" ] \
        || die 'UnitFixtureFoundation leaked into a Foundation.NSExtensionContext unit compile'
fi

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

if ! "${DISPATCH_CMD[@]}" >"$STAGE/dispatch-compile.log" 2>&1; then
    cat "$STAGE/dispatch-compile.log" >&2
    refuse_ambiguous "$STAGE/dispatch-compile.log"
    die 'existential dispatch compile failed'
fi
refuse_ambiguous "$STAGE/dispatch-compile.log"

export LD_LIBRARY_PATH="$STAGE${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}"
dispatch_output=$("$STAGE/existential-dispatch")
printf '%s\n' "$dispatch_output"
printf '%s\n' "$dispatch_output" | grep -Fqx -- 'USERNOTIFICATIONSUI_EXISTENTIAL_DISPATCH_OK' \
    || die 'existential dispatch marker missing'

if [ "$CONTEXT_KIND" = foundation ]; then
    cat > "$STAGE/FoundationContextBind.swift" << 'EOF'
import Foundation
import UserNotificationsUI

@main
enum FoundationContextBind {
    static func main() {
        let _: Foundation.NSExtensionContext.Type = NSExtensionContext.self
        let _: (Foundation.NSExtensionContext) -> Void = { context in
            context.dismissNotificationContentExtension()
        }
        print("USERNOTIFICATIONSUI_UNIT_FIXTURE_FOUNDATION_CONTEXT_OK")
    }
}
EOF
    if ! swiftc -warnings-as-errors -parse-as-library -I "$STAGE" \
        "$STAGE/FoundationContextBind.swift" \
        "$STAGE/libUserNotificationsUI.dylib" \
        "$STAGE/libUIKit.dylib" \
        "$STAGE/libUserNotifications.dylib" \
        -o "$STAGE/foundation-context-bind" \
        >"$STAGE/foundation-bind-compile.log" 2>&1; then
        cat "$STAGE/foundation-bind-compile.log" >&2
        refuse_ambiguous "$STAGE/foundation-bind-compile.log"
        die 'foundation-context bind compile failed'
    fi
    refuse_ambiguous "$STAGE/foundation-bind-compile.log"
    bind_output=$("$STAGE/foundation-context-bind")
    printf '%s\n' "$bind_output"
    printf '%s\n' "$bind_output" \
        | grep -Fqx -- 'USERNOTIFICATIONSUI_UNIT_FIXTURE_FOUNDATION_CONTEXT_OK' \
        || die 'foundation-context bind marker missing'
else
    cat > "$STAGE/LookalikeContextBind.swift" << 'EOF'
import UnitFixtureFoundation
import UserNotificationsUI

@main
enum LookalikeContextBind {
    static func main() {
        let _: (UnitFixtureFoundation.NSExtensionContext) -> Void = { context in
            context.dismissNotificationContentExtension()
        }
        print("USERNOTIFICATIONSUI_UNIT_FIXTURE_LOOKALIKE_CONTEXT_OK")
    }
}
EOF
    if ! swiftc -warnings-as-errors -parse-as-library -I "$STAGE" \
        "$STAGE/LookalikeContextBind.swift" \
        "$STAGE/libUserNotificationsUI.dylib" \
        "$STAGE/libUIKit.dylib" \
        "$STAGE/libUserNotifications.dylib" \
        "$STAGE/libUnitFixtureFoundation.dylib" \
        -o "$STAGE/lookalike-context-bind" \
        >"$STAGE/lookalike-bind-compile.log" 2>&1; then
        cat "$STAGE/lookalike-bind-compile.log" >&2
        refuse_ambiguous "$STAGE/lookalike-bind-compile.log"
        die 'lookalike-context bind compile failed'
    fi
    refuse_ambiguous "$STAGE/lookalike-bind-compile.log"
    bind_output=$("$STAGE/lookalike-context-bind")
    printf '%s\n' "$bind_output"
    printf '%s\n' "$bind_output" \
        | grep -Fqx -- 'USERNOTIFICATIONSUI_UNIT_FIXTURE_LOOKALIKE_CONTEXT_OK' \
        || die 'lookalike-context bind marker missing'
fi

printf 'USERNOTIFICATIONSUI_UNIT_FIXTURE_OK dispatch=existential userNotifications=repository uikit=lookalike nsextensioncontext=%s\n' \
    "$CONTEXT_KIND"
