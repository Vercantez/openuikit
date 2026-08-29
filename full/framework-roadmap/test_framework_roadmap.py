#!/usr/bin/env python3

from __future__ import annotations

import hashlib
import json
import os
from pathlib import Path
import subprocess
import tempfile
import unittest
from unittest.mock import patch

import framework_roadmap as roadmap


class ImportParsingTests(unittest.TestCase):
    def test_swift_attributes_selective_imports_and_comments(self) -> None:
        source = b'''
import Foundation
@_exported import SwiftUI
public import Combine
import struct UniformTypeIdentifiers.UTType
// import FakeLine
/*
import FakeBlock
/* import FakeNested */
*/
let value = "// import FakeString"
let raw = #"not an import"#
let multiline = """
import FakeMultiline
"""
'''
        self.assertEqual(
            [hit.module for hit in roadmap.extract_imports("Feature.swift", source)],
            ["Foundation", "SwiftUI", "Combine", "UniformTypeIdentifiers"],
        )

    def test_objective_c_umbrella_and_module_imports(self) -> None:
        source = b"""
#import <UIKit/UIKit.h>
# include <WebKit/WKWebView.h>
@import AuthenticationServices;
#import "LocalThing.h"
// #import <Fake/Fake.h>
"""
        self.assertEqual(
            [hit.module for hit in roadmap.extract_imports("Feature.m", source)],
            ["UIKit", "WebKit", "AuthenticationServices"],
        )


class PolicyTests(unittest.TestCase):
    def test_shipping_path_filter_is_explicit(self) -> None:
        self.assertEqual(roadmap.is_shipping_source("App/UI/View.swift"), (True, None))
        self.assertEqual(
            roadmap.is_shipping_source("AppTests/UI/View.swift"),
            (False, "non-shipping-directory"),
        )
        self.assertEqual(
            roadmap.is_shipping_source("App/UI/ViewTests.swift"),
            (False, "test-source-filename"),
        )
        self.assertEqual(
            roadmap.is_shipping_source("Library/Sources/LibraryTestHelpers/Stub.swift"),
            (False, "non-shipping-directory"),
        )
        self.assertEqual(
            roadmap.is_shipping_source(".claude/templates/Example.swift"),
            (False, "hidden-tooling-directory"),
        )
        self.assertEqual(
            roadmap.is_shipping_source("README.md"),
            (False, "unsupported-extension"),
        )

    def test_classification_does_not_guess_apple_by_prefix(self) -> None:
        self.assertEqual(roadmap.classify_module("SwiftUI")[:2], ("apple_first_party", "high"))
        self.assertEqual(roadmap.classify_module("QuartzCore")[:2], ("apple_first_party", "high"))
        for module in ("AppKit", "Cocoa", "WatchKit", "XCTest"):
            self.assertEqual(
                roadmap.classify_module(module)[:2],
                ("apple_non_ios_or_developer", "high"),
            )
        for module in (
            "FoundationEssentials",
            "FoundationNetworking",
            "FoundationXML",
            "PackageDescription",
        ):
            self.assertEqual(
                roadmap.classify_module(module)[:2],
                ("swift_toolchain", "high"),
            )
        self.assertEqual(
            roadmap.classify_module("CoreCompanyFeature")[:2],
            ("project_or_third_party", "medium"),
        )
        self.assertEqual(roadmap.classify_module("_PrivateMaybe")[:2], ("uncertain", "low"))
        self.assertEqual(roadmap.classify_module("Watchkit")[:2], ("uncertain", "low"))

    def test_runtime_port_allowlist_excludes_non_iphoneos_modules(self) -> None:
        self.assertTrue(
            {"SwiftUI", "UIKit", "WebKit"}.issubset(
                roadmap.APPLE_IPHONEOS_FRAMEWORK_MODULES
            )
        )
        self.assertTrue(
            roadmap.APPLE_IPHONEOS_FRAMEWORK_MODULES.isdisjoint(
                roadmap.APPLE_NON_IOS_OR_DEVELOPER_MODULES
            )
        )
        self.assertTrue(
            roadmap.APPLE_IPHONEOS_FRAMEWORK_MODULES.isdisjoint(
                {"FoundationEssentials", "FoundationNetworking", "FoundationXML"}
            )
        )

    def test_canonical_ranking_is_iphoneos_runtime_only(self) -> None:
        artifact = json.loads(
            (Path(__file__).resolve().parent / "framework-roadmap.json").read_text(
                encoding="utf-8"
            )
        )
        rankings = artifact["iphoneos_runtime_port_candidate_rankings"]
        ranked = set(rankings["by_app_coverage"])
        self.assertEqual(
            len(ranked),
            artifact["summary"]["iphoneos_runtime_port_candidate_count"],
        )
        self.assertTrue({"SwiftUI", "UIKit", "Foundation"}.issubset(ranked))
        self.assertTrue(
            ranked.isdisjoint(
                {
                    "AppKit", "Cocoa", "WatchKit", "XCTest",
                    "FoundationEssentials", "FoundationNetworking",
                    "FoundationXML", "PackageDescription",
                }
            )
        )


