#import <Foundation/NSObject.h>

#include <SystemConfiguration/SystemConfiguration.h>

#include <arpa/inet.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

typedef struct {
    int callbacks;
    int retains;
    int releases;
    SCNetworkReachabilityFlags lastFlags;
} CallbackState;

static void requireCondition(int condition, const char *message) {
    if (!condition) {
        fprintf(stderr, "SystemConfigurationGuestRuntime: %s\n", message);
        exit(1);
    }
}

static const void *retainContext(const void *rawContext) {
    CallbackState *state = (CallbackState *)rawContext;
    state->retains += 1;
    return rawContext;
}

static void releaseContext(const void *rawContext) {
    CallbackState *state = (CallbackState *)rawContext;
    state->releases += 1;
}

static void reachabilityChanged(
    SCNetworkReachabilityRef target,
    SCNetworkReachabilityFlags flags,
    void *rawContext
) {
    (void)target;
    CallbackState *state = rawContext;
    requireCondition(state != NULL, "callback context is missing");
    state->callbacks += 1;
    state->lastFlags = flags;
}

static void releaseTarget(SCNetworkReachabilityRef target) {
    [(id)(void *)target release];
}

int main(void) {
    requireCondition(
        kCFErrorDomainSystemConfiguration == NULL &&
            SCCopyLastError() == NULL,
        "unavailable guest CFError boundary must fail closed"
    );
    requireCondition(
        SCNetworkReachabilityGetTypeID() == (CFTypeID)0x53435243U,
        "portable type identity drifted"
    );
    requireCondition(
        SCNetworkReachabilityCreateWithName(NULL, "") == NULL,
        "empty names must fail"
    );
    requireCondition(
        SCError() == kSCStatusInvalidArgument,
        "empty names must set invalid-argument status"
    );
    requireCondition(
        strcmp(SCErrorString(SCError()), "Invalid argument") == 0,
        "invalid-argument description drifted"
    );

    SCNetworkReachabilityRef target =
        SCNetworkReachabilityCreateWithName(NULL, "example.invalid");
    requireCondition(target != NULL, "named target creation failed");
    SCNetworkReachabilityFlags flags = UINT32_MAX;
    requireCondition(
        !SCNetworkReachabilityGetFlags(target, &flags),
        "external routes must start unknown"
    );
    requireCondition(flags == 0, "unknown reachability must clear flags");
    requireCondition(
        SCError() == kSCStatusReachabilityUnknown,
        "unknown reachability status drifted"
    );

    CallbackState callbackState = {0};
    SCNetworkReachabilityContext context = {
        .version = 0,
        .info = &callbackState,
        .retain = retainContext,
        .release = releaseContext,
        .copyDescription = NULL
    };
    requireCondition(
        SCNetworkReachabilitySetCallback(
            target,
            reachabilityChanged,
            &context
        ),
        "callback registration failed"
    );
    requireCondition(callbackState.retains == 1, "context was not retained");
    requireCondition(
        SCNetworkReachabilitySetDispatchQueue(
            target,
            (dispatch_queue_t)(uintptr_t)1
        ),
        "dispatch scheduling failed"
    );

    SCNetworkReachabilityFlags wifi =
        kSCNetworkReachabilityFlagsReachable |
        kSCNetworkReachabilityFlagsIsDirect;
    requireCondition(
        OpenSystemConfigurationSetReachabilityFlags(target, wifi, true),
        "Wi-Fi host update failed"
    );
    requireCondition(
        callbackState.callbacks == 1 && callbackState.lastFlags == wifi,
        "Wi-Fi callback was not delivered"
    );
    requireCondition(
        OpenSystemConfigurationSetReachabilityFlags(target, wifi, true),
        "duplicate host update failed"
    );
    requireCondition(
        callbackState.callbacks == 1,
        "duplicate flags must be coalesced"
    );

    SCNetworkReachabilityFlags cellular =
        kSCNetworkReachabilityFlagsReachable |
        kSCNetworkReachabilityFlagsIsWWAN;
    requireCondition(
        OpenSystemConfigurationSetReachabilityFlags(target, cellular, true),
        "cellular host update failed"
    );
    requireCondition(
        callbackState.callbacks == 2 && callbackState.lastFlags == cellular,
        "cellular callback was not delivered"
    );
    requireCondition(
        SCNetworkReachabilityGetFlags(target, &flags) && flags == cellular,
        "cellular flags were not retained"
    );

    requireCondition(
        SCNetworkReachabilitySetDispatchQueue(target, NULL),
        "dispatch unscheduling failed"
    );
    requireCondition(
        OpenSystemConfigurationSetReachabilityFlags(target, 0, true),
        "offline host update failed"
    );
    requireCondition(
        callbackState.callbacks == 2,
        "unscheduled target received a callback"
    );
    requireCondition(
        SCNetworkReachabilityScheduleWithRunLoop(
            target,
            (CFRunLoopRef)(uintptr_t)2,
            (CFStringRef)(uintptr_t)3
        ),
        "run-loop scheduling failed"
    );
    requireCondition(
        OpenSystemConfigurationSetReachabilityFlags(target, wifi, true),
        "run-loop host update failed"
    );
    requireCondition(
        callbackState.callbacks == 3 && callbackState.lastFlags == wifi,
        "run-loop callback was not delivered"
    );
    requireCondition(
        !SCNetworkReachabilitySetDispatchQueue(
            target,
            (dispatch_queue_t)(uintptr_t)1
        ),
        "mixed scheduling mechanisms must fail"
    );
    requireCondition(
        SCError() == kSCStatusNotifierActive,
        "mixed scheduling status drifted"
    );
    requireCondition(
        SCNetworkReachabilityUnscheduleFromRunLoop(
            target,
            (CFRunLoopRef)(uintptr_t)2,
            (CFStringRef)(uintptr_t)3
        ),
        "run-loop unscheduling failed"
    );

    SCNetworkReachabilityRef second =
        SCNetworkReachabilityCreateWithName(NULL, "second.invalid");
    requireCondition(second != NULL, "second target creation failed");
    uint64_t generation = OpenSystemConfigurationReachabilityGeneration();
    OpenSystemConfigurationSetDefaultReachability(cellular, true);
    requireCondition(
        OpenSystemConfigurationReachabilityGeneration() == generation + 1,
        "global generation did not advance exactly once"
    );
    requireCondition(
        SCNetworkReachabilityGetFlags(second, &flags) && flags == cellular,
        "global host state did not reach existing targets"
    );
    SCNetworkReachabilityRef third =
        SCNetworkReachabilityCreateWithName(NULL, "third.invalid");
    requireCondition(
        third != NULL && SCNetworkReachabilityGetFlags(third, &flags) &&
            flags == cellular,
        "global host state did not seed new targets"
    );

    struct sockaddr_in loopbackAddress;
    memset(&loopbackAddress, 0, sizeof(loopbackAddress));
    loopbackAddress.sin_len = sizeof(loopbackAddress);
    loopbackAddress.sin_family = AF_INET;
    loopbackAddress.sin_addr.s_addr = htonl(INADDR_LOOPBACK);
    SCNetworkReachabilityRef loopback =
        SCNetworkReachabilityCreateWithAddress(
            NULL,
            (const struct sockaddr *)&loopbackAddress
        );
    requireCondition(
        loopback != NULL && SCNetworkReachabilityGetFlags(loopback, &flags),
        "loopback must have deterministic reachability"
    );
    requireCondition(
        (flags & (kSCNetworkReachabilityFlagsReachable |
                  kSCNetworkReachabilityFlagsIsLocalAddress |
                  kSCNetworkReachabilityFlagsIsDirect)) ==
            (kSCNetworkReachabilityFlagsReachable |
             kSCNetworkReachabilityFlagsIsLocalAddress |
             kSCNetworkReachabilityFlagsIsDirect),
        "loopback flags drifted"
    );

    requireCondition(
        SCNetworkReachabilitySetCallback(target, NULL, NULL),
        "callback removal failed"
    );
    requireCondition(
        callbackState.retains == callbackState.releases,
        "callback context ownership is unbalanced"
    );

    releaseTarget(loopback);
    releaseTarget(third);
    releaseTarget(second);
    releaseTarget(target);

    puts(
        "SYSTEMCONFIGURATION_GUEST_OK "
        "reachability=unknown,host-driven,loopback "
        "flags=wifi,cellular,offline "
        "callbacks=dispatch,runloop,coalesced,cooperative "
        "context=balanced"
    );
    return 0;
}
