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
# Named CANNOT, never ninja'd.

if [ -n "${SWIFTCORE_OVERLAY_TARGETS_INC:-}" ]; then
    return 0 2>/dev/null || exit 0
fi
SWIFTCORE_OVERLAY_TARGETS_INC=1

overlay_candidate_targets() {
    local arch=${1:?overlay_candidate_targets: arch}
    printf '%s\n' \
        "swift_Concurrency-macosx-${arch}" \
        "swiftSynchronization-macosx-${arch}" \
        "swift_StringProcessing-macosx-${arch}" \
        "swift_Builtin_float-macosx-${arch}" \
        "swift_RegexParser-macosx-${arch}" \
        "swiftObservation-macosx-${arch}" \
        "swiftDarwin-macosx-${arch}" \
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
            echo "CANNOT_STAGE_XCODE_DARWIN_OVERLAYS target=$n reason=not in ninja -t targets; Swift 6.2.4 Linux-host OSX stdlib does not add_subdirectory Apple SDK overlays (_DarwinFoundation1/2/3, _errno, ObjectiveC — stdlib/public/CMakeLists.txt:359 'picking them up from the SDK')"
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
    local ninja_bin=${NINJA:-ninja}
    local darwin_o="stdlib/public/Platform/OSX/${arch}/Darwin.o"
    local cmds="" node
    echo "overlay_sysroot: ninja -t commands for Darwin overlay compile (arch=$arch)"
    for node in "$darwin_o" "swiftDarwin-macosx-${arch}"; do
        cmds=$("$ninja_bin" -C "$build_dir" -t commands "$node" 2>/dev/null) || cmds=""
        if [ -n "$cmds" ]; then
            echo "overlay_sysroot: ninja -t commands node=$node"
            break
        fi
    done
    if [ -z "$cmds" ]; then
        echo "overlay_sysroot: ninja -t commands Darwin.o ABSENT (no -isysroot/-sdk in graph yet)"
        return 0
    fi
    python3 - "$cmds" <<'PY'
import sys
text = sys.argv[1]
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
# run. `-o …*.so` is ELF (keep -soname, linker=ld.lld) even under macosx/.
# overlay_print_darwin_link_from_ninja <build_dir> <arch>
overlay_print_darwin_link_from_ninja() {
    local build_dir=${1:?overlay_print_darwin_link_from_ninja: build dir}
    local arch=${2:?overlay_print_darwin_link_from_ninja: arch}
    local ninja_bin=${NINJA:-ninja}
    local py
    py=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/clangxx_darwin_link.py
    local node="lib/swift/macosx/${arch}/libswiftDarwin.so"
    local cmds=""
    echo "overlay_link: ninja -t commands for Darwin dylib (arch=$arch node=$node)"
    cmds=$("$ninja_bin" -C "$build_dir" -t commands "$node" 2>/dev/null) || cmds=""
    if [ -z "$cmds" ]; then
        cmds=$("$ninja_bin" -C "$build_dir" -t commands "swiftDarwin-macosx-${arch}" 2>/dev/null) || cmds=""
    fi
    if [ -z "$cmds" ]; then
        echo "overlay_link: ninja Darwin dylib command ABSENT"
        return 0
    fi
    python3 - "$py" "$cmds" <<'PY'
import os, shlex, subprocess, sys

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

py, text = sys.argv[1], sys.argv[2]
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
rewritten = (proc.stdout or "").strip()
err = (proc.stderr or "").strip()
if err:
    for eline in err.splitlines():
        print(eline)
print("overlay_link: rewritten", rewritten if rewritten else "ABSENT")
outp = ""
for i, a in enumerate(args):
    if a == "-o" and i + 1 < len(args):
        outp = args[i + 1]
        break
base = os.path.basename(outp)
decision = next((l for l in err.splitlines() if l.startswith("clangxx_darwin_link: -o ")), "")
if not decision:
    print("overlay_link: missing -o decision line")
    sys.exit(1)
if base.endswith(".so") or ".so." in base:
    if "decision=elf" not in decision or "linker=ld.lld" not in decision:
        print("overlay_link: .so output must be decision=elf linker=ld.lld")
        sys.exit(1)
    if "soname" not in rewritten:
        print("overlay_link: ELF rewritten dropped soname")
        sys.exit(1)
    if "ld64.lld" in rewritten:
        print("overlay_link: ELF .so routed to ld64.lld")
        sys.exit(1)
else:
    if "soname" in rewritten:
        print("overlay_link: rewritten still has soname")
        sys.exit(1)
    if rewritten and "-install_name" not in rewritten and "-Wl,-install_name" not in rewritten:
        print("overlay_link: rewritten missing -install_name")
        sys.exit(1)
PY
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
