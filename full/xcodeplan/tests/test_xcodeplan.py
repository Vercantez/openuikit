from __future__ import annotations

import copy
import hashlib
import os
import shutil
import stat
import subprocess
import sys
import tempfile
import unittest
from unittest import mock
from pathlib import Path


HERE = Path(__file__).resolve().parent
TOOL_DIR = HERE.parent
sys.path.insert(0, os.fspath(TOOL_DIR))

import xcodeplan  # noqa: E402


FIXTURE = HERE / "fixtures" / "mini"
PROJECT = FIXTURE / "Blockzilla.xcodeproj" / "project.pbxproj"
SCHEME = FIXTURE / "Blockzilla.xcodeproj" / "xcshareddata" / "xcschemes" / "Focus.xcscheme"

MINI_SPEC = xcodeplan.GraphSpec(
    scheme_name="Focus",
    run_configuration="FocusDebug",
    target_id="AAAAAAAAAAAAAAAAAAAAAAAA",
    target_name="Blockzilla",
    product_type="com.apple.product-type.application",
    phases=xcodeplan.FOCUS_GRAPH.phases,
    target_dependencies=("Extension",),
    package_products=("LocalKit",),
    source_count=3,
    swift_source_count=2,
    non_swift_sources=("Intents.intentdefinition",),
    framework_count=1,
    resource_count=1,
    embedded_extension_count=1,
    allowed_shell_variables=xcodeplan.FOCUS_GRAPH.allowed_shell_variables,
)


class OpenStepParserTests(unittest.TestCase):
    def test_comments_escapes_arrays_and_nested_dictionaries(self) -> None:
        value = xcodeplan.parse_openstep(
            r'''
            // header
            {
                scalar = bare-token;
                quoted = "line\n\"two\"";
                array = (one, two, /* trailing comment */ );
                nested = { key = "https://example.invalid/path"; };
            }
            ''',
            "unit-fixture",
        )
        self.assertEqual(value["scalar"], "bare-token")
        self.assertEqual(value["quoted"], 'line\n"two"')
        self.assertEqual(value["array"], ["one", "two"])
        self.assertEqual(value["nested"]["key"], "https://example.invalid/path")

    def test_duplicate_dictionary_key_is_rejected(self) -> None:
        with self.assertRaisesRegex(xcodeplan.PlanError, "duplicate dictionary key"):
            xcodeplan.parse_openstep("{ key = one; key = two; }")

    def test_unterminated_comment_is_rejected(self) -> None:
        with self.assertRaisesRegex(xcodeplan.PlanError, "unterminated block comment"):
            xcodeplan.parse_openstep("{ /* never closed")


