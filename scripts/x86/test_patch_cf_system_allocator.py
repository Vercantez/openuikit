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

PIN_CFBASE = textwrap.dedent(
    r"""
    DECLARE_STATIC_CLASS_REF(__NSCFType);

    static _CF_CONSTANT_OBJECT_BACKING struct __CFAllocator __kCFAllocatorMalloc = {
        INIT_CFRUNTIME_BASE_WITH_CLASS(__NSCFType, _kCFRuntimeIDCFAllocator),
    };
    static _CF_CONSTANT_OBJECT_BACKING struct __CFAllocator __kCFAllocatorMallocZone = {
        INIT_CFRUNTIME_BASE_WITH_CLASS(__NSCFType, _kCFRuntimeIDCFAllocator),
    };
    static _CF_CONSTANT_OBJECT_BACKING struct __CFAllocator __kCFAllocatorSystemDefault = {
        INIT_CFRUNTIME_BASE_WITH_CLASS(__NSCFType, _kCFRuntimeIDCFAllocator),
    };
    static _CF_CONSTANT_OBJECT_BACKING struct __CFAllocator __kCFAllocatorNull = {
        INIT_CFRUNTIME_BASE_WITH_CLASS(__NSCFType, _kCFRuntimeIDCFAllocator),
    };

    const CFAllocatorRef kCFAllocatorUseContext = (CFAllocatorRef)0x03ab;

    void *CFAllocatorAllocate(CFAllocatorRef allocator, CFIndex size, CFOptionFlags hint) {
    #if TARGET_OS_MAC
        if (_CFTypeGetClass(allocator) != __CFISAForCFAllocator()) {
            return malloc_zone_malloc((malloc_zone_t *)allocator, size);
        }
    #endif
        return NULL;
    }

    DECLARE_STATIC_CLASS_REF(NSNull);
    struct __CFNull _CF_CONSTANT_OBJECT_BACKING __kCFNull = {
        INIT_CFRUNTIME_BASE_WITH_CLASS(NSNull, _kCFRuntimeIDCFNull)
    };
    """
)

PIN_PLATFORM = textwrap.dedent(
    r"""
    CF_PRIVATE void __CFTSDInitialize() {
    #if !TARGET_OS_WASI
        static dispatch_once_t once;
        dispatch_once(&once, ^{
            (void)pthread_key_create(&__CFTSDIndexKey, __CFTSDFinalize);
        });
    #endif
    }

    static __CFTSDTable *__CFTSDGetTable(const Boolean create) {
        __CFTSDTable *table = (__CFTSDTable *)__CFTSDGetSpecific();
        // Make sure we're not setting data again after destruction.
        if (table == CF_TSD_BAD_PTR) {
            return NULL;
        }
        // Create table on demand
        if (!table && create) {
            // This memory is freed in the finalize function
            table = (__CFTSDTable *)calloc(1, sizeof(__CFTSDTable));
            // Windows and Linux have created the table already, we need to initialize it here for other platforms. On Windows, the cleanup function is called by DllMain when a thread exits. On Linux the destructor is set at init time.
    #if !TARGET_OS_WIN32
            __CFTSDInitialize();
    #endif
            __CFTSDSetSpecific(table);
        }

        return table;
    }
    """
)


