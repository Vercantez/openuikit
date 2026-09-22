#!/usr/bin/env python3
"""Route (b) iOS target: curated SDK + generated-manifest plumbing.

docs/agent_reports/ios-target-route.md. The unit tests build fake SDK trees;
the live tests read Xcode's iPhoneSimulator SDK and skip without it.
"""
from __future__ import annotations

import json
import os
import shutil
import subprocess
import sys
import tempfile
import unittest
from pathlib import Path

HERE = Path(__file__).resolve().parent
sys.path.insert(0, str(HERE))

import ios_target_sdk as sdkmod  # noqa: E402
import xcodeproj_to_package as ingest  # noqa: E402

UIKIT = HERE.parent.parent
FIXTURE = HERE / "fixtures" / "MiniApp.xcodeproj"


def _live_sdk() -> Path | None:
    if shutil.which("xcrun") is None:
        return None
    try:
        return sdkmod.default_sdk()
    except (subprocess.CalledProcessError, OSError):
        return None


LIVE_SDK = _live_sdk()


def _framework(sdk: Path, name: str, header: str = "", interface: str | None = None) -> None:
    fw = sdk / "System/Library/Frameworks" / f"{name}.framework"
    (fw / "Headers").mkdir(parents=True)
    (fw / "Headers" / f"{name}.h").write_text(header)
    if interface is not None:
        mod = fw / "Modules" / f"{name}.swiftmodule"
        mod.mkdir(parents=True)
        (mod / "arm64-apple-ios-simulator.swiftinterface").write_text(interface)


def _fake_sdk(root: Path) -> Path:
    sdk = root / "iPhoneSimulator26.1.sdk"
    (sdk / "usr/lib/swift/Swift.swiftmodule").mkdir(parents=True)
    (sdk / "usr/include").mkdir(parents=True)
    (sdk / "SDKSettings.json").write_text('{"Version": "26.1"}')
    _framework(sdk, "UIKit", "#import <Foundation/Foundation.h>\n#import <QuartzCore/QuartzCore.h>\n")
    _framework(sdk, "SwiftUI", "", "import Swift\nimport UIKit\n")
    _framework(sdk, "Foundation", "#include <CoreFoundation/CoreFoundation.h>\n")
    _framework(sdk, "CoreFoundation")
    _framework(sdk, "QuartzCore", "#import <Foundation/Foundation.h>\n")
    # direct header import, @import, a Swift-only import, and a transitive one
    _framework(sdk, "AVKit", "#import <UIKit/UIKit.h>\n")
    _framework(sdk, "MessageUI", "@import UIKit;\n")
    _framework(sdk, "WidgetKit", "", "@_exported import SwiftUI\n")
    _framework(sdk, "IntentsUI", "#if TARGET_OS_IOS\n#  import <AVKit/AVKit.h>\n#endif\n")
    _framework(sdk, "AVFoundation", "#import <QuartzCore/QuartzCore.h>\n", "import Foundation\n")
    return sdk


