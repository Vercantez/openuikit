#!/usr/bin/env python3
"""Materialize a verify tree from env/contract.json on any host.

Idempotent: rerun = verify. Fixes (chown/mode/safe.directory/stage) are
printed explicitly. Honest per-host inability uses the marker vocabulary
in scripts/env/markers.py. Does not rewrite PR #3 .cursor scripts: corpus
clones go through .cursor/clone-pinned-repo.sh.

When a gate sources this (default, not --strict) remaining unsatisfied
rows are reported and the process exits 0 so the gate's original refusal
text stays the behavior oracle. --strict exits 2 if this host still owes
a row it is expected to satisfy.
"""

from __future__ import annotations

import argparse
import json
import os
from pathlib import Path
import shutil
import stat
import subprocess
import sys
import tempfile

if __package__ in (None, ""):
    sys.path.insert(0, str(Path(__file__).resolve().parent))
    from contract import demanded_by, load_contract, repo_root_from
    from ledger import sha256_file
else:
    from .contract import demanded_by, load_contract, repo_root_from
    from .ledger import sha256_file


class PrepareError(RuntimeError):
    pass


def _run(argv: list[str], cwd: Path | None = None) -> subprocess.CompletedProcess[str]:
    return subprocess.run(
        argv,
        cwd=cwd,
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
        text=True,
        check=False,
    )


def host_arch() -> str:
    return os.uname().machine


def host_os() -> str:
    return os.uname().sysname


def expected_cannot_for_host(contract: dict, arch: str, system: str) -> list[str]:
    if system == "Darwin":
        return list(contract["hosts"]["macos-oracle"]["expected_cannot"])
    if arch in ("aarch64", "arm64"):
        return list(contract["hosts"]["ec2-aarch64"]["expected_cannot"])
    return list(contract["hosts"]["cursor-x86_64"]["expected_cannot"])


def which(name: str) -> str | None:
    return shutil.which(name)


class Outcome:
    def __init__(
        self,
        status: str,
        ident: str,
        detail: str,
        marker: str | None = None,
    ) -> None:
        self.status = status
        self.id = ident
        self.detail = detail
        self.marker = marker

    def line(self) -> str:
        marker = f" marker={self.marker}" if self.marker else ""
        return f"ENV_PREPARE_{self.status.upper()} id={self.id} {self.detail}{marker}"


def git_global_safe_directories() -> list[str]:
    result = _run(["git", "config", "--global", "--get-all", "safe.directory"])
    if result.returncode not in (0, 1):
        return []
    return [line for line in result.stdout.splitlines() if line]


def ensure_safe_directory(path: Path) -> Outcome:
    resolved = str(path.resolve())
    existing = git_global_safe_directories()
    if resolved in existing or "*" in existing:
        return Outcome("satisfied", "git-safe-directory", f"path={resolved} reused=1")
    added = _run(["git", "config", "--global", "--add", "safe.directory", resolved])
    if added.returncode != 0:
        return Outcome(
            "cannot",
            "git-safe-directory",
            f"path={resolved} {added.stderr.strip()}",
            marker=None,
        )
    return Outcome("satisfied", "git-safe-directory", f"path={resolved} added=1")


def ensure_mode_0700(path: Path, ident: str) -> Outcome:
    path.mkdir(parents=True, exist_ok=True)
    metadata = path.lstat()
    if stat.S_ISLNK(metadata.st_mode):
        return Outcome("unsatisfied", ident, f"path={path} is a symlink")
    mode = stat.S_IMODE(metadata.st_mode)
    owner_ok = metadata.st_uid == os.geteuid()
    changed = []
    if not owner_ok:
        try:
            os.chown(path, os.geteuid(), -1)
            changed.append("chown")
        except OSError as error:
            return Outcome("unsatisfied", ident, f"path={path} chown failed: {error}")
    if mode & 0o077:
        os.chmod(path, 0o700)
        changed.append("chmod0700")
    if changed:
        return Outcome("satisfied", ident, f"path={path} fixed={','.join(changed)}")
    return Outcome("satisfied", ident, f"path={path} reused=1 mode=0700")


