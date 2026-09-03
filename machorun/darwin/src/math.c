/* math.c -- the libm half of our /usr/lib/libSystem.B.dylib.
 *
 * On Darwin there is no separate -lm: libSystem.B.dylib re-exports
 * /usr/lib/system/libsystem_m.dylib, so a guest that calls cos() has an
 * undefined `_cos` against libSystem and nothing else. Ours has to answer it.
 *
 * WHAT THIS IS AND IS NOT. It is the same bet as the rest of libSystem: the
 * bytes go to glibc. It is NOT a claim that glibc's libm and Apple's Libm
 * agree bit-for-bit, and that claim would be false -- IEEE 754 pins +-*\/ and
 * sqrt exactly and says nothing at all about sin, cos, pow, exp or log, where
 * every implementation is free to be off by its own fraction of an ulp.
 *
 * That is precisely why the quartz fixture is a PIXEL diff against the same
 * binary on macOS rather than an eyeball: if a transcendental disagrees, a
 * rasteriser is the machine that turns the disagreement into something you can
 * see. docs/UNIMPLEMENTED.md#libm-ulp records the bound. Nothing here rounds,
 * clamps or "fixes up" a result -- a divergence must show, not be papered over.
 *
 * Not forwarded on purpose: sqrt, fabs, floor, ceil, round, trunc, rint,
 * nearbyint, copysign, fma, fmax, fmin and their float forms. clang lowers all
 * of those to a single arm64 instruction (fsqrt, fabs, frintm/p/a/z/x/i,
 * fcpysign, fmadd, fmaxnm/fminnm) for -ffp-contract=on targets, so a guest
 * built by Apple's clang has no call to make. Where a guest DOES emit a call
 * -- it can, with -fno-builtin -- the symbol is here too, so the surface is
 * complete rather than "complete for the compilers we have tried".
 *
 * Built with -nostdinc like every other file in darwin/src: the prototypes are
 * here, and the _glibc_ asm labels are the explicit boundary (dsys.h).
 */

#include "dsys.h"

#define M1(name)  extern double glibc_##name(double)         GLIBCSYM(name);
#define M1F(name) extern float  glibc_##name##f(float)        GLIBCSYM(name##f);
#define M2(name)  extern double glibc_##name(double, double) GLIBCSYM(name);
#define M2F(name) extern float  glibc_##name##f(float, float) GLIBCSYM(name##f);
#define M1L(name) extern long double glibc_##name##l(long double) GLIBCSYM(name##l);
#define M2L(name) extern long double glibc_##name##l(long double, long double) GLIBCSYM(name##l);

/* ----------------------------------------------------------- glibc's libm */
M1(sin)    M1F(sin)
M1(cos)    M1F(cos)
M1(tan)    M1F(tan)
M1(asin)   M1F(asin)
M1(acos)   M1F(acos)
M1(atan)   M1F(atan)
M1(sinh)   M1F(sinh)
M1(cosh)   M1F(cosh)
M1(tanh)   M1F(tanh)
M1(asinh)  M1F(asinh)
M1(acosh)  M1F(acosh)
M1(atanh)  M1F(atanh)
M1(exp)    M1F(exp)
M1(exp2)   M1F(exp2)
M1(expm1)  M1F(expm1)
M1(log)    M1F(log)
M1(log2)   M1F(log2)
M1(log10)  M1F(log10)
M1(log1p)  M1F(log1p)
M1(logb)   M1F(logb)
M1(cbrt)   M1F(cbrt)
M1(erf)    M1F(erf)
M1(erfc)   M1F(erfc)
M1(tgamma) M1F(tgamma)
M1(lgamma) M1F(lgamma)
M1(sqrt)   M1F(sqrt)
M1(fabs)   M1F(fabs)
M1(floor)  M1F(floor)
M1(ceil)   M1F(ceil)
M1(round)  M1F(round)
M1(trunc)  M1F(trunc)
M1(rint)   M1F(rint)
M1(nearbyint) M1F(nearbyint)

M2(atan2)  M2F(atan2)
M2(pow)    M2F(pow)
M2(fmod)   M2F(fmod)
M2(hypot)  M2F(hypot)
M2(copysign) M2F(copysign)
M2(fdim)   M2F(fdim)
M2(fmax)   M2F(fmax)
M2(fmin)   M2F(fmin)
M2(remainder) M2F(remainder)
M2(nextafter) M2F(nextafter)

