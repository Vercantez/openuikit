#!/bin/bash
# gen_tbd.sh -- generate sdk/usr/lib/*.tbd from OUR OWN dylibs.
#
#   scripts/gen_tbd.sh          generate, then check
#   scripts/gen_tbd.sh --check  check only; write nothing
#
# The point of generating rather than transcribing: the exported surface is by
# construction exactly what darwin/usr/lib/*.dylib implements. Apple's
# libSystem.B.tbd is 337 KB of symbols we mostly do not have; ours is a few KB
# of symbols we certainly do.
#
# RUN THIS AFTER build_darwin.sh / build_objc4.sh, NEVER BEFORE. The dylibs are
# the source of truth and a stale .tbd is a lie the linker will believe: ld64
# will happily resolve a symbol the .tbd promises and nothing defines, and the
# failure then surfaces at run time, in a guest, as an undefined-symbol abort.
# sdk/usr/lib is gitignored for the same reason.
#
# ---------------------------------------------------------------------------
# WHY THIS IS NOT `nm | sed`
#
# libobjc.A.dylib has 138 undefined symbols. 116 are exported by our
# libSystem.B.dylib. The other 22 are defined by THE LOADER -- the Linux ELF
# PIE -- and by no dylib at all: the _dyld_* image-notify surface plus
# dyld_stub_binder. On Darwin those live in libdyld.dylib, which Apple's
# libSystem.B.tbd re-exports (39 such libraries). Here there is no
# libdyld.dylib, because the loader IS dyld.
#
# So libSystem.tbd is  nm(libSystem.B.dylib) UNION darwin/loader-exports.txt,
# and that second list is a static file, which means it can rot. Three checks
# below keep it honest; each is a hard failure.
#
#   CHECK 1  every name in loader-exports.txt is really defined by
#            build/machorun. A loader change that drops or renames one is
#            caught here, not in a guest six weeks later.
#   CHECK 2  the list is neither short nor long: the set of symbols our dylibs
#            import and no dylib of ours exports must equal it exactly.
#   CHECK 3  every symbol imported by every committed Mach-O in tests/bin and
#            tests/objc44 is exported by one of the generated .tbd files.
#            This is the one that answers "is the stub complete?" with the
#            corpus rather than with an opinion.
#
# ---------------------------------------------------------------------------
# THE ONE FORMAT TRAP, since the error message does not say it (survey §4.2):
# a tbd-v4 file MUST end with the YAML document-end marker `...`. Omit it and
# LLVM's TextAPI reader rejects the whole file as
#     could not load TAPI file ...: unsupported file type
# which sounds like a corrupt binary and costs an hour. Everything else in the
# format -- current-version, quoting, extra stanzas -- is optional.
set -uo pipefail

ROOT=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
DYLIB="$ROOT/darwin/usr/lib"
OUT="$ROOT/sdk/usr/lib"
LOADER="${MACHORUN_LOADER:-$ROOT/build/machorun}"
LOADER_EXPORTS="$ROOT/darwin/loader-exports.txt"

MODE=generate
case "${1:---}" in
    --check) MODE=check ;;
    --) ;;
    -h|--help) sed -n '2,10p' "$0"; exit 0 ;;
    *) echo "gen_tbd: unknown option $1" >&2; exit 64 ;;
esac

die() { echo "gen_tbd: $*" >&2; exit 1; }

NM="${NM:-}"
if [ -z "$NM" ]; then
    for c in llvm-nm-18 llvm-nm nm; do
        command -v "$c" >/dev/null 2>&1 && { NM="$c"; break; }
    done
fi
[ -n "$NM" ] || die "no nm found (llvm-nm-18, llvm-nm or nm)"

