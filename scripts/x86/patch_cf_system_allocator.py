#!/usr/bin/env python3
"""Rewrite TARGET_OS_MAC CF allocator paths that pass a CFAllocator as a zone.

Usage:
    python3 scripts/x86/patch_cf_system_allocator.py <CoreFoundation-dir-or-CFBase.c>

machorun libSystem has exactly one malloc zone (the default). Two Apple
TARGET_OS_MAC paths abort (guest exit 71 in __CFRuntimeCreateInstance):

  1. __CFAllocatorSystemAllocate passes allocator->_context.info as a zone.
     The portable #else already uses malloc/calloc/realloc/free.
  2. CFAllocatorAllocate treats a CFAllocator as a malloc_zone_t when
     _cfisa != __CFISAForCFAllocator(). corelibs never registers that
     class (table is 0) while static allocators carry __NSCFType, so
     kCFAllocatorSystemDefault takes malloc_zone_malloc(allocator).
     clang -Os folds an isa conjunct against the static object into the
     same 0 table slot, so a second isa check does not survive.

Rewrite (1) to the portable bodies and (2) to malloc/realloc/free.
Real malloc_zone_t* passed as a CFAllocator then use the process heap,
which is the only zone this libSystem has.

CreateInstance then CFRetain(realAllocator) when
_CFAllocatorIsSystemDefault is false. On this guest the TSD default is a
Linux heap pointer, not the static __kCFAllocatorSystemDefault, so retain
walks a raw malloc block and SIGSEGVs in __CFNonObjCRetain. Force the
system-default identity:

  3. _CFAllocatorIsSystemDefault always true (never prefix-store/retain).
  4. __CFGetDefaultAllocator always kCFAllocatorSystemDefault (ignore TSD).

Does not rewrite:
  * CFAllocatorCustom* zone vtable (allocator used as a zone).
  * CFRuntime.c malloc_zone_memalign(malloc_default_zone(), ...) — default
    zone is legal on this libSystem.

The pin checkout is not mutated. Callers copy Sources/CoreFoundation first.
A directory argument requires include/CFRuntime.h and
internalInclude/CFInternal.h (named CANNOT via SystemExit if absent).
"""
from __future__ import annotations

import pathlib
import sys

SIG_ALLOCATE = "static void *__CFAllocatorSystemAllocate(CFIndex size, CFOptionFlags hint, void *info)"
SIG_REALLOCATE = "static void *__CFAllocatorSystemReallocate(void *ptr, CFIndex newsize, CFOptionFlags hint, void *info)"
SIG_DEALLOCATE = "static void __CFAllocatorSystemDeallocate(void *ptr, void *info)"
SIG_IS_SYSTEM_DEFAULT = (
    "CF_INLINE Boolean _CFAllocatorIsSystemDefault(CFAllocatorRef allocator)"
)
SIG_GET_DEFAULT = "CF_INLINE CFAllocatorRef __CFGetDefaultAllocator(void)"

PORTABLE_ALLOCATE = """static void *__CFAllocatorSystemAllocate(CFIndex size, CFOptionFlags hint, void *info) {
    (void)info;
    if (hint == _CFAllocatorHintZeroWhenAllocating) {
        return calloc(1, size);
    } else {
        return malloc(size);
    }
}"""

PORTABLE_REALLOCATE = """static void *__CFAllocatorSystemReallocate(void *ptr, CFIndex newsize, CFOptionFlags hint, void *info) {
    (void)hint;
    (void)info;
    return realloc(ptr, newsize);
}"""

PORTABLE_DEALLOCATE = """static void __CFAllocatorSystemDeallocate(void *ptr, void *info) {
    (void)info;
    free(ptr);
}"""

REPL_IS_SYSTEM_DEFAULT = """CF_INLINE Boolean _CFAllocatorIsSystemDefault(CFAllocatorRef allocator) {
    (void)allocator;
    /* openuikit-x86: never prefix-store a custom allocator */
    return true;
}"""

