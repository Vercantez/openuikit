#!/usr/bin/env python3
"""Arch-keyed inventories the Focus widget/onboarding gates assert.

One source for expected_*_loads, expected_*_inputs, package file lists, and
otool CPU strings. Arm64 tuples are the historical literals (Gate B at
e93727e0). x86_64 load lists apply the operator-evidenced overlay autolink
swap; x86_64 input/package lists start as the arm64 lists (paths already go
through $SYS/$PACKAGE/$FULL which carry FULL_OUT_SUFFIX).

Operator dumps on the x86_64 EC2 box (FULL_OUT_SUFFIX=-x86_64):

  otool -L every packaged dylib / guest:
    build/swiftui-guest-x86_64/package/libOpenUIKit.dylib
    build/swiftui-guest-x86_64/package/libFoundationEssentials.dylib
    build/swiftui-guest-x86_64/package/libOpenCoreGraphics.dylib
    build/swiftui-guest-x86_64/package/libSwiftUI.dylib
    build/swiftui-guest-x86_64/package/libOpenCombine.dylib
    build/swiftui-guest-x86_64/package/libCombine.dylib
    build/swiftui-guest-x86_64/package/libSymbols.dylib
    build/swiftui-guest-x86_64/focus_widget_guest

  link maps (widget gate writes these under audit/):
    build/swiftui-guest-x86_64/audit/libOpenUIKit.link-map
    build/swiftui-guest-x86_64/audit/libFoundationEssentials.link-map
    build/swiftui-guest-x86_64/audit/libOpenCoreGraphics.link-map
    build/swiftui-guest-x86_64/audit/libSwiftUI.link-map
    build/swiftui-guest-x86_64/audit/libOpenCombine.link-map
    build/swiftui-guest-x86_64/audit/libCombine.link-map
    build/swiftui-guest-x86_64/audit/libSymbols.link-map
    build/swiftui-guest-x86_64/audit/focus_widget_guest.link-map

  onboarding link maps:
    build/focus-onboarding-guest-x86_64/audit/libOpenUIKit.link-map
    build/focus-onboarding-guest-x86_64/audit/libFoundationEssentials.link-map
    build/focus-onboarding-guest-x86_64/audit/libOpenCoreGraphics.link-map
    build/focus-onboarding-guest-x86_64/audit/libSwiftUI.link-map
    build/focus-onboarding-guest-x86_64/audit/libOpenCombine.link-map
    build/focus-onboarding-guest-x86_64/audit/libCombine.link-map
    build/focus-onboarding-guest-x86_64/audit/libSymbols.link-map
    build/focus-onboarding-guest-x86_64/audit/libFoundation.link-map
    build/focus-onboarding-guest-x86_64/audit/libWidget.link-map
    build/focus-onboarding-guest-x86_64/audit/libOnboarding.link-map

Keep in lockstep with full/scripts/guest_arch.py for otool CPU. Input templates
use {PACKAGE}/{SYS}/… so the gate binds run paths; tests hash the templates.
"""

from __future__ import annotations

import argparse
import hashlib
import re
import sys

ARCHES = ("arm64", "x86_64")
GATES = ("widget", "onboarding")
KINDS = ("loads", "inputs", "package", "otool-cpu")

# Operator evidence (x86_64 EC2, main e93727e0): the packaged dylib records
# LC_LOAD_DYLIB of libswift_DarwinFoundation1.dylib where arm64 records
# libswift_errno.dylib. Arm64 overlays are the iOS simulator runtime; x86_64
# overlays are Apple's macOS dyld shared cache (scratch/apple-x86-overlays).
# libswift_errno there re-exports _DarwinFoundation1, and the toolchain's
# autolink/-l choice follows the re-export target.
ARM64_OVERLAY_AUTOLINK = "/usr/lib/swift/libswift_errno.dylib"
X86_OVERLAY_AUTOLINK = "/usr/lib/swift/libswift_DarwinFoundation1.dylib"
ARM64_OVERLAY_AUTOLINK_TBD = "{SYS}/usr/lib/swift/libswift_errno.tbd"
X86_OVERLAY_AUTOLINK_TBD = "{SYS}/usr/lib/swift/libswift_DarwinFoundation1.tbd"

