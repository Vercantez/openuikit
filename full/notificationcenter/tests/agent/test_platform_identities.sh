#!/usr/bin/env bash
# Integration-labelled identity probe.
#
# Consumes actual staged guest Foundation and UIKit module/dylib outputs from
# this repository (or a caller-supplied guest package stage). Never compiles
# tests/agent/platform-stage lookalikes as Foundation or UIKit. If
# Foundation.NSExtensionContext is unavailable, report that central dependency
# blocker and do not emit a platform-success marker.
set -euo pipefail

die() {
    printf 'NOTIFICATIONCENTER_PLATFORM_GATE_REFUSING: %s\n' "$*" >&2
    exit 1
}

blocked() {
    printf 'NOTIFICATIONCENTER_PLATFORM_BLOCKED dependency=%s\n' "$1"
    printf 'NOTIFICATIONCENTER_PLATFORM_IDENTITY_NOT_CLAIMED\n'
    exit 0
}

SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)
FRAMEWORK_ROOT=$(CDPATH= cd -- "$SCRIPT_DIR/../.." && pwd -P)
REPO_ROOT=$(git -C "$FRAMEWORK_ROOT" rev-parse --show-toplevel 2>/dev/null) \
    || die 'framework seed is not inside a Git worktree'

if [ "${NOTIFICATIONCENTER_UNIT_FIXTURE:-}" = "1" ]; then
    die 'NOTIFICATIONCENTER_UNIT_FIXTURE=1 is not a platform identity path; use tests/agent/test_unit_fixture.sh'
fi

command -v swiftc >/dev/null 2>&1 || die 'swiftc is unavailable'
command -v python3 >/dev/null 2>&1 || die 'python3 is unavailable'
command -v nm >/dev/null 2>&1 || die 'nm is unavailable'

python3 -B - "$FRAMEWORK_ROOT" <<'PY' || die 'immutable validator failed'
import pathlib, subprocess, sys
root = pathlib.Path(sys.argv[1]).resolve()
repo = pathlib.Path(subprocess.check_output(
    ["git", "-C", str(root), "rev-parse", "--show-toplevel"],
    text=True,
).strip())
script = repo / "full/framework-fanout/validate_seed.py"
subprocess.check_call(
    [sys.executable, "-B", str(script), "--framework", str(root), "--phase", "deliverable"],
)
PY

