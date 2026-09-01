#!/usr/bin/env python3
"""Build the deterministic, offline Cursor framework campaign manifest.

The builder reads already-generated direct ``full/<slug>`` dossiers.  It never
contacts Cursor, invokes an agent, or changes a dossier.  The output is linked
into place only after it is complete and accepted by ``cursor_campaign.py``;
an existing output is always a hard failure and is never replaced.
"""

from __future__ import annotations

import argparse
import csv
from dataclasses import dataclass
import hashlib
import json
import os
from pathlib import Path, PurePosixPath
import re
import stat
import sys
import tempfile
from typing import Any, Callable, Sequence
import urllib.parse


CAMPAIGN_ID = "ios26.1-fwseed-r1"
SCHEMA = 1
TARGET_HEADER = ("module", "slug", "lane", "priority", "risks", "dependencies")
LANES = frozenset(
    {"leaf-full", "medium-full", "large-partitioned", "legacy-adapter"}
)
MODULE_RE = re.compile(r"^[A-Za-z_][A-Za-z0-9_]*$")
SLUG_RE = re.compile(r"^[a-z][a-z0-9]*(?:-[a-z0-9]+)*$")
SHA_RE = re.compile(r"^[0-9a-f]{40}$")
SHA256_RE = re.compile(r"^[0-9a-f]{64}$")
BUILD_ID_RE = re.compile(r"^bld-[A-Za-z0-9][A-Za-z0-9-]*$")
CAMPAIGN_ID_RE = re.compile(r"^[a-z0-9][a-z0-9._-]{0,127}$")
CONTROL_RE = re.compile(r"[\x00-\x1f\x7f]")

FRAMEWORK_KEYS = frozenset(
    {
        "schema",
        "module",
        "slug",
        "lane",
        "risks",
        "dependencies",
        "symbolCount",
        "relationshipCount",
        "symbolGraph",
        "publicSurface",
        "tbdExports",
        "corpusSummary",
        "sdkInputs",
        "guestManifest",
        "runtimeMarker",
        "coveragePolicy",
        "provenance",
    }
)
REQUIRED_IMMUTABLE = frozenset(
    {
        "AGENTS.md",
        "FANOUT_TASK.md",
        "reference/framework.json",
        "reference/seed-files.sha256",
        "tests/acceptance/test_host.sh",
    }
)


class ManifestError(RuntimeError):
    """A deterministic fail-closed builder error."""


@dataclass(frozen=True)
class Target:
    module: str
    slug: str
    lane: str
    priority: int
    risks: tuple[str, ...]
    dependencies: tuple[str, ...]


def refuse(condition: bool, message: str) -> None:
    if not condition:
        raise ManifestError(message)


def sha256_bytes(value: bytes) -> str:
    return hashlib.sha256(value).hexdigest()


