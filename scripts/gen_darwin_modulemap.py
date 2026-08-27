#!/usr/bin/env python3
"""gen_darwin_modulemap.py <sysroot> -- declare the Clang modules a sysroot can
honestly support, by PRUNING Apple's modulemaps rather than copying or
flattening them.

MACOS ONLY, and it writes into the TARGET SYSROOT, never into machorun's own
sdk/usr/include.  That is deliberate and it is what keeps sdk/PROVENANCE.md's
central claim true: "Xcode is no longer a build input", every committed byte
redistributably licensed.  The output of this script is derived from Apple's
Xcode SDK modulemaps, so it belongs in a gitignored build sysroot alongside the
.swiftinterface files that are staged from the same place -- not in git.

WHY THIS EXISTS.  A Swift `import Darwin` needs the *Clang* module `Darwin`.
machorun's staged sysroot declared exactly one Clang module (ObjectiveC), so
the chain

    import Synchronization -> Synchronization.swiftinterface: import Darwin
      -> Darwin.swiftinterface: underlying Objective-C module 'Darwin'

died at the last step, behind a misleading top-level error about toolchain
version skew.  It is a missing module DECLARATION, not a version problem.

THREE WAYS TO PRODUCE THAT DECLARATION, AND TWO OF THEM ARE WRONG.

  copy Apple's      names 305 headers this sysroot does not stage.  Every one is
                    a fresh latent gap -- exactly the class being retired.
  flatten           one `module Darwin { header ... }` over whatever is present.
                    This is what the first generator did, and it CANNOT work:
                    the interfaces import NAMED SUBMODULES --
                    `Darwin.Mach.message`, `_DarwinFoundation1._errno`,
                    `_DarwinFoundation3.pthread` -- which a flat module has no
                    way to provide.  It also collapses four top-level modules
                    into one.
  prune             keep Apple's structure, drop `header` lines whose file is
                    absent, drop modules left empty.  Never names a header that
                    is not there, and preserves every submodule name that is.

The pruning rule is the whole design: a module is kept if, after pruning, it
still declares something -- a header of its own, or a surviving submodule.

WHAT IS DROPPED ON PURPOSE, beyond absent headers:

  requires found_incompatible_headers__check_search_paths
        Apple's `_c_standard_library_obsolete` marks itself deliberately
        unbuildable; it exists to produce an error when include paths are
        wrong.  Keeping it means importing Darwin fails by design.
  i386 / x86_64 submodules
        we are arm64-only, and those headers are legitimately absent.  They
        fall out of the absent-header rule on their own; this is only a note
        that their disappearance is correct rather than a gap.

WHAT THIS DOES NOT PROVE.  "Every header present" is necessary, not sufficient:
a module whose own headers are staged can still fail because one of them
#includes something absent, or because a Swift overlay written against Apple's
libc reaches for a declaration our clean-room header omits.  Both happened --
see docs/UNIMPLEMENTED.md#darwin-clang-module.  THE OUTPUT OF THIS SCRIPT IS
NOT THE TEST.  The test is compiling `import Darwin` against the result:

    python3 scripts/gen_darwin_modulemap.py <sysroot>
    swiftc -target arm64-apple-macos11 -sdk <sysroot> \\
           -runtime-compatibility-version none -parse-as-library \\
           -module-name T -emit-object -o /tmp/t.o t.swift    # t.swift: import Darwin

which needs a Linux swiftc and so runs in the Swift container, not here.  It is
the cheapest possible check of the whole chain: no swift-foundation checkout,
one source line, and every module in the chain gets built to satisfy it.
"""

import os
import re
import sys

# ---------------------------------------------------------------- the parser
#
# A modulemap is a brace-nested grammar, so it is parsed rather than regexed.
# Only the constructs Apple's Darwin-family maps actually use are handled, and
# anything unrecognised is carried through VERBATIM rather than guessed at --
# a line this script does not understand must not be silently dropped, because
# dropping a `requires` or an `export` changes what the module means.

