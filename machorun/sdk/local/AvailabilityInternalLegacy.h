/*
 * AvailabilityInternalLegacy.h -- machorun's clean-room replacement.
 *
 * NOT Apple's header.  Apple's is 4,346 lines / 414 KB -- the pre-__API_AVAILABLE
 * __OSX_AVAILABLE_STARTING expansion matrix, one #define per (macOS, iOS)
 * version pair.  It matches nothing in any apple-oss-distributions release
 * (docs/SDK_SURVEY.md §2.4).
 *
 * The entire matrix exists to turn a version pair into an
 * __attribute__((availability(...))) diagnostic.  This SDK emits no such
 * diagnostics -- AvailabilityInternal.h says why -- so the matrix collapses to
 * the two lines below, and the file survives only so that a guest's
 * `#include <AvailabilityInternalLegacy.h>` resolves.
 *
 * WHAT THIS OMITS: 414 KB of deprecation warnings, and nothing else.  No
 * constant, type, layout or symbol name comes out of Apple's version.
 */

#ifndef __AVAILABILITY_INTERNAL_LEGACY__
#define __AVAILABILITY_INTERNAL_LEGACY__

#include <AvailabilityInternal.h>

#endif /* __AVAILABILITY_INTERNAL_LEGACY__ */
