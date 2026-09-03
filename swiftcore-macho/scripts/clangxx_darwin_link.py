#!/usr/bin/env python3
"""clang++ / clang driver shim: pick the linker per OUTPUT FILE, not globally.

Classify from `-o`:
  `*.so`  → ELF / ld.lld, keep `-soname`
  `*.dylib` (or `-install_name` / apple triple) → Darwin / ld64.lld

Never from directory names (`macosx` in the path is the Darwin-target
stdlib's host-side ELF helper). Clang 18+ wants `--ld-path=` rather than
`-fuse-ld=<absolute path>`. Every shared link prints one line:

    clangxx_darwin_link: -o <path> decision=elf|darwin linker=ld.lld|ld64.lld
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


def _real_clang() -> str:
    env = os.environ.get("SWIFTCORE_REAL_CLANG")
    if env:
        return env
    tc = os.environ.get("TC")
    if tc:
        cand = os.path.join(tc, "bin", "clang")
        if os.path.isfile(cand) and os.access(cand, os.X_OK):
            return cand
    return "/usr/bin/clang"


def _real_compiler() -> str:
    driver = os.environ.get("SWIFTCORE_CLANG_DRIVER", "clang++")
    if driver.endswith("++"):
        return _real_clangxx()
    return _real_clang()


def _lld_bin() -> str:
    return os.environ.get("LLD_BIN") or "/usr/lib/llvm-18/bin"


def _ld_lld() -> str:
    env = os.environ.get("LD_LLD")
    if env:
        return env
    return os.path.join(_lld_bin(), "ld.lld")


def _ld64_lld() -> str:
    env = os.environ.get("LD64_LLD")
    if env:
        return env
    for name in ("ld64.lld", "ld64.lld-18"):
        cand = os.path.join(_lld_bin(), name)
        if os.path.isfile(cand):
            return cand
    return os.path.join(_lld_bin(), "ld64.lld")


def linker_label(path: str) -> str:
    base = os.path.basename(path)
    if "ld64" in base:
        return "ld64.lld"
    if base.startswith("ld.lld") or base == "ld.lld":
        return "ld.lld"
    return base or path


def _ld_path_flag(linker_path: str) -> str:
    """Clang 18+: `--ld-path=` is the non-deprecated way to pass an absolute linker."""
    return f"--ld-path={linker_path}"


def _is_linker_select_flag(tok: str) -> bool:
    return tok.startswith("-fuse-ld=") or tok.startswith("--ld-path=")


def _set_ld_path(argv: list[str], linker_path: str) -> list[str]:
    """Drop -fuse-ld=* / --ld-path=* and set `--ld-path=<absolute linker>` once."""
    out: list[str] = []
    replaced = False
    flag = _ld_path_flag(linker_path)
    for a in argv:
        if _is_linker_select_flag(a):
            if not replaced:
                out.append(flag)
                replaced = True
            continue
        out.append(a)
    if not replaced:
        out.append(flag)
    return out


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


def _output_path(argv: list[str]) -> str | None:
    for i, a in enumerate(argv):
        if a == "-o" and i + 1 < len(argv):
            return argv[i + 1]
        if a.startswith("-o") and len(a) > 2:
            return a[2:]
    return None


def _output_is_elf_so(path: str) -> bool:
    """True for a shared-object output. Basename only — never the directory."""
    base = os.path.basename(path)
    return base.endswith(".so") or ".so." in base


def _output_is_dylib(path: str) -> bool:
    return os.path.basename(path).endswith(".dylib")


def _has_install_name(argv: list[str]) -> bool:
    for i, a in enumerate(argv):
        if a.startswith("-Wl,-install_name") or a.startswith("-install_name"):
            return True
        if a in ("-install_name", "-Wl,-install_name") and i + 1 < len(argv):
            return True
        if a == "-Xlinker" and i + 1 < len(argv) and "install_name" in argv[i + 1]:
            return True
    return False


def link_flavor(argv: list[str]) -> str | None:
    """Classify a driver invocation: 'darwin', 'elf', or None (not a shared link).

    Output file first: `-o …*.so` is always ELF (the Darwin-target stdlib's
    host-side helper is still named libswiftCore.so and lives under macosx/).
    `.dylib`, `-install_name`, or an apple triple selects ld64.lld.
    """
    if _is_compile(argv):
        return None
    if not (_is_shared(argv) or _has_soname_flag(argv)):
        return None
    out = _output_path(argv) or ""
    if _output_is_elf_so(out):
        return "elf"
    if _output_is_dylib(out):
        return "darwin"
    if _has_install_name(argv):
        return "darwin"
    t = _target(argv)
    if t and APPLE_MARKER in t:
        return "darwin"
    if "-dynamiclib" in argv:
        return "darwin"
    return "elf"


def _is_darwin_target(argv: list[str]) -> bool:
    return link_flavor(argv) == "darwin"


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
    return link_flavor(argv) == "darwin"


def rewrite_elf_shared(argv: list[str]) -> list[str]:
    """ELF shared link: keep -soname / -shared; force ld.lld (never ld64.lld)."""
    return _set_ld_path(argv, _ld_lld())


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
        if _is_linker_select_flag(a):
            # Darwin-target: --ld-path=ld64.lld, never gold / host ld.lld.
            have_fuse = True
            out.append(_ld_path_flag(_ld64_lld()))
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
        extra.append(_ld_path_flag(_ld64_lld()))
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


def log_link(
    kind: str,
    linker: str,
    original: list[str],
    rewritten: list[str] | None = None,
) -> None:
    out = _output_path(original) or "ABSENT"
    # One line the operator can grep: -o and the decision together.
    sys.stderr.write(f"clangxx_darwin_link: -o {out} decision={kind} linker={linker}\n")
    sys.stderr.write("clangxx_darwin_link: ninja argv: " + shlex.join(original) + "\n")
    if rewritten is not None:
        sys.stderr.write("clangxx_darwin_link: rewritten argv: " + shlex.join(rewritten) + "\n")
    sys.stderr.flush()


def _run_compiler(real: str, compiler_argv: list[str]) -> int:
    """Invoke the real clang/clang++. Map exec failures so ninja does not see a bare 126."""
    if not os.path.isfile(real):
        sys.stderr.write(f"CANNOT_COMPILER_NOT_EXECUTABLE path={real} reason=missing\n")
        return 2
    if not os.access(real, os.X_OK):
        sys.stderr.write(
            f"CANNOT_COMPILER_NOT_EXECUTABLE path={real} reason=not-executable "
            "(bash/ninja would report rc=126)\n"
        )
        return 2
    try:
        rc = subprocess.call([real] + compiler_argv)
    except OSError as e:
        sys.stderr.write(
            f"CANNOT_COMPILER_NOT_EXECUTABLE path={real} errno={e.errno} {e}\n"
        )
        return 2
    if rc == 126:
        sys.stderr.write(
            f"clangxx_darwin_link: compiler rc=126 (not executable / ENOEXEC) path={real}\n"
        )
    return rc


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
    real = _real_compiler()
    # argv[0] is this script; clang++ / clang driver args follow.
    args = argv[1:]
    flavor = link_flavor(args)
    print_rewritten = bool(os.environ.get("SWIFTCORE_CLANGXX_PRINT_REWRITTEN"))
    if flavor == "darwin":
        rewritten = rewrite_darwin_shared(args)
        log_link("darwin", linker_label(_ld64_lld()), args, rewritten)
        if print_rewritten:
            print(" ".join(rewritten))
            return 0
        rc = _run_compiler(real, rewritten)
        if rc == 0:
            mirror_so_to_dylib(rewritten)
        return rc
    if flavor == "elf":
        rewritten = rewrite_elf_shared(args)
        log_link("elf", linker_label(_ld_lld()), args, rewritten)
        if print_rewritten:
            print(" ".join(rewritten))
            return 0
        return _run_compiler(real, rewritten)
    if print_rewritten:
        print(" ".join(args))
        return 0
    return _run_compiler(real, args)


if __name__ == "__main__":
    raise SystemExit(main(sys.argv))
