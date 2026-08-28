#!/usr/bin/env python3
"""Lightweight adversarial tests for the OpenCombine vendoring policy."""

from __future__ import annotations

import hashlib
import json
import os
from pathlib import Path
import shutil
import subprocess
import tempfile
import unittest


HERE = Path(__file__).resolve().parent
ROOT = HERE.parent.parent
POLICY_TOOL = HERE / "policy_tool.pl"
POLICY = HERE / "policy.json"


def digest_sources(repo: Path, paths: list[str]) -> str:
    digest = hashlib.sha256()
    for rel in sorted(paths):
        digest.update(rel.encode())
        digest.update(b"\0")
        digest.update((repo / rel).read_bytes())
        digest.update(b"\0")
    return digest.hexdigest()


def digest_input_tree(root: Path) -> tuple[str, int, int, int]:
    records: list[tuple[str, str, str]] = []
    for path in sorted(root.rglob("*"), key=lambda item: item.relative_to(root).as_posix()):
        rel = path.relative_to(root).as_posix()
        if path.is_symlink():
            records.append((rel, "L", os.readlink(path)))
        elif path.is_dir():
            records.append((rel, "D", ""))
        elif path.is_file():
            records.append((rel, "F", hashlib.sha256(path.read_bytes()).hexdigest()))
        else:
            raise AssertionError(f"unsupported fixture entry: {path}")
    digest = hashlib.sha256()
    for rel, kind, value in records:
        digest.update(kind.encode() + b"\0" + rel.encode() + b"\0")
        digest.update(value.encode() + b"\0")
    return (
        digest.hexdigest(),
        sum(kind == "D" for _, kind, _ in records),
        sum(kind == "F" for _, kind, _ in records),
        sum(kind == "L" for _, kind, _ in records),
    )


