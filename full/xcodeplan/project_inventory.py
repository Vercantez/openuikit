#!/usr/bin/env python3
"""Canonical target inventory for ordinary Xcode projects.

This is the reusable discovery layer in front of the pinned Focus planner. It
does not generally evaluate Xcode build settings or execute build phases. It
does resolve the narrow native product-setting subset needed to establish one
safe wrapper and executable identity. It resolves a shared scheme (or an explicitly named target),
inventories classic PBX build files, and models the simple
filesystem-synchronized groups emitted by modern Xcode project templates.
"""

from __future__ import annotations

import argparse
import json
import os
import posixpath
import re
import stat
import sys
import unicodedata
import xml.etree.ElementTree as ET
import xml.parsers.expat as expat
from pathlib import Path
from typing import Any, Mapping, Sequence

import xcodeplan
import xcconfig


PlanError = xcodeplan.PlanError


SOURCE_EXTENSIONS = frozenset(
    {
        ".c",
        ".cc",
        ".cpp",
        ".cxx",
        ".intentdefinition",
        ".m",
        ".metal",
        ".mlkitmodel",
        ".mlmodel",
        ".mm",
        ".s",
        ".swift",
        ".xcdatamodel",
        ".xcdatamodeld",
        ".xcmappingmodel",
    }
)
HEADER_EXTENSIONS = frozenset({".h", ".hh", ".hpp", ".hxx", ".modulemap"})
RESOURCE_EXTENSIONS = frozenset(
    {
        ".caf",
        ".css",
        ".gif",
        ".heic",
        ".html",
        ".icns",
        ".ico",
        ".jpeg",
        ".jpg",
        ".js",
        ".json",
        ".m4a",
        ".md",
        ".mov",
        ".mp3",
        ".mp4",
        ".otf",
        ".pdf",
        ".plist",
        ".png",
        ".scn",
        ".strings",
        ".stringsdict",
        ".xcstrings",
        ".svg",
        ".txt",
        ".ttf",
        ".wav",
        ".xcprivacy",
        ".xib",
        ".xml",
        ".yaml",
        ".yml",
        ".storyboard",
    }
)
SOURCE_DIRECTORY_EXTENSIONS = frozenset(
    {
        ".mlpackage",
        ".xcdatamodel",
        ".xcdatamodeld",
        ".xcmappingmodel",
    }
)
RESOURCE_DIRECTORY_EXTENSIONS = frozenset(
    {
        ".atlas",
        ".bundle",
        ".icon",
        ".imagecatalog",
        ".rtfd",
        ".scnassets",
        ".xcassets",
        ".xcstickers",
    }
)
RECURSIVE_DIRECTORY_EXTENSIONS = frozenset({".lproj"})
IGNORED_SYNCHRONIZED_NAMES = frozenset({".DS_Store", ".git", ".svn"})

EXPLICIT_HEADER_FILE_TYPES = frozenset(
    {
        "sourcecode.c.h",
        "sourcecode.cpp.h",
        "sourcecode.module-map",
    }
)
EXPLICIT_SOURCE_FILE_TYPES = frozenset(
    {
        "file.intentdefinition",
        "file.mlmodel",
        "sourcecode.asm",
        "sourcecode.asm.asm",
        "sourcecode.asm.llvm",
        "sourcecode.c.c",
        "sourcecode.c.c.preprocessed",
        "sourcecode.c.objc",
        "sourcecode.c.objc.preprocessed",
        "sourcecode.cpp.cpp",
        "sourcecode.cpp.cpp.preprocessed",
        "sourcecode.cpp.objcpp",
        "sourcecode.cpp.objcpp.preprocessed",
        "sourcecode.glsl",
        "sourcecode.metal",
        "sourcecode.opencl",
        "sourcecode.swift",
        "wrapper.xcdatamodel",
        "wrapper.xcdatamodeld",
        "wrapper.xcmappingmodel",
    }
)
EXPLICIT_RESOURCE_FILE_TYPES = frozenset(
    {
        "audio.aiff",
        "audio.au",
        "audio.midi",
        "audio.mp3",
        "audio.wav",
        "file.storyboard",
        "file.xib",
        "image.bmp",
        "image.gif",
        "image.icns",
        "image.ico",
        "image.jpeg",
        "image.pdf",
        "image.pict",
        "image.png",
        "image.svg",
        "image.tiff",
        "sourcecode.javascript",
        "text",
        "text.css",
        "text.html",
        "text.html.other",
        "text.json",
        "text.json.xcstrings",
        "text.plist",
        "text.plist.app-privacy",
        "text.plist.strings",
        "text.plist.stringsdict",
        "text.plist.xml",
        "text.rtf",
        "text.xml",
        "text.yaml",
        "video.avi",
        "video.mpeg",
        "video.quartz-composer",
        "video.quicktime",
    }
)
EXPLICIT_SOURCE_DIRECTORY_TYPES = frozenset(
    {
        "folder.mlpackage",
        "wrapper.xcdatamodel",
        "wrapper.xcdatamodeld",
        "wrapper.xcmappingmodel",
    }
)
EXPLICIT_RESOURCE_DIRECTORY_TYPES = frozenset(
    {
        "folder.abstractassetcatalog",
        "folder.assetcatalog",
        "folder.iconcomposer.icon",
        "folder.imagecatalog",
        "folder.skatlas",
        "folder.stickers",
        "wrapper.cfbundle",
        "wrapper.plug-in",
        "wrapper.rtfd",
        "wrapper.scnassets",
    }
)
EXPLICIT_FILE_TYPES = (
    EXPLICIT_HEADER_FILE_TYPES
    | EXPLICIT_SOURCE_FILE_TYPES
    | EXPLICIT_RESOURCE_FILE_TYPES
)
EXPLICIT_DIRECTORY_TYPES = (
    EXPLICIT_SOURCE_DIRECTORY_TYPES | EXPLICIT_RESOURCE_DIRECTORY_TYPES
)
EXPLICIT_SYNCHRONIZED_TYPES = EXPLICIT_FILE_TYPES | EXPLICIT_DIRECTORY_TYPES

SUPPORTED_PRODUCT_TYPES = {
    "com.apple.product-type.application": ("wrapper.application", ".app"),
}

PHASE_KINDS = {
    "PBXCopyFilesBuildPhase": "copy_files",
    "PBXFrameworksBuildPhase": "frameworks",
    "PBXHeadersBuildPhase": "headers",
    "PBXResourcesBuildPhase": "resources",
    "PBXShellScriptBuildPhase": "shell_script",
    "PBXSourcesBuildPhase": "sources",
}

_PBX_VARIABLE = re.compile(r"\$\(([^)]+)\)|\$\{([^}]+)\}")

# These settings participate in Xcode's native application-product identity.
# Conditional variants are deliberately unsupported: without an SDK,
# destination, architecture, and full xcconfig evaluator there is no single
# value that this inventory can prove.
_PRODUCT_IDENTITY_SETTING_NAMES = frozenset(
    {
        "BUILD_DIR",
        "BUILD_ROOT",
        "BUILT_PRODUCTS_DIR",
        "CODESIGNING_FOLDER_PATH",
        "CONFIGURATION_BUILD_DIR",
        "CONTENTS_FOLDER_PATH",
        "CONTENTS_FOLDER_PATH_SHALLOW_BUNDLE_NO",
        "CONTENTS_FOLDER_PATH_SHALLOW_BUNDLE_YES",
        "DEPLOYMENT_LOCATION",
        "DSTROOT",
        "EXECUTABLE_EXTENSION",
        "EXECUTABLE_FOLDER_PATH",
        "EXECUTABLE_FOLDER_PATH_SHALLOW_BUNDLE_NO",
        "EXECUTABLE_FOLDER_PATH_SHALLOW_BUNDLE_YES",
        "EXECUTABLE_NAME",
        "EXECUTABLE_PATH",
        "EXECUTABLE_PREFIX",
        "EXECUTABLE_SUFFIX",
        "EXECUTABLE_VARIANT_SUFFIX",
        "EXECUTABLES_FOLDER_PATH",
        "FULL_PRODUCT_NAME",
        "INSTALL_DIR",
        "INSTALL_PATH",
        "LLVM_TARGET_TRIPLE_SUFFIX",
        "MACH_O_TYPE",
        "OBJROOT",
        "PACKAGE_TYPE",
        "PRODUCT_BUNDLE_IDENTIFIER",
        "PRODUCT_BUNDLE_PACKAGE_TYPE",
        "PRODUCT_MODULE_NAME",
        "PRODUCT_NAME",
        "PRODUCT_TYPE",
        "PRODUCT_TYPE_IDENTIFIER",
        "PROJECT",
        "PROJECT_NAME",
        "SHALLOW_BUNDLE",
        "SHALLOW_BUNDLE_PLATFORM",
        "SHALLOW_BUNDLE_TRIPLE",
        "SKIP_INSTALL",
        "SWIFT_PLATFORM_TARGET_PREFIX",
        "SYMROOT",
        "TARGET_BUILD_DIR",
        "TARGET_NAME",
        "WRAPPER_EXTENSION",
        "WRAPPER_NAME",
        "WRAPPER_PREFIX",
        "WRAPPER_SUFFIX",
    }
)

# Xcode computes SHALLOW_BUNDLE through a destination-derived setting name
# (for example SHALLOW_BUNDLE_macos).  The set of possible suffixes is owned by
# installed platforms, so enumerating only today's spellings would be unsafe.
_PRODUCT_IDENTITY_SETTING_PREFIXES = (
    "SHALLOW_BUNDLE_",
)

_UNMODELED_PRODUCT_PATH_SETTINGS = frozenset(
    {
        "BUILD_DIR",
        "BUILD_ROOT",
        "BUILT_PRODUCTS_DIR",
        "CODESIGNING_FOLDER_PATH",
        "CONFIGURATION_BUILD_DIR",
        "CONTENTS_FOLDER_PATH",
        "CONTENTS_FOLDER_PATH_SHALLOW_BUNDLE_NO",
        "CONTENTS_FOLDER_PATH_SHALLOW_BUNDLE_YES",
        "DSTROOT",
        "EXECUTABLE_FOLDER_PATH",
        "EXECUTABLE_FOLDER_PATH_SHALLOW_BUNDLE_NO",
        "EXECUTABLE_FOLDER_PATH_SHALLOW_BUNDLE_YES",
        "EXECUTABLE_PATH",
        "EXECUTABLES_FOLDER_PATH",
        "INSTALL_DIR",
        "INSTALL_PATH",
        "LLVM_TARGET_TRIPLE_SUFFIX",
        "OBJROOT",
        "PACKAGE_TYPE",
        "PRODUCT_MODULE_NAME",
        "SHALLOW_BUNDLE",
        "SHALLOW_BUNDLE_PLATFORM",
        "SHALLOW_BUNDLE_TRIPLE",
        "SWIFT_PLATFORM_TARGET_PREFIX",
        "SYMROOT",
        "TARGET_BUILD_DIR",
    }
)

