#!/usr/bin/env python3
"""Extract primary compiler errors without counting rendered source markers.

Swift prints each diagnostic twice in ordinary text output: once as a
location-bearing primary line and once below the source as ``|- error:``.
Source snippets can also contain the literal text ``error:``.  A census over
substring counts therefore has neither a stable nor a meaningful denominator.
"""

from __future__ import annotations

from pathlib import Path
import argparse
from collections import Counter
import re
import sys
from dataclasses import dataclass


# Primary Swift/Clang diagnostics begin at column zero and carry a source
# location.  Accept both file:line:column and driver-style <unknown>:line.
# Rendered ``| `- error:`` markers and source lines are intentionally excluded.
PRIMARY_ERROR = re.compile(
    r"^(?P<path>\S.*?):(?P<line>\d+)(?::(?P<column>\d+))?: "
    r"error: (?P<message>.*)$",
    re.MULTILINE,
)


@dataclass(frozen=True)
class PrimaryError:
    path: str
    line: int
    column: int | None
    message: str


def primary_errors(text: str) -> list[PrimaryError]:
    return [
        PrimaryError(
            path=match.group("path"),
            line=int(match.group("line")),
            column=(
                int(match.group("column"))
                if match.group("column") is not None
                else None
            ),
            message=match.group("message"),
        )
        for match in PRIMARY_ERROR.finditer(text)
    ]


def primary_error_messages(text: str) -> list[str]:
    return [diagnostic.message for diagnostic in primary_errors(text)]


def normalize_path(path: str, roots: list[tuple[str, Path]]) -> str:
    if path.startswith("<") and path.endswith(">"):
        return path
    candidate = Path(path)
    for label, root in roots:
        try:
            relative = candidate.relative_to(root)
        except ValueError:
            continue
        return f"{label}/{relative.as_posix()}"
    if candidate.is_absolute():
        # An unclassified absolute path would make two otherwise identical
        # fresh-root runs compare differently. Refuse it instead of silently
        # blessing a host-specific diagnostic subject.
        raise ValueError(f"unclassified absolute diagnostic path: {path}")
    return candidate.as_posix()


def normalized_primary_lines(
    text: str,
    roots: list[tuple[str, Path]],
) -> list[str]:
    rows = []
    for diagnostic in primary_errors(text):
        path = normalize_path(diagnostic.path, roots)
        message = diagnostic.message.replace("\t", "\\t")
        column = "" if diagnostic.column is None else str(diagnostic.column)
        rows.append(f"{path}\t{diagnostic.line}\t{column}\t{message}")
    return sorted(rows)


def diagnostic_delta_lines(
    baseline: list[str],
    candidate: list[str],
) -> list[str]:
    baseline_counts = Counter(baseline)
    candidate_counts = Counter(candidate)
    removed = baseline_counts - candidate_counts
    added = candidate_counts - baseline_counts
    rows = [
        "format\tfocus-primary-delta-v1",
        f"baseline-count\t{sum(baseline_counts.values())}",
        f"candidate-count\t{sum(candidate_counts.values())}",
        f"removed-count\t{sum(removed.values())}",
        f"added-count\t{sum(added.values())}",
    ]
    rows.extend(
        f"removed\t{removed[row]}\t{row}" for row in sorted(removed)
    )
    rows.extend(f"added\t{added[row]}\t{row}" for row in sorted(added))
    return rows


def main(argv: list[str]) -> int:
    parser = argparse.ArgumentParser()
    subparsers = parser.add_subparsers(dest="command", required=True)
    count_parser = subparsers.add_parser("count")
    count_parser.add_argument("log", type=Path)
    normalize_parser = subparsers.add_parser("normalize")
    normalize_parser.add_argument("log", type=Path)
    normalize_parser.add_argument("output", type=Path)
    normalize_parser.add_argument(
        "--root",
        action="append",
        default=[],
        metavar="LABEL=ABSOLUTE_PATH",
    )
    delta_parser = subparsers.add_parser("delta")
    delta_parser.add_argument("baseline", type=Path)
    delta_parser.add_argument("candidate", type=Path)
    delta_parser.add_argument("output", type=Path)
    arguments = parser.parse_args(argv[1:])
    if arguments.command == "count":
        text = arguments.log.read_text(encoding="utf-8", errors="replace")
        print(len(primary_errors(text)))
        return 0

    if arguments.command == "delta":
        baseline = arguments.baseline.read_text(encoding="utf-8").splitlines()
        candidate = arguments.candidate.read_text(encoding="utf-8").splitlines()
        rows = diagnostic_delta_lines(baseline, candidate)
        arguments.output.write_text("".join(row + "\n" for row in rows), encoding="utf-8")
        return 0

    text = arguments.log.read_text(encoding="utf-8", errors="replace")
    roots: list[tuple[str, Path]] = []
    for specification in arguments.root:
        label, separator, value = specification.partition("=")
        if not separator or not label or not value or "/" in label or "\t" in label:
            parser.error(f"invalid --root value: {specification!r}")
        path = Path(value)
        if not path.is_absolute():
            parser.error(f"--root path must be absolute: {value!r}")
        roots.append((label, path))
    # Longest roots win when one checkout is nested beneath another.
    roots.sort(key=lambda item: len(item[1].parts), reverse=True)
    try:
        rows = normalized_primary_lines(text, roots)
    except ValueError as exc:
        parser.error(str(exc))
    payload = "".join(row + "\n" for row in rows)
    arguments.output.write_text(payload, encoding="utf-8")
    return 0


if __name__ == "__main__":
    raise SystemExit(main(sys.argv))
