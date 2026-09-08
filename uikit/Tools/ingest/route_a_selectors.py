#!/usr/bin/env python3
"""Opt-in native Linux selector lowering; never edits the imported app in place.

This is a bounded source adapter, not an Objective-C compiler. It resolves
same-file, explicitly @objc instance methods with zero or one parameter and a
Void result. It emits OpenUIKit SelectorDispatching implementations, and refuses
to write a file if any selector or @objc attribute remains unexplained. Audit
coverage is syntax coverage, not a claim that the rest of an app builds.

  python3 Tools/ingest/route_a_selectors.py audit Sources/Blockzilla --report /tmp/a.json
  python3 Tools/ingest/route_a_selectors.py rewrite --route-a Input.swift --output /tmp/Input.swift

Route (b) must keep the original source. The output is a separate generated copy.
"""
from __future__ import annotations

import argparse
from dataclasses import dataclass, field
import hashlib
import json
from pathlib import Path
import re
import sys


def mask_noncode(source: str) -> str:
    """Preserve offsets/newlines while hiding Swift comments and string literals."""
    out = list(source)
    i = 0
    while i < len(source):
        start = i
        if source.startswith("//", i):
            end = source.find("\n", i)
            i = len(source) if end < 0 else end
        elif source.startswith("/*", i):
            depth = 1
            i += 2
            while i < len(source) and depth:
                if source.startswith("/*", i):
                    depth += 1
                    i += 2
                elif source.startswith("*/", i):
                    depth -= 1
                    i += 2
                else:
                    i += 1
            if depth:
                raise ValueError("unterminated block comment")
        else:
            opening = re.match(r'(#+)?("""|")', source[i:])
            if not opening:
                i += 1
                continue
            hashes, quote = opening.group(1) or "", opening.group(2)
            i += len(opening.group())
            terminator = quote + hashes
            while i < len(source) and not source.startswith(terminator, i):
                if source.startswith("\\" + hashes, i):
                    i += 2 + len(hashes)
                else:
                    i += 1
            if i >= len(source):
                raise ValueError("unterminated string literal")
            i += len(terminator)
            # Code inside interpolation needs a real Swift parser. Fail closed
            # if it contains one of the constructs this adapter would rewrite.
            literal = source[start:i]
            if ("\\" + hashes + "(") in literal and re.search(r"#selector\s*\(|@objc\b", literal):
                raise ValueError("selector/objc in string interpolation is unsupported")
        for j in range(start, i):
            if out[j] != "\n":
                out[j] = " "
    return "".join(out)


def pairs(code: str) -> dict[int, int]:
    stack: list[tuple[str, int]] = []
    result: dict[int, int] = {}
    for i, c in enumerate(code):
        if c in "({[":
            stack.append((c, i))
        elif c in ")}]":
            if not stack or stack[-1][0] != {")": "(", "}": "{", "]": "["}[c]:
                raise ValueError("unbalanced Swift delimiters")
            _, start = stack.pop()
            result[start] = i
    if stack:
        raise ValueError("unbalanced Swift delimiters")
    return result


@dataclass
class Owner:
    name: str
    start: int
    opening: int
    closing: int
    header: str
    kind: str
    methods: list[Method] = field(default_factory=list)


@dataclass
class Method:
    owner: Owner
    name: str
    label: str | None
    selector: str
    attribute_start: int
    attribute_end: int

    @property
    def reference(self) -> str:
        return self.name + (f"({self.label}:)" if self.label is not None else "")


