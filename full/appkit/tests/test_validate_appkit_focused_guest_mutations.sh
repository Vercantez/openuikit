#!/usr/bin/env bash
# Prove that the AppKit focused validator rejects independently corrupted
# identity, artifact, module, export/load, oracle, and completion boundaries.

set -euo pipefail

W=${W:-/w}
PROOF=${1:?usage: test_validate_appkit_focused_guest_mutations.sh PROOF OUTPUT}
OUTPUT=${2:?usage: test_validate_appkit_focused_guest_mutations.sh PROOF OUTPUT}
VALIDATOR=$W/full/appkit/tests/validate_appkit_focused_guest.sh
APPKIT_ID=/System/Library/Frameworks/AppKit.framework/Versions/C/AppKit

die() {
    printf 'test_validate_appkit_focused_guest_mutations: %s\n' "$*" >&2
    exit 2
}

case "$OUTPUT" in
    /*/appkit-focused-mutations|/*/appkit-focused-mutations-[A-Za-z0-9._-]*) ;;
    *) die "output must be an absolute narrowly named mutation path: $OUTPUT" ;;
esac
[ ! -e "$OUTPUT" ] || die "mutation output already exists: $OUTPUT"
[ -x "$VALIDATOR" ] || die 'AppKit focused validator is not executable'

mkdir "$OUTPUT"
cleanup() {
    find "$OUTPUT" -depth -delete
}
trap cleanup EXIT HUP INT TERM

bash "$VALIDATOR" "$PROOF" >/dev/null
rejections=0

replace_with_append() {
    local path=$1
    cp -p "$path" "$path.mutating"
    printf '\nAPPKIT_MUTATION\n' >> "$path.mutating"
    mv -f "$path.mutating" "$path"
}

expect_rejected() {
    local name=$1
    local case_root=$OUTPUT/appkit-focused-proof-$name
    mkdir "$case_root"
    cp -a --reflink=auto "$PROOF"/. "$case_root"/

    case "$name" in
        framework-byte)
            replace_with_append \
                "$case_root/frameworks/AppKit.framework/Versions/C/AppKit"
            ;;
        runtime-byte)
            replace_with_append \
                "$case_root/guest-root/darwin$APPKIT_ID"
            ;;
        module-missing)
            mv "$case_root/frameworks/AppKit.framework/Versions/C/Modules/AppKit.swiftmodule/arm64-apple-macos.swiftmodule" \
                "$case_root/module.removed"
            ;;
        export-attestation)
            replace_with_append "$case_root/attestation/appkit-exports.txt"
            ;;
        load-attestation)
            replace_with_append \
                "$case_root/attestation/appkit-load-identities.txt"
            ;;
        oracle-log)
            replace_with_append \
                "$case_root/attestation/AppKitInterfaceOracle.log"
            ;;
        completion-record)
            replace_with_append "$case_root/PROOF_COMPLETE"
            ;;
        framework-link)
            unlink "$case_root/frameworks/AppKit.framework/AppKit"
            ln -s Versions/Bogus/AppKit \
                "$case_root/frameworks/AppKit.framework/AppKit"
            ;;
        install-identity)
            binary=$case_root/frameworks/AppKit.framework/Versions/C/AppKit
            runtime=$case_root/guest-root/darwin$APPKIT_ID
            cp -p "$binary" "$binary.mutating"
            llvm-install-name-tool-18 -id \
                /System/Library/Frameworks/AppKit.framework/Versions/B/AppKit \
                "$binary.mutating"
            mv -f "$binary.mutating" "$binary"
            cp -p "$binary" "$runtime.mutating"
            mv -f "$runtime.mutating" "$runtime"
            ;;
        load-closure)
            binary=$case_root/frameworks/AppKit.framework/Versions/C/AppKit
            runtime=$case_root/guest-root/darwin$APPKIT_ID
            cp -p "$binary" "$binary.mutating"
            llvm-install-name-tool-18 -change @rpath/libFoundation.dylib \
                @rpath/libFoundatioX.dylib "$binary.mutating"
            mv -f "$binary.mutating" "$binary"
            cp -p "$binary" "$runtime.mutating"
            mv -f "$runtime.mutating" "$runtime"
            ;;
        *) die "unknown mutation: $name" ;;
    esac

    set +e
    bash "$VALIDATOR" "$case_root" \
        > "$OUTPUT/$name.validator.log" 2>&1
    status=$?
    set -e
    [ "$status" -ne 0 ] || die "validator accepted mutation: $name"
    grep -Fq 'validate_appkit_focused_guest:' \
        "$OUTPUT/$name.validator.log" \
        || die "validator rejection lacked a bounded diagnostic: $name"
    rejections=$((rejections + 1))
    find "$case_root" -depth -delete
    printf 'APPKIT_VALIDATOR_MUTATION_REJECTED name=%s status=%s\n' \
        "$name" "$status"
}

for mutation in \
    framework-byte runtime-byte module-missing export-attestation \
    load-attestation oracle-log completion-record framework-link \
    install-identity load-closure; do
    expect_rejected "$mutation"
done
[ "$rejections" -eq 10 ] || die 'mutation rejection count drifted'

cleanup
trap - EXIT HUP INT TERM
printf 'APPKIT_VALIDATOR_MUTATIONS_OK rejected=%s pristine=1\n' "$rejections"
