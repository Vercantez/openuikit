#!/usr/bin/env python3
"""Inventory framework imports from the pinned iOS application corpus.

Only committed Git blobs at the exact commits in ``CORPUS_PINS`` are read.
The checkout contents are never read as source input, so dirty/untracked files
cannot change the result.  The output deliberately measures direct textual
imports; it is not a linker closure or a claim that an import is launch-time
reachable.
"""

from __future__ import annotations

import argparse
from collections import defaultdict
from dataclasses import dataclass
import hashlib
import json
import os
from pathlib import Path, PurePosixPath
import re
import subprocess
import sys
from typing import Any, Iterable


SCHEMA = 2
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
FOCUS_MAIN_MANIFEST_SHA256 = (
    "1a870fe23b50fac9f05bfa8db73902625be433cec96db83f6a8f8752a929ad02"
)

CORPUS_PINS = {
    "Hackers": "83016de256ef5418f76ec53182d25e302a519234",
    "NetNewsWire": "3b378e72f877f86258b2d04e1601719f9d0036a7",
    "ProtonMail-ios": "701463fe4542945c49ac5d326b0c27e91441e02f",
    "Signal-iOS": "eec0a2f587b49082efdb5a4dc1e2a491fd52144f",
    "Telegram-iOS": "6ad963e5b62d354da79040f388ae2b9132fb17b8",
    "WordPress-iOS": "8d89c36221d06d5b9b8887e7092cfa9dfce98cf0",
    "duckduckgo-ios": "7b3f6010d27a3a69fe92a2ad698543f2e67c8900",
    "eidolon": "44486ed9149f16b3eb3a5e687f99ae078309f4fe",
    "eigen": "8d61cf9fee501dc0ec2fe964cfa9394890a8574f",
    "element-ios": "36a1788da26933557c468325da2851298ed0386b",
    "firefox-ios": "b0799c34c313be9e832b749794f91277a9ce57eb",
    "focus-ios": "a2832521c1daa0c23419c73705ae043ed60c9791",
    "home-assistant-ios": "2ada5ddd5449b520cc03267f06e82e9c6c3d7b45",
    "ios-oss": "2f2dabb40b74dd1e7a7511a0dedb47d967ab08a0",
    "mastodon-ios": "ea5ef8e7daee650029f44b1ec6f744a08c4eed51",
    "nextcloud-ios": "8104883d62b98f078b34479d9ebecdfa16b56cd7",
    "pocket-casts-ios": "3b27afc6e69d56b5d7eb67579fa5e622fbeaed10",
    "simplenote-ios": "9b1bb17d8ec224a709d306e0ec34cee38bc7d933",
    "vlc-ios": "12cd503e3b12e00f0bc36ef568d2edf985c7d473",
    "wikipedia-ios": "2f334df620ba1e5aa36d24d9d9dccdf3aa935d4b",
}

SOURCE_SUFFIXES = frozenset({".swift", ".m", ".mm", ".h", ".pch"})

# This is intentionally a transparent, conservative path policy rather than a
# claim to understand every Xcode/Bazel target in twenty unrelated projects.
# Tracked product source candidates are included, including vendored code that
# is committed in the app repository.  Obvious non-shipping scopes are removed.
EXCLUDED_DIRECTORY_NAMES = frozenset(
    {
        ".build",
        "benchmark",
        "benchmarks",
        "build",
        "demo",
        "demos",
        "deriveddata",
        "docs",
        "documentation",
        "example",
        "examples",
        "fixture",
        "fixtures",
        "mock",
        "mocks",
        "playground",
        "playgrounds",
        "sample",
        "samples",
        "script",
        "scripts",
        "snapshottests",
        "test",
        "testbed",
        "tests",
        "tooling",
        "tools",
        "uitest",
        "uitests",
        "unittest",
        "unittests",
        "unit_test",
        "wmftestkitchen",
    }
)
NON_SHIPPING_DIRECTORY_SUFFIXES = (
    "datamocks",
    "networkfixtures",
    "snapshottests",
    "testfixtures",
    "testhelpers",
    "testing",
    "testkit",
    "testmocks",
    "testsfoundation",
    "testsupport",
    "tests",
    "testutils",
    "uitests",
    "unittests",
)
TEST_FILE_SUFFIXES = ("test.swift", "tests.swift", "test.m", "tests.m", "test.mm", "tests.mm")