#if defined(__x86_64__)
/* Darwin x86_64 long double is 16 bytes (x87), matching glibc. Forward l→l. */
M1L(sin) M1L(cos) M1L(tan)
M1L(asin) M1L(acos) M1L(atan)
M1L(sinh) M1L(cosh) M1L(tanh)
M1L(asinh) M1L(acosh) M1L(atanh)
M1L(exp) M1L(exp2) M1L(expm1)
M1L(log) M1L(log2) M1L(log10) M1L(log1p) M1L(logb)
M1L(cbrt) M1L(erf) M1L(erfc) M1L(tgamma) M1L(lgamma)
M1L(sqrt) M1L(fabs)
M1L(floor) M1L(ceil) M1L(round) M1L(trunc) M1L(rint) M1L(nearbyint)
M2L(atan2) M2L(pow) M2L(fmod) M2L(hypot) M2L(copysign)
M2L(fdim) M2L(fmax) M2L(fmin) M2L(remainder) M2L(nextafter)
extern long double glibc_lgammal_r(long double, int *) GLIBCSYM(lgammal_r);
extern long double glibc_ldexpl(long double, int) GLIBCSYM(ldexpl);
extern long double glibc_frexpl(long double, int *) GLIBCSYM(frexpl);
extern long double glibc_modfl(long double, long double *) GLIBCSYM(modfl);
#endif

extern double glibc_ldexp(double, int)       GLIBCSYM(ldexp);
extern float  glibc_ldexpf(float, int)       GLIBCSYM(ldexpf);
extern double glibc_frexp(double, int *)     GLIBCSYM(frexp);
extern float  glibc_frexpf(float, int *)     GLIBCSYM(frexpf);
extern double glibc_modf(double, double *)   GLIBCSYM(modf);
extern float  glibc_modff(float, float *)    GLIBCSYM(modff);
extern double glibc_scalbn(double, int)      GLIBCSYM(scalbn);
extern float  glibc_scalbnf(float, int)      GLIBCSYM(scalbnf);
extern double glibc_fma(double, double, double) GLIBCSYM(fma);
extern float  glibc_fmaf(float, float, float)   GLIBCSYM(fmaf);
#if defined(__x86_64__)
/* Darwin x86_64 long double is 16-byte x87, matching glibc. Host-bind. */
extern long double glibc_fmal(long double, long double, long double) GLIBCSYM(fmal);
#endif
extern long   glibc_lround(double)           GLIBCSYM(lround);
extern float  glibc_lroundf(float)           GLIBCSYM(lroundf);
extern long long glibc_llround(double)       GLIBCSYM(llround);
extern long   glibc_lrint(double)            GLIBCSYM(lrint);
extern int    glibc_ilogb(double)            GLIBCSYM(ilogb);
extern void   glibc_sincos(double, double *, double *) GLIBCSYM(sincos);
extern void   glibc_sincosf(float, float *, float *)   GLIBCSYM(sincosf);

/* The BSD-compatibility set, added because Swift's _DarwinFoundation1 overlay
 * calls it -- see the note in sdk/local/math.h. glibc's libm has every one of
 * these under the same name, and none of them takes or returns a long double,
 * so the width hazard below does not apply to this group. */
extern double glibc_lgamma_r(double, int *)  GLIBCSYM(lgamma_r);
extern float  glibc_lgammaf_r(float, int *)  GLIBCSYM(lgammaf_r);
extern double glibc_j0(double)               GLIBCSYM(j0);
extern double glibc_j1(double)               GLIBCSYM(j1);
extern double glibc_jn(int, double)          GLIBCSYM(jn);
extern double glibc_y0(double)               GLIBCSYM(y0);
extern double glibc_y1(double)               GLIBCSYM(y1);
extern double glibc_yn(int, double)          GLIBCSYM(yn);

/* __exp10 IS FORWARDED TO GLIBC'S exp10 RATHER THAN COMPUTED, and the reason
 * is a bug this project has already made once.
 *
 * Written the obvious way -- `return pow(10.0, x);` -- clang RECOGNISES THE
 * exp10 IDIOM and tail-calls __exp10, which is the function being defined. It
 * compiled to a single unconditional branch to itself:
 *
 *     78: 14000000    b   0x78
 *
 * with no warning, and it produced ZERO undefined symbols -- so the symbol
 * table looked HEALTHIER than the correct version, which references pow. That
 * is in the false-green catalogue, and std::__sort later did the same thing for
 * the same reason.
 *
 * glibc's libm exports a real exp10 (checked with nm -D: two versioned
 * symbols), so there is nothing to compute here and no idiom to trip over. A
 * forward is not a workaround -- Darwin's __exp10 and POSIX exp10 are the same
 * function -- and it is also the ONLY form that structurally cannot recurse,
 * because the callee is a different symbol in a different library.
 *
 * VERIFIED BY DISASSEMBLY rather than by the symbol table, because the symbol
 * table is exactly what lied last time. */
extern double glibc_exp10(double)            GLIBCSYM(exp10);
extern float  glibc_exp10f(float)            GLIBCSYM(exp10f);

EXPORT double __exp10(double x)  { return glibc_exp10(x); }
EXPORT float  __exp10f(float x)  { return glibc_exp10f(x); }