BIND_NAMES = (
    "PACKAGE",
    "SYS",
    "MRROOT",
    "FULL",
    "OUT",
    "FE_OUT",
    "FE_COLLECTIONS",
    "FE_OS",
    "FE_CSHIMS",
    "OPENCOMBINE_ARTIFACTS",
    "RELATIVE_TIME_RUNTIME",
)

_PLACEHOLDER = re.compile(r"\{([A-Z][A-Z0-9_]*)\}")


def canonical_text(items: tuple[str, ...]) -> str:
    """Same bytes `printf '%s\\n' item...` feeds into bash $(...) before strip."""
    if not items:
        return ""
    return "\n".join(items) + "\n"


def inventory_sha256(items: tuple[str, ...]) -> str:
    return hashlib.sha256(canonical_text(items).encode("utf-8")).hexdigest()


def macos_overlay_autolink_loads(items: tuple[str, ...], arch: str) -> tuple[str, ...]:
    if arch == "arm64":
        return items
    if arch != "x86_64":
        raise ValueError(f"unsupported arch {arch!r}")
    return tuple(
        X86_OVERLAY_AUTOLINK if item == ARM64_OVERLAY_AUTOLINK else item
        for item in items
    )


def macos_overlay_autolink_inputs(items: tuple[str, ...], arch: str) -> tuple[str, ...]:
    if arch == "arm64":
        return items
    if arch != "x86_64":
        raise ValueError(f"unsupported arch {arch!r}")
    return tuple(
        X86_OVERLAY_AUTOLINK_TBD if item == ARM64_OVERLAY_AUTOLINK_TBD else item
        for item in items
    )


# --- widget LC_LOAD_DYLIB inventories (otool -L, no path binds) ---