def clone_or_verify_git(
    root: Path, row: dict, verify_only: bool
) -> Outcome:
    dest = Path(row["destination"])
    if not dest.is_absolute():
        dest = root / dest
    ident = row["id"]
    cloner = root / ".cursor" / "clone-pinned-repo.sh"
    lock = root / ".cursor" / "scratch-corpus-pins.json"
    uses_corpus_cloner = row.get("lock") == ".cursor/scratch-corpus-pins.json"
    if dest.is_dir() and (dest / ".git").exists():
        commit = _run(["git", "-c", f"safe.directory={dest}", "-C", str(dest), "rev-parse", "HEAD"])
        tree = _run(
            ["git", "-c", f"safe.directory={dest}", "-C", str(dest), "rev-parse", "HEAD^{tree}"]
        )
        if (
            commit.returncode == 0
            and tree.returncode == 0
            and commit.stdout.strip() == row["commit"]
            and tree.stdout.strip() == row["tree"]
        ):
            return Outcome(
                "satisfied",
                ident,
                f"commit={row['commit']} tree={row['tree']} dest={dest.relative_to(root) if dest.is_relative_to(root) else dest} reused=1",
            )
        return Outcome(
            "unsatisfied",
            ident,
            f"live_commit={commit.stdout.strip() or 'unreadable'} want={row['commit']}",
        )
    if verify_only:
        return Outcome("unsatisfied", ident, f"missing dest={dest}")
    if not uses_corpus_cloner:
        # Build a one-row lock the PR #3 cloner already understands.
        if not str(row["destination"]).startswith("scratch/"):
            return Outcome("cannot", ident, "destination is not under scratch/")
        lock_dir = Path(tempfile.mkdtemp(prefix=".env-contract-lock.", dir=str(root / "scratch" if (root / "scratch").is_dir() else "/tmp")))
        lock = lock_dir / "lock.json"
        lock.write_text(
            json.dumps({"sources": [{
                "id": ident,
                "repository": row["repository"],
                "commit": row["commit"],
                "tree": row["tree"],
                "destination": row["destination"],
            }]}, indent=2)
            + "\n",
            encoding="utf-8",
        )
    if not cloner.is_file():
        return Outcome("cannot", ident, "clone-pinned-repo.sh is missing")
    cloned = _run(
        [
            "bash",
            str(cloner),
            "--lock",
            str(lock),
            "--id",
            ident if uses_corpus_cloner else ident,
            "--repo-root",
            str(root),
        ]
    )
    if cloned.returncode != 0:
        detail = (cloned.stderr or cloned.stdout).strip().splitlines()
        tail = detail[-1] if detail else f"exit {cloned.returncode}"
        return Outcome("unsatisfied", ident, f"clone failed: {tail}")
    return Outcome(
        "satisfied",
        ident,
        f"commit={row['commit']} tree={row['tree']} cloned=1",
    )


def verify_inrepo_tree(root: Path, row: dict) -> Outcome:
    ident = row["id"]
    path = root / row["path"]
    if not path.is_dir() or path.is_symlink():
        return Outcome("unsatisfied", ident, f"missing subtree {path}")
    result = _run(["git", "-C", str(root), "rev-parse", f"HEAD:{row['path']}"])
    if result.returncode != 0:
        return Outcome("unsatisfied", ident, result.stderr.strip() or "rev-parse failed")
    live = result.stdout.strip()
    if live != row["tree"]:
        return Outcome(
            "unsatisfied",
            ident,
            f"live={live} pin={row['tree']} (will not advance vendor_pins.sh)",
        )
    return Outcome("satisfied", ident, f"tree={live} reused=1")


