#!/usr/bin/env python3
"""Fail-closed proof for Focus's exact non-SwiftUI Onboarding closure.

The proof emits Apple-targeted modules from proof-local, byte-attested copies
of the pinned OpenUIKit, SnapKit, and Focus inputs.  It is deliberately not a
SwiftPM/Xcode build of Focus and it does not link or execute an application.
"""

from __future__ import annotations

import ctypes
from dataclasses import dataclass
import errno
from functools import lru_cache
import hashlib
import json
import os
from pathlib import Path, PurePosixPath
import re
import stat
import subprocess
import sys
from typing import Any, Iterable, Sequence


FOCUS_COMMIT = "a2832521c1daa0c23419c73705ae043ed60c9791"
OPENUIKIT_COMMIT = "4c82757bb9cf193605dd9625d73562b1758e85e8"
SNAPKIT_COMMIT = "e74fe2a978d1216c3602b129447c7301573cc2d8"
TARGET = "arm64-apple-macos13.0"
SWIFTPM_TRIPLE = "arm64-apple-macosx"
SWIFT_LANGUAGE_VERSION = "5"
MODULE_ORDER = ("UIKit", "SnapKit", "DesignSystem", "OnboardingUIKitCore")
DIRECT_MODULES = ("SnapKit", "DesignSystem", "OnboardingUIKitCore")
MODULE_SUFFIXES = (".abi.json", ".swiftdoc", ".swiftmodule", ".swiftsourceinfo")

FOCUS_MANIFEST = {
    "path": "BlockzillaPackage/Package.swift",
    "size": 1975,
    "sha256": "2d29b769de137389f5613de6755211b255533375bf6003a2192f514e96899248",
}
FOCUS_WORKSPACE_LOCK = {
    "path": "Blockzilla.xcodeproj/project.xcworkspace/xcshareddata/swiftpm/Package.resolved",
    "size": 1409,
    "sha256": "632a0df0276ba7828f456ae3964f158fb7115d05f175ddf637abdd7ab4a4633b",
}

DESIGN_SOURCES = (
    "BlockzillaPackage/Sources/DesignSystem/Bundle+CurrentBundle.swift",
    "BlockzillaPackage/Sources/DesignSystem/UIColor+AppColors.swift",
    "BlockzillaPackage/Sources/DesignSystem/UIFont+AppFonts.swift",
    "BlockzillaPackage/Sources/DesignSystem/UIImage+AppImages.swift",
)
DESIGN_EXCLUSIONS = (
    "BlockzillaPackage/Sources/DesignSystem/Preview Files/AppColorsView.swift",
    "BlockzillaPackage/Sources/DesignSystem/Preview Files/AppFontsView.swift",
    "BlockzillaPackage/Sources/DesignSystem/Preview Files/AppImagesView.swift",
)
ONBOARDING_SOURCES = (
    "BlockzillaPackage/Sources/Onboarding/Handler/Action.swift",
    "BlockzillaPackage/Sources/Onboarding/Handler/OnboardingEventsHandlerV1.swift",
    "BlockzillaPackage/Sources/Onboarding/Handler/OnboardingEventsHandlerV2.swift",
    "BlockzillaPackage/Sources/Onboarding/Handler/OnboardingEventsHandling.swift",
    "BlockzillaPackage/Sources/Onboarding/Handler/OnboardingVersion.swift",
    "BlockzillaPackage/Sources/Onboarding/Handler/ToolTipRoute.swift",
    "BlockzillaPackage/Sources/Onboarding/OnboardingViewController.swift",
    "BlockzillaPackage/Sources/Onboarding/Tooltip/TooltipTableViewCell.swift",
    "BlockzillaPackage/Sources/Onboarding/Tooltip/TooltipView.swift",
    "BlockzillaPackage/Sources/Onboarding/Tooltip/TooltipViewController.swift",
)
ONBOARDING_EXCLUSIONS = (
    "BlockzillaPackage/Sources/Onboarding/DesignSystem/Color+AppColors.swift",
    "BlockzillaPackage/Sources/Onboarding/DesignSystem/Font+AppFonts.swift",
    "BlockzillaPackage/Sources/Onboarding/DesignSystem/Image+AppImages.swift",
    "BlockzillaPackage/Sources/Onboarding/PortraitHostingController.swift",
    "BlockzillaPackage/Sources/Onboarding/Preview Files/OnboardingPreview.swift",
    "BlockzillaPackage/Sources/Onboarding/SwiftUI Onboarding/CardBannerView.swift",
    "BlockzillaPackage/Sources/Onboarding/SwiftUI Onboarding/DefaultBrowserOnboardingView.swift",
    "BlockzillaPackage/Sources/Onboarding/SwiftUI Onboarding/GetStartedOnboardingView.swift",
    "BlockzillaPackage/Sources/Onboarding/SwiftUI Onboarding/OnboardingView.swift",
    "BlockzillaPackage/Sources/Onboarding/SwiftUI Onboarding/OnboardingViewModel.swift",
    "BlockzillaPackage/Sources/Onboarding/SwiftUI Onboarding/ShowMeHowOnboardingView.swift",
)

SNAPKIT_SOURCES = (
    "Sources/Constraint.swift",
    "Sources/ConstraintAttributes.swift",
    "Sources/ConstraintConfig.swift",
    "Sources/ConstraintConstantTarget.swift",
    "Sources/ConstraintDSL.swift",
    "Sources/ConstraintDescription.swift",
    "Sources/ConstraintDirectionalInsetTarget.swift",
    "Sources/ConstraintDirectionalInsets.swift",
    "Sources/ConstraintInsetTarget.swift",
    "Sources/ConstraintInsets.swift",
    "Sources/ConstraintItem.swift",
    "Sources/ConstraintLayoutGuide+Extensions.swift",
    "Sources/ConstraintLayoutGuide.swift",
    "Sources/ConstraintLayoutGuideDSL.swift",
    "Sources/ConstraintLayoutSupport.swift",
    "Sources/ConstraintLayoutSupportDSL.swift",
    "Sources/ConstraintMaker.swift",
    "Sources/ConstraintMakerEditable.swift",
    "Sources/ConstraintMakerExtendable.swift",
    "Sources/ConstraintMakerFinalizable.swift",
    "Sources/ConstraintMakerPrioritizable.swift",
    "Sources/ConstraintMakerRelatable+Extensions.swift",
    "Sources/ConstraintMakerRelatable.swift",
    "Sources/ConstraintMultiplierTarget.swift",
    "Sources/ConstraintOffsetTarget.swift",
    "Sources/ConstraintPriority.swift",
    "Sources/ConstraintPriorityTarget.swift",
    "Sources/ConstraintRelatableTarget.swift",
    "Sources/ConstraintRelation.swift",
    "Sources/ConstraintView+Extensions.swift",
    "Sources/ConstraintView.swift",
    "Sources/ConstraintViewDSL.swift",
    "Sources/LayoutConstraint.swift",
    "Sources/LayoutConstraintItem.swift",
    "Sources/Typealiases.swift",
    "Sources/UILayoutSupport+Extensions.swift",
)
SNAPKIT_EXCLUSION = {
    "path": "Sources/Debugging.swift",
    "size": 6281,
    "sha256": "6af70d54a6e6fb112d87f8adb93caead0bc2afc472e4bbb04347bf591be3b3e3",
    "reason": (
        "Diagnostic string formatting only: it overrides NSLayoutConstraint.description "
        "through NSObject/@objc dispatch, which a pure-Swift OpenUIKit base cannot provide; "
        "it defines no constraint creation, installation, update, or SnapKit DSL API."
    ),
}

OPENUIKIT_ROOTS = (
    "Package.swift",
    "Sources/COpenUIKitABI",
    "Sources/CPortableIO",
    "Sources/CQuartz",
    "Sources/CSDL2",
    "Sources/CSTBTrueType",
    "Sources/DemoApp",
    "Sources/OpenCoreGraphics",
    "Sources/OpenUIKit",
    "Sources/OpenUIKitC",
    "Sources/RealAppProbe",
    "Sources/UIKitShim",
    "Sources/objcparity",
    "Sources/openhost/AppMode.swift",
    "Sources/openhost/HostCore.swift",
    "Sources/openhost/main.swift",
    "Sources/openrender",
    "Tests",
)
OPENUIKIT_VALIDATION_EXCLUSIONS = (
    {
        "path": "Sources/openhost/SceneBuilder.swift",
        "sha256": "c28f5085f31c6035da590d26d591e1db89aadf496e49f695ad434aa3366eb452",
        "size": 32,
        "target": "../openrender/SceneBuilder.swift",
    },
    {
        "path": "Sources/openhost/SceneIO.swift",
        "sha256": "ee579d7cd85f4ef611f195eb72a9665d9a3b3976fe1ad11046e7f22f8906584b",
        "size": 27,
        "target": "../openrender/SceneIO.swift",
    },
)

