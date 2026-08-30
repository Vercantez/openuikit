from __future__ import annotations

import os
from pathlib import Path
import subprocess
import tempfile
import unittest


HERE = Path(__file__).resolve().parent
XCODEPLAN = HERE.parent
REPOSITORY = XCODEPLAN.parent.parent


class PortableApplicationGuestDriverTests(unittest.TestCase):
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
