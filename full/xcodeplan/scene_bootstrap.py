#!/usr/bin/env python3
"""Classify and prepare the portable application entry point for an Xcode slice.

The generated Swift file is a build input, never an edit to application
source. UIKit delegate applications receive the ordinary strict single-scene
bootstrap. A top-level ``@main struct`` directly conforming to ``SwiftUI.App``
already inherits its entry point from the framework, so its generated input is
deliberately comment-only: emitting another ``main`` would be a collision.
Everything else fails closed.
"""

from __future__ import annotations

import argparse
import hashlib
import json
import os
from pathlib import Path, PurePosixPath
import plistlib
import re
import stat
import sys
from typing import Any, Iterable


class BootstrapError(RuntimeError):
    """The inventory is outside the deliberately narrow bootstrap contract."""


_IDENTIFIER = r"[A-Za-z_][A-Za-z0-9_]*"
_DECLARATION_MODIFIERS = r"(?:(?:public|internal|private|fileprivate|open|final)\s+)*"
_NOMINAL = re.compile(
    rf"@\s*main\b"
    rf"(?:(?:\s+|@{_IDENTIFIER}(?:\s*\([^)]*\))?))*"
    rf"(?P<modifiers>{_DECLARATION_MODIFIERS})"
    rf"(?P<kind>class|struct|enum)\s+(?P<name>{_IDENTIFIER})"
    rf"(?:\s*:\s*(?P<inheritance>[^{{]+))?\s*{{",
    re.MULTILINE,
)
_SCENE_CLASS = re.compile(
    rf"(?:(?:@{_IDENTIFIER}(?:\s*\([^)]*\))?\s+))*"
    rf"(?P<modifiers>{_DECLARATION_MODIFIERS})"
    rf"class\s+(?P<name>{_IDENTIFIER})\s*:\s*(?P<inheritance>[^{{]+)\s*{{",
    re.MULTILINE,
)
_INITIALIZER = re.compile(
    rf"(?:(?:@{_IDENTIFIER}(?:\s*\([^)]*\))?\s+))*"
    rf"(?:(?:public|internal|private|fileprivate|open|final|required|convenience|override)\s+)*"
    r"init\s*[?!]?\s*\(",
    re.MULTILINE,
)


def _mapping(value: Any, label: str) -> dict[str, Any]:
    if not isinstance(value, dict):
        raise BootstrapError(f"{label} must be an object")
    return value


def _list(value: Any, label: str) -> list[Any]:
    if not isinstance(value, list):
        raise BootstrapError(f"{label} must be an array")
    return value


def _string(value: Any, label: str) -> str:
    if not isinstance(value, str) or not value:
        raise BootstrapError(f"{label} must be a non-empty string")
    return value


def _sha256(data: bytes) -> str:
    return hashlib.sha256(data).hexdigest()


def _strict_root(path: Path) -> Path:
    try:
        metadata = path.lstat()
    except OSError as exc:
        raise BootstrapError(f"cannot inspect source root: {path}: {exc}") from exc
    if stat.S_ISLNK(metadata.st_mode):
        raise BootstrapError(f"source root must not be a symlink: {path}")
    if not stat.S_ISDIR(metadata.st_mode):
        raise BootstrapError(f"source root is not a directory: {path}")
    try:
        return path.resolve(strict=True)
    except OSError as exc:
        raise BootstrapError(f"cannot resolve source root: {path}: {exc}") from exc


def _relative_path(value: str, label: str) -> PurePosixPath:
    relative = PurePosixPath(value)
    if relative.is_absolute() or not relative.parts or any(
        part in ("", ".", "..") for part in relative.parts
    ):
        raise BootstrapError(f"{label} is not a safe relative path: {value!r}")
    return relative


def _regular_file(root: Path, value: str, label: str) -> Path:
    relative = _relative_path(value, label)
    current = root
    for index, component in enumerate(relative.parts):
        current = current / component
        try:
            metadata = current.lstat()
        except OSError as exc:
            raise BootstrapError(f"cannot inspect {label}: {current}: {exc}") from exc
        if stat.S_ISLNK(metadata.st_mode):
            raise BootstrapError(f"{label} traverses a symlink: {current}")
        last = index == len(relative.parts) - 1
        if last and not stat.S_ISREG(metadata.st_mode):
            raise BootstrapError(f"{label} is not a regular file: {current}")
        if not last and not stat.S_ISDIR(metadata.st_mode):
            raise BootstrapError(f"{label} parent is not a directory: {current}")
    try:
        current.resolve(strict=True).relative_to(root)
    except (OSError, ValueError) as exc:
        raise BootstrapError(f"{label} escapes the source root: {current}") from exc
    return current


