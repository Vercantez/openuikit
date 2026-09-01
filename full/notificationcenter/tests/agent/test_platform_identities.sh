#!/usr/bin/env bash
# Stage canonical Foundation+UIKit modules, build NotificationCenter with no
# fallback path, and prove UIEdgeInsets / UIVibrancyEffect / NSExtensionContext
# keep UIKit/Foundation identities. Products stay in a temp directory.
set -euo pipefail

die() {
    printf 'NOTIFICATIONCENTER_PLATFORM_GATE_REFUSING: %s\n' "$*" >&2
    exit 1
}

SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)
FRAMEWORK_ROOT=$(CDPATH= cd -- "$SCRIPT_DIR/../.." && pwd -P)
REPO_ROOT=$(git -C "$FRAMEWORK_ROOT" rev-parse --show-toplevel 2>/dev/null) \
    || die 'framework seed is not inside a Git worktree'
STAGE_SOURCES=$SCRIPT_DIR/platform-stage

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

TMP=$(mktemp -d "${TMPDIR:-/tmp}/notificationcenter-platform.XXXXXX") \
    || die 'cannot create platform-test directory'
cleanup() {
    rm -rf -- "$TMP"
}
trap cleanup EXIT HUP INT TERM

STAGE=$TMP/stage
mkdir -p "$STAGE"

swiftc -warnings-as-errors -parse-as-library -emit-library -emit-module \
    -module-name Foundation \
    -emit-module-path "$STAGE/Foundation.swiftmodule" \
    -emit-module-interface-path "$STAGE/Foundation.swiftinterface" \
    -enable-library-evolution -no-verify-emitted-module-interface \
    -o "$STAGE/libFoundation.dylib" \
    "$STAGE_SOURCES/StagedFoundation.swift"
test -s "$STAGE/libFoundation.dylib" || die 'staged libFoundation.dylib missing'
grep -Fq 'class NSExtensionContext' "$STAGE/Foundation.swiftinterface" \
    || die 'staged Foundation interface lacks NSExtensionContext'

swiftc -warnings-as-errors -parse-as-library -emit-library -emit-module \
    -I "$STAGE" \
    -module-name UIKit \
    -emit-module-path "$STAGE/UIKit.swiftmodule" \
    -emit-module-interface-path "$STAGE/UIKit.swiftinterface" \
    -enable-library-evolution -no-verify-emitted-module-interface \
    -o "$STAGE/libUIKit.dylib" \
    "$STAGE/libFoundation.dylib" \
    "$STAGE_SOURCES/StagedUIKit.swift"
test -s "$STAGE/libUIKit.dylib" || die 'staged libUIKit.dylib missing'
grep -Fq 'struct UIEdgeInsets' "$STAGE/UIKit.swiftinterface" \
    || die 'staged UIKit interface lacks UIEdgeInsets'
grep -Fq 'class UIVibrancyEffect' "$STAGE/UIKit.swiftinterface" \
    || die 'staged UIKit interface lacks UIVibrancyEffect'

mapfile -t SOURCES < "$FRAMEWORK_ROOT/notificationcenter_guest_sources.txt"
SOURCE_PATHS=()
for relative in "${SOURCES[@]}"; do
    SOURCE_PATHS+=("$REPO_ROOT/$relative")
done

swiftc -warnings-as-errors -parse-as-library -emit-library -emit-module \
    -I "$STAGE" \
    -module-name NotificationCenter \
    -emit-module-path "$STAGE/NotificationCenter.swiftmodule" \
    -emit-module-interface-path "$STAGE/NotificationCenter.swiftinterface" \
    -enable-library-evolution -no-verify-emitted-module-interface \
    -o "$STAGE/libNotificationCenter.dylib" \
    "$STAGE/libFoundation.dylib" "$STAGE/libUIKit.dylib" \
    "${SOURCE_PATHS[@]}"
test -s "$STAGE/libNotificationCenter.dylib" \
    || die 'libNotificationCenter.dylib was not produced'

INTERFACE=$STAGE/NotificationCenter.swiftinterface
if grep -Eq '^public struct UIEdgeInsets|^open class UIVibrancyEffect|^public class UIVibrancyEffect|^open class NSExtensionContext|^public class NSExtensionContext' "$INTERFACE"; then
    die 'NotificationCenter.swiftinterface declares a fallback nominal type'
fi
grep -Fq 'extension UIKit.UIVibrancyEffect' "$INTERFACE" \
    || die 'NotificationCenter.swiftinterface lacks UIVibrancyEffect extension'
grep -Fq 'extension Foundation.NSExtensionContext' "$INTERFACE" \
    || die 'NotificationCenter.swiftinterface lacks NSExtensionContext extension'
grep -Fq 'UIKit.UIEdgeInsets' "$INTERFACE" \
    || die 'NotificationCenter.swiftinterface dropped UIKit.UIEdgeInsets signatures'

