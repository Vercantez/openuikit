#ifndef OPENUIKIT_SYSTEMCONFIGURATION_SCNETWORKREACHABILITY_H
#define OPENUIKIT_SYSTEMCONFIGURATION_SCNETWORKREACHABILITY_H

#include <CoreFoundation/CoreFoundation.h>
#include <dispatch/dispatch.h>
#include <sys/socket.h>
#include <sys/types.h>

#if defined(__GNUC__)
#define OPEN_SYSTEMCONFIGURATION_EXPORT \
    __attribute__((visibility("default")))
#else
#define OPEN_SYSTEMCONFIGURATION_EXPORT
#endif

CF_IMPLICIT_BRIDGING_ENABLED
CF_ASSUME_NONNULL_BEGIN

typedef const struct CF_BRIDGED_TYPE(id) __SCNetworkReachability
    *SCNetworkReachabilityRef;

typedef struct {
    CFIndex version;
    void * __nullable info;
    const void * __nonnull (* __nullable retain)(const void *info);
    void (* __nullable release)(const void *info);
    CFStringRef __nonnull (* __nullable copyDescription)(const void *info);
} SCNetworkReachabilityContext;

typedef CF_OPTIONS(uint32_t, SCNetworkReachabilityFlags) {
    kSCNetworkReachabilityFlagsTransientConnection = 1U << 0,
    kSCNetworkReachabilityFlagsReachable = 1U << 1,
    kSCNetworkReachabilityFlagsConnectionRequired = 1U << 2,
    kSCNetworkReachabilityFlagsConnectionOnTraffic = 1U << 3,
    kSCNetworkReachabilityFlagsInterventionRequired = 1U << 4,
    kSCNetworkReachabilityFlagsConnectionOnDemand = 1U << 5,
    kSCNetworkReachabilityFlagsIsLocalAddress = 1U << 16,
    kSCNetworkReachabilityFlagsIsDirect = 1U << 17,
    kSCNetworkReachabilityFlagsIsWWAN = 1U << 18,
    kSCNetworkReachabilityFlagsConnectionAutomatic =
        kSCNetworkReachabilityFlagsConnectionOnTraffic
};

typedef void (*SCNetworkReachabilityCallBack)(
    SCNetworkReachabilityRef target,
    SCNetworkReachabilityFlags flags,
    void * __nullable info
);

OPEN_SYSTEMCONFIGURATION_EXPORT SCNetworkReachabilityRef __nullable
SCNetworkReachabilityCreateWithAddress(
    CFAllocatorRef __nullable allocator,
    const struct sockaddr *address
);

OPEN_SYSTEMCONFIGURATION_EXPORT SCNetworkReachabilityRef __nullable
SCNetworkReachabilityCreateWithAddressPair(
    CFAllocatorRef __nullable allocator,
    const struct sockaddr * __nullable localAddress,
    const struct sockaddr * __nullable remoteAddress
);

OPEN_SYSTEMCONFIGURATION_EXPORT SCNetworkReachabilityRef __nullable
SCNetworkReachabilityCreateWithName(
    CFAllocatorRef __nullable allocator,
    const char *nodename
);

OPEN_SYSTEMCONFIGURATION_EXPORT CFTypeID
SCNetworkReachabilityGetTypeID(void);

OPEN_SYSTEMCONFIGURATION_EXPORT Boolean
SCNetworkReachabilityGetFlags(
    SCNetworkReachabilityRef target,
    SCNetworkReachabilityFlags *flags
);

OPEN_SYSTEMCONFIGURATION_EXPORT Boolean
SCNetworkReachabilitySetCallback(
    SCNetworkReachabilityRef target,
    SCNetworkReachabilityCallBack __nullable callout,
    SCNetworkReachabilityContext * __nullable context
);

OPEN_SYSTEMCONFIGURATION_EXPORT Boolean
SCNetworkReachabilityScheduleWithRunLoop(
    SCNetworkReachabilityRef target,
    CFRunLoopRef runLoop,
    CFStringRef runLoopMode
);

OPEN_SYSTEMCONFIGURATION_EXPORT Boolean
SCNetworkReachabilityUnscheduleFromRunLoop(
    SCNetworkReachabilityRef target,
    CFRunLoopRef runLoop,
    CFStringRef runLoopMode
);

OPEN_SYSTEMCONFIGURATION_EXPORT Boolean
SCNetworkReachabilitySetDispatchQueue(
    SCNetworkReachabilityRef target,
    dispatch_queue_t __nullable queue
);

CF_ASSUME_NONNULL_END
CF_IMPLICIT_BRIDGING_DISABLED

#endif