WIDGET_LOADS_ARM64: dict[str, tuple[str, ...]] = {
    "openuikit": (
        "@rpath/libOpenUIKit.dylib",
        "@rpath/libFoundationEssentials.dylib",
        "@rpath/libOpenCoreGraphics.dylib",
        "/usr/lib/swift/libswiftCore.dylib",
        "/usr/lib/libswiftcompat.dylib",
        "/usr/lib/libSystem.B.dylib",
        "/usr/lib/libobjc.A.dylib",
        "/usr/lib/libquartz.dylib",
        "/usr/lib/swift/libswift_Concurrency.dylib",
        "/usr/lib/swift/libswiftObjectiveC.dylib",
        "/usr/lib/swift/libswift_errno.dylib",
    ),
    "foundationessentials": (
        "@rpath/libFoundationEssentials.dylib",
        "/usr/lib/swift/libswiftCore.dylib",
        "/usr/lib/libswiftcompat.dylib",
        "/usr/lib/libSystem.B.dylib",
        "/usr/lib/swift/libswiftDarwin.dylib",
        "/usr/lib/swift/libswift_StringProcessing.dylib",
        "/usr/lib/swift/libswiftSynchronization.dylib",
        "/usr/lib/libobjc.A.dylib",
        "/usr/lib/swift/libswift_errno.dylib",
    ),
    "opencoregraphics": (
        "@rpath/libOpenCoreGraphics.dylib",
        "/usr/lib/swift/libswiftCore.dylib",
        "/usr/lib/libswiftcompat.dylib",
        "/usr/lib/libSystem.B.dylib",
        "/usr/lib/libquartz.dylib",
        "/usr/lib/libobjc.A.dylib",
    ),
    "swiftui": (
        "@rpath/libSwiftUI.dylib",
        "@rpath/libOpenUIKit.dylib",
        "@rpath/libOpenCoreGraphics.dylib",
        "@rpath/libCombine.dylib",
        "@rpath/libOpenCombine.dylib",
        "@rpath/libSymbols.dylib",
        "@rpath/libFoundationEssentials.dylib",
        "/usr/lib/swift/libswiftCore.dylib",
        "/usr/lib/libswiftcompat.dylib",
        "/usr/lib/libSystem.B.dylib",
        "/usr/lib/libobjc.A.dylib",
        "/usr/lib/libquartz.dylib",
        "/usr/lib/swift/libswift_Concurrency.dylib",
        "/usr/lib/swift/libswiftObjectiveC.dylib",
        "/usr/lib/swift/libswiftObservation.dylib",
    ),
    "opencombine": (
        "@rpath/libOpenCombine.dylib",
        "/usr/lib/swift/libswift_Concurrency.dylib",
        "/usr/lib/swift/libswiftCore.dylib",
        "/usr/lib/libc++abi.dylib",
        "/usr/lib/libSystem.B.dylib",
        "/usr/lib/libSystem.real.dylib",
        "/usr/lib/libobjc.A.dylib",
    ),
    "combine": (
        "@rpath/libCombine.dylib",
        "@rpath/libOpenCombine.dylib",
        "@rpath/libOpenCombine.dylib",
        "/usr/lib/swift/libswiftCore.dylib",
        "/usr/lib/libSystem.B.dylib",
    ),
    "symbols": (
        "@rpath/libSymbols.dylib",
        "/usr/lib/swift/libswiftCore.dylib",
        "/usr/lib/libswiftcompat.dylib",
        "/usr/lib/libSystem.B.dylib",
    ),
    "guest": (
        "@rpath/libSwiftUI.dylib",
        "@rpath/libOpenUIKit.dylib",
        "@rpath/libFoundationEssentials.dylib",
        "@rpath/libOpenCoreGraphics.dylib",
        "@rpath/libSymbols.dylib",
        "/usr/lib/swift/libswiftCore.dylib",
        "/usr/lib/libswiftcompat.dylib",
        "/usr/lib/libSystem.B.dylib",
        "/usr/lib/libobjc.A.dylib",
        "/usr/lib/libquartz.dylib",
        "/usr/lib/swift/libswiftObjectiveC.dylib",
    ),
}

# --- widget link-map Object-files inventories ---

