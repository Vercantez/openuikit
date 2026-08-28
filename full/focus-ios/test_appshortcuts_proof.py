#!/usr/bin/env python3
"""Positive and adversarial tests for the pinned AppShortcuts module proof."""

from __future__ import annotations

import copy
import os
from pathlib import Path
import shutil
import subprocess
import sys
import tempfile
import unittest
from unittest.mock import patch

import appshortcuts_proof as subject


HERE = Path(__file__).resolve().parent
SWIFT_MACHO_LINUX = HERE.parent.parent
FOCUS_SOURCE = SWIFT_MACHO_LINUX / "scratch" / "ladder-corpus" / "focus-ios"
OPENUIKIT_SOURCE = SWIFT_MACHO_LINUX.parent / "uikit"
POLICY_PATH = HERE / "appshortcuts-proof.json"
RESOURCE_POLICY_PATH = HERE / "package-resources.json"


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
    run(["git", "-c", "core.fsmonitor=false", "-c", f"core.hooksPath={os.devnull}", "-C", str(destination), "checkout", "--quiet", "--detach", commit])


class PolicyAndPrimitiveTests(unittest.TestCase):
    def setUp(self) -> None:
        self.raw, self.policy = subject.load_policy(POLICY_PATH)

    def test_reviewed_policy_has_no_source_adaptation(self) -> None:
        self.assertEqual(self.policy, subject.expected_policy())
        self.assertNotIn("adaptation", self.policy)
        self.assertEqual([len(target["sources"]) for target in self.policy["targets"]], [11, 1, 4, 5])
        exclusions = self.policy["targets"][2]["production_exclusions"]
        self.assertEqual(len(exclusions["sources"]), 3)
        self.assertEqual(
            subject.records_digest(
                (item["path"], (FOCUS_SOURCE / "focus-ios" / item["path"]).read_bytes())
                for item in exclusions["sources"]
            ),
            exclusions["source_digest"],
        )

    def test_nested_malformed_policy_refuses_without_python_shape_errors(self) -> None:
        mutations = [
            ("resource_integration", None),
            ("build", "not-a-mapping"),
            ("focus", {"commit": subject.FOCUS_COMMIT}),
        ]
        for key, value in mutations:
            changed = copy.deepcopy(self.policy)
            changed[key] = value
            with self.subTest(key=key), self.assertRaises(subject.ProofError):
                subject._validate_policy_shape(changed)

    def test_malformed_production_exclusion_refuses(self) -> None:
        changed = copy.deepcopy(self.policy)
        changed["targets"][2]["production_exclusions"] = {"sources": []}
        with self.assertRaisesRegex(subject.ProofError, "production_exclusions"):
            subject._validate_policy_shape(changed)

    def test_semantically_valid_policy_drift_refuses(self) -> None:
        changed = copy.deepcopy(self.policy)
        changed["targets"][0]["source_digest"] = "0" * 64
        with tempfile.TemporaryDirectory(prefix="focus-appshortcuts-policy.") as temporary:
            path = Path(temporary) / "changed.json"
            path.write_bytes(subject.canonical_json(changed))
            with self.assertRaisesRegex(subject.ProofError, "reviewed Focus AppShortcuts"):
                subject.load_policy(path)

    def test_resource_accessor_path_escape_refuses_before_use(self) -> None:
        changed = copy.deepcopy(self.policy)
        changed["resource_integration"]["accessor_path"] = "accessors/../../escape.swift"
        with self.assertRaisesRegex(subject.ProofError, "normalized relative"):
            subject._validate_policy_shape(changed)

    def test_source_adaptation_config_is_rejected(self) -> None:
        changed = copy.deepcopy(self.policy)
        changed["adaptation"] = {"path": "generated/overlay.swift"}
        with self.assertRaisesRegex(subject.ProofError, "top-level keys"):
            subject._validate_policy_shape(changed)

    def test_ambient_git_redirects_are_removed(self) -> None:
        with patch.dict(
            os.environ,
            {
                "GIT_DIR": "/tmp/untrusted-git-dir",
                "GIT_WORK_TREE": "/tmp/untrusted-work-tree",
                "GIT_CONFIG_GLOBAL": "/tmp/untrusted-config",
                "GIT_NO_REPLACE_OBJECTS": "0",
            },
            clear=False,
        ):
            environment = subject.controlled_environment()
        self.assertNotIn("GIT_DIR", environment)
        self.assertNotIn("GIT_WORK_TREE", environment)
        self.assertEqual(environment["GIT_CONFIG_GLOBAL"], os.devnull)
        self.assertEqual(environment["GIT_CONFIG_NOSYSTEM"], "1")
        self.assertEqual(environment["GIT_NO_REPLACE_OBJECTS"], "1")

    def test_source_adaptation_output_must_not_exist(self) -> None:
        with tempfile.TemporaryDirectory(prefix="focus-appshortcuts-no-adaptation.") as temporary:
            output = Path(temporary)
            subject.verify_no_source_adaptations(output)
            generated = output / "generated"
            generated.mkdir()
            (generated / "overlay.swift").write_bytes(b"not allowed")
            with self.assertRaisesRegex(subject.ProofError, "adaptation output exists"):
                subject.verify_no_source_adaptations(output)

    def test_stale_output_refuses_without_touching_it(self) -> None:
        with tempfile.TemporaryDirectory(prefix="focus-appshortcuts-output.") as temporary:
            root = Path(temporary)
            focus = root / "focus"
            uikit = root / "uikit"
            output = root / "proof"
            focus.mkdir()
            uikit.mkdir()
            output.mkdir()
            sentinel = output / "keep"
            sentinel.write_bytes(b"user data")
            with self.assertRaisesRegex(subject.ProofError, "stale proof output"):
                subject._resolve_new_output(str(output), focus, uikit)
            self.assertEqual(sentinel.read_bytes(), b"user data")

    def test_resource_policy_and_tool_are_bracketable(self) -> None:
        with tempfile.TemporaryDirectory(prefix="focus-appshortcuts-local-deps.") as temporary:
            root = Path(temporary)
            shutil.copy2(HERE / "package-resources.json", root / "package-resources.json")
            shutil.copy2(HERE / "package_resources.py", root / "package_resources.py")
            with patch.object(subject, "HERE", root):
                subject._attest_local_dependency(self.policy)
                tool = root / "package_resources.py"
                data = bytearray(tool.read_bytes())
                data[0] ^= 1
                tool.write_bytes(data)
                with self.assertRaisesRegex(subject.ProofError, "resource tool changed"):
                    subject._attest_local_dependency(self.policy)


