#!/usr/bin/env bash
# Focused compile-only SwiftUI #Preview proof. This deliberately does not run
# or render a preview; it verifies host-plugin transport plus target metadata
# for the named and unnamed source forms used by ordinary SwiftPM packages.

set -euo pipefail
umask 077

die() {
    echo "swiftui-previewprobe: $*" >&2
    exit 2
}

[[ $# -eq 1 ]] || die "usage: $0 /path/to/OpenUIKit"
script_dir=$(cd "$(dirname "$0")" && pwd -P)
candidate=$(cd "$1" && pwd -P)
fixture_source="$script_dir/Fixture"
swift_syntax_revision=4799286537280063c85a32f09884cfbca301b1a1
swift_syntax_tree=4c96b84ec6f59391ca70d18191500c14854d3d91

for tool in swift swiftc git file shasum; do
    command -v "$tool" >/dev/null || die "required tool is missing: $tool"
done
[[ -f "$candidate/Package.swift" && ! -L "$candidate/Package.swift" ]] \
    || die "candidate Package.swift is not a regular file"

status_before=$(git -C "$candidate" status --porcelain=v1 --untracked-files=all)
head_before=$(git -C "$candidate" rev-parse HEAD)
tree_before=$(git -C "$candidate" rev-parse HEAD^{tree})
scratch=$(mktemp -d "${TMPDIR:-/tmp}/open-uikit-swiftui-preview.XXXXXX")
cleanup() {
    if [[ "${OPENUIKIT_SWIFTUI_PREVIEW_KEEP_OUTPUT:-0}" == "1" ]]; then
        echo "swiftui-preview.scratch=$scratch"
    elif command -v trash >/dev/null 2>&1; then
        trash "$scratch"
    else
        rm -rf -- "$scratch"
    fi
}
trap cleanup EXIT

cp -R "$fixture_source" "$scratch/fixture"
export OPENUIKIT_PREVIEW_ROOT="$candidate"
swift build --package-path "$scratch/fixture" --scratch-path "$scratch/build" \
    --target SwiftUIPreviewClient --disable-index-store -Xswiftc -gnone \
    >"$scratch/build.stdout" 2>"$scratch/build.stderr" || {
        cat "$scratch/build.stdout" "$scratch/build.stderr" >&2
        die "SwiftUIPreviewClient build failed"
    }

syntax="$scratch/build/checkouts/swift-syntax"
[[ $(git -C "$syntax" rev-parse HEAD) == "$swift_syntax_revision" ]] \
    || die "resolved SwiftSyntax revision drifted"
[[ $(git -C "$syntax" rev-parse 'HEAD^{tree}') == "$swift_syntax_tree" ]] \
    || die "resolved SwiftSyntax tree drifted"

bin_path=$(swift build --package-path "$scratch/fixture" \
    --scratch-path "$scratch/build" --show-bin-path | tail -1)
plugin="$bin_path/OpenUIKitPreviewMacros-tool"
client="$scratch/fixture/Sources/SwiftUIPreviewClient/Client.swift"
[[ -x "$plugin" ]] || die "Preview host plugin is missing"

swiftc -typecheck -parse-as-library -module-name SwiftUIPreviewClient \
    -I "$bin_path/Modules" \
    -Xcc "-fmodule-map-file=$candidate/Sources/CQuartz/include/module.modulemap" \
    -Xcc "-I$candidate/Sources/CQuartz/include" \
    -Xcc "-fmodule-map-file=$bin_path/CSTBTrueType.build/module.modulemap" \
    -Xcc "-fmodule-map-file=$bin_path/CPortableIO.build/module.modulemap" \
    -load-plugin-executable "$plugin#OpenUIKitPreviewMacros" \
    -Xfrontend -dump-macro-expansions "$client" \
    >"$scratch/expansion.stdout" 2>"$scratch/expansion.stderr"
[[ ! -s "$scratch/expansion.stdout" ]] \
    || die "macro expansion unexpectedly wrote stdout"
[[ $(grep -c 'DeveloperToolsSupport.PreviewRegistry' \
    "$scratch/expansion.stderr") -eq 2 ]] \
    || die "expected named and unnamed PreviewRegistry expansions"
grep -Fq 'DeveloperToolsSupport.Preview(body: {' "$scratch/expansion.stderr" \
    || die "typed Preview body construction is missing"
grep -Fq 'Text("Unnamed")' "$scratch/expansion.stderr" \
    || die "unnamed Preview body is missing"
grep -Fq 'Text("Named")' "$scratch/expansion.stderr" \
    || die "named Preview body is missing"
! grep -Fq 'error:' "$scratch/expansion.stderr" \
    || die "macro expansion produced an error diagnostic"

case "$(uname -s)" in
    Darwin) file "$plugin" | grep -Fq 'Mach-O 64-bit executable arm64' \
        || die "host plugin is not native arm64 Mach-O" ;;
    Linux) file "$plugin" | grep -Fq 'ELF 64-bit' \
        || die "host plugin is not native ELF" ;;
    *) die "unsupported host: $(uname -s)" ;;
esac

[[ $(git -C "$candidate" status --porcelain=v1 --untracked-files=all) \
    == "$status_before" ]] || die "candidate status changed during proof"
[[ $(git -C "$candidate" rev-parse HEAD) == "$head_before" ]] \
    || die "candidate HEAD changed during proof"
[[ $(git -C "$candidate" rev-parse HEAD^{tree}) == "$tree_before" ]] \
    || die "candidate tree changed during proof"

echo "swiftui-preview.host=$(uname -s)"
echo "swiftui-preview.compiler=$(swiftc --version 2>&1 | head -1)"
echo "swiftui-preview.plugin_sha256=$(shasum -a 256 "$plugin" | awk '{print $1}')"
echo "swiftui-preview.expansion_sha256=$(shasum -a 256 "$scratch/expansion.stderr" | awk '{print $1}')"
echo "SWIFTUI_PREVIEW_COMPILE_ONLY_OK forms=named,unnamed registries=2 host=none"
