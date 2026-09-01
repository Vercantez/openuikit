from pathlib import Path
import subprocess
import tempfile
import unittest


HARNESS = Path(__file__).resolve().parents[1]
DRIVER = HARNESS / "linux_gui_harness.sh"
ENTRYPOINT = HARNESS / "container_entrypoint.sh"
DOCKERFILE = HARNESS / "Dockerfile"
README = HARNESS / "README.md"


class LinuxGUIHarnessTests(unittest.TestCase):
    def test_shell_sources_are_syntactically_valid(self) -> None:
        for source in (DRIVER, ENTRYPOINT):
            subprocess.run(["bash", "-n", str(source)], check=True)

    def test_help_and_url_are_available_without_docker(self) -> None:
        help_result = subprocess.run(
            [str(DRIVER), "--help"],
            check=True,
            text=True,
            capture_output=True,
        )
        self.assertIn("build --source DIR --commit SHA --tree SHA", help_result.stdout)
        self.assertIn("health", help_result.stdout)
        self.assertIn("relaunch", help_result.stdout)
        self.assertIn("stop", help_result.stdout)
        url_result = subprocess.run(
            [str(DRIVER), "url", "--port", "6123"],
            check=True,
            text=True,
            capture_output=True,
        )
        self.assertEqual(
            url_result.stdout.strip(),
            "http://127.0.0.1:6123/vnc.html?autoconnect=1&resize=scale",
        )

    def test_audit_accepts_exact_commit_tree_and_rejects_drift(self) -> None:
        with tempfile.TemporaryDirectory() as temporary:
            repository = Path(temporary) / "source"
            repository.mkdir()
            subprocess.run(["git", "init", "-q", str(repository)], check=True)
            subprocess.run(
                ["git", "-C", str(repository), "config", "user.name", "Harness Test"],
                check=True,
            )
            subprocess.run(
                [
                    "git",
                    "-C",
                    str(repository),
                    "config",
                    "user.email",
                    "harness@example.invalid",
                ],
                check=True,
            )
            (repository / "Package.swift").write_text(
                "// swift-tools-version: 6.0\n", encoding="utf-8"
            )
            subprocess.run(["git", "-C", str(repository), "add", "Package.swift"], check=True)
            subprocess.run(
                ["git", "-C", str(repository), "commit", "-q", "-m", "fixture"],
                check=True,
            )
            commit = subprocess.check_output(
                ["git", "-C", str(repository), "rev-parse", "HEAD^{commit}"],
                text=True,
            ).strip()
            tree = subprocess.check_output(
                ["git", "-C", str(repository), "rev-parse", "HEAD^{tree}"],
                text=True,
            ).strip()
            result = subprocess.run(
                [
                    str(DRIVER),
                    "audit",
                    "--source",
                    str(repository),
                    "--commit",
                    commit,
                    "--tree",
                    tree,
                ],
                check=True,
                text=True,
                capture_output=True,
            )
            self.assertIn("GUI_SOURCE_AUDIT_OK", result.stdout)
            self.assertIn(f"commit={commit}", result.stdout)
            self.assertIn(f"tree={tree}", result.stdout)

            drift = subprocess.run(
                [
                    str(DRIVER),
                    "audit",
                    "--source",
                    str(repository),
                    "--commit",
                    commit,
                    "--tree",
                    "0" * 40,
                ],
                text=True,
                capture_output=True,
            )
            self.assertEqual(drift.returncode, 2)
            self.assertIn("tree mismatch", drift.stderr)

    def test_build_contract_is_source_pinned_and_cold_capable(self) -> None:
        driver = DRIVER.read_text(encoding="utf-8")
        dockerfile = DOCKERFILE.read_text(encoding="utf-8")
        for token in (
            'archive --format=tar',
            "--no-cache",
            "commit must be a full lowercase 40-hex object ID",
            "tree must be a full lowercase 40-hex object ID",
            "SOURCE_ARCHIVE_SHA256",
            "GUI_IMAGE_BUILD_OK",
        ):
            self.assertIn(token, driver)
        for token in (
            "swift@sha256:29b983751c605c2d3102d2ab93438c6e0cadf110d9d2aa6e929b6dec9dcb7cbc",
            "org.opencontainers.image.revision",
            "org.opencontainers.image.source-tree",
            "source-provenance.tsv",
            "rm -rf .build",
            "-Xswiftc -disable-cmo",
        ):
            self.assertIn(token, dockerfile)
        self.assertNotIn(":/opt/application", driver)
        self.assertNotIn("sed -i", driver)
        self.assertNotIn("patch ", driver)

    def test_display_and_health_contract_is_end_to_end(self) -> None:
        driver = DRIVER.read_text(encoding="utf-8")
        entrypoint = ENTRYPOINT.read_text(encoding="utf-8")
        for token in (
            "Xvfb",
            "x11vnc",
            "websockify",
            "SDL_VIDEODRIVER=x11",
            "xdotool search --onlyvisible",
            "initial.png",
            "ready.env",
            "OPENPLATFORM_GUI_READY",
        ):
            self.assertIn(token, entrypoint)
        for token in (
            '127.0.0.1:${port}:6080',
            "xwininfo -id",
            "health.png",
            "standard_deviation",
            "GUI_HEALTH_OK",
            "runtime/image commit mismatch",
            "runtime/image tree mismatch",
        ):
            self.assertIn(token, driver)

    def test_documentation_distinguishes_native_and_true_ios_routes(self) -> None:
        documentation = README.read_text(encoding="utf-8")
        self.assertIn("native Linux/OpenUIKit display route", documentation)
        self.assertIn("not evidence", documentation)
        self.assertIn("platform-7 Mach-O guest", documentation)
        self.assertIn("not represented as an external", documentation)
        self.assertIn("--cold", documentation)
        self.assertIn("127.0.0.1:6080", documentation)


if __name__ == "__main__":
    unittest.main()