HEADER_RE = re.compile(
    r'^\s*(?:(private|textual|umbrella|exclude)\s+)*header\s+"([^"]+)"')
# DOTTED NAMES ARE REAL AND WERE NEARLY MISSED. `Darwin_C.modulemap` opens with
# `module Darwin.C {` -- it RE-OPENS a submodule of a module declared in another
# file. A name pattern without the dot does not match that line, so every
# submodule inside it parses as a TOP-LEVEL module and would be emitted in the
# wrong namespace. It stayed invisible because Darwin_C prunes to nothing in
# this sysroot: a parser bug behind an empty result.
MODULE_RE = re.compile(
    r'^\s*(?:(explicit|framework)\s+)*module\s+([A-Za-z_][A-Za-z0-9_.]*)\s*'
    r'(\[[^{]*\])?\s*\{')
EXTERN_RE = re.compile(
    r'^\s*extern\s+module\s+([A-Za-z_][A-Za-z0-9_]*)\s+"([^"]+)"')
REQUIRES_UNBUILDABLE = 'found_incompatible_headers__check_search_paths'


# ------------------------------------------------ the `_modules/` shim headers
#
# Apple's Darwin_C module is built entirely out of headers like
# `_modules/_darwin_c_stdlib.h`, and every one of the 78 is the SAME shape:
#
#     #if !__building_module(Darwin)
#     #error "Do not include this header directly, include <stdlib.h> instead"
#     #endif
#     #include <stdlib.h>
#
# They carry no interface at all -- they are a MECHANISM for giving a module
# exactly one header to own while the real header stays includable by everyone
# else. We stage none of them, so every module built on them pruned to nothing
# and `Darwin.C` -- the C standard library -- disappeared. `import Darwin` still
# COMPILED, because the overlay chain never asks for Darwin.C; but user code
# calling `exit(0)` got "cannot find 'exit' in scope". That is precisely the
# shape of "the module builds" being weaker than "the code works", found by
# linking and running rather than by compiling.
#
# SO SYNTHESISE THEM RATHER THAN DROP THE MODULE. Two facts are read out of
# Apple's copy -- the name in `__building_module()` and the header it includes
# -- and our own file is written from them. Reading two identifiers is not
# copying a header, and the result lands in the gitignored sysroot like
# everything else here.
#
# A shim is written ONLY when the header it forwards to is actually staged.
# Otherwise it would be a file that exists and cannot compile, which is worse
# than the module being absent: an absence is nameable, a broken include is a
# diagnostic 400 lines into someone else's build.
SHIM_MODULE_RE = re.compile(r'__building_module\(([A-Za-z_][A-Za-z0-9_]*)\)')
SHIM_INCLUDE_RE = re.compile(r'^\s*#\s*include\s+<([^>]+)>', re.M)


def synthesise_shim(rel, sdk_inc, out_inc, present):
    """Write our own copy of a _modules/ shim. True once it exists."""
    src = os.path.join(sdk_inc, rel)
    if not os.path.isfile(src):
        return False
    with open(src) as f:
        text = f.read()
    m = SHIM_MODULE_RE.search(text)
    incs = SHIM_INCLUDE_RE.findall(text)
    if not m or not incs:
        return False                      # not the shape this understands
    if any(i not in present for i in incs):
        return False                      # forwards to something we do not stage

    guard = '__MR_' + re.sub(r'[^A-Za-z0-9]', '_', rel).upper() + '_'
    body = [
        '/* GENERATED by machorun scripts/gen_darwin_modulemap.py -- do not edit.',
        ' *',
        ' * A module shim, not an interface: its whole job is to give the Clang',
        ' * module `%s` one header to own while the real header stays' % m.group(1),
        ' * includable by everyone else. The #error is functional --',
        ' * __building_module() is true only while Clang is compiling that',
        ' * module, so including this by hand is a diagnostic rather than a',
        ' * second, unmodularised copy of the real header. */',
        '#ifndef %s' % guard,
        '#define %s' % guard,
        '#if !__building_module(%s)' % m.group(1),
        '#error "Do not include this header directly, include <%s> instead"' % incs[0],
        '#endif',
    ]
    body += ['#include <%s>' % i for i in incs]
    body += ['#endif /* %s */' % guard, '']

    dst = os.path.join(out_inc, rel)
    os.makedirs(os.path.dirname(dst), exist_ok=True)
    with open(dst, 'w') as f:
        f.write('\n'.join(body))
    present.add(rel)
    return True


