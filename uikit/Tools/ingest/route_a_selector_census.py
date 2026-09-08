#!/usr/bin/env python3
"""Lexical Focus selector inventory; all conditional branches, no compile claim.

Run from uikit/. Comments and string text are masked (string interpolation is
code). Class inheritance is resolved against source declarations and measured
iOS SDK declarations, never inferred from a UI/NS spelling. Unresolved bases
are emitted. Every occurrence keeps its original path, line, and source text.
"""
import argparse
from collections import Counter
import hashlib
import json
from pathlib import Path
import re
import subprocess

SCOPE = {
    "Blockzilla": ["Sources/Blockzilla"],
    "FocusLocalPackages": ["Sources/BlockzillaPackage"],
    "SnapKitVendored": ["Sources/SnapKit"],
    "FuziVendored": ["Sources/Fuzi"],
    "FocusDependencyAdapters": ["Sources/Sentry", "Sources/FocusAppServices", "Sources/RealAppProbe/FocusModules"],
}


STRING_START = re.compile(r'(\#*)("""|")')


def mask_noncode(source):
    """Preserve offsets/newlines; understand nested comments and Swift strings."""
    out = ["\n" if c == "\n" else " " for c in source]
    n = len(source)

    def code(i, interpolation=False):
        depth = 1 if interpolation else 0
        while i < n:
            if source.startswith("//", i):
                end = source.find("\n", i)
                i = n if end < 0 else end
                continue
            if source.startswith("/*", i):
                level, i = 1, i + 2
                while i < n and level:
                    if source.startswith("/*", i):
                        level, i = level + 1, i + 2
                    elif source.startswith("*/", i):
                        level, i = level - 1, i + 2
                    else:
                        i += 1
                continue
            string_start = STRING_START.match(source, i)
            if string_start:
                hashes, quote = string_start.groups()
                end_token, escape = quote + hashes, "\\" + hashes
                i += len(string_start.group())
                while i < n:
                    if source.startswith(escape + "(", i):
                        i = code(i + len(escape) + 1, True)
                    elif source.startswith(escape, i):
                        i += len(escape) + 1
                    elif source.startswith(end_token, i):
                        i += len(end_token)
                        break
                    else:
                        i += 1
                continue
            if interpolation:
                if source[i] == "(":
                    depth += 1
                elif source[i] == ")":
                    depth -= 1
                    if depth == 0:
                        return i + 1
            out[i] = source[i]
            i += 1
        return i

    code(0)
    return "".join(out)


def balanced_end(code, opening):
    level = 0
    for i in range(opening, len(code)):
        if code[i] == "(":
            level += 1
        elif code[i] == ")":
            level -= 1
            if level == 0:
                return i + 1
    raise ValueError(f"unclosed expression at offset {opening}")


def location(path, source, offset):
    line = source.count("\n", 0, offset) + 1
    return {"path": str(path), "line": line, "text": source.splitlines()[line - 1].strip()}


CLASS = re.compile(r'\bclass\s+(\w+)(?:\s*<[^{};]*?>)?\s*(?::\s*([^{};]+))?\s*\{')


def class_declarations(path, source):
    code = mask_noncode(source)
    result = []
    for match in CLASS.finditer(code):
        clause = match.group(2) or ""
        base = re.match(r'([\w.]+)', clause)
        entry = location(path, source, match.start())
        entry.update(name=match.group(1), first_inherited_type=base.group(1).split(".")[-1] if base else None)
        result.append(entry)
    return result


def scan_file(path):
    source = path.read_text()
    code = mask_noncode(source)
    occurrences = []
    patterns = {"selector": r'#selector\s*\(', "objc": r'@objc\b', "objcMembers": r'@objcMembers\b', "perform": r'\bperform\s*\('}
    for kind, pattern in patterns.items():
        for match in re.finditer(pattern, code):
            if kind == "perform" and re.search(r'\bfunc\s*$', code[:match.start()]):
                continue
            entry = location(path, source, match.start())
            entry["kind"] = kind
            if kind in {"selector", "perform"}:
                opening = code.index("(", match.start())
                end = balanced_end(code, opening)
                entry["expression"] = source[opening + 1:end - 1]
            occurrences.append(entry)
    return {"path": str(path), "sha256": hashlib.sha256(source.encode()).hexdigest(),
            "counts": dict(Counter(o["kind"] for o in occurrences)),
            "occurrences": sorted(occurrences, key=lambda o: (o["line"], o["kind"])),
            "classes": class_declarations(path, source)}


