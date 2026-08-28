#!/usr/bin/env python3
"""Positive and adversarial controls for Focus generated-source pins."""

from __future__ import annotations

from pathlib import Path
import os
import plistlib
import sys
import tempfile
import unittest
from unittest.mock import patch
import zipfile

import generated_sources as subject


FOCUS_CHECKOUT_VALUE = os.environ.get("FOCUS_IOS_CHECKOUT")
FOCUS_REPOSITORY = (
    Path(FOCUS_CHECKOUT_VALUE).expanduser().resolve() if FOCUS_CHECKOUT_VALUE else None
)


def require_checkout(test: unittest.TestCase, path: Path | None, variable: str) -> Path:
    if path is None or not path.is_dir():
        test.skipTest(f"set {variable} to the required pinned checkout")
    return path


class GitIsolationTests(unittest.TestCase):
    @staticmethod
    def make_repository(path: Path, payload: str) -> str:
        subject.subprocess.run(["git", "init", "-q", str(path)], check=True)
        (path / "subject.txt").write_text(payload, encoding="utf-8")
        subject.subprocess.run(
            ["git", "-C", str(path), "add", "subject.txt"], check=True
        )
        subject.subprocess.run(
            [
                "git",
                "-C",
                str(path),
                "-c",
                "user.name=Focus provenance test",
                "-c",
                "user.email=focus-provenance@example.invalid",
                "commit",
                "-q",
                "-m",
                "fixture",
            ],
            check=True,
        )
        return subject.subprocess.check_output(
            ["git", "-C", str(path), "rev-parse", "HEAD"], text=True
        ).strip()

    def test_git_attestation_ignores_ambient_repository_redirection(self) -> None:
        with tempfile.TemporaryDirectory(prefix="focus-git-isolation.") as temp:
            root = Path(temp).resolve()
            expected_repo = root / "expected"
            redirected_repo = root / "redirected"
            expected_commit = self.make_repository(expected_repo, "expected\n")
            redirected_commit = self.make_repository(redirected_repo, "redirected\n")
            self.assertNotEqual(expected_commit, redirected_commit)

            hostile = {
                "GIT_DIR": str(redirected_repo / ".git"),
                "GIT_WORK_TREE": str(redirected_repo),
                "GIT_INDEX_FILE": str(redirected_repo / ".git/index"),
                "GIT_OBJECT_DIRECTORY": str(redirected_repo / ".git/objects"),
                "GIT_CONFIG_GLOBAL": str(root / "hostile.gitconfig"),
                "GIT_CONFIG_COUNT": "1",
                "GIT_CONFIG_KEY_0": "core.fsmonitor",
                "GIT_CONFIG_VALUE_0": "true",
            }
            with patch.dict(os.environ, hostile):
                self.assertEqual(
                    subject._git(expected_repo, "rev-parse", "HEAD"),
                    expected_commit,
                )
                controlled = subject._controlled_git_environment()

            for name in hostile:
                self.assertNotEqual(controlled.get(name), hostile[name])
            self.assertEqual(controlled["GIT_CONFIG_GLOBAL"], os.devnull)
            self.assertEqual(controlled["GIT_CONFIG_NOSYSTEM"], "1")
            self.assertEqual(controlled["GIT_NO_REPLACE_OBJECTS"], "1")
            self.assertEqual(controlled["GIT_OPTIONAL_LOCKS"], "0")


class FocusGeneratedInputIntegrationTests(unittest.TestCase):
    def test_pinned_focus_inputs_and_intent_tool_metadata_match(self) -> None:
        repo = require_checkout(self, FOCUS_REPOSITORY, "FOCUS_IOS_CHECKOUT")
        self.assertEqual(subject.verify_focus(str(repo)), repo)


