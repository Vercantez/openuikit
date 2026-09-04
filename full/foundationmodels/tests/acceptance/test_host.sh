#!/usr/bin/env bash
set -euo pipefail

die() {
    printf 'FRAMEWORK_FANOUT_HOST_GATE_REFUSING: %s\n' "$*" >&2
    exit 1
}

SCRIPT_DIR=$(unset CDPATH; cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)
FRAMEWORK_ROOT=$(unset CDPATH; cd -- "$SCRIPT_DIR/../.." && pwd -P)
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
command -v cmp >/dev/null 2>&1 || die 'cmp is unavailable'
command -v timeout >/dev/null 2>&1 || die 'timeout is unavailable'

SHARED_VALIDATOR=$REPO_ROOT/full/framework-fanout/validate_seed.py
if [ ! -f "$SHARED_VALIDATOR" ] || [ -L "$SHARED_VALIDATOR" ]; then
    die 'shared deliverable validator is missing or unsafe'
fi
python3 -B "$SHARED_VALIDATOR" \
    --framework "$FRAMEWORK_ROOT" --phase deliverable \
    || die 'shared deliverable validator rejected framework'

python3 -B - "$FRAMEWORK_ROOT" "$REPO_ROOT" <<'PY'
import csv
import hashlib
import json
from pathlib import Path, PurePosixPath
import re
import struct
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

def strict_json(path, label):
    def pairs(values):
        result = {}
        for key, value in values:
            if key in result:
                fail(f"{label} has duplicate JSON key {key!r}")
            result[key] = value
        return result
    def number(token):
        fail(f"{label} has forbidden JSON number {token!r}")
    try:
        return json.loads(
            path.read_text(encoding="utf-8"),
            object_pairs_hook=pairs,
            parse_float=number,
            parse_constant=number,
        )
    except (OSError, UnicodeError, json.JSONDecodeError) as error:
        fail(f"invalid {label}: {error}")

def canonical_payload(value, label):
    def validate(item):
        if item is None or type(item) in (bool, int):
            return
        if isinstance(item, str):
            try:
                item.encode("utf-8")
            except UnicodeEncodeError:
                fail(f"{label} has an unpaired Unicode surrogate")
            return
        if isinstance(item, list):
            for child in item:
                validate(child)
            return
        if isinstance(item, dict):
            for key, child in item.items():
                if not isinstance(key, str):
                    fail(f"{label} has a non-string object key")
                validate(key)
                validate(child)
            return
        fail(f"{label} has unsupported JSON value {type(item).__name__}")
    validate(value)
    return json.dumps(
        value, ensure_ascii=False, sort_keys=True, separators=(",", ":"),
        allow_nan=False
    ).encode("utf-8")

def multiset_hash(domain, payloads):
    if len(payloads) >= 1 << 64:
        fail("semantic multiset has too many payloads")
    value = hashlib.sha256()
    value.update(domain)
    value.update(struct.pack(">Q", len(payloads)))
    for payload in sorted(payloads):
        if len(payload) >= 1 << 64:
            fail("semantic multiset payload is too large")
        value.update(struct.pack(">Q", len(payload)))
        value.update(payload)
    return value.hexdigest()

def read_tsv(relative_name, header):
    raw = confined(relative_name).read_bytes()
    if b"\x00" in raw or not raw.endswith(b"\n"):
        fail(f"invalid TSV encoding/terminator: {relative_name}")
    try:
        rows = list(csv.reader(raw.decode("utf-8").splitlines(), delimiter="\t", quoting=csv.QUOTE_NONE))
    except UnicodeError as error:
        fail(f"invalid TSV UTF-8 in {relative_name}: {error}")
    if not rows or rows[0] != header or any(len(row) != len(header) for row in rows[1:]):
        fail(f"TSV schema differs: {relative_name}")
    return rows[1:]

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

def repo_file(relative_text):
    relative = PurePosixPath(relative_text)
    if relative.is_absolute() or ".." in relative.parts or not relative.parts:
        fail(f"unsafe repository path: {relative_text!r}")
    candidate = repo.joinpath(*relative.parts)
    try:
        candidate.resolve(strict=True).relative_to(repo)
    except (OSError, ValueError):
        fail(f"repository path escapes or is missing: {relative_text}")
    if candidate.is_symlink() or not candidate.is_file():
        fail(f"repository path is not a non-link regular file: {relative_text}")
    return candidate

