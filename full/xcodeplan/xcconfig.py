#!/usr/bin/env python3
"""Fail-closed evaluator for source-root-contained Xcode configuration files.

The generic project inventory only needs a destination-independent subset of
Xcode's configuration language.  This module intentionally models that subset
as a real, ordered language rather than searching configuration bytes for a
few interesting setting names:

* required quoted ``#include`` directives are evaluated at their textual
  position;
* ``=``, ``+=`` and ``?=`` assignments update one ordered setting layer;
* C/C++ comments, quoted values and backslash-newline continuation are parsed;
* every input is a regular, non-symlink file beneath one canonical source root;
* include cycles, missing/ambiguous files and unmodelled directives or
  conditional assignments fail closed; and
* every evaluated file occurrence is recorded with its content digest.

Destination-conditional assignments and optional includes are deliberately not
accepted.  Selecting either requires SDK/destination state that the portable
inventory does not possess.
"""

from __future__ import annotations

import hashlib
import os
import posixpath
import re
import stat
import unicodedata
from dataclasses import dataclass
from pathlib import Path
from typing import Any, Mapping

import xcodeplan


PlanError = xcodeplan.PlanError

_ASSIGNMENT = re.compile(
    r"(?P<key>[A-Za-z_][A-Za-z0-9_]*)(?P<conditions>(?:\s*\[[^\]\r\n]+\])*)"
    r"\s*(?P<operator>\?=|\+=|=)\s*(?P<value>.*)\Z"
)
_INCLUDE = re.compile(r'#\s*include\s+"(?P<path>[^"\r\n]+)"\s*\Z')
_VARIABLE = re.compile(r"\$\(([^)]+)\)|\$\{([^}]+)\}")


@dataclass(frozen=True)
class Evaluation:
    """One evaluated xcconfig layer plus immutable input provenance."""

    settings: dict[str, str]
    files: tuple[dict[str, Any], ...]
    includes: tuple[dict[str, Any], ...]
    assignment_count: int
    entry_path: str


def _portable_name(value: str) -> str:
    """Approximate the case/normalization folding of common macOS worktrees.

    Git can contain spellings that collide under this identity.  We only use a
    folded match when it is unique, so evaluation remains deterministic on a
    case-sensitive Linux checkout while preserving the include semantics of a
    repository authored and built on default APFS.
    """

    return unicodedata.normalize("NFC", value).casefold()


def replace_inherited(value: str, key: str, previous: Any) -> str:
    """Bind Xcode's same-setting/``inherited`` references to the lower value."""

    if not isinstance(previous, str):
        return value

    def replace(match: re.Match[str]) -> str:
        name = match.group(1) or match.group(2)
        return previous if name in {"inherited", key} else match.group(0)

    return _VARIABLE.sub(replace, value)


def apply_assignment(
    state: dict[str, Any],
    assigned: dict[str, str],
    *,
    key: str,
    operator: str,
    value: str,
) -> None:
    """Apply one xcconfig assignment in textual order.

    ``assigned`` contains only values contributed by this configuration layer;
    ``state`` additionally contains lower-precedence settings.
    """

    previous = state.get(key)
    if operator == "?=" and key in state:
        return
    value = replace_inherited(value, key, previous)
    if operator == "+=" and key in state:
        if not isinstance(previous, str):
            # A PBX list and an xcconfig string cannot be combined faithfully
            # without Xcode's type coercion rules.
            raise PlanError(
                f"xcconfig += cannot append to non-string inherited setting {key}"
            )
        value = f"{previous} {value}" if value else previous
    state[key] = value
    assigned[key] = value


