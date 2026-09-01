#!/usr/bin/env python3
"""Normalize a packaged platform for the generic application builder.

The application pipeline can consume either the broad portable core package
or the stricter framework-shaped true-iOS SDK.  Both underlying validators
remain authoritative; this module only exposes their shared build contract so
the compiler, linker, bundle materializer, and cold launcher cannot silently
select different platform interpretations.
"""

from __future__ import annotations

import argparse
from pathlib import Path
import sys
from typing import Any

import core_guest_package
import true_ios_platform_package


class ApplicationPlatformError(RuntimeError):
    """A package cannot be selected as exactly one supported platform kind."""


def _markers(root: Path) -> tuple[bool, bool]:
    return (
        (root / "attestation/core-package.json").is_file(),
        (root / "PLATFORM_COMPLETE").is_file(),
    )


def validate(path: Path) -> tuple[Path, dict[str, Any]]:
    """Validate *path* and return one normalized application-build contract."""

    core_marker, true_ios_marker = _markers(path)
    if core_marker == true_ios_marker:
        if core_marker:
            raise ApplicationPlatformError(
                "package ambiguously contains core and true-iOS completion markers"
            )
        raise ApplicationPlatformError(
            "package has neither a core nor a true-iOS completion marker"
        )

    if core_marker:
        root, manifest = core_guest_package.validate(path)
        target = manifest["target"]["triple"]
        paths = dict(manifest["paths"])
        paths["runtime_root"] = paths["guest_root"]
        contract = {
            "kind": "core",
            "target_triple": target,
            "bundle_layout": "macos",
            "contract_file": "attestation/core-package.json",
            "paths": paths,
            "preview": manifest["preview"],
            # Legacy core packages intentionally make the application
            # executable own the one DeveloperToolsSupport definition used
            # by libUIKit. A plugin-free core package owns no such edge.
            "developer_tools_support_linkage": (
                "application-object" if manifest["preview"] else "none"
            ),
            "swift_compile_arguments": manifest["swift_compile_arguments"],
            "executable_link_arguments": manifest["executable_link_arguments"],
            "app_compile_diagnostic_arguments": (
                manifest["preview"]["app_compile_diagnostic_arguments"]
                if manifest["preview"]
                else []
            ),
        }
        return root, contract

    root, metadata = true_ios_platform_package.validate(path)
    contract = {
        "kind": "true-ios",
        "target_triple": metadata["target"],
        "bundle_layout": "ios",
        "contract_file": "PLATFORM_COMPLETE",
        "paths": dict(metadata["paths"]),
        # Preview expansion is deliberately outside the production contract.
        # The packaged compiler-library plugins still serve ordinary macros.
        "preview": None,
        # A true-iOS platform packages DeveloperToolsSupport as a normal
        # framework/dylib. libUIKit's Preview metadata initializer therefore
        # resolves from that dylib, never from an application-owned object.
        "developer_tools_support_linkage": "platform-dylib",
        "swift_compile_arguments": metadata["swift_compile_arguments"],
        "executable_link_arguments": metadata["executable_link_arguments"],
        "app_compile_diagnostic_arguments": [],
    }
    return root, contract


def rooted_swift_compile_arguments(
    root: Path, contract: dict[str, Any]
) -> list[str]:
    values = contract["swift_compile_arguments"]
    if contract["kind"] == "core":
        return core_guest_package.rooted_swift_compile_arguments(root, values)
    return true_ios_platform_package.rooted_compile_arguments(root, values)


def _parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("package_root", type=Path)
    group = parser.add_mutually_exclusive_group()
    group.add_argument("--emit-swift-arguments", action="store_true")
    group.add_argument("--emit-link-arguments", action="store_true")
    group.add_argument("--emit-app-diagnostic-arguments", action="store_true")
    group.add_argument("--emit-summary", action="store_true")
    parser.add_argument("--absolute-package-paths", action="store_true")
    return parser


def main(argv: list[str] | None = None) -> int:
    parser = _parser()
    arguments = parser.parse_args(argv)
    if arguments.absolute_package_paths and not arguments.emit_swift_arguments:
        parser.error("--absolute-package-paths requires --emit-swift-arguments")
    try:
        root, contract = validate(arguments.package_root)
        if arguments.emit_swift_arguments:
            values = contract["swift_compile_arguments"]
            if arguments.absolute_package_paths:
                values = rooted_swift_compile_arguments(root, contract)
            sys.stdout.buffer.write(
                b"".join(value.encode("utf-8") + b"\0" for value in values)
            )
        elif arguments.emit_link_arguments:
            sys.stdout.buffer.write(
                b"".join(
                    value.encode("utf-8") + b"\0"
                    for value in contract["executable_link_arguments"]
                )
            )
        elif arguments.emit_app_diagnostic_arguments:
            sys.stdout.buffer.write(
                b"".join(
                    value.encode("utf-8") + b"\0"
                    for value in contract["app_compile_diagnostic_arguments"]
                )
            )
        else:
            print(
                "APPLICATION_PLATFORM_PACKAGE_OK "
                f"kind={contract['kind']} target={contract['target_triple']} "
                f"layout={contract['bundle_layout']} "
                f"dts={contract['developer_tools_support_linkage']} root={root}"
            )
    except (
        ApplicationPlatformError,
        core_guest_package.CorePackageError,
        true_ios_platform_package.TrueIOSPlatformError,
        OSError,
        KeyError,
        TypeError,
    ) as exc:
        print(f"application-platform-package: {exc}", file=sys.stderr)
        return 1
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
