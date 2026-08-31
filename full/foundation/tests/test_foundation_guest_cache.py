#!/usr/bin/env python3
"""Static contract for the project-owned NSURL bridge and NSCache."""

from __future__ import annotations

import hashlib
from pathlib import Path
import unittest


ROOT = Path(__file__).resolve().parents[3]
URL_SOURCE = ROOT / "full/foundation/NSURL.swift"
CACHE_SOURCE = ROOT / "full/foundation/NSCache.swift"
ORACLE = ROOT / "full/foundation/tests/FoundationCacheOracle.swift"
GOLDEN = ROOT / "full/foundation/tests/foundation-cache-apple-2026-08-31.txt"


class FoundationGuestCacheTests(unittest.TestCase):
    def test_url_bridge_is_a_real_reference_bridge(self) -> None:
        source = URL_SOURCE.read_text(encoding="utf-8")
        for token in (
            "public protocol ReferenceConvertible",
            "open class NSURL: ObjectiveC.NSObject, NSCopying",
            "internal let _foundationGuestURL: URL",
            "extension URL: @retroactive ReferenceConvertible",
            "@retroactive _ObjectiveCBridgeable",
            "public func _bridgeToObjectiveC() -> NSURL",
            "public static func _forceBridgeFromObjectiveC(",
            "public static func _conditionallyBridgeFromObjectiveC(",
            "public static func _unconditionallyBridgeFromObjectiveC(",
            "extension NSURL: _HasCustomAnyHashableRepresentation",
        ):
            self.assertIn(token, source)
        self.assertNotIn("typealias NSURL", source)

    def test_cache_is_equality_keyed_locked_and_limit_aware(self) -> None:
        source = CACHE_SOURCE.read_text(encoding="utf-8")
        for token in (
            "open class NSCache<KeyType: AnyObject, ObjectType: AnyObject>",
            "private let _lock = NSLock()",
            "private var _entries: [_FoundationGuestCacheKey: Entry]",
            "private var _leastRecent: Entry?",
            "private var _mostRecent: Entry?",
            "open weak var delegate: (any NSCacheDelegate)?",
            "_moveToMostRecentLocked(entry)",
            "_totalCostLimit > 0 && _totalCost > _totalCostLimit",
            "_countLimit > 0 && _entries.count > _countLimit",
            "let normalizedCost = cost < 0 ? Int.max : cost",
            "Unmanaged<NSCache<AnyObject, AnyObject>>",
        ):
            self.assertIn(token, source)
        self.assertNotIn("let normalizedCost = max(cost, 0)", source)

    def test_oracle_and_native_transcript_are_pinned(self) -> None:
        oracle = ORACLE.read_text(encoding="utf-8")
        for token in (
            "let bridged = absolute as NSURL",
            "let roundTrip = bridged as URL",
            "let cache = NSCache<NSURL, Value>()",
            "cache.delegate-same-identity",
            "cache.negative-cost-after-first",
            "cache.access-recency-evicted",
            "cache.retains-key",
            "cache.releases-value",
            "cache.delegate-is-weak",
        ):
            self.assertIn(token, oracle)

        payload = GOLDEN.read_bytes()
        self.assertTrue(payload.endswith(b"\n"))
        self.assertEqual(len(payload.splitlines()), 43)
        self.assertEqual(
            hashlib.sha256(payload).hexdigest(),
            "0dd1fab4b09c76dfe6ab6fc07ac93d9350cf3bb19d31c7d8524c2df8e59e441c",
        )


if __name__ == "__main__":
    unittest.main()
