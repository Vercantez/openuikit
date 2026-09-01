from pathlib import Path
import unittest


ROOT = Path(__file__).resolve().parents[2]
MATH = ROOT / "full/shims/libsystem_math_compat.c"
BUILD_FULL = ROOT / "full/scripts/build_full.sh"
LEGACY_BUILD = ROOT / "scripts/build_runtime_shims.sh"
PROBE = ROOT / "full/frameworks/CoreGuestPackageProbe.swift"
BUILDER = ROOT / "full/frameworks/build_core_guest_package.sh"


class LibSystemMathCompatibilityTests(unittest.TestCase):
    def test_runtime_defines_the_two_exact_darwin_symbols(self) -> None:
        source = MATH.read_text(encoding="utf-8")
        self.assertEqual(source.count('__asm__("_nan")'), 1)
        self.assertEqual(source.count('__asm__("_remquo")'), 1)
        self.assertIn("quotient_bits &= 0x7f", source)
        self.assertIn("0x7ff8000000000000", source)
        self.assertIn("0x0007ffffffffffff", source)
        self.assertIn("UINT64_MAX", source)

    def test_every_libsystem_umbrella_links_the_math_object(self) -> None:
        full = BUILD_FULL.read_text(encoding="utf-8")
        legacy = LEGACY_BUILD.read_text(encoding="utf-8")
        self.assertEqual(full.count('"$OUT/mathpatch.o"'), 3)
        self.assertEqual(legacy.count('"$OUT/mathpatch.o"'), 2)
        self.assertIn('full/shims/libsystem_math_compat.c', full)
        self.assertIn('full/shims/libsystem_math_compat.c', legacy)
        for symbol in ("_nan", "_remquo"):
            self.assertIn(symbol, full)
            self.assertIn(symbol, BUILDER.read_text(encoding="utf-8"))

    def test_cold_probe_executes_the_real_swift_tgmath_surface(self) -> None:
        probe = PROBE.read_text(encoding="utf-8")
        self.assertIn("remquo(CGFloat(257), CGFloat(1))", probe)
        self.assertIn('OpenCoreGraphics.nan("0x42")', probe)
        self.assertNotIn('precondition(nan("0x42")', probe)
        self.assertIn("graphics=coreimage,quartzcore,tgmath", probe)
        self.assertIn(
            "graphics=coreimage,quartzcore,tgmath",
            BUILDER.read_text(encoding="utf-8"),
        )


if __name__ == "__main__":
    unittest.main()