def stage_file(source: Path, dest: Path, expected: str, ident: str, verify_only: bool) -> Outcome:
    if not source.is_file() or source.is_symlink():
        return Outcome("unsatisfied", ident, f"source missing {source}")
    source_hash = sha256_file(source)
    if source_hash != expected:
        return Outcome(
            "unsatisfied",
            ident,
            f"source hash {source_hash} != {expected}",
        )
    if dest.is_file() and not dest.is_symlink() and sha256_file(dest) == expected:
        return Outcome("satisfied", ident, f"sha256={expected} reused=1")
    if verify_only:
        if dest.is_file():
            return Outcome("unsatisfied", ident, f"dest hash {sha256_file(dest)} != {expected}")
        return Outcome("unsatisfied", ident, f"missing dest={dest}")
    dest.parent.mkdir(parents=True, exist_ok=True)
    tmp = dest.parent / f".{dest.name}.INCOMPLETE"
    shutil.copyfile(source, tmp)
    os.chmod(tmp, stat.S_IMODE(source.stat().st_mode))
    tmp.replace(dest)
    staged = sha256_file(dest)
    if staged != expected:
        return Outcome("unsatisfied", ident, f"staged hash {staged} != {expected}")
    return Outcome("staged", ident, f"sha256={expected} dest={dest}")


def verify_absolute_hash(path: Path, expected: str, ident: str) -> Outcome:
    if not path.is_file() or path.is_symlink():
        return Outcome("unsatisfied", ident, f"missing {path}")
    actual = sha256_file(path)
    if actual != expected:
        return Outcome("unsatisfied", ident, f"hash {actual} != {expected}")
    return Outcome("satisfied", ident, f"sha256={expected} reused=1")


def maybe_build_loader(root: Path, verify_only: bool, arch: str) -> Outcome:
    loader = root / "machorun" / "build" / "machorun"
    if loader.is_file() and os.access(loader, os.X_OK) and not loader.is_symlink():
        return Outcome("satisfied", "machorun-loader", f"path={loader} reused=1")
    if arch not in ("aarch64", "arm64"):
        return Outcome(
            "cannot",
            "machorun-loader",
            f"host={arch}",
            marker="CURSOR_ENV_CANNOT_BUILD_LOADER",
        )
    if verify_only:
        return Outcome("unsatisfied", "machorun-loader", "missing loader")
    built = _run(["sh", str(root / "machorun" / "scripts" / "build.sh"), "loader"], cwd=root)
    if built.returncode != 0 or not loader.is_file():
        tail = (built.stderr or built.stdout).strip().splitlines()
        return Outcome(
            "unsatisfied",
            "machorun-loader",
            tail[-1] if tail else "build.sh loader failed",
        )
    return Outcome("cold-built", "machorun-loader", f"path={loader}")


