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

Linux CMake concatenates $SONAME_FLAG$SONAME (`-Wl,-soname,` + `libswiftX.so`)
or emits `-Xlinker -soname`. ld64.lld does not accept `-soname`; rewrite to
`-install_name` and drop `--as-needed` / `-rpath-link`. Always print the
ninja argv and the rewritten argv so the operator log shows both.
"""
from __future__ import annotations

import os
import shlex
import shutil
import subprocess
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
        if a in ("-target", "--target") and i + 1 < len(argv):
            return argv[i + 1]
        if a.startswith("--target="):
            return a.split("=", 1)[1]
    return None


def _is_shared(argv: list[str]) -> bool:
    return (
        "-shared" in argv
        or "-dynamiclib" in argv
        or any(a == "-Wl,-dylib" or a.startswith("-Wl,-dylib,") for a in argv)
    )


def _is_darwin_target(argv: list[str]) -> bool:
    t = _target(argv)
    if t and APPLE_MARKER in t:
        return True
    for a in argv:
        if APPLE_MARKER in a:
            return True
        if "MacOSX.sdk" in a:
            return True
        if a.startswith("-mmacosx-version-min"):
            return True
    return False


def _soname_payload(tok: str) -> str | None:
    """GNU soname flag → payload. Empty string means the value is the next argv."""
    if tok in ("-soname", "-Wl,-soname", "--soname"):
        return ""
    for prefix in (
        "-Wl,-soname,",
        "-Wl,-soname=",
        "-soname,",
        "-soname=",
        "--soname=",
        "--soname,",
    ):
        if tok.startswith(prefix):
            return tok[len(prefix) :]
    return None


def _has_soname_flag(argv: list[str]) -> bool:
    i = 0
    while i < len(argv):
        a = argv[i]
        if _soname_payload(a) is not None:
            return True
        if a == "-Xlinker" and i + 1 < len(argv) and _soname_payload(argv[i + 1]) is not None:
            return True
        i += 1
    return False


def is_darwin_shared_link(argv: list[str]) -> bool:
    if _is_compile(argv):
        return False
    if not _is_darwin_target(argv):
        return False
    return _is_shared(argv) or _has_soname_flag(argv)


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


def _darwin_install_name(soname: str) -> str:
    """Map Linux CMake soname libswiftX.so to the Darwin LC_ID_DYLIB guests load."""
    base = os.path.basename(soname)
    if base.startswith("libswift") and base.endswith(".so"):
        return "/usr/lib/swift/" + base[: -len(".so")] + ".dylib"
    if base.startswith("libswift") and base.endswith(".dylib") and not soname.startswith("/"):
        return "/usr/lib/swift/" + base
    return soname


_ELF_DROP = {
    "--as-needed",
    "-as-needed",
    "-Wl,--as-needed",
    "-Wl,-as-needed",
    "--no-as-needed",
    "-Wl,--no-as-needed",
}


def _take_next_value(argv: list[str], i: int) -> tuple[str, int]:
    """Consume the next argv as a linker value, unwrapping a leading -Xlinker."""
    if i >= len(argv):
        return "", i
    if argv[i] == "-Xlinker" and i + 1 < len(argv):
        return argv[i + 1], i + 2
    return argv[i], i + 1


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
        if a in _ELF_DROP:
            continue
        if a.startswith("-Wl,-rpath-link") or a in ("-rpath-link", "-Wl,-rpath-link"):
            if a in ("-rpath-link", "-Wl,-rpath-link") and not a.startswith("-Wl,-rpath-link,"):
                skip_next = True
            continue
        if a == "-Xlinker" and i < len(argv):
            nxt = argv[i]
            sn = _soname_payload(nxt)
            if sn is not None:
                i += 1
                if sn == "":
                    sn, i = _take_next_value(argv, i)
                if sn:
                    out.append(f"-Wl,-install_name,{_darwin_install_name(sn)}")
                continue
            if nxt in _ELF_DROP or nxt.startswith("-rpath-link") or nxt.startswith("--rpath-link"):
                i += 1
                continue
            out.append(a)
            out.append(nxt)
            i += 1
            continue
        sn = _soname_payload(a)
        if sn is not None:
            if sn == "":
                sn, i = _take_next_value(argv, i)
            if sn:
                out.append(f"-Wl,-install_name,{_darwin_install_name(sn)}")
            continue
        if a.startswith("-Wl,-install_name,"):
            out.append(
                "-Wl,-install_name," + _darwin_install_name(a[len("-Wl,-install_name,"):])
            )
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

    rewritten = out + extra
    return _drop_leftover_elf_link_flags(rewritten)


def _drop_leftover_elf_link_flags(argv: list[str]) -> list[str]:
    """Last pass: ld64.lld must never see -soname / --as-needed / -rpath-link."""
    out: list[str] = []
    i = 0
    while i < len(argv):
        a = argv[i]
        i += 1
        if a in _ELF_DROP:
            continue
        if a.startswith("-Wl,-rpath-link") or a in ("-rpath-link",):
            continue
        if _soname_payload(a) is not None:
            if _soname_payload(a) == "":
                if i < len(argv) and argv[i] == "-Xlinker":
                    i += 1
                if i < len(argv):
                    i += 1
            continue
        if a == "-Xlinker" and i < len(argv):
            nxt = argv[i]
            if _soname_payload(nxt) is not None or nxt in _ELF_DROP or nxt.startswith("-rpath-link"):
                i += 1
                if _soname_payload(nxt) == "":
                    if i < len(argv) and argv[i] == "-Xlinker":
                        i += 1
                    if i < len(argv):
                        i += 1
                continue
        out.append(a)
    return out


def log_darwin_rewrite(original: list[str], rewritten: list[str]) -> None:
    sys.stderr.write("clangxx_darwin_link: ninja argv: " + shlex.join(original) + "\n")
    sys.stderr.write("clangxx_darwin_link: rewritten argv: " + shlex.join(rewritten) + "\n")
    sys.stderr.flush()


def _output_path(argv: list[str]) -> str | None:
    for i, a in enumerate(argv):
        if a == "-o" and i + 1 < len(argv):
            return argv[i + 1]
        if a.startswith("-o") and len(a) > 2:
            return a[2:]
    return None


def mirror_so_to_dylib(argv: list[str]) -> None:
    """Ninja names Darwin dylibs .so; phase2 / stage_artifacts want .dylib."""
    out = _output_path(argv)
    if not out or not out.endswith(".so"):
        return
    if "/lib/swift/macosx/" not in out.replace("\\", "/"):
        return
    if not os.path.isfile(out):
        return
    dylib = out[: -len(".so")] + ".dylib"
    shutil.copy2(out, dylib)


def main(argv: list[str]) -> int:
    real = _real_clangxx()
    # argv[0] is this script; clang++ driver args follow.
    args = argv[1:]
    if is_darwin_shared_link(args):
        rewritten = rewrite_darwin_shared(args)
        log_darwin_rewrite(args, rewritten)
        if os.environ.get("SWIFTCORE_CLANGXX_PRINT_REWRITTEN"):
            print(" ".join(rewritten))
            return 0
        rc = subprocess.call([real] + rewritten)
        if rc == 0:
            mirror_so_to_dylib(rewritten)
        return rc
    if os.environ.get("SWIFTCORE_CLANGXX_PRINT_REWRITTEN"):
        print(" ".join(args))
        return 0
    os.execv(real, [real] + args)
    return 127


if __name__ == "__main__":
    raise SystemExit(main(sys.argv))
