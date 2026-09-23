#!/usr/bin/env python3
"""Refuse a guest <Foundation/Foundation.h> that names a class nobody defines.

    check_runtime_names.py <include-dir> <object.o>...

Every @interface in full/objcfoundation/include carries
OF_SWIFT_CLASS("<runtime name>", "<Swift module>"). Objective-C code compiled
against it references _OBJC_CLASS_$_<runtime name>, so a renamed or removed
facade class would otherwise surface as an undefined symbol in some app link,
or worse, bind to nothing at run time. This checks each runtime name against
the Objective-C class symbols the given objects define, and that the Swift
module named is the one whose mangled prefix the runtime name carries.
"""

from __future__ import annotations

import re
import subprocess
import sys
from pathlib import Path

DECLARATION = re.compile(r'OF_SWIFT_CLASS\("([^"]+)",\s*"([^"]+)"\)')
MANGLED = re.compile(r"_TtC(\d+)(\w+)")


def declared(include_dir: Path) -> list[tuple[str, str, str]]:
    rows = []
    for header in sorted(include_dir.rglob("*.h")):
        for match in DECLARATION.finditer(header.read_text(encoding="utf-8")):
            rows.append((header.name, match.group(1), match.group(2)))
    return rows


def module_of(runtime_name: str) -> str | None:
    match = MANGLED.fullmatch(runtime_name)
    if not match:
        return None
    length = int(match.group(1))
    return match.group(2)[:length]


def problems(rows: list[tuple[str, str, str]], defined: set[str]) -> list[str]:
    found = []
    if not rows:
        found.append("no OF_SWIFT_CLASS declarations found")
    for header, runtime_name, module in rows:
        if f"_OBJC_CLASS_$_{runtime_name}" not in defined:
            found.append(f"{header}: no object defines Objective-C class {runtime_name}")
        mangled_module = module_of(runtime_name)
        if mangled_module is not None and mangled_module != module:
            found.append(f"{header}: {runtime_name} is in module {mangled_module}, header says {module}")
    return found


def defined_classes(objects: list[str]) -> set[str]:
    out = subprocess.run(
        ["llvm-nm-18", "--defined-only", "--extern-only", "-j", *objects],
        check=True, capture_output=True, text=True,
    ).stdout
    return {line.strip() for line in out.splitlines() if line.startswith("_OBJC_CLASS_$_")}


def main(argv: list[str]) -> int:
    if len(argv) < 3:
        print(__doc__.strip().splitlines()[2], file=sys.stderr)
        return 2
    rows = declared(Path(argv[1]))
    found = problems(rows, defined_classes(argv[2:]))
    for problem in found:
        print(f"check_runtime_names: {problem}", file=sys.stderr)
    if found:
        return 1
    print(f"   -> {len(rows)} Foundation classes bound to their Swift runtime names")
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv))
