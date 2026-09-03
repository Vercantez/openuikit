/*
 * math_decl_probe.c -- every math name must be DECLARED, in all three
 * precisions, under -Werror=implicit-function-declaration.
 *
 * This exists because of a bug that was invisible for the life of the header.
 * sdk/local/math.h generates the float and long-double forms by token pasting:
 *
 *     #define __MR_MATH1(f) ... extern float f##f(float) ...
 *
 * Both operands of `##` are the parameter, because the parameter was named
 * `f`. Substitution happens on each side, so __MR_MATH1(cos) declared `coscos`
 * and never `cosf` -- for all 42 single-precision names at once.
 *
 * Nothing caught it, and could not have:
 *
 *   - the bogus names collide with nothing, so the header compiles clean;
 *   - libSystem's own math.c is correct (its macro parameter is `name`, so
 *     `name##f` pastes against a literal), so the SYMBOLS all exist -- the
 *     implementations were there the whole time, only unreachable by name;
 *   - a C caller of cosf() gets "implicit declaration" pointing at its own
 *     line, not at the macro;
 *   - and a C++ caller does not even get that. libc++'s <cmath> imports these
 *     with `using ::cosf _LIBCPP_USING_IF_EXISTS`, which is *designed* to stay
 *     silent when the name is absent, so the failure re-emerges far away --
 *     measured, inside <complex>, as "reference to unresolved using
 *     declaration".
 *
 * So the check has to be a compile of the real names. Declared-ness is the
 * property; there is nothing to print and nothing to diff.
 *
 * The long-double half tests the opposite failure. Those names WERE declared
 * correctly (`fn##l` pastes against a literal `l`) and were implemented
 * nowhere -- an unbacked promise, the same class as a .tbd advertising a
 * symbol nothing defines. They are real now, and they forward to glibc's
 * DOUBLE entry points on purpose: long double is 8 bytes on arm64-apple-macos
 * and 16 on aarch64 glibc, so forwarding l-to-l would pass half the expected
 * width. See darwin/src/math.c.
 *
 * Build (both sides; see scripts/sdk_abi_probe.sh):
 *   clang -target arm64-apple-macos11 -isysroot sdk \
 *         -Werror=implicit-function-declaration -fsyntax-only \
 *         sdk/tests/math_decl_probe.c
 */

#include <math.h>

/* One-argument, all three precisions. */
#define MR_PROBE1(fn) \
    double  probe_##fn##_d(double x)           { return fn(x); }        \
    float   probe_##fn##_f(float x)            { return fn##f(x); }     \
    long double probe_##fn##_l(long double x)  { return fn##l(x); }

/* Two-argument, all three precisions. */
#define MR_PROBE2(fn) \
    double  probe2_##fn##_d(double x, double y)          { return fn(x, y); }    \
    float   probe2_##fn##_f(float x, float y)            { return fn##f(x, y); } \
    long double probe2_##fn##_l(long double x, long double y) { return fn##l(x, y); }

MR_PROBE1(acos)   MR_PROBE1(asin)   MR_PROBE1(atan)
MR_PROBE1(cos)    MR_PROBE1(sin)    MR_PROBE1(tan)
MR_PROBE1(acosh)  MR_PROBE1(asinh)  MR_PROBE1(atanh)
MR_PROBE1(cosh)   MR_PROBE1(sinh)   MR_PROBE1(tanh)
MR_PROBE1(exp)    MR_PROBE1(exp2)   MR_PROBE1(expm1)
MR_PROBE1(log)    MR_PROBE1(log10)  MR_PROBE1(log1p)
MR_PROBE1(log2)   MR_PROBE1(logb)   MR_PROBE1(cbrt)
MR_PROBE1(fabs)   MR_PROBE1(sqrt)   MR_PROBE1(erf)
MR_PROBE1(erfc)   MR_PROBE1(lgamma) MR_PROBE1(tgamma)
MR_PROBE1(ceil)   MR_PROBE1(floor)  MR_PROBE1(nearbyint)
MR_PROBE1(rint)   MR_PROBE1(round)  MR_PROBE1(trunc)

MR_PROBE2(atan2)  MR_PROBE2(hypot)  MR_PROBE2(pow)
MR_PROBE2(fmod)   MR_PROBE2(remainder) MR_PROBE2(copysign)
MR_PROBE2(nextafter) MR_PROBE2(fdim) MR_PROBE2(fmax) MR_PROBE2(fmin)

/* The mixed-signature ones, which the macros above do not cover. */
float       probe_ldexpf(float x, int e)      { return ldexpf(x, e); }
long double probe_ldexpl(long double x, int e){ return ldexpl(x, e); }
float       probe_frexpf(float x, int *e)     { return frexpf(x, e); }
long double probe_frexpl(long double x, int *e){ return frexpl(x, e); }
float       probe_modff(float x, float *i)    { return modff(x, i); }
long double probe_modfl(long double x, long double *i) { return modfl(x, i); }
float       probe_fmaf(float x, float y, float z) { return fmaf(x, y, z); }
long double probe_fmal(long double x, long double y, long double z) { return fmal(x, y, z); }

/* The property the l-forwarders rest on. If Darwin's long double ever stops
 * being a double, darwin/src/math.c is passing the wrong width to glibc. */
#if defined(__x86_64__)
_Static_assert(sizeof(long double) == 16,
               "x86_64-apple-macos long double must be 16 bytes");
#else
_Static_assert(sizeof(long double) == sizeof(double),
               "arm64-apple-macos long double must be 8 bytes");
#endif
