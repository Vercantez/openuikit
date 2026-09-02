/*
 * AvailabilityInternal.h -- machorun's clean-room replacement.
 *
 * NOT Apple's header.  Apple's is 536 lines and matches only a stale xnu
 * EXTERNAL_HEADERS snapshot (47% line-identical -- docs/SDK_SURVEY.md §2.1),
 * which is why it is written here rather than vendored.
 *
 * THE ONE DESIGN DECISION IN THIS FILE, stated plainly:
 *
 *   Every availability ATTRIBUTE in this SDK expands to nothing.
 *
 * Apple's version of this header is a 782 KB expansion matrix whose entire
 * output is `__attribute__((availability(...)))` -- a compile-time DIAGNOSTIC.
 * It changes no code generation, no symbol name, no struct layout, no calling
 * convention.  machorun ships no public API whose availability anyone checks,
 * and its deployment target is fixed by scripts/build_darwin.sh, so the
 * diagnostic has nothing to tell us.
 *
 * What is NOT dropped is the arithmetic: __MAC_10_13 and friends keep their
 * real values (AvailabilityVersions.h), because vendored headers compare
 * against them inside #if and a wrong number there DOES change what compiles.
 *
 * WHAT THIS OMITS versus Apple's:
 *   - all deprecation and unavailability warnings.  Calling a function Apple
 *     marks as removed-in-10.9 compiles silently here.
 *   - __API_AVAILABLE_BEGIN / _END scoped forms are accepted and ignored
 *     rather than applied to a region.
 *   - the Swift-availability plumbing (__SWIFT_UNAVAILABLE et al) is accepted
 *     and ignored; nothing here is imported by Swift.
 */

#ifndef __AVAILABILITY_INTERNAL__
#define __AVAILABILITY_INTERNAL__

#include <AvailabilityVersions.h>

/* Apple's internal spellings.  Variadic so that every arity Apple's headers
 * use -- __OS_AVAILABILITY(macosx,introduced=10.6) through the four-platform
 * forms -- swallows its arguments. */
#define __OS_AVAILABILITY(...)
#define __OS_AVAILABILITY_MSG(...)
#define __OS_AVAILABILITY_REPLACEMENT(...)

#define __API_AVAILABLE(...)
#define __API_AVAILABLE_BEGIN(...)
#define __API_AVAILABLE_END
#define __API_DEPRECATED(...)
#define __API_DEPRECATED_WITH_REPLACEMENT(...)
#define __API_DEPRECATED_BEGIN(...)
#define __API_DEPRECATED_END
#define __API_UNAVAILABLE(...)
#define __API_UNAVAILABLE_BEGIN(...)
#define __API_UNAVAILABLE_END
#define __SPI_AVAILABLE(...)
#define __SPI_DEPRECATED(...)
#define __SPI_DEPRECATED_WITH_REPLACEMENT(...)

/* The per-platform pre-2016 spellings. */
#define __OSX_AVAILABLE(_vers)
#define __OSX_AVAILABLE_STARTING(...)
#define __OSX_AVAILABLE_BUT_DEPRECATED(...)
#define __OSX_AVAILABLE_BUT_DEPRECATED_MSG(...)
#define __OSX_DEPRECATED(...)
#define __OSX_UNAVAILABLE
#define __OSX_PROHIBITED

#define __IOS_AVAILABLE(_vers)
#define __IOS_DEPRECATED(...)
#define __IOS_UNAVAILABLE
#define __IOS_PROHIBITED

#define __TVOS_AVAILABLE(_vers)
#define __TVOS_DEPRECATED(...)
#define __TVOS_UNAVAILABLE
#define __TVOS_PROHIBITED

#define __WATCHOS_AVAILABLE(_vers)
#define __WATCHOS_DEPRECATED(...)
#define __WATCHOS_UNAVAILABLE
#define __WATCHOS_PROHIBITED

#define __VISIONOS_AVAILABLE(_vers)
#define __VISIONOS_DEPRECATED(...)
#define __VISIONOS_UNAVAILABLE
#define __VISIONOS_PROHIBITED

#define __BRIDGEOS_AVAILABLE(_vers)
#define __BRIDGEOS_DEPRECATED(...)
#define __BRIDGEOS_UNAVAILABLE
#define __BRIDGEOS_PROHIBITED

#define __DRIVERKIT_AVAILABLE(_vers)
#define __DRIVERKIT_DEPRECATED(...)
#define __DRIVERKIT_UNAVAILABLE
#define __DRIVERKIT_PROHIBITED

#define __SWIFT_UNAVAILABLE
#define __SWIFT_UNAVAILABLE_MSG(_msg)

/* Two that are NOT diagnostics and therefore are not dropped: weak_import
 * changes the symbol's binding, and the enum-availability marker is inert. */
#define __AVAILABILITY_INTERNAL_WEAK_IMPORT __attribute__((weak_import))
#define __ENUM_AVAILABLE(...)
#define __ENUM_DEPRECATED(...)

#endif /* __AVAILABILITY_INTERNAL__ */
