#!/usr/bin/env python3
"""Unit tests for fail-closed cross-import-overlay seed scoping."""

from __future__ import annotations

import json
from pathlib import Path
import tempfile
import unittest

import generate_seed_v2 as base
import generate_seed_v2_scoped as scoped


def write_graph(
    root: Path,
    name: str,
    *,
    bystanders: list[str] | None = None,
    symbols: int = 1,
    relationships: int = 0,
) -> None:
    module: dict[str, object] = {"name": "MapKit", "platform": {}}
    if bystanders is not None:
        module["bystanders"] = bystanders
    graph = {
        "metadata": {"formatVersion": {"major": 0, "minor": 6, "patch": 0}},
        "module": module,
        "symbols": [
            {
                "identifier": {"precise": f"s:test:{name}:{index}"},
                "kind": {"identifier": "swift.struct"},
                "pathComponents": [f"Symbol{index}"],
            }
            for index in range(symbols)
        ],
        "relationships": [
            {"kind": "memberOf", "source": f"s:{index}", "target": "s:root"}
            for index in range(relationships)
        ],
    }
    (root / name).write_text(
        json.dumps(graph, ensure_ascii=False, sort_keys=True) + "\n",
        encoding="utf-8",
    )


def write_projection_graphs(
    root: Path,
    *,
    volatile_source: str,
    ordinary_target: str = "s:ordinary-target",
) -> None:
    symbols = [
        {
            "identifier": {"precise": "c:objc(cs)MKImportedA"},
            "kind": {"identifier": "swift.class"},
            "pathComponents": ["MKImportedA"],
        },
        {
            "identifier": {"precise": "c:objc(cs)MKImportedB"},
            "kind": {"identifier": "swift.class"},
            "pathComponents": ["MKImportedB"],
        },
        {
            "identifier": {"precise": "c:objc(cs)MKNotAClass"},
            "kind": {"identifier": "swift.struct"},
            "pathComponents": ["MKNotAClass"],
        },
        {
            "identifier": {"precise": "s:MapKitNativeClass"},
            "kind": {"identifier": "swift.class"},
            "pathComponents": ["MapKitNativeClass"],
        },
    ]
    relationships = [
        {
            "kind": "conformsTo",
            "source": volatile_source,
            "target": "s:s8SendableP",
            "targetFallback": "Swift.Sendable",
        },
        {
            "kind": "conformsTo",
            "source": "c:objc(cs)MKNotAClass",
            "target": "s:s8SendableP",
            "targetFallback": "Swift.Sendable",
        },
        {
            "kind": "conformsTo",
            "source": "s:MapKitNativeClass",
            "target": "s:s16SendableMetatypeP",
            "targetFallback": "Swift.SendableMetatype",
        },
        {
            "kind": "memberOf",
            "source": "s:member",
            "target": ordinary_target,
        },
    ]
    graph = {
        "metadata": {"formatVersion": {"major": 0, "minor": 6, "patch": 0}},
        "module": {"name": "MapKit", "platform": {}},
        "symbols": symbols,
        "relationships": relationships,
    }
    (root / "MapKit.symbols.json").write_text(
        json.dumps(graph, ensure_ascii=False, sort_keys=True) + "\n",
        encoding="utf-8",
    )
    extension_graph = {
        "metadata": {"formatVersion": {"major": 0, "minor": 6, "patch": 0}},
        "module": {"name": "MapKit", "platform": {}},
        "symbols": [],
        "relationships": [
            {
                "kind": "conformsTo",
                "source": "c:objc(cs)MKImportedA",
                "target": "s:s8SendableP",
                "targetFallback": "Swift.Sendable",
            }
        ],
    }
    (root / "MapKit@Foundation.symbols.json").write_text(
        json.dumps(extension_graph, ensure_ascii=False, sort_keys=True) + "\n",
        encoding="utf-8",
    )


