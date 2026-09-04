#!/usr/bin/env python3
"""Contract checks for the portable Foundation ByteCountFormatter."""

from __future__ import annotations

import hashlib
from pathlib import Path
import unittest


ROOT = Path(__file__).resolve().parents[3]
SOURCE = ROOT / "full/foundation/ByteCountFormatter.swift"
ORACLE = ROOT / "full/foundation/tests/FoundationByteCountFormatterOracle.swift"
GOLDEN = ROOT / "full/foundation/tests/foundation-byte-count-apple-2026-08-31.txt"


class FoundationByteCountFormatterTests(unittest.TestCase):
    def test_surface_and_algorithm_are_real(self) -> None:
        source = SOURCE.read_text(encoding="utf-8")
        for token in (
            "open class ByteCountFormatter: ObjectiveC.NSObject",
            "public struct Units: OptionSet",
            "public enum CountStyle: UInt",
            "public static let useYBOrHigher",
            "open class func string(",
            "open func string(fromByteCount byteCount: Int64)",
            "private func _selectedUnit(",
            "rounded(.toNearestOrAwayFromZero)",
            "private func _groupedInteger(",
        ):
            self.assertIn(token, source)
        self.assertNotIn("return \"0 bytes\"", source)

    def test_apple_oracle_is_pinned(self) -> None:
        oracle = ORACLE.read_text(encoding="utf-8")
        for token in (
            "ByteCountFormatter.CountStyle.file",
            "ByteCountFormatter.string(fromByteCount:",
            "formatter.allowedUnits = [.useKB]",
            "formatter.includesActualByteCount = true",
            "bytes.allowsNonnumericFormatting = false",
            "ByteCountFormatter.Units.useYBOrHigher.rawValue",
        ):
            self.assertIn(token, oracle)

        payload = GOLDEN.read_bytes()
        self.assertTrue(payload.endswith(b"\n"))
        self.assertEqual(len(payload.splitlines()), 91)
        self.assertEqual(
            hashlib.sha256(payload).hexdigest(),
            "04b140256b7090a59bfef77354fbcf202ec7085b2191f43ff7201f601ea17270",
        )


if __name__ == "__main__":
    unittest.main()
