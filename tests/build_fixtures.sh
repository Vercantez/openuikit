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
want 14_utility          && build 14_utility          "$CHAINED_TARGET" 14_utility          14_utility.c --

# ---------------------------------------------------------------- rung (r)
# Where the loader PUT things, rather than what it ran. libswiftCore has the
# 47-bit isa mask compiled into it, so an image at or above 2^47 makes the
# Swift standard library fault on a pointer it computed itself. macOS satisfies
# this for free -- its user address space is 47 bits, which is why Apple could
# bake the mask into a compiler at all -- so the two sides agree exactly when
# machorun's placement policy is doing its job. See src/map.c.
want 19_isa_mask         && build 19_isa_mask         "$CHAINED_TARGET" 19_isa_mask         19_isa_mask.c --

# Condition variables and mutex attributes, which back std::condition_variable
# and std::recursive_mutex. Graded like any other fixture, but note what it is
# really checking: that a cond WAITS (with a negative control that must time
# out) and that PTHREAD_MUTEX_RECURSIVE survives the trip, since Darwin and
# glibc swap the RECURSIVE and ERRORCHECK constants.
want 21_pthread_cond     && build 21_pthread_cond     "$CHAINED_TARGET" 21_pthread_cond     21_pthread_cond.c --

# The constants that cross the boundary. All 128 _SC_* names differ between
# Darwin and glibc, so sysconf cannot be forwarded. Grades PREDICATES rather
# than values, because the right answers legitimately differ per host.
want 22_sysconf          && build 22_sysconf          "$CHAINED_TARGET" 22_sysconf          22_sysconf.c --

# The password database. Darwin's struct passwd is 72 bytes and glibc's 48,
# agreeing for four fields and then diverging -- pw_dir, the field callers
# actually want, falls off the end of glibc's allocation. Predicates again,
# since usernames and home directories differ per host.
want 23_passwd           && build 23_passwd           "$CHAINED_TARGET" 23_passwd           23_passwd.c --

# ---------------------------------------------------------------- rung (w)
# Blocking signals: sigset_t is 4 bytes on Darwin and 128 on glibc, TEN of the
# 29 standard signal numbers differ, and SIG_BLOCK/UNBLOCK/SETMASK are off by
# one. All three need translating or the round trip names different signals --
# and the off-by-one is silent, since a forwarded SIG_BLOCK reads as
# SIG_UNBLOCK and returns success. darwin/src/posix.c translates; this grades it.
want 25_sigmask          && build 25_sigmask          "$CHAINED_TARGET" 25_sigmask          25_sigmask.c --

# ---------------------------------------------------------------- rung (v)
# std::sort over the five types libcxx_std.cpp instantiates by hand. It SORTS
# rather than links, because the symbol resolved perfectly while recursing
# forever -- a link test would have passed throughout.
if want 24_cxx_sort; then
    "$CC" -target "$CHAINED_TARGET" "${SDKFLAGS[@]}" -g0 -O1 -std=c++17 -o "$BIN/24_cxx_sort" \
        "$SRC/24_cxx_sort.cpp" -lc++
    echo "==> 24_cxx_sort"; built+=(24_cxx_sort)
fi

# ---------------------------------------------------------------- rung (y)
# Apple's TYPED allocator. Every request asks for a size and an alignment that
# differ, and neither is 16, because a wrong-argument bug in this family is
# invisible whenever the two coincide -- and 16 is both the usual alignment and
# a plausible size. Checked with malloc_size BEFORE anything is written: the
# broken version returned a valid pointer every time and the damage surfaced
# elsewhere, later, as somebody else's crash.
want 26_malloc_type      && build 26_malloc_type      "$CHAINED_TARGET" 26_malloc_type      26_malloc_type.c --

# ---------------------------------------------------------------- rung (z)
# Unwinding a real stack through Apple's compact __TEXT,__unwind_info. It WALKS
# rather than links: every unwind symbol resolved perfectly while the unwinder
# was a set of aborting stubs.
want 27_unwind           && build 27_unwind           "$CHAINED_TARGET" 27_unwind           27_unwind.c --

# --------------------------------------------------------------- rung (aa)
# poll(2). A regression guard rather than a discriminating test, and the
# fixture's own header says why: the two flags that differ cannot be reached
# from a fixture, because poll masks revents by the events requested and the
# one case that would show the mapping is a place the two KERNELS disagree.
# What it does hold is the eight agreeing flags, the counts, and the wrapper's
# heap path, byte-for-byte against macOS.
want 28_poll             && build 28_poll             "$CHAINED_TARGET" 28_poll             28_poll.c --

