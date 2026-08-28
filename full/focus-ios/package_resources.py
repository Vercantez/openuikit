#!/usr/bin/env python3
"""Fail-closed staging for the pinned Focus package-resource slice.

This is intentionally not a general SwiftPM resource interpreter.  It accepts
one reviewed Focus commit, one reviewed Package.swift, five resource roots, and
one compile-only DesignSystem ``Bundle.module`` accessor.  Both source and
staged inventories are byte-attested; directory structure below each catalog
is retained exactly.

The staged accessor defines a trapping ``Bundle.module`` only so the four
shipping DesignSystem sources can emit a module.  It deliberately makes no
claim that Foundation can discover this tool's staged directories at runtime.
"""

from __future__ import annotations

from dataclasses import dataclass
import hashlib
import json
import os
from pathlib import Path, PurePosixPath
import re
import stat
import subprocess
import sys
from typing import Any, Iterable


APPROVED_COMMIT = "a2832521c1daa0c23419c73705ae043ed60c9791"
APPROVED_MANIFEST = {
    "path": "BlockzillaPackage/Package.swift",
    "size": 1975,
    "sha256": "2d29b769de137389f5613de6755211b255533375bf6003a2192f514e96899248",
}
APPROVED_RESOURCES = (
    {
        "target": "DesignSystem",
        "declaration": "raw-unhandled",
        "source_path": "BlockzillaPackage/Sources/DesignSystem/Colors.xcassets",
        "stage_path": "resources/DesignSystem/Colors.xcassets",
        "kind": "directory",
        "file_count": 40,
        "byte_count": 18621,
        "source_digest": "da3cadc474b51d242db2dde483c15b4c5c0b03bac0df11c3ff1dd32281e994d4",
    },
    {
        "target": "DesignSystem",
        "declaration": "raw-unhandled",
        "source_path": "BlockzillaPackage/Sources/DesignSystem/Assets.xcassets",
        "stage_path": "resources/DesignSystem/Assets.xcassets",
        "kind": "directory",
        "file_count": 77,
        "byte_count": 150818,
        "source_digest": "9a06e64a83591e2dc2e7f6e44afd6f181c4f9501f4bf22502887b3033e025532",
    },
    {
        "target": "Widget",
        "declaration": "raw-unhandled",
        "source_path": "BlockzillaPackage/Sources/Widget/Media.xcassets",
        "stage_path": "resources/Widget/Media.xcassets",
        "kind": "directory",
        "file_count": 5,
        "byte_count": 73131,
        "source_digest": "cf65ea586b104d622bb50ec5f0c09a1dc11ec0f293d322776dbb6f698f880126",
    },
    {
        "target": "Licenses",
        "declaration": "declared-copy",
        "source_path": "BlockzillaPackage/Sources/Licenses/license-list.plist",
        "stage_path": "resources/Licenses/license-list.plist",
        "kind": "file",
        "file_count": 1,
        "byte_count": 55562,
        "source_digest": "8c814c66d2e1fb2d38bd6442b1dcd9793327ca7a596b5179060b766275bef377",
    },
    {
        "target": "Licenses",
        "declaration": "declared-copy",
        "source_path": "BlockzillaPackage/Sources/Licenses/focus-ios.plist",
        "stage_path": "resources/Licenses/focus-ios.plist",
        "kind": "file",
        "file_count": 1,
        "byte_count": 16500,
        "source_digest": "e613db4a1ae22ea3b65a35f7b36e047b88e8b8dea6266c5e94cb250e8193ec45",
    },
)
APPROVED_SOURCE_DIGEST = (
    "c04936bbf7e156abd3e417c5234b168026d0260c8e3eacd8aa3c0a8e83015f19"
)
APPROVED_STAGED_RESOURCE_DIGEST = (
    "0e58bc76ee291d321cd94a1c98310cee0e86703f17cf48ea5be0dbaa64fb4bee"
)
APPROVED_MODULE_PROOF = {
    "target": "DesignSystem",
    "openuikit_commit": "81e1e05fbde712a28ea031534462b80740ed5eb5",
    "sources": [
        {
            "path": "BlockzillaPackage/Sources/DesignSystem/Bundle+CurrentBundle.swift",
            "size": 2060,
            "sha256": "725315f04ecbbe4bdeceb73bdf07550e2c3f38307696d0fa7035600e018ca3af",
        },
        {
            "path": "BlockzillaPackage/Sources/DesignSystem/UIColor+AppColors.swift",
            "size": 3248,
            "sha256": "4078f76f180d37f6d560dd63d59ef161302a73b7f416933533663700c314224f",
        },
        {
            "path": "BlockzillaPackage/Sources/DesignSystem/UIFont+AppFonts.swift",
            "size": 1412,
            "sha256": "ac4895febb0ad6c588ada61420b0b271afb33092d76e1dbed828ee8b337c83e6",
        },
        {
            "path": "BlockzillaPackage/Sources/DesignSystem/UIImage+AppImages.swift",
            "size": 2152,
            "sha256": "ba5720a57aa90406b95a66ea62433557b666c1558d59781018de050585797734",
        },
    ],
    "source_digest": "00d6773590819770061d4dc9e23adedc1f5ed39962a321475093289edf28ca9b",
    "accessor": {
        "stage_path": "accessors/DesignSystem/Bundle+Module.swift",
        "size": 146,
        "sha256": "c0a3ee61e4fc8015d5e4a36775293347e21c58850605a6d47141f344211829aa",
    },
}

