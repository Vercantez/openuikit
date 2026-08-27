#ifndef _COMPLEX_H_
#define _COMPLEX_H_
/* Minimal Darwin <complex.h>. machorun's SDK ships math.h but NOT complex.h,
   and clang's own /usr/lib/swift/clang/include/tgmath.h includes it
   UNCONDITIONALLY -- so any C module built against that sysroot which reaches
   tgmath.h fails to build. Nothing here needs complex arithmetic; this only
   has to satisfy the include. */
#define complex _Complex
#define _Complex_I ((float _Complex)1.0fi)
#define I _Complex_I
#endif