# --------------------------------------------------------------- rung (ab)
# sigaction(2): the first thing in the corpus that crosses the boundary in BOTH
# directions. Every other wrapper is finished when the call returns; this one
# installs a callback that glibc invokes later, with LINUX's signal number, into
# guest code that will compare it against Darwin's. SIGUSR1 is 30 here and 10
# there, and 10 on Darwin is SIGBUS.
want 29_sigaction        && build 29_sigaction        "$CHAINED_TARGET" 29_sigaction        29_sigaction.c --

# --------------------------------------------------------------- rung (ac)
# A C++ exception that really is thrown, really crosses frames, and really is
# caught by type. rung (z) proved the UNWINDER works; this proves the language
# runtime above it does. The case that matters is the handler that must NOT
# match -- a personality routine that said yes to everything would pass every
# other case here.
if want 30_throw; then
    "$CC" -target "$CHAINED_TARGET" "${SDKFLAGS[@]}" -g0 -O1 -std=c++17 -o "$BIN/30_throw" \
        "$SRC/30_throw.cpp" -lc++
    echo "==> 30_throw"; built+=(30_throw)
fi

# --------------------------------------------------------------- rung (ad)
# The libdispatch boundary. Two of its eleven symbols can be graded against a
# macOS oracle, and they are the two carrying the subtler mistake: fcntl, where
# the COMMAND agrees (F_GETFL 3, F_SETFL 4) and the O_* VALUE it carries does
# not, and madvise, where the four common advice values agree and the fifth --
# MADV_FREE, the only one libdispatch uses -- does not.
want 31_fcntl_madvise    && build 31_fcntl_madvise    "$CHAINED_TARGET" 31_fcntl_madvise    31_fcntl_madvise.c --

# --------------------------------------------------------------- rung (ae)
# The pthread_attr surface, where the SAFE-LOOKING direction is the broken one:
# Darwin's PTHREAD_CREATE_JOINABLE is 1 and glibc's 1 is DETACHED, so a forward
# hands back a thread the guest cannot join and only the DETACHED direction
# fails loudly. Same for SCHED_OTHER, whose 1 is glibc's SCHED_FIFO.
want 32_pthread_attr     && build 32_pthread_attr     "$CHAINED_TARGET" 32_pthread_attr     32_pthread_attr.c --

# --------------------------------------------------------------- rung (af)
# Loading a dylib at RUN TIME. The plugin deliberately carries an initialiser,
# a TLV, an exported function and a call into libSystem, because mapping is the
# easy part -- those four are what the rest of the dlopen sequence exists for,
# and a fixture that only checked `dlopen(...) != NULL` would pass with three
# of them broken. The plugin is NOT linked into the executable: it is found by
# path at run time, so it must not be on the link line.
if want 33_dlopen; then
    "$CC" -target "$CHAINED_TARGET" "${SDKFLAGS[@]}" -g0 -O1 -dynamiclib \
        -o "$BIN/lib33plug.dylib" "$SRC/33plug.c" -install_name "@rpath/lib33plug.dylib"
    "$CC" -target "$CHAINED_TARGET" "${SDKFLAGS[@]}" -g0 -O1 -o "$BIN/33_dlopen" \
        "$SRC/33_dlopen.c"
    echo "==> 33_dlopen"; built+=(33_dlopen)
fi

# --------------------------------------------------------------- rung (ag)
# The five sysctl MIBs CoreFoundation needs. sysctl is the only entry in the
# whole boundary with NOTHING to forward to -- glibc dropped sys/sysctl.h,
# Linux's sysctl(2) returns ENOSYS, and the symbol survives only as a compat
# stub -- so every MIB is a translation or a refusal. KERN_PROC_PID gates
# __CFInitialize itself.
want 34_sysctl           && build 34_sysctl           "$CHAINED_TARGET" 34_sysctl           34_sysctl.c --

# --------------------------------------------------------------- rung (ah)
# Three of CoreFoundation's initialisation walls. _NSGetExecutablePath is the
# sharp one: readlink("/proc/self/exe") returns the LOADER under machorun -- a
# real, existing, readable path that is not the guest -- and CF uses the answer
# to find the main bundle. pthread_atfork is a third kind of gap: same name,
# and glibc exports no dynamic symbol for it at all.
want 35_execpath         && build 35_execpath         "$CHAINED_TARGET" 35_execpath         35_execpath.c --

# ---------------------------------------------------------------- rung (s)
# Reading a directory. DIR is opaque so the pointer crosses fine, which is why
# this needs grading: struct dirent does NOT agree between Darwin and glibc
# (d_type 20 vs 18, d_name 21 vs 19, 1048 bytes vs 280), so a forwarded record
# yields truncated names and a wrong d_type with exit 0. darwin/src/posix.c
# translates; this proves it against macOS.
want 20_dirent           && build 20_dirent           "$CHAINED_TARGET" 20_dirent           20_dirent.c --

