#!/usr/bin/env python3
"""Pinned Apple goldens for the portable Foundation formatter families."""

from __future__ import annotations

import hashlib
from pathlib import Path
import unittest


ROOT = Path(__file__).resolve().parents[3]
TESTS = ROOT / "full/foundation/tests"
FOUNDATION = ROOT / "full/foundation"

FAMILIES = (
    (
        "DateFormatter",
        FOUNDATION / "DateFormatter.swift",
        TESTS / "FoundationDateFormatterOracle.swift",
        TESTS / "foundation-date-formatter-apple-2026-09-05.txt",
        260,
        "84a46634dd58a12a34de8de9aa1f66e0cb33a1d8ff174386a3dd64407ae3b3b7",
        ("date(from:", "_stylePatterns", "en_US_POSIX.1.0", "ja_JP.4.4"),
        ("hh 'o''clock' a", "parse.posix", "de_DE"),
    ),
    (
        "JSONSerialization",
        FOUNDATION / "JSONSerialization.swift",
        TESTS / "FoundationJSONSerializationOracle.swift",
        TESTS / "foundation-json-serialization-apple-2026-09-05.txt",
        41,
        "5f187eaac6c905da2693c215cfdc77b3f1d62a8e38ba8fc5cadde0afc71c737b",
        ("_stripJSONTrailingCommas", "fragmentsAllowed", "NSJSONSerializationErrorIndex"),
        ('#"{"a":1,}"#', "trail.\\(index).ok", "prettyPrinted"),
    ),
    (
        "NSRegularExpression",
        FOUNDATION / "NSRegularExpression.swift",
        TESTS / "FoundationNSRegularExpressionOracle.swift",
        TESTS / "foundation-nsregularexpression-apple-2026-09-05.txt",
        62,
        "662f6ff1b573dd356deee18900069b128f4c317d062ecfbbe872fc52899da5a3",
        ("numberOfCaptureGroups", "stringByReplacingMatches", "range(withName name:"),
        ("(?<word>[0-9]+)", "re.named.word", "anchorsMatchLines"),
    ),
    (
        "NumberFormatter",
        FOUNDATION / "NumberFormatter.swift",
        TESTS / "FoundationNumberFormatterOracle.swift",
        TESTS / "foundation-number-formatter-apple-2026-09-05.txt",
        178,
        "f35de34111f334621940318f2f764680cea2e967752a7242f5bf9b1b6e774be8",
        ("case ordinal = 6", "RoundingMode", "en_US_POSIX", "ja_JP"),
        ('("ordinal", .ordinal)', "halfEven", "parse.de"),
    ),
    (
        "ISO8601DateFormatter",
        FOUNDATION / "ISO8601DateFormatter.swift",
        TESTS / "FoundationISO8601DateFormatterOracle.swift",
        TESTS / "foundation-iso8601-date-formatter-apple-2026-09-05.txt",
        33,
        "e1a61100b1acd19408eb73e978a84b983a97b09e117a50887143e57c3bed04e7",
        ("withInternetDateTime", "withFractionalSeconds", "withWeekOfYear"),
        ('"internet.frac"', "parse.offset", "opt.internet"),
    ),
    (
        "DateComponentsFormatter",
        FOUNDATION / "DateComponentsFormatter.swift",
        TESTS / "FoundationDateComponentsFormatterOracle.swift",
        TESTS / "foundation-date-components-formatter-apple-2026-09-05.txt",
        46,
        "6e5bd8bf2b38f55cce53c08fcc8dc63f465b88aa760132728a8594f107c46335",
        ("ZeroFormattingBehavior", "dropAll", "UnitsStyle"),
        ("dcf.full.\\(localeID)", "zero.pad", "allowedUnits"),
    ),
)


class FoundationFormatterOracleTests(unittest.TestCase):
    def test_each_family_is_pinned_to_the_apple_golden(self) -> None:
        for name, source, oracle, golden, rows, digest, source_tokens, oracle_tokens in FAMILIES:
            with self.subTest(name=name):
                source_text = source.read_text(encoding="utf-8")
                oracle_text = oracle.read_text(encoding="utf-8")
                for token in source_tokens:
                    self.assertIn(token, source_text, f"{name} source missing {token}")
                for token in oracle_tokens:
                    self.assertIn(token, oracle_text, f"{name} oracle missing {token}")
                payload = golden.read_bytes()
                self.assertTrue(payload.endswith(b"\n"), name)
                self.assertEqual(len(payload.splitlines()), rows, name)
                self.assertEqual(hashlib.sha256(payload).hexdigest(), digest, name)


if __name__ == "__main__":
    unittest.main()