WIDGET_INPUTS_ARM64: dict[str, tuple[str, ...]] = {
    "openuikit": (
        "linker synthesized",
        "{PACKAGE}/libFoundationEssentials.dylib",
        "{PACKAGE}/libOpenCoreGraphics.dylib",
        "{SYS}/usr/lib/swift/libswiftCore.tbd",
        "{SYS}/usr/lib/libSystem.tbd",
        "{SYS}/usr/lib/libobjc.tbd",
        "{MRROOT}/darwin/usr/lib/libquartz.dylib",
        "{MRROOT}/darwin/usr/lib/libSystem.B.dylib",
        "{FULL}/openuikit.o",
        "{FULL}/cportableio.o",
        "{FULL}/cstbtruetype.o",
        "{FULL}/hostclock.o",
        "{FULL}/swiftcorepatch.o",
        "{SYS}/usr/lib/swift/libswift_Concurrency.tbd",
        "{SYS}/usr/lib/swift/libswiftObjectiveC.tbd",
    ),
    "foundationessentials": (
        "linker synthesized",
        "{SYS}/usr/lib/swift/libswiftCore.tbd",
        "{MRROOT}/darwin/usr/lib/libswiftcompat.dylib",
        "{SYS}/usr/lib/libSystem.tbd",
        "{MRROOT}/darwin/usr/lib/libSystem.B.dylib",
        "{FE_OUT}/FoundationEssentials.o",
        "{FE_COLLECTIONS}/InternalCollectionsUtilities.o",
        "{FE_COLLECTIONS}/OrderedCollections.o",
        "{FE_COLLECTIONS}/_RopeModule.o",
        "{FE_OS}/os.o",
        "{FE_CSHIMS}/platform_shims.o",
        "{FE_CSHIMS}/string_shims.o",
        "{FE_CSHIMS}/uuid.o",
        "{FE_OUT}/fm_unimplemented.o",
        "{FE_OUT}/uuid_compat.o",
        "{FULL}/swiftcorepatch.o",
        "{SYS}/usr/lib/swift/libswiftDarwin.tbd",
        "{SYS}/usr/lib/swift/libswift_StringProcessing.tbd",
        "{SYS}/usr/lib/swift/libswiftSynchronization.tbd",
        "{SYS}/usr/lib/libobjc.tbd",
    ),
    "opencoregraphics": (
        "linker synthesized",
        "{SYS}/usr/lib/swift/libswiftCore.tbd",
        "{SYS}/usr/lib/libSystem.tbd",
        "{MRROOT}/darwin/usr/lib/libquartz.dylib",
        "{MRROOT}/darwin/usr/lib/libSystem.B.dylib",
        "{FULL}/opencoregraphics.o",
        "{SYS}/usr/lib/libobjc.tbd",
    ),
    "swiftui": (
        "linker synthesized",
        "{PACKAGE}/libOpenUIKit.dylib",
        "{PACKAGE}/libOpenCoreGraphics.dylib",
        "{PACKAGE}/libCombine.dylib",
        "{PACKAGE}/libSymbols.dylib",
        "{PACKAGE}/libFoundationEssentials.dylib",
        "{SYS}/usr/lib/swift/libswiftCore.tbd",
        "{SYS}/usr/lib/libSystem.tbd",
        "{SYS}/usr/lib/libobjc.tbd",
        "{MRROOT}/darwin/usr/lib/libSystem.B.dylib",
        "{OUT}/swiftui.o",
        "{SYS}/usr/lib/swift/libswift_Concurrency.tbd",
        "{SYS}/usr/lib/swift/libswiftObjectiveC.tbd",
        "{SYS}/usr/lib/swift/libswiftObservation.tbd",
    ),
    "opencombine": (
        "linker synthesized",
        "{OPENCOMBINE_ARTIFACTS}/OpenCombine.o",
        "{OUT}/copencombinehelpers.o",
        "{SYS}/usr/lib/swift/libswift_Concurrency.tbd",
        "{SYS}/usr/lib/swift/libswiftCore.tbd",
        "{MRROOT}/darwin/usr/lib/libc++abi.dylib",
        "{SYS}/usr/lib/libSystem.tbd",
        "{SYS}/usr/lib/libobjc.tbd",
    ),
    "combine": (
        "linker synthesized",
        "{OUT}/combine.o",
        "{SYS}/usr/lib/libSystem.tbd",
    ),
    "symbols": (
        "linker synthesized",
        "{OUT}/symbols.o",
        "{SYS}/usr/lib/swift/libswiftCore.tbd",
        "{SYS}/usr/lib/libSystem.tbd",
    ),
    "guest": (
        "linker synthesized",
        "{PACKAGE}/libSwiftUI.dylib",
        "{PACKAGE}/libOpenUIKit.dylib",
        "{PACKAGE}/libFoundationEssentials.dylib",
        "{PACKAGE}/libOpenCoreGraphics.dylib",
        "{SYS}/usr/lib/swift/libswiftCore.tbd",
        "{SYS}/usr/lib/libSystem.tbd",
        "{SYS}/usr/lib/libobjc.tbd",
        "{MRROOT}/darwin/usr/lib/libSystem.B.dylib",
        "{OUT}/guest-main.o",
        "{OUT}/focuswidget.o",
        "{SYS}/usr/lib/swift/libswiftObjectiveC.tbd",
    ),
}

# --- onboarding link-map Object-files inventories ---