REPL_GET_DEFAULT = """CF_INLINE CFAllocatorRef __CFGetDefaultAllocator(void) {
    /* openuikit-x86: static system default only */
    return kCFAllocatorSystemDefault;
}"""

ZONE_AS_ALLOCATOR = (
    (
        "malloc_zone_malloc((malloc_zone_t *)allocator, size)",
        "malloc(size)",
    ),
    (
        "malloc_zone_malloc((malloc_zone_t *)allocator, newsize)",
        "malloc(newsize)",
    ),
    (
        "malloc_zone_realloc((malloc_zone_t *)allocator, ptr, newsize)",
        "realloc(ptr, newsize)",
    ),
    (
        "malloc_zone_free((malloc_zone_t *)allocator, ptr)",
        "free(ptr)",
    ),
)

MARKER_IS_SYSTEM_DEFAULT = "openuikit-x86: never prefix-store a custom allocator"
MARKER_GET_DEFAULT = "openuikit-x86: static system default only"


def _cfbase_path(arg: str) -> pathlib.Path:
    p = pathlib.Path(arg)
    if p.is_dir():
        return p / "CFBase.c"
    return p


def _function_span(text: str, signature: str, start: int = 0) -> tuple[int, int]:
    pos = text.find(signature, start)
    if pos < 0:
        raise SystemExit(
            f"patch_cf_system_allocator: missing {signature} "
            "(pin changed; will not invent a CF allocator)"
        )
    brace = text.find("{", pos)
    if brace < 0:
        raise SystemExit(
            f"patch_cf_system_allocator: {signature} has no opening brace"
        )
    depth = 0
    i = brace
    while i < len(text):
        c = text[i]
        if c == "{":
            depth += 1
        elif c == "}":
            depth -= 1
            if depth == 0:
                return pos, i + 1
        i += 1
    raise SystemExit(
        f"patch_cf_system_allocator: {signature} is unclosed"
    )


def _first_body(text: str, signature: str) -> str:
    start, end = _function_span(text, signature)
    return text[start:end]


def already_patched(text: str) -> bool:
    try:
        body = _first_body(text, SIG_ALLOCATE)
    except SystemExit:
        return False
    if "malloc_zone_malloc" in body or "malloc(" not in body:
        return False
    return "malloc_zone_malloc((malloc_zone_t *)allocator" not in text


def already_patched_is_system_default(text: str) -> bool:
    try:
        body = _first_body(text, SIG_IS_SYSTEM_DEFAULT)
    except SystemExit:
        return False
    return MARKER_IS_SYSTEM_DEFAULT in body


def already_patched_get_default(text: str) -> bool:
    try:
        body = _first_body(text, SIG_GET_DEFAULT)
    except SystemExit:
        return False
    return MARKER_GET_DEFAULT in body


def patch_text(text: str) -> str:
    if already_patched(text):
        return text
    body = _first_body(text, SIG_ALLOCATE)
    if "malloc_zone_malloc" not in body:
        raise SystemExit(
            "patch_cf_system_allocator: first __CFAllocatorSystemAllocate "
            "does not call malloc_zone_malloc and is not the portable malloc "
            "body (pin changed; will not invent a CF allocator)"
        )
    replacements = (
        (SIG_ALLOCATE, PORTABLE_ALLOCATE),
        (SIG_REALLOCATE, PORTABLE_REALLOCATE),
        (SIG_DEALLOCATE, PORTABLE_DEALLOCATE),
    )
    out = text
    for signature, replacement in replacements:
        start, end = _function_span(out, signature)
        out = out[:start] + replacement + out[end:]
    n = 0
    for old, new in ZONE_AS_ALLOCATOR:
        c = out.count(old)
        if c:
            out = out.replace(old, new)
            n += c
    if n < 1:
        raise SystemExit(
            "patch_cf_system_allocator: no allocator-as-zone malloc_zone_* "
            "calls (pin changed; will not invent a CF allocator)"
        )
    first = _first_body(out, SIG_ALLOCATE)
    if "malloc_zone_malloc" in first:
        raise SystemExit(
            "patch_cf_system_allocator: Mac system-allocator rewrite did not stick"
        )
    if "malloc_zone_malloc((malloc_zone_t *)allocator" in out:
        raise SystemExit(
            "patch_cf_system_allocator: allocator-as-zone malloc_zone_malloc remains"
        )
    return out


