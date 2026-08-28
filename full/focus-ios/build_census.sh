#!/bin/bash
# build_census.sh -- #93 phase 2. Clear focus-ios's MODULE walls, then run the
# saturated -wmo census against OpenUIKit and classify what is left.
#
#   full/focus-ios/build_census.sh [OUTDIR]
#
# STAGED, AND EVERY STAGE REPORTS RATHER THAN STOPS. A stage that fails is a
# census row, not an abort -- stopping at the first failure is exactly the
# behaviour that produced phase 1's "4 errors" false green.
#
#   1. OpenUIKit          built FRESH from a clone of ~/uikit (never written to)
#   2. stub modules       Glean, FocusAppServices, WebKit, Sentry, Fuzi,
#                         MobileCoreServices -- measured surfaces, see stubs/
#   3. SnapKit            THE REAL SOURCE, recompiled. Not reimplemented:
#                         recompile-from-source is the whole point of the
#                         project, and SnapKit is MIT and pure Swift over
#                         NSLayoutConstraint. Its OpenUIKit gaps are census rows.
#   4. the app's own SPM targets, in dependency order
#   5. the app module
#   6. classify every error and print the breakdown with denominators
#
# ★ -wmo IS NOT OPTIONAL. swiftc's default multi-file mode stops after the first
# file with errors, which understated this app's real count by 266x in phase 1
# (4 vs 1,066). Every typecheck below passes -wmo for that reason.
set -uo pipefail

HERE=$(cd "$(dirname "$0")" && pwd)
SML=$(cd "$HERE/../.." && pwd)
APP=${APP:-$SML/scratch/ladder-corpus/focus-ios/focus-ios}
SNAPKIT=${SNAPKIT:-$SML/scratch/ladder-deps/SnapKit}
OUT=${1:-/tmp/focus-ios-census}
TARGET=${TARGET:-arm64-apple-macos13.0}
UIKIT_SRC=${UIKIT_SRC:-$HOME/uikit}

mkdir -p "$OUT/modules" "$OUT/logs"
say() { printf '%s\n' "$*"; }
hr()  { say ""; say "########## $*"; }

# --- 0. pins, by COMMIT ------------------------------------------------------
hr "0. pins"
say "  focus-ios  $(git -C "$APP" rev-parse HEAD 2>/dev/null)"
say "  SnapKit    $(git -C "$SNAPKIT" rev-parse HEAD 2>/dev/null)"
say "  OpenUIKit  $(git -C "$UIKIT_SRC" rev-parse HEAD 2>/dev/null)"

# --- 1. OpenUIKit, built fresh ----------------------------------------------
hr "1. OpenUIKit (fresh clone; ~/uikit is read-only and is never written)"
UIKIT_CLONE=$OUT/uikit
if [ ! -d "$UIKIT_CLONE" ]; then
    git clone -q --shared "$UIKIT_SRC" "$UIKIT_CLONE" || { say "  clone failed"; exit 2; }
fi
( cd "$UIKIT_CLONE" && swift build -c release --product OpenUIKit ) \
    > "$OUT/logs/openuikit.log" 2>&1
rc=$?
B=$UIKIT_CLONE/.build/arm64-apple-macosx/release
if [ ! -f "$B/Modules/UIKit.swiftmodule" ]; then
    say "  FAILED to build OpenUIKit (rc=$rc) -- see logs/openuikit.log"; exit 3
fi
say "  built: $(ls "$B/Modules"/*.swiftmodule | wc -l | tr -d ' ') modules, UIKit shim present"

INC=(-I "$B/Modules" -I "$B")
for m in $(find "$UIKIT_CLONE/Sources" -name 'module.modulemap'); do
    INC+=(-Xcc -I -Xcc "$(dirname "$m")")
done

# build_mod <module-name> <logname> <srcdir> -- typecheck AND emit a module.
# Takes a DIRECTORY, not an argument list: several focus-ios source paths contain
# SPACES ("Preview Files", "SwiftUI Onboarding"), and an unquoted $(find ...) had
# split them into "unexpected input file" errors that landed in the census as if
# they were the app's problem. Reading a NUL-safe list is the fix.
build_mod() {
    local name=$1; shift
    local log=$1; shift
    local srcdir=$1; shift
    local -a srcs=()
    while IFS= read -r -d '' f; do srcs+=("$f"); done \
        < <(find "$srcdir" -name '*.swift' -print0)
    set -- "${srcs[@]}"
    swiftc -emit-module -emit-module-path "$OUT/modules/$name.swiftmodule" \
        -wmo -target "$TARGET" -module-name "$name" \
        "${INC[@]}" -I "$OUT/modules" "$@" > "$OUT/logs/$log.log" 2>&1
    local r=$?
    local n; n=$(grep -c 'error:' "$OUT/logs/$log.log" 2>/dev/null || echo 0)
    printf '  %-22s %s  (%s errors)\n' "$name" \
        "$([ $r -eq 0 ] && echo OK || echo FAILED)" "$n"
    return $r
}

