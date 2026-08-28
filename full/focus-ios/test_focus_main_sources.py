#!/usr/bin/env python3
"""Positive and adversarial controls for the Blockzilla source attestation."""

from __future__ import annotations

from contextlib import redirect_stdout
import io
import json
from pathlib import Path
import shutil
import tempfile
import unittest
from unittest.mock import patch

import focus_main_sources as subject


HERE = Path(__file__).resolve().parent
SWIFT_MACHO_LINUX = HERE.parent.parent
FOCUS_REPOSITORY = (
    SWIFT_MACHO_LINUX / "scratch" / "ladder-corpus" / "focus-ios" / "focus-ios"
)
POLICY_PATH = HERE / "focus-main-sources.json"


class FocusMainSourcesIntegrationTests(unittest.TestCase):
    def test_exact_checked_subject_emits_nul_manifest_and_full_audit(self) -> None:
        self.assertTrue(FOCUS_REPOSITORY.is_dir(), FOCUS_REPOSITORY)
        with tempfile.TemporaryDirectory(prefix="focus-main-positive.") as temp:
            manifest = Path(temp) / "sources.nul"
            audit_path = Path(temp) / "audit.json"
            with redirect_stdout(io.StringIO()):
                audit = subject.prepare(
                    str(FOCUS_REPOSITORY), str(POLICY_PATH),
                    str(manifest), str(audit_path),
                )

            raw_manifest = manifest.read_bytes()
            self.assertTrue(raw_manifest.endswith(b"\0"))
            entries = raw_manifest[:-1].split(b"\0")
            self.assertEqual(len(entries), 129)
            self.assertEqual(raw_manifest.count(b"\0"), 129)
            self.assertIn(
                str(
                    FOCUS_REPOSITORY
                    / "Blockzilla/Tracking Protection/TrackingProtectionViewController.swift"
                ).encode(),
                entries,
            )

            self.assertEqual(audit["target_swift_reference_count"], 131)
            self.assertEqual(audit["present_source_count"], 129)
            self.assertEqual(audit["generated_missing_source_count"], 2)
            self.assertEqual(
                audit["expected_generated_missing"],
                list(subject.APPROVED_GENERATED_MISSING),
            )
            self.assertEqual(len(audit["present_sources"]), 129)
            self.assertEqual(
                json.loads(audit_path.read_text(encoding="utf-8")), audit
            )