ACCESSOR_BYTES = (
    b"import Foundation\n"
    b"\n"
    b"extension Foundation.Bundle {\n"
    b"    static var module: Bundle { fatalError(\"runtime Bundle.module discovery is unavailable\") }\n"
    b"}\n"
)

POLICY_KEYS = {
    "schema",
    "repository_commit",
    "package_manifest",
    "resources",
    "source_digest",
    "staged_resource_digest",
    "module_proof",
}
MANIFEST_KEYS = {"path", "size", "sha256"}
RESOURCE_KEYS = {
    "target",
    "declaration",
    "source_path",
    "stage_path",
    "kind",
    "file_count",
    "byte_count",
    "source_digest",
}
MODULE_PROOF_KEYS = {
    "target",
    "openuikit_commit",
    "sources",
    "source_digest",
    "accessor",
}
SOURCE_KEYS = {"path", "size", "sha256"}
ACCESSOR_KEYS = {"stage_path", "size", "sha256"}
SHA256_RE = re.compile(r"[0-9a-f]{64}\Z")
COMMIT_RE = re.compile(r"[0-9a-f]{40}\Z")
NOFOLLOW = getattr(os, "O_NOFOLLOW", 0)
DIRECTORY = getattr(os, "O_DIRECTORY", 0)


class PolicyError(RuntimeError):
    """The requested source or stage is not the reviewed subject."""


@dataclass(frozen=True)
class ResourceFile:
    source_path: str
    stage_path: str
    data: bytes

    @property
    def size(self) -> int:
        return len(self.data)

    @property
    def sha256(self) -> str:
        return sha256(self.data)

    def audit_record(self) -> dict[str, Any]:
        return {
            "source_path": self.source_path,
            "stage_path": self.stage_path,
            "size": self.size,
            "sha256": self.sha256,
        }


@dataclass(frozen=True)
class SourceFile:
    path: str
    data: bytes

    @property
    def size(self) -> int:
        return len(self.data)

    @property
    def sha256(self) -> str:
        return sha256(self.data)

    def audit_record(self) -> dict[str, Any]:
        return {"path": self.path, "size": self.size, "sha256": self.sha256}


@dataclass
class CapturedInputs:
    repository_commit: str
    package_manifest: SourceFile
    resource_groups: list[dict[str, Any]]
    resource_files: list[ResourceFile]
    module_sources: list[SourceFile]

    def identity(self) -> bytes:
        value = {
            "repository_commit": self.repository_commit,
            "package_manifest": self.package_manifest.audit_record(),
            "resources": [
                {
                    "source_path": group["policy"]["source_path"],
                    "source_directories": group["source_directories"],
                    "files": [item.audit_record() for item in group["files"]],
                }
                for group in self.resource_groups
            ],
            "module_sources": [item.audit_record() for item in self.module_sources],
        }
        return canonical_json(value)


def sha256(data: bytes) -> str:
    return hashlib.sha256(data).hexdigest()


def canonical_json(value: Any) -> bytes:
    return (json.dumps(value, indent=2, sort_keys=True) + "\n").encode("utf-8")


def _byte_sort(values: Iterable[str]) -> list[str]:
    return sorted(values, key=lambda value: value.encode("utf-8"))


def records_digest(records: Iterable[tuple[str, bytes]]) -> str:
    """Hash normalized path, byte count, and content hash for each file."""
    aggregate = hashlib.sha256()
    for path, data in sorted(records, key=lambda item: item[0].encode("utf-8")):
        aggregate.update(path.encode("utf-8"))
        aggregate.update(b"\0")
        aggregate.update(str(len(data)).encode("ascii"))
        aggregate.update(b"\0")
        aggregate.update(sha256(data).encode("ascii"))
        aggregate.update(b"\n")
    return aggregate.hexdigest()


def controlled_git_environment() -> dict[str, str]:
    """Keep ambient Git redirection/configuration out of pin checks."""
    environment = {
        name: value for name, value in os.environ.items() if not name.startswith("GIT_")
    }
    environment.update(
        {
            "GIT_CONFIG_GLOBAL": os.devnull,
            "GIT_CONFIG_NOSYSTEM": "1",
            "GIT_NO_REPLACE_OBJECTS": "1",
            "GIT_OPTIONAL_LOCKS": "0",
            "LANG": "C",
            "LC_ALL": "C",
        }
    )
    return environment


