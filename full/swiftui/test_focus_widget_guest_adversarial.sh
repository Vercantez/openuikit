#!/usr/bin/env bash
# Destructive-to-cache integration checks for the resume-only proof boundary.
# Run only in a disposable/isolated swift-macho checkout after one successful
# ordinary build_focus_widget_guest.sh invocation.

set -euo pipefail

W=${W:-/w}
# shellcheck disable=SC1091
. "$W/full/scripts/guest_arch.inc"
RESOURCE_INPUT=${1:?usage: test_focus_widget_guest_adversarial.sh <normalized-Focus_Widget.bundle>}
FULL=$W/build/full${FULL_OUT_SUFFIX}
SYS=$W/scratch/sysroot_fe4${FULL_OUT_SUFFIX}
MRROOT=$W/scratch/mrroot_full${FULL_OUT_SUFFIX}
ATTEST=$W/full/swiftui/focus_widget_guest_attest.pl
BUILD=$W/full/swiftui/build_focus_widget_guest.sh

for required in \
    "$FULL/focus-widget-build-inputs.manifest" \
    "$FULL/focus-widget-runtime-closure.manifest" \
    "$W/full/foundation/foundationessentials_import_guard.swift" \
    "$FULL/foundation/essentials/FoundationEssentials.swiftmodule" \
    "$FULL/OpenUIKit.swiftmodule" \
    "$FULL/inc/CPortableIO/module.modulemap" \
    "$FULL/inc/CPortableIO/cportableio.h" \
    "$SYS/usr/lib/swift/libswiftCore.tbd" \
    "$MRROOT/darwin/System/Library/Frameworks/Foundation.framework/Foundation" \
    "$ATTEST"; do
    [ -f "$required" ] || {
        echo "focus_widget_guest_adversarial: missing prerequisite $required" >&2
        exit 2
    }
done

TMP=$(mktemp -d /tmp/focus-widget-adversarial.XXXXXX)
CURRENT_TARGET=
CURRENT_BACKUP=
# 0 = originally absent, 1 = regular file, 2 = directory moved aside and
# replaced by a symlink for the runtime-ancestor case.
CURRENT_EXISTED=0
restore_current() {
    if [ -n "$CURRENT_TARGET" ]; then
        if [ -L "$CURRENT_TARGET" ] || [ -f "$CURRENT_TARGET" ]; then
            unlink "$CURRENT_TARGET"
        elif [ -d "$CURRENT_TARGET" ]; then
            rmdir "$CURRENT_TARGET"
        fi
        case "$CURRENT_EXISTED" in
            1) cp -p "$CURRENT_BACKUP" "$CURRENT_TARGET" ;;
            2) mv "$CURRENT_BACKUP" "$CURRENT_TARGET" ;;
        esac
    fi
    CURRENT_TARGET=
    CURRENT_BACKUP=
    CURRENT_EXISTED=0
}
cleanup() {
    restore_current
    rm -rf "$TMP"
}
trap cleanup EXIT

begin_case() {
    local label=$1 target=$2
    CURRENT_TARGET=$target
    CURRENT_BACKUP=$TMP/$label.backup
    CURRENT_EXISTED=1
    cp -p "$target" "$CURRENT_BACKUP"
}

begin_absent_case() {
    local label=$1 target=$2
    [ ! -e "$target" ] && [ ! -L "$target" ] || {
        echo "focus_widget_guest_adversarial: expected absent mutation target $target" >&2
        exit 2
    }
    CURRENT_TARGET=$target
    CURRENT_BACKUP=$TMP/$label.backup
    CURRENT_EXISTED=0
}

begin_directory_symlink_case() {
    local label=$1 target=$2
    [ -d "$target" ] && [ ! -L "$target" ] || {
        echo "focus_widget_guest_adversarial: expected real directory mutation target $target" >&2
        exit 2
    }
    CURRENT_TARGET=$target
    CURRENT_BACKUP=$TMP/$label.backup
    CURRENT_EXISTED=2
    mv "$CURRENT_TARGET" "$CURRENT_BACKUP"
    ln -s "$CURRENT_BACKUP" "$CURRENT_TARGET"
}

