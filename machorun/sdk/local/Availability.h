/*
 * Availability.h -- machorun's clean-room replacement.
 *
 * NOT Apple's header.  Apple's is 625 lines; xnu's published EXTERNAL_HEADERS
 * copy is a 420-line stale snapshot only 47% line-identical to it
 * (docs/SDK_SURVEY.md §2.1), so neither is vendored.
 *
 * The public spellings of the availability attributes.  Every one expands to
 * nothing; AvailabilityInternal.h states why, and what that omits.
 */

#ifndef __AVAILABILITY__
#define __AVAILABILITY__

#include <AvailabilityVersions.h>
#include <AvailabilityInternal.h>

/* The __OSX_AVAILABLE_STARTING family and the __API_* family both live in
 * AvailabilityInternal.h, because vendored headers reach for the underscored
 * names directly.  Here are the un-underscored public aliases. */
#define OSX_AVAILABLE(_vers)
#define OSX_DEPRECATED(...)
#define IOS_AVAILABLE(_vers)
#define IOS_DEPRECATED(...)
#define TVOS_AVAILABLE(_vers)
#define TVOS_DEPRECATED(...)
#define WATCHOS_AVAILABLE(_vers)
#define WATCHOS_DEPRECATED(...)

#define __NSi_AVAILABLE(...)
#define NS_AVAILABLE(...)
#define NS_DEPRECATED(...)

#endif /* __AVAILABILITY__ */
