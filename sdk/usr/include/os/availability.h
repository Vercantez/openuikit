/*
 * os/availability.h -- machorun's clean-room replacement.
 *
 * NOT Apple's header.  Apple's is 294 lines and matches nothing in any
 * apple-oss-distributions release (docs/SDK_SURVEY.md §2.4).
 *
 * This is the modern, un-underscored front end: API_AVAILABLE(macos(10.12)),
 * API_DEPRECATED(...), API_UNAVAILABLE(...).  Each forwards to the underscored
 * form in AvailabilityInternal.h, and each of those expands to nothing.  That
 * header states the decision and exactly what it omits.
 */

#ifndef __OS_AVAILABILITY__
#define __OS_AVAILABILITY__

#include <AvailabilityInternal.h>

#define API_AVAILABLE(...)                     __API_AVAILABLE(__VA_ARGS__)
#define API_AVAILABLE_BEGIN(...)               __API_AVAILABLE_BEGIN(__VA_ARGS__)
#define API_AVAILABLE_END                      __API_AVAILABLE_END
#define API_DEPRECATED(...)                    __API_DEPRECATED(__VA_ARGS__)
#define API_DEPRECATED_WITH_REPLACEMENT(...)   __API_DEPRECATED_WITH_REPLACEMENT(__VA_ARGS__)
#define API_DEPRECATED_BEGIN(...)              __API_DEPRECATED_BEGIN(__VA_ARGS__)
#define API_DEPRECATED_END                     __API_DEPRECATED_END
#define API_UNAVAILABLE(...)                   __API_UNAVAILABLE(__VA_ARGS__)
#define API_UNAVAILABLE_BEGIN(...)             __API_UNAVAILABLE_BEGIN(__VA_ARGS__)
#define API_UNAVAILABLE_END                    __API_UNAVAILABLE_END

#define SPI_AVAILABLE(...)                     __SPI_AVAILABLE(__VA_ARGS__)
#define SPI_DEPRECATED(...)                    __SPI_DEPRECATED(__VA_ARGS__)
#define SPI_DEPRECATED_WITH_REPLACEMENT(...)   __SPI_DEPRECATED_WITH_REPLACEMENT(__VA_ARGS__)

/* Apple gates these on __swift__; nothing here is imported by Swift. */
#define SWIFT_UNAVAILABLE                      __SWIFT_UNAVAILABLE
#define SWIFT_UNAVAILABLE_MSG(_msg)            __SWIFT_UNAVAILABLE_MSG(_msg)

#endif /* __OS_AVAILABILITY__ */
