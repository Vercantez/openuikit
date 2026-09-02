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
#   CHECK 0  every .tbd ON DISK is byte-identical to what this run would emit.
#            The one check that reads the artefact instead of re-deriving it --
#            see its own note. A .tbd that lags its dylib passes every other
#            check in this file, because they all recompute from the dylibs.
#   CHECK 1  every name in loader-exports.txt is really defined by
#            build/machorun. A loader change that drops or renames one is
#            caught here, not in a guest six weeks later.
#   CHECK 2  the list is neither short nor long: the set of symbols our dylibs
#            import and no dylib of ours exports must equal it exactly.
#   CHECK 3  every symbol imported by every committed Mach-O in tests/bin and
#            tests/objc44 is exported by one of the generated .tbd files.
#            This is the one that answers "is the stub complete?" with the
#            corpus rather than with an opinion.
#   CHECK 4  no two dylibs in darwin/usr/lib define the same symbol (below).
#   CHECK 5  every symbol the darwin root leaves to the loader's HOST FALLBACK
#            is accounted for by a decision -- the `_glibc_*` label, the loader
#            export list, src/host_deny.c, or darwin/host-bound-allowed.txt.
#            The only one of the five that is not about the .tbd surface at
#            all; it is here because it sweeps the same "every dylib present"
#            scope CHECK 4 does. Delegated to scripts/check_undefined.sh,
#            which also grades guest roots.
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

# THIS GATE RUNS ON LINUX ONLY, AND SAYING SO IS THE POINT (#95).
#
# Run on macOS it exits 1 with 28 `comm: not in sorted order` lines and CHECK 5
# output that reads like a genuine host-fallback regression -- because BSD comm
# rejects input GNU comm accepts. The darwin root is fine; the gate simply
# cannot run here. That is a FALSE RED, and it is the mirror of the false green
# in CHECK 3 that graded zero binaries under a UTF-8 locale (#74): a wrong
# verdict is worse than no verdict, in either colour. One measured cost of it --
# during #90's baseline this was nearly recorded as "gen_tbd is red before and
# after", which would have set two meaningless numbers against each other.
#
# Same refusal shape as scripts/objc44.sh, deliberately: one message up front
# naming the right invocation, rather than a wall of output that invites someone
# to re-record a baseline.
[ "$(uname -s)" = "Linux" ] || {
    echo "gen_tbd: this reads the LINUX darwin/ root, but \`uname -s\` says $(uname -s)." >&2
    echo "         BSD comm rejects input GNU comm accepts, so this would report a" >&2
    echo "         FALSE regression rather than a result. Run it in the test bed:" >&2
    echo "           docker run --rm -i --platform linux/arm64 -v \"$ROOT:/work\" -w /work \\" >&2
    echo "             \"\${MACHORUN_IMAGE:-machorun-testbed:24.04}\" bash -c 'bash scripts/gen_tbd.sh'" >&2
    exit 2; }

# Every sort and comm in this file has to agree on collation, and only two sites
# said so. A locale-dependent sort feeding a locale-dependent comm is exactly how
# #74's CHECK 3 came to grade zero binaries while printing a pass, so set it once
# here rather than per call site and leave nothing to remember.
export LC_ALL=C

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

# BOTH MODES EMIT, and only one of them installs. That is the whole of CHECK 0
# below: a generated artefact can only be graded by regenerating it and
# comparing, because every other check here RE-DERIVES the symbol set from the
# dylibs and is therefore blind to what is actually on disk.
mkdir -p "$TMP/out"
emit_tbd "/usr/lib/libSystem.B.dylib" "$TMP/sym.libSystem.B" "$TMP/out/libSystem.B.tbd"
emit_tbd "/usr/lib/libobjc.A.dylib"   "$TMP/sym.libobjc.A"   "$TMP/out/libobjc.A.tbd"
emit_tbd "/usr/lib/libc++.1.dylib"    "$TMP/sym.libc++.1"    "$TMP/out/libc++.1.tbd"
emit_tbd "/usr/lib/libc++abi.dylib"   "$TMP/sym.libc++abi"   "$TMP/out/libc++abi.tbd"
[ -f "$TMP/sym.libquartz" ] && \
    emit_tbd "/usr/lib/libquartz.dylib" "$TMP/sym.libquartz" "$TMP/out/libquartz.tbd"