class ScopedGeneratorTests(unittest.TestCase):
    def make_valid_graphs(self, root: Path, *, reverse: bool = False) -> None:
        records = [
            ("MapKit.symbols.json", None, 2, 3),
            ("MapKit@Foundation.symbols.json", None, 1, 0),
            ("_MapKit_SwiftUI@MapKit.symbols.json", ["SwiftUI"], 4, 5),
            ("_MapKit_SwiftUI@Swift.symbols.json", ["SwiftUI"], 2, 1),
        ]
        if reverse:
            records.reverse()
        for name, bystanders, symbols, relationships in records:
            write_graph(
                root,
                name,
                bystanders=bystanders,
                symbols=symbols,
                relationships=relationships,
            )

    def test_scope_is_reproducible_and_retains_full_closure(self) -> None:
        with tempfile.TemporaryDirectory() as first_text, tempfile.TemporaryDirectory() as second_text:
            first = Path(first_text)
            second = Path(second_text)
            self.make_valid_graphs(first)
            self.make_valid_graphs(second, reverse=True)
            left = scoped.classify_symbol_graphs(
                first, "MapKit", ["_MapKit_SwiftUI"]
            )
            right = scoped.classify_symbol_graphs(
                second, "MapKit", ["_MapKit_SwiftUI"]
            )
            self.assertEqual(scoped.json_bytes(left), scoped.json_bytes(right))
            self.assertEqual(4, left["rawExtractorFileCount"])
            self.assertEqual(2, left["includedFileCount"])
            self.assertEqual(2, left["excludedFileCount"])
            self.assertEqual(9, left["rawExtractorSymbolOccurrenceCount"])
            self.assertEqual(9, left["rawExtractorRelationshipOccurrenceCount"])
            self.assertEqual(
                ["_MapKit_SwiftUI"],
                left["approvedExcludedCrossImportOverlayModules"],
            )
            self.assertEqual(4, len(list(first.glob("*.symbols.json"))))

    def test_unapproved_cross_import_overlay_is_rejected(self) -> None:
        with tempfile.TemporaryDirectory() as temporary:
            root = Path(temporary)
            write_graph(root, "MapKit.symbols.json")
            write_graph(
                root,
                "_MapKit_Other@MapKit.symbols.json",
                bystanders=["Other"],
            )
            with self.assertRaisesRegex(
                scoped.ScopedSeedError, "unapproved cross-import overlay"
            ):
                scoped.classify_symbol_graphs(
                    root, "MapKit", ["_MapKit_SwiftUI"]
                )

    def test_unused_approved_exclusion_is_rejected(self) -> None:
        with tempfile.TemporaryDirectory() as temporary:
            root = Path(temporary)
            write_graph(root, "MapKit.symbols.json")
            with self.assertRaisesRegex(
                scoped.ScopedSeedError, "approved exclusion set"
            ):
                scoped.classify_symbol_graphs(
                    root, "MapKit", ["_MapKit_SwiftUI"]
                )

    def test_projection_removes_only_primary_imported_objc_class_edges(self) -> None:
        with tempfile.TemporaryDirectory() as temporary:
            root = Path(temporary)
            write_projection_graphs(
                root, volatile_source="c:objc(cs)MKImportedA"
            )
            projection = scoped.compute_base_relationship_projection(root, "MapKit")
            self.assertEqual(5, projection["rawRelationshipOccurrenceCount"])
            self.assertEqual(
                4, projection["projectedRelationshipOccurrenceCount"]
            )
            self.assertEqual(1, projection["excludedRelationshipOccurrenceCount"])
            self.assertEqual(1, len(projection["excludedRows"]))
            row = projection["excludedRows"][0]
            self.assertEqual("c:objc(cs)MKImportedA", row["source"])
            self.assertEqual("s:s8SendableP", row["target"])
            self.assertEqual("Swift.Sendable", row["targetFallback"])
            self.assertIsNone(row["sourceOrigin"])

            graph_path = root / "MapKit.symbols.json"
            graph = json.loads(graph_path.read_text(encoding="utf-8"))
            graph["relationships"].extend(
                (
                    {
                        "kind": "conformsTo",
                        "source": "c:objc(cs)MKImportedA",
                        "target": "s:s16SendableMetatypeP",
                        "targetFallback": "Swift.SendableMetatype",
                    },
                    {
                        "kind": "conformsTo",
                        "source": "c:objc(cs)MKImportedA",
                        "target": "s:SomeOtherProtocol",
                        "targetFallback": "Other.Protocol",
                    },
                )
            )
            graph_path.write_text(
                json.dumps(graph, ensure_ascii=False, sort_keys=True) + "\n",
                encoding="utf-8",
            )
            expanded = scoped.compute_base_relationship_projection(root, "MapKit")
            self.assertEqual(7, expanded["rawRelationshipOccurrenceCount"])
            self.assertEqual(5, expanded["projectedRelationshipOccurrenceCount"])
            self.assertEqual(2, expanded["excludedRelationshipOccurrenceCount"])
            self.assertEqual(
                {"s:s8SendableP", "s:s16SendableMetatypeP"},
                {item["target"] for item in expanded["excludedRows"]},
            )

    def test_projection_stabilizes_only_the_known_volatile_edge(self) -> None:
        with tempfile.TemporaryDirectory() as left_text, tempfile.TemporaryDirectory() as right_text:
            left = Path(left_text)
            right = Path(right_text)
            write_projection_graphs(
                left, volatile_source="c:objc(cs)MKImportedA"
            )
            write_projection_graphs(
                right, volatile_source="c:objc(cs)MKImportedB"
            )
            left_projection = scoped.compute_base_relationship_projection(
                left, "MapKit"
            )
            right_projection = scoped.compute_base_relationship_projection(
                right, "MapKit"
            )
            self.assertNotEqual(
                left_projection["rawRelationshipMultisetSHA256"],
                right_projection["rawRelationshipMultisetSHA256"],
            )
            self.assertEqual(
                left_projection["projectedRelationshipMultisetSHA256"],
                right_projection["projectedRelationshipMultisetSHA256"],
            )
            self.assertNotEqual(
                left_projection["excludedRelationshipMultisetSHA256"],
                right_projection["excludedRelationshipMultisetSHA256"],
            )

    def test_ordinary_relationship_change_is_not_projected_away(self) -> None:
        with tempfile.TemporaryDirectory() as left_text, tempfile.TemporaryDirectory() as right_text:
            left = Path(left_text)
            right = Path(right_text)
            write_projection_graphs(
                left,
                volatile_source="c:objc(cs)MKImportedA",
                ordinary_target="s:ordinary-target-a",
            )
            write_projection_graphs(
                right,
                volatile_source="c:objc(cs)MKImportedA",
                ordinary_target="s:ordinary-target-b",
            )
            left_projection = scoped.compute_base_relationship_projection(
                left, "MapKit"
            )
            right_projection = scoped.compute_base_relationship_projection(
                right, "MapKit"
            )
            self.assertNotEqual(
                left_projection["projectedRelationshipMultisetSHA256"],
                right_projection["projectedRelationshipMultisetSHA256"],
            )
            canonical = [
                {"sourcePath": path, "sha256": "a" * 64}
                for path in scoped.CANONICAL_OUTPUT_PATHS
            ]

            def run(number: int, projection: dict[str, object]) -> dict[str, object]:
                return {
                    "run": number,
                    "uniqueSymbolCount": 4,
                    "symbolOccurrenceCount": 4,
                    "symbolMultisetSHA256": "b" * 64,
                    "rawRelationshipMultisetSHA256": projection[
                        "rawRelationshipMultisetSHA256"
                    ],
                    "baseRelationshipProjection": projection,
                    "canonicalOutputs": canonical,
                }

            with self.assertRaisesRegex(
                scoped.ScopedSeedError, "narrow relationship projection"
            ):
                scoped._validate_run_invariants(
                    [
                        run(1, left_projection),
                        run(2, right_projection),
                        run(3, left_projection),
                    ]
                )


