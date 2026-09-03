"""Source-level gate for scripts/pack_macho.py.

The rewriter is the fixture generator: if it silently stopped packing, the
committed packed dylib would still load on the mmap path and the copy path
would rot. --selftest rebuilds from tests/bin/libdylib_greet.dylib and
checks the unaligned-vmaddr / shared-page / export-offset invariants.

The committed cache_layout binaries are also checked here, so a Darwin
rebuild that forgot the pack/rename/oversize steps cannot land an aligned
dylib under the packed name.
"""
import importlib.util
import subprocess
import sys
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
PACK = ROOT / "scripts" / "pack_macho.py"
BIN = ROOT / "tests" / "bin"


def _pack_mod():
    spec = importlib.util.spec_from_file_location("pack_macho", PACK)
    mod = importlib.util.module_from_spec(spec)
    assert spec.loader is not None
    spec.loader.exec_module(mod)
    return mod


class PackMachoTests(unittest.TestCase):
    def test_selftest(self) -> None:
        r = subprocess.run(
            [sys.executable, str(PACK), "--selftest"],
            cwd=ROOT,
            capture_output=True,
            text=True,
            check=False,
        )
        self.assertEqual(r.returncode, 0, r.stdout + r.stderr)
        self.assertIn("pack_macho --selftest ok", r.stdout)

    def test_pack_script_is_the_generator(self) -> None:
        text = PACK.read_text(encoding="utf-8")
        for token in (
            "CACHE_UNALIGN = 0x720",
            "def pack_bytes",
            "def oversize_bytes",
            "dyld-shared-cache",
        ):
            self.assertIn(token, text)

    def test_committed_packed_dylib_is_unaligned(self) -> None:
        pm = _pack_mod()
        path = BIN / "libcache_packed.dylib"
        self.assertTrue(path.is_file(), path)
        img = pm.Image(path.read_bytes())
        text = next(s for s in img.segs if s.name == "__TEXT")
        data_c = next(s for s in img.segs if s.name == "__DATA_CONST")
        data_s = next(s for s in img.segs if s.name == "__DATA")
        self.assertTrue(pm.aligned(text.vmaddr))
        self.assertFalse(pm.aligned(data_c.vmaddr), hex(data_c.vmaddr))
        self.assertFalse(pm.aligned(data_c.fileoff), data_c.fileoff)
        self.assertEqual(
            data_c.vmaddr & ~(pm.HOST_PAGE - 1),
            data_s.vmaddr & ~(pm.HOST_PAGE - 1),
        )
        packed = pm.pack_bytes(
            (BIN / "libcache_layout.dylib").read_bytes(),
            install_name="@rpath/libcache_packed.dylib",
        )
        self.assertEqual(path.read_bytes(), packed)

    def test_committed_oversize_exceeds_file(self) -> None:
        pm = _pack_mod()
        path = BIN / "cache_layout_oversize"
        data = path.read_bytes()
        img = pm.Image(data)
        le = next(s for s in img.segs if s.name == "__LINKEDIT")
        self.assertGreater(le.fileoff + le.filesize, len(data))
        self.assertEqual(
            data,
            pm.oversize_bytes((BIN / "main_ret").read_bytes(), "__LINKEDIT"),
        )

    def test_stubs_adrp_targets_packed_got_page(self) -> None:
        """The 2026-09-03 packed-fixture crash: stubs still ADRP'd 0x4000."""
        pm = _pack_mod()
        packed = (BIN / "libcache_packed.dylib").read_bytes()
        img = pm.Image(packed)
        text = next(s for s in img.segs if s.name == "__TEXT")
        data_c = next(s for s in img.segs if s.name == "__DATA_CONST")
        stubs = next(s for s in text.sects if s["name"] == "__stubs")
        got_page = data_c.vmaddr & ~(pm.HOST_PAGE - 1)
        self.assertEqual(got_page, 0x14000)
        for off in range(0, stubs["size"], 12):
            pc = stubs["addr"] + off
            insn = int.from_bytes(packed[stubs["offset"] + off:][:4], "little")
            adrp = pm.decode_adrp(insn, pc)
            self.assertIsNotNone(adrp, hex(insn))
            self.assertEqual(adrp[1], got_page, f"stub ADRP at {pc:#x} -> {adrp[1]:#x}")

    def test_copy_map_in_process(self) -> None:
        src = ROOT / "tests" / "host" / "test_copy_map.c"
        out = Path("/tmp/mr-test-copy-map")
        r = subprocess.run(
            [
                "cc",
                "-std=gnu11",
                "-Wall",
                "-Wextra",
                "-Wno-unused-parameter",
                "-I",
                str(ROOT / "src"),
                "-o",
                str(out),
                str(src),
                str(ROOT / "src" / "map.c"),
                str(ROOT / "src" / "util.c"),
            ],
            cwd=ROOT,
            capture_output=True,
            text=True,
            check=False,
        )
        self.assertEqual(r.returncode, 0, r.stdout + r.stderr)
        r = subprocess.run([str(out)], capture_output=True, text=True, check=False)
        self.assertEqual(r.returncode, 0, r.stdout + r.stderr)
        self.assertIn("test_copy_map ok", r.stdout)
        self.assertIn("gap +0x4008 PROT_NONE", r.stdout)

    def test_committed_rename_roundtrip(self) -> None:
        pm = _pack_mod()
        layout = bytearray((BIN / "cache_layout").read_bytes())
        packed_exe = (BIN / "cache_layout_packed").read_bytes()
        n = pm.set_lc_string(
            layout, "@rpath/libcache_layout.dylib", "@rpath/libcache_packed.dylib"
        )
        self.assertGreaterEqual(n, 1)
        self.assertEqual(bytes(layout), packed_exe)


if __name__ == "__main__":
    unittest.main()
