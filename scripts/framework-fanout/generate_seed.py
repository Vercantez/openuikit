#!/usr/bin/env python3
"""Generate an immutable clean-room seed for one Apple framework port.

The generator intentionally runs only on the Mac/Xcode oracle host.  It records
public SDK evidence and exact symbol-graph output, but never copies Apple SDK
headers, module maps, Swift interfaces, or text-based dylib stubs into the
repository.
"""

from __future__ import annotations

import argparse
import hashlib
import json
import math
import os
from pathlib import Path, PurePosixPath
import re
import shutil
import stat
import subprocess
import sys
import tempfile
from typing import Any, Iterable, Iterator, Sequence


SCHEMA = 1
EXPECTED_XCODE_VERSION = "26.1"
EXPECTED_SDK_VERSION = "26.1"
SDK_NAME = "iphoneos"
TARGET = "arm64-apple-ios26.0"
LANES = (
    "leaf-full",
    "medium-full",
    "large-partitioned",
    "legacy-adapter",
)
ALLOWED_STATUSES = (
    "implemented",
    "declared",
    "deferred",
    "unavailable",
    "not-applicable",
)
NONDEFERRED_STATUSES = ("implemented", "declared")
CANONICAL_SURFACE_POLICY = (
    "primary-module-graph_then-module-owned_then-utf8-path_then-"
    "canonical-payload_then-index-v1"
)
MODULE_RE = re.compile(r"^[A-Za-z_][A-Za-z0-9_]*$")
SLUG_RE = re.compile(r"^[a-z][a-z0-9]*(?:-[a-z0-9]+)*$")
CONTROL_RE = re.compile(r"[\x00-\x1f\x7f]")
SHA256_RE = re.compile(r"^[0-9a-f]{64}$")


class SeedError(RuntimeError):
    """A fail-closed input, SDK, or generation error."""


