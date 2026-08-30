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
#   3. SnapKit            THE REAL SOURCE at Focus's workspace-lock revision,
#                         recompiled. Not reimplemented: recompile-from-source
#                         is the whole point of the project, and SnapKit is MIT
#                         and pure Swift over NSLayoutConstraint. One
#                         diagnostic-only source file is excluded by a pinned,
#                         hash-checked vendoring rule. The lock link, rule,
#                         source denominator, and subject digest are printed and
#                         recorded on every run.
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
SNAPKIT=${SNAPKIT:-$SML/scratch/xcodeplan-deps/SnapKit}
OUT=${1:-/tmp/focus-ios-census}
REQUESTED_TARGET=${TARGET:-}
UIKIT_SRC=${UIKIT_SRC:-$HOME/uikit}
FOCUS_EXPECTED_COMMIT=a2832521c1daa0c23419c73705ae043ed60c9791
FOCUS_EXPECTED_TREE=065d8e374c9caa3be2915165ba7cbbe4b1d61d7e
SNAPKIT_EXPECTED_COMMIT=e74fe2a978d1216c3602b129447c7301573cc2d8
SNAPKIT_EXPECTED_TREE=2100f3f3429a309151bc49021a0495ebde575b3f
CENSUS_SOURCE_MODE=${CENSUS_SOURCE_MODE:-broad}
EXPECTED_SUPPORT_COMMIT=${EXPECTED_SUPPORT_COMMIT:-}
EXPECTED_SUPPORT_TREE=${EXPECTED_SUPPORT_TREE:-}
EXPECTED_UIKIT_COMMIT=${EXPECTED_UIKIT_COMMIT:-}
EXPECTED_UIKIT_TREE=${EXPECTED_UIKIT_TREE:-}
BASELINE_PRIMARY=${BASELINE_PRIMARY:-}

case "$CENSUS_SOURCE_MODE" in
    broad|exact-main) ;;
    *) printf 'REFUSED: unknown CENSUS_SOURCE_MODE: %s\n' "$CENSUS_SOURCE_MODE" >&2; exit 2 ;;
esac

if [ "$CENSUS_SOURCE_MODE" = exact-main ]; then
    [ -z "$REQUESTED_TARGET" ] || \
        [ "$REQUESTED_TARGET" = arm64-apple-macos15.0 ] || {
            printf 'REFUSED: exact-main target must be arm64-apple-macos15.0, got %s\n' \
                "$REQUESTED_TARGET" >&2
            exit 2
        }
    TARGET=arm64-apple-macos15.0
else
    TARGET=${REQUESTED_TARGET:-arm64-apple-macos13.0}
fi

assert_clean_identity() {
    local repository=$1 expected_commit=$2 expected_tree=$3 label=$4
    local actual_commit actual_tree status
    actual_commit=$(git -C "$repository" rev-parse --verify HEAD^{commit}) || exit 2
    actual_tree=$(git -C "$repository" rev-parse --verify HEAD^{tree}) || exit 2
    status=$(git -C "$repository" status --porcelain=v1 --untracked-files=all) || exit 2
    [ "$actual_commit" = "$expected_commit" ] || {
        printf 'REFUSED: %s commit %s, expected %s\n' \
            "$label" "$actual_commit" "$expected_commit" >&2
        exit 2
    }
    [ "$actual_tree" = "$expected_tree" ] || {
        printf 'REFUSED: %s tree %s, expected %s\n' \
            "$label" "$actual_tree" "$expected_tree" >&2
        exit 2
    }
    [ -z "$status" ] || {
        printf 'REFUSED: %s checkout is dirty: %s\n' "$label" "$status" >&2
        exit 2
    }
}

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

