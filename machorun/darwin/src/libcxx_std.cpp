// libcxx_std.cpp -- the out-of-line half of libc++ that a C++ guest leaves
// undefined, for /usr/lib/libc++.1.dylib.
//
// READ darwin/src/libcxx.c FIRST. That file is the operator new/delete family
// and the __cxa_guard_* trio, written in C, and its header says honestly that
// it is not libc++. This file is the next rung, and it exists because
// vendor/quartz reached past that rung: 12 symbols that the LLVM 18 headers
// DECLARE but deliberately do not define inline.
//
//   9  std::__1::basic_string<char> members     append/assign/resize/push_back/
//                                               operator=/the (str,pos,n,alloc) ctor
//   1  std::__1::__sort<__less<double>&, double*>
//   2  std::__1::to_string(int) and (unsigned long)
//   1  std::__1::__next_prime(size_t)
//
// They are out of line because libc++'s headers carry `extern template`
// declarations for them (string:2129 `_LIBCPP_DECLARE`, __algorithm/sort.h:916,
// __hash_table:75) so that every translation unit shares one copy in the
// shipping dylib. On Linux that dylib is an ELF and cannot be linked into a
// Mach-O guest, so the copy has to come from here.
//
// HOW THIS AVOIDS BEING A REIMPLEMENTATION. Nine of the twelve are not written
// out at all: `template class std::basic_string<char>;` below is an explicit
// instantiation DEFINITION, which overrides the header's extern-template
// declaration and makes the compiler emit LLVM 18's own code from LLVM 18's own
// headers. Same for __sort. That is exactly what libc++'s src/string.cpp and
// src/algorithm.cpp do, and it is why those nine cannot silently drift from the
// header set they are compiled against.
//
// The three that ARE written out are the ones whose definitions live in a .cpp
// Ubuntu's libc++-18-dev does not ship (src/string.cpp, src/hash.cpp), so:
//
//   to_string      decimal formatting of an integer. Exact by definition;
//                  there is one right answer and no room to differ.
//   __next_prime   CONTRACT: the smallest prime >= n. libc++'s version reaches
//                  it with a 210-wheel and a table of small primes, purely as
//                  an optimisation; the RESULT is identical to trial division,
//                  which is what is here. This matters more than it looks:
//                  __next_prime picks unordered_map's bucket count, so a
//                  different answer would give a different iteration order
//                  than the same program gets on macOS. Same answer, same
//                  order. (Bucket count is still not observable in quartz --
//                  its five unordered_maps are keyed on heap pointers and are
//                  never iterated -- but relying on that would be luck.)
//
// Compiled -fno-exceptions -fno-rtti on purpose, matching how quartz is built
// (scripts/build_quartz.sh says why): machorun has no unwinder over Apple's
// compact __unwind_info yet -- docs/UNIMPLEMENTED.md#unwind-compact -- so an
// exception cannot be delivered. With -fno-exceptions libc++'s throw sites
// become _LIBCPP_VERBOSE_ABORT, which is a loud abort and not a silent wrong
// answer. -fno-rtti keeps std::type_info out, which would otherwise pull
// __cxxabiv1::__si_class_type_info's vtable in from a libc++abi we do not have.

#include <string>
#include <algorithm>
#include <unordered_map>
#include <cstdarg>
#include <cstdio>
#include <cstdlib>
#include <thread>
#include <unistd.h>

// ---------------------------------------------------------------------------
// Explicit instantiation definitions. No code of ours: LLVM 18's, emitted here.
// ---------------------------------------------------------------------------
template class std::basic_string<char>;

