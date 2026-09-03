#!/usr/bin/env bash
# Build tests/src as x86_64-apple-macos Mach-O on Linux.
#
# Output: tests/bin-x86_64/  (never overwrites tests/bin/)
# Apple's toolchain is NOT available here, so these are not the committed
# reference bytes; they exist so this x86_64 VM can run the difftest loop
# itself. A fixture that cannot be produced REFUSES with a canonical marker
# and is never silently skipped.
#
# Usage: scripts/build_fixtures_linux_x86_64.sh [fixture-id ...]
set -euo pipefail

HERE="$(cd "$(dirname "$0")" && pwd)"
# shellcheck source=guest_arch.inc
source "$HERE/guest_arch.inc"
ROOT="$(cd "$HERE/.." && pwd)"
SRC="$ROOT/tests/src"
BIN="$ROOT/tests/bin-x86_64"
OBJ="$BIN/.obj"
SDK="$ROOT/sdk"
META="$BIN/.refuse"
ARM64_BIN="$ROOT/tests/bin"

MACHO_CLANG="${DARWIN_CLANG:-clang-18}"
MACHO_LD="${LD64:-ld64.lld-18}"
LIPO="${LIPO:-llvm-lipo-18}"
INSTALL_NAME_TOOL="${INSTALL_NAME_TOOL:-llvm-install-name-tool-18}"

CHAINED_TARGET="x86_64-apple-macos12"
CLASSIC_TARGET="x86_64-apple-macos11"

if [[ "$(uname -m)" != "x86_64" ]]; then
    echo "CANNOT_BUILD_X86_FIXTURES: host is $(uname -m), need x86_64" >&2
    exit 1
fi
if [[ "$(uname -s)" != "Linux" ]]; then
    echo "CANNOT_BUILD_X86_FIXTURES: this builder is the Linux stand-in; on Darwin use tests/build_fixtures.sh" >&2
    exit 1
fi
command -v "$MACHO_CLANG" >/dev/null || { echo "CANNOT_BUILD_X86_FIXTURES: no $MACHO_CLANG" >&2; exit 1; }
command -v "$MACHO_LD" >/dev/null || { echo "CANNOT_BUILD_X86_FIXTURES: no $MACHO_LD" >&2; exit 1; }
if [[ ! -f "$SDK/usr/lib/libSystem.tbd" && ! -f "$SDK/usr/lib/libSystem.B.tbd" ]]; then
    echo "CANNOT_BUILD_X86_FIXTURES: missing sdk/usr/lib/libSystem*.tbd — run scripts/build.sh all first" >&2
    exit 1
fi

rm -rf "$BIN"
mkdir -p "$BIN" "$OBJ" "$META"

WANT=("$@")
want() {
    [ ${#WANT[@]} -eq 0 ] && return 0
    local w
    for w in "${WANT[@]}"; do [ "$w" = "$1" ] && return 0; done
    return 1
}

BUILT=0
REFUSED=0
built_ids=()

refuse() {
    local marker="$1" id="$2" why="$3"
    printf '%s\t%s\t%s\n' "$marker" "$id" "$why" | tee -a "$META/log.tsv" >&2
    echo "$marker: $id — $why" > "$META/$id"
    REFUSED=$((REFUSED + 1))
}

platform_ver() {
    case "$1" in
        *macos12*) echo 12.0.0 ;;
        *macos11*) echo 11.0.0 ;;
        *)         echo 11.0.0 ;;
    esac
}

# clang-18's Darwin driver on Linux does not synthesise -arch / -platform_version
# for ld64.lld (docs/SDK_SURVEY.md §4.4). Compile, then link as a second step.
compile_one() {
    local src="$1" obj="$2" target="$3"
    shift 3
    "$MACHO_CLANG" -c -target "$target" -isysroot "$SDK" -g0 -O1 "$@" -o "$obj" "$src"
}