def exported_name(name: str, label: str | None, explicit: str | None) -> str:
    if explicit is not None:
        if explicit.count(":") != (label is not None):
            raise ValueError("explicit Objective-C name has wrong arity")
        return explicit
    # MEASURED route-a-selector-wall Apple Swift 6.2.1 Foundation oracle:
    # Tools/ingest/route_a_selector_names.swift: plain() -> plain;
    # changed(_:) -> changed:; toggle(sender:) -> toggleWithSender:.
    # The same oracle also checks notification, gestureRecognizer, enabled,
    # and clipboardString, all named first-label families in Focus. This
    # bounded adapter does not infer multiargument,
    # initializer, getter/setter, override, or ObjC protocol selector names.
    if label is None:
        return name
    if label == "_":
        return name + ":"
    if label not in {"sender", "notification", "gestureRecognizer", "enabled", "clipboardString"}:
        raise ValueError("unmeasured inferred first-argument label; use an explicit @objc selector")
    return name + "With" + label[0].upper() + label[1:] + ":"


def transform(source: str, path: str = "<source>") -> tuple[str, dict]:
    report: dict = {"path": path, "source_sha256": hashlib.sha256(source.encode()).hexdigest(),
                    "selectors": [], "objc_attributes": [], "errors": []}
    try:
        code = mask_noncode(source)
        matching = pairs(code)
    except ValueError as error:
        report["errors"].append(str(error))
        return source, report

    def line(offset: int) -> int:
        return source.count("\n", 0, offset) + 1

    owners: list[Owner] = []
    for match in re.finditer(r"\b(class|extension)\s+([A-Za-z_]\w*)\b([^{}]*)\{", code):
        # 'class func' is not a class declaration.
        if match.group(2) in {"func", "var", "let", "subscript"}:
            continue
        opening = match.end() - 1
        owners.append(Owner(match.group(2), match.start(), opening,
                            matching[opening], match.group(3), match.group(1)))

    def enclosing(offset: int) -> Owner | None:
        candidates = [owner for owner in owners if owner.opening < offset < owner.closing]
        return min(candidates, key=lambda owner: owner.closing - owner.opening) if candidates else None

    def conditional_scopes(offset: int) -> list[int]:
        scopes: list[int] = []
        for directive in re.finditer(r"(?m)^\s*#(if|endif)\b", code[:offset]):
            if directive.group(1) == "if":
                scopes.append(directive.start())
            elif scopes:
                scopes.pop()
        return scopes

    edits: list[tuple[int, int, str]] = []
    for attr in re.finditer(r"@objc(?:Members)?\b(?:\s*\(([^()]*)\))?", code):
        entry = {"line": line(attr.start()), "status": "unsupported"}
        report["objc_attributes"].append(entry)
        if attr.group().startswith("@objcMembers"):
            entry["reason"] = "implicit @objcMembers exposure is unsupported"
            continue
        owner = enclosing(attr.start())
        declaration = re.match(
            r"\s*((?:(?:public|open|internal|fileprivate|private|final|dynamic)\s+)*)"
            r"func\s+([A-Za-z_]\w*)\s*\(", code[attr.end():])
        if owner is None or owner.kind != "class" or declaration is None:
            entry["reason"] = "only instance methods directly declared in a class are supported"
            continue
        if "<" in owner.header or "where" in owner.header:
            entry["reason"] = "generic class requires separate dispatch evidence"
            continue
        if conditional_scopes(attr.start()) != conditional_scopes(owner.opening):
            entry["reason"] = "conditionally declared method requires matching dispatch conditions"
            continue
        # Direct class members only, not nested local functions.
        if any(start > owner.opening and start < attr.start() < end
               for start, end in matching.items() if code[start] == "{" and end < owner.closing):
            entry["reason"] = "nested declaration is unsupported"
            continue
        opening = attr.end() + declaration.end() - 1
        closing = matching[opening]
        params = code[opening + 1:closing].strip()
        tail = re.match(r"\s*(?:->\s*(?:Void|\(\))\s*)?\{", code[closing + 1:])
        if tail is None:
            entry["reason"] = "only synchronous nonthrowing Void methods are supported"
            continue
        label = None
        if params:
            param = re.fullmatch(
                r"([A-Za-z_]\w*)(?:\s+[A-Za-z_]\w*)?\s*:\s*"
                r"([A-Za-z_]\w*(?:\.[A-Za-z_]\w*)*[?!]?)(?:\s*=\s*nil)?", params)
            if param is None:
                entry["reason"] = "only zero arguments or one simply typed sender is supported"
                continue
            label = param.group(1)
        name = declaration.group(2)
        explicit = re.sub(r"\s+", "", attr.group(1)) if attr.group(1) else None
        if explicit and not re.fullmatch(r"[A-Za-z_]\w*:?", explicit):
            entry["reason"] = "unsupported explicit Objective-C selector"
            continue
        try:
            selector = exported_name(name, label, explicit)
        except ValueError as error:
            entry["reason"] = str(error)
            continue
        owner.methods.append(Method(owner, name, label, selector, attr.start(), attr.end()))
        entry.update(status="lowered", method=f"{owner.name}.{name}", selector=selector)
        edits.append((attr.start(), attr.end(), ""))

    used: dict[int, list[Method]] = {}
    for match in re.finditer(r"#selector\s*\(", code):
        start, opening = match.start(), match.end() - 1
        closing = matching[opening]
        expression = re.sub(r"\s+", "", code[opening + 1:closing])
        entry = {"line": line(start), "expression": expression, "status": "unsupported"}
        report["selectors"].append(entry)
        parsed = re.fullmatch(r"(?:(self|Self|[A-Za-z_]\w*)\.)?([A-Za-z_]\w*)(?:\((([A-Za-z_]\w*):)?\))?", expression)
        owner = enclosing(start)
        if parsed is None:
            entry["reason"] = "only a method reference with zero or one label is supported"
            continue
        qualifier, name, _, label = parsed.groups()
        if qualifier and qualifier not in {"self", "Self"}:
            targets = [candidate for candidate in owners if candidate.name == qualifier and candidate.kind == "class"]
        else:
            targets = [owner] if owner else []
        if len(targets) != 1:
            entry["reason"] = "target declaration is absent or ambiguous in this file"
            continue
        target = targets[0]
        candidates = [method for method in target.methods if method.name == name
                      and ("(" not in expression or method.label == label)]
        if len(candidates) != 1:
            entry["reason"] = "no unique supported explicitly @objc method declaration"
            continue
        method = candidates[0]
        # A duplicate dispatch implementation needs inheritance/override analysis.
        target_scopes = [candidate for candidate in owners if candidate.name == target.name]
        if any("SelectorDispatching" in scope.header or
               re.search(r"\bfunc\s+perform\s*\(", code[scope.opening + 1:scope.closing])
               for scope in target_scopes):
            entry["reason"] = "existing selector dispatch requires manual integration"
            continue
        entry.update(status="lowered", selector=method.selector, method=f"{target.name}.{method.reference}")
        edits.append((start, closing + 1, f"Selector.named({json.dumps(method.selector)})"))
        if method not in used.setdefault(target.start, []):
            used[target.start].append(method)

    for owner in owners:
        methods = used.get(owner.start, [])
        if not methods:
            continue
        # The method stays inside its class, so private action methods remain
        # callable. Using an instance-local table also avoids stored static state
        # and Swift concurrency checks on ActionTable's closures.
        entries = "\n".join(f'            .action({json.dumps(m.selector)}, {owner.name}.{m.reference}),' for m in methods)
        witness = f"""
    // Generated by Tools/ingest/route_a_selectors.py for native Linux route (a).
    public func perform(_ selectorName: String, with sender: Any?) -> Bool {{
        let actions: ActionTable<{owner.name}> = [
{entries}
        ]
        return actions.perform(selectorName, on: self, with: sender)
    }}
"""
        edits.append((owner.closing, owner.closing, witness))
        edits.append((owner.opening, owner.opening,
                      (", " if ":" in owner.header else ": ") + "SelectorDispatching "))

    report["counts"] = {
        "selectors": len(report["selectors"]),
        "lowered_selectors": sum(item["status"] == "lowered" for item in report["selectors"]),
        "objc_attributes": len(report["objc_attributes"]),
        "lowered_objc_attributes": sum(item["status"] == "lowered" for item in report["objc_attributes"]),
        "dispatch_classes": len(used),
    }
    report["complete"] = (not report["errors"] and
                          all(item["status"] == "lowered" for item in report["selectors"] + report["objc_attributes"]))
    result = source
    for start, end, replacement in sorted(edits, reverse=True):
        result = result[:start] + replacement + result[end:]
    return result, report


