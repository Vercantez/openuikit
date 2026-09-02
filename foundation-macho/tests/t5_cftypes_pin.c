/* Pin src/nscf/CFTypesMirror.h against CoreFoundation's REAL definitions.
 *
 *   compiled with -I <CF>/include, so both headers are in scope at once
 *
 * WHY THIS EXISTS. CFTypesMirror.h is a hand-written copy of another
 * component's layout, and the component it copies never checks it. That is
 * exactly the shape of the `linux_stat` mirror in machorun, which asserted its
 * own hand-written struct against itself and would have kept passing while
 * stat() returned nonsense. A mirror nobody checks is not a shortcut, it is a
 * second source of truth waiting to drift.
 *
 * The drift would be SILENT, which is what makes it worth a test rather than a
 * comment. Every __NSCF* file includes the mirror and none includes CFBase.h,
 * so each stays internally consistent no matter how wrong the mirror is. A
 * CFIndex that became `int` would compile everywhere and truncate every length
 * above 2^31 at the boundary.
 *
 * This file is the one place both headers meet. It has no runtime component --
 * if it compiles, the mirror agrees; if the mirror drifts, it fails to compile
 * and names the field.
 *
 * NOTE ON __builtin_types_compatible_p: sizeof agreement is NOT enough here.
 * CFBase.h declares CFIndex as `signed long long` under __LLP64__ and `signed
 * long` otherwise -- same width on our target, different type identity, which
 * survives every size check and fails an overload or a CFIndex* assignment.
 * So the scalar types are pinned by IDENTITY, and only the struct by layout.
 */

#include <CoreFoundation/CFBase.h>
#include <CoreFoundation/CFDate.h>   /* CFAbsoluteTime lives here, not in CFBase.h */

/* Include the mirror under a rename, so the two definitions can coexist in one
 * translation unit and be compared. Without this they would simply collide --
 * and a collision is a weaker check, because it only catches a difference the
 * compiler happens to consider a redefinition. */
#define Boolean             MIRROR_Boolean
#define UniChar             MIRROR_UniChar
#define CFIndex             MIRROR_CFIndex
#define CFRange             MIRROR_CFRange
#define CFComparisonResult  MIRROR_CFComparisonResult
#define CFAbsoluteTime      MIRROR_CFAbsoluteTime
#define CFNumberType        MIRROR_CFNumberType
#define _NSCF_CFTYPES_MIRROR_H_RENAMED
#include "../src/nscf/CFTypesMirror.h"
#undef Boolean
#undef UniChar
#undef CFIndex
#undef CFRange
#undef CFComparisonResult
#undef CFAbsoluteTime
#undef CFNumberType

/* --- scalars, pinned by TYPE IDENTITY rather than by size ----------------- */

_Static_assert(__builtin_types_compatible_p(MIRROR_CFIndex, CFIndex),
    "CFTypesMirror.h: CFIndex disagrees with CFBase.h. Note CFBase.h declares "
    "it TWICE -- signed long long under __LLP64__, signed long otherwise -- so "
    "a size check would not catch this.");

_Static_assert(__builtin_types_compatible_p(MIRROR_Boolean, Boolean),
    "CFTypesMirror.h: Boolean disagrees with MacTypes.h");

_Static_assert(__builtin_types_compatible_p(MIRROR_UniChar, UniChar),
    "CFTypesMirror.h: UniChar disagrees with CFBase.h");

_Static_assert(__builtin_types_compatible_p(MIRROR_CFComparisonResult,
                                            CFComparisonResult),
    "CFTypesMirror.h: CFComparisonResult disagrees with CFBase.h");

_Static_assert(__builtin_types_compatible_p(MIRROR_CFAbsoluteTime,
                                            CFAbsoluteTime),
    "CFTypesMirror.h: CFAbsoluteTime disagrees with CFDate.h");

/* --- the struct, pinned by layout ----------------------------------------- */

_Static_assert(sizeof(MIRROR_CFRange) == sizeof(CFRange),
    "CFTypesMirror.h: CFRange size disagrees with CFBase.h");
_Static_assert(_Alignof(MIRROR_CFRange) == _Alignof(CFRange),
    "CFTypesMirror.h: CFRange alignment disagrees with CFBase.h");
_Static_assert(__builtin_offsetof(MIRROR_CFRange, location) ==
               __builtin_offsetof(CFRange, location),
    "CFTypesMirror.h: CFRange.location is at the wrong offset");
_Static_assert(__builtin_offsetof(MIRROR_CFRange, length) ==
               __builtin_offsetof(CFRange, length),
    "CFTypesMirror.h: CFRange.length is at the wrong offset -- note that "
    "swapping location and length would keep the SIZE identical, which is why "
    "the offsets are pinned individually rather than just the struct.");
_Static_assert(__builtin_types_compatible_p(
                   __typeof__(((MIRROR_CFRange *)0)->location),
                   __typeof__(((CFRange *)0)->location)),
    "CFTypesMirror.h: CFRange.location has the wrong type");

/* CFNumberType is CF_ENUM(CFIndex, ...) so its underlying type is CFIndex and
 * it is EIGHT bytes. The mirror originally said `int` and THIS ASSERT CAUGHT IT
 * on the pin's first run -- a 4-byte value passed where CF reads 8, with the
 * upper half whatever was in the register. Pinned by size rather than identity
 * because an enum's compatibility with its underlying type is not something
 * __builtin_types_compatible_p reports usefully; size is what matters for
 * passing it by value. Stated rather than silently weakened. */
#include <CoreFoundation/CFNumber.h>
_Static_assert(sizeof(MIRROR_CFNumberType) == sizeof(CFNumberType),
    "CFTypesMirror.h: CFNumberType size disagrees with CFNumber.h");
