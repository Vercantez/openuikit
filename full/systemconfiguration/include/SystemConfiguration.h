#ifndef OPENUIKIT_SYSTEMCONFIGURATION_H
#define OPENUIKIT_SYSTEMCONFIGURATION_H

#include <CoreFoundation/CoreFoundation.h>

#include "SCNetwork.h"
#include "SCNetworkReachability.h"
#include "OpenSystemConfiguration.h"

enum {
    kSCStatusOK = 0,
    kSCStatusFailed = 1001,
    kSCStatusInvalidArgument = 1002,
    kSCStatusAccessError = 1003,
    kSCStatusNoKey = 1004,
    kSCStatusKeyExists = 1005,
    kSCStatusLocked = 1006,
    kSCStatusNeedLock = 1007,
    kSCStatusNoStoreSession = 2001,
    kSCStatusNoStoreServer = 2002,
    kSCStatusNotifierActive = 2003,
    kSCStatusNoPrefsSession = 3001,
    kSCStatusPrefsBusy = 3002,
    kSCStatusNoConfigFile = 3003,
    kSCStatusNoLink = 3004,
    kSCStatusStale = 3005,
    kSCStatusMaxLink = 3006,
    kSCStatusReachabilityUnknown = 4001
};

CF_IMPLICIT_BRIDGING_ENABLED
CF_ASSUME_NONNULL_BEGIN

OPEN_SYSTEMCONFIGURATION_EXPORT extern const CFStringRef
kCFErrorDomainSystemConfiguration;

OPEN_SYSTEMCONFIGURATION_EXPORT CFErrorRef __nullable SCCopyLastError(void);
OPEN_SYSTEMCONFIGURATION_EXPORT int SCError(void);
OPEN_SYSTEMCONFIGURATION_EXPORT const char *SCErrorString(int status);

CF_ASSUME_NONNULL_END
CF_IMPLICIT_BRIDGING_DISABLED

#endif
