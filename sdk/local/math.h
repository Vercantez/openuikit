/*
 * math.h -- machorun's clean-room replacement.
 *
 * NOT Apple's header.  This one is a CORRECTION to docs/SDK_SURVEY.md, which
 * put math.h in category (a) -- obtainable upstream -- on the strength of a
 * path match against apple-oss-distributions/Libm.  Staging it and compiling
 * proved that wrong, loudly:
 *
 *     sdk/usr/include/math.h:32:2: error: Unknown architecture
 *
 * Libm's published `Source/math.h` is a five-line dispatcher to
 * `architecture/{ppc,i386,arm}/math.h`, all three of which are 2002-era files
 * for 32-bit architectures.  __arm64__ is not __arm__, so the dispatcher falls
 * through to its #error.  Libm has not shipped a release since; the modern
 * math.h (802 lines in MacOSX15.4.sdk) comes from Apple's closed libm.  A
 * search of all eleven fetched trees finds four math.h files and no other.
 *
 * So math.h is the one genuine category-(c) header, and the survey's headline
 * -- "the genuinely-only-in-the-Xcode-SDK category is empty" -- is off by one.
 *
 * It is also the easiest possible category-(c) header, because <math.h> is not
 * Apple's interface: it is ISO C99 §7.12 plus a handful of Darwin extensions,
 * and clang implements essentially all of it as a builtin.  What follows is
 * written from the standard.
 *
 * WHAT THIS OMITS versus Apple's 802-line header:
 *   - the __sincos / __sincosf / __sinpi / __cospi / __tanpi / __exp10 family
 *     and Apple's other non-standard spellings.  They are declared below only
 *     where a vendored header or our own userland needs them; the rest are
 *     absent, so calling one is an undeclared-identifier error rather than a
 *     link-time surprise.
 *   - every __API_AVAILABLE / __DARWIN_ALIAS annotation.  See
 *     sdk/local/AvailabilityInternal.h for why this SDK carries no
 *     availability diagnostics at all.
 *   - the BSD-compatibility block (j0/j1/jn/y0/y1/yn, gamma, significand,
 *     drem, and the `struct exception` / matherr machinery).  Nothing this
 *     project compiles reaches for them.
 *   - _Float16 and __float128 overloads.
 */

#ifndef _MATH_H_
#define _MATH_H_

#include <sys/cdefs.h>

__BEGIN_DECLS

/* ------------------------------------------------------------------ types */
typedef float  float_t;
typedef double double_t;

/* ------------------------------------------------------------- constants */
#define HUGE_VAL   __builtin_huge_val()
#define HUGE_VALF  __builtin_huge_valf()
#define HUGE_VALL  __builtin_huge_vall()
#define INFINITY   __builtin_inff()
#define NAN        __builtin_nanf("")

#define FP_NAN         1
#define FP_INFINITE    2
#define FP_ZERO        3
#define FP_NORMAL      4
#define FP_SUBNORMAL   5
#define FP_SUPERNORMAL 6  /* Darwin defines it; no arm64 value ever has it */

#define FP_ILOGB0    (-2147483647 - 1)
#define FP_ILOGBNAN  (-2147483647 - 1)

#define MATH_ERRNO     1
#define MATH_ERREXCEPT 2
#define math_errhandling (MATH_ERRNO | MATH_ERREXCEPT)

/* C99 §7.12.3 classification.  Every one is a clang builtin; using the
 * builtins is what makes this file correct for arm64 without a table. */
#define fpclassify(x) \
    __builtin_fpclassify(FP_NAN, FP_INFINITE, FP_NORMAL, FP_SUBNORMAL, FP_ZERO, x)
#define isfinite(x)   __builtin_isfinite(x)
#define isinf(x)      __builtin_isinf(x)
#define isnan(x)      __builtin_isnan(x)
#define isnormal(x)   __builtin_isnormal(x)
#define signbit(x)    __builtin_signbit(x)

/* C99 §7.12.14 comparison. */
#define isgreater(x, y)      __builtin_isgreater((x), (y))
#define isgreaterequal(x, y) __builtin_isgreaterequal((x), (y))
#define isless(x, y)         __builtin_isless((x), (y))
#define islessequal(x, y)    __builtin_islessequal((x), (y))
#define islessgreater(x, y)  __builtin_islessgreater((x), (y))
#define isunordered(x, y)    __builtin_isunordered((x), (y))

/* ------------------------------------------------------------- functions */
#define __MR_MATH1(f) \
    extern double f(double); extern float f##f(float); extern long double f##l(long double)
