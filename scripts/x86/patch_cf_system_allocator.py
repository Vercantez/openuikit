#!/usr/bin/env python3
"""Bind CFAllocator's isa/class and create the TSD key before first getspecific.

Usage:
    python3 scripts/x86/patch_cf_system_allocator.py <CoreFoundation-dir>

Does NOT rewrite the TARGET_OS_MAC malloc_zone_t* branch. CF is designed to
accept a raw zone as a CFAllocator; removing that path changes semantics.

Root cause (cold-build probes on this guest, pin f3a7a343):

  At CFAllocatorAllocate from CFStringCreateWithBytes / _CFStringGetTypeID:
    kCFAllocatorSystemDefault isa = 0
    __CFISAForCFAllocator()   = 0   (table slot 2 empty)
    take_zone                 = 0
    __CFInitialized           = 0
    TARGET_OS_MAC=1 DEPLOYMENT_RUNTIME_SWIFT=0 INCLUDE_OBJC=1
    STATIC_CLASS_REF(__NSCFType) is NULL (ForFoundationOnly.h !SWIFT branch)

  So the system-default object does NOT take the zone branch: both sides of
  `_CFTypeGetClass(allocator) != __CFISAForCFAllocator()` are 0. Registering
  CFAllocator in the class table while leaving static isa at 0 would CREATE
  that mismatch. Apple's comparison is true because BOTH sides are the
  CFAllocator/__NSCFType class.

  The abort is a later allocate whose `allocator` is a Linux heap pointer
  (isa == that pointer, typeid garbage, take_zone=1). __CFGetDefaultAllocator
  reads _CFGetTSD(__CFTSDKeyAllocator). __CFInitialize is not a constructor
  under TARGET_OS_MAC (only LINUX/BSD/WASI), so the pthread key is never
  created and pthread_getspecific(0) collides with another runtime's key 0.

This patcher:

  1. Points the four static CFAllocator objects' isa at nscf's
     OBJC_CLASS_$___NSCFType (the class INIT_CFRUNTIME_BASE_WITH_CLASS names).
  2. Constructor-registers that class in table slot _kCFRuntimeIDCFAllocator
     so __CFISAForCFAllocator() matches, before any CFStringCreate.
  3. Creates the TSD key with pthread_once (not dispatch_once) and does so
     before the first pthread_getspecific, which is Apple's
     __CFTSDInitialize-before-first-use ordering without running the rest of
     __CFInitialize (Darwin walls: argv, atfork, encoding).

The pin checkout is not mutated. Callers copy Sources/CoreFoundation first.
"""
from __future__ import annotations

import pathlib
import sys

MARKER_ISA = "openuikit-x86: static CFAllocator isa is __NSCFType"
MARKER_TSD = "openuikit-x86: TSD key before getspecific"
MARKER_CTOR = "openuikit-x86: bind CFAllocator class before first CFStringCreate"

DECL_OLD = "DECLARE_STATIC_CLASS_REF(__NSCFType);"

DECL_NEW = """DECLARE_STATIC_CLASS_REF(__NSCFType);
/* openuikit-x86: static CFAllocator isa is __NSCFType
 *
 * ForFoundationOnly.h defines STATIC_CLASS_REF(...) as NULL when
 * DEPLOYMENT_RUNTIME_SWIFT=0, so INIT_CFRUNTIME_BASE_WITH_CLASS writes isa 0.
 * nscf's __NSCFType lives in the same libCFTest image as these objects
 * (_OBJC_CLASS_$___NSCFType). Using that symbol matches Apple's
 * DEPLOYMENT_RUNTIME_SWIFT fill (every slot, including CFAllocator, is
 * the NSCFType base class) without flipping SWIFT on for the whole TU.
 * NSNull later in this file keeps STATIC_CLASS_REF(NSNull)=NULL. */
extern void OBJC_CLASS_$___NSCFType;
#define OPENUIKIT_CFALLOCATOR_ISA ((uintptr_t)&OBJC_CLASS_$___NSCFType)"""

