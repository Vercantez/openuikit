#!/usr/bin/env bash
# Independently validate every material AppKit focused-proof boundary.

set -euo pipefail

W=${W:-/w}
ROOT=${1:?usage: validate_appkit_focused_guest.sh APPKIT_PROOF}
APPKIT_ID=/System/Library/Frameworks/AppKit.framework/Versions/C/AppKit
EXPECTED_EXPORT_COUNT=198
EXPECTED_EXPORT_SHA=dd9b850d2dcf4deb398752a950248a229b4374c40fa948727fa13ef9f50a2b15
EXPECTED_IMPORT_SHA=58c8c02cadac24ec680699924a8e4bcc7701562519242e74316b752b048195a4
EXPECTED_ORACLE_SHA=7e6460172de03f740a085b12550ed6c1fa4f041706103bf62d4d413a385c90ff
EXPECTED_RUNTIME_SHA=c879019a43de64c4764e81bc71dbea77f71fbcff041d787606146e566e4b75b4

die() {
    printf 'validate_appkit_focused_guest: %s\n' "$*" >&2
    exit 2
}

case "$ROOT" in
    /*/appkit-focused-proof|/*/appkit-focused-proof-[A-Za-z0-9._-]*) ;;
    *) die "proof must be an absolute narrowly named AppKit proof path: $ROOT" ;;
esac
[ -d "$ROOT" ] && [ ! -L "$ROOT" ] || die 'proof root is missing or linked'
[ -f "$ROOT/PROOF_COMPLETE" ] && [ ! -L "$ROOT/PROOF_COMPLETE" ] \
    || die 'proof completion record is missing or linked'

scratch=$(mktemp -d "${TMPDIR:-/tmp}/validate-appkit.XXXXXX")
cleanup() {
    find "$scratch" -depth -delete
}
trap cleanup EXIT HUP INT TERM

framework=$ROOT/frameworks/AppKit.framework
versioned=$framework/Versions/C/AppKit
module_dir=$framework/Versions/C/Modules/AppKit.swiftmodule
module=$module_dir/arm64-apple-macos.swiftmodule
interface=$module_dir/arm64-apple-macos.swiftinterface
runtime=$ROOT/guest-root/darwin$APPKIT_ID

for regular in "$versioned" "$module" "$interface" "$runtime" \
    "$ROOT/probe/AppKitGuestRuntime" "$ROOT/probe/AppKitInterfaceOracle" \
    "$ROOT/attestation/appkit-exports.txt" \
    "$ROOT/attestation/appkit-imports.txt" \
    "$ROOT/attestation/appkit-loads.txt" \
    "$ROOT/attestation/appkit-load-identities.txt" \
    "$ROOT/attestation/AppKitGuestRuntime.log" \
    "$ROOT/attestation/AppKitInterfaceOracle.log"; do
    [ -f "$regular" ] && [ ! -L "$regular" ] \
        || die "required regular artifact is missing: $regular"
done
[ -s "$module" ] && [ -s "$interface" ] || die 'AppKit module artifacts are empty'
grep -Fq -- '-module-link-name AppKit' "$interface" \
    || die 'AppKit textual interface lost its link identity'

check_link() {
    local path=$1 expected=$2
    [ -L "$path" ] || die "required framework link is missing: $path"
    [ "$(readlink "$path")" = "$expected" ] \
        || die "framework link target drifted: $path"
}
check_link "$framework/Versions/Current" C
check_link "$framework/AppKit" Versions/Current/AppKit
check_link "$framework/Modules" Versions/Current/Modules
runtime_framework=$ROOT/guest-root/darwin/System/Library/Frameworks/AppKit.framework
check_link "$runtime_framework/Versions/Current" C
check_link "$runtime_framework/AppKit" Versions/Current/AppKit

cmp "$versioned" "$runtime" \
    || die 'compile and cold-runtime AppKit binaries differ'
for binary in "$versioned" "$runtime"; do
    llvm-otool-18 -hv "$binary" \
        | grep -Eq 'MH_MAGIC_64[[:space:]]+ARM64.*[[:space:]]DYLIB' \
        || die "artifact is not an ARM64 Mach-O dylib: $binary"
    [ "$(llvm-otool-18 -D "$binary" | tail -n 1)" = "$APPKIT_ID" ] \
        || die "AppKit install identity drifted: $binary"
done

llvm-nm-18 --defined-only --extern-only --just-symbol-name "$versioned" \
    | LC_ALL=C sort -u > "$scratch/exports.txt"
llvm-nm-18 --undefined-only --extern-only --just-symbol-name "$versioned" \
    | LC_ALL=C sort -u > "$scratch/imports.txt"
cmp "$scratch/exports.txt" "$ROOT/attestation/appkit-exports.txt" \
    || die 'AppKit export attestation does not match its binary'
cmp "$scratch/imports.txt" "$ROOT/attestation/appkit-imports.txt" \
    || die 'AppKit import attestation does not match its binary'