#define __MR_MATH2(f) \
    extern double f(double, double); extern float f##f(float, float); \
    extern long double f##l(long double, long double)

__MR_MATH1(acos);   __MR_MATH1(asin);   __MR_MATH1(atan);
__MR_MATH1(cos);    __MR_MATH1(sin);    __MR_MATH1(tan);
__MR_MATH1(acosh);  __MR_MATH1(asinh);  __MR_MATH1(atanh);
__MR_MATH1(cosh);   __MR_MATH1(sinh);   __MR_MATH1(tanh);
__MR_MATH1(exp);    __MR_MATH1(exp2);   __MR_MATH1(expm1);
__MR_MATH1(log);    __MR_MATH1(log10);  __MR_MATH1(log1p);
__MR_MATH1(log2);   __MR_MATH1(logb);   __MR_MATH1(cbrt);
__MR_MATH1(fabs);   __MR_MATH1(sqrt);   __MR_MATH1(erf);
__MR_MATH1(erfc);   __MR_MATH1(lgamma); __MR_MATH1(tgamma);
__MR_MATH1(ceil);   __MR_MATH1(floor);  __MR_MATH1(nearbyint);
__MR_MATH1(rint);   __MR_MATH1(round);  __MR_MATH1(trunc);

__MR_MATH2(atan2);  __MR_MATH2(hypot);  __MR_MATH2(pow);
__MR_MATH2(fmod);   __MR_MATH2(remainder); __MR_MATH2(copysign);
__MR_MATH2(nextafter); __MR_MATH2(fdim); __MR_MATH2(fmax); __MR_MATH2(fmin);

#undef __MR_MATH1
#undef __MR_MATH2

extern double      frexp(double, int *);
extern float       frexpf(float, int *);
extern long double frexpl(long double, int *);

extern int ilogb(double);
extern int ilogbf(float);
extern int ilogbl(long double);

extern double      ldexp(double, int);
extern float       ldexpf(float, int);
extern long double ldexpl(long double, int);

extern double      modf(double, double *);
extern float       modff(float, float *);
extern long double modfl(long double, long double *);

extern double      scalbn(double, int);
extern float       scalbnf(float, int);
extern long double scalbnl(long double, int);
extern double      scalbln(double, long);
extern float       scalblnf(float, long);
extern long double scalblnl(long double, long);

extern long      lrint(double);
extern long      lrintf(float);
extern long      lrintl(long double);
extern long long llrint(double);
extern long long llrintf(float);
extern long long llrintl(long double);
extern long      lround(double);
extern long      lroundf(float);
extern long      lroundl(long double);
extern long long llround(double);
extern long long llroundf(float);
extern long long llroundl(long double);

extern double      remquo(double, double, int *);
extern float       remquof(float, float, int *);
extern long double remquol(long double, long double, int *);

extern double      nan(const char *);
extern float       nanf(const char *);
extern long double nanl(const char *);

extern double      nexttoward(double, long double);
extern float       nexttowardf(float, long double);
extern long double nexttowardl(long double, long double);

extern double      fma(double, double, double);
extern float       fmaf(float, float, float);
extern long double fmal(long double, long double, long double);

/* Darwin extensions our own userland and vendored headers actually use. */
extern void   __sincos(double, double *, double *);
extern void   __sincosf(float, float *, float *);
extern double __exp10(double);
extern float  __exp10f(float);

/* -------------------------------------------------- the M_* conveniences */
/* Not ISO C -- XSI, and every Darwin math.h has shipped them unconditionally. */
#define M_E        2.71828182845904523536028747135266250
#define M_LOG2E    1.44269504088896340735992468100189214
#define M_LOG10E   0.434294481903251827651128918916605082
#define M_LN2      0.693147180559945309417232121458176568
#define M_LN10     2.30258509299404568401799145468436421
#define M_PI       3.14159265358979323846264338327950288
#define M_PI_2     1.57079632679489661923132169163975144
#define M_PI_4     0.785398163397448309615660845819875721
#define M_1_PI     0.318309886183790671537767526745028724
#define M_2_PI     0.636619772367581343075535053490057448
#define M_2_SQRTPI 1.12837916709551257389615890312154517
#define M_SQRT2    1.41421356237309504880168872420969808
#define M_SQRT1_2  0.707106781186547524400844362104849039

#define MAXFLOAT   ((float)3.40282346638528860e+38)

__END_DECLS

#endif /* _MATH_H_ */
