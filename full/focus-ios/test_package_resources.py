#!/usr/bin/env python3
"""Self-contained positive and adversarial tests for package_resources.py."""

from __future__ import annotations

import json
import os
from pathlib import Path, PurePosixPath
import stat
import tempfile
import unittest
from unittest.mock import patch

import package_resources as subject


HERE = Path(__file__).resolve().parent
SWIFT_MACHO_LINUX = HERE.parent.parent
PINNED_FOCUS = (
    SWIFT_MACHO_LINUX / "scratch" / "ladder-corpus" / "focus-ios" / "focus-ios"
)
PINNED_POLICY = HERE / "package-resources.json"


class PackageResourceFixtureTests(unittest.TestCase):
    """Exercise policy mechanics without depending on an external checkout."""

    def setUp(self) -> None:
        self.temp = tempfile.TemporaryDirectory(prefix="focus-package-resources-test.")
        self.root = Path(self.temp.name)
        self.repo = self.root / "focus-ios"
        self.repo.mkdir()
        self.commit = "a" * 40

        self.manifest_path = "BlockzillaPackage/Package.swift"
        self._put(self.manifest_path, b"// fixture Package.swift\n")
        self.group_shapes = [
            (
                "DesignSystem",
                "raw-unhandled",
                "BlockzillaPackage/Sources/DesignSystem/Colors.xcassets",
                "resources/DesignSystem/Colors.xcassets",
                "directory",
            ),
            (
                "DesignSystem",
                "raw-unhandled",
                "BlockzillaPackage/Sources/DesignSystem/Assets.xcassets",
                "resources/DesignSystem/Assets.xcassets",
                "directory",
            ),
            (
                "Widget",
                "raw-unhandled",
                "BlockzillaPackage/Sources/Widget/Media.xcassets",
                "resources/Widget/Media.xcassets",
                "directory",
            ),
            (
                "Licenses",
                "declared-copy",
                "BlockzillaPackage/Sources/Licenses/license-list.plist",
                "resources/Licenses/license-list.plist",
                "file",
            ),
            (
                "Licenses",
                "declared-copy",
                "BlockzillaPackage/Sources/Licenses/focus-ios.plist",
                "resources/Licenses/focus-ios.plist",
                "file",
            ),
        ]
        self._put(
            "BlockzillaPackage/Sources/DesignSystem/Colors.xcassets/Contents.json",
            b'{"fixture":"colors"}\n',
        )
        self._put(
            "BlockzillaPackage/Sources/DesignSystem/Colors.xcassets/Accent.colorset/Contents.json",
            b'{"color":"accent"}\n',
        )
        self._put(
            "BlockzillaPackage/Sources/DesignSystem/Assets.xcassets/Contents.json",
            b'{"fixture":"images"}\n',
        )
        self._put(
            "BlockzillaPackage/Sources/DesignSystem/Assets.xcassets/logo.imageset/Contents.json",
            b'{"filename":"logo.pdf"}\n',
        )
        self._put(
            "BlockzillaPackage/Sources/DesignSystem/Assets.xcassets/logo.imageset/logo.pdf",
            b"%PDF-fixture-design-system\n",
        )
        self._put(
            "BlockzillaPackage/Sources/Widget/Media.xcassets/Contents.json",
            b'{"fixture":"widget"}\n',
        )
        self._put(
            "BlockzillaPackage/Sources/Widget/Media.xcassets/Gradient.colorset/Contents.json",
            b'{"color":"gradient"}\n',
        )
        self._put(
            "BlockzillaPackage/Sources/Widget/Media.xcassets/icon.imageset/icon.pdf",
            b"%PDF-fixture-widget\n",
        )
        self._put(
            "BlockzillaPackage/Sources/Licenses/license-list.plist",
            b"fixture dependency licenses\n",
        )
        self._put(
            "BlockzillaPackage/Sources/Licenses/focus-ios.plist",
            b"fixture Focus license\n",
        )

        self.module_source_paths = [
            "BlockzillaPackage/Sources/DesignSystem/Bundle+CurrentBundle.swift",
            "BlockzillaPackage/Sources/DesignSystem/UIColor+AppColors.swift",
            "BlockzillaPackage/Sources/DesignSystem/UIFont+AppFonts.swift",
            "BlockzillaPackage/Sources/DesignSystem/UIImage+AppImages.swift",
        ]
        for index, relative in enumerate(self.module_source_paths):
            self._put(relative, f"// fixture source {index}\n".encode("utf-8"))

        self.resources = self._make_resource_policy()
        all_resource_records = self._all_resource_records(self.resources)
        staged_records = [
            (self._stage_path(resource, path), data)
            for resource in self.resources
            for path, data in self._group_records(resource)
        ]
        module_sources = []
        module_records = []
        for relative in self.module_source_paths:
            data = (self.repo / relative).read_bytes()
            module_sources.append(
                {"path": relative, "size": len(data), "sha256": subject.sha256(data)}
            )
            module_records.append((relative, data))
        manifest_data = (self.repo / self.manifest_path).read_bytes()
        self.manifest = {
            "path": self.manifest_path,
            "size": len(manifest_data),
            "sha256": subject.sha256(manifest_data),
        }
        self.module_proof = {
            "target": "DesignSystem",
            "openuikit_commit": "b" * 40,
            "sources": module_sources,
            "source_digest": subject.records_digest(module_records),
            "accessor": {
                "stage_path": "accessors/DesignSystem/Bundle+Module.swift",
                "size": len(subject.ACCESSOR_BYTES),
                "sha256": subject.sha256(subject.ACCESSOR_BYTES),
            },
        }
        self.policy = {
            "schema": 1,
            "repository_commit": self.commit,
            "package_manifest": self.manifest,
            "resources": self.resources,
            "source_digest": subject.records_digest(all_resource_records),
            "staged_resource_digest": subject.records_digest(staged_records),
            "module_proof": self.module_proof,
        }
        self.policy_path = self.root / "policy.json"
        self.policy_path.write_bytes(subject.canonical_json(self.policy))
        self.stage_path = self.root / "stage"
        self.audit_path = self.root / "audit.json"
        self.tracked = subject._byte_sort(path for path, _ in all_resource_records)
        self.fake_commit = self.commit

        self.constant_patch = patch.multiple(
            subject,
            APPROVED_COMMIT=self.commit,
            APPROVED_MANIFEST=self.manifest,
            APPROVED_RESOURCES=tuple(self.resources),
            APPROVED_SOURCE_DIGEST=self.policy["source_digest"],
            APPROVED_STAGED_RESOURCE_DIGEST=self.policy["staged_resource_digest"],
            APPROVED_MODULE_PROOF=self.module_proof,
        )
        self.constant_patch.start()

    def tearDown(self) -> None:
        self.constant_patch.stop()
        self.temp.cleanup()

    def _put(self, relative: str, data: bytes) -> None:
        destination = self.repo / relative
        destination.parent.mkdir(parents=True, exist_ok=True)
        destination.write_bytes(data)

    def _paths_below(self, root: str, kind: str) -> list[str]:
        root_path = self.repo / root
        if kind == "file":
            return [root]
        return subject._byte_sort(
            path.relative_to(self.repo).as_posix()
            for path in root_path.rglob("*")
            if path.is_file()
        )

    def _make_resource_policy(self) -> list[dict]:
        resources = []
        for target, declaration, source, stage, kind in self.group_shapes:
            paths = self._paths_below(source, kind)
            records = [(path, (self.repo / path).read_bytes()) for path in paths]
            resources.append(
                {
                    "target": target,
                    "declaration": declaration,
                    "source_path": source,
                    "stage_path": stage,
                    "kind": kind,
                    "file_count": len(records),
                    "byte_count": sum(len(data) for _, data in records),
                    "source_digest": subject.records_digest(records),
                }
            )
        return resources

    def _group_records(self, resource: dict) -> list[tuple[str, bytes]]:
        return [
            (path, (self.repo / path).read_bytes())
            for path in self._paths_below(resource["source_path"], resource["kind"])
        ]

    def _all_resource_records(
        self, resources: list[dict]
    ) -> list[tuple[str, bytes]]:
        return [record for resource in resources for record in self._group_records(resource)]

    @staticmethod
    def _stage_path(resource: dict, source: str) -> str:
        if resource["kind"] == "file":
            return resource["stage_path"]
        suffix = PurePosixPath(source).relative_to(
            PurePosixPath(resource["source_path"])
        )
        return (PurePosixPath(resource["stage_path"]) / suffix).as_posix()

    def fake_git(self, repo: Path, *args: str) -> bytes:
        self.assertEqual(repo, self.repo.resolve())
        if args == ("rev-parse", "--verify", "HEAD^{commit}"):
            return (self.fake_commit + "\n").encode("ascii")
        expected_roots = tuple(resource["source_path"] for resource in self.resources)
        if args == ("ls-files", "-z", "--", *expected_roots):
            return b"".join(path.encode("utf-8") + b"\0" for path in self.tracked)
        self.fail(f"unexpected git invocation: {args}")

    def run_stage(self, policy_path: Path | None = None):
        with patch.object(subject, "git", side_effect=self.fake_git):
            return subject.stage(
                str(self.repo),
                str(policy_path or self.policy_path),
                str(self.stage_path),
                str(self.audit_path),
            )

    def run_verify(self):
        with patch.object(subject, "git", side_effect=self.fake_git):
            return subject.verify(
                str(self.repo),
                str(self.policy_path),
                str(self.stage_path),
                str(self.audit_path),
            )

    def write_changed_policy(self, policy: dict) -> Path:
        changed = self.root / "changed-policy.json"
        changed.write_bytes(subject.canonical_json(policy))
        return changed

    def first_staged_resource(self) -> Path:
        relative = self._stage_path(
            self.resources[0], self._group_records(self.resources[0])[0][0]
        )
        return self.stage_path / relative

    def test_positive_stage_and_verify_preserve_catalog_hierarchy(self) -> None:
        audit = self.run_stage()
        verified = self.run_verify()
        self.assertEqual(verified, audit)
        self.assertEqual(audit["resource_file_count"], 10)
        self.assertTrue(
            (
                self.stage_path
                / "resources/DesignSystem/Assets.xcassets/logo.imageset/logo.pdf"
            ).is_file()
        )
        self.assertEqual(
            (
                self.stage_path
                / "accessors/DesignSystem/Bundle+Module.swift"
            ).read_bytes(),
            subject.ACCESSOR_BYTES,
        )
        staged_swift = list(self.stage_path.rglob("*.swift"))
        self.assertEqual(len(staged_swift), 1)
        for path in self.stage_path.rglob("*"):
            expected = 0o755 if path.is_dir() else 0o644
            self.assertEqual(stat.S_IMODE(path.lstat().st_mode), expected)
        self.assertEqual(stat.S_IMODE(self.stage_path.lstat().st_mode), 0o755)

    def test_two_fresh_stages_have_identical_inventory_bytes_and_audits(self) -> None:
        self.run_stage()
        first_files, first_directories = subject._walk_stage(self.stage_path)
        first_payloads = {
            relative: (self.stage_path / relative).read_bytes()
            for relative in first_files
        }
        first_audit = self.audit_path.read_bytes()

        second_stage = self.root / "stage-two"
        second_audit = self.root / "audit-two.json"
        with patch.object(subject, "git", side_effect=self.fake_git):
            subject.stage(
                str(self.repo),
                str(self.policy_path),
                str(second_stage),
                str(second_audit),
            )
        second_files, second_directories = subject._walk_stage(second_stage)
        self.assertEqual(second_files, first_files)
        self.assertEqual(second_directories, first_directories)
        self.assertEqual(
            {relative: (second_stage / relative).read_bytes() for relative in second_files},
            first_payloads,
        )
        self.assertEqual(second_audit.read_bytes(), first_audit)

    def test_refuses_stale_stage_without_touching_it(self) -> None:
        self.stage_path.mkdir()
        sentinel = self.stage_path / "user-data"
        sentinel.write_bytes(b"keep me")
        with self.assertRaisesRegex(subject.PolicyError, "stale stage"):
            self.run_stage()
        self.assertEqual(sentinel.read_bytes(), b"keep me")
        self.assertFalse(self.audit_path.exists())

    def test_refuses_stale_audit_before_creating_stage(self) -> None:
        self.audit_path.write_bytes(b"old audit")
        with self.assertRaisesRegex(subject.PolicyError, "stale audit"):
            self.run_stage()
        self.assertFalse(self.stage_path.exists())
        self.assertEqual(self.audit_path.read_bytes(), b"old audit")

    def test_verify_refuses_tampered_staged_bytes(self) -> None:
        self.run_stage()
        staged = self.first_staged_resource()
        changed = bytearray(staged.read_bytes())
        changed[0] ^= 1
        staged.write_bytes(changed)
        with self.assertRaisesRegex(subject.PolicyError, "tampered"):
            self.run_verify()

    def test_verify_refuses_untracked_staged_file(self) -> None:
        self.run_stage()
        unexpected = self.stage_path / "resources/DesignSystem/untracked.bin"
        unexpected.write_bytes(b"not attested")
        with self.assertRaisesRegex(subject.PolicyError, "file inventory"):
            self.run_verify()

    def test_verify_refuses_untracked_staged_directory(self) -> None:
        self.run_stage()
        (self.stage_path / "resources/DesignSystem/empty-untracked").mkdir()
        with self.assertRaisesRegex(subject.PolicyError, "directory inventory"):
            self.run_verify()

    def test_verify_refuses_staged_symlink(self) -> None:
        self.run_stage()
        staged = self.first_staged_resource()
        target = self.stage_path / "accessors/DesignSystem/Bundle+Module.swift"
        staged.unlink()
        staged.symlink_to(target)
        with self.assertRaisesRegex(subject.PolicyError, "must not contain symlinks"):
            self.run_verify()

    def test_verify_refuses_staged_root_mode_tamper(self) -> None:
        self.run_stage()
        self.stage_path.chmod(0o700)
        with self.assertRaisesRegex(subject.PolicyError, "root directory mode"):
            self.run_verify()

    def test_verify_refuses_stale_audit_bytes(self) -> None:
        self.run_stage()
        audit = json.loads(self.audit_path.read_text(encoding="utf-8"))
        audit["source_digest"] = "0" * 64
        self.audit_path.write_bytes(subject.canonical_json(audit))
        with self.assertRaisesRegex(subject.PolicyError, "audit is stale"):
            self.run_verify()

    def test_refuses_source_byte_tamper_at_same_size(self) -> None:
        source = self.repo / self.tracked[0]
        changed = bytearray(source.read_bytes())
        changed[0] ^= 1
        source.write_bytes(changed)
        with self.assertRaisesRegex(subject.PolicyError, "resource bytes changed"):
            self.run_stage()
        self.assertFalse(self.stage_path.exists())

    def test_refuses_untracked_source_file(self) -> None:
        self._put(
            "BlockzillaPackage/Sources/DesignSystem/Colors.xcassets/Untracked.colorset/Contents.json",
            b"{}\n",
        )
        with self.assertRaisesRegex(subject.PolicyError, "resource inventory changed"):
            self.run_stage()
        self.assertFalse(self.stage_path.exists())

    def test_refuses_untracked_empty_source_directory(self) -> None:
        (
            self.repo
            / "BlockzillaPackage/Sources/DesignSystem/Colors.xcassets/Empty.colorset"
        ).mkdir()
        with self.assertRaisesRegex(subject.PolicyError, "untracked or empty directory"):
            self.run_stage()

    def test_refuses_source_symlink(self) -> None:
        source = self.repo / self.tracked[0]
        other = self.repo / self.tracked[1]
        source.unlink()
        source.symlink_to(other)
        with self.assertRaisesRegex(subject.PolicyError, "must not contain symlinks"):
            self.run_stage()

    def test_refuses_package_manifest_tamper(self) -> None:
        manifest = self.repo / self.manifest_path
        changed = bytearray(manifest.read_bytes())
        changed[0] ^= 1
        manifest.write_bytes(changed)
        with self.assertRaisesRegex(subject.PolicyError, "Package.swift hash changed"):
            self.run_stage()

    def test_refuses_designsystem_source_tamper(self) -> None:
        source = self.repo / self.module_source_paths[0]
        changed = bytearray(source.read_bytes())
        changed[0] ^= 1
        source.write_bytes(changed)
        with self.assertRaisesRegex(subject.PolicyError, "DesignSystem source changed"):
            self.run_stage()

    def test_refuses_commit_drift(self) -> None:
        self.fake_commit = "c" * 40
        with self.assertRaisesRegex(subject.PolicyError, "Focus pin changed"):
            self.run_stage()

    def test_git_pin_checks_strip_ambient_redirection_and_configuration(self) -> None:
        with patch.dict(
            os.environ,
            {
                "GIT_DIR": "/tmp/redirected-git-dir",
                "GIT_WORK_TREE": "/tmp/redirected-work-tree",
                "GIT_CONFIG_GLOBAL": "/tmp/untrusted-gitconfig",
                "GIT_NO_REPLACE_OBJECTS": "0",
            },
            clear=False,
        ):
            environment = subject.controlled_git_environment()
        self.assertNotIn("GIT_DIR", environment)
        self.assertNotIn("GIT_WORK_TREE", environment)
        self.assertEqual(environment["GIT_CONFIG_GLOBAL"], os.devnull)
        self.assertEqual(environment["GIT_CONFIG_NOSYSTEM"], "1")
        self.assertEqual(environment["GIT_NO_REPLACE_OBJECTS"], "1")
        self.assertEqual(environment["GIT_OPTIONAL_LOCKS"], "0")

    def test_refuses_valid_but_unreviewed_policy_widening(self) -> None:
        changed = json.loads(json.dumps(self.policy))
        changed["resources"][0]["declaration"] = "declared-copy"
        changed_policy = self.write_changed_policy(changed)
        with self.assertRaisesRegex(subject.PolicyError, "reviewed Focus resource subject"):
            self.run_stage(changed_policy)

    def test_refuses_source_path_escape_before_repository_access(self) -> None:
        changed = json.loads(json.dumps(self.policy))
        changed["resources"][0]["source_path"] = "../outside.xcassets"
        changed_policy = self.write_changed_policy(changed)
        with self.assertRaisesRegex(subject.PolicyError, "escapes or aliases"):
            self.run_stage(changed_policy)
        self.assertFalse(self.stage_path.exists())

    def test_refuses_stage_path_escape(self) -> None:
        changed = json.loads(json.dumps(self.policy))
        changed["resources"][0]["stage_path"] = "resources/DesignSystem/../../escape"
        changed_policy = self.write_changed_policy(changed)
        with self.assertRaisesRegex(subject.PolicyError, "escapes or aliases"):
            self.run_stage(changed_policy)
        self.assertFalse((self.root / "escape").exists())

    def test_refuses_absolute_and_backslash_policy_paths(self) -> None:
        for malicious in ("/tmp/escape", "resources\\escape"):
            changed = json.loads(json.dumps(self.policy))
            changed["module_proof"]["accessor"]["stage_path"] = malicious
            changed_policy = self.write_changed_policy(changed)
            with self.subTest(path=malicious):
                with self.assertRaises(subject.PolicyError):
                    self.run_stage(changed_policy)