class GitObjectTests(unittest.TestCase):
    def git(self, repo: Path, *args: str) -> bytes:
        return subprocess.check_output(["git", "-C", str(repo), *args])

    def test_tree_and_blob_scan_ignores_dirty_worktree(self) -> None:
        with tempfile.TemporaryDirectory() as temporary:
            repo = Path(temporary) / "app"
            repo.mkdir()
            self.git(repo, "init", "-q")
            (repo / "App.swift").write_text("import Foundation\n", encoding="utf-8")
            (repo / "AppTests").mkdir()
            (repo / "AppTests" / "Ignored.swift").write_text("import XCTest\n", encoding="utf-8")
            self.git(repo, "add", ".")
            self.git(
                repo,
                "-c",
                "user.name=Roadmap Test",
                "-c",
                "user.email=roadmap@example.invalid",
                "commit",
                "-qm",
                "fixture",
            )
            pin = self.git(repo, "rev-parse", "HEAD").decode().strip()
            sources, counts = roadmap.list_tree_sources(repo, pin)
            self.assertEqual([source.path for source in sources], ["App.swift"])
            self.assertEqual(counts["included"], 1)
            self.assertEqual(counts["non-shipping-directory"], 1)

            (repo / "App.swift").write_text("import SwiftUI\n", encoding="utf-8")
            hits = roadmap.read_blob_imports(repo, sources)
            self.assertEqual([hit.module for hit in hits], ["Foundation"])
            self.assertEqual(
                roadmap.source_manifest_digest(sources),
                hashlib.sha256(
                    b"App.swift\0" + sources[0].oid.encode("ascii") + b"\0"
                ).hexdigest(),
            )

            with patch.dict(
                os.environ,
                {
                    "GIT_DIR": "/tmp/roadmap-decoy",
                    "GIT_REPLACE_REF_BASE": "refs/replace-decoy/",
                    "PATH": "/tmp/fake-bin",
                },
                clear=False,
            ):
                isolated_sources, _ = roadmap.list_tree_sources(repo, pin)
                isolated_hits = roadmap.read_blob_imports(repo, isolated_sources)
            self.assertEqual(isolated_sources, sources)
            self.assertEqual([hit.module for hit in isolated_hits], ["Foundation"])

    def test_canonical_json_is_stable_and_newline_terminated(self) -> None:
        value = {"z": 2, "a": [1]}
        first = roadmap.canonical_json(value)
        second = roadmap.canonical_json(value)
        self.assertEqual(first, second)
        self.assertTrue(first.endswith(b"\n"))
        self.assertEqual(json.loads(first), value)


if __name__ == "__main__":
    unittest.main()
