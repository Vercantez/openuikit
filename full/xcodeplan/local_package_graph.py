#!/usr/bin/env python3
"""Freeze the reachable local Swift-package graph for one Xcode application.

The planner deliberately does not execute ``Package.swift``.  It accepts a
small, explicit PackageDescription surface, follows only source-root-contained
local dependencies, and records remote dependencies as unresolved materialized
inputs.  Every manifest, lock file, reachable source, and C-family textual
input is hashed.
"""

from __future__ import annotations

import argparse
from dataclasses import dataclass
import hashlib
import json
import os
from pathlib import Path, PurePosixPath
import re
import stat
import sys
import unicodedata
from typing import Any, Iterable, Mapping


class PackageGraphError(RuntimeError):
    """The selected package graph cannot be represented without guessing."""


@dataclass(frozen=True)
class _Token:
    kind: str
    value: str
    offset: int


_IDENTIFIER = re.compile(r"[A-Za-z_][A-Za-z0-9_]*\Z")
_SEMVER = re.compile(r"(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)\Z")
_C_SOURCE_LANGUAGES = {
    ".c": "c",
    ".cc": "cxx",
    ".cpp": "cxx",
    ".cxx": "cxx",
    ".m": "objective-c",
    ".mm": "objective-cxx",
    ".s": "assembler",
    ".S": "assembler-with-cpp",
}
_CODE_EXTENSIONS = frozenset(_C_SOURCE_LANGUAGES)
# C-family compilation can consume textual inclusions as directly as ordinary
# headers.  Freezing only ``*.h`` would leave a mutation hole for projects such
# as swift-cmark, whose generated entity tables are checked in as ``*.inc``.
_C_HEADER_EXTENSIONS = frozenset(
    {".h", ".hh", ".hpp", ".hxx", ".inc", ".def"}
)


def _mapping(value: Any, label: str) -> dict[str, Any]:
    if not isinstance(value, dict):
        raise PackageGraphError(f"{label} must be an object")
    return value


def _list(value: Any, label: str) -> list[Any]:
    if not isinstance(value, list):
        raise PackageGraphError(f"{label} must be an array")
    return value


def _string(value: Any, label: str) -> str:
    if not isinstance(value, str) or not value:
        raise PackageGraphError(f"{label} must be a non-empty string")
    if any(character in value for character in "\0\r\n"):
        raise PackageGraphError(f"{label} contains a forbidden control character")
    return value


def _portable(value: str) -> str:
    return unicodedata.normalize("NFC", value.casefold())


def _sha256(data: bytes) -> str:
    return hashlib.sha256(data).hexdigest()


def canonical_json(value: Any) -> bytes:
    return (json.dumps(value, sort_keys=True, separators=(",", ":")) + "\n").encode(
        "utf-8"
    )


def _json_no_duplicates(data: bytes, label: str) -> Any:
    def pairs(values: list[tuple[str, Any]]) -> dict[str, Any]:
        result: dict[str, Any] = {}
        for key, value in values:
            if key in result:
                raise PackageGraphError(f"{label} repeats JSON key {key!r}")
            result[key] = value
        return result

    try:
        return json.loads(data, object_pairs_hook=pairs)
    except (UnicodeDecodeError, json.JSONDecodeError) as exc:
        raise PackageGraphError(f"cannot parse {label}: {exc}") from exc


def _strict_root(value: Path) -> Path:
    if not value.is_absolute():
        raise PackageGraphError("application source root must be absolute")
    try:
        metadata = value.lstat()
    except OSError as exc:
        raise PackageGraphError(
            f"cannot inspect application source root: {exc}"
        ) from exc
    if stat.S_ISLNK(metadata.st_mode) or not stat.S_ISDIR(metadata.st_mode):
        raise PackageGraphError("application source root must be an ordinary directory")
    return value.resolve(strict=True)


def _safe_stored_relative(value: str, label: str) -> PurePosixPath:
    path = PurePosixPath(value)
    if (
        path.is_absolute()
        or not path.parts
        or path.as_posix() != value
        or any(part in ("", ".", "..") for part in path.parts)
        or "\\" in value
    ):
        raise PackageGraphError(f"{label} is not a normalized relative path: {value!r}")
    return path


def _lexical_dependency_path(value: str, label: str) -> PurePosixPath:
    path = PurePosixPath(value)
    if path.is_absolute() or not path.parts or "\\" in value:
        raise PackageGraphError(f"{label} is not a relative POSIX path: {value!r}")
    if any(part in ("", ".") for part in path.parts):
        raise PackageGraphError(f"{label} is not lexically normalized: {value!r}")
    return path


def _ordinary(root: Path, relative: PurePosixPath, label: str) -> Path:
    current = root
    for component in relative.parts:
        current = current / component
        try:
            metadata = current.lstat()
        except OSError as exc:
            raise PackageGraphError(
                f"cannot inspect {label}: {current}: {exc}"
            ) from exc
        if stat.S_ISLNK(metadata.st_mode):
            raise PackageGraphError(f"{label} traverses a symlink: {current}")
    try:
        current.resolve(strict=True).relative_to(root)
    except (OSError, ValueError) as exc:
        raise PackageGraphError(
            f"{label} escapes the application source root: {current}"
        ) from exc
    return current


def _resolve_local_dependency(
    root: Path, package_relative: str, dependency: str, label: str
) -> str:
    raw = _lexical_dependency_path(dependency, label)
    stack = list(PurePosixPath(package_relative).parts)
    for component in raw.parts:
        if component == "..":
            if not stack:
                raise PackageGraphError(f"{label} escapes the application source root")
            stack.pop()
        else:
            stack.append(component)
    if not stack:
        raise PackageGraphError(f"{label} resolves to the application source root")
    relative = PurePosixPath(*stack)
    path = _ordinary(root, relative, label)
    if not path.is_dir():
        raise PackageGraphError(f"{label} is not an ordinary directory: {path}")
    return relative.as_posix()


def _file_record(root: Path, relative: str, label: str) -> dict[str, Any]:
    path = _ordinary(root, _safe_stored_relative(relative, label), label)
    metadata = path.lstat()
    if not stat.S_ISREG(metadata.st_mode):
        raise PackageGraphError(f"{label} is not a regular file: {path}")
    data = path.read_bytes()
    return {"path": relative, "sha256": _sha256(data), "size": len(data)}


def _tokenize(text: str, label: str) -> list[_Token]:
    result: list[_Token] = []
    index = 0
    size = len(text)
    while index < size:
        character = text[index]
        if character.isspace():
            index += 1
            continue
        if text.startswith("//", index):
            end = text.find("\n", index + 2)
            index = size if end < 0 else end + 1
            continue
        if text.startswith("/*", index):
            start = index
            index += 2
            depth = 1
            while index < size and depth:
                if text.startswith("/*", index):
                    depth += 1
                    index += 2
                elif text.startswith("*/", index):
                    depth -= 1
                    index += 2
                else:
                    index += 1
            if depth:
                raise PackageGraphError(
                    f"{label} has an unterminated block comment at {start}"
                )
            continue
        if character == '"':
            start = index
            index += 1
            escaped = False
            while index < size:
                current = text[index]
                if current in "\r\n":
                    raise PackageGraphError(
                        f"{label} uses an unsupported multiline string at {start}"
                    )
                if escaped:
                    escaped = False
                elif current == "\\":
                    escaped = True
                elif current == '"':
                    index += 1
                    result.append(_Token("string", text[start:index], start))
                    break
                index += 1
            else:
                raise PackageGraphError(
                    f"{label} has an unterminated string at {start}"
                )
            continue
        if character.isascii() and (character.isalpha() or character == "_"):
            start = index
            index += 1
            while (
                index < size
                and text[index].isascii()
                and (text[index].isalnum() or text[index] == "_")
            ):
                index += 1
            result.append(_Token("identifier", text[start:index], start))
            continue
        if character.isascii() and character.isdigit():
            start = index
            index += 1
            while index < size and text[index].isascii() and text[index].isdigit():
                index += 1
            result.append(_Token("number", text[start:index], start))
            continue
        result.append(_Token("punctuation", character, index))
        index += 1
    return result


def _evaluate_manifest_condition(expression: str, label: str) -> bool:
    value = expression.strip()
    platform = re.fullmatch(r"os\((Windows|Linux|macOS)\)", value)
    if platform is not None:
        # The portable graph models Xcode's Apple-target manifest profile even
        # when its compiler jobs later execute on a Linux host.
        return platform.group(1) == "macOS"
    swift = re.fullmatch(
        r"swift\(>=(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)\)", value
    )
    if swift is not None:
        requested = (int(swift.group(1)), int(swift.group(2)))
        return (6, 2) >= requested
    raise PackageGraphError(
        f"{label} uses unsupported conditional compilation expression {value!r}"
    )


def _preprocess_manifest_conditions(text: str, label: str) -> str:
    result: list[str] = []
    # parent-active, branch-condition, else-seen
    stack: list[tuple[bool, bool, bool]] = []
    active = True
    for line_number, line in enumerate(text.splitlines(keepends=True), 1):
        stripped = line.strip()
        if stripped.startswith("#if "):
            condition = _evaluate_manifest_condition(
                stripped[4:], f"{label}:{line_number}"
            )
            stack.append((active, condition, False))
            active = active and condition
            result.append("\n" if line.endswith("\n") else "")
            continue
        if stripped == "#else":
            if not stack:
                raise PackageGraphError(f"{label}:{line_number} has unmatched #else")
            parent, condition, seen_else = stack[-1]
            if seen_else:
                raise PackageGraphError(f"{label}:{line_number} repeats #else")
            stack[-1] = (parent, condition, True)
            active = parent and not condition
            result.append("\n" if line.endswith("\n") else "")
            continue
        if stripped == "#endif":
            if not stack:
                raise PackageGraphError(f"{label}:{line_number} has unmatched #endif")
            parent, _, _ = stack.pop()
            active = parent
            result.append("\n" if line.endswith("\n") else "")
            continue
        if stripped.startswith("#elseif"):
            raise PackageGraphError(f"{label}:{line_number} uses unsupported #elseif")
        result.append(line if active else ("\n" if line.endswith("\n") else ""))
    if stack:
        raise PackageGraphError(f"{label} has an unterminated #if")
    return "".join(result)


def _matching_delimiter(tokens: list[_Token], start: int, label: str) -> int:
    pairs = {"(": ")", "[": "]", "{": "}"}
    opening = tokens[start].value
    closing = pairs.get(opening)
    if closing is None:
        raise PackageGraphError(f"{label} does not begin with a delimiter")
    stack = [opening]
    reverse = {value: key for key, value in pairs.items()}
    for index in range(start + 1, len(tokens)):
        value = tokens[index].value
        if value in pairs:
            stack.append(value)
        elif value in reverse:
            if not stack or stack.pop() != reverse[value]:
                raise PackageGraphError(f"{label} has unbalanced delimiters")
            if not stack:
                return index
    raise PackageGraphError(f"{label} has an unterminated delimiter")


def _environment_string_ternary(
    tokens: list[_Token], label: str
) -> list[_Token] | None:
    question = next(
        (index for index, token in enumerate(tokens) if token.value == "?"), -1
    )
    if question < 0:
        return None
    colon = next(
        (
            index
            for index, token in enumerate(tokens[question + 1 :], question + 1)
            if token.value == ":"
        ),
        -1,
    )
    if (
        colon < 0
        or len(tokens[question + 1 : colon]) != 1
        or len(tokens[colon + 1 :]) != 1
        or tokens[question + 1].kind != "string"
        or tokens[colon + 1].kind != "string"
    ):
        return None
    condition = [token.value for token in tokens[:question]]
    if (
        "environment" not in condition
        or "[" not in condition
        or "]" not in condition
        or condition[-3:] != ["=", "=", "nil"]
    ):
        return None
    key_tokens = [token for token in tokens[:question] if token.kind == "string"]
    if len(key_tokens) != 1:
        raise PackageGraphError(f"{label} environment condition has no unique key")
    _decode_swift_string(key_tokens[0], f"{label} environment key")
    # The manifest profile is deliberately hermetic: no caller-provided
    # environment enters dependency or compiler-setting selection.
    return [tokens[question + 1]]


def _static_manifest_bindings(
    tokens: list[_Token],
    stop: int,
    label: str,
    manifest_root: Path | None = None,
) -> dict[str, list[_Token]]:
    bindings: dict[str, list[_Token]] = {}
    index = 0
    depth = 0
    while index < stop:
        token = tokens[index]
        if token.value in "([{":
            depth += 1
            index += 1
            continue
        if token.value in ")]}" and depth:
            depth -= 1
            index += 1
            continue
        if (
            depth != 0
            or token.value not in {"let", "var"}
            or index + 1 >= stop
            or tokens[index + 1].kind != "identifier"
        ):
            index += 1
            continue
        name = tokens[index + 1].value
        cursor = index + 2
        local_depth = 0
        assignment = -1
        while cursor < stop:
            value = tokens[cursor].value
            if value in "([{":
                local_depth += 1
            elif value in ")]}" and local_depth:
                local_depth -= 1
            elif value == "=" and local_depth == 0:
                assignment = cursor
                break
            elif value in {"let", "var"} and local_depth == 0:
                break
            cursor += 1
        if assignment < 0 or assignment + 1 >= stop:
            index += 2
            continue
        start = assignment + 1
        first = tokens[start].value
        end = -1
        if first == "[":
            end = _matching_delimiter(tokens, start, f"{label} binding {name!r}")
        elif first == "{":
            closure_end = _matching_delimiter(
                tokens, start, f"{label} binding {name!r}"
            )
            closure = tokens[start : closure_end + 1]
            values = [item.value for item in closure]
            strings = {
                _decode_swift_string(item, f"{label} binding {name!r}")
                for item in closure
                if item.kind == "string"
            }
            required = {
                "CI.xcconfig",
                "Local.xcconfig",
                "TUIST_SWIFT_CONDITIONS",
            }
            define_count = sum(
                values[offset : offset + 2] == [".", "define"]
                for offset in range(max(0, len(values) - 1))
            )
            if (
                manifest_root is not None
                and required <= strings
                and define_count == 1
                and not (manifest_root / "CI.xcconfig").exists()
                and not (manifest_root / "CI.xcconfig").is_symlink()
                and not (manifest_root / "Local.xcconfig").exists()
                and not (manifest_root / "Local.xcconfig").is_symlink()
                and "environment" in values
                and "map" in values
            ):
                # Under the hermetic manifest profile, both optional files and
                # the process environment are absent, so this exact
                # file/environment-to-.define closure is provably empty.
                bindings[name] = [
                    _Token("punctuation", "[", tokens[start].offset),
                    _Token("punctuation", "]", tokens[start].offset),
                ]
                index = closure_end + 1
                continue
        elif first == "." and start + 2 < stop and tokens[start + 2].value == "(":
            end = _matching_delimiter(
                tokens, start + 2, f"{label} binding {name!r}"
            )
        elif tokens[start].kind == "string":
            end = start
        if end >= 0 and end < stop:
            bindings[name] = tokens[start : end + 1]
            index = end + 1
            continue

        next_declaration = stop
        scan = start
        scan_depth = 0
        while scan < stop:
            value = tokens[scan].value
            if value in "([{":
                scan_depth += 1
            elif value in ")]}" and scan_depth:
                scan_depth -= 1
            elif value in {"let", "var"} and scan_depth == 0 and scan > start:
                next_declaration = scan
                break
            scan += 1
        ternary = _environment_string_ternary(
            tokens[start:next_declaration], f"{label} binding {name!r}"
        )
        if ternary is not None:
            bindings[name] = ternary
        index = max(index + 2, next_declaration)
    return bindings


