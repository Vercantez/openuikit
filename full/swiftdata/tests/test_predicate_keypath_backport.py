#!/usr/bin/env python3
"""Prove the pinned, derived Foundation Predicate backport fails closed."""

from __future__ import annotations

import hashlib
from pathlib import Path
import shutil
import subprocess
import tempfile
import unittest


REPO = Path(__file__).resolve().parents[3]
PATCH = (
    REPO
    / "full/foundation/patches/FoundationEssentials-PredicateFinalClassKeyPath.patch"
)
PINNED = Path(
    "/private/tmp/hackers-platform-cold-inputs-20260831/swift-foundation/"
    "Sources/FoundationEssentials/Predicate/KeyPath+Inspection.swift"
)
SOURCE_SHA = "835ca09d5d0bf757abc02af0ca4294cc58bcad3d455ef71c1026746ad7ba08f7"
PATCH_SHA = "ecf4e8045d42fb196705f37fbf723f75e11c20d9d6b2adc251210ed87e1464de"


def digest(path: Path) -> str:
    return hashlib.sha256(path.read_bytes()).hexdigest()


def apply(source: Path, output: Path) -> subprocess.CompletedProcess[str]:
    return subprocess.run(
        [
            "patch", "--batch", "--forward", "--fuzz=0", "-s",
            "-o", str(output), str(source), str(PATCH),
        ],
        text=True,
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
        check=False,
    )


class PredicateKeyPathBackportTests(unittest.TestCase):
    def test_exact_pinned_source_is_derived_without_mutating_upstream(self) -> None:
        self.assertTrue(PINNED.is_file(), f"missing exact pinned source: {PINNED}")
        self.assertEqual(digest(PINNED), SOURCE_SHA)
        self.assertEqual(digest(PATCH), PATCH_SHA)
        before = PINNED.read_bytes()
        with tempfile.TemporaryDirectory(prefix="predicate-keypath-backport.") as temp:
            output = Path(temp) / "KeyPath+Inspection.swift"
            result = apply(PINNED, output)
            self.assertEqual(result.returncode, 0, result.stderr)
            derived = output.read_text(encoding="utf-8")
            self.assertIn(
                "STORED_COMPONENT_PAYLOAD_MAXIMUM_INLINE_OFFSET", derived
            )
            self.assertNotIn("private func _keyPathOffset", derived)
        self.assertEqual(PINNED.read_bytes(), before)

    def test_context_mutation_is_refused(self) -> None:
        with tempfile.TemporaryDirectory(prefix="predicate-keypath-mutation.") as temp:
            source = Path(temp) / "KeyPath+Inspection.swift"
            shutil.copyfile(PINNED, source)
            source.write_text(
                source.read_text(encoding="utf-8").replace(
                    "private func _keyPathOffset",
                    "private func _mutatedKeyPathOffset",
                    1,
                ),
                encoding="utf-8",
            )
            output = Path(temp) / "derived.swift"
            result = apply(source, output)
            self.assertNotEqual(result.returncode, 0)


if __name__ == "__main__":
    unittest.main()
