#!/usr/bin/env bash
# Fail-closed host-plugin and target-side #Preview proof. The package fixture is
# copied into a private scratch directory so dependency resolution never writes
# Package.resolved or .build into the OpenUIKit checkout.

set -euo pipefail
umask 077

die() {
    echo "previewprobe: $*" >&2
    exit 2
}

[[ $# -eq 1 ]] || die "usage: $0 /path/to/OpenUIKit"

script_dir=$(cd "$(dirname "$0")" && pwd -P)
candidate=$(cd "$1" && pwd -P)
fixture_source="$script_dir/Fixture"
expected="$script_dir/expected.txt"
swift_syntax_revision=4799286537280063c85a32f09884cfbca301b1a1
swift_syntax_tree=4c96b84ec6f59391ca70d18191500c14854d3d91

for tool in swift swiftc git cmp file shasum; do
    command -v "$tool" >/dev/null || die "required tool is missing: $tool"
done
[[ -f "$candidate/Package.swift" && ! -L "$candidate/Package.swift" ]] \
    || die "candidate Package.swift is not a regular file"
[[ ! -e "$candidate/Package.resolved" && ! -e "$candidate/.build" ]] \
    || die "candidate contains stale build/resolution residue"

status_before=$(git -C "$candidate" status --porcelain=v1 --untracked-files=all)
head_before=$(git -C "$candidate" rev-parse HEAD)
tree_before=$(git -C "$candidate" rev-parse HEAD^{tree})

scratch=$(mktemp -d "${TMPDIR:-/tmp}/open-uikit-preview-probe.XXXXXX")
cleanup() {
    if [[ "${OPENUIKIT_PREVIEW_KEEP_OUTPUT:-0}" == "1" ]]; then
        echo "preview.scratch=$scratch"
    else
        rm -rf -- "$scratch"
    fi
}
trap cleanup EXIT

cp -R "$fixture_source" "$scratch/fixture"
export OPENUIKIT_PREVIEW_ROOT="$candidate"

build_log="$scratch/build.log"
swift build --package-path "$scratch/fixture" --scratch-path "$scratch/build" \
    --product PreviewRuntime --disable-index-store -Xswiftc -gnone \
    >"$build_log" 2>&1 || {
        cat "$build_log" >&2
        die "PreviewRuntime build failed"
    }
[[ $(git -C "$scratch/build/checkouts/swift-syntax" rev-parse HEAD) \
    == "$swift_syntax_revision" ]] \
    || die "resolved SwiftSyntax revision drifted"
[[ $(git -C "$scratch/build/checkouts/swift-syntax" rev-parse 'HEAD^{tree}') \
    == "$swift_syntax_tree" ]] \
    || die "resolved SwiftSyntax tree drifted"

bin_path=$(swift build --package-path "$scratch/fixture" \
    --scratch-path "$scratch/build" --show-bin-path | tail -1)
plugin="$bin_path/OpenUIKitPreviewMacros-tool"
runtime="$bin_path/PreviewRuntime"
[[ -x "$plugin" && -x "$runtime" ]] \
    || die "plugin or runtime executable is missing"

"$runtime" >"$scratch/runtime.stdout" 2>"$scratch/runtime.stderr"
[[ ! -s "$scratch/runtime.stderr" ]] || {
    cat "$scratch/runtime.stderr" >&2
    die "runtime wrote stderr"
}
cmp -s "$expected" "$scratch/runtime.stdout" \
    || die "runtime output diverged"

module_dir="$bin_path/Modules"
client="$scratch/fixture/Sources/PreviewClient/Client.swift"
common=(
    -parse-as-library
    -module-name PreviewClient
    -I "$module_dir"
    -Xcc "-fmodule-map-file=$candidate/Sources/CQuartz/include/module.modulemap"
    -Xcc "-I$candidate/Sources/CQuartz/include"
    -Xcc "-fmodule-map-file=$bin_path/CSTBTrueType.build/module.modulemap"
    -Xcc "-fmodule-map-file=$bin_path/CPortableIO.build/module.modulemap"
)

swiftc -typecheck "${common[@]}" \
    -load-plugin-executable "$plugin#OpenUIKitPreviewMacros" \
    -Xfrontend -dump-macro-expansions "$client" \
    >"$scratch/expansion.stdout" 2>"$scratch/expansion.stderr"
[[ ! -s "$scratch/expansion.stdout" ]] \
    || die "macro expansion unexpectedly wrote stdout"
[[ "$(grep -c 'DeveloperToolsSupport.PreviewRegistry' "$scratch/expansion.stderr")" -eq 2 ]] \
    || die "expected two PreviewRegistry expansions"
grep -Fq '"PreviewClient/Client.swift"' "$scratch/expansion.stderr" \
    || die "fileID metadata drifted"
grep -Fq 'static var line: Int {' "$scratch/expansion.stderr" \
    || die "line metadata is missing"
grep -Fq 'DeveloperToolsSupport.Preview(body: {' "$scratch/expansion.stderr" \
    || die "functional Preview construction is missing"
grep -Fq 'return __b_buildContent {' "$scratch/expansion.stderr" \
    || die "single-expression body wrapper is missing"

set +e
swiftc -typecheck "${common[@]}" "$client" \
    >"$scratch/missing-plugin.stdout" 2>"$scratch/missing-plugin.stderr"
missing_plugin_status=$?
set -e
[[ "$missing_plugin_status" -ne 0 ]] \
    || die "client unexpectedly compiled without the host plugin"
grep -Fq "plugin for module 'OpenUIKitPreviewMacros' not found" \
    "$scratch/missing-plugin.stderr" \
    || die "missing-plugin diagnostic drifted"

for negative in NamedNegative BodyNegative SPINegative; do
    set +e
    swift build --package-path "$scratch/fixture" --scratch-path "$scratch/build" \
        --target "$negative" --disable-index-store -Xswiftc -gnone \
        >"$scratch/$negative.stdout" 2>"$scratch/$negative.stderr"
    negative_status=$?
    set -e
    [[ "$negative_status" -ne 0 ]] \
        || die "$negative unexpectedly compiled"
done
grep -Fq "no exact matches in call to macro 'Preview'" \
    "$scratch/NamedNegative.stdout" "$scratch/NamedNegative.stderr" \
    || die "named-preview fail-closed diagnostic drifted"
grep -Fq "This builder requires exactly one content expression" \
    "$scratch/BodyNegative.stdout" "$scratch/BodyNegative.stderr" \
    || die "multi-expression Preview fail-closed diagnostic drifted"
grep -Fq "inaccessible due to '@_spi' protection level" \
    "$scratch/SPINegative.stdout" "$scratch/SPINegative.stderr" \
    || die "SPI protection diagnostic drifted"

case "$(uname -s)" in
    Darwin)
        swiftc -c "${common[@]}" -target arm64-apple-macosx15.0 \
            -load-plugin-executable "$plugin#OpenUIKitPreviewMacros" \
            "$client" -o "$scratch/preview-client.o"
        file "$plugin" | grep -Fq 'Mach-O 64-bit executable arm64' \
            || die "host plugin is not native arm64 Mach-O"
        file "$scratch/preview-client.o" | grep -Fq 'Mach-O 64-bit object arm64' \
            || die "explicit target artifact is not arm64 Mach-O"
        ;;
    Linux)
        file "$plugin" | grep -Fq 'ELF 64-bit' \
            || die "host plugin is not native ELF"
        file "$runtime" | grep -Fq 'ELF 64-bit' \
            || die "runtime is not native ELF"
        ;;
    *) die "unsupported host: $(uname -s)" ;;
