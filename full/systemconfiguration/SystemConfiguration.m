#import <Foundation/NSObject.h>

#include "SystemConfiguration.h"

#include <arpa/inet.h>
#include <pthread.h>
#include <stdint.h>
#include <stdlib.h>
#include <string.h>

typedef enum {
    OpenReachabilityTargetName = 1,
    OpenReachabilityTargetAddress = 2,
    OpenReachabilityTargetAddressPair = 3
} OpenReachabilityTargetKind;

@interface OpenSCNetworkReachability : NSObject {
@public
    pthread_mutex_t stateLock;
    SCNetworkReachabilityFlags flags;
    Boolean flagsValid;
    SCNetworkReachabilityCallBack callback;
    SCNetworkReachabilityContext callbackContext;
    Boolean hasCallbackContext;
    dispatch_queue_t dispatchQueue;
    CFRunLoopRef runLoop;
    CFStringRef runLoopMode;
    OpenReachabilityTargetKind targetKind;
    char *targetName;
    struct sockaddr_storage localAddress;
    struct sockaddr_storage remoteAddress;
    Boolean hasLocalAddress;
    Boolean hasRemoteAddress;
    OpenSCNetworkReachability *previousTarget;
    OpenSCNetworkReachability *nextTarget;
}
@end

static pthread_mutex_t openTargetsLock = PTHREAD_MUTEX_INITIALIZER;
static OpenSCNetworkReachability *openTargetsHead;
static SCNetworkReachabilityFlags openDefaultFlags;
static Boolean openDefaultFlagsValid;
static uint64_t openReachabilityGeneration;
static _Thread_local int openLastError;

OPEN_SYSTEMCONFIGURATION_EXPORT const CFStringRef
kCFErrorDomainSystemConfiguration =
    CFSTR("com.apple.SystemConfiguration");

static void openSetError(int status) {
    openLastError = status;
}

static size_t openAddressLength(const struct sockaddr *address) {
    if (address == NULL) {
        return 0;
    }
    if (address->sa_len >= sizeof(struct sockaddr) &&
        address->sa_len <= sizeof(struct sockaddr_storage)) {
        return address->sa_len;
    }
    switch (address->sa_family) {
    case AF_INET:
        return sizeof(struct sockaddr_in);
    case AF_INET6:
        return sizeof(struct sockaddr_in6);
    default:
        return sizeof(struct sockaddr);
    }
}

static Boolean openAddressIsLoopback(const struct sockaddr *address) {
    if (address == NULL) {
        return false;
    }
    if (address->sa_family == AF_INET) {
        const struct sockaddr_in *ipv4 = (const struct sockaddr_in *)address;
        return (ntohl(ipv4->sin_addr.s_addr) & 0xff000000U) == 0x7f000000U;
    }
    if (address->sa_family == AF_INET6) {
        const struct sockaddr_in6 *ipv6 = (const struct sockaddr_in6 *)address;
        return IN6_IS_ADDR_LOOPBACK(&ipv6->sin6_addr);
    }
    return false;
}

static Boolean openNameIsLoopback(const char *name) {
    return strcmp(name, "localhost") == 0 ||
        strcmp(name, "localhost.") == 0 ||
        strcmp(name, "127.0.0.1") == 0 ||
        strcmp(name, "::1") == 0;
}

static void openRegisterTarget(OpenSCNetworkReachability *target) {
    pthread_mutex_lock(&openTargetsLock);
    target->flags = openDefaultFlags;
    target->flagsValid = openDefaultFlagsValid;
    target->previousTarget = NULL;
    target->nextTarget = openTargetsHead;
    if (openTargetsHead != nil) {
        openTargetsHead->previousTarget = target;
    }
    openTargetsHead = target;
    pthread_mutex_unlock(&openTargetsLock);
}

static void openUnregisterTarget(OpenSCNetworkReachability *target) {
    pthread_mutex_lock(&openTargetsLock);
    if (target->previousTarget != nil) {
        target->previousTarget->nextTarget = target->nextTarget;
    } else if (openTargetsHead == target) {
        openTargetsHead = target->nextTarget;
    }
    if (target->nextTarget != nil) {
        target->nextTarget->previousTarget = target->previousTarget;
    }
    target->previousTarget = nil;
    target->nextTarget = nil;
    pthread_mutex_unlock(&openTargetsLock);
}

@implementation OpenSCNetworkReachability