class FocusGeneratedInputAdversarialTests(unittest.TestCase):
    def setUp(self) -> None:
        self.temp = tempfile.TemporaryDirectory(prefix="focus-generated-test.")
        self.root = Path(self.temp.name)
        self.repo = self.root / "focus-ios"
        self.repo.mkdir()
        self.focus_inputs: dict[str, str] = {}
        for relative in subject.FOCUS_INPUTS:
            destination = self.repo / relative
            destination.parent.mkdir(parents=True, exist_ok=True)
            if relative.endswith("Intents.intentdefinition"):
                data = plistlib.dumps(
                    {
                        "INIntentDefinitionToolsVersion": subject.INTENT_TOOLS_VERSION,
                        "INIntentDefinitionToolsBuildVersion": (
                            subject.INTENT_TOOLS_BUILD_VERSION
                        ),
                    },
                    fmt=plistlib.FMT_XML,
                    sort_keys=True,
                )
            else:
                data = f"Focus fixture: {relative}\n".encode()
            destination.write_bytes(data)
            self.focus_inputs[relative] = subject.sha256(data)

    def tearDown(self) -> None:
        self.temp.cleanup()

    @staticmethod
    def fake_git(repo: Path, *args: str) -> str:
        if args == ("rev-parse", "--verify", "HEAD^{commit}"):
            return subject.FOCUS_COMMIT
        if args == ("show", "-s", "--format=%ct", "HEAD"):
            return subject.FOCUS_COMMIT_EPOCH
        raise AssertionError(f"unexpected git invocation: {repo} {args}")

    def verify(self) -> Path:
        with patch.object(subject, "FOCUS_INPUTS", self.focus_inputs), patch.object(
            subject, "_git", side_effect=self.fake_git
        ):
            return subject.verify_focus(str(self.repo))

    def test_self_contained_fixture_is_accepted(self) -> None:
        self.assertEqual(self.verify(), self.repo.resolve())

    def test_refuses_input_byte_drift(self) -> None:
        path = self.repo / "nimbus.fml.yaml"
        changed = bytearray(path.read_bytes())
        changed[-1] ^= 1
        path.write_bytes(changed)
        with self.assertRaisesRegex(subject.GenerationError, "input hash changed"):
            self.verify()

    def test_refuses_input_symlink(self) -> None:
        path = self.repo / "Blockzilla/metrics.yaml"
        target = self.repo / "nimbus.fml.yaml"
        path.unlink()
        path.symlink_to(target)
        with self.assertRaisesRegex(subject.GenerationError, "symlink"):
            self.verify()

    def test_refuses_intent_metadata_drift_even_if_hash_policy_is_mocked(self) -> None:
        path = self.repo / "Blockzilla/Base.lproj/Intents.intentdefinition"
        intent = plistlib.loads(path.read_bytes())
        intent["INIntentDefinitionToolsVersion"] = "99.0"
        path.write_bytes(plistlib.dumps(intent, fmt=plistlib.FMT_XML, sort_keys=True))
        changed_hash = subject.sha256(path.read_bytes())
        hashes = dict(self.focus_inputs)
        hashes["Blockzilla/Base.lproj/Intents.intentdefinition"] = changed_hash
        self.focus_inputs = hashes
        with self.assertRaisesRegex(subject.GenerationError, "tools version changed"):
            self.verify()


