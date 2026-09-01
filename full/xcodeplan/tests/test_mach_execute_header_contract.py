#!/usr/bin/env python3

from pathlib import Path
import unittest


ROOT = Path(__file__).resolve().parents[3]
TRUE_IOS_BUILDER = ROOT / "full/xcodeplan/build_true_ios_platform_frameworks.sh"
APPLICATION_DRIVER = ROOT / "full/xcodeplan/build_portable_application_guest.sh"
FOUNDATION_INTL_BUILDER = (
    ROOT
    / "full/foundationinternationalization/build_foundation_internationalization.sh"
)

# These are the remaining helpers invoked directly by the two production
# routes. They inspect, plan, materialize, or attest; executable linking must
# stay in the two audited owners above. FoundationInternationalization is
# handled separately because it owns three Mach-O dylibs and no executable.
NON_LINKING_HELPERS = (
    ROOT / "full/xcodeplan/application_platform_package.py",
    ROOT / "full/xcodeplan/application_build_plan.py",
    ROOT / "full/xcodeplan/local_package_graph.py",
    ROOT / "full/xcodeplan/materialize_application_bundle.py",
    ROOT / "full/xcodeplan/compiler_input_providers.py",
    ROOT / "full/xcodeplan/application_object_contract.py",
    ROOT / "full/xcodeplan/swift_compiler_diagnostics.sh",
    ROOT / "full/xcodeplan/core_guest_package.py",
    ROOT / "full/xcodeplan/true_ios_platform_package.py",
    ROOT / "full/swiftui/focus_widget_guest_attest.pl",
    ROOT / "full/scripts/uihelpers_subject.sh",
    ROOT / "full/oracle-opencombine/policy_tool.pl",
)

MACH_HEADER_EXPORT = "-exported_symbol __mh_execute_header"


def logical_shell_commands(source: str) -> list[str]:
    """Join backslash-continued shell source into auditable commands."""

    commands: list[str] = []
    pieces: list[str] = []
    for raw_line in source.splitlines():
        line = raw_line.strip()
        if not pieces and (not line or line.startswith("#")):
            continue
        if line.endswith("\\"):
            pieces.append(line[:-1].rstrip())
            continue
        pieces.append(line)
        commands.append(" ".join(piece for piece in pieces if piece))
        pieces = []
    if pieces:
        commands.append(" ".join(piece for piece in pieces if piece))
    return commands


def direct_macho_link_commands(source: str) -> list[str]:
    prefixes = (
        '"${LD[@]}" ',
        "ld64.lld-18 ",
        "link_command=(ld64.lld-18 ",
    )
    return [
        command
        for command in logical_shell_commands(source)
        if command.startswith(prefixes)
    ]


def validate_direct_link_commands(
    source: str,
    *,
    expected_links: int,
    expected_executables: int,
    expected_linker_mentions: int,
) -> None:
    if source.count("ld64.lld-18") != expected_linker_mentions:
        raise AssertionError("literal Mach-O linker ownership drifted")
    commands = direct_macho_link_commands(source)
    if len(commands) != expected_links:
        raise AssertionError(
            f"Mach-O link command count {len(commands)}, expected {expected_links}"
        )
    executables = 0
    for command in commands:
        is_dylib = " -dylib " in f" {command} "
        export_count = command.count(MACH_HEADER_EXPORT)
        if is_dylib:
            if export_count:
                raise AssertionError("Mach-O dylib exports __mh_execute_header")
            continue
        executables += 1
        if export_count != 1:
            raise AssertionError(
                "Mach-O executable __mh_execute_header export count "
                f"{export_count}, expected 1"
            )
    if executables != expected_executables:
        raise AssertionError(
            f"Mach-O executable link count {executables}, "
            f"expected {expected_executables}"
        )


def validate_application_link_command(source: str) -> None:
    if source.count("ld64.lld-18") != 2:
        raise AssertionError("generic application linker ownership drifted")
    commands = direct_macho_link_commands(source)
    if len(commands) != 1 or not commands[0].startswith(
        "link_command=(ld64.lld-18 "
    ):
        raise AssertionError("generic application link ownership drifted")
    link_start = source.index("    link_command=(ld64.lld-18 ")
    link_end = source.index("\n    local linked_app_object_count", link_start)
    link_block = source[link_start:link_end]
    if source.count(
        "local -a executable_export_arguments=("
        "-exported_symbol __mh_execute_header)"
    ) != 1:
        raise AssertionError("generic application Mach header export drifted")
    if link_block.count('"${executable_export_arguments[@]}"') != 1:
        raise AssertionError(
            "generic application link does not consume its exact export array"
        )
    if MACH_HEADER_EXPORT not in source:
        raise AssertionError("generic application Mach header export is absent")


class MachExecuteHeaderContractTests(unittest.TestCase):
    def test_true_ios_platform_executable_exports_the_flat_header(self) -> None:
        source = TRUE_IOS_BUILDER.read_text(encoding="utf-8")
        validate_direct_link_commands(
            source,
            expected_links=19,
            expected_executables=1,
            expected_linker_mentions=2,
        )
        with self.assertRaisesRegex(
            AssertionError, "__mh_execute_header export count"
        ):
            validate_direct_link_commands(
                source.replace(MACH_HEADER_EXPORT, "", 1),
                expected_links=19,
                expected_executables=1,
                expected_linker_mentions=2,
            )
        with self.assertRaisesRegex(
            AssertionError, "__mh_execute_header export count"
        ):
            validate_direct_link_commands(
                source.replace(
                    MACH_HEADER_EXPORT,
                    f"{MACH_HEADER_EXPORT} {MACH_HEADER_EXPORT}",
                    1,
                ),
                expected_links=19,
                expected_executables=1,
                expected_linker_mentions=2,
            )

    def test_generic_application_link_consumes_one_header_export(self) -> None:
        source = APPLICATION_DRIVER.read_text(encoding="utf-8")
        validate_application_link_command(source)
        for token in (
            "-exported_symbol __mh_execute_header",
            '"${executable_export_arguments[@]}"',
        ):
            with self.subTest(deleted=token):
                with self.assertRaisesRegex(
                    AssertionError, "application.*(header|export)"
                ):
                    validate_application_link_command(
                        source.replace(token, "", 1)
                    )

    def test_direct_helpers_cannot_hide_an_executable_link(self) -> None:
        foundation_intl = FOUNDATION_INTL_BUILDER.read_text(encoding="utf-8")
        validate_direct_link_commands(
            foundation_intl,
            expected_links=3,
            expected_executables=0,
            expected_linker_mentions=4,
        )
        for helper in NON_LINKING_HELPERS:
            with self.subTest(helper=helper.relative_to(ROOT)):
                source = helper.read_text(encoding="utf-8")
                self.assertNotIn("ld64.lld", source)
                self.assertEqual(direct_macho_link_commands(source), [])


if __name__ == "__main__":
    unittest.main()
