#!/usr/bin/env python3
"""Generate an immutable clean-room seed for one Apple framework port.

The generator intentionally runs only on the Mac/Xcode oracle host.  It records
public SDK evidence and exact symbol-graph output, but never copies Apple SDK
headers, module maps, Swift interfaces, or text-based dylib stubs into the
repository.
"""

from __future__ import annotations

import argparse
import ctypes
from dataclasses import dataclass
import errno
import hashlib
import json
import math
import os
from pathlib import Path, PurePosixPath
import re
import shutil
import stat
import struct
import subprocess
import sys
import tempfile
from typing import Any, Iterable, Iterator, Sequence


SCHEMA = 1
FRAMEWORK_SCHEMA = 2
SYMBOL_GRAPH_SCHEMA = 2
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
    "canonical-payload-v2"
)
SEMANTIC_HASH_POLICY = "sorted-canonical-json-u64be-length-prefixed-sha256-v1"
SYMBOL_MULTISET_DOMAIN = b"OpenUIKit.SymbolGraph.SymbolMultiset.v1\0"
RELATIONSHIP_MULTISET_DOMAIN = b"OpenUIKit.SymbolGraph.RelationshipMultiset.v1\0"
CONFLICT_HEADER = (
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
)
CROSSWALK_HEADER = (
    "precise",
    "graphKind",
    "graphPath",
    "status",
    "basis",
    "rawCandidateCount",
    "compatibleCandidateCount",
    "selectedNodePath",
    "candidateNodePaths",
)
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
MODULE_RE = re.compile(r"^[A-Za-z_][A-Za-z0-9_]*$")
SLUG_RE = re.compile(r"^[a-z][a-z0-9]*(?:-[a-z0-9]+)*$")
MODULE_LOCATION_KINDS = (
    "framework",
    "framework-clang-module",
    "swift-module",
    "clang-module",
    "clang-submodule",
)
ROADMAP_OPERATOR_OVERRIDE = "none (operator override)"
IGNORED_REEXPORT_MODULES = frozenset(
    {
        "Block",
        "CFNetwork",
        "CoreFoundation",
        "Darwin",
        "Dispatch",
        "Foundation",
        "ObjectiveC",
        "Swift",
        "SwiftOnoneSupport",
        "SwiftShims",
        "XPC",
        "_Concurrency",
        "_StringProcessing",
        "os",
        "os_object",
        "os_workgroup",
        "ptrauth",
        "ptrcheck",
    }
)
_MODULEMAP_DECL_RE = re.compile(
    r"(?:(?P<extern>extern)\s+)?(?:explicit\s+)?(?:framework\s+)?"
    r"(?<![A-Za-z0-9_])module\s+"
    r"(?P<name>\*|[_A-Za-z][_A-Za-z0-9]*)"
)
_MODULEMAP_HEADER_RE = re.compile(
    r"""(?:exclude\s+)?(?:umbrella\s+)?header\s+("(?:\\.|[^"\\])*"|<(?:\\.|[^>\\])*>)"""
)
_MODULEMAP_UMBRELLA_DIR_RE = re.compile(
    r"""umbrella\s+("(?:\\.|[^"\\])*")"""
)
_MODULEMAP_EXPORT_RE = re.compile(
    r"export\s+(\*|[_A-Za-z][_A-Za-z0-9]*(?:\.[_A-Za-z][_A-Za-z0-9]*)*)"
)
_MODULEMAP_ALIAS_RE = re.compile(
    r"=\s*([_A-Za-z][_A-Za-z0-9]*)"
)
_SWIFT_EXPORTED_IMPORT_RE = re.compile(
    r"@_exported\s+import\s+(?:(?:class|enum|func|let|protocol|struct|typealias|var)\s+)?"
    r"([A-Za-z_][A-Za-z0-9_]*)"
)
_OBJC_IMPORT_RE = re.compile(
    r"""(?:@import\s+([A-Za-z_][A-Za-z0-9_]*)|#\s*(?:import|include)\s*<([A-Za-z_][A-Za-z0-9_]*)/)"""
)
CONTROL_RE = re.compile(r"[\x00-\x1f\x7f]")
SHA256_RE = re.compile(r"^[0-9a-f]{64}$")
EXTERNAL_EVIDENCE_LOCK = "full/framework-fanout/external-evidence-sources.json"
HERMETIC_PATH = "/usr/bin:/bin:/usr/sbin:/sbin"
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


class SeedError(RuntimeError):
    """A fail-closed input, SDK, or generation error."""


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


def strict_json_load(path: Path, *, label: str) -> Any:
    """Parse generated compiler JSON without accepting lossy extensions."""

    def reject_pairs(pairs: list[tuple[str, Any]]) -> dict[str, Any]:
        result: dict[str, Any] = {}
        for key, value in pairs:
            if key in result:
                raise SeedError(f"{label} contains duplicate JSON key {key!r}")
            result[key] = value
        return result

    def reject_number(token: str) -> Any:
        raise SeedError(f"{label} contains forbidden JSON number {token!r}")

    try:
        return json.loads(
            path.read_text(encoding="utf-8"),
            object_pairs_hook=reject_pairs,
            parse_float=reject_number,
            parse_constant=reject_number,
        )
    except SeedError:
        raise
    except (OSError, UnicodeError, json.JSONDecodeError) as error:
        raise SeedError(f"invalid {label}: {error}") from error


def canonical_json_bytes(value: Any, *, label: str) -> bytes:
    """Return the schema-v2 canonical payload after validating its JSON domain."""

    def validate(item: Any) -> None:
        if item is None or type(item) in (bool, int):
            return
        if isinstance(item, str):
            try:
                item.encode("utf-8")
            except UnicodeEncodeError as error:
                raise SeedError(f"{label} contains an unpaired Unicode surrogate") from error
            return
        if isinstance(item, list):
            for child in item:
                validate(child)
            return
        if isinstance(item, dict):
            for key, child in item.items():
                if not isinstance(key, str):
                    raise SeedError(f"{label} contains a non-string object key")
                validate(key)
                validate(child)
            return
        raise SeedError(f"{label} contains unsupported JSON value {type(item).__name__}")

    validate(value)
    try:
        return json.dumps(
            value,
            ensure_ascii=False,
            sort_keys=True,
            separators=(",", ":"),
            allow_nan=False,
        ).encode("utf-8")
    except (TypeError, ValueError, UnicodeEncodeError) as error:
        raise SeedError(f"cannot canonicalize {label}: {error}") from error


def semantic_multiset_sha256(domain: bytes, payloads: Sequence[bytes]) -> str:
    if len(payloads) >= 1 << 64:
        raise SeedError("semantic multiset has too many payloads")
    digest = hashlib.sha256()
    digest.update(domain)
    digest.update(struct.pack(">Q", len(payloads)))
    for payload in sorted(payloads):
        if len(payload) >= 1 << 64:
            raise SeedError("semantic multiset payload is too large")
        digest.update(struct.pack(">Q", len(payload)))
        digest.update(payload)
    return digest.hexdigest()


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
        raise SeedError("module does not produce a load-smoke marker")
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


def publish_directory_exclusive(source: Path, destination: Path) -> None:
    """Atomically publish a directory on macOS without replacing any target."""

    if sys.platform != "darwin":
        raise SeedError("exclusive framework seed publication requires macOS")
    libc = ctypes.CDLL(None, use_errno=True)
    renameatx = libc.renameatx_np
    renameatx.argtypes = [
        ctypes.c_int,
        ctypes.c_char_p,
        ctypes.c_int,
        ctypes.c_char_p,
        ctypes.c_uint,
    ]
    renameatx.restype = ctypes.c_int
    at_fdcwd = -2
    rename_excl = 0x00000004
    result = renameatx(
        at_fdcwd,
        os.fsencode(source),
        at_fdcwd,
        os.fsencode(destination),
        rename_excl,
    )
    if result == 0:
        return
    error_number = ctypes.get_errno()
    if error_number in {errno.EEXIST, errno.ENOTEMPTY}:
        raise SeedError(
            f"refusing to replace existing framework seed: {destination}"
        )
    raise SeedError(
        f"cannot atomically publish framework seed {destination}: "
        f"{os.strerror(error_number)}"
    )


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


def classify_sdk_input(
    path: Path, walk_root: Path, *, allow_loose_headers: bool = False
) -> str | None:
    try:
        parts = path.relative_to(walk_root).parts
    except ValueError:
        parts = path.parts
    if "PrivateHeaders" in parts:
        return None
    if "Headers" in parts:
        return "header"
    if allow_loose_headers and path.suffix == ".h":
        return "header"
    if path.name.endswith("modulemap"):
        return "modulemap"
    if path.name.endswith(".swiftinterface"):
        return "swiftinterface"
    if path.suffix == ".tbd":
        return "tbd"
    return None


def _sdk_input_records(
    selected: dict[str, tuple[str, Path]], sdk_root: Path, module: str
) -> tuple[list[dict[str, Any]], list[Path]]:
    if not selected:
        raise SeedError(f"no public SDK inputs found for {module}")
    records: list[dict[str, Any]] = []
    tbd_paths: dict[str, Path] = {}
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
        if category == "tbd":
            tbd_paths[sdk_relative] = path
    return records, [tbd_paths[key] for key in sorted(tbd_paths)]


