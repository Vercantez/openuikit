#!/usr/bin/env python3
"""Fail-closed module-emission proof for Focus's AppShortcuts package slice.

This is intentionally a pinned proof, not a SwiftPM or Xcode replacement.  It
accepts one Focus commit, one OpenUIKit commit, exact source inventories, and
the already-reviewed package-resource stage. Every application module is
emitted separately with the same fixed cross-target contract.
"""

from __future__ import annotations

from dataclasses import dataclass
import hashlib
import json
import os
from pathlib import Path, PurePosixPath
import re
import shutil
import stat
import subprocess
import sys
from typing import Any, Iterable

import package_resources as resource_tool


HERE = Path(__file__).resolve().parent
FOCUS_COMMIT = "a2832521c1daa0c23419c73705ae043ed60c9791"
OPENUIKIT_COMMIT = "0bba80a4138ece678844e2f55da16ffb7cbf70e9"
TARGET = "arm64-apple-macos13.0"
SWIFT_LANGUAGE_VERSION = "5"
MODULE_NAMES = ("UIHelpers", "UIComponents", "DesignSystem", "AppShortcuts")
MODULE_SUFFIXES = (".abi.json", ".swiftdoc", ".swiftmodule", ".swiftsourceinfo")

APPROVED_MANIFEST = {
    "path": "BlockzillaPackage/Package.swift",
    "size": 1975,
    "sha256": "2d29b769de137389f5613de6755211b255533375bf6003a2192f514e96899248",
}

APPROVED_TARGETS = [
    {
        "name": "UIHelpers",
        "source_root": "BlockzillaPackage/Sources/UIHelpers",
        "source_digest": "5d240421951ca5d1523027e097e50c86d8ebc3ac96ce14a31461071df6660b9c",
        "sources": [
            {"path": "BlockzillaPackage/Sources/UIHelpers/FaviIconGenerator.swift", "size": 1421, "sha256": "061714d90475de0320a2498b22c75d2a430625c7f49636902f0c8304d151fc93"},
            {"path": "BlockzillaPackage/Sources/UIHelpers/ImageLoader.swift", "size": 2489, "sha256": "ef3ceee801c0fb7e63d0a78185f5956c56c4fde976f9ef909eac5065132e0bcb"},
            {"path": "BlockzillaPackage/Sources/UIHelpers/UIApplication+Orientation.swift", "size": 648, "sha256": "c47e83212c074d34bd0f793065faba5e0691a7612eec6f8cbd59691a7907a309"},
            {"path": "BlockzillaPackage/Sources/UIHelpers/UIButton+Background.swift", "size": 1388, "sha256": "2f5dcc1c57b951a86d54d4f41dcbc415a9d08c92bba9c7c6295fe4040f582382"},
            {"path": "BlockzillaPackage/Sources/UIHelpers/UIDeviceExtensions.swift", "size": 999, "sha256": "2167de4be7bfd70659bd2c786a7a9a463d266316660d04eb83cdd668f9cfde40"},
            {"path": "BlockzillaPackage/Sources/UIHelpers/UIImageExtensions.swift", "size": 731, "sha256": "13e31d863f387bc493d5ef2761ca46c7edc62c744e11ff396e85b2bfe0512319"},
            {"path": "BlockzillaPackage/Sources/UIHelpers/UILabelExtensions.swift", "size": 383, "sha256": "ca9be28a9998bbf4c93ad1fb33df0e1a6dfea4e0a475ce617ad481fd862102bf"},
            {"path": "BlockzillaPackage/Sources/UIHelpers/UIScreenExtensions.swift", "size": 350, "sha256": "959f976a3b34bba81d59cee67f97a188d2114ab175c11eccd2397db42907b443"},
            {"path": "BlockzillaPackage/Sources/UIHelpers/UITableView+Dequeue.swift", "size": 817, "sha256": "dceb0ac806f6faf634aed350d69edaf304414b374404f2af46bc2fbd7a108de7"},
            {"path": "BlockzillaPackage/Sources/UIHelpers/UIViewController+Child.swift", "size": 991, "sha256": "06dd18d432add4ca3a8c70bbfb455d007bef75df6388e3a5dbdb7b541f3760f0"},
            {"path": "BlockzillaPackage/Sources/UIHelpers/UIViewExtensions.swift", "size": 1616, "sha256": "72c10b8c6849ad412bacd5f7b6ddb3cb8662d49f8af2998abd0ffdc946fa5f37"},
        ],
    },
    {
        "name": "UIComponents",
        "source_root": "BlockzillaPackage/Sources/UIComponents",
        "source_digest": "973462bfb1cd91327344759fbe3c5972ae0b42d16463aa6c126795863b5953c8",
        "sources": [
            {"path": "BlockzillaPackage/Sources/UIComponents/AsyncImageView.swift", "size": 2278, "sha256": "5fbda4ebce61254c8b0099f3f50892947beab6654af168885b6cac00240abdaa"},
        ],
    },
    {
        "name": "DesignSystem",
        "source_root": "BlockzillaPackage/Sources/DesignSystem",
        "source_digest": "00d6773590819770061d4dc9e23adedc1f5ed39962a321475093289edf28ca9b",
        "sources": [
            {"path": "BlockzillaPackage/Sources/DesignSystem/Bundle+CurrentBundle.swift", "size": 2060, "sha256": "725315f04ecbbe4bdeceb73bdf07550e2c3f38307696d0fa7035600e018ca3af"},
            {"path": "BlockzillaPackage/Sources/DesignSystem/UIColor+AppColors.swift", "size": 3248, "sha256": "4078f76f180d37f6d560dd63d59ef161302a73b7f416933533663700c314224f"},
            {"path": "BlockzillaPackage/Sources/DesignSystem/UIFont+AppFonts.swift", "size": 1412, "sha256": "ac4895febb0ad6c588ada61420b0b271afb33092d76e1dbed828ee8b337c83e6"},
            {"path": "BlockzillaPackage/Sources/DesignSystem/UIImage+AppImages.swift", "size": 2152, "sha256": "ba5720a57aa90406b95a66ea62433557b666c1558d59781018de050585797734"},
        ],
        "production_exclusions": {
            "rationale": "SwiftUI-only Preview Files are not inputs to the reviewed four-source production subset.",
            "source_digest": "f51db65db76ad183db8cd1d9df5322a4fd1b0be5990c1620373c21fba2cc734c",
            "sources": [
                {"path": "BlockzillaPackage/Sources/DesignSystem/Preview Files/AppColorsView.swift", "size": 4148, "sha256": "0bcfbf1b672fdd82d305a8fd0fbbc319e59285b43b7aa7d4566cf445e5ecd2f1"},
                {"path": "BlockzillaPackage/Sources/DesignSystem/Preview Files/AppFontsView.swift", "size": 2114, "sha256": "99da3374150876e5212adc7f9baca7f1cd4c62afea40919a64ac31a700e7e00a"},
                {"path": "BlockzillaPackage/Sources/DesignSystem/Preview Files/AppImagesView.swift", "size": 1752, "sha256": "59f55ca617ce706cb7abe85b3d44f192261fb8690ba05b8eab4fde02f1664508"},
            ],
        },
    },
    {
        "name": "AppShortcuts",
        "source_root": "BlockzillaPackage/Sources/AppShortcuts",
        "source_digest": "8af6563e8cf24f8fc0cf36e232393321aed36deff8178edd7dbe57c7a27b885e",
        "sources": [
            {"path": "BlockzillaPackage/Sources/AppShortcuts/Shortcut.swift", "size": 1691, "sha256": "b7f1501bd41bad472012008bc35a20883de651b6d787070c6b7ce4ed2174120a"},
            {"path": "BlockzillaPackage/Sources/AppShortcuts/ShortcutView.swift", "size": 5956, "sha256": "a5cfad552e9552bb5afdec662ec05583e1deee5826bfbd6beb4a629867ede8f1"},
            {"path": "BlockzillaPackage/Sources/AppShortcuts/ShortcutViewModel.swift", "size": 1189, "sha256": "2d34847cb586ecb53508d52883cc494e90912c21f76c98c4ee17e4f67f4e7b41"},
            {"path": "BlockzillaPackage/Sources/AppShortcuts/ShortcutsManager.swift", "size": 4078, "sha256": "67a979250e07a5d97abf7ebb8a4f59d1810c564c8ce5641071e1e880b3c4cce3"},
            {"path": "BlockzillaPackage/Sources/AppShortcuts/ShortcutsPersister.swift", "size": 1017, "sha256": "82edccb54c639e035d82f186c26dc1e6d20d84a9a00cd9bee85bab894307f44e"},
        ],
    },
]