/* ------------------------------------------------------------ the exports */
/* THE `l` FORMS MUST NOT REACH glibc's `l` FORMS, and the reason is an ABI
 * difference rather than a naming one. MEASURED: `long double` is 8 bytes on
 * arm64-apple-macos -- it IS a double -- and 16 bytes on aarch64 glibc, where
 * it is a 128-bit quad in a different register class. Forwarding sinl() to
 * glibc_sinl() would hand 8 bytes to a callee expecting 16 and return
 * plausible garbage, silently. So a Darwin `l` entry point forwards to glibc's
 * DOUBLE function, which is exactly what its argument already is.
 *
 * Same hazard family as posix_spawnattr_t (docs/UNIMPLEMENTED.md#posix-spawn):
 * a type whose width differs across the boundary. There it was a struct; here
 * it is a scalar. The assert is what makes the assumption fail loudly rather
 * than quietly if either side ever moves.
 *
 * These existed as DECLARATIONS in sdk/local/math.h with no definition
 * anywhere -- an unbacked promise, the same class as a .tbd advertising a
 * symbol nothing defines. A guest calling sinl() linked and then died at load. */
#if defined(__x86_64__)
_Static_assert(sizeof(long double) == 16,
               "Darwin x86_64 long double must be 16 bytes; if this fires, the l-suffixed "
               "forwarders are passing the wrong width to glibc's long-double functions");

#define FWD1(name)  EXPORT double name(double x) { return glibc_##name(x); } \
                    EXPORT float  name##f(float x) { return glibc_##name##f(x); } \
                    EXPORT long double name##l(long double x) { return glibc_##name##l(x); }