# Classification is allowlist based.  A name absent from these sets is never
# guessed to be Apple merely because it resembles an Apple framework name.
APPLE_IPHONEOS_FRAMEWORK_MODULES = frozenset(
    {
        "AVFAudio",
        "AVFoundation",
        "AVKit",
        "Accelerate",
        "Accounts",
        "ActivityKit",
        "AdSupport",
        "AdAttributionKit",
        "AdServices",
        "AddressBook",
        "AlarmKit",
        "AppClip",
        "AppIntents",
        "AppTrackingTransparency",
        "ARKit",
        "AssetsLibrary",
        "AuthenticationServices",
        "AudioToolbox",
        "AudioUnit",
        "BackgroundTasks",
        "BusinessChat",
        "CallKit",
        "CarPlay",
        "CFNetwork",
        "Charts",
        "ClassKit",
        "ClockKit",
        "CloudKit",
        "Combine",
        "Contacts",
        "ContactsUI",
        "CoreAudio",
        "CoreAudioKit",
        "CoreAudioTypes",
        "CoreBluetooth",
        "CoreData",
        "CoreFoundation",
        "CoreGraphics",
        "CoreHaptics",
        "CoreImage",
        "CoreLocation",
        "CoreMedia",
        "CoreMediaIO",
        "CoreMIDI",
        "CoreML",
        "CoreMotion",
        "CoreNFC",
        "CoreServices",
        "CoreSpotlight",
        "CoreTelephony",
        "CoreText",
        "CoreTransferable",
        "CoreVideo",
        "CryptoKit",
        "DeviceActivity",
        "DeveloperToolsSupport",
        "DeviceCheck",
        "DeviceDiscoveryUI",
        "EventKit",
        "EventKitUI",
        "ExposureNotification",
        "ExtensionFoundation",
        "ExtensionKit",
        "ExternalAccessory",
        "FamilyControls",
        "FileProvider",
        "FileProviderUI",
        "Foundation",
        "FoundationModels",
        "GLKit",
        "GameController",
        "GameKit",
        "GameplayKit",
        "HealthKit",
        "HomeKit",
        "ImageCaptureCore",
        "ImagePlayground",
        "Intents",
        "IntentsUI",
        "JavaScriptCore",
        "IOKit",
        "LinkPresentation",
        "LocalAuthentication",
        "MapKit",
        "MediaAccessibility",
        "MediaPlayer",
        "MessageUI",
        "Messages",
        "Metal",
        "MetalKit",
        "MetalPerformanceShaders",
        "MetricKit",
        "MatterSupport",
        "MobileCoreServices",
        "MultipeerConnectivity",
        "NaturalLanguage",
        "Network",
        "NetworkExtension",
        "NotificationCenter",
        "OSLog",
        "PassKit",
        "PencilKit",
        "Photos",
        "PhotosUI",
        "PushKit",
        "QuickLook",
        "QuickLookThumbnailing",
        "ReplayKit",
        "SafariServices",
        "SceneKit",
        "Security",
        "SensorKit",
        "ShazamKit",
        "Social",
        "Speech",
        "SpriteKit",
        "StoreKit",
        "SwiftData",
        "SwiftUI",
        "SwiftUICore",
        "SystemConfiguration",
        "ThreadNetwork",
        "TipKit",
        "Translation",
        "UIKit",
        "UniformTypeIdentifiers",
        "UserNotifications",
        "UserNotificationsUI",
        "VideoSubscriberAccount",
        "VideoToolbox",
        "Vision",
        "VisionKit",
        "WatchConnectivity",
        "WeatherKit",
        "WebKit",
        "WiFiAware",
        "WidgetKit",
        "_PassKit_SwiftUI",
    }
)

# These are Apple-owned modules observed in the heterogeneous repository
# trees, but they are not iPhoneOS application-runtime port candidates.  Keep
# them explicit instead of allowing the conventional-name fallback to label
# them project/third-party code.
APPLE_NON_IOS_OR_DEVELOPER_MODULES = frozenset(
    {
        "AppKit",
        "Cocoa",
        "WatchKit",
        "XCTest",
    }
)

APPLE_SYSTEM_MODULES = frozenset(
    {
        "CommonCrypto",
        "Compression",
        "Darwin",
        "Dispatch",
        "IOSurface",
        "ImageIO",
        "MachO",
        "ObjectiveC",
        "OpenGLES",
        "PDFKit",
        "QuartzCore",
        "QuickLookUI",
        "XPC",
        "dispatch",
        "libkern",
        "mach",
        "notify",
        "objc",
        "os",
        "simd",
    }
)

SWIFT_TOOLCHAIN_MODULES = frozenset(
    {
        "FoundationEssentials",
        "FoundationNetworking",
        "FoundationXML",
        "Observation",
        "PackageDescription",
        "RegexBuilder",
        "Swift",
        "Synchronization",
        "_Concurrency",
        "_StringProcessing",
        "swift",
    }
)

NON_APPLE_SYSTEM_MODULES = frozenset(
    {
        "Glibc",
        "SQLite3",
        "WinSDK",
        "arpa",
        "net",
        "netinet",
        "netinet6",
        "netipsec",
        "pthread",
        "sys",
        "libxml2",
        "zlib",
    }
)

REQUESTED_FAMILIES = (
    ("Foundation", ("Foundation",), "base runtime, data, files, networking facades"),
    ("UIKit", ("UIKit",), "iOS application and view framework"),
    ("SwiftUI", ("SwiftUI",), "declarative UI framework"),
    ("Combine", ("Combine",), "reactive streams and property publishing"),
    ("WebKit", ("WebKit",), "web view and browser engine API"),
    ("Intents / IntentsUI", ("Intents", "IntentsUI"), "Siri/custom intent model and UI"),
    ("UserNotifications", ("UserNotifications", "UserNotificationsUI"), "notification delivery and extension UI"),
    ("BackgroundTasks", ("BackgroundTasks",), "background scheduling and task lifecycle"),
    ("CoreSpotlight", ("CoreSpotlight",), "system search indexing"),
    (
        "MobileCoreServices / UTType",
        ("MobileCoreServices", "UniformTypeIdentifiers"),
        "legacy UTI APIs and modern UTType (UTType is a type, not an importable module)",
    ),
    ("WidgetKit", ("WidgetKit",), "widget extension runtime"),
    ("SafariServices", ("SafariServices",), "Safari view and content-blocker APIs"),
    ("StoreKit", ("StoreKit",), "purchases and App Store APIs"),
    ("AuthenticationServices", ("AuthenticationServices",), "web authentication and credentials"),
    ("CoreGraphics", ("CoreGraphics",), "2D geometry and drawing"),
    ("QuartzCore", ("QuartzCore",), "Core Animation layers and timing"),
)

