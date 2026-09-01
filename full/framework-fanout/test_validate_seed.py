#!/usr/bin/env python3
"""Unit tests for the framework fan-out validator."""

from __future__ import annotations

import hashlib
import json
import os
import tempfile
import unittest
from pathlib import Path

from validate_seed import Validator


def digest(path: Path) -> str:
    return hashlib.sha256(path.read_bytes()).hexdigest()


class Fixture:
    def __init__(self, root: Path) -> None:
        self.root = root
        self.framework = root / "full" / "tinykit"
        self.reference = self.framework / "reference"
        self.graph_dir = self.reference / "symbol-graphs"
        self.agent_tests = self.framework / "tests" / "agent"
        self.acceptance = self.framework / "tests" / "acceptance"
        self.graph_dir.mkdir(parents=True)
        self.agent_tests.mkdir(parents=True)
        self.acceptance.mkdir(parents=True)
        (root / "full" / "framework-fanout").mkdir(parents=True)
        (root / "full" / "framework-roadmap").mkdir(parents=True)

    def write_json(self, path: Path, value: object) -> None:
        path.write_text(
            json.dumps(value, indent=2, sort_keys=True) + "\n", encoding="utf-8"
        )

    def write_digest(self, path: Path, relatives: set[str]) -> None:
        text = "".join(
            f"{digest(self.framework / relative)}  {relative}\n"
            for relative in sorted(relatives)
        )
        path.write_text(text, encoding="ascii")

    def create_seed(self) -> None:
        generator = self.root / "full" / "framework-fanout" / "generate.py"
        generator.write_text("# pinned generator\n", encoding="utf-8")
        roadmap_path = (
            self.root / "full" / "framework-roadmap" / "framework-roadmap.json"
        )
        module_record = {
            "module": "TinyKit",
            "category": "apple_first_party",
            "iphoneos_runtime_app_coverage_rank": 1,
            "iphoneos_runtime_focus_launch_build_rank": 1,
        }
        family = {"family": "Tiny", "modules": ["TinyKit"]}
        roadmap = {
            "schema": 2,
            "requested_roadmap_families": [family],
            "iphoneos_runtime_port_candidate_rankings": {
                "by_app_coverage": ["TinyKit"],
                "by_focus_launch_build_relevance": ["TinyKit"],
            },
            "modules": [module_record],
        }
        self.write_json(roadmap_path, roadmap)

        graph_path = self.graph_dir / "TinyKit.symbols.json"
        graph = {
            "metadata": {"formatVersion": {"major": 0, "minor": 6, "patch": 0}},
            "module": {"name": "TinyKit", "platform": {}},
            "symbols": [
                {
                    "identifier": {"precise": "s:7TinyKit6answerSivp"},
                    "kind": {"identifier": "swift.var", "displayName": "Variable"},
                    "names": {"title": "answer"},
                    "pathComponents": ["answer"],
                    "declarationFragments": [{"spelling": "var answer: Int"}],
                },
                {
                    "identifier": {"precise": "s:7TinyKit7meaningSiyF"},
                    "kind": {"identifier": "swift.func", "displayName": "Function"},
                    "names": {"title": "meaning()"},
                    "pathComponents": ["meaning()"],
                    "declarationFragments": [
                        {"spelling": "func meaning() -> Int"}
                    ],
                },
            ],
            "relationships": [],
        }
        self.write_json(graph_path, graph)
        graph_relative = "reference/symbol-graphs/TinyKit.symbols.json"
        overlay_graph_path = self.graph_dir / "TinyKit@Foundation.symbols.json"
        overlay_graph = {
            "metadata": {"formatVersion": {"major": 0, "minor": 6, "patch": 0}},
            "module": {"name": "TinyKit", "platform": {}},
            "symbols": [
                {
                    "identifier": {"precise": "s:7TinyKit6answerSivp"},
                    "kind": {"identifier": "swift.var", "displayName": "Variable"},
                    "names": {"title": "overlay answer"},
                    "pathComponents": ["Overlay", "answer"],
                    "declarationFragments": [
                        {"spelling": "static var answer: Int"}
                    ],
                }
            ],
            "relationships": [],
        }
        self.write_json(overlay_graph_path, overlay_graph)
        overlay_graph_relative = (
            "reference/symbol-graphs/TinyKit@Foundation.symbols.json"
        )
        self.write_json(
            self.reference / "symbol-graphs.json",
            {
                "schema": 1,
                "module": "TinyKit",
                "target": "arm64-apple-ios26.1",
                "minimumAccessLevel": "public",
                "canonicalSurfacePolicy": (
                    "primary-module-graph_then-module-owned_then-utf8-path_then-"
                    "canonical-payload_then-index-v1"
                ),
                "duplicateOccurrenceCount": 1,
                "conflictingDuplicateIdentifierCount": 1,
                "files": [
                    {
                        "path": graph_relative,
                        "sha256": digest(graph_path),
                        "symbolCount": 2,
                        "relationshipCount": 0,
                    },
                    {
                        "path": overlay_graph_relative,
                        "sha256": digest(overlay_graph_path),
                        "symbolCount": 1,
                        "relationshipCount": 0,
                    },
                ],
                "symbolCount": 2,
                "relationshipCount": 0,
            },
        )
        (self.reference / "public-surface.tsv").write_text(
            "precise\tkind\ttitle\tpath\tdeclaration\n"
            "s:7TinyKit6answerSivp\tswift.var\tanswer\tanswer\tvar answer: Int\n"
            "s:7TinyKit7meaningSiyF\tswift.func\tmeaning()\tmeaning()\tfunc meaning() -> Int\n",
            encoding="utf-8",
        )
        (self.reference / "tbd-exports.tsv").write_text(
            "symbol\tsourceSDKRelativePath\n_$sTiny\tSystem/Library/Frameworks/TinyKit.framework/TinyKit.tbd\n",
            encoding="utf-8",
        )
        (self.reference / "sdk-inputs.tsv").write_text(
            "category\tsdkRelativePath\tsize\tsha256\n"
            f"swiftinterface\tSystem/Library/Frameworks/TinyKit.framework/Modules/TinyKit.swiftmodule/arm64-apple-ios.swiftinterface\t1\t{'0' * 64}\n",
            encoding="utf-8",
        )
        self.write_json(
            self.reference / "corpus-summary.json",
            {
                "schema": 1,
                "module": "TinyKit",
                "source": {
                    "path": "full/framework-roadmap/framework-roadmap.json",
                    "sha256": digest(roadmap_path),
                    "schema": 2,
                },
                "moduleRecord": module_record,
                "requestedFamilies": [family],
                "rankings": {
                    "byAppCoverage": 1,
                    "byFocusLaunchBuildRelevance": 1,
                },
            },
        )
        self.write_json(
            self.reference / "framework.json",
            {
                "schema": 1,
                "module": "TinyKit",
                "slug": "tinykit",
                "lane": "leaf-full",
                "risks": ["runtime behavior is not described by declarations"],
                "dependencies": [],
                "symbolCount": 2,
                "relationshipCount": 0,
                "symbolGraph": "reference/symbol-graphs.json",
                "publicSurface": "reference/public-surface.tsv",
                "tbdExports": "reference/tbd-exports.tsv",
                "corpusSummary": "reference/corpus-summary.json",
                "sdkInputs": "reference/sdk-inputs.tsv",
                "guestManifest": "tinykit_guest_sources.txt",
                "runtimeMarker": "TINYKIT_AGENT_RUNTIME_OK",
                "coveragePolicy": {
                    "allowedStatuses": [
                        "implemented",
                        "declared",
                        "deferred",
                        "unavailable",
                        "not-applicable",
                    ],
                    "nondeferredStatuses": ["implemented", "declared"],
                    "minimumNondeferredCount": 2,
                    "rule": "ceil(80% of precise IDs)",
                },
                "provenance": {
                    "generatorPath": "full/framework-fanout/generate.py",
                    "generatorSHA256": digest(generator),
                    "xcodeVersion": "26.1",
                    "xcodeBuild": "17B55",
                    "sdkName": "iphoneos",
                    "sdkVersion": "26.1",
                    "target": "arm64-apple-ios26.1",
                    "frameworkSDKRelativePath": "System/Library/Frameworks/TinyKit.framework",
                    "sdkPath": "/Applications/Xcode.app/SDKs/iPhoneOS.sdk",
                    "rawSDKInputCount": 1,
                    "tbdInputCount": 0,
                    "arm64TBDExportCount": 1,
                    "roadmapPath": "full/framework-roadmap/framework-roadmap.json",
                    "roadmapSHA256": digest(roadmap_path),
                },
            },
        )
        (self.framework / "AGENTS.md").write_text("immutable instructions\n")
        (self.framework / "FANOUT_TASK.md").write_text("immutable task\n")
        (self.framework / "tinykit_guest_sources.txt").write_text("", encoding="utf-8")
        (self.acceptance / "test_host.sh").write_text("#!/bin/sh\nexit 0\n")

        seed_files = {
            "reference/symbol-graphs.json",
            graph_relative,
            overlay_graph_relative,
            "reference/public-surface.tsv",
            "reference/tbd-exports.tsv",
            "reference/sdk-inputs.tsv",
            "reference/corpus-summary.json",
        }
        self.write_digest(self.reference / "seed-files.sha256", seed_files)
        immutable = {
            "AGENTS.md",
            "FANOUT_TASK.md",
            "tests/acceptance/test_host.sh",
            "reference/framework.json",
            "reference/symbol-graphs.json",
            graph_relative,
            overlay_graph_relative,
            "reference/public-surface.tsv",
            "reference/tbd-exports.tsv",
            "reference/sdk-inputs.tsv",
            "reference/corpus-summary.json",
            "reference/seed-files.sha256",
        }
        self.write_digest(self.reference / "immutable-files.sha256", immutable)

    def create_deliverable(self) -> None:
        (self.framework / "TinyKit.swift").write_text(
            "public let answer = 42\npublic func meaning() -> Int { answer }\n",
            encoding="utf-8",
        )
        (self.framework / "tinykit_guest_sources.txt").write_text(
            "full/tinykit/TinyKit.swift\n", encoding="utf-8"
        )
        (self.framework / "README.md").write_text("# TinyKit starting point\n")
        (self.framework / "coverage.tsv").write_text(
            "precise\tstatus\tevidence\tnotes\n"
            "s:7TinyKit6answerSivp\timplemented\tTinyKit.swift:1\t\n"
            "s:7TinyKit7meaningSiyF\tdeclared\tTinyKit.swift:2\tbehavior needs oracle\n",
            encoding="utf-8",
        )
        (self.framework / "oracle-questions.tsv").write_text(
            "precise\tquestion\trisk\treason\n"
            "module\tWhat is the runtime contract?\twrong behavior\theaders cannot answer it\n",
            encoding="utf-8",
        )
        (self.agent_tests / "TinyKitRuntime.swift").write_text(
            'print("TINYKIT_AGENT_RUNTIME_OK")\n', encoding="utf-8"
        )