def write_file(path: Path, text: str) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(text, encoding="utf-8")


class NonFrameworkSeedTests(unittest.TestCase):
    def make_sdk(self) -> tuple[tempfile.TemporaryDirectory[str], Path]:
        temporary = tempfile.TemporaryDirectory()
        self.addCleanup(temporary.cleanup)
        sdk = Path(temporary.name) / "iPhoneOS.sdk"
        sdk.mkdir()
        return temporary, sdk

    def test_locator_prefers_swift_framework_bundle(self) -> None:
        _temporary, sdk = self.make_sdk()
        write_file(
            sdk
            / "System/Library/Frameworks/Foundation.framework/Modules/Foundation.swiftmodule/arm64-apple-ios.swiftinterface",
            "// swift-interface-format-version: 1.0\npublic struct FoundationMarker {}\n",
        )
        write_file(
            sdk / "usr/lib/swift/Foundation.swiftmodule/arm64-apple-ios.swiftinterface",
            "// should not win over the framework bundle\n",
        )
        location = base.locate_sdk_module(sdk, "Foundation")
        self.assertEqual("framework", location.kind)
        self.assertEqual(
            "System/Library/Frameworks/Foundation.framework",
            location.sdk_relative_path,
        )
        self.assertIn("framework bundle is present", location.reason)
        self.assertEqual([], base.extractor_clang_module_args(location))

    def test_locator_uses_clang_module_map_for_c_only_framework(self) -> None:
        _temporary, sdk = self.make_sdk()
        framework = sdk / "System/Library/Frameworks/IOKit.framework"
        write_file(
            framework / "Modules/module.modulemap",
            'framework module IOKit [system] {\n    umbrella header "IOKitLib.h"\n    export *\n}\n',
        )
        write_file(
            framework / "Headers/IOKitLib.h",
            "typedef int IOReturn;\nIOReturn IOMasterPort(void);\n",
        )
        location = base.locate_sdk_module(sdk, "IOKit")
        self.assertEqual("framework-clang-module", location.kind)
        self.assertIn("no Swift module", location.reason)
        args = base.extractor_clang_module_args(location)
        module_map = str(framework / "Modules/module.modulemap")
        self.assertIn("-Xcc", args)
        self.assertIn(f"-fmodule-map-file={module_map}", args)
        self.assertEqual(
            "-Xcc",
            args[args.index(f"-fmodule-map-file={module_map}") - 1],
        )

    def test_locator_finds_swift_only_module(self) -> None:
        _temporary, sdk = self.make_sdk()
        write_file(
            sdk
            / "usr/lib/swift/Compression.swiftmodule/arm64-apple-ios.swiftinterface",
            "// swift-interface-format-version: 1.0\npublic enum compression_algorithm: Int {}\n",
        )
        location = base.locate_sdk_module(sdk, "Compression")
        self.assertEqual("swift-module", location.kind)
        self.assertEqual(
            "usr/lib/swift/Compression.swiftmodule",
            location.sdk_relative_path,
        )
        self.assertIn("located Swift module", location.reason)
        self.assertEqual([], base.extractor_clang_module_args(location))
        records, tbds = base.collect_located_sdk_inputs(location, sdk, "Compression")
        self.assertEqual([], tbds)
        self.assertEqual(["swiftinterface"], [row["category"] for row in records])

    def test_locator_finds_clang_module_directory_map(self) -> None:
        _temporary, sdk = self.make_sdk()
        write_file(
            sdk / "usr/include/CommonCrypto/module.modulemap",
            'module CommonCrypto [system] [extern_c] {\n    header "CommonCrypto.h"\n    export *\n}\n',
        )
        write_file(
            sdk / "usr/include/CommonCrypto/CommonCrypto.h",
            "int CC_SHA256(const void *data, unsigned int len, unsigned char *md);\n",
        )
        location = base.locate_sdk_module(sdk, "CommonCrypto")
        self.assertEqual("clang-module", location.kind)
        self.assertEqual(
            "usr/include/CommonCrypto/module.modulemap",
            location.sdk_relative_path,
        )
        self.assertIn("located Clang module map", location.reason)
        args = base.extractor_clang_module_args(location)
        module_map = str(sdk / "usr/include/CommonCrypto/module.modulemap")
        self.assertEqual(
            [
                "-I",
                str(sdk / "usr/include/CommonCrypto"),
                "-I",
                str(sdk / "usr/include"),
                "-Xcc",
                f"-fmodule-map-file={module_map}",
                "-Xcc",
                f"-I{sdk / 'usr/include/CommonCrypto'}",
                "-Xcc",
                f"-I{sdk / 'usr/include'}",
            ],
            args,
        )
        records, _tbds = base.collect_located_sdk_inputs(location, sdk, "CommonCrypto")
        categories = {row["category"] for row in records}
        self.assertEqual({"header", "modulemap"}, categories)

    def test_clang_module_map_flag_is_passed_via_xcc(self) -> None:
        _temporary, sdk = self.make_sdk()
        write_file(
            sdk / "usr/include/CommonCrypto/module.modulemap",
            'module CommonCrypto [system] [extern_c] {\n    header "CommonCrypto.h"\n    export *\n}\n',
        )
        write_file(
            sdk / "usr/include/CommonCrypto/CommonCrypto.h",
            "int CC_SHA256(const void *data, unsigned int len, unsigned char *md);\n",
        )
        location = base.locate_sdk_module(sdk, "CommonCrypto")
        extract_args = base.extractor_clang_module_args(location)
        module_map_flag = (
            f"-fmodule-map-file={sdk / 'usr/include/CommonCrypto/module.modulemap'}"
        )
        self.assertIn(module_map_flag, extract_args)
        self.assertEqual(
            "-Xcc", extract_args[extract_args.index(module_map_flag) - 1]
        )
        self.assertTrue(
            any(
                argument == "-Xcc" and extract_args[index + 1].startswith("-I")
                for index, argument in enumerate(extract_args[:-1])
            )
        )
        extract_command = base.symbol_graph_extract_command(
            "/usr/bin/swift-symbolgraph-extract",
            "CommonCrypto",
            sdk,
            Path("/tmp/out"),
            Path("/tmp/cache"),
            extract_args,
        )
        self.assertEqual(
            extract_command[extract_command.index(module_map_flag) - 1],
            "-Xcc",
        )
        with self.assertRaisesRegex(base.SeedError, "without a preceding -Xcc"):
            base.symbol_graph_extract_command(
                "/usr/bin/swift-symbolgraph-extract",
                "CommonCrypto",
                sdk,
                Path("/tmp/out"),
                Path("/tmp/cache"),
                [module_map_flag],
            )
        digester_args = base.digester_clang_module_args(location)
        self.assertNotIn("-Xcc", digester_args)
        self.assertFalse(
            any(argument.startswith("-fmodule-map-file") for argument in digester_args)
        )
        self.assertEqual(
            [
                "-I",
                str(sdk / "usr/include/CommonCrypto"),
                "-I",
                str(sdk / "usr/include"),
            ],
            digester_args,
        )


    def test_locator_finds_top_level_clang_submodule(self) -> None:
        _temporary, sdk = self.make_sdk()
        write_file(
            sdk / "usr/include/module.modulemap",
            'module Darwin [system] { header "stdio.h" }\n'
            'module zlib [system] [extern_c] {\n    header "zlib.h"\n    export *\n}\n',
        )
        write_file(sdk / "usr/include/zlib.h", "int compress(void);\n")
        write_file(sdk / "usr/include/stdio.h", "int printf(const char *fmt, ...);\n")
        location = base.locate_sdk_module(sdk, "zlib")
        self.assertEqual("clang-submodule", location.kind)
        self.assertEqual("usr/include/module.modulemap", location.sdk_relative_path)
        self.assertIn("located Clang submodule zlib", location.reason)
        records, _tbds = base.collect_located_sdk_inputs(location, sdk, "zlib")
        paths = {row["sdkRelativePath"] for row in records}
        self.assertIn("usr/include/module.modulemap", paths)
        self.assertIn("usr/include/zlib.h", paths)
        self.assertNotIn("usr/include/stdio.h", paths)

    def test_locator_prefers_swiftmodule_over_clang_map(self) -> None:
        _temporary, sdk = self.make_sdk()
        write_file(
            sdk / "usr/lib/swift/Compression.swiftmodule/arm64-apple-ios.swiftinterface",
            "public enum compression_algorithm: Int {}\n",
        )
        write_file(
            sdk / "usr/include/Compression/module.modulemap",
            'module Compression { header "compression.h" }\n',
        )
        location = base.locate_sdk_module(sdk, "Compression")
        self.assertEqual("swift-module", location.kind)

    def test_systemconfiguration_is_a_framework(self) -> None:
        _temporary, sdk = self.make_sdk()
        write_file(
            sdk
            / "System/Library/Frameworks/SystemConfiguration.framework/Modules/module.modulemap",
            'framework module SystemConfiguration [system] {\n    umbrella header "SystemConfiguration.h"\n    export *\n}\n',
        )
        write_file(
            sdk
            / "System/Library/Frameworks/SystemConfiguration.framework/Headers/SystemConfiguration.h",
            "typedef int SCNetworkReachabilityRef;\n",
        )
        location = base.locate_sdk_module(sdk, "SystemConfiguration")
        self.assertEqual("framework-clang-module", location.kind)
        self.assertEqual(
            "System/Library/Frameworks/SystemConfiguration.framework",
            location.sdk_relative_path,
        )

    def test_locator_refuses_unknown_module(self) -> None:
        _temporary, sdk = self.make_sdk()
        write_file(sdk / "usr/include/stdio.h", "int printf(const char *fmt, ...);\n")
        with self.assertRaisesRegex(
            base.SeedError, "public iPhoneOS module is missing"
        ):
            base.locate_sdk_module(sdk, "CommonCrypto")

    def test_locator_refuses_clang_map_that_does_not_declare_the_module(self) -> None:
        _temporary, sdk = self.make_sdk()
        write_file(
            sdk / "usr/include/CommonCrypto/module.modulemap",
            'module SomethingElse [system] { header "CommonCrypto.h" }\n',
        )
        write_file(
            sdk / "usr/include/CommonCrypto/CommonCrypto.h",
            "int CC_SHA256(const void *data, unsigned int len, unsigned char *md);\n",
        )
        with self.assertRaisesRegex(base.SeedError, "does not declare CommonCrypto"):
            base.locate_sdk_module(sdk, "CommonCrypto")

    def test_umbrella_reexport_from_swiftinterface_is_named(self) -> None:
        _temporary, sdk = self.make_sdk()
        write_file(
            sdk
            / "System/Library/Frameworks/MobileCoreServices.framework/Modules/MobileCoreServices.swiftmodule/arm64-apple-ios.swiftinterface",
            "// swift-interface-format-version: 1.0\n"
            "@_exported import UniformTypeIdentifiers\n",
        )
        write_file(
            sdk
            / "System/Library/Frameworks/MobileCoreServices.framework/Headers/MobileCoreServices.h",
            "#ifndef MOBILECORESERVICES\n"
            "#define MOBILECORESERVICES\n"
            "#include <CoreFoundation/CoreFoundation.h>\n"
            "#include <UniformTypeIdentifiers/UniformTypeIdentifiers.h>\n"
            "#endif\n",
        )
        location = base.locate_sdk_module(sdk, "MobileCoreServices")
        self.assertEqual("framework", location.kind)
        self.assertEqual(
            "UniformTypeIdentifiers",
            base.detect_umbrella_reexport(
                "MobileCoreServices", location, sdk, require_pure=True
            ),
        )
        with self.assertRaisesRegex(
            base.SeedError,
            r"umbrella re-export of UniformTypeIdentifiers; seed UniformTypeIdentifiers instead",
        ):
            base.refuse_empty_or_umbrella("MobileCoreServices", 0, "UniformTypeIdentifiers")

    def test_real_clang_module_is_not_an_umbrella(self) -> None:
        _temporary, sdk = self.make_sdk()
        write_file(
            sdk / "usr/include/CommonCrypto/module.modulemap",
            'module CommonCrypto [system] [extern_c] {\n    header "CommonCrypto.h"\n    export *\n}\n',
        )
        write_file(
            sdk / "usr/include/CommonCrypto/CommonCrypto.h",
            "#include <CoreFoundation/CoreFoundation.h>\n"
            "int CC_SHA256(const void *data, unsigned int len, unsigned char *md);\n",
        )
        location = base.locate_sdk_module(sdk, "CommonCrypto")
        self.assertIsNone(
            base.detect_umbrella_reexport(
                "CommonCrypto", location, sdk, require_pure=True
            )
        )
        base.refuse_empty_or_umbrella("CommonCrypto", 12, None)

    def test_empty_surface_without_named_reexport_is_refused(self) -> None:
        with self.assertRaisesRegex(
            base.SeedError, r"public surface is empty \(0 symbols\) for EmptyKit"
        ):
            base.refuse_empty_or_umbrella("EmptyKit", 0, None)

    def test_roadmap_override_is_opt_in(self) -> None:
        with tempfile.TemporaryDirectory() as temporary:
            roadmap_path = Path(temporary) / "framework-roadmap.json"
            roadmap_path.write_text(
                json.dumps(
                    {
                        "schema": 2,
                        "modules": [{"module": "Foundation"}],
                        "requested_roadmap_families": [
                            {"family": "data", "modules": ["SwiftData"]}
                        ],
                        "iphoneos_runtime_port_candidate_rankings": {
                            "by_app_coverage": ["Foundation"],
                            "by_focus_launch_build_relevance": ["Foundation"],
                        },
                    }
                )
                + "\n",
                encoding="utf-8",
            )
            with self.assertRaisesRegex(
                base.SeedError, "exactly one SwiftData record"
            ):
                base.roadmap_summary(roadmap_path, "SwiftData")
            summary = base.roadmap_summary(
                roadmap_path, "SwiftData", allow_missing=True
            )
            self.assertEqual(
                {"roadmap": base.ROADMAP_OPERATOR_OVERRIDE},
                summary["moduleRecord"],
            )
            self.assertEqual(
                [{"family": "data", "modules": ["SwiftData"]}],
                summary["requestedFamilies"],
            )
            recorded = base.roadmap_summary(roadmap_path, "Foundation", allow_missing=True)
            self.assertEqual({"module": "Foundation"}, recorded["moduleRecord"])

    def test_allow_no_roadmap_record_flag_defaults_off(self) -> None:
        parser = base.argument_parser()
        args = parser.parse_args(
            [
                "--module",
                "Compression",
                "--slug",
                "compression",
                "--lane",
                "medium-full",
                "--risks",
                "fail-closed",
                "--output-root",
                "/tmp",
            ]
        )
        self.assertFalse(args.allow_no_roadmap_record)
        scoped_parser = scoped.argument_parser()
        scoped_args = scoped_parser.parse_args(
            [
                "--module",
                "Compression",
                "--slug",
                "compression",
                "--lane",
                "medium-full",
                "--risks",
                "fail-closed",
                "--output-root",
                "/tmp",
                "--exclude-cross-import-overlay-module",
                "_Compression_SwiftUI",
                "--allow-no-roadmap-record",
            ]
        )
        self.assertTrue(scoped_args.allow_no_roadmap_record)


if __name__ == "__main__":
    unittest.main()
