#!/usr/bin/env python3
"""Emit the fail-closed SwiftUI source contract for pinned Focus.

This is intentionally a *source* inventory, not a claim that SwiftUI exists on
Linux.  It accepts one reviewed Focus revision and one reviewed Xcode-plan
artifact, verifies every inspected source against its pinned Git blob, then
records a reviewed lexical compatibility surface and the external declarations
which an unmodified-source module named ``SwiftUI`` must make visible.

The scanner is deliberately small and auditable.  It tokenizes comments and
string literals away and recognizes only a reviewed vocabulary. Token
locations are exact, but spelling alone is never called compiler-resolved
SwiftUI ownership. Source hashes and an exact expected importer set make the
source boundary fail closed: a new file requires review rather than being
silently classified.
"""

from __future__ import annotations

import argparse
from collections import Counter, defaultdict
import hashlib
import json
import os
from pathlib import Path, PurePosixPath
import re
import stat
import subprocess
import sys
from typing import Any, Iterable


FOCUS_COMMIT = "a2832521c1daa0c23419c73705ae043ed60c9791"
SCHEMA = 2
FOCUS_GIT_PREFIX = "focus-ios/"
XCODE_PLAN_SHA256 = "7d7fa64265cf926de3caf37c3227ff57649492713a8360abe2e6f968183f0568"
PACKAGE_MANIFEST_SHA256 = "2d29b769de137389f5613de6755211b255533375bf6003a2192f514e96899248"
PBX_PROJECT_SHA256 = "5a9c088023d20de3e41e6283ab4bde12338ae54da3f2a57b1e6743434b74e4ac"
SYSTEM_GIT = "/usr/bin/git"
GIT_ENVIRONMENT = {
    "GIT_CONFIG_GLOBAL": os.devnull,
    "GIT_CONFIG_NOSYSTEM": "1",
    "GIT_NO_REPLACE_OBJECTS": "1",
    "GIT_OPTIONAL_LOCKS": "0",
    "LANG": "C",
    "LC_ALL": "C",
    "PATH": "/usr/bin:/bin",
}

# These are the local products in the main app link closure.  Widget is a
# transitive dependency of Onboarding.  The target directories have implicit
# SwiftPM source membership at this pinned manifest (no exclude/sources list).
PACKAGE_TARGETS = (
    "AppShortcuts",
    "DesignSystem",
    "Licenses",
    "Onboarding",
    "UIHelpers",
    "Widget",
)
WIDGET_EXTENSION_SOURCES = (
    "Shared/AppConfig.swift",
    "Shared/AppInfo.swift",
    "Widgets/Widgets.swift",
)


class ContractError(RuntimeError):
    """The requested source boundary differs from the reviewed contract."""


# path -> (scope, target, semantic role, in main app link closure)
EXPECTED_IMPORTERS: dict[str, tuple[str, str, str, bool]] = {
    "Blockzilla/BrowserViewController.swift":
        ("main_application", "Blockzilla", "hosting_call_site", True),
    "Blockzilla/InternalSettings/InternalCrashReportingSettingsView.swift":
        ("main_application", "Blockzilla", "runtime_view", True),
    "Blockzilla/InternalSettings/InternalExperimentDetailView.swift":
        ("main_application", "Blockzilla", "runtime_view", True),
    "Blockzilla/InternalSettings/InternalExperimentsSettingsView.swift":
        ("main_application", "Blockzilla", "runtime_view", True),
    "Blockzilla/InternalSettings/InternalOnboardingSettingsView.swift":
        ("main_application", "Blockzilla", "runtime_view", True),
    "Blockzilla/InternalSettings/InternalSettingsView.swift":
        ("main_application", "Blockzilla", "runtime_view", True),
    "Blockzilla/InternalSettings/InternalTelemetrySettingsView.swift":
        ("main_application", "Blockzilla", "runtime_view", True),
    "Blockzilla/Onboarding/OnboardingFactory.swift":
        ("main_application", "Blockzilla", "hosting_call_site", True),
    "Blockzilla/Settings/Controller/SettingsViewController.swift":
        ("main_application", "Blockzilla", "hosting_call_site", True),

    "BlockzillaPackage/Sources/DesignSystem/Preview Files/AppColorsView.swift":
        ("local_package", "DesignSystem", "preview_only", True),
    "BlockzillaPackage/Sources/DesignSystem/Preview Files/AppFontsView.swift":
        ("local_package", "DesignSystem", "preview_only", True),
    "BlockzillaPackage/Sources/DesignSystem/Preview Files/AppImagesView.swift":
        ("local_package", "DesignSystem", "preview_only", True),
    "BlockzillaPackage/Sources/DesignSystem/UIColor+AppColors.swift":
        ("local_package", "DesignSystem", "runtime_support", True),
    "BlockzillaPackage/Sources/Licenses/LicenseListView.swift":
        ("local_package", "Licenses", "runtime_view", True),
    "BlockzillaPackage/Sources/Onboarding/DesignSystem/Color+AppColors.swift":
        ("local_package", "Onboarding", "runtime_support", True),
    "BlockzillaPackage/Sources/Onboarding/DesignSystem/Font+AppFonts.swift":
        ("local_package", "Onboarding", "runtime_support", True),
    "BlockzillaPackage/Sources/Onboarding/DesignSystem/Image+AppImages.swift":
        ("local_package", "Onboarding", "runtime_support", True),
    "BlockzillaPackage/Sources/Onboarding/PortraitHostingController.swift":
        ("local_package", "Onboarding", "hosting_bridge", True),
    "BlockzillaPackage/Sources/Onboarding/Preview Files/OnboardingPreview.swift":
        ("local_package", "Onboarding", "preview_only", True),
    "BlockzillaPackage/Sources/Onboarding/SwiftUI Onboarding/CardBannerView.swift":
        ("local_package", "Onboarding", "runtime_view", True),
    "BlockzillaPackage/Sources/Onboarding/SwiftUI Onboarding/DefaultBrowserOnboardingView.swift":
        ("local_package", "Onboarding", "runtime_view", True),
    "BlockzillaPackage/Sources/Onboarding/SwiftUI Onboarding/GetStartedOnboardingView.swift":
        ("local_package", "Onboarding", "runtime_view", True),
    "BlockzillaPackage/Sources/Onboarding/SwiftUI Onboarding/OnboardingView.swift":
        ("local_package", "Onboarding", "runtime_view", True),
    "BlockzillaPackage/Sources/Onboarding/SwiftUI Onboarding/OnboardingViewModel.swift":
        ("local_package", "Onboarding", "runtime_support", True),
    "BlockzillaPackage/Sources/Onboarding/SwiftUI Onboarding/ShowMeHowOnboardingView.swift":
        ("local_package", "Onboarding", "runtime_view", True),
    "BlockzillaPackage/Sources/Widget/Assets.swift":
        ("local_package", "Widget", "runtime_support", True),
    "BlockzillaPackage/Sources/Widget/SearchWidgetView.swift":
        ("local_package", "Widget", "runtime_view", True),

    "Widgets/Widgets.swift":
        ("widget_extension", "WidgetsExtension", "extension_entry_point", False),
}


