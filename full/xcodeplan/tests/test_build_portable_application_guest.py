from __future__ import annotations

import os
from pathlib import Path
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


def validate_multi_source_single_object_contract(source: str) -> None:
    required_once = (
        "application_codegen_arguments=(-wmo)",
        'local -a compile_sources=("${app_sources[@]}" "${platform_sources[@]}")',
        '"${#compile_sources[@]}" -gt 1',
        '"$effective_wmo_count" -eq 1',
        "application effective -wmo count",
        'printf \'whole-module-flag\\t-wmo\\tcount=%s\\n\'',
        '"${compile_sources[@]}"',
    )
    drifted = [token for token in required_once if source.count(token) != 1]
    if drifted:
        raise AssertionError(
            f"multi-source single-object compile contract drifted: {drifted}"
        )
    if source.count('"${application_codegen_arguments[@]}"') != 2:
        raise AssertionError(
            "multi-source single-object compile contract drifted: "
            "code-generation argument count/check wiring"
        )
    if source.count("-whole-module-optimization") != 1:
        raise AssertionError("noncanonical whole-module refusal drifted")


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

    def test_multi_source_single_object_requires_exactly_one_wmo(self) -> None:
        source = (XCODEPLAN / "build_portable_application_guest.sh").read_text(
            encoding="utf-8"
        )
        validate_multi_source_single_object_contract(source)
        for token in (
            "application_codegen_arguments=(-wmo)",
            '"${application_codegen_arguments[@]}"',
            '"${#compile_sources[@]}" -gt 1',
            '"$effective_wmo_count" -eq 1',
            '"${compile_sources[@]}"',
        ):
            with self.subTest(deleted=token):
                with self.assertRaisesRegex(AssertionError, "compile contract"):
                    validate_multi_source_single_object_contract(
                        source.replace(token, "", 1)
                    )
        with self.assertRaisesRegex(AssertionError, "compile contract"):
            validate_multi_source_single_object_contract(
                source.replace(
                    "application_codegen_arguments=(-wmo)",
                    "application_codegen_arguments=(-wmo -wmo)",
                    1,
                )
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