ACCESSOR_BYTES = (
    b"import Foundation\n\n"
    b"extension Foundation.Bundle {\n"
    b"    static var module: Bundle { fatalError(\"runtime Bundle.module discovery is unavailable\") }\n"
    b"}\n"
)
ACCESSOR_PATH = "generated/DesignSystem/Bundle+Module.swift"
ACCESSOR_SHA256 = "c0a3ee61e4fc8015d5e4a36775293347e21c58850605a6d47141f344211829aa"

EXPECTED_ONBOARDING_WARNINGS = (
    {
        "path": "BlockzillaPackage/Sources/Onboarding/Handler/OnboardingEventsHandlerV2.swift",
        "line": 11,
        "column": 57,
        "message": "cannot use struct 'Publisher' here; 'Combine' was not imported by this file",
    },
    {
        "path": "BlockzillaPackage/Sources/Onboarding/Handler/OnboardingEventsHandling.swift",
        "line": 9,
        "column": 50,
        "message": "cannot use struct 'Publisher' here; 'Combine' was not imported by this file",
    },
)

SYSTEM_XCRUN = "/usr/bin/xcrun"
SAFE_PATH = "/usr/bin:/bin:/usr/sbin:/sbin"
SHA256_RE = re.compile(r"[0-9a-f]{64}\Z")
COMMIT_RE = re.compile(r"[0-9a-f]{40}\Z")
PRIMARY_WARNING_RE = re.compile(r"^(.*?):(\d+):(\d+): warning: (.*)$")
PRIMARY_ERROR_RE = re.compile(r"(?:^|:\d+:\d+: )error: ", re.MULTILINE)
ANY_WARNING_RE = re.compile(r"(?:^|:\d+:\d+: )warning: ", re.MULTILINE)
NOFOLLOW = getattr(os, "O_NOFOLLOW", 0)
DARWIN_ACL_TYPE_EXTENDED = 0x00000100


class ProofError(RuntimeError):
    """The requested proof no longer describes the reviewed subject."""


@lru_cache(maxsize=1)
def _darwin_acl_functions() -> tuple[Any, Any]:
    libc = ctypes.CDLL(None, use_errno=True)
    acl_get_link = libc.acl_get_link_np
    acl_get_link.argtypes = (ctypes.c_char_p, ctypes.c_int)
    acl_get_link.restype = ctypes.c_void_p
    acl_free = libc.acl_free
    acl_free.argtypes = (ctypes.c_void_p,)
    acl_free.restype = ctypes.c_int
    return acl_get_link, acl_free


def _has_extended_acl(path: Path) -> bool:
    """Return whether a path carries a macOS extended ACL, without following it."""
    if sys.platform != "darwin":
        return False
    acl_get_link, acl_free = _darwin_acl_functions()
    ctypes.set_errno(0)
    acl = acl_get_link(os.fsencode(path), DARWIN_ACL_TYPE_EXTENDED)
    if not acl:
        error = ctypes.get_errno()
        if error == errno.ENOENT:
            return False
        raise ProofError(f"cannot inspect extended ACL for {path}: errno {error}")
    try:
        return True
    finally:
        if acl_free(acl) != 0:
            raise ProofError(f"cannot release extended ACL inspection for {path}")


@dataclass(frozen=True)
class CapturedFile:
    path: str
    data: bytes

    def record(self) -> dict[str, Any]:
        return {"path": self.path, "sha256": sha256(self.data), "size": len(self.data)}


@dataclass(frozen=True)
class FocusCapture:
    commit: str
    status_sha256: str
    manifest: CapturedFile
    workspace_lock: CapturedFile
    design_sources: tuple[CapturedFile, ...]
    design_exclusions: tuple[CapturedFile, ...]
    design_resources: tuple[CapturedFile, ...]
    onboarding_sources: tuple[CapturedFile, ...]
    onboarding_exclusions: tuple[CapturedFile, ...]

    def identity(self) -> bytes:
        return canonical_json(capture_audit(self))


@dataclass(frozen=True)
class RepositoryCapture:
    name: str
    commit: str
    status_sha256: str
    files: tuple[CapturedFile, ...]
    exclusions: tuple[CapturedFile, ...] = ()

    def identity(self) -> bytes:
        return canonical_json(capture_audit(self))


@dataclass(frozen=True)
class AppleToolchain:
    xcrun_path: str
    xcrun_size: int
    xcrun_sha256: str
    swift_launcher_path: str
    swift_resolved_path: str
    swift_size: int
    swift_sha256: str
    swiftc_launcher_path: str
    swiftc_resolved_path: str
    swiftc_size: int
    swiftc_sha256: str
    sdk_path: str
    sdk_settings_size: int
    sdk_settings_sha256: str
    swift_version: bytes
    swiftc_version: bytes

    def audit(self) -> dict[str, Any]:
        return {
            "discovery": {
                "path": self.xcrun_path,
                "sha256": self.xcrun_sha256,
                "size": self.xcrun_size,
            },
            "environment": {
                "inheritance": "none; fixed allowlist",
                "values": controlled_environment(),
            },
            "sdk": {
                "path": self.sdk_path,
                "settings_sha256": self.sdk_settings_sha256,
                "settings_size": self.sdk_settings_size,
            },
            "swift": {
                "launcher_path": self.swift_launcher_path,
                "resolved_path": self.swift_resolved_path,
                "sha256": self.swift_sha256,
                "size": self.swift_size,
                "version": self.swift_version.decode("utf-8", errors="strict").splitlines(),
                "version_sha256": sha256(self.swift_version),
            },
            "swiftc": {
                "launcher_path": self.swiftc_launcher_path,
                "resolved_path": self.swiftc_resolved_path,
                "sha256": self.swiftc_sha256,
                "size": self.swiftc_size,
                "version": self.swiftc_version.decode("utf-8", errors="strict").splitlines(),
                "version_sha256": sha256(self.swiftc_version),
            },
        }


def sha256(data: bytes) -> str:
    return hashlib.sha256(data).hexdigest()


def canonical_json(value: Any) -> bytes:
    return (json.dumps(value, indent=2, sort_keys=True) + "\n").encode("utf-8")


def records_digest(records: Iterable[tuple[str, bytes]]) -> str:
    aggregate = hashlib.sha256()
    for path, data in sorted(records, key=lambda item: item[0].encode("utf-8")):
        aggregate.update(path.encode("utf-8"))
        aggregate.update(b"\0")
        aggregate.update(str(len(data)).encode("ascii"))
        aggregate.update(b"\0")
        aggregate.update(sha256(data).encode("ascii"))
        aggregate.update(b"\n")
    return aggregate.hexdigest()


