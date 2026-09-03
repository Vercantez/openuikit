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
`-platform_version`/`-arch`. CMake `LINK_PATH` starts with
`-L/usr/lib/llvm-18/lib`; drop that on Darwin links and pass
`-nostdlib++` plus the sysroot `usr/lib/libc++.tbd` / `libc++abi.tbd`
so ld64 never opens the host ELF `libc++.so`. Print
`cxx_runtime=<tbd>`. Pass `libclang_rt.osx.a` (compiler-rt
generic Darwin builtins, including `__isPlatformVersionAtLeast` /
`__divti3`) and print `compiler_rt=<archive>`. Linux/unknown-linux-gnu
→ ld.lld, keep `-soname`.
`-soname` is rewritten to `-install_name` only so ld64 never sees the GNU
flag; nothing else is rewritten (PR #40's -dynamiclib/-nostdlib pass
dropped -platform_version/-arch).
"""
from __future__ import annotations

import os
import re
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


def _isysroot(argv: list[str]) -> str | None:
    for i, a in enumerate(argv):
        if a in ("-isysroot", "--sysroot") and i + 1 < len(argv):
            return argv[i + 1]
        if a.startswith("-isysroot="):
            return a.split("=", 1)[1]
        if a.startswith("--sysroot="):
            return a.split("=", 1)[1]
    return None


def _host_elf_cxx_libdir(path: str) -> bool:
    """True if `path` is a Linux libc++ search dir (ELF libc++.so / llvm-*/lib)."""
    if not path:
        return False
    p = os.path.normpath(path).replace("\\", "/").rstrip("/")
    if p.endswith("/llvm-18/lib") or p.endswith("/llvm-19/lib") or "/llvm-18/lib/" in p + "/":
        return True
    # CMake LINK_PATH puts this first; ld64 then opens ELF libc++.so.
    if os.path.isfile(os.path.join(p, "libc++.so")):
        return True
    return False


def _strip_host_cxx_libdirs(argv: list[str]) -> list[str]:
    """Drop -L/-B to host llvm-*/lib so ld64 never sees ELF libc++.so.

    Keep `-B/usr/lib/llvm-18/bin` (linker tools). Only the *lib* dir is poison.
    """
    out: list[str] = []
    i = 0
    while i < len(argv):
        a = argv[i]
        i += 1
        if a in ("-L", "-B") and i < len(argv):
            path = argv[i]
            if a == "-B" and not _host_elf_cxx_libdir(path):
                out.append(a)
                out.append(path)
                i += 1
                continue
            if _host_elf_cxx_libdir(path):
                i += 1
                continue
            out.append(a)
            out.append(path)
            i += 1
            continue
        if a.startswith("-L"):
            path = a[2:]
            if path.startswith("="):
                path = path[1:]
            if _host_elf_cxx_libdir(path):
                continue
        if a.startswith("-B") and not a.startswith("-Bdynamic") and not a.startswith("-Bstatic"):
            path = a[2:]
            if path.startswith("="):
                path = path[1:]
            if _host_elf_cxx_libdir(path):
                continue
        if a.startswith("-Wl,"):
            parts = a.split(",")
            # -Wl,-L,/usr/lib/llvm-18/lib  or -Wl,-rpath-link,/usr/lib/llvm-18/lib
            skip = False
            # ld64.lld has no -rpath-link at all (ELF-only); measured 2026-09-03:
            # swiftObservation's link died "unknown argument '-rpath-link'" on a
            # non-llvm-18 path. Drop it regardless of the directory.
            if "-rpath-link" in parts:
                skip = True
            for j, p in enumerate(parts):
                if p in ("-L", "-rpath-link", "-rpath") and j + 1 < len(parts):
                    if _host_elf_cxx_libdir(parts[j + 1]):
                        skip = True
                        break
                if p.startswith("-L") and _host_elf_cxx_libdir(p[2:]):
                    skip = True
                    break
            if skip:
                continue
        out.append(a)
    return out


def darwin_cxx_tbds(argv: list[str]) -> list[str]:
    """Sysroot libc++ / libc++abi tbds the Darwin link must use (not host .so)."""
    root = _isysroot(argv)
    if not root:
        return []
    tbds = []
    for name in ("libc++.tbd", "libc++abi.tbd"):
        cand = os.path.join(root, "usr/lib", name)
        tbds.append(cand)
    return tbds


def darwin_cxx_runtime_path(argv: list[str]) -> str:
    tbds = darwin_cxx_tbds(argv)
    return tbds[0] if tbds else "ABSENT"


# Apple's libswiftDarwin.dylib LC_REEXPORT_DYLIB set (measured on the
# x86_64 extract). Only Darwin; no other overlay grows re-exports.
DARWIN_REEXPORT_SHELLS = (
    "libswift_Builtin_float",
    "libswift_DarwinFoundation1",
    "libswift_DarwinFoundation2",
    "libswift_DarwinFoundation3",
)


def _is_libswift_darwin_output(path: str | None) -> bool:
    if not path:
        return False
    base = os.path.basename(path)
    return base in ("libswiftDarwin.dylib", "libswiftDarwin.so")


def _search_dirs_for_reexport(argv: list[str], out_path: str | None) -> list[str]:
    dirs: list[str] = []
    seen: set[str] = set()

    def add(p: str) -> None:
        if not p:
            return
        n = os.path.normpath(p)
        if n in seen:
            return
        seen.add(n)
        dirs.append(n)

    if out_path:
        d = os.path.dirname(os.path.abspath(out_path))
        add(d)
        add(os.path.dirname(d))
    i = 0
    while i < len(argv):
        a = argv[i]
        i += 1
        if a in ("-L", "-Wl,-L") and i < len(argv):
            add(argv[i])
            i += 1
            continue
        if a.startswith("-L") and len(a) > 2:
            add(a[2:])
            continue
        if a.startswith("-Wl,-L,"):
            add(a.split(",", 2)[-1])
    return dirs


def find_darwin_reexport_shells(argv: list[str]) -> list[str]:
    """Absolute paths of the four Darwin re-export shells, or [].

    All four must exist (Apple's LC_REEXPORT_DYLIB set is exactly these).
    Prefer .dylib over the ninja .so sibling.
    """
    if not _is_libswift_darwin_output(_output_path(argv)):
        return []
    dirs = _search_dirs_for_reexport(argv, _output_path(argv))
    found: list[str] = []
    for name in DARWIN_REEXPORT_SHELLS:
        hit = ""
        for d in dirs:
            for ext in (".dylib", ".so"):
                cand = os.path.join(d, name + ext)
                if os.path.isfile(cand):
                    hit = cand
                    break
            if hit:
                break
        if not hit:
            return []
        found.append(hit)
    return found


def darwin_reexport_link_flags(argv: list[str]) -> list[str]:
    """-Xlinker -reexport_library for Apple's four Darwin shells.

    Only when linking libswiftDarwin and all four dylibs are on disk.
    Do not -reexport any other overlay.
    """
    paths = find_darwin_reexport_shells(argv)
    if not paths:
        return []
    flags: list[str] = []
    for p in paths:
        flags.extend(["-Xlinker", "-reexport_library", "-Xlinker", p])
    return flags


# lld honours Apple's `$ld$previous$<name>$$<compat>$<start>$<end>$$` symbols:
# our built libswift_Builtin_float carries
# `$ld$previous$/usr/lib/swift/libswiftDarwin.dylib$$1$10.14.4$15.0$$`, so a
# libswiftDarwin link at the CMake deployment target (macosx13.0) records the
# Builtin_float re-export under the PREVIOUS name -- a self LC_REEXPORT of
# libswiftDarwin and no Builtin_float (measured on the x86_64 box 2026-09-03:
# target 13.0 -> [libswiftDarwin, DF1, DF2, DF3]; 15.0 -> Apple's four).
# Link libswiftDarwin at the platform floor every guest links against.
DARWIN_REEXPORT_MIN_DEPLOYMENT = "15.0"


def raise_darwin_deployment_target(argv: list[str]) -> list[str]:
    """When linking libswiftDarwin with the four shells, lift `-target
    <arch>-apple-macosx<ver>` to macosx15.0 so `$ld$previous` ranges ending at
    15.0 cannot rename the Builtin_float re-export. Other links untouched."""
    if not find_darwin_reexport_shells(argv):
        return argv
    out: list[str] = []
    i = 0
    changed = None
    pat = re.compile(r"^((?:--target=)?[^-]+-apple-macosx)(\d+(?:\.\d+)*)$")
    while i < len(argv):
        a = argv[i]
        if a in ("-target", "--target") and i + 1 < len(argv):
            m = pat.match(argv[i + 1])
            if m and _version_lt(m.group(2), DARWIN_REEXPORT_MIN_DEPLOYMENT):
                changed = (argv[i + 1], m.group(1) + DARWIN_REEXPORT_MIN_DEPLOYMENT)
                out.extend([a, changed[1]])
                i += 2
                continue
        m = pat.match(a)
        if m and a.startswith("--target=") and _version_lt(m.group(2), DARWIN_REEXPORT_MIN_DEPLOYMENT):
            changed = (a, m.group(1) + DARWIN_REEXPORT_MIN_DEPLOYMENT)
            out.append(changed[1])
            i += 1
            continue
        out.append(a)
        i += 1
    if changed:
        sys.stderr.write(
            f"clangxx_darwin_link: libswiftDarwin deployment {changed[0]} -> {changed[1]} "
            "(so $ld$previous cannot rename the Builtin_float re-export)\n"
        )
    return out


def _version_lt(a: str, b: str) -> bool:
    pa = [int(x) for x in a.split(".")]
    pb = [int(x) for x in b.split(".")]
    n = max(len(pa), len(pb))
    pa += [0] * (n - len(pa)); pb += [0] * (n - len(pb))
    return pa < pb


def darwin_compiler_rt_osx_path() -> str:
    """Darwin-target compiler-rt builtins archive (generic C + os_version_check)."""
    env = os.environ.get("SWIFTCORE_COMPILER_RT_OSX")
    if env:
        return env
    work = os.environ.get("SWIFTCORE_WORK") or os.path.join(
        os.path.expanduser("~"), "work"
    )
    return os.path.join(work, "build", "libclang_rt.osx.a")


def darwin_compiler_rt_link_flags(argv: list[str]) -> list[str]:
    """Pass Darwin compiler-rt builtins so availability checks resolve.

    Linux clang has no libclang_rt.osx.a in its resource dir. Overlay links
    are NOUNDEFS (no -undefined dynamic_lookup), so clang's
    __isPlatformVersionAtLeast must come from this archive — not libSystem
    (gen_tbd CHECK 4 vs libswiftcompat) and not a glibc host-bind.

    Do not -force_load: that would pull the member into every Darwin dylib
    (including ones that never emit an availability check) and surface any
    leftover undefineds from the TU. Regular archive search is enough when
    the object refs the symbol.
    """
    path = darwin_compiler_rt_osx_path()
    if any("libclang_rt.osx.a" in a for a in argv):
        return []
    return [path]


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

    CMake LINK_PATH puts `-L/usr/lib/llvm-18/lib` first; the driver's
    `-stdlib=libc++` then hands ld64.lld the host ELF `libc++.so`
    (`unhandled file type`). Drop that -L/-B, pass `-nostdlib++`, and
    add the sysroot `usr/lib/libc++.tbd` / `libc++abi.tbd`.
    """
    out = rewrite_darwin_soname(argv) if _has_soname_flag(argv) else list(argv)
    out = _strip_host_cxx_libdirs(out)
    kept: list[str] = []
    saw_fuse_lld = False
    saw_ld64_path = False
    saw_nostdlibxx = False
    ld_path = _ld_path_flag(_ld64_lld())
    tbds = darwin_cxx_tbds(out)
    tbd_set = set(tbds)
    for a in out:
        if a.startswith("-fuse-ld="):
            val = a.split("=", 1)[1]
            base = os.path.basename(val.rstrip("/"))
            if val == "lld" or base in ("ld64.lld", "ld64.lld-18"):
                if not saw_fuse_lld:
                    kept.append("-fuse-ld=lld")
                    saw_fuse_lld = True
            continue
        if a.startswith("--ld-path="):
            path = a.split("=", 1)[1]
            if "ld64" in os.path.basename(path):
                if not saw_ld64_path:
                    kept.append(ld_path)
                    saw_ld64_path = True
            continue
        if a == "-nostdlib++":
            saw_nostdlibxx = True
            kept.append(a)
            continue
        # Host -lc++ would still search leftover -L; sysroot tbds replace it.
        if a in ("-lc++", "-lc++abi", "-stdlib=libc++"):
            continue
        if a in tbd_set:
            continue
        kept.append(a)
    if not saw_fuse_lld:
        kept.append("-fuse-ld=lld")
    if not saw_ld64_path:
        kept.append(ld_path)
    if not saw_nostdlibxx:
        kept.append("-nostdlib++")
    for t in tbds:
        kept.append(t)
    kept.extend(darwin_compiler_rt_link_flags(kept))
    kept.extend(darwin_reexport_link_flags(kept))
    kept = raise_darwin_deployment_target(kept)
    # clang ignores argv after -###; keep diagnostics last.
    diag = [a for a in kept if a in ("-###", "-v", "--verbose")]
    if diag:
        kept = [a for a in kept if a not in ("-###", "-v", "--verbose")] + diag
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
        sys.stderr.write(
            f"clangxx_darwin_link: cxx_runtime={darwin_cxx_runtime_path(original)}\n"
        )
        sys.stderr.write(
            f"clangxx_darwin_link: compiler_rt={darwin_compiler_rt_osx_path()}\n"
        )
        shells = find_darwin_reexport_shells(driver_argv or original)
        if shells:
            names = ",".join(os.path.basename(p) for p in shells)
            sys.stderr.write(f"clangxx_darwin_link: darwin_reexport={names}\n")
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
