#!/usr/bin/env python3
"""Positive and adversarial controls for the Onboarding UIKit proof."""

from __future__ import annotations

import copy
import os
from pathlib import Path
import subprocess
import sys
import tempfile
import unittest
from unittest.mock import patch

import onboarding_uikit_proof as subject


HERE = Path(__file__).resolve().parent
SWIFT_MACHO_LINUX = HERE.parent.parent
FOCUS_SOURCE = SWIFT_MACHO_LINUX / "scratch" / "ladder-corpus" / "focus-ios"
OPENUIKIT_SOURCE = SWIFT_MACHO_LINUX.parent / "uikit"
SNAPKIT_SOURCE = SWIFT_MACHO_LINUX / "scratch" / "xcodeplan-deps" / "SnapKit"
POLICY_PATH = HERE / "onboarding-uikit-proof.json"


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


def fake_toolchain() -> subject.AppleToolchain:
    return subject.AppleToolchain(
        xcrun_path="/usr/bin/xcrun",
        xcrun_size=1,
        xcrun_sha256="0" * 64,
        swift_launcher_path="/AppleToolchain/usr/bin/swift",
        swift_resolved_path="/AppleToolchain/usr/bin/swift-frontend",
        swift_size=1,
        swift_sha256="1" * 64,
        swiftc_launcher_path="/AppleToolchain/usr/bin/swiftc",
        swiftc_resolved_path="/AppleToolchain/usr/bin/swift-frontend",
        swiftc_size=1,
        swiftc_sha256="1" * 64,
        sdk_path="/AppleSDK/MacOSX.sdk",
        sdk_settings_size=1,
        sdk_settings_sha256="2" * 64,
        swift_version=b"Apple Swift fixture\n",
        swiftc_version=b"Apple Swift fixture\n",
    )


