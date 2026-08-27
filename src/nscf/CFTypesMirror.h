/* CFBase.h's types, mirrored once for the __NSCF* classes.
 *
 * WHY MIRRORED AT ALL: these files compile standalone today, because CF's own
 * headers are staged only for the census. A duplicate typedef of an identical
 * type is legal C, so this costs nothing and keeps the classes buildable on
 * their own.
 *
 * WHY IN ONE PLACE: this is the third file that needed them, and three copies
 * that must agree is the same "two sources of truth" hazard this project keeps
 * finding elsewhere -- with the extra sting that a divergence here would be a
 * silent ABI mismatch rather than a compile error, since each file would be
 * internally consistent.
 *
 * EVERY VALUE BELOW IS VERIFIED AGAINST THE REAL HEADER, not recalled:
 *
 *   CFIndex   CFBase.h declares it TWICE -- `signed long long` under __LLP64__
 *             and `signed long` otherwise. Same width, different type identity,
 *             which survives a size check and fails an overload. Settled by
 *             compiling `_Static_assert(__builtin_types_compatible_p(CFIndex,
 *             long))` against CF's real CFBase.h with our flags: exits 0.
 *   Boolean   MacTypes.h:19, `unsigned char`. Checked in the sysroot.
 *   UniChar   CFBase.h:91, `unsigned short`. Checked.
 *   CFRange   CFBase.h:480-483, two CFIndex fields, location then length.
 *   CFNumberType  CF_ENUM(CFIndex, ...) in CFNumber.h -- EIGHT bytes, not four.
 *                 Pinned after the mirror got it wrong.
 *
 * All of the above are asserted against CF's real headers by
 * tests/t5_cftypes_pin.c, which is the only place the mirror and CFBase.h meet
 * in one translation unit. It has already caught one wrong type.
 *
 * If CF's headers ever land on these files' include path, these become
 * redundant rather than wrong -- identical typedefs coexist.
 */
#ifndef _NSCF_CFTYPES_MIRROR_H
#define _NSCF_CFTYPES_MIRROR_H

typedef unsigned char  Boolean;
typedef unsigned short UniChar;
typedef long           CFIndex;
typedef struct { CFIndex location; CFIndex length; } CFRange;

typedef CFIndex        CFComparisonResult;
typedef double         CFAbsoluteTime;
/* CFIndex, NOT int. CFNumber.h declares it as CF_ENUM(CFIndex, CFNumberType),
 * so the underlying type is CFIndex and it is EIGHT bytes. I wrote `int` and
 * the pin in tests/t5_cftypes_pin.c caught it on its first run -- which would
 * otherwise have passed a 4-byte value to -_getValue:forType: where CF reads 8,
 * leaving the upper half whatever happened to be in the register. Exactly the
 * shape of the nfds_t finding: a scalar argument of the wrong width, invisible
 * to every check except one that compares against the real declaration. */
typedef CFIndex        CFNumberType;

#endif /* _NSCF_CFTYPES_MIRROR_H */
