#!/usr/bin/env python3
"""Emit CoreFoundation's complete undefined-symbol set, with provenance."""
import subprocess, os, sys, glob, collections

C   = "/private/tmp/claude-501/-Users-miguelsalinas-uikit/8c75c08f-5c8e-42ec-9353-7334732ef488/scratchpad/symwork/census"
LIB = "/private/tmp/claude-501/-Users-miguelsalinas-uikit/8c75c08f-5c8e-42ec-9353-7334732ef488/scratchpad/symwork/lib/libSystem.B.dylib"
X   = "/private/tmp/claude-501/-Users-miguelsalinas-uikit/8c75c08f-5c8e-42ec-9353-7334732ef488/scratchpad/symwork/cfextra"
NM  = "nm"
OUT = "/Users/miguelsalinas/foundation-macho/docs/cf-census/cf-undefined-symbols.txt"

def nm(path, *flags):
    out = subprocess.run([NM, *flags, path], capture_output=True, text=True).stdout
    res = []
    for line in out.splitlines():
        p = line.split()
        if p:
            # Mach-O prefixes C symbols with EXACTLY ONE underscore. lstrip("_")
            # strips them all and turns __NSGetExecutablePath into
            # NSGetExecutablePath -- the wrong name to implement against.
            n = p[-1]
            res.append(n[1:] if n.startswith("_") else n)
    return res

objs = sorted(glob.glob(f"{C}/obj/*.o"))
undef_by_obj, defined = {}, set()
for o in objs:
    b = os.path.basename(o)[:-2]
    undef_by_obj[b] = set(nm(o, "--undefined-only"))
    defined |= set(nm(o, "--defined-only", "--extern-only"))

allundef = set().union(*undef_by_obj.values())
external = allundef - defined
sysexp   = set(nm(LIB, "--defined-only", "--extern-only"))

# functions our shim headers declare with nothing behind them
shimdecl = set()
import re
for h in glob.glob(f"{X}/**/*.h", recursive=True):
    try: txt = open(h, errors="replace").read()
    except OSError: continue
    for m in re.finditer(r'(?:^|\n)\s*(?:[A-Za-z_][\w \*]*?)\b(\w+)\s*\([^;{]*\)\s*;', txt):
        shimdecl.add(m.group(1))

in_sys  = sorted(external & sysexp)
gap     = external - sysexp
shimmed = sorted(external & shimdecl)
real    = sorted(gap - shimdecl)

owner = collections.defaultdict(list)
for b, syms in undef_by_obj.items():
    for s in syms:
        if s in gap:
            owner[s].append(b)

cf_commit = subprocess.run(["git","-C","/Users/miguelsalinas/foundation-macho","rev-parse","--short","HEAD"],
                           capture_output=True, text=True).stdout.strip() or "unknown"

W = open(OUT, "w").write
W(f"""# CoreFoundation — complete undefined-symbol set
#
# PROVENANCE. Read before implementing anything below.
#
#   generated        : 2026-08-27
#   foundation-macho : {cf_commit}  (scripts/cf_census.sh, scripts/cf_shims.sh)
#   CF source        : swift-corelibs-foundation release/6.2
#   machorun         : master bdc5dc0 sysroot (TARGET_OS_* macros from 5d64c3b)
#   ICU headers      : apple/swift-foundation-icu 0.0.9 icuSources/include
#   target           : arm64-apple-macos13.0
#
#   BUILD CONFIGURATION — the CORRECTED one:
#     -DDEPLOYMENT_RUNTIME_SWIFT=0   (ObjC mode, the mode DECISION.md chose)
#     -fcf-runtime-abi=objc          (NOT =swift)
#     NO -Wno-everything             (undeclared-function calls are errors)
#     empty translation units excluded
#     NO -DTARGET_OS_* predefines    (machorun 5d64c3b made them unnecessary)
#
#   census : PASS=77 FAIL=5 EMPTY=4 (denominator 82); {len(objs)} objects
#
# SUPERSEDES every count in docs/CF_TRIAGE.md. Three libc counts appear there —
# 46, then 40, then 28 — as the measurement improved. NONE is this list: those
# were filtered subsets of smaller builds (60 and 69 objects). This is the whole
# external set from {len(objs)}.
#
# NOT EXHAUSTIVE. 5 files still fail, so their symbols are absent:
#   CFRunLoop, CFSocket, CFString, CFTimeZone, CFUtilities
# CFString and CFRunLoop are heavy libc consumers — expect this list to GROW.
#
# CONTAMINATION CHECK (asked for, and it found something):
#   cf_shims.sh declares functions with nothing behind them. CF reaches
#   {len(shimmed)} of them — section D. For those the NAME is real (CF genuinely
#   calls them) but the SIGNATURE is mine and the ABI is UNVERIFIED. Confirm
#   each against real Darwin headers before implementing.
#
#   posix_spawn: NOT REACHED. CFPlatform.c mentions it but compiles emitting no
#   posix_spawn* reference — the call sites are in branches not taken for our
#   target. So the hollow spawn.h is NOT contaminating this list, and the
#   posix_spawnattr_t 8-vs-336-byte ABI trap does not apply to CF today. It
#   applies the moment anything does reach it.
#
#   totals: {len(allundef)} undefined, {len(external)} external,
#           {len(in_sys)} already in libSystem, {len(real)} genuinely absent,
#           {len(shimmed)} shim-declared
""")