SWIFT_IMPORT_RE = re.compile(
    r"^\s*(?:(?:@[_A-Za-z][_A-Za-z0-9]*(?:\([^)]*\))?)\s+)*"
    r"(?:(?:fileprivate|internal|package|private|public)\s+)?"
    r"import\s+(?:(?:class|enum|func|let|protocol|struct|typealias|var)\s+)?"
    r"([_A-Za-z][_A-Za-z0-9]*)\b"
)
OBJC_UMBRELLA_RE = re.compile(
    r"^\s*#\s*(?:import|include)\s*<\s*([_A-Za-z][_A-Za-z0-9]*)\s*/"
)
OBJC_MODULE_RE = re.compile(r"^\s*@\s*import\s+([_A-Za-z][_A-Za-z0-9]*)\b")


class RoadmapError(RuntimeError):
    """The pinned inventory subject or generated artifact is invalid."""


@dataclass(frozen=True)
class TreeSource:
    path: str
    oid: str
    size: int | None = None


@dataclass(frozen=True)
class ImportHit:
    module: str
    path: str
    line: int
    language: str


def _git(repo: Path, *args: str) -> bytes:
    try:
        return subprocess.check_output(
            [
                SYSTEM_GIT,
                "--no-replace-objects",
                "-c", "core.fsmonitor=false",
                "-c", f"core.hooksPath={os.devnull}",
                "-C", str(repo),
                *args,
            ],
            stderr=subprocess.STDOUT,
            env=GIT_ENVIRONMENT,
        )
    except (OSError, subprocess.CalledProcessError) as exc:
        output = getattr(exc, "output", b"")
        if isinstance(output, bytes):
            detail = output.decode("utf-8", errors="replace").strip()
        else:
            detail = str(output)
        raise RoadmapError(f"git {' '.join(args)} failed in {repo}: {detail}") from exc


def is_shipping_source(path: str) -> tuple[bool, str | None]:
    """Apply the documented tracked-product-source path policy."""

    pure = PurePosixPath(path)
    suffix = pure.suffix.lower()
    if suffix not in SOURCE_SUFFIXES:
        return False, "unsupported-extension"
    directories = [part.lower() for part in pure.parts[:-1]]
    for part in directories:
        if part.startswith("."):
            return False, "hidden-tooling-directory"
        if (
            part in EXCLUDED_DIRECTORY_NAMES
            or part.startswith("testable")
            or part.endswith(NON_SHIPPING_DIRECTORY_SUFFIXES)
        ):
            return False, "non-shipping-directory"
    filename = pure.name.lower()
    if filename.endswith(TEST_FILE_SUFFIXES):
        return False, "test-source-filename"
    return True, None


def strip_comments_preserving_lines(source: str) -> str:
    """Blank comments and string literals while preserving line positions."""

    result: list[str] = []
    index = 0
    block_depth = 0
    quote_close: str | None = None
    escaped = False
    while index < len(source):
        char = source[index]
        next_char = source[index + 1] if index + 1 < len(source) else ""
        if block_depth:
            if char == "/" and next_char == "*":
                block_depth += 1
                result.extend((" ", " "))
                index += 2
            elif char == "*" and next_char == "/":
                block_depth -= 1
                result.extend((" ", " "))
                index += 2
            else:
                result.append("\n" if char == "\n" else " ")
                index += 1
            continue
        if quote_close is not None:
            if source.startswith(quote_close, index) and not escaped:
                result.extend(" " * len(quote_close))
                index += len(quote_close)
                quote_close = None
                continue
            result.append("\n" if char == "\n" else " ")
            if escaped:
                escaped = False
            elif char == "\\":
                escaped = True
            index += 1
            continue
        hash_end = index
        while hash_end < len(source) and source[hash_end] == "#":
            hash_end += 1
        quote = None
        if source.startswith('"""', hash_end):
            quote = '"""'
        elif hash_end < len(source) and source[hash_end] == '"':
            quote = '"'
        if quote is not None:
            hashes = source[index:hash_end]
            opening = hashes + quote
            quote_close = quote + hashes
            result.extend(" " * len(opening))
            index += len(opening)
        elif char == "'":
            quote_close = "'"
            result.append(" ")
            index += 1
        elif char == "/" and next_char == "/":
            while index < len(source) and source[index] != "\n":
                result.append(" ")
                index += 1
        elif char == "/" and next_char == "*":
            block_depth = 1
            result.extend((" ", " "))
            index += 2
        else:
            result.append(char)
            index += 1
    return "".join(result)


def extract_imports(path: str, source_bytes: bytes) -> list[ImportHit]:
    """Extract direct imports from one committed Swift/Objective-C source blob."""

    try:
        source = source_bytes.decode("utf-8")
    except UnicodeDecodeError:
        source = source_bytes.decode("utf-8", errors="replace")
    source = strip_comments_preserving_lines(source)
    suffix = PurePosixPath(path).suffix.lower()
    language = "swift" if suffix == ".swift" else "objective-c"
    hits: list[ImportHit] = []
    for line_number, line in enumerate(source.splitlines(), start=1):
        match = SWIFT_IMPORT_RE.match(line) if language == "swift" else None
        if match is None and language == "objective-c":
            match = OBJC_UMBRELLA_RE.match(line) or OBJC_MODULE_RE.match(line)
        if match is not None:
            hits.append(ImportHit(match.group(1), path, line_number, language))
    return hits


