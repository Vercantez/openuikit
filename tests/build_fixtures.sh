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

# ------------------------------------------------ the id must be unique
#
# A FIXTURE'S IDENTITY IS ITS NAME, and the name is the only thing anyone
# chooses. There used to be a number too, and it was the source of four merge
# collisions in one day: two agents never build the same fixture, but they
# always race for the same next integer, and the loser only finds out at merge
# time because the id is claimed on a branch and visible only when it lands.
#
# The number is gone. `difftest.sh` renders the ladder position from row order,
# so nothing has to be claimed. What is left is the case that IS a real
# conflict -- two people building a fixture for the same thing -- and this
# refuses rather than letting four filenames (bin/, expected/, meta/, src/)
# silently overwrite each other's baselines.
dupes=$(awk -F'\t' '!/^#/ && NF {print $1}' "$ROOT/tests/manifest.tsv" \
        "$ROOT/tests/draw_manifest.tsv" | sort | uniq -d)
if [ -n "$dupes" ]; then
    echo "build_fixtures: duplicate fixture id(s) in the manifests:" >&2
    printf '     %s\n' $dupes >&2
    echo "   A fixture id is four filenames -- tests/{bin,expected,meta,src}/ --" >&2
    echo "   so a duplicate silently overwrites another fixture's baselines." >&2
    exit 2
fi
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

# ---------------------------------------------------------------- the `exit_unixthread` rung
# No libSystem calls at all: raw Darwin svc syscalls. Still dynamically
# linked so dyld can bind dyld_stub_binder.
if want exit_raw; then
    build exit_raw "$CLASSIC_TARGET" exit_raw exit_raw.s -- \
        -nostdlib -e _start -lSystem
fi

# Truly static: LC_UNIXTHREAD instead of LC_MAIN, no LC_LOAD_DYLINKER.
# macOS 11+ on arm64 REFUSES to exec this (SIGKILL), so there is no oracle
# output -- it is a parse-only fixture. Kept because LC_UNIXTHREAD is the
# entry form the loader will meet in old/embedded binaries.
if want exit_unixthread; then
    build exit_unixthread "$CLASSIC_TARGET" exit_unixthread exit_raw.s -- \
        -nostdlib -e _start -static
fi

# ---------------------------------------------------------------- the `main_ret_classic` rung
want main_ret         && build main_ret         "$CHAINED_TARGET" main_ret         main_ret.c --
want main_ret_classic && build main_ret_classic "$CLASSIC_TARGET" main_ret_classic main_ret.c --

# ---------------------------------------------------------------- the `printf_classic` rung
want printf           && build printf           "$CHAINED_TARGET" printf           printf.c --
want printf_classic  && build printf_classic  "$CLASSIC_TARGET" printf_classic  printf.c --

# ---------------------------------------------------------------- the `malloc` rung
want malloc           && build malloc           "$CHAINED_TARGET" malloc           malloc.c --

# ---------------------------------------------------------------- the `cxx_init` rung
# NOTE (verified 2026-08-25, ld-1230.1): the two targets do not merely change
# the fixup encoding, they change how initialisers are *stored*:
#   macos12+ -> __TEXT,__init_offsets      type 0x16 S_INIT_FUNC_OFFSETS
#               (uint32 offsets from the mach_header; read-only, no fixups)
#   macos11  -> __DATA_CONST,__mod_init_func type 0x09 S_MOD_INIT_FUNC_POINTERS
#               (absolute pointers, rebased at load)
# A loader that only knows __mod_init_func silently runs zero constructors on
# anything Xcode built this decade. Hence both variants are fixtures.
want mod_init          && build mod_init          "$CHAINED_TARGET" mod_init          mod_init.c --
want mod_init_classic && build mod_init_classic "$CLASSIC_TARGET" mod_init_classic mod_init.c --
if want cxx_init; then
    "$CC" -target "$CHAINED_TARGET" "${SDKFLAGS[@]}" -g0 -O1 -std=c++17 -o "$BIN/cxx_init" \
        "$SRC/cxx_init.cpp" -lc++
    echo "==> cxx_init"; built+=(cxx_init)
fi

# ---------------------------------------------------------------- the `tls` rung
want tls              && build tls              "$CHAINED_TARGET" tls              tls.c --

