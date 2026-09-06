#!/usr/bin/env python3
"""Unit tests for Tools/ingest/xcodeproj_to_package.py.

Parser tests run against a committed MiniApp fixture. Target/source/resource
tests also run against the three ladder clones under scratch/ladder-corpus
(focus-ios Blockzilla, Hackers, pocket-casts-ios podcasts) when that tree is
present — clone with full/ladder/clone_corpus.sh or copy the pinned SHAs.
"""
from __future__ import annotations

import json
import os
import sys
import tempfile
import unittest
from pathlib import Path

HERE = Path(__file__).resolve().parent
sys.path.insert(0, str(HERE))

import xcodeproj_to_package as ingest  # noqa: E402

UIKIT = HERE.parent.parent
WORKTREE = UIKIT.parent
FIXTURE = HERE / "fixtures" / "MiniApp.xcodeproj"
CORPUS = Path(os.environ.get("LADDER_CORPUS", WORKTREE / "scratch" / "ladder-corpus"))

FOCUS_PIN = "a2832521c1daa0c23419c73705ae043ed60c9791"
HACKERS_PIN = "83016de256ef5418f76ec53182d25e302a519234"
POCKET_PIN = "3b27afc6e69d56b5d7eb67579fa5e622fbeaed10"


def _git_head(repo: Path) -> str:
    import subprocess

    return subprocess.check_output(
        ["git", "-C", str(repo), "rev-parse", "HEAD"], text=True
    ).strip()


def _corpus_available() -> bool:
    return (
        (CORPUS / "focus-ios" / "focus-ios" / "Blockzilla.xcodeproj" / "project.pbxproj").is_file()
        and (CORPUS / "Hackers" / "Hackers.xcodeproj" / "project.pbxproj").is_file()
        and (CORPUS / "pocket-casts-ios" / "podcasts.xcodeproj" / "project.pbxproj").is_file()
    )


class OpenStepParserTests(unittest.TestCase):
    def test_comments_escapes_arrays_and_nested_dictionaries(self) -> None:
        value = ingest.parse_openstep(
            r"""
            // header
            {
                scalar = bare-token;
                quoted = "line\n\"two\"";
                array = (one, two, /* trailing comment */ );
                nested = { key = "https://example.invalid/path"; };
            }
            """,
            "unit-fixture",
        )
        self.assertEqual(value["scalar"], "bare-token")
        self.assertEqual(value["quoted"], 'line\n"two"')
        self.assertEqual(value["array"], ["one", "two"])
        self.assertEqual(value["nested"]["key"], "https://example.invalid/path")

    def test_duplicate_dictionary_key_is_rejected(self) -> None:
        with self.assertRaisesRegex(ingest.OpenStepError, "duplicate dictionary key"):
            ingest.parse_openstep("{ key = one; key = two; }")

    def test_unterminated_comment_is_rejected(self) -> None:
        with self.assertRaisesRegex(ingest.OpenStepError, "unterminated block comment"):
            ingest.parse_openstep("{ /* never closed")

    def test_unicode_and_octal_escapes(self) -> None:
        value = ingest.parse_openstep(r'{ a = "\U0041\101"; }')
        self.assertEqual(value["a"], "AA")