def git(repo: Path, *args: str) -> bytes:
    try:
        return subprocess.check_output(
            [
                "git",
                "-c",
                "core.fsmonitor=false",
                "-c",
                f"core.hooksPath={os.devnull}",
                "-C",
                str(repo),
                *args,
            ],
            stderr=subprocess.STDOUT,
            env=controlled_git_environment(),
        )
    except (OSError, subprocess.CalledProcessError) as exc:
        detail = getattr(exc, "output", b"")
        if isinstance(detail, bytes):
            rendered = detail.decode("utf-8", errors="replace").strip()
        else:
            rendered = str(detail)
        raise PolicyError(f"git {' '.join(args)} failed: {rendered}") from exc


def _require_exact_keys(value: Any, keys: set[str], label: str) -> dict[str, Any]:
    if not isinstance(value, dict) or set(value) != keys:
        raise PolicyError(f"{label} keys must be exactly {sorted(keys)}")
    return value


def _validate_integer(value: Any, label: str) -> int:
    if type(value) is not int or value < 0:
        raise PolicyError(f"{label} must be a non-negative integer")
    return value


def _validate_sha256(value: Any, label: str) -> str:
    if not isinstance(value, str) or not SHA256_RE.fullmatch(value):
        raise PolicyError(f"{label} must be a lowercase SHA-256")
    return value


def _validate_commit(value: Any, label: str) -> str:
    if not isinstance(value, str) or not COMMIT_RE.fullmatch(value):
        raise PolicyError(f"{label} must be a lowercase 40-byte Git object ID")
    return value


def _validate_relative(value: Any, label: str) -> str:
    if not isinstance(value, str) or not value:
        raise PolicyError(f"{label} must be a non-empty string")
    if "\\" in value or any(character in value for character in ("\0", "\n", "\r")):
        raise PolicyError(f"{label} contains a forbidden character")
    path = PurePosixPath(value)
    if path.is_absolute() or path.as_posix() != value:
        raise PolicyError(f"{label} is not a normalized relative POSIX path: {value!r}")
    if any(part in ("", ".", "..") for part in path.parts):
        raise PolicyError(f"{label} escapes or aliases its root: {value!r}")
    return value


def _validate_policy_shape(policy: Any) -> dict[str, Any]:
    policy = _require_exact_keys(policy, POLICY_KEYS, "policy")
    if type(policy["schema"]) is not int or policy["schema"] != 1:
        raise PolicyError("policy schema must be integer 1")
    _validate_commit(policy["repository_commit"], "repository_commit")

    manifest = _require_exact_keys(
        policy["package_manifest"], MANIFEST_KEYS, "package_manifest"
    )
    _validate_relative(manifest["path"], "package_manifest.path")
    _validate_integer(manifest["size"], "package_manifest.size")
    _validate_sha256(manifest["sha256"], "package_manifest.sha256")

    resources = policy["resources"]
    if not isinstance(resources, list) or not resources:
        raise PolicyError("resources must be a non-empty list")
    seen_sources: set[str] = set()
    seen_stages: set[str] = set()
    for index, raw_resource in enumerate(resources):
        label = f"resources[{index}]"
        resource = _require_exact_keys(raw_resource, RESOURCE_KEYS, label)
        if not isinstance(resource["target"], str) or not resource["target"]:
            raise PolicyError(f"{label}.target must be a non-empty string")
        if resource["declaration"] not in ("raw-unhandled", "declared-copy"):
            raise PolicyError(f"{label}.declaration is unsupported")
        source = _validate_relative(resource["source_path"], f"{label}.source_path")
        stage = _validate_relative(resource["stage_path"], f"{label}.stage_path")
        if not stage.startswith(f"resources/{resource['target']}/"):
            raise PolicyError(f"{label}.stage_path is outside its target stage root")
        if resource["kind"] not in ("directory", "file"):
            raise PolicyError(f"{label}.kind must be directory or file")
        _validate_integer(resource["file_count"], f"{label}.file_count")
        _validate_integer(resource["byte_count"], f"{label}.byte_count")
        _validate_sha256(resource["source_digest"], f"{label}.source_digest")
        if source in seen_sources or stage in seen_stages:
            raise PolicyError(f"{label} duplicates a source or stage path")
        seen_sources.add(source)
        seen_stages.add(stage)

    _validate_sha256(policy["source_digest"], "source_digest")
    _validate_sha256(policy["staged_resource_digest"], "staged_resource_digest")

    module = _require_exact_keys(
        policy["module_proof"], MODULE_PROOF_KEYS, "module_proof"
    )
    if not isinstance(module["target"], str) or not module["target"]:
        raise PolicyError("module_proof.target must be a non-empty string")
    _validate_commit(module["openuikit_commit"], "module_proof.openuikit_commit")
    if not isinstance(module["sources"], list) or not module["sources"]:
        raise PolicyError("module_proof.sources must be a non-empty list")
    seen_module_sources: set[str] = set()
    for index, raw_source in enumerate(module["sources"]):
        label = f"module_proof.sources[{index}]"
        source = _require_exact_keys(raw_source, SOURCE_KEYS, label)
        path = _validate_relative(source["path"], f"{label}.path")
        _validate_integer(source["size"], f"{label}.size")
        _validate_sha256(source["sha256"], f"{label}.sha256")
        if path in seen_module_sources:
            raise PolicyError(f"{label}.path is duplicated")
        seen_module_sources.add(path)
    _validate_sha256(module["source_digest"], "module_proof.source_digest")
    accessor = _require_exact_keys(
        module["accessor"], ACCESSOR_KEYS, "module_proof.accessor"
    )
    accessor_path = _validate_relative(
        accessor["stage_path"], "module_proof.accessor.stage_path"
    )
    if not accessor_path.startswith(f"accessors/{module['target']}/"):
        raise PolicyError("module_proof.accessor.stage_path is outside its target")
    _validate_integer(accessor["size"], "module_proof.accessor.size")
    _validate_sha256(accessor["sha256"], "module_proof.accessor.sha256")
    return policy


