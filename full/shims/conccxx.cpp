// conccxx.cpp -- the two symbols libswift_Concurrency binds against LIBC++.
//
// dyld_info -fixups says so explicitly: __cxa_pure_virtual comes from libc++,
// and operator new(size_t, __type_descriptor_t) is a weak-def-coalesce import.
// These binaries use two-level namespace binding, so putting either in the
// libSystem umbrella would leave it invisible -- machorun says as much:
//     undefined symbol '___cxa_pure_virtual'
//       wanted by: libswift_Concurrency.dylib
//       looked in: libc++.1.dylib
// Companion to full/shims/concpatch.c, which holds the 20 libSystem-owned ones.

#include <cstddef>
#include <cstdlib>

extern "C" {
long write(int, const void *, unsigned long);

// Calling a pure virtual IS a bug. Aborting loudly is the CORRECT
// implementation of this symbol, not a stub standing in for one.
__attribute__((noreturn)) void __cxa_pure_virtual(void)
{
    static const char msg[] = "conccxx: pure virtual function called\n";
    write(2, msg, sizeof(msg) - 1);
    abort();
}

// libc++'s typed-allocation overload of operator new. The type descriptor is a
// hint for typed allocators, which we do not have, so malloc IS a complete and
// correct implementation -- this one is real, not a stub.
void *conc_typed_new(std::size_t n, unsigned long long td) asm("__ZnwmSt19__type_descriptor_t");
void *conc_typed_new(std::size_t n, unsigned long long td)
{
    (void)td;
    void *p = std::malloc(n ? n : 1);
    if (!p) {
        static const char msg[] = "conccxx: operator new out of memory\n";
        write(2, msg, sizeof(msg) - 1);
        abort();
    }
    return p;
}
} // extern "C"