# Reviewed SwiftUI-shaped identifiers.  Their occurrences are conservative
# lexical candidates: an identifier can collide with an app/UIKit name, so the
# inventory never treats an unqualified token as compiler-resolved ownership.
# The exact source/importer/hash boundary remains fail closed.
SWIFTUI_TYPES = frozenset({
    "Button",
    "Color",
    "EdgeInsets",
    "Font",
    "ForEach",
    "Form",
    "Gradient",
    "HStack",
    "Image",
    "LinearGradient",
    "List",
    "NavigationLink",
    "NavigationView",
    "ObservableObject",
    "Picker",
    "PreviewProvider",
    "RoundedRectangle",
    "ScrollView",
    "Section",
    "Spacer",
    "TabView",
    "TapGesture",
    "Text",
    "TextField",
    "Toggle",
    "UIHostingController",
    "UIViewControllerRepresentable",
    "VStack",
    "View",
    "ZStack",
})

PROPERTY_WRAPPERS = frozenset({"ObservedObject", "Published", "State"})
GLOBAL_FUNCTIONS = frozenset({"withAnimation"})

# Only calls with these member spellings are retained as modifier candidates.
# This narrows noise but does not prove the receiver is a SwiftUI View.
VIEW_MODIFIERS = frozenset({
    "aspectRatio",
    "background",
    "bold",
    "clipShape",
    "colorScheme",
    "cornerRadius",
    "disabled",
    "edgesIgnoringSafeArea",
    "font",
    "fontWeight",
    "foregroundColor",
    "frame",
    "ignoresSafeArea",
    "minimumScaleFactor",
    "multilineTextAlignment",
    "navigationBarBackButtonHidden",
    "navigationBarHidden",
    "navigationBarTitle",
    "navigationBarTitleDisplayMode",
    "navigationTitle",
    "onAppear",
    "onChange",
    "onReceive",
    "onTapGesture",
    "opacity",
    "overlay",
    "padding",
    "previewContext",
    "previewLayout",
    "resizable",
    "scaledToFill",
    "scaledToFit",
    "shadow",
    "simultaneousGesture",
    "stroke",
    "tabViewStyle",
    "tag",
    "toolbar",
})

# Leading-dot cases/factories commonly inferred by SwiftUI generic context.
# Large hosting files also contain UIKit members with these spellings, so every
# occurrence is explicitly reported as a lexical candidate, not attribution.
INFERRED_MEMBERS = frozenset({
    "all",
    "always",
    "black",
    "bold",
    "bottom",
    "bottomTrailing",
    "caption",
    "center",
    "fit",
    "gray",
    "headline",
    "horizontal",
    "infinity",
    "inline",
    "leading",
    "light",
    "medium",
    "page",
    "sizeThatFits",
    "system",
    "title3",
    "top",
    "topLeading",
    "trailing",
    "vertical",
    "white",
})

# These are supplied by another first-party module but participate directly in
# SwiftUI generic extension lookup.  Keeping them separate prevents the SwiftUI
# port from accidentally claiming WidgetKit coverage.
ADJACENT_FRAMEWORK_APIS = {
    "WidgetKit": frozenset({
        "StaticConfiguration",
        "Timeline",
        "TimelineEntry",
        "TimelineProvider",
        "Widget",
        "WidgetConfiguration",
        "WidgetPreviewContext",
    }),
}

