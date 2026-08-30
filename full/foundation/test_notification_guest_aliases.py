#!/usr/bin/env python3
"""Fail-closed static teeth for the guest notification identity boundary."""

from pathlib import Path
import re
import unittest


ROOT = Path(__file__).resolve().parents[2]
ALIASES = ROOT / "full/appshim/FoundationOpenUIKitAliases.swift"
FOUNDATION_PROBE = (
    ROOT / "full/foundation/notification_foundation_extension_probe.swift"
)
UIKIT_PROBE = ROOT / "full/foundation/notification_uikit_consumer_probe.swift"
DIRECT_PROBE = ROOT / "full/foundation/notification_direct_import_probe.swift"

EXPECTED_ALIASES = {
    "Notification": "OpenUIKit.Notification",
    "NSNotification": "OpenUIKit.NSNotification",
    "NotificationCenter": "OpenUIKit.NotificationCenter",
    "OperationQueue": "OpenUIKit.OperationQueue",
}


def parsed_aliases(source: str) -> dict[str, str]:
    return dict(
        re.findall(
            r"(?m)^public typealias ([A-Za-z_][A-Za-z0-9_]*) = "
            r"([A-Za-z_][A-Za-z0-9_.]*)$",
            source,
        )
    )


def validate_alias_source(source: str) -> None:
    aliases = parsed_aliases(source)
    for name, expected in EXPECTED_ALIASES.items():
        actual = aliases.get(name)
        if actual != expected:
            raise AssertionError(
                f"{name} alias expected {expected}, got {actual!r}"
            )
    if "public typealias NotificationToken" in source:
        raise AssertionError("Foundation must not publish NotificationToken")
    unexpected = set(aliases) - set(EXPECTED_ALIASES)
    if unexpected:
        raise AssertionError(f"unexpected Foundation aliases: {sorted(unexpected)!r}")
    if not re.search(
        r"#if canImport\(ObjectiveC\)\s+"
        r"(?:.*\n)*?public typealias NSNotification = "
        r"OpenUIKit\.NSNotification\s+#endif",
        source,
    ):
        raise AssertionError("NSNotification is not bounded to Objective-C guests")
    for declaration in (
        "struct Notification",
        "class Notification",
        "struct NotificationCenter",
        "class NotificationCenter",
        "struct OperationQueue",
        "class OperationQueue",
    ):
        if re.search(rf"(?m)^public (?:final |open )?{declaration}", source):
            raise AssertionError(f"lookalike implementation escaped: {declaration}")


def imports(source: str) -> list[str]:
    return re.findall(r"(?m)^import ([A-Za-z_][A-Za-z0-9_]*)$", source)


def logical_shell_lines(source: str) -> list[str]:
    return [
        line.strip()
        for line in re.sub(r"\\\n\s*", " ", source).splitlines()
        if line.strip() and not line.lstrip().startswith("#")
    ]