_UNMODELED_PRODUCT_PATH_SETTING_PREFIXES = (
    "SHALLOW_BUNDLE_",
)

_BUNDLE_IDENTIFIER_COMPONENT = r"[A-Za-z0-9](?:[A-Za-z0-9-]*[A-Za-z0-9])?"
_BUNDLE_IDENTIFIER = re.compile(
    rf"{_BUNDLE_IDENTIFIER_COMPONENT}(?:\.{_BUNDLE_IDENTIFIER_COMPONENT})*\Z"
)


def _canonical_basename(value: str, context: str) -> str:
    """Return one canonical, variable-free POSIX filename component."""
    if (
        not value
        or value in {".", ".."}
        or "/" in value
        or "\\" in value
        or ":" in value
        or "$" in value
        or any(unicodedata.category(character).startswith("C") for character in value)
        or posixpath.basename(value) != value
        or posixpath.normpath(value) != value
    ):
        raise PlanError(f"{context} must be a canonical basename, got {value!r}")
    return value


def _safe_artifact_stem(value: str, context: str) -> str:
    """Return a normalized artifact stem safe for argv-oriented build stages.

    Spaces and normalized Unicode letters/numbers are intentional: real app
    products such as ``Firefox Focus`` use them.  Shell operators, quoting
    characters, glob syntax, and other punctuation are excluded rather than
    relying on every future consumer to recover an argv boundary correctly.
    """
    _canonical_basename(value, context)
    if value != unicodedata.normalize("NFC", value):
        raise PlanError(f"{context} must use NFC-normalized Unicode, got {value!r}")
    if value.strip() != value:
        raise PlanError(f"{context} must not have leading/trailing whitespace, got {value!r}")
    if not unicodedata.category(value[0])[0] in {"L", "N"}:
        raise PlanError(f"{context} must begin with a letter or number, got {value!r}")
    unsafe = [
        character
        for character in value
        if unicodedata.category(character)[0] not in {"L", "M", "N"}
        and character not in {" ", ".", "_", "-", "+"}
    ]
    if unsafe:
        raise PlanError(
            f"{context} contains characters outside the safe artifact grammar: {value!r}"
        )
    return value


def _safe_artifact_name(value: str, suffix: str, context: str) -> str:
    """Validate one build artifact basename with an exact product suffix."""
    _canonical_basename(value, context)
    if not value.endswith(suffix) or value == suffix:
        raise PlanError(f"{context} must end in {suffix!r}, got {value!r}")
    _safe_artifact_stem(value[: -len(suffix)], f"{context} stem")
    return value


class _ForbiddenSchemeDeclaration(Exception):
    pass


def _parse_scheme_xml(raw: bytes, path: Path) -> ET.Element:
    """Parse scheme XML while rejecting DTD/entity syntax for every encoding.

    Expat performs XML's own encoding detection before invoking declaration
    handlers, so UTF-8/16/32 and other encodings accepted by the parser receive
    the same fail-closed declaration policy.  A byte substring scan cannot make
    that guarantee (UTF-16 was the motivating counterexample).
    """
    guard = expat.ParserCreate()

    def reject_declaration(*_arguments: object) -> None:
        raise _ForbiddenSchemeDeclaration

    guard.StartDoctypeDeclHandler = reject_declaration
    guard.EntityDeclHandler = reject_declaration
    guard.ExternalEntityRefHandler = reject_declaration
    try:
        guard.Parse(raw, True)
    except _ForbiddenSchemeDeclaration as exc:
        raise PlanError(f"scheme {path} contains a forbidden DTD/entity declaration") from exc
    except expat.ExpatError as exc:
        raise PlanError(f"cannot parse scheme {path}: {exc}") from exc
    try:
        return ET.fromstring(raw)
    except ET.ParseError as exc:
        raise PlanError(f"cannot parse scheme {path}: {exc}") from exc


def _read_project(project_bundle: Path) -> tuple[Path, dict[str, Any]]:
    project_bundle = project_bundle.absolute()
    try:
        source_root_metadata = project_bundle.parent.lstat()
        if stat.S_ISLNK(source_root_metadata.st_mode):
            raise PlanError(
                f"project source root must not be a symlink: {project_bundle.parent}"
            )
        if not stat.S_ISDIR(source_root_metadata.st_mode):
            raise PlanError(
                f"project source root must be a directory: {project_bundle.parent}"
            )
        canonical_source_root = project_bundle.parent.resolve(strict=True)
    except PlanError:
        raise
    except OSError as exc:
        raise PlanError(
            f"cannot inspect project source root {project_bundle.parent}: {exc}"
        ) from exc
    project_bundle = canonical_source_root / project_bundle.name
    try:
        bundle_metadata = project_bundle.lstat()
    except OSError as exc:
        raise PlanError(f"cannot inspect project bundle {project_bundle}: {exc}") from exc
    if (
        project_bundle.suffix != ".xcodeproj"
        or stat.S_ISLNK(bundle_metadata.st_mode)
        or not stat.S_ISDIR(bundle_metadata.st_mode)
    ):
        raise PlanError(
            f"project must be an existing non-symlink .xcodeproj directory: {project_bundle}"
        )
    project_path = project_bundle / "project.pbxproj"
    try:
        metadata = project_path.lstat()
        if stat.S_ISLNK(metadata.st_mode) or not stat.S_ISREG(metadata.st_mode):
            raise PlanError(f"project file must be a regular non-symlink: {project_path}")
        parsed = xcodeplan.parse_openstep(
            project_path.read_text(encoding="utf-8"), os.fspath(project_path)
        )
    except PlanError:
        raise
    except OSError as exc:
        raise PlanError(f"cannot read project file {project_path}: {exc}") from exc
    root = xcodeplan.require_dict(parsed, "project root")
    xcodeplan.require_keys(
        root, ("archiveVersion", "objectVersion", "objects", "rootObject"), "project root"
    )
    return project_path, root


def _scheme_path(project_bundle: Path, scheme: str) -> Path:
    supplied = Path(scheme)
    supplied_is_path = supplied.suffix == ".xcscheme" or len(supplied.parts) > 1
    if supplied_is_path and supplied.suffix != ".xcscheme":
        raise PlanError(
            f"explicit shared scheme path must end in '.xcscheme', got {scheme!r}"
        )
    identity = supplied.stem if supplied_is_path else scheme
    _canonical_basename(identity, "scheme selector identity")
    if supplied_is_path:
        return supplied.absolute()
    return (
        project_bundle
        / "xcshareddata"
        / "xcschemes"
        / f"{scheme}.xcscheme"
    ).absolute()


def parse_runnable_scheme(path: Path, project_bundle: Path) -> dict[str, str]:
    if path.suffix != ".xcscheme":
        raise PlanError(f"shared scheme path must end in '.xcscheme', got {path}")
    source_root = project_bundle.parent.resolve(strict=True)
    supplied_path = path.absolute()
    current = Path(supplied_path.anchor)
    entered_source_root = current == source_root
    for component in supplied_path.parts[1:]:
        current = current / component
        try:
            metadata = current.lstat()
            resolved_current = current.resolve(strict=True)
        except OSError as exc:
            raise PlanError(f"cannot inspect shared scheme path {current}: {exc}") from exc
        if stat.S_ISLNK(metadata.st_mode):
            # Ancestor aliases such as /tmp -> /private/tmp are outside the
            # source root and may be part of its spelling. Once the walk
            # reaches the source root, no scheme component may be a symlink.
            is_strict_root_ancestor = (
                resolved_current != source_root
                and source_root.is_relative_to(resolved_current)
            )
            if not is_strict_root_ancestor:
                raise PlanError(
                    "shared scheme must be inside the project source root "
                    f"without symlinks: {path}"
                )
        if resolved_current == source_root:
            entered_source_root = True
        elif entered_source_root:
            try:
                resolved_current.relative_to(source_root)
            except ValueError as exc:
                raise PlanError(
                    f"shared scheme must be inside the project source root: {path}"
                ) from exc
        elif not source_root.is_relative_to(resolved_current):
            raise PlanError(
                f"shared scheme must be inside the project source root: {path}"
            )
    try:
        resolved_path = supplied_path.resolve(strict=True)
        relative_path = resolved_path.relative_to(source_root)
    except ValueError as exc:
        raise PlanError(
            f"shared scheme must be inside the project source root: {path}"
        ) from exc
    except OSError as exc:
        raise PlanError(f"cannot resolve shared scheme {path}: {exc}") from exc
    try:
        resolved_metadata = resolved_path.lstat()
    except OSError as exc:
        raise PlanError(f"cannot inspect shared scheme {path}: {exc}") from exc
    if not stat.S_ISREG(resolved_metadata.st_mode):
        raise PlanError(f"shared scheme must be a regular file: {path}")
    try:
        raw = resolved_path.read_bytes()
    except OSError as exc:
        raise PlanError(f"cannot read shared scheme {path}: {exc}") from exc
    root = _parse_scheme_xml(raw, path)
    if root.tag != "Scheme":
        raise PlanError(f"scheme root must be Scheme, got {root.tag!r}")

    launches = root.findall("./LaunchAction")
    if len(launches) != 1:
        raise PlanError(f"scheme must have exactly one LaunchAction, got {len(launches)}")
    launch = launches[0]
    configuration = launch.get("buildConfiguration")
    if not configuration:
        raise PlanError("scheme LaunchAction has no buildConfiguration")
    references = launch.findall("./BuildableProductRunnable/BuildableReference")
    if len(references) != 1:
        raise PlanError(
            "scheme LaunchAction must contain exactly one runnable BuildableReference"
        )
    reference = references[0]
    target_id = reference.get("BlueprintIdentifier")
    target_name = reference.get("BlueprintName")
    buildable_name = reference.get("BuildableName")
    container = reference.get("ReferencedContainer")
    required = {
        "BlueprintIdentifier": target_id,
        "BlueprintName": target_name,
        "BuildableName": buildable_name,
        "ReferencedContainer": container,
    }
    missing = [name for name, value in required.items() if not value]
    if missing:
        raise PlanError(f"scheme runnable reference is missing: {', '.join(missing)}")
    buildable_name = _safe_artifact_name(
        xcodeplan.require_string(buildable_name, "scheme runnable BuildableName"),
        ".app",
        "scheme runnable BuildableName",
    )
    if reference.get("BuildableIdentifier") != "primary":
        raise PlanError("scheme runnable BuildableIdentifier must be 'primary'")
    expected_container = f"container:{project_bundle.name}"
    if container != expected_container:
        raise PlanError(
            f"scheme runnable container must be {expected_container!r}, got {container!r}"
        )

    running_entries = []
    reference_attributes = (
        "BuildableIdentifier",
        "BlueprintIdentifier",
        "BuildableName",
        "BlueprintName",
        "ReferencedContainer",
    )
    for entry in root.findall("./BuildAction/BuildActionEntries/BuildActionEntry"):
        child = entry.find("./BuildableReference")
        if (
            child is not None
            and child.get("BlueprintIdentifier") == target_id
            and entry.get("buildForRunning") == "YES"
        ):
            mismatches = [
                name
                for name in reference_attributes
                if child.get(name) != reference.get(name)
            ]
            if mismatches:
                raise PlanError(
                    "scheme BuildAction reference differs from runnable reference: "
                    + ", ".join(mismatches)
                )
            running_entries.append(entry)
    if len(running_entries) != 1:
        raise PlanError(
            f"scheme must build runnable target {target_name!r} for running exactly once; "
            f"found {len(running_entries)} entries"
        )
    resolved_identity = _canonical_basename(
        resolved_path.stem, "resolved scheme identity"
    )
    return {
        "name": resolved_identity,
        "path": relative_path.as_posix(),
        "configuration": configuration,
        "target_id": target_id,
        "target_name": target_name,
        "buildable_name": buildable_name,
        "referenced_container": container,
    }


