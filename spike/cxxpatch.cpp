// cxxpatch.cpp -- the 5 libc++ symbols the iOS-simulator libswiftCore.dylib
// imports that machorun's curated /usr/lib/libc++.1.dylib does not export.
//
// This compiles to an UMBRELLA libc++.1.dylib: it defines these 5 and
// LC_REEXPORT_DYLIBs machorun's real libc++ (staged as /usr/lib/libc++.real.dylib)
// for the other ~83. machorun searches a bound image's re-export deps
// (src/resolve.c), so a two-level import "X from libc++.1.dylib" resolves in
// whichever half actually has X. Nothing here reimplements libc++: the one
// symbol with real behaviour that libc++ owns (operator+) is produced by an
// explicit template instantiation from the SAME LLVM-18 headers, i.e. libc++'s
// own code, and the machorun half supplies its out-of-line callees.
//
// Measured missing set (dyld_info -imports libswiftCore | comm against machorun
// libc++ exports):
//   __ZNSt3__122__libcpp_verbose_abortEPKcz          hardening abort
//   ___cxa_demangle                                  name demangler
//   ___gxx_personality_v0                            EH personality
//   __ZNSt3__16thread20hardware_concurrencyEv         CPU count
//   __ZNSt3__1plIcNS_...EPKS6_RKS9_                    operator+(const char*, string)
// The first three sit on abort/exception/reflection paths a bitmap draw never
// reaches, so loud stubs are correct. The last two can genuinely be called, so
// they have real behaviour.

#include <string>
#include <unistd.h>
#include <stdio.h>
#include <stdlib.h>
#include <stdarg.h>

// ---- real behaviour ----

// std::__1::thread::hardware_concurrency()
extern "C" unsigned int
mr_hw_concurrency(void) asm("__ZNSt3__16thread20hardware_concurrencyEv");
extern "C" unsigned int mr_hw_concurrency(void) {
    long n = sysconf(_SC_NPROCESSORS_ONLN);
    return n > 0 ? (unsigned int)n : 1u;
}

// std::__1::operator+(const char*, const std::__1::string&) -- libc++'s own code
template std::__1::string
std::__1::operator+<char, std::__1::char_traits<char>, std::__1::allocator<char> >(
    const char*, const std::__1::string&);

// ---- loud stubs (bind must succeed; never entered on the drawing path) ----

extern "C" void
mr_verbose_abort(const char* fmt, ...) asm("__ZNSt3__122__libcpp_verbose_abortEPKcz");
extern "C" void mr_verbose_abort(const char* fmt, ...) {
    va_list ap; va_start(ap, fmt);
    vfprintf(stderr, fmt, ap);
    va_end(ap);
    fprintf(stderr, "\ncxxpatch: libc++ __libcpp_verbose_abort reached\n");
    abort();
}

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