# ---------------------------------------------------------------- the `dylib_classic` rung
# Two images. The dylib's install name is @rpath-relative and the executable
# carries LC_RPATH=@loader_path, so both must sit in tests/bin together.
build_dylib_pair() { # <target> <libname> <exename>
    local target="$1" lib="$2" exe="$3"
    "$CC" -target "$target" "${SDKFLAGS[@]}" -g0 -O1 -dynamiclib -o "$BIN/$lib" \
        "$SRC/dylib_lib.c" \
        -install_name "@rpath/$lib" \
        -Wl,-U,_exe_callback
    # NOTE: -Wl,-undefined,dynamic_lookup would force the linker back to
    # classic LC_DYLD_INFO_ONLY even at macos12. A single -U keeps chained
    # fixups, so the chained/classic axis stays controlled by -target alone.
    "$CC" -target "$target" "${SDKFLAGS[@]}" -g0 -O1 -o "$BIN/$exe" \
        "$SRC/dylib_main.c" "$BIN/$lib" \
        -Wl,-rpath,@loader_path \
        -Wl,-export_dynamic
}
if want dylib; then
    echo "==> dylib"; build_dylib_pair "$CHAINED_TARGET" libdylib_greet.dylib dylib; built+=(dylib)
fi
if want dylib_classic; then
    echo "==> dylib_classic"; build_dylib_pair "$CLASSIC_TARGET" libdylib_greet_classic.dylib dylib_classic; built+=(dylib_classic)
fi

# ---------------------------------------------------------------- the `pthread` rung
want pthread          && build pthread          "$CHAINED_TARGET" pthread          pthread.c -- -pthread

# ---------------------------------------------------------------- the `objc` rung
if want objc; then
    "$CC" -target "$CHAINED_TARGET" "${SDKFLAGS[@]}" -g0 -O1 -fobjc-arc-exceptions -Wno-objc-root-class \
        -o "$BIN/objc" "$SRC/objc.m" -lobjc
    echo "==> objc"; built+=(objc)
fi

# ---------------------------------------------------------------- the `varargs_classic` rung
# The ABI rungs. Everything above proves the loader; these prove the Darwin
# userland underneath it -- the places where "forward it to glibc" is not a
# translation but a different program. See docs/ABI.md for the measurements.
want varargs          && build varargs          "$CHAINED_TARGET" varargs          varargs.c --
want varargs_classic && build varargs_classic "$CLASSIC_TARGET" varargs_classic varargs.c --
want mach             && build mach             "$CHAINED_TARGET" mach             mach.c --
want errno            && build errno            "$CHAINED_TARGET" errno            errno.c --
want utility          && build utility          "$CHAINED_TARGET" utility          utility.c --

# ---------------------------------------------------------------- the `isa_mask` rung
# Where the loader PUT things, rather than what it ran. libswiftCore has the
# 47-bit isa mask compiled into it, so an image at or above 2^47 makes the
# Swift standard library fault on a pointer it computed itself. macOS satisfies
# this for free -- its user address space is 47 bits, which is why Apple could
# bake the mask into a compiler at all -- so the two sides agree exactly when
# machorun's placement policy is doing its job. See src/map.c.
want isa_mask         && build isa_mask         "$CHAINED_TARGET" isa_mask         isa_mask.c --

# Condition variables and mutex attributes, which back std::condition_variable
# and std::recursive_mutex. Graded like any other fixture, but note what it is
# really checking: that a cond WAITS (with a negative control that must time
# out) and that PTHREAD_MUTEX_RECURSIVE survives the trip, since Darwin and
# glibc swap the RECURSIVE and ERRORCHECK constants.
want pthread_cond     && build pthread_cond     "$CHAINED_TARGET" pthread_cond     pthread_cond.c --

# The constants that cross the boundary. All 128 _SC_* names differ between
# Darwin and glibc, so sysconf cannot be forwarded. Grades PREDICATES rather
# than values, because the right answers legitimately differ per host.
want sysconf          && build sysconf          "$CHAINED_TARGET" sysconf          sysconf.c --

# The password database. Darwin's struct passwd is 72 bytes and glibc's 48,
# agreeing for four fields and then diverging -- pw_dir, the field callers
# actually want, falls off the end of glibc's allocation. Predicates again,
# since usernames and home directories differ per host.
want passwd           && build passwd           "$CHAINED_TARGET" passwd           passwd.c --

# ---------------------------------------------------------------- the `sigmask` rung
# Blocking signals: sigset_t is 4 bytes on Darwin and 128 on glibc, TEN of the
# 29 standard signal numbers differ, and SIG_BLOCK/UNBLOCK/SETMASK are off by
# one. All three need translating or the round trip names different signals --
# and the off-by-one is silent, since a forwarded SIG_BLOCK reads as
# SIG_UNBLOCK and returns success. darwin/src/posix.c translates; this grades it.
want sigmask          && build sigmask          "$CHAINED_TARGET" sigmask          sigmask.c --

