#!/usr/bin/env python3
"""Fail-closed build-plan extraction for the pinned focus-ios Xcode target.

This is deliberately not an xcodebuild replacement.  It parses the shared
scheme and OpenStep project file, resolves the selected PBX target graph, and
emits one canonical JSON description that downstream Linux build stages can
consume.  The accepted subject and graph are pinned below; drift is an error,
not an invitation to silently reinterpret a changed Xcode project.
"""

from __future__ import annotations

import argparse
import hashlib
import json
import os
import posixpath
import re
import stat
import subprocess
import sys
import xml.etree.ElementTree as ET
from dataclasses import dataclass
from pathlib import Path
from typing import Any, Iterable, Mapping, Sequence


class PlanError(RuntimeError):
    """A malformed, unresolved, or unpinned project boundary."""


@dataclass(frozen=True)
class InputPin:
    name: str
    relative_path: str
    sha256: str


@dataclass(frozen=True)
class PhaseSpec:
    isa: str
    name: str


@dataclass(frozen=True)
class GitTreeEntry:
    mode: str
    kind: str
    object_id: str


@dataclass(frozen=True)
class GraphSpec:
    scheme_name: str
    run_configuration: str
    target_id: str
    target_name: str
    product_type: str
    phases: tuple[PhaseSpec, ...]
    target_dependencies: tuple[str, ...]
    package_products: tuple[str, ...]
    source_count: int
    swift_source_count: int
    non_swift_sources: tuple[str, ...]
    framework_count: int
    resource_count: int
    embedded_extension_count: int
    allowed_shell_variables: frozenset[str]


FOCUS_COMMIT = "a2832521c1daa0c23419c73705ae043ed60c9791"
FOCUS_GIT_PREFIX = "focus-ios/"

FOCUS_INPUTS = (
    InputPin(
        "project",
        "Blockzilla.xcodeproj/project.pbxproj",
        "5a9c088023d20de3e41e6283ab4bde12338ae54da3f2a57b1e6743434b74e4ac",
    ),
    InputPin(
        "scheme",
        "Blockzilla.xcodeproj/xcshareddata/xcschemes/Focus.xcscheme",
        "595241ed130e7187908a261998ef28da19bcb91eaedbac43ffbcc5fd29ddbaff",
    ),
    InputPin(
        "local_package_manifest",
        "BlockzillaPackage/Package.swift",
        "2d29b769de137389f5613de6755211b255533375bf6003a2192f514e96899248",
    ),
    InputPin(
        "package_resolution",
        "Blockzilla.xcodeproj/project.xcworkspace/xcshareddata/swiftpm/Package.resolved",
        "632a0df0276ba7828f456ae3964f158fb7115d05f175ddf637abdd7ab4a4633b",
    ),
)

FOCUS_GRAPH = GraphSpec(
    scheme_name="Focus",
    run_configuration="FocusDebug",
    target_id="E4BF2DD21BACE8CA00DA9D68",
    target_name="Blockzilla",
    product_type="com.apple.product-type.application",
    phases=(
        PhaseSpec("PBXShellScriptBuildPhase", "Run Script (Copy Wordmark)"),
        PhaseSpec("PBXShellScriptBuildPhase", "Run Swiftlint"),
        PhaseSpec("PBXShellScriptBuildPhase", "Glean"),
        PhaseSpec("PBXShellScriptBuildPhase", "Nimbus Feature Manifest Generator Script"),
        PhaseSpec("PBXSourcesBuildPhase", "Sources"),
        PhaseSpec("PBXFrameworksBuildPhase", "Frameworks"),
        PhaseSpec("PBXResourcesBuildPhase", "Resources"),
        PhaseSpec("PBXCopyFilesBuildPhase", "Embed App Extensions"),
    ),
    target_dependencies=(
        "ContentBlocker",
        "ShareExtension",
        "FocusIntentExtension",
        "WidgetsExtension",
    ),
    package_products=(
        "SnapKit",
        "Fuzi",
        "Sentry",
        "Glean",
        "UIHelpers",
        "DesignSystem",
        "Onboarding",
        "FocusAppServices",
        "AppShortcuts",
        "Licenses",
    ),
    source_count=132,
    swift_source_count=131,
    non_swift_sources=("Intents.intentdefinition",),
    framework_count=10,
    resource_count=26,
    embedded_extension_count=4,
    allowed_shell_variables=frozenset(
        {"ACTION", "PWD", "PRODUCT_NAME", "SOURCE_ROOT", "SRCROOT"}
    ),
)


def sha256_bytes(data: bytes) -> str:
    return hashlib.sha256(data).hexdigest()


def sha256_file(path: Path) -> str:
    try:
        return sha256_bytes(path.read_bytes())
    except OSError as exc:
        raise PlanError(f"cannot read pinned input {path}: {exc}") from exc


def git_blob_object_id(data: bytes, object_format: str) -> str:
    if object_format not in {"sha1", "sha256"}:
        raise PlanError(f"unsupported Git object format {object_format!r}")
    digest = hashlib.new(object_format)
    digest.update(f"blob {len(data)}\0".encode("ascii"))
    digest.update(data)
    return digest.hexdigest()


