#!/usr/bin/env python3
"""Behavioural tests for build_full.sh's opt-in stage cache (BUILD_FULL_STAGE_CACHE).

The functions between the ">>> stage-cache functions" markers are extracted
from full/scripts/build_full.sh and run under the same `set -euo pipefail` the
build uses. They need GNU find/stat/touch, so the tests skip elsewhere (run
them in the guest container, e.g. openuikit-guest-env:arm64).

Regression covered: on 2026-09-22 a store on the main checkout died with
"cp: skipping file ..., as it was replaced while being copied" (GNU cp's inode
identity check tripping on Docker Desktop's bind mount) and took the whole
build with it. The cache must not depend on cp or tar at all, a failed or
unverifiable store must only warn, and a restore that cannot be staged must
leave the outputs untouched and report a miss.
"""

from __future__ import annotations

import hashlib
import os
from pathlib import Path
import platform
import shutil
import stat
import subprocess
import tempfile
import unittest

ROOT = Path(__file__).resolve().parents[2]
BUILD_FULL = ROOT / "full/scripts/build_full.sh"
BEGIN = "# >>> stage-cache functions"
END = "# <<< stage-cache functions"


def extract_functions() -> str:
    text = BUILD_FULL.read_text(encoding="utf-8")
    start = text.index(BEGIN)
    end = text.index(END, start)
    return text[start:end]


def gnu_tools_available() -> bool:
    if platform.system() != "Linux":
        return False
    probe = subprocess.run(
        ["find", "/", "-maxdepth", "0", "-printf", "%m"],
        capture_output=True, text=True, check=False,
    )
    return probe.returncode == 0 and probe.stdout.strip().isdigit()


def snapshot(path: Path) -> dict[str, tuple]:
    """Type, mode, content/target and mtime of every entry at and under path."""
    result: dict[str, tuple] = {}
    entries = [path]
    if path.is_dir() and not path.is_symlink():
        entries += sorted(path.rglob("*"))
    for entry in entries:
        info = entry.lstat()
        name = entry.relative_to(path).as_posix()
        if stat.S_ISLNK(info.st_mode):
            result[name] = ("l", os.readlink(entry))
        elif stat.S_ISDIR(info.st_mode):
            result[name] = ("d", stat.S_IMODE(info.st_mode), info.st_mtime_ns)
        else:
            digest = hashlib.sha256(entry.read_bytes()).hexdigest()
            result[name] = ("f", stat.S_IMODE(info.st_mode), digest, info.st_mtime_ns)
    return result