def sdk_hierarchy(sdk):
    declarations = {}
    frameworks = sdk / "System/Library/Frameworks"
    for framework in ["UIKit", "Foundation", "SwiftUI"]:
        paths = sorted((frameworks / (framework + ".framework") / "Headers").glob("*.h"))
        paths += sorted((frameworks / (framework + ".framework") / "Modules" / (framework + ".swiftmodule")).glob("arm64-apple-ios-simulator.swiftinterface"))
        for path in paths:
            source = path.read_text()
            relative = path.relative_to(sdk)
            if path.suffix == ".h":
                pattern = r'@interface\s+(\w+)(?:\s*<[^;{}]*?>)?\s*:\s*(\w+)'
                entries = []
                for match in re.finditer(pattern, source):
                    entry = location(relative, source, match.start())
                    entry.update(name=match.group(1), first_inherited_type=match.group(2))
                    entries.append(entry)
            else:
                entries = class_declarations(relative, source)
            for entry in entries:
                declarations.setdefault(entry["name"], entry)
    return declarations


def inventory(roots, sdk):
    files = []
    for scope, paths in roots.items():
        for path in sorted({p for root in paths for p in Path(root).rglob("*.swift")}):
            entry = scan_file(path)
            entry["scope"] = scope
            files.append(entry)
    classes = [entry for f in files for entry in f["classes"]]
    by_name = {}
    for entry in classes:
        by_name.setdefault(entry["name"], []).append(entry)
    sdk_classes = sdk_hierarchy(sdk)
    used_sdk = {}
    for entry in classes:
        base = entry["first_inherited_type"]
        chain, seen = [], {entry["name"]}
        status = "no_inheritance" if not base else "unresolved_base"
        while base:
            chain.append(base)
            if base == "NSObject":
                status = "direct" if len(chain) == 1 else "transitive"
                break
            if base in seen:
                status = "inheritance_cycle_or_name_collision"
                break
            seen.add(base)
            if base in by_name:
                parents = {parent["first_inherited_type"] for parent in by_name[base]}
                if len(parents) > 1:
                    status = "ambiguous_source_name"
                    break
                base = next(iter(parents))
                if not base:
                    status = "source_base_without_inheritance"
            elif base in sdk_classes:
                parent = sdk_classes[base]
                used_sdk[base] = parent
                base = parent["first_inherited_type"]
            else:
                break
        entry["nsobject_status"] = status
        entry["inheritance_chain"] = chain
    for row in files:
        counts = Counter(row["counts"])
        for cls in row["classes"]:
            counts["nsobject_" + cls["nsobject_status"]] += 1
        row["counts"] = dict(counts)
    summaries = {}
    for scope in roots:
        rows = [f for f in files if f["scope"] == scope]
        counts = Counter({"files": len(rows), "selector": 0, "objc": 0, "objcMembers": 0, "perform": 0})
        for row in rows:
            counts.update(row["counts"])
            counts["classes"] += len(row["classes"])
        summaries[scope] = dict(counts)
    return {"schema": 1, "method": "Swift code tokens across all conditional branches; comments and string text excluded; interpolation retained. NSObject ancestry is source + iOS SDK, not Linux runtime identity. Unresolved first inherited names include protocols and are not claimed NSObject subclasses.",
            "sdk": sdk.name, "roots": roots, "summary": summaries,
            "sdk_ancestry_evidence": sorted(used_sdk.values(), key=lambda e: e["name"]), "files": files}


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--out", required=True, type=Path)
    parser.add_argument("--sdk", type=Path)
    args = parser.parse_args()
    sdk = args.sdk or Path(subprocess.check_output(["xcrun", "--sdk", "iphonesimulator", "--show-sdk-path"], text=True).strip())
    data = inventory(SCOPE, sdk)
    args.out.parent.mkdir(parents=True, exist_ok=True)
    args.out.write_text(json.dumps(data, indent=2) + "\n")
    print(json.dumps(data["summary"], indent=2))


if __name__ == "__main__":
    main()
