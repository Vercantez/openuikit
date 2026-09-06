#!/usr/bin/env python3
"""Load Apple-framework coverage ledgers as SUPPLY.

A framework row counts as supplied ONLY for identifiers whose coverage.tsv
status is exactly `implemented`. `declared`, `deferred`, `unavailable`, and
`not-applicable` are not supply. A coverage.tsv that exists but has zero
implemented rows does not supply the module.

Module names come from `full/<slug>/reference/framework.json` (`module`), not
from the directory slug. Combine and `os` are OpenUIKit package products
(no coverage.tsv); they are listed separately as PRODUCT supply.

    ./ledger_supply.py <full-root> [out.json]
"""
from __future__ import annotations

import csv
import json
import os
import re
import sys
from collections import defaultdict

ALLOWED = {"implemented", "declared", "deferred", "unavailable", "not-applicable"}

# OpenUIKit Package.swift library products that resolve an `import` on the
# guest/Linux RealApp path. Measured in uikit/Package.swift (coreProducts +
# frameworkProducts). UIKit/Foundation are the original port, not "new
# ledger supply"; they stay in this set so MOD can subtract them if a caller
# asks for unsupplied-only. Callers that want the 08-27 MOD denominator
# should not subtract UIKit/Foundation.
PACKAGE_PRODUCTS = {
    "OpenUIKit", "UIKit", "DeveloperToolsSupport", "SwiftUI", "Symbols",
    "OpenCoreGraphics", "Combine", "os", "OpenUIKitC",
    "SafariServices", "MessageUI", "LinkPresentation",
    "StoreKit", "ImageIO", "CoreImage",
    "Glean", "Intents", "IntentsUI", "Onboarding", "Licenses", "DesignSystem",
}

# Guest Foundation types with carried Darwin goldens (guest-app-path.md,
# foundation-oracles.md, guest-trial.md). Still only the types declared in
# files listed by foundation_guest_sources.txt — this set is a documentation
# overlay, not extra supply.
GUEST_ORACLE_FAMILIES = {
    "DateFormatter", "NumberFormatter", "ISO8601DateFormatter",
    "DateComponentsFormatter", "JSONSerialization", "NSRegularExpression",
    "URLSession", "ByteCountFormatter", "UserDefaults", "HTTPCookie",
    "URLComponents",
}


def _read(path):
    try:
        with open(path, encoding="utf-8", errors="ignore") as f:
            return f.read()
    except OSError:
        return ""


def load_coverage_tsv(path):
    """Return {precise: status} for a coverage.tsv. Invalid statuses ignored."""
    out = {}
    with open(path, encoding="utf-8", errors="ignore", newline="") as f:
        rows = csv.DictReader(f, delimiter="\t")
        if not rows.fieldnames or "precise" not in rows.fieldnames or "status" not in rows.fieldnames:
            return out
        for row in rows:
            pid = (row.get("precise") or "").strip()
            status = (row.get("status") or "").strip()
            if pid and status in ALLOWED:
                out[pid] = status
    return out


def implemented_titles(surface_path, implemented_ids):
    """Top-level Swift type names for implemented precise IDs.

    public-surface.tsv `title` is `WKWebView` or `WKWebpagePreferences.ContentMode`.
    We take the first path component so nested types still credit the outer type.
    """
    names = set()
    if not os.path.isfile(surface_path) or not implemented_ids:
        return names
    with open(surface_path, encoding="utf-8", errors="ignore", newline="") as f:
        rows = csv.DictReader(f, delimiter="\t")
        if not rows.fieldnames or "precise" not in rows.fieldnames:
            return names
        title_key = "title" if "title" in rows.fieldnames else None
        path_key = "path" if "path" in rows.fieldnames else None
        kind_key = "kind" if "kind" in rows.fieldnames else None
        for row in rows:
            if row.get("precise") not in implemented_ids:
                continue
            kind = (row.get(kind_key) or "") if kind_key else ""
            # Prefer type-bearing rows; still accept a property's outer type.
            title = (row.get(title_key) or "") if title_key else ""
            pth = (row.get(path_key) or "") if path_key else ""
            token = title or pth
            if not token:
                continue
            top = token.split(".")[0].strip()
            if re.match(r"^[A-Z][A-Za-z0-9_]*$", top):
                names.add(top)
    return names


# Do NOT list `class` as a modifier — `open class Foo` would consume `class`
# as a modifier and then fail to see the type keyword.
DECL_RE = re.compile(
    r"^[ \t]*(?:@[^\n]+[ \t]+)*(?:(?:open|public|package)\s+)+(?:(?:final|indirect)\s+)*"
    r"(?:class|struct|enum|protocol|actor|typealias)\s+([A-Z][A-Za-z0-9_]*)",
    re.M,
)


def types_in_swift_files(paths):
    names = set()
    for p in paths:
        names |= set(DECL_RE.findall(_read(p)))
    return names