- (instancetype)init {
    self = [super init];
    if (self != nil) {
        if (pthread_mutex_init(&stateLock, NULL) != 0) {
            [self release];
            return nil;
        }
        memset(&callbackContext, 0, sizeof(callbackContext));
        openRegisterTarget(self);
    }
    return self;
}

- (void)dealloc {
    openUnregisterTarget(self);
    pthread_mutex_lock(&stateLock);
    SCNetworkReachabilityContext context = callbackContext;
    Boolean releaseContext = hasCallbackContext;
    hasCallbackContext = false;
    callback = NULL;
    pthread_mutex_unlock(&stateLock);
    if (releaseContext && context.release != NULL && context.info != NULL) {
        context.release(context.info);
    }
    free(targetName);
    pthread_mutex_destroy(&stateLock);
    [super dealloc];
}

@end

static OpenSCNetworkReachability *openTarget(
    SCNetworkReachabilityRef target
) {
    return (OpenSCNetworkReachability *)(void *)target;
}

static SCNetworkReachabilityRef openCreateTarget(
    OpenReachabilityTargetKind kind
) {
    OpenSCNetworkReachability *target =
        [[OpenSCNetworkReachability alloc] init];
    if (target == nil) {
        openSetError(kSCStatusFailed);
        return NULL;
    }
    target->targetKind = kind;
    openSetError(kSCStatusOK);
    return (SCNetworkReachabilityRef)(void *)target;
}

SCNetworkReachabilityRef SCNetworkReachabilityCreateWithName(
    CFAllocatorRef allocator,
    const char *nodename
) {
    (void)allocator;
    if (nodename == NULL || nodename[0] == '\0') {
        openSetError(kSCStatusInvalidArgument);
        return NULL;
    }
    size_t length = strnlen(nodename, 1025);
    if (length > 1024) {
        openSetError(kSCStatusInvalidArgument);
        return NULL;
    }
    SCNetworkReachabilityRef result = openCreateTarget(OpenReachabilityTargetName);
    if (result == NULL) {
        return NULL;
    }
    OpenSCNetworkReachability *target = openTarget(result);
    target->targetName = malloc(length + 1);
    if (target->targetName == NULL) {
        [target release];
        openSetError(kSCStatusFailed);
        return NULL;
    }
    memcpy(target->targetName, nodename, length + 1);
    if (openNameIsLoopback(nodename)) {
        target->flags = kSCNetworkReachabilityFlagsReachable |
            kSCNetworkReachabilityFlagsIsLocalAddress |
            kSCNetworkReachabilityFlagsIsDirect;
        target->flagsValid = true;
    }
    return result;
}

SCNetworkReachabilityRef SCNetworkReachabilityCreateWithAddress(
    CFAllocatorRef allocator,
    const struct sockaddr *address
) {
    (void)allocator;
    if (address == NULL) {
        openSetError(kSCStatusInvalidArgument);
        return NULL;
    }
    SCNetworkReachabilityRef result =
        openCreateTarget(OpenReachabilityTargetAddress);
    if (result == NULL) {
        return NULL;
    }
    OpenSCNetworkReachability *target = openTarget(result);
    size_t length = openAddressLength(address);
    memcpy(&target->remoteAddress, address, length);
    target->hasRemoteAddress = true;
    if (openAddressIsLoopback(address)) {
        target->flags = kSCNetworkReachabilityFlagsReachable |
            kSCNetworkReachabilityFlagsIsLocalAddress |
            kSCNetworkReachabilityFlagsIsDirect;
        target->flagsValid = true;
    }
    return result;
}

SCNetworkReachabilityRef SCNetworkReachabilityCreateWithAddressPair(
    CFAllocatorRef allocator,
    const struct sockaddr *localAddress,
    const struct sockaddr *remoteAddress
) {
    (void)allocator;
    if (localAddress == NULL && remoteAddress == NULL) {
        openSetError(kSCStatusInvalidArgument);
        return NULL;
    }
    SCNetworkReachabilityRef result =
        openCreateTarget(OpenReachabilityTargetAddressPair);
    if (result == NULL) {
        return NULL;
    }
    OpenSCNetworkReachability *target = openTarget(result);
    if (localAddress != NULL) {
        memcpy(
            &target->localAddress,
            localAddress,
            openAddressLength(localAddress)
        );
        target->hasLocalAddress = true;
    }
    if (remoteAddress != NULL) {
        memcpy(
            &target->remoteAddress,
            remoteAddress,
            openAddressLength(remoteAddress)
        );
        target->hasRemoteAddress = true;
    }
    if ((remoteAddress != NULL && openAddressIsLoopback(remoteAddress)) ||
        (remoteAddress == NULL && openAddressIsLoopback(localAddress))) {
        target->flags = kSCNetworkReachabilityFlagsReachable |
            kSCNetworkReachabilityFlagsIsLocalAddress |
            kSCNetworkReachabilityFlagsIsDirect;
        target->flagsValid = true;
    }
    return result;
}

