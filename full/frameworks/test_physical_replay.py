#!/usr/bin/env python3
"""Behavior tests for physical cold-replay preparation and input snapshots."""

from __future__ import annotations

import json
import hashlib
import os
from pathlib import Path
import stat
import subprocess
import tempfile
import unittest


HERE = Path(__file__).resolve().parent
TOOL = HERE / "physical_replay.py"
HOST_WRAPPER = HERE / "run_core_guest_package_docker.sh"


class PhysicalReplayTests(unittest.TestCase):
    def setUp(self) -> None:
        self.temporary = tempfile.TemporaryDirectory()
        self.root = Path(self.temporary.name)

    def tearDown(self) -> None:
        self.temporary.cleanup()

    def run_tool(
        self, *arguments: str | Path, expected: int = 0
    ) -> subprocess.CompletedProcess[str]:
        result = subprocess.run(
            ["python3", "-B", str(TOOL), *(str(value) for value in arguments)],
            text=True,
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
            check=False,
        )
        self.assertEqual(
            result.returncode,
            expected,
            f"stdout:\n{result.stdout}\nstderr:\n{result.stderr}",
        )
        return result

    def make_git_repository(
        self,
        path: Path,
        name: str,
        *,
        ignore_runtime: bool = False,
        ignore_scratch: bool = False,
    ) -> tuple[str, str]:
        path.mkdir(parents=True)
        subprocess.run(["git", "init", "--quiet", str(path)], check=True)
        subprocess.run(
            ["git", "-C", str(path), "config", "user.email", "fixture@example.test"],
            check=True,
        )
        subprocess.run(
            ["git", "-C", str(path), "config", "user.name", "Replay Fixture"],
            check=True,
        )
        (path / "tracked.txt").write_text(f"{name}\n", encoding="utf-8")
        ignores = []
        if ignore_runtime:
            ignores.extend(("build/", "darwin/usr/"))
        if ignore_scratch:
            ignores.extend(("build/", "scratch/"))
        if ignores:
            (path / ".gitignore").write_text(
                "\n".join(dict.fromkeys(ignores)) + "\n", encoding="utf-8"
            )
        subprocess.run(["git", "-C", str(path), "add", "."], check=True)
        subprocess.run(
            ["git", "-C", str(path), "commit", "--quiet", "-m", name], check=True
        )
        commit = subprocess.check_output(
            ["git", "-C", str(path), "rev-parse", "HEAD"], text=True
        ).strip()
        tree = subprocess.check_output(
            ["git", "-C", str(path), "rev-parse", "HEAD^{tree}"], text=True
        ).strip()
        return commit, tree

    def test_copy_tree_preserves_semantics_without_any_source_hardlinks(self) -> None:
        source = self.root / "source"
        source.mkdir()
        executable = source / "tool"
        executable.write_bytes(b"executable payload\n")
        executable.chmod(0o751)
        hardlink = source / "tool-again"
        os.link(executable, hardlink)
        empty = source / "empty"
        empty.mkdir()
        (source / "tool-link").symlink_to("tool")

        destination = self.root / "destination"
        report = self.root / "copy.json"
        self.run_tool(
            "copy-tree",
            "--source",
            source,
            "--destination",
            destination,
            "--label",
            "fixture",
            "--output",
            report,
        )

        self.assertEqual((destination / "tool").read_bytes(), executable.read_bytes())
        self.assertEqual(stat.S_IMODE((destination / "tool").stat().st_mode), 0o751)
        self.assertEqual(os.readlink(destination / "tool-link"), "tool")
        self.assertTrue((destination / "empty").is_dir())
        source_inodes = {executable.stat().st_ino, hardlink.stat().st_ino}
        copied_inodes = {
            (destination / "tool").stat().st_ino,
            (destination / "tool-again").stat().st_ino,
        }
        self.assertTrue(source_inodes.isdisjoint(copied_inodes))
        self.assertEqual(len(copied_inodes), 2)
        evidence = json.loads(report.read_text(encoding="ascii"))
        self.assertEqual(evidence["format"], "core-guest-physical-copy-v1")
        self.assertEqual(evidence["files"], 2)
        self.assertEqual(evidence["symlinks"], 1)
        self.assertEqual(len(evidence["manifest_sha256"]), 64)

    def test_copy_tree_rejects_special_files_and_removes_partial_copy(self) -> None:
        source = self.root / "source"
        source.mkdir()
        (source / "ordinary").write_text("ordinary", encoding="utf-8")
        os.mkfifo(source / "pipe")
        destination = self.root / "destination"
        result = self.run_tool(
            "copy-tree",
            "--source",
            source,
            "--destination",
            destination,
            "--label",
            "fixture",
            "--output",
            self.root / "copy.json",
            expected=2,
        )
        self.assertIn("unsupported input file type", result.stderr)
        self.assertFalse(destination.exists())

        overlap = self.run_tool(
            "copy-tree",
            "--source",
            source,
            "--destination",
            source / "nested-copy",
            "--label",
            "overlap",
            "--output",
            self.root / "overlap.json",
            expected=2,
        )
        self.assertIn("overlaps its source", overlap.stderr)
        self.assertFalse((source / "nested-copy").exists())

    def test_snapshot_excludes_only_named_fresh_paths_and_detects_input_drift(self) -> None:
        replay = self.root / "replay"
        (replay / "input").mkdir(parents=True)
        (replay / "input/source.swift").write_text("let value = 1\n", encoding="utf-8")
        (replay / "input/link").symlink_to("source.swift")
        (replay / "fresh/cache").mkdir(parents=True)
        (replay / "fresh/cache/generated").write_text("before", encoding="utf-8")
        before = self.root / "before.jsonl"
        after_fresh = self.root / "after-fresh.jsonl"
        self.run_tool(
            "snapshot",
            "--root",
            replay,
            "--output",
            before,
            "--exclude",
            "fresh/cache",
        )

        records = [json.loads(line) for line in before.read_text(encoding="ascii").splitlines()]
        source_record = next(record for record in records if record.get("path") == "input/source.swift")
        link_record = next(record for record in records if record.get("path") == "input/link")
        self.assertEqual(source_record["type"], "file")
        self.assertEqual(source_record["mode"], "0644")
        self.assertEqual(len(source_record["sha256"]), 64)
        self.assertEqual(link_record["type"], "symlink")
        self.assertEqual(link_record["target"], "source.swift")
        self.assertNotIn(
            "fresh/cache/generated", {record.get("path") for record in records}
        )

        (replay / "fresh/cache/generated").write_text("after", encoding="utf-8")
        self.run_tool(
            "snapshot",
            "--root",
            replay,
            "--output",
            after_fresh,
            "--exclude",
            "fresh/cache",
        )
        self.run_tool("compare", "--before", before, "--after", after_fresh)

        (replay / "input/source.swift").write_text("let value = 2\n", encoding="utf-8")
        after_input = self.root / "after-input.jsonl"
        self.run_tool(
            "snapshot",
            "--root",
            replay,
            "--output",
            after_input,
            "--exclude",
            "fresh/cache",
        )
        result = self.run_tool(
            "compare",
            "--before",
            before,
            "--after",
            after_input,
            expected=2,
        )
        self.assertIn("changed input/source.swift", result.stderr)

    def test_snapshot_detects_mode_and_symlink_target_drift(self) -> None:
        replay = self.root / "replay"
        replay.mkdir()
        regular = replay / "regular"
        regular.write_text("payload", encoding="utf-8")
        regular.chmod(0o644)
        link = replay / "link"
        link.symlink_to("regular")
        before = self.root / "before.jsonl"
        self.run_tool("snapshot", "--root", replay, "--output", before)

        regular.chmod(0o600)
        link.unlink()
        link.symlink_to("missing")
        after = self.root / "after.jsonl"
        self.run_tool("snapshot", "--root", replay, "--output", after)
        result = self.run_tool(
            "compare", "--before", before, "--after", after, expected=2
        )
        self.assertIn("changed link", result.stderr)
        self.assertIn("changed regular", result.stderr)

    def test_copy_file_is_physical_and_cleanup_is_parent_scoped(self) -> None:
        source = self.root / "source"
        source.write_bytes(b"preview input")
        source.chmod(0o744)
        replay = self.root / "run/replay"
        replay.mkdir(parents=True)
        destination = replay / "copied"
        report = self.root / "copy.json"
        self.run_tool(
            "copy-file",
            "--source",
            source,
            "--destination",
            destination,
            "--label",
            "preview",
            "--output",
            report,
        )
        self.assertNotEqual(source.stat().st_ino, destination.stat().st_ino)
        self.assertEqual(stat.S_IMODE(destination.stat().st_mode), 0o744)

        refused = self.run_tool(
            "remove-tree",
            "--path",
            replay,
            "--expected-parent",
            self.root,
            expected=2,
        )
        self.assertIn("not a direct child", refused.stderr)
        self.run_tool(
            "remove-tree",
            "--path",
            replay,
            "--expected-parent",
            replay.parent,
        )
        self.assertFalse(replay.exists())

    def test_publish_is_same_filesystem_direct_child_rename(self) -> None:
        source = self.root / "run/replay/w/build/core-package"
        source.mkdir(parents=True)
        (source / "PACKAGE_COMPLETE").write_text("complete\n", encoding="utf-8")
        output_parent = self.root / "published"
        output_parent.mkdir()
        destination = output_parent / "core-package"
        self.run_tool(
            "publish",
            "--source",
            source,
            "--destination",
            destination,
            "--expected-parent",
            output_parent,
        )
        self.assertFalse(source.exists())
        self.assertEqual(
            (destination / "PACKAGE_COMPLETE").read_text(encoding="utf-8"),
            "complete\n",
        )

        second = self.root / "second"
        second.mkdir()
        refused = self.run_tool(
            "publish",
            "--source",
            second,
            "--destination",
            output_parent / "nested/core-package",
            "--expected-parent",
            output_parent,
            expected=2,
        )
        self.assertIn("not a direct child", refused.stderr)

    def test_host_wrapper_prepares_one_physical_bind_before_fake_docker(self) -> None:
        support = self.root / "support"
        uikit = self.root / "uikit"
        machorun = self.root / "machorun"
        support_commit, support_tree = self.make_git_repository(
            support, "support", ignore_scratch=True
        )
        uikit_commit, uikit_tree = self.make_git_repository(uikit, "uikit")
        machorun_commit, machorun_tree = self.make_git_repository(
            machorun, "machorun", ignore_runtime=True
        )
        loader = machorun / "build/machorun"
        loader.parent.mkdir(parents=True)
        loader.write_bytes(b"ignored loader\n")
        loader.chmod(0o755)
        runtime = machorun / "darwin/usr/lib/libSystem.B.dylib"
        runtime.parent.mkdir(parents=True)
        runtime.write_bytes(b"runtime\n")
        loader_hash = hashlib.sha256(loader.read_bytes()).hexdigest()

        staged = self.root / "staged"
        for relative in ("sysroot_fe4", "mrroot", "mrroot_fe"):
            (staged / relative).mkdir(parents=True)
            (staged / relative / "input").write_text(relative, encoding="utf-8")
        self.make_git_repository(staged / "swift-foundation", "foundation")
        self.make_git_repository(staged / "swift-collections", "collections")
        opencombine = staged / "opencombine-core-durable-20260828-r2"
        self.make_git_repository(opencombine / "source", "opencombine")
        (opencombine / "export/artifacts").mkdir(parents=True)
        (opencombine / "export/artifacts/result.json").write_text(
            "{}\n", encoding="utf-8"
        )

        preview_module = self.root / "DeveloperToolsSupport.swiftmodule"
        preview_object = self.root / "developertoolsupport.o"
        preview_plugin = self.root / "OpenUIKitPreviewMacros-tool"
        for path, payload in (
            (preview_module, b"module"),
            (preview_object, b"object"),
            (preview_plugin, b"plugin"),
        ):
            path.write_bytes(payload)
        preview_plugin.chmod(0o755)

        image = "sha256:" + "a" * 64
        docker_arguments = self.root / "docker-arguments.txt"
        fake_bin = self.root / "bin"
        fake_bin.mkdir()
        fake_docker = fake_bin / "docker"
        fake_docker.write_text(
            "#!/bin/sh\n"
            "if [ \"$1\" = image ] && [ \"$2\" = inspect ]; then\n"
            "  case \"$4\" in\n"
            "    '{{.Id}}') printf '%s\\n' \"$FAKE_IMAGE\" ;;\n"
            "    '{{.Os}}/{{.Architecture}}') printf '%s\\n' linux/arm64 ;;\n"
            "    *) exit 92 ;;\n"
            "  esac\n"
            "  exit 0\n"
            "fi\n"
            "[ \"$1\" = run ] || exit 93\n"
            "printf '%s\\n' \"$@\" > \"$FAKE_DOCKER_ARGUMENTS\"\n"
            "exit 37\n",
            encoding="utf-8",
        )
        fake_docker.chmod(0o755)
        output = self.root / "output/core-package"
        output.parent.mkdir()
        environment = os.environ.copy()
        environment.update(
            {
                "FAKE_DOCKER_ARGUMENTS": str(docker_arguments),
                "FAKE_IMAGE": image,
                "PATH": f"{fake_bin}:{environment['PATH']}",
            }
        )
        result = subprocess.run(
            [
                "/bin/bash",
                str(HOST_WRAPPER),
                "--container-image",
                image,
                "--support-checkout",
                str(support),
                "--expected-support-commit",
                support_commit,
                "--expected-support-tree",
                support_tree,
                "--staged-input-root",
                str(staged),
                "--uikit-checkout",
                str(uikit),
                "--expected-uikit-commit",
                uikit_commit,
                "--expected-uikit-tree",
                uikit_tree,
                "--machorun-checkout",
                str(machorun),
                "--expected-machorun-commit",
                machorun_commit,
                "--expected-machorun-tree",
                machorun_tree,
                "--expected-machorun-loader-sha256",
                loader_hash,
                "--developer-tools-support-module",
                str(preview_module),
                "--developer-tools-support-object",
                str(preview_object),
                "--preview-macro-plugin",
                str(preview_plugin),
                "--output-root",
                str(output),
            ],
            text=True,
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
            env=environment,
            check=False,
        )
        self.assertEqual(result.returncode, 37, result.stderr)
        arguments = docker_arguments.read_text(encoding="utf-8").splitlines()
        self.assertEqual(arguments.count("-v"), 1)
        bind = arguments[arguments.index("-v") + 1]
        self.assertTrue(bind.endswith("/replay:/replay:rw"), bind)
        self.assertIn("--network", arguments)
        self.assertEqual(arguments[arguments.index("--network") + 1], "none")
        self.assertIn("--read-only", arguments)
        self.assertEqual(arguments.count("--tmpfs"), 1)
        tmpfs_values = [
            arguments[index + 1]
            for index, argument in enumerate(arguments)
            if argument == "--tmpfs"
        ]
        self.assertFalse(any(value.startswith("/replay/") for value in tmpfs_values))
        for original in (support, uikit, machorun, staged):
            self.assertFalse(any(str(original) in argument for argument in arguments))
        self.assertIn(
            "/replay/inputs/preview/DeveloperToolsSupport.swiftmodule", arguments
        )
        self.assertIn("/replay/inputs/preview/developertoolsupport.o", arguments)
        self.assertIn(
            "/replay/inputs/preview/OpenUIKitPreviewMacros-tool", arguments
        )

        quarantines = list(output.parent.glob(".core-guest-run.*.INVALID-DO-NOT-USE"))
        self.assertEqual(len(quarantines), 1, result.stderr)
        replay = quarantines[0] / "replay"
        copied_loader = replay / "machorun/build/machorun"
        self.assertEqual(copied_loader.read_bytes(), loader.read_bytes())
        self.assertNotEqual(copied_loader.stat().st_ino, loader.stat().st_ino)
        copied_preview = replay / "inputs/preview/DeveloperToolsSupport.swiftmodule"
        self.assertEqual(copied_preview.read_bytes(), preview_module.read_bytes())
        self.assertNotEqual(copied_preview.stat().st_ino, preview_module.stat().st_ino)
        self.assertTrue((quarantines[0] / "evidence/input-manifest.pre.jsonl").is_file())


if __name__ == "__main__":
    unittest.main()
