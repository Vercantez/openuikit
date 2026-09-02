#!/usr/bin/env python3
"""Byte-identical refusal text for the extracted hash ledger."""

from __future__ import annotations

import hashlib
from pathlib import Path
import subprocess
import tempfile
import unittest
import sys

ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT / "scripts" / "env"))

from ledger import LedgerError, require_hash, sha256_file  # noqa: E402


LEDGER = ROOT / "scripts" / "env" / "ledger.py"


class LedgerHashTests(unittest.TestCase):
    def test_sha256_matches_hashlib_and_sha256sum(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            path = Path(tmp) / "blob"
            path.write_bytes(b"openuikit-ledger\n")
            digest = sha256_file(path)
            self.assertEqual(digest, hashlib.sha256(b"openuikit-ledger\n").hexdigest())
            proc = subprocess.run(
                ["python3", str(LEDGER), "hash-file", str(path)],
                check=True,
                capture_output=True,
                text=True,
            )
            self.assertEqual(proc.stdout.strip(), digest)

    def test_core_require_hash_refusal_text_is_byte_identical(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            path = Path(tmp) / "blob"
            path.write_bytes(b"x")
            actual = sha256_file(path)
            expected = "0" * 64
            proc = subprocess.run(
                [
                    "python3",
                    str(LEDGER),
                    "--style",
                    "core",
                    "require-hash",
                    str(path),
                    expected,
                    "machorun-Swift-core",
                ],
                capture_output=True,
                text=True,
            )
            self.assertEqual(proc.returncode, 2)
            self.assertEqual(
                proc.stderr,
                f"core_guest_package: REFUSING -- machorun-Swift-core hash {actual}, expected {expected}\n",
            )

    def test_core_missing_file_refusal_text(self) -> None:
        missing = Path("/tmp/openuikit-ledger-absent-file")
        if missing.exists():
            missing.unlink()
        proc = subprocess.run(
            [
                "python3",
                str(LEDGER),
                "--style",
                "core",
                "require-hash",
                str(missing),
                "0" * 64,
                "label",
            ],
            capture_output=True,
            text=True,
        )
        self.assertEqual(proc.returncode, 2)
        self.assertEqual(
            proc.stderr,
            f"core_guest_package: REFUSING -- missing regular label: {missing}\n",
        )

    def test_focus_widget_drift_refusal_text(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            path = Path(tmp) / "Assets.swift"
            path.write_bytes(b"not-the-pin")
            actual = sha256_file(path)
            proc = subprocess.run(
                [
                    "python3",
                    str(LEDGER),
                    "--style",
                    "focus-widget",
                    "require-hash",
                    str(path),
                    "e" * 64,
                    "Assets.swift",
                ],
                capture_output=True,
                text=True,
            )
            self.assertEqual(proc.returncode, 2)
            self.assertEqual(
                proc.stderr,
                f"focus_widget_guest: Assets.swift drifted: {actual}\n",
            )

    def test_require_hash_success_is_silent(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            path = Path(tmp) / "ok"
            path.write_bytes(b"ok")
            digest = sha256_file(path)
            require_hash(path, digest, "ok", "core")
            proc = subprocess.run(
                ["python3", str(LEDGER), "require-hash", str(path), digest, "ok"],
                check=True,
                capture_output=True,
                text=True,
            )
            self.assertEqual(proc.stdout, "")
            self.assertEqual(proc.stderr, "")

    def test_core_guest_package_delegates_hash_ledger(self) -> None:
        text = (ROOT / "full/frameworks/build_core_guest_package.sh").read_text()
        self.assertIn('LEDGER_TOOL=$W/scripts/env/ledger.py', text)
        self.assertIn('python3 "$LEDGER_TOOL" --style core hash-file "$1"', text)
        self.assertIn(
            'python3 "$LEDGER_TOOL" --style core require-hash "$1" "$2" "$3"',
            text,
        )
        self.assertIn(
            'python3 "$LEDGER_TOOL" --style core assert-clean-commit "$1" "$2" "$3" "$4"',
            text,
        )
        self.assertNotIn('hash_file() { sha256sum', text)
        self.assertIn(
            'require_hash "$SWIFT_CORE_RUNTIME" "$EXPECTED_MACHORUN_SWIFT_CORE_SHA256"',
            text,
        )
        self.assertIn("assert_clean_commit \"$SWIFT_FOUNDATION\"", text)

    def test_symlink_is_missing_regular(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            real = Path(tmp) / "real"
            link = Path(tmp) / "link"
            real.write_bytes(b"x")
            link.symlink_to(real)
            with self.assertRaises(LedgerError) as raised:
                require_hash(link, sha256_file(real), "label", "core")
            self.assertIn("missing regular label:", str(raised.exception))


if __name__ == "__main__":
    unittest.main(verbosity=2)
