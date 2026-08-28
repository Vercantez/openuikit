#!/usr/bin/env python3
"""Positive and adversarial controls for the pinned Focus Widget proof."""

from __future__ import annotations

import copy
import os
from pathlib import Path
import subprocess
import sys
import tempfile
import unittest
from unittest.mock import patch

import widget_proof as subject


HERE = Path(__file__).resolve().parent
SWIFT_MACHO_LINUX = HERE.parent.parent
FOCUS_SOURCE = SWIFT_MACHO_LINUX / "scratch" / "ladder-corpus" / "focus-ios"
OPENUIKIT_SOURCE = SWIFT_MACHO_LINUX.parent / "uikit"
SNAPKIT_SOURCE = SWIFT_MACHO_LINUX / "scratch" / "xcodeplan-deps" / "SnapKit"
POLICY_PATH = HERE / "widget-proof.json"


def run(command: list[str]) -> None:
    subprocess.run(
        command,
        check=True,
        stdout=subprocess.DEVNULL,
        stderr=subprocess.DEVNULL,
        env=subject.controlled_environment(),
    )


def clone_at(source: Path, destination: Path, commit: str) -> None:
    run(["git", "clone", "--quiet", "--shared", "--no-checkout", str(source), str(destination)])
    run(
        [
            "git", "-c", "core.fsmonitor=false", "-c", f"core.hooksPath={os.devnull}",
            "-C", str(destination), "checkout", "--quiet", "--detach", commit,
        ]
    )


class PolicyTests(unittest.TestCase):
    def setUp(self) -> None:
        self.raw, self.policy = subject.load_policy(POLICY_PATH)

    def test_exact_policy_and_claim_boundary(self) -> None:
        self.assertEqual(self.policy, subject.expected_policy())
        self.assertEqual(self.raw, subject.canonical_json(self.policy))
        self.assertEqual(len(self.policy["target"]["sources"]), 2)
        self.assertEqual(self.policy["resources"]["file_count"], 5)
        self.assertEqual(self.policy["resources"]["byte_count"], 73131)
        self.assertFalse(self.policy["claims"]["linux_guest_link_or_run"])
        self.assertFalse(self.policy["claims"]["resource_catalog_compilation_or_decode"])
        self.assertTrue(all(not item["compiler_input"] for item in self.policy["port_context"].values()))

    def test_semantically_valid_drift_and_adaptation_key_refuse(self) -> None:
        changed = copy.deepcopy(self.policy)
        changed["target"]["source_digest"] = "0" * 64
        with tempfile.TemporaryDirectory(prefix="focus-widget-policy.") as temporary:
            path = Path(temporary) / "changed.json"
            path.write_bytes(subject.canonical_json(changed))
            with self.assertRaisesRegex(subject.ProofError, "reviewed Focus Widget"):
                subject.load_policy(path)
        changed = copy.deepcopy(self.policy)
        changed["adaptation"] = {"path": "generated/Widget/overlay.swift"}
        with self.assertRaisesRegex(subject.ProofError, "top-level keys"):
            subject._validate_policy_shape(changed)

    def test_path_escape_and_context_as_input_refuse(self) -> None:
        changed = copy.deepcopy(self.policy)
        changed["resources"]["stage_path"] = "resources/../escape"
        with self.assertRaisesRegex(subject.ProofError, "normalized relative"):
            subject._validate_policy_shape(changed)
        changed = copy.deepcopy(self.policy)
        changed["port_context"]["openuikit"]["compiler_input"] = True
        with self.assertRaisesRegex(subject.ProofError, "outside the Widget compiler inputs"):
            subject._validate_policy_shape(changed)

    def test_ambient_git_redirects_are_removed(self) -> None:
        overrides = {
            "DEVELOPER_DIR": "/tmp/fake-developer",
            "GIT_DIR": "/tmp/decoy",
            "GIT_WORK_TREE": "/tmp/decoy",
            "PATH": "/tmp/fake-bin",
            "SDKROOT": "/tmp/fake-sdk",
            "SWIFT_DRIVER_SWIFT_EXEC": "/tmp/fake-driver",
            "SWIFT_EXEC": "/tmp/fake-swiftc",
            "TOOLCHAINS": "fake-toolchain",
        }
        with patch.dict(os.environ, overrides, clear=False):
            environment = subject.controlled_environment()
        self.assertNotIn("GIT_DIR", environment)
        self.assertNotIn("GIT_WORK_TREE", environment)
        for name in ("DEVELOPER_DIR", "SDKROOT", "SWIFT_DRIVER_SWIFT_EXEC", "SWIFT_EXEC", "TOOLCHAINS"):
            self.assertNotIn(name, environment)
        self.assertEqual(environment["GIT_CONFIG_GLOBAL"], os.devnull)
        self.assertEqual(environment["GIT_NO_REPLACE_OBJECTS"], "1")
        self.assertEqual(environment["PATH"], subject.SAFE_PATH)

    @unittest.skipUnless(sys.platform == "darwin", "Apple toolchain discovery requires macOS")
    def test_toolchain_discovery_ignores_path_and_driver_spoofing(self) -> None:
        with patch.dict(
            os.environ,
            {
                "DEVELOPER_DIR": "/tmp/fake-developer",
                "PATH": "/tmp/fake-bin",
                "SDKROOT": "/tmp/fake-sdk",
                "SWIFT_EXEC": "/tmp/fake-swiftc",
                "TOOLCHAINS": "fake-toolchain",
            },
            clear=False,
        ):
            toolchain = subject._apple_toolchain()
        self.assertEqual(toolchain.xcrun_path, "/usr/bin/xcrun")
        self.assertTrue(Path(toolchain.compiler_launcher_path).is_absolute())
        self.assertTrue(Path(toolchain.compiler_resolved_path).is_file())
        self.assertTrue(Path(toolchain.sdk_path).is_dir())
        self.assertNotIn("/tmp/fake", toolchain.compiler_launcher_path)
        self.assertNotIn("/tmp/fake", toolchain.sdk_path)
        self.assertRegex(toolchain.compiler_sha256, r"^[0-9a-f]{64}$")

    def test_stale_output_refuses_without_touching_it(self) -> None:
        with tempfile.TemporaryDirectory(prefix="focus-widget-output.") as temporary:
            root = Path(temporary)
            output = root / "proof"
            output.mkdir()
            sentinel = output / "keep"
            sentinel.write_bytes(b"user data")
            with self.assertRaisesRegex(subject.ProofError, "stale proof output"):
                subject._resolve_new_output(str(output), (root,))
            self.assertEqual(sentinel.read_bytes(), b"user data")