class OpenStepParser:
    """Small strict parser for the ASCII OpenStep plist grammar Xcode writes."""

    _punctuation = frozenset("{}()=;,")

    def __init__(self, text: str, source: str = "<pbxproj>") -> None:
        self.text = text
        self.source = source
        self.index = 0
        self.length = len(text)
        self._lookahead: str | None = None

    def parse(self) -> Any:
        value = self._parse_value()
        token = self._next()
        if token is not None:
            self._fail(f"unexpected trailing token {token!r}")
        return value

    def _line_col(self) -> tuple[int, int]:
        line = self.text.count("\n", 0, self.index) + 1
        last_newline = self.text.rfind("\n", 0, self.index)
        return line, self.index - last_newline

    def _fail(self, message: str) -> None:
        line, column = self._line_col()
        raise PlanError(f"{self.source}:{line}:{column}: {message}")

    def _skip_layout(self) -> None:
        while self.index < self.length:
            if self.text[self.index].isspace():
                self.index += 1
                continue
            if self.text.startswith("//", self.index):
                newline = self.text.find("\n", self.index + 2)
                self.index = self.length if newline < 0 else newline + 1
                continue
            if self.text.startswith("/*", self.index):
                end = self.text.find("*/", self.index + 2)
                if end < 0:
                    self._fail("unterminated block comment")
                self.index = end + 2
                continue
            break

    def _read_quoted(self) -> str:
        self.index += 1  # opening quote
        result: list[str] = []
        escapes = {"n": "\n", "r": "\r", "t": "\t", "b": "\b", "f": "\f"}
        while self.index < self.length:
            char = self.text[self.index]
            self.index += 1
            if char == '"':
                return "".join(result)
            if char != "\\":
                result.append(char)
                continue
            if self.index >= self.length:
                self._fail("unterminated quoted-string escape")
            escaped = self.text[self.index]
            self.index += 1
            if escaped == "\n":
                continue
            if escaped in escapes:
                result.append(escapes[escaped])
            elif escaped in {'"', "\\"}:
                result.append(escaped)
            elif escaped in "01234567":
                digits = escaped
                while self.index < self.length and len(digits) < 3:
                    candidate = self.text[self.index]
                    if candidate not in "01234567":
                        break
                    digits += candidate
                    self.index += 1
                result.append(chr(int(digits, 8)))
            elif escaped == "U":
                digits = self.text[self.index : self.index + 4]
                if len(digits) != 4 or not re.fullmatch(r"[0-9A-Fa-f]{4}", digits):
                    self._fail("invalid OpenStep Unicode escape")
                self.index += 4
                result.append(chr(int(digits, 16)))
            else:
                # OpenStep accepts C-style escaping of punctuation such as \$.
                result.append(escaped)
        self._fail("unterminated quoted string")
        raise AssertionError("unreachable")

    def _read_token(self) -> str | None:
        self._skip_layout()
        if self.index >= self.length:
            return None
        char = self.text[self.index]
        if char in self._punctuation:
            self.index += 1
            return char
        if char == '"':
            return self._read_quoted()
        start = self.index
        while self.index < self.length:
            char = self.text[self.index]
            if char.isspace() or char in self._punctuation:
                break
            if self.text.startswith("//", self.index) or self.text.startswith("/*", self.index):
                break
            self.index += 1
        if self.index == start:
            self._fail(f"cannot tokenize character {self.text[self.index]!r}")
        return self.text[start : self.index]

    def _peek(self) -> str | None:
        if self._lookahead is None:
            self._lookahead = self._read_token()
        return self._lookahead

    def _next(self) -> str | None:
        token = self._peek()
        self._lookahead = None
        return token

    def _expect(self, expected: str) -> None:
        actual = self._next()
        if actual != expected:
            self._fail(f"expected {expected!r}, got {actual!r}")

    def _parse_value(self) -> Any:
        token = self._next()
        if token is None:
            self._fail("expected a value, got end of file")
        if token == "{":
            return self._parse_dictionary()
        if token == "(":
            return self._parse_array()
        if token in self._punctuation:
            self._fail(f"unexpected punctuation {token!r}")
        return token

    def _parse_dictionary(self) -> dict[str, Any]:
        result: dict[str, Any] = {}
        while self._peek() != "}":
            key = self._next()
            if key is None or key in self._punctuation:
                self._fail(f"expected dictionary key, got {key!r}")
            if key in result:
                self._fail(f"duplicate dictionary key {key!r}")
            self._expect("=")
            result[key] = self._parse_value()
            self._expect(";")
        self._expect("}")
        return result

    def _parse_array(self) -> list[Any]:
        result: list[Any] = []
        while self._peek() != ")":
            result.append(self._parse_value())
            if self._peek() == ",":
                self._expect(",")
            elif self._peek() != ")":
                self._fail(f"expected ',' or ')', got {self._peek()!r}")
        self._expect(")")
        return result


def parse_openstep(text: str, source: str = "<pbxproj>") -> Any:
    return OpenStepParser(text, source).parse()


def require_dict(value: Any, context: str) -> dict[str, Any]:
    if not isinstance(value, dict):
        raise PlanError(f"{context} must be a dictionary, got {type(value).__name__}")
    return value


def require_list(value: Any, context: str) -> list[Any]:
    if not isinstance(value, list):
        raise PlanError(f"{context} must be an array, got {type(value).__name__}")
    return value


def require_string(value: Any, context: str) -> str:
    if not isinstance(value, str):
        raise PlanError(f"{context} must be a string, got {type(value).__name__}")
    return value


def require_keys(mapping: Mapping[str, Any], keys: Iterable[str], context: str) -> None:
    missing = [key for key in keys if key not in mapping]
    if missing:
        raise PlanError(f"{context} is missing required key(s): {', '.join(missing)}")


def parse_scheme(path: Path, spec: GraphSpec) -> dict[str, str]:
    try:
        raw = path.read_bytes()
    except OSError as exc:
        raise PlanError(f"cannot read scheme {path}: {exc}") from exc
    if b"<!DOCTYPE" in raw.upper():
        raise PlanError(f"scheme {path} contains a forbidden DOCTYPE")
    try:
        root = ET.fromstring(raw)
    except ET.ParseError as exc:
        raise PlanError(f"cannot parse scheme {path}: {exc}") from exc
    if root.tag != "Scheme":
        raise PlanError(f"scheme root must be Scheme, got {root.tag!r}")

    launches = root.findall("./LaunchAction")
    if len(launches) != 1:
        raise PlanError(f"scheme must have exactly one LaunchAction, got {len(launches)}")
    launch = launches[0]
    configuration = launch.get("buildConfiguration")
    if configuration != spec.run_configuration:
        raise PlanError(
            f"run configuration drift: expected {spec.run_configuration!r}, got {configuration!r}"
        )
    references = launch.findall("./BuildableProductRunnable/BuildableReference")
    if len(references) != 1:
        raise PlanError(
            "LaunchAction must contain exactly one BuildableProductRunnable/BuildableReference"
        )
    reference = references[0]
    expected_attributes = {
        "BuildableIdentifier": "primary",
        "BlueprintIdentifier": spec.target_id,
        "BlueprintName": spec.target_name,
        "ReferencedContainer": "container:Blockzilla.xcodeproj",
    }
    for key, expected in expected_attributes.items():
        actual = reference.get(key)
        if actual != expected:
            raise PlanError(
                f"scheme launch {key} drift: expected {expected!r}, got {actual!r}"
            )

    running_entries: list[ET.Element] = []
    for entry in root.findall("./BuildAction/BuildActionEntries/BuildActionEntry"):
        child = entry.find("./BuildableReference")
        if child is not None and child.get("BlueprintIdentifier") == spec.target_id:
            if entry.get("buildForRunning") == "YES":
                running_entries.append(entry)
    if len(running_entries) != 1:
        raise PlanError(
            f"scheme must build target {spec.target_name!r} for running exactly once; "
            f"found {len(running_entries)} entries"
        )
    buildable_name = reference.get("BuildableName")
    if not buildable_name or "$" in buildable_name:
        raise PlanError(f"scheme has unresolved BuildableName {buildable_name!r}")
    return {
        "name": spec.scheme_name,
        "run_configuration": configuration,
        "target_id": spec.target_id,
        "target_name": spec.target_name,
        "buildable_name": buildable_name,
        "referenced_container": expected_attributes["ReferencedContainer"],
    }


