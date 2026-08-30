#!/usr/bin/env python3
"""Create an exact, multiplicity-preserving untouched-Focus diagnostic delta."""

from __future__ import annotations

import argparse
from collections import Counter
import hashlib
from pathlib import Path
import re
import sys


PRIMARY = re.compile(
    r"^(?P<path>\S.*?):(?P<line>\d+)(?::(?P<column>\d+))?: error: (?P<message>.*)$",
    re.MULTILINE,
)


class Refusal(RuntimeError):
    pass


def refuse(message: str) -> None:
    raise Refusal(message)


def sha256_bytes(payload: bytes) -> str:
    return hashlib.sha256(payload).hexdigest()


def read_regular(path: Path, label: str) -> bytes:
    if path.is_symlink() or not path.is_file():
        refuse(f"{label} is not a regular non-symlink file: {path}")
    return path.read_bytes()


def diagnostics(log: Path, focus_root: Path) -> list[tuple[str, int, int, str]]:
    payload = read_regular(log, "diagnostic log")
    text = payload.decode("utf-8", errors="replace")
    root = focus_root.resolve(strict=True)
    result: list[tuple[str, int, int, str]] = []
    for match in PRIMARY.finditer(text):
        source = Path(match["path"])
        try:
            relative = source.resolve(strict=True).relative_to(root).as_posix()
        except (OSError, ValueError) as error:
            refuse(f"diagnostic source is outside untouched Focus: {source}: {error}")
        message = match["message"]
        if any(character in message for character in "\0\r\n\t"):
            refuse("diagnostic message contains a forbidden control character")
        result.append(
            (
                relative,
                int(match["line"]),
                int(match["column"] or 0),
                message,
            )
        )
    return result


def normalized_payload(values: list[tuple[str, int, int, str]]) -> bytes:
    return (
        "".join(
            f"diagnostic\t{path}\t{line}\t{column}\t{message}\n"
            for path, line, column, message in values
        )
    ).encode("utf-8")


def write_new(path: Path, payload: bytes, label: str) -> None:
    if path.exists() or path.is_symlink():
        refuse(f"refusing to overwrite {label}: {path}")
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_bytes(payload)


def measure(args: argparse.Namespace) -> None:
    baseline_log = Path(args.baseline_log)
    candidate_log = Path(args.candidate_log)
    focus_root = Path(args.focus_root)
    baseline = diagnostics(baseline_log, focus_root)
    candidate = diagnostics(candidate_log, focus_root)
    baseline_counter = Counter(baseline)
    candidate_counter = Counter(candidate)
    removed = baseline_counter - candidate_counter
    added = candidate_counter - baseline_counter
    removed_count = sum(removed.values())
    added_count = sum(added.values())
    if args.require_no_added and added_count:
        refuse(f"candidate introduced {added_count} primary diagnostics")

    lines = [
        "format\tfocus-first-party-delta-v1",
        f"target\t{args.target}",
        f"baseline-count\t{len(baseline)}",
        f"candidate-count\t{len(candidate)}",
        f"removed-count\t{removed_count}",
        f"added-count\t{added_count}",
    ]
    for disposition, differences in (("removed", removed), ("added", added)):
        for identity, multiplicity in sorted(differences.items()):
            path, line, column, message = identity
            lines.append(
                f"{disposition}\t{multiplicity}\t{path}\t{line}\t{column}\t{message}"
            )
    delta_payload = ("\n".join(lines) + "\n").encode("utf-8")
    baseline_payload = normalized_payload(baseline)
    candidate_payload = normalized_payload(candidate)
    write_new(Path(args.output), delta_payload, "delta output")
    if args.baseline_normalized:
        write_new(
            Path(args.baseline_normalized), baseline_payload,
            "baseline normalized output",
        )
    if args.candidate_normalized:
        write_new(
            Path(args.candidate_normalized), candidate_payload,
            "candidate normalized output",
        )
    print(
        "FOCUS_FIRST_PARTY_DELTA_OK "
        f"baseline={len(baseline)} candidate={len(candidate)} "
        f"removed={removed_count} added={added_count} "
        f"baseline_raw={sha256_bytes(read_regular(baseline_log, 'baseline log'))} "
        f"candidate_raw={sha256_bytes(read_regular(candidate_log, 'candidate log'))} "
        f"baseline_normalized={sha256_bytes(baseline_payload)} "
        f"candidate_normalized={sha256_bytes(candidate_payload)} "
        f"delta={sha256_bytes(delta_payload)}"
    )


def parser() -> argparse.ArgumentParser:
    result = argparse.ArgumentParser()
    result.add_argument("--baseline-log", required=True)
    result.add_argument("--candidate-log", required=True)
    result.add_argument("--focus-root", required=True)
    result.add_argument("--target", required=True)
    result.add_argument("--output", required=True)
    result.add_argument("--baseline-normalized")
    result.add_argument("--candidate-normalized")
    result.add_argument("--require-no-added", action="store_true")
    return result


def main() -> int:
    try:
        measure(parser().parse_args())
    except Refusal as error:
        print(f"focus_first_party_delta: REFUSING -- {error}", file=sys.stderr)
        return 2
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
