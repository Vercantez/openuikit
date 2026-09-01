from __future__ import annotations

import os
from pathlib import Path
import re
import subprocess
import tempfile
import unittest


HERE = Path(__file__).resolve().parent
XCODEPLAN = HERE.parent
REPOSITORY = XCODEPLAN.parent.parent
PREVIEW_EXECUTABLE_EXPORT_SYMBOL = (
    "_$s21DeveloperToolsSupport7PreviewV14_openUIKitBodyACypyScMYcc_tcfC"
)


def validate_preview_executable_export_contract(source: str) -> None:
    assignment = (
        "PREVIEW_EXECUTABLE_EXPORT_SYMBOL=" f"'{PREVIEW_EXECUTABLE_EXPORT_SYMBOL}'"
    )
    required_once = (
        assignment,
        '-exported_symbol "$PREVIEW_EXECUTABLE_EXPORT_SYMBOL"',
        "uikit_preview_import_count=$(nm_symbol_count --undefined-only",
        "preview_definition_count=$(nm_symbol_count --defined-only",
        "executable_preview_export_count=$(nm_symbol_count --defined-only",
        "non-Preview libUIKit imports the Preview initializer",
        "application Preview initializer export count",
        "libUIKit_preview_initializer_import_count",
        "executable_preview_initializer_export_count",
    )
    drifted = [token for token in required_once if source.count(token) != 1]
    if drifted:
        raise AssertionError(
            f"portable-app Preview executable-export contract drifted: {drifted}"
        )
    if "-export_dynamic" in source or "-exported_symbols_list" in source:
        raise AssertionError("portable-app Preview export must remain one exact symbol")


def validate_multi_source_object_map_contract(source: str) -> None:
    required_once = (
        "local -a derived_sources=()",
        '"${production_app_sources[@]}" "${derived_sources[@]}" "${platform_sources[@]}"',
        '"${#compile_sources[@]}" -gt 1',
        'application_object_contract.py" create-output-map',
        'application_object_contract.py" verify-objects',
        'application_object_contract.py" reverify-objects',
        '-output-file-map "$output_map" "${compile_sources[@]}"',
        '"$effective_output_map_count" -eq 1',
        '"$effective_wmo_count" -eq 0',
        '"$effective_disable_batch_count" -eq 0',
        '"$effective_dump_count" -eq 0',
        "local serial_job_argument=-j1",
        '"${plugin_arguments[@]}" "$serial_job_argument"\n'
        '            "${diagnostic_arguments[@]}"',
        '"$serial_job_argument" -emit-object',
        '"$effective_serial_job_count" -eq 1',
        "application compile arguments must not override the pinned driver job count",
        "application compile has an unpinned driver job argument",
        "local preview_effective_serial_job_count=0",
        'for argument in "${preview_command[@]}"; do',
        '"$preview_effective_serial_job_count" -eq 1',
        "Preview evidence compile has an unpinned driver job argument",
        "Preview evidence effective serialized driver job count is not one",
        "portable-preview-evidence-audit-v3",
        'object_audit=$output/application-object-audit.json',
        '--audit "$output/application-cross-file-symbols.json"',
        '--cross-file-audit "$output/application-cross-file-symbols.json"',
        '--audit "$output/application-linked-symbols.json"',
        '"${package_objects[@]}" "${extra_objects[@]}")',
    )
    drifted = [token for token in required_once if source.count(token) != 1]
    if drifted:
        raise AssertionError(
            f"multi-source object-map compile contract drifted: {drifted}"
        )
    if source.count('"${compile_command[@]}"') != 3:
        raise AssertionError(
            "multi-source object-map compile contract drifted: "
            "compile-command capture/invocation wiring"
        )
    if source.count("-j1") != 1:
        raise AssertionError(
            "multi-source object-map compile contract drifted: serial job pin"
        )
    if source.count("driver-max-parallel-job-count\\t1\\n") != 2:
        raise AssertionError(
            "multi-source object-map compile contract drifted: "
            "plugin invocation job audits"
        )
    if source.count("driver-job-flag-count\\t%s\\n") != 2:
        raise AssertionError(
            "multi-source object-map compile contract drifted: "
            "plugin invocation job-flag audits"
        )
    for stream in ("$preview_stderr", "$compile_stderr"):
        token = f'swift_compiler_output_has_failure_diagnostic "{stream}"'
        if source.count(token) != 1:
            raise AssertionError(
                "multi-source object-map compile contract drifted: "
                f"fatal compiler diagnostic guard for {stream}"
            )
    forbidden_legacy = (
        "application_codegen_arguments",
        '-emit-object -o "$object"',
        "application.o",
    )
    if any(token in source for token in forbidden_legacy):
        raise AssertionError("legacy single-object compile contract returned")
    for refusal in (
        "must not enable whole-module optimization",
        "must not disable default driver scheduling",
        "must not dump full-module macro expansions",
    ):
        if source.count(refusal) != 1:
            raise AssertionError(f"multi-source object-map refusal drifted: {refusal}")