class _Evaluator:
    def __init__(self, source_root: Path, inherited: Mapping[str, Any]) -> None:
        try:
            metadata = source_root.lstat()
            if stat.S_ISLNK(metadata.st_mode) or not stat.S_ISDIR(metadata.st_mode):
                raise PlanError(
                    f"xcconfig source root must be a non-symlink directory: {source_root}"
                )
            self.root = source_root.resolve(strict=True)
        except PlanError:
            raise
        except OSError as exc:
            raise PlanError(f"cannot inspect xcconfig source root {source_root}: {exc}") from exc
        self.state: dict[str, Any] = dict(inherited)
        self.assigned: dict[str, str] = {}
        self.files: list[dict[str, Any]] = []
        self.includes: list[dict[str, Any]] = []
        self.assignment_count = 0
        self._active: list[str] = []
        self._bytes: dict[str, bytes] = {}

    @staticmethod
    def _safe_requested_path(value: str, context: str) -> str:
        if (
            not value
            or posixpath.isabs(value)
            or "\\" in value
            or "$" in value
            or any(unicodedata.category(character).startswith("C") for character in value)
        ):
            raise PlanError(f"{context} has unsafe path {value!r}")
        return value

    def _canonical_path(self, base: str, requested: str, context: str) -> str:
        requested = self._safe_requested_path(requested, context)
        normalized = posixpath.normpath(posixpath.join(base, requested))
        if normalized in {"", ".", ".."} or normalized.startswith("../"):
            raise PlanError(f"{context} escapes xcconfig source root: {requested!r}")

        current = self.root
        actual: list[str] = []
        components = normalized.split("/")
        for index, component in enumerate(components):
            try:
                entries = list(os.scandir(current))
            except OSError as exc:
                raise PlanError(f"cannot inspect {context} directory {current}: {exc}") from exc
            exact = [entry for entry in entries if entry.name == component]
            if exact:
                matches = exact
            else:
                folded = _portable_name(component)
                matches = [entry for entry in entries if _portable_name(entry.name) == folded]
            if not matches:
                raise PlanError(f"missing {context}: {normalized}")
            if len(matches) != 1:
                names = ", ".join(sorted(entry.name for entry in matches))
                raise PlanError(
                    f"ambiguous {context} component {component!r}: {names}"
                )
            entry = matches[0]
            candidate = Path(entry.path)
            try:
                metadata = candidate.lstat()
            except OSError as exc:
                raise PlanError(f"cannot inspect {context} {candidate}: {exc}") from exc
            if stat.S_ISLNK(metadata.st_mode):
                raise PlanError(f"{context} traverses a symlink: {normalized}")
            if index < len(components) - 1:
                if not stat.S_ISDIR(metadata.st_mode):
                    raise PlanError(
                        f"{context} traverses a non-directory component: {normalized}"
                    )
            elif not stat.S_ISREG(metadata.st_mode):
                raise PlanError(f"{context} is not a regular file: {normalized}")
            current = candidate
            actual.append(entry.name)

        relative = "/".join(actual)
        try:
            current.resolve(strict=True).relative_to(self.root)
        except ValueError as exc:
            raise PlanError(f"{context} escapes xcconfig source root: {relative}") from exc
        except OSError as exc:
            raise PlanError(f"cannot resolve {context} {relative}: {exc}") from exc
        return relative

    def _read(self, relative: str) -> bytes:
        cached = self._bytes.get(relative)
        if cached is not None:
            return cached
        candidate = self.root / relative
        try:
            before = candidate.lstat()
            data = candidate.read_bytes()
            after = candidate.lstat()
        except OSError as exc:
            raise PlanError(f"cannot read xcconfig {relative}: {exc}") from exc
        stable_fields = ("st_dev", "st_ino", "st_mode", "st_size", "st_mtime_ns")
        if any(getattr(before, field) != getattr(after, field) for field in stable_fields):
            raise PlanError(f"xcconfig changed while being read: {relative}")
        if stat.S_ISLNK(after.st_mode) or not stat.S_ISREG(after.st_mode):
            raise PlanError(f"xcconfig is not a regular non-symlink file: {relative}")
        self._bytes[relative] = data
        return data

    @staticmethod
    def _without_comments(text: str, relative: str) -> str:
        output: list[str] = []
        index = 0
        quote = False
        block = False
        while index < len(text):
            character = text[index]
            following = text[index + 1] if index + 1 < len(text) else ""
            if block:
                if character == "*" and following == "/":
                    output.extend((" ", " "))
                    block = False
                    index += 2
                else:
                    output.append("\n" if character == "\n" else " ")
                    index += 1
                continue
            if quote:
                output.append(character)
                if character == "\\" and following:
                    output.append(following)
                    index += 2
                else:
                    if character == '"':
                        quote = False
                    index += 1
                continue
            if character == '"':
                quote = True
                output.append(character)
                index += 1
            elif character == "/" and following == "/":
                output.extend((" ", " "))
                index += 2
                while index < len(text) and text[index] != "\n":
                    output.append(" ")
                    index += 1
            elif character == "/" and following == "*":
                output.extend((" ", " "))
                block = True
                index += 2
            else:
                output.append(character)
                index += 1
        if block:
            raise PlanError(f"xcconfig {relative} has an unterminated block comment")
        if quote:
            raise PlanError(f"xcconfig {relative} has an unterminated quoted value")
        return "".join(output)

    @staticmethod
    def _logical_lines(text: str) -> list[tuple[int, str]]:
        result: list[tuple[int, str]] = []
        pending = ""
        start = 1
        physical = text.splitlines()
        for line_number, line in enumerate(physical, start=1):
            if not pending:
                start = line_number
            trailing = len(line) - len(line.rstrip("\\"))
            continued = trailing % 2 == 1
            pending += line[:-1] if continued else line
            if not continued:
                result.append((start, pending))
                pending = ""
        if pending:
            raise PlanError(f"xcconfig has a dangling line continuation at line {start}")
        return result

    @staticmethod
    def _value(raw: str, relative: str, line: int) -> str:
        result: list[str] = []
        quote = False
        index = 0
        while index < len(raw):
            character = raw[index]
            if character == '"':
                quote = not quote
                index += 1
            elif character == "\\":
                if index + 1 >= len(raw):
                    raise PlanError(
                        f"xcconfig {relative}:{line} has a dangling value escape"
                    )
                result.append(raw[index + 1])
                index += 2
            else:
                result.append(character)
                index += 1
        if quote:
            raise PlanError(f"xcconfig {relative}:{line} has an unterminated quote")
        return "".join(result).strip()

    def _evaluate_file(
        self,
        requested: str,
        *,
        base: str,
        included_from: str | None,
        include_line: int | None,
    ) -> str:
        context = "xcconfig entry" if included_from is None else "xcconfig include"
        relative = self._canonical_path(base, requested, context)
        if relative in self._active:
            first = self._active.index(relative)
            chain = self._active[first:] + [relative]
            raise PlanError(f"xcconfig include cycle: {' -> '.join(chain)}")
        data = self._read(relative)
        digest = hashlib.sha256(data).hexdigest()
        self.files.append({"path": relative, "sha256": digest})
        if included_from is not None:
            self.includes.append(
                {
                    "from": included_from,
                    "line": include_line,
                    "path": relative,
                    "requested_path": requested,
                }
            )
        try:
            text = data.decode("utf-8-sig")
        except UnicodeDecodeError as exc:
            raise PlanError(f"xcconfig {relative} is not UTF-8: {exc}") from exc
        if "\x00" in text:
            raise PlanError(f"xcconfig {relative} contains a NUL byte")
        text = self._without_comments(text, relative)
        self._active.append(relative)
        try:
            for line_number, raw_line in self._logical_lines(text):
                line = raw_line.strip()
                if not line:
                    continue
                if line.startswith("#"):
                    include = _INCLUDE.fullmatch(line)
                    if include is None:
                        raise PlanError(
                            f"xcconfig {relative}:{line_number} uses an unsupported directive"
                        )
                    self._evaluate_file(
                        include.group("path"),
                        base=posixpath.dirname(relative),
                        included_from=relative,
                        include_line=line_number,
                    )
                    continue
                assignment = _ASSIGNMENT.fullmatch(line)
                if assignment is None:
                    raise PlanError(
                        f"xcconfig {relative}:{line_number} has a malformed assignment"
                    )
                if assignment.group("conditions").strip():
                    raise PlanError(
                        f"xcconfig {relative}:{line_number} uses an unsupported conditional "
                        f"assignment for {assignment.group('key')}"
                    )
                key = assignment.group("key")
                value = self._value(
                    assignment.group("value"), relative, line_number
                )
                apply_assignment(
                    self.state,
                    self.assigned,
                    key=key,
                    operator=assignment.group("operator"),
                    value=value,
                )
                self.assignment_count += 1
        finally:
            self._active.pop()
        return relative

    def evaluate(self, entry_path: str) -> Evaluation:
        entry = self._evaluate_file(
            entry_path,
            base="",
            included_from=None,
            include_line=None,
        )
        return Evaluation(
            settings=dict(self.assigned),
            files=tuple(dict(item) for item in self.files),
            includes=tuple(dict(item) for item in self.includes),
            assignment_count=self.assignment_count,
            entry_path=entry,
        )


def evaluate(
    source_root: Path,
    entry_path: str,
    inherited: Mapping[str, Any] | None = None,
) -> Evaluation:
    """Evaluate one required xcconfig entry as a setting layer."""

    return _Evaluator(source_root, inherited or {}).evaluate(entry_path)