class NimbusProvenanceAdversarialTests(unittest.TestCase):
    def setUp(self) -> None:
        self.temp = tempfile.TemporaryDirectory(prefix="focus-nimbus-provenance.")
        self.root = Path(self.temp.name).resolve()
        self.package = self.root / "rust-components-swift"
        self.appservices = self.root / "application-services"
        self.glean = self.appservices / "components/external/glean"
        self.package.mkdir()
        self.glean.mkdir(parents=True)

        self.package_inputs: dict[str, str] = {}
        for relative in subject.NIMBUS_PACKAGE_INPUTS:
            data = f"package fixture: {relative}\n".encode()
            path = self.package / relative
            path.parent.mkdir(parents=True, exist_ok=True)
            path.write_bytes(data)
            self.package_inputs[relative] = subject.sha256(data)
            prefix = "swift-source/focus/Nimbus/"
            if relative.startswith(prefix):
                mapped = (
                    self.appservices
                    / "components/nimbus/ios/Nimbus"
                    / relative.removeprefix(prefix)
                )
                mapped.parent.mkdir(parents=True, exist_ok=True)
                mapped.write_bytes(data)

        self.appservices_inputs: dict[str, str] = {}
        for relative in subject.NIMBUS_SOURCE_INPUTS:
            data = f"appservices fixture: {relative}\n".encode()
            path = self.appservices / relative
            path.parent.mkdir(parents=True, exist_ok=True)
            path.write_bytes(data)
            self.appservices_inputs[relative] = subject.sha256(data)

        self.package_dirty = ""
        self.appservices_dirty = ""
        self.glean_dirty = ""
        self.package_commit = subject.NIMBUS_PACKAGE_COMMIT
        self.package_tag = subject.NIMBUS_PACKAGE_TAG
        self.appservices_commit = subject.NIMBUS_APPSERVICES_COMMIT
        self.glean_commit = subject.NIMBUS_GLEAN_SUBMODULE_COMMIT
        self.gitlink = subject.NIMBUS_GLEAN_SUBMODULE_COMMIT
        self.runtime_tree = subject.NIMBUS_RUNTIME_TREE
        self.generator_tree = subject.NIMBUS_GENERATOR_TREE

    def tearDown(self) -> None:
        self.temp.cleanup()

    def fake_git(self, repo: Path, *args: str) -> str:
        repo = repo.resolve()
        if repo == self.package:
            if args == ("rev-parse", "--verify", "HEAD^{commit}"):
                return self.package_commit
            if args == ("describe", "--tags", "--exact-match", "HEAD"):
                return self.package_tag
            if args == ("status", "--porcelain=v1", "--untracked-files=all"):
                return self.package_dirty
        elif repo == self.appservices:
            if args == ("rev-parse", "--verify", "HEAD^{commit}"):
                return self.appservices_commit
            if args == ("rev-parse", "HEAD:components/nimbus/ios/Nimbus"):
                return self.runtime_tree
            if args == (
                "rev-parse",
                "HEAD:components/support/nimbus-fml",
            ):
                return self.generator_tree
            if args == (
                "status",
                "--porcelain=v1",
                "--untracked-files=all",
                "--ignore-submodules=none",
            ):
                return self.appservices_dirty
            if args == ("ls-tree", "HEAD", "components/external/glean"):
                return f"160000 commit {self.gitlink}\tcomponents/external/glean"
        elif repo == self.glean:
            if args == ("rev-parse", "--verify", "HEAD^{commit}"):
                return self.glean_commit
            if args == ("status", "--porcelain=v1", "--untracked-files=all"):
                return self.glean_dirty
        raise AssertionError(f"unexpected git invocation: {repo} {args}")

    def verify_package(self) -> Path:
        with patch.object(
            subject, "NIMBUS_PACKAGE_INPUTS", self.package_inputs
        ), patch.object(subject, "_git", side_effect=self.fake_git):
            return subject.verify_rust_components(str(self.package))

    def verify_appservices(self) -> Path:
        with patch.object(
            subject, "NIMBUS_SOURCE_INPUTS", self.appservices_inputs
        ), patch.object(subject, "_git", side_effect=self.fake_git):
            return subject.verify_appservices(str(self.appservices))

    def test_positive_controls_verify_both_repositories_and_mapping(self) -> None:
        self.assertEqual(self.verify_package(), self.package)
        self.assertEqual(self.verify_appservices(), self.appservices)
        with patch.object(subject, "NIMBUS_PACKAGE_INPUTS", self.package_inputs):
            subject._verify_nimbus_source_mapping(self.package, self.appservices)

    def test_rust_components_refuses_hash_drift(self) -> None:
        path = self.package / "Package.swift"
        path.write_bytes(path.read_bytes() + b"drift")
        with self.assertRaisesRegex(subject.GenerationError, "input hash changed"):
            self.verify_package()

    def test_rust_components_refuses_wrong_commit(self) -> None:
        self.package_commit = "0" * 40
        with self.assertRaisesRegex(subject.GenerationError, "pin changed"):
            self.verify_package()

    def test_rust_components_refuses_wrong_tag(self) -> None:
        self.package_tag = "unexpected-tag"
        with self.assertRaisesRegex(subject.GenerationError, "tag changed"):
            self.verify_package()

    def test_rust_components_refuses_dirty_checkout(self) -> None:
        self.package_dirty = " M Package.swift"
        with self.assertRaisesRegex(subject.GenerationError, "not clean"):
            self.verify_package()

    def test_appservices_refuses_hash_drift(self) -> None:
        path = self.appservices / "Cargo.lock"
        path.write_bytes(path.read_bytes() + b"drift")
        with self.assertRaisesRegex(subject.GenerationError, "input hash changed"):
            self.verify_appservices()

    def test_appservices_refuses_wrong_commit(self) -> None:
        self.appservices_commit = "0" * 40
        with self.assertRaisesRegex(subject.GenerationError, "pin changed"):
            self.verify_appservices()

    def test_appservices_refuses_runtime_tree_drift(self) -> None:
        self.runtime_tree = "0" * 40
        with self.assertRaisesRegex(subject.GenerationError, "runtime tree changed"):
            self.verify_appservices()

    def test_appservices_refuses_generator_tree_drift(self) -> None:
        self.generator_tree = "0" * 40
        with self.assertRaisesRegex(subject.GenerationError, "generator tree changed"):
            self.verify_appservices()

    def test_appservices_refuses_dirty_root_checkout(self) -> None:
        self.appservices_dirty = " M Cargo.lock"
        with self.assertRaisesRegex(subject.GenerationError, "not clean"):
            self.verify_appservices()

    def test_appservices_refuses_gitlink_drift(self) -> None:
        self.gitlink = "0" * 40
        with self.assertRaisesRegex(subject.GenerationError, "gitlink changed"):
            self.verify_appservices()

    def test_appservices_refuses_dirty_glean_submodule(self) -> None:
        self.glean_dirty = "?? generated-file"
        with self.assertRaisesRegex(subject.GenerationError, "submodule is not clean"):
            self.verify_appservices()

    def test_appservices_refuses_glean_submodule_head_drift(self) -> None:
        self.glean_commit = "0" * 40
        with self.assertRaisesRegex(subject.GenerationError, "submodule pin changed"):
            self.verify_appservices()

    def test_source_mapping_refuses_one_byte_mismatch(self) -> None:
        mapped = self.appservices / "components/nimbus/ios/Nimbus/Nimbus.swift"
        mapped.write_bytes(mapped.read_bytes() + b"drift")
        with patch.object(subject, "NIMBUS_PACKAGE_INPUTS", self.package_inputs):
            with self.assertRaisesRegex(
                subject.GenerationError, "source mapping changed"
            ):
                subject._verify_nimbus_source_mapping(self.package, self.appservices)