def expected_policy() -> dict[str, Any]:
    return {
        "build": {
            "apple_toolchain_required": True,
            "dependency_order": list(MODULE_ORDER),
            "direct_module_suffixes": list(MODULE_SUFFIXES),
            "openuikit_swiftpm_target": "UIKit",
            "parse_as_library": True,
            "swift_language_version": SWIFT_LANGUAGE_VERSION,
            "swiftpm_triple": SWIFTPM_TRIPLE,
            "target": TARGET,
            "whole_module_optimization": True,
        },
        "claims": {
            "apple_toolchain_module_emission_only": True,
            "focus_package_or_xcode_build": False,
            "linux_guest_link_or_run": False,
            "resource_catalog_compilation_or_decode": False,
            "runtime_bundle_discovery": False,
        },
        "diagnostic_contract": {
            "dependency_build_diagnostics_recorded_and_zero_errors": True,
            "design_system_and_snapkit_zero_diagnostics": True,
            "onboarding_expected_warnings": [dict(item) for item in EXPECTED_ONBOARDING_WARNINGS],
            "zero_errors_every_module": True,
        },
        "focus": {
            "commit": FOCUS_COMMIT,
            "design_system": {
                "excluded_source_count": 3,
                "excluded_source_digest": "f51db65db76ad183db8cd1d9df5322a4fd1b0be5990c1620373c21fba2cc734c",
                "excluded_sources": list(DESIGN_EXCLUSIONS),
                "input_stage_path": "inputs/focus",
                "resource_byte_count": 169439,
                "resource_count": 117,
                "resource_declaration": "raw-unhandled-at-pinned-manifest",
                "resource_digest": "4f75873dc2a9e08bea4d35cd1b2e6fc8cad6858f0ff8f44afeb59efe2ffde61f",
                "resource_stage_path": "resources/DesignSystem",
                "source_byte_count": 8872,
                "source_count": 4,
                "source_digest": "00d6773590819770061d4dc9e23adedc1f5ed39962a321475093289edf28ca9b",
                "source_root": "BlockzillaPackage/Sources/DesignSystem",
                "sources": list(DESIGN_SOURCES),
            },
            "onboarding_uikit_core": {
                "excluded_source_count": 11,
                "excluded_source_digest": "a6279791d2fd29f777c7a3f3cc00dfa3e51619af9a29a60ec84fed649ed288c3",
                "excluded_sources": list(ONBOARDING_EXCLUSIONS),
                "input_stage_path": "inputs/focus",
                "module_name": "OnboardingUIKitCore",
                "source_byte_count": 25924,
                "source_count": 10,
                "source_digest": "d26e2983c5de94bd187b100b21713cf0f84e9e2dff551628377e0dc9b91a32cb",
                "source_root": "BlockzillaPackage/Sources/Onboarding",
                "sources": list(ONBOARDING_SOURCES),
            },
            "package_manifest": dict(FOCUS_MANIFEST),
            "workspace_lock": dict(FOCUS_WORKSPACE_LOCK),
            "worktree_prefix": "focus-ios",
        },
        "generated_source": {
            "classification": "generated-build-input",
            "path": ACCESSOR_PATH,
            "purpose": "compile-only DesignSystem Bundle.module contract; runtime discovery unavailable",
            "sha256": ACCESSOR_SHA256,
            "size": len(ACCESSOR_BYTES),
        },
        "openuikit": {
            "commit": OPENUIKIT_COMMIT,
            "input_stage_path": "inputs/openuikit",
            "inventory_byte_count": 8441392,
            "inventory_digest": "7f500c99e43e41836c8db5e40449450710373d45cf8e01bda71791e8b7a3e0a7",
            "inventory_file_count": 299,
            "inventory_roots": list(OPENUIKIT_ROOTS),
            "package_manifest": {
                "path": "Package.swift",
                "sha256": "83222d507a16fa3fb1b93988d67beb5a017b73d790fd47e617da3f213f5bc061",
                "size": 9314,
            },
            "validation_only_symlink_exclusions": [
                dict(item) for item in OPENUIKIT_VALIDATION_EXCLUSIONS
            ],
            "worktree_prefix": ".",
        },
        "schema": 1,
        "snapkit": {
            "commit": SNAPKIT_COMMIT,
            "excluded_source": dict(SNAPKIT_EXCLUSION),
            "included_source_byte_count": 121457,
            "included_source_count": 36,
            "included_source_digest": "e9c16679de0d7f0e6cda4a8f296f2c173bb1bdc1d11303e1c5a0f2d9459a6b54",
            "included_sources": list(SNAPKIT_SOURCES),
            "input_stage_path": "inputs/snapkit",
            "source_root": "Sources",
            "workspace_lock_revision": SNAPKIT_COMMIT,
            "worktree_prefix": ".",
        },
    }


def _validate_relative(value: Any, label: str) -> str:
    if not isinstance(value, str) or not value:
        raise ProofError(f"{label} must be a non-empty string")
    if "\\" in value or any(character in value for character in ("\0", "\n", "\r")):
        raise ProofError(f"{label} contains a forbidden character")
    path = PurePosixPath(value)
    if path.is_absolute() or path.as_posix() != value or any(
        part in ("", ".", "..") for part in path.parts
    ):
        raise ProofError(f"{label} is not a normalized relative POSIX path: {value!r}")
    return value


def _read_regular(path: Path, label: str) -> bytes:
    try:
        metadata = path.lstat()
    except OSError as exc:
        raise ProofError(f"cannot stat {label} {path}: {exc}") from exc
    if stat.S_ISLNK(metadata.st_mode):
        raise ProofError(f"{label} must not be a symlink: {path}")
    try:
        descriptor = os.open(path, os.O_RDONLY | NOFOLLOW)
    except OSError as exc:
        raise ProofError(f"cannot open {label} {path}: {exc}") from exc
    try:
        before = os.fstat(descriptor)
        if not stat.S_ISREG(before.st_mode):
            raise ProofError(f"{label} is not a regular file: {path}")
        chunks: list[bytes] = []
        while True:
            chunk = os.read(descriptor, 1024 * 1024)
            if not chunk:
                break
            chunks.append(chunk)
        after = os.fstat(descriptor)
        before_identity = (
            before.st_dev, before.st_ino, before.st_size, before.st_mtime_ns, before.st_ctime_ns,
        )
        after_identity = (
            after.st_dev, after.st_ino, after.st_size, after.st_mtime_ns, after.st_ctime_ns,
        )
        if before_identity != after_identity:
            raise ProofError(f"{label} changed while being read: {path}")
        data = b"".join(chunks)
        if len(data) != after.st_size:
            raise ProofError(f"{label} size changed while being read: {path}")
        return data
    finally:
        os.close(descriptor)


def _validate_policy_shape(policy: Any) -> None:
    expected_keys = {
        "build", "claims", "diagnostic_contract", "focus", "generated_source",
        "openuikit", "schema", "snapkit",
    }
    if not isinstance(policy, dict) or set(policy) != expected_keys:
        raise ProofError("policy has unexpected top-level keys")
    if type(policy["schema"]) is not int or policy["schema"] != 1:
        raise ProofError("policy schema must be integer 1")
    for commit_path in (("focus", "commit"), ("openuikit", "commit"), ("snapkit", "commit")):
        value = policy[commit_path[0]].get(commit_path[1])
        if not isinstance(value, str) or not COMMIT_RE.fullmatch(value):
            raise ProofError(f"{'.'.join(commit_path)} must be a lowercase Git object ID")
    path_values: list[tuple[Any, str]] = [
        (policy["focus"].get("worktree_prefix"), "focus.worktree_prefix"),
        (policy["openuikit"].get("input_stage_path"), "openuikit.input_stage_path"),
        (policy["snapkit"].get("input_stage_path"), "snapkit.input_stage_path"),
        (policy["generated_source"].get("path"), "generated_source.path"),
    ]
    path_values.extend((path, "focus.design_system.sources") for path in policy["focus"]["design_system"]["sources"])
    path_values.extend((path, "focus.design_system.excluded_sources") for path in policy["focus"]["design_system"]["excluded_sources"])
    path_values.extend((path, "focus.onboarding.sources") for path in policy["focus"]["onboarding_uikit_core"]["sources"])
    path_values.extend((path, "focus.onboarding.excluded_sources") for path in policy["focus"]["onboarding_uikit_core"]["excluded_sources"])
    path_values.extend((path, "openuikit.inventory_roots") for path in policy["openuikit"]["inventory_roots"])
    path_values.extend((path, "snapkit.included_sources") for path in policy["snapkit"]["included_sources"])
    for value, label in path_values:
        if value == "." and label.endswith("worktree_prefix"):
            continue
        _validate_relative(value, label)
    for section in (
        policy["focus"]["package_manifest"], policy["focus"]["workspace_lock"],
        policy["openuikit"]["package_manifest"], policy["snapkit"]["excluded_source"],
    ):
        _validate_relative(section["path"], "policy file path")
        if type(section["size"]) is not int or section["size"] < 0:
            raise ProofError("policy file size must be a non-negative integer")
        if not isinstance(section["sha256"], str) or not SHA256_RE.fullmatch(section["sha256"]):
            raise ProofError("policy file hash must be a lowercase SHA-256")


def load_policy(path: Path) -> tuple[bytes, dict[str, Any]]:
    data = _read_regular(path, "Onboarding UIKit proof policy")
    try:
        policy = json.loads(data)
    except json.JSONDecodeError as exc:
        raise ProofError(f"cannot parse Onboarding UIKit proof policy: {exc}") from exc
    _validate_policy_shape(policy)
    if policy != expected_policy():
        raise ProofError("policy does not match the reviewed Focus Onboarding UIKit subject")
    if data != canonical_json(policy):
        raise ProofError("Onboarding UIKit proof policy is not canonically encoded")
    return data, policy


def controlled_environment() -> dict[str, str]:
    # Start from an allowlist, not the caller's process environment. Clang and
    # Swift accept a wide and evolving family of driver-affecting variables
    # (for example CCC_OVERRIDE_OPTIONS and C_INCLUDE_PATH); attempting to
    # enumerate and remove them would make an "exact inputs" proof porous.
    return {
        "GIT_CONFIG_GLOBAL": os.devnull,
        "GIT_CONFIG_NOSYSTEM": "1",
        "GIT_NO_REPLACE_OBJECTS": "1",
        "GIT_OPTIONAL_LOCKS": "0",
        "HOME": "/var/empty",
        "LANG": "C",
        "LC_ALL": "C",
        "PATH": SAFE_PATH,
        "TMPDIR": "/tmp",
    }


def git(repo: Path, *args: str) -> bytes:
    command = [
        "git", "-c", "core.fsmonitor=false", "-c", f"core.hooksPath={os.devnull}",
        "-C", str(repo), *args,
    ]
    try:
        return subprocess.check_output(
            command, stderr=subprocess.STDOUT, env=controlled_environment()
        )
    except (OSError, subprocess.CalledProcessError) as exc:
        output = getattr(exc, "output", b"")
        detail = output.decode("utf-8", errors="replace").strip() if isinstance(output, bytes) else str(output)
        raise ProofError(f"git {' '.join(args)} failed: {detail}") from exc