CFTypeID SCNetworkReachabilityGetTypeID(void) {
    return (CFTypeID)0x53435243U;
}

Boolean SCNetworkReachabilityGetFlags(
    SCNetworkReachabilityRef targetRef,
    SCNetworkReachabilityFlags *result
) {
    if (targetRef == NULL || result == NULL) {
        openSetError(kSCStatusInvalidArgument);
        return false;
    }
    OpenSCNetworkReachability *target = openTarget(targetRef);
    pthread_mutex_lock(&target->stateLock);
    Boolean valid = target->flagsValid;
    SCNetworkReachabilityFlags current = target->flags;
    pthread_mutex_unlock(&target->stateLock);
    if (!valid) {
        *result = 0;
        openSetError(kSCStatusReachabilityUnknown);
        return false;
    }
    *result = current;
    openSetError(kSCStatusOK);
    return true;
}

Boolean SCNetworkReachabilitySetCallback(
    SCNetworkReachabilityRef targetRef,
    SCNetworkReachabilityCallBack callout,
    SCNetworkReachabilityContext *context
) {
    if (targetRef == NULL || (callout != NULL && context != NULL &&
        context->version != 0)) {
        openSetError(kSCStatusInvalidArgument);
        return false;
    }
    OpenSCNetworkReachability *target = openTarget(targetRef);
    pthread_mutex_lock(&target->stateLock);
    SCNetworkReachabilityContext oldContext = target->callbackContext;
    Boolean releaseOldContext = target->hasCallbackContext;
    memset(&target->callbackContext, 0, sizeof(target->callbackContext));
    target->hasCallbackContext = false;
    target->callback = callout;
    if (callout != NULL && context != NULL) {
        target->callbackContext = *context;
        if (context->retain != NULL && context->info != NULL) {
            target->callbackContext.info =
                (void *)context->retain(context->info);
        }
        target->hasCallbackContext = true;
    }
    pthread_mutex_unlock(&target->stateLock);
    if (releaseOldContext && oldContext.release != NULL &&
        oldContext.info != NULL) {
        oldContext.release(oldContext.info);
    }
    openSetError(kSCStatusOK);
    return true;
}

Boolean SCNetworkReachabilitySetDispatchQueue(
    SCNetworkReachabilityRef targetRef,
    dispatch_queue_t queue
) {
    if (targetRef == NULL) {
        openSetError(kSCStatusInvalidArgument);
        return false;
    }
    OpenSCNetworkReachability *target = openTarget(targetRef);
    pthread_mutex_lock(&target->stateLock);
    if (queue != NULL && target->runLoop != NULL) {
        pthread_mutex_unlock(&target->stateLock);
        openSetError(kSCStatusNotifierActive);
        return false;
    }
    target->dispatchQueue = queue;
    pthread_mutex_unlock(&target->stateLock);
    openSetError(kSCStatusOK);
    return true;
}

Boolean SCNetworkReachabilityScheduleWithRunLoop(
    SCNetworkReachabilityRef targetRef,
    CFRunLoopRef runLoop,
    CFStringRef runLoopMode
) {
    if (targetRef == NULL || runLoop == NULL || runLoopMode == NULL) {
        openSetError(kSCStatusInvalidArgument);
        return false;
    }
    OpenSCNetworkReachability *target = openTarget(targetRef);
    pthread_mutex_lock(&target->stateLock);
    if (target->dispatchQueue != NULL || target->runLoop != NULL) {
        pthread_mutex_unlock(&target->stateLock);
        openSetError(kSCStatusNotifierActive);
        return false;
    }
    target->runLoop = runLoop;
    target->runLoopMode = runLoopMode;
    pthread_mutex_unlock(&target->stateLock);
    openSetError(kSCStatusOK);
    return true;
}

