#!/usr/bin/env python3
"""Fail-closed Apple-toolchain module-emission proof for Focus's Widget target.

The proof consumes exactly two unchanged shipping Swift sources plus one
generated, compile-only ``Bundle.module`` accessor. It stages the target's raw
asset catalog verbatim, but deliberately does not link, execute, discover a
bundle, compile the catalog, or decode its payloads.
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


FOCUS_COMMIT = "a2832521c1daa0c23419c73705ae043ed60c9791"
OPENUIKIT_COMMIT = "0bba80a4138ece678844e2f55da16ffb7cbf70e9"
SNAPKIT_COMMIT = "e74fe2a978d1216c3602b129447c7301573cc2d8"
TARGET = "arm64-apple-macos13.0"
SWIFT_LANGUAGE_VERSION = "5"
MODULE_NAME = "Widget"
MODULE_SUFFIXES = (".abi.json", ".swiftdoc", ".swiftmodule", ".swiftsourceinfo")

APPROVED_MANIFEST = {
    "path": "BlockzillaPackage/Package.swift",
    "size": 1975,
    "sha256": "2d29b769de137389f5613de6755211b255533375bf6003a2192f514e96899248",
}

APPROVED_SOURCES = [
    {
        "path": "BlockzillaPackage/Sources/Widget/Assets.swift",
        "size": 533,
        "sha256": "efac8d1c98b562374e54eea7540b4201523db670a6353eff8f0a0273d294526e",
    },
    {
        "path": "BlockzillaPackage/Sources/Widget/SearchWidgetView.swift",
        "size": 2006,
        "sha256": "721669388a4556e1609f580ed87d6065b63981770e71b0f77db292767b05f6c2",
    },
]
APPROVED_SOURCE_DIGEST = "9206ccc2a5bc96333805a38d48fb2092a40d308a4db950897e7977161e67884e"

APPROVED_RESOURCE_FILES = [
    {
        "path": "BlockzillaPackage/Sources/Widget/Media.xcassets/Contents.json",
        "size": 63,
        "sha256": "0fd49ba3c3585c709678e0046a821c3c60685ec7063720d30d3a3448be3a208b",
    },
    {
        "path": "BlockzillaPackage/Sources/Widget/Media.xcassets/GradientFirst.colorset/Contents.json",
        "size": 692,
        "sha256": "75759bdc8a68e4694bda34486c47e347ab8af010ebb8de7372b0ca443c08186b",
    },
    {
        "path": "BlockzillaPackage/Sources/Widget/Media.xcassets/GradientSecond.colorset/Contents.json",
        "size": 692,
        "sha256": "f71bc94e686809660d920da6f7804174097e038302a843c3533da45ceda44af2",
    },
    {
        "path": "BlockzillaPackage/Sources/Widget/Media.xcassets/icon_logo.imageset/Contents.json",
        "size": 159,
        "sha256": "b4a48ee46b1087f15188dc0a4cdf065251008e51e44427b1bb94f0744085eb79",
    },
    {
        "path": "BlockzillaPackage/Sources/Widget/Media.xcassets/icon_logo.imageset/icon_logo.pdf",
        "size": 71525,
        "sha256": "7f8ea654a4d0ac064fb38027c16ae730b1f0561a031bb465b71997b0df4188b7",
    },
]
APPROVED_RESOURCE_DIGEST = "cf65ea586b104d622bb50ec5f0c09a1dc11ec0f293d322776dbb6f698f880126"

ACCESSOR_BYTES = (
    b"import Foundation\n\n"
    b"extension Foundation.Bundle {\n"
    b"    static var module: Bundle { fatalError(\"runtime Bundle.module discovery is unavailable\") }\n"
    b"}\n"
)
ACCESSOR_PATH = "generated/Widget/Bundle+Module.swift"
ACCESSOR_SHA256 = "c0a3ee61e4fc8015d5e4a36775293347e21c58850605a6d47141f344211829aa"

SYSTEM_XCRUN = "/usr/bin/xcrun"
SAFE_PATH = "/usr/bin:/bin:/usr/sbin:/sbin"
TOOLCHAIN_OVERRIDE_NAMES = frozenset(
    {
        "AR",
        "AS",
        "CC",
        "CPATH",
        "CPLUS_INCLUDE_PATH",
        "CXX",
        "DEVELOPER_DIR",
        "IPHONEOS_DEPLOYMENT_TARGET",
        "LD",
        "LD_LIBRARY_PATH",
        "LIBRARY_PATH",
        "MACOSX_DEPLOYMENT_TARGET",
        "NM",
        "OBJC_INCLUDE_PATH",
        "RANLIB",
        "SDKROOT",
        "STRIP",
        "TOOLCHAINS",
    }
)
TOOLCHAIN_OVERRIDE_PREFIXES = ("CLANG_", "DYLD_", "LLVM_", "SWIFT_", "XCRUN_")

SHA256_RE = re.compile(r"[0-9a-f]{64}\Z")
COMMIT_RE = re.compile(r"[0-9a-f]{40}\Z")
NOFOLLOW = getattr(os, "O_NOFOLLOW", 0)


class ProofError(RuntimeError):
    """The requested proof no longer describes the reviewed subject."""


@dataclass(frozen=True)
class CapturedFile:
    path: str
    data: bytes

    def record(self) -> dict[str, Any]:
        return {"path": self.path, "size": len(self.data), "sha256": sha256(self.data)}


@dataclass(frozen=True)
class FocusCapture:
    commit: str
    status_sha256: str
    manifest: CapturedFile
    sources: tuple[CapturedFile, ...]
    resources: tuple[CapturedFile, ...]

    def identity(self) -> bytes:
        return canonical_json(
            {
                "commit": self.commit,
                "manifest": self.manifest.record(),
                "resources": [item.record() for item in self.resources],
                "sources": [item.record() for item in self.sources],
                "status_sha256": self.status_sha256,
            }
        )


@dataclass(frozen=True)
class ContextCapture:
    name: str
    commit: str
    status_sha256: str

    def identity(self) -> bytes:
        return canonical_json(self.audit())

    def audit(self) -> dict[str, Any]:
        return {
            "commit": self.commit,
            "compiler_input": False,
            "name": self.name,
            "status_sha256": self.status_sha256,
        }


@dataclass(frozen=True)
class AppleToolchain:
    xcrun_path: str
    xcrun_size: int
    xcrun_sha256: str
    compiler_launcher_path: str
    compiler_resolved_path: str
    compiler_size: int
    compiler_sha256: str
    sdk_path: str
    version: bytes

    def audit(self) -> dict[str, Any]:
        return {
            "compiler": {
                "launcher_path": self.compiler_launcher_path,
                "resolved_path": self.compiler_resolved_path,
                "sha256": self.compiler_sha256,
                "size": self.compiler_size,
            },
            "discovery": {
                "path": self.xcrun_path,
                "sha256": self.xcrun_sha256,
                "size": self.xcrun_size,
            },
            "environment": {
                "path": SAFE_PATH,
                "removed_exact_overrides": sorted(TOOLCHAIN_OVERRIDE_NAMES),
                "removed_override_prefixes": list(TOOLCHAIN_OVERRIDE_PREFIXES),
            },
            "sdk": {"path": self.sdk_path},
            "version": self.version.decode("utf-8", errors="strict").splitlines(),
            "version_sha256": sha256(self.version),
        }


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


def expected_policy() -> dict[str, Any]:
    return {
        "build": {
            "apple_toolchain_required": True,
            "module_name": MODULE_NAME,
            "module_suffixes": list(MODULE_SUFFIXES),
            "parse_as_library": True,
            "swift_language_version": SWIFT_LANGUAGE_VERSION,
            "target": TARGET,
            "whole_module_optimization": True,
        },
        "claims": {
            "apple_toolchain_module_emission_only": True,
            "linux_guest_link_or_run": False,
            "resource_catalog_compilation_or_decode": False,
            "runtime_bundle_discovery": False,
        },
        "focus": {
            "commit": FOCUS_COMMIT,
            "package_manifest": dict(APPROVED_MANIFEST),
            "worktree_prefix": "focus-ios",
        },
        "generated_source": {
            "classification": "generated-build-input",
            "path": ACCESSOR_PATH,
            "purpose": "compile-only module-local Bundle.module contract; runtime discovery intentionally unavailable",
            "sha256": ACCESSOR_SHA256,
            "size": len(ACCESSOR_BYTES),
        },
        "port_context": {
            "openuikit": {
                "commit": OPENUIKIT_COMMIT,
                "compiler_input": False,
                "worktree_prefix": ".",
            },
            "snapkit": {
                "commit": SNAPKIT_COMMIT,
                "compiler_input": False,
                "worktree_prefix": ".",
            },
        },
        "resources": {
            "byte_count": 73131,
            "declaration": "raw-unhandled-at-pinned-manifest",
            "file_count": 5,
            "files": json.loads(json.dumps(APPROVED_RESOURCE_FILES)),
            "source_digest": APPROVED_RESOURCE_DIGEST,
            "source_path": "BlockzillaPackage/Sources/Widget/Media.xcassets",
            "stage_path": "resources/Widget/Media.xcassets",
        },
        "schema": 1,
        "target": {
            "input_stage_path": "inputs/Widget",
            "name": MODULE_NAME,
            "source_digest": APPROVED_SOURCE_DIGEST,
            "source_root": "BlockzillaPackage/Sources/Widget",
            "sources": json.loads(json.dumps(APPROVED_SOURCES)),
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
    top_keys = {"build", "claims", "focus", "generated_source", "port_context", "resources", "schema", "target"}
    if not isinstance(policy, dict) or set(policy) != top_keys:
        raise ProofError("policy has unexpected top-level keys")
    if type(policy["schema"]) is not int or policy["schema"] != 1:
        raise ProofError("policy schema must be integer 1")

    def mapping(value: Any, keys: set[str], label: str) -> dict[str, Any]:
        if not isinstance(value, dict) or set(value) != keys:
            raise ProofError(f"{label} keys changed")
        return value

    def integer(value: Any, label: str) -> None:
        if type(value) is not int or value < 0:
            raise ProofError(f"{label} must be a non-negative integer")

    def digest(value: Any, label: str) -> None:
        if not isinstance(value, str) or not SHA256_RE.fullmatch(value):
            raise ProofError(f"{label} must be a lowercase SHA-256")

    def file_record(value: Any, label: str) -> str:
        record = mapping(value, {"path", "sha256", "size"}, label)
        path = _validate_relative(record["path"], f"{label}.path")
        integer(record["size"], f"{label}.size")
        digest(record["sha256"], f"{label}.sha256")
        return path

    focus = mapping(policy["focus"], {"commit", "package_manifest", "worktree_prefix"}, "focus")
    if not isinstance(focus["commit"], str) or not COMMIT_RE.fullmatch(focus["commit"]):
        raise ProofError("focus.commit must be a lowercase Git object ID")
    if not isinstance(focus["worktree_prefix"], str) or not focus["worktree_prefix"]:
        raise ProofError("focus.worktree_prefix must be a non-empty string")
    file_record(focus["package_manifest"], "focus.package_manifest")

    context = mapping(policy["port_context"], {"openuikit", "snapkit"}, "port_context")
    for name in ("openuikit", "snapkit"):
        item = mapping(context[name], {"commit", "compiler_input", "worktree_prefix"}, f"port_context.{name}")
        if not isinstance(item["commit"], str) or not COMMIT_RE.fullmatch(item["commit"]):
            raise ProofError(f"port_context.{name}.commit must be a lowercase Git object ID")
        if item["compiler_input"] is not False:
            raise ProofError(f"port_context.{name} must remain outside the Widget compiler inputs")
        if not isinstance(item["worktree_prefix"], str) or not item["worktree_prefix"]:
            raise ProofError(f"port_context.{name}.worktree_prefix must be a non-empty string")

    target = mapping(
        policy["target"],
        {"input_stage_path", "name", "source_digest", "source_root", "sources"},
        "target",
    )
    if not isinstance(target["name"], str) or not target["name"]:
        raise ProofError("target.name must be a non-empty string")
    _validate_relative(target["source_root"], "target.source_root")
    _validate_relative(target["input_stage_path"], "target.input_stage_path")
    digest(target["source_digest"], "target.source_digest")
    if not isinstance(target["sources"], list) or not target["sources"]:
        raise ProofError("target.sources must be a non-empty list")
    paths = [file_record(value, f"target.sources[{index}]") for index, value in enumerate(target["sources"])]
    if len(set(paths)) != len(paths):
        raise ProofError("target source paths are duplicated")

    resource = mapping(
        policy["resources"],
        {"byte_count", "declaration", "file_count", "files", "source_digest", "source_path", "stage_path"},
        "resources",
    )
    for key in ("source_path", "stage_path"):
        _validate_relative(resource[key], f"resources.{key}")
    if not isinstance(resource["declaration"], str) or not resource["declaration"]:
        raise ProofError("resources.declaration must be a non-empty string")
    integer(resource["file_count"], "resources.file_count")
    integer(resource["byte_count"], "resources.byte_count")
    digest(resource["source_digest"], "resources.source_digest")
    if not isinstance(resource["files"], list) or not resource["files"]:
        raise ProofError("resources.files must be a non-empty list")
    resource_paths = [file_record(value, f"resources.files[{index}]") for index, value in enumerate(resource["files"])]
    if len(set(resource_paths)) != len(resource_paths):
        raise ProofError("resource paths are duplicated")

    generated = mapping(
        policy["generated_source"],
        {"classification", "path", "purpose", "sha256", "size"},
        "generated_source",
    )
    _validate_relative(generated["path"], "generated_source.path")
    if not isinstance(generated["purpose"], str) or not generated["purpose"]:
        raise ProofError("generated_source.purpose must be a non-empty string")
    if generated["classification"] != "generated-build-input":
        raise ProofError("generated_source.classification changed")
    integer(generated["size"], "generated_source.size")
    digest(generated["sha256"], "generated_source.sha256")

    build = mapping(
        policy["build"],
        {"apple_toolchain_required", "module_name", "module_suffixes", "parse_as_library", "swift_language_version", "target", "whole_module_optimization"},
        "build",
    )
    if build["apple_toolchain_required"] is not True:
        raise ProofError("build must require the Apple toolchain")
    for key in ("parse_as_library", "whole_module_optimization"):
        if type(build[key]) is not bool:
            raise ProofError(f"build.{key} must be a boolean")
    for key in ("module_name", "swift_language_version", "target"):
        if not isinstance(build[key], str) or not build[key]:
            raise ProofError(f"build.{key} must be a non-empty string")
    if not isinstance(build["module_suffixes"], list) or not all(isinstance(item, str) for item in build["module_suffixes"]):
        raise ProofError("build.module_suffixes must be a string list")

    claims = mapping(
        policy["claims"],
        {"apple_toolchain_module_emission_only", "linux_guest_link_or_run", "resource_catalog_compilation_or_decode", "runtime_bundle_discovery"},
        "claims",
    )
    if claims != {
        "apple_toolchain_module_emission_only": True,
        "linux_guest_link_or_run": False,
        "resource_catalog_compilation_or_decode": False,
        "runtime_bundle_discovery": False,
    }:
        raise ProofError("claim boundary changed")


def _read_regular(path: Path, label: str) -> bytes:
    try:
        metadata = path.lstat()
    except OSError as exc:
        raise ProofError(f"cannot stat {label} {path}: {exc}") from exc
    if stat.S_ISLNK(metadata.st_mode):
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
        before_identity = (before.st_dev, before.st_ino, before.st_size, before.st_mtime_ns, before.st_ctime_ns)
        after_identity = (after.st_dev, after.st_ino, after.st_size, after.st_mtime_ns, after.st_ctime_ns)
        if before_identity != after_identity:
            raise ProofError(f"{label} changed while being read: {path}")
        data = b"".join(chunks)
        if len(data) != after.st_size:
            raise ProofError(f"{label} size changed while being read: {path}")
        return data
    finally:
        os.close(descriptor)


def load_policy(path: Path) -> tuple[bytes, dict[str, Any]]:
    data = _read_regular(path, "Widget policy")
    try:
        policy = json.loads(data)
    except json.JSONDecodeError as exc:
        raise ProofError(f"cannot parse Widget policy: {exc}") from exc
    _validate_policy_shape(policy)
    if policy != expected_policy():
        raise ProofError("policy does not match the reviewed Focus Widget subject")
    if data != canonical_json(policy):
        raise ProofError("Widget policy is not canonically encoded")
    return data, policy


def controlled_environment() -> dict[str, str]:
    environment = {
        name: value
        for name, value in os.environ.items()
        if not name.startswith("GIT_")
        and name not in TOOLCHAIN_OVERRIDE_NAMES
        and not name.startswith(TOOLCHAIN_OVERRIDE_PREFIXES)
    }
    environment.update(
        {
            "GIT_CONFIG_GLOBAL": os.devnull,
            "GIT_CONFIG_NOSYSTEM": "1",
            "GIT_NO_REPLACE_OBJECTS": "1",
            "GIT_OPTIONAL_LOCKS": "0",
            "LANG": "C",
            "LC_ALL": "C",
            "PATH": SAFE_PATH,
        }
    )
    return environment


def git(repo: Path, *args: str) -> bytes:
    command = [
        "git", "-c", "core.fsmonitor=false", "-c", f"core.hooksPath={os.devnull}",
        "-C", str(repo), *args,
    ]
    try:
        return subprocess.check_output(command, stderr=subprocess.STDOUT, env=controlled_environment())
    except (OSError, subprocess.CalledProcessError) as exc:
        output = getattr(exc, "output", b"")
        detail = output.decode("utf-8", errors="replace").strip() if isinstance(output, bytes) else str(output)
        raise ProofError(f"git {' '.join(args)} failed: {detail}") from exc


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
    for part in PurePosixPath(_validate_relative(relative, "subject path")).parts:
        current = current / part
        try:
            metadata = current.lstat()
        except OSError as exc:
            raise ProofError(f"cannot stat subject path component {current}: {exc}") from exc
        if stat.S_ISLNK(metadata.st_mode):
            raise ProofError(f"subject path must not contain symlinks: {current}")


def _attest_committed_file(
    root: Path,
    repo: Path,
    prefix: str,
    expected: dict[str, Any],
    label: str,
) -> CapturedFile:
    relative = expected["path"]
    full = _git_path(prefix, relative)
    raw = git(root, "ls-tree", "-z", "HEAD", "--", full)
    records = [record for record in raw.split(b"\0") if record]
    if len(records) != 1 or b"\t" not in records[0]:
        raise ProofError(f"{label} is not exactly one committed blob: {relative}")
    metadata, raw_path = records[0].split(b"\t", 1)
    fields = metadata.split(b" ")
    if len(fields) != 3 or fields[0] != b"100644" or fields[1] != b"blob":
        raise ProofError(f"{label} Git mode/type changed: {relative}")
    if raw_path.decode("utf-8", errors="strict") != full:
        raise ProofError(f"{label} Git path changed: {relative}")
    _reject_symlink_components(repo, relative)
    data = _read_regular(repo / relative, label)
    committed = git(root, "cat-file", "blob", fields[2].decode("ascii", errors="strict"))
    if data != committed:
        raise ProofError(f"{label} worktree bytes differ from HEAD: {relative}")
    captured = CapturedFile(relative, data)
    if captured.record() != expected:
        raise ProofError(f"{label} bytes changed: {relative}")
    return captured


def _tracked_inventory(root: Path, prefix: str, subject_root: str, swift_only: bool) -> list[str]:
    full_root = _git_path(prefix, subject_root)
    raw = git(root, "ls-tree", "-r", "--name-only", "-z", "HEAD", "--", full_root)
    if raw and not raw.endswith(b"\0"):
        raise ProofError("Git subject inventory is not NUL terminated")
    prefix_text = "" if prefix == "." else f"{prefix}/"
    result: list[str] = []
    for raw_path in raw.split(b"\0"):
        if not raw_path:
            continue
        path = raw_path.decode("utf-8", errors="strict")
        if not path.startswith(prefix_text):
            raise ProofError("Git subject inventory escaped its repository prefix")
        relative = path[len(prefix_text):]
        if not swift_only or relative.endswith(".swift"):
            result.append(relative)
    return sorted(result, key=lambda value: value.encode("utf-8"))


def capture_focus(repo: Path, policy: dict[str, Any]) -> FocusCapture:
    focus_policy = policy["focus"]
    root, prefix = _repository_root_and_prefix(repo, focus_policy["worktree_prefix"], "Focus")
    commit = git(root, "rev-parse", "--verify", "HEAD^{commit}").decode("ascii", errors="strict").strip()
    if commit != focus_policy["commit"]:
        raise ProofError(f"Focus commit changed: expected {focus_policy['commit']}, got {commit}")
    status = git(root, "status", "--porcelain=v1", "-z", "--untracked-files=all")
    if status:
        raise ProofError("Focus worktree is dirty or contains untracked files")
    manifest = _attest_committed_file(root, repo, prefix, focus_policy["package_manifest"], "Package.swift")

    target = policy["target"]
    expected_sources = sorted((item["path"] for item in target["sources"]), key=lambda value: value.encode("utf-8"))
    if _tracked_inventory(root, prefix, target["source_root"], True) != expected_sources:
        raise ProofError("Widget committed Swift inventory changed")
    sources = tuple(
        _attest_committed_file(root, repo, prefix, expected, "Widget source")
        for expected in target["sources"]
    )
    if records_digest((item.path, item.data) for item in sources) != target["source_digest"]:
        raise ProofError("Widget aggregate source digest changed")

    resources_policy = policy["resources"]
    expected_resources = sorted((item["path"] for item in resources_policy["files"]), key=lambda value: value.encode("utf-8"))
    if _tracked_inventory(root, prefix, resources_policy["source_path"], False) != expected_resources:
        raise ProofError("Widget resource inventory changed")
    resources = tuple(
        _attest_committed_file(root, repo, prefix, expected, "Widget resource")
        for expected in resources_policy["files"]
    )
    if len(resources) != resources_policy["file_count"]:
        raise ProofError("Widget resource file count changed")
    if sum(len(item.data) for item in resources) != resources_policy["byte_count"]:
        raise ProofError("Widget resource byte count changed")
    if records_digest((item.path, item.data) for item in resources) != resources_policy["source_digest"]:
        raise ProofError("Widget resource digest changed")
    return FocusCapture(commit, sha256(status), manifest, sources, resources)


def capture_context(repo: Path, policy: dict[str, Any], key: str) -> ContextCapture:
    context = policy["port_context"][key]
    label = "OpenUIKit" if key == "openuikit" else "SnapKit"
    root, _ = _repository_root_and_prefix(repo, context["worktree_prefix"], label)
    commit = git(root, "rev-parse", "--verify", "HEAD^{commit}").decode("ascii", errors="strict").strip()
    if commit != context["commit"]:
        raise ProofError(f"{label} commit changed: expected {context['commit']}, got {commit}")
    status = git(root, "status", "--porcelain=v1", "-z", "--untracked-files=all")
    if status:
        raise ProofError(f"{label} worktree is dirty or contains untracked files")
    return ContextCapture(label, commit, sha256(status))


def _resolve_new_output(value: str, repositories: tuple[Path, ...]) -> Path:
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
    for repository in repositories:
        try:
            output.relative_to(repository)
        except ValueError:
            continue
        raise ProofError("proof output must be outside source repositories")
    return output


def _write_exclusive(path: Path, data: bytes, label: str) -> None:
    path.parent.mkdir(mode=0o755, parents=True, exist_ok=True)
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


def _tree_inventory(root: Path, label: str) -> tuple[list[str], list[str]]:
    if root.is_symlink() or not root.is_dir():
        raise ProofError(f"{label} root must be a real directory: {root}")
    directories: list[str] = []
    files: list[str] = []
    for current_value, raw_directories, raw_files in os.walk(root, topdown=True, followlinks=False):
        current = Path(current_value)
        for name in raw_directories:
            path = current / name
            metadata = path.lstat()
            if stat.S_ISLNK(metadata.st_mode) or not stat.S_ISDIR(metadata.st_mode):
                raise ProofError(f"{label} contains a non-directory entry: {path}")
            directories.append(path.relative_to(root).as_posix())
        for name in raw_files:
            path = current / name
            _read_regular(path, label)
            files.append(path.relative_to(root).as_posix())
    return (
        sorted(directories, key=lambda value: value.encode("utf-8")),
        sorted(files, key=lambda value: value.encode("utf-8")),
    )


def _expected_stage(captured: FocusCapture, policy: dict[str, Any]) -> list[tuple[str, bytes]]:
    source_root = PurePosixPath(policy["resources"]["source_path"])
    stage_root = PurePosixPath(policy["resources"]["stage_path"])
    result: list[tuple[str, bytes]] = []
    for item in captured.resources:
        try:
            suffix = PurePosixPath(item.path).relative_to(source_root)
        except ValueError as exc:
            raise ProofError(f"resource escaped approved root: {item.path}") from exc
        result.append(((stage_root / suffix).as_posix(), item.data))
    return sorted(result, key=lambda item: item[0].encode("utf-8"))


def stage_resources(output: Path, captured: FocusCapture, policy: dict[str, Any]) -> list[dict[str, Any]]:
    records: list[dict[str, Any]] = []
    for relative, data in _expected_stage(captured, policy):
        _write_exclusive(output / relative, data, "staged Widget resource")
        records.append({"path": relative, "sha256": sha256(data), "size": len(data)})
    verify_stage(output, captured, policy)
    return records


def _expected_directories(paths: Iterable[str]) -> list[str]:
    result: set[str] = set()
    for value in paths:
        parent = PurePosixPath(value).parent
        while parent.as_posix() != ".":
            result.add(parent.as_posix())
            parent = parent.parent
    return sorted(result, key=lambda value: value.encode("utf-8"))


def _expected_source_inputs(
    captured: FocusCapture,
    policy: dict[str, Any],
) -> list[tuple[str, str, bytes]]:
    source_root = PurePosixPath(policy["target"]["source_root"])
    input_root = PurePosixPath(policy["target"]["input_stage_path"])
    result: list[tuple[str, str, bytes]] = []
    for item in captured.sources:
        try:
            suffix = PurePosixPath(item.path).relative_to(source_root)
        except ValueError as exc:
            raise ProofError(f"shipping source escaped approved root: {item.path}") from exc
        result.append((item.path, (input_root / suffix).as_posix(), item.data))
    return sorted(result, key=lambda item: item[1].encode("utf-8"))


def stage_source_inputs(
    output: Path,
    captured: FocusCapture,
    policy: dict[str, Any],
) -> list[dict[str, Any]]:
    records: list[dict[str, Any]] = []
    for source_path, input_path, data in _expected_source_inputs(captured, policy):
        _write_exclusive(output / input_path, data, "unchanged Widget shipping-source input")
        records.append(
            {
                "input_path": input_path,
                "sha256": sha256(data),
                "size": len(data),
                "source_path": source_path,
            }
        )
    verify_source_inputs(output, captured, policy)
    return records


def verify_source_inputs(output: Path, captured: FocusCapture, policy: dict[str, Any]) -> None:
    expected = _expected_source_inputs(captured, policy)
    expected_files = [input_path for _, input_path, _ in expected]
    actual_directories, actual_files = _tree_inventory(output / "inputs", "shipping-source input stage")
    relative_expected_files = [PurePosixPath(path).relative_to("inputs").as_posix() for path in expected_files]
    if actual_files != relative_expected_files:
        raise ProofError("shipping-source input inventory is stale, missing, or untracked")
    if actual_directories != _expected_directories(relative_expected_files):
        raise ProofError("shipping-source input directory inventory changed")
    for _, input_path, data in expected:
        staged = _read_regular(output / input_path, "unchanged Widget shipping-source input")
        if staged != data:
            raise ProofError(f"shipping-source input bytes changed: {input_path}")


def verify_stage(output: Path, captured: FocusCapture, policy: dict[str, Any]) -> None:
    expected = _expected_stage(captured, policy)
    expected_files = [path for path, _ in expected]
    actual_directories, actual_files = _tree_inventory(output / "resources", "Widget resource stage")
    relative_expected_files = [PurePosixPath(path).relative_to("resources").as_posix() for path in expected_files]
    if actual_files != relative_expected_files:
        raise ProofError("Widget staged resource inventory is stale, missing, or untracked")
    expected_directories = _expected_directories(relative_expected_files)
    if actual_directories != expected_directories:
        raise ProofError("Widget staged resource directory inventory changed")
    for relative, data in expected:
        staged = _read_regular(output / relative, "staged Widget resource")
        if staged != data:
            raise ProofError(f"staged Widget resource bytes changed: {relative}")


def write_generated_source(output: Path, policy: dict[str, Any]) -> dict[str, Any]:
    generated = policy["generated_source"]
    if len(ACCESSOR_BYTES) != generated["size"] or sha256(ACCESSOR_BYTES) != generated["sha256"]:
        raise ProofError("compiled-in Widget Bundle.module accessor changed")
    _write_exclusive(output / generated["path"], ACCESSOR_BYTES, "Widget Bundle.module accessor")
    verify_generated_source(output, policy)
    return {
        "classification": generated["classification"],
        "path": generated["path"],
        "purpose": generated["purpose"],
        "sha256": generated["sha256"],
        "size": generated["size"],
    }


def verify_generated_source(output: Path, policy: dict[str, Any]) -> None:
    generated = policy["generated_source"]
    root = output / "generated"
    directories, files = _tree_inventory(root, "generated source stage")
    expected_file = PurePosixPath(generated["path"]).relative_to("generated").as_posix()
    if files != [expected_file] or directories != _expected_directories([expected_file]):
        raise ProofError("generated source inventory contains an adaptation or unexpected input")
    data = _read_regular(output / generated["path"], "Widget Bundle.module accessor")
    if len(data) != generated["size"] or sha256(data) != generated["sha256"] or data != ACCESSOR_BYTES:
        raise ProofError("generated Widget Bundle.module accessor changed")


def _run(command: list[str], log: Path, label: str) -> None:
    try:
        with log.open("xb") as output:
            result = subprocess.run(
                command,
                stdout=output,
                stderr=subprocess.STDOUT,
                env=controlled_environment(),
                check=False,
            )
    except OSError as exc:
        raise ProofError(f"cannot run {label}: {exc}") from exc
    if result.returncode != 0:
        raise ProofError(f"{label} failed with exit {result.returncode}; see {log}")


def _one_absolute_path(data: bytes, label: str) -> Path:
    try:
        lines = data.decode("utf-8", errors="strict").splitlines()
    except UnicodeError as exc:
        raise ProofError(f"{label} returned non-UTF-8 output") from exc
    if len(lines) != 1 or not lines[0]:
        raise ProofError(f"{label} did not return exactly one path")
    path = Path(lines[0])
    if not path.is_absolute():
        raise ProofError(f"{label} returned a non-absolute path")
    return path


def _apple_toolchain() -> AppleToolchain:
    if sys.platform != "darwin":
        raise ProofError("Widget proof requires macOS and the Apple Swift toolchain")
    xcrun = Path(SYSTEM_XCRUN)
    xcrun_data = _read_regular(xcrun, "system xcrun")
    if not os.access(xcrun, os.X_OK):
        raise ProofError("system xcrun is not executable")
    environment = controlled_environment()
    try:
        compiler_output = subprocess.check_output(
            [SYSTEM_XCRUN, "--sdk", "macosx", "--find", "swiftc"],
            stderr=subprocess.STDOUT,
            env=environment,
        )
        sdk_output = subprocess.check_output(
            [SYSTEM_XCRUN, "--sdk", "macosx", "--show-sdk-path"],
            stderr=subprocess.STDOUT,
            env=environment,
        )
    except (OSError, subprocess.CalledProcessError) as exc:
        raise ProofError(f"cannot resolve the Apple Swift toolchain with {SYSTEM_XCRUN}: {exc}") from exc

    compiler_launcher = _one_absolute_path(compiler_output, "xcrun swiftc discovery")
    try:
        compiler_resolved = compiler_launcher.resolve(strict=True)
    except OSError as exc:
        raise ProofError(f"cannot resolve xcrun's swiftc: {exc}") from exc
    compiler_data = _read_regular(compiler_resolved, "resolved Apple Swift compiler")
    if not os.access(compiler_launcher, os.X_OK):
        raise ProofError("xcrun's Swift compiler is not executable")

    sdk_reported = _one_absolute_path(sdk_output, "xcrun macOS SDK discovery")
    try:
        sdk = sdk_reported.resolve(strict=True)
    except OSError as exc:
        raise ProofError(f"cannot resolve xcrun's macOS SDK: {exc}") from exc
    if not sdk.is_dir() or sdk.is_symlink():
        raise ProofError("xcrun's resolved macOS SDK is not a real directory")

    try:
        version = subprocess.check_output(
            [str(compiler_launcher), "--version"],
            stderr=subprocess.STDOUT,
            env=environment,
        )
    except (OSError, subprocess.CalledProcessError) as exc:
        raise ProofError(f"cannot identify xcrun's Swift compiler: {exc}") from exc
    if b"Apple Swift version" not in version:
        raise ProofError("Widget proof requires Apple's Swift compiler")
    return AppleToolchain(
        xcrun_path=SYSTEM_XCRUN,
        xcrun_size=len(xcrun_data),
        xcrun_sha256=sha256(xcrun_data),
        compiler_launcher_path=str(compiler_launcher),
        compiler_resolved_path=str(compiler_resolved),
        compiler_size=len(compiler_data),
        compiler_sha256=sha256(compiler_data),
        sdk_path=str(sdk),
        version=version,
    )


def _compiler_command(
    toolchain: AppleToolchain,
    output: Path,
    policy: dict[str, Any],
    shipping_inputs: list[dict[str, Any]],
) -> list[str]:
    module_path = output / "modules" / f"{MODULE_NAME}.swiftmodule"
    source_paths = [output / item["input_path"] for item in shipping_inputs]
    accessor = output / policy["generated_source"]["path"]
    return [
        toolchain.compiler_launcher_path,
        "-sdk",
        toolchain.sdk_path,
        "-emit-module",
        "-emit-module-path",
        str(module_path),
        "-parse-as-library",
        "-wmo",
        "-swift-version",
        policy["build"]["swift_language_version"],
        "-target",
        policy["build"]["target"],
        "-module-name",
        policy["build"]["module_name"],
        *(str(path) for path in source_paths),
        str(accessor),
    ]


def compile_module(
    output: Path,
    captured: FocusCapture,
    policy: dict[str, Any],
    shipping_inputs: list[dict[str, Any]],
) -> tuple[list[dict[str, Any]], dict[str, Any], dict[str, Any]]:
    toolchain = _apple_toolchain()
    modules = output / "modules"
    diagnostics = output / "diagnostics"
    modules.mkdir(mode=0o755)
    diagnostics.mkdir(mode=0o755)
    log = diagnostics / f"{MODULE_NAME}.log"
    verify_source_inputs(output, captured, policy)
    verify_generated_source(output, policy)
    command = _compiler_command(toolchain, output, policy, shipping_inputs)
    _run(command, log, "Widget module emission")
    verify_source_inputs(output, captured, policy)
    verify_generated_source(output, policy)
    if _apple_toolchain() != toolchain:
        raise ProofError("Apple compiler or macOS SDK identity changed during module emission")
    log_data = _read_regular(log, "Widget diagnostic log")
    if log_data:
        raise ProofError(f"Widget emitted unexpected diagnostics; see {log}")
    expected_files = sorted(f"{MODULE_NAME}{suffix}" for suffix in MODULE_SUFFIXES)
    _, actual_files = _tree_inventory(modules, "Widget module outputs")
    if actual_files != expected_files:
        raise ProofError("Widget module output inventory is stale, missing, or untracked")
    outputs: list[dict[str, Any]] = []
    for name in expected_files:
        data = _read_regular(modules / name, "Widget module output")
        if not data:
            raise ProofError(f"Widget module output is empty: {name}")
        outputs.append({"path": f"modules/{name}", "sha256": sha256(data), "size": len(data)})
    diagnostic = {"path": f"diagnostics/{MODULE_NAME}.log", "sha256": sha256(log_data), "size": len(log_data)}
    toolchain_audit = toolchain.audit()
    toolchain_audit["invocation"] = {
        "command": command,
        "compiler_inputs": [
            {"classification": "unchanged-shipping-source", **item}
            for item in shipping_inputs
        ]
        + [
            {
                "classification": policy["generated_source"]["classification"],
                "path": policy["generated_source"]["path"],
                "sha256": policy["generated_source"]["sha256"],
                "size": policy["generated_source"]["size"],
            }
        ],
        "link_step": False,
        "operation": "emit-module-only",
    }
    return outputs, diagnostic, toolchain_audit


def prove(
    focus_value: str,
    openuikit_value: str,
    snapkit_value: str,
    policy_value: str,
    output_value: str,
) -> dict[str, Any]:
    focus = _resolve_repository(focus_value, "Focus")
    openuikit = _resolve_repository(openuikit_value, "OpenUIKit")
    snapkit = _resolve_repository(snapkit_value, "SnapKit")
    policy_path = Path(policy_value).resolve(strict=True)
    policy_bytes, policy = load_policy(policy_path)
    before_focus = capture_focus(focus, policy)
    before_ui = capture_context(openuikit, policy, "openuikit")
    before_snapkit = capture_context(snapkit, policy, "snapkit")
    repository_roots = tuple(
        Path(git(repository, "rev-parse", "--show-toplevel").decode("utf-8", errors="strict").strip()).resolve(strict=True)
        for repository in (focus, openuikit, snapkit)
    )
    output = _resolve_new_output(output_value, repository_roots)
    output.mkdir(mode=0o755)

    shipping_inputs = stage_source_inputs(output, before_focus, policy)
    staged_resources = stage_resources(output, before_focus, policy)
    generated_source = write_generated_source(output, policy)
    module_outputs, diagnostic, toolchain = compile_module(
        output,
        before_focus,
        policy,
        shipping_inputs,
    )
    verify_source_inputs(output, before_focus, policy)
    verify_stage(output, before_focus, policy)
    verify_generated_source(output, policy)

    after_focus = capture_focus(focus, policy)
    after_ui = capture_context(openuikit, policy, "openuikit")
    after_snapkit = capture_context(snapkit, policy, "snapkit")
    if before_focus.identity() != after_focus.identity():
        raise ProofError("Focus Widget subject changed during module emission")
    if before_ui.identity() != after_ui.identity():
        raise ProofError("OpenUIKit context changed during module emission")
    if before_snapkit.identity() != after_snapkit.identity():
        raise ProofError("SnapKit context changed during module emission")
    if _read_regular(policy_path, "closing Widget policy") != policy_bytes:
        raise ProofError("Widget policy changed during module emission")

    audit = {
        "build": policy["build"],
        "claims": policy["claims"],
        "diagnostics": [diagnostic],
        "focus_commit": after_focus.commit,
        "generated_build_inputs": [generated_source],
        "module_outputs": module_outputs,
        "policy_sha256": sha256(policy_bytes),
        "port_context": [after_ui.audit(), after_snapkit.audit()],
        "resource_stage": {
            "byte_count": sum(item["size"] for item in staged_resources),
            "file_count": len(staged_resources),
            "source_digest": policy["resources"]["source_digest"],
            "staged_files": staged_resources,
        },
        "schema": 1,
        "shipping_source_edits": [],
        "shipping_source_inputs": {
            "files": shipping_inputs,
            "source_count": len(shipping_inputs),
            "source_digest": policy["target"]["source_digest"],
        },
        "target": {
            "name": MODULE_NAME,
            "source_count": len(after_focus.sources),
            "source_digest": policy["target"]["source_digest"],
            "sources": [item.record() for item in after_focus.sources],
        },
        "toolchain": toolchain,
    }
    _write_exclusive(output / "widget-audit.json", canonical_json(audit), "Widget audit")
    return audit


def _usage() -> str:
    return "usage: widget_proof.py prove FOCUS_REPO OPENUIKIT_REPO SNAPKIT_REPO POLICY NEW_OUTPUT"


def main(argv: list[str]) -> int:
    if len(argv) != 7 or argv[1] != "prove":
        print(_usage(), file=sys.stderr)
        return 2
    try:
        audit = prove(*argv[2:])
    except (ProofError, OSError, UnicodeError, ValueError) as exc:
        print(f"REFUSED: {exc}", file=sys.stderr)
        return 1
    print("PROVED: pinned Focus Widget target emitted one clean Apple-toolchain module")
    print(f"  Focus:     {audit['focus_commit']}")
    print(f"  target:    {audit['build']['target']} (Swift {audit['build']['swift_language_version']}, -wmo)")
    print("  sources:   2 unchanged shipping + 1 generated compile-only Bundle.module accessor")
    print("  resources: 5 raw files / 73131 bytes staged; not compiled or decoded")
    return 0


if __name__ == "__main__":
    raise SystemExit(main(sys.argv))
