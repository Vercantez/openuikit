#!/usr/bin/env python3
"""Refuse to call class registration done unless it is COMPLETE.

    scripts/check_registration.py <CF_SOURCE_DIR> [--objdir DIR]

Exit 0 only when every CFTypeID CoreFoundation defines has been adjudicated
AND every type that must be registered actually is. Any gap is an ERROR, never
a warning -- see "why this refuses" below.

WHY THIS EXISTS
---------------
__CFRuntimeObjCClassTable is empty today because corelibs has no
_CFRuntimeBridgeClasses. That emptiness is not neutral: CF_IS_OBJC compares an
instance's _cfisa against __CFISAForTypeID(typeID), and _CFRuntimeCreateInstance
initialises _cfisa FROM THAT SAME SLOT (CFRuntime.c:550). So a CF-created
instance matches its own type's slot whether or not the type is registered --
registered and unregistered types are each self-consistent.

That makes the danger TEMPORAL rather than partial: an instance created before
its type is registered keeps _cfisa = 0 while the slot later holds a class, and
CF then reads that instance as a foreign ObjC object and messages a struct. Any
registration must therefore happen in __CFInitialize, before instances exist.

It also makes one category genuinely inconsistent TODAY, independent of
registration: objects whose _cfisa does not come from the table at all. Constant
CFStrings are exactly that -- with -fconstant-cfstrings the compiler stamps
their isa with &___CFConstantStringClassReference, which CFRuntime.c defines as
a ZEROED int[24]. Nonzero isa, zero slot, so CF_IS_OBJC is already true for
every CFSTR literal, and restoring the dispatch macros armed that. Checked here
as CONSTANT_STRING.

WHAT IT REFUSES ON
------------------
Each check below fails the run rather than printing a warning, because a
half-populated table is the one state nothing else in the build can detect.

  UNADJUDICATED    a typeID CF defines that the table says nothing about
  STALE            a table row naming a typeID CF does not define
  CONTRADICTED     a type CF dispatches on, marked NOT_BRIDGED
  UNREGISTERED     a BRIDGED type with no _CFRuntimeBridgeClasses call
  MISSING_CLASS    a BRIDGED type whose ObjC class is not implemented
  MISPLACED        a registration call outside __CFInitialize (temporal rule)
  CONSTANT_STRING  CFString bridged while CF still defines the constant class

The BRIDGED set is DERIVED, not remembered: a type is bridged iff CF itself
dispatches on it, i.e. it appears as the first argument of CF_IS_OBJC or
CF_OBJC_[RETAINED_]FUNCDISPATCHV. CF's own source is the authority on which
types it is prepared to receive a foreign instance of. The table only has to
agree with that derivation and name a class; it cannot invent membership.

The typeID-free path (CFTYPE_IS_OBJC, behind CFGetTypeID/CFEqual/CFHash) is
deliberately NOT treated as evidence of bridging. It applies to every type, but
it reads __CFGenericTypeID_inline(obj) and compares against that type's own
slot, so unregistered types stay self-consistent under it.
"""
import os
import re
import shlex
import subprocess
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
TABLE = os.path.join(HERE, os.pardir, "docs", "cf-registration.tsv")

# Types CF dispatches on but whose typeID is spelled as a function call at the
# call site. Mapping a spelling to a symbol is not an adjudication -- both names
# denote the same type -- so this stays in the tool.
CALL_SPELLING = re.compile(r"^CF(\w+)GetTypeID$")


def die(msg):
    print(f"check_registration: {msg}", file=sys.stderr)
    sys.exit(2)


def cf_sources(cf):
    return sorted(
        os.path.join(cf, f) for f in os.listdir(cf) if f.endswith(".c")
    )


def declared_type_ids(cf):
    """Every _kCFRuntimeID* CF defines, plus dynamically registered types."""
    hdr = os.path.join(cf, "internalInclude", "CFRuntime_Internal.h")
    if not os.path.exists(hdr):
        die(f"missing {hdr}")
    text = open(hdr).read()
    ids = {}
    for m in re.finditer(r"^\s*(_kCFRuntimeID\w+)\s*=\s*(\d+)", text, re.M):
        ids[m.group(1)] = int(m.group(2))
    if not ids:
        die("parsed ZERO typeIDs from CFRuntime_Internal.h -- refusing to "
            "report an empty set as agreement")

    dynamic = {}
    for path in cf_sources(cf):
        src = open(path, errors="replace").read()
        for m in re.finditer(
            r"(\w+)\s*=\s*_CFRuntimeRegisterClass\s*\(", src
        ):
            dynamic[m.group(1)] = os.path.basename(path)
    return ids, dynamic


