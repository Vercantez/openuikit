# scripts/x86/ud_guest.inc -- phase2 item ud-guest-x86.
# Sourced from common.inc. Not executed.
#
# Produces x86_64 ud_guest through foundation-macho's committed pipeline:
#   objects in $W/scratch/ud-guest-x86_64/fe  (never scratch/ud-guest)
#   libCFTest.dylib from build_cfobjc.sh + build_cftest_harness.sh
#     (never a stub dylib; link_ud_guest.sh stays the only ud_guest linker)
#     ICU headers are required (swift-foundation-icu pin). Without them
#     CFString.c does not compile and the harness would stub
#     CFStringCreateWithBytes. The derived stub set is compared to
#     foundation-macho/docs/cf-census/cftest-stub-{func-active,data}.txt;
#     a mismatch is CANNOT_CFTEST_STUBS (own ENV_PREPARE line) and does
#     not proceed to link_ud_guest.sh.
#   after link, before run: stage that dylib into
#     scratch/mrroot_full-x86_64/darwin/usr/lib/libCFTest.dylib
#     (arm64 analogue: build_cftest_harness.sh -> $W/root; not build_full.sh)
#   libswiftcompat.dylib in that tree's lib/
#   Linux Dispatch host bridge + Darwin libOpenDispatch.dylib (Reminder/Focus
#     mechanism) via phase2_ud_guest_ensure_dispatch; rung a LD_PRELOADs the
#     bridge against a run-local overlay that contains the Darwin image
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
# Census comparison pin (PR #50 arm64 rebuild). Tagged swift-6.2.4-RELEASE.
# Clone the full git tree so HEAD^{tree} matches env/contract.json; the recipe
# compiles only Sources/CoreFoundation.
PHASE2_UD_GUEST_CF_ID=swift-corelibs-foundation
PHASE2_UD_GUEST_CF_REPO=https://github.com/swiftlang/swift-corelibs-foundation.git
PHASE2_UD_GUEST_CF_COMMIT=f3a7a34302317a95665bf4ff1a62ee1b459c1695
PHASE2_UD_GUEST_CF_TREE=2f9136f253a51406f2bcb0a612bcb6a9eba03570
PHASE2_UD_GUEST_CF_DEST_REL=scratch/ud-guest-x86_64/cf
PHASE2_UD_GUEST_CF_SOURCES_REL=Sources/CoreFoundation
# ICU headers CFString.c / CFCalendar.c / CFLocale.c include. Same pin as
# env/contract.json swift-foundation-icu. Destination is the repo-level
# scratch tree other guests already use, not under ud-guest-x86_64.
PHASE2_UD_GUEST_ICU_ID=swift-foundation-icu
PHASE2_UD_GUEST_ICU_REPO=https://github.com/apple/swift-foundation-icu.git
PHASE2_UD_GUEST_ICU_COMMIT=87dbab99780e277b6a4c2a397ab1a894f877b39a
PHASE2_UD_GUEST_ICU_TREE=823a4a2a13f60a0fd2715db85a754dda11d5fd39
PHASE2_UD_GUEST_ICU_DEST_REL=scratch/swift-foundation-icu
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
    # Fallback path for link_ud_guest.sh when collections/ is absent.
    # The linker takes collections/_RopeModule.o XOR this file, never both.
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