// __sort is the one where the header stops at a DECLARATION (sort.h:891) --
// libc++ puts the one-line body in src/algorithm.cpp so the specialisations
// below are the only copies in the shipping dylib.
//
// THIS USED TO FORWARD TO __sort_dispatch AND RECURSED FOREVER. The reasoning
// for doing so was sound and the LOWERING is what bit, which is the third time
// this project has met that shape (see __exp10). sort.h:960 declares
//
//     template <class _AlgPolicy, class _Type, __enable_if_t<
//               __sort_is_specialized_in_library<_Type>::value, int> = 0>
//     void __sort_dispatch(_Type* __first, _Type* __last, __less<>&) {
//       __less<_Type> __comp;
//       std::__sort<__less<_Type>&, _Type*>(__first, __last, __comp);
//     }
//
// -- so for exactly the arithmetic types instantiated below, handing
// __sort_dispatch a transparent __less<> routes it straight back into the
// specialisation being defined. All five compiled to an unconditional
// self-call with no base case:
//
//     __ZNSt3__16__sortIRNS_6__lessIddEEPdEEvT0_S5_T_:
//       2608  bl  __ZNSt3__16__sortIRNS_6__lessIddEEPdEEvT0_S5_T_   <- itself
//
// Any guest std::sorting a double, float, int, long or unsigned long array
// through this libc++ recursed until the stack died -- and a stack-overflow
// SIGSEGV leaves the crash handler no stack to run on, so machorun printed
// nothing at all. Found by existential-fix; the reproducer is a ~50-line C
// program that renders a gradient layer, dying 3/3 here and exiting 0 on macOS.
//
// THE FIX CALLS THE ALGORITHM RATHER THAN ANOTHER DISPATCHER, because
// re-forwarding is what recursed. std::__introsort is what __sort_dispatch's
// GENERIC overload (sort.h:922) invokes once it has finished dispatching, so
// this is the same code libc++ runs for a type with no specialisation -- the
// property the old comment wanted -- reached without the step that turns back.
// It terminates by construction: introsort's own base cases are insertion sort
// below a length threshold and heapsort at the depth limit, and the explicit
// n < 2 return below makes the smallest case obvious rather than implied.
_LIBCPP_BEGIN_NAMESPACE_STD
// The comparator parameter is DELIBERATELY unused. __less<T,T> is an empty
// struct with no operator() -- comp.h:33 says so in as many words: "The
// definition is required because __less is part of the ABI, but it's empty
// because all comparisons should be transparent." The only transparent
// specialisation, __less<void,void>, is the one that actually compares, and it
// is stateless, so substituting it is not an approximation: it is what the
// caller meant by naming __less<double> in the first place.
template <class _Comp, class _RandomAccessIterator>
void __sort(_RandomAccessIterator __first, _RandomAccessIterator __last, _Comp)
{
    typedef typename iterator_traits<_RandomAccessIterator>::difference_type _Diff;
    _Diff __n = __last - __first;
    if (__n < 2) return;                       // nothing to do, and a visible base case

    __less<> __transparent;
    // Identical to sort.h:922-931, which is the generic dispatch: the depth
    // limit past which introsort falls back to heapsort, and the branchless
    // partitioning flag it picks for arithmetic types.
    _Diff __depth_limit = 2 * std::__log2i(__n);
    std::__introsort<_ClassicAlgPolicy,
                     __less<>&,
                     _RandomAccessIterator,
                     __use_branchless_sort<__less<>&, _RandomAccessIterator>::value>(
        __first, __last, __transparent, __depth_limit);
}

template void __sort<__less<double>&, double*>(double*, double*, __less<double>&);
template void __sort<__less<float>&, float*>(float*, float*, __less<float>&);
template void __sort<__less<int>&, int*>(int*, int*, __less<int>&);
template void __sort<__less<long>&, long*>(long*, long*, __less<long>&);
template void __sort<__less<unsigned long>&, unsigned long*>(unsigned long*, unsigned long*, __less<unsigned long>&);
_LIBCPP_END_NAMESPACE_STD

// ---------------------------------------------------------------------------
// The three that have to be written.
// ---------------------------------------------------------------------------
_LIBCPP_BEGIN_NAMESPACE_STD

// Smallest prime >= n. See the header comment for why "any prime" is not good
// enough and why trial division is nevertheless the right implementation.
size_t __next_prime(size_t n)
{
    // libc++'s table starts at 0, so __next_prime(0) is 0 and __next_prime(1)
    // is 2. Reproduced rather than tidied: it is the observable behaviour.
    if (n <= 1) return n == 0 ? 0u : 2u;
    if (n <= 2) return 2;
    if ((n & 1) == 0) ++n;
    for (;; n += 2) {
        if (n % 3 == 0) continue;
        bool prime = true;
        // 6k+/-1 wheel. n is odd and not a multiple of 3 here.
        for (size_t d = 5; d * d <= n; d += 6) {
            if (n % d == 0 || n % (d + 2) == 0) { prime = false; break; }
        }
        if (prime) return n;
    }
}

