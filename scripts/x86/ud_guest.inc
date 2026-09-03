# scripts/x86/ud_guest.inc -- phase2 item ud-guest-x86.
# Sourced from common.inc. Not executed.
#
# Produces x86_64 ud_guest through foundation-macho's committed pipeline:
#   objects in $W/scratch/ud-guest-x86_64/fe  (never scratch/ud-guest)
#   libCFTest.dylib + libswiftcompat.dylib in that tree's lib/
#   link via foundation-macho/scripts/link_ud_guest.sh  (no second linker)
#   binary at $W/scratch/ud-guest-x86_64/bin/ud_guest, handed to rung a as
#   UD_GUEST_BIN.
#
# FE objects are reused from build/full-x86_64/foundation (the same
# build_fe.sh / build_collections.sh / build_os_module.sh / build_cshims.sh
# argv phase2 already ran). This item does not invoke those scripts.
#
# Pipeline input differences vs foundation-macho #87 (see PHASE2.md):
#   * FE compile flags are identical (full/foundation/build_*.sh); only
#     TARGET/SYS/MC/OUT differ (x86 suffix vs historical arm64 scratch/fe4_*).
#   * removefile_compat.o is compiled by phase2 into essentials/ and is NOT
#     an input to link_ud_guest.sh (the #87 guest never linked it).
#   * uuid_compat.o is a build_full.sh input and is NOT on the #87 link line.
#   * fm_unimplemented.o is compiled once into essentials/ with build_full.sh's
#     clang argv, then staged; not recompiled with different flags.
#   * Port + runner compile argv matches build_ud_score_guest.sh (COMPILE_TRIPLE
#     macos15, -O -wmo, -I fe/{module,collections,os} + CFPreferencesMinimal).
#   * Link TRIPLE is macos13 (foundation-macho/scripts/guest_arch.inc).
#   * SDK is scratch/sysroot_fe4-x86_64, exposed as $ud_w/fe/sysroot because
#     link_ud_guest.sh defaults SDK=$W/fe/sysroot.

if [ -n "${PHASE2_UD_GUEST_INC:-}" ]; then
    return 0 2>/dev/null || exit 0
fi
PHASE2_UD_GUEST_INC=1

PHASE2_UD_GUEST_LINKER=foundation-macho/scripts/link_ud_guest.sh
PHASE2_UD_GUEST_EXPECTED_LOADS=(
    libswiftCore
    libswiftDarwin
    libswift_StringProcessing
    libswiftSynchronization
    libswift_errno
    libobjc
    libSystem
    libCFTest
    libswiftcompat
)

phase2_ud_guest_worktree() {
    local tree=$1
    printf '%s/scratch/ud-guest-x86_64\n' "$tree"
}

phase2_ud_guest_refuse_unsuffixed() {
    local dest=$1
    case "$dest" in
        */scratch/ud-guest-x86_64)
            return 0
            ;;
        *)
            printf 'CANNOT_UD_GUEST_WORKTREE file=%s reason=refusing unsuffixed/arm64 ud-guest work tree\n' \
                "$dest"
            return 1
            ;;
    esac
}

# One line: CANNOT_UD_GUEST_<MARKER> file=<basename> <rest>
phase2_ud_guest_cannot() {
    local marker=$1 file=$2
    shift 2
    printf 'CANNOT_UD_GUEST_%s file=%s %s\n' "$marker" "$file" "$*"
}

phase2_ud_guest_stage_file() {
    # stage_file <src> <dest> <file> <MARKER> [macho]
    # macho=1 (default) requires X86_64 Mach-O; macho=0 for swiftmodules.
    local src=$1 dest=$2 file=$3 marker=$4 macho=${5:-1}
    if [ ! -f "$src" ]; then
        phase2_ud_guest_cannot "$marker" "$file" "missing at $src"
        return 1
    fi
    if [ "$macho" = 1 ] && ! phase2_is_x86_macho "$src"; then
        phase2_ud_guest_cannot "$marker" "$file" "not X86_64 Mach-O: $src"
        return 1
    fi
    mkdir -p "$(dirname "$dest")"
    ln -f "$src" "$dest" 2>/dev/null || cp -a "$src" "$dest"
}

