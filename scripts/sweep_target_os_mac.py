#!/usr/bin/env python3
"""Classify every TARGET_OS_MAC gate in CoreFoundation.

    scripts/sweep_target_os_mac.py <CF_SOURCE_DIR> [--objdir DIR]

THE QUESTION: we are TARGET_OS_MAC by target triple and corelibs by
implementation. corelibs branches on TARGET_OS_MAC meaning "Apple's
CoreFoundation supplies this". It does not. So for every such gate: DOES APPLE'S
BRANCH REFERENCE CODE THAT EXISTS HERE, OR NOT?

`__CFMachPortClass` was the purest instance -- a runtime class table entry for
CFMachPort.c, a file corelibs does not contain. It surfaced as one undefined
symbol at a link. This converts the rest from an open-ended series of surprises
into a list, the same way pre-measuring the init walls turned five round trips
into one.

DEPTH-TRACKED, NOT GREPPED, AND THAT IS THE WHOLE POINT
------------------------------------------------------
Twice in one investigation I read the NEAREST #if and got the wrong enclosing
condition. `_CFThreadSetName` looked guarded by
SWIFT_CORELIBS_FOUNDATION_HAS_THREADS; the real gate was
`#if DEPLOYMENT_RUNTIME_SWIFT` opened 119 lines earlier and closing 537 lines
later -- the entire rest of the file. Grepping for directives would reproduce
that error at scale, in output nobody re-reads. So this tracks a real depth
stack and reports the FULL enclosing chain for every gate.

It is also why the region for each gate is delimited by matching #else/#endif at
the gate's own depth rather than by "the next #endif", which is the same bug in
a different costume.

WHAT "REFERENCES CODE THAT DOES NOT EXIST" MEANS HERE
-----------------------------------------------------
For each Apple-branch region, identifiers are extracted and checked against the
symbols our built objects actually define, plus the identifiers CF's own sources
define anywhere. A name in neither is a candidate: something Apple's branch
expects and we do not have.

This is a CANDIDATE list, not a verdict list. Macro expansion, local variables
and struct fields all produce identifiers, and no static pass distinguishes them
perfectly -- the tool reports what it cannot attribute rather than dropping it,
because a "could not determine" bucket read as noise is exactly what hid the
CFDictionary isa crash for hours.
"""
import os
import re
import subprocess
import sys

IF = re.compile(r"^\s*#\s*(if|ifdef|ifndef)\b(.*)$")
ELIF = re.compile(r"^\s*#\s*elif\b(.*)$")
ELSE = re.compile(r"^\s*#\s*else\b")
ENDIF = re.compile(r"^\s*#\s*endif\b")
# WHAT CREATES A LINK DEPENDENCY, not every word in the region. The first
# version extracted all identifiers and drowned the answer in comment prose
# ("Also", "Backup", "Ideally"), C keywords and CF typedefs -- 83 "unresolved"
# names for one gate, none of them actionable. A findings list nobody can act on
# is the same failure as a "could not determine" bucket read as noise.
#
# A gate is dangerous when it CALLS or TAKES THE ADDRESS OF something that does
# not exist here -- which is exactly what __CFMachPortClass was. So: calls and
# address-of only, after comments are stripped.
CALL = re.compile(r"\b([A-Za-z_]\w{2,})\s*\(")
ADDR = re.compile(r"&\s*([A-Za-z_]\w{2,})\b")
COMMENT = re.compile(r"/\*.*?\*/|//[^\n]*", re.S)
KEYWORDS = {"if","for","while","switch","return","sizeof","defined","do","else",
            "case","break","goto","typedef","struct","union","enum","static",
            "const","void","char","int","long","bool","true","false","NULL",
            "unsigned","signed","float","double","extern","inline","register"}

# TARGET_OS_MAC gates that also admit the platforms we are NOT are not
# interesting: `TARGET_OS_MAC || TARGET_OS_LINUX` is taken by corelibs on Linux
# too, so its contents are portable by construction. Only gates where
# TARGET_OS_MAC is the sole way in can hide Apple-only code.
OTHER_PLATFORMS = ("TARGET_OS_LINUX", "TARGET_OS_BSD", "TARGET_OS_WIN32",
                   "TARGET_OS_WASI", "TARGET_OS_ANDROID", "TARGET_OS_CYGWIN")