class MiniAppFixtureTests(unittest.TestCase):
    def setUp(self) -> None:
        self.graph = ingest.ProjectGraph(FIXTURE)
        self.tid, self.target = self.graph.pick_app_target(None)
        self.manifest = ingest.build_manifest(self.graph, self.tid, self.target)

    def test_picks_application_target_not_tests(self) -> None:
        self.assertEqual(self.target["name"], "MiniApp")
        self.assertEqual(self.target["productType"], ingest.APP_PRODUCT_TYPE)

    def test_explicit_target_name(self) -> None:
        tid, target = self.graph.pick_app_target("MiniAppTests")
        self.assertEqual(target["name"], "MiniAppTests")
        self.assertIn("unit-test", target["productType"])

    def test_swift_sources_exclude_ui_and_unit_tests(self) -> None:
        self.assertEqual(self.manifest["swift_sources"], ["MiniApp/AppDelegate.swift"])
        self.assertNotIn("MiniAppTests/MiniAppTests.swift", self.manifest["swift_sources"])

    def test_resources_mapped_to_port_loaders(self) -> None:
        res = self.manifest["resources"]
        self.assertEqual(res["xcassets"], ["MiniApp/Assets.xcassets"])
        self.assertEqual(res["nibs"], ["MiniApp/SwitchCell.xib"])
        self.assertEqual(res["strings"], ["MiniApp/en.lproj/Localizable.strings"])
        self.assertEqual(res["json"], ["MiniApp/config.json"])

    def test_info_plist_keys(self) -> None:
        info = self.manifest["info"]
        self.assertEqual(info["bundle_identifier"], "com.openuikit.MiniApp")
        self.assertEqual(info["display_name"], "Mini App")
        self.assertEqual(info["keys"]["CFBundleName"], "MiniApp")

    def test_snapkit_and_webkit_are_ported_products(self) -> None:
        spm = {row["name"]: row for row in self.manifest["spm"]}
        self.assertEqual(spm["SnapKit"]["class"], "UIKit-bound")
        self.assertEqual(spm["SnapKit"]["port"], "SnapKit")
        no_port = {row["name"] for row in self.manifest["no_port"]}
        self.assertNotIn("SnapKit", no_port)
        self.assertNotIn("WebKit", no_port)
        self.assertNotIn("UIKit", no_port)
        self.assertNotIn("Foundation", no_port)
        self.assertNotIn("Combine", no_port)
        self.assertNotIn("os", no_port)

    def test_combine_and_os_are_ported_products(self) -> None:
        combine = ingest.classify_module("Combine")
        self.assertEqual(combine["port"], "Combine")
        self.assertEqual(combine["class"], "Foundation-heavy")
        os_mod = ingest.classify_module("os")
        self.assertEqual(os_mod["port"], "os")
        self.assertEqual(os_mod["class"], "Foundation-heavy")

    def test_emit_package_layout(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            out = Path(tmp) / "pkg"
            ingest.emit_tree(self.graph, self.manifest, out, UIKIT)
            self.assertTrue((out / "Package.swift").is_file())
            text = (out / "Package.swift").read_text(encoding="utf-8")
            self.assertIn('.executable(name: "MiniApp", targets: ["MiniApp"])', text)
            self.assertIn(".executableTarget(", text)
            self.assertIn('.product(name: "UIKit", package: "OpenUIKit")', text)
            self.assertIn('.package(name: "OpenUIKit", path:', text)
            self.assertIn('.product(name: "OpenUIKit", package: "OpenUIKit"),', text)
            self.assertIn(
                '.product(name: "Combine", package: "OpenUIKit", condition: .when(platforms: [.linux]))',
                text,
            )
            self.assertIn(
                '.product(name: "os", package: "OpenUIKit", condition: .when(platforms: [.linux]))',
                text,
            )
            self.assertIn(
                '.product(name: "Glean", package: "OpenUIKit", condition: .when(platforms: [.linux]))',
                text,
            )
            self.assertIn(
                '.product(name: "SnapKit", package: "OpenUIKit", condition: .when(platforms: [.linux]))',
                text,
            )
            self.assertIn(
                '.product(name: "Sentry", package: "OpenUIKit", condition: .when(platforms: [.linux]))',
                text,
            )
            self.assertIn(
                '.product(name: "Fuzi", package: "OpenUIKit", condition: .when(platforms: [.linux]))',
                text,
            )
            self.assertIn(
                '.product(name: "libkern", package: "OpenUIKit", condition: .when(platforms: [.linux]))',
                text,
            )
            self.assertIn("-default-isolation", text)
            self.assertTrue((out / "Sources" / "MiniApp" / "MiniApp" / "AppDelegate.swift").is_file())
            self.assertTrue((out / "Sources" / "MiniApp" / "Resources" / "Assets.xcassets").is_dir())
            self.assertTrue((out / "Sources" / "MiniApp" / "Resources" / "nibs" / "SwitchCell.xib").is_file())
            self.assertTrue((out / "Sources" / "MiniApp" / "Resources" / "json" / "config.json").is_file())
            self.assertTrue((out / "Sources" / "MiniApp" / "Resources" / "ingest-info.json").is_file())
            dumped = json.loads((out / "source-manifest.json").read_text(encoding="utf-8"))
            self.assertEqual(dumped["info"]["bundle_identifier"], "com.openuikit.MiniApp")
            self.assertIn("nibs", dumped["generated"]["resource_map"])

    def test_json_cli_is_json_only_on_stdout(self) -> None:
        import subprocess

        proc = subprocess.run(
            [
                sys.executable,
                str(HERE / "xcodeproj_to_package.py"),
                str(FIXTURE),
                "--json",
            ],
            cwd=str(UIKIT),
            capture_output=True,
            text=True,
            check=False,
        )
        self.assertEqual(proc.returncode, 0, proc.stderr)
        payload = json.loads(proc.stdout)
        self.assertEqual(payload["target"]["name"], "MiniApp")
        self.assertTrue("target" in proc.stderr)


class XcconfigTests(unittest.TestCase):
    def test_include_and_overlay(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            (root / "base.xcconfig").write_text(
                "PRODUCT_BUNDLE_IDENTIFIER_ROOT = au.com.example.app\n"
                "PRODUCT_NAME = BaseName\n",
                encoding="utf-8",
            )
            (root / "debug.xcconfig").write_text(
                '#include "base.xcconfig"\n'
                "PRODUCT_BUNDLE_IDENTIFIER = $(PRODUCT_BUNDLE_IDENTIFIER_ROOT)\n"
                "PRODUCT_NAME = DebugName // overlay\n",
                encoding="utf-8",
            )
            parsed = ingest.parse_xcconfig(root / "debug.xcconfig")
            self.assertEqual(parsed["PRODUCT_BUNDLE_IDENTIFIER_ROOT"], "au.com.example.app")
            self.assertEqual(
                parsed["PRODUCT_BUNDLE_IDENTIFIER"], "$(PRODUCT_BUNDLE_IDENTIFIER_ROOT)"
            )
            self.assertEqual(parsed["PRODUCT_NAME"], "DebugName")
            expanded = ingest.expand_setting(parsed["PRODUCT_BUNDLE_IDENTIFIER"], parsed)
            self.assertEqual(expanded, "au.com.example.app")


@unittest.skipUnless(_corpus_available(), f"ladder corpus missing at {CORPUS}")
class FocusBlockzillaTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls) -> None:
        cls.repo = CORPUS / "focus-ios"
        # mozilla-mobile/focus-ios git root contains a nested focus-ios/ app tree.
        nested = cls.repo / "focus-ios"
        cls.git_root = cls.repo if (cls.repo / ".git").exists() else nested
        cls.head = _git_head(cls.git_root)
        cls.graph = ingest.ProjectGraph(nested / "Blockzilla.xcodeproj")
        cls.tid, cls.target = cls.graph.pick_app_target("Blockzilla")
        cls.manifest = ingest.build_manifest(
            cls.graph, cls.tid, cls.target, preferred_configuration="FocusDebug"
        )

    def test_pin(self) -> None:
        self.assertEqual(self.head, FOCUS_PIN)

    def test_target_and_info(self) -> None:
        self.assertEqual(self.target["name"], "Blockzilla")
        self.assertEqual(self.target["productType"], ingest.APP_PRODUCT_TYPE)
        self.assertEqual(self.manifest["info"]["bundle_identifier"], "org.mozilla.ios.Focus")
        self.assertTrue(self.manifest["info"]["display_name"])

    def test_swift_sources_are_the_app_not_tests(self) -> None:
        sources = self.manifest["swift_sources"]
        self.assertGreater(len(sources), 80)
        joined = " ".join(sources).lower()
        self.assertNotIn("xcuitest", joined)
        self.assertFalse(any("focus-ios-tests/" in p.lower() for p in sources))
        self.assertTrue(any(p.endswith("SettingsViewController.swift") for p in sources))

    def test_resources_include_xcassets(self) -> None:
        catalogs = self.manifest["resources"]["xcassets"]
        self.assertTrue(any(p.endswith("Assets.xcassets") for p in catalogs))

    def test_spm_ladder_classes(self) -> None:
        by_name = {row["name"]: row for row in self.manifest["spm"]}
        self.assertEqual(by_name["SnapKit"]["class"], "UIKit-bound")
        self.assertEqual(by_name["Sentry"]["class"], "ObjC")
        # Fuzi was not one of the 30 deps the ladder classified.
        self.assertEqual(by_name["Fuzi"]["class"], "unmeasured")
        self.assertEqual(by_name["SnapKit"]["port"], "SnapKit")
        self.assertEqual(by_name["Sentry"]["port"], "Sentry")
        self.assertEqual(by_name["Fuzi"]["port"], "Fuzi")
        self.assertEqual(by_name["DesignSystem"]["origin"], "local")
        self.assertEqual(by_name["DesignSystem"]["relative_path"], "BlockzillaPackage")
        self.assertEqual(by_name["UIHelpers"]["package_name"], "Focus")

    def test_no_cocoapods_or_objc_in_blockzilla(self) -> None:
        kinds = {g["kind"] for g in self.manifest["gaps"]}
        self.assertNotIn("CocoaPods", kinds)
        self.assertNotIn("Carthage", kinds)
        self.assertNotIn("ObjC sources", kinds)
        self.assertEqual(self.manifest["counts"]["objc_sources"], 0)

    def test_webkit_snapkit_sentry_are_ported(self) -> None:
        names = {row["name"] for row in self.manifest["no_port"]}
        self.assertNotIn("WebKit", names)
        self.assertNotIn("SnapKit", names)
        self.assertNotIn("Sentry", names)
        self.assertNotIn("Fuzi", names)


@unittest.skipUnless(_corpus_available(), f"ladder corpus missing at {CORPUS}")
class HackersTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls) -> None:
        cls.repo = CORPUS / "Hackers"
        cls.head = _git_head(cls.repo)
        cls.graph = ingest.ProjectGraph(cls.repo / "Hackers.xcodeproj")
        cls.tid, cls.target = cls.graph.pick_app_target("Hackers")
        cls.manifest = ingest.build_manifest(cls.graph, cls.tid, cls.target)

    def test_pin(self) -> None:
        self.assertEqual(self.head, HACKERS_PIN)

    def test_synchronized_app_sources(self) -> None:
        self.assertEqual(self.target["productType"], ingest.APP_PRODUCT_TYPE)
        sources = self.manifest["swift_sources"]
        self.assertTrue(any(p.startswith("App/") and p.endswith(".swift") for p in sources))
        self.assertFalse(any("uitest" in p.lower() for p in sources))
        self.assertFalse(any(p.startswith("Extensions/") for p in sources))

    def test_local_spm_products(self) -> None:
        by_name = {row["name"]: row for row in self.manifest["spm"]}
        for name in ("Domain", "Feed", "Data", "Networking", "Settings"):
            self.assertIn(name, by_name)
            self.assertEqual(by_name[name]["origin"], "local")
            self.assertTrue(by_name[name].get("relative_path"))
            self.assertEqual(by_name[name].get("tools_version"), "6.4")

    def test_info_plist(self) -> None:
        self.assertTrue(self.manifest["info"]["bundle_identifier"])
        plist = self.manifest["info"]["info_plist_file"]
        self.assertIsNotNone(plist)
        self.assertIn("Hackers-Info.plist", plist)

    def test_assets_catalog_from_sync_root(self) -> None:
        catalogs = self.manifest["resources"]["xcassets"]
        self.assertTrue(
            catalogs or any("Assets" in p for p in self.manifest["other_resources"]),
            f"expected Assets catalog, got {catalogs} / {self.manifest['other_resources'][:8]}",
        )