def _resolve_repository(value: str, label: str) -> Path:
    requested = Path(value)
    if requested.is_symlink():
        raise ProofError(f"{label} repository must not be a symlink: {requested}")
    try:
        resolved = requested.resolve(strict=True)
    except OSError as exc:
        raise ProofError(f"cannot resolve {label} repository: {exc}") from exc
    if not resolved.is_dir():
        raise ProofError(f"{label} repository is not a directory: {resolved}")
    return resolved


def _repository_root_and_prefix(repo: Path, expected_prefix: str, label: str) -> tuple[Path, str]:
    repo = repo.resolve(strict=True)
    raw_root = git(repo, "rev-parse", "--show-toplevel").decode("utf-8", errors="strict").strip()
    root = Path(raw_root).resolve(strict=True)
    try:
        relative = repo.relative_to(root).as_posix()
    except ValueError as exc:
        raise ProofError(f"{label} path is outside its Git worktree") from exc
    actual_prefix = "." if relative == "." else relative
    if actual_prefix != expected_prefix:
        raise ProofError(
            f"{label} worktree prefix changed: expected {expected_prefix!r}, got {actual_prefix!r}"
        )
    return root, actual_prefix


def _git_path(prefix: str, relative: str) -> str:
    return relative if prefix == "." else f"{prefix}/{relative}"


def _reject_symlink_components(repo: Path, relative: str) -> None:
    current = repo
    for part in PurePosixPath(_validate_relative(relative, "subject path")).parts:
        current /= part
        try:
            metadata = current.lstat()
        except OSError as exc:
            raise ProofError(f"cannot stat subject path component {current}: {exc}") from exc
        if stat.S_ISLNK(metadata.st_mode):
            raise ProofError(f"subject path must not contain symlinks: {current}")


def _tree_entries(root: Path, prefix: str, roots: Sequence[str]) -> dict[str, str]:
    full_roots = [_git_path(prefix, _validate_relative(value, "inventory root")) for value in roots]
    raw = git(root, "ls-tree", "-r", "-z", "HEAD", "--", *full_roots)
    entries: dict[str, str] = {}
    prefix_text = "" if prefix == "." else f"{prefix}/"
    for record in (item for item in raw.split(b"\0") if item):
        if b"\t" not in record:
            raise ProofError("malformed Git tree record")
        metadata, raw_path = record.split(b"\t", 1)
        fields = metadata.split(b" ")
        if len(fields) != 3 or fields[0] != b"100644" or fields[1] != b"blob":
            raise ProofError("proof inputs must be regular non-executable Git blobs")
        full = raw_path.decode("utf-8", errors="strict")
        if not full.startswith(prefix_text):
            raise ProofError("Git inventory escaped its repository prefix")
        relative = full[len(prefix_text):]
        if relative in entries:
            raise ProofError(f"duplicate Git inventory path: {relative}")
        entries[relative] = fields[2].decode("ascii", errors="strict")
    return entries


def _attest_paths(
    root: Path,
    repo: Path,
    prefix: str,
    entries: dict[str, str],
    paths: Sequence[str],
    label: str,
) -> tuple[CapturedFile, ...]:
    captured: list[CapturedFile] = []
    for relative in paths:
        _validate_relative(relative, f"{label} path")
        object_id = entries.get(relative)
        if object_id is None:
            raise ProofError(f"{label} is not a committed blob: {relative}")
        _reject_symlink_components(repo, relative)
        data = _read_regular(repo / relative, label)
        committed = git(root, "cat-file", "blob", object_id)
        if data != committed:
            raise ProofError(f"{label} worktree bytes differ from HEAD: {relative}")
        captured.append(CapturedFile(relative, data))
    return tuple(captured)


def _attest_symlink(
    root: Path, repo: Path, prefix: str, expected: dict[str, Any], label: str,
) -> CapturedFile:
    relative = _validate_relative(expected["path"], f"{label} path")
    full = _git_path(prefix, relative)
    raw = git(root, "ls-tree", "-z", "HEAD", "--", full)
    records = [record for record in raw.split(b"\0") if record]
    if len(records) != 1 or b"\t" not in records[0]:
        raise ProofError(f"{label} is not exactly one committed symlink: {relative}")
    metadata, raw_path = records[0].split(b"\t", 1)
    fields = metadata.split(b" ")
    if len(fields) != 3 or fields[0] != b"120000" or fields[1] != b"blob":
        raise ProofError(f"{label} Git mode/type changed: {relative}")
    if raw_path.decode("utf-8", errors="strict") != full:
        raise ProofError(f"{label} Git path changed: {relative}")
    path = repo / relative
    try:
        metadata_on_disk = path.lstat()
        target = os.readlink(path).encode("utf-8", errors="strict")
    except OSError as exc:
        raise ProofError(f"cannot inspect {label} {path}: {exc}") from exc
    if not stat.S_ISLNK(metadata_on_disk.st_mode):
        raise ProofError(f"{label} worktree entry is not a symlink: {relative}")
    committed = git(root, "cat-file", "blob", fields[2].decode("ascii", errors="strict"))
    if target != committed:
        raise ProofError(f"{label} worktree target differs from HEAD: {relative}")
    captured = CapturedFile(relative, target)
    if captured.record() != {key: expected[key] for key in ("path", "sha256", "size")}:
        raise ProofError(f"{label} target bytes changed: {relative}")
    if target.decode("utf-8", errors="strict") != expected["target"]:
        raise ProofError(f"{label} target changed: {relative}")
    return captured


def _assert_digest(
    files: Sequence[CapturedFile], expected_count: int, expected_bytes: int,
    expected_digest: str, label: str,
) -> None:
    if len(files) != expected_count:
        raise ProofError(f"{label} count changed: expected {expected_count}, got {len(files)}")
    byte_count = sum(len(item.data) for item in files)
    if byte_count != expected_bytes:
        raise ProofError(f"{label} byte count changed: expected {expected_bytes}, got {byte_count}")
    actual = records_digest((item.path, item.data) for item in files)
    if actual != expected_digest:
        raise ProofError(f"{label} digest changed: expected {expected_digest}, got {actual}")


def _status_and_commit(root: Path, expected_commit: str, label: str) -> tuple[str, str]:
    commit = git(root, "rev-parse", "HEAD").decode("ascii", errors="strict").strip()
    if commit != expected_commit:
        raise ProofError(f"{label} pin changed: expected {expected_commit}, got {commit}")
    status = git(root, "status", "--porcelain=v1", "-z", "--untracked-files=all", "--ignored=no")
    if status:
        display = status.replace(b"\0", b"\n").decode("utf-8", errors="replace").strip()
        raise ProofError(f"{label} worktree is not clean:\n{display}")
    return commit, sha256(status)