# Public names which the exact importers use without directly importing the
# provider module.  These are the compatibility module's visible/re-export
# requirements, not a claim that SwiftUI owns the declarations.  UIKit is an
# accepted direct visibility route for its Foundation/CoreGraphics/CoreText
# dependencies, matching the pinned files which already import UIKit.
VISIBLE_MODULE_API_VOCABULARY: dict[str, frozenset[str]] = {
    "Combine": frozenset({"ObservableObject", "Published"}),
    "CoreGraphics": frozenset({"CGFloat"}),
    "CoreText": frozenset({"CTFont"}),
    "Foundation": frozenset({
        "Bundle",
        "Date",
        "NSError",
        "NSException",
        "NSLocalizedString",
        "URL",
        "UserDefaults",
    }),
    "UIKit": frozenset({
        "UIApplication",
        "UIInterfaceOrientationMask",
        "UIImage",
        "UIPasteboard",
        "UIPageControl",
        "UIColor",
        "UIFont",
        "UIViewController",
    }),
}

DIRECT_VISIBILITY_IMPORTS: dict[str, frozenset[str]] = {
    "Combine": frozenset({"Combine"}),
    "CoreGraphics": frozenset({"CoreGraphics", "UIKit"}),
    "CoreText": frozenset({"CoreText", "UIKit"}),
    "Foundation": frozenset({"Foundation", "UIKit"}),
    "UIKit": frozenset({"UIKit"}),
}

# Source-level additions declared by Focus, not SwiftUI requirements.  They are
# recorded because their bodies constrain the underlying framework APIs.
FOCUS_SWIFTUI_EXTENSIONS: dict[str, dict[str, list[str]]] = {
    "BlockzillaPackage/Sources/DesignSystem/Preview Files/AppFontsView.swift": {
        "Font": ["init(uiFont:)"]
    },
    "BlockzillaPackage/Sources/DesignSystem/UIColor+AppColors.swift": {
        "Color": ["accent"]
    },
    "BlockzillaPackage/Sources/Onboarding/DesignSystem/Color+AppColors.swift": {
        "Color": [
            "actionButton", "secondOnboardingScreenBackground",
            "secondOnboardingScreenBottomButton", "secondOnboardingScreenText",
            "systemBackground",
        ]
    },
    "BlockzillaPackage/Sources/Onboarding/DesignSystem/Font+AppFonts.swift": {
        "Font": ["body16", "body16Bold", "title20", "title28Bold"]
    },
    "BlockzillaPackage/Sources/Onboarding/DesignSystem/Image+AppImages.swift": {
        "Image": [
            "background", "close", "huggingFocus", "jiggleModeImage", "logo",
            "stepOneImage", "stepThreeImage", "stepTwoImage",
        ]
    },
    "BlockzillaPackage/Sources/Widget/Assets.swift": {
        "Gradient": ["quickAccessWidget"],
        "Image": ["logo", "magnifyingGlass"],
    },
    "Widgets/Widgets.swift": {
        "Gradient": ["quickAccessWidget"],
        "View": ["widgetBackground(backgroundView:)"]
    },
}

IMPORT_SWIFTUI_RE = re.compile(r"^\s*import\s+SwiftUI\s*$", re.MULTILINE)
SELECTIVE_IMPORT_KINDS = frozenset(
    {"class", "enum", "func", "let", "protocol", "struct", "typealias", "var"}
)


def sha256_bytes(data: bytes) -> str:
    return hashlib.sha256(data).hexdigest()


def _run_git(repo: Path, *arguments: str) -> bytes:
    command = [
        SYSTEM_GIT,
        "--no-replace-objects",
        "-c", "core.fsmonitor=false",
        "-c", "core.hooksPath=/dev/null",
        "-c", "user.useConfigOnly=true",
        "-c", "protocol.file.allow=never",
        "-C", str(repo),
        *arguments,
    ]
    try:
        return subprocess.check_output(
            command, stderr=subprocess.STDOUT, env=GIT_ENVIRONMENT,
        )
    except (OSError, subprocess.CalledProcessError) as exc:
        detail = getattr(exc, "output", b"")
        if isinstance(detail, bytes):
            detail = detail.decode("utf-8", errors="replace").strip()
        raise ContractError(f"git {' '.join(arguments)} failed: {detail}") from exc


def _read_regular(path: Path, label: str) -> bytes:
    if path.is_symlink():
        raise ContractError(f"{label} must not be a symlink: {path}")
    flags = os.O_RDONLY | getattr(os, "O_NOFOLLOW", 0)
    try:
        descriptor = os.open(path, flags)
    except OSError as exc:
        raise ContractError(f"cannot open {label} {path}: {exc}") from exc
    try:
        before = os.fstat(descriptor)
        if not stat.S_ISREG(before.st_mode):
            raise ContractError(f"{label} is not a regular file: {path}")
        chunks: list[bytes] = []
        while True:
            chunk = os.read(descriptor, 1024 * 1024)
            if not chunk:
                break
            chunks.append(chunk)
        after = os.fstat(descriptor)
        identity_before = (before.st_dev, before.st_ino, before.st_size, before.st_mtime_ns)
        identity_after = (after.st_dev, after.st_ino, after.st_size, after.st_mtime_ns)
        if identity_before != identity_after:
            raise ContractError(f"{label} changed while being read: {path}")
        return b"".join(chunks)
    finally:
        os.close(descriptor)


def _validate_relative(path: str) -> str:
    if not isinstance(path, str) or not path or any(c in path for c in "\0\r\n"):
        raise ContractError(f"invalid source path {path!r}")
    pure = PurePosixPath(path)
    if pure.is_absolute() or pure.as_posix() != path or any(p in ("", ".", "..") for p in pure.parts):
        raise ContractError(f"source path is not normalized and relative: {path!r}")
    return path