class PolicyTests(unittest.TestCase):
    def setUp(self) -> None:
        self.raw, self.policy = subject.load_policy(POLICY_PATH)

    def test_exact_policy_inventory_and_claim_boundary(self) -> None:
        self.assertEqual(self.policy, subject.expected_policy())
        self.assertEqual(self.raw, subject.canonical_json(self.policy))
        self.assertEqual(self.policy["focus"]["onboarding_uikit_core"]["source_count"], 10)
        self.assertEqual(self.policy["focus"]["onboarding_uikit_core"]["excluded_source_count"], 11)
        self.assertEqual(self.policy["focus"]["design_system"]["source_count"], 4)
        self.assertEqual(self.policy["focus"]["design_system"]["resource_count"], 117)
        self.assertEqual(self.policy["snapkit"]["included_source_count"], 36)
        self.assertEqual(self.policy["openuikit"]["inventory_file_count"], 299)
        self.assertEqual(len(self.policy["diagnostic_contract"]["onboarding_expected_warnings"]), 2)
        self.assertFalse(self.policy["claims"]["focus_package_or_xcode_build"])
        self.assertFalse(self.policy["claims"]["linux_guest_link_or_run"])

    def test_semantic_drift_and_source_adaptation_key_refuse(self) -> None:
        changed = copy.deepcopy(self.policy)
        changed["focus"]["onboarding_uikit_core"]["source_digest"] = "0" * 64
        with tempfile.TemporaryDirectory(prefix="onboarding-policy.") as temporary:
            path = Path(temporary) / "changed.json"
            path.write_bytes(subject.canonical_json(changed))
            with self.assertRaisesRegex(subject.ProofError, "reviewed Focus Onboarding UIKit"):
                subject.load_policy(path)
        changed = copy.deepcopy(self.policy)
        changed["adaptation"] = {"path": "generated/Onboarding/overlay.swift"}
        with self.assertRaisesRegex(subject.ProofError, "top-level keys"):
            subject._validate_policy_shape(changed)

    def test_path_escape_refuses(self) -> None:
        changed = copy.deepcopy(self.policy)
        changed["snapkit"]["input_stage_path"] = "inputs/../escape"
        with self.assertRaisesRegex(subject.ProofError, "normalized relative"):
            subject._validate_policy_shape(changed)

    def test_ambient_git_and_toolchain_redirects_are_removed(self) -> None:
        overrides = {
            "CCC_OVERRIDE_OPTIONS": "^--target=x86_64-unknown-linux-gnu",
            "C_INCLUDE_PATH": "/tmp/fake-c-headers",
            "DEVELOPER_DIR": "/tmp/fake-developer",
            "GIT_DIR": "/tmp/decoy",
            "GIT_WORK_TREE": "/tmp/decoy",
            "OBJCPLUS_INCLUDE_PATH": "/tmp/fake-objcxx-headers",
            "PATH": "/tmp/fake-bin",
            "SDKROOT": "/tmp/fake-sdk",
            "SWIFT_DRIVER_SWIFT_EXEC": "/tmp/fake-driver",
            "SWIFT_EXEC": "/tmp/fake-swiftc",
            "TOOLCHAINS": "fake-toolchain",
        }
        with patch.dict(os.environ, overrides, clear=False):
            environment = subject.controlled_environment()
        for name in (
            "CCC_OVERRIDE_OPTIONS", "C_INCLUDE_PATH", "DEVELOPER_DIR",
            "GIT_DIR", "GIT_WORK_TREE", "OBJCPLUS_INCLUDE_PATH", "SDKROOT",
            "SWIFT_DRIVER_SWIFT_EXEC", "SWIFT_EXEC", "TOOLCHAINS",
        ):
            self.assertNotIn(name, environment)
        self.assertEqual(set(environment), {
            "GIT_CONFIG_GLOBAL", "GIT_CONFIG_NOSYSTEM", "GIT_NO_REPLACE_OBJECTS",
            "GIT_OPTIONAL_LOCKS", "HOME", "LANG", "LC_ALL", "PATH", "TMPDIR",
        })
        self.assertEqual(environment["GIT_CONFIG_GLOBAL"], os.devnull)
        self.assertEqual(environment["GIT_NO_REPLACE_OBJECTS"], "1")
        self.assertEqual(environment["PATH"], subject.SAFE_PATH)

    def test_stale_output_refuses_without_touching_it(self) -> None:
        with tempfile.TemporaryDirectory(prefix="onboarding-output.") as temporary:
            root = Path(temporary)
            output = root / "proof"
            output.mkdir()
            sentinel = output / "keep"
            sentinel.write_bytes(b"user data")
            with self.assertRaisesRegex(subject.ProofError, "stale proof output"):
                subject._resolve_new_output(str(output), (root,))
            self.assertEqual(sentinel.read_bytes(), b"user data")

    @unittest.skipUnless(sys.platform == "darwin", "macOS ACL semantics")
    def test_unsafe_or_acl_bearing_output_parent_refuses(self) -> None:
        with tempfile.TemporaryDirectory(prefix="onboarding-parent.") as temporary:
            root = Path(temporary)
            unsafe = root / "unsafe"
            unsafe.mkdir(mode=0o700)
            unsafe.chmod(0o777)
            with self.assertRaisesRegex(subject.ProofError, "owned.*private mode 0700"):
                subject._resolve_new_output(str(unsafe / "proof"), ())

            acl_parent = root / "acl-parent"
            acl_parent.mkdir(mode=0o700)
            run(["/bin/chmod", "+a", "everyone allow read,write", str(acl_parent)])
            try:
                with self.assertRaisesRegex(subject.ProofError, "extended ACL"):
                    subject._resolve_new_output(str(acl_parent / "proof"), ())
            finally:
                run(["/bin/chmod", "-N", str(acl_parent)])

    @unittest.skipUnless(sys.platform == "darwin", "Apple toolchain discovery requires macOS")
    def test_toolchain_discovery_ignores_spoofing_and_hashes_sdk(self) -> None:
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
        self.assertTrue(Path(toolchain.swift_resolved_path).is_file())
        self.assertTrue(Path(toolchain.swiftc_resolved_path).is_file())
        self.assertTrue(Path(toolchain.sdk_path).is_dir())
        self.assertNotIn("/tmp/fake", toolchain.swift_launcher_path)
        self.assertNotIn("/tmp/fake", toolchain.sdk_path)
        self.assertRegex(toolchain.sdk_settings_sha256, r"^[0-9a-f]{64}$")


