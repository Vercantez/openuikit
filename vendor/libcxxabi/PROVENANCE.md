# vendor/libcxxabi — provenance

LLVM's libc++abi, **pristine**, at tag `llvmorg-18.1.8`, from
`https://github.com/llvm/llvm-project`, sparse checkout of `libcxxabi/`.
`vendor/libcxx` is `libcxx/src` from the same tree, at the same tag.

**Zero patches, and there is no `patches-libcxxabi/`.** Every file compiled
against machorun's own `sdk/` on the first attempt. If a patch ever becomes
necessary, create the directory and apply it to a copy at build time, as
`scripts/build_quartz.sh` does, so "how many patches?" stays a number.

## Four traps, three of them handed over rather than rediscovered

foundation-scope built this on a machine that no longer exists and passed on
the three that cost real time. They are recorded here because each one *looks*
like an obvious improvement:

1. **Do NOT pass `-fno-rtti`.** It breaks 22 files — `private_typeinfo.cpp`
   uses `dynamic_cast` against its own type-info hierarchy. It reads like a
   free size win.
2. **Do NOT put `libcxx/include` on the include path.** It shadows the
   sysroot's libc++ headers and yields a `_LIBCPP_VERSION` mismatch against
   everything else in the tree. `libcxx/src` — which IS needed, for
   `"include/atomic_support.h"` and `"include/refstring.h"` — is a different
   directory and carries no public headers, so it cannot shadow anything.
3. **Do NOT shim `div_t`/`ldiv_t`.** The sysroot has them, in `<_stdlib.h>`
   rather than `<stdlib.h>`. The general form is worth more than the instance:
   **Darwin splits declarations into `_`-prefixed headers, so grep the header
   that DEFINES a name, not the one named after it** — otherwise an empty
   result reads as "absent" when it means "you looked in the wrong file".

The fourth was found here: **`-DLIBCXX_BUILDING_LIBCXXABI` is not optional**,
and the linker says so. Without it `libcxx/src/exception.cpp` takes its fallback
path and defines `std::terminate`, which `cxa_handlers.cpp` already defines —
`ld64.lld: error: duplicate symbol: __ZSt9terminatev`. With it, `<cxxabi.h>`
supplies `_LIBCPPABI_VERSION`, libc++ delegates `terminate` and the exception
pointer to libc++abi, and the two libraries split where they are meant to. The
same switch is why `stdexcept_default.ipp` omits the `~runtime_error()` family:
libc++abi's `stdlib_stdexcept.cpp` owns them.

## What is built, and what is not

17 files, listed in `scripts/build_darwin.sh`. Excluded, each for a named
reason and none of them "it did not build":

    cxa_noexception.cpp    only compiled when the library is built WITHOUT
                           exceptions, which is the opposite of the point
    cxa_thread_atexit.cpp  needs __cxa_thread_atexit_impl; see
                           docs/UNIMPLEMENTED.md#tlv-thread-atexit
    aix_state_tab_eh.inc   AIX

`cxa_demangle.cpp` IS built, and the reason is worth recording: it was excluded
first on the grounds that "nothing in the corpus calls `__cxa_demangle`". That
was wrong and the `.tbd` drift check said so immediately — **libc++abi calls it
itself**, from the terminate handler that prints the type of an uncaught
exception. A stub returning NULL would have "worked" (libc++abi falls back to
the mangled name) and quietly diverged from macOS on exactly the path a
crashing guest takes.

## Where it lives, and why that is not where it started

`/usr/lib/libc++abi.dylib`, re-exported by `libc++.1.dylib`, with
`libobjc.A.dylib` linking against it — Darwin's arrangement, verified against
Apple's shipped `libswiftCore` with `nm -m` (`___gxx_personality_v0` is *from
libc++*; `__Unwind_Resume` is *from libSystem*). The first attempt put it inside
libSystem and failed for C++ guests; the full account is in
`docs/UNIMPLEMENTED.md#unwind-compact` and `darwin/src/objcsupport.c`.