# Pin from env/contract.json. dest is the full git checkout; CF TUs are under
# Sources/CoreFoundation. An existing dest whose HEAD^{tree} differs is a
# refusal that names the commit — not a silent restage.
phase2_ud_guest_ensure_cf_checkout() {
    local ud_w=$1 repo=$2
    local dest=$ud_w/cf
    local commit=$PHASE2_UD_GUEST_CF_COMMIT
    local tree=$PHASE2_UD_GUEST_CF_TREE
    local origin=$PHASE2_UD_GUEST_CF_REPO
    local cloner=$repo/.cursor/clone-pinned-repo.sh
    local live_commit live_tree tree_root lock_dir lock log st
    local sources=$dest/$PHASE2_UD_GUEST_CF_SOURCES_REL

    if [ -e "$dest" ]; then
        if [ -d "$dest/.git" ]; then
            live_commit=$(git -c "safe.directory=$dest" -C "$dest" rev-parse HEAD 2>/dev/null || true)
            live_tree=$(git -c "safe.directory=$dest" -C "$dest" rev-parse 'HEAD^{tree}' 2>/dev/null || true)
            if [ "$live_commit" = "$commit" ] && [ "$live_tree" = "$tree" ]; then
                if [ -f "$sources/CFRuntime.c" ] && [ -f "$sources/CFPreferences.c" ]; then
                    return 0
                fi
                phase2_ud_guest_cannot LIBCFTEST libCFTest.dylib \
                    "no x86_64 Mach-O. pinned CF checkout $commit at $dest is missing $PHASE2_UD_GUEST_CF_SOURCES_REL (recipe compiles only that directory). Will not invent a stub dylib."
                return 1
            fi
            # Existing dest with a different tree is a refusal that names the
            # pin. clone-pinned-repo.sh would replace it; we must not.
            phase2_ud_guest_cannot LIBCFTEST libCFTest.dylib \
                "no x86_64 Mach-O. CF checkout tree differs at $dest live_commit=${live_commit:-unreadable} want=$commit live_tree=${live_tree:-unreadable} want=$tree (env/contract.json $PHASE2_UD_GUEST_CF_ID). Will not invent a stub dylib."
            return 1
        fi
        if [ -d "$dest" ] && [ -z "$(ls -A "$dest" 2>/dev/null || true)" ]; then
            rmdir "$dest" || {
                phase2_ud_guest_cannot LIBCFTEST libCFTest.dylib \
                    "no x86_64 Mach-O. empty $dest could not be cleared to fetch $commit (env/contract.json $PHASE2_UD_GUEST_CF_ID). Will not invent a stub dylib."
                return 1
            }
        else
            phase2_ud_guest_cannot LIBCFTEST libCFTest.dylib \
                "no x86_64 Mach-O. $dest exists and is not a git checkout of $commit (env/contract.json $PHASE2_UD_GUEST_CF_ID). Will not invent a stub dylib."
            return 1
        fi
    fi

    if [ ! -f "$cloner" ]; then
        phase2_ud_guest_cannot LIBCFTEST libCFTest.dylib \
            "no x86_64 Mach-O. missing $cloner; cannot fetch $PHASE2_UD_GUEST_CF_ID commit=$commit. Will not invent a stub dylib."
        return 1
    fi
    tree_root=$(CDPATH= cd -- "$ud_w/../.." && pwd)
    lock_dir=$(mktemp -d "$ud_w/.cf-pin-lock.XXXXXX")
    lock=$lock_dir/lock.json
    printf '%s\n' "{
  \"sources\": [{
    \"id\": \"$PHASE2_UD_GUEST_CF_ID\",
    \"repository\": \"$origin\",
    \"commit\": \"$commit\",
    \"tree\": \"$tree\",
    \"destination\": \"$PHASE2_UD_GUEST_CF_DEST_REL\"
  }]
}" >"$lock"
    log=$ud_w/lib/cf-checkout.log
    mkdir -p "$ud_w/lib"
    set +e
    bash "$cloner" --lock "$lock" --id "$PHASE2_UD_GUEST_CF_ID" --repo-root "$tree_root" \
        >"$log" 2>&1
    st=$?
    set -e
    rm -rf "$lock_dir"
    if [ "$st" -ne 0 ] || [ ! -d "$dest/.git" ]; then
        phase2_ud_guest_cannot LIBCFTEST libCFTest.dylib \
            "no x86_64 Mach-O. failed to fetch $PHASE2_UD_GUEST_CF_ID commit=$commit tree=$tree dest=$PHASE2_UD_GUEST_CF_DEST_REL log=$log. Will not invent a stub dylib."
        return 1
    fi
    live_commit=$(git -c "safe.directory=$dest" -C "$dest" rev-parse HEAD)
    live_tree=$(git -c "safe.directory=$dest" -C "$dest" rev-parse 'HEAD^{tree}')
    if [ "$live_commit" != "$commit" ] || [ "$live_tree" != "$tree" ]; then
        phase2_ud_guest_cannot LIBCFTEST libCFTest.dylib \
            "no x86_64 Mach-O. CF checkout tree differs at $dest live_commit=$live_commit want=$commit live_tree=$live_tree want=$tree (env/contract.json $PHASE2_UD_GUEST_CF_ID). Will not invent a stub dylib."
        return 1
    fi
    if [ ! -f "$sources/CFRuntime.c" ] || [ ! -f "$sources/CFPreferences.c" ]; then
        phase2_ud_guest_cannot LIBCFTEST libCFTest.dylib \
            "no x86_64 Mach-O. pinned CF checkout $commit at $dest is missing $PHASE2_UD_GUEST_CF_SOURCES_REL. Will not invent a stub dylib."
        return 1
    fi
    return 0
}

