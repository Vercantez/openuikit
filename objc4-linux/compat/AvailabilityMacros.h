/* compat/AvailabilityMacros.h -- objc4-linux. See Availability.h. */
#ifndef _OBJC4LINUX_AVAILABILITYMACROS_H
#define _OBJC4LINUX_AVAILABILITYMACROS_H

#include <Availability.h>

#define AVAILABLE_MAC_OS_X_VERSION_10_0_AND_LATER
#define DEPRECATED_ATTRIBUTE                    __attribute__((deprecated))
#define DEPRECATED_MSG_ATTRIBUTE(msg)           __attribute__((deprecated(msg)))
#define UNAVAILABLE_ATTRIBUTE                   __attribute__((unavailable))

#define MAC_OS_X_VERSION_10_0   1000
#define MAC_OS_X_VERSION_10_15  101500
#define MAC_OS_X_VERSION_MIN_REQUIRED  MAC_OS_X_VERSION_10_15
#define MAC_OS_X_VERSION_MAX_ALLOWED   999999

#define AVAILABLE_MAC_OS_X_VERSION_10_0_AND_LATER_BUT_DEPRECATED_IN_MAC_OS_X_VERSION_10_5
#define AVAILABLE_MAC_OS_X_VERSION_10_5_AND_LATER

#endif