def expected_policy() -> dict[str, Any]:
    return {
        "schema": 1,
        "repository_commit": APPROVED_COMMIT,
        "package_manifest": dict(APPROVED_MANIFEST),
        "resources": [dict(resource) for resource in APPROVED_RESOURCES],
        "source_digest": APPROVED_SOURCE_DIGEST,
        "staged_resource_digest": APPROVED_STAGED_RESOURCE_DIGEST,
        "module_proof": json.loads(json.dumps(APPROVED_MODULE_PROOF)),
    }


def _read_regular_file(path: Path, label: str) -> bytes:
    try:
        before_link = path.lstat()
    except OSError as exc:
        raise PolicyError(f"cannot stat {label} {path}: {exc}") from exc
    if stat.S_ISLNK(before_link.st_mode):
        raise PolicyError(f"{label} must not be a symlink: {path}")
    flags = os.O_RDONLY | NOFOLLOW
    try:
        descriptor = os.open(path, flags)
    except OSError as exc:
        raise PolicyError(f"cannot open {label} {path}: {exc}") from exc
    try:
        before = os.fstat(descriptor)
        if not stat.S_ISREG(before.st_mode):
            raise PolicyError(f"{label} is not a regular file: {path}")
        chunks: list[bytes] = []
        while True:
            chunk = os.read(descriptor, 1024 * 1024)
            if not chunk:
                break
            chunks.append(chunk)
        after = os.fstat(descriptor)
        identity_before = (
            before.st_dev,
            before.st_ino,
            before.st_size,
            before.st_mtime_ns,
            before.st_ctime_ns,
        )
        identity_after = (
            after.st_dev,
            after.st_ino,
            after.st_size,
            after.st_mtime_ns,
            after.st_ctime_ns,
        )
        if identity_before != identity_after:
            raise PolicyError(f"{label} changed while it was being read: {path}")
        data = b"".join(chunks)
        if len(data) != after.st_size:
            raise PolicyError(f"{label} size changed while it was being read: {path}")
        return data
    finally:
        os.close(descriptor)


def load_policy(policy_path: Path) -> tuple[bytes, dict[str, Any]]:
    policy_bytes = _read_regular_file(policy_path, "policy")
    try:
        raw_policy = json.loads(policy_bytes)
    except json.JSONDecodeError as exc:
        raise PolicyError(f"cannot parse policy {policy_path}: {exc}") from exc
    policy = _validate_policy_shape(raw_policy)
    if policy != expected_policy():
        raise PolicyError("policy does not match the reviewed Focus resource subject")
    if len(ACCESSOR_BYTES) != policy["module_proof"]["accessor"]["size"]:
        raise PolicyError("compiled-in Bundle.module accessor size changed")
    if sha256(ACCESSOR_BYTES) != policy["module_proof"]["accessor"]["sha256"]:
        raise PolicyError("compiled-in Bundle.module accessor hash changed")
    return policy_bytes, policy


def _resolve_repository(value: str) -> Path:
    requested = Path(value)
    if requested.is_symlink():
        raise PolicyError(f"Focus repository must not be a symlink: {requested}")
    try:
        repo = requested.resolve(strict=True)
    except OSError as exc:
        raise PolicyError(f"cannot resolve Focus repository {value}: {exc}") from exc
    if not repo.is_dir():
        raise PolicyError(f"Focus repository is not a directory: {repo}")
    return repo


def _resolve_new_output(value: str, label: str) -> Path:
    raw = Path(value)
    if raw.name in ("", ".", ".."):
        raise PolicyError(f"{label} must name a new path")
    try:
        parent = raw.parent.resolve(strict=True)
    except OSError as exc:
        raise PolicyError(f"cannot resolve {label} parent {raw.parent}: {exc}") from exc
    if not parent.is_dir():
        raise PolicyError(f"{label} parent is not a directory: {parent}")
    return parent / raw.name


def _absolute_existing(value: str, label: str) -> Path:
    raw = Path(value)
    try:
        parent = raw.parent.resolve(strict=True)
    except OSError as exc:
        raise PolicyError(f"cannot resolve {label} parent {raw.parent}: {exc}") from exc
    return parent / raw.name


def _lexists(path: Path) -> bool:
    return os.path.lexists(os.fspath(path))


def _is_within(path: Path, parent: Path) -> bool:
    try:
        path.relative_to(parent)
        return True
    except ValueError:
        return False


