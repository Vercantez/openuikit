#!/usr/bin/env python3
"""SwiftPM's ``Bundle.module`` accessor, as Xcode generates it for iOS apps.

A Swift package target that declares ``resources:`` gets a generated
``resource_bundle_accessor.swift`` and a ``<Package>_<Target>.bundle``.
MEASURED (Xcode 26.1, ``xcodebuild -destination 'generic/platform=iOS
Simulator'`` over a one-target package, 2026-09-23): the accessor Xcode writes
to ``DerivedSources/resource_bundle_accessor.swift`` is byte-identical to
:func:`accessor_source` (golden:
``tests/fixtures/swiftpm-accessor/ResPkg_ResLib.xcode26.1-iphonesimulator.swift``).
It looks for the bundle in ``Bundle.main.resourceURL`` (an app: the guest
app layout stages package bundles there, materialize_application_bundle.py),
then beside the framework holding the module, then beside a command-line
tool, and stops with ``fatalError`` otherwise. The same text type-checks
against the guest Foundation facade unchanged (``import class
Foundation.Bundle`` resolves to the facade's Bundle).

The bundle stem is the package name made a C99 identifier (``Core-Utilities``
-> ``Core_Utilities``), ``_``, and the target's module name.

    python3 swiftpm_resource_accessor.py <bundle-stem> <out.swift>
"""

from __future__ import annotations

import re
import sys
from pathlib import Path

_STEM = re.compile(r"[A-Za-z_][A-Za-z0-9_]*\Z")

_TEMPLATE = '''import class Foundation.Bundle
import class Foundation.ProcessInfo
import struct Foundation.URL

private class BundleFinder {}

extension Foundation.Bundle {
    /// Returns the resource bundle associated with the current Swift module.
    static let module: Bundle = {
        let bundleName = "@STEM@"

        let overrides: [URL]
        #if DEBUG
        // The 'PACKAGE_RESOURCE_BUNDLE_PATH' name is preferred since the expected value is a path. The
        // check for 'PACKAGE_RESOURCE_BUNDLE_URL' will be removed when all clients have switched over.
        // This removal is tracked by rdar://107766372.
        if let override = ProcessInfo.processInfo.environment["PACKAGE_RESOURCE_BUNDLE_PATH"]
                       ?? ProcessInfo.processInfo.environment["PACKAGE_RESOURCE_BUNDLE_URL"] {
            overrides = [URL(fileURLWithPath: override)]
        } else {
            overrides = []
        }
        #else
        overrides = []
        #endif

        let candidates = overrides + [
            // Bundle should be present here when the package is linked into an App.
            Bundle.main.resourceURL,

            // Bundle should be present here when the package is linked into a framework.
            Bundle(for: BundleFinder.self).resourceURL,

            // For command-line tools.
            Bundle.main.bundleURL,
        ]

        for candidate in candidates {
            let bundlePath = candidate?.appendingPathComponent(bundleName + ".bundle")
            if let bundle = bundlePath.flatMap(Bundle.init(url:)) {
                return bundle
            }
        }
        fatalError("unable to find bundle named @STEM@")
    }()
}'''


class AccessorError(ValueError):
    """The bundle name cannot be spelled in the generated Swift source."""


def bundle_stem(package_name: str, module_name: str) -> str:
    """``<c99 package name>_<module>``, SwiftPM's resource bundle stem."""
    package = re.sub(r"[^A-Za-z0-9_]", "_", package_name)
    if package[:1].isdigit():
        package = "_" + package
    stem = f"{package}_{module_name}"
    if _STEM.fullmatch(stem) is None:
        raise AccessorError(f"unsafe SwiftPM resource bundle stem: {stem!r}")
    return stem


def accessor_source(stem: str) -> bytes:
    """The accessor Xcode 26.1 generates for bundle ``<stem>.bundle``."""
    if _STEM.fullmatch(stem) is None:
        raise AccessorError(f"unsafe SwiftPM resource bundle stem: {stem!r}")
    return _TEMPLATE.replace("@STEM@", stem).encode("utf-8")


def main(argv: list[str]) -> int:
    if len(argv) != 3:
        print(__doc__.strip().splitlines()[-1].strip(), file=sys.stderr)
        return 2
    Path(argv[2]).write_bytes(accessor_source(argv[1]))
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv))