def _mask_swift_noncode(text: str) -> str:
    """Blank comments and strings while preserving offsets and newlines."""

    chars = list(text)
    size = len(text)

    def blank(start: int, end: int) -> None:
        for offset in range(start, end):
            if chars[offset] != "\n":
                chars[offset] = " "

    index = 0
    while index < size:
        if text.startswith("//", index):
            end = text.find("\n", index + 2)
            if end < 0:
                end = size
            blank(index, end)
            index = end
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
                raise BootstrapError("unterminated Swift block comment")
            blank(start, index)
            continue

        hashes = 0
        while index + hashes < size and text[index + hashes] == "#":
            hashes += 1
        quote = index + hashes
        if quote < size and text[quote] == '"':
            start = index
            multiline = text.startswith('"""', quote)
            quote_count = 3 if multiline else 1
            index = quote + quote_count
            terminator = ('"' * quote_count) + ('#' * hashes)
            while index < size:
                if text.startswith(terminator, index):
                    index += len(terminator)
                    break
                if not hashes and not multiline and text[index] == "\\":
                    index = min(size, index + 2)
                else:
                    index += 1
            else:
                raise BootstrapError("unterminated Swift string literal")
            blank(start, index)
            continue

        index += 1

    return "".join(chars)


def _is_top_level(masked: str, offset: int) -> bool:
    prefix = masked[:offset]
    return prefix.count("{") == prefix.count("}")


def _inherits(
    inheritance: str | None, protocol: str, *, module: str = "UIKit"
) -> bool:
    if inheritance is None:
        return False
    pattern = (
        rf"(?<![A-Za-z0-9_.])(?:{re.escape(module)}\.)?"
        rf"{protocol}(?![A-Za-z0-9_])"
    )
    return re.search(pattern, inheritance) is not None


def _direct_superclass(inheritance: str | None) -> str | None:
    if inheritance is None:
        return None
    first = inheritance.split(",", 1)[0].strip()
    if first.startswith("UIKit."):
        first = first[len("UIKit.") :]
    return first


def _declaration_body(masked: str, match: re.Match[str], label: str) -> str:
    opening = match.end() - 1
    if opening < 0 or masked[opening] != "{":
        raise BootstrapError(f"cannot locate {label} declaration body")
    depth = 1
    index = opening + 1
    while index < len(masked):
        if masked[index] == "{":
            depth += 1
        elif masked[index] == "}":
            depth -= 1
            if depth == 0:
                return masked[opening + 1 : index]
        index += 1
    raise BootstrapError(f"unterminated {label} declaration")


def _require_generated_reference_contract(
    masked: str, match: re.Match[str], label: str
) -> None:
    modifiers = set(match.group("modifiers").split())
    if modifiers.intersection({"private", "fileprivate"}):
        raise BootstrapError(
            f"{label} is private/fileprivate and cannot be referenced from a generated file"
        )
    if _direct_superclass(match.group("inheritance")) != "UIResponder":
        raise BootstrapError(
            f"{label} must directly inherit UIResponder so zero-argument construction is proven"
        )
    body = _declaration_body(masked, match, label)
    if any(
        _is_top_level(body, initializer.start())
        for initializer in _INITIALIZER.finditer(body)
    ):
        raise BootstrapError(
            f"{label} declares an initializer; zero-argument construction is not proven"
        )


def _read_swift_sources(
    inventory: dict[str, Any], root: Path
) -> list[tuple[str, Path, bytes, str]]:
    result: list[tuple[str, Path, bytes, str]] = []
    seen: set[str] = set()
    for index, raw_entry in enumerate(_list(inventory.get("sources"), "sources")):
        entry = _mapping(raw_entry, f"sources[{index}]")
        value = _string(entry.get("path"), f"sources[{index}].path")
        if value in seen:
            raise BootstrapError(f"duplicate source path: {value}")
        seen.add(value)
        if not value.endswith(".swift"):
            continue
        path = _regular_file(root, value, f"sources[{index}].path")
        data = path.read_bytes()
        try:
            text = data.decode("utf-8")
        except UnicodeDecodeError as exc:
            raise BootstrapError(f"Swift source is not UTF-8: {value}") from exc
        result.append((value, path, data, _mask_swift_noncode(text)))
    if not result:
        raise BootstrapError("inventory contains no materialized Swift sources")
    return result