translate_ldflag() {
    # Echo ld64 flags corresponding to one Darwin-clang extra argument.
    # -Wl* MUST precede -W*: otherwise -Wl,-U,_foo is swallowed as compile-only.
    local a="$1"
    case "$a" in
        -pthread) ;;
        -Wl,-export_dynamic) echo "-export_dynamic" ;;
        -Wl,-undefined,dynamic_lookup) echo "-undefined"; echo "dynamic_lookup" ;;
        -Wl,-U,*) echo "-U"; echo "${a#-Wl,-U,}" ;;
        -Wl,-rpath,*) echo "-rpath"; echo "${a#-Wl,-rpath,}" ;;
        -Wl,*)
            local rest="${a#-Wl,}"
            IFS=',' read -r -a parts <<<"$rest"
            printf '%s\n' "${parts[@]}"
            ;;
        -std=*|-f*|-W*|-D*|-I*|-g*|-O*|-m*) ;;  # compile-only
        -lc++|-lSystem|-lm|-lc) echo "$a" ;;
        -l*) echo "$a" ;;
        *) echo "$a" ;;
    esac
}

link_exe() {
    local out="$1" target="$2"
    shift 2
    local pv; pv=$(platform_ver "$target")
    local extras=()
    local objs=()
    local a
    for a in "$@"; do
        case "$a" in
            *.o) objs+=("$a") ;;
            *)
                local t
                while IFS= read -r t; do
                    [ -n "$t" ] && extras+=("$t")
                done < <(translate_ldflag "$a")
                ;;
        esac
    done
    "$MACHO_LD" -arch x86_64 -syslibroot "$SDK" -lSystem -L/usr/lib \
        -platform_version macos "$pv" "$pv" \
        -o "$out" "${objs[@]}" ${extras[@]+"${extras[@]}"}
}

link_dylib() {
    local out="$1" target="$2" install_name="$3"
    shift 3
    local pv; pv=$(platform_ver "$target")
    local extras=() objs=() a t
    for a in "$@"; do
        case "$a" in
            *.o) objs+=("$a") ;;
            *)
                while IFS= read -r t; do
                    [ -n "$t" ] && extras+=("$t")
                done < <(translate_ldflag "$a")
                ;;
        esac
    done
    "$MACHO_LD" -dylib -arch x86_64 -syslibroot "$SDK" -lSystem -L/usr/lib \
        -install_name "$install_name" \
        -platform_version macos "$pv" "$pv" \
        -o "$out" "${objs[@]}" ${extras[@]+"${extras[@]}"}
}

# build <id> <target> <output-name> <src-basenames...> -- <extra clang flags...>
build() {
    local id="$1"; shift
    local target="$1"; shift
    local out="$1"; shift
    local srcs=() extra_c=() extra_ld=()
    while [ $# -gt 0 ] && [ "$1" != "--" ]; do srcs+=("$1"); shift; done
    [ "${1:-}" = "--" ] && shift
    local a
    for a in "$@"; do
        case "$a" in
            -Wl*) extra_ld+=("$a") ;;
            -std=*|-f*|-W*|-D*|-I*|-g*|-O*|-m*|-pthread) extra_c+=("$a") ;;
            *) extra_ld+=("$a") ;;
        esac
    done
    echo "==> $id"
    local objs=() src base obj
    for src in "${srcs[@]}"; do
        case "$src" in
            *.s)
                refuse "CANNOT_ASSEMBLE_X86" "$id" \
                    "source $src is arm64 assembly; no x86_64 translation in tests/src"
                return 0
                ;;
            *.m)
                if [ ! -f "$ROOT/darwin/usr/lib/libobjc.A.dylib" ]; then
                    refuse "CANNOT_BUILD_LIBOBJC_X86" "$id" \
                        "libobjc.A.dylib is not built; run scripts/build.sh objc4"
                    return 0
                fi
                ;;
            *.swift)
                refuse "CANNOT_BUILD_SWIFT_X86" "$id" "Swift fixtures are out of this phase"
                return 0
                ;;
        esac
        base="$(basename "$src")"
        obj="$OBJ/${id}_${base%.*}.o"
        if ! compile_one "$SRC/$src" "$obj" "$target" ${extra_c[@]+"${extra_c[@]}"}; then
            refuse "CANNOT_LINK_X86" "$id" "compile of $src failed"
            return 0
        fi
        objs+=("$obj")
    done
    if ! link_exe "$BIN/$out" "$target" "${objs[@]}" ${extra_ld[@]+"${extra_ld[@]}"}; then
        refuse "CANNOT_LINK_X86" "$id" "link of $out failed"
        return 0
    fi
    built_ids+=("$id")
    BUILT=$((BUILT + 1))
}