# otool, for reading LC_REEXPORT_DYLIB. Same shape as NM above, and the REFUSAL
# matters as much as the search: a tool that is absent must stop the script, not
# return nothing. `otool` does not exist in the test-bed container at all --
# `llvm-otool-18` does -- and a hardcoded `otool` here would silently find no
# re-exports and emit .tbd files that are quietly short, which is the bug this
# is being added to fix. Empty is the answer that most needs its instrument
# checked.
OTOOL="${OTOOL:-}"
if [ -z "$OTOOL" ]; then
    for c in llvm-otool-18 llvm-otool otool; do
        command -v "$c" >/dev/null 2>&1 && { OTOOL="$c"; break; }
    done
fi
[ -n "$OTOOL" ] || die "no otool found (llvm-otool-18, llvm-otool or otool)"

# nm interleaves `<file> (for architecture arm64):` banners when handed a fat
# Mach-O -- tests/bin/fat is one -- and `$NF` on such a line yields the
# literal token `arm64):`. Dropping banner and blank lines is what keeps the fat
# fixture from inventing two symbols that do not exist.
strip_banners() { grep -vE '^$|\(for architecture .*\):$|^[^ ]*:$'; }

# defined-external symbols of a Mach-O or ELF file, one per line
exports_of() { "$NM" --defined-only --extern-only --format=just-symbols "$1" 2>/dev/null \
                 | sed 's/[[:space:]]*$//' | strip_banners | sort -u; }
# The install names a dylib RE-EXPORTS. otool prints `name <path> (offset N)`
# on the line after the LC_REEXPORT_DYLIB command.
reexports_of() { "$OTOOL" -l "$1" 2>/dev/null \
                   | awk '/LC_REEXPORT_DYLIB/{f=1} f&&/^ *name /{print $2; f=0}'; }

# undefined symbols. --format=just-symbols does not filter, so parse the long form.
imports_of() { "$NM" -u "$1" 2>/dev/null | strip_banners | awk '{print $NF}' | sort -u; }

# ------------------------------------------------------------------ inputs
# libquartz is OPTIONAL and the other three are not, which is a deliberate
# asymmetry. libSystem/libobjc/libc++ are the Darwin runtime a guest is entitled
# to assume exists; libquartz is a framework we chose to host, and a tree that
# has never run scripts/build.sh quartz should still be able to regenerate its
# stubs. Absent, it is skipped with a line saying so -- never emitted empty,
# because an empty .tbd is a promise ld64 will believe (see this script's
# header) and the guest would then fail at run time instead of at link time.
DYLIBS=(libSystem.B libobjc.A libc++.1 libc++abi)
for d in "${DYLIBS[@]}"; do
    [ -f "$DYLIB/$d.dylib" ] || die "no $DYLIB/$d.dylib -- build it first (scripts/build.sh all)"
done
if [ -f "$DYLIB/libquartz.dylib" ]; then
    DYLIBS+=(libquartz)
else
    echo "   note: no $DYLIB/libquartz.dylib -- skipping libquartz.tbd (scripts/build.sh quartz)"
    rm -f "$OUT/libquartz.tbd"
fi
[ -x "$LOADER" ] || die "no loader at $LOADER -- scripts/build.sh loader"
[ -f "$LOADER_EXPORTS" ] || die "no $LOADER_EXPORTS"

TMP=$(mktemp -d); trap 'rm -rf "$TMP"' EXIT

for d in "${DYLIBS[@]}"; do
    exports_of "$DYLIB/$d.dylib" > "$TMP/exp.$d"
    imports_of "$DYLIB/$d.dylib" > "$TMP/imp.$d"
done
# Column 1 is the symbol; a `#internal` marker means "the loader defines it but
# the SDK does not advertise it" -- checked for existence, kept out of the .tbd.
grep -vE '^[[:space:]]*(#|$)' "$LOADER_EXPORTS" | awk '{print $1}' | sort -u > "$TMP/loader"
# symbol -> the ELF name that really defines it (see the =<elf-name> annotation)
grep -vE '^[[:space:]]*(#|$)' "$LOADER_EXPORTS" \
    | awk '{n=$1; sub(/^_/,"",n); for(i=2;i<=NF;i++) if($i ~ /^=/){n=substr($i,2)} print $1"\t"n}' \
    | sort -u > "$TMP/loader_elfname"
