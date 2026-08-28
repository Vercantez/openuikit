#!/usr/bin/env python3
"""Negative controls for the focus-ios SnapKit vendoring rule."""

from __future__ import annotations

import hashlib
import json
from pathlib import Path
import subprocess
import tempfile
import unittest

from snapkit_sources import PolicyError, prepare


class SnapKitSourcesTests(unittest.TestCase):
    def setUp(self) -> None:
        self.temp = tempfile.TemporaryDirectory(prefix="snapkit-policy-test.")
        self.root = Path(self.temp.name)
        self.repo = self.root / "SnapKit"
        (self.repo / "Sources").mkdir(parents=True)
        (self.repo / "Sources" / "Core.swift").write_text("public struct Core {}\n")
        (self.repo / "Sources" / "Debugging.swift").write_text(
            "// diagnostic-only fixture\n"
        )
        subprocess.run(["git", "init", "-q", str(self.repo)], check=True)
        subprocess.run(["git", "-C", str(self.repo), "add", "Sources"], check=True)
        subprocess.run(
            [
                "git", "-C", str(self.repo), "-c", "user.name=Policy Test",
                "-c", "user.email=policy@example.invalid", "commit", "-qm", "fixture",
            ],
            check=True,
        )
        commit = subprocess.check_output(
            ["git", "-C", str(self.repo), "rev-parse", "HEAD"], text=True
        ).strip()
        debugging = (self.repo / "Sources" / "Debugging.swift").read_bytes()
        self.policy = {
            "schema": 1,
            "repository_commit": commit,
            "source_root": "Sources",
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

    def tearDown(self) -> None:
        self.temp.cleanup()

    def write_policy(self) -> None:
        self.policy_path.write_text(json.dumps(self.policy))

    def run_prepare(self):
        return prepare(
            str(self.repo), str(self.policy_path), str(self.list_path),
            str(self.audit_path),
        )

    def test_valid_rule_records_exact_denominator_and_subject(self) -> None:
        audit = self.run_prepare()
        self.assertEqual(audit["discovered_source_count"], 2)
        self.assertEqual(audit["included_source_count"], 1)
        self.assertEqual(audit["excluded_source_count"], 1)
        self.assertEqual(
            self.list_path.read_text().splitlines(),
            [str((self.repo / "Sources" / "Core.swift").resolve())],
        )

    def test_refuses_changed_excluded_bytes(self) -> None:
        self.policy["exclusions"][0]["sha256"] = "0" * 64
        self.write_policy()
        with self.assertRaisesRegex(PolicyError, "excluded source hash changed"):
            self.run_prepare()

    def test_refuses_repository_pin_drift(self) -> None:
        self.policy["repository_commit"] = "0" * 40
        self.write_policy()
        with self.assertRaisesRegex(PolicyError, "SnapKit pin changed"):
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


if __name__ == "__main__":
    unittest.main()
