#!/usr/bin/env python3
"""Validate an immutable framework seed or a cloud-agent deliverable.

This deliberately has no third-party dependencies.  It is run both before a
framework is handed to an agent and from the framework's acceptance script
after the agent has produced a starting implementation.
"""

from __future__ import annotations

import argparse
import csv
import hashlib
import json
import os
import re
import struct
import sys
from pathlib import Path, PurePosixPath
from typing import Any, Iterable, Sequence


SCHEMA = 1
FRAMEWORK_SCHEMAS = {1, 2}
OPTIONAL_FRAMEWORK_METADATA_KEYS = {"moduleLocation", "roadmap"}
MODULE_LOCATION_KEYS = {"kind", "sdkRelativePath", "reason"}
MODULE_LOCATION_KINDS = {
    "framework",
    "framework-clang-module",
    "swift-module",
    "clang-module",
    "clang-submodule",
}
ROADMAP_OPERATOR_OVERRIDE = "none (operator override)"
ROADMAP_OPERATOR_OVERRIDE_RECORD = {"roadmap": ROADMAP_OPERATOR_OVERRIDE}
EXTERNAL_EVIDENCE_LOCK = "full/framework-fanout/external-evidence-sources.json"
EXTERNAL_POLICY_KEYS = {
    "behaviorAuthority",
    "conflictRule",
    "copyRule",
    "declarationPrecedence",
    "runtimeRule",
}
EXTERNAL_POLICY_SEQUENCE_KEYS = {
    "behaviorAuthority",
    "declarationPrecedence",
}
EXTERNAL_POLICY_TEXT_KEYS = EXTERNAL_POLICY_KEYS - EXTERNAL_POLICY_SEQUENCE_KEYS
EXTERNAL_SOURCE_KEYS = {
    "capabilities",
    "commit",
    "environmentVariable",
    "id",
    "licensePath",
    "licenseSHA256",
    "licenseSummary",
    "repository",
    "sourcePathTemplates",
}
EXTERNAL_SOURCE_ID_RE = re.compile(r"^[a-z0-9]+(?:-[a-z0-9]+)*$")
EXTERNAL_ENVIRONMENT_RE = re.compile(r"^OPENUIKIT_[A-Z0-9]+(?:_[A-Z0-9]+)*$")
EXTERNAL_REPOSITORY_RE = re.compile(
    r"^https://github\.com/[A-Za-z0-9_.-]+/[A-Za-z0-9_.-]+\.git$"
)
SYMBOL_GRAPH_SCOPE_PATH = "reference/symbol-graph-scope.json"
SYMBOL_GRAPH_REPRODUCIBILITY_PATH = (
    "reference/symbol-graph-reproducibility.json"
)
SCOPED_GENERATOR_PATH = "scripts/framework-fanout/generate_seed_v2_scoped.py"
BASE_V2_GENERATOR_PATH = "scripts/framework-fanout/generate_seed_v2.py"
SYMBOL_GRAPH_SCOPE_POLICY = (
    "base-module-and-extension-graphs-with-exact-cross-import-overlay-"
    "exclusions-v1"
)
SYMBOL_GRAPH_SCOPE_KEYS = {
    "schema",
    "policy",
    "requestedModule",
    "approvedExcludedCrossImportOverlayModules",
    "includedFiles",
    "excludedFiles",
    "includedFileCount",
    "includedSymbolOccurrenceCount",
    "includedRelationshipOccurrenceCount",
    "excludedFileCount",
    "excludedSymbolOccurrenceCount",
    "excludedRelationshipOccurrenceCount",
    "rawExtractorFileCount",
    "rawExtractorSymbolOccurrenceCount",
    "rawExtractorRelationshipOccurrenceCount",
    "sourceGenerator",
    "baseRelationshipProjection",
}
SYMBOL_GRAPH_SCOPE_RECORD_KEYS = {
    "fileName",
    "sha256",
    "symbolCount",
    "relationshipCount",
    "graphModule",
    "bystanders",
    "crossImportOverlayModule",
}
SYMBOL_GRAPH_REPRODUCIBILITY_POLICY = (
    "three-fresh-extractions-with-raw-volatility-and-stable-derived-evidence-v1"
)
BASE_RELATIONSHIP_PROJECTION_POLICY = (
    "exclude-primary-imported-objc-class-conformsTo-swift-sendable-v1"
)
BASE_RELATIONSHIP_PROJECTION_REASON = (
    "Xcode 26.1 nondeterministically assigns inherited Swift Sendable "
    "conformance relationships among imported Objective-C MapKit classes"
)
PROJECTED_RELATIONSHIP_MULTISET_DOMAIN = (
    b"OpenUIKit.SymbolGraph.ScopedStableRelationshipProjection.v1\0"
)
EXCLUDED_RELATIONSHIP_MULTISET_DOMAIN = (
    b"OpenUIKit.SymbolGraph.ScopedExcludedRelationshipMultiset.v1\0"
)
SENDABLE_TARGETS = {
    "s:s16SendableMetatypeP": "Swift.SendableMetatype",
    "s:s8SendableP": "Swift.Sendable",
}
CANONICAL_REPRODUCIBILITY_OUTPUT_PATHS = (
    "reference/public-surface.tsv",
    "reference/api-digester.json",
    "reference/api-crosswalk.tsv",
    "reference/symbol-conflicts.tsv",
    "reference/tbd-exports.tsv",
    "reference/sdk-inputs.tsv",
    "reference/corpus-summary.json",
    "reference/external-evidence.json",
)
BASE_RELATIONSHIP_PROJECTION_KEYS = {
    "schema",
    "policy",
    "reason",
    "primaryGraphFileName",
    "targets",
    "rawRelationshipOccurrenceCount",
    "rawRelationshipMultisetSHA256",
    "projectedRelationshipOccurrenceCount",
    "projectedRelationshipMultisetSHA256",
    "excludedRelationshipOccurrenceCount",
    "excludedRelationshipMultisetSHA256",
    "excludedRows",
}
BASE_RELATIONSHIP_PROJECTION_ROW_KEYS = {
    "relationship",
    "canonicalSHA256",
    "source",
    "target",
    "targetFallback",
    "sourceOrigin",
    "count",
    "multisetSHA256",
    "reason",
}
REPRODUCIBILITY_KEYS = {
    "schema",
    "policy",
    "requestedModule",
    "runCount",
    "minimumRequiredDistinctRawRelationshipHashes",
    "observedDistinctRawRelationshipHashCount",
    "canonicalOutputPaths",
    "stable",
    "runs",
}
REPRODUCIBILITY_RUN_KEYS = {
    "run",
    "graphRoot",
    "includedFiles",
    "excludedFiles",
    "extraction",
    "uniqueSymbolCount",
    "symbolOccurrenceCount",
    "symbolMultisetSHA256",
    "rawRelationshipOccurrenceCount",
    "rawRelationshipMultisetSHA256",
    "baseRelationshipProjection",
    "canonicalOutputs",
}
REPRODUCIBILITY_STABLE_KEYS = {
    "uniqueSymbolCount",
    "symbolOccurrenceCount",
    "symbolMultisetSHA256",
    "projectedRelationshipOccurrenceCount",
    "projectedRelationshipMultisetSHA256",
    "canonicalOutputSHA256",
}
REPRODUCIBILITY_CANONICAL_OUTPUT_KEYS = {
    "sourcePath",
    "retainedPath",
    "sha256",
}
REPRODUCIBILITY_EXTRACTION_KEYS = {
    "xcodeVersion",
    "xcodeBuild",
    "sdkName",
    "sdkVersion",
    "target",
    "symbolGraphExtractorPath",
    "symbolGraphExtractorSHA256",
    "symbolGraphExtractorVersion",
    "commandTemplate",
    "temporaryPathPolicy",
    "environmentPolicy",
}
LANES = {
    "leaf-full",
    "medium-full",
    "large-partitioned",
    "legacy-adapter",
}
ALLOWED_STATUSES = [
    "implemented",
    "declared",
    "deferred",
    "unavailable",
    "not-applicable",
]
NONDEFERRED_STATUSES = ["implemented", "declared"]
COVERAGE_HEADER = ["precise", "status", "evidence", "notes"]
ORACLE_HEADER = ["precise", "question", "risk", "reason"]
SURFACE_HEADER = ["precise", "kind", "title", "path", "declaration"]
TBD_HEADER = ["symbol", "sourceSDKRelativePath"]
SDK_INPUT_HEADER = ["category", "sdkRelativePath", "size", "sha256"]
CONFLICT_HEADER = [
    "precise",
    "payloadSHA256",
    "graphPath",
    "ownershipTier",
    "occurrenceCount",
    "canonicalSelection",
    "kind",
    "title",
    "symbolPath",
    "declaration",
]
CROSSWALK_HEADER = [
    "precise",
    "graphKind",
    "graphPath",
    "status",
    "basis",
    "rawCandidateCount",
    "compatibleCandidateCount",
    "selectedNodePath",
    "candidateNodePaths",
]
SDK_INPUT_CATEGORIES = {"header", "modulemap", "swiftinterface", "tbd"}
CANONICAL_SURFACE_POLICY_V1 = (
    "primary-module-graph_then-module-owned_then-utf8-path_then-"
    "canonical-payload_then-index-v1"
)
CANONICAL_SURFACE_POLICY_V2 = (
    "primary-module-graph_then-module-owned_then-utf8-path_then-"
    "canonical-payload-v2"
)
SEMANTIC_HASH_POLICY = "sorted-canonical-json-u64be-length-prefixed-sha256-v1"
SYMBOL_MULTISET_DOMAIN = b"OpenUIKit.SymbolGraph.SymbolMultiset.v1\0"
RELATIONSHIP_MULTISET_DOMAIN = b"OpenUIKit.SymbolGraph.RelationshipMultiset.v1\0"
GRAPH_KIND_TO_DECL_KINDS = {
    "swift.associatedtype": frozenset(("AssociatedType",)),
    "swift.class": frozenset(("Class",)),
    "swift.deinit": frozenset(("Destructor",)),
    "swift.enum": frozenset(("Enum",)),
    "swift.enum.case": frozenset(("EnumElement",)),
    "swift.func": frozenset(("Func",)),
    "swift.func.op": frozenset(("Func",)),
    "swift.init": frozenset(("Constructor",)),
    "swift.ivar": frozenset(("Var",)),
    "swift.macro": frozenset(("Macro",)),
    "swift.method": frozenset(("Func",)),
    "swift.method.op": frozenset(("Func",)),
    "swift.operator": frozenset(("Operator",)),
    "swift.precedencegroup": frozenset(("PrecedenceGroup",)),
    "swift.property": frozenset(("Var",)),
    "swift.protocol": frozenset(("Protocol",)),
    "swift.struct": frozenset(("Struct",)),
    "swift.subscript": frozenset(("Subscript",)),
    "swift.type.method": frozenset(("Func",)),
    "swift.type.method.op": frozenset(("Func",)),
    "swift.type.property": frozenset(("Var",)),
    "swift.type.subscript": frozenset(("Subscript",)),
    "swift.typealias": frozenset(("TypeAlias",)),
    "swift.var": frozenset(("Var",)),
}
TYPE_MEMBER_GRAPH_KINDS = frozenset(
    (
        "swift.type.method",
        "swift.type.method.op",
        "swift.type.property",
        "swift.type.subscript",
    )
)
INSTANCE_MEMBER_GRAPH_KINDS = frozenset(
    ("swift.method", "swift.method.op", "swift.property", "swift.subscript")
)
CONTAINER_DECL_KINDS = frozenset(
    ("Actor", "Class", "Enum", "Extension", "Protocol", "Struct")
)
CALLABLE_DECL_KINDS = frozenset(
    ("Constructor", "Destructor", "Func", "Operator", "Subscript")
)
API_LIST_FIELDS = frozenset(("accessors", "children", "conformances", "declAttributes"))
FORBIDDEN_API_KEY_NORMALIZATIONS = frozenset(("location", "toolarguments"))
SHA256_RE = re.compile(r"[0-9a-f]{64}\Z")
CONTROL_RE = re.compile(r"[\x00-\x1f\x7f]")
SLUG_RE = re.compile(r"[a-z][a-z0-9]*(?:-[a-z0-9]+)*\Z")
MODULE_RE = re.compile(r"[_A-Za-z][_A-Za-z0-9]*\Z")

BUILD_DIRECTORY_NAMES = {
    ".build",
    ".swiftpm",
    ".xcodebuild",
    "build",
    "Build",
    "DerivedData",
    "deriveddata",
    "scratch",
}
BUILD_FILE_SUFFIXES = {
    ".a",
    ".d",
    ".dia",
    ".dylib",
    ".o",
    ".pcm",
    ".profdata",
    ".so",
    ".swiftdoc",
    ".swiftmodule",
    ".swiftsourceinfo",
}


class InvalidSeed(Exception):
    """Raised for an error that prevents meaningful dependent checks."""


