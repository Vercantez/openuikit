#!/usr/bin/env bash
# Compile every frozen Swift source, package a relocatable .app, and cold-run
# it as an arm64 Mach-O guest on Linux. Application/vendor trees are mounted
# read-only; every derived root is caller-supplied and must not exist.
set -euo pipefail

SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
SUPPORT_ROOT=$(cd -- "$SCRIPT_DIR/../.." && pwd)
PREVIEW_EXECUTABLE_EXPORT_SYMBOL='_$s21DeveloperToolsSupport7PreviewV14_openUIKitBodyACypyScMYcc_tcfC'
source "$SCRIPT_DIR/swift_compiler_diagnostics.sh"

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
  [--remote-package-materializations EXACT_MATERIALIZATION_SET_JSON] \
  [--remote-package-cache CONTENT_ADDRESSED_CACHE_ROOT] \
  [--preview-plugin OPENUIKIT_PREVIEW_MACROS_TOOL] \
  [--preview-evidence-source-list NUL_TERMINATED_RELATIVE_PATHS] \
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
    python3 -B - "$1" <<'PY'
from pathlib import Path
import sys
print(Path(sys.argv[1]).resolve(strict=True))
PY
}

prepare_host() {
    local inventory= source_root= platform= container_image= plugin=
    local preview_source_list= remote_materializations= remote_cache= output=
    while [ "$#" -gt 0 ]; do
        case "$1" in
            --inventory) [ "$#" -ge 2 ] || usage; inventory=$2; shift 2 ;;
            --source-root) [ "$#" -ge 2 ] || usage; source_root=$2; shift 2 ;;
            --platform-package) [ "$#" -ge 2 ] || usage; platform=$2; shift 2 ;;
            --container-image) [ "$#" -ge 2 ] || usage; container_image=$2; shift 2 ;;
            --preview-plugin) [ "$#" -ge 2 ] || usage; plugin=$2; shift 2 ;;
            --remote-package-materializations)
                [ "$#" -ge 2 ] || usage
                remote_materializations=$2
                shift 2
                ;;
            --remote-package-cache)
                [ "$#" -ge 2 ] || usage
                remote_cache=$2
                shift 2
                ;;
            --preview-evidence-source-list)
                [ "$#" -ge 2 ] || usage
                preview_source_list=$2
                shift 2
                ;;
            --output-root) [ "$#" -ge 2 ] || usage; output=$2; shift 2 ;;
            *) usage ;;
        esac
    done
    [ -n "$inventory" ] && [ -n "$source_root" ] && [ -n "$platform" ] \
        && [ -n "$container_image" ] && [ -n "$output" ] || usage
    if [ -n "$remote_materializations" ] || [ -n "$remote_cache" ]; then
        [ -n "$remote_materializations" ] && [ -n "$remote_cache" ] \
            || die "remote materializations and cache must be supplied together"
    fi
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
    [ -z "$preview_source_list" ] \
        || preview_source_list=$(canonical_existing "$preview_source_list")
    [ -z "$remote_materializations" ] \
        || remote_materializations=$(canonical_existing "$remote_materializations")
    [ -z "$remote_cache" ] || remote_cache=$(canonical_existing "$remote_cache")
    require_regular "$inventory" "inventory"
    require_directory "$source_root" "application source root"
    require_directory "$platform" "core guest package"
    [ -z "$plugin" ] || require_regular "$plugin" "Preview macro plugin"
    [ -z "$preview_source_list" ] \
        || require_regular "$preview_source_list" "Preview evidence source list"
    [ -z "$remote_materializations" ] \
        || require_regular "$remote_materializations" "remote package materialization set"
    [ -z "$remote_cache" ] \
        || require_directory "$remote_cache" "remote package cache"
    case "$output" in /*) ;; *) die "output root must be absolute" ;; esac
    [ ! -e "$output" ] && [ ! -L "$output" ] \
        || die "output root already exists: $output"
    local output_parent output_name
    output_parent=$(dirname -- "$output")
    output_name=$(basename -- "$output")
    require_directory "$output_parent" "output parent"
    output_parent=$(canonical_existing "$output_parent")
    output=$output_parent/$output_name

    python3 -B "$SCRIPT_DIR/core_guest_package.py" "$platform" --emit-summary
    local preview_required expected_plugin_sha actual_plugin_sha
    local preview_source_list_sha=
    read -r preview_required expected_plugin_sha < <(
        PYTHONPATH="$SCRIPT_DIR" python3 -B - "$platform" <<'PY'
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
        [ -n "$preview_source_list" ] \
            || die "core package requires --preview-evidence-source-list"
        [ -x "$plugin" ] || die "Preview macro plugin is not executable: $plugin"
        actual_plugin_sha=$(shasum -a 256 "$plugin" | awk '{print $1}')
        [ "$actual_plugin_sha" = "$expected_plugin_sha" ] \
            || die "Preview macro plugin hash differs from core package"
        preview_source_list_sha=$(shasum -a 256 "$preview_source_list" | awk '{print $1}')
    elif [ -n "$plugin" ]; then
        die "--preview-plugin supplied but core package has no Preview contract"
    elif [ -n "$preview_source_list" ]; then
        die "--preview-evidence-source-list supplied without a Preview contract"
    fi

    local -a remote_plan_arguments=() remote_cache_arguments=()
    if [ -n "$remote_cache" ]; then
        remote_plan_arguments=(--remote-materializations "$remote_materializations"
            --remote-cache-root "$remote_cache")
        remote_cache_arguments=(--remote-cache-root "$remote_cache")
    fi
    python3 -B "$SCRIPT_DIR/application_build_plan.py" "$inventory" \
        --source-root "$source_root" --output-dir "$output" \
        "${remote_plan_arguments[@]}"
    python3 -B "$SCRIPT_DIR/application_build_plan.py" \
        "$output/application-build-plan.json" --source-root "$source_root" \
        "${remote_cache_arguments[@]}" --verify
    if [ -f "$output/local-package-graph.json" ] \
        && [ ! -L "$output/local-package-graph.json" ]; then
        require_regular "$output/local-package-targets.nul" \
            "local Swift-package target list"
        python3 -B "$SCRIPT_DIR/local_package_graph.py" verify-plan-binding \
            "$output/local-package-graph.json" \
            --application-plan "$output/application-build-plan.json" \
            --target-list "$output/local-package-targets.nul" \
            --source-root "$source_root" "${remote_cache_arguments[@]}"
        python3 -B "$SCRIPT_DIR/local_package_graph.py" require-buildable \
            "$output/local-package-graph.json" --source-root "$source_root" \
            "${remote_cache_arguments[@]}"
    fi
    if [ "$preview_required" = yes ]; then
        [ ! -e "$output/preview-evidence-sources.nul" ] \
            && [ ! -L "$output/preview-evidence-sources.nul" ] \
            || die "Preview evidence source-list destination already exists"
        cp "$preview_source_list" "$output/preview-evidence-sources.nul"
        require_regular "$output/preview-evidence-sources.nul" \
            "copied Preview evidence source list"
        [ "$(shasum -a 256 "$output/preview-evidence-sources.nul" | awk '{print $1}')" \
            = "$preview_source_list_sha" ] \
            || die "copied Preview evidence source list differs"
    fi

    local product platform_resources output_app
    product=$(python3 -B - "$output/application-build-plan.json" <<'PY'
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
        PYTHONPATH="$SCRIPT_DIR" python3 -B - "$platform" <<'PY'
from pathlib import Path
import core_guest_package
import sys
root, manifest = core_guest_package.validate(Path(sys.argv[1]))
print(root / manifest["paths"]["resources"])
PY
    )
    output_app=$output/$product.app
    python3 -B "$SCRIPT_DIR/materialize_application_bundle.py" \
        "$output/application-build-plan.json" --source-root "$source_root" \
        --platform-resources "$platform_resources" --output-app "$output_app" \
        --attestation "$output/bundle-materialization.json" \
        "${remote_cache_arguments[@]}"

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
            printf 'preview_evidence_source_list_sha256\t%s\n' \
                "$preview_source_list_sha"
        fi
        if [ -n "$remote_cache" ]; then
            printf 'remote_materializations_sha256\t%s\n' \
                "$(shasum -a 256 "$remote_materializations" | awk '{print $1}')"
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
    if [ -n "$remote_cache" ]; then
        docker_command+=(-v "$remote_cache:/remote-packages:ro")
    fi
    docker_command+=("$container_image"
        bash /support/full/xcodeplan/build_portable_application_guest.sh
        --inside /app /output /platform)
    if [ -n "$plugin" ]; then
        docker_command+=(--preview-plugin-inside /preview-plugin)
    fi
    if [ -n "$remote_cache" ]; then
        docker_command+=(--remote-package-cache-inside /remote-packages)
    fi

    set +e
    "${docker_command[@]}" 2>&1 | tee "$output/driver.log"
    local -a statuses=("${PIPESTATUS[@]}")
    set -e
    python3 -B "$SCRIPT_DIR/application_build_plan.py" \
        "$output/application-build-plan.json" --source-root "$source_root" \
        "${remote_cache_arguments[@]}" --verify
    [ "$(git -C "$SUPPORT_ROOT" rev-parse --verify HEAD^{commit})" = "$support_commit" ] \
        && [ "$(git -C "$SUPPORT_ROOT" rev-parse --verify HEAD^{tree})" = "$support_tree" ] \
        || die "support checkout identity changed during build"
    support_status=$(git -C "$SUPPORT_ROOT" status --porcelain=v1 --untracked-files=all)
    [ -z "$support_status" ] || die "support checkout changed during build: $support_status"
    if [ "$preview_required" = yes ]; then
        [ "$(shasum -a 256 "$preview_source_list" | awk '{print $1}')" \
            = "$preview_source_list_sha" ] \
            || die "Preview evidence source list changed during build"
        [ "$(shasum -a 256 "$output/preview-evidence-sources.nul" | awk '{print $1}')" \
            = "$preview_source_list_sha" ] \
            || die "copied Preview evidence source list changed during build"
    fi
    [ "${statuses[0]}" -eq 0 ] && [ "${statuses[1]}" -eq 0 ] \
        || die "container/tee failed: docker=${statuses[0]} tee=${statuses[1]}"
    grep -Fx 'PORTABLE_APPLICATION_GUEST_OK' "$output/driver.log" >/dev/null \
        || die "driver success marker is missing"
    echo "PORTABLE_APPLICATION_HOST_OK output=$output"
}

build_inside() {
    [ "$#" -ge 3 ] || die "invalid internal invocation"
    local app_root=$1 output=$2 platform=$3 plugin= remote_cache=
    shift 3
    while [ "$#" -gt 0 ]; do
        case "$1" in
            --preview-plugin-inside)
                [ "$#" -ge 2 ] || die "truncated internal Preview plugin argument"
                plugin=$2
                shift 2
                ;;
            --remote-package-cache-inside)
                [ "$#" -ge 2 ] || die "truncated internal remote cache argument"
                remote_cache=$2
                shift 2
                ;;
            *) die "invalid internal invocation" ;;
        esac
    done
    require_directory "$app_root" "mounted application source root"
    require_directory "$output" "mounted output root"
    require_directory "$platform" "mounted platform package"
    [ -z "$remote_cache" ] \
        || require_directory "$remote_cache" "mounted remote package cache"
    [ -z "${ADDITIONAL_SWIFT_DRIVER_FLAGS+x}" ] \
        || die "ADDITIONAL_SWIFT_DRIVER_FLAGS must be absent for an attested compile plan"
    for tool in python3 swiftc clang-18 clang++-18 ld64.lld-18 llvm-nm-18 llvm-otool-18 file sha256sum perl; do
        command -v "$tool" >/dev/null || die "required container tool is missing: $tool"
    done
    PYTHONPATH="$SCRIPT_DIR" python3 -B "$SCRIPT_DIR/core_guest_package.py" \
        "$platform" --emit-summary
    local -a remote_cache_arguments=()
    [ -z "$remote_cache" ] \
        || remote_cache_arguments=(--remote-cache-root "$remote_cache")
    python3 -B "$SCRIPT_DIR/application_build_plan.py" \
        "$output/application-build-plan.json" --source-root "$app_root" \
        "${remote_cache_arguments[@]}" --verify

    local module product preview_required expected_plugin_sha plugin_module dts_object
    local -a metadata
    mapfile -d '' -t metadata < <(
        PYTHONPATH="$SCRIPT_DIR" python3 -B - "$platform" \
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
        PYTHONPATH="$SCRIPT_DIR" python3 -B "$SCRIPT_DIR/core_guest_package.py" \
            "$platform" --emit-swift-arguments --absolute-package-paths
    )
    mapfile -d '' -t link_arguments < <(
        PYTHONPATH="$SCRIPT_DIR" python3 -B "$SCRIPT_DIR/core_guest_package.py" \
            "$platform" --emit-link-arguments
    )
    mapfile -d '' -t diagnostic_arguments < <(
        PYTHONPATH="$SCRIPT_DIR" python3 -B "$SCRIPT_DIR/core_guest_package.py" \
            "$platform" --emit-app-diagnostic-arguments
    )
    mapfile -d '' -t relative_sources <"$output/app-sources.nul"
    local swift_sdk_root= swift_sdk_argument_count=0 swift_argument_index
    for swift_argument_index in "${!swift_arguments[@]}"; do
        if [ "${swift_arguments[swift_argument_index]}" = -sdk ]; then
            [ "$((swift_argument_index + 1))" -lt "${#swift_arguments[@]}" ] \
                || die "platform Swift arguments end after -sdk"
            swift_sdk_root=${swift_arguments[swift_argument_index + 1]}
            swift_sdk_argument_count=$((swift_sdk_argument_count + 1))
        fi
    done
    [ "$swift_sdk_argument_count" -eq 1 ] \
        || die "platform Swift arguments must contain exactly one SDK"
    case "$swift_sdk_root" in
        "$platform"/*) ;;
        *) die "platform Swift SDK is not rooted at the mounted package: $swift_sdk_root" ;;
    esac
    require_directory "$swift_sdk_root" "rooted platform Swift SDK"
    [ "${#relative_sources[@]}" -gt 0 ] || die "application source list is empty"
    local relative source
    for relative in "${relative_sources[@]}"; do
        case "$relative" in /*|*../*|../*|*/..) die "unsafe application source path: $relative" ;; esac
        source=$app_root/$relative
        require_regular "$source" "application source"
        app_sources+=("$source")
    done

    local module_cache preview_module_cache object_root output_map object_audit
    module_cache=$output/module-cache
    preview_module_cache=$output/preview-evidence-module-cache
    object_root=$output/application-objects
    output_map=$output/application-output-file-map.json
    object_audit=$output/application-object-audit.json
    [ ! -e "$module_cache" ] && [ ! -L "$module_cache" ] \
        || die "module cache already exists"
    [ ! -e "$object_root" ] && [ ! -L "$object_root" ] \
        || die "application object root already exists"
    [ ! -e "$output_map" ] && [ ! -L "$output_map" ] \
        || die "application output-file map already exists"
    [ ! -e "$object_audit" ] && [ ! -L "$object_audit" ] \
        || die "application object audit already exists"
    mkdir "$module_cache"
    local -a plugin_arguments=()
    if [ "$preview_required" = yes ]; then
        plugin_arguments=(-load-plugin-executable "$plugin#$plugin_module")
    fi
    # Every invocation that loads the SwiftSyntax executable plugin must use
    # one driver job. Swift 6.2.4 can otherwise race the framed termination
    # message against plugin teardown and report Corrupted JSON after success.
    local serial_job_argument=-j1

    # Compile the frozen Swift-package graph as one Swift/Clang module and
    # object boundary per reachable target. A remote product is never guessed
    # or stubbed: preflight stops until its exact pinned source is materialized.
    local package_graph package_build_root package_module_root package_clang_module_cache
    local -a package_import_arguments=() package_link_arguments=()
    local -a package_objects=() package_target_indices=()
    package_graph=$output/local-package-graph.json
    package_build_root=$output/local-package-build
    package_module_root=$package_build_root/modules
    package_clang_module_cache=$package_build_root/clang-module-cache
    if [ -e "$package_graph" ] || [ -L "$package_graph" ]; then
        require_regular "$package_graph" "local Swift-package graph"
        require_regular "$output/local-package-targets.nul" \
            "local Swift-package target list"
        python3 -B "$SCRIPT_DIR/local_package_graph.py" verify-plan-binding \
            "$package_graph" \
            --application-plan "$output/application-build-plan.json" \
            --target-list "$output/local-package-targets.nul" \
            --source-root "$app_root" "${remote_cache_arguments[@]}"
        python3 -B "$SCRIPT_DIR/local_package_graph.py" require-buildable \
            "$package_graph" --source-root "$app_root" \
            "${remote_cache_arguments[@]}"
        python3 -B "$SCRIPT_DIR/local_package_graph.py" prepare-build \
            "$package_graph" --source-root "$app_root" \
            --output-root "$package_build_root" "${remote_cache_arguments[@]}"
        [ ! -e "$package_clang_module_cache" ] \
            && [ ! -L "$package_clang_module_cache" ] \
            || die "local package Clang module cache already exists"
        mkdir "$package_clang_module_cache"
        package_import_arguments=(-I "$package_module_root")
        local -a package_clang_import_arguments=()
        require_regular "$package_build_root/clang-import-arguments.nul" \
            "local package Clang import argument record"
        mapfile -d '' -t package_clang_import_arguments \
            <"$package_build_root/clang-import-arguments.nul"
        [ "$(( ${#package_clang_import_arguments[@]} % 2 ))" -eq 0 ] \
            || die "local package Clang import arguments are truncated"
        local package_import_cursor package_import_value
        for ((package_import_cursor = 0; package_import_cursor < ${#package_clang_import_arguments[@]}; package_import_cursor += 2)); do
            [ "${package_clang_import_arguments[package_import_cursor]}" = -Xcc ] \
                || die "local package Clang import argument is not wrapped by -Xcc"
            package_import_value=${package_clang_import_arguments[package_import_cursor + 1]}
            case "$package_import_value" in
                -fmodule-map-file="$package_build_root"/*)
                    require_regular "${package_import_value#-fmodule-map-file=}" \
                        "local package Clang module map" ;;
                -I"$package_build_root"/*)
                    require_directory "${package_import_value#-I}" \
                        "local package public header directory" ;;
                *) die "local package Clang import argument escaped its build root: $package_import_value" ;;
            esac
        done
        package_import_arguments+=("${package_clang_import_arguments[@]}")
        require_regular "$package_build_root/clang-link-arguments.nul" \
            "local package Clang link argument record"
        mapfile -d '' -t package_link_arguments \
            <"$package_build_root/clang-link-arguments.nul"
        if [ "${#package_link_arguments[@]}" -gt 0 ]; then
            [ "${#package_link_arguments[@]}" -eq 1 ] \
                && [ "${package_link_arguments[0]}" = -lc++ ] \
                || die "local package C++ link arguments drifted"
        fi
        mapfile -d '' -t package_target_indices \
            <"$package_build_root/targets.nul"
        [ "${#package_target_indices[@]}" -gt 0 ] \
            || die "local Swift-package graph has no build targets"
        local package_index package_target_type package_module package_module_output package_output_map
        local package_source_count package_language_count package_compiler_argument_count
        local package_cxx_argument_count package_object_count package_cursor package_offset
        local package_stdout package_stderr package_status package_object package_language
        local package_source_index package_compiler package_compile_directory
        local -a package_record package_sources package_source_languages
        local -a package_compiler_arguments package_cxx_arguments
        local -a package_expected_objects package_command
        for package_index in "${package_target_indices[@]}"; do
            package_record=()
            mapfile -d '' -t package_record < <(
                python3 -B "$SCRIPT_DIR/local_package_graph.py" emit-target-record \
                    "$package_build_root/build-contract.json" \
                    --index "$((10#$package_index))"
            )
            [ "${#package_record[@]}" -ge 10 ] \
                || die "local package target record is truncated: $package_index"
            package_target_type=${package_record[0]}
            package_module=${package_record[1]}
            package_module_output=$package_build_root/${package_record[2]}
            package_output_map=${package_record[3]}
            package_source_count=${package_record[4]}
            [[ "$package_source_count" =~ ^[0-9]+$ ]] \
                || die "local package source count is invalid: $package_index"
            [ "$package_source_count" -gt 0 ] \
                || die "local package target has no sources: $package_module"
            package_sources=()
            for ((package_cursor = 0; package_cursor < package_source_count; package_cursor++)); do
                if [[ "${package_record[5 + package_cursor]}" = /* ]]; then
                    package_sources+=("${package_record[5 + package_cursor]}")
                else
                    package_sources+=("$app_root/${package_record[5 + package_cursor]}")
                fi
                require_regular "${package_sources[-1]}" "local package source"
            done
            package_offset=$((5 + package_source_count))
            package_language_count=${package_record[package_offset]}
            [[ "$package_language_count" =~ ^[0-9]+$ ]] \
                && [ "$package_language_count" -eq "$package_source_count" ] \
                || die "local package source language count is invalid: $package_module"
            package_offset=$((package_offset + 1))
            package_source_languages=()
            for ((package_cursor = 0; package_cursor < package_language_count; package_cursor++)); do
                package_source_languages+=("${package_record[package_offset + package_cursor]}")
            done
            package_offset=$((package_offset + package_language_count))
            package_compiler_argument_count=${package_record[package_offset]}
            [[ "$package_compiler_argument_count" =~ ^[0-9]+$ ]] \
                || die "local package compiler argument count is invalid: $package_index"
            package_offset=$((package_offset + 1))
            package_compiler_arguments=()
            for ((package_cursor = 0; package_cursor < package_compiler_argument_count; package_cursor++)); do
                package_compiler_arguments+=("${package_record[package_offset + package_cursor]}")
            done
            package_offset=$((package_offset + package_compiler_argument_count))
            package_cxx_argument_count=${package_record[package_offset]}
            [[ "$package_cxx_argument_count" =~ ^[0-9]+$ ]] \
                || die "local package C++ argument count is invalid: $package_index"
            package_offset=$((package_offset + 1))
            package_cxx_arguments=()
            for ((package_cursor = 0; package_cursor < package_cxx_argument_count; package_cursor++)); do
                package_cxx_arguments+=("${package_record[package_offset + package_cursor]}")
            done
            package_offset=$((package_offset + package_cxx_argument_count))
            package_object_count=${package_record[package_offset]}
            [[ "$package_object_count" =~ ^[0-9]+$ ]] \
                || die "local package object count is invalid: $package_index"
            [ "$package_object_count" -eq "$package_source_count" ] \
                || die "local package source/object count differs: $package_module"
            package_offset=$((package_offset + 1))
            package_expected_objects=()
            for ((package_cursor = 0; package_cursor < package_object_count; package_cursor++)); do
                package_expected_objects+=(
                    "$package_build_root/${package_record[package_offset + package_cursor]}"
                )
            done
            package_offset=$((package_offset + package_object_count))
            [ "${#package_record[@]}" -eq "$package_offset" ] \
                || die "local package target record has trailing fields: $package_index"
            package_compile_directory=$package_build_root/targets/$package_index-$package_module
            case "$package_target_type" in
                swift)
                    [ "$package_output_map" != - ] \
                        || die "local Swift package target has no output-file map: $package_module"
                    package_output_map=$package_build_root/$package_output_map
                    [ "$package_cxx_argument_count" -eq 0 ] \
                        || die "local Swift package target carries C++ arguments: $package_module"
                    [ "$((package_compiler_argument_count % 2))" -eq 0 ] \
                        || die "local package Swift arguments are not option/value pairs: $package_module"
                    for package_language in "${package_source_languages[@]}"; do
                        [ "$package_language" = swift ] \
                            || die "local Swift package target has a non-Swift source: $package_module"
                    done
                    for ((package_cursor = 0; package_cursor < package_compiler_argument_count; package_cursor += 2)); do
                        case "${package_compiler_arguments[package_cursor]}" in
                            -swift-version)
                                case "${package_compiler_arguments[package_cursor + 1]}" in
                                    4|4.2|5|6) ;;
                                    *) die "local package Swift language mode is invalid: $package_module" ;;
                                esac ;;
                            -default-isolation)
                                [ "${package_compiler_arguments[package_cursor + 1]}" = MainActor ] \
                                    || die "local package default isolation is invalid: $package_module" ;;
                            -enable-experimental-feature)
                                [ "${package_compiler_arguments[package_cursor + 1]}" = StrictConcurrency ] \
                                    || die "local package experimental feature is invalid: $package_module" ;;
                            -D)
                                [[ "${package_compiler_arguments[package_cursor + 1]}" =~ ^[A-Za-z_][A-Za-z0-9_]*$ ]] \
                                    || die "local package compilation condition is invalid: $package_module" ;;
                            *) die "local package Swift compiler argument is outside the allowlist: ${package_compiler_arguments[package_cursor]}" ;;
                        esac
                    done
                    package_command=(swiftc "${swift_arguments[@]}"
                        "${package_compiler_arguments[@]}"
                        -module-cache-path "$module_cache"
                        "${package_import_arguments[@]}" -parse-as-library
                        -module-name "$package_module"
                        -emit-module -emit-module-path "$package_module_output"
                        -emit-object -output-file-map "$package_output_map"
                        "${package_sources[@]}")
                    package_stdout=$package_compile_directory/compile.stdout
                    package_stderr=$package_compile_directory/compile.stderr
                    printf '%s\0' "${package_command[@]}" \
                        >"$package_compile_directory/compile-arguments.nul"
                    echo "== compile local Swift-package target $package_module"
                    set +e
                    (
                        cd "$platform"
                        "${package_command[@]}"
                    ) >"$package_stdout" 2>"$package_stderr"
                    package_status=$?
                    set -e
                    cat "$package_stderr" >&2
                    [ "$package_status" -eq 0 ] \
                        || die "local package target $package_module compiler exited $package_status"
                    [ ! -s "$package_stdout" ] \
                        || die "local package target $package_module emitted unexpected stdout"
                    if swift_compiler_output_has_failure_diagnostic "$package_stderr"; then
                        die "local package target $package_module emitted a failure diagnostic despite success"
                    fi
                    require_regular "$package_module_output" "local package Swift module" ;;
                clang)
                    [ "$package_output_map" = - ] \
                        || die "local Clang package target unexpectedly has an output-file map: $package_module"
                    require_regular "$package_module_output" "local package Clang module map"
                    for package_cursor in "${!package_compiler_arguments[@]}"; do
                        case "${package_compiler_arguments[package_cursor]}" in
                            -I"$package_build_root"/*)
                                require_directory "${package_compiler_arguments[package_cursor]#-I}" \
                                    "local package C header search path" ;;
                            *)
                                [[ "${package_compiler_arguments[package_cursor]}" =~ ^-D[A-Za-z_][A-Za-z0-9_]*(=.*)?$ ]] \
                                    || die "local package C compiler argument is outside the allowlist: ${package_compiler_arguments[package_cursor]}" ;;
                        esac
                    done
                    for package_cursor in "${!package_cxx_arguments[@]}"; do
                        case "${package_cxx_arguments[package_cursor]}" in
                            -I"$package_build_root"/*)
                                require_directory "${package_cxx_arguments[package_cursor]#-I}" \
                                    "local package C++ header search path" ;;
                            *)
                                [[ "${package_cxx_arguments[package_cursor]}" =~ ^-D[A-Za-z_][A-Za-z0-9_]*(=.*)?$ ]] \
                                    || die "local package C++ compiler argument is outside the allowlist: ${package_cxx_arguments[package_cursor]}" ;;
                        esac
                    done
                    for package_source_index in "${!package_sources[@]}"; do
                        package_language=${package_source_languages[package_source_index]}
                        case "$package_language" in
                            c|objective-c|assembler|assembler-with-cpp)
                                package_compiler=clang-18 ;;
                            cxx|objective-cxx)
                                package_compiler=clang++-18 ;;
                            *) die "local Clang package target has unsupported source language: $package_language" ;;
                        esac
                        package_command=("$package_compiler"
                            -target arm64-apple-macos15.0 -isysroot "$swift_sdk_root"
                            -fmodules -fmodules-cache-path="$package_clang_module_cache"
                            -fmodule-name="$package_module"
                            "${package_compiler_arguments[@]}")
                        if [ "$package_compiler" = clang++-18 ]; then
                            package_command+=(-stdlib=libc++ "${package_cxx_arguments[@]}")
                        fi
                        package_command+=(-c "${package_sources[package_source_index]}"
                            -o "${package_expected_objects[package_source_index]}")
                        package_stdout=$package_compile_directory/compile-$package_source_index.stdout
                        package_stderr=$package_compile_directory/compile-$package_source_index.stderr
                        printf '%s\0' "${package_command[@]}" \
                            >"$package_compile_directory/compile-$package_source_index-arguments.nul"
                        echo "== compile local C-family package target $package_module [$package_source_index/$package_source_count]"
                        set +e
                        (
                            cd "$platform"
                            "${package_command[@]}"
                        ) >"$package_stdout" 2>"$package_stderr"
                        package_status=$?
                        set -e
                        cat "$package_stderr" >&2
                        [ "$package_status" -eq 0 ] \
                            || die "local package target $package_module C-family compiler exited $package_status"
                        [ ! -s "$package_stdout" ] \
                            || die "local package target $package_module emitted unexpected C-family compiler stdout"
                    done ;;
                *) die "local package target has unsupported compiler family: $package_target_type" ;;
            esac
            for package_object in "${package_expected_objects[@]}"; do
                require_regular "$package_object" "local package target object"
                file "$package_object" | grep -F 'Mach-O 64-bit arm64 object' >/dev/null \
                    || die "local package object is not ARM64 Mach-O: $package_object"
                package_objects+=("$package_object")
            done
        done
        python3 -B "$SCRIPT_DIR/local_package_graph.py" verify-build-contract \
            "$package_graph" --source-root "$app_root" \
            --output-root "$package_build_root" "${remote_cache_arguments[@]}"
    else
        [ ! -e "$output/local-package-targets.nul" ] \
            && [ ! -L "$output/local-package-targets.nul" ] \
            || die "local package target list exists without its graph"
    fi

    local -a platform_sources=(
        "$output/GeneratedSceneBootstrap.swift"
        "$SCRIPT_DIR/PortableUIKitApplicationHost.swift"
        "$SUPPORT_ROOT/full/driver/RunLoop.swift"
    )
    # Compiler providers consume only build-plan-attested non-Swift inputs and
    # publish a fresh, independently verifiable output root. Generated Swift is
    # ordered after untouched app sources and before platform host sources.
    local -a derived_sources=()
    local derived_root derived_relative derived_source
    derived_root=$output/derived-sources
    [ ! -e "$derived_root" ] && [ ! -L "$derived_root" ] \
        || die "derived-source output root already exists"
    echo "== generate attested compiler-provider Swift inputs"
    python3 -B "$SCRIPT_DIR/compiler_input_providers.py" generate \
        --build-plan "$output/application-build-plan.json" \
        --source-root "$app_root" --output-root "$derived_root"
    python3 -B "$SCRIPT_DIR/compiler_input_providers.py" verify \
        --build-plan "$output/application-build-plan.json" \
        --source-root "$app_root" --output-root "$derived_root"
    local -a derived_relative_sources=()
    mapfile -d '' -t derived_relative_sources \
        <"$derived_root/derived-sources.nul"
    for derived_relative in "${derived_relative_sources[@]}"; do
        case "$derived_relative" in
            /*|*../*|../*|*/..)
                die "unsafe derived Swift source path: $derived_relative" ;;
        esac
        derived_source=$derived_root/$derived_relative
        require_regular "$derived_source" "attested derived Swift source"
        derived_sources+=("$derived_source")
    done
    local argument
    for argument in "${swift_arguments[@]}"; do
        case "$argument" in
            -wmo|-whole-module-optimization)
                die "application compile arguments must not enable whole-module optimization" ;;
            -disable-batch-mode)
                die "application compile arguments must not disable default driver scheduling" ;;
            -enable-batch-mode)
                die "application compile arguments must not override default driver scheduling" ;;
            -j|-j*)
                die "application compile arguments must not override the pinned driver job count" ;;
            -dump-macro-expansions)
                die "application production compile must not dump full-module macro expansions" ;;
            -output-file-map|-primary-file)
                die "application compile arguments contain a driver-owned scheduling option: $argument" ;;
        esac
    done
    if [ "$preview_required" = yes ]; then
        [ "${#diagnostic_arguments[@]}" -eq 2 ] \
            && [ "${diagnostic_arguments[0]}" = -Xfrontend ] \
            && [ "${diagnostic_arguments[1]}" = -dump-macro-expansions ] \
            || die "Preview diagnostic arguments drifted"
        require_regular "$output/preview-evidence-sources.nul" \
            "copied Preview evidence source list"
        [ ! -e "$preview_module_cache" ] && [ ! -L "$preview_module_cache" ] \
            || die "Preview evidence module cache already exists"
        mkdir "$preview_module_cache"
        local -a preview_sources preview_command
        mapfile -d '' -t preview_sources < <(
            python3 -B "$SCRIPT_DIR/application_object_contract.py" \
                validate-preview-sources \
                --source-root "$app_root" \
                --application-source-list "$output/app-sources.nul" \
                --preview-source-list "$output/preview-evidence-sources.nul" \
                --audit "$output/preview-evidence-source-audit.json"
        )
        [ "${#preview_sources[@]}" -gt 0 ] \
            && [ "${#preview_sources[@]}" -lt "${#app_sources[@]}" ] \
            || die "Preview evidence must use a nonempty proper source subset"
        preview_command=(swiftc "${swift_arguments[@]}"
            -module-cache-path "$preview_module_cache"
            "${package_import_arguments[@]}"
            -default-isolation MainActor -module-name "$module"
            "${plugin_arguments[@]}" "$serial_job_argument"
            "${diagnostic_arguments[@]}"
            -typecheck "${preview_sources[@]}")
        local preview_effective_serial_job_count=0
        for argument in "${preview_command[@]}"; do
            case "$argument" in
                "$serial_job_argument")
                    preview_effective_serial_job_count=$((preview_effective_serial_job_count + 1)) ;;
                -j|-j*)
                    die "Preview evidence compile has an unpinned driver job argument: $argument" ;;
            esac
        done
        [ "$preview_effective_serial_job_count" -eq 1 ] \
            || die "Preview evidence effective serialized driver job count is not one"
        printf '%s\0' "${preview_command[@]}" \
            >"$output/preview-evidence-compile-arguments.nul"
        local preview_stdout preview_stderr preview_status
        preview_stdout=$output/app-macro-expansions.stdout
        preview_stderr=$output/app-macro-expansions.stderr
        [ ! -e "$preview_stdout" ] && [ ! -L "$preview_stdout" ] \
            && [ ! -e "$preview_stderr" ] && [ ! -L "$preview_stderr" ] \
            || die "Preview evidence compiler output already exists"
        echo "== prove bounded Preview expansion"
        set +e
        (
            cd "$platform"
            "${preview_command[@]}"
        ) >"$preview_stdout" 2>"$preview_stderr"
        preview_status=$?
        set -e
        cat "$preview_stderr" >&2
        [ "$preview_status" -eq 0 ] \
            || die "Preview evidence compiler exited $preview_status"
        [ ! -s "$preview_stdout" ] \
            || die "Preview evidence compiler emitted unexpected stdout"
        if swift_compiler_output_has_failure_diagnostic "$preview_stderr"; then
            grep -En "$SWIFT_COMPILER_FAILURE_DIAGNOSTIC_PATTERN" \
                "$preview_stderr" >&2 || true
            die "Preview evidence compiler emitted a failure diagnostic despite success"
        fi
        {
            printf 'format\tportable-preview-evidence-audit-v3\n'
            printf 'application-source-count\t%s\n' "${#app_sources[@]}"
            printf 'bounded-source-count\t%s\n' "${#preview_sources[@]}"
            printf 'module-name\t%s\n' "$module"
            printf 'whole-module-flag-count\t0\n'
            printf 'disable-batch-mode-count\t0\n'
            printf 'dump-macro-expansions-count\t1\n'
            printf 'driver-job-flag-count\t%s\n' \
                "$preview_effective_serial_job_count"
            printf 'driver-max-parallel-job-count\t1\n'
            printf 'planned-frontend-job-count\t1\n'
            printf 'source-audit-sha256\t%s\n' \
                "$(sha256sum "$output/preview-evidence-source-audit.json" | awk '{print $1}')"
            printf 'arguments-sha256\t%s\n' \
                "$(sha256sum "$output/preview-evidence-compile-arguments.nul" | awk '{print $1}')"
            printf 'stderr-sha256\t%s\n' \
                "$(sha256sum "$preview_stderr" | awk '{print $1}')"
        } >"$output/preview-evidence-audit.tsv"
    else
        [ "${#diagnostic_arguments[@]}" -eq 0 ] \
            || die "non-Preview package published diagnostic arguments"
        [ ! -e "$output/preview-evidence-sources.nul" ] \
            && [ ! -L "$output/preview-evidence-sources.nul" ] \
            || die "non-Preview build carries a Preview evidence source list"
    fi

    local materialized_root materialized_source_list materialization_audit
    materialized_root=$output/preview-materialized-sources
    materialized_source_list=$output/preview-materialized-app-sources.nul
    materialization_audit=$output/preview-materialization-audit.json
    local -a production_app_sources=("${app_sources[@]}")
    local preview_original_source= preview_materialized_source=
    if [ "$preview_required" = yes ]; then
        echo "== materialize the attested Preview expansion into an output-owned source"
        python3 -B "$SCRIPT_DIR/application_object_contract.py" \
            materialize-preview-expansion \
            --source-root "$app_root" \
            --application-source-list "$output/app-sources.nul" \
            --preview-source-audit "$output/preview-evidence-source-audit.json" \
            --expansion-stderr "$preview_stderr" \
            --output-root "$materialized_root" \
            --compile-source-list "$materialized_source_list" \
            --audit "$materialization_audit" --module-name "$module"
        python3 -B "$SCRIPT_DIR/application_object_contract.py" \
            verify-preview-materialization \
            --source-root "$app_root" \
            --application-source-list "$output/app-sources.nul" \
            --preview-source-audit "$output/preview-evidence-source-audit.json" \
            --expansion-stderr "$preview_stderr" \
            --output-root "$materialized_root" \
            --compile-source-list "$materialized_source_list" \
            --audit "$materialization_audit" --module-name "$module"
        mapfile -d '' -t production_app_sources <"$materialized_source_list"
        [ "${#production_app_sources[@]}" -eq "${#app_sources[@]}" ] \
            || die "materialized application source count drifted"
        local source_index materialized_difference_count=0
        for source_index in "${!app_sources[@]}"; do
            if [ "${app_sources[$source_index]}" != "${production_app_sources[$source_index]}" ]; then
                materialized_difference_count=$((materialized_difference_count + 1))
                preview_original_source=${app_sources[$source_index]}
                preview_materialized_source=${production_app_sources[$source_index]}
            fi
        done
        [ "$materialized_difference_count" -eq 1 ] \
            || die "materialized application source list must replace exactly one source"
        case "$preview_materialized_source" in
            "$materialized_root"/*) ;;
            *) die "materialized Preview source escaped its output root" ;;
        esac
    else
        [ ! -e "$materialized_root" ] && [ ! -L "$materialized_root" ] \
            && [ ! -e "$materialized_source_list" ] \
            && [ ! -L "$materialized_source_list" ] \
            && [ ! -e "$materialization_audit" ] \
            && [ ! -L "$materialization_audit" ] \
            || die "non-Preview build carries Preview materialization artifacts"
    fi
    local -a compile_sources=(
        "${production_app_sources[@]}" "${derived_sources[@]}" "${platform_sources[@]}"
    )
    [ "${#compile_sources[@]}" -gt 1 ] \
        || die "application compile unexpectedly has fewer than two sources"

    python3 -B "$SCRIPT_DIR/application_object_contract.py" create-output-map \
        --output-map "$output_map" --object-root "$object_root" \
        "${compile_sources[@]}"
    # The executable plugin is confined to the bounded evidence invocation.
    # Production consumes the freshly attested expansion as ordinary Swift;
    # every logical app source still has one ordered output-map entry.
    local -a compile_command
    compile_command=(swiftc "${swift_arguments[@]}"
        -module-cache-path "$module_cache"
        "${package_import_arguments[@]}"
        -default-isolation MainActor -module-name "$module"
        "$serial_job_argument" -emit-object
        -output-file-map "$output_map" "${compile_sources[@]}")
    local effective_output_map_count=0
    local effective_wmo_count=0
    local effective_disable_batch_count=0
    local effective_dump_count=0
    local effective_serial_job_count=0
    local effective_plugin_load_count=0
    local effective_plugin_path_count=0
    local effective_original_preview_source_count=0
    local effective_materialized_preview_source_count=0
    for argument in "${compile_command[@]}"; do
        case "$argument" in
            -output-file-map)
                effective_output_map_count=$((effective_output_map_count + 1)) ;;
            -wmo|-whole-module-optimization)
                effective_wmo_count=$((effective_wmo_count + 1)) ;;
            -disable-batch-mode)
                effective_disable_batch_count=$((effective_disable_batch_count + 1)) ;;
            -dump-macro-expansions)
                effective_dump_count=$((effective_dump_count + 1)) ;;
            -load-plugin-executable)
                effective_plugin_load_count=$((effective_plugin_load_count + 1)) ;;
            "$serial_job_argument")
                effective_serial_job_count=$((effective_serial_job_count + 1)) ;;
            -j|-j*)
                die "application compile has an unpinned driver job argument: $argument" ;;
        esac
        [ -z "$plugin" ] || [ "$argument" != "$plugin#$plugin_module" ] \
            || effective_plugin_path_count=$((effective_plugin_path_count + 1))
        [ -z "$preview_original_source" ] || [ "$argument" != "$preview_original_source" ] \
            || effective_original_preview_source_count=$((effective_original_preview_source_count + 1))
        [ -z "$preview_materialized_source" ] || [ "$argument" != "$preview_materialized_source" ] \
            || effective_materialized_preview_source_count=$((effective_materialized_preview_source_count + 1))
    done
    [ "$effective_output_map_count" -eq 1 ] \
        || die "application effective output-file-map count $effective_output_map_count, expected 1"
    [ "$effective_wmo_count" -eq 0 ] \
        || die "application effective whole-module flag count is not zero"
    [ "$effective_disable_batch_count" -eq 0 ] \
        || die "application effective disable-batch-mode count is not zero"
    [ "$effective_dump_count" -eq 0 ] \
        || die "application production compile includes macro dumping"
    [ "$effective_serial_job_count" -eq 1 ] \
        || die "application effective serialized driver job count is not one"
    [ "$effective_plugin_load_count" -eq 0 ] \
        && [ "$effective_plugin_path_count" -eq 0 ] \
        || die "application production compile retains a Preview plugin argument"
    [ "$effective_original_preview_source_count" -eq 0 ] \
        || die "application production compile retains the original #Preview source"
    if [ "$preview_required" = yes ]; then
        [ "$effective_materialized_preview_source_count" -eq 1 ] \
            || die "application production compile does not contain one materialized Preview source"
    else
        [ "$effective_materialized_preview_source_count" -eq 0 ] \
            || die "non-Preview compile contains a materialized Preview source"
    fi
    printf '%s\0' "${compile_command[@]}" \
        >"$output/application-compile-arguments.nul"

    local compile_stdout compile_stderr compile_status
    compile_stdout=$output/application-compile.stdout
    compile_stderr=$output/application-compile.stderr
    [ ! -e "$compile_stderr" ] && [ ! -L "$compile_stderr" ] \
        && [ ! -e "$compile_stdout" ] && [ ! -L "$compile_stdout" ] \
        || die "application compiler output already exists"
    echo "== compile ordered application sources with attested Preview materialization"
    set +e
    (
        cd "$platform"
        "${compile_command[@]}"
    ) >"$compile_stdout" 2>"$compile_stderr"
    compile_status=$?
    set -e
    cat "$compile_stderr" >&2
    [ "$compile_status" -eq 0 ] \
        || die "application compiler exited $compile_status"
    [ ! -s "$compile_stdout" ] \
        || die "application compiler emitted unexpected stdout"
    if swift_compiler_output_has_failure_diagnostic "$compile_stderr"; then
        grep -En "$SWIFT_COMPILER_FAILURE_DIAGNOSTIC_PATTERN" \
            "$compile_stderr" >&2 || true
        die "application compiler emitted a failure diagnostic despite success"
    fi
    local -a application_objects
    mapfile -d '' -t application_objects < <(
        python3 -B "$SCRIPT_DIR/application_object_contract.py" verify-objects \
            --output-map "$output_map" --object-root "$object_root" \
            --audit "$object_audit" "${compile_sources[@]}"
    )
    [ "${#application_objects[@]}" -eq "${#compile_sources[@]}" ] \
        || die "verified application object count drifted"
    local object_index object_path
    : >"$output/application-object-formats.txt"
    for object_index in "${!application_objects[@]}"; do
        object_path=${application_objects[$object_index]}
        file "$object_path" \
            | tee -a "$output/application-object-formats.txt" \
            | grep -F 'Mach-O 64-bit arm64 object' >/dev/null \
            || die "application object is not ARM64 Mach-O: $object_path"
        llvm-otool-18 -hv "$object_path" | grep -Eq \
            'MH_MAGIC_64[[:space:]]+ARM64.*[[:space:]]OBJECT' \
            || die "application object header drifted: $object_path"
    done
    python3 -B "$SCRIPT_DIR/application_object_contract.py" \
        audit-cross-file-symbols --nm "$(command -v llvm-nm-18)" \
        --audit "$output/application-cross-file-symbols.json" \
        "${application_objects[@]}"
    {
        printf 'format\tportable-application-compile-audit-v4\n'
        printf 'mode\tstandard-driver-output-file-map\n'
        printf 'source-count\t%s\n' "${#compile_sources[@]}"
        printf 'application-source-count\t%s\n' "${#app_sources[@]}"
        printf 'original-application-source-count\t%s\n' \
            "$(( ${#app_sources[@]} - effective_materialized_preview_source_count ))"
        printf 'materialized-application-source-count\t%s\n' \
            "$effective_materialized_preview_source_count"
        printf 'derived-source-count\t%s\n' "${#derived_sources[@]}"
        printf 'platform-source-count\t%s\n' "${#platform_sources[@]}"
        printf 'package-target-count\t%s\n' "${#package_target_indices[@]}"
        printf 'package-object-count\t%s\n' "${#package_objects[@]}"
        printf 'object-count\t%s\n' "${#application_objects[@]}"
        printf 'output-file-map-count\t%s\n' "$effective_output_map_count"
        printf 'whole-module-flag-count\t%s\n' "$effective_wmo_count"
        printf 'disable-batch-mode-count\t%s\n' "$effective_disable_batch_count"
        printf 'production-macro-dump-count\t%s\n' "$effective_dump_count"
        printf 'production-plugin-load-count\t%s\n' "$effective_plugin_load_count"
        printf 'production-plugin-path-count\t%s\n' "$effective_plugin_path_count"
        printf 'original-preview-source-count\t%s\n' \
            "$effective_original_preview_source_count"
        printf 'driver-job-flag-count\t%s\n' "$effective_serial_job_count"
        printf 'driver-max-parallel-job-count\t1\n'
        printf 'planned-frontend-job-count\t%s\n' "${#compile_sources[@]}"
        printf 'additional-swift-driver-flags-set\t0\n'
        printf 'output-file-map-sha256\t%s\n' \
            "$(sha256sum "$output_map" | awk '{print $1}')"
        printf 'object-audit-sha256\t%s\n' \
            "$(sha256sum "$object_audit" | awk '{print $1}')"
        printf 'cross-file-audit-sha256\t%s\n' \
            "$(sha256sum "$output/application-cross-file-symbols.json" | awk '{print $1}')"
        printf 'arguments-sha256\t%s\n' \
            "$(sha256sum "$output/application-compile-arguments.nul" | awk '{print $1}')"
        printf 'stderr-sha256\t%s\n' \
            "$(sha256sum "$compile_stderr" | awk '{print $1}')"
        printf 'derived-source-attestation-sha256\t%s\n' \
            "$(sha256sum "$derived_root/derived-sources-attestation.json" | awk '{print $1}')"
        if [ "$preview_required" = yes ]; then
            printf 'preview-materialization-audit-sha256\t%s\n' \
                "$(sha256sum "$materialization_audit" | awk '{print $1}')"
        fi
    } >"$output/application-compile-audit.tsv"

    local app frameworks executable libraries
    app=$output/$product.app
    frameworks=$app/Contents/Frameworks
    executable=$app/Contents/MacOS/$product
    require_directory "$frameworks" "application Frameworks directory"
    [ ! -e "$executable" ] && [ ! -L "$executable" ] \
        || die "application executable already exists"
    libraries=$(PYTHONPATH="$SCRIPT_DIR" python3 -B - "$platform" <<'PY'
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
        for object_index in "${!application_objects[@]}"; do
            object_path=${application_objects[$object_index]}
            printf 'app_object\t%06d\t%s\t%s\n' \
                "$object_index" \
                "$(sha256sum "$object_path" | awk '{print $1}')" \
                "$object_path"
        done
        for object_index in "${!package_objects[@]}"; do
            object_path=${package_objects[$object_index]}
            printf 'package_object\t%06d\t%s\t%s\n' \
                "$object_index" \
                "$(sha256sum "$object_path" | awk '{print $1}')" \
                "$object_path"
        done
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
    local -a link_command
    link_command=(ld64.lld-18 "${link_arguments[@]}" -dead_strip
        "${package_link_arguments[@]}"
        "${executable_export_arguments[@]}"
        -rpath @executable_path/../Frameworks
        -o "$executable" "${application_objects[@]}" \
        "${package_objects[@]}" "${extra_objects[@]}")
    local linked_app_object_count=0
    local command_argument
    for object_path in "${application_objects[@]}"; do
        local per_object_link_count=0
        for command_argument in "${link_command[@]}"; do
            [ "$command_argument" != "$object_path" ] \
                || per_object_link_count=$((per_object_link_count + 1))
        done
        [ "$per_object_link_count" -eq 1 ] \
            || die "application object link count is not one: $object_path"
        linked_app_object_count=$((linked_app_object_count + per_object_link_count))
    done
    [ "$linked_app_object_count" -eq "${#application_objects[@]}" ] \
        || die "application link object count drifted"
    local linked_package_object_count=0
    for object_path in "${package_objects[@]}"; do
        local per_package_object_link_count=0
        for command_argument in "${link_command[@]}"; do
            [ "$command_argument" != "$object_path" ] \
                || per_package_object_link_count=$((per_package_object_link_count + 1))
        done
        [ "$per_package_object_link_count" -eq 1 ] \
            || die "local package object link count is not one: $object_path"
        linked_package_object_count=$((linked_package_object_count + per_package_object_link_count))
    done
    [ "$linked_package_object_count" -eq "${#package_objects[@]}" ] \
        || die "local package link object count drifted"
    printf '%s\0' "${link_command[@]}" \
        >"$output/application-link-arguments.nul"
    echo "== link relocatable application executable"
    (
        cd "$platform"
        "${link_command[@]}"
    )
    chmod 0755 "$executable"
    file "$executable" | tee "$output/executable-file.txt"
    llvm-otool-18 -hv "$executable" | grep -Eq \
        'MH_MAGIC_64[[:space:]]+ARM64.*[[:space:]]EXECUTE' \
        || die "linked application is not an ARM64 Mach-O executable"
    python3 -B "$SCRIPT_DIR/application_object_contract.py" \
        audit-linked-executable --nm "$(command -v llvm-nm-18)" \
        --executable "$executable" \
        --cross-file-audit "$output/application-cross-file-symbols.json" \
        --audit "$output/application-linked-symbols.json" \
        "${application_objects[@]}"
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
        printf 'linked_app_object_count\t%s\n' "$linked_app_object_count"
        printf 'linked_package_object_count\t%s\n' "$linked_package_object_count"
        printf 'libUIKit_preview_initializer_import_count\t%s\n' \
            "$uikit_preview_import_count"
        printf 'executable_preview_initializer_export_count\t%s\n' \
            "$executable_preview_export_count"
    } >>"$output/application-link-objects.tsv"

    local guest_root
    guest_root=$(PYTHONPATH="$SCRIPT_DIR" python3 -B - "$platform" <<'PY'
from pathlib import Path
import core_guest_package
import sys
root, manifest = core_guest_package.validate(Path(sys.argv[1]))
print(root / manifest["paths"]["guest_root"])
PY
    )
    local url_transport_host dispatch_host dispatch_runtime blocks_runtime relative_time_host foundation_intl_host
    url_transport_host=$guest_root/host/libOpenURLTransportHost.so
    dispatch_host=$guest_root/host/libOpenDispatchHost.so
    dispatch_runtime=$guest_root/host/libdispatch.so
    blocks_runtime=$guest_root/host/libBlocksRuntime.so
    relative_time_host=$guest_root/host/libOpenRelativeTimeHost.so
    foundation_intl_host=$guest_root/host/libOpenFoundationInternationalizationHost.so
    require_regular "$url_transport_host" "Linux URL transport helper"
    require_regular "$relative_time_host" "Linux relative-time helper"
    require_regular "$foundation_intl_host" \
        "Linux FoundationInternationalization helper"
    require_regular "$dispatch_host" "Linux Dispatch helper"
    require_regular "$dispatch_runtime" "pinned Linux libdispatch"
    require_regular "$blocks_runtime" "pinned Linux BlocksRuntime"
    perl "$SUPPORT_ROOT/full/swiftui/focus_widget_guest_attest.pl" closure \
        --otool llvm-otool-18 --executable "$executable" \
        --package "$frameworks" --guest-root "$guest_root" \
        >"$output/runtime-closure.manifest"

    echo "== cold-launch packaged application under machorun"
    (
        cd "$output"
        LD_LIBRARY_PATH="$guest_root/host${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}" \
        LD_PRELOAD="$dispatch_host:$foundation_intl_host:$url_transport_host:$relative_time_host${LD_PRELOAD:+:$LD_PRELOAD}" \
            MACHORUN_ROOT="$guest_root" OPENUIKIT_HOST_TURNS=3 \
            "$guest_root/machorun" "$executable"
    ) | tee "$output/runtime.log"
    grep -Fx 'PORTABLE_UIKIT_HOST_ACTIVE windows=1' "$output/runtime.log" >/dev/null \
        || die "application did not reach one active UIWindow"
    grep -Fx 'PORTABLE_UIKIT_HOST_LOOP_OK turns=3 paced=true' "$output/runtime.log" >/dev/null \
        || die "application did not complete three production host-loop turns"

    python3 -B "$SCRIPT_DIR/application_build_plan.py" \
        "$output/application-build-plan.json" --source-root "$app_root" \
        "${remote_cache_arguments[@]}" --verify
    python3 -B "$SCRIPT_DIR/compiler_input_providers.py" verify \
        --build-plan "$output/application-build-plan.json" \
        --source-root "$app_root" --output-root "$derived_root"
    if [ "$preview_required" = yes ]; then
        [ "$(sha256sum "$plugin" | awk '{print $1}')" = "$expected_plugin_sha" ] \
            || die "Preview macro plugin changed during build"
        python3 -B "$SCRIPT_DIR/application_object_contract.py" \
            verify-preview-materialization \
            --source-root "$app_root" \
            --application-source-list "$output/app-sources.nul" \
            --preview-source-audit "$output/preview-evidence-source-audit.json" \
            --expansion-stderr "$preview_stderr" \
            --output-root "$materialized_root" \
            --compile-source-list "$materialized_source_list" \
            --audit "$materialization_audit" --module-name "$module"
    fi
    python3 -B "$SCRIPT_DIR/application_object_contract.py" reverify-objects \
        --output-map "$output_map" --object-root "$object_root" \
        --audit "$object_audit" "${compile_sources[@]}"
    local -a build_artifacts=(
        application-compile.stderr
        application-compile.stdout
        application-compile-arguments.nul
        application-compile-audit.tsv
        application-cross-file-symbols.json
        application-link-arguments.nul
        application-link-objects.tsv
        application-linked-symbols.json
        application-object-audit.json
        application-object-formats.txt
        application-output-file-map.json
        runtime-closure.manifest
        runtime.log
    )
    if [ "$preview_required" = yes ]; then
        build_artifacts+=(
            app-macro-expansions.stderr
            app-macro-expansions.stdout
            preview-evidence-audit.tsv
            preview-evidence-compile-arguments.nul
            preview-evidence-source-audit.json
            preview-evidence-sources.nul
            preview-materialization-audit.json
            preview-materialized-app-sources.nul
        )
    fi
    (
        cd "$output"
        find "$product.app" -type f -print0 | sort -z | xargs -0 sha256sum \
            >application-files.sha256
        sha256sum "${build_artifacts[@]}" \
            >application-build-artifacts.sha256
        find application-objects -maxdepth 1 -type f -name '*.o' -print0 \
            | sort -z | xargs -0 sha256sum \
            >>application-build-artifacts.sha256
        find derived-sources -type f -print0 | sort -z | xargs -0 sha256sum \
            >>application-build-artifacts.sha256
        if [ -d local-package-build ]; then
            find local-package-build -type f -print0 | sort -z | xargs -0 sha256sum \
                >>application-build-artifacts.sha256
        fi
        if [ "$preview_required" = yes ]; then
            find preview-materialized-sources -type f -print0 \
                | sort -z | xargs -0 sha256sum \
                >>application-build-artifacts.sha256
        fi
    )
    echo 'PORTABLE_APPLICATION_GUEST_OK'
}

if [ "${1:-}" = --inside ]; then
    shift
    build_inside "$@"
else
    prepare_host "$@"
fi