def collect_sdk_inputs(
    framework_root: Path,
    sdk_root: Path,
    module: str,
    *,
    allow_loose_headers: bool = False,
) -> tuple[list[dict[str, Any]], list[Path]]:
    selected: dict[str, tuple[str, Path]] = {}
    logical_binary = framework_root / module
    for path in logical_sdk_walk(framework_root, sdk_root):
        category = classify_sdk_input(
            path, framework_root, allow_loose_headers=allow_loose_headers
        )
        if path == logical_binary and looks_like_tbd(path):
            category = "tbd"
        if category is None:
            continue
        sdk_relative = path.relative_to(sdk_root).as_posix()
        if sdk_relative in selected:
            raise SeedError(f"duplicate logical SDK input: {sdk_relative}")
        selected[sdk_relative] = (category, path)
    return _sdk_input_records(selected, sdk_root, module)


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


@dataclass(frozen=True)
class ModuleLocation:
    """Resolved public SDK module location and extractor path."""

    kind: str
    sdk_relative_path: str
    reason: str
    input_root: Path
    module_map: Path | None

    def record(self) -> dict[str, str]:
        return {
            "kind": self.kind,
            "sdkRelativePath": self.sdk_relative_path,
            "reason": self.reason,
        }


def _require_inside_sdk(path: Path, sdk_root: Path) -> Path:
    try:
        real = path.resolve(strict=True)
        sdk_real = sdk_root.resolve(strict=True)
    except OSError as error:
        raise SeedError(f"cannot resolve SDK path {path}: {error}") from error
    if not within(real, sdk_real):
        raise SeedError(f"SDK path escapes SDK root: {path}")
    return path


def _existing_sdk_path(sdk_root: Path, *parts: str) -> Path | None:
    path = sdk_root.joinpath(*parts)
    if not path.exists():
        return None
    return _require_inside_sdk(path, sdk_root)


def _sdk_relative(path: Path, sdk_root: Path) -> str:
    return path.relative_to(sdk_root).as_posix()


def _framework_has_swift_artifacts(
    framework_root: Path, sdk_root: Path, module: str
) -> bool:
    modules_dir = framework_root / "Modules"
    swiftmodule = modules_dir / f"{module}.swiftmodule"
    if swiftmodule.exists():
        _require_inside_sdk(swiftmodule, sdk_root)
        return True
    if not modules_dir.is_dir():
        return False
    _require_inside_sdk(modules_dir, sdk_root)
    for path in logical_sdk_walk(modules_dir, sdk_root):
        if path.name.endswith(".swiftinterface") or path.name.endswith(".swiftmodule"):
            return True
    return False


def _framework_module_map(framework_root: Path, sdk_root: Path) -> Path | None:
    for candidate in (
        framework_root / "Modules" / "module.modulemap",
        framework_root / "Modules" / "module.map",
    ):
        if candidate.is_file():
            return _require_inside_sdk(candidate, sdk_root)
    return None


def _strip_modulemap_comments(text: str) -> str:
    output: list[str] = []
    index = 0
    length = len(text)
    while index < length:
        if text.startswith("//", index):
            newline = text.find("\n", index)
            if newline < 0:
                break
            output.append("\n")
            index = newline + 1
            continue
        if text.startswith("/*", index):
            end = text.find("*/", index + 2)
            if end < 0:
                raise SeedError("unterminated module map comment")
            output.append(" ")
            index = end + 2
            continue
        char = text[index]
        if char == '"':
            index += 1
            output.append('"')
            while index < length:
                current = text[index]
                output.append(current)
                index += 1
                if current == "\\" and index < length:
                    output.append(text[index])
                    index += 1
                    continue
                if current == '"':
                    break
            else:
                raise SeedError("unterminated module map string")
            continue
        output.append(char)
        index += 1
    return "".join(output)


def _quoted_modulemap_path(token: str) -> str:
    if len(token) >= 2 and token[0] == '"' and token[-1] == '"':
        return token[1:-1].replace("\\\\", "\\").replace('\\"', '"')
    if len(token) >= 2 and token[0] == "<" and token[-1] == ">":
        return token[1:-1]
    raise SeedError(f"invalid module map path token: {token!r}")


def _matching_brace_end(text: str, open_index: int) -> int:
    if open_index >= len(text) or text[open_index] != "{":
        raise SeedError("module map body is not a brace group")
    depth = 0
    index = open_index
    length = len(text)
    while index < length:
        char = text[index]
        if char == '"':
            index += 1
            while index < length:
                current = text[index]
                index += 1
                if current == "\\":
                    index += 1
                    continue
                if current == '"':
                    break
            else:
                raise SeedError("unterminated module map string")
            continue
        if char == "{":
            depth += 1
        elif char == "}":
            depth -= 1
            if depth == 0:
                return index
        index += 1
    raise SeedError("unterminated module map body")


def _iter_modulemap_decls(text: str) -> Iterator[tuple[str, str | None, str | None]]:
    """Yield (module_name, body_or_none, extern_or_alias_target)."""

    stripped = _strip_modulemap_comments(text)
    search_from = 0
    while True:
        match = _MODULEMAP_DECL_RE.search(stripped, search_from)
        if match is None:
            return
        name = match.group("name")
        cursor = match.end()
        while cursor < len(stripped) and stripped[cursor] in " \t\r\n":
            cursor += 1
        while cursor < len(stripped) and stripped[cursor] == "[":
            close = stripped.find("]", cursor)
            if close < 0:
                raise SeedError("unterminated module map attribute")
            cursor = close + 1
            while cursor < len(stripped) and stripped[cursor] in " \t\r\n":
                cursor += 1
        if match.group("extern"):
            if cursor >= len(stripped) or stripped[cursor] != '"':
                raise SeedError(f"extern module {name} is missing a module map path")
            end = cursor + 1
            while end < len(stripped) and stripped[end] != '"':
                if stripped[end] == "\\":
                    end += 2
                    continue
                end += 1
            if end >= len(stripped):
                raise SeedError("unterminated extern module map path")
            yield name, None, _quoted_modulemap_path(stripped[cursor : end + 1])
            search_from = end + 1
            continue
        if cursor < len(stripped) and stripped[cursor] == "=":
            alias = _MODULEMAP_ALIAS_RE.match(stripped, cursor)
            if alias is None:
                raise SeedError(f"module {name} has an invalid alias")
            yield name, None, alias.group(1)
            search_from = alias.end()
            continue
        if cursor >= len(stripped) or stripped[cursor] != "{":
            search_from = match.end()
            continue
        close = _matching_brace_end(stripped, cursor)
        yield name, stripped[cursor + 1 : close], None
        search_from = close + 1


def _find_named_module_in_map(
    text: str, module: str
) -> tuple[str | None, str | None]:
    """Return (body, alias_or_extern_target) for the first named module."""

    for name, body, target in _iter_modulemap_decls(text):
        if name == module:
            return body, target
        if body:
            nested_body, nested_target = _find_named_module_in_map(body, module)
            if nested_body is not None or nested_target is not None:
                return nested_body, nested_target
    return None, None


def module_map_declares(text: str, module: str) -> bool:
    body, target = _find_named_module_in_map(text, module)
    return body is not None or target is not None


def _read_sdk_text(path: Path, *, label: str) -> str:
    try:
        return path.read_text(encoding="utf-8")
    except (OSError, UnicodeError) as error:
        raise SeedError(f"cannot read {label}: {error}") from error


def _resolve_clang_module_map(
    map_path: Path, sdk_root: Path, module: str, *, seen: frozenset[Path]
) -> tuple[Path, str | None, str | None]:
    real = map_path.resolve(strict=True)
    if real in seen:
        raise SeedError(f"cyclic Clang module map redirect for {module}")
    text = _read_sdk_text(map_path, label=f"module map {map_path.name}")
    body, target = _find_named_module_in_map(text, module)
    if body is None and target is None:
        raise SeedError(f"module map does not declare {module}: {map_path}")
    if body is not None:
        return map_path, body, None
    assert target is not None
    if MODULE_RE.fullmatch(target):
        return map_path, None, target
    redirected = (map_path.parent / target).resolve(strict=False)
    if not redirected.is_file():
        raise SeedError(f"extern module map for {module} is missing: {target}")
    _require_inside_sdk(redirected, sdk_root)
    return _resolve_clang_module_map(
        redirected, sdk_root, module, seen=seen | {real}
    )


def _collect_loose_headers(directory: Path, sdk_root: Path) -> list[Path]:
    headers: list[Path] = []
    for path in logical_sdk_walk(directory, sdk_root):
        if path.suffix == ".h" and "PrivateHeaders" not in path.parts:
            headers.append(path)
    return headers


