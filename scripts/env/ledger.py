#!/usr/bin/env python3
"""Hash and checkout-ledger primitives shared by shell gates.

Shell keeps compile/link/run. This module owns content hashing, pin
comparison, and the exact refusal strings those gates already print.
A style that changes a refusal character is a behavior change.
"""

from __future__ import annotations

import argparse
import hashlib
import os
from pathlib import Path
import stat
import subprocess
import sys


class LedgerError(RuntimeError):
    def __init__(self, message: str, exit_code: int = 2) -> None:
        super().__init__(message)
        self.exit_code = exit_code


STYLES: dict[str, dict[str, str]] = {
    "core": {
        "prefix": "core_guest_package: REFUSING -- ",
        "missing": "missing regular {label}: {path}",
        "mismatch": "{label} hash {actual}, expected {expected}",
        "not_git": "{label} is not a Git checkout: {repo}",
        "commit": "{label} commit {actual}, expected {expected}",
        "tree": "{label} tree {actual}, expected {expected}",
        "dirty": "{label} checkout is dirty: {status}",
    },
    "focus-widget": {
        "prefix": "focus_widget_guest: ",
        "missing": "missing regular {label}: {path}",
        "mismatch": "{label} drifted: {actual}",
        "not_git": "{label} is not a Git checkout: {repo}",
        "commit": "{label} commit {actual}, expected {expected}",
        "tree": "{label} tree {actual}, expected {expected}",
        "dirty": "{label} checkout is dirty: {status}",
    },
    "focus-onboarding": {
        "prefix": "focus_onboarding_guest: ",
        "missing": "missing regular {label}: {path}",
        "mismatch": "{label} drifted: {actual}",
        "not_git": "{label} is not a Git checkout: {repo}",
        "commit": "{label} commit {actual}, expected {expected}",
        "tree": "{label} tree {actual}, expected {expected}",
        "dirty": "{label} checkout is dirty: {status}",
    },
}


def sha256_file(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as handle:
        for chunk in iter(lambda: handle.read(1024 * 1024), b""):
            digest.update(chunk)
    return digest.hexdigest()


def require_regular(path: Path, label: str, style: str) -> None:
    try:
        mode = path.lstat().st_mode
    except FileNotFoundError as error:
        raise LedgerError(_format(style, "missing", label=label, path=str(path))) from error
    if stat.S_ISLNK(mode) or not stat.S_ISREG(mode):
        raise LedgerError(_format(style, "missing", label=label, path=str(path)))


def _format(style: str, key: str, **fields: str) -> str:
    spec = STYLES[style]
    return spec["prefix"] + spec[key].format(**fields)


def require_hash(path: Path, expected: str, label: str, style: str = "core") -> str:
    require_regular(path, label, style)
    actual = sha256_file(path)
    if actual != expected:
        raise LedgerError(
            _format(
                style,
                "mismatch",
                label=label,
                actual=actual,
                expected=expected,
                path=str(path),
            )
        )
    return actual


def _git(repo: Path, *args: str) -> tuple[int, str, str]:
    # No extra safe.directory: the gate refusal for dubious-ownership is load-bearing.
    result = subprocess.run(
        ["git", "-C", str(repo), *args],
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
        check=False,
        text=True,
    )
    return result.returncode, result.stdout, result.stderr


def assert_clean_commit(
    repo: Path,
    expected_commit: str,
    expected_tree: str,
    label: str,
    style: str = "core",
) -> None:
    git_dir = repo / ".git"
    if not git_dir.exists():
        raise LedgerError(_format(style, "not_git", label=label, repo=str(repo)))
    status, commit, err = _git(repo, "rev-parse", "--verify", "HEAD^{commit}")
    if status != 0:
        raise LedgerError(_format(style, "not_git", label=label, repo=str(repo)))
    commit = commit.strip()
    status, tree, err = _git(repo, "rev-parse", "--verify", "HEAD^{tree}")
    if status != 0:
        raise LedgerError(_format(style, "not_git", label=label, repo=str(repo)))
    tree = tree.strip()
    status, porcelain, err = _git(
        repo, "status", "--porcelain=v1", "--untracked-files=all"
    )
    if status != 0:
        raise LedgerError(_format(style, "not_git", label=label, repo=str(repo)))
    if commit != expected_commit:
        raise LedgerError(
            _format(style, "commit", label=label, actual=commit, expected=expected_commit)
        )
    if tree != expected_tree:
        raise LedgerError(
            _format(style, "tree", label=label, actual=tree, expected=expected_tree)
        )
    if porcelain.strip():
        raise LedgerError(
            _format(style, "dirty", label=label, status=porcelain.strip())
        )


def load_tree_digest():
    root = Path(__file__).resolve().parents[2]
    path = root / ".cursor" / "tree-digest.py"
    import importlib.util

    spec = importlib.util.spec_from_file_location("cursor_tree_digest", path)
    if spec is None or spec.loader is None:
        raise LedgerError("tree-digest.py is missing")
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module.tree_digest


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(prog="ledger.py")
    parser.add_argument("--style", choices=sorted(STYLES), default="core")
    sub = parser.add_subparsers(dest="command", required=True)

    hash_p = sub.add_parser("hash-file")
    hash_p.add_argument("path")

    req_p = sub.add_parser("require-hash")
    req_p.add_argument("path")
    req_p.add_argument("expected")
    req_p.add_argument("label")

    git_p = sub.add_parser("assert-clean-commit")
    git_p.add_argument("repo")
    git_p.add_argument("commit")
    git_p.add_argument("tree")
    git_p.add_argument("label")

    digest_p = sub.add_parser("tree-digest")
    digest_p.add_argument("root")

    args = parser.parse_args(argv)
    try:
        if args.command == "hash-file":
            path = Path(args.path)
            require_regular(path, "file", args.style)
            sys.stdout.write(sha256_file(path) + "\n")
            return 0
        if args.command == "require-hash":
            require_hash(Path(args.path), args.expected, args.label, args.style)
            return 0
        if args.command == "assert-clean-commit":
            assert_clean_commit(
                Path(args.repo), args.commit, args.tree, args.label, args.style
            )
            return 0
        if args.command == "tree-digest":
            tree_digest = load_tree_digest()
            sys.stdout.write(tree_digest(Path(args.root)) + "\n")
            return 0
    except LedgerError as error:
        sys.stderr.write(str(error) + "\n")
        return error.exit_code
    return 2


if __name__ == "__main__":
    raise SystemExit(main())
