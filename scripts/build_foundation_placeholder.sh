#!/bin/bash
# build_foundation_placeholder.sh -- satisfy the two framework dependencies the
# staged iOS-SIMULATOR Swift overlays DECLARE and never USE, with dylibs that
# export nothing.
#
#   scripts/build_foundation_placeholder.sh [ROOT]     # default /work/root
#   REPLACE=1 scripts/build_foundation_placeholder.sh  # also displace a
#                                                      # non-placeholder file
#
# THE WALL (task #89). Four staged overlays are iOS-simulator builds --
# libswift_Builtin_float, libswiftSynchronization, libswift_RegexParser,
# libswift_StringProcessing -- and each carries an LC_LOAD_DYLIB on
#
#     /System/Library/Frameworks/Foundation.framework/Foundation
#     /System/Library/Frameworks/CoreFoundation.framework/CoreFoundation
#
# machorun refuses a guest whose dylib graph names a file that is not there, so
# ud_guest died before main. FoundationEssentials pulls those overlays in (40
# references from FoundationEssentials.o), so they cannot simply be dropped.
#
# WHY AN EMPTY FILE IS THE RIGHT ANSWER, AND WHY THE SCRIPT RE-DERIVES IT.
# ld64 keeps an LC_LOAD_DYLIB for a framework the driver named on the command
# line whether or not a single symbol came from it. Measured: across the 12
# staged overlays, ZERO undefined symbols are attributed to Foundation or to
# CoreFoundation. The dependency is real as a load command and empty as a fact.
#
# That measurement is the whole justification, so this script MAKES IT AGAIN on
# every run rather than quoting it (CHECK 1 below). A comment recording a
# measurement rots; a gate that re-runs it does not. And CHECK 0 proves the
# instrument can actually see a Foundation bind before CHECK 1's zero is
# allowed to mean anything -- an empty result from a blind instrument is this
# project's most-repeated false green.
#
# THE SHADOWING PROPERTY. This project is BUILDING Foundation, so a file at
# Foundation's canonical path is a shadowing hazard by construction. Exporting
# nothing removes the hazard instead of managing it: there is no symbol for a
# binder to prefer. These are two-level-namespace images, so a future real bind
# through either slot fails AT LOAD, naming the symbol -- loud, not plausible.
#
# WHAT THE CoreFoundation SLOT COSTS TODAY. In /work/root that path holds a
# byte-identical COPY of libCFTest.dylib (same md5, and its LC_ID_DYLIB still
# says /usr/lib/libCFTest.dylib). machorun keys loaded images by REQUESTED PATH,
# so it loads our CoreFoundation TWICE -- objc reports all 22 CF classes as
# duplicated, and CF's global state (runtime class table, allocators, the
# preferences cache) exists twice in one process. Replacing that copy with a
# placeholder leaves exactly one CoreFoundation. That is a REPLACEMENT of an
# existing file, so it needs REPLACE=1; it is not done silently.
set -euo pipefail

W=${W:-/work}
R=${R:-/repo}
ROOT=${1:-$W/root}
SDK=${SDK:-$W/sdk/MacOSX.sdk}
LLD=${LLD_BIN:-/usr/lib/llvm-18/bin}
NM=${NM:-llvm-nm-18}
OTOOL=${OTOOL:-llvm-otool-18}
TRIPLE=${TRIPLE:-arm64-apple-macos13.0}
REPLACE=${REPLACE:-0}

# Images CHECK 1 must sweep that do not live in the root. The guest EXECUTABLE
# is the obvious one -- it is the thing being loaded and it is not in the root,
# so a sweep of the root alone answers a question narrower than the one asked.
# Space-separated paths.
read -r -a EXTRA <<< "${EXTRA:-/work/bin/ud_guest}"

FINGERPRINT=_machorun_foundation_placeholder
SRC=$R/src/placeholder/FoundationPlaceholder.c

# leaf name : install path. The leaf is what `nm -m` prints in its "(from X)"
# attribution, so it is also the key CHECK 1 searches for.
SLOTS=(
  "Foundation:/System/Library/Frameworks/Foundation.framework/Foundation"
  "CoreFoundation:/System/Library/Frameworks/CoreFoundation.framework/CoreFoundation"
)

[ -d "$ROOT/darwin" ] || { echo "no guest root at $ROOT (expected $ROOT/darwin)" >&2; exit 2; }
mkdir -p "$W/obj"