def _clang_module_headers(
    map_path: Path, body: str, sdk_root: Path
) -> list[Path]:
    headers: list[Path] = []
    search_from = 0
    while True:
        next_module = _MODULEMAP_DECL_RE.search(body, search_from)
        next_header = _MODULEMAP_HEADER_RE.search(body, search_from)
        next_umbrella = _MODULEMAP_UMBRELLA_DIR_RE.search(body, search_from)
        candidates: list[tuple[int, str, re.Match[str]]] = []
        if next_module is not None:
            candidates.append((next_module.start(), "module", next_module))
        if next_header is not None:
            candidates.append((next_header.start(), "header", next_header))
        if (
            next_umbrella is not None
            and "header"
            not in body[max(0, next_umbrella.start() - 8) : next_umbrella.start()]
        ):
            candidates.append((next_umbrella.start(), "umbrella", next_umbrella))
        if not candidates:
            break
        candidates.sort(key=lambda item: item[0])
        kind = candidates[0][1]
        match = candidates[0][2]
        if kind == "module":
            name = match.group("name")
            cursor = match.end()
            while cursor < len(body) and body[cursor] in " \t\r\n":
                cursor += 1
            while cursor < len(body) and body[cursor] == "[":
                close = body.find("]", cursor)
                if close < 0:
                    break
                cursor = close + 1
                while cursor < len(body) and body[cursor] in " \t\r\n":
                    cursor += 1
            if cursor < len(body) and body[cursor] == "{":
                close = _matching_brace_end(body, cursor)
                if name != "*":
                    headers.extend(
                        _clang_module_headers(
                            map_path, body[cursor + 1 : close], sdk_root
                        )
                    )
                search_from = close + 1
            else:
                search_from = match.end()
            continue
        if kind == "header" and not match.group(0).startswith("exclude"):
            relative = _quoted_modulemap_path(match.group(1))
            header = map_path.parent / relative
            if header.is_file():
                headers.append(_require_inside_sdk(header, sdk_root))
        elif kind == "umbrella":
            relative = _quoted_modulemap_path(match.group(1))
            directory = map_path.parent / relative
            if directory.is_dir():
                _require_inside_sdk(directory, sdk_root)
                headers.extend(_collect_loose_headers(directory, sdk_root))
        search_from = match.end()
    return headers


def _module_map_export_names(body: str, module: str) -> set[str]:
    names: set[str] = set()
    for match in _MODULEMAP_EXPORT_RE.finditer(body):
        value = match.group(1)
        if value == "*":
            continue
        exported = value.split(".", 1)[0]
        if exported != module and MODULE_RE.fullmatch(exported):
            names.add(exported)
    return names


def locate_sdk_module(sdk_root: Path, module: str) -> ModuleLocation:
    """Locate a public iPhoneOS framework, Swift module, or Clang module."""

    if not MODULE_RE.fullmatch(module):
        raise SeedError(f"invalid Swift module identifier: {module!r}")
    _require_inside_sdk(sdk_root, sdk_root)

    framework_root = _existing_sdk_path(
        sdk_root, "System", "Library", "Frameworks", f"{module}.framework"
    )
    if framework_root is not None and framework_root.is_dir():
        relative = _sdk_relative(framework_root, sdk_root)
        module_map = _framework_module_map(framework_root, sdk_root)
        if _framework_has_swift_artifacts(framework_root, sdk_root, module):
            return ModuleLocation(
                kind="framework",
                sdk_relative_path=relative,
                reason=(
                    "public iPhoneOS framework bundle is present at "
                    f"{relative}"
                ),
                input_root=framework_root,
                module_map=module_map,
            )
        if module_map is None:
            raise SeedError(
                f"public iPhoneOS framework {module}.framework has no Swift "
                "module and no Clang module map"
            )
        return ModuleLocation(
            kind="framework-clang-module",
            sdk_relative_path=relative,
            reason=(
                "public iPhoneOS framework bundle is present at "
                f"{relative} but has no Swift module; using Clang module map at "
                f"{_sdk_relative(module_map, sdk_root)}"
            ),
            input_root=framework_root,
            module_map=module_map,
        )

    swiftmodule = _existing_sdk_path(
        sdk_root, "usr", "lib", "swift", f"{module}.swiftmodule"
    )
    if swiftmodule is not None:
        relative = _sdk_relative(swiftmodule, sdk_root)
        return ModuleLocation(
            kind="swift-module",
            sdk_relative_path=relative,
            reason=(
                "public iPhoneOS framework is absent; located Swift module at "
                f"{relative}"
            ),
            input_root=swiftmodule,
            module_map=None,
        )

    clang_dir_map = _existing_sdk_path(
        sdk_root, "usr", "include", module, "module.modulemap"
    )
    if clang_dir_map is not None and clang_dir_map.is_file():
        relative = _sdk_relative(clang_dir_map, sdk_root)
        text = _read_sdk_text(
            clang_dir_map, label=f"Clang module map {relative}"
        )
        if not module_map_declares(text, module):
            raise SeedError(
                f"module map at {relative} does not declare {module}"
            )
        return ModuleLocation(
            kind="clang-module",
            sdk_relative_path=relative,
            reason=(
                "public iPhoneOS framework is absent; located Clang module map "
                f"at {relative}"
            ),
            input_root=clang_dir_map.parent,
            module_map=clang_dir_map,
        )

    top_level_map = _existing_sdk_path(
        sdk_root, "usr", "include", "module.modulemap"
    )
    if top_level_map is not None and top_level_map.is_file():
        text = _read_sdk_text(top_level_map, label="usr/include/module.modulemap")
        if module_map_declares(text, module):
            resolved_map, _body, alias = _resolve_clang_module_map(
                top_level_map, sdk_root, module, seen=frozenset()
            )
            relative = _sdk_relative(resolved_map, sdk_root)
            reason = (
                "public iPhoneOS framework is absent; located Clang submodule "
                f"{module} in usr/include/module.modulemap"
            )
            if resolved_map != top_level_map:
                reason += f" (redirected to {relative})"
            if alias is not None:
                reason += f"; module aliases {alias}"
            return ModuleLocation(
                kind="clang-submodule",
                sdk_relative_path=relative,
                reason=reason,
                input_root=resolved_map.parent,
                module_map=resolved_map,
            )

    raise SeedError(
        "public iPhoneOS module is missing: no "
        f"{module}.framework, usr/lib/swift/{module}.swiftmodule, "
        f"usr/include/{module}/module.modulemap, or {module} submodule in "
        "usr/include/module.modulemap"
    )


def clang_include_directories(location: ModuleLocation) -> list[Path]:
    directories: list[Path] = []
    if location.kind == "clang-module":
        directories.append(location.input_root)
        parent = location.input_root.parent
        if parent.name == "include":
            directories.append(parent)
    elif location.kind == "clang-submodule" and location.module_map is not None:
        directories.append(location.module_map.parent)
    elif location.kind == "framework-clang-module":
        headers = location.input_root / "Headers"
        if headers.is_dir():
            directories.append(headers)
    unique: list[Path] = []
    seen: set[Path] = set()
    for directory in directories:
        if directory not in seen:
            seen.add(directory)
            unique.append(directory)
    return unique


def xcc_passthrough(*clang_args: str) -> list[str]:
    """Spell Clang importer flags as argv pairs ``-Xcc``, ``<clang-arg>``.

    ``swift-symbolgraph-extract`` only accepts options in the
    SwiftSymbolGraphExtract group.  ``-fmodule-map-file`` is a Clang flag, so
    it must be the Separate value of ``-Xcc``, never a top-level extractor
    argument.
    """

    argv: list[str] = []
    for clang_arg in clang_args:
        if not clang_arg or clang_arg.startswith("-Xcc"):
            raise SeedError(f"invalid Clang importer passthrough: {clang_arg!r}")
        argv.extend(("-Xcc", clang_arg))
    return argv


def reject_bare_clang_importer_flags(argv: Sequence[str], *, tool: str) -> None:
    for index, argument in enumerate(argv):
        if argument.startswith("-fmodule-map-file") and (
            index == 0 or argv[index - 1] != "-Xcc"
        ):
            raise SeedError(
                f"{tool} received Clang flag {argument!r} without a preceding -Xcc"
            )


def extractor_clang_module_args(location: ModuleLocation) -> list[str]:
    if location.kind not in {
        "clang-module",
        "clang-submodule",
        "framework-clang-module",
    }:
        return []
    if location.module_map is None:
        raise SeedError(
            f"Clang module location is missing a module map: {location.sdk_relative_path}"
        )
    include_dirs = clang_include_directories(location)
    argv: list[str] = []
    for directory in include_dirs:
        argv.extend(("-I", str(directory)))
    argv.extend(xcc_passthrough(f"-fmodule-map-file={location.module_map}"))
    argv.extend(xcc_passthrough(*(f"-I{directory}" for directory in include_dirs)))
    reject_bare_clang_importer_flags(argv, tool="swift-symbolgraph-extract")
    return argv


def digester_clang_module_args(location: ModuleLocation) -> list[str]:
    """Xcode 26.1's api-digester option table does not accept ``-Xcc``."""

    if location.kind not in {
        "clang-module",
        "clang-submodule",
        "framework-clang-module",
    }:
        return []
    argv: list[str] = []
    for directory in clang_include_directories(location):
        argv.extend(("-I", str(directory)))
    return argv


def symbol_graph_extract_command(
    extractor: Path | str,
    module: str,
    sdk_root: Path,
    output_dir: Path,
    module_cache: Path,
    extra_frontend_args: Sequence[str] = (),
) -> list[str]:
    argv = [
        str(extractor),
        "-module-name",
        module,
        "-target",
        TARGET,
        "-sdk",
        str(sdk_root),
        *extra_frontend_args,
        "-minimum-access-level",
        "public",
        "-module-cache-path",
        str(module_cache),
        "-output-dir",
        str(output_dir),
    ]
    reject_bare_clang_importer_flags(argv, tool="swift-symbolgraph-extract")
    return argv


def api_digester_command(
    digester: Path | str,
    module: str,
    sdk_root: Path,
    output_path: Path,
    extra_frontend_args: Sequence[str] = (),
) -> list[str]:
    argv = [
        str(digester),
        "-dump-sdk",
        "-module",
        module,
        "-o",
        str(output_path),
        "-target",
        TARGET,
        "-sdk",
        str(sdk_root),
        *extra_frontend_args,
        "-avoid-location",
        "-avoid-tool-args",
        "-abort-on-module-fail",
    ]
    reject_bare_clang_importer_flags(argv, tool="swift-api-digester")
    return argv