def classify_module(module: str) -> tuple[str, str, str]:
    """Return category, confidence, and policy reason for a module name."""

    if module in APPLE_IPHONEOS_FRAMEWORK_MODULES:
        return (
            "apple_first_party",
            "high",
            "fixed iPhoneOS public-framework runtime-port allowlist",
        )
    if module in APPLE_SYSTEM_MODULES:
        return (
            "apple_first_party",
            "high",
            "fixed iPhoneOS SDK/system-module runtime-port allowlist",
        )
    if module in APPLE_NON_IOS_OR_DEVELOPER_MODULES:
        return (
            "apple_non_ios_or_developer",
            "high",
            "fixed non-iPhoneOS Apple framework/developer-module allowlist",
        )
    if module in SWIFT_TOOLCHAIN_MODULES:
        return "swift_toolchain", "high", "fixed Swift toolchain-module allowlist"
    if module in NON_APPLE_SYSTEM_MODULES:
        return "non_apple_system", "high", "fixed portable/system-module allowlist"
    casefolded_apple = {
        candidate.casefold()
        for candidate in (
            APPLE_IPHONEOS_FRAMEWORK_MODULES
            | APPLE_SYSTEM_MODULES
            | APPLE_NON_IOS_OR_DEVELOPER_MODULES
        )
    }
    if module.casefold() in casefolded_apple:
        return (
            "uncertain",
            "low",
            "case-insensitive collision with an Apple allowlist name; exact module spelling differs",
        )
    if module.startswith("_") or (module and module[0].islower()):
        return (
            "uncertain",
            "low",
            "unrecognized private-style or lowercase module; manual ownership review required",
        )
    return (
        "project_or_third_party",
        "medium",
        "not present in fixed Apple, Swift-toolchain, or system allowlists",
    )


def list_tree_sources(repo: Path, pin: str) -> tuple[list[TreeSource], dict[str, int]]:
    raw = _git(repo, "ls-tree", "-r", "-l", "-z", "--full-tree", pin)
    included: list[TreeSource] = []
    counts: dict[str, int] = defaultdict(int)
    for raw_record in raw.split(b"\0"):
        if not raw_record:
            continue
        try:
            metadata, raw_path = raw_record.split(b"\t", 1)
            mode, object_type, raw_oid, raw_size = metadata.split(b" ", 3)
            path = raw_path.decode("utf-8")
        except (ValueError, UnicodeDecodeError) as exc:
            raise RoadmapError(f"cannot parse UTF-8 Git tree entry in {repo}") from exc
        if mode == b"160000" or object_type != b"blob":
            counts["gitlinks-or-non-blobs"] += 1
            continue
        allowed, reason = is_shipping_source(path)
        if not allowed:
            counts[reason or "excluded"] += 1
            continue
        size = None if raw_size == b"-" else int(raw_size)
        included.append(TreeSource(path=path, oid=raw_oid.decode("ascii"), size=size))
        counts["included"] += 1
    return sorted(included, key=lambda item: item.path), dict(sorted(counts.items()))


def read_blob_imports(repo: Path, sources: Iterable[TreeSource]) -> list[ImportHit]:
    """Read blobs through one cat-file process without consulting the worktree."""

    command = [
        SYSTEM_GIT,
        "--no-replace-objects",
        "-c", "core.fsmonitor=false",
        "-c", f"core.hooksPath={os.devnull}",
        "-C", str(repo),
        "cat-file", "--batch",
    ]
    try:
        process = subprocess.Popen(
            command,
            stdin=subprocess.PIPE,
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
            env=GIT_ENVIRONMENT,
        )
    except OSError as exc:
        raise RoadmapError(f"cannot start git cat-file in {repo}: {exc}") from exc
    assert process.stdin is not None
    assert process.stdout is not None
    hits: list[ImportHit] = []
    try:
        for source in sources:
            process.stdin.write(source.oid.encode("ascii") + b"\n")
            process.stdin.flush()
            header = process.stdout.readline().rstrip(b"\n")
            fields = header.split(b" ")
            if len(fields) != 3 or fields[0] != source.oid.encode("ascii") or fields[1] != b"blob":
                raise RoadmapError(
                    f"unexpected cat-file response for {source.path}: {header!r}"
                )
            size = int(fields[2])
            blob = process.stdout.read(size)
            terminator = process.stdout.read(1)
            if len(blob) != size or terminator != b"\n":
                raise RoadmapError(f"truncated cat-file response for {source.path}")
            if source.size is not None and size != source.size:
                raise RoadmapError(f"tree/blob size disagreement for {source.path}")
            hits.extend(extract_imports(source.path, blob))
    finally:
        try:
            process.stdin.close()
        except BrokenPipeError:
            pass
    stderr = process.stderr.read() if process.stderr is not None else b""
    return_code = process.wait()
    process.stdout.close()
    if process.stderr is not None:
        process.stderr.close()
    if return_code != 0:
        raise RoadmapError(
            f"git cat-file failed in {repo}: {stderr.decode('utf-8', errors='replace').strip()}"
        )
    return hits


def source_manifest_digest(sources: Iterable[TreeSource]) -> str:
    payload = b"".join(
        item.path.encode("utf-8") + b"\0" + item.oid.encode("ascii") + b"\0"
        for item in sources
    )
    return hashlib.sha256(payload).hexdigest()


