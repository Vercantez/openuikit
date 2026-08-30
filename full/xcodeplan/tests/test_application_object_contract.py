from __future__ import annotations

import json
import os
from pathlib import Path
import struct
import subprocess
import sys
import tempfile
import unittest


HERE = Path(__file__).resolve().parent
TOOL_DIR = HERE.parent
sys.path.insert(0, os.fspath(TOOL_DIR))

import application_object_contract  # noqa: E402


def macho_object(payload: bytes = b"") -> bytes:
    return struct.pack(
        "<IIIIIIII",
        0xFEEDFACF,
        0x0100000C,
        0,
        1,
        0,
        0,
        0,
        0,
    ) + payload


def nul_paths(*paths: str) -> bytes:
    return b"".join(path.encode("utf-8") + b"\0" for path in paths)


class ApplicationObjectContractTests(unittest.TestCase):
    def make_sources(self, root: Path, count: int = 3) -> list[str]:
        sources: list[str] = []
        for index in range(count):
            path = root / f"Source{index}.swift"
            path.write_text(f"func source{index}() {{}}\n", encoding="utf-8")
            sources.append(os.fspath(path))
        return sources

    def publish_objects(self, object_root: Path, count: int) -> None:
        for index in range(count):
            (object_root / f"{index:06d}.o").write_bytes(
                macho_object(f"object-{index}".encode("ascii"))
            )

    def test_output_map_and_arm64_objects_are_exact_and_ordered(self) -> None:
        with tempfile.TemporaryDirectory(prefix="application-object-contract.") as raw:
            root = Path(raw).resolve()
            sources = self.make_sources(root)
            output_map = root / "output-file-map.json"
            object_root = root / "objects"
            audit = root / "object-audit.json"
            application_object_contract.create_output_map(
                output_map, object_root, sources
            )
            self.publish_objects(object_root, len(sources))
            objects = application_object_contract.verify_objects(
                output_map, object_root, audit, sources
            )

            self.assertEqual(
                [path.name for path in objects],
                ["000000.o", "000001.o", "000002.o"],
            )
            mapping = json.loads(output_map.read_text(encoding="utf-8"))
            self.assertEqual(list(mapping), sources)
            self.assertEqual(
                [Path(mapping[source]["object"]).name for source in sources],
                [path.name for path in objects],
            )
            document = json.loads(audit.read_text(encoding="utf-8"))
            self.assertEqual(document["object_count"], len(sources))
            self.assertEqual(
                [record["source"] for record in document["objects"]], sources
            )
            self.assertEqual(
                [record["index"] for record in document["objects"]], [0, 1, 2]
            )
            application_object_contract.verify_objects(
                output_map,
                object_root,
                audit,
                sources,
                publish_audit=False,
            )
            objects[1].write_bytes(macho_object(b"post-audit mutation"))
            with self.assertRaisesRegex(
                application_object_contract.ObjectContractError, "published.*differs"
            ):
                application_object_contract.verify_objects(
                    output_map,
                    object_root,
                    audit,
                    sources,
                    publish_audit=False,
                )

    def test_output_map_tamper_missing_extra_symlink_and_arch_drift_refuse(self) -> None:
        cases = ("map", "missing", "extra", "symlink", "architecture")
        for case in cases:
            with self.subTest(case=case), tempfile.TemporaryDirectory(
                prefix=f"application-object-{case}."
            ) as raw:
                root = Path(raw).resolve()
                sources = self.make_sources(root)
                output_map = root / "output-file-map.json"
                object_root = root / "objects"
                audit = root / "audit.json"
                application_object_contract.create_output_map(
                    output_map, object_root, sources
                )
                self.publish_objects(object_root, len(sources))
                if case == "map":
                    value = json.loads(output_map.read_text(encoding="utf-8"))
                    first = sources[0]
                    value[first]["object"] = os.fspath(object_root / "999999.o")
                    output_map.write_text(json.dumps(value), encoding="utf-8")
                elif case == "missing":
                    (object_root / "000001.o").unlink()
                elif case == "extra":
                    (object_root / "unexpected.o").write_bytes(macho_object())
                elif case == "symlink":
                    target = object_root / "000001.o"
                    target.unlink()
                    target.symlink_to(object_root / "000000.o")
                elif case == "architecture":
                    (object_root / "000001.o").write_bytes(b"not Mach-O")
                with self.assertRaises(application_object_contract.ObjectContractError):
                    application_object_contract.verify_objects(
                        output_map, object_root, audit, sources
                    )

    def test_duplicate_sources_and_reused_outputs_refuse(self) -> None:
        with tempfile.TemporaryDirectory(prefix="application-object-refusal.") as raw:
            root = Path(raw).resolve()
            sources = self.make_sources(root, 2)
            with self.assertRaisesRegex(
                application_object_contract.ObjectContractError, "duplicate"
            ):
                application_object_contract.create_output_map(
                    root / "duplicate.json", root / "duplicate-objects", [sources[0]] * 2
                )
            application_object_contract.create_output_map(
                root / "map.json", root / "objects", sources
            )
            with self.assertRaisesRegex(
                application_object_contract.ObjectContractError, "already exists"
            ):
                application_object_contract.create_output_map(
                    root / "map.json", root / "other-objects", sources
                )

    def test_cli_emits_exact_nul_order_only_after_complete_verification(self) -> None:
        with tempfile.TemporaryDirectory(prefix="application-object-cli.") as raw:
            root = Path(raw).resolve()
            sources = self.make_sources(root)
            output_map = root / "map.json"
            object_root = root / "objects"
            tool = TOOL_DIR / "application_object_contract.py"
            created = subprocess.run(
                [
                    sys.executable,
                    "-B",
                    os.fspath(tool),
                    "create-output-map",
                    "--output-map",
                    os.fspath(output_map),
                    "--object-root",
                    os.fspath(object_root),
                    *sources,
                ],
                stdout=subprocess.PIPE,
                stderr=subprocess.PIPE,
                check=False,
            )
            self.assertEqual(created.returncode, 0, created.stderr)
            self.assertEqual(created.stdout, b"")
            self.publish_objects(object_root, len(sources))
            verified = subprocess.run(
                [
                    sys.executable,
                    "-B",
                    os.fspath(tool),
                    "verify-objects",
                    "--output-map",
                    os.fspath(output_map),
                    "--object-root",
                    os.fspath(object_root),
                    "--audit",
                    os.fspath(root / "audit.json"),
                    *sources,
                ],
                stdout=subprocess.PIPE,
                stderr=subprocess.PIPE,
                check=False,
            )
            self.assertEqual(verified.returncode, 0, verified.stderr)
            self.assertEqual(
                verified.stdout,
                b"".join(os.fsencode(object_root / f"{index:06d}.o") + b"\0" for index in range(3)),
            )

    def test_preview_source_list_is_ordered_bounded_and_contains_macro(self) -> None:
        with tempfile.TemporaryDirectory(prefix="preview-source-contract.") as raw:
            root = Path(raw).resolve()
            source_root = root / "source"
            source_root.mkdir()
            (source_root / "A.swift").write_text(
                "#Preview { DependencyView() }\n", encoding="utf-8"
            )
            (source_root / "B.swift").write_text(
                "struct DependencyView {}\n", encoding="utf-8"
            )
            (source_root / "C.swift").write_text("struct Other {}\n", encoding="utf-8")
            application_list = root / "application.nul"
            preview_list = root / "preview.nul"
            application_list.write_bytes(nul_paths("A.swift", "B.swift", "C.swift"))
            preview_list.write_bytes(nul_paths("A.swift", "B.swift"))
            paths = application_object_contract.validate_preview_sources(
                source_root, application_list, preview_list, root / "audit.json"
            )
            self.assertEqual([path.name for path in paths], ["A.swift", "B.swift"])

            refusals = {
                "full-module": ("A.swift", "B.swift", "C.swift"),
                "reordered": ("B.swift", "A.swift"),
                "duplicate": ("A.swift", "A.swift"),
                "non-target": ("A.swift", "Missing.swift"),
                "no-preview": ("B.swift",),
            }
            for name, values in refusals.items():
                with self.subTest(refusal=name):
                    candidate = root / f"{name}.nul"
                    candidate.write_bytes(nul_paths(*values))
                    with self.assertRaises(
                        application_object_contract.ObjectContractError
                    ):
                        application_object_contract.validate_preview_sources(
                            source_root,
                            application_list,
                            candidate,
                            root / f"{name}-audit.json",
                        )

    def test_cross_file_edge_and_post_link_resolution_are_fail_closed(self) -> None:
        with tempfile.TemporaryDirectory(prefix="cross-file-symbol-contract.") as raw:
            root = Path(raw).resolve()
            first = root / "000000.o"
            second = root / "000001.o"
            executable = root / "Application"
            for path in (first, second, executable):
                path.write_bytes(b"fixture")
            nm = root / "llvm-nm"
            nm.write_text(
                "#!/bin/sh\n"
                "mode=$1\n"
                "last=\n"
                "for argument in \"$@\"; do last=$argument; done\n"
                "name=$(basename \"$last\")\n"
                "case \"$mode:$name\" in\n"
                "  --defined-only:000000.o) printf '%s\\n' '_$sSharedSymbol' '_symbolic ScA_pSg' ;;\n"
                "  --undefined-only:000001.o) printf '%s\\n' '_$sSharedSymbol' '_symbolic ScA_pSg' ;;\n"
                "  --undefined-only:Application) echo '_externalRuntime' ;;\n"
                "esac\n",
                encoding="utf-8",
            )
            nm.chmod(0o755)
            cross = application_object_contract.audit_cross_file_symbols(
                nm, root / "cross.json", [os.fspath(first), os.fspath(second)]
            )
            self.assertEqual(cross["edge_count"], 2)
            self.assertEqual(cross["edges"][0]["consumer"], 1)
            self.assertEqual(cross["edges"][0]["provider"], 0)
            linked = application_object_contract.audit_linked_executable(
                nm,
                executable,
                root / "cross.json",
                root / "linked.json",
                [os.fspath(first), os.fspath(second)],
            )
            self.assertEqual(linked["unresolved_internal_symbols"], [])

            cross_payload = (root / "cross.json").read_bytes()
            (root / "cross.json").write_text("{}\n", encoding="utf-8")
            with self.assertRaisesRegex(
                application_object_contract.ObjectContractError,
                "cross-file symbol audit differs",
            ):
                application_object_contract.audit_linked_executable(
                    nm,
                    executable,
                    root / "cross.json",
                    root / "linked-cross-tamper.json",
                    [os.fspath(first), os.fspath(second)],
                )
            (root / "cross.json").write_bytes(cross_payload)

            nm.write_text(
                nm.read_text(encoding="utf-8").replace(
                    "--undefined-only:Application) echo '_externalRuntime'",
                    "--undefined-only:Application) echo '_$sSharedSymbol'",
                ),
                encoding="utf-8",
            )
            with self.assertRaisesRegex(
                application_object_contract.ObjectContractError, "app-internal"
            ):
                application_object_contract.audit_linked_executable(
                    nm,
                    executable,
                    root / "cross.json",
                    root / "linked-failure.json",
                    [os.fspath(first), os.fspath(second)],
                )


if __name__ == "__main__":
    unittest.main()
