#!/bin/bash
# Build the Mach-O fixture corpus with Apple's toolchain.
#
# DARWIN ONLY, ON PURPOSE. The fixtures are the reference bytes; they must be
# produced by the real Xcode linker, not by ld64.lld on Linux. The built
# binaries are committed to git, so this script normally does not need to run:
# it exists so the corpus is reproducible and auditable, not as part of the
# test loop.
#
# Usage: tests/build_fixtures.sh [fixture-id ...]
#        (no args = build everything)
#
# After building, run  harness/run_macos.sh --record  to refresh baselines.
set -euo pipefail

if [ "$(uname -s)" != "Darwin" ]; then
    echo "build_fixtures.sh: refusing to run on $(uname -s)." >&2
    echo "  Fixtures must be built by Apple's toolchain on macOS." >&2
    exit 64
fi

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SRC="$ROOT/tests/src"
BIN="$ROOT/tests/bin"
META="$ROOT/tests/meta"
mkdir -p "$BIN" "$META"

CC="$(xcrun -f clang)"
SDK="$(xcrun --sdk macosx --show-sdk-path)"
SDKFLAGS=(-isysroot "$SDK")

# The one lever that flips fixup format (verified 2026-08-25):
#   -target arm64-apple-macos11  -> LC_DYLD_INFO_ONLY   (classic opcodes)
#   -target arm64-apple-macos12+ -> LC_DYLD_CHAINED_FIXUPS + LC_DYLD_EXPORTS_TRIE
CHAINED_TARGET="arm64-apple-macos12"
CLASSIC_TARGET="arm64-apple-macos11"