def evidence_digest(hits: Iterable[ImportHit]) -> str:
    payload = b"".join(
        hit.module.encode("utf-8")
        + b"\0"
        + hit.path.encode("utf-8")
        + b"\0"
        + str(hit.line).encode("ascii")
        + b"\0"
        + hit.language.encode("ascii")
        + b"\0"
        for hit in sorted(hits, key=lambda h: (h.module, h.path, h.line, h.language))
    )
    return hashlib.sha256(payload).hexdigest()


def load_focus_main_sources(
    manifest_path: Path,
    focus_repo: Path,
    focus_sources: list[TreeSource],
    expected_pin: str,
) -> tuple[set[str], dict[str, Any]]:
    try:
        raw = manifest_path.read_bytes()
        manifest = json.loads(raw)
    except (OSError, json.JSONDecodeError) as exc:
        raise RoadmapError(f"cannot read Focus main-source manifest: {exc}") from exc
    manifest_sha256 = hashlib.sha256(raw).hexdigest()
    if manifest_sha256 != FOCUS_MAIN_MANIFEST_SHA256:
        raise RoadmapError(
            "Focus main-source manifest differs from the reviewed pinned attestation"
        )
    if manifest.get("repository_commit") != expected_pin:
        raise RoadmapError("Focus main-source manifest pin does not match corpus pin")
    project = manifest.get("project")
    present = manifest.get("present_sources")
    if not isinstance(project, dict) or not isinstance(project.get("path"), str):
        raise RoadmapError("Focus main-source manifest has no project path")
    if not isinstance(present, list) or not all(isinstance(item, str) for item in present):
        raise RoadmapError("Focus main-source manifest has invalid present_sources")

    tree_paths = {item.path: item for item in focus_sources}
    project_suffix = project["path"]
    all_tree = _git(focus_repo, "ls-tree", "-r", "-z", "--name-only", expected_pin)
    project_candidates = [
        value.decode("utf-8")
        for value in all_tree.split(b"\0")
        if value and (value.decode("utf-8") == project_suffix or value.decode("utf-8").endswith("/" + project_suffix))
    ]
    if len(project_candidates) != 1:
        raise RoadmapError(
            f"cannot uniquely locate Focus project root for {project_suffix!r}: {project_candidates}"
        )
    located_project = project_candidates[0]
    root_prefix = located_project[: -len(project_suffix)]
    project_blob = _git(focus_repo, "show", f"{expected_pin}:{located_project}")
    if hashlib.sha256(project_blob).hexdigest() != project.get("sha256"):
        raise RoadmapError("Focus project blob differs from main-source attestation")
    if len(project_blob) != project.get("size"):
        raise RoadmapError("Focus project blob size differs from main-source attestation")
    mapped = {root_prefix + value for value in present}
    missing = sorted(mapped - set(tree_paths))
    if missing:
        raise RoadmapError(
            "Focus main-source paths are outside the shipping-source subject: "
            + ", ".join(missing[:5])
        )
    attestation = {
        "manifest_path": "full/focus-ios/focus-main-sources.json",
        "manifest_sha256": manifest_sha256,
        "project_root_prefix": root_prefix,
        "present_source_count": len(mapped),
        "present_source_digest": manifest.get("present_source_digest"),
    }
    return mapped, attestation


def _module_stats(
    module: str,
    repo_hits: dict[str, list[ImportHit]],
    focus_main_sources: set[str],
) -> dict[str, Any]:
    per_app: dict[str, dict[str, Any]] = {}
    all_hits: list[tuple[str, ImportHit]] = []
    for app in sorted(repo_hits):
        selected = [hit for hit in repo_hits[app] if hit.module == module]
        if not selected:
            continue
        all_hits.extend((app, hit) for hit in selected)
        files = sorted({hit.path for hit in selected})
        per_app[app] = {
            "file_count": len(files),
            "occurrence_count": len(selected),
            "evidence_sha256": evidence_digest(selected),
            "sample_paths": files[:8],
        }
    focus_hits = [hit for app, hit in all_hits if app == "focus-ios"]
    focus_main_hits = [hit for hit in focus_hits if hit.path in focus_main_sources]
    launch_names = {"AppDelegate.swift", "SceneDelegate.swift", "main.swift"}
    focus_launch_hits = [
        hit for hit in focus_main_hits if PurePosixPath(hit.path).name in launch_names
    ]
    category, confidence, reason = classify_module(module)
    return {
        "module": module,
        "category": category,
        "classification_confidence": confidence,
        "classification_reason": reason,
        "app_coverage_count": len(per_app),
        "file_count": len({(app, hit.path) for app, hit in all_hits}),
        "occurrence_count": len(all_hits),
        "focus": {
            "repository_file_count": len({hit.path for hit in focus_hits}),
            "main_target_file_count": len({hit.path for hit in focus_main_hits}),
            "launch_anchor_file_count": len({hit.path for hit in focus_launch_hits}),
            "main_target_evidence_sha256": evidence_digest(focus_main_hits),
            "launch_anchor_paths": sorted({hit.path for hit in focus_launch_hits}),
        },
        "per_app": per_app,
    }


def _focus_sort_key(record: dict[str, Any]) -> tuple[Any, ...]:
    focus = record["focus"]
    return (
        -int(focus["launch_anchor_file_count"] > 0),
        -int(focus["main_target_file_count"] > 0),
        -focus["main_target_file_count"],
        -int(focus["repository_file_count"] > 0),
        -focus["repository_file_count"],
        -record["app_coverage_count"],
        record["module"],
    )