def audit(paths: list[Path]) -> dict:
    files = sorted({file for path in paths for file in (path.rglob("*.swift") if path.is_dir() else [path])})
    reports = [transform(path.read_text(), str(path))[1] for path in files]
    total = {key: sum(report.get("counts", {}).get(key, 0) for report in reports)
             for key in ("selectors", "lowered_selectors", "objc_attributes", "lowered_objc_attributes", "dispatch_classes")}
    total["remaining_selectors"] = total["selectors"] - total["lowered_selectors"]
    total["remaining_objc_attributes"] = total["objc_attributes"] - total["lowered_objc_attributes"]
    total["emittable_selectors"] = sum(report.get("counts", {}).get("selectors", 0)
                                       for report in reports if report.get("complete"))
    total["emittable_objc_attributes"] = sum(report.get("counts", {}).get("objc_attributes", 0)
                                             for report in reports if report.get("complete"))
    total["not_emittable_selectors"] = total["selectors"] - total["emittable_selectors"]
    total["not_emittable_objc_attributes"] = total["objc_attributes"] - total["emittable_objc_attributes"]
    total["emittable_files_with_selectors"] = sum(bool(report.get("counts", {}).get("selectors", 0))
                                                 for report in reports if report.get("complete"))
    return {"schema": 1, "route": "a", "scope": "bounded source adaptation, not whole-app compilation",
            "limitations": ["Lowered counts are candidates; rewrite emits only complete selector/objc files.",
                            "Whole-file emission does not establish whole-file compilation or API compatibility.",
                            "NSObject.perform, KVC, implicit exposure, protocol dispatch and timer/notification runtime bridges are not implemented here.",
                            "Removing an unreferenced @objc attribute does not register that method for dynamic invocation.",
                            "App inheritance and conformance outside each input file require compiler validation."],
            "totals": total, "files": reports}


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    commands = parser.add_subparsers(dest="command", required=True)
    scan = commands.add_parser("audit")
    scan.add_argument("paths", nargs="+", type=Path)
    scan.add_argument("--report", type=Path)
    rewrite = commands.add_parser("rewrite")
    rewrite.add_argument("source", type=Path)
    rewrite.add_argument("--route-a", action="store_true", required=True)
    rewrite.add_argument("--output", type=Path, required=True)
    rewrite.add_argument("--report", type=Path)
    args = parser.parse_args()

    def same_file(first: Path, second: Path) -> bool:
        return first.resolve() == second.resolve() or (first.exists() and second.exists() and first.samefile(second))

    if args.command == "audit":
        if args.report and any(same_file(args.report, source) for path in args.paths
                               for source in (path.rglob("*.swift") if path.is_dir() else [path])):
            parser.error("report must not overwrite an input source")
        report = audit(args.paths)
        success = True
    else:
        if same_file(args.source, args.output):
            parser.error("output must be a separate generated copy; never rewrite route (b) in place")
        if args.report and any(same_file(args.report, path) for path in [args.source, args.output]):
            parser.error("report must be separate from source and output")
        output, report = transform(args.source.read_text(), str(args.source))
        success = report.get("complete", False)
        if success:
            args.output.parent.mkdir(parents=True, exist_ok=True)
            args.output.write_text("// GENERATED: native Linux route (a) selector adapter. Keep original source for route (b).\nimport OpenUIKit\n" + output)
    serialized = json.dumps(report, indent=2) + "\n"
    if args.report:
        args.report.write_text(serialized)
    print(serialized, end="")
    return 0 if success else 2


if __name__ == "__main__":
    sys.exit(main())