def _target_by_selector(root: Mapping[str, Any], selector: str | None) -> tuple[str, str]:
    objects = xcodeplan.require_dict(root.get("objects"), "project.objects")
    project_id = xcodeplan.require_string(root.get("rootObject"), "project.rootObject")
    project = xcodeplan.require_dict(objects.get(project_id), f"PBX object {project_id}")
    if project.get("isa") != "PBXProject":
        raise PlanError(f"root object {project_id} is not a PBXProject")
    candidates: list[tuple[str, str]] = []
    for raw_id in xcodeplan.require_list(project.get("targets"), "PBXProject.targets"):
        target_id = xcodeplan.require_string(raw_id, "PBXProject target reference")
        target = xcodeplan.require_dict(objects.get(target_id), f"PBX object {target_id}")
        if target.get("isa") != "PBXNativeTarget":
            continue
        name = xcodeplan.require_string(target.get("name"), f"target {target_id}.name")
        if selector is None or selector in {target_id, name}:
            candidates.append((target_id, name))
    if len(candidates) != 1:
        label = "native target" if selector is None else f"target {selector!r}"
        available = sorted(
            xcodeplan.require_string(objects[target_id].get("name"), f"target {target_id}.name")
            for target_id in xcodeplan.require_list(project.get("targets"), "PBXProject.targets")
            if isinstance(objects.get(target_id), dict)
            and objects[target_id].get("isa") == "PBXNativeTarget"
        )
        raise PlanError(
            f"{label} must resolve exactly once; found {len(candidates)} "
            f"(available: {', '.join(available)})"
        )
    return candidates[0]


def _validate_project_directory_layout(root: Mapping[str, Any]) -> None:
    """Fail closed until nontrivial PBXProject source-root rebasing is modeled."""
    objects = xcodeplan.require_dict(root.get("objects"), "project.objects")
    project_id = xcodeplan.require_string(root.get("rootObject"), "project.rootObject")
    project = xcodeplan.require_dict(objects.get(project_id), f"PBX object {project_id}")
    if project.get("isa") != "PBXProject":
        raise PlanError(f"root object {project_id} is not a PBXProject")
    for key in ("projectDirPath", "projectRoot"):
        value = xcodeplan.require_string(project.get(key, ""), f"PBXProject.{key}")
        allowed = {"", "."} if key == "projectDirPath" else {""}
        if value not in allowed:
            raise PlanError(
                f"PBXProject.{key} uses unsupported source-root rebasing {value!r}"
            )