def _expand_manifest_bindings(
    tokens: list[_Token],
    bindings: Mapping[str, list[_Token]],
    label: str,
    stack: tuple[str, ...] = (),
) -> list[_Token]:
    result: list[_Token] = []
    for index, token in enumerate(tokens):
        previous = tokens[index - 1].value if index else None
        following = tokens[index + 1].value if index + 1 < len(tokens) else None
        if (
            token.kind == "identifier"
            and token.value in bindings
            and previous != "."
            and following not in {":", "(", "."}
        ):
            if token.value in stack:
                raise PackageGraphError(
                    f"{label} has cyclic static binding {token.value!r}"
                )
            result.extend(
                _expand_manifest_bindings(
                    list(bindings[token.value]),
                    bindings,
                    label,
                    (*stack, token.value),
                )
            )
        else:
            result.append(token)
    return result


def _decode_swift_string(token: _Token, label: str) -> str:
    if token.kind != "string":
        raise PackageGraphError(f"{label} must be a static string literal")
    raw = token.value[1:-1]
    result: list[str] = []
    index = 0
    while index < len(raw):
        character = raw[index]
        if character != "\\":
            result.append(character)
            index += 1
            continue
        index += 1
        if index >= len(raw):
            raise PackageGraphError(f"{label} has a dangling string escape")
        escape = raw[index]
        index += 1
        if escape == "(":
            raise PackageGraphError(f"{label} uses unsupported string interpolation")
        replacements = {
            "\\": "\\",
            '"': '"',
            "n": "\n",
            "r": "\r",
            "t": "\t",
            "0": "\0",
        }
        if escape in replacements:
            result.append(replacements[escape])
            continue
        if escape == "u" and index < len(raw) and raw[index] == "{":
            end = raw.find("}", index + 1)
            digits = raw[index + 1 : end] if end >= 0 else ""
            if end < 0 or not re.fullmatch(r"[0-9A-Fa-f]{1,8}", digits):
                raise PackageGraphError(f"{label} has an invalid Unicode escape")
            try:
                result.append(chr(int(digits, 16)))
            except ValueError as exc:
                raise PackageGraphError(
                    f"{label} has an invalid Unicode scalar"
                ) from exc
            index = end + 1
            continue
        raise PackageGraphError(f"{label} has unsupported string escape \\{escape}")
    value = "".join(result)
    return _string(value, label)


def _balanced(tokens: list[_Token], label: str) -> None:
    pairs = {")": "(", "]": "[", "}": "{"}
    stack: list[str] = []
    for token in tokens:
        if token.value in "([{":
            stack.append(token.value)
        elif token.value in ")]}":
            if not stack or stack.pop() != pairs[token.value]:
                raise PackageGraphError(f"{label} has unbalanced delimiters")
    if stack:
        raise PackageGraphError(f"{label} has unbalanced delimiters")


def _split(tokens: list[_Token], delimiter: str, label: str) -> list[list[_Token]]:
    _balanced(tokens, label)
    result: list[list[_Token]] = []
    current: list[_Token] = []
    depth = 0
    for token in tokens:
        if token.value in "([{":
            depth += 1
        elif token.value in ")]}":
            depth -= 1
        if token.value == delimiter and depth == 0:
            result.append(current)
            current = []
        else:
            current.append(token)
    result.append(current)
    if result and not result[-1]:
        result.pop()
    if any(not item for item in result):
        raise PackageGraphError(f"{label} contains an empty element")
    return result


def _named_arguments(tokens: list[_Token], label: str) -> dict[str, list[_Token]]:
    result: dict[str, list[_Token]] = {}
    for index, item in enumerate(_split(tokens, ",", label)):
        depth = 0
        separator = -1
        for offset, token in enumerate(item):
            if token.value in "([{":
                depth += 1
            elif token.value in ")]}":
                depth -= 1
            elif token.value == ":" and depth == 0:
                separator = offset
                break
        if separator != 1 or item[0].kind != "identifier" or separator == len(item) - 1:
            raise PackageGraphError(
                f"{label} argument {index} is not a static named argument"
            )
        name = item[0].value
        if name in result:
            raise PackageGraphError(f"{label} repeats argument {name!r}")
        result[name] = item[separator + 1 :]
    return result


def _call(tokens: list[_Token], label: str) -> tuple[str, dict[str, list[_Token]]]:
    if tokens and tokens[0].value == ".":
        tokens = tokens[1:]
    if (
        len(tokens) < 3
        or tokens[0].kind != "identifier"
        or tokens[1].value != "("
        or tokens[-1].value != ")"
    ):
        raise PackageGraphError(f"{label} must be one static call expression")
    _balanced(tokens, label)
    depth = 0
    closing = -1
    for index, token in enumerate(tokens[1:], 1):
        if token.value == "(":
            depth += 1
        elif token.value == ")":
            depth -= 1
            if depth == 0:
                closing = index
                break
    if closing != len(tokens) - 1:
        raise PackageGraphError(f"{label} has trailing or nested dynamic syntax")
    return tokens[0].value, _named_arguments(tokens[2:-1], label)


def _array(tokens: list[_Token], label: str) -> list[list[_Token]]:
    concatenated = _split(tokens, "+", label)
    if len(concatenated) > 1:
        result: list[list[_Token]] = []
        for index, item in enumerate(concatenated):
            result.extend(_array(item, f"{label} concatenation[{index}]"))
        return result
    if len(tokens) < 2 or tokens[0].value != "[" or tokens[-1].value != "]":
        raise PackageGraphError(f"{label} must be a static array literal")
    if len(tokens) == 2:
        return []
    return _split(tokens[1:-1], ",", label)


def _literal(tokens: list[_Token], label: str) -> str:
    if len(tokens) != 1:
        raise PackageGraphError(f"{label} must be one static string literal")
    return _decode_swift_string(tokens[0], label)


def _version_literal(tokens: list[_Token], label: str) -> str:
    if len(tokens) == 1:
        return _literal(tokens, label)
    if (
        len(tokens) < 7
        or tokens[0].kind != "identifier"
        or tokens[0].value != "Version"
        or tokens[1].value != "("
        or tokens[-1].value != ")"
    ):
        raise PackageGraphError(
            f"{label} must be a static string or Version integer literal"
        )
    parts = _split(tokens[2:-1], ",", label)
    if (
        len(parts) != 3
        or any(len(part) != 1 or part[0].kind != "number" for part in parts)
        or any(
            len(part[0].value) > 1 and part[0].value.startswith("0")
            for part in parts
        )
    ):
        raise PackageGraphError(
            f"{label} must be Version(major, minor, patch) integer literals"
        )
    return ".".join(part[0].value for part in parts)


def _literal_array(tokens: list[_Token], label: str) -> list[str]:
    return [
        _literal(item, f"{label}[{index}]")
        for index, item in enumerate(_array(tokens, label))
    ]


def _optional_literal(
    arguments: Mapping[str, list[_Token]], name: str, label: str
) -> str | None:
    value = arguments.get(name)
    return None if value is None else _literal(value, f"{label}.{name}")


def _parse_product(tokens: list[_Token], label: str) -> dict[str, Any]:
    kind, arguments = _call(tokens, label)
    if kind != "library":
        name = _optional_literal(arguments, "name", label)
        return {"kind": kind, "name": name}
    allowed = {"name", "targets", "type"}
    unknown = set(arguments) - allowed
    if unknown:
        raise PackageGraphError(
            f"{label} uses unsupported library arguments: {sorted(unknown)}"
        )
    name = _literal(arguments.get("name", []), f"{label}.name")
    targets = _literal_array(arguments.get("targets", []), f"{label}.targets")
    if not targets or len(set(targets)) != len(targets):
        raise PackageGraphError(f"{label} must name distinct library targets")
    library_type = "automatic"
    if "type" in arguments:
        raw = arguments["type"]
        if len(raw) != 2 or raw[0].value != "." or raw[1].kind != "identifier":
            raise PackageGraphError(f"{label}.type is not a static member")
        library_type = raw[1].value
        if library_type not in {"automatic", "static", "dynamic"}:
            raise PackageGraphError(
                f"{label} uses unsupported library type {library_type!r}"
            )
    return {
        "kind": "library",
        "library_type": library_type,
        "name": name,
        "targets": targets,
    }


def _parse_package_dependency(tokens: list[_Token], label: str) -> dict[str, Any]:
    kind, arguments = _call(tokens, label)
    if kind != "package":
        raise PackageGraphError(f"{label} is not a .package declaration")
    name = _optional_literal(arguments, "name", label)
    if "path" in arguments:
        if set(arguments) - {"name", "path"}:
            raise PackageGraphError(
                f"{label} mixes local and unsupported dependency arguments"
            )
        return {
            "kind": "local",
            "name": name,
            "path": _literal(arguments["path"], f"{label}.path"),
        }
    if "url" not in arguments:
        raise PackageGraphError(f"{label} has neither path nor url")
    requirement_keys = [
        key for key in ("exact", "from", "revision", "branch") if key in arguments
    ]
    if len(requirement_keys) != 1 or set(arguments) - {
        "name",
        "url",
        "traits",
        *requirement_keys,
    }:
        raise PackageGraphError(f"{label} needs one supported remote requirement")
    if "traits" in arguments:
        for index, item in enumerate(
            _array(arguments["traits"], f"{label}.traits")
        ):
            trait_kind, trait_arguments = _call(item, f"{label}.traits[{index}]")
            if trait_kind != "trait" or set(trait_arguments) != {
                "name",
                "condition",
            }:
                raise PackageGraphError(
                    f"{label}.traits[{index}] is not a static trait propagation"
                )
            name_value = _literal(
                trait_arguments["name"], f"{label}.traits[{index}].name"
            )
            condition_kind, condition_arguments = _call(
                trait_arguments["condition"],
                f"{label}.traits[{index}].condition",
            )
            if (
                condition_kind != "when"
                or set(condition_arguments) != {"traits"}
                or _literal_array(
                    condition_arguments["traits"],
                    f"{label}.traits[{index}].condition.traits",
                )
                != [name_value]
            ):
                raise PackageGraphError(
                    f"{label}.traits[{index}] has unsupported propagation semantics"
                )
    requirement = requirement_keys[0]
    return {
        "kind": "remote",
        "name": name,
        "requirement": {
            "kind": requirement,
            "value": _version_literal(
                arguments[requirement], f"{label}.{requirement}"
            ),
        },
        "url": _literal(arguments["url"], f"{label}.url"),
    }


def _appended_remote_dependencies(
    tokens: list[_Token],
    start: int,
    bindings: Mapping[str, list[_Token]],
    label: str,
) -> list[dict[str, Any]]:
    result: list[dict[str, Any]] = []
    index = start
    marker = ["package", ".", "dependencies", "+", "="]
    while index + len(marker) < len(tokens):
        if [item.value for item in tokens[index : index + len(marker)]] != marker:
            index += 1
            continue
        array_start = index + len(marker)
        if tokens[array_start].value != "[":
            raise PackageGraphError(
                f"{label} mutates package.dependencies with a non-array expression"
            )
        array_end = _matching_delimiter(
            tokens, array_start, f"{label} package.dependencies append"
        )
        expression = _expand_manifest_bindings(
            tokens[array_start : array_end + 1],
            bindings,
            f"{label} package.dependencies append",
        )
        for dependency_index, item in enumerate(
            _array(expression, f"{label} package.dependencies append")
        ):
            dependency = _parse_package_dependency(
                item,
                f"{label} package.dependencies append[{dependency_index}]",
            )
            # The hermetic profile has no SWIFTCI_USE_LOCAL_DEPS-style
            # environment. A local alternative therefore remains inactive;
            # if a selected target still names it, resolution fails closed.
            if dependency["kind"] == "remote":
                result.append(dependency)
        index = array_end + 1
    return result


def _static_member_array(tokens: list[_Token], label: str) -> list[str]:
    result: list[str] = []
    for index, item in enumerate(_array(tokens, label)):
        if (
            len(item) != 2
            or item[0].value != "."
            or item[1].kind != "identifier"
        ):
            raise PackageGraphError(f"{label}[{index}] is not a static member")
        result.append(item[1].value)
    return result


def _target_dependency_condition_active(tokens: list[_Token], label: str) -> bool:
    kind, arguments = _call(tokens, label)
    if kind != "when" or not arguments or set(arguments) - {"platforms", "traits"}:
        raise PackageGraphError(f"{label} uses an unsupported target condition")
    active = True
    if "platforms" in arguments:
        active = "macOS" in _static_member_array(
            arguments["platforms"], f"{label}.platforms"
        )
    if "traits" in arguments:
        # The hermetic Xcode profile enables no caller-selected package traits.
        _literal_array(arguments["traits"], f"{label}.traits")
        active = False
    return active


def _parse_target_dependency(
    tokens: list[_Token], label: str
) -> dict[str, Any] | None:
    if len(tokens) == 1 and tokens[0].kind == "string":
        return {"kind": "by_name", "name": _decode_swift_string(tokens[0], label)}
    kind, arguments = _call(tokens, label)
    if kind in {"byName", "target"}:
        if set(arguments) != {"name"}:
            raise PackageGraphError(
                f"{label} uses unsupported conditional target dependency"
            )
        return {
            "kind": "by_name" if kind == "byName" else "target",
            "name": _literal(arguments["name"], f"{label}.name"),
        }
    if kind in {"product", "productItem"}:
        fields = set(arguments)
        if kind == "product" and fields not in (
            {"name", "package"},
            {"name", "package", "condition"},
        ):
            raise PackageGraphError(
                f"{label} uses unsupported conditional product dependency"
            )
        if kind == "productItem" and fields != {"name", "package", "condition"}:
            raise PackageGraphError(
                f"{label} uses unsupported conditional product dependency"
            )
        if "condition" in arguments:
            condition = arguments["condition"]
            if (
                len(condition) == 1
                and condition[0].kind == "identifier"
                and condition[0].value == "nil"
            ):
                pass
            elif not _target_dependency_condition_active(
                condition, f"{label}.condition"
            ):
                return None
        return {
            "kind": "product",
            "name": _literal(arguments["name"], f"{label}.name"),
            "package": _literal(arguments["package"], f"{label}.package"),
        }
    raise PackageGraphError(f"{label} uses unsupported dependency expression .{kind}")


def _conditional_platform(tokens: list[_Token]) -> str | None:
    values = [token.value for token in tokens]
    marker = [".", "when", "(", "platforms", ":", "[", "."]
    for index in range(len(values) - len(marker) - 2):
        if values[index : index + len(marker)] == marker:
            platform = tokens[index + len(marker)]
            if (
                platform.kind == "identifier"
                and values[index + len(marker) + 1 : index + len(marker) + 3]
                == ["]", ")"]
            ):
                return platform.value
    return None