def safe_relative_text(value):
    if not isinstance(value, str) or not value or "\\" in value:
        return False
    path = PurePosixPath(value)
    return not path.is_absolute() and all(
        part not in {"", ".", ".."} for part in path.parts
    )

def valid_external_policy(policy):
    keys = {
        "behaviorAuthority", "conflictRule", "copyRule",
        "declarationPrecedence", "runtimeRule"
    }
    sequence_keys = {"behaviorAuthority", "declarationPrecedence"}
    if type(policy) is not dict or set(policy) != keys:
        return False
    for key in keys - sequence_keys:
        value = policy[key]
        if (
            type(value) is not str
            or not value.strip()
            or re.search(r"[\x00-\x1f\x7f]", value)
        ):
            return False
    for key in sequence_keys:
        values = policy[key]
        if type(values) is not list or not values:
            return False
        if any(
            type(value) is not str
            or not value.strip()
            or re.search(r"[\x00-\x1f\x7f]", value)
            for value in values
        ):
            return False
        if len(values) != len(set(values)):
            return False
    return True

def swift_code_projection(source):
    characters = list(source)
    length = len(source)

    def mask(start, end):
        for index in range(start, end):
            if characters[index] not in {"\n", "\r"}:
                characters[index] = " "

    def quoted_end(start, hashes, quote_count):
        cursor = start + hashes + quote_count
        terminator = '"' * quote_count + "#" * hashes
        while cursor < length:
            if source.startswith(terminator, cursor):
                return cursor + len(terminator)
            if hashes == 0 and source[cursor] == "\\":
                cursor += min(2, length - cursor)
            else:
                cursor += 1
        fail("unterminated Swift string literal")

    cursor = 0
    while cursor < length:
        if source.startswith("//", cursor):
            end = source.find("\n", cursor + 2)
            if end < 0:
                end = length
            mask(cursor, end)
            cursor = end
            continue
        if source.startswith("/*", cursor):
            depth = 1
            end = cursor + 2
            while end < length and depth:
                if source.startswith("/*", end):
                    depth += 1
                    end += 2
                elif source.startswith("*/", end):
                    depth -= 1
                    end += 2
                else:
                    end += 1
            if depth:
                fail("unterminated Swift block comment")
            mask(cursor, end)
            cursor = end
            continue
        delimiter = cursor
        while delimiter < length and source[delimiter] == "#":
            delimiter += 1
        hashes = delimiter - cursor
        if delimiter < length and source.startswith('"""', delimiter):
            end = quoted_end(cursor, hashes, 3)
            mask(cursor, end)
            cursor = end
            continue
        if delimiter < length and source[delimiter] == '"':
            end = quoted_end(cursor, hashes, 1)
            mask(cursor, end)
            cursor = end
            continue
        if hashes and delimiter < length and source[delimiter] == "/":
            terminator = "/" + "#" * hashes
            end = source.find(terminator, delimiter + 1)
            if end < 0:
                fail("unterminated Swift raw-regex literal")
            end += len(terminator)
            mask(cursor, end)
            cursor = end
            continue
        cursor += 1
    return "".join(characters)

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
    "reference/symbol-conflicts.tsv",
    "reference/public-surface.tsv",
    "reference/api-digester.json",
    "reference/api-crosswalk.tsv",
    "reference/tbd-exports.tsv",
    "reference/sdk-inputs.tsv",
    "reference/corpus-summary.json",
    "reference/external-evidence.json",
}
graph_files = {path for path in immutable if path.startswith("reference/symbol-graphs/")}
expected_seed |= graph_files
if set(seed) != expected_seed:
    fail("seed-files digest has a missing or unexpected evidence path")

framework = json.loads(confined("reference/framework.json").read_text(encoding="utf-8"))
required_keys = {
    "schema", "module", "slug", "lane", "risks", "dependencies",
    "symbolCount", "relationshipCount", "symbolGraph", "symbolConflicts",
    "publicSurface", "apiDigester", "apiCrosswalk", "tbdExports",
    "corpusSummary", "externalEvidence", "sdkInputs", "guestManifest",
    "runtimeMarker", "coveragePolicy", "provenance"
}
if set(framework) != required_keys or framework["schema"] != 2:
    fail("framework.json schema/keys differ")
if root.name != framework["slug"]:
    fail("framework slug differs from directory")
for key in (
    "symbolGraph", "symbolConflicts", "publicSurface", "apiDigester",
    "apiCrosswalk", "tbdExports", "corpusSummary", "externalEvidence",
    "sdkInputs"
):
    confined(framework[key])

