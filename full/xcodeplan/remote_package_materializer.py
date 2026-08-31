#!/usr/bin/env python3
"""Materialize exact remote Swift-package pins into verified immutable caches.

This tool never asks SwiftPM to resolve a dependency.  Its only network input
is an exact URL/revision pair already frozen by ``Package.resolved`` and the
local package graph.  Cache hits are re-proved and corrupt/stale entries are
refused rather than repaired in place.
"""

from __future__ import annotations

import argparse
import hashlib
import json
import os
from pathlib import Path, PurePosixPath
import re
import secrets
import shutil
import stat
import subprocess
import sys
import unicodedata
from typing import Any, Mapping
from urllib.parse import urlsplit, urlunsplit


class MaterializationError(RuntimeError):
    """An exact remote package could not be proved."""


_OBJECT_ID = re.compile(r"[0-9a-f]{40,64}\Z")


def _mapping(value: Any, label: str) -> dict[str, Any]:
    if not isinstance(value, dict):
        raise MaterializationError(f"{label} must be an object")
    return value


def _list(value: Any, label: str) -> list[Any]:
    if not isinstance(value, list):
        raise MaterializationError(f"{label} must be an array")
    return value


def _string(value: Any, label: str) -> str:
    if not isinstance(value, str) or not value:
        raise MaterializationError(f"{label} must be a non-empty string")
    if any(character in value for character in "\0\r\n"):
        raise MaterializationError(f"{label} contains a forbidden control character")
    return value


def _sha256(data: bytes) -> str:
    return hashlib.sha256(data).hexdigest()


def canonical_json(value: Any) -> bytes:
    return (json.dumps(value, sort_keys=True, separators=(",", ":")) + "\n").encode(
        "utf-8"
    )


def _json_no_duplicates(data: bytes, label: str) -> Any:
    def pairs(values: list[tuple[str, Any]]) -> dict[str, Any]:
        result: dict[str, Any] = {}
        for key, value in values:
            if key in result:
                raise MaterializationError(f"{label} repeats JSON key {key!r}")
            result[key] = value
        return result

    try:
        return json.loads(data, object_pairs_hook=pairs)
    except (UnicodeDecodeError, json.JSONDecodeError) as exc:
        raise MaterializationError(f"cannot parse {label}: {exc}") from exc


def _ordinary_absolute_directory(value: Path, label: str, create: bool = False) -> Path:
    if not value.is_absolute():
        raise MaterializationError(f"{label} must be absolute")
    if create and not value.exists() and not value.is_symlink():
        parent = _ordinary_absolute_directory(value.parent, f"{label} parent")
        value = parent / value.name
        value.mkdir(mode=0o755)
    try:
        metadata = value.lstat()
    except OSError as exc:
        raise MaterializationError(f"cannot inspect {label}: {value}: {exc}") from exc
    if stat.S_ISLNK(metadata.st_mode):
        raise MaterializationError(f"{label} must not be a symlink: {value}")
    if not stat.S_ISDIR(metadata.st_mode):
        raise MaterializationError(f"{label} is not an ordinary directory: {value}")
    return value.resolve(strict=True)


def _safe_relative(value: str, label: str) -> PurePosixPath:
    path = PurePosixPath(value)
    if (
        path.is_absolute()
        or not path.parts
        or path.as_posix() != value
        or any(part in ("", ".", "..") for part in path.parts)
        or "\\" in value
        or any(character in value for character in "\0\r\n")
    ):
        raise MaterializationError(f"{label} is not a normalized relative path")
    return path


def _ordinary_file(root: Path, relative: str, label: str) -> Path:
    root = root.resolve(strict=True)
    path = root
    for component in _safe_relative(relative, label).parts:
        path /= component
        try:
            metadata = path.lstat()
        except OSError as exc:
            raise MaterializationError(
                f"cannot inspect {label}: {path}: {exc}"
            ) from exc
        if stat.S_ISLNK(metadata.st_mode):
            raise MaterializationError(f"{label} traverses a symlink: {path}")
    if not stat.S_ISREG(path.lstat().st_mode):
        raise MaterializationError(f"{label} is not a regular file: {path}")
    try:
        path.resolve(strict=True).relative_to(root)
    except ValueError as exc:
        raise MaterializationError(f"{label} escapes its cache entry") from exc
    return path