@unittest.skipUnless(FOCUS_SOURCE.is_dir(), "pinned Focus repository is unavailable")
class FocusAndStageTests(unittest.TestCase):
    def setUp(self) -> None:
        self.temporary = tempfile.TemporaryDirectory(prefix="focus-widget-source.")
        self.root = Path(self.temporary.name)
        self.clone = self.root / "focus"
        clone_at(FOCUS_SOURCE, self.clone, subject.FOCUS_COMMIT)
        self.repo = self.clone / "focus-ios"
        _, self.policy = subject.load_policy(POLICY_PATH)

    def tearDown(self) -> None:
        self.temporary.cleanup()

    def test_exact_capture_and_deterministic_stage(self) -> None:
        capture = subject.capture_focus(self.repo, self.policy)
        self.assertEqual(len(capture.sources), 2)
        self.assertEqual(len(capture.resources), 5)
        first = self.root / "first"
        second = self.root / "second"
        first.mkdir()
        second.mkdir()
        first_sources = subject.stage_source_inputs(first, capture, self.policy)
        second_sources = subject.stage_source_inputs(second, capture, self.policy)
        first_records = subject.stage_resources(first, capture, self.policy)
        second_records = subject.stage_resources(second, capture, self.policy)
        self.assertEqual(first_sources, second_sources)
        self.assertEqual(first_records, second_records)
        for record in first_sources:
            relative = Path(record["input_path"])
            self.assertEqual((first / relative).read_bytes(), (second / relative).read_bytes())
        for record in first_records:
            relative = Path(record["path"])
            self.assertEqual((first / relative).read_bytes(), (second / relative).read_bytes())

    def test_source_and_resource_drift_refuse_even_when_hidden_from_status(self) -> None:
        for expected, message in (
            (self.policy["target"]["sources"][0], "worktree bytes differ|bytes changed"),
            (self.policy["resources"]["files"][0], "worktree bytes differ|bytes changed"),
        ):
            git_path = f"focus-ios/{expected['path']}"
            run(["git", "-C", str(self.clone), "update-index", "--assume-unchanged", "--", git_path])
            path = self.repo / expected["path"]
            original = path.read_bytes()
            path.write_bytes(original + b"drift")
            with self.assertRaisesRegex(subject.ProofError, message):
                subject.capture_focus(self.repo, self.policy)
            path.write_bytes(original)
            run(["git", "-C", str(self.clone), "update-index", "--no-assume-unchanged", "--", git_path])

    def test_resource_tamper_and_generated_adaptation_refuse(self) -> None:
        capture = subject.capture_focus(self.repo, self.policy)
        output = self.root / "proof"
        output.mkdir()
        source_records = subject.stage_source_inputs(output, capture, self.policy)
        records = subject.stage_resources(output, capture, self.policy)
        staged_source = output / source_records[0]["input_path"]
        staged_source.write_bytes(staged_source.read_bytes() + b"drift")
        with self.assertRaisesRegex(subject.ProofError, "shipping-source input bytes changed"):
            subject.verify_source_inputs(output, capture, self.policy)
        staged = output / records[0]["path"]
        staged.write_bytes(staged.read_bytes() + b"drift")
        with self.assertRaisesRegex(subject.ProofError, "bytes changed"):
            subject.verify_stage(output, capture, self.policy)

        generated_output = self.root / "generated-proof"
        generated_output.mkdir()
        subject.write_generated_source(generated_output, self.policy)
        extra = generated_output / "generated" / "Widget" / "overlay.swift"
        extra.write_bytes(b"source adaptation")
        with self.assertRaisesRegex(subject.ProofError, "adaptation or unexpected input"):
            subject.verify_generated_source(generated_output, self.policy)

    def test_compiler_command_uses_only_proof_local_shipping_copies(self) -> None:
        capture = subject.capture_focus(self.repo, self.policy)
        output = self.root / "command-proof"
        output.mkdir()
        shipping_inputs = subject.stage_source_inputs(output, capture, self.policy)
        subject.write_generated_source(output, self.policy)
        fake_toolchain = subject.AppleToolchain(
            xcrun_path="/usr/bin/xcrun",
            xcrun_size=1,
            xcrun_sha256="0" * 64,
            compiler_launcher_path="/AppleToolchain/usr/bin/swiftc",
            compiler_resolved_path="/AppleToolchain/usr/bin/swift-frontend",
            compiler_size=1,
            compiler_sha256="1" * 64,
            sdk_path="/AppleSDK/MacOSX.sdk",
            version=b"Apple Swift version fixture\n",
        )
        command = subject._compiler_command(fake_toolchain, output, self.policy, shipping_inputs)
        for record in shipping_inputs:
            self.assertIn(str(output / record["input_path"]), command)
        for source in capture.sources:
            self.assertNotIn(str(self.repo / source.path), command)
        swift_inputs = [argument for argument in command if argument.endswith(".swift")]
        self.assertTrue(all(Path(argument).is_relative_to(output) for argument in swift_inputs))


