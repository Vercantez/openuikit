#!/usr/bin/env bash
# Compile every frozen Swift source, package a relocatable .app, and cold-run
# it as an arm64 Mach-O guest on Linux. Application/vendor trees are mounted
# read-only; every derived root is caller-supplied and must not exist.
set -euo pipefail

SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
SUPPORT_ROOT=$(cd -- "$SCRIPT_DIR/../.." && pwd)
PREVIEW_EXECUTABLE_EXPORT_SYMBOL='_$s21DeveloperToolsSupport7PreviewV14_openUIKitBodyACypyScMYcc_tcfC'

die() {
    echo "portable-application-guest: $*" >&2
    exit 2
}

usage() {
    cat >&2 <<'EOF'
usage: build_portable_application_guest.sh \
  --inventory INVENTORY_JSON \
  --source-root APPLICATION_PROJECT_ROOT \
  --platform-package CORE_GUEST_PACKAGE \
  --container-image SHA256_IMAGE_ID \
  [--preview-plugin OPENUIKIT_PREVIEW_MACROS_TOOL] \
  --output-root ABSOLUTE_NONEXISTENT_DIRECTORY
EOF
    exit 2
}

require_regular() {
    local path=$1 label=$2
    [ -f "$path" ] && [ ! -L "$path" ] || die "$label is not a regular file: $path"
}

require_directory() {
    local path=$1 label=$2
    [ -d "$path" ] && [ ! -L "$path" ] || die "$label is not an ordinary directory: $path"
}

nm_symbol_count() {
    local mode=$1 path=$2 symbol=$3
    llvm-nm-18 "$mode" --extern-only --just-symbol-name "$path" 2>/dev/null \
        | awk -v expected="$symbol" '$0 == expected { count++ } END { print count + 0 }'
}

nm_developer_tools_support_count() {
    local mode=$1 path=$2
    llvm-nm-18 "$mode" --extern-only --just-symbol-name "$path" 2>/dev/null \
        | awk 'index($0, "DeveloperToolsSupport") { count++ } END { print count + 0 }'
}

canonical_existing() {
    python3 - "$1" <<'PY'
from pathlib import Path
import sys
print(Path(sys.argv[1]).resolve(strict=True))
PY
}