def _check_output_relationships(repo: Path, stage: Path, audit: Path) -> None:
    if stage == audit or _is_within(audit, stage) or _is_within(stage, audit):
        raise PolicyError("stage and audit paths must be separate and non-nested")
    if _is_within(stage, repo) or _is_within(audit, repo):
        raise PolicyError("stage and audit outputs must be outside the Focus repository")


def _reject_symlink_components(repo: Path, relative: str) -> None:
    current = repo
    for part in PurePosixPath(relative).parts:
        current = current / part
        try:
            metadata = current.lstat()
        except OSError as exc:
            raise PolicyError(f"cannot stat approved input path {current}: {exc}") from exc
        if stat.S_ISLNK(metadata.st_mode):
            raise PolicyError(f"approved input path must not contain symlinks: {current}")


def _walk_directory(repo: Path, root_relative: str) -> tuple[list[str], list[str]]:
    root = repo / root_relative
    files: list[str] = []
    directories: list[str] = [root_relative]

    def walk(directory: Path) -> None:
        try:
            with os.scandir(directory) as iterator:
                entries = sorted(iterator, key=lambda entry: entry.name.encode("utf-8"))
        except (OSError, UnicodeEncodeError) as exc:
            raise PolicyError(f"cannot scan resource directory {directory}: {exc}") from exc
        for entry in entries:
            entry_path = Path(entry.path)
            relative = entry_path.relative_to(repo).as_posix()
            _validate_relative(relative, "discovered resource path")
            if entry.is_symlink():
                raise PolicyError(f"resource tree must not contain symlinks: {entry_path}")
            if entry.is_dir(follow_symlinks=False):
                directories.append(relative)
                walk(entry_path)
            elif entry.is_file(follow_symlinks=False):
                files.append(relative)
            else:
                raise PolicyError(f"resource entry is not a regular file: {entry_path}")

    walk(root)
    return _byte_sort(files), _byte_sort(directories)


def _tracked_resource_files(repo: Path, policy: dict[str, Any]) -> list[str]:
    roots = [resource["source_path"] for resource in policy["resources"]]
    raw = git(repo, "ls-files", "-z", "--", *roots)
    if raw and not raw.endswith(b"\0"):
        raise PolicyError("git ls-files returned a non-NUL-terminated inventory")
    tracked: list[str] = []
    for item in raw.split(b"\0"):
        if not item:
            continue
        try:
            decoded = item.decode("utf-8")
        except UnicodeDecodeError as exc:
            raise PolicyError("tracked resource path is not UTF-8") from exc
        tracked.append(_validate_relative(decoded, "tracked resource path"))
    if len(set(tracked)) != len(tracked):
        raise PolicyError("git returned duplicate tracked resource paths")
    return _byte_sort(tracked)


def _expected_directories(root: str, tracked_files: Iterable[str]) -> list[str]:
    root_path = PurePosixPath(root)
    directories = {root}
    for tracked in tracked_files:
        path = PurePosixPath(tracked)
        try:
            path.relative_to(root_path)
        except ValueError:
            continue
        parent = path.parent
        while True:
            directories.add(parent.as_posix())
            if parent == root_path:
                break
            parent = parent.parent
    return _byte_sort(directories)


def _resource_stage_path(resource: dict[str, Any], source_path: str) -> str:
    if resource["kind"] == "file":
        if source_path != resource["source_path"]:
            raise PolicyError("file resource expanded to more than its approved path")
        return resource["stage_path"]
    source_root = PurePosixPath(resource["source_path"])
    try:
        suffix = PurePosixPath(source_path).relative_to(source_root)
    except ValueError as exc:
        raise PolicyError(f"resource escaped its approved root: {source_path}") from exc
    return (PurePosixPath(resource["stage_path"]) / suffix).as_posix()


def _read_repo_file(repo: Path, relative: str, label: str) -> bytes:
    _reject_symlink_components(repo, relative)
    return _read_regular_file(repo / relative, label)