# --- 2. stub modules ---------------------------------------------------------
hr "2. stub modules (measured surfaces -- see stubs/*/*.swift for what and why)"
for s in Glean FocusAppServices WebKit Sentry Fuzi MobileCoreServices; do
    build_mod "$s" "stub-$s" "$HERE/stubs/$s"
done

# --- 3. SnapKit, the REAL source --------------------------------------------
hr "3. SnapKit -- real upstream source, recompiled against OpenUIKit"
build_mod SnapKit snapkit "$SNAPKIT/Sources"

# --- 4. the app's own SPM targets, dependency order --------------------------
hr "4. focus-ios's own SPM targets"
P=$APP/BlockzillaPackage/Sources
for t in UIHelpers DesignSystem Widget Licenses UIComponents Onboarding AppShortcuts; do
    [ -d "$P/$t" ] || { say "  $t: no such target dir"; continue; }
    build_mod "$t" "target-$t" "$P/$t"
done

# --- 5. the app module -------------------------------------------------------
#
# THE SATURATION PROBLEM, AND THE INSTRUMENT THAT SOLVES IT. Stage 4's targets
# fail on OpenUIKit gaps, so their .swiftmodule is never emitted, so the app's
# `import Onboarding` reports "no such module" and swiftc stops -- and the app
# census reads as 2 errors, which is the SAME false-green shape phase 1 hit.
# The app's errors would be invisible behind an unrelated failure.
#
# So: emit an EMPTY module for each of the app's own SPM target names purely to
# satisfy the import statements, and compile the app's sources TOGETHER WITH the
# package sources as one module, so the real types come from the source in front
# of the compiler rather than from a module that could not be built. The empty
# modules contribute no symbols and therefore cannot mask a gap; they only stop
# `import` from halting the run.
hr "5. name-only modules, so an unbuildable target cannot hide the app's errors"
mkdir -p "$OUT/empty"
# SnapKit is in this list even though its REAL source is compiled at stage 3:
# stage 3 fails on OpenUIKit gaps, so no .swiftmodule is emitted, so the app's
# `import SnapKit` halts the run. The name-only module lets the app census
# proceed; the resulting `has no member 'snp'` errors are attributed to SnapKit
# by classify.py rather than counted against OpenUIKit.
for t in UIHelpers DesignSystem Widget Licenses UIComponents Onboarding AppShortcuts SnapKit; do
    printf '// name-only module: satisfies `import %s`, defines nothing.\n' "$t" \
        > "$OUT/empty/$t.swift"
    swiftc -emit-module -emit-module-path "$OUT/empty/$t.swiftmodule" \
        -wmo -target "$TARGET" -module-name "$t" "$OUT/empty/$t.swift" \
        >> "$OUT/logs/empty.log" 2>&1
done
say "  emitted $(ls "$OUT/empty"/*.swiftmodule 2>/dev/null | wc -l | tr -d ' ') name-only modules"

hr "6. THE SATURATED CENSUS -- all shipping sources, one module, -wmo"
find "$APP" -name '*.swift' \
  | grep -v '/focus-ios-tests/' \
  | grep -v '/Tests/' \
  | grep -v '/ContentBlockerGen/' \
  | grep -v '/Package.swift$' \
  | grep -v 'get_supported_locales.swift' \
  > "$OUT/appfiles.txt"
say "  shipping files: $(wc -l < "$OUT/appfiles.txt" | tr -d ' ')"
files=()
while IFS= read -r l; do files+=("$l"); done < "$OUT/appfiles.txt"
swiftc -typecheck -wmo -target "$TARGET" -module-name Blockzilla \
    "${INC[@]}" -I "$OUT/modules" -I "$OUT/empty" "${files[@]}" \
    > "$OUT/logs/app.log" 2>&1
say "  errors: $(grep -c 'error:' "$OUT/logs/app.log" | tr -d ' ')"

# --- 6. the census -----------------------------------------------------------
hr "7. CENSUS"
python3 "$HERE/classify.py" "$OUT" "$APP" | tee "$OUT/census.txt"
