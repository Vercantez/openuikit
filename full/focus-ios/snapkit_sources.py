#!/usr/bin/env python3
"""Prepare and attest the exact SnapKit source set used by the focus-ios census.

This is a vendoring rule, not a source transformer.  It accepts one reviewed,
diagnostic-only exclusion and refuses if the Focus workspace lock, repository
pin, source inventory, source digest, excluded bytes, or approved exclusion
scope changes.  It writes both the exact compiler input list and a deterministic
JSON attestation of every source hash.
"""

from __future__ import annotations

import hashlib
import json
import os
from pathlib import Path
import stat
import subprocess
import sys
from typing import Any


APPROVED_EXCLUSIONS = ("Sources/Debugging.swift",)
APPROVED_LOCK_PATH = (
    "Blockzilla.xcodeproj/project.xcworkspace/xcshareddata/swiftpm/"
    "Package.resolved"
)
APPROVED_PACKAGE = "SnapKit"
APPROVED_REPOSITORY_URL = "https://github.com/SnapKit/SnapKit"
POLICY_KEYS = {
    "schema",
    "repository_commit",
    "source_root",
    "all_source_digest",
    "included_source_digest",
    "workspace_lock",
    "exclusions",
}
LOCK_KEYS = {
    "focus_repository_commit",
    "path",
    "sha256",
    "package",
    "repository_url",
    "revision",
    "version",
}
EXCLUSION_KEYS = {"path", "sha256", "reason"}


class PolicyError(RuntimeError):
    pass


def sha256(data: bytes) -> str:
    return hashlib.sha256(data).hexdigest()


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
        output = getattr(exc, "output", b"")
        detail = output.decode("utf-8", errors="replace").strip()
        raise PolicyError(f"git {' '.join(args)} failed: {detail}") from exc


def resolve_directory(path_arg: str, label: str) -> Path:
    path = Path(path_arg).expanduser()
    if path.is_symlink():
        raise PolicyError(f"{label} must not be a symlink: {path}")
    try:
        resolved = path.resolve(strict=True)
    except OSError as exc:
        raise PolicyError(f"cannot resolve {label} {path}: {exc}") from exc
    if not resolved.is_dir():
        raise PolicyError(f"{label} is not a directory: {resolved}")
    return resolved


def reject_symlink_components(root: Path, relative: str, label: str) -> None:
    current = root
    for component in Path(relative).parts:
        current /= component
        if not os.path.lexists(current):
            return
        try:
            mode = os.lstat(current).st_mode
        except OSError as exc:
            raise PolicyError(f"cannot inspect {label} path {current}: {exc}") from exc
        if stat.S_ISLNK(mode):
            raise PolicyError(f"{label} path must not contain symlinks: {current}")


def read_regular(path: Path, label: str) -> bytes:
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
        before_identity = (
            before.st_dev,
            before.st_ino,
            before.st_size,
            before.st_mtime_ns,
        )
        after_identity = (
            after.st_dev,
            after.st_ino,
            after.st_size,
            after.st_mtime_ns,
        )
        if before_identity != after_identity:
            raise PolicyError(f"{label} changed while being read: {path}")
        return b"".join(chunks)
    finally:
        os.close(descriptor)


def digest_sources(repo: Path, paths: list[str]) -> str:
    digest = hashlib.sha256()
    for rel in paths:
        digest.update(rel.encode("utf-8"))
        digest.update(b"\0")
        digest.update(read_regular(repo / rel, "SnapKit source"))
        digest.update(b"\0")
    return digest.hexdigest()


