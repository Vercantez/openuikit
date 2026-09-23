"""Tests for spm_app_chain.py — fixture-only, no corpus needed."""
from __future__ import annotations

import json
import os
import subprocess
import sys
import tempfile
import unittest

HERE = os.path.dirname(os.path.abspath(__file__))
TOOL = os.path.join(HERE, "spm_app_chain.py")


class SpmAppChainTests(unittest.TestCase):
    def setUp(self):
        self.tmp = tempfile.mkdtemp(prefix="spm_app_chain_")
        self.corpus = os.path.join(self.tmp, "corpus")
        self.checkouts = os.path.join(self.tmp, "checkouts")
        self.openuikit = os.path.join(self.tmp, "uikit")
        for rel in ["corpus/App/Sources/App", "checkouts/Dep/Sources/Dep", "uikit/Sources/Shims/Svc"]:
            os.makedirs(os.path.join(self.tmp, rel))
        open(os.path.join(self.corpus, "App/Sources/App/A.swift"), "w").write("import Dep\nimport Svc\n")
        open(os.path.join(self.corpus, "App/Sources/App/Info.plist"), "w").write("<plist/>")
        open(os.path.join(self.checkouts, "Dep/Sources/Dep/D.swift"), "w").write("public let d = 1\n")
        open(os.path.join(self.openuikit, "Sources/Shims/Svc/S.swift"), "w").write("public let s = 1\n")
        self.spec = os.path.join(self.tmp, "chain.json")
        json.dump({
            "name": "Chain",
            "shims": [{"name": "Svc", "root": "openuikit", "path": "Sources/Shims/Svc"}],
            "targets": [
                {"name": "Dep", "root": "checkouts", "path": "Dep/Sources/Dep", "swift_language_mode": "5"},
                {"name": "App", "root": "corpus", "path": "App/Sources/App", "deps": ["Dep", "Svc"],
                 "openuikit": ["UIKit"], "exclude": ["Info.plist"], "resources": ["Res"]},
            ],
        }, open(self.spec, "w"))

    def run_tool(self, *extra):
        out = os.path.join(self.tmp, "out")
        p = subprocess.run([sys.executable, TOOL, self.spec, "--out", out, "--corpus", self.corpus,
                            "--checkouts", self.checkouts, "--openuikit", self.openuikit, *extra],
                           capture_output=True, text=True)
        return p, out

    def test_links_targets_and_renders_manifest(self):
        p, out = self.run_tool()
        self.assertEqual(p.returncode, 0, p.stderr)
        manifest = open(os.path.join(out, "Package.swift")).read()
        self.assertIn('swift-tools-version:6.0', manifest)
        self.assertIn('defaultLocalization: "en"', manifest)
        self.assertIn('platforms: [.macOS("13.0"), .iOS("26.0")]', manifest)
        self.assertIn('.package(name: "OpenUIKit", path: "%s")' % json.dumps(self.openuikit)[1:-1], manifest)
        self.assertIn('dependencies: ["Dep", "Svc", .product(name: "UIKit", package: "OpenUIKit")]', manifest)
        self.assertIn('exclude: ["Info.plist"]', manifest)
        self.assertIn('resources: [.process("Res")]', manifest)
        self.assertIn('swiftSettings: [.swiftLanguageMode(.v5)]', manifest)
        # shims come first so a target may depend on them
        self.assertLess(manifest.index('name: "Svc"'), manifest.index('name: "Dep"'))
        for name, src in [("App", os.path.join(self.corpus, "App/Sources/App")),
                          ("Dep", os.path.join(self.checkouts, "Dep/Sources/Dep")),
                          ("Svc", os.path.join(self.openuikit, "Sources/Shims/Svc"))]:
            link = os.path.join(out, "Sources", name)
            self.assertTrue(os.path.islink(link), name)
            self.assertEqual(os.path.realpath(link), os.path.realpath(src))
        # upstream trees untouched
        self.assertEqual(sorted(os.listdir(os.path.join(self.corpus, "App/Sources/App"))), ["A.swift", "Info.plist"])

    def test_objc_target_gets_the_clang_safariservices_module(self):
        # NetNewsWire's NetNewsWireObjC: an Objective-C target whose
        # `@import SafariServices;` must reach the Clang module with
        # `export *` (product SafariServicesObjC); a Swift target keeps the
        # Swift SafariServices product (docs/agent_reports/safari-objc.md).
        os.makedirs(os.path.join(self.corpus, "App/ObjC"))
        open(os.path.join(self.corpus, "App/ObjC/Extras.m"), "w").write("@import SafariServices;\n")
        spec = json.load(open(self.spec))
        spec["targets"][1]["openuikit"] = ["UIKit", "SafariServices"]
        spec["targets"].append({"name": "AppObjC", "root": "corpus", "path": "App/ObjC",
                                "openuikit": ["SafariServices"]})
        json.dump(spec, open(self.spec, "w"))
        p, out = self.run_tool()
        self.assertEqual(p.returncode, 0, p.stderr)
        manifest = open(os.path.join(out, "Package.swift")).read()
        targets = manifest[manifest.index(".target("):]
        objc = targets[targets.index('name: "AppObjC"'):]
        self.assertIn('.product(name: "SafariServicesObjC", package: "OpenUIKit")', objc)
        # ...with the generated-header define pair every Clang consumer gets.
        self.assertIn("-DSWIFT_CLASS_NAMED(SWIFT_NAME)=SWIFT_COMPILE_NAME(SWIFT_NAME) SWIFT_CLASS_EXTRA", objc)
        swift = targets[targets.index('name: "App",'):targets.index('name: "AppObjC"')]
        self.assertIn('.product(name: "SafariServices", package: "OpenUIKit")', swift)
        self.assertNotIn("SafariServicesObjC", swift)

    def test_executable_kind_and_linker_flags(self):
        spec = json.load(open(self.spec))
        spec["targets"][1]["kind"] = "executable"
        spec["targets"][1]["linker_flags"] = ["-Xlinker", "-sectcreate", "-Xlinker", "__TEXT"]
        json.dump(spec, open(self.spec, "w"))
        p, out = self.run_tool()
        self.assertEqual(p.returncode, 0, p.stderr)
        manifest = open(os.path.join(out, "Package.swift")).read()
        self.assertIn('.executableTarget(\n            name: "App"', manifest)
        self.assertIn('linkerSettings: [.unsafeFlags(["-Xlinker", "-sectcreate", "-Xlinker", "__TEXT"])]', manifest)
        self.assertIn('.target(\n            name: "Dep"', manifest)
        self.assertIn('.executable(name: "App", targets: ["App"])', manifest)
        self.assertIn('.library(name: "Dep", targets: ["Dep"])', manifest)

    def test_copy_writes_provenance_hashes(self):
        p, out = self.run_tool("--copy")
        self.assertEqual(p.returncode, 0, p.stderr)
        prov = json.load(open(os.path.join(out, "PROVENANCE.json")))
        self.assertEqual(set(prov), {"App", "Dep", "Svc"})
        self.assertEqual(sorted(prov["App"]["files"]), ["A.swift", "Info.plist"])
        self.assertEqual(len(prov["Dep"]["files"]["D.swift"]), 64)
        self.assertFalse(os.path.islink(os.path.join(out, "Sources", "App")))

    def test_file_list_target_overlay_platforms_and_c_settings(self):
        # An Xcode app target is a file list spanning several folders (NetNewsWire:
        # iOS/ + Shared/ minus membership exceptions), and some upstream files are
        # generated by the app's own build (SecretKey.swift from its .gyb).
        for rel, body in [("App/iOS/Main.swift", "x"), ("App/iOS/Skip.swift", "y"),
                          ("App/Shared/Util/U.swift", "z")]:
            os.makedirs(os.path.dirname(os.path.join(self.corpus, rel)), exist_ok=True)
            open(os.path.join(self.corpus, rel), "w").write(body)
        gen = os.path.join(self.tmp, "generated")
        os.makedirs(os.path.join(gen, "Dep"))
        open(os.path.join(gen, "Dep/Gen.swift"), "w").write("public let g = 1\n")
        spec = json.load(open(self.spec))
        spec["platforms"] = [".macOS(.v15)", ".iOS(.v17)"]
        spec["targets"][0]["overlay"] = {"Gen.swift": {"root": "generated", "path": "Dep/Gen.swift"}}
        spec["targets"][0]["c_settings"] = ['.headerSearchPath("include")']
        spec["targets"].append({"name": "NNW", "root": "corpus", "deps": ["Dep"],
                                "files": ["App/iOS/Main.swift", "App/Shared/Util/U.swift"]})
        json.dump(spec, open(self.spec, "w"))
        p, out = self.run_tool("--generated", gen)
        self.assertEqual(p.returncode, 0, p.stderr)
        manifest = open(os.path.join(out, "Package.swift")).read()
        # The spec's platforms are kept, except that an iOS floor below
        # OpenUIKit's .iOS("26.0") is raised to it: SwiftPM refuses a client
        # floor below a dependency's (docs/agent_reports/ios-target-route.md).
        self.assertIn('platforms: [.macOS(.v15), .iOS("26.0")]', manifest)
        self.assertIn('cSettings: [.headerSearchPath("include")]', manifest)
        nnw = os.path.join(out, "Sources", "NNW")
        self.assertFalse(os.path.islink(nnw))
        self.assertEqual(os.path.realpath(os.path.join(nnw, "App/Shared/Util/U.swift")),
                         os.path.realpath(os.path.join(self.corpus, "App/Shared/Util/U.swift")))
        self.assertTrue(os.path.islink(os.path.join(nnw, "App/iOS/Main.swift")))
        self.assertFalse(os.path.exists(os.path.join(nnw, "App/iOS/Skip.swift")))
        dep = os.path.join(out, "Sources", "Dep")
        self.assertFalse(os.path.islink(dep))
        self.assertEqual(sorted(os.listdir(dep)), ["D.swift", "Gen.swift"])
        self.assertEqual(os.path.realpath(os.path.join(dep, "D.swift")),
                         os.path.realpath(os.path.join(self.checkouts, "Dep/Sources/Dep/D.swift")))
        # upstream trees untouched
        self.assertEqual(sorted(os.listdir(os.path.join(self.checkouts, "Dep/Sources/Dep"))), ["D.swift"])
        # a missing listed file is a spec error
        spec["targets"][-1]["files"].append("App/iOS/Gone.swift")
        json.dump(spec, open(self.spec, "w"))
        p, _ = self.run_tool("--generated", gen)
        self.assertEqual(p.returncode, 1)
        self.assertIn("no such file", p.stderr)

    def test_rejects_forward_dependency_and_missing_dir(self):
        spec = json.load(open(self.spec))
        spec["targets"].reverse()
        json.dump(spec, open(self.spec, "w"))
        p, _ = self.run_tool()
        self.assertEqual(p.returncode, 1)
        self.assertIn("dependency Dep is not declared before it", p.stderr)
        spec["targets"].reverse()
        spec["targets"][0]["path"] = "Dep/Sources/Nope"
        json.dump(spec, open(self.spec, "w"))
        p, _ = self.run_tool()
        self.assertEqual(p.returncode, 1)
        self.assertIn("no such directory", p.stderr)

    def _with_generated(self, gen):
        os.makedirs(os.path.join(self.corpus, "Configs"), exist_ok=True)
        open(os.path.join(self.corpus, "Configs/Secrets.swift.example"), "w").write(
            "public enum Secrets { public static let isOSS = false }\n")
        spec = json.load(open(self.spec))
        spec["targets"][1]["generated"] = [gen]
        json.dump(spec, open(self.spec, "w"))

    def test_generated_file_overlays_without_writing_upstream(self):
        self._with_generated({"file": "Secrets.swift", "root": "corpus", "path": "Configs/Secrets.swift.example",
                              "replace": [["isOSS = false", "isOSS = true"]]})
        p, out = self.run_tool()
        self.assertEqual(p.returncode, 0, p.stderr)
        app = os.path.join(out, "Sources", "App")
        self.assertFalse(os.path.islink(app))
        self.assertTrue(os.path.islink(os.path.join(app, "A.swift")))
        self.assertIn("isOSS = true", open(os.path.join(app, "Secrets.swift")).read())
        gen = json.load(open(os.path.join(out, "GENERATED.json")))
        self.assertEqual(gen["App"][0]["file"], "Secrets.swift")
        self.assertEqual(len(gen["App"][0]["sha256"]), 64)
        # the frozen tree gained nothing
        self.assertEqual(sorted(os.listdir(os.path.join(self.corpus, "App/Sources/App"))), ["A.swift", "Info.plist"])
        # regenerating over an existing output is idempotent
        p, _ = self.run_tool()
        self.assertEqual(p.returncode, 0, p.stderr)

    def test_extra_package_product_with_module_alias(self):
        os.makedirs(os.path.join(self.openuikit, "Sources/Shims"), exist_ok=True)
        spec = json.load(open(self.spec))
        spec["packages"] = [{"name": "Shims", "root": "openuikit", "path": "Sources/Shims"}]
        spec["targets"][1]["deps"].append({"product": "KStripe", "package": "Shims", "alias": "Stripe"})
        json.dump(spec, open(self.spec, "w"))
        p, out = self.run_tool()
        self.assertEqual(p.returncode, 0, p.stderr)
        manifest = open(os.path.join(out, "Package.swift")).read()
        self.assertIn('.package(name: "Shims", path: %s)' % json.dumps(os.path.join(self.openuikit, "Sources/Shims")),
                      manifest)
        self.assertIn('.product(name: "KStripe", package: "Shims", moduleAliases: ["KStripe": "Stripe"])', manifest)
        spec["targets"][1]["deps"][-1]["package"] = "Nope"
        json.dump(spec, open(self.spec, "w"))
        p, _ = self.run_tool()
        self.assertEqual(p.returncode, 1)
        self.assertIn("package Nope is not declared", p.stderr)

    def test_openuikit_manifest_filter_builds_a_symlinked_view(self):
        open(os.path.join(self.openuikit, "Package.swift"), "w").write(
            "let targets = core + eidolon\nlet package = Package(name: \"OpenUIKit\")\n")
        spec = json.load(open(self.spec))
        spec["openuikit_manifest_filter"] = [[" + eidolon", ""]]
        json.dump(spec, open(self.spec, "w"))
        p, out = self.run_tool()
        self.assertEqual(p.returncode, 0, p.stderr)
        filtered = os.path.join(out, "OpenUIKitFiltered")
        self.assertIn("let targets = core\n", open(os.path.join(filtered, "Package.swift")).read())
        self.assertTrue(os.path.islink(os.path.join(filtered, "Sources")))
        self.assertIn('.package(name: "OpenUIKit", path: %s)' % json.dumps(filtered),
                      open(os.path.join(out, "Package.swift")).read())
        # the real manifest is untouched
        self.assertIn("+ eidolon", open(os.path.join(self.openuikit, "Package.swift")).read())
        spec["openuikit_manifest_filter"] = [["nope", ""]]
        json.dump(spec, open(self.spec, "w"))
        p, _ = self.run_tool()
        self.assertEqual(p.returncode, 1)

    def test_macos_deployment_follows_spec(self):
        # ios-oss deploys iOS 18; the Apple-toolchain chain maps it to macOS 15.
        spec = json.load(open(self.spec))
        spec["macos_deployment"] = "15.0"
        json.dump(spec, open(self.spec, "w"))
        p, out = self.run_tool()
        self.assertEqual(p.returncode, 0, p.stderr)
        self.assertIn('platforms: [.macOS("15.0"), .iOS("26.0")]', open(os.path.join(out, "Package.swift")).read())

    def test_generated_substitution_must_match(self):
        self._with_generated({"file": "Secrets.swift", "root": "corpus", "path": "Configs/Secrets.swift.example",
                              "replace": [["isOSS = maybe", "isOSS = true"]]})
        p, _ = self.run_tool()
        self.assertEqual(p.returncode, 1)
        self.assertIn("substitution", p.stderr)


if __name__ == "__main__":
    unittest.main()