def _ensure_child_directory(parent: Path, name: str, label: str) -> Path:
    if not name or name in {".", ".."} or "/" in name or "\\" in name:
        raise MaterializationError(f"{label} has an unsafe directory name")
    parent = _ordinary_absolute_directory(parent, f"{label} parent")
    child = parent / name
    if not child.exists() and not child.is_symlink():
        try:
            child.mkdir(mode=0o755)
        except FileExistsError:
            pass
    child = _ordinary_absolute_directory(child, label)
    try:
        child.relative_to(parent)
    except ValueError as exc:
        raise MaterializationError(f"{label} escapes its parent") from exc
    return child


def normalized_remote_url(value: str, *, allow_file_url: bool = False) -> str:
    """Validate a source-control URL and return its exact canonical spelling."""

    raw = _string(value, "remote package URL")
    parsed = urlsplit(raw)
    allowed = {"https"} | ({"file"} if allow_file_url else set())
    if parsed.scheme.lower() not in allowed:
        raise MaterializationError(
            f"remote package URL scheme is not allowed: {parsed.scheme!r}"
        )
    if parsed.query or parsed.fragment or parsed.username or parsed.password:
        raise MaterializationError(
            "remote package URL contains credentials, query, or fragment"
        )
    if parsed.scheme.lower() == "https":
        if not parsed.hostname or parsed.port not in (None, 443):
            raise MaterializationError(
                "remote HTTPS package URL has no host or a non-default port"
            )
        netloc = parsed.hostname.lower()
        path = parsed.path
    else:
        if parsed.netloc not in ("", "localhost") or not parsed.path.startswith("/"):
            raise MaterializationError(
                "test file package URL must be an absolute local URL"
            )
        netloc = parsed.netloc
        path = parsed.path
    components = PurePosixPath(path).parts
    if (
        not path
        or path.endswith("/")
        or "\\" in path
        or any(part in (".", "..") for part in components)
    ):
        raise MaterializationError("remote package URL path is not canonical")
    return urlunsplit((parsed.scheme.lower(), netloc, path, "", ""))


def descriptor_for(
    package: Mapping[str, Any], *, allow_file_url: bool = False
) -> dict[str, str]:
    pin = _mapping(package.get("pin"), "external package pin")
    revision = _string(pin.get("revision"), "external package pin revision")
    if _OBJECT_ID.fullmatch(revision) is None:
        raise MaterializationError("external package pin is not an immutable object ID")
    raw_url = _string(package.get("url"), "external package URL")
    url = normalized_remote_url(
        raw_url,
        allow_file_url=allow_file_url,
    )
    raw_location = _string(pin.get("location"), "external package pin location")
    location = normalized_remote_url(
        raw_location,
        allow_file_url=allow_file_url,
    )
    if url != raw_url or location != raw_location:
        raise MaterializationError(
            "external package URL or pin location is not canonical"
        )
    if location != url:
        raise MaterializationError(
            "external package URL differs from its exact pin location"
        )
    identity = _string(package.get("identity"), "external package identity")
    if not re.fullmatch(r"[a-z0-9][a-z0-9._-]*", identity):
        raise MaterializationError(
            f"external package identity is not portable: {identity!r}"
        )
    return {"identity": identity, "revision": revision, "url": url}


def _validated_descriptor(
    descriptor: Mapping[str, Any], *, allow_file_url: bool = False
) -> dict[str, str]:
    identity = _string(descriptor.get("identity"), "remote descriptor identity")
    revision = _string(descriptor.get("revision"), "remote descriptor revision")
    raw_url = _string(descriptor.get("url"), "remote descriptor URL")
    url = normalized_remote_url(raw_url, allow_file_url=allow_file_url)
    if url != raw_url:
        raise MaterializationError("remote descriptor URL is not canonically spelled")
    if not re.fullmatch(r"[a-z0-9][a-z0-9._-]*", identity):
        raise MaterializationError(
            f"remote descriptor identity is not portable: {identity!r}"
        )
    if _OBJECT_ID.fullmatch(revision) is None:
        raise MaterializationError(
            "remote descriptor revision is not an immutable object ID"
        )
    return {"identity": identity, "revision": revision, "url": url}