if [ "$MODE" = generate ]; then
    mkdir -p "$OUT"
    for d in "${DYLIBS[@]}"; do cp "$TMP/out/$d.tbd" "$OUT/$d.tbd"; done
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
    # ------------- CHECK 0: the .tbd ON DISK is the one this script would write
    #
    # THE ARTEFACT THE LINKER READS IS THE ONE NOTHING WAS CHECKING. Every other
    # check in this file recomputes the symbol set from darwin/usr/lib/*.dylib
    # and grades THAT -- so a .tbd that lags its dylib passes all of them.
    # Reproduced by construction: deleting two symbol lines from
    # libSystem.B.tbd left `gen_tbd.sh --check` printing "all five checks
    # passed" and `check_stale.sh` returning 0.
    #
    # THAT IS NOT A COSMETIC LAG, and the failure mode is the expensive kind.
    # The LOADER resolves against the dylib and the LINKER against the .tbd, so
    # a short .tbd does not fail -- it MANUFACTURES PHANTOM MISSING SYMBOLS.
    # Measured downstream 2026-08-27: a consumer's stub count fell 245 -> 208
    # the moment a lagging .tbd was refreshed, and four functions had been
    # written to fill gaps that did not exist. Worse, those stubs then LINKED
    # AHEAD of libSystem and shadowed the real implementations -- one of them
    # replacing a correct _NSGetExecutablePath with a documented fiction, so
    # every CF log line named the loader instead of the guest.
    #
    # `cmp`, not a symbol-set comparison, and deliberately: the install name,
    # the targets, the tbd-version and the document-end marker are as load-
    # bearing as the symbol list (omit the `...` and LLVM rejects the whole
    # file as "unsupported file type"). Byte identity is the only property that
    # cannot be partly true.
    for d in "${DYLIBS[@]}"; do
        [ -f "$OUT/$d.tbd" ] || die "--check: $OUT/$d.tbd does not exist (run without --check)"
    done
    tbd_drift=0
    for d in "${DYLIBS[@]}"; do
        cmp -s "$TMP/out/$d.tbd" "$OUT/$d.tbd" && continue
        tbd_drift=1
        echo "!! $OUT/$d.tbd is NOT what this script would generate from" >&2
        echo "   $DYLIB/$d.dylib. The linker reads the .tbd and the loader reads" >&2
        echo "   the dylib, so this does not fail a link -- it invents missing" >&2
        echo "   symbols and hides real ones." >&2
        printf '   on disk: %6d symbol lines   would be: %6d\n' \
            "$(grep -c "^ *'" "$OUT/$d.tbd" || true)" \
            "$(grep -c "^ *'" "$TMP/out/$d.tbd" || true)" >&2
        grep -o "'[^']*'" "$OUT/$d.tbd"     | tr -d "'" | LC_ALL=C sort -u > "$TMP/have.$d"
        grep -o "'[^']*'" "$TMP/out/$d.tbd" | tr -d "'" | LC_ALL=C sort -u > "$TMP/want.$d"
        comm -13 "$TMP/have.$d" "$TMP/want.$d" | sed 's/^/     missing from the .tbd: /' | head -20 >&2
        comm -23 "$TMP/have.$d" "$TMP/want.$d" | sed 's/^/     .tbd advertises but the dylib does not define: /' | head -20 >&2
    done
    if [ "$tbd_drift" != 0 ]; then
        echo "   Regenerate: scripts/build.sh tbd   (and RE-STAGE any sysroot that copied it)" >&2
        exit 1
    fi
    # The three unsuffixed names ld64 actually looks for. A missing symlink is
    # a link failure with a confusing message rather than a wrong answer, but it
    # is generated here too, so it is graded here too.
    for l in libSystem:libSystem.B libobjc:libobjc.A libc++:libc++.1; do
        [ -L "$OUT/${l%%:*}.tbd" ] || die "--check: $OUT/${l%%:*}.tbd is not a symlink (run without --check)"
        [ "$(readlink "$OUT/${l%%:*}.tbd")" = "${l#*:}.tbd" ] || \
            die "--check: $OUT/${l%%:*}.tbd points at $(readlink "$OUT/${l%%:*}.tbd"), not ${l#*:}.tbd"
    done
    echo "   CHECK 0: every .tbd on disk is byte-identical to what this run would emit"
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
#
# ...AND THE FILTER BELOW WAS THE SECOND SCOPE BUG IN THESE SAME EIGHT LINES.
# It used to be `head -c 4 "$f" | grep -q .` as an is-this-a-binary test. Mach-O
# magic is cf fa ed fe, which is not a valid UTF-8 character, and under a UTF-8
# locale GNU grep's `.` matches a CHARACTER -- so the filter dropped EVERY
# BINARY IN THE CORPUS. Measured on an unchanged tree, same second:
#     $ bash scripts/gen_tbd.sh --check
#        corpus: 0 binaries import 0 distinct symbols; 0 unresolved by the stubs
#        all four checks passed
#     $ LC_ALL=C bash scripts/gen_tbd.sh --check
#        corpus: 103 binaries import 395 distinct symbols; 0 unresolved
# Not the grep: GNU grep 3.12 from Homebrew's gnubin gives 0 too. It is the
# locale, and en_US.UTF-8 is what everyone here actually has. Live since fc13df4
# (2026-08-26), i.e. this check has been INERT on every build for two days --
# and CHECK 3 is the one its own header calls "the one that answers 'is the stub
# complete?' with the corpus rather than with an opinion".
#
# So the filter now matches the Mach-O MAGIC, byte by byte, through `od`. That
# says what it means (this corpus is Mach-O fixtures, nothing else) and there is
# no character decoding anywhere in it to be locale-dependent.
CORPUS=(); CANDIDATES=(); DROPPED=""
while IFS= read -r f; do
    case "$f" in *.txt|*.md|*.sh|*.c|*.m) continue ;; esac
    CANDIDATES+=("$f")
    magic=$(head -c 4 "$f" | LC_ALL=C od -An -tx1 | tr -d ' \n')
    case "$magic" in
        cffaedfe|cefaedfe|feedfacf|feedface|cafebabe|bebafeca) CORPUS+=("$f") ;;
        *) DROPPED="$DROPPED$f\tmagic ${magic:-empty}\n" ;;
    esac
