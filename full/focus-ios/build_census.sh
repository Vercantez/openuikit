#!/bin/bash
# build_census.sh -- #93. Clear focus-ios's MODULE walls, then run the
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
#                         NSLayoutConstraint. One diagnostic-only source file
#                         is excluded by a pinned, hash-checked vendoring rule.
#                         The rule, source denominator, and subject digest are
#                         printed and recorded on every run.
#   4. the app's own SPM targets, in dependency order
#   5. a broad all-source saturation module (not the Xcode target graph)
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

# Reusing a directory can retain an old module or log and manufacture a green
# stage. The census is defined over a fresh output root, so enforce that at the
# boundary instead of relying on the caller to remember.
if [ -d "$OUT" ] && [ -n "$(find "$OUT" -mindepth 1 -maxdepth 1 -print -quit)" ]; then
    printf 'REFUSED: output directory is not empty: %s\n' "$OUT" >&2
    exit 2
fi
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
    compile_mod "$name" "$log" "${srcs[@]}"
}

# compile_mod <module-name> <logname> <source>...
compile_mod() {
    local name=$1; shift
    local log=$1; shift
    swiftc -emit-module -emit-module-path "$OUT/modules/$name.swiftmodule" \
        -wmo -target "$TARGET" -module-name "$name" \
        "${INC[@]}" -I "$OUT/modules" "$@" > "$OUT/logs/$log.log" 2>&1
    local r=$?
    local n; n=$(python3 -B "$HERE/diagnostics.py" count "$OUT/logs/$log.log")
    printf '  %-22s %s  (%s primary diagnostics)\n' "$name" \
        "$([ $r -eq 0 ] && echo OK || echo FAILED)" "$n"
    return $r
}

# build_mod_list <module-name> <logname> <newline-safe-list>
build_mod_list() {
    local name=$1; shift
    local log=$1; shift
    local list=$1; shift
    local -a srcs=()
    while IFS= read -r f; do
        [ -n "$f" ] && srcs+=("$f")
    done < "$list"
    compile_mod "$name" "$log" "${srcs[@]}"
}

# --- 2. stub modules ---------------------------------------------------------
hr "2. stub modules (measured surfaces -- see stubs/*/*.swift for what and why)"
for s in Glean FocusAppServices WebKit Sentry Fuzi MobileCoreServices; do
    build_mod "$s" "stub-$s" "$HERE/stubs/$s"
done

# --- 3. SnapKit, the REAL source --------------------------------------------
hr "3. SnapKit -- real upstream source, one explicit vendoring exclusion"
SNAPKIT_POLICY=$HERE/snapkit-exclusions.json
SNAPKIT_FILES=$OUT/snapkit-files.txt
SNAPKIT_AUDIT_BEFORE=$OUT/snapkit-vendoring-before.json
SNAPKIT_AUDIT_AFTER=$OUT/snapkit-vendoring-after.json

# This is intentionally fatal rather than another census row. If the pin,
# source set, excluded file, or excluded file's bytes changed, the compiler's
# subject is no longer the approved SnapKit vendoring subject.
python3 -B "$HERE/snapkit_sources.py" "$SNAPKIT" "$SNAPKIT_POLICY" \
    "$SNAPKIT_FILES" "$SNAPKIT_AUDIT_BEFORE" \
    | tee "$OUT/logs/snapkit-vendoring-before.log"
rc=$?
[ $rc -eq 0 ] || { say "  REFUSED SnapKit vendoring policy (rc=$rc)"; exit 4; }

build_mod_list SnapKit snapkit "$SNAPKIT_FILES"
snapkit_rc=$?
if [ $snapkit_rc -eq 0 ] && [ -f "$OUT/modules/SnapKit.swiftmodule" ]; then
    SNAPKIT_BUILT=1
else
    SNAPKIT_BUILT=0
fi

# Recompute after swiftc returns. This closes the subject bracket: a dependency
# source mutation during compilation voids the row instead of leaving a green
# result attached to an unknown mixture of bytes.
python3 -B "$HERE/snapkit_sources.py" "$SNAPKIT" "$SNAPKIT_POLICY" \
    "$OUT/snapkit-files-after.txt" "$SNAPKIT_AUDIT_AFTER" \
    > "$OUT/logs/snapkit-vendoring-after.log"
rc=$?
[ $rc -eq 0 ] || { say "  REFUSED post-build SnapKit subject (rc=$rc)"; exit 4; }
if ! cmp -s "$SNAPKIT_FILES" "$OUT/snapkit-files-after.txt" || \
   ! cmp -s "$SNAPKIT_AUDIT_BEFORE" "$SNAPKIT_AUDIT_AFTER"; then
    say "  REFUSED: SnapKit subject changed while swiftc was running"
    exit 4
fi
say "  subject bracket: unchanged before/after swiftc"

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
#
# This is intentionally a SATURATION instrument, not an executable target
# manifest. It also sees extension-product sources and cannot see generated
# Xcode inputs. README.md records the exact measured difference; the runnable
# build uses a separate, fail-closed target inventory rather than this `find`.
hr "5. name-only modules, so an unbuildable target cannot hide the app's errors"
mkdir -p "$OUT/empty"
# SnapKit gets a name-only fallback only when the real source fails. When the
# real module exists, emitting another SnapKit.swiftmodule in a later -I path is
# needless ambiguity and could turn a path-order change into a false green.
name_only_targets=(UIHelpers DesignSystem Widget Licenses UIComponents Onboarding AppShortcuts)
if [ "$SNAPKIT_BUILT" -eq 0 ]; then
    name_only_targets+=(SnapKit)
    say "  SnapKit: real module absent; emitting an explicit name-only fallback"
else
    say "  SnapKit: using the real 36-source module; no name-only fallback"
fi
for t in "${name_only_targets[@]}"; do
    printf '// name-only module: satisfies `import %s`, defines nothing.\n' "$t" \
        > "$OUT/empty/$t.swift"
    swiftc -emit-module -emit-module-path "$OUT/empty/$t.swiftmodule" \
        -wmo -target "$TARGET" -module-name "$t" "$OUT/empty/$t.swift" \
        >> "$OUT/logs/empty.log" 2>&1
done
say "  emitted $(ls "$OUT/empty"/*.swiftmodule 2>/dev/null | wc -l | tr -d ' ') name-only modules"

hr "6. THE BROAD SATURATED CENSUS -- all non-test sources, one module, -wmo"
find "$APP" -name '*.swift' \
  | grep -v '/focus-ios-tests/' \
  | grep -v '/Tests/' \
  | grep -v '/ContentBlockerGen/' \
  | grep -v '/Package.swift$' \
  | grep -v 'get_supported_locales.swift' \
  > "$OUT/appfiles.txt"
say "  broad source files: $(wc -l < "$OUT/appfiles.txt" | tr -d ' ')"
files=()
while IFS= read -r l; do files+=("$l"); done < "$OUT/appfiles.txt"
swiftc -typecheck -wmo -target "$TARGET" -module-name Blockzilla \
    "${INC[@]}" -I "$OUT/modules" -I "$OUT/empty" "${files[@]}" \
    > "$OUT/logs/app.log" 2>&1
say "  primary diagnostics: $(python3 -B "$HERE/diagnostics.py" count "$OUT/logs/app.log")"

# --- 6. the census -----------------------------------------------------------
hr "7. CENSUS"
python3 -B "$HERE/classify.py" "$OUT" "$APP" | tee "$OUT/census.txt"