def validate_preview_transport_contract(source: str) -> None:
    required_once = (
        "local preview_evidence_enabled=no\n    local preview_source_list_sha=",
        "local preview_evidence_enabled=no legacy_preview_evidence_count=0",
        'legacy_preview_evidence_count=1',
        '"legacy Preview evidence count is outside the 0-or-1 contract"',
        '"enabled legacy Preview evidence count is not one"',
        '"disabled legacy Preview evidence count is not zero"',
        '"--preview-evidence-source-list requires --preview-plugin"',
        '"--preview-plugin requires --preview-evidence-source-list"',
        'materialize-preview-expansion \\\n',
        'materialized_root=$output/preview-materialized-sources',
        'materialized_source_list=$output/preview-materialized-app-sources.nul',
        'materialization_audit=$output/preview-materialization-audit.json',
        'local -a production_app_sources=("${app_sources[@]}")',
        'mapfile -d \'\' -t production_app_sources <"$materialized_source_list"',
        '"$materialized_difference_count" -eq 1',
        'preview_original_source=${app_sources[$source_index]}',
        'preview_materialized_source=${production_app_sources[$source_index]}',
        'effective_plugin_load_count=0',
        'effective_plugin_path_count=0',
        'effective_original_preview_source_count=0',
        'effective_materialized_preview_source_count=0',
        'application production compile retains a Preview plugin argument',
        'application production compile retains the original #Preview source',
        'application production compile does not contain one materialized Preview source',
        'portable-application-compile-audit-v5',
        'preview-target-support\\t%s\\n',
        'legacy-preview-evidence-count\\t%s\\n',
        'production-plugin-load-count\\t%s\\n',
        'production-plugin-path-count\\t%s\\n',
        'original-preview-source-count\\t%s\\n',
        'materialized-application-source-count\\t%s\\n',
        'additional-swift-driver-flags-set\\t0\\n',
        'ADDITIONAL_SWIFT_DRIVER_FLAGS must be absent for an attested compile plan',
        'find preview-materialized-sources -type f -print0',
    )
    drifted = [token for token in required_once if source.count(token) != 1]
    if drifted:
        raise AssertionError(f"Preview transport contract drifted: {drifted}")
    if source.count('verify-preview-materialization \\\n') != 2:
        raise AssertionError("Preview transport verification bracket drifted")
    if source.count('if [ "$preview_evidence_enabled" = yes ]; then') < 8:
        raise AssertionError("Preview transport optional-evidence bracket drifted")
    if source.count("preview_evidence_enabled=yes") != 2:
        raise AssertionError("Preview transport host/guest enablement drifted")
    for legacy_requirement in (
        "core package requires --preview-plugin",
        "core package requires --preview-evidence-source-list",
    ):
        if legacy_requirement in source:
            raise AssertionError(
                "generic Preview transport regained a mandatory legacy input"
            )
    production_start = source.index("    compile_command=(swiftc")
    production = source[production_start : source.index(
        "    local effective_output_map_count", production_start
    )]
    if '"${plugin_arguments[@]}"' in production or "-load-plugin-executable" in production:
        raise AssertionError("production compile regained a Preview plugin argument")
    package_start = source.index("            package_command=(swiftc")
    package = source[package_start : source.index(
        "            package_stdout=", package_start
    )]
    if '"${plugin_arguments[@]}"' in package or "-load-plugin-executable" in package:
        raise AssertionError("package compile regained a Preview plugin argument")


