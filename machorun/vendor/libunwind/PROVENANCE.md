# vendor/libunwind — provenance

LLVM's libunwind, **pristine**, at tag `llvmorg-18.1.8`, from
`https://github.com/llvm/llvm-project`, sparse checkout of `libunwind/`.

```
git clone --depth 1 --branch llvmorg-18.1.8 --filter=blob:none --sparse \
    https://github.com/llvm/llvm-project
git -C llvm-project sparse-checkout set libunwind
# vendor/libunwind/{src,include} are that tree's libunwind/{src,include}
# minus the two CMakeLists.txt.
```

**Zero patches, and there is no `patches-libunwind/`.** Unlike `vendor/objc4`
and `vendor/quartz`, this builds unmodified against machorun's own `sdk/` on the
first attempt — every file, no edits. That is worth stating plainly because it
is unusual for this project and because it means the compact-unwind reader in
`libSystem.B.dylib` is byte-for-byte the one Apple's toolchain ships rather than
an approximation of it. If a patch ever becomes necessary, create
`patches-libunwind/` and apply it to a copy at build time, exactly as
`scripts/build_quartz.sh` does, so "how many patches?" stays a number.

## Why LLVM's and not Apple's

Apple's `libunwind-201` distribution is already partly staged into `sdk/` —
`libunwind.h` and `__libunwind_config.h` come from it (see
`sdk/CHECKSUMS.sha256`). It is **not** the source used here, for two reasons.
It ships only those two headers and no `unwind.h` or
`mach-o/compact_unwind_encoding.h`, so it cannot supply what the build needs;
and it predates arm64. LLVM's libunwind is the same lineage — Apple upstreamed
it — and 18.1.8 matches the `clang 18.1.3` the test-bed compiles with, so the
C++ it is compiled from and the compiler compiling it agree.

The three headers staged into `sdk/usr/include` from this tree (`unwind.h`,
`unwind_itanium.h`, `mach-o/compact_unwind_encoding.h`) are recorded in
`sdk/MANIFEST.tsv` as coming from `vendor/libunwind/...`, and deliberately have
no rows in `sdk/CHECKSUMS.sha256`: that file describes files fetched from
upstream, and these live in this repository where git vouches for them.

## What is built, and what is not

`scripts/build_darwin.sh` compiles five files into `libSystem.B.dylib`:

    src/libunwind.cpp              the unw_* level-2 API and UnwindCursor
    src/UnwindLevel1.c             _Unwind_RaiseException and friends
    src/UnwindLevel1-gcc-ext.c     _Unwind_Backtrace, _Unwind_Resume_or_Rethrow
    src/UnwindRegistersRestore.S   register restore/save, hand-written arm64
    src/UnwindRegistersSave.S

The excluded files are **other architectures' unwinders, not gaps**:
`Unwind-EHABI.cpp` (ARM32), `Unwind-seh.cpp` (Windows), `Unwind-sjlj.c`
(setjmp/longjmp unwinding), `Unwind-wasm.c` and `Unwind_AIXExtras.cpp`. None is
reachable on `arm64-apple-macos`.

It is compiled INTO libSystem rather than shipped as a separate dylib because
that is the Darwin arrangement: on macOS `libunwind.dylib` is a sub-library of
the libSystem umbrella and libSystem re-exports it, so a guest that links
`-lSystem` already expects `_Unwind_*` to be there. A separate dylib would need
re-export chasing, which the loader does not implement.

## What it needs from us

Three things, all of which the link named precisely when they were missing:

* `pthread_rwlock_rdlock` / `_wrlock` / `_unlock` — around libunwind's DWARF FDE
  cache and its dynamic unwind-section registry. `darwin/src/libsystem.c`.
* `_dyld_find_unwind_sections` — libunwind decodes the section, only dyld knows
  where it is. `src/unwind.c`.
* `_dyld_register_func_for_remove_image` — an honest no-op; nothing here is ever
  unmapped, so the callback would have nothing to report.
