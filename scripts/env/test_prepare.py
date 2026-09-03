#!/usr/bin/env python3
"""prepare.py prints denominators and is idempotent on verify."""

from __future__ import annotations

from pathlib import Path
import os
import re
import subprocess
import tempfile
import unittest
import sys

ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT / "scripts" / "env"))

from ledger import sha256_file  # noqa: E402
from prepare import (  # noqa: E402
    expected_cannot_for_host,
    guest_out_suffix,
    host_arch,
    prepare,
    resolve_row_path,
    summarize,
)
from contract import load_contract  # noqa: E402

PREPARE = ROOT / "scripts" / "env" / "prepare.py"
SUMMARY = re.compile(
    r"^ENV_PREPARE_SUMMARY satisfied=(\d+)/(\d+) cold-built=(\d+)/(\d+) "
    r"staged=(\d+)/(\d+) CANNOT=(\d+)/(\d+) unsatisfied=(\d+) host=\S+ gate=\S+"
)


class PrepareTests(unittest.TestCase):
    def test_verify_only_focus_widget_prints_denominators(self) -> None:
        proc = subprocess.run(
            [
                "python3",
                str(PREPARE),
                "--gate",
                "focus-widget",
                "--verify-only",
            ],
            cwd=ROOT,
            capture_output=True,
            text=True,
        )
        self.assertEqual(proc.returncode, 0, proc.stderr + proc.stdout)
        summary = [line for line in proc.stdout.splitlines() if line.startswith("ENV_PREPARE_SUMMARY ")]
        self.assertEqual(len(summary), 1, proc.stdout)
        match = SUMMARY.match(summary[0])
        self.assertIsNotNone(match, summary[0])
        sat, sat_d, built, built_d, staged, staged_d, cannot, cannot_d, unsatisfied = (
            int(g) for g in match.groups()
        )
        self.assertGreater(sat_d, 0)
        self.assertGreaterEqual(sat, 0)
        self.assertLessEqual(sat, sat_d)
        self.assertGreaterEqual(cannot_d, 2)  # x86_64 expected CANNOT set is large
        print(summary[0])
        self.assertIn("gate=focus-widget", summary[0])

    def test_rerun_is_idempotent_status_set(self) -> None:
        first = subprocess.run(
            ["python3", str(PREPARE), "--gate", "focus-widget", "--verify-only"],
            cwd=ROOT,
            capture_output=True,
            text=True,
            check=True,
        )
        second = subprocess.run(
            ["python3", str(PREPARE), "--gate", "focus-widget", "--verify-only"],
            cwd=ROOT,
            capture_output=True,
            text=True,
            check=True,
        )
        first_summary = [ln for ln in first.stdout.splitlines() if ln.startswith("ENV_PREPARE_SUMMARY ")][0]
        second_summary = [ln for ln in second.stdout.splitlines() if ln.startswith("ENV_PREPARE_SUMMARY ")][0]
        self.assertEqual(first_summary, second_summary)

    def test_libswiftCore_artifact_hash_is_the_contract_pin(self) -> None:
        artifact = ROOT / "swiftcore-macho/artifacts/swift-macosx/arm64/libswiftCore.dylib"
        self.assertTrue(artifact.is_file())
        self.assertEqual(
            sha256_file(artifact),
            "dd01686e06c81a21755bb864b43dad446c011e6c60c6b387b3b332c0a12708cb",
        )

    def test_materialize_stages_libswiftCore_and_fixes_mktemp_root(self) -> None:
        proc = subprocess.run(
            ["python3", str(PREPARE), "--gate", "focus-widget", "--no-fetch"],
            cwd=ROOT,
            capture_output=True,
            text=True,
        )
        self.assertEqual(proc.returncode, 0, proc.stderr + proc.stdout)
        self.assertTrue((ROOT / "build" / "full").is_dir())
        dest = ROOT / "machorun/darwin/usr/lib/swift/libswiftCore.dylib"
        self.assertTrue(dest.is_file(), proc.stdout)
        self.assertEqual(
            sha256_file(dest),
            "dd01686e06c81a21755bb864b43dad446c011e6c60c6b387b3b332c0a12708cb",
        )
        self.assertRegex(proc.stdout, r"ENV_PREPARE_(STAGED|SATISFIED) id=libswiftCore")
        # x86 cannot compile the arm64 Linux-native loader; if this host already
        # has an x86 ELF loader (phase2 substrate), the row is satisfied instead.
        self.assertTrue(
            "CURSOR_ENV_CANNOT_BUILD_LOADER" in proc.stdout
            or "ENV_PREPARE_SATISFIED id=machorun-loader" in proc.stdout,
            proc.stdout,
        )
        summary = [ln for ln in proc.stdout.splitlines() if ln.startswith("ENV_PREPARE_SUMMARY ")][0]
        print(summary)

    def test_gate_argv_shape_is_accepted(self) -> None:
        proc = subprocess.run(
            [
                "python3",
                str(PREPARE),
                "--contract",
                str(ROOT / "env" / "contract.json"),
                "--root",
                str(ROOT),
                "--gate",
                "focus-widget",
                "--verify-only",
            ],
            cwd=ROOT,
            capture_output=True,
            text=True,
        )
        self.assertEqual(proc.returncode, 0, proc.stderr + proc.stdout)
        self.assertIn("ENV_PREPARE_SUMMARY", proc.stdout)
        self.assertIn("gate=focus-widget", proc.stdout)

    def test_summarize_counts_match_outcomes(self) -> None:
        contract = load_contract(ROOT)
        outcomes = prepare(ROOT, "focus-widget", verify_only=True, fetch=False)
        line = summarize(
            outcomes,
            host_arch(),
            "focus-widget",
            expected_cannot_for_host(contract, host_arch(), "Linux"),
        )
        self.assertTrue(SUMMARY.match(line), line)
        cannot_rows = [o for o in outcomes if o.status == "cannot"]
        self.assertTrue(
            any(o.marker == "CURSOR_ENV_CANNOT_BUILD_LOADER" for o in cannot_rows)
            or any(o.id == "machorun-loader" and o.status == "satisfied" for o in outcomes)
            or host_arch() in ("aarch64", "arm64")
        )