api_digester = strict_json(confined(framework["apiDigester"]), "API digester")
if not isinstance(api_digester, dict) or set(api_digester) != {"ABIRoot"}:
    fail("API digester root object differs")
api_root = api_digester["ABIRoot"]
if (
    not isinstance(api_root, dict)
    or api_root.get("kind") != "Root"
    or api_root.get("name") != framework["module"]
    or api_root.get("printedName") != framework["module"]
    or not isinstance(api_root.get("children"), list)
):
    fail("API digester module/root differs")
api_node_count = 0
api_declarations = []
api_container_kinds = {"Actor", "Class", "Enum", "Extension", "Protocol", "Struct"}
api_callable_kinds = {"Constructor", "Destructor", "Func", "Operator", "Subscript"}
api_list_fields = {"accessors", "children", "conformances", "declAttributes"}
def pointer_component(value):
    return value.replace("~", "~0").replace("/", "~1")
def visit_api(value, pointer, container_names, direct_root_child=False):
    global api_node_count
    if isinstance(value, list):
        for index, child in enumerate(value):
            visit_api(child, f"{pointer}/{index}", container_names)
        return
    if not isinstance(value, dict):
        return
    for key in value:
        normalized = re.sub(r"[^a-z0-9]", "", key.casefold())
        if normalized in {"location", "toolarguments"}:
            fail(f"API digester forbidden provenance field {key!r} at {pointer}")
    kind = value.get("kind")
    if "kind" in value:
        if not isinstance(kind, str) or not kind or re.search(r"[\x00-\x1f\x7f]", kind):
            fail(f"API digester unsafe kind at {pointer}")
        api_node_count += 1
    child_container_names = container_names
    if "declKind" in value:
        for key in ("kind", "declKind", "moduleName", "name", "printedName"):
            candidate = value.get(key)
            if not isinstance(candidate, str) or not candidate or re.search(r"[\x00-\x1f\x7f]", candidate):
                fail(f"API declaration {pointer} has unsafe {key}")
        if re.fullmatch(r"[_A-Za-z][_A-Za-z0-9]*", value["moduleName"]) is None:
            fail(f"API declaration {pointer} has invalid module owner")
        usr = value.get("usr")
        if usr is not None and (not isinstance(usr, str) or not usr or re.search(r"[\x00-\x1f\x7f]", usr)):
            fail(f"API declaration {pointer} has unsafe usr")
        if value.get("static") is not None and type(value.get("static")) is not bool:
            fail(f"API declaration {pointer} has non-boolean static")
        for key in api_list_fields:
            if key in value and not isinstance(value[key], list):
                fail(f"API declaration {pointer} field {key} must be a list")
        attributes = value.get("declAttributes")
        if isinstance(attributes, list) and any(
            not isinstance(attribute, str) or re.search(r"[\x00-\x1f\x7f]", attribute)
            for attribute in attributes
        ):
            fail(f"API declaration {pointer} has unsafe attributes")
        decl_kind = value["declKind"]
        leaf = value["printedName"] if decl_kind in api_callable_kinds else value["name"]
        api_declarations.append({
            "nodePath": pointer,
            "directRootChild": direct_root_child,
            "logicalPath": container_names + (leaf,),
            "node": value,
        })
        if decl_kind in api_container_kinds:
            child_container_names = container_names + (value["name"],)
    for key, child in value.items():
        child_pointer = f"{pointer}/{pointer_component(key)}"
        if isinstance(child, list):
            for index, item in enumerate(child):
                visit_api(
                    item, f"{child_pointer}/{index}", child_container_names,
                    pointer == "/ABIRoot" and key == "children"
                )
        elif isinstance(child, dict):
            visit_api(child, child_pointer, child_container_names)
visit_api(api_root, "/ABIRoot", ())
if api_node_count <= 1 or not api_declarations:
    fail("API digester has no declaration nodes")
provenance = framework["provenance"]
if provenance.get("apiDigesterNodeCount") != api_node_count:
    fail("API digester node count differs")
if provenance.get("apiDigesterFormatVersion") != api_root.get("json_format_version"):
    fail("API digester format version differs")
if provenance.get("apiDeclarationNodeCount") != len(api_declarations):
    fail("API declaration node count differs")