APPROVED_RESOURCE_INTEGRATION = {
    "policy_path": "package-resources.json",
    "policy_size": 3626,
    "policy_sha256": "386de0addac9cc47fd9a4a54d665b62186d179c0a2516d45b30636f649c40acc",
    "tool_path": "package_resources.py",
    "tool_size": 41722,
    "tool_sha256": "3ac3e47a861fdcc7dcf8cf1f34c940ab908b295b34e282aa8dc6d4decf919cce",
    "accessor_path": "accessors/DesignSystem/Bundle+Module.swift",
    "accessor_size": 146,
    "accessor_sha256": "c0a3ee61e4fc8015d5e4a36775293347e21c58850605a6d47141f344211829aa",
    "historical_openuikit_commit": "81e1e05fbde712a28ea031534462b80740ed5eb5",
}

SHA256_RE = re.compile(r"[0-9a-f]{64}\Z")
COMMIT_RE = re.compile(r"[0-9a-f]{40}\Z")
NOFOLLOW = getattr(os, "O_NOFOLLOW", 0)


class ProofError(RuntimeError):
    """The requested proof no longer describes the reviewed subject."""


@dataclass(frozen=True)
class SourceFile:
    path: str
    data: bytes

    def record(self) -> dict[str, Any]:
        return {"path": self.path, "size": len(self.data), "sha256": sha256(self.data)}


