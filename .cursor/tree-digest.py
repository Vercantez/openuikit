#!/usr/bin/env python3
"""Deterministic content digest of a product tree: sorted relative paths +
SHA-256 (files) or symlink targets. Directories are not hashed as nodes."""
import hashlib
import os
import sys
from pathlib import Path


def sha256_file(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as handle:
        for chunk in iter(lambda: handle.read(1024 * 1024), b""):
            digest.update(chunk)
    return digest.hexdigest()


def tree_digest(root: Path) -> str:
    digest = hashlib.sha256()
    records = []
    for dirpath, dirnames, filenames in os.walk(root, followlinks=False):
        dirnames.sort()
        for name in sorted(filenames):
            path = Path(dirpath) / name
            relative = path.relative_to(root).as_posix()
            if path.is_symlink():
                records.append(("l", relative, os.readlink(path)))
            elif path.is_file():
                records.append(("f", relative, sha256_file(path)))
            else:
                raise SystemExit(f"tree-digest: unsupported node: {path}")
    records.sort(key=lambda item: item[1])
    for kind, relative, value in records:
        digest.update(f"{kind}\t{relative}\t{value}\0".encode())
    return digest.hexdigest()


if __name__ == "__main__":
    if len(sys.argv) != 2:
        raise SystemExit("usage: tree-digest.py ROOT")
    root = Path(sys.argv[1])
    if not root.is_dir() or root.is_symlink():
        raise SystemExit(f"tree-digest: not a real directory: {root}")
    print(tree_digest(root))