class FocusMainSourcesAdversarialTests(unittest.TestCase):
    def setUp(self) -> None:
        if not FOCUS_REPOSITORY.is_dir():
            self.fail(f"missing pinned Focus fixture: {FOCUS_REPOSITORY}")
        self.temp = tempfile.TemporaryDirectory(prefix="focus-main-policy-test.")
        self.root = Path(self.temp.name)
        self.repo = self.root / "focus-ios"
        self.repo.mkdir()

        self.policy = json.loads(POLICY_PATH.read_text(encoding="utf-8"))
        for relative in self.policy["present_sources"]:
            destination = self.repo / relative
            destination.parent.mkdir(parents=True, exist_ok=True)
            shutil.copy2(FOCUS_REPOSITORY / relative, destination)
        project_relative = self.policy["project"]["path"]
        project_destination = self.repo / project_relative
        project_destination.parent.mkdir(parents=True, exist_ok=True)
        shutil.copy2(FOCUS_REPOSITORY / project_relative, project_destination)

        self.policy_path = POLICY_PATH
        self.manifest_path = self.root / "sources.nul"
        self.audit_path = self.root / "audit.json"
        self.fake_commit = subject.APPROVED_COMMIT
        self.fake_tracked_sources = list(self.policy["present_sources"])

    def tearDown(self) -> None:
        self.temp.cleanup()

    def fake_git(self, repo: Path, *args: str) -> bytes:
        self.assertEqual(repo, self.repo.resolve())
        if args == ("rev-parse", "--verify", "HEAD^{commit}"):
            return (self.fake_commit + "\n").encode("ascii")
        if args == (
            "ls-files", "-z", "--", *subject.APPROVED_SOURCE_ROOTS
        ):
            return b"".join(
                relative.encode("utf-8") + b"\0"
                for relative in self.fake_tracked_sources
            )
        self.fail(f"unexpected git invocation: {args}")

    def run_prepare(self):
        with patch.object(subject, "git", side_effect=self.fake_git):
            with redirect_stdout(io.StringIO()):
                return subject.prepare(
                    str(self.repo), str(self.policy_path),
                    str(self.manifest_path), str(self.audit_path),
                )

    def write_modified_policy(self, policy: dict) -> None:
        self.policy_path = self.root / "modified-policy.json"
        self.policy_path.write_text(
            json.dumps(policy, indent=2) + "\n", encoding="utf-8"
        )

    def assert_no_outputs(self) -> None:
        self.assertFalse(self.manifest_path.exists())
        self.assertFalse(self.audit_path.exists())

    def test_fixture_positive_control(self) -> None:
        audit = self.run_prepare()
        self.assertEqual(audit["present_source_count"], 129)
        self.assertEqual(self.manifest_path.read_bytes().count(b"\0"), 129)

    def test_refuses_commit_drift(self) -> None:
        self.fake_commit = "0" * 40
        with self.assertRaisesRegex(subject.PolicyError, "Focus pin changed"):
            self.run_prepare()
        self.assert_no_outputs()

    def test_refuses_project_bytes_drift_even_at_the_same_size(self) -> None:
        project = self.repo / self.policy["project"]["path"]
        changed = bytearray(project.read_bytes())
        changed[0] ^= 1
        project.write_bytes(changed)
        with self.assertRaisesRegex(subject.PolicyError, "project hash changed"):
            self.run_prepare()
        self.assert_no_outputs()

    def test_refuses_source_set_deletion(self) -> None:
        (self.repo / self.policy["present_sources"][0]).unlink()
        with self.assertRaisesRegex(subject.PolicyError, "source inventory changed"):
            self.run_prepare()
        self.assert_no_outputs()

    def test_refuses_source_bytes_drift_even_at_the_same_size(self) -> None:
        source_path = self.repo / self.policy["present_sources"][0]
        changed = bytearray(source_path.read_bytes())
        changed[0] ^= 1
        source_path.write_bytes(changed)
        with self.assertRaisesRegex(subject.PolicyError, "source bytes changed"):
            self.run_prepare()
        self.assert_no_outputs()

    def test_refuses_source_symlink(self) -> None:
        link = self.repo / self.policy["present_sources"][0]
        target = self.repo / self.policy["present_sources"][1]
        link.unlink()
        link.symlink_to(target)
        with self.assertRaisesRegex(subject.PolicyError, "must not contain symlinks"):
            self.run_prepare()
        self.assert_no_outputs()

    def test_refuses_untracked_swift_source(self) -> None:
        unexpected = self.repo / "Blockzilla/Unexpected Source.swift"
        unexpected.write_text("// not in the target\n", encoding="utf-8")
        with self.assertRaisesRegex(subject.PolicyError, "source inventory changed"):
            self.run_prepare()
        self.assert_no_outputs()

    def test_refuses_policy_source_path_drift(self) -> None:
        changed_policy = json.loads(json.dumps(self.policy))
        changed_policy["present_sources"][0] = "Blockzilla/Unexpected.swift"
        changed_policy["present_sources"].sort()
        self.write_modified_policy(changed_policy)
        with self.assertRaisesRegex(subject.PolicyError, "source inventory changed"):
            self.run_prepare()
        self.assert_no_outputs()

    def test_refuses_policy_hash_drift(self) -> None:
        changed_policy = json.loads(json.dumps(self.policy))
        changed_policy["present_source_digest"] = "0" * 64
        self.write_modified_policy(changed_policy)
        with self.assertRaisesRegex(subject.PolicyError, "approved digest"):
            self.run_prepare()
        self.assert_no_outputs()


if __name__ == "__main__":
    unittest.main()