class NotificationGuestAliasTests(unittest.TestCase):
    def test_aliases_are_exact_and_do_not_invent_an_api(self) -> None:
        source = ALIASES.read_text()
        validate_alias_source(source)
        self.assertEqual(imports(source), ["OpenUIKit"])
        self.assertNotIn("@_exported import OpenUIKit", source)
        self.assertIn("not a claim that the complete Foundation.NSNotification", source)
        self.assertIn("Coding,", source)
        self.assertIn("interoperability with an Apple Foundation center", source)

    def test_alias_validator_has_per_identity_negative_teeth(self) -> None:
        source = ALIASES.read_text()
        for name, target in EXPECTED_ALIASES.items():
            with self.subTest(identity=name):
                tampered = source.replace(
                    f"public typealias {name} = {target}",
                    f"public typealias {name} = OpenUIKit.NSCoder",
                    1,
                )
                with self.assertRaisesRegex(
                    AssertionError, rf"^{name} alias expected"
                ):
                    validate_alias_source(tampered)

        token = source + "\npublic typealias NotificationToken = Swift.Int\n"
        with self.assertRaisesRegex(AssertionError, "NotificationToken"):
            validate_alias_source(token)

    def test_probe_files_preserve_file_scoped_import_topologies(self) -> None:
        foundation = FOUNDATION_PROBE.read_text()
        uikit = UIKIT_PROBE.read_text()
        direct = DIRECT_PROBE.read_text()
        self.assertEqual(imports(foundation), ["Foundation"])
        self.assertEqual(imports(uikit), ["UIKit"])
        self.assertEqual(imports(direct), ["Foundation", "UIKit"])
        self.assertIn("extension Notification.Name", foundation)
        self.assertIn(".guestReminderDidChange", uikit)
        self.assertNotRegex(uikit, r"(?m)^import (Foundation|OpenUIKit)$")

    def test_probe_has_a_named_assignment_for_every_identity(self) -> None:
        foundation = FOUNDATION_PROBE.read_text()
        uikit = UIKIT_PROBE.read_text()
        direct = DIRECT_PROBE.read_text()
        for name in (
            "Notification",
            "NotificationName",
            "NotificationCenter",
            "OperationQueue",
            "NSNotification",
        ):
            with self.subTest(identity=name):
                self.assertIn(f"foundation{name}Metatype", foundation)
                self.assertIn(f"foundation{name}Metatype", uikit)
        for spelling in (
            "Notification.Type",
            "Notification.Name.Type",
            "NotificationCenter.Type",
            "OperationQueue.Type",
            "NSNotification.Type",
        ):
            with self.subTest(spelling=spelling):
                self.assertIn(f"Foundation.{spelling}", direct)
                self.assertIn(f"UIKit.{spelling}", direct)

    def test_every_foundation_shim_invocation_includes_shared_aliases(self) -> None:
        expected = {
            "FoundationGuest.swift": {
                "full/swiftui/build_focus_onboarding_guest.sh"
            },
            "Foundation.swift": {
                "full/scripts/app_probe2.sh",
                "full/scripts/build_full.sh",
            },
        }
        observed: dict[str, set[str]] = {name: set() for name in expected}
        alias_token = "full/appshim/FoundationOpenUIKitAliases.swift"

        for script in sorted((ROOT / "full").rglob("*.sh")):
            relative = script.relative_to(ROOT).as_posix()
            for command in logical_shell_lines(script.read_text()):
                for input_name in expected:
                    token = f"full/appshim/{input_name}"
                    if token not in command:
                        continue
                    observed[input_name].add(relative)
                    self.assertIn(
                        alias_token,
                        command,
                        f"{relative} compiles {input_name} without shared aliases",
                    )

        self.assertEqual(observed, expected)

    def test_full_build_enforces_early_identity_probe_order(self) -> None:
        build = (ROOT / "full/scripts/build_full.sh").read_text()
        openuikit = build.index("-module-name OpenUIKit")
        uikit = build.index("-module-name UIKit", openuikit)
        foundation = build.index("-module-name Foundation", uikit)
        identity = build.index("-module-name NotificationGuestIdentityProbe", foundation)
        self.assertLess(openuikit, uikit)
        self.assertLess(uikit, foundation)
        self.assertLess(foundation, identity)
        for probe in (FOUNDATION_PROBE, UIKIT_PROBE, DIRECT_PROBE):
            self.assertEqual(build.count(probe.name), 1)

    def test_reusable_and_packaged_umbrellas_run_the_exact_probe(self) -> None:
        onboarding = (
            ROOT / "full/swiftui/build_focus_onboarding_guest.sh"
        ).read_text()
        package = (ROOT / "full/swiftui/build_focus_package_guest.sh").read_text()
        self.assertIn("-I \"$FULL/uikitinc\"", onboarding)
        self.assertIn(
            "-module-name FoundationGuestNotificationIdentityProbe", onboarding
        )
        self.assertIn(
            "-module-name FocusPackageNotificationIdentityProbe", package
        )
        self.assertLess(
            package.index(
                'bash "$W/full/swiftui/build_focus_onboarding_guest.sh"'
            ),
            package.index("-module-name UIKit"),
        )
        self.assertIn("final app-facing UIKit after Foundation facade", package)
        self.assertIn("not the final app-facing", onboarding)
        for probe in (FOUNDATION_PROBE, UIKIT_PROBE, DIRECT_PROBE):
            self.assertEqual(onboarding.count(probe.name), 1)
            self.assertEqual(package.count(probe.name), 1)

    def test_legacy_diagnostic_keeps_early_uikit_before_foundation(self) -> None:
        script = (ROOT / "full/scripts/app_probe2.sh").read_text()
        self.assertLess(
            script.index("-module-name UIKit"),
            script.index("-module-name Foundation"),
        )


if __name__ == "__main__":
    unittest.main()