@unittest.skipUnless(
    FOCUS_SOURCE.is_dir() and OPENUIKIT_SOURCE.is_dir() and SNAPKIT_SOURCE.is_dir(),
    "pinned repositories are unavailable",
)
class CaptureAndStageTests(unittest.TestCase):
    def setUp(self) -> None:
        self.temporary = tempfile.TemporaryDirectory(prefix="onboarding-capture.")
        self.root = Path(self.temporary.name)
        self.focus_clone = self.root / "focus"
        self.ui_clone = self.root / "uikit"
        self.snapkit_clone = self.root / "snapkit"
        clone_at(FOCUS_SOURCE, self.focus_clone, subject.FOCUS_COMMIT)
        clone_at(OPENUIKIT_SOURCE, self.ui_clone, subject.OPENUIKIT_COMMIT)
        clone_at(SNAPKIT_SOURCE, self.snapkit_clone, subject.SNAPKIT_COMMIT)
        self.focus_repo = self.focus_clone / "focus-ios"
        _, self.policy = subject.load_policy(POLICY_PATH)

    def tearDown(self) -> None:
        self.temporary.cleanup()

    def test_exact_capture_and_deterministic_proof_local_stage(self) -> None:
        focus = subject.capture_focus(self.focus_repo, self.policy)
        ui = subject.capture_openuikit(self.ui_clone, self.policy)
        snapkit = subject.capture_snapkit(self.snapkit_clone, self.policy)
        self.assertEqual((len(focus.onboarding_sources), len(focus.onboarding_exclusions)), (10, 11))
        self.assertEqual((len(focus.design_sources), len(focus.design_resources)), (4, 117))
        self.assertEqual((len(ui.files), len(snapkit.files), len(snapkit.exclusions)), (299, 36, 1))
        first = self.root / "first"
        second = self.root / "second"
        first.mkdir()
        second.mkdir()
        first_records = subject.stage_files(first, snapkit.files, self.policy["snapkit"]["input_stage_path"])
        second_records = subject.stage_files(second, snapkit.files, self.policy["snapkit"]["input_stage_path"])
        self.assertEqual(first_records, second_records)
        for record in first_records:
            relative = Path(record["input_path"])
            self.assertEqual((first / relative).read_bytes(), (second / relative).read_bytes())

    def test_hidden_worktree_drift_refuses(self) -> None:
        relative = subject.ONBOARDING_SOURCES[0]
        git_path = f"focus-ios/{relative}"
        run(["git", "-C", str(self.focus_clone), "update-index", "--assume-unchanged", "--", git_path])
        path = self.focus_repo / relative
        original = path.read_bytes()
        path.write_bytes(original + b"drift")
        with self.assertRaisesRegex(subject.ProofError, "worktree bytes differ"):
            subject.capture_focus(self.focus_repo, self.policy)
        path.write_bytes(original)
        run(["git", "-C", str(self.focus_clone), "update-index", "--no-assume-unchanged", "--", git_path])

    def test_dirty_or_untracked_worktree_refuses(self) -> None:
        untracked = self.snapkit_clone / "untracked.proof-test"
        untracked.write_bytes(b"not part of the pinned subject")
        with self.assertRaisesRegex(subject.ProofError, "worktree is not clean"):
            subject.capture_snapkit(self.snapkit_clone, self.policy)

    def test_staged_tamper_and_generated_adaptation_refuse(self) -> None:
        snapkit = subject.capture_snapkit(self.snapkit_clone, self.policy)
        output = self.root / "tamper"
        output.mkdir()
        records = subject.stage_files(output, snapkit.files, self.policy["snapkit"]["input_stage_path"])
        staged = output / records[0]["input_path"]
        staged.write_bytes(staged.read_bytes() + b"drift")
        with self.assertRaisesRegex(subject.ProofError, "staged shipping-input bytes changed"):
            subject.verify_staged_files(output, snapkit.files, self.policy["snapkit"]["input_stage_path"])

        generated_output = self.root / "generated"
        generated_output.mkdir()
        subject.write_generated_source(generated_output, self.policy)
        extra = generated_output / "generated" / "DesignSystem" / "overlay.swift"
        extra.write_bytes(b"source adaptation")
        with self.assertRaisesRegex(subject.ProofError, "adaptation or unexpected input"):
            subject.verify_generated_source(generated_output, self.policy)

    def test_compiler_inputs_are_private_and_write_protected(self) -> None:
        output = self.root / "sealed"
        output.mkdir(mode=0o700)
        for relative in (
            "generated/DesignSystem/Bundle+Module.swift",
            "inputs/focus/Action.swift",
            "resources/DesignSystem/Contents.json",
        ):
            subject._write_exclusive(output / relative, b"reviewed input\n", "test input")
        subject.seal_compiler_inputs(output)
        subject.verify_compiler_inputs_sealed(output)
        self.assertEqual(output.stat().st_mode & 0o777, 0o700)
        candidate = output / "inputs/focus/Action.swift"
        self.assertEqual(candidate.stat().st_mode & 0o777, 0o444)
        with self.assertRaises(PermissionError):
            candidate.write_bytes(b"transient compiler-time mutation\n")

    @unittest.skipUnless(sys.platform == "darwin", "macOS ACL semantics")
    def test_inherited_compiler_input_acl_refuses(self) -> None:
        output = self.root / "acl-sealed"
        output.mkdir(mode=0o700)
        inputs = output / "inputs"
        inputs.mkdir()
        run([
            "/bin/chmod", "+a", "everyone allow read,write,file_inherit,directory_inherit",
            str(inputs),
        ])
        try:
            for relative in (
                "generated/DesignSystem/Bundle+Module.swift",
                "inputs/focus/Action.swift",
                "resources/DesignSystem/Contents.json",
            ):
                subject._write_exclusive(output / relative, b"reviewed input\n", "test input")
            with self.assertRaisesRegex(subject.ProofError, "extended ACL"):
                subject.seal_compiler_inputs(output)
        finally:
            run(["/bin/chmod", "-RN", str(output)])

    def test_commands_reference_only_proof_local_package_and_sources(self) -> None:
        toolchain = fake_toolchain()
        output = self.root / "command-proof"
        output.mkdir()
        ui_command = subject._openuikit_command(toolchain, output, self.policy)
        self.assertIn(str(output / self.policy["openuikit"]["input_stage_path"]), ui_command)
        self.assertNotIn(str(self.ui_clone.resolve()), "\n".join(ui_command))
        staged_sources = [
            output / self.policy["snapkit"]["input_stage_path"] / path
            for path in subject.SNAPKIT_SOURCES
        ]
        direct = subject._direct_command(
            toolchain, output, self.policy, "SnapKit", staged_sources,
        )
        for path in staged_sources:
            self.assertIn(str(path), direct)
        self.assertNotIn(str(self.snapkit_clone.resolve()), "\n".join(direct))
        swift_inputs = [argument for argument in direct if argument.endswith(".swift")]
        self.assertTrue(all(Path(argument).is_relative_to(output) for argument in swift_inputs))


