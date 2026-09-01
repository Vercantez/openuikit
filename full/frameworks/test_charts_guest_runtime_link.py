from pathlib import Path
import unittest


BUILDER = Path(__file__).with_name("build_core_guest_package.sh")


def validate_charts_main_header_export(source: str) -> None:
    start_token = "== compile/link/run the standalone Charts mark and interaction gate"
    end_token = "== typecheck the exact-surface IceCubes Charts consumer"
    if source.count(start_token) != 1 or source.count(end_token) != 1:
        raise AssertionError("Charts gate boundaries drifted")
    section = source.split(start_token, 1)[1].split(end_token, 1)[0]
    if section.count("-exported_symbol __mh_execute_header") != 1:
        raise AssertionError("Charts gate must export one main Mach header")
    if section.index("-exported_symbol __mh_execute_header") > section.index(
        '"${PREVIEW_STANDALONE_EXPORT_FLAGS[@]}"'
    ):
        raise AssertionError("main Mach header must be an unconditional export")


class ChartsGuestRuntimeLinkTests(unittest.TestCase):
    def test_charts_gate_exports_the_header_libsystem_resolves_flat(self) -> None:
        validate_charts_main_header_export(BUILDER.read_text(encoding="utf-8"))

    def test_missing_header_export_mutation_is_rejected(self) -> None:
        source = BUILDER.read_text(encoding="utf-8")
        start = source.index(
            "== compile/link/run the standalone Charts mark and interaction gate"
        )
        end = source.index(
            "== typecheck the exact-surface IceCubes Charts consumer", start
        )
        mutated = (
            source[:start]
            + source[start:end].replace(
                "    -exported_symbol __mh_execute_header \\\n", "", 1
            )
            + source[end:]
        )
        with self.assertRaisesRegex(AssertionError, "main Mach header"):
            validate_charts_main_header_export(mutated)


if __name__ == "__main__":
    unittest.main()