_PBX_VARIABLE = re.compile(r"\$\(([^)]+)\)|\$\{([^}]+)\}")
_SHELL_VARIABLE = re.compile(r"(?<!\\)\$(?:\{([A-Za-z_][A-Za-z0-9_]*)\}|([A-Za-z_][A-Za-z0-9_]*))")


class ProjectPlanner:
    PHASE_KIND = {
        "PBXShellScriptBuildPhase": "shell_script",
        "PBXSourcesBuildPhase": "sources",
        "PBXFrameworksBuildPhase": "frameworks",
        "PBXResourcesBuildPhase": "resources",
        "PBXCopyFilesBuildPhase": "copy_files",
    }

    def __init__(
        self,
        root: Mapping[str, Any],
        repo: Path,
        spec: GraphSpec,
        *,
        git_tree: Mapping[str, GitTreeEntry] | None = None,
        git_object_format: str = "sha1",
    ) -> None:
        self.root = dict(root)
        self.repo = repo
        self.spec = spec
        self.git_tree = dict(git_tree) if git_tree is not None else None
        self.git_object_format = git_object_format
        tracked_directories: set[str] = set()
        for path in self.git_tree or ():
            parent = posixpath.dirname(path)
            while parent:
                tracked_directories.add(parent)
                parent = posixpath.dirname(parent)
        self.tracked_directories = frozenset(tracked_directories)
        self.objects = require_dict(self.root.get("objects"), "project.objects")
        self.project_id = require_string(self.root.get("rootObject"), "project.rootObject")
        self.project = self.object(self.project_id, "PBXProject")
        self.main_group_id = require_string(self.project.get("mainGroup"), "PBXProject.mainGroup")
        project_targets = require_list(self.project.get("targets"), "PBXProject.targets")
        if project_targets.count(self.spec.target_id) != 1:
            raise PlanError(
                f"PBXProject.targets must contain selected target {self.spec.target_id} exactly once"
            )
        self.parents: dict[str, str] = {}
        self._group_cache: dict[str, str] = {}
        self._index_group_parents()

    def _require_pinned_file(self, candidate: Path, context: str) -> str:
        relative = candidate.relative_to(self.repo).as_posix()
        if self.git_tree is None:
            if not candidate.exists():
                raise PlanError(f"{context} does not exist: {relative}")
            return relative
        entry = self.git_tree.get(relative)
        if entry is None:
            raise PlanError(
                f"{context} contains untracked or ignored path at pinned commit: {relative}"
            )
        if entry.kind != "blob" or entry.mode not in {"100644", "100755", "120000"}:
            raise PlanError(
                f"{context} uses unsupported Git tree entry {entry.mode} {entry.kind}: {relative}"
            )
        try:
            metadata = candidate.lstat()
            if entry.mode == "120000":
                if not stat.S_ISLNK(metadata.st_mode):
                    raise PlanError(f"{context} has Git/worktree type drift: {relative}")
                payload = os.fsencode(os.readlink(candidate))
            else:
                if not stat.S_ISREG(metadata.st_mode):
                    raise PlanError(f"{context} has Git/worktree type drift: {relative}")
                expected_executable = entry.mode == "100755"
                actual_executable = bool(metadata.st_mode & stat.S_IXUSR)
                if actual_executable != expected_executable:
                    raise PlanError(f"{context} has Git/worktree mode drift: {relative}")
                payload = candidate.read_bytes()
        except PlanError:
            raise
        except OSError as exc:
            raise PlanError(f"cannot inspect {context} {candidate}: {exc}") from exc
        actual_object_id = git_blob_object_id(payload, self.git_object_format)
        if actual_object_id != entry.object_id:
            raise PlanError(f"{context} has worktree content drift from pinned Git blob: {relative}")
        return relative

    def _require_pinned_input(self, path: str, context: str) -> None:
        full_path = self.repo / path
        if not full_path.exists():
            raise PlanError(f"{context} does not exist: {path}")
        if self.git_tree is None or full_path.is_symlink() or not full_path.is_dir():
            self._require_pinned_file(full_path, context)
            return
        if path not in self.tracked_directories:
            raise PlanError(f"{context} is not tracked at pinned commit: {path}")

        seen_files: set[str] = set()

        def visit(directory: Path) -> None:
            try:
                entries = list(os.scandir(directory))
            except OSError as exc:
                raise PlanError(f"cannot inspect {context} directory {directory}: {exc}") from exc
            for entry in entries:
                candidate = Path(entry.path)
                relative = candidate.relative_to(self.repo).as_posix()
                if entry.is_symlink() or not entry.is_dir(follow_symlinks=False):
                    seen_files.add(self._require_pinned_file(candidate, context))
                elif relative not in self.tracked_directories:
                    raise PlanError(
                        f"{context} contains untracked or ignored directory at pinned commit: "
                        f"{relative}"
                    )
                else:
                    visit(candidate)

        visit(full_path)
        prefix = f"{path}/"
        expected_files = {tracked for tracked in self.git_tree if tracked.startswith(prefix)}
        missing = sorted(expected_files - seen_files)
        if missing:
            raise PlanError(
                f"{context} is missing pinned Git tree path(s): {', '.join(missing[:3])}"
            )

    def object(self, object_id: str, expected_isa: str | Sequence[str] | None = None) -> dict[str, Any]:
        if object_id not in self.objects:
            raise PlanError(f"unresolved PBX object reference {object_id}")
        obj = require_dict(self.objects[object_id], f"PBX object {object_id}")
        isa = require_string(obj.get("isa"), f"PBX object {object_id}.isa")
        if expected_isa is not None:
            choices = (expected_isa,) if isinstance(expected_isa, str) else tuple(expected_isa)
            if isa not in choices:
                raise PlanError(
                    f"PBX object {object_id} has isa {isa!r}; expected {' or '.join(choices)}"
                )
        return obj

    def _index_group_parents(self) -> None:
        for parent_id, raw in self.objects.items():
            if not isinstance(raw, dict) or raw.get("isa") not in {"PBXGroup", "PBXVariantGroup"}:
                continue
            for child in require_list(raw.get("children", []), f"{parent_id}.children"):
                child_id = require_string(child, f"child of {parent_id}")
                previous = self.parents.get(child_id)
                if previous is not None and previous != parent_id:
                    raise PlanError(
                        f"PBX object {child_id} has multiple parents: {previous} and {parent_id}"
                    )
                self.parents[child_id] = parent_id

    @staticmethod
    def _join(base: str, component: str, context: str) -> str:
        if not component:
            return base
        if component.startswith("/"):
            raise PlanError(f"{context} uses an absolute path {component!r}")
        normalized = posixpath.normpath(posixpath.join(base, component))
        if normalized == ".":
            return ""
        if normalized == ".." or normalized.startswith("../"):
            raise PlanError(f"{context} escapes the repository: {normalized!r}")
        return normalized

    def _expand_path(self, value: str, context: str) -> str:
        if value.startswith("/"):
            raise PlanError(f"{context} uses an absolute path {value!r}")
        known = {
            "SRCROOT": "",
            "SOURCE_ROOT": "",
            "PROJECT_DIR": "",
            "PROJECT": "Blockzilla",
        }

        def replace(match: re.Match[str]) -> str:
            name = match.group(1) or match.group(2)
            if name not in known:
                raise PlanError(f"{context} contains unresolved build variable {name!r}")
            return known[name]

        expanded = _PBX_VARIABLE.sub(replace, value)
        if "$" in expanded:
            raise PlanError(f"{context} contains unresolved variable syntax: {expanded!r}")
        return self._join("", expanded.lstrip("/"), context)

    def _group_directory(self, group_id: str, active: frozenset[str] = frozenset()) -> str:
        if group_id in self._group_cache:
            return self._group_cache[group_id]
        if group_id in active:
            raise PlanError(f"cycle in PBX group graph at {group_id}")
        group = self.object(group_id, "PBXGroup")
        if group_id == self.main_group_id:
            parent_path = ""
        else:
            parent_id = self.parents.get(group_id)
            if parent_id is None:
                raise PlanError(f"PBX group {group_id} is detached from mainGroup")
            parent = self.object(parent_id)
            if parent["isa"] != "PBXGroup":
                raise PlanError(f"PBX group {group_id} is nested under non-directory {parent_id}")
            parent_path = self._group_directory(parent_id, active | {group_id})
        source_tree = group.get("sourceTree", "<group>")
        raw_component = group.get("path", "")
        component = (
            self._expand_path(
                require_string(raw_component, f"PBX group {group_id}.path"),
                f"PBX group {group_id}.path",
            )
            if raw_component
            else ""
        )
        if source_tree == "<group>":
            result = self._join(parent_path, component, f"PBX group {group_id}")
        elif source_tree in {"SOURCE_ROOT", "PROJECT_DIR"}:
            result = self._join("", component, f"PBX group {group_id}")
        else:
            raise PlanError(
                f"PBX group {group_id} has unresolved sourceTree {source_tree!r}"
            )
        self._group_cache[group_id] = result
        return result

    def _containing_directory(self, ref_id: str) -> str:
        parent_id = self.parents.get(ref_id)
        if parent_id is None:
            raise PlanError(f"file reference {ref_id} is detached from mainGroup")
        parent = self.object(parent_id)
        if parent["isa"] == "PBXVariantGroup":
            parent_id = self.parents.get(parent_id, "")
            if not parent_id:
                raise PlanError(f"variant group containing {ref_id} is detached")
        return self._group_directory(parent_id)

    def resolve_file(self, ref_id: str) -> dict[str, Any]:
        obj = self.object(ref_id, ("PBXFileReference", "PBXVariantGroup"))
        isa = obj["isa"]
        component = obj.get("path") or obj.get("name")
        if not component:
            raise PlanError(f"file reference {ref_id} has neither path nor name")
        source_tree = obj.get("sourceTree", "<group>")
        if source_tree == "<group>":
            repo_path = self._join(
                self._containing_directory(ref_id),
                self._expand_path(component, f"file reference {ref_id}"),
                f"file reference {ref_id}",
            )
            external_tree = None
        elif source_tree in {"SOURCE_ROOT", "PROJECT_DIR"}:
            repo_path = self._expand_path(component, f"file reference {ref_id}")
            external_tree = None
        elif source_tree in {"BUILT_PRODUCTS_DIR", "SDKROOT"}:
            repo_path = None
            external_tree = source_tree
        else:
            raise PlanError(f"file reference {ref_id} has unresolved sourceTree {source_tree!r}")
        result: dict[str, Any] = {
            "file_ref_id": ref_id,
            "name": obj.get("name") or posixpath.basename(component),
            "source_tree": source_tree,
        }
        if repo_path is not None:
            result["path"] = repo_path
        else:
            result["path"] = component
            result["external_tree"] = external_tree
        file_type = obj.get("lastKnownFileType") or obj.get("explicitFileType")
        if file_type:
            result["file_type"] = file_type
        if isa == "PBXVariantGroup":
            variants = []
            for child_id in require_list(obj.get("children"), f"variant group {ref_id}.children"):
                variant = self.resolve_file(require_string(child_id, f"variant child of {ref_id}"))
                if "path" not in variant or variant.get("external_tree"):
                    raise PlanError(f"variant {child_id} does not resolve inside the repository")
                variants.append(variant["path"])
            if not variants:
                raise PlanError(f"variant group {ref_id} is empty")
            result["variant_paths"] = variants
        return result

    def _build_file(self, build_file_id: str) -> tuple[dict[str, Any], dict[str, Any]]:
        build_file = self.object(build_file_id, "PBXBuildFile")
        refs = [key for key in ("fileRef", "productRef") if key in build_file]
        if len(refs) != 1:
            raise PlanError(
                f"PBXBuildFile {build_file_id} must have exactly one fileRef/productRef, got {refs}"
            )
        return build_file, {"kind": refs[0], "id": require_string(build_file[refs[0]], refs[0])}

    def _configuration(self, target: Mapping[str, Any], name: str) -> str:
        list_id = require_string(target.get("buildConfigurationList"), "target.buildConfigurationList")
        config_list = self.object(list_id, "XCConfigurationList")
        matches = []
        for config_id in require_list(config_list.get("buildConfigurations"), "buildConfigurations"):
            config_id = require_string(config_id, "build configuration reference")
            config = self.object(config_id, "XCBuildConfiguration")
            if config.get("name") == name:
                matches.append(config_id)
        if len(matches) != 1:
            raise PlanError(
                f"target must contain configuration {name!r} exactly once, found {len(matches)}"
            )
        return matches[0]

    def _shell_phase(self, phase_id: str, phase: Mapping[str, Any]) -> dict[str, Any]:
        if require_list(phase.get("files", []), f"shell phase {phase_id}.files"):
            raise PlanError(f"shell phase {phase_id} contains unsupported PBXBuildFile inputs")
        shell_path = require_string(phase.get("shellPath"), f"shell phase {phase_id}.shellPath")
        if shell_path != "/bin/sh":
            raise PlanError(f"shell phase {phase_id} uses unknown shell {shell_path!r}")
        script = require_string(phase.get("shellScript"), f"shell phase {phase_id}.shellScript")
        variables = sorted(
            {match.group(1) or match.group(2) for match in _SHELL_VARIABLE.finditer(script)}
        )
        unknown = sorted(set(variables) - self.spec.allowed_shell_variables)
        if unknown:
            raise PlanError(
                f"shell phase {phase_id} contains unresolved variable(s): {', '.join(unknown)}"
            )
        residual_dollars = _SHELL_VARIABLE.sub("", script)
        if "$" in residual_dollars:
            raise PlanError(
                f"shell phase {phase_id} contains unsupported variable/command syntax"
            )
        result = {
            "shell_path": shell_path,
            "script_sha256": sha256_bytes(script.encode("utf-8")),
            "script_variables": variables,
        }
        for key, output_key in (
            ("inputPaths", "input_paths"),
            ("outputPaths", "output_paths"),
            ("inputFileListPaths", "input_file_lists"),
            ("outputFileListPaths", "output_file_lists"),
        ):
            paths = require_list(phase.get(key, []), f"shell phase {phase_id}.{key}")
            result[output_key] = [
                self._expand_path(require_string(path, f"{phase_id}.{key}"), f"{phase_id}.{key}")
                for path in paths
            ]
        return result

    def _file_phase(
        self, phase_id: str, phase: Mapping[str, Any], *, require_internal: bool
    ) -> list[dict[str, Any]]:
        entries = []
        seen_build_files: set[str] = set()
        for raw_id in require_list(phase.get("files"), f"phase {phase_id}.files"):
            build_file_id = require_string(raw_id, f"phase {phase_id} build file")
            if build_file_id in seen_build_files:
                raise PlanError(f"phase {phase_id} repeats PBXBuildFile {build_file_id}")
            seen_build_files.add(build_file_id)
            build_file, reference = self._build_file(build_file_id)
            if reference["kind"] != "fileRef":
                raise PlanError(f"phase {phase_id} unexpectedly contains a package product")
            resolved = self.resolve_file(reference["id"])
            if require_internal and resolved.get("external_tree"):
                raise PlanError(
                    f"phase {phase_id} file {reference['id']} resolves outside the repository"
                )
            entry = {"build_file_id": build_file_id, **resolved}
            if "settings" in build_file:
                entry["settings"] = build_file["settings"]
            entries.append(entry)
        return entries

    def _framework_phase(self, phase_id: str, phase: Mapping[str, Any]) -> list[dict[str, str]]:
        entries = []
        for raw_id in require_list(phase.get("files"), f"phase {phase_id}.files"):
            build_file_id = require_string(raw_id, f"phase {phase_id} build file")
            _, reference = self._build_file(build_file_id)
            if reference["kind"] != "productRef":
                raise PlanError(f"framework phase {phase_id} contains a non-package file reference")
            product = self.object(reference["id"], "XCSwiftPackageProductDependency")
            entries.append(
                {
                    "build_file_id": build_file_id,
                    "product_ref_id": reference["id"],
                    "name": require_string(product.get("productName"), "package productName"),
                }
            )
        return entries

    def _target_dependencies(self, target: Mapping[str, Any]) -> list[dict[str, str]]:
        result = []
        for raw_id in require_list(target.get("dependencies"), "target.dependencies"):
            dependency_id = require_string(raw_id, "target dependency reference")
            dependency = self.object(dependency_id, "PBXTargetDependency")
            target_id = dependency.get("target")
            if not target_id:
                raise PlanError(
                    f"target dependency {dependency_id} uses an unresolved proxy instead of target"
                )
            target_id = require_string(target_id, f"target dependency {dependency_id}.target")
            target_object = self.object(target_id, "PBXNativeTarget")
            if "targetProxy" in dependency:
                proxy_id = require_string(
                    dependency["targetProxy"], f"target dependency {dependency_id}.targetProxy"
                )
                proxy = self.object(proxy_id, "PBXContainerItemProxy")
                remote_id = require_string(
                    proxy.get("remoteGlobalIDString"), f"target proxy {proxy_id}.remoteGlobalIDString"
                )
                if remote_id != target_id:
                    raise PlanError(
                        f"target dependency {dependency_id} proxy points to {remote_id}, not {target_id}"
                    )
            result.append(
                {
                    "dependency_id": dependency_id,
                    "target_id": target_id,
                    "name": require_string(target_object.get("name"), f"target {target_id}.name"),
                }
            )
        return result

    def _package_products(self, target: Mapping[str, Any]) -> list[dict[str, Any]]:
        result = []
        for raw_id in require_list(
            target.get("packageProductDependencies"), "target.packageProductDependencies"
        ):
            product_id = require_string(raw_id, "package product reference")
            product = self.object(product_id, "XCSwiftPackageProductDependency")
            item: dict[str, Any] = {
                "product_ref_id": product_id,
                "name": require_string(product.get("productName"), f"product {product_id}.name"),
            }
            if "package" in product:
                package_id = require_string(product["package"], f"product {product_id}.package")
                package = self.object(package_id, "XCRemoteSwiftPackageReference")
                item.update(
                    {
                        "origin": "remote",
                        "package_ref_id": package_id,
                        "repository_url": require_string(
                            package.get("repositoryURL"), f"package {package_id}.repositoryURL"
                        ),
                        "requirement": require_dict(
                            package.get("requirement"), f"package {package_id}.requirement"
                        ),
                    }
                )
            else:
                item["origin"] = "local"
            result.append(item)
        return result

    def build(self, scheme: Mapping[str, str]) -> dict[str, Any]:
        target = self.object(self.spec.target_id, "PBXNativeTarget")
        target_name = require_string(target.get("name"), "selected target.name")
        if target_name != self.spec.target_name:
            raise PlanError(
                f"target name drift: expected {self.spec.target_name!r}, got {target_name!r}"
            )
        product_type = require_string(target.get("productType"), "selected target.productType")
        if product_type != self.spec.product_type:
            raise PlanError(
                f"target product type drift: expected {self.spec.product_type!r}, got {product_type!r}"
            )
        if require_list(target.get("buildRules", []), "target.buildRules"):
            raise PlanError("selected target contains unsupported custom build rules")
        configuration_id = self._configuration(target, self.spec.run_configuration)
        product_reference_id = require_string(
            target.get("productReference"), "selected target.productReference"
        )
        product_reference = self.resolve_file(product_reference_id)
        if product_reference.get("source_tree") != "BUILT_PRODUCTS_DIR":
            raise PlanError("selected target product is not in BUILT_PRODUCTS_DIR")

        phase_ids = require_list(target.get("buildPhases"), "target.buildPhases")
        if len(phase_ids) != len(self.spec.phases):
            raise PlanError(
                f"phase count drift: expected {len(self.spec.phases)}, got {len(phase_ids)}"
            )
        phases: list[dict[str, Any]] = []
        generated_outputs: set[str] = set()
        for index, (raw_id, expected) in enumerate(zip(phase_ids, self.spec.phases)):
            phase_id = require_string(raw_id, f"target.buildPhases[{index}]")
            phase = self.object(phase_id)
            isa = phase["isa"]
            if isa not in self.PHASE_KIND:
                raise PlanError(f"unknown build phase type {isa!r} at index {index}")
            name = phase.get("name") or self.PHASE_KIND[isa].capitalize()
            if isa != expected.isa or name != expected.name:
                raise PlanError(
                    f"phase {index} drift: expected {expected.isa}/{expected.name!r}, "
                    f"got {isa}/{name!r}"
                )
            item: dict[str, Any] = {
                "index": index,
                "phase_id": phase_id,
                "kind": self.PHASE_KIND[isa],
                "name": name,
            }
            if isa == "PBXShellScriptBuildPhase":
                detail = self._shell_phase(phase_id, phase)
                generated_outputs.update(detail["output_paths"])
                item.update(detail)
            elif isa == "PBXSourcesBuildPhase":
                item["files"] = self._file_phase(phase_id, phase, require_internal=True)
            elif isa == "PBXFrameworksBuildPhase":
                item["products"] = self._framework_phase(phase_id, phase)
            elif isa == "PBXResourcesBuildPhase":
                item["files"] = self._file_phase(phase_id, phase, require_internal=True)
            elif isa == "PBXCopyFilesBuildPhase":
                item["files"] = self._file_phase(phase_id, phase, require_internal=False)
                item["destination_subfolder_spec"] = int(
                    require_string(phase.get("dstSubfolderSpec"), f"copy phase {phase_id}.dstSubfolderSpec")
                )
                item["destination_path"] = require_string(
                    phase.get("dstPath", ""), f"copy phase {phase_id}.dstPath"
                )
            phases.append(item)

        all_output_paths = [
            path
            for phase in phases
            if phase["kind"] == "shell_script"
            for path in phase["output_paths"]
        ]
        if len(all_output_paths) != len(set(all_output_paths)):
            raise PlanError("multiple shell phases declare the same output path")
        for phase in phases:
            if phase["kind"] != "shell_script":
                continue
            for input_path in phase["input_paths"] + phase["input_file_lists"]:
                self._require_pinned_input(
                    input_path, f"shell phase {phase['name']!r} input"
                )

        source_phase = next(phase for phase in phases if phase["kind"] == "sources")
        resource_phase = next(phase for phase in phases if phase["kind"] == "resources")
        framework_phase = next(phase for phase in phases if phase["kind"] == "frameworks")
        copy_phase = next(phase for phase in phases if phase["kind"] == "copy_files")

        for phase in (source_phase, resource_phase):
            for entry in phase["files"]:
                path = entry["path"]
                entry["generated"] = path in generated_outputs
                if entry["generated"]:
                    continue
                if "variant_paths" in entry:
                    for variant_path in entry["variant_paths"]:
                        self._require_pinned_input(
                            variant_path, f"variant group {entry['file_ref_id']} path"
                        )
                else:
                    self._require_pinned_input(path, "resolved project path")

        sources = source_phase["files"]
        swift_sources = [entry for entry in sources if entry["path"].endswith(".swift")]
        non_swift = [posixpath.basename(entry["path"]) for entry in sources if not entry["path"].endswith(".swift")]
        if len(sources) != self.spec.source_count:
            raise PlanError(
                f"source count drift: expected {self.spec.source_count}, got {len(sources)}"
            )
        if len(swift_sources) != self.spec.swift_source_count:
            raise PlanError(
                f"Swift source count drift: expected {self.spec.swift_source_count}, "
                f"got {len(swift_sources)}"
            )
        if tuple(non_swift) != self.spec.non_swift_sources:
            raise PlanError(
                f"non-Swift source drift: expected {self.spec.non_swift_sources}, got {tuple(non_swift)}"
            )
        if len(framework_phase["products"]) != self.spec.framework_count:
            raise PlanError("framework phase count drift")
        if len(resource_phase["files"]) != self.spec.resource_count:
            raise PlanError("resource phase count drift")
        if len(copy_phase["files"]) != self.spec.embedded_extension_count:
            raise PlanError("embedded extension count drift")
        if copy_phase["destination_subfolder_spec"] != 13 or copy_phase["destination_path"]:
            raise PlanError(
                "Embed App Extensions must copy to wrapper subfolder spec 13 with an empty dstPath"
            )
        for entry in copy_phase["files"]:
            if entry.get("source_tree") != "BUILT_PRODUCTS_DIR":
                raise PlanError(
                    f"embedded extension {entry['name']!r} is not from BUILT_PRODUCTS_DIR"
                )
            settings = require_dict(entry.get("settings"), f"embedded extension {entry['name']} settings")
            attributes = require_list(settings.get("ATTRIBUTES"), "embedded extension ATTRIBUTES")
            if attributes != ["RemoveHeadersOnCopy"]:
                raise PlanError(
                    f"embedded extension {entry['name']!r} has unsupported copy attributes {attributes}"
                )

        dependencies = self._target_dependencies(target)
        dependency_names = tuple(item["name"] for item in dependencies)
        if dependency_names != self.spec.target_dependencies:
            raise PlanError(
                f"target dependency drift: expected {self.spec.target_dependencies}, got {dependency_names}"
            )
        products = self._package_products(target)
        product_names = tuple(item["name"] for item in products)
        if product_names != self.spec.package_products:
            raise PlanError(
                f"package product drift: expected {self.spec.package_products}, got {product_names}"
            )
        framework_names = {item["name"] for item in framework_phase["products"]}
        if framework_names != set(product_names):
            raise PlanError(
                "framework products do not exactly match target.packageProductDependencies"
            )
        embedded_names = tuple(item["name"] for item in copy_phase["files"])
        expected_embedded = tuple(f"{name}.appex" for name in self.spec.target_dependencies)
        # Xcode's copy order differs from dependency order; compare as a set but retain order in JSON.
        if set(embedded_names) != set(expected_embedded):
            raise PlanError(
                f"embedded extension drift: expected {expected_embedded}, got {embedded_names}"
            )

        return {
            "scheme": dict(scheme),
            "target": {
                "target_id": self.spec.target_id,
                "name": target_name,
                "product_type": product_type,
                "configuration_id": configuration_id,
                "product": product_reference,
            },
            "build_phases": phases,
            "target_dependencies": dependencies,
            "package_products": products,
            "summary": {
                "phase_count": len(phases),
                "shell_phase_count": sum(p["kind"] == "shell_script" for p in phases),
                "source_count": len(sources),
                "swift_source_count": len(swift_sources),
                "non_swift_source_count": len(non_swift),
                "framework_count": len(framework_phase["products"]),
                "resource_count": len(resource_phase["files"]),
                "embedded_extension_count": len(copy_phase["files"]),
                "target_dependency_count": len(dependencies),
                "package_product_count": len(products),
            },
        }


