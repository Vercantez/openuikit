#!/usr/bin/env python3
"""Host-gate framework.json key check for module-path seeds."""

from __future__ import annotations

import json
from pathlib import Path
import sys
import unittest

import generate_seed_v2 as base

REPO_ROOT = Path(__file__).resolve().parents[2]
VALIDATE_SEED_DIR = REPO_ROOT / "full" / "framework-fanout"
if str(VALIDATE_SEED_DIR) not in sys.path:
    sys.path.insert(0, str(VALIDATE_SEED_DIR))
import validate_seed  # noqa: E402


def eval_generated_key_check(framework: object) -> str | None:
    """Execute the exact Python fragment inlined into test_host.sh."""

    namespace: dict[str, object] = {"framework": framework}

    def fail(message: str) -> None:
        raise SystemExit(message)

    namespace["fail"] = fail
    try:
        exec(base.host_gate_framework_json_key_check_python(), namespace)
    except SystemExit as error:
        return str(error)
    return None


def vanilla_framework_json() -> dict[str, object]:
    metadata = {key: key for key in base.REQUIRED_FRAMEWORK_JSON_KEYS}
    metadata["schema"] = 2
    return metadata


def module_path_framework_json(*, roadmap: bool = False) -> dict[str, object]:
    metadata = vanilla_framework_json()
    metadata["moduleLocation"] = {
        "kind": "clang-module",
        "sdkRelativePath": "usr/include/CommonCrypto/module.modulemap",
        "reason": "public Darwin clang module directory map is present",
    }
    if roadmap:
        metadata["roadmap"] = base.ROADMAP_OPERATOR_OVERRIDE
    return metadata


class HostGateFrameworkJsonKeysTest(unittest.TestCase):
    def test_optional_keys_match_deliverable_validator(self) -> None:
        self.assertEqual(
            base.OPTIONAL_FRAMEWORK_JSON_KEYS,
            validate_seed.OPTIONAL_FRAMEWORK_METADATA_KEYS,
        )

    def test_acceptance_script_embeds_generated_key_check(self) -> None:
        script = base.acceptance_script()
        fragment = base.host_gate_framework_json_key_check_python()
        self.assertIn(fragment, script)
        self.assertNotIn("HOST_GATE_FRAMEWORK_JSON_KEY_CHECK", script)
        self.assertNotIn(
            'if set(framework) != required_keys or framework["schema"] != 2:',
            script,
        )

    def test_vanilla_framework_json_still_passes_host_gate_key_check(self) -> None:
        framework = vanilla_framework_json()
        self.assertIsNone(base.host_gate_framework_json_keys_error(framework))
        self.assertIsNone(eval_generated_key_check(framework))

    def test_module_path_seed_passes_host_gate_framework_json_key_check(self) -> None:
        framework = module_path_framework_json()
        self.assertEqual(
            set(framework) - base.REQUIRED_FRAMEWORK_JSON_KEYS,
            {"moduleLocation"},
        )
        self.assertIsNone(base.host_gate_framework_json_keys_error(framework))
        self.assertIsNone(eval_generated_key_check(framework))

        with_roadmap = module_path_framework_json(roadmap=True)
        self.assertEqual(
            set(with_roadmap) - base.REQUIRED_FRAMEWORK_JSON_KEYS,
            {"moduleLocation", "roadmap"},
        )
        self.assertIsNone(base.host_gate_framework_json_keys_error(with_roadmap))
        self.assertIsNone(eval_generated_key_check(with_roadmap))

    def test_published_module_path_seeds_pass_host_gate_key_check(self) -> None:
        for slug in ("commoncrypto", "compression", "swiftdata"):
            path = (
                REPO_ROOT / "full" / slug / "reference" / "framework.json"
            )
            framework = json.loads(path.read_text(encoding="utf-8"))
            with self.subTest(slug=slug):
                extras = set(framework) - base.REQUIRED_FRAMEWORK_JSON_KEYS
                self.assertTrue(extras <= base.OPTIONAL_FRAMEWORK_JSON_KEYS, extras)
                self.assertIn("moduleLocation", framework)
                self.assertIsNone(
                    base.host_gate_framework_json_keys_error(framework),
                    extras,
                )
                self.assertIsNone(eval_generated_key_check(framework), extras)

    def test_unexpected_framework_json_key_fails_host_gate(self) -> None:
        framework = module_path_framework_json()
        framework["unexpected"] = True
        self.assertEqual(
            base.host_gate_framework_json_keys_error(framework),
            "framework.json schema/keys differ",
        )
        self.assertEqual(
            eval_generated_key_check(framework),
            "framework.json schema/keys differ",
        )


if __name__ == "__main__":
    unittest.main()