# ---------------------------------------------------------------- the `cxx_sort` rung
# std::sort over the five types libcxx_std.cpp instantiates by hand. It SORTS
# rather than links, because the symbol resolved perfectly while recursing
# forever -- a link test would have passed throughout.
if want cxx_sort; then
    "$CC" -target "$CHAINED_TARGET" "${SDKFLAGS[@]}" -g0 -O1 -std=c++17 -o "$BIN/cxx_sort" \
        "$SRC/cxx_sort.cpp" -lc++
    echo "==> cxx_sort"; built+=(cxx_sort)
fi

# ---------------------------------------------------------------- the `malloc_type` rung
# Apple's TYPED allocator. Every request asks for a size and an alignment that
# differ, and neither is 16, because a wrong-argument bug in this family is
# invisible whenever the two coincide -- and 16 is both the usual alignment and
# a plausible size. Checked with malloc_size BEFORE anything is written: the
# broken version returned a valid pointer every time and the damage surfaced
# elsewhere, later, as somebody else's crash.
want malloc_type      && build malloc_type      "$CHAINED_TARGET" malloc_type      malloc_type.c --

# ---------------------------------------------------------------- the `unwind` rung
# Unwinding a real stack through Apple's compact __TEXT,__unwind_info. It WALKS
# rather than links: every unwind symbol resolved perfectly while the unwinder
# was a set of aborting stubs.
want unwind           && build unwind           "$CHAINED_TARGET" unwind           unwind.c --

# --------------------------------------------------------------- the `poll` rung
# poll(2). A regression guard rather than a discriminating test, and the
# fixture's own header says why: the two flags that differ cannot be reached
# from a fixture, because poll masks revents by the events requested and the
# one case that would show the mapping is a place the two KERNELS disagree.
# What it does hold is the eight agreeing flags, the counts, and the wrapper's
# heap path, byte-for-byte against macOS.
want poll             && build poll             "$CHAINED_TARGET" poll             poll.c --

# --------------------------------------------------------------- the `sigaction` rung
# sigaction(2): the first thing in the corpus that crosses the boundary in BOTH
# directions. Every other wrapper is finished when the call returns; this one
# installs a callback that glibc invokes later, with LINUX's signal number, into
# guest code that will compare it against Darwin's. SIGUSR1 is 30 here and 10
# there, and 10 on Darwin is SIGBUS.
want sigaction        && build sigaction        "$CHAINED_TARGET" sigaction        sigaction.c --

# --------------------------------------------------------------- the `throw` rung
# A C++ exception that really is thrown, really crosses frames, and really is
# caught by type. the `unwind` rung proved the UNWINDER works; this proves the language
# runtime above it does. The case that matters is the handler that must NOT
# match -- a personality routine that said yes to everything would pass every
# other case here.
if want throw; then
    "$CC" -target "$CHAINED_TARGET" "${SDKFLAGS[@]}" -g0 -O1 -std=c++17 -o "$BIN/throw" \
        "$SRC/throw.cpp" -lc++
    echo "==> throw"; built+=(throw)
fi

# --------------------------------------------------------------- the `fcntl_madvise` rung
# The libdispatch boundary. Two of its eleven symbols can be graded against a
# macOS oracle, and they are the two carrying the subtler mistake: fcntl, where
# the COMMAND agrees (F_GETFL 3, F_SETFL 4) and the O_* VALUE it carries does
# not, and madvise, where the four common advice values agree and the fifth --
# MADV_FREE, the only one libdispatch uses -- does not.
want fcntl_madvise    && build fcntl_madvise    "$CHAINED_TARGET" fcntl_madvise    fcntl_madvise.c --

# --------------------------------------------------------------- the `pthread_attr` rung
# The pthread_attr surface, where the SAFE-LOOKING direction is the broken one:
# Darwin's PTHREAD_CREATE_JOINABLE is 1 and glibc's 1 is DETACHED, so a forward
# hands back a thread the guest cannot join and only the DETACHED direction
# fails loudly. Same for SCHED_OTHER, whose 1 is glibc's SCHED_FIFO.
want pthread_attr     && build pthread_attr     "$CHAINED_TARGET" pthread_attr     pthread_attr.c --