# ---------------------------------------------------------------- rung (n)
# The drawing rung. A plain C binary against /usr/lib/libquartz.dylib -- our
# Mach-O build of ~/quartz. NOT in tests/manifest.tsv and NOT graded by
# scripts/difftest.sh, because it is the one fixture whose result is a FILE
# rather than stdout and whose macOS run needs DYLD_LIBRARY_PATH (the install
# name is an absolute Darwin path that exists on neither host -- see
# scripts/build_quartz_macos.sh for why that is the right choice). Its
# differential lives in scripts/quartz_pixel.sh, which runs both sides and
# compares the PNG byte for byte.
#
# The link is against build/quartz-macos/libquartz.dylib purely so ld64 can see
# the exported symbols; what gets recorded in the binary is that dylib's
# INSTALL NAME, /usr/lib/libquartz.dylib, and nothing about where it sat.
if want 15_quartz; then
    echo "==> 15_quartz"
    QZLIB="$ROOT/build/quartz-macos/libquartz.dylib"
    [ -f "$QZLIB" ] || bash "$ROOT/scripts/build_quartz_macos.sh" >/dev/null
    [ -f "$QZLIB" ] || die_msg "15_quartz needs $QZLIB (scripts/build_quartz_macos.sh)"
    "$CC" -target "$CHAINED_TARGET" "${SDKFLAGS[@]}" -g0 -O1 \
        -I"$ROOT/vendor/quartz/include" \
        -o "$BIN/15_quartz" "$SRC/15_quartz.c" "$QZLIB"
    built+=(15_quartz)
fi

# --------------------------------------------------- rungs (o) and (p)
# Objective-C that DRAWS. Three images: libquartz, libobjc and libSystem, which
# is one more than anything below rung (n) loads. 15_quartz proved the
# rasteriser with no ObjC in it; 09_objc proved ObjC with no drawing in it;
# these two are the composition, and the composition is the milestone.
#
# Same PNG discipline and the same install-name trick as 15_quartz: not in
# tests/manifest.tsv, listed in tests/draw_manifest.tsv, graded by
# scripts/quartz_pixel.sh.
#
# 16 first, and it is deliberately trivial -- one root class, two ivars, one
# shape. It is the bisection point for 17: if 16 fails there is no point
# reading 17's pixel diff at all.
#
# -Wno-objc-root-class because both are Foundation-free by design, exactly like
# 09_objc: a class with its own `Class isa` and no NSObject anywhere. -lobjc
# resolves to /usr/lib/libobjc.A.dylib, which machorun's prefix map sends to
# darwin/usr/lib/libobjc.A.dylib -- our Mach-O build of Apple's objc4.
build_objc_draw() { # build_objc_draw <id> <source-file>
    local id="$1" src="$2"
    echo "==> $id"
    local qzlib="$ROOT/build/quartz-macos/libquartz.dylib"
    [ -f "$qzlib" ] || bash "$ROOT/scripts/build_quartz_macos.sh" >/dev/null
    [ -f "$qzlib" ] || die_msg "$id needs $qzlib (scripts/build_quartz_macos.sh)"
    "$CC" -target "$CHAINED_TARGET" "${SDKFLAGS[@]}" -g0 -O1 \
        -fobjc-arc-exceptions -Wno-objc-root-class \
        -I"$ROOT/vendor/quartz/include" \
        -o "$BIN/$id" "$SRC/$src" "$qzlib" -lobjc
    built+=("$id")
}
want 16_objc_quartz && build_objc_draw 16_objc_quartz 16_objc_quartz.m
want 17_objc_shapes && build_objc_draw 17_objc_shapes 17_objc_shapes.m

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

    # otool/file/nm echo the path they were given, so a recorded baseline
    # otherwise embeds whichever directory built it. That made every agent
    # working in a git worktree dirty all 34 meta files and collide with every
    # other agent, for no change in content. Rewrite the repository root to a
    # fixed marker so these files describe the BINARY and nothing else.
    { echo "### file";           file "$f"
      echo; echo "### mach header";   otool -h "$f"
      echo; echo "### dependencies";  otool -L "$f"
      echo; echo "### load commands"; printf '%s\n' "$LC"
      echo; echo "### undefined symbols";        nm -u  "$f" 2>/dev/null
      echo; echo "### defined external symbols"; nm -gU "$f" 2>/dev/null
    } | sed "s|$ROOT/|<machorun>/|g" > "$META/$n.otool.txt"

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
      # Same elision as the otool file above, and it was NOT redundant:
      # tests/meta/10_fat.summary.txt shipped with a worktree path in its
      # `dylibs:` line, because otool -L on a universal binary names the file
      # itself among its own dependencies.
    } | sed "s|$ROOT/|<machorun>/|g" > "$META/$n.summary.txt"
done
set -e

echo
echo "built: ${built[*]:-<none>}"
echo "next: harness/run_macos.sh --record"