ONBOARDING_INPUTS_ARM64: dict[str, tuple[str, ...]] = {
    "openuikit": (
        "linker synthesized",
        "{PACKAGE}/libFoundationEssentials.dylib",
        "{PACKAGE}/libOpenCoreGraphics.dylib",
        "{SYS}/usr/lib/swift/libswiftCore.tbd",
        "{SYS}/usr/lib/swift/libswiftObjectiveC.tbd",
        "{SYS}/usr/lib/libSystem.tbd",
        "{SYS}/usr/lib/libobjc.tbd",
        "{MRROOT}/darwin/usr/lib/libquartz.dylib",
        "{MRROOT}/darwin/usr/lib/libSystem.B.dylib",
        "{FULL}/openuikit.o",
        "{FULL}/cportableio.o",
        "{FULL}/cstbtruetype.o",
        "{FULL}/hostclock.o",
        "{FULL}/swiftcorepatch.o",
        "{SYS}/usr/lib/swift/libswift_Concurrency.tbd",
    ),
    "foundationessentials": (
        "linker synthesized",
        "{SYS}/usr/lib/swift/libswiftCore.tbd",
        "{MRROOT}/darwin/usr/lib/libswiftcompat.dylib",
        "{SYS}/usr/lib/libSystem.tbd",
        "{MRROOT}/darwin/usr/lib/libSystem.B.dylib",
        "{FE_OUT}/FoundationEssentials.o",
        "{FE_COLLECTIONS}/InternalCollectionsUtilities.o",
        "{FE_COLLECTIONS}/OrderedCollections.o",
        "{FE_COLLECTIONS}/_RopeModule.o",
        "{FE_OS}/os.o",
        "{FE_CSHIMS}/platform_shims.o",
        "{FE_CSHIMS}/string_shims.o",
        "{FE_CSHIMS}/uuid.o",
        "{FE_OUT}/fm_unimplemented.o",
        "{FE_OUT}/removefile_compat.o",
        "{FE_OUT}/uuid_compat.o",
        "{FULL}/swiftcorepatch.o",
        "{SYS}/usr/lib/swift/libswiftDarwin.tbd",
        "{SYS}/usr/lib/swift/libswift_StringProcessing.tbd",
        "{SYS}/usr/lib/swift/libswiftSynchronization.tbd",
        "{SYS}/usr/lib/libobjc.tbd",
    ),
    "opencoregraphics": (
        "linker synthesized",
        "{SYS}/usr/lib/swift/libswiftCore.tbd",
        "{SYS}/usr/lib/libSystem.tbd",
        "{MRROOT}/darwin/usr/lib/libquartz.dylib",
        "{MRROOT}/darwin/usr/lib/libSystem.B.dylib",
        "{FULL}/opencoregraphics.o",
        "{SYS}/usr/lib/libobjc.tbd",
    ),
    "swiftui": (
        "linker synthesized",
        "{PACKAGE}/libOpenUIKit.dylib",
        "{PACKAGE}/libOpenCoreGraphics.dylib",
        "{PACKAGE}/libCombine.dylib",
        "{PACKAGE}/libSymbols.dylib",
        "{PACKAGE}/libFoundationEssentials.dylib",
        "{SYS}/usr/lib/swift/libswiftCore.tbd",
        "{SYS}/usr/lib/libSystem.tbd",
        "{SYS}/usr/lib/libobjc.tbd",
        "{MRROOT}/darwin/usr/lib/libSystem.B.dylib",
        "{OUT}/swiftui.o",
        "{SYS}/usr/lib/swift/libswift_Concurrency.tbd",
        "{SYS}/usr/lib/swift/libswiftObjectiveC.tbd",
        "{SYS}/usr/lib/swift/libswiftObservation.tbd",
    ),
    "opencombine": (
        "linker synthesized",
        "{OPENCOMBINE_ARTIFACTS}/OpenCombine.o",
        "{OUT}/copencombinehelpers.o",
        "{SYS}/usr/lib/swift/libswift_Concurrency.tbd",
        "{SYS}/usr/lib/swift/libswiftCore.tbd",
        "{MRROOT}/darwin/usr/lib/libc++abi.dylib",
        "{SYS}/usr/lib/libSystem.tbd",
        "{SYS}/usr/lib/libobjc.tbd",
    ),
    "combine": (
        "linker synthesized",
        "{OUT}/combine.o",
        "{SYS}/usr/lib/libSystem.tbd",
    ),
    "symbols": (
        "linker synthesized",
        "{OUT}/symbols.o",
        "{SYS}/usr/lib/swift/libswiftCore.tbd",
        "{SYS}/usr/lib/libSystem.tbd",
    ),
    "foundation": (
        "linker synthesized",
        "{OUT}/foundation.o",
        "{OUT}/corefoundation.o",
        "{FE_OUT}/FoundationEssentials.o",
        "{FE_COLLECTIONS}/InternalCollectionsUtilities.o",
        "{FE_COLLECTIONS}/OrderedCollections.o",
        "{FE_COLLECTIONS}/_RopeModule.o",
        "{FE_OS}/os.o",
        "{FE_CSHIMS}/platform_shims.o",
        "{FE_CSHIMS}/string_shims.o",
        "{FE_CSHIMS}/uuid.o",
        "{FE_OUT}/fm_unimplemented.o",
        "{FE_OUT}/removefile_compat.o",
        "{FE_OUT}/uuid_compat.o",
        "{SYS}/usr/lib/swift/libswiftCore.tbd",
        "{SYS}/usr/lib/swift/libswiftObjectiveC.tbd",
        "{MRROOT}/darwin/usr/lib/libswiftcompat.dylib",
        "{PACKAGE}/libOpenUIKit.dylib",
        "{PACKAGE}/libCombine.dylib",
        "{PACKAGE}/libOpenCoreGraphics.dylib",
        "{RELATIVE_TIME_RUNTIME}",
        "{SYS}/usr/lib/swift/libswift_StringProcessing.tbd",
        "{SYS}/usr/lib/swift/libswiftSynchronization.tbd",
        "{SYS}/usr/lib/swift/libswiftDarwin.tbd",
        "{SYS}/usr/lib/swift/libswift_Concurrency.tbd",
        "{SYS}/usr/lib/libSystem.tbd",
        "{SYS}/usr/lib/libobjc.tbd",
    ),
    "widget": (
        "linker synthesized",
        "{PACKAGE}/libSwiftUI.dylib",
        "{PACKAGE}/libOpenUIKit.dylib",
        "{PACKAGE}/libFoundationEssentials.dylib",
        "{SYS}/usr/lib/swift/libswiftCore.tbd",
        "{SYS}/usr/lib/libSystem.tbd",
        "{MRROOT}/darwin/usr/lib/libSystem.B.dylib",
        "{OUT}/widget.o",
        "{SYS}/usr/lib/swift/libswiftObjectiveC.tbd",
    ),
    "onboarding": (
        "linker synthesized",
        "{PACKAGE}/libFoundation.dylib",
        "{PACKAGE}/libSwiftUI.dylib",
        "{PACKAGE}/libWidget.dylib",
        "{PACKAGE}/libOpenUIKit.dylib",
        "{PACKAGE}/libCombine.dylib",
        "{SYS}/usr/lib/swift/libswiftCore.tbd",
        "{SYS}/usr/lib/libSystem.tbd",
        "{SYS}/usr/lib/libobjc.tbd",
        "{MRROOT}/darwin/usr/lib/libSystem.B.dylib",
        "{OUT}/onboarding.o",
        "{SYS}/usr/lib/swift/libswiftObjectiveC.tbd",
    ),
}