def sha256_file(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as handle:
        for chunk in iter(lambda: handle.read(1024 * 1024), b""):
            digest.update(chunk)
    return digest.hexdigest()


def write_text(path: Path, value: str, *, executable: bool = False) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(value, encoding="utf-8", newline="\n")
    if executable:
        path.chmod(0o755)


def write_json(path: Path, value: Any) -> None:
    write_text(
        path,
        json.dumps(value, ensure_ascii=False, indent=2, sort_keys=True) + "\n",
    )


def run_checked(
    argv: Sequence[str],
    *,
    env: dict[str, str] | None = None,
    cwd: Path | None = None,
) -> str:
    try:
        result = subprocess.run(
            list(argv),
            cwd=cwd,
            env=env,
            check=False,
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
            text=True,
            encoding="utf-8",
        )
    except OSError as error:
        raise SeedError(f"cannot execute {argv[0]}: {error}") from error
    if result.returncode != 0:
        stderr = result.stderr.strip()
        if len(stderr) > 4000:
            stderr = stderr[-4000:]
        raise SeedError(
            f"command failed ({result.returncode}): {' '.join(argv)}"
            + (f"\n{stderr}" if stderr else "")
        )
    return result.stdout


def parse_csv_tokens(value: str, *, label: str, module_tokens: bool) -> list[str]:
    tokens = [token.strip() for token in value.split(",") if token.strip()]
    if len(tokens) != len(set(tokens)):
        raise SeedError(f"{label} contains duplicate values")
    for token in tokens:
        if CONTROL_RE.search(token):
            raise SeedError(f"{label} contains a control character")
        if len(token.encode("utf-8")) > 240:
            raise SeedError(f"{label} value is unreasonably long")
        if module_tokens and not MODULE_RE.fullmatch(token):
            raise SeedError(f"invalid dependency module: {token!r}")
    return tokens


def runtime_marker(module: str) -> str:
    normalized = re.sub(r"[^A-Za-z0-9]+", "_", module).strip("_").upper()
    if not normalized:
        raise SeedError("module does not produce a runtime marker")
    return f"{normalized}_AGENT_RUNTIME_OK"


def minimum_nondeferred_count(lane: str, symbol_count: int) -> tuple[int, str]:
    if symbol_count < 0:
        raise SeedError("negative symbol count")
    if lane in ("leaf-full", "legacy-adapter"):
        return math.ceil(symbol_count * 0.80), "ceil(80% of exact public symbols)"
    if lane == "medium-full":
        return math.ceil(symbol_count * 0.50), "ceil(50% of exact public symbols)"
    if lane == "large-partitioned":
        return (
            min(150, max(50, math.ceil(symbol_count * 0.10))),
            "min(150, max(50, ceil(10% of exact public symbols)))",
        )
    raise SeedError(f"unsupported lane: {lane}")


def tsv_escape(value: str) -> str:
    return (
        value.replace("\\", "\\\\")
        .replace("\t", "\\t")
        .replace("\n", "\\n")
        .replace("\r", "\\r")
    )


def within(path: Path, parent: Path) -> bool:
    try:
        path.relative_to(parent)
    except ValueError:
        return False
    return True


def safe_output_root(argument: str, repo_root: Path) -> Path:
    supplied = Path(argument).expanduser()
    if not supplied.is_absolute():
        supplied = Path.cwd() / supplied
    if not supplied.exists() or not supplied.is_dir():
        raise SeedError("--output-root must name an existing directory")
    if supplied.is_symlink():
        raise SeedError("--output-root may not be a symbolic link")
    root = supplied.resolve(strict=True)
    repo = repo_root.resolve(strict=True)
    if root == Path(root.anchor):
        raise SeedError("refusing a filesystem root as --output-root")
    if within(root, repo):
        approved = (repo / "full").resolve(strict=False)
        if root != approved:
            raise SeedError(
                "repository output is confined to the repo's full directory; "
                "app sources and shared integration files are out of scope"
            )
    return root


def logical_sdk_walk(root: Path, sdk_root: Path) -> Iterator[Path]:
    """Walk logical SDK paths, following safe directory symlinks without loops."""

    sdk_real = sdk_root.resolve(strict=True)

    def visit(directory: Path, ancestors: frozenset[Path]) -> Iterator[Path]:
        try:
            real_directory = directory.resolve(strict=True)
        except OSError as error:
            raise SeedError(f"broken SDK directory path: {directory}: {error}") from error
        if not within(real_directory, sdk_real):
            raise SeedError(f"SDK directory escapes SDK root: {directory}")
        if real_directory in ancestors:
            return
        next_ancestors = ancestors | {real_directory}
        try:
            entries = sorted(os.scandir(directory), key=lambda entry: entry.name)
        except OSError as error:
            raise SeedError(f"cannot scan SDK directory {directory}: {error}") from error
        for entry in entries:
            path = directory / entry.name
            try:
                if entry.is_dir(follow_symlinks=True):
                    yield from visit(path, next_ancestors)
                elif entry.is_file(follow_symlinks=True):
                    real_file = path.resolve(strict=True)
                    if not within(real_file, sdk_real):
                        raise SeedError(f"SDK file escapes SDK root: {path}")
                    yield path
            except OSError as error:
                raise SeedError(f"cannot inspect SDK entry {path}: {error}") from error

    yield from visit(root, frozenset())


def looks_like_tbd(path: Path) -> bool:
    if path.suffix == ".tbd":
        return True
    try:
        prefix = path.open("rb").read(512)
    except OSError as error:
        raise SeedError(f"cannot read SDK file {path}: {error}") from error
    return b"!tapi-tbd" in prefix or b"tbd-version:" in prefix


def classify_sdk_input(path: Path, framework_root: Path) -> str | None:
    relative = path.relative_to(framework_root)
    parts = relative.parts
    if "Headers" in parts and "PrivateHeaders" not in parts:
        return "header"
    if path.name.endswith("modulemap"):
        return "modulemap"
    if path.name.endswith(".swiftinterface"):
        return "swiftinterface"
    if path.suffix == ".tbd":
        return "tbd"
    return None


def collect_sdk_inputs(
    framework_root: Path, sdk_root: Path, module: str
) -> tuple[list[dict[str, Any]], list[Path]]:
    selected: dict[str, tuple[str, Path]] = {}
    tbd_paths: dict[str, Path] = {}
    logical_binary = framework_root / module
    for path in logical_sdk_walk(framework_root, sdk_root):
        category = classify_sdk_input(path, framework_root)
        if path == logical_binary and looks_like_tbd(path):
            category = "tbd"
        if category is None:
            continue
        sdk_relative = path.relative_to(sdk_root).as_posix()
        if sdk_relative in selected:
            raise SeedError(f"duplicate logical SDK input: {sdk_relative}")
        selected[sdk_relative] = (category, path)
        if category == "tbd":
            tbd_paths[sdk_relative] = path
    if not selected:
        raise SeedError(f"no public SDK inputs found for {module}")

    records: list[dict[str, Any]] = []
    for sdk_relative, (category, path) in sorted(selected.items()):
        real = path.resolve(strict=True)
        mode = real.stat().st_mode
        if not stat.S_ISREG(mode):
            raise SeedError(f"SDK input is not a regular file: {path}")
        digest = sha256_file(real)
        if not SHA256_RE.fullmatch(digest):
            raise AssertionError("invalid sha256 implementation result")
        records.append(
            {
                "category": category,
                "sdkRelativePath": sdk_relative,
                "size": real.stat().st_size,
                "sha256": digest,
            }
        )
    return records, [tbd_paths[key] for key in sorted(tbd_paths)]


def write_sdk_input_ledger(path: Path, records: Sequence[dict[str, Any]]) -> None:
    lines = ["category\tsdkRelativePath\tsize\tsha256"]
    for record in records:
        lines.append(
            "\t".join(
                (
                    record["category"],
                    record["sdkRelativePath"],
                    str(record["size"]),
                    record["sha256"],
                )
            )
        )
    write_text(path, "\n".join(lines) + "\n")


def generate_symbol_graphs(
    module: str,
    sdk_root: Path,
    temp_root: Path,
    reference_root: Path,
    clean_env: dict[str, str],
) -> tuple[dict[str, Any], dict[str, dict[str, Any]]]:
    raw_root = temp_root / "symbol-graphs"
    raw_root.mkdir()
    command = [
        "/usr/bin/xcrun",
        "--sdk",
        SDK_NAME,
        "swift-symbolgraph-extract",
        "-module-name",
        module,
        "-target",
        TARGET,
        "-sdk",
        str(sdk_root),
        "-minimum-access-level",
        "public",
        "-module-cache-path",
        str(temp_root / "swift-module-cache"),
        "-output-dir",
        str(raw_root),
    ]
    run_checked(command, env=clean_env)
    graph_files = sorted(raw_root.glob("*.symbols.json"), key=lambda item: item.name)
    if not graph_files:
        raise SeedError(f"symbol graph extraction produced no graph for {module}")

    destination_root = reference_root / "symbol-graphs"
    destination_root.mkdir()
    graph_records: list[dict[str, Any]] = []
    occurrences_by_precise: dict[
        str, list[tuple[tuple[Any, ...], bytes, dict[str, Any]]]
    ] = {}
    relationship_count = 0
    raw_symbol_count = 0
    for source in graph_files:
        if source.is_symlink() or not source.is_file():
            raise SeedError(f"unexpected symbol graph output: {source}")
        try:
            graph = json.loads(source.read_text(encoding="utf-8"))
        except (OSError, UnicodeError, json.JSONDecodeError) as error:
            raise SeedError(f"invalid symbol graph {source.name}: {error}") from error
        symbols = graph.get("symbols")
        relationships = graph.get("relationships")
        if not isinstance(symbols, list) or not isinstance(relationships, list):
            raise SeedError(f"symbol graph lacks symbol/relationship arrays: {source.name}")
        destination = destination_root / source.name
        shutil.copyfile(source, destination)
        digest = sha256_file(destination)
        graph_records.append(
            {
                "path": destination.relative_to(reference_root.parent).as_posix(),
                "sha256": digest,
                "symbolCount": len(symbols),
                "relationshipCount": len(relationships),
            }
        )
        graph_module = graph.get("module")
        graph_module_name = (
            graph_module.get("name") if isinstance(graph_module, dict) else None
        )
        relative_graph_path = destination.relative_to(reference_root.parent).as_posix()
        if graph_module_name == module and source.name == f"{module}.symbols.json":
            ownership_tier = 0
        elif graph_module_name == module:
            ownership_tier = 1
        else:
            ownership_tier = 2
        relationship_count += len(relationships)
        raw_symbol_count += len(symbols)
        for symbol_index, symbol in enumerate(symbols):
            if not isinstance(symbol, dict):
                raise SeedError(f"non-object symbol in {source.name}")
            identifier = symbol.get("identifier")
            precise = identifier.get("precise") if isinstance(identifier, dict) else None
            if not isinstance(precise, str) or not precise or CONTROL_RE.search(precise):
                raise SeedError(f"symbol without a safe precise identifier in {source.name}")
            canonical_payload = json.dumps(
                symbol,
                ensure_ascii=False,
                sort_keys=True,
                separators=(",", ":"),
            ).encode("utf-8")
            selection_key = (
                ownership_tier,
                relative_graph_path.encode("utf-8"),
                canonical_payload,
                symbol_index,
            )
            occurrences_by_precise.setdefault(precise, []).append(
                (selection_key, canonical_payload, symbol)
            )

    symbols_by_precise: dict[str, dict[str, Any]] = {}
    conflicting_duplicate_count = 0
    for precise, occurrences in occurrences_by_precise.items():
        symbols_by_precise[precise] = min(occurrences, key=lambda item: item[0])[2]
        if len({payload for _key, payload, _symbol in occurrences}) > 1:
            conflicting_duplicate_count += 1

    manifest = {
        "schema": SCHEMA,
        "module": module,
        "target": TARGET,
        "minimumAccessLevel": "public",
        "files": graph_records,
        "symbolCount": len(symbols_by_precise),
        "relationshipCount": relationship_count,
        "duplicateOccurrenceCount": raw_symbol_count - len(symbols_by_precise),
        "conflictingDuplicateIdentifierCount": conflicting_duplicate_count,
        "canonicalSurfacePolicy": CANONICAL_SURFACE_POLICY,
    }
    return manifest, symbols_by_precise


def declaration_text(symbol: dict[str, Any]) -> str:
    fragments = symbol.get("declarationFragments", [])
    if not isinstance(fragments, list):
        return ""
    spellings: list[str] = []
    for fragment in fragments:
        if isinstance(fragment, dict) and isinstance(fragment.get("spelling"), str):
            spellings.append(fragment["spelling"])
    return "".join(spellings)


def write_public_surface(
    path: Path, symbols_by_precise: dict[str, dict[str, Any]]
) -> None:
    lines = ["precise\tkind\ttitle\tpath\tdeclaration"]
    for precise in sorted(symbols_by_precise):
        symbol = symbols_by_precise[precise]
        kind_object = symbol.get("kind")
        kind = kind_object.get("identifier", "") if isinstance(kind_object, dict) else ""
        names = symbol.get("names")
        title = names.get("title", "") if isinstance(names, dict) else ""
        path_components = symbol.get("pathComponents")
        if not isinstance(kind, str) or CONTROL_RE.search(kind):
            raise SeedError(f"unsafe kind for precise identifier {precise}")
        if not isinstance(title, str):
            title = ""
        if not isinstance(path_components, list) or not all(
            isinstance(component, str) for component in path_components
        ):
            path_components = []
        values = (
            precise,
            kind,
            tsv_escape(title),
            tsv_escape(".".join(path_components)),
            tsv_escape(declaration_text(symbol)),
        )
        lines.append("\t".join(values))
    write_text(path, "\n".join(lines) + "\n")


def write_tbd_exports(
    path: Path,
    tbd_paths: Sequence[Path],
    sdk_root: Path,
    clean_env: dict[str, str],
) -> int:
    rows: set[tuple[str, str]] = set()
    for tbd in tbd_paths:
        output = run_checked(
            ["/usr/bin/xcrun", "nm", "-arch", "arm64", "-gjU", str(tbd)],
            env=clean_env,
        )
        sdk_relative = tbd.relative_to(sdk_root).as_posix()
        for line in output.splitlines():
            symbol = line.strip()
            if not symbol:
                continue
            if CONTROL_RE.search(symbol):
                raise SeedError(f"unsafe export name emitted for {sdk_relative}")
            rows.add((symbol, sdk_relative))
    lines = ["symbol\tsourceSDKRelativePath"]
    lines.extend(f"{symbol}\t{source}" for symbol, source in sorted(rows))
    write_text(path, "\n".join(lines) + "\n")
    return len(rows)


def roadmap_summary(roadmap_path: Path, module: str) -> dict[str, Any]:
    try:
        roadmap = json.loads(roadmap_path.read_text(encoding="utf-8"))
    except (OSError, UnicodeError, json.JSONDecodeError) as error:
        raise SeedError(f"cannot read framework roadmap: {error}") from error
    if not isinstance(roadmap, dict) or not isinstance(roadmap.get("modules"), list):
        raise SeedError("framework roadmap has an unsupported schema")
    matches = [item for item in roadmap["modules"] if item.get("module") == module]
    if len(matches) != 1:
        raise SeedError(f"framework roadmap must contain exactly one {module} record")
    module_record = matches[0]
    families = [
        family
        for family in roadmap.get("requested_roadmap_families", [])
        if module in family.get("modules", [])
    ]
    rankings = roadmap.get("iphoneos_runtime_port_candidate_rankings", {})

    def rank(name: str) -> int | None:
        values = rankings.get(name, [])
        try:
            return values.index(module) + 1
        except ValueError:
            return None

    return {
        "schema": SCHEMA,
        "module": module,
        "source": {
            "path": "full/framework-roadmap/framework-roadmap.json",
            "sha256": sha256_file(roadmap_path),
            "schema": roadmap.get("schema"),
        },
        "moduleRecord": module_record,
        "requestedFamilies": families,
        "rankings": {
            "byAppCoverage": rank("by_app_coverage"),
            "byFocusLaunchBuildRelevance": rank(
                "by_focus_launch_build_relevance"
            ),
        },
    }


def digest_lines(root: Path, relative_paths: Iterable[str]) -> str:
    lines: list[str] = []
    seen: set[str] = set()
    for relative_text in sorted(relative_paths):
        relative = PurePosixPath(relative_text)
        if relative.is_absolute() or ".." in relative.parts or relative_text in seen:
            raise SeedError(f"unsafe or duplicate digest path: {relative_text}")
        seen.add(relative_text)
        path = root.joinpath(*relative.parts)
        if path.is_symlink() or not path.is_file():
            raise SeedError(f"digest input is not a regular file: {relative_text}")
        lines.append(f"{sha256_file(path)}  {relative_text}")
    return "\n".join(lines) + "\n"


def markdown_list(values: Sequence[str], empty: str) -> str:
    if not values:
        return f"- {empty}"
    return "\n".join(f"- `{value}`" for value in values)


def agents_markdown(
    *,
    module: str,
    slug: str,
    lane: str,
    risks: Sequence[str],
    dependencies: Sequence[str],
    minimum: int,
    marker: str,
) -> str:
    return f"""# {module} framework fan-out rules

This directory is an isolated clean-room starting point for the Linux `{module}`
port. Work only inside `full/{slug}/`. Do not edit application
sources, another framework, package-wide manifests, shared integration/build
files, or anything under `reference/` or `tests/acceptance/`.

## Immutable evidence

`reference/immutable-files.sha256` seals this file, `FANOUT_TASK.md`, every
reference input, and `tests/acceptance/test_host.sh`. Never rewrite, regenerate,
or reseal those files. SDK headers, module maps, Swift interfaces, and TBD files
are proprietary inputs: their paths and hashes are recorded, but their bytes
must not be copied into this repository.

All extractor-emitted graph files are preserved byte-for-byte. Apple graphs can
legitimately repeat a precise identifier. `reference/public-surface.tsv` contains
one canonical row per exact ID under the fixed `canonicalSurfacePolicy` recorded
in `reference/symbol-graphs.json`; duplicate occurrence and full-payload conflict
counts remain explicit there. Never treat canonical compaction as evidence that
the other raw occurrences did not exist.

## Required output

- Implement a real Linux module named `{module}` and a loadable
  `lib{module}.dylib`. Put implementation Swift files in this framework
  directory, outside `tests/`, and list each one as a repo-relative path in
  `{slug}_guest_sources.txt`.
- Create `coverage.tsv` with the exact header
  `precise\tstatus\tevidence\tnotes`. Include every precise identifier from
  `reference/public-surface.tsv` exactly once. Allowed statuses are
  `implemented`, `declared`, `deferred`, `unavailable`, and `not-applicable`.
  At least {minimum} rows must be `implemented` or `declared` for the `{lane}`
  lane. A declaration that does not compile is not `declared`; behavior that was
  not exercised is not `implemented`.
- Create `oracle-questions.tsv` with the exact header
  `precise\tquestion\trisk\treason`. Use an exact graph precise ID, or `module`
  for a cross-cutting question. Include at least one concrete question; do not
  guess behavior missing from public inputs.
- Create a nonempty `README.md` describing what is real, fail-closed, and still
  deferred. The primary implementation file must be `{module}.swift`.
- Create `tests/agent/{module}Runtime.swift`. It must import `{module}`, exercise
  meaningful implemented behavior, and print exactly `{marker}` on success.
- Preserve unavailable, entitlement-gated, hardware-only, and Apple-service
  behavior honestly. Prefer deterministic fail-closed errors or inert behavior
  over fabricated success. Do not add or prioritize `#Preview` support.

## Build discipline

Run `bash tests/acceptance/test_host.sh` from this framework directory before
committing. It validates evidence, coverage, the source manifest, warnings-as-
errors compilation, dylib creation, import, linking, and the runtime marker.
Keep all generated products in temporary directories; remove `.build`, `build`,
and `scratch` before reporting completion. Do not weaken or bypass the gate.

Dependencies expected by this seed:

{markdown_list(dependencies, "No additional framework dependency was declared.")}

Risk labels:

{markdown_list(risks, "No risk label was supplied.")}
"""


def task_markdown(
    *,
    module: str,
    slug: str,
    lane: str,
    risks: Sequence[str],
    dependencies: Sequence[str],
    symbol_count: int,
    relationship_count: int,
    minimum: int,
    rule: str,
    marker: str,
) -> str:
    return f"""# Port `{module}` to Linux

Build a substantial, honest starting implementation of Apple's public `{module}`
surface without changing any app source or shared platform integration file.
This is a **{lane}** lane seeded from Xcode {EXPECTED_XCODE_VERSION}'s iPhoneOS
{EXPECTED_SDK_VERSION} SDK.

The immutable seed contains {symbol_count} unique public precise identifiers and
{relationship_count} symbol-graph relationships. The acceptance floor is
{minimum} nondeferred (`implemented` or `declared`) identifiers: {rule}.

Start with `reference/public-surface.tsv`, then use the raw exact graphs listed by
`reference/symbol-graphs.json` for declarations, relationships, and availability.
The compact surface deterministically selects one occurrence per precise ID;
the graph manifest records the selection policy and duplicate/conflict counts,
while every raw occurrence remains immutable for review.
Use `reference/sdk-inputs.tsv` and `reference/tbd-exports.tsv` as provenance and
ABI evidence only; the Apple SDK input bytes are intentionally absent. Use
`reference/corpus-summary.json` to prioritize APIs exercised by the 20-app
roadmap corpus.

Deliver all of the following in `full/{slug}/`:

1. Linux Swift sources for module `{module}` and `lib{module}.dylib`, with every
   implementation source listed in `{slug}_guest_sources.txt`.
2. Complete exact-ID `coverage.tsv` using only the five allowed statuses and
   evidence paths or test names that substantiate nondeferred claims.
3. Nonempty `{module}.swift` and `README.md`, plus `oracle-questions.tsv` with
   header `precise\tquestion\trisk\treason` and at least one question; use
   `module` only for cross-cutting items.
4. `tests/agent/{module}Runtime.swift`, meaningful focused tests, and the exact
   success marker `{marker}`.
5. A clean successful run of `bash tests/acceptance/test_host.sh` with no checked-
   in or stale build products.

Declared dependencies:

{markdown_list(dependencies, "None beyond the Swift Linux toolchain.")}

Known risk labels:

{markdown_list(risks, "None supplied.")}

Do not invent successful Apple service, device, entitlement, privacy, or UI
behavior. Record questions that need a central Apple-oracle probe and keep those
paths fail-closed until observed.
"""


def acceptance_script() -> str:
    # The here-doc is single quoted so framework paths cannot become shell code.
    return r'''#!/usr/bin/env bash
set -euo pipefail

die() {
    printf 'FRAMEWORK_FANOUT_HOST_GATE_REFUSING: %s\n' "$*" >&2
    exit 1
}

SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)
FRAMEWORK_ROOT=$(CDPATH= cd -- "$SCRIPT_DIR/../.." && pwd -P)
REPO_ROOT=$(git -C "$FRAMEWORK_ROOT" rev-parse --show-toplevel 2>/dev/null) \
    || die 'framework seed is not inside a Git worktree'
[ "$(dirname -- "$FRAMEWORK_ROOT")" = "$REPO_ROOT/full" ] \
    || die 'framework root is not a direct child of full'

for stale in .build build scratch; do
    [ ! -e "$FRAMEWORK_ROOT/$stale" ] \
        || die "stale product directory exists: $stale"
done

command -v python3 >/dev/null 2>&1 || die 'python3 is unavailable'
command -v swiftc >/dev/null 2>&1 || die 'swiftc is unavailable'

python3 -B - "$FRAMEWORK_ROOT" "$REPO_ROOT" <<'PY'
import csv
import hashlib
import json
from pathlib import Path, PurePosixPath
import re
import sys

root = Path(sys.argv[1]).resolve(strict=True)
repo = Path(sys.argv[2]).resolve(strict=True)

def fail(message):
    raise SystemExit(f"FRAMEWORK_FANOUT_HOST_GATE_REFUSING: {message}")

def sha(path):
    digest = hashlib.sha256()
    with path.open("rb") as handle:
        for chunk in iter(lambda: handle.read(1024 * 1024), b""):
            digest.update(chunk)
    return digest.hexdigest()

def confined(relative_text):
    relative = PurePosixPath(relative_text)
    if relative.is_absolute() or ".." in relative.parts or not relative.parts:
        fail(f"unsafe relative path: {relative_text!r}")
    candidate = root.joinpath(*relative.parts)
    try:
        candidate.resolve(strict=True).relative_to(root)
    except (OSError, ValueError):
        fail(f"path escapes or is missing: {relative_text}")
    if candidate.is_symlink() or not candidate.is_file():
        fail(f"path is not a non-link regular file: {relative_text}")
    return candidate

def read_digest(relative_name):
    ledger = confined(relative_name)
    entries = {}
    for number, line in enumerate(ledger.read_text(encoding="utf-8").splitlines(), 1):
        if "  " not in line:
            fail(f"malformed {relative_name}:{number}")
        digest, relative = line.split("  ", 1)
        if not re.fullmatch(r"[0-9a-f]{64}", digest) or relative in entries:
            fail(f"invalid/duplicate {relative_name}:{number}")
        entries[relative] = digest
    if not entries:
        fail(f"empty digest ledger: {relative_name}")
    for relative, expected in entries.items():
        if sha(confined(relative)) != expected:
            fail(f"digest mismatch: {relative}")
    return entries

immutable = read_digest("reference/immutable-files.sha256")
if "reference/immutable-files.sha256" in immutable:
    fail("immutable digest may not attest itself")
required_immutable = {
    "AGENTS.md",
    "FANOUT_TASK.md",
    "reference/framework.json",
    "reference/seed-files.sha256",
    "tests/acceptance/test_host.sh",
}
if not required_immutable.issubset(immutable):
    fail("immutable digest is missing required seed files")

seed = read_digest("reference/seed-files.sha256")
expected_seed = {
    "reference/symbol-graphs.json",
    "reference/public-surface.tsv",
    "reference/tbd-exports.tsv",
    "reference/sdk-inputs.tsv",
    "reference/corpus-summary.json",
}
graph_files = {path for path in immutable if path.startswith("reference/symbol-graphs/")}
expected_seed |= graph_files
if set(seed) != expected_seed:
    fail("seed-files digest has a missing or unexpected evidence path")

framework = json.loads(confined("reference/framework.json").read_text(encoding="utf-8"))
required_keys = {
    "schema", "module", "slug", "lane", "risks", "dependencies",
    "symbolCount", "relationshipCount", "symbolGraph", "publicSurface",
    "tbdExports", "corpusSummary", "sdkInputs", "guestManifest",
    "runtimeMarker", "coveragePolicy", "provenance"
}
if set(framework) != required_keys or framework["schema"] != 1:
    fail("framework.json schema/keys differ")
if root.name != framework["slug"]:
    fail("framework slug differs from directory")
for key in ("symbolGraph", "publicSurface", "tbdExports", "corpusSummary", "sdkInputs"):
    confined(framework[key])

graph_manifest = json.loads(confined(framework["symbolGraph"]).read_text(encoding="utf-8"))
if graph_manifest.get("module") != framework["module"]:
    fail("symbol graph module differs")
if graph_manifest.get("symbolCount") != framework["symbolCount"]:
    fail("symbol count differs")
if graph_manifest.get("relationshipCount") != framework["relationshipCount"]:
    fail("relationship count differs")
manifest_graph_paths = {entry.get("path") for entry in graph_manifest.get("files", [])}
if manifest_graph_paths != graph_files:
    fail("symbol graph file inventory differs")
canonical_policy = (
    "primary-module-graph_then-module-owned_then-utf8-path_then-"
    "canonical-payload_then-index-v1"
)
if graph_manifest.get("canonicalSurfacePolicy") != canonical_policy:
    fail("canonical surface policy differs")

occurrences = {}
raw_symbol_count = 0
raw_relationship_count = 0
for entry in graph_manifest["files"]:
    graph_path = entry["path"]
    graph_file = confined(graph_path)
    if sha(graph_file) != entry.get("sha256"):
        fail(f"symbol graph hash differs: {graph_path}")
    graph = json.loads(graph_file.read_text(encoding="utf-8"))
    symbols = graph.get("symbols")
    relationships = graph.get("relationships")
    if not isinstance(symbols, list) or not isinstance(relationships, list):
        fail(f"raw symbol graph has wrong schema: {graph_path}")
    if entry.get("symbolCount") != len(symbols):
        fail(f"raw symbol count differs: {graph_path}")
    if entry.get("relationshipCount") != len(relationships):
        fail(f"raw relationship count differs: {graph_path}")
    raw_symbol_count += len(symbols)
    raw_relationship_count += len(relationships)
    graph_module = graph.get("module")
    graph_module_name = graph_module.get("name") if isinstance(graph_module, dict) else None
    basename = PurePosixPath(graph_path).name
    if graph_module_name == framework["module"] and basename == f"{framework['module']}.symbols.json":
        tier = 0
    elif graph_module_name == framework["module"]:
        tier = 1
    else:
        tier = 2
    for symbol_index, symbol in enumerate(symbols):
        identifier = symbol.get("identifier") if isinstance(symbol, dict) else None
        precise = identifier.get("precise") if isinstance(identifier, dict) else None
        if not isinstance(precise, str) or not precise:
            fail(f"raw symbol lacks precise identifier: {graph_path}[{symbol_index}]")
        payload = json.dumps(
            symbol, ensure_ascii=False, sort_keys=True, separators=(",", ":")
        ).encode("utf-8")
        key = (tier, graph_path.encode("utf-8"), payload, symbol_index)
        occurrences.setdefault(precise, []).append((key, payload, symbol))

canonical_symbols = {
    precise: min(values, key=lambda item: item[0])[2]
    for precise, values in occurrences.items()
}
duplicate_occurrences = raw_symbol_count - len(canonical_symbols)
conflicting_duplicates = sum(
    len({payload for _key, payload, _symbol in values}) > 1
    for values in occurrences.values()
)
if graph_manifest.get("symbolCount") != len(canonical_symbols):
    fail("unique raw symbol count differs")
if graph_manifest.get("relationshipCount") != raw_relationship_count:
    fail("raw relationship total differs")
if graph_manifest.get("duplicateOccurrenceCount") != duplicate_occurrences:
    fail("duplicate occurrence count differs")
if graph_manifest.get("conflictingDuplicateIdentifierCount") != conflicting_duplicates:
    fail("conflicting duplicate identifier count differs")

def escaped(value):
    return value.replace("\\", "\\\\").replace("\t", "\\t").replace("\n", "\\n").replace("\r", "\\r")

def expected_surface_row(precise, symbol):
    kind_object = symbol.get("kind")
    kind = kind_object.get("identifier", "") if isinstance(kind_object, dict) else ""
    names = symbol.get("names")
    title = names.get("title", "") if isinstance(names, dict) else ""
    components = symbol.get("pathComponents")
    if not isinstance(components, list) or not all(isinstance(item, str) for item in components):
        components = []
    fragments = symbol.get("declarationFragments")
    if not isinstance(fragments, list):
        fragments = []
    declaration = "".join(
        fragment.get("spelling", "")
        for fragment in fragments
        if isinstance(fragment, dict) and isinstance(fragment.get("spelling", ""), str)
    )
    return [precise, kind, escaped(title), escaped(".".join(components)), escaped(declaration)]

surface_path = confined(framework["publicSurface"])
with surface_path.open(encoding="utf-8", newline="") as handle:
    rows = list(csv.reader(handle, delimiter="\t", quoting=csv.QUOTE_NONE))
if not rows or rows[0] != ["precise", "kind", "title", "path", "declaration"]:
    fail("public surface header differs")
if any(len(row) != 5 for row in rows[1:]):
    fail("public surface row width differs")
precise_ids = [row[0] for row in rows[1:]]
if precise_ids != sorted(precise_ids) or len(precise_ids) != len(set(precise_ids)):
    fail("public surface precise identifiers are duplicate or unsorted")
if len(precise_ids) != framework["symbolCount"]:
    fail("public surface symbol count differs")
expected_rows = [
    expected_surface_row(precise, canonical_symbols[precise])
    for precise in sorted(canonical_symbols)
]
if rows[1:] != expected_rows:
    fail("public surface does not match canonical raw-symbol selection")

policy = framework["coveragePolicy"]
allowed = policy.get("allowedStatuses")
if allowed != ["implemented", "declared", "deferred", "unavailable", "not-applicable"]:
    fail("coverage allowed statuses differ")
if policy.get("nondeferredStatuses") != ["implemented", "declared"]:
    fail("coverage nondeferred statuses differ")
minimum = policy.get("minimumNondeferredCount")
if not isinstance(minimum, int) or minimum < 0:
    fail("invalid nondeferred minimum")

coverage_path = confined("coverage.tsv")
with coverage_path.open(encoding="utf-8", newline="") as handle:
    coverage = list(csv.reader(handle, delimiter="\t"))
if not coverage or coverage[0] != ["precise", "status", "evidence", "notes"]:
    fail("coverage.tsv header differs")
if any(len(row) != 4 for row in coverage[1:]):
    fail("coverage.tsv row width differs")
coverage_ids = [row[0] for row in coverage[1:]]
if len(coverage_ids) != len(set(coverage_ids)) or set(coverage_ids) != set(precise_ids):
    fail("coverage.tsv must contain every precise identifier exactly once")
nondeferred = 0
for precise, status, evidence, _notes in coverage[1:]:
    if status not in allowed:
        fail(f"invalid coverage status for {precise}: {status}")
    if status in ("implemented", "declared"):
        nondeferred += 1
        if not evidence.strip():
            fail(f"nondeferred row lacks evidence: {precise}")
if nondeferred < minimum:
    fail(f"nondeferred coverage {nondeferred} is below {minimum}")

oracle_path = confined("oracle-questions.tsv")
with oracle_path.open(encoding="utf-8", newline="") as handle:
    questions = list(csv.reader(handle, delimiter="\t"))
if not questions or questions[0] != ["precise", "question", "risk", "reason"]:
    fail("oracle-questions.tsv header differs")
if len(questions) == 1:
    fail("oracle-questions.tsv must contain at least one question")
for row in questions[1:]:
    if len(row) != 4 or not all(field.strip() for field in row):
        fail("oracle question has an empty field or wrong width")
    if row[0] != "module" and row[0] not in set(precise_ids):
        fail(f"oracle question has unknown precise identifier: {row[0]}")

manifest_relative = framework["guestManifest"]
manifest_path = confined(manifest_relative)
source_relatives = manifest_path.read_text(encoding="utf-8").splitlines()
if not source_relatives or any(not item for item in source_relatives):
    fail("guest source manifest is empty or contains blank rows")
if len(source_relatives) != len(set(source_relatives)):
    fail("guest source manifest contains duplicates")
if source_relatives != sorted(source_relatives):
    fail("guest source manifest is not path-sorted")
expected_prefix = f"full/{framework['slug']}/"
expected_primary = expected_prefix + framework["module"] + ".swift"
if expected_primary not in source_relatives:
    fail(f"guest source manifest lacks primary implementation: {expected_primary}")
for relative_text in source_relatives:
    relative = PurePosixPath(relative_text)
    if relative.as_posix() != relative_text or relative.is_absolute() or ".." in relative.parts:
        fail(f"unsafe guest source path: {relative_text}")
    if not relative_text.startswith(expected_prefix) or relative.suffix != ".swift":
        fail(f"guest source is outside framework or is not Swift: {relative_text}")
    local_parts = relative.parts[2:]
    if "tests" in local_parts:
        fail(f"test source listed as product source: {relative_text}")
    candidate = repo.joinpath(*relative.parts)
    try:
        candidate.resolve(strict=True).relative_to(root)
    except (OSError, ValueError):
        fail(f"guest source escapes or is missing: {relative_text}")
    if candidate.is_symlink() or not candidate.is_file():
        fail(f"guest source is not a non-link regular file: {relative_text}")

readme = confined("README.md")
if not readme.read_text(encoding="utf-8").strip():
    fail("README.md is empty")
runtime = confined(f"tests/agent/{framework['module']}Runtime.swift")
runtime_text = runtime.read_text(encoding="utf-8")
if f"import {framework['module']}" not in runtime_text:
    fail("runtime probe does not import the framework module")
if framework["runtimeMarker"] not in runtime_text:
    fail("runtime probe does not contain the exact success marker")

print("FRAMEWORK_FANOUT_REFERENCE_OK")
PY

MODULE=$(python3 -B -c 'import json,sys; print(json.load(open(sys.argv[1], encoding="utf-8"))["module"])' \
    "$FRAMEWORK_ROOT/reference/framework.json")
MANIFEST=$(python3 -B -c 'import json,sys; print(json.load(open(sys.argv[1], encoding="utf-8"))["guestManifest"])' \
    "$FRAMEWORK_ROOT/reference/framework.json")
MARKER=$(python3 -B -c 'import json,sys; print(json.load(open(sys.argv[1], encoding="utf-8"))["runtimeMarker"])' \
    "$FRAMEWORK_ROOT/reference/framework.json")

mapfile -t SOURCES < "$FRAMEWORK_ROOT/$MANIFEST"
SOURCE_PATHS=()
for relative in "${SOURCES[@]}"; do
    SOURCE_PATHS+=("$REPO_ROOT/$relative")
done

TMP=$(mktemp -d "${TMPDIR:-/tmp}/framework-fanout-host.XXXXXX") \
    || die 'cannot create host-test directory'
cleanup() {
    rm -rf -- "$TMP"
}
trap cleanup EXIT HUP INT TERM

swiftc -warnings-as-errors -parse-as-library -emit-library -emit-module \
    -module-name "$MODULE" \
    -emit-module-path "$TMP/$MODULE.swiftmodule" \
    -o "$TMP/lib$MODULE.dylib" \
    "${SOURCE_PATHS[@]}"
test -s "$TMP/lib$MODULE.dylib" || die "lib$MODULE.dylib was not produced"

swiftc -warnings-as-errors -I "$TMP" \
    "$FRAMEWORK_ROOT/tests/agent/${MODULE}Runtime.swift" \
    "$TMP/lib$MODULE.dylib" \
    -o "$TMP/guest-runtime"

runtime_output=$(LD_LIBRARY_PATH="$TMP${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}" \
    "$TMP/guest-runtime")
printf '%s\n' "$runtime_output" | grep -Fqx -- "$MARKER" \
    || die 'guest runtime did not emit the exact success marker'

printf '%s\n' "$runtime_output"
printf 'FRAMEWORK_FANOUT_HOST_OK module=%s dylib=lib%s.dylib\n' "$MODULE" "$MODULE"
'''


def prepare_clean_environment(temp_root: Path) -> dict[str, str]:
    clean_env = dict(os.environ)
    home = temp_root / "home"
    temporary = temp_root / "tmp"
    module_cache = temp_root / "clang-module-cache"
    for path in (home, temporary, module_cache):
        path.mkdir()
    clean_env.update(
        {
            "HOME": str(home),
            "CFFIXED_USER_HOME": str(home),
            "TMPDIR": str(temporary),
            "CLANG_MODULE_CACHE_PATH": str(module_cache),
            "SWIFT_MODULECACHE_PATH": str(temp_root / "swift-module-cache"),
            "LC_ALL": "C",
            "LANG": "C",
        }
    )
    return clean_env


def validate_xcode() -> dict[str, str]:
    if sys.platform != "darwin":
        raise SeedError("framework seeds must be generated on macOS")
    if not Path("/usr/bin/xcrun").is_file():
        raise SeedError("/usr/bin/xcrun is unavailable")
    version_lines = run_checked(["/usr/bin/xcrun", "xcodebuild", "-version"]).splitlines()
    expected = f"Xcode {EXPECTED_XCODE_VERSION}"
    if not version_lines or version_lines[0].strip() != expected:
        actual = version_lines[0].strip() if version_lines else "missing"
        raise SeedError(f"requires {expected}; found {actual}")
    build = ""
    if len(version_lines) > 1 and version_lines[1].startswith("Build version "):
        build = version_lines[1][len("Build version ") :].strip()
    if not build:
        raise SeedError("cannot determine the Xcode build version")
    sdk_version = run_checked(
        ["/usr/bin/xcrun", "--sdk", SDK_NAME, "--show-sdk-version"]
    ).strip()
    if sdk_version != EXPECTED_SDK_VERSION:
        raise SeedError(
            f"requires iPhoneOS SDK {EXPECTED_SDK_VERSION}; found {sdk_version}"
        )
    sdk_path = run_checked(
        ["/usr/bin/xcrun", "--sdk", SDK_NAME, "--show-sdk-path"]
    ).strip()
    logical_sdk = Path(sdk_path)
    if not logical_sdk.is_absolute() or not logical_sdk.exists():
        raise SeedError("xcrun returned a missing or non-absolute SDK path")
    try:
        sdk_directory = logical_sdk.parent.resolve(strict=True)
        sdk = logical_sdk.resolve(strict=True)
    except OSError as error:
        raise SeedError(f"cannot resolve the xcrun SDK path: {error}") from error
    if (
        sdk_directory.name != "SDKs"
        or sdk_directory.parent.name != "Developer"
        or sdk_directory.parent.parent.name != "iPhoneOS.platform"
    ):
        raise SeedError("xcrun SDK is outside the expected iPhoneOS SDKs directory")
    if not sdk.is_dir() or not within(sdk, sdk_directory):
        raise SeedError(
            "resolved xcrun SDK must be a directory inside the same iPhoneOS SDKs directory"
        )
    extractor = run_checked(
        ["/usr/bin/xcrun", "--sdk", SDK_NAME, "--find", "swift-symbolgraph-extract"]
    ).strip()
    if not Path(extractor).is_file():
        raise SeedError("swift-symbolgraph-extract is unavailable")
    return {
        "xcodeVersion": EXPECTED_XCODE_VERSION,
        "xcodeBuild": build,
        "sdkName": SDK_NAME,
        "sdkVersion": sdk_version,
        # xcrun commonly returns iPhoneOS26.1.sdk as a safe sibling symlink to
        # iPhoneOS.sdk.  Record the resolved directory used for every hash.
        "sdkPath": str(sdk),
        "symbolGraphExtractor": extractor,
    }


def generate(args: argparse.Namespace) -> Path:
    module = args.module
    slug = args.slug
    lane = args.lane
    if not MODULE_RE.fullmatch(module):
        raise SeedError(f"invalid Swift module identifier: {module!r}")
    if not SLUG_RE.fullmatch(slug):
        raise SeedError(f"invalid slug: {slug!r}")
    risks = parse_csv_tokens(args.risks, label="risks", module_tokens=False)
    if not risks:
        raise SeedError("--risks must contain at least one risk label")
    dependencies = sorted(
        parse_csv_tokens(args.dependencies, label="dependencies", module_tokens=True)
    )
    if module in dependencies:
        raise SeedError("a framework may not depend on itself")

    script_path = Path(__file__).resolve(strict=True)
    repo_root = script_path.parents[2]
    roadmap_path = repo_root / "full/framework-roadmap/framework-roadmap.json"
    if not roadmap_path.is_file():
        raise SeedError("generator is not inside the expected platform repository")
    output_root = safe_output_root(args.output_root, repo_root)
    target_root = output_root / slug
    if target_root.exists() or target_root.is_symlink():
        raise SeedError(f"refusing to replace existing framework seed: {target_root}")

    toolchain = validate_xcode()
    sdk_root = Path(toolchain["sdkPath"])
    framework_root = sdk_root / "System/Library/Frameworks" / f"{module}.framework"
    if not framework_root.is_dir():
        raise SeedError(f"public iPhoneOS framework is missing: {module}.framework")
    framework_real = framework_root.resolve(strict=True)
    if not within(framework_real, sdk_root.resolve(strict=True)):
        raise SeedError("framework path escapes the iPhoneOS SDK")

    stage = Path(tempfile.mkdtemp(prefix=f".{slug}.seed.", dir=output_root))
    temp_root: Path | None = None
    published = False
    try:
        temp_root = Path(tempfile.mkdtemp(prefix=f"{slug}-oracle-seed."))
        clean_env = prepare_clean_environment(temp_root)
        reference_root = stage / "reference"
        reference_root.mkdir()
        (stage / "tests/acceptance").mkdir(parents=True)

        sdk_records, tbd_paths = collect_sdk_inputs(framework_root, sdk_root, module)
        write_sdk_input_ledger(reference_root / "sdk-inputs.tsv", sdk_records)

        graph_manifest, symbols = generate_symbol_graphs(
            module, sdk_root, temp_root, reference_root, clean_env
        )
        write_json(reference_root / "symbol-graphs.json", graph_manifest)
        write_public_surface(reference_root / "public-surface.tsv", symbols)
        tbd_export_count = write_tbd_exports(
            reference_root / "tbd-exports.tsv", tbd_paths, sdk_root, clean_env
        )

        corpus = roadmap_summary(roadmap_path, module)
        write_json(reference_root / "corpus-summary.json", corpus)

        symbol_count = graph_manifest["symbolCount"]
        relationship_count = graph_manifest["relationshipCount"]
        minimum, rule = minimum_nondeferred_count(lane, symbol_count)
        marker = runtime_marker(module)

        write_text(
            stage / "AGENTS.md",
            agents_markdown(
                module=module,
                slug=slug,
                lane=lane,
                risks=risks,
                dependencies=dependencies,
                minimum=minimum,
                marker=marker,
            ),
        )
        write_text(
            stage / "FANOUT_TASK.md",
            task_markdown(
                module=module,
                slug=slug,
                lane=lane,
                risks=risks,
                dependencies=dependencies,
                symbol_count=symbol_count,
                relationship_count=relationship_count,
                minimum=minimum,
                rule=rule,
                marker=marker,
            ),
        )
        write_text(stage / f"{slug}_guest_sources.txt", "")
        write_text(
            stage / "tests/acceptance/test_host.sh",
            acceptance_script(),
            executable=True,
        )

        evidence_paths = [
            "reference/symbol-graphs.json",
            "reference/public-surface.tsv",
            "reference/tbd-exports.tsv",
            "reference/sdk-inputs.tsv",
            "reference/corpus-summary.json",
        ] + [record["path"] for record in graph_manifest["files"]]
        write_text(
            reference_root / "seed-files.sha256",
            digest_lines(stage, evidence_paths),
        )

        framework_json = {
            "schema": SCHEMA,
            "module": module,
            "slug": slug,
            "lane": lane,
            "risks": risks,
            "dependencies": dependencies,
            "symbolCount": symbol_count,
            "relationshipCount": relationship_count,
            "symbolGraph": "reference/symbol-graphs.json",
            "publicSurface": "reference/public-surface.tsv",
            "tbdExports": "reference/tbd-exports.tsv",
            "corpusSummary": "reference/corpus-summary.json",
            "sdkInputs": "reference/sdk-inputs.tsv",
            "guestManifest": f"{slug}_guest_sources.txt",
            "runtimeMarker": marker,
            "coveragePolicy": {
                "allowedStatuses": list(ALLOWED_STATUSES),
                "nondeferredStatuses": list(NONDEFERRED_STATUSES),
                "minimumNondeferredCount": minimum,
                "rule": rule,
            },
            "provenance": {
                "generatorPath": "scripts/framework-fanout/generate_seed.py",
                "generatorSHA256": sha256_file(script_path),
                "xcodeVersion": toolchain["xcodeVersion"],
                "xcodeBuild": toolchain["xcodeBuild"],
                "sdkName": toolchain["sdkName"],
                "sdkVersion": toolchain["sdkVersion"],
                "sdkPath": toolchain["sdkPath"],
                "target": TARGET,
                "frameworkSDKRelativePath": framework_root.relative_to(sdk_root).as_posix(),
                "roadmapPath": "full/framework-roadmap/framework-roadmap.json",
                "roadmapSHA256": sha256_file(roadmap_path),
                "rawSDKInputCount": len(sdk_records),
                "tbdInputCount": len(tbd_paths),
                "arm64TBDExportCount": tbd_export_count,
            },
        }
        write_json(reference_root / "framework.json", framework_json)

        immutable_paths = [
            "AGENTS.md",
            "FANOUT_TASK.md",
            "tests/acceptance/test_host.sh",
        ]
        immutable_paths.extend(
            path.relative_to(stage).as_posix()
            for path in reference_root.rglob("*")
            if path.is_file() and path.name != "immutable-files.sha256"
        )
        write_text(
            reference_root / "immutable-files.sha256",
            digest_lines(stage, immutable_paths),
        )

        # Publish only after every output and digest has been written.  The target
        # was checked above and rename is atomic because stage shares its parent.
        stage.rename(target_root)
        published = True
        return target_root
    finally:
        if temp_root is not None:
            shutil.rmtree(temp_root, ignore_errors=True)
        if not published:
            shutil.rmtree(stage, ignore_errors=True)


def argument_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(
        description=(
            "Generate a clean-room Xcode 26.1 iPhoneOS framework seed without "
            "copying raw Apple SDK files"
        )
    )
    parser.add_argument("--module", required=True, help="exact Swift module name")
    parser.add_argument("--slug", required=True, help="lowercase dossier directory name")
    parser.add_argument("--lane", required=True, choices=LANES)
    parser.add_argument(
        "--risks",
        required=True,
        help="comma-separated risk labels from the campaign plan",
    )
    parser.add_argument(
        "--dependencies",
        default="",
        help="optional comma-separated exact dependency module names",
    )
    parser.add_argument(
        "--output-root",
        required=True,
        help="existing destination parent (the repository's full directory)",
    )
    return parser


def main(argv: Sequence[str] | None = None) -> int:
    parser = argument_parser()
    args = parser.parse_args(argv)
    try:
        destination = generate(args)
    except SeedError as error:
        print(f"framework_seed: REFUSING -- {error}", file=sys.stderr)
        return 2
    print(f"FRAMEWORK_FANOUT_SEED_OK path={destination}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
