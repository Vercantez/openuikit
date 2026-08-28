#!/usr/bin/env python3
"""Attest and emit the exact Focus iOS Blockzilla Swift source subject.

The Xcode project is deliberately not partially parsed here.  The reviewed
project bytes, native-target/build-phase IDs, and all 131 Swift references are
pinned in ``focus-main-sources.json``.  This validator refuses any change to
that subject and emits only the 129 references that exist before Xcode's two
code-generation phases run.

The compiler manifest is NUL-delimited, not line-delimited.  A later caller can
consume it with ``read -d ''`` without splitting paths that contain spaces (or
depending on newline quoting).  The JSON audit records the two expected
generated-but-missing references separately.
"""

from __future__ import annotations

import hashlib
import json
import os
from pathlib import Path, PurePosixPath
import stat
import subprocess
import sys
from typing import Any


APPROVED_COMMIT = "a2832521c1daa0c23419c73705ae043ed60c9791"
APPROVED_PROJECT = {
    "path": "Blockzilla.xcodeproj/project.pbxproj",
    "sha256": "5a9c088023d20de3e41e6283ab4bde12338ae54da3f2a57b1e6743434b74e4ac",
    "size": 409402,
}
APPROVED_TARGET = {
    "name": "Blockzilla",
    "native_target_id": "E4BF2DD21BACE8CA00DA9D68",
    "sources_build_phase_id": "E4BF2DCF1BACE8CA00DA9D68",
    "swift_reference_count": 131,
}
APPROVED_SOURCE_ROOTS = ("Blockzilla", "Deferred", "Shared")
APPROVED_GENERATED_MISSING = (
    "Blockzilla/Generated/AppNimbus.swift",
    "Blockzilla/Generated/Metrics.swift",
)
APPROVED_PRESENT_COUNT = 129
APPROVED_PRESENT_DIGEST = (
    "8327bf020dc5171167d687a6bf3f107ec2b123f5dc3658236ddbfea894b8123a"
)

POLICY_KEYS = {
    "schema",
    "repository_commit",
    "project",
    "target",
    "source_roots",
    "present_sources",
    "expected_generated_missing",
    "present_source_digest",
}
PROJECT_KEYS = {"path", "sha256", "size"}
TARGET_KEYS = {
    "name",
    "native_target_id",
    "sources_build_phase_id",
    "swift_reference_count",
}


class PolicyError(RuntimeError):
    """The requested compiler subject is not exactly the reviewed subject."""


def sha256(data: bytes) -> str:
    return hashlib.sha256(data).hexdigest()


