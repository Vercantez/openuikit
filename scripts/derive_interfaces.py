#!/usr/bin/env python3
"""Derive Objective-C method declarations from CoreFoundation's own call sites.

    derive_interfaces.py <census-log-dir> <cf-source-dir>

WHY CALL SITES RATHER THAN HEADERS. 65 of the 151 selectors CF messages are
Apple-private SPI with no public declaration anywhere. But CF is the CALLER, and
its dispatch macros carry the full type information at the point of use:

    CF_OBJC_FUNCDISPATCHV(typeID, RETTYPE, (NSClass *)recv, sel:(ArgT)a ...)
                                  ^^^^^^^   ^^^^^^^          ^^^^
                                  return    receiver         parameter

A header is a claim about an ABI; a call site IS the ABI, because it is the code
that has to agree. So for the private half this is a *better* source than a
header would be, not a worse one.

This reads clang's "-Wobjc-method-access" warnings for the file:line of each
unresolved message, then parses the macro at that line. Nothing here consults
Apple's headers: those are used only to VERIFY the public half
(scripts/verify_sigs.py), never to generate.

Emits declarations grouped by class, each citing the call site it came from, and
reports separately on anything it could not derive with confidence — a guessed
signature is the posix_spawnattr_t hazard moved into Objective-C.
"""
import re, sys, os, glob, collections

LOGDIR = sys.argv[1] if len(sys.argv) > 1 else "/root/work/r/log"
CFDIR  = sys.argv[2] if len(sys.argv) > 2 else "/priv/cfsrc"

WARN = re.compile(
    r'^(?P<file>[^:]+):(?P<line>\d+):\d+: warning: '
    r'(?P<kind>instance|class) method \'(?P<sel>[-+][A-Za-z0-9_:]+)\' not found',
    re.M)   # re.M is load-bearing: without it '^' only matches the start of the
            # whole file and finditer silently yields nothing -- 0 call sites
            # parsed, which looks like "no work to do" rather than a broken regex.

# CF_OBJC_FUNCDISPATCHV(typeID, RETTYPE, (NSClass *)recv, message...)
FUNCD = re.compile(
    r'CF_OBJC(?:_RETAINED)?_FUNCDISPATCHV\s*\(\s*(?P<tid>[^,]+),\s*'
    r'(?P<ret>[A-Za-z_][A-Za-z0-9_ \*]*?)\s*,\s*'
    r'\(\s*(?P<cls>NS[A-Za-z]+)\s*\*\s*\)\s*(?P<recv>[A-Za-z_][A-Za-z0-9_]*)\s*,\s*'
    r'(?P<msg>.*)\)\s*;?\s*$')

# CF_OBJC_CALLV((NSClass *)recv, message...)
CALLV = re.compile(
    r'CF_OBJC_CALLV\s*\(\s*\(\s*(?P<cls>NS[A-Za-z]+)\s*\*\s*\)\s*'
    r'(?P<recv>[A-Za-z_][A-Za-z0-9_]*)\s*,\s*(?P<msg>.*?)\)\s*;?\s*$')


def balanced_types(msg):
    """Extract each `(Type)` cast, honouring NESTED parentheses.

    A naive `\(([^)]*)\)` stops at the first ')' and mangles function-pointer
    types like `(void (*)(const void *, void *))` into `(void (*)`. That emitted
    SYNTACTICALLY INVALID declarations, which took the census from 77 to zero --
    strictly worse than not deriving them at all, because a malformed header
    breaks every file rather than leaving one method undeclared.
    """
    types, i = [], 0
    while True:
        j = msg.find(':', i)
        if j < 0:
            break
        k = j + 1
        while k < len(msg) and msg[k].isspace():
            k += 1
        if k >= len(msg) or msg[k] != '(':
            i = j + 1
            continue
        depth, start = 0, k
        while k < len(msg):
            if msg[k] == '(':
                depth += 1
            elif msg[k] == ')':
                depth -= 1
                if depth == 0:
                    break
            k += 1
        if depth != 0:
            return None                                    # unbalanced; refuse
        types.append(msg[start + 1:k])
        i = k + 1
    return types


# Arguments are not always written as (Type)casts. CF passes expressions --
# `range:NSMakeRange(a, b)` -- whose type is knowable from the callee. Inferring
# these is legitimate: the type is determined by CF's own code, not guessed.
EXPR_TYPE = {
    "NSMakeRange": "NSRange",
    "CFRangeMake": "CFRange",
}