def descriptor_digest(descriptor: Mapping[str, str]) -> str:
    return _sha256(
        canonical_json(
            {
                "classification": "exact-remote-swift-package-pin",
                "format_version": 1,
                **descriptor,
            }
        )
    )


def _entry_relative(digest: str) -> str:
    if re.fullmatch(r"[0-9a-f]{64}", digest) is None:
        raise MaterializationError("cache key is not a SHA-256 digest")
    return f"objects/sha256/{digest[:2]}/{digest}"


def _git_environment() -> dict[str, str]:
    environment = os.environ.copy()
    environment.update(
        {
            "GIT_CONFIG_GLOBAL": os.devnull,
            "GIT_CONFIG_NOSYSTEM": "1",
            "GIT_TERMINAL_PROMPT": "0",
        }
    )
    return environment


def _git(
    repository: Path | None,
    arguments: list[str],
    label: str,
    *,
    input_data: bytes | None = None,
) -> bytes:
    command = [
        "git",
        "-c",
        "core.autocrlf=false",
        "-c",
        "core.eol=lf",
        "-c",
        "core.hooksPath=/dev/null",
    ]
    if repository is not None:
        command.extend(["-C", os.fspath(repository)])
    command.extend(arguments)
    completed = subprocess.run(
        command,
        env=_git_environment(),
        input=input_data,
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
        check=False,
    )
    if completed.returncode:
        diagnostic = completed.stderr.decode("utf-8", errors="replace").strip()
        raise MaterializationError(
            f"{label} failed: {diagnostic or 'git exited nonzero'}"
        )
    return completed.stdout


def _single_line(data: bytes, label: str) -> str:
    try:
        value = data.decode("ascii").rstrip("\n")
    except UnicodeDecodeError as exc:
        raise MaterializationError(f"{label} is not ASCII") from exc
    if not value or "\n" in value or "\r" in value or "\0" in value:
        raise MaterializationError(f"{label} is not one line")
    return value


def _blob_object_id(data: bytes, expected_length: int) -> str:
    if expected_length == 40:
        digest = hashlib.sha1()
    elif expected_length == 64:
        digest = hashlib.sha256()
    else:
        raise MaterializationError("tracked blob uses an unsupported object format")
    digest.update(f"blob {len(data)}\0".encode("ascii"))
    digest.update(data)
    return digest.hexdigest()


def _symlink_target_within_repository(path: str, target: bytes) -> str:
    try:
        value = target.decode("utf-8")
    except UnicodeDecodeError as exc:
        raise MaterializationError(
            f"tracked symlink {path!r} target is not UTF-8"
        ) from exc
    if (
        not value
        or PurePosixPath(value).is_absolute()
        or "\\" in value
        or any(character in value for character in "\0\r\n")
    ):
        raise MaterializationError(
            f"tracked symlink {path!r} target is not a portable relative path"
        )

    resolved = list(PurePosixPath(path).parent.parts)
    for component in PurePosixPath(value).parts:
        if component in ("", "."):
            continue
        if component == "..":
            if not resolved:
                raise MaterializationError(
                    f"tracked symlink {path!r} escapes the repository"
                )
            resolved.pop()
        else:
            resolved.append(component)
    if resolved and resolved[0] == ".git":
        raise MaterializationError(
            f"tracked symlink {path!r} targets repository metadata"
        )
    return value


