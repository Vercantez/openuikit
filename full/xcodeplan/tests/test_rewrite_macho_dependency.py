#!/usr/bin/env python3

from __future__ import annotations

from pathlib import Path
import struct
import sys
import tempfile
import unittest


TOOL_DIR = Path(__file__).resolve().parent.parent
sys.path.insert(0, str(TOOL_DIR))

from rewrite_macho_dependency import (  # noqa: E402
    MachODependencyRewriteError,
    rewrite_dependency,
    rewrite_file,
)


OLD = "/System/Library/Frameworks/Foundation.framework/Foundation"
NEW = "/usr/lib/libFoundation.dylib"


def command(kind: int, payload: bytes) -> bytes:
    size = (8 + len(payload) + 7) & ~7
    return struct.pack("<II", kind, size) + payload + bytes(size - 8 - len(payload))


def dylib(kind: int, name: str) -> bytes:
    return command(
        kind,
        struct.pack("<IIII", 24, 0, 0x10000, 0x10000)
        + name.encode("utf-8")
        + b"\0",
    )


def macho(*names: str) -> bytes:
    commands = [dylib(0x0C, name) for name in names]
    payload = b"".join(commands)
    return struct.pack(
        "<IiiIIIII", 0xFEEDFACF, 0x0100000C, 0, 6,
        len(commands), len(payload), 0, 0,
    ) + payload + b"PAYLOAD-MUST-NOT-MOVE"


class RewriteMachODependencyTests(unittest.TestCase):
    def test_exact_shorter_dependency_is_rewritten_in_place(self) -> None:
        original = macho(OLD, "/usr/lib/libobjc.A.dylib")
        rewritten = rewrite_dependency(original, OLD, NEW)
        self.assertEqual(len(rewritten), len(original))
        self.assertNotIn(OLD.encode("utf-8"), rewritten)
        self.assertIn(NEW.encode("utf-8") + b"\0", rewritten)
        self.assertEqual(
            rewritten[-len(b"PAYLOAD-MUST-NOT-MOVE"):],
            b"PAYLOAD-MUST-NOT-MOVE",
        )

    def test_absent_duplicate_and_growing_subjects_fail_closed(self) -> None:
        with self.assertRaisesRegex(MachODependencyRewriteError, "found 0"):
            rewrite_dependency(macho("/usr/lib/libobjc.A.dylib"), OLD, NEW)
        with self.assertRaisesRegex(MachODependencyRewriteError, "found 2"):
            rewrite_dependency(macho(OLD, OLD), OLD, NEW)
        with self.assertRaisesRegex(MachODependencyRewriteError, "does not fit"):
            rewrite_dependency(macho("/x"), "/x", OLD)

    def test_file_mode_is_preserved(self) -> None:
        with tempfile.TemporaryDirectory(prefix="rewrite-macho-dependency.") as temporary:
            path = Path(temporary) / "libswiftCore.dylib"
            path.write_bytes(macho(OLD))
            path.chmod(0o755)
            rewrite_file(path, OLD, NEW)
            self.assertEqual(path.stat().st_mode & 0o777, 0o755)
            self.assertIn(NEW.encode("utf-8") + b"\0", path.read_bytes())


if __name__ == "__main__":
    unittest.main()
