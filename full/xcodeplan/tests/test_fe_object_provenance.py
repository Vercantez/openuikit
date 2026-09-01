#!/usr/bin/env python3

from __future__ import annotations

import hashlib
import importlib.util
from pathlib import Path
import re
import subprocess
import sys
import tempfile
import unittest


ROOT = Path(__file__).resolve().parents[3]
TOOL = ROOT / "full/foundation/fe_object_provenance.py"
BUILD_FULL = ROOT / "full/scripts/build_full.sh"
PLATFORM_BUILDER = ROOT / "full/xcodeplan/build_true_ios_platform_frameworks.sh"


def load_tool():
    spec = importlib.util.spec_from_file_location("fe_object_provenance", TOOL)
    assert spec is not None and spec.loader is not None
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


class FEObjectProvenanceTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls) -> None:
        cls.tool = load_tool()

    def setUp(self) -> None:
        self.temporary = tempfile.TemporaryDirectory()
        temporary = Path(self.temporary.name)
        self.project = temporary / "project"
        self.full = temporary / "full"
        self.attestation = temporary / "foundation-fe-object-provenance.tsv"
        self.subject = "a" * 64

        source_paths = {source for _, source in self.tool.PROJECT_OWNED_SOURCES}
        for relative in source_paths:
            path = self.project / relative
            path.parent.mkdir(parents=True, exist_ok=True)
            path.write_bytes(f"source:{relative}\n".encode("ascii"))
        for relative in self.tool.FE_OBJECTS:
            path = self.full / relative
            path.parent.mkdir(parents=True, exist_ok=True)
            path.write_bytes(f"object:{relative}\n".encode("ascii"))

        self.attestation.write_bytes(
            self.tool.render(self.project, self.full, self.subject)
        )

    def tearDown(self) -> None:
        self.temporary.cleanup()

    def verify(self) -> subprocess.CompletedProcess[str]:
        return subprocess.run(
            [
                sys.executable,
                str(TOOL),
                "verify",
                "--project",
                str(self.project),
                "--full",
                str(self.full),
                "--subject",
                self.subject,
                "--attestation",
                str(self.attestation),
            ],
            check=False,
            text=True,
            capture_output=True,
        )

    def test_exact_source_object_and_subject_closure_verifies(self) -> None:
        result = self.verify()
        self.assertEqual(result.returncode, 0, result.stderr)
        rows = self.attestation.read_text(encoding="ascii").splitlines()
        self.assertEqual(rows[0], f"schema\t{self.tool.SCHEMA}")
        self.assertEqual(rows[1], f"full-subject\t{self.subject}")
        self.assertEqual(
            sum(row.startswith("source\t") for row in rows),
            len(self.tool.PROJECT_OWNED_SOURCES),
        )
        self.assertEqual(
            sum(row.startswith("object\t") for row in rows),
            len(self.tool.FE_OBJECTS),
        )

    def test_attested_object_set_exactly_matches_both_link_closures(self) -> None:
        full_builder = BUILD_FULL.read_text(encoding="utf-8")
        full_match = re.search(r"\nFE_OBJECTS=\(\n(?P<body>.*?)\n\)\n", full_builder, re.S)
        self.assertIsNotNone(full_match)
        full_prefixes = {
            "FE_OUT": "foundation/essentials",
            "FE_COLLECTIONS": "foundation/collections",
            "FE_OS": "foundation/os",
            "FE_CSHIMS": "foundation/cshims",
        }
        full_objects = []
        assert full_match is not None
        for variable, basename in re.findall(
            r'^\s+"\$(FE_OUT|FE_COLLECTIONS|FE_OS|FE_CSHIMS)/([^"/]+\.o)"$',
            full_match.group("body"),
            re.M,
        ):
            full_objects.append(f"{full_prefixes[variable]}/{basename}")

        platform_builder = PLATFORM_BUILDER.read_text(encoding="utf-8")
        platform_match = re.search(
            r"\nFE_OBJECTS=\(\n(?P<body>.*?)\n\)\n", platform_builder, re.S
        )
        self.assertIsNotNone(platform_match)
        assert platform_match is not None
        platform_objects = re.findall(
            r'^\s+"\$FULL/([^"/]+(?:/[^"/]+)*/[^"/]+\.o)"$',
            platform_match.group("body"),
            re.M,
        )

        self.assertEqual(tuple(full_objects), self.tool.FE_OBJECTS)
        self.assertEqual(tuple(platform_objects), self.tool.FE_OBJECTS)

    def test_old_object_is_rejected_after_each_owning_source_changes(self) -> None:
        for object_relative, source_relative in self.tool.PROJECT_OWNED_SOURCES:
            with self.subTest(source=source_relative, object=object_relative):
                source = self.project / source_relative
                original_source = source.read_bytes()
                object_path = self.full / object_relative
                object_before = hashlib.sha256(object_path.read_bytes()).hexdigest()
                source.write_bytes(original_source + b"mutated\n")

                result = self.verify()

                self.assertEqual(result.returncode, 2)
                self.assertIn(source_relative, result.stderr)
                self.assertIn(
                    "does not match the active project sources and full-build objects",
                    result.stderr,
                )
                self.assertEqual(
                    hashlib.sha256(object_path.read_bytes()).hexdigest(), object_before
                )
                source.write_bytes(original_source)
                self.assertEqual(self.verify().returncode, 0)

    def test_any_consumed_fe_object_byte_mutation_is_rejected(self) -> None:
        for object_relative in self.tool.FE_OBJECTS:
            with self.subTest(object=object_relative):
                object_path = self.full / object_relative
                original = object_path.read_bytes()
                object_path.write_bytes(original + b"stale-or-corrupt\n")
                result = self.verify()
                self.assertEqual(result.returncode, 2)
                self.assertIn(object_relative, result.stderr)
                object_path.write_bytes(original)

    def test_subject_mismatch_and_linked_input_fail_closed(self) -> None:
        mismatched = subprocess.run(
            [
                sys.executable,
                str(TOOL),
                "verify",
                "--project",
                str(self.project),
                "--full",
                str(self.full),
                "--subject",
                "b" * 64,
                "--attestation",
                str(self.attestation),
            ],
            check=False,
            text=True,
            capture_output=True,
        )
        self.assertEqual(mismatched.returncode, 2)
        self.assertIn("full-subject", mismatched.stderr)

        source_relative = self.tool.PROJECT_OWNED_SOURCES[0][1]
        source = self.project / source_relative
        source.unlink()
        source.symlink_to(self.attestation)
        linked = self.verify()
        self.assertEqual(linked.returncode, 2)
        self.assertIn("regular non-symlink", linked.stderr)


if __name__ == "__main__":
    unittest.main()