def parse_package_resolution(path: Path) -> list[dict[str, Any]]:
    try:
        value = json.loads(path.read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError) as exc:
        raise PlanError(f"cannot parse package resolution {path}: {exc}") from exc
    if value.get("version") == 1:
        pins = value.get("object", {}).get("pins")
    else:
        pins = value.get("pins")
    if not isinstance(pins, list):
        raise PlanError("Package.resolved has no recognized pins array")
    result = []
    for index, pin in enumerate(pins):
        pin = require_dict(pin, f"Package.resolved pin {index}")
        state = require_dict(pin.get("state"), f"Package.resolved pin {index}.state")
        identity = pin.get("identity") or pin.get("package")
        location = pin.get("location") or pin.get("repositoryURL")
        result.append(
            {
                "identity": require_string(identity, f"Package.resolved pin {index}.identity"),
                "location": require_string(location, f"Package.resolved pin {index}.location"),
                "revision": require_string(state.get("revision"), f"Package.resolved pin {index}.revision"),
                "version": state.get("version"),
                "branch": state.get("branch"),
            }
        )
    return result


def controlled_git_environment() -> dict[str, str]:
    environment = {key: value for key, value in os.environ.items() if not key.startswith("GIT_")}
    environment.update(
        {
            "GIT_CONFIG_GLOBAL": os.devnull,
            "GIT_CONFIG_NOSYSTEM": "1",
            "GIT_NO_REPLACE_OBJECTS": "1",
            "GIT_OPTIONAL_LOCKS": "0",
            "LANG": "C",
            "LC_ALL": "C",
        }
    )
    return environment