def _attested_source(repo: Path, relative: str) -> bytes:
    relative = _validate_relative(relative)
    path = repo / relative
    payload = _read_regular(path, "Focus source")
    pinned = _run_git(repo, "show", f"{FOCUS_COMMIT}:{FOCUS_GIT_PREFIX}{relative}")
    if payload != pinned:
        raise ContractError(f"source differs from pinned Git blob: {relative}")
    return payload


def _decode_utf8(payload: bytes, relative: str) -> str:
    try:
        return payload.decode("utf-8")
    except UnicodeDecodeError as exc:
        raise ContractError(f"Swift source is not UTF-8: {relative}: {exc}") from exc


def swift_tokens(source: str) -> list[tuple[str, int]]:
    """Return (token, line) pairs, omitting comments and string contents.

    Nested block comments and multiline strings are handled.  Identifiers in
    string interpolation are deliberately omitted: none of the reviewed
    framework references occur only inside interpolation, and treating prose as
    source would be worse.  ``test_focus_swiftui_surface.py`` pins this policy.
    """
    tokens: list[tuple[str, int]] = []
    index = 0
    line = 1
    length = len(source)

    def advance(count: int = 1) -> None:
        nonlocal index, line
        end = min(index + count, length)
        line += source.count("\n", index, end)
        index = end

    while index < length:
        if source.startswith("//", index):
            newline = source.find("\n", index + 2)
            advance(length - index if newline < 0 else newline - index)
            continue
        if source.startswith("/*", index):
            depth = 1
            advance(2)
            while depth and index < length:
                if source.startswith("/*", index):
                    depth += 1
                    advance(2)
                elif source.startswith("*/", index):
                    depth -= 1
                    advance(2)
                else:
                    advance()
            if depth:
                raise ContractError("unterminated Swift block comment")
            continue
        if source.startswith('"""', index):
            advance(3)
            while index < length and not source.startswith('"""', index):
                if source[index] == "\\" and index + 1 < length:
                    advance(2)
                else:
                    advance()
            if index >= length:
                raise ContractError("unterminated Swift multiline string")
            advance(3)
            continue
        if source[index] == '"':
            advance()
            while index < length and source[index] != '"':
                if source[index] == "\\" and index + 1 < length:
                    advance(2)
                else:
                    advance()
            if index >= length:
                raise ContractError("unterminated Swift string")
            advance()
            continue
        character = source[index]
        if character.isalpha() or character == "_":
            start = index
            token_line = line
            advance()
            while index < length and (source[index].isalnum() or source[index] == "_"):
                advance()
            tokens.append((source[start:index], token_line))
            continue
        if character.isdigit():
            start = index
            token_line = line
            advance()
            while index < length and (source[index].isdigit() or source[index] == "_"):
                advance()
            tokens.append((source[start:index], token_line))
            continue
        if character in "@.$#{}():,[]=<>\\":
            tokens.append((character, line))
        advance()
    return tokens


def _locations(tokens: list[tuple[str, int]], names: Iterable[str]) -> dict[str, list[int]]:
    accepted = frozenset(names)
    found: dict[str, set[int]] = defaultdict(set)
    for token, line in tokens:
        if token in accepted:
            found[token].add(line)
    return {name: sorted(found[name]) for name in sorted(found)}


def _member_locations(
    tokens: list[tuple[str, int]], names: Iterable[str], *, require_call: bool
) -> dict[str, list[int]]:
    accepted = frozenset(names)
    found: dict[str, set[int]] = defaultdict(set)
    for index in range(1, len(tokens)):
        token, line = tokens[index]
        if token not in accepted or tokens[index - 1][0] != ".":
            continue
        if require_call:
            next_token = tokens[index + 1][0] if index + 1 < len(tokens) else None
            if next_token not in {"(", "{"}:
                continue
        found[token].add(line)
    return {name: sorted(found[name]) for name in sorted(found)}


def _attribute_locations(tokens: list[tuple[str, int]]) -> dict[str, list[int]]:
    found: dict[str, set[int]] = defaultdict(set)
    for index in range(1, len(tokens)):
        token, line = tokens[index]
        if token in PROPERTY_WRAPPERS and tokens[index - 1][0] == "@":
            found[token].add(line)
    return {name: sorted(found[name]) for name in sorted(found)}


def _direct_imports(tokens: list[tuple[str, int]]) -> frozenset[str]:
    """Return exact direct import module spellings from one attested source."""

    modules: set[str] = set()
    for index, (token, line) in enumerate(tokens):
        if token != "import" or index + 1 >= len(tokens):
            continue
        cursor = index + 1
        if tokens[cursor][0] in SELECTIVE_IMPORT_KINDS:
            cursor += 1
        if cursor >= len(tokens) or tokens[cursor][1] != line:
            continue
        module = tokens[cursor][0]
        if re.fullmatch(r"[_A-Za-z][_A-Za-z0-9]*", module):
            modules.add(module)
    return frozenset(modules)


def _visible_module_api_locations(
    tokens: list[tuple[str, int]], direct_imports: frozenset[str]
) -> dict[str, dict[str, list[int]]]:
    """Derive external declarations which a compatibility import must expose.

    A symbol is omitted when the file directly imports its provider (or UIKit,
    for the provider families UIKit already exposes in the reviewed graph).
    The remaining locations are exact lexical evidence for *visibility*, not
    ownership: the new SwiftUI module may re-export the provider or arrange an
    equivalent single module identity.
    """

    result: dict[str, dict[str, list[int]]] = {}
    for module, names in sorted(VISIBLE_MODULE_API_VOCABULARY.items()):
        if direct_imports & DIRECT_VISIBILITY_IMPORTS[module]:
            continue
        locations = _locations(tokens, names)
        if locations:
            result[module] = locations
    return result