grep -vE '^[[:space:]]*(#|$)' "$LOADER_EXPORTS" | grep -v '#internal' | awk '{print $1}' | sort -u > "$TMP/loader_public"
exports_of "$LOADER" > "$TMP/loader_elf"

cat "$TMP"/exp.* | sort -u > "$TMP/all_exp"
# _glibc_* is the EXPLICIT boundary our own dylibs use: darwin/src/dsys.h
# declares glibc's puts as `_glibc_puts` (GLIBCSYM), and src/resolve.c turns
# that prefix into a dlsym against the host's libc. Those 127 names are not a
# .tbd concern in either direction and must never appear in one.
cat "$TMP"/imp.* | grep -v '^_glibc_' | sort -u > "$TMP/all_imp"

fail=0

# ------------------------------------------------- CHECK 1: the loader has them
# Mach-O prefixes C symbols with '_'; the loader is an ELF, so strip one.
# dyld_stub_binder is the exception -- it carries no underscore in either.
missing=""
while IFS=$'\t' read -r s elf; do
    grep -qx "$elf" "$TMP/loader_elf" && continue
    grep -qx "$s"   "$TMP/loader_elf" && continue
    missing="$missing $s(->$elf)"
done < "$TMP/loader_elfname"
if [ -n "$missing" ]; then
    echo "!! loader-exports.txt names symbol(s) the loader does not define:" >&2
    for s in $missing; do echo "     $s" >&2; done
    echo "   Either the loader dropped them, or darwin/loader-exports.txt is stale." >&2
    fail=1
fi

# -------------------------------------------- CHECK 2: the list is exactly right
comm -23 "$TMP/all_imp" "$TMP/all_exp" > "$TMP/need_from_loader"
if ! diff -q "$TMP/need_from_loader" "$TMP/loader" >/dev/null; then
    echo "!! darwin/loader-exports.txt does not match what our dylibs actually need:" >&2
    diff "$TMP/loader" "$TMP/need_from_loader" \
        | sed 's/^</     only in loader-exports.txt: /; s/^>/     needed but not listed: /' >&2
    echo "   Update darwin/loader-exports.txt, deliberately, and say why in its header." >&2
    fail=1
fi

# ------------------------- CHECK 4: no two dylibs define the same symbol
#
# A duplicate definition is not an error to the linker and not an error to the
# loader. It is a COIN TOSS resolved by load order, and it has cost this project
# twice: `swift_retain`/`swift_release` defined in libSystem beat the real
# libswiftCore (which is why `-lswiftCore` before `-lSystem` was once
# load-bearing), and syspatch.c's malloc_type shim beat machorun's own for a
# week. Found by machorun-isamask with an all-pairs sweep; the severity
# classification below is what turns "duplicate" into "act now" or "note it".
#
# THE DANGEROUS CLASS IS ZEROFILL-VERSUS-REAL. A symbol in (__DATA,__common) is
# a PLACEHOLDER -- "no contents in the file" -- put there to satisfy a link. If
# a consumer binds FLAT and the placeholder loads first, it wins, and the caller
# gets zeroed memory where an implementation should be. Two real definitions are
# a mess; a placeholder shadowing a real one is a jump through NULL waiting for
# a link order to change.
#
# IT SCANS EVERY DYLIB PRESENT, NOT JUST THE ONES WE EMIT STUBS FOR, and that is
# the whole point. The overlap that prompted this is between libc++abi.dylib and
# libswiftcompat.dylib -- and libswiftcompat is staged from ~/swiftcore-macho,
# so it is not in DYLIBS and never will be. A check scoped to DYLIBS would have
# reported "clean" about the four libraries it knew and said nothing about the
# fifth, which is exactly how check_stale missed libc++abi. The reassuring
# output and the correct output are indistinguishable when the scope is wrong.
#
# IT IS HARD, and it was deliberately not landed that way first. machorun-isamask
# scoped this check and did not add it, because at the time the one live overlap
# was in a tree this repository does not own, and failing everyone's build over
# someone else's bug is not a trade a script gets to make. That was right. The
# constraint disappeared when swiftcore-macho deleted the duplicates from
# libswiftcompat, so it goes in hard rather than as advice nobody reads.
#
# A STALE STAGED ARTIFACT CAN TRIP THIS, and the message below says so, because
# the first person to hit it will otherwise think a fixed bug is back.
# scripts/stage_swiftcore.sh re-copies libswiftcompat and libswiftCore from
# ~/swiftcore-macho; a copy predating their fix still carries the duplicates
# while every git-level check says the tree is current.
DUP_SOFT=0