class PolicyTests(unittest.TestCase):
    def setUp(self) -> None:
        self.temp = tempfile.TemporaryDirectory(prefix="opencombine-policy.")
        self.base = Path(self.temp.name)
        self.tool = self.base / "tool"
        shutil.copytree(HERE, self.tool)
        self.policy_path = self.tool / "policy.json"
        self.repo = self.base / "OpenCombine"
        core = self.repo / "Sources" / "OpenCombine"
        helper = self.repo / "Sources" / "COpenCombineHelpers"
        helper_include = helper / "include"
        dispatch = self.repo / "Sources" / "OpenCombineDispatch"
        core.mkdir(parents=True)
        helper_include.mkdir(parents=True)
        dispatch.mkdir(parents=True)
        source_names = ["A Space.swift"] + [f"Source{i:03}.swift" for i in range(102)]
        for index, name in enumerate(source_names):
            (core / name).write_text(f"public struct Fixture{index} {{}}\n")
        self.helper_path = helper / "COpenCombineHelpers.cpp"
        self.helper_path.write_text("// fixture helper\n")
        self.helper_header_path = helper_include / "COpenCombineHelpers.h"
        self.helper_header_path.write_text("// fixture header\n")
        self.modulemap_path = helper_include / "module.modulemap"
        self.modulemap_path.write_text(
            'module COpenCombineHelpers { header "COpenCombineHelpers.h" }\n'
        )
        self.dispatch_path = dispatch / "DispatchQueue+Scheduler.swift"
        self.dispatch_path.write_text("// fixture Dispatch boundary\n")
        subprocess.run(["git", "init", "-q", str(self.repo)], check=True)
        subprocess.run(["git", "-C", str(self.repo), "add", "Sources"], check=True)
        subprocess.run(
            [
                "git", "-C", str(self.repo), "-c", "user.name=Policy Test",
                "-c", "user.email=policy@example.invalid", "commit", "-qm", "fixture",
            ],
            check=True,
        )
        policy = json.loads(self.policy_path.read_text())
        policy["repository"]["commit"] = subprocess.check_output(
            ["git", "-C", str(self.repo), "rev-parse", "HEAD"], text=True
        ).strip()
        paths = [f"Sources/OpenCombine/{name}" for name in source_names]
        policy["core_sources"]["swift_file_count"] = len(paths)
        policy["core_sources"]["sha256"] = digest_sources(self.repo, paths)
        policy["helper_patch"]["upstream_sha256"] = hashlib.sha256(
            self.helper_path.read_bytes()
        ).hexdigest()
        for rel in policy["compiler_inputs"]["files"]:
            policy["compiler_inputs"]["files"][rel] = hashlib.sha256(
                (self.repo / rel).read_bytes()
            ).hexdigest()
        self.write_policy(policy)

    def tearDown(self) -> None:
        self.temp.cleanup()

    def read_policy(self) -> dict:
        return json.loads(self.policy_path.read_text())

    def write_policy(self, policy: dict) -> None:
        self.policy_path.write_text(json.dumps(policy, indent=2, sort_keys=True) + "\n")

    def run_tool(self, mode: str, *args: str | Path) -> subprocess.CompletedProcess[str]:
        return subprocess.run(
            ["perl", str(POLICY_TOOL), mode, str(self.policy_path), *(str(a) for a in args)],
            text=True,
            capture_output=True,
        )

    def attest(self) -> subprocess.CompletedProcess[str]:
        return self.run_tool(
            "attest", self.repo, self.base / "sources.nul", self.base / "audit.json"
        )

    def test_valid_subject_and_nul_safe_space(self) -> None:
        result = self.attest()
        self.assertEqual(result.returncode, 0, result.stderr)
        values = (self.base / "sources.nul").read_bytes().split(b"\0")
        self.assertEqual(values[-1], b"")
        self.assertEqual(len(values) - 1, 103)
        self.assertTrue(any(b"A Space.swift" in value for value in values))
        audit = json.loads((self.base / "audit.json").read_text())
        self.assertEqual(audit["swift_source_count"], 103)
        self.assertEqual(len(audit["compiler_inputs"]), 4)

    def test_dirty_compiler_subject_is_refused(self) -> None:
        (self.repo / "Sources/OpenCombine/Source101.swift").write_text("// dirty\n")
        result = self.attest()
        self.assertNotEqual(result.returncode, 0)
        self.assertIn("compiler subject is not clean", result.stderr)

    def test_untracked_swift_source_is_refused(self) -> None:
        (self.repo / "Sources/OpenCombine/Untracked.swift").write_text("// drift\n")
        result = self.attest()
        self.assertNotEqual(result.returncode, 0)
        self.assertIn("compiler subject is not clean", result.stderr)

    def test_dirty_helper_header_is_refused(self) -> None:
        self.helper_header_path.write_text("// dirty header\n")
        result = self.attest()
        self.assertNotEqual(result.returncode, 0)
        self.assertIn("compiler subject is not clean", result.stderr)

    def test_dirty_modulemap_is_refused(self) -> None:
        self.modulemap_path.write_text("module Drift {}\n")
        result = self.attest()
        self.assertNotEqual(result.returncode, 0)
        self.assertIn("compiler subject is not clean", result.stderr)

    def test_dirty_dispatch_boundary_source_is_refused(self) -> None:
        self.dispatch_path.write_text("// dirty Dispatch source\n")
        result = self.attest()
        self.assertNotEqual(result.returncode, 0)
        self.assertIn("compiler subject is not clean", result.stderr)

    def test_untracked_helper_input_is_refused(self) -> None:
        (self.helper_header_path.parent / "Untracked.h").write_text("// drift\n")
        result = self.attest()
        self.assertNotEqual(result.returncode, 0)
        self.assertIn("compiler subject is not clean", result.stderr)

    def test_untracked_dispatch_input_is_refused(self) -> None:
        (self.dispatch_path.parent / "Untracked.swift").write_text("// drift\n")
        result = self.attest()
        self.assertNotEqual(result.returncode, 0)
        self.assertIn("compiler subject is not clean", result.stderr)

    def test_pin_drift_is_refused(self) -> None:
        policy = self.read_policy()
        policy["repository"]["commit"] = "0" * 40
        self.write_policy(policy)
        result = self.attest()
        self.assertNotEqual(result.returncode, 0)
        self.assertIn("pin changed", result.stderr)

    def test_denominator_drift_is_refused(self) -> None:
        policy = self.read_policy()
        policy["core_sources"]["swift_file_count"] = 104
        self.write_policy(policy)
        result = self.attest()
        self.assertNotEqual(result.returncode, 0)
        self.assertIn("source denominator must remain exactly 103", result.stderr)

    def test_digest_drift_is_refused(self) -> None:
        policy = self.read_policy()
        policy["core_sources"]["sha256"] = "0" * 64
        self.write_policy(policy)
        result = self.attest()
        self.assertNotEqual(result.returncode, 0)
        self.assertIn("source digest changed", result.stderr)

    def test_helper_hash_drift_is_refused(self) -> None:
        policy = self.read_policy()
        policy["helper_patch"]["upstream_sha256"] = "0" * 64
        self.write_policy(policy)
        result = self.attest()
        self.assertNotEqual(result.returncode, 0)
        self.assertIn("helper upstream hash disagrees", result.stderr)

    def test_compiler_input_hash_drift_is_refused(self) -> None:
        policy = self.read_policy()
        header = "Sources/COpenCombineHelpers/include/COpenCombineHelpers.h"
        policy["compiler_inputs"]["files"][header] = "0" * 64
        self.write_policy(policy)
        result = self.attest()
        self.assertNotEqual(result.returncode, 0)
        self.assertIn("compiler input hash changed", result.stderr)

    def test_asset_content_drift_is_refused(self) -> None:
        with (self.tool / "Combine.swift").open("a") as stream:
            stream.write("// mutation\n")
        result = self.run_tool("assets", self.tool)
        self.assertNotEqual(result.returncode, 0)
        self.assertIn("asset hash changed", result.stderr)

    def test_asset_scope_expansion_is_refused(self) -> None:
        policy = self.read_policy()
        policy["assets"]["oracles/unreviewed.swift"] = "0" * 64
        self.write_policy(policy)
        result = self.run_tool("assets", self.tool)
        self.assertNotEqual(result.returncode, 0)
        self.assertIn("assets keys changed", result.stderr)

    def test_policy_scope_expansion_is_refused(self) -> None:
        policy = self.read_policy()
        policy["silent_fallback"] = True
        self.write_policy(policy)
        result = self.run_tool("assets", self.tool)
        self.assertNotEqual(result.returncode, 0)
        self.assertIn("policy keys changed", result.stderr)

    def test_nested_toolchain_scope_expansion_is_refused(self) -> None:
        policy = self.read_policy()
        policy["toolchain"]["unreviewed_fallback"] = "/usr/bin/swiftc"
        self.write_policy(policy)
        result = self.run_tool("assets", self.tool)
        self.assertNotEqual(result.returncode, 0)
        self.assertIn("toolchain keys changed", result.stderr)

    def test_module_relative_absolute_and_traversal_are_refused(self) -> None:
        for bad in ("/tmp/Swift.swiftmodule", "../Swift.swiftmodule"):
            with self.subTest(bad=bad):
                policy = self.read_policy()
                policy["toolchain"]["swift_module_relative"] = bad
                self.write_policy(policy)
                result = self.run_tool("assets", self.tool)
                self.assertNotEqual(result.returncode, 0)
                self.assertIn("swift_module_relative", result.stderr)
                self.write_policy(json.loads(POLICY.read_text()))

    def test_isolated_bundle_relative_traversal_is_refused(self) -> None:
        policy = self.read_policy()
        policy["isolated_inputs"]["swift_module"]["bundle_relative"] = (
            "../Swift.swiftmodule"
        )
        self.write_policy(policy)
        result = self.run_tool("assets", self.tool)
        self.assertNotEqual(result.returncode, 0)
        self.assertIn("bundle_relative", result.stderr)

    def test_dispatch_input_path_traversal_is_refused(self) -> None:
        policy = self.read_policy()
        policy["dispatch_boundary"]["libswift_dispatch_tbd_path"] = (
            "/work/fe/sysroot/usr/lib/swift/../libswiftDispatch.tbd"
        )
        self.write_policy(policy)
        result = self.run_tool("assets", self.tool)
        self.assertNotEqual(result.returncode, 0)
        self.assertIn("tbd path scope changed", result.stderr)

    def test_link_runtime_hash_disagreement_is_refused(self) -> None:
        policy = self.read_policy()
        policy["link_inputs"]["/work/lib/libswiftCore.dylib"] = "0" * 64
        self.write_policy(policy)
        result = self.run_tool("assets", self.tool)
        self.assertNotEqual(result.returncode, 0)
        self.assertIn("link/runtime hash agreement changed", result.stderr)

    def test_oracle_contract_relaxation_is_refused(self) -> None:
        policy = self.read_policy()
        policy["oracles"]["mutated_exit"] = 0
        self.write_policy(policy)
        result = self.run_tool("assets", self.tool)
        self.assertNotEqual(result.returncode, 0)
        self.assertIn("oracle contract changed", result.stderr)

    def test_oracle_discriminator_substring_or_stream_change_is_refused(self) -> None:
        for key, value in (
            ("mutated_line", "ORACLE_FAIL received=[3, 5, 9] stored=[3, 3, 5]"),
            ("positive_stream", "stderr"),
        ):
            with self.subTest(key=key):
                policy = self.read_policy()
                policy["oracles"][key] = value
                self.write_policy(policy)
                result = self.run_tool("assets", self.tool)
                self.assertNotEqual(result.returncode, 0)
                self.assertIn("oracle contract changed", result.stderr)
                self.write_policy(json.loads(POLICY.read_text()))

    def test_dispatch_failure_discriminator_change_is_refused(self) -> None:
        policy = self.read_policy()
        policy["dispatch_boundary"]["expected_interface_error_line"] = (
            "error: no such module '_StringProcessing'"
        )
        self.write_policy(policy)
        result = self.run_tool("assets", self.tool)
        self.assertNotEqual(result.returncode, 0)
        self.assertIn("interface-error discriminator changed", result.stderr)

    def test_dispatch_absence_relaxation_is_refused(self) -> None:
        policy = self.read_policy()
        policy["dispatch_boundary"]["expected_target_compatible_module_count"] = 1
        self.write_policy(policy)
        result = self.run_tool("assets", self.tool)
        self.assertNotEqual(result.returncode, 0)
        self.assertIn("must remain zero", result.stderr)

    def make_dispatch_fixture(self) -> Path:
        policy = self.read_policy()
        work = self.base / "work"
        bundle = work / "fe/sysroot/usr/lib/swift/Dispatch.swiftmodule"
        bundle.mkdir(parents=True)
        for rel in policy["dispatch_boundary"]["dispatch_swiftmodule_bundle_files"]:
            path = bundle / rel
            path.write_bytes((rel + "\n").encode())
            policy["dispatch_boundary"]["dispatch_swiftmodule_bundle_files"][rel] = (
                hashlib.sha256(path.read_bytes()).hexdigest()
            )
        self.write_policy(policy)
        return work

    def test_dispatch_bundle_is_recorded_and_target_module_is_absent(self) -> None:
        work = self.make_dispatch_fixture()
        audit_path = self.base / "dispatch.json"
        result = self.run_tool("dispatch", work, audit_path)
        self.assertEqual(result.returncode, 0, result.stderr)
        audit = json.loads(audit_path.read_text())
        self.assertEqual(
            audit["dispatch_swiftmodule_entries"],
            [{"kind": "directory", "path": "/work/fe/sysroot/usr/lib/swift/Dispatch.swiftmodule"}],
        )
        self.assertEqual(len(audit["bundle_files"]), 8)
        self.assertEqual(audit["target_compatible_modules_or_interfaces"], [])
        self.assertEqual(audit["libswift_dispatch_dylibs"], [])

    def test_target_compatible_dispatch_module_is_refused(self) -> None:
        work = self.make_dispatch_fixture()
        bundle = work / "fe/sysroot/usr/lib/swift/Dispatch.swiftmodule"
        (bundle / "arm64-apple-macos.swiftinterface").write_text("// drift\n")
        result = self.run_tool("dispatch", work, self.base / "dispatch.json")
        self.assertNotEqual(result.returncode, 0)
        self.assertIn("target-compatible Dispatch", result.stderr)

    def test_empty_dispatch_bundle_directory_is_refused(self) -> None:
        work = self.make_dispatch_fixture()
        bundle = work / "fe/sysroot/usr/lib/swift/Dispatch.swiftmodule"
        (bundle / "unreviewed-empty-directory").mkdir()
        result = self.run_tool("dispatch", work, self.base / "dispatch.json")
        self.assertNotEqual(result.returncode, 0)
        self.assertIn("bundle directory count changed", result.stderr)

    def test_standalone_dispatch_swiftmodule_file_is_refused(self) -> None:
        work = self.base / "work"
        standalone = work / "fe/sysroot/usr/lib/swift/Dispatch.swiftmodule"
        standalone.parent.mkdir(parents=True)
        standalone.write_bytes(b"standalone module drift\n")
        result = self.run_tool("dispatch", work, self.base / "dispatch.json")
        self.assertNotEqual(result.returncode, 0)
        self.assertIn("entry kind changed", result.stderr)

    def test_libswift_dispatch_runtime_appearance_is_refused(self) -> None:
        work = self.make_dispatch_fixture()
        runtime = work / "lib/libswiftDispatch.dylib"
        runtime.parent.mkdir(parents=True)
        runtime.write_bytes(b"drift\n")
        result = self.run_tool("dispatch", work, self.base / "dispatch.json")
        self.assertNotEqual(result.returncode, 0)
        self.assertIn("libswiftDispatch.dylib count changed", result.stderr)

    @staticmethod
    def macho_block(index: int, kind: str, path: str, compat: str, current: str) -> str:
        return (
            f"Load command {index}\n"
            f"          cmd {kind}\n"
            "      cmdsize 64\n"
            f"         name {path} (offset 24)\n"
            "   time stamp 0 Thu Jan  1 00:00:00 1970\n"
            f"      current version {current}\n"
            f"compatibility version {compat}\n"
        )

    def test_macho_load_parser_captures_kinds_versions_and_spellings(self) -> None:
        raw = self.base / "all-headers.txt"
        expected = self.base / "expected-loads.txt"
        parsed = self.base / "parsed-loads.txt"
        records = [
            ("LC_ID_DYLIB", "/usr/lib/libSubject.dylib", "0.0.0", "0.0.0"),
            ("LC_LOAD_DYLIB", "/usr/lib/libSystem.B.dylib", "1.0.0", "1.2.3"),
            ("LC_LOAD_WEAK_DYLIB", "@rpath/libDynamic.dylib", "2.0.0", "2.4.0"),
            ("LC_REEXPORT_DYLIB", "/System/Library/Frameworks/Foundation.framework/Foundation", "1.0.0", "9.0.0"),
            ("LC_LOAD_UPWARD_DYLIB", "@loader_path/libSibling.dylib", "0.0.0", "3.0.0"),
            ("LC_LAZY_LOAD_DYLIB", "@executable_path/libLazy.dylib", "0.0.0", "0.1.0"),
        ]
        raw.write_text("Mach header\n" + "".join(
            self.macho_block(index, *record) for index, record in enumerate(records)
        ))
        expected.write_text("\n".join("\t".join(record) for record in records) + "\n")
        result = self.run_tool("verify-loads", raw, expected, parsed)
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(parsed.read_text().splitlines(), ["\t".join(r) for r in records])

    def test_macho_load_parser_rejects_version_mutation(self) -> None:
        raw = self.base / "all-headers.txt"
        expected = self.base / "expected-loads.txt"
        parsed = self.base / "parsed-loads.txt"
        raw.write_text(self.macho_block(0, "LC_LOAD_DYLIB", "/usr/lib/libA.dylib", "1.0.0", "2.0.0"))
        expected.write_text("LC_LOAD_DYLIB\t/usr/lib/libA.dylib\t1.0.0\t2.0.1\n")
        result = self.run_tool("verify-loads", raw, expected, parsed)
        self.assertNotEqual(result.returncode, 0)
        self.assertIn("load records or order changed", result.stderr)

    def test_macho_load_parser_rejects_weak_and_reexport_kind_mutations(self) -> None:
        for actual_kind, expected_kind in (
            ("LC_LOAD_WEAK_DYLIB", "LC_LOAD_DYLIB"),
            ("LC_REEXPORT_DYLIB", "LC_LOAD_DYLIB"),
        ):
            with self.subTest(actual_kind=actual_kind):
                raw = self.base / f"{actual_kind}.txt"
                expected = self.base / f"{actual_kind}.expected"
                parsed = self.base / f"{actual_kind}.parsed"
                raw.write_text(self.macho_block(0, actual_kind, "@rpath/libA.dylib", "0.0.0", "0.0.0"))
                expected.write_text(f"{expected_kind}\t@rpath/libA.dylib\t0.0.0\t0.0.0\n")
                result = self.run_tool("verify-loads", raw, expected, parsed)
                self.assertNotEqual(result.returncode, 0)
                self.assertIn("load records or order changed", result.stderr)

    def test_macho_load_parser_rejects_unknown_dylib_kind(self) -> None:
        raw = self.base / "all-headers.txt"
        expected = self.base / "expected-loads.txt"
        parsed = self.base / "parsed-loads.txt"
        raw.write_text(self.macho_block(0, "LC_PREBOUND_DYLIB", "/usr/lib/libA.dylib", "0.0.0", "0.0.0"))
        expected.write_text("LC_LOAD_DYLIB\t/usr/lib/libA.dylib\t0.0.0\t0.0.0\n")
        result = self.run_tool("verify-loads", raw, expected, parsed)
        self.assertNotEqual(result.returncode, 0)
        self.assertIn("unsupported Mach-O dylib load kind", result.stderr)

    def test_dispatch_error_normalizer_keeps_driver_and_file_headlines(self) -> None:
        raw = self.base / "dispatch.stderr"
        normalized = self.base / "dispatch.errors"
        prefix = "/tmp/opencombine-core.fixture"
        raw.write_text(
            "warning: expected warning\n"
            "error: driver-level failure\n"
            "fatal error: fatal driver-level failure\n"
            f"{prefix}/source/File.swift:8:8: error: source failure\n"
            f"{prefix}/source/Header.h:9:9: fatal error: header failure\n"
            "<unknown>:0: error: unknown failure\n"
            "  8 | import Dispatch\n"
            "    |        `- error: rendered detail, not a headline\n"
        )
        result = self.run_tool(
            "normalize-dispatch-errors", raw, prefix, normalized
        )
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(
            normalized.read_text().splitlines(),
            [
                "error: driver-level failure",
                "fatal error: fatal driver-level failure",
                "<SUBJECT>/source/File.swift:8:8: error: source failure",
                "<SUBJECT>/source/Header.h:9:9: fatal error: header failure",
                "<unknown>:0: error: unknown failure",
            ],
        )

    def make_module_tree_fixture(self) -> Path:
        root = self.base / "Swift.swiftmodule"
        root.mkdir()
        for index in range(6):
            (root / f"fixture-{index}.swiftmodule").write_bytes(f"module {index}\n".encode())
        digest, dirs, files, symlinks = digest_input_tree(root)
        policy = self.read_policy()
        subject = policy["isolated_inputs"]["swift_module"]
        subject.update(directory_count=dirs, file_count=files, symlink_count=symlinks, sha256=digest)
        self.write_policy(policy)
        return root

    def test_isolated_tree_attestation_and_content_drift(self) -> None:
        root = self.make_module_tree_fixture()
        manifest = self.base / "module.nul"
        audit = self.base / "module.json"
        valid = self.run_tool("tree", "swift_module", root, manifest, audit)
        self.assertEqual(valid.returncode, 0, valid.stderr)
        self.assertEqual(json.loads(audit.read_text())["file_count"], 6)
        with (root / "fixture-0.swiftmodule").open("ab") as stream:
            stream.write(b"drift")
        changed = self.run_tool("tree", "swift_module", root, manifest, audit)
        self.assertNotEqual(changed.returncode, 0)
        self.assertIn("tree digest changed", changed.stderr)

    def test_isolated_tree_inventory_and_symlink_drift(self) -> None:
        root = self.make_module_tree_fixture()
        manifest = self.base / "module.nul"
        audit = self.base / "module.json"
        (root / "shadow.swiftmodule").write_bytes(b"shadow\n")
        expanded = self.run_tool("tree", "swift_module", root, manifest, audit)
        self.assertNotEqual(expanded.returncode, 0)
        self.assertIn("file denominator changed", expanded.stderr)
        (root / "shadow.swiftmodule").unlink()
        (root / "shadow-link").symlink_to("fixture-0.swiftmodule")
        linked = self.run_tool("tree", "swift_module", root, manifest, audit)
        self.assertNotEqual(linked.returncode, 0)
        self.assertIn("symlink denominator changed", linked.stderr)

    def make_runtime_fixture(self) -> Path:
        policy = self.read_policy()
        root = self.base / "runtime"
        for rel in policy["runtime_root"]["files"]:
            path = root / rel
            path.parent.mkdir(parents=True, exist_ok=True)
            path.write_bytes((rel + "\n").encode())
            policy["runtime_root"]["files"][rel] = hashlib.sha256(
                path.read_bytes()
            ).hexdigest()
        pairs = {
            "/work/lib/libc++abi.dylib": "darwin/usr/lib/libc++abi.dylib",
            "/work/lib/libobjc.A.dylib": "darwin/usr/lib/libobjc.A.dylib",
            "/work/lib/libswiftCore.dylib": "darwin/usr/lib/swift/libswiftCore.dylib",
            "/work/lib/libswiftcompat.dylib": "darwin/usr/lib/libswiftcompat.dylib",
        }
        for link, runtime in pairs.items():
            policy["link_inputs"][link] = policy["runtime_root"]["files"][runtime]
        self.write_policy(policy)
        return root

    def write_tree_manifest(self, root: Path, paths: list[str]) -> Path:
        manifest = self.base / "tree.manifest.nul"
        records = bytearray()
        for rel in sorted(paths):
            records.extend(hashlib.sha256((root / rel).read_bytes()).hexdigest().encode())
            records.extend(b"\0")
            records.extend(rel.encode())
            records.extend(b"\0")
        manifest.write_bytes(records)
        return manifest

    def test_runtime_exact_subject_and_mutations(self) -> None:
        root = self.make_runtime_fixture()
        valid = self.run_tool("runtime", root)
        self.assertEqual(valid.returncode, 0, valid.stderr)

        target = root / "darwin/usr/lib/libSystem.real.dylib"
        with target.open("ab") as stream:
            stream.write(b"mutation")
        changed = self.run_tool("runtime", root)
        self.assertNotEqual(changed.returncode, 0)
        self.assertIn("runtime-root hash changed", changed.stderr)

        target.write_bytes(("darwin/usr/lib/libSystem.real.dylib\n").encode())
        extra = root / "darwin/usr/lib/unreviewed.dylib"
        extra.write_bytes(b"extra")
        expanded = self.run_tool("runtime", root)
        self.assertNotEqual(expanded.returncode, 0)
        self.assertIn("runtime-root file inventory changed", expanded.stderr)

    def test_runtime_symlink_directory_is_refused(self) -> None:
        root = self.make_runtime_fixture()
        (root / "linked-directory").symlink_to(root / "darwin", target_is_directory=True)
        result = self.run_tool("runtime", root)
        self.assertNotEqual(result.returncode, 0)
        self.assertIn("runtime root contains a symlink", result.stderr)

    def test_export_tree_manifest_rejects_hash_and_inventory_drift(self) -> None:
        root = self.base / "export"
        (root / "nested").mkdir(parents=True)
        (root / "RESULT.txt").write_text("PASS\n")
        (root / "nested/artifact with space").write_bytes(b"artifact\n")
        manifest = self.write_tree_manifest(
            root, ["RESULT.txt", "nested/artifact with space"]
        )
        valid = self.run_tool("verify-tree", root, manifest)
        self.assertEqual(valid.returncode, 0, valid.stderr)

        (root / "RESULT.txt").write_text("false green\n")
        changed = self.run_tool("verify-tree", root, manifest)
        self.assertNotEqual(changed.returncode, 0)
        self.assertIn("manifest-tree hash changed", changed.stderr)

        (root / "RESULT.txt").write_text("PASS\n")
        (root / "unreviewed").write_bytes(b"extra")
        expanded = self.run_tool("verify-tree", root, manifest)
        self.assertNotEqual(expanded.returncode, 0)
        self.assertIn("manifest-tree file inventory changed", expanded.stderr)

    def test_export_tree_manifest_rejects_path_traversal(self) -> None:
        root = self.base / "export"
        root.mkdir()
        (root / "artifact").write_bytes(b"artifact\n")
        digest = hashlib.sha256(b"artifact\n").hexdigest().encode()
        manifest = self.base / "traversal.manifest.nul"
        manifest.write_bytes(digest + b"\0../artifact\0")
        result = self.run_tool("verify-tree", root, manifest)
        self.assertNotEqual(result.returncode, 0)
        self.assertIn("unsafe path", result.stderr)

    def test_export_tree_manifest_rejects_nonregular_entry(self) -> None:
        root = self.base / "export"
        root.mkdir()
        (root / "artifact").write_bytes(b"artifact\n")
        manifest = self.write_tree_manifest(root, ["artifact"])
        os.mkfifo(root / "unexpected-fifo")
        result = self.run_tool("verify-tree", root, manifest)
        self.assertNotEqual(result.returncode, 0)
        self.assertIn("non-regular file", result.stderr)


