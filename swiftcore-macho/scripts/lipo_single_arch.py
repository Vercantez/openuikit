#!/usr/bin/env python3
"""Single-arch substitute for Apple `lipo` on a Linux-host Darwin stdlib build.

Swift's `_add_swift_lipo_target` (AddSwiftStdlib.cmake:686-687) emits:

    cmake -E env ${lipo_lto_env} ${SWIFT_LIPO} -create -output DST SRC...

On Darwin, SWIFT_LIPO is Apple's lipo. `find_toolchain_tool(... lipo)` finds
nothing on Linux, so SWIFT_LIPO is empty and ninja runs:

    cmake -E env -create -output DST SRC

Ubuntu cmake 3.28 does not implement `cmake -E env -create` (`unknown option
'-create'`). That blocked every overlay that flattens
`lib/swift/macosx/<arch>/libswiftX.so` → `lib/swift/macosx/libswiftX.so`
(_RegexParser, _StringProcessing, Synchronization, ...).

This tool is `-DSWIFT_LIPO=` so the generated command is a real copy. One
input: copy. Two or more: CANNOT_LIPO_FAT_ON_LINUX (this configure is one
Darwin arch). `--rewrite-ninja` patches an already-generated graph whose
SWIFT_LIPO was empty.
"""
from __future__ import annotations

import argparse
import os
import re
import shutil
import sys
from pathlib import Path

CREATE_RE = re.compile(
    r"((?:/\S+/)?cmake(?:-\d+(?:\.\d+)*)?)\s+-E\s+env"
    r"(?:\s+[A-Za-z_][A-Za-z0-9_]*=\S+)*"
    r"\s+-create\s+-output\s+(\S+)\s+(\S+)"
)


def parse_lipo_argv(argv: list[str]) -> tuple[str | None, list[str]]:
    output = None
    inputs: list[str] = []
    i = 0
    while i < len(argv):
        a = argv[i]
        i += 1
        if a in ("-create", "-archs"):
            continue
        if a == "-output":
            if i < len(argv):
                output = argv[i]
                i += 1
            continue
        if a.startswith("-"):
            # Unknown flag: skip a following value if it does not look like a path.
            continue
        inputs.append(a)
    return output, inputs


def lipo_create(output: str, inputs: list[str]) -> int:
    if not output:
        print("CANNOT_LIPO_FAT_ON_LINUX: lipo -create missing -output", file=sys.stderr)
        return 2
    if len(inputs) == 0:
        print("CANNOT_LIPO_FAT_ON_LINUX: lipo -create has no inputs", file=sys.stderr)
        return 2
    if len(inputs) > 1:
        print(
            "CANNOT_LIPO_FAT_ON_LINUX: this Linux-host OSX configure is one Darwin "
            f"arch; refusing to lipo {len(inputs)} inputs into {output}",
            file=sys.stderr,
        )
        return 2
    src = inputs[0]
    if not os.path.isfile(src):
        print(f"CANNOT_LIPO_FAT_ON_LINUX: input missing {src}", file=sys.stderr)
        return 2
    dest_dir = os.path.dirname(output)
    if dest_dir:
        os.makedirs(dest_dir, exist_ok=True)
    shutil.copy2(src, output)
    return 0


def rewrite_ninja_text(text: str) -> tuple[str, int]:
    n = 0

    def repl(m: re.Match[str]) -> str:
        nonlocal n
        n += 1
        cmake, dst, src = m.group(1), m.group(2), m.group(3)
        return f"{cmake} -E copy {src} {dst}"

    return CREATE_RE.sub(repl, text), n


def rewrite_ninja_dir(build_dir: str) -> int:
    total = 0
    root = Path(build_dir)
    files = [root / "build.ninja"]
    rules = root / "CMakeFiles" / "rules.ninja"
    if rules.is_file():
        files.append(rules)
    for p in files:
        if not p.is_file():
            continue
        text = p.read_text(errors="replace")
        new, n = rewrite_ninja_text(text)
        if n:
            p.write_text(new)
            print(f"lipo_single_arch: rewrote {n} empty-lipo command(s) in {p}")
            total += n
    if total == 0:
        print(f"lipo_single_arch: no empty-lipo cmake -E env -create lines in {build_dir}")
    return 0


def main(argv: list[str]) -> int:
    if argv and argv[0] == "--rewrite-ninja":
        if len(argv) < 2:
            print("usage: lipo_single_arch.py --rewrite-ninja <build-dir>", file=sys.stderr)
            return 2
        return rewrite_ninja_dir(argv[1])
    # argparse only for --help; lipo argv is positional flags.
    if argv and argv[0] in ("-h", "--help"):
        print(__doc__)
        return 0
    output, inputs = parse_lipo_argv(argv)
    if output is None and not inputs:
        print("usage: lipo -create -output DST SRC", file=sys.stderr)
        return 2
    return lipo_create(output or "", inputs)


if __name__ == "__main__":
    raise SystemExit(main(sys.argv[1:]))