# Every dylib under darwin/usr/lib, including the staged runtimes.
ALL_DYLIBS=$(find "$DYLIB" -name '*.dylib' 2>/dev/null | sort)
for f in $ALL_DYLIBS; do
    n=$(basename "$f" .dylib)
    [ -f "$TMP/dup.$n" ] || exports_of "$f" > "$TMP/dup.$n"
    # zerofill symbols: (__DATA,__common) and friends carry no bytes in the file
    "$NM" -m "$f" 2>/dev/null | strip_banners \
        | awk '/__common|__bss/ && /external/ {print $NF}' | sort -u > "$TMP/zf.$n"
done

dup_found=0
for a in $ALL_DYLIBS; do
    for b in $ALL_DYLIBS; do
        [ "$a" \< "$b" ] || continue
        na=$(basename "$a" .dylib); nb=$(basename "$b" .dylib)
        both=$(comm -12 "$TMP/dup.$na" "$TMP/dup.$nb")
        [ -n "$both" ] || continue
        dup_found=1
        echo "!! $na.dylib and $nb.dylib both define $(echo "$both" | wc -l | tr -d ' ') symbol(s):" >&2
        for sym in $both; do
            tag=""
            grep -qx "$sym" "$TMP/zf.$na" && tag="$tag  [$na is ZEROFILL -- a placeholder, not an implementation]"
            grep -qx "$sym" "$TMP/zf.$nb" && tag="$tag  [$nb is ZEROFILL -- a placeholder, not an implementation]"
            echo "     $sym$tag" >&2
        done
    done
done
if [ "$dup_found" = 1 ]; then
    echo "   Which one wins is decided by LOAD ORDER, so this passes or fails by luck." >&2
    echo "   The fix is DELETION, not correction: when a real library grows a real" >&2
    echo "   implementation, remove the duplicate from the shim rather than maintain two." >&2
    echo "   If a STAGED artifact is involved (libswiftcompat, libswiftCore), try" >&2
    echo "   scripts/stage_swiftcore.sh first -- a stale copy carries duplicates that" >&2
    echo "   the source no longer has, and every git-level check says you are current." >&2
    [ "$DUP_SOFT" = 1 ] && echo "   (reported, not failed -- see CHECK 4's exit condition)" >&2
    [ "$DUP_SOFT" = 1 ] || fail=1
fi

[ "$fail" = 0 ] || exit 1