def product_outcome(
    root: Path, row: dict, verify_only: bool, arch: str, system: str
) -> Outcome:
    ident = row["id"]
    path = root / row["path"] if not Path(row["path"]).is_absolute() else Path(row["path"])
    cannot = row.get("cannot_on", {})
    if ident == "machorun-loader":
        return maybe_build_loader(root, verify_only, arch)
    if ident == "libswiftCore":
        return stage_file(
            root / row["source"] if "source" in row else path,
            path,
            row["sha256"],
            ident,
            verify_only,
        )
    if ident == "opencombine-export":
        hashes = row.get("content_hashes") or {}
        missing = []
        export_root = root / row["path"]
        for name, digest in hashes.items():
            file_path = export_root / name
            if not file_path.is_file():
                missing.append(name)
                continue
            actual = sha256_file(file_path)
            if actual != digest:
                return Outcome("unsatisfied", ident, f"{name} hash {actual} != {digest}")
        if missing:
            marker = cannot.get("x86_64") or cannot.get("Linux-without-loader")
            if marker and arch not in ("aarch64", "arm64"):
                return Outcome("cannot", ident, f"missing {','.join(missing)}", marker=marker)
            return Outcome("unsatisfied", ident, f"missing {','.join(missing)}")
        return Outcome("satisfied", ident, f"files={len(hashes)}/{len(hashes)} reused=1")
    if ident == "tbd-stubs":
        if arch not in ("aarch64", "arm64"):
            return Outcome(
                "cannot",
                ident,
                f"host={arch}",
                marker="CURSOR_ENV_CANNOT_GENERATE_TBD",
            )
        if path.is_dir() and any(path.glob("*.tbd")):
            return Outcome("satisfied", ident, "tbd present reused=1")
        return Outcome("unsatisfied", ident, "tbd missing")
    if ident == "sysroot_fe4":
        if path.is_dir() and (path / "usr" / "include").is_dir():
            return Outcome("satisfied", ident, f"path={path} reused=1")
        marker = cannot.get("Linux") if system == "Linux" else None
        if marker:
            return Outcome("cannot", ident, "full Xcode overlays absent", marker=marker)
        return Outcome("unsatisfied", ident, f"missing {path}")
    if ident == "mrroot_full":
        if path.is_dir() and (path / "darwin" / "usr" / "lib").is_dir():
            loader = path / "machorun"
            if not loader.is_file() and arch not in ("aarch64", "arm64"):
                return Outcome(
                    "cannot",
                    ident,
                    "dylibs present, loader absent",
                    marker="CURSOR_ENV_CANNOT_STAGE_MRROOT_LOADER",
                )
            return Outcome("satisfied", ident, f"path={path} reused=1")
        if arch not in ("aarch64", "arm64"):
            return Outcome(
                "cannot",
                ident,
                f"host={arch}",
                marker="CURSOR_ENV_CANNOT_STAGE_MRROOT_LOADER",
            )
        return Outcome("unsatisfied", ident, f"missing {path}")
    if ident == "modcache_swiftui_guest":
        if path.is_dir():
            return Outcome("satisfied", ident, "present reused=1")
        return Outcome(
            "cannot",
            ident,
            "absent (honest empty would look populated)",
            marker="CURSOR_ENV_CANNOT_BUILD_MODCACHE_SWIFTUI_GUEST",
        )
    if ident == "darwin-userland":
        probe = path / "libSystem.B.dylib"
        if probe.is_file() and not probe.is_symlink():
            return Outcome("satisfied", ident, f"path={path} reused=1")
        return Outcome("unsatisfied", ident, f"missing {probe}")
    if path.exists():
        return Outcome("satisfied", ident, f"path={path} reused=1")
    marker = cannot.get(arch) or cannot.get(system)
    if marker:
        return Outcome("cannot", ident, f"missing {path}", marker=marker)
    return Outcome("unsatisfied", ident, f"missing {path}")


def staged_outcome(root: Path, row: dict, verify_only: bool, arch: str, system: str) -> Outcome:
    ident = row["id"]
    if ident == "libswiftCore":
        source = root / row["source"]
        dest = root / row["path"]
        return stage_file(source, dest, row["sha256"], ident, verify_only)
    if ident in ("dejavu-sans", "dejavu-sans-bold"):
        return verify_absolute_hash(Path(row["path"]), row["sha256"], ident)
    if ident == "mrroot_fe-overlays":
        path = root / row["path"]
        if path.is_dir():
            return Outcome("satisfied", ident, f"path={path} reused=1")
        if system != "Darwin":
            return Outcome(
                "cannot",
                ident,
                "CoreSimulator overlays are macOS-only",
                marker="CURSOR_ENV_CANNOT_STAGE_SIMRUNTIME_OVERLAY_DYLIBS",
            )
        return Outcome("unsatisfied", ident, f"missing {path}")
    if ident == "mrroot-base-runtime":
        path = root / row["path"]
        if path.is_dir():
            return Outcome("satisfied", ident, f"path={path} reused=1")
        return Outcome("unsatisfied", ident, f"missing {path}")
    path = root / row["path"] if not Path(row.get("path", "")).is_absolute() else Path(row["path"])
    if path.exists():
        return Outcome("satisfied", ident, f"path={path} reused=1")
    return Outcome("unsatisfied", ident, f"missing {path}")