def collect_located_sdk_inputs(
    location: ModuleLocation, sdk_root: Path, module: str
) -> tuple[list[dict[str, Any]], list[Path]]:
    if location.kind in {"framework", "framework-clang-module"}:
        return collect_sdk_inputs(location.input_root, sdk_root, module)
    if location.kind == "swift-module":
        root = location.input_root
        if root.is_dir():
            return collect_sdk_inputs(
                root, sdk_root, module, allow_loose_headers=True
            )
        selected: dict[str, tuple[str, Path]] = {}
        category = classify_sdk_input(root, root.parent, allow_loose_headers=True)
        if category is None and root.name.endswith(".swiftinterface"):
            category = "swiftinterface"
        if category is None:
            raise SeedError(f"no public SDK inputs found for {module}")
        selected[_sdk_relative(root, sdk_root)] = (category, root)
        return _sdk_input_records(selected, sdk_root, module)
    if location.kind == "clang-module":
        return collect_sdk_inputs(
            location.input_root, sdk_root, module, allow_loose_headers=True
        )
    if location.kind != "clang-submodule" or location.module_map is None:
        raise SeedError(f"unsupported module location kind: {location.kind}")
    selected = {}
    map_path = location.module_map
    selected[_sdk_relative(map_path, sdk_root)] = ("modulemap", map_path)
    _resolved, body, _alias = _resolve_clang_module_map(
        map_path, sdk_root, module, seen=frozenset()
    )
    if body:
        for header in _clang_module_headers(map_path, body, sdk_root):
            relative = _sdk_relative(header, sdk_root)
            selected.setdefault(relative, ("header", header))
    return _sdk_input_records(selected, sdk_root, module)


def _iter_location_text_files(
    location: ModuleLocation, sdk_root: Path
) -> Iterator[Path]:
    roots: list[Path] = []
    if location.module_map is not None and location.module_map.is_file():
        yield location.module_map
    if location.input_root.is_file():
        yield location.input_root
        return
    if location.input_root.is_dir():
        roots.append(location.input_root)
    seen: set[Path] = set()
    for root in roots:
        for path in logical_sdk_walk(root, sdk_root):
            resolved = path.resolve(strict=True)
            if resolved in seen:
                continue
            seen.add(resolved)
            if path.suffix in {".h", ".swiftinterface"} or path.name.endswith(
                "modulemap"
            ):
                yield path


def _imported_module_names_from_header(text: str) -> set[str]:
    names: set[str] = set()
    for match in _OBJC_IMPORT_RE.finditer(text):
        imported = match.group(1) or match.group(2)
        if imported:
            names.add(imported)
    return names


def _strip_c_comments_and_strings(text: str) -> str:
    output: list[str] = []
    index = 0
    length = len(text)
    while index < length:
        if text.startswith("//", index):
            newline = text.find("\n", index)
            if newline < 0:
                break
            output.append("\n")
            index = newline + 1
            continue
        if text.startswith("/*", index):
            end = text.find("*/", index + 2)
            if end < 0:
                break
            output.append(" ")
            index = end + 2
            continue
        char = text[index]
        if char in {'"', "'"}:
            quote = char
            index += 1
            while index < length:
                current = text[index]
                index += 1
                if current == "\\":
                    index += 1
                    continue
                if current == quote:
                    break
            output.append(" ")
            continue
        output.append(char)
        index += 1
    return "".join(output)


def _header_is_import_only(text: str) -> bool:
    for raw_line in _strip_c_comments_and_strings(text).splitlines():
        line = raw_line.strip()
        if not line:
            continue
        if line.startswith("#"):
            continue
        if line.startswith("@import "):
            continue
        if line in {"{", "}", "@end"}:
            continue
        return False
    return True


def _swiftinterface_exports(text: str) -> tuple[set[str], bool]:
    exported: set[str] = set()
    has_other_api = False
    for raw_line in text.splitlines():
        stripped = raw_line.strip()
        if not stripped or stripped.startswith("//") or stripped.startswith("#"):
            continue
        match = _SWIFT_EXPORTED_IMPORT_RE.search(stripped)
        if match:
            exported.add(match.group(1))
            continue
        if stripped.startswith("import "):
            continue
        if stripped.startswith("@_"):
            continue
        has_other_api = True
    return exported, has_other_api


def candidate_reexport_modules(
    module: str, location: ModuleLocation, sdk_root: Path
) -> set[str]:
    names: set[str] = set()
    if location.module_map is not None:
        text = _read_sdk_text(location.module_map, label="module map")
        body, target = _find_named_module_in_map(text, module)
        if target and MODULE_RE.fullmatch(target):
            names.add(target)
        if body:
            names |= _module_map_export_names(body, module)
    for path in _iter_location_text_files(location, sdk_root):
        if path.name.endswith("modulemap"):
            continue
        text = _read_sdk_text(path, label=path.name)
        if path.name.endswith(".swiftinterface"):
            exported, _has_other = _swiftinterface_exports(text)
            names |= exported
            continue
        if path.suffix == ".h":
            names |= _imported_module_names_from_header(text)
    names.discard(module)
    names -= IGNORED_REEXPORT_MODULES
    return names


def surface_looks_like_pure_reexport(
    module: str, location: ModuleLocation, sdk_root: Path
) -> bool:
    saw_surface = False
    if location.module_map is not None:
        text = _read_sdk_text(location.module_map, label="module map")
        _body, target = _find_named_module_in_map(text, module)
        if target and MODULE_RE.fullmatch(target) and target != module:
            return True
    for path in _iter_location_text_files(location, sdk_root):
        if path.name.endswith("modulemap"):
            continue
        text = _read_sdk_text(path, label=path.name)
        if path.name.endswith(".swiftinterface"):
            saw_surface = True
            _exported, has_other = _swiftinterface_exports(text)
            if has_other:
                return False
            continue
        if path.suffix == ".h":
            saw_surface = True
            if not _header_is_import_only(text):
                return False
    return saw_surface


def detect_umbrella_reexport(
    module: str,
    location: ModuleLocation,
    sdk_root: Path,
    *,
    require_pure: bool = False,
) -> str | None:
    candidates = candidate_reexport_modules(module, location, sdk_root)
    if len(candidates) != 1:
        return None
    if require_pure and not surface_looks_like_pure_reexport(
        module, location, sdk_root
    ):
        return None
    return next(iter(candidates))


def refuse_empty_or_umbrella(
    module: str, symbol_count: int, reexport: str | None
) -> None:
    if symbol_count > 0:
        return
    if reexport:
        raise SeedError(
            f"umbrella re-export of {reexport}; seed {reexport} instead"
        )
    raise SeedError(f"public surface is empty (0 symbols) for {module}")