def _parse_swift_setting(
    tokens: list[_Token], label: str
) -> dict[str, str] | None:
    values = [token.value for token in tokens]
    if (
        len(tokens) == 6
        and values[0] == "."
        and values[1] == "swiftLanguageMode"
        and values[2] == "("
        and values[3] == "."
        and values[5] == ")"
        and tokens[4].kind == "identifier"
    ):
        modes = {"v4": "4", "v4_2": "4.2", "v5": "5", "v6": "6"}
        mode = modes.get(values[4])
        if mode is None:
            raise PackageGraphError(
                f"{label} uses unsupported Swift language mode {values[4]!r}"
            )
        return {"kind": "swift_language_mode", "value": mode}
    if values == [
        ".",
        "defaultIsolation",
        "(",
        "MainActor",
        ".",
        "self",
        ")",
    ]:
        return {"kind": "default_isolation", "value": "MainActor"}
    if (
        len(tokens) == 5
        and values[:3] == [".", "enableExperimentalFeature", "("]
        and values[-1] == ")"
        and tokens[3].kind == "string"
    ):
        feature = _decode_swift_string(tokens[3], label)
        if feature == "StrictConcurrency":
            return {"kind": "experimental_feature", "value": feature}
    if values[:3] == [".", "unsafeFlags", "("]:
        platform = _conditional_platform(tokens)
        if platform == "windows":
            return None
    if values[:3] == [".", "define", "("]:
        platform = _conditional_platform(tokens)
        if platform is not None and platform != "macOS":
            return None
        if (
            len(tokens) == 5
            and tokens[3].kind == "string"
            and values[4] == ")"
        ):
            return {
                "kind": "define",
                "value": _decode_swift_string(tokens[3], label),
            }
    raise PackageGraphError(f"{label} uses an unsupported Swift setting")


def _parse_c_family_setting(
    tokens: list[_Token], label: str
) -> dict[str, Any] | None:
    values = [token.value for token in tokens]
    if (
        len(tokens) == 5
        and values[:3] == [".", "headerSearchPath", "("]
        and values[-1] == ")"
        and tokens[3].kind == "string"
    ):
        return {
            "kind": "header_search_path",
            "path": _decode_swift_string(tokens[3], f"{label}.path"),
        }
    if len(tokens) < 5 or values[:3] != [".", "define", "("] or values[-1] != ")":
        raise PackageGraphError(f"{label} uses an unsupported C-family setting")
    arguments = _split(tokens[3:-1], ",", label)
    if not arguments or len(arguments[0]) != 1:
        raise PackageGraphError(f"{label} uses an unsupported C-family define")
    name = _decode_swift_string(arguments[0][0], f"{label}.name")
    if _IDENTIFIER.fullmatch(name) is None or not name.isascii():
        raise PackageGraphError(f"{label}.name is not a portable C identifier")
    value: str | None = None
    condition: list[_Token] | None = None
    for argument in arguments[1:]:
        if (
            len(argument) >= 4
            and argument[0].value == "."
            and argument[1].kind == "identifier"
            and argument[1].value == "when"
        ):
            if condition is not None:
                raise PackageGraphError(f"{label} repeats C define condition")
            condition = argument
            continue
        if (
            len(argument) < 3
            or argument[0].kind != "identifier"
            or argument[1].value != ":"
        ):
            raise PackageGraphError(f"{label} uses an unsupported C-family define")
        if argument[0].value == "to" and len(argument) == 3:
            if value is not None:
                raise PackageGraphError(f"{label} repeats C define value")
            value = _decode_swift_string(argument[2], f"{label}.value")
            if any(character in value for character in "\0\r\n"):
                raise PackageGraphError(f"{label}.value contains a control character")
        elif argument[0].value == "condition":
            if condition is not None:
                raise PackageGraphError(f"{label} repeats C define condition")
            condition = argument[2:]
        else:
            raise PackageGraphError(f"{label} uses an unsupported C-family define")
    if condition is not None and not _target_dependency_condition_active(
        condition, f"{label}.condition"
    ):
        return None
    return {"kind": "define", "name": name, "value": value}


def _c_family_setting_arguments(
    raw_settings: Any,
    label: str,
    *,
    staged_target_root: Path | None = None,
) -> list[str]:
    arguments: list[str] = []
    seen: set[tuple[str, str]] = set()
    for index, raw in enumerate(_list(raw_settings, label)):
        setting = _mapping(raw, f"{label}[{index}]")
        kind = _string(setting.get("kind"), f"{label}[{index}].kind")
        if kind == "define":
            if set(setting) != {"kind", "name", "value"}:
                raise PackageGraphError(f"{label}[{index}] has unsupported fields")
            name = _string(setting.get("name"), f"{label}[{index}].name")
            if _IDENTIFIER.fullmatch(name) is None or not name.isascii():
                raise PackageGraphError(
                    f"{label}[{index}].name is not a portable C identifier"
                )
            value = setting.get("value")
            if value is not None:
                if not isinstance(value, str) or any(
                    character in value for character in "\0\r\n"
                ):
                    raise PackageGraphError(
                        f"{label}[{index}].value is not a safe C define value"
                    )
            identity = (kind, name)
            if identity in seen:
                raise PackageGraphError(f"{label} repeats C define {name!r}")
            seen.add(identity)
            arguments.append(f"-D{name}" if value is None else f"-D{name}={value}")
            continue
        if kind == "header_search_path":
            if set(setting) != {"kind", "path"}:
                raise PackageGraphError(f"{label}[{index}] has unsupported fields")
            relative = _safe_stored_relative(
                _string(setting.get("path"), f"{label}[{index}].path"),
                f"{label}[{index}].path",
            )
            identity = (kind, _portable(relative.as_posix()))
            if identity in seen:
                raise PackageGraphError(
                    f"{label} repeats header search path {relative.as_posix()!r}"
                )
            seen.add(identity)
            if staged_target_root is not None:
                arguments.append(
                    "-I" + os.fspath(staged_target_root / "headers" / relative)
                )
            continue
        raise PackageGraphError(f"{label}[{index}] has unsupported kind {kind!r}")
    return arguments


def _parse_resource(tokens: list[_Token], label: str) -> dict[str, str]:
    values = [token.value for token in tokens]
    if (
        len(tokens) != 5
        or values[0] != "."
        or tokens[1].kind != "identifier"
        or values[1] not in {"copy", "process"}
        or values[2] != "("
        or values[4] != ")"
        or tokens[3].kind != "string"
    ):
        raise PackageGraphError(f"{label} uses an unsupported resource expression")
    return {
        "kind": values[1],
        "path": _decode_swift_string(tokens[3], f"{label}.path"),
    }


def _swift_setting_arguments(
    raw_settings: Any, label: str
) -> list[str]:
    arguments: list[str] = []
    seen: set[tuple[str, str]] = set()
    singleton_kinds: set[str] = set()
    for index, raw in enumerate(_list(raw_settings, label)):
        setting = _mapping(raw, f"{label}[{index}]")
        if set(setting) != {"kind", "value"}:
            raise PackageGraphError(
                f"{label}[{index}] has unsupported fields"
            )
        kind = _string(setting.get("kind"), f"{label}[{index}].kind")
        value = _string(setting.get("value"), f"{label}[{index}].value")
        identity = (kind, value)
        if identity in seen:
            raise PackageGraphError(f"{label} repeats {kind!r} value {value!r}")
        seen.add(identity)
        if kind == "swift_language_mode" and value in {"4", "4.2", "5", "6"}:
            if kind in singleton_kinds:
                raise PackageGraphError(f"{label} repeats {kind!r}")
            singleton_kinds.add(kind)
            arguments.extend(["-swift-version", value])
        elif kind == "default_isolation" and value == "MainActor":
            if kind in singleton_kinds:
                raise PackageGraphError(f"{label} repeats {kind!r}")
            singleton_kinds.add(kind)
            arguments.extend(["-default-isolation", "MainActor"])
        elif kind == "experimental_feature" and value == "StrictConcurrency":
            arguments.extend(["-enable-experimental-feature", value])
        elif kind == "define" and re.fullmatch(r"[A-Za-z_][A-Za-z0-9_]*", value):
            arguments.extend(["-D", value])
        else:
            raise PackageGraphError(
                f"{label}[{index}] has unsupported {kind!r} value {value!r}"
            )
    return arguments


def _parse_target(tokens: list[_Token], label: str) -> dict[str, Any]:
    kind, arguments = _call(tokens, label)
    name = _optional_literal(arguments, "name", label)
    if name is None:
        raise PackageGraphError(f"{label} has no static name")
    if kind != "target":
        return {"kind": kind, "name": name}
    allowed = {
        "name",
        "dependencies",
        "path",
        "exclude",
        "sources",
        "swiftSettings",
        "resources",
        "cSettings",
        "cxxSettings",
        "publicHeadersPath",
    }
    unknown = set(arguments) - allowed
    if unknown:
        raise PackageGraphError(
            f"{label} target {name!r} uses unsupported arguments: {sorted(unknown)}"
        )
    dependencies = []
    for index, item in enumerate(
        _array(
            arguments.get(
                "dependencies",
                [_Token("punctuation", "[", 0), _Token("punctuation", "]", 0)],
            ),
            f"{label}.dependencies",
        )
    ):
        dependency = _parse_target_dependency(
            item, f"{label}.dependencies[{index}]"
        )
        if dependency is not None:
            dependencies.append(dependency)
    swift_settings = []
    for index, item in enumerate(
        _array(
            arguments.get(
                "swiftSettings",
                [_Token("punctuation", "[", 0), _Token("punctuation", "]", 0)],
            ),
            f"{label}.swiftSettings",
        )
    ):
        setting = _parse_swift_setting(item, f"{label}.swiftSettings[{index}]")
        if setting is not None:
            swift_settings.append(setting)
    _swift_setting_arguments(swift_settings, f"{label}.swiftSettings")
    c_settings = []
    for index, item in enumerate(
        _array(
            arguments.get(
                "cSettings",
                [_Token("punctuation", "[", 0), _Token("punctuation", "]", 0)],
            ),
            f"{label}.cSettings",
        )
    ):
        setting = _parse_c_family_setting(item, f"{label}.cSettings[{index}]")
        if setting is not None:
            c_settings.append(setting)
    cxx_settings = []
    for index, item in enumerate(
        _array(
            arguments.get(
                "cxxSettings",
                [_Token("punctuation", "[", 0), _Token("punctuation", "]", 0)],
            ),
            f"{label}.cxxSettings",
        )
    ):
        setting = _parse_c_family_setting(item, f"{label}.cxxSettings[{index}]")
        if setting is not None:
            cxx_settings.append(setting)
    _c_family_setting_arguments(c_settings, f"{label}.cSettings")
    _c_family_setting_arguments(cxx_settings, f"{label}.cxxSettings")
    return {
        "c_settings": c_settings,
        "cxx_settings": cxx_settings,
        "dependencies": dependencies,
        "exclude": (
            _literal_array(arguments["exclude"], f"{label}.exclude")
            if "exclude" in arguments
            else []
        ),
        "kind": "target",
        "name": name,
        "path": _optional_literal(arguments, "path", label),
        "resources": [
            _parse_resource(item, f"{label}.resources[{index}]")
            for index, item in enumerate(
                _array(
                    arguments.get(
                        "resources",
                        [
                            _Token("punctuation", "[", 0),
                            _Token("punctuation", "]", 0),
                        ],
                    ),
                    f"{label}.resources",
                )
            )
        ],
        "public_headers_path": _optional_literal(
            arguments, "publicHeadersPath", label
        ),
        "sources": (
            _literal_array(arguments["sources"], f"{label}.sources")
            if "sources" in arguments
            else None
        ),
        "swift_settings": swift_settings,
    }


def _parse_manifest(
    data: bytes, label: str, manifest_root: Path | None = None
) -> dict[str, Any]:
    try:
        text = data.decode("utf-8")
    except UnicodeDecodeError as exc:
        raise PackageGraphError(f"{label} is not UTF-8: {exc}") from exc
    text = _preprocess_manifest_conditions(text, label)
    tokens = _tokenize(text, label)
    candidates: list[int] = []
    delimiter_depth = 0
    for index in range(len(tokens) - 4):
        token = tokens[index]
        if [token.value for token in tokens[index : index + 5]] == [
            "let",
            "package",
            "=",
            "Package",
            "(",
        ] and delimiter_depth == 0:
            candidates.append(index)
        if token.value in "([{":
            delimiter_depth += 1
        elif token.value in ")]}":
            delimiter_depth -= 1
            if delimiter_depth < 0:
                raise PackageGraphError(f"{label} has unbalanced delimiters")
    if len(candidates) != 1:
        raise PackageGraphError(
            f"{label} must contain exactly one static 'let package = Package(...)'"
        )
    start = candidates[0] + 3
    depth = 0
    end = -1
    for index in range(start + 1, len(tokens)):
        if tokens[index].value == "(":
            depth += 1
        elif tokens[index].value == ")":
            depth -= 1
            if depth == 0:
                end = index
                break
    if end < 0:
        raise PackageGraphError(f"{label} Package call is unbalanced")
    bindings = _static_manifest_bindings(
        tokens, candidates[0], label, manifest_root
    )
    package_tokens = _expand_manifest_bindings(
        tokens[start : end + 1], bindings, f"{label} Package"
    )
    if any(token.value == "#" for token in package_tokens):
        raise PackageGraphError(
            f"{label} Package expression uses unsupported macro syntax"
        )
    _, arguments = _call(package_tokens, f"{label} Package")
    name = _literal(arguments.get("name", []), f"{label} Package.name")
    products = [
        _parse_product(item, f"{label} products[{index}]")
        for index, item in enumerate(
            _array(
                arguments.get(
                    "products",
                    [_Token("punctuation", "[", 0), _Token("punctuation", "]", 0)],
                ),
                f"{label} products",
            )
        )
    ]
    dependencies = [
        _parse_package_dependency(item, f"{label} dependencies[{index}]")
        for index, item in enumerate(
            _array(
                arguments.get(
                    "dependencies",
                    [_Token("punctuation", "[", 0), _Token("punctuation", "]", 0)],
                ),
                f"{label} dependencies",
            )
        )
    ]
    dependencies.extend(
        _appended_remote_dependencies(tokens, end + 1, bindings, label)
    )
    targets = [
        _parse_target(item, f"{label} targets[{index}]")
        for index, item in enumerate(
            _array(arguments.get("targets", []), f"{label} targets")
        )
    ]
    for collection, collection_label in ((products, "product"), (targets, "target")):
        seen: set[str] = set()
        for item in collection:
            item_name = item.get("name")
            if item_name is None:
                continue
            key = _portable(item_name)
            if key in seen:
                raise PackageGraphError(
                    f"{label} repeats {collection_label} name {item_name!r}"
                )
            seen.add(key)
    return {
        "dependencies": dependencies,
        "name": name,
        "products": products,
        "targets": targets,
    }


