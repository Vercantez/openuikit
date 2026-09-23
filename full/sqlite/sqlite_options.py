#!/usr/bin/env python3
"""The guest libsqlite3's compile options, derived from the measured iOS table.

    sqlite_options.py flags                 -> one -DSQLITE_... argument per line
    sqlite_options.py check <transcript>    -> compare a guestsqliteoptions run

apple_compile_options.tsv lists every sqlite3_compileoption_get() row of the
iOS 26.1 simulator's libsqlite3 with an action (define, define0, derived, omit,
guest). ``check`` requires a guest transcript's ``opt`` rows to be exactly the
define/define0/derived/guest rows, its version to equal Apple's, and its
threading mode and pragma defaults to equal Apple's. The COMPILER row is required but its value
(the toolchain) is not compared.
"""

from __future__ import annotations

import sys
from pathlib import Path

HERE = Path(__file__).resolve().parent
TABLE = HERE / "apple_compile_options.tsv"
ACTIONS = {"define", "define0", "derived", "omit", "guest"}


class OptionsError(Exception):
    pass


def load(table: Path = TABLE) -> list[tuple[str, str, str]]:
    rows: list[tuple[str, str, str]] = []
    seen: set[str] = set()
    for number, line in enumerate(table.read_text(encoding="utf-8").splitlines(), 1):
        if not line or line.startswith("#"):
            continue
        fields = line.split("\t")
        if len(fields) != 3:
            raise OptionsError(f"{table.name}:{number}: expected 3 tab-separated fields")
        option, action, reason = fields
        if action not in ACTIONS:
            raise OptionsError(f"{table.name}:{number}: unknown action {action!r}")
        if action in {"omit", "guest", "define0"} and reason in {"", "-"}:
            raise OptionsError(f"{table.name}:{number}: {action} needs a reason")
        if action == "define0" and "=" in option:
            raise OptionsError(f"{table.name}:{number}: define0 is for valueless rows")
        if option in seen:
            raise OptionsError(f"{table.name}:{number}: duplicate row {option}")
        seen.add(option)
        rows.append((option, action, reason))
    return rows


def flags(rows: list[tuple[str, str, str]]) -> list[str]:
    result = []
    for option, action, _ in rows:
        if action in {"define", "guest"}:
            result.append(f"-DSQLITE_{option}")
        elif action == "define0":
            result.append(f"-DSQLITE_{option}=0")
    return result


def expected_guest_rows(rows: list[tuple[str, str, str]]) -> list[str]:
    return sorted(o for o, a, _ in rows if a in {"define", "define0", "derived", "guest"})


def apple_rows(rows: list[tuple[str, str, str]]) -> list[str]:
    return [o for o, a, _ in rows if a != "guest"]


def _transcript(text: str) -> tuple[str, list[str], list[str]]:
    """(libversion line, opt rows, every other behavioural line in order).

    ``sourceid`` is dropped: Apple's 3.51.0 carries its own patched check-in
    id (".../apl"), which no upstream build can reproduce.
    """
    head = ""
    options = []
    behaviour = []
    for line in text.splitlines():
        if line.startswith("libversion "):
            head = line
        elif line.startswith("opt "):
            options.append(line[4:])
        elif not line.startswith("sourceid "):
            behaviour.append(line)
    return head, options, behaviour


def check(guest_text: str, apple_text: str, rows: list[tuple[str, str, str]]) -> list[str]:
    problems = []
    apple_head, apple_options, apple_pragmas = _transcript(apple_text)
    guest_head, guest_options, guest_pragmas = _transcript(guest_text)
    if not apple_pragmas or guest_pragmas != apple_pragmas:
        for index, (guest, apple) in enumerate(zip(guest_pragmas, apple_pragmas)):
            if guest != apple:
                problems.append(f"line {index}: guest {guest!r} iOS {apple!r}")
                break
        else:
            problems.append(
                f"behaviour lines differ in count: guest {len(guest_pragmas)} iOS {len(apple_pragmas)}"
            )
    if apple_options != apple_rows(rows):
        problems.append("the table no longer lists exactly the Apple transcript's rows")
    if guest_head != apple_head:
        problems.append(f"version/threadsafe differ: guest {guest_head!r}, iOS {apple_head!r}")
    # sqlite3.c always reports the compiler that built it; the guest's is
    # clang-18, Apple's clang-17. Exactly one such row, value not compared.
    compilers = [o for o in guest_options if o.startswith("COMPILER=clang-")]
    if len(compilers) != 1:
        problems.append(f"expected one COMPILER=clang-* row, got {compilers}")
    guest_options = [o for o in guest_options if not o.startswith("COMPILER=")]
    expected = expected_guest_rows(rows)
    if sorted(guest_options) != expected:
        missing = sorted(set(expected) - set(guest_options))
        extra = sorted(set(guest_options) - set(expected))
        problems.append(f"compile options differ: missing {missing} extra {extra}")
    return problems


def main(argv: list[str]) -> int:
    rows = load()
    if argv[1:] == ["flags"]:
        print("\n".join(flags(rows)))
        return 0
    if len(argv) == 4 and argv[1] == "check":
        problems = check(
            Path(argv[2]).read_text(encoding="utf-8"),
            Path(argv[3]).read_text(encoding="utf-8"),
            rows,
        )
        for problem in problems:
            print(f"sqlite options: {problem}")
        return 1 if problems else 0
    print("usage: sqlite_options.py flags | check <guest-transcript> <ios-transcript>", file=sys.stderr)
    return 2


if __name__ == "__main__":
    sys.exit(main(sys.argv))
