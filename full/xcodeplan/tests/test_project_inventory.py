from __future__ import annotations

import os
import shutil
import subprocess
import sys
import tempfile
import unittest
from pathlib import Path


HERE = Path(__file__).resolve().parent
TOOL_DIR = HERE.parent
sys.path.insert(0, os.fspath(TOOL_DIR))

import project_inventory  # noqa: E402


FIXTURES = HERE / "fixtures"
MODERN_FIXTURE = FIXTURES / "modern_sync"
MODERN_PROJECT = MODERN_FIXTURE / "ModernSync.xcodeproj"
MODERN_SCHEME = (
    MODERN_PROJECT
    / "xcshareddata"
    / "xcschemes"
    / "ModernApp.xcscheme"
)
MINI_FIXTURE = FIXTURES / "mini"
MINI_PROJECT = MINI_FIXTURE / "Blockzilla.xcodeproj"


class ProjectInventoryFixtureTests(unittest.TestCase):
    def inventory(self, project: Path = MODERN_PROJECT, **kwargs):
        return project_inventory.build_project_inventory(
            project,
            scheme_name="ModernApp",
            **kwargs,
        )

    def copied_modern_fixture(self, directory: str) -> tuple[Path, Path]:
        root = Path(directory) / "modern_sync"
        shutil.copytree(MODERN_FIXTURE, root)
        return root, root / "ModernSync.xcodeproj"

    def add_selected_build_setting(
        self,
        project: Path,
        owner: str,
        key: str,
        encoded_value: str,
    ) -> None:
        pbxproj = project / "project.pbxproj"
        contents = pbxproj.read_text(encoding="utf-8")
        escaped_key = (
            key.replace("\\", "\\\\")
            .replace('"', '\\"')
            .replace("\n", "\\n")
            .replace("\r", "\\r")
            .replace("\t", "\\t")
        )
        encoded_key = (
            f'"{escaped_key}"'
            if (
                "[" in key
                or key.strip() != key
                or any(character.isspace() for character in key)
            )
            else key
        )
        if owner == "target":
            marker = '\t\t\t\tPRODUCT_NAME = "$(TARGET_NAME)";'
            replacement = marker + f"\n\t\t\t\t{encoded_key} = {encoded_value};"
        elif owner == "project":
            marker = "SWIFT_VERSION = 5.0;"
            replacement = f"{encoded_key} = {encoded_value}; {marker}"
        else:
            self.fail(f"unknown settings owner {owner!r}")
        self.assertIn(marker, contents)
        pbxproj.write_text(contents.replace(marker, replacement, 1), encoding="utf-8")

    def test_shared_scheme_selects_exact_runnable_target(self) -> None:
        with self.assertRaisesRegex(
            project_inventory.PlanError,
            "native target must resolve exactly once",
        ):
            project_inventory.build_project_inventory(MODERN_PROJECT)

        inventory = self.inventory()
        self.assertEqual(
            inventory["scheme"],
            {
                "name": "ModernApp",
                "path": (
                    "ModernSync.xcodeproj/xcshareddata/xcschemes/"
                    "ModernApp.xcscheme"
                ),
                "configuration": "Debug",
                "target_id": "AAAAAAAAAAAAAAAAAAAAAAAA",
                "target_name": "ModernApp",
                "buildable_name": "ModernApp.app",
                "referenced_container": "container:ModernSync.xcodeproj",
            },
        )
        self.assertEqual(inventory["target"]["name"], "ModernApp")
        self.assertEqual(inventory["configuration"]["name"], "Debug")
        self.assertEqual(inventory["configuration"]["project"]["name"], "Debug")
        self.assertEqual(inventory["configuration"]["target"]["name"], "Debug")

        with self.assertRaisesRegex(
            project_inventory.PlanError,
            "--target does not match the scheme runnable target",
        ):
            project_inventory.build_project_inventory(
                MODERN_PROJECT,
                scheme_name="ModernApp",
                target_selector="Helper",
            )

    def test_explicit_empty_selectors_never_downgrade_to_defaults(self) -> None:
        cases = (
            ({"scheme_name": ""}, "--scheme selector must not be empty"),
            ({"target_selector": ""}, "--target selector must not be empty"),
            (
                {"target_selector": "ModernApp", "configuration_name": ""},
                "--configuration selector must not be empty",
            ),
            (
                {"scheme_name": "ModernApp", "configuration_name": ""},
                "--configuration selector must not be empty",
            ),
        )
        for arguments, diagnostic in cases:
            with self.subTest(arguments=arguments), self.assertRaisesRegex(
                project_inventory.PlanError, diagnostic
            ):
                project_inventory.build_project_inventory(MODERN_PROJECT, **arguments)

    def test_cli_rejects_explicit_empty_selectors(self) -> None:
        tool = TOOL_DIR / "project_inventory.py"
        cases = (
            ("--scheme", "", "--scheme selector must not be empty"),
            ("--target", "", "--target selector must not be empty"),
            ("--configuration", "", "--configuration selector must not be empty"),
        )
        for option, value, diagnostic in cases:
            with self.subTest(option=option):
                command = [sys.executable, os.fspath(tool), os.fspath(MODERN_PROJECT)]
                if option == "--configuration":
                    command.extend(("--target", "ModernApp"))
                command.extend((option, value))
                process = subprocess.run(
                    command,
                    check=False,
                    stdout=subprocess.PIPE,
                    stderr=subprocess.PIPE,
                )
                self.assertEqual(process.returncode, 2)
                self.assertEqual(process.stdout, b"")
                self.assertIn(diagnostic.encode("utf-8"), process.stderr)

    def test_present_empty_default_configuration_does_not_use_single_fallback(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            _, project = self.copied_modern_fixture(directory)
            pbxproj = project / "project.pbxproj"
            contents = pbxproj.read_text(encoding="utf-8")
            marker = "\t\t\tdefaultConfigurationName = Debug;"
            self.assertIn(marker, contents)
            pbxproj.write_text(
                contents.replace(marker, '\t\t\tdefaultConfigurationName = "";', 1),
                encoding="utf-8",
            )
            with self.assertRaisesRegex(
                project_inventory.PlanError, "target.defaultConfigurationName is empty"
            ):
                project_inventory.build_project_inventory(
                    project,
                    target_selector="Helper",
                )

    def test_scheme_buildable_name_matches_selected_target_product(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            root, project = self.copied_modern_fixture(directory)
            scheme = (
                project
                / "xcshareddata"
                / "xcschemes"
                / "ModernApp.xcscheme"
            )
            scheme.write_text(
                scheme.read_text(encoding="utf-8").replace(
                    'BuildableName="ModernApp.app"',
                    'BuildableName="Wrong.app"',
                ),
                encoding="utf-8",
            )
            with self.assertRaisesRegex(
                project_inventory.PlanError, "scheme.*buildable.*product"
            ):
                project_inventory.build_project_inventory(
                    project,
                    scheme_name="ModernApp",
                )

    def test_scheme_selector_identity_must_be_a_canonical_basename(self) -> None:
        for selector, filename in ((".", "..xcscheme"), ("..", "...xcscheme")):
            with self.subTest(selector=selector), tempfile.TemporaryDirectory() as directory:
                _, project = self.copied_modern_fixture(directory)
                schemes = project / "xcshareddata" / "xcschemes"
                shutil.copyfile(schemes / "ModernApp.xcscheme", schemes / filename)
                with self.assertRaisesRegex(
                    project_inventory.PlanError,
                    "scheme selector identity must be a canonical basename",
                ):
                    project_inventory.build_project_inventory(
                        project,
                        scheme_name=selector,
                    )

        hostile_stems = (
            "Bad\\Name",
            "C:Bad",
            "$BAD",
            "Bad\nName",
            "Bad\u202eName",
        )
        for stem in hostile_stems:
            with self.subTest(stem=stem), tempfile.TemporaryDirectory() as directory:
                _, project = self.copied_modern_fixture(directory)
                schemes = project / "xcshareddata" / "xcschemes"
                hostile = schemes / f"{stem}.xcscheme"
                shutil.copyfile(schemes / "ModernApp.xcscheme", hostile)
                with self.assertRaisesRegex(
                    project_inventory.PlanError,
                    "scheme selector identity must be a canonical basename",
                ):
                    project_inventory.build_project_inventory(
                        project,
                        scheme_name=os.fspath(hostile),
                    )

    def test_explicit_scheme_path_requires_xcscheme_extension(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            _, project = self.copied_modern_fixture(directory)
            scheme = project / "xcshareddata" / "xcschemes" / "ModernApp.xcscheme"
            wrong_extension = scheme.with_name("ModernApp.xml")
            shutil.copyfile(scheme, wrong_extension)
            with self.assertRaisesRegex(
                project_inventory.PlanError,
                "explicit shared scheme path must end in '.xcscheme'",
            ):
                project_inventory.build_project_inventory(
                    project,
                    scheme_name=os.fspath(wrong_extension),
                )

    def test_scheme_dtd_and_entities_are_rejected_after_xml_decoding(self) -> None:
        encodings = (("utf-8", "UTF-8"), ("utf-16", "UTF-16"))
        for codec, declaration in encodings:
            with self.subTest(codec=codec), tempfile.TemporaryDirectory() as directory:
                _, project = self.copied_modern_fixture(directory)
                scheme = project / "xcshareddata" / "xcschemes" / "ModernApp.xcscheme"
                contents = scheme.read_text(encoding="utf-8")
                contents = contents.replace("UTF-8", declaration, 1).replace(
                    '<Scheme version="1.7">',
                    '<!DOCTYPE Scheme [<!ENTITY app "ModernApp">]>\n'
                    '<Scheme version="1.7">',
                    1,
                )
                scheme.write_bytes(contents.encode(codec))
                with self.assertRaisesRegex(
                    project_inventory.PlanError,
                    "forbidden DTD/entity declaration",
                ):
                    project_inventory.build_project_inventory(
                        project,
                        scheme_name="ModernApp",
                    )

    def test_scheme_buildable_name_must_be_a_canonical_basename(self) -> None:
        unsafe_names = (
            "../ModernApp.app",
            "Modern/App.app",
            "Modern\\App.app",
            "C:ModernApp.app",
            "$(PRODUCT_NAME).app",
            "Modern&#10;App.app",
            "Modern\u202eApp.app",
        )
        for unsafe_name in unsafe_names:
            with self.subTest(name=unsafe_name), tempfile.TemporaryDirectory() as directory:
                _, project = self.copied_modern_fixture(directory)
                scheme = (
                    project
                    / "xcshareddata"
                    / "xcschemes"
                    / "ModernApp.xcscheme"
                )
                contents = scheme.read_text(encoding="utf-8")
                self.assertEqual(contents.count('BuildableName="ModernApp.app"'), 2)
                scheme.write_text(
                    contents.replace(
                        'BuildableName="ModernApp.app"',
                        f'BuildableName="{unsafe_name}"',
                    ),
                    encoding="utf-8",
                )
                with self.assertRaisesRegex(
                    project_inventory.PlanError,
                    "BuildableName must be a canonical basename",
                ):
                    project_inventory.build_project_inventory(
                        project,
                        scheme_name="ModernApp",
                    )

    def test_selected_target_product_must_come_from_built_products(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            _, project = self.copied_modern_fixture(directory)
            pbxproj = project / "project.pbxproj"
            contents = pbxproj.read_text(encoding="utf-8")
            marker = "\t\t\tpath = ModernApp.app;\n\t\t\tsourceTree = BUILT_PRODUCTS_DIR;"
            self.assertIn(marker, contents)
            pbxproj.write_text(
                contents.replace(
                    marker,
                    "\t\t\tpath = ModernApp.app;\n\t\t\tsourceTree = \"<group>\";",
                    1,
                ),
                encoding="utf-8",
            )
            with self.assertRaisesRegex(
                project_inventory.PlanError,
                "product reference must use BUILT_PRODUCTS_DIR",
            ):
                project_inventory.build_project_inventory(
                    project,
                    scheme_name="ModernApp",
                )

    def test_external_product_path_is_canonical_and_beneath_built_products(self) -> None:
        unsafe_paths = (
            "/private/tmp/ModernApp.app",
            "../ModernApp.app",
            "Products/../../ModernApp.app",
            "Products/../ModernApp.app",
            "./ModernApp.app",
            '"Products//ModernApp.app"',
            '"..\\\\ModernApp.app"',
            '"C:/ModernApp.app"',
            '"$(TARGET_BUILD_DIR)/ModernApp.app"',
            '"Modern\\nApp.app"',
            '"Modern\\U202eApp.app"',
        )
        for unsafe_path in unsafe_paths:
            with self.subTest(path=unsafe_path), tempfile.TemporaryDirectory() as directory:
                _, project = self.copied_modern_fixture(directory)
                pbxproj = project / "project.pbxproj"
                contents = pbxproj.read_text(encoding="utf-8")
                marker = "\t\t\tpath = ModernApp.app;"
                self.assertIn(marker, contents)
                pbxproj.write_text(
                    contents.replace(marker, f"\t\t\tpath = {unsafe_path};", 1),
                    encoding="utf-8",
                )
                with self.assertRaisesRegex(
                    project_inventory.PlanError,
                    "unsafe.*path rooted at BUILT_PRODUCTS_DIR|"
                    "control/format character.*BUILT_PRODUCTS_DIR|"
                    "unresolved variable.*BUILT_PRODUCTS_DIR",
                ):
                    project_inventory.build_project_inventory(
                        project,
                        scheme_name="ModernApp",
                    )

        with tempfile.TemporaryDirectory() as directory:
            _, project = self.copied_modern_fixture(directory)
            pbxproj = project / "project.pbxproj"
            contents = pbxproj.read_text(encoding="utf-8")
            marker = "\t\t\tpath = ModernApp.app;"
            self.assertIn(marker, contents)
            pbxproj.write_text(
                contents.replace(
                    marker,
                    "\t\t\tpath = Products/ModernApp.app;",
                    1,
                ),
                encoding="utf-8",
            )
            inventory = project_inventory.build_project_inventory(
                project,
                scheme_name="ModernApp",
            )
            self.assertEqual(
                inventory["target"]["product"]["path"],
                "Products/ModernApp.app",
            )

        with tempfile.TemporaryDirectory() as directory:
            _, project = self.copied_modern_fixture(directory)
            pbxproj = project / "project.pbxproj"
            contents = pbxproj.read_text(encoding="utf-8")
            marker = "\t\t\tpath = ModernApp.app;"
            self.assertIn(marker, contents)
            pbxproj.write_text(
                contents.replace(
                    marker,
                    '\t\t\tpath = "Products;touch PWN/ModernApp.app";',
                    1,
                ),
                encoding="utf-8",
            )
            with self.assertRaisesRegex(
                project_inventory.PlanError,
                "product-reference directory component.*safe artifact grammar",
            ):
                project_inventory.build_project_inventory(
                    project,
                    target_selector="ModernApp",
                    configuration_name="Debug",
                )

    def test_all_external_tree_phase_inputs_use_the_same_safe_path_boundary(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory) / "mini"
            shutil.copytree(MINI_FIXTURE, root)
            project = root / "Blockzilla.xcodeproj"
            pbxproj = project / "project.pbxproj"
            contents = pbxproj.read_text(encoding="utf-8")
            marker = "\t\t\tpath = Extension.appex;"
            self.assertIn(marker, contents)
            pbxproj.write_text(
                contents.replace(marker, "\t\t\tpath = ../Extension.appex;", 1),
                encoding="utf-8",
            )
            with self.assertRaisesRegex(
                project_inventory.PlanError,
                "unsafe.*path rooted at BUILT_PRODUCTS_DIR",
            ):
                project_inventory.build_project_inventory(
                    project,
                    scheme_name="Focus",
                )

        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory) / "mini"
            shutil.copytree(MINI_FIXTURE, root)
            project = root / "Blockzilla.xcodeproj"
            pbxproj = project / "project.pbxproj"
            contents = pbxproj.read_text(encoding="utf-8")
            object_marker = "\t\t100000000000000000000001 = {"
            build_marker = "\t\t200000000000000000000001 = {"
            phase_marker = "\t\t\tfiles = (200000000000000000000004, );"
            for marker in (object_marker, build_marker, phase_marker):
                self.assertIn(marker, contents)
            contents = contents.replace(
                object_marker,
                "\t\t100000000000000000000008 = {\n"
                "\t\t\texplicitFileType = wrapper.framework;\n"
                "\t\t\tisa = PBXFileReference;\n"
                "\t\t\tpath = ../System/Library/Frameworks/Unsafe.framework;\n"
                "\t\t\tsourceTree = SDKROOT;\n"
                "\t\t};\n"
                + object_marker,
                1,
            ).replace(
                build_marker,
                "\t\t200000000000000000000007 = {isa = PBXBuildFile; "
                "fileRef = 100000000000000000000008; };\n"
                + build_marker,
                1,
            ).replace(
                phase_marker,
                "\t\t\tfiles = (\n"
                "\t\t\t\t200000000000000000000004,\n"
                "\t\t\t\t200000000000000000000007,\n"
                "\t\t\t);",
                1,
            )
            pbxproj.write_text(contents, encoding="utf-8")
            with self.assertRaisesRegex(
                project_inventory.PlanError,
                "unsafe.*path rooted at SDKROOT",
            ):
                project_inventory.build_project_inventory(
                    project,
                    scheme_name="Focus",
                )

    def test_selected_target_product_type_matches_application_role(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            _, project = self.copied_modern_fixture(directory)
            pbxproj = project / "project.pbxproj"
            contents = pbxproj.read_text(encoding="utf-8")
            marker = "\t\t\texplicitFileType = wrapper.application;"
            self.assertIn(marker, contents)
            pbxproj.write_text(
                contents.replace(
                    marker,
                    "\t\t\texplicitFileType = wrapper.framework;",
                    1,
                ),
                encoding="utf-8",
            )
            with self.assertRaisesRegex(
                project_inventory.PlanError,
                "product reference type must be 'wrapper.application'",
            ):
                project_inventory.build_project_inventory(
                    project,
                    scheme_name="ModernApp",
                )

    def test_exact_product_reference_rejects_unresolved_product_name(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            _, project = self.copied_modern_fixture(directory)
            pbxproj = project / "project.pbxproj"
            contents = pbxproj.read_text(encoding="utf-8")
            marker = '\t\t\t\tPRODUCT_NAME = "$(TARGET_NAME)";'
            self.assertIn(marker, contents)
            pbxproj.write_text(
                contents.replace(
                    marker,
                    '\t\t\t\tPRODUCT_NAME = "$(inherited)";',
                    1,
                ),
                encoding="utf-8",
            )
            with self.assertRaisesRegex(
                project_inventory.PlanError,
                "unresolved PRODUCT_NAME variable 'inherited'",
            ):
                project_inventory.build_project_inventory(
                    project,
                    scheme_name="ModernApp",
                )

    def test_missing_product_name_fails_closed_in_every_selection_mode(self) -> None:
        modes = (
            {"scheme_name": "ModernApp"},
            {"target_selector": "ModernApp", "configuration_name": "Debug"},
        )
        for arguments in modes:
            with self.subTest(arguments=arguments), tempfile.TemporaryDirectory() as directory:
                _, project = self.copied_modern_fixture(directory)
                pbxproj = project / "project.pbxproj"
                contents = pbxproj.read_text(encoding="utf-8")
                marker = '\t\t\t\tPRODUCT_NAME = "$(TARGET_NAME)";\n'
                self.assertIn(marker, contents)
                pbxproj.write_text(contents.replace(marker, "", 1), encoding="utf-8")
                with self.assertRaisesRegex(
                    project_inventory.PlanError,
                    "without an explicit PRODUCT_NAME",
                ):
                    project_inventory.build_project_inventory(project, **arguments)

    def test_coordinated_alias_cannot_replace_missing_native_product_name(self) -> None:
        modes = (
            {"scheme_name": "ModernApp"},
            {"target_selector": "ModernApp", "configuration_name": "Debug"},
        )
        for arguments in modes:
            with self.subTest(arguments=arguments), tempfile.TemporaryDirectory() as directory:
                _, project = self.copied_modern_fixture(directory)
                pbxproj = project / "project.pbxproj"
                contents = pbxproj.read_text(encoding="utf-8")
                product_name = '\t\t\t\tPRODUCT_NAME = "$(TARGET_NAME)";\n'
                product_path = "\t\t\tpath = ModernApp.app;"
                self.assertIn(product_name, contents)
                self.assertIn(product_path, contents)
                pbxproj.write_text(
                    contents.replace(product_name, "", 1).replace(
                        product_path, "\t\t\tpath = Alias.app;", 1
                    ),
                    encoding="utf-8",
                )
                scheme = project / "xcshareddata" / "xcschemes" / "ModernApp.xcscheme"
                scheme.write_text(
                    scheme.read_text(encoding="utf-8").replace(
                        'BuildableName="ModernApp.app"',
                        'BuildableName="Alias.app"',
                    ),
                    encoding="utf-8",
                )
                with self.assertRaisesRegex(
                    project_inventory.PlanError,
                    "without an explicit PRODUCT_NAME",
                ):
                    project_inventory.build_project_inventory(project, **arguments)

    def test_unsafe_product_name_is_rejected_when_exact_output_matches(self) -> None:
        unsafe_settings = (
            '"../ModernApp"',
            '"Modern/App"',
            '"Modern\\\\App"',
            '"C:/ModernApp"',
            '"$(UNRESOLVED)"',
            '"Modern\\nApp"',
            '"Modern\\U202eApp"',
        )
        marker = '\t\t\t\tPRODUCT_NAME = "$(TARGET_NAME)";'
        for unsafe_setting in unsafe_settings:
            with self.subTest(setting=unsafe_setting), tempfile.TemporaryDirectory() as directory:
                _, project = self.copied_modern_fixture(directory)
                pbxproj = project / "project.pbxproj"
                contents = pbxproj.read_text(encoding="utf-8")
                self.assertIn(marker, contents)
                pbxproj.write_text(
                    contents.replace(
                        marker,
                        f"\t\t\t\tPRODUCT_NAME = {unsafe_setting};",
                        1,
                    ),
                    encoding="utf-8",
                )
                with self.assertRaisesRegex(
                    project_inventory.PlanError,
                    "effective PRODUCT_NAME must be a canonical basename|"
                    "unresolved PRODUCT_NAME variable 'UNRESOLVED'",
                ):
                    project_inventory.build_project_inventory(
                        project,
                        scheme_name="ModernApp",
                    )

    def test_unsafe_product_name_is_rejected_when_product_reference_differs(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            _, project = self.copied_modern_fixture(directory)
            pbxproj = project / "project.pbxproj"
            contents = pbxproj.read_text(encoding="utf-8")
            self.assertIn("\t\t\tpath = ModernApp.app;", contents)
            self.assertIn('\t\t\t\tPRODUCT_NAME = "$(TARGET_NAME)";', contents)
            contents = contents.replace(
                "\t\t\tpath = ModernApp.app;",
                "\t\t\tpath = Alias.app;",
                1,
            ).replace(
                '\t\t\t\tPRODUCT_NAME = "$(TARGET_NAME)";',
                '\t\t\t\tPRODUCT_NAME = "Modern/App";',
                1,
            )
            pbxproj.write_text(contents, encoding="utf-8")
            with self.assertRaisesRegex(
                project_inventory.PlanError,
                "effective PRODUCT_NAME must be a canonical basename",
            ):
                project_inventory.build_project_inventory(
                    project,
                    scheme_name="ModernApp",
                )

    def test_coordinated_unsafe_buildable_and_product_name_are_rejected(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            _, project = self.copied_modern_fixture(directory)
            pbxproj = project / "project.pbxproj"
            contents = pbxproj.read_text(encoding="utf-8")
            contents = contents.replace(
                "\t\t\tpath = ModernApp.app;",
                "\t\t\tpath = Alias.app;",
                1,
            ).replace(
                '\t\t\t\tPRODUCT_NAME = "$(TARGET_NAME)";',
                '\t\t\t\tPRODUCT_NAME = "../ModernApp";',
                1,
            )
            pbxproj.write_text(contents, encoding="utf-8")
            scheme = (
                project
                / "xcshareddata"
                / "xcschemes"
                / "ModernApp.xcscheme"
            )
            scheme.write_text(
                scheme.read_text(encoding="utf-8").replace(
                    'BuildableName="ModernApp.app"',
                    'BuildableName="../ModernApp.app"',
                ),
                encoding="utf-8",
            )
            with self.assertRaisesRegex(
                project_inventory.PlanError,
                "BuildableName must be a canonical basename",
            ):
                project_inventory.build_project_inventory(
                    project,
                    scheme_name="ModernApp",
                )

    def test_valid_product_name_alias_matches_scheme_basename(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            _, project = self.copied_modern_fixture(directory)
            pbxproj = project / "project.pbxproj"
            contents = pbxproj.read_text(encoding="utf-8")
            contents = contents.replace(
                "\t\t\tpath = ModernApp.app;",
                "\t\t\tpath = Alias.app;",
                1,
            ).replace(
                '\t\t\t\tPRODUCT_NAME = "$(TARGET_NAME)";',
                "\t\t\t\tPRODUCT_NAME = ModernApp;",
                1,
            )
            pbxproj.write_text(contents, encoding="utf-8")
            inventory = project_inventory.build_project_inventory(
                project,
                scheme_name="ModernApp",
            )
            self.assertEqual(inventory["target"]["product"]["path"], "Alias.app")
            self.assertEqual(inventory["scheme"]["buildable_name"], "ModernApp.app")

    def test_product_display_name_cannot_prove_scheme_identity(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            _, project = self.copied_modern_fixture(directory)
            pbxproj = project / "project.pbxproj"
            contents = pbxproj.read_text(encoding="utf-8")
            marker = "\t\t\tpath = ModernApp.app;\n\t\t\tsourceTree = BUILT_PRODUCTS_DIR;"
            self.assertIn(marker, contents)
            pbxproj.write_text(
                contents.replace(
                    marker,
                    "\t\t\tname = Alias.app;\n" + marker,
                    1,
                ),
                encoding="utf-8",
            )
            scheme = (
                project
                / "xcshareddata"
                / "xcschemes"
                / "ModernApp.xcscheme"
            )
            scheme.write_text(
                scheme.read_text(encoding="utf-8").replace(
                    'BuildableName="ModernApp.app"',
                    'BuildableName="Alias.app"',
                ),
                encoding="utf-8",
            )
            with self.assertRaisesRegex(
                project_inventory.PlanError, "scheme.*buildable.*product"
            ):
                project_inventory.build_project_inventory(
                    project,
                    scheme_name="ModernApp",
                )

    def test_product_output_path_does_not_hide_inherited_name_with_display_name(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            _, project = self.copied_modern_fixture(directory)
            pbxproj = project / "project.pbxproj"
            contents = pbxproj.read_text(encoding="utf-8")
            product_marker = (
                "\t\t\tpath = ModernApp.app;\n\t\t\tsourceTree = BUILT_PRODUCTS_DIR;"
            )
            setting_marker = '\t\t\t\tPRODUCT_NAME = "$(TARGET_NAME)";'
            self.assertIn(product_marker, contents)
            self.assertIn(setting_marker, contents)
            contents = contents.replace(
                product_marker,
                "\t\t\tname = Alias.app;\n" + product_marker,
                1,
            ).replace(
                setting_marker,
                '\t\t\t\tPRODUCT_NAME = "$(inherited)";',
                1,
            )
            pbxproj.write_text(contents, encoding="utf-8")
            with self.assertRaisesRegex(
                project_inventory.PlanError,
                "unresolved PRODUCT_NAME variable 'inherited'",
            ):
                project_inventory.build_project_inventory(
                    project,
                    scheme_name="ModernApp",
                )

    def test_target_only_mode_validates_effective_product_name(self) -> None:
        marker = '\t\t\t\tPRODUCT_NAME = "$(TARGET_NAME)";'
        hostile = (
            '"../Escape"',
            '"$(UNRESOLVED)"',
            '"ModernApp;touch PWN"',
            '"Cafe\\U0301"',
        )
        for setting in hostile:
            with self.subTest(setting=setting), tempfile.TemporaryDirectory() as directory:
                _, project = self.copied_modern_fixture(directory)
                pbxproj = project / "project.pbxproj"
                contents = pbxproj.read_text(encoding="utf-8")
                self.assertIn(marker, contents)
                pbxproj.write_text(
                    contents.replace(
                        marker,
                        f"\t\t\t\tPRODUCT_NAME = {setting};",
                        1,
                    ),
                    encoding="utf-8",
                )
                with self.assertRaisesRegex(
                    project_inventory.PlanError,
                    "PRODUCT_NAME|safe artifact grammar|NFC-normalized",
                ):
                    project_inventory.build_project_inventory(
                        project,
                        target_selector="ModernApp",
                        configuration_name="Debug",
                    )

    def test_conditional_product_name_settings_fail_closed(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            _, project = self.copied_modern_fixture(directory)
            pbxproj = project / "project.pbxproj"
            contents = pbxproj.read_text(encoding="utf-8")
            marker = '\t\t\t\tPRODUCT_NAME = "$(TARGET_NAME)";'
            self.assertIn(marker, contents)
            pbxproj.write_text(
                contents.replace(
                    marker,
                    marker
                    + '\n\t\t\t\t"PRODUCT_NAME[sdk=iphoneos*]" = Conditional;',
                    1,
                ),
                encoding="utf-8",
            )
            with self.assertRaisesRegex(
                project_inventory.PlanError,
                "conditional build settings.*PRODUCT_NAME",
            ):
                project_inventory.build_project_inventory(
                    project,
                    target_selector="ModernApp",
                    configuration_name="Debug",
                )

    def test_native_product_identity_overrides_are_checked_in_every_mode_and_scope(self) -> None:
        hostile = {
            "WRAPPER_EXTENSION": "evil",
            "WRAPPER_PREFIX": "Evil-",
            "WRAPPER_NAME": "Hijacked.app",
            "FULL_PRODUCT_NAME": "Hijacked.app",
            "EXECUTABLE_NAME": "Hijacked",
            "EXECUTABLE_VARIANT_SUFFIX": "-variant",
            "MACH_O_TYPE": "mh_dylib",
            "SKIP_INSTALL": "YES",
        }
        modes = (
            {"scheme_name": "ModernApp"},
            {"target_selector": "ModernApp", "configuration_name": "Debug"},
        )
        for owner in ("project", "target"):
            for key, value in hostile.items():
                for arguments in modes:
                    with (
                        self.subTest(owner=owner, key=key, arguments=arguments),
                        tempfile.TemporaryDirectory() as directory,
                    ):
                        _, project = self.copied_modern_fixture(directory)
                        self.add_selected_build_setting(project, owner, key, value)
                        with self.assertRaisesRegex(
                            project_inventory.PlanError,
                            rf"{owner} build setting {key} must be the canonical literal",
                        ):
                            project_inventory.build_project_inventory(
                                project, **arguments
                            )

    def test_canonical_native_product_identity_literals_are_supported(self) -> None:
        canonical = {
            "DEPLOYMENT_LOCATION": "NO",
            "EXECUTABLE_EXTENSION": '""',
            "EXECUTABLE_NAME": "ModernApp",
            "EXECUTABLE_PREFIX": '""',
            "EXECUTABLE_SUFFIX": '""',
            "EXECUTABLE_VARIANT_SUFFIX": '""',
            "FULL_PRODUCT_NAME": "ModernApp.app",
            "MACH_O_TYPE": "mh_execute",
            "PRODUCT_BUNDLE_PACKAGE_TYPE": "APPL",
            "PRODUCT_TYPE": '"com.apple.product-type.application"',
            "PRODUCT_TYPE_IDENTIFIER": '"com.apple.product-type.application"',
            "PROJECT": "ModernSync",
            "PROJECT_NAME": "ModernSync",
            "SKIP_INSTALL": "NO",
            "TARGET_NAME": "ModernApp",
            "WRAPPER_EXTENSION": "app",
            "WRAPPER_NAME": "ModernApp.app",
            "WRAPPER_PREFIX": '""',
            "WRAPPER_SUFFIX": ".app",
        }
        for owner in ("project", "target"):
            with self.subTest(owner=owner), tempfile.TemporaryDirectory() as directory:
                _, project = self.copied_modern_fixture(directory)
                for key, value in canonical.items():
                    self.add_selected_build_setting(project, owner, key, value)
                scheme_inventory = project_inventory.build_project_inventory(
                    project, scheme_name="ModernApp"
                )
                target_inventory = project_inventory.build_project_inventory(
                    project,
                    target_selector="ModernApp",
                    configuration_name="Debug",
                )
                self.assertEqual(
                    scheme_inventory["target"]["buildable_name"], "ModernApp.app"
                )
                self.assertEqual(
                    target_inventory["target"]["buildable_name"], "ModernApp.app"
                )

    def test_empty_unresolved_and_conditional_identity_settings_fail_closed(self) -> None:
        cases = (
            ("WRAPPER_EXTENSION", '""'),
            ("WRAPPER_NAME", '"$(PRODUCT_NAME).app"'),
            ("FULL_PRODUCT_NAME", '"$(WRAPPER_NAME)"'),
            ("EXECUTABLE_NAME", '"$(PRODUCT_NAME)"'),
            ("EXECUTABLE_PREFIX", '"$(inherited)"'),
            ("EXECUTABLE_SUFFIX", '".bin"'),
            ("EXECUTABLE_VARIANT_SUFFIX", '"-variant"'),
            ("MACH_O_TYPE", '""'),
            ("SKIP_INSTALL", '""'),
        )
        for key, value in cases:
            with self.subTest(key=key), tempfile.TemporaryDirectory() as directory:
                _, project = self.copied_modern_fixture(directory)
                self.add_selected_build_setting(project, "target", key, value)
                with self.assertRaisesRegex(
                    project_inventory.PlanError, rf"target build setting {key}"
                ):
                    project_inventory.build_project_inventory(
                        project, scheme_name="ModernApp"
                    )

        conditional_keys = (
            "WRAPPER_EXTENSION",
            "WRAPPER_NAME",
            "FULL_PRODUCT_NAME",
            "EXECUTABLE_NAME",
            "MACH_O_TYPE",
            "SKIP_INSTALL",
            "PRODUCT_BUNDLE_IDENTIFIER",
            "CONTENTS_FOLDER_PATH",
        )
        for key in conditional_keys:
            with self.subTest(conditional=key), tempfile.TemporaryDirectory() as directory:
                _, project = self.copied_modern_fixture(directory)
                self.add_selected_build_setting(
                    project,
                    "target",
                    f"{key}[sdk=iphoneos*]",
                    "Conditional",
                )
                with self.assertRaisesRegex(
                    project_inventory.PlanError,
                    rf"conditional build settings.*{key}",
                ):
                    project_inventory.build_project_inventory(
                        project,
                        target_selector="ModernApp",
                        configuration_name="Debug",
                    )

    def test_xcode_whitespace_aliases_cannot_hide_identity_setting_keys(self) -> None:
        conditional_keys = (
            "PRODUCT_NAME [sdk=macosx*]",
            "PRODUCT_NAME   [sdk=macosx*]",
            "PRODUCT_NAME\t[sdk=macosx*]",
            "PRODUCT_NAME \t[sdk=macosx*]",
            "PRODUCT_NAME\n[sdk=macosx*]",
            "WRAPPER_NAME [sdk=macosx*]",
            "SHALLOW_BUNDLE_macos [sdk=macosx*]",
        )
        direct_aliases = (
            "PRODUCT_NAME ",
            "PRODUCT_NAME\t",
            "PRODUCT_NAME\r",
            "PRODUCT_NAME\n",
            "PRODUCT_NAME\u00a0",
            "PRODUCT_NAME\u2003",
            " PRODUCT_NAME",
            "WRAPPER_NAME ",
            "SHALLOW_BUNDLE_macos ",
        )
        modes = (
            {"scheme_name": "ModernApp"},
            {"target_selector": "ModernApp", "configuration_name": "Debug"},
        )
        for owner in ("project", "target"):
            for key in conditional_keys:
                value = "Hijacked.app" if "WRAPPER_NAME" in key else "Hijacked"
                for arguments in modes:
                    with (
                        self.subTest(
                            owner=owner,
                            conditional_key=repr(key),
                            arguments=arguments,
                        ),
                        tempfile.TemporaryDirectory() as directory,
                    ):
                        _, project = self.copied_modern_fixture(directory)
                        self.add_selected_build_setting(project, owner, key, value)
                        with self.assertRaisesRegex(
                            project_inventory.PlanError,
                            "conditional build settings",
                        ):
                            project_inventory.build_project_inventory(
                                project, **arguments
                            )
            for key in direct_aliases:
                value = "Hijacked.app" if "WRAPPER_NAME" in key else "Hijacked"
                for arguments in modes:
                    with (
                        self.subTest(
                            owner=owner,
                            direct_key=repr(key),
                            arguments=arguments,
                        ),
                        tempfile.TemporaryDirectory() as directory,
                    ):
                        _, project = self.copied_modern_fixture(directory)
                        self.add_selected_build_setting(project, owner, key, value)
                        with self.assertRaisesRegex(
                            project_inventory.PlanError,
                            "noncanonical build setting key aliases",
                        ):
                            project_inventory.build_project_inventory(
                                project, **arguments
                            )

    def test_direct_native_product_paths_fail_closed_in_every_scope(self) -> None:
        keys = (
            "BUILD_DIR",
            "BUILD_ROOT",
            "BUILT_PRODUCTS_DIR",
            "CODESIGNING_FOLDER_PATH",
            "CONFIGURATION_BUILD_DIR",
            "CONTENTS_FOLDER_PATH",
            "EXECUTABLE_FOLDER_PATH",
            "EXECUTABLE_PATH",
            "INSTALL_DIR",
            "INSTALL_PATH",
            "OBJROOT",
            "PACKAGE_TYPE",
            "PRODUCT_MODULE_NAME",
            "SHALLOW_BUNDLE",
            "SHALLOW_BUNDLE_PLATFORM",
            "SHALLOW_BUNDLE_TRIPLE",
            "SHALLOW_BUNDLE_macos",
            "SWIFT_PLATFORM_TARGET_PREFIX",
            "LLVM_TARGET_TRIPLE_SUFFIX",
            "TARGET_BUILD_DIR",
        )
        modes = (
            {"scheme_name": "ModernApp"},
            {"target_selector": "ModernApp", "configuration_name": "Debug"},
        )
        for owner in ("project", "target"):
            for key in keys:
                for arguments in modes:
                    with (
                        self.subTest(owner=owner, key=key, arguments=arguments),
                        tempfile.TemporaryDirectory() as directory,
                    ):
                        _, project = self.copied_modern_fixture(directory)
                        self.add_selected_build_setting(
                            project, owner, key, '"Hijacked/Output"'
                        )
                        with self.assertRaisesRegex(
                            project_inventory.PlanError,
                            rf"explicit {owner} build setting {key}",
                        ):
                            project_inventory.build_project_inventory(
                                project, **arguments
                            )

    def test_selected_base_configurations_cannot_hide_product_identity_settings(self) -> None:
        modes = (
            {"scheme_name": "ModernApp"},
            {"target_selector": "ModernApp", "configuration_name": "Debug"},
        )
        configuration_ids = {
            "project": "400000000000000000000002",
            "target": "400000000000000000000005",
        }
        for owner, configuration_id in configuration_ids.items():
            with self.subTest(owner=owner), tempfile.TemporaryDirectory() as directory:
                root, project = self.copied_modern_fixture(directory)
                pbxproj = project / "project.pbxproj"
                contents = pbxproj.read_text(encoding="utf-8")
                child_marker = "\t\t\t\t000000000000000000000003,"
                object_marker = "\t\t000000000000000000000004 = {"
                configuration_marker = (
                    f"\t\t{configuration_id} = {{\n"
                    "\t\t\tisa = XCBuildConfiguration;"
                )
                for marker in (child_marker, object_marker, configuration_marker):
                    self.assertIn(marker, contents)
                contents = contents.replace(
                    child_marker,
                    child_marker + "\n\t\t\t\t100000000000000000000003,",
                    1,
                ).replace(
                    object_marker,
                    "\t\t100000000000000000000003 = {\n"
                    "\t\t\tisa = PBXFileReference;\n"
                    "\t\t\tlastKnownFileType = text.xcconfig;\n"
                    "\t\t\tpath = Base.xcconfig;\n"
                    "\t\t\tsourceTree = \"<group>\";\n"
                    "\t\t};\n"
                    + object_marker,
                    1,
                ).replace(
                    configuration_marker,
                    configuration_marker
                    + "\n\t\t\tbaseConfigurationReference = "
                    "100000000000000000000003;",
                    1,
                )
                pbxproj.write_text(contents, encoding="utf-8")
                (root / "Base.xcconfig").write_text(
                    "WRAPPER_NAME = Hijacked.app\n", encoding="utf-8"
                )
                for arguments in modes:
                    with self.subTest(owner=owner, arguments=arguments), self.assertRaisesRegex(
                        project_inventory.PlanError,
                        rf"selected {owner} base configuration",
                    ):
                        project_inventory.build_project_inventory(project, **arguments)

    def test_present_bundle_identifiers_use_a_safe_literal_grammar(self) -> None:
        invalid = (
            '""',
            '"$(PRODUCT_BUNDLE_IDENTIFIER)"',
            '"example..ModernApp"',
            '".example.ModernApp"',
            '"example.ModernApp."',
            '"example/ModernApp"',
            '"example ModernApp"',
            '"example;touch"',
            '"éxample.ModernApp"',
            '"-example.ModernApp"',
            '"example.-ModernApp"',
            '"example.ModernApp-"',
        )
        marker = "\t\t\t\tPRODUCT_BUNDLE_IDENTIFIER = example.ModernApp;"
        for owner in ("project", "target"):
            for value in invalid:
                with (
                    self.subTest(owner=owner, value=value),
                    tempfile.TemporaryDirectory() as directory,
                ):
                    _, project = self.copied_modern_fixture(directory)
                    if owner == "target":
                        pbxproj = project / "project.pbxproj"
                        contents = pbxproj.read_text(encoding="utf-8")
                        self.assertIn(marker, contents)
                        pbxproj.write_text(
                            contents.replace(
                                marker,
                                f"\t\t\t\tPRODUCT_BUNDLE_IDENTIFIER = {value};",
                                1,
                            ),
                            encoding="utf-8",
                        )
                    else:
                        self.add_selected_build_setting(
                            project, owner, "PRODUCT_BUNDLE_IDENTIFIER", value
                        )
                    with self.assertRaisesRegex(
                        project_inventory.PlanError,
                        rf"{owner} PRODUCT_BUNDLE_IDENTIFIER must be",
                    ):
                        project_inventory.build_project_inventory(
                            project, scheme_name="ModernApp"
                        )

    def test_project_product_name_inheritance_is_effective_and_exact(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            _, project = self.copied_modern_fixture(directory)
            pbxproj = project / "project.pbxproj"
            contents = pbxproj.read_text(encoding="utf-8")
            project_marker = "\t\t\tbuildSettings = { SWIFT_VERSION = 5.0; };"
            target_marker = '\t\t\t\tPRODUCT_NAME = "$(TARGET_NAME)";'
            self.assertIn(project_marker, contents)
            self.assertIn(target_marker, contents)
            contents = contents.replace(
                project_marker,
                '\t\t\tbuildSettings = { PRODUCT_NAME = "Café Notes"; SWIFT_VERSION = 5.0; };',
                1,
            ).replace(
                target_marker,
                '\t\t\t\tPRODUCT_NAME = "$(inherited)";\n'
                '\t\t\t\tEXECUTABLE_NAME = "Café Notes";\n'
                '\t\t\t\tFULL_PRODUCT_NAME = "Café Notes.app";\n'
                '\t\t\t\tWRAPPER_NAME = "Café Notes.app";',
                1,
            )
            pbxproj.write_text(contents, encoding="utf-8")
            scheme = project / "xcshareddata" / "xcschemes" / "ModernApp.xcscheme"
            scheme.write_text(
                scheme.read_text(encoding="utf-8").replace(
                    'BuildableName="ModernApp.app"',
                    'BuildableName="Café Notes.app"',
                ),
                encoding="utf-8",
            )
            inventory = project_inventory.build_project_inventory(
                project,
                scheme_name="ModernApp",
            )
            self.assertEqual(inventory["target"]["effective_product_name"], "Café Notes")
            self.assertEqual(inventory["target"]["buildable_name"], "Café Notes.app")
            self.assertEqual(inventory["target"]["product_name_origin"], "target")

    def test_project_product_name_is_effective_when_target_omits_it(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            _, project = self.copied_modern_fixture(directory)
            pbxproj = project / "project.pbxproj"
            contents = pbxproj.read_text(encoding="utf-8")
            project_marker = "\t\t\tbuildSettings = { SWIFT_VERSION = 5.0; };"
            target_marker = '\t\t\t\tPRODUCT_NAME = "$(TARGET_NAME)";\n'
            self.assertIn(project_marker, contents)
            self.assertIn(target_marker, contents)
            pbxproj.write_text(
                contents.replace(
                    project_marker,
                    "\t\t\tbuildSettings = { PRODUCT_NAME = ProjectApp; "
                    "SWIFT_VERSION = 5.0; };",
                    1,
                ).replace(target_marker, "", 1),
                encoding="utf-8",
            )
            scheme = project / "xcshareddata" / "xcschemes" / "ModernApp.xcscheme"
            scheme.write_text(
                scheme.read_text(encoding="utf-8").replace(
                    'BuildableName="ModernApp.app"',
                    'BuildableName="ProjectApp.app"',
                ),
                encoding="utf-8",
            )
            for arguments in (
                {"scheme_name": "ModernApp"},
                {"target_selector": "ModernApp", "configuration_name": "Debug"},
            ):
                with self.subTest(arguments=arguments):
                    inventory = project_inventory.build_project_inventory(
                        project, **arguments
                    )
                    self.assertEqual(
                        inventory["target"]["effective_product_name"], "ProjectApp"
                    )
                    self.assertEqual(
                        inventory["target"]["product_name_origin"], "project"
                    )

    def test_unsafe_project_product_name_is_rejected_even_when_overridden(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            _, project = self.copied_modern_fixture(directory)
            pbxproj = project / "project.pbxproj"
            contents = pbxproj.read_text(encoding="utf-8")
            marker = "\t\t\tbuildSettings = { SWIFT_VERSION = 5.0; };"
            self.assertIn(marker, contents)
            pbxproj.write_text(
                contents.replace(
                    marker,
                    '\t\t\tbuildSettings = { PRODUCT_NAME = "../Escape"; SWIFT_VERSION = 5.0; };',
                    1,
                ),
                encoding="utf-8",
            )
            with self.assertRaisesRegex(
                project_inventory.PlanError,
                "effective PRODUCT_NAME must be a canonical basename",
            ):
                project_inventory.build_project_inventory(
                    project,
                    target_selector="ModernApp",
                    configuration_name="Debug",
                )

    def test_safe_contradictory_product_name_cannot_hide_behind_scheme(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            _, project = self.copied_modern_fixture(directory)
            pbxproj = project / "project.pbxproj"
            contents = pbxproj.read_text(encoding="utf-8")
            marker = '\t\t\t\tPRODUCT_NAME = "$(TARGET_NAME)";'
            self.assertIn(marker, contents)
            pbxproj.write_text(
                contents.replace(
                    marker,
                    "\t\t\t\tPRODUCT_NAME = DifferentButSafe;",
                    1,
                ),
                encoding="utf-8",
            )
            with self.assertRaisesRegex(
                project_inventory.PlanError,
                "scheme buildable name.*effective product name",
            ):
                project_inventory.build_project_inventory(
                    project,
                    scheme_name="ModernApp",
                )

    def test_target_presentation_fields_are_validated_in_target_mode(self) -> None:
        replacements = (
            (
                "\t\t\tproductName = ModernApp;",
                '\t\t\tproductName = "../PresentationEscape";',
                "selected target.productName",
            ),
            (
                "\t\t\tname = ModernApp;\n\t\t\tpackageProductDependencies = ();",
                '\t\t\tname = "Bad;Name";\n\t\t\tpackageProductDependencies = ();',
                "selected target.name",
            ),
        )
        for marker, replacement, diagnostic in replacements:
            with self.subTest(diagnostic=diagnostic), tempfile.TemporaryDirectory() as directory:
                _, project = self.copied_modern_fixture(directory)
                pbxproj = project / "project.pbxproj"
                contents = pbxproj.read_text(encoding="utf-8")
                self.assertIn(marker, contents)
                pbxproj.write_text(
                    contents.replace(marker, replacement, 1),
                    encoding="utf-8",
                )
                with self.assertRaisesRegex(project_inventory.PlanError, diagnostic):
                    selector = (
                        "ModernApp"
                        if "productName" in marker
                        else "AAAAAAAAAAAAAAAAAAAAAAAA"
                    )
                    project_inventory.build_project_inventory(
                        project,
                        target_selector=selector,
                        configuration_name="Debug",
                    )

    def test_present_empty_product_name_is_not_an_absent_field_fallback(self) -> None:
        marker = "\t\t\tproductName = ModernApp;"
        with tempfile.TemporaryDirectory() as directory:
            _, project = self.copied_modern_fixture(directory)
            pbxproj = project / "project.pbxproj"
            contents = pbxproj.read_text(encoding="utf-8")
            self.assertIn(marker, contents)
            pbxproj.write_text(
                contents.replace(marker, '\t\t\tproductName = "";', 1),
                encoding="utf-8",
            )
            with self.assertRaisesRegex(
                project_inventory.PlanError,
                "selected target.productName must be a canonical basename",
            ):
                project_inventory.build_project_inventory(
                    project,
                    target_selector="ModernApp",
                    configuration_name="Debug",
                )

        with tempfile.TemporaryDirectory() as directory:
            _, project = self.copied_modern_fixture(directory)
            pbxproj = project / "project.pbxproj"
            contents = pbxproj.read_text(encoding="utf-8")
            self.assertIn(marker, contents)
            pbxproj.write_text(contents.replace(marker + "\n", "", 1), encoding="utf-8")
            inventory = project_inventory.build_project_inventory(
                project,
                target_selector="ModernApp",
                configuration_name="Debug",
            )
            self.assertEqual(inventory["target"]["product_name"], "ModernApp")

    def test_present_empty_product_reference_path_does_not_fallback_to_name(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            _, project = self.copied_modern_fixture(directory)
            pbxproj = project / "project.pbxproj"
            contents = pbxproj.read_text(encoding="utf-8")
            marker = "\t\t\tpath = ModernApp.app;\n\t\t\tsourceTree = BUILT_PRODUCTS_DIR;"
            self.assertIn(marker, contents)
            pbxproj.write_text(
                contents.replace(
                    marker,
                    '\t\t\tname = ModernApp.app;\n\t\t\tpath = "";\n'
                    "\t\t\tsourceTree = BUILT_PRODUCTS_DIR;",
                    1,
                ),
                encoding="utf-8",
            )
            with self.assertRaisesRegex(
                project_inventory.PlanError,
                "selected target.productReference path is empty",
            ):
                project_inventory.build_project_inventory(
                    project,
                    target_selector="ModernApp",
                    configuration_name="Debug",
                )

    def test_product_reference_presentation_name_uses_safe_artifact_grammar(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            _, project = self.copied_modern_fixture(directory)
            pbxproj = project / "project.pbxproj"
            contents = pbxproj.read_text(encoding="utf-8")
            marker = "\t\t\tpath = ModernApp.app;\n\t\t\tsourceTree = BUILT_PRODUCTS_DIR;"
            self.assertIn(marker, contents)
            pbxproj.write_text(
                contents.replace(
                    marker,
                    '\t\t\tname = "ModernApp;touch PWN.app";\n' + marker,
                    1,
                ),
                encoding="utf-8",
            )
            with self.assertRaisesRegex(
                project_inventory.PlanError,
                "productReference.name.*safe artifact grammar",
            ):
                project_inventory.build_project_inventory(
                    project,
                    target_selector="ModernApp",
                    configuration_name="Debug",
                )

    def test_scheme_build_action_reference_matches_launch_reference(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            _, project = self.copied_modern_fixture(directory)
            scheme = (
                project
                / "xcshareddata"
                / "xcschemes"
                / "ModernApp.xcscheme"
            )
            scheme.write_text(
                scheme.read_text(encoding="utf-8").replace(
                    'BuildableName="ModernApp.app"',
                    'BuildableName="Wrong.app"',
                    1,
                ),
                encoding="utf-8",
            )
            with self.assertRaisesRegex(
                project_inventory.PlanError,
                "BuildAction.*reference.*runnable",
            ):
                project_inventory.build_project_inventory(
                    project,
                    scheme_name="ModernApp",
                )

    def test_synchronized_sources_resources_and_headers_are_exact(self) -> None:
        inventory = self.inventory()
        self.assertEqual(
            [item["path"] for item in inventory["sources"]],
            [
                "App/Bridge.m",
                "App/Main.swift",
                "App/Nested/Feature.swift",
                "App/OtherTargetOnly.swift",
                "App/Upper.SWIFT",
            ],
        )
        self.assertEqual(
            [item["path"] for item in inventory["resources"]],
            [
                "App/Assets.xcassets",
                "App/Base.lproj/Localizable.strings",
                "App/Config.payload",
                "App/Data.json",
            ],
        )
        self.assertEqual(
            [item["path"] for item in inventory["headers"]],
            ["App/Generated.inc", "App/Public.h"],
        )
        self.assertTrue(
            all(item["origin"] == "filesystem_synchronized"
                for key in ("sources", "resources", "headers")
                for item in inventory[key])
        )
        self.assertTrue(inventory["resources"][0]["directory_resource"])
        self.assertEqual(
            inventory["resources"][2]["explicit_file_type"], "text.json"
        )
        self.assertEqual(
            inventory["headers"][0]["explicit_file_type"], "sourcecode.c.h"
        )
        self.assertEqual(
            inventory["summary"],
            {
                "phase_count": 3,
                "source_count": 5,
                "swift_source_count": 4,
                "resource_count": 4,
                "header_count": 2,
                "unclassified_count": 0,
                "synchronized_group_count": 1,
                "target_dependency_count": 0,
                "package_product_count": 0,
                "missing_input_count": 0,
            },
        )
        self.assertEqual(inventory["unsupported_features"], [])

    def test_synchronized_mlpackage_is_one_opaque_compiler_input(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            root, project = self.copied_modern_fixture(directory)
            package = root / "App" / "Model.mlpackage"
            package.mkdir()
            (package / "Manifest.json").write_text("{}\n", encoding="utf-8")
            inventory = project_inventory.build_project_inventory(
                project,
                scheme_name="ModernApp",
            )
            paths = [item["path"] for item in inventory["sources"]]
            self.assertIn("App/Model.mlpackage", paths)
            self.assertNotIn("App/Model.mlpackage/Manifest.json", paths)
            item = next(
                item for item in inventory["sources"]
                if item["path"] == "App/Model.mlpackage"
            )
            self.assertTrue(item["directory_source"])

    def test_synchronized_compiler_wrappers_are_atomic_sources(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            root, project = self.copied_modern_fixture(directory)
            app = root / "App"
            (app / "Model.mlmodel").write_bytes(b"model\n")
            (app / "Legacy.mlkitmodel").write_bytes(b"legacy\n")
            for name in (
                "Single.xcdatamodel",
                "Versioned.xcdatamodeld",
                "Migration.xcmappingmodel",
            ):
                wrapper = app / name
                wrapper.mkdir()
                (wrapper / "contents").write_text("contents\n", encoding="utf-8")
            package = app / "Package.mlpackage"
            package.mkdir()
            (package / "Manifest.json").write_text("{}\n", encoding="utf-8")

            inventory = project_inventory.build_project_inventory(
                project,
                scheme_name="ModernApp",
            )
            compiler_paths = {
                item["path"] for item in inventory["sources"]
                if item["path"].startswith(
                    (
                        "App/Legacy.",
                        "App/Migration.",
                        "App/Model.",
                        "App/Package.",
                        "App/Single.",
                        "App/Versioned.",
                    )
                )
            }
            self.assertEqual(
                compiler_paths,
                {
                    "App/Legacy.mlkitmodel",
                    "App/Migration.xcmappingmodel",
                    "App/Model.mlmodel",
                    "App/Package.mlpackage",
                    "App/Single.xcdatamodel",
                    "App/Versioned.xcdatamodeld",
                },
            )
            all_paths = {
                item["path"]
                for key in ("sources", "resources", "headers", "unclassified")
                for item in inventory[key]
            }
            self.assertNotIn("App/Package.mlpackage/Manifest.json", all_paths)
            self.assertNotIn("App/Single.xcdatamodel/contents", all_paths)

    def test_current_resource_wrappers_remain_atomic_resources(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            root, project = self.copied_modern_fixture(directory)
            app = root / "App"
            for name in ("Pictures.imagecatalog", "Stickers.xcstickers", "Brand.icon"):
                wrapper = app / name
                wrapper.mkdir()
                (wrapper / "Contents.json").write_text("{}\n", encoding="utf-8")
            pbxproj = project / "project.pbxproj"
            contents = pbxproj.read_text(encoding="utf-8")
            marker = "\t\t\texplicitFileTypes = {"
            self.assertIn(marker, contents)
            pbxproj.write_text(
                contents.replace(
                    marker,
                    marker
                    + "\n\t\t\t\tBrand.icon = folder.iconcomposer.icon;"
                    + "\n\t\t\t\tPictures.imagecatalog = folder.imagecatalog;"
                    + "\n\t\t\t\tStickers.xcstickers = folder.stickers;",
                    1,
                ),
                encoding="utf-8",
            )
            inventory = project_inventory.build_project_inventory(
                project,
                scheme_name="ModernApp",
            )
            resource_paths = {item["path"] for item in inventory["resources"]}
            self.assertTrue(
                {
                    "App/Brand.icon",
                    "App/Pictures.imagecatalog",
                    "App/Stickers.xcstickers",
                }.issubset(resource_paths)
            )
            self.assertFalse(any(path.endswith("/Contents.json") for path in resource_paths))

    def test_explicit_file_types_are_mapped_semantically(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            root, project = self.copied_modern_fixture(directory)
            app = root / "App"
            (app / "Model.payload").write_bytes(b"model\n")
            package = app / "Package.payload"
            package.mkdir()
            (package / "Manifest.json").write_text("{}\n", encoding="utf-8")
            pbxproj = project / "project.pbxproj"
            contents = pbxproj.read_text(encoding="utf-8")
            marker = "\t\t\texplicitFileTypes = {"
            self.assertIn(marker, contents)
            pbxproj.write_text(
                contents.replace(
                    marker,
                    marker
                    + "\n\t\t\t\tModel.payload = file.mlmodel;"
                    + "\n\t\t\t\tPackage.payload = folder.mlpackage;",
                    1,
                ),
                encoding="utf-8",
            )
            inventory = project_inventory.build_project_inventory(
                project,
                scheme_name="ModernApp",
            )
            source_paths = {item["path"] for item in inventory["sources"]}
            self.assertIn("App/Model.payload", source_paths)
            self.assertIn("App/Package.payload", source_paths)
            self.assertEqual(inventory["unclassified"], [])
            self.assertEqual(inventory["unsupported_features"], [])

    def test_unknown_explicit_type_prefixes_are_rejected(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            _, project = self.copied_modern_fixture(directory)
            pbxproj = project / "project.pbxproj"
            contents = pbxproj.read_text(encoding="utf-8")
            marker = "\t\t\texplicitFileTypes = {"
            self.assertIn(marker, contents)
            pbxproj.write_text(
                contents.replace(
                    marker,
                    marker
                    + "\n\t\t\t\tBridge.m = audio.codex-imaginary;"
                    + "\n\t\t\t\tData.json = image.codex-imaginary;"
                    + "\n\t\t\t\tMain.swift = sourcecode.codex-imaginary;"
                    + "\n\t\t\t\tPublic.h = video.codex-imaginary;",
                    1,
                ),
                encoding="utf-8",
            )
            with self.assertRaisesRegex(
                project_inventory.PlanError,
                "Bridge\\.m.*unsupported explicit file type.*audio\\.codex-imaginary",
            ):
                project_inventory.build_project_inventory(
                    project,
                    scheme_name="ModernApp",
                )

    def test_empty_explicit_file_type_is_rejected(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            _, project = self.copied_modern_fixture(directory)
            pbxproj = project / "project.pbxproj"
            contents = pbxproj.read_text(encoding="utf-8")
            marker = "\t\t\texplicitFileTypes = {"
            self.assertIn(marker, contents)
            pbxproj.write_text(
                contents.replace(
                    marker,
                    marker + '\n\t\t\t\tMain.swift = "";',
                    1,
                ),
                encoding="utf-8",
            )
            with self.assertRaisesRegex(
                project_inventory.PlanError,
                "Main\\.swift.*unsupported explicit file type ''",
            ):
                project_inventory.build_project_inventory(
                    project,
                    scheme_name="ModernApp",
                )

    def test_exact_explicit_type_allowlists_preserve_distinct_semantics(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            _, project = self.copied_modern_fixture(directory)
            pbxproj = project / "project.pbxproj"
            contents = pbxproj.read_text(encoding="utf-8")
            marker = "\t\t\texplicitFileTypes = {"
            self.assertIn(marker, contents)
            pbxproj.write_text(
                contents.replace(
                    marker,
                    marker
                    + "\n\t\t\t\tBridge.m = sourcecode.c.objc;"
                    + "\n\t\t\t\tData.json = image.png;"
                    + "\n\t\t\t\tMain.swift = sourcecode.swift;"
                    + "\n\t\t\t\tPublic.h = sourcecode.c.h;",
                    1,
                ),
                encoding="utf-8",
            )
            inventory = project_inventory.build_project_inventory(
                project,
                scheme_name="ModernApp",
            )
            self.assertTrue(
                {"App/Bridge.m", "App/Main.swift"}.issubset(
                    {item["path"] for item in inventory["sources"]}
                )
            )
            self.assertIn(
                "App/Data.json",
                {item["path"] for item in inventory["resources"]},
            )
            self.assertIn(
                "App/Public.h",
                {item["path"] for item in inventory["headers"]},
            )
            self.assertEqual(inventory["unclassified"], [])
            self.assertEqual(inventory["unsupported_features"], [])

    def test_project_directory_rebasing_fails_closed(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            _, project = self.copied_modern_fixture(directory)
            pbxproj = project / "project.pbxproj"
            contents = pbxproj.read_text(encoding="utf-8")
            pbxproj.write_text(
                contents.replace('projectDirPath = "";', "projectDirPath = AltRoot;", 1),
                encoding="utf-8",
            )
            with self.assertRaisesRegex(
                project_inventory.PlanError,
                "projectDirPath uses unsupported source-root rebasing",
            ):
                self.inventory(project)

        with tempfile.TemporaryDirectory() as directory:
            _, project = self.copied_modern_fixture(directory)
            pbxproj = project / "project.pbxproj"
            contents = pbxproj.read_text(encoding="utf-8")
            pbxproj.write_text(
                contents.replace('projectRoot = "";', "projectRoot = AltRoot;", 1),
                encoding="utf-8",
            )
            with self.assertRaisesRegex(
                project_inventory.PlanError,
                "projectRoot uses unsupported source-root rebasing",
            ):
                self.inventory(project)

        with tempfile.TemporaryDirectory() as directory:
            _, project = self.copied_modern_fixture(directory)
            pbxproj = project / "project.pbxproj"
            contents = pbxproj.read_text(encoding="utf-8")
            pbxproj.write_text(
                contents.replace('projectRoot = "";', "projectRoot = .;", 1),
                encoding="utf-8",
            )
            with self.assertRaisesRegex(
                project_inventory.PlanError,
                "projectRoot uses unsupported source-root rebasing",
            ):
                self.inventory(project)

    def test_legacy_dot_project_directory_is_supported(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            _, project = self.copied_modern_fixture(directory)
            pbxproj = project / "project.pbxproj"
            contents = pbxproj.read_text(encoding="utf-8")
            pbxproj.write_text(
                contents.replace('projectDirPath = "";', "projectDirPath = .;", 1),
                encoding="utf-8",
            )
            inventory = self.inventory(project)
            self.assertEqual(inventory["target"]["name"], "ModernApp")

    def test_unknown_dotted_directory_fails_closed_as_unclassified(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            root, project = self.copied_modern_fixture(directory)
            package = root / "App" / "Model.unknownwrapper"
            package.mkdir()
            (package / "Hidden.swift").write_text("struct Hidden {}\n", encoding="utf-8")
            inventory = project_inventory.build_project_inventory(
                project,
                scheme_name="ModernApp",
            )
            self.assertEqual(
                [item["path"] for item in inventory["unclassified"]],
                ["App/Model.unknownwrapper"],
            )
            self.assertNotIn(
                "App/Model.unknownwrapper/Hidden.swift",
                [item["path"] for item in inventory["sources"]],
            )
            self.assertTrue(inventory["unsupported_features"])

    def test_membership_exclusions_are_selected_target_specific(self) -> None:
        inventory = self.inventory()
        group = inventory["filesystem_synchronized_groups"][0]
        self.assertEqual(group["group_id"], "000000000000000000000003")
        self.assertEqual(group["path"], "App")
        self.assertEqual(
            group["exception_ids"], ["500000000000000000000001"]
        )
        self.assertEqual(
            group["membership_exceptions"],
            ["Excluded.swift", "ExcludedFolder", "Info.plist"],
        )
        self.assertEqual(
            group["ignored"],
            [
                {"path": ".ignored.swift", "reason": "hidden"},
                {"path": "Excluded.swift", "reason": "membership_exception"},
                {"path": "ExcludedFolder", "reason": "membership_exception"},
                {"path": "Info.plist", "reason": "membership_exception"},
            ],
        )
        all_paths = {
            item["path"]
            for key in ("sources", "resources", "headers", "unclassified")
            for item in inventory[key]
        }
        self.assertIn("App/OtherTargetOnly.swift", all_paths)
        self.assertNotIn("App/Excluded.swift", all_paths)
        self.assertFalse(any(path.startswith("App/ExcludedFolder/") for path in all_paths))
        self.assertNotIn("App/Info.plist", all_paths)

        helper = project_inventory.build_project_inventory(
            MODERN_PROJECT,
            target_selector="Helper",
            configuration_name="Debug",
        )
        helper_paths = {
            item["path"]
            for key in ("sources", "resources", "headers", "unclassified")
            for item in helper[key]
        }
        self.assertNotIn("App/OtherTargetOnly.swift", helper_paths)
        self.assertIn("App/Excluded.swift", helper_paths)
        self.assertIn("App/ExcludedFolder/Secret.swift", helper_paths)
        self.assertIn("App/Info.plist", helper_paths)

    def test_explicit_type_for_membership_excluded_file_is_allowed(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            _, project = self.copied_modern_fixture(directory)
            pbxproj = project / "project.pbxproj"
            contents = pbxproj.read_text(encoding="utf-8")
            marker = "\t\t\texplicitFileTypes = {"
            self.assertIn(marker, contents)
            contents = contents.replace(
                marker,
                marker + "\n\t\t\t\tExcluded.swift = sourcecode.swift;",
                1,
            )
            pbxproj.write_text(contents, encoding="utf-8")
            inventory = project_inventory.build_project_inventory(
                project,
                scheme_name="ModernApp",
            )
            self.assertNotIn(
                "App/Excluded.swift",
                {
                    item["path"]
                    for key in ("sources", "resources", "headers", "unclassified")
                    for item in inventory[key]
                },
            )

    def test_explicit_type_for_absent_file_is_rejected(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            _, project = self.copied_modern_fixture(directory)
            pbxproj = project / "project.pbxproj"
            contents = pbxproj.read_text(encoding="utf-8")
            marker = "\t\t\texplicitFileTypes = {"
            self.assertIn(marker, contents)
            pbxproj.write_text(
                contents.replace(
                    marker,
                    marker + "\n\t\t\t\tMissing.swift = sourcecode.swift;",
                    1,
                ),
                encoding="utf-8",
            )
            with self.assertRaisesRegex(
                project_inventory.PlanError,
                "explicit file types for absent.*Missing.swift",
            ):
                project_inventory.build_project_inventory(
                    project,
                    scheme_name="ModernApp",
                )

    def test_classic_mini_project_remains_compatible(self) -> None:
        inventory = project_inventory.build_project_inventory(
            MINI_PROJECT,
            scheme_name="Focus",
        )
        self.assertEqual(inventory["target"]["name"], "Blockzilla")
        self.assertEqual(inventory["configuration"]["name"], "FocusDebug")
        self.assertIsNone(inventory["configuration"]["project"])
        self.assertEqual(
            [item["path"] for item in inventory["sources"]],
            [
                "App/Source.swift",
                "App/Generated.swift",
                "App/Intents.intentdefinition",
            ],
        )
        self.assertEqual(
            [item["path"] for item in inventory["resources"]],
            ["App/Resource.txt"],
        )
        self.assertEqual(
            inventory["missing_inputs"],
            [
                {
                    "build_file_id": "200000000000000000000002",
                    "path": "App/Generated.swift",
                    "phase_id": "300000000000000000000005",
                }
            ],
        )
        self.assertIn("not materialized", inventory["unsupported_features"][0])
        self.assertEqual(inventory["filesystem_synchronized_groups"], [])
        shell_phases = [
            phase
            for phase in inventory["build_phases"]
            if phase["kind"] == "shell_script"
        ]
        self.assertEqual(len(shell_phases), 4)
        self.assertTrue(all(phase["files"] == [] for phase in shell_phases))

    def test_canonical_output_is_byte_deterministic(self) -> None:
        first = project_inventory.canonical_json(self.inventory())
        second = project_inventory.canonical_json(self.inventory())
        self.assertEqual(first, second)
        self.assertTrue(first.endswith(b"\n"))

        command = [
            sys.executable,
            os.fspath(TOOL_DIR / "project_inventory.py"),
            os.fspath(MODERN_PROJECT),
            "--scheme",
            "ModernApp",
        ]
        first_process = subprocess.run(
            command,
            check=True,
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
        )
        second_process = subprocess.run(
            command,
            check=True,
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
        )
        self.assertEqual(first_process.stdout, second_process.stdout)
        self.assertEqual(first_process.stdout, first)
        self.assertEqual(first_process.stderr, b"")
        self.assertEqual(second_process.stderr, b"")


class ProjectInventoryPathSafetyTests(unittest.TestCase):
    def copied_modern_fixture(self, directory: str) -> tuple[Path, Path]:
        root = Path(directory) / "modern_sync"
        shutil.copytree(MODERN_FIXTURE, root)
        return root, root / "ModernSync.xcodeproj"

    def inventory(self, project: Path):
        return project_inventory.build_project_inventory(
            project,
            scheme_name="ModernApp",
        )

    def copied_mini_fixture(self, directory: str) -> tuple[Path, Path]:
        root = Path(directory) / "mini"
        shutil.copytree(MINI_FIXTURE, root)
        return root, root / "Blockzilla.xcodeproj"

    def add_target_phase(
        self,
        contents: str,
        phase_id: str,
        isa: str,
        build_file_ids: list[str],
        extra_fields: str = "",
    ) -> str:
        object_marker = "\t\t400000000000000000000001 = {"
        target_marker = (
            "\t\t\t\t300000000000000000000008,\n"
            "\t\t\t);"
        )
        self.assertIn(object_marker, contents)
        self.assertIn(target_marker, contents)
        files = "\n".join(f"\t\t\t\t{item}," for item in build_file_ids)
        phase = (
            f"\t\t{phase_id} = {{\n"
            f"\t\t\tisa = {isa};\n"
            f"{extra_fields}"
            "\t\t\tfiles = (\n"
            f"{files}\n"
            "\t\t\t);\n"
            "\t\t};\n"
        )
        contents = contents.replace(object_marker, phase + object_marker, 1)
        return contents.replace(
            target_marker,
            "\t\t\t\t300000000000000000000008,\n"
            f"\t\t\t\t{phase_id},\n"
            "\t\t\t);",
            1,
        )

    def add_classic_source_alias(self, contents: str, path: str) -> str:
        child_marker = "\t\t\t\t100000000000000000000001 /* Source.swift */,"
        object_marker = "\t\t100000000000000000000001 = {"
        build_marker = "\t\t200000000000000000000001 = {"
        phase_marker = "\t\t\t\t200000000000000000000001,"
        for marker in (child_marker, object_marker, build_marker, phase_marker):
            self.assertIn(marker, contents)
        return contents.replace(
            child_marker,
            child_marker + "\n\t\t\t\t100000000000000000000008 /* source alias */,",
            1,
        ).replace(
            object_marker,
            "\t\t100000000000000000000008 = {\n"
            "\t\t\tisa = PBXFileReference;\n"
            "\t\t\tlastKnownFileType = sourcecode.swift;\n"
            f'\t\t\tpath = "{path}";\n'
            '\t\t\tsourceTree = "<group>";\n'
            "\t\t};\n"
            + object_marker,
            1,
        ).replace(
            build_marker,
            "\t\t200000000000000000000007 = {isa = PBXBuildFile; "
            "fileRef = 100000000000000000000008; };\n"
            + build_marker,
            1,
        ).replace(
            phase_marker,
            phase_marker + "\n\t\t\t\t200000000000000000000007,",
            1,
        )

    def test_supplied_source_root_symlink_is_rejected(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            root, _ = self.copied_modern_fixture(directory)
            alias = Path(directory) / "source-root"
            alias.symlink_to(root, target_is_directory=True)
            with self.assertRaisesRegex(
                project_inventory.PlanError,
                "project source root must not be a symlink",
            ):
                self.inventory(alias / "ModernSync.xcodeproj")

    def test_synchronized_root_parent_escape_is_rejected(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            _, project = self.copied_modern_fixture(directory)
            pbxproj = project / "project.pbxproj"
            text = pbxproj.read_text(encoding="utf-8")
            pbxproj.write_text(
                text.replace("\t\t\tpath = App;", "\t\t\tpath = ../outside;", 1),
                encoding="utf-8",
            )
            with self.assertRaisesRegex(
                project_inventory.PlanError, "escapes the repository"
            ):
                self.inventory(project)

    def test_synchronized_root_symlink_is_rejected(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            root, project = self.copied_modern_fixture(directory)
            real_app = root / "RealApp"
            (root / "App").rename(real_app)
            (root / "App").symlink_to(real_app, target_is_directory=True)
            with self.assertRaisesRegex(
                project_inventory.PlanError, "traverses a symlink"
            ):
                self.inventory(project)

    def test_synchronized_child_symlink_is_rejected(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            root, project = self.copied_modern_fixture(directory)
            outside = Path(directory) / "Outside.swift"
            outside.write_text("struct Outside {}\n", encoding="utf-8")
            (root / "App" / "Unsafe.swift").symlink_to(outside)
            with self.assertRaisesRegex(
                project_inventory.PlanError, "contains a symlink: Unsafe.swift"
            ):
                self.inventory(project)

    def test_source_aliases_are_rejected_by_portable_casefold_identity(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            _, project = self.copied_mini_fixture(directory)
            pbxproj = project / "project.pbxproj"
            contents = self.add_classic_source_alias(
                pbxproj.read_text(encoding="utf-8"),
                "source.swift",
            )
            pbxproj.write_text(contents, encoding="utf-8")
            with self.assertRaisesRegex(
                project_inventory.PlanError,
                "aliased inputs.*Source\\.swift.*source\\.swift.*more than once",
            ):
                project_inventory.build_project_inventory(
                    project,
                    scheme_name="Focus",
                )

    def test_source_aliases_are_rejected_by_unicode_normalization_identity(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            root, project = self.copied_mini_fixture(directory)
            source = root / "App" / "Source.swift"
            normalized = root / "App" / "Café.swift"
            source.rename(normalized)
            pbxproj = project / "project.pbxproj"
            contents = pbxproj.read_text(encoding="utf-8").replace(
                "\t\t\tpath = Source.swift;",
                '\t\t\tpath = "Café.swift";',
                1,
            )
            contents = self.add_classic_source_alias(contents, "Café.swift")
            pbxproj.write_text(contents, encoding="utf-8")
            with self.assertRaisesRegex(
                project_inventory.PlanError,
                "aliased inputs.*more than once",
            ):
                project_inventory.build_project_inventory(
                    project,
                    scheme_name="Focus",
                )

    def test_source_hard_links_are_rejected_by_filesystem_identity(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            root, project = self.copied_modern_fixture(directory)
            os.link(root / "App" / "Main.swift", root / "App" / "MainAlias.swift")
            with self.assertRaisesRegex(
                project_inventory.PlanError,
                "one filesystem object.*more than once",
            ):
                self.inventory(project)

    def test_directory_resource_nested_symlink_is_rejected(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            root, project = self.copied_modern_fixture(directory)
            outside = Path(directory) / "Outside.json"
            outside.write_text("{}\n", encoding="utf-8")
            (root / "App" / "Assets.xcassets" / "Unsafe.json").symlink_to(outside)
            with self.assertRaisesRegex(
                project_inventory.PlanError, "contains a symlink.*Assets.xcassets"
            ):
                self.inventory(project)

    def test_project_file_symlink_is_rejected(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            _, project = self.copied_modern_fixture(directory)
            pbxproj = project / "project.pbxproj"
            outside = Path(directory) / "project.pbxproj"
            pbxproj.rename(outside)
            pbxproj.symlink_to(outside)
            with self.assertRaisesRegex(
                project_inventory.PlanError, "project file must be a regular non-symlink"
            ):
                self.inventory(project)

    def test_classic_phase_source_symlink_escape_is_rejected(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory) / "mini"
            shutil.copytree(MINI_FIXTURE, root)
            source = root / "App" / "Source.swift"
            outside = Path(directory) / "Outside.swift"
            source.rename(outside)
            source.symlink_to(outside)
            with self.assertRaisesRegex(project_inventory.PlanError, "symlink"):
                project_inventory.build_project_inventory(
                    root / "Blockzilla.xcodeproj",
                    scheme_name="Focus",
                )

    def test_missing_generated_source_cannot_hide_symlink_parent(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory) / "mini"
            shutil.copytree(MINI_FIXTURE, root)
            project = root / "Blockzilla.xcodeproj"
            pbxproj = project / "project.pbxproj"
            contents = pbxproj.read_text(encoding="utf-8")
            marker = "\t\t\tpath = Generated.swift;"
            self.assertIn(marker, contents)
            pbxproj.write_text(
                contents.replace(
                    marker,
                    "\t\t\tpath = Generated/Output.swift;",
                    1,
                ),
                encoding="utf-8",
            )
            outside = Path(directory) / "Generated"
            outside.mkdir()
            (root / "App" / "Generated").symlink_to(
                outside,
                target_is_directory=True,
            )
            with self.assertRaisesRegex(project_inventory.PlanError, "symlink"):
                project_inventory.build_project_inventory(
                    project,
                    scheme_name="Focus",
                )

    def test_classic_base_configuration_symlink_escape_is_rejected(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory) / "mini"
            shutil.copytree(MINI_FIXTURE, root)
            project = root / "Blockzilla.xcodeproj"
            pbxproj = project / "project.pbxproj"
            contents = pbxproj.read_text(encoding="utf-8")
            child_marker = (
                "\t\t\t\t100000000000000000000005 /* Resource.txt */,"
            )
            self.assertIn(child_marker, contents)
            contents = contents.replace(
                child_marker,
                child_marker
                + "\n\t\t\t\t100000000000000000000008 /* Config.xcconfig */,",
                1,
            )
            object_marker = "\t\t100000000000000000000001 = {"
            self.assertIn(object_marker, contents)
            contents = contents.replace(
                object_marker,
                "\t\t100000000000000000000008 = {\n"
                "\t\t\tisa = PBXFileReference;\n"
                "\t\t\tlastKnownFileType = text.xcconfig;\n"
                "\t\t\tpath = Config.xcconfig;\n"
                "\t\t\tsourceTree = \"<group>\";\n"
                "\t\t};\n"
                + object_marker,
                1,
            )
            configuration_marker = (
                "\t\t400000000000000000000002 = {\n"
                "\t\t\tisa = XCBuildConfiguration;"
            )
            self.assertIn(configuration_marker, contents)
            contents = contents.replace(
                configuration_marker,
                configuration_marker
                + "\n\t\t\tbaseConfigurationReference = "
                "100000000000000000000008;",
                1,
            )
            pbxproj.write_text(contents, encoding="utf-8")
            config = root / "App" / "Config.xcconfig"
            config.write_text("PRODUCT_NAME = Configured\n", encoding="utf-8")
            with self.assertRaisesRegex(
                project_inventory.PlanError,
                "cannot determine product identity through.*base configuration",
            ):
                project_inventory.build_project_inventory(
                    project,
                    scheme_name="Focus",
                )
            config.unlink()
            outside = Path(directory) / "Config.xcconfig"
            outside.write_text("SETTING = outside\n", encoding="utf-8")
            config.symlink_to(outside)
            with self.assertRaisesRegex(project_inventory.PlanError, "symlink"):
                project_inventory.build_project_inventory(
                    project,
                    scheme_name="Focus",
                )

    def test_selected_base_configuration_is_pinned_then_rejected_for_identity(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            root, project = self.copied_modern_fixture(directory)
            pbxproj = project / "project.pbxproj"
            contents = pbxproj.read_text(encoding="utf-8")
            child_marker = "\t\t\t\t000000000000000000000003,"
            self.assertIn(child_marker, contents)
            contents = contents.replace(
                child_marker,
                child_marker + "\n\t\t\t\t000000000000000000000005,",
                1,
            )
            object_marker = "\t\t000000000000000000000004 = {"
            self.assertIn(object_marker, contents)
            contents = contents.replace(
                object_marker,
                "\t\t000000000000000000000005 = {\n"
                "\t\t\tisa = PBXFileSystemSynchronizedRootGroup;\n"
                "\t\t\texplicitFileTypes = {};\n"
                "\t\t\texplicitFolders = ();\n"
                "\t\t\tpath = Configs;\n"
                "\t\t\tsourceTree = \"<group>\";\n"
                "\t\t};\n"
                + object_marker,
                1,
            )
            configuration_marker = (
                "\t\t400000000000000000000005 = {\n"
                "\t\t\tisa = XCBuildConfiguration;"
            )
            self.assertIn(configuration_marker, contents)
            contents = contents.replace(
                configuration_marker,
                configuration_marker
                + "\n\t\t\tbaseConfigurationReferenceAnchor = "
                "000000000000000000000005;\n"
                "\t\t\tbaseConfigurationReferenceRelativePath = Base.xcconfig;",
                1,
            )
            pbxproj.write_text(contents, encoding="utf-8")

            configs = root / "Configs"
            configs.mkdir()
            config = configs / "Base.xcconfig"
            config.write_text("SETTING = inside\n", encoding="utf-8")
            with self.assertRaisesRegex(
                project_inventory.PlanError,
                "cannot determine product identity through the selected target "
                "base configuration",
            ):
                self.inventory(project)

            outside = Path(directory) / "Outside.xcconfig"
            config.rename(outside)
            config.symlink_to(outside)
            with self.assertRaisesRegex(project_inventory.PlanError, "symlink"):
                self.inventory(project)

    def test_classic_framework_symlink_escape_is_rejected(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory) / "mini"
            shutil.copytree(MINI_FIXTURE, root)
            project = root / "Blockzilla.xcodeproj"
            pbxproj = project / "project.pbxproj"
            contents = pbxproj.read_text(encoding="utf-8")
            self.assertIn(
                "\t\t\t\t100000000000000000000005 /* Resource.txt */,",
                contents,
            )
            contents = contents.replace(
                "\t\t\t\t100000000000000000000005 /* Resource.txt */,",
                "\t\t\t\t100000000000000000000005 /* Resource.txt */,\n"
                "\t\t\t\t100000000000000000000008 /* Unsafe.framework */,",
                1,
            )
            self.assertIn("\t\t100000000000000000000001 = {", contents)
            contents = contents.replace(
                "\t\t100000000000000000000001 = {",
                "\t\t100000000000000000000008 = {\n"
                "\t\t\tisa = PBXFileReference;\n"
                "\t\t\texplicitFileType = wrapper.framework;\n"
                "\t\t\tpath = Unsafe.framework;\n"
                "\t\t\tsourceTree = \"<group>\";\n"
                "\t\t};\n"
                "\t\t100000000000000000000001 = {",
                1,
            )
            self.assertIn("\t\t200000000000000000000001 = {", contents)
            contents = contents.replace(
                "\t\t200000000000000000000001 = {",
                "\t\t200000000000000000000007 = {isa = PBXBuildFile; "
                "fileRef = 100000000000000000000008; };\n"
                "\t\t200000000000000000000001 = {",
                1,
            )
            self.assertIn(
                "\t\t\tfiles = (200000000000000000000004, );",
                contents,
            )
            contents = contents.replace(
                "\t\t\tfiles = (200000000000000000000004, );",
                "\t\t\tfiles = (\n"
                "\t\t\t\t200000000000000000000004,\n"
                "\t\t\t\t200000000000000000000007,\n"
                "\t\t\t);",
                1,
            )
            pbxproj.write_text(contents, encoding="utf-8")
            outside = Path(directory) / "Unsafe.framework"
            outside.mkdir()
            (outside / "Unsafe").write_bytes(b"framework\n")
            (root / "App" / "Unsafe.framework").symlink_to(
                outside,
                target_is_directory=True,
            )
            with self.assertRaisesRegex(project_inventory.PlanError, "symlink"):
                project_inventory.build_project_inventory(
                    project,
                    scheme_name="Focus",
                )

    def test_shell_phase_build_files_are_rejected_before_target_reuse_can_escape(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            _, project = self.copied_mini_fixture(directory)
            pbxproj = project / "project.pbxproj"
            contents = pbxproj.read_text(encoding="utf-8")
            marker = (
                "\t\t300000000000000000000001 = {\n"
                "\t\t\tisa = PBXShellScriptBuildPhase;\n"
                "\t\t\tfiles = ();"
            )
            self.assertIn(marker, contents)
            pbxproj.write_text(
                contents.replace(
                    marker,
                    "\t\t300000000000000000000001 = {\n"
                    "\t\t\tisa = PBXShellScriptBuildPhase;\n"
                    "\t\t\tfiles = (200000000000000000000001, );",
                    1,
                ),
                encoding="utf-8",
            )
            with self.assertRaisesRegex(
                project_inventory.PlanError,
                "target build phases 300000000000000000000001 and "
                "300000000000000000000005 repeat PBXBuildFile "
                "200000000000000000000001",
            ):
                project_inventory.build_project_inventory(
                    project,
                    scheme_name="Focus",
                )

        with tempfile.TemporaryDirectory() as directory:
            _, project = self.copied_mini_fixture(directory)
            pbxproj = project / "project.pbxproj"
            contents = pbxproj.read_text(encoding="utf-8")
            phase_marker = (
                "\t\t300000000000000000000001 = {\n"
                "\t\t\tisa = PBXShellScriptBuildPhase;\n"
                "\t\t\tfiles = ();"
            )
            build_marker = "\t\t200000000000000000000001 = {"
            self.assertIn(phase_marker, contents)
            self.assertIn(build_marker, contents)
            contents = contents.replace(
                phase_marker,
                "\t\t300000000000000000000001 = {\n"
                "\t\t\tisa = PBXShellScriptBuildPhase;\n"
                "\t\t\tfiles = (200000000000000000000007, );",
                1,
            ).replace(
                build_marker,
                "\t\t200000000000000000000007 = {isa = PBXBuildFile; "
                "fileRef = 100000000000000000000001; };\n"
                + build_marker,
                1,
            )
            pbxproj.write_text(contents, encoding="utf-8")
            with self.assertRaisesRegex(
                project_inventory.PlanError,
                "shell phase 300000000000000000000001 contains unsupported "
                "PBXBuildFile inputs: 200000000000000000000007",
            ):
                project_inventory.build_project_inventory(
                    project,
                    scheme_name="Focus",
                )

    def test_framework_phase_rejects_distinct_build_files_for_one_product(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory) / "mini"
            shutil.copytree(MINI_FIXTURE, root)
            project = root / "Blockzilla.xcodeproj"
            pbxproj = project / "project.pbxproj"
            contents = pbxproj.read_text(encoding="utf-8")
            object_marker = (
                "\t\t200000000000000000000005 = {isa = PBXBuildFile; "
                "fileRef = 100000000000000000000005; };"
            )
            self.assertIn(object_marker, contents)
            contents = contents.replace(
                object_marker,
                "\t\t200000000000000000000007 = {isa = PBXBuildFile; "
                "productRef = 600000000000000000000001; };\n" + object_marker,
                1,
            )
            phase_marker = "\t\t\tfiles = (200000000000000000000004, );"
            self.assertIn(phase_marker, contents)
            contents = contents.replace(
                phase_marker,
                "\t\t\tfiles = (\n"
                "\t\t\t\t200000000000000000000004,\n"
                "\t\t\t\t200000000000000000000007,\n"
                "\t\t\t);",
                1,
            )
            pbxproj.write_text(contents, encoding="utf-8")
            with self.assertRaisesRegex(project_inventory.PlanError, "more than once"):
                project_inventory.build_project_inventory(
                    project,
                    scheme_name="Focus",
                )

    def test_framework_phase_rejects_distinct_build_files_for_one_local_path(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory) / "mini"
            shutil.copytree(MINI_FIXTURE, root)
            project = root / "Blockzilla.xcodeproj"
            framework = root / "App" / "Local.framework"
            framework.mkdir()
            (framework / "Local").write_bytes(b"framework\n")
            pbxproj = project / "project.pbxproj"
            contents = pbxproj.read_text(encoding="utf-8")
            child_marker = "\t\t\t\t100000000000000000000005 /* Resource.txt */,"
            self.assertIn(child_marker, contents)
            contents = contents.replace(
                child_marker,
                child_marker + "\n\t\t\t\t100000000000000000000008 /* Local.framework */,",
                1,
            )
            object_marker = "\t\t100000000000000000000001 = {"
            self.assertIn(object_marker, contents)
            contents = contents.replace(
                object_marker,
                "\t\t100000000000000000000008 = {\n"
                "\t\t\tisa = PBXFileReference;\n"
                "\t\t\texplicitFileType = wrapper.framework;\n"
                "\t\t\tpath = Local.framework;\n"
                "\t\t\tsourceTree = \"<group>\";\n"
                "\t\t};\n"
                + object_marker,
                1,
            )
            build_marker = "\t\t200000000000000000000001 = {"
            self.assertIn(build_marker, contents)
            contents = contents.replace(
                build_marker,
                "\t\t200000000000000000000007 = {isa = PBXBuildFile; "
                "fileRef = 100000000000000000000008; };\n"
                "\t\t200000000000000000000008 = {isa = PBXBuildFile; "
                "fileRef = 100000000000000000000008; };\n"
                + build_marker,
                1,
            )
            phase_marker = "\t\t\tfiles = (200000000000000000000004, );"
            self.assertIn(phase_marker, contents)
            contents = contents.replace(
                phase_marker,
                "\t\t\tfiles = (\n"
                "\t\t\t\t200000000000000000000004,\n"
                "\t\t\t\t200000000000000000000007,\n"
                "\t\t\t\t200000000000000000000008,\n"
                "\t\t\t);",
                1,
            )
            pbxproj.write_text(contents, encoding="utf-8")
            with self.assertRaisesRegex(project_inventory.PlanError, "more than once"):
                project_inventory.build_project_inventory(
                    project,
                    scheme_name="Focus",
                )

    def test_copy_phase_rejects_distinct_build_files_for_one_product(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory) / "mini"
            shutil.copytree(MINI_FIXTURE, root)
            project = root / "Blockzilla.xcodeproj"
            pbxproj = project / "project.pbxproj"
            contents = pbxproj.read_text(encoding="utf-8")
            object_marker = "\t\t200000000000000000000006 = {"
            self.assertIn(object_marker, contents)
            contents = contents.replace(
                object_marker,
                "\t\t200000000000000000000007 = {\n"
                "\t\t\tisa = PBXBuildFile;\n"
                "\t\t\tfileRef = 100000000000000000000007;\n"
                "\t\t};\n" + object_marker,
                1,
            )
            phase_marker = "\t\t\tfiles = (200000000000000000000006, );"
            self.assertIn(phase_marker, contents)
            contents = contents.replace(
                phase_marker,
                "\t\t\tfiles = (\n"
                "\t\t\t\t200000000000000000000006,\n"
                "\t\t\t\t200000000000000000000007,\n"
                "\t\t\t);",
                1,
            )
            pbxproj.write_text(contents, encoding="utf-8")
            with self.assertRaisesRegex(project_inventory.PlanError, "more than once"):
                project_inventory.build_project_inventory(
                    project,
                    scheme_name="Focus",
                )

    def test_framework_phases_reject_repeated_build_file_target_wide(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            _, project = self.copied_mini_fixture(directory)
            pbxproj = project / "project.pbxproj"
            contents = self.add_target_phase(
                pbxproj.read_text(encoding="utf-8"),
                "300000000000000000000009",
                "PBXFrameworksBuildPhase",
                ["200000000000000000000004"],
            )
            pbxproj.write_text(contents, encoding="utf-8")
            with self.assertRaisesRegex(
                project_inventory.PlanError,
                "target build phases.*repeat PBXBuildFile 200000000000000000000004",
            ):
                project_inventory.build_project_inventory(
                    project,
                    scheme_name="Focus",
                )

    def test_framework_phases_reject_local_path_target_wide(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            root, project = self.copied_mini_fixture(directory)
            framework = root / "App" / "Local.framework"
            framework.mkdir()
            (framework / "Local").write_bytes(b"framework\n")
            pbxproj = project / "project.pbxproj"
            contents = pbxproj.read_text(encoding="utf-8")
            child_marker = "\t\t\t\t100000000000000000000005 /* Resource.txt */,"
            object_marker = "\t\t100000000000000000000001 = {"
            build_marker = "\t\t200000000000000000000001 = {"
            framework_marker = "\t\t\tfiles = (200000000000000000000004, );"
            for marker in (child_marker, object_marker, build_marker, framework_marker):
                self.assertIn(marker, contents)
            contents = contents.replace(
                child_marker,
                child_marker
                + "\n\t\t\t\t100000000000000000000008 /* Local.framework */,",
                1,
            ).replace(
                object_marker,
                "\t\t100000000000000000000008 = {\n"
                "\t\t\tisa = PBXFileReference;\n"
                "\t\t\texplicitFileType = wrapper.framework;\n"
                "\t\t\tpath = Local.framework;\n"
                "\t\t\tsourceTree = \"<group>\";\n"
                "\t\t};\n"
                + object_marker,
                1,
            ).replace(
                build_marker,
                "\t\t200000000000000000000007 = {isa = PBXBuildFile; "
                "fileRef = 100000000000000000000008; };\n"
                "\t\t200000000000000000000008 = {isa = PBXBuildFile; "
                "fileRef = 100000000000000000000008; };\n"
                + build_marker,
                1,
            ).replace(
                framework_marker,
                "\t\t\tfiles = (\n"
                "\t\t\t\t200000000000000000000004,\n"
                "\t\t\t\t200000000000000000000007,\n"
                "\t\t\t);",
                1,
            )
            contents = self.add_target_phase(
                contents,
                "300000000000000000000009",
                "PBXFrameworksBuildPhase",
                ["200000000000000000000008"],
            )
            pbxproj.write_text(contents, encoding="utf-8")
            with self.assertRaisesRegex(
                project_inventory.PlanError,
                "target frameworks phases.*Local\\.framework.*more than once",
            ):
                project_inventory.build_project_inventory(
                    project,
                    scheme_name="Focus",
                )

    def test_copy_phases_reject_repeated_build_file_target_wide(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            _, project = self.copied_mini_fixture(directory)
            pbxproj = project / "project.pbxproj"
            contents = self.add_target_phase(
                pbxproj.read_text(encoding="utf-8"),
                "300000000000000000000009",
                "PBXCopyFilesBuildPhase",
                ["200000000000000000000006"],
                "\t\t\tdstPath = \"\";\n\t\t\tdstSubfolderSpec = 13;\n",
            )
            pbxproj.write_text(contents, encoding="utf-8")
            with self.assertRaisesRegex(
                project_inventory.PlanError,
                "target build phases.*repeat PBXBuildFile 200000000000000000000006",
            ):
                project_inventory.build_project_inventory(
                    project,
                    scheme_name="Focus",
                )

    def test_copy_phases_reject_distinct_build_files_for_one_path(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            _, project = self.copied_mini_fixture(directory)
            pbxproj = project / "project.pbxproj"
            contents = pbxproj.read_text(encoding="utf-8")
            build_marker = "\t\t200000000000000000000001 = {"
            self.assertIn(build_marker, contents)
            contents = contents.replace(
                build_marker,
                "\t\t200000000000000000000007 = {isa = PBXBuildFile; "
                "fileRef = 100000000000000000000007; };\n"
                + build_marker,
                1,
            )
            contents = self.add_target_phase(
                contents,
                "300000000000000000000009",
                "PBXCopyFilesBuildPhase",
                ["200000000000000000000007"],
                "\t\t\tdstPath = \"\";\n\t\t\tdstSubfolderSpec = 13;\n",
            )
            pbxproj.write_text(contents, encoding="utf-8")
            with self.assertRaisesRegex(
                project_inventory.PlanError,
                "target copy_files phases.*Extension\\.appex.*more than once",
            ):
                project_inventory.build_project_inventory(
                    project,
                    scheme_name="Focus",
                )

    def test_distinct_framework_inputs_and_link_embed_roles_remain_valid(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            root, project = self.copied_mini_fixture(directory)
            framework = root / "App" / "Local.framework"
            framework.mkdir()
            (framework / "Local").write_bytes(b"framework\n")
            pbxproj = project / "project.pbxproj"
            contents = pbxproj.read_text(encoding="utf-8")
            child_marker = "\t\t\t\t100000000000000000000005 /* Resource.txt */,"
            object_marker = "\t\t100000000000000000000001 = {"
            build_marker = "\t\t200000000000000000000001 = {"
            copy_marker = "\t\t\tfiles = (200000000000000000000006, );"
            for marker in (child_marker, object_marker, build_marker, copy_marker):
                self.assertIn(marker, contents)
            contents = contents.replace(
                child_marker,
                child_marker
                + "\n\t\t\t\t100000000000000000000008 /* Local.framework */,",
                1,
            ).replace(
                object_marker,
                "\t\t100000000000000000000008 = {\n"
                "\t\t\tisa = PBXFileReference;\n"
                "\t\t\texplicitFileType = wrapper.framework;\n"
                "\t\t\tpath = Local.framework;\n"
                "\t\t\tsourceTree = \"<group>\";\n"
                "\t\t};\n"
                + object_marker,
                1,
            ).replace(
                build_marker,
                "\t\t200000000000000000000007 = {isa = PBXBuildFile; "
                "fileRef = 100000000000000000000008; };\n"
                "\t\t200000000000000000000008 = {isa = PBXBuildFile; "
                "fileRef = 100000000000000000000008; };\n"
                + build_marker,
                1,
            ).replace(
                copy_marker,
                "\t\t\tfiles = (\n"
                "\t\t\t\t200000000000000000000006,\n"
                "\t\t\t\t200000000000000000000008,\n"
                "\t\t\t);",
                1,
            )
            contents = self.add_target_phase(
                contents,
                "300000000000000000000009",
                "PBXFrameworksBuildPhase",
                ["200000000000000000000007"],
            )
            pbxproj.write_text(contents, encoding="utf-8")
            inventory = project_inventory.build_project_inventory(
                project,
                scheme_name="Focus",
            )
            framework_phases = [
                phase for phase in inventory["build_phases"]
                if phase["kind"] == "frameworks"
            ]
            self.assertEqual(len(framework_phases), 2)
            self.assertEqual(
                [item["path"] for item in framework_phases[1]["items"]],
                ["App/Local.framework"],
            )
            copy_phase = next(
                phase for phase in inventory["build_phases"]
                if phase["kind"] == "copy_files"
            )
            self.assertEqual(
                [item["path"] for item in copy_phase["files"]],
                ["Extension.appex", "App/Local.framework"],
            )

    def test_shared_scheme_parent_traversal_escape_is_rejected(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            root, project = self.copied_modern_fixture(directory)
            outside = Path(directory) / "Outside.xcscheme"
            shutil.copyfile(MODERN_SCHEME, outside)
            traversing_path = project / ".." / ".." / outside.name
            self.assertFalse(outside.resolve().is_relative_to(root.resolve()))
            self.assertEqual(traversing_path.resolve(), outside.resolve())
            with self.assertRaisesRegex(
                project_inventory.PlanError,
                "shared scheme must be inside the project source root",
            ):
                project_inventory.build_project_inventory(
                    project,
                    scheme_name=os.fspath(traversing_path),
                )

    def test_nonexistent_explicit_scheme_is_rejected_as_plan_error(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            _, project = self.copied_modern_fixture(directory)
            missing = (
                project
                / "xcshareddata"
                / "xcschemes"
                / "Missing.xcscheme"
            )
            with self.assertRaisesRegex(
                project_inventory.PlanError,
                "cannot inspect shared scheme path.*Missing\\.xcscheme",
            ):
                project_inventory.build_project_inventory(
                    project,
                    scheme_name=os.fspath(missing),
                )

    def test_shared_scheme_symlink_escape_is_rejected_as_plan_error(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            root, project = self.copied_modern_fixture(directory)
            scheme = (
                project
                / "xcshareddata"
                / "xcschemes"
                / "ModernApp.xcscheme"
            )
            outside = Path(directory) / "Outside.xcscheme"
            scheme.rename(outside)
            scheme.symlink_to(outside)
            with self.assertRaisesRegex(
                project_inventory.PlanError,
                "shared scheme must be inside the project source root",
            ):
                self.inventory(project)


if __name__ == "__main__":
    unittest.main()