def _package_identity(dependency: Mapping[str, Any]) -> str:
    if dependency.get("name"):
        return _portable(_string(dependency["name"], "package dependency name"))
    location = _string(dependency.get("url"), "package dependency url").rstrip("/")
    basename = location.rsplit("/", 1)[-1]
    if basename.lower().endswith(".git"):
        basename = basename[:-4]
    if not basename:
        raise PackageGraphError(f"cannot derive package identity from {location!r}")
    return _portable(basename)


def _inventory_remote_requirement(raw: Any, label: str) -> dict[str, str]:
    requirement = _mapping(raw, label)
    kind = _string(requirement.get("kind"), f"{label}.kind")
    if kind in {"revision", "branch"}:
        native_fields = {"kind", kind}
        canonical_fields = {"kind", "value"}
        fields = set(requirement)
        if fields == native_fields:
            value_key = kind
        elif fields == canonical_fields:
            value_key = "value"
        else:
            raise PackageGraphError(f"{label} has unsupported requirement fields")
        return {
            "kind": kind,
            "value": _string(requirement.get(value_key), f"{label}.{value_key}"),
        }
    shapes = {
        "upToNextMajorVersion": ("minimumVersion", "from"),
        "exactVersion": ("version", "exact"),
        # Canonical graph verification reconstructs this already-normalized
        # spelling instead of inventing an Xcode object shape.
        "from": ("value", "from"),
        "exact": ("value", "exact"),
    }
    shape = shapes.get(kind)
    if shape is None:
        raise PackageGraphError(
            f"{label} uses unsupported Xcode package requirement {kind!r}"
        )
    value_key, normalized_kind = shape
    if set(requirement) != {"kind", value_key}:
        raise PackageGraphError(f"{label} has unsupported requirement fields")
    return {
        "kind": normalized_kind,
        "value": _string(requirement.get(value_key), f"{label}.{value_key}"),
    }


def _dependency_matches(dependency: Mapping[str, Any], value: str) -> bool:
    names = []
    if dependency.get("name"):
        names.append(_string(dependency["name"], "package dependency name"))
    if dependency.get("kind") == "remote":
        names.append(_package_identity(dependency))
    else:
        names.append(
            PurePosixPath(
                _string(dependency.get("resolved_path"), "local dependency path")
            ).name
        )
        names.append(
            _string(dependency.get("package_name"), "local dependency package name")
        )
    return _portable(value) in {_portable(name) for name in names}