def dispatched_types(cf):
    """Types CF messages: first argument of CF_IS_OBJC / CF_OBJC_*FUNCDISPATCHV.

    Returns {typeID symbol: [call sites]} plus the set of call sites whose
    first argument is a local variable, which the tool cannot resolve and must
    surface rather than silently drop.
    """
    pat = re.compile(
        r"\bCF_(?:IS_OBJC|OBJC_FUNCDISPATCHV|OBJC_RETAINED_FUNCDISPATCHV)"
        r"\(\s*([A-Za-z_]\w*)\s*(\(\s*\))?"
    )
    hits, unresolved = {}, []
    for path in cf_sources(cf):
        base = os.path.basename(path)
        for n, line in enumerate(open(path, errors="replace"), 1):
            for m in pat.finditer(line):
                name = m.group(1)
                call = CALL_SPELLING.match(name)
                if call:
                    name = "_kCFRuntimeIDCF" + call.group(1)
                elif not name.startswith("_kCFRuntimeID"):
                    # A local variable -- unresolvable from the call site.
                    unresolved.append(f"{base}:{n} CF_IS_OBJC({name}, ...)")
                    continue
                hits.setdefault(name, []).append(f"{base}:{n}")
    return hits, unresolved


def registration_calls(cf):
    """_CFRuntimeBridgeClasses call sites, and whether each is in __CFInitialize."""
    calls = {}
    for path in cf_sources(cf):
        src = open(path, errors="replace").read()
        # Body of __CFInitialize, for the temporal rule. Brace-matched rather
        # than regex-bounded: a regex stopping at the first '}' would call every
        # call site misplaced and the check would fail for a bogus reason.
        init_lo = init_hi = -1
        m = re.search(r"\bvoid\s+__CFInitialize\s*\([^)]*\)\s*\{", src)
        if m:
            init_lo, depth = m.end() - 1, 0
            for i in range(init_lo, len(src)):
                if src[i] == "{":
                    depth += 1
                elif src[i] == "}":
                    depth -= 1
                    if depth == 0:
                        init_hi = i
                        break
        for c in re.finditer(
            r"_CFRuntimeBridgeClasses\s*\(\s*(\w+)\s*,\s*\"([^\"]+)\"", src
        ):
            inside = init_lo <= c.start() <= init_hi if init_hi > 0 else False
            calls[c.group(1)] = (c.group(2), os.path.basename(path), inside)
    return calls


def defines_constant_string_class(objdir):
    """Does CF still DEFINE ___CFConstantStringClassReference?

    It must import it: the constant-string class has to be a real ObjC class
    supplied by our Foundation, not CF's zeroed int[24]. Measured from the
    object file, because the #if ladder that selects it is not readable by eye.
    """
    obj = os.path.join(objdir, "CFRuntime.o") if objdir else None
    if not obj or not os.path.exists(obj):
        return None  # not measured; reported as such, never as a pass
    nm = shlex.split(os.environ.get("NM", "llvm-nm-18"))
    try:
        r = subprocess.run(
            nm + ["--defined-only", obj], capture_output=True, text=True
        )
    except FileNotFoundError:
        return None
    if r.returncode != 0 or not r.stdout.strip():
        # An nm that fails, or reports nothing, must not read as "clean".
        return None
    out = r.stdout
    return "___CFConstantStringClassReference" in out


def load_table():
    if not os.path.exists(TABLE):
        die(f"missing adjudication table {TABLE}")
    rows = {}
    for n, line in enumerate(open(TABLE), 1):
        line = line.split("#", 1)[0].strip()
        if not line:
            continue
        parts = line.split("\t")
        parts = [p for p in parts if p != ""]
        if len(parts) != 3:
            die(f"{TABLE}:{n}: expected 3 tab-separated fields, got {len(parts)}")
        sym, verdict, detail = parts
        if verdict not in ("BRIDGED", "NOT_BRIDGED"):
            die(f"{TABLE}:{n}: verdict must be BRIDGED or NOT_BRIDGED")
        rows[sym] = (verdict, detail)
    return rows


def implemented_classes():
    """Classes our Foundation actually implements.

    Sourced from a file the Foundation build writes. Absent means none are
    implemented yet -- which is the honest answer today, and makes every
    BRIDGED row fail MISSING_CLASS rather than quietly pass.
    """
    path = os.path.join(HERE, os.pardir, "docs", "cf-census", "ns-classes.txt")
    if not os.path.exists(path):
        return set()
    # Skip comments. Without this the generated file's own header counted as
    # five classes, so the guard reported 10 implemented where 5 exist -- and
    # would have accepted a "class" named `#`. An instrument that reads its
    # input file's prose as data is the same error as reading a declaration as
    # a call; it just happens one layer up.
    out = set()
    for line in open(path):
        line = line.split("#", 1)[0].strip()
        if line:
            out.add(line)
    return out