# Map build/full-x86_64/foundation -> $ud_w/fe as stage_fe_guest.sh does for
# the #87 tree. Hardlink when possible; never rebuild FE.
phase2_ud_guest_stage_fe() {
    local fe_out=$1 ud_w=$2
    local report

    phase2_ud_guest_refuse_unsuffixed "$ud_w" || return 1
    mkdir -p "$ud_w/fe/module" "$ud_w/fe/collections" "$ud_w/fe/os" "$ud_w/fe/cshims"

    phase2_ud_guest_stage_file \
        "$fe_out/essentials/FoundationEssentials.o" \
        "$ud_w/fe/module/FoundationEssentials.o" \
        FoundationEssentials.o FOUNDATIONESSENTIALS || return 1
    phase2_ud_guest_stage_file \
        "$fe_out/essentials/FoundationEssentials.swiftmodule" \
        "$ud_w/fe/module/FoundationEssentials.swiftmodule" \
        FoundationEssentials.swiftmodule FOUNDATIONESSENTIALS 0 || return 1
    if [ -f "$fe_out/essentials/FoundationEssentials.swiftdoc" ]; then
        phase2_ud_guest_stage_file \
            "$fe_out/essentials/FoundationEssentials.swiftdoc" \
            "$ud_w/fe/module/FoundationEssentials.swiftdoc" \
            FoundationEssentials.swiftdoc FOUNDATIONESSENTIALS 0 || true
    fi

    phase2_ud_guest_stage_file \
        "$fe_out/collections/OrderedCollections.o" \
        "$ud_w/fe/collections/OrderedCollections.o" \
        OrderedCollections.o ORDEREDCOLLECTIONS || return 1
    phase2_ud_guest_stage_file \
        "$fe_out/collections/OrderedCollections.swiftmodule" \
        "$ud_w/fe/collections/OrderedCollections.swiftmodule" \
        OrderedCollections.swiftmodule ORDEREDCOLLECTIONS 0 || return 1
    phase2_ud_guest_stage_file \
        "$fe_out/collections/InternalCollectionsUtilities.o" \
        "$ud_w/fe/collections/InternalCollectionsUtilities.o" \
        InternalCollectionsUtilities.o INTERNALCOLLECTIONSUTILITIES || return 1
    phase2_ud_guest_stage_file \
        "$fe_out/collections/InternalCollectionsUtilities.swiftmodule" \
        "$ud_w/fe/collections/InternalCollectionsUtilities.swiftmodule" \
        InternalCollectionsUtilities.swiftmodule INTERNALCOLLECTIONSUTILITIES 0 || return 1
    phase2_ud_guest_stage_file \
        "$fe_out/collections/_RopeModule.o" \
        "$ud_w/fe/collections/_RopeModule.o" \
        _RopeModule.o ROPEMODULE || return 1
    phase2_ud_guest_stage_file \
        "$fe_out/collections/_RopeModule.swiftmodule" \
        "$ud_w/fe/collections/_RopeModule.swiftmodule" \
        _RopeModule.swiftmodule ROPEMODULE 0 || return 1
    # link_ud_guest.sh also looks at $W/fe/_RopeModule.o (optional duplicate).
    phase2_ud_guest_stage_file \
        "$fe_out/collections/_RopeModule.o" \
        "$ud_w/fe/_RopeModule.o" \
        _RopeModule.o ROPEMODULE || return 1

    phase2_ud_guest_stage_file \
        "$fe_out/os/os.o" "$ud_w/fe/os/os.o" os.o OS || return 1
    if [ -f "$fe_out/os/os.swiftmodule" ]; then
        phase2_ud_guest_stage_file \
            "$fe_out/os/os.swiftmodule" "$ud_w/fe/os/os.swiftmodule" \
            os.swiftmodule OS 0 || return 1
    fi

    phase2_ud_guest_stage_file \
        "$fe_out/cshims/platform_shims.o" \
        "$ud_w/fe/cshims/platform_shims.o" \
        platform_shims.o PLATFORM_SHIMS || return 1
    phase2_ud_guest_stage_file \
        "$fe_out/cshims/string_shims.o" \
        "$ud_w/fe/cshims/string_shims.o" \
        string_shims.o STRING_SHIMS || return 1
    phase2_ud_guest_stage_file \
        "$fe_out/cshims/uuid.o" \
        "$ud_w/fe/cshims/uuid.o" \
        uuid.o UUID || return 1

    printf 'OK fe-staged dest=%s\n' "$ud_w/fe"
}