@unittest.skipUnless(
    sys.platform == "darwin"
    and FOCUS_SOURCE.is_dir()
    and OPENUIKIT_SOURCE.is_dir()
    and SNAPKIT_SOURCE.is_dir(),
    "exact proof requires pinned repositories and the Apple Swift toolchain",
)
class ExactIntegrationTest(unittest.TestCase):
    def test_exact_module_emission_warning_contract_and_narrow_claims(self) -> None:
        with tempfile.TemporaryDirectory(prefix="onboarding-integration.") as temporary:
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
            inputs = audit["shipping_source_inputs"]
            self.assertEqual(len(inputs["onboarding_uikit_core"]), 10)
            self.assertEqual(len(inputs["design_system"]), 4)
            self.assertEqual(len(inputs["snapkit"]), 36)
            self.assertEqual(len(inputs["openuikit_package"]), 299)
            self.assertEqual(audit["shipping_source_edits"], [])
            self.assertEqual(len(audit["generated_build_inputs"]), 1)
            self.assertEqual(audit["raw_resource_stage"]["file_count"], 117)
            self.assertEqual(audit["raw_resource_stage"]["byte_count"], 169439)
            self.assertEqual(len(audit["module_outputs"]), 24)
            self.assertEqual(len(audit["diagnostics"]), 4)
            by_module = {item["module"]: item for item in audit["diagnostics"]}
            self.assertEqual(by_module["SnapKit"]["size"], 0)
            self.assertEqual(by_module["DesignSystem"]["size"], 0)
            self.assertEqual(by_module["OnboardingUIKitCore"]["warning_count"], 2)
            self.assertEqual(
                audit["diagnostic_contract"]["reviewed_onboarding_warnings"],
                audit["diagnostic_contract"]["onboarding_expected_warnings"],
            )
            self.assertFalse(audit["claims"]["focus_package_or_xcode_build"])
            self.assertFalse(audit["claims"]["linux_guest_link_or_run"])
            self.assertFalse(audit["claims"]["resource_catalog_compilation_or_decode"])
            toolchain = audit["toolchain"]
            self.assertEqual(toolchain["discovery"]["path"], "/usr/bin/xcrun")
            self.assertRegex(toolchain["swiftc"]["sha256"], r"^[0-9a-f]{64}$")
            self.assertRegex(toolchain["sdk"]["settings_sha256"], r"^[0-9a-f]{64}$")
            self.assertEqual(len(toolchain["invocations"]), 4)
            commands = "\n".join(
                argument
                for invocation in toolchain["invocations"]
                for argument in invocation["command"]
            )
            for clone in (focus_clone, ui_clone, snapkit_clone):
                self.assertNotIn(str(clone.resolve()), commands)
            self.assertTrue(all(not item["link_step"] for item in toolchain["invocations"]))
            self.assertGreater((output / "modules" / "OnboardingUIKitCore.swiftmodule").stat().st_size, 0)
            self.assertTrue((output / "onboarding-uikit-audit.json").is_file())


if __name__ == "__main__":
    unittest.main()