def capture_inputs(repo: Path, policy: dict[str, Any]) -> CapturedInputs:
    commit = git(repo, "rev-parse", "--verify", "HEAD^{commit}").decode(
        "ascii", errors="strict"
    ).strip()
    if commit != policy["repository_commit"]:
        raise PolicyError(
            f"Focus pin changed: expected {policy['repository_commit']}, got {commit}"
        )

    manifest_policy = policy["package_manifest"]
    manifest_data = _read_repo_file(
        repo, manifest_policy["path"], "Package.swift"
    )
    manifest = SourceFile(manifest_policy["path"], manifest_data)
    if manifest.size != manifest_policy["size"]:
        raise PolicyError("Package.swift size changed")
    if manifest.sha256 != manifest_policy["sha256"]:
        raise PolicyError("Package.swift hash changed")

    tracked_all = _tracked_resource_files(repo, policy)
    tracked_set = set(tracked_all)
    discovered_all: list[str] = []
    resource_groups: list[dict[str, Any]] = []
    resource_files: list[ResourceFile] = []

    for resource in policy["resources"]:
        source_root = resource["source_path"]
        _reject_symlink_components(repo, source_root)
        root_path = repo / source_root
        if resource["kind"] == "directory":
            try:
                metadata = root_path.lstat()
            except OSError as exc:
                raise PolicyError(f"cannot stat resource root {root_path}: {exc}") from exc
            if not stat.S_ISDIR(metadata.st_mode):
                raise PolicyError(f"resource root is not a directory: {root_path}")
            discovered, directories = _walk_directory(repo, source_root)
        else:
            try:
                metadata = root_path.lstat()
            except OSError as exc:
                raise PolicyError(f"cannot stat resource file {root_path}: {exc}") from exc
            if not stat.S_ISREG(metadata.st_mode):
                raise PolicyError(f"resource is not a regular file: {root_path}")
            discovered = [source_root]
            directories = []

        root_posix = PurePosixPath(source_root)
        tracked_group = [
            path
            for path in tracked_all
            if PurePosixPath(path) == root_posix
            or root_posix in PurePosixPath(path).parents
        ]
        if discovered != tracked_group:
            raise PolicyError(f"resource inventory changed below {source_root}")
        if resource["kind"] == "directory":
            expected_directories = _expected_directories(source_root, tracked_group)
            if directories != expected_directories:
                raise PolicyError(
                    f"untracked or empty directory changed below {source_root}"
                )

        group_files: list[ResourceFile] = []
        for source_path in discovered:
            data = _read_repo_file(repo, source_path, "resource file")
            item = ResourceFile(
                source_path,
                _resource_stage_path(resource, source_path),
                data,
            )
            group_files.append(item)
            resource_files.append(item)
        discovered_all.extend(discovered)

        actual_count = len(group_files)
        actual_bytes = sum(item.size for item in group_files)
        actual_digest = records_digest(
            (item.source_path, item.data) for item in group_files
        )
        if actual_count != resource["file_count"]:
            raise PolicyError(f"resource file count changed below {source_root}")
        if actual_bytes != resource["byte_count"]:
            raise PolicyError(f"resource byte count changed below {source_root}")
        if actual_digest != resource["source_digest"]:
            raise PolicyError(f"resource bytes changed below {source_root}")
        resource_groups.append(
            {
                "policy": resource,
                "source_directories": directories,
                "files": group_files,
            }
        )

    if _byte_sort(discovered_all) != tracked_all or set(discovered_all) != tracked_set:
        raise PolicyError("tracked resource inventory crossed approved resource roots")
    if len({item.source_path for item in resource_files}) != len(resource_files):
        raise PolicyError("approved resource roots overlap")
    if len({item.stage_path for item in resource_files}) != len(resource_files):
        raise PolicyError("approved resources collide in the stage")

    actual_source_digest = records_digest(
        (item.source_path, item.data) for item in resource_files
    )
    actual_stage_digest = records_digest(
        (item.stage_path, item.data) for item in resource_files
    )
    if actual_source_digest != policy["source_digest"]:
        raise PolicyError("aggregate resource source digest changed")
    if actual_stage_digest != policy["staged_resource_digest"]:
        raise PolicyError("aggregate staged-resource digest changed")

    module_sources: list[SourceFile] = []
    for expected in policy["module_proof"]["sources"]:
        data = _read_repo_file(repo, expected["path"], "DesignSystem source")
        item = SourceFile(expected["path"], data)
        if item.size != expected["size"] or item.sha256 != expected["sha256"]:
            raise PolicyError(f"DesignSystem source changed: {expected['path']}")
        module_sources.append(item)
    module_digest = records_digest((item.path, item.data) for item in module_sources)
    if module_digest != policy["module_proof"]["source_digest"]:
        raise PolicyError("DesignSystem source digest changed")

    after_commit = git(repo, "rev-parse", "--verify", "HEAD^{commit}").decode(
        "ascii", errors="strict"
    ).strip()
    if after_commit != commit:
        raise PolicyError("Focus commit changed while inputs were captured")
    return CapturedInputs(
        repository_commit=commit,
        package_manifest=manifest,
        resource_groups=resource_groups,
        resource_files=resource_files,
        module_sources=module_sources,
    )


def build_audit(
    policy_bytes: bytes, policy: dict[str, Any], captured: CapturedInputs
) -> dict[str, Any]:
    groups: list[dict[str, Any]] = []
    for group in captured.resource_groups:
        resource = group["policy"]
        groups.append(
            {
                "target": resource["target"],
                "declaration": resource["declaration"],
                "source_path": resource["source_path"],
                "stage_path": resource["stage_path"],
                "kind": resource["kind"],
                "file_count": len(group["files"]),
                "byte_count": sum(item.size for item in group["files"]),
                "source_digest": records_digest(
                    (item.source_path, item.data) for item in group["files"]
                ),
                "source_directories": group["source_directories"],
                "files": [item.audit_record() for item in group["files"]],
            }
        )
    staged_directories = _expected_stage_directories(captured, policy)
    return {
        "schema": 1,
        "repository_commit": captured.repository_commit,
        "policy_sha256": sha256(policy_bytes),
        "package_manifest": captured.package_manifest.audit_record(),
        "resource_file_count": len(captured.resource_files),
        "resource_byte_count": sum(item.size for item in captured.resource_files),
        "source_digest": records_digest(
            (item.source_path, item.data) for item in captured.resource_files
        ),
        "staged_resource_digest": records_digest(
            (item.stage_path, item.data) for item in captured.resource_files
        ),
        "resources": groups,
        "staged_directories": staged_directories,
        "module_proof": {
            "target": policy["module_proof"]["target"],
            "openuikit_commit": policy["module_proof"]["openuikit_commit"],
            "source_digest": records_digest(
                (item.path, item.data) for item in captured.module_sources
            ),
            "sources": [item.audit_record() for item in captured.module_sources],
            "accessor": {
                "stage_path": policy["module_proof"]["accessor"]["stage_path"],
                "size": len(ACCESSOR_BYTES),
                "sha256": sha256(ACCESSOR_BYTES),
            },
        },
    }


