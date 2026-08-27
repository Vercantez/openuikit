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

# nm interleaves `<file> (for architecture arm64):` banners when handed a fat
# Mach-O -- tests/bin/10_fat is one -- and `$NF` on such a line yields the
# literal token `arm64):`. Dropping banner and blank lines is what keeps the fat
# fixture from inventing two symbols that do not exist.
strip_banners() { grep -vE '^$|\(for architecture .*\):$|^[^ ]*:$'; }

# defined-external symbols of a Mach-O or ELF file, one per line
exports_of() { "$NM" --defined-only --extern-only --format=just-symbols "$1" 2>/dev/null \
                 | sed 's/[[:space:]]*$//' | strip_banners | sort -u; }
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

[ "$fail" = 0 ] || exit 1

# ------------------------------------------------------------------- emit
# libSystem carries the loader's exports because on Darwin libSystem.B.tbd
# re-exports libdyld.dylib and here the loader is dyld. Re-exporting cannot be
# expressed without a libdyld to point at, so they are merged in.
sort -u "$TMP/exp.libSystem.B" "$TMP/loader_public" > "$TMP/sym.libSystem.B"
cp "$TMP/exp.libobjc.A"  "$TMP/sym.libobjc.A"
cp "$TMP/exp.libc++.1"   "$TMP/sym.libc++.1"
cp "$TMP/exp.libc++abi"  "$TMP/sym.libc++abi"
[ -f "$TMP/exp.libquartz" ] && cp "$TMP/exp.libquartz" "$TMP/sym.libquartz"

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

CORPUS=()
for f in "$ROOT"/tests/bin/* "$ROOT"/tests/objc44/*; do
    [ -f "$f" ] || continue
    case "$f" in *.txt|*.md|*.sh|*.c|*.m) continue ;; esac
    head -c 4 "$f" | grep -q . || continue
    CORPUS+=("$f")
done

: > "$TMP/corpus_imp"
for f in "${CORPUS[@]}"; do imports_of "$f" >> "$TMP/corpus_imp"; done
sort -u "$TMP/corpus_imp" -o "$TMP/corpus_imp"

# Guest-local dylibs in the corpus (lib07greet, lib041-multi-image, ...) are part
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

echo "   all three checks passed"