@unittest.skipUnless(FOCUS_SOURCE.is_dir(), "pinned Focus repository is unavailable")
class FocusRepositoryAttestationTests(unittest.TestCase):
    def setUp(self) -> None:
        self.temporary = tempfile.TemporaryDirectory(prefix="focus-appshortcuts-source.")
        self.root = Path(self.temporary.name)
        self.clone = self.root / "focus"
        clone_at(FOCUS_SOURCE, self.clone, subject.FOCUS_COMMIT)
        self.repo = self.clone / "focus-ios"
        _, self.policy = subject.load_policy(POLICY_PATH)

    def tearDown(self) -> None:
        self.temporary.cleanup()

    def test_positive_exact_focus_capture(self) -> None:
        capture = subject.capture_focus(self.repo, self.policy)
        self.assertEqual(capture.commit, subject.FOCUS_COMMIT)
        self.assertEqual(sum(len(sources) for _, sources in capture.targets), 21)
        self.assertEqual(len(capture.exclusions), 3)

    def test_dirty_and_untracked_worktrees_refuse(self) -> None:
        source = self.repo / self.policy["targets"][0]["sources"][0]["path"]
        source.write_bytes(source.read_bytes() + b"\n")
        with self.assertRaisesRegex(subject.ProofError, "dirty or contains untracked"):
            subject.capture_focus(self.repo, self.policy)

        run(["git", "-C", str(self.clone), "checkout", "--quiet", "--", "."])
        unexpected = self.repo / "untracked-proof-input"
        unexpected.write_bytes(b"not reviewed")
        with self.assertRaisesRegex(subject.ProofError, "dirty or contains untracked"):
            subject.capture_focus(self.repo, self.policy)

    def test_assume_unchanged_source_drift_still_refuses(self) -> None:
        expected = self.policy["targets"][0]["sources"][0]
        git_path = f"focus-ios/{expected['path']}"
        run(["git", "-C", str(self.clone), "update-index", "--assume-unchanged", "--", git_path])
        source = self.repo / expected["path"]
        changed = bytearray(source.read_bytes())
        changed[0] ^= 1
        source.write_bytes(changed)
        with self.assertRaisesRegex(subject.ProofError, "worktree bytes differ|bytes changed"):
            subject.capture_focus(self.repo, self.policy)

    def test_source_symlink_refuses(self) -> None:
        expected = self.policy["targets"][0]["sources"][0]
        source = self.repo / expected["path"]
        other = self.repo / self.policy["targets"][0]["sources"][1]["path"]
        source.unlink()
        source.symlink_to(other.name)
        root, prefix = subject._repository_root_and_prefix(self.repo, "focus-ios", "Focus")
        with self.assertRaisesRegex(subject.ProofError, "must not contain symlinks"):
            subject._attest_committed_file(root, self.repo, prefix, expected, "fixture source")

    def test_capture_ignores_ambient_git_redirection(self) -> None:
        with patch.dict(
            os.environ,
            {"GIT_DIR": "/tmp/decoy", "GIT_WORK_TREE": "/tmp/decoy-tree"},
            clear=False,
        ):
            capture = subject.capture_focus(self.repo, self.policy)
        self.assertEqual(capture.commit, subject.FOCUS_COMMIT)

    def test_exact_resource_stage_drift_refuses(self) -> None:
        stage = self.root / "stage"
        audit = self.root / "resource-audit.json"
        subject.resource_tool.stage(str(self.repo), str(RESOURCE_POLICY_PATH), str(stage), str(audit))
        staged = next(path for path in stage.rglob("*") if path.is_file() and path.suffix != ".swift")
        staged.write_bytes(staged.read_bytes() + b"drift")
        with self.assertRaises(subject.resource_tool.PolicyError):
            subject.resource_tool.verify(str(self.repo), str(RESOURCE_POLICY_PATH), str(stage), str(audit))