def _syntax_inventory(source: str, tokens: list[tuple[str, int]]) -> dict[str, Any]:
    # These are conservative lexical syntax candidates.  Brace nesting does
    # not distinguish a result-builder expression from a nested callback, and
    # token spelling alone does not resolve a conformance or projected value.
    # The names make that limit machine-visible in the canonical contract.
    flattened = " ".join(token for token, _ in tokens)
    named_projected_values = sum(
        1
        for index in range(len(tokens) - 1)
        if tokens[index][0] == "$"
        and re.fullmatch(r"[A-Za-z_][A-Za-z0-9_]*", tokens[index + 1][0])
    )
    view_body_conditionals = 0
    for index in range(len(tokens) - 5):
        if [token for token, _ in tokens[index:index + 5]] != [
            "var", "body", ":", "some", "View"
        ]:
            continue
        cursor = index + 5
        while cursor < len(tokens) and tokens[cursor][0] != "{":
            cursor += 1
        if cursor == len(tokens):
            continue
        depth = 1
        cursor += 1
        while cursor < len(tokens) and depth:
            token = tokens[cursor][0]
            if token == "{":
                depth += 1
            elif token == "}":
                depth -= 1
            elif token == "if":
                view_body_conditionals += 1
            cursor += 1
    declaration_prefix = r"(?:struct|class|enum)\s+\w+(?:\s*<[^{}]*>)?"
    return {
        "availability_check_tokens": len(re.findall(r"#\s*available\s*\(", flattened)),
        "generic_view_constraint_candidates": len(re.findall(r"\b(?:where\s+\w+\s*:\s*View|<\s*\w+\s*:\s*View\s*>)", flattened)),
        "body_some_view_declarations": len(re.findall(r"\bvar\s+body\s*:\s*some\s+View\b", flattened)),
        "preview_provider_conformance_candidates": len(re.findall(r":\s*PreviewProvider\b", flattened)),
        "opaque_some_view_parameter_candidates": len(re.findall(r":\s*some\s+View\b", flattened)) - len(re.findall(r"\bvar\s+\w+\s*:\s*some\s+View\b", flattened)),
        "some_view_occurrences": len(re.findall(r"\bsome\s+View\b", flattened)),
        "named_dollar_projection_candidates": named_projected_values,
        "if_tokens_lexically_nested_under_body_braces": view_body_conditionals,
        "view_conformance_candidates": (
            len(re.findall(declaration_prefix + r"\s*:\s*(?:\w+\s*,\s*)*View\b", flattened))
            + len(re.findall(r"\bextension\s+\w+\s*:\s*View\b", flattened))
        ),
    }


def _analyze_source(relative: str, payload: bytes) -> dict[str, Any]:
    source = _decode_utf8(payload, relative)
    tokens = swift_tokens(source)
    direct_imports = _direct_imports(tokens)
    scope, target, role, app_link = EXPECTED_IMPORTERS[relative]
    expected_extensions = FOCUS_SWIFTUI_EXTENSIONS.get(relative, {})
    extension_types = frozenset(
        match.group(1)
        for match in re.finditer(r"\bextension\s+(Color|Font|Gradient|Image|View)\b", source)
    )
    if extension_types != frozenset(expected_extensions):
        raise ContractError(
            f"Focus-declared SwiftUI extension set drifted in {relative}: "
            f"expected {sorted(expected_extensions)}, got {sorted(extension_types)}"
        )
    for members in expected_extensions.values():
        for member in members:
            base = member.split("(", 1)[0]
            if not re.search(rf"\b{re.escape(base)}\b", source):
                raise ContractError(f"reviewed extension member {member!r} missing in {relative}")
    types = _locations(tokens, SWIFTUI_TYPES)
    # SettingsViewController has an app-owned nested enum named Section.  It has
    # no SwiftUI Section usage, and is a hosting-only file; exclude that known
    # collision while retaining explicit SwiftUI.Section in actual view files.
    if relative == "Blockzilla/Settings/Controller/SettingsViewController.swift":
        types.pop("Section", None)
    adjacent: dict[str, dict[str, list[int]]] = {}
    for module, names in sorted(ADJACENT_FRAMEWORK_APIS.items()):
        locations = _locations(tokens, names)
        if locations:
            adjacent[module] = locations
    return {
        "app_link_closure": app_link,
        "bytes": len(payload),
        "direct_imports": sorted(direct_imports),
        "direct_import_swiftui": bool(IMPORT_SWIFTUI_RE.search(source)),
        "focus_declared_swiftui_extensions": expected_extensions,
        "lexical_swiftui_candidate_locations": {
            "global_functions": _locations(tokens, GLOBAL_FUNCTIONS),
            "leading_dot_members": _member_locations(tokens, INFERRED_MEMBERS, require_call=False),
            "property_wrappers": _attribute_locations(tokens),
            "types_and_protocols": types,
            "dot_call_modifiers": _member_locations(tokens, VIEW_MODIFIERS, require_call=True),
        },
        "adjacent_framework_lexical_candidate_locations": adjacent,
        "visible_module_api_locations": _visible_module_api_locations(
            tokens, direct_imports
        ),
        "line_count": payload.count(b"\n") + (0 if not payload or payload.endswith(b"\n") else 1),
        "path": relative,
        "role": role,
        "scope": scope,
        "sha256": sha256_bytes(payload),
        "lexical_syntax": _syntax_inventory(source, tokens),
        "target": target,
    }