api_owned_count = sum(
    record["node"].get("moduleName") == framework["module"]
    for record in api_declarations
)
if provenance.get("apiOwnedDeclarationNodeCount") != api_owned_count:
    fail("API owned declaration node count differs")

external = json.loads(confined(framework["externalEvidence"]).read_text(encoding="utf-8"))
if (
    not isinstance(external, dict)
    or set(external) != {"schema", "module", "lock", "policy", "sources"}
    or external.get("schema") != 1
    or external.get("module") != framework["module"]
    or not valid_external_policy(external.get("policy"))
    or not isinstance(external.get("sources"), list)
    or not external["sources"]
):
    fail("external evidence schema/module differs")
external_lock = external.get("lock")
if not isinstance(external_lock, dict) or set(external_lock) != {"path", "sha256"}:
    fail("external evidence lock record differs")
lock_path = repo_file(external_lock["path"])
if sha(lock_path) != external_lock["sha256"]:
    fail("external evidence lock digest differs")
repository_lock = strict_json(lock_path, "repository external evidence lock")
if (
    not isinstance(repository_lock, dict)
    or set(repository_lock) != {"schema", "policy", "sources"}
    or repository_lock.get("schema") != 1
    or not valid_external_policy(repository_lock.get("policy"))
    or not isinstance(repository_lock.get("sources"), list)
    or not repository_lock["sources"]
):
    fail("repository external evidence lock schema/policy differs")
if external["policy"] != repository_lock["policy"]:
    fail("external evidence policy differs from repository lock")
if external_lock["path"] != framework["provenance"].get("externalEvidenceLockPath"):
    fail("external evidence lock path differs from provenance")
if external_lock["sha256"] != framework["provenance"].get("externalEvidenceLockSHA256"):
    fail("external evidence lock hash differs from provenance")

graph_manifest = json.loads(confined(framework["symbolGraph"]).read_text(encoding="utf-8"))
graph_manifest_keys = {
    "schema", "module", "target", "minimumAccessLevel", "files",
    "symbolCount", "relationshipCount", "duplicateOccurrenceCount",
    "duplicateRelationshipOccurrenceCount", "conflictingDuplicateIdentifierCount",
    "canonicalSurfacePolicy", "semanticHashPolicy", "symbolMultisetSHA256",
    "relationshipMultisetSHA256", "conflictLedger"
}
if not isinstance(graph_manifest, dict) or set(graph_manifest) != graph_manifest_keys:
    fail("symbol graph manifest schema differs")
if graph_manifest.get("schema") != 2:
    fail("symbol graph manifest version differs")
if graph_manifest.get("module") != framework["module"]:
    fail("symbol graph module differs")
if graph_manifest.get("symbolCount") != framework["symbolCount"]:
    fail("symbol count differs")
if graph_manifest.get("relationshipCount") != framework["relationshipCount"]:
    fail("relationship count differs")
manifest_paths = [entry.get("path") for entry in graph_manifest.get("files", [])]
manifest_graph_paths = set(manifest_paths)
if manifest_graph_paths != graph_files:
    fail("symbol graph file inventory differs")
if manifest_paths != sorted(manifest_paths, key=lambda value: value.encode("utf-8")):
    fail("symbol graph file inventory is not UTF-8 sorted")
canonical_policy = (
    "primary-module-graph_then-module-owned_then-utf8-path_then-"
    "canonical-payload-v2"
)
if graph_manifest.get("canonicalSurfacePolicy") != canonical_policy:
    fail("canonical surface policy differs")
if graph_manifest.get("semanticHashPolicy") != "sorted-canonical-json-u64be-length-prefixed-sha256-v1":
    fail("semantic hash policy differs")
if graph_manifest.get("conflictLedger") != framework["symbolConflicts"]:
    fail("symbol conflict ledger path differs")

occurrences = {}
symbol_payloads = []
relationship_payloads = []
raw_symbol_count = 0
raw_relationship_count = 0
for entry in graph_manifest["files"]:
    graph_path = entry["path"]
    graph_file = confined(graph_path)
    if sha(graph_file) != entry.get("sha256"):
        fail(f"symbol graph hash differs: {graph_path}")
    graph = strict_json(graph_file, f"raw symbol graph {graph_path}")
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
    for relationship_index, relationship in enumerate(relationships):
        if not isinstance(relationship, dict):
            fail(f"raw relationship is not an object: {graph_path}[{relationship_index}]")
        relationship_payloads.append(
            canonical_payload(relationship, f"{graph_path} relationship[{relationship_index}]")
        )
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
        payload = canonical_payload(symbol, f"{graph_path} symbol[{symbol_index}]")
        symbol_payloads.append(payload)
        key = (tier, graph_path.encode("utf-8"), payload)
        occurrences.setdefault(precise, []).append({
            "selectionKey": key,
            "payload": payload,
            "symbol": symbol,
            "graphPath": graph_path,
            "ownershipTier": tier,
        })

