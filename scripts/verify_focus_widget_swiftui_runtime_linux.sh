#!/usr/bin/env bash
# Run the exact Focus SwiftUI runtime proof on macOS and native Linux, then
# require the emitted PNGs to be byte-identical.

set -euo pipefail
umask 077

usage() {
    echo "usage: $0 /path/to/BlockzillaPackage /path/to/Focus_Widget.bundle NEW_WORK_DIR" >&2
    echo "       SWIFT_LINUX_IMAGE defaults to swift:6.2-noble" >&2
    exit 64
}

fail() {
    echo "error: $*" >&2
    exit 1
}

[[ $# -eq 3 ]] || usage
[[ "$(uname -s)" == "Darwin" ]] || fail "the cross-platform driver must start on macOS"

script_dir=$(cd "$(dirname "$0")" && pwd -P)
open_uikit_root=$(cd "$script_dir/.." && pwd -P)
focus_package_root=$(cd "$1" 2>/dev/null && pwd -P) || usage
normalized_bundle=$(cd "$2" 2>/dev/null && pwd -P) || usage

work_argument=$3
[[ ! -e "$work_argument" && ! -L "$work_argument" ]] \
    || fail "work directory must not already exist: $work_argument"
mkdir -p "$work_argument"
work_root=$(cd "$work_argument" && pwd -P)
chmod 0700 "$work_root"
mkdir -p "$work_root/fonts" "$work_root/out"

for font in SFNS.ttf SFNSMono.ttf SFNSItalic.ttf; do
    source_font="/System/Library/Fonts/$font"
    [[ -f "$source_font" && ! -L "$source_font" ]] \
        || fail "required local Apple font is missing or symlinked: $source_font"
    cp -p "$source_font" "$work_root/fonts/$font"
done

focus_repo=$(git -C "$focus_package_root" rev-parse --show-toplevel 2>/dev/null) \
    || fail "BlockzillaPackage must be inside a Git checkout"
case "$focus_package_root" in
    "$focus_repo"/*) focus_package_relative=${focus_package_root#"$focus_repo"/} ;;
    *) fail "BlockzillaPackage escaped its Git checkout" ;;
esac

image=${SWIFT_LINUX_IMAGE:-swift:6.2-noble}
docker info >/dev/null 2>&1 || fail "Docker daemon is not available"

echo "==> macOS exact-source render"
OPENUIKIT_FONT_DIR="$work_root/fonts" \
    "$script_dir/prove_focus_widget_swiftui_runtime.sh" \
    "$focus_package_root" "$normalized_bundle" "$work_root/out/macos-focus-widget.png"

echo "==> native Linux exact-source render ($image)"
docker run --rm \
    -v "$open_uikit_root:/src:ro" \
    -v "$focus_repo:/focus:ro" \
    -v "$normalized_bundle:/input/Focus_Widget.bundle:ro" \
    -v "$work_root/fonts:/fonts:ro" \
    -v "$work_root/out:/out" \
    -e OPENUIKIT_FONT_DIR=/fonts \
    "$image" \
    bash /src/scripts/prove_focus_widget_swiftui_runtime.sh \
        "/focus/$focus_package_relative" \
        /input/Focus_Widget.bundle \
        /out/linux-focus-widget.png

cmp "$work_root/out/macos-focus-widget.png" "$work_root/out/linux-focus-widget.png" \
    || fail "macOS and Linux PNG bytes differ"

if command -v shasum >/dev/null 2>&1; then
    digest=$(shasum -a 256 "$work_root/out/macos-focus-widget.png" | awk '{print $1}')
else
    digest=$(sha256sum "$work_root/out/macos-focus-widget.png" | awk '{print $1}')
fi

echo "PORTABILITY VERIFIED: exact Focus SearchWidgetView runs natively on Linux"
echo "container image: $image"
echo "byte-identical PNG sha256: $digest"
echo "macOS PNG: $work_root/out/macos-focus-widget.png"
echo "Linux PNG: $work_root/out/linux-focus-widget.png"