def _tracked_tree(
    repository: Path,
) -> tuple[
    str,
    int,
    str,
    list[dict[str, str]],
    list[dict[str, str]],
]:
    raw = _git(repository, ["ls-tree", "-r", "-z", "HEAD"], "tracked-tree inventory")
    entries = raw.split(b"\0")
    if entries and not entries[-1]:
        entries.pop()
    count = 0
    gitlinks: list[dict[str, str]] = []
    regular_files: list[tuple[str, str]] = []
    symlinks: list[dict[str, str]] = []
    portable_paths: set[str] = set()
    for index, record in enumerate(entries):
        try:
            metadata, raw_path = record.split(b"\t", 1)
            mode, kind, object_id = metadata.decode("ascii").split(" ")
            path = raw_path.decode("utf-8")
        except (ValueError, UnicodeDecodeError) as exc:
            raise MaterializationError(
                f"tracked-tree entry {index} is malformed"
            ) from exc
        if _OBJECT_ID.fullmatch(object_id) is None:
            raise MaterializationError(
                f"tracked-tree entry {path!r} has unsupported mode or kind {mode} {kind}"
            )
        portable_path = unicodedata.normalize("NFC", path.casefold())
        if portable_path in portable_paths:
            raise MaterializationError(
                f"tracked-tree repeats or portably aliases path {path!r}"
            )
        portable_paths.add(portable_path)
        if mode == "160000" and kind == "commit":
            physical = repository / path
            if physical.exists() or physical.is_symlink():
                try:
                    metadata = physical.lstat()
                except OSError as exc:
                    raise MaterializationError(
                        f"cannot inspect unmaterialized gitlink {path!r}: {exc}"
                    ) from exc
                if stat.S_ISLNK(metadata.st_mode) or not stat.S_ISDIR(metadata.st_mode):
                    raise MaterializationError(
                        f"unmaterialized gitlink is not an ordinary directory: {path}"
                    )
                try:
                    physical.resolve(strict=True).relative_to(repository)
                except ValueError as exc:
                    raise MaterializationError(
                        f"unmaterialized gitlink escapes the repository: {path}"
                    ) from exc
                try:
                    with os.scandir(physical) as children:
                        if next(children, None) is not None:
                            raise MaterializationError(
                                f"unmaterialized gitlink contains worktree content: {path}"
                            )
                except OSError as exc:
                    raise MaterializationError(
                        f"cannot scan unmaterialized gitlink {path!r}: {exc}"
                    ) from exc
            gitlinks.append({"commit": object_id, "path": path})
            continue
        if mode == "120000" and kind == "blob":
            physical = repository / path
            try:
                metadata = physical.lstat()
            except OSError as exc:
                raise MaterializationError(
                    f"cannot inspect tracked symlink {path!r}: {exc}"
                ) from exc
            if not stat.S_ISLNK(metadata.st_mode):
                raise MaterializationError(
                    f"tracked symlink is not a physical symlink: {path}"
                )
            try:
                actual_target = os.readlink(os.fsencode(physical))
            except OSError as exc:
                raise MaterializationError(
                    f"cannot read tracked symlink {path!r}: {exc}"
                ) from exc
            if _blob_object_id(actual_target, len(object_id)) != object_id:
                raise MaterializationError(
                    f"tracked symlink target differs from HEAD: {path}"
                )
            target = _symlink_target_within_repository(path, actual_target)
            symlinks.append(
                {"blob": object_id, "path": path, "target": target}
            )
            continue
        if mode not in {"100644", "100755"} or kind != "blob":
            raise MaterializationError(
                f"tracked-tree entry {path!r} has unsupported mode or kind {mode} {kind}"
            )
        physical = _ordinary_file(repository, path, f"tracked file {path!r}")
        regular_files.append((path, object_id))
        count += 1
    if regular_files:
        actual_objects = _git(
            repository,
            ["hash-object", "--no-filters", "--stdin-paths"],
            "hash tracked regular files",
            input_data=b"".join(
                path.encode("utf-8") + b"\n" for path, _ in regular_files
            ),
        ).splitlines()
        if len(actual_objects) != len(regular_files):
            raise MaterializationError(
                "tracked-file hashing returned an inconsistent result count"
            )
        for (path, expected), actual in zip(
            regular_files, actual_objects, strict=True
        ):
            try:
                actual_object = actual.decode("ascii")
            except UnicodeDecodeError as exc:
                raise MaterializationError(
                    f"tracked file {path!r} object ID is not ASCII"
                ) from exc
            if actual_object != expected:
                raise MaterializationError(
                    f"tracked file content differs from HEAD: {path}"
                )
    return (
        _sha256(raw),
        count,
        _sha256(
            b"\0".join(sorted(record.split(b"\t", 1)[1] for record in entries))
            + (b"\0" if entries else b"")
        ),
        gitlinks,
        symlinks,
    )