def _aggregate(
    files: list[dict[str, Any]],
) -> tuple[dict[str, Any], dict[str, dict[str, dict[str, Any]]]]:
    api_files: dict[str, dict[str, set[str]]] = defaultdict(lambda: defaultdict(set))
    api_lines: dict[str, dict[str, int]] = defaultdict(lambda: defaultdict(int))
    syntax = Counter()
    adjacent: dict[str, dict[str, set[str]]] = defaultdict(lambda: defaultdict(set))
    visible_files: dict[str, dict[str, set[str]]] = defaultdict(lambda: defaultdict(set))
    visible_lines: dict[str, dict[str, int]] = defaultdict(lambda: defaultdict(int))
    for item in files:
        for family, symbols in item["lexical_swiftui_candidate_locations"].items():
            for symbol, lines in symbols.items():
                api_files[family][symbol].add(item["path"])
                api_lines[family][symbol] += len(lines)
        for module, symbols in item["adjacent_framework_lexical_candidate_locations"].items():
            for symbol in symbols:
                adjacent[module][symbol].add(item["path"])
        for module, symbols in item["visible_module_api_locations"].items():
            for symbol, lines in symbols.items():
                visible_files[module][symbol].add(item["path"])
                visible_lines[module][symbol] += len(lines)
        syntax.update(item["lexical_syntax"])
    lexical = {
        "adjacent_framework_lexical_candidates": {
            module: {
                symbol: sorted(paths)
                for symbol, paths in sorted(symbols.items())
            }
            for module, symbols in sorted(adjacent.items())
        },
        "swiftui_lexical_candidates": {
            family: {
                symbol: {
                    "file_count": len(paths),
                    "files": sorted(paths),
                    "line_location_count": api_lines[family][symbol],
                }
                for symbol, paths in sorted(symbols.items())
            }
            for family, symbols in sorted(api_files.items())
        },
        "lexical_syntax_counts": dict(sorted(syntax.items())),
    }
    visible = {
        module: {
            symbol: {
                "file_count": len(paths),
                "files": sorted(paths),
                "line_location_count": visible_lines[module][symbol],
            }
            for symbol, paths in sorted(symbols.items())
        }
        for module, symbols in sorted(visible_files.items())
    }
    return lexical, visible


def _load_plan(path: Path) -> tuple[bytes, dict[str, Any]]:
    payload = _read_regular(path, "Xcode plan")
    if sha256_bytes(payload) != XCODE_PLAN_SHA256:
        raise ContractError("Xcode plan bytes differ from reviewed canonical artifact")
    try:
        plan = json.loads(payload)
    except json.JSONDecodeError as exc:
        raise ContractError(f"cannot parse Xcode plan: {exc}") from exc
    if plan.get("subject", {}).get("git_commit") != FOCUS_COMMIT:
        raise ContractError("Xcode plan does not describe the reviewed Focus commit")
    return payload, plan


def _main_target_sources(plan: dict[str, Any]) -> list[str]:
    phases = [phase for phase in plan.get("build_phases", []) if phase.get("kind") == "sources"]
    if len(phases) != 1:
        raise ContractError(f"expected one main-target source phase, got {len(phases)}")
    files = phases[0].get("files")
    if not isinstance(files, list):
        raise ContractError("main-target source phase files must be a list")
    paths = [item.get("path") for item in files if item.get("file_type") == "sourcecode.swift"]
    if len(paths) != 131 or any(not isinstance(path, str) for path in paths):
        raise ContractError("reviewed Blockzilla target must have exactly 131 Swift references")
    return paths


def _discover_package_importers(repo: Path) -> tuple[list[str], dict[str, int]]:
    discovered: list[str] = []
    target_counts: dict[str, int] = {}
    for target in PACKAGE_TARGETS:
        base = repo / "BlockzillaPackage" / "Sources" / target
        if not base.is_dir() or base.is_symlink():
            raise ContractError(f"missing or unsafe implicit SwiftPM source directory: {base}")
        swift_files = sorted(base.rglob("*.swift"))
        target_counts[target] = len(swift_files)
        for path in swift_files:
            relative = path.relative_to(repo).as_posix()
            payload = _attested_source(repo, relative)
            if IMPORT_SWIFTUI_RE.search(_decode_utf8(payload, relative)):
                discovered.append(relative)
    return sorted(discovered), dict(sorted(target_counts.items()))