def host_outcome(row: dict) -> list[Outcome]:
    ident = row["id"]
    out: list[Outcome] = []
    if row["kind"] in ("tools", "tool-alias"):
        for tool in row.get("tools", []):
            if which(tool):
                out.append(Outcome("satisfied", f"{ident}:{tool}", "on PATH"))
            else:
                out.append(Outcome("unsatisfied", f"{ident}:{tool}", "missing"))
        aliases = row.get("must_resolve_to")
        if aliases:
            for unversioned, versioned in zip(row.get("tools", []), aliases):
                left = which(unversioned)
                right = which(versioned)
                if left and right and Path(left).resolve() == Path(right).resolve():
                    out.append(Outcome("satisfied", f"{ident}:{unversioned}->18", "alias ok"))
                elif left and right:
                    out.append(
                        Outcome(
                            "unsatisfied",
                            f"{ident}:{unversioned}",
                            f"{left} != {right}",
                        )
                    )
        return out
    if row["kind"] == "toolchain":
        swiftc = which("swiftc")
        if not swiftc:
            return [Outcome("unsatisfied", ident, "swiftc missing")]
        version = _run([swiftc, "--version"])
        needle = row.get("match", "")
        if needle and needle in version.stdout:
            return [Outcome("satisfied", ident, needle)]
        if version.returncode == 0:
            first = version.stdout.splitlines()[0] if version.stdout else "unknown"
            return [Outcome("unsatisfied", ident, first)]
        return [Outcome("unsatisfied", ident, "swiftc --version failed")]
    if row["kind"] == "tool-pin":
        for profile in row.get("profiles", []):
            path = Path(profile["path"])
            if path.is_file() and not path.is_symlink():
                actual = sha256_file(path)
                if actual == profile["sha256"]:
                    return [Outcome("satisfied", ident, f"profile={profile['id']} reused=1")]
        return [Outcome("unsatisfied", ident, "no matching poppler profile on this host")]
    return [Outcome("satisfied", ident, "no-op")]


def filesystem_outcome(root: Path, row: dict, verify_only: bool) -> list[Outcome]:
    ident = row["id"]
    if ident == "git-safe-directory":
        targets = [root]
        return [ensure_safe_directory(path) for path in targets]
    if ident == "mktemp-root":
        path = root / row["path"]
        if verify_only and not path.exists():
            return [Outcome("unsatisfied", ident, f"missing {path}")]
        path.mkdir(parents=True, exist_ok=True)
        if path.is_symlink() or not path.is_dir():
            return [Outcome("unsatisfied", ident, f"not a directory: {path}")]
        return [Outcome("satisfied", ident, f"path={path} reused=1")]
    if ident == "proof-parent-0700":
        parent = root / "scratch" / ".env-proof-parent"
        if verify_only and not parent.exists():
            return [Outcome("unsatisfied", ident, f"missing {parent}")]
        return [ensure_mode_0700(parent, ident)]
    if ident == "ancestor-trust":
        parent = root / "scratch" / ".env-proof-parent"
        if not parent.is_dir():
            return [Outcome("unsatisfied", ident, "proof parent missing")]
        child = parent
        euid = os.geteuid()
        while True:
            container = child.parent
            if container == child:
                break
            meta = container.stat()
            if meta.st_uid not in (0, euid):
                return [
                    Outcome(
                        "unsatisfied",
                        ident,
                        f"untrusted owner uid={meta.st_uid} path={container}",
                    )
                ]
            child = container
        return [Outcome("satisfied", ident, "ancestors trusted")]
    if ident == "macios-evidence-parent":
        path = Path(row["path"])
        if not path.is_dir():
            return [Outcome("cannot", ident, f"missing {path}")]
        return [Outcome("satisfied", ident, f"path={path}")]
    return [Outcome("satisfied", ident, "no-op")]