def patch_is_system_default(text: str) -> str:
    if already_patched_is_system_default(text):
        return text
    body = _first_body(text, SIG_IS_SYSTEM_DEFAULT)
    if "return false" not in body or "CFAllocatorGetDefault" not in body:
        raise SystemExit(
            "patch_cf_system_allocator: _CFAllocatorIsSystemDefault is not "
            "the pin's pointer-identity predicate (pin changed; will not "
            "invent a CF allocator)"
        )
    start, end = _function_span(text, SIG_IS_SYSTEM_DEFAULT)
    return text[:start] + REPL_IS_SYSTEM_DEFAULT + text[end:]


def patch_get_default_allocator(text: str) -> str:
    if already_patched_get_default(text):
        return text
    body = _first_body(text, SIG_GET_DEFAULT)
    if "_CFGetTSD(__CFTSDKeyAllocator)" not in body:
        raise SystemExit(
            "patch_cf_system_allocator: __CFGetDefaultAllocator does not "
            "read __CFTSDKeyAllocator (pin changed; will not invent a CF "
            "allocator)"
        )
    start, end = _function_span(text, SIG_GET_DEFAULT)
    return text[:start] + REPL_GET_DEFAULT + text[end:]


def _write_if_changed(path: pathlib.Path, original: str, updated: str, what: str) -> None:
    if updated != original:
        path.write_text(updated, encoding="utf-8")
        print(f"patched {path} ({what})", file=sys.stderr)
    else:
        print(f"already patched {path}", file=sys.stderr)


def main(argv: list[str]) -> int:
    if len(argv) != 2:
        print(
            "usage: patch_cf_system_allocator.py <CoreFoundation-dir-or-CFBase.c>",
            file=sys.stderr,
        )
        return 2
    arg = pathlib.Path(argv[1])
    require_headers = arg.is_dir()
    path = _cfbase_path(argv[1])
    if not path.is_file():
        print(f"patch_cf_system_allocator: missing {path}", file=sys.stderr)
        return 2
    root = path.parent if path.name == "CFBase.c" else arg
    runtime = root / "include" / "CFRuntime.h"
    internal = root / "internalInclude" / "CFInternal.h"
    if require_headers:
        if not runtime.is_file():
            print(
                f"patch_cf_system_allocator: missing {runtime} "
                "(pin changed; will not invent a CF allocator)",
                file=sys.stderr,
            )
            return 2
        if not internal.is_file():
            print(
                f"patch_cf_system_allocator: missing {internal} "
                "(pin changed; will not invent a CF allocator)",
                file=sys.stderr,
            )
            return 2

    original = path.read_text(encoding="utf-8")
    _write_if_changed(
        path,
        original,
        patch_text(original),
        "__CFAllocatorSystem* and allocator-as-zone -> malloc/free",
    )

    if runtime.is_file():
        rt = runtime.read_text(encoding="utf-8")
        _write_if_changed(
            runtime,
            rt,
            patch_is_system_default(rt),
            "_CFAllocatorIsSystemDefault always true",
        )
    if internal.is_file():
        inn = internal.read_text(encoding="utf-8")
        _write_if_changed(
            internal,
            inn,
            patch_get_default_allocator(inn),
            "__CFGetDefaultAllocator always kCFAllocatorSystemDefault",
        )
    return 0


if __name__ == "__main__":
    raise SystemExit(main(sys.argv))