class InventoryPlanner(xcodeplan.ProjectPlanner):
    """Generic PBX resolver with synchronized-group discovery."""

    def __init__(
        self,
        root: Mapping[str, Any],
        source_root: Path,
        project_name: str,
        target_id: str,
        configuration_name: str | None,
    ) -> None:
        objects = xcodeplan.require_dict(root.get("objects"), "project.objects")
        target = xcodeplan.require_dict(objects.get(target_id), f"PBX object {target_id}")
        target_name = xcodeplan.require_string(target.get("name"), f"target {target_id}.name")
        product_type = xcodeplan.require_string(
            target.get("productType"), f"target {target_id}.productType"
        )
        spec = xcodeplan.GraphSpec(
            scheme_name="",
            run_configuration=configuration_name or "",
            target_id=target_id,
            target_name=target_name,
            product_type=product_type,
            phases=(),
            target_dependencies=(),
            package_products=(),
            source_count=0,
            swift_source_count=0,
            non_swift_sources=(),
            framework_count=0,
            resource_count=0,
            embedded_extension_count=0,
            allowed_shell_variables=frozenset(),
        )
        self.project_name = project_name
        super().__init__(root, source_root, spec)

    @staticmethod
    def _safe_external_tree_path(value: str, source_tree: str, context: str) -> str:
        """Return a canonical path proven to remain beneath an external root."""
        if not value:
            raise PlanError(f"{context} has an empty path rooted at {source_tree}")
        if posixpath.isabs(value):
            raise PlanError(
                f"{context} has an unsafe absolute path rooted at {source_tree}: {value!r}"
            )
        if "\\" in value or ":" in value:
            raise PlanError(
                f"{context} has an unsafe separator in path rooted at {source_tree}: "
                f"{value!r}"
            )
        if "$" in value:
            raise PlanError(
                f"{context} has an unresolved variable in path rooted at {source_tree}: "
                f"{value!r}"
            )
        if any(unicodedata.category(character).startswith("C") for character in value):
            raise PlanError(
                f"{context} has a control/format character in path rooted at "
                f"{source_tree}: {value!r}"
            )
        normalized = posixpath.normpath(value)
        components = value.split("/")
        if (
            normalized != value
            or normalized in {"", ".", ".."}
            or normalized.startswith("../")
            or any(component in {"", ".", ".."} for component in components)
        ):
            raise PlanError(
                f"{context} has an unsafe non-canonical path rooted at {source_tree}: "
                f"{value!r}"
            )
        return normalized

    def resolve_file(self, ref_id: str) -> dict[str, Any]:
        resolved = super().resolve_file(ref_id)
        external_tree = resolved.get("external_tree")
        if external_tree:
            external_tree = xcodeplan.require_string(
                external_tree, f"file reference {ref_id} external tree"
            )
            resolved["path"] = self._safe_external_tree_path(
                xcodeplan.require_string(
                    resolved.get("path"), f"file reference {ref_id} external path"
                ),
                external_tree,
                f"file reference {ref_id}",
            )
        return resolved

    def _index_group_parents(self) -> None:
        for parent_id, raw in self.objects.items():
            if not isinstance(raw, dict) or raw.get("isa") not in {
                "PBXGroup",
                "PBXVariantGroup",
            }:
                continue
            for child in xcodeplan.require_list(raw.get("children", []), f"{parent_id}.children"):
                child_id = xcodeplan.require_string(child, f"child of {parent_id}")
                previous = self.parents.get(child_id)
                if previous is not None and previous != parent_id:
                    raise PlanError(
                        f"PBX object {child_id} has multiple parents: {previous} and {parent_id}"
                    )
                self.parents[child_id] = parent_id

    def _expand_path(self, value: str, context: str) -> str:
        if value.startswith("/"):
            raise PlanError(f"{context} uses an absolute path {value!r}")
        known = {
            "SRCROOT": "",
            "SOURCE_ROOT": "",
            "PROJECT_DIR": "",
            "PROJECT": self.project_name,
            "PROJECT_NAME": self.project_name,
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

    def _configuration_record(
        self, owner: Mapping[str, Any], name: str | None, context: str
    ) -> dict[str, Any]:
        list_id = xcodeplan.require_string(
            owner.get("buildConfigurationList"), f"{context}.buildConfigurationList"
        )
        config_list = self.object(list_id, "XCConfigurationList")
        raw_ids = xcodeplan.require_list(
            config_list.get("buildConfigurations"), f"{context}.buildConfigurations"
        )
        available: list[tuple[str, str]] = []
        for raw_id in raw_ids:
            config_id = xcodeplan.require_string(raw_id, f"{context} configuration reference")
            config = self.object(config_id, "XCBuildConfiguration")
            available.append(
                (config_id, xcodeplan.require_string(config.get("name"), f"config {config_id}.name"))
            )
        if name is not None:
            selected_name = xcodeplan.require_string(
                name, f"explicit {context} configuration selector"
            )
            if not selected_name:
                raise PlanError(f"explicit {context} configuration selector is empty")
        elif "defaultConfigurationName" in config_list:
            selected_name = xcodeplan.require_string(
                config_list.get("defaultConfigurationName"),
                f"{context}.defaultConfigurationName",
            )
            if not selected_name:
                raise PlanError(f"{context}.defaultConfigurationName is empty")
        else:
            selected_name = None
        if selected_name is None and len(available) == 1:
            selected_name = available[0][1]
        matches = [item for item in available if item[1] == selected_name]
        if len(matches) != 1:
            raise PlanError(
                f"{context} configuration {selected_name!r} must resolve exactly once; "
                f"available: {', '.join(item[1] for item in available)}"
            )
        config_id, selected_name = matches[0]
        config = self.object(config_id, "XCBuildConfiguration")
        result: dict[str, Any] = {
            "configuration_id": config_id,
            "name": selected_name,
            "build_settings": xcodeplan.require_dict(
                config.get("buildSettings", {}), f"config {config_id}.buildSettings"
            ),
        }
        if "baseConfigurationReference" in config:
            ref_id = xcodeplan.require_string(
                config["baseConfigurationReference"], f"config {config_id}.baseConfigurationReference"
            )
            resolved = self.resolve_file(ref_id)
            if resolved.get("external_tree"):
                raise PlanError(
                    f"config {config_id} base configuration uses an unsupported external "
                    f"source tree"
                )
            relative = xcodeplan.require_string(
                resolved.get("path"), f"config {config_id} base configuration path"
            )
            candidate = self._validate_existing_path(
                relative, f"config {config_id} base configuration"
            )
            if not candidate.is_file():
                raise PlanError(
                    f"config {config_id} base configuration is not a regular file: {relative}"
                )
            result["base_configuration"] = resolved
        elif "baseConfigurationReferenceAnchor" in config:
            anchor = xcodeplan.require_string(
                config["baseConfigurationReferenceAnchor"],
                f"config {config_id}.baseConfigurationReferenceAnchor",
            )
            relative = xcodeplan.require_string(
                config.get("baseConfigurationReferenceRelativePath"),
                f"config {config_id}.baseConfigurationReferenceRelativePath",
            )
            path = self._join(
                self._synchronized_root_directory(anchor),
                relative,
                f"config {config_id} base configuration",
            )
            candidate = self._validate_existing_path(
                path, f"config {config_id} base configuration"
            )
            if not candidate.is_file():
                raise PlanError(
                    f"config {config_id} base configuration is not a regular file: {path}"
                )
            result["base_configuration"] = {
                "anchor_id": anchor,
                "path": path,
            }
        return result

    def _expand_effective_setting(
        self,
        key: str,
        value: Any,
        settings: Mapping[str, Any],
        builtins: Mapping[str, str],
        active: frozenset[str] = frozenset(),
    ) -> Any:
        """Expand a setting when every dependency is destination-independent.

        Unknown platform defaults intentionally leave the original expression
        in the inventory.  Identity-sensitive consumers subsequently validate
        their values as literals, so an unresolved variable can never become a
        guessed product name or path.
        """

        if not isinstance(value, str):
            return value
        if key in active:
            raise PlanError(f"cycle while expanding build setting {key}")

        unresolved = False

        def replace(match: re.Match[str]) -> str:
            nonlocal unresolved
            name = match.group(1) or match.group(2)
            if name in builtins:
                return builtins[name]
            dependency = settings.get(name)
            if isinstance(dependency, str):
                try:
                    expanded = self._expand_effective_setting(
                        name,
                        dependency,
                        settings,
                        builtins,
                        active | {key},
                    )
                except PlanError:
                    unresolved = True
                    return match.group(0)
                if isinstance(expanded, str) and "$" not in expanded:
                    return expanded
            unresolved = True
            return match.group(0)

        expanded = _PBX_VARIABLE.sub(replace, value)
        if unresolved or "$" in expanded:
            return value
        return expanded

    def _materialize_configuration_settings(
        self,
        configuration: dict[str, Any],
        inherited: Mapping[str, Any],
        *,
        owner: str,
        target_name: str,
    ) -> dict[str, Any]:
        """Evaluate xcconfig then PBX settings as one Xcode precedence layer."""

        declared = xcodeplan.require_dict(
            configuration.get("build_settings"),
            f"{owner} configuration build settings",
        )
        state: dict[str, Any] = dict(inherited)
        assigned: dict[str, Any] = {}
        base = configuration.get("base_configuration")
        if base is not None:
            base_record = xcodeplan.require_dict(
                base, f"{owner} configuration base_configuration"
            )
            entry_path = xcodeplan.require_string(
                base_record.get("path"),
                f"{owner} configuration base_configuration.path",
            )
            evaluation = xcconfig.evaluate(self.repo, entry_path, state)
            state.update(evaluation.settings)
            assigned.update(evaluation.settings)
            base_record["path"] = evaluation.entry_path
            base_record["files"] = [dict(item) for item in evaluation.files]
            base_record["includes"] = [dict(item) for item in evaluation.includes]
            base_record["assignment_count"] = evaluation.assignment_count

        # PBX buildSettings is one dictionary layer.  References to the same
        # setting or $(inherited) bind to the value below this layer; references
        # to other settings remain lazy until the complete map is available.
        lower = dict(state)
        for raw_key, value in declared.items():
            key = xcodeplan.require_string(raw_key, f"{owner} build setting name")
            if isinstance(value, str):
                value = xcconfig.replace_inherited(value, key, lower.get(key))
            state[key] = value
            assigned[key] = value

        builtins = {
            "CONFIGURATION": xcodeplan.require_string(
                configuration.get("name"), f"{owner} configuration name"
            ),
            "PROJECT": self.project_name,
            "PROJECT_NAME": self.project_name,
            "TARGET_NAME": target_name,
        }
        effective = {
            key: self._expand_effective_setting(
                key, value, state, builtins
            )
            for key, value in assigned.items()
        }
        configuration["build_settings"] = effective
        combined = dict(inherited)
        combined.update(effective)
        return combined

    def _synchronized_root_directory(self, group_id: str) -> str:
        group = self.object(group_id, "PBXFileSystemSynchronizedRootGroup")
        component = group.get("path") or group.get("name")
        if not component:
            raise PlanError(f"synchronized root {group_id} has neither path nor name")
        component = self._expand_path(
            xcodeplan.require_string(component, f"synchronized root {group_id}.path"),
            f"synchronized root {group_id}.path",
        )
        source_tree = group.get("sourceTree", "<group>")
        if source_tree == "<group>":
            parent_id = self.parents.get(group_id)
            if parent_id is None:
                raise PlanError(f"synchronized root {group_id} is detached from mainGroup")
            parent = self.object(parent_id)
            if parent.get("isa") != "PBXGroup":
                raise PlanError(f"synchronized root {group_id} has non-group parent {parent_id}")
            base = self._group_directory(parent_id)
        elif source_tree in {"SOURCE_ROOT", "PROJECT_DIR"}:
            base = ""
        else:
            raise PlanError(
                f"synchronized root {group_id} has unsupported sourceTree {source_tree!r}"
            )
        return self._join(base, component, f"synchronized root {group_id}")

    @staticmethod
    def _normalize_relative(value: str, context: str) -> str:
        if not value or value.startswith("/") or "\\" in value:
            raise PlanError(f"{context} has unsafe relative path {value!r}")
        normalized = posixpath.normpath(value)
        if normalized != value or normalized == ".." or normalized.startswith("../"):
            raise PlanError(f"{context} has unsafe relative path {value!r}")
        return normalized

    def _validate_existing_path(self, relative: str, context: str) -> Path:
        candidate = self.repo / relative
        current = self.repo
        for component in Path(relative).parts:
            current = current / component
            try:
                metadata = current.lstat()
            except OSError as exc:
                raise PlanError(f"cannot inspect {context} {relative}: {exc}") from exc
            if stat.S_ISLNK(metadata.st_mode):
                raise PlanError(f"{context} traverses a symlink: {relative}")
        try:
            candidate.relative_to(self.repo)
        except ValueError as exc:
            raise PlanError(f"{context} escapes source root: {relative}") from exc
        return candidate

    def _validate_existing_path_prefix(self, relative: str, context: str) -> Path | None:
        """Reject unsafe existing ancestors while permitting a missing final input."""
        candidate = self.repo / relative
        current = self.repo
        components = Path(relative).parts
        for index, component in enumerate(components):
            current = current / component
            try:
                metadata = current.lstat()
            except FileNotFoundError:
                return None
            except OSError as exc:
                raise PlanError(f"cannot inspect {context} {relative}: {exc}") from exc
            if stat.S_ISLNK(metadata.st_mode):
                raise PlanError(f"{context} traverses a symlink: {relative}")
            if index < len(components) - 1 and not stat.S_ISDIR(metadata.st_mode):
                raise PlanError(
                    f"{context} traverses a non-directory path component: {relative}"
                )
        try:
            candidate.relative_to(self.repo)
        except ValueError as exc:
            raise PlanError(f"{context} escapes source root: {relative}") from exc
        return candidate

    @staticmethod
    def _kind_for_path(relative: str, explicit_file_type: str | None) -> str:
        if explicit_file_type is not None:
            if explicit_file_type in EXPLICIT_HEADER_FILE_TYPES:
                return "headers"
            if explicit_file_type in EXPLICIT_SOURCE_FILE_TYPES:
                return "sources"
            if explicit_file_type in EXPLICIT_RESOURCE_FILE_TYPES:
                return "resources"
            raise PlanError(
                f"synchronized file {relative!r} uses unsupported explicit file type "
                f"{explicit_file_type!r}"
            )
        extension = Path(relative).suffix.lower()
        if extension in SOURCE_EXTENSIONS:
            return "sources"
        if extension in HEADER_EXTENSIONS:
            return "headers"
        if extension in RESOURCE_EXTENSIONS:
            return "resources"
        return "unclassified"

    @staticmethod
    def _kind_for_directory(relative: str, explicit_file_type: str | None) -> str:
        if explicit_file_type is not None:
            if explicit_file_type in EXPLICIT_SOURCE_DIRECTORY_TYPES:
                return "sources"
            if explicit_file_type in EXPLICIT_RESOURCE_DIRECTORY_TYPES:
                return "resources"
            raise PlanError(
                f"synchronized directory {relative!r} uses unsupported explicit file type "
                f"{explicit_file_type!r}"
            )
        extension = Path(relative).suffix.lower()
        if extension in SOURCE_DIRECTORY_EXTENSIONS:
            return "sources"
        if extension in RESOURCE_DIRECTORY_EXTENSIONS:
            return "resources"
        return "unclassified"

    @staticmethod
    def _is_excluded(relative: str, exclusions: set[str]) -> bool:
        return any(relative == path or relative.startswith(f"{path}/") for path in exclusions)

    @staticmethod
    def _validate_directory_input(directory: Path, relative: str, owner: str) -> None:
        try:
            entries = sorted(os.scandir(directory), key=lambda entry: entry.name)
        except OSError as exc:
            raise PlanError(
                f"cannot scan directory input {relative}: {exc}"
            ) from exc
        for entry in entries:
            child = f"{relative}/{entry.name}"
            if entry.is_symlink():
                raise PlanError(
                    f"{owner} contains a symlink: {child}"
                )
            if entry.is_dir(follow_symlinks=False):
                InventoryPlanner._validate_directory_input(Path(entry.path), child, owner)
            elif not entry.is_file(follow_symlinks=False):
                raise PlanError(
                    f"{owner} contains unsupported filesystem object: "
                    f"{child}"
                )

    @staticmethod
    def _phase_item_identities(entry: Mapping[str, Any]) -> list[tuple[str, str]]:
        if entry.get("kind") == "package_product":
            return [
                (
                    "package_product",
                    xcodeplan.require_string(
                        entry.get("product_ref_id"), "phase package product reference"
                    ),
                )
            ]
        tree = xcodeplan.require_string(
            entry.get("external_tree") or "SOURCE_ROOT", "phase input source tree"
        )
        paths = entry.get("variant_paths") or [entry.get("path")]
        return [
            (tree, xcodeplan.require_string(path, "phase input path"))
            for path in paths
        ]

    @staticmethod
    def _portable_path_identity(tree: str, path: str) -> tuple[str, str]:
        """Model the aliases seen by common case/normalization-insensitive hosts."""
        return tree, unicodedata.normalize("NFC", path.casefold())

    def _filesystem_object_identity(
        self, tree: str, path: str, context: str
    ) -> tuple[int, int] | None:
        if tree != "SOURCE_ROOT":
            return None
        candidate = self.repo / path
        try:
            metadata = candidate.lstat()
        except FileNotFoundError:
            return None
        except OSError as exc:
            raise PlanError(f"cannot inspect {context} {path!r}: {exc}") from exc
        if stat.S_ISLNK(metadata.st_mode):
            raise PlanError(f"{context} traverses or names a symlink: {path}")
        return metadata.st_dev, metadata.st_ino

    def _validate_unique_phase_items(
        self, phase_id: str, entries: Sequence[Mapping[str, Any]]
    ) -> None:
        build_file_ids: set[str] = set()
        identities: dict[tuple[str, str], tuple[str, str]] = {}
        filesystem_objects: dict[tuple[int, int], tuple[str, str]] = {}
        for entry in entries:
            build_file_id = xcodeplan.require_string(
                entry.get("build_file_id"), f"phase {phase_id} build file"
            )
            if build_file_id in build_file_ids:
                raise PlanError(
                    f"phase {phase_id} repeats PBXBuildFile {build_file_id}"
                )
            build_file_ids.add(build_file_id)
            for identity in self._phase_item_identities(entry):
                tree, path = identity
                portable = self._portable_path_identity(tree, path)
                previous = identities.get(portable)
                if previous is not None:
                    raise PlanError(
                        f"phase {phase_id} inventories aliased inputs {previous[1]!r} "
                        f"and {path!r} more than once"
                    )
                identities[portable] = identity
                object_identity = self._filesystem_object_identity(
                    tree, path, f"phase {phase_id} input"
                )
                if object_identity is not None:
                    previous = filesystem_objects.get(object_identity)
                    if previous is not None:
                        raise PlanError(
                            f"phase {phase_id} inventories filesystem object through "
                            f"{previous[1]!r} and {path!r} more than once"
                        )
                    filesystem_objects[object_identity] = identity

    def _validate_unique_target_phase_items(
        self, phases: Sequence[Mapping[str, Any]]
    ) -> None:
        build_file_owners: dict[str, str] = {}
        semantic_owners: dict[tuple[str, str, str], str] = {}
        filesystem_owners: dict[tuple[str, int, int], tuple[str, str]] = {}
        for phase in phases:
            phase_id = xcodeplan.require_string(phase.get("phase_id"), "build phase id")
            kind = xcodeplan.require_string(phase.get("kind"), f"phase {phase_id} kind")
            if kind == "frameworks":
                entries = xcodeplan.require_list(
                    phase.get("items", []), f"framework phase {phase_id} items"
                )
            else:
                entries = xcodeplan.require_list(
                    phase.get("files", []), f"phase {phase_id} files"
                )
            for entry in entries:
                entry = xcodeplan.require_dict(entry, f"phase {phase_id} input")
                build_file_id = xcodeplan.require_string(
                    entry.get("build_file_id"), f"phase {phase_id} build file"
                )
                previous_phase = build_file_owners.get(build_file_id)
                if previous_phase is not None:
                    raise PlanError(
                        f"target build phases {previous_phase} and {phase_id} repeat "
                        f"PBXBuildFile {build_file_id}"
                    )
                build_file_owners[build_file_id] = phase_id

                # Linking and embedding one framework are distinct roles and use
                # distinct PBXBuildFiles in valid Xcode graphs. Within either role,
                # however, one semantic input may occur only once target-wide.
                if kind not in {"frameworks", "copy_files"}:
                    continue
                for tree, path in self._phase_item_identities(entry):
                    portable_tree, portable_path = self._portable_path_identity(tree, path)
                    identity = (kind, portable_tree, portable_path)
                    previous_phase = semantic_owners.get(identity)
                    if previous_phase is not None:
                        raise PlanError(
                            f"target {kind} phases {previous_phase} and {phase_id} "
                            f"inventory input {path!r} more than once"
                        )
                    semantic_owners[identity] = phase_id
                    object_identity = self._filesystem_object_identity(
                        tree, path, f"target {kind} phase input"
                    )
                    if object_identity is not None:
                        object_key = (kind, *object_identity)
                        previous = filesystem_owners.get(object_key)
                        if previous is not None:
                            raise PlanError(
                                f"target {kind} phases {previous[0]} and {phase_id} "
                                f"inventory one filesystem object through {previous[1]!r} "
                                f"and {path!r} more than once"
                            )
                        filesystem_owners[object_key] = (phase_id, path)

    def _synchronized_group(
        self, group_id: str, target_id: str
    ) -> dict[str, Any]:
        group = self.object(group_id, "PBXFileSystemSynchronizedRootGroup")
        relative_root = self._synchronized_root_directory(group_id)
        root_path = self._validate_existing_path(relative_root, f"synchronized root {group_id}")
        if not root_path.is_dir():
            raise PlanError(f"synchronized root is not a directory: {relative_root}")

        explicit_folders = [
            self._normalize_relative(
                xcodeplan.require_string(item, f"synchronized root {group_id}.explicitFolders"),
                f"synchronized root {group_id}.explicitFolders",
            )
            for item in xcodeplan.require_list(
                group.get("explicitFolders", []), f"synchronized root {group_id}.explicitFolders"
            )
        ]
        if explicit_folders:
            raise PlanError(
                f"synchronized root {group_id} uses unsupported explicitFolders: "
                f"{', '.join(explicit_folders)}"
            )
        raw_types = xcodeplan.require_dict(
            group.get("explicitFileTypes", {}), f"synchronized root {group_id}.explicitFileTypes"
        )
        explicit_file_types = {
            self._normalize_relative(
                xcodeplan.require_string(path, f"synchronized root {group_id}.explicitFileTypes key"),
                f"synchronized root {group_id}.explicitFileTypes key",
            ): xcodeplan.require_string(file_type, f"explicit file type for {path}")
            for path, file_type in raw_types.items()
        }
        for relative, file_type in explicit_file_types.items():
            if file_type not in EXPLICIT_SYNCHRONIZED_TYPES:
                raise PlanError(
                    f"synchronized root {group_id} path {relative!r} uses unsupported "
                    f"explicit file type {file_type!r}"
                )

        exclusions: set[str] = set()
        exception_ids: list[str] = []
        for raw_id in xcodeplan.require_list(
            group.get("exceptions", []), f"synchronized root {group_id}.exceptions"
        ):
            exception_id = xcodeplan.require_string(raw_id, f"exception of {group_id}")
            exception = self.object(exception_id)
            isa = exception["isa"]
            if isa == "PBXFileSystemSynchronizedGroupBuildPhaseMembershipExceptionSet":
                raise PlanError(
                    f"synchronized root {group_id} uses unsupported build-phase membership "
                    f"exception {exception_id}"
                )
            if isa != "PBXFileSystemSynchronizedBuildFileExceptionSet":
                raise PlanError(
                    f"synchronized root {group_id} has unsupported exception type {isa!r}"
                )
            exception_target = xcodeplan.require_string(
                exception.get("target"), f"synchronized exception {exception_id}.target"
            )
            if exception_target != target_id:
                continue
            exception_ids.append(exception_id)
            unsupported_keys = [
                key
                for key in (
                    "additionalCompilerFlagsByRelativePath",
                    "attributesByRelativePath",
                    "platformFiltersByRelativePath",
                    "privateHeaders",
                    "publicHeaders",
                )
                if exception.get(key)
            ]
            if unsupported_keys:
                raise PlanError(
                    f"synchronized exception {exception_id} uses unsupported metadata: "
                    f"{', '.join(unsupported_keys)}"
                )
            for item in xcodeplan.require_list(
                exception.get("membershipExceptions", []),
                f"synchronized exception {exception_id}.membershipExceptions",
            ):
                exclusions.add(
                    self._normalize_relative(
                        xcodeplan.require_string(item, f"membership exception {exception_id}"),
                        f"membership exception {exception_id}",
                    )
                )

        items: dict[str, list[dict[str, Any]]] = {
            "headers": [],
            "resources": [],
            "sources": [],
            "unclassified": [],
        }
        ignored: list[dict[str, str]] = []

        def visit(directory: Path, prefix: str = "") -> None:
            try:
                entries = sorted(os.scandir(directory), key=lambda entry: entry.name)
            except OSError as exc:
                raise PlanError(f"cannot scan synchronized root {relative_root}: {exc}") from exc
            for entry in entries:
                child_relative = entry.name if not prefix else f"{prefix}/{entry.name}"
                if entry.name in IGNORED_SYNCHRONIZED_NAMES or entry.name.startswith("."):
                    ignored.append({"path": child_relative, "reason": "hidden"})
                    continue
                if self._is_excluded(child_relative, exclusions):
                    ignored.append({"path": child_relative, "reason": "membership_exception"})
                    continue
                if entry.is_symlink():
                    raise PlanError(
                        f"synchronized root {group_id} contains a symlink: {child_relative}"
                    )
                if entry.is_dir(follow_symlinks=False):
                    extension = Path(entry.name).suffix.lower()
                    file_type = explicit_file_types.get(child_relative)
                    kind = self._kind_for_directory(child_relative, file_type)
                    if kind in {"sources", "resources"}:
                        self._validate_directory_input(
                            Path(entry.path), child_relative, f"synchronized root {group_id}"
                        )
                        item = {
                            "group_id": group_id,
                            "origin": "filesystem_synchronized",
                            "path": self._join(
                                relative_root, child_relative, f"synchronized item {child_relative}"
                            ),
                            "relative_path": child_relative,
                        }
                        if file_type:
                            item["explicit_file_type"] = file_type
                        item[
                            "directory_source" if kind == "sources" else "directory_resource"
                        ] = True
                        items[kind].append(item)
                    elif file_type or (
                        extension and extension not in RECURSIVE_DIRECTORY_EXTENSIONS
                    ):
                        self._validate_directory_input(
                            Path(entry.path), child_relative, f"synchronized root {group_id}"
                        )
                        item = {
                            "group_id": group_id,
                            "origin": "filesystem_synchronized",
                            "path": self._join(
                                relative_root,
                                child_relative,
                                f"synchronized item {child_relative}",
                            ),
                            "relative_path": child_relative,
                            "directory_input": True,
                        }
                        if file_type:
                            item["explicit_file_type"] = file_type
                        items["unclassified"].append(item)
                    else:
                        visit(Path(entry.path), child_relative)
                    continue
                if not entry.is_file(follow_symlinks=False):
                    raise PlanError(
                        f"synchronized root {group_id} contains unsupported filesystem object: "
                        f"{child_relative}"
                    )
                file_type = explicit_file_types.get(child_relative)
                kind = self._kind_for_path(child_relative, file_type)
                item = {
                    "group_id": group_id,
                    "origin": "filesystem_synchronized",
                    "path": self._join(
                        relative_root, child_relative, f"synchronized item {child_relative}"
                    ),
                    "relative_path": child_relative,
                }
                if file_type:
                    item["explicit_file_type"] = file_type
                items[kind].append(item)

        visit(root_path)
        consumed_types = {
            item["relative_path"] for values in items.values() for item in values
        }
        for relative in set(explicit_file_types) - consumed_types:
            if not self._is_excluded(relative, exclusions):
                continue
            project_relative = self._join(
                relative_root,
                relative,
                f"excluded explicit file type {relative}",
            )
            if not os.path.lexists(self.repo / project_relative):
                continue
            excluded_path = self._validate_existing_path(
                project_relative,
                f"excluded explicit file type {relative}",
            )
            if excluded_path.is_file():
                self._kind_for_path(relative, explicit_file_types[relative])
            elif excluded_path.is_dir():
                self._kind_for_directory(relative, explicit_file_types[relative])
            else:
                raise PlanError(
                    f"synchronized root {group_id} has an explicit file type for an "
                    f"unsupported filesystem object: {relative}"
                )
            consumed_types.add(relative)
        unused_types = sorted(set(explicit_file_types) - consumed_types)
        if unused_types:
            raise PlanError(
                f"synchronized root {group_id} has explicit file types for absent/excluded paths: "
                f"{', '.join(unused_types)}"
            )
        return {
            "group_id": group_id,
            "path": relative_root,
            "source_tree": group.get("sourceTree", "<group>"),
            "exception_ids": exception_ids,
            "membership_exceptions": sorted(exclusions),
            "items": items,
            "ignored": ignored,
        }

    def _explicit_phase_files(
        self, phase_id: str, phase: Mapping[str, Any], *, allow_external: bool
    ) -> list[dict[str, Any]]:
        result = self._file_phase(phase_id, phase, require_internal=not allow_external)
        for entry in result:
            entry["origin"] = "explicit"
            if entry.get("external_tree"):
                continue
            relative_paths = entry.get("variant_paths") or [entry["path"]]
            missing_paths: list[str] = []
            for relative in relative_paths:
                candidate = self._validate_existing_path_prefix(
                    relative, f"explicit phase input {entry['build_file_id']}"
                )
                if candidate is None:
                    missing_paths.append(relative)
                    continue
                if candidate.is_dir():
                    self._validate_directory_input(
                        candidate, relative, f"phase {phase_id}"
                    )
                elif not candidate.is_file():
                    raise PlanError(
                        f"explicit phase input is not a regular file or directory: {relative}"
                    )
            if missing_paths:
                entry["missing_paths"] = missing_paths
        self._validate_unique_phase_items(phase_id, result)
        return result

    def _framework_items(self, phase_id: str, phase: Mapping[str, Any]) -> list[dict[str, Any]]:
        result: list[dict[str, Any]] = []
        for raw_id in xcodeplan.require_list(phase.get("files", []), f"phase {phase_id}.files"):
            build_file_id = xcodeplan.require_string(raw_id, f"phase {phase_id} build file")
            build_file, reference = self._build_file(build_file_id)
            if reference["kind"] == "productRef":
                product = self.object(reference["id"], "XCSwiftPackageProductDependency")
                item: dict[str, Any] = {
                    "build_file_id": build_file_id,
                    "kind": "package_product",
                    "product_ref_id": reference["id"],
                    "name": xcodeplan.require_string(
                        product.get("productName"), f"product {reference['id']}.productName"
                    ),
                }
            else:
                resolved = self.resolve_file(reference["id"])
                if not resolved.get("external_tree"):
                    relative = xcodeplan.require_string(
                        resolved.get("path"), f"framework reference {reference['id']}.path"
                    )
                    candidate = self._validate_existing_path_prefix(
                        relative, f"framework phase input {build_file_id}"
                    )
                    if candidate is None:
                        resolved["missing_paths"] = [relative]
                    else:
                        if candidate.is_dir():
                            self._validate_directory_input(
                                candidate, relative, f"framework phase {phase_id}"
                            )
                        elif not candidate.is_file():
                            raise PlanError(
                                f"framework phase input is not a regular file or directory: "
                                f"{relative}"
                            )
                item = {
                    "build_file_id": build_file_id,
                    "kind": "file_reference",
                    **resolved,
                }
            if "settings" in build_file:
                item["settings"] = build_file["settings"]
            result.append(item)
        self._validate_unique_phase_items(phase_id, result)
        return result

    def _phase_records(self, target: Mapping[str, Any]) -> tuple[list[dict[str, Any]], list[dict[str, Any]], list[dict[str, Any]], list[dict[str, Any]], list[str]]:
        phases: list[dict[str, Any]] = []
        sources: list[dict[str, Any]] = []
        resources: list[dict[str, Any]] = []
        headers: list[dict[str, Any]] = []
        unsupported: list[str] = []
        unsupported_shell_inputs: list[tuple[str, list[str]]] = []
        for index, raw_id in enumerate(
            xcodeplan.require_list(target.get("buildPhases", []), "target.buildPhases")
        ):
            phase_id = xcodeplan.require_string(raw_id, f"target.buildPhases[{index}]")
            phase = self.object(phase_id)
            isa = phase["isa"]
            kind = PHASE_KINDS.get(isa, "unsupported")
            record: dict[str, Any] = {
                "index": index,
                "phase_id": phase_id,
                "isa": isa,
                "kind": kind,
                "name": phase.get("name") or kind.replace("_", " ").title(),
            }
            if kind in {"sources", "resources", "headers"}:
                files = self._explicit_phase_files(
                    phase_id, phase, allow_external=False
                )
                record["files"] = files
                if kind == "sources":
                    sources.extend(files)
                elif kind == "resources":
                    resources.extend(files)
                else:
                    headers.extend(files)
            elif kind == "frameworks":
                record["items"] = self._framework_items(phase_id, phase)
            elif kind == "copy_files":
                record["files"] = self._explicit_phase_files(
                    phase_id, phase, allow_external=True
                )
                record["destination_subfolder_spec"] = xcodeplan.require_string(
                    phase.get("dstSubfolderSpec", "0"), f"copy phase {phase_id}.dstSubfolderSpec"
                )
                record["destination_path"] = xcodeplan.require_string(
                    phase.get("dstPath", ""), f"copy phase {phase_id}.dstPath"
                )
            elif kind == "shell_script":
                shell_phase = dict(phase)
                shell_phase["files"] = xcodeplan.require_list(
                    phase.get("files", []), f"shell phase {phase_id}.files"
                )
                shell_files = self._explicit_phase_files(
                    phase_id, shell_phase, allow_external=True
                )
                record["files"] = shell_files
                if shell_files:
                    build_file_ids = [
                        xcodeplan.require_string(
                            entry.get("build_file_id"),
                            f"shell phase {phase_id} build file",
                        )
                        for entry in shell_files
                    ]
                    unsupported_shell_inputs.append((phase_id, build_file_ids))
                script = xcodeplan.require_string(
                    phase.get("shellScript", ""), f"shell phase {phase_id}.shellScript"
                )
                record.update(
                    {
                        "shell_path": xcodeplan.require_string(
                            phase.get("shellPath", ""), f"shell phase {phase_id}.shellPath"
                        ),
                        "script_sha256": xcodeplan.sha256_bytes(script.encode("utf-8")),
                    }
                )
                for key, output_key in (
                    ("inputPaths", "input_paths"),
                    ("outputPaths", "output_paths"),
                    ("inputFileListPaths", "input_file_lists"),
                    ("outputFileListPaths", "output_file_lists"),
                ):
                    record[output_key] = [
                        xcodeplan.require_string(value, f"shell phase {phase_id}.{key}")
                        for value in xcodeplan.require_list(
                            phase.get(key, []), f"shell phase {phase_id}.{key}"
                        )
                    ]
            else:
                unsupported.append(f"build phase {phase_id} has unsupported type {isa}")
            phases.append(record)
        self._validate_unique_target_phase_items(phases)
        if unsupported_shell_inputs:
            phase_id, build_file_ids = unsupported_shell_inputs[0]
            raise PlanError(
                f"shell phase {phase_id} contains unsupported PBXBuildFile inputs: "
                f"{', '.join(build_file_ids)}"
            )
        return phases, sources, resources, headers, unsupported

    def _expand_product_name(
        self,
        configured: str,
        *,
        context: str,
        target_name: str,
        inherited: str | None,
    ) -> str:
        replacements = {
            "PROJECT": self.project_name,
            "PROJECT_NAME": self.project_name,
            "TARGET_NAME": target_name,
        }

        def replace(match: re.Match[str]) -> str:
            variable = match.group(1) or match.group(2)
            if variable == "inherited":
                if inherited is None:
                    raise PlanError(
                        "unresolved PRODUCT_NAME variable 'inherited': no inherited "
                        f"value is available for {context}"
                    )
                return inherited
            if variable not in replacements:
                raise PlanError(
                    f"unresolved PRODUCT_NAME variable {variable!r} in {context}"
                )
            return replacements[variable]

        effective = _PBX_VARIABLE.sub(replace, configured)
        if "$" in effective or not effective:
            raise PlanError(f"cannot resolve {context} {configured!r}")
        return _safe_artifact_stem(effective, "effective PRODUCT_NAME")

    @staticmethod
    def _product_identity_setting_key(key: str) -> tuple[str, bool] | None:
        """Classify a setting name using Xcode's whitespace behavior.

        Xcode right-trims direct build-setting names and permits whitespace
        between a base name and its first conditional bracket.  Python's
        Unicode-aware ``strip`` is intentionally a little stricter than the
        observed native ASCII space/tab behavior: no whitespace alias of a
        product-identity setting is allowed to pass as an unrelated key.
        """
        raw_base, separator, _conditions = key.partition("[")
        base = raw_base.strip()
        if (
            base not in _PRODUCT_IDENTITY_SETTING_NAMES
            and not any(
                base.startswith(prefix)
                for prefix in _PRODUCT_IDENTITY_SETTING_PREFIXES
            )
        ):
            return None
        return base, bool(separator)

    def _validate_product_identity_setting_keys(
        self,
        settings_by_owner: Sequence[tuple[str, Mapping[str, Any]]],
    ) -> None:
        conditional: list[str] = []
        aliases: list[str] = []
        for owner, settings in settings_by_owner:
            for raw_key in settings:
                key = xcodeplan.require_string(raw_key, f"{owner} build setting name")
                classified = self._product_identity_setting_key(key)
                if classified is None:
                    continue
                base, is_conditional = classified
                if is_conditional:
                    conditional.append(f"{owner}:{key!r}")
                elif key != base:
                    aliases.append(f"{owner}:{key!r}")
        if conditional:
            raise PlanError(
                "cannot determine product identity with conditional build settings: "
                + ", ".join(sorted(conditional))
            )
        if aliases:
            raise PlanError(
                "cannot determine product identity with noncanonical build setting "
                "key aliases: "
                + ", ".join(sorted(aliases))
            )

    @staticmethod
    def _validate_bundle_identifier(value: str, context: str) -> str:
        if (
            value != unicodedata.normalize("NFC", value)
            or value.strip() != value
            or _BUNDLE_IDENTIFIER.fullmatch(value) is None
        ):
            raise PlanError(
                f"{context} must be a nonempty, variable-free ASCII DNS-style bundle "
                "identifier"
            )
        return value

    def _validate_native_product_settings(
        self,
        settings_by_owner: Sequence[tuple[str, Mapping[str, Any]]],
        *,
        target_name: str,
        effective_product_name: str,
        buildable_name: str,
        product_type: str,
        expected_suffix: str,
    ) -> None:
        """Prove the native wrapper and executable identity or fail closed.

        Xcode permits these derived values to be overridden independently.
        Notably, FULL_PRODUCT_NAME can even disagree with WRAPPER_NAME and split
        the native build graph.  We accept absent defaults and exact canonical
        literals only; conditionals, inheritance, and path relocation remain
        outside this inventory's destination-independent contract.
        """
        expected_literals = {
            "DEPLOYMENT_LOCATION": "NO",
            "EXECUTABLE_EXTENSION": "",
            "EXECUTABLE_NAME": effective_product_name,
            "EXECUTABLE_PREFIX": "",
            "EXECUTABLE_SUFFIX": "",
            "EXECUTABLE_VARIANT_SUFFIX": "",
            "FULL_PRODUCT_NAME": buildable_name,
            "MACH_O_TYPE": "mh_execute",
            "PRODUCT_BUNDLE_PACKAGE_TYPE": "APPL",
            "PRODUCT_TYPE": product_type,
            "PRODUCT_TYPE_IDENTIFIER": product_type,
            "PROJECT": self.project_name,
            "PROJECT_NAME": self.project_name,
            "SKIP_INSTALL": "NO",
            "TARGET_NAME": target_name,
            "WRAPPER_EXTENSION": expected_suffix.removeprefix("."),
            "WRAPPER_NAME": buildable_name,
            "WRAPPER_PREFIX": "",
            "WRAPPER_SUFFIX": expected_suffix,
        }
        for owner, settings in settings_by_owner:
            for key in sorted(settings):
                if (
                    key in _UNMODELED_PRODUCT_PATH_SETTINGS
                    or any(
                        key.startswith(prefix)
                        for prefix in _UNMODELED_PRODUCT_PATH_SETTING_PREFIXES
                    )
                ):
                    raise PlanError(
                        f"cannot determine product identity with explicit {owner} "
                        f"build setting {key}"
                    )
            for key, expected in expected_literals.items():
                if key not in settings:
                    continue
                actual = xcodeplan.require_string(
                    settings.get(key), f"{owner} build setting {key}"
                )
                if actual != expected:
                    raise PlanError(
                        f"{owner} build setting {key} must be the canonical literal "
                        f"{expected!r}, got {actual!r}"
                    )
            if "PRODUCT_BUNDLE_IDENTIFIER" in settings:
                self._validate_bundle_identifier(
                    xcodeplan.require_string(
                        settings.get("PRODUCT_BUNDLE_IDENTIFIER"),
                        f"{owner} PRODUCT_BUNDLE_IDENTIFIER",
                    ),
                    f"{owner} PRODUCT_BUNDLE_IDENTIFIER",
                )

    def _product_identity(
        self,
        target: Mapping[str, Any],
        target_configuration: Mapping[str, Any],
        project_configuration: Mapping[str, Any] | None,
        product_reference: Mapping[str, Any],
        product: Mapping[str, Any],
        product_type: str,
        expected_suffix: str,
        scheme: Mapping[str, str] | None,
    ) -> dict[str, str]:
        """Resolve one validated product identity for scheme and target modes.

        PBX product-reference paths are presentation metadata and can be stale
        across configurations (Focus uses one shared reference for differently
        named Focus/Klar products).  The selected configuration's effective
        PRODUCT_NAME is authoritative.  A runnable scheme, when supplied, must
        agree with that effective artifact exactly.
        """
        target_name = _safe_artifact_stem(
            xcodeplan.require_string(target.get("name"), "selected target.name"),
            "selected target.name",
        )
        if "productName" in target:
            target_product_name_value = xcodeplan.require_string(
                target.get("productName"), "selected target.productName"
            )
        else:
            target_product_name_value = target_name
        target_product_name = _safe_artifact_stem(
            target_product_name_value, "selected target.productName"
        )

        product_path = xcodeplan.require_string(
            product.get("path"), "selected target product path"
        )
        product_path_components = product_path.split("/")
        for component in product_path_components[:-1]:
            _safe_artifact_stem(
                component,
                "selected target product-reference directory component",
            )
        reference_output_name = _safe_artifact_name(
            product_path_components[-1],
            expected_suffix,
            "selected target product-reference output name",
        )
        if "name" in product_reference:
            _safe_artifact_name(
                xcodeplan.require_string(
                    product_reference.get("name"),
                    "selected target.productReference.name",
                ),
                expected_suffix,
                "selected target.productReference.name",
            )

        target_settings = xcodeplan.require_dict(
            target_configuration.get("build_settings"),
            "target configuration build settings",
        )
        project_settings = (
            xcodeplan.require_dict(
                project_configuration.get("build_settings"),
                "project configuration build settings",
            )
            if project_configuration is not None
            else {}
        )
        settings_by_owner = (
            ("project", project_settings),
            ("target", target_settings),
        )
        self._validate_product_identity_setting_keys(settings_by_owner)
        target_product_setting_text = (
            xcodeplan.require_string(
                target_settings.get("PRODUCT_NAME"), "target PRODUCT_NAME"
            )
            if "PRODUCT_NAME" in target_settings
            else None
        )
        inherited_product_name: str | None = None
        if "PRODUCT_NAME" in project_settings:
            inherited_product_name = self._expand_product_name(
                xcodeplan.require_string(
                    project_settings.get("PRODUCT_NAME"),
                    "project PRODUCT_NAME",
                ),
                context="project PRODUCT_NAME",
                target_name=target_name,
                inherited=None,
            )

        if target_product_setting_text is not None:
            effective_product_name = self._expand_product_name(
                target_product_setting_text,
                context="target PRODUCT_NAME",
                target_name=target_name,
                inherited=inherited_product_name,
            )
            setting_origin = "target"
        elif inherited_product_name is not None:
            effective_product_name = inherited_product_name
            setting_origin = "project"
        else:
            # Xcode does not default an absent PRODUCT_NAME from PBX target or
            # product-reference presentation metadata.  Its application
            # package rules instead derive an empty stem (for example `.app`).
            # Inventing a basename here would therefore misreport the native
            # wrapper even if a coordinated scheme used the same invented name.
            raise PlanError(
                "cannot determine product identity without an explicit PRODUCT_NAME "
                "in the selected target or project build configuration"
            )

        buildable_name = _safe_artifact_name(
            f"{effective_product_name}{expected_suffix}",
            expected_suffix,
            "effective build artifact name",
        )
        self._validate_native_product_settings(
            settings_by_owner,
            target_name=target_name,
            effective_product_name=effective_product_name,
            buildable_name=buildable_name,
            product_type=product_type,
            expected_suffix=expected_suffix,
        )
        if scheme is not None and scheme["buildable_name"] != buildable_name:
            raise PlanError(
                f"scheme buildable name {scheme['buildable_name']!r} does not match "
                f"effective product name {buildable_name!r}"
            )
        return {
            "target_name": target_name,
            "target_product_name": target_product_name,
            "effective_product_name": effective_product_name,
            "buildable_name": buildable_name,
            "product_reference_name": reference_output_name,
            "product_name_origin": setting_origin,
        }

    def build_inventory(
        self,
        project_path: Path,
        configuration_name: str | None,
        scheme: Mapping[str, str] | None,
    ) -> dict[str, Any]:
        target = self.object(self.spec.target_id, "PBXNativeTarget")
        if xcodeplan.require_list(target.get("buildRules", []), "target.buildRules"):
            raise PlanError("selected target contains unsupported custom build rules")
        target_name = xcodeplan.require_string(target.get("name"), "selected target.name")
        product_type = xcodeplan.require_string(
            target.get("productType"), "selected target.productType"
        )
        if scheme is not None:
            if scheme["target_id"] != self.spec.target_id or scheme["target_name"] != target_name:
                raise PlanError("scheme runnable target does not match selected PBX target")
        selected_configuration = configuration_name
        target_configuration = self._configuration_record(
            target, selected_configuration, "target"
        )
        selected_configuration = target_configuration["name"]
        project_configuration = (
            self._configuration_record(self.project, selected_configuration, "project")
            if "buildConfigurationList" in self.project
            else None
        )
        target_name = xcodeplan.require_string(
            target.get("name"), "selected target.name"
        )
        project_effective_settings = (
            self._materialize_configuration_settings(
                project_configuration,
                {},
                owner="project",
                target_name=target_name,
            )
            if project_configuration is not None
            else {}
        )
        self._materialize_configuration_settings(
            target_configuration,
            project_effective_settings,
            owner="target",
            target_name=target_name,
        )
        product_ref_id = xcodeplan.require_string(
            target.get("productReference"), "selected target.productReference"
        )
        product_reference = self.object(product_ref_id, "PBXFileReference")
        product_source_tree = xcodeplan.require_string(
            product_reference.get("sourceTree"),
            "selected target.productReference.sourceTree",
        )
        if product_source_tree != "BUILT_PRODUCTS_DIR":
            raise PlanError(
                "selected target product reference must use BUILT_PRODUCTS_DIR, "
                f"got {product_source_tree!r}"
            )
        expected_product = SUPPORTED_PRODUCT_TYPES.get(product_type)
        if expected_product is None:
            raise PlanError(
                f"selected target uses unsupported product type {product_type!r}"
            )
        expected_file_type, expected_suffix = expected_product
        declared_product_types = {
            xcodeplan.require_string(
                product_reference[key], f"selected target.productReference.{key}"
            )
            for key in ("explicitFileType", "lastKnownFileType")
            if key in product_reference
        }
        if declared_product_types != {expected_file_type}:
            raise PlanError(
                f"selected target product reference type must be {expected_file_type!r}, "
                f"got {sorted(declared_product_types)!r}"
            )
        if "path" in product_reference:
            product_component = xcodeplan.require_string(
                product_reference.get("path"),
                "selected target.productReference path",
            )
            if not product_component:
                raise PlanError("selected target.productReference path is empty")
        else:
            product_component = xcodeplan.require_string(
                product_reference.get("name"),
                "selected target.productReference name fallback",
            )
            if not product_component:
                raise PlanError("selected target.productReference name fallback is empty")
        if Path(product_component).suffix != expected_suffix:
            raise PlanError(
                f"selected target product reference must end in {expected_suffix!r}, "
                f"got {product_component!r}"
            )
        product = self.resolve_file(product_ref_id)
        product_identity = self._product_identity(
            target,
            target_configuration,
            project_configuration,
            product_reference,
            product,
            product_type,
            expected_suffix,
            scheme,
        )

        phases, sources, resources, headers, unsupported = self._phase_records(target)
        missing_inputs: list[dict[str, str]] = []
        for phase in phases:
            phase_id = xcodeplan.require_string(phase.get("phase_id"), "build phase id")
            for entry in phase.get("files") or phase.get("items") or []:
                for path in entry.get("missing_paths", []):
                    missing_inputs.append(
                        {
                            "build_file_id": xcodeplan.require_string(
                                entry.get("build_file_id"),
                                f"missing input in phase {phase_id}",
                            ),
                            "path": xcodeplan.require_string(
                                path, f"missing input path in phase {phase_id}"
                            ),
                            "phase_id": phase_id,
                        }
                    )
        if missing_inputs:
            unsupported.append(
                f"{len(missing_inputs)} classic build-phase input(s) are not materialized"
            )
        synchronized_groups = []
        unclassified: list[dict[str, Any]] = []
        seen_group_ids: set[str] = set()
        for raw_id in xcodeplan.require_list(
            target.get("fileSystemSynchronizedGroups", []),
            "target.fileSystemSynchronizedGroups",
        ):
            group_id = xcodeplan.require_string(raw_id, "filesystem synchronized group")
            if group_id in seen_group_ids:
                raise PlanError(f"target repeats synchronized group {group_id}")
            seen_group_ids.add(group_id)
            group = self._synchronized_group(group_id, self.spec.target_id)
            synchronized_groups.append(group)
            sources.extend(group["items"]["sources"])
            resources.extend(group["items"]["resources"])
            headers.extend(group["items"]["headers"])
            unclassified.extend(group["items"]["unclassified"])
        phase_kinds = {phase["kind"] for phase in phases}
        if any(group["items"]["sources"] for group in synchronized_groups) and "sources" not in phase_kinds:
            raise PlanError("filesystem-synchronized sources have no PBXSourcesBuildPhase")
        if any(group["items"]["resources"] for group in synchronized_groups) and "resources" not in phase_kinds:
            raise PlanError("filesystem-synchronized resources have no PBXResourcesBuildPhase")

        categorized = {
            "sources": sources,
            "resources": resources,
            "headers": headers,
            "unclassified": unclassified,
        }
        category_by_path: dict[str, tuple[str, str]] = {}
        category_by_object: dict[tuple[int, int], tuple[str, str]] = {}
        for category, entries in categorized.items():
            for entry in entries:
                paths = entry.get("variant_paths") or [entry.get("path")]
                for raw_path in paths:
                    path = xcodeplan.require_string(raw_path, f"{category} entry path")
                    _, portable_path = self._portable_path_identity("SOURCE_ROOT", path)
                    previous = category_by_path.get(portable_path)
                    if previous is not None:
                        raise PlanError(
                            f"project target inventories aliased paths {previous[1]!r} and "
                            f"{path!r} more than once ({previous[0]} and {category})"
                        )
                    category_by_path[portable_path] = (category, path)
                    object_identity = self._filesystem_object_identity(
                        "SOURCE_ROOT", path, f"{category} entry"
                    )
                    if object_identity is not None:
                        previous = category_by_object.get(object_identity)
                        if previous is not None:
                            raise PlanError(
                                f"project target inventories one filesystem object through "
                                f"{previous[1]!r} and {path!r} more than once "
                                f"({previous[0]} and {category})"
                            )
                        category_by_object[object_identity] = (category, path)
        if unclassified:
            unsupported.append(
                f"{len(unclassified)} filesystem-synchronized path(s) have unknown build membership"
            )

        dependencies = self._target_dependencies(target)
        package_products = self._package_products(target)
        relative_project = project_path.relative_to(self.repo).as_posix()
        result: dict[str, Any] = {
            "format_version": 1,
            "project": {
                "name": self.project_name,
                "path": relative_project,
                "sha256": xcodeplan.sha256_file(project_path),
                "archive_version": self.root["archiveVersion"],
                "object_version": self.root["objectVersion"],
            },
            "target": {
                "target_id": self.spec.target_id,
                "name": product_identity["target_name"],
                "product_name": product_identity["target_product_name"],
                "effective_product_name": product_identity["effective_product_name"],
                "buildable_name": product_identity["buildable_name"],
                "product_name_origin": product_identity["product_name_origin"],
                "product_type": product_type,
                "product": product,
            },
            "configuration": {
                "name": selected_configuration,
                "project": project_configuration,
                "target": target_configuration,
            },
            "build_phases": phases,
            "filesystem_synchronized_groups": synchronized_groups,
            "sources": sources,
            "resources": resources,
            "headers": headers,
            "unclassified": unclassified,
            "target_dependencies": dependencies,
            "package_products": package_products,
            "missing_inputs": missing_inputs,
            "unsupported_features": unsupported,
            "summary": {
                "phase_count": len(phases),
                "source_count": len(sources),
                "swift_source_count": sum(
                    item["path"].lower().endswith(".swift") for item in sources
                ),
                "resource_count": len(resources),
                "header_count": len(headers),
                "unclassified_count": len(unclassified),
                "synchronized_group_count": len(synchronized_groups),
                "target_dependency_count": len(dependencies),
                "package_product_count": len(package_products),
                "missing_input_count": len(missing_inputs),
            },
        }
        if scheme is not None:
            result["scheme"] = dict(scheme)
        return result


def build_project_inventory(
    project_bundle: Path,
    *,
    scheme_name: str | None = None,
    target_selector: str | None = None,
    configuration_name: str | None = None,
) -> dict[str, Any]:
    for label, value in (
        ("--scheme", scheme_name),
        ("--target", target_selector),
        ("--configuration", configuration_name),
    ):
        if value is not None:
            xcodeplan.require_string(value, f"{label} selector")
            if not value:
                raise PlanError(f"{label} selector must not be empty")
    project_bundle = project_bundle.absolute()
    project_path, root = _read_project(project_bundle)
    _validate_project_directory_layout(root)
    project_bundle = project_path.parent
    source_root = project_bundle.parent
    scheme = None
    if scheme_name is not None:
        scheme = parse_runnable_scheme(
            _scheme_path(project_bundle, scheme_name), project_bundle
        )
        if target_selector is not None and target_selector not in {
            scheme["target_id"],
            scheme["target_name"],
        }:
            raise PlanError("--target does not match the scheme runnable target")
        if (
            configuration_name is not None
            and configuration_name != scheme["configuration"]
        ):
            raise PlanError("--configuration does not match the scheme launch configuration")
        target_selector = scheme["target_id"]
        configuration_name = scheme["configuration"]
    target_id, _ = _target_by_selector(root, target_selector)
    planner = InventoryPlanner(
        root,
        source_root,
        project_bundle.stem,
        target_id,
        configuration_name,
    )
    return planner.build_inventory(project_path, configuration_name, scheme)


def canonical_json(value: Mapping[str, Any]) -> bytes:
    return (json.dumps(value, sort_keys=True, indent=2, ensure_ascii=False) + "\n").encode(
        "utf-8"
    )


def main(argv: Sequence[str] | None = None) -> int:
    parser = argparse.ArgumentParser(
        description="Inventory one runnable target from an Xcode project without Xcode."
    )
    parser.add_argument("project", type=Path, help="path to an .xcodeproj directory")
    selection = parser.add_mutually_exclusive_group()
    selection.add_argument("--scheme", help="shared scheme name or .xcscheme path")
    selection.add_argument("--target", help="native target name or PBX object identifier")
    parser.add_argument("--configuration", help="target configuration (inferred from scheme/default)")
    parser.add_argument("--output", type=Path, help="write canonical JSON here instead of stdout")
    args = parser.parse_args(argv)
    try:
        payload = canonical_json(
            build_project_inventory(
                args.project,
                scheme_name=args.scheme,
                target_selector=args.target,
                configuration_name=args.configuration,
            )
        )
        if args.output:
            args.output.write_bytes(payload)
        else:
            sys.stdout.buffer.write(payload)
    except (PlanError, OSError) as exc:
        print(f"project-inventory: ERROR: {exc}", file=sys.stderr)
        return 2
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