def _expected_payloads(
    captured: CapturedInputs, policy: dict[str, Any]
) -> dict[str, bytes]:
    payloads = {item.stage_path: item.data for item in captured.resource_files}
    accessor_path = policy["module_proof"]["accessor"]["stage_path"]
    if accessor_path in payloads:
        raise PolicyError("Bundle.module accessor collides with a staged resource")
    payloads[accessor_path] = ACCESSOR_BYTES
    return payloads


def _expected_stage_directories(
    captured: CapturedInputs, policy: dict[str, Any]
) -> list[str]:
    directories: set[str] = set()
    for path in _expected_payloads(captured, policy):
        parent = PurePosixPath(path).parent
        while parent != PurePosixPath("."):
            directories.add(parent.as_posix())
            parent = parent.parent
    return _byte_sort(directories)


def _write_all(descriptor: int, data: bytes) -> None:
    offset = 0
    while offset < len(data):
        written = os.write(descriptor, data[offset:])
        if written <= 0:
            raise PolicyError("short write while publishing staged output")
        offset += written


def _write_relative(root_descriptor: int, relative: str, data: bytes) -> None:
    normalized = _validate_relative(relative, "staged output path")
    parts = PurePosixPath(normalized).parts
    current = os.dup(root_descriptor)
    try:
        for part in parts[:-1]:
            try:
                os.mkdir(part, 0o755, dir_fd=current)
            except FileExistsError:
                pass
            try:
                following = os.open(
                    part, os.O_RDONLY | DIRECTORY | NOFOLLOW, dir_fd=current
                )
            except OSError as exc:
                raise PolicyError(f"cannot enter staged directory {part}: {exc}") from exc
            os.close(current)
            current = following
            os.fchmod(current, 0o755)
        try:
            output = os.open(
                parts[-1],
                os.O_WRONLY | os.O_CREAT | os.O_EXCL | NOFOLLOW,
                0o644,
                dir_fd=current,
            )
        except OSError as exc:
            raise PolicyError(f"cannot create staged file {relative}: {exc}") from exc
        try:
            _write_all(output, data)
            os.fchmod(output, 0o644)
            os.fsync(output)
        finally:
            os.close(output)
    finally:
        os.close(current)


def _walk_stage(stage: Path) -> tuple[list[str], list[str]]:
    try:
        root_metadata = stage.lstat()
    except OSError as exc:
        raise PolicyError(f"cannot stat stage root {stage}: {exc}") from exc
    if stat.S_ISLNK(root_metadata.st_mode) or not stat.S_ISDIR(root_metadata.st_mode):
        raise PolicyError(f"stage root must be a real directory: {stage}")
    files: list[str] = []
    directories: list[str] = []

    def walk(directory: Path) -> None:
        try:
            with os.scandir(directory) as iterator:
                entries = sorted(iterator, key=lambda entry: entry.name.encode("utf-8"))
        except (OSError, UnicodeEncodeError) as exc:
            raise PolicyError(f"cannot scan stage directory {directory}: {exc}") from exc
        for entry in entries:
            path = Path(entry.path)
            relative = path.relative_to(stage).as_posix()
            _validate_relative(relative, "staged inventory path")
            if entry.is_symlink():
                raise PolicyError(f"staged inventory must not contain symlinks: {path}")
            if entry.is_dir(follow_symlinks=False):
                directories.append(relative)
                walk(path)
            elif entry.is_file(follow_symlinks=False):
                files.append(relative)
            else:
                raise PolicyError(f"staged entry is not a regular file: {path}")

    walk(stage)
    return _byte_sort(files), _byte_sort(directories)


def verify_stage(
    stage: Path, captured: CapturedInputs, policy: dict[str, Any]
) -> None:
    payloads = _expected_payloads(captured, policy)
    files, directories = _walk_stage(stage)
    if stat.S_IMODE(stage.lstat().st_mode) != 0o755:
        raise PolicyError("staged root directory mode changed")
    expected_files = _byte_sort(payloads)
    expected_directories = _expected_stage_directories(captured, policy)
    if files != expected_files:
        raise PolicyError("staged file inventory is stale, missing, or untracked")
    if directories != expected_directories:
        raise PolicyError("staged directory inventory is stale, missing, or untracked")
    for relative in expected_files:
        data = _read_regular_file(stage / relative, "staged file")
        if data != payloads[relative]:
            raise PolicyError(f"staged file was tampered with: {relative}")
        mode = stat.S_IMODE((stage / relative).lstat().st_mode)
        if mode != 0o644:
            raise PolicyError(f"staged file mode changed: {relative}")
    for relative in expected_directories:
        mode = stat.S_IMODE((stage / relative).lstat().st_mode)
        if mode != 0o755:
            raise PolicyError(f"staged directory mode changed: {relative}")


