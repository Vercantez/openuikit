#!/usr/bin/env python3
"""Unit teeth for patch_cf_system_allocator.py. No CF checkout required."""
from __future__ import annotations

import pathlib
import sys
import tempfile
import textwrap
import unittest

HERE = pathlib.Path(__file__).resolve().parent
sys.path.insert(0, str(HERE))
import patch_cf_system_allocator as patcher  # noqa: E402

# The fixture mirrors the pin's TARGET_OS_MAC + portable #else pair plus
# CFAllocator-as-zone dispatch that must survive the rewrite.

MAC_AND_PORTABLE = textwrap.dedent(
    r"""
    static void *__CFAllocatorSystemAllocate(CFIndex size, CFOptionFlags hint, void *info) {
        malloc_zone_t * const zone = (info == &__MallocDefaultZoneInfoPlaceholder) ? malloc_default_zone() : (malloc_zone_t *)info;
        void *result = NULL;
        if (hint == _CFAllocatorHintZeroWhenAllocating) {
            result = malloc_zone_calloc(zone, 1, size);
        } else {
            result = malloc_zone_malloc(zone, size);
        }
        return result;
    }

    static void *__CFAllocatorSystemReallocate(void *ptr, CFIndex newsize, CFOptionFlags hint, void *info) {
        malloc_zone_t * const zone = (info == &__MallocDefaultZoneInfoPlaceholder) ? malloc_default_zone() : (malloc_zone_t *)info;
        return malloc_zone_realloc(zone, ptr, newsize);
    }

    static void __CFAllocatorSystemDeallocate(void *ptr, void *info) {
        malloc_zone_t * const zone = (info == &__MallocDefaultZoneInfoPlaceholder) ? malloc_default_zone() : (malloc_zone_t *)info;
        malloc_zone_free(zone, ptr);
    }

    #else

    static void *__CFAllocatorSystemAllocate(CFIndex size, CFOptionFlags hint, void *info) {
        if (hint == _CFAllocatorHintZeroWhenAllocating) {
            return calloc(1, size);
        } else {
            return malloc(size);
        }
    }

    static void *__CFAllocatorSystemReallocate(void *ptr, CFIndex newsize, CFOptionFlags hint, void *info) {
        return realloc(ptr, newsize);
    }

    static void __CFAllocatorSystemDeallocate(void *ptr, void *info) {
        free(ptr);
    }
    #endif

    void *CFAllocatorAllocate(CFAllocatorRef allocator, CFIndex size, CFOptionFlags hint) {
    #if TARGET_OS_MAC
        if (_CFTypeGetClass(allocator) != __CFISAForCFAllocator()) {
            return malloc_zone_malloc((malloc_zone_t *)allocator, size);
        }
    #endif
        return NULL;
    }
    """
)


class PatchSystemAllocator(unittest.TestCase):
    def test_rewrites_mac_callbacks_keeps_zone_dispatch(self) -> None:
        out = patcher.patch_text(MAC_AND_PORTABLE)
        first = patcher._first_body(out, patcher.SIG_ALLOCATE)
        self.assertNotIn("malloc_zone_malloc", first)
        self.assertIn("return malloc(size);", first)
        self.assertIn("malloc_zone_malloc((malloc_zone_t *)allocator, size);", out)
        self.assertTrue(patcher.already_patched(out))

    def test_idempotent(self) -> None:
        once = patcher.patch_text(MAC_AND_PORTABLE)
        twice = patcher.patch_text(once)
        self.assertEqual(once, twice)

    def test_refuses_missing_callbacks(self) -> None:
        with self.assertRaises(SystemExit):
            patcher.patch_text("int main(void) { return 0; }\n")

    def test_writes_file(self) -> None:
        with tempfile.TemporaryDirectory() as td:
            path = pathlib.Path(td) / "CFBase.c"
            path.write_text(MAC_AND_PORTABLE, encoding="utf-8")
            rc = patcher.main(["patch_cf_system_allocator.py", str(path)])
            self.assertEqual(rc, 0)
            text = path.read_text(encoding="utf-8")
            self.assertTrue(patcher.already_patched(text))
            rc2 = patcher.main(["patch_cf_system_allocator.py", str(path.parent)])
            self.assertEqual(rc2, 0)


if __name__ == "__main__":
    unittest.main()