#define FWD2(name)  EXPORT double name(double x, double y) { return glibc_##name(x, y); } \
                    EXPORT float  name##f(float x, float y) { return glibc_##name##f(x, y); } \
                    EXPORT long double name##l(long double x, long double y) \
                        { return glibc_##name##l(x, y); }
#else
_Static_assert(sizeof(long double) == sizeof(double),
               "Darwin arm64 long double must be a double; if this fires, the l-suffixed "
               "forwarders are passing the wrong width to glibc's double functions");

#define FWD1(name)  EXPORT double name(double x) { return glibc_##name(x); } \
                    EXPORT float  name##f(float x) { return glibc_##name##f(x); } \
                    EXPORT long double name##l(long double x) { return glibc_##name((double)x); }
#define FWD2(name)  EXPORT double name(double x, double y) { return glibc_##name(x, y); } \
                    EXPORT float  name##f(float x, float y) { return glibc_##name##f(x, y); } \
                    EXPORT long double name##l(long double x, long double y) \
                        { return glibc_##name((double)x, (double)y); }
#endif

FWD1(sin) FWD1(cos) FWD1(tan)
FWD1(asin) FWD1(acos) FWD1(atan)
FWD1(sinh) FWD1(cosh) FWD1(tanh)
FWD1(asinh) FWD1(acosh) FWD1(atanh)
FWD1(exp) FWD1(exp2) FWD1(expm1)
FWD1(log) FWD1(log2) FWD1(log10) FWD1(log1p) FWD1(logb)
FWD1(cbrt) FWD1(erf) FWD1(erfc) FWD1(tgamma) FWD1(lgamma)
FWD1(sqrt) FWD1(fabs)
FWD1(floor) FWD1(ceil) FWD1(round) FWD1(trunc) FWD1(rint) FWD1(nearbyint)

FWD2(atan2) FWD2(pow) FWD2(fmod) FWD2(hypot) FWD2(copysign)
FWD2(fdim) FWD2(fmax) FWD2(fmin) FWD2(remainder) FWD2(nextafter)

/* A DECLARATION IN sdk/local/math.h WITHOUT A DEFINITION HERE IS AN UNBACKED
 * PROMISE -- the sinl() failure recorded above. These are the definitions for
 * the BSD block that header now declares. lgammal_r takes the double path for
 * the same width reason as every other `l` form. */
EXPORT double lgamma_r(double x, int *s)  { return glibc_lgamma_r(x, s); }
EXPORT float  lgammaf_r(float x, int *s)  { return glibc_lgammaf_r(x, s); }
#if defined(__x86_64__)
EXPORT long double lgammal_r(long double x, int *s) { return glibc_lgammal_r(x, s); }
EXPORT long double ldexpl(long double x, int e) { return glibc_ldexpl(x, e); }
EXPORT long double frexpl(long double x, int *e) { return glibc_frexpl(x, e); }
EXPORT long double modfl(long double x, long double *i) { return glibc_modfl(x, i); }
#else
EXPORT long double lgammal_r(long double x, int *s) { return glibc_lgamma_r((double)x, s); }
#endif
EXPORT double j0(double x)          { return glibc_j0(x); }
EXPORT double j1(double x)          { return glibc_j1(x); }
EXPORT double jn(int n, double x)   { return glibc_jn(n, x); }
EXPORT double y0(double x)          { return glibc_y0(x); }
EXPORT double y1(double x)          { return glibc_y1(x); }
EXPORT double yn(int n, double x)   { return glibc_yn(n, x); }

EXPORT double ldexp(double x, int e)   { return glibc_ldexp(x, e); }
EXPORT float  ldexpf(float x, int e)   { return glibc_ldexpf(x, e); }
EXPORT double frexp(double x, int *e)  { return glibc_frexp(x, e); }
EXPORT float  frexpf(float x, int *e)  { return glibc_frexpf(x, e); }
EXPORT double modf(double x, double *i){ return glibc_modf(x, i); }
EXPORT float  modff(float x, float *i) { return glibc_modff(x, i); }
EXPORT double scalbn(double x, int e)  { return glibc_scalbn(x, e); }
EXPORT float  scalbnf(float x, int e)  { return glibc_scalbnf(x, e); }
EXPORT double fma(double a, double b, double c) { return glibc_fma(a, b, c); }
EXPORT float  fmaf(float a, float b, float c)   { return glibc_fmaf(a, b, c); }
#if defined(__x86_64__)
EXPORT long double fmal(long double a, long double b, long double c)
{
    return glibc_fmal(a, b, c);
}
#else
/* Darwin arm64 long double IS double (8 bytes); glibc aarch64 fmal is
 * binary128. Host-binding would pass 8 bytes to a 16-byte callee. fma is
 * the operation Darwin's long double actually performs. The tbd still
 * advertises _fmal -- the export is implemented, not ARCH-hidden. */
EXPORT long double fmal(long double a, long double b, long double c)
{
    return glibc_fma((double)a, (double)b, (double)c);
}
#endif
EXPORT long   lround(double x)         { return glibc_lround(x); }
EXPORT long   lroundf(float x)         { return (long)glibc_lroundf(x); }
EXPORT long long llround(double x)     { return glibc_llround(x); }
EXPORT long   lrint(double x)          { return glibc_lrint(x); }
EXPORT int    ilogb(double x)          { return glibc_ilogb(x); }

/* __sincos_stret / __sincosf_stret -- a DARWIN ABI, not a POSIX function.
 *
 * clang emits a call to these instead of separate sin+cos calls whenever it
 * sees both of a value on an Apple target; quartz's rotation code trips it.
 * The return type is a two-element homogeneous float aggregate, so AAPCS64
 * returns it in v0/v1 (d0/d1 for the double form) rather than through x8, and
 * the field ORDER is the ABI: sinval first, cosval second. Apple's
 * <math.h> spells it
 *     __float2  { float  __sinval, __cosval; }
 *     __double2 { double __sinval, __cosval; }
 * and getting them the wrong way round would silently transpose every rotation
 * in the guest, which is the sort of bug a pixel diff catches and a unit test
 * of libSystem does not. */
struct mr_double2 { double sinval, cosval; };
struct mr_float2  { float  sinval, cosval; };

EXPORT struct mr_double2 __sincos_stret(double x)
{
    struct mr_double2 r;
    glibc_sincos(x, &r.sinval, &r.cosval);
    return r;
}

EXPORT struct mr_float2 __sincosf_stret(float x)
{
    struct mr_float2 r;
    glibc_sincosf(x, &r.sinval, &r.cosval);
    return r;
}

/* Darwin also exports the plain names. Same aggregate, same order. */
EXPORT void __sincos(double x, double *s, double *c)  { glibc_sincos(x, s, c); }
EXPORT void __sincosf(float x, float *s, float *c)    { glibc_sincosf(x, s, c); }
EXPORT void sincos(double x, double *s, double *c)    { glibc_sincos(x, s, c); }
EXPORT void sincosf(float x, float *s, float *c)      { glibc_sincosf(x, s, c); }

/* Classification. Darwin's <math.h> lowers isnan/isinf/isfinite to compiler
 * builtins, but a guest built -fno-builtin, or one using the legacy non-macro
 * spellings, calls these. They are exact in IEEE 754, so no divergence is
 * possible and nothing is borrowed from glibc. */
EXPORT int __isnand(double x)  { return x != x; }
EXPORT int __isnanf(float x)   { return x != x; }
EXPORT int __isinfd(double x)  { return !(x != x) && (x > 1.7976931348623157e308 || x < -1.7976931348623157e308); }
EXPORT int __isinff(float x)   { return !(x != x) && (x > 3.4028234663852886e38f || x < -3.4028234663852886e38f); }
EXPORT int __isfinited(double x) { return !__isnand(x) && !__isinfd(x); }
EXPORT int __isfinitef(float x)  { return !__isnanf(x) && !__isinff(x); }
