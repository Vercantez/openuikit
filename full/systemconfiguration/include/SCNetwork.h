#ifndef OPENUIKIT_SYSTEMCONFIGURATION_SCNETWORK_H
#define OPENUIKIT_SYSTEMCONFIGURATION_SCNETWORK_H

#include <CoreFoundation/CoreFoundation.h>
#include <sys/socket.h>
#include <sys/types.h>

CF_IMPLICIT_BRIDGING_ENABLED
CF_ASSUME_NONNULL_BEGIN

typedef uint32_t SCNetworkConnectionFlags;

enum {
    kSCNetworkFlagsTransientConnection = 1U << 0,
    kSCNetworkFlagsReachable = 1U << 1,
    kSCNetworkFlagsConnectionRequired = 1U << 2,
    kSCNetworkFlagsConnectionAutomatic = 1U << 3,
    kSCNetworkFlagsInterventionRequired = 1U << 4,
    kSCNetworkFlagsIsLocalAddress = 1U << 16,
    kSCNetworkFlagsIsDirect = 1U << 17
};

CF_ASSUME_NONNULL_END
CF_IMPLICIT_BRIDGING_DISABLED

#endif