@dataclass(frozen=True)
class RepositoryCapture:
    commit: str
    status_sha256: str
    manifest: SourceFile | None
    targets: tuple[tuple[str, tuple[SourceFile, ...]], ...]
    exclusions: tuple[SourceFile, ...] = ()

    def identity(self) -> bytes:
        return canonical_json(
            {
                "commit": self.commit,
                "status_sha256": self.status_sha256,
                "manifest": self.manifest.record() if self.manifest else None,
                "targets": [
                    {"name": name, "sources": [source.record() for source in sources]}
                    for name, sources in self.targets
                ],
                "production_exclusions": [source.record() for source in self.exclusions],
            }
        )


def sha256(data: bytes) -> str:
    return hashlib.sha256(data).hexdigest()


def canonical_json(value: Any) -> bytes:
    return (json.dumps(value, indent=2, sort_keys=True) + "\n").encode("utf-8")


def records_digest(records: Iterable[tuple[str, bytes]]) -> str:
    aggregate = hashlib.sha256()
    for path, data in sorted(records, key=lambda item: item[0].encode("utf-8")):
        aggregate.update(path.encode("utf-8"))
        aggregate.update(b"\0")
        aggregate.update(str(len(data)).encode("ascii"))
        aggregate.update(b"\0")
        aggregate.update(sha256(data).encode("ascii"))
        aggregate.update(b"\n")
    return aggregate.hexdigest()


def controlled_environment() -> dict[str, str]:
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
    command = [
        "git", "-c", "core.fsmonitor=false", "-c", f"core.hooksPath={os.devnull}",
        "-C", str(repo), *args,
    ]
    try:
        return subprocess.check_output(
            command, stderr=subprocess.STDOUT, env=controlled_environment()
        )
    except (OSError, subprocess.CalledProcessError) as exc:
        output = getattr(exc, "output", b"")
        detail = output.decode("utf-8", errors="replace").strip() if isinstance(output, bytes) else str(output)
        raise ProofError(f"git {' '.join(args)} failed: {detail}") from exc


def expected_policy() -> dict[str, Any]:
    return {
        "schema": 1,
        "focus": {
            "commit": FOCUS_COMMIT,
            "worktree_prefix": "focus-ios",
            "package_manifest": dict(APPROVED_MANIFEST),
        },
        "openuikit": {"commit": OPENUIKIT_COMMIT, "worktree_prefix": "."},
        "targets": json.loads(json.dumps(APPROVED_TARGETS)),
        "resource_integration": dict(APPROVED_RESOURCE_INTEGRATION),
        "build": {
            "target": TARGET,
            "swift_language_version": SWIFT_LANGUAGE_VERSION,
            "whole_module_optimization": True,
            "parse_as_library": True,
            "module_order": list(MODULE_NAMES),
        },
    }


def _validate_relative(value: Any, label: str) -> str:
    if not isinstance(value, str) or not value:
        raise ProofError(f"{label} must be a non-empty string")
    if "\\" in value or any(character in value for character in ("\0", "\n", "\r")):
        raise ProofError(f"{label} contains a forbidden character")
    path = PurePosixPath(value)
    if path.is_absolute() or path.as_posix() != value or any(part in ("", ".", "..") for part in path.parts):
        raise ProofError(f"{label} is not a normalized relative POSIX path: {value!r}")
    return value