# ------------------------------------------- re-exports, merged INLINE
#
# A .tbd must vend everything the dylib vends, and a dylib vends what it
# re-exports. Ours did not, and it was a real defect rather than a cosmetic one:
# libc++.1.dylib re-exports libc++abi.dylib exactly as on Darwin, but
# libc++.1.tbd listed only its own 105 symbols and none of libc++abi's 367.
# ___gxx_personality_v0 was among the missing, so anything built on Linux
# against this SDK could not bind it two-level and fell through to
# `-undefined dynamic_lookup` -- A FLAT BIND, decided by load order, which is
# the exact defect class CHECK 4 above exists to remove. Found by
# swiftcore-build while trying to relink libswiftCore against these stubs.
#
# INLINE, NOT A `reexported-libraries:` STANZA, because that is what Apple does
# and the linker's behaviour is what matters. Measured on the host SDK:
# MacOSX.sdk/usr/lib/libc++.tbd has NO reexported-libraries stanza and DOES list
# __gxx_personality_v0 in its own exports:. That is why `-lc++` on macOS yields
# a two-level bind naming libc++.
#
# Depth-limited for the same reason src/resolve.c's lookup_in is: a re-export
# cycle would otherwise not terminate, and four is deeper than any real chain.
reexport_closure() { # reexport_closure <dylib-path> <depth>
    local f="$1" d="${2:-0}" name base
    [ "$d" -lt 4 ] || return 0
    for name in $(reexports_of "$f"); do
        base="$DYLIB/$(basename "$name")"
        [ -f "$base" ] || {
            echo "   note: $(basename "$f") re-exports $name, which is not in $DYLIB;" >&2
            echo "         its symbols cannot be merged and guests will not see them." >&2
            continue
        }
        exports_of "$base"
        reexport_closure "$base" $((d + 1))
    done
}

# ------------------------------------------------------------------- emit
# libSystem carries the loader's exports because on Darwin libSystem.B.tbd
# re-exports libdyld.dylib and here the loader is dyld. Re-exporting cannot be
# expressed without a libdyld to point at, so they are merged in.
for d in "${DYLIBS[@]}"; do
    { cat "$TMP/exp.$d"; reexport_closure "$DYLIB/$d.dylib"; } | sort -u > "$TMP/sym.$d"
done
# libSystem additionally carries the loader's exports, because on Darwin
# libSystem.B.tbd re-exports libdyld.dylib and here the loader IS dyld. That one
# cannot be expressed as an LC_REEXPORT_DYLIB -- there is no libdyld to point at
# -- so it is merged from the list instead.
sort -u "$TMP/sym.libSystem.B" "$TMP/loader_public" > "$TMP/sym.libSystem.B.tmp"
mv "$TMP/sym.libSystem.B.tmp" "$TMP/sym.libSystem.B"

emit_tbd() { # emit_tbd <install-name> <symbol-file> <dest>
    {
        echo "--- !tapi-tbd"
        echo "tbd-version:     4"
        echo "targets:         [ arm64-macos ]"
        echo "install-name:    '$1'"
        echo "current-version: 1"
        echo "compatibility-version: 1"
        echo "exports:"
        echo "  - targets:   [ arm64-macos ]"
        echo "    symbols:   ["
        sed "s/^/                  '/; s/\$/',/" "$2"
        echo "               ]"
        # The document-end marker. NOT optional. See this script's header.
        echo "..."
    } > "$3"
}

if [ "$MODE" = generate ]; then
    mkdir -p "$OUT"
    emit_tbd "/usr/lib/libSystem.B.dylib" "$TMP/sym.libSystem.B" "$OUT/libSystem.B.tbd"
    emit_tbd "/usr/lib/libobjc.A.dylib"   "$TMP/sym.libobjc.A"   "$OUT/libobjc.A.tbd"
    emit_tbd "/usr/lib/libc++.1.dylib"    "$TMP/sym.libc++.1"    "$OUT/libc++.1.tbd"
    emit_tbd "/usr/lib/libc++abi.dylib"   "$TMP/sym.libc++abi"   "$OUT/libc++abi.tbd"
    [ -f "$TMP/sym.libquartz" ] && \
        emit_tbd "/usr/lib/libquartz.dylib" "$TMP/sym.libquartz" "$OUT/libquartz.tbd"
    # Apple ships libSystem.tbd and libobjc.tbd as symlinks; -lSystem looks for
    # the unsuffixed name. libquartz has no suffixed form, so no symlink.
    ln -sf libSystem.B.tbd "$OUT/libSystem.tbd"
    ln -sf libobjc.A.tbd   "$OUT/libobjc.tbd"
    ln -sf libc++.1.tbd    "$OUT/libc++.tbd"
    for d in "${DYLIBS[@]}"; do
        printf '   %-18s %5d symbols  %7d bytes\n' \
            "$d.tbd" "$(wc -l < "$TMP/sym.$d")" "$(wc -c < "$OUT/$d.tbd")"
    done