def build_contract(focus_repo: Path, xcode_plan: Path) -> dict[str, Any]:
    focus_repo = focus_repo.resolve()
    head = _run_git(focus_repo, "rev-parse", "HEAD").decode("ascii").strip()
    if head != FOCUS_COMMIT:
        raise ContractError(f"Focus checkout must be at {FOCUS_COMMIT}, got {head}")

    _, plan = _load_plan(xcode_plan.resolve())
    manifest = _attested_source(focus_repo, "BlockzillaPackage/Package.swift")
    if sha256_bytes(manifest) != PACKAGE_MANIFEST_SHA256:
        raise ContractError("local package manifest differs from reviewed bytes")
    project = _attested_source(focus_repo, "Blockzilla.xcodeproj/project.pbxproj")
    if sha256_bytes(project) != PBX_PROJECT_SHA256:
        raise ContractError("Xcode project differs from reviewed bytes")

    main_sources = _main_target_sources(plan)
    generated_missing = sorted(path for path in main_sources if not (focus_repo / path).exists())
    if generated_missing != [
        "Blockzilla/Generated/AppNimbus.swift",
        "Blockzilla/Generated/Metrics.swift",
    ]:
        raise ContractError(f"main-target generated source boundary drifted: {generated_missing}")

    main_importers: list[str] = []
    for relative in main_sources:
        if relative in generated_missing:
            continue
        payload = _attested_source(focus_repo, relative)
        if IMPORT_SWIFTUI_RE.search(_decode_utf8(payload, relative)):
            main_importers.append(relative)

    package_importers, package_source_counts = _discover_package_importers(focus_repo)

    # The exact PBX project bytes pin this extension source-phase membership;
    # the identifiers are additionally checked so the assertion is visible.
    widget_source = "Widgets/Widgets.swift"
    project_text = _decode_utf8(project, "Blockzilla.xcodeproj/project.pbxproj")
    for needle in (
        "C824D2DA28EEBF9B00DEA5DE /* Widgets.swift in Sources */",
        "C824D2D428EEBF9000DEA5DE /* WidgetsExtension */",
        "C824D2D128EEBF9000DEA5DE /* Sources */",
    ):
        if needle not in project_text:
            raise ContractError(f"WidgetsExtension membership marker missing: {needle}")
    widget_importers: list[str] = []
    for relative in WIDGET_EXTENSION_SOURCES:
        payload = _attested_source(focus_repo, relative)
        if IMPORT_SWIFTUI_RE.search(_decode_utf8(payload, relative)):
            widget_importers.append(relative)
    if widget_importers != [widget_source]:
        raise ContractError(f"WidgetsExtension SwiftUI importer boundary drifted: {widget_importers}")

    discovered = sorted(set(main_importers + package_importers + widget_importers))
    expected = sorted(EXPECTED_IMPORTERS)
    if discovered != expected:
        missing = sorted(set(expected) - set(discovered))
        added = sorted(set(discovered) - set(expected))
        raise ContractError(f"SwiftUI importer set drifted; missing={missing}, added={added}")

    files = [_analyze_source(relative, _attested_source(focus_repo, relative)) for relative in expected]
    app_link_files = [item for item in files if item["app_link_closure"]]
    preview_only = [item for item in files if item["role"] == "preview_only"]
    role_counts = Counter(item["role"] for item in files)
    scope_counts = Counter(item["scope"] for item in files)
    target_import_counts = Counter(item["target"] for item in files)
    lexical_aggregate, visible_requirements = _aggregate(files)

    return {
        "schema": SCHEMA,
        "claim_boundary": {
            "compile_surface": "Exact checked-in direct-import files and hashes for the reviewed pin; API-looking tokens remain conservative lexical candidates, not compiler-resolved ownership or ABI completeness.",
            "lexical_candidates": "Token locations are exact, but type/member/projected-value/ViewBuilder attribution is deliberately not claimed; hosting files contain UIKit and Combine collisions.",
            "renderer": "No renderer is implemented or proven by this inventory.",
            "runtime_semantics": "No SwiftUI runtime behavior is implemented or proven by this inventory.",
            "source_compatibility_goal": "A guest module named SwiftUI must compile these sources without changing their imports or call sites.",
        },
        "subject": {
            "focus_commit": FOCUS_COMMIT,
            "focus_repository": "mozilla-mobile/focus-ios",
            "package_manifest": {
                "path": "BlockzillaPackage/Package.swift",
                "sha256": PACKAGE_MANIFEST_SHA256,
            },
            "pbx_project": {
                "path": "Blockzilla.xcodeproj/project.pbxproj",
                "sha256": PBX_PROJECT_SHA256,
            },
            "xcode_plan": {
                "path": "full/xcodeplan/focus-plan.json",
                "sha256": XCODE_PLAN_SHA256,
                "target": "Blockzilla",
                "configuration": "FocusDebug",
                "swift_source_references": 131,
            },
        },
        "generated_source_boundary": {
            "main_target_missing_outputs": [
                {
                    "accepted_output_sha256": "62c7618de24c2e7273c8e48f54a05988fddff719d92400e262ed8770058f4bec",
                    "direct_import_swiftui": False,
                    "path": "Blockzilla/Generated/AppNimbus.swift",
                    "provenance": "full/focus-ios/generated_sources_provenance.md",
                    "status": "reviewed developer-channel output hash; historical launcher revision inferred",
                },
                {
                    "accepted_output_sha256": "aea69809e642b25bebb82f392d82d8d6efca2227fc585cff8bf983e0fd3bea17",
                    "direct_import_swiftui": False,
                    "path": "Blockzilla/Generated/Metrics.swift",
                    "provenance": "full/focus-ios/generated_sources_provenance.md",
                    "status": "reproducibly generated and reviewed output hash",
                },
            ],
            "intent_derived_output": {
                "current_xcode_reference_sha256": "4b8206a1e37f0bb6c13cb8ef1fb2b9fd0b0fbb360c05c73b7762a1d1eebbabb4",
                "direct_import_swiftui": False,
                "historical_xcode_14_2_bytes": "unresolved",
                "path": "derived/EraseIntent.swift",
                "provenance": "full/focus-ios/generated_sources_provenance.md",
            },
        },
        "membership": {
            "app_link_closure_direct_importers": len(app_link_files),
            "direct_importer_count": len(files),
            "package_implicit_swift_source_counts": package_source_counts,
            "preview_only_compile_inputs": len(preview_only),
            "production_or_bridge_inputs": len(files) - len(preview_only),
            "role_counts": dict(sorted(role_counts.items())),
            "scope_counts": dict(sorted(scope_counts.items())),
            "target_direct_import_counts": dict(sorted(target_import_counts.items())),
            "unique_widget_extension_only_importers": 1,
            "widget_extension_swift_source_count": len(WIDGET_EXTENSION_SOURCES),
        },
        "implicit_compile_requirements": {
            "compiler_lowering": [
                "ViewBuilder.buildBlock/buildEither/buildIf/buildLimitedAvailability",
                "Binding projected-value plumbing",
                "DynamicProperty update participation",
                "opaque-result and conditional-content storage",
            ],
            "inferred_public_signature_families": [
                "Alignment / HorizontalAlignment / VerticalAlignment",
                "Animation and withAnimation",
                "Axis and Edge.Set",
                "Binding",
                "ColorScheme",
                "ContentMode",
                "Font.TextStyle and Font.Weight",
                "NavigationBarItem.TitleDisplayMode",
                "Optional View content",
                "PageTabViewStyle and index-display mode",
                "PreviewLayout",
                "Shape and ShapeStyle",
                "TextAlignment",
                "ToolbarContentBuilder",
                "UnitPoint",
            ],
            "required_reexports_or_visible_modules": {
                module: sorted(symbols)
                for module, symbols in sorted(
                    (module, evidence.keys())
                    for module, evidence in visible_requirements.items()
                )
            },
            "visible_module_symbol_evidence": visible_requirements,
            "visibility_derivation": "For each exact importer, scan a reviewed external-symbol vocabulary and retain occurrences when the source does not directly import the provider (UIKit is an accepted direct visibility route for Foundation/CoreGraphics/CoreText). Locations prove unqualified visibility demand, not declaration ownership.",
            "reason": "The pinned files use these unqualified without a direct provider import, or require them through property-wrapper/result-builder lowering. SwiftUI may re-export the single authoritative provider module rather than redeclare its types.",
        },
        "entry_surfaces": [
            {
                "entry": "OnboardingFactory.make(.v2)",
                "host": "PortraitHostingController<OnboardingView>",
                "kind": "main_app_runtime",
            },
            {
                "entry": "BrowserViewController route .widget",
                "host": "PortraitHostingController<CardBannerView>",
                "kind": "main_app_runtime",
            },
            {
                "entry": "BrowserViewController route .showMeHow",
                "host": "PortraitHostingController<ShowMeHowOnboardingView>",
                "kind": "main_app_runtime",
            },
            {
                "entry": "SettingsViewController licenses",
                "host": "UIHostingController<LicenseListView>",
                "kind": "main_app_runtime",
            },
            {
                "entry": "SettingsViewController internal settings",
                "host": "UIHostingController<InternalSettingsView>",
                "kind": "main_app_runtime",
            },
            {
                "entry": "WidgetsExtension @main",
                "host": "WidgetKit StaticConfiguration<FocusWidgetsEntryView>",
                "kind": "extension_runtime",
            },
        ],
        "aggregate": lexical_aggregate,
        "files": files,
    }