# Same clang argv as full/scripts/build_full.sh for fm_unimplemented.c.
phase2_ud_guest_compile_fm_unimplemented() {
    local sys=$1 dest=$2 target=$3 src_tree=$4
    mkdir -p "$(dirname "$dest")"
    clang-18 -target "$target" -isysroot "$sys" -O1 -nostdinc \
        -DOPEN_FOUNDATION_UUID_COMPAT=1 \
        -c "$src_tree/full/foundation/fm_unimplemented.c" \
        -o "$dest"
}

phase2_ud_guest_ensure_fm_unimplemented() {
    local fe_out=$1 sys=$2 target=$3 src_tree=$4 ud_w=$5
    local src=$fe_out/essentials/fm_unimplemented.o
    if [ -f "$src" ] && phase2_is_x86_macho "$src"; then
        :
    else
        local st
        set +e
        phase2_ud_guest_compile_fm_unimplemented "$sys" "$src" "$target" "$src_tree"
        st=$?
        set -e
        if [ "$st" -ne 0 ]; then
            phase2_ud_guest_cannot FM_UNIMPLEMENTED fm_unimplemented.o \
                "clang exit $st (build_full.sh argv -O1 -nostdinc -DOPEN_FOUNDATION_UUID_COMPAT=1)"
            return 1
        fi
        if [ ! -f "$src" ] || ! phase2_is_x86_macho "$src"; then
            phase2_ud_guest_cannot FM_UNIMPLEMENTED fm_unimplemented.o \
                "not X86_64 Mach-O after compile: $src"
            return 1
        fi
    fi
    phase2_ud_guest_stage_file \
        "$src" "$ud_w/fe/fm_unimplemented.o" \
        fm_unimplemented.o FM_UNIMPLEMENTED
}

phase2_ud_guest_point_sysroot() {
    local sys=$1 ud_w=$2
    if [ ! -d "$sys/usr/lib" ]; then
        phase2_ud_guest_cannot SYSROOT sysroot "missing x86 FE sysroot at $sys"
        return 1
    fi
    mkdir -p "$ud_w/fe"
    rm -f "$ud_w/fe/sysroot"
    ln -sfn "$sys" "$ud_w/fe/sysroot"
}

# Port compile: same shape as foundation-macho/scripts/build_ud_score_guest.sh
# (COMPILE_TRIPLE, -O -wmo, CFPreferencesMinimal -I) plus the CShims clang
# module map every FoundationEssentials consumer uses (build_url_runner.sh,
# build_fe_host.sh). Collections modules are on argv twice: the staged
# $ud_w/fe/collections tree (link_ud_guest.sh layout) and the authoritative
# build/full-x86_64/foundation/collections output phase2 already built
# (build_url_runner.sh / PR #28 FI search-path class). Without those -I
# paths, swiftc reports missing required modules OrderedCollections and
# _RopeModule.
phase2_ud_guest_compile_port() {
    local ud_w=$1 repo=$2 sdk=$3 compile_triple=$4 mc=$5
    local fe_out=${6:-}
    local src_ud=$repo/foundation-macho/src/overlay/UserDefaults.swift
    local src_bridge=$repo/foundation-macho/src/overlay/UserDefaultsBridge_Guest.swift
    local out=$ud_w/fe/UserDefaultsGuest.o
    local log=$ud_w/fe/UserDefaultsGuest.swiftc.log
    local st cshims
    local -a cshims_args=() collections_i=()
    if [ ! -f "$src_ud" ] || [ ! -f "$src_bridge" ]; then
        phase2_ud_guest_cannot USERDEFAULTSGUEST UserDefaultsGuest.o \
            "missing overlay sources under foundation-macho/src/overlay"
        return 1
    fi
    mkdir -p "$ud_w/fe" "$mc"
    phase2_ensure_sdk_settings "$sdk"
    cshims=$repo/scratch/swift-foundation/Sources/_FoundationCShims/include
    if [ -f "$cshims/module.modulemap" ]; then
        cshims_args=(-Xcc -fmodule-map-file="$cshims/module.modulemap" -Xcc -I"$cshims")
    fi
    if [ -n "$fe_out" ] && [ -d "$fe_out/collections" ]; then
        collections_i=(-I "$fe_out/collections")
    fi
    set +e
    swiftc -c -O -wmo -parse-as-library \
        -module-name PortedUserDefaultsGuest \
        -emit-module -emit-module-path "$ud_w/fe/PortedUserDefaultsGuest.swiftmodule" \
        -target "$compile_triple" -sdk "$sdk" \
        -runtime-compatibility-version none \
        -module-cache-path "$mc" \
        -I "$ud_w/fe/module" -I "$ud_w/fe" -I "$ud_w/fe/collections" -I "$ud_w/fe/os" \
        "${collections_i[@]}" \
        -I "$repo/foundation-macho/include/CFPreferencesMinimal" \
        "${cshims_args[@]}" \
        "$src_ud" "$src_bridge" \
        -o "$out" >"$log" 2>&1
    st=$?
    set -e
    if [ "$st" -ne 0 ] || [ ! -f "$out" ] || ! phase2_is_x86_macho "$out"; then
        phase2_ud_guest_cannot USERDEFAULTSGUEST UserDefaultsGuest.o \
            "swiftc exit $st log=$log"
        return 1
    fi
}