class FixturePlanTests(unittest.TestCase):
    def setUp(self) -> None:
        self.parsed = xcodeplan.parse_openstep(PROJECT.read_text(encoding="utf-8"), os.fspath(PROJECT))
        self.scheme = xcodeplan.parse_scheme(SCHEME, MINI_SPEC)

    def plan(self, parsed=None):
        return xcodeplan.ProjectPlanner(parsed or self.parsed, FIXTURE, MINI_SPEC).build(self.scheme)

    @staticmethod
    def fixture_git_tree(root: Path = FIXTURE) -> dict[str, xcodeplan.GitTreeEntry]:
        result = {}
        for path in root.rglob("*"):
            if not path.is_file():
                continue
            mode = "100755" if path.stat().st_mode & stat.S_IXUSR else "100644"
            result[path.relative_to(root).as_posix()] = xcodeplan.GitTreeEntry(
                mode=mode,
                kind="blob",
                object_id=xcodeplan.git_blob_object_id(path.read_bytes(), "sha1"),
            )
        return result

    def test_fixture_extracts_ordered_graph_and_generated_input(self) -> None:
        plan = self.plan()
        self.assertEqual(
            [phase["name"] for phase in plan["build_phases"]],
            [phase.name for phase in MINI_SPEC.phases],
        )
        self.assertEqual(
            plan["summary"],
            {
                "phase_count": 8,
                "shell_phase_count": 4,
                "source_count": 3,
                "swift_source_count": 2,
                "non_swift_source_count": 1,
                "framework_count": 1,
                "resource_count": 1,
                "embedded_extension_count": 1,
                "target_dependency_count": 1,
                "package_product_count": 1,
            },
        )
        sources = plan["build_phases"][4]["files"]
        self.assertEqual([entry["path"] for entry in sources], [
            "App/Source.swift",
            "App/Generated.swift",
            "App/Intents.intentdefinition",
        ])
        self.assertFalse(sources[0]["generated"])
        self.assertTrue(sources[1]["generated"])
        self.assertEqual(sources[2]["variant_paths"], [
            "App/Base.lproj/Intents.intentdefinition"
        ])
        self.assertEqual([item["name"] for item in plan["target_dependencies"]], ["Extension"])
        self.assertEqual([item["name"] for item in plan["package_products"]], ["LocalKit"])

    def test_canonical_json_is_byte_deterministic(self) -> None:
        first = xcodeplan.canonical_json(self.plan())
        second = xcodeplan.canonical_json(self.plan(copy.deepcopy(self.parsed)))
        self.assertEqual(first, second)
        self.assertTrue(first.endswith(b"\n"))

    def test_unknown_phase_type_is_rejected(self) -> None:
        parsed = copy.deepcopy(self.parsed)
        parsed["objects"]["300000000000000000000004"]["isa"] = "PBXMagicBuildPhase"
        with self.assertRaisesRegex(xcodeplan.PlanError, "unknown build phase type"):
            self.plan(parsed)

    def test_known_phase_in_wrong_slot_is_rejected(self) -> None:
        parsed = copy.deepcopy(self.parsed)
        target = parsed["objects"][MINI_SPEC.target_id]
        target["buildPhases"][0], target["buildPhases"][1] = (
            target["buildPhases"][1],
            target["buildPhases"][0],
        )
        with self.assertRaisesRegex(xcodeplan.PlanError, "phase 0 drift"):
            self.plan(parsed)

    def test_dangling_build_file_reference_is_rejected(self) -> None:
        parsed = copy.deepcopy(self.parsed)
        parsed["objects"]["200000000000000000000001"]["fileRef"] = "DEADDEADDEADDEADDEADDEAD"
        with self.assertRaisesRegex(xcodeplan.PlanError, "unresolved PBX object reference"):
            self.plan(parsed)

    def test_unresolved_path_variable_is_rejected(self) -> None:
        parsed = copy.deepcopy(self.parsed)
        parsed["objects"]["300000000000000000000003"]["inputPaths"] = ["$(MYSTERY)/input"]
        with self.assertRaisesRegex(xcodeplan.PlanError, "unresolved build variable 'MYSTERY'"):
            self.plan(parsed)

    def test_unresolved_group_path_variable_is_rejected(self) -> None:
        parsed = copy.deepcopy(self.parsed)
        parsed["objects"]["000000000000000000000003"]["path"] = "$(MYSTERY)/App"
        with self.assertRaisesRegex(xcodeplan.PlanError, "unresolved build variable 'MYSTERY'"):
            self.plan(parsed)

    def test_absolute_project_path_is_rejected(self) -> None:
        parsed = copy.deepcopy(self.parsed)
        parsed["objects"]["100000000000000000000001"]["path"] = "/tmp/Source.swift"
        with self.assertRaisesRegex(xcodeplan.PlanError, "uses an absolute path"):
            self.plan(parsed)

    def test_unresolved_shell_variable_is_rejected(self) -> None:
        parsed = copy.deepcopy(self.parsed)
        parsed["objects"]["300000000000000000000003"]["shellScript"] = "echo $SECRET\n"
        with self.assertRaisesRegex(xcodeplan.PlanError, "unresolved variable.*SECRET"):
            self.plan(parsed)

    def test_shell_command_substitution_is_rejected(self) -> None:
        parsed = copy.deepcopy(self.parsed)
        parsed["objects"]["300000000000000000000003"]["shellScript"] = "echo $(uname)\n"
        with self.assertRaisesRegex(xcodeplan.PlanError, "unsupported variable/command syntax"):
            self.plan(parsed)

    def test_missing_shell_input_is_rejected(self) -> None:
        parsed = copy.deepcopy(self.parsed)
        parsed["objects"]["300000000000000000000003"]["inputPaths"] = ["missing.yaml"]
        with self.assertRaisesRegex(xcodeplan.PlanError, "does not exist: missing.yaml"):
            self.plan(parsed)

    def test_existing_untracked_graph_inputs_are_rejected(self) -> None:
        tree = self.fixture_git_tree()
        for relative_path in ("App/Source.swift", "App/Resource.txt", "App/Input.yaml"):
            with self.subTest(relative_path=relative_path):
                reduced_tree = dict(tree)
                del reduced_tree[relative_path]
                planner = xcodeplan.ProjectPlanner(
                    self.parsed,
                    FIXTURE,
                    MINI_SPEC,
                    git_tree=reduced_tree,
                )
                with self.assertRaisesRegex(xcodeplan.PlanError, "untracked or ignored path"):
                    planner.build(self.scheme)

    def test_untracked_descendant_of_consumed_directory_is_rejected(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            repo = Path(directory) / "mini"
            shutil.copytree(FIXTURE, repo)
            tree = self.fixture_git_tree(repo)
            (repo / "App" / "Injected.txt").write_text("not in pinned Git tree\n", encoding="utf-8")
            planner = xcodeplan.ProjectPlanner(
                self.parsed,
                repo,
                MINI_SPEC,
                git_tree=tree,
            )
            with self.assertRaisesRegex(xcodeplan.PlanError, "untracked or ignored path"):
                planner._require_pinned_input("App", "directory resource")

    def test_worktree_blob_drift_is_rejected_even_when_status_could_hide_it(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            repo = Path(directory) / "mini"
            shutil.copytree(FIXTURE, repo)
            tree = self.fixture_git_tree(repo)
            (repo / "App" / "Source.swift").write_text("let changed = true\n", encoding="utf-8")
            planner = xcodeplan.ProjectPlanner(
                self.parsed,
                repo,
                MINI_SPEC,
                git_tree=tree,
            )
            with self.assertRaisesRegex(xcodeplan.PlanError, "content drift from pinned Git blob"):
                planner.build(self.scheme)

    def test_duplicate_shell_output_is_rejected(self) -> None:
        parsed = copy.deepcopy(self.parsed)
        parsed["objects"]["300000000000000000000004"]["outputPaths"] = [
            "$(SRCROOT)/App/Generated.swift"
        ]
        with self.assertRaisesRegex(xcodeplan.PlanError, "same output path"):
            self.plan(parsed)

    def test_copy_phase_attributes_are_fail_closed(self) -> None:
        parsed = copy.deepcopy(self.parsed)
        settings = parsed["objects"]["200000000000000000000006"]["settings"]
        settings["ATTRIBUTES"] = ["CodeSignOnCopy"]
        with self.assertRaisesRegex(xcodeplan.PlanError, "unsupported copy attributes"):
            self.plan(parsed)

    def test_scheme_configuration_drift_is_rejected(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            path = Path(directory) / "Focus.xcscheme"
            path.write_text(
                SCHEME.read_text(encoding="utf-8").replace("FocusDebug", "Release"),
                encoding="utf-8",
            )
            with self.assertRaisesRegex(xcodeplan.PlanError, "run configuration drift"):
                xcodeplan.parse_scheme(path, MINI_SPEC)


class PinTests(unittest.TestCase):
    def git(self, repo: Path, *args: str) -> str:
        return subprocess.run(
            ["git", "-C", os.fspath(repo), *args],
            check=True,
            text=True,
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
        ).stdout.strip()

    def test_commit_hash_and_tracked_worktree_are_attested(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            repo = Path(directory)
            self.git(repo, "init", "-q")
            self.git(repo, "config", "user.email", "fixture@example.invalid")
            self.git(repo, "config", "user.name", "Fixture")
            subject = repo / "input.txt"
            subject.write_text("pinned\n", encoding="utf-8")
            self.git(repo, "add", "input.txt")
            self.git(repo, "commit", "-qm", "fixture")
            commit = self.git(repo, "rev-parse", "HEAD")
            digest = hashlib.sha256(subject.read_bytes()).hexdigest()
            pins = (xcodeplan.InputPin("input", "input.txt", digest),)

            verified = xcodeplan.verify_pins(repo, commit, pins)
            self.assertEqual(verified["git_commit"], commit)

            with self.assertRaisesRegex(xcodeplan.PlanError, "commit drift"):
                xcodeplan.verify_pins(repo, "0" * 40, pins)
            with self.assertRaisesRegex(xcodeplan.PlanError, "input hash drift"):
                xcodeplan.verify_pins(
                    repo,
                    commit,
                    (xcodeplan.InputPin("input", "input.txt", "0" * 64),),
                )
            subject.write_text("changed\n", encoding="utf-8")
            with self.assertRaisesRegex(xcodeplan.PlanError, "tracked worktree drift"):
                xcodeplan.verify_pins(repo, commit, pins)

    def test_ambient_git_directory_cannot_redirect_attestation(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            subject = root / "subject"
            decoy = root / "decoy"
            for repo in (subject, decoy):
                repo.mkdir()
                self.git(repo, "init", "-q")
                self.git(repo, "config", "user.email", "fixture@example.invalid")
                self.git(repo, "config", "user.name", "Fixture")
                (repo / "input.txt").write_text("pinned\n", encoding="utf-8")
                (repo / "source.swift").write_text("let value = 1\n", encoding="utf-8")
                self.git(repo, "add", ".")
                self.git(repo, "commit", "-qm", "fixture")
            commit = self.git(subject, "rev-parse", "HEAD")
            digest = hashlib.sha256((subject / "input.txt").read_bytes()).hexdigest()
            (subject / "source.swift").write_text("let value = 2\n", encoding="utf-8")
            poisoned_environment = {
                "GIT_DIR": os.fspath(decoy / ".git"),
                "GIT_WORK_TREE": os.fspath(decoy),
            }
            with mock.patch.dict(os.environ, poisoned_environment):
                with self.assertRaisesRegex(xcodeplan.PlanError, "tracked worktree drift"):
                    xcodeplan.verify_pins(
                        subject,
                        commit,
                        (xcodeplan.InputPin("input", "input.txt", digest),),
                    )


class PinnedFocusIntegrationTests(unittest.TestCase):
    @unittest.skipUnless(os.environ.get("FOCUS_IOS_CHECKOUT"), "FOCUS_IOS_CHECKOUT is not set")
    def test_live_checkout_matches_canonical_plan(self) -> None:
        checkout = Path(os.environ["FOCUS_IOS_CHECKOUT"])
        payload = xcodeplan.checked_focus_plan(checkout, TOOL_DIR / "focus-plan.json")
        plan = xcodeplan.build_focus_plan(checkout)
        self.assertEqual(payload, xcodeplan.canonical_json(plan))
        self.assertEqual(plan["summary"]["source_count"], 132)


if __name__ == "__main__":
    unittest.main()
