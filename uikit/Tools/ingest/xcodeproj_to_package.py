#!/usr/bin/env python3
"""Turn an iOS .xcodeproj into an OpenUIKit Swift package.

A Linux agent gets a real app as project.pbxproj, not Package.swift. This
tool parses that OpenStep plist (no Xcode, no plistlib — Xcode's dialect is
not XML), picks the application target, and emits:

  * Package.swift that depends on the OpenUIKit package (UIKit / SwiftUI
    products, MainActor isolation matching an Xcode 26 app target)
  * a source manifest (JSON) with every Swift file, Info.plist keys the
    harness needs, resources mapped onto the port's loaders, and every
    SwiftPM / Apple-framework import classified the way the 20-app ladder
    classified its 30 measured deps
  * a Resources/ tree: .xcassets as catalogs, .xib/.storyboard into a
    fixtures/realapp-style nibs directory, .strings/.lproj for Bundle
    localization, .json as bundled data

It stops with a named gap list for CocoaPods, Carthage, Objective-C
sources, and mixed Swift+ObjC targets. With --allow-gaps a mixed target is
emitted in Xcode's staged order on route (b): a Swift library target that
reads the app's ObjC headers through its bridging header, a Clang target that
depends on it (so SwiftPM has written `<App>-Swift.h` before any .m file
compiles), and a `<App>Main` executable for main.m. `<UIKit/UIKit.h>` is
OpenUIKit's compiler-generated header plus OpenUIKitObjCSupport. What that
does NOT give is Objective-C subclasses of OpenUIKit classes: the generated
header marks them objc_subclassing_restricted, and lifting the attribute
crashes on the first Swift vtable read (simplenote-launch3, measured).
Missing Apple frameworks and SPM products are reported, not silently
dropped.

    python3 Tools/ingest/xcodeproj_to_package.py path/to/App.xcodeproj \\
        [--target NAME] [--out DIR] [--openuikit DIR] [--allow-gaps]

Exit 0 on a complete ingest. Exit 2 when a gap with no port is present
(unless --allow-gaps). Exit 1 on parse / usage errors.
"""
from __future__ import annotations

import argparse
import json
import os
import posixpath
import re
import shutil
import sys
import xml.etree.ElementTree as ET
from pathlib import Path, PurePosixPath
from typing import Any

HERE = Path(__file__).resolve().parent
UIKIT_ROOT = HERE.parent.parent

# ---------------------------------------------------------------------------
# OpenStep plist (the grammar Xcode writes as project.pbxproj)
# ---------------------------------------------------------------------------


class OpenStepError(Exception):
    """project.pbxproj is not a well-formed OpenStep plist."""


class OpenStepParser:
    """Strict ASCII OpenStep parser. Comments, quoted strings, bare tokens."""

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
        raise OpenStepError(f"{self.source}:{line}:{column}: {message}")

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
        self.index += 1
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
            if self.text.startswith("//", self.index) or self.text.startswith(
                "/*", self.index
            ):
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


# ---------------------------------------------------------------------------
# XML Info.plist (Apple's XML DTD, not OpenStep)
# ---------------------------------------------------------------------------


def parse_xml_plist(text: str, source: str = "<plist>") -> Any:
    try:
        root = ET.fromstring(text)
    except ET.ParseError as exc:
        raise OpenStepError(f"{source}: XML plist parse failed: {exc}") from exc
    if root.tag != "plist":
        raise OpenStepError(f"{source}: expected <plist>, got <{root.tag}>")
    children = [c for c in list(root) if c.tag is not None]
    if not children:
        return None
    return _xml_plist_value(children[0], source)


def _xml_plist_value(el: ET.Element, source: str) -> Any:
    tag = el.tag
    if tag == "dict":
        result: dict[str, Any] = {}
        children = list(el)
        i = 0
        while i < len(children):
            key_el = children[i]
            if key_el.tag != "key":
                raise OpenStepError(f"{source}: dict entry is not <key>")
            if i + 1 >= len(children):
                raise OpenStepError(f"{source}: <key> {key_el.text!r} has no value")
            result[key_el.text or ""] = _xml_plist_value(children[i + 1], source)
            i += 2
        return result
    if tag == "array":
        return [_xml_plist_value(c, source) for c in list(el)]
    if tag == "string":
        return el.text or ""
    if tag == "integer":
        return int(el.text or "0")
    if tag == "real":
        return float(el.text or "0")
    if tag == "true":
        return True
    if tag == "false":
        return False
    if tag in {"data", "date"}:
        return el.text or ""
    raise OpenStepError(f"{source}: unsupported plist tag <{tag}>")


def parse_plist_file(path: Path) -> Any:
    raw = path.read_bytes()
    text = raw.decode("utf-8")
    stripped = text.lstrip("\ufeff").lstrip()
    if stripped.startswith("<?xml") or stripped.startswith("<plist") or stripped.startswith("<!DOCTYPE"):
        return parse_xml_plist(text, str(path))
    return parse_openstep(text, str(path))


# ---------------------------------------------------------------------------
# Ladder classification (measured 2026-08-27, full/ladder/dep-classes)
# ---------------------------------------------------------------------------

# Product names as the 20-app ladder scored them. First match wins when an
# import or XCSwiftPackageProductDependency name equals the key. Values are
# the four classes the brief names, plus the two extra rungs the ladder
# actually assigned (SwiftUI/Combine-bound, pure-Swift portable).
# The 30 deps clone_deps.sh actually classified (full/ladder/dep-classes-2026-08-27.json).
# Names not on this list are reported as class=unmeasured rather than guessed.
LADDER_DEP_CLASS: dict[str, str] = {
    "Sentry": "ObjC",
    "Lottie": "SwiftUI/Combine-bound",
    "SwiftSoup": "Foundation-heavy",
    "Alamofire": "networking-bound",
    "Kingfisher": "SwiftUI/Combine-bound",
    "KeychainAccess": "UIKit-bound",
    "SDWebImage": "ObjC",
    "GRDB": "Foundation-heavy",
    "CocoaLumberjack": "ObjC",
    "SwiftyJSON": "Foundation-heavy",
    "SwiftProtobuf": "Foundation-heavy",
    "RealmSwift": "ObjC",
    "Nimble": "Foundation-heavy",
    "Quick": "Foundation-heavy",
    "SnapKit": "UIKit-bound",
    "AlamofireImage": "UIKit-bound",
    "Starscream": "Foundation-heavy",
    "SVProgressHUD": "ObjC",
    "RxSwift": "UIKit-bound",
    "NextcloudKit": "SwiftUI/Combine-bound",
    "Apollo": "networking-bound",
    "ReactiveSwift": "Foundation-heavy",
    "Nuke": "SwiftUI/Combine-bound",
    "HAKit": "networking-bound",
    "ObjectMapper": "Foundation-heavy",
    "Interstellar": "Foundation-heavy",
    "PromiseKit": "Foundation-heavy",
    "SwipeCellKit": "UIKit-bound",
    "Moya": "networking-bound",
    "DifferenceKit": "UIKit-bound",
}

# OpenUIKit Package.swift products an external package can actually depend on.
# Combine and os are products so an ingested SwiftPM package on Linux can
# `import Combine` / `import os` (17/20 and 13/20 ladder apps,
# scratch/ladder-corpus 2026-09-05, docs/agent_reports/combine-product.md;
# Focus Blockzilla 15 Combine files at a2832521,
# docs/agent_reports/focus-e2e.md). Darwin dependents keep the SDK modules
# via `.product(..., condition: .when(platforms: [.linux]))`.
PORTED_PRODUCTS = {
    "UIKit": "UIKit",
    "OpenUIKit": "OpenUIKit",
    "SwiftUI": "SwiftUI",
    "Symbols": "Symbols",
    "DeveloperToolsSupport": "DeveloperToolsSupport",
    "OpenCoreGraphics": "OpenCoreGraphics",
    "CoreGraphics": "OpenCoreGraphics",
    "Combine": "Combine",
    "os": "os",
    # RealAppProbe harness stubs, now products so ingested Focus on Linux
    # can `import Glean` without a colliding second target (focus-e2e
    # wave1, docker swift:6.2-noble). Not Mozilla Glean / SDK Intents.
    "Glean": "Glean",
    "Intents": "Intents",
    "IntentsUI": "IntentsUI",
    "Onboarding": "Onboarding",
    "Licenses": "Licenses",
    "DesignSystem": "DesignSystem",
    "SnapKit": "SnapKit",
    "WebKit": "WebKit",
    "Sentry": "Sentry",
    "Fuzi": "Fuzi",
    "libkern": "libkern",
    "FocusAppServices": "FocusAppServices",
    "UIHelpers": "UIHelpers",
    "UIComponents": "UIComponents",
    "AppShortcuts": "AppShortcuts",
    "LocalAuthentication": "LocalAuthentication",
    "PassKit": "PassKit",
    "Network": "Network",
    "SafariServices": "SafariServices",
    "StoreKit": "StoreKit",
}

# Simplenote 9b1bb17: these five source dependencies build on Darwin route
# (b). CoreData/AppKit and @objc still prevent claiming a Linux/guest port.
DARWIN_SOURCE_PRODUCTS = {
    "SimplenoteFoundation", "SimplenoteEndpoints", "SimplenoteInterlinks",
    "SimplenoteSearch", "Gridicons", "Simperium", "AutomatticTracks",
    "AutomatticTracksModelObjC",
    # Eidolon 44486ed: ten host modules compile in Swift 4. RxCocoa selects
    # AppKit on route (b); a product is not proof of its inactive UIKit APIs.
    "RxSwift", "RxCocoa", "Moya", "Action", "RxOptional", "NSObject_Rx",
    "SwiftyJSON", "Result", "Alamofire", "Reachability",
    "Keys", "ARAnalytics", "Stripe", "EidolonLaunchCompat",
}
PORTED_PRODUCTS.update({name: name for name in DARWIN_SOURCE_PRODUCTS})

