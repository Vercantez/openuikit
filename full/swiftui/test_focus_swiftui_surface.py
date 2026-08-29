#!/usr/bin/env python3
from __future__ import annotations

import hashlib
import json
import os
from pathlib import Path
import sys
import tempfile
import unittest
from unittest.mock import patch

HERE = Path(__file__).resolve().parent
sys.path.insert(0, str(HERE))
import focus_swiftui_surface as subject


REPOSITORY = HERE.parents[1]
FOCUS = REPOSITORY / "scratch/ladder-corpus/focus-ios/focus-ios"
PLAN = REPOSITORY / "full/xcodeplan/focus-plan.json"
CANONICAL = HERE / "focus-swiftui-surface.json"
DONORS = HERE / "donor-lock.json"


class FocusSwiftUISurfaceTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls) -> None:
        cls.contract = subject.build_contract(FOCUS, PLAN)
        cls.payload = subject.canonical_bytes(cls.contract)

    def test_regeneration_is_byte_identical(self) -> None:
        self.assertEqual(self.payload, CANONICAL.read_bytes())

    def test_reviewed_scope_denominators(self) -> None:
        membership = self.contract["membership"]
        self.assertEqual(membership["direct_importer_count"], 28)
        self.assertEqual(membership["app_link_closure_direct_importers"], 27)
        self.assertEqual(
            membership["scope_counts"],
            {"local_package": 18, "main_application": 9, "widget_extension": 1},
        )
        self.assertEqual(membership["preview_only_compile_inputs"], 4)
        self.assertEqual(membership["widget_extension_swift_source_count"], 3)
        self.assertEqual(
            membership["target_direct_import_counts"],
            {
                "Blockzilla": 9,
                "DesignSystem": 4,
                "Licenses": 1,
                "Onboarding": 11,
                "Widget": 2,
                "WidgetsExtension": 1,
            },
        )

    def test_every_expected_source_is_attested_and_imports_swiftui(self) -> None:
        files = self.contract["files"]
        self.assertEqual([item["path"] for item in files], sorted(subject.EXPECTED_IMPORTERS))
        self.assertTrue(all(item["direct_import_swiftui"] for item in files))
        self.assertTrue(all(len(item["sha256"]) == 64 for item in files))

    def test_git_attestation_ignores_ambient_redirects_and_path(self) -> None:
        with patch.dict(
            os.environ,
            {
                "GIT_DIR": "/tmp/swiftui-contract-decoy",
                "GIT_REPLACE_REF_BASE": "refs/replace-decoy/",
                "PATH": "/tmp/fake-bin",
            },
            clear=False,
        ):
            head = subject._run_git(FOCUS, "rev-parse", "HEAD").decode("ascii").strip()
        self.assertEqual(head, subject.FOCUS_COMMIT)
        self.assertEqual(set(subject.GIT_ENVIRONMENT), {
            "GIT_CONFIG_GLOBAL", "GIT_CONFIG_NOSYSTEM", "GIT_NO_REPLACE_OBJECTS",
            "GIT_OPTIONAL_LOCKS", "LANG", "LC_ALL", "PATH",
        })

    def test_contract_contains_all_focus_compile_families(self) -> None:
        aggregate = self.contract["aggregate"]["swiftui_lexical_candidates"]
        types = set(aggregate["types_and_protocols"])
        modifiers = set(aggregate["dot_call_modifiers"])
        wrappers = set(aggregate["property_wrappers"])
        self.assertTrue(
            {
                "View", "UIHostingController", "UIViewControllerRepresentable",
                "Text", "Image", "Button", "VStack", "HStack", "ZStack",
                "Form", "Section", "List", "ForEach", "NavigationLink",
                "NavigationView", "TabView", "Picker", "Toggle", "TextField",
                "ScrollView", "Gradient", "LinearGradient", "RoundedRectangle",
            }.issubset(types)
        )
        self.assertTrue(
            {
                "frame", "padding", "background", "foregroundColor", "font",
                "onAppear", "onChange", "onReceive", "simultaneousGesture",
                "tabViewStyle", "toolbar", "navigationBarTitle",
            }.issubset(modifiers)
        )
        self.assertEqual(wrappers, {"ObservedObject", "Published", "State"})

    def test_visible_module_requirements_are_derived_with_evidence(self) -> None:
        requirements = self.contract["implicit_compile_requirements"]
        modules = requirements["required_reexports_or_visible_modules"]
        evidence = requirements["visible_module_symbol_evidence"]
        self.assertEqual(
            modules,
            {
                "Combine": ["ObservableObject", "Published"],
                "CoreGraphics": ["CGFloat"],
                "CoreText": ["CTFont"],
                "Foundation": [
                    "Bundle", "Date", "NSError", "NSException",
                    "NSLocalizedString", "URL", "UserDefaults",
                ],
                "UIKit": [
                    "UIApplication", "UIColor", "UIFont", "UIImage",
                    "UIInterfaceOrientationMask", "UIPageControl",
                    "UIPasteboard", "UIViewController",
                ],
            },
        )
        self.assertEqual(
            evidence["UIKit"]["UIImage"]["files"],
            ["BlockzillaPackage/Sources/DesignSystem/Preview Files/AppImagesView.swift"],
        )
        self.assertEqual(
            evidence["UIKit"]["UIPasteboard"]["files"],
            ["Blockzilla/InternalSettings/InternalTelemetrySettingsView.swift"],
        )
        self.assertEqual(
            evidence["Foundation"]["UserDefaults"]["files"],
            ["Blockzilla/InternalSettings/InternalOnboardingSettingsView.swift"],
        )

    def test_ambiguous_surface_is_labeled_as_lexical_candidates(self) -> None:
        browser = next(
            item for item in self.contract["files"]
            if item["path"] == "Blockzilla/BrowserViewController.swift"
        )
        candidates = browser["lexical_swiftui_candidate_locations"]
        self.assertIn("bottom", candidates["leading_dot_members"])
        self.assertEqual(
            browser["lexical_syntax"]["named_dollar_projection_candidates"], 2
        )
        detail = next(
            item for item in self.contract["files"]
            if item["path"].endswith("InternalExperimentDetailView.swift")
        )
        self.assertEqual(
            detail["lexical_syntax"][
                "if_tokens_lexically_nested_under_body_braces"
            ],
            5,
        )
        boundary = self.contract["claim_boundary"]["lexical_candidates"]
        self.assertIn("not claimed", boundary)
        self.assertNotIn("framework_api_locations", browser)
        self.assertNotIn("syntax", browser)

    def test_smallest_executable_slice_is_present_without_an_overlay(self) -> None:
        widget_files = {
            item["path"]: item
            for item in self.contract["files"]
            if item["target"] == "Widget"
        }
        self.assertEqual(
            set(widget_files),
            {
                "BlockzillaPackage/Sources/Widget/Assets.swift",
                "BlockzillaPackage/Sources/Widget/SearchWidgetView.swift",
            },
        )
        self.assertEqual(widget_files["BlockzillaPackage/Sources/Widget/SearchWidgetView.swift"]["role"], "runtime_view")
        self.assertEqual(self.contract["claim_boundary"]["renderer"], "No renderer is implemented or proven by this inventory.")

    def test_preview_sources_are_compile_inputs_not_runtime_claims(self) -> None:
        previews = [item for item in self.contract["files"] if item["role"] == "preview_only"]
        self.assertEqual(len(previews), 4)
        self.assertTrue(all(item["app_link_closure"] for item in previews))
        self.assertTrue(all("Preview Files/" in item["path"] for item in previews))

    def test_focus_owned_extensions_are_not_misattributed_to_swiftui(self) -> None:
        declared = {
            item["path"]: item["focus_declared_swiftui_extensions"]
            for item in self.contract["files"]
            if item["focus_declared_swiftui_extensions"]
        }
        self.assertEqual(set(declared), set(subject.FOCUS_SWIFTUI_EXTENSIONS))
        self.assertEqual(
            declared["BlockzillaPackage/Sources/Widget/Assets.swift"],
            {"Gradient": ["quickAccessWidget"], "Image": ["logo", "magnifyingGlass"]},
        )
        self.assertEqual(
            declared["BlockzillaPackage/Sources/DesignSystem/UIColor+AppColors.swift"],
            {"Color": ["accent"]},
        )

    def test_generated_source_limit_is_explicit(self) -> None:
        boundary = self.contract["generated_source_boundary"]
        self.assertEqual(len(boundary["main_target_missing_outputs"]), 2)
        self.assertEqual(boundary["intent_derived_output"]["historical_xcode_14_2_bytes"], "unresolved")
        self.assertTrue(all(not item["direct_import_swiftui"] for item in boundary["main_target_missing_outputs"]))

    def test_lexer_ignores_comments_and_string_payloads(self) -> None:
        source = '''
        // Button Text import SwiftUI
        /* outer Text /* nested Image */ Button */
        let prose = "Form Section Toggle"
        Button { Text("ignored Image") }
        '''
        values = [token for token, _ in subject.swift_tokens(source)]
        self.assertEqual(values.count("Button"), 1)
        self.assertEqual(values.count("Text"), 1)
        self.assertNotIn("Image", values)
        self.assertNotIn("Form", values)

    def test_direct_import_derivation_uses_comment_free_tokens(self) -> None:
        source = '''
        // import FakeComment
        let prose = "import FakeString"
        @_exported import SwiftUI
        public import Combine
        import struct Foundation.URL
        '''
        self.assertEqual(
            subject._direct_imports(subject.swift_tokens(source)),
            {"Combine", "Foundation", "SwiftUI"},
        )

    def test_lexer_rejects_unterminated_layout(self) -> None:
        with self.assertRaisesRegex(subject.ContractError, "unterminated Swift block comment"):
            subject.swift_tokens("/* never closes")
        with self.assertRaisesRegex(subject.ContractError, "unterminated Swift string"):
            subject.swift_tokens('"never closes')

    def test_check_mode_rejects_tampered_canonical(self) -> None:
        with tempfile.TemporaryDirectory() as temporary:
            candidate = Path(temporary) / "contract.json"
            candidate.write_bytes(self.payload + b" ")
            self.assertEqual(
                subject.main([
                    "--focus-repo", str(FOCUS),
                    "--xcode-plan", str(PLAN),
                    "--check", str(candidate),
                ]),
                2,
            )

    def test_donor_pins_and_license_hashes_are_closed(self) -> None:
        lock = json.loads(DONORS.read_text(encoding="utf-8"))
        self.assertEqual(lock["schema"], 1)
        candidates = lock["candidates"]
        self.assertEqual(len(candidates), 6)
        self.assertEqual(len({item["repository"] for item in candidates}), 6)
        for item in candidates:
            self.assertRegex(item["revision"], r"^[0-9a-f]{40}$")
            self.assertRegex(item["license"]["sha256"], r"^[0-9a-f]{64}$")
            self.assertIn(item["license"]["spdx"], {"MIT", "Apache-2.0"})

    def test_canonical_hash_is_stable_and_nonempty(self) -> None:
        digest = hashlib.sha256(self.payload).hexdigest()
        self.assertRegex(digest, r"^[0-9a-f]{64}$")
        self.assertGreater(len(self.payload), 10_000)


if __name__ == "__main__":
    unittest.main()