else
    for d in "${DYLIBS[@]}"; do
        [ -f "$OUT/$d.tbd" ] || die "--check: $OUT/$d.tbd does not exist (run without --check)"
    done
fi

# --------------------------------- CHECK 3: the corpus resolves against the stubs
# Every committed Mach-O binary was built by APPLE'S toolchain against APPLE'S
# SDK -- deliberately, see docs/SDK_SURVEY.md §6.3 -- so this is a real test of
# whether our stub covers the surface Apple's linker actually emitted.
# Every stub we just emitted -- driven off DYLIBS rather than a hand-written
# list, because a hand-written list is how libquartz's 507 exports got written
# to libquartz.tbd and then ignored two lines later, which made CHECK 3 report
# 34 phantom missing symbols on a tree where nothing was missing at all.
: > "$TMP/tbd_all"
for d in "${DYLIBS[@]}"; do cat "$TMP/sym.$d" >> "$TMP/tbd_all"; done
sort -u "$TMP/tbd_all" -o "$TMP/tbd_all"

# RECURSIVELY, and that is not tidiness. A `*` glob is a sweep over "the
# artifacts I happen to see", and tests/bin grew a subdirectory the moment a
# fixture needed two libraries with the SAME BASENAME in different directories
# (loader_path). The glob then found tests/bin/loader_path importing `_mid_open`
# and did NOT find loader_path_plugins/libloader_path_mid.dylib exporting it, so
# it reported a missing symbol about a set that excluded the answer -- which is
# the exact failure this check exists to catch, pointed at itself.
CORPUS=()
while IFS= read -r f; do
    case "$f" in *.txt|*.md|*.sh|*.c|*.m) continue ;; esac
    head -c 4 "$f" | grep -q . || continue
    CORPUS+=("$f")
done < <(find "$ROOT/tests/bin" "$ROOT/tests/objc44" -type f -not -name '.*' | sort)

: > "$TMP/corpus_imp"
for f in "${CORPUS[@]}"; do imports_of "$f" >> "$TMP/corpus_imp"; done
sort -u "$TMP/corpus_imp" -o "$TMP/corpus_imp"

# Guest-local dylibs in the corpus (libdylib_greet, lib041-multi-image, ...) are part
# of the test corpus, not of the SDK; their exports resolve the rest.
: > "$TMP/corpus_exp"
for f in "${CORPUS[@]}"; do exports_of "$f" >> "$TMP/corpus_exp"; done
sort -u "$TMP/corpus_exp" -o "$TMP/corpus_exp"

comm -23 "$TMP/corpus_imp" "$TMP/tbd_all" | comm -23 - "$TMP/corpus_exp" > "$TMP/corpus_missing"
n_corpus_imp=$(wc -l < "$TMP/corpus_imp")
n_missing=$(grep -c . "$TMP/corpus_missing" || true)

printf '   corpus: %d binaries import %d distinct symbols; %d unresolved by the stubs\n' \
    "${#CORPUS[@]}" "$n_corpus_imp" "$n_missing"
if [ "$n_missing" != 0 ]; then
    echo "!! symbols the corpus references and no .tbd exports:" >&2
    sed 's/^/     /' "$TMP/corpus_missing" >&2
    echo "   Implement them in darwin/src, or say in docs/UNIMPLEMENTED.md why not." >&2
    exit 1
fi

echo "   all four checks passed"