build_dylib() {
    local target="$1" src="$2" out="$3" install_name="$4"
    shift 4
    local extra_c=() extra_ld=() a
    for a in "$@"; do
        case "$a" in
            -Wl*) extra_ld+=("$a") ;;
            -std=*|-f*|-W*|-D*|-I*|-g*|-O*|-m*|-pthread) extra_c+=("$a") ;;
            *) extra_ld+=("$a") ;;
        esac
    done
    local obj="$OBJ/$(basename "$out").o"
    compile_one "$SRC/$src" "$obj" "$target" ${extra_c[@]+"${extra_c[@]}"}
    link_dylib "$out" "$target" "$install_name" "$obj" ${extra_ld[@]+"${extra_ld[@]}"}
}

# ---------------------------------------------------------------- rungs
# Same order and same sources as tests/build_fixtures.sh. Flags are the Darwin
# clang flags that script passes; this file translates them for ld64.

if want exit_raw; then
    refuse "CANNOT_ASSEMBLE_X86" "exit_raw" \
        "tests/src/exit_raw.s is arm64 assembly; no x86_64 translation in tests/src"
fi
if want exit_unixthread; then
    refuse "CANNOT_ASSEMBLE_X86" "exit_unixthread" \
        "tests/src/exit_raw.s is arm64 assembly; LC_UNIXTHREAD x86_64 needs a distinct .s living beside, not instead"
fi

want main_ret         && build main_ret         "$CHAINED_TARGET" main_ret         main_ret.c --
want main_ret_classic && build main_ret_classic "$CLASSIC_TARGET" main_ret_classic main_ret.c --

want printf           && build printf           "$CHAINED_TARGET" printf           printf.c --
want printf_classic  && build printf_classic  "$CLASSIC_TARGET" printf_classic  printf.c --

want malloc           && build malloc           "$CHAINED_TARGET" malloc           malloc.c --

want mod_init          && build mod_init          "$CHAINED_TARGET" mod_init          mod_init.c --
want mod_init_classic && build mod_init_classic "$CLASSIC_TARGET" mod_init_classic mod_init.c --

if want cxx_init; then
    echo "==> cxx_init"
    if compile_one "$SRC/cxx_init.cpp" "$OBJ/cxx_init.o" "$CHAINED_TARGET" -std=c++17 && \
       link_exe "$BIN/cxx_init" "$CHAINED_TARGET" "$OBJ/cxx_init.o" -lc++; then
        built_ids+=(cxx_init); BUILT=$((BUILT + 1))
    else
        refuse "CANNOT_LINK_X86" "cxx_init" "C++ compile or link failed"
    fi
fi

want tls              && build tls              "$CHAINED_TARGET" tls              tls.c --

build_dylib_pair() {
    local target="$1" lib="$2" exe="$3"
    build_dylib "$target" dylib_lib.c "$BIN/$lib" "@rpath/$lib" -Wl,-U,_exe_callback
    compile_one "$SRC/dylib_main.c" "$OBJ/${exe}_main.o" "$target"
    link_exe "$BIN/$exe" "$target" "$OBJ/${exe}_main.o" "$BIN/$lib" \
        -Wl,-rpath,@loader_path -Wl,-export_dynamic
}