class PatchAllocatorIsaAndTSD(unittest.TestCase):
    def test_binds_static_isa_keeps_zone_branch(self) -> None:
        out = patcher.patch_cfbase(PIN_CFBASE)
        self.assertIn(patcher.MARKER_ISA, out)
        self.assertIn(patcher.MARKER_CTOR, out)
        self.assertIn("OBJC_CLASS_$___NSCFType", out)
        self.assertIn("_SetCFRuntimeObjcClass(OPENUIKIT_CFALLOCATOR_ISA", out)
        self.assertIn(
            "malloc_zone_malloc((malloc_zone_t *)allocator, size)", out
        )
        self.assertNotIn(
            "INIT_CFRUNTIME_BASE_WITH_CLASS(__NSCFType, _kCFRuntimeIDCFAllocator)",
            out,
        )
        self.assertIn(
            "INIT_CFRUNTIME_BASE_WITH_CLASS(NSNull, _kCFRuntimeIDCFNull)", out
        )
        self.assertTrue(patcher.already_patched_base(out))

    def test_cfbase_idempotent(self) -> None:
        once = patcher.patch_cfbase(PIN_CFBASE)
        twice = patcher.patch_cfbase(once)
        self.assertEqual(once, twice)

    def test_tsd_key_before_getspecific(self) -> None:
        out = patcher.patch_platform(PIN_PLATFORM)
        self.assertIn(patcher.MARKER_TSD, out)
        self.assertIn("pthread_once(&once, __CFTSDCreateKey)", out)
        self.assertIn("__CFTSDInitialize();", out)
        # key is created before the first getspecific, not only on create=
        self.assertLess(
            out.find("__CFTSDInitialize();"),
            out.find("__CFTSDGetSpecific()"),
        )
        self.assertNotIn("dispatch_once(&once, ^{", out)
        self.assertTrue(patcher.already_patched_platform(out))

    def test_platform_idempotent(self) -> None:
        once = patcher.patch_platform(PIN_PLATFORM)
        twice = patcher.patch_platform(once)
        self.assertEqual(once, twice)

    def test_refuses_missing_cfbase_anchor(self) -> None:
        with self.assertRaises(SystemExit):
            patcher.patch_cfbase("int main(void) { return 0; }\n")

    def test_refuses_missing_zone_branch(self) -> None:
        with self.assertRaises(SystemExit):
            patcher.patch_cfbase(
                PIN_CFBASE.replace(
                    "malloc_zone_malloc((malloc_zone_t *)allocator, size)",
                    "malloc(size)",
                )
            )

    def test_refuses_missing_platform_anchor(self) -> None:
        with self.assertRaises(SystemExit):
            patcher.patch_platform("int main(void) { return 0; }\n")

    def test_directory_patches_base_and_platform_not_headers(self) -> None:
        with tempfile.TemporaryDirectory() as td:
            root = pathlib.Path(td)
            (root / "include").mkdir()
            (root / "internalInclude").mkdir()
            (root / "CFBase.c").write_text(PIN_CFBASE, encoding="utf-8")
            (root / "CFPlatform.c").write_text(PIN_PLATFORM, encoding="utf-8")
            (root / "include" / "CFRuntime.h").write_text(
                "CF_INLINE Boolean _CFAllocatorIsSystemDefault"
                "(CFAllocatorRef allocator) {\n"
                "    if (allocator == kCFAllocatorSystemDefault) return true;\n"
                "    return false;\n"
                "}\n",
                encoding="utf-8",
            )
            (root / "internalInclude" / "CFInternal.h").write_text(
                "CF_INLINE CFAllocatorRef __CFGetDefaultAllocator(void) {\n"
                "    CFAllocatorRef allocator = "
                "(CFAllocatorRef)_CFGetTSD(__CFTSDKeyAllocator);\n"
                "    if (NULL == allocator) {\n"
                "        allocator = kCFAllocatorSystemDefault;\n"
                "    }\n"
                "    return allocator;\n"
                "}\n",
                encoding="utf-8",
            )
            rc = patcher.main(["patch_cf_system_allocator.py", str(root)])
            self.assertEqual(rc, 0)
            base = (root / "CFBase.c").read_text(encoding="utf-8")
            plat = (root / "CFPlatform.c").read_text(encoding="utf-8")
            self.assertTrue(patcher.already_patched_base(base))
            self.assertTrue(patcher.already_patched_platform(plat))
            self.assertIn(
                "malloc_zone_malloc((malloc_zone_t *)allocator, size)", base
            )
            rt = (root / "include" / "CFRuntime.h").read_text(encoding="utf-8")
            inn = (root / "internalInclude" / "CFInternal.h").read_text(
                encoding="utf-8"
            )
            self.assertIn("allocator == kCFAllocatorSystemDefault", rt)
            self.assertIn("_CFGetTSD(__CFTSDKeyAllocator)", inn)
            rc2 = patcher.main(["patch_cf_system_allocator.py", str(root)])
            self.assertEqual(rc2, 0)

    def test_file_argument_is_refused(self) -> None:
        with tempfile.TemporaryDirectory() as td:
            path = pathlib.Path(td) / "CFBase.c"
            path.write_text(PIN_CFBASE, encoding="utf-8")
            rc = patcher.main(["patch_cf_system_allocator.py", str(path)])
            self.assertEqual(rc, 2)


if __name__ == "__main__":
    unittest.main()