class _Planner:
    def __init__(
        self,
        inventory: dict[str, Any],
        source_root: Path,
        remote_materializations: Mapping[str, dict[str, Any]] | None = None,
        remote_materialization_set: dict[str, Any] | None = None,
        remote_cache_root: Path | None = None,
        source_external_graph: dict[str, Any] | None = None,
    ):
        self.inventory = inventory
        self.root = _strict_root(source_root)
        self.packages: dict[str, dict[str, Any]] = {}
        self.package_names: dict[str, str] = {}
        self.target_state: dict[str, int] = {}
        self.reachable: dict[str, dict[str, Any]] = {}
        self.external_consumers: list[dict[str, Any]] = []
        self.remote_materializations = dict(remote_materializations or {})
        self.remote_materialization_set = remote_materialization_set
        self.remote_cache_root = remote_cache_root
        self.remote_packages: dict[str, dict[str, Any]] = {}
        self.top_level_remote_declarations: list[tuple[str, dict[str, Any], str]] = []
        self.source_external_graph = source_external_graph

    def _register_package(
        self,
        *,
        graph_path: str,
        filesystem_root: Path,
        manifest_relative: str,
        origin: str,
        source_prefix: str,
        materialization: dict[str, Any] | None,
        label: str,
    ) -> dict[str, Any]:
        if graph_path in self.packages:
            return self.packages[graph_path]
        manifest_record = _file_record(
            filesystem_root, manifest_relative, f"{label} manifest"
        )
        parsed = _parse_manifest(
            (filesystem_root / manifest_relative).read_bytes(),
            f"{label} {manifest_relative}",
            filesystem_root,
        )
        targets = {item["name"]: item for item in parsed["targets"]}
        products = {
            item["name"]: item for item in parsed["products"] if item.get("name")
        }
        for product in products.values():
            if product["kind"] != "library":
                continue
            for target in product["targets"]:
                if target not in targets:
                    raise PackageGraphError(
                        f"{manifest_relative} product {product['name']!r} names missing target {target!r}"
                    )
        package_key = _portable(parsed["name"])
        previous = self.package_names.get(package_key)
        if previous is not None and previous != graph_path:
            raise PackageGraphError(
                f"duplicate package name {parsed['name']!r} at {previous!r} and {graph_path!r}"
            )
        self.package_names[package_key] = graph_path
        model = {
            "dependencies": parsed["dependencies"],
            "filesystem_root": filesystem_root,
            "manifest": manifest_record,
            "materialization": materialization,
            "name": parsed["name"],
            "origin": origin,
            "path": graph_path,
            "products": products,
            "source_prefix": source_prefix,
            "targets": targets,
        }
        self.packages[graph_path] = model
        return model

    def load_package(self, relative_value: str, label: str) -> dict[str, Any]:
        relative = _safe_stored_relative(relative_value, label).as_posix()
        if relative in self.packages:
            return self.packages[relative]
        directory = _ordinary(self.root, PurePosixPath(relative), label)
        if not directory.is_dir():
            raise PackageGraphError(
                f"{label} is not an ordinary directory: {directory}"
            )
        manifest_relative = f"{relative}/Package.swift"
        model = self._register_package(
            graph_path=relative,
            filesystem_root=self.root,
            manifest_relative=manifest_relative,
            origin="local",
            source_prefix=relative,
            materialization=None,
            label=label,
        )
        dependency_identities: set[tuple[str, str]] = set()
        for index, dependency in enumerate(model["dependencies"]):
            if dependency["kind"] != "local":
                dependency["identity"] = _package_identity(dependency)
                identity = ("remote", f"{dependency['identity']}\0{dependency['url']}")
            else:
                resolved = _resolve_local_dependency(
                    self.root,
                    relative,
                    dependency["path"],
                    f"{manifest_relative} dependencies[{index}].path",
                )
                dependency["resolved_path"] = resolved
                child = self.load_package(
                    resolved, f"{manifest_relative} local dependency"
                )
                dependency["package_name"] = child["name"]
                identity = ("local", resolved)
            if identity in dependency_identities:
                raise PackageGraphError(
                    f"{manifest_relative} repeats package dependency {identity[1]!r}"
                )
            dependency_identities.add(identity)
        return model

    def load_remote_package(
        self, identity: str, materialization: dict[str, Any]
    ) -> dict[str, Any]:
        if self.remote_cache_root is None:
            raise PackageGraphError("remote package cache root was not supplied")
        try:
            import remote_package_materializer

            repository = remote_package_materializer.repository_for(
                self.remote_cache_root, materialization
            )
        except (OSError, remote_package_materializer.MaterializationError) as exc:
            raise PackageGraphError(
                f"cannot bind remote package {identity!r}: {exc}"
            ) from exc
        revision = _string(
            materialization.get("commit"), "remote materialization commit"
        )
        graph_path = f"@remote/{identity}/{revision}"
        model = self._register_package(
            graph_path=graph_path,
            filesystem_root=repository,
            manifest_relative="Package.swift",
            origin="remote",
            source_prefix="",
            materialization=materialization,
            label=f"remote package {identity!r}",
        )
        if model["dependencies"]:
            for dependency in model["dependencies"]:
                if dependency["kind"] == "local":
                    raise PackageGraphError(
                        f"remote package {identity!r} declares unsupported local-path dependency"
                    )
                dependency["identity"] = _package_identity(dependency)
        # SwiftPM identity is derived from the package location (or an explicit
        # dependency alias), not from Package.name. Real packages such as
        # purchases-ios-spm legitimately publish a different manifest name.
        # URL, identity, revision, and tree are already bound by the verified
        # materialization descriptor, so requiring name equality would reject
        # valid source without strengthening the trust boundary.
        self.remote_packages[identity] = model
        return model

    def _target_id(self, package: Mapping[str, Any], name: str) -> str:
        package_path = _string(package.get("path"), "package path")
        if "#" in package_path:
            raise PackageGraphError(
                f"package path cannot form a stable target identity: {package_path!r}"
            )
        if (
            not name.isascii()
            or re.fullmatch(r"[A-Za-z_][A-Za-z0-9_.-]*", name) is None
        ):
            raise PackageGraphError(
                f"reachable target has a nonportable name: {name!r}"
            )
        return f"{package_path}#{name}"

    @staticmethod
    def _module_name(target_name: str) -> str:
        # SwiftPM exposes Clang targets through a C99 identifier derived by
        # replacing punctuation (notably cmark-gfm's hyphen) with underscores.
        module = re.sub(r"[^A-Za-z0-9_]", "_", target_name)
        if module and module[0].isdigit():
            module = "_" + module
        if not module or _IDENTIFIER.fullmatch(module) is None:
            raise PackageGraphError(
                f"target name has no portable C99 module identity: {target_name!r}"
            )
        return module

    def _product_targets(
        self, package: Mapping[str, Any], product_name: str, label: str
    ) -> list[str]:
        product = package["products"].get(product_name)
        if product is None:
            raise PackageGraphError(
                f"{label} names missing product {product_name!r} in package {package['name']!r}"
            )
        if product["kind"] != "library":
            raise PackageGraphError(
                f"{label} selects unsupported product kind .{product['kind']}"
            )
        return list(product["targets"])

    def _local_dependency_packages(
        self, package: Mapping[str, Any]
    ) -> list[tuple[dict[str, Any], dict[str, Any]]]:
        result = []
        for dependency in package["dependencies"]:
            if dependency["kind"] == "local":
                result.append((dependency, self.packages[dependency["resolved_path"]]))
        return result

    def _resolve_dependency(
        self,
        package: dict[str, Any],
        target: dict[str, Any],
        dependency: dict[str, Any],
    ) -> list[dict[str, Any]]:
        label = f"target {package['name']}.{target['name']} dependency {dependency['name']!r}"
        if dependency["kind"] == "target":
            if dependency["name"] not in package["targets"]:
                raise PackageGraphError(f"{label} names a missing local target")
            return [
                {
                    "kind": "target",
                    "target_id": self._target_id(package, dependency["name"]),
                }
            ]

        if dependency["kind"] == "product":
            matches: list[tuple[dict[str, Any], dict[str, Any]]] = []
            for declaration, child in self._local_dependency_packages(package):
                if _dependency_matches(declaration, dependency["package"]):
                    matches.append((declaration, child))
            remote = [
                declaration
                for declaration in package["dependencies"]
                if declaration["kind"] == "remote"
                and _dependency_matches(declaration, dependency["package"])
            ]
            if len(matches) + len(remote) != 1:
                raise PackageGraphError(
                    f"{label} package identity must resolve exactly once"
                )
            if remote:
                materialized = self.remote_packages.get(remote[0]["identity"])
                if materialized is not None:
                    return [
                        {
                            "kind": "product_target",
                            "product": dependency["name"],
                            "target_id": self._target_id(materialized, name),
                        }
                        for name in self._product_targets(
                            materialized, dependency["name"], label
                        )
                    ]
                return [
                    {
                        "kind": "external_product",
                        "package_identity": remote[0]["identity"],
                        "product": dependency["name"],
                        "url": remote[0]["url"],
                    }
                ]
            _, child = matches[0]
            return [
                {
                    "kind": "product_target",
                    "product": dependency["name"],
                    "target_id": self._target_id(child, name),
                }
                for name in self._product_targets(child, dependency["name"], label)
            ]

        if dependency["name"] in package["targets"]:
            return [
                {
                    "kind": "target",
                    "target_id": self._target_id(package, dependency["name"]),
                }
            ]
        local_matches: list[tuple[dict[str, Any], str]] = []
        for _, child in self._local_dependency_packages(package):
            if dependency["name"] in child["products"]:
                local_matches.append((child, dependency["name"]))
        remote_matches = [
            declaration
            for declaration in package["dependencies"]
            if declaration["kind"] == "remote"
            and _dependency_matches(declaration, dependency["name"])
        ]
        if len(local_matches) + len(remote_matches) != 1:
            raise PackageGraphError(
                f"{label} must resolve exactly once; use an explicit .product dependency"
            )
        if remote_matches:
            remote = remote_matches[0]
            materialized = self.remote_packages.get(remote["identity"])
            if materialized is not None:
                return [
                    {
                        "kind": "product_target",
                        "product": dependency["name"],
                        "target_id": self._target_id(materialized, name),
                    }
                    for name in self._product_targets(
                        materialized, dependency["name"], label
                    )
                ]
            return [
                {
                    "kind": "external_product",
                    "package_identity": remote["identity"],
                    "product": dependency["name"],
                    "url": remote["url"],
                }
            ]
        child, product = local_matches[0]
        return [
            {
                "kind": "product_target",
                "product": product,
                "target_id": self._target_id(child, name),
            }
            for name in self._product_targets(child, product, label)
        ]

    def resolve_target(self, package: dict[str, Any], target_name: str) -> None:
        target_id = self._target_id(package, target_name)
        state = self.target_state.get(target_id, 0)
        if state:
            return
        target = package["targets"].get(target_name)
        if target is None:
            raise PackageGraphError(f"reachable target is missing: {target_id}")
        if target["kind"] != "target":
            raise PackageGraphError(
                f"reachable target {target_id} uses unsupported kind .{target['kind']}"
            )
        self.target_state[target_id] = 1
        edges: list[dict[str, Any]] = []
        seen: set[tuple[str, str]] = set()
        for dependency in target["dependencies"]:
            for edge in self._resolve_dependency(package, target, dependency):
                key = (
                    edge["kind"],
                    edge.get(
                        "target_id",
                        f"{edge.get('package_identity')}#{edge.get('product')}",
                    ),
                )
                if key in seen:
                    raise PackageGraphError(
                        f"target {target_id} repeats dependency edge {key[1]!r}"
                    )
                seen.add(key)
                edges.append(edge)
                if "target_id" in edge:
                    child_package_path, child_target = edge["target_id"].split("#", 1)
                    self.resolve_target(self.packages[child_package_path], child_target)
                else:
                    self.external_consumers.append(
                        {
                            "consumer_target": target_id,
                            "package_identity": edge["package_identity"],
                            "product": edge["product"],
                            "url": edge["url"],
                        }
                    )
        self.reachable[target_id] = {
            "dependencies": edges,
            "module": self._module_name(target_name),
            "package": package,
            "target": target,
            "target_id": target_id,
        }
        self.target_state[target_id] = 2

    def _topological_ids(self) -> list[str]:
        indegree = {target_id: 0 for target_id in self.reachable}
        consumers: dict[str, list[str]] = {
            target_id: [] for target_id in self.reachable
        }
        for consumer, model in self.reachable.items():
            for edge in model["dependencies"]:
                dependency = edge.get("target_id")
                if dependency is None:
                    continue
                if dependency not in indegree:
                    raise PackageGraphError(
                        f"target graph has an unresolved edge to {dependency}"
                    )
                indegree[consumer] += 1
                consumers[dependency].append(consumer)
        ready = sorted(
            (key for key, value in indegree.items() if value == 0),
            key=lambda item: item.encode("utf-8"),
        )
        ordered: list[str] = []
        while ready:
            current = ready.pop(0)
            ordered.append(current)
            for consumer in sorted(
                consumers[current], key=lambda item: item.encode("utf-8")
            ):
                indegree[consumer] -= 1
                if indegree[consumer] == 0:
                    ready.append(consumer)
                    ready.sort(key=lambda item: item.encode("utf-8"))
        if len(ordered) != len(indegree):
            cyclic = sorted(
                (key for key, value in indegree.items() if value),
                key=lambda item: item.encode("utf-8"),
            )
            raise PackageGraphError(
                f"local target dependency cycle: {' -> '.join(cyclic)}"
            )
        return ordered

    @staticmethod
    def _generated_module_map(module: str) -> bytes:
        return (
            f"module {module} {{\n"
            '    umbrella "."\n'
            "    export *\n"
            "}\n"
        ).encode("utf-8")

    def _target_files(self, model: Mapping[str, Any]) -> dict[str, Any]:
        package = model["package"]
        target = model["target"]
        filesystem_root = package["filesystem_root"]
        raw_path = target["path"] or f"Sources/{target['name']}"
        target_relative = _lexical_dependency_path(
            raw_path, f"target {model['target_id']} path"
        )
        if ".." in target_relative.parts:
            raise PackageGraphError(
                f"target {model['target_id']} path escapes its package"
            )
        source_prefix = package["source_prefix"]
        base_relative = (
            PurePosixPath(source_prefix) / target_relative
            if source_prefix
            else target_relative
        )
        base = _ordinary(
            filesystem_root,
            base_relative,
            f"target {model['target_id']} source root",
        )
        if not base.is_dir():
            raise PackageGraphError(
                f"target {model['target_id']} source root is not a directory"
            )

        excludes: list[PurePosixPath] = []
        for index, value in enumerate(target["exclude"]):
            excluded = _safe_stored_relative(
                value, f"target {model['target_id']} exclude[{index}]"
            )
            _ordinary(
                filesystem_root,
                base_relative / excluded,
                f"target {model['target_id']} exclude[{index}]",
            )
            excludes.append(excluded)

        def is_excluded(relative: PurePosixPath) -> bool:
            return any(
                relative == item or item in relative.parents for item in excludes
            )

        selected: list[PurePosixPath]
        if target["sources"] is None:
            selected = [PurePosixPath(".")]
        else:
            selected = []
            seen_selection: set[str] = set()
            for index, value in enumerate(target["sources"]):
                relative = _safe_stored_relative(
                    value, f"target {model['target_id']} sources[{index}]"
                )
                key = _portable(relative.as_posix())
                if key in seen_selection:
                    raise PackageGraphError(
                        f"target {model['target_id']} repeats or aliases source selection {value!r}"
                    )
                seen_selection.add(key)
                _ordinary(
                    filesystem_root,
                    base_relative / relative,
                    f"target {model['target_id']} sources[{index}]",
                )
                selected.append(relative)

        source_paths: list[PurePosixPath] = []

        def visit_sources(path: Path, relative: PurePosixPath) -> None:
            if relative != PurePosixPath(".") and is_excluded(relative):
                return
            metadata = path.lstat()
            if stat.S_ISLNK(metadata.st_mode):
                raise PackageGraphError(
                    f"target {model['target_id']} contains symlink {relative}"
                )
            if stat.S_ISREG(metadata.st_mode):
                if path.suffix == ".swift":
                    source_paths.append(relative)
                elif path.suffix in _CODE_EXTENSIONS:
                    source_paths.append(relative)
                return
            if not stat.S_ISDIR(metadata.st_mode):
                raise PackageGraphError(
                    f"target {model['target_id']} contains unsupported node {relative}"
                )
            for entry in sorted(
                os.scandir(path), key=lambda item: item.name.encode("utf-8")
            ):
                child = (
                    PurePosixPath(entry.name)
                    if relative == PurePosixPath(".")
                    else relative / entry.name
                )
                visit_sources(Path(entry.path), child)

        for selection in selected:
            visit_sources(
                base if selection == PurePosixPath(".") else base / selection, selection
            )
        source_paths.sort(key=lambda item: item.as_posix().encode("utf-8"))
        if not source_paths:
            raise PackageGraphError(
                f"reachable target {model['target_id']} has no Swift or C-family sources"
            )
        has_swift = any(path.suffix == ".swift" for path in source_paths)
        has_c_family = any(path.suffix in _CODE_EXTENSIONS for path in source_paths)
        if has_swift and has_c_family:
            raise PackageGraphError(
                f"reachable target {model['target_id']} mixes Swift and C-family sources"
            )
        target_type = "swift" if has_swift else "clang"
        if target_type == "swift" and (
            target["c_settings"]
            or target["cxx_settings"]
            or target["public_headers_path"] is not None
        ):
            raise PackageGraphError(
                f"Swift target {model['target_id']} declares C-family-only settings"
            )
        if target_type == "clang" and target["swift_settings"]:
            raise PackageGraphError(
                f"C-family target {model['target_id']} declares Swift-only settings"
            )

        source_records: list[dict[str, Any]] = []
        seen_paths: set[str] = set()
        for relative in source_paths:
            stored = (base_relative / relative).as_posix()
            key = _portable(stored)
            if key in seen_paths:
                raise PackageGraphError(
                    f"target {model['target_id']} repeats or aliases source {stored!r}"
                )
            seen_paths.add(key)
            record = _file_record(
                filesystem_root,
                stored,
                f"target {model['target_id']} source",
            )
            if self.source_external_graph is not None:
                record["source_origin"] = (
                    "application"
                    if package["origin"] == "local"
                    else f"remote:{package['materialization']['identity']}"
                )
            if target_type == "clang":
                record["language"] = _C_SOURCE_LANGUAGES[relative.suffix]
            source_records.append(record)

        if target_type == "swift":
            return {
                "headers": [],
                "module_map": None,
                "public_headers_path": None,
                "sources": source_records,
                "target_type": target_type,
            }

        public_relative = _lexical_dependency_path(
            target["public_headers_path"] or "include",
            f"target {model['target_id']} publicHeadersPath",
        )
        if ".." in public_relative.parts:
            raise PackageGraphError(
                f"target {model['target_id']} publicHeadersPath escapes its target"
            )
        public_directory = _ordinary(
            filesystem_root,
            base_relative / public_relative,
            f"target {model['target_id']} public headers",
        )
        if not public_directory.is_dir():
            raise PackageGraphError(
                f"target {model['target_id']} public headers path is not a directory"
            )
        for setting_index, setting in enumerate(
            [*target["c_settings"], *target["cxx_settings"]]
        ):
            if setting["kind"] != "header_search_path":
                continue
            relative = _safe_stored_relative(
                setting["path"],
                f"target {model['target_id']} header search path[{setting_index}]",
            )
            directory = _ordinary(
                filesystem_root,
                base_relative / relative,
                f"target {model['target_id']} header search path[{setting_index}]",
            )
            if not directory.is_dir():
                raise PackageGraphError(
                    f"target {model['target_id']} header search path is not a directory: {relative.as_posix()}"
                )

        header_paths: list[PurePosixPath] = []

        def visit_headers(path: Path, relative: PurePosixPath) -> None:
            if relative != PurePosixPath(".") and is_excluded(relative):
                return
            metadata = path.lstat()
            if stat.S_ISLNK(metadata.st_mode):
                raise PackageGraphError(
                    f"target {model['target_id']} contains symlink {relative}"
                )
            if stat.S_ISREG(metadata.st_mode):
                if path.suffix in _C_HEADER_EXTENSIONS:
                    header_paths.append(relative)
                return
            if not stat.S_ISDIR(metadata.st_mode):
                raise PackageGraphError(
                    f"target {model['target_id']} contains unsupported node {relative}"
                )
            for entry in sorted(
                os.scandir(path), key=lambda item: item.name.encode("utf-8")
            ):
                child = (
                    PurePosixPath(entry.name)
                    if relative == PurePosixPath(".")
                    else relative / entry.name
                )
                visit_headers(Path(entry.path), child)

        visit_headers(base, PurePosixPath("."))
        header_paths.sort(key=lambda item: item.as_posix().encode("utf-8"))
        header_records: list[dict[str, Any]] = []
        for relative in header_paths:
            stored = (base_relative / relative).as_posix()
            record = _file_record(
                filesystem_root,
                stored,
                f"target {model['target_id']} C-family header",
            )
            record["target_relative_path"] = relative.as_posix()
            if self.source_external_graph is not None:
                record["source_origin"] = (
                    "application"
                    if package["origin"] == "local"
                    else f"remote:{package['materialization']['identity']}"
                )
            header_records.append(record)

        module_map_relative = public_relative / "module.modulemap"
        module_map_path = base / module_map_relative
        if (
            not is_excluded(module_map_relative)
            and (module_map_path.exists() or module_map_path.is_symlink())
        ):
            module_map = _file_record(
                filesystem_root,
                (base_relative / module_map_relative).as_posix(),
                f"target {model['target_id']} module map",
            )
            module_map["kind"] = "source"
            if self.source_external_graph is not None:
                module_map["source_origin"] = (
                    "application"
                    if package["origin"] == "local"
                    else f"remote:{package['materialization']['identity']}"
                )
        else:
            generated = self._generated_module_map(model["module"])
            module_map = {
                "kind": "generated",
                "sha256": _sha256(generated),
                "size": len(generated),
            }
        return {
            "headers": header_records,
            "module_map": module_map,
            "public_headers_path": public_relative.as_posix(),
            "sources": source_records,
            "target_type": target_type,
        }

    def _target_resources(self, model: Mapping[str, Any]) -> list[dict[str, Any]]:
        """Freeze every byte selected by a SwiftPM resource rule.

        SwiftPM resolves resource paths relative to the target source root, but
        permits a declaration such as ``../Sources/PrivacyInfo.xcprivacy`` as
        long as it remains inside the package.  Store paths relative to the
        application or exact remote repository so the graph stays relocatable.
        ``copy`` preserves a selected directory wrapper; ``process`` exposes
        the directory's children at the resource-bundle root.  Asset catalogs
        intentionally remain source-form inputs for OpenUIKit's deterministic
        asset indexer.
        """

        package = model["package"]
        target = model["target"]
        if not target["resources"]:
            return []
        filesystem_root = package["filesystem_root"]
        raw_target_path = target["path"] or f"Sources/{target['name']}"
        target_relative = _lexical_dependency_path(
            raw_target_path, f"target {model['target_id']} path"
        )
        if ".." in target_relative.parts:
            raise PackageGraphError(
                f"target {model['target_id']} path escapes its package"
            )
        source_prefix = PurePosixPath(package["source_prefix"])
        package_floor = len(source_prefix.parts)
        base_relative = source_prefix / target_relative
        records: list[dict[str, Any]] = []
        destinations: dict[str, str] = {}

        def resolve(value: str, label: str) -> PurePosixPath:
            raw = _lexical_dependency_path(value, label)
            stack = list(base_relative.parts)
            for component in raw.parts:
                if component == "..":
                    if len(stack) <= package_floor:
                        raise PackageGraphError(
                            f"{label} escapes target package {package['name']!r}"
                        )
                    stack.pop()
                else:
                    stack.append(component)
            relative = PurePosixPath(*stack)
            _ordinary(filesystem_root, relative, label)
            return relative

        def add_file(
            input_relative: PurePosixPath,
            bundle_relative: PurePosixPath,
            rule: str,
            label: str,
        ) -> None:
            if not bundle_relative.parts or any(
                part in {"", ".", ".."} for part in bundle_relative.parts
            ):
                raise PackageGraphError(
                    f"{label} has an unsafe resource-bundle destination"
                )
            destination = bundle_relative.as_posix()
            key = _portable(destination)
            previous = destinations.get(key)
            if previous is not None:
                raise PackageGraphError(
                    f"target {model['target_id']} resource destination {destination!r} "
                    f"collides with {previous!r}"
                )
            destinations[key] = destination
            record = _file_record(filesystem_root, input_relative.as_posix(), label)
            record.update({"bundle_path": destination, "rule": rule})
            if self.source_external_graph is not None:
                record["source_origin"] = (
                    "application"
                    if package["origin"] == "local"
                    else f"remote:{package['materialization']['identity']}"
                )
            records.append(record)

        for index, declaration in enumerate(target["resources"]):
            label = f"target {model['target_id']} resources[{index}]"
            input_relative = resolve(declaration["path"], label)
            physical = _ordinary(filesystem_root, input_relative, label)
            metadata = physical.lstat()
            rule = declaration["kind"]
            if stat.S_ISLNK(metadata.st_mode):
                raise PackageGraphError(f"{label} traverses a symlink: {physical}")
            if stat.S_ISREG(metadata.st_mode):
                add_file(input_relative, PurePosixPath(physical.name), rule, label)
                continue
            if not stat.S_ISDIR(metadata.st_mode):
                raise PackageGraphError(
                    f"{label} is not a regular file or ordinary directory"
                )

            destination_root = (
                PurePosixPath(physical.name)
                if rule == "copy" or physical.name.endswith(".xcassets")
                else PurePosixPath()
            )
            found_file = False

            def visit(directory: Path, relative: PurePosixPath) -> None:
                nonlocal found_file
                for entry in sorted(
                    os.scandir(directory), key=lambda item: item.name.encode("utf-8")
                ):
                    child_relative = relative / entry.name
                    child = Path(entry.path)
                    child_metadata = child.lstat()
                    if stat.S_ISLNK(child_metadata.st_mode):
                        raise PackageGraphError(
                            f"{label} contains symlink {child_relative}"
                        )
                    if stat.S_ISDIR(child_metadata.st_mode):
                        visit(child, child_relative)
                    elif stat.S_ISREG(child_metadata.st_mode):
                        found_file = True
                        add_file(
                            input_relative / child_relative,
                            destination_root / child_relative,
                            rule,
                            label,
                        )
                    else:
                        raise PackageGraphError(
                            f"{label} contains unsupported node {child_relative}"
                        )

            visit(physical, PurePosixPath())
            if not found_file:
                raise PackageGraphError(f"{label} selects an empty directory")

        records.sort(key=lambda item: item["bundle_path"].encode("utf-8"))
        return records

    def _resolution_path(self) -> str | None:
        explicit = self.inventory.get("package_resolution")
        if explicit is not None:
            return _string(
                _mapping(explicit, "package_resolution").get("path"),
                "package_resolution.path",
            )
        project = self.inventory.get("project")
        if not isinstance(project, dict) or not isinstance(project.get("path"), str):
            return None
        project_path = PurePosixPath(project["path"])
        if (
            project_path.name != "project.pbxproj"
            or not project_path.parent.name.endswith(".xcodeproj")
        ):
            return None
        candidate = (
            project_path.parent
            / "project.xcworkspace/xcshareddata/swiftpm/Package.resolved"
        )
        physical = self.root / candidate
        if not physical.exists() and not physical.is_symlink():
            return None
        _ordinary(self.root, candidate, "workspace package resolution")
        return candidate.as_posix()

    def _pins(
        self, required: bool
    ) -> tuple[dict[str, Any] | None, list[dict[str, Any]]]:
        relative = self._resolution_path()
        if relative is None:
            if required:
                raise PackageGraphError(
                    "reachable remote packages require a workspace Package.resolved"
                )
            return None, []
        record = _file_record(self.root, relative, "workspace Package.resolved")
        root = _mapping(
            _json_no_duplicates((self.root / relative).read_bytes(), relative), relative
        )
        if root.get("version") not in {2, 3}:
            raise PackageGraphError(f"{relative} has unsupported format version")
        raw_pins = _list(root.get("pins"), f"{relative}.pins")
        pins: list[dict[str, Any]] = []
        identities: set[str] = set()
        locations: set[str] = set()
        for index, raw in enumerate(raw_pins):
            pin = _mapping(raw, f"{relative}.pins[{index}]")
            identity = _portable(
                _string(pin.get("identity"), f"{relative}.pins[{index}].identity")
            )
            location = _string(
                pin.get("location"), f"{relative}.pins[{index}].location"
            )
            state = _mapping(pin.get("state"), f"{relative}.pins[{index}].state")
            revision = _string(
                state.get("revision"), f"{relative}.pins[{index}].state.revision"
            )
            if not re.fullmatch(r"[0-9a-f]{40,64}", revision):
                raise PackageGraphError(
                    f"{relative}.pins[{index}] revision is not an immutable lowercase object id"
                )
            if identity in identities or _portable(location.rstrip("/")) in locations:
                raise PackageGraphError(f"{relative} repeats a package pin")
            identities.add(identity)
            locations.add(_portable(location.rstrip("/")))
            pins.append(
                {
                    "identity": identity,
                    "kind": _string(pin.get("kind"), f"{relative}.pins[{index}].kind"),
                    "location": location,
                    "revision": revision,
                    "version": state.get("version"),
                    "branch": state.get("branch"),
                }
            )
            if pins[-1]["kind"] != "remoteSourceControl":
                raise PackageGraphError(
                    f"{relative}.pins[{index}] has unsupported kind {pins[-1]['kind']!r}"
                )
        pins.sort(key=lambda item: item["identity"].encode("utf-8"))
        return record, pins

    def _validate_requirement(
        self, requirement: Mapping[str, str], pin: Mapping[str, Any], label: str
    ) -> None:
        kind = requirement["kind"]
        value = requirement["value"]
        if kind == "revision":
            if pin["revision"] != value:
                raise PackageGraphError(
                    f"{label} pin revision does not match manifest revision"
                )
            return
        if kind == "branch":
            if pin.get("branch") != value:
                raise PackageGraphError(
                    f"{label} pin branch does not match manifest branch"
                )
            return
        version = pin.get("version")
        if not isinstance(version, str):
            raise PackageGraphError(
                f"{label} version requirement has no pinned version"
            )
        wanted_match = _SEMVER.fullmatch(value)
        pinned_match = _SEMVER.fullmatch(version)
        if wanted_match is None or pinned_match is None:
            raise PackageGraphError(f"{label} uses an unsupported semantic version")
        wanted = tuple(int(item) for item in wanted_match.groups())
        pinned = tuple(int(item) for item in pinned_match.groups())
        if kind == "exact" and pinned != wanted:
            raise PackageGraphError(
                f"{label} exact version {value} resolved to {version}"
            )
        if kind == "from":
            if wanted[0] > 0:
                upper = (wanted[0] + 1, 0, 0)
            elif wanted[1] > 0:
                upper = (0, wanted[1] + 1, 0)
            else:
                upper = (0, 0, wanted[2] + 1)
            if not wanted <= pinned < upper:
                raise PackageGraphError(
                    f"{label} from-version {value} resolved outside its compatible range: {version}"
                )

    def build(self) -> dict[str, Any] | None:
        raw_products = self.inventory.get("package_products", [])
        products = _list(raw_products, "package_products")
        if not products:
            return None
        references = _list(
            self.inventory.get("local_package_references", []),
            "local_package_references",
        )
        for index, raw in enumerate(references):
            reference = _mapping(raw, f"local_package_references[{index}]")
            self.load_package(
                _string(
                    reference.get("relative_path"),
                    f"local_package_references[{index}].relative_path",
                ),
                f"local package reference[{index}]",
            )
        for identity, materialization in sorted(
            self.remote_materializations.items(),
            key=lambda item: item[0].encode("utf-8"),
        ):
            self.load_remote_package(identity, materialization)
        selected: list[dict[str, Any]] = []
        selected_keys: set[str] = set()
        for index, raw in enumerate(products):
            product = _mapping(raw, f"package_products[{index}]")
            name = _string(product.get("name"), f"package_products[{index}].name")
            key = _portable(name)
            if key in selected_keys:
                raise PackageGraphError(
                    f"selected package products repeat or alias {name!r}"
                )
            selected_keys.add(key)
            origin = product.get("origin", "local")
            if origin == "remote":
                url = _string(
                    product.get("repository_url"),
                    f"package_products[{index}].repository_url",
                )
                requirement = _inventory_remote_requirement(
                    product.get("requirement"),
                    f"package_products[{index}].requirement",
                )
                identity = _package_identity({"url": url})
                selected_record = {
                    "name": name,
                    "origin": "remote",
                    "package_identity": identity,
                    "repository_url": url,
                    "requirement": requirement,
                }
                materialized = self.remote_packages.get(identity)
                if materialized is None:
                    if self.source_external_graph is not None:
                        raise PackageGraphError(
                            f"selected remote product {name!r} has no verified materialization"
                        )
                    declaration = {
                        "identity": identity,
                        "name": None,
                        "requirement": requirement,
                        "url": url,
                    }
                    self.top_level_remote_declarations.append(
                        ("@application", declaration, identity)
                    )
                    self.external_consumers.append(
                        {
                            "consumer_target": "@application",
                            "package_identity": identity,
                            "product": name,
                            "url": url,
                        }
                    )
                    selected_record["target_ids"] = []
                else:
                    target_names = self._product_targets(
                        materialized,
                        name,
                        f"selected remote product {name!r}",
                    )
                    selected_record.update(
                        {
                            "package_path": materialized["path"],
                            "target_ids": [
                                self._target_id(materialized, target_name)
                                for target_name in target_names
                            ],
                        }
                    )
                    for target_name in target_names:
                        self.resolve_target(materialized, target_name)
                selected.append(selected_record)
                continue
            if origin != "local":
                raise PackageGraphError(
                    f"package_products[{index}] has unsupported origin {origin!r}"
                )
            relative = product.get("relative_path")
            candidates: list[dict[str, Any]]
            if relative is not None:
                candidates = [
                    self.load_package(
                        _string(relative, f"package_products[{index}].relative_path"),
                        f"selected product {name!r}",
                    )
                ]
            else:
                candidates = [
                    package
                    for package in self.packages.values()
                    if name in package["products"]
                ]
            candidates = [
                package for package in candidates if name in package["products"]
            ]
            if len(candidates) != 1:
                raise PackageGraphError(
                    f"selected local product {name!r} must resolve to exactly one package; candidates={len(candidates)}"
                )
            package = candidates[0]
            target_names = self._product_targets(
                package, name, f"selected product {name!r}"
            )
            target_ids = [
                self._target_id(package, target_name) for target_name in target_names
            ]
            selected.append(
                {
                    "name": name,
                    "package_path": package["path"],
                    "target_ids": target_ids,
                }
            )
            for target_name in target_names:
                self.resolve_target(package, target_name)

        ordered_ids = self._topological_ids()
        module_names: dict[str, str] = {}
        filesystem_paths: dict[str, tuple[str, tuple[int, int]]] = {}
        targets: list[dict[str, Any]] = []
        resource_bundles: dict[str, str] = {}
        for order, target_id in enumerate(ordered_ids):
            model = self.reachable[target_id]
            module = model["module"]
            module_key = _portable(module)
            previous = module_names.get(module_key)
            if previous is not None:
                raise PackageGraphError(
                    f"reachable targets {previous} and {target_id} emit duplicate module {module!r}"
                )
            module_names[module_key] = target_id
            resources = self._target_resources(model)
            target_files = self._target_files(model)
            sources = target_files["sources"]
            frozen_inputs = [*sources, *target_files["headers"], *resources]
            module_map = target_files["module_map"]
            if module_map is not None and module_map["kind"] == "source":
                frozen_inputs.append(module_map)
            for record in frozen_inputs:
                path = record["path"]
                source_origin = record.get("source_origin", "application")
                if source_origin == "application":
                    actual = self.root / path
                elif isinstance(source_origin, str) and source_origin.startswith(
                    "remote:"
                ):
                    identity = source_origin.split(":", 1)[1]
                    remote = self.remote_packages.get(identity)
                    if remote is None:
                        raise PackageGraphError(
                            f"source names missing remote package {identity!r}"
                        )
                    actual = remote["filesystem_root"] / path
                else:
                    raise PackageGraphError(
                        f"unsupported source origin {source_origin!r}"
                    )
                metadata = actual.stat()
                identity = (metadata.st_dev, metadata.st_ino)
                portable_path = _portable(path)
                previous_record = filesystem_paths.get(portable_path)
                if previous_record is not None:
                    raise PackageGraphError(
                        f"reachable targets repeat or alias frozen input {path!r}"
                    )
                for previous_path, previous_identity in filesystem_paths.values():
                    if previous_identity == identity:
                        raise PackageGraphError(
                            f"reachable targets inventory hard-linked inputs {previous_path!r} and {path!r}"
                        )
                filesystem_paths[portable_path] = (path, identity)
            target_record = {
                "dependencies": model["dependencies"],
                "module": module,
                "order": order,
                "package_path": model["package"]["path"],
                "sources": sources,
                "target_type": target_files["target_type"],
                "target_id": target_id,
            }
            if target_files["target_type"] == "swift" and model["target"]["swift_settings"]:
                target_record["swift_settings"] = model["target"]["swift_settings"]
            if resources:
                bundle_stem = (
                    f"{self._module_name(model['package']['name'])}_{module}"
                )
                bundle_name = f"{bundle_stem}.bundle"
                bundle_key = _portable(bundle_name)
                previous_bundle = resource_bundles.get(bundle_key)
                if previous_bundle is not None:
                    raise PackageGraphError(
                        f"reachable targets {previous_bundle} and {target_id} emit "
                        f"duplicate resource bundle {bundle_name!r}"
                    )
                resource_bundles[bundle_key] = target_id
                target_record["resource_bundle"] = bundle_name
                target_record["resources"] = resources
            if target_files["target_type"] == "clang":
                target_record.update(
                    {
                        "c_settings": model["target"]["c_settings"],
                        "cxx_settings": model["target"]["cxx_settings"],
                        "headers": target_files["headers"],
                        "module_map": target_files["module_map"],
                        "public_headers_path": target_files[
                            "public_headers_path"
                        ],
                    }
                )
            targets.append(target_record)

        reachable_package_paths = sorted(
            {model["package"]["path"] for model in self.reachable.values()},
            key=lambda item: item.encode("utf-8"),
        )
        package_records: list[dict[str, Any]] = []
        product_edges: list[dict[str, Any]] = []
        remote_declarations: list[tuple[str, dict[str, Any], str]] = list(
            self.top_level_remote_declarations
        )
        for path in reachable_package_paths:
            package = self.packages[path]
            local_dependencies = []
            remote_dependencies = []
            for dependency in package["dependencies"]:
                if dependency["kind"] == "local":
                    local_dependencies.append(
                        {
                            "declared_path": dependency["path"],
                            "package_path": dependency["resolved_path"],
                        }
                    )
                else:
                    declaration = {
                        "identity": dependency["identity"],
                        "name": dependency["name"],
                        "requirement": dependency["requirement"],
                        "url": dependency["url"],
                    }
                    remote_dependencies.append(declaration)
                    remote_declarations.append(
                        (path, dependency, dependency["identity"])
                    )
            package_record = {
                "local_dependencies": local_dependencies,
                "manifest": package["manifest"],
                "name": package["name"],
                "path": path,
                "remote_dependencies": remote_dependencies,
            }
            if self.source_external_graph is not None:
                package_record["origin"] = package["origin"]
                package_record["materialization"] = package["materialization"]
            package_records.append(package_record)
            for name, product in sorted(
                package["products"].items(), key=lambda item: item[0].encode("utf-8")
            ):
                if product["kind"] == "library":
                    product_edge = {
                        "library_type": product["library_type"],
                        "name": name,
                        "package_path": path,
                        "target_ids": [
                            self._target_id(package, target)
                            for target in product["targets"]
                        ],
                    }
                    if self.source_external_graph is not None:
                        product_edge["origin"] = package["origin"]
                    product_edges.append(product_edge)

        used_external = {
            (item["package_identity"], item["url"]) for item in self.external_consumers
        }
        declarations = [
            item
            for item in remote_declarations
            if (item[2], item[1]["url"]) in used_external
        ]
        resolution, pins = self._pins(bool(declarations))
        external: list[dict[str, Any]] = []
        for identity, url in sorted(
            used_external,
            key=lambda item: (item[0].encode("utf-8"), item[1].encode("utf-8")),
        ):
            matching_declarations = [
                item
                for item in declarations
                if item[2] == identity and item[1]["url"] == url
            ]
            pin_matches = [
                pin
                for pin in pins
                if pin["identity"] == identity
                and _portable(pin["location"].rstrip("/")) == _portable(url.rstrip("/"))
            ]
            if len(pin_matches) != 1:
                raise PackageGraphError(
                    f"remote package {identity!r} at {url!r} must have exactly one workspace pin"
                )
            pin = pin_matches[0]
            requirements = []
            for package_path, declaration, _ in matching_declarations:
                requirement = {
                    "package_path": package_path,
                    **declaration["requirement"],
                }
                self._validate_requirement(
                    declaration["requirement"], pin, f"remote package {identity!r}"
                )
                requirements.append(requirement)
            consumers = sorted(
                [
                    {
                        "consumer_target": item["consumer_target"],
                        "product": item["product"],
                    }
                    for item in self.external_consumers
                    if item["package_identity"] == identity and item["url"] == url
                ],
                key=lambda item: (
                    item["consumer_target"].encode("utf-8"),
                    item["product"].encode("utf-8"),
                ),
            )
            external.append(
                {
                    "consumers": consumers,
                    "identity": identity,
                    "materialization": None,
                    "pin": pin,
                    "requirements": requirements,
                    "url": url,
                }
            )

        target_edges = [
            {"consumer": target["target_id"], **edge}
            for target in targets
            for edge in target["dependencies"]
        ]
        result = {
            "buildability": {
                "reason": (
                    "remote-package-materialization-required" if external else None
                ),
                "status": "blocked" if external else "buildable",
            },
            "classification": "portable-local-swift-package-graph",
            "external_packages": external,
            "format_version": 2 if self.source_external_graph is not None else 1,
            "package_resolution": resolution,
            "packages": package_records,
            "product_edges": product_edges,
            "resolution_pins": pins,
            "selected_products": selected,
            "summary": {
                "external_packages": len(external),
                "local_packages": sum(
                    1
                    for package in package_records
                    if package.get("origin", "local") == "local"
                ),
                "local_products": sum(
                    1
                    for product in product_edges
                    if product.get("origin", "local") == "local"
                ),
                "local_targets": sum(
                    1
                    for target in targets
                    if not target["target_id"].startswith("@remote/")
                ),
                **(
                    {
                        "remote_packages": sum(
                            1
                            for package in package_records
                            if package.get("origin") == "remote"
                        ),
                        "remote_targets": sum(
                            1
                            for target in targets
                            if target["target_id"].startswith("@remote/")
                        ),
                        "remote_products": sum(
                            1
                            for product in product_edges
                            if product.get("origin") == "remote"
                        ),
                    }
                    if self.source_external_graph is not None
                    else {}
                ),
                "resolution_pins": len(pins),
                "selected_products": len(selected),
                "resource_bundles": sum(
                    "resource_bundle" in target for target in targets
                ),
                "resource_files": sum(
                    len(target.get("resources", [])) for target in targets
                ),
                "c_family_headers": sum(
                    len(target.get("headers", [])) for target in targets
                ),
                "c_family_sources": sum(
                    len(target["sources"])
                    for target in targets
                    if target["target_type"] == "clang"
                ),
                "clang_targets": sum(
                    target["target_type"] == "clang" for target in targets
                ),
                "swift_sources": sum(
                    len(target["sources"])
                    for target in targets
                    if target["target_type"] == "swift"
                ),
                "swift_targets": sum(
                    target["target_type"] == "swift" for target in targets
                ),
                "target_dependency_edges": len(target_edges),
            },
            "target_dependency_edges": target_edges,
            "targets": targets,
        }
        if self.source_external_graph is not None:
            result["remote_materializations"] = self.remote_materialization_set
            result["source_external_graph_sha256"] = _sha256(
                canonical_json(self.source_external_graph)
            )
        return result