INIT_OLD = "INIT_CFRUNTIME_BASE_WITH_CLASS(__NSCFType, _kCFRuntimeIDCFAllocator)"
INIT_NEW = (
    "{ ._cfisa = OPENUIKIT_CFALLOCATOR_ISA, "
    "._cfinfoa = 0x0000000000000080ULL | ((_kCFRuntimeIDCFAllocator) << 8) }"
)

CTOR_ANCHOR = "const CFAllocatorRef kCFAllocatorUseContext = (CFAllocatorRef)0x03ab;"

CTOR_NEW = """const CFAllocatorRef kCFAllocatorUseContext = (CFAllocatorRef)0x03ab;

CF_PRIVATE void __CFTSDInitialize(void);

/* openuikit-x86: bind CFAllocator class before first CFStringCreate
 *
 * Table slot 2 (__CFISAForCFAllocator) is otherwise left 0 because CFAllocator
 * is NOT_BRIDGED (docs/cf-registration.tsv) and the SWIFT all-slots fill is
 * compiled out. isa and the table must match: setting only one takes the
 * malloc_zone_t* branch for kCFAllocatorSystemDefault. */
static void __CFAllocatorBindIsa(void) __attribute__((constructor(101)));
static void __CFAllocatorBindIsa(void) {
    _SetCFRuntimeObjcClass(OPENUIKIT_CFALLOCATOR_ISA, _kCFRuntimeIDCFAllocator);
    __CFTSDInitialize();
}"""

TSD_INIT_OLD = """CF_PRIVATE void __CFTSDInitialize() {
#if !TARGET_OS_WASI
    static dispatch_once_t once;
    dispatch_once(&once, ^{
        (void)pthread_key_create(&__CFTSDIndexKey, __CFTSDFinalize);
    });
#endif
}"""

TSD_INIT_NEW = """static void __CFTSDCreateKey(void) {
    (void)pthread_key_create(&__CFTSDIndexKey, __CFTSDFinalize);
}

CF_PRIVATE void __CFTSDInitialize() {
#if !TARGET_OS_WASI
    /* openuikit-x86: TSD key before getspecific
     * pthread_once, not dispatch_once: this Darwin-target guest may run
     * before libdispatch_init (libSystem does that on a real Mac). */
    static pthread_once_t once = PTHREAD_ONCE_INIT;
    pthread_once(&once, __CFTSDCreateKey);
#endif
}"""

GET_TABLE_OLD = """static __CFTSDTable *__CFTSDGetTable(const Boolean create) {
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
    }"""

GET_TABLE_NEW = """static __CFTSDTable *__CFTSDGetTable(const Boolean create) {
    /* openuikit-x86: TSD key before getspecific
     * Apple's __CFInitialize calls __CFTSDInitialize first. Without that,
     * pthread_getspecific on a zero pthread_key_t returns another runtime's
     * key 0 (a Linux heap block), which __CFGetDefaultAllocator then hands
     * to CFAllocatorAllocate as a malloc_zone_t*. */
#if !TARGET_OS_WIN32
    __CFTSDInitialize();
#endif
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
        __CFTSDSetSpecific(table);
    }"""


def already_patched_base(text: str) -> bool:
    return MARKER_ISA in text and MARKER_CTOR in text


def already_patched_platform(text: str) -> bool:
    return MARKER_TSD in text and "pthread_once(&once, __CFTSDCreateKey)" in text