class Module:
    def __init__(self, decl):
        self.decl = decl          # the `module X [attrs] {` line, verbatim
        self.headers = []         # (verbatim_line, path) for each header
        self.children = []        # nested Module objects
        self.externs = []         # (verbatim_line, name, file)
        self.other = []           # export/requires/link/use/comments, in order
        self.unbuildable = False

    def prune(self, present, kept_externs, shim=None):
        """Drop absent headers and empty children. True if anything survives.

        `shim` is given the chance to CREATE a missing header before it is
        judged absent -- see synthesise_shim. Only `_modules/` paths are
        offered, because those are the only ones whose content is mechanism
        rather than interface."""
        if self.unbuildable:
            return False
        kept = []
        for h in self.headers:
            if h[1] in present:
                kept.append(h)
            elif shim and h[1].startswith('_modules/') and shim(h[1]):
                kept.append(h)
        self.headers = kept
        self.children = [c for c in self.children
                         if c.prune(present, kept_externs, shim)]
        self.externs = [e for e in self.externs if e[2] in kept_externs]
        return bool(self.headers or self.children or self.externs)

    def emit(self, out, indent=0):
        pad = '  ' * indent
        out.append(pad + self.decl)
        for line in self.other:
            out.append(pad + '  ' + line)
        for line, _ in self.headers:
            out.append(pad + '  ' + line)
        for line, _, _ in self.externs:
            out.append(pad + '  ' + line)
        for c in self.children:
            c.emit(out, indent + 1)
        out.append(pad + '}')


def parse(path):
    """Parse one modulemap into a list of top-level Modules."""
    with open(path) as f:
        lines = f.read().split('\n')

    roots, stack, i = [], [], 0
    while i < len(lines):
        raw = lines[i]
        line = raw.strip()
        i += 1

        if not line or line.startswith('//'):
            continue

        m = MODULE_RE.match(raw)
        if m:
            mod = Module(line if line.endswith('{') else line)
            (stack[-1].children if stack else roots).append(mod)
            stack.append(mod)
            continue

        if line == '}':
            if stack:
                stack.pop()
            continue

        if not stack:
            continue

        cur = stack[-1]

        m = EXTERN_RE.match(raw)
        if m:
            cur.externs.append((line, m.group(1), m.group(2)))
            continue

        m = HEADER_RE.match(raw)
        if m:
            cur.headers.append((line, m.group(2)))
            continue

        if line.startswith('requires') and REQUIRES_UNBUILDABLE in line:
            cur.unbuildable = True
            continue

        cur.other.append(line)

    return roots


