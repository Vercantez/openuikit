from pathlib import Path
import unittest


ROOT = Path(__file__).resolve().parents[2]
HOST = ROOT / "xcodeplan" / "build_and_run_true_ios_target_guest.sh"
GUEST = ROOT / "xcodeplan" / "true_ios_target_guest_inner.sh"
PROBE = ROOT / "xcodeplan" / "TrueIOSTargetProbe.swift"


class TrueIOSTargetGuestTests(unittest.TestCase):
    def test_route_is_true_ios_no_network_and_source_preserving(self) -> None:
        host = HOST.read_text(encoding="utf-8")
        guest = GUEST.read_text(encoding="utf-8")
        probe = PROBE.read_text(encoding="utf-8")

        self.assertIn("#if os(iOS)", probe)
        self.assertIn("#error", probe)
        self.assertIn("arm64-apple-ios17.0-simulator", guest)
        self.assertIn("-platform_version ios-simulator", guest)
        self.assertIn("platform 7", guest)
        self.assertIn("TRUE_IOS_TRIPLE_GUEST_OK", probe)
        self.assertIn("TRUE_IOS_TRIPLE_GUEST_OK", guest)
        self.assertIn("-module-name os", guest)
        self.assertIn("-module-name OSLog", guest)
        self.assertIn("libOSLog.dylib", guest)
        self.assertIn("-reexport_library", guest)
        self.assertIn("OSLOG_GUEST_MACHO_OK", guest)
        self.assertIn("--network none", host)
        self.assertIn("--read-only", host)
        self.assertIn('"$CORE_PACKAGE:/package:ro"', host)
        self.assertIn('cp -a "$CORE_PACKAGE/sdk/." "$STAGE/sdk/"', host)
        self.assertIn('inputs/OSLogGuestRuntime.swift', host)
        self.assertNotIn(":/package:rw", host)
        self.assertNotIn("xcodebuild", host)
        self.assertNotIn("swift build", host)


if __name__ == "__main__":
    unittest.main()