# Smoke runner: top-level code must be named main.swift (same as the
# scoreboard recipe in build_ud_score_guest.sh).
phase2_ud_guest_compile_runner() {
    local ud_w=$1 repo=$2 sdk=$3 compile_triple=$4 mc=$5
    local fe_out=${6:-}
    local src=$repo/foundation-macho/tests/ud_guest_runner.swift
    local builddir=$ud_w/fe/runner-src
    local out=$ud_w/fe/runner.o
    local log=$ud_w/fe/runner.swiftc.log
    local st cshims
    local -a cshims_args=() collections_i=()
    if [ ! -f "$src" ]; then
        phase2_ud_guest_cannot RUNNER runner.o \
            "missing foundation-macho/tests/ud_guest_runner.swift"
        return 1
    fi
    rm -rf "$builddir"
    mkdir -p "$builddir" "$mc"
    phase2_ensure_sdk_settings "$sdk"
    cp "$src" "$builddir/main.swift"
    cshims=$repo/scratch/swift-foundation/Sources/_FoundationCShims/include
    if [ -f "$cshims/module.modulemap" ]; then
        cshims_args=(-Xcc -fmodule-map-file="$cshims/module.modulemap" -Xcc -I"$cshims")
    fi
    if [ -n "$fe_out" ] && [ -d "$fe_out/collections" ]; then
        collections_i=(-I "$fe_out/collections")
    fi
    set +e
    swiftc -c -O -wmo \
        -module-name ud_guest \
        -target "$compile_triple" -sdk "$sdk" \
        -runtime-compatibility-version none \
        -module-cache-path "$mc" \
        -I "$ud_w/fe/module" -I "$ud_w/fe" -I "$ud_w/fe/collections" -I "$ud_w/fe/os" \
        "${collections_i[@]}" \
        -I "$repo/foundation-macho/include/CFPreferencesMinimal" \
        "${cshims_args[@]}" \
        "$builddir/main.swift" \
        -o "$out" >"$log" 2>&1
    st=$?
    set -e
    if [ "$st" -ne 0 ] || [ ! -f "$out" ] || ! phase2_is_x86_macho "$out"; then
        phase2_ud_guest_cannot RUNNER runner.o "swiftc exit $st log=$log"
        return 1
    fi
}

phase2_ud_guest_find_x86_dylib() {
    local name=$1
    shift
    local c
    for c in "$@"; do
        [ -n "$c" ] || continue
        [ -f "$c" ] || continue
        phase2_is_x86_macho "$c" || continue
        printf '%s\n' "$c"
        return 0
    done
    return 1
}