def _coverage_sort_key(record: dict[str, Any]) -> tuple[Any, ...]:
    return (
        -record["app_coverage_count"],
        -record["file_count"],
        -record["focus"]["main_target_file_count"],
        record["module"],
    )


def build_inventory(
    corpus: Path,
    focus_manifest: Path,
    pins: dict[str, str] | None = None,
) -> dict[str, Any]:
    pins = dict(CORPUS_PINS if pins is None else pins)
    if not pins:
        raise RoadmapError("corpus pin set is empty")
    repo_hits: dict[str, list[ImportHit]] = {}
    repo_records: list[dict[str, Any]] = []
    sources_by_repo: dict[str, list[TreeSource]] = {}
    for app, pin in sorted(pins.items()):
        repo = corpus / app
        if not repo.is_dir():
            raise RoadmapError(f"missing pinned corpus repository: {repo}")
        actual = _git(repo, "rev-parse", "HEAD").decode("ascii").strip()
        if actual != pin:
            raise RoadmapError(f"{app} HEAD changed: expected {pin}, got {actual}")
        sources, exclusions = list_tree_sources(repo, pin)
        hits = read_blob_imports(repo, sources)
        sources_by_repo[app] = sources
        repo_hits[app] = hits
        repo_records.append(
            {
                "app": app,
                "commit": pin,
                "shipping_source_candidate_count": len(sources),
                "source_manifest_sha256": source_manifest_digest(sources),
                "direct_import_count": len(hits),
                "direct_import_evidence_sha256": evidence_digest(hits),
                "tree_filter_counts": exclusions,
            }
        )

    if "focus-ios" not in sources_by_repo:
        raise RoadmapError("Focus must be present to produce Focus relevance ranks")
    focus_main_sources, focus_attestation = load_focus_main_sources(
        focus_manifest,
        corpus / "focus-ios",
        sources_by_repo["focus-ios"],
        pins["focus-ios"],
    )

    observed_modules = {hit.module for hits in repo_hits.values() for hit in hits}
    required_modules = {module for _, modules, _ in REQUESTED_FAMILIES for module in modules}
    module_records = [
        _module_stats(module, repo_hits, focus_main_sources)
        for module in sorted(observed_modules | required_modules)
    ]
    iphoneos_runtime_records = [
        record for record in module_records if record["category"] == "apple_first_party"
    ]
    coverage_order = sorted(iphoneos_runtime_records, key=_coverage_sort_key)
    focus_order = sorted(iphoneos_runtime_records, key=_focus_sort_key)
    coverage_rank = {record["module"]: index + 1 for index, record in enumerate(coverage_order)}
    focus_rank = {record["module"]: index + 1 for index, record in enumerate(focus_order)}
    for record in module_records:
        record["iphoneos_runtime_app_coverage_rank"] = coverage_rank.get(record["module"])
        record["iphoneos_runtime_focus_launch_build_rank"] = focus_rank.get(record["module"])

    by_module = {record["module"]: record for record in module_records}
    families: list[dict[str, Any]] = []
    for name, modules, note in REQUESTED_FAMILIES:
        records = [by_module[module] for module in modules]
        apps = sorted({app for record in records for app in record["per_app"]})
        families.append(
            {
                "family": name,
                "modules": list(modules),
                "note": note,
                "app_coverage_count": len(apps),
                "apps": apps,
                "file_count": sum(record["file_count"] for record in records),
                "focus_main_target_file_count": sum(
                    record["focus"]["main_target_file_count"] for record in records
                ),
                "focus_repository_file_count": sum(
                    record["focus"]["repository_file_count"] for record in records
                ),
            }
        )

    category_counts: dict[str, int] = defaultdict(int)
    for record in module_records:
        category_counts[record["category"]] += 1
    return {
        "schema": SCHEMA,
        "subject": {
            "kind": "direct textual imports in committed tracked product-source candidates",
            "corpus_root_argument": "scratch/ladder-corpus",
            "repository_count": len(repo_records),
            "source_suffixes": sorted(SOURCE_SUFFIXES),
            "submodules": "gitlinks recorded as excluded; nested repositories are not traversed",
            "worktree_policy": "read HEAD identity, tree entries, and blobs via Git object database; ignore worktree bytes",
            "git_environment_policy": "absolute /usr/bin/git, no replacement objects, no inherited environment, no global/system config, fixed locale and PATH",
            "shipping_filter_policy": {
                "included": "tracked Swift/Objective-C source/header blobs outside explicit non-shipping path exclusions; committed vendored source remains included",
                "excluded_directory_names": sorted(EXCLUDED_DIRECTORY_NAMES),
                "excluded_directory_suffixes": list(NON_SHIPPING_DIRECTORY_SUFFIXES),
                "excluded_hidden_directories": True,
                "excluded_testable_prefix_directories": True,
                "excluded_test_filename_suffixes": list(TEST_FILE_SUFFIXES),
                "limitation": "path policy is a reproducible approximation across heterogeneous Xcode/Bazel projects, not target membership or launch reachability",
            },
            "import_policy": "Swift import declarations and Objective-C @import or angle-bracket #import/#include umbrella roots; conditional imports count; local quoted headers do not",
            "classification_policy": {
                "apple_first_party": "exact membership in fixed iPhoneOS public-framework or iPhoneOS SDK/system-module runtime-port allowlists",
                "apple_non_ios_or_developer": "exact membership in a fixed Apple-owned non-iPhoneOS/developer-module allowlist; reported but excluded from runtime port rankings",
                "swift_toolchain": "exact membership in fixed Swift toolchain allowlist; reported separately from Apple frameworks",
                "non_apple_system": "exact membership in fixed portable/system allowlist",
                "project_or_third_party": "all other conventional module names; app-local and third-party are intentionally combined because imports alone cannot distinguish ownership",
                "uncertain": "unrecognized underscore-prefixed or lowercase module names; requires manual ownership review",
                "no_name_shape_guessing": "true except case-insensitive Apple-name collisions are flagged uncertain rather than assigned ownership",
                "allowlist_basis": "fixed reviewed names, including all observed names matching public iPhoneOS 26.1 framework directories plus reviewed iPhoneOS SDK/system modules; non-iOS Apple/developer and cross-platform Swift-toolchain modules are explicit separate categories; generation does not consult the host SDK",
                "allowlists": {
                    "apple_iphoneos_framework_modules": sorted(APPLE_IPHONEOS_FRAMEWORK_MODULES),
                    "apple_iphoneos_sdk_system_modules": sorted(APPLE_SYSTEM_MODULES),
                    "apple_non_ios_or_developer_modules": sorted(APPLE_NON_IOS_OR_DEVELOPER_MODULES),
                    "swift_toolchain_modules": sorted(SWIFT_TOOLCHAIN_MODULES),
                    "non_apple_system_modules": sorted(NON_APPLE_SYSTEM_MODULES),
                },
            },
            "ranking_policy": {
                "subject": "observed iPhoneOS public-framework and reviewed iPhoneOS SDK/system-module runtime port candidates only; non-iOS Apple/developer and Swift-toolchain modules are excluded",
                "app_coverage": "iPhoneOS/runtime candidates by distinct app repositories, then distinct source files, then Focus main-target files, then module name",
                "focus_launch_build": "iPhoneOS/runtime candidates by direct launch-anchor import, exact Blockzilla main-target import/file count, any Focus-repository import/file count, corpus coverage, then module name",
                "launch_anchor_definition": "exact main-target basenames AppDelegate.swift, SceneDelegate.swift, or main.swift",
                "limitation": "ranking is static direct-import/build evidence; it does not assert transitive linkage or runtime launch reachability",
            },
        },
        "focus_main_target_attestation": focus_attestation,
        "summary": {
            "repository_count": len(repo_records),
            "shipping_source_candidate_count": sum(
                record["shipping_source_candidate_count"] for record in repo_records
            ),
            "direct_import_count": sum(record["direct_import_count"] for record in repo_records),
            "observed_module_count": len(observed_modules),
            "reported_module_count": len(module_records),
            "category_module_counts": dict(sorted(category_counts.items())),
            "iphoneos_runtime_port_candidate_count": len(iphoneos_runtime_records),
            "apple_non_ios_or_developer_module_count": category_counts.get(
                "apple_non_ios_or_developer", 0
            ),
            "uncertain_modules": sorted(
                record["module"]
                for record in module_records
                if record["category"] == "uncertain"
            ),
        },
        "repositories": repo_records,
        "requested_roadmap_families": families,
        "iphoneos_runtime_port_candidate_rankings": {
            "by_app_coverage": [record["module"] for record in coverage_order],
            "by_focus_launch_build_relevance": [record["module"] for record in focus_order],
        },
        "modules": module_records,
    }