# Route (b) mixed targets (simplenote-launch3). SwiftPM emits
# `<Target>-Swift.h` plus a module map under `.build/<triple>/<cfg>/
# <Target>.build/include/` for every Swift target that a Clang target depends
# on (MEASURED: OpenUIKit.build/include/OpenUIKit-Swift.h, 134 interfaces,
# after `swift build --target OpenUIKit`). That header IS the Objective-C
# UIKit on route (b); OpenUIKitObjCSupport carries the C enums, structs,
# protocols and typed strings the generated header cannot express. The
# ordering Xcode gives a mixed target (Swift first, then the .m files that
# import the generated header) is therefore an ordinary SwiftPM dependency:
# the Clang target depends on the Swift target.
OBJC_SUPPORT_PRODUCT = "OpenUIKitObjCSupport"
# `@objc(selector)` twins of OpenUIKit members (Sources/OpenUIKitObjCBridge);
# SwiftPM emits its generated header the same way. ObjC side only: the Swift
# half already has the members natively.
OBJC_BRIDGE_PRODUCT = "OpenUIKitObjCBridge"
OBJC_DARWIN_PRODUCTS = {"Simperium", "AutomatticTracksModelObjC"}
# The app's Swift half reads the OpenUIKit Clang module through the bridging
# header, and OpenUIKit imports AppKit on macOS (FoundationTypes.swift:63), so
# these six OpenUIKit classes collide with AppKit's: `'NSLayoutConstraint' has
# different definitions in different modules` (MEASURED probe1). Renaming the
# identifiers for the Swift-side parse keeps the runtime name, and Swift maps
# the interface back to the OpenUIKit class (MEASURED probe1: an ObjC
# subclass of the module's UITextView is assignable to OpenUIKit.UITextView;
# a textual copy of the same header is NOT mapped).
SWIFT_SIDE_NS_RENAMES = [
    "NSAdaptiveImageGlyph", "NSLayoutConstraint", "NSLayoutManager",
    "NSTextAttachment", "NSTextAttachmentViewProvider", "NSTextContainer",
]
# Where SwiftPM writes OpenUIKit's generated header, relative to the generated
# package root (MEASURED: swiftc runs with the package root as cwd, so a
# relative -Xcc -I resolves). Missing directories are ignored by clang.
GENERATED_HEADER_DIRS = [
    f".build/{triple}/{cfg}/OpenUIKit.build/include"
    for cfg in ("debug", "release")
    for triple in ("arm64-apple-macosx", "x86_64-apple-macosx")
]
# OpenUIKit names these modules differently per platform (Package.swift:155):
# the literal Apple names on Linux, OpenUIKit* on Darwin. SwiftPM validates a
# product name even under a platform condition (MEASURED: `product 'libkern'
# required by package ... not found` on macOS), so the generated manifest
# carries the same #if.
PLATFORM_NAMED_PRODUCTS = [("libkern", "OpenUIKitLibkern"), ("StoreKit", "OpenUIKitStoreKit")]

# Toolchain modules that exist on Linux Swift without an OpenUIKit product.
TOOLCHAIN_MODULES = {
    "Foundation",
    "FoundationEssentials",
    "Dispatch",
    "Darwin",
    "Glibc",
    "Observation",
    "Synchronization",
    "_Concurrency",
    "Swift",
}

UIKIT_FAMILY_PREFIXES = (
    "UI",
    "WK",
    "AV",
    "MK",
    "SK",
    "PK",
    "HK",
    "CN",
    "EK",
    "IN",
    "UN",
    "AS",
    "QL",
    "PH",
    "AR",
    "VN",
    "GC",
    "GK",
    "HM",
    "CK",
    "NSLayout",
    "CA",
)

NETWORKING_MODULES = {
    "Network",
    "NetworkExtension",
    "CFNetwork",
    "MultipeerConnectivity",
}

OBJC_MODULES = {
    "ObjectiveC",
    "objc",
    "FoundationXML",
}

SOURCE_EXTENSIONS = {".swift", ".m", ".mm", ".c", ".cc", ".cpp", ".h", ".hpp"}
SWIFT_EXT = ".swift"
OBJC_EXT = {".m", ".mm"}
C_EXT = {".c", ".cc", ".cpp"}
HEADER_EXT = {".h", ".hpp"}
RESOURCE_CATALOG_EXT = {".xcassets"}
NIB_EXT = {".xib", ".storyboard"}
STRINGS_EXT = {".strings", ".stringsdict"}
JSON_EXT = {".json"}
RESOURCE_EXT = RESOURCE_CATALOG_EXT | NIB_EXT | STRINGS_EXT | JSON_EXT

TEST_PRODUCT_TYPES = {
    "com.apple.product-type.bundle.unit-test",
    "com.apple.product-type.bundle.ui-testing",
}
APP_PRODUCT_TYPE = "com.apple.product-type.application"
WATCH_HINTS = ("watch", "watchkit")
TEST_PATH_HINTS = ("tests/", "uitests/", "uitest/", "snapshottests/", "screenshottests/")

SKIP_DIR_NAMES = {
    ".git",
    "xcuserdata",
    "DerivedData",
    "Pods",
    "Carthage",
    ".build",
    "build",
}

IMPORT_RE = re.compile(
    r"^(?:@testable\s+|@_exported\s+)?import\s+"
    r"(?:(?:class|struct|enum|func|var|let|typealias)\s+)?"
    r"([A-Za-z_][A-Za-z0-9_]*)",
    re.MULTILINE,
)

SETTING_VAR_RE = re.compile(r"\$\(([^)]+)\)|\$\{([^}]+)\}")
XCCONFIG_INCLUDE_RE = re.compile(r'^#include(\?)?\s+"([^"]+)"')
XCCONFIG_ASSIGN_RE = re.compile(
    r"^([A-Za-z_][A-Za-z0-9_]*)\s*(?:\[[^\]]+\])?\s*=\s*(.*)$"
)
PACKAGE_NAME_RE = re.compile(r'Package\s*\(\s*name\s*:\s*"([^"]+)"', re.DOTALL)
PACKAGE_PRODUCT_RE = re.compile(
    r'\.(?:library|executable|plugin)\s*\(\s*name\s*:\s*"([^"]+)"'
)
SWIFT_TOOLS_VERSION_RE = re.compile(
    r"^//\s*swift-tools-version:\s*([0-9.]+)", re.MULTILINE
)


def parse_xcconfig(path: Path, *, seen: set[Path] | None = None) -> dict[str, str]:
    """Read an .xcconfig, following #include / #include? (Pocket Casts config/).

    Assignment order is include-then-body, matching Xcode: a later KEY = value
    in the same file wins over an included one. Conditional keys (KEY[sdk=…])
    are stored under the bare KEY — none of the three ladder apps use a
    conditional for PRODUCT_BUNDLE_IDENTIFIER.
    """
    settings: dict[str, str] = {}
    if seen is None:
        seen = set()
    try:
        resolved = path.resolve()
    except OSError:
        return settings
    if resolved in seen or not path.is_file():
        return settings
    seen.add(resolved)
    try:
        text = path.read_text(encoding="utf-8")
    except OSError:
        return settings
    for raw_line in text.splitlines():
        line = raw_line.strip()
        if not line or line.startswith("//"):
            continue
        include = XCCONFIG_INCLUDE_RE.match(line)
        if include:
            nested = path.parent / include.group(2)
            included = parse_xcconfig(nested, seen=seen)
            settings.update(included)
            continue
        comment = line.find(" //")
        if comment >= 0:
            line = line[:comment].rstrip()
        assign = XCCONFIG_ASSIGN_RE.match(line)
        if not assign:
            continue
        settings[assign.group(1)] = assign.group(2).strip()
    return settings


def read_package_swift_metadata(manifest: Path) -> dict[str, Any]:
    """Pull name / products / tools-version off a Package.swift with regex.

    Not a Swift parser — the three ladder packages (and MiniApp has none) use
    the conventional `Package(name: "…")` / `.library(name: "…")` form.
    """
    info: dict[str, Any] = {
        "package_name": None,
        "tools_version": None,
        "products": [],
    }
    if not manifest.is_file():
        return info
    try:
        text = manifest.read_text(encoding="utf-8")
    except OSError:
        return info
    tools = SWIFT_TOOLS_VERSION_RE.search(text)
    if tools:
        info["tools_version"] = tools.group(1)
    name = PACKAGE_NAME_RE.search(text)
    if name:
        info["package_name"] = name.group(1)
    info["products"] = PACKAGE_PRODUCT_RE.findall(text)
    return info


class IngestError(Exception):
    """The project cannot be turned into an OpenUIKit package."""


# ---------------------------------------------------------------------------
# PBX graph
# ---------------------------------------------------------------------------


def _as_dict(value: Any, context: str) -> dict[str, Any]:
    if not isinstance(value, dict):
        raise IngestError(f"{context} must be a dictionary, got {type(value).__name__}")
    return value


def _as_list(value: Any, context: str) -> list[Any]:
    if value is None:
        return []
    if not isinstance(value, list):
        raise IngestError(f"{context} must be an array, got {type(value).__name__}")
    return value


def _as_str(value: Any, context: str) -> str:
    if not isinstance(value, str):
        raise IngestError(f"{context} must be a string, got {type(value).__name__}")
    return value


def _safe_join(base: str, component: str) -> str:
    if not component:
        return base
    if component.startswith("/"):
        raise IngestError(f"absolute path not allowed: {component!r}")
    combined = posixpath.normpath(posixpath.join(base, component) if base else component)
    if combined == ".":
        return ""
    if combined == ".." or combined.startswith("../"):
        raise IngestError(f"path escapes the project: {combined!r}")
    return combined