def infer_expr_type(msg, part):
    """Type of the argument following `part:` when it is a known call, else None."""
    m = re.search(re.escape(part) + r'\s*:\s*(\w+)\s*\(', msg)
    return EXPR_TYPE.get(m.group(1)) if m else None


def parse_message(msg, selector):
    """Turn `sel:(T)a other:(U)b` into a declaration body using SELECTOR order."""
    parts = [p for p in selector.lstrip('-+').split(':') if p]
    if ':' not in selector:
        return selector.lstrip('-+')                      # zero-argument
    types = balanced_types(msg)
    if types is None:
        return None
    if len(types) < len(parts):
        # Fill gaps from inferable expressions before giving up.
        filled, ti = [], 0
        for part in parts:
            inferred = infer_expr_type(msg, part)
            if inferred:
                filled.append(inferred)
            elif ti < len(types):
                filled.append(types[ti]); ti += 1
            else:
                return None
        types = filled
    body = " ".join(f"{p}:({t.strip()})a{i}" for i, (p, t) in
                    enumerate(zip(parts, types)))
    # Self-check: a declaration we emit must at least have balanced parens.
    # Generating broken syntax is a worse failure than declining to generate.
    if body.count('(') != body.count(')'):
        return None
    return body


def main():
    by_class = collections.defaultdict(dict)   # class -> {decl: [citations]}
    undecided = []
    seen = set()
    src_cache = {}

    for log in sorted(glob.glob(os.path.join(LOGDIR, "*.err"))):
        for m in WARN.finditer(open(log, errors="replace").read()):
            f, ln, sel = m["file"], int(m["line"]), m["sel"]
            if (f, ln, sel) in seen:
                continue
            seen.add((f, ln, sel))
            path = os.path.join(CFDIR, os.path.basename(f))
            if path not in src_cache:
                try:
                    src_cache[path] = open(path, errors="replace").read().splitlines()
                except OSError:
                    src_cache[path] = []
            lines = src_cache[path]
            if not (0 < ln <= len(lines)):
                continue
            # Macro invocations wrap. Join forward until the parens balance, so a
            # multi-line CF_OBJC_FUNCDISPATCHV is seen whole.
            #
            # This mattered more than it looks: with single-line-only parsing,
            # iteration 2 derived just 4 of 50 and 34 were reported as "call site
            # not a recognised dispatch macro". The curve FLATTENED -- which reads
            # as convergence, and was not. A harvest can stop growing for three
            # reasons, not two: the set closed, the build broke, or THE TOOL HIT
            # ITS LIMIT. Only the first is progress.
            text = lines[ln - 1].strip()
            if text.count('(') != text.count(')'):
                joined, k = text, ln
                while k < len(lines) and joined.count('(') != joined.count(')') \
                        and k - ln < 6:
                    joined += " " + lines[k].strip()
                    k += 1
                if joined.count('(') == joined.count(')'):
                    text = joined

            fm = FUNCD.search(text)
            cm = CALLV.search(text)
            cite = f"{os.path.basename(f)}:{ln}"
            if fm:
                body = parse_message(fm["msg"], sel)
                if body:
                    decl = f"{sel[0]} ({fm['ret'].strip()}){body};"
                    by_class[fm["cls"]].setdefault(decl, []).append(cite)
                    continue
                # RECOGNISED but not typeable. Saying "not a recognised dispatch
                # macro" here was FALSE, and it cost an afternoon: it sent me to
                # implement multi-line macro joining, which was never the
                # problem. A diagnostic that names the wrong cause is worse than
                # one that says only "failed" -- it directs the fix.
                undecided.append((cite, fm["cls"], sel,
                                  "FUNCDISPATCHV with untyped argument(s)"))
                continue
            if cm:
                # CALLV has no explicit return type; the caller's context does.
                undecided.append((cite, cm["cls"], sel, "CF_OBJC_CALLV: return type from context"))
                continue
            undecided.append((cite, "?", sel, "call site not a recognised dispatch macro"))

    total = sum(len(d) for d in by_class.values())
    print(f"/* Derived from {len(seen)} call sites: {total} declarations across "
          f"{len(by_class)} classes. */\n")
    for cls in sorted(by_class):
        print(f"@interface {cls} : NSObject")
        for decl, cites in sorted(by_class[cls].items()):
            print(f"    {decl:<70} /* {', '.join(sorted(set(cites))[:3])} */")
        print("@end\n")

    if undecided:
        print(f"/* NOT DERIVED — {len(undecided)}. These need a human, not a guess. */")
        for cite, cls, sel, why in undecided:
            print(f"/*   {cite:<22} {cls:<18} {sel:<34} {why} */")


main()
