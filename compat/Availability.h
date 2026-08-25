/*
 * compat/Availability.h  --  objc4-linux
 *
 * There are no OS versions to be available in. Every availability macro
 * expands to nothing; every __*_AVAILABLE_STARTING check is vacuously true.
 */
#ifndef _OBJC4LINUX_AVAILABILITY_H
#define _OBJC4LINUX_AVAILABILITY_H

#define __OSX_AVAILABLE_STARTING(...)
#define __OSX_AVAILABLE_BUT_DEPRECATED(...)
#define __OSX_AVAILABLE_BUT_DEPRECATED_MSG(...)
#define __OSX_AVAILABLE(...)
#define __OSX_DEPRECATED(...)
#define __IOS_AVAILABLE(...)
#define __IOS_DEPRECATED(...)
#define __IOS_PROHIBITED
#define __TVOS_AVAILABLE(...)
#define __TVOS_DEPRECATED(...)
#define __TVOS_PROHIBITED
#define __WATCHOS_AVAILABLE(...)
#define __WATCHOS_DEPRECATED(...)
#define __WATCHOS_PROHIBITED
#define __BRIDGEOS_AVAILABLE(...)
#define __BRIDGEOS_DEPRECATED(...)
#define __BRIDGEOS_PROHIBITED
#define __SWIFT_UNAVAILABLE
#define __SWIFT_UNAVAILABLE_MSG(...)

#define API_AVAILABLE(...)
#define API_AVAILABLE_BEGIN(...)
#define API_AVAILABLE_END
#define API_UNAVAILABLE(...)
#define API_UNAVAILABLE_BEGIN(...)
#define API_UNAVAILABLE_END
#define API_DEPRECATED(...)
#define API_DEPRECATED_WITH_REPLACEMENT(...)
#define SPI_AVAILABLE(...)
#define SPI_DEPRECATED(...)
#define SPI_DEPRECATED_WITH_REPLACEMENT(...)

/* Version constants some headers compare against. Values are irrelevant
 * because every comparison sits inside a macro we already emptied. */
#define __MAC_OS_X_VERSION_MIN_REQUIRED     999999
#define __MAC_OS_X_VERSION_MAX_ALLOWED      999999
#define __IPHONE_OS_VERSION_MIN_REQUIRED    0
#define __IPHONE_OS_VERSION_MAX_ALLOWED     0


/* __*_UNAVAILABLE / __*_PROHIBITED: also nothing. */
#define __OSX_UNAVAILABLE
#define __IOS_UNAVAILABLE
#define __TVOS_UNAVAILABLE
#define __WATCHOS_UNAVAILABLE
#define __BRIDGEOS_UNAVAILABLE
#define __VISIONOS_UNAVAILABLE
#define __VISIONOS_AVAILABLE(...)
#define __VISIONOS_DEPRECATED(...)
#define __MAC_OS_VERSION_MIN_REQUIRED 999999

#endif