@unittest.skipUnless(gnu_tools_available(), "needs Linux with GNU find/stat/touch")
class StageCacheTests(unittest.TestCase):
    def setUp(self) -> None:
        self.tmp = Path(tempfile.mkdtemp(prefix="stage-cache-test-")).resolve()
        self.addCleanup(shutil.rmtree, self.tmp, True)
        self.functions = self.tmp / "functions.sh"
        self.functions.write_text(extract_functions(), encoding="utf-8")
        self.cache = self.tmp / "cache"
        self.bin = self.tmp / "bin"
        self.bin.mkdir()
        self.out = self.tmp / "out"
        self.tree = self.out / "tree"
        self.single = self.out / "single.dylib"
        self.make_outputs()

    def make_outputs(self) -> None:
        (self.tree / "sub dir" / "deep").mkdir(parents=True)
        (self.tree / "a.o").write_bytes(os.urandom(4096))
        (self.tree / "sub dir" / "name with spaces.swift").write_text("let x = 1\n")
        tool = self.tree / "sub dir" / "deep" / "tool"
        tool.write_bytes(b"#!/bin/sh\necho hi\n")
        tool.chmod(0o755)
        private = self.tree / "private.txt"
        private.write_text("secret\n")
        private.chmod(0o600)
        (self.tree / "link-to-sdk").symlink_to("/nonexistent/sdk")
        (self.tree / "sub dir" / "rel-link").symlink_to("../a.o")
        (self.tree / "sub dir" / "empty").mkdir()
        (self.tree / "sub dir" / "deep").chmod(0o700)
        self.single.write_bytes(os.urandom(1024))
        for index, entry in enumerate(sorted(self.out.rglob("*"))):
            if not entry.is_symlink():
                os.utime(entry, ns=(10**18 + index, 10**18 + index))

    def fake(self, name: str, body: str) -> None:
        tool = self.bin / name
        tool.write_text("#!/bin/bash\n" + body + "\n", encoding="utf-8")
        tool.chmod(0o755)

    def run_bash(self, script: str, *, fakes: bool = False) -> subprocess.CompletedProcess:
        env = dict(os.environ)
        env["BUILD_FULL_STAGE_CACHE"] = "1"
        env["BUILD_FULL_STAGE_CACHE_DIR"] = str(self.cache)
        if fakes:
            env["PATH"] = f"{self.bin}:{env['PATH']}"
        prelude = (
            "set -euo pipefail\n"
            'die() { echo "die: $*" >&2; exit 2; }\n'
            f'. "{self.functions}"\n'
            f'TREE="{self.tree}"; SINGLE="{self.single}"\n'
        )
        return subprocess.run(
            ["bash", "-c", prelude + script],
            env=env, capture_output=True, text=True, check=False,
        )

    def store(self, *, fakes: bool = False) -> subprocess.CompletedProcess:
        return self.run_bash(
            'stage_cache_store demo k1 "$TREE" "$SINGLE"\necho AFTER-STORE\n',
            fakes=fakes,
        )

    def restore(self, *, fakes: bool = False) -> subprocess.CompletedProcess:
        return self.run_bash(
            'if stage_cache_restore demo k1 "$TREE" "$SINGLE"; then echo HIT; else echo MISS; fi\n',
            fakes=fakes,
        )

    def assert_no_restore_leftovers(self) -> None:
        self.assertEqual(list(self.out.rglob("*.stage-restore")), [])

    def test_roundtrip_is_exact_and_independent_of_cp_and_tar(self) -> None:
        refusal = (
            'echo "$(basename "$0"): skipping file \'$1\', as it was replaced '
            'while being copied" >&2; exit 1'
        )
        self.fake("cp", refusal)
        self.fake("tar", refusal)
        before = {"tree": snapshot(self.tree), "single": snapshot(self.single)}

        stored = self.store(fakes=True)
        self.assertEqual(stored.returncode, 0, stored.stderr)
        self.assertIn("stage cache: demo stored key=k1", stored.stdout)
        self.assertNotIn("WARNING", stored.stderr)

        shutil.rmtree(self.tree)
        self.tree.mkdir()
        (self.tree / "stale").write_text("left over from a previous run\n")
        self.single.write_bytes(b"stale")

        restored = self.restore(fakes=True)
        self.assertEqual(restored.returncode, 0, restored.stderr)
        self.assertIn("HIT", restored.stdout)
        after = {"tree": snapshot(self.tree), "single": snapshot(self.single)}
        self.assertEqual(after, before)
        self.assert_no_restore_leftovers()

    def test_failed_store_only_warns_and_records_nothing(self) -> None:
        self.fake("cat", "echo 'cat: read error' >&2; exit 1")
        stored = self.store(fakes=True)
        self.assertEqual(stored.returncode, 0, stored.stderr)
        self.assertIn("AFTER-STORE", stored.stdout)
        self.assertIn("WARNING: demo not recorded", stored.stderr)
        self.assertEqual(list((self.cache / "demo").iterdir()), [])
        miss = self.restore()
        self.assertIn("MISS", miss.stdout)

    def test_store_that_does_not_match_the_outputs_is_discarded(self) -> None:
        # A copy that differs from its source (e.g. a writer still running)
        # must never become an entry.
        self.fake("cat", '/bin/cat "$@"; printf x')
        stored = self.store(fakes=True)
        self.assertEqual(stored.returncode, 0, stored.stderr)
        self.assertIn("differs from the originals", stored.stderr)
        self.assertIn("WARNING: demo not recorded", stored.stderr)
        self.assertEqual(list((self.cache / "demo").iterdir()), [])

    def test_restore_that_cannot_be_staged_leaves_outputs_untouched(self) -> None:
        self.assertEqual(self.store().returncode, 0)
        (self.tree / "newer.o").write_text("current output\n")
        before = {"tree": snapshot(self.tree), "single": snapshot(self.single)}
        self.fake("cat", "exit 1")
        restored = self.restore(fakes=True)
        self.assertEqual(restored.returncode, 0, restored.stderr)
        self.assertIn("MISS", restored.stdout)
        self.assertIn("could not be staged", restored.stderr)
        # The outputs themselves are untouched (their parent directory's own
        # mtime moves when the staging sibling is created and removed).
        after = {"tree": snapshot(self.tree), "single": snapshot(self.single)}
        self.assertEqual(after, before)
        self.assert_no_restore_leftovers()

    def test_corrupted_entry_is_a_miss_and_is_dropped(self) -> None:
        self.assertEqual(self.store().returncode, 0)
        entry = self.cache / "demo" / "k1"
        victim = next(p for p in (entry / "payload").rglob("a.o"))
        victim.write_bytes(b"corrupted")
        before = snapshot(self.out)
        restored = self.restore()
        self.assertIn("MISS", restored.stdout)
        self.assertIn("does not match its manifest", restored.stderr)
        self.assertFalse(entry.exists())
        self.assertEqual(snapshot(self.out), before)

    def test_disabled_cache_never_hits_or_writes(self) -> None:
        result = self.run_bash(
            'BUILD_FULL_STAGE_CACHE=0\n'
            'stage_cache_store demo k1 "$TREE"\n'
            'if stage_cache_restore demo k1 "$TREE"; then echo HIT; else echo MISS; fi\n'
        )
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertIn("MISS", result.stdout)
        self.assertFalse(self.cache.exists())


class StageCacheSourceTests(unittest.TestCase):
    def test_cache_code_never_copies_with_cp_or_tar(self) -> None:
        functions = extract_functions()
        for forbidden in ("cp -a", "cp -R", "cp -r", "tar -", "rsync"):
            self.assertNotIn(forbidden, functions)

    def test_store_is_wrapped_so_it_cannot_fail_the_build(self) -> None:
        functions = extract_functions()
        self.assertIn('stage_cache_store_entry "$@" || {', functions)


if __name__ == "__main__":
    unittest.main()