def _attestation(
    descriptor: Mapping[str, str], repository: Path, repository_relative: str
) -> dict[str, Any]:
    repository = _ordinary_absolute_directory(repository, "cached repository")
    metadata_root = _ordinary_absolute_directory(
        repository / ".git", "cached repository metadata"
    )
    try:
        metadata_root.relative_to(repository)
    except ValueError as exc:
        raise MaterializationError(
            "cached repository metadata escapes its worktree"
        ) from exc
    remotes = (
        _git(repository, ["remote"], "enumerate repository remotes")
        .decode("utf-8", errors="strict")
        .splitlines()
    )
    if remotes != ["origin"]:
        raise MaterializationError("repository must contain exactly one origin remote")
    origin = _single_line(
        _git(
            repository,
            ["remote", "get-url", "--all", "origin"],
            "read repository origin",
        ),
        "repository origin",
    )
    if origin != descriptor["url"]:
        raise MaterializationError(
            f"repository origin changed: expected {descriptor['url']!r}, got {origin!r}"
        )
    head = _single_line(
        _git(
            repository,
            ["rev-parse", "--verify", "HEAD^{commit}"],
            "resolve repository HEAD",
        ),
        "repository HEAD",
    )
    if head != descriptor["revision"]:
        raise MaterializationError(
            f"repository HEAD changed: expected {descriptor['revision']}, got {head}"
        )
    head_name = _single_line(
        _git(
            repository,
            ["rev-parse", "--abbrev-ref", "HEAD"],
            "inspect repository HEAD mode",
        ),
        "repository HEAD mode",
    )
    if head_name != "HEAD":
        raise MaterializationError("repository HEAD is not detached")
    shallow = _single_line(
        _git(
            repository,
            ["rev-parse", "--is-shallow-repository"],
            "inspect shallow state",
        ),
        "repository shallow state",
    )
    if shallow != "false":
        raise MaterializationError("repository is unexpectedly shallow")
    replacements = _git(
        repository,
        ["for-each-ref", "--format=%(refname)", "refs/replace"],
        "inspect replacement references",
    )
    if replacements:
        raise MaterializationError("repository contains replacement references")
    tree = _single_line(
        _git(
            repository,
            ["rev-parse", "--verify", "HEAD^{tree}"],
            "resolve repository tree",
        ),
        "repository tree",
    )
    object_format = _single_line(
        _git(
            repository,
            ["rev-parse", "--show-object-format"],
            "read repository object format",
        ),
        "repository object format",
    )
    expected_length = {"sha1": 40, "sha256": 64}.get(object_format)
    if (
        expected_length is None
        or len(head) != expected_length
        or len(tree) != expected_length
    ):
        raise MaterializationError(
            f"unsupported or inconsistent Git object format {object_format!r}"
        )
    status = _git(
        repository,
        ["status", "--porcelain=v1", "-z", "--untracked-files=all"],
        "inspect repository cleanliness",
    )
    if status:
        raise MaterializationError("repository worktree is not exactly clean")
    _git(
        repository,
        ["fsck", "--strict", "--no-reflogs", descriptor["revision"]],
        "verify repository object connectivity",
    )
    (
        listing_sha256,
        tracked_file_count,
        tracked_paths_sha256,
        gitlinks,
        symlinks,
    ) = _tracked_tree(repository)
    manifest = _ordinary_file(repository, "Package.swift", "remote Package.swift")
    manifest_data = manifest.read_bytes()
    return {
        "cache_key": f"sha256:{descriptor_digest(descriptor)}",
        "classification": "exact-remote-swift-package-materialization",
        "commit": head,
        "format_version": 3,
        "gitlink_count": len(gitlinks),
        "gitlinks": gitlinks,
        "identity": descriptor["identity"],
        "manifest": {
            "path": "Package.swift",
            "sha256": _sha256(manifest_data),
            "size": len(manifest_data),
        },
        "object_format": object_format,
        "origin": origin,
        "repository_path": repository_relative,
        "symlink_count": len(symlinks),
        "symlinks": symlinks,
        "tracked_file_count": tracked_file_count,
        "tracked_paths_sha256": tracked_paths_sha256,
        "tracked_tree_listing_sha256": listing_sha256,
        "tree": tree,
        "url": descriptor["url"],
    }