# The port's normalized target-resource plan must supply Bundle.module
# accessors outside the application source.  The raw swiftc
# census has no build-plan step, so stage that one narrowly identified,
# compile-only generated input for each exact target whose pinned sources
# resolve SwiftPM's Bundle.module member.  This is build support, not an
# overlay: it defines no application type, traps if accidentally executed, and
# lives under OUT.
target_needs_bundle_accessor() {
    case "$1" in
        DesignSystem|Widget|Licenses|Onboarding) return 0 ;;
        *) return 1 ;;
    esac
}

write_bundle_accessor() {
    local target=$1
    local directory="$OUT/generated-build-support/$target"
    local accessor="$directory/resource_bundle_accessor.swift"
    mkdir -p "$directory"
    printf '%s\n' \
        '// Generated build support: normalized Bundle.module census accessor.' \
        'import Foundation' \
        'extension Foundation.Bundle {' \
        '    static var module: Bundle { fatalError("compile-only census accessor") }' \
        '}' > "$accessor"
    printf '%s\n' "$accessor"
}

# --- 0. pins, by COMMIT ------------------------------------------------------
hr "0. pins"
if [ "$CENSUS_SOURCE_MODE" = exact-main ]; then
    [ -n "$EXPECTED_SUPPORT_COMMIT" ] && [ -n "$EXPECTED_SUPPORT_TREE" ] \
        && [ -n "$EXPECTED_UIKIT_COMMIT" ] && [ -n "$EXPECTED_UIKIT_TREE" ] || {
            say "  REFUSED: exact-main requires expected support/UIKit commit and tree"
            exit 2
        }
    assert_clean_identity "$SML" "$EXPECTED_SUPPORT_COMMIT" "$EXPECTED_SUPPORT_TREE" support
    assert_clean_identity "$APP" "$FOCUS_EXPECTED_COMMIT" "$FOCUS_EXPECTED_TREE" Focus
    assert_clean_identity "$SNAPKIT" "$SNAPKIT_EXPECTED_COMMIT" \
        "$SNAPKIT_EXPECTED_TREE" SnapKit
    assert_clean_identity "$UIKIT_SRC" "$EXPECTED_UIKIT_COMMIT" "$EXPECTED_UIKIT_TREE" OpenUIKit
    BASELINE_PRIMARY_SHA_BEFORE=''
    if [ -n "$BASELINE_PRIMARY" ]; then
        case "$BASELINE_PRIMARY" in /*) ;; *) say '  REFUSED: baseline primary path must be absolute'; exit 2 ;; esac
        [ -f "$BASELINE_PRIMARY" ] && [ ! -L "$BASELINE_PRIMARY" ] || {
            say "  REFUSED: baseline primary input is not a regular non-symlink file"
            exit 2
        }
        BASELINE_PRIMARY_SHA_BEFORE=$(shasum -a 256 "$BASELINE_PRIMARY" | awk '{print $1}')
    fi
fi
python3 -B "$HERE/focus_subject.py" "$APP" "$FOCUS_EXPECTED_COMMIT" \
    "$OUT/focus-subject-before.json" || exit 4
say "  focus-ios  $(git -C "$APP" rev-parse HEAD 2>/dev/null)"
say "  SnapKit    $(git -C "$SNAPKIT" rev-parse HEAD 2>/dev/null)"
say "  OpenUIKit  $(git -C "$UIKIT_SRC" rev-parse HEAD 2>/dev/null)"

# --- 1. OpenUIKit, built fresh ----------------------------------------------
hr "1. OpenUIKit (fresh clone; ~/uikit is read-only and is never written)"
UIKIT_CLONE=$OUT/uikit
if [ ! -d "$UIKIT_CLONE" ]; then
    git clone -q --no-hardlinks "$UIKIT_SRC" "$UIKIT_CLONE" || { say "  clone failed"; exit 2; }
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
    local accessor
    while IFS= read -r -d '' f; do srcs+=("$f"); done \
        < <(find "$srcdir" -name '*.swift' -print0)
    if target_needs_bundle_accessor "$name"; then
        accessor=$(write_bundle_accessor "$name")
        srcs+=("$accessor")
        say "  $name generated build support: ${accessor#"$OUT"/}"
    fi
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
# workspace lock, source set/digests, excluded file, or excluded file's bytes
# changed, the compiler's subject is no longer the approved SnapKit vendoring
# subject.
python3 -B "$HERE/snapkit_sources.py" "$SNAPKIT" "$APP" "$SNAPKIT_POLICY" \
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
python3 -B "$HERE/snapkit_sources.py" "$SNAPKIT" "$APP" "$SNAPKIT_POLICY" \
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

if [ "$CENSUS_SOURCE_MODE" = exact-main ]; then
    hr "6. EXACT BLOCKZILLA TARGET CENSUS -- pinned 129 present sources, -wmo"
    EXACT_POLICY=$HERE/focus-main-sources.json
    EXACT_MANIFEST_BEFORE=$OUT/exact-main-sources-before.nul
    EXACT_AUDIT_BEFORE=$OUT/exact-main-subject-before.json
    EXACT_MANIFEST_AFTER=$OUT/exact-main-sources-after.nul
    EXACT_AUDIT_AFTER=$OUT/exact-main-subject-after.json
    python3 -B "$HERE/focus_main_sources.py" "$APP" "$EXACT_POLICY" \
        "$EXACT_MANIFEST_BEFORE" "$EXACT_AUDIT_BEFORE" || exit 4
    files=()
    while IFS= read -r -d '' path; do files+=("$path"); done < "$EXACT_MANIFEST_BEFORE"
    [ "${#files[@]}" -eq 129 ] || {
        say "  REFUSED: exact source manifest count ${#files[@]}, expected 129"
        exit 4
    }
    swiftc -typecheck -wmo -target "$TARGET" -module-name Blockzilla \
        "${INC[@]}" -I "$OUT/modules" -I "$OUT/empty" "${files[@]}" \
        > "$OUT/logs/exact-main.log" 2>&1
    exact_rc=$?
    python3 -B "$HERE/diagnostics.py" normalize \
        "$OUT/logs/exact-main.log" "$OUT/exact-main-primary.tsv" \
        --root "focus=$APP" --root "output=$OUT" \
        --root "uikit=$UIKIT_CLONE" --root "snapkit=$SNAPKIT" \
        --root "support=$SML" || exit 4
    exact_count=$(python3 -B "$HERE/diagnostics.py" count "$OUT/logs/exact-main.log")
    normalized_count=$(wc -l < "$OUT/exact-main-primary.tsv" | tr -d '[:space:]')
    [ "$exact_count" = "$normalized_count" ] || {
        say "  REFUSED: normalized diagnostic count $normalized_count, expected $exact_count"
        exit 4
    }
    say "  exact present sources: ${#files[@]} (plus 2 generated-missing, not synthesized)"
    say "  primary diagnostics: $exact_count (swiftc rc=$exact_rc)"
else
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
fi

# Re-attest every Focus Swift byte after all compiler processes return. This
# catches edited, untracked, ignored, assume-unchanged, and skip-worktree Swift
# inputs rather than trusting `git status`, and brackets the live subject just
# like the SnapKit vendoring gate above.
python3 -B "$HERE/focus_subject.py" "$APP" "$FOCUS_EXPECTED_COMMIT" \
    "$OUT/focus-subject-after.json" || exit 4
if ! cmp -s "$OUT/focus-subject-before.json" "$OUT/focus-subject-after.json"; then
    say "  REFUSED: Focus Swift source subject changed while swiftc was running"
    exit 4
fi
say "  Focus source bracket: unchanged before/after all census compilers"

if [ "$CENSUS_SOURCE_MODE" = exact-main ]; then
    python3 -B "$HERE/focus_main_sources.py" "$APP" "$EXACT_POLICY" \
        "$EXACT_MANIFEST_AFTER" "$EXACT_AUDIT_AFTER" || exit 4
    cmp -s "$EXACT_MANIFEST_BEFORE" "$EXACT_MANIFEST_AFTER" || {
        say "  REFUSED: exact target source manifest changed during census"
        exit 4
    }
    cmp -s "$EXACT_AUDIT_BEFORE" "$EXACT_AUDIT_AFTER" || {
        say "  REFUSED: exact target source audit changed during census"
        exit 4
    }
    assert_clean_identity "$SML" "$EXPECTED_SUPPORT_COMMIT" "$EXPECTED_SUPPORT_TREE" support
    assert_clean_identity "$APP" "$FOCUS_EXPECTED_COMMIT" "$FOCUS_EXPECTED_TREE" Focus
    assert_clean_identity "$SNAPKIT" "$SNAPKIT_EXPECTED_COMMIT" \
        "$SNAPKIT_EXPECTED_TREE" SnapKit
    assert_clean_identity "$UIKIT_SRC" "$EXPECTED_UIKIT_COMMIT" "$EXPECTED_UIKIT_TREE" OpenUIKit
    normalized_sha=$(shasum -a 256 "$OUT/exact-main-primary.tsv" | awk '{print $1}')
    raw_log_sha=$(shasum -a 256 "$OUT/logs/exact-main.log" | awk '{print $1}')
    delta_sha=''
    if [ -n "$BASELINE_PRIMARY" ]; then
        BASELINE_PRIMARY_SHA_AFTER=$(shasum -a 256 "$BASELINE_PRIMARY" | awk '{print $1}')
        [ "$BASELINE_PRIMARY_SHA_AFTER" = "$BASELINE_PRIMARY_SHA_BEFORE" ] || {
            say '  REFUSED: baseline normalized diagnostics changed during census'
            exit 4
        }
        python3 -B "$HERE/diagnostics.py" delta "$BASELINE_PRIMARY" \
            "$OUT/exact-main-primary.tsv" "$OUT/exact-main-delta.tsv" || exit 4
        delta_sha=$(shasum -a 256 "$OUT/exact-main-delta.tsv" | awk '{print $1}')
    fi
    {
        printf 'format\tfocus-exact-main-census-v1\n'
        printf 'support\t%s\t%s\n' "$EXPECTED_SUPPORT_COMMIT" "$EXPECTED_SUPPORT_TREE"
        printf 'focus\t%s\t%s\n' "$FOCUS_EXPECTED_COMMIT" "$FOCUS_EXPECTED_TREE"
        printf 'uikit\t%s\t%s\n' "$EXPECTED_UIKIT_COMMIT" "$EXPECTED_UIKIT_TREE"
        printf 'snapkit\t%s\t%s\n' "$SNAPKIT_EXPECTED_COMMIT" "$SNAPKIT_EXPECTED_TREE"
        printf 'sources\tpresent\t129\n'
        printf 'sources\tgenerated-missing\t2\n'
        printf 'target\t%s\n' "$TARGET"
        printf 'diagnostics\tprimary\t%s\n' "$exact_count"
        printf 'diagnostics\traw-log-sha256\t%s\n' "$raw_log_sha"
        printf 'diagnostics\tnormalized-sha256\t%s\n' "$normalized_sha"
        if [ -n "$BASELINE_PRIMARY" ]; then
            printf 'diagnostics\tbaseline-sha256\t%s\n' "$BASELINE_PRIMARY_SHA_BEFORE"
            printf 'diagnostics\tdelta-sha256\t%s\n' "$delta_sha"
        fi
        printf 'swiftc-exit\t%s\n' "$exact_rc"
    } > "$OUT/exact-main-result.tsv"
    hr "7. EXACT TARGET RESULT"
    cat "$OUT/exact-main-result.tsv"
    exit 0
fi

# --- 7. the census -----------------------------------------------------------
hr "7. CENSUS"
python3 -B "$HERE/classify.py" "$OUT" "$APP" | tee "$OUT/census.txt"
