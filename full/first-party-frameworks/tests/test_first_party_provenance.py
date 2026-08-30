#!/usr/bin/env python3
"""Deletion, mutation, ordering, and symlink negatives for source provenance."""

from __future__ import annotations

import json
from pathlib import Path
import shutil
import subprocess
import tempfile
import unittest


HERE = Path(__file__).resolve().parent
REPO = HERE.parents[2]
TOOL = HERE.parent / "first_party_provenance.py"
POLICY = HERE.parent / "first-party-provenance.json"


def exact_file_records(value: object) -> list[dict[str, str]]:
    result: list[dict[str, str]] = []
    if isinstance(value, dict):
        if set(value) == {"path", "sha256"}:
            result.append(value)
        else:
            for child in value.values():
                result.extend(exact_file_records(child))
    elif isinstance(value, list):
        for child in value:
            result.extend(exact_file_records(child))
    return result


class ProvenanceTests(unittest.TestCase):
    def setUp(self) -> None:
        self.temporary = tempfile.TemporaryDirectory()
        self.root = Path(self.temporary.name) / "support"
        self.root.mkdir()
        self.policy = json.loads(POLICY.read_text(encoding="utf-8"))
        for record in exact_file_records(self.policy):
            source = REPO / record["path"]
            destination = self.root / record["path"]
            destination.parent.mkdir(parents=True, exist_ok=True)
            shutil.copyfile(source, destination)

    def tearDown(self) -> None:
        self.temporary.cleanup()

    def run_gate(
        self,
        *,
        expected: int = 0,
        policy: Path = POLICY,
        output_name: str = "attestation.tsv",
    ) -> subprocess.CompletedProcess[str]:
        result = subprocess.run(
            [
                "python3",
                "-B",
                str(TOOL),
                "production",
                "--support-root",
                str(self.root),
                "--policy",
                str(policy),
                "--output",
                str(self.root / output_name),
            ],
            text=True,
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
            check=False,
        )
        self.assertEqual(
            result.returncode,
            expected,
            f"stdout:\n{result.stdout}\nstderr:\n{result.stderr}",
        )
        return result

    def test_exact_policy_emits_seven_ordered_sources(self) -> None:
        self.run_gate()
        lines = (self.root / "attestation.tsv").read_text().splitlines()
        sources = [line.split("\t")[2] for line in lines if line.startswith("source\t")]
        self.assertEqual(
            sources,
            [framework["name"] for framework in self.policy["frameworks"]],
        )

    def test_source_mutation_is_refused(self) -> None:
        source = self.root / self.policy["frameworks"][0]["sources"][0]["path"]
        source.write_text(source.read_text() + "\n", encoding="utf-8")
        refusal = self.run_gate(expected=2)
        self.assertIn("digest drifted", refusal.stderr)

    def test_source_deletion_is_refused(self) -> None:
        source = self.root / self.policy["frameworks"][3]["sources"][0]["path"]
        source.unlink()
        refusal = self.run_gate(expected=2)
        self.assertIn("physical Swift source set drifted", refusal.stderr)

    def test_source_symlink_is_refused(self) -> None:
        first = self.root / self.policy["frameworks"][0]["sources"][0]["path"]
        second = self.root / self.policy["frameworks"][1]["sources"][0]["path"]
        first.unlink()
        first.symlink_to(second)
        refusal = self.run_gate(expected=2)
        self.assertIn("symlinked", refusal.stderr)

    def test_top_manifest_reordering_is_refused(self) -> None:
        top = self.root / self.policy["top_source_manifest"]["path"]
        lines = top.read_text(encoding="utf-8").splitlines()
        top.write_text("\n".join(reversed(lines)) + "\n", encoding="utf-8")
        refusal = self.run_gate(expected=2)
        self.assertIn("digest drifted", refusal.stderr)

    def test_policy_framework_reordering_is_refused(self) -> None:
        policy = dict(self.policy)
        policy["frameworks"] = list(reversed(policy["frameworks"]))
        mutated = self.root / "mutated-policy.json"
        mutated.write_text(json.dumps(policy), encoding="utf-8")
        refusal = self.run_gate(expected=2, policy=mutated)
        self.assertIn("framework order drifted", refusal.stderr)

    def test_existing_output_is_refused(self) -> None:
        self.run_gate()
        refusal = self.run_gate(expected=2)
        self.assertIn("refusing to overwrite output", refusal.stderr)


if __name__ == "__main__":
    unittest.main()
