#!/usr/bin/env python3
from __future__ import annotations

import json
from pathlib import Path
import shutil
import subprocess
import tempfile
import unittest


HERE = Path(__file__).resolve().parent
ROOT = HERE.parents[2]
WEBKIT = ROOT / "full/webkit"
TOOL = WEBKIT / "webkit_provenance.py"
POLICY = WEBKIT / "webkit-provenance.json"


def run_production(root: Path, expected: int = 0) -> subprocess.CompletedProcess[str]:
    result = subprocess.run(
        [
            "python3",
            "-B",
            str(TOOL),
            "production",
            "--support-root",
            str(root),
            "--policy",
            str(root / "full/webkit/webkit-provenance.json"),
            "--output",
            str(root / "attestation.tsv"),
        ],
        text=True,
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
        check=False,
    )
    if result.returncode != expected:
        raise AssertionError(
            f"expected {expected}, got {result.returncode}\n"
            f"stdout:\n{result.stdout}\nstderr:\n{result.stderr}"
        )
    return result


class WebKitProvenanceTests(unittest.TestCase):
    def setUp(self) -> None:
        self.temporary = tempfile.TemporaryDirectory()
        self.root = Path(self.temporary.name)
        policy = json.loads(POLICY.read_text(encoding="utf-8"))
        relative_files = [
            "full/webkit/webkit-provenance.json",
            policy["source_manifest"]["path"],
            policy["native_oracle"]["signature_source"]["path"],
            policy["native_oracle"]["golden"]["path"],
        ] + [record["path"] for record in policy["sources"]]
        for relative in relative_files:
            target = self.root / relative
            target.parent.mkdir(parents=True, exist_ok=True)
            shutil.copyfile(ROOT / relative, target)

    def tearDown(self) -> None:
        self.temporary.cleanup()

    def test_exact_production_subject_is_attested(self) -> None:
        run_production(self.root)
        lines = (self.root / "attestation.tsv").read_text().splitlines()
        self.assertEqual(lines[0], "format\twebkit-guest-sources-v1")
        self.assertEqual(len([line for line in lines if line.startswith("source\t")]), 5)
        self.assertEqual(len([line for line in lines if line.startswith("native-")]), 3)

    def test_deleted_source_is_refused(self) -> None:
        (self.root / "full/webkit/WebKitError.swift").unlink()
        refusal = run_production(self.root, expected=2)
        self.assertIn("missing WebKit production source", refusal.stderr)

    def test_mutated_source_is_refused(self) -> None:
        source = self.root / "full/webkit/WebKitWebView.swift"
        source.write_text(source.read_text() + "\n// mutation\n")
        refusal = run_production(self.root, expected=2)
        self.assertIn("digest drifted", refusal.stderr)

    def test_reordered_manifest_is_refused(self) -> None:
        manifest = self.root / "full/webkit/webkit_guest_sources.txt"
        lines = manifest.read_text().splitlines()
        lines[0], lines[1] = lines[1], lines[0]
        manifest.write_text("\n".join(lines) + "\n")
        refusal = run_production(self.root, expected=2)
        self.assertIn("manifest digest drifted", refusal.stderr)

    def test_unmanifested_production_swift_is_refused(self) -> None:
        (self.root / "full/webkit/Lookalike.swift").write_text("public struct Lookalike {}\n")
        refusal = run_production(self.root, expected=2)
        self.assertIn("unmanifested", refusal.stderr)

    def test_symlinked_source_is_refused(self) -> None:
        source = self.root / "full/webkit/WebKitError.swift"
        source.unlink()
        source.symlink_to(self.root / "full/webkit/WebKitContent.swift")
        refusal = run_production(self.root, expected=2)
        self.assertIn("symlinked", refusal.stderr)


if __name__ == "__main__":
    unittest.main()