def capture_focus(repo: Path, policy: dict[str, Any]) -> FocusCapture:
    focus_policy = policy["focus"]
    root, prefix = _repository_root_and_prefix(repo, focus_policy["worktree_prefix"], "Focus")
    commit, status_digest = _status_and_commit(root, focus_policy["commit"], "Focus")
    roots = (
        focus_policy["package_manifest"]["path"],
        focus_policy["workspace_lock"]["path"],
        focus_policy["design_system"]["source_root"],
        focus_policy["onboarding_uikit_core"]["source_root"],
    )
    entries = _tree_entries(root, prefix, roots)

    manifest = _attest_paths(root, repo, prefix, entries, [focus_policy["package_manifest"]["path"]], "Focus manifest")[0]
    if manifest.record() != focus_policy["package_manifest"]:
        raise ProofError("Focus package manifest bytes changed")
    lock = _attest_paths(root, repo, prefix, entries, [focus_policy["workspace_lock"]["path"]], "Focus workspace lock")[0]
    if lock.record() != focus_policy["workspace_lock"]:
        raise ProofError("Focus workspace lock bytes changed")
    if SNAPKIT_COMMIT.encode("ascii") not in lock.data:
        raise ProofError("Focus workspace lock no longer contains the pinned SnapKit revision")

    design_policy = focus_policy["design_system"]
    design_all_swift = sorted(
        path for path in entries
        if path.startswith(design_policy["source_root"] + "/") and path.endswith(".swift")
    )
    expected_design = sorted(design_policy["sources"] + design_policy["excluded_sources"])
    if design_all_swift != expected_design:
        raise ProofError("DesignSystem Swift source inventory changed")
    design_sources = _attest_paths(root, repo, prefix, entries, design_policy["sources"], "DesignSystem source")
    design_exclusions = _attest_paths(root, repo, prefix, entries, design_policy["excluded_sources"], "DesignSystem excluded source")
    resource_paths = sorted(
        path for path in entries
        if path.startswith(design_policy["source_root"] + "/") and not path.endswith(".swift")
    )
    design_resources = _attest_paths(root, repo, prefix, entries, resource_paths, "DesignSystem raw resource")
    _assert_digest(design_sources, design_policy["source_count"], design_policy["source_byte_count"], design_policy["source_digest"], "DesignSystem source")
    _assert_digest(design_exclusions, design_policy["excluded_source_count"], 8014, design_policy["excluded_source_digest"], "DesignSystem excluded source")
    _assert_digest(design_resources, design_policy["resource_count"], design_policy["resource_byte_count"], design_policy["resource_digest"], "DesignSystem raw resource")

    onboarding_policy = focus_policy["onboarding_uikit_core"]
    onboarding_all_swift = sorted(
        path for path in entries
        if path.startswith(onboarding_policy["source_root"] + "/") and path.endswith(".swift")
    )
    expected_onboarding = sorted(onboarding_policy["sources"] + onboarding_policy["excluded_sources"])
    if onboarding_all_swift != expected_onboarding:
        raise ProofError("Onboarding Swift source inventory changed")
    onboarding_sources = _attest_paths(root, repo, prefix, entries, onboarding_policy["sources"], "Onboarding UIKit source")
    onboarding_exclusions = _attest_paths(root, repo, prefix, entries, onboarding_policy["excluded_sources"], "Onboarding excluded source")
    _assert_digest(onboarding_sources, onboarding_policy["source_count"], onboarding_policy["source_byte_count"], onboarding_policy["source_digest"], "Onboarding UIKit source")
    _assert_digest(onboarding_exclusions, onboarding_policy["excluded_source_count"], 25271, onboarding_policy["excluded_source_digest"], "Onboarding excluded source")
    return FocusCapture(
        commit, status_digest, manifest, lock, design_sources, design_exclusions,
        design_resources, onboarding_sources, onboarding_exclusions,
    )


def capture_openuikit(repo: Path, policy: dict[str, Any]) -> RepositoryCapture:
    ui_policy = policy["openuikit"]
    root, prefix = _repository_root_and_prefix(repo, ui_policy["worktree_prefix"], "OpenUIKit")
    commit, status_digest = _status_and_commit(root, ui_policy["commit"], "OpenUIKit")
    entries = _tree_entries(root, prefix, ui_policy["inventory_roots"])
    paths = sorted(entries, key=lambda value: value.encode("utf-8"))
    files = _attest_paths(root, repo, prefix, entries, paths, "OpenUIKit staged input")
    _assert_digest(files, ui_policy["inventory_file_count"], ui_policy["inventory_byte_count"], ui_policy["inventory_digest"], "OpenUIKit staged inventory")
    manifest = next((item for item in files if item.path == "Package.swift"), None)
    if manifest is None or manifest.record() != ui_policy["package_manifest"]:
        raise ProofError("OpenUIKit package manifest bytes changed")
    exclusions = tuple(
        _attest_symlink(root, repo, prefix, expected, "OpenUIKit validation-only symlink exclusion")
        for expected in ui_policy["validation_only_symlink_exclusions"]
    )
    return RepositoryCapture("OpenUIKit", commit, status_digest, files, exclusions)


def capture_snapkit(repo: Path, policy: dict[str, Any]) -> RepositoryCapture:
    snap_policy = policy["snapkit"]
    root, prefix = _repository_root_and_prefix(repo, snap_policy["worktree_prefix"], "SnapKit")
    commit, status_digest = _status_and_commit(root, snap_policy["commit"], "SnapKit")
    entries = _tree_entries(root, prefix, [snap_policy["source_root"]])
    all_swift = sorted(path for path in entries if path.endswith(".swift"))
    expected = sorted(snap_policy["included_sources"] + [snap_policy["excluded_source"]["path"]])
    if all_swift != expected:
        raise ProofError("SnapKit Swift source inventory changed")
    files = _attest_paths(root, repo, prefix, entries, snap_policy["included_sources"], "SnapKit source")
    exclusion = _attest_paths(root, repo, prefix, entries, [snap_policy["excluded_source"]["path"]], "SnapKit excluded source")
    _assert_digest(files, snap_policy["included_source_count"], snap_policy["included_source_byte_count"], snap_policy["included_source_digest"], "SnapKit included source")
    if exclusion[0].record() != {
        key: snap_policy["excluded_source"][key] for key in ("path", "sha256", "size")
    }:
        raise ProofError("SnapKit diagnostic-only exclusion bytes changed")
    return RepositoryCapture("SnapKit", commit, status_digest, files, exclusion)


def capture_audit(capture: FocusCapture | RepositoryCapture) -> dict[str, Any]:
    if isinstance(capture, FocusCapture):
        return {
            "commit": capture.commit,
            "design_exclusions": [item.record() for item in capture.design_exclusions],
            "design_resources": [item.record() for item in capture.design_resources],
            "design_sources": [item.record() for item in capture.design_sources],
            "manifest": capture.manifest.record(),
            "onboarding_exclusions": [item.record() for item in capture.onboarding_exclusions],
            "onboarding_sources": [item.record() for item in capture.onboarding_sources],
            "status_sha256": capture.status_sha256,
            "workspace_lock": capture.workspace_lock.record(),
        }
    return {
        "commit": capture.commit,
        "exclusions": [item.record() for item in capture.exclusions],
        "files": [item.record() for item in capture.files],
        "name": capture.name,
        "status_sha256": capture.status_sha256,
    }


def _verify_safe_output_parent(parent: Path) -> None:
    """Reject output locations another unprivileged UID could replace."""
    effective_uid = os.geteuid()
    metadata = parent.stat()
    mode = stat.S_IMODE(metadata.st_mode)
    if metadata.st_uid != effective_uid or mode & 0o077:
        raise ProofError(
            "proof output parent must be owned by the current user and private mode 0700"
        )

    child = parent
    while True:
        if _has_extended_acl(child):
            raise ProofError(f"proof output ancestor carries an extended ACL: {child}")
        container = child.parent
        if container == child:
            break
        container_metadata = container.stat()
        container_mode = stat.S_IMODE(container_metadata.st_mode)
        if container_metadata.st_uid not in (0, effective_uid):
            raise ProofError(
                f"proof output ancestor has an untrusted owner: {container}"
            )
        if container_mode & 0o022:
            sticky = bool(container_metadata.st_mode & stat.S_ISVTX)
            protected_child = child.stat().st_uid == effective_uid
            if not (sticky and protected_child):
                raise ProofError(
                    f"proof output ancestor permits cross-UID replacement: {container}"
                )
        child = container


def _resolve_new_output(value: str, repository_roots: Sequence[Path]) -> Path:
    requested = Path(value)
    if requested.is_symlink() or requested.exists():
        raise ProofError(f"stale proof output already exists: {requested}")
    try:
        parent = requested.parent.resolve(strict=True)
    except OSError as exc:
        raise ProofError(f"cannot resolve proof output parent: {exc}") from exc
    output = parent / requested.name
    _verify_safe_output_parent(parent)
    for root in repository_roots:
        try:
            output.relative_to(root.resolve(strict=True))
        except ValueError:
            continue
        raise ProofError(f"proof output must be outside repository worktrees: {output}")
    return output


def _write_exclusive(path: Path, data: bytes, label: str) -> None:
    path.parent.mkdir(mode=0o755, parents=True, exist_ok=True)
    try:
        descriptor = os.open(path, os.O_WRONLY | os.O_CREAT | os.O_EXCL | NOFOLLOW, 0o644)
    except OSError as exc:
        raise ProofError(f"cannot create {label} {path}: {exc}") from exc
    try:
        view = memoryview(data)
        while view:
            written = os.write(descriptor, view)
            if written <= 0:
                raise ProofError(f"short write while creating {label}: {path}")
            view = view[written:]
        os.fsync(descriptor)
    finally:
        os.close(descriptor)


def _tree_inventory(root: Path, label: str) -> list[str]:
    if root.is_symlink() or not root.is_dir():
        raise ProofError(f"{label} root is missing or not a directory: {root}")
    paths: list[str] = []
    for current, directories, files in os.walk(root, followlinks=False):
        current_path = Path(current)
        for name in directories:
            candidate = current_path / name
            if candidate.is_symlink():
                raise ProofError(f"{label} contains a symlink directory: {candidate}")
        for name in files:
            candidate = current_path / name
            if candidate.is_symlink():
                raise ProofError(f"{label} contains a symlink file: {candidate}")
            paths.append(candidate.relative_to(root).as_posix())
    return sorted(paths, key=lambda value: value.encode("utf-8"))


