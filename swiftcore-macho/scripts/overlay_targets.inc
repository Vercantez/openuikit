# overlay_targets.inc -- sourced. Derive overlay ninja names from the
# configured graph (`ninja -t targets`), never from a hardcoded list that
# can name a target CMake did not create.
#
# Phase-2 FE mrroot overlays (scripts/x86/common.inc phase2_fe_overlay_names)
# plus _Concurrency / Observation that the SwiftUI guest also loads.
# In-tree on a Linux-host OSX configure: _Concurrency, Synchronization,
# _StringProcessing, _Builtin_float, _RegexParser (with STRING_PROCESSING),
# Observation (with OBSERVATION), Darwin (Platform/). Not CMake targets on
# Linux: ObjectiveC, _DarwinFoundation1/2/3, _errno — those are Apple SDK
# overlays (stdlib/public/CMakeLists.txt:359: "On Apple platforms, we aren't
# building any overlays. Instead, we're picking them up from the SDK.").
# They are not ninja targets. `overlay_build_xcode_shells` compiles them
# from sysroot .swiftinterface (or in-tree re-export shells) + ObjectiveC.swift
# with the Darwin driver *before* the Darwin ninja target so libswiftDarwin
# can LC_REEXPORT DarwinFoundation{1,2,3}. Shared-cache Apple dylibs have no
# LC_DYLD_INFO.

if [ -n "${SWIFTCORE_OVERLAY_TARGETS_INC:-}" ]; then
    return 0 2>/dev/null || exit 0
fi
SWIFTCORE_OVERLAY_TARGETS_INC=1

# ninja -t commands for a dylib node is megabytes (every object). Passing
# that string as a python argv is E2BIG; bash then reports rc=126 and
# CANNOT_NOT_EXECUTABLE blames /usr/bin/python3. Write a temp file.
overlay_write_ninja_commands() {
    local dest=${1:?overlay_write_ninja_commands: dest}
    local build_dir=${2:?overlay_write_ninja_commands: build dir}
    local node=${3:?overlay_write_ninja_commands: node}
    local ninja_bin=${NINJA:-ninja}
    if ! "$ninja_bin" -C "$build_dir" -t commands "$node" >"$dest" 2>/dev/null; then
        : > "$dest"
    fi
}

overlay_candidate_targets() {
    local arch=${1:?overlay_candidate_targets: arch}
    # Builtin_float before Darwin so libswiftDarwin can LC_REEXPORT it.
    # Darwin before Synchronization (Sync's ninja graph depends on Darwin).
    # DarwinFoundation shells are not ninja targets; overlay_build_xcode_shells
    # runs them before this ninja loop.
    printf '%s\n' \
        "swift_Builtin_float-macosx-${arch}" \
        "swiftDarwin-macosx-${arch}" \
        "swift_Concurrency-macosx-${arch}" \
        "swift_StringProcessing-macosx-${arch}" \
        "swift_RegexParser-macosx-${arch}" \
        "swiftObservation-macosx-${arch}" \
        "swiftSynchronization-macosx-${arch}" \
        "swift_DarwinFoundation1-macosx-${arch}" \
        "swift_DarwinFoundation2-macosx-${arch}" \
        "swift_DarwinFoundation3-macosx-${arch}" \
        "swift_errno-macosx-${arch}" \
        "swiftObjectiveC-macosx-${arch}"
}

overlay_required_target() {
    case "$1" in
        swift_Concurrency-macosx-*|swiftSynchronization-macosx-*|swift_StringProcessing-macosx-*|swift_Builtin_float-macosx-*|swift_RegexParser-macosx-*)
            return 0 ;;
        *) return 1 ;;
    esac
}

overlay_xcode_only_target() {
    case "$1" in
        swiftObjectiveC-macosx-*|swift_DarwinFoundation[123]-macosx-*|swift_errno-macosx-*)
            return 0 ;;
        *) return 1 ;;
    esac
}