class CargoIsolationTests(unittest.TestCase):
    @staticmethod
    def version_run(command: list[str], **kwargs):
        if command[0] == "rustc":
            output = subject.NIMBUS_RUSTC_VERSION + "\n"
        elif command[0] == "cargo":
            output = subject.NIMBUS_CARGO_VERSION + "\n"
        else:
            raise AssertionError(command)
        return subject.subprocess.CompletedProcess(command, 0, output)

    def test_exact_rust_and_cargo_versions_are_accepted(self) -> None:
        environment = {"PATH": "/attested/bin"}
        with patch.object(subject, "_run", side_effect=self.version_run) as run:
            subject._verify_rust_toolchain(environment)
        for call in run.call_args_list:
            self.assertIs(call.kwargs["env"], environment)

    def test_rust_compiler_version_drift_is_refused(self) -> None:
        def run(command: list[str], **kwargs):
            output = (
                "rustc 1.76.0 (drift)\n"
                if command[0] == "rustc"
                else subject.NIMBUS_CARGO_VERSION + "\n"
            )
            return subject.subprocess.CompletedProcess(command, 0, output)

        with patch.object(subject, "_run", side_effect=run):
            with self.assertRaisesRegex(subject.GenerationError, "Rust compiler"):
                subject._verify_rust_toolchain({"PATH": "/attested/bin"})

    def test_cargo_version_drift_is_refused(self) -> None:
        def run(command: list[str], **kwargs):
            output = (
                subject.NIMBUS_RUSTC_VERSION + "\n"
                if command[0] == "rustc"
                else "cargo 1.76.0 (drift)\n"
            )
            return subject.subprocess.CompletedProcess(command, 0, output)

        with patch.object(subject, "_run", side_effect=run):
            with self.assertRaisesRegex(subject.GenerationError, "Cargo"):
                subject._verify_rust_toolchain({"PATH": "/attested/bin"})

    def test_private_cargo_environment_removes_ambient_build_overrides(self) -> None:
        with tempfile.TemporaryDirectory(prefix="focus-cargo-home.") as temp:
            cargo_home = Path(temp) / "cargo-home"
            with patch.dict(
                os.environ,
                {
                    "PATH": "/usr/bin",
                    "HOME": "/nondefault/home",
                    "CARGO_HOME": "/ambient/cargo",
                    "CARGO_TARGET_DIR": "/ambient/target",
                    "RUSTC_WRAPPER": "/ambient/wrapper",
                    "RUSTFLAGS": "--cfg ambient",
                    "GIT_CONFIG_COUNT": "1",
                    "CC_x86_64_unknown_linux_gnu": "/ambient/cc",
                    "x86_64_unknown_linux_gnu_CFLAGS": "-Dambient",
                    "PYTHONPATH": "/ambient/python",
                    "HTTPS_PROXY": "http://proxy.invalid",
                },
                clear=True,
            ):
                environment = subject._private_cargo_environment(cargo_home)
            self.assertEqual(environment["CARGO_HOME"], str(cargo_home))
            self.assertEqual(environment["CARGO_INCREMENTAL"], "0")
            self.assertEqual(environment["GIT_CONFIG_GLOBAL"], os.devnull)
            self.assertEqual(environment["GIT_CONFIG_NOSYSTEM"], "1")
            self.assertEqual(
                environment["SOURCE_DATE_EPOCH"], subject.FOCUS_COMMIT_EPOCH
            )
            self.assertEqual(environment["HTTPS_PROXY"], "http://proxy.invalid")
            self.assertEqual(environment["HOME"], "/nondefault/home")
            for refused in (
                "CARGO_TARGET_DIR",
                "RUSTC_WRAPPER",
                "RUSTFLAGS",
                "GIT_CONFIG_COUNT",
                "CC_x86_64_unknown_linux_gnu",
                "x86_64_unknown_linux_gnu_CFLAGS",
                "PYTHONPATH",
            ):
                self.assertNotIn(refused, environment)

    def test_external_cargo_configuration_is_refused(self) -> None:
        with tempfile.TemporaryDirectory(prefix="focus-cargo-config.") as temp:
            root = Path(temp).resolve()
            appservices = root / "workspace/application-services"
            (appservices / ".cargo").mkdir(parents=True)
            (appservices / ".cargo/config").write_text("[alias]\n", encoding="utf-8")
            subject._reject_external_cargo_configuration(appservices)

            external = appservices.parent / ".cargo/config.toml"
            external.parent.mkdir()
            external.write_text("[build]\ntarget-dir = 'ambient'\n", encoding="utf-8")
            with self.assertRaisesRegex(
                subject.GenerationError, "external Cargo configuration"
            ):
                subject._reject_external_cargo_configuration(appservices)