if want dylib; then
    echo "==> dylib"
    if build_dylib_pair "$CHAINED_TARGET" libdylib_greet.dylib dylib; then
        built_ids+=(dylib); BUILT=$((BUILT + 1))
    else
        refuse "CANNOT_LINK_X86" "dylib" "dylib pair link failed"
    fi
fi
if want dylib_classic; then
    echo "==> dylib_classic"
    if build_dylib_pair "$CLASSIC_TARGET" libdylib_greet_classic.dylib dylib_classic; then
        built_ids+=(dylib_classic); BUILT=$((BUILT + 1))
    else
        refuse "CANNOT_LINK_X86" "dylib_classic" "classic dylib pair link failed"
    fi
fi

want pthread          && build pthread          "$CHAINED_TARGET" pthread          pthread.c -- -pthread

want objc && build objc "$CHAINED_TARGET" objc objc.m -- \
    -fobjc-runtime=macosx-10.15 -Wno-objc-root-class \
    "$ROOT/darwin/usr/lib/libobjc.A.dylib"

want varargs          && build varargs          "$CHAINED_TARGET" varargs          varargs.c --
want varargs_classic && build varargs_classic "$CLASSIC_TARGET" varargs_classic varargs.c --
want mach             && build mach             "$CHAINED_TARGET" mach             mach.c --
want errno            && build errno            "$CHAINED_TARGET" errno            errno.c --
want utility          && build utility          "$CHAINED_TARGET" utility          utility.c --
want isa_mask         && build isa_mask         "$CHAINED_TARGET" isa_mask         isa_mask.c --
want pthread_cond     && build pthread_cond     "$CHAINED_TARGET" pthread_cond     pthread_cond.c --
want sigmask          && build sigmask          "$CHAINED_TARGET" sigmask          sigmask.c --
want sysconf          && build sysconf          "$CHAINED_TARGET" sysconf          sysconf.c --
want passwd           && build passwd           "$CHAINED_TARGET" passwd           passwd.c --

if want cxx_sort; then
    echo "==> cxx_sort"
    if compile_one "$SRC/cxx_sort.cpp" "$OBJ/cxx_sort.o" "$CHAINED_TARGET" -std=c++17 && \
       link_exe "$BIN/cxx_sort" "$CHAINED_TARGET" "$OBJ/cxx_sort.o" -lc++; then
        built_ids+=(cxx_sort); BUILT=$((BUILT + 1))
    else
        refuse "CANNOT_LINK_X86" "cxx_sort" "C++ compile or link failed"
    fi
fi

want malloc_type      && build malloc_type      "$CHAINED_TARGET" malloc_type      malloc_type.c --
want unwind           && build unwind           "$CHAINED_TARGET" unwind           unwind.c --
want poll             && build poll             "$CHAINED_TARGET" poll             poll.c --
want sigaction        && build sigaction        "$CHAINED_TARGET" sigaction        sigaction.c --

if want throw; then
    echo "==> throw"
    if compile_one "$SRC/throw.cpp" "$OBJ/throw.o" "$CHAINED_TARGET" -std=c++17 && \
       link_exe "$BIN/throw" "$CHAINED_TARGET" "$OBJ/throw.o" -lc++; then
        built_ids+=(throw); BUILT=$((BUILT + 1))
    else
        refuse "CANNOT_LINK_X86" "throw" "C++ compile or link failed"
    fi
fi

want fcntl_madvise    && build fcntl_madvise    "$CHAINED_TARGET" fcntl_madvise    fcntl_madvise.c --
want pthread_attr     && build pthread_attr     "$CHAINED_TARGET" pthread_attr     pthread_attr.c --

