#!/usr/bin/env python3
"""Reproduce the exact seven-framework source census over the pinned 20 apps."""

from __future__ import annotations

import argparse
import hashlib
import json
from pathlib import Path
import re
import subprocess
import sys


FRAMEWORKS = (
    "LocalAuthentication",
    "SafariServices",
    "Network",
    "StoreKit",
    "AudioToolbox",
    "CoreHaptics",
    "PassKit",
)
TOKEN_PATTERNS = {
    "LocalAuthentication": r"\b(?:LA[A-Z][A-Za-z0-9_]*)\b",
    "SafariServices": r"\b(?:SF(?:Safari|ContentBlocker)[A-Za-z0-9_]*)\b",
    "Network": r"\b(?:NW[A-Z][A-Za-z0-9_]*)\b",
    "StoreKit": r"\b(?:SK[A-Z][A-Za-z0-9_]*|Product|Transaction|AppStore|Storefront|VerificationResult)\b",
    "AudioToolbox": r"\b(?:Audio[A-Z][A-Za-z0-9_]*|kAudio[A-Za-z0-9_]*|SystemSoundID|kSystemSound[A-Za-z0-9_]*)\b",
    "CoreHaptics": r"\b(?:CH[A-Z][A-Za-z0-9_]*)\b",
    "PassKit": r"\b(?:PK[A-Z][A-Za-z0-9_]*)\b",
}
SOURCE_GLOBS = ("*.swift", "*.m", "*.mm", "*.h", "*.hpp")


class Refusal(RuntimeError):
    pass


def run(command: list[str], cwd: Path | None = None) -> str:
    result = subprocess.run(
        command,
        cwd=cwd,
        text=True,
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
    )
    if result.returncode != 0:
        raise Refusal(
            f"command failed ({result.returncode}): {' '.join(command)}\n"
            + result.stderr
        )
    return result.stdout


def sha256(payload: bytes) -> str:
    return hashlib.sha256(payload).hexdigest()


def read_pins(path: Path) -> list[dict[str, str]]:
    records: list[dict[str, str]] = []
    for number, line in enumerate(path.read_text(encoding="utf-8").splitlines(), 1):
        fields = line.split("\t")
        if len(fields) != 4:
            raise Refusal(f"malformed pin line {number}")
        name, repository, commit, pinned_at = fields
        if not re.fullmatch(r"[0-9a-f]{40}", commit):
            raise Refusal(f"invalid commit at pin line {number}")
        records.append(
            {
                "name": name,
                "repository": repository,
                "commit": commit,
                "pinned_at": pinned_at,
            }
        )
    if len(records) != 20 or len({row["name"] for row in records}) != 20:
        raise Refusal("pin manifest must contain exactly 20 unique apps")
    return records


def verify_app(root: Path, pin: dict[str, str]) -> dict[str, str]:
    app = root / pin["name"]
    if not (app / ".git").exists():
        raise Refusal(f"missing Git checkout: {app}")
    head = run(["git", "rev-parse", "HEAD"], app).strip()
    if head != pin["commit"]:
        raise Refusal(f"{pin['name']} HEAD {head}, expected {pin['commit']}")
    if run(["git", "status", "--porcelain=v1", "--untracked-files=all"], app):
        raise Refusal(f"dirty corpus checkout: {pin['name']}")
    tree = run(["git", "rev-parse", "HEAD^{tree}"], app).strip()
    return {**pin, "tree": tree}


def import_pattern(framework: str) -> str:
    return (
        rf"(^|[[:space:]])(@testable[[:space:]]+)?import[[:space:]]+"
        rf"{framework}([[:space:]]|$)|#(import|include)[[:space:]]*"
        rf"[<\"]{framework}[/\"]"
    )


def imported_files(root: Path, framework: str) -> list[Path]:
    command = ["rg", "-l", "--hidden", "-g", "!**/.git/**"]
    for glob in SOURCE_GLOBS:
        command += ["-g", glob]
    command += [import_pattern(framework), str(root)]
    result = subprocess.run(
        command,
        text=True,
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
    )
    if result.returncode not in (0, 1):
        raise Refusal(f"rg failed for {framework}: {result.stderr}")
    return sorted(Path(line) for line in result.stdout.splitlines())


