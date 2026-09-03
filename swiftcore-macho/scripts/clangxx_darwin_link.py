#!/usr/bin/env python3
"""clang++ driver shim for Darwin-target shared links on a Linux CMake host.

Ninja's CXX_SHARED_LIBRARY rule is generated from Modules/Platform/Linux.cmake,
so it always injects `-shared` (and historically `-Wl,-soname`) even when every
object is Mach-O `x86_64-apple-macosx`. Swift's clang then picks ld64.lld (via
-fuse-ld=lld -B) and the Mach-O linker rejects ELF host libc++ / -soname, or
leaves Darwin symbols undefined because the recipe never passed -lSystem.

This wrapper leaves compile / host-ELF links alone. Darwin-target -shared /
-dynamiclib invocations are rewritten to the recipe in link_macho_dylib.sh:
-dynamiclib -fuse-ld=lld -nostdlib -lSystem -lc++ -Wl,-undefined,dynamic_lookup.
"""
from __future__ import annotations

import os
import sys

APPLE_MARKER = "-apple-"


def _real_clangxx() -> str:
    env = os.environ.get("SWIFTCORE_REAL_CLANGXX")
    if env:
        return env
    tc = os.environ.get("TC")
    if tc:
        cand = os.path.join(tc, "bin", "clang++")
        if os.path.isfile(cand) and os.access(cand, os.X_OK):
            return cand
    for cand in ("/usr/bin/clang++", "clang++"):
        return cand
    return "clang++"


def _lld_bin() -> str:
    return os.environ.get("LLD_BIN") or "/usr/lib/llvm-18/bin"


def _is_compile(argv: list[str]) -> bool:
    return any(a in ("-c", "-E", "-fsyntax-only", "-S") for a in argv)


def _target(argv: list[str]) -> str | None:
    for i, a in enumerate(argv):
        if a == "-target" and i + 1 < len(argv):
            return argv[i + 1]
        if a.startswith("--target="):
            return a.split("=", 1)[1]
    return None


def _is_shared(argv: list[str]) -> bool:
    return "-shared" in argv or "-dynamiclib" in argv


def is_darwin_shared_link(argv: list[str]) -> bool:
    if _is_compile(argv):
        return False
    if not _is_shared(argv):
        return False
    t = _target(argv)
    return bool(t and APPLE_MARKER in t)


def _is_host_elf_input(arg: str) -> bool:
    base = os.path.basename(arg)
    if not (base.endswith(".so") or ".so." in base):
        return False
    if "/lib/swift/macosx/" in arg.replace("\\", "/"):
        return False
    prefixes = (
        "/usr/lib/llvm-",
        "/usr/lib/",
        "/lib/",
        "/usr/bin/../lib",
    )
    return arg.startswith(prefixes)


def _drop_libdir(arg: str) -> bool:
    if not arg.startswith("-L"):
        return False
    path = arg[2:]
    if "/lib/swift/macosx" in path and "/usr/bin/" not in path:
        return False
    if path.startswith("/usr/lib/llvm-"):
        return True
    if path.startswith("/usr/bin/") or path.startswith("/usr/lib/x86_64-linux"):
        return True
    if path in ("/usr/lib", "/lib", "/usr/lib64", "/lib64"):
        return True
    return False


def rewrite_darwin_shared(argv: list[str]) -> list[str]:
    """Return clang++ argv for a Mach-O dylib link (same intent as link_macho_dylib.sh)."""
    out: list[str] = []
    skip_next = False
    have_fuse = False
    have_B = False
    have_dynamiclib = False
    have_nostdlib = False
    have_undef = False
    have_lSystem = False
    have_lcxx = False
    have_lobjc = False
    i = 0
    while i < len(argv):
        a = argv[i]
        i += 1
        if skip_next:
            skip_next = False
            continue
        if a == "-shared":
            continue
        if a == "-dynamiclib":
            have_dynamiclib = True
            out.append(a)
            continue
        if a == "-fuse-ld=lld" or a.startswith("-fuse-ld=lld"):
            have_fuse = True
            out.append("-fuse-ld=lld")
            continue
        if a.startswith("-fuse-ld="):
            # Never pass gold / bfd through a Darwin-target link.
            have_fuse = True
            out.append("-fuse-ld=lld")
            continue
        if a.startswith("-B"):
            have_B = True
            out.append(f"-B{_lld_bin()}")
            continue
        if a == "-Wl,-soname" or a == "-soname":
            # Convert GNU soname to Darwin install_name; consume the next arg.
            if i < len(argv):
                soname = argv[i]
                i += 1
                out.append(f"-Wl,-install_name,{soname}")
            continue
        if a.startswith("-Wl,-soname,"):
            out.append("-Wl,-install_name," + a[len("-Wl,-soname,"):])
            continue
        if a.startswith("-Wl,-rpath-link"):
            continue
        if a == "-Wl,-rpath-link":
            skip_next = True
            continue
        if a in ("-lstdc++", "-lgcc_s", "-lgcc", "-lc", "-ldl", "-lpthread", "-lm"):
            continue
        if a == "-lSystem":
            have_lSystem = True
            out.append(a)
            continue
        if a == "-lc++":
            have_lcxx = True
            out.append(a)
            continue
        if a == "-lobjc":
            have_lobjc = True
            out.append(a)
            continue
        if a == "-nostdlib":
            have_nostdlib = True
            out.append(a)
            continue
        if a in ("-Wl,-undefined,dynamic_lookup", "-undefined"):
            if a == "-undefined":
                if i < len(argv):
                    i += 1
            have_undef = True
            out.append("-Wl,-undefined,dynamic_lookup")
            continue
        if _drop_libdir(a):
            continue
        if not a.startswith("-") and _is_host_elf_input(a):
            continue
        out.append(a)

    extra: list[str] = []
    if not have_dynamiclib:
        extra.append("-dynamiclib")
    if not have_fuse:
        extra.append("-fuse-ld=lld")
    if not have_B:
        extra.append(f"-B{_lld_bin()}")
    if not have_nostdlib:
        extra.append("-nostdlib")
    if not have_lSystem:
        extra.append("-lSystem")
    if not have_lobjc:
        extra.append("-lobjc")
    if not have_lcxx:
        extra.append("-lc++")
    if not have_undef:
        extra.append("-Wl,-undefined,dynamic_lookup")

    # Insert Darwin link extras after the compiler's own flags but before objects.
    # Putting them at the end is what link_macho_dylib.sh does and is enough
    # for ld64.lld to resolve -lSystem from the sysroot -L path already in argv.
    return out + extra


def main(argv: list[str]) -> int:
    real = _real_clangxx()
    # argv[0] is this script; clang++ driver args follow.
    args = argv[1:]
    if is_darwin_shared_link(args):
        args = rewrite_darwin_shared(args)
        if os.environ.get("SWIFTCORE_CLANGXX_LOG"):
            sys.stderr.write("clangxx_darwin_link: Darwin shared rewrite\n")
            sys.stderr.write("  " + " ".join(args) + "\n")
    if os.environ.get("SWIFTCORE_CLANGXX_PRINT_REWRITTEN"):
        print(" ".join(args))
        return 0
    os.execv(real, [real] + args)
    return 127


if __name__ == "__main__":
    raise SystemExit(main(sys.argv))