class GeneratorRefusalTests(unittest.TestCase):
    @staticmethod
    def make_fake_glean_wheel(path: Path) -> bytes:
        with zipfile.ZipFile(path, "w") as archive:
            archive.writestr("glean_parser/__init__.py", "")
            archive.writestr("glean_parser/util.py", "import datetime\n")
            archive.writestr(
                "glean_parser/translate.py",
                "from pathlib import Path\n"
                "from . import util\n"
                "def translate(inputs, output_format, output_dir, options, config):\n"
                "    utc = util.datetime.datetime.utcnow().date().isoformat()\n"
                "    local = util.datetime.datetime.now().date().isoformat()\n"
                "    payload = f'{utc}|{local}|{output_format}|{options}|{config}\\n'\n"
                "    output_dir.mkdir(parents=True, exist_ok=True)\n"
                "    (output_dir / 'Metrics.swift').write_text(payload)\n"
                "    return 0\n",
            )
            archive.writestr(
                "glean_parser-13.0.0.dist-info/METADATA",
                "Metadata-Version: 2.1\nName: glean-parser\nVersion: 13.0.0\n",
            )
        return path.read_bytes()

    def test_glean_freezes_utcnow_and_now_at_focus_commit_date(self) -> None:
        with tempfile.TemporaryDirectory(prefix="focus-glean-clock.") as temp:
            root = Path(temp)
            focus = root / "focus"
            focus.mkdir()
            wheelhouse = root / "wheelhouse"
            wheelhouse.mkdir()
            wheel = wheelhouse / subject.GLEAN_PARSER_WHEEL_FILENAME
            wheel_data = self.make_fake_glean_wheel(wheel)
            expected = (
                f"{subject.GLEAN_REFERENCE_DATE}|{subject.GLEAN_REFERENCE_DATE}|swift|"
                "{'glean_namespace': 'Glean', 'build_date': '0'}|{}\n"
            ).encode()
            output = root / "output/Metrics.swift"
            with patch.object(
                subject, "verify_focus", return_value=focus
            ), patch.object(
                subject, "GLEAN_PARSER_WHEEL_SHA256", subject.sha256(wheel_data)
            ), patch.object(
                subject, "GLEAN_OUTPUT_SHA256", subject.sha256(expected)
            ), patch.object(
                subject,
                "_prepare_isolated_glean_python",
                return_value=(Path(sys.executable), wheel),
            ):
                subject.generate_glean(
                    str(focus),
                    sys.executable,
                    str(wheelhouse),
                    str(output),
                )
            self.assertEqual(output.read_bytes(), expected)

    def test_glean_refuses_unattested_wheel_before_generation(self) -> None:
        with tempfile.TemporaryDirectory(prefix="focus-glean-refusal.") as temp:
            root = Path(temp)
            focus = root / "focus"
            focus.mkdir()
            output = root / "Metrics.swift"
            wheelhouse = root / "wheelhouse"
            wheelhouse.mkdir()
            wheel = wheelhouse / subject.GLEAN_PARSER_WHEEL_FILENAME
            wheel.write_bytes(b"not the pinned wheel")
            with patch.object(subject, "verify_focus", return_value=focus):
                with self.assertRaisesRegex(subject.GenerationError, "wheel hash"):
                    subject.generate_glean(
                        str(focus),
                        "python3",
                        str(wheelhouse),
                        str(output),
                    )
            self.assertFalse(output.exists())

    def test_glean_refuses_dependency_lock_drift_before_creating_venv(self) -> None:
        with tempfile.TemporaryDirectory(prefix="focus-glean-lock.") as temp:
            root = Path(temp)
            wheel = root / subject.GLEAN_PARSER_WHEEL_FILENAME
            wheel_data = self.make_fake_glean_wheel(wheel)
            with patch.object(
                subject, "GLEAN_PARSER_WHEEL_SHA256", subject.sha256(wheel_data)
            ), patch.object(subject, "GLEAN_DEPENDENCY_LOCK_SHA256", "0" * 64):
                with self.assertRaisesRegex(
                    subject.GenerationError, "dependency lock hash changed"
                ):
                    subject._prepare_isolated_glean_python(
                        sys.executable, str(root), root / "temporary"
                    )
            self.assertFalse((root / "temporary/venv").exists())

    def test_glean_refuses_unreviewed_generated_bytes(self) -> None:
        with tempfile.TemporaryDirectory(prefix="focus-glean-oracle.") as temp:
            root = Path(temp)
            focus = root / "focus"
            focus.mkdir()
            wheelhouse = root / "wheelhouse"
            wheelhouse.mkdir()
            wheel = wheelhouse / subject.GLEAN_PARSER_WHEEL_FILENAME
            wheel_data = self.make_fake_glean_wheel(wheel)
            output = root / "Metrics.swift"
            with patch.object(
                subject, "verify_focus", return_value=focus
            ), patch.object(
                subject, "GLEAN_PARSER_WHEEL_SHA256", subject.sha256(wheel_data)
            ), patch.object(
                subject,
                "_prepare_isolated_glean_python",
                return_value=(Path(sys.executable), wheel),
            ):
                with self.assertRaisesRegex(
                    subject.GenerationError, "generated Metrics.swift hash changed"
                ):
                    subject.generate_glean(
                        str(focus),
                        sys.executable,
                        str(wheelhouse),
                        str(output),
                    )
            self.assertFalse(output.exists())

    def test_glean_refuses_focus_mutation_during_generation(self) -> None:
        with tempfile.TemporaryDirectory(prefix="focus-glean-mutation.") as temp:
            root = Path(temp).resolve()
            focus = root / "focus"
            focus.mkdir()
            manifest = focus / "Blockzilla/metrics.yaml"
            manifest.parent.mkdir()
            original = b"pinned metrics\n"
            manifest.write_bytes(original)
            wheelhouse = root / "wheelhouse"
            wheelhouse.mkdir()
            wheel = wheelhouse / subject.GLEAN_PARSER_WHEEL_FILENAME
            wheel_data = self.make_fake_glean_wheel(wheel)
            generated_bytes = b"reviewed output\n"
            output = root / "Metrics.swift"

            def verify_focus(path: str) -> Path:
                if manifest.read_bytes() != original:
                    raise subject.GenerationError("Focus input hash changed")
                return focus

            def run(command: list[str], **kwargs):
                generated_dir = Path(command[-2])
                (generated_dir / "Metrics.swift").write_bytes(generated_bytes)
                manifest.write_bytes(b"mutated during generator execution\n")
                return subject.subprocess.CompletedProcess(command, 0, "")

            with patch.object(
                subject, "verify_focus", side_effect=verify_focus
            ), patch.object(
                subject, "GLEAN_PARSER_WHEEL_SHA256", subject.sha256(wheel_data)
            ), patch.object(
                subject, "GLEAN_OUTPUT_SHA256", subject.sha256(generated_bytes)
            ), patch.object(
                subject,
                "_prepare_isolated_glean_python",
                return_value=(Path(sys.executable), wheel),
            ), patch.object(
                subject, "_run", side_effect=run
            ):
                with self.assertRaisesRegex(
                    subject.GenerationError, "input hash changed"
                ):
                    subject.generate_glean(
                        str(focus),
                        sys.executable,
                        str(wheelhouse),
                        str(output),
                    )
            self.assertFalse(output.exists())

    def test_nimbus_refuses_unknown_channel_without_building(self) -> None:
        with self.assertRaisesRegex(
            subject.GenerationError, "unsupported Nimbus channel"
        ):
            subject.generate_nimbus(
                "focus",
                "rust-components",
                "appservices",
                "target",
                "nightly",
                "AppNimbus.swift",
            )

    @staticmethod
    def fake_nimbus_run(
        generated_bytes: bytes,
    ):
        def run(command: list[str], **kwargs):
            if command[0] == "cargo" and "build" in command:
                target = Path(command[command.index("--target-dir") + 1])
                executable = target / "release/nimbus-fml"
                executable.parent.mkdir(parents=True)
                executable.write_text("#!/bin/sh\nexit 0\n", encoding="utf-8")
                executable.chmod(0o700)
            elif "generate" in command:
                generated = Path(command[-1]) / "AppNimbus.swift"
                generated.write_bytes(generated_bytes)
            return subject.subprocess.CompletedProcess(
                args=command, returncode=0, stdout=""
            )

        return run

    def test_nimbus_accepts_only_reviewed_generated_bytes(self) -> None:
        with tempfile.TemporaryDirectory(prefix="focus-nimbus-oracle.") as temp:
            root = Path(temp).resolve()
            focus = root / "focus"
            package = root / "package"
            appservices = root / "appservices"
            for checkout in (focus, package, appservices):
                checkout.mkdir()
            target = root / "target"
            output = root / "AppNimbus.swift"
            generated = b"reviewed Nimbus output\n"
            with patch.object(
                subject, "verify_focus", return_value=focus
            ), patch.object(
                subject, "verify_rust_components", return_value=package
            ), patch.object(
                subject, "verify_appservices", return_value=appservices
            ), patch.object(
                subject, "_verify_nimbus_source_mapping"
            ), patch.object(
                subject, "_verify_rust_toolchain"
            ), patch.object(
                subject, "_run", side_effect=self.fake_nimbus_run(generated)
            ), patch.object(
                subject,
                "NIMBUS_OUTPUT_SHA256",
                {"developer": subject.sha256(generated)},
            ):
                subject.generate_nimbus(
                    "focus",
                    "package",
                    "appservices",
                    str(target),
                    "developer",
                    str(output),
                )
            self.assertEqual(output.read_bytes(), generated)

    def test_nimbus_uses_private_fetch_then_frozen_offline_build(self) -> None:
        with tempfile.TemporaryDirectory(prefix="focus-nimbus-cargo.") as temp:
            root = Path(temp).resolve()
            focus = root / "focus"
            package = root / "package"
            appservices = root / "appservices"
            for checkout in (focus, package, appservices):
                checkout.mkdir()
            target = root / "target"
            output = root / "AppNimbus.swift"
            generated = b"reviewed Nimbus output\n"
            calls: list[tuple[list[str], dict[str, object]]] = []

            def run(command: list[str], **kwargs):
                calls.append((list(command), dict(kwargs)))
                if command[0] == "cargo" and "build" in command:
                    executable = target / "release/nimbus-fml"
                    executable.parent.mkdir(parents=True)
                    executable.write_text("#!/bin/sh\nexit 0\n", encoding="utf-8")
                    executable.chmod(0o700)
                elif "generate" in command:
                    (Path(command[-1]) / "AppNimbus.swift").write_bytes(generated)
                return subject.subprocess.CompletedProcess(command, 0, "")

            with patch.dict(
                os.environ,
                {
                    "CARGO_HOME": "/ambient/cargo",
                    "CARGO_TARGET_DIR": "/ambient/target",
                    "RUSTFLAGS": "--cfg ambient",
                    "GIT_CONFIG_COUNT": "1",
                },
            ), patch.object(
                subject, "verify_focus", return_value=focus
            ) as verify_focus, patch.object(
                subject, "verify_rust_components", return_value=package
            ) as verify_package, patch.object(
                subject, "verify_appservices", return_value=appservices
            ) as verify_appservices, patch.object(
                subject, "_verify_nimbus_source_mapping"
            ) as verify_mapping, patch.object(
                subject, "_verify_rust_toolchain"
            ) as verify_toolchain, patch.object(
                subject, "_run", side_effect=run
            ), patch.object(
                subject,
                "NIMBUS_OUTPUT_SHA256",
                {"developer": subject.sha256(generated)},
            ):
                subject.generate_nimbus(
                    "focus",
                    "package",
                    "appservices",
                    str(target),
                    "developer",
                    str(output),
                )

            self.assertEqual(verify_focus.call_count, 3)
            self.assertEqual(verify_package.call_count, 3)
            self.assertEqual(verify_appservices.call_count, 3)
            self.assertEqual(verify_mapping.call_count, 3)
            verify_toolchain.assert_called_once()

            fetch = next(call for call in calls if "fetch" in call[0])
            build = next(call for call in calls if "build" in call[0])
            self.assertIn("--locked", fetch[0])
            self.assertNotIn("--frozen", fetch[0])
            self.assertIn("--frozen", build[0])
            self.assertNotIn("--locked", build[0])
            fetch_environment = fetch[1]["env"]
            build_environment = build[1]["env"]
            self.assertEqual(
                fetch_environment["CARGO_HOME"], str(target / "cargo-home")
            )
            self.assertNotIn("CARGO_NET_OFFLINE", fetch_environment)
            self.assertEqual(build_environment["CARGO_NET_OFFLINE"], "true")
            for name in (
                "CARGO_TARGET_DIR",
                "RUSTFLAGS",
                "GIT_CONFIG_COUNT",
            ):
                self.assertNotIn(name, fetch_environment)
                self.assertNotIn(name, build_environment)
            self.assertEqual((target / "cargo-home").stat().st_mode & 0o777, 0o700)
            self.assertEqual(output.read_bytes(), generated)

    def test_nimbus_refuses_focus_mutation_during_generator_execution(self) -> None:
        with tempfile.TemporaryDirectory(prefix="focus-nimbus-mutation.") as temp:
            root = Path(temp).resolve()
            focus = root / "focus"
            package = root / "package"
            appservices = root / "appservices"
            for checkout in (focus, package, appservices):
                checkout.mkdir()
            manifest = focus / "nimbus.fml.yaml"
            original = b"pinned manifest\n"
            manifest.write_bytes(original)
            target = root / "target"
            output = root / "AppNimbus.swift"
            generated = b"reviewed Nimbus output\n"

            def verify_focus(path: str) -> Path:
                if manifest.read_bytes() != original:
                    raise subject.GenerationError("Focus input hash changed")
                return focus

            def run(command: list[str], **kwargs):
                if command[0] == "cargo" and "build" in command:
                    executable = target / "release/nimbus-fml"
                    executable.parent.mkdir(parents=True)
                    executable.write_text("#!/bin/sh\nexit 0\n", encoding="utf-8")
                    executable.chmod(0o700)
                elif "generate" in command:
                    (Path(command[-1]) / "AppNimbus.swift").write_bytes(generated)
                    manifest.write_bytes(b"mutated during generator execution\n")
                return subject.subprocess.CompletedProcess(command, 0, "")

            with patch.object(
                subject, "verify_focus", side_effect=verify_focus
            ), patch.object(
                subject, "verify_rust_components", return_value=package
            ), patch.object(
                subject, "verify_appservices", return_value=appservices
            ), patch.object(
                subject, "_verify_nimbus_source_mapping"
            ), patch.object(
                subject, "_verify_rust_toolchain"
            ), patch.object(
                subject, "_run", side_effect=run
            ), patch.object(
                subject,
                "NIMBUS_OUTPUT_SHA256",
                {"developer": subject.sha256(generated)},
            ):
                with self.assertRaisesRegex(
                    subject.GenerationError, "input hash changed"
                ):
                    subject.generate_nimbus(
                        "focus",
                        "package",
                        "appservices",
                        str(target),
                        "developer",
                        str(output),
                    )
            self.assertFalse(output.exists())

    def test_nimbus_refuses_unreviewed_generated_bytes(self) -> None:
        with tempfile.TemporaryDirectory(prefix="focus-nimbus-refusal.") as temp:
            root = Path(temp).resolve()
            focus = root / "focus"
            package = root / "package"
            appservices = root / "appservices"
            for checkout in (focus, package, appservices):
                checkout.mkdir()
            output = root / "AppNimbus.swift"
            with patch.object(
                subject, "verify_focus", return_value=focus
            ), patch.object(
                subject, "verify_rust_components", return_value=package
            ), patch.object(
                subject, "verify_appservices", return_value=appservices
            ), patch.object(
                subject, "_verify_nimbus_source_mapping"
            ), patch.object(
                subject, "_verify_rust_toolchain"
            ), patch.object(
                subject,
                "_run",
                side_effect=self.fake_nimbus_run(b"unreviewed Nimbus output\n"),
            ):
                with self.assertRaisesRegex(
                    subject.GenerationError, "AppNimbus.swift.*hash changed"
                ):
                    subject.generate_nimbus(
                        "focus",
                        "package",
                        "appservices",
                        str(root / "target"),
                        "developer",
                        str(output),
                    )
            self.assertFalse(output.exists())

    def test_readiness_fails_while_intents_generation_is_unresolved(self) -> None:
        with patch.object(
            subject, "verify_focus", return_value=Path("/verified/focus")
        ):
            self.assertEqual(
                subject.main(["generated_sources.py", "readiness", "focus"]), 1
            )

    def test_output_is_never_overwritten(self) -> None:
        with tempfile.TemporaryDirectory(prefix="focus-output-refusal.") as temp:
            output = Path(temp) / "Metrics.swift"
            output.write_text("owned by caller\n", encoding="utf-8")
            with self.assertRaisesRegex(
                subject.GenerationError, "refusing to overwrite"
            ):
                subject._new_output_path(str(output))
            self.assertEqual(output.read_text(encoding="utf-8"), "owned by caller\n")

    def test_cargo_target_must_be_new_and_is_created_private(self) -> None:
        with tempfile.TemporaryDirectory(prefix="focus-cargo-target.") as temp:
            root = Path(temp).resolve()
            source = root / "source"
            source.mkdir()
            target = root / "target"
            created = subject._create_cargo_target_directory(str(target), (source,))
            self.assertEqual(created, target)
            self.assertEqual(created.stat().st_mode & 0o777, 0o700)
            with self.assertRaisesRegex(subject.GenerationError, "tool-owned"):
                subject._create_cargo_target_directory(str(target), (source,))
            inside = source / "target"
            with self.assertRaisesRegex(subject.GenerationError, "disjoint"):
                subject._create_cargo_target_directory(str(inside), (source,))
            self.assertFalse(inside.exists())

    def test_output_inside_pinned_checkout_is_refused_without_creating_parent(
        self,
    ) -> None:
        with tempfile.TemporaryDirectory(prefix="focus-output-scope.") as temp:
            checkout = Path(temp).resolve() / "focus"
            checkout.mkdir()
            generated_dir = checkout / "Blockzilla/Generated"
            output = generated_dir / "Metrics.swift"
            with self.assertRaisesRegex(subject.GenerationError, "outside"):
                subject._new_output_path(str(output), (checkout,))
            self.assertFalse(generated_dir.exists())