Boolean SCNetworkReachabilityUnscheduleFromRunLoop(
    SCNetworkReachabilityRef targetRef,
    CFRunLoopRef runLoop,
    CFStringRef runLoopMode
) {
    if (targetRef == NULL || runLoop == NULL || runLoopMode == NULL) {
        openSetError(kSCStatusInvalidArgument);
        return false;
    }
    OpenSCNetworkReachability *target = openTarget(targetRef);
    pthread_mutex_lock(&target->stateLock);
    if (target->runLoop != runLoop || target->runLoopMode != runLoopMode) {
        pthread_mutex_unlock(&target->stateLock);
        openSetError(kSCStatusInvalidArgument);
        return false;
    }
    target->runLoop = NULL;
    target->runLoopMode = NULL;
    pthread_mutex_unlock(&target->stateLock);
    openSetError(kSCStatusOK);
    return true;
}

static Boolean openUpdateTarget(
    OpenSCNetworkReachability *target,
    SCNetworkReachabilityFlags newFlags,
    Boolean valid
) {
    SCNetworkReachabilityCallBack callout = NULL;
    SCNetworkReachabilityContext context;
    Boolean releaseTemporaryContext = false;
    memset(&context, 0, sizeof(context));

    pthread_mutex_lock(&target->stateLock);
    Boolean changed = target->flags != newFlags || target->flagsValid != valid;
    target->flags = newFlags;
    target->flagsValid = valid;
    Boolean scheduled = target->dispatchQueue != NULL || target->runLoop != NULL;
    if (changed && valid && scheduled && target->callback != NULL) {
        callout = target->callback;
        context = target->callbackContext;
        if (target->hasCallbackContext && context.retain != NULL &&
            context.info != NULL) {
            context.info = (void *)context.retain(context.info);
            releaseTemporaryContext = true;
        }
    }
    pthread_mutex_unlock(&target->stateLock);

    if (callout != NULL) {
        callout(
            (SCNetworkReachabilityRef)(void *)target,
            newFlags,
            context.info
        );
    }
    if (releaseTemporaryContext && context.release != NULL) {
        context.release(context.info);
    }
    return true;
}

Boolean OpenSystemConfigurationSetReachabilityFlags(
    SCNetworkReachabilityRef targetRef,
    SCNetworkReachabilityFlags newFlags,
    Boolean valid
) {
    if (targetRef == NULL) {
        openSetError(kSCStatusInvalidArgument);
        return false;
    }
    openUpdateTarget(openTarget(targetRef), newFlags, valid);
    pthread_mutex_lock(&openTargetsLock);
    openReachabilityGeneration += 1;
    pthread_mutex_unlock(&openTargetsLock);
    openSetError(kSCStatusOK);
    return true;
}

void OpenSystemConfigurationSetDefaultReachability(
    SCNetworkReachabilityFlags newFlags,
    Boolean valid
) {
    pthread_mutex_lock(&openTargetsLock);
    openDefaultFlags = newFlags;
    openDefaultFlagsValid = valid;
    openReachabilityGeneration += 1;
    size_t count = 0;
    for (OpenSCNetworkReachability *target = openTargetsHead;
         target != nil;
         target = target->nextTarget) {
        count += 1;
    }
    OpenSCNetworkReachability **targets = count == 0
        ? NULL
        : calloc(count, sizeof(*targets));
    size_t retainedCount = 0;
    if (targets != NULL) {
        for (OpenSCNetworkReachability *target = openTargetsHead;
             target != nil;
             target = target->nextTarget) {
            targets[retainedCount++] = [target retain];
        }
    }
    pthread_mutex_unlock(&openTargetsLock);

    for (size_t index = 0; index < retainedCount; index += 1) {
        openUpdateTarget(targets[index], newFlags, valid);
        [targets[index] release];
    }
    free(targets);
    openSetError(kSCStatusOK);
}

uint64_t OpenSystemConfigurationReachabilityGeneration(void) {
    pthread_mutex_lock(&openTargetsLock);
    uint64_t result = openReachabilityGeneration;
    pthread_mutex_unlock(&openTargetsLock);
    return result;
}

CFErrorRef SCCopyLastError(void) {
    return NULL;
}

int SCError(void) {
    return openLastError;
}

const char *SCErrorString(int status) {
    switch (status) {
    case kSCStatusOK:
        return "Success";
    case kSCStatusFailed:
        return "Non-specific failure";
    case kSCStatusInvalidArgument:
        return "Invalid argument";
    case kSCStatusNotifierActive:
        return "Notifier is currently active";
    case kSCStatusReachabilityUnknown:
        return "Reachability cannot be determined";
    default:
        return "SystemConfiguration error";
    }
}
