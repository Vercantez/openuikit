from __future__ import annotations

import copy
import json
import os
from pathlib import Path
import subprocess
import tempfile
import unittest


HERE = Path(__file__).resolve().parent
TOOL_DIR = HERE.parent
import sys

sys.path.insert(0, os.fspath(TOOL_DIR))

import local_package_graph  # noqa: E402
import remote_package_materializer  # noqa: E402


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

    @staticmethod
    def git(repository: Path, *arguments: str) -> str:
        return subprocess.run(
            ["git", "-C", os.fspath(repository), *arguments],
            check=True,
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
            text=True,
        ).stdout

    def materialized_remote(self) -> tuple[dict, Path]:
        origin = Path(self.temporary.name) / "RemoteOrigin"
        origin.mkdir()
        self.git(origin, "init", "--initial-branch=main")
        self.git(origin, "config", "user.name", "Graph Test")
        self.git(origin, "config", "user.email", "graph@example.invalid")
        (origin / "Package.swift").write_text(
            "// swift-tools-version: 6.0\n"
            "import PackageDescription\n"
            'let package = Package(name: "Remote", products: ['
            '.library(name: "Remote", targets: ["Remote"])], '
            'targets: [.target(name: "Remote")])\n',
            encoding="utf-8",
        )
        source = origin / "Sources/Remote/Remote.swift"
        source.parent.mkdir(parents=True)
        source.write_text("public struct Remote {}\n", encoding="utf-8")
        self.git(origin, "add", "--all")
        self.git(origin, "commit", "-m", "remote")
        revision = self.git(origin, "rev-parse", "HEAD").strip()
        resolution = (
            self.root
            / "Probe.xcodeproj/project.xcworkspace/xcshareddata/swiftpm/Package.resolved"
        )
        value = json.loads(resolution.read_text(encoding="utf-8"))
        value["pins"][0]["state"]["revision"] = revision
        resolution.write_text(json.dumps(value), encoding="utf-8")
        baseline = self.graph()
        descriptor = remote_package_materializer.descriptor_for(
            baseline["external_packages"][0]
        )
        digest = remote_package_materializer.descriptor_digest(descriptor)
        cache = Path(self.temporary.name) / "remote-cache"
        entry = cache / f"objects/sha256/{digest[:2]}/{digest}"
        repository = entry / "repository"
        entry.mkdir(parents=True)
        subprocess.run(
            ["git", "clone", "--no-tags", os.fspath(origin), os.fspath(repository)],
            check=True,
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
        )
        self.git(repository, "checkout", "--detach", revision)
        self.git(
            repository,
            "remote",
            "set-url",
            "origin",
            "https://example.invalid/Remote.git",
        )
        record = remote_package_materializer._attestation(
            descriptor, repository, f"objects/sha256/{digest[:2]}/{digest}/repository"
        )
        (entry / "attestation.json").write_bytes(
            remote_package_materializer.canonical_json(record)
        )
        materializations = {
            "classification": "exact-remote-swift-package-materialization-set",
            "format_version": 1,
            "packages": [record],
            "source_graph_sha256": local_package_graph._sha256(
                local_package_graph.canonical_json(baseline)
            ),
        }
        return materializations, cache

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
                "resource_bundles": 0,
                "resource_files": 0,
                "selected_products": 1,
                "c_family_headers": 0,
                "c_family_sources": 0,
                "clang_targets": 0,
                "swift_sources": 3,
                "swift_targets": 3,
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

    def test_materialized_remote_targets_are_in_the_build_graph_and_contract(
        self,
    ) -> None:
        materializations, cache = self.materialized_remote()
        graph = local_package_graph.plan(
            self.inventory, self.root, materializations, cache
        )
        self.assertIsNotNone(graph)
        assert graph is not None
        self.assertEqual(graph["format_version"], 2)
        self.assertEqual(graph["buildability"], {"reason": None, "status": "buildable"})
        self.assertEqual(
            [target["target_id"] for target in graph["targets"]],
            [
                f"@remote/remote/{materializations['packages'][0]['commit']}#Remote",
                "Core#Core",
                "Util#Util",
                "Feature#Feature",
            ],
        )
        self.assertEqual(graph["summary"]["remote_packages"], 1)
        self.assertEqual(graph["summary"]["remote_targets"], 1)
        self.assertEqual(graph["summary"]["swift_sources"], 4)
        self.assertEqual(graph["external_packages"], [])
        local_package_graph.require_buildable(graph)
        local_package_graph.verify(graph, self.root, cache)
        output = Path(self.temporary.name) / "expanded-build"
        contract = local_package_graph.prepare_build(graph, self.root, output, cache)
        self.assertTrue(Path(contract["targets"][0]["sources"][0]).is_absolute())
        self.assertTrue(Path(contract["targets"][-1]["sources"][0]).is_absolute())
        local_package_graph.verify_build_contract(graph, self.root, output, cache)
        remote_source = (
            cache
            / materializations["packages"][0]["repository_path"]
            / "Sources/Remote/Remote.swift"
        )
        remote_source.write_text("public struct Changed {}\n", encoding="utf-8")
        with self.assertRaisesRegex(
            local_package_graph.PackageGraphError, "stale or corrupt"
        ):
            local_package_graph.verify(graph, self.root, cache)

    def test_remote_relative_source_paths_are_namespaced_by_origin(self) -> None:
        origins: dict[str, Path] = {}
        revisions: dict[str, str] = {}
        urls = {
            "First": "https://example.invalid/First.git",
            "Second": "https://example.invalid/Second.git",
        }
        for name, url in urls.items():
            origin = Path(self.temporary.name) / f"{name}Origin"
            origin.mkdir()
            self.git(origin, "init", "--initial-branch=main")
            self.git(origin, "config", "user.name", "Graph Test")
            self.git(origin, "config", "user.email", "graph@example.invalid")
            (origin / "Package.swift").write_text(
                "// swift-tools-version: 6.0\n"
                "import PackageDescription\n"
                f'let package = Package(name: "{name}", products: ['
                f'.library(name: "{name}", targets: ["{name}"])], '
                f'targets: [.target(name: "{name}", path: "Sources/Shared")])\n',
                encoding="utf-8",
            )
            source = origin / "Sources/Shared/Shared.swift"
            source.parent.mkdir(parents=True)
            source.write_text(f"public struct {name} {{}}\n", encoding="utf-8")
            self.git(origin, "add", "--all")
            self.git(origin, "commit", "-m", name)
            origins[name.lower()] = origin
            revisions[name.lower()] = self.git(origin, "rev-parse", "HEAD").strip()

        self.write_package(
            "Feature",
            """
            let package = Package(
                name: "Feature",
                products: [.library(name: "Feature", targets: ["Feature"])],
                dependencies: [
                    .package(url: "https://example.invalid/First.git", exact: "1.0.0"),
                    .package(url: "https://example.invalid/Second.git", exact: "1.0.0")
                ],
                targets: [.target(name: "Feature", dependencies: [
                    .product(name: "First", package: "First"),
                    .product(name: "Second", package: "Second")
                ])]
            )
            """,
        )
        resolution = (
            self.root
            / "Probe.xcodeproj/project.xcworkspace/xcshareddata/swiftpm/Package.resolved"
        )
        resolution.write_text(
            json.dumps(
                {
                    "version": 3,
                    "pins": [
                        {
                            "identity": name.lower(),
                            "kind": "remoteSourceControl",
                            "location": urls[name],
                            "state": {
                                "revision": revisions[name.lower()],
                                "version": "1.0.0",
                            },
                        }
                        for name in ("First", "Second")
                    ],
                }
            ),
            encoding="utf-8",
        )
        baseline = self.graph()
        cache = Path(self.temporary.name) / "remote-cache-two"
        records = []
        for descriptor in remote_package_materializer._graph_descriptors(
            baseline, False
        ):
            digest = remote_package_materializer.descriptor_digest(descriptor)
            entry = cache / f"objects/sha256/{digest[:2]}/{digest}"
            repository = entry / "repository"
            entry.mkdir(parents=True)
            subprocess.run(
                [
                    "git",
                    "clone",
                    "--no-tags",
                    os.fspath(origins[descriptor["identity"]]),
                    os.fspath(repository),
                ],
                check=True,
                stdout=subprocess.PIPE,
                stderr=subprocess.PIPE,
            )
            self.git(repository, "checkout", "--detach", descriptor["revision"])
            self.git(repository, "remote", "set-url", "origin", descriptor["url"])
            record = remote_package_materializer._attestation(
                descriptor,
                repository,
                f"objects/sha256/{digest[:2]}/{digest}/repository",
            )
            (entry / "attestation.json").write_bytes(
                remote_package_materializer.canonical_json(record)
            )
            records.append(record)
        materializations = {
            "classification": "exact-remote-swift-package-materialization-set",
            "format_version": 1,
            "packages": records,
            "source_graph_sha256": local_package_graph._sha256(
                local_package_graph.canonical_json(baseline)
            ),
        }
        graph = local_package_graph.plan(
            self.inventory, self.root, materializations, cache
        )
        self.assertIsNotNone(graph)
        assert graph is not None
        remote_targets = [
            target for target in graph["targets"] if target["target_id"].startswith("@remote/")
        ]
        self.assertEqual(len(remote_targets), 2)
        self.assertEqual(
            {target["sources"][0]["path"] for target in remote_targets},
            {"Sources/Shared/Shared.swift"},
        )
        self.assertEqual(
            {target["sources"][0]["source_origin"] for target in remote_targets},
            {"remote:first", "remote:second"},
        )
        local_package_graph.verify(graph, self.root, cache)

    def test_top_level_xcode_remote_product_can_be_frozen_then_materialized(self) -> None:
        materializations, cache = self.materialized_remote()
        inventory = {
            "project": {"path": "Probe.xcodeproj/project.pbxproj"},
            "local_package_references": [],
            "package_products": [
                {
                    "name": "Remote",
                    "origin": "remote",
                    "repository_url": "https://example.invalid/Remote.git",
                    "requirement": {
                        "kind": "exactVersion",
                        "version": "1.2.3",
                    },
                }
            ],
        }
        baseline = local_package_graph.plan(inventory, self.root)
        self.assertIsNotNone(baseline)
        assert baseline is not None
        self.assertEqual(baseline["buildability"]["status"], "blocked")
        self.assertEqual(
            baseline["selected_products"],
            [
                {
                    "name": "Remote",
                    "origin": "remote",
                    "package_identity": "remote",
                    "repository_url": "https://example.invalid/Remote.git",
                    "requirement": {"kind": "exact", "value": "1.2.3"},
                    "target_ids": [],
                }
            ],
        )
        self.assertEqual(
            baseline["external_packages"][0]["consumers"],
            [{"consumer_target": "@application", "product": "Remote"}],
        )
        local_package_graph.verify(baseline, self.root)

        rebound = copy.deepcopy(materializations)
        rebound["source_graph_sha256"] = local_package_graph._sha256(
            local_package_graph.canonical_json(baseline)
        )
        expanded = local_package_graph.plan(inventory, self.root, rebound, cache)
        self.assertIsNotNone(expanded)
        assert expanded is not None
        self.assertEqual(expanded["buildability"], {"reason": None, "status": "buildable"})
        self.assertEqual(expanded["external_packages"], [])
        self.assertEqual(len(expanded["targets"]), 1)
        self.assertTrue(expanded["targets"][0]["target_id"].endswith("#Remote"))
        self.assertEqual(
            expanded["selected_products"][0]["target_ids"],
            [expanded["targets"][0]["target_id"]],
        )
        local_package_graph.verify(expanded, self.root, cache)

    def test_top_level_revision_requirement_survives_canonical_verification(self) -> None:
        materializations, _ = self.materialized_remote()
        revision = materializations["packages"][0]["commit"]
        inventory = {
            "project": {"path": "Probe.xcodeproj/project.pbxproj"},
            "local_package_references": [],
            "package_products": [
                {
                    "name": "Remote",
                    "origin": "remote",
                    "repository_url": "https://example.invalid/Remote.git",
                    "requirement": {
                        "kind": "revision",
                        "revision": revision,
                    },
                }
            ],
        }
        graph = local_package_graph.plan(inventory, self.root)
        self.assertIsNotNone(graph)
        assert graph is not None
        self.assertEqual(
            graph["selected_products"][0]["requirement"],
            {"kind": "revision", "value": revision},
        )
        local_package_graph.verify(graph, self.root)
        self.assertEqual(
            local_package_graph._inventory_remote_requirement(
                {"kind": "branch", "branch": "release"}, "requirement"
            ),
            {"kind": "branch", "value": "release"},
        )
        self.assertEqual(
            local_package_graph._inventory_remote_requirement(
                {"kind": "branch", "value": "release"}, "requirement"
            ),
            {"kind": "branch", "value": "release"},
        )

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
            "#if canImport(DynamicThing)\n"
            'let package = Package(name: "Feature", targets: [])\n'
            "#endif\n",
            encoding="utf-8",
        )
        with self.assertRaisesRegex(
            local_package_graph.PackageGraphError,
            "unsupported conditional compilation expression",
        ):
            self.graph()

    def test_manifest_profile_selects_static_apple_and_swift_branches(self) -> None:
        self.make_local_only()
        self.write_package(
            "Feature",
            """
            #if os(Linux)
            let featureTargets: [Target] = [.executableTarget(name: "Wrong")]
            #else
            let featureTargets: [Target] = [.target(name: "Feature")]
            #endif
            let package = Package(
                name: "Feature",
                products: [.library(name: "Feature", targets: ["Feature"])],
                targets: featureTargets
            )
            #if swift(>=5.6)
            package.dependencies += []
            #endif
            """,
        )
        graph = self.graph()
        self.assertIn("Feature#Feature", [item["target_id"] for item in graph["targets"]])
        local_package_graph.verify(graph, self.root)

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

    def test_static_version_constructor_requirement_is_frozen(self) -> None:
        manifest = self.root / "Feature/Package.swift"
        manifest.write_text(
            manifest.read_text(encoding="utf-8").replace(
                'exact: "1.2.3"', "from: Version(1, 2, 3)"
            ),
            encoding="utf-8",
        )
        graph = self.graph()
        self.assertEqual(
            graph["external_packages"][0]["requirements"],
            [
                {
                    "kind": "from",
                    "package_path": "Feature",
                    "value": "1.2.3",
                }
            ],
        )
        local_package_graph.verify(graph, self.root)

        manifest.write_text(
            manifest.read_text(encoding="utf-8").replace(
                "Version(1, 2, 3)", "Version(major, 2, 3)"
            ),
            encoding="utf-8",
        )
        with self.assertRaisesRegex(
            local_package_graph.PackageGraphError, "integer literals"
        ):
            self.graph()

    def test_unconditional_product_item_dependency_is_normalized(self) -> None:
        manifest = self.root / "Feature/Package.swift"
        manifest.write_text(
            manifest.read_text(encoding="utf-8").replace(
                '.product(name: "Remote", package: "Remote")',
                '.productItem(name: "Remote", package: "Remote", condition: nil)',
            ),
            encoding="utf-8",
        )
        graph = self.graph()
        feature = next(
            target for target in graph["targets"] if target["target_id"] == "Feature#Feature"
        )
        self.assertIn(
            {
                "kind": "external_product",
                "package_identity": "remote",
                "product": "Remote",
                "url": "https://example.invalid/Remote.git",
            },
            feature["dependencies"],
        )
        local_package_graph.verify(graph, self.root)

        manifest.write_text(
            manifest.read_text(encoding="utf-8").replace(
                "condition: nil", "condition: .when(platforms: [.iOS])"
            ),
            encoding="utf-8",
        )
        graph = self.graph()
        feature = next(
            target for target in graph["targets"] if target["target_id"] == "Feature#Feature"
        )
        self.assertNotIn("Remote", [item.get("product") for item in feature["dependencies"]])

        manifest.write_text(
            manifest.read_text(encoding="utf-8").replace(
                "condition: .when(platforms: [.iOS])",
                "condition: .when(configuration: .debug)",
            ),
            encoding="utf-8",
        )
        with self.assertRaisesRegex(
            local_package_graph.PackageGraphError, "unsupported target condition"
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
        self.assertEqual(record[0], b"swift")
        self.assertEqual(record[1], b"Core")
        self.assertEqual(record[4], b"1")
        local_package_graph.verify_build_contract(graph, self.root, output)
        with self.assertRaisesRegex(
            local_package_graph.PackageGraphError, "already exists"
        ):
            local_package_graph.prepare_build(graph, self.root, output)
        map_path = output / contract["targets"][0]["output_file_map"]
        map_path.write_text("{}\n", encoding="utf-8")
        with self.assertRaisesRegex(local_package_graph.PackageGraphError, "changed"):
            local_package_graph.verify_build_contract(graph, self.root, output)

    def test_static_swift_settings_reach_the_exact_target_build_record(self) -> None:
        self.make_local_only()
        self.write_package(
            "Core",
            """
            let package = Package(
                name: "Core",
                products: [.library(name: "Core", targets: ["Core"])],
                targets: [
                    .target(
                        name: "Core",
                        swiftSettings: [
                            .swiftLanguageMode(.v6),
                            .defaultIsolation(MainActor.self)
                        ]
                    )
                ]
            )
            """,
        )
        graph = self.graph()
        core = graph["targets"][0]
        self.assertEqual(
            core["swift_settings"],
            [
                {"kind": "swift_language_mode", "value": "6"},
                {"kind": "default_isolation", "value": "MainActor"},
            ],
        )
        output = Path(self.temporary.name) / "swift-settings-build"
        contract = local_package_graph.prepare_build(graph, self.root, output)
        self.assertEqual(contract["format_version"], 3)
        self.assertEqual(
            contract["targets"][0]["compiler_arguments"],
            ["-swift-version", "6", "-default-isolation", "MainActor"],
        )
        record = local_package_graph.emit_target_record(contract, 0).split(b"\0")[:-1]
        source_count = int(record[4])
        language_count_index = 5 + source_count
        language_count = int(record[language_count_index])
        argument_count_index = language_count_index + 1 + language_count
        self.assertEqual(record[argument_count_index], b"4")
        self.assertEqual(
            record[argument_count_index + 1 : argument_count_index + 5],
            [b"-swift-version", b"6", b"-default-isolation", b"MainActor"],
        )
        local_package_graph.verify_build_contract(graph, self.root, output)

        self.write_package(
            "Core",
            """
            let package = Package(
                name: "Core",
                products: [.library(name: "Core", targets: ["Core"])],
                targets: [
                    .target(
                        name: "Core",
                        swiftSettings: [.unsafeFlags(["-unmodeled"])]
                    )
                ]
            )
            """,
        )
        with self.assertRaisesRegex(
            local_package_graph.PackageGraphError,
            "unsupported Swift setting",
        ):
            self.graph()

    def test_tools_version_and_package_modes_select_effective_swift_mode(self) -> None:
        self.make_local_only()
        core_manifest = self.root / "Core/Package.swift"
        core_manifest.write_text(
            core_manifest.read_text(encoding="utf-8").replace(
                "swift-tools-version: 6.4", "swift-tools-version: 5.9.1"
            ),
            encoding="utf-8",
        )
        graph = self.graph()
        core = graph["targets"][0]
        self.assertEqual(
            core["swift_settings"],
            [{"kind": "swift_language_mode", "value": "5"}],
        )
        core_package = next(
            package for package in graph["packages"] if package["path"] == "Core"
        )
        self.assertEqual(core_package["tools_version"], "5.9.1")
        self.assertEqual(core_package["swift_language_mode"], "5")
        output = Path(self.temporary.name) / "tools-version-build"
        contract = local_package_graph.prepare_build(graph, self.root, output)
        self.assertEqual(
            contract["targets"][0]["compiler_arguments"],
            ["-swift-version", "5"],
        )
        local_package_graph.verify_build_contract(graph, self.root, output)

        self.write_package(
            "Core",
            """
            let package = Package(
                name: "Core",
                products: [.library(name: "Core", targets: ["Core"])],
                targets: [.target(name: "Core")],
                swiftLanguageModes: [.v4_2, .v5]
            )
            """,
        )
        graph = self.graph()
        self.assertEqual(
            graph["targets"][0]["swift_settings"],
            [{"kind": "swift_language_mode", "value": "5"}],
        )

        self.write_package(
            "Core",
            """
            let package = Package(
                name: "Core",
                products: [.library(name: "Core", targets: ["Core"])],
                targets: [
                    .target(
                        name: "Core",
                        swiftSettings: [.swiftLanguageMode(.v5)]
                    )
                ],
                swiftLanguageModes: [.v6]
            )
            """,
        )
        graph = self.graph()
        self.assertEqual(
            graph["targets"][0]["swift_settings"],
            [{"kind": "swift_language_mode", "value": "5"}],
        )

    def test_missing_or_ambiguous_swift_language_contract_is_refused(self) -> None:
        self.make_local_only()
        core_manifest = self.root / "Core/Package.swift"
        core_manifest.write_text(
            core_manifest.read_text(encoding="utf-8").replace(
                "// swift-tools-version: 6.4\n", ""
            ),
            encoding="utf-8",
        )
        with self.assertRaisesRegex(
            local_package_graph.PackageGraphError,
            "exactly one static swift-tools-version",
        ):
            self.graph()

        self.write_package(
            "Core",
            """
            let package = Package(
                name: "Core",
                products: [.library(name: "Core", targets: ["Core"])],
                targets: [.target(name: "Core")],
                swiftLanguageModes: []
            )
            """,
        )
        with self.assertRaisesRegex(
            local_package_graph.PackageGraphError,
            "swiftLanguageModes must not be empty",
        ):
            self.graph()

    def test_resources_are_frozen_bundled_and_get_a_generated_accessor(self) -> None:
        self.make_local_only()
        core = self.root / "Core"
        (core / "PrivacyInfo.xcprivacy").write_text("privacy\n", encoding="utf-8")
        static = core / "Sources/Core/Static"
        static.mkdir()
        (static / "icon.dat").write_bytes(b"icon")
        shared = core / "Sources/Shared"
        shared.mkdir()
        (shared / "configuration.json").write_text("{}\n", encoding="utf-8")
        self.write_package(
            "Core",
            """
            let package = Package(
                name: "Core-Utilities",
                products: [.library(name: "Core", targets: ["Core"])],
                targets: [
                    .target(
                        name: "Core",
                        resources: [
                            .copy("../../PrivacyInfo.xcprivacy"),
                            .copy("Static"),
                            .process("../Shared")
                        ]
                    )
                ]
            )
            """,
        )
        graph = self.graph()
        target = graph["targets"][0]
        self.assertEqual(target["resource_bundle"], "Core_Utilities_Core.bundle")
        self.assertEqual(
            [item["bundle_path"] for item in target["resources"]],
            ["PrivacyInfo.xcprivacy", "Static/icon.dat", "configuration.json"],
        )
        self.assertEqual(graph["summary"]["resource_bundles"], 1)
        self.assertEqual(graph["summary"]["resource_files"], 3)
        output = Path(self.temporary.name) / "resource-build"
        contract = local_package_graph.prepare_build(graph, self.root, output)
        core_contract = contract["targets"][0]
        self.assertEqual(core_contract["resource_bundle"], "Core_Utilities_Core.bundle")
        accessor = output / "targets/000000-Core/resource_bundle_accessor.swift"
        self.assertIn(
            'appendingPathComponent("Core_Utilities_Core.bundle")',
            accessor.read_text(encoding="utf-8"),
        )
        self.assertIn(os.fspath(accessor), core_contract["sources"])
        local_package_graph.verify_build_contract(graph, self.root, output)

        (core / "Sources/Shared/configuration.json").write_text(
            '{"changed":true}\n', encoding="utf-8"
        )
        with self.assertRaises(local_package_graph.PackageGraphError):
            local_package_graph.verify(graph, self.root)

    def test_resource_destination_collision_and_package_escape_are_refused(self) -> None:
        self.make_local_only()
        core = self.root / "Core"
        left = core / "Sources/Core/Left"
        right = core / "Sources/Core/Right"
        left.mkdir()
        right.mkdir()
        (left / "same.txt").write_text("left\n", encoding="utf-8")
        (right / "same.txt").write_text("right\n", encoding="utf-8")
        self.write_package(
            "Core",
            """
            let package = Package(
                name: "Core",
                products: [.library(name: "Core", targets: ["Core"])],
                targets: [.target(name: "Core", resources: [
                    .process("Left/same.txt"), .process("Right/same.txt")
                ])]
            )
            """,
        )
        with self.assertRaisesRegex(
            local_package_graph.PackageGraphError, "resource destination.*collides"
        ):
            self.graph()

        manifest = core / "Package.swift"
        manifest.write_text(
            manifest.read_text(encoding="utf-8").replace(
                '.process("Left/same.txt"), .process("Right/same.txt")',
                '.copy("../../../outside.txt")',
            ),
            encoding="utf-8",
        )
        with self.assertRaisesRegex(
            local_package_graph.PackageGraphError, "escapes target package"
        ):
            self.graph()

    def test_c_family_targets_freeze_stage_and_emit_clang_modules(self) -> None:
        native = self.root / "Native"
        (native / "Sources/c-core/include").mkdir(parents=True)
        (native / "Sources/c-core/private").mkdir()
        (native / "Sources/CXX/include").mkdir(parents=True)
        (native / "Sources/Consumer").mkdir(parents=True)
        (native / "Package.swift").write_text(
            "// swift-tools-version: 6.2\n"
            "import PackageDescription\n"
            "let applePlatforms: [PackageDescription.Platform] = [.iOS, .macOS]\n"
            "let package = Package(\n"
            '  name: "Native",\n'
            '  products: [.library(name: "Native", targets: ["Consumer"])],\n'
            "  targets: [\n"
            '    .target(name: "c-core", cSettings: [\n'
            '      .define("CORE_MODE", to: "7"),\n'
            '      .define("APPLE_MODE", .when(platforms: applePlatforms)),\n'
            '      .define("INACTIVE", .when(platforms: applePlatforms, traits: ["Off"])),\n'
            '      .headerSearchPath("private")\n'
            "    ]),\n"
            '    .target(name: "CXX", cxxSettings: [.define("CXX_MODE")]),\n'
            '    .target(name: "Consumer", dependencies: ["c-core", "CXX"])\n'
            "  ]\n"
            ")\n",
            encoding="utf-8",
        )
        (native / "Sources/c-core/core.c").write_text(
            '#include "c-core.h"\n#include "detail.inc"\nint core(void) { return CORE_MODE + DETAIL; }\n',
            encoding="utf-8",
        )
        (native / "Sources/c-core/include/c-core.h").write_text(
            "int core(void);\n", encoding="utf-8"
        )
        (native / "Sources/c-core/include/module.modulemap").write_text(
            'module c_core { header "c-core.h" export * }\n', encoding="utf-8"
        )
        (native / "Sources/c-core/private/detail.inc").write_text(
            "#define DETAIL 2\n", encoding="utf-8"
        )
        (native / "Sources/CXX/value.cpp").write_text(
            '#include "CXX.h"\nint cxx(void) { return 3; }\n', encoding="utf-8"
        )
        (native / "Sources/CXX/include/CXX.h").write_text(
            "int cxx(void);\n", encoding="utf-8"
        )
        (native / "Sources/Consumer/Consumer.swift").write_text(
            "import c_core\nimport CXX\npublic let nativeValue = core() + cxx()\n",
            encoding="utf-8",
        )
        inventory = {
            "local_package_references": [{"relative_path": "Native"}],
            "package_products": [
                {"name": "Native", "origin": "local", "relative_path": "Native"}
            ],
        }
        graph = local_package_graph.plan(inventory, self.root)
        self.assertIsNotNone(graph)
        assert graph is not None
        self.assertEqual(
            [(item["module"], item["target_type"]) for item in graph["targets"]],
            [("CXX", "clang"), ("c_core", "clang"), ("Consumer", "swift")],
        )
        c_core = graph["targets"][1]
        self.assertEqual(c_core["sources"][0]["language"], "c")
        self.assertEqual(
            [item["target_relative_path"] for item in c_core["headers"]],
            ["include/c-core.h", "private/detail.inc"],
        )
        self.assertEqual(c_core["module_map"]["kind"], "source")
        self.assertEqual(
            c_core["c_settings"],
            [
                {"kind": "define", "name": "CORE_MODE", "value": "7"},
                {"kind": "define", "name": "APPLE_MODE", "value": None},
                {"kind": "header_search_path", "path": "private"},
            ],
        )
        self.assertEqual(graph["targets"][0]["module_map"]["kind"], "generated")
        self.assertEqual(graph["summary"]["c_family_sources"], 2)
        self.assertEqual(graph["summary"]["c_family_headers"], 3)
        local_package_graph.verify(graph, self.root)

        include = native / "Sources/c-core/private/detail.inc"
        original = include.read_bytes()
        include.write_bytes(b"#define DETAIL 9\n")
        with self.assertRaises(local_package_graph.PackageGraphError):
            local_package_graph.verify(graph, self.root)
        include.write_bytes(original)

        output = Path(self.temporary.name) / "native-build"
        contract = local_package_graph.prepare_build(graph, self.root, output)
        self.assertEqual(contract["format_version"], 3)
        self.assertTrue(contract["requires_cxx_runtime"])
        self.assertEqual((output / "clang-link-arguments.nul").read_bytes(), b"-lc++\0")
        self.assertIn(
            "-Xcc", contract["clang_import_arguments"]
        )
        staged_map = output / contract["targets"][1]["module_output"]
        self.assertEqual(
            staged_map.read_text(encoding="utf-8"),
            'module c_core { header "c-core.h" export * }\n',
        )
        generated_map = output / contract["targets"][0]["module_output"]
        self.assertEqual(
            generated_map.read_text(encoding="utf-8"),
            'module CXX {\n    umbrella "."\n    export *\n}\n',
        )
        c_record = local_package_graph.emit_target_record(contract, 1).split(b"\0")[:-1]
        self.assertEqual(c_record[:5], [b"clang", b"c_core", str(contract["targets"][1]["module_output"]).encode(), b"-", b"1"])
        local_package_graph.verify_build_contract(graph, self.root, output)
        staged_header = output / contract["targets"][1]["headers"][0]["path"]
        staged_header.write_text("changed\n", encoding="utf-8")
        with self.assertRaisesRegex(local_package_graph.PackageGraphError, "changed"):
            local_package_graph.verify_build_contract(graph, self.root, output)


if __name__ == "__main__":
    unittest.main()