class WrapperGuardTests(unittest.TestCase):
    def test_existing_output_refused_before_heavy_inputs(self) -> None:
        with tempfile.TemporaryDirectory(prefix="opencombine-existing.", dir=ROOT / "scratch") as out:
            result = subprocess.run(
                ["bash", str(HERE / "build_and_run.sh"), out],
                text=True,
                capture_output=True,
            )
            self.assertEqual(result.returncode, 2)
            self.assertIn("output path already exists", result.stderr)

    def test_output_outside_scratch_is_refused(self) -> None:
        candidate = Path(tempfile.gettempdir()) / "opencombine-outside-policy"
        result = subprocess.run(
            ["bash", str(HERE / "build_and_run.sh"), str(candidate)],
            text=True,
            capture_output=True,
        )
        self.assertEqual(result.returncode, 2)
        self.assertIn("output must be a new child", result.stderr)

    def test_container_subject_with_path_traversal_is_refused(self) -> None:
        result = subprocess.run(
            ["bash", str(HERE / "container_build.sh"), "/tmp/opencombine-core.x/../escape"],
            text=True,
            capture_output=True,
        )
        self.assertEqual(result.returncode, 2)
        self.assertIn("one safe path segment", result.stderr)


if __name__ == "__main__":
    unittest.main()