def _validate_policy_shape(policy: Any) -> None:
    top_keys = {"schema", "focus", "openuikit", "targets", "resource_integration", "build"}
    if not isinstance(policy, dict) or set(policy) != top_keys:
        raise ProofError("policy has unexpected top-level keys")
    if type(policy["schema"]) is not int or policy["schema"] != 1:
        raise ProofError("policy schema must be integer 1")

    def require_mapping(value: Any, keys: set[str], label: str) -> dict[str, Any]:
        if not isinstance(value, dict) or set(value) != keys:
            raise ProofError(f"{label} keys changed")
        return value

    def require_size(value: Any, label: str) -> None:
        if type(value) is not int or value < 0:
            raise ProofError(f"{label} must be a non-negative integer")

    def require_hash(value: Any, label: str) -> None:
        if not isinstance(value, str) or not SHA256_RE.fullmatch(value):
            raise ProofError(f"{label} must be a lowercase SHA-256")

    def validate_sources(value: Any, label: str, seen: set[str]) -> None:
        if not isinstance(value, list) or not value:
            raise ProofError(f"{label} must be a non-empty list")
        for index, raw_source in enumerate(value):
            source = require_mapping(raw_source, {"path", "size", "sha256"}, f"{label}[{index}]")
            path = _validate_relative(source["path"], f"{label}[{index}].path")
            if path in seen:
                raise ProofError(f"{label}[{index}].path is duplicated")
            seen.add(path)
            require_size(source["size"], f"{label}[{index}].size")
            require_hash(source["sha256"], f"{label}[{index}].sha256")

    for owner in ("focus", "openuikit"):
        raw = policy[owner]
        required = {"commit", "worktree_prefix"} | ({"package_manifest"} if owner == "focus" else set())
        raw = require_mapping(raw, required, owner)
        if not isinstance(raw["commit"], str) or not COMMIT_RE.fullmatch(raw["commit"]):
            raise ProofError(f"{owner}.commit must be a lowercase Git object ID")
        if not isinstance(raw["worktree_prefix"], str) or not raw["worktree_prefix"]:
            raise ProofError(f"{owner}.worktree_prefix must be a non-empty string")
    manifest = require_mapping(policy["focus"]["package_manifest"], {"path", "size", "sha256"}, "focus.package_manifest")
    _validate_relative(manifest["path"], "focus.package_manifest.path")
    require_size(manifest["size"], "focus.package_manifest.size")
    require_hash(manifest["sha256"], "focus.package_manifest.sha256")

    names: list[str] = []
    paths: set[str] = set()
    if not isinstance(policy["targets"], list) or not policy["targets"]:
        raise ProofError("targets must be a non-empty list")
    for index, raw_target in enumerate(policy["targets"]):
        base_keys = {"name", "source_root", "source_digest", "sources"}
        if not isinstance(raw_target, dict) or set(raw_target) not in (base_keys, base_keys | {"production_exclusions"}):
            raise ProofError(f"targets[{index}] keys changed")
        target = raw_target
        if not isinstance(target["name"], str) or not target["name"]:
            raise ProofError(f"targets[{index}].name must be a non-empty string")
        names.append(target["name"])
        _validate_relative(target["source_root"], f"targets[{index}].source_root")
        require_hash(target["source_digest"], f"targets[{index}].source_digest")
        validate_sources(target["sources"], f"targets[{index}].sources", paths)
        if "production_exclusions" in target:
            if target["name"] != "DesignSystem":
                raise ProofError("only DesignSystem may carry production exclusions")
            exclusion = require_mapping(target["production_exclusions"], {"rationale", "source_digest", "sources"}, f"targets[{index}].production_exclusions")
            if not isinstance(exclusion["rationale"], str) or not exclusion["rationale"]:
                raise ProofError("production-exclusion rationale must be non-empty")
            require_hash(exclusion["source_digest"], "production-exclusion digest")
            validate_sources(exclusion["sources"], f"targets[{index}].production_exclusions.sources", paths)
    if names != list(MODULE_NAMES):
        raise ProofError("target order or names changed")

    resource_keys = {"policy_path", "policy_size", "policy_sha256", "tool_path", "tool_size", "tool_sha256", "accessor_path", "accessor_size", "accessor_sha256", "historical_openuikit_commit"}
    integration = require_mapping(policy["resource_integration"], resource_keys, "resource_integration")
    for key in ("policy_path", "tool_path", "accessor_path"):
        _validate_relative(integration[key], f"resource_integration.{key}")
    for key in ("policy_size", "tool_size", "accessor_size"):
        require_size(integration[key], f"resource_integration.{key}")
    for key in ("policy_sha256", "tool_sha256", "accessor_sha256"):
        require_hash(integration[key], f"resource_integration.{key}")
    if not isinstance(integration["historical_openuikit_commit"], str) or not COMMIT_RE.fullmatch(integration["historical_openuikit_commit"]):
        raise ProofError("resource historical OpenUIKit commit is malformed")

    build = require_mapping(policy["build"], {"target", "swift_language_version", "whole_module_optimization", "parse_as_library", "module_order"}, "build")
    if not isinstance(build["target"], str) or not build["target"] or not isinstance(build["swift_language_version"], str) or not build["swift_language_version"]:
        raise ProofError("build target/language version must be strings")
    if type(build["whole_module_optimization"]) is not bool or type(build["parse_as_library"]) is not bool:
        raise ProofError("build optimization/library flags must be booleans")
    if not isinstance(build["module_order"], list) or not all(isinstance(item, str) for item in build["module_order"]):
        raise ProofError("build.module_order must be a string list")


def _read_regular(path: Path, label: str) -> bytes:
    try:
        link_metadata = path.lstat()
    except OSError as exc:
        raise ProofError(f"cannot stat {label} {path}: {exc}") from exc
    if stat.S_ISLNK(link_metadata.st_mode):
        raise ProofError(f"{label} must not be a symlink: {path}")
    try:
        descriptor = os.open(path, os.O_RDONLY | NOFOLLOW)
    except OSError as exc:
        raise ProofError(f"cannot open {label} {path}: {exc}") from exc
    try:
        before = os.fstat(descriptor)
        if not stat.S_ISREG(before.st_mode):
            raise ProofError(f"{label} is not a regular file: {path}")
        chunks: list[bytes] = []
        while True:
            chunk = os.read(descriptor, 1024 * 1024)
            if not chunk:
                break
            chunks.append(chunk)
        after = os.fstat(descriptor)
        if (before.st_dev, before.st_ino, before.st_size, before.st_mtime_ns, before.st_ctime_ns) != (after.st_dev, after.st_ino, after.st_size, after.st_mtime_ns, after.st_ctime_ns):
            raise ProofError(f"{label} changed while being read: {path}")
        data = b"".join(chunks)
        if len(data) != after.st_size:
            raise ProofError(f"{label} size changed while being read: {path}")
        return data
    finally:
        os.close(descriptor)


def load_policy(path: Path) -> tuple[bytes, dict[str, Any]]:
    data = _read_regular(path, "AppShortcuts policy")
    try:
        policy = json.loads(data)
    except json.JSONDecodeError as exc:
        raise ProofError(f"cannot parse AppShortcuts policy: {exc}") from exc
    _validate_policy_shape(policy)
    if policy != expected_policy():
        raise ProofError("policy does not match the reviewed Focus AppShortcuts subject")
    return data, policy


