#!/usr/bin/env python3
"""Select CFRunLoop.c's epoll platform layer on a Darwin target.

    scripts/patch_cf_runloop.py <CF_SOURCE_DIR>

Idempotent. REFUSES if the file does not have exactly the shape it expects.

WHY THIS IS A PATCH AND NOT A -D
--------------------------------
CFRunLoop.c already contains the whole non-Mach implementation: corelibs writes
every platform primitive for Linux using eventfd/epoll/timerfd. We never reach
it because we build `-target arm64-apple-macos`, so TARGET_OS_MAC is 1 and wins
every guard. This is SELECTING CODE THAT IS ALREADY IN THE FILE, not porting.

The obvious shortcut -- redefine TARGET_OS_MAC to 0 and TARGET_OS_LINUX to 1
after TargetConditionals.h -- was MEASURED and rejected. It takes the file to a
single missing header, which looks like success, and then produces
`qos_class_main` / `qos_class_self` redeclared as static in CFInternal.h,
conflicting with the real Darwin SDK. Telling a whole translation unit it is not
Darwin changes decisions far outside the run loop, and the two visible errors are
only the ones that happen to be visible. So the guards are rewritten in place,
where each change is scoped to the thing it selects.

WHAT IT REWRITES, AND HOW IT FINDS IT
-------------------------------------
Only preprocessor chains that offer BOTH a TARGET_OS_MAC branch and a
TARGET_OS_LINUX branch -- i.e. places where corelibs has already written both
implementations and merely picks the wrong one for us. Chains that mention only
one platform are left alone; a `#if TARGET_OS_MAC` with no Linux alternative is
not a platform choice, it is Darwin-specific code with no replacement, and
disabling it would be a different and unjustified edit.

The chains are located STRUCTURALLY, by matching `#if`/`#elif`/`#else`/`#endif`
nesting, not by grepping for the guard text. That distinction has already cost
this project once: enumerating libdispatch's run-loop sites by grepping
`mach_port_*` found five where there were six, because the missed one's Darwin
branch called none of the names searched for. Precision in a search is not
coverage.
"""
import os
import re
import sys

MARK = "CF_RUNLOOP_USE_EPOLL"

# Measured against swift-corelibs-foundation release/6.2. If corelibs changes
# shape, the count changes and this refuses rather than silently doing less.
EXPECTED_CHAINS = 12

PROLOGUE = """/* swiftcore-macho / foundation-macho: see scripts/patch_cf_runloop.py.
 *
 * CFRunLoop.c contains BOTH a Mach implementation and an eventfd/epoll one.
 * We are a Darwin target without Mach IPC, so TARGET_OS_MAC selects the wrong
 * half. These two macros replace TARGET_OS_MAC / TARGET_OS_LINUX in exactly the
 * guards that offer both, and nowhere else -- TARGET_OS_MAC keeps its real
 * meaning everywhere it is asking "is this Darwin" rather than "is Mach here".
 */
#ifndef CF_RUNLOOP_USE_MACH
#define CF_RUNLOOP_USE_MACH 0
#endif
#ifndef CF_RUNLOOP_USE_EPOLL
#define CF_RUNLOOP_USE_EPOLL 1
#endif

"""


def die(msg):
    print(f"patch_cf_runloop: {msg}", file=sys.stderr)
    sys.exit(2)


def find_chains(lines):
    """Chains offering both a TARGET_OS_MAC and a TARGET_OS_LINUX branch.

    Returns [(indices of the branch lines)], located by brace-free
    preprocessor nesting rather than by text search.
    """
    chains, stack = [], []
    for i, line in enumerate(lines):
        t = line.strip()
        if re.match(r"#\s*if", t):
            stack.append([i, [i]])
        elif re.match(r"#\s*(elif|else)", t) and stack:
            stack[-1][1].append(i)
        elif re.match(r"#\s*endif", t) and stack:
            _, idxs = stack.pop()
            br = [lines[j] for j in idxs]
            if any("TARGET_OS_MAC" in b for b in br) and \
               any("TARGET_OS_LINUX" in b for b in br):
                chains.append(idxs)
    if stack:
        die("unbalanced preprocessor nesting -- refusing to edit")
    return chains


def rewrite(line):
    """Rewrite one branch line, or return it unchanged.

    A branch naming BOTH platforms already treats them alike and must not be
    touched: `#elif TARGET_OS_MAC || (TARGET_OS_LINUX && !TARGET_OS_CYGWIN)`
    is upstream saying "these two agree here", which stays true for us.
    """
    has_mac = "TARGET_OS_MAC" in line
    has_lin = "TARGET_OS_LINUX" in line
    if has_mac and has_lin:
        return line, False
    if has_mac:
        return line.replace("TARGET_OS_MAC", "CF_RUNLOOP_USE_MACH"), True
    if has_lin:
        # `TARGET_OS_LINUX && !TARGET_OS_CYGWIN` collapses: we are neither
        # Linux nor Cygwin as far as TargetConditionals is concerned, and the
        # exclusion exists only to keep Cygwin out of the Linux branch.
        out = re.sub(r"TARGET_OS_LINUX\s*&&\s*!\s*TARGET_OS_CYGWIN",
                     MARK, line)
        out = out.replace("TARGET_OS_LINUX", MARK)
        return out, True
    return line, False


def main():
    if len(sys.argv) < 2:
        die("usage: patch_cf_runloop.py <CF_SOURCE_DIR>")
    path = os.path.join(sys.argv[1], "CFRunLoop.c")
    if not os.path.exists(path):
        die(f"missing {path}")
    src = open(path).read()

    if MARK in src:
        print("  CFRunLoop.c: already patched")
        return 0

    lines = src.split("\n")
    chains = find_chains(lines)
    if len(chains) != EXPECTED_CHAINS:
        die(f"expected {EXPECTED_CHAINS} dual-platform chains, found "
            f"{len(chains)} -- corelibs has changed shape. Refusing rather "
            f"than patching a file this script no longer understands.")

    changed = 0
    for idxs in chains:
        for j in idxs:
            new, did = rewrite(lines[j])
            if did:
                lines[j] = new
                changed += 1
    if changed == 0:
        die("located the chains but rewrote nothing -- refusing to report "
            "success for a no-op")

    out = "\n".join(lines)
    # Put the definitions after the last #include of the prologue region, so
    # they precede every guard. CFRunLoop.c opens with its licence block then
    # includes; anchoring on the first #include keeps this stable.
    m = re.search(r"^#include ", out, re.M)
    if not m:
        die("no #include found -- cannot place the selector definitions")
    out = out[:m.start()] + PROLOGUE + out[m.start():]

    open(path, "w").write(out)
    print(f"  CFRunLoop.c: rewrote {changed} branch guards across "
          f"{len(chains)} dual-platform chains")
    return 0


if __name__ == "__main__":
    sys.exit(main())