# --------------------------------------------------------------- the `dlopen` rung
# Loading a dylib at RUN TIME. The plugin deliberately carries an initialiser,
# a TLV, an exported function and a call into libSystem, because mapping is the
# easy part -- those four are what the rest of the dlopen sequence exists for,
# and a fixture that only checked `dlopen(...) != NULL` would pass with three
# of them broken. The plugin is NOT linked into the executable: it is found by
# path at run time, so it must not be on the link line.
if want dlopen; then
    "$CC" -target "$CHAINED_TARGET" "${SDKFLAGS[@]}" -g0 -O1 -dynamiclib \
        -o "$BIN/libdlopen_plug.dylib" "$SRC/dlopen_plug.c" -install_name "@rpath/libdlopen_plug.dylib"
    "$CC" -target "$CHAINED_TARGET" "${SDKFLAGS[@]}" -g0 -O1 -o "$BIN/dlopen" \
        "$SRC/dlopen.c"
    echo "==> dlopen"; built+=(dlopen)
fi

# --------------------------------------------------------------- the `sysctl` rung
# The five sysctl MIBs CoreFoundation needs. sysctl is the only entry in the
# whole boundary with NOTHING to forward to -- glibc dropped sys/sysctl.h,
# Linux's sysctl(2) returns ENOSYS, and the symbol survives only as a compat
# stub -- so every MIB is a translation or a refusal. KERN_PROC_PID gates
# __CFInitialize itself.
want sysctl           && build sysctl           "$CHAINED_TARGET" sysctl           sysctl.c --
# --------------------------------------------------------------- the `execpath` rung
# "Which image and symbol is this address in", and the scoped dlsym handles.
# One gap, not three: dladdr, RTLD_NEXT/SELF/MAIN_ONLY and dlopen's
# @loader_path were all missing THE CALLING IMAGE. -export_dynamic so the
# executable's exported_fn is in its own trie, and the fixture's static
# local_fn is deliberately NOT, because dladdr must read LC_SYMTAB.
if want dladdr; then
    "$CC" -target "$CHAINED_TARGET" "${SDKFLAGS[@]}" -g0 -O1 -o "$BIN/dladdr" \
        "$SRC/dladdr.c" -Wl,-export_dynamic
    echo "==> dladdr"; built+=(dladdr)
fi

# --------------------------------------------------------------- the `execpath` rung
# Three of CoreFoundation's initialisation walls. _NSGetExecutablePath is the
# sharp one: readlink("/proc/self/exe") returns the LOADER under machorun -- a
# real, existing, readable path that is not the guest -- and CF uses the answer
# to find the main bundle. pthread_atfork is a third kind of gap: same name,
# and glibc exports no dynamic symbol for it at all.
want execpath         && build execpath         "$CHAINED_TARGET" execpath         execpath.c --

# The _dyld_* image table. Three gaps that look unrelated in a symbol census --
# _NSGetExecutablePath needing the MAIN image, dladdr needing the CALLING one,
# and these needing the WHOLE TABLE -- are one cause: libSystem has no view of
# MR.images, and here the loader IS dyld.
want dyld_images         && build dyld_images         "$CHAINED_TARGET" dyld_images         dyld_images.c --

# OSAtomic and OSSpinLock. No struct, no constant, no variadic argument, no
# differing width -- the entire risk is a RETURN VALUE off by one operation:
# Darwin's increment family returns the NEW value, so add_fetch and not
# fetch_add. Every assertion is written so a fetch_add implementation fails it.
want osatomic            && build osatomic            "$CHAINED_TARGET" osatomic            osatomic.c --