def verify_workspace_lock(
    focus_repo: Path, lock_policy: Any, repository_commit: str
) -> dict[str, Any]:
    if not isinstance(lock_policy, dict) or set(lock_policy) != LOCK_KEYS:
        raise PolicyError(f"workspace_lock keys must be exactly {sorted(LOCK_KEYS)}")
    for key in LOCK_KEYS:
        if not isinstance(lock_policy[key], str):
            raise PolicyError(f"workspace_lock.{key} must be a string")
    if lock_policy["path"] != APPROVED_LOCK_PATH:
        raise PolicyError(f"workspace lock path must remain exactly {APPROVED_LOCK_PATH}")
    if lock_policy["package"] != APPROVED_PACKAGE:
        raise PolicyError(f"workspace lock package must remain exactly {APPROVED_PACKAGE}")
    if lock_policy["repository_url"] != APPROVED_REPOSITORY_URL:
        raise PolicyError(
            "workspace lock repository_url must remain exactly "
            f"{APPROVED_REPOSITORY_URL}"
        )
    if lock_policy["revision"] != repository_commit:
        raise PolicyError(
            "SnapKit policy commit does not match workspace lock revision: "
            f"{repository_commit} != {lock_policy['revision']}"
        )

    actual_focus_commit = git(
        focus_repo, "rev-parse", "--verify", "HEAD^{commit}"
    ).decode().strip()
    if actual_focus_commit != lock_policy["focus_repository_commit"]:
        raise PolicyError(
            "Focus pin changed: expected "
            f"{lock_policy['focus_repository_commit']}, got {actual_focus_commit}"
        )

    relative = lock_policy["path"]
    reject_symlink_components(focus_repo, relative, "workspace lock")
    lock_path = focus_repo / relative
    lock_bytes = read_regular(lock_path, "workspace lock")
    actual_hash = sha256(lock_bytes)
    if actual_hash != lock_policy["sha256"]:
        raise PolicyError(
            "workspace lock hash changed: expected "
            f"{lock_policy['sha256']}, got {actual_hash}"
        )

    tree_record = git(
        focus_repo, "ls-tree", "-z", "HEAD", "--", relative
    ).rstrip(b"\0")
    tree_fields = tree_record.split(None, 3)
    if len(tree_fields) != 4 or tree_fields[0:2] != [b"100644", b"blob"]:
        raise PolicyError(
            "workspace lock must be one tracked non-executable blob at pinned HEAD"
        )
    blob_id = tree_fields[2].decode("ascii", errors="strict")
    committed_bytes = git(focus_repo, "show", f"HEAD:./{relative}")
    if committed_bytes != lock_bytes:
        raise PolicyError("workspace lock worktree bytes differ from pinned HEAD")
    lock_dirty = git(
        focus_repo,
        "status",
        "--porcelain=v1",
        "--untracked-files=all",
        "--",
        relative,
    ).decode("utf-8", errors="replace").strip()
    if lock_dirty:
        raise PolicyError(f"workspace lock index/worktree is not clean:\n{lock_dirty}")

    try:
        resolution = json.loads(lock_bytes)
    except json.JSONDecodeError as exc:
        raise PolicyError(f"workspace lock is not valid JSON: {exc}") from exc
    if (
        not isinstance(resolution, dict)
        or set(resolution) != {"object", "version"}
        or resolution["version"] != 1
        or not isinstance(resolution["object"], dict)
        or set(resolution["object"]) != {"pins"}
        or not isinstance(resolution["object"]["pins"], list)
    ):
        raise PolicyError("workspace lock must retain the reviewed version-1 shape")
    matches = [
        pin
        for pin in resolution["object"]["pins"]
        if isinstance(pin, dict) and pin.get("package") == lock_policy["package"]
    ]
    if len(matches) != 1:
        raise PolicyError(
            f"workspace lock must contain exactly one {lock_policy['package']} pin"
        )
    expected_pin = {
        "package": lock_policy["package"],
        "repositoryURL": lock_policy["repository_url"],
        "state": {
            "branch": None,
            "revision": lock_policy["revision"],
            "version": lock_policy["version"],
        },
    }
    if matches[0] != expected_pin:
        raise PolicyError(
            f"workspace lock {lock_policy['package']} pin changed: "
            f"expected {expected_pin!r}, got {matches[0]!r}"
        )

    return {
        "focus_repository": str(focus_repo),
        "focus_repository_commit": actual_focus_commit,
        "path": relative,
        "sha256": actual_hash,
        "git_blob": blob_id,
        "package": lock_policy["package"],
        "repository_url": lock_policy["repository_url"],
        "revision": lock_policy["revision"],
        "version": lock_policy["version"],
    }