is_lookalike_root() {
    local root=$1
    local resolved
    resolved=$(CDPATH= cd -- "$root" && pwd -P)
    case "$resolved" in
        "$SCRIPT_DIR"|"$SCRIPT_DIR"/*|"$FRAMEWORK_ROOT/tests"|"$FRAMEWORK_ROOT/tests"/*)
            return 0
            ;;
    esac
    [ -f "$resolved/StagedFoundation.swift" ] \
        || [ -f "$resolved/StagedUIKit.swift" ] \
        || [ -f "$resolved/NOTIFICATIONCENTER_UNIT_FIXTURE" ]
}

find_module_include() {
    local root=$1
    local name=$2
    if [ -e "$root/modules/${name}.swiftmodule" ]; then
        printf '%s\n' "$root/modules"
        return 0
    fi
    if [ -e "$root/${name}.swiftmodule" ]; then
        printf '%s\n' "$root"
        return 0
    fi
    return 1
}

find_dylib() {
    local root=$1
    local name=$2
    if [ -f "$root/lib/lib${name}.dylib" ]; then
        printf '%s\n' "$root/lib/lib${name}.dylib"
        return 0
    fi
    if [ -f "$root/lib${name}.dylib" ]; then
        printf '%s\n' "$root/lib${name}.dylib"
        return 0
    fi
    return 1
}

collect_stage_candidates() {
    local -a raw=()
    local value
    for value in \
        "${NOTIFICATIONCENTER_PLATFORM_STAGE:-}" \
        "${GUEST_PACKAGE_STAGE:-}" \
        "${OPENUIKIT_GUEST_PACKAGE:-}" \
        "${CORE_GUEST_PACKAGE:-}" \
        "${CORE_GUEST_PACKAGE_STAGE:-}" \
        "${OPENUIKIT_STAGE:-}" \
        "${FOUNDATION_STAGE:-}" \
        "${UIKIT_STAGE:-}"
    do
        [ -n "$value" ] || continue
        raw+=("$value")
    done
    if [ "${#raw[@]}" -eq 0 ]; then
        return 0
    fi
    printf '%s\n' "${raw[@]}"
}

FOUNDATION_INCLUDE=""
FOUNDATION_DYLIB=""
UIKIT_INCLUDE=""
UIKIT_DYLIB=""
STAGE_ROOT=""

while IFS= read -r candidate; do
    [ -n "$candidate" ] || continue
    [ -d "$candidate" ] || continue
    if is_lookalike_root "$candidate"; then
        printf 'NOTIFICATIONCENTER_PLATFORM_GATE_REFUSING: refusing test-owned lookalike stage %s\n' \
            "$candidate" >&2
        continue
    fi
    foundation_include=$(find_module_include "$candidate" Foundation || true)
    foundation_dylib=$(find_dylib "$candidate" Foundation || true)
    uikit_include=$(find_module_include "$candidate" UIKit || true)
    uikit_dylib=$(find_dylib "$candidate" UIKit || true)
    if [ -n "$foundation_include" ] && [ -n "$foundation_dylib" ]; then
        FOUNDATION_INCLUDE=$foundation_include
        FOUNDATION_DYLIB=$foundation_dylib
        STAGE_ROOT=$candidate
    fi
    if [ -n "$uikit_include" ] && [ -n "$uikit_dylib" ]; then
        UIKIT_INCLUDE=$uikit_include
        UIKIT_DYLIB=$uikit_dylib
        STAGE_ROOT=${STAGE_ROOT:-$candidate}
    fi
done < <(collect_stage_candidates)

TMP=$(mktemp -d "${TMPDIR:-/tmp}/notificationcenter-platform.XXXXXX") \
    || die 'cannot create platform-test directory'
cleanup() {
    rm -rf -- "$TMP"
}
trap cleanup EXIT HUP INT TERM

if [ -z "$FOUNDATION_INCLUDE" ] || [ -z "$FOUNDATION_DYLIB" ]; then
    swiftc -warnings-as-errors -typecheck \
        "$SCRIPT_DIR/FoundationNSExtensionContextProbe.swift" \
        >"$TMP/toolchain-foundation-nsextensioncontext.log" 2>&1 || true
    cat "$TMP/toolchain-foundation-nsextensioncontext.log" >&2 || true
    blocked 'Foundation.NSExtensionContext'
fi

if ! swiftc -warnings-as-errors -typecheck \
    -I "$FOUNDATION_INCLUDE" \
    "$SCRIPT_DIR/FoundationNSExtensionContextProbe.swift" \
    >"$TMP/foundation-nsextensioncontext.log" 2>&1
then
    cat "$TMP/foundation-nsextensioncontext.log" >&2 || true
    blocked 'Foundation.NSExtensionContext'
fi

if [ -z "$UIKIT_INCLUDE" ] || [ -z "$UIKIT_DYLIB" ]; then
    blocked 'UIKit.UIEdgeInsets'
fi

if ! swiftc -warnings-as-errors -typecheck \
    -I "$FOUNDATION_INCLUDE" -I "$UIKIT_INCLUDE" \
    "$SCRIPT_DIR/UIKitCanonicalTypesProbe.swift" \
    >"$TMP/uikit-canonical.log" 2>&1
then
    cat "$TMP/uikit-canonical.log" >&2 || true
    blocked 'UIKit.UIEdgeInsets'
fi

mapfile -t SOURCES < "$FRAMEWORK_ROOT/notificationcenter_guest_sources.txt"
SOURCE_PATHS=()
for relative in "${SOURCES[@]}"; do
    SOURCE_PATHS+=("$REPO_ROOT/$relative")
done

INCLUDE_FLAGS=(-I "$FOUNDATION_INCLUDE")
if [ "$UIKIT_INCLUDE" != "$FOUNDATION_INCLUDE" ]; then
    INCLUDE_FLAGS+=(-I "$UIKIT_INCLUDE")
fi

swiftc -warnings-as-errors -parse-as-library -emit-library -emit-module \
    "${INCLUDE_FLAGS[@]}" \
    -D NOTIFICATIONCENTER_HAS_FOUNDATION_EXTENSION_CONTEXT \
    -module-name NotificationCenter \
    -emit-module-path "$TMP/NotificationCenter.swiftmodule" \
    -emit-module-interface-path "$TMP/NotificationCenter.swiftinterface" \
    -enable-library-evolution -no-verify-emitted-module-interface \
    -o "$TMP/libNotificationCenter.dylib" \
    "$FOUNDATION_DYLIB" "$UIKIT_DYLIB" \
    "${SOURCE_PATHS[@]}"
test -s "$TMP/libNotificationCenter.dylib" \
    || die 'libNotificationCenter.dylib was not produced'

INTERFACE=$TMP/NotificationCenter.swiftinterface
if grep -Eq '^public struct UIEdgeInsets|^open class UIVibrancyEffect|^public class UIVibrancyEffect|^open class NSExtensionContext|^public class NSExtensionContext' "$INTERFACE"; then
    die 'NotificationCenter.swiftinterface declares a fallback nominal type'
fi
grep -Fq 'extension UIKit.UIVibrancyEffect' "$INTERFACE" \
    || die 'NotificationCenter.swiftinterface lacks UIVibrancyEffect extension'
grep -Fq 'extension Foundation.NSExtensionContext' "$INTERFACE" \
    || die 'NotificationCenter.swiftinterface lacks NSExtensionContext extension'
grep -Fq 'UIKit.UIEdgeInsets' "$INTERFACE" \
    || die 'NotificationCenter.swiftinterface dropped UIKit.UIEdgeInsets signatures'

NM_OUT=$TMP/notificationcenter.nm
nm -g "$TMP/libNotificationCenter.dylib" > "$NM_OUT" || die 'nm failed on libNotificationCenter.dylib'
FORBIDDEN=$TMP/forbidden-nominals.txt
: > "$FORBIDDEN"
if grep -E '\$s18NotificationCenter12UIEdgeInsetsV|\$s18NotificationCenter16UIVibrancyEffectC|\$s18NotificationCenter18NSExtensionContextC' "$NM_OUT" \
    > "$FORBIDDEN"; then
    die "dylib emitted NotificationCenter-owned fallback types: $(tr '\n' ' ' < "$FORBIDDEN")"
fi
FORBIDDEN_COUNT=$(grep -c . "$FORBIDDEN" || true)
[ "$FORBIDDEN_COUNT" -eq 0 ] \
    || die "forbidden nominal count $FORBIDDEN_COUNT, expected 0"

strings "$TMP/NotificationCenter.swiftmodule" > "$TMP/module.strings"
if grep -E 'NotificationCenter\.UIEdgeInsets|NotificationCenter\.UIVibrancyEffect|NotificationCenter\.NSExtensionContext' \
    "$TMP/module.strings"; then
    die 'swiftmodule strings contain NotificationCenter-owned fallback identities'
fi

swiftc -warnings-as-errors \
    "${INCLUDE_FLAGS[@]}" \
    -D NOTIFICATIONCENTER_HAS_FOUNDATION_EXTENSION_CONTEXT \
    "$SCRIPT_DIR/NotificationCenterIdentityProbe.swift" \
    "$FOUNDATION_DYLIB" "$UIKIT_DYLIB" \
    "$TMP/libNotificationCenter.dylib" \
    -o "$TMP/identity-probe"

LIB_DIR=$(dirname -- "$FOUNDATION_DYLIB")
UIKIT_LIB_DIR=$(dirname -- "$UIKIT_DYLIB")
export LD_LIBRARY_PATH="$TMP:$LIB_DIR:$UIKIT_LIB_DIR${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}"
identity_output=$("$TMP/identity-probe")
printf '%s\n' "$identity_output" | grep -Fqx 'NOTIFICATIONCENTER_IDENTITY_PROBE_OK' \
    || die 'identity probe did not emit NOTIFICATIONCENTER_IDENTITY_PROBE_OK'

printf '%s\n' "$identity_output"
printf 'NOTIFICATIONCENTER_NO_NOMINAL_FALLBACK_TYPES count=%s\n' "$FORBIDDEN_COUNT"
printf 'NOTIFICATIONCENTER_PLATFORM_DYLIB_OK module=NotificationCenter dylib=libNotificationCenter.dylib fallback=absent\n'
printf 'NOTIFICATIONCENTER_PLATFORM_STAGE_OK foundation=guest uikit=guest stage=%s\n' "$STAGE_ROOT"