def sha256_file(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as stream:
        for chunk in iter(lambda: stream.read(1024 * 1024), b""):
            digest.update(chunk)
    return digest.hexdigest()


def is_int(value: Any) -> bool:
    return type(value) is int


def valid_external_policy(policy: Any) -> bool:
    """Accept only canonical, meaningful policy text and ordered sequences."""
    if type(policy) is not dict or set(policy) != EXTERNAL_POLICY_KEYS:
        return False
    for key in EXTERNAL_POLICY_TEXT_KEYS:
        value = policy[key]
        if type(value) is not str or not value.strip() or CONTROL_RE.search(value):
            return False
    for key in EXTERNAL_POLICY_SEQUENCE_KEYS:
        values = policy[key]
        if type(values) is not list or not values:
            return False
        if any(
            type(value) is not str
            or not value.strip()
            or CONTROL_RE.search(value)
            for value in values
        ):
            return False
        # Order carries precedence/authority meaning; duplicates are ambiguous.
        if len(values) != len(set(values)):
            return False
    return True


def normalized_runtime_marker(module: str) -> str:
    normalized = re.sub(r"[^A-Za-z0-9]+", "_", module).strip("_").upper()
    return f"{normalized}_AGENT_RUNTIME_OK"


def swift_code_projection(source: str) -> str:
    """Mask Swift comments and string/raw-regex literals, preserving layout."""

    characters = list(source)
    length = len(source)

    def mask(start: int, end: int) -> None:
        for index in range(start, end):
            if characters[index] not in {"\n", "\r"}:
                characters[index] = " "

    def quoted_end(start: int, hashes: int, quote_count: int) -> int:
        cursor = start + hashes + quote_count
        terminator = '"' * quote_count + "#" * hashes
        while cursor < length:
            if source.startswith(terminator, cursor):
                return cursor + len(terminator)
            if hashes == 0 and source[cursor] == "\\":
                cursor += min(2, length - cursor)
            else:
                cursor += 1
        raise ValueError("unterminated Swift string literal")

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
                raise ValueError("unterminated Swift block comment")
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
                raise ValueError("unterminated Swift raw-regex literal")
            end += len(terminator)
            mask(cursor, end)
            cursor = end
            continue
        cursor += 1
    return "".join(characters)


def tsv_escape(value: str) -> str:
    return (
        value.replace("\\", "\\\\")
        .replace("\t", "\\t")
        .replace("\n", "\\n")
        .replace("\r", "\\r")
    )


def canonical_json_bytes(value: Any, *, label: str) -> bytes:
    def validate(item: Any) -> None:
        if item is None or type(item) in (bool, int):
            return
        if isinstance(item, str):
            try:
                item.encode("utf-8")
            except UnicodeEncodeError as exc:
                raise ValueError(f"{label} contains an unpaired Unicode surrogate") from exc
            return
        if isinstance(item, list):
            for child in item:
                validate(child)
            return
        if isinstance(item, dict):
            for key, child in item.items():
                if not isinstance(key, str):
                    raise ValueError(f"{label} contains a non-string object key")
                validate(key)
                validate(child)
            return
        raise ValueError(
            f"{label} contains unsupported JSON value {type(item).__name__}"
        )

    validate(value)
    try:
        return json.dumps(
            value,
            ensure_ascii=False,
            sort_keys=True,
            separators=(",", ":"),
            allow_nan=False,
        ).encode("utf-8")
    except (TypeError, ValueError, UnicodeEncodeError) as exc:
        raise ValueError(f"cannot canonicalize {label}: {exc}") from exc


def semantic_multiset_sha256(domain: bytes, payloads: Sequence[bytes]) -> str:
    if len(payloads) >= 1 << 64:
        raise ValueError("semantic multiset has too many payloads")
    digest = hashlib.sha256()
    digest.update(domain)
    digest.update(struct.pack(">Q", len(payloads)))
    for payload in sorted(payloads):
        if len(payload) >= 1 << 64:
            raise ValueError("semantic multiset payload is too large")
        digest.update(struct.pack(">Q", len(payload)))
        digest.update(payload)
    return digest.hexdigest()


def compute_base_relationship_projection(
    documents: Sequence[tuple[str, dict[str, Any]]], module: str
) -> dict[str, Any]:
    """Recompute the scoped projection from immutable retained graph objects."""

    primary_name = f"{module}.symbols.json"
    primary = next(
        (graph for file_name, graph in documents if file_name == primary_name), None
    )
    if primary is None:
        raise ValueError(f"scoped primary graph is missing: {primary_name}")
    symbols = primary.get("symbols")
    if not isinstance(symbols, list):
        raise ValueError("scoped primary graph symbols must be a list")
    imported_objc_classes: set[str] = set()
    for index, symbol in enumerate(symbols):
        if not isinstance(symbol, dict):
            raise ValueError(f"scoped primary symbol[{index}] must be an object")
        identifier = symbol.get("identifier")
        precise = identifier.get("precise") if isinstance(identifier, dict) else None
        kind = symbol.get("kind")
        kind_identifier = kind.get("identifier") if isinstance(kind, dict) else None
        if (
            isinstance(precise, str)
            and precise.startswith("c:objc(cs)")
            and kind_identifier == "swift.class"
        ):
            imported_objc_classes.add(precise)

    raw_payloads: list[bytes] = []
    projected_payloads: list[bytes] = []
    excluded_payloads: list[bytes] = []
    excluded_by_payload: dict[bytes, tuple[dict[str, Any], int]] = {}
    for file_name, graph in documents:
        relationships = graph.get("relationships")
        if not isinstance(relationships, list):
            raise ValueError(f"scoped graph relationships must be a list: {file_name}")
        for index, relationship in enumerate(relationships):
            if not isinstance(relationship, dict):
                raise ValueError(
                    f"scoped relationship must be an object: {file_name}[{index}]"
                )
            payload = canonical_json_bytes(
                relationship,
                label=f"scoped relationship {file_name}[{index}]",
            )
            raw_payloads.append(payload)
            is_volatile = (
                file_name == primary_name
                and relationship.get("kind") == "conformsTo"
                and relationship.get("target") in SENDABLE_TARGETS
                and relationship.get("source") in imported_objc_classes
            )
            if not is_volatile:
                projected_payloads.append(payload)
                continue
            excluded_payloads.append(payload)
            previous = excluded_by_payload.get(payload)
            if previous is None:
                excluded_by_payload[payload] = (relationship, 1)
            else:
                excluded_by_payload[payload] = (previous[0], previous[1] + 1)

    excluded_rows: list[dict[str, Any]] = []
    for payload in sorted(excluded_by_payload):
        relationship, count = excluded_by_payload[payload]
        excluded_rows.append(
            {
                "relationship": relationship,
                "canonicalSHA256": hashlib.sha256(payload).hexdigest(),
                "source": relationship["source"],
                "target": relationship["target"],
                "targetFallback": relationship.get("targetFallback"),
                "sourceOrigin": relationship.get("sourceOrigin"),
                "count": count,
                "multisetSHA256": semantic_multiset_sha256(
                    EXCLUDED_RELATIONSHIP_MULTISET_DOMAIN, [payload] * count
                ),
                "reason": BASE_RELATIONSHIP_PROJECTION_REASON,
            }
        )
    return {
        "schema": 1,
        "policy": BASE_RELATIONSHIP_PROJECTION_POLICY,
        "reason": BASE_RELATIONSHIP_PROJECTION_REASON,
        "primaryGraphFileName": primary_name,
        "targets": [
            {"precise": precise, "fallback": SENDABLE_TARGETS[precise]}
            for precise in sorted(SENDABLE_TARGETS)
        ],
        "rawRelationshipOccurrenceCount": len(raw_payloads),
        "rawRelationshipMultisetSHA256": semantic_multiset_sha256(
            RELATIONSHIP_MULTISET_DOMAIN, raw_payloads
        ),
        "projectedRelationshipOccurrenceCount": len(projected_payloads),
        "projectedRelationshipMultisetSHA256": semantic_multiset_sha256(
            PROJECTED_RELATIONSHIP_MULTISET_DOMAIN, projected_payloads
        ),
        "excludedRelationshipOccurrenceCount": len(excluded_payloads),
        "excludedRelationshipMultisetSHA256": semantic_multiset_sha256(
            EXCLUDED_RELATIONSHIP_MULTISET_DOMAIN, excluded_payloads
        ),
        "excludedRows": excluded_rows,
    }


def compute_scoped_graph_summary(
    documents: Sequence[tuple[str, dict[str, Any]]], module: str
) -> dict[str, Any]:
    precise_ids: set[str] = set()
    symbol_payloads: list[bytes] = []
    symbol_occurrence_count = 0
    for file_name, graph in documents:
        symbols = graph.get("symbols")
        if not isinstance(symbols, list):
            raise ValueError(f"scoped graph symbols must be a list: {file_name}")
        for index, symbol in enumerate(symbols):
            if not isinstance(symbol, dict):
                raise ValueError(
                    f"scoped symbol must be an object: {file_name}[{index}]"
                )
            identifier = symbol.get("identifier")
            precise = identifier.get("precise") if isinstance(identifier, dict) else None
            if not isinstance(precise, str) or not precise:
                raise ValueError(
                    f"scoped symbol lacks precise identifier: {file_name}[{index}]"
                )
            precise_ids.add(precise)
            symbol_payloads.append(
                canonical_json_bytes(
                    symbol, label=f"scoped symbol {file_name}[{index}]"
                )
            )
            symbol_occurrence_count += 1
    projection = compute_base_relationship_projection(documents, module)
    return {
        "uniqueSymbolCount": len(precise_ids),
        "symbolOccurrenceCount": symbol_occurrence_count,
        "symbolMultisetSHA256": semantic_multiset_sha256(
            SYMBOL_MULTISET_DOMAIN, symbol_payloads
        ),
        "rawRelationshipOccurrenceCount": projection[
            "rawRelationshipOccurrenceCount"
        ],
        "rawRelationshipMultisetSHA256": projection[
            "rawRelationshipMultisetSHA256"
        ],
        "baseRelationshipProjection": projection,
    }


def symbol_surface_fields(precise: str, symbol: dict[str, Any]) -> list[str]:
    kind_object = symbol.get("kind")
    kind = kind_object.get("identifier", "") if isinstance(kind_object, dict) else ""
    names = symbol.get("names")
    title = names.get("title", "") if isinstance(names, dict) else ""
    path_components = symbol.get("pathComponents")
    if not isinstance(kind, str) or not kind or CONTROL_RE.search(kind):
        raise ValueError(f"unsafe kind for precise identifier {precise}")
    if not isinstance(title, str):
        title = ""
    if not isinstance(path_components, list) or not all(
        isinstance(component, str) for component in path_components
    ):
        raise ValueError(f"invalid path components for precise identifier {precise}")
    fragments = symbol.get("declarationFragments")
    declaration = ""
    if isinstance(fragments, list):
        declaration = "".join(
            fragment.get("spelling", "")
            for fragment in fragments
            if isinstance(fragment, dict)
            and isinstance(fragment.get("spelling", ""), str)
        )
    return [
        precise,
        kind,
        tsv_escape(title),
        tsv_escape(".".join(path_components)),
        tsv_escape(declaration),
    ]


def json_pointer_component(value: str) -> str:
    return value.replace("~", "~0").replace("/", "~1")


class Validator:
    """Validator with an injectable repository root for unit testing."""

    def __init__(self, repo_root: Path, framework: Path, phase: str) -> None:
        self.repo_root = repo_root.resolve()
        self.framework_argument = framework
        self.phase = phase
        self.framework: Path | None = None
        self.errors: list[str] = []
        self.metadata: dict[str, Any] | None = None
        self.precise_ids: list[str] = []
        self.surface_by_precise: dict[str, list[str]] = {}
        self.canonical_symbols: dict[str, dict[str, Any]] = {}
        self.guest_sources: set[str] = set()
        self.load_smoke_source = ""
        self._digest_cache: dict[Path, str] = {}

    def error(self, message: str) -> None:
        self.errors.append(message)

    def fatal(self, message: str) -> None:
        self.error(message)
        raise InvalidSeed(message)

    def _sha256(self, path: Path) -> str:
        """Hash each immutable input at most once during a validation run."""
        key = path.resolve()
        value = self._digest_cache.get(key)
        if value is None:
            value = sha256_file(path)
            self._digest_cache[key] = value
        return value

    def validate(self) -> list[str]:
        try:
            self._locate_framework()
            assert self.framework is not None
            self._scan_for_forbidden_artifacts()
            self._validate_seed()
            if self.phase == "deliverable":
                self._validate_deliverable()
        except InvalidSeed:
            pass
        return self.errors

    def _locate_framework(self) -> None:
        candidate = self.framework_argument
        if not candidate.is_absolute():
            candidate = Path.cwd() / candidate
        if not candidate.exists():
            self.fatal(f"framework directory does not exist: {candidate}")
        if candidate.is_symlink():
            self.fatal(f"framework directory must not be a symlink: {candidate}")
        try:
            resolved = candidate.resolve(strict=True)
        except OSError as exc:
            self.fatal(f"cannot resolve framework directory {candidate}: {exc}")
            return
        expected_parent = (self.repo_root / "full").resolve()
        if not resolved.is_dir() or resolved.parent != expected_parent:
            self.fatal(
                "--framework must name one direct full/<slug> directory inside "
                f"the repository: {resolved}"
            )
        if resolved.name == "framework-fanout" or not SLUG_RE.fullmatch(resolved.name):
            self.fatal(f"invalid framework slug: {resolved.name!r}")
        self.framework = resolved

    def _scan_for_forbidden_artifacts(self) -> None:
        assert self.framework is not None
        for root, directory_names, file_names in os.walk(
            self.framework, topdown=True, followlinks=False
        ):
            root_path = Path(root)
            for name in list(directory_names):
                path = root_path / name
                relative = path.relative_to(self.framework).as_posix()
                if path.is_symlink():
                    self.error(f"symlink is forbidden in framework tree: {relative}")
                    directory_names.remove(name)
                    continue
                if name in BUILD_DIRECTORY_NAMES:
                    self.error(f"build-product directory is forbidden: {relative}")
                    directory_names.remove(name)
            for name in file_names:
                path = root_path / name
                relative = path.relative_to(self.framework).as_posix()
                if path.is_symlink():
                    self.error(f"symlink is forbidden in framework tree: {relative}")
                    continue
                if path.suffix in BUILD_FILE_SUFFIXES or name == ".DS_Store":
                    self.error(f"build product is forbidden: {relative}")
                    continue
                try:
                    with path.open("rb") as stream:
                        magic = stream.read(4)
                except OSError as exc:
                    self.error(f"cannot inspect {relative}: {exc}")
                    continue
                if magic == b"\x7fELF" or magic in {
                    b"\xca\xfe\xba\xbe",
                    b"\xce\xfa\xed\xfe",
                    b"\xcf\xfa\xed\xfe",
                    b"\xfe\xed\xfa\xce",
                    b"\xfe\xed\xfa\xcf",
                }:
                    self.error(f"compiled binary is forbidden: {relative}")

    def _framework_file(self, relative: str, *, must_exist: bool = True) -> Path:
        assert self.framework is not None
        posix = PurePosixPath(relative)
        if (
            not relative
            or "\\" in relative
            or posix.is_absolute()
            or any(part in {"", ".", ".."} for part in posix.parts)
        ):
            self.fatal(f"unsafe framework-relative path: {relative!r}")
        path = self.framework.joinpath(*posix.parts)
        if must_exist and not path.exists():
            self.fatal(f"required file is missing: {relative}")
        if path.is_symlink():
            self.fatal(f"required file must not be a symlink: {relative}")
        if must_exist:
            try:
                resolved = path.resolve(strict=True)
                resolved.relative_to(self.framework)
            except (OSError, ValueError):
                self.fatal(f"path escapes framework directory: {relative}")
            if not path.is_file():
                self.fatal(f"required path is not a regular file: {relative}")
        return path

    def _repo_file(self, relative: str) -> Path:
        posix = PurePosixPath(relative)
        if (
            not relative
            or "\\" in relative
            or posix.is_absolute()
            or any(part in {"", ".", ".."} for part in posix.parts)
        ):
            self.fatal(f"unsafe repository-relative path: {relative!r}")
        path = self.repo_root.joinpath(*posix.parts)
        if not path.exists() or path.is_symlink() or not path.is_file():
            self.fatal(f"referenced repository file is missing or unsafe: {relative}")
        try:
            path.resolve(strict=True).relative_to(self.repo_root)
        except (OSError, ValueError):
            self.fatal(f"referenced repository path escapes root: {relative}")
        return path

    def _read_json(self, relative: str) -> Any:
        path = self._framework_file(relative)
        try:
            with path.open("r", encoding="utf-8") as stream:
                return json.load(stream)
        except (OSError, UnicodeError, json.JSONDecodeError) as exc:
            self.fatal(f"invalid JSON in {relative}: {exc}")

    def _read_strict_json(self, relative: str) -> Any:
        path = self._framework_file(relative)

        def reject_pairs(pairs: list[tuple[str, Any]]) -> dict[str, Any]:
            result: dict[str, Any] = {}
            for key, value in pairs:
                if key in result:
                    raise ValueError(f"duplicate JSON key {key!r}")
                result[key] = value
            return result

        def reject_number(token: str) -> Any:
            raise ValueError(f"forbidden JSON number {token!r}")

        try:
            return json.loads(
                path.read_text(encoding="utf-8"),
                object_pairs_hook=reject_pairs,
                parse_float=reject_number,
                parse_constant=reject_number,
            )
        except (OSError, UnicodeError, json.JSONDecodeError, ValueError) as exc:
            self.fatal(f"invalid strict JSON in {relative}: {exc}")

    def _read_tsv(self, relative: str, expected_header: Sequence[str]) -> list[list[str]]:
        path = self._framework_file(relative)
        try:
            raw = path.read_bytes()
            text = raw.decode("utf-8")
        except (OSError, UnicodeError) as exc:
            self.fatal(f"cannot read UTF-8 TSV {relative}: {exc}")
        if b"\x00" in raw:
            self.fatal(f"NUL byte is forbidden in TSV: {relative}")
        if not raw.endswith(b"\n"):
            self.error(f"TSV must end in a newline: {relative}")
        rows = list(csv.reader(text.splitlines(), delimiter="\t", quoting=csv.QUOTE_NONE))
        if not rows or rows[0] != list(expected_header):
            actual = rows[0] if rows else []
            self.fatal(
                f"wrong TSV header in {relative}: expected {list(expected_header)!r}, "
                f"got {actual!r}"
            )
        width = len(expected_header)
        for number, row in enumerate(rows[1:], start=2):
            if len(row) != width:
                self.error(
                    f"{relative}:{number}: expected {width} columns, got {len(row)}"
                )
        if any(len(row) != width for row in rows[1:]):
            raise InvalidSeed(f"malformed TSV: {relative}")
        return rows[1:]

    def _validate_seed(self) -> None:
        for relative in (
            "AGENTS.md",
            "FANOUT_TASK.md",
            "reference/framework.json",
            "reference/symbol-graphs.json",
            "reference/public-surface.tsv",
            "reference/tbd-exports.tsv",
            "reference/sdk-inputs.tsv",
            "reference/corpus-summary.json",
            "reference/seed-files.sha256",
            "reference/immutable-files.sha256",
            "tests/acceptance/test_host.sh",
        ):
            self._framework_file(relative)

        metadata = self._read_json("reference/framework.json")
        if not isinstance(metadata, dict):
            self.fatal("reference/framework.json must contain an object")
        self.metadata = metadata
        framework_schema = metadata.get("schema")
        if framework_schema == 2:
            self._framework_file("reference/api-digester.json")
            self._framework_file("reference/api-crosswalk.tsv")
            self._framework_file("reference/symbol-conflicts.tsv")
            self._framework_file("reference/external-evidence.json")
        self._validate_framework_metadata(metadata)
        graph_files = self._validate_symbol_graphs(metadata)
        scope_candidate = self._framework_file(
            SYMBOL_GRAPH_SCOPE_PATH, must_exist=False
        )
        reproducibility_candidate = self._framework_file(
            SYMBOL_GRAPH_REPRODUCIBILITY_PATH, must_exist=False
        )
        has_scope = scope_candidate.exists() or scope_candidate.is_symlink()
        has_reproducibility = (
            reproducibility_candidate.exists()
            or reproducibility_candidate.is_symlink()
        )
        provenance = metadata.get("provenance")
        generator_path = (
            provenance.get("generatorPath") if isinstance(provenance, dict) else None
        )
        if generator_path == SCOPED_GENERATOR_PATH and not has_scope:
            self.error(
                f"scoped generator requires {SYMBOL_GRAPH_SCOPE_PATH}"
            )
        elif has_scope and generator_path != SCOPED_GENERATOR_PATH:
            self.error(
                "symbol-graph scope provenance requires the scoped generator"
            )
        if generator_path == SCOPED_GENERATOR_PATH and not has_reproducibility:
            self.error(
                f"scoped generator requires {SYMBOL_GRAPH_REPRODUCIBILITY_PATH}"
            )
        elif has_reproducibility and generator_path != SCOPED_GENERATOR_PATH:
            self.error(
                "symbol-graph reproducibility provenance requires the scoped generator"
            )
        if has_scope:
            self._framework_file(SYMBOL_GRAPH_SCOPE_PATH)
            self._validate_symbol_graph_scope(metadata, graph_files)
        self._validate_public_surface(metadata)
        if framework_schema == 2:
            self._validate_api_digester(metadata)
        self._validate_tbd_exports(metadata)
        self._validate_sdk_inputs(metadata)
        self._validate_corpus(metadata)
        if framework_schema == 2:
            self._validate_external_evidence(metadata)

        seed_expected = {
            "reference/symbol-graphs.json",
            "reference/public-surface.tsv",
            "reference/tbd-exports.tsv",
            "reference/sdk-inputs.tsv",
            "reference/corpus-summary.json",
            *graph_files,
        }
        if framework_schema == 2:
            seed_expected |= {
                "reference/api-digester.json",
                "reference/api-crosswalk.tsv",
                "reference/symbol-conflicts.tsv",
                "reference/external-evidence.json",
            }
        self._validate_digest("reference/seed-files.sha256", seed_expected)

        assert self.framework is not None
        reference_files = {
            path.relative_to(self.framework).as_posix()
            for path in (self.framework / "reference").rglob("*")
            if path.is_file()
            and path.relative_to(self.framework).as_posix()
            != "reference/immutable-files.sha256"
        }
        immutable_expected = {
            "AGENTS.md",
            "FANOUT_TASK.md",
            "tests/acceptance/test_host.sh",
            *reference_files,
        }
        self._validate_digest("reference/immutable-files.sha256", immutable_expected)

    def _validate_framework_metadata(self, metadata: dict[str, Any]) -> None:
        assert self.framework is not None
        framework_schema = metadata.get("schema")
        expected_keys = {
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
        if framework_schema == 2:
            expected_keys |= {
                "apiCrosswalk",
                "apiDigester",
                "externalEvidence",
                "symbolConflicts",
            }
        actual_keys = set(metadata)
        missing = expected_keys - actual_keys
        extra = actual_keys - expected_keys - OPTIONAL_FRAMEWORK_METADATA_KEYS
        if missing or extra:
            self.error(
                f"reference/framework.json keys differ from schema v{framework_schema}: "
                f"missing={sorted(missing)}, extra={sorted(extra)}"
            )
        if type(framework_schema) is not int or framework_schema not in FRAMEWORK_SCHEMAS:
            self.error(
                f"framework schema must be one of {sorted(FRAMEWORK_SCHEMAS)}"
            )
        module = metadata.get("module")
        slug = metadata.get("slug")
        if not isinstance(module, str) or not MODULE_RE.fullmatch(module):
            self.error(f"invalid Swift module name in framework metadata: {module!r}")
        if slug != self.framework.name:
            self.error(
                f"framework slug {slug!r} does not match directory {self.framework.name!r}"
            )
        if metadata.get("lane") not in LANES:
            self.error(f"invalid framework lane: {metadata.get('lane')!r}")
        risks = metadata.get("risks")
        if not isinstance(risks, list) or any(
            not isinstance(risk, str) or not risk.strip() for risk in risks
        ):
            self.error("risks must be a list of nonempty strings")
        elif len(set(risks)) != len(risks):
            self.error("risks must not contain duplicates")
        dependencies = metadata.get("dependencies")
        if not isinstance(dependencies, list) or any(
            not isinstance(dependency, str) or not MODULE_RE.fullmatch(dependency)
            for dependency in dependencies
        ):
            self.error("dependencies must be a list of exact module tokens")
        elif dependencies != sorted(set(dependencies)):
            self.error("dependencies must be sorted and unique")
        elif module in dependencies:
            self.error("dependencies must not contain the framework module itself")
        for key in ("symbolCount", "relationshipCount"):
            value = metadata.get(key)
            if not is_int(value) or value < 0:
                self.error(f"{key} must be a nonnegative integer")
        fixed_paths = {
            "symbolGraph": "reference/symbol-graphs.json",
            "publicSurface": "reference/public-surface.tsv",
            "tbdExports": "reference/tbd-exports.tsv",
            "corpusSummary": "reference/corpus-summary.json",
            "sdkInputs": "reference/sdk-inputs.tsv",
            "guestManifest": f"{self.framework.name}_guest_sources.txt",
        }
        if framework_schema == 2:
            fixed_paths |= {
                "apiCrosswalk": "reference/api-crosswalk.tsv",
                "apiDigester": "reference/api-digester.json",
                "externalEvidence": "reference/external-evidence.json",
                "symbolConflicts": "reference/symbol-conflicts.tsv",
            }
        for key, expected in fixed_paths.items():
            if metadata.get(key) != expected:
                self.error(f"{key} must be {expected!r}, got {metadata.get(key)!r}")
        if isinstance(module, str):
            expected_marker = normalized_runtime_marker(module)
            if metadata.get("runtimeMarker") != expected_marker:
                self.error(
                    f"runtimeMarker must be {expected_marker!r}, "
                    f"got {metadata.get('runtimeMarker')!r}"
                )

        policy = metadata.get("coveragePolicy")
        policy_keys = {
            "allowedStatuses",
            "nondeferredStatuses",
            "minimumNondeferredCount",
            "rule",
        }
        if not isinstance(policy, dict):
            self.error("coveragePolicy must be an object")
        else:
            if set(policy) != policy_keys:
                self.error(
                    "coveragePolicy keys differ from schema v1: "
                    f"missing={sorted(policy_keys - set(policy))}, "
                    f"extra={sorted(set(policy) - policy_keys)}"
                )
            if policy.get("allowedStatuses") != ALLOWED_STATUSES:
                self.error("coveragePolicy.allowedStatuses does not match schema v1")
            if policy.get("nondeferredStatuses") != NONDEFERRED_STATUSES:
                self.error("coveragePolicy.nondeferredStatuses does not match schema v1")
            minimum = policy.get("minimumNondeferredCount")
            count = metadata.get("symbolCount")
            if not is_int(minimum) or minimum < 0:
                self.error("coveragePolicy.minimumNondeferredCount must be nonnegative")
            elif is_int(count) and minimum > count:
                self.error(
                    "coveragePolicy.minimumNondeferredCount exceeds symbolCount"
                )
            if not isinstance(policy.get("rule"), str) or not policy["rule"].strip():
                self.error("coveragePolicy.rule must be a nonempty string")

        provenance = metadata.get("provenance")
        provenance_keys = {
            "generatorPath",
            "generatorSHA256",
            "xcodeVersion",
            "xcodeBuild",
            "sdkName",
            "sdkVersion",
            "target",
            "frameworkSDKRelativePath",
            "rawSDKInputCount",
            "tbdInputCount",
            "arm64TBDExportCount",
            "roadmapPath",
            "roadmapSHA256",
        }
        if framework_schema == 1:
            provenance_keys.add("sdkPath")
        elif framework_schema == 2:
            provenance_keys |= {
                "apiCrosswalkAmbiguousCount",
                "apiCrosswalkExactUSRCount",
                "apiCrosswalkImportNameCount",
                "apiCrosswalkUnmatchedCount",
                "apiDeclarationNodeCount",
                "apiDigesterFormatVersion",
                "apiDigesterNodeCount",
                "apiDigesterPath",
                "apiDigesterSHA256",
                "apiDigesterVersion",
                "apiOwnedDeclarationNodeCount",
                "externalEvidenceLockPath",
                "externalEvidenceLockSHA256",
                "symbolGraphRelationshipMultisetSHA256",
                "symbolGraphExtractorPath",
                "symbolGraphExtractorSHA256",
                "symbolGraphExtractorVersion",
                "symbolGraphSymbolMultisetSHA256",
            }
        if not isinstance(provenance, dict):
            self.error("provenance must be an object")
            return
        if set(provenance) != provenance_keys:
            self.error(
                "provenance keys differ from schema v1: "
                f"missing={sorted(provenance_keys - set(provenance))}, "
                f"extra={sorted(set(provenance) - provenance_keys)}"
            )
        required_strings = [
            "xcodeVersion",
            "xcodeBuild",
            "sdkName",
            "sdkVersion",
            "target",
            "frameworkSDKRelativePath",
        ]
        if framework_schema == 1:
            required_strings.append("sdkPath")
        elif framework_schema == 2:
            required_strings.extend(
                (
                    "apiDigesterPath",
                    "apiDigesterVersion",
                    "symbolGraphExtractorPath",
                    "symbolGraphExtractorVersion",
                )
            )
        for key in required_strings:
            if not isinstance(provenance.get(key), str) or not provenance[key].strip():
                self.error(f"provenance.{key} must be a nonempty string")
        for key in ("rawSDKInputCount", "tbdInputCount", "arm64TBDExportCount"):
            value = provenance.get(key)
            if not is_int(value) or value < 0:
                self.error(f"provenance.{key} must be a nonnegative integer")
        if framework_schema == 2:
            for key in (
                "apiDeclarationNodeCount",
                "apiDigesterFormatVersion",
                "apiDigesterNodeCount",
            ):
                value = provenance.get(key)
                if not is_int(value) or value <= 0:
                    self.error(f"provenance.{key} must be a positive integer")
            for key in (
                "apiCrosswalkAmbiguousCount",
                "apiCrosswalkExactUSRCount",
                "apiCrosswalkImportNameCount",
                "apiCrosswalkUnmatchedCount",
                "apiOwnedDeclarationNodeCount",
            ):
                value = provenance.get(key)
                if not is_int(value) or value < 0:
                    self.error(f"provenance.{key} must be a nonnegative integer")
            for key in (
                "symbolGraphRelationshipMultisetSHA256",
                "symbolGraphSymbolMultisetSHA256",
            ):
                value = provenance.get(key)
                if not isinstance(value, str) or not SHA256_RE.fullmatch(value):
                    self.error(f"provenance.{key} is not a lowercase SHA-256")
            crosswalk_count_keys = (
                "apiCrosswalkExactUSRCount",
                "apiCrosswalkImportNameCount",
                "apiCrosswalkAmbiguousCount",
                "apiCrosswalkUnmatchedCount",
            )
            if all(is_int(provenance.get(key)) for key in crosswalk_count_keys):
                if sum(provenance[key] for key in crosswalk_count_keys) != metadata.get(
                    "symbolCount"
                ):
                    self.error("provenance API crosswalk counts do not sum to symbolCount")
            if (
                is_int(provenance.get("apiOwnedDeclarationNodeCount"))
                and is_int(provenance.get("apiDeclarationNodeCount"))
                and provenance["apiOwnedDeclarationNodeCount"]
                > provenance["apiDeclarationNodeCount"]
            ):
                self.error(
                    "provenance.apiOwnedDeclarationNodeCount exceeds declaration count"
                )
            tool_fields = {
                "apiDigester": "swift-api-digester",
                "symbolGraphExtractor": "swift-symbolgraph-extract",
            }
            for prefix, expected_name in tool_fields.items():
                relative = provenance.get(f"{prefix}Path")
                digest = provenance.get(f"{prefix}SHA256")
                version = provenance.get(f"{prefix}Version")
                if (
                    not isinstance(relative, str)
                    or not self._is_safe_relative_text(relative)
                    or PurePosixPath(relative).name != expected_name
                ):
                    self.error(
                        f"provenance.{prefix}Path must be a safe Xcode-relative "
                        f"path ending in {expected_name!r}"
                    )
                if not isinstance(digest, str) or not SHA256_RE.fullmatch(digest):
                    self.error(
                        f"provenance.{prefix}SHA256 is not a lowercase SHA-256"
                    )
                if (
                    not isinstance(version, str)
                    or not version
                    or version.strip() != version
                    or any(character in version for character in "\x00\r\n\t")
                    or len(version.encode("utf-8")) > 500
                ):
                    self.error(
                        f"provenance.{prefix}Version must be one safe version line"
                    )
            if provenance.get("externalEvidenceLockPath") != EXTERNAL_EVIDENCE_LOCK:
                self.error(
                    f"provenance.externalEvidenceLockPath must be {EXTERNAL_EVIDENCE_LOCK!r}"
                )
            external_digest = provenance.get("externalEvidenceLockSHA256")
            if not isinstance(external_digest, str) or not SHA256_RE.fullmatch(
                external_digest
            ):
                self.error(
                    "provenance.externalEvidenceLockSHA256 is not a lowercase SHA-256"
                )
        for path_key, digest_key in (
            ("generatorPath", "generatorSHA256"),
            ("roadmapPath", "roadmapSHA256"),
        ):
            relative = provenance.get(path_key)
            expected_digest = provenance.get(digest_key)
            if not isinstance(relative, str) or not isinstance(expected_digest, str):
                self.error(f"provenance {path_key}/{digest_key} must be strings")
                continue
            if not SHA256_RE.fullmatch(expected_digest):
                self.error(f"provenance.{digest_key} is not a lowercase SHA-256")
                continue
            try:
                actual = self._sha256(self._repo_file(relative))
            except InvalidSeed:
                continue
            if actual != expected_digest:
                self.error(
                    f"provenance digest mismatch for {relative}: "
                    f"expected {expected_digest}, got {actual}"
                )

        if "moduleLocation" in metadata:
            location = metadata.get("moduleLocation")
            if not isinstance(location, dict) or set(location) != MODULE_LOCATION_KEYS:
                self.error(
                    "moduleLocation keys differ from schema: "
                    f"expected {sorted(MODULE_LOCATION_KEYS)}"
                )
            else:
                kind = location.get("kind")
                relative = location.get("sdkRelativePath")
                reason = location.get("reason")
                if kind not in MODULE_LOCATION_KINDS:
                    self.error(f"moduleLocation.kind is invalid: {kind!r}")
                if (
                    not isinstance(relative, str)
                    or not self._is_safe_relative_text(relative)
                ):
                    self.error("moduleLocation.sdkRelativePath must be a safe SDK path")
                elif (
                    isinstance(provenance, dict)
                    and provenance.get("frameworkSDKRelativePath") != relative
                ):
                    self.error(
                        "moduleLocation.sdkRelativePath does not match "
                        "provenance.frameworkSDKRelativePath"
                    )
                if not isinstance(reason, str) or not reason.strip():
                    self.error("moduleLocation.reason must be a nonempty string")
        if "roadmap" in metadata:
            if metadata.get("roadmap") != ROADMAP_OPERATOR_OVERRIDE:
                self.error(
                    "framework roadmap override must be "
                    f"{ROADMAP_OPERATOR_OVERRIDE!r}"
                )

    def _validate_symbol_graphs(self, metadata: dict[str, Any]) -> set[str]:
        manifest = self._read_json("reference/symbol-graphs.json")
        if not isinstance(manifest, dict):
            self.fatal("reference/symbol-graphs.json must contain an object")
        framework_schema = metadata.get("schema")
        graph_schema = 2 if framework_schema == 2 else 1
        expected_keys = {
            "schema",
            "module",
            "target",
            "minimumAccessLevel",
            "canonicalSurfacePolicy",
            "duplicateOccurrenceCount",
            "conflictingDuplicateIdentifierCount",
            "files",
            "symbolCount",
            "relationshipCount",
        }
        if graph_schema == 2:
            expected_keys |= {
                "conflictLedger",
                "duplicateRelationshipOccurrenceCount",
                "relationshipMultisetSHA256",
                "semanticHashPolicy",
                "symbolMultisetSHA256",
            }
        if set(manifest) != expected_keys:
            self.error(f"symbol graph manifest keys differ from schema v{graph_schema}")
        if manifest.get("schema") != graph_schema:
            self.error(f"symbol graph manifest schema must be {graph_schema}")
        if manifest.get("module") != metadata.get("module"):
            self.error("symbol graph manifest module does not match framework metadata")
        provenance = metadata.get("provenance")
        if (
            not isinstance(provenance, dict)
            or manifest.get("target") != provenance.get("target")
        ):
            self.error("symbol graph target does not match framework provenance")
        if manifest.get("minimumAccessLevel") != "public":
            self.error("symbol graph minimumAccessLevel must be 'public'")
        expected_policy = (
            CANONICAL_SURFACE_POLICY_V2
            if graph_schema == 2
            else CANONICAL_SURFACE_POLICY_V1
        )
        if manifest.get("canonicalSurfacePolicy") != expected_policy:
            self.error(
                f"symbol graph canonicalSurfacePolicy does not match schema v{graph_schema}"
            )
        if graph_schema == 2:
            if manifest.get("semanticHashPolicy") != SEMANTIC_HASH_POLICY:
                self.error("symbol graph semanticHashPolicy does not match schema v2")
            if manifest.get("conflictLedger") != "reference/symbol-conflicts.tsv":
                self.error(
                    "symbol graph conflictLedger must be reference/symbol-conflicts.tsv"
                )
        files = manifest.get("files")
        if not isinstance(files, list) or not files:
            self.fatal("symbol graph manifest files must be a nonempty list")

        graph_paths: set[str] = set()
        manifest_path_order: list[str] = []
        occurrences: dict[str, list[dict[str, Any]]] = {}
        symbol_payloads: list[bytes] = []
        relationship_payloads: list[bytes] = []
        raw_symbol_count = 0
        total_relationships = 0
        for index, entry in enumerate(files):
            label = f"symbol graph manifest files[{index}]"
            if not isinstance(entry, dict) or set(entry) != {
                "path",
                "sha256",
                "symbolCount",
                "relationshipCount",
            }:
                self.error(f"{label} has wrong schema")
                continue
            relative = entry.get("path")
            digest = entry.get("sha256")
            if (
                not isinstance(relative, str)
                or not relative.startswith("reference/symbol-graphs/")
                or not relative.endswith(".symbols.json")
            ):
                self.error(f"{label}.path is not a raw symbol graph path")
                continue
            if relative in graph_paths:
                self.error(f"duplicate raw symbol graph path: {relative}")
                continue
            graph_paths.add(relative)
            manifest_path_order.append(relative)
            if not isinstance(digest, str) or not SHA256_RE.fullmatch(digest):
                self.error(f"{label}.sha256 is invalid")
            graph_path = self._framework_file(relative)
            if isinstance(digest, str) and self._sha256(graph_path) != digest:
                self.error(f"raw symbol graph digest mismatch: {relative}")
            graph = (
                self._read_strict_json(relative)
                if graph_schema == 2
                else self._read_json(relative)
            )
            if not isinstance(graph, dict):
                self.error(f"raw symbol graph must contain an object: {relative}")
                continue
            graph_module = graph.get("module")
            graph_module_name = (
                graph_module.get("name") if isinstance(graph_module, dict) else None
            )
            if not isinstance(graph_module_name, str) or not graph_module_name:
                self.error(f"raw symbol graph lacks a module name: {relative}")
                graph_module_name = ""
            symbols = graph.get("symbols")
            relationships = graph.get("relationships")
            if not isinstance(symbols, list):
                self.error(f"raw symbol graph symbols must be a list: {relative}")
                symbols = []
            if not isinstance(relationships, list):
                self.error(f"raw symbol graph relationships must be a list: {relative}")
                relationships = []
            if graph_schema == 2:
                for relationship_index, relationship in enumerate(relationships):
                    if not isinstance(relationship, dict):
                        self.fatal(
                            f"{relative}: relationship[{relationship_index}] must be an object"
                        )
                    try:
                        relationship_payloads.append(
                            canonical_json_bytes(
                                relationship,
                                label=(
                                    f"{relative}: relationship[{relationship_index}]"
                                ),
                            )
                        )
                    except ValueError as exc:
                        self.fatal(str(exc))
            raw_symbol_count += len(symbols)
            for symbol_index, symbol in enumerate(symbols):
                precise = None
                if isinstance(symbol, dict) and isinstance(symbol.get("identifier"), dict):
                    precise = symbol["identifier"].get("precise")
                if not isinstance(precise, str) or not precise:
                    self.error(
                        f"{relative}: symbol[{symbol_index}] lacks a precise identifier"
                    )
                    continue
                if any(character in precise for character in "\x00\r\n\t"):
                    self.error(f"{relative}: unsafe precise identifier {precise!r}")
                    continue
                try:
                    expected_surface = symbol_surface_fields(precise, symbol)
                    canonical_payload = canonical_json_bytes(
                        symbol, label=f"{relative}: symbol[{symbol_index}]"
                    )
                except ValueError as exc:
                    if graph_schema == 2:
                        self.fatal(str(exc))
                    self.error(str(exc))
                    continue
                if graph_schema == 2:
                    symbol_payloads.append(canonical_payload)
                requested_module = metadata.get("module")
                basename = PurePosixPath(relative).name
                if (
                    graph_module_name == requested_module
                    and basename == f"{requested_module}.symbols.json"
                ):
                    tier = 0
                elif graph_module_name == requested_module:
                    tier = 1
                else:
                    tier = 2
                canonical_key = (
                    tier,
                    relative.encode("utf-8"),
                    canonical_payload,
                )
                if graph_schema == 1:
                    canonical_key += (symbol_index,)
                occurrences.setdefault(precise, []).append(
                    {
                        "selectionKey": canonical_key,
                        "payload": canonical_payload,
                        "symbol": symbol,
                        "surface": expected_surface,
                        "graphPath": relative,
                        "ownershipTier": tier,
                    }
                )
            if entry.get("symbolCount") != len(symbols):
                self.error(f"symbolCount mismatch for {relative}")
            if entry.get("relationshipCount") != len(relationships):
                self.error(f"relationshipCount mismatch for {relative}")
            total_relationships += len(relationships)

        if graph_schema == 2 and manifest_path_order != sorted(
            manifest_path_order, key=lambda value: value.encode("utf-8")
        ):
            self.error("symbol graph manifest files must be sorted by UTF-8 path")

        surface_by_precise: dict[str, list[str]] = {}
        canonical_symbols: dict[str, dict[str, Any]] = {}
        conflicting_identifiers = 0
        conflict_rows: list[tuple[tuple[Any, ...], list[str]]] = []
        payload_by_digest: dict[str, bytes] = {}
        for precise, values in occurrences.items():
            canonical = min(values, key=lambda value: value["selectionKey"])
            surface_by_precise[precise] = canonical["surface"]
            canonical_symbols[precise] = canonical["symbol"]
            if len({value["payload"] for value in values}) <= 1:
                continue
            conflicting_identifiers += 1
            if graph_schema != 2:
                continue
            grouped: dict[tuple[bytes, str, int], list[dict[str, Any]]] = {}
            for occurrence in values:
                key = (
                    occurrence["payload"],
                    occurrence["graphPath"],
                    occurrence["ownershipTier"],
                )
                grouped.setdefault(key, []).append(occurrence)
            for (payload, graph_path, ownership_tier), group in grouped.items():
                payload_digest = hashlib.sha256(payload).hexdigest()
                previous = payload_by_digest.setdefault(payload_digest, payload)
                if previous != payload:
                    self.fatal("SHA-256 collision between distinct symbol payloads")
                selected = (
                    payload == canonical["payload"]
                    and graph_path == canonical["graphPath"]
                    and ownership_tier == canonical["ownershipTier"]
                )
                surface = group[0]["surface"]
                row = [
                    precise,
                    payload_digest,
                    graph_path,
                    str(ownership_tier),
                    str(len(group)),
                    "1" if selected else "0",
                    surface[1],
                    surface[2],
                    surface[3],
                    surface[4],
                ]
                conflict_rows.append(
                    (
                        (
                            precise.encode("utf-8"),
                            ownership_tier,
                            graph_path.encode("utf-8"),
                            payload,
                        ),
                        row,
                    )
                )
        duplicate_occurrences = raw_symbol_count - len(occurrences)

        self.surface_by_precise = surface_by_precise
        self.canonical_symbols = canonical_symbols
        self.precise_ids = sorted(surface_by_precise)
        if manifest.get("symbolCount") != len(surface_by_precise):
            self.error("symbol graph manifest symbolCount does not match raw graphs")
        if manifest.get("duplicateOccurrenceCount") != duplicate_occurrences:
            self.error(
                "symbol graph duplicateOccurrenceCount does not match raw graphs"
            )
        if (
            manifest.get("conflictingDuplicateIdentifierCount")
            != conflicting_identifiers
        ):
            self.error(
                "symbol graph conflictingDuplicateIdentifierCount does not match raw graphs"
            )
        if manifest.get("relationshipCount") != total_relationships:
            self.error("symbol graph manifest relationshipCount does not match raw graphs")
        if metadata.get("symbolCount") != len(surface_by_precise):
            self.error("framework symbolCount does not match raw graphs")
        if metadata.get("relationshipCount") != total_relationships:
            self.error("framework relationshipCount does not match raw graphs")
        if graph_schema == 2:
            duplicate_relationships = total_relationships - len(
                set(relationship_payloads)
            )
            if (
                manifest.get("duplicateRelationshipOccurrenceCount")
                != duplicate_relationships
            ):
                self.error(
                    "symbol graph duplicateRelationshipOccurrenceCount does not match raw graphs"
                )
            try:
                symbol_hash = semantic_multiset_sha256(
                    SYMBOL_MULTISET_DOMAIN, symbol_payloads
                )
                relationship_hash = semantic_multiset_sha256(
                    RELATIONSHIP_MULTISET_DOMAIN, relationship_payloads
                )
            except ValueError as exc:
                self.fatal(str(exc))
            if manifest.get("symbolMultisetSHA256") != symbol_hash:
                self.error("symbol graph symbolMultisetSHA256 does not match raw graphs")
            if manifest.get("relationshipMultisetSHA256") != relationship_hash:
                self.error(
                    "symbol graph relationshipMultisetSHA256 does not match raw graphs"
                )
            provenance = metadata.get("provenance")
            if isinstance(provenance, dict):
                if provenance.get("symbolGraphSymbolMultisetSHA256") != symbol_hash:
                    self.error(
                        "provenance symbol multiset hash does not match raw graphs"
                    )
                if (
                    provenance.get("symbolGraphRelationshipMultisetSHA256")
                    != relationship_hash
                ):
                    self.error(
                        "provenance relationship multiset hash does not match raw graphs"
                    )
            expected_conflicts = [row for _key, row in sorted(conflict_rows)]
            actual_conflicts = self._read_tsv(
                str(metadata.get("symbolConflicts")), CONFLICT_HEADER
            )
            if actual_conflicts != expected_conflicts:
                self.error(
                    "reference/symbol-conflicts.tsv does not match raw graph conflicts"
                )
        return graph_paths

    def _validate_symbol_graph_scope(
        self, metadata: dict[str, Any], graph_paths: set[str]
    ) -> None:
        scope = self._read_strict_json(SYMBOL_GRAPH_SCOPE_PATH)
        if not isinstance(scope, dict) or set(scope) != SYMBOL_GRAPH_SCOPE_KEYS:
            self.fatal("symbol-graph scope provenance has the wrong schema")
        if scope.get("schema") != 1:
            self.error("symbol-graph scope schema must be 1")
        if scope.get("policy") != SYMBOL_GRAPH_SCOPE_POLICY:
            self.error("symbol-graph scope policy differs")
        module = metadata.get("module")
        if scope.get("requestedModule") != module:
            self.error("symbol-graph scope requested module differs")

        approved = scope.get("approvedExcludedCrossImportOverlayModules")
        if (
            not isinstance(approved, list)
            or not approved
            or any(
                not isinstance(value, str) or not MODULE_RE.fullmatch(value)
                for value in approved
            )
            or approved != sorted(set(approved))
            or module in approved
        ):
            self.fatal(
                "symbol-graph scope approved exclusions must be sorted exact modules"
            )

        source_generator = scope.get("sourceGenerator")
        if (
            not isinstance(source_generator, dict)
            or set(source_generator) != {"path", "sha256"}
            or source_generator.get("path") != BASE_V2_GENERATOR_PATH
            or not isinstance(source_generator.get("sha256"), str)
            or not SHA256_RE.fullmatch(source_generator["sha256"])
        ):
            self.fatal("symbol-graph scope source generator provenance differs")
        try:
            source_digest = self._sha256(
                self._repo_file(BASE_V2_GENERATOR_PATH)
            )
        except InvalidSeed:
            source_digest = None
        if source_digest is not None and source_generator["sha256"] != source_digest:
            self.error("symbol-graph scope source generator digest differs")

        graph_manifest = self._read_json("reference/symbol-graphs.json")
        if not isinstance(graph_manifest, dict) or not isinstance(
            graph_manifest.get("files"), list
        ):
            self.fatal("symbol graph manifest is unavailable to scope validator")
        expected_included: list[dict[str, Any]] = []
        primary_documents: list[tuple[str, dict[str, Any]]] = []
        for record in graph_manifest["files"]:
            if not isinstance(record, dict):
                self.fatal("symbol graph manifest file record is malformed")
            relative = record.get("path")
            if not isinstance(relative, str) or relative not in graph_paths:
                self.fatal("symbol graph scope encountered an unknown graph path")
            graph = self._read_strict_json(relative)
            if not isinstance(graph, dict):
                self.fatal(f"scoped graph root is not an object: {relative}")
            graph_module = graph.get("module")
            if not isinstance(graph_module, dict):
                self.fatal(f"scoped graph module is malformed: {relative}")
            bystanders = graph_module.get("bystanders", [])
            if (
                not isinstance(bystanders, list)
                or any(
                    not isinstance(value, str) or not MODULE_RE.fullmatch(value)
                    for value in bystanders
                )
                or bystanders
            ):
                self.error(
                    f"in-scope graph must not contain cross-import bystanders: {relative}"
                )
            file_name = PurePosixPath(relative).name
            suffix = ".symbols.json"
            declaring = (
                file_name[: -len(suffix)].split("@", 1)[0]
                if file_name.endswith(suffix)
                else ""
            )
            if declaring != module:
                self.error(
                    f"in-scope graph is not declared by base module {module}: {relative}"
                )
            expected_included.append(
                {
                    "fileName": file_name,
                    "sha256": record.get("sha256"),
                    "symbolCount": record.get("symbolCount"),
                    "relationshipCount": record.get("relationshipCount"),
                    "graphModule": graph_module.get("name"),
                    "bystanders": [],
                    "crossImportOverlayModule": None,
                }
            )
            primary_documents.append((file_name, graph))

        included = scope.get("includedFiles")
        if included != expected_included:
            self.error(
                "symbol-graph scope included records do not match retained raw graphs"
            )

        excluded = scope.get("excludedFiles")
        if not isinstance(excluded, list) or not excluded:
            self.fatal("symbol-graph scope must record excluded graph files")
        excluded_names: list[str] = []
        observed_modules: set[str] = set()
        excluded_symbol_count = 0
        excluded_relationship_count = 0
        for index, record in enumerate(excluded):
            if (
                not isinstance(record, dict)
                or set(record) != SYMBOL_GRAPH_SCOPE_RECORD_KEYS
            ):
                self.fatal(
                    f"symbol-graph scope excluded record {index} has wrong keys"
                )
            file_name = record.get("fileName")
            digest = record.get("sha256")
            symbol_count = record.get("symbolCount")
            relationship_count = record.get("relationshipCount")
            graph_module = record.get("graphModule")
            bystanders = record.get("bystanders")
            overlay_module = record.get("crossImportOverlayModule")
            if (
                not isinstance(file_name, str)
                or PurePosixPath(file_name).name != file_name
                or not file_name.endswith(".symbols.json")
                or "@" not in file_name
            ):
                self.fatal(
                    f"symbol-graph scope excluded record {index} has unsafe name"
                )
            declaring = file_name[: -len(".symbols.json")].split("@", 1)[0]
            if (
                not isinstance(overlay_module, str)
                or declaring != overlay_module
                or overlay_module not in approved
            ):
                self.error(
                    f"symbol-graph scope excluded record {index} is not approved"
                )
            if graph_module != module:
                self.error(
                    f"symbol-graph scope excluded record {index} graph module differs"
                )
            if (
                not isinstance(bystanders, list)
                or not bystanders
                or any(
                    not isinstance(value, str) or not MODULE_RE.fullmatch(value)
                    for value in bystanders
                )
                or bystanders != sorted(set(bystanders))
            ):
                self.error(
                    f"symbol-graph scope excluded record {index} bystanders differ"
                )
            if not isinstance(digest, str) or not SHA256_RE.fullmatch(digest):
                self.error(
                    f"symbol-graph scope excluded record {index} hash is invalid"
                )
            if not is_int(symbol_count) or symbol_count < 0:
                self.error(
                    f"symbol-graph scope excluded record {index} symbol count is invalid"
                )
            else:
                excluded_symbol_count += symbol_count
            if not is_int(relationship_count) or relationship_count < 0:
                self.error(
                    f"symbol-graph scope excluded record {index} relationship count is invalid"
                )
            else:
                excluded_relationship_count += relationship_count
            excluded_names.append(file_name)
            if isinstance(overlay_module, str):
                observed_modules.add(overlay_module)
            excluded_path = self._framework_file(
                f"reference/symbol-graphs/{file_name}", must_exist=False
            )
            if excluded_path.exists() or excluded_path.is_symlink():
                self.error(
                    f"excluded cross-import graph remains in base dossier: {file_name}"
                )

        if excluded_names != sorted(set(excluded_names)):
            self.error("symbol-graph scope excluded file records must be sorted and unique")
        if observed_modules != set(approved):
            self.error(
                "symbol-graph scope approved modules do not equal observed exclusions"
            )

        included_symbol_count = sum(
            record.get("symbolCount", 0)
            for record in expected_included
            if is_int(record.get("symbolCount"))
        )
        included_relationship_count = sum(
            record.get("relationshipCount", 0)
            for record in expected_included
            if is_int(record.get("relationshipCount"))
        )
        expected_counts = {
            "includedFileCount": len(expected_included),
            "includedSymbolOccurrenceCount": included_symbol_count,
            "includedRelationshipOccurrenceCount": included_relationship_count,
            "excludedFileCount": len(excluded),
            "excludedSymbolOccurrenceCount": excluded_symbol_count,
            "excludedRelationshipOccurrenceCount": excluded_relationship_count,
            "rawExtractorFileCount": len(expected_included) + len(excluded),
            "rawExtractorSymbolOccurrenceCount": (
                included_symbol_count + excluded_symbol_count
            ),
            "rawExtractorRelationshipOccurrenceCount": (
                included_relationship_count + excluded_relationship_count
            ),
        }
        for key, expected in expected_counts.items():
            if scope.get(key) != expected:
                self.error(
                    f"symbol-graph scope {key} differs: "
                    f"expected {expected}, got {scope.get(key)!r}"
                )

        try:
            primary_projection = compute_base_relationship_projection(
                primary_documents, str(module)
            )
        except (KeyError, ValueError) as exc:
            self.fatal(f"cannot recompute scoped relationship projection: {exc}")
        recorded_projection = scope.get("baseRelationshipProjection")
        if (
            not isinstance(recorded_projection, dict)
            or set(recorded_projection) != BASE_RELATIONSHIP_PROJECTION_KEYS
        ):
            self.fatal("symbol-graph scope projection has the wrong schema")
        for index, row in enumerate(recorded_projection.get("excludedRows", [])):
            if (
                not isinstance(row, dict)
                or set(row) != BASE_RELATIONSHIP_PROJECTION_ROW_KEYS
            ):
                self.fatal(
                    f"symbol-graph scope projection row {index} has the wrong schema"
                )
        if recorded_projection != primary_projection:
            self.error(
                "symbol-graph scope projection does not match immutable raw graphs"
            )
        self._validate_symbol_graph_reproducibility(
            metadata,
            scope,
            primary_documents,
            expected_included,
        )

    def _validate_symbol_graph_reproducibility(
        self,
        metadata: dict[str, Any],
        scope: dict[str, Any],
        primary_documents: list[tuple[str, dict[str, Any]]],
        primary_included: list[dict[str, Any]],
    ) -> None:
        document = self._read_strict_json(SYMBOL_GRAPH_REPRODUCIBILITY_PATH)
        if not isinstance(document, dict) or set(document) != REPRODUCIBILITY_KEYS:
            self.fatal("symbol-graph reproducibility provenance has the wrong schema")
        if document.get("schema") != 1:
            self.error("symbol-graph reproducibility schema must be 1")
        if document.get("policy") != SYMBOL_GRAPH_REPRODUCIBILITY_POLICY:
            self.error("symbol-graph reproducibility policy differs")
        module = metadata.get("module")
        if document.get("requestedModule") != module:
            self.error("symbol-graph reproducibility module differs")
        if document.get("canonicalOutputPaths") != list(
            CANONICAL_REPRODUCIBILITY_OUTPUT_PATHS
        ):
            self.error("symbol-graph reproducibility canonical output paths differ")
        if document.get("minimumRequiredDistinctRawRelationshipHashes") != 2:
            self.error(
                "symbol-graph reproducibility raw-volatility minimum must be 2"
            )

        runs = document.get("runs")
        if not isinstance(runs, list) or len(runs) < 3:
            self.fatal("symbol-graph reproducibility requires at least three runs")
        if document.get("runCount") != len(runs):
            self.error("symbol-graph reproducibility runCount differs")

        provenance = metadata.get("provenance")
        if not isinstance(provenance, dict):
            self.fatal("framework provenance is unavailable to reproducibility validator")
        extraction_keys = (
            "xcodeVersion",
            "xcodeBuild",
            "sdkName",
            "sdkVersion",
            "target",
            "symbolGraphExtractorPath",
            "symbolGraphExtractorSHA256",
            "symbolGraphExtractorVersion",
        )
        expected_extraction = {key: provenance.get(key) for key in extraction_keys}
        expected_extraction["commandTemplate"] = [
            "{symbolGraphExtractorPath}",
            "-module-name",
            module,
            "-target",
            provenance.get("target"),
            "-sdk",
            "{iPhoneOSSDKRoot}",
            "-minimum-access-level",
            "public",
            "-module-cache-path",
            "{freshTemporaryModuleCache}",
            "-output-dir",
            "{freshTemporaryOutputDirectory}",
        ]
        expected_extraction["temporaryPathPolicy"] = (
            "fresh-private-paths-redacted-with-explicit-command-placeholders-v1"
        )
        expected_extraction["environmentPolicy"] = (
            "generate_seed_v2.prepare_clean_environment-v1"
        )

        recomputed_runs: list[dict[str, Any]] = []
        raw_hashes: set[str] = set()
        for index, run in enumerate(runs, start=1):
            if not isinstance(run, dict) or set(run) != REPRODUCIBILITY_RUN_KEYS:
                self.fatal(
                    f"symbol-graph reproducibility run {index} has the wrong schema"
                )
            if run.get("run") != index:
                self.error(
                    "symbol-graph reproducibility runs must be consecutively numbered"
                )
            expected_graph_root = (
                "reference/symbol-graphs"
                if index == 1
                else f"reference/reproducibility/run-{index}/symbol-graphs"
            )
            if run.get("graphRoot") != expected_graph_root:
                self.error(
                    f"symbol-graph reproducibility run {index} graph root differs"
                )

            documents_for_run: list[tuple[str, dict[str, Any]]] = []
            included = run.get("includedFiles")
            if not isinstance(included, list) or not included:
                self.fatal(
                    f"symbol-graph reproducibility run {index} included files differ"
                )
            names: list[str] = []
            expected_records: list[dict[str, Any]] = []
            for record_index, record in enumerate(included):
                if (
                    not isinstance(record, dict)
                    or set(record) != SYMBOL_GRAPH_SCOPE_RECORD_KEYS
                ):
                    self.fatal(
                        "symbol-graph reproducibility included record has wrong schema: "
                        f"run={index} record={record_index}"
                    )
                file_name = record.get("fileName")
                if (
                    not isinstance(file_name, str)
                    or PurePosixPath(file_name).name != file_name
                    or not file_name.endswith(".symbols.json")
                ):
                    self.fatal(
                        f"symbol-graph reproducibility run {index} has unsafe graph name"
                    )
                relative = f"{expected_graph_root}/{file_name}"
                graph_path = self._framework_file(relative)
                graph = self._read_strict_json(relative)
                if not isinstance(graph, dict):
                    self.fatal(
                        f"symbol-graph reproducibility graph is not an object: {relative}"
                    )
                graph_module = graph.get("module")
                symbols = graph.get("symbols")
                relationships = graph.get("relationships")
                if (
                    not isinstance(graph_module, dict)
                    or graph_module.get("name") != module
                    or not isinstance(symbols, list)
                    or not isinstance(relationships, list)
                ):
                    self.fatal(
                        f"symbol-graph reproducibility graph structure differs: {relative}"
                    )
                bystanders = graph_module.get("bystanders", [])
                if bystanders != []:
                    self.error(
                        f"reproducibility base graph has cross-import bystanders: {relative}"
                    )
                expected_record = {
                    "fileName": file_name,
                    "sha256": self._sha256(graph_path),
                    "symbolCount": len(symbols),
                    "relationshipCount": len(relationships),
                    "graphModule": module,
                    "bystanders": [],
                    "crossImportOverlayModule": None,
                }
                expected_records.append(expected_record)
                documents_for_run.append((file_name, graph))
                names.append(file_name)
            if names != sorted(set(names)):
                self.error(
                    f"symbol-graph reproducibility run {index} graphs are not sorted/unique"
                )
            graph_directory = self.framework / expected_graph_root  # type: ignore[operator]
            observed_names = sorted(
                path.name for path in graph_directory.iterdir() if path.is_file()
            )
            if observed_names != names:
                self.error(
                    f"symbol-graph reproducibility run {index} graph closure differs"
                )
            if expected_records != included:
                self.error(
                    f"symbol-graph reproducibility run {index} graph records differ"
                )
            if index == 1:
                if documents_for_run != primary_documents:
                    self.error(
                        "symbol-graph reproducibility primary documents differ from scope"
                    )
                if included != primary_included:
                    self.error(
                        "symbol-graph reproducibility primary records differ from scope"
                    )

            excluded = run.get("excludedFiles")
            if not isinstance(excluded, list) or not excluded:
                self.fatal(
                    f"symbol-graph reproducibility run {index} exclusions are missing"
                )
            self._validate_reproducibility_exclusions(
                excluded,
                scope.get("approvedExcludedCrossImportOverlayModules"),
                str(module),
                index,
            )
            if index == 1 and excluded != scope.get("excludedFiles"):
                self.error(
                    "symbol-graph reproducibility primary exclusions differ from scope"
                )

            extraction = run.get("extraction")
            if (
                not isinstance(extraction, dict)
                or set(extraction) != REPRODUCIBILITY_EXTRACTION_KEYS
            ):
                self.fatal(
                    f"symbol-graph reproducibility run {index} extraction schema differs"
                )
            if extraction != expected_extraction:
                self.error(
                    f"symbol-graph reproducibility run {index} extraction provenance differs"
                )

            try:
                summary = compute_scoped_graph_summary(
                    documents_for_run, str(module)
                )
            except (KeyError, ValueError) as exc:
                self.fatal(
                    f"cannot recompute symbol-graph reproducibility run {index}: {exc}"
                )
            for key in (
                "uniqueSymbolCount",
                "symbolOccurrenceCount",
                "symbolMultisetSHA256",
                "rawRelationshipOccurrenceCount",
                "rawRelationshipMultisetSHA256",
                "baseRelationshipProjection",
            ):
                if run.get(key) != summary[key]:
                    self.error(
                        f"symbol-graph reproducibility run {index} {key} differs"
                    )
            raw_hashes.add(summary["rawRelationshipMultisetSHA256"])

            outputs = run.get("canonicalOutputs")
            if not isinstance(outputs, list):
                self.fatal(
                    f"symbol-graph reproducibility run {index} canonical outputs differ"
                )
            expected_output_records: list[dict[str, str]] = []
            for source_path in CANONICAL_REPRODUCIBILITY_OUTPUT_PATHS:
                retained_path = (
                    source_path
                    if index == 1
                    else (
                        f"reference/reproducibility/run-{index}/canonical/"
                        f"{PurePosixPath(source_path).name}"
                    )
                )
                retained_file = self._framework_file(retained_path)
                expected_output_records.append(
                    {
                        "sourcePath": source_path,
                        "retainedPath": retained_path,
                        "sha256": self._sha256(retained_file),
                    }
                )
            if outputs != expected_output_records:
                self.error(
                    f"symbol-graph reproducibility run {index} canonical output records differ"
                )
            recomputed_runs.append(
                summary
                | {
                    "canonicalOutputSHA256": {
                        record["sourcePath"]: record["sha256"]
                        for record in expected_output_records
                    }
                }
            )

        distinct_count = len(raw_hashes)
        if document.get("observedDistinctRawRelationshipHashCount") != distinct_count:
            self.error(
                "symbol-graph reproducibility distinct raw hash count differs"
            )
        if distinct_count < 2:
            self.error(
                "symbol-graph reproducibility does not prove raw relationship volatility"
            )

        first = recomputed_runs[0]
        stable = {
            "uniqueSymbolCount": first["uniqueSymbolCount"],
            "symbolOccurrenceCount": first["symbolOccurrenceCount"],
            "symbolMultisetSHA256": first["symbolMultisetSHA256"],
            "projectedRelationshipOccurrenceCount": first[
                "baseRelationshipProjection"
            ]["projectedRelationshipOccurrenceCount"],
            "projectedRelationshipMultisetSHA256": first[
                "baseRelationshipProjection"
            ]["projectedRelationshipMultisetSHA256"],
            "canonicalOutputSHA256": first["canonicalOutputSHA256"],
        }
        for index, result in enumerate(recomputed_runs[1:], start=2):
            for key in (
                "uniqueSymbolCount",
                "symbolOccurrenceCount",
                "symbolMultisetSHA256",
            ):
                if result[key] != first[key]:
                    self.error(
                        f"symbol-graph reproducibility run {index} is unstable for {key}"
                    )
            if (
                result["baseRelationshipProjection"][
                    "projectedRelationshipOccurrenceCount"
                ]
                != stable["projectedRelationshipOccurrenceCount"]
                or result["baseRelationshipProjection"][
                    "projectedRelationshipMultisetSHA256"
                ]
                != stable["projectedRelationshipMultisetSHA256"]
            ):
                self.error(
                    f"symbol-graph reproducibility run {index} projected relationships differ"
                )
            if result["canonicalOutputSHA256"] != stable["canonicalOutputSHA256"]:
                self.error(
                    f"symbol-graph reproducibility run {index} canonical outputs differ"
                )
        recorded_stable = document.get("stable")
        if (
            not isinstance(recorded_stable, dict)
            or set(recorded_stable) != REPRODUCIBILITY_STABLE_KEYS
        ):
            self.fatal("symbol-graph reproducibility stable claim has wrong schema")
        if recorded_stable != stable:
            self.error(
                "symbol-graph reproducibility stable claim does not match retained evidence"
            )

    def _validate_reproducibility_exclusions(
        self,
        excluded: list[Any],
        approved_value: Any,
        module: str,
        run_number: int,
    ) -> None:
        approved = approved_value if isinstance(approved_value, list) else []
        names: list[str] = []
        observed_modules: set[str] = set()
        for index, record in enumerate(excluded):
            if (
                not isinstance(record, dict)
                or set(record) != SYMBOL_GRAPH_SCOPE_RECORD_KEYS
            ):
                self.fatal(
                    "symbol-graph reproducibility excluded record has wrong schema: "
                    f"run={run_number} record={index}"
                )
            file_name = record.get("fileName")
            overlay = record.get("crossImportOverlayModule")
            bystanders = record.get("bystanders")
            if (
                not isinstance(file_name, str)
                or PurePosixPath(file_name).name != file_name
                or not file_name.endswith(".symbols.json")
                or "@" not in file_name
                or not isinstance(overlay, str)
                or file_name[: -len(".symbols.json")].split("@", 1)[0] != overlay
                or overlay not in approved
                or record.get("graphModule") != module
                or not isinstance(bystanders, list)
                or not bystanders
                or bystanders != sorted(set(bystanders))
                or any(
                    not isinstance(value, str) or not MODULE_RE.fullmatch(value)
                    for value in bystanders
                )
                or not isinstance(record.get("sha256"), str)
                or not SHA256_RE.fullmatch(record["sha256"])
                or not is_int(record.get("symbolCount"))
                or record["symbolCount"] < 0
                or not is_int(record.get("relationshipCount"))
                or record["relationshipCount"] < 0
            ):
                self.error(
                    "symbol-graph reproducibility exclusion cannot be reclassified: "
                    f"run={run_number} record={index}"
                )
            if isinstance(file_name, str):
                names.append(file_name)
            if isinstance(overlay, str):
                observed_modules.add(overlay)
        if names != sorted(set(names)) or observed_modules != set(approved):
            self.error(
                f"symbol-graph reproducibility run {run_number} exclusion closure differs"
            )

    def _validate_public_surface(self, metadata: dict[str, Any]) -> None:
        rows = self._read_tsv(str(metadata.get("publicSurface")), SURFACE_HEADER)
        ids: list[str] = []
        for number, row in enumerate(rows, start=2):
            precise, kind, title, path, declaration = row
            if not precise:
                self.error(f"reference/public-surface.tsv:{number}: precise is required")
            if any(character in precise + kind for character in "\x00\r\n\t"):
                self.error(
                    f"reference/public-surface.tsv:{number}: control character in join key"
                )
            ids.append(precise)
        if ids != sorted(ids):
            self.error("reference/public-surface.tsv must be sorted by precise identifier")
        if len(set(ids)) != len(ids):
            self.error("reference/public-surface.tsv contains duplicate precise identifiers")
        self._compare_precise_sets("reference/public-surface.tsv", ids)
        expected_rows = [self.surface_by_precise[precise] for precise in self.precise_ids]
        if rows != expected_rows:
            for index, (actual, expected) in enumerate(
                zip(rows, expected_rows), start=2
            ):
                if actual != expected:
                    self.error(
                        f"reference/public-surface.tsv:{index}: row does not match raw graph"
                    )
                    break
            else:
                self.error(
                    "reference/public-surface.tsv rows do not exactly match raw graphs"
                )

    def _validate_api_digester(self, metadata: dict[str, Any]) -> None:
        document = self._read_strict_json(str(metadata.get("apiDigester")))
        if not isinstance(document, dict) or set(document) != {"ABIRoot"}:
            self.fatal("reference/api-digester.json must contain only ABIRoot")
        root = document.get("ABIRoot")
        if not isinstance(root, dict):
            self.fatal("reference/api-digester.json ABIRoot must be an object")
        if root.get("kind") != "Root":
            self.error("API digester ABIRoot kind must be Root")
        if root.get("name") != metadata.get("module"):
            self.error("API digester root name does not match framework module")
        if root.get("printedName") != metadata.get("module"):
            self.error("API digester printedName does not match framework module")
        if not isinstance(root.get("children"), list):
            self.error("API digester root children must be a list")
        format_version = root.get("json_format_version")
        if not is_int(format_version) or format_version <= 0:
            self.error("API digester json_format_version must be a positive integer")

        node_count = 0
        declarations: list[dict[str, Any]] = []

        def visit(
            value: Any,
            pointer: str,
            container_names: tuple[str, ...],
            *,
            direct_root_child: bool = False,
        ) -> None:
            nonlocal node_count
            if isinstance(value, list):
                for index, child in enumerate(value):
                    visit(child, f"{pointer}/{index}", container_names)
                return
            if not isinstance(value, dict):
                return
            for key in value:
                normalized = re.sub(r"[^a-z0-9]", "", key.casefold())
                if normalized in FORBIDDEN_API_KEY_NORMALIZATIONS:
                    self.fatal(
                        f"API digester forbidden provenance field {key!r} at {pointer}"
                    )
            kind = value.get("kind")
            if "kind" in value:
                if not isinstance(kind, str) or not kind or CONTROL_RE.search(kind):
                    self.fatal(f"API digester has an unsafe kind at {pointer}")
                node_count += 1

            child_container_names = container_names
            if "declKind" in value:
                for key in ("kind", "declKind", "moduleName", "name", "printedName"):
                    candidate = value.get(key)
                    if (
                        not isinstance(candidate, str)
                        or not candidate
                        or CONTROL_RE.search(candidate)
                    ):
                        self.fatal(f"API declaration {pointer} has an unsafe {key}")
                if not MODULE_RE.fullmatch(value["moduleName"]):
                    self.fatal(
                        f"API declaration {pointer} has an invalid module owner"
                    )
                usr = value.get("usr")
                if usr is not None and (
                    not isinstance(usr, str) or not usr or CONTROL_RE.search(usr)
                ):
                    self.fatal(f"API declaration {pointer} has an unsafe usr")
                static = value.get("static")
                if static is not None and type(static) is not bool:
                    self.fatal(
                        f"API declaration {pointer} has a non-boolean static"
                    )
                for key in API_LIST_FIELDS:
                    if key in value and not isinstance(value[key], list):
                        self.fatal(
                            f"API declaration {pointer} field {key} must be a list"
                        )
                attributes = value.get("declAttributes")
                if isinstance(attributes, list) and any(
                    not isinstance(attribute, str) or CONTROL_RE.search(attribute)
                    for attribute in attributes
                ):
                    self.fatal(
                        f"API declaration {pointer} has unsafe declaration attributes"
                    )
                decl_kind = value["declKind"]
                leaf = (
                    value["printedName"]
                    if decl_kind in CALLABLE_DECL_KINDS
                    else value["name"]
                )
                declarations.append(
                    {
                        "nodePath": pointer,
                        "directRootChild": direct_root_child,
                        "logicalPath": container_names + (leaf,),
                        "node": value,
                    }
                )
                if decl_kind in CONTAINER_DECL_KINDS:
                    child_container_names = container_names + (value["name"],)

            for key, child in value.items():
                child_pointer = f"{pointer}/{json_pointer_component(key)}"
                if isinstance(child, list):
                    for index, item in enumerate(child):
                        visit(
                            item,
                            f"{child_pointer}/{index}",
                            child_container_names,
                            direct_root_child=(
                                pointer == "/ABIRoot" and key == "children"
                            ),
                        )
                elif isinstance(child, dict):
                    visit(child, child_pointer, child_container_names)

        visit(root, "/ABIRoot", ())
        if node_count <= 1 or not declarations:
            self.error("API digester must contain declaration nodes")

        module = metadata.get("module")
        if not isinstance(module, str):
            self.fatal("framework module is unavailable for API crosswalk")
        usr_records: dict[str, list[dict[str, Any]]] = {}
        import_records: dict[str, list[dict[str, Any]]] = {}
        for record in declarations:
            node = record["node"]
            usr = node.get("usr")
            if isinstance(usr, str):
                usr_records.setdefault(usr, []).append(record)
            attributes = node.get("declAttributes")
            if (
                record["directRootChild"]
                and node.get("declKind") == "Import"
                and node.get("moduleName") == module
                and usr is None
                and isinstance(attributes, list)
                and "Exported" in attributes
                and node.get("name") == node.get("printedName")
                and isinstance(node.get("name"), str)
                and node["name"].startswith(f"{module}.")
            ):
                import_records.setdefault(node["name"], []).append(record)

        graph_facts: dict[str, tuple[str, tuple[str, ...]]] = {}
        for precise, symbol in self.canonical_symbols.items():
            kind_object = symbol.get("kind")
            graph_kind = (
                kind_object.get("identifier")
                if isinstance(kind_object, dict)
                else None
            )
            graph_path = symbol.get("pathComponents")
            if not isinstance(graph_kind, str) or not graph_kind:
                self.fatal(f"crosswalk graph kind is invalid for {precise}")
            if not isinstance(graph_path, list) or not all(
                isinstance(component, str) and not CONTROL_RE.search(component)
                for component in graph_path
            ):
                self.fatal(f"crosswalk graph path is invalid for {precise}")
            graph_facts[precise] = (graph_kind, tuple(graph_path))

        graph_import_key_counts: dict[str, int] = {}
        for _kind, graph_path in graph_facts.values():
            key = f"{module}." + ".".join(graph_path)
            graph_import_key_counts[key] = graph_import_key_counts.get(key, 0) + 1

        status_counts = {
            "exact-usr": 0,
            "import-name": 0,
            "ambiguous": 0,
            "unmatched": 0,
        }
        expected_rows: list[list[str]] = []
        for precise in sorted(
            self.canonical_symbols, key=lambda value: value.encode("utf-8")
        ):
            graph_kind, graph_path = graph_facts[precise]
            exact_records = usr_records.get(precise, [])
            owned = [
                record
                for record in exact_records
                if record["node"].get("moduleName") == module
                and record["node"].get("declKind") != "Import"
            ]
            foreign = [
                record
                for record in exact_records
                if record["node"].get("moduleName") != module
            ]
            selected: dict[str, Any] | None = None
            candidates: list[dict[str, Any]] = []
            compatible: list[dict[str, Any]] = []
            basis = "none"
            if owned:
                basis = "exact-usr"
                candidates = owned
                expected_decl_kinds = GRAPH_KIND_TO_DECL_KINDS.get(
                    graph_kind, frozenset()
                )
                compatible = [
                    record
                    for record in owned
                    if record["node"].get("declKind") in expected_decl_kinds
                    and not (
                        graph_kind in TYPE_MEMBER_GRAPH_KINDS
                        and record["node"].get("static") is not True
                    )
                    and not (
                        graph_kind in INSTANCE_MEMBER_GRAPH_KINDS
                        and record["node"].get("static") is True
                    )
                ]
                if len(compatible) > 1:
                    path_matches = [
                        record
                        for record in compatible
                        if record["logicalPath"] == graph_path
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
                import_key = f"{module}." + ".".join(graph_path)
                candidates = import_records.get(import_key, [])
                compatible = candidates
                if candidates:
                    basis = "exported-import-name"
                    if (
                        len(candidates) == 1
                        and graph_import_key_counts[import_key] == 1
                    ):
                        selected = candidates[0]
                        status = "import-name"
                    else:
                        status = "ambiguous"
                else:
                    status = "unmatched"
            status_counts[status] += 1
            candidate_paths = sorted(
                (record["nodePath"] for record in candidates),
                key=lambda value: value.encode("utf-8"),
            )
            expected_rows.append(
                [
                    precise,
                    graph_kind,
                    json.dumps(
                        list(graph_path),
                        ensure_ascii=False,
                        separators=(",", ":"),
                    ),
                    status,
                    basis,
                    str(len(candidates)),
                    str(len(compatible)),
                    selected["nodePath"] if selected is not None else "",
                    json.dumps(
                        candidate_paths,
                        ensure_ascii=False,
                        separators=(",", ":"),
                    ),
                ]
            )
        actual_rows = self._read_tsv(
            str(metadata.get("apiCrosswalk")), CROSSWALK_HEADER
        )
        if actual_rows != expected_rows:
            self.error(
                "reference/api-crosswalk.tsv does not match graph/API declaration facts"
            )

        provenance = metadata.get("provenance")
        if isinstance(provenance, dict):
            if provenance.get("apiDigesterFormatVersion") != format_version:
                self.error(
                    "provenance.apiDigesterFormatVersion does not match API digester"
                )
            if provenance.get("apiDigesterNodeCount") != node_count:
                self.error(
                    "provenance.apiDigesterNodeCount does not match API digester"
                )
            if provenance.get("apiDeclarationNodeCount") != len(declarations):
                self.error(
                    "provenance.apiDeclarationNodeCount does not match API digester"
                )
            owned_declarations = sum(
                record["node"].get("moduleName") == module
                for record in declarations
            )
            if provenance.get("apiOwnedDeclarationNodeCount") != owned_declarations:
                self.error(
                    "provenance.apiOwnedDeclarationNodeCount does not match API digester"
                )
            provenance_counts = {
                "exact-usr": provenance.get("apiCrosswalkExactUSRCount"),
                "import-name": provenance.get("apiCrosswalkImportNameCount"),
                "ambiguous": provenance.get("apiCrosswalkAmbiguousCount"),
                "unmatched": provenance.get("apiCrosswalkUnmatchedCount"),
            }
            if provenance_counts != status_counts:
                self.error("provenance API crosswalk counts do not match crosswalk")

    def _validate_external_evidence(self, metadata: dict[str, Any]) -> None:
        evidence = self._read_json(str(metadata.get("externalEvidence")))
        expected_keys = {"schema", "module", "lock", "policy", "sources"}
        if not isinstance(evidence, dict) or set(evidence) != expected_keys:
            self.fatal("reference/external-evidence.json has the wrong schema")
        if evidence.get("schema") != SCHEMA:
            self.error(f"external evidence schema must be {SCHEMA}")
        module = metadata.get("module")
        if evidence.get("module") != module:
            self.error("external evidence module does not match framework metadata")
        if not valid_external_policy(evidence.get("policy")):
            self.error("external evidence policy has invalid values")
        lock_record = evidence.get("lock")
        if not isinstance(lock_record, dict) or set(lock_record) != {
            "path",
            "sha256",
        }:
            self.fatal("external evidence lock record has the wrong schema")
        lock_relative = lock_record.get("path")
        lock_digest = lock_record.get("sha256")
        if lock_relative != EXTERNAL_EVIDENCE_LOCK:
            self.error(
                f"external evidence lock path must be {EXTERNAL_EVIDENCE_LOCK!r}"
            )
        if not isinstance(lock_digest, str) or not SHA256_RE.fullmatch(lock_digest):
            self.error("external evidence lock SHA-256 is invalid")
        try:
            lock_path = self._repo_file(str(lock_relative))
        except InvalidSeed:
            return
        actual_digest = self._sha256(lock_path)
        if lock_digest != actual_digest:
            self.error("external evidence lock digest does not match repository lock")
        provenance = metadata.get("provenance")
        if isinstance(provenance, dict):
            if provenance.get("externalEvidenceLockPath") != lock_relative:
                self.error("external evidence lock path does not match provenance")
            if provenance.get("externalEvidenceLockSHA256") != lock_digest:
                self.error("external evidence lock digest does not match provenance")
        try:
            lock = json.loads(lock_path.read_text(encoding="utf-8"))
        except (OSError, UnicodeError, json.JSONDecodeError) as exc:
            self.fatal(f"cannot parse external evidence lock: {exc}")
            return
        if (
            not isinstance(lock, dict)
            or set(lock) != {"schema", "policy", "sources"}
            or lock.get("schema") != SCHEMA
            or not isinstance(lock.get("sources"), list)
            or not lock["sources"]
        ):
            self.fatal("repository external evidence lock has the wrong schema")
        if not valid_external_policy(lock.get("policy")):
            self.fatal("repository external evidence policy has invalid values")
        if evidence.get("policy") != lock.get("policy"):
            self.error("external evidence policy differs from repository lock")

        expected_sources: list[dict[str, Any]] = []
        seen_ids: set[str] = set()
        seen_environment_variables: set[str] = set()
        for index, source in enumerate(lock["sources"]):
            if not isinstance(source, dict) or set(source) != EXTERNAL_SOURCE_KEYS:
                self.error(
                    f"external evidence lock source {index} has the wrong schema"
                )
                continue
            source_id = source.get("id")
            environment_variable = source.get("environmentVariable")
            repository = source.get("repository")
            license_path = source.get("licensePath")
            license_digest = source.get("licenseSHA256")
            license_summary = source.get("licenseSummary")
            commit = source.get("commit")
            capabilities = source.get("capabilities")
            templates = source.get("sourcePathTemplates")
            source_valid = True
            if (
                not isinstance(source_id, str)
                or EXTERNAL_SOURCE_ID_RE.fullmatch(source_id) is None
                or source_id in seen_ids
            ):
                self.error(f"external evidence lock source {index} has invalid ID")
                source_valid = False
            if (
                not isinstance(environment_variable, str)
                or EXTERNAL_ENVIRONMENT_RE.fullmatch(environment_variable) is None
                or environment_variable in seen_environment_variables
            ):
                self.error(
                    f"external evidence lock source {index} has invalid environment variable"
                )
                source_valid = False
            if (
                not isinstance(repository, str)
                or EXTERNAL_REPOSITORY_RE.fullmatch(repository) is None
            ):
                self.error(
                    f"external evidence lock source {index} has unapproved repository URL"
                )
                source_valid = False
            if (
                not isinstance(license_path, str)
                or not self._is_safe_relative_text(license_path)
            ):
                self.error(
                    f"external evidence lock source {index} has unsafe license path"
                )
                source_valid = False
            if not isinstance(commit, str) or re.fullmatch(r"[0-9a-f]{40}", commit) is None:
                self.error(f"external evidence lock source {index} has invalid commit")
                source_valid = False
            if (
                not isinstance(license_digest, str)
                or SHA256_RE.fullmatch(license_digest) is None
            ):
                self.error(
                    f"external evidence lock source {index} has invalid license digest"
                )
                source_valid = False
            if (
                not isinstance(license_summary, str)
                or not license_summary.strip()
                or CONTROL_RE.search(license_summary)
            ):
                self.error(
                    f"external evidence lock source {index} has invalid license summary"
                )
                source_valid = False
            if (
                not isinstance(capabilities, list)
                or not capabilities
                or any(
                    not isinstance(value, str)
                    or EXTERNAL_SOURCE_ID_RE.fullmatch(value) is None
                    for value in capabilities
                )
                or capabilities != sorted(set(capabilities))
            ):
                self.error(
                    f"external evidence lock source {index} has invalid capabilities"
                )
                source_valid = False
            if (
                not isinstance(templates, list)
                or not templates
                or len(templates) != len(set(templates))
                or any(
                    not isinstance(template, str)
                    or not template
                    or CONTROL_RE.search(template)
                    for template in templates
                )
            ):
                self.error(
                    f"external evidence lock source {index} has invalid path templates"
                )
                source_valid = False
            elif isinstance(module, str):
                for template in templates:
                    resolved_template = template.replace("{module}", module).replace(
                        "{moduleLower}", module.lower()
                    )
                    if (
                        "{" in resolved_template
                        or "}" in resolved_template
                        or not self._is_safe_relative_text(resolved_template.rstrip("/"))
                    ):
                        self.error(
                            f"external evidence lock source {index} has unsafe path template"
                        )
                        source_valid = False
                        break
            if not source_valid:
                continue
            seen_ids.add(source_id)
            seen_environment_variables.add(environment_variable)
            resolved = dict(source)
            del resolved["sourcePathTemplates"]
            resolved["suggestedSourcePaths"] = [
                template.replace("{module}", str(module)).replace(
                    "{moduleLower}", str(module).lower()
                )
                for template in templates
            ]
            expected_sources.append(resolved)
        if evidence.get("sources") != expected_sources:
            self.error("external evidence sources differ from pinned repository lock")

    def _validate_tbd_exports(self, metadata: dict[str, Any]) -> None:
        rows = self._read_tsv(str(metadata.get("tbdExports")), TBD_HEADER)
        keys: list[tuple[str, str]] = []
        for number, (symbol, sdk_path) in enumerate(rows, start=2):
            if not symbol or not sdk_path:
                self.error(f"reference/tbd-exports.tsv:{number}: both fields are required")
            if not self._is_safe_relative_text(sdk_path):
                self.error(
                    f"reference/tbd-exports.tsv:{number}: unsafe SDK-relative path"
                )
            keys.append((symbol, sdk_path))
        if keys != sorted(keys):
            self.error("reference/tbd-exports.tsv must be sorted")
        if len(set(keys)) != len(keys):
            self.error("reference/tbd-exports.tsv contains duplicate rows")
        provenance = metadata.get("provenance")
        if (
            isinstance(provenance, dict)
            and provenance.get("arm64TBDExportCount") != len(rows)
        ):
            self.error("provenance.arm64TBDExportCount does not match tbd export rows")

    def _validate_sdk_inputs(self, metadata: dict[str, Any]) -> None:
        rows = self._read_tsv(str(metadata.get("sdkInputs")), SDK_INPUT_HEADER)
        if not rows:
            self.error("reference/sdk-inputs.tsv must contain at least one SDK input")
        keys: list[tuple[str, str]] = []
        for number, (category, sdk_path, size_text, digest) in enumerate(rows, start=2):
            if category not in SDK_INPUT_CATEGORIES:
                self.error(
                    f"reference/sdk-inputs.tsv:{number}: invalid category {category!r}"
                )
            if not self._is_safe_relative_text(sdk_path):
                self.error(f"reference/sdk-inputs.tsv:{number}: unsafe SDK-relative path")
            try:
                size = int(size_text)
            except ValueError:
                size = -1
            if size < 0 or str(size) != size_text:
                self.error(
                    f"reference/sdk-inputs.tsv:{number}: size must be canonical nonnegative integer"
                )
            if not SHA256_RE.fullmatch(digest):
                self.error(f"reference/sdk-inputs.tsv:{number}: invalid SHA-256")
            keys.append((category, sdk_path))
        if len(set(keys)) != len(keys):
            self.error("reference/sdk-inputs.tsv contains duplicate inputs")
        provenance = metadata.get("provenance")
        if isinstance(provenance, dict):
            if provenance.get("rawSDKInputCount") != len(rows):
                self.error("provenance.rawSDKInputCount does not match SDK input rows")
            tbd_count = sum(category == "tbd" for category, _ in keys)
            if provenance.get("tbdInputCount") != tbd_count:
                self.error("provenance.tbdInputCount does not match SDK tbd input rows")

    def _validate_corpus(self, metadata: dict[str, Any]) -> None:
        corpus = self._read_json(str(metadata.get("corpusSummary")))
        if not isinstance(corpus, dict):
            self.fatal("reference/corpus-summary.json must contain an object")
        expected_keys = {
            "schema",
            "module",
            "source",
            "moduleRecord",
            "requestedFamilies",
            "rankings",
        }
        if set(corpus) != expected_keys:
            self.error("corpus summary keys differ from schema v1")
        if corpus.get("schema") != SCHEMA:
            self.error(f"corpus summary schema must be {SCHEMA}")
        if corpus.get("module") != metadata.get("module"):
            self.error("corpus summary module does not match framework metadata")
        source = corpus.get("source")
        if not isinstance(source, dict) or set(source) != {"path", "sha256", "schema"}:
            self.fatal("corpus summary source has wrong schema")
        path_text = source.get("path")
        digest = source.get("sha256")
        if not isinstance(path_text, str) or not isinstance(digest, str):
            self.fatal("corpus summary source path and sha256 must be strings")
        roadmap_path = self._repo_file(path_text)
        if not SHA256_RE.fullmatch(digest) or self._sha256(roadmap_path) != digest:
            self.error("corpus summary source digest does not match roadmap")
        provenance = metadata.get("provenance")
        if isinstance(provenance, dict):
            if path_text != provenance.get("roadmapPath"):
                self.error("corpus source path does not match provenance roadmapPath")
            if digest != provenance.get("roadmapSHA256"):
                self.error("corpus source digest does not match provenance roadmapSHA256")
        try:
            roadmap = json.loads(roadmap_path.read_text(encoding="utf-8"))
        except (OSError, UnicodeError, json.JSONDecodeError) as exc:
            self.fatal(f"cannot parse corpus roadmap {path_text}: {exc}")
            return
        if not isinstance(roadmap, dict):
            self.fatal("corpus roadmap must contain an object")
        if source.get("schema") != roadmap.get("schema"):
            self.error("corpus source schema does not match roadmap schema")
        module = metadata.get("module")
        modules = roadmap.get("modules")
        if not isinstance(modules, list):
            self.fatal("corpus roadmap modules must be a list")
        matching_modules = [
            record
            for record in modules
            if isinstance(record, dict) and record.get("module") == module
        ]
        operator_override = metadata.get("roadmap") == ROADMAP_OPERATOR_OVERRIDE
        if operator_override:
            if matching_modules:
                self.error(
                    "roadmap operator override is invalid when the roadmap "
                    f"contains a record for module {module!r}"
                )
            elif corpus.get("moduleRecord") != ROADMAP_OPERATOR_OVERRIDE_RECORD:
                self.error(
                    "corpus moduleRecord must record "
                    f"{ROADMAP_OPERATOR_OVERRIDE!r} when the seed uses the "
                    "roadmap operator override"
                )
        elif len(matching_modules) != 1:
            self.error(f"roadmap must contain exactly one record for module {module!r}")
        elif corpus.get("moduleRecord") != matching_modules[0]:
            self.error("corpus moduleRecord is not the exact pinned roadmap record")

        families = roadmap.get("requested_roadmap_families")
        if not isinstance(families, list):
            self.fatal("corpus roadmap requested_roadmap_families must be a list")
        expected_families = [
            family
            for family in families
            if isinstance(family, dict)
            and isinstance(family.get("modules"), list)
            and module in family["modules"]
        ]
        if corpus.get("requestedFamilies") != expected_families:
            self.error("corpus requestedFamilies is not the exact pinned roadmap subset")

        ranking_source = roadmap.get("iphoneos_runtime_port_candidate_rankings")
        rankings = corpus.get("rankings")
        if not isinstance(ranking_source, dict) or not isinstance(rankings, dict):
            self.error("corpus roadmap or summary rankings have wrong schema")
        elif set(rankings) != {
            "byAppCoverage",
            "byFocusLaunchBuildRelevance",
        }:
            self.error("corpus rankings keys differ from schema v1")
        else:
            expected_app = self._one_based_position(
                ranking_source.get("by_app_coverage"), module
            )
            expected_focus = self._one_based_position(
                ranking_source.get("by_focus_launch_build_relevance"), module
            )
            if rankings.get("byAppCoverage") != expected_app:
                self.error("corpus byAppCoverage rank does not match roadmap")
            if rankings.get("byFocusLaunchBuildRelevance") != expected_focus:
                self.error("corpus byFocusLaunchBuildRelevance rank does not match roadmap")

    @staticmethod
    def _one_based_position(values: Any, wanted: Any) -> int | None:
        if not isinstance(values, list):
            return None
        try:
            return values.index(wanted) + 1
        except ValueError:
            return None

    @staticmethod
    def _is_safe_relative_text(value: str) -> bool:
        if not isinstance(value, str) or not value or "\\" in value:
            return False
        path = PurePosixPath(value)
        return not path.is_absolute() and all(
            part not in {"", ".", ".."} for part in path.parts
        )

    def _validate_digest(self, relative: str, expected_paths: set[str]) -> None:
        path = self._framework_file(relative)
        try:
            raw = path.read_bytes()
            text = raw.decode("ascii")
        except (OSError, UnicodeError) as exc:
            self.fatal(f"cannot read ASCII digest {relative}: {exc}")
        if not raw.endswith(b"\n"):
            self.error(f"digest must end in a newline: {relative}")
        entries: list[tuple[str, str]] = []
        for number, line in enumerate(text.splitlines(), start=1):
            match = re.fullmatch(r"([0-9a-f]{64})  (.+)", line)
            if not match:
                self.error(f"{relative}:{number}: malformed digest row")
                continue
            digest, target = match.groups()
            entries.append((target, digest))
        targets = [target for target, _ in entries]
        if targets != sorted(targets):
            self.error(f"digest rows must be path-sorted: {relative}")
        if len(set(targets)) != len(targets):
            self.error(f"digest contains duplicate paths: {relative}")
        actual_set = set(targets)
        if actual_set != expected_paths:
            self.error(
                f"digest path set mismatch in {relative}: "
                f"missing={sorted(expected_paths - actual_set)}, "
                f"extra={sorted(actual_set - expected_paths)}"
            )
        for target, expected_digest in entries:
            try:
                target_path = self._framework_file(target)
            except InvalidSeed:
                continue
            actual_digest = self._sha256(target_path)
            if actual_digest != expected_digest:
                self.error(
                    f"immutable digest mismatch for {target}: "
                    f"expected {expected_digest}, got {actual_digest}"
                )

    def _compare_precise_sets(self, label: str, values: Iterable[str]) -> None:
        actual = set(values)
        expected = set(self.precise_ids)
        if actual != expected:
            self.error(
                f"{label} precise-ID accounting mismatch: "
                f"missing={sorted(expected - actual)[:10]}, "
                f"extra={sorted(actual - expected)[:10]}"
            )

    def _validate_deliverable(self) -> None:
        assert self.framework is not None
        assert self.metadata is not None
        module = self.metadata.get("module")
        slug = self.framework.name
        if not isinstance(module, str):
            self.fatal("cannot validate deliverable without a valid module name")
        smoke_name = (
            f"tests/agent/{module}LoadSmoke.swift"
            if self.metadata.get("schema") == 2
            else f"tests/agent/{module}Runtime.swift"
        )
        required = {
            "implementation": f"{module}.swift",
            "manifest": f"{slug}_guest_sources.txt",
            "readme": "README.md",
            "coverage": "coverage.tsv",
            "oracle": "oracle-questions.tsv",
            "loadSmoke": smoke_name,
        }
        paths = {name: self._framework_file(path) for name, path in required.items()}
        for name in ("implementation", "readme", "loadSmoke"):
            if paths[name].stat().st_size == 0:
                self.error(f"deliverable file must not be empty: {required[name]}")

        self._validate_guest_manifest(paths["manifest"], required["implementation"])

        try:
            load_smoke_source = paths["loadSmoke"].read_text(encoding="utf-8")
        except (OSError, UnicodeError) as exc:
            self.error(f"cannot read load smoke probe {required['loadSmoke']}: {exc}")
        else:
            self.load_smoke_source = load_smoke_source
            marker = self.metadata.get("runtimeMarker")
            if not isinstance(marker, str) or marker not in load_smoke_source:
                self.error(
                    f"load smoke probe must contain exact success marker {marker!r}"
                )
            if self.metadata.get("schema") == 2:
                expected_load_smoke = (
                    f'import {module}\n\n'
                    f'let frameworkLoadSmokeMarker = "{marker}"\n'
                )
                if load_smoke_source != expected_load_smoke:
                    self.error(
                        "schema-v2 load smoke must exactly match the canonical "
                        "module-import and marker declaration"
                    )

        self._validate_coverage(paths["coverage"])
        self._validate_oracle_questions(paths["oracle"])

        dependencies = self.metadata.get("dependencies")
        if self.metadata.get("schema") == 2 and isinstance(dependencies, list) and dependencies:
            identity_relative = f"tests/agent/{module}DependencyIdentity.swift"
            identity_path = self._framework_file(identity_relative)
            try:
                identity_source = identity_path.read_text(encoding="utf-8")
            except (OSError, UnicodeError) as exc:
                self.error(f"cannot read dependency identity probe: {exc}")
            else:
                for imported_module in [module, *dependencies]:
                    pattern = re.compile(
                        rf"(?m)^\s*(?:@testable\s+)?import\s+{re.escape(imported_module)}\s*$"
                    )
                    if pattern.search(identity_source) is None:
                        self.error(
                            f"dependency identity probe must import {imported_module}"
                        )

    def _validate_guest_manifest(self, path: Path, implementation: str) -> None:
        assert self.framework is not None
        try:
            raw = path.read_bytes()
            text = raw.decode("utf-8")
        except (OSError, UnicodeError) as exc:
            self.fatal(f"cannot read guest source manifest: {exc}")
        if not raw.endswith(b"\n"):
            self.error("guest source manifest must end in a newline")
        entries = text.splitlines()
        self.guest_sources = set(entries)
        if not entries:
            self.error("guest source manifest must list at least one Swift source")
            return
        if entries != sorted(entries):
            self.error("guest source manifest must be path-sorted")
        if len(set(entries)) != len(entries):
            self.error("guest source manifest contains duplicate paths")
        expected_prefix = f"full/{self.framework.name}/"
        expected_main = expected_prefix + implementation
        if expected_main not in entries:
            self.error(f"guest source manifest must include {expected_main}")
        for number, entry in enumerate(entries, start=1):
            if not entry or entry.strip() != entry:
                self.error(f"guest source manifest:{number}: blank or padded path")
                continue
            if not entry.startswith(expected_prefix) or not entry.endswith(".swift"):
                self.error(
                    f"guest source manifest:{number}: source must be a repo-relative "
                    f".swift path beneath {expected_prefix}"
                )
                continue
            relative = entry[len(expected_prefix) :]
            parts = PurePosixPath(relative).parts
            if "tests" in parts or any(part in BUILD_DIRECTORY_NAMES for part in parts):
                self.error(
                    f"guest source manifest:{number}: tests/build paths are forbidden: {entry}"
                )
                continue
            try:
                self._framework_file(relative)
            except InvalidSeed:
                continue

    def _validate_coverage(self, path: Path) -> None:
        relative = path.relative_to(self.framework).as_posix()  # type: ignore[arg-type]
        rows = self._read_tsv(relative, COVERAGE_HEADER)
        ids: list[str] = []
        nondeferred = 0
        for number, (precise, status_value, evidence, notes) in enumerate(rows, start=2):
            ids.append(precise)
            if status_value not in ALLOWED_STATUSES:
                self.error(f"coverage.tsv:{number}: invalid status {status_value!r}")
            if status_value in NONDEFERRED_STATUSES:
                nondeferred += 1
                if not evidence.strip():
                    self.error(
                        f"coverage.tsv:{number}: {status_value} row needs evidence"
                    )
                elif self.metadata and self.metadata.get("schema") == 2:
                    self._validate_schema2_coverage_evidence(
                        number, status_value, evidence
                    )
            elif status_value in ALLOWED_STATUSES and not notes.strip():
                self.error(
                    f"coverage.tsv:{number}: {status_value} row needs an explanatory note"
                )
        if len(set(ids)) != len(ids):
            self.error("coverage.tsv contains duplicate precise identifiers")
        self._compare_precise_sets("coverage.tsv", ids)
        policy = self.metadata.get("coveragePolicy") if self.metadata else None
        minimum = policy.get("minimumNondeferredCount") if isinstance(policy, dict) else None
        if is_int(minimum) and nondeferred < minimum:
            self.error(
                f"coverage.tsv has {nondeferred} implemented/declared IDs; "
                f"lane {self.metadata.get('lane')!r} requires at least {minimum}"
            )

    def _validate_schema2_coverage_evidence(
        self, number: int, status_value: str, evidence: str
    ) -> None:
        assert self.framework is not None
        expected_prefix = "test:" if status_value == "implemented" else "source:"
        if not evidence.startswith(expected_prefix):
            self.error(
                f"coverage.tsv:{number}: {status_value} evidence must start with "
                f"{expected_prefix!r}"
            )
            return
        body = evidence[len(expected_prefix) :]
        relative, separator, anchor = body.rpartition("#")
        if (
            not separator
            or not self._is_safe_relative_text(relative)
            or re.fullmatch(r"[A-Za-z_][A-Za-z0-9_]*", anchor) is None
        ):
            self.error(
                f"coverage.tsv:{number}: evidence must be a safe repo path plus #identifier"
            )
            return

        slug = self.framework.name
        framework_prefix = f"full/{slug}/"
        if not relative.startswith(framework_prefix):
            self.error(
                f"coverage.tsv:{number}: evidence path must be beneath {framework_prefix}"
            )
            return
        local_relative = relative[len(framework_prefix) :]
        try:
            source_path = self._framework_file(local_relative)
            source_text = source_path.read_text(encoding="utf-8")
        except (InvalidSeed, OSError, UnicodeError):
            self.error(f"coverage.tsv:{number}: evidence source is missing or unreadable")
            return

        if status_value == "declared":
            if relative not in self.guest_sources:
                self.error(
                    f"coverage.tsv:{number}: declared evidence must cite a product source"
                )
            try:
                source_code = swift_code_projection(source_text)
            except ValueError as exc:
                self.error(
                    f"coverage.tsv:{number}: invalid Swift product source: {exc}"
                )
                return
            if re.search(rf"\b{re.escape(anchor)}\b", source_code) is None:
                self.error(
                    f"coverage.tsv:{number}: declared evidence anchor is absent from "
                    "Swift code"
                )
            return

        expected_test_prefix = f"full/{slug}/tests/agent/"
        if (
            not relative.startswith(expected_test_prefix)
            or not relative.endswith("Tests.swift")
            or not anchor.startswith("test")
        ):
            self.error(
                f"coverage.tsv:{number}: implemented evidence must cite a test* function "
                "in tests/agent/*Tests.swift"
            )
            return
        try:
            source_code = swift_code_projection(source_text)
        except ValueError as exc:
            self.error(f"coverage.tsv:{number}: invalid Swift test source: {exc}")
            return
        declaration_pattern = re.compile(
            rf"(?m)^[ \t]*func[ \t]+{re.escape(anchor)}[ \t]*"
            r"\([ \t]*\)[ \t\r\n]*(?:->[ \t]*Void[ \t\r\n]*)?\{"
        )
        if declaration_pattern.search(source_code) is None:
            self.error(
                f"coverage.tsv:{number}: implemented evidence must define a top-level "
                "synchronous no-argument test function"
            )

    def _validate_oracle_questions(self, path: Path) -> None:
        relative = path.relative_to(self.framework).as_posix()  # type: ignore[arg-type]
        rows = self._read_tsv(relative, ORACLE_HEADER)
        if not rows:
            self.error("oracle-questions.tsv must contain at least one question")
            return
        seen: set[tuple[str, str, str, str]] = set()
        precise_set = set(self.precise_ids)
        for number, row in enumerate(rows, start=2):
            precise, question, risk, reason = row
            if any(not field.strip() for field in row):
                self.error(f"oracle-questions.tsv:{number}: all fields must be nonempty")
            if precise != "module" and precise not in precise_set:
                self.error(
                    f"oracle-questions.tsv:{number}: precise must be 'module' or an exact graph ID"
                )
            key = tuple(row)
            if key in seen:
                self.error(f"oracle-questions.tsv:{number}: duplicate question row")
            seen.add(key)


def parse_args(argv: Sequence[str]) -> argparse.Namespace:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "--framework",
        required=True,
        type=Path,
        help="direct framework directory, normally full/<slug>",
    )
    parser.add_argument("--phase", required=True, choices=("seed", "deliverable"))
    return parser.parse_args(argv)


def main(argv: Sequence[str] | None = None) -> int:
    args = parse_args(sys.argv[1:] if argv is None else argv)
    repo_root = Path(__file__).resolve().parents[2]
    validator = Validator(repo_root, args.framework, args.phase)
    errors = validator.validate()
    if errors:
        print(
            f"FRAMEWORK_FANOUT_{args.phase.upper()}_INVALID errors={len(errors)}",
            file=sys.stderr,
        )
        for error in errors:
            print(f"- {error}", file=sys.stderr)
        return 1
    metadata = validator.metadata or {}
    print(
        f"FRAMEWORK_FANOUT_{args.phase.upper()}_OK "
        f"module={metadata.get('module')} lane={metadata.get('lane')} "
        f"symbols={len(validator.precise_ids)}"
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