def validate_derived_source_provider_contract(source: str) -> None:
    required_once = (
        'compiler_input_providers.py" generate',
        "derived_root=$output/derived-sources",
        '<"$derived_root/derived-sources.nul"',
        'derived_sources+=("$derived_source")',
        "derived-source-attestation-sha256\\t%s\\n",
        "find derived-sources -type f -print0",
    )
    drifted = [token for token in required_once if source.count(token) != 1]
    if drifted:
        raise AssertionError(f"derived-source provider contract drifted: {drifted}")
    if source.count('compiler_input_providers.py" verify') != 2:
        raise AssertionError("derived-source provider verification bracket drifted")
    app = source.index('"${production_app_sources[@]}" "${derived_sources[@]}"')
    platform = source.index('"${platform_sources[@]}"', app)
    if app >= platform:
        raise AssertionError("derived-source compile ordering drifted")


def validate_local_package_module_object_boundary(source: str) -> None:
    required_once = (
        'local_package_graph.py" prepare-build',
        'local_package_graph.py" emit-target-record',
        'local_package_graph.py" verify-build-contract',
        'package_import_arguments=(-I "$package_module_root")',
        '-module-name "$package_module"',
        '-emit-module -emit-module-path "$package_module_output"',
        'package_objects+=("$package_object")',
        '"${package_objects[@]}" "${extra_objects[@]}")',
        "local package experimental feature is invalid",
        "local package compilation condition is invalid",
        "local package object link count is not one",
        "local linked_package_object_count=0",
    )
    drifted = [token for token in required_once if source.count(token) != 1]
    if source.count('local_package_graph.py" require-buildable') != 2:
        drifted.append('local_package_graph.py" require-buildable (host+guest)')
    if source.count('local_package_graph.py" verify-plan-binding') != 2:
        drifted.append('local_package_graph.py" verify-plan-binding (host+guest)')
    if drifted:
        raise AssertionError(f"local package module/object boundary drifted: {drifted}")
    preflight = source.rindex('local_package_graph.py" require-buildable')
    compile_target = source.index("== compile local Swift-package target")
    application_compile = source.index(
        "== compile ordered application sources with packaged compiler plugins"
    )
    if not preflight < compile_target < application_compile:
        raise AssertionError("local package build order drifted")


def validate_c_family_package_boundary(source: str) -> None:
    required_once = (
        "for tool in python3 swiftc clang-18 clang++-18",
        '"$platform" --emit-swift-arguments --absolute-package-paths',
        "local swift_sdk_root= swift_sdk_argument_count=0 swift_argument_index",
        'swift_sdk_root=${swift_arguments[swift_argument_index + 1]}',
        '"$swift_sdk_argument_count" -eq 1',
        'require_directory "$swift_sdk_root" "rooted platform Swift SDK"',
        '<"$package_build_root/clang-import-arguments.nul"',
        '<"$package_build_root/clang-link-arguments.nul"',
        'package_import_arguments+=("${package_clang_import_arguments[@]}")',
        'package_clang_module_cache=$package_build_root/clang-module-cache',
        'mkdir "$package_clang_module_cache"',
        'require_regular "$package_module_output" "local package Clang module map"',
        '-target "$compiler_target" -isysroot "$swift_sdk_root"',
        '-fmodules -fmodules-cache-path="$package_clang_module_cache"',
        '-fmodule-name="$package_module"',
        'package_compiler=clang-18',
        'package_compiler=clang++-18',
        'package_command+=(-c "${package_sources[package_source_index]}"',
        '"${package_link_arguments[@]}"',
    )
    drifted = [token for token in required_once if source.count(token) != 1]
    if drifted:
        raise AssertionError(f"local package C-family boundary drifted: {drifted}")
    target_case = source.index('case "$package_target_type" in')
    swift_case = source.index("                swift)", target_case)
    clang_case = source.index("                clang)", target_case)
    swift_block = source[swift_case:clang_case]
    clang_block = source[
        clang_case : source.index(
            '                *) die "local package target has unsupported compiler family',
            clang_case,
        )
    ]
    if '-module-cache-path "$module_cache"' not in swift_block:
        raise AssertionError("package Swift import cache boundary drifted")
    if '-fmodules-cache-path="$package_clang_module_cache"' not in clang_block:
        raise AssertionError("package Clang cache boundary drifted")
    if '-fmodules-cache-path="$module_cache"' in clang_block:
        raise AssertionError("package Clang contaminated the Swift import cache")
    package_object = source.index('package_objects+=("$package_object")', clang_case)
    application_compile = source.index(
        "== compile ordered application sources with packaged compiler plugins"
    )
    if not target_case < clang_case < package_object < application_compile:
        raise AssertionError("local package C-family build ordering drifted")