[ "$(wc -l < "$scratch/exports.txt" | tr -d '[:space:]')" \
    -eq "$EXPECTED_EXPORT_COUNT" ] || die 'AppKit export count drifted'
[ "$(sha256sum "$scratch/exports.txt" | awk '{print $1}')" \
    = "$EXPECTED_EXPORT_SHA" ] || die 'AppKit exact export contract drifted'
[ "$(sha256sum "$scratch/imports.txt" | awk '{print $1}')" \
    = "$EXPECTED_IMPORT_SHA" ] || die 'AppKit exact import contract drifted'

llvm-otool-18 -L "$versioned" > "$scratch/loads.txt"
awk 'NR > 1 { print $1 }' "$scratch/loads.txt" > "$scratch/load-identities.txt"
cmp "$W/full/appkit/tests/appkit-load-identities.txt" \
    "$scratch/load-identities.txt" || die 'AppKit binary load closure drifted'
cmp "$W/full/appkit/tests/appkit-load-identities.txt" \
    "$ROOT/attestation/appkit-load-identities.txt" \
    || die 'AppKit load attestation drifted'
awk 'NR > 1 { print $1 }' "$ROOT/attestation/appkit-loads.txt" \
    > "$scratch/attested-load-identities.txt"
cmp "$scratch/load-identities.txt" "$scratch/attested-load-identities.txt" \
    || die 'AppKit detailed load attestation does not match its binary'
if grep -Fq '/System/Library/Frameworks/Foundation.framework/' \
    "$scratch/load-identities.txt"; then
    die 'AppKit loads Apple Foundation rather than the portable runtime'
fi

for probe in AppKitGuestRuntime AppKitInterfaceOracle; do
    llvm-otool-18 -hv "$ROOT/probe/$probe" \
        | grep -Eq 'MH_MAGIC_64[[:space:]]+ARM64.*[[:space:]]EXECUTE' \
        || die "$probe is not an ARM64 Mach-O executable"
    [ "$(llvm-otool-18 -L "$ROOT/probe/$probe" \
        | awk -v expected="$APPKIT_ID" \
            '$1 == expected { count++ } END { print count + 0 }')" -eq 1 ] \
        || die "$probe AppKit load is missing or duplicated"
done

cmp "$W/full/appkit/tests/appkit-interface-apple-xcode-26.1.txt" \
    "$ROOT/attestation/AppKitInterfaceOracle.log" \
    || die 'AppKit cold oracle differs from Apple'
grep -Fxq \
    'APPKIT_GUEST_MACHO_OK surface=application,alert,workspace,window,font,color ui=headless workspace=fail-closed alert=cancel-or-abort fonts=unavailable' \
    "$ROOT/attestation/AppKitGuestRuntime.log" \
    || die 'AppKit cold runtime marker drifted'
[ "$(sha256sum "$ROOT/attestation/AppKitInterfaceOracle.log" | awk '{print $1}')" \
    = "$EXPECTED_ORACLE_SHA" ] || die 'AppKit oracle hash drifted'
[ "$(sha256sum "$ROOT/attestation/AppKitGuestRuntime.log" | awk '{print $1}')" \
    = "$EXPECTED_RUNTIME_SHA" ] || die 'AppKit cold runtime hash drifted'

framework_sha=$(sha256sum "$versioned" | awk '{print $1}')
module_sha=$(sha256sum "$module" | awk '{print $1}')
manifest=$ROOT/PROOF_COMPLETE
grep -Fxq $'format\tappkit-focused-proof-v1' "$manifest" \
    || die 'proof format drifted'
grep -Fxq "$(printf 'install-name\t%s' "$APPKIT_ID")" "$manifest" \
    || die 'proof install-name record drifted'
grep -Fxq "$(printf 'framework\t%s' "$framework_sha")" "$manifest" \
    || die 'proof framework hash drifted'
grep -Fxq "$(printf 'module\t%s' "$module_sha")" "$manifest" \
    || die 'proof module hash drifted'
grep -Fxq "$(printf 'exports\tcount=%s\tsha256=%s' \
    "$EXPECTED_EXPORT_COUNT" "$EXPECTED_EXPORT_SHA")" "$manifest" \
    || die 'proof export record drifted'
grep -Fxq "$(printf 'apple-differential\trows=10\tsha256=%s' \
    "$EXPECTED_ORACLE_SHA")" "$manifest" \
    || die 'proof oracle record drifted'
grep -Fxq "$(printf 'cold-runtime\tsha256=%s' "$EXPECTED_RUNTIME_SHA")" \
    "$manifest" || die 'proof cold-runtime record drifted'
[ "$(wc -l < "$manifest" | tr -d '[:space:]')" -eq 7 ] \
    || die 'proof completion record has unexpected rows'

printf 'APPKIT_FOCUSED_VALIDATE_OK exports=%s loads=16 apple-rows=10 cold=1\n' \
    "$EXPECTED_EXPORT_COUNT"