def _resolve_repository(value: str, label: str) -> Path:
    requested = Path(value)
    if requested.is_symlink():
        raise ProofError(f"{label} repository must not be a symlink: {requested}")
    try:
        resolved = requested.resolve(strict=True)
    except OSError as exc:
        raise ProofError(f"cannot resolve {label} repository: {exc}") from exc
    if not resolved.is_dir():
        raise ProofError(f"{label} repository is not a directory: {resolved}")
    return resolved


def _repository_root_and_prefix(repo: Path, expected_prefix: str, label: str) -> tuple[Path, str]:
    repo = repo.resolve(strict=True)
    raw_root = git(repo, "rev-parse", "--show-toplevel").decode("utf-8", errors="strict").strip()
    root = Path(raw_root).resolve(strict=True)
    try:
        relative = repo.relative_to(root).as_posix()
    except ValueError as exc:
        raise ProofError(f"{label} path is outside its Git worktree") from exc
    actual_prefix = "." if relative == "." else relative
    if actual_prefix != expected_prefix:
        raise ProofError(f"{label} worktree prefix changed: expected {expected_prefix!r}, got {actual_prefix!r}")
    return root, actual_prefix


def _git_path(prefix: str, relative: str) -> str:
    return relative if prefix == "." else f"{prefix}/{relative}"


def _reject_symlink_components(repo: Path, relative: str) -> None:
    current = repo
    for part in PurePosixPath(_validate_relative(relative, "source path")).parts:
        current = current / part
        try:
            metadata = current.lstat()
        except OSError as exc:
            raise ProofError(f"cannot stat source path component {current}: {exc}") from exc
        if stat.S_ISLNK(metadata.st_mode):
            raise ProofError(f"source path must not contain symlinks: {current}")


def _attest_committed_file(root: Path, repo: Path, prefix: str, expected: dict[str, Any], label: str) -> SourceFile:
    relative = expected["path"]
    full = _git_path(prefix, relative)
    raw = git(root, "ls-tree", "-z", "HEAD", "--", full)
    records = [record for record in raw.split(b"\0") if record]
    if len(records) != 1 or b"\t" not in records[0]:
        raise ProofError(f"{label} is not exactly one committed blob: {relative}")
    metadata, raw_path = records[0].split(b"\t", 1)
    fields = metadata.split(b" ")
    if len(fields) != 3 or fields[0] != b"100644" or fields[1] != b"blob" or raw_path.decode("utf-8", errors="strict") != full:
        raise ProofError(f"{label} Git mode/type/path changed: {relative}")
    _reject_symlink_components(repo, relative)
    data = _read_regular(repo / relative, label)
    committed = git(root, "cat-file", "blob", fields[2].decode("ascii", errors="strict"))
    if data != committed:
        raise ProofError(f"{label} worktree bytes differ from HEAD: {relative}")
    item = SourceFile(relative, data)
    if item.record() != expected:
        raise ProofError(f"{label} bytes changed: {relative}")
    return item


def _tracked_swift_inventory(root: Path, prefix: str, source_root: str) -> list[str]:
    full_root = _git_path(prefix, source_root)
    raw = git(root, "ls-tree", "-r", "--name-only", "-z", "HEAD", "--", full_root)
    if raw and not raw.endswith(b"\0"):
        raise ProofError("Git source inventory is not NUL terminated")
    prefix_text = "" if prefix == "." else f"{prefix}/"
    inventory: list[str] = []
    for raw_path in raw.split(b"\0"):
        if not raw_path:
            continue
        path = raw_path.decode("utf-8", errors="strict")
        if not path.startswith(prefix_text):
            raise ProofError("Git source inventory escaped its repository prefix")
        relative = path[len(prefix_text):]
        if relative.endswith(".swift"):
            inventory.append(relative)
    return sorted(inventory, key=lambda value: value.encode("utf-8"))


def capture_focus(repo: Path, policy: dict[str, Any]) -> RepositoryCapture:
    focus_policy = policy["focus"]
    root, prefix = _repository_root_and_prefix(repo, focus_policy["worktree_prefix"], "Focus")
    commit = git(root, "rev-parse", "--verify", "HEAD^{commit}").decode("ascii", errors="strict").strip()
    if commit != focus_policy["commit"]:
        raise ProofError(f"Focus commit changed: expected {focus_policy['commit']}, got {commit}")
    status = git(root, "status", "--porcelain=v1", "-z", "--untracked-files=all")
    if status:
        raise ProofError("Focus worktree is dirty or contains untracked files")
    manifest = _attest_committed_file(root, repo, prefix, focus_policy["package_manifest"], "Package.swift")
    captured_targets: list[tuple[str, tuple[SourceFile, ...]]] = []
    captured_exclusions: list[SourceFile] = []
    for target in policy["targets"]:
        expected_paths = [item["path"] for item in target["sources"]]
        exclusion = target.get("production_exclusions")
        excluded_paths = [item["path"] for item in exclusion["sources"]] if exclusion else []
        if _tracked_swift_inventory(root, prefix, target["source_root"]) != sorted(expected_paths + excluded_paths, key=lambda value: value.encode("utf-8")):
            raise ProofError(f"{target['name']} committed Swift inventory changed")
        sources = tuple(
            _attest_committed_file(root, repo, prefix, expected, f"{target['name']} source")
            for expected in target["sources"]
        )
        if records_digest((source.path, source.data) for source in sources) != target["source_digest"]:
            raise ProofError(f"{target['name']} aggregate source digest changed")
        captured_targets.append((target["name"], sources))
        if exclusion:
            excluded = [
                _attest_committed_file(root, repo, prefix, expected, f"{target['name']} production exclusion")
                for expected in exclusion["sources"]
            ]
            if records_digest((source.path, source.data) for source in excluded) != exclusion["source_digest"]:
                raise ProofError(f"{target['name']} production-exclusion digest changed")
            captured_exclusions.extend(excluded)
    return RepositoryCapture(commit, sha256(status), manifest, tuple(captured_targets), tuple(captured_exclusions))