def plan(
    inventory: dict[str, Any],
    source_root: Path,
    remote_materializations: dict[str, Any] | None = None,
    remote_cache_root: Path | None = None,
) -> dict[str, Any] | None:
    baseline = _Planner(inventory, source_root).build()
    if remote_materializations is None:
        if remote_cache_root is not None:
            raise PackageGraphError(
                "remote package cache root was supplied without materializations"
            )
        return baseline
    if baseline is None:
        raise PackageGraphError(
            "remote materializations were supplied for an empty package graph"
        )
    if remote_cache_root is None:
        raise PackageGraphError(
            "remote materializations require a remote package cache root"
        )
    try:
        import remote_package_materializer

        verified = remote_package_materializer.verify_set(
            remote_materializations, baseline, remote_cache_root
        )
    except (OSError, remote_package_materializer.MaterializationError) as exc:
        raise PackageGraphError(
            f"remote materialization verification failed: {exc}"
        ) from exc
    return _Planner(
        inventory,
        source_root,
        remote_materializations=verified,
        remote_materialization_set=remote_materializations,
        remote_cache_root=remote_cache_root,
        source_external_graph=baseline,
    ).build()


def _inventory_from_graph(graph: dict[str, Any]) -> dict[str, Any]:
    selected = _list(graph.get("selected_products"), "graph selected_products")
    packages = _list(graph.get("packages"), "graph packages")
    inventory: dict[str, Any] = {
        "local_package_references": [
            {
                "relative_path": _string(
                    _mapping(item, "graph package").get("path"), "graph package.path"
                )
            }
            for item in packages
            if _mapping(item, "graph package").get("origin", "local") == "local"
        ],
        "package_products": [],
    }
    for index, raw in enumerate(selected):
        item = _mapping(raw, f"graph selected_products[{index}]")
        name = _string(item.get("name"), f"graph selected_products[{index}].name")
        if item.get("origin", "local") == "remote":
            inventory["package_products"].append(
                {
                    "name": name,
                    "origin": "remote",
                    "repository_url": _string(
                        item.get("repository_url"),
                        f"graph selected_products[{index}].repository_url",
                    ),
                    "requirement": _mapping(
                        item.get("requirement"),
                        f"graph selected_products[{index}].requirement",
                    ),
                }
            )
        else:
            inventory["package_products"].append(
                {
                    "name": name,
                    "origin": "local",
                    "relative_path": _string(
                        item.get("package_path"),
                        f"graph selected_products[{index}].package_path",
                    ),
                }
            )
    resolution = graph.get("package_resolution")
    if resolution is not None:
        inventory["package_resolution"] = {
            "path": _string(
                _mapping(resolution, "graph package_resolution").get("path"),
                "graph package_resolution.path",
            )
        }
    return inventory