// Decimal formatting. 20 digits is enough for 2^64-1; 21 with the sign.
template <class _Unsigned>
static char *mr_utoa(char *end, _Unsigned v)
{
    do { *--end = static_cast<char>('0' + (v % 10)); v /= 10; } while (v);
    return end;
}

string to_string(int v)
{
    char buf[24];
    char *end = buf + sizeof(buf);
    unsigned u = v < 0 ? 0u - static_cast<unsigned>(v) : static_cast<unsigned>(v);
    char *p = mr_utoa(end, u);
    if (v < 0) *--p = '-';
    return string(p, static_cast<size_t>(end - p));
}

string to_string(unsigned v)
{
    char buf[24];
    char *end = buf + sizeof(buf);
    char *p = mr_utoa(end, v);
    return string(p, static_cast<size_t>(end - p));
}

string to_string(long v)
{
    char buf[24];
    char *end = buf + sizeof(buf);
    unsigned long u = v < 0 ? 0ul - static_cast<unsigned long>(v) : static_cast<unsigned long>(v);
    char *p = mr_utoa(end, u);
    if (v < 0) *--p = '-';
    return string(p, static_cast<size_t>(end - p));
}

string to_string(unsigned long v)
{
    char buf[24];
    char *end = buf + sizeof(buf);
    char *p = mr_utoa(end, v);
    return string(p, static_cast<size_t>(end - p));
}

string to_string(long long v)
{
    char buf[24];
    char *end = buf + sizeof(buf);
    unsigned long long u = v < 0 ? 0ull - static_cast<unsigned long long>(v)
                                 : static_cast<unsigned long long>(v);
    char *p = mr_utoa(end, u);
    if (v < 0) *--p = '-';
    return string(p, static_cast<size_t>(end - p));
}

string to_string(unsigned long long v)
{
    char buf[24];
    char *end = buf + sizeof(buf);
    char *p = mr_utoa(end, v);
    return string(p, static_cast<size_t>(end - p));
}

_LIBCPP_END_NAMESPACE_STD

// ---------------------------------------------------------------------------
// Overlay NOUNDEFS. Apple's libc++.tbd exports these three; this dylib did
// not, because:
//
//   __libcpp_verbose_abort
//       build_darwin.sh compiled this TU with
//       -D_LIBCPP_VERBOSE_ABORT(...)=__builtin_trap(), so the handler was
//       never a symbol. The trap define stays on objc4 TUs (compile-time);
//       the dylib must export the function Swift's .o files import.
//
//   thread::hardware_concurrency
//       declaration-only in LLVM 18 <thread>; the body lives in src/thread.cpp
//       which is not in the vendored libcxx sources. _LIBCPP_HAS_NO_THREADS
//       is not set -- the function was simply never instantiated.
//
//   operator+(const char*, const string&)
//       a separate `extern template` from `template class basic_string<char>`
//       (string:688). Instantiating the class does not emit this overload.
//
// A definition here means the full/ cxxpatch umbrella must NOT also define
// them -- a definition in the umbrella beats libc++.real.
// ---------------------------------------------------------------------------

_LIBCPP_BEGIN_NAMESPACE_STD

_LIBCPP_NORETURN void __libcpp_verbose_abort(const char* format, ...)
{
    std::va_list ap;
    va_start(ap, format);
    std::vfprintf(stderr, format, ap);
    va_end(ap);
    std::fprintf(stderr, "\nlibc++: __libcpp_verbose_abort reached\n");
    std::abort();
}

unsigned thread::hardware_concurrency() _NOEXCEPT
{
    long n = ::sysconf(_SC_NPROCESSORS_ONLN);
    return n > 0 ? static_cast<unsigned>(n) : 1u;
}

_LIBCPP_END_NAMESPACE_STD

template std::__1::string
std::__1::operator+<char, std::__1::char_traits<char>, std::__1::allocator<char> >(
    const char*, const std::__1::string&);