echo "==> compiling FoundationPlaceholder.c"
clang -target $TRIPLE -isysroot "$SDK" -Os -c "$SRC" -o "$W/obj/FoundationPlaceholder.o"

# ---------------------------------------------------------------------------
# CHECK 0 -- POSITIVE CONTROL FOR THE INSTRUMENT.
#
# CHECK 1 concludes from an ABSENCE: no undefined symbol says "(from
# Foundation)". An absence is worth nothing until the pattern has been shown to
# fire on a case that is present. So: link a throwaway dylib AGAINST a
# Foundation-named placeholder, referencing its one export, and require that
# `nm -m` on the result really does print "(from Foundation)". If it does not,
# the instrument is blind and CHECK 1's zero means nothing.
echo "==> CHECK 0: can the instrument see a Foundation bind at all?"
CTL=$W/obj/_placeholder_control
mkdir -p "$CTL"
clang -target $TRIPLE -isysroot "$SDK" -fuse-ld=lld -B "$LLD" -nostdlib -dynamiclib \
  -install_name /System/Library/Frameworks/Foundation.framework/Foundation \
  "$W/obj/FoundationPlaceholder.o" -o "$CTL/Foundation"
cat > "$CTL/ctl.c" <<EOF
extern const char ${FINGERPRINT#_}[];
const char *_control_reads_the_placeholder(void) { return ${FINGERPRINT#_}; }
EOF
clang -target $TRIPLE -isysroot "$SDK" -Os -c "$CTL/ctl.c" -o "$CTL/ctl.o"
clang -target $TRIPLE -isysroot "$SDK" -fuse-ld=lld -B "$LLD" -nostdlib -dynamiclib \
  -install_name /usr/lib/_placeholder_control.dylib \
  "$CTL/ctl.o" "$CTL/Foundation" -o "$CTL/control.dylib"
if "$NM" -m "$CTL/control.dylib" 2>/dev/null | grep -q '(from Foundation)'; then
    echo "    control binds $FINGERPRINT and nm -m reports '(from Foundation)' -- the pattern fires"
else
    echo "REFUSING: the control dylib DOES bind a Foundation symbol and yet" >&2
    echo "  '$NM -m' never printed '(from Foundation)'. The instrument cannot see" >&2
    echo "  what CHECK 1 is about to report zero of. Fix the instrument first." >&2
    "$NM" -m "$CTL/control.dylib" 2>&1 | grep undefined | sed 's/^/    /' >&2
    exit 5
fi

# ---------------------------------------------------------------------------
# CHECK 1 -- NOTHING IN THE ROOT ACTUALLY BINDS THROUGH THESE SLOTS.
#
# Sweep every Mach-O in the root, not just the four overlays known to name
# them: the premise is about the WHOLE root, and a sweep restricted to the
# images you already suspect enumerates your hypothesis rather than the facts.
# The per-image totals are printed so the denominator is visible -- a sweep
# that found nothing because it looked at nothing prints the same "0" as a
# sweep that looked at everything.
#
# The Mach-O test is `od`, NOT `grep` on raw bytes. A grep for the four magic
# bytes silently matches nothing under a UTF-8 locale -- this repo has already
# shipped one gate that graded zero binaries that way and still printed a pass.
# The first version of this sweep hit it too: it saw 37 of 38 images and the
# skipped one was invisible, which is why the skipped list is PRINTED below
# rather than counted.
echo "==> CHECK 1: re-deriving the premise over the whole root"
total_files=0 total_images=0 total_undef=0 skipped=0
declare -A hits=()
for name_path in "${SLOTS[@]}"; do hits[${name_path%%:*}]=0; done

while IFS= read -r img; do
    total_files=$((total_files + 1))
    magic=$(head -c4 "$img" 2>/dev/null | od -An -tx1 | tr -d ' \n')
    if [ "$magic" != "cffaedfe" ]; then
        echo "    not-Mach-O (magic $magic), NOT SWEPT: $img"
        skipped=$((skipped + 1))
        continue
    fi
    total_images=$((total_images + 1))
    u=$("$NM" -m "$img" 2>/dev/null | grep -c '(undefined)' || true)
    total_undef=$((total_undef + u))
    for name_path in "${SLOTS[@]}"; do
        leaf=${name_path%%:*}
        n=$("$NM" -m "$img" 2>/dev/null | grep -c "(from $leaf)" || true)
        if [ "${n:-0}" -gt 0 ]; then
            hits[$leaf]=$(( ${hits[$leaf]} + n ))
            echo "    *** $(basename "$img") binds $n symbol(s) from $leaf"
            "$NM" -m "$img" 2>/dev/null | grep "(from $leaf)" | head -10 | sed 's/^/        /'
        fi
    done
done < <(find "$ROOT" -type f; for x in "${EXTRA[@]:-}"; do [ -n "$x" ] && [ -f "$x" ] && echo "$x"; done)

echo "    swept $total_images Mach-O images of $total_files files ($skipped skipped, listed above),"
echo "    $total_undef undefined symbols in total"
fail=0
for name_path in "${SLOTS[@]}"; do
    leaf=${name_path%%:*}
    printf '    binds attributed to %-16s %s\n' "$leaf:" "${hits[$leaf]}"
    [ "${hits[$leaf]}" -eq 0 ] || fail=1
done
if [ "$fail" -ne 0 ]; then
    echo "REFUSING: something in this root really does bind through a slot this" >&2
    echo "  script was about to replace with an empty dylib. The premise that" >&2
    echo "  justified the placeholder no longer holds -- read the names above." >&2
    exit 6
fi

# ---------------------------------------------------------------------------
# Install.
for name_path in "${SLOTS[@]}"; do
    leaf=${name_path%%:*}; install_name=${name_path#*:}
    dest=$ROOT/darwin$install_name

    if [ -e "$dest" ]; then
        if "$NM" -g "$dest" 2>/dev/null | grep -q "$FINGERPRINT"; then
            echo "==> $leaf: replacing the existing placeholder"
        elif [ "$REPLACE" = "1" ]; then
            echo "==> $leaf: DISPLACING a non-placeholder file (REPLACE=1)"
            echo "    was: $(wc -c < "$dest") bytes, install_name $("$OTOOL" -D "$dest" 2>/dev/null | tail -1)"
            echo "    exported ObjC classes: $("$NM" -g --defined-only "$dest" 2>/dev/null | grep -c '_OBJC_CLASS_\$_' || true)"
            # OUT of the root, not beside the placeholder. A guest root should
            # contain only what the guest loads; a 2 MB inert copy of
            # CoreFoundation left inside it is a future misreading waiting to
            # happen, and this project has been bitten by exactly that kind of
            # unowned file more than once.
            mkdir -p "$W/displaced"
            aside=$W/displaced/$leaf.$(date +%Y%m%dT%H%M%S)
            mv "$dest" "$aside"
            echo "    moved OUT of the root to $aside"
        else
            echo "REFUSING: $dest exists and is NOT the placeholder." >&2
            echo "  It may be the real $leaf. Re-run with REPLACE=1 if displacing" >&2
            echo "  it is what you mean; it will be moved aside, not deleted." >&2
            exit 2
        fi
    fi

    mkdir -p "$(dirname "$dest")"
    clang -target $TRIPLE -isysroot "$SDK" \
      -fuse-ld=lld -B "$LLD" -nostdlib -dynamiclib \
      -install_name "$install_name" \
      "$W/obj/FoundationPlaceholder.o" -o "$dest"

    # TOOTH: exactly one export, and it is the fingerprint. An empty dylib that
    # quietly grew an export is the entire hazard this design exists to avoid,
    # and only a COUNT can see it.
    exports=$("$NM" -g --defined-only --extern-only "$dest" 2>/dev/null | awk 'NF>=3{print $3}' | sort -u)
    n=$(printf '%s\n' "$exports" | grep -c . || true)
    if [ "$n" -ne 1 ] || [ "$exports" != "$FINGERPRINT" ]; then
        echo "REFUSING: $leaf placeholder exports $n symbol(s), expected exactly 1" >&2
        printf '%s\n' "$exports" | sed 's/^/    /' >&2
        exit 3
    fi

    # TOOTH: no dependencies of its own. A placeholder that dragged in libSystem
    # would make the guest's dylib graph depend on how this file was linked.
    deps=$("$OTOOL" -L "$dest" 2>/dev/null | tail -n +3 | grep -c . || true)
    if [ "${deps:-0}" -ne 0 ]; then
        echo "REFUSING: $leaf placeholder has $deps LC_LOAD_DYLIB entries; it must have none" >&2
        "$OTOOL" -L "$dest" 2>/dev/null | tail -n +3 | sed 's/^/    /' >&2
        exit 4
    fi

    echo "    $install_name"
    echo "      $(wc -c < "$dest") bytes, 1 export ($FINGERPRINT), 0 dependencies"
done

echo "== both slots satisfied by empty dylibs in $ROOT"