@unittest.skipUnless(
    sys.platform == "darwin" and FOCUS_SOURCE.is_dir() and OPENUIKIT_SOURCE.is_dir(),
    "exact proof requires local pinned repositories and the Apple Swift toolchain",
)
class ExactAppShortcutsIntegrationTest(unittest.TestCase):
    def test_exact_four_module_proof_and_closing_adversarial_checks(self) -> None:
        with tempfile.TemporaryDirectory(prefix="focus-appshortcuts-integration.") as temporary:
            root = Path(temporary)
            focus_clone = root / "focus"
            uikit_clone = root / "uikit"
            clone_at(FOCUS_SOURCE, focus_clone, subject.FOCUS_COMMIT)
            clone_at(OPENUIKIT_SOURCE, uikit_clone, subject.OPENUIKIT_COMMIT)
            focus = focus_clone / "focus-ios"
            output = root / "proof"
            audit = subject.prove(str(focus), str(uikit_clone), str(POLICY_PATH), str(output))
            self.assertEqual([item["name"] for item in audit["targets"]], list(subject.MODULE_NAMES))
            self.assertEqual(len(audit["module_outputs"]), 16)
            self.assertTrue(all(item["size"] == 0 for item in audit["diagnostics"]))
            self.assertEqual(audit["source_adaptations"], [])
            self.assertEqual(len(audit["generated_swift_inputs"]), 1)
            self.assertEqual(audit["generated_swift_inputs"][0]["target"], "DesignSystem")
            self.assertEqual(
                audit["generated_swift_inputs"][0]["path"],
                "package-resources/accessors/DesignSystem/Bundle+Module.swift",
            )
            self.assertNotIn("adaptation", subject.expected_policy())
            self.assertFalse((output / "generated").exists())
            for name in subject.MODULE_NAMES:
                self.assertGreater((output / "modules" / f"{name}.swiftmodule").stat().st_size, 0)

            resource = next(path for path in (output / "package-resources").rglob("*") if path.is_file() and path.suffix != ".swift")
            resource.write_bytes(resource.read_bytes() + b"drift")
            with self.assertRaises(subject.resource_tool.PolicyError):
                subject.resource_tool.verify(
                    str(focus), str(RESOURCE_POLICY_PATH),
                    str(output / "package-resources"),
                    str(output / "package-resources-audit.json"),
                )


if __name__ == "__main__":
    unittest.main()