def validate_remote_package_cache_boundary(source: str) -> None:
    required_once = (
        "[--remote-package-materializations EXACT_MATERIALIZATION_SET_JSON]",
        "[--remote-package-cache CONTENT_ADDRESSED_CACHE_ROOT]",
        'remote_plan_arguments=(--remote-materializations "$remote_materializations"',
        'docker_command+=(-v "$remote_cache:/remote-packages:ro")',
        "--remote-package-cache-inside /remote-packages",
        "remote_materializations_sha256\\t%s\\n",
        'if [[ "${package_record[5 + package_cursor]}" = /* ]]; then',
        'package_sources+=("${package_record[5 + package_cursor]}")',
    )
    drifted = [token for token in required_once if source.count(token) != 1]
    if drifted:
        raise AssertionError(f"remote package cache boundary drifted: {drifted}")
    if (
        source.count('remote_cache_arguments=(--remote-cache-root "$remote_cache")')
        != 2
    ):
        raise AssertionError("remote package cache host/guest binding drifted")
    if source.count('"${remote_cache_arguments[@]}"') < 8:
        raise AssertionError("remote package cache re-verification bracket drifted")
    forbidden = (
        'cp "$remote_cache"',
        'docker_command+=(-v "$remote_cache:/remote-packages")',
        "chmod -R",
    )
    if any(token in source for token in forbidden):
        raise AssertionError("remote package cache lost its read-only boundary")


def validate_nounset_dependent_path_contract(source: str) -> None:
    required = (
        "local app frameworks executable libraries",
        "app=$output/$product.app",
        "frameworks=$app/Contents/Frameworks",
        "executable=$app/Contents/MacOS/$product ;;",
        "frameworks=$app/Frameworks",
        "executable=$app/$product ;;",
    )
    lines = [line.strip() for line in source.splitlines()]
    if any(lines.count(token) != 1 for token in required):
        raise AssertionError("nounset-safe dependent path declaration drifted")
    positions = [lines.index(token) for token in required]
    if positions != sorted(positions):
        raise AssertionError("nounset-safe dependent path declaration drifted")
    unsafe = (
        "local app=$output/$product.app frameworks=$app/Contents/Frameworks",
        "local executable=$app/Contents/MacOS/$product libraries",
    )
    if any(token in source for token in unsafe):
        raise AssertionError("nounset-unsafe dependent path declaration returned")


def validate_no_chained_local_assignments(source: str) -> None:
    assignment = re.compile(r"(?:^|\s)([A-Za-z_][A-Za-z0-9_]*)=([^\s;]+)")
    failures: list[str] = []
    for number, line in enumerate(source.splitlines(), 1):
        if not re.match(r"^\s*local(?:\s|$)", line):
            continue
        seen: list[str] = []
        for match in assignment.finditer(line):
            name, value = match.groups()
            for earlier in seen:
                reference = re.compile(
                    rf"\$(?:{re.escape(earlier)}\b|\{{{re.escape(earlier)}\}})"
                )
                if reference.search(value):
                    failures.append(f"line {number}: {name} depends on {earlier}")
            seen.append(name)
    if failures:
        raise AssertionError(f"nounset-unsafe chained local assignment: {failures}")


def validate_python_invocations_are_bytecode_free(source: str) -> None:
    failures: list[int] = []
    for number, line in enumerate(source.splitlines(), 1):
        if not re.search(r"(?:^|\s)python3(?:\s|$)", line):
            continue
        if "command -v python3" in line or "for tool in python3" in line:
            continue
        if not re.search(r"(?:^|\s)python3 -B(?:\s|$)", line):
            failures.append(number)
    if failures:
        raise AssertionError(
            f"production Python invocation can write bytecode: lines={failures}"
        )