# --- widget package tree inventories (identical on both arches today) ---

WIDGET_PACKAGE_NAMES_ARM64: tuple[str, ...] = (
    "Combine.abi.json",
    "Combine.swiftdoc",
    "Combine.swiftmodule",
    "Combine.swiftsourceinfo",
    "OpenCombine.swiftdoc",
    "OpenCombine.swiftmodule",
    "OpenCoreGraphics.abi.json",
    "OpenCoreGraphics.swiftdoc",
    "OpenCoreGraphics.swiftmodule",
    "OpenCoreGraphics.swiftsourceinfo",
    "OpenUIKit.abi.json",
    "OpenUIKit.swiftdoc",
    "OpenUIKit.swiftmodule",
    "OpenUIKit.swiftsourceinfo",
    "SwiftUI.abi.json",
    "SwiftUI.swiftdoc",
    "SwiftUI.swiftmodule",
    "SwiftUI.swiftsourceinfo",
    "Symbols.abi.json",
    "Symbols.swiftdoc",
    "Symbols.swiftmodule",
    "Symbols.swiftsourceinfo",
    "libCombine.dylib",
    "libFoundationEssentials.dylib",
    "libOpenCombine.dylib",
    "libOpenCoreGraphics.dylib",
    "libOpenUIKit.dylib",
    "libSwiftUI.dylib",
    "libSymbols.dylib",
)