class ProjectGraph:
    def __init__(self, project_bundle: Path) -> None:
        bundle = project_bundle.resolve()
        if bundle.is_file() and bundle.name == "project.pbxproj":
            bundle = bundle.parent
        if bundle.suffix != ".xcodeproj" or not bundle.is_dir():
            raise IngestError(f"expected an .xcodeproj directory, got {project_bundle}")
        pbx = bundle / "project.pbxproj"
        if not pbx.is_file():
            raise IngestError(f"missing {pbx}")
        self.bundle = bundle
        self.source_root = bundle.parent
        self.project_name = bundle.stem
        parsed = parse_openstep(pbx.read_text(encoding="utf-8"), str(pbx))
        root = _as_dict(parsed, "project.pbxproj")
        self.objects = _as_dict(root.get("objects"), "objects")
        self.project_id = _as_str(root.get("rootObject"), "rootObject")
        self.project = self.object(self.project_id, "PBXProject")
        self.main_group_id = _as_str(self.project.get("mainGroup"), "mainGroup")
        self.parents: dict[str, str] = {}
        self._group_cache: dict[str, str] = {}
        self._index_parents()

    def object(self, object_id: str, expected_isa: str | tuple[str, ...] | None = None) -> dict[str, Any]:
        if object_id not in self.objects:
            raise IngestError(f"unresolved PBX object {object_id}")
        obj = _as_dict(self.objects[object_id], f"object {object_id}")
        isa = _as_str(obj.get("isa"), f"{object_id}.isa")
        if expected_isa is not None:
            choices = (expected_isa,) if isinstance(expected_isa, str) else expected_isa
            if isa not in choices:
                raise IngestError(
                    f"object {object_id} has isa {isa!r}; expected {' or '.join(choices)}"
                )
        return obj

    def _index_parents(self) -> None:
        for parent_id, raw in self.objects.items():
            if not isinstance(raw, dict):
                continue
            isa = raw.get("isa")
            if isa in {"PBXGroup", "PBXVariantGroup", "XCVersionGroup"}:
                for child in _as_list(raw.get("children"), f"{parent_id}.children"):
                    child_id = _as_str(child, f"child of {parent_id}")
                    self.parents.setdefault(child_id, parent_id)

    def native_targets(self) -> list[tuple[str, dict[str, Any]]]:
        result = []
        for tid in _as_list(self.project.get("targets"), "PBXProject.targets"):
            tid = _as_str(tid, "target id")
            obj = self.object(tid)
            if obj.get("isa") == "PBXNativeTarget":
                result.append((tid, obj))
        return result

    def pick_app_target(self, name: str | None) -> tuple[str, dict[str, Any]]:
        apps: list[tuple[str, dict[str, Any]]] = []
        for tid, obj in self.native_targets():
            product = obj.get("productType", "")
            tname = obj.get("name") or obj.get("productName") or tid
            if name is not None and tname == name:
                return tid, obj
            if product == APP_PRODUCT_TYPE:
                apps.append((tid, obj))
        if name is not None:
            available = sorted(
                (o.get("name") or tid) for tid, o in self.native_targets()
            )
            raise IngestError(
                f"no native target named {name!r}; known targets: {available}"
            )
        if not apps:
            raise IngestError("no com.apple.product-type.application target")
        def score(item: tuple[str, dict[str, Any]]) -> tuple[int, str]:
            tname = (item[1].get("name") or "").lower()
            penalty = 0
            if any(h in tname for h in WATCH_HINTS):
                penalty += 10
            if "clip" in tname or "widget" in tname:
                penalty += 5
            if tname == self.project_name.lower():
                penalty -= 2
            return (penalty, tname)
        apps.sort(key=score)
        return apps[0]

    def _group_directory(self, group_id: str, active: frozenset[str] = frozenset()) -> str:
        if group_id in self._group_cache:
            return self._group_cache[group_id]
        if group_id in active:
            raise IngestError(f"cycle in PBX group graph at {group_id}")
        group = self.object(group_id)
        isa = group.get("isa")
        if isa == "PBXFileSystemSynchronizedRootGroup":
            return self._sync_root_directory(group_id)
        if group_id == self.main_group_id:
            parent_path = ""
        else:
            parent_id = self.parents.get(group_id)
            if parent_id is None:
                parent_path = ""
            else:
                parent_path = self._group_directory(parent_id, active | {group_id})
        source_tree = group.get("sourceTree", "<group>")
        component = group.get("path") or ""
        if source_tree in {"SOURCE_ROOT", "PROJECT_DIR"}:
            result = component
        else:
            result = _safe_join(parent_path, component)
        self._group_cache[group_id] = result
        return result

    def _sync_root_directory(self, group_id: str) -> str:
        group = self.object(group_id, "PBXFileSystemSynchronizedRootGroup")
        parent_id = self.parents.get(group_id)
        parent_path = self._group_directory(parent_id) if parent_id else ""
        source_tree = group.get("sourceTree", "<group>")
        component = group.get("path") or group.get("name") or ""
        if source_tree in {"SOURCE_ROOT", "PROJECT_DIR"}:
            return component
        return _safe_join(parent_path, component)

    def _containing_directory(self, ref_id: str) -> str:
        parent_id = self.parents.get(ref_id)
        if parent_id is None:
            return ""
        parent = self.object(parent_id)
        isa = parent.get("isa")
        if isa == "PBXVariantGroup":
            return self._group_directory(parent_id) if parent_id in self.parents else (
                parent.get("path") or ""
            )
        if isa == "PBXFileSystemSynchronizedRootGroup":
            return self._sync_root_directory(parent_id)
        if isa in {"PBXGroup", "XCVersionGroup"}:
            return self._group_directory(parent_id)
        return ""

    def xcconfig_path(self, cfg: dict[str, Any]) -> Path | None:
        """Resolve XCBuildConfiguration's base .xcconfig (classic file ref or Xcode 16 anchor).

        Pocket Casts Debug/Release (project.pbxproj BDBD540C / BDBD540D) use
        `baseConfigurationReferenceAnchor` + `baseConfigurationReferenceRelativePath`
        pointing at the `config` PBXFileSystemSynchronizedRootGroup —
        `config/PocketCasts.debug.xcconfig` on disk. That file's PRODUCT_BUNDLE_IDENTIFIER
        is `$(PRODUCT_BUNDLE_IDENTIFIER_ROOT)` = `au.com.shiftyjelly.podcasts`.
        """
        rel = cfg.get("baseConfigurationReferenceRelativePath")
        anchor = cfg.get("baseConfigurationReferenceAnchor")
        if anchor and rel:
            anchor_id = _as_str(anchor, "baseConfigurationReferenceAnchor")
            anchor_obj = self.object(anchor_id)
            isa = anchor_obj.get("isa")
            if isa == "PBXFileSystemSynchronizedRootGroup":
                base = self._sync_root_directory(anchor_id)
            elif isa in {"PBXGroup", "XCVersionGroup"}:
                base = self._group_directory(anchor_id)
            else:
                resolved = self.resolve_file(anchor_id)
                base = posixpath.dirname(resolved.get("path") or "")
            joined = _safe_join(base, rel)
            return self.source_root / joined
        ref = cfg.get("baseConfigurationReference")
        if ref:
            resolved = self.resolve_file(_as_str(ref, "baseConfigurationReference"))
            path = resolved.get("path")
            if path and not resolved.get("external_tree"):
                return self.source_root / path
        return None

    def resolve_file(self, ref_id: str) -> dict[str, Any]:
        obj = self.object(ref_id)
        isa = obj.get("isa")
        source_tree = obj.get("sourceTree", "<group>")
        component = obj.get("path") or obj.get("name") or ""
        result: dict[str, Any] = {
            "id": ref_id,
            "isa": isa,
            "name": obj.get("name") or posixpath.basename(component),
            "source_tree": source_tree,
            "file_type": obj.get("lastKnownFileType") or obj.get("explicitFileType"),
        }
        if isa == "PBXVariantGroup":
            logical = obj.get("name") or obj.get("path") or component
            result["path"] = _safe_join(self._containing_directory(ref_id), logical)
            variants = []
            for child in _as_list(obj.get("children"), f"{ref_id}.children"):
                child_id = _as_str(child, "variant child")
                variants.append(self.resolve_file(child_id))
            result["variants"] = variants
            return result
        if source_tree in {"BUILT_PRODUCTS_DIR", "DEVELOPER_DIR", "SDKROOT"}:
            result["path"] = component
            result["external_tree"] = source_tree
            return result
        if source_tree in {"SOURCE_ROOT", "PROJECT_DIR", "<absolute>"}:
            result["path"] = component.lstrip("/")
            return result
        result["path"] = _safe_join(self._containing_directory(ref_id), component)
        return result

    def _phase_files(self, target: dict[str, Any], isa: str) -> list[dict[str, Any]]:
        files: list[dict[str, Any]] = []
        for phase_id in _as_list(target.get("buildPhases"), "buildPhases"):
            phase = self.object(_as_str(phase_id, "phase"))
            if phase.get("isa") != isa:
                continue
            for bf_id in _as_list(phase.get("files"), f"{phase_id}.files"):
                build_file = self.object(_as_str(bf_id, "build file"))
                file_ref = build_file.get("fileRef")
                product_ref = build_file.get("productRef")
                if file_ref:
                    resolved = self.resolve_file(_as_str(file_ref, "fileRef"))
                    resolved["build_file_id"] = bf_id
                    files.append(resolved)
                elif product_ref:
                    files.append(
                        {
                            "id": product_ref,
                            "isa": "XCSwiftPackageProductDependency",
                            "product_ref": product_ref,
                            "build_file_id": bf_id,
                        }
                    )
        return files

    def _membership_exceptions(self, group: dict[str, Any], target_id: str) -> set[str]:
        excluded: set[str] = set()
        for raw in _as_list(group.get("exceptions"), "exceptions"):
            exception = self.object(_as_str(raw, "exception"))
            if exception.get("isa") != "PBXFileSystemSynchronizedBuildFileExceptionSet":
                continue
            if exception.get("target") != target_id:
                continue
            for item in _as_list(
                exception.get("membershipExceptions"), "membershipExceptions"
            ):
                excluded.add(_as_str(item, "membership exception"))
        return excluded

    def _walk_synchronized(self, group_id: str, target_id: str) -> list[dict[str, Any]]:
        group = self.object(group_id, "PBXFileSystemSynchronizedRootGroup")
        relative_root = self._sync_root_directory(group_id)
        root_path = self.source_root / relative_root
        if not root_path.is_dir():
            return []
        excluded = self._membership_exceptions(group, target_id)
        items: list[dict[str, Any]] = []

        def visit(directory: Path, prefix: str) -> None:
            try:
                entries = sorted(directory.iterdir(), key=lambda p: p.name)
            except OSError:
                return
            for entry in entries:
                name = entry.name
                if name in SKIP_DIR_NAMES or name.startswith("."):
                    continue
                child_rel = name if not prefix else f"{prefix}/{name}"
                if child_rel in excluded or any(
                    child_rel == ex or child_rel.startswith(ex.rstrip("/") + "/")
                    for ex in excluded
                ):
                    continue
                if entry.is_symlink():
                    continue
                if entry.is_dir():
                    suffix = entry.suffix.lower()
                    if suffix in RESOURCE_CATALOG_EXT | {".lproj"}:
                        items.append(
                            {
                                "id": group_id,
                                "isa": "PBXFileSystemSynchronizedRootGroup",
                                "name": name,
                                "path": _safe_join(relative_root, child_rel),
                                "origin": "filesystem_synchronized",
                                "directory": True,
                            }
                        )
                        continue
                    visit(entry, child_rel)
                    continue
                items.append(
                    {
                        "id": group_id,
                        "isa": "PBXFileSystemSynchronizedRootGroup",
                        "name": name,
                        "path": _safe_join(relative_root, child_rel),
                        "origin": "filesystem_synchronized",
                        "file_type": None,
                    }
                )

        visit(root_path, "")
        return items

    def target_inputs(self, target_id: str, target: dict[str, Any]) -> dict[str, list[dict[str, Any]]]:
        sources = self._phase_files(target, "PBXSourcesBuildPhase")
        resources = self._phase_files(target, "PBXResourcesBuildPhase")
        frameworks = self._phase_files(target, "PBXFrameworksBuildPhase")
        for group_id in _as_list(
            target.get("fileSystemSynchronizedGroups"), "fileSystemSynchronizedGroups"
        ):
            gid = _as_str(group_id, "sync group")
            for item in self._walk_synchronized(gid, target_id):
                path = item.get("path") or ""
                lower = path.lower()
                ext = Path(path).suffix.lower()
                if ext in OBJC_EXT | {SWIFT_EXT} or ext in {".c", ".cc", ".cpp"}:
                    sources.append(item)
                elif (
                    ext in RESOURCE_EXT
                    or item.get("directory")
                    or lower.endswith(".lproj")
                    or ext in RESOURCE_CATALOG_EXT
                ):
                    resources.append(item)
                elif ext:
                    resources.append(item)
        return {"sources": sources, "resources": resources, "frameworks": frameworks}

    def local_package_infos(self) -> list[dict[str, Any]]:
        """Local Swift packages the pbxproj actually references.

        Two measured forms:
        * XCLocalSwiftPackageReference (Hackers Data/Domain/Features/…)
        * PBXFileReference lastKnownFileType = wrapper whose path holds
          Package.swift (Focus BlockzillaPackage — there is no
          XCLocalSwiftPackageReference for it; Xcode 16 omits `package =`
          on the unique product names UIHelpers/DesignSystem/Onboarding/…)
        """
        infos: list[dict[str, Any]] = []
        seen: set[str] = set()

        def add_root(relative: str) -> None:
            relative = relative.rstrip("/")
            if not relative or relative in seen:
                return
            manifest = self.source_root / relative / "Package.swift"
            if not manifest.is_file():
                return
            seen.add(relative)
            meta = read_package_swift_metadata(manifest)
            infos.append(
                {
                    "relative_path": relative,
                    "package_name": meta["package_name"] or posixpath.basename(relative),
                    "tools_version": meta["tools_version"],
                    "products": meta["products"],
                }
            )

        for raw in _as_list(self.project.get("packageReferences"), "packageReferences"):
            ref = self.object(_as_str(raw, "package reference"))
            if ref.get("isa") != "XCLocalSwiftPackageReference":
                continue
            add_root(ref.get("relativePath") or "")

        for oid, obj in self.objects.items():
            if not isinstance(obj, dict):
                continue
            if obj.get("isa") != "PBXFileReference":
                continue
            if obj.get("lastKnownFileType") != "wrapper":
                continue
            try:
                resolved = self.resolve_file(oid)
            except IngestError:
                continue
            rel = resolved.get("path") or ""
            if resolved.get("external_tree") or not rel:
                continue
            add_root(rel)
        return infos

    def local_package_product_map(self) -> dict[str, str]:
        """productName -> relativePath for XCLocalSwiftPackageReference / wrapper packages.

        Xcode 16 omits `package =` on XCSwiftPackageProductDependency when the
        product name is unique in the workspace (Hackers Data/Domain/Feed,
        Focus DesignSystem). Ownership is recovered from the local Package.swift
        files the project already references — measured, not guessed from
        directory names alone.
        """
        mapping: dict[str, str] = {}
        for info in self.local_package_infos():
            relative = info["relative_path"]
            mapping[posixpath.basename(relative)] = relative
            mapping[info["package_name"]] = relative
            for product in info["products"]:
                mapping[product] = relative
        return mapping

    def package_products(self, target: dict[str, Any]) -> list[dict[str, Any]]:
        local_products = self.local_package_product_map()
        local_by_path = {info["relative_path"]: info for info in self.local_package_infos()}
        result = []
        for raw in _as_list(
            target.get("packageProductDependencies"), "packageProductDependencies"
        ):
            pid = _as_str(raw, "package product")
            product = self.object(pid, "XCSwiftPackageProductDependency")
            item: dict[str, Any] = {
                "id": pid,
                "name": product.get("productName") or pid,
            }
            package_id = product.get("package")
            if package_id is None:
                # Unique-product omission (Xcode 16). Recover from local refs.
                local = local_products.get(item["name"])
                if local:
                    item["origin"] = "local"
                    item["relative_path"] = local
                    item["package_id_omitted"] = True
                else:
                    item["origin"] = "implicit"
            else:
                package = self.object(_as_str(package_id, "package"))
                isa = package.get("isa")
                if isa == "XCRemoteSwiftPackageReference":
                    item["origin"] = "remote"
                    item["repository_url"] = package.get("repositoryURL")
                    item["requirement"] = package.get("requirement")
                elif isa == "XCLocalSwiftPackageReference":
                    item["origin"] = "local"
                    item["relative_path"] = package.get("relativePath")
                else:
                    item["origin"] = isa or "unknown"
            rel = item.get("relative_path")
            if rel and rel in local_by_path:
                info = local_by_path[rel]
                item["package_name"] = info["package_name"]
                item["tools_version"] = info["tools_version"]
            result.append(item)
        return result

    def merged_settings(self, target: dict[str, Any], preferred: str | None = None) -> dict[str, str]:
        settings: dict[str, str] = {}

        def absorb(config_list_id: Any) -> None:
            if not config_list_id:
                return
            cfg_list = self.object(_as_str(config_list_id, "config list"), "XCConfigurationList")
            configs = []
            for cid in _as_list(cfg_list.get("buildConfigurations"), "buildConfigurations"):
                cfg = self.object(_as_str(cid, "config"), "XCBuildConfiguration")
                configs.append(cfg)
            if not configs:
                return
            chosen = None
            want = preferred or cfg_list.get("defaultConfigurationName")
            if want:
                for cfg in configs:
                    if cfg.get("name") == want:
                        chosen = cfg
                        break
            if chosen is None:
                for name in ("FocusDebug", "Debug", "Release"):
                    for cfg in configs:
                        if cfg.get("name") == name:
                            chosen = cfg
                            break
                    if chosen is not None:
                        break
            if chosen is None:
                chosen = configs[0]
            xc_path = self.xcconfig_path(chosen)
            if xc_path is not None:
                for key, value in parse_xcconfig(xc_path).items():
                    settings[key] = value
            raw = chosen.get("buildSettings") or {}
            if isinstance(raw, dict):
                for key, value in raw.items():
                    if isinstance(value, list):
                        settings[key] = " ".join(str(v) for v in value)
                    elif isinstance(value, str):
                        settings[key] = value
                    else:
                        settings[key] = str(value)

        absorb(self.project.get("buildConfigurationList"))
        absorb(target.get("buildConfigurationList"))
        return settings