def stage_files(
    output: Path, files: Sequence[CapturedFile], stage_root: str,
) -> list[dict[str, Any]]:
    _validate_relative(stage_root, "input stage root")
    records: list[dict[str, Any]] = []
    for item in files:
        input_path = f"{stage_root}/{item.path}"
        _write_exclusive(output / input_path, item.data, "staged shipping input")
        records.append(
            {
                "input_path": input_path,
                "repository_path": item.path,
                "sha256": sha256(item.data),
                "size": len(item.data),
            }
        )
    verify_staged_files(output, files, stage_root)
    return records


def verify_staged_files(output: Path, files: Sequence[CapturedFile], stage_root: str) -> None:
    root = output / stage_root
    expected_paths = sorted((item.path for item in files), key=lambda value: value.encode("utf-8"))
    if _tree_inventory(root, f"{stage_root} staged inputs") != expected_paths:
        raise ProofError(f"{stage_root} staged inventory contains an adaptation or unexpected input")
    by_path = {item.path: item for item in files}
    for relative in expected_paths:
        data = _read_regular(root / relative, "staged shipping input")
        if data != by_path[relative].data:
            raise ProofError(f"staged shipping-input bytes changed: {stage_root}/{relative}")


def stage_design_resources(
    output: Path, resources: Sequence[CapturedFile], policy: dict[str, Any],
) -> list[dict[str, Any]]:
    design = policy["focus"]["design_system"]
    source_root = design["source_root"] + "/"
    stage_root = design["resource_stage_path"]
    records: list[dict[str, Any]] = []
    for item in resources:
        if not item.path.startswith(source_root):
            raise ProofError(f"DesignSystem resource escaped source root: {item.path}")
        relative = item.path[len(source_root):]
        stage_path = f"{stage_root}/{relative}"
        _write_exclusive(output / stage_path, item.data, "staged DesignSystem raw resource")
        records.append(
            {
                "path": stage_path,
                "repository_path": item.path,
                "sha256": sha256(item.data),
                "size": len(item.data),
            }
        )
    verify_design_resources(output, resources, policy)
    return records


def verify_design_resources(
    output: Path, resources: Sequence[CapturedFile], policy: dict[str, Any],
) -> None:
    design = policy["focus"]["design_system"]
    source_root = design["source_root"] + "/"
    stage_root = design["resource_stage_path"]
    expected: dict[str, bytes] = {}
    for item in resources:
        relative = item.path[len(source_root):]
        expected[relative] = item.data
    if _tree_inventory(output / stage_root, "DesignSystem raw resource stage") != sorted(
        expected, key=lambda value: value.encode("utf-8")
    ):
        raise ProofError("DesignSystem raw resource stage inventory changed")
    for relative, expected_data in expected.items():
        if _read_regular(output / stage_root / relative, "staged DesignSystem raw resource") != expected_data:
            raise ProofError(f"DesignSystem raw resource bytes changed: {relative}")


def write_generated_source(output: Path, policy: dict[str, Any]) -> dict[str, Any]:
    generated = policy["generated_source"]
    if len(ACCESSOR_BYTES) != generated["size"] or sha256(ACCESSOR_BYTES) != generated["sha256"]:
        raise ProofError("compiled-in generated accessor contract changed")
    _write_exclusive(output / generated["path"], ACCESSOR_BYTES, "generated DesignSystem accessor")
    verify_generated_source(output, policy)
    return {
        "classification": generated["classification"],
        "path": generated["path"],
        "purpose": generated["purpose"],
        "sha256": generated["sha256"],
        "size": generated["size"],
    }


def verify_generated_source(output: Path, policy: dict[str, Any]) -> None:
    generated = policy["generated_source"]
    root = output / PurePosixPath(generated["path"]).parent
    expected_name = PurePosixPath(generated["path"]).name
    if _tree_inventory(root, "generated DesignSystem inputs") != [expected_name]:
        raise ProofError("generated input inventory contains an adaptation or unexpected input")
    data = _read_regular(output / generated["path"], "generated DesignSystem accessor")
    if len(data) != generated["size"] or sha256(data) != generated["sha256"] or data != ACCESSOR_BYTES:
        raise ProofError("generated DesignSystem accessor bytes changed")


def _compiler_input_roots(output: Path) -> tuple[Path, ...]:
    return tuple(output / name for name in ("generated", "inputs", "resources"))


def seal_compiler_inputs(output: Path) -> None:
    """Make every staged input tree non-writable before invoking any compiler."""
    for root in _compiler_input_roots(output):
        if root.is_symlink() or not root.is_dir():
            raise ProofError(f"compiler input root is missing or not a directory: {root}")
        for current, directories, files in os.walk(root, topdown=False, followlinks=False):
            current_path = Path(current)
            for name in files:
                candidate = current_path / name
                if candidate.is_symlink() or not candidate.is_file():
                    raise ProofError(f"compiler input is not a regular file: {candidate}")
                candidate.chmod(0o444)
            for name in directories:
                candidate = current_path / name
                if candidate.is_symlink() or not candidate.is_dir():
                    raise ProofError(f"compiler input is not a directory: {candidate}")
                candidate.chmod(0o555)
        root.chmod(0o555)
    verify_compiler_inputs_sealed(output)


def verify_compiler_inputs_sealed(output: Path) -> None:
    output_metadata = output.stat()
    if output_metadata.st_uid != os.geteuid() or stat.S_IMODE(output_metadata.st_mode) != 0o700:
        raise ProofError("proof output root is not private mode 0700")
    if _has_extended_acl(output):
        raise ProofError("proof output root carries an extended ACL")
    for root in _compiler_input_roots(output):
        for current, directories, files in os.walk(root, followlinks=False):
            current_path = Path(current)
            if _has_extended_acl(current_path):
                raise ProofError(f"compiler input directory carries an extended ACL: {current_path}")
            if stat.S_IMODE(current_path.stat().st_mode) & 0o222:
                raise ProofError(f"compiler input directory became writable: {current_path}")
            for name in (*directories, *files):
                candidate = current_path / name
                if candidate.is_symlink():
                    raise ProofError(f"compiler input tree contains a symlink: {candidate}")
                if _has_extended_acl(candidate):
                    raise ProofError(f"compiler input carries an extended ACL: {candidate}")
                if stat.S_IMODE(candidate.stat().st_mode) & 0o222:
                    raise ProofError(f"compiler input became writable: {candidate}")


def _run_output(command: list[str], label: str) -> bytes:
    try:
        return subprocess.check_output(
            command, stderr=subprocess.STDOUT, env=controlled_environment()
        )
    except (OSError, subprocess.CalledProcessError) as exc:
        output = getattr(exc, "output", b"")
        detail = output.decode("utf-8", errors="replace").strip() if isinstance(output, bytes) else str(output)
        raise ProofError(f"{label} failed: {detail}") from exc


def _discover_executable(name: str) -> tuple[str, str, int, str]:
    raw = _run_output([SYSTEM_XCRUN, "--find", name], f"Apple {name} discovery")
    try:
        launcher = Path(raw.decode("utf-8", errors="strict").strip())
    except UnicodeDecodeError as exc:
        raise ProofError(f"Apple {name} discovery emitted non-UTF-8 output") from exc
    if not launcher.is_absolute():
        raise ProofError(f"Apple {name} launcher must be an absolute path: {launcher}")
    try:
        resolved = launcher.resolve(strict=True)
    except OSError as exc:
        raise ProofError(f"cannot resolve Apple {name} executable: {exc}") from exc
    data = _read_regular(resolved, f"Apple {name} executable")
    return str(launcher), str(resolved), len(data), sha256(data)


def _apple_toolchain() -> AppleToolchain:
    if sys.platform != "darwin":
        raise ProofError("the exact proof requires macOS and the Apple Swift toolchain")
    xcrun = Path(SYSTEM_XCRUN)
    if xcrun.is_symlink():
        raise ProofError(f"system xcrun must not be a symlink: {xcrun}")
    xcrun_data = _read_regular(xcrun, "system xcrun")
    swift = _discover_executable("swift")
    swiftc = _discover_executable("swiftc")
    sdk_raw = _run_output([SYSTEM_XCRUN, "--show-sdk-path", "--sdk", "macosx"], "macOS SDK discovery")
    sdk = Path(sdk_raw.decode("utf-8", errors="strict").strip())
    if not sdk.is_absolute():
        raise ProofError(f"macOS SDK must be an absolute directory path: {sdk}")
    try:
        sdk = sdk.resolve(strict=True)
    except OSError as exc:
        raise ProofError(f"cannot resolve macOS SDK: {exc}") from exc
    if not sdk.is_dir():
        raise ProofError(f"macOS SDK is not a directory: {sdk}")
    settings = _read_regular(sdk / "SDKSettings.json", "macOS SDK settings")
    swift_version = _run_output([swift[0], "--version"], "Apple swift version query")
    swiftc_version = _run_output([swiftc[0], "--version"], "Apple swiftc version query")
    return AppleToolchain(
        SYSTEM_XCRUN, len(xcrun_data), sha256(xcrun_data),
        swift[0], swift[1], swift[2], swift[3],
        swiftc[0], swiftc[1], swiftc[2], swiftc[3],
        str(sdk), len(settings), sha256(settings), swift_version, swiftc_version,
    )