class GeneratorEndToEndTests(unittest.TestCase):
    def test_exact_glean_wheel_generates_reviewed_metrics(self) -> None:
        focus = require_checkout(self, FOCUS_REPOSITORY, "FOCUS_IOS_CHECKOUT")
        wheelhouse_value = os.environ.get("FOCUS_GLEAN_WHEELHOUSE")
        python_value = os.environ.get("FOCUS_GLEAN_PYTHON")
        if not wheelhouse_value or not python_value:
            self.skipTest("set FOCUS_GLEAN_WHEELHOUSE and FOCUS_GLEAN_PYTHON")
        wheelhouse = Path(wheelhouse_value).expanduser().resolve()
        # A virtualenv's Python is commonly a symlink; resolving it would drop
        # the virtualenv site-packages containing glean-parser's dependencies.
        python = Path(python_value).expanduser().absolute()
        with tempfile.TemporaryDirectory(prefix="focus-glean-e2e.") as temp:
            output = Path(temp) / "Metrics.swift"
            subject.generate_glean(
                str(focus), str(python), str(wheelhouse), str(output)
            )
            self.assertEqual(
                subject.sha256(output.read_bytes()), subject.GLEAN_OUTPUT_SHA256
            )

    def test_exact_nimbus_sources_generate_reviewed_manifest(self) -> None:
        focus = require_checkout(self, FOCUS_REPOSITORY, "FOCUS_IOS_CHECKOUT")
        package_value = os.environ.get("FOCUS_RUST_COMPONENTS_CHECKOUT")
        appservices_value = os.environ.get("FOCUS_APPSERVICES_CHECKOUT")
        if not package_value or not appservices_value:
            self.skipTest(
                "set FOCUS_RUST_COMPONENTS_CHECKOUT and " "FOCUS_APPSERVICES_CHECKOUT"
            )
        package = Path(package_value).expanduser().resolve()
        appservices = Path(appservices_value).expanduser().resolve()
        with tempfile.TemporaryDirectory(prefix="focus-nimbus-e2e.") as temp:
            root = Path(temp)
            target = root / "cargo-target"
            output = root / "AppNimbus.swift"
            subject.generate_nimbus(
                str(focus),
                str(package),
                str(appservices),
                str(target),
                "developer",
                str(output),
            )
            self.assertEqual(
                subject.sha256(output.read_bytes()),
                subject.NIMBUS_OUTPUT_SHA256["developer"],
            )


if __name__ == "__main__":
    unittest.main()