def expand_setting(value: str, settings: dict[str, str], extra: dict[str, str] | None = None) -> str:
    env = dict(settings)
    if extra:
        env.update(extra)

    def replace(match: re.Match[str]) -> str:
        name = match.group(1) or match.group(2)
        return env.get(name, match.group(0))

    current = value
    for _ in range(8):
        nxt = SETTING_VAR_RE.sub(replace, current)
        if nxt == current:
            return nxt
        current = nxt
    return current


def is_test_path(path: str) -> bool:
    lower = path.replace("\\", "/").lower()
    base = posixpath.basename(lower)
    if "uitest" in lower or lower.endswith("uitests.swift"):
        return True
    if lower.endswith("tests.swift") and "tests/" in lower:
        return True
    for hint in TEST_PATH_HINTS:
        if hint in lower:
            return True
    if base.endswith("tests.swift") or base.endswith("test.swift"):
        # Keep production helpers named FooTest.swift inside the app target;
        # drop files sitting in a *Tests* directory only. The hints above
        # already caught directory tests. A file called FooTests.swift at
        # the app root of a non-test target is still app code (rare).
        return False
    return False


def classify_module(name: str) -> dict[str, Any]:
    """Return {name, class, port, kind} for an import or package product."""
    if name in PORTED_PRODUCTS:
        if name in LADDER_DEP_CLASS:
            cls = LADDER_DEP_CLASS[name]
        elif name in {"Foundation", "Dispatch", "Combine", "os", "libkern"}:
            cls = "Foundation-heavy"
        elif name == "Fuzi":
            cls = "unmeasured"
        else:
            cls = "UIKit-bound"
        return {
            "name": name,
            "kind": "apple_framework",
            "class": cls,
            "port": PORTED_PRODUCTS[name],
            **({"port_platforms": ["macOS"]} if name in DARWIN_SOURCE_PRODUCTS else {}),
        }
    if name in TOOLCHAIN_MODULES:
        cls = "Foundation-heavy"
        if name in NETWORKING_MODULES:
            cls = "networking"
        return {
            "name": name,
            "kind": "toolchain",
            "class": cls,
            "port": "toolchain",
        }
    if name in LADDER_DEP_CLASS:
        return {
            "name": name,
            "kind": "spm",
            "class": LADDER_DEP_CLASS[name],
            "port": None,
        }
    if name in NETWORKING_MODULES:
        return {
            "name": name,
            "kind": "apple_framework",
            "class": "networking",
            "port": None,
        }
    if name in OBJC_MODULES:
        return {
            "name": name,
            "kind": "apple_framework",
            "class": "ObjC",
            "port": None,
        }
    if name in {"WebKit", "SafariServices", "MessageUI", "StoreKit", "Photos", "PhotosUI",
                "MapKit", "CoreLocation", "AVFoundation", "AVKit", "CoreData",
                "WidgetKit", "AppIntents", "Intents", "IntentsUI", "UserNotifications",
                "AuthenticationServices", "LocalAuthentication", "PassKit", "HealthKit",
                "HomeKit", "CloudKit", "CoreHaptics", "CoreImage", "CoreML",
                "CoreMotion", "CoreBluetooth", "CoreTelephony", "CallKit", "PushKit",
                "BackgroundTasks", "CoreSpotlight", "QuickLook", "LinkPresentation",
                "UniformTypeIdentifiers", "CryptoKit", "Security", "MetricKit",
                "AppTrackingTransparency", "AdSupport", "Speech", "Vision",
                "GameKit", "ReplayKit", "WatchKit", "WatchConnectivity",
                "NotificationCenter", "CoreServices", "MobileCoreServices",
                "ImageIO", "CoreText", "CoreMedia", "CoreVideo", "AudioToolbox",
                "MediaPlayer", "JavaScriptCore", "Accounts", "Social",
                "AddressBook", "AddressBookUI", "EventKit", "EventKitUI",
                "Contacts", "ContactsUI", "CoreNFC", "NearbyInteraction",
                "DeviceCheck", "ClassKit", "PencilKit", "RealityKit",
                "SceneKit", "SpriteKit", "GameplayKit", "Metal", "MetalKit",
                "GLKit", "OpenGLES", "ARKit", "VisionKit", "QuickLookThumbnailing",
                "FileProvider", "FileProviderUI", "IdentityLookup",
                "NaturalLanguage", "CreateML", "SoundAnalysis", "ShazamKit",
                "ActivityKit", "AlarmKit", "TipKit", "Translation", "SwiftData",
                "Charts", "CoreTransferable", "GroupActivities", "ScreenTime",
                "ManagedSettings", "FamilyControls", "BrowserEngineKit",
                "CarPlay", "ClockKit", "CoreAudio", "CoreAudioKit",
                "CoreMIDI", "ExternalAccessory", "GLKit", "IOKit",
                "MultipeerConnectivity", "NetworkExtension", "PDFKit",
                "Photos", "QuartzCore", "SystemConfiguration"}:
        cls = "networking" if name in NETWORKING_MODULES else "UIKit-bound"
        if name in {"CoreData", "CloudKit", "CryptoKit", "Security", "CoreML",
                    "NaturalLanguage", "SwiftData"}:
            cls = "Foundation-heavy"
        return {
            "name": name,
            "kind": "apple_framework",
            "class": cls,
            "port": None,
        }
    # Unknown SPM / in-tree module. Leave class empty of a guess that would
    # pretend we measured it; the ladder only classified 30 deps.
    return {
        "name": name,
        "kind": "unknown",
        "class": "unmeasured",
        "port": None,
    }