def canonical_json(inventory: dict[str, Any]) -> bytes:
    return (json.dumps(inventory, indent=2, ensure_ascii=False) + "\n").encode("utf-8")


def render_markdown(inventory: dict[str, Any]) -> bytes:
    summary = inventory["summary"]
    modules = {record["module"]: record for record in inventory["modules"]}
    lines = [
        "# Apple framework port roadmap",
        "",
        "This is a source-unchanged inventory of direct imports in committed Git blobs at the 20 pinned app revisions. It is a roadmap input, not a claim that an Xcode project links or launches on Linux.",
        "",
        "## Scope and evidence",
        "",
        f"- {summary['repository_count']} pinned repositories; {summary['shipping_source_candidate_count']} tracked shipping-source candidates; {summary['direct_import_count']} direct import declarations.",
        "- Worktree source bytes are ignored. Git tree/blob objects at the pinned commits are the input.",
        "- Tests, examples, demos, fixtures, docs, scripts, tools, and benchmark paths are excluded by the exact policy in the JSON. Committed vendored product source is included.",
        "- The path policy is reproducible but is not a universal Xcode/Bazel target parser. Static imports do not prove transitive linkage or launch-time reachability.",
        "- iPhoneOS/runtime port candidacy is an exact allowlist decision. Non-iOS Apple/developer modules and Swift-toolchain modules are explicit separate categories. App-local and third-party modules remain grouped because an import name cannot reliably distinguish them. Private-style/lowercase unknowns are flagged uncertain.",
        "",
        "## iPhoneOS/runtime port candidates by app coverage",
        "",
        "| Rank | Module | Apps / 20 | Files | Focus main target | Focus repository |",
        "| ---: | --- | ---: | ---: | ---: | ---: |",
    ]
    coverage_names = inventory["iphoneos_runtime_port_candidate_rankings"]["by_app_coverage"]
    for name in coverage_names[:40]:
        record = modules[name]
        lines.append(
            f"| {record['iphoneos_runtime_app_coverage_rank']} | `{name}` | {record['app_coverage_count']} | {record['file_count']} | {record['focus']['main_target_file_count']} | {record['focus']['repository_file_count']} |"
        )
    lines.extend(
        [
            "",
            f"The table shows the top 40 of {len(coverage_names)} observed iPhoneOS/runtime port candidates; the JSON contains the complete ranking. Apple-owned non-iOS/developer modules and Swift-toolchain modules remain inventoried but are excluded from this order.",
            "",
            "## Focus launch/build relevance",
            "",
            "This order puts direct imports in Focus launch anchors first, then imports in the exact 129-source Blockzilla target, then other Focus repository sources. It is build evidence, not a runtime call-graph claim.",
            "",
            "| Rank | Module | Launch anchors | Main-target files | Focus files | Corpus apps |",
            "| ---: | --- | ---: | ---: | ---: | ---: |",
        ]
    )
    focus_names = [
        name
        for name in inventory["iphoneos_runtime_port_candidate_rankings"]["by_focus_launch_build_relevance"]
        if modules[name]["focus"]["repository_file_count"] > 0
    ]
    for name in focus_names:
        record = modules[name]
        lines.append(
            f"| {record['iphoneos_runtime_focus_launch_build_rank']} | `{name}` | {record['focus']['launch_anchor_file_count']} | {record['focus']['main_target_file_count']} | {record['focus']['repository_file_count']} | {record['app_coverage_count']} |"
        )
    lines.extend(
        [
            "",
            "## Requested baseline families",
            "",
            "| Family | Import modules | Apps / 20 | Files | Focus main target | Focus repository |",
            "| --- | --- | ---: | ---: | ---: | ---: |",
        ]
    )
    for family in inventory["requested_roadmap_families"]:
        rendered_modules = ", ".join(f"`{name}`" for name in family["modules"])
        lines.append(
            f"| {family['family']} | {rendered_modules} | {family['app_coverage_count']} | {family['file_count']} | {family['focus_main_target_file_count']} | {family['focus_repository_file_count']} |"
        )
    uncertain = summary["uncertain_modules"]
    non_ios_apple = sorted(
        record["module"]
        for record in inventory["modules"]
        if record["category"] == "apple_non_ios_or_developer"
    )
    swift_toolchain = sorted(
        record["module"]
        for record in inventory["modules"]
        if record["category"] == "swift_toolchain"
    )
    lines.extend(
        [
            "",
            "## Classification boundary",
            "",
            f"Observed categories: {json.dumps(summary['category_module_counts'], sort_keys=True)}.",
            "",
            "Apple-owned non-iOS/developer modules (inventoried, not ranked as iPhoneOS runtime ports): "
            + ", ".join(f"`{name}`" for name in non_ios_apple)
            + ".",
            "",
            "Swift-toolchain modules (inventoried, not framework ports): "
            + ", ".join(f"`{name}`" for name in swift_toolchain)
            + ".",
            "",
            "Uncertain module names requiring ownership review: "
            + (", ".join(f"`{name}`" for name in uncertain) if uncertain else "none")
            + ".",
            "",
            "`MobileCoreServices` is the legacy module; modern `UTType` lives in `UniformTypeIdentifiers` and is not itself an importable module. Full per-app evidence counts, samples, source/blob digests, policy, and both complete rankings are in `framework-roadmap.json`.",
            "",
            "## Reproduce",
            "",
            "```sh",
            "cd full/framework-roadmap",
            "python3 framework_roadmap.py --check",
            "python3 -m unittest -v test_framework_roadmap.py",
            "```",
            "",
        ]
    )
    return "\n".join(lines).encode("utf-8")