NM_OUT=$STAGE/notificationcenter.nm
nm -g "$STAGE/libNotificationCenter.dylib" > "$NM_OUT"
FORBIDDEN=$STAGE/forbidden-nominals.txt
: > "$FORBIDDEN"
if grep -E '\$s18NotificationCenter12UIEdgeInsetsV|\$s18NotificationCenter16UIVibrancyEffectC|\$s18NotificationCenter18NSExtensionContextC' "$NM_OUT" \
    > "$FORBIDDEN"; then
    die "dylib emitted NotificationCenter-owned fallback types: $(tr '\n' ' ' < "$FORBIDDEN")"
fi
FORBIDDEN_COUNT=$(grep -c . "$FORBIDDEN" || true)
[ "$FORBIDDEN_COUNT" -eq 0 ] \
    || die "forbidden nominal count $FORBIDDEN_COUNT, expected 0"

strings "$STAGE/NotificationCenter.swiftmodule" > "$STAGE/module.strings"
if grep -E 'NotificationCenter\.UIEdgeInsets|NotificationCenter\.UIVibrancyEffect|NotificationCenter\.NSExtensionContext' \
    "$STAGE/module.strings"; then
    die 'swiftmodule strings contain NotificationCenter-owned fallback identities'
fi

DIFF_EXPECT=$STAGE/interface-expected.txt
DIFF_ACTUAL=$STAGE/interface-actual.txt
{
    echo 'extension Foundation.NSExtensionContext'
    echo 'extension UIKit.UIVibrancyEffect'
    echo 'UIKit.UIEdgeInsets'
    echo 'notificationCenter()'
    echo 'widgetPrimary()'
    echo 'widgetSecondary()'
    echo 'widgetEffect(forVibrancyStyle'
    echo 'widgetMarginInsets'
} | LC_ALL=C sort > "$DIFF_EXPECT"
{
    grep -F 'extension Foundation.NSExtensionContext' "$INTERFACE"
    grep -F 'extension UIKit.UIVibrancyEffect' "$INTERFACE"
    grep -F 'UIKit.UIEdgeInsets' "$INTERFACE"
    grep -F 'notificationCenter()' "$INTERFACE"
    grep -F 'widgetPrimary()' "$INTERFACE"
    grep -F 'widgetSecondary()' "$INTERFACE"
    grep -F 'widgetEffect(forVibrancyStyle' "$INTERFACE"
    grep -F 'widgetMarginInsets' "$INTERFACE"
} | sed 's/^[[:space:]]*//' | LC_ALL=C sort -u > "$DIFF_ACTUAL"
python3 -B - "$DIFF_EXPECT" "$DIFF_ACTUAL" <<'PY' || die 'interface token diff failed'
import sys
from pathlib import Path
expected = [line.strip() for line in Path(sys.argv[1]).read_text().splitlines() if line.strip()]
actual = Path(sys.argv[2]).read_text()
missing = [token for token in expected if token not in actual]
if missing:
    raise SystemExit("missing interface tokens: " + ", ".join(missing))
PY

swiftc -warnings-as-errors -I "$STAGE" \
    "$SCRIPT_DIR/NotificationCenterIdentityProbe.swift" \
    "$STAGE/libFoundation.dylib" "$STAGE/libUIKit.dylib" \
    "$STAGE/libNotificationCenter.dylib" \
    -o "$STAGE/identity-probe"

swiftc -warnings-as-errors -I "$STAGE" \
    "$SCRIPT_DIR/NotificationCenterRuntime.swift" \
    "$STAGE/libFoundation.dylib" "$STAGE/libUIKit.dylib" \
    "$STAGE/libNotificationCenter.dylib" \
    -o "$STAGE/platform-runtime"

export LD_LIBRARY_PATH="$STAGE${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}"
identity_output=$("$STAGE/identity-probe")
printf '%s\n' "$identity_output" | grep -Fqx 'NOTIFICATIONCENTER_IDENTITY_PROBE_OK' \
    || die 'identity probe did not emit NOTIFICATIONCENTER_IDENTITY_PROBE_OK'
runtime_output=$("$STAGE/platform-runtime")
printf '%s\n' "$runtime_output" | grep -Fqx 'NOTIFICATIONCENTER_AGENT_RUNTIME_OK' \
    || die 'platform runtime did not emit NOTIFICATIONCENTER_AGENT_RUNTIME_OK'

printf '%s\n' "$identity_output"
printf '%s\n' "$runtime_output"
printf 'NOTIFICATIONCENTER_NO_NOMINAL_FALLBACK_TYPES count=%s\n' "$FORBIDDEN_COUNT"
printf 'NOTIFICATIONCENTER_PLATFORM_DYLIB_OK module=NotificationCenter dylib=libNotificationCenter.dylib fallback=absent\n'
printf 'NOTIFICATIONCENTER_PLATFORM_STAGE_OK foundation=staged uikit=staged\n'