def scan_imports(source_root: Path, paths: list[str]) -> dict[str, int]:
    counts: dict[str, int] = {}
    for rel in paths:
        full = source_root / rel
        if not full.is_file():
            continue
        try:
            text = full.read_text(encoding="utf-8")
        except (OSError, UnicodeDecodeError):
            continue
        for match in IMPORT_RE.finditer(text):
            name = match.group(1)
            counts[name] = counts.get(name, 0) + 1
    return counts


def detect_repo_gaps(source_root: Path, sources: list[dict[str, Any]]) -> list[dict[str, str]]:
    gaps: list[dict[str, str]] = []
    if (source_root / "Podfile").is_file() or (source_root / "Pods").is_dir():
        gaps.append(
            {
                "kind": "CocoaPods",
                "detail": "Podfile or Pods/ present; CocoaPods has no OpenUIKit port",
            }
        )
    if (source_root / "Cartfile").is_file() or (source_root / "Carthage").is_dir():
        gaps.append(
            {
                "kind": "Carthage",
                "detail": "Cartfile or Carthage/ present; Carthage has no OpenUIKit port",
            }
        )
    # Mixed Swift/Clang sources are emitted as separate dependent targets.
    return gaps


def resource_bucket(path: str) -> str | None:
    lower = path.lower()
    ext = Path(path).suffix.lower()
    if ext in RESOURCE_CATALOG_EXT or lower.endswith(".xcassets"):
        return "xcassets"
    if ext in NIB_EXT:
        return "nibs"
    if ext in STRINGS_EXT or lower.endswith(".lproj") or "/.lproj/" in lower or ".lproj/" in lower:
        return "strings"
    if ext in JSON_EXT:
        return "json"
    return None


def flatten_resource_paths(item: dict[str, Any]) -> list[str]:
    if item.get("variants"):
        paths = []
        for variant in item["variants"]:
            paths.extend(flatten_resource_paths(variant))
        return paths
    path = item.get("path")
    if not path or item.get("external_tree"):
        return []
    return [path]


def read_info_keys(graph: ProjectGraph, target: dict[str, Any], settings: dict[str, str]) -> dict[str, Any]:
    extra = {
        "TARGET_NAME": target.get("name") or "",
        "PRODUCT_NAME": settings.get("PRODUCT_NAME") or target.get("productName") or target.get("name") or "",
        "PROJECT_NAME": graph.project_name,
        "SRCROOT": "",
        "SOURCE_ROOT": "",
    }
    product_name = expand_setting(settings.get("PRODUCT_NAME") or extra["PRODUCT_NAME"], settings, extra)
    extra["PRODUCT_NAME"] = product_name
    bundle_id = expand_setting(
        settings.get("PRODUCT_BUNDLE_IDENTIFIER") or "", settings, extra
    )
    display = expand_setting(
        settings.get("INFOPLIST_KEY_CFBundleDisplayName")
        or settings.get("INFOPLIST_KEY_CFBundleName")
        or product_name,
        settings,
        extra,
    )
    info_file = settings.get("INFOPLIST_FILE") or ""
    info_file = expand_setting(info_file, settings, extra)
    plist_keys: dict[str, Any] = {}
    if info_file and info_file not in {"YES", "NO"}:
        candidate = graph.source_root / info_file
        if candidate.is_file():
            try:
                parsed = parse_plist_file(candidate)
            except (OpenStepError, OSError, UnicodeDecodeError) as exc:
                plist_keys["_error"] = str(exc)
            else:
                if isinstance(parsed, dict):
                    for key in (
                        "CFBundleIdentifier",
                        "CFBundleDisplayName",
                        "CFBundleName",
                        "CFBundleExecutable",
                        "CFBundleShortVersionString",
                        "CFBundleVersion",
                    ):
                        if key in parsed:
                            value = parsed[key]
                            if isinstance(value, str):
                                plist_keys[key] = expand_setting(value, settings, extra)
                            else:
                                plist_keys[key] = value
    if "CFBundleIdentifier" not in plist_keys and bundle_id:
        plist_keys["CFBundleIdentifier"] = bundle_id
    if "CFBundleDisplayName" not in plist_keys and display:
        plist_keys["CFBundleDisplayName"] = display
    if "CFBundleName" not in plist_keys and product_name:
        plist_keys["CFBundleName"] = product_name
    return {
        "info_plist_file": info_file or None,
        "bundle_identifier": plist_keys.get("CFBundleIdentifier"),
        "display_name": plist_keys.get("CFBundleDisplayName") or plist_keys.get("CFBundleName"),
        "product_name": product_name,
        "keys": plist_keys,
        "configuration_settings": {
            k: settings[k]
            for k in (
                "PRODUCT_BUNDLE_IDENTIFIER",
                "PRODUCT_NAME",
                "INFOPLIST_FILE",
                "INFOPLIST_KEY_CFBundleDisplayName",
                "GENERATE_INFOPLIST_FILE",
            )
            if k in settings
        },
    }