def main():
    if len(sys.argv) != 2:
        sys.exit('usage: gen_darwin_modulemap.py <sysroot>')
    sysroot = sys.argv[1]
    inc = os.path.join(sysroot, 'usr', 'include')
    if not os.path.isdir(inc):
        sys.exit('no %s' % inc)

    sdk = os.popen('xcrun --sdk macosx --show-sdk-path').read().strip()
    if not sdk or not os.path.isdir(sdk):
        sys.exit('no macOS SDK: this script needs Xcode, and runs on macOS only')

    # Every header the target sysroot actually stages, as sysroot-relative
    # paths -- which is the same spelling a modulemap uses.
    present = set()
    for dirpath, _, files in os.walk(inc):
        for f in files:
            present.add(os.path.relpath(os.path.join(dirpath, f), inc))

    # The Darwin family, in dependency order. `Darwin.modulemap` pulls the
    # others in by `extern module`, and each generated file is only referenced
    # if it survived pruning -- so an extern naming a map we dropped is dropped
    # too, rather than left pointing at a file that does not exist.
    family = ['Darwin_C', 'Darwin_POSIX', 'Darwin_Mach', 'Darwin_Mach_machine',
              'Darwin_machine', 'Darwin_sys', 'DarwinBasic',
              'DarwinFoundation1', 'DarwinFoundation2', 'DarwinFoundation3',
              'Darwin']

    kept, stats, entries = set(), [], []
    for name in family:
        src = os.path.join(sdk, 'usr', 'include', name + '.modulemap')
        if not os.path.isfile(src):
            continue
        roots = parse(src)
        n_before = sum(count_headers(r) for r in roots)
        shim = lambda rel: synthesise_shim(rel, os.path.join(sdk, 'usr', 'include'),
                                          inc, present)
        roots = [r for r in roots if r.prune(present, kept, shim)]
        n_after = sum(count_headers(r) for r in roots)
        if not roots:
            stats.append((name, n_before, 0, 'DROPPED (nothing survived)'))
            continue

        out = ['// GENERATED by machorun scripts/gen_darwin_modulemap.py.',
               '// Pruned from %s.modulemap in' % name,
               '//   %s' % sdk,
               '// to the headers THIS sysroot stages. Do not edit; do not commit.',
               '']
        for r in roots:
            r.emit(out)
            out.append('')
        with open(os.path.join(inc, name + '.modulemap'), 'w') as f:
            f.write('\n'.join(out))
        kept.add(name + '.modulemap')
        stats.append((name, n_before, n_after, 'ok'))
        # ONE `extern module` PER SURVIVING TOP-LEVEL MODULE, which is exactly
        # what Apple's own usr/include/module.modulemap does -- `pthread`,
        # `sched`, `unistd` and `_DarwinFoundation3` all point at
        # DarwinFoundation3.modulemap. Deriving the entries from what actually
        # survived means a module we pruned away is never advertised.
        for r in roots:
            n = module_name(r)
            # A DOTTED root re-opens a submodule of a module declared
            # elsewhere -- `module Darwin.C` in Darwin_C.modulemap. Apple's own
            # module.modulemap gives those no entry, because they are reached
            # through the parent's `extern module C "Darwin_C.modulemap"`.
            # Advertising them top-level would declare `Darwin.C` twice.
            if '.' not in n:
                entries.append((n, name))

    # Reference the family from the sysroot's own module.modulemap, which
    # already declares ObjectiveC. APPENDED, not rewritten: that file is
    # machorun's, and this script adds only what it generated. Re-running is
    # idempotent because each line is checked against what is already there.
    top = os.path.join(inc, 'module.modulemap')
    existing = open(top).read() if os.path.isfile(top) else ''
    add = ['extern module %s "%s.modulemap"' % (mod, f) for mod, f in entries]
    add = [a for a in add if a not in existing]
    if add:
        with open(top, 'a') as f:
            f.write('\n// Appended by machorun scripts/gen_darwin_modulemap.py\n')
            f.write('\n'.join(add) + '\n')

    w = max(len(s[0]) for s in stats) if stats else 0
    print('== Darwin modulemaps pruned to %d staged headers' % len(present))
    for name, before, after, note in stats:
        print('   %-*s  %3d -> %3d headers   %s' % (w, name, before, after, note))


def count_headers(mod):
    return len(mod.headers) + sum(count_headers(c) for c in mod.children)


def module_name(mod):
    m = MODULE_RE.match(mod.decl)
    return m.group(2) if m else '?'


if __name__ == '__main__':
    main()
