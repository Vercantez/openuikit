#!/usr/bin/env python3

from __future__ import annotations

import json
import os
from pathlib import Path
import plistlib
import tempfile
import unittest

import intentdefinition_compiler as compiler


FOCUS_INPUT = Path(
    "scratch/ladder-corpus/focus-ios/focus-ios/Blockzilla/Base.lproj/"
    "Intents.intentdefinition"
)
FOCUS_SHA256 = "d73b6f7eb39cdf2c80af4e84fd737e8c2196ded95c4ff886d5e74e2e8ff413de"


def model() -> dict:
    return {
        "INIntentDefinitionModelVersion": "1.2",
        "INIntentDefinitionToolsVersion": "15.4",
        "INIntentDefinitionToolsBuildVersion": "15F31d",
        "INIntentDefinitionNamespace": "test",
        "INEnums": [
            {
                "INEnumName": "Choice",
                "INEnumClassName": "PortableChoice",
                "INEnumType": "Regular",
                "INEnumValues": [
                    {"INEnumValueName": "unknown"},
                    {"INEnumValueName": "public", "INEnumValueIndex": 7},
                ],
            }
        ],
        "INTypes": [
            {
                "INTypeName": "Thing",
                "INTypeClassName": "PortableThing",
                "INTypeProperties": [
                    {
                        "INTypePropertyName": "identifier",
                        "INTypePropertyType": "String",
                        "INTypePropertyDefault": True,
                    },
                    {
                        "INTypePropertyName": "note",
                        "INTypePropertyType": "String",
                    },
                ],
            }
        ],
        "INIntents": [
            {
                "INIntentName": "DoThing",
                "INIntentType": "Custom",
                "INIntentParameters": [
                    {
                        "INIntentParameterName": "things",
                        "INIntentParameterType": "Object",
                        "INIntentParameterObjectType": "Thing",
                        "INIntentParameterSupportsMultipleValues": True,
                        "INIntentParameterSupportsDynamicEnumeration": True,
                        "INIntentParameterSupportsSearch": True,
                        "INIntentParameterSupportsResolution": True,
                    },
                    {
                        "INIntentParameterName": "choice",
                        "INIntentParameterType": "Integer",
                        "INIntentParameterEnumType": "Choice",
                    },
                    {
                        "INIntentParameterName": "count",
                        "INIntentParameterType": "Integer",
                    },
                ],
                "INIntentResponse": {
                    "INIntentResponseCodes": [
                        {"INIntentResponseCodeName": "success", "INIntentResponseCodeSuccess": True},
                        {
                            "INIntentResponseCodeName": "failureWithReason",
                            "INIntentResponseCodeFormatString": "${reason}",
                        },
                    ],
                    "INIntentResponseParameters": [
                        {
                            "INIntentResponseParameterName": "reason",
                            "INIntentResponseParameterType": "String",
                        }
                    ],
                },
            },
            {
                "INIntentName": "PlayMedia",
                "INIntentClassName": "INPlayMediaIntent",
                "INIntentType": "System",
                "INIntentResponse": {"INIntentResponseCodes": []},
            },
        ],
    }