def build_manifest(
    graph: ProjectGraph,
    target_id: str,
    target: dict[str, Any],
    *,
    preferred_configuration: str | None = None,
) -> dict[str, Any]:
    tname = target.get("name") or target.get("productName") or target_id
    settings = graph.merged_settings(target, preferred_configuration)
    inputs = graph.target_inputs(target_id, target)
    packages = graph.package_products(target)

    swift_sources = []
    other_sources = []
    for item in inputs["sources"]:
        path = item.get("path") or ""
        if item.get("external_tree"):
            continue
        ext = Path(path).suffix.lower()
        if ext == SWIFT_EXT:
            if is_test_path(path):
                continue
            swift_sources.append(path)
        elif ext:
            other_sources.append({"path": path, "ext": ext})

    # Preserve PBX order, then drop duplicates (sync walk can re-list).
    seen: set[str] = set()
    ordered_swift: list[str] = []
    for path in swift_sources:
        if path in seen:
            continue
        seen.add(path)
        ordered_swift.append(path)

    resources: dict[str, list[str]] = {"xcassets": [], "nibs": [], "strings": [], "json": []}
    other_resources: list[str] = []
    for item in inputs["resources"]:
        for path in flatten_resource_paths(item):
            bucket = resource_bucket(path)
            if bucket:
                if path not in resources[bucket]:
                    resources[bucket].append(path)
            else:
                other_resources.append(path)

    linked_frameworks = []
    for item in inputs["frameworks"]:
        if item.get("product_ref"):
            continue
        name = item.get("name") or posixpath.basename(item.get("path") or "")
        if name.endswith(".framework"):
            name = name[: -len(".framework")]
        if not name:
            continue
        linked_frameworks.append(name)

    import_counts = scan_imports(graph.source_root, ordered_swift)
    imports = []
    for name, count in sorted(import_counts.items(), key=lambda kv: (-kv[1], kv[0])):
        row = classify_module(name)
        row["files"] = count
        imports.append(row)

    spm_rows = []
    for pkg in packages:
        row = classify_module(pkg["name"])
        row["kind"] = "spm_" + pkg.get("origin", "unknown")
        row["origin"] = pkg.get("origin")
        if pkg.get("repository_url"):
            row["repository_url"] = pkg["repository_url"]
        if pkg.get("relative_path"):
            row["relative_path"] = pkg["relative_path"]
        if pkg.get("package_name"):
            row["package_name"] = pkg["package_name"]
        if pkg.get("tools_version"):
            row["tools_version"] = pkg["tools_version"]
        if pkg.get("origin") == "local":
            if pkg["name"] in PORTED_PRODUCTS:
                # Focus BlockzillaPackage products now exist on OpenUIKit
                # (UIHelpers / DesignSystem / Onboarding / …). Link them.
                row["port"] = PORTED_PRODUCTS[pkg["name"]]
            else:
                # Copied to LocalPackages/ for inspection. Not rewritten onto
                # OpenUIKit products (Hackers' local packages are swift-tools-version
                # 6.4 / iOS 26 — Linux Swift 6.2 cannot load them).
                row["port"] = None
                row["reason"] = (
                    f"local Swift package {pkg.get('package_name') or pkg['name']} "
                    f"at {pkg.get('relative_path')} (swift-tools-version "
                    f"{pkg.get('tools_version') or 'unknown'}); copied next to the "
                    "generated package, not linked — the port does not rewrite "
                    "third-party Package.swift onto OpenUIKit products"
                )
        spm_rows.append(row)

    framework_rows = []
    seen_fw: set[str] = set()
    for name in linked_frameworks:
        if name in seen_fw:
            continue
        seen_fw.add(name)
        row = classify_module(name)
        row["kind"] = "linked_framework"
        framework_rows.append(row)

    objc_sources = [s["path"] for s in other_sources if s["ext"] in OBJC_EXT]
    c_sources = [s["path"] for s in other_sources if s["ext"] in C_EXT]
    header_sources = [s["path"] for s in other_sources if s["ext"] in HEADER_EXT]
    for path in objc_sources + c_sources:
        directory = graph.source_root / posixpath.dirname(path)
        if directory.is_dir():
            for header in directory.rglob("*"):
                if header.is_file() and header.suffix.lower() in HEADER_EXT:
                    rel = header.relative_to(graph.source_root).as_posix()
                    if not is_test_path(rel) and rel not in header_sources:
                        header_sources.append(rel)
    header_sources.sort()
    bridging_header = None
    raw_bridging_header = settings.get("SWIFT_OBJC_BRIDGING_HEADER")
    if raw_bridging_header:
        expanded = expand_setting(raw_bridging_header, settings)
        if not expanded.startswith("$"):
            bridging_header = expanded
            if (graph.source_root / expanded).is_file() and expanded not in header_sources:
                header_sources.append(expanded)
                header_sources.sort()
    swift_header_consumers: list[str] = []
    # Eidolon 44486ed BridgingHeader.h imports sibling PodsBridgingHeader.h,
    # which is not a PBX source. Follow existing local quoted includes rather
    # than emitting a library with a header we silently failed to copy.
    pending_headers = list(header_sources)
    while pending_headers:
        header = graph.source_root / pending_headers.pop()
        if not header.is_file():
            continue
        for name in re.findall(r'^\s*#\s*(?:import|include)\s*"([^"]+)"',
                               header.read_text(encoding="utf-8", errors="replace"),
                               flags=re.MULTILINE):
            candidate = (header.parent / name).resolve()
            if (not candidate.is_file() or candidate.suffix.lower() not in HEADER_EXT
                    or not candidate.is_relative_to(graph.source_root.resolve())):
                continue
            rel = candidate.relative_to(graph.source_root.resolve()).as_posix()
            if rel not in header_sources:
                header_sources.append(rel)
                pending_headers.append(rel)
    header_sources.sort()
    for path in objc_sources + c_sources + header_sources:
        source = graph.source_root / path
        if source.is_file():
            try:
                text = source.read_text(encoding="utf-8")
            except (OSError, UnicodeDecodeError):
                continue
            for match in re.finditer(r"#\s*import\s*[<\"]([^>\"]+-Swift\.h)[>\"]", text):
                if match.group(1) not in swift_header_consumers:
                    swift_header_consumers.append(match.group(1))

    # Simplenote 9b1bb17: Simplenote/Credentials/SPCredentials.swift is written
    # by a build phase from ~/.configure secrets; the repo ships the public
    # Simplenote/SPCredentials-demo.swift instead. A missing source whose
    # `<stem>-demo.swift` sibling exists in its directory or the parent is
    # emitted under the expected path from that demo. Real credentials are
    # never read.
    demo_substitutes: list[dict[str, str]] = []
    for missing in ordered_swift:
        if (graph.source_root / missing).is_file():
            continue
        stem = PurePosixPath(missing).stem
        directory = posixpath.dirname(missing)
        candidates = [posixpath.join(directory, f"{stem}-demo.swift")]
        if directory:
            candidates.append(posixpath.join(posixpath.dirname(directory), f"{stem}-demo.swift"))
        for candidate in candidates:
            if (graph.source_root / candidate).is_file():
                demo_substitutes.append({"missing": missing, "demo": candidate})
                break

    gaps = detect_repo_gaps(graph.source_root, inputs["sources"])
    local_names: set[str] = set()
    for info in graph.local_package_infos():
        local_names.add(info["package_name"])
        local_names.update(info["products"])
    sibling_names = {
        obj.get("name") for _, obj in graph.native_targets() if obj.get("name")
    }
    known_in_tree = local_names | sibling_names
    no_port = []
    for row in spm_rows + framework_rows + imports:
        if row.get("port"):
            continue
        if row.get("kind") in {"toolchain"}:
            continue
        if row.get("name") in PORTED_PRODUCTS:
            continue
        if row.get("kind") == "unknown" and row.get("class") == "unmeasured":
            if row["name"] in known_in_tree:
                # Local SPM product or sibling PBX target (Hackers Domain,
                # Focus DesignSystem). Not an Apple/SPM port gap.
                continue
            # Linux swift:6.2-noble first error on Pocket Casts (with
            # --allow-gaps) is `no such module 'AutomatticTracks'` —
            # ABTestProvider.swift:1. Xcode 16's packageProductDependencies
            # lists only `XcodeTarget_podcasts`; the real module is recovered
            # from the import, not guessed.
            no_port.append(
                {
                    "name": row["name"],
                    "kind": "import",
                    "class": "unmeasured",
                    "reason": (
                        f"{row['name']} is imported by the app target but is "
                        "not a local Swift package product, not a sibling PBX "
                        "target, and has no OpenUIKit package product (not one "
                        "of the 30 ladder-classified deps)"
                    ),
                }
            )
            continue
        if row.get("kind") in {"apple_framework", "linked_framework", "spm", "spm_remote", "spm_local"}:
            if row.get("port") is None:
                no_port.append(
                    {
                        "name": row["name"],
                        "kind": row["kind"],
                        "class": row["class"],
                        "reason": row.get("reason")
                        or f"{row['name']} has no OpenUIKit package product "
                        f"(ladder class {row['class']})",
                    }
                )

    # Dedup no_port by name.
    seen_np: set[str] = set()
    unique_no_port = []
    for item in no_port:
        if item["name"] in seen_np:
            continue
        seen_np.add(item["name"])
        unique_no_port.append(item)

    in_tree_modules = [
        row for row in imports
        if row.get("class") == "unmeasured" and row["name"] in known_in_tree
    ]

    info = read_info_keys(graph, target, settings)
    sibling_targets = []
    for tid, obj in graph.native_targets():
        sibling_targets.append(
            {
                "id": tid,
                "name": obj.get("name"),
                "product_type": obj.get("productType"),
            }
        )

    return {
        "project": str(graph.bundle),
        "project_name": graph.project_name,
        "source_root": str(graph.source_root),
        "target": {
            "id": target_id,
            "name": tname,
            "product_type": target.get("productType"),
            "product_name": target.get("productName"),
        },
        "sibling_targets": sibling_targets,
        "info": info,
        "swift_sources": ordered_swift,
        # Simplenote 9b1bb17: 229 PBX references, 228 files; SPCredentials.swift
        # is generated and absent. Never call the PBX count a compile denominator.
        "missing_swift_sources": [p for p in ordered_swift if not (graph.source_root / p).is_file()],
        "demo_substitutes": demo_substitutes,
        "other_sources": other_sources,
        "objc_sources": objc_sources,
        "c_sources": c_sources,
        "header_sources": header_sources,
        "bridging_header": bridging_header,
        "swift_language_version": settings.get("SWIFT_VERSION"),
        "swift_header_consumers": swift_header_consumers,
        "resources": resources,
        "other_resources": other_resources,
        "spm": spm_rows,
        "frameworks": framework_rows,
        "imports": imports,
        "in_tree_modules": [{"name": r["name"], "files": r.get("files")} for r in in_tree_modules],
        "gaps": gaps,
        "no_port": unique_no_port,
        "counts": {
            "swift_sources": len(ordered_swift),
            "present_swift_sources": sum((graph.source_root / p).is_file() for p in ordered_swift),
            "objc_sources": sum(1 for s in other_sources if s["ext"] in OBJC_EXT),
            "c_sources": sum(1 for s in other_sources if s["ext"] in C_EXT),
            "header_sources": len(header_sources),
            "xcassets": len(resources["xcassets"]),
            "nibs": len(resources["nibs"]),
            "strings": len(resources["strings"]),
            "json": len(resources["json"]),
            "spm": len(spm_rows),
            "imports": len(imports),
            "no_port": len(unique_no_port),
            "gaps": len(gaps),
        },
    }


def _swift_string(value: str) -> str:
    return json.dumps(value, ensure_ascii=False)