def _find_application_entry_point(
    sources: Iterable[tuple[str, Path, bytes, str]],
) -> tuple[str, str, str, bytes]:
    declarations: list[tuple[str, re.Match[str], bytes, str]] = []
    for relative, _path, data, masked in sources:
        declarations.extend(
            (relative, match, data, masked)
            for match in _NOMINAL.finditer(masked)
            if _is_top_level(masked, match.start())
        )
    if len(declarations) != 1:
        raise BootstrapError(
            f"expected exactly one top-level @main declaration, found {len(declarations)}"
        )
    relative, match, data, masked = declarations[0]
    declaration_kind = match.group("kind")
    inheritance = match.group("inheritance")
    if declaration_kind == "class" and _inherits(
        inheritance, "UIApplicationDelegate"
    ):
        _require_generated_reference_contract(
            masked, match, "@main application delegate"
        )
        return "uikit-scene-bootstrap", match.group("name"), relative, data
    if declaration_kind == "struct" and _inherits(
        inheritance, "App", module="SwiftUI"
    ):
        return "swiftui-app-default-main", match.group("name"), relative, data
    raise BootstrapError(
        "@main type is neither a class directly conforming to "
        "UIApplicationDelegate nor a struct directly conforming to SwiftUI.App"
    )


def _build_settings(inventory: dict[str, Any]) -> tuple[dict[str, Any], dict[str, Any]]:
    configuration = _mapping(inventory.get("configuration"), "configuration")
    project = _mapping(configuration.get("project"), "configuration.project")
    target = _mapping(configuration.get("target"), "configuration.target")
    return (
        _mapping(project.get("build_settings"), "project build_settings"),
        _mapping(target.get("build_settings"), "target build_settings"),
    )


def _setting(project: dict[str, Any], target: dict[str, Any], name: str) -> Any:
    return target[name] if name in target else project.get(name)


def _module_identifier(value: str) -> str:
    identifier = re.sub(r"[^A-Za-z0-9_]", "_", value)
    if not identifier:
        raise BootstrapError("product name cannot form a Swift module identifier")
    if identifier[0].isdigit():
        identifier = "_" + identifier
    return identifier


def _product_module_name(
    inventory: dict[str, Any], project: dict[str, Any], target_settings: dict[str, Any]
) -> str:
    target = _mapping(inventory.get("target"), "target")
    target_name = _string(target.get("name"), "target.name")
    product_name = _string(target.get("product_name"), "target.product_name")
    raw = _setting(project, target_settings, "PRODUCT_MODULE_NAME")
    if raw is None or raw in ("$(PRODUCT_NAME)", "$(PRODUCT_NAME:c99extidentifier)"):
        return _module_identifier(product_name)
    if raw == "$(TARGET_NAME)":
        return _module_identifier(target_name)
    raw_name = _string(raw, "PRODUCT_MODULE_NAME")
    if "$" in raw_name or not re.fullmatch(_IDENTIFIER, raw_name):
        raise BootstrapError(f"unsupported PRODUCT_MODULE_NAME: {raw_name!r}")
    return raw_name


def _info_plist_path(
    root: Path, project: dict[str, Any], target: dict[str, Any]
) -> Path:
    raw = _string(_setting(project, target, "INFOPLIST_FILE"), "INFOPLIST_FILE")
    for token in ("$(SRCROOT)/", "${SRCROOT}/", "$(PROJECT_DIR)/", "${PROJECT_DIR}/"):
        if raw.startswith(token):
            raw = raw[len(token) :]
            break
    if "$" in raw:
        raise BootstrapError(f"unsupported INFOPLIST_FILE expansion: {raw!r}")
    return _regular_file(root, raw, "INFOPLIST_FILE")