def _check_or_write(path: Path, expected: bytes, check: bool) -> None:
    if check:
        try:
            actual = path.read_bytes()
        except OSError as exc:
            raise RoadmapError(f"cannot read canonical artifact {path}: {exc}") from exc
        if actual != expected:
            raise RoadmapError(
                f"canonical artifact differs: {path}; regenerate without --check"
            )
    else:
        path.write_bytes(expected)


def parse_args(argv: list[str]) -> argparse.Namespace:
    here = Path(__file__).resolve().parent
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "--corpus",
        type=Path,
        default=here.parents[1] / "scratch" / "ladder-corpus",
    )
    parser.add_argument(
        "--focus-main-manifest",
        type=Path,
        default=here.parent / "focus-ios" / "focus-main-sources.json",
    )
    parser.add_argument("--json", type=Path, default=here / "framework-roadmap.json")
    parser.add_argument("--markdown", type=Path, default=here / "FRAMEWORK-ROADMAP.md")
    parser.add_argument("--check", action="store_true")
    return parser.parse_args(argv)


def main(argv: list[str] | None = None) -> int:
    args = parse_args(sys.argv[1:] if argv is None else argv)
    try:
        inventory = build_inventory(
            args.corpus.resolve(), args.focus_main_manifest.resolve()
        )
        _check_or_write(args.json.resolve(), canonical_json(inventory), args.check)
        _check_or_write(args.markdown.resolve(), render_markdown(inventory), args.check)
    except RoadmapError as exc:
        print(f"framework-roadmap: error: {exc}", file=sys.stderr)
        return 1
    action = "verified" if args.check else "wrote"
    print(
        f"framework-roadmap: {action} {len(inventory['repositories'])} repositories, "
        f"{inventory['summary']['shipping_source_candidate_count']} sources, "
        f"{inventory['summary']['direct_import_count']} imports, "
        f"{inventory['summary']['iphoneos_runtime_port_candidate_count']} "
        "iPhoneOS/runtime port candidates"
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