def git_command(repo: Path, *arguments: str) -> list[str]:
    return [
        "git",
        "-c",
        "core.fsmonitor=false",
        "-c",
        f"core.hooksPath={os.devnull}",
        "-C",
        os.fspath(repo),
        *arguments,
    ]


def git_output(repo: Path, *arguments: str) -> str:
    try:
        completed = subprocess.run(
            git_command(repo, *arguments),
            check=True,
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
            text=True,
            env=controlled_git_environment(),
        )
    except (OSError, subprocess.CalledProcessError) as exc:
        detail = getattr(exc, "stderr", "") or str(exc)
        raise PlanError(f"git {' '.join(arguments)} failed for {repo}: {detail.strip()}") from exc
    return completed.stdout.strip()


def git_tree_entries(repo: Path, commit: str) -> tuple[dict[str, GitTreeEntry], str]:
    object_format = git_output(repo, "rev-parse", "--show-object-format")
    worktree_prefix = git_output(repo, "rev-parse", "--show-prefix")
    if object_format not in {"sha1", "sha256"}:
        raise PlanError(f"unsupported Git object format {object_format!r}")
    try:
        completed = subprocess.run(
            git_command(repo, "ls-tree", "-r", "--full-tree", "-z", commit),
            check=True,
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
            env=controlled_git_environment(),
        )
    except (OSError, subprocess.CalledProcessError) as exc:
        detail = getattr(exc, "stderr", b"")
        if isinstance(detail, bytes):
            detail = detail.decode("utf-8", errors="replace")
        raise PlanError(f"cannot enumerate pinned Git tree for {repo}: {detail or exc}") from exc

    result: dict[str, GitTreeEntry] = {}
    for record in completed.stdout.split(b"\0"):
        if not record:
            continue
        try:
            metadata, raw_path = record.split(b"\t", 1)
            mode, kind, raw_object_id = metadata.split(b" ", 2)
            path = raw_path.decode("utf-8")
            entry = GitTreeEntry(
                mode=mode.decode("ascii"),
                kind=kind.decode("ascii"),
                object_id=raw_object_id.decode("ascii"),
            )
        except (UnicodeDecodeError, ValueError) as exc:
            raise PlanError("pinned Git tree contains an unparseable entry") from exc
        if not path or path.startswith("/") or posixpath.normpath(path) != path:
            raise PlanError(f"pinned Git tree contains unsafe path {path!r}")
        if worktree_prefix:
            if not path.startswith(worktree_prefix):
                continue
            path = path[len(worktree_prefix) :]
            if not path:
                continue
        if path in result:
            raise PlanError(f"pinned Git tree contains duplicate path {path!r}")
        result[path] = entry
    return result, object_format


