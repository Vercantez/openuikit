#!/usr/bin/env python3
"""clang++ / clang driver shim: pick the linker from `-target`, not `.so`.

Linux CMake names the Darwin-target stdlib `libswiftCore.so`
(CMAKE_SHARED_LIBRARY_SUFFIX). That file is the Mach-O dylib guests load;
clang's Darwin driver already emits `-dynamic -dylib -arch -syslibroot
-platform_version` from `-target …-apple-…` and `-isysroot …MacOSX.sdk`.
Forcing ld.lld at that argv made:

    ld.lld: error: unknown argument '-dynamic' / '-dylib' / '-arch' / '-syslibroot'

Apple triple → exec the real clang++ with the original argv plus
`--ld-path=` and keep `-fuse-ld=lld` so the Darwin driver still emits
`-platform_version`/`-arch`. Replacing `-fuse-ld=lld` with `--ld-path=`
alone made ld64.lld fail `must specify -platform_version`.
Linux/unknown-linux-gnu → ld.lld, keep `-soname`.
`-soname` is rewritten to `-install_name` only so ld64 never sees the GNU
flag; nothing else is rewritten (PR #40's -dynamiclib/-nostdlib pass
dropped -platform_version/-arch).
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
    """Drop -fuse-ld=* / --ld-path=* and set `--ld-path=<absolute linker>` once.

    ELF only. Darwin must keep `-fuse-ld=lld` (see darwin_driver_argv).
    """
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


def _output_is_dylib(path: str) -> bool:
    return os.path.basename(path).endswith(".dylib")


def link_flavor(argv: list[str]) -> str | None:
    """Classify from `-target`: apple → darwin, linux → elf. Not from `.so`."""
    if _is_compile(argv):
        return None
    if not (_is_shared(argv) or _has_soname_flag(argv)):
        return None
    t = _target(argv)
    if t and APPLE_MARKER in t:
        return "darwin"
    if t and ("linux" in t.lower() or "unknown-linux" in t.lower()):
        return "elf"
    if any("MacOSX.sdk" in a for a in argv):
        return "darwin"
    out = _output_path(argv) or ""
    if _output_is_dylib(out):
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


def _darwin_install_name(soname: str) -> str:
    """Map Linux CMake soname libswiftX.so to the Darwin LC_ID_DYLIB guests load."""
    base = os.path.basename(soname)
    if base.startswith("libswift") and base.endswith(".so"):
        return "/usr/lib/swift/" + base[: -len(".so")] + ".dylib"
    if base.startswith("libswift") and base.endswith(".dylib") and not soname.startswith("/"):
        return "/usr/lib/swift/" + base
    return soname


def _take_next_value(argv: list[str], i: int) -> tuple[str, int]:
    """Consume the next argv as a linker value, unwrapping a leading -Xlinker."""
    if i >= len(argv):
        return "", i
    if argv[i] == "-Xlinker" and i + 1 < len(argv):
        return argv[i + 1], i + 2
    return argv[i], i + 1


def rewrite_darwin_soname(argv: list[str]) -> list[str]:
    """Map GNU -soname to Darwin -install_name; keep every other driver flag."""
    out: list[str] = []
    i = 0
    while i < len(argv):
        a = argv[i]
        i += 1
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
        out.append(a)
    return out


def darwin_driver_argv(argv: list[str]) -> list[str]:
    """Exec clang++ with the original driver argv plus linker resolution.

    Do not re-issue the Mach-O link. Clang's Darwin driver turns
    -target/-isysroot/-shared/-fuse-ld=lld into
    -dynamic/-dylib/-arch/-syslibroot/-platform_version for ld64.
    Replacing `-fuse-ld=lld` with `--ld-path=<ld64.lld>` alone made the
    driver emit `-macosx_version_min` instead of `-platform_version`, so
    ld64.lld failed with `must specify -platform_version` / `missing -arch`.
    Keep `-fuse-ld=lld` (drop gold) and add `--ld-path=` so resolution
    hits ld64.lld. Translate GNU `-soname` only if it is still in argv.
    """
    out = rewrite_darwin_soname(argv) if _has_soname_flag(argv) else list(argv)
    kept: list[str] = []
    saw_fuse_lld = False
    saw_ld64_path = False
    ld_path = _ld_path_flag(_ld64_lld())
    for a in out:
        if a.startswith("-fuse-ld="):
            val = a.split("=", 1)[1]
            base = os.path.basename(val.rstrip("/"))
            if val == "lld" or base in ("ld64.lld", "ld64.lld-18"):
                if not saw_fuse_lld:
                    kept.append("-fuse-ld=lld")
                    saw_fuse_lld = True
            # gold / bfd / -fuse-ld=<absolute path>: drop. Darwin maps
            # the name `lld` to ld64.lld; an absolute -fuse-ld= is deprecated
            # and skips -platform_version the same way --ld-path-alone does.
            continue
        if a.startswith("--ld-path="):
            path = a.split("=", 1)[1]
            if "ld64" in os.path.basename(path):
                if not saw_ld64_path:
                    kept.append(ld_path)
                    saw_ld64_path = True
            continue
        kept.append(a)
    if not saw_fuse_lld:
        kept.append("-fuse-ld=lld")
    if not saw_ld64_path:
        kept.append(ld_path)
    return kept


def rewrite_darwin_shared(argv: list[str]) -> list[str]:
    """Back-compat name: Darwin is driver pass-through, not a Mach-O rewrite."""
    return darwin_driver_argv(argv)


def log_link(
    kind: str,
    linker: str,
    original: list[str],
    *,
    driver_argv: list[str] | None = None,
    rewritten: list[str] | None = None,
) -> None:
    out = _output_path(original) or "ABSENT"
    # One line the operator can grep: -o and the decision together.
    sys.stderr.write(f"clangxx_darwin_link: -o {out} decision={kind} linker={linker}\n")
    sys.stderr.write("clangxx_darwin_link: ninja argv: " + shlex.join(original) + "\n")
    if kind == "darwin":
        # Never log "rewritten argv" for Darwin — that was the re-issued
        # link that dropped driver -platform_version/-arch.
        if driver_argv is not None:
            sys.stderr.write(
                "clangxx_darwin_link: driver argv: " + shlex.join(driver_argv) + "\n"
            )
    elif rewritten is not None:
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
        driver_argv = darwin_driver_argv(args)
        log_link("darwin", linker_label(_ld64_lld()), args, driver_argv=driver_argv)
        if print_rewritten:
            print(" ".join(driver_argv))
            return 0
        rc = _run_compiler(real, driver_argv)
        if rc == 0:
            mirror_so_to_dylib(driver_argv)
        return rc
    if flavor == "elf":
        rewritten = rewrite_elf_shared(args)
        log_link("elf", linker_label(_ld_lld()), args, rewritten=rewritten)
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