expect_resume_refusal() {
    local label=$1 log=$TMP/$1.log rc
    case "$CURRENT_EXISTED" in
        1)
            if [ -f "$CURRENT_TARGET" ] && [ ! -L "$CURRENT_TARGET" ] && \
                    cmp -s "$CURRENT_TARGET" "$CURRENT_BACKUP"; then
                echo "focus_widget_guest_adversarial: $label mutation changed no bytes or type" >&2
                exit 2
            fi ;;
        2)
            [ -L "$CURRENT_TARGET" ] || {
                echo "focus_widget_guest_adversarial: $label did not install its ancestor symlink" >&2
                exit 2
            } ;;
        *)
            [ -e "$CURRENT_TARGET" ] || [ -L "$CURRENT_TARGET" ] || {
                echo "focus_widget_guest_adversarial: $label did not add its node" >&2
                exit 2
            } ;;
    esac
    set +e
    SKIP_FULL_BUILD=1 bash "$BUILD" "$RESOURCE_INPUT" > "$log" 2>&1
    rc=$?
    set -e
    restore_current
    [ "$rc" -ne 0 ] || {
        echo "focus_widget_guest_adversarial: $label tamper unexpectedly passed" >&2
        sed -n '1,160p' "$log" >&2
        exit 2
    }
    if grep -Eq '== run (arm64|x86_64) Mach-O|^PASS: exact unchanged Focus|^== PASS:' "$log"; then
        echo "focus_widget_guest_adversarial: $label reached guest success before refusal" >&2
        sed -n '1,200p' "$log" >&2
        exit 2
    fi
    printf 'ADVERSARIAL PASS: %-28s resume refused before guest success (rc=%s)\n' "$label" "$rc"
}

begin_case guard-source "$W/full/foundation/foundationessentials_import_guard.swift"
printf '\n// adversarial guard-source drift\n' >> "$CURRENT_TARGET"
expect_resume_refusal guard-source

begin_case swiftmodule "$FULL/OpenUIKit.swiftmodule"
printf 'adversarial-swiftmodule-drift' >> "$CURRENT_TARGET"
expect_resume_refusal swiftmodule

begin_case foundationessentials-swiftmodule \
    "$FULL/foundation/essentials/FoundationEssentials.swiftmodule"
printf 'adversarial-foundationessentials-swiftmodule-drift' >> "$CURRENT_TARGET"
expect_resume_refusal foundationessentials-swiftmodule

begin_case modulemap "$FULL/inc/CPortableIO/module.modulemap"
printf '\n// adversarial modulemap drift\n' >> "$CURRENT_TARGET"
expect_resume_refusal modulemap

begin_case header "$FULL/inc/CPortableIO/cportableio.h"
printf '\n/* adversarial header drift */\n' >> "$CURRENT_TARGET"
expect_resume_refusal header

begin_absent_case header-extra "$FULL/inc/CPortableIO/adversarial-extra.h"
printf '/* adversarial extra header */\n' > "$CURRENT_TARGET"
expect_resume_refusal header-extra

begin_case header-missing "$FULL/inc/CPortableIO/cportableio.h"
unlink "$CURRENT_TARGET"
expect_resume_refusal header-missing

begin_case header-symlink "$FULL/inc/CPortableIO/cportableio.h"
unlink "$CURRENT_TARGET"
ln -s "$CURRENT_BACKUP" "$CURRENT_TARGET"
expect_resume_refusal header-symlink

begin_case sysroot-tbd "$SYS/usr/lib/swift/libswiftCore.tbd"
printf '\n# adversarial sysroot TBD drift\n' >> "$CURRENT_TARGET"
expect_resume_refusal sysroot-tbd

begin_case extensionless-stub "$MRROOT/darwin/System/Library/Frameworks/Foundation.framework/Foundation"
printf 'adversarial-extensionless-stub-drift' >> "$CURRENT_TARGET"
expect_resume_refusal extensionless-stub

# Leaf-only lstat checks do not protect a trusted root: an ancestor directory
# can be moved outside the root and replaced by a symlink while every loaded
# image keeps the same bytes. The complete resume used to pass this mutation
# and falsely label the external stub as guest-root content.
begin_directory_symlink_case runtime-ancestor-symlink \
    "$MRROOT/darwin/System/Library/Frameworks/Foundation.framework"
expect_resume_refusal runtime-ancestor-symlink

begin_case provider-logic "$ATTEST"
perl -pi -e 's/SwiftUI => '\''libSwiftUI'\''/SwiftUI => '\''libSwiftUI_TAMPER'\''/' "$CURRENT_TARGET"
expect_resume_refusal provider-logic

begin_case inventory-logic "$ATTEST"
perl -pi -e 's/foundationessentials_import_guard\.swift/foundationessentials_import_guard.tampered.swift/' "$CURRENT_TARGET"
expect_resume_refusal inventory-logic

final_log=$TMP/final-clean-resume.log
SKIP_FULL_BUILD=1 bash "$BUILD" "$RESOURCE_INPUT" > "$final_log" 2>&1
grep -Fxq '== PASS: unchanged Focus widget ran through packaged SwiftUI/OpenUIKit/Combine dylibs as a Linux Mach-O guest' \
    "$final_log" || {
    echo "focus_widget_guest_adversarial: clean resume did not recover after restored tamper cases" >&2
    sed -n '1,240p' "$final_log" >&2
    exit 2
}
echo "ADVERSARIAL PASS: clean isolated resume completed after all restored tamper cases"