class PinnedPackageResourceIntegrationTests(unittest.TestCase):
    def test_exact_focus_checkout_stages_and_verifies(self) -> None:
        if not PINNED_FOCUS.is_dir():
            self.skipTest(f"pinned Focus checkout is unavailable: {PINNED_FOCUS}")
        with tempfile.TemporaryDirectory(prefix="focus-package-resources-pinned.") as temp:
            root = Path(temp)
            stage_path = root / "stage"
            audit_path = root / "audit.json"
            audit = subject.stage(
                str(PINNED_FOCUS),
                str(PINNED_POLICY),
                str(stage_path),
                str(audit_path),
            )
            self.assertEqual(
                subject.verify(
                    str(PINNED_FOCUS),
                    str(PINNED_POLICY),
                    str(stage_path),
                    str(audit_path),
                ),
                audit,
            )
            self.assertEqual(audit["resource_file_count"], 124)
            self.assertEqual(audit["resource_byte_count"], 314632)
            self.assertEqual(
                audit["source_digest"],
                "c04936bbf7e156abd3e417c5234b168026d0260c8e3eacd8aa3c0a8e83015f19",
            )
            self.assertEqual(len(audit["module_proof"]["sources"]), 4)
            self.assertTrue(
                (
                    stage_path
                    / "resources/Widget/Media.xcassets/icon_logo.imageset/icon_logo.pdf"
                ).is_file()
            )
            self.assertEqual(
                list(stage_path.rglob("*.swift")),
                [stage_path / "accessors/DesignSystem/Bundle+Module.swift"],
            )


if __name__ == "__main__":
    unittest.main()
