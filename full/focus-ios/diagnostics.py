#!/usr/bin/env python3
"""Extract primary compiler errors without counting rendered source markers.

Swift prints each diagnostic twice in ordinary text output: once as a
location-bearing primary line and once below the source as ``|- error:``.
Source snippets can also contain the literal text ``error:``.  A census over
substring counts therefore has neither a stable nor a meaningful denominator.
"""

from __future__ import annotations

from pathlib import Path
import re
import sys


# Primary Swift/Clang diagnostics begin at column zero and carry a source
# location.  Accept both file:line:column and driver-style <unknown>:line.
# Rendered ``| `- error:`` markers and source lines are intentionally excluded.
PRIMARY_ERROR = re.compile(
    r"^\S.*?:\d+(?::\d+)?: error: (?P<message>.*)$", re.MULTILINE
)


def primary_error_messages(text: str) -> list[str]:
    return [match.group("message") for match in PRIMARY_ERROR.finditer(text)]


def main(argv: list[str]) -> int:
    if len(argv) != 3 or argv[1] != "count":
        print(f"usage: {argv[0]} count LOG", file=sys.stderr)
        return 2
    text = Path(argv[2]).read_text(encoding="utf-8", errors="replace")
    print(len(primary_error_messages(text)))
    return 0


if __name__ == "__main__":
    raise SystemExit(main(sys.argv))