def patch_cfbase(text: str) -> str:
    if already_patched_base(text):
        return text
    if DECL_OLD not in text:
        raise SystemExit(
            "patch_cf_system_allocator: missing DECLARE_STATIC_CLASS_REF(__NSCFType) "
            "(pin changed; will not invent a CF allocator isa)"
        )
    if text.count(INIT_OLD) < 4:
        raise SystemExit(
            "patch_cf_system_allocator: expected four static CFAllocator "
            "INIT_CFRUNTIME_BASE_WITH_CLASS(__NSCFType) sites "
            f"(found {text.count(INIT_OLD)}; pin changed)"
        )
    if CTOR_ANCHOR not in text:
        raise SystemExit(
            "patch_cf_system_allocator: missing kCFAllocatorUseContext "
            "(pin changed; will not invent a CF allocator constructor)"
        )
    if "malloc_zone_malloc((malloc_zone_t *)allocator" not in text:
        raise SystemExit(
            "patch_cf_system_allocator: CFBase.c has no allocator-as-zone "
            "malloc_zone_malloc (pin changed, or a previous rewrite removed "
            "the branch CF is designed to have)"
        )
    out = text.replace(DECL_OLD, DECL_NEW, 1)
    out = out.replace(INIT_OLD, INIT_NEW)
    out = out.replace(CTOR_ANCHOR, CTOR_NEW, 1)
    if MARKER_ISA not in out or MARKER_CTOR not in out:
        raise SystemExit("patch_cf_system_allocator: CFBase.c isa/ctor rewrite did not stick")
    if "malloc_zone_malloc((malloc_zone_t *)allocator" not in out:
        raise SystemExit(
            "patch_cf_system_allocator: allocator-as-zone branch was removed; "
            "refusing to change CF zone semantics"
        )
    if INIT_OLD in out:
        raise SystemExit(
            "patch_cf_system_allocator: static CFAllocator still uses "
            "STATIC_CLASS_REF(__NSCFType)"
        )
    return out


def patch_platform(text: str) -> str:
    if already_patched_platform(text):
        return text
    if TSD_INIT_OLD not in text:
        raise SystemExit(
            "patch_cf_system_allocator: missing pin __CFTSDInitialize "
            "dispatch_once body (pin changed; will not invent TSD init)"
        )
    if GET_TABLE_OLD not in text:
        raise SystemExit(
            "patch_cf_system_allocator: missing pin __CFTSDGetTable "
            "(pin changed; will not invent TSD getspecific ordering)"
        )
    out = text.replace(TSD_INIT_OLD, TSD_INIT_NEW, 1)
    out = out.replace(GET_TABLE_OLD, GET_TABLE_NEW, 1)
    if MARKER_TSD not in out:
        raise SystemExit("patch_cf_system_allocator: CFPlatform.c TSD rewrite did not stick")
    if "dispatch_once(&once, ^{" in out and "__CFTSDCreateKey" not in out:
        raise SystemExit(
            "patch_cf_system_allocator: __CFTSDInitialize still uses dispatch_once"
        )
    return out


def _write_if_changed(path: pathlib.Path, original: str, updated: str, what: str) -> None:
    if updated != original:
        path.write_text(updated, encoding="utf-8")
        print(f"patched {path} ({what})", file=sys.stderr)
    else:
        print(f"already patched {path}", file=sys.stderr)


def main(argv: list[str]) -> int:
    if len(argv) != 2:
        print(
            "usage: patch_cf_system_allocator.py <CoreFoundation-dir>",
            file=sys.stderr,
        )
        return 2
    root = pathlib.Path(argv[1])
    if not root.is_dir():
        print(
            "patch_cf_system_allocator: need a CoreFoundation directory "
            f"(got {root})",
            file=sys.stderr,
        )
        return 2
    base = root / "CFBase.c"
    platform = root / "CFPlatform.c"
    if not base.is_file():
        print(f"patch_cf_system_allocator: missing {base}", file=sys.stderr)
        return 2
    if not platform.is_file():
        print(
            f"patch_cf_system_allocator: missing {platform} "
            "(pin changed; will not invent a CF allocator)",
            file=sys.stderr,
        )
        return 2

    original_base = base.read_text(encoding="utf-8")
    _write_if_changed(
        base,
        original_base,
        patch_cfbase(original_base),
        "static CFAllocator isa -> __NSCFType + constructor class bind",
    )
    original_plat = platform.read_text(encoding="utf-8")
    _write_if_changed(
        platform,
        original_plat,
        patch_platform(original_plat),
        "__CFTSDInitialize pthread_once; key before getspecific",
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main(sys.argv))
