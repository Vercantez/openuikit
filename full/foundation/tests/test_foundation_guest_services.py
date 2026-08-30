#!/usr/bin/env python3
"""Static fail-closed checks for the production Foundation facade manifest."""

from pathlib import Path
import unittest


ROOT = Path(__file__).resolve().parents[3]
MANIFEST = ROOT / "full/foundation/foundation_guest_sources.txt"
ONBOARDING = ROOT / "full/swiftui/build_focus_onboarding_guest.sh"

EXPECTED = [
    "full/appshim/FoundationGuest.swift",
    "full/appshim/FoundationOpenUIKitAliases.swift",
    "full/foundation/CharacterSet.swift",
    "full/foundation/String+CharacterSet.swift",
    "full/foundation/Scanner.swift",
    "full/foundation/Error+LocalizedDescription.swift",
    "full/foundation/DateFormatter.swift",
    "full/foundation/UserDefaults.swift",
]


class FoundationGuestServicesTests(unittest.TestCase):
    def test_manifest_is_exact_and_production_only(self) -> None:
        self.assertEqual(MANIFEST.read_text().splitlines(), EXPECTED)
        self.assertTrue(MANIFEST.read_bytes().endswith(b"\n"))
        self.assertEqual(len(EXPECTED), len(set(EXPECTED)))
        for relative in EXPECTED:
            path = ROOT / relative
            self.assertTrue(path.is_file(), relative)
            self.assertFalse(path.is_symlink(), relative)
            self.assertNotIn("/tests/", relative)
            self.assertNotIn("probe", relative.lower())

    def test_onboarding_consumes_and_validates_manifest(self) -> None:
        source = ONBOARDING.read_text()
        self.assertIn("FOUNDATION_GUEST_MANIFEST=", source)
        self.assertIn("mapfile -t FOUNDATION_GUEST_RELATIVE_SOURCES", source)
        self.assertIn('"${#FOUNDATION_GUEST_RELATIVE_SOURCES[@]}" -eq 8', source)
        self.assertIn('"${FOUNDATION_GUEST_SOURCES[@]}"', source)
        self.assertIn("duplicate Foundation guest source", source)
        self.assertIn("escaped production source roots", source)
        compile_region = source[source.index("== compile the bounded Foundation umbrella"):]
        compile_region = compile_region[:compile_region.index("== FoundationGuest/UIKit")]
        self.assertNotIn('"$W/full/appshim/FoundationGuest.swift"', compile_region)
        self.assertNotIn('"$W/full/appshim/FoundationOpenUIKitAliases.swift"', compile_region)

    def test_date_formatter_is_calendar_backed_and_bounded(self) -> None:
        source = (ROOT / "full/foundation/DateFormatter.swift").read_text()
        self.assertIn("Calendar", source)
        self.assertIn("dateComponents", source)
        self.assertIn("TimeZone", source)
        for token in ('case "M", "L"', 'case "E"', 'case "h"', 'case "S"', 'case "X"'):
            self.assertIn(token, source)
        self.assertNotIn("Date(timeIntervalSince1970: 0)", source)

    def test_user_defaults_has_real_persistence_and_value_round_trips(self) -> None:
        source = (ROOT / "full/foundation/UserDefaults.swift").read_text()
        self.assertIn("Data(contentsOf:", source)
        self.assertIn("data.write", source)
        self.assertIn("options: .atomic", source)
        self.assertIn("JSONEncoder", source)
        self.assertIn("JSONDecoder", source)
        self.assertIn("Mutex<", source)
        self.assertIn("case data(Data)", source)
        self.assertIn("case date(Date)", source)
        self.assertNotIn("static var storage", source)

    def test_host_gate_is_cross_process_and_mutation_sensitive(self) -> None:
        source = (
            ROOT / "full/foundation/tests/test_foundation_guest_services_host.sh"
        ).read_text()
        self.assertIn('"$WORK/defaults" write "$SUITE"', source)
        self.assertIn('"$WORK/defaults" read "$SUITE"', source)
        self.assertIn("DateFormatter mutation escaped", source)
        self.assertIn("cmp \"$WORK/oracle.txt\"", source)


if __name__ == "__main__":
    unittest.main()