def git(repo: Path, *args: str) -> bytes:
    try:
        return subprocess.check_output(
            ["git", "-C", str(repo), *args], stderr=subprocess.STDOUT
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


def _validate_relative_source(value: Any, label: str) -> str:
    if not isinstance(value, str) or not value:
        raise PolicyError(f"{label} must be a non-empty string")
    if any(character in value for character in ("\0", "\n", "\r")):
        raise PolicyError(f"{label} contains a forbidden control character")
    path = PurePosixPath(value)
    if path.is_absolute() or path.as_posix() != value:
        raise PolicyError(f"{label} is not a normalized relative POSIX path: {value!r}")
    if any(part in ("", ".", "..") for part in path.parts):
        raise PolicyError(f"{label} escapes or aliases the source root: {value!r}")
    if path.suffix != ".swift":
        raise PolicyError(f"{label} is not a Swift source: {value!r}")
    if not path.parts or path.parts[0] not in APPROVED_SOURCE_ROOTS:
        raise PolicyError(f"{label} is outside the approved source roots: {value!r}")
    return value


def load_policy(policy_path: Path) -> tuple[bytes, dict[str, Any]]:
    try:
        policy_bytes = policy_path.read_bytes()
        policy = json.loads(policy_bytes)
    except (OSError, json.JSONDecodeError) as exc:
        raise PolicyError(f"cannot read policy {policy_path}: {exc}") from exc

    policy = _require_exact_keys(policy, POLICY_KEYS, "policy")
    if type(policy["schema"]) is not int or policy["schema"] != 1:
        raise PolicyError(f"unsupported policy schema: {policy['schema']!r}")
    if policy["repository_commit"] != APPROVED_COMMIT:
        raise PolicyError("policy repository commit is not the approved Focus pin")

    project = _require_exact_keys(policy["project"], PROJECT_KEYS, "project")
    if project != APPROVED_PROJECT:
        raise PolicyError("project attestation differs from the approved bytes/hash")

    target = _require_exact_keys(policy["target"], TARGET_KEYS, "target")
    if target != APPROVED_TARGET:
        raise PolicyError("target/build-phase identity differs from the approved target")

    roots = policy["source_roots"]
    if roots != list(APPROVED_SOURCE_ROOTS):
        raise PolicyError(
            f"source roots must remain exactly {list(APPROVED_SOURCE_ROOTS)}"
        )

    present = policy["present_sources"]
    if not isinstance(present, list):
        raise PolicyError("present_sources must be a list")
    present = [
        _validate_relative_source(value, f"present_sources[{index}]")
        for index, value in enumerate(present)
    ]
    if len(present) != APPROVED_PRESENT_COUNT:
        raise PolicyError(
            f"present source count changed: expected {APPROVED_PRESENT_COUNT}, "
            f"got {len(present)}"
        )
    if present != sorted(present) or len(set(present)) != len(present):
        raise PolicyError("present_sources must be unique and bytewise sorted")

    missing = policy["expected_generated_missing"]
    if not isinstance(missing, list):
        raise PolicyError("expected_generated_missing must be a list")
    missing = [
        _validate_relative_source(value, f"expected_generated_missing[{index}]")
        for index, value in enumerate(missing)
    ]
    if tuple(missing) != APPROVED_GENERATED_MISSING:
        raise PolicyError(
            "generated-missing scope changed: approved exactly "
            f"{list(APPROVED_GENERATED_MISSING)}, got {missing}"
        )
    if set(present) & set(missing):
        raise PolicyError("present and generated-missing source sets overlap")
    if len(present) + len(missing) != APPROVED_TARGET["swift_reference_count"]:
        raise PolicyError("131-source target denominator does not reconcile")

    digest = policy["present_source_digest"]
    if digest != APPROVED_PRESENT_DIGEST:
        raise PolicyError("present source digest differs from the approved digest")
    return policy_bytes, policy


def _reject_symlink_components(repo: Path, relative: str) -> None:
    current = repo
    for part in PurePosixPath(relative).parts:
        current = current / part
        if not os.path.lexists(current):
            return
        try:
            mode = os.lstat(current).st_mode
        except OSError as exc:
            raise PolicyError(f"cannot inspect path component {current}: {exc}") from exc
        if stat.S_ISLNK(mode):
            raise PolicyError(f"approved subject path must not be a symlink: {current}")


def _read_regular_file(path: Path, label: str) -> bytes:
    if path.is_symlink():
        raise PolicyError(f"{label} must not be a symlink: {path}")
    flags = os.O_RDONLY | getattr(os, "O_NOFOLLOW", 0)
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
        if (
            before.st_dev,
            before.st_ino,
            before.st_size,
            before.st_mtime_ns,
        ) != (
            after.st_dev,
            after.st_ino,
            after.st_size,
            after.st_mtime_ns,
        ):
            raise PolicyError(f"{label} changed while it was being read: {path}")
        return b"".join(chunks)
    finally:
        os.close(descriptor)


def discover_sources(repo: Path, roots: list[str]) -> list[str]:
    discovered: list[str] = []

    def walk(directory: Path) -> None:
        try:
            with os.scandir(directory) as iterator:
                entries = sorted(iterator, key=lambda entry: entry.name)
        except OSError as exc:
            raise PolicyError(f"cannot scan source directory {directory}: {exc}") from exc
        for entry in entries:
            entry_path = Path(entry.path)
            if entry.is_symlink():
                raise PolicyError(f"source tree must not contain symlinks: {entry_path}")
            if entry.is_dir(follow_symlinks=False):
                walk(entry_path)
            elif entry.name.endswith(".swift"):
                if not entry.is_file(follow_symlinks=False):
                    raise PolicyError(f"Swift source is not a regular file: {entry_path}")
                discovered.append(entry_path.relative_to(repo).as_posix())

    for root in roots:
        _reject_symlink_components(repo, root)
        root_path = repo / root
        if not root_path.is_dir():
            raise PolicyError(f"approved source root is not a directory: {root_path}")
        walk(root_path)
    return sorted(discovered)


def source_attestation(repo: Path, paths: list[str]) -> tuple[str, dict[str, str]]:
    aggregate = hashlib.sha256()
    hashes: dict[str, str] = {}
    for relative in paths:
        _reject_symlink_components(repo, relative)
        data = _read_regular_file(repo / relative, "Swift source")
        hashes[relative] = sha256(data)
        aggregate.update(relative.encode("utf-8"))
        aggregate.update(b"\0")
        aggregate.update(data)
        aggregate.update(b"\0")
    return aggregate.hexdigest(), hashes


def _git_tracked_swift_sources(repo: Path, roots: list[str]) -> list[str]:
    raw = git(repo, "ls-files", "-z", "--", *roots)
    try:
        paths = [
            entry.decode("utf-8")
            for entry in raw.split(b"\0")
            if entry and entry.endswith(b".swift")
        ]
    except UnicodeDecodeError as exc:
        raise PolicyError("tracked Swift path is not valid UTF-8") from exc
    return sorted(paths)


def _write_new(path: Path, data: bytes) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    flags = os.O_WRONLY | os.O_CREAT | os.O_EXCL
    try:
        descriptor = os.open(path, flags, 0o600)
    except OSError as exc:
        raise PolicyError(f"cannot create output {path}: {exc}") from exc
    try:
        view = memoryview(data)
        while view:
            written = os.write(descriptor, view)
            if written == 0:
                raise OSError("zero-byte write")
            view = view[written:]
    except OSError as exc:
        try:
            path.unlink()
        except OSError:
            pass
        raise PolicyError(f"cannot write output {path}: {exc}") from exc
    finally:
        os.close(descriptor)


def prepare(
    repo_arg: str, policy_arg: str, manifest_arg: str, audit_arg: str
) -> dict[str, Any]:
    repo_input = Path(repo_arg).expanduser()
    if repo_input.is_symlink():
        raise PolicyError(f"Focus repository must not be a symlink: {repo_input}")
    try:
        repo = repo_input.resolve(strict=True)
    except OSError as exc:
        raise PolicyError(f"cannot resolve Focus repository {repo_input}: {exc}") from exc
    if not repo.is_dir():
        raise PolicyError(f"Focus repository is not a directory: {repo}")

    policy_path = Path(policy_arg).expanduser().resolve()
    manifest_path = Path(manifest_arg).expanduser().absolute()
    audit_path = Path(audit_arg).expanduser().absolute()
    if manifest_path == audit_path:
        raise PolicyError("manifest and audit outputs must be different files")
    for output in (manifest_path, audit_path):
        if os.path.lexists(output):
            raise PolicyError(f"refusing to overwrite existing output: {output}")

    policy_bytes, policy = load_policy(policy_path)
    actual_commit = git(repo, "rev-parse", "--verify", "HEAD^{commit}").decode(
        "ascii", errors="strict"
    ).strip()
    if actual_commit != APPROVED_COMMIT:
        raise PolicyError(
            f"Focus pin changed: expected {APPROVED_COMMIT}, got {actual_commit}"
        )

    project_relative = policy["project"]["path"]
    _reject_symlink_components(repo, project_relative)
    project_path = repo / project_relative
    project_bytes_before = _read_regular_file(project_path, "Xcode project")
    if len(project_bytes_before) != policy["project"]["size"]:
        raise PolicyError(
            "Xcode project size changed: expected "
            f"{policy['project']['size']}, got {len(project_bytes_before)}"
        )
    actual_project_hash = sha256(project_bytes_before)
    if actual_project_hash != policy["project"]["sha256"]:
        raise PolicyError(
            "Xcode project hash changed: expected "
            f"{policy['project']['sha256']}, got {actual_project_hash}"
        )

    expected_present: list[str] = policy["present_sources"]
    roots: list[str] = policy["source_roots"]
    disk_sources = discover_sources(repo, roots)
    if disk_sources != expected_present:
        expected = set(expected_present)
        actual = set(disk_sources)
        raise PolicyError(
            "Blockzilla Swift source inventory changed; "
            f"expected-only={sorted(expected - actual)}, "
            f"disk-only={sorted(actual - expected)}"
        )

    tracked_sources = _git_tracked_swift_sources(repo, roots)
    if tracked_sources != expected_present:
        expected = set(expected_present)
        actual = set(tracked_sources)
        raise PolicyError(
            "tracked Blockzilla Swift source inventory changed; "
            f"expected-only={sorted(expected - actual)}, "
            f"tracked-only={sorted(actual - expected)}"
        )

    for relative in policy["expected_generated_missing"]:
        _reject_symlink_components(repo, relative)
        if os.path.lexists(repo / relative):
            raise PolicyError(
                f"expected generated source is unexpectedly present: {relative}"
            )

    actual_source_digest, source_hashes = source_attestation(repo, expected_present)
    if actual_source_digest != policy["present_source_digest"]:
        raise PolicyError(
            "Blockzilla Swift source bytes changed: expected digest "
            f"{policy['present_source_digest']}, got {actual_source_digest}"
        )

    # Bracket the read so a moving worktree cannot receive a successful audit.
    if discover_sources(repo, roots) != disk_sources:
        raise PolicyError("Blockzilla Swift inventory changed during attestation")
    second_digest, second_hashes = source_attestation(repo, expected_present)
    if second_digest != actual_source_digest or second_hashes != source_hashes:
        raise PolicyError("Blockzilla Swift source bytes changed during attestation")
    project_bytes_after = _read_regular_file(project_path, "Xcode project")
    if project_bytes_after != project_bytes_before:
        raise PolicyError("Xcode project bytes changed during attestation")
    final_commit = git(repo, "rev-parse", "--verify", "HEAD^{commit}").decode(
        "ascii", errors="strict"
    ).strip()
    if final_commit != actual_commit:
        raise PolicyError("Focus HEAD changed during attestation")

    manifest_bytes = b"".join(
        str(repo / relative).encode("utf-8") + b"\0"
        for relative in expected_present
    )
    audit: dict[str, Any] = {
        "schema": 1,
        "repository": str(repo),
        "repository_commit": actual_commit,
        "policy_sha256": sha256(policy_bytes),
        "project": {
            **policy["project"],
            "actual_sha256": actual_project_hash,
        },
        "target": policy["target"],
        "source_roots": roots,
        "target_swift_reference_count": policy["target"]["swift_reference_count"],
        "present_source_count": len(expected_present),
        "generated_missing_source_count": len(
            policy["expected_generated_missing"]
        ),
        "present_source_digest": actual_source_digest,
        "manifest_format": "nul-delimited-utf8-absolute-paths",
        "manifest_sha256": sha256(manifest_bytes),
        "present_sources": [
            {"path": relative, "sha256": source_hashes[relative]}
            for relative in expected_present
        ],
        "expected_generated_missing": policy["expected_generated_missing"],
    }

    audit_bytes = (json.dumps(audit, indent=2, sort_keys=True) + "\n").encode(
        "utf-8"
    )
    created: list[Path] = []
    try:
        _write_new(manifest_path, manifest_bytes)
        created.append(manifest_path)
        _write_new(audit_path, audit_bytes)
        created.append(audit_path)
    except Exception:
        for path in created:
            try:
                path.unlink()
            except OSError:
                pass
        raise

    print(f"  Focus commit: {actual_commit}")
    print(
        "  Blockzilla Swift references: "
        f"{policy['target']['swift_reference_count']} = "
        f"{len(expected_present)} present + "
        f"{len(policy['expected_generated_missing'])} generated-missing"
    )
    for relative in policy["expected_generated_missing"]:
        print(f"  EXPECTED GENERATED-MISSING {relative}")
    print(f"  project sha256: {actual_project_hash}")
    print(f"  present source digest: {actual_source_digest}")
    print(f"  NUL manifest: {manifest_path}")
    print(f"  audit: {audit_path}")
    return audit


def main(argv: list[str]) -> int:
    if len(argv) != 5:
        print(
            "usage: focus_main_sources.py REPO POLICY NUL_MANIFEST AUDIT_JSON",
            file=sys.stderr,
        )
        return 2
    try:
        prepare(argv[1], argv[2], argv[3], argv[4])
    except (PolicyError, UnicodeError) as exc:
        print(f"REFUSED: {exc}", file=sys.stderr)
        return 1
    return 0


if __name__ == "__main__":
    raise SystemExit(main(sys.argv))