done < <(find "$ROOT/tests/bin" "$ROOT/tests/objc44" -type f -not -name '.*' | LC_ALL=C sort)

# THE VERDICT MUST CONSUME THE DENOMINATOR. The old code printed `corpus: 0`
# truthfully on the line above `all four checks passed` -- a count a human has
# to notice is not a check. Two independent refusals:
#
#   (a) an EMPTY corpus is never a pass. Whatever went wrong, this check did not
#       run, and saying so is the only honest output.
#   (b) every CANDIDATE must be a Mach-O. Measured today: 103 candidates, 103
#       Mach-O, 0 other -- the extension list above already removes everything
#       that is not a binary, so a dropped candidate means either a new kind of
#       fixture (add its extension) or a filter that has stopped working. Named,
#       with the magic that was actually read, because "0 binaries" was exactly
#       the diagnostic that was missing last time.
if [ "${#CORPUS[@]}" -eq 0 ]; then
    echo "!! CHECK 3 CANNOT RUN: the corpus is empty (${#CANDIDATES[@]} candidate file(s) under tests/)." >&2
    echo "   This check grades stub completeness AGAINST THE CORPUS; with no corpus it grades nothing." >&2
    echo "   Refusing rather than reporting 0 unresolved symbols out of 0." >&2
    exit 1
fi
if [ -n "$DROPPED" ]; then
    echo "!! CHECK 3 SCOPE: ${#CORPUS[@]} of ${#CANDIDATES[@]} candidate file(s) were classified as Mach-O." >&2
    echo "   These were dropped and would have been graded silently:" >&2
    printf '%b' "$DROPPED" | while IFS=$'\t' read -r df dm; do
        [ -n "$df" ] && printf '     %-56s %s\n' "${df#$ROOT/}" "$dm"
    done >&2
    echo "   If a non-binary fixture was added, exclude it by extension above." >&2
    exit 1
fi

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

# --------------- CHECK 5: what the darwin root leaves to the HOST fallback
#
# CHECKs 2 and 3 are both about the .tbd surface -- what our dylibs promise a
# linker. This one is about what the LOADER does when nothing promised
# anything: src/resolve.c answers an unresolved bind from an is_runtime image
# out of glibc BY NAME, with no translation, and nothing graded that. It is not
# a .tbd concern, but it belongs beside CHECK 4 for the reason CHECK 4 exists:
# both sweep EVERY dylib in the tree including the staged ones a hand-written
# DYLIBS list would never mention, and both are about a resolution decided by
# something other than the linker.
#
# Delegated rather than inlined, because the same check has to run against
# GUEST roots (~/swift-macho-linux/scratch/mrroot_fe and its siblings), which
# is where it found the eight names #73 is about. Two copies of one symbol
# checker would drift exactly as a .tbd drifts from its dylib.
echo "   CHECK 5: the host-fallback surface of darwin/"
# Status captured from the command, NOT from a pipeline: `cmd | sed` reports
# sed's exit status, and this file's `set -o pipefail` is one edit away from
# turning that into a check that cannot fail.
cu_out=$(bash "$ROOT/scripts/check_undefined.sh" --strict "$ROOT/darwin" 2>&1); cu_rc=$?
printf '%s\n' "$cu_out" | sed 's/^/   /'
if [ "$cu_rc" != 0 ]; then
    echo "!! re-run: scripts/check_undefined.sh --strict $ROOT/darwin" >&2
    exit 1
fi

echo "   all six checks passed"