class PortableApplicationGuestDriverTests(unittest.TestCase):
    def test_host_delegates_resource_binding_to_the_shared_runtime_contract(
        self,
    ) -> None:
        source = (XCODEPLAN / "PortableUIKitApplicationHost.swift").read_text(
            encoding="utf-8"
        )
        self.assertIn(
            "OpenUIKitRuntime.configureApplicationBundleResources(at: resources)",
            source,
        )
        self.assertNotIn("OpenUIKitRuntime.resourceRoot =", source)
        self.assertNotIn("FontEngine.advance", source)
        self.assertNotIn("DejaVuSans.ttf", source)

        run_body = source[source.index("static func run(") :]
        self.assertIn("prepare()", run_body)
        self.assertNotIn("configurePackagedResources()", run_body)

    def test_driver_owns_complete_generic_compile_package_launch_path(self) -> None:
        script = (XCODEPLAN / "build_portable_application_guest.sh").read_text(
            encoding="utf-8"
        )
        self.assertIn("mapfile -d '' -t relative_sources", script)
        self.assertIn('relative_sources <"$output/app-sources.nul"', script)
        self.assertIn('"${app_sources[@]}"', script)
        self.assertIn("GeneratedSceneBootstrap.swift", script)
        self.assertIn("PortableUIKitApplicationHost.swift", script)
        self.assertIn("RunLoop.swift", script)
        self.assertNotIn("ReminderSceneRuntimeSupport", script)
        self.assertNotIn("Reminder", script)
        self.assertIn('-v "$source_root:/app:ro"', script)
        self.assertIn('-v "$platform:/platform:ro"', script)
        self.assertIn('-v "$SUPPORT_ROOT:/support:ro"', script)
        self.assertIn("--container-image SHA256_IMAGE_ID", script)
        self.assertIn("--preview-evidence-source-list", script)
        self.assertIn("container image must be an exact sha256 content ID", script)
        self.assertIn("docker image inspect --format '{{.Id}}'", script)
        self.assertIn("expected linux/arm64", script)
        self.assertIn("container_image\\t%s\\tplatform=%s", script)
        self.assertIn('docker_command+=("$container_image"', script)
        self.assertNotIn("docker_command+=(swift-macho-spike:noble", script)
        self.assertIn("application_platform_package.py", script)
        self.assertIn('--bundle-layout "$bundle_layout"', script)
        self.assertIn('-target "$compiler_target"', script)
        self.assertIn('ios) application_framework_rpath=@executable_path/Frameworks', script)
        self.assertIn("materialize_application_bundle.py", script)
        self.assertEqual(
            script.count("--require-canonical-project-inventory"),
            1,
        )
        self.assertIn("-load-plugin-executable", script)
        self.assertIn("--emit-app-diagnostic-arguments", script)
        self.assertIn("app-macro-expansions.stderr", script)
        self.assertIn("application-link-objects.tsv", script)
        self.assertIn("DeveloperToolsSupport object link count is not one", script)
        self.assertIn("developer_tools_support_object", script)
        self.assertIn("focus_widget_guest_attest.pl", script)
        self.assertIn("PORTABLE_UIKIT_HOST_ACTIVE windows=1", script)
        self.assertIn("PORTABLE_UIKIT_HOST_LOOP_OK turns=3 paced=true", script)
        self.assertIn("PORTABLE_APPLICATION_GUEST_OK", script)

    def test_preview_executable_export_is_exact_and_mutation_is_refused(self) -> None:
        source = (XCODEPLAN / "build_portable_application_guest.sh").read_text(
            encoding="utf-8"
        )
        validate_preview_executable_export_contract(source)
        for token in (
            '-exported_symbol "$PREVIEW_EXECUTABLE_EXPORT_SYMBOL"',
            "uikit_preview_import_count=$(nm_symbol_count --undefined-only",
            "preview_definition_count=$(nm_symbol_count --defined-only",
            "executable_preview_export_count=$(nm_symbol_count --defined-only",
        ):
            with self.subTest(deleted=token):
                with self.assertRaisesRegex(AssertionError, "export contract"):
                    validate_preview_executable_export_contract(
                        source.replace(token, "", 1)
                    )
        with self.assertRaisesRegex(AssertionError, "export contract"):
            validate_preview_executable_export_contract(
                source.replace(
                    PREVIEW_EXECUTABLE_EXPORT_SYMBOL,
                    PREVIEW_EXECUTABLE_EXPORT_SYMBOL + "_MUTATED",
                    1,
                )
            )

    def test_multi_source_object_map_is_exact_and_forbids_bad_scheduling(self) -> None:
        source = (XCODEPLAN / "build_portable_application_guest.sh").read_text(
            encoding="utf-8"
        )
        validate_multi_source_object_map_contract(source)
        for token in (
            'application_object_contract.py" create-output-map',
            'application_object_contract.py" verify-objects',
            'application_object_contract.py" reverify-objects',
            '-output-file-map "$output_map" "${compile_sources[@]}"',
            '"${#compile_sources[@]}" -gt 1',
            '"$effective_output_map_count" -eq 1',
            '"$effective_wmo_count" -eq 0',
            '"$effective_disable_batch_count" -eq 0',
            '"$effective_dump_count" -eq 0',
            "local serial_job_argument=-j1",
            '"${plugin_arguments[@]}" "$serial_job_argument"\n'
            '            "${diagnostic_arguments[@]}"',
            "local preview_effective_serial_job_count=0",
            '"$preview_effective_serial_job_count" -eq 1',
            'swift_compiler_output_has_failure_diagnostic "$preview_stderr"',
            '"$effective_serial_job_count" -eq 1',
            '"${package_objects[@]}" "${extra_objects[@]}")',
        ):
            with self.subTest(deleted=token):
                with self.assertRaisesRegex(AssertionError, "compile contract"):
                    validate_multi_source_object_map_contract(
                        source.replace(token, "", 1)
                    )
        with self.assertRaisesRegex(AssertionError, "compile contract"):
            validate_multi_source_object_map_contract(
                source.replace(
                    '-output-file-map "$output_map" "${compile_sources[@]}"',
                    '-output-file-map "$output_map" "${compile_sources[@]}"\n'
                    '-output-file-map "$output_map" "${compile_sources[@]}"',
                    1,
                )
            )
        with self.assertRaisesRegex(AssertionError, "compile contract"):
            validate_multi_source_object_map_contract(
                source.replace("local serial_job_argument=-j1",
                               "local serial_job_argument=-j2", 1)
            )

    def test_local_packages_are_separate_topological_module_object_boundaries(
        self,
    ) -> None:
        source = (XCODEPLAN / "build_portable_application_guest.sh").read_text(
            encoding="utf-8"
        )
        validate_local_package_module_object_boundary(source)
        for token in (
            'local_package_graph.py" prepare-build',
            'local_package_graph.py" emit-target-record',
            '-emit-module -emit-module-path "$package_module_output"',
            'package_objects+=("$package_object")',
            '"${package_objects[@]}" "${extra_objects[@]}")',
        ):
            with self.subTest(deleted=token):
                with self.assertRaisesRegex(AssertionError, "module/object boundary"):
                    validate_local_package_module_object_boundary(
                        source.replace(token, "", 1)
                    )

    def test_c_family_packages_are_clang_modules_and_exact_link_objects(self) -> None:
        source = (XCODEPLAN / "build_portable_application_guest.sh").read_text(
            encoding="utf-8"
        )
        validate_c_family_package_boundary(source)
        for token in (
            "for tool in python3 swiftc clang-18 clang++-18",
            '"$platform" --emit-swift-arguments --absolute-package-paths',
            '"$swift_sdk_argument_count" -eq 1',
            '<"$package_build_root/clang-import-arguments.nul"',
            'require_regular "$package_module_output" "local package Clang module map"',
            '-target "$compiler_target" -isysroot "$swift_sdk_root"',
            'package_command+=(-c "${package_sources[package_source_index]}"',
            '"${package_link_arguments[@]}"',
        ):
            with self.subTest(deleted=token):
                with self.assertRaisesRegex(AssertionError, "C-family"):
                    validate_c_family_package_boundary(source.replace(token, "", 1))

    def test_remote_packages_use_the_same_module_boundary_from_a_read_only_cache(
        self,
    ) -> None:
        source = (XCODEPLAN / "build_portable_application_guest.sh").read_text(
            encoding="utf-8"
        )
        validate_remote_package_cache_boundary(source)
        for token in (
            'docker_command+=(-v "$remote_cache:/remote-packages:ro")',
            "--remote-package-cache-inside /remote-packages",
            'remote_cache_arguments=(--remote-cache-root "$remote_cache")',
            'if [[ "${package_record[5 + package_cursor]}" = /* ]]; then',
        ):
            with self.subTest(deleted=token):
                with self.assertRaisesRegex(AssertionError, "remote package cache"):
                    validate_remote_package_cache_boundary(source.replace(token, "", 1))

    def test_preview_plugins_are_generic_and_legacy_evidence_is_optional(self) -> None:
        source = (XCODEPLAN / "build_portable_application_guest.sh").read_text(
            encoding="utf-8"
        )
        validate_preview_transport_contract(source)
        for token in (
            "local preview_evidence_enabled=no legacy_preview_evidence_count=0",
            '"--preview-evidence-source-list requires --preview-plugin"',
            '"--preview-plugin requires --preview-evidence-source-list"',
            'materialize-preview-expansion \\\n',
            'verify-preview-materialization \\\n',
            'mapfile -d \'\' -t production_app_sources <"$materialized_source_list"',
            '"$materialized_difference_count" -eq 1',
            'preview_original_source=${app_sources[$source_index]}',
            'preview_materialized_source=${production_app_sources[$source_index]}',
            'application production compile retains a Preview plugin argument',
            'application production compile retains the original #Preview source',
            'production-plugin-load-count\\t%s\\n',
            'original-preview-source-count\\t%s\\n',
            'ADDITIONAL_SWIFT_DRIVER_FLAGS must be absent for an attested compile plan',
            'find preview-materialized-sources -type f -print0',
        ):
            with self.subTest(deleted=token):
                with self.assertRaisesRegex(AssertionError, "transport"):
                    validate_preview_transport_contract(
                        source.replace(token, "", 1)
                    )
        with self.assertRaisesRegex(AssertionError, "production compile"):
            validate_preview_transport_contract(
                source.replace(
                    '"$serial_job_argument" -emit-object',
                    '"${plugin_arguments[@]}" "$serial_job_argument" -emit-object',
                    1,
                )
            )
        with self.assertRaisesRegex(AssertionError, "package compile"):
            validate_preview_transport_contract(
                source.replace(
                    '-module-name "$package_module"',
                    '-module-name "$package_module" "${plugin_arguments[@]}"',
                    1,
                )
            )

    def test_derived_source_provider_is_generated_and_reverified(self) -> None:
        source = (XCODEPLAN / "build_portable_application_guest.sh").read_text(
            encoding="utf-8"
        )
        validate_derived_source_provider_contract(source)
        for token in (
            'compiler_input_providers.py" generate',
            'compiler_input_providers.py" verify',
            '<"$derived_root/derived-sources.nul"',
            'derived_sources+=("$derived_source")',
            "find derived-sources -type f -print0",
        ):
            with self.subTest(deleted=token):
                with self.assertRaisesRegex(AssertionError, "derived-source"):
                    validate_derived_source_provider_contract(
                        source.replace(token, "", 1)
                    )

    def test_dependent_application_paths_are_nounset_safe(self) -> None:
        source = (XCODEPLAN / "build_portable_application_guest.sh").read_text(
            encoding="utf-8"
        )
        validate_nounset_dependent_path_contract(source)
        validate_no_chained_local_assignments(source)
        for token in (
            "local app frameworks executable libraries",
            "app=$output/$product.app",
            "frameworks=$app/Contents/Frameworks",
            "executable=$app/Contents/MacOS/$product ;;",
            "frameworks=$app/Frameworks",
            "executable=$app/$product ;;",
        ):
            with self.subTest(deleted=token):
                with self.assertRaisesRegex(AssertionError, "nounset-safe"):
                    mutated = "\n".join(
                        line
                        for line in source.splitlines()
                        if line.strip() != token
                    )
                    validate_nounset_dependent_path_contract(
                        mutated
                    )
        with self.assertRaisesRegex(AssertionError, "chained local"):
            validate_no_chained_local_assignments(
                "f() {\n"
                "    local output=/tmp/result cache=$output/module-cache\n"
                "}\n"
            )

    def test_production_python_invocations_are_bytecode_free(self) -> None:
        source = (XCODEPLAN / "build_portable_application_guest.sh").read_text(
            encoding="utf-8"
        )
        validate_python_invocations_are_bytecode_free(source)
        with self.assertRaisesRegex(AssertionError, "write bytecode"):
            validate_python_invocations_are_bytecode_free(
                source.replace("python3 -B -", "python3 -", 1)
            )

    def test_compiler_failure_classifier_rejects_unlocated_errors(self) -> None:
        classifier = XCODEPLAN / "swift_compiler_diagnostics.sh"
        cases = {
            "sdk-warning": (
                "warning: Could not read SDKSettings.json for SDK at: sdk\n",
                False,
            ),
            "macro-source-text": ('    let message = "error: harmless"\n', False),
            "located-error": ("/app/View.swift:8:2: error: broken\n", True),
            "internal-error": ("Internal Error: Corrupted JSON\n", True),
            "unlocated-error": ("swiftc: error: frontend failed\n", True),
            "fatal-error": ("fatal error: malformed module\n", True),
            "llvm-error": ("LLVM ERROR: bad machine code\n", True),
        }
        with tempfile.TemporaryDirectory() as temporary:
            for name, (contents, expected_failure) in cases.items():
                with self.subTest(name=name):
                    stream = Path(temporary) / name
                    stream.write_text(contents, encoding="utf-8")
                    result = subprocess.run(
                        [
                            "/bin/bash",
                            "-c",
                            'source "$1"; swift_compiler_output_has_failure_diagnostic "$2"',
                            "classifier-test",
                            str(classifier),
                            str(stream),
                        ],
                        stdout=subprocess.PIPE,
                        stderr=subprocess.PIPE,
                        check=False,
                    )
                    self.assertEqual(
                        result.returncode == 0,
                        expected_failure,
                        f"{name}: rc={result.returncode} stderr={result.stderr!r}",
                    )

    def test_legacy_static_link_closes_uuid_compatibility_symbols(self) -> None:
        script = (XCODEPLAN / "build_and_run_reminder_scene_guest.sh").read_text(
            encoding="utf-8"
        )
        self.assertIn('"$full/foundation/cshims/uuid.o"', script)
        self.assertIn('"$full/foundation/essentials/uuid_compat.o"', script)

    def test_harness_installs_python_for_generic_guest_drivers(self) -> None:
        dockerfile = (REPOSITORY / "harness" / "Dockerfile").read_text(encoding="utf-8")
        builder = (REPOSITORY / "harness" / "build_image.sh").read_text(
            encoding="utf-8"
        )
        self.assertIn(
            "@sha256:29b983751c605c2d3102d2ab93438c6e0cadf110d9d2aa6e929b6dec9dcb7cbc",
            dockerfile,
        )
        self.assertIn("libc++-18-dev", dockerfile)
        self.assertIn("python3", dockerfile)
        self.assertIn("libc++-18-dev=1:18.1.3-1ubuntu1", dockerfile)
        self.assertIn("python3=3.12.3-0ubuntu2.1", dockerfile)
        self.assertIn("--platform linux/arm64", builder)
        self.assertIn("runtime-attestation.tsv", builder)
        self.assertIn("libcxx_compile_and_run", builder)
        self.assertIn(".INVALID-DO-NOT-USE", builder)

    def test_driver_refuses_a_mutable_image_tag_before_docker(self) -> None:
        script = XCODEPLAN / "build_portable_application_guest.sh"
        with tempfile.TemporaryDirectory() as temporary:
            fake_docker = Path(temporary) / "docker"
            fake_docker.write_text("#!/bin/sh\nexit 91\n", encoding="utf-8")
            fake_docker.chmod(0o755)
            environment = os.environ.copy()
            environment["PATH"] = f"{temporary}:{environment['PATH']}"
            result = subprocess.run(
                [
                    "/bin/bash",
                    str(script),
                    "--inventory",
                    "/inventory.json",
                    "--source-root",
                    "/sources",
                    "--platform-package",
                    "/platform",
                    "--container-image",
                    "swift-macho-spike:noble",
                    "--output-root",
                    "/new-output",
                ],
                text=True,
                stdout=subprocess.PIPE,
                stderr=subprocess.PIPE,
                env=environment,
                check=False,
            )
        self.assertEqual(result.returncode, 2, result.stderr)
        self.assertIn("exact sha256 content ID", result.stderr)


if __name__ == "__main__":
    unittest.main()