WIDGET_PACKAGE_DIRECTORIES_ARM64: tuple[str, ...] = (
    "include",
    "include/CHostClock",
    "include/COpenCombineHelpers",
    "include/CPortableIO",
    "include/CQuartz",
    "include/CQuartz/quartz",
    "include/CSTBTrueType",
    "include/_FoundationCShims",
    "modules",
    "modules/Collections",
    "modules/FoundationEssentials",
    "modules/os",
)

WIDGET_FE_MODULE_FILES_ARM64: tuple[str, ...] = (
    "Collections/InternalCollectionsUtilities.abi.json",
    "Collections/InternalCollectionsUtilities.swiftdoc",
    "Collections/InternalCollectionsUtilities.swiftmodule",
    "Collections/InternalCollectionsUtilities.swiftsourceinfo",
    "Collections/OrderedCollections.abi.json",
    "Collections/OrderedCollections.swiftdoc",
    "Collections/OrderedCollections.swiftmodule",
    "Collections/OrderedCollections.swiftsourceinfo",
    "Collections/_RopeModule.abi.json",
    "Collections/_RopeModule.swiftdoc",
    "Collections/_RopeModule.swiftmodule",
    "Collections/_RopeModule.swiftsourceinfo",
    "FoundationEssentials/FoundationEssentials.abi.json",
    "FoundationEssentials/FoundationEssentials.swiftdoc",
    "FoundationEssentials/FoundationEssentials.swiftmodule",
    "FoundationEssentials/FoundationEssentials.swiftsourceinfo",
    "os/os.abi.json",
    "os/os.swiftdoc",
    "os/os.swiftmodule",
    "os/os.swiftsourceinfo",
)

WIDGET_PACKAGE_FILE_COUNT = 101
WIDGET_PACKAGE_DIRECTORY_COUNT = 12

OTOOL_CPU = {
    "arm64": "ARM64",
    "x86_64": "X86_64",
}


def _loads_table(gate: str) -> dict[str, tuple[str, ...]]:
    if gate == "widget":
        return WIDGET_LOADS_ARM64
    raise KeyError(f"gate {gate!r} has no LC_LOAD_DYLIB inventories")


def _inputs_table(gate: str) -> dict[str, tuple[str, ...]]:
    if gate == "widget":
        return WIDGET_INPUTS_ARM64
    if gate == "onboarding":
        return ONBOARDING_INPUTS_ARM64
    raise KeyError(f"unknown gate {gate!r}")


def loads(gate: str, name: str, arch: str) -> tuple[str, ...]:
    return macos_overlay_autolink_loads(_loads_table(gate)[name], arch)


def inputs(gate: str, name: str, arch: str) -> tuple[str, ...]:
    return macos_overlay_autolink_inputs(_inputs_table(gate)[name], arch)