def canonical_bytes(contract: dict[str, Any]) -> bytes:
    return (json.dumps(contract, indent=2, sort_keys=True) + "\n").encode("utf-8")


def _write_new_or_replace(path: Path, payload: bytes) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    temporary = path.with_name(f".{path.name}.tmp-{os.getpid()}")
    if temporary.exists():
        raise ContractError(f"refusing existing temporary path: {temporary}")
    flags = os.O_WRONLY | os.O_CREAT | os.O_EXCL | getattr(os, "O_NOFOLLOW", 0)
    descriptor = os.open(temporary, flags, 0o644)
    try:
        offset = 0
        while offset < len(payload):
            written = os.write(descriptor, payload[offset:])
            if written <= 0:
                raise ContractError(f"short write while creating {temporary}")
            offset += written
        os.fsync(descriptor)
    finally:
        os.close(descriptor)
    os.replace(temporary, path)


def main(argv: list[str] | None = None) -> int:
    script = Path(__file__).resolve()
    repository = script.parents[2]
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "--focus-repo",
        type=Path,
        default=repository / "scratch/ladder-corpus/focus-ios/focus-ios",
    )
    parser.add_argument(
        "--xcode-plan",
        type=Path,
        default=repository / "full/xcodeplan/focus-plan.json",
    )
    mode = parser.add_mutually_exclusive_group()
    mode.add_argument("--output", type=Path, help="write canonical JSON")
    mode.add_argument("--check", type=Path, help="compare against canonical JSON")
    arguments = parser.parse_args(argv)
    try:
        payload = canonical_bytes(build_contract(arguments.focus_repo, arguments.xcode_plan))
        if arguments.check:
            expected = _read_regular(arguments.check.resolve(), "canonical SwiftUI contract")
            if expected != payload:
                raise ContractError(f"canonical contract drift: {arguments.check}")
            print(f"SWIFTUI CONTRACT OK sha256={sha256_bytes(payload)}")
        elif arguments.output:
            _write_new_or_replace(arguments.output.resolve(), payload)
            print(f"wrote {arguments.output} sha256={sha256_bytes(payload)}")
        else:
            sys.stdout.buffer.write(payload)
        return 0
    except ContractError as exc:
        print(f"SWIFTUI CONTRACT ERROR: {exc}", file=sys.stderr)
        return 2


if __name__ == "__main__":
    raise SystemExit(main())