esac

[[ "$(git -C "$candidate" status --porcelain=v1 --untracked-files=all)" == "$status_before" ]] \
    || die "candidate status changed during proof"
[[ "$(git -C "$candidate" rev-parse HEAD)" == "$head_before" ]] \
    || die "candidate HEAD changed during proof"
[[ "$(git -C "$candidate" rev-parse HEAD^{tree})" == "$tree_before" ]] \
    || die "candidate tree changed during proof"
[[ ! -e "$candidate/Package.resolved" && ! -e "$candidate/.build" ]] \
    || die "proof left candidate build/resolution residue"

cat "$scratch/runtime.stdout"
echo "preview.host=$(uname -s)"
echo "preview.compiler=$(swiftc --version 2>&1 | head -1)"
echo "preview.candidate_head=$head_before"
echo "preview.candidate_tree=$tree_before"
echo "preview.swift_syntax_revision=$swift_syntax_revision"
echo "preview.swift_syntax_tree=$swift_syntax_tree"
echo "preview.plugin_sha256=$(shasum -a 256 "$plugin" | awk '{print $1}')"
echo "preview.runtime_sha256=$(shasum -a 256 "$runtime" | awk '{print $1}')"
echo "preview.expansion_sha256=$(shasum -a 256 "$scratch/expansion.stderr" | awk '{print $1}')"
echo "PREVIEW_PROBE_OK"