phase2_ud_guest_ensure_swiftcompat() {
    local repo=$1 sys=$2 ud_w=$3 mrlib=$4 loader=$5
    local dest=$ud_w/lib/libswiftcompat.dylib
    local found src_dir
    mkdir -p "$ud_w/lib"
    found=$(phase2_ud_guest_find_x86_dylib libswiftcompat.dylib \
        "${UD_SWIFTCOMPAT_DYLIB:-}" \
        "$dest" \
        "$mrlib/libswiftcompat.dylib" \
        "$repo/scratch/mrroot-x86_64/darwin/usr/lib/libswiftcompat.dylib" \
        || true)
    if [ -n "$found" ]; then
        [ "$found" = "$dest" ] || cp -a "$found" "$dest"
        return 0
    fi
    src_dir=$repo/swiftcore-macho/sdk/compat
    if [ ! -f "$src_dir/swiftcompat.c" ] || [ ! -f "$src_dir/shim.cpp" ]; then
        phase2_ud_guest_cannot LIBSWIFTCOMPAT libswiftcompat.dylib \
            "no x86_64 Mach-O and swiftcore-macho/sdk/compat sources missing"
        return 1
    fi
    # Committed recipe: swiftcore-macho/scripts/build_compat.sh. Alias SDK
    # supplies libSystem.tbd / libc++.tbd names the link line uses; never copy
    # artifacts/libswiftcompat.dylib (arm64).
    local log st alias
    log=$ud_w/lib/build_compat.log
    alias=$ud_w/lib/compat-sdk
    mkdir -p "$ud_w/lib"
    phase2_prepare_compat_alias_sdk "$sys" "$alias"
    set +e
    W="$ud_w" \
        SDK="$alias" \
        SRC="$src_dir" \
        MRLIB="$mrlib" \
        LOADER="$loader" \
        OUT="$dest" \
        NM=llvm-nm-18 \
        bash "$repo/swiftcore-macho/scripts/build_compat.sh" >"$log" 2>&1
    st=$?
    set -e
    if [ "$st" -ne 0 ] || [ ! -f "$dest" ] || ! phase2_is_x86_macho "$dest"; then
        phase2_ud_guest_cannot LIBSWIFTCOMPAT libswiftcompat.dylib \
            "build_compat.sh exit $st (committed swiftcore-macho recipe; artifacts/libswiftcompat.dylib is arm64) $(phase2_flatten < "$log")"
        rm -f "$log"
        return 1
    fi
    rm -f "$log"
}

phase2_ud_guest_ensure_cftest() {
    local ud_w=$1 repo=$2
    local dest=$ud_w/lib/libCFTest.dylib
    local found
    mkdir -p "$ud_w/lib"
    found=$(phase2_ud_guest_find_x86_dylib libCFTest.dylib \
        "${UD_CFTEST_DYLIB:-}" \
        "$dest" \
        "$repo/scratch/ud-guest-x86_64/lib/libCFTest.dylib" \
        || true)
    if [ -n "$found" ]; then
        [ "$found" = "$dest" ] || cp -a "$found" "$dest"
        return 0
    fi
    # /work/cfobjc has no committed compile recipe (docs/CF_PREFERENCES_EXECUTION.md).
    # build_cftest_harness.sh only relinks objects that already exist. Do not
    # invent a second CF compiler or a stub dylib.
    phase2_ud_guest_cannot LIBCFTEST libCFTest.dylib \
        "no x86_64 Mach-O. Committed CF linker is foundation-macho/scripts/build_cftest_harness.sh; cfobjc objects have no committed recipe (shell-history only). Will not invent a CF compiler or a stub. Operator: provide UD_CFTEST_DYLIB=x86_64 libCFTest.dylib."
    return 1
}

phase2_ud_guest_link() {
    local repo=$1 ud_w=$2 sys=$3 out=$4
    local linker=$repo/$PHASE2_UD_GUEST_LINKER
    local log=$ud_w/bin/ud_guest.link.log
    local st
    if [ ! -f "$linker" ]; then
        phase2_ud_guest_cannot UD_GUEST ud_guest "missing committed linker $linker"
        return 1
    fi
    mkdir -p "$(dirname "$out")"
    set +e
    W="$ud_w" SDK="$sys" OUT="$out" LLD_BIN=/usr/lib/llvm-18/bin \
        bash "$linker" >"$log" 2>&1
    st=$?
    set -e
    if [ "$st" -ne 0 ] || [ ! -f "$out" ]; then
        phase2_ud_guest_cannot UD_GUEST ud_guest \
            "link_ud_guest.sh exit $st $(phase2_flatten < "$log")"
        return 1
    fi
    if ! phase2_is_x86_macho "$out"; then
        phase2_ud_guest_cannot UD_GUEST ud_guest "linked file is not X86_64 Mach-O: $out"
        return 1
    fi
}

