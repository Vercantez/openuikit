#!/usr/bin/env python3
"""Portable content identity for the full Focus guest's inputs (no build cache)."""
import hashlib
import pathlib
import sys

root, uikit = map(pathlib.Path, sys.argv[1:3])
inputs = []
for base, relative in [
    (uikit, 'Sources'),
    (uikit, 'fixtures/realapp/assets'),
    (uikit, 'fixtures/realapp/focus-bundle'),
    (uikit, 'fixtures/realapp/focus-package'),
    (root, 'full/appshim'), (root, 'full/foundation'),
    (root, 'full/dispatch'), (root, 'full/focus-ios'),
    (root, 'full/driver'), (root, 'full/shims'), (root, 'full/observation'),
    (root, 'full/scripts/build_full.sh'), (root, 'full/xcassets/xcassets_tool.py'),
]:
    target = base / relative
    files = [target] if target.is_file() else sorted(target.rglob('*'))
    for path in files:
        if '__pycache__' in path.parts or path.suffix == '.pyc':
            continue
        if path.is_file():
            name = ('uikit/' if base == uikit else '') + path.relative_to(base).as_posix()
            inputs.append((name, hashlib.sha256(path.read_bytes()).hexdigest()))
hash = hashlib.sha256()
for name, digest in sorted(inputs):
    hash.update((name + '\t' + digest + '\n').encode())
print(hash.hexdigest())