class ValidatorTests(unittest.TestCase):
    def make_fixture(self) -> tuple[tempfile.TemporaryDirectory[str], Fixture]:
        temporary = tempfile.TemporaryDirectory()
        fixture = Fixture(Path(temporary.name))
        fixture.create_seed()
        return temporary, fixture

    def validate(self, fixture: Fixture, phase: str) -> list[str]:
        return Validator(fixture.root, fixture.framework, phase).validate()

    def test_valid_seed_and_deliverable(self) -> None:
        temporary, fixture = self.make_fixture()
        self.addCleanup(temporary.cleanup)
        self.assertEqual([], self.validate(fixture, "seed"))
        fixture.create_deliverable()
        self.assertEqual([], self.validate(fixture, "deliverable"))

    def test_immutable_mutation_is_rejected(self) -> None:
        temporary, fixture = self.make_fixture()
        self.addCleanup(temporary.cleanup)
        (fixture.framework / "FANOUT_TASK.md").write_text("changed\n")
        errors = self.validate(fixture, "seed")
        self.assertTrue(any("immutable digest mismatch" in error for error in errors))

    def test_duplicate_conflict_metadata_is_recomputed(self) -> None:
        temporary, fixture = self.make_fixture()
        self.addCleanup(temporary.cleanup)
        manifest_path = fixture.reference / "symbol-graphs.json"
        manifest = json.loads(manifest_path.read_text(encoding="utf-8"))
        manifest["duplicateOccurrenceCount"] = 0
        fixture.write_json(manifest_path, manifest)
        errors = self.validate(fixture, "seed")
        self.assertTrue(
            any("duplicateOccurrenceCount does not match" in error for error in errors)
        )

    def test_missing_precise_id_and_low_coverage_are_rejected(self) -> None:
        temporary, fixture = self.make_fixture()
        self.addCleanup(temporary.cleanup)
        fixture.create_deliverable()
        (fixture.framework / "coverage.tsv").write_text(
            "precise\tstatus\tevidence\tnotes\n"
            "s:7TinyKit6answerSivp\timplemented\tTinyKit.swift:1\t\n",
            encoding="utf-8",
        )
        errors = self.validate(fixture, "deliverable")
        self.assertTrue(any("precise-ID accounting mismatch" in error for error in errors))
        self.assertTrue(any("requires at least 2" in error for error in errors))

    def test_out_of_scope_manifest_path_is_rejected(self) -> None:
        temporary, fixture = self.make_fixture()
        self.addCleanup(temporary.cleanup)
        fixture.create_deliverable()
        (fixture.framework / "tinykit_guest_sources.txt").write_text(
            "full/other/Stolen.swift\nfull/tinykit/TinyKit.swift\n", encoding="utf-8"
        )
        errors = self.validate(fixture, "deliverable")
        self.assertTrue(any("beneath full/tinykit/" in error for error in errors))

    @unittest.skipIf(os.name == "nt", "symlink semantics differ on Windows")
    def test_symlink_and_build_product_are_rejected(self) -> None:
        temporary, fixture = self.make_fixture()
        self.addCleanup(temporary.cleanup)
        fixture.create_deliverable()
        (fixture.framework / ".build").mkdir()
        (fixture.framework / "linked.swift").symlink_to(fixture.framework / "TinyKit.swift")
        errors = self.validate(fixture, "deliverable")
        self.assertTrue(any("symlink is forbidden" in error for error in errors))
        self.assertTrue(any("build-product directory" in error for error in errors))


if __name__ == "__main__":
    unittest.main()
