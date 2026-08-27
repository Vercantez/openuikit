#!/usr/bin/env python3
"""Refuse any class whose isa is baked at compile time but which cannot answer
CF's type-id-free dispatch.

    scripts/check_baked_isa.py [src/nscf]

THE ASYMMETRY THIS EXISTS TO CATCH
----------------------------------
CF's type-id-FREE dispatch (CFTYPE_OBJC_FUNCDISPATCH, five sites in
CFRuntime.c) tests

    isa != __CFISAForTypeID(typeID_of(obj))

For an ordinary bridged instance those are equal -- _CFRuntimeCreateInstance
initialises _cfisa FROM the slot -- so the test is false and CF stays on its
native path. That equality is what makes the whole forwarding surface sound.

A class whose isa is BAKED AT COMPILE TIME cannot participate in that. The
constant-string alias puts __NSCFConstantString into every CFSTR's isa field in
__DATA, before any registration exists to match it, and CFString's slot holds
__NSCFString. They can never be equal, so constant strings take the ObjC branch
of EVERY type-id-free dispatch, always.

The consequence is not subtle and it was live: CFGetTypeID(CFSTR("x")),
CFEqual and CFHash on a constant string each died with "unrecognized selector"
until those three methods were written. Measured, not predicted.

WHY A GUARD RATHER THAN A FIX AND A NOTE
----------------------------------------
The criterion is now known -- an isa fixed at compile time rather than assigned
from a slot -- so the next such class should be FOUND rather than MET. Met is an
unrecognised-selector abort a long way from its cause, or, if someone implements
one of the three by forwarding, a hang with no output.

Today __NSCFConstantString is the only class that qualifies, so this is cheap
and says so. When a second baked-isa class appears, this refuses instead.
"""
import os
import re
import sys

# The three selectors CFRuntime.c dispatches WITHOUT a typeID, so every
# baked-isa instance receives them. Derived from the call sites rather than
# remembered: CFGetTypeID:772, CFEqual:966/981/982, CFHash:1005.
REQUIRED = ("_cfTypeID", "hash", "isEqual:")

# The .set and its target are frequently SPLIT ACROSS ADJACENT STRING LITERALS,
# because the line is long:
#
#     __asm__(".globl ___CFConstantStringClassReference\n\t"
#             ".set   ___CFConstantStringClassReference, "
#             "_OBJC_CLASS_$___NSCFConstantString\n");
#
# A line-oriented pattern sees neither half and reports "no baked-isa class" --
# a CLEAN PASS for a file that contains exactly the thing being looked for. The
# first version of this guard did precisely that, and its own negative control
# caught it: deleting -hash still passed, which proved the guard was not
# reading anything. So the source is stripped of C string-literal punctuation
# before matching, which joins the halves.
SET_ALIAS = re.compile(r'\.set\s+_+(\w+)\s*,\s*_OBJC_CLASS_\$_(\w+)')
IMPL = re.compile(r"^@implementation\s+(\w+)", re.M)
METHOD = re.compile(r"^\s*[-+]\s*\([^)]*\)\s*(\w+:?)", re.M)


def main():
    root = sys.argv[1] if len(sys.argv) > 1 else "src/nscf"
    if not os.path.isdir(root):
        sys.exit(f"check_baked_isa: no such directory {root}")

    baked = {}          # class name -> file that bakes its isa
    methods = {}        # class name -> set of selectors it implements
    for fn in sorted(os.listdir(root)):
        if not fn.endswith(".m"):
            continue
        path = os.path.join(root, fn)
        src = open(path, errors="replace").read()
        # Join adjacent string literals so a split .set directive is visible.
        flat = re.sub(r'"\s*"', "", src).replace("\\n", " ").replace("\\t", " ")
        for _alias, cls in SET_ALIAS.findall(flat):
            baked[cls] = fn
        # Attribute methods to the @implementation they follow.
        cur = None
        for line in src.split("\n"):
            m = IMPL.match(line)
            if m:
                cur = m.group(1)
                methods.setdefault(cur, set())
                continue
            if line.startswith("@end"):
                cur = None
                continue
            if cur:
                mm = METHOD.match(line)
                if mm:
                    methods[cur].add(mm.group(1))

    if not baked:
        # No baked-isa class is a legitimate state, but an EMPTY PARSE is not
        # distinguishable from it here, so say which was measured rather than
        # printing a bare pass.
        print("check_baked_isa: no class has a compile-time-baked isa "
              f"(scanned {root}). Nothing to check.")
        return 0

    problems = []
    for cls, fn in sorted(baked.items()):
        have = methods.get(cls, set())
        missing = [s for s in REQUIRED if s not in have]
        print(f"  {cls}  (isa baked in {fn})  implements "
              f"{len(REQUIRED) - len(missing)}/{len(REQUIRED)} required")
        if missing:
            problems.append((cls, fn, missing))

    if problems:
        print("\nREFUSING: a class with a compile-time-baked isa cannot match "
              "its typeID's\nregistration slot, so CF sends it EVERY type-id-free "
              "dispatch. Missing any\nof these is an unrecognized-selector abort "
              "at runtime, far from the cause:\n")
        for cls, fn, missing in problems:
            print(f"  {cls} ({fn}) is missing: {', '.join(missing)}")
        print("\nImplement them WITHOUT calling the CF function that dispatched "
              "to them --\nforwarding -hash to CFHash is a cycle, and it hangs "
              "rather than crashing.")
        return 1

    print("\nOK: every baked-isa class answers all three type-id-free selectors.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