def gates(path):
    """Every TARGET_OS_MAC gate, with its full enclosing chain and region."""
    with open(path, errors="replace") as fh:
        lines = fh.readlines()
    stack, found = [], []
    for i, line in enumerate(lines, 1):
        m = IF.match(line)
        if m:
            cond = m.group(2).strip()
            stack.append({"line": i, "cond": cond, "depth": len(stack)})
            if "TARGET_OS_MAC" in cond:
                found.append({"line": i, "cond": cond,
                              "enclosing": [(f["line"], f["cond"])
                                            for f in stack[:-1]],
                              "end": None, "alt": None})
            continue
        if ENDIF.match(line):
            if stack:
                closing = stack.pop()
                for g in found:
                    if g["line"] == closing["line"] and g["end"] is None:
                        g["end"] = i
            continue
        # #else / #elif at the gate's OWN depth ends Apple's branch. Matching by
        # depth rather than by "next #else" is the same discipline as the region
        # delimiting above.
        if (ELSE.match(line) or ELIF.match(line)) and stack:
            cur = stack[-1]
            for g in found:
                if g["line"] == cur["line"] and g["alt"] is None:
                    g["alt"] = i
    return found, lines


def defined_symbols(objdir):
    """Names our built objects actually define. Empty set if unavailable."""
    out = set()
    if not objdir or not os.path.isdir(objdir):
        return out
    for nm in (["llvm-nm-18"], ["llvm-nm"], ["nm"]):
        try:
            objs = [os.path.join(objdir, f) for f in os.listdir(objdir)
                    if f.endswith(".o")]
            if not objs:
                return out
            r = subprocess.run(nm + ["--defined-only"] + objs,
                               capture_output=True, text=True)
            if r.returncode == 0 and r.stdout.strip():
                for ln in r.stdout.splitlines():
                    parts = ln.split()
                    if parts:
                        out.add(parts[-1].lstrip("_"))
                return out
        except (FileNotFoundError, OSError):
            continue
    return out


def main():
    if len(sys.argv) < 2:
        sys.exit(__doc__)
    cf = sys.argv[1]
    objdir = None
    if "--objdir" in sys.argv:
        objdir = sys.argv[sys.argv.index("--objdir") + 1]

    defined = defined_symbols(objdir)
    if not defined:
        print("NOTE: no built objects available, so the 'missing' column is not\n"
              "      computed. Pass --objdir with a built CF to get it. Reporting\n"
              "      gate structure only -- a partial answer stated as partial.\n")

    # Identifiers CF defines anywhere in its own sources, so a name used in an
    # Apple branch and defined in some other CF file is not a gap.
    cf_idents = set()
    srcs = sorted(f for f in os.listdir(cf) if f.endswith((".c", ".h")))
    for fn in srcs:
        with open(os.path.join(cf, fn), errors="replace") as fh:
            for m in re.finditer(r"^\s*(?:CF_(?:PRIVATE|EXPORT|INLINE)\s+)?"
                                 r"(?:static\s+)?[A-Za-z_][\w \*]*?\b(\w+)\s*\(",
                                 fh.read(), re.M):
                cf_idents.add(m.group(1))

    total = mac_only = 0
    rows = []
    for fn in srcs:
        if not fn.endswith(".c"):
            continue
        found, lines = gates(os.path.join(cf, fn))
        for g in found:
            total += 1
            if any(p in g["cond"] for p in OTHER_PLATFORMS):
                continue          # portable by construction -- see note above
            mac_only += 1
            end = g["alt"] or g["end"] or g["line"]
            body = COMMENT.sub(" ", "".join(lines[g["line"]:end - 1]))
            names = set(CALL.findall(body)) | set(ADDR.findall(body))
            names -= KEYWORDS
            unknown = sorted(n for n in names
                             if n not in defined and n not in cf_idents
                             and not n.isupper())
            rows.append((fn, g["line"], end - g["line"], g["cond"],
                         g["enclosing"], unknown))

    print(f"TARGET_OS_MAC gates: {total} total, {mac_only} where TARGET_OS_MAC "
          f"is the SOLE way in\n")
    rows.sort(key=lambda r: -r[2])
    for fn, line, size, cond, enclosing, unknown in rows:
        if not unknown and size < 4:
            continue
        print(f"{fn}:{line}  ({size} lines)  #if {cond[:56]}")
        for el, ec in enclosing:
            print(f"    enclosed by {el}: #if {ec[:52]}")
        if unknown:
            print(f"    unresolved identifiers ({len(unknown)}): "
                  f"{', '.join(unknown[:8])}")
        print()


if __name__ == "__main__":
    main()