def verify_pins(
    repo: Path,
    commit: str,
    pins: Sequence[InputPin],
    *,
    expected_worktree_prefix: str | None = None,
) -> dict[str, Any]:
    if not repo.is_dir():
        raise PlanError(f"focus-ios checkout is not a directory: {repo}")
    actual_top_level = Path(git_output(repo, "rev-parse", "--show-toplevel")).resolve()
    actual_prefix = git_output(repo, "rev-parse", "--show-prefix")
    resolved_from_git = (actual_top_level / actual_prefix).resolve()
    if resolved_from_git != repo.resolve():
        raise PlanError(
            f"focus-ios path does not match Git's worktree/prefix: expected {repo.resolve()}, "
            f"got {resolved_from_git}"
        )
    if expected_worktree_prefix is not None and actual_prefix != expected_worktree_prefix:
        raise PlanError(
            f"focus-ios Git worktree prefix drift: expected {expected_worktree_prefix!r}, "
            f"got {actual_prefix!r}"
        )
    actual_commit = git_output(repo, "rev-parse", "HEAD")
    if actual_commit != commit:
        raise PlanError(f"focus-ios commit drift: expected {commit}, got {actual_commit}")
    tracked_drift = git_output(repo, "status", "--porcelain", "--untracked-files=no")
    if tracked_drift:
        raise PlanError(f"focus-ios has tracked worktree drift:\n{tracked_drift}")
    inputs: dict[str, Any] = {}
    for pin in pins:
        path = repo / pin.relative_path
        actual_hash = sha256_file(path)
        if actual_hash != pin.sha256:
            raise PlanError(
                f"input hash drift for {pin.relative_path}: expected {pin.sha256}, got {actual_hash}"
            )
        inputs[pin.name] = {"path": pin.relative_path, "sha256": actual_hash}
    return {"git_commit": actual_commit, "inputs": inputs}


