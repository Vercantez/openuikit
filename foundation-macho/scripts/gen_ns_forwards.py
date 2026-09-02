#!/usr/bin/env python3
"""Generate the @class forward declarations CoreFoundation needs to compile.

    scripts/gen_ns_forwards.py <CF_SOURCE_DIR> [-o include/CFNSForwards.h]

WHY THIS EXISTS
---------------
Restoring CF's ObjC dispatch macros turns casts that were previously dead text
into real code. CF_OBJC_FUNCDISPATCHV sites cast through Foundation class
types -- `(NSNumber *)boolean`, `(NSMutableString *)str` -- and with the macros
armed those casts must name types that exist. Compiling CF as ObjC without them
fails with "use of undeclared identifier 'NSNumber'" in 8 TUs.

A forward declaration is genuinely all that is required. The cast is a no-op at
runtime: the object's real class is whatever __CFInitialize registered for that
typeID, and CF never sends a message through the static type. So `@class NSFoo;`
is sufficient, and inventing @interface bodies here would be a lie about a class
that lives elsewhere.

THE LIST IS DERIVED, NEVER TYPED
--------------------------------
Same rule as docs/cf-registration.tsv. A hand-maintained list of 23 class names
drifts the moment corelibs adds a dispatch site, and drifts silently, because
the failure is a compile error in a file nobody was looking at. So the set comes
out of CF's own sources.

NOT EVERY NS NAME IN A POINTER CAST IS A CLASS. NSRange and NSUInteger appear in
casts too -- `(NSRange *)` and `(NSUInteger *)` for out-parameters -- and both
are already TYPES. Emitting `@class NSRange;` for them is not subtle: it is
"redefinition of 'NSRange' as different kind of symbol", a hard error.

WHICH NAMES ARE ALREADY TYPES IS A QUESTION ONLY THE COMPILER CAN ANSWER, and
the first version of this script got it wrong by trying to answer it with a
regex over include/*.h. Two ways that failed, both instructive:

  NSRange     is `typedef struct _NSRange { ... } NSRange;`. Splitting the
              typedef on the first ';' lands INSIDE the struct body, so the
              parser never saw the trailing name. Brace-blind text parsing of C
              is the same mistake as enumerating sources with `find`.
  NSUInteger  is not in our headers AT ALL. It arrives from the SDK via
              objc/NSObjCRuntime.h, so no amount of grepping our own tree could
              have found it. The compilation context is bigger than our files.

So the exclusion set now comes from scripts/classify_ns_names.sh, which compiles
a one-line probe per candidate against the real sysroot and reports which names
already name a type. Pass it with --types-file. Without it this script REFUSES
rather than guessing, because guessing wrong here produces a header that breaks
every CF translation unit at once.
"""
import os
import re
import sys

CAST = re.compile(r"\(\s*(NS[A-Za-z0-9_]+)\s*\*")
TYPEDEF_TAIL = re.compile(r"\b(NS[A-Za-z0-9_]+)\s*;")


def derive_names(cfdir):
    names = set()
    for fn in sorted(os.listdir(cfdir)):
        if not fn.endswith((".c", ".m", ".h")):
            continue
        with open(os.path.join(cfdir, fn), errors="replace") as fh:
            names.update(CAST.findall(fh.read()))
    return names


def existing_types(path):
    """Names the COMPILER says already denote a type.

    Produced by scripts/classify_ns_names.sh against the real sysroot -- see the
    module docstring for why this cannot be answered by reading our headers.
    """
    with open(path) as fh:
        return {ln.strip() for ln in fh if ln.strip()}


def main():
    if len(sys.argv) < 2:
        sys.exit(__doc__)
    cfdir = sys.argv[1]
    out = "include/CFNSForwards.h"
    if "-o" in sys.argv:
        out = sys.argv[sys.argv.index("-o") + 1]
    if "--candidates" in sys.argv:
        # Emit the raw candidate list for classify_ns_names.sh to probe.
        for n in sorted(derive_names(cfdir)):
            print(n)
        return
    if "--types-file" not in sys.argv:
        sys.exit("gen_ns_forwards: --types-file is required.\n"
                 "  Which NS names already denote a type is a question only the\n"
                 "  compiler can answer (NSUInteger is not in our headers at\n"
                 "  all -- it comes from the SDK). Run:\n"
                 "    scripts/gen_ns_forwards.py <cf> --candidates > cand.txt\n"
                 "    scripts/classify_ns_names.sh cand.txt > types.txt\n"
                 "  then pass --types-file types.txt. Guessing here emits a\n"
                 "  @class for an existing type and breaks every CF TU at once.")
    typespath = sys.argv[sys.argv.index("--types-file") + 1]

    names = derive_names(cfdir)
    if not names:
        # An empty set would generate a header that declares nothing, and CF
        # would fail with the same undeclared-identifier errors while this
        # script reported success. Refuse instead.
        sys.exit(f"gen_ns_forwards: found ZERO NS casts under {cfdir} -- "
                 "refusing to write an empty header, which would look like a "
                 "pass and change nothing.")
    known = existing_types(typespath)
    classes = sorted(names - known)
    skipped = sorted(names & known)

    body = [
        "/* GENERATED by scripts/gen_ns_forwards.py -- do not edit.",
        " *",
        " * The Foundation classes CoreFoundation casts through in its ObjC",
        " * dispatch macros. Forward declarations only: the cast is a no-op at",
        " * runtime, since the object's real class is whatever __CFInitialize",
        " * registered for its typeID and CF never messages through the static",
        " * type. Declaring @interface bodies here would be a lie about classes",
        " * that live in src/nscf/.",
        " *",
        " * Derived from CF's own sources, never typed by hand -- a fixed list",
        " * drifts the moment corelibs adds a dispatch site, and drifts",
        " * silently.",
        " *",
        f" * {len(classes)} classes.",
    ]
    if skipped:
        body += [
            " *",
            " * Excluded, because our own headers already define them as TYPES",
            " * and @class would be a redefinition rather than a duplicate:",
            " *   " + ", ".join(skipped),
        ]
    body += [
        " */",
        "#ifndef CF_NS_FORWARDS_H",
        "#define CF_NS_FORWARDS_H",
        "#if defined(__OBJC__)",
    ]
    body += [f"@class {n};" for n in classes]
    body += ["#endif", "#endif", ""]

    with open(out, "w") as fh:
        fh.write("\n".join(body))
    print(f"gen_ns_forwards: {len(classes)} classes -> {out}")
    if skipped:
        print(f"  excluded as existing types: {', '.join(skipped)}")


if __name__ == "__main__":
    main()