def verify(
    graph: dict[str, Any],
    source_root: Path,
    remote_cache_root: Path | None = None,
) -> None:
    if graph.get("classification") != "portable-local-swift-package-graph" or graph.get(
        "format_version"
    ) not in {1, 2}:
        raise PackageGraphError("input is not a supported local Swift-package graph")
    materializations = None
    if graph.get("format_version") == 2:
        materializations = _mapping(
            graph.get("remote_materializations"), "graph remote_materializations"
        )
    actual = plan(
        _inventory_from_graph(graph),
        source_root,
        materializations,
        remote_cache_root,
    )
    if actual is None or canonical_json(actual) != canonical_json(graph):
        raise PackageGraphError("local Swift-package graph changed or is inconsistent")


def verify_plan_binding(
    graph: dict[str, Any],
    application_plan: dict[str, Any],
    target_list: bytes,
    source_root: Path,
    remote_cache_root: Path | None = None,
) -> None:
    embedded = _mapping(
        application_plan.get("local_package_graph"),
        "application plan local_package_graph",
    )
    if canonical_json(embedded) != canonical_json(graph):
        raise PackageGraphError(
            "standalone local package graph differs from the application plan"
        )
    expected_targets = b"".join(
        _string(
            _mapping(raw, f"graph targets[{index}]").get("target_id"),
            f"graph targets[{index}].target_id",
        ).encode("utf-8")
        + b"\0"
        for index, raw in enumerate(_list(graph.get("targets"), "graph targets"))
    )
    if target_list != expected_targets:
        raise PackageGraphError(
            "local package target list differs from the frozen graph"
        )
    verify(graph, source_root, remote_cache_root)


def require_buildable(graph: dict[str, Any]) -> None:
    external = _list(graph.get("external_packages"), "graph external_packages")
    if external:
        descriptions = []
        for raw in external:
            package = _mapping(raw, "graph external package")
            pin = _mapping(package.get("pin"), "graph external package pin")
            descriptions.append(
                f"{_string(package.get('identity'), 'external identity')}@{_string(pin.get('revision'), 'external revision')} ({_string(package.get('url'), 'external url')})"
            )
        raise PackageGraphError(
            "remote package materialization required before compilation: "
            + "; ".join(descriptions)
        )
    if (
        _mapping(graph.get("buildability"), "graph buildability").get("status")
        != "buildable"
    ):
        raise PackageGraphError("local package graph is not marked buildable")


def _resource_bundle_accessor(bundle_name: str) -> bytes:
    if re.fullmatch(r"[A-Za-z_][A-Za-z0-9_]*\.bundle", bundle_name) is None:
        raise PackageGraphError(
            f"package resource bundle has an unsafe name: {bundle_name!r}"
        )
    return (
        "import Foundation\n\n"
        "extension Foundation.Bundle {\n"
        "    static let module: Bundle = {\n"
        "        guard let resourceURL = Bundle.main.resourceURL else {\n"
        "            fatalError(\"main bundle has no resource URL\")\n"
        "        }\n"
        "        let bundlePath = resourceURL\n"
        f'            .appendingPathComponent("{bundle_name}").path\n'
        "        guard let bundle = Bundle(path: bundlePath) else {\n"
        f'            fatalError("unable to load SwiftPM resource bundle {bundle_name}")\n'
        "        }\n"
        "        return bundle\n"
        "    }()\n"
        "}\n"
    ).encode("utf-8")


def _build_contract(
    graph: dict[str, Any],
    source_root: Path,
    output_root: Path,
    remote_cache_root: Path | None = None,
) -> tuple[dict[str, Any], dict[str, bytes]]:
    verify(graph, source_root, remote_cache_root)
    require_buildable(graph)
    root = _strict_root(source_root)
    if not output_root.is_absolute():
        raise PackageGraphError("local package build root must be absolute")
    try:
        output_root.resolve(strict=False).relative_to(root)
    except ValueError:
        pass
    else:
        raise PackageGraphError(
            "local package build root must be outside the source root"
        )
    targets = _list(graph.get("targets"), "graph targets")
    remote_roots: dict[str, Path] = {}
    if graph.get("format_version") == 2:
        if remote_cache_root is None:
            raise PackageGraphError(
                "materialized package graph requires a remote package cache root"
            )
        try:
            import remote_package_materializer

            materialization_set = _mapping(
                graph.get("remote_materializations"), "graph remote_materializations"
            )
            for raw in _list(
                materialization_set.get("packages"), "remote materialization packages"
            ):
                materialization = _mapping(raw, "remote materialization package")
                identity = _string(
                    materialization.get("identity"), "remote materialization identity"
                )
                remote_roots[identity] = remote_package_materializer.repository_for(
                    remote_cache_root, materialization
                )
        except (OSError, remote_package_materializer.MaterializationError) as exc:
            raise PackageGraphError(
                f"cannot resolve remote package sources: {exc}"
            ) from exc
    target_models = [
        _mapping(raw, f"graph targets[{index}]")
        for index, raw in enumerate(targets)
    ]
    target_by_id = {
        _string(target.get("target_id"), f"graph targets[{index}].target_id"): target
        for index, target in enumerate(target_models)
    }
    directories: dict[str, str] = {}
    for index, target in enumerate(target_models):
        if target.get("order") != index:
            raise PackageGraphError("graph target order is not contiguous")
        module = _string(target.get("module"), f"graph targets[{index}].module")
        if not _IDENTIFIER.fullmatch(module) or not module.isascii():
            raise PackageGraphError(
                f"package module is not a portable Swift or Clang identifier: {module!r}"
            )
        directories[
            _string(target.get("target_id"), f"graph targets[{index}].target_id")
        ] = f"targets/{index:06d}-{module}"

    def physical_record(record: Mapping[str, Any], label: str) -> Path:
        path = _string(record.get("path"), f"{label}.path")
        origin = record.get("source_origin", "application")
        if graph.get("format_version") == 1:
            physical = root / path
        elif origin == "application":
            physical = root / path
        elif isinstance(origin, str) and origin.startswith("remote:"):
            identity = origin.split(":", 1)[1]
            remote_root = remote_roots.get(identity)
            if remote_root is None:
                raise PackageGraphError(
                    f"{label} names missing remote materialization {identity!r}"
                )
            physical = remote_root / path
        else:
            raise PackageGraphError(f"unsupported {label} origin {origin!r}")
        data = physical.read_bytes()
        if len(data) != record.get("size") or _sha256(data) != record.get("sha256"):
            raise PackageGraphError(f"{label} changed after graph verification: {path}")
        return physical

    records: list[dict[str, Any]] = []
    files: dict[str, bytes] = {}
    clang_import_arguments: list[str] = []
    requires_cxx_runtime = False
    for index, target in enumerate(target_models):
        module = _string(target.get("module"), f"graph targets[{index}].module")
        target_id = _string(
            target.get("target_id"), f"graph targets[{index}].target_id"
        )
        directory = directories[target_id]
        target_type = _string(
            target.get("target_type"), f"graph targets[{index}].target_type"
        )
        if target_type not in {"swift", "clang"}:
            raise PackageGraphError(
                f"graph targets[{index}].target_type is unsupported: {target_type!r}"
            )
        output_map_relative = f"{directory}/output-file-map.json"
        module_relative = (
            f"modules/{module}.swiftmodule"
            if target_type == "swift"
            else f"{directory}/headers/{_string(target.get('public_headers_path'), f'graph targets[{index}].public_headers_path')}/module.modulemap"
        )
        sources: list[str] = []
        source_languages: list[str] = []
        for source_index, raw_source in enumerate(
            _list(target.get("sources"), f"graph targets[{index}].sources")
        ):
            source = _mapping(
                raw_source, f"graph targets[{index}].sources[{source_index}]"
            )
            source_label = f"graph targets[{index}].sources[{source_index}]"
            physical = physical_record(source, source_label)
            if graph.get("format_version") == 1:
                sources.append(
                    _string(source.get("path"), f"{source_label}.path")
                )
            else:
                sources.append(os.fspath(physical))
            language = source.get("language", "swift")
            if target_type == "swift" and language != "swift":
                raise PackageGraphError(f"{source_label} has non-Swift language")
            if target_type == "clang" and language not in set(
                _C_SOURCE_LANGUAGES.values()
            ):
                raise PackageGraphError(
                    f"{source_label} has unsupported C-family language {language!r}"
                )
            source_languages.append(language)
        resource_bundle = target.get("resource_bundle")
        if resource_bundle is not None:
            if target_type != "swift":
                raise PackageGraphError(
                    f"graph targets[{index}] assigns resources to a C-family target"
                )
            bundle_name = _string(
                resource_bundle, f"graph targets[{index}].resource_bundle"
            )
            accessor_relative = f"{directory}/resource_bundle_accessor.swift"
            files[accessor_relative] = _resource_bundle_accessor(bundle_name)
            sources.append(os.fspath(output_root / accessor_relative))
            source_languages.append("swift")
        objects = [
            f"{directory}/objects/{source_index:06d}.o"
            for source_index in range(len(sources))
        ]
        if target_type == "swift":
            output_map = {
                (source if Path(source).is_absolute() else os.fspath(root / source)): {
                    "object": os.fspath(output_root / object_relative)
                }
                for source, object_relative in zip(sources, objects, strict=True)
            }
            files[output_map_relative] = canonical_json(output_map)
            compiler_arguments = _swift_setting_arguments(
                target.get("swift_settings", []),
                f"graph targets[{index}].swift_settings",
            )
            cxx_arguments: list[str] = []
            header_directories: list[str] = []
            header_records: list[dict[str, str]] = []
        else:
            staged_target_root = output_root / directory
            public_headers_path = _safe_stored_relative(
                _string(
                    target.get("public_headers_path"),
                    f"graph targets[{index}].public_headers_path",
                ),
                f"graph targets[{index}].public_headers_path",
            )
            public_headers = staged_target_root / "headers" / public_headers_path
            header_directories = [
                f"{directory}/headers/{public_headers_path.as_posix()}"
            ]
            header_records = []
            for header_index, raw_header in enumerate(
                _list(target.get("headers"), f"graph targets[{index}].headers")
            ):
                header = _mapping(
                    raw_header, f"graph targets[{index}].headers[{header_index}]"
                )
                header_label = f"graph targets[{index}].headers[{header_index}]"
                physical = physical_record(header, header_label)
                target_relative = _safe_stored_relative(
                    _string(
                        header.get("target_relative_path"),
                        f"{header_label}.target_relative_path",
                    ),
                    f"{header_label}.target_relative_path",
                )
                staged = f"{directory}/headers/{target_relative.as_posix()}"
                if staged in files:
                    raise PackageGraphError(
                        f"C-family target repeats staged header {target_relative.as_posix()!r}"
                    )
                data = physical.read_bytes()
                files[staged] = data
                header_records.append(
                    {
                        "path": staged,
                        "sha256": _sha256(data),
                        "size": len(data),
                    }
                )
            raw_module_map = _mapping(
                target.get("module_map"), f"graph targets[{index}].module_map"
            )
            module_map_kind = _string(
                raw_module_map.get("kind"),
                f"graph targets[{index}].module_map.kind",
            )
            if module_map_kind == "source":
                module_map_data = physical_record(
                    raw_module_map, f"graph targets[{index}].module_map"
                ).read_bytes()
            elif module_map_kind == "generated":
                if set(raw_module_map) != {"kind", "sha256", "size"}:
                    raise PackageGraphError(
                        f"graph targets[{index}].module_map generated fields differ"
                    )
                module_map_data = _Planner._generated_module_map(module)
                if (
                    len(module_map_data) != raw_module_map.get("size")
                    or _sha256(module_map_data) != raw_module_map.get("sha256")
                ):
                    raise PackageGraphError(
                        f"graph targets[{index}] generated module map changed"
                    )
            else:
                raise PackageGraphError(
                    f"graph targets[{index}] has unsupported module map kind"
                )
            files[module_relative] = module_map_data
            own_include = "-I" + os.fspath(public_headers)
            compiler_arguments = [own_include]
            for edge_index, raw_edge in enumerate(
                _list(target.get("dependencies"), f"graph targets[{index}].dependencies")
            ):
                edge = _mapping(
                    raw_edge,
                    f"graph targets[{index}].dependencies[{edge_index}]",
                )
                dependency_id = edge.get("target_id")
                if dependency_id is None:
                    continue
                dependency = target_by_id.get(dependency_id)
                if dependency is None:
                    raise PackageGraphError(
                        f"graph targets[{index}] names missing dependency {dependency_id!r}"
                    )
                if dependency.get("target_type") != "clang":
                    continue
                dependency_public = _safe_stored_relative(
                    _string(
                        dependency.get("public_headers_path"),
                        f"dependency {dependency_id} public_headers_path",
                    ),
                    f"dependency {dependency_id} public_headers_path",
                )
                compiler_arguments.append(
                    "-I"
                    + os.fspath(
                        output_root
                        / directories[dependency_id]
                        / "headers"
                        / dependency_public
                    )
                )
            compiler_arguments.extend(
                _c_family_setting_arguments(
                    target.get("c_settings", []),
                    f"graph targets[{index}].c_settings",
                    staged_target_root=staged_target_root,
                )
            )
            cxx_arguments = _c_family_setting_arguments(
                target.get("cxx_settings", []),
                f"graph targets[{index}].cxx_settings",
                staged_target_root=staged_target_root,
            )
            for setting in [
                *target.get("c_settings", []),
                *target.get("cxx_settings", []),
            ]:
                if setting.get("kind") == "header_search_path":
                    header_directories.append(
                        f"{directory}/headers/{setting['path']}"
                    )
            clang_import_arguments.extend(
                [
                    "-Xcc",
                    "-fmodule-map-file=" + os.fspath(output_root / module_relative),
                    "-Xcc",
                    own_include,
                ]
            )
            if any(
                language in {"cxx", "objective-cxx"}
                for language in source_languages
            ):
                requires_cxx_runtime = True
        record = {
            "compiler_arguments": compiler_arguments,
            "cxx_arguments": cxx_arguments,
            "header_directories": header_directories,
            "headers": header_records,
            "module": module,
            "module_output": module_relative,
            "objects": objects,
            "output_file_map": (
                output_map_relative if target_type == "swift" else None
            ),
            "sources": sources,
            "source_languages": source_languages,
            "target_id": target_id,
            "target_type": target_type,
        }
        if resource_bundle is not None:
            record["resource_bundle"] = bundle_name
        records.append(record)
    contract = {
        "classification": "portable-local-package-build-contract",
        "clang_import_arguments": clang_import_arguments,
        "format_version": 3,
        "graph_sha256": _sha256(canonical_json(graph)),
        "requires_cxx_runtime": requires_cxx_runtime,
        "targets": records,
    }
    files["build-contract.json"] = canonical_json(contract)
    files["clang-import-arguments.nul"] = b"".join(
        argument.encode("utf-8") + b"\0" for argument in clang_import_arguments
    )
    files["clang-link-arguments.nul"] = (
        b"-lc++\0" if requires_cxx_runtime else b""
    )
    files["targets.nul"] = b"".join(
        f"{index:06d}".encode("ascii") + b"\0" for index in range(len(records))
    )
    return contract, files