if want dlopen; then
    echo "==> dlopen"
    if build_dylib "$CHAINED_TARGET" dlopen_plug.c "$BIN/libdlopen_plug.dylib" \
            "@rpath/libdlopen_plug.dylib" && \
       compile_one "$SRC/dlopen.c" "$OBJ/dlopen.o" "$CHAINED_TARGET" && \
       link_exe "$BIN/dlopen" "$CHAINED_TARGET" "$OBJ/dlopen.o"; then
        built_ids+=(dlopen); BUILT=$((BUILT + 1))
    else
        refuse "CANNOT_LINK_X86" "dlopen" "plugin or executable link failed"
    fi
fi

want sysctl           && build sysctl           "$CHAINED_TARGET" sysctl           sysctl.c --

if want dladdr; then
    echo "==> dladdr"
    if compile_one "$SRC/dladdr.c" "$OBJ/dladdr.o" "$CHAINED_TARGET" && \
       link_exe "$BIN/dladdr" "$CHAINED_TARGET" "$OBJ/dladdr.o" -Wl,-export_dynamic; then
        built_ids+=(dladdr); BUILT=$((BUILT + 1))
    else
        refuse "CANNOT_LINK_X86" "dladdr" "link failed"
    fi
fi

want execpath         && build execpath         "$CHAINED_TARGET" execpath         execpath.c --
want dyld_images      && build dyld_images      "$CHAINED_TARGET" dyld_images      dyld_images.c --
want osatomic         && build osatomic         "$CHAINED_TARGET" osatomic         osatomic.c --
want rlimit           && build rlimit           "$CHAINED_TARGET" rlimit           rlimit.c --

if want loader_path; then
    echo "==> loader_path"
    LP_DIR="$BIN/loader_path_plugins"
    mkdir -p "$LP_DIR"
    ok=1
    for where in bin plugins; do
        case "$where" in
            bin)     out="$BIN/libloader_path_leaf.dylib" ;;
            plugins) out="$LP_DIR/libloader_path_leaf.dylib" ;;
        esac
        obj="$OBJ/loader_path_leaf_$where.o"
        if ! compile_one "$SRC/loader_path_leaf.c" "$obj" "$CHAINED_TARGET" \
                -DLEAF_WHERE="\"$where\"" || \
           ! link_dylib "$out" "$CHAINED_TARGET" "@rpath/libloader_path_leaf_$where.dylib" "$obj"; then
            ok=0
        fi
    done
    if [ "$ok" = 1 ] && \
       compile_one "$SRC/loader_path_mid.c" "$OBJ/loader_path_mid.o" "$CHAINED_TARGET" && \
       link_dylib "$LP_DIR/libloader_path_mid.dylib" "$CHAINED_TARGET" \
            "@rpath/libloader_path_mid.dylib" "$OBJ/loader_path_mid.o" \
            -Wl,-rpath,@loader_path && \
       compile_one "$SRC/loader_path.c" "$OBJ/loader_path.o" "$CHAINED_TARGET" && \
       link_exe "$BIN/loader_path" "$CHAINED_TARGET" "$OBJ/loader_path.o" \
            "$LP_DIR/libloader_path_mid.dylib" \
            -Wl,-rpath,@loader_path \
            -Wl,-rpath,@loader_path/loader_path_plugins; then
        built_ids+=(loader_path); BUILT=$((BUILT + 1))
    else
        refuse "CANNOT_LINK_X86" "loader_path" "multi-directory dylib link failed"
    fi
fi