def build_focus_plan(repo: Path, *, verify: bool = True) -> dict[str, Any]:
    repo = repo.resolve()
    if verify:
        subject = verify_pins(
            repo,
            FOCUS_COMMIT,
            FOCUS_INPUTS,
            expected_worktree_prefix=FOCUS_GIT_PREFIX,
        )
    else:
        subject = {
            "git_commit": FOCUS_COMMIT,
            "inputs": {
                pin.name: {
                    "path": pin.relative_path,
                    "sha256": sha256_file(repo / pin.relative_path),
                }
                for pin in FOCUS_INPUTS
            },
        }
    by_name = {pin.name: pin for pin in FOCUS_INPUTS}
    project_path = repo / by_name["project"].relative_path
    scheme_path = repo / by_name["scheme"].relative_path
    try:
        project_text = project_path.read_text(encoding="utf-8")
    except OSError as exc:
        raise PlanError(f"cannot read project {project_path}: {exc}") from exc
    parsed = parse_openstep(project_text, os.fspath(project_path))
    project = require_dict(parsed, "project root")
    require_keys(project, ("archiveVersion", "objectVersion", "objects", "rootObject"), "project root")
    scheme = parse_scheme(scheme_path, FOCUS_GRAPH)
    tree_entries, object_format = git_tree_entries(repo, subject["git_commit"])
    planner = ProjectPlanner(
        project,
        repo,
        FOCUS_GRAPH,
        git_tree=tree_entries,
        git_object_format=object_format,
    )
    graph = planner.build(scheme)
    lock_path = repo / by_name["package_resolution"].relative_path
    return {
        "format_version": 1,
        "subject": {
            "repository": "mozilla-mobile/focus-ios",
            **subject,
            "project_archive_version": project["archiveVersion"],
            "project_object_version": project["objectVersion"],
        },
        **graph,
        "package_resolution": parse_package_resolution(lock_path),
    }