def load_guest_foundation(full_root):
    full_root = os.path.abspath(full_root)
    manifest = os.path.join(full_root, "foundation", "foundation_guest_sources.txt")
    files = []
    repo = os.path.dirname(full_root)
    if os.path.isfile(manifest):
        for line in open(manifest):
            line = line.strip()
            if not line or line.startswith("#"):
                continue
            files.append(os.path.join(repo, line))
    return types_in_swift_files(files), files


def load_product_types(uikit_src):
    """Declared types in Combine and os package-product sources."""
    out = {}
    for prod, rel in (("Combine", "Combine"), ("os", "os")):
        d = os.path.join(uikit_src, prod)
        files = []
        if os.path.isdir(d):
            for dp, _, fns in os.walk(d):
                for f in fns:
                    if f.endswith(".swift"):
                        files.append(os.path.join(dp, f))
        out[prod] = sorted(types_in_swift_files(files))
    return out


def load_ledgers(full_root):
    """Enumerate every full/<slug>/coverage.tsv. Print what was enumerated."""
    lanes = []
    missing_json = []
    no_implemented = []
    by_module = {}
    status_totals = defaultdict(int)
    enumerated = []

    for slug in sorted(os.listdir(full_root)):
        lane = os.path.join(full_root, slug)
        cov = os.path.join(lane, "coverage.tsv")
        if not os.path.isfile(cov):
            continue
        enumerated.append(slug)
        fj = os.path.join(lane, "reference", "framework.json")
        module = None
        if os.path.isfile(fj):
            try:
                module = json.load(open(fj)).get("module")
            except (json.JSONDecodeError, OSError):
                module = None
        if not module:
            missing_json.append(slug)
            module = slug
        coverage = load_coverage_tsv(cov)
        by_status = defaultdict(int)
        for st in coverage.values():
            by_status[st] += 1
            status_totals[st] += 1
        implemented_ids = {p for p, st in coverage.items() if st == "implemented"}
        surface = os.path.join(lane, "reference", "public-surface.tsv")
        impl_types = implemented_titles(surface, implemented_ids)
        rec = {
            "slug": slug,
            "module": module,
            "coverage_rows": len(coverage),
            "by_status": dict(by_status),
            "implemented": len(implemented_ids),
            "implemented_types": sorted(impl_types),
        }
        lanes.append(rec)
        # First ledger wins if two slugs share a module name (should not happen).
        by_module.setdefault(module, rec)
        if rec["implemented"] == 0:
            no_implemented.append(module)

    supplied_modules = {m for m, rec in by_module.items() if rec["implemented"] > 0}
    return {
        "enumerated_slugs": enumerated,
        "n_ledgers": len(enumerated),
        "missing_framework_json": missing_json,
        "modules_with_zero_implemented": sorted(no_implemented),
        "supplied_modules": sorted(supplied_modules),
        "package_products": sorted(PACKAGE_PRODUCTS),
        "status_totals": dict(status_totals),
        "lanes": lanes,
        "by_module": by_module,
    }


def is_module_supplied(name, ledgers):
    """True iff this import name is a supplied Apple module or package product.

    Ledger supply is identifier-level at load time; at MODULE granularity a
    module is supplied iff at least one coverage row is `implemented`.
    """
    if name in PACKAGE_PRODUCTS:
        return True
    rec = ledgers["by_module"].get(name)
    return bool(rec and rec["implemented"] > 0)


def main():
    full_root = sys.argv[1]
    outf = sys.argv[2] if len(sys.argv) > 2 else None
    data = load_ledgers(full_root)
    guest_types, gfiles = load_guest_foundation(full_root)
    data["guest_foundation_files"] = len(gfiles)
    data["guest_foundation_types"] = sorted(guest_types)
    uikit_src = os.path.join(os.path.dirname(full_root), "uikit", "Sources")
    data["product_types"] = load_product_types(uikit_src)

    print(f"enumerated coverage.tsv: {data['n_ledgers']}")
    print(f"  missing framework.json: {len(data['missing_framework_json'])} {data['missing_framework_json'][:8]}")
    print(f"  supplied modules (≥1 implemented): {len(data['supplied_modules'])}")
    print(f"  modules with 0 implemented: {len(data['modules_with_zero_implemented'])}")
    print("  status totals:", data["status_totals"])
    print(f"  guest Foundation files {data['guest_foundation_files']} "
          f"types {len(guest_types)}")
    print("  guest types:", ", ".join(sorted(guest_types)[:40]),
          (f"... +{len(guest_types)-40}" if len(guest_types) > 40 else ""))
    print("  Combine product types:", data["product_types"].get("Combine"))
    print("  os product types:", data["product_types"].get("os"))
    if outf:
        dump = {k: v for k, v in data.items() if k != "by_module"}
        json.dump(dump, open(outf, "w"), indent=1)
        print(f"wrote {outf}")


if __name__ == "__main__":
    main()
