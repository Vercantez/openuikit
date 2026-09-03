#!/usr/bin/env bash
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