canonical_symbols = {
    precise: min(values, key=lambda item: item["selectionKey"])["symbol"]
    for precise, values in occurrences.items()
}
duplicate_occurrences = raw_symbol_count - len(canonical_symbols)
conflicting_duplicates = sum(
    len({item["payload"] for item in values}) > 1
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
duplicate_relationships = raw_relationship_count - len(set(relationship_payloads))
if graph_manifest.get("duplicateRelationshipOccurrenceCount") != duplicate_relationships:
    fail("duplicate relationship occurrence count differs")
symbol_multiset_hash = multiset_hash(
    b"OpenUIKit.SymbolGraph.SymbolMultiset.v1\0", symbol_payloads
)
relationship_multiset_hash = multiset_hash(
    b"OpenUIKit.SymbolGraph.RelationshipMultiset.v1\0", relationship_payloads
)
if graph_manifest.get("symbolMultisetSHA256") != symbol_multiset_hash:
    fail("symbol semantic multiset hash differs")
if graph_manifest.get("relationshipMultisetSHA256") != relationship_multiset_hash:
    fail("relationship semantic multiset hash differs")
if provenance.get("symbolGraphSymbolMultisetSHA256") != symbol_multiset_hash:
    fail("provenance symbol semantic multiset hash differs")
if provenance.get("symbolGraphRelationshipMultisetSHA256") != relationship_multiset_hash:
    fail("provenance relationship semantic multiset hash differs")

def escaped(value):
    return value.replace("\\", "\\\\").replace("\t", "\\t").replace("\n", "\\n").replace("\r", "\\r")

def expected_surface_row(precise, symbol):
    kind_object = symbol.get("kind")
    kind = kind_object.get("identifier", "") if isinstance(kind_object, dict) else ""
    names = symbol.get("names")
    title = names.get("title", "") if isinstance(names, dict) else ""
    components = symbol.get("pathComponents")
    if not isinstance(kind, str) or not kind or re.search(r"[\x00-\x1f\x7f]", kind):
        fail(f"unsafe symbol kind for {precise}")
    if not isinstance(components, list) or not all(isinstance(item, str) for item in components):
        fail(f"invalid symbol path for {precise}")
    fragments = symbol.get("declarationFragments")
    if not isinstance(fragments, list):
        fragments = []
    declaration = "".join(
        fragment.get("spelling", "")
        for fragment in fragments
        if isinstance(fragment, dict) and isinstance(fragment.get("spelling", ""), str)
    )
    return [precise, kind, escaped(title), escaped(".".join(components)), escaped(declaration)]

conflict_rows = []
payload_by_digest = {}
for precise, values in occurrences.items():
    if len({item["payload"] for item in values}) <= 1:
        continue
    canonical = min(values, key=lambda item: item["selectionKey"])
    grouped = {}
    for occurrence in values:
        group_key = (
            occurrence["payload"], occurrence["graphPath"], occurrence["ownershipTier"]
        )
        grouped.setdefault(group_key, []).append(occurrence)
    for (payload, graph_path, ownership_tier), group in grouped.items():
        payload_digest = hashlib.sha256(payload).hexdigest()
        previous = payload_by_digest.setdefault(payload_digest, payload)
        if previous != payload:
            fail("SHA-256 collision between distinct symbol payloads")
        selected = (
            payload == canonical["payload"]
            and graph_path == canonical["graphPath"]
            and ownership_tier == canonical["ownershipTier"]
        )
        surface = expected_surface_row(precise, group[0]["symbol"])
        row = [
            precise, payload_digest, graph_path, str(ownership_tier), str(len(group)),
            "1" if selected else "0", surface[1], surface[2], surface[3], surface[4]
        ]
        conflict_rows.append((
            (precise.encode("utf-8"), ownership_tier, graph_path.encode("utf-8"), payload),
            row
        ))
expected_conflict_rows = [row for _key, row in sorted(conflict_rows)]
actual_conflict_rows = read_tsv(framework["symbolConflicts"], [
    "precise", "payloadSHA256", "graphPath", "ownershipTier",
    "occurrenceCount", "canonicalSelection", "kind", "title", "symbolPath",
    "declaration"
])
if actual_conflict_rows != expected_conflict_rows:
    fail("symbol conflict ledger does not match raw graphs")

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

graph_kind_to_decl_kinds = {
    "swift.associatedtype": {"AssociatedType"}, "swift.class": {"Class"},
    "swift.deinit": {"Destructor"}, "swift.enum": {"Enum"},
    "swift.enum.case": {"EnumElement"}, "swift.func": {"Func"},
    "swift.func.op": {"Func"}, "swift.init": {"Constructor"},
    "swift.ivar": {"Var"}, "swift.macro": {"Macro"},
    "swift.method": {"Func"}, "swift.method.op": {"Func"},
    "swift.operator": {"Operator"}, "swift.precedencegroup": {"PrecedenceGroup"},
    "swift.property": {"Var"}, "swift.protocol": {"Protocol"},
    "swift.struct": {"Struct"}, "swift.subscript": {"Subscript"},
    "swift.type.method": {"Func"}, "swift.type.method.op": {"Func"},
    "swift.type.property": {"Var"}, "swift.type.subscript": {"Subscript"},
    "swift.typealias": {"TypeAlias"}, "swift.var": {"Var"},
}
type_member_kinds = {
    "swift.type.method", "swift.type.method.op", "swift.type.property",
    "swift.type.subscript"
}
instance_member_kinds = {
    "swift.method", "swift.method.op", "swift.property", "swift.subscript"
}
usr_records = {}
import_records = {}
for record in api_declarations:
    node = record["node"]
    usr = node.get("usr")
    if isinstance(usr, str):
        usr_records.setdefault(usr, []).append(record)
    attributes = node.get("declAttributes")
    if (
        record["directRootChild"] and node.get("declKind") == "Import"
        and node.get("moduleName") == framework["module"] and usr is None
        and isinstance(attributes, list) and "Exported" in attributes
        and node.get("name") == node.get("printedName")
        and isinstance(node.get("name"), str)
        and node["name"].startswith(f"{framework['module']}.")
    ):
        import_records.setdefault(node["name"], []).append(record)
graph_facts = {}
for precise, symbol in canonical_symbols.items():
    kind_object = symbol.get("kind")
    graph_kind = kind_object.get("identifier") if isinstance(kind_object, dict) else None
    graph_path = symbol.get("pathComponents")
    if not isinstance(graph_kind, str) or not graph_kind:
        fail(f"crosswalk graph kind is invalid for {precise}")
    if not isinstance(graph_path, list) or not all(
        isinstance(component, str) and not re.search(r"[\x00-\x1f\x7f]", component)
        for component in graph_path
    ):
        fail(f"crosswalk graph path is invalid for {precise}")
    graph_facts[precise] = (graph_kind, tuple(graph_path))
graph_import_key_counts = {}
for _kind, graph_path in graph_facts.values():
    import_key = f"{framework['module']}." + ".".join(graph_path)
    graph_import_key_counts[import_key] = graph_import_key_counts.get(import_key, 0) + 1
crosswalk_counts = {"exact-usr": 0, "import-name": 0, "ambiguous": 0, "unmatched": 0}
expected_crosswalk_rows = []
for precise in sorted(canonical_symbols, key=lambda value: value.encode("utf-8")):
    graph_kind, graph_path = graph_facts[precise]
    exact_records = usr_records.get(precise, [])
    owned = [
        record for record in exact_records
        if record["node"].get("moduleName") == framework["module"]
        and record["node"].get("declKind") != "Import"
    ]
    foreign = [
        record for record in exact_records
        if record["node"].get("moduleName") != framework["module"]
    ]
    selected = None
    candidates = []
    compatible = []
    basis = "none"
    if owned:
        basis = "exact-usr"
        candidates = owned
        expected_decl_kinds = graph_kind_to_decl_kinds.get(graph_kind, set())
        compatible = [
            record for record in owned
            if record["node"].get("declKind") in expected_decl_kinds
            and not (
                graph_kind in type_member_kinds
                and record["node"].get("static") is not True
            )
            and not (
                graph_kind in instance_member_kinds
                and record["node"].get("static") is True
            )
        ]
        if len(compatible) > 1:
            path_matches = [
                record for record in compatible if record["logicalPath"] == graph_path
            ]
            if path_matches:
                compatible = path_matches
        if len(compatible) == 1:
            selected = compatible[0]
            status = "exact-usr"
        else:
            status = "ambiguous"
    elif foreign:
        basis = "foreign-usr"
        candidates = foreign
        status = "ambiguous"
    else:
        import_key = f"{framework['module']}." + ".".join(graph_path)
        candidates = import_records.get(import_key, [])
        compatible = candidates
        if candidates:
            basis = "exported-import-name"
            if len(candidates) == 1 and graph_import_key_counts[import_key] == 1:
                selected = candidates[0]
                status = "import-name"
            else:
                status = "ambiguous"
        else:
            status = "unmatched"
    crosswalk_counts[status] += 1
    candidate_paths = sorted(
        (record["nodePath"] for record in candidates),
        key=lambda value: value.encode("utf-8")
    )
    expected_crosswalk_rows.append([
        precise, graph_kind,
        json.dumps(list(graph_path), ensure_ascii=False, separators=(",", ":")),
        status, basis, str(len(candidates)), str(len(compatible)),
        selected["nodePath"] if selected is not None else "",
        json.dumps(candidate_paths, ensure_ascii=False, separators=(",", ":")),
    ])
actual_crosswalk_rows = read_tsv(framework["apiCrosswalk"], [
    "precise", "graphKind", "graphPath", "status", "basis",
    "rawCandidateCount", "compatibleCandidateCount", "selectedNodePath",
    "candidateNodePaths"
])
if actual_crosswalk_rows != expected_crosswalk_rows:
    fail("API crosswalk does not match graph/API declaration facts")
provenance_crosswalk_counts = {
    "exact-usr": provenance.get("apiCrosswalkExactUSRCount"),
    "import-name": provenance.get("apiCrosswalkImportNameCount"),
    "ambiguous": provenance.get("apiCrosswalkAmbiguousCount"),
    "unmatched": provenance.get("apiCrosswalkUnmatchedCount"),
}
if provenance_crosswalk_counts != crosswalk_counts:
    fail("API crosswalk provenance counts differ")

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
structured_claims = []
for number, (precise, status, evidence, notes) in enumerate(coverage[1:], 2):
    if status not in allowed:
        fail(f"invalid coverage status for {precise}: {status}")
    if status in ("implemented", "declared"):
        nondeferred += 1
        if not evidence.strip():
            fail(f"nondeferred row lacks evidence: {precise}")
        structured_claims.append((number, status, evidence))
    elif not notes.strip():
        fail(f"coverage.tsv:{number}: {status} row needs an explanatory note")
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
load_smoke = confined(f"tests/agent/{framework['module']}LoadSmoke.swift")
load_smoke_text = load_smoke.read_text(encoding="utf-8")
expected_load_smoke = (
    f"import {framework['module']}\n\n"
    f"let frameworkLoadSmokeMarker = \"{framework['runtimeMarker']}\"\n"
)
if load_smoke_text != expected_load_smoke:
    fail("schema-v2 load smoke differs from canonical import/marker source")

guest_source_set = set(source_relatives)
framework_prefix = f"full/{framework['slug']}/"
test_prefix = framework_prefix + "tests/agent/"
for number, status, evidence in structured_claims:
    evidence_prefix = "test:" if status == "implemented" else "source:"
    if not evidence.startswith(evidence_prefix):
        fail(
            f"coverage.tsv:{number}: {status} evidence must start with "
            f"{evidence_prefix!r}"
        )
    body = evidence[len(evidence_prefix):]
    relative_text, separator, anchor = body.rpartition("#")
    if (
        not separator
        or not safe_relative_text(relative_text)
        or re.fullmatch(r"[A-Za-z_][A-Za-z0-9_]*", anchor) is None
    ):
        fail(
            f"coverage.tsv:{number}: evidence must be a safe repo path plus "
            "#identifier"
        )
    if not relative_text.startswith(framework_prefix):
        fail(
            f"coverage.tsv:{number}: evidence path must be beneath "
            f"{framework_prefix}"
        )
    evidence_path = repo_file(relative_text)
    try:
        evidence_text = evidence_path.read_text(encoding="utf-8")
    except (OSError, UnicodeError):
        fail(f"coverage.tsv:{number}: evidence source is unreadable")
    evidence_code = swift_code_projection(evidence_text)

    if status == "declared":
        if relative_text not in guest_source_set:
            fail(
                f"coverage.tsv:{number}: declared evidence must cite a product source"
            )
        if re.search(rf"\b{re.escape(anchor)}\b", evidence_code) is None:
            fail(
                f"coverage.tsv:{number}: declared evidence anchor is absent from Swift code"
            )
        continue

    if (
        not relative_text.startswith(test_prefix)
        or not relative_text.endswith("Tests.swift")
        or not anchor.startswith("test")
    ):
        fail(
            f"coverage.tsv:{number}: implemented evidence must cite a test* "
            "function in tests/agent/*Tests.swift"
        )
    declaration_pattern = re.compile(
        rf"(?m)^[ \t]*func[ \t]+{re.escape(anchor)}[ \t]*"
        r"\([ \t]*\)[ \t\r\n]*(?:->[ \t]*Void[ \t\r\n]*)?\{"
    )
    if declaration_pattern.search(evidence_code) is None:
        fail(
            f"coverage.tsv:{number}: implemented evidence must define a top-level "
            "synchronous no-argument test function"
        )

if framework["dependencies"]:
    identity = confined(f"tests/agent/{framework['module']}DependencyIdentity.swift")
    identity_text = identity.read_text(encoding="utf-8")
    for dependency in [framework["module"], *framework["dependencies"]]:
        if not re.search(rf"(?m)^\s*(?:@testable\s+)?import\s+{re.escape(dependency)}\s*$", identity_text):
            fail(f"dependency identity probe does not import {dependency}")

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

python3 -B - "$FRAMEWORK_ROOT/coverage.tsv" "$TMP/main.swift" \
    "$MODULE" "$MARKER" <<'PY'
import csv
import json
from pathlib import Path
import re
import sys

coverage_path = Path(sys.argv[1])
output_path = Path(sys.argv[2])
module = sys.argv[3]
marker = sys.argv[4]
if re.fullmatch(r"[A-Za-z_][A-Za-z0-9_]*", module) is None:
    raise SystemExit("invalid module in runner generation")
if re.fullmatch(r"[A-Z0-9_]+_AGENT_RUNTIME_OK", marker) is None:
    raise SystemExit("invalid marker in runner generation")
with coverage_path.open(encoding="utf-8", newline="") as handle:
    rows = list(csv.reader(handle, delimiter="\t"))
tests = []
for row in rows[1:]:
    if len(row) != 4 or row[1] != "implemented":
        continue
    anchor = row[2].rpartition("#")[2]
    if re.fullmatch(r"test[A-Za-z0-9_]*", anchor) is None:
        raise SystemExit(f"invalid implemented test anchor: {anchor!r}")
    tests.append(anchor)
tests = sorted(set(tests))
lines = [
    "import Glibc",
    f"import {module}",
    "",
    "guard let frameworkPath = getenv(\"OPENUIKIT_LOAD_DYLIB\") else {",
    '    fatalError("OPENUIKIT_LOAD_DYLIB is missing")',
    "}",
    "guard let frameworkHandle = dlopen(frameworkPath, RTLD_NOW | RTLD_LOCAL) else {",
    '    fatalError("framework dlopen failed")',
    "}",
]
lines.extend(f"{name}()" for name in tests)
lines.extend(
    [
        "_ = dlclose(frameworkHandle)",
        f"print({json.dumps(marker)})",
        "",
    ]
)
output_path.write_text("\n".join(lines), encoding="utf-8", newline="\n")
PY
mapfile -d '' -t TEST_PATHS < <(
    find "$FRAMEWORK_ROOT/tests/agent" -type f -name '*Tests.swift' -print0 \
        | sort -z
)
swiftc -warnings-as-errors -I "$TMP" \
    "$TMP/main.swift" \
    "${TEST_PATHS[@]}" \
    "$TMP/lib$MODULE.dylib" \
    -o "$TMP/guest-load-smoke"

printf '%s\n' "$MARKER" > "$TMP/expected.stdout"
OPENUIKIT_LOAD_DYLIB="$TMP/lib$MODULE.dylib" \
LD_LIBRARY_PATH="$TMP" \
    timeout --signal=TERM --kill-after=5s 120s \
    "$TMP/guest-load-smoke" > "$TMP/actual.stdout"
cmp -s "$TMP/expected.stdout" "$TMP/actual.stdout" \
    || die 'guest load smoke did not emit only the exact success marker bytes'

cat "$TMP/actual.stdout"
printf 'FRAMEWORK_FANOUT_HOST_OK module=%s dylib=lib%s.dylib\n' "$MODULE" "$MODULE"