def prepare_build(
    graph: dict[str, Any],
    source_root: Path,
    output_root: Path,
    remote_cache_root: Path | None = None,
) -> dict[str, Any]:
    contract, files = _build_contract(
        graph, source_root, output_root, remote_cache_root
    )
    if output_root.exists() or output_root.is_symlink():
        raise PackageGraphError(
            f"local package build root already exists: {output_root}"
        )
    output_root.mkdir(mode=0o755)
    (output_root / "modules").mkdir(mode=0o755)
    for index, raw_target in enumerate(contract["targets"]):
        target = _mapping(raw_target, f"build contract targets[{index}]")
        objects = _list(target.get("objects"), f"build contract targets[{index}].objects")
        if not objects:
            raise PackageGraphError(f"build contract targets[{index}] has no objects")
        object_parent = _safe_stored_relative(
            _string(objects[0], f"build contract targets[{index}].objects[0]"),
            f"build contract targets[{index}].objects[0]",
        ).parent
        (output_root / object_parent).mkdir(mode=0o755, parents=True)
        for directory_index, raw_directory in enumerate(
            _list(
                target.get("header_directories"),
                f"build contract targets[{index}].header_directories",
            )
        ):
            relative = _safe_stored_relative(
                _string(
                    raw_directory,
                    f"build contract targets[{index}].header_directories[{directory_index}]",
                ),
                f"build contract targets[{index}].header_directories[{directory_index}]",
            )
            (output_root / relative).mkdir(mode=0o755, parents=True, exist_ok=True)
    for relative, data in files.items():
        path = output_root / relative
        path.parent.mkdir(mode=0o755, parents=True, exist_ok=True)
        if relative.endswith("output-file-map.json"):
            (path.parent / "objects").mkdir(mode=0o755, exist_ok=True)
        path.write_bytes(data)
    return contract


def verify_build_contract(
    graph: dict[str, Any],
    source_root: Path,
    output_root: Path,
    remote_cache_root: Path | None = None,
) -> dict[str, Any]:
    if (
        not output_root.is_absolute()
        or not output_root.is_dir()
        or output_root.is_symlink()
    ):
        raise PackageGraphError(
            "local package build root is not an ordinary absolute directory"
        )
    contract, files = _build_contract(
        graph, source_root, output_root, remote_cache_root
    )
    for relative, expected in files.items():
        path = output_root / relative
        if not path.is_file() or path.is_symlink() or path.read_bytes() != expected:
            raise PackageGraphError(f"local package build contract changed: {relative}")
    for index, raw_target in enumerate(contract["targets"]):
        target = _mapping(raw_target, f"build contract targets[{index}]")
        for directory_index, raw_directory in enumerate(
            _list(
                target.get("header_directories"),
                f"build contract targets[{index}].header_directories",
            )
        ):
            relative = _safe_stored_relative(
                _string(
                    raw_directory,
                    f"build contract targets[{index}].header_directories[{directory_index}]",
                ),
                f"build contract targets[{index}].header_directories[{directory_index}]",
            )
            path = output_root / relative
            if not path.is_dir() or path.is_symlink():
                raise PackageGraphError(
                    f"local package build contract changed: {relative.as_posix()}"
                )
    return contract


def emit_target_record(contract: dict[str, Any], index: int) -> bytes:
    if contract.get("classification") != "portable-local-package-build-contract":
        raise PackageGraphError("input is not a local package build contract")
    targets = _list(contract.get("targets"), "build contract targets")
    if index < 0 or index >= len(targets):
        raise PackageGraphError(f"target build index is out of range: {index}")
    target = _mapping(targets[index], f"build contract targets[{index}]")
    if contract.get("format_version") != 3:
        raise PackageGraphError("input is not a version 3 local package build contract")
    output_file_map = target.get("output_file_map")
    if output_file_map is not None:
        output_file_map = _string(output_file_map, "target build output_file_map")
    values = [
        _string(target.get("target_type"), "target build target_type"),
        _string(target.get("module"), "target build module"),
        _string(target.get("module_output"), "target build module_output"),
        output_file_map or "-",
        str(len(_list(target.get("sources"), "target build sources"))),
        *[_string(item, "target build source") for item in target["sources"]],
        str(
            len(
                _list(
                    target.get("source_languages"),
                    "target build source languages",
                )
            )
        ),
        *[
            _string(item, "target build source language")
            for item in target["source_languages"]
        ],
        str(
            len(
                _list(
                    target.get("compiler_arguments"),
                    "target build compiler arguments",
                )
            )
        ),
        *[
            _string(item, "target build compiler argument")
            for item in target["compiler_arguments"]
        ],
        str(
            len(
                _list(
                    target.get("cxx_arguments"),
                    "target build C++ arguments",
                )
            )
        ),
        *[
            _string(item, "target build C++ argument")
            for item in target["cxx_arguments"]
        ],
        str(len(_list(target.get("objects"), "target build objects"))),
        *[_string(item, "target build object") for item in target["objects"]],
    ]
    return b"".join(value.encode("utf-8") + b"\0" for value in values)


def _parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(description=__doc__)
    commands = parser.add_subparsers(dest="command", required=True)
    create = commands.add_parser("plan")
    create.add_argument("inventory", type=Path)
    create.add_argument("--source-root", required=True, type=Path)
    create.add_argument("--output", required=True, type=Path)
    create.add_argument("--remote-materializations", type=Path)
    create.add_argument("--remote-cache-root", type=Path)
    check = commands.add_parser("verify")
    check.add_argument("graph", type=Path)
    check.add_argument("--source-root", required=True, type=Path)
    check.add_argument("--remote-cache-root", type=Path)
    buildable = commands.add_parser("require-buildable")
    buildable.add_argument("graph", type=Path)
    buildable.add_argument("--source-root", required=True, type=Path)
    buildable.add_argument("--remote-cache-root", type=Path)
    binding = commands.add_parser("verify-plan-binding")
    binding.add_argument("graph", type=Path)
    binding.add_argument("--application-plan", required=True, type=Path)
    binding.add_argument("--target-list", required=True, type=Path)
    binding.add_argument("--source-root", required=True, type=Path)
    binding.add_argument("--remote-cache-root", type=Path)
    prepare = commands.add_parser("prepare-build")
    prepare.add_argument("graph", type=Path)
    prepare.add_argument("--source-root", required=True, type=Path)
    prepare.add_argument("--output-root", required=True, type=Path)
    prepare.add_argument("--remote-cache-root", type=Path)
    verify_build = commands.add_parser("verify-build-contract")
    verify_build.add_argument("graph", type=Path)
    verify_build.add_argument("--source-root", required=True, type=Path)
    verify_build.add_argument("--output-root", required=True, type=Path)
    verify_build.add_argument("--remote-cache-root", type=Path)
    emit = commands.add_parser("emit-target-record")
    emit.add_argument("contract", type=Path)
    emit.add_argument("--index", required=True, type=int)
    return parser


def main(argv: list[str] | None = None) -> int:
    arguments = _parser().parse_args(argv)
    try:
        if arguments.command == "plan":
            inventory = _mapping(
                _json_no_duplicates(arguments.inventory.read_bytes(), "inventory"),
                "inventory",
            )
            materializations = None
            if arguments.remote_materializations is not None:
                materializations = _mapping(
                    _json_no_duplicates(
                        arguments.remote_materializations.read_bytes(),
                        "remote materializations",
                    ),
                    "remote materializations",
                )
            graph = plan(
                inventory,
                arguments.source_root,
                materializations,
                arguments.remote_cache_root,
            )
            if graph is None:
                raise PackageGraphError("inventory selects no package products")
            if arguments.output.exists() or arguments.output.is_symlink():
                raise PackageGraphError(f"output already exists: {arguments.output}")
            arguments.output.write_bytes(canonical_json(graph))
            print(
                "LOCAL_PACKAGE_GRAPH_OK "
                f"packages={len(graph['packages'])} "
                f"targets={len(graph['targets'])} "
                f"sources={graph['summary']['swift_sources'] + graph['summary']['c_family_sources']} "
                f"external={graph['summary']['external_packages']} "
                f"sha256={_sha256(canonical_json(graph))}"
            )
        elif arguments.command in {
            "verify",
            "require-buildable",
            "verify-plan-binding",
        }:
            graph = _mapping(
                _json_no_duplicates(arguments.graph.read_bytes(), "package graph"),
                "package graph",
            )
            verify(graph, arguments.source_root, arguments.remote_cache_root)
            if arguments.command == "verify-plan-binding":
                application_plan = _mapping(
                    _json_no_duplicates(
                        arguments.application_plan.read_bytes(), "application plan"
                    ),
                    "application plan",
                )
                verify_plan_binding(
                    graph,
                    application_plan,
                    arguments.target_list.read_bytes(),
                    arguments.source_root,
                    arguments.remote_cache_root,
                )
                print("LOCAL_PACKAGE_GRAPH_PLAN_BINDING_VERIFIED")
            elif arguments.command == "require-buildable":
                require_buildable(graph)
                print("LOCAL_PACKAGE_GRAPH_BUILDABLE")
            else:
                print(
                    "LOCAL_PACKAGE_GRAPH_VERIFIED "
                    f"targets={len(graph['targets'])} "
                    f"external={graph['summary']['external_packages']}"
                )
        elif arguments.command in {"prepare-build", "verify-build-contract"}:
            graph = _mapping(
                _json_no_duplicates(arguments.graph.read_bytes(), "package graph"),
                "package graph",
            )
            if arguments.command == "prepare-build":
                contract = prepare_build(
                    graph,
                    arguments.source_root,
                    arguments.output_root,
                    arguments.remote_cache_root,
                )
                print(
                    f"LOCAL_PACKAGE_BUILD_PREPARED targets={len(contract['targets'])}"
                )
            else:
                contract = verify_build_contract(
                    graph,
                    arguments.source_root,
                    arguments.output_root,
                    arguments.remote_cache_root,
                )
                print(
                    f"LOCAL_PACKAGE_BUILD_CONTRACT_VERIFIED targets={len(contract['targets'])}"
                )
        else:
            contract = _mapping(
                _json_no_duplicates(arguments.contract.read_bytes(), "build contract"),
                "build contract",
            )
            sys.stdout.buffer.write(emit_target_record(contract, arguments.index))
    except (OSError, PackageGraphError) as exc:
        print(f"local-package-graph: {exc}", file=sys.stderr)
        return 1
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