class CuratedSDKUnitTests(unittest.TestCase):
    def test_closure_removes_ui_stack_and_every_importer(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            sdk = _fake_sdk(Path(tmp))
            removed = sdkmod.removal_closure(sdkmod.scan_sdk(sdk))
        self.assertEqual(set(removed), {"UIKit", "SwiftUI", "AppKit", "AVKit", "MessageUI", "WidgetKit", "IntentsUI"})
        self.assertEqual(removed["AVKit"], "imports UIKit")
        self.assertEqual(removed["MessageUI"], "imports UIKit")
        self.assertEqual(removed["WidgetKit"], "imports SwiftUI")
        self.assertEqual(removed["IntentsUI"], "imports AVKit")

    def test_farm_omits_removed_and_never_touches_the_sdk(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            sdk = _fake_sdk(Path(tmp))
            before = sorted(str(p.relative_to(sdk)) for p in sdk.rglob("*"))
            out = Path(tmp) / "out"
            manifest = sdkmod.curate(sdk, out)
            root = Path(manifest["curated_sdk"])
            self.assertEqual(root, out / "iPhoneSimulator26.1.sdk")
            frameworks = sorted(p.name for p in (root / "System/Library/Frameworks").iterdir())
            self.assertEqual(frameworks, ["AVFoundation.framework", "CoreFoundation.framework",
                                          "Foundation.framework", "QuartzCore.framework"])
            # every kept entry is a link into the real SDK
            self.assertTrue((root / "System/Library/Frameworks/Foundation.framework").is_symlink())
            self.assertTrue((root / "SDKSettings.json").is_symlink())
            self.assertTrue((root / "usr/lib/swift/Swift.swiftmodule").is_symlink())
            self.assertTrue((root / "usr/include").is_symlink())
            self.assertEqual(manifest["triple"], "arm64-apple-ios26.1-simulator")
            self.assertEqual(sdkmod.swift_build_flags(manifest),
                             ["--triple", "arm64-apple-ios26.1-simulator", "--sdk", str(root)])
            # reuse is a no-op; a rebuild after the farm is deleted restores it
            self.assertEqual(sdkmod.curate(sdk, out), manifest)
            sdkmod._rmtree_links(root)
            self.assertEqual(sdkmod.curate(sdk, out)["removed"], manifest["removed"])
            after = sorted(str(p.relative_to(sdk)) for p in sdk.rglob("*"))
        self.assertEqual(before, after)

    def test_cross_import_overlays_on_removed_bystanders_are_pruned(self) -> None:
        # MEASURED: Apple's Intents (kept) + OpenUIKit's module named UIKit
        # made Swift load AppIntents' cross-import overlay `_AppIntents_UIKit`
        # (removed: it imports UIKit): "no such module '_AppIntents_UIKit'".
        with tempfile.TemporaryDirectory() as tmp:
            sdk = _fake_sdk(Path(tmp))
            _framework(sdk, "AppIntents", "#import <Foundation/Foundation.h>\n", "import Foundation\n")
            cross = sdk / "System/Library/Frameworks/AppIntents.framework/Modules/AppIntents.swiftcrossimport"
            cross.mkdir(parents=True)
            (cross / "UIKit.swiftoverlay").write_text("version: 1\nmodules:\n  - name: _AppIntents_UIKit\n")
            (cross / "Foundation.swiftoverlay").write_text("version: 1\nmodules:\n  - name: _AppIntents_Foundation\n")
            _framework(sdk, "_AppIntents_UIKit", "", "import AppIntents\nimport UIKit\n")
            sub = sdk / "System/Library/SubFrameworks/UIUtilities.framework/Headers"
            sub.mkdir(parents=True)
            (sub / "UIUtilities.h").write_text("#import <UIKit/UIKit.h>\n")
            manifest = sdkmod.curate(sdk, Path(tmp) / "out")
            root = Path(manifest["curated_sdk"])
            fw = root / "System/Library/Frameworks/AppIntents.framework"
            self.assertFalse(fw.is_symlink())
            kept = root / "System/Library/Frameworks/AppIntents.framework/Modules/AppIntents.swiftcrossimport"
            self.assertEqual(sorted(p.name for p in kept.iterdir()), ["Foundation.swiftoverlay"])
            self.assertTrue((fw / "Headers").is_symlink())
            self.assertIn("UIUtilities", manifest["removed"])
            self.assertFalse((root / "System/Library/SubFrameworks/UIUtilities.framework").exists())
            self.assertEqual(manifest["pruned_cross_imports"], {"AppIntents": ["UIKit"]})
            self.assertTrue((sdk / "System/Library/Frameworks/AppIntents.framework/Modules/"
                             "AppIntents.swiftcrossimport/UIKit.swiftoverlay").is_file())

    def test_swift_import_forms(self) -> None:
        text = "@_exported import UIKit\nimport struct SwiftUI.Color\n@preconcurrency import AVKit\n  // import Nope\n"
        self.assertEqual(sdkmod.swift_imports(text), {"UIKit", "SwiftUI", "AVKit"})


@unittest.skipUnless(LIVE_SDK, "Xcode iPhoneSimulator SDK not available")
class CuratedSDKLiveTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls) -> None:
        cls.graph = sdkmod.scan_sdk(LIVE_SDK)
        cls.removed = sdkmod.removal_closure(cls.graph)

    def test_apple_ui_stack_and_its_importers_are_removed(self) -> None:
        # MEASURED (iPhoneSimulator26.1): these reach Apple's UIKit/SwiftUI.
        for name in ("UIKit", "SwiftUI", "AVKit", "MessageUI", "WebKit", "SafariServices",
                     "PassKit", "StoreKit", "LinkPresentation", "PhotosUI", "IntentsUI", "WidgetKit"):
            self.assertIn(name, self.removed, name)

    def test_foundation_layer_is_kept(self) -> None:
        for name in ("Foundation", "CoreFoundation", "CoreGraphics", "QuartzCore", "AVFoundation",
                     "AVFAudio", "CoreData", "Combine", "Dispatch", "ObjectiveC", "CoreText",
                     "UserNotifications", "UniformTypeIdentifiers", "Network", "LocalAuthentication"):
            self.assertIn(name, self.graph, name)
            self.assertNotIn(name, self.removed, name)

    def test_sdk_supplied_products_exist_in_the_curated_sdk(self) -> None:
        import spm_app_chain
        self.assertEqual(spm_app_chain.IOS_SDK_SUPPLIED_PRODUCTS, ingest.IOS_SDK_SUPPLIED_PRODUCTS)
        for name in ingest.IOS_SDK_SUPPLIED_PRODUCTS:
            self.assertIn(name, self.graph, name)
            self.assertNotIn(name, self.removed, name)

    def test_every_removed_framework_the_port_supplies_is_linked_on_ios(self) -> None:
        ported_and_removed = {
            name for name, product in ingest.PORTED_PRODUCTS.items()
            if name in self.removed and name not in ("UIKit", "SwiftUI")
        }
        self.assertEqual(ported_and_removed,
                         set(ingest.IOS_LINKED_PORT_PRODUCTS) | set(ingest.UNCONDITIONAL_PORT_PRODUCTS))


class GeneratedManifestTests(unittest.TestCase):
    def setUp(self) -> None:
        self.graph = ingest.ProjectGraph(FIXTURE)
        self.tid, self.target = self.graph.pick_app_target("MiniApp")
        self.manifest = ingest.build_manifest(self.graph, self.tid, self.target)

    def _emit(self) -> str:
        with tempfile.TemporaryDirectory() as tmp:
            out = Path(tmp) / "pkg"
            ingest.emit_tree(self.graph, self.manifest, out, UIKIT)
            return (out / "Package.swift").read_text()

    def test_platforms_include_ios_floor_matching_openuikit(self) -> None:
        text = self._emit()
        self.assertIn('platforms: [.macOS(.v11), .iOS("26.0")]', text)
        self.assertIn('.iOS("26.0")', (UIKIT / "Package.swift").read_text())

    def test_darwin_source_products_are_linked_on_ios(self) -> None:
        self.manifest["imports"].append(ingest.classify_module("Gridicons"))
        text = self._emit()
        self.assertIn('.product(name: "Gridicons", package: "OpenUIKit", condition: .when(platforms: [.macOS, .iOS]))', text)
        self.assertNotIn(".when(platforms: [.macOS]))", text)

    def test_port_products_whose_sdk_framework_is_removed_link_on_ios(self) -> None:
        for name in ("MessageUI", "PhotosUI", "LinkPresentation"):
            self.manifest["imports"].append(ingest.classify_module(name))
        text = self._emit()
        for name in sorted(ingest.IOS_LINKED_PORT_PRODUCTS):
            self.assertIn(
                f'.product(name: "{name}", package: "OpenUIKit", condition: .when(platforms: [.linux, .iOS]))',
                text, name)

    def test_generated_header_dirs_cover_the_ios_simulator_triple(self) -> None:
        self.assertIn(".build/arm64-apple-ios-simulator/debug/OpenUIKit.build/include", ingest.GENERATED_HEADER_DIRS)
        self.assertIn(".build/arm64-apple-ios-simulator/release/OpenUIKit.build/include", ingest.GENERATED_HEADER_DIRS)


class ChainPlumbingTests(unittest.TestCase):
    """spm_app_chain.py / chain_census.py carry the iOS target too."""

    def test_chain_manifest_declares_the_ios_floor(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            (root / "corpus/App").mkdir(parents=True)
            (root / "corpus/App/A.swift").write_text("import UIKit\n")
            (root / "checkouts").mkdir()
            spec = root / "chain.json"
            spec.write_text(json.dumps({"name": "Chain", "targets": [
                {"name": "App", "root": "corpus", "path": "App", "openuikit": ["UIKit"]}]}))
            p = subprocess.run([sys.executable, str(HERE / "spm_app_chain.py"), str(spec),
                                "--out", str(root / "out"), "--corpus", str(root / "corpus"),
                                "--checkouts", str(root / "checkouts"), "--openuikit", str(UIKIT)],
                               capture_output=True, text=True)
            self.assertEqual(p.returncode, 0, p.stderr)
            manifest = (root / "out/Package.swift").read_text()
        self.assertIn(ingest.IOS_PLATFORM_FLOOR, manifest)

    def test_chain_links_sdk_supplied_products_only_off_ios(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            (root / "corpus/App").mkdir(parents=True)
            (root / "checkouts").mkdir()
            spec = root / "chain.json"
            spec.write_text(json.dumps({"name": "Chain", "targets": [
                {"name": "App", "root": "corpus", "path": "App", "openuikit": ["UIKit", "MobileCoreServices"]}]}))
            subprocess.run([sys.executable, str(HERE / "spm_app_chain.py"), str(spec),
                            "--out", str(root / "out"), "--corpus", str(root / "corpus"),
                            "--checkouts", str(root / "checkouts"), "--openuikit", str(UIKIT)],
                           check=True, capture_output=True)
            manifest = (root / "out/Package.swift").read_text()
        self.assertIn('.product(name: "UIKit", package: "OpenUIKit")', manifest)
        self.assertIn('.product(name: "MobileCoreServices", package: "OpenUIKit", '
                      'condition: .when(platforms: [.macOS, .linux]))', manifest)

    def test_census_passes_the_ios_build_flags(self) -> None:
        import chain_census
        cmd = chain_census.build_command("App", 4, ["--triple", "arm64-apple-ios26.1-simulator", "--sdk", "/x"])
        self.assertEqual(cmd, ["swift", "build", "--target", "App", "-j", "4",
                               "--triple", "arm64-apple-ios26.1-simulator", "--sdk", "/x"])
        self.assertEqual(chain_census.build_command("App", 2, []), ["swift", "build", "--target", "App", "-j", "2"])

    def test_build_subcommand_runs_swift_build_for_the_ios_triple(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            sdk = _fake_sdk(Path(tmp))
            calls = []
            rc = sdkmod.main(["--sdk", str(sdk), "--out", str(Path(tmp) / "c"), "--build",
                              str(Path(tmp)), "--target", "App"],
                             runner=lambda cmd, cwd: calls.append((cmd, cwd)) or 0)
        self.assertEqual(rc, 0)
        self.assertEqual(calls, [(["swift", "build", "--target", "App", "--triple",
                                   "arm64-apple-ios26.1-simulator", "--sdk",
                                   str(Path(tmp) / "c" / "iPhoneSimulator26.1.sdk")], str(Path(tmp)))])


if __name__ == "__main__":
    unittest.main()
