#!/usr/bin/env python3
"""Lock-agreement teeth for env/contract.json and the marker registry."""

from __future__ import annotations

import json
import unittest
from pathlib import Path
import sys

ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT / "scripts"))

from env.contract import checkouts_by_id, demanded_by, load_contract, validate_against_locks
from env.markers import (
    CANNOT_PREFIX,
    MARKERS,
    classify_line,
    count_kinds,
    emitted_cannot_names,
)


class ContractLockTests(unittest.TestCase):
    def test_contract_agrees_with_every_consumed_lock(self) -> None:
        notes = validate_against_locks(ROOT)
        self.assertGreaterEqual(len(notes), 10)
        self.assertTrue(all("agree" in note or "cited" in note for note in notes))

    def test_focus_widget_demanded_rows_have_denominators(self) -> None:
        contract = load_contract(ROOT)
        rows = demanded_by(contract, "focus-widget")
        checkout_n = len(rows["checkouts"])
        product_n = len(rows["built_products"])
        staged_n = len(rows["staged_externals"])
        host_n = len(rows["host_requirements"])
        fs_n = len(rows["filesystem_preconditions"])
        total = checkout_n + product_n + staged_n + host_n + fs_n
        self.assertGreaterEqual(checkout_n, 6)
        self.assertGreaterEqual(product_n, 4)
        self.assertGreaterEqual(staged_n, 3)
        self.assertGreaterEqual(fs_n, 3)
        self.assertGreaterEqual(total, 18)
        print(
            f"focus-widget demanded_by checkouts={checkout_n} "
            f"built_products={product_n} staged={staged_n} "
            f"host={host_n} filesystem={fs_n} total={total}"
        )

    def test_corpus_ids_are_exactly_the_lock_set(self) -> None:
        contract = load_contract(ROOT)
        lock = json.loads(
            (ROOT / ".cursor" / "scratch-corpus-pins.json").read_text(encoding="utf-8")
        )
        lock_ids = {row["id"] for row in lock["sources"]}
        contract_ids = {
            row["id"]
            for row in contract["checkouts"]
            if row.get("lock") == ".cursor/scratch-corpus-pins.json"
        }
        self.assertEqual(lock_ids, contract_ids)

    def test_vendor_pins_are_not_silently_advanced(self) -> None:
        checkouts = checkouts_by_id(load_contract(ROOT))
        self.assertEqual(
            checkouts["uikit-inrepo"]["tree"],
            "e737cdd02e89f8aa7446ee69a6464ac1c2108335",
        )
        self.assertEqual(
            checkouts["machorun-inrepo"]["tree"],
            "51fa23295a14085f079a90b6977c4918b165c449",
        )

    def test_ud_guest_x86_demands_pinned_corelibs_foundation(self) -> None:
        row = checkouts_by_id(load_contract(ROOT))["swift-corelibs-foundation"]
        self.assertEqual(row["commit"], "f3a7a34302317a95665bf4ff1a62ee1b459c1695")
        self.assertEqual(row["tree"], "2f9136f253a51406f2bcb0a612bcb6a9eba03570")
        self.assertEqual(row["destination"], "scratch/ud-guest-x86_64/cf")
        self.assertIn("ud-guest-x86", row["demanded_by"])
        self.assertEqual(
            row["repository"],
            "https://github.com/swiftlang/swift-corelibs-foundation.git",
        )
        self.assertEqual(row["lock"], "scripts/x86/ud_guest.inc")
        self.assertEqual(row["kind"], "git")

    def test_focus_widget_gate_still_locks_all_attestation_pins(self) -> None:
        notes = validate_against_locks(ROOT)
        pin_notes = [n for n in notes if n.startswith("focus_widget_attestation_pins ")]
        self.assertEqual(len(pin_notes), 1)
        self.assertIn("25/25", pin_notes[0])
        print(pin_notes[0])


class MarkerRegistryTests(unittest.TestCase):
    def test_emitted_cannot_markers_are_the_pr3_set(self) -> None:
        names = emitted_cannot_names()
        expected = (
            "CURSOR_ENV_CANNOT_BUILD_LOADER",
            "CURSOR_ENV_CANNOT_GENERATE_TBD",
            "CURSOR_ENV_CANNOT_STAGE_MRROOT_LOADER",
            "CURSOR_ENV_CANNOT_STAGE_XCODE_DARWIN_OVERLAYS",
            "CURSOR_ENV_CANNOT_STAGE_SIMRUNTIME_OVERLAY_DYLIBS",
            "CURSOR_ENV_CANNOT_BUILD_OPENCOMBINE_EXPORT",
            "CURSOR_ENV_CANNOT_BUILD_MODCACHE_SWIFTUI_GUEST",
            "CURSOR_ENV_CANNOT_EXECUTE_ARM64",
        )
        self.assertEqual(names, expected)
        self.assertTrue(all(name.startswith(CANNOT_PREFIX) for name in names))
        self.assertFalse(MARKERS["NEEDS_DARWIN_BASELINE"].currently_emitted)

    def test_count_kinds_separates_cannot_from_refuse(self) -> None:
        lines = [
            "CURSOR_ENV_CANNOT_EXECUTE_ARM64 host=x86_64 machorun=arm64-linux-native",
            "CURSOR_CORPUS_OK id=swift-collections reused=1",
            "ENV_PREPARE_SUMMARY satisfied=1/1 cold-built=0/0 staged=0/0 CANNOT=0/0",
            "focus_widget_guest: missing /w/scratch/swift-collections",
            "some other log line",
        ]
        counts = count_kinds(lines)
        self.assertEqual(
            counts,
            {"cannot": 1, "pass": 1, "summary": 1, "refuse": 1, "other": 1},
        )
        self.assertEqual(classify_line(lines[0]), "cannot")
        self.assertEqual(classify_line(lines[3]), "refuse")


if __name__ == "__main__":
    unittest.main(verbosity=2)