WANT=("$@")
want() {
    [ ${#WANT[@]} -eq 0 ] && return 0
    local w
    for w in "${WANT[@]}"; do [ "$w" = "$1" ] && return 0; done
    return 1
}

built=()
die_msg() { echo "build_fixtures.sh: $*" >&2; exit 1; }

build() { # build <id> <target> <output-name> <src...> -- <extra link flags...>
    local id="$1"; shift
    local target="$1"; shift
    local out="$1"; shift
    local srcs=() extra=()
    while [ $# -gt 0 ] && [ "$1" != "--" ]; do srcs+=("$SRC/$1"); shift; done
    [ "${1:-}" = "--" ] && shift
    extra=("$@")
    echo "==> $id"
    # bash 3.2 (/bin/bash on macOS) + set -u: an empty array expansion is an
    # "unbound variable" error, hence the ${a[@]+...} guard.
    "$CC" -target "$target" "${SDKFLAGS[@]}" -g0 -O1 -o "$BIN/$out" \
        "${srcs[@]}" ${extra[@]+"${extra[@]}"}
    built+=("$id")
}

# ---------------------------------------------------------------- rung (a)
# No libSystem calls at all: raw Darwin svc syscalls. Still dynamically
# linked so dyld can bind dyld_stub_binder.
if want 01_exit_raw; then
    build 01_exit_raw "$CLASSIC_TARGET" 01_exit_raw 01_exit_raw.s -- \
        -nostdlib -e _start -lSystem
fi

# Truly static: LC_UNIXTHREAD instead of LC_MAIN, no LC_LOAD_DYLINKER.
# macOS 11+ on arm64 REFUSES to exec this (SIGKILL), so there is no oracle
# output -- it is a parse-only fixture. Kept because LC_UNIXTHREAD is the
# entry form the loader will meet in old/embedded binaries.
if want 01b_exit_unixthread; then
    build 01b_exit_unixthread "$CLASSIC_TARGET" 01b_exit_unixthread 01_exit_raw.s -- \
        -nostdlib -e _start -static
fi

# ---------------------------------------------------------------- rung (b)
want 02_main_ret         && build 02_main_ret         "$CHAINED_TARGET" 02_main_ret         02_main_ret.c --
want 02c_main_ret_classic && build 02c_main_ret_classic "$CLASSIC_TARGET" 02c_main_ret_classic 02_main_ret.c --

# ---------------------------------------------------------------- rung (c)
want 03_printf           && build 03_printf           "$CHAINED_TARGET" 03_printf           03_printf.c --
want 03c_printf_classic  && build 03c_printf_classic  "$CLASSIC_TARGET" 03c_printf_classic  03_printf.c --

# ---------------------------------------------------------------- rung (d)
want 04_malloc           && build 04_malloc           "$CHAINED_TARGET" 04_malloc           04_malloc.c --

# ---------------------------------------------------------------- rung (e)
# NOTE (verified 2026-08-25, ld-1230.1): the two targets do not merely change
# the fixup encoding, they change how initialisers are *stored*:
#   macos12+ -> __TEXT,__init_offsets      type 0x16 S_INIT_FUNC_OFFSETS
#               (uint32 offsets from the mach_header; read-only, no fixups)
#   macos11  -> __DATA_CONST,__mod_init_func type 0x09 S_MOD_INIT_FUNC_POINTERS
#               (absolute pointers, rebased at load)
# A loader that only knows __mod_init_func silently runs zero constructors on
# anything Xcode built this decade. Hence both variants are fixtures.
want 05_mod_init          && build 05_mod_init          "$CHAINED_TARGET" 05_mod_init          05_mod_init.c --
want 05c_mod_init_classic && build 05c_mod_init_classic "$CLASSIC_TARGET" 05c_mod_init_classic 05_mod_init.c --
if want 05b_cxx_init; then
    "$CC" -target "$CHAINED_TARGET" "${SDKFLAGS[@]}" -g0 -O1 -std=c++17 -o "$BIN/05b_cxx_init" \
        "$SRC/05b_cxx_init.cpp" -lc++
    echo "==> 05b_cxx_init"; built+=(05b_cxx_init)
fi

# ---------------------------------------------------------------- rung (f)
want 06_tls              && build 06_tls              "$CHAINED_TARGET" 06_tls              06_tls.c --

# ---------------------------------------------------------------- rung (g)
# Two images. The dylib's install name is @rpath-relative and the executable
# carries LC_RPATH=@loader_path, so both must sit in tests/bin together.
build_dylib_pair() { # <target> <libname> <exename>
    local target="$1" lib="$2" exe="$3"
    "$CC" -target "$target" "${SDKFLAGS[@]}" -g0 -O1 -dynamiclib -o "$BIN/$lib" \
        "$SRC/07_dylib_lib.c" \
        -install_name "@rpath/$lib" \
        -Wl,-U,_exe_callback
    # NOTE: -Wl,-undefined,dynamic_lookup would force the linker back to
    # classic LC_DYLD_INFO_ONLY even at macos12. A single -U keeps chained
    # fixups, so the chained/classic axis stays controlled by -target alone.
    "$CC" -target "$target" "${SDKFLAGS[@]}" -g0 -O1 -o "$BIN/$exe" \
        "$SRC/07_dylib_main.c" "$BIN/$lib" \
        -Wl,-rpath,@loader_path \
        -Wl,-export_dynamic
}
if want 07_dylib; then
    echo "==> 07_dylib"; build_dylib_pair "$CHAINED_TARGET" lib07greet.dylib 07_dylib; built+=(07_dylib)
fi
if want 07c_dylib_classic; then
    echo "==> 07c_dylib_classic"; build_dylib_pair "$CLASSIC_TARGET" lib07greet_classic.dylib 07c_dylib_classic; built+=(07c_dylib_classic)
fi

# ---------------------------------------------------------------- rung (h)
want 08_pthread          && build 08_pthread          "$CHAINED_TARGET" 08_pthread          08_pthread.c -- -pthread

# ---------------------------------------------------------------- rung (i)
if want 09_objc; then
    "$CC" -target "$CHAINED_TARGET" "${SDKFLAGS[@]}" -g0 -O1 -fobjc-arc-exceptions -Wno-objc-root-class \
        -o "$BIN/09_objc" "$SRC/09_objc.m" -lobjc
    echo "==> 09_objc"; built+=(09_objc)
fi

# ---------------------------------------------------------------- rung (j)
# The ABI rungs. Everything above proves the loader; these prove the Darwin
# userland underneath it -- the places where "forward it to glibc" is not a
# translation but a different program. See docs/ABI.md for the measurements.
want 11_varargs          && build 11_varargs          "$CHAINED_TARGET" 11_varargs          11_varargs.c --
want 11c_varargs_classic && build 11c_varargs_classic "$CLASSIC_TARGET" 11c_varargs_classic 11_varargs.c --
want 12_mach             && build 12_mach             "$CHAINED_TARGET" 12_mach             12_mach.c --
want 13_errno            && build 13_errno            "$CHAINED_TARGET" 13_errno            13_errno.c --

# -------------------------------------------------- off-ladder: structure
# A universal binary. macOS picks the arm64 slice and behaves exactly like
# 03_printf, so the recorded baseline is identical -- which means any
# difference under machorun is purely a FAT_MAGIC / slice-selection bug.
# The x86_64 slice is real (built, not padding) so the selector has to
# actually choose rather than take the first slice.
if want 10_fat; then
    echo "==> 10_fat"
    [ -f "$BIN/03_printf" ] || die_msg "10_fat is lipo'd from 03_printf; build that first"
    "$CC" -target x86_64-apple-macos11 "${SDKFLAGS[@]}" -g0 -O1 \
        -o "$BIN/.10_fat.x86_64" "$SRC/03_printf.c"
    xcrun lipo -create "$BIN/.10_fat.x86_64" "$BIN/03_printf" -output "$BIN/10_fat"
    rm -f "$BIN/.10_fat.x86_64"
    built+=(10_fat)
fi

# --------------------------------------------------------------- metadata
# Record the structural facts the loader has to cope with. This is the
# machine-readable half of docs/FIXTURES.md.
echo
echo "recording metadata -> tests/meta/"
set +e   # otool/nm/grep returning "nothing found" is normal here
for f in "$BIN"/*; do
    n="$(basename "$f")"
    LC="$(otool -l "$f")"

    { echo "### file";           file "$f"
      echo; echo "### mach header";   otool -h "$f"
      echo; echo "### dependencies";  otool -L "$f"
      echo; echo "### load commands"; printf '%s\n' "$LC"
      echo; echo "### undefined symbols";        nm -u  "$f" 2>/dev/null
      echo; echo "### defined external symbols"; nm -gU "$f" 2>/dev/null
    } > "$META/$n.otool.txt"

    # Every section, with its segment and its S_* type nibble. The section
    # TYPE (flags & 0xff) is what tells the loader that a __DATA section is
    # really a list of initialiser pointers or a TLS template:
    #   0x09 S_MOD_INIT_FUNC_POINTERS   0x0a S_MOD_TERM_FUNC_POINTERS
    #   0x06 S_NON_LAZY_SYMBOL_POINTERS 0x07 S_LAZY_SYMBOL_POINTERS
    #   0x08 S_SYMBOL_STUBS
    #   0x11 S_THREAD_LOCAL_REGULAR     0x12 S_THREAD_LOCAL_ZEROFILL
    #   0x13 S_THREAD_LOCAL_VARIABLES   0x14 S_THREAD_LOCAL_VARIABLE_POINTERS
    sections="$(printf '%s\n' "$LC" | awk '
        /^ *sectname /{sn=$2}
        /^ *segname /{sg=$2}
        /^ *flags 0x/{if(sn!=""){printf "%s,%s,%s\n", sg, sn, $2; sn=""}}')"

    archs="$(lipo -archs "$f" 2>/dev/null)"
    { echo "binary: $n"
      echo "architectures: ${archs:-arm64}"
      case "$archs" in
        *\ *) echo "NOTE: universal binary -- otool merges all slices, so the"
              echo "      lists below are the union across architectures." ;;
      esac
      printf 'filetype: '
      otool -hv "$f" | awk 'NR==4{print $5}'
      printf 'header-flags: '
      otool -hv "$f" | awk 'NR==4{for(i=8;i<=NF;i++)printf "%s%s",$i,(i<NF?" ":"\n")}'
      printf 'load-commands: '
      printf '%s\n' "$LC" | awk '/^ *cmd LC_/{print $2}' | sort -u | paste -sd, -
      printf 'fixups: '
      if   printf '%s\n' "$LC" | grep -q LC_DYLD_CHAINED_FIXUPS; then echo "chained (LC_DYLD_CHAINED_FIXUPS + LC_DYLD_EXPORTS_TRIE)"
      elif printf '%s\n' "$LC" | grep -q LC_DYLD_INFO_ONLY;      then echo "classic (LC_DYLD_INFO_ONLY opcode streams)"
      else echo "none"; fi
      printf 'entry: '
      if   printf '%s\n' "$LC" | grep -q LC_MAIN;       then echo LC_MAIN
      elif printf '%s\n' "$LC" | grep -q LC_UNIXTHREAD; then echo LC_UNIXTHREAD
      else echo "n/a (dylib)"; fi
      printf 'dylibs: '
      otool -L "$f" | tail -n +2 | awk '{print $1}' | paste -sd, -
      printf 'rpaths: '
      printf '%s\n' "$LC" | awk '/^ *path .* \(offset/{print $2}' | paste -sd, -
      echo 'loader-relevant sections (segment,section,flags):'
      printf '%s\n' "$sections" \
        | grep -E '__init_offsets|__mod_init_func|__mod_term_func|__thread_vars|__thread_data|__thread_bss|__objc_|__got|__la_symbol_ptr|__nl_symbol_ptr|__stubs|__auth' \
        | sed 's/^/  /'
      printf 'undefined-symbol-count: '
      nm -u "$f" 2>/dev/null | grep -c .
    } > "$META/$n.summary.txt"
done
set -e

echo
echo "built: ${built[*]:-<none>}"
echo "next: harness/run_macos.sh --record"