# Resource limits, writev and thread scope. Only two of seven RLIMIT_* numbers
# move, which is what makes them look safe -- and both land on LIVE Linux
# limits: Darwin's NOFILE is Linux's MEMLOCK, so a forward returns a byte
# figure as a file-descriptor count. struct rlimit and struct iovec both agree
# on the two systems, so this is a constants problem in a struct's clothes.
want rlimit              && build rlimit              "$CHAINED_TARGET" rlimit              rlimit.c --
# @loader_path in a dlopen, which means the CALLER's directory and not the main
# executable's. FOUR IMAGES IN TWO DIRECTORIES, because that is the only shape
# in which the two answers differ:
#
#   bin/loader_path                            the executable
#   bin/libloader_path_leaf.dylib              leaf_where() -> "bin"
#   bin/loader_path_plugins/..._mid.dylib      the caller, in the OTHER directory
#   bin/loader_path_plugins/..._leaf.dylib     leaf_where() -> "plugins"
#
# The two leaves share a BASENAME and differ only in which directory they are
# in -- that is deliberate, and it is what makes the wrong answer dangerous:
# resolving against the main executable returns a valid handle to the wrong
# library rather than failing. They are given distinct INSTALL NAMES so dyld
# registers them as two images; with one install name it would be free to hand
# back the first for both.
#
# LC_RPATH order on the executable is load-bearing. @loader_path (= bin) comes
# FIRST so that the executable's @rpath answer is bin's leaf and differs from
# the plugin's; @loader_path/loader_path_plugins comes second and is what finds
# the middle dylib at startup.
if want loader_path; then
    LP_DIR="$BIN/loader_path_plugins"
    mkdir -p "$LP_DIR"
    for where in bin plugins; do
        case "$where" in
            bin)     out="$BIN/libloader_path_leaf.dylib" ;;
            plugins) out="$LP_DIR/libloader_path_leaf.dylib" ;;
        esac
        "$CC" -target "$CHAINED_TARGET" "${SDKFLAGS[@]}" -g0 -O1 -dynamiclib -o "$out" \
            "$SRC/loader_path_leaf.c" -DLEAF_WHERE="\"$where\"" \
            -install_name "@rpath/libloader_path_leaf_$where.dylib"
    done
    "$CC" -target "$CHAINED_TARGET" "${SDKFLAGS[@]}" -g0 -O1 -dynamiclib \
        -o "$LP_DIR/libloader_path_mid.dylib" "$SRC/loader_path_mid.c" \
        -install_name "@rpath/libloader_path_mid.dylib" \
        -Wl,-rpath,@loader_path
    "$CC" -target "$CHAINED_TARGET" "${SDKFLAGS[@]}" -g0 -O1 -o "$BIN/loader_path" \
        "$SRC/loader_path.c" "$LP_DIR/libloader_path_mid.dylib" \
        -Wl,-rpath,@loader_path \
        -Wl,-rpath,@loader_path/loader_path_plugins
    echo "==> loader_path"; built+=(loader_path)
fi

# The environment. `environ` is a VARIABLE the guest reads and getenv is a
# CALL, and they had different backing: environ from the loader's envp, getenv
# from glibc's array. Identical contents at startup, diverging on the first
# write -- the worst lifetime for a defect, since the code that breaks is never
# the code that introduced it. The environ WALK is the half that would fail.
want environ             && build environ             "$CHAINED_TARGET" environ             environ.c --

# __exp10 and the BSD string forms. __exp10 is in the false-green catalogue as
# the function that compiled to an unconditional branch to ITSELF when written
# as pow(10.0, x) -- clang recognises the idiom and tail-calls the function
# being defined -- and produced ZERO undefined symbols, so the symbol table
# looked healthier than the correct version. Every line of this fixture
# produces a VALUE, because a symbol that exists and links is precisely the
# reassuring signal that hid it.
want exp10_strings       && build exp10_strings       "$CHAINED_TARGET" exp10_strings       exp10_strings.c --

# readdir_r, whose contract is easy to get backwards: it returns an ERRNO -- 0
# at end of directory included -- and signals EOF by storing NULL through
# `result`. It does not return -1 and does not set errno. The dirent
# translation it shares with readdir now lives in one helper, because two
# copies would be free to drift on d_reclen, which is what a caller walking a
# buffer steps by.
want dirent_r            && build dirent_r            "$CHAINED_TARGET" dirent_r            dirent_r.c --

# sscanf. Variadic, so it cannot be forwarded -- and unlike printf, every one
# of its variadic arguments is a POINTER IT WRITES THROUGH, making a forward a
# wild store per conversion. Bounded to the directives CF's census showed, with
# the unsupported case aborting by name rather than returning a short count,
# which would be indistinguishable from input that legitimately did not match.
want sscanf              && build sscanf              "$CHAINED_TARGET" sscanf              sscanf.c --

# vm_copy. Mach's in-task virtual copy, and every summary of it is wrong: no
# page-alignment requirement, memmove semantics on overlap (the checksum tells
# that apart from a forward copy), and an unmapped OR read-only OR PROT_NONE
# region gives KERN_INVALID_ADDRESS rather than KERN_PROTECTION_FAILURE. A
# bare memmove would SIGSEGV where Darwin returns an error, so the check is
# the implementation and this is what pins it.
want vm_copy             && build vm_copy             "$CHAINED_TARGET" vm_copy             vm_copy.c --

