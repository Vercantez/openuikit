#!/usr/bin/env python3
"""Prepare and attest the exact SnapKit source set used by the focus-ios census.

This is a vendoring rule, not a source transformer.  It accepts one reviewed,
diagnostic-only exclusion and refuses if the repository pin, source inventory,
excluded bytes, or approved exclusion scope changes.  It writes both the exact
compiler input list and a deterministic JSON attestation of every source hash.
"""

from __future__ import annotations

import hashlib
import json
from pathlib import Path
import subprocess
import sys
from typing import Any


APPROVED_EXCLUSIONS = ("Sources/Debugging.swift",)
POLICY_KEYS = {"schema", "repository_commit", "source_root", "exclusions"}
EXCLUSION_KEYS = {"path", "sha256", "reason"}


class PolicyError(RuntimeError):
    pass


def sha256(data: bytes) -> str:
    return hashlib.sha256(data).hexdigest()


def git(repo: Path, *args: str) -> bytes:
    try:
        return subprocess.check_output(
            ["git", "-C", str(repo), *args], stderr=subprocess.STDOUT
        )
    except subprocess.CalledProcessError as exc:
        detail = exc.output.decode("utf-8", errors="replace").strip()
        raise PolicyError(f"git {' '.join(args)} failed: {detail}") from exc


def digest_sources(repo: Path, paths: list[str]) -> str:
    digest = hashlib.sha256()
    for rel in paths:
        digest.update(rel.encode("utf-8"))
        digest.update(b"\0")
        digest.update((repo / rel).read_bytes())
        digest.update(b"\0")
    return digest.hexdigest()


def prepare(repo_arg: str, policy_arg: str, list_arg: str, audit_arg: str) -> dict[str, Any]:
    repo = Path(repo_arg).resolve()
    policy_path = Path(policy_arg).resolve()
    list_path = Path(list_arg).resolve()
    audit_path = Path(audit_arg).resolve()

    if not repo.is_dir():
        raise PolicyError(f"SnapKit repository is not a directory: {repo}")
    try:
        policy_bytes = policy_path.read_bytes()
        policy = json.loads(policy_bytes)
    except (OSError, json.JSONDecodeError) as exc:
        raise PolicyError(f"cannot read policy {policy_path}: {exc}") from exc

    if not isinstance(policy, dict) or set(policy) != POLICY_KEYS:
        raise PolicyError(f"policy keys must be exactly {sorted(POLICY_KEYS)}")
    if policy["schema"] != 1:
        raise PolicyError(f"unsupported policy schema: {policy['schema']!r}")
    if policy["source_root"] != "Sources":
        raise PolicyError("source_root must remain exactly 'Sources'")
    if not isinstance(policy["repository_commit"], str):
        raise PolicyError("repository_commit must be a string")

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

    actual_commit = git(repo, "rev-parse", "HEAD").decode().strip()
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

    source_hashes = {rel: sha256((repo / rel).read_bytes()) for rel in tracked}
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

    attestation = {
        "schema": 1,
        "repository": str(repo),
        "repository_commit": actual_commit,
        "policy_sha256": sha256(policy_bytes),
        "source_root": "Sources",
        "discovered_source_count": len(tracked),
        "included_source_count": len(included),
        "excluded_source_count": len(exclusions),
        "all_source_digest": digest_sources(repo, tracked),
        "included_source_digest": digest_sources(repo, included),
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
    if len(argv) != 5:
        print(
            "usage: snapkit_sources.py REPO POLICY SOURCE_LIST AUDIT_JSON",
            file=sys.stderr,
        )
        return 2
    try:
        prepare(argv[1], argv[2], argv[3], argv[4])
    except PolicyError as exc:
        print(f"REFUSED: {exc}", file=sys.stderr)
        return 1
    return 0


if __name__ == "__main__":
    raise SystemExit(main(sys.argv))