def main():
    if len(sys.argv) < 2:
        die(__doc__.strip().splitlines()[2].strip())
    cf = sys.argv[1]
    objdir = None
    if "--objdir" in sys.argv:
        objdir = sys.argv[sys.argv.index("--objdir") + 1]
    if not os.path.isdir(cf):
        die(f"not a directory: {cf}")

    ids, dynamic = declared_type_ids(cf)
    dispatched, unresolved = dispatched_types(cf)
    calls = registration_calls(cf)
    table = load_table()
    have_classes = implemented_classes()

    errors = []

    unknown_dispatch = sorted(set(dispatched) - set(ids))
    for sym in unknown_dispatch:
        errors.append(("STALE_DISPATCH", sym,
                       f"dispatched at {dispatched[sym][0]} but CF defines no such typeID"))

    for sym in sorted(ids):
        row = table.get(sym)
        if row is None:
            errors.append(("UNADJUDICATED", sym,
                           "no row in docs/cf-registration.tsv"))
            continue
        verdict, detail = row
        is_dispatched = sym in dispatched
        if verdict == "NOT_BRIDGED" and is_dispatched:
            errors.append(("CONTRADICTED", sym,
                           f"marked NOT_BRIDGED but CF dispatches on it "
                           f"({len(dispatched[sym])} sites, e.g. {dispatched[sym][0]})"))
        if verdict == "BRIDGED":
            if not is_dispatched:
                errors.append(("CONTRADICTED", sym,
                               "marked BRIDGED but CF has no dispatch site for it"))
            if detail not in have_classes:
                errors.append(("MISSING_CLASS", sym,
                               f"class {detail} is not implemented"))
            call = calls.get(sym)
            if call is None:
                errors.append(("UNREGISTERED", sym,
                               "no _CFRuntimeBridgeClasses call"))
            else:
                cls, where, inside = call
                if cls != detail:
                    errors.append(("UNREGISTERED", sym,
                                   f"registered as {cls}, table says {detail}"))
                elif not inside:
                    errors.append(("MISPLACED", sym,
                                   f"registered in {where} outside __CFInitialize"))

    for sym in sorted(set(table) - set(ids)):
        errors.append(("STALE", sym, "table row for a typeID CF does not define"))

    cfstring = table.get("_kCFRuntimeIDCFString")
    if cfstring and cfstring[0] == "BRIDGED":
        defines = defines_constant_string_class(objdir)
        if defines is None:
            errors.append(("CONSTANT_STRING", "_kCFRuntimeIDCFString",
                           "NOT MEASURED -- pass --objdir with a built CFRuntime.o"))
        elif defines:
            errors.append(("CONSTANT_STRING", "_kCFRuntimeIDCFString",
                           "CF still DEFINES ___CFConstantStringClassReference "
                           "(a zeroed int[24]); every CFSTR would be messaged "
                           "as that non-class"))

    bridged = sum(1 for v, _ in table.values() if v == "BRIDGED")
    print(f"typeIDs declared by CF     : {len(ids)}"
          f"  (+{len(dynamic)} registered dynamically: "
          f"{', '.join(sorted(dynamic)) or 'none'})")
    print(f"adjudicated in table       : {len(table)}  "
          f"({bridged} BRIDGED, {len(table) - bridged} NOT_BRIDGED)")
    print(f"types CF dispatches on     : {len(dispatched)}")
    print(f"registration calls present : {len(calls)}")
    print(f"ObjC classes implemented   : {len(have_classes)}")
    if unresolved:
        print(f"\nunresolvable dispatch sites ({len(unresolved)}) -- first argument is a "
              f"local variable.\nThese are reported, not ignored; each is a type this tool "
              f"cannot attribute:")
        for u in unresolved:
            print(f"  {u}")

    if not errors:
        print("\nREGISTRATION COMPLETE: every typeID adjudicated, every bridged "
              "type registered.")
        return 0

    print(f"\nREFUSING: {len(errors)} problem(s).")
    width = max(len(k) for k, _, _ in errors)
    by_kind = {}
    for kind, sym, why in errors:
        by_kind.setdefault(kind, []).append((sym, why))
    for kind in sorted(by_kind):
        rows = by_kind[kind]
        print(f"\n{kind.ljust(width)}  ({len(rows)})")
        for sym, why in rows:
            print(f"  {sym:<38} {why}")
    return 1


if __name__ == "__main__":
    sys.exit(main())