def _remove_staging(path: Path) -> None:
    if path.exists() or path.is_symlink():
        shutil.rmtree(path)


def verify_entry(
    cache_root: Path,
    descriptor: Mapping[str, str],
    expected: Mapping[str, Any] | None = None,
    *,
    allow_file_url: bool = False,
) -> dict[str, Any]:
    descriptor = _validated_descriptor(descriptor, allow_file_url=allow_file_url)
    root = _ordinary_absolute_directory(cache_root, "remote package cache root")
    digest = descriptor_digest(descriptor)
    relative = _entry_relative(digest)
    entry = root / relative
    try:
        entry = _ordinary_absolute_directory(entry, "remote package cache entry")
        entry.relative_to(root)
        repository = _ordinary_absolute_directory(
            entry / "repository", "cached repository"
        )
        repository.relative_to(entry)
        attestation_file = _ordinary_file(
            entry, "attestation.json", "cache attestation"
        )
    except (MaterializationError, ValueError) as exc:
        raise MaterializationError(
            f"stale or corrupt cache entry {digest}: {exc}"
        ) from exc
    try:
        actual = _attestation(descriptor, repository, f"{relative}/repository")
        stored = _mapping(
            _json_no_duplicates(attestation_file.read_bytes(), "cache attestation"),
            "cache attestation",
        )
    except (OSError, MaterializationError) as exc:
        raise MaterializationError(
            f"stale or corrupt cache entry {digest}: {exc}"
        ) from exc
    if canonical_json(stored) != canonical_json(actual):
        raise MaterializationError(
            f"stale or corrupt cache entry {digest}: attestation changed"
        )
    if expected is not None and canonical_json(expected) != canonical_json(actual):
        raise MaterializationError(
            f"stale or corrupt cache entry {digest}: expected identity changed"
        )
    return actual


def materialize_entry(
    cache_root: Path,
    descriptor: Mapping[str, str],
    *,
    allow_file_url: bool = False,
) -> dict[str, Any]:
    descriptor = _validated_descriptor(descriptor, allow_file_url=allow_file_url)
    root = _ordinary_absolute_directory(
        cache_root, "remote package cache root", create=True
    )
    digest = descriptor_digest(descriptor)
    entry = root / _entry_relative(digest)
    if entry.exists() or entry.is_symlink():
        return verify_entry(root, descriptor, allow_file_url=allow_file_url)
    objects = _ensure_child_directory(root, "objects", "remote package object root")
    algorithm = _ensure_child_directory(
        objects, "sha256", "remote package object algorithm root"
    )
    parent = _ensure_child_directory(
        algorithm, digest[:2], "remote package cache object parent"
    )
    staging_parent = _ensure_child_directory(
        root, ".staging", "remote package staging root"
    )
    stage = staging_parent / f"{digest}.{os.getpid()}.{secrets.token_hex(8)}"
    stage.mkdir(mode=0o700)
    try:
        repository = stage / "repository"
        clone_arguments = [
            "clone",
            "--no-checkout",
            "--no-tags",
            "--origin",
            "origin",
            "--config",
            "core.autocrlf=false",
            "--config",
            "core.eol=lf",
            "--config",
            "core.symlinks=true",
            "--",
            descriptor["url"],
            os.fspath(repository),
        ]
        _git(None, clone_arguments, f"clone exact package {descriptor['identity']!r}")
        try:
            _git(
                repository,
                ["cat-file", "-e", f"{descriptor['revision']}^{{commit}}"],
                "locate pinned commit",
            )
        except MaterializationError:
            _git(
                repository,
                ["fetch", "--no-tags", "origin", descriptor["revision"]],
                "fetch exact pinned commit",
            )
        _git(
            repository,
            ["checkout", "--detach", "--force", descriptor["revision"], "--"],
            "checkout exact pinned commit",
        )
        relative = _entry_relative(digest)
        actual = _attestation(descriptor, repository, f"{relative}/repository")
        (stage / "attestation.json").write_bytes(canonical_json(actual))
        try:
            stage.rename(entry)
        except FileExistsError:
            _remove_staging(stage)
            return verify_entry(root, descriptor, allow_file_url=allow_file_url)
        return verify_entry(
            root,
            descriptor,
            actual,
            allow_file_url=allow_file_url,
        )
    except BaseException:
        _remove_staging(stage)
        raise