def _run_logged(command: list[str], log: Path, label: str) -> None:
    try:
        with log.open("xb") as stream:
            result = subprocess.run(
                command, stdout=stream, stderr=subprocess.STDOUT,
                env=controlled_environment(), check=False,
            )
    except OSError as exc:
        raise ProofError(f"cannot run {label}: {exc}") from exc
    if result.returncode != 0:
        raise ProofError(f"{label} failed with exit status {result.returncode}; see {log}")


def _openuikit_command(
    toolchain: AppleToolchain, output: Path, policy: dict[str, Any],
) -> list[str]:
    stage = output / policy["openuikit"]["input_stage_path"]
    scratch = output / "build" / "openuikit"
    return [
        toolchain.swift_launcher_path,
        "build",
        "--quiet",
        "--package-path", str(stage),
        "--scratch-path", str(scratch),
        "--configuration", "release",
        "--target", policy["build"]["openuikit_swiftpm_target"],
        "--triple", policy["build"]["swiftpm_triple"],
        "--sdk", toolchain.sdk_path,
    ]


def _module_search_and_clang_arguments(output: Path, policy: dict[str, Any]) -> list[str]:
    release = output / "build" / "openuikit" / f"{policy['build']['swiftpm_triple']}" / "release"
    staged_ui = output / policy["openuikit"]["input_stage_path"]
    return [
        "-I", str(release / "Modules"),
        "-Xcc", f"-fmodule-map-file={release / 'CSTBTrueType.build/module.modulemap'}",
        "-Xcc", "-I", "-Xcc", str(staged_ui / "Sources/CSTBTrueType/include"),
        "-Xcc", f"-fmodule-map-file={release / 'CPortableIO.build/module.modulemap'}",
        "-Xcc", "-I", "-Xcc", str(staged_ui / "Sources/CPortableIO/include"),
        "-Xcc", f"-fmodule-map-file={staged_ui / 'Sources/CQuartz/include/module.modulemap'}",
        "-Xcc", "-I", "-Xcc", str(staged_ui / "Sources/CQuartz/include"),
    ]


def _direct_command(
    toolchain: AppleToolchain, output: Path, policy: dict[str, Any],
    module_name: str, source_paths: Sequence[Path],
) -> list[str]:
    return [
        toolchain.swiftc_launcher_path,
        "-emit-module",
        "-emit-module-path", str(output / "modules" / f"{module_name}.swiftmodule"),
        "-wmo",
        "-parse-as-library",
        "-swift-version", policy["build"]["swift_language_version"],
        "-sdk", toolchain.sdk_path,
        "-target", policy["build"]["target"],
        "-module-name", module_name,
        "-I", str(output / "modules"),
        *_module_search_and_clang_arguments(output, policy),
        *(str(path) for path in source_paths),
    ]


def _verify_all_stages(
    output: Path, focus: FocusCapture, openuikit: RepositoryCapture,
    snapkit: RepositoryCapture, policy: dict[str, Any],
) -> None:
    verify_compiler_inputs_sealed(output)
    verify_staged_files(output, openuikit.files, policy["openuikit"]["input_stage_path"])
    verify_staged_files(output, snapkit.files, policy["snapkit"]["input_stage_path"])
    focus_sources = (*focus.design_sources, *focus.onboarding_sources)
    verify_staged_files(output, focus_sources, policy["focus"]["design_system"]["input_stage_path"])
    verify_design_resources(output, focus.design_resources, policy)
    verify_generated_source(output, policy)


def _module_outputs(root: Path, module_names: Sequence[str], output_prefix: str) -> list[dict[str, Any]]:
    expected_names = sorted(
        (f"{module}{suffix}" for module in module_names for suffix in MODULE_SUFFIXES),
        key=lambda value: value.encode("utf-8"),
    )
    if _tree_inventory(root, f"{output_prefix} module outputs") != expected_names:
        raise ProofError(f"{output_prefix} module output inventory is stale, missing, or untracked")
    records: list[dict[str, Any]] = []
    for name in expected_names:
        data = _read_regular(root / name, f"{output_prefix} module output")
        if not data:
            raise ProofError(f"{output_prefix} module output is empty: {name}")
        records.append(
            {
                "path": f"{output_prefix}/{name}",
                "sha256": sha256(data),
                "size": len(data),
            }
        )
    return records


def _diagnostic_record(
    log: Path, output: Path, toolchain: AppleToolchain,
    module: str, require_empty: bool = False,
) -> tuple[dict[str, Any], str]:
    data = _read_regular(log, f"{module} diagnostic log")
    try:
        text = data.decode("utf-8", errors="strict")
    except UnicodeDecodeError as exc:
        raise ProofError(f"{module} diagnostic log is not UTF-8") from exc
    if any("error: " in line for line in text.splitlines()):
        raise ProofError(f"{module} emitted an error diagnostic; see {log}")
    if require_empty and data:
        raise ProofError(f"{module} emitted unexpected diagnostics; see {log}")
    normalized = text.replace(str(output.resolve()), "$OUTPUT")
    normalized = normalized.replace(toolchain.sdk_path, "$SDK")
    toolchain_root = str(Path(toolchain.swiftc_resolved_path).parents[3])
    normalized = normalized.replace(toolchain_root, "$TOOLCHAIN")
    record = {
        "module": module,
        "normalized_sha256": sha256(normalized.encode("utf-8")),
        "path": log.relative_to(output).as_posix(),
        "sha256": sha256(data),
        "size": len(data),
        "warning_count": len(ANY_WARNING_RE.findall(text)),
    }
    return record, text


def _verify_onboarding_warnings(
    text: str, output: Path, policy: dict[str, Any],
) -> list[dict[str, Any]]:
    staged_root = output / policy["focus"]["onboarding_uikit_core"]["input_stage_path"]
    warnings: list[dict[str, Any]] = []
    for line in text.splitlines():
        match = PRIMARY_WARNING_RE.match(line)
        if match is None:
            continue
        raw_path, raw_line, raw_column, message = match.groups()
        try:
            relative = Path(raw_path).resolve(strict=True).relative_to(staged_root.resolve(strict=True)).as_posix()
        except (OSError, ValueError) as exc:
            raise ProofError(f"Onboarding warning came from outside staged Focus inputs: {raw_path}") from exc
        warnings.append(
            {
                "column": int(raw_column),
                "line": int(raw_line),
                "message": message,
                "path": relative,
            }
        )
    expected = policy["diagnostic_contract"]["onboarding_expected_warnings"]
    if warnings != expected:
        raise ProofError(f"Onboarding warning contract changed: expected {expected!r}, got {warnings!r}")
    if len(ANY_WARNING_RE.findall(text)) != len(expected):
        raise ProofError("Onboarding emitted a warning outside the two reviewed Combine-import diagnostics")
    return warnings