UNSUFFIXED_TREE = re.compile(
    r"/scratch/(mrroot_full|mrroot_fe|sysroot_fe4|mrroot)(?!-x86_64)(?=/|\s|$)"
)


class SuffixPathPrepareTests(unittest.TestCase):
    def test_empty_suffix_keeps_contract_spellings(self) -> None:
        old = os.environ.pop("FULL_OUT_SUFFIX", None)
        try:
            self.assertEqual(guest_out_suffix(), "")
            self.assertEqual(
                resolve_row_path(ROOT, {"id": "sysroot_fe4", "path": "scratch/sysroot_fe4"}),
                ROOT / "scratch/sysroot_fe4",
            )
            self.assertEqual(
                resolve_row_path(ROOT, {"id": "mrroot-base-runtime", "path": "scratch/mrroot"}),
                ROOT / "scratch/mrroot",
            )
            self.assertEqual(
                resolve_row_path(
                    ROOT,
                    {
                        "id": "opencombine-export",
                        "path": "scratch/oc/export/artifacts",
                    },
                ),
                ROOT / "scratch/oc/export/artifacts",
            )
        finally:
            if old is not None:
                os.environ["FULL_OUT_SUFFIX"] = old
            else:
                os.environ.pop("FULL_OUT_SUFFIX", None)

    def test_x86_suffix_prepare_never_touches_unsuffixed_arm64_trees(self) -> None:
        import shutil

        with tempfile.TemporaryDirectory(prefix="env-prepare-x86-suffix.") as tmp:
            fixture = Path(tmp)
            (fixture / "env").mkdir()
            shutil.copy2(ROOT / "env/contract.json", fixture / "env/contract.json")
            for trap in (
                "scratch/sysroot_fe4/usr/include",
                "scratch/mrroot/darwin/usr/lib/swift",
                "scratch/mrroot_full/darwin/usr/lib",
                "scratch/mrroot_fe/darwin/usr/lib/swift",
            ):
                path = fixture / trap
                path.mkdir(parents=True)
                (path / ".trap").write_text("arm64-only\n", encoding="utf-8")
            proc = subprocess.run(
                [
                    "python3",
                    str(PREPARE),
                    "--root",
                    str(fixture),
                    "--gate",
                    "focus-widget",
                    "--verify-only",
                    "--no-fetch",
                ],
                env={**os.environ, "FULL_OUT_SUFFIX": "-x86_64"},
                capture_output=True,
                text=True,
            )
            self.assertEqual(proc.returncode, 0, proc.stderr + proc.stdout)
            for line in proc.stdout.splitlines():
                if line.startswith("ENV_PREPARE_"):
                    self.assertIsNone(UNSUFFIXED_TREE.search(line), line)
            self.assertRegex(proc.stdout, r"id=sysroot_fe4 .*sysroot_fe4-x86_64")
            self.assertRegex(proc.stdout, r"id=mrroot_full .*mrroot_full-x86_64")
            self.assertRegex(proc.stdout, r"id=mrroot-base-runtime .*mrroot-x86_64")
            self.assertRegex(proc.stdout, r"id=mrroot_fe-overlays .*mrroot_fe-x86_64")
            self.assertIn("CANNOT_X86_OVERLAYS_NOT_BUILT", proc.stdout)
            self.assertIn("missing=libswiftDarwin.dylib", proc.stdout)
            self.assertNotIn(
                "CURSOR_ENV_CANNOT_STAGE_SIMRUNTIME_OVERLAY_DYLIBS", proc.stdout
            )
            tbd = [ln for ln in proc.stdout.splitlines() if "id=tbd-stubs" in ln]
            self.assertEqual(len(tbd), 1, proc.stdout)
            self.assertNotIn("CURSOR_ENV_CANNOT_GENERATE_TBD", tbd[0])
            self.assertNotIn("host=x86_64", tbd[0])
            oc = [ln for ln in proc.stdout.splitlines() if "id=opencombine-export" in ln]
            self.assertEqual(len(oc), 1, proc.stdout)
            self.assertNotIn("CURSOR_ENV_CANNOT_BUILD_OPENCOMBINE_EXPORT", oc[0])
            self.assertIn("export-x86_64", oc[0])


if __name__ == "__main__":
    unittest.main(verbosity=2)