W("\n# " + "="*70 + "\n# SECTION A — already exported by machorun libSystem. No work needed.\n# " + "="*70 + "\n")
for s in in_sys: W(f"  {s}\n")

def cat(x):
    if re.match(r"^(u_|ucal_|uloc_|ucnv_|ucol_|uset_|uregex_|utrans_|unum_|udat_|udtitvfmt_|ulistfmt_|ureldatefmt_|udatpg_|ufieldpositer_|uenum_|ubrk_|uidna_|usearch_|ucurr_|uscript_|utext_|ulocdata_|unumsys_|uameas)", x): return "ICU"
    if re.match(r"^_?dispatch_", x): return "libdispatch"
    if re.match(r"^(mach_|mk_timer)", x): return "Mach"
    if re.match(r"^(CF|__CF|_CF|kCF)", x): return "CF (from the 5 failing files)"
    if re.match(r"^OS(Atomic|Memory|SpinLock)", x): return "OSAtomic/OSSpinLock"
    if re.match(r"^(_dyld|getsect|getseg|_NSGet)", x): return "dyld / Mach-O introspection"
    return "libc / pthread / locale / dirent"
bycat = collections.defaultdict(list)
for x in real: bycat[cat(x)].append(x)
W("\n# " + "="*70 + f"\n# SECTION B — NOT in libSystem: the actual gap ({len(real)})\n#\n")
W("# INDEX — swift-loader-fixes wants the 'libc / pthread / locale / dirent'\n"
  "# block; the rest belong to other tracks (ICU=ours, dispatch=#47, Mach=the\n"
  "# RunLoop fork, CF_*=resolves when the 5 failing files compile).\n#\n")
for k in sorted(bycat, key=lambda k: -len(bycat[k])):
    W(f"#   {k:<34} {len(bycat[k])}\n")
W("# " + "="*70 + "\n")
for k in sorted(bycat, key=lambda k: -len(bycat[k])):
    W(f"\n  ## {k} ({len(bycat[k])})\n")
    for x in bycat[k]: W(f"  {x}\n")

W("\n# " + "="*70 + "\n# SECTION C — per-object attribution for section B.\n"
  "# One file = stubbable or deferrable. Sixteen files = structural.\n# " + "="*70 + "\n")
for s in real:
    f = owner.get(s, [])
    W(f"  {s:<44} {len(f):>2}  {' '.join(sorted(f))}\n")

W("\n# " + "="*70 + f"\n# SECTION D — reached, but DECLARED BY MY SHIM ({len(shimmed)}). ABI UNVERIFIED.\n# " + "="*70 + "\n")
for s in shimmed:
    f = sorted(b for b, u in undef_by_obj.items() if s in u)
    W(f"  {s:<44} {len(f):>2}  {' '.join(f)}\n")

print(f"wrote {OUT}: external={len(external)} inSys={len(in_sys)} gap={len(real)} shimmed={len(shimmed)}")
