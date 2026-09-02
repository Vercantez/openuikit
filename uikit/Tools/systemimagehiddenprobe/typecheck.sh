#!/bin/zsh
# Host-side Foundation-hidden ARM64 Mach-O compile closure. This emits modules
# and typechecks the literal-UIKit probe; linking/execution belongs to the
# serialized Linux machorun gate and is intentionally not claimed here.
set -euo pipefail

candidate_root="$(cd "$(dirname "$0")/../.." && pwd -P)"
support_root="${1:-$candidate_root/../swift-macho-linux}"
support_commit=777e7c083a90452841009f56eec959c098761113
sysroot_path="$support_root/scratch/sysroot_fe4"

[[ "$(git -C "$support_root" rev-parse HEAD)" == "$support_commit" ]]
[[ -z "$(git -C "$support_root" status --porcelain)" ]]
[[ -d "$sysroot_path/usr/include" ]]
[[ -f "$support_root/full/shims/FoundationNames.swift" ]]

probe_tmp="$(mktemp -d /private/tmp/system-image-hidden-source.XXXXXX)"
trap 'rm -rf -- "$probe_tmp"' EXIT

ocg_sources=($candidate_root/Sources/OpenCoreGraphics/**/*.swift(N))
oui_sources=($candidate_root/Sources/OpenUIKit/**/*.swift(N))
[[ ${#ocg_sources[@]} -eq 12 ]]
[[ ${#oui_sources[@]} -eq 101 ]]

common_flags=(
    -target arm64-apple-macos15.0
    -sdk "$sysroot_path"
    -module-cache-path "$probe_tmp/module-cache"
    -runtime-compatibility-version none
    -wmo
    -Xfrontend -disable-implicit-string-processing-module-import
    -Xfrontend -disable-objc-attr-requires-foundation-module
)
c_includes=(
    -Xcc -fmodule-map-file="$candidate_root/Sources/CQuartz/include/module.modulemap"
    -Xcc -I"$candidate_root/Sources/CQuartz/include"
    -Xcc -fmodule-map-file="$support_root/build/full/inc/CPortableIO/module.modulemap"
    -Xcc -I"$support_root/build/full/inc/CPortableIO"
    -Xcc -fmodule-map-file="$support_root/build/full/inc/CSTBTrueType/module.modulemap"
    -Xcc -I"$support_root/build/full/inc/CSTBTrueType"
)

swiftc "${common_flags[@]}" "${c_includes[@]}" \
    -module-name OpenCoreGraphics -emit-module \
    -emit-module-path "$probe_tmp/OpenCoreGraphics.swiftmodule" \
    "${ocg_sources[@]}"
swiftc "${common_flags[@]}" "${c_includes[@]}" -I "$probe_tmp" \
    -module-name OpenUIKit -emit-module \
    -emit-module-path "$probe_tmp/OpenUIKit.swiftmodule" \
    "${oui_sources[@]}" "$support_root/full/shims/FoundationNames.swift"
swiftc "${common_flags[@]}" "${c_includes[@]}" -I "$probe_tmp" \
    -module-name UIKit -emit-module \
    -emit-module-path "$probe_tmp/UIKit.swiftmodule" \
    "$candidate_root/Sources/UIKitShim/UIKit.swift"
swiftc "${common_flags[@]}" "${c_includes[@]}" -I "$probe_tmp" \
    -parse-as-library -typecheck \
    "$candidate_root/Tools/systemimagehiddenprobe/main.swift"

print "FOUNDATION_HIDDEN_LITERAL_UIKIT_SOURCE_OK symbols=6 openuikit=101 support=$support_commit"
print "scope=module-emission+typecheck linked=0 executed=0"