phase2_ud_guest_find_icu() {
    local repo=$1
    local c
    for c in \
        "${ICU_INC:-}" \
        "$repo/scratch/swift-foundation-icu/icuSources/include" \
        "$HOME/swift-foundation-icu/icuSources/include"
    do
        [ -n "$c" ] || continue
        [ -d "$c" ] || continue
        printf '%s\n' "$c"
        return 0
    done
    return 1
}

# Pin from env/contract.json. dest is scratch/swift-foundation-icu at the
# repo root (other guests share it). Wrong-tree dest is a named refusal.
phase2_ud_guest_ensure_icu_checkout() {
    local repo=$1
    local dest=$repo/$PHASE2_UD_GUEST_ICU_DEST_REL
    local commit=$PHASE2_UD_GUEST_ICU_COMMIT
    local tree=$PHASE2_UD_GUEST_ICU_TREE
    local origin=$PHASE2_UD_GUEST_ICU_REPO
    local cloner=$repo/.cursor/clone-pinned-repo.sh
    local live_commit live_tree lock_dir lock log st include

    include=$dest/icuSources/include
    if [ -e "$dest" ]; then
        if [ -d "$dest/.git" ]; then
            live_commit=$(git -c "safe.directory=$dest" -C "$dest" rev-parse HEAD 2>/dev/null || true)
            live_tree=$(git -c "safe.directory=$dest" -C "$dest" rev-parse 'HEAD^{tree}' 2>/dev/null || true)
            if [ "$live_commit" = "$commit" ] && [ "$live_tree" = "$tree" ]; then
                if [ -d "$include/_foundation_unicode" ]; then
                    return 0
                fi
                phase2_ud_guest_cannot LIBCFTEST libCFTest.dylib \
                    "no x86_64 Mach-O. pinned ICU checkout $commit at $dest is missing icuSources/include/_foundation_unicode (CFString.c includes it). Will not invent a stub dylib."
                return 1
            fi
            phase2_ud_guest_cannot LIBCFTEST libCFTest.dylib \
                "no x86_64 Mach-O. ICU checkout tree differs at $dest live_commit=${live_commit:-unreadable} want=$commit live_tree=${live_tree:-unreadable} want=$tree (env/contract.json $PHASE2_UD_GUEST_ICU_ID). Will not invent a stub dylib."
            return 1
        fi
        if [ -d "$dest" ] && [ -z "$(ls -A "$dest" 2>/dev/null || true)" ]; then
            rmdir "$dest" || {
                phase2_ud_guest_cannot LIBCFTEST libCFTest.dylib \
                    "no x86_64 Mach-O. empty $dest could not be cleared to fetch $commit (env/contract.json $PHASE2_UD_GUEST_ICU_ID). Will not invent a stub dylib."
                return 1
            }
        else
            phase2_ud_guest_cannot LIBCFTEST libCFTest.dylib \
                "no x86_64 Mach-O. $dest exists and is not a git checkout of $commit (env/contract.json $PHASE2_UD_GUEST_ICU_ID). Will not invent a stub dylib."
            return 1
        fi
    fi

    if [ ! -f "$cloner" ]; then
        phase2_ud_guest_cannot LIBCFTEST libCFTest.dylib \
            "no x86_64 Mach-O. missing $cloner; cannot fetch $PHASE2_UD_GUEST_ICU_ID commit=$commit. Will not invent a stub dylib."
        return 1
    fi
    lock_dir=$(mktemp -d "$repo/scratch/.icu-pin-lock.XXXXXX")
    lock=$lock_dir/lock.json
    printf '%s\n' "{
  \"sources\": [{
    \"id\": \"$PHASE2_UD_GUEST_ICU_ID\",
    \"repository\": \"$origin\",
    \"commit\": \"$commit\",
    \"tree\": \"$tree\",
    \"destination\": \"$PHASE2_UD_GUEST_ICU_DEST_REL\"
  }]
}" >"$lock"
    log=$repo/scratch/ud-guest-x86_64/lib/icu-checkout.log
    mkdir -p "$(dirname "$log")"
    set +e
    bash "$cloner" --lock "$lock" --id "$PHASE2_UD_GUEST_ICU_ID" --repo-root "$repo" \
        >"$log" 2>&1
    st=$?
    set -e
    rm -rf "$lock_dir"
    if [ "$st" -ne 0 ] || [ ! -d "$dest/.git" ]; then
        phase2_ud_guest_cannot LIBCFTEST libCFTest.dylib \
            "no x86_64 Mach-O. failed to fetch $PHASE2_UD_GUEST_ICU_ID commit=$commit tree=$tree dest=$PHASE2_UD_GUEST_ICU_DEST_REL log=$log. Will not invent a stub dylib."
        return 1
    fi
    live_commit=$(git -c "safe.directory=$dest" -C "$dest" rev-parse HEAD)
    live_tree=$(git -c "safe.directory=$dest" -C "$dest" rev-parse 'HEAD^{tree}')
    if [ "$live_commit" != "$commit" ] || [ "$live_tree" != "$tree" ]; then
        phase2_ud_guest_cannot LIBCFTEST libCFTest.dylib \
            "no x86_64 Mach-O. ICU checkout tree differs at $dest live_commit=$live_commit want=$commit live_tree=$live_tree want=$tree (env/contract.json $PHASE2_UD_GUEST_ICU_ID). Will not invent a stub dylib."
        return 1
    fi
    if [ ! -d "$include/_foundation_unicode" ]; then
        phase2_ud_guest_cannot LIBCFTEST libCFTest.dylib \
            "no x86_64 Mach-O. pinned ICU checkout $commit at $dest is missing icuSources/include/_foundation_unicode. Will not invent a stub dylib."
        return 1
    fi
    return 0
}