def generate_symbol_graphs(
    module: str,
    sdk_root: Path,
    temp_root: Path,
    reference_root: Path,
    clean_env: dict[str, str],
    extractor: Path,
    extra_frontend_args: Sequence[str] = (),
) -> tuple[dict[str, Any], dict[str, dict[str, Any]]]:
    raw_root = temp_root / "symbol-graphs"
    raw_root.mkdir()
    command = symbol_graph_extract_command(
        extractor,
        module,
        sdk_root,
        raw_root,
        temp_root / "swift-module-cache",
        extra_frontend_args,
    )
    run_checked(command, env=clean_env)
    graph_files = sorted(raw_root.glob("*.symbols.json"), key=lambda item: item.name)
    if not graph_files:
        raise SeedError(f"symbol graph extraction produced no graph for {module}")

    destination_root = reference_root / "symbol-graphs"
    destination_root.mkdir()
    graph_records: list[dict[str, Any]] = []
    occurrences_by_precise: dict[str, list[dict[str, Any]]] = {}
    symbol_payloads: list[bytes] = []
    relationship_payloads: list[bytes] = []
    relationship_count = 0
    raw_symbol_count = 0
    for source in graph_files:
        if source.is_symlink() or not source.is_file():
            raise SeedError(f"unexpected symbol graph output: {source}")
        graph = strict_json_load(source, label=f"symbol graph {source.name}")
        if not isinstance(graph, dict):
            raise SeedError(f"symbol graph root is not an object: {source.name}")
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
        if not isinstance(graph_module_name, str) or not graph_module_name:
            raise SeedError(f"symbol graph lacks a module name: {source.name}")
        relative_graph_path = destination.relative_to(reference_root.parent).as_posix()
        if graph_module_name == module and source.name == f"{module}.symbols.json":
            ownership_tier = 0
        elif graph_module_name == module:
            ownership_tier = 1
        else:
            ownership_tier = 2
        relationship_count += len(relationships)
        raw_symbol_count += len(symbols)
        for relationship_index, relationship in enumerate(relationships):
            if not isinstance(relationship, dict):
                raise SeedError(
                    f"non-object relationship in {source.name}[{relationship_index}]"
                )
            relationship_payloads.append(
                canonical_json_bytes(
                    relationship,
                    label=f"relationship {source.name}[{relationship_index}]",
                )
            )
        for symbol_index, symbol in enumerate(symbols):
            if not isinstance(symbol, dict):
                raise SeedError(f"non-object symbol in {source.name}")
            identifier = symbol.get("identifier")
            precise = identifier.get("precise") if isinstance(identifier, dict) else None
            if not isinstance(precise, str) or not precise or CONTROL_RE.search(precise):
                raise SeedError(f"symbol without a safe precise identifier in {source.name}")
            canonical_payload = canonical_json_bytes(
                symbol, label=f"symbol {source.name}[{symbol_index}]"
            )
            symbol_payloads.append(canonical_payload)
            selection_key = (
                ownership_tier,
                relative_graph_path.encode("utf-8"),
                canonical_payload,
            )
            occurrences_by_precise.setdefault(precise, []).append(
                {
                    "selectionKey": selection_key,
                    "payload": canonical_payload,
                    "symbol": symbol,
                    "graphPath": relative_graph_path,
                    "ownershipTier": ownership_tier,
                }
            )

    symbols_by_precise: dict[str, dict[str, Any]] = {}
    conflicting_duplicate_count = 0
    conflict_rows: list[tuple[tuple[Any, ...], list[str]]] = []
    payload_by_digest: dict[str, bytes] = {}
    for precise, occurrences in occurrences_by_precise.items():
        canonical = min(occurrences, key=lambda item: item["selectionKey"])
        symbols_by_precise[precise] = canonical["symbol"]
        distinct_payloads = {item["payload"] for item in occurrences}
        if len(distinct_payloads) <= 1:
            continue
        conflicting_duplicate_count += 1
        grouped: dict[tuple[bytes, str, int], list[dict[str, Any]]] = {}
        for occurrence in occurrences:
            group_key = (
                occurrence["payload"],
                occurrence["graphPath"],
                occurrence["ownershipTier"],
            )
            grouped.setdefault(group_key, []).append(occurrence)
        for (payload, graph_path, ownership_tier), group in grouped.items():
            payload_digest = hashlib.sha256(payload).hexdigest()
            previous = payload_by_digest.setdefault(payload_digest, payload)
            if previous != payload:
                raise SeedError("SHA-256 collision between distinct symbol payloads")
            surface = symbol_surface_fields(precise, group[0]["symbol"])
            selected = (
                payload == canonical["payload"]
                and graph_path == canonical["graphPath"]
                and ownership_tier == canonical["ownershipTier"]
            )
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

    conflict_lines = ["\t".join(CONFLICT_HEADER)]
    conflict_lines.extend("\t".join(row) for _key, row in sorted(conflict_rows))
    write_text(
        reference_root / "symbol-conflicts.tsv",
        "\n".join(conflict_lines) + "\n",
    )

    manifest = {
        "schema": SYMBOL_GRAPH_SCHEMA,
        "module": module,
        "target": TARGET,
        "minimumAccessLevel": "public",
        "files": graph_records,
        "symbolCount": len(symbols_by_precise),
        "relationshipCount": relationship_count,
        "duplicateOccurrenceCount": raw_symbol_count - len(symbols_by_precise),
        "duplicateRelationshipOccurrenceCount": (
            relationship_count - len(set(relationship_payloads))
        ),
        "conflictingDuplicateIdentifierCount": conflicting_duplicate_count,
        "canonicalSurfacePolicy": CANONICAL_SURFACE_POLICY,
        "semanticHashPolicy": SEMANTIC_HASH_POLICY,
        "symbolMultisetSHA256": semantic_multiset_sha256(
            SYMBOL_MULTISET_DOMAIN, symbol_payloads
        ),
        "relationshipMultisetSHA256": semantic_multiset_sha256(
            RELATIONSHIP_MULTISET_DOMAIN, relationship_payloads
        ),
        "conflictLedger": "reference/symbol-conflicts.tsv",
    }
    return manifest, symbols_by_precise


def _json_pointer_component(value: str) -> str:
    return value.replace("~", "~0").replace("/", "~1")


