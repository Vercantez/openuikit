#!/usr/bin/env python3
"""Negative controls for the focus-ios SnapKit vendoring rule."""

from __future__ import annotations

import hashlib
import json
import os
from pathlib import Path
import subprocess
import tempfile
import unittest
from unittest.mock import patch

from snapkit_sources import PolicyError, digest_sources, prepare


class SnapKitSourcesTests(unittest.TestCase):
    def setUp(self) -> None:
        self.temp = tempfile.TemporaryDirectory(prefix="snapkit-policy-test.")
        self.root = Path(self.temp.name)
        self.repo = self.root / "SnapKit"
        self.focus_repo = self.root / "focus-ios"
        (self.repo / "Sources").mkdir(parents=True)
        (self.repo / "Sources" / "Core.swift").write_text("public struct Core {}\n")
        (self.repo / "Sources" / "Debugging.swift").write_text(
            "// diagnostic-only fixture\n"
        )
        commit = self.initialize_repository(self.repo, "Sources")

        self.lock_path = (
            self.focus_repo
            / "Blockzilla.xcodeproj/project.xcworkspace/xcshareddata/swiftpm/Package.resolved"
        )
        self.lock_path.parent.mkdir(parents=True)
        self.lock = {
            "object": {
                "pins": [
                    {
                        "package": "SnapKit",
                        "repositoryURL": "https://github.com/SnapKit/SnapKit",
                        "state": {
                            "branch": None,
                            "revision": commit,
                            "version": "5.7.0",
                        },
                    }
                ]
            },
            "version": 1,
        }
        self.write_lock()
        focus_commit = self.initialize_repository(
            self.focus_repo,
            "Blockzilla.xcodeproj/project.xcworkspace/xcshareddata/swiftpm/Package.resolved",
        )
        debugging = (self.repo / "Sources" / "Debugging.swift").read_bytes()
        self.policy = {
            "schema": 2,
            "repository_commit": commit,
            "source_root": "Sources",
            "all_source_digest": digest_sources(
                self.repo,
                ["Sources/Core.swift", "Sources/Debugging.swift"],
            ),
            "included_source_digest": digest_sources(
                self.repo, ["Sources/Core.swift"]
            ),
            "workspace_lock": {
                "focus_repository_commit": focus_commit,
                "path": (
                    "Blockzilla.xcodeproj/project.xcworkspace/xcshareddata/"
                    "swiftpm/Package.resolved"
                ),
                "sha256": hashlib.sha256(self.lock_path.read_bytes()).hexdigest(),
                "package": "SnapKit",
                "repository_url": "https://github.com/SnapKit/SnapKit",
                "revision": commit,
                "version": "5.7.0",
            },
            "exclusions": [{
                "path": "Sources/Debugging.swift",
                "sha256": hashlib.sha256(debugging).hexdigest(),
                "reason": "diagnostic-only test fixture",
            }],
        }
        self.policy_path = self.root / "policy.json"
        self.list_path = self.root / "sources.txt"
        self.audit_path = self.root / "audit.json"
        self.write_policy()

    @staticmethod
    def initialize_repository(path: Path, tracked: str) -> str:
        subprocess.run(["git", "init", "-q", str(path)], check=True)
        subprocess.run(["git", "-C", str(path), "add", tracked], check=True)
        subprocess.run(
            [
                "git", "-C", str(path), "-c", "user.name=Policy Test",
                "-c", "user.email=policy@example.invalid", "commit", "-qm", "fixture",
            ],
            check=True,
        )
        return subprocess.check_output(
            ["git", "-C", str(path), "rev-parse", "HEAD"], text=True
        ).strip()

    @staticmethod
    def commit_all(repo: Path, message: str) -> str:
        subprocess.run(["git", "-C", str(repo), "add", "-A"], check=True)
        subprocess.run(
            [
                "git", "-C", str(repo), "-c", "user.name=Policy Test",
                "-c", "user.email=policy@example.invalid", "commit", "-qm", message,
            ],
            check=True,
        )
        return subprocess.check_output(
            ["git", "-C", str(repo), "rev-parse", "HEAD"], text=True
        ).strip()

    def tearDown(self) -> None:
        self.temp.cleanup()

    def write_policy(self) -> None:
        self.policy_path.write_text(json.dumps(self.policy))

    def write_lock(self) -> None:
        self.lock_path.write_text(json.dumps(self.lock, sort_keys=True) + "\n")

    def run_prepare(self):
        return prepare(
            str(self.repo), str(self.focus_repo), str(self.policy_path),
            str(self.list_path), str(self.audit_path),
        )

    def test_valid_rule_records_exact_denominator_and_subject(self) -> None:
        audit = self.run_prepare()
        self.assertEqual(audit["discovered_source_count"], 2)
        self.assertEqual(audit["included_source_count"], 1)
        self.assertEqual(audit["excluded_source_count"], 1)
        self.assertEqual(audit["workspace_lock"]["version"], "5.7.0")
        self.assertEqual(
            audit["workspace_lock"]["revision"], self.policy["repository_commit"]
        )
        self.assertEqual(
            self.list_path.read_text().splitlines(),
            [str((self.repo / "Sources" / "Core.swift").resolve())],
        )

    def test_git_checks_ignore_ambient_repository_redirection(self) -> None:
        redirected = self.root / "redirected"
        redirected.mkdir()
        (redirected / "unrelated.txt").write_text("unrelated\n")
        self.initialize_repository(redirected, "unrelated.txt")
        hostile = {
            "GIT_DIR": str(redirected / ".git"),
            "GIT_WORK_TREE": str(redirected),
            "GIT_INDEX_FILE": str(redirected / ".git/index"),
            "GIT_CONFIG_COUNT": "1",
            "GIT_CONFIG_KEY_0": "core.fsmonitor",
            "GIT_CONFIG_VALUE_0": "true",
        }
        with patch.dict(os.environ, hostile):
            audit = self.run_prepare()
        self.assertEqual(
            audit["repository_commit"], self.policy["repository_commit"]
        )

    def test_refuses_changed_excluded_bytes(self) -> None:
        self.policy["exclusions"][0]["sha256"] = "0" * 64
        self.write_policy()
        with self.assertRaisesRegex(PolicyError, "excluded source hash changed"):
            self.run_prepare()

    def test_refuses_repository_pin_drift(self) -> None:
        (self.repo / "README.md").write_text("new commit\n")
        self.commit_all(self.repo, "move SnapKit HEAD")
        with self.assertRaisesRegex(PolicyError, "SnapKit pin changed"):
            self.run_prepare()

    def test_refuses_focus_repository_pin_drift(self) -> None:
        (self.focus_repo / "README.md").write_text("new commit\n")
        self.commit_all(self.focus_repo, "move Focus HEAD")
        with self.assertRaisesRegex(PolicyError, "Focus pin changed"):
            self.run_prepare()

    def test_refuses_workspace_lock_byte_drift(self) -> None:
        self.lock["object"]["pins"][0]["state"]["version"] = "5.7.1"
        self.write_lock()
        with self.assertRaisesRegex(PolicyError, "workspace lock hash changed"):
            self.run_prepare()

    def test_refuses_workspace_lock_not_matching_pinned_head(self) -> None:
        self.lock["object"]["pins"][0]["state"]["version"] = "5.7.1"
        self.write_lock()
        self.policy["workspace_lock"]["sha256"] = hashlib.sha256(
            self.lock_path.read_bytes()
        ).hexdigest()
        self.write_policy()
        with self.assertRaisesRegex(PolicyError, "worktree bytes differ from pinned HEAD"):
            self.run_prepare()

    def test_refuses_workspace_lock_index_drift_with_clean_worktree_bytes(self) -> None:
        original = self.lock_path.read_bytes()
        self.lock["object"]["pins"][0]["state"]["version"] = "5.7.1"
        self.write_lock()
        subprocess.run(
            ["git", "-C", str(self.focus_repo), "add", str(self.lock_path)],
            check=True,
        )
        self.lock_path.write_bytes(original)
        with self.assertRaisesRegex(PolicyError, "index/worktree is not clean"):
            self.run_prepare()

    def test_refuses_workspace_snapkit_pin_drift_even_when_rehashed(self) -> None:
        self.lock["object"]["pins"][0]["state"]["revision"] = "0" * 40
        self.write_lock()
        self.policy["workspace_lock"]["sha256"] = hashlib.sha256(
            self.lock_path.read_bytes()
        ).hexdigest()
        self.policy["workspace_lock"]["focus_repository_commit"] = self.commit_all(
            self.focus_repo, "change resolved SnapKit pin"
        )
        self.write_policy()
        with self.assertRaisesRegex(PolicyError, "workspace lock SnapKit pin changed"):
            self.run_prepare()

    def test_refuses_included_source_digest_drift(self) -> None:
        self.policy["included_source_digest"] = "0" * 64
        self.write_policy()
        with self.assertRaisesRegex(PolicyError, "included-source digest changed"):
            self.run_prepare()

    def test_refuses_all_source_digest_drift(self) -> None:
        self.policy["all_source_digest"] = "0" * 64
        self.write_policy()
        with self.assertRaisesRegex(PolicyError, "all-source digest changed"):
            self.run_prepare()

    def test_refuses_expanded_exclusion_scope(self) -> None:
        self.policy["exclusions"].append({
            "path": "Sources/Core.swift",
            "sha256": hashlib.sha256(
                (self.repo / "Sources" / "Core.swift").read_bytes()
            ).hexdigest(),
            "reason": "must not be silently accepted",
        })
        self.write_policy()
        with self.assertRaisesRegex(PolicyError, "exclusion scope changed"):
            self.run_prepare()

    def test_refuses_dirty_tracked_source(self) -> None:
        (self.repo / "Sources" / "Core.swift").write_text("public struct Changed {}\n")
        with self.assertRaisesRegex(PolicyError, "Sources is not clean"):
            self.run_prepare()

    def test_refuses_untracked_source(self) -> None:
        (self.repo / "Sources" / "Unexpected.swift").write_text("// unexpected\n")
        with self.assertRaisesRegex(PolicyError, "Sources is not clean"):
            self.run_prepare()

    def test_refuses_ignored_untracked_source(self) -> None:
        (self.repo / ".git" / "info" / "exclude").write_text(
            "Sources/Unexpected.swift\n"
        )
        (self.repo / "Sources" / "Unexpected.swift").write_text("// unexpected\n")
        with self.assertRaisesRegex(PolicyError, "inventories differ"):
            self.run_prepare()


if __name__ == "__main__":
    unittest.main()