# Fill OVERLAY_NINJA_TARGETS. Print CANNOT_* for missing names. Exit 2 if a
# required overlay is absent. Never emit a name that is not in `ninja -t targets`.
# OVERLAY_STATUS[target] is built|FAILED|CANNOT_<reason> (CANNOT filled here;
# built/FAILED filled by the caller after each independent ninja).
#
# overlay_select_targets <build_dir> <arch>
overlay_select_targets() {
    local build_dir=${1:?overlay_select_targets: build dir}
    local arch=${2:?overlay_select_targets: arch}
    local dump n have
    OVERLAY_NINJA_TARGETS=()
    declare -gA OVERLAY_STATUS
    OVERLAY_STATUS=()

    if [ -n "${NINJA_TARGETS_DUMP:-}" ]; then
        dump=$(cat "$NINJA_TARGETS_DUMP")
    else
        local ninja_bin=${NINJA:-ninja}
        dump=$("$ninja_bin" -C "$build_dir" -t targets)
    fi
    echo "overlay_select: ninja -t targets from ${NINJA_TARGETS_DUMP:-$build_dir}"

    local missing_required=0
    while IFS= read -r n; do
        [ -n "$n" ] || continue
        have=0
        printf '%s\n' "$dump" | grep -E "^${n}:" >/dev/null && have=1
        if [ "$have" = 1 ]; then
            echo "overlay_select: have $n"
            OVERLAY_NINJA_TARGETS+=("$n")
            continue
        fi
        if overlay_xcode_only_target "$n"; then
            echo "CANNOT_STAGE_XCODE_DARWIN_OVERLAYS target=$n reason=not in ninja -t targets; will build via overlay_build_xcode_shells (sysroot interface / in-tree re-export, not Apple dyld-cache copies)"
            OVERLAY_STATUS[$n]=CANNOT_STAGE_XCODE_DARWIN_OVERLAYS
            continue
        fi
        if overlay_required_target "$n"; then
            echo "CANNOT_OVERLAY_TARGET_ABSENT target=$n reason=not in ninja -t targets; required overlay was not created by this CMake configuration" >&2
            OVERLAY_STATUS[$n]=CANNOT_OVERLAY_TARGET_ABSENT
            missing_required=1
            continue
        fi
        # Observation is in-tree when SWIFT_ENABLE_EXPERIMENTAL_OBSERVATION=ON
        # (overlays=1). An older graph without that flag still lists it on the
        # scoreboard as CANNOT rather than failing the whole select.
        if [[ "$n" == swiftObservation-macosx-* ]]; then
            echo "CANNOT_OVERLAY_TARGET_ABSENT target=$n reason=not in ninja -t targets; enable -DSWIFT_ENABLE_EXPERIMENTAL_OBSERVATION=ON (SWIFTCORE_OVERLAYS=1)"
            OVERLAY_STATUS[$n]=CANNOT_OVERLAY_TARGET_ABSENT
            continue
        fi
        # Darwin (and any other optional Platform overlay): named refusal, skip.
        echo "CANNOT_STAGE_XCODE_DARWIN_OVERLAYS target=$n reason=not in ninja -t targets"
        OVERLAY_STATUS[$n]=CANNOT_STAGE_XCODE_DARWIN_OVERLAYS
    done < <(overlay_candidate_targets "$arch")

    if [ "$missing_required" = 1 ]; then
        if [ ${#OVERLAY_NINJA_TARGETS[@]} -gt 0 ]; then
            echo "overlay_select: will ninja ${OVERLAY_NINJA_TARGETS[*]}"
        else
            echo "overlay_select: will ninja"
        fi
        return 2
    fi
    if [ ${#OVERLAY_NINJA_TARGETS[@]} -eq 0 ]; then
        echo "overlay_select: no overlay ninja targets in this configuration" >&2
        return 2
    fi
    echo "overlay_select: will ninja ${OVERLAY_NINJA_TARGETS[*]}"
    return 0
}

# OVERLAY <ninja-target> built|FAILED|CANNOT_<reason>
overlay_print_scoreboard() {
    local arch=${1:?overlay_print_scoreboard: arch}
    local n st
    echo "==== overlay scoreboard ===="
    while IFS= read -r n; do
        [ -n "$n" ] || continue
        st=${OVERLAY_STATUS[$n]:-UNKNOWN}
        echo "OVERLAY $n $st"
    done < <(overlay_candidate_targets "$arch")
}

# ls of produced overlay dylibs / ELF .so under lib/swift/macosx.
overlay_list_products() {
    local root=${1:?overlay_list_products: macosx dir}
    echo "==== overlay products $root ===="
    if [ ! -d "$root" ]; then
        echo "(absent)"
        return 0
    fi
    ls -la "$root"
    local d
    for d in "$root"/*/; do
        [ -d "$d" ] || continue
        echo "-- $d --"
        ls -la "$d"
    done
    echo "-- libswift*.dylib / libswift*.so --"
    find "$root" \( -name 'libswift*.dylib' -o -name 'libswift*.so' \) -print | sort
}

# Flatten lib/swift/macosx/<arch>/libswiftX.{so,dylib,a} to
# lib/swift/macosx/libswiftX.* (the unarch path overlay ninja depends on).
# overlay_flatten_unarch <build_dir> <arch>
overlay_flatten_unarch() {
    local build_dir=${1:?overlay_flatten_unarch: build dir}
    local arch=${2:?overlay_flatten_unarch: arch}
    local arch_dir=$build_dir/lib/swift/macosx/$arch
    local unarch=$build_dir/lib/swift/macosx
    local f bn
    [ -d "$arch_dir" ] || return 0
    mkdir -p "$unarch"
    for f in "$arch_dir"/libswift*.so "$arch_dir"/libswift*.dylib "$arch_dir"/libswift*.a; do
        [ -e "$f" ] || continue
        bn=$(basename "$f")
        ln -sfn "$arch/$bn" "$unarch/$bn"
    done
}

# Print the exact -isysroot / -sdk the Darwin overlay compile receives.
# Swift's Darwin.o line uses -sdk (clang cc1 may rewrite that to -isysroot);
# print both, so the operator log proves which tree ninja used.
# overlay_print_isysroot_from_ninja <build_dir> <arch>
overlay_print_isysroot_from_ninja() {
    local build_dir=${1:?overlay_print_isysroot_from_ninja: build dir}
    local arch=${2:?overlay_print_isysroot_from_ninja: arch}
    local darwin_o="stdlib/public/Platform/OSX/${arch}/Darwin.o"
    local cmds_file node
    cmds_file=$(mktemp)
    echo "overlay_sysroot: ninja -t commands for Darwin overlay compile (arch=$arch)"
    for node in "$darwin_o" "swiftDarwin-macosx-${arch}"; do
        overlay_write_ninja_commands "$cmds_file" "$build_dir" "$node"
        if [ -s "$cmds_file" ]; then
            echo "overlay_sysroot: ninja -t commands node=$node"
            break
        fi
    done
    if [ ! -s "$cmds_file" ]; then
        echo "overlay_sysroot: ninja -t commands Darwin.o ABSENT (no -isysroot/-sdk in graph yet)"
        rm -f "$cmds_file"
        return 0
    fi
    python3 - "$cmds_file" <<'PY'
import pathlib, sys
text = pathlib.Path(sys.argv[1]).read_text(errors="replace")
tokens = text.split()
flags = ("-isysroot", "-sdk")
seen = {f: [] for f in flags}
i = 0
while i < len(tokens):
    t = tokens[i]
    for f in flags:
        if t == f and i + 1 < len(tokens):
            p = tokens[i + 1]
            if p not in seen[f]:
                seen[f].append(p)
            i += 2
            break
        if t.startswith(f + "="):
            p = t.split("=", 1)[1]
            if p not in seen[f]:
                seen[f].append(p)
            i += 1
            break
    else:
        i += 1
for f in flags:
    if seen[f]:
        for p in seen[f]:
            print("overlay_sysroot: ninja Darwin.o %s=%s" % (f, p))
    else:
        print("overlay_sysroot: ninja Darwin.o %s=ABSENT" % f)
PY
    rm -f "$cmds_file"
}

# Prove overlay compiles load Darwin via -sdk, not libc++ via -fmodule-map-file.
# overlay_print_overlay_module_evidence <build_dir> <arch>
overlay_print_overlay_module_evidence() {
    local build_dir=${1:?overlay_print_overlay_module_evidence: build dir}
    local arch=${2:?overlay_print_overlay_module_evidence: arch}
    local ninja_bin=${NINJA:-ninja}
    local node ifc
    echo "overlay_sysroot: overlay compile module evidence (arch=$arch)"
    for node in \
        "stdlib/public/Platform/OSX/${arch}/Darwin.o" \
        "swiftSynchronization-macosx-${arch}" \
        "swift_Concurrency-macosx-${arch}" \
        "swift_StringProcessing-macosx-${arch}" \
        "swift_Builtin_float-macosx-${arch}" \
        "swift_RegexParser-macosx-${arch}" \
        "swiftObservation-macosx-${arch}"
    do
        local cmds
        cmds=$("$ninja_bin" -C "$build_dir" -t commands "$node" 2>/dev/null) || cmds=""
        if [ -z "$cmds" ]; then
            echo "overlay_sysroot: ninja $node commands=ABSENT"
            continue
        fi
        if printf '%s\n' "$cmds" | grep -q -- '-fmodule-map-file'; then
            echo "overlay_sysroot: ninja $node -fmodule-map-file=PRESENT"
            printf '%s\n' "$cmds" | tr ' ' '\n' | grep -E '^-fmodule-map-file' | sort -u | sed 's/^/overlay_sysroot:   /'
        else
            echo "overlay_sysroot: ninja $node -fmodule-map-file=ABSENT"
        fi
    done
    local macosx=$build_dir/lib/swift/macosx
    for ifc in \
        "$macosx/Darwin.swiftmodule/"*apple-macos.swiftinterface \
        "$macosx/Synchronization.swiftmodule/"*apple-macos.swiftinterface \
        "$macosx/_Concurrency.swiftmodule/"*apple-macos.swiftinterface \
        "$macosx/_StringProcessing.swiftmodule/"*apple-macos.swiftinterface \
        "$macosx/_Builtin_float.swiftmodule/"*apple-macos.swiftinterface \
        "$macosx/_RegexParser.swiftmodule/"*apple-macos.swiftinterface \
        "$macosx/Observation.swiftmodule/"*apple-macos.swiftinterface
    do
        [ -f "$ifc" ] || continue
        echo "overlay_sysroot: imports $(basename "$(dirname "$ifc")")/$(basename "$ifc"): $(grep -E '^(@_exported )?import ' "$ifc" | tr '\n' ' ')"
    done
}

# Print the ninja link for libswiftDarwin.so and the argv the shim would
# run. Classify by `-target` (apple → Darwin/ld64.lld even when CMake names
# the output .so). Darwin is driver pass-through (no rewritten argv);
# GNU -soname becomes -install_name. ninja -t commands is read from a
# temp file (never argv — E2BIG is bash rc=126).
# overlay_print_darwin_link_from_ninja <build_dir> <arch>
overlay_print_darwin_link_from_ninja() {
    local build_dir=${1:?overlay_print_darwin_link_from_ninja: build dir}
    local arch=${2:?overlay_print_darwin_link_from_ninja: arch}
    local py
    py=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/clangxx_darwin_link.py
    local node="lib/swift/macosx/${arch}/libswiftDarwin.so"
    local cmds_file
    cmds_file=$(mktemp)
    echo "overlay_link: ninja -t commands for Darwin dylib (arch=$arch node=$node)"
    overlay_write_ninja_commands "$cmds_file" "$build_dir" "$node"
    if [ ! -s "$cmds_file" ]; then
        overlay_write_ninja_commands "$cmds_file" "$build_dir" "swiftDarwin-macosx-${arch}"
    fi
    if [ ! -s "$cmds_file" ]; then
        echo "overlay_link: ninja Darwin dylib command ABSENT"
        rm -f "$cmds_file"
        return 0
    fi
    python3 - "$py" "$cmds_file" <<'PY'
import os, pathlib, shlex, subprocess, sys

def compiler_args(line):
    argv = shlex.split(line)
    if not argv:
        return []
    # CMake CXX_SHARED_LIBRARY rules wrap as: : && <compiler> ... && :
    if argv[0] == ":" and len(argv) > 2 and argv[1] == "&&":
        argv = argv[2:]
    while len(argv) >= 2 and argv[-2] == "&&" and argv[-1] == ":":
        argv = argv[:-2]
    i = 0
    for j, t in enumerate(argv):
        base = os.path.basename(t.rstrip("\\"))
        if base in ("clang++", "clang", "clangxx_darwin_link.py") or t.endswith("/clang++"):
            i = j
            break
    return argv[i + 1 :]

py, cmds_path = sys.argv[1], sys.argv[2]
text = pathlib.Path(cmds_path).read_text(errors="replace")
line = None
for raw in text.splitlines():
    if "libswiftDarwin.so" in raw and " -o " in raw and (
        "clang++" in raw or "clang " in raw or raw.lstrip().startswith("clang")
    ):
        line = raw
        break
if line is None:
    for raw in text.splitlines():
        if "libswiftDarwin.so" in raw and ("-shared" in raw or "-dynamiclib" in raw or "soname" in raw):
            line = raw
            break
if line is None:
    print("overlay_link: ninja Darwin dylib command ABSENT (no clang++ link line)")
    sys.exit(0)
print("overlay_link: ninja", line)
args = compiler_args(line)
env = os.environ.copy()
env["SWIFTCORE_CLANGXX_PRINT_REWRITTEN"] = "1"
proc = subprocess.run(
    [sys.executable, py, *args], env=env, text=True, capture_output=True
)
executed = (proc.stdout or "").strip()
err = (proc.stderr or "").strip()
if err:
    for eline in err.splitlines():
        print(eline)
        if "rewritten argv:" in eline:
            print("overlay_link: Darwin must not log rewritten argv")
            sys.exit(1)

def flavor_from_argv(tokens):
    for i, tok in enumerate(tokens):
        if tok in ("-target", "--target") and i + 1 < len(tokens):
            t = tokens[i + 1].lower()
            if "apple" in t:
                return "darwin"
            if "linux" in t or "unknown-linux" in t:
                return "elf"
        if tok.startswith("--target=") or tok.startswith("-target="):
            t = tok.split("=", 1)[1].lower()
            if "apple" in t:
                return "darwin"
            if "linux" in t or "unknown-linux" in t:
                return "elf"
    if any("MacOSX.sdk" in t for t in tokens) or any(t.endswith(".dylib") for t in tokens):
        return "darwin"
    return "elf"

decision = next((l for l in err.splitlines() if l.startswith("clangxx_darwin_link: -o ")), "")
if not decision:
    print("overlay_link: missing -o decision line")
    sys.exit(1)
flavor = flavor_from_argv(args)
if flavor == "elf":
    print("overlay_link: rewritten", executed if executed else "ABSENT")
    if "decision=elf" not in decision or "linker=ld.lld" not in decision:
        print("overlay_link: linux-target .so must be decision=elf linker=ld.lld")
        sys.exit(1)
    if "soname" not in executed:
        print("overlay_link: ELF rewritten dropped soname")
        sys.exit(1)
    if "ld64.lld" in executed:
        print("overlay_link: ELF linux-target link still targets ld64.lld")
        sys.exit(1)
else:
    print("overlay_link: driver argv", executed if executed else "ABSENT")
    if "decision=darwin" not in decision or "linker=ld64.lld" not in decision:
        print("overlay_link: apple-target .so must be decision=darwin linker=ld64.lld")
        sys.exit(1)
    if "soname" in executed:
        print("overlay_link: Darwin driver argv still has GNU -soname")
        sys.exit(1)
    if executed and "-install_name" not in executed and "-Wl,-install_name" not in executed:
        print("overlay_link: driver argv missing -install_name")
        sys.exit(1)
    if "ld64.lld" not in executed:
        print("overlay_link: Darwin driver argv missing ld64.lld")
        sys.exit(1)
    if "-fuse-ld=lld" not in executed:
        print("overlay_link: Darwin driver argv missing -fuse-ld=lld")
        sys.exit(1)
    if "-dynamiclib" in executed.split():
        print("overlay_link: Darwin driver argv injected -dynamiclib")
        sys.exit(1)
    if "-nostdlib" in executed.split():
        print("overlay_link: Darwin driver argv injected -nostdlib (C); use -nostdlib++")
        sys.exit(1)
    if "/usr/lib/llvm-18/lib" in executed:
        print("overlay_link: Darwin driver argv still has host /usr/lib/llvm-18/lib")
        sys.exit(1)
    cxx = next((l for l in err.splitlines() if l.startswith("clangxx_darwin_link: cxx_runtime=")), "")
    if "libc++.tbd" not in cxx:
        print("overlay_link: missing cxx_runtime= sysroot libc++.tbd")
        sys.exit(1)
    crt = next((l for l in err.splitlines() if l.startswith("clangxx_darwin_link: compiler_rt=")), "")
    if "libclang_rt.osx.a" not in crt or "libclang_rt.osx.a" not in executed:
        print("overlay_link: missing compiler_rt= libclang_rt.osx.a")
        sys.exit(1)
    if "-platform_version" in executed.split() or (
        "-arch" in executed.split() and "ld64" not in executed
    ):
        print("overlay_link: Darwin shim injected linker flags the driver should compose")
        sys.exit(1)
PY
    local st=$?
    rm -f "$cmds_file"
    return "$st"
}

# Resolve the phony overlay target to its libswift*.so and see whether that
# node's ninja inputs include the Darwin overlay (libswiftDarwin / Darwin.swiftmodule).
# overlay_ninja_depends_on_darwin <build_dir> <target> → 0 if yes.
overlay_ninja_depends_on_darwin() {
    local build_dir=${1:?overlay_ninja_depends_on_darwin: build dir}
    local target=${2:?overlay_ninja_depends_on_darwin: target}
    local ninja_bin=${NINJA:-ninja}
    local q so
    q=$("$ninja_bin" -C "$build_dir" -t query "$target" 2>/dev/null) || q=""
    so=$(printf '%s\n' "$q" | awk '/libswift[^ /]*\.(so|dylib)/ { gsub(/^[ \t|]+/, ""); print $1; exit }')
    if [ -n "$so" ]; then
        q=$q$'\n'$("$ninja_bin" -C "$build_dir" -t query "$so" 2>/dev/null || true)
    fi
    printf '%s\n' "$q" | grep -Eq 'libswiftDarwin\.(so|dylib)|swiftDarwin-swiftmodule|Platform/swiftDarwin'
}

# First compiler/ninja error line from an overlay log, single line.
# overlay_first_error <logfile>
overlay_first_error() {
    local log=${1:?overlay_first_error: log}
    local line
    [ -f "$log" ] || { printf 'ABSENT\n'; return 0; }
    line=$(grep -E -m1 '(^error:|: error:|^fatal error:|ninja: error:)' "$log" || true)
    if [ -z "$line" ]; then
        line=$(grep -E -m1 'FAILED:|ninja: build stopped' "$log" || true)
    fi
    if [ -z "$line" ]; then
        printf 'ABSENT\n'
        return 0
    fi
    printf '%s\n' "$line" | tr '\n' ' ' | sed 's/[[:space:]]\+/ /g; s/[[:space:]]*$//'
}

# If this overlay's ninja graph depends on swiftDarwin, record
# FAILED dep=swiftDarwin. Otherwise FAILED first_error=<line>.
# overlay_status_on_fail <build_dir> <target> <logfile>
overlay_status_on_fail() {
    local build_dir=${1:?overlay_status_on_fail: build dir}
    local target=${2:?overlay_status_on_fail: target}
    local log=${3:?overlay_status_on_fail: log}
    local err
    case "$target" in
        swiftDarwin-macosx-*)
            err=$(overlay_first_error "$log")
            OVERLAY_STATUS[$target]="FAILED first_error=$err"
            echo "OVERLAY $target FAILED first_error=$err"
            return 0
            ;;
    esac
    if overlay_ninja_depends_on_darwin "$build_dir" "$target"; then
        OVERLAY_STATUS[$target]="FAILED dep=swiftDarwin"
        echo "OVERLAY $target FAILED dep=swiftDarwin (ninja graph inputs include libswiftDarwin / Darwin.swiftmodule)"
        return 0
    fi
    err=$(overlay_first_error "$log")
    OVERLAY_STATUS[$target]="FAILED first_error=$err"
    echo "OVERLAY $target FAILED first_error=$err (ninja graph does not depend on swiftDarwin)"
}

# Ninja's Linux rule writes .so; phase2 / stage_artifacts look for .dylib.
# overlay_copy_so_as_dylib <build_dir> <arch>
overlay_copy_so_as_dylib() {
    local build_dir=${1:?overlay_copy_so_as_dylib: build dir}
    local arch=${2:?overlay_copy_so_as_dylib: arch}
    local arch_dir=$build_dir/lib/swift/macosx/$arch
    local so dylib
    [ -d "$arch_dir" ] || return 0
    for so in "$arch_dir"/libswift*.so; do
        [ -e "$so" ] || continue
        dylib=${so%.so}.dylib
        if [ ! -e "$dylib" ] || [ "$so" -nt "$dylib" ]; then
            cp -f "$so" "$dylib"
        fi
    done
}

# Apple's libswiftDarwin LC_REEXPORT_DYLIB install names (exactly four).
overlay_darwin_reexport_install_names() {
    printf '%s\n' \
        /usr/lib/swift/libswift_Builtin_float.dylib \
        /usr/lib/swift/libswift_DarwinFoundation1.dylib \
        /usr/lib/swift/libswift_DarwinFoundation2.dylib \
        /usr/lib/swift/libswift_DarwinFoundation3.dylib
}

overlay_darwin_lc_reexport_names() {
    local dylib=$1
    local otool=${OTOOL:-llvm-otool-18}
    command -v "$otool" >/dev/null 2>&1 || otool=llvm-otool
    "$otool" -l "$dylib" 2>/dev/null \
        | awk '/LC_REEXPORT_DYLIB/{f=1} f&&/^ *name /{print $2; f=0}' \
        | sort -u
}

# After ninja Darwin + the four shells exist, relink libswiftDarwin so it
# carries Apple's four LC_REEXPORT_DYLIB entries. clangxx_darwin_link.py
# injects -reexport_library when those dylibs are on disk; this pass covers
# the case where ninja first linked Darwin as a Synchronization dep before
# Builtin_float landed.
# overlay_ensure_darwin_reexports <build_dir> <arch>
overlay_ensure_darwin_reexports() {
    local build_dir=${1:?overlay_ensure_darwin_reexports: build dir}
    local arch=${2:?overlay_ensure_darwin_reexports: arch}
    local py cmds_file darwin want have missing
    if [ "${SWIFTCORE_NINJA_HARNESS:-0}" = 1 ]; then
        echo "overlay_ensure_darwin_reexports: skip (SWIFTCORE_NINJA_HARNESS=1)"
        return 0
    fi
    darwin=$build_dir/lib/swift/macosx/$arch/libswiftDarwin.dylib
    [ -f "$darwin" ] || darwin=$build_dir/lib/swift/macosx/$arch/libswiftDarwin.so
    if [ ! -f "$darwin" ]; then
        echo "overlay_ensure_darwin_reexports: no libswiftDarwin (ninja Darwin did not land)"
        return 0
    fi
    want=$(overlay_darwin_reexport_install_names | sort -u)
    have=$(overlay_darwin_lc_reexport_names "$darwin")
    if [ "$(printf '%s\n' "$have")" = "$(printf '%s\n' "$want")" ]; then
        echo "overlay_ensure_darwin_reexports: $darwin already has four LC_REEXPORT_DYLIB"
        printf '%s\n' "$have" | sed 's/^/  reexport /'
        return 0
    fi
    py=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/clangxx_darwin_link.py
    cmds_file=$(mktemp)
    overlay_write_ninja_commands "$cmds_file" "$build_dir" \
        "lib/swift/macosx/${arch}/libswiftDarwin.so"
    if [ ! -s "$cmds_file" ]; then
        overlay_write_ninja_commands "$cmds_file" "$build_dir" \
            "swiftDarwin-macosx-${arch}"
    fi
    if [ ! -s "$cmds_file" ]; then
        echo "CANNOT_DARWIN_REEXPORT reason=no ninja Darwin link command to relink" >&2
        rm -f "$cmds_file"
        return 2
    fi
    echo "overlay_ensure_darwin_reexports: relink $darwin with -reexport_library of four shells"
    set +e
    python3 - "$py" "$cmds_file" <<'PY'
import os, pathlib, shlex, subprocess, sys

def compiler_args(line):
    argv = shlex.split(line)
    if not argv:
        return []
    if argv[0] == ":" and len(argv) > 2 and argv[1] == "&&":
        argv = argv[2:]
    while len(argv) >= 2 and argv[-2] == "&&" and argv[-1] == ":":
        argv = argv[:-2]
    i = 0
    for j, t in enumerate(argv):
        base = os.path.basename(t.rstrip("\\"))
        if base in ("clang++", "clang", "clangxx_darwin_link.py") or t.endswith("/clang++"):
            i = j
            break
    return argv[i + 1 :]

py, cmds_path = sys.argv[1], sys.argv[2]
text = pathlib.Path(cmds_path).read_text(errors="replace")
line = None
for raw in text.splitlines():
    if "libswiftDarwin.so" in raw and " -o " in raw and (
        "clang++" in raw or "clang " in raw or "clangxx_darwin_link" in raw
    ):
        line = raw
        break
if line is None:
    sys.stderr.write("CANNOT_DARWIN_REEXPORT reason=no clang++ Darwin link line\n")
    sys.exit(2)
args = compiler_args(line)
proc = subprocess.run([sys.executable, py, *args])
sys.exit(proc.returncode)
PY
    local st=$?
    set -e
    rm -f "$cmds_file"
    if [ "$st" -ne 0 ]; then
        echo "CANNOT_DARWIN_REEXPORT reason=relink rc=$st" >&2
        return "$st"
    fi
    overlay_copy_so_as_dylib "$build_dir" "$arch"
    overlay_flatten_unarch "$build_dir" "$arch"
    darwin=$build_dir/lib/swift/macosx/$arch/libswiftDarwin.dylib
    [ -f "$darwin" ] || darwin=$build_dir/lib/swift/macosx/$arch/libswiftDarwin.so
    have=$(overlay_darwin_lc_reexport_names "$darwin")
    missing=$(comm -23 <(printf '%s\n' "$want") <(printf '%s\n' "$have"))
    if [ -n "$missing" ]; then
        echo "CANNOT_DARWIN_REEXPORT missing=$(printf '%s' "$missing" | tr '\n' ',')" >&2
        echo "  have:" >&2
        printf '%s\n' "$have" | sed 's/^/    /' >&2
        return 2
    fi
    echo "overlay_ensure_darwin_reexports: four LC_REEXPORT_DYLIB on $darwin"
    printf '%s\n' "$have" | sed 's/^/  reexport /'
    return 0
}

# Compile the five non-ninja Apple-SDK overlays with the Darwin driver.
# overlay_build_xcode_shells <build_dir> <arch>
# Skipped in SWIFTCORE_NINJA_HARNESS (fake ninja / no Darwin resource-dir).
# Called *before* the Darwin ninja target so libswiftDarwin can re-export
# DarwinFoundation{1,2,3}. Builtin_float is a ninja target, built first.
overlay_build_xcode_shells() {
    local build_dir=${1:?overlay_build_xcode_shells: build dir}
    local arch=${2:?overlay_build_xcode_shells: arch}
    local script log line n st
    if [ "${SWIFTCORE_NINJA_HARNESS:-0}" = 1 ]; then
        echo "overlay_build_xcode_shells: skip (SWIFTCORE_NINJA_HARNESS=1)"
        return 0
    fi
    script=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/build_sdk_overlays.sh
    log=${W:-/tmp}/sdk-overlays.log
    echo "==== overlay_build_xcode_shells arch=$arch ===="
    set +e
    bash "$script" "$arch" "$build_dir" >"$log" 2>&1
    st=$?
    set -e
    cat "$log"
    while IFS= read -r line; do
        case "$line" in
            "sdk_overlay: STATUS "*" built")
                n=${line#sdk_overlay: STATUS }
                n=${n% built}
                OVERLAY_STATUS[$n]=built
                ;;
        esac
    done < "$log"
    if [ "$st" -ne 0 ]; then
        for n in \
            "swift_DarwinFoundation1-macosx-${arch}" \
            "swift_DarwinFoundation2-macosx-${arch}" \
            "swift_DarwinFoundation3-macosx-${arch}" \
            "swift_errno-macosx-${arch}" \
            "swiftObjectiveC-macosx-${arch}"
        do
            case "${OVERLAY_STATUS[$n]:-}" in
                built) ;;
                *)
                    OVERLAY_STATUS[$n]="FAILED first_error=$(overlay_first_error "$log")"
                    ;;
            esac
        done
        return "$st"
    fi
    overlay_flatten_unarch "$build_dir" "$arch"
    overlay_copy_so_as_dylib "$build_dir" "$arch"
    return 0
}