if want dup_images; then
    echo "==> dup_images"
    DUP_DIR="$BIN/dup_images_alias"
    mkdir -p "$DUP_DIR"
    ok=1
    if ! command -v "$INSTALL_NAME_TOOL" >/dev/null; then
        refuse "CANNOT_LINK_X86" "dup_images" "no $INSTALL_NAME_TOOL"
        ok=0
    fi
    if [ "$ok" = 1 ]; then
        for kind in link copy; do
            obj="$OBJ/dup_leaf_$kind.o"
            midobj="$OBJ/dup_mid_$kind.o"
            if ! compile_one "$SRC/dup_images_leaf.c" "$obj" "$CHAINED_TARGET" -DDUP_KIND="$kind" || \
               ! link_dylib "$BIN/libdup_$kind.dylib" "$CHAINED_TARGET" \
                    "@rpath/libdup_$kind.dylib" "$obj"; then
                ok=0; break
            fi
            rm -f "$DUP_DIR/libdup_$kind.dylib"
            if [ "$kind" = link ]; then ln -s "../libdup_$kind.dylib" "$DUP_DIR/libdup_$kind.dylib"
            else cp "$BIN/libdup_$kind.dylib" "$DUP_DIR/libdup_$kind.dylib"; fi
            if ! compile_one "$SRC/dup_images_mid.c" "$midobj" "$CHAINED_TARGET" -DDUP_KIND="$kind" || \
               ! link_dylib "$BIN/libdup_${kind}_mid.dylib" "$CHAINED_TARGET" \
                    "@rpath/libdup_${kind}_mid.dylib" "$midobj" "$BIN/libdup_$kind.dylib" \
                    -Wl,-rpath,@loader_path; then
                ok=0; break
            fi
            "$INSTALL_NAME_TOOL" -change "@rpath/libdup_$kind.dylib" \
                "@rpath/dup_images_alias/libdup_$kind.dylib" "$BIN/libdup_${kind}_mid.dylib"
        done
    fi
    if [ "$ok" = 1 ] && \
       compile_one "$SRC/dup_images.c" "$OBJ/dup_images.o" "$CHAINED_TARGET" && \
       link_exe "$BIN/dup_images" "$CHAINED_TARGET" "$OBJ/dup_images.o" \
            "$BIN/libdup_link.dylib" "$BIN/libdup_link_mid.dylib" \
            "$BIN/libdup_copy.dylib" "$BIN/libdup_copy_mid.dylib" \
            -Wl,-rpath,@loader_path; then
        built_ids+=(dup_images); BUILT=$((BUILT + 1))
    else
        [ -f "$META/dup_images" ] || refuse "CANNOT_LINK_X86" "dup_images" "dedupe-contract link failed"
    fi
fi

want environ             && build environ             "$CHAINED_TARGET" environ             environ.c --
want exp10_strings       && build exp10_strings       "$CHAINED_TARGET" exp10_strings       exp10_strings.c --
want dirent_r            && build dirent_r            "$CHAINED_TARGET" dirent_r            dirent_r.c --
want sscanf              && build sscanf              "$CHAINED_TARGET" sscanf              sscanf.c --
want vm_copy             && build vm_copy             "$CHAINED_TARGET" vm_copy             vm_copy.c --
want uname               && build uname               "$CHAINED_TARGET" uname               uname.c --
want grp                 && build grp                 "$CHAINED_TARGET" grp                 grp.c --
want xattr               && build xattr               "$CHAINED_TARGET" xattr               xattr.c --
want quota               && build quota               "$CHAINED_TARGET" quota               quota.c --
want fts                 && build fts                 "$CHAINED_TARGET" fts                 fts.c --
want pthread_mutex_variants && build pthread_mutex_variants "$CHAINED_TARGET" pthread_mutex_variants pthread_mutex_variants.c --
want cflog_surface       && build cflog_surface       "$CHAINED_TARGET" cflog_surface       cflog_surface.c --
want statfs              && build statfs              "$CHAINED_TARGET" statfs              statfs.c --
want copyfile            && build copyfile            "$CHAINED_TARGET" copyfile            copyfile.c --
want hostbound_surface   && build hostbound_surface   "$CHAINED_TARGET" hostbound_surface   hostbound_surface.c --
want hostbound_osver     && build hostbound_osver     "$CHAINED_TARGET" hostbound_osver     hostbound_osver.c --
want fmal                && build fmal                "$CHAINED_TARGET" fmal                fmal.c -- -fno-builtin
want dyld_objc_constant  && build dyld_objc_constant  "$CHAINED_TARGET" dyld_objc_constant  dyld_objc_constant.c --
want dirent              && build dirent              "$CHAINED_TARGET" dirent              dirent.c --