def prepare(
    repo_arg: str,
    focus_repo_arg: str,
    policy_arg: str,
    list_arg: str,
    audit_arg: str,
) -> dict[str, Any]:
    repo = resolve_directory(repo_arg, "SnapKit repository")
    focus_repo = resolve_directory(focus_repo_arg, "Focus repository")
    policy_path = Path(policy_arg).resolve()
    list_path = Path(list_arg).resolve()
    audit_path = Path(audit_arg).resolve()

    try:
        policy_bytes = read_regular(policy_path, "SnapKit policy")
        policy = json.loads(policy_bytes)
    except (PolicyError, json.JSONDecodeError) as exc:
        raise PolicyError(f"cannot read policy {policy_path}: {exc}") from exc

    if not isinstance(policy, dict) or set(policy) != POLICY_KEYS:
        raise PolicyError(f"policy keys must be exactly {sorted(POLICY_KEYS)}")
    if policy["schema"] != 2:
        raise PolicyError(f"unsupported policy schema: {policy['schema']!r}")
    if policy["source_root"] != "Sources":
        raise PolicyError("source_root must remain exactly 'Sources'")
    if not isinstance(policy["repository_commit"], str):
        raise PolicyError("repository_commit must be a string")
    for key in ("all_source_digest", "included_source_digest"):
        if not isinstance(policy[key], str):
            raise PolicyError(f"{key} must be a string")

    lock_attestation = verify_workspace_lock(
        focus_repo, policy["workspace_lock"], policy["repository_commit"]
    )

    exclusions = policy["exclusions"]
    if not isinstance(exclusions, list):
        raise PolicyError("exclusions must be a list")
    for exclusion in exclusions:
        if not isinstance(exclusion, dict) or set(exclusion) != EXCLUSION_KEYS:
            raise PolicyError(
                f"each exclusion must have exactly {sorted(EXCLUSION_KEYS)}"
            )
    excluded_paths = tuple(exclusion["path"] for exclusion in exclusions)
    if excluded_paths != APPROVED_EXCLUSIONS:
        raise PolicyError(
            "exclusion scope changed: approved exactly "
            f"{list(APPROVED_EXCLUSIONS)}, got {list(excluded_paths)}"
        )

    actual_commit = git(
        repo, "rev-parse", "--verify", "HEAD^{commit}"
    ).decode().strip()
    if actual_commit != policy["repository_commit"]:
        raise PolicyError(
            f"SnapKit pin changed: expected {policy['repository_commit']}, got {actual_commit}"
        )

    dirty = git(
        repo, "status", "--porcelain=v1", "--untracked-files=all", "--", "Sources"
    ).decode("utf-8", errors="replace").strip()
    if dirty:
        raise PolicyError(f"SnapKit Sources is not clean:\n{dirty}")

    tracked = sorted(
        entry.decode("utf-8")
        for entry in git(repo, "ls-files", "-z", "--", "Sources").split(b"\0")
        if entry and entry.endswith(b".swift")
    )
    source_dir = repo / "Sources"
    disk: list[str] = []
    for path in source_dir.rglob("*.swift"):
        if path.is_symlink():
            raise PolicyError(f"Swift source must not be a symlink: {path}")
        if not path.is_file():
            raise PolicyError(f"Swift source is not a regular file: {path}")
        rel = path.relative_to(repo).as_posix()
        if "\n" in rel or "\r" in rel:
            raise PolicyError(f"newline in source path is unsupported: {rel!r}")
        disk.append(rel)
    disk.sort()
    if tracked != disk:
        only_tracked = sorted(set(tracked) - set(disk))
        only_disk = sorted(set(disk) - set(tracked))
        raise PolicyError(
            "tracked/disk Swift source inventories differ; "
            f"tracked-only={only_tracked}, disk-only={only_disk}"
        )

    source_hashes = {
        rel: sha256(read_regular(repo / rel, "SnapKit source")) for rel in tracked
    }
    for exclusion in exclusions:
        rel = exclusion["path"]
        if rel not in source_hashes:
            raise PolicyError(f"excluded source is absent from inventory: {rel}")
        if not isinstance(exclusion["reason"], str) or not exclusion["reason"].strip():
            raise PolicyError(f"excluded source has no reason: {rel}")
        if source_hashes[rel] != exclusion["sha256"]:
            raise PolicyError(
                f"excluded source hash changed for {rel}: "
                f"expected {exclusion['sha256']}, got {source_hashes[rel]}"
            )

    excluded = set(excluded_paths)
    included = [rel for rel in tracked if rel not in excluded]
    if len(included) + len(excluded) != len(tracked):
        raise PolicyError("source denominator does not reconcile")

    all_source_digest = digest_sources(repo, tracked)
    included_source_digest = digest_sources(repo, included)
    if all_source_digest != policy["all_source_digest"]:
        raise PolicyError(
            "all-source digest changed: expected "
            f"{policy['all_source_digest']}, got {all_source_digest}"
        )
    if included_source_digest != policy["included_source_digest"]:
        raise PolicyError(
            "included-source digest changed: expected "
            f"{policy['included_source_digest']}, got {included_source_digest}"
        )

    attestation = {
        "schema": 2,
        "repository": str(repo),
        "repository_commit": actual_commit,
        "workspace_lock": lock_attestation,
        "policy_sha256": sha256(policy_bytes),
        "source_root": "Sources",
        "discovered_source_count": len(tracked),
        "included_source_count": len(included),
        "excluded_source_count": len(exclusions),
        "all_source_digest": all_source_digest,
        "included_source_digest": included_source_digest,
        "included_sources": [
            {"path": rel, "sha256": source_hashes[rel]} for rel in included
        ],
        "exclusions": exclusions,
    }

    list_path.parent.mkdir(parents=True, exist_ok=True)
    audit_path.parent.mkdir(parents=True, exist_ok=True)
    list_path.write_text(
        "".join(f"{repo / rel}\n" for rel in included), encoding="utf-8"
    )
    audit_path.write_text(
        json.dumps(attestation, indent=2, sort_keys=True) + "\n", encoding="utf-8"
    )

    print(
        "  Focus Package.resolved: "
        f"{lock_attestation['path']} sha256={lock_attestation['sha256']}"
    )
    print(
        "  SnapKit lock: "
        f"{lock_attestation['version']} @ {lock_attestation['revision']}"
    )
    print(f"  SnapKit commit: {actual_commit}")
    print(
        "  source denominator: "
        f"{len(tracked)} discovered = {len(included)} included + "
        f"{len(exclusions)} excluded"
    )
    for exclusion in exclusions:
        print(
            f"  EXCLUDED {exclusion['path']} sha256={exclusion['sha256']}"
        )
        print(f"    reason: {exclusion['reason']}")
    print(f"  included source digest: {attestation['included_source_digest']}")
    print(f"  audit: {audit_path}")
    return attestation


def main(argv: list[str]) -> int:
    if len(argv) != 6:
        print(
            "usage: snapkit_sources.py SNAPKIT_REPO FOCUS_REPO POLICY "
            "SOURCE_LIST AUDIT_JSON",
            file=sys.stderr,
        )
        return 2
    try:
        prepare(argv[1], argv[2], argv[3], argv[4], argv[5])
    except PolicyError as exc:
        print(f"REFUSED: {exc}", file=sys.stderr)
        return 1
    return 0


if __name__ == "__main__":
    raise SystemExit(main(sys.argv))