# Turn the harness CANNOT_CFTEST_STUBS extra= missing= line into the ENV_PREPARE
# payload: count of unexpected names and the first five.
phase2_ud_guest_format_stub_cannot() {
    local line=$1
    local extra miss count first
    extra=${line#*extra=}
    extra=${extra%% missing=*}
    miss=${line#*missing=}
    if [ -n "$extra" ]; then
        count=$(printf '%s\n' "$extra" | tr ',' '\n' | grep -c . || true)
        first=$(printf '%s\n' "$extra" | tr ',' '\n' | grep -v '^$' | head -5 | paste -sd, -)
    else
        count=$(printf '%s\n' "$miss" | tr ',' '\n' | grep -c . || true)
        first=$(printf '%s\n' "$miss" | tr ',' '\n' | grep -v '^$' | head -5 | paste -sd, -)
    fi
    printf 'CANNOT_CFTEST_STUBS file=libCFTest.dylib count=%s first=%s extra=%s missing=%s\n' \
        "${count:-0}" "$first" "$extra" "$miss"
}

phase2_ud_guest_ensure_cftest() {
    local ud_w=$1 repo=$2
    local sys=${3:-$ud_w/fe/sysroot}
    local dest=$ud_w/lib/libCFTest.dylib
    local found recipe linker cf icu log st checker stub_line
    mkdir -p "$ud_w/lib"
    found=$(phase2_ud_guest_find_x86_dylib libCFTest.dylib \
        "${UD_CFTEST_DYLIB:-}" \
        "$dest" \
        "$repo/scratch/ud-guest-x86_64/lib/libCFTest.dylib" \
        || true)
    checker=$repo/foundation-macho/scripts/check_cftest_stubs.sh
    # Reuse a present dylib only when:
    #   * stub pin files exist and match (the 80-object / 220-stub set), or
    #   * no stub pin files exist (UD_CFTEST_DYLIB test dummy / override
    #     without leftover stub lists).
    # A leftover 143-name stub-func-active.txt must not count as satisfied.
    if [ -n "$found" ]; then
        if [ -f "$ud_w/stub-func-active.txt" ] && [ -f "$ud_w/stub-data.txt" ] \
            && [ -f "$checker" ]
        then
            stub_line=$(bash "$checker" "$ud_w/stub-func-active.txt" "$ud_w/stub-data.txt" || true)
            case "$stub_line" in
                CFTEST_STUBS_OK*)
                    [ "$found" = "$dest" ] || cp -a "$found" "$dest"
                    return 0
                    ;;
            esac
            # Mismatch: rebuild through the recipe. Do not reuse.
        else
            [ "$found" = "$dest" ] || cp -a "$found" "$dest"
            return 0
        fi
    fi

    recipe=$repo/foundation-macho/scripts/build_cfobjc.sh
    linker=$repo/foundation-macho/scripts/build_cftest_harness.sh
    if [ ! -f "$recipe" ]; then
        phase2_ud_guest_cannot LIBCFTEST libCFTest.dylib \
            "no x86_64 Mach-O. missing committed recipe $recipe. Will not invent a stub dylib."
        return 1
    fi
    if [ ! -f "$linker" ]; then
        phase2_ud_guest_cannot LIBCFTEST libCFTest.dylib \
            "no x86_64 Mach-O. missing committed CF linker $linker. Will not invent a stub dylib."
        return 1
    fi

    if ! phase2_ud_guest_ensure_cf_checkout "$ud_w" "$repo"; then
        return 1
    fi
    if ! phase2_ud_guest_ensure_icu_checkout "$repo"; then
        return 1
    fi
    cf=$ud_w/cf/$PHASE2_UD_GUEST_CF_SOURCES_REL
    if [ ! -f "$cf/CFRuntime.c" ]; then
        phase2_ud_guest_cannot LIBCFTEST libCFTest.dylib \
            "no x86_64 Mach-O. pinned CF checkout $PHASE2_UD_GUEST_CF_COMMIT missing $cf. Will not invent a stub dylib."
        return 1
    fi
    if [ ! -d "$sys/usr/include" ]; then
        phase2_ud_guest_cannot LIBCFTEST libCFTest.dylib \
            "no x86_64 Mach-O. Darwin sysroot missing at $sys (need usr/include). Committed recipe is foundation-macho/scripts/build_cfobjc.sh; committed CF linker is foundation-macho/scripts/build_cftest_harness.sh. Will not invent a stub dylib."
        return 1
    fi

    icu=$(phase2_ud_guest_find_icu "$repo" || true)
    if [ -z "$icu" ]; then
        phase2_ud_guest_cannot LIBCFTEST libCFTest.dylib \
            "no x86_64 Mach-O. ICU headers missing after $PHASE2_UD_GUEST_ICU_ID pin (need icuSources/include/_foundation_unicode). CFString.c will not compile; the harness would stub CFStringCreateWithBytes. Will not invent a stub dylib."
        return 1
    fi
    log=$ud_w/lib/build_cfobjc.log
    set +e
    W="$ud_w" \
        SDK="$sys" \
        CF="$cf" \
        OUT="$ud_w/cfobjc" \
        ICU_INC="$icu" \
        TRIPLE=x86_64-apple-macos13.0 \
        bash "$recipe" >"$log" 2>&1
    st=$?
    set -e
    if [ "$st" -ne 0 ]; then
        if grep -q '^CANNOT_CFOBJC_OBJECTS ' "$log"; then
            phase2_ud_guest_cannot LIBCFTEST libCFTest.dylib \
                "$(grep '^CANNOT_CFOBJC_OBJECTS ' "$log" | tail -1 | phase2_flatten) log=$log. Will not invent a stub dylib."
            return 1
        fi
        phase2_ud_guest_cannot LIBCFTEST libCFTest.dylib \
            "build_cfobjc.sh exit $st log=$log. Committed recipe is foundation-macho/scripts/build_cfobjc.sh; committed CF linker is foundation-macho/scripts/build_cftest_harness.sh. Will not invent a stub dylib."
        return 1
    fi

    log=$ud_w/lib/build_cftest_harness.log
    set +e
    W="$ud_w" \
        SDK="$sys" \
        CF="$ud_w/cfobjc/src" \
        CF_FALLBACK="$cf" \
        LIB="$ud_w/lib" \
        CFOBJC_OBJ="$ud_w/cfobjc/obj" \
        NSCF_OBJ="$ud_w/nscfobj" \
        R="$repo/foundation-macho" \
        PROBE_SRC="$repo/foundation-macho/tests/probe_sysctl.c" \
        TRIPLE=x86_64-apple-macos13.0 \
        LLD_BIN=/usr/lib/llvm-18/bin \
        bash "$linker" >"$log" 2>&1
    st=$?
    set -e
    if grep -q '^CANNOT_CFTEST_STUBS ' "$log"; then
        phase2_ud_guest_format_stub_cannot "$(grep '^CANNOT_CFTEST_STUBS ' "$log" | tail -1)"
        return 1
    fi
    if [ "$st" -ne 0 ] || [ ! -f "$dest" ] || ! phase2_is_x86_macho "$dest"; then
        phase2_ud_guest_cannot LIBCFTEST libCFTest.dylib \
            "build_cftest_harness.sh exit $st (committed CF linker; objects from build_cfobjc.sh) log=$log. Will not invent a stub dylib."
        return 1
    fi
}

phase2_ud_guest_link() {
    local repo=$1 ud_w=$2 sys=$3 out=$4
    local linker=$repo/$PHASE2_UD_GUEST_LINKER
    local log=$ud_w/link_ud_guest.log
    local st
    if [ ! -f "$linker" ]; then
        phase2_ud_guest_cannot UD_GUEST ud_guest "missing committed linker $linker"
        return 1
    fi
    mkdir -p "$(dirname "$out")" "$ud_w"
    set +e
    W="$ud_w" SDK="$sys" OUT="$out" LLD_BIN=/usr/lib/llvm-18/bin \
        bash "$linker" >"$log" 2>&1
    st=$?
    set -e
    if [ "$st" -ne 0 ] || [ ! -f "$out" ]; then
        # Spill to the work-tree root (same rule as the swiftc logs). Do not
        # flatten ld64 text onto the CANNOT line — the inputs listing alone
        # buries the diagnostic.
        phase2_ud_guest_cannot UD_GUEST ud_guest \
            "link_ud_guest.sh exit $st log=$log"
        return 1
    fi
    if ! phase2_is_x86_macho "$out"; then
        phase2_ud_guest_cannot UD_GUEST ud_guest \
            "linked file is not X86_64 Mach-O: $out log=$log"
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

# Stage libCFTest.dylib into a named run root, after link, before run.
# Arm64: build_cftest_harness.sh copies $W/lib/libCFTest.dylib into
# $W/root/darwin/usr/lib/ when that directory exists (/work/root). x86 W is
# scratch/ud-guest-x86_64; the run root is scratch/mrroot_full-x86_64.
# full/scripts/build_full.sh does not stage libCFTest (ARCH does not change
# that). Never copy onto the CoreFoundation.framework slot: a byte-identical
# copy there is the duplicate-image refusal in run_ud_guest.sh.
# Prints: status=cold-built|satisfied path=… sha256=…
phase2_stage_cftest_into_run_root() {
    local src=$1 dest_root=$2
    local dest=$dest_root/darwin/usr/lib/libCFTest.dylib
    local cf_slot=$dest_root/darwin/System/Library/Frameworks/CoreFoundation.framework/CoreFoundation
    local sha a b already=0
    if [ ! -f "$src" ] || ! phase2_is_x86_macho "$src"; then
        printf 'CANNOT_UD_GUEST_LIBCFTEST file=libCFTest.dylib reason=no x86 Mach-O to stage into run root src=%s\n' \
            "${src:-empty}"
        return 1
    fi
    mkdir -p "$(dirname "$dest")"
    if [ -f "$dest" ] && cmp -s "$src" "$dest"; then
        already=1
    else
        cp -f "$src" "$dest"
    fi
    sha=$(sha256sum "$dest" | awk '{print $1}')
    if [ -f "$cf_slot" ]; then
        a=$(md5sum "$cf_slot" | awk '{print $1}')
        b=$(md5sum "$dest" | awk '{print $1}')
        if [ "$a" = "$b" ]; then
            printf 'CANNOT_UD_GUEST_LIBCFTEST file=libCFTest.dylib reason=CoreFoundation slot is a byte-identical copy of libCFTest.dylib (duplicate-image refusal) path=%s\n' \
                "$cf_slot"
            return 1
        fi
    fi
    if [ "$already" -eq 1 ]; then
        printf 'status=satisfied path=%s sha256=%s\n' "$dest" "$sha"
    else
        printf 'status=cold-built path=%s sha256=%s\n' "$dest" "$sha"
    fi
}

# Linux Dispatch host bridge + Darwin OpenDispatch facade for rung a.
# Reuses scratch/mrroot-x86_64/host/libOpenDispatchHost.so when that file is
# already ELF x86-64 (phase2_build_x86_host_helpers / Reminder script).
# Builds the Darwin image with the same clang/ld64 argv as
# full/swiftui/build_focus_onboarding_guest.sh / build_core_guest_package.sh:
# install_name /usr/lib/libOpenDispatch.dylib, -undefined dynamic_lookup.
# Prints: status=cold-built|satisfied bridge=… runtime=… sha256=…
phase2_ud_guest_ensure_dispatch() {
    local repo=$1 ud_w=$2 sys=$3 target=$4
    local existing_host=${5:-}
    local host_dir host dest obj log st arch darwin_sha host_ok=0 darwin_ok=0
    local built_host=0 built_darwin=0

    phase2_ud_guest_refuse_unsuffixed "$ud_w" || return 1
    mkdir -p "$ud_w/lib" "$ud_w/host" "$ud_w/host-work"

    host=$ud_w/host/libOpenDispatchHost.so
    if [ -f "$existing_host" ] && [ ! -L "$existing_host" ] \
        && phase2_is_elf_x86_so "$existing_host"
    then
        host=$existing_host
        host_ok=1
    elif [ -f "$host" ] && [ ! -L "$host" ] && phase2_is_elf_x86_so "$host"; then
        host_ok=1
    fi

    if [ "$host_ok" -ne 1 ]; then
        host_dir=$ud_w/host
        rm -f "$host_dir/libOpenDispatchHost.so"
        log=$ud_w/host-work/build_host_bridge.log
        set +e
        bash "$repo/full/dispatch/build_host_bridge.sh" \
            --repo "$repo" \
            --host-dir "$host_dir" \
            --work-dir "$ud_w/host-work" \
            --skip-runtime-pin \
            --host-abi "ELF64-$(uname -m)" \
            --refuse-prefix 'ud-guest-dispatch: ' \
            >"$log" 2>&1
        st=$?
        set -e
        host=$host_dir/libOpenDispatchHost.so
        if [ "$st" -ne 0 ] || [ ! -f "$host" ] || [ -L "$host" ] \
            || ! phase2_is_elf_x86_so "$host"
        then
            phase2_ud_guest_cannot DISPATCH libOpenDispatchHost.so \
                "build_host_bridge.sh exit $st log=$log"
            return 1
        fi
        built_host=1
        host_ok=1
    fi

    dest=$ud_w/lib/libOpenDispatch.dylib
    case "$target" in
        x86_64-*) arch=x86_64 ;;
        arm64-*|aarch64-*) arch=arm64 ;;
        *)
            phase2_ud_guest_cannot DISPATCH libOpenDispatch.dylib \
                "cannot derive ld64 -arch from target=$target"
            return 1
            ;;
    esac
    if [ -f "$dest" ] && phase2_is_x86_macho "$dest" \
        && [ "$(llvm-otool-18 -D "$dest" 2>/dev/null | tail -n 1)" = \
            /usr/lib/libOpenDispatch.dylib ]
    then
        darwin_ok=1
    fi
    if [ "$darwin_ok" -ne 1 ]; then
        if [ ! -d "$sys/usr/lib" ]; then
            phase2_ud_guest_cannot DISPATCH libOpenDispatch.dylib \
                "no Darwin sysroot at $sys to link OpenDispatchBridge.c"
            return 1
        fi
        obj=$ud_w/lib/open-dispatch-bridge.o
        log=$ud_w/lib/open-dispatch-bridge.log
        set +e
        clang-18 -target "$target" -isysroot "$sys" -std=c11 -O2 \
            -fvisibility=hidden -Wall -Wextra -Werror \
            -I "$repo/full/dispatch/include" \
            -c "$repo/full/dispatch/OpenDispatchBridge.c" \
            -o "$obj" >"$log" 2>&1
        st=$?
        set -e
        if [ "$st" -ne 0 ] || [ ! -f "$obj" ]; then
            phase2_ud_guest_cannot DISPATCH libOpenDispatch.dylib \
                "OpenDispatchBridge.c clang exit $st log=$log"
            return 1
        fi
        set +e
        ld64.lld-18 -arch "$arch" -platform_version macos 15.0 15.0 \
            -syslibroot "$sys" \
            -dylib -dead_strip -undefined dynamic_lookup \
            -install_name /usr/lib/libOpenDispatch.dylib \
            -o "$dest" "$obj" >>"$log" 2>&1
        st=$?
        set -e
        if [ "$st" -ne 0 ] || [ ! -f "$dest" ] || ! phase2_is_x86_macho "$dest" \
            || [ "$(llvm-otool-18 -D "$dest" 2>/dev/null | tail -n 1)" != \
                /usr/lib/libOpenDispatch.dylib ]
        then
            phase2_ud_guest_cannot DISPATCH libOpenDispatch.dylib \
                "ld64 OpenDispatchBridge exit $st log=$log"
            return 1
        fi
        built_darwin=1
        darwin_ok=1
    fi

    darwin_sha=$(sha256sum "$dest" | awk '{print $1}')
    if [ "$built_host" -eq 0 ] && [ "$built_darwin" -eq 0 ]; then
        printf 'status=satisfied bridge=%s runtime=%s sha256=%s\n' \
            "$host" "$dest" "$darwin_sha"
    else
        printf 'status=cold-built bridge=%s runtime=%s sha256=%s\n' \
            "$host" "$dest" "$darwin_sha"
    fi
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

    report=$(phase2_ud_guest_ensure_cftest "$ud_w" "$repo" "$sys" || true)
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