def _scene_delegate_name(plist: dict[str, Any], module_name: str) -> str:
    manifest = _mapping(plist.get("UIApplicationSceneManifest"), "UIApplicationSceneManifest")
    if manifest.get("UIApplicationSupportsMultipleScenes") is True:
        raise BootstrapError("multiple-scene applications are outside this bootstrap slice")
    configurations = _mapping(
        manifest.get("UISceneConfigurations"),
        "UIApplicationSceneManifest.UISceneConfigurations",
    )
    values = _list(
        configurations.get("UIWindowSceneSessionRoleApplication"),
        "UIWindowSceneSessionRoleApplication configurations",
    )
    if not values:
        raise BootstrapError("no window-application scene configuration")

    delegate_names: set[str] = set()
    for index, raw in enumerate(values):
        configuration = _mapping(raw, f"scene configuration[{index}]")
        storyboard = configuration.get("UISceneStoryboardFile")
        if storyboard not in (None, ""):
            raise BootstrapError("storyboard scene bootstraps are not implemented")
        scene_class = configuration.get("UISceneClassName")
        if scene_class not in (None, "", "UIWindowScene", "UIKit.UIWindowScene"):
            raise BootstrapError(f"custom scene class is not implemented: {scene_class!r}")

        raw_delegate = _string(
            configuration.get("UISceneDelegateClassName"),
            f"scene configuration[{index}].UISceneDelegateClassName",
        )
        expanded = raw_delegate
        for token in ("$(PRODUCT_MODULE_NAME)", "${PRODUCT_MODULE_NAME}"):
            expanded = expanded.replace(token, module_name)
        if "$" in expanded:
            raise BootstrapError(f"unresolved scene delegate class: {raw_delegate!r}")
        parts = expanded.split(".")
        if len(parts) == 2:
            if parts[0] != module_name:
                raise BootstrapError(
                    f"scene delegate belongs to unexpected module: {expanded!r}"
                )
            expanded = parts[1]
        if not re.fullmatch(_IDENTIFIER, expanded):
            raise BootstrapError(f"unsupported scene delegate type: {expanded!r}")
        delegate_names.add(expanded)

    if len(delegate_names) != 1:
        raise BootstrapError("window scene configurations select different delegate classes")
    return next(iter(delegate_names))


def _find_scene_delegate(
    sources: Iterable[tuple[str, Path, bytes, str]], expected: str
) -> tuple[str, bytes]:
    declarations: list[tuple[str, bytes, str, re.Match[str]]] = []
    for relative, _path, data, masked in sources:
        for match in _SCENE_CLASS.finditer(masked):
            if (
                _is_top_level(masked, match.start())
                and match.group("name") == expected
                and _inherits(match.group("inheritance"), "UIWindowSceneDelegate")
            ):
                declarations.append((relative, data, masked, match))
    if len(declarations) != 1:
        raise BootstrapError(
            f"expected one top-level {expected}: UIWindowSceneDelegate declaration, "
            f"found {len(declarations)}"
        )
    relative, data, masked, match = declarations[0]
    _require_generated_reference_contract(masked, match, "scene delegate")
    return relative, data


def _validate_inventory(inventory: dict[str, Any]) -> None:
    if inventory.get("format_version") != 1:
        raise BootstrapError("unsupported inventory format_version")
    target = _mapping(inventory.get("target"), "target")
    if target.get("product_type") != "com.apple.product-type.application":
        raise BootstrapError("scene bootstrap requires an application target")
    unsupported = _list(inventory.get("unsupported_features"), "unsupported_features")
    if unsupported:
        raise BootstrapError("inventory has unsupported features")
    missing = _list(inventory.get("missing_inputs"), "missing_inputs")
    if missing:
        raise BootstrapError("inventory has missing inputs")


def _uikit_generated_source(app_name: str, scene_name: str) -> bytes:
    return (
        "import UIKit\n"
        "\n"
        "// Generated build input: portable UIKit supplies this method on Linux.\n"
        f"extension {app_name} {{\n"
        "    @MainActor\n"
        "    static func main() {\n"
        "        PortableUIKitApplicationHost.prepare()\n"
        f"        let appDelegate = {app_name}()\n"
        "        let application = UIApplicationMain(delegate: appDelegate)\n"
        f"        let scene = application._hostConnectWindowScene(delegate: {scene_name}())\n"
        "        application._hostDidBecomeActive()\n"
        "        PortableUIKitApplicationHost.run(application: application, scene: scene)\n"
        "    }\n"
        "}\n"
    ).encode("utf-8")