def package_items(name: str, arch: str) -> tuple[str, ...]:
    if arch not in ARCHES:
        raise ValueError(f"unsupported arch {arch!r}")
    # Package topology is the same on both arches today; keep the lookup
    # arch-keyed so a later x86-only file can land without rewriting the gate.
    tables = {
        "names": WIDGET_PACKAGE_NAMES_ARM64,
        "directories": WIDGET_PACKAGE_DIRECTORIES_ARM64,
        "fe_module_files": WIDGET_FE_MODULE_FILES_ARM64,
    }
    try:
        return tables[name]
    except KeyError as exc:
        raise KeyError(f"unknown package inventory {name!r}") from exc


def package_scalar(name: str, arch: str) -> str:
    if arch not in ARCHES:
        raise ValueError(f"unsupported arch {arch!r}")
    scalars = {
        "file_count": str(WIDGET_PACKAGE_FILE_COUNT),
        "directory_count": str(WIDGET_PACKAGE_DIRECTORY_COUNT),
    }
    try:
        return scalars[name]
    except KeyError as exc:
        raise KeyError(f"unknown package scalar {name!r}") from exc


def otool_cpu(arch: str) -> str:
    try:
        return OTOOL_CPU[arch]
    except KeyError as exc:
        raise ValueError(f"unsupported arch {arch!r}") from exc


def expand(items: tuple[str, ...], binds: dict[str, str]) -> tuple[str, ...]:
    expanded = []
    for item in items:
        def repl(match: re.Match[str]) -> str:
            key = match.group(1)
            if key not in binds:
                raise ValueError(f"unbound inventory placeholder {{{key}}} in {item!r}")
            return binds[key]

        expanded.append(_PLACEHOLDER.sub(repl, item))
    leftover = [item for item in expanded if _PLACEHOLDER.search(item)]
    if leftover:
        raise ValueError(f"unexpanded inventory placeholders: {leftover}")
    return tuple(expanded)


def parse_binds(raw: list[str]) -> dict[str, str]:
    binds: dict[str, str] = {}
    for item in raw:
        if "=" not in item:
            raise ValueError(f"bind must be KEY=VALUE, got {item!r}")
        key, value = item.split("=", 1)
        binds[key] = value
    return binds


def emit(arch: str, gate: str, kind: str, name: str, binds: dict[str, str]) -> str:
    if kind == "otool-cpu":
        return otool_cpu(arch) + "\n"
    if kind == "package":
        if name in ("file_count", "directory_count"):
            return package_scalar(name, arch) + "\n"
        return canonical_text(package_items(name, arch))
    if kind == "loads":
        return canonical_text(loads(gate, name, arch))
    if kind == "inputs":
        return canonical_text(expand(inputs(gate, name, arch), binds))
    raise ValueError(f"unknown kind {kind!r}")


def check_names(gate: str, kind: str) -> tuple[str, ...]:
    if kind == "loads":
        return tuple(sorted(_loads_table(gate)))
    if kind == "inputs":
        return tuple(sorted(_inputs_table(gate)))
    if kind == "package":
        if gate != "widget":
            raise KeyError(f"gate {gate!r} has no package inventories")
        return (
            "directory_count",
            "directories",
            "fe_module_files",
            "file_count",
            "names",
        )
    if kind == "otool-cpu":
        return ("otool-cpu",)
    raise KeyError(f"unknown kind {kind!r}")


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--arch", required=True, choices=ARCHES)
    parser.add_argument("--gate", required=True, choices=GATES)
    parser.add_argument("--kind", required=True, choices=KINDS)
    parser.add_argument("--name", default="")
    parser.add_argument("--bind", action="append", default=[], metavar="KEY=VALUE")
    args = parser.parse_args(argv)
    name = args.name
    if args.kind != "otool-cpu" and not name:
        parser.error("--name is required unless --kind otool-cpu")
    try:
        sys.stdout.write(
            emit(args.arch, args.gate, args.kind, name, parse_binds(args.bind))
        )
    except (KeyError, ValueError) as exc:
        print(f"guest_gate_inventories: {exc}", file=sys.stderr)
        return 2
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