class IntentDefinitionCompilerTests(unittest.TestCase):
    def setUp(self) -> None:
        self.temporary = tempfile.TemporaryDirectory()
        self.root = Path(self.temporary.name)
        self.input = self.root / "Probe.intentdefinition"
        self.input.write_bytes(plistlib.dumps(model(), fmt=plistlib.FMT_XML, sort_keys=True))

    def tearDown(self) -> None:
        self.temporary.cleanup()

    def generate(self, name: str = "generated") -> Path:
        output = self.root / name
        compiler.generate(self.input, output, "Portable.App")
        return output

    def test_generates_typed_custom_sources_and_attestation(self) -> None:
        output = self.generate()
        manifest = compiler.verify(output)
        self.assertEqual(manifest["counts"]["swift_sources"], 3)
        self.assertEqual(manifest["counts"]["skipped_system_intents"], 1)
        self.assertEqual(
            manifest["skipped_system_intents"],
            [
                {
                    "model_name": "PlayMedia",
                    "class_name": "INPlayMediaIntent",
                    "reason": "owned-by-Intents-runtime",
                }
            ],
        )
        intent = (output / "DoThingIntent.swift").read_text()
        self.assertIn("public var things: [PortableThing]? = nil", intent)
        self.assertIn("public var choice: PortableChoice = .unknown", intent)
        self.assertIn("public var count: NSNumber? = nil", intent)
        self.assertIn(
            "provideThingsOptionsCollection(for intent: DoThingIntent, searchTerm: String?",
            intent,
        )
        self.assertIn("case failureWithReason = 100", intent)
        self.assertIn("static func failureWithReason(reason: String)", intent)
        object_source = (output / "PortableThing.swift").read_text()
        self.assertNotIn("var identifier", object_source)
        self.assertIn("public var note: String? = nil", object_source)

    def test_generation_is_byte_deterministic(self) -> None:
        first = self.generate("first")
        second = self.generate("second")
        first_files = {path.name: path.read_bytes() for path in first.iterdir()}
        second_files = {path.name: path.read_bytes() for path in second.iterdir()}
        self.assertEqual(first_files, second_files)

    def test_verify_rejects_tampered_source(self) -> None:
        output = self.generate()
        path = output / "DoThingIntent.swift"
        path.write_bytes(path.read_bytes() + b"// tampered\n")
        with self.assertRaisesRegex(compiler.Refusal, "generated output changed"):
            compiler.verify(output)

    def test_verify_rejects_unmanifested_artifact(self) -> None:
        output = self.generate()
        (output / "stale.o").write_bytes(b"stale")
        with self.assertRaisesRegex(compiler.Refusal, "differs from manifest"):
            compiler.verify(output)

    def test_refuses_to_overwrite_output(self) -> None:
        self.generate()
        with self.assertRaisesRegex(compiler.Refusal, "overwrite"):
            compiler.generate(self.input, self.root / "generated", "Portable.App")

    def test_refuses_symlink_input(self) -> None:
        link = self.root / "linked.intentdefinition"
        link.symlink_to(self.input)
        with self.assertRaisesRegex(compiler.Refusal, "symlink"):
            compiler.generate(link, self.root / "linked-output", "Portable.App")

    def test_refuses_unsupported_model_version_without_output(self) -> None:
        value = model()
        value["INIntentDefinitionModelVersion"] = "99"
        self.input.write_bytes(plistlib.dumps(value))
        output = self.root / "unsupported"
        with self.assertRaisesRegex(compiler.Refusal, "model version"):
            compiler.generate(self.input, output, "Portable.App")
        self.assertFalse(output.exists())

    def test_refuses_duplicate_swift_names_without_output(self) -> None:
        value = model()
        value["INTypes"].append(
            {
                "INTypeName": "OtherThing",
                "INTypeClassName": "PortableThing",
                "INTypeProperties": [],
            }
        )
        self.input.write_bytes(plistlib.dumps(value))
        output = self.root / "duplicate"
        with self.assertRaisesRegex(compiler.Refusal, "same output filename"):
            compiler.generate(self.input, output, "Portable.App")
        self.assertFalse(output.exists())

    def test_cli_refusal_is_exit_two(self) -> None:
        result = compiler.main(
            [
                "generate",
                "--input",
                os.fspath(self.input),
                "--output-root",
                os.fspath(self.root / "bad-module"),
                "--module-name",
                "Bad-Module",
            ]
        )
        self.assertEqual(result, 2)

    @unittest.skipUnless(FOCUS_INPUT.is_file(), "pinned Focus corpus is not staged")
    def test_pinned_focus_schema_generates_erase_contract(self) -> None:
        payload = FOCUS_INPUT.read_bytes()
        self.assertEqual(compiler.sha256_bytes(payload), FOCUS_SHA256)
        output = self.root / "focus"
        manifest = compiler.generate(FOCUS_INPUT, output, "Blockzilla")
        self.assertEqual(manifest["counts"]["swift_sources"], 1)
        self.assertEqual([entry["path"] for entry in manifest["outputs"]], [
            "EraseIntent.swift",
            "declaration-inventory.json",
        ])
        source = (output / "EraseIntent.swift").read_text()
        for declaration in (
            "class EraseIntent: INIntent",
            "protocol EraseIntentHandling",
            "enum EraseIntentResponseCode",
            "class EraseIntentResponse: INIntentResponse",
        ):
            self.assertIn(declaration, source)


if __name__ == "__main__":
    unittest.main()