def validate_api_declarations(
    document: Any, module: str
) -> tuple[dict[str, Any], int, list[dict[str, Any]]]:
    if not isinstance(document, dict) or set(document) != {"ABIRoot"}:
        raise SeedError("API-digester output must contain only ABIRoot")
    root = document.get("ABIRoot")
    if (
        not isinstance(root, dict)
        or root.get("kind") != "Root"
        or root.get("name") != module
        or root.get("printedName") != module
        or not isinstance(root.get("children"), list)
    ):
        raise SeedError(f"API-digester root does not describe {module}")
    format_version = root.get("json_format_version")
    if type(format_version) is not int or format_version <= 0:
        raise SeedError("API-digester json_format_version is invalid")

    declarations: list[dict[str, Any]] = []
    node_count = 0

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
                raise SeedError(
                    f"API-digester forbidden provenance field {key!r} at {pointer}"
                )
        kind = value.get("kind")
        if "kind" in value:
            if not isinstance(kind, str) or not kind or CONTROL_RE.search(kind):
                raise SeedError(f"API-digester has an unsafe kind at {pointer}")
            node_count += 1

        child_container_names = container_names
        if "declKind" in value:
            required = ("kind", "declKind", "moduleName", "name", "printedName")
            for key in required:
                candidate = value.get(key)
                if (
                    not isinstance(candidate, str)
                    or not candidate
                    or CONTROL_RE.search(candidate)
                ):
                    raise SeedError(
                        f"API declaration {pointer} has an unsafe {key}"
                    )
            if not MODULE_RE.fullmatch(value["moduleName"]):
                raise SeedError(
                    f"API declaration {pointer} has an invalid module owner"
                )
            usr = value.get("usr")
            if usr is not None and (
                not isinstance(usr, str) or not usr or CONTROL_RE.search(usr)
            ):
                raise SeedError(f"API declaration {pointer} has an unsafe usr")
            static = value.get("static")
            if static is not None and type(static) is not bool:
                raise SeedError(f"API declaration {pointer} has a non-boolean static")
            for key in API_LIST_FIELDS:
                if key in value and not isinstance(value[key], list):
                    raise SeedError(
                        f"API declaration {pointer} field {key} must be a list"
                    )
            attributes = value.get("declAttributes")
            if isinstance(attributes, list) and any(
                not isinstance(attribute, str) or CONTROL_RE.search(attribute)
                for attribute in attributes
            ):
                raise SeedError(
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
            child_pointer = f"{pointer}/{_json_pointer_component(key)}"
            if isinstance(child, list):
                for index, item in enumerate(child):
                    visit(
                        item,
                        f"{child_pointer}/{index}",
                        child_container_names,
                        direct_root_child=(pointer == "/ABIRoot" and key == "children"),
                    )
            elif isinstance(child, dict):
                visit(child, child_pointer, child_container_names)

    visit(root, "/ABIRoot", ())
    if node_count <= 1 or not declarations:
        raise SeedError(f"API-digester output for {module} has no declaration nodes")
    return root, node_count, declarations


def _crosswalk_graph_facts(
    precise: str, symbol: dict[str, Any]
) -> tuple[str, tuple[str, ...]]:
    kind_object = symbol.get("kind")
    kind = kind_object.get("identifier") if isinstance(kind_object, dict) else None
    path_components = symbol.get("pathComponents")
    if not isinstance(kind, str) or not kind or CONTROL_RE.search(kind):
        raise SeedError(f"crosswalk graph kind is invalid for {precise}")
    if not isinstance(path_components, list) or not all(
        isinstance(component, str) and not CONTROL_RE.search(component)
        for component in path_components
    ):
        raise SeedError(f"crosswalk graph path is invalid for {precise}")
    return kind, tuple(path_components)


def _crosswalk_compatible(graph_kind: str, record: dict[str, Any]) -> bool:
    node = record["node"]
    if node.get("declKind") not in GRAPH_KIND_TO_DECL_KINDS.get(
        graph_kind, frozenset()
    ):
        return False
    if graph_kind in TYPE_MEMBER_GRAPH_KINDS and node.get("static") is not True:
        return False
    if graph_kind in INSTANCE_MEMBER_GRAPH_KINDS and node.get("static") is True:
        return False
    return True


def generate_api_crosswalk(
    path: Path,
    module: str,
    symbols_by_precise: dict[str, dict[str, Any]],
    declarations: Sequence[dict[str, Any]],
) -> dict[str, int]:
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

    graph_facts = {
        precise: _crosswalk_graph_facts(precise, symbol)
        for precise, symbol in symbols_by_precise.items()
    }
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
    rows: list[list[str]] = []
    for precise in sorted(symbols_by_precise, key=lambda value: value.encode("utf-8")):
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
            compatible = [
                record
                for record in owned
                if _crosswalk_compatible(graph_kind, record)
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
                if len(candidates) == 1 and graph_import_key_counts[import_key] == 1:
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
        rows.append(
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
    lines = ["\t".join(CROSSWALK_HEADER)]
    lines.extend("\t".join(row) for row in rows)
    write_text(path, "\n".join(lines) + "\n")
    return status_counts


def generate_api_digester(
    module: str,
    sdk_root: Path,
    temp_root: Path,
    reference_root: Path,
    clean_env: dict[str, str],
    digester: Path,
    symbols_by_precise: dict[str, dict[str, Any]],
    extra_frontend_args: Sequence[str] = (),
) -> dict[str, int]:
    """Emit a location-free Swift API-digester tree for declaration identity.

    Symbol graphs are the canonical public-ID census, while the digester tree
    supplies complementary compiler-import facts such as ObjC USRs, base types,
    protocols, attributes, optionality, and ordered enum children.  It remains
    static API evidence and must never be treated as runtime behavior evidence.
    """

    raw_path = temp_root / f"{module}.api-digester.json"
    command = api_digester_command(
        digester,
        module,
        sdk_root,
        raw_path,
        extra_frontend_args,
    )
    run_checked(command, env=clean_env)
    document = strict_json_load(raw_path, label=f"API-digester output for {module}")
    root, node_count, declarations = validate_api_declarations(document, module)
    write_json(reference_root / "api-digester.json", document)
    status_counts = generate_api_crosswalk(
        reference_root / "api-crosswalk.tsv",
        module,
        symbols_by_precise,
        declarations,
    )
    return {
        "formatVersion": root["json_format_version"],
        "nodeCount": node_count,
        "declarationNodeCount": len(declarations),
        "ownedDeclarationNodeCount": sum(
            record["node"].get("moduleName") == module for record in declarations
        ),
        "exactUSRCount": status_counts["exact-usr"],
        "importNameCount": status_counts["import-name"],
        "ambiguousCount": status_counts["ambiguous"],
        "unmatchedCount": status_counts["unmatched"],
    }


def external_evidence_summary(lock_path: Path, module: str) -> dict[str, Any]:
    try:
        lock = json.loads(lock_path.read_text(encoding="utf-8"))
    except (OSError, UnicodeError, json.JSONDecodeError) as error:
        raise SeedError(f"cannot read external evidence lock: {error}") from error
    if (
        not isinstance(lock, dict)
        or set(lock) != {"schema", "policy", "sources"}
        or lock.get("schema") != SCHEMA
        or not valid_external_policy(lock.get("policy"))
        or not isinstance(lock.get("sources"), list)
        or not lock["sources"]
    ):
        raise SeedError("external evidence lock has an unsupported schema")

    resolved_sources: list[dict[str, Any]] = []
    seen_ids: set[str] = set()
    seen_environment_variables: set[str] = set()
    for index, source in enumerate(lock["sources"]):
        if not isinstance(source, dict) or set(source) != EXTERNAL_SOURCE_KEYS:
            raise SeedError(f"external evidence source {index} has the wrong schema")
        source_id = source.get("id")
        environment_variable = source.get("environmentVariable")
        repository = source.get("repository")
        license_path = source.get("licensePath")
        capabilities = source.get("capabilities")
        templates = source.get("sourcePathTemplates")
        license_summary = source.get("licenseSummary")
        if (
            not isinstance(source_id, str)
            or EXTERNAL_SOURCE_ID_RE.fullmatch(source_id) is None
            or source_id in seen_ids
        ):
            raise SeedError(f"external evidence source {index} has an invalid ID")
        if (
            not isinstance(environment_variable, str)
            or EXTERNAL_ENVIRONMENT_RE.fullmatch(environment_variable) is None
            or environment_variable in seen_environment_variables
        ):
            raise SeedError(
                f"external evidence source {index} has an invalid environment variable"
            )
        if (
            not isinstance(repository, str)
            or EXTERNAL_REPOSITORY_RE.fullmatch(repository) is None
        ):
            raise SeedError(
                f"external evidence source {index} has an unapproved repository URL"
            )
        if (
            not isinstance(license_path, str)
            or not license_path
            or CONTROL_RE.search(license_path)
            or "\\" in license_path
            or PurePosixPath(license_path).is_absolute()
            or not PurePosixPath(license_path).parts
            or any(part in {"", ".", ".."} for part in PurePosixPath(license_path).parts)
        ):
            raise SeedError(
                f"external evidence source {index} has an unsafe license path"
            )
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
            raise SeedError(
                f"external evidence source {index} has invalid capabilities"
            )
        if (
            not isinstance(license_summary, str)
            or not license_summary.strip()
            or CONTROL_RE.search(license_summary)
        ):
            raise SeedError(
                f"external evidence source {index} has an invalid license summary"
            )
        if (
            not isinstance(templates, list)
            or not templates
            or len(templates) != len(set(templates))
        ):
            raise SeedError(f"external evidence source {index} has invalid templates")
        for template in templates:
            if not isinstance(template, str) or not template or CONTROL_RE.search(template):
                raise SeedError(
                    f"external evidence source {index} has an invalid path template"
                )
            resolved_template = template.replace("{module}", module).replace(
                "{moduleLower}", module.lower()
            )
            path = PurePosixPath(resolved_template)
            if (
                "{" in resolved_template
                or "}" in resolved_template
                or "\\" in resolved_template
                or path.is_absolute()
                or not path.parts
                or any(part in {"", ".", ".."} for part in path.parts)
            ):
                raise SeedError(
                    f"external evidence source {index} has an unsafe path template"
                )
        commit = source.get("commit")
        license_digest = source.get("licenseSHA256")
        if (
            not isinstance(commit, str)
            or not re.fullmatch(r"[0-9a-f]{40}", commit)
            or not isinstance(license_digest, str)
            or not SHA256_RE.fullmatch(license_digest)
        ):
            raise SeedError(f"external evidence source {index} has invalid pins")
        seen_ids.add(source_id)
        seen_environment_variables.add(environment_variable)
        resolved = dict(source)
        del resolved["sourcePathTemplates"]
        resolved["suggestedSourcePaths"] = [
            template.replace("{module}", module).replace(
                "{moduleLower}", module.lower()
            )
            for template in templates
        ]
        resolved_sources.append(resolved)

    return {
        "schema": SCHEMA,
        "module": module,
        "lock": {
            "path": EXTERNAL_EVIDENCE_LOCK,
            "sha256": sha256_file(lock_path),
        },
        "policy": lock["policy"],
        "sources": resolved_sources,
    }


def declaration_text(symbol: dict[str, Any]) -> str:
    fragments = symbol.get("declarationFragments", [])
    if not isinstance(fragments, list):
        return ""
    spellings: list[str] = []
    for fragment in fragments:
        if isinstance(fragment, dict) and isinstance(fragment.get("spelling"), str):
            spellings.append(fragment["spelling"])
    return "".join(spellings)


def symbol_surface_fields(precise: str, symbol: dict[str, Any]) -> list[str]:
    kind_object = symbol.get("kind")
    kind = kind_object.get("identifier", "") if isinstance(kind_object, dict) else ""
    names = symbol.get("names")
    title = names.get("title", "") if isinstance(names, dict) else ""
    path_components = symbol.get("pathComponents")
    if not isinstance(kind, str) or not kind or CONTROL_RE.search(kind):
        raise SeedError(f"unsafe kind for precise identifier {precise}")
    if not isinstance(title, str):
        title = ""
    if not isinstance(path_components, list) or not all(
        isinstance(component, str) for component in path_components
    ):
        raise SeedError(f"invalid path components for precise identifier {precise}")
    return [
        precise,
        kind,
        tsv_escape(title),
        tsv_escape(".".join(path_components)),
        tsv_escape(declaration_text(symbol)),
    ]


def write_public_surface(
    path: Path, symbols_by_precise: dict[str, dict[str, Any]]
) -> None:
    lines = ["precise\tkind\ttitle\tpath\tdeclaration"]
    for precise in sorted(symbols_by_precise):
        lines.append("\t".join(symbol_surface_fields(precise, symbols_by_precise[precise])))
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


def roadmap_summary(
    roadmap_path: Path, module: str, *, allow_missing: bool = False
) -> dict[str, Any]:
    try:
        roadmap = json.loads(roadmap_path.read_text(encoding="utf-8"))
    except (OSError, UnicodeError, json.JSONDecodeError) as error:
        raise SeedError(f"cannot read framework roadmap: {error}") from error
    if not isinstance(roadmap, dict) or not isinstance(roadmap.get("modules"), list):
        raise SeedError("framework roadmap has an unsupported schema")
    matches = [item for item in roadmap["modules"] if item.get("module") == module]
    if len(matches) > 1:
        raise SeedError(f"framework roadmap must contain exactly one {module} record")
    if not matches:
        if not allow_missing:
            raise SeedError(
                f"framework roadmap must contain exactly one {module} record"
            )
        module_record: Any = {"roadmap": ROADMAP_OPERATOR_OVERRIDE}
    else:
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

`reference/api-digester.json` is a location-free compiler dump from the same
pinned Xcode SDK. Reconcile it with the symbol graph before writing declarations:
use it for imported ObjC USRs, superclass/protocol identity, selectors, type
optionality, declaration attributes, and ordered enum children. The graph remains
the canonical exact-ID census. `reference/external-evidence.json` pins independent
binding sources available in the prepared cloud environment. They are a
read-only secondary cross-check, never authority over the Apple-derived files and
never runtime evidence. If sources conflict, defer the declaration and add an
oracle question. Do not guess.

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
  not exercised is not `implemented`. Every `implemented` row must cite
  `test:full/{slug}/tests/agent/*Tests.swift#testName`; define that exact `test*`
  function for the sealed runner to call. Every `declared` row must cite
  `source:full/{slug}/<product-source>.swift#Symbol`; the source must be listed in
  `{slug}_guest_sources.txt` and contain the exact identifier anchor. Deferred,
  unavailable, and not-applicable rows require explanatory notes.
- Create `oracle-questions.tsv` with the exact header
  `precise\tquestion\trisk\treason`. Use an exact graph precise ID, or `module`
  for a cross-cutting question. Include at least one concrete question; do not
  guess behavior missing from public inputs.
- Create a nonempty `README.md` describing what is real, fail-closed, and still
  deferred. The primary implementation file must be `{module}.swift`.
- Put focused behavioral checks in `tests/agent/*Tests.swift` as top-level,
  synchronous, no-argument functions named `test*`. Create
  `tests/agent/{module}LoadSmoke.swift` with exactly these three logical lines
  (including the blank line): `import {module}`, a blank line, and
  `let frameworkLoadSmokeMarker = "{marker}"`. The sealed gate generates the
  executable runner from `implemented` coverage rows, imports and explicitly
  loads the dylib, invokes every cited test exactly once, and emits the marker
  as its sole stdout. Loading and printing are acceptance plumbing, not
  behavioral evidence by themselves.
- When dependencies are listed below, create
  `tests/agent/{module}DependencyIdentity.swift`. Import `{module}` and every
  declared dependency and pass genuine dependency values through public
  `{module}` APIs. This probe is for the clean EC2 integration build; the isolated
  host gate is not permission to create same-named stand-ins. Never declare a
  public framework-local substitute for a dependency-owned type.
- Preserve unavailable, entitlement-gated, hardware-only, and Apple-service
  behavior honestly. Prefer deterministic fail-closed errors or inert behavior
  over fabricated success. Do not add or prioritize `#Preview` support.

Before implementation, make a declaration-facts pass: exact graph ID and
signature, matching API-digester node/USR, dependency owner, and any corroborating
binding source location. Static sources do not establish defaults, callback
timing, queues, retention, coding round trips, hardware behavior, or service
success. Such behavior is `implemented` only with focused behavioral test
evidence; the load-smoke marker alone proves none of it.

## Build discipline

Run `bash tests/acceptance/test_host.sh` from this framework directory before
committing. It validates evidence, coverage, the source manifest, warnings-as-
errors compilation, dylib creation, import, linking, focused tests, and the exact
load-smoke marker.
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
Reconcile each planned declaration with `reference/api-digester.json` before
coding. It supplies the compiler's imported ObjC USRs, base/protocol identity,
selectors, optionality, attributes, and ordered enum children. Then consult the
pinned independent bindings described by `reference/external-evidence.json` as a
secondary cross-check. Apple-derived evidence wins; any unresolved conflict is an
oracle question, not a license to guess. External bindings are not runtime
evidence and their implementation must not be copied.
Use `reference/sdk-inputs.tsv` and `reference/tbd-exports.tsv` as provenance and
ABI evidence only; the Apple SDK input bytes are intentionally absent. Use
`reference/corpus-summary.json` to prioritize APIs exercised by the 20-app
roadmap corpus.

Deliver all of the following in `full/{slug}/`:

1. Linux Swift sources for module `{module}` and `lib{module}.dylib`, with every
   implementation source listed in `{slug}_guest_sources.txt`.
2. Complete exact-ID `coverage.tsv` using only the five allowed statuses.
   `implemented` evidence has the exact form
   `test:full/{slug}/tests/agent/*Tests.swift#testName`; `declared` evidence has
   the exact form `source:full/{slug}/<product-source>.swift#Symbol`. Every cited
   test/function and product source/anchor must exist, and the product source
   must be listed in `{slug}_guest_sources.txt`.
3. Nonempty `{module}.swift` and `README.md`, plus `oracle-questions.tsv` with
   header `precise\tquestion\trisk\treason` and at least one question; use
   `module` only for cross-cutting items.
4. Top-level synchronous no-argument functions named `test*` in
   `tests/agent/*Tests.swift`, plus `tests/agent/{module}LoadSmoke.swift` whose
   exact content is `import {module}`, one blank line, and
   `let frameworkLoadSmokeMarker = "{marker}"`. The sealed gate derives a runner
   from `implemented` coverage, loads `lib{module}.dylib`, and calls each cited
   test exactly once before accepting marker-only output. The load/marker check
   is not behavioral evidence by itself.
5. If dependencies are declared, `tests/agent/{module}DependencyIdentity.swift`
   importing the real modules and exercising genuine dependency values. The
   clean EC2 integration build, not a framework-local lookalike, is the authority.
6. A clean successful run of `bash tests/acceptance/test_host.sh` with no checked-
   in or stale build products.

Declared dependencies:

{markdown_list(dependencies, "None beyond the Swift Linux toolchain.")}

Known risk labels:

{markdown_list(risks, "None supplied.")}

Do not invent successful Apple service, device, entitlement, privacy, or UI
behavior. Record questions that need a central Apple-oracle probe and keep those
paths fail-closed until observed. Static declarations and binding annotations do
not prove defaults, callback timing, queue choice, exactly-once delivery,
retention, coding round trips, hardware behavior, or service results.
"""


def acceptance_script() -> str:
    # The here-doc is single quoted so framework paths cannot become shell code.
    return r'''#!/usr/bin/env bash
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
'''


def select_developer_directory() -> Path:
    """Resolve the active Xcode once, without honoring ambient toolchain overrides."""

    if sys.platform != "darwin":
        raise SeedError("framework seeds must be generated on macOS")
    selector = Path("/usr/bin/xcode-select")
    if not selector.is_file():
        raise SeedError("/usr/bin/xcode-select is unavailable")
    bootstrap_env = {
        "PATH": HERMETIC_PATH,
        "LANG": "C",
        "LC_ALL": "C",
    }
    selected_text = run_checked(
        [str(selector), "-p"], env=bootstrap_env
    ).strip()
    selected = Path(selected_text)
    if not selected.is_absolute() or not selected.is_dir():
        raise SeedError("xcode-select returned a missing or non-absolute Developer directory")
    try:
        developer_dir = selected.resolve(strict=True)
    except OSError as error:
        raise SeedError(f"cannot resolve the selected Developer directory: {error}") from error
    if developer_dir.name != "Developer" or developer_dir.parent.name != "Contents":
        raise SeedError("xcode-select does not identify a full Xcode Developer directory")
    return developer_dir


def prepare_clean_environment(
    temp_root: Path, developer_dir: Path
) -> dict[str, str]:
    """Build an allowlisted extractor environment with one explicit Xcode."""

    home = temp_root / "home"
    temporary = temp_root / "tmp"
    module_cache = temp_root / "clang-module-cache"
    for path in (home, temporary, module_cache):
        path.mkdir()
    return {
        "PATH": HERMETIC_PATH,
        "HOME": str(home),
        "CFFIXED_USER_HOME": str(home),
        "TMPDIR": str(temporary),
        "CLANG_MODULE_CACHE_PATH": str(module_cache),
        "SWIFT_MODULECACHE_PATH": str(temp_root / "swift-module-cache"),
        "LC_ALL": "C",
        "LANG": "C",
        "DEVELOPER_DIR": str(developer_dir),
    }


def resolve_developer_tool(
    name: str,
    developer_dir: Path,
    clean_env: dict[str, str],
) -> dict[str, str]:
    """Resolve one Xcode tool, retaining its dispatching symlink as argv[0]."""

    located_text = run_checked(
        ["/usr/bin/xcrun", "--sdk", SDK_NAME, "--find", name],
        env=clean_env,
    ).strip()
    if not located_text or CONTROL_RE.search(located_text):
        raise SeedError(f"xcrun returned an unsafe path for {name}")
    logical = Path(located_text)
    if not logical.is_absolute() or not logical.is_file():
        raise SeedError(f"xcrun returned a missing or non-absolute path for {name}")
    try:
        relative = logical.relative_to(developer_dir)
        resolved = logical.resolve(strict=True)
    except (OSError, ValueError) as error:
        raise SeedError(f"cannot resolve {name} inside the selected Xcode: {error}") from error
    if not within(resolved, developer_dir) or not resolved.is_file():
        raise SeedError(f"{name} resolves outside the selected Xcode Developer directory")
    relative_text = relative.as_posix()
    if (
        PurePosixPath(relative_text).name != name
        or ".." in PurePosixPath(relative_text).parts
    ):
        raise SeedError(f"xcrun returned a noncanonical relative path for {name}")

    # The logical tool names dispatch through swift-frontend and reject a version
    # flag themselves. Query the resolved executable, then retain only the first
    # architecture-independent compiler identity line in canonical provenance.
    version_lines = run_checked(
        [str(resolved), "-version"], env=clean_env
    ).splitlines()
    version = version_lines[0].strip() if version_lines else ""
    if (
        not version
        or CONTROL_RE.search(version)
        or len(version.encode("utf-8")) > 500
    ):
        raise SeedError(f"cannot determine a safe version identity for {name}")
    return {
        "executable": str(logical),
        "path": relative_text,
        "sha256": sha256_file(logical),
        "version": version,
    }


def validate_xcode(
    developer_dir: Path, clean_env: dict[str, str]
) -> dict[str, str]:
    if not Path("/usr/bin/xcrun").is_file():
        raise SeedError("/usr/bin/xcrun is unavailable")
    if clean_env.get("DEVELOPER_DIR") != str(developer_dir):
        raise SeedError("extractor environment does not pin the selected Developer directory")
    version_lines = run_checked(
        ["/usr/bin/xcrun", "xcodebuild", "-version"], env=clean_env
    ).splitlines()
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
        ["/usr/bin/xcrun", "--sdk", SDK_NAME, "--show-sdk-version"],
        env=clean_env,
    ).strip()
    if sdk_version != EXPECTED_SDK_VERSION:
        raise SeedError(
            f"requires iPhoneOS SDK {EXPECTED_SDK_VERSION}; found {sdk_version}"
        )
    sdk_path = run_checked(
        ["/usr/bin/xcrun", "--sdk", SDK_NAME, "--show-sdk-path"],
        env=clean_env,
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
        or not within(sdk_directory, developer_dir)
    ):
        raise SeedError("xcrun SDK is outside the expected iPhoneOS SDKs directory")
    if not sdk.is_dir() or not within(sdk, sdk_directory):
        raise SeedError(
            "resolved xcrun SDK must be a directory inside the same iPhoneOS SDKs directory"
        )
    extractor = resolve_developer_tool(
        "swift-symbolgraph-extract", developer_dir, clean_env
    )
    digester = resolve_developer_tool(
        "swift-api-digester", developer_dir, clean_env
    )
    return {
        "xcodeVersion": EXPECTED_XCODE_VERSION,
        "xcodeBuild": build,
        "sdkName": SDK_NAME,
        "sdkVersion": sdk_version,
        # Absolute paths are process-local inputs only. Canonical provenance
        # records Xcode-relative tool identities and logical SDK identity.
        "_sdkPath": str(sdk),
        "_symbolGraphExtractorExecutable": extractor["executable"],
        "_apiDigesterExecutable": digester["executable"],
        "symbolGraphExtractorPath": extractor["path"],
        "symbolGraphExtractorSHA256": extractor["sha256"],
        "symbolGraphExtractorVersion": extractor["version"],
        "apiDigesterPath": digester["path"],
        "apiDigesterSHA256": digester["sha256"],
        "apiDigesterVersion": digester["version"],
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
    external_evidence_lock_path = repo_root / EXTERNAL_EVIDENCE_LOCK
    if not roadmap_path.is_file():
        raise SeedError("generator is not inside the expected platform repository")
    if not external_evidence_lock_path.is_file():
        raise SeedError("external evidence source lock is missing")
    output_root = safe_output_root(args.output_root, repo_root)
    target_root = output_root / slug
    if target_root.exists() or target_root.is_symlink():
        raise SeedError(f"refusing to replace existing framework seed: {target_root}")

    developer_dir = select_developer_directory()
    stage = Path(tempfile.mkdtemp(prefix=f".{slug}.seed.", dir=output_root))
    temp_root: Path | None = None
    published = False
    try:
        temp_root = Path(tempfile.mkdtemp(prefix=f"{slug}-oracle-seed."))
        clean_env = prepare_clean_environment(temp_root, developer_dir)
        toolchain = validate_xcode(developer_dir, clean_env)
        sdk_root = Path(toolchain["_sdkPath"])
        location = locate_sdk_module(sdk_root, module)
        extract_frontend_args = extractor_clang_module_args(location)
        digester_frontend_args = digester_clang_module_args(location)
        umbrella = detect_umbrella_reexport(
            module, location, sdk_root, require_pure=True
        )
        if umbrella is not None:
            raise SeedError(
                f"umbrella re-export of {umbrella}; seed {umbrella} instead"
            )

        reference_root = stage / "reference"
        reference_root.mkdir()
        (stage / "tests/acceptance").mkdir(parents=True)

        sdk_records, tbd_paths = collect_located_sdk_inputs(
            location, sdk_root, module
        )
        write_sdk_input_ledger(reference_root / "sdk-inputs.tsv", sdk_records)

        graph_manifest, symbols = generate_symbol_graphs(
            module,
            sdk_root,
            temp_root,
            reference_root,
            clean_env,
            Path(toolchain["_symbolGraphExtractorExecutable"]),
            extract_frontend_args,
        )
        write_json(reference_root / "symbol-graphs.json", graph_manifest)
        write_public_surface(reference_root / "public-surface.tsv", symbols)
        refuse_empty_or_umbrella(
            module,
            graph_manifest["symbolCount"],
            detect_umbrella_reexport(module, location, sdk_root),
        )
        api_stats = generate_api_digester(
            module,
            sdk_root,
            temp_root,
            reference_root,
            clean_env,
            Path(toolchain["_apiDigesterExecutable"]),
            symbols,
            digester_frontend_args,
        )
        tbd_export_count = write_tbd_exports(
            reference_root / "tbd-exports.tsv", tbd_paths, sdk_root, clean_env
        )

        corpus = roadmap_summary(
            roadmap_path,
            module,
            allow_missing=bool(getattr(args, "allow_no_roadmap_record", False)),
        )
        write_json(reference_root / "corpus-summary.json", corpus)
        external_evidence = external_evidence_summary(
            external_evidence_lock_path, module
        )
        write_json(reference_root / "external-evidence.json", external_evidence)

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
            "reference/symbol-conflicts.tsv",
            "reference/public-surface.tsv",
            "reference/api-digester.json",
            "reference/api-crosswalk.tsv",
            "reference/tbd-exports.tsv",
            "reference/sdk-inputs.tsv",
            "reference/corpus-summary.json",
            "reference/external-evidence.json",
        ] + [record["path"] for record in graph_manifest["files"]]
        write_text(
            reference_root / "seed-files.sha256",
            digest_lines(stage, evidence_paths),
        )

        framework_json = {
            "schema": FRAMEWORK_SCHEMA,
            "module": module,
            "slug": slug,
            "lane": lane,
            "risks": risks,
            "dependencies": dependencies,
            "symbolCount": symbol_count,
            "relationshipCount": relationship_count,
            "symbolGraph": "reference/symbol-graphs.json",
            "symbolConflicts": "reference/symbol-conflicts.tsv",
            "publicSurface": "reference/public-surface.tsv",
            "apiDigester": "reference/api-digester.json",
            "apiCrosswalk": "reference/api-crosswalk.tsv",
            "tbdExports": "reference/tbd-exports.tsv",
            "corpusSummary": "reference/corpus-summary.json",
            "externalEvidence": "reference/external-evidence.json",
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
                "generatorPath": "scripts/framework-fanout/generate_seed_v2.py",
                "generatorSHA256": sha256_file(script_path),
                "xcodeVersion": toolchain["xcodeVersion"],
                "xcodeBuild": toolchain["xcodeBuild"],
                "sdkName": toolchain["sdkName"],
                "sdkVersion": toolchain["sdkVersion"],
                "target": TARGET,
                "frameworkSDKRelativePath": location.sdk_relative_path,
                "symbolGraphExtractorPath": toolchain[
                    "symbolGraphExtractorPath"
                ],
                "symbolGraphExtractorSHA256": toolchain[
                    "symbolGraphExtractorSHA256"
                ],
                "symbolGraphExtractorVersion": toolchain[
                    "symbolGraphExtractorVersion"
                ],
                "apiDigesterPath": toolchain["apiDigesterPath"],
                "apiDigesterSHA256": toolchain["apiDigesterSHA256"],
                "apiDigesterVersion": toolchain["apiDigesterVersion"],
                "roadmapPath": "full/framework-roadmap/framework-roadmap.json",
                "roadmapSHA256": sha256_file(roadmap_path),
                "rawSDKInputCount": len(sdk_records),
                "tbdInputCount": len(tbd_paths),
                "arm64TBDExportCount": tbd_export_count,
                "apiDigesterFormatVersion": api_stats["formatVersion"],
                "apiDigesterNodeCount": api_stats["nodeCount"],
                "apiDeclarationNodeCount": api_stats["declarationNodeCount"],
                "apiOwnedDeclarationNodeCount": api_stats[
                    "ownedDeclarationNodeCount"
                ],
                "apiCrosswalkExactUSRCount": api_stats["exactUSRCount"],
                "apiCrosswalkImportNameCount": api_stats["importNameCount"],
                "apiCrosswalkAmbiguousCount": api_stats["ambiguousCount"],
                "apiCrosswalkUnmatchedCount": api_stats["unmatchedCount"],
                "symbolGraphSymbolMultisetSHA256": graph_manifest[
                    "symbolMultisetSHA256"
                ],
                "symbolGraphRelationshipMultisetSHA256": graph_manifest[
                    "relationshipMultisetSHA256"
                ],
                "externalEvidenceLockPath": EXTERNAL_EVIDENCE_LOCK,
                "externalEvidenceLockSHA256": sha256_file(
                    external_evidence_lock_path
                ),
            },
        }
        framework_json["moduleLocation"] = location.record()
        if corpus.get("moduleRecord") == {"roadmap": ROADMAP_OPERATOR_OVERRIDE}:
            framework_json["roadmap"] = ROADMAP_OPERATOR_OVERRIDE
        write_json(reference_root / "framework.json", framework_json)

        immutable_paths = [
            "AGENTS.md",
            "FANOUT_TASK.md",
            "tests/acceptance/test_host.sh",
        ]
        immutable_paths.extend(
            path.relative_to(stage).as_posix()
            for path in reference_root.rglob("*")
            if path.is_file()
            and path.relative_to(stage).as_posix()
            != "reference/immutable-files.sha256"
        )
        write_text(
            reference_root / "immutable-files.sha256",
            digest_lines(stage, immutable_paths),
        )

        # Publish only after every output and digest has been written.  The
        # Darwin no-replace rename closes the long extraction race while
        # preserving a one-step directory publication on the same filesystem.
        publish_directory_exclusive(stage, target_root)
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
    parser.add_argument(
        "--allow-no-roadmap-record",
        action="store_true",
        help=(
            "if the framework roadmap has no module record, record "
            f"{ROADMAP_OPERATOR_OVERRIDE!r} instead of refusing; default still refuses"
        ),
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
