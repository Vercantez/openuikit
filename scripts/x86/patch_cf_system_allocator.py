#!/usr/bin/env python3
"""Rewrite TARGET_OS_MAC CF system-allocator callbacks to malloc/free.

Usage:
    python3 scripts/x86/patch_cf_system_allocator.py <CoreFoundation-dir-or-CFBase.c>

machorun libSystem has exactly one malloc zone (the default). Apple's
TARGET_OS_MAC __CFAllocatorSystemAllocate passes allocator->_context.info as
the zone; that pointer is not the default zone, so malloc_zone_malloc aborts
(guest exit 71 in __CFRuntimeCreateInstance). The portable #else branch in
the same file already uses malloc/calloc/realloc/free. Apply that body to the
Mac callbacks only.

Does not rewrite:
  * CFAllocator-as-zone dispatch (malloc_zone_* when the allocator ISA is a
    zone) — those keep zone vtable calls.
  * CFRuntime.c malloc_zone_memalign(malloc_default_zone(), ...) — default
    zone is legal on this libSystem.

The pin checkout is not mutated. Callers copy Sources/CoreFoundation first.
"""
from __future__ import annotations

import pathlib
import sys

SIG_ALLOCATE = "static void *__CFAllocatorSystemAllocate(CFIndex size, CFOptionFlags hint, void *info)"
SIG_REALLOCATE = "static void *__CFAllocatorSystemReallocate(void *ptr, CFIndex newsize, CFOptionFlags hint, void *info)"
SIG_DEALLOCATE = "static void __CFAllocatorSystemDeallocate(void *ptr, void *info)"

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


def _cfbase_path(arg: str) -> pathlib.Path:
    p = pathlib.Path(arg)
    if p.is_dir():
        return p / "CFBase.c"
    return p


def _function_span(text: str, signature: str, start: int = 0) -> tuple[int, int]:
    pos = text.find(signature, start)
    if pos < 0:
        raise SystemExit(
            f"patch_cf_system_allocator: CFBase.c is missing {signature} "
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
    return "malloc_zone_malloc" not in body and "malloc(" in body


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
    first = _first_body(out, SIG_ALLOCATE)
    if "malloc_zone_malloc" in first:
        raise SystemExit(
            "patch_cf_system_allocator: Mac system-allocator rewrite did not stick"
        )
    if "malloc_zone_malloc" not in out:
        raise SystemExit(
            "patch_cf_system_allocator: zone-as-allocator malloc_zone_malloc "
            "vanished; refusing to drop CFAllocator-as-zone dispatch"
        )
    return out


def main(argv: list[str]) -> int:
    if len(argv) != 2:
        print(
            "usage: patch_cf_system_allocator.py <CoreFoundation-dir-or-CFBase.c>",
            file=sys.stderr,
        )
        return 2
    path = _cfbase_path(argv[1])
    if not path.is_file():
        print(f"patch_cf_system_allocator: missing {path}", file=sys.stderr)
        return 2
    original = path.read_text(encoding="utf-8")
    updated = patch_text(original)
    if updated != original:
        path.write_text(updated, encoding="utf-8")
        print(f"patched {path} (__CFAllocatorSystem* -> malloc/free)", file=sys.stderr)
    else:
        print(f"already patched {path}", file=sys.stderr)
    return 0


if __name__ == "__main__":
    raise SystemExit(main(sys.argv))
