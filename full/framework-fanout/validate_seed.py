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
import sys
from pathlib import Path, PurePosixPath
from typing import Any, Iterable, Sequence


SCHEMA = 1
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
SDK_INPUT_CATEGORIES = {"header", "modulemap", "swiftinterface", "tbd"}
CANONICAL_SURFACE_POLICY = (
    "primary-module-graph_then-module-owned_then-utf8-path_then-"
    "canonical-payload_then-index-v1"
)
SHA256_RE = re.compile(r"[0-9a-f]{64}\Z")
SLUG_RE = re.compile(r"[a-z0-9][a-z0-9-]*\Z")
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


def normalized_runtime_marker(module: str) -> str:
    normalized = re.sub(r"[^A-Za-z0-9]+", "_", module).strip("_").upper()
    return f"{normalized}_AGENT_RUNTIME_OK"


def tsv_escape(value: str) -> str:
    return (
        value.replace("\\", "\\\\")
        .replace("\t", "\\t")
        .replace("\n", "\\n")
        .replace("\r", "\\r")
    )


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
        self._validate_framework_metadata(metadata)
        graph_files = self._validate_symbol_graphs(metadata)
        self._validate_public_surface(metadata)
        self._validate_tbd_exports(metadata)
        self._validate_sdk_inputs(metadata)
        self._validate_corpus(metadata)

        seed_expected = {
            "reference/symbol-graphs.json",
            "reference/public-surface.tsv",
            "reference/tbd-exports.tsv",
            "reference/sdk-inputs.tsv",
            "reference/corpus-summary.json",
            *graph_files,
        }
        self._validate_digest("reference/seed-files.sha256", seed_expected)

        assert self.framework is not None
        reference_files = {
            path.relative_to(self.framework).as_posix()
            for path in (self.framework / "reference").rglob("*")
            if path.is_file() and path.name != "immutable-files.sha256"
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
        if set(metadata) != expected_keys:
            self.error(
                "reference/framework.json keys differ from schema v1: "
                f"missing={sorted(expected_keys - set(metadata))}, "
                f"extra={sorted(set(metadata) - expected_keys)}"
            )
        if metadata.get("schema") != SCHEMA:
            self.error(f"framework schema must be {SCHEMA}")
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
            "sdkPath",
            "rawSDKInputCount",
            "tbdInputCount",
            "arm64TBDExportCount",
            "roadmapPath",
            "roadmapSHA256",
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
        for key in (
            "xcodeVersion",
            "xcodeBuild",
            "sdkName",
            "sdkVersion",
            "target",
            "frameworkSDKRelativePath",
            "sdkPath",
        ):
            if not isinstance(provenance.get(key), str) or not provenance[key].strip():
                self.error(f"provenance.{key} must be a nonempty string")
        for key in ("rawSDKInputCount", "tbdInputCount", "arm64TBDExportCount"):
            value = provenance.get(key)
            if not is_int(value) or value < 0:
                self.error(f"provenance.{key} must be a nonnegative integer")
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

    def _validate_symbol_graphs(self, metadata: dict[str, Any]) -> set[str]:
        manifest = self._read_json("reference/symbol-graphs.json")
        if not isinstance(manifest, dict):
            self.fatal("reference/symbol-graphs.json must contain an object")
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
        if set(manifest) != expected_keys:
            self.error("symbol graph manifest keys differ from schema v1")
        if manifest.get("schema") != SCHEMA:
            self.error(f"symbol graph manifest schema must be {SCHEMA}")
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
        if manifest.get("canonicalSurfacePolicy") != CANONICAL_SURFACE_POLICY:
            self.error(
                "symbol graph canonicalSurfacePolicy does not match schema v1"
            )
        files = manifest.get("files")
        if not isinstance(files, list) or not files:
            self.fatal("symbol graph manifest files must be a nonempty list")

        graph_paths: set[str] = set()
        occurrences: dict[
            str, list[tuple[tuple[int, bytes, bytes, int], bytes, list[str]]]
        ] = {}
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
            if not isinstance(digest, str) or not SHA256_RE.fullmatch(digest):
                self.error(f"{label}.sha256 is invalid")
            graph_path = self._framework_file(relative)
            if isinstance(digest, str) and self._sha256(graph_path) != digest:
                self.error(f"raw symbol graph digest mismatch: {relative}")
            graph = self._read_json(relative)
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
                kind_object = symbol.get("kind") if isinstance(symbol, dict) else None
                kind = (
                    kind_object.get("identifier", "")
                    if isinstance(kind_object, dict)
                    else ""
                )
                if not isinstance(kind, str) or any(
                    character in kind for character in "\x00\r\n\t"
                ):
                    self.error(f"{relative}: unsafe symbol kind for {precise!r}")
                    kind = ""
                names = symbol.get("names") if isinstance(symbol, dict) else None
                title = names.get("title", "") if isinstance(names, dict) else ""
                if not isinstance(title, str):
                    title = ""
                path_components = (
                    symbol.get("pathComponents") if isinstance(symbol, dict) else None
                )
                if not isinstance(path_components, list) or not all(
                    isinstance(component, str) for component in path_components
                ):
                    path_components = []
                fragments = (
                    symbol.get("declarationFragments")
                    if isinstance(symbol, dict)
                    else None
                )
                spellings: list[str] = []
                if isinstance(fragments, list):
                    for fragment in fragments:
                        if isinstance(fragment, dict) and isinstance(
                            fragment.get("spelling"), str
                        ):
                            spellings.append(fragment["spelling"])
                expected_surface = [
                    precise,
                    kind,
                    tsv_escape(title),
                    tsv_escape(".".join(path_components)),
                    tsv_escape("".join(spellings)),
                ]
                canonical_payload = json.dumps(
                    symbol,
                    ensure_ascii=False,
                    sort_keys=True,
                    separators=(",", ":"),
                ).encode("utf-8")
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
                    symbol_index,
                )
                occurrences.setdefault(precise, []).append(
                    (canonical_key, canonical_payload, expected_surface)
                )
            if entry.get("symbolCount") != len(symbols):
                self.error(f"symbolCount mismatch for {relative}")
            if entry.get("relationshipCount") != len(relationships):
                self.error(f"relationshipCount mismatch for {relative}")
            total_relationships += len(relationships)

        surface_by_precise: dict[str, list[str]] = {}
        conflicting_identifiers = 0
        for precise, values in occurrences.items():
            canonical = min(values, key=lambda value: value[0])
            surface_by_precise[precise] = canonical[2]
            if len({value[1] for value in values}) > 1:
                conflicting_identifiers += 1
        duplicate_occurrences = raw_symbol_count - len(occurrences)

        self.surface_by_precise = surface_by_precise
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
        return graph_paths

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
        if len(matching_modules) != 1:
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
        required = {
            "implementation": f"{module}.swift",
            "manifest": f"{slug}_guest_sources.txt",
            "readme": "README.md",
            "coverage": "coverage.tsv",
            "oracle": "oracle-questions.tsv",
            "runtime": f"tests/agent/{module}Runtime.swift",
        }
        paths = {name: self._framework_file(path) for name, path in required.items()}
        for name in ("implementation", "readme", "runtime"):
            if paths[name].stat().st_size == 0:
                self.error(f"deliverable file must not be empty: {required[name]}")

        self._validate_guest_manifest(paths["manifest"], required["implementation"])
        self._validate_coverage(paths["coverage"])
        self._validate_oracle_questions(paths["oracle"])

        try:
            runtime_source = paths["runtime"].read_text(encoding="utf-8")
        except (OSError, UnicodeError) as exc:
            self.error(f"cannot read runtime probe {required['runtime']}: {exc}")
        else:
            marker = self.metadata.get("runtimeMarker")
            if not isinstance(marker, str) or marker not in runtime_source:
                self.error(
                    f"runtime probe must contain exact success marker {marker!r}"
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