def summarize(outcomes: list[Outcome], arch: str, gate: str, expected_cannot: list[str]) -> str:
    sat = [o for o in outcomes if o.status == "satisfied"]
    built = [o for o in outcomes if o.status == "cold-built"]
    staged = [o for o in outcomes if o.status == "staged"]
    cannot = [o for o in outcomes if o.status == "cannot"]
    unsatisfied = [o for o in outcomes if o.status == "unsatisfied"]
    checkable = [o for o in outcomes if o.status in ("satisfied", "unsatisfied", "staged", "cold-built")]
    buildable = built + [o for o in outcomes if o.id == "machorun-loader" and o.status != "cannot"]
    stageable = staged + [o for o in outcomes if o.status == "unsatisfied" and "hash" in o.detail]
    expected_n = len(expected_cannot)
    logged_markers = [o.marker for o in cannot if o.marker]
    logged_n = len(logged_markers)
    return (
        "ENV_PREPARE_SUMMARY "
        f"satisfied={len(sat)}/{len(checkable)} "
        f"cold-built={len(built)}/{max(len(buildable), len(built))} "
        f"staged={len(staged)}/{max(len(staged) + len([o for o in outcomes if o.status == 'unsatisfied' and o.id == 'libswiftCore']), len(staged))} "
        f"CANNOT={logged_n}/{expected_n} "
        f"unsatisfied={len(unsatisfied)} "
        f"host={arch} gate={gate or '*'} "
        f"markers={','.join(logged_markers) if logged_markers else 'none'}"
    )


def prepare(
    root: Path,
    gate: str | None,
    verify_only: bool,
    fetch: bool = True,
) -> list[Outcome]:
    contract = load_contract(root)
    arch = host_arch()
    system = host_os()
    sections = (
        demanded_by(contract, gate)
        if gate
        else {
            "checkouts": contract["checkouts"],
            "built_products": contract["built_products"],
            "staged_externals": contract["staged_externals"],
            "host_requirements": contract["host_requirements"],
            "filesystem_preconditions": contract["filesystem_preconditions"],
        }
    )
    outcomes: list[Outcome] = []

    for row in sections["filesystem_preconditions"]:
        outcomes.extend(filesystem_outcome(root, row, verify_only))

    for row in sections["host_requirements"]:
        if row["id"] == "zstd" and gate == "focus-widget":
            continue
        if row["id"] == "poppler-pdftocairo" and gate == "focus-widget":
            continue
        if row["id"] == "core-guest-extra-tools" and gate == "focus-widget":
            continue
        outcomes.extend(host_outcome(row))

    for row in sections["checkouts"]:
        if row["kind"] == "in-repo-subtree":
            outcomes.append(verify_inrepo_tree(root, row))
        elif row["kind"] in ("git", "git-sparse"):
            if row["id"] == "dotnet-macios" and gate == "focus-widget":
                continue
            if row["kind"] == "git-sparse":
                dest = Path(row["destination"])
                if dest.is_dir() and (dest / ".git").exists():
                    outcomes.append(Outcome("satisfied", row["id"], f"path={dest} reused=1"))
                else:
                    outcomes.append(Outcome("cannot", row["id"], f"missing {dest}"))
                continue
            outcomes.append(clone_or_verify_git(root, row, verify_only or not fetch))

    for row in sections["staged_externals"]:
        outcomes.append(staged_outcome(root, row, verify_only, arch, system))

    for row in sections["built_products"]:
        outcomes.append(product_outcome(root, row, verify_only, arch, system))

    return outcomes


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(prog="prepare.py")
    parser.add_argument("--contract", default=None, help="unused; contract is env/contract.json")
    parser.add_argument("--root", default=None)
    parser.add_argument("--gate", default=None)
    parser.add_argument("--verify-only", action="store_true")
    parser.add_argument("--no-fetch", action="store_true", help="do not clone missing git checkouts")
    parser.add_argument("--strict", action="store_true")
    args = parser.parse_args(argv)
    root = Path(args.root).resolve() if args.root else repo_root_from()
    os.chdir(root)
    contract = load_contract(root)
    arch = host_arch()
    system = host_os()
    expected = expected_cannot_for_host(contract, arch, system)
    outcomes = prepare(root, args.gate, args.verify_only, fetch=not args.no_fetch)
    for outcome in outcomes:
        print(outcome.line())
    summary = summarize(outcomes, arch, args.gate or "*", expected)
    print(summary)
    unsatisfied = [o for o in outcomes if o.status == "unsatisfied"]
    if args.strict and unsatisfied:
        return 2
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
