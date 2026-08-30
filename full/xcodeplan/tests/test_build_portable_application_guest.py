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
        "PREVIEW_EXECUTABLE_EXPORT_SYMBOL="
        f"'{PREVIEW_EXECUTABLE_EXPORT_SYMBOL}'"
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
        '"${app_sources[@]}" "${derived_sources[@]}" "${platform_sources[@]}"',
        '"${#compile_sources[@]}" -gt 1',
        'application_object_contract.py" create-output-map',
        'application_object_contract.py" verify-objects',
        'application_object_contract.py" reverify-objects',
        '-output-file-map "$output_map" "${compile_sources[@]}"',
        '"$effective_output_map_count" -eq 1',
        '"$effective_wmo_count" -eq 0',
        '"$effective_disable_batch_count" -eq 0',
        '"$effective_dump_count" -eq 0',
        'object_audit=$output/application-object-audit.json',
        '--audit "$output/application-cross-file-symbols.json"',
        '--cross-file-audit "$output/application-cross-file-symbols.json"',
        '--audit "$output/application-linked-symbols.json"',
        '-o "$executable" "${application_objects[@]}" "${extra_objects[@]}")',
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


def validate_nounset_dependent_path_contract(source: str) -> None:
    required = (
        "local app frameworks executable libraries",
        "app=$output/$product.app",
        "frameworks=$app/Contents/Frameworks",
        "executable=$app/Contents/MacOS/$product",
    )
    lines = source.splitlines()
    exact = [f"    {token}" for token in required]
    if any(lines.count(line) != 1 for line in exact):
        raise AssertionError("nounset-safe dependent path declaration drifted")
    positions = [lines.index(line) for line in exact]
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
                reference = re.compile(rf"\$(?:{re.escape(earlier)}\b|\{{{re.escape(earlier)}\}})")
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
    def test_host_binds_and_probes_resources_before_font_file_fallback(self) -> None:
        source = (XCODEPLAN / "PortableUIKitApplicationHost.swift").read_text(
            encoding="utf-8"
        )
        resource_binding = source.index("OpenUIKitRuntime.resourceRoot = openUIKit")
        table_probe = source.index("let metricsProbe = FontEngine.advance(")
        fallback_binding = source.index(
            'OpenUIKitRuntime.fontPaths["system"] = openUIKit'
        )
        self.assertLess(resource_binding, table_probe)
        self.assertLess(table_probe, fallback_binding)
        self.assertIn("guard metricsProbe > 0", source)

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
        self.assertIn("core_guest_package.py", script)
        self.assertIn("materialize_application_bundle.py", script)
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
            '-o "$executable" "${application_objects[@]}" "${extra_objects[@]}")',
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
            "executable=$app/Contents/MacOS/$product",
        ):
            with self.subTest(deleted=token):
                with self.assertRaisesRegex(AssertionError, "nounset-safe"):
                    validate_nounset_dependent_path_contract(
                        source.replace(f"    {token}\n", "", 1)
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
        dockerfile = (REPOSITORY / "harness" / "Dockerfile").read_text(
            encoding="utf-8"
        )
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
