#!/usr/bin/env python3
"""Unit tests for fail-closed cross-import-overlay seed scoping."""

from __future__ import annotations

import json
from pathlib import Path
import tempfile
import unittest

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


if __name__ == "__main__":
    unittest.main()
