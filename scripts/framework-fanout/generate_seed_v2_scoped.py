#!/usr/bin/env python3
"""Generate a schema-v2 seed with an explicit cross-import-overlay scope.

Swift's symbol-graph extractor intentionally emits cross-import overlays when
some SDK modules are inspected.  Those overlays are separate Swift modules and
must not silently inflate a base-framework dossier.  This additive generator
uses ``generate_seed_v2.py`` for extraction and every ordinary seed artifact,
but intercepts the extractor output before the base generator consumes it.  It
keeps all base-module and base extension graphs byte-for-byte, removes only
graphs whose exact declaring overlay module is explicitly approved on the
command line, and seals names, counts, and raw hashes for every emitted graph in
``reference/symbol-graph-scope.json``.

The original generator is deliberately not modified: already-published schema-
v2 seeds pin its exact SHA-256.
"""

from __future__ import annotations

import argparse
import hashlib
import json
from pathlib import Path, PurePosixPath
import shutil
import sys
import tempfile
from typing import Any, Sequence

import generate_seed_v2 as base


SCOPE_SCHEMA = 1
SCOPE_POLICY = (
    "base-module-and-extension-graphs-with-exact-cross-import-overlay-"
    "exclusions-v1"
)
SCOPE_PATH = "reference/symbol-graph-scope.json"
REPRODUCIBILITY_PATH = "reference/symbol-graph-reproducibility.json"
SCOPED_GENERATOR_PATH = "scripts/framework-fanout/generate_seed_v2_scoped.py"
BASE_GENERATOR_PATH = "scripts/framework-fanout/generate_seed_v2.py"
REPRODUCIBILITY_SCHEMA = 1
REPRODUCIBILITY_POLICY = (
    "three-fresh-extractions-with-raw-volatility-and-stable-derived-evidence-v1"
)
PROJECTION_SCHEMA = 1
PROJECTION_POLICY = (
    "exclude-primary-imported-objc-class-conformsTo-swift-sendable-v1"
)
PROJECTION_REASON = (
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
CANONICAL_OUTPUT_PATHS = (
    "reference/public-surface.tsv",
    "reference/api-digester.json",
    "reference/api-crosswalk.tsv",
    "reference/symbol-conflicts.tsv",
    "reference/tbd-exports.tsv",
    "reference/sdk-inputs.tsv",
    "reference/corpus-summary.json",
    "reference/external-evidence.json",
)
DEFAULT_REPRODUCIBILITY_RUN_COUNT = 3


class ScopedSeedError(RuntimeError):
    """A fail-closed scope, extraction, or publication error."""


def json_bytes(value: Any) -> bytes:
    return (
        json.dumps(value, ensure_ascii=False, indent=2, sort_keys=True) + "\n"
    ).encode("utf-8")


def _graph_documents(
    graph_root: Path, requested_module: str
) -> list[tuple[Path, dict[str, Any]]]:
    if not graph_root.is_dir() or graph_root.is_symlink():
        raise ScopedSeedError("retained symbol graph root is missing or unsafe")
    paths = sorted(graph_root.glob("*.symbols.json"), key=lambda value: value.name)
    if not paths:
        raise ScopedSeedError("retained symbol graph root is empty")
    unexpected = sorted(path.name for path in graph_root.iterdir() if path not in paths)
    if unexpected:
        raise ScopedSeedError(
            f"retained symbol graph root has unexpected entries: {unexpected}"
        )
    documents: list[tuple[Path, dict[str, Any]]] = []
    for path in paths:
        if path.is_symlink() or not path.is_file():
            raise ScopedSeedError(f"retained graph is not a regular file: {path.name}")
        graph = base.strict_json_load(path, label=f"retained graph {path.name}")
        if not isinstance(graph, dict):
            raise ScopedSeedError(f"retained graph root is not an object: {path.name}")
        module = graph.get("module")
        if not isinstance(module, dict) or module.get("name") != requested_module:
            raise ScopedSeedError(
                f"retained graph does not describe {requested_module}: {path.name}"
            )
        if not isinstance(graph.get("symbols"), list) or not isinstance(
            graph.get("relationships"), list
        ):
            raise ScopedSeedError(
                f"retained graph lacks symbol/relationship arrays: {path.name}"
            )
        documents.append((path, graph))
    return documents


def compute_base_relationship_projection(
    graph_root: Path, requested_module: str
) -> dict[str, Any]:
    """Compute a narrow, auditable projection without modifying raw graphs."""

    documents = _graph_documents(graph_root, requested_module)
    primary_name = f"{requested_module}.symbols.json"
    primary = next((graph for path, graph in documents if path.name == primary_name), None)
    if primary is None:
        raise ScopedSeedError(f"primary graph is missing: {primary_name}")

    imported_objc_classes: set[str] = set()
    for index, symbol in enumerate(primary["symbols"]):
        if not isinstance(symbol, dict):
            raise ScopedSeedError(f"non-object symbol in {primary_name}[{index}]")
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
    for path, graph in documents:
        for index, relationship in enumerate(graph["relationships"]):
            if not isinstance(relationship, dict):
                raise ScopedSeedError(
                    f"non-object relationship in {path.name}[{index}]"
                )
            payload = base.canonical_json_bytes(
                relationship,
                label=f"scoped relationship {path.name}[{index}]",
            )
            raw_payloads.append(payload)
            is_volatile = (
                path.name == primary_name
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
        repeated = [payload] * count
        excluded_rows.append(
            {
                "relationship": relationship,
                "canonicalSHA256": hashlib.sha256(payload).hexdigest(),
                "source": relationship["source"],
                "target": relationship["target"],
                "targetFallback": relationship.get("targetFallback"),
                "sourceOrigin": relationship.get("sourceOrigin"),
                "count": count,
                "multisetSHA256": base.semantic_multiset_sha256(
                    EXCLUDED_RELATIONSHIP_MULTISET_DOMAIN, repeated
                ),
                "reason": PROJECTION_REASON,
            }
        )

    return {
        "schema": PROJECTION_SCHEMA,
        "policy": PROJECTION_POLICY,
        "reason": PROJECTION_REASON,
        "primaryGraphFileName": primary_name,
        "targets": [
            {"precise": precise, "fallback": SENDABLE_TARGETS[precise]}
            for precise in sorted(SENDABLE_TARGETS)
        ],
        "rawRelationshipOccurrenceCount": len(raw_payloads),
        "rawRelationshipMultisetSHA256": base.semantic_multiset_sha256(
            base.RELATIONSHIP_MULTISET_DOMAIN, raw_payloads
        ),
        "projectedRelationshipOccurrenceCount": len(projected_payloads),
        "projectedRelationshipMultisetSHA256": base.semantic_multiset_sha256(
            PROJECTED_RELATIONSHIP_MULTISET_DOMAIN, projected_payloads
        ),
        "excludedRelationshipOccurrenceCount": len(excluded_payloads),
        "excludedRelationshipMultisetSHA256": base.semantic_multiset_sha256(
            EXCLUDED_RELATIONSHIP_MULTISET_DOMAIN, excluded_payloads
        ),
        "excludedRows": excluded_rows,
    }


def compute_graph_summary(
    graph_root: Path, requested_module: str
) -> dict[str, Any]:
    documents = _graph_documents(graph_root, requested_module)
    precise_ids: set[str] = set()
    symbol_payloads: list[bytes] = []
    symbol_occurrence_count = 0
    for path, graph in documents:
        for index, symbol in enumerate(graph["symbols"]):
            if not isinstance(symbol, dict):
                raise ScopedSeedError(f"non-object symbol in {path.name}[{index}]")
            identifier = symbol.get("identifier")
            precise = identifier.get("precise") if isinstance(identifier, dict) else None
            if not isinstance(precise, str) or not precise:
                raise ScopedSeedError(
                    f"symbol lacks a precise identifier in {path.name}[{index}]"
                )
            precise_ids.add(precise)
            symbol_payloads.append(
                base.canonical_json_bytes(
                    symbol, label=f"scoped symbol {path.name}[{index}]"
                )
            )
            symbol_occurrence_count += 1
    projection = compute_base_relationship_projection(graph_root, requested_module)
    return {
        "uniqueSymbolCount": len(precise_ids),
        "symbolOccurrenceCount": symbol_occurrence_count,
        "symbolMultisetSHA256": base.semantic_multiset_sha256(
            base.SYMBOL_MULTISET_DOMAIN, symbol_payloads
        ),
        "rawRelationshipOccurrenceCount": projection[
            "rawRelationshipOccurrenceCount"
        ],
        "rawRelationshipMultisetSHA256": projection[
            "rawRelationshipMultisetSHA256"
        ],
        "baseRelationshipProjection": projection,
    }


def _graph_record(
    path: Path,
    requested_module: str,
    approved_exclusions: frozenset[str],
) -> tuple[dict[str, Any], bool]:
    name = path.name
    suffix = ".symbols.json"
    if not name.endswith(suffix) or name == suffix:
        raise ScopedSeedError(f"unexpected symbol graph file name: {name!r}")
    stem = name[: -len(suffix)]
    declaring_module = stem.split("@", 1)[0]
    if not base.MODULE_RE.fullmatch(declaring_module):
        raise ScopedSeedError(
            f"symbol graph has an invalid declaring module in its name: {name!r}"
        )

    graph = base.strict_json_load(path, label=f"scoped symbol graph {name}")
    if not isinstance(graph, dict):
        raise ScopedSeedError(f"symbol graph root is not an object: {name}")
    module = graph.get("module")
    symbols = graph.get("symbols")
    relationships = graph.get("relationships")
    if (
        not isinstance(module, dict)
        or module.get("name") != requested_module
        or not isinstance(symbols, list)
        or not isinstance(relationships, list)
    ):
        raise ScopedSeedError(
            f"symbol graph does not describe requested module {requested_module}: {name}"
        )
    raw_bystanders = module.get("bystanders", [])
    if (
        not isinstance(raw_bystanders, list)
        or any(
            not isinstance(value, str) or not base.MODULE_RE.fullmatch(value)
            for value in raw_bystanders
        )
        or len(raw_bystanders) != len(set(raw_bystanders))
    ):
        raise ScopedSeedError(f"symbol graph has invalid bystanders: {name}")
    bystanders = sorted(raw_bystanders)
    is_cross_import = bool(bystanders)

    if is_cross_import:
        if "@" not in stem:
            raise ScopedSeedError(
                f"cross-import graph does not encode its declaring module: {name}"
            )
        if declaring_module not in approved_exclusions:
            raise ScopedSeedError(
                "unapproved cross-import overlay graph emitted: "
                f"module={declaring_module} file={name}"
            )
    else:
        if declaring_module != requested_module:
            raise ScopedSeedError(
                "unapproved non-base symbol graph emitted: "
                f"module={declaring_module} file={name}"
            )
        if declaring_module in approved_exclusions:
            raise ScopedSeedError(
                f"approved overlay module lacks cross-import bystanders: {name}"
            )

    record = {
        "fileName": name,
        "sha256": base.sha256_file(path),
        "symbolCount": len(symbols),
        "relationshipCount": len(relationships),
        "graphModule": requested_module,
        "bystanders": bystanders,
        "crossImportOverlayModule": declaring_module if is_cross_import else None,
    }
    return record, is_cross_import


def classify_symbol_graphs(
    raw_root: Path,
    requested_module: str,
    approved_exclusions: Sequence[str],
) -> dict[str, Any]:
    """Return deterministic full-closure evidence without mutating ``raw_root``."""

    if not raw_root.is_dir() or raw_root.is_symlink():
        raise ScopedSeedError("extractor output root is missing or unsafe")
    if not base.MODULE_RE.fullmatch(requested_module):
        raise ScopedSeedError(f"invalid requested module: {requested_module!r}")
    exclusions = tuple(sorted(approved_exclusions))
    if (
        not exclusions
        or len(exclusions) != len(set(exclusions))
        or any(not base.MODULE_RE.fullmatch(value) for value in exclusions)
        or requested_module in exclusions
    ):
        raise ScopedSeedError(
            "approved cross-import overlay modules must be unique exact module names"
        )
    approved = frozenset(exclusions)

    paths = sorted(raw_root.glob("*.symbols.json"), key=lambda value: value.name)
    if not paths:
        raise ScopedSeedError("symbol graph extraction produced no files")
    unexpected_entries = sorted(
        path.name
        for path in raw_root.iterdir()
        if path not in paths
    )
    if unexpected_entries:
        raise ScopedSeedError(
            f"extractor output contains unexpected entries: {unexpected_entries}"
        )

    included: list[dict[str, Any]] = []
    excluded: list[dict[str, Any]] = []
    for path in paths:
        if path.is_symlink() or not path.is_file():
            raise ScopedSeedError(f"symbol graph is not a regular file: {path.name}")
        record, is_cross_import = _graph_record(
            path, requested_module, approved
        )
        (excluded if is_cross_import else included).append(record)

    if not any(record["fileName"] == f"{requested_module}.symbols.json" for record in included):
        raise ScopedSeedError(
            f"primary base-module graph is missing: {requested_module}.symbols.json"
        )
    observed_exclusions = {
        record["crossImportOverlayModule"] for record in excluded
    }
    if observed_exclusions != set(exclusions):
        raise ScopedSeedError(
            "approved exclusion set does not equal emitted cross-import overlay set: "
            f"approved={list(exclusions)} observed={sorted(observed_exclusions)}"
        )

    included_symbols = sum(record["symbolCount"] for record in included)
    included_relationships = sum(
        record["relationshipCount"] for record in included
    )
    excluded_symbols = sum(record["symbolCount"] for record in excluded)
    excluded_relationships = sum(
        record["relationshipCount"] for record in excluded
    )
    return {
        "schema": SCOPE_SCHEMA,
        "policy": SCOPE_POLICY,
        "requestedModule": requested_module,
        "approvedExcludedCrossImportOverlayModules": list(exclusions),
        "includedFiles": included,
        "excludedFiles": excluded,
        "includedFileCount": len(included),
        "includedSymbolOccurrenceCount": included_symbols,
        "includedRelationshipOccurrenceCount": included_relationships,
        "excludedFileCount": len(excluded),
        "excludedSymbolOccurrenceCount": excluded_symbols,
        "excludedRelationshipOccurrenceCount": excluded_relationships,
        "rawExtractorFileCount": len(paths),
        "rawExtractorSymbolOccurrenceCount": included_symbols + excluded_symbols,
        "rawExtractorRelationshipOccurrenceCount": (
            included_relationships + excluded_relationships
        ),
        "sourceGenerator": {
            "path": BASE_GENERATOR_PATH,
            "sha256": "",  # Filled from the repository immediately before sealing.
        },
    }


def remove_classified_exclusions(raw_root: Path, scope: dict[str, Any]) -> None:
    for record in scope["excludedFiles"]:
        file_name = record["fileName"]
        if PurePosixPath(file_name).name != file_name:
            raise ScopedSeedError(f"unsafe excluded graph name: {file_name!r}")
        path = raw_root / file_name
        if path.is_symlink() or not path.is_file():
            raise ScopedSeedError(f"excluded graph disappeared before filtering: {file_name}")
        if base.sha256_file(path) != record["sha256"]:
            raise ScopedSeedError(f"excluded graph changed before filtering: {file_name}")
        path.unlink()


def _replace_scope_instructions(dossier: Path, exclusions: Sequence[str]) -> None:
    agents = dossier / "AGENTS.md"
    text = agents.read_text(encoding="utf-8")
    old = (
        "All extractor-emitted graph files are preserved byte-for-byte. Apple graphs can\n"
        "legitimately repeat a precise identifier."
    )
    modules = ", ".join(f"`{value}`" for value in exclusions)
    new = (
        "All in-scope base-module and base-extension graph files are preserved byte-for-byte.\n"
        "The extractor also emitted cross-import overlay graphs for "
        f"{modules}; those separate\n"
        "modules are excluded by exact name, while their file names, counts, bystanders, and\n"
        "raw hashes are sealed in `reference/symbol-graph-scope.json`. Three fresh base-graph\n"
        "extractions and their ordinary raw relationship hashes are retained in\n"
        "`reference/symbol-graph-reproducibility.json`. Its additional stable projection\n"
        "excludes only the recorded Xcode 26.1 Sendable-conformance emitter volatility; it\n"
        "does not replace the ordinary schema-v2 raw hash. Apple graphs can legitimately\n"
        "repeat a precise identifier."
    )
    if text.count(old) != 1:
        raise ScopedSeedError("generated AGENTS.md scope paragraph differs")
    base.write_text(agents, text.replace(old, new))


def _reseal_dossier(
    dossier: Path,
    repo_root: Path,
    scope: dict[str, Any],
    exclusions: Sequence[str],
) -> None:
    base_generator = repo_root / BASE_GENERATOR_PATH
    scoped_generator = repo_root / SCOPED_GENERATOR_PATH
    if not base_generator.is_file() or not scoped_generator.is_file():
        raise ScopedSeedError("scoped generator provenance files are missing")
    scope["sourceGenerator"] = {
        "path": BASE_GENERATOR_PATH,
        "sha256": base.sha256_file(base_generator),
    }
    base.write_json(dossier / SCOPE_PATH, scope)

    framework_path = dossier / "reference/framework.json"
    framework = base.strict_json_load(
        framework_path, label="scoped framework metadata"
    )
    if not isinstance(framework, dict) or framework.get("schema") != 2:
        raise ScopedSeedError("base generator did not produce schema-v2 metadata")
    provenance = framework.get("provenance")
    if not isinstance(provenance, dict):
        raise ScopedSeedError("base generator did not produce provenance")
    provenance["generatorPath"] = SCOPED_GENERATOR_PATH
    provenance["generatorSHA256"] = base.sha256_file(scoped_generator)
    base.write_json(framework_path, framework)
    _replace_scope_instructions(dossier, exclusions)

    reference = dossier / "reference"
    immutable_paths = [
        "AGENTS.md",
        "FANOUT_TASK.md",
        "tests/acceptance/test_host.sh",
    ]
    immutable_paths.extend(
        path.relative_to(dossier).as_posix()
        for path in reference.rglob("*")
        if path.is_file()
        and path.relative_to(dossier).as_posix()
        != "reference/immutable-files.sha256"
    )
    base.write_text(
        reference / "immutable-files.sha256",
        base.digest_lines(dossier, immutable_paths),
    )


def _canonical_output_records(
    dossier: Path, retained_prefix: str | None
) -> list[dict[str, str]]:
    records: list[dict[str, str]] = []
    for source_relative in CANONICAL_OUTPUT_PATHS:
        source = dossier / source_relative
        if not source.is_file() or source.is_symlink():
            raise ScopedSeedError(
                f"canonical generated output is missing or unsafe: {source_relative}"
            )
        if retained_prefix is None:
            retained_relative = source_relative
        else:
            retained_relative = (
                f"{retained_prefix}/canonical/{PurePosixPath(source_relative).name}"
            )
        records.append(
            {
                "sourcePath": source_relative,
                "retainedPath": retained_relative,
                "sha256": base.sha256_file(source),
            }
        )
    return records


def _extraction_provenance(dossier: Path, module: str) -> dict[str, Any]:
    framework = base.strict_json_load(
        dossier / "reference/framework.json", label="run framework metadata"
    )
    provenance = framework.get("provenance") if isinstance(framework, dict) else None
    if not isinstance(provenance, dict):
        raise ScopedSeedError("run framework metadata lacks provenance")
    keys = (
        "xcodeVersion",
        "xcodeBuild",
        "sdkName",
        "sdkVersion",
        "target",
        "symbolGraphExtractorPath",
        "symbolGraphExtractorSHA256",
        "symbolGraphExtractorVersion",
    )
    result = {key: provenance.get(key) for key in keys}
    if any(not isinstance(value, str) or not value for value in result.values()):
        raise ScopedSeedError("run extractor/toolchain provenance is incomplete")
    result["commandTemplate"] = [
        "{symbolGraphExtractorPath}",
        "-module-name",
        module,
        "-target",
        provenance["target"],
        "-sdk",
        "{iPhoneOSSDKRoot}",
        "-minimum-access-level",
        "public",
        "-module-cache-path",
        "{freshTemporaryModuleCache}",
        "-output-dir",
        "{freshTemporaryOutputDirectory}",
    ]
    result["temporaryPathPolicy"] = (
        "fresh-private-paths-redacted-with-explicit-command-placeholders-v1"
    )
    result["environmentPolicy"] = "generate_seed_v2.prepare_clean_environment-v1"
    return result


def _copy_retained_run_evidence(
    source_dossier: Path,
    primary_dossier: Path,
    run_number: int,
) -> tuple[str, list[dict[str, str]]]:
    prefix = f"reference/reproducibility/run-{run_number}"
    destination_graph_root = primary_dossier / prefix / "symbol-graphs"
    destination_graph_root.mkdir(parents=True)
    source_graph_root = source_dossier / "reference/symbol-graphs"
    for source in sorted(source_graph_root.iterdir(), key=lambda value: value.name):
        if source.is_symlink() or not source.is_file() or not source.name.endswith(
            ".symbols.json"
        ):
            raise ScopedSeedError(
                f"unexpected retained graph while copying run {run_number}: {source.name}"
            )
        shutil.copyfile(source, destination_graph_root / source.name)

    canonical_records = _canonical_output_records(source_dossier, prefix)
    canonical_root = primary_dossier / prefix / "canonical"
    canonical_root.mkdir()
    for record in canonical_records:
        source = source_dossier / record["sourcePath"]
        destination = primary_dossier / record["retainedPath"]
        shutil.copyfile(source, destination)
        if base.sha256_file(destination) != record["sha256"]:
            raise ScopedSeedError(
                f"canonical output changed while copying run {run_number}: "
                f"{record['sourcePath']}"
            )
    return f"{prefix}/symbol-graphs", canonical_records


def _generate_one(
    args: argparse.Namespace,
    output_root: Path,
    exclusions: Sequence[str],
) -> tuple[Path, dict[str, Any]]:
    captured_scope: dict[str, Any] | None = None
    original_run_checked = base.run_checked

    def scoped_run_checked(
        argv: Sequence[str],
        *,
        env: dict[str, str],
        cwd: Path | None = None,
    ) -> str:
        nonlocal captured_scope
        output = original_run_checked(argv, env=env, cwd=cwd)
        if Path(argv[0]).name == "swift-symbolgraph-extract" and "-output-dir" in argv:
            if captured_scope is not None:
                raise ScopedSeedError("extractor ran more than once")
            values = list(argv)
            try:
                output_index = values.index("-output-dir") + 1
                module_index = values.index("-module-name") + 1
            except (ValueError, IndexError) as error:
                raise ScopedSeedError("extractor invocation shape differs") from error
            raw_root = Path(values[output_index])
            extracted_module = values[module_index]
            if extracted_module != args.module:
                raise ScopedSeedError("extractor module differs from requested module")
            captured_scope = classify_symbol_graphs(raw_root, args.module, exclusions)
            remove_classified_exclusions(raw_root, captured_scope)
        return output

    base_args = argparse.Namespace(
        module=args.module,
        slug=args.slug,
        lane=args.lane,
        risks=args.risks,
        dependencies=args.dependencies,
        output_root=str(output_root),
    )
    base.run_checked = scoped_run_checked
    try:
        dossier = base.generate(base_args)
    finally:
        base.run_checked = original_run_checked
    if captured_scope is None:
        raise ScopedSeedError("symbol graph extraction was not scope-audited")
    return dossier, captured_scope


def _run_record(
    *,
    run_number: int,
    dossier: Path,
    graph_root: Path,
    graph_root_relative: str,
    scope: dict[str, Any],
    canonical_outputs: list[dict[str, str]],
    module: str,
) -> dict[str, Any]:
    summary = compute_graph_summary(graph_root, module)
    return {
        "run": run_number,
        "graphRoot": graph_root_relative,
        "includedFiles": scope["includedFiles"],
        "excludedFiles": scope["excludedFiles"],
        "extraction": _extraction_provenance(dossier, module),
        **summary,
        "canonicalOutputs": canonical_outputs,
    }


def _validate_run_invariants(runs: Sequence[dict[str, Any]]) -> dict[str, Any]:
    if len(runs) < DEFAULT_REPRODUCIBILITY_RUN_COUNT:
        raise ScopedSeedError("at least three fresh extraction runs are required")
    stable_keys = (
        "uniqueSymbolCount",
        "symbolOccurrenceCount",
        "symbolMultisetSHA256",
    )
    first = runs[0]
    for key in stable_keys:
        if any(run[key] != first[key] for run in runs[1:]):
            raise ScopedSeedError(f"fresh extraction runs disagree on {key}")
    projected_count = first["baseRelationshipProjection"][
        "projectedRelationshipOccurrenceCount"
    ]
    projected_hash = first["baseRelationshipProjection"][
        "projectedRelationshipMultisetSHA256"
    ]
    for run in runs[1:]:
        projection = run["baseRelationshipProjection"]
        if (
            projection["projectedRelationshipOccurrenceCount"] != projected_count
            or projection["projectedRelationshipMultisetSHA256"] != projected_hash
        ):
            raise ScopedSeedError(
                "fresh extraction runs disagree after the narrow relationship projection"
            )

    first_outputs = {
        record["sourcePath"]: record["sha256"]
        for record in first["canonicalOutputs"]
    }
    for run in runs[1:]:
        outputs = {
            record["sourcePath"]: record["sha256"]
            for record in run["canonicalOutputs"]
        }
        if outputs != first_outputs:
            raise ScopedSeedError(
                "fresh extraction runs disagree on canonical generated outputs"
            )

    raw_hashes = {run["rawRelationshipMultisetSHA256"] for run in runs}
    if len(raw_hashes) < 2:
        raise ScopedSeedError(
            "fresh extractions did not exhibit the required raw relationship volatility"
        )
    return {
        "uniqueSymbolCount": first["uniqueSymbolCount"],
        "symbolOccurrenceCount": first["symbolOccurrenceCount"],
        "symbolMultisetSHA256": first["symbolMultisetSHA256"],
        "projectedRelationshipOccurrenceCount": projected_count,
        "projectedRelationshipMultisetSHA256": projected_hash,
        "canonicalOutputSHA256": first_outputs,
    }


def generate(args: argparse.Namespace) -> Path:
    script_path = Path(__file__).resolve(strict=True)
    repo_root = script_path.parents[2]
    output_root = base.safe_output_root(args.output_root, repo_root)
    destination = output_root / args.slug
    if destination.exists() or destination.is_symlink():
        raise ScopedSeedError(f"refusing to replace existing framework seed: {destination}")

    exclusions = sorted(args.exclude_cross_import_overlay_module)
    run_count = args.reproducibility_run_count
    if run_count < DEFAULT_REPRODUCIBILITY_RUN_COUNT:
        raise ScopedSeedError("--reproducibility-run-count must be at least 3")
    with tempfile.TemporaryDirectory(prefix=f"{args.slug}-scoped-seed-stage.") as temporary:
        stage_root = Path(temporary)
        generated: list[tuple[Path, dict[str, Any]]] = []
        for run_number in range(1, run_count + 1):
            run_output_root = stage_root / f"run-{run_number}-output"
            run_output_root.mkdir()
            generated.append(
                _generate_one(args, run_output_root, exclusions)
            )

        primary_dossier, primary_scope = generated[0]
        runs: list[dict[str, Any]] = []
        primary_outputs = _canonical_output_records(primary_dossier, None)
        runs.append(
            _run_record(
                run_number=1,
                dossier=primary_dossier,
                graph_root=primary_dossier / "reference/symbol-graphs",
                graph_root_relative="reference/symbol-graphs",
                scope=primary_scope,
                canonical_outputs=primary_outputs,
                module=args.module,
            )
        )
        for run_number, (run_dossier, run_scope) in enumerate(
            generated[1:], start=2
        ):
            graph_root_relative, canonical_outputs = _copy_retained_run_evidence(
                run_dossier, primary_dossier, run_number
            )
            runs.append(
                _run_record(
                    run_number=run_number,
                    dossier=run_dossier,
                    graph_root=primary_dossier / graph_root_relative,
                    graph_root_relative=graph_root_relative,
                    scope=run_scope,
                    canonical_outputs=canonical_outputs,
                    module=args.module,
                )
            )

        stable = _validate_run_invariants(runs)
        primary_scope["baseRelationshipProjection"] = runs[0][
            "baseRelationshipProjection"
        ]
        reproducibility = {
            "schema": REPRODUCIBILITY_SCHEMA,
            "policy": REPRODUCIBILITY_POLICY,
            "requestedModule": args.module,
            "runCount": len(runs),
            "minimumRequiredDistinctRawRelationshipHashes": 2,
            "observedDistinctRawRelationshipHashCount": len(
                {run["rawRelationshipMultisetSHA256"] for run in runs}
            ),
            "canonicalOutputPaths": list(CANONICAL_OUTPUT_PATHS),
            "stable": stable,
            "runs": runs,
        }
        base.write_json(primary_dossier / REPRODUCIBILITY_PATH, reproducibility)
        _reseal_dossier(primary_dossier, repo_root, primary_scope, exclusions)
        base.publish_directory_exclusive(primary_dossier, destination)
    return destination


def argument_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(
        description=(
            "Generate a schema-v2 base-framework seed while excluding only "
            "explicitly approved cross-import overlay modules"
        )
    )
    parser.add_argument("--module", required=True)
    parser.add_argument("--slug", required=True)
    parser.add_argument("--lane", required=True, choices=base.LANES)
    parser.add_argument("--risks", required=True)
    parser.add_argument("--dependencies", default="")
    parser.add_argument("--output-root", required=True)
    parser.add_argument(
        "--exclude-cross-import-overlay-module",
        action="append",
        required=True,
        help="exact separately compiled cross-import overlay module to exclude",
    )
    parser.add_argument(
        "--reproducibility-run-count",
        type=int,
        default=DEFAULT_REPRODUCIBILITY_RUN_COUNT,
        help="number of fresh evidence runs to retain (minimum: 3)",
    )
    return parser


def main(argv: Sequence[str] | None = None) -> int:
    args = argument_parser().parse_args(argv)
    try:
        destination = generate(args)
    except (base.SeedError, ScopedSeedError, OSError) as error:
        print(f"framework_scoped_seed: REFUSING -- {error}", file=sys.stderr)
        return 2
    print(f"FRAMEWORK_FANOUT_SCOPED_SEED_OK path={destination}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