def build(corpus: Path, pins_path: Path) -> dict[str, object]:
    pins = read_pins(pins_path)
    apps = [verify_app(corpus, pin) for pin in pins]
    app_names = {row["name"] for row in apps}
    frameworks: list[dict[str, object]] = []
    all_record_lines: list[str] = []

    for framework in FRAMEWORKS:
        symbol_counts: dict[str, int] = {}
        symbol_apps: dict[str, set[str]] = {}
        records: list[dict[str, object]] = []
        framework_record_lines: list[str] = []
        for path in imported_files(corpus, framework):
            relative = path.relative_to(corpus).as_posix()
            app = relative.split("/", 1)[0]
            if app not in app_names:
                raise Refusal(f"un-pinned top-level corpus path: {relative}")
            payload = path.read_bytes()
            text = payload.decode("utf-8", errors="ignore")
            tokens = re.findall(TOKEN_PATTERNS[framework], text)
            for token in tokens:
                symbol_counts[token] = symbol_counts.get(token, 0) + 1
                symbol_apps.setdefault(token, set()).add(app)
            record = {
                "path": relative,
                "sha256": sha256(payload),
                "bytes": len(payload),
            }
            records.append(record)
            all_record_lines.append(
                f"{framework}\t{relative}\t{record['sha256']}\t{len(payload)}"
            )
            framework_record_lines.append(
                f"{relative}\t{record['sha256']}\t{len(payload)}"
            )

        app_counts: dict[str, int] = {}
        for record in records:
            app = str(record["path"]).split("/", 1)[0]
            app_counts[app] = app_counts.get(app, 0) + 1
        symbols = [
            {
                "name": name,
                "references": count,
                "apps": len(symbol_apps[name]),
            }
            for name, count in sorted(
                symbol_counts.items(), key=lambda pair: (-pair[1], pair[0])
            )
        ]
        frameworks.append(
            {
                "name": framework,
                "import_file_count": len(records),
                "importing_apps": dict(sorted(app_counts.items())),
                "ordered_file_inventory_sha256": sha256(
                    ("\n".join(framework_record_lines) + "\n").encode()
                ),
                "symbols": symbols,
                "focus_files": [
                    record for record in records
                    if str(record["path"]).startswith("focus-ios/")
                ],
            }
        )

    inventory_payload = ("\n".join(all_record_lines) + "\n").encode()
    return {
        "format": "open-uikit-first-party-framework-corpus-v1",
        "pins_manifest": {
            "path": "full/ladder/corpus-pins-2026-08-27.tsv",
            "sha256": sha256(pins_path.read_bytes()),
        },
        "apps": apps,
        "frameworks": frameworks,
        "ordered_file_inventory_sha256": sha256(inventory_payload),
    }


def canonical(document: dict[str, object]) -> bytes:
    return (json.dumps(document, indent=2, sort_keys=True) + "\n").encode()


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--corpus", required=True, type=Path)
    parser.add_argument("--pins", required=True, type=Path)
    parser.add_argument("--compare", type=Path)
    parser.add_argument("--expect-sha256")
    args = parser.parse_args()
    try:
        payload = canonical(build(args.corpus, args.pins))
        if args.expect_sha256 is not None:
            if not re.fullmatch(r"[0-9a-f]{64}", args.expect_sha256):
                raise Refusal("expected census SHA-256 must be lowercase 64-hex")
            actual = sha256(payload)
            if actual != args.expect_sha256:
                raise Refusal(
                    f"corpus census SHA-256 {actual}, expected {args.expect_sha256}"
                )
            document = json.loads(payload)
            counts = ",".join(
                f"{row['name']}={row['import_file_count']}"
                for row in document["frameworks"]
            )
            print(
                "FIRST_PARTY_FRAMEWORK_CORPUS_OK "
                f"sha256={actual} apps=20 frameworks=7 files={counts}"
            )
        elif args.compare is not None:
            if args.compare.read_bytes() != payload:
                raise Refusal(f"corpus census drifted from {args.compare}")
            print(
                "FIRST_PARTY_FRAMEWORK_CORPUS_OK "
                f"sha256={sha256(payload)} apps=20 frameworks=7"
            )
        else:
            sys.stdout.buffer.write(payload)
        return 0
    except (OSError, Refusal) as error:
        print(f"REFUSED: {error}", file=sys.stderr)
        return 2


if __name__ == "__main__":
    raise SystemExit(main())