def capture_openuikit(repo: Path, policy: dict[str, Any]) -> RepositoryCapture:
    ui_policy = policy["openuikit"]
    root, _ = _repository_root_and_prefix(repo, ui_policy["worktree_prefix"], "OpenUIKit")
    commit = git(root, "rev-parse", "--verify", "HEAD^{commit}").decode("ascii", errors="strict").strip()
    if commit != ui_policy["commit"]:
        raise ProofError(f"OpenUIKit commit changed: expected {ui_policy['commit']}, got {commit}")
    status = git(root, "status", "--porcelain=v1", "-z", "--untracked-files=all")
    if status:
        raise ProofError("OpenUIKit worktree is dirty or contains untracked files")
    return RepositoryCapture(commit, sha256(status), None, ())


def _attest_local_dependency(policy: dict[str, Any]) -> tuple[Path, Path]:
    integration = policy["resource_integration"]
    resource_policy = HERE / integration["policy_path"]
    resource_script = HERE / integration["tool_path"]
    for path, size_key, hash_key, label in (
        (resource_policy, "policy_size", "policy_sha256", "resource policy"),
        (resource_script, "tool_size", "tool_sha256", "resource tool"),
    ):
        data = _read_regular(path, label)
        if len(data) != integration[size_key] or sha256(data) != integration[hash_key]:
            raise ProofError(f"pinned {label} changed")
    return resource_policy, resource_script


def _resolve_new_output(value: str, focus: Path, openuikit: Path) -> Path:
    raw = Path(value)
    if raw.name in ("", ".", ".."):
        raise ProofError("proof output must name a fresh path")
    try:
        parent = raw.parent.resolve(strict=True)
    except OSError as exc:
        raise ProofError(f"cannot resolve proof output parent: {exc}") from exc
    output = parent / raw.name
    if os.path.lexists(os.fspath(output)):
        raise ProofError(f"stale proof output already exists: {output}")
    for repo in (focus, openuikit):
        try:
            output.relative_to(repo)
        except ValueError:
            pass
        else:
            raise ProofError("proof output must be outside source repositories")
    return output


def _write_exclusive(path: Path, data: bytes, label: str) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    try:
        descriptor = os.open(path, os.O_WRONLY | os.O_CREAT | os.O_EXCL | NOFOLLOW, 0o644)
    except OSError as exc:
        raise ProofError(f"cannot create {label} {path}: {exc}") from exc
    try:
        offset = 0
        while offset < len(data):
            written = os.write(descriptor, data[offset:])
            if written <= 0:
                raise ProofError(f"short write while creating {label}")
            offset += written
        os.fchmod(descriptor, 0o644)
        os.fsync(descriptor)
    finally:
        os.close(descriptor)


def verify_no_source_adaptations(output: Path) -> None:
    """The strengthened proof must never recreate the retired source overlay."""
    generated = output / "generated"
    if os.path.lexists(os.fspath(generated)):
        raise ProofError("source adaptation output exists in an adaptation-free proof")


def _run(command: list[str], log: Path, label: str, cwd: Path | None = None) -> None:
    try:
        with log.open("xb") as output:
            result = subprocess.run(
                command, cwd=cwd, stdout=output, stderr=subprocess.STDOUT,
                env=controlled_environment(), check=False,
            )
    except OSError as exc:
        raise ProofError(f"cannot run {label}: {exc}") from exc
    if result.returncode != 0:
        raise ProofError(f"{label} failed with exit {result.returncode}; see {log}")