@unittest.skipUnless(_corpus_available(), f"ladder corpus missing at {CORPUS}")
class PocketCastsTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls) -> None:
        cls.repo = CORPUS / "pocket-casts-ios"
        cls.head = _git_head(cls.repo)
        cls.graph = ingest.ProjectGraph(cls.repo / "podcasts.xcodeproj")
        cls.tid, cls.target = cls.graph.pick_app_target("podcasts")
        cls.manifest = ingest.build_manifest(cls.graph, cls.tid, cls.target)

    def test_pin(self) -> None:
        self.assertEqual(self.head, POCKET_PIN)

    def test_picks_phone_app_not_watch(self) -> None:
        tid, target = self.graph.pick_app_target(None)
        self.assertEqual(target["name"], "podcasts")
        self.assertNotIn("Watch", target["name"])

    def test_xibs_map_to_nibs_bucket(self) -> None:
        nibs = self.manifest["resources"]["nibs"]
        self.assertTrue(any(p.endswith("SwitchCell.xib") for p in nibs), nibs[:20])
        self.assertTrue(any(p.endswith("DisclosureCell.xib") for p in nibs), nibs[:20])

    def test_swift_sources_exist_and_skip_tests(self) -> None:
        sources = self.manifest["swift_sources"]
        self.assertGreater(len(sources), 20)
        self.assertFalse(any("/uitests/" in p.lower() for p in sources))

    def test_no_cocoapods(self) -> None:
        kinds = {g["kind"] for g in self.manifest["gaps"]}
        self.assertNotIn("CocoaPods", kinds)

    def test_stops_on_objc_mixed_target(self) -> None:
        kinds = {g["kind"] for g in self.manifest["gaps"]}
        self.assertIn("ObjC sources", kinds)
        self.assertIn("mixed target", kinds)
        self.assertGreater(self.manifest["counts"]["objc_sources"], 0)

    def test_bundle_id_from_xcconfig(self) -> None:
        # project Debug/Release baseConfigurationReferenceAnchor →
        # config/PocketCasts.debug.xcconfig → PRODUCT_BUNDLE_IDENTIFIER_ROOT
        # au.com.shiftyjelly.podcasts (config/PocketCasts.base.xcconfig).
        self.assertEqual(
            self.manifest["info"]["bundle_identifier"],
            "au.com.shiftyjelly.podcasts",
        )

    def test_automattic_tracks_import_is_no_port(self) -> None:
        # Linux swift:6.2-noble first error with --allow-gaps is
        # podcasts/ABTest/ABTestProvider.swift:1 `no such module 'AutomatticTracks'`.
        names = {row["name"] for row in self.manifest["no_port"]}
        self.assertIn("AutomatticTracks", names)