def canonical_json(plan: Mapping[str, Any]) -> bytes:
    return (json.dumps(plan, sort_keys=True, indent=2, ensure_ascii=False) + "\n").encode("utf-8")


def checked_focus_plan(repo: Path, canonical_path: Path) -> bytes:
    generated = canonical_json(build_focus_plan(repo))
    try:
        expected = canonical_path.read_bytes()
    except OSError as exc:
        raise PlanError(f"cannot read canonical plan {canonical_path}: {exc}") from exc
    if generated != expected:
        raise PlanError(
            f"canonical plan drift: generated bytes differ from {canonical_path}; "
            "review the parsed graph and update the attestation intentionally"
        )
    return generated


def main(argv: Sequence[str] | None = None) -> int:
    parser = argparse.ArgumentParser(
        description="Parse and attest the pinned focus-ios Focus Xcode build graph."
    )
    parser.add_argument("repo", type=Path, help="path to the pinned focus-ios checkout")
    parser.add_argument(
        "--canonical",
        type=Path,
        default=Path(__file__).with_name("focus-plan.json"),
        help="checked canonical JSON to compare (default: adjacent focus-plan.json)",
    )
    parser.add_argument("--output", type=Path, help="write attested JSON here instead of stdout")
    args = parser.parse_args(argv)
    try:
        payload = checked_focus_plan(args.repo, args.canonical)
        if args.output:
            args.output.write_bytes(payload)
        else:
            sys.stdout.buffer.write(payload)
    except (PlanError, OSError) as exc:
        print(f"xcodeplan: ERROR: {exc}", file=sys.stderr)
        return 2
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