def _build_openuikit(source: Path, output: Path, commit: str) -> tuple[Path, dict[str, Any]]:
    clone = output / "work" / "openuikit"
    scratch = output / "work" / "openuikit-build"
    clone.parent.mkdir(parents=True)
    _run(["git", "clone", "--quiet", "--no-checkout", "--no-hardlinks", str(source), str(clone)], output / "openuikit-clone.log", "OpenUIKit clone")
    _run(["git", "-c", "core.fsmonitor=false", "-c", f"core.hooksPath={os.devnull}", "-C", str(clone), "checkout", "--quiet", "--detach", commit], output / "openuikit-checkout.log", "OpenUIKit checkout")
    if git(clone, "rev-parse", "--verify", "HEAD^{commit}").decode("ascii").strip() != commit or git(clone, "status", "--porcelain=v1", "-z", "--untracked-files=all"):
        raise ProofError("fresh OpenUIKit clone does not exactly match its pin")
    build_log = output / "openuikit-build.log"
    _run(["swift", "build", "--package-path", str(clone), "--scratch-path", str(scratch), "--configuration", "release", "--product", "OpenUIKit", "--triple", "arm64-apple-macosx"], build_log, "fresh OpenUIKit build")
    candidates = sorted(scratch.rglob("Modules/UIKit.swiftmodule"))
    if len(candidates) != 1 or not candidates[0].is_file():
        raise ProofError("fresh OpenUIKit build did not emit exactly one UIKit.swiftmodule")
    modules = candidates[0].parent
    if git(clone, "rev-parse", "--verify", "HEAD^{commit}").decode("ascii").strip() != commit or git(clone, "status", "--porcelain=v1", "-z", "--untracked-files=all"):
        raise ProofError("OpenUIKit clone changed during its build")
    module_data = _read_regular(candidates[0], "fresh UIKit module")
    return modules, {
        "commit": commit,
        "uikit_module": {"size": len(module_data), "sha256": sha256(module_data)},
        "build_log": {"size": build_log.stat().st_size, "sha256": sha256(_read_regular(build_log, "OpenUIKit build log"))},
    }


def _module_sources(captured: RepositoryCapture) -> dict[str, list[Path]]:
    # Repository source paths are reconstructed by the caller from the capture.
    return {name: [Path(source.path) for source in sources] for name, sources in captured.targets}


def _compile_modules(focus: Path, ui_modules: Path, output: Path, captured: RepositoryCapture, accessor: Path) -> tuple[list[dict[str, Any]], list[dict[str, Any]]]:
    modules = output / "modules"
    diagnostics = output / "diagnostics"
    modules.mkdir()
    diagnostics.mkdir()
    include_args = [
        "-I", str(ui_modules),
        "-I", str(ui_modules.parent),
        "-I", str(modules),
    ]
    clone = output / "work" / "openuikit"
    for modulemap in sorted(clone.rglob("module.modulemap"), key=lambda path: os.fsencode(path)):
        include_args.extend(["-Xcc", "-I", "-Xcc", str(modulemap.parent)])
    source_map = _module_sources(captured)
    source_map["DesignSystem"].append(accessor)
    module_records: list[dict[str, Any]] = []
    diagnostic_records: list[dict[str, Any]] = []
    swiftc = shutil.which("swiftc")
    if swiftc is None:
        raise ProofError("swiftc is unavailable")
    for name in MODULE_NAMES:
        log = diagnostics / f"{name}.log"
        sources = [path if path.is_absolute() else focus / path for path in source_map[name]]
        command = [
            swiftc, "-emit-module", "-emit-module-path", str(modules / f"{name}.swiftmodule"),
            "-parse-as-library", "-wmo", "-swift-version", SWIFT_LANGUAGE_VERSION,
            "-target", TARGET, "-module-name", name, *include_args,
            *(str(path) for path in sources),
        ]
        _run(command, log, f"{name} module emission")
        log_data = _read_regular(log, f"{name} diagnostics")
        if log_data:
            raise ProofError(f"{name} emitted unexpected diagnostics; see {log}")
        diagnostic_records.append({"path": log.relative_to(output).as_posix(), "size": 0, "sha256": sha256(b"")})
        for suffix in MODULE_SUFFIXES:
            path = modules / f"{name}{suffix}"
            data = _read_regular(path, f"{name} module output")
            if not data:
                raise ProofError(f"{name}{suffix} is empty")
            module_records.append({"path": path.relative_to(output).as_posix(), "size": len(data), "sha256": sha256(data)})
    actual_files = sorted(path.relative_to(modules).as_posix() for path in modules.iterdir() if path.is_file())
    expected_files = sorted(f"{name}{suffix}" for name in MODULE_NAMES for suffix in MODULE_SUFFIXES)
    if actual_files != expected_files:
        raise ProofError("module output inventory is stale, missing, or untracked")
    return module_records, diagnostic_records


def _source_audit(captured: RepositoryCapture, policy: dict[str, Any]) -> list[dict[str, Any]]:
    policy_by_name = {target["name"]: target for target in policy["targets"]}
    return [
        {
            "name": name,
            "source_count": len(sources),
            "source_digest": policy_by_name[name]["source_digest"],
            "sources": [source.record() for source in sources],
        }
        for name, sources in captured.targets
    ]


def _exclusion_audit(captured: RepositoryCapture, policy: dict[str, Any]) -> dict[str, Any]:
    exclusion = next(
        target["production_exclusions"]
        for target in policy["targets"]
        if "production_exclusions" in target
    )
    return {
        "target": "DesignSystem",
        "rationale": exclusion["rationale"],
        "source_count": len(captured.exclusions),
        "source_digest": exclusion["source_digest"],
        "sources": [source.record() for source in captured.exclusions],
    }