def _write_audit_exclusive(audit: Path, data: bytes) -> None:
    try:
        descriptor = os.open(
            audit, os.O_WRONLY | os.O_CREAT | os.O_EXCL | NOFOLLOW, 0o644
        )
    except OSError as exc:
        raise PolicyError(f"cannot create audit file {audit}: {exc}") from exc
    try:
        _write_all(descriptor, data)
        os.fchmod(descriptor, 0o644)
        os.fsync(descriptor)
    finally:
        os.close(descriptor)


def stage(
    repo_value: str, policy_value: str, stage_value: str, audit_value: str
) -> dict[str, Any]:
    repo = _resolve_repository(repo_value)
    policy_path = _absolute_existing(policy_value, "policy")
    stage_path = _resolve_new_output(stage_value, "stage")
    audit_path = _resolve_new_output(audit_value, "audit")
    _check_output_relationships(repo, stage_path, audit_path)
    if _lexists(stage_path):
        raise PolicyError(f"stale stage output already exists: {stage_path}")
    if _lexists(audit_path):
        raise PolicyError(f"stale audit output already exists: {audit_path}")

    policy_bytes, policy = load_policy(policy_path)
    before = capture_inputs(repo, policy)
    payloads = _expected_payloads(before, policy)

    try:
        os.mkdir(stage_path, 0o755)
        os.chmod(stage_path, 0o755, follow_symlinks=False)
    except OSError as exc:
        raise PolicyError(f"cannot create fresh stage root {stage_path}: {exc}") from exc
    try:
        root_descriptor = os.open(
            stage_path, os.O_RDONLY | DIRECTORY | NOFOLLOW
        )
    except OSError as exc:
        raise PolicyError(f"cannot open fresh stage root {stage_path}: {exc}") from exc
    try:
        for relative in _byte_sort(payloads):
            _write_relative(root_descriptor, relative, payloads[relative])
    finally:
        os.close(root_descriptor)

    verify_stage(stage_path, before, policy)
    after = capture_inputs(repo, policy)
    if before.identity() != after.identity():
        raise PolicyError("Focus resource subject changed while staging")
    audit = build_audit(policy_bytes, policy, after)
    _write_audit_exclusive(audit_path, canonical_json(audit))
    return audit


def verify(
    repo_value: str, policy_value: str, stage_value: str, audit_value: str
) -> dict[str, Any]:
    repo = _resolve_repository(repo_value)
    policy_path = _absolute_existing(policy_value, "policy")
    stage_path = _absolute_existing(stage_value, "stage")
    audit_path = _absolute_existing(audit_value, "audit")
    _check_output_relationships(repo, stage_path, audit_path)
    policy_bytes, policy = load_policy(policy_path)
    before = capture_inputs(repo, policy)
    verify_stage(stage_path, before, policy)
    expected_audit = build_audit(policy_bytes, policy, before)
    actual_audit_bytes = _read_regular_file(audit_path, "audit")
    if actual_audit_bytes != canonical_json(expected_audit):
        raise PolicyError("audit is stale, malformed, or does not attest this stage")
    after = capture_inputs(repo, policy)
    if before.identity() != after.identity():
        raise PolicyError("Focus resource subject changed while verifying")
    verify_stage(stage_path, after, policy)
    return expected_audit


def _usage() -> str:
    return (
        "usage: package_resources.py stage REPO POLICY NEW_STAGE NEW_AUDIT\n"
        "       package_resources.py verify REPO POLICY STAGE AUDIT"
    )


def main(argv: list[str]) -> int:
    if len(argv) != 6 or argv[1] not in ("stage", "verify"):
        print(_usage(), file=sys.stderr)
        return 2
    command, repo, policy, stage_path, audit = argv[1:]
    try:
        if command == "stage":
            result = stage(repo, policy, stage_path, audit)
            verb = "STAGED"
        else:
            result = verify(repo, policy, stage_path, audit)
            verb = "VERIFIED"
    except (PolicyError, OSError, UnicodeError, ValueError) as exc:
        print(f"REFUSED: {exc}", file=sys.stderr)
        return 1
    print(
        f"{verb}: {result['resource_file_count']} resource files, "
        f"{result['resource_byte_count']} bytes"
    )
    print(f"  source digest: {result['source_digest']}")
    print(f"  staged digest: {result['staged_resource_digest']}")
    print(
        "  module proof: "
        f"{len(result['module_proof']['sources'])} DesignSystem sources + "
        f"{result['module_proof']['accessor']['stage_path']}"
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main(sys.argv))
