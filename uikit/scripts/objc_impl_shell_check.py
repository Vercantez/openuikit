#!/usr/bin/env python3
"""objc_impl_shell_check.py — keep the two shapes of an `@objc @implementation`
class in sync (docs/agent_reports/objc-impl-chain1.md).

On Darwin (OPENUIKIT_OBJC_IMPLEMENTATION) UIResponder / UIView / UIWindow are
declared in Objective-C and implemented by

    #if OPENUIKIT_OBJC_IMPLEMENTATION
    // objc-impl-shell: open class UIView: UIResponder
    @objc @implementation extension UIView { ... }              (main interface)
    @objc(OpenUIKitInternal) @implementation extension UIView { ... }   (category)
    extension UIView { @objc open ... }                          (Swift-typed overridables)
    #else
    <GENERATED plain-Swift class: the same members in one `open class` body>
    #endif

Swift's `#if` cannot split a declaration's braces, so the plain-Swift shape
(native Linux, the Foundation-hidden guest route) has to be a second copy of
the same member list. This script DERIVES that copy from the Darwin block:
the containers are merged into one class body, `@objc(...)` attributes are
dropped, and member blocks under a nested `#if OPENUIKIT_OBJC_IMPLEMENTATION`
keep only their `#elseif` / `#else` branches. A generated artefact is graded
by regenerating it and comparing bytes:

    python3 scripts/objc_impl_shell_check.py Sources/OpenUIKit/UIResponder.swift ...
    python3 scripts/objc_impl_shell_check.py --fix <files>   # rewrite the #else block

Exit status 1 when any file's #else block differs from the derivation.
"""
import re
import sys

GUARD = "#if OPENUIKIT_OBJC_IMPLEMENTATION"
DIRECTIVE = re.compile(r"^// objc-impl-shell: (open class \w+(?:: \w+)?)\s*$")
HEAD = re.compile(r"^(?:@objc(?:\([^)]*\))? )?(?:@implementation )?extension (\w+) \{$")
OBJC_ATTR = re.compile(r"@objc(?:\([^)]*\))?\s*")
GENERATED_NOTE = ("// GENERATED from the block above by scripts/objc_impl_shell_check.py "
                  "--fix; do not edit by hand.")


def find_blocks(lines):
    """Yield (if_index, else_index, endif_index) for every top-level guard
    block whose first non-comment line is a shell directive."""
    i = 0
    while i < len(lines):
        if lines[i].rstrip() == GUARD and i + 1 < len(lines) and DIRECTIVE.match(lines[i + 1]):
            depth = 0
            else_at = None
            j = i
            while j < len(lines):
                s = lines[j].strip()
                if s.startswith("#if"):
                    depth += 1
                elif s == "#endif":
                    depth -= 1
                    if depth == 0:
                        break
                elif s == "#else" and depth == 1:
                    else_at = j
                j += 1
            if else_at is None or j >= len(lines):
                raise SystemExit(f"malformed shell block at line {i + 1}")
            yield i, else_at, j
            i = j
        i += 1


def derive(darwin):
    """darwin: lines between the guard and its #else (directive first)."""
    m = DIRECTIVE.match(darwin[0])
    head = m.group(1)
    out = ["@preconcurrency @MainActor", head + " {"]
    body = []
    in_container = False
    i = 1
    while i < len(darwin):
        line = darwin[i]
        stripped = line.strip()
        if not in_container:
            if HEAD.match(line):
                in_container = True
            # comments / blanks / attributes between containers describe the
            # container, not a member: dropped.
            i += 1
            continue
        if line == "}":
            in_container = False
            i += 1
            continue
        if stripped == GUARD:
            # Nested Darwin-only member block: drop the #if branch, keep the
            # #elseif/#else branches (unwrapped when only #else remains).
            depth = 0
            branches = []  # (condition or None, lines)
            cur_cond, cur = "__drop__", []
            j = i
            while j < len(darwin):
                t = darwin[j].strip()
                if t.startswith("#if"):
                    depth += 1
                    if depth > 1:
                        cur.append(darwin[j])
                elif t == "#endif":
                    depth -= 1
                    if depth == 0:
                        branches.append((cur_cond, cur))
                        break
                    cur.append(darwin[j])
                elif depth == 1 and t.startswith("#elseif"):
                    branches.append((cur_cond, cur))
                    cur_cond, cur = t[len("#elseif"):].strip(), []
                elif depth == 1 and t == "#else":
                    branches.append((cur_cond, cur))
                    cur_cond, cur = None, []
                else:
                    cur.append(darwin[j])
                j += 1
            kept = [(c, b) for c, b in branches if c != "__drop__"]
            if kept:
                conds = [c for c, _ in kept if c is not None]
                if not conds:
                    body.extend(kept[0][1])
                else:
                    first = True
                    for c, b in kept:
                        if c is None:
                            body.append("#else")
                        else:
                            body.append(("#if " if first else "#elseif ") + c)
                            first = False
                        body.extend(b)
                    body.append("#endif")
            i = j + 1
            continue
        # Ordinary member line: strip Objective-C attributes.
        new = OBJC_ATTR.sub("", line)
        if new.strip() == "" and stripped != "":
            i += 1  # attribute-only line
            continue
        body.append(new.rstrip() if new.strip() else "")
        i += 1
    # collapse runs of blank lines and trailing blanks
    collapsed = []
    for l in body:
        if l == "" and (not collapsed or collapsed[-1] == ""):
            continue
        collapsed.append(l)
    while collapsed and collapsed[-1] == "":
        collapsed.pop()
    return [GENERATED_NOTE] + out + collapsed + ["}"]


def main():
    fix = "--fix" in sys.argv
    files = [a for a in sys.argv[1:] if a != "--fix"]
    bad = 0
    for path in files:
        with open(path) as f:
            lines = f.read().split("\n")
        changed = False
        for if_at, else_at, endif_at in reversed(list(find_blocks(lines))):
            want = derive(lines[if_at + 1:else_at])
            have = lines[else_at + 1:endif_at]
            if want != have:
                bad += 1
                name = DIRECTIVE.match(lines[if_at + 1]).group(1)
                print(f"{path}: plain-Swift shell of `{name}` is out of date "
                      f"({len(have)} lines, derivation {len(want)} lines)")
                if fix:
                    lines[else_at + 1:endif_at] = want
                    changed = True
        if changed:
            with open(path, "w") as f:
                f.write("\n".join(lines))
            print(f"{path}: rewritten")
    if bad and not fix:
        sys.exit(1)
    print("objc_impl_shell_check: " + ("fixed" if fix and bad else "in sync"))


if __name__ == "__main__":
    main()