def compile_modules(
    output: Path, focus: FocusCapture, openuikit: RepositoryCapture,
    snapkit: RepositoryCapture, policy: dict[str, Any],
    staged_records: dict[str, list[dict[str, Any]]],
) -> tuple[list[dict[str, Any]], list[dict[str, Any]], list[dict[str, Any]], dict[str, Any]]:
    toolchain = _apple_toolchain()
    diagnostics_root = output / "diagnostics"
    modules_root = output / "modules"
    diagnostics_root.mkdir(mode=0o755)
    modules_root.mkdir(mode=0o755)
    invocations: list[dict[str, Any]] = []
    diagnostics: list[dict[str, Any]] = []

    _verify_all_stages(output, focus, openuikit, snapkit, policy)
    ui_command = _openuikit_command(toolchain, output, policy)
    ui_log = diagnostics_root / "OpenUIKitSwiftPM.log"
    _run_logged(ui_command, ui_log, "staged OpenUIKit UIKit-target build")
    _verify_all_stages(output, focus, openuikit, snapkit, policy)
    ui_diagnostic, _ = _diagnostic_record(ui_log, output, toolchain, "OpenUIKitSwiftPM")
    diagnostics.append(ui_diagnostic)
    ui_release = output / "build" / "openuikit" / policy["build"]["swiftpm_triple"] / "release"
    ui_outputs = _module_outputs(
        ui_release / "Modules", ("OpenCoreGraphics", "OpenUIKit", "UIKit"),
        f"build/openuikit/{policy['build']['swiftpm_triple']}/release/Modules",
    )
    invocations.append(
        {
            "command": ui_command,
            "compiler_inputs": [
                {"classification": "staged-pinned-package-input", **record}
                for record in staged_records["openuikit"]
            ],
            "link_step": False,
            "operation": "SwiftPM target module emission",
            "target": "UIKit",
        }
    )

    direct_specs: list[tuple[str, list[Path], str]] = [
        (
            "SnapKit",
            [output / record["input_path"] for record in staged_records["snapkit"]],
            "unchanged-shipping-source",
        ),
        (
            "DesignSystem",
            [output / record["input_path"] for record in staged_records["design"]]
            + [output / policy["generated_source"]["path"]],
            "unchanged-shipping-source-plus-generated-accessor",
        ),
        (
            "OnboardingUIKitCore",
            [output / record["input_path"] for record in staged_records["onboarding"]],
            "unchanged-shipping-source",
        ),
    ]
    reviewed_warnings: list[dict[str, Any]] = []
    for module_name, paths, classification in direct_specs:
        _verify_all_stages(output, focus, openuikit, snapkit, policy)
        command = _direct_command(toolchain, output, policy, module_name, paths)
        log = diagnostics_root / f"{module_name}.log"
        _run_logged(command, log, f"{module_name} module emission")
        _verify_all_stages(output, focus, openuikit, snapkit, policy)
        diagnostic, text = _diagnostic_record(
            log, output, toolchain, module_name,
            require_empty=module_name in ("SnapKit", "DesignSystem"),
        )
        if module_name == "OnboardingUIKitCore":
            reviewed_warnings = _verify_onboarding_warnings(text, output, policy)
        diagnostics.append(diagnostic)
        compiler_inputs: list[dict[str, Any]] = []
        for path in paths:
            relative = path.relative_to(output).as_posix()
            data = _read_regular(path, f"{module_name} compiler input")
            entry_classification = classification
            if relative == policy["generated_source"]["path"]:
                entry_classification = policy["generated_source"]["classification"]
            compiler_inputs.append(
                {
                    "classification": entry_classification,
                    "path": relative,
                    "sha256": sha256(data),
                    "size": len(data),
                }
            )
        invocations.append(
            {
                "command": command,
                "compiler_inputs": compiler_inputs,
                "link_step": False,
                "module": module_name,
                "operation": "emit-module-only",
            }
        )

    direct_outputs = _module_outputs(modules_root, DIRECT_MODULES, "modules")
    if _apple_toolchain() != toolchain:
        raise ProofError("Apple compiler or macOS SDK identity changed during module emission")
    toolchain_audit = toolchain.audit()
    toolchain_audit["invocations"] = invocations
    return ui_outputs, direct_outputs, diagnostics, {
        "reviewed_onboarding_warnings": reviewed_warnings,
        "toolchain": toolchain_audit,
    }


def prove(
    focus_value: str, openuikit_value: str, snapkit_value: str,
    policy_value: str, output_value: str,
) -> dict[str, Any]:
    focus_repo = _resolve_repository(focus_value, "Focus")
    openuikit_repo = _resolve_repository(openuikit_value, "OpenUIKit")
    snapkit_repo = _resolve_repository(snapkit_value, "SnapKit")
    policy_path = Path(policy_value).resolve(strict=True)
    policy_bytes, policy = load_policy(policy_path)

    before_focus = capture_focus(focus_repo, policy)
    before_ui = capture_openuikit(openuikit_repo, policy)
    before_snapkit = capture_snapkit(snapkit_repo, policy)
    repository_roots = tuple(
        Path(git(repo, "rev-parse", "--show-toplevel").decode("utf-8", errors="strict").strip()).resolve(strict=True)
        for repo in (focus_repo, openuikit_repo, snapkit_repo)
    )
    output = _resolve_new_output(output_value, repository_roots)
    output.mkdir(mode=0o700)

    ui_records = stage_files(
        output, before_ui.files, policy["openuikit"]["input_stage_path"]
    )
    snapkit_records = stage_files(
        output, before_snapkit.files, policy["snapkit"]["input_stage_path"]
    )
    focus_shipping_sources = (*before_focus.design_sources, *before_focus.onboarding_sources)
    focus_records = stage_files(
        output, focus_shipping_sources, policy["focus"]["design_system"]["input_stage_path"]
    )
    design_paths = {item.path for item in before_focus.design_sources}
    onboarding_paths = {item.path for item in before_focus.onboarding_sources}
    design_records = [record for record in focus_records if record["repository_path"] in design_paths]
    onboarding_records = [record for record in focus_records if record["repository_path"] in onboarding_paths]
    resource_records = stage_design_resources(output, before_focus.design_resources, policy)
    generated_record = write_generated_source(output, policy)
    seal_compiler_inputs(output)
    staged_records = {
        "design": design_records,
        "onboarding": onboarding_records,
        "openuikit": ui_records,
        "snapkit": snapkit_records,
    }
    ui_outputs, direct_outputs, diagnostics, compile_audit = compile_modules(
        output, before_focus, before_ui, before_snapkit, policy, staged_records,
    )
    _verify_all_stages(output, before_focus, before_ui, before_snapkit, policy)

    after_focus = capture_focus(focus_repo, policy)
    after_ui = capture_openuikit(openuikit_repo, policy)
    after_snapkit = capture_snapkit(snapkit_repo, policy)
    if before_focus.identity() != after_focus.identity():
        raise ProofError("Focus Onboarding/DesignSystem subject changed during module emission")
    if before_ui.identity() != after_ui.identity():
        raise ProofError("OpenUIKit subject changed during module emission")
    if before_snapkit.identity() != after_snapkit.identity():
        raise ProofError("SnapKit subject changed during module emission")
    if _read_regular(policy_path, "closing Onboarding UIKit policy") != policy_bytes:
        raise ProofError("Onboarding UIKit proof policy changed during module emission")

    audit = {
        "build": policy["build"],
        "claims": policy["claims"],
        "compiler_input_isolation": {
            "proof_root_mode": "0700",
            "staged_directory_mode": "0555",
            "staged_file_mode": "0444",
            "verification": "before and after every compiler invocation",
        },
        "diagnostic_contract": {
            **policy["diagnostic_contract"],
            "reviewed_onboarding_warnings": compile_audit["reviewed_onboarding_warnings"],
        },
        "diagnostics": diagnostics,
        "focus": capture_audit(after_focus),
        "generated_build_inputs": [generated_record],
        "module_outputs": [*ui_outputs, *direct_outputs],
        "openuikit": capture_audit(after_ui),
        "policy_sha256": sha256(policy_bytes),
        "raw_resource_stage": {
            "byte_count": sum(record["size"] for record in resource_records),
            "declaration": policy["focus"]["design_system"]["resource_declaration"],
            "file_count": len(resource_records),
            "resource_catalog_compilation_or_decode": False,
            "source_digest": policy["focus"]["design_system"]["resource_digest"],
            "staged_files": resource_records,
        },
        "schema": 1,
        "shipping_source_edits": [],
        "shipping_source_inputs": {
            "design_system": design_records,
            "onboarding_uikit_core": onboarding_records,
            "openuikit_package": ui_records,
            "snapkit": snapkit_records,
        },
        "snapkit": capture_audit(after_snapkit),
        "source_exclusions": {
            "design_system_preview_only": [item.record() for item in after_focus.design_exclusions],
            "onboarding_swiftui_and_preview": [item.record() for item in after_focus.onboarding_exclusions],
            "snapkit_diagnostic_only": [
                {**item.record(), "reason": policy["snapkit"]["excluded_source"]["reason"]}
                for item in after_snapkit.exclusions
            ],
        },
        "toolchain": compile_audit["toolchain"],
    }
    audit_path = output / "onboarding-uikit-audit.json"
    _write_exclusive(audit_path, canonical_json(audit), "Onboarding UIKit audit")
    print(
        "ONBOARDING UIKIT PROOF OK: "
        f"{len(onboarding_records)} unchanged Onboarding sources, "
        f"{len(design_records)} DesignSystem sources, {len(snapkit_records)} SnapKit sources, "
        f"{len(ui_records)} OpenUIKit package inputs, "
        f"{len(compile_audit['reviewed_onboarding_warnings'])} reviewed warnings; "
        "Apple modules emitted, no link/run"
    )
    print(f"  audit: {audit_path}")
    return audit


def main(argv: Sequence[str]) -> int:
    if len(argv) != 6:
        print(
            "usage: onboarding_uikit_proof.py FOCUS_REPO OPENUIKIT_REPO "
            "SNAPKIT_REPO POLICY_JSON OUTPUT_DIR",
            file=sys.stderr,
        )
        return 2
    try:
        prove(argv[1], argv[2], argv[3], argv[4], argv[5])
    except ProofError as exc:
        print(f"REFUSED: {exc}", file=sys.stderr)
        return 1
    return 0


if __name__ == "__main__":
    raise SystemExit(main(sys.argv))