# quartz / objc_quartz / objc_shapes live in tests/draw_manifest.tsv, not the
# stdout difftest. Build them when named and the dylibs exist; otherwise refuse.
if [ ${#WANT[@]} -gt 0 ]; then
    for id in quartz objc_quartz objc_shapes; do
        want "$id" || continue
        if [ ! -f "$ROOT/darwin/usr/lib/libquartz.dylib" ]; then
            refuse "CANNOT_BUILD_QUARTZ_X86" "$id" \
                "libquartz.dylib is not built; run scripts/build.sh quartz"
            continue
        fi
        if [ "$id" != quartz ] && [ ! -f "$ROOT/darwin/usr/lib/libobjc.A.dylib" ]; then
            refuse "CANNOT_BUILD_LIBOBJC_X86" "$id" \
                "libobjc.A.dylib is not built; run scripts/build.sh objc4"
            continue
        fi
        case "$id" in
            quartz)
                build quartz "$CHAINED_TARGET" quartz quartz.c -- \
                    -I"$ROOT/vendor/quartz/include" \
                    "$ROOT/darwin/usr/lib/libquartz.dylib"
                ;;
            objc_quartz)
                build objc_quartz "$CHAINED_TARGET" objc_quartz objc_quartz.m -- \
                    -I"$ROOT/vendor/quartz/include" -fobjc-runtime=macosx-10.15 \
                    -Wno-objc-root-class \
                    "$ROOT/darwin/usr/lib/libobjc.A.dylib" \
                    "$ROOT/darwin/usr/lib/libquartz.dylib"
                ;;
            objc_shapes)
                build objc_shapes "$CHAINED_TARGET" objc_shapes objc_shapes.m -- \
                    -I"$ROOT/vendor/quartz/include" -fobjc-runtime=macosx-10.15 \
                    -Wno-objc-root-class \
                    "$ROOT/darwin/usr/lib/libobjc.A.dylib" \
                    "$ROOT/darwin/usr/lib/libquartz.dylib"
                ;;
        esac
    done
fi

if want fat; then
    echo "==> fat"
    if [ ! -f "$BIN/printf" ]; then
        refuse "CANNOT_LIPO_X86" "fat" "fat is lipo'd from printf; build that first"
    elif [ ! -f "$ARM64_BIN/printf" ]; then
        refuse "CANNOT_LIPO_X86" "fat" "need arm64 tests/bin/printf as the other slice"
    elif ! command -v "$LIPO" >/dev/null; then
        refuse "CANNOT_LIPO_X86" "fat" "no $LIPO"
    elif "$LIPO" -create -output "$BIN/fat" "$BIN/printf" "$ARM64_BIN/printf"; then
        built_ids+=(fat); BUILT=$((BUILT + 1))
    else
        refuse "CANNOT_LIPO_X86" "fat" "llvm-lipo -create failed"
    fi
fi

# Any remaining manifest ids that this script does not know how to build.
if [ ${#WANT[@]} -eq 0 ] && [ -f "$ROOT/tests/manifest.tsv" ]; then
    while IFS=$'\t' read -r id _; do
        [[ "$id" == \#* || -z "$id" ]] && continue
        [[ " ${built_ids[*]} " == *" $id "* ]] && continue
        [[ -f "$META/$id" ]] && continue
        refuse "CANNOT_BUILD_X86" "$id" "no builder case for this fixture"
    done < "$ROOT/tests/manifest.tsv"
fi

echo
echo "BUILD_SUMMARY built=$BUILT refused=$REFUSED out=$BIN"
echo "built: ${built_ids[*]:-<none>}"
printf '%s\n' "$BUILT" > "$BIN/.built_count"
printf '%s\n' "$REFUSED" > "$BIN/.refused_count"