def _graph_descriptors(
    graph: Mapping[str, Any], allow_file_url: bool
) -> list[dict[str, str]]:
    external = _list(graph.get("external_packages"), "graph external_packages")
    direct = [
        descriptor_for(
            _mapping(raw, f"graph external_packages[{index}]"),
            allow_file_url=allow_file_url,
        )
        for index, raw in enumerate(external)
    ]
    if len({descriptor_digest(item) for item in direct}) != len(direct):
        raise MaterializationError("graph repeats an exact remote package descriptor")

    pins = _list(graph.get("resolution_pins", []), "graph resolution_pins")
    closure: list[dict[str, str]] = []
    for index, raw in enumerate(pins):
        pin = _mapping(raw, f"graph resolution_pins[{index}]")
        if pin.get("kind") != "remoteSourceControl":
            raise MaterializationError(
                f"graph resolution_pins[{index}] is not remote source control"
            )
        closure.append(
            descriptor_for(
                {
                    "identity": pin.get("identity"),
                    "url": pin.get("location"),
                    "pin": {
                        "location": pin.get("location"),
                        "revision": pin.get("revision"),
                    },
                },
                allow_file_url=allow_file_url,
            )
        )

    by_identity: dict[str, dict[str, str]] = {}
    by_url: dict[str, str] = {}
    for descriptor in [*direct, *closure]:
        identity = descriptor["identity"]
        previous = by_identity.get(identity)
        if previous is not None and previous != descriptor:
            raise MaterializationError(
                f"graph binds remote package identity {identity!r} more than once"
            )
        previous_identity = by_url.get(descriptor["url"])
        if previous_identity is not None and previous_identity != identity:
            raise MaterializationError(
                f"graph aliases one remote package URL as {previous_identity!r} and {identity!r}"
            )
        by_identity[identity] = descriptor
        by_url[descriptor["url"]] = identity
    result = list(by_identity.values())
    result.sort(key=lambda item: (item["identity"].encode(), item["url"].encode()))
    return result


def materialize_graph(
    graph: Mapping[str, Any],
    cache_root: Path,
    *,
    allow_file_url: bool = False,
) -> dict[str, Any]:
    graph_bytes = canonical_json(graph)
    packages = [
        materialize_entry(cache_root, descriptor, allow_file_url=allow_file_url)
        for descriptor in _graph_descriptors(graph, allow_file_url)
    ]
    result = {
        "classification": "exact-remote-swift-package-materialization-set",
        "format_version": 1,
        "packages": packages,
        "source_graph_sha256": _sha256(graph_bytes),
    }
    verify_set(result, graph, cache_root, allow_file_url=allow_file_url)
    return result