def emit_package_swift(
    manifest: dict[str, Any],
    *,
    openuikit: Path,
    target_name: str,
    library: bool = False,
) -> str:
    rel = os.fspath(openuikit)
    products = [
        '                .product(name: "OpenUIKit", package: "OpenUIKit")',
        '                .product(name: "UIKit", package: "OpenUIKit")',
        '                .product(name: "SwiftUI", package: "OpenUIKit")',
        '                .product(name: "DeveloperToolsSupport", package: "OpenUIKit")',
        '                .product(name: "Symbols", package: "OpenUIKit")',
        '                .product(name: "Combine", package: "OpenUIKit", condition: .when(platforms: [.linux]))',
        '                .product(name: "os", package: "OpenUIKit", condition: .when(platforms: [.linux]))',
        '                .product(name: "Glean", package: "OpenUIKit", condition: .when(platforms: [.linux]))',
        '                .product(name: "Intents", package: "OpenUIKit", condition: .when(platforms: [.linux]))',
        '                .product(name: "IntentsUI", package: "OpenUIKit", condition: .when(platforms: [.linux]))',
        '                .product(name: "Onboarding", package: "OpenUIKit", condition: .when(platforms: [.linux]))',
        '                .product(name: "Licenses", package: "OpenUIKit", condition: .when(platforms: [.linux]))',
        '                .product(name: "DesignSystem", package: "OpenUIKit", condition: .when(platforms: [.linux]))',
        '                .product(name: "SnapKit", package: "OpenUIKit", condition: .when(platforms: [.linux]))',
        '                .product(name: "Sentry", package: "OpenUIKit", condition: .when(platforms: [.linux]))',
        '                .product(name: "Fuzi", package: "OpenUIKit", condition: .when(platforms: [.linux]))',
        '                .product(name: "WebKit", package: "OpenUIKit")',
        '                .product(name: "FocusAppServices", package: "OpenUIKit")',
        '                .product(name: "UIHelpers", package: "OpenUIKit")',
        '                .product(name: "UIComponents", package: "OpenUIKit")',
        '                .product(name: "AppShortcuts", package: "OpenUIKit")',
        '                .product(name: "LocalAuthentication", package: "OpenUIKit", condition: .when(platforms: [.linux]))',
        '                .product(name: "PassKit", package: "OpenUIKit", condition: .when(platforms: [.linux]))',
        '                .product(name: "Network", package: "OpenUIKit", condition: .when(platforms: [.linux]))',
        '                .product(name: "SafariServices", package: "OpenUIKit", condition: .when(platforms: [.linux]))',
    ]
    # libkern / StoreKit are emitted through PLATFORM_NAMED_PRODUCTS below
    # (eidolon-launch and simplenote-launch3 both measured that SwiftPM
    # resolves a product name before evaluating its platform condition).
    demanded = {r["name"] for r in manifest["spm"] + manifest["imports"]}
    for name in sorted(DARWIN_SOURCE_PRODUCTS & demanded):
        products.append(
            f'                .product(name: "{name}", package: "OpenUIKit", '
            'condition: .when(platforms: [.macOS]))'
        )
    resources_block = ""
    if any(manifest["resources"].values()):
        resources_block = ',\n            resources: [\n                .copy("Resources"),\n            ]'
    product_deps = ",\n".join(products)
    # Pocket Casts ships podcasts/main.swift; SwiftPM 5.4+ then classifies the
    # target as executable and refuses a .library product (measured Linux
    # swift:6.2-noble: "library product 'podcasts' should not contain
    # executable targets"). Application targets are always emitted as
    # executableTarget so @main / main.swift apps load the manifest.
    executable = not library and manifest.get("target", {}).get("product_type") == APP_PRODUCT_TYPE
    product_decl = (
        f".executable(name: {_swift_string(target_name)}, targets: [{_swift_string(target_name)}])"
        if executable
        else f".library(name: {_swift_string(target_name)}, targets: [{_swift_string(target_name)}])"
    )
    target_kind = "executableTarget" if executable else "target"
    mixed = bool(manifest.get("objc_sources") or manifest.get("c_sources"))
    clang_name = f"{target_name}ObjC"
    main_name = f"{target_name}Main"
    has_main = mixed and any(
        posixpath.basename(p) == "main.m" for p in manifest.get("objc_sources", [])
    )
    swift_flags = [
        '"-default-isolation", "MainActor"',
        '"-disable-availability-checking"',
    ]
    clang_target = ""
    target_deps = product_deps
    extra_products = ""
    if mixed:
        # Route (b) staged order (Xcode's): the Swift target compiles first
        # against the app's ObjC headers through the bridging header, emits
        # `<App>-Swift.h`, then the Clang target (which depends on it) compiles
        # the .m files. The Swift target must NOT depend on the Clang target;
        # its references to ObjC classes resolve at the final link.
        header_dirs = sorted({posixpath.dirname(h) for h in manifest.get("header_sources", [])})
        xcc: list[str] = []
        for directory in GENERATED_HEADER_DIRS:
            xcc += ["-Xcc", f"-I{directory}"]
        for directory in header_dirs:
            xcc += ["-Xcc", f"-ISources/{clang_name}/include/{directory}" if directory else f"-ISources/{clang_name}/include"]
        xcc += ["-Xcc", f"-ISources/{clang_name}/include"]
        for name in SWIFT_SIDE_NS_RENAMES:
            xcc += ["-Xcc", f"-D{name}=OUK_{name}"]
        bridging = manifest.get("bridging_header")
        if bridging:
            swift_flags.append(f'"-import-objc-header", "Sources/{clang_name}/include/{bridging}"')
        swift_flags.extend(
            f'"{xcc[i]}", "{xcc[i + 1]}"' for i in range(0, len(xcc), 2)
        )
        # The bridging header reaches <UIKit/UIKit.h>, which imports the
        # support header; depending on the product gives the Swift target its
        # include path and module map (MEASURED: 'UIKitObjCSupport.h' file not
        # found in the bridging-header PCH without it).
        target_deps = product_deps + (
            f',\n                .product(name: "{OBJC_SUPPORT_PRODUCT}", package: "OpenUIKit", '
            'condition: .when(platforms: [.macOS]))'
        )
        objc_products = [
            f'                .product(name: "{OBJC_SUPPORT_PRODUCT}", package: "OpenUIKit", condition: .when(platforms: [.macOS]))',
            f'                .product(name: "{OBJC_BRIDGE_PRODUCT}", package: "OpenUIKit", condition: .when(platforms: [.macOS]))',
        ]
        # AutomatticTracks' ObjC surface is its own Clang target (pass 2);
        # the app demands the Swift product name.
        demanded_objc = set(demanded)
        if "AutomatticTracks" in demanded:
            demanded_objc.add("AutomatticTracksModelObjC")
        for name in sorted(OBJC_DARWIN_PRODUCTS & demanded_objc):
            objc_products.append(
                f'                .product(name: "{name}", package: "OpenUIKit", condition: .when(platforms: [.macOS]))'
            )
        search_paths = [
            f'                .headerSearchPath("include/{d}")' if d else '                .headerSearchPath("include")'
            for d in header_dirs
        ]
        search_paths += [
            f'                .headerSearchPath("{d}")'
            for d in sorted({posixpath.dirname(p) for p in manifest.get("objc_sources", []) + manifest.get("c_sources", [])})
            if d
        ]
        search_paths.append('                .headerSearchPath("include/UIKit")')
        # UIKitObjCSupport.h carries an AppKit-colliding C struct for the
        # Objective-C side only (see the header).
        search_paths.append('                .define("OPENUIKIT_OBJC_SIDE", to: "1")')
        objc_product_lines = ",\n".join(objc_products)
        search_lines = ",\n".join(search_paths)
        clang_target = f'''        .target(
            name: {_swift_string(clang_name)},
            dependencies: [
                {_swift_string(target_name)},
                .product(name: "OpenUIKit", package: "OpenUIKit"),
{objc_product_lines},
            ],
            path: "Sources/{clang_name}",
            publicHeadersPath: "include",
            cSettings: [
{search_lines},
            ]
        ),
'''
        if has_main:
            clang_target += f'''        .executableTarget(
            name: {_swift_string(main_name)},
            dependencies: [{_swift_string(clang_name)}, {_swift_string(target_name)}],
            path: "Sources/{main_name}",
            cSettings: [
                .headerSearchPath("../{clang_name}/include"),
{search_lines.replace('.headerSearchPath("include', '.headerSearchPath("../' + clang_name + '/include')},
            ]
        ),
'''
            extra_products = f',\n        .executable(name: {_swift_string(main_name)}, targets: [{_swift_string(main_name)}])'
        # A mixed app's product is the library pair; main.m is its own executable.
        product_decl = (
            f'.library(name: {_swift_string(target_name)}, targets: [{_swift_string(target_name)}, {_swift_string(clang_name)}])'
        )
        target_kind = "target"
    swift_flag_lines = ",\n".join(f"                    {flag}" for flag in swift_flags)
    linux_named = ",\n".join(
        f'    .product(name: "{linux}", package: "OpenUIKit")' for linux, _ in PLATFORM_NAMED_PRODUCTS
    )
    darwin_named = ",\n".join(
        f'    .product(name: "{darwin}", package: "OpenUIKit")' for _, darwin in PLATFORM_NAMED_PRODUCTS
    )
    darwin_aliases = ", ".join(
        f'"-module-alias", "{linux}={darwin}"' for linux, darwin in PLATFORM_NAMED_PRODUCTS
    )
    # Swift 4.0 is a source rule at Eidolon's pin: the same native UIKit
    # UIApplicationLaunchOptionsKey probe fails in Swift 5 and passes in 4.
    language = manifest.get("swift_language_version")
    language = {"4.0": "4", "5.0": "5", "6.0": "6"}.get(language, language)
    language_setting = (f',\n    swiftLanguageVersions: [.version({_swift_string(language)})]'
                        if language in {"4", "4.2", "5", "6"} else "")
    return f"""// swift-tools-version:5.9
// Generated by Tools/ingest/xcodeproj_to_package.py — do not edit by hand.
// Source project: {manifest["project"]}
// Target: {manifest["target"]["name"]}
import PackageDescription

// OpenUIKit names these modules per platform (its Package.swift:155); a
// product name is validated even under a platform condition.
#if os(Linux)
let platformNamedProducts: [Target.Dependency] = [
{linux_named},
]
let platformModuleAliases: [String] = []
#else
let platformNamedProducts: [Target.Dependency] = [
{darwin_named},
]
let platformModuleAliases: [String] = [{darwin_aliases}]
#endif

let package = Package(
    name: {_swift_string(target_name)},
    platforms: [.macOS(.v11)],
    products: [
        {product_decl}{extra_products},
    ],
    dependencies: [
        .package(name: "OpenUIKit", path: {_swift_string(rel)}),
    ],
    targets: [
{clang_target}        .{target_kind}(
            name: {_swift_string(target_name)},
            dependencies: [
{target_deps},
            ] + platformNamedProducts{resources_block},
            swiftSettings: [
                .unsafeFlags([
{swift_flag_lines},
                ] + platformModuleAliases),
            ]
        ),
    ]{language_setting}
)
"""


def _copy_file(src: Path, dst: Path) -> None:
    dst.parent.mkdir(parents=True, exist_ok=True)
    if src.is_dir():
        if dst.exists():
            shutil.rmtree(dst)
        shutil.copytree(src, dst, symlinks=False, ignore=shutil.ignore_patterns(".git", "xcuserdata"))
        return
    shutil.copy2(src, dst)


def _copy_swift_source_with_libkern(src: Path, dst: Path) -> None:
    """Copy a Swift file, adding Linux-resolvable imports the corpus omits.

    MEASURED mozilla-mobile/focus-ios a2832521
    Blockzilla/Lib/Deferred/Deferred.swift sibling ReadWriteLock.swift:
    `import Foundation` only, then OSAtomicCompareAndSwap32Barrier and
    OSSpinLockLock/Unlock. Darwin Foundation re-exports libkern; Linux
    corelibs does not. The corpus is never patched — only the generated
    ingest copy gets the import (focus-deps).

    `import os.log` is rewritten to `import os`: SwiftPM cannot ship a
    module named os.log (focus-e2e), and clang submodules on the os
    target still failed `import os.log` (MEASURED swift:6.2-noble
    OSTests.swift:5). The os product already exports OSLog / os_log.
    """
    dst.parent.mkdir(parents=True, exist_ok=True)
    text = src.read_text(encoding="utf-8")
    needs_libkern = (
        "OSAtomicCompareAndSwap" in text or "OSSpinLock" in text
    ) and "import libkern" not in text
    if needs_libkern:
        text = "import libkern\n" + text
    # SwiftPM cannot ship a module literally named os.log (focus-e2e:
    # target "os.log" compiles as os_log). The os product already exports
    # OSLog / os_log. Generated copies rewrite the import so NimbusWrapper
    # does not need a generated-package exclude. MEASURED OSTests
    # `import os.log` still fails with clang submodules on the os target
    # (swift:6.2-noble).
    text = re.sub(r"^import os\.log\b", "import os", text, flags=re.MULTILINE)
    text = re.sub(r"^import os\.signpost\b", "import os", text, flags=re.MULTILINE)
    dst.write_text(text, encoding="utf-8")


