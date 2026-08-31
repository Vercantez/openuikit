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

import remote_package_materializer as materializer  # noqa: E402


class RemotePackageMaterializerTests(unittest.TestCase):
    def setUp(self) -> None:
        self.temporary = tempfile.TemporaryDirectory(prefix="remote-package-test.")
        self.root = Path(self.temporary.name)
        self.origin = self.root / "origin"
        self.origin.mkdir()
        self.git(self.origin, "init", "--initial-branch=main")
        self.git(self.origin, "config", "user.name", "Package Test")
        self.git(self.origin, "config", "user.email", "package@example.invalid")
        (self.origin / "Package.swift").write_text(
            "// swift-tools-version: 6.0\n"
            "import PackageDescription\n"
            'let package = Package(name: "Remote", products: ['
            '.library(name: "Remote", targets: ["Remote"])], '
            'targets: [.target(name: "Remote")])\n',
            encoding="utf-8",
        )
        source = self.origin / "Sources/Remote/Remote.swift"
        source.parent.mkdir(parents=True)
        source.write_text("public struct Remote {}\n", encoding="utf-8")
        self.git(self.origin, "add", "--all")
        self.git(self.origin, "commit", "-m", "pinned source")
        self.revision = self.git(self.origin, "rev-parse", "HEAD").strip()
        self.tree = self.git(self.origin, "rev-parse", "HEAD^{tree}").strip()
        self.url = self.origin.as_uri()
        self.descriptor = {
            "identity": "remote",
            "revision": self.revision,
            "url": self.url,
        }
        self.cache = self.root / "cache"

    def tearDown(self) -> None:
        self.temporary.cleanup()

    @staticmethod
    def git(repository: Path, *arguments: str) -> str:
        completed = subprocess.run(
            ["git", "-C", os.fspath(repository), *arguments],
            check=True,
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
            text=True,
        )
        return completed.stdout

    def materialize(self) -> dict:
        return materializer.materialize_entry(
            self.cache, self.descriptor, allow_file_url=True
        )

    def repository(self, record: dict) -> Path:
        return self.cache / record["repository_path"]

    def test_exact_pin_is_content_addressed_clean_and_reusable(self) -> None:
        record = self.materialize()
        digest = materializer.descriptor_digest(self.descriptor)
        self.assertEqual(record["cache_key"], f"sha256:{digest}")
        self.assertEqual(record["commit"], self.revision)
        self.assertEqual(record["tree"], self.tree)
        self.assertEqual(record["origin"], self.url)
        self.assertEqual(record["tracked_file_count"], 2)
        self.assertEqual(self.materialize(), record)
        self.assertEqual(self.git(self.repository(record), "status", "--porcelain"), "")

    def test_tracked_untracked_origin_head_and_attestation_drift_are_refused(
        self,
    ) -> None:
        mutations = (
            "tracked",
            "untracked",
            "origin",
            "head",
            "attestation",
            "metadata_symlink",
        )
        for mutation in mutations:
            with self.subTest(mutation=mutation):
                cache = self.root / f"cache-{mutation}"
                record = materializer.materialize_entry(
                    cache, self.descriptor, allow_file_url=True
                )
                repository = cache / record["repository_path"]
                if mutation == "tracked":
                    (repository / "Sources/Remote/Remote.swift").write_text(
                        "public struct Changed {}\n", encoding="utf-8"
                    )
                elif mutation == "untracked":
                    (repository / "untracked").write_text("drift", encoding="utf-8")
                elif mutation == "origin":
                    self.git(
                        repository, "remote", "set-url", "origin", "file:///changed"
                    )
                elif mutation == "head":
                    self.git(repository, "config", "user.name", "Cache Mutator")
                    self.git(
                        repository, "config", "user.email", "cache@example.invalid"
                    )
                    (repository / "Sources/Remote/Remote.swift").write_text(
                        "public struct Changed {}\n", encoding="utf-8"
                    )
                    self.git(repository, "add", "--all")
                    self.git(repository, "commit", "-m", "wrong head")
                elif mutation == "attestation":
                    attestation = repository.parent / "attestation.json"
                    value = json.loads(attestation.read_text(encoding="utf-8"))
                    value["tree"] = "0" * 40
                    attestation.write_text(json.dumps(value), encoding="utf-8")
                else:
                    metadata = repository / ".git"
                    metadata.rename(repository / ".git.real")
                    metadata.symlink_to(".git.real")
                with self.assertRaisesRegex(
                    materializer.MaterializationError, "stale or corrupt cache entry"
                ):
                    materializer.verify_entry(
                        cache, self.descriptor, allow_file_url=True
                    )

    def test_preexisting_corrupt_entry_is_not_repaired_or_recloned(self) -> None:
        self.cache.mkdir()
        digest = materializer.descriptor_digest(self.descriptor)
        entry = self.cache / f"objects/sha256/{digest[:2]}/{digest}"
        entry.mkdir(parents=True)
        sentinel = entry / "do-not-overwrite"
        sentinel.write_text("preserve evidence", encoding="utf-8")
        with self.assertRaisesRegex(
            materializer.MaterializationError, "stale or corrupt cache entry"
        ):
            self.materialize()
        self.assertEqual(sentinel.read_text(encoding="utf-8"), "preserve evidence")

    def test_cache_object_parent_symlink_escape_is_refused(self) -> None:
        self.cache.mkdir()
        outside = self.root / "outside-cache"
        outside.mkdir()
        (self.cache / "objects").symlink_to(outside)
        with self.assertRaisesRegex(
            materializer.MaterializationError, "symlink|escapes"
        ):
            self.materialize()
        self.assertEqual(list(outside.iterdir()), [])

    def test_internal_tracked_symlink_is_attested_and_reverified(self) -> None:
        linked = self.origin / "linked"
        linked.symlink_to("Package.swift")
        self.git(self.origin, "add", "linked")
        self.git(self.origin, "commit", "-m", "symlink")
        descriptor = {
            **self.descriptor,
            "revision": self.git(self.origin, "rev-parse", "HEAD").strip(),
        }
        cache = self.root / "symlink-cache"
        record = materializer.materialize_entry(
            cache, descriptor, allow_file_url=True
        )
        self.assertEqual(record["format_version"], 3)
        self.assertEqual(record["symlink_count"], 1)
        self.assertEqual(
            record["symlinks"],
            [
                {
                    "blob": self.git(
                        self.origin, "rev-parse", "HEAD:linked"
                    ).strip(),
                    "path": "linked",
                    "target": "Package.swift",
                }
            ],
        )
        checkout = cache / record["repository_path"] / "linked"
        self.assertTrue(checkout.is_symlink())
        self.assertEqual(os.readlink(checkout), "Package.swift")
        self.assertEqual(
            materializer.verify_entry(cache, descriptor, allow_file_url=True),
            record,
        )
        checkout.unlink()
        checkout.symlink_to("Sources/Remote/Remote.swift")
        with self.assertRaisesRegex(
            materializer.MaterializationError, "stale or corrupt cache entry"
        ):
            materializer.verify_entry(cache, descriptor, allow_file_url=True)

    def test_tracked_symlink_that_escapes_repository_is_refused(self) -> None:
        linked = self.origin / "outside"
        linked.symlink_to("../outside")
        self.git(self.origin, "add", "outside")
        self.git(self.origin, "commit", "-m", "escaping symlink")
        descriptor = {
            **self.descriptor,
            "revision": self.git(self.origin, "rev-parse", "HEAD").strip(),
        }
        with self.assertRaisesRegex(
            materializer.MaterializationError, "escapes the repository"
        ):
            materializer.materialize_entry(
                self.root / "escaping-symlink-cache",
                descriptor,
                allow_file_url=True,
            )

    def test_unmaterialized_gitlink_is_attested_but_never_cloned(self) -> None:
        submodule = self.root / "documentation-origin"
        submodule.mkdir()
        self.git(submodule, "init", "--initial-branch=main")
        self.git(submodule, "config", "user.name", "Package Test")
        self.git(submodule, "config", "user.email", "package@example.invalid")
        (submodule / "README.md").write_text("documentation\n", encoding="utf-8")
        self.git(submodule, "add", "--all")
        self.git(submodule, "commit", "-m", "documentation")
        gitlink_commit = self.git(submodule, "rev-parse", "HEAD").strip()

        self.git(
            self.origin,
            "-c",
            "protocol.file.allow=always",
            "submodule",
            "add",
            submodule.as_uri(),
            "Documentation",
        )
        self.git(self.origin, "commit", "-m", "add documentation gitlink")
        descriptor = {
            **self.descriptor,
            "revision": self.git(self.origin, "rev-parse", "HEAD").strip(),
        }
        cache = self.root / "gitlink-cache"
        record = materializer.materialize_entry(
            cache, descriptor, allow_file_url=True
        )
        self.assertEqual(record["format_version"], 3)
        self.assertEqual(record["gitlink_count"], 1)
        self.assertEqual(
            record["gitlinks"],
            [{"commit": gitlink_commit, "path": "Documentation"}],
        )
        checkout = cache / record["repository_path"] / "Documentation"
        self.assertTrue(not checkout.exists() or list(checkout.iterdir()) == [])
        self.assertFalse((checkout / "README.md").exists())
        self.assertEqual(
            materializer.verify_entry(
                cache, descriptor, allow_file_url=True
            ),
            record,
        )

    def test_url_and_descriptor_spoofing_are_refused(self) -> None:
        invalid = (
            "http://example.invalid/Remote.git",
            "https://user@example.invalid/Remote.git",
            "https://example.invalid/a/../Remote.git",
            "ssh://git@example.invalid/Remote.git",
        )
        for url in invalid:
            with self.subTest(url=url), self.assertRaises(
                materializer.MaterializationError
            ):
                materializer.normalized_remote_url(url)
        package = {
            "identity": "remote",
            "url": "https://example.invalid/Remote.git",
            "pin": {
                "location": "https://mirror.invalid/Remote.git",
                "revision": "a" * 40,
            },
        }
        with self.assertRaisesRegex(materializer.MaterializationError, "differs"):
            materializer.descriptor_for(package)

    def test_materialization_output_must_be_new_absolute_and_outside_source(
        self,
    ) -> None:
        outside = self.root / "output.json"
        self.assertEqual(
            materializer._new_output_path(outside, self.origin.resolve(), "output"),
            outside.resolve(strict=False),
        )
        with self.assertRaisesRegex(materializer.MaterializationError, "outside"):
            materializer._new_output_path(
                self.origin / "materializations.json", self.origin.resolve(), "output"
            )
        with self.assertRaisesRegex(materializer.MaterializationError, "absolute"):
            materializer._new_output_path(
                Path("relative.json"), self.origin.resolve(), "output"
            )
        outside.write_text("occupied", encoding="utf-8")
        with self.assertRaisesRegex(
            materializer.MaterializationError, "already exists"
        ):
            materializer._new_output_path(outside, self.origin.resolve(), "output")

    def test_materialization_set_binds_graph_order_count_and_identity(self) -> None:
        package = {
            "identity": "remote",
            "url": self.url,
            "pin": {"location": self.url, "revision": self.revision},
        }
        graph = {"external_packages": [package]}
        result = materializer.materialize_graph(graph, self.cache, allow_file_url=True)
        verified = materializer.verify_set(
            result, graph, self.cache, allow_file_url=True
        )
        self.assertEqual(list(verified), ["remote"])
        changed_graph = copy.deepcopy(graph)
        changed_graph["external_packages"][0]["identity"] = "other"
        with self.assertRaisesRegex(
            materializer.MaterializationError, "different source graph"
        ):
            materializer.verify_set(
                result, changed_graph, self.cache, allow_file_url=True
            )

    def test_complete_frozen_resolution_closure_is_materialized(self) -> None:
        other = self.root / "other-origin"
        other.mkdir()
        self.git(other, "init", "--initial-branch=main")
        self.git(other, "config", "user.name", "Package Test")
        self.git(other, "config", "user.email", "package@example.invalid")
        (other / "Package.swift").write_text(
            "// swift-tools-version: 6.0\n"
            "import PackageDescription\n"
            'let package = Package(name: "Other", targets: ['
            '.target(name: "Other")])\n',
            encoding="utf-8",
        )
        source = other / "Sources/Other/Other.swift"
        source.parent.mkdir(parents=True)
        source.write_text("public struct Other {}\n", encoding="utf-8")
        self.git(other, "add", "--all")
        self.git(other, "commit", "-m", "other pinned source")
        other_revision = self.git(other, "rev-parse", "HEAD").strip()
        other_url = other.as_uri()

        package = {
            "identity": "remote",
            "url": self.url,
            "pin": {"location": self.url, "revision": self.revision},
        }
        graph = {
            "external_packages": [package],
            "resolution_pins": [
                {
                    "identity": "remote",
                    "kind": "remoteSourceControl",
                    "location": self.url,
                    "revision": self.revision,
                },
                {
                    "identity": "other",
                    "kind": "remoteSourceControl",
                    "location": other_url,
                    "revision": other_revision,
                },
            ],
        }
        result = materializer.materialize_graph(
            graph, self.cache, allow_file_url=True
        )
        self.assertEqual(
            [record["identity"] for record in result["packages"]],
            ["other", "remote"],
        )
        self.assertEqual(
            set(
                materializer.verify_set(
                    result, graph, self.cache, allow_file_url=True
                )
            ),
            {"other", "remote"},
        )


if __name__ == "__main__":
    unittest.main()