def sha256_file(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as handle:
        for block in iter(lambda: handle.read(1024 * 1024), b""):
            digest.update(block)
    return digest.hexdigest()


def json_bytes(value: Any) -> bytes:
    return (json.dumps(value, ensure_ascii=False, indent=2, sort_keys=True) + "\n").encode(
        "utf-8"
    )


def require_plain_string(value: Any, label: str, *, maximum: int = 500) -> str:
    refuse(isinstance(value, str), f"{label} must be a string")
    refuse(value == value.strip() and bool(value), f"{label} must be nonempty and unpadded")
    refuse(not CONTROL_RE.search(value), f"{label} contains a control character")
    refuse(len(value.encode("utf-8")) <= maximum, f"{label} is unreasonably long")
    return value


def safe_relative(value: str, label: str) -> PurePosixPath:
    require_plain_string(value, label)
    relative = PurePosixPath(value)
    refuse(
        not relative.is_absolute()
        and value == relative.as_posix()
        and all(part not in {"", ".", ".."} for part in relative.parts),
        f"{label} is not a safe canonical relative path: {value!r}",
    )
    return relative


def confined_file(root: Path, relative_text: str, label: str) -> Path:
    relative = safe_relative(relative_text, label)
    path = root.joinpath(*relative.parts)
    refuse(path.exists(), f"{label} is missing: {relative_text}")
    refuse(not path.is_symlink(), f"{label} must not be a symlink: {relative_text}")
    refuse(path.is_file(), f"{label} must be a regular file: {relative_text}")
    try:
        path.resolve(strict=True).relative_to(root.resolve(strict=True))
    except (OSError, ValueError) as exc:
        raise ManifestError(f"{label} escapes its dossier: {relative_text}") from exc
    return path


def parse_csv_field(value: str, label: str, *, required: bool) -> tuple[str, ...]:
    if value == "":
        refuse(not required, f"{label} must not be empty")
        return ()
    values = tuple(item.strip() for item in value.split(","))
    refuse(all(values), f"{label} contains an empty token")
    refuse(len(values) == len(set(values)), f"{label} contains a duplicate token")
    for item in values:
        require_plain_string(item, label, maximum=240)
    return values


def read_targets(path: Path) -> list[Target]:
    refuse(path.exists(), f"targets TSV does not exist: {path}")
    refuse(not path.is_symlink() and path.is_file(), "targets TSV must be a non-link regular file")
    try:
        raw = path.read_bytes()
        text = raw.decode("utf-8")
    except (OSError, UnicodeError) as exc:
        raise ManifestError(f"cannot read targets TSV: {exc}") from exc
    refuse(b"\x00" not in raw, "targets TSV contains a NUL byte")
    refuse(raw.endswith(b"\n"), "targets TSV must end in a newline")
    rows = list(csv.reader(text.splitlines(), delimiter="\t", quoting=csv.QUOTE_NONE))
    refuse(bool(rows) and tuple(rows[0]) == TARGET_HEADER, "targets TSV header differs from schema")
    refuse(len(rows) > 1, "targets TSV contains no framework rows")

    targets: list[Target] = []
    modules: set[str] = set()
    slugs: set[str] = set()
    for number, row in enumerate(rows[1:], start=2):
        refuse(len(row) == len(TARGET_HEADER), f"targets TSV line {number} has {len(row)} fields")
        module, slug, lane, priority_text, risks_text, dependencies_text = row
        require_plain_string(module, f"targets line {number} module")
        require_plain_string(slug, f"targets line {number} slug")
        refuse(bool(MODULE_RE.fullmatch(module)), f"invalid module at targets line {number}: {module!r}")
        refuse(bool(SLUG_RE.fullmatch(slug)), f"invalid slug at targets line {number}: {slug!r}")
        refuse(lane in LANES, f"invalid lane at targets line {number}: {lane!r}")
        refuse(priority_text.isascii() and priority_text.isdigit(), f"invalid priority at line {number}")
        priority = int(priority_text)
        refuse(priority >= 0, f"negative priority at targets line {number}")
        refuse(module not in modules, f"duplicate target module: {module}")
        refuse(slug not in slugs, f"duplicate target slug: {slug}")
        modules.add(module)
        slugs.add(slug)
        targets.append(
            Target(
                module=module,
                slug=slug,
                lane=lane,
                priority=priority,
                risks=parse_csv_field(
                    risks_text, f"targets line {number} risks", required=True
                ),
                # The seed generator canonicalizes module dependencies before
                # sealing framework.json; compare against that same ordering.
                dependencies=tuple(
                    sorted(
                        parse_csv_field(
                            dependencies_text,
                            f"targets line {number} dependencies",
                            required=False,
                        )
                    )
                ),
            )
        )
    return sorted(targets, key=lambda item: (-item.priority, item.slug))


def read_json_object(path: Path, label: str) -> dict[str, Any]:
    try:
        value = json.loads(path.read_text(encoding="utf-8"))
    except (OSError, UnicodeError, json.JSONDecodeError) as exc:
        raise ManifestError(f"cannot read {label}: {exc}") from exc
    refuse(isinstance(value, dict), f"{label} must contain a JSON object")
    return value


def parse_and_verify_immutable_ledger(dossier: Path, ledger: Path) -> str:
    try:
        raw = ledger.read_bytes()
        text = raw.decode("ascii")
    except (OSError, UnicodeError) as exc:
        raise ManifestError(f"cannot read immutable ledger for {dossier.name}: {exc}") from exc
    refuse(raw.endswith(b"\n"), f"immutable ledger for {dossier.name} must end in a newline")
    entries: dict[str, str] = {}
    for number, line in enumerate(text.splitlines(), start=1):
        refuse("  " in line, f"malformed immutable ledger {dossier.name}:{number}")
        expected, relative_text = line.split("  ", 1)
        refuse(bool(SHA256_RE.fullmatch(expected)), f"bad digest in immutable ledger {dossier.name}:{number}")
        safe_relative(relative_text, f"immutable ledger {dossier.name}:{number} path")
        refuse(relative_text not in entries, f"duplicate immutable path for {dossier.name}: {relative_text}")
        refuse(
            relative_text != "reference/immutable-files.sha256",
            f"immutable ledger for {dossier.name} must not attest itself",
        )
        entries[relative_text] = expected
    refuse(bool(entries), f"immutable ledger for {dossier.name} is empty")
    refuse(
        list(entries) == sorted(entries),
        f"immutable ledger paths for {dossier.name} are not sorted",
    )
    refuse(
        REQUIRED_IMMUTABLE.issubset(entries),
        f"immutable ledger for {dossier.name} lacks required paths: "
        f"{sorted(REQUIRED_IMMUTABLE - set(entries))}",
    )
    for relative_text, expected in entries.items():
        target = confined_file(
            dossier, relative_text, f"immutable input for {dossier.name}"
        )
        actual = sha256_file(target)
        refuse(
            actual == expected,
            f"immutable digest mismatch for {dossier.name}/{relative_text}: "
            f"expected {expected}, got {actual}",
        )
    return sha256_bytes(raw)


def normalized_runtime_marker(module: str) -> str:
    normalized = re.sub(r"[^A-Za-z0-9]", "_", module).upper()
    return f"{normalized}_AGENT_RUNTIME_OK"


def verify_metadata(metadata: dict[str, Any], target: Target, dossier: Path) -> None:
    refuse(set(metadata) == FRAMEWORK_KEYS, f"framework.json keys differ for {target.module}")
    expected_scalars = {
        "schema": 1,
        "module": target.module,
        "slug": target.slug,
        "lane": target.lane,
        "guestManifest": f"{target.slug}_guest_sources.txt",
        "runtimeMarker": normalized_runtime_marker(target.module),
        "symbolGraph": "reference/symbol-graphs.json",
        "publicSurface": "reference/public-surface.tsv",
        "tbdExports": "reference/tbd-exports.tsv",
        "corpusSummary": "reference/corpus-summary.json",
        "sdkInputs": "reference/sdk-inputs.tsv",
    }
    for key, expected in expected_scalars.items():
        refuse(
            metadata.get(key) == expected,
            f"{target.module} metadata {key} differs: expected {expected!r}, "
            f"got {metadata.get(key)!r}",
        )
    refuse(
        metadata.get("risks") == list(target.risks),
        f"{target.module} metadata risks do not match targets TSV",
    )
    refuse(
        metadata.get("dependencies") == list(target.dependencies),
        f"{target.module} metadata dependencies do not match targets TSV",
    )
    symbol_count = metadata.get("symbolCount")
    refuse(
        isinstance(symbol_count, int) and not isinstance(symbol_count, bool) and symbol_count >= 0,
        f"{target.module} metadata symbolCount must be a nonnegative integer",
    )
    provenance = metadata.get("provenance")
    refuse(isinstance(provenance, dict), f"{target.module} metadata provenance must be an object")
    refuse(provenance.get("xcodeVersion") == "26.1", f"{target.module} Xcode version is not 26.1")
    refuse(provenance.get("sdkVersion") == "26.1", f"{target.module} SDK version is not 26.1")
    for relative in (
        "AGENTS.md",
        "FANOUT_TASK.md",
        f"{target.slug}_guest_sources.txt",
        "tests/acceptance/test_host.sh",
    ):
        confined_file(dossier, relative, f"required seed input for {target.module}")
    gate = dossier / "tests/acceptance/test_host.sh"
    refuse(
        bool(gate.stat().st_mode & stat.S_IXUSR),
        f"acceptance gate is not executable for {target.module}",
    )


def framework_record(
    repo_root: Path, target: Target, environment_marker: str
) -> dict[str, Any]:
    dossier = repo_root / "full" / target.slug
    refuse(dossier.exists(), f"dossier is missing for {target.module}: full/{target.slug}")
    refuse(not dossier.is_symlink() and dossier.is_dir(), f"dossier must be a non-link directory: {dossier}")
    try:
        resolved = dossier.resolve(strict=True)
    except OSError as exc:
        raise ManifestError(f"cannot resolve dossier for {target.module}: {exc}") from exc
    refuse(
        resolved.parent == (repo_root / "full").resolve(strict=True),
        f"dossier is not a direct full/<slug> directory: {dossier}",
    )
    metadata_path = confined_file(
        dossier, "reference/framework.json", f"framework metadata for {target.module}"
    )
    ledger_path = confined_file(
        dossier,
        "reference/immutable-files.sha256",
        f"immutable ledger for {target.module}",
    )
    metadata = read_json_object(metadata_path, f"framework metadata for {target.module}")
    verify_metadata(metadata, target, dossier)
    immutable_digest = parse_and_verify_immutable_ledger(dossier, ledger_path)

    module = target.module
    slug = target.slug
    return {
        "module": module,
        "slug": slug,
        "lane": target.lane,
        "priority": target.priority,
        "agentName": f"Port {module} to Linux",
        "taskPath": f"full/{slug}/FANOUT_TASK.md",
        "ownedPaths": [f"full/{slug}/**"],
        "editablePaths": [
            f"full/{slug}/*.swift",
            f"full/{slug}/{slug}_guest_sources.txt",
            f"full/{slug}/README.md",
            f"full/{slug}/coverage.tsv",
            f"full/{slug}/oracle-questions.tsv",
            f"full/{slug}/tests/agent/**",
        ],
        "immutableDigest": immutable_digest,
        "gate": f"bash full/{slug}/tests/acceptance/test_host.sh",
        "expectedMarkers": [
            environment_marker,
            "FRAMEWORK_FANOUT_REFERENCE_OK",
            metadata["runtimeMarker"],
            f"FRAMEWORK_FANOUT_HOST_OK module={module} dylib=lib{module}.dylib",
        ],
        "dependencies": list(target.dependencies),
        "symbolCount": metadata["symbolCount"],
        "risks": list(target.risks),
    }


def normalize_repository_url(value: str) -> str:
    value = require_plain_string(value, "--repository-url").rstrip("/")
    parsed = urllib.parse.urlsplit(value)
    refuse(
        parsed.scheme == "https"
        and parsed.netloc == "github.com"
        and parsed.path.count("/") == 2
        and not parsed.username
        and not parsed.password
        and not parsed.query
        and not parsed.fragment,
        "--repository-url must be https://github.com/<owner>/<repo> without credentials, query, or fragment",
    )
    return value


def build_manifest(
    *,
    repo_root: Path,
    targets_path: Path,
    campaign_id: str,
    starting_sha: str,
    starting_ref: str,
    repository_url: str,
    active_build_id: str,
    environment_marker: str,
) -> dict[str, Any]:
    campaign_id = require_plain_string(campaign_id, "--campaign-id", maximum=128)
    refuse(
        bool(CAMPAIGN_ID_RE.fullmatch(campaign_id)),
        "--campaign-id must use lowercase letters, digits, dots, underscores, or hyphens",
    )
    starting_sha = starting_sha.lower()
    refuse(bool(SHA_RE.fullmatch(starting_sha)), "--starting-sha must be a full 40-character Git SHA")
    starting_ref = require_plain_string(starting_ref, "--starting-ref", maximum=255)
    refuse(not starting_ref.startswith("-"), "--starting-ref must not begin with '-'")
    repository_url = normalize_repository_url(repository_url)
    active_build_id = require_plain_string(active_build_id, "--active-build-id", maximum=200)
    refuse(bool(BUILD_ID_RE.fullmatch(active_build_id)), "--active-build-id is not a Cursor Build id")
    environment_marker = require_plain_string(
        environment_marker, "--environment-marker", maximum=500
    )

    targets = read_targets(targets_path)
    frameworks = [
        framework_record(repo_root, target, environment_marker) for target in targets
    ]
    return {
        "schema": SCHEMA,
        "campaign": {
            "id": campaign_id,
            "startingSha": starting_sha,
            "activeBuildId": active_build_id,
            "environmentMarker": environment_marker,
        },
        "repository": {"url": repository_url, "startingRef": starting_ref},
        "defaults": {
            "modelId": "grok-4.6",
            "effort": "high",
            "fast": False,
            "maxActive": 24,
            "createRatePerMinute": 12,
            "maxRepairRuns": 2,
            "timeoutMinutes": 60,
            "autoCreatePR": True,
            "skipReviewerRequest": True,
        },
        "frameworks": frameworks,
    }


def validate_with_launcher(path: Path) -> None:
    try:
        from cursor_campaign import CampaignError, normalize_manifest
    except ImportError as exc:
        raise ManifestError(f"cannot import sibling cursor_campaign.py: {exc}") from exc
    try:
        normalize_manifest(path)
    except CampaignError as exc:
        raise ManifestError(f"cursor_campaign.py rejected generated manifest: {exc}") from exc


def atomic_publish_json(
    path: Path,
    value: dict[str, Any],
    *,
    validate: Callable[[Path], None] | None = None,
) -> str:
    refuse(not os.path.lexists(path), f"refusing to overwrite existing output: {path}")
    refuse(path.parent.exists() and path.parent.is_dir(), f"output parent is missing: {path.parent}")
    refuse(not path.parent.is_symlink(), f"output parent must not be a symlink: {path.parent}")
    payload = json_bytes(value)
    descriptor, temporary_name = tempfile.mkstemp(
        prefix=f".{path.name}.", suffix=".tmp", dir=path.parent
    )
    temporary = Path(temporary_name)
    linked = False
    try:
        os.fchmod(descriptor, 0o644)
        with os.fdopen(descriptor, "wb") as handle:
            handle.write(payload)
            handle.flush()
            os.fsync(handle.fileno())
        if validate is not None:
            validate(temporary)
        try:
            os.link(temporary, path)
            linked = True
        except FileExistsError as exc:
            raise ManifestError(f"refusing to overwrite existing output: {path}") from exc
        directory_descriptor = os.open(path.parent, os.O_RDONLY)
        try:
            os.fsync(directory_descriptor)
        finally:
            os.close(directory_descriptor)
    finally:
        try:
            temporary.unlink()
        except FileNotFoundError:
            pass
    refuse(linked, "manifest was not published")
    return sha256_bytes(payload)


def repo_root_for_script() -> Path:
    script = Path(__file__).resolve(strict=True)
    root = script.parents[2]
    refuse((root / ".git").exists(), "builder is not inside a Git worktree")
    return root


def checked_input_path(value: str, repo_root: Path, label: str) -> Path:
    supplied = Path(value).expanduser()
    if not supplied.is_absolute():
        supplied = Path.cwd() / supplied
    refuse(supplied.exists(), f"{label} does not exist: {supplied}")
    refuse(not supplied.is_symlink(), f"{label} must not be a symlink")
    resolved = supplied.resolve(strict=True)
    try:
        resolved.relative_to(repo_root.resolve(strict=True))
    except ValueError as exc:
        raise ManifestError(f"{label} must be inside the repository") from exc
    return resolved


def checked_output_path(value: str, repo_root: Path) -> Path:
    supplied = Path(value).expanduser()
    if not supplied.is_absolute():
        supplied = Path.cwd() / supplied
    parent = supplied.parent.resolve(strict=True)
    expected = (repo_root / "full/framework-fanout").resolve(strict=True)
    refuse(parent == expected, "--output must be a direct file in full/framework-fanout")
    refuse(supplied.name not in {"", ".", ".."}, "--output must name a file")
    return parent / supplied.name


def run_self_check() -> None:
    with tempfile.TemporaryDirectory(prefix="framework-manifest-self-check-") as temporary:
        root = Path(temporary)
        (root / ".git").mkdir()
        campaign_root = root / "full/framework-fanout"
        dossier = root / "full/tinykit"
        reference = dossier / "reference"
        acceptance = dossier / "tests/acceptance"
        campaign_root.mkdir(parents=True)
        reference.mkdir(parents=True)
        acceptance.mkdir(parents=True)

        target_text = (
            "\t".join(TARGET_HEADER)
            + "\nTinyKit\ttinykit\tleaf-full\t100\tservice,fail-closed\tFoundation\n"
        )
        targets = campaign_root / "targets.tsv"
        targets.write_text(target_text, encoding="utf-8", newline="\n")
        (dossier / "AGENTS.md").write_text("immutable rules\n", encoding="utf-8")
        (dossier / "FANOUT_TASK.md").write_text("immutable task\n", encoding="utf-8")
        (dossier / "tinykit_guest_sources.txt").write_text("", encoding="utf-8")
        gate = acceptance / "test_host.sh"
        gate.write_text("#!/bin/sh\nexit 1\n", encoding="utf-8")
        gate.chmod(0o755)
        metadata = {
            "schema": 1,
            "module": "TinyKit",
            "slug": "tinykit",
            "lane": "leaf-full",
            "risks": ["service", "fail-closed"],
            "dependencies": ["Foundation"],
            "symbolCount": 2,
            "relationshipCount": 0,
            "symbolGraph": "reference/symbol-graphs.json",
            "publicSurface": "reference/public-surface.tsv",
            "tbdExports": "reference/tbd-exports.tsv",
            "corpusSummary": "reference/corpus-summary.json",
            "sdkInputs": "reference/sdk-inputs.tsv",
            "guestManifest": "tinykit_guest_sources.txt",
            "runtimeMarker": "TINYKIT_AGENT_RUNTIME_OK",
            "coveragePolicy": {},
            "provenance": {"xcodeVersion": "26.1", "sdkVersion": "26.1"},
        }
        framework_json = reference / "framework.json"
        framework_json.write_bytes(json_bytes(metadata))
        seed_ledger = reference / "seed-files.sha256"
        seed_ledger.write_text("0" * 64 + "  placeholder\n", encoding="ascii")
        immutable_relatives = (
            "AGENTS.md",
            "FANOUT_TASK.md",
            "reference/framework.json",
            "reference/seed-files.sha256",
            "tests/acceptance/test_host.sh",
        )
        immutable = reference / "immutable-files.sha256"
        immutable.write_text(
            "".join(
                f"{sha256_file(dossier / relative)}  {relative}\n"
                for relative in sorted(immutable_relatives)
            ),
            encoding="ascii",
        )

        first = build_manifest(
            repo_root=root,
            targets_path=targets,
            campaign_id="ios26.1-fwseed-self-check",
            starting_sha="a" * 40,
            starting_ref="seed-branch",
            repository_url="https://github.com/example/openuikit",
            active_build_id="bld-self-check",
            environment_marker="CURSOR_SWIFT_ENVIRONMENT_OK",
        )
        second = build_manifest(
            repo_root=root,
            targets_path=targets,
            campaign_id="ios26.1-fwseed-self-check",
            starting_sha="a" * 40,
            starting_ref="seed-branch",
            repository_url="https://github.com/example/openuikit",
            active_build_id="bld-self-check",
            environment_marker="CURSOR_SWIFT_ENVIRONMENT_OK",
        )
        refuse(json_bytes(first) == json_bytes(second), "determinism self-check failed")
        refuse(
            first["campaign"]["id"] == "ios26.1-fwseed-self-check",
            "campaign-id self-check failed",
        )
        framework = first["frameworks"][0]
        refuse(framework["ownedPaths"] == ["full/tinykit/**"], "owned-path self-check failed")
        refuse(
            framework["expectedMarkers"][-1]
            == "FRAMEWORK_FANOUT_HOST_OK module=TinyKit dylib=libTinyKit.dylib",
            "marker self-check failed",
        )
        output = campaign_root / "campaign.json"
        atomic_publish_json(output, first, validate=validate_with_launcher)
        try:
            atomic_publish_json(output, first, validate=validate_with_launcher)
        except ManifestError as exc:
            refuse("overwrite" in str(exc), "overwrite self-check returned the wrong error")
        else:
            raise ManifestError("overwrite self-check failed")

    print(
        "FRAMEWORK_FANOUT_MANIFEST_SELF_CHECK_OK "
        "deterministic=ok dossiers=verified launcher-compatible=ok overwrite=refused"
    )


def argument_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(
        description="Build the deterministic offline Cursor framework campaign manifest."
    )
    parser.add_argument(
        "--self-check",
        action="store_true",
        help="run offline deterministic integration tests and exit",
    )
    parser.add_argument("--targets", help="campaign target TSV")
    parser.add_argument(
        "--campaign-id",
        help=f"unique campaign id (default: {CAMPAIGN_ID})",
    )
    parser.add_argument("--starting-sha", help="full seed commit SHA")
    parser.add_argument("--starting-ref", help="Cursor repository starting ref")
    parser.add_argument("--repository-url", help="https://github.com/<owner>/<repo>")
    parser.add_argument("--active-build-id", help="verified active Cursor Build id")
    parser.add_argument("--environment-marker", help="exact cloud environment success marker")
    parser.add_argument("--output", help="new manifest path under full/framework-fanout")
    return parser


def main(argv: Sequence[str] | None = None) -> int:
    parser = argument_parser()
    args = parser.parse_args(argv)
    try:
        if args.self_check:
            supplied = [
                args.targets,
                args.campaign_id,
                args.starting_sha,
                args.starting_ref,
                args.repository_url,
                args.active_build_id,
                args.environment_marker,
                args.output,
            ]
            refuse(not any(value is not None for value in supplied), "--self-check takes no build inputs")
            run_self_check()
            return 0

        required = {
            "--targets": args.targets,
            "--starting-sha": args.starting_sha,
            "--starting-ref": args.starting_ref,
            "--repository-url": args.repository_url,
            "--active-build-id": args.active_build_id,
            "--environment-marker": args.environment_marker,
            "--output": args.output,
        }
        missing = [name for name, value in required.items() if value is None]
        refuse(not missing, f"missing required arguments: {', '.join(missing)}")
        repo_root = repo_root_for_script()
        targets_path = checked_input_path(args.targets, repo_root, "--targets")
        output_path = checked_output_path(args.output, repo_root)
        manifest = build_manifest(
            repo_root=repo_root,
            targets_path=targets_path,
            campaign_id=args.campaign_id or CAMPAIGN_ID,
            starting_sha=args.starting_sha,
            starting_ref=args.starting_ref,
            repository_url=args.repository_url,
            active_build_id=args.active_build_id,
            environment_marker=args.environment_marker,
        )
        digest = atomic_publish_json(output_path, manifest, validate=validate_with_launcher)
    except ManifestError as exc:
        print(f"framework_manifest: REFUSING -- {exc}", file=sys.stderr)
        return 2
    print(
        f"FRAMEWORK_FANOUT_MANIFEST_OK output={output_path} "
        f"frameworks={len(manifest['frameworks'])} sha256={digest}"
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
