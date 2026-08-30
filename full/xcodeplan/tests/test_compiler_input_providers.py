from __future__ import annotations

import copy
import hashlib
import json
import os
from pathlib import Path
import plistlib
import sys
import tempfile
import unittest


HERE = Path(__file__).resolve().parent
TOOL_DIR = HERE.parent
sys.path.insert(0, os.fspath(TOOL_DIR))

import compiler_input_providers  # noqa: E402


def sha256(path: Path) -> str:
    return hashlib.sha256(path.read_bytes()).hexdigest()


class CompilerInputProviderTests(unittest.TestCase):
    def setUp(self) -> None:
        self.temporary = tempfile.TemporaryDirectory(
            prefix="compiler-input-provider-test."
        )
        self.base = Path(self.temporary.name)
        self.source_root = self.base / "source"
        self.source_root.mkdir()
        definition = self.source_root / "App/Base.lproj/Intents.intentdefinition"
        definition.parent.mkdir(parents=True)
        definition.write_bytes(
            plistlib.dumps(
                {
                    "INEnums": [],
                    "INIntentDefinitionModelVersion": "1.2",
                    "INIntentDefinitionToolsBuildVersion": "17B55",
                    "INIntentDefinitionToolsVersion": "26.1",
                    "INIntents": [
                        {
                            "INIntentDescription": "Erase",
                            "INIntentName": "Erase",
                            "INIntentParameters": [],
                            "INIntentResponse": {
                                "INIntentResponseCodes": [],
                                "INIntentResponseParameters": [],
                            },
                            "INIntentTitle": "Erase",
                            "INIntentType": "Custom",
                        }
                    ],
                    "INTypes": [],
                },
                sort_keys=True,
            )
        )
        strings = self.source_root / "App/fr.lproj/Intents.strings"
        strings.parent.mkdir(parents=True)
        strings.write_text('"Erase" = "Effacer";\n', encoding="utf-8")
        self.plan = {
            "classification": "portable-application-build-plan",
            "compiler_inputs": [
                {
                    "input_files": [
                        {
                            "path": "App/Base.lproj/Intents.intentdefinition",
                            "sha256": sha256(definition),
                            "size": definition.stat().st_size,
                        },
                        {
                            "path": "App/fr.lproj/Intents.strings",
                            "sha256": sha256(strings),
                            "size": strings.stat().st_size,
                        },
                    ],
                    "logical_path": "App/Intents.intentdefinition",
                    "primary_path": "App/Base.lproj/Intents.intentdefinition",
                    "provider": "open-intentdefinition",
                }
            ],
            "format_version": 2,
            "module": "Probe",
        }
        self.plan_path = self.base / "application-build-plan.json"
        self.write_plan(self.plan)

    def tearDown(self) -> None:
        self.temporary.cleanup()

    def write_plan(self, value: dict) -> None:
        self.plan_path.write_text(
            json.dumps(value, sort_keys=True, separators=(",", ":")) + "\n",
            encoding="utf-8",
        )

    def test_generates_attested_swift_without_touching_sources(self) -> None:
        before = {
            path.relative_to(self.source_root).as_posix(): sha256(path)
            for path in self.source_root.rglob("*")
            if path.is_file()
        }
        output = self.base / "derived-sources"
        document = compiler_input_providers.generate(
            self.plan_path, self.source_root, output
        )
        verified, sources = compiler_input_providers.verify(
            self.plan_path, self.source_root, output
        )
        self.assertEqual(document, verified)
        self.assertEqual(document["provider_count"], 1)
        self.assertEqual(document["source_count"], 1)
        self.assertEqual([path.name for path in sources], ["EraseIntent.swift"])
        self.assertIn("public class EraseIntent", sources[0].read_text())
        self.assertEqual(
            (output / "derived-sources.nul").read_bytes(),
            document["sources"][0]["path"].encode("utf-8") + b"\0",
        )
        after = {
            path.relative_to(self.source_root).as_posix(): sha256(path)
            for path in self.source_root.rglob("*")
            if path.is_file()
        }
        self.assertEqual(before, after)

    def test_generation_is_byte_deterministic_and_empty_input_is_explicit(self) -> None:
        first = self.base / "first"
        second = self.base / "second"
        compiler_input_providers.generate(self.plan_path, self.source_root, first)
        compiler_input_providers.generate(self.plan_path, self.source_root, second)
        first_files = {
            path.relative_to(first).as_posix(): path.read_bytes()
            for path in first.rglob("*")
            if path.is_file()
        }
        second_files = {
            path.relative_to(second).as_posix(): path.read_bytes()
            for path in second.rglob("*")
            if path.is_file()
        }
        self.assertEqual(first_files, second_files)

        empty_plan = copy.deepcopy(self.plan)
        empty_plan["compiler_inputs"] = []
        self.write_plan(empty_plan)
        empty = self.base / "empty"
        document = compiler_input_providers.generate(
            self.plan_path, self.source_root, empty
        )
        self.assertEqual(document["sources"], [])
        self.assertEqual((empty / "derived-sources.nul").read_bytes(), b"")
        compiler_input_providers.verify(self.plan_path, self.source_root, empty)

    def test_refuses_changed_input_output_tool_contract_and_extra_artifact(self) -> None:
        output = self.base / "derived"
        compiler_input_providers.generate(self.plan_path, self.source_root, output)
        source = next((output / "providers").rglob("*.swift"))
        source.write_text(source.read_text() + "// changed\n", encoding="utf-8")
        with self.assertRaisesRegex(
            compiler_input_providers.ProviderError,
            "provider verification failed",
        ):
            compiler_input_providers.verify(self.plan_path, self.source_root, output)

        output2 = self.base / "derived2"
        compiler_input_providers.generate(self.plan_path, self.source_root, output2)
        (output2 / "stale.swift").write_text("stale\n", encoding="utf-8")
        with self.assertRaisesRegex(
            compiler_input_providers.ProviderError, "unexpected artifact"
        ):
            compiler_input_providers.verify(self.plan_path, self.source_root, output2)

        definition = self.source_root / "App/Base.lproj/Intents.intentdefinition"
        definition.write_bytes(definition.read_bytes() + b"\n")
        with self.assertRaisesRegex(
            compiler_input_providers.ProviderError, "frozen compiler input changed"
        ):
            compiler_input_providers.verify(self.plan_path, self.source_root, output2)

    def test_refuses_symlinks_duplicate_inputs_and_unsupported_provider(self) -> None:
        changed = copy.deepcopy(self.plan)
        changed["compiler_inputs"][0]["provider"] = "intentbuilderc"
        self.write_plan(changed)
        with self.assertRaisesRegex(
            compiler_input_providers.ProviderError, "unsupported compiler-input provider"
        ):
            compiler_input_providers.generate(
                self.plan_path, self.source_root, self.base / "unsupported"
            )

        self.write_plan(self.plan)
        primary = self.source_root / "App/Base.lproj/Intents.intentdefinition"
        real = self.source_root / "App/Base.lproj/real.intentdefinition"
        primary.rename(real)
        primary.symlink_to(real.name)
        with self.assertRaisesRegex(
            compiler_input_providers.ProviderError, "symlink"
        ):
            compiler_input_providers.generate(
                self.plan_path, self.source_root, self.base / "symlink"
            )

    def test_refuses_duplicate_json_and_mismatched_variant_topology(self) -> None:
        self.plan_path.write_text(
            '{"classification":"portable-application-build-plan",'
            '"classification":"portable-application-build-plan",'
            '"compiler_inputs":[],"format_version":2,"module":"Probe"}\n',
            encoding="utf-8",
        )
        with self.assertRaisesRegex(
            compiler_input_providers.ProviderError, "duplicate JSON key"
        ):
            compiler_input_providers.generate(
                self.plan_path, self.source_root, self.base / "duplicate-json"
            )

        changed = copy.deepcopy(self.plan)
        changed["compiler_inputs"][0]["input_files"][1]["path"] = (
            "App/fr.lproj/Wrong.strings"
        )
        wrong = self.source_root / "App/fr.lproj/Wrong.strings"
        wrong.write_text('"Erase" = "Effacer";\n', encoding="utf-8")
        changed["compiler_inputs"][0]["input_files"][1]["sha256"] = sha256(wrong)
        changed["compiler_inputs"][0]["input_files"][1]["size"] = wrong.stat().st_size
        self.write_plan(changed)
        with self.assertRaisesRegex(
            compiler_input_providers.ProviderError,
            "mismatched localization variant",
        ):
            compiler_input_providers.generate(
                self.plan_path, self.source_root, self.base / "wrong-variant"
            )


if __name__ == "__main__":
    unittest.main()