def verify_set(
    materializations: Mapping[str, Any],
    graph: Mapping[str, Any],
    cache_root: Path,
    *,
    allow_file_url: bool = False,
) -> dict[str, dict[str, Any]]:
    if (
        materializations.get("classification")
        != "exact-remote-swift-package-materialization-set"
        or materializations.get("format_version") != 1
    ):
        raise MaterializationError(
            "input is not a supported remote materialization set"
        )
    if materializations.get("source_graph_sha256") != _sha256(canonical_json(graph)):
        raise MaterializationError(
            "remote materialization set belongs to a different source graph"
        )
    expected_descriptors = _graph_descriptors(graph, allow_file_url)
    packages = _list(materializations.get("packages"), "materialization packages")
    if len(packages) != len(expected_descriptors):
        raise MaterializationError(
            "remote materialization set has the wrong package count"
        )
    result: dict[str, dict[str, Any]] = {}
    for index, (descriptor, raw) in enumerate(
        zip(expected_descriptors, packages, strict=True)
    ):
        expected = _mapping(raw, f"materialization packages[{index}]")
        actual = verify_entry(
            cache_root,
            descriptor,
            expected,
            allow_file_url=allow_file_url,
        )
        identity = descriptor["identity"]
        if identity in result:
            raise MaterializationError(
                f"remote materialization repeats identity {identity!r}"
            )
        result[identity] = actual
    return result


def repository_for(cache_root: Path, materialization: Mapping[str, Any]) -> Path:
    root = _ordinary_absolute_directory(cache_root, "remote package cache root")
    relative = _string(
        materialization.get("repository_path"), "materialization repository_path"
    )
    path = root
    for component in _safe_relative(relative, "materialization repository_path").parts:
        path /= component
        metadata = path.lstat()
        if stat.S_ISLNK(metadata.st_mode):
            raise MaterializationError(
                "materialization repository_path traverses a symlink"
            )
    return _ordinary_absolute_directory(path, "materialized repository")


def _new_output_path(value: Path, source_root: Path, label: str) -> Path:
    if not value.is_absolute():
        raise MaterializationError(f"{label} must be absolute")
    parent = _ordinary_absolute_directory(value.parent, f"{label} parent")
    output = parent / value.name
    try:
        output.resolve(strict=False).relative_to(source_root)
    except ValueError:
        pass
    else:
        raise MaterializationError(
            f"{label} must be outside the application source root"
        )
    if output.exists() or output.is_symlink():
        raise MaterializationError(f"{label} already exists: {output}")
    return output


def _parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(description=__doc__)
    commands = parser.add_subparsers(dest="command", required=True)
    for name in ("materialize", "verify"):
        command = commands.add_parser(name)
        command.add_argument("graph", type=Path)
        command.add_argument("--source-root", required=True, type=Path)
        command.add_argument("--cache-root", required=True, type=Path)
        command.add_argument("--materializations", required=True, type=Path)
        command.add_argument("--allow-file-url-for-tests", action="store_true")
    return parser


def main(argv: list[str] | None = None) -> int:
    arguments = _parser().parse_args(argv)
    try:
        import local_package_graph

        graph = _mapping(
            _json_no_duplicates(arguments.graph.read_bytes(), "package graph"),
            "package graph",
        )
        local_package_graph.verify(graph, arguments.source_root)
        source_root = _ordinary_absolute_directory(
            arguments.source_root, "application source root"
        )
        cache_root = arguments.cache_root.resolve(strict=False)
        try:
            cache_root.relative_to(source_root)
        except ValueError:
            pass
        else:
            raise MaterializationError(
                "remote package cache root must be outside the application source root"
            )
        if arguments.command == "materialize":
            output = _new_output_path(
                arguments.materializations,
                source_root,
                "remote materialization output",
            )
            result = materialize_graph(
                graph,
                arguments.cache_root,
                allow_file_url=arguments.allow_file_url_for_tests,
            )
            output.write_bytes(canonical_json(result))
            print(
                "REMOTE_PACKAGE_MATERIALIZATION_OK "
                f"packages={len(result['packages'])} "
                f"sha256={_sha256(canonical_json(result))}"
            )
        else:
            result = _mapping(
                _json_no_duplicates(
                    arguments.materializations.read_bytes(), "materializations"
                ),
                "materializations",
            )
            verified = verify_set(
                result,
                graph,
                arguments.cache_root,
                allow_file_url=arguments.allow_file_url_for_tests,
            )
            print(f"REMOTE_PACKAGE_MATERIALIZATION_VERIFIED packages={len(verified)}")
    except (OSError, MaterializationError, subprocess.SubprocessError) as exc:
        print(f"remote-package-materializer: {exc}", file=sys.stderr)
        return 1
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