prepare_host() {
    local inventory= source_root= platform= container_image= plugin= output=
    while [ "$#" -gt 0 ]; do
        case "$1" in
            --inventory) [ "$#" -ge 2 ] || usage; inventory=$2; shift 2 ;;
            --source-root) [ "$#" -ge 2 ] || usage; source_root=$2; shift 2 ;;
            --platform-package) [ "$#" -ge 2 ] || usage; platform=$2; shift 2 ;;
            --container-image) [ "$#" -ge 2 ] || usage; container_image=$2; shift 2 ;;
            --preview-plugin) [ "$#" -ge 2 ] || usage; plugin=$2; shift 2 ;;
            --output-root) [ "$#" -ge 2 ] || usage; output=$2; shift 2 ;;
            *) usage ;;
        esac
    done
    [ -n "$inventory" ] && [ -n "$source_root" ] && [ -n "$platform" ] \
        && [ -n "$container_image" ] && [ -n "$output" ] || usage
    command -v python3 >/dev/null || die "python3 is required"
    command -v docker >/dev/null || die "docker is required"
    command -v git >/dev/null || die "git is required"
    [ "${#container_image}" -eq 71 ] \
        || die "container image must be an exact sha256 content ID"
    case "$container_image" in
        sha256:*[!0-9a-f]*|*[!0-9a-f])
            die "container image must be an exact lowercase sha256 content ID" ;;
        sha256:*) ;;
        *) die "container image must be an exact sha256 content ID" ;;
    esac
    local actual_image_id image_platform
    actual_image_id=$(docker image inspect --format '{{.Id}}' "$container_image" 2>/dev/null) \
        || die "container image is unavailable: $container_image"
    [ "$actual_image_id" = "$container_image" ] \
        || die "container image identity differs: $actual_image_id"
    image_platform=$(docker image inspect --format '{{.Os}}/{{.Architecture}}' \
        "$container_image")
    [ "$image_platform" = linux/arm64 ] \
        || die "container image platform is $image_platform, expected linux/arm64"
    local support_commit support_tree support_status
    support_commit=$(git -C "$SUPPORT_ROOT" rev-parse --verify HEAD^{commit})
    support_tree=$(git -C "$SUPPORT_ROOT" rev-parse --verify HEAD^{tree})
    support_status=$(git -C "$SUPPORT_ROOT" status --porcelain=v1 --untracked-files=all)
    [ -z "$support_status" ] || die "support checkout is not clean: $support_status"

    inventory=$(canonical_existing "$inventory")
    source_root=$(canonical_existing "$source_root")
    platform=$(canonical_existing "$platform")
    [ -z "$plugin" ] || plugin=$(canonical_existing "$plugin")
    require_regular "$inventory" "inventory"
    require_directory "$source_root" "application source root"
    require_directory "$platform" "core guest package"
    [ -z "$plugin" ] || require_regular "$plugin" "Preview macro plugin"
    case "$output" in /*) ;; *) die "output root must be absolute" ;; esac
    [ ! -e "$output" ] && [ ! -L "$output" ] \
        || die "output root already exists: $output"
    local output_parent output_name
    output_parent=$(dirname -- "$output")
    output_name=$(basename -- "$output")
    require_directory "$output_parent" "output parent"
    output_parent=$(canonical_existing "$output_parent")
    output=$output_parent/$output_name

    python3 "$SCRIPT_DIR/core_guest_package.py" "$platform" --emit-summary
    local preview_required expected_plugin_sha actual_plugin_sha
    read -r preview_required expected_plugin_sha < <(
        PYTHONPATH="$SCRIPT_DIR" python3 - "$platform" <<'PY'
from pathlib import Path
import core_guest_package
import sys
_root, manifest = core_guest_package.validate(Path(sys.argv[1]))
preview = manifest["preview"]
print("yes", preview["plugin_sha256"] if preview else "-") if preview else print("no -")
PY
    )
    if [ "$preview_required" = yes ]; then
        [ -n "$plugin" ] || die "core package requires --preview-plugin"
        [ -x "$plugin" ] || die "Preview macro plugin is not executable: $plugin"
        actual_plugin_sha=$(shasum -a 256 "$plugin" | awk '{print $1}')
        [ "$actual_plugin_sha" = "$expected_plugin_sha" ] \
            || die "Preview macro plugin hash differs from core package"
    elif [ -n "$plugin" ]; then
        die "--preview-plugin supplied but core package has no Preview contract"
    fi

    python3 "$SCRIPT_DIR/application_build_plan.py" "$inventory" \
        --source-root "$source_root" --output-dir "$output"
    python3 "$SCRIPT_DIR/application_build_plan.py" \
        "$output/application-build-plan.json" --source-root "$source_root" --verify

    local product platform_resources output_app
    product=$(python3 - "$output/application-build-plan.json" <<'PY'
import json
from pathlib import Path
import sys
value = json.loads(Path(sys.argv[1]).read_text(encoding="utf-8"))["product_name"]
if not isinstance(value, str) or not value or "/" in value or "\0" in value or "\n" in value:
    raise SystemExit("unsafe product name")
print(value)
PY
    )
    platform_resources=$(
        PYTHONPATH="$SCRIPT_DIR" python3 - "$platform" <<'PY'
from pathlib import Path
import core_guest_package
import sys
root, manifest = core_guest_package.validate(Path(sys.argv[1]))
print(root / manifest["paths"]["resources"])
PY
    )
    output_app=$output/$product.app
    python3 "$SCRIPT_DIR/materialize_application_bundle.py" \
        "$output/application-build-plan.json" --source-root "$source_root" \
        --platform-resources "$platform_resources" --output-app "$output_app" \
        --attestation "$output/bundle-materialization.json"

    {
        printf 'support_commit\t%s\n' "$support_commit"
        printf 'support_tree\t%s\n' "$support_tree"
        printf 'inventory_sha256\t%s\n' "$(shasum -a 256 "$inventory" | awk '{print $1}')"
        printf 'core_manifest_sha256\t%s\n' \
            "$(shasum -a 256 "$platform/attestation/core-package.json" | awk '{print $1}')"
        printf 'container_image\t%s\tplatform=%s\n' \
            "$container_image" "$image_platform"
        if [ -n "$plugin" ]; then
            printf 'preview_plugin_sha256\t%s\n' "$expected_plugin_sha"
        fi
    } >"$output/host-inputs.tsv"

    local -a docker_command
    docker_command=(docker run --rm --platform linux/arm64
        -v "$SUPPORT_ROOT:/support:ro"
        -v "$source_root:/app:ro"
        -v "$platform:/platform:ro"
        -v "$output:/output"
        -w /platform)
    if [ -n "$plugin" ]; then
        docker_command+=(-v "$plugin:/preview-plugin:ro")
    fi
    docker_command+=("$container_image"
        bash /support/full/xcodeplan/build_portable_application_guest.sh
        --inside /app /output /platform)
    if [ -n "$plugin" ]; then
        docker_command+=(/preview-plugin)
    fi

    set +e
    "${docker_command[@]}" 2>&1 | tee "$output/driver.log"
    local -a statuses=("${PIPESTATUS[@]}")
    set -e
    python3 "$SCRIPT_DIR/application_build_plan.py" \
        "$output/application-build-plan.json" --source-root "$source_root" --verify
    [ "$(git -C "$SUPPORT_ROOT" rev-parse --verify HEAD^{commit})" = "$support_commit" ] \
        && [ "$(git -C "$SUPPORT_ROOT" rev-parse --verify HEAD^{tree})" = "$support_tree" ] \
        || die "support checkout identity changed during build"
    support_status=$(git -C "$SUPPORT_ROOT" status --porcelain=v1 --untracked-files=all)
    [ -z "$support_status" ] || die "support checkout changed during build: $support_status"
    [ "${statuses[0]}" -eq 0 ] && [ "${statuses[1]}" -eq 0 ] \
        || die "container/tee failed: docker=${statuses[0]} tee=${statuses[1]}"
    grep -Fx 'PORTABLE_APPLICATION_GUEST_OK' "$output/driver.log" >/dev/null \
        || die "driver success marker is missing"
    echo "PORTABLE_APPLICATION_HOST_OK output=$output"
}

build_inside() {
    [ "$#" -eq 3 ] || [ "$#" -eq 4 ] || die "invalid internal invocation"
    local app_root=$1 output=$2 platform=$3 plugin=${4:-}
    require_directory "$app_root" "mounted application source root"
    require_directory "$output" "mounted output root"
    require_directory "$platform" "mounted platform package"
    for tool in python3 swiftc ld64.lld-18 llvm-nm-18 llvm-otool-18 file sha256sum perl; do
        command -v "$tool" >/dev/null || die "required container tool is missing: $tool"
    done
    PYTHONPATH="$SCRIPT_DIR" python3 "$SCRIPT_DIR/core_guest_package.py" \
        "$platform" --emit-summary
    python3 "$SCRIPT_DIR/application_build_plan.py" \
        "$output/application-build-plan.json" --source-root "$app_root" --verify

    local module product preview_required expected_plugin_sha plugin_module dts_object
    local -a metadata
    mapfile -d '' -t metadata < <(
        PYTHONPATH="$SCRIPT_DIR" python3 - "$platform" \
            "$output/application-build-plan.json" <<'PY'
import json
from pathlib import Path
import core_guest_package
import sys
_root, manifest = core_guest_package.validate(Path(sys.argv[1]))
plan = json.loads(Path(sys.argv[2]).read_text(encoding="utf-8"))
preview = manifest["preview"]
module = plan["module"]
product = plan["product_name"]
if not isinstance(module, str) or not module.isidentifier() or not module.isascii():
    raise SystemExit("module is not a portable Swift identifier")
if not isinstance(product, str) or not product or any(c in product for c in "/\r\n\0"):
    raise SystemExit("product is not a safe application basename")
values = [module, product]
if preview:
    values.extend(["yes", preview["plugin_sha256"], preview["plugin_module"], preview["developer_tools_support_object"]])
else:
    values.extend(["no", "-", "-", "-"])
sys.stdout.buffer.write(b"".join(value.encode("utf-8") + b"\0" for value in values))
PY
    )
    [ "${#metadata[@]}" -eq 6 ] || die "invalid application/platform metadata"
    module=${metadata[0]}
    product=${metadata[1]}
    preview_required=${metadata[2]}
    expected_plugin_sha=${metadata[3]}
    plugin_module=${metadata[4]}
    dts_object=${metadata[5]}
    if [ "$preview_required" = yes ]; then
        require_regular "$plugin" "mounted Preview macro plugin"
        [ -x "$plugin" ] || die "mounted Preview macro plugin is not executable"
        local plugin_sha
        plugin_sha=$(sha256sum "$plugin" | awk '{print $1}')
        [ "$plugin_sha" = "$expected_plugin_sha" ] \
            || die "mounted Preview macro plugin hash differs"
        file "$plugin" | grep -Eq 'ELF 64-bit.*(ARM aarch64|aarch64)' \
            || die "Preview macro plugin is not a Linux aarch64 ELF executable"
        require_regular "$platform/$dts_object" "DeveloperToolsSupport target object"
    elif [ -n "$plugin" ]; then
        die "mounted Preview plugin without package Preview contract"
    fi

    local -a swift_arguments link_arguments diagnostic_arguments relative_sources app_sources
    mapfile -d '' -t swift_arguments < <(
        PYTHONPATH="$SCRIPT_DIR" python3 "$SCRIPT_DIR/core_guest_package.py" \
            "$platform" --emit-swift-arguments
    )
    mapfile -d '' -t link_arguments < <(
        PYTHONPATH="$SCRIPT_DIR" python3 "$SCRIPT_DIR/core_guest_package.py" \
            "$platform" --emit-link-arguments
    )
    mapfile -d '' -t diagnostic_arguments < <(
        PYTHONPATH="$SCRIPT_DIR" python3 "$SCRIPT_DIR/core_guest_package.py" \
            "$platform" --emit-app-diagnostic-arguments
    )
    mapfile -d '' -t relative_sources <"$output/app-sources.nul"
    [ "${#relative_sources[@]}" -gt 0 ] || die "application source list is empty"
    local relative source
    for relative in "${relative_sources[@]}"; do
        case "$relative" in /*|*../*|../*|*/..) die "unsafe application source path: $relative" ;; esac
        source=$app_root/$relative
        require_regular "$source" "application source"
        app_sources+=("$source")
    done

    local module_cache=$output/module-cache object=$output/application.o
    [ ! -e "$module_cache" ] && [ ! -L "$module_cache" ] \
        || die "module cache already exists"
    [ ! -e "$object" ] && [ ! -L "$object" ] || die "application object already exists"
    mkdir "$module_cache"
    local -a plugin_arguments=()
    if [ "$preview_required" = yes ]; then
        plugin_arguments=(-load-plugin-executable "$plugin#$plugin_module")
    fi

    local -a platform_sources=(
        "$output/GeneratedSceneBootstrap.swift"
        "$SCRIPT_DIR/PortableUIKitApplicationHost.swift"
        "$SUPPORT_ROOT/full/driver/RunLoop.swift"
    )
    local -a compile_sources=("${app_sources[@]}" "${platform_sources[@]}")
    local -a application_codegen_arguments=(-wmo)
    local argument effective_wmo_count=0
    for argument in "${swift_arguments[@]}" \
        "${application_codegen_arguments[@]}"; do
        case "$argument" in
            -wmo) effective_wmo_count=$((effective_wmo_count + 1)) ;;
            -whole-module-optimization)
                die "application whole-module flag must use canonical -wmo" ;;
        esac
    done
    [ "${#compile_sources[@]}" -gt 1 ] \
        || die "application compile unexpectedly has fewer than two sources"
    [ "$effective_wmo_count" -eq 1 ] \
        || die "application effective -wmo count $effective_wmo_count, expected 1"
    {
        printf 'format\tportable-application-compile-audit-v1\n'
        printf 'source-count\t%s\n' "${#compile_sources[@]}"
        printf 'whole-module-flag\t-wmo\tcount=%s\n' "$effective_wmo_count"
        printf 'output\tapplication.o\n'
    } >"$output/application-compile-audit.tsv"

    local compile_stderr=$output/app-macro-expansions.stderr compile_status
    [ ! -e "$compile_stderr" ] && [ ! -L "$compile_stderr" ] \
        || die "application compiler diagnostic output already exists"
    echo "== compile every untouched application source"
    set +e
    (
        cd "$platform"
        swiftc "${swift_arguments[@]}" -module-cache-path "$module_cache" \
            "${application_codegen_arguments[@]}" \
            -default-isolation MainActor -module-name "$module" \
            "${plugin_arguments[@]}" "${diagnostic_arguments[@]}" \
            -emit-object -o "$object" \
            "${compile_sources[@]}"
    ) 2>"$compile_stderr"
    compile_status=$?
    set -e
    cat "$compile_stderr" >&2
    [ "$compile_status" -eq 0 ] \
        || die "application compiler exited $compile_status"
    if grep -Eq ':[0-9]+:[0-9]+: error:' "$compile_stderr"; then
        die "application compiler emitted an error diagnostic despite success"
    fi

    local app=$output/$product.app frameworks=$app/Contents/Frameworks
    local executable=$app/Contents/MacOS/$product libraries
    require_directory "$frameworks" "application Frameworks directory"
    [ ! -e "$executable" ] && [ ! -L "$executable" ] \
        || die "application executable already exists"
    libraries=$(PYTHONPATH="$SCRIPT_DIR" python3 - "$platform" <<'PY'
from pathlib import Path
import core_guest_package
import sys
root, manifest = core_guest_package.validate(Path(sys.argv[1]))
print(root / manifest["paths"]["libraries"])
PY
    )
    local library basename
    while IFS= read -r -d '' library; do
        [ ! -L "$library" ] || die "core library is a symlink: $library"
        basename=$(basename -- "$library")
        [ ! -e "$frameworks/$basename" ] && [ ! -L "$frameworks/$basename" ] \
            || die "framework destination already exists: $basename"
        cp "$library" "$frameworks/$basename"
        chmod 0755 "$frameworks/$basename"
        cmp -s "$library" "$frameworks/$basename" \
            || die "copied framework differs from core package: $basename"
    done < <(find "$libraries" -maxdepth 1 -type f -name '*.dylib' -print0 | sort -z)
    find "$frameworks" -maxdepth 1 -type f -name '*.dylib' -print -quit | grep -q . \
        || die "core package contains no dylibs"

    local -a extra_objects=()
    local uikit_preview_import_count uikit_dts_import_count
    uikit_preview_import_count=$(nm_symbol_count --undefined-only \
        "$libraries/libUIKit.dylib" "$PREVIEW_EXECUTABLE_EXPORT_SYMBOL")
    uikit_dts_import_count=$(nm_developer_tools_support_count --undefined-only \
        "$libraries/libUIKit.dylib")
    if [ "$preview_required" = yes ]; then
        extra_objects+=("$platform/$dts_object")
        [ "$uikit_preview_import_count" -eq 1 ] \
            || die "Preview libUIKit initializer import count $uikit_preview_import_count, expected 1"
        [ "$uikit_dts_import_count" -eq 1 ] \
            || die "Preview libUIKit DeveloperToolsSupport import count $uikit_dts_import_count, expected 1"
        local preview_definition_count
        preview_definition_count=$(nm_symbol_count --defined-only \
            "${extra_objects[0]}" "$PREVIEW_EXECUTABLE_EXPORT_SYMBOL")
        [ "$preview_definition_count" -eq 1 ] \
            || die "Preview DTS initializer definition count $preview_definition_count, expected 1"
    else
        [ "$uikit_preview_import_count" -eq 0 ] \
            || die "non-Preview libUIKit imports the Preview initializer"
        [ "$uikit_dts_import_count" -eq 0 ] \
            || die "non-Preview libUIKit imports DeveloperToolsSupport"
    fi
    {
        printf 'app_object\t%s\t%s\n' "$(sha256sum "$object" | awk '{print $1}')" "$object"
        if [ "$preview_required" = yes ]; then
            [ "${#extra_objects[@]}" -eq 1 ] \
                || die "DeveloperToolsSupport object link count is not one"
            printf 'developer_tools_support_object\t%s\t%s\n' \
                "$(sha256sum "${extra_objects[0]}" | awk '{print $1}')" \
                "${extra_objects[0]}"
        fi
    } >"$output/application-link-objects.tsv"
    local -a executable_export_arguments=(-exported_symbol __mh_execute_header)
    if [ "$preview_required" = yes ]; then
        executable_export_arguments+=(
            -exported_symbol "$PREVIEW_EXECUTABLE_EXPORT_SYMBOL"
        )
    fi
    echo "== link relocatable application executable"
    (
        cd "$platform"
        ld64.lld-18 "${link_arguments[@]}" -dead_strip \
            "${executable_export_arguments[@]}" \
            -rpath @executable_path/../Frameworks \
            -o "$executable" "$object" "${extra_objects[@]}"
    )
    chmod 0755 "$executable"
    file "$executable" | tee "$output/executable-file.txt"
    llvm-otool-18 -hv "$executable" | grep -Eq \
        'MH_MAGIC_64[[:space:]]+ARM64.*[[:space:]]EXECUTE' \
        || die "linked application is not an ARM64 Mach-O executable"
    local executable_preview_export_count executable_dts_export_count expected_export_count
    executable_preview_export_count=$(nm_symbol_count --defined-only \
        "$executable" "$PREVIEW_EXECUTABLE_EXPORT_SYMBOL")
    executable_dts_export_count=$(nm_developer_tools_support_count --defined-only \
        "$executable")
    expected_export_count=0
    [ "$preview_required" != yes ] || expected_export_count=1
    [ "$executable_preview_export_count" -eq "$expected_export_count" ] \
        || die "application Preview initializer export count $executable_preview_export_count, expected $expected_export_count"
    [ "$executable_dts_export_count" -eq "$expected_export_count" ] \
        || die "application DeveloperToolsSupport export count $executable_dts_export_count, expected $expected_export_count"
    {
        printf 'libUIKit_preview_initializer_import_count\t%s\n' \
            "$uikit_preview_import_count"
        printf 'executable_preview_initializer_export_count\t%s\n' \
            "$executable_preview_export_count"
    } >>"$output/application-link-objects.tsv"

    local guest_root
    guest_root=$(PYTHONPATH="$SCRIPT_DIR" python3 - "$platform" <<'PY'
from pathlib import Path
import core_guest_package
import sys
root, manifest = core_guest_package.validate(Path(sys.argv[1]))
print(root / manifest["paths"]["guest_root"])
PY
    )
    perl "$SUPPORT_ROOT/full/swiftui/focus_widget_guest_attest.pl" closure \
        --otool llvm-otool-18 --executable "$executable" \
        --package "$frameworks" --guest-root "$guest_root" \
        >"$output/runtime-closure.manifest"

    echo "== cold-launch packaged application under machorun"
    (
        cd "$output"
        MACHORUN_ROOT="$guest_root" OPENUIKIT_HOST_TURNS=3 \
            "$guest_root/machorun" "$executable"
    ) | tee "$output/runtime.log"
    grep -Fx 'PORTABLE_UIKIT_HOST_ACTIVE windows=1' "$output/runtime.log" >/dev/null \
        || die "application did not reach one active UIWindow"
    grep -Fx 'PORTABLE_UIKIT_HOST_LOOP_OK turns=3 paced=true' "$output/runtime.log" >/dev/null \
        || die "application did not complete three production host-loop turns"

    python3 "$SCRIPT_DIR/application_build_plan.py" \
        "$output/application-build-plan.json" --source-root "$app_root" --verify
    if [ "$preview_required" = yes ]; then
        [ "$(sha256sum "$plugin" | awk '{print $1}')" = "$expected_plugin_sha" ] \
            || die "Preview macro plugin changed during build"
    fi
    (
        cd "$output"
        find "$product.app" -type f -print0 | sort -z | xargs -0 sha256sum \
            >application-files.sha256
        sha256sum application.o app-macro-expansions.stderr \
            application-compile-audit.tsv application-link-objects.tsv \
            runtime-closure.manifest runtime.log \
            >application-build-artifacts.sha256
    )
    echo 'PORTABLE_APPLICATION_GUEST_OK'
}

if [ "${1:-}" = --inside ]; then
    shift
    build_inside "$@"
else
    prepare_host "$@"
fi