# ---------------------------------------------------------------- the `pthread_cond` rung
# Reading a directory. DIR is opaque so the pointer crosses fine, which is why
# this needs grading: struct dirent does NOT agree between Darwin and glibc
# (d_type 20 vs 18, d_name 21 vs 19, 1048 bytes vs 280), so a forwarded record
# yields truncated names and a wrong d_type with exit 0. darwin/src/posix.c
# translates; this proves it against macOS.
want dirent           && build dirent           "$CHAINED_TARGET" dirent           dirent.c --

# ---------------------------------------------------------------- the `quartz` rung
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
if want quartz; then
    echo "==> quartz"
    QZLIB="$ROOT/build/quartz-macos/libquartz.dylib"
    [ -f "$QZLIB" ] || bash "$ROOT/scripts/build_quartz_macos.sh" >/dev/null
    [ -f "$QZLIB" ] || die_msg "quartz needs $QZLIB (scripts/build_quartz_macos.sh)"
    "$CC" -target "$CHAINED_TARGET" "${SDKFLAGS[@]}" -g0 -O1 \
        -I"$ROOT/vendor/quartz/include" \
        -o "$BIN/quartz" "$SRC/quartz.c" "$QZLIB"
    built+=(quartz)
fi

# --------------------------------------------------- the `objc_quartz` rung and (p)
# Objective-C that DRAWS. Three images: libquartz, libobjc and libSystem, which
# is one more than anything below the `quartz` rung loads. quartz proved the
# rasteriser with no ObjC in it; objc proved ObjC with no drawing in it;
# these two are the composition, and the composition is the milestone.
#
# Same PNG discipline and the same install-name trick as quartz: not in
# tests/manifest.tsv, listed in tests/draw_manifest.tsv, graded by
# scripts/quartz_pixel.sh.
#
# 16 first, and it is deliberately trivial -- one root class, two ivars, one
# shape. It is the bisection point for 17: if 16 fails there is no point
# reading 17's pixel diff at all.
#
# -Wno-objc-root-class because both are Foundation-free by design, exactly like
# objc: a class with its own `Class isa` and no NSObject anywhere. -lobjc
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
want objc_quartz && build_objc_draw objc_quartz objc_quartz.m
want objc_shapes && build_objc_draw objc_shapes objc_shapes.m

# -------------------------------------------------- off-ladder: structure
# A universal binary. macOS picks the arm64 slice and behaves exactly like
# printf, so the recorded baseline is identical -- which means any
# difference under machorun is purely a FAT_MAGIC / slice-selection bug.
# The x86_64 slice is real (built, not padding) so the selector has to
# actually choose rather than take the first slice.
if want fat; then
    echo "==> fat"
    [ -f "$BIN/printf" ] || die_msg "fat is lipo'd from printf; build that first"
    "$CC" -target x86_64-apple-macos11 "${SDKFLAGS[@]}" -g0 -O1 \
        -o "$BIN/.fat.x86_64" "$SRC/printf.c"
    xcrun lipo -create "$BIN/.fat.x86_64" "$BIN/printf" -output "$BIN/fat"
    rm -f "$BIN/.fat.x86_64"
    built+=(fat)
fi

# --------------------------------------------------------------- metadata
# Record the structural facts the loader has to cope with. This is the
# machine-readable half of docs/FIXTURES.md.
echo
echo "recording metadata -> tests/meta/"
set +e   # otool/nm/grep returning "nothing found" is normal here
#
# FILES, RECURSIVELY, AND NAMED BY THEIR PATH UNDER tests/bin. The corpus grew
# a subdirectory when `loader_path` needed two libraries with the SAME BASENAME
# in different directories -- which is the only shape in which @loader_path's
# answer is distinguishable from the main executable's. A basename here would
# make those two collide on one meta file and record whichever came second,
# which is precisely the collision this directory layout exists to expose.
# Top-level fixtures contain no slash, so their meta filenames do not move.
while IFS= read -r f; do
    n="${f#"$BIN"/}"; n="${n//\//_}"
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
      # tests/meta/fat.summary.txt shipped with a worktree path in its
      # `dylibs:` line, because otool -L on a universal binary names the file
      # itself among its own dependencies.
    } | sed "s|$ROOT/|<machorun>/|g" > "$META/$n.summary.txt"
done < <(find "$BIN" -type f -not -name '.*' | sort)   # -not -name '.*': the glob
                                          # this replaced skipped dotfiles, and
                                          # tests/bin/.stress.stderr is one
set -e

echo
echo "built: ${built[*]:-<none>}"
echo "next: harness/run_macos.sh --record"
