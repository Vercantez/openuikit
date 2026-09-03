// cxxpatch.cpp -- the libc++ symbols the iOS-simulator libswiftCore.dylib
// imports that machorun's /usr/lib/libc++.1.dylib does not export.
//
// This compiles to an UMBRELLA libc++.1.dylib: it defines these and
// LC_REEXPORT_DYLIBs machorun's real libc++ (staged as /usr/lib/libc++.real.dylib)
// for the rest. machorun searches a bound image's re-export deps
// (src/resolve.c), so a two-level import "X from libc++.1.dylib" resolves in
// whichever half actually has X.
//
// Three symbols MOVED into machorun's libc++ (darwin/src/libcxx_std.cpp) and
// MUST NOT be redefined here -- a definition in the umbrella beats .real:
//   __ZNSt3__122__libcpp_verbose_abortEPKcz
//   __ZNSt3__16thread20hardware_concurrencyEv
//   operator+(const char*, const string&)  (extern template)
//
// Remaining (abort/EH paths a bitmap draw never reaches; loud stubs):
//   ___cxa_demangle
//   ___gxx_personality_v0

#include <stdio.h>
#include <stdlib.h>
#include <stddef.h>

extern "C" char*
mr_cxa_demangle(const char*, char*, size_t*, int* status) asm("___cxa_demangle");
extern "C" char* mr_cxa_demangle(const char*, char*, size_t*, int* status) {
    if (status) *status = -1;   // -1 = "a memory allocation failure occurred"
    return 0;                    // contract: NULL means not demangled
}

extern "C" int mr_personality(void) asm("___gxx_personality_v0");
extern "C" int mr_personality(void) {
    fprintf(stderr, "cxxpatch: __gxx_personality_v0 reached (C++ exception unwind)\n");
    abort();
}