@unittest.skipUnless(
    sys.platform == "darwin"
    and FOCUS_SOURCE.is_dir()
    and OPENUIKIT_SOURCE.is_dir()
    and SNAPKIT_SOURCE.is_dir(),
    "exact proof requires pinned repositories and the Apple Swift toolchain",
)
class ExactWidgetIntegrationTest(unittest.TestCase):
    def test_exact_module_emission_and_narrow_claims(self) -> None:
        with tempfile.TemporaryDirectory(prefix="focus-widget-integration.") as temporary:
            root = Path(temporary)
            focus_clone = root / "focus"
            ui_clone = root / "uikit"
            snapkit_clone = root / "snapkit"
            clone_at(FOCUS_SOURCE, focus_clone, subject.FOCUS_COMMIT)
            clone_at(OPENUIKIT_SOURCE, ui_clone, subject.OPENUIKIT_COMMIT)
            clone_at(SNAPKIT_SOURCE, snapkit_clone, subject.SNAPKIT_COMMIT)
            output = root / "proof"
            audit = subject.prove(
                str(focus_clone / "focus-ios"),
                str(ui_clone),
                str(snapkit_clone),
                str(POLICY_PATH),
                str(output),
            )
            self.assertEqual(audit["target"]["source_count"], 2)
            self.assertEqual(len(audit["generated_build_inputs"]), 1)
            self.assertEqual(audit["generated_build_inputs"][0]["classification"], "generated-build-input")
            self.assertEqual(audit["shipping_source_edits"], [])
            self.assertEqual(audit["shipping_source_inputs"]["source_count"], 2)
            self.assertEqual(audit["resource_stage"]["file_count"], 5)
            self.assertEqual(audit["resource_stage"]["byte_count"], 73131)
            self.assertEqual(len(audit["module_outputs"]), 4)
            self.assertEqual(audit["diagnostics"][0]["size"], 0)
            self.assertTrue(all(not item["compiler_input"] for item in audit["port_context"]))
            self.assertFalse(audit["claims"]["linux_guest_link_or_run"])
            self.assertFalse(audit["claims"]["resource_catalog_compilation_or_decode"])
            toolchain = audit["toolchain"]
            self.assertEqual(toolchain["discovery"]["path"], "/usr/bin/xcrun")
            self.assertRegex(toolchain["compiler"]["sha256"], r"^[0-9a-f]{64}$")
            self.assertTrue(Path(toolchain["sdk"]["path"]).is_dir())
            command = toolchain["invocation"]["command"]
            self.assertIn("-sdk", command)
            self.assertIn(toolchain["sdk"]["path"], command)
            self.assertNotIn(str(focus_clone.resolve()), "\n".join(command))
            for record in audit["shipping_source_inputs"]["files"]:
                self.assertIn(str(output.resolve() / record["input_path"]), command)
            self.assertFalse(toolchain["invocation"]["link_step"])
            self.assertGreater((output / "modules" / "Widget.swiftmodule").stat().st_size, 0)
            self.assertTrue((output / "widget-audit.json").is_file())


if __name__ == "__main__":
    unittest.main()