class LibkernIngestCopyTests(unittest.TestCase):
    def test_prepends_import_libkern_for_osatomic(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            src = Path(tmp) / "ReadWriteLock.swift"
            dst = Path(tmp) / "out" / "ReadWriteLock.swift"
            src.write_text(
                "import Foundation\n"
                "func lock(_ p: UnsafeMutablePointer<Int32>) {\n"
                "    _ = OSAtomicCompareAndSwap32Barrier(0, 1, p)\n"
                "    OSSpinLockLock(p)\n"
                "}\n",
                encoding="utf-8",
            )
            ingest._copy_swift_source_with_libkern(src, dst)
            text = dst.read_text(encoding="utf-8")
            self.assertTrue(text.startswith("import libkern\nimport Foundation\n"))
            self.assertEqual(text.count("import libkern"), 1)

    def test_leaves_unrelated_swift_alone(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            src = Path(tmp) / "App.swift"
            dst = Path(tmp) / "out" / "App.swift"
            src.write_text("import Foundation\n", encoding="utf-8")
            ingest._copy_swift_source_with_libkern(src, dst)
            self.assertEqual(dst.read_text(encoding="utf-8"), "import Foundation\n")

    def test_rewrites_import_os_log(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            src = Path(tmp) / "NimbusWrapper.swift"
            dst = Path(tmp) / "out" / "NimbusWrapper.swift"
            src.write_text("import os.log\nimport Foundation\n", encoding="utf-8")
            ingest._copy_swift_source_with_libkern(src, dst)
            self.assertEqual(
                dst.read_text(encoding="utf-8"),
                "import os\nimport Foundation\n",
            )


if __name__ == "__main__":
    unittest.main()