phase2_ud_guest_write_otool_evidence() {
    local bin=$1 evid=$2
    {
        echo "== llvm-otool-18 -hv"
        llvm-otool-18 -hv "$bin"
        echo
        echo "== llvm-otool-18 -L"
        llvm-otool-18 -L "$bin"
    } >"$evid"
}

phase2_ud_guest_check_loads() {
    local evid=$1
    local name
    for name in "${PHASE2_UD_GUEST_EXPECTED_LOADS[@]}"; do
        if ! grep -q "$name" "$evid"; then
            phase2_ud_guest_cannot UD_GUEST ud_guest \
                "otool -L missing expected load $name (evidence $evid)"
            return 1
        fi
    done
    if ! grep -q 'MH_MAGIC_64[[:space:]]\+X86_64' "$evid"; then
        phase2_ud_guest_cannot UD_GUEST ud_guest \
            "otool -hv missing MH_MAGIC_64 X86_64 (evidence $evid)"
        return 1
    fi
    return 0
}

# Main producer. Prints one line:
#   OK bin=... evid=...
#   CANNOT_UD_GUEST_<MARKER> file=... ...
phase2_try_ud_guest() {
    local repo=$1
    local fe_out=$2
    local sys=$3
    local target=$4
    local mc=$5
    local mrlib=$6
    local loader=$7
    local ud_w out evid report
    local compile_triple

    ud_w=$(phase2_ud_guest_worktree "$repo")
    report=$(phase2_ud_guest_refuse_unsuffixed "$ud_w" || true)
    case "$report" in
        CANNOT_*) printf '%s\n' "$report"; return 1 ;;
    esac
    # foundation-macho guest_arch: compile macos15, link macos13. Source in a
    # subshell so TRIPLE/ARCH do not clobber full/scripts/guest_arch.inc.
    compile_triple=$(
        # shellcheck disable=SC1091
        . "$repo/foundation-macho/scripts/guest_arch.inc"
        printf '%s\n' "${COMPILE_TRIPLE:-$target}"
    )

    mkdir -p "$ud_w/fe" "$ud_w/lib" "$ud_w/bin"

    report=$(phase2_ud_guest_point_sysroot "$sys" "$ud_w" || true)
    case "$report" in CANNOT_*) printf '%s\n' "$report"; return 1 ;; esac

    report=$(phase2_ud_guest_stage_fe "$fe_out" "$ud_w" || true)
    case "$report" in CANNOT_*) printf '%s\n' "$report"; return 1 ;; esac

    report=$(phase2_ud_guest_ensure_fm_unimplemented \
        "$fe_out" "$sys" "$target" "$repo" "$ud_w" || true)
    case "$report" in CANNOT_*) printf '%s\n' "$report"; return 1 ;; esac

    if ! phase2_ud_guest_compile_port "$ud_w" "$repo" "$sys" "$compile_triple" "$mc" "$fe_out"; then
        return 1
    fi
    if ! phase2_ud_guest_compile_runner "$ud_w" "$repo" "$sys" "$compile_triple" "$mc" "$fe_out"; then
        return 1
    fi

    report=$(phase2_ud_guest_ensure_swiftcompat "$repo" "$sys" "$ud_w" "$mrlib" "$loader" || true)
    case "$report" in CANNOT_*) printf '%s\n' "$report"; return 1 ;; esac

    report=$(phase2_ud_guest_ensure_cftest "$ud_w" "$repo" || true)
    case "$report" in CANNOT_*) printf '%s\n' "$report"; return 1 ;; esac

    out=$ud_w/bin/ud_guest
    if ! phase2_ud_guest_link "$repo" "$ud_w" "$sys" "$out"; then
        return 1
    fi
    evid=$ud_w/bin/ud_guest.otool.txt
    phase2_ud_guest_write_otool_evidence "$out" "$evid"
    if ! phase2_ud_guest_check_loads "$evid"; then
        return 1
    fi
    printf 'OK bin=%s evid=%s linker=%s\n' "$out" "$evid" "$PHASE2_UD_GUEST_LINKER"
}