def _swiftui_generated_source(app_name: str) -> bytes:
    return (
        f"// Generated build input: {app_name} inherits SwiftUI.App's default main; "
        "no competing entry point is emitted.\n"
    ).encode("utf-8")


def generate(inventory: dict[str, Any], source_root: Path) -> tuple[bytes, dict[str, Any]]:
    _validate_inventory(inventory)
    root = _strict_root(source_root)
    sources = _read_swift_sources(inventory, root)
    entry_point, app_name, app_path, app_data = _find_application_entry_point(
        sources
    )
    project_settings, target_settings = _build_settings(inventory)
    module_name = _product_module_name(inventory, project_settings, target_settings)
    plist_path = _info_plist_path(root, project_settings, target_settings)
    plist_data = plist_path.read_bytes()
    try:
        plist = _mapping(plistlib.loads(plist_data), "Info.plist")
    except (plistlib.InvalidFileException, ValueError) as exc:
        raise BootstrapError(f"cannot parse Info.plist: {exc}") from exc
    if entry_point == "uikit-scene-bootstrap":
        scene_name = _scene_delegate_name(plist, module_name)
        scene_path, scene_data = _find_scene_delegate(sources, scene_name)
        generated = _uikit_generated_source(app_name, scene_name)
        application_record = {
            "app_delegate": {
                "path": app_path,
                "sha256": _sha256(app_data),
                "type": app_name,
            },
            "scene_delegate": {
                "path": scene_path,
                "sha256": _sha256(scene_data),
                "type": scene_name,
            },
        }
    else:
        generated = _swiftui_generated_source(app_name)
        application_record = {
            "swiftui_app": {
                "path": app_path,
                "sha256": _sha256(app_data),
                "type": app_name,
            }
        }

    record = {
        "classification": "generated-build-input",
        "entry_point": entry_point,
        "generated_sha256": _sha256(generated),
        "generated_size": len(generated),
        "info_plist": {
            "path": plist_path.relative_to(root).as_posix(),
            "sha256": _sha256(plist_data),
        },
        "inventory_swift_source_count": len(sources),
        "module": module_name,
        **application_record,
    }
    return generated, record


def _write_exclusive(path: Path, data: bytes, source_root: Path) -> None:
    if not path.parent.exists() or not path.parent.is_dir():
        raise BootstrapError(f"output parent does not exist: {path.parent}")
    root = source_root.resolve(strict=True)
    parent = path.parent.resolve(strict=True)
    try:
        parent.relative_to(root)
    except ValueError:
        pass
    else:
        raise BootstrapError("generated bootstrap output must be outside application source root")
    flags = os.O_WRONLY | os.O_CREAT | os.O_EXCL
    if hasattr(os, "O_NOFOLLOW"):
        flags |= os.O_NOFOLLOW
    try:
        descriptor = os.open(path, flags, 0o644)
    except OSError as exc:
        raise BootstrapError(f"cannot create generated bootstrap: {path}: {exc}") from exc
    try:
        with os.fdopen(descriptor, "wb") as handle:
            handle.write(data)
    except Exception:
        try:
            path.unlink()
        except OSError:
            pass
        raise


def _parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("inventory", type=Path, help="canonical project inventory JSON")
    parser.add_argument("--source-root", required=True, type=Path)
    parser.add_argument(
        "--output",
        type=Path,
        help="exclusive output path outside source root; omit to write Swift to stdout",
    )
    return parser


def main(argv: list[str] | None = None) -> int:
    arguments = _parser().parse_args(argv)
    try:
        raw_inventory = json.loads(arguments.inventory.read_text(encoding="utf-8"))
        inventory = _mapping(raw_inventory, "inventory")
        generated, record = generate(inventory, arguments.source_root)
        if arguments.output is None:
            sys.stdout.buffer.write(generated)
        else:
            _write_exclusive(arguments.output, generated, arguments.source_root)
            print(json.dumps(record, sort_keys=True, separators=(",", ":")))
    except (BootstrapError, OSError, json.JSONDecodeError) as exc:
        print(f"scene-bootstrap: {exc}", file=sys.stderr)
        return 1
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