def emit_tree(
    graph: ProjectGraph,
    manifest: dict[str, Any],
    out_dir: Path,
    openuikit: Path,
    *,
    module_name: str | None = None,
    library: bool = False,
) -> None:
    out_dir.mkdir(parents=True, exist_ok=True)
    target_name = re.sub(r"[^A-Za-z0-9_]", "_", module_name or manifest["target"]["name"])
    if not target_name or target_name[0].isdigit():
        target_name = "App_" + target_name
    src_root = out_dir / "Sources" / target_name
    objc_root = out_dir / "Sources" / f"{target_name}ObjC"
    res_root = src_root / "Resources"
    if src_root.exists():
        shutil.rmtree(src_root)
    if objc_root.exists():
        shutil.rmtree(objc_root)
    src_root.mkdir(parents=True)

    # Swift sources keep their repo-relative path so #filePath stays meaningful.
    # Focus Deferred/ReadWriteLock.swift names OSAtomic* / OSSpinLock* with
    # only `import Foundation` (Darwin re-exports libkern). Generated copies
    # get `import libkern` so the Linux product resolves; corpus is unpatched.
    for rel in manifest["swift_sources"]:
        src = graph.source_root / rel
        if not src.is_file():
            continue
        dest = src_root / rel
        if src.suffix == ".swift":
            _copy_swift_source_with_libkern(src, dest)
        else:
            _copy_file(src, dest)
    # A generated source that is absent but has a public `-demo` sibling is
    # emitted from the demo under the expected path (Simplenote SPCredentials).
    for row in manifest.get("demo_substitutes", []):
        _copy_swift_source_with_libkern(graph.source_root / row["demo"], src_root / row["missing"])

    main_root = out_dir / "Sources" / f"{target_name}Main"
    if main_root.exists():
        shutil.rmtree(main_root)
    if manifest.get("objc_sources") or manifest.get("c_sources"):
        include_root = objc_root / "include"
        include_root.mkdir(parents=True, exist_ok=True)
        for rel in manifest.get("objc_sources", []) + manifest.get("c_sources", []):
            src = graph.source_root / rel
            if not src.is_file():
                continue
            if posixpath.basename(rel) == "main.m":
                # UIApplicationMain lives in its own executable target so the
                # library pair can be linked by a harness (Focus recipe).
                _copy_file(src, main_root / "main.m")
            else:
                _copy_file(src, objc_root / rel)
        for rel in manifest.get("header_sources", []):
            src = graph.source_root / rel
            if src.is_file():
                _copy_file(src, include_root / rel)
        guard = re.sub(r"[^A-Za-z0-9]", "_", target_name).upper() + "_UMBRELLA_H"
        lines = ["/* Generated umbrella. */", f"#ifndef {guard}", f"#define {guard}"]
        lines.extend(f'#include "{path}"' for path in manifest.get("header_sources", []))
        lines.append("#endif")
        (include_root / f"{target_name}Umbrella.h").write_text(
            "\n".join(lines) + "\n", encoding="utf-8"
        )
        # `<UIKit/UIKit.h>` on route (b): OpenUIKit's compiler-generated header
        # (SwiftPM hands the Clang target `-I .build/.../OpenUIKit.build/include`
        # because it depends on OpenUIKit) plus the hand declarations. The
        # app's own `<App>-Swift.h` is generated by SwiftPM the same way when
        # the Swift target builds; no placeholder is written.
        (include_root / "UIKit").mkdir(parents=True, exist_ok=True)
        (include_root / "UIKit" / "UIKit.h").write_text(
            "/* Generated route-(b) UIKit umbrella (Tools/ingest/xcodeproj_to_package.py).\n"
            " * OpenUIKit-Swift.h is emitted by SwiftPM for the OpenUIKit target; the\n"
            " * support header carries the enums/structs/protocols it cannot. */\n"
            "#ifndef OPENUIKIT_ROUTE_B_UIKIT_H\n"
            "#define OPENUIKIT_ROUTE_B_UIKIT_H\n"
            "#import <Foundation/Foundation.h>\n"
            '#import "OpenUIKit-Swift.h"\n'
            '#import "UIKitObjCSupport.h"\n'
            "#if !__swift__\n"
            '#import "OpenUIKitObjCBridge-Swift.h"\n'
            "#endif\n"
            "#endif\n",
            encoding="utf-8",
        )

    mapping_notes = {
        "xcassets": "OpenUIKit named-color/image reader (docs/NAMED_ASSETS.md): "
        "raw Colors.xcassets / Assets.xcassets / Media.xcassets at the resource "
        "root, or an openuikit-xcassets-index",
        "nibs": "OpenUIKit UINib reads compiled NIBArchive (fixtures/realapp/nibs); "
        "source .xib/.storyboard is copied here. ibtool --compile is macOS-only",
        "strings": "Bundle localization: .strings / .lproj laid out as a resource bundle",
        "json": "bundled JSON next to the module, same as fixtures/realapp/*.json",
    }
    resource_map: dict[str, list[dict[str, str]]] = {k: [] for k in mapping_notes}

    def place_resource(rel: str, bucket: str) -> None:
        src = graph.source_root / rel
        if not src.exists():
            return
        dest_name = posixpath.basename(rel.rstrip("/"))
        if bucket == "xcassets":
            dest = res_root / dest_name
        elif bucket == "nibs":
            dest = res_root / "nibs" / dest_name
        elif bucket == "strings":
            dest = res_root / "Localization" / rel
        else:
            dest = res_root / "json" / dest_name
        _copy_file(src, dest)
        resource_map[bucket].append(
            {
                "from": rel,
                "to": str(dest.relative_to(src_root)),
                "loader": mapping_notes[bucket],
            }
        )

    for bucket, paths in manifest["resources"].items():
        for rel in paths:
            place_resource(rel, bucket)

    info_path = src_root / "Resources" / "ingest-info.json"
    info_path.parent.mkdir(parents=True, exist_ok=True)
    info_path.write_text(
        json.dumps(
            {
                "bundle_identifier": manifest["info"].get("bundle_identifier"),
                "display_name": manifest["info"].get("display_name"),
                "product_name": manifest["info"].get("product_name"),
                "keys": manifest["info"].get("keys"),
            },
            indent=2,
            sort_keys=True,
        )
        + "\n",
        encoding="utf-8",
    )

    # Package.swift path to OpenUIKit is relative to the generated package.
    rel_openuikit = os.path.relpath(openuikit.resolve(), start=out_dir.resolve())
    package_text = emit_package_swift(
        manifest, openuikit=Path(rel_openuikit), target_name=target_name, library=library
    )
    (out_dir / "Package.swift").write_text(package_text, encoding="utf-8")

    manifest_out = dict(manifest)
    manifest_out["generated"] = {
        "package_swift": "Package.swift",
        "target_name": target_name,
        "library": library,
        "openuikit": rel_openuikit,
        "resource_map": resource_map,
        "ingest_info": "Sources/" + target_name + "/Resources/ingest-info.json",
    }

    vendor = out_dir / "LocalPackages"
    copied_local: list[dict[str, str]] = []
    seen_local: set[str] = set()
    for row in manifest["spm"]:
        if row.get("origin") != "local":
            continue
        rel = row.get("relative_path") or ""
        if not rel or rel in seen_local:
            continue
        src = graph.source_root / rel
        if not src.is_dir():
            continue
        seen_local.add(rel)
        dest = vendor / posixpath.basename(rel)
        _copy_file(src, dest)
        copied_local.append(
            {
                "from": rel,
                "to": str(dest.relative_to(out_dir)),
                "package_name": row.get("package_name") or posixpath.basename(rel),
                "tools_version": row.get("tools_version") or "",
            }
        )
    manifest_out["generated"]["local_packages"] = copied_local
    (out_dir / "source-manifest.json").write_text(
        json.dumps(manifest_out, indent=2, ensure_ascii=False) + "\n",
        encoding="utf-8",
    )


def format_gap_report(manifest: dict[str, Any]) -> str:
    lines = []
    target = manifest["target"]["name"]
    lines.append(f"target {target!r}  swift={manifest['counts']['swift_sources']}  "
                 f"present_swift={manifest['counts']['present_swift_sources']}  "
                 f"gaps={manifest['counts']['gaps']}  no_port={manifest['counts']['no_port']}")
    for path in manifest["missing_swift_sources"]:
        lines.append(f"MISSING SWIFT SOURCE: {path}")
    if manifest["gaps"]:
        lines.append("GAPS (no port — ingest stops):")
        for gap in manifest["gaps"]:
            lines.append(f"  - {gap['kind']}: {gap['detail']}")
    if manifest["no_port"]:
        lines.append("NO PORT (imports / SPM / frameworks the generated package cannot link):")
        for item in manifest["no_port"]:
            lines.append(
                f"  - {item['name']}  [{item['kind']}, {item['class']}]  {item['reason']}"
            )
    if not manifest["gaps"] and not manifest["no_port"]:
        lines.append("no CocoaPods/Carthage/ObjC/mixed-target gaps; every named import has a port or is in-tree")
    return "\n".join(lines)


def find_xcodeproj(path: Path) -> Path:
    if path.suffix == ".xcodeproj" and path.is_dir():
        return path
    if path.is_file() and path.name == "project.pbxproj":
        return path.parent
    if path.is_dir():
        found = sorted(path.glob("*.xcodeproj")) + sorted(path.glob("*/*.xcodeproj"))
        # Prefer an application project over a workspace-only nested one.
        apps = [p for p in found if (p / "project.pbxproj").is_file()]
        if len(apps) == 1:
            return apps[0]
        if apps:
            # focus-ios: Blockzilla.xcodeproj inside focus-ios/
            named = [p for p in apps if p.stem.lower() in {path.name.lower(), "blockzilla", "hackers", "podcasts"}]
            return named[0] if named else apps[0]
    raise IngestError(f"cannot find an .xcodeproj under {path}")


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("project", type=Path, help=".xcodeproj, project.pbxproj, or an app checkout")
    parser.add_argument("--target", help="PBX native target name (default: the application target)")
    parser.add_argument("--library", action="store_true", help="emit a library for a separate launch harness; preserves upstream entry-point source")
    parser.add_argument("--module-name", help="generated module identity (PBX target selection is unchanged)")
    parser.add_argument("--configuration", help="XCBuildConfiguration name (default: FocusDebug/Debug/list default)")
    parser.add_argument("--out", type=Path, help="write Package.swift + sources + source-manifest.json here")
    parser.add_argument(
        "--openuikit",
        type=Path,
        default=UIKIT_ROOT,
        help="path to the OpenUIKit package (default: this uikit/ checkout)",
    )
    parser.add_argument(
        "--allow-gaps",
        action="store_true",
        help="still emit Package.swift when CocoaPods/Carthage/ObjC/mixed gaps exist",
    )
    parser.add_argument("--json", action="store_true", help="print the manifest JSON on stdout")
    args = parser.parse_args(argv)

    try:
        bundle = find_xcodeproj(args.project)
        graph = ProjectGraph(bundle)
        target_id, target = graph.pick_app_target(args.target)
        manifest = build_manifest(
            graph, target_id, target, preferred_configuration=args.configuration
        )
    except (OpenStepError, IngestError) as exc:
        print(f"xcodeproj_to_package: {exc}", file=sys.stderr)
        return 1

    report = format_gap_report(manifest)
    if args.json:
        print(json.dumps(manifest, indent=2, ensure_ascii=False))
        print(report, file=sys.stderr)
    else:
        print(report)

    hard_gaps = bool(manifest["gaps"])
    if args.out is not None:
        if hard_gaps and not args.allow_gaps:
            print(
                "xcodeproj_to_package: not emitting a package; pass --allow-gaps "
                "to write sources anyway",
                file=sys.stderr,
            )
            return 2
        emit_tree(graph, manifest, args.out, args.openuikit.resolve(),
                  module_name=args.module_name, library=args.library)
        print(f"wrote {args.out / 'Package.swift'}", file=sys.stderr)
        print(f"wrote {args.out / 'source-manifest.json'}", file=sys.stderr)

    if hard_gaps and not args.allow_gaps:
        return 2
    return 0


if __name__ == "__main__":
    sys.exit(main())