def prove(focus_value: str, openuikit_value: str, policy_value: str, output_value: str) -> dict[str, Any]:
    focus = _resolve_repository(focus_value, "Focus")
    openuikit = _resolve_repository(openuikit_value, "OpenUIKit")
    policy_path = Path(policy_value).resolve(strict=True)
    policy_bytes, policy = load_policy(policy_path)
    resource_policy, _ = _attest_local_dependency(policy)
    before_focus = capture_focus(focus, policy)
    before_ui = capture_openuikit(openuikit, policy)
    output = _resolve_new_output(output_value, focus, openuikit)
    output.mkdir(mode=0o755)

    resource_stage = output / "package-resources"
    resource_audit_path = output / "package-resources-audit.json"
    try:
        resource_audit = resource_tool.stage(str(focus), str(resource_policy), str(resource_stage), str(resource_audit_path))
    except resource_tool.PolicyError as exc:
        raise ProofError(f"package-resource stage refused: {exc}") from exc
    integration = policy["resource_integration"]
    resource_module = resource_audit.get("module_proof", {})
    if resource_module.get("openuikit_commit") != integration["historical_openuikit_commit"]:
        raise ProofError("package-resource historical OpenUIKit proof pin changed")
    accessor = resource_stage / integration["accessor_path"]
    accessor_data = _read_regular(accessor, "DesignSystem Bundle.module accessor")
    if len(accessor_data) != integration["accessor_size"] or sha256(accessor_data) != integration["accessor_sha256"]:
        raise ProofError("staged DesignSystem Bundle.module accessor changed")

    verify_no_source_adaptations(output)
    ui_modules, ui_build = _build_openuikit(openuikit, output, policy["openuikit"]["commit"])
    module_outputs, diagnostics = _compile_modules(focus, ui_modules, output, before_focus, accessor)
    verify_no_source_adaptations(output)

    try:
        resource_tool.verify(str(focus), str(resource_policy), str(resource_stage), str(resource_audit_path))
    except resource_tool.PolicyError as exc:
        raise ProofError(f"package-resource closing verification refused: {exc}") from exc
    # Close the local-tool bracket too: the compiler consumed an accessor made
    # by these exact bytes, so a concurrent policy/tool edit voids the proof.
    _attest_local_dependency(policy)
    closing_accessor = _read_regular(accessor, "closing DesignSystem Bundle.module accessor")
    if len(closing_accessor) != integration["accessor_size"] or sha256(closing_accessor) != integration["accessor_sha256"]:
        raise ProofError("DesignSystem Bundle.module accessor changed during module emission")
    after_focus = capture_focus(focus, policy)
    after_ui = capture_openuikit(openuikit, policy)
    if before_focus.identity() != after_focus.identity():
        raise ProofError("Focus source subject changed during module emission")
    if before_ui.identity() != after_ui.identity():
        raise ProofError("OpenUIKit source subject changed during module emission")

    swiftc = shutil.which("swiftc")
    assert swiftc is not None
    version = subprocess.check_output(
        [swiftc, "--version"], stderr=subprocess.STDOUT,
        env=controlled_environment(),
    )
    audit = {
        "schema": 1,
        "focus_commit": before_focus.commit,
        "openuikit_commit": before_ui.commit,
        "policy_sha256": sha256(policy_bytes),
        "resource_policy_sha256": integration["policy_sha256"],
        "resource_tool_sha256": integration["tool_sha256"],
        "resource_audit_sha256": sha256(_read_regular(resource_audit_path, "package-resource audit")),
        "resource_historical_openuikit_commit": integration["historical_openuikit_commit"],
        "build": policy["build"],
        "toolchain": {"swiftc": str(Path(swiftc).resolve()), "version_sha256": sha256(version), "version": version.decode("utf-8", errors="strict").splitlines()},
        "targets": _source_audit(after_focus, policy),
        "production_exclusions": _exclusion_audit(after_focus, policy),
        "source_adaptations": [],
        "generated_swift_inputs": [
            {
                "target": "DesignSystem",
                "kind": "compile-only Bundle.module accessor",
                "path": f"package-resources/{integration['accessor_path']}",
                "size": integration["accessor_size"],
                "sha256": integration["accessor_sha256"],
            }
        ],
        "openuikit_build": ui_build,
        "module_outputs": module_outputs,
        "diagnostics": diagnostics,
    }
    _write_exclusive(output / "appshortcuts-audit.json", canonical_json(audit), "AppShortcuts audit")
    return audit


def _usage() -> str:
    return "usage: appshortcuts_proof.py prove FOCUS_REPO OPENUIKIT_REPO POLICY NEW_OUTPUT"


def main(argv: list[str]) -> int:
    if len(argv) != 6 or argv[1] != "prove":
        print(_usage(), file=sys.stderr)
        return 2
    try:
        audit = prove(*argv[2:])
    except (ProofError, OSError, UnicodeError, ValueError) as exc:
        print(f"REFUSED: {exc}", file=sys.stderr)
        return 1
    print("PROVED: pinned Focus AppShortcuts port slice emitted four clean modules")
    print(f"  Focus:     {audit['focus_commit']}")
    print(f"  OpenUIKit: {audit['openuikit_commit']}")
    print(f"  target:    {audit['build']['target']} (Swift {audit['build']['swift_language_version']}, -wmo)")
    print(f"  sources:   {sum(target['source_count'] for target in audit['targets'])} unchanged shipping + 1 generated Bundle.module accessor")
    return 0


if __name__ == "__main__":
    raise SystemExit(main(sys.argv))
