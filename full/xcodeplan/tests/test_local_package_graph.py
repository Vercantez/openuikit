from __future__ import annotations

import copy
import json
import os
from pathlib import Path
import tempfile
import unittest


HERE = Path(__file__).resolve().parent
TOOL_DIR = HERE.parent
import sys

sys.path.insert(0, os.fspath(TOOL_DIR))

import local_package_graph  # noqa: E402


class LocalPackageGraphTests(unittest.TestCase):
    def setUp(self) -> None:
        self.temporary = tempfile.TemporaryDirectory(prefix="local-package-graph-test.")
        self.root = Path(self.temporary.name) / "Subject"
        self.root.mkdir()
        self.write_package(
            "Core",
            """
            let package = Package(
                name: "Core",
                products: [.library(name: "Core", targets: ["Core"])],
                targets: [.target(name: "Core")]
            )
            """,
        )
        self.write_package(
            "Util",
            """
            let package = Package(
                name: "Util",
                products: [.library(name: "Util", targets: ["Util"])],
                dependencies: [.package(path: "../Core")],
                targets: [.target(name: "Util", dependencies: ["Core"])]
            )
            """,
        )
        self.write_package(
            "Feature",
            """
            let package = Package(
                name: "Feature",
                products: [.library(name: "Feature", targets: ["Feature"])],
                dependencies: [
                    .package(path: "../Util"),
                    .package(url: "https://example.invalid/Remote.git", exact: "1.2.3")
                ],
                targets: [
                    .target(
                        name: "Feature",
                        dependencies: [
                            "Util",
                            .product(name: "Remote", package: "Remote")
                        ]
                    ),
                    .testTarget(name: "FeatureTests", dependencies: ["Feature"])
                ]
            )
            """,
        )
        resolution = (
            self.root
            / "Probe.xcodeproj/project.xcworkspace/xcshareddata/swiftpm/Package.resolved"
        )
        resolution.parent.mkdir(parents=True)
        resolution.write_text(
            json.dumps(
                {
                    "version": 3,
                    "pins": [
                        {
                            "identity": "remote",
                            "kind": "remoteSourceControl",
                            "location": "https://example.invalid/Remote.git",
                            "state": {
                                "revision": "a" * 40,
                                "version": "1.2.3",
                            },
                        }
                    ],
                }
            ),
            encoding="utf-8",
        )
        self.inventory = {
            "project": {"path": "Probe.xcodeproj/project.pbxproj"},
            "local_package_references": [
                {"relative_path": "Feature"},
                {"relative_path": "Core"},
                {"relative_path": "Util"},
            ],
            "package_products": [
                {"name": "Feature", "origin": "local", "relative_path": "Feature"}
            ],
        }

    def tearDown(self) -> None:
        self.temporary.cleanup()

    def write_package(self, name: str, manifest: str) -> None:
        package = self.root / name
        (package / f"Sources/{name}").mkdir(parents=True, exist_ok=True)
        (package / "Package.swift").write_text(
            "// swift-tools-version: 6.4\nimport PackageDescription\n" + manifest,
            encoding="utf-8",
        )
        (package / f"Sources/{name}/{name}.swift").write_text(
            f"public struct {name} {{ public init() {{}} }}\n", encoding="utf-8"
        )

    def graph(self) -> dict:
        graph = local_package_graph.plan(self.inventory, self.root)
        self.assertIsNotNone(graph)
        return graph  # type: ignore[return-value]

    def make_local_only(self) -> None:
        self.write_package(
            "Feature",
            """
            let package = Package(
                name: "Feature",
                products: [.library(name: "Feature", targets: ["Feature"])],
                dependencies: [.package(path: "../Util")],
                targets: [.target(name: "Feature", dependencies: ["Util"])]
            )
            """,
        )

    def test_freezes_topology_edges_hashes_and_exact_remote_pin(self) -> None:
        graph = self.graph()
        self.assertEqual(
            [target["target_id"] for target in graph["targets"]],
            ["Core#Core", "Util#Util", "Feature#Feature"],
        )
        self.assertEqual(
            graph["summary"],
            {
                "external_packages": 1,
                "local_packages": 3,
                "local_products": 3,
                "local_targets": 3,
                "resolution_pins": 1,
                "selected_products": 1,
                "swift_sources": 3,
                "target_dependency_edges": 3,
            },
        )
        self.assertEqual(graph["buildability"]["status"], "blocked")
        remote = graph["external_packages"][0]
        self.assertEqual(remote["identity"], "remote")
        self.assertEqual(remote["pin"]["revision"], "a" * 40)
        self.assertEqual(
            remote["consumers"],
            [{"consumer_target": "Feature#Feature", "product": "Remote"}],
        )
        self.assertTrue(
            all(
                len(source["sha256"]) == 64
                for target in graph["targets"]
                for source in target["sources"]
            )
        )
        local_package_graph.verify(graph, self.root)
        with self.assertRaisesRegex(
            local_package_graph.PackageGraphError,
            "remote package materialization required.*remote@" + "a" * 40,
        ):
            local_package_graph.require_buildable(graph)

    def test_source_manifest_and_lock_mutations_are_detected(self) -> None:
        mutations = (
            (
                self.root / "Core/Sources/Core/Core.swift",
                "\npublic let changed = true\n",
            ),
            (self.root / "Util/Package.swift", "\n// changed\n"),
            (
                self.root
                / "Probe.xcodeproj/project.xcworkspace/xcshareddata/swiftpm/Package.resolved",
                " ",
            ),
        )
        for path, suffix in mutations:
            with self.subTest(path=path.name):
                graph = self.graph()
                original = path.read_text(encoding="utf-8")
                path.write_text(original + suffix, encoding="utf-8")
                with self.assertRaises(local_package_graph.PackageGraphError):
                    local_package_graph.verify(graph, self.root)
                path.write_text(original, encoding="utf-8")

    def test_cycle_is_refused(self) -> None:
        self.write_package(
            "Core",
            """
            let package = Package(
                name: "Core",
                products: [.library(name: "Core", targets: ["Core"])],
                dependencies: [.package(path: "../Util")],
                targets: [.target(name: "Core", dependencies: ["Util"])]
            )
            """,
        )
        with self.assertRaisesRegex(local_package_graph.PackageGraphError, "cycle"):
            self.graph()

    def test_duplicate_selection_and_ambiguous_product_are_refused(self) -> None:
        duplicate = copy.deepcopy(self.inventory)
        duplicate["package_products"].append(
            {"name": "Feature", "origin": "local", "relative_path": "Feature"}
        )
        with self.assertRaisesRegex(local_package_graph.PackageGraphError, "repeat"):
            local_package_graph.plan(duplicate, self.root)

        self.write_package(
            "Other",
            """
            let package = Package(
                name: "Other",
                products: [.library(name: "Feature", targets: ["Other"])],
                targets: [.target(name: "Other")]
            )
            """,
        )
        ambiguous = copy.deepcopy(self.inventory)
        ambiguous["local_package_references"].append({"relative_path": "Other"})
        del ambiguous["package_products"][0]["relative_path"]
        with self.assertRaisesRegex(
            local_package_graph.PackageGraphError, "exactly one package"
        ):
            local_package_graph.plan(ambiguous, self.root)

    def test_escape_missing_and_symlink_inputs_are_refused(self) -> None:
        feature_manifest = self.root / "Feature/Package.swift"
        original = feature_manifest.read_text(encoding="utf-8")
        feature_manifest.write_text(
            original.replace(
                '.package(path: "../Util")', '.package(path: "../../Outside")'
            ),
            encoding="utf-8",
        )
        with self.assertRaisesRegex(local_package_graph.PackageGraphError, "escapes"):
            self.graph()
        feature_manifest.write_text(original, encoding="utf-8")

        missing = copy.deepcopy(self.inventory)
        missing["local_package_references"][0]["relative_path"] = "Missing"
        with self.assertRaisesRegex(
            local_package_graph.PackageGraphError, "cannot inspect"
        ):
            local_package_graph.plan(missing, self.root)

        source = self.root / "Core/Sources/Core/Core.swift"
        source.unlink()
        source.symlink_to(self.root / "Util/Sources/Util/Util.swift")
        with self.assertRaisesRegex(local_package_graph.PackageGraphError, "symlink"):
            self.graph()

    def test_missing_and_unsupported_reachable_targets_are_refused(self) -> None:
        self.write_package(
            "Feature",
            """
            let package = Package(
                name: "Feature",
                products: [.library(name: "Feature", targets: ["Missing"])],
                targets: [.target(name: "Feature")]
            )
            """,
        )
        with self.assertRaisesRegex(
            local_package_graph.PackageGraphError, "missing target"
        ):
            self.graph()

        self.write_package(
            "Feature",
            """
            let package = Package(
                name: "Feature",
                products: [.library(name: "Feature", targets: ["Feature"])],
                targets: [.executableTarget(name: "Feature")]
            )
            """,
        )
        with self.assertRaisesRegex(
            local_package_graph.PackageGraphError, "unsupported kind"
        ):
            self.graph()

        manifest = self.root / "Feature/Package.swift"
        manifest.write_text(
            "// swift-tools-version: 6.4\n"
            "import PackageDescription\n"
            "#if os(macOS)\n"
            'let package = Package(name: "Feature", targets: [])\n'
            "#endif\n",
            encoding="utf-8",
        )
        with self.assertRaisesRegex(
            local_package_graph.PackageGraphError, "conditional or macro"
        ):
            self.graph()

    def test_remote_pin_constraint_mismatch_is_refused(self) -> None:
        resolution = (
            self.root
            / "Probe.xcodeproj/project.xcworkspace/xcshareddata/swiftpm/Package.resolved"
        )
        value = json.loads(resolution.read_text(encoding="utf-8"))
        value["pins"][0]["state"]["version"] = "1.2.4"
        resolution.write_text(json.dumps(value), encoding="utf-8")
        with self.assertRaisesRegex(
            local_package_graph.PackageGraphError, "exact version"
        ):
            self.graph()

    def test_symlinked_workspace_resolution_is_refused(self) -> None:
        resolution = (
            self.root
            / "Probe.xcodeproj/project.xcworkspace/xcshareddata/swiftpm/Package.resolved"
        )
        donor = Path(self.temporary.name) / "Package.resolved"
        donor.write_bytes(resolution.read_bytes())
        resolution.unlink()
        resolution.symlink_to(donor)
        with self.assertRaisesRegex(local_package_graph.PackageGraphError, "symlink"):
            self.graph()

    def test_local_only_build_contract_is_exclusive_and_tamper_evident(self) -> None:
        self.make_local_only()
        graph = self.graph()
        local_package_graph.require_buildable(graph)
        target_list = b"".join(
            target["target_id"].encode("utf-8") + b"\0" for target in graph["targets"]
        )
        local_package_graph.verify_plan_binding(
            graph, {"local_package_graph": graph}, target_list, self.root
        )
        with self.assertRaisesRegex(
            local_package_graph.PackageGraphError, "target list"
        ):
            local_package_graph.verify_plan_binding(
                graph,
                {"local_package_graph": graph},
                target_list + b"extra\0",
                self.root,
            )
        with self.assertRaisesRegex(
            local_package_graph.PackageGraphError, "differs from the application plan"
        ):
            local_package_graph.verify_plan_binding(
                graph,
                {"local_package_graph": {**graph, "targets": []}},
                target_list,
                self.root,
            )
        output = Path(self.temporary.name) / "package-build"
        contract = local_package_graph.prepare_build(graph, self.root, output)
        self.assertEqual(len(contract["targets"]), 3)
        self.assertEqual(
            (output / "targets.nul").read_bytes(),
            b"000000\0" b"000001\0" b"000002\0",
        )
        record = local_package_graph.emit_target_record(contract, 0).split(b"\0")[:-1]
        self.assertEqual(record[0], b"Core")
        self.assertEqual(record[3], b"1")
        local_package_graph.verify_build_contract(graph, self.root, output)
        with self.assertRaisesRegex(
            local_package_graph.PackageGraphError, "already exists"
        ):
            local_package_graph.prepare_build(graph, self.root, output)
        map_path = output / contract["targets"][0]["output_file_map"]
        map_path.write_text("{}\n", encoding="utf-8")
        with self.assertRaisesRegex(local_package_graph.PackageGraphError, "changed"):
            local_package_graph.verify_build_contract(graph, self.root, output)


if __name__ == "__main__":
    unittest.main()
