#!/usr/bin/env python3
"""Unit tests for the framework fan-out validator."""

from __future__ import annotations

import hashlib
import json
import os
import struct
import tempfile
import unittest
from pathlib import Path

from validate_seed import Validator, compute_scoped_graph_summary


def digest(path: Path) -> str:
    return hashlib.sha256(path.read_bytes()).hexdigest()


def canonical_payload(value: object) -> bytes:
    return json.dumps(
        value,
        ensure_ascii=False,
        sort_keys=True,
        separators=(",", ":"),
        allow_nan=False,
    ).encode("utf-8")


def multiset_hash(domain: bytes, payloads: list[bytes]) -> str:
    value = hashlib.sha256()
    value.update(domain)
    value.update(struct.pack(">Q", len(payloads)))
    for payload in sorted(payloads):
        value.update(struct.pack(">Q", len(payload)))
        value.update(payload)
    return value.hexdigest()


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
        external_lock_path = (
            self.root
            / "full"
            / "framework-fanout"
            / "external-evidence-sources.json"
        )
        external_lock = {
            "schema": 1,
            "policy": {
                "behaviorAuthority": ["runtime-oracle", "focused-tests"],
                "conflictRule": "Apple evidence wins",
                "copyRule": "Read-only facts",
                "declarationPrecedence": ["apple-sdk", "test-bindings"],
                "runtimeRule": "Static bindings are not runtime evidence",
            },
            "sources": [
                {
                    "capabilities": ["enum-raw-values", "objc-selectors"],
                    "id": "test-bindings",
                    "repository": "https://github.com/example/bindings.git",
                    "commit": "1" * 40,
                    "licensePath": "LICENSE",
                    "licenseSHA256": "2" * 64,
                    "licenseSummary": "MIT test fixture.",
                    "environmentVariable": "OPENUIKIT_TEST_BINDINGS_ROOT",
                    "sourcePathTemplates": [
                        "src/{module}/",
                        "src/{moduleLower}.txt",
                    ],
                }
            ],
        }
        self.write_json(external_lock_path, external_lock)
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
        primary_answer_payload = canonical_payload(graph["symbols"][0])
        meaning_payload = canonical_payload(graph["symbols"][1])
        overlay_answer_payload = canonical_payload(overlay_graph["symbols"][0])
        symbol_multiset_hash = multiset_hash(
            b"OpenUIKit.SymbolGraph.SymbolMultiset.v1\0",
            [primary_answer_payload, meaning_payload, overlay_answer_payload],
        )
        relationship_multiset_hash = multiset_hash(
            b"OpenUIKit.SymbolGraph.RelationshipMultiset.v1\0", []
        )
        self.write_json(
            self.reference / "symbol-graphs.json",
            {
                "schema": 2,
                "module": "TinyKit",
                "target": "arm64-apple-ios26.1",
                "minimumAccessLevel": "public",
                "canonicalSurfacePolicy": (
                    "primary-module-graph_then-module-owned_then-utf8-path_then-"
                    "canonical-payload-v2"
                ),
                "semanticHashPolicy": (
                    "sorted-canonical-json-u64be-length-prefixed-sha256-v1"
                ),
                "symbolMultisetSHA256": symbol_multiset_hash,
                "relationshipMultisetSHA256": relationship_multiset_hash,
                "conflictLedger": "reference/symbol-conflicts.tsv",
                "duplicateOccurrenceCount": 1,
                "duplicateRelationshipOccurrenceCount": 0,
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
        (self.reference / "symbol-conflicts.tsv").write_text(
            "precise\tpayloadSHA256\tgraphPath\townershipTier\toccurrenceCount\t"
            "canonicalSelection\tkind\ttitle\tsymbolPath\tdeclaration\n"
            f"s:7TinyKit6answerSivp\t{hashlib.sha256(primary_answer_payload).hexdigest()}\t"
            f"{graph_relative}\t0\t1\t1\tswift.var\tanswer\tanswer\tvar answer: Int\n"
            f"s:7TinyKit6answerSivp\t{hashlib.sha256(overlay_answer_payload).hexdigest()}\t"
            f"{overlay_graph_relative}\t1\t1\t0\tswift.var\toverlay answer\t"
            "Overlay.answer\tstatic var answer: Int\n",
            encoding="utf-8",
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
        api_digester = {
            "ABIRoot": {
                "children": [
                    {
                        "declKind": "Var",
                        "kind": "Var",
                        "moduleName": "TinyKit",
                        "name": "answer",
                        "printedName": "answer",
                        "usr": "s:7TinyKit6answerSivp",
                    }
                ],
                "json_format_version": 8,
                "kind": "Root",
                "name": "TinyKit",
                "printedName": "TinyKit",
            }
        }
        self.write_json(self.reference / "api-digester.json", api_digester)
        (self.reference / "api-crosswalk.tsv").write_text(
            "precise\tgraphKind\tgraphPath\tstatus\tbasis\trawCandidateCount\t"
            "compatibleCandidateCount\tselectedNodePath\tcandidateNodePaths\n"
            "s:7TinyKit6answerSivp\tswift.var\t[\"answer\"]\texact-usr\t"
            "exact-usr\t1\t1\t/ABIRoot/children/0\t"
            "[\"/ABIRoot/children/0\"]\n"
            "s:7TinyKit7meaningSiyF\tswift.func\t[\"meaning()\"]\tunmatched\t"
            "none\t0\t0\t\t[]\n",
            encoding="utf-8",
        )
        external_evidence = {
            "schema": 1,
            "module": "TinyKit",
            "lock": {
                "path": "full/framework-fanout/external-evidence-sources.json",
                "sha256": digest(external_lock_path),
            },
            "policy": external_lock["policy"],
            "sources": [
                {
                    key: value
                    for key, value in external_lock["sources"][0].items()
                    if key != "sourcePathTemplates"
                }
                | {
                    "suggestedSourcePaths": [
                        "src/TinyKit/",
                        "src/tinykit.txt",
                    ]
                }
            ],
        }
        self.write_json(
            self.reference / "external-evidence.json", external_evidence
        )
        self.write_json(
            self.reference / "framework.json",
            {
                "schema": 2,
                "module": "TinyKit",
                "slug": "tinykit",
                "lane": "leaf-full",
                "risks": ["runtime behavior is not described by declarations"],
                "dependencies": [],
                "symbolCount": 2,
                "relationshipCount": 0,
                "symbolGraph": "reference/symbol-graphs.json",
                "symbolConflicts": "reference/symbol-conflicts.tsv",
                "publicSurface": "reference/public-surface.tsv",
                "apiDigester": "reference/api-digester.json",
                "apiCrosswalk": "reference/api-crosswalk.tsv",
                "tbdExports": "reference/tbd-exports.tsv",
                "corpusSummary": "reference/corpus-summary.json",
                "externalEvidence": "reference/external-evidence.json",
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
                    "symbolGraphExtractorPath": (
                        "Toolchains/XcodeDefault.xctoolchain/usr/bin/"
                        "swift-symbolgraph-extract"
                    ),
                    "symbolGraphExtractorSHA256": "3" * 64,
                    "symbolGraphExtractorVersion": (
                        "Apple Swift version 6.2.1 (swiftlang-test clang-test)"
                    ),
                    "apiDigesterPath": (
                        "Toolchains/XcodeDefault.xctoolchain/usr/bin/"
                        "swift-api-digester"
                    ),
                    "apiDigesterSHA256": "4" * 64,
                    "apiDigesterVersion": (
                        "Apple Swift version 6.2.1 (swiftlang-test clang-test)"
                    ),
                    "rawSDKInputCount": 1,
                    "tbdInputCount": 0,
                    "arm64TBDExportCount": 1,
                    "roadmapPath": "full/framework-roadmap/framework-roadmap.json",
                    "roadmapSHA256": digest(roadmap_path),
                    "apiDigesterFormatVersion": 8,
                    "apiDigesterNodeCount": 2,
                    "apiDeclarationNodeCount": 1,
                    "apiOwnedDeclarationNodeCount": 1,
                    "apiCrosswalkExactUSRCount": 1,
                    "apiCrosswalkImportNameCount": 0,
                    "apiCrosswalkAmbiguousCount": 0,
                    "apiCrosswalkUnmatchedCount": 1,
                    "symbolGraphSymbolMultisetSHA256": symbol_multiset_hash,
                    "symbolGraphRelationshipMultisetSHA256": (
                        relationship_multiset_hash
                    ),
                    "externalEvidenceLockPath": (
                        "full/framework-fanout/external-evidence-sources.json"
                    ),
                    "externalEvidenceLockSHA256": digest(external_lock_path),
                },
            },
        )
        (self.framework / "AGENTS.md").write_text("immutable instructions\n")
        (self.framework / "FANOUT_TASK.md").write_text("immutable task\n")
        (self.framework / "tinykit_guest_sources.txt").write_text("", encoding="utf-8")
        (self.acceptance / "test_host.sh").write_text("#!/bin/sh\nexit 0\n")

        seed_files = {
            "reference/symbol-graphs.json",
            "reference/symbol-conflicts.tsv",
            graph_relative,
            overlay_graph_relative,
            "reference/public-surface.tsv",
            "reference/api-digester.json",
            "reference/api-crosswalk.tsv",
            "reference/tbd-exports.tsv",
            "reference/sdk-inputs.tsv",
            "reference/corpus-summary.json",
            "reference/external-evidence.json",
        }
        self.write_digest(self.reference / "seed-files.sha256", seed_files)
        immutable = {
            "AGENTS.md",
            "FANOUT_TASK.md",
            "tests/acceptance/test_host.sh",
            "reference/framework.json",
            "reference/symbol-graphs.json",
            "reference/symbol-conflicts.tsv",
            graph_relative,
            overlay_graph_relative,
            "reference/public-surface.tsv",
            "reference/api-digester.json",
            "reference/api-crosswalk.tsv",
            "reference/tbd-exports.tsv",
            "reference/sdk-inputs.tsv",
            "reference/corpus-summary.json",
            "reference/external-evidence.json",
            "reference/seed-files.sha256",
        }
        self.write_digest(self.reference / "immutable-files.sha256", immutable)
        self.seed_files = seed_files
        self.immutable_files = immutable

    def reseal(self) -> None:
        self.write_digest(self.reference / "seed-files.sha256", self.seed_files)
        self.write_digest(
            self.reference / "immutable-files.sha256", self.immutable_files
        )

    def enable_symbol_graph_scope(self) -> None:
        scripts = self.root / "scripts" / "framework-fanout"
        scripts.mkdir(parents=True, exist_ok=True)
        base_generator = scripts / "generate_seed_v2.py"
        scoped_generator = scripts / "generate_seed_v2_scoped.py"
        base_generator.write_text("# pinned base generator\n", encoding="utf-8")
        scoped_generator.write_text("# pinned scoped generator\n", encoding="utf-8")

        primary_path = self.graph_dir / "TinyKit.symbols.json"
        primary = json.loads(primary_path.read_text(encoding="utf-8"))
        primary["symbols"].append(
            {
                "identifier": {"precise": "c:objc(cs)TinyObjC"},
                "kind": {"identifier": "swift.class", "displayName": "Class"},
                "names": {"title": "TinyObjC"},
                "pathComponents": ["TinyObjC"],
                "declarationFragments": [{"spelling": "class TinyObjC"}],
            }
        )
        primary["relationships"] = [
            {
                "kind": "conformsTo",
                "source": "c:objc(cs)TinyObjC",
                "target": "s:s8SendableP",
                "targetFallback": "Swift.Sendable",
            }
        ]
        self.write_json(primary_path, primary)

        overlay_path = self.graph_dir / "TinyKit@Foundation.symbols.json"
        overlay = json.loads(overlay_path.read_text(encoding="utf-8"))
        symbol_payloads = [
            canonical_payload(symbol)
            for graph in (primary, overlay)
            for symbol in graph["symbols"]
        ]
        relationship_payloads = [
            canonical_payload(relationship)
            for graph in (primary, overlay)
            for relationship in graph["relationships"]
        ]
        symbol_hash = multiset_hash(
            b"OpenUIKit.SymbolGraph.SymbolMultiset.v1\0", symbol_payloads
        )
        relationship_hash = multiset_hash(
            b"OpenUIKit.SymbolGraph.RelationshipMultiset.v1\0",
            relationship_payloads,
        )

        manifest = json.loads(
            (self.reference / "symbol-graphs.json").read_text(encoding="utf-8")
        )
        manifest["files"][0]["sha256"] = digest(primary_path)
        manifest["files"][0]["symbolCount"] = 3
        manifest["files"][0]["relationshipCount"] = 1
        manifest["symbolCount"] = 3
        manifest["relationshipCount"] = 1
        manifest["symbolMultisetSHA256"] = symbol_hash
        manifest["relationshipMultisetSHA256"] = relationship_hash
        self.write_json(self.reference / "symbol-graphs.json", manifest)

        surface_path = self.reference / "public-surface.tsv"
        surface_lines = surface_path.read_text(encoding="utf-8").splitlines()
        surface_lines.insert(
            1,
            "c:objc(cs)TinyObjC\tswift.class\tTinyObjC\tTinyObjC\tclass TinyObjC",
        )
        surface_path.write_text("\n".join(surface_lines) + "\n", encoding="utf-8")

        crosswalk_path = self.reference / "api-crosswalk.tsv"
        crosswalk_lines = crosswalk_path.read_text(encoding="utf-8").splitlines()
        crosswalk_lines.insert(
            1,
            "c:objc(cs)TinyObjC\tswift.class\t[\"TinyObjC\"]\tunmatched\t"
            "none\t0\t0\t\t[]",
        )
        crosswalk_path.write_text(
            "\n".join(crosswalk_lines) + "\n", encoding="utf-8"
        )

        metadata_path = self.reference / "framework.json"
        metadata = json.loads(metadata_path.read_text(encoding="utf-8"))
        metadata["symbolCount"] = 3
        metadata["relationshipCount"] = 1
        metadata["coveragePolicy"]["minimumNondeferredCount"] = 3
        metadata["provenance"]["apiCrosswalkUnmatchedCount"] = 2
        metadata["provenance"]["symbolGraphSymbolMultisetSHA256"] = symbol_hash
        metadata["provenance"][
            "symbolGraphRelationshipMultisetSHA256"
        ] = relationship_hash
        self.write_json(metadata_path, metadata)

        included = []
        for record in manifest["files"]:
            graph = json.loads(
                (self.framework / record["path"]).read_text(encoding="utf-8")
            )
            included.append(
                {
                    "fileName": Path(record["path"]).name,
                    "sha256": record["sha256"],
                    "symbolCount": record["symbolCount"],
                    "relationshipCount": record["relationshipCount"],
                    "graphModule": graph["module"]["name"],
                    "bystanders": [],
                    "crossImportOverlayModule": None,
                }
            )
        scope = {
            "schema": 1,
            "policy": (
                "base-module-and-extension-graphs-with-exact-cross-import-"
                "overlay-exclusions-v1"
            ),
            "requestedModule": "TinyKit",
            "approvedExcludedCrossImportOverlayModules": [
                "_TinyKit_SwiftUI"
            ],
            "includedFiles": included,
            "excludedFiles": [
                {
                    "fileName": "_TinyKit_SwiftUI@TinyKit.symbols.json",
                    "sha256": "5" * 64,
                    "symbolCount": 4,
                    "relationshipCount": 5,
                    "graphModule": "TinyKit",
                    "bystanders": ["SwiftUI"],
                    "crossImportOverlayModule": "_TinyKit_SwiftUI",
                }
            ],
            "includedFileCount": 2,
            "includedSymbolOccurrenceCount": 4,
            "includedRelationshipOccurrenceCount": 1,
            "excludedFileCount": 1,
            "excludedSymbolOccurrenceCount": 4,
            "excludedRelationshipOccurrenceCount": 5,
            "rawExtractorFileCount": 3,
            "rawExtractorSymbolOccurrenceCount": 8,
            "rawExtractorRelationshipOccurrenceCount": 6,
            "sourceGenerator": {
                "path": "scripts/framework-fanout/generate_seed_v2.py",
                "sha256": digest(base_generator),
            },
        }
        primary_documents = [
            (
                Path(record["path"]).name,
                json.loads(
                    (self.framework / record["path"]).read_text(encoding="utf-8")
                ),
            )
            for record in manifest["files"]
        ]
        primary_summary = compute_scoped_graph_summary(
            primary_documents, "TinyKit"
        )
        scope["baseRelationshipProjection"] = primary_summary[
            "baseRelationshipProjection"
        ]
        scope_path = self.reference / "symbol-graph-scope.json"
        self.write_json(scope_path, scope)

        metadata = json.loads(metadata_path.read_text(encoding="utf-8"))
        metadata["provenance"]["generatorPath"] = (
            "scripts/framework-fanout/generate_seed_v2_scoped.py"
        )
        metadata["provenance"]["generatorSHA256"] = digest(scoped_generator)
        self.write_json(metadata_path, metadata)

        extraction_keys = (
            "xcodeVersion",
            "xcodeBuild",
            "sdkName",
            "sdkVersion",
            "target",
            "symbolGraphExtractorPath",
            "symbolGraphExtractorSHA256",
            "symbolGraphExtractorVersion",
        )
        extraction = {
            key: metadata["provenance"][key] for key in extraction_keys
        }
        extraction["commandTemplate"] = [
            "{symbolGraphExtractorPath}",
            "-module-name",
            "TinyKit",
            "-target",
            metadata["provenance"]["target"],
            "-sdk",
            "{iPhoneOSSDKRoot}",
            "-minimum-access-level",
            "public",
            "-module-cache-path",
            "{freshTemporaryModuleCache}",
            "-output-dir",
            "{freshTemporaryOutputDirectory}",
        ]
        extraction["temporaryPathPolicy"] = (
            "fresh-private-paths-redacted-with-explicit-command-placeholders-v1"
        )
        extraction["environmentPolicy"] = (
            "generate_seed_v2.prepare_clean_environment-v1"
        )
        canonical_paths = [
            "reference/public-surface.tsv",
            "reference/api-digester.json",
            "reference/api-crosswalk.tsv",
            "reference/symbol-conflicts.tsv",
            "reference/tbd-exports.tsv",
            "reference/sdk-inputs.tsv",
            "reference/corpus-summary.json",
            "reference/external-evidence.json",
        ]
        runs = []
        for run_number, target, fallback in (
            (1, "s:s8SendableP", "Swift.Sendable"),
            (2, "s:s16SendableMetatypeP", "Swift.SendableMetatype"),
            (3, "s:s8SendableP", "Swift.Sendable"),
        ):
            if run_number == 1:
                graph_root_relative = "reference/symbol-graphs"
                documents = primary_documents
                run_included = included
            else:
                graph_root_relative = (
                    f"reference/reproducibility/run-{run_number}/symbol-graphs"
                )
                graph_root = self.framework / graph_root_relative
                graph_root.mkdir(parents=True)
                documents = []
                run_included = []
                for record in included:
                    source = self.graph_dir / record["fileName"]
                    graph = json.loads(source.read_text(encoding="utf-8"))
                    if record["fileName"] == "TinyKit.symbols.json":
                        graph["relationships"][0]["target"] = target
                        graph["relationships"][0]["targetFallback"] = fallback
                    destination = graph_root / record["fileName"]
                    self.write_json(destination, graph)
                    updated = dict(record)
                    updated["sha256"] = digest(destination)
                    updated["relationshipCount"] = len(graph["relationships"])
                    run_included.append(updated)
                    documents.append((record["fileName"], graph))
            summary = compute_scoped_graph_summary(documents, "TinyKit")
            canonical_records = []
            for source_relative in canonical_paths:
                if run_number == 1:
                    retained_relative = source_relative
                else:
                    retained_relative = (
                        f"reference/reproducibility/run-{run_number}/canonical/"
                        f"{Path(source_relative).name}"
                    )
                    retained = self.framework / retained_relative
                    retained.parent.mkdir(parents=True, exist_ok=True)
                    retained.write_bytes((self.framework / source_relative).read_bytes())
                canonical_records.append(
                    {
                        "sourcePath": source_relative,
                        "retainedPath": retained_relative,
                        "sha256": digest(self.framework / retained_relative),
                    }
                )
            runs.append(
                {
                    "run": run_number,
                    "graphRoot": graph_root_relative,
                    "includedFiles": run_included,
                    "excludedFiles": scope["excludedFiles"],
                    "extraction": extraction,
                    **summary,
                    "canonicalOutputs": canonical_records,
                }
            )
        stable_outputs = {
            record["sourcePath"]: record["sha256"]
            for record in runs[0]["canonicalOutputs"]
        }
        reproducibility = {
            "schema": 1,
            "policy": (
                "three-fresh-extractions-with-raw-volatility-and-stable-"
                "derived-evidence-v1"
            ),
            "requestedModule": "TinyKit",
            "runCount": 3,
            "minimumRequiredDistinctRawRelationshipHashes": 2,
            "observedDistinctRawRelationshipHashCount": 2,
            "canonicalOutputPaths": canonical_paths,
            "stable": {
                "uniqueSymbolCount": primary_summary["uniqueSymbolCount"],
                "symbolOccurrenceCount": primary_summary["symbolOccurrenceCount"],
                "symbolMultisetSHA256": primary_summary["symbolMultisetSHA256"],
                "projectedRelationshipOccurrenceCount": primary_summary[
                    "baseRelationshipProjection"
                ]["projectedRelationshipOccurrenceCount"],
                "projectedRelationshipMultisetSHA256": primary_summary[
                    "baseRelationshipProjection"
                ]["projectedRelationshipMultisetSHA256"],
                "canonicalOutputSHA256": stable_outputs,
            },
            "runs": runs,
        }
        repro_path = self.reference / "symbol-graph-reproducibility.json"
        self.write_json(repro_path, reproducibility)
        self.immutable_files.update(
            {
                "reference/symbol-graph-scope.json",
                "reference/symbol-graph-reproducibility.json",
                *(
                    path.relative_to(self.framework).as_posix()
                    for path in (self.reference / "reproducibility").rglob("*")
                    if path.is_file()
                ),
            }
        )
        self.reseal()

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
            "s:7TinyKit6answerSivp\timplemented\t"
            "test:full/tinykit/tests/agent/TinyKitBehaviorTests.swift#testAnswer\t\n"
            "s:7TinyKit7meaningSiyF\tdeclared\t"
            "source:full/tinykit/TinyKit.swift#meaning\tbehavior needs oracle\n",
            encoding="utf-8",
        )
        (self.framework / "oracle-questions.tsv").write_text(
            "precise\tquestion\trisk\treason\n"
            "module\tWhat is the runtime contract?\twrong behavior\theaders cannot answer it\n",
            encoding="utf-8",
        )
        (self.agent_tests / "TinyKitBehaviorTests.swift").write_text(
            "import TinyKit\n"
            "func testAnswer() { precondition(answer == 42) }\n",
            encoding="utf-8",
        )
        (self.agent_tests / "TinyKitLoadSmoke.swift").write_text(
            "import TinyKit\n\n"
            'let frameworkLoadSmokeMarker = "TINYKIT_AGENT_RUNTIME_OK"\n',
            encoding="utf-8",
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

    def test_valid_scoped_seed(self) -> None:
        temporary, fixture = self.make_fixture()
        self.addCleanup(temporary.cleanup)
        fixture.enable_symbol_graph_scope()
        self.assertEqual([], self.validate(fixture, "seed"))

    def test_scoped_seed_rejects_unapproved_excluded_module(self) -> None:
        temporary, fixture = self.make_fixture()
        self.addCleanup(temporary.cleanup)
        fixture.enable_symbol_graph_scope()
        scope_path = fixture.reference / "symbol-graph-scope.json"
        scope = json.loads(scope_path.read_text(encoding="utf-8"))
        scope["excludedFiles"][0]["fileName"] = (
            "_TinyKit_Other@TinyKit.symbols.json"
        )
        scope["excludedFiles"][0]["crossImportOverlayModule"] = "_TinyKit_Other"
        fixture.write_json(scope_path, scope)
        fixture.reseal()
        errors = self.validate(fixture, "seed")
        self.assertTrue(any("is not approved" in error for error in errors))

    def test_scoped_generator_requires_scope_provenance(self) -> None:
        temporary, fixture = self.make_fixture()
        self.addCleanup(temporary.cleanup)
        fixture.enable_symbol_graph_scope()
        scope_path = fixture.reference / "symbol-graph-scope.json"
        scope_path.unlink()
        fixture.immutable_files.remove("reference/symbol-graph-scope.json")
        fixture.reseal()
        errors = self.validate(fixture, "seed")
        self.assertTrue(any("scoped generator requires" in error for error in errors))

    def test_scoped_reproducibility_rejects_ordinary_relationship_change(self) -> None:
        temporary, fixture = self.make_fixture()
        self.addCleanup(temporary.cleanup)
        fixture.enable_symbol_graph_scope()
        graph_root = (
            fixture.reference / "reproducibility" / "run-2" / "symbol-graphs"
        )
        graph_path = graph_root / "TinyKit.symbols.json"
        graph = json.loads(graph_path.read_text(encoding="utf-8"))
        graph["relationships"].append(
            {
                "kind": "memberOf",
                "source": "s:ordinary-member",
                "target": "s:ordinary-container",
            }
        )
        fixture.write_json(graph_path, graph)
        documents = []
        for path in sorted(graph_root.glob("*.symbols.json")):
            documents.append(
                (path.name, json.loads(path.read_text(encoding="utf-8")))
            )
        summary = compute_scoped_graph_summary(documents, "TinyKit")
        repro_path = fixture.reference / "symbol-graph-reproducibility.json"
        repro = json.loads(repro_path.read_text(encoding="utf-8"))
        run = repro["runs"][1]
        for record in run["includedFiles"]:
            if record["fileName"] == graph_path.name:
                record["sha256"] = digest(graph_path)
                record["relationshipCount"] = len(graph["relationships"])
        for key in (
            "uniqueSymbolCount",
            "symbolOccurrenceCount",
            "symbolMultisetSHA256",
            "rawRelationshipOccurrenceCount",
            "rawRelationshipMultisetSHA256",
            "baseRelationshipProjection",
        ):
            run[key] = summary[key]
        repro["observedDistinctRawRelationshipHashCount"] = len(
            {item["rawRelationshipMultisetSHA256"] for item in repro["runs"]}
        )
        fixture.write_json(repro_path, repro)
        fixture.reseal()
        errors = self.validate(fixture, "seed")
        self.assertTrue(
            any("projected relationships differ" in error for error in errors),
            errors,
        )

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

    def test_semantic_hash_is_independent_of_symbol_array_order(self) -> None:
        temporary, fixture = self.make_fixture()
        self.addCleanup(temporary.cleanup)
        graph_path = fixture.graph_dir / "TinyKit.symbols.json"
        graph = json.loads(graph_path.read_text(encoding="utf-8"))
        graph["symbols"].reverse()
        fixture.write_json(graph_path, graph)
        manifest_path = fixture.reference / "symbol-graphs.json"
        manifest = json.loads(manifest_path.read_text(encoding="utf-8"))
        manifest["files"][0]["sha256"] = digest(graph_path)
        fixture.write_json(manifest_path, manifest)
        fixture.reseal()
        self.assertEqual([], self.validate(fixture, "seed"))

    def test_relationship_multiset_preserves_duplicates_and_ignores_order(self) -> None:
        temporary, fixture = self.make_fixture()
        self.addCleanup(temporary.cleanup)
        graph_path = fixture.graph_dir / "TinyKit.symbols.json"
        graph = json.loads(graph_path.read_text(encoding="utf-8"))
        first = {
            "kind": "memberOf",
            "source": "s:7TinyKit7meaningSiyF",
            "target": "s:7TinyKit6answerSivp",
        }
        second = {
            "kind": "defaultImplementationOf",
            "source": "s:7TinyKit6answerSivp",
            "target": "s:7TinyKit7meaningSiyF",
        }
        graph["relationships"] = [first, second, first]
        fixture.write_json(graph_path, graph)

        relationship_hash = multiset_hash(
            b"OpenUIKit.SymbolGraph.RelationshipMultiset.v1\0",
            [canonical_payload(first), canonical_payload(second), canonical_payload(first)],
        )
        manifest_path = fixture.reference / "symbol-graphs.json"
        manifest = json.loads(manifest_path.read_text(encoding="utf-8"))
        manifest["files"][0]["sha256"] = digest(graph_path)
        manifest["files"][0]["relationshipCount"] = 3
        manifest["relationshipCount"] = 3
        manifest["duplicateRelationshipOccurrenceCount"] = 1
        manifest["relationshipMultisetSHA256"] = relationship_hash
        fixture.write_json(manifest_path, manifest)
        metadata_path = fixture.reference / "framework.json"
        metadata = json.loads(metadata_path.read_text(encoding="utf-8"))
        metadata["relationshipCount"] = 3
        metadata["provenance"][
            "symbolGraphRelationshipMultisetSHA256"
        ] = relationship_hash
        fixture.write_json(metadata_path, metadata)
        fixture.reseal()
        self.assertEqual([], self.validate(fixture, "seed"))

        graph["relationships"] = [second, first, first]
        fixture.write_json(graph_path, graph)
        manifest["files"][0]["sha256"] = digest(graph_path)
        fixture.write_json(manifest_path, manifest)
        fixture.reseal()
        self.assertEqual([], self.validate(fixture, "seed"))

    def test_schema2_rejects_nonobject_relationship(self) -> None:
        temporary, fixture = self.make_fixture()
        self.addCleanup(temporary.cleanup)
        graph_path = fixture.graph_dir / "TinyKit.symbols.json"
        graph = json.loads(graph_path.read_text(encoding="utf-8"))
        graph["relationships"] = [42]
        fixture.write_json(graph_path, graph)
        manifest_path = fixture.reference / "symbol-graphs.json"
        manifest = json.loads(manifest_path.read_text(encoding="utf-8"))
        manifest["files"][0]["sha256"] = digest(graph_path)
        fixture.write_json(manifest_path, manifest)
        fixture.reseal()
        errors = self.validate(fixture, "seed")
        self.assertTrue(any("relationship[0] must be an object" in error for error in errors))

    def test_schema2_rejects_floating_json_numbers(self) -> None:
        temporary, fixture = self.make_fixture()
        self.addCleanup(temporary.cleanup)
        graph_path = fixture.graph_dir / "TinyKit.symbols.json"
        graph = json.loads(graph_path.read_text(encoding="utf-8"))
        graph["symbols"][0]["forbiddenFloat"] = 1.5
        fixture.write_json(graph_path, graph)
        manifest_path = fixture.reference / "symbol-graphs.json"
        manifest = json.loads(manifest_path.read_text(encoding="utf-8"))
        manifest["files"][0]["sha256"] = digest(graph_path)
        fixture.write_json(manifest_path, manifest)
        fixture.reseal()
        errors = self.validate(fixture, "seed")
        self.assertTrue(any("forbidden JSON number" in error for error in errors))

    def test_framework_schema_rejects_boolean(self) -> None:
        temporary, fixture = self.make_fixture()
        self.addCleanup(temporary.cleanup)
        metadata_path = fixture.reference / "framework.json"
        metadata = json.loads(metadata_path.read_text(encoding="utf-8"))
        metadata["schema"] = True
        fixture.write_json(metadata_path, metadata)
        fixture.reseal()
        errors = self.validate(fixture, "seed")
        self.assertTrue(
            any("framework schema must be one of" in error for error in errors),
            errors,
        )

    def test_symbol_conflict_ledger_is_recomputed(self) -> None:
        temporary, fixture = self.make_fixture()
        self.addCleanup(temporary.cleanup)
        path = fixture.reference / "symbol-conflicts.tsv"
        path.write_text(
            path.read_text(encoding="utf-8").replace("\t0\t1\t1\t", "\t0\t2\t1\t", 1),
            encoding="utf-8",
        )
        fixture.reseal()
        errors = self.validate(fixture, "seed")
        self.assertTrue(any("symbol-conflicts.tsv" in error for error in errors))

    def test_header_only_conflict_ledger_validates_without_conflicts(self) -> None:
        temporary, fixture = self.make_fixture()
        self.addCleanup(temporary.cleanup)
        primary_path = fixture.graph_dir / "TinyKit.symbols.json"
        overlay_path = fixture.graph_dir / "TinyKit@Foundation.symbols.json"
        primary = json.loads(primary_path.read_text(encoding="utf-8"))
        overlay = json.loads(overlay_path.read_text(encoding="utf-8"))
        overlay["symbols"] = [primary["symbols"][0]]
        fixture.write_json(overlay_path, overlay)
        payloads = [
            canonical_payload(primary["symbols"][0]),
            canonical_payload(primary["symbols"][1]),
            canonical_payload(primary["symbols"][0]),
        ]
        symbol_hash = multiset_hash(
            b"OpenUIKit.SymbolGraph.SymbolMultiset.v1\0", payloads
        )
        manifest_path = fixture.reference / "symbol-graphs.json"
        manifest = json.loads(manifest_path.read_text(encoding="utf-8"))
        manifest["files"][1]["sha256"] = digest(overlay_path)
        manifest["conflictingDuplicateIdentifierCount"] = 0
        manifest["symbolMultisetSHA256"] = symbol_hash
        fixture.write_json(manifest_path, manifest)
        (fixture.reference / "symbol-conflicts.tsv").write_text(
            "precise\tpayloadSHA256\tgraphPath\townershipTier\toccurrenceCount\t"
            "canonicalSelection\tkind\ttitle\tsymbolPath\tdeclaration\n",
            encoding="utf-8",
        )
        metadata_path = fixture.reference / "framework.json"
        metadata = json.loads(metadata_path.read_text(encoding="utf-8"))
        metadata["provenance"]["symbolGraphSymbolMultisetSHA256"] = symbol_hash
        fixture.write_json(metadata_path, metadata)
        fixture.reseal()
        self.assertEqual([], self.validate(fixture, "seed"))

    def test_api_crosswalk_is_recomputed(self) -> None:
        temporary, fixture = self.make_fixture()
        self.addCleanup(temporary.cleanup)
        path = fixture.reference / "api-crosswalk.tsv"
        path.write_text(
            path.read_text(encoding="utf-8").replace(
                "\texact-usr\texact-usr\t1\t1\t", "\tunmatched\tnone\t0\t0\t", 1
            ),
            encoding="utf-8",
        )
        fixture.reseal()
        errors = self.validate(fixture, "seed")
        self.assertTrue(any("api-crosswalk.tsv" in error for error in errors))

    def test_exported_import_name_crosswalk_is_valid(self) -> None:
        temporary, fixture = self.make_fixture()
        self.addCleanup(temporary.cleanup)
        api_path = fixture.reference / "api-digester.json"
        api = json.loads(api_path.read_text(encoding="utf-8"))
        api["ABIRoot"]["children"].append(
            {
                "declAttributes": ["Exported"],
                "declKind": "Import",
                "kind": "Import",
                "moduleName": "TinyKit",
                "name": "TinyKit.meaning()",
                "printedName": "TinyKit.meaning()",
            }
        )
        fixture.write_json(api_path, api)
        crosswalk_path = fixture.reference / "api-crosswalk.tsv"
        crosswalk_path.write_text(
            crosswalk_path.read_text(encoding="utf-8").replace(
                "s:7TinyKit7meaningSiyF\tswift.func\t[\"meaning()\"]\tunmatched\t"
                "none\t0\t0\t\t[]",
                "s:7TinyKit7meaningSiyF\tswift.func\t[\"meaning()\"]\timport-name\t"
                "exported-import-name\t1\t1\t/ABIRoot/children/1\t"
                "[\"/ABIRoot/children/1\"]",
            ),
            encoding="utf-8",
        )
        metadata_path = fixture.reference / "framework.json"
        metadata = json.loads(metadata_path.read_text(encoding="utf-8"))
        provenance = metadata["provenance"]
        provenance["apiDigesterNodeCount"] = 3
        provenance["apiDeclarationNodeCount"] = 2
        provenance["apiOwnedDeclarationNodeCount"] = 2
        provenance["apiCrosswalkImportNameCount"] = 1
        provenance["apiCrosswalkUnmatchedCount"] = 0
        fixture.write_json(metadata_path, metadata)
        fixture.reseal()
        self.assertEqual([], self.validate(fixture, "seed"))

    def test_ambiguous_import_name_crosswalk_is_valid(self) -> None:
        temporary, fixture = self.make_fixture()
        self.addCleanup(temporary.cleanup)
        api_path = fixture.reference / "api-digester.json"
        api = json.loads(api_path.read_text(encoding="utf-8"))
        imported = {
            "declAttributes": ["Exported"],
            "declKind": "Import",
            "kind": "Import",
            "moduleName": "TinyKit",
            "name": "TinyKit.meaning()",
            "printedName": "TinyKit.meaning()",
        }
        api["ABIRoot"]["children"].extend((imported, dict(imported)))
        fixture.write_json(api_path, api)
        crosswalk_path = fixture.reference / "api-crosswalk.tsv"
        crosswalk_path.write_text(
            crosswalk_path.read_text(encoding="utf-8").replace(
                "s:7TinyKit7meaningSiyF\tswift.func\t[\"meaning()\"]\tunmatched\t"
                "none\t0\t0\t\t[]",
                "s:7TinyKit7meaningSiyF\tswift.func\t[\"meaning()\"]\tambiguous\t"
                "exported-import-name\t2\t2\t\t"
                "[\"/ABIRoot/children/1\",\"/ABIRoot/children/2\"]",
            ),
            encoding="utf-8",
        )
        metadata_path = fixture.reference / "framework.json"
        metadata = json.loads(metadata_path.read_text(encoding="utf-8"))
        provenance = metadata["provenance"]
        provenance["apiDigesterNodeCount"] = 4
        provenance["apiDeclarationNodeCount"] = 3
        provenance["apiOwnedDeclarationNodeCount"] = 3
        provenance["apiCrosswalkAmbiguousCount"] = 1
        provenance["apiCrosswalkUnmatchedCount"] = 0
        fixture.write_json(metadata_path, metadata)
        fixture.reseal()
        self.assertEqual([], self.validate(fixture, "seed"))

    def test_api_digester_forbids_tool_arguments(self) -> None:
        temporary, fixture = self.make_fixture()
        self.addCleanup(temporary.cleanup)
        path = fixture.reference / "api-digester.json"
        api = json.loads(path.read_text(encoding="utf-8"))
        api["ABIRoot"]["tool_arguments"] = ["-sdk", "/private/sdk"]
        fixture.write_json(path, api)
        fixture.reseal()
        errors = self.validate(fixture, "seed")
        self.assertTrue(any("forbidden provenance field" in error for error in errors))

    def test_strict_graph_json_rejects_duplicate_keys(self) -> None:
        temporary, fixture = self.make_fixture()
        self.addCleanup(temporary.cleanup)
        graph_path = fixture.graph_dir / "TinyKit.symbols.json"
        text = graph_path.read_text(encoding="utf-8").replace(
            '"symbols": [', '"symbols": [],\n  "symbols": [', 1
        )
        graph_path.write_text(text, encoding="utf-8")
        manifest_path = fixture.reference / "symbol-graphs.json"
        manifest = json.loads(manifest_path.read_text(encoding="utf-8"))
        manifest["files"][0]["sha256"] = digest(graph_path)
        fixture.write_json(manifest_path, manifest)
        fixture.reseal()
        errors = self.validate(fixture, "seed")
        self.assertTrue(any("duplicate JSON key" in error for error in errors))

    def test_api_digester_identity_is_recomputed(self) -> None:
        temporary, fixture = self.make_fixture()
        self.addCleanup(temporary.cleanup)
        path = fixture.reference / "api-digester.json"
        document = json.loads(path.read_text(encoding="utf-8"))
        document["ABIRoot"]["name"] = "WrongKit"
        fixture.write_json(path, document)
        errors = self.validate(fixture, "seed")
        self.assertTrue(
            any("API digester root name does not match" in error for error in errors)
        )

    def test_schema2_requires_relative_hashed_tool_provenance(self) -> None:
        temporary, fixture = self.make_fixture()
        self.addCleanup(temporary.cleanup)
        path = fixture.reference / "framework.json"
        document = json.loads(path.read_text(encoding="utf-8"))
        provenance = document["provenance"]
        provenance["sdkPath"] = "/Applications/Xcode.app/SDKs/iPhoneOS.sdk"
        provenance["apiDigesterPath"] = "/Applications/Xcode.app/swift-api-digester"
        del provenance["symbolGraphExtractorSHA256"]
        fixture.write_json(path, document)
        errors = self.validate(fixture, "seed")
        self.assertTrue(any("provenance keys differ" in error for error in errors))
        self.assertTrue(
            any("apiDigesterPath must be a safe Xcode-relative path" in error for error in errors)
        )
        self.assertTrue(
            any("symbolGraphExtractorSHA256" in error for error in errors)
        )

    def test_external_evidence_lock_drift_is_rejected(self) -> None:
        temporary, fixture = self.make_fixture()
        self.addCleanup(temporary.cleanup)
        lock = (
            fixture.root
            / "full"
            / "framework-fanout"
            / "external-evidence-sources.json"
        )
        document = json.loads(lock.read_text(encoding="utf-8"))
        document["sources"][0]["commit"] = "3" * 40
        fixture.write_json(lock, document)
        errors = self.validate(fixture, "seed")
        self.assertTrue(
            any("external evidence lock digest" in error for error in errors)
        )

    def test_external_evidence_repository_url_is_fail_closed(self) -> None:
        temporary, fixture = self.make_fixture()
        self.addCleanup(temporary.cleanup)
        lock = (
            fixture.root
            / "full"
            / "framework-fanout"
            / "external-evidence-sources.json"
        )
        document = json.loads(lock.read_text(encoding="utf-8"))
        document["sources"][0]["repository"] = "--upload-pack=malicious"
        fixture.write_json(lock, document)
        errors = self.validate(fixture, "seed")
        self.assertTrue(
            any("unapproved repository URL" in error for error in errors)
        )

    def test_external_evidence_policy_values_are_fail_closed(self) -> None:
        invalid_values = (
            ("non-string text", "conflictRule", 7),
            ("empty text", "copyRule", "   "),
            ("control in text", "runtimeRule", "static\nruntime"),
            ("non-list sequence", "behaviorAuthority", "runtime-oracle"),
            ("empty sequence", "declarationPrecedence", []),
            (
                "invalid sequence member",
                "behaviorAuthority",
                ["runtime-oracle", "\x7f"],
            ),
            (
                "duplicate sequence member",
                "declarationPrecedence",
                ["apple-sdk", "apple-sdk"],
            ),
        )
        for label, key, value in invalid_values:
            with self.subTest(label=label), tempfile.TemporaryDirectory() as temporary:
                fixture = Fixture(Path(temporary))
                fixture.create_seed()
                lock_path = (
                    fixture.root
                    / "full"
                    / "framework-fanout"
                    / "external-evidence-sources.json"
                )
                lock = json.loads(lock_path.read_text(encoding="utf-8"))
                lock["policy"][key] = value
                fixture.write_json(lock_path, lock)

                external_path = fixture.reference / "external-evidence.json"
                external = json.loads(external_path.read_text(encoding="utf-8"))
                external["policy"] = lock["policy"]
                external["lock"]["sha256"] = digest(lock_path)
                fixture.write_json(external_path, external)

                metadata_path = fixture.reference / "framework.json"
                metadata = json.loads(metadata_path.read_text(encoding="utf-8"))
                metadata["provenance"]["externalEvidenceLockSHA256"] = digest(
                    lock_path
                )
                fixture.write_json(metadata_path, metadata)
                fixture.reseal()

                errors = self.validate(fixture, "seed")
                self.assertTrue(
                    any(
                        "external evidence policy has invalid values" in error
                        for error in errors
                    ),
                    errors,
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

    def test_schema2_rejects_unstructured_implemented_evidence(self) -> None:
        temporary, fixture = self.make_fixture()
        self.addCleanup(temporary.cleanup)
        fixture.create_deliverable()
        path = fixture.framework / "coverage.tsv"
        text = path.read_text(encoding="utf-8").replace(
            "test:full/tinykit/tests/agent/TinyKitBehaviorTests.swift#testAnswer",
            "TinyKit.swift:1",
        )
        path.write_text(text, encoding="utf-8")
        errors = self.validate(fixture, "deliverable")
        self.assertTrue(
            any("implemented evidence must start with 'test:'" in error for error in errors)
        )

    def test_schema2_rejects_test_declaration_inside_comments_or_strings(self) -> None:
        temporary, fixture = self.make_fixture()
        self.addCleanup(temporary.cleanup)
        fixture.create_deliverable()
        (fixture.agent_tests / "TinyKitBehaviorTests.swift").write_text(
            "// func testAnswer() { preconditionFailure() }\n"
            'let decoy = """\n'
            "func testAnswer() { preconditionFailure() }\n"
            '"""\n',
            encoding="utf-8",
        )
        errors = self.validate(fixture, "deliverable")
        self.assertTrue(
            any("top-level synchronous no-argument test function" in error for error in errors),
            errors,
        )

    def test_schema2_rejects_declared_anchor_inside_comments_or_strings(self) -> None:
        temporary, fixture = self.make_fixture()
        self.addCleanup(temporary.cleanup)
        fixture.create_deliverable()
        (fixture.framework / "TinyKit.swift").write_text(
            "public let answer = 42\n"
            "// public func meaning() -> Int { answer }\n"
            'let decoy = "meaning"\n',
            encoding="utf-8",
        )
        errors = self.validate(fixture, "deliverable")
        self.assertTrue(
            any("declared evidence anchor is absent from Swift code" in error for error in errors),
            errors,
        )

    def test_nested_immutable_ledger_name_is_not_excluded_from_inventory(self) -> None:
        temporary, fixture = self.make_fixture()
        self.addCleanup(temporary.cleanup)
        injected = fixture.reference / "injected" / "immutable-files.sha256"
        injected.parent.mkdir()
        injected.write_text("unsealed\n", encoding="utf-8")
        errors = self.validate(fixture, "seed")
        self.assertTrue(
            any(
                "digest path set mismatch in reference/immutable-files.sha256" in error
                and "reference/injected/immutable-files.sha256" in error
                for error in errors
            ),
            errors,
        )

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
