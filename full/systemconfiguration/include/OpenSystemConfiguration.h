#ifndef OPENUIKIT_OPEN_SYSTEMCONFIGURATION_H
#define OPENUIKIT_OPEN_SYSTEMCONFIGURATION_H

#include "SCNetworkReachability.h"

#ifdef __cplusplus
extern "C" {
#endif

/*
 * Explicit Linux-host boundary. The framework never infers that an external
 * route exists. A launcher or network monitor supplies a state here and every
 * live target receives a coalesced callback through its selected scheduling
 * mechanism. Callback delivery is cooperative and serial with this call; the
 * app host therefore invokes it from its lifecycle executor.
 */
OPEN_SYSTEMCONFIGURATION_EXPORT void
OpenSystemConfigurationSetDefaultReachability(
    SCNetworkReachabilityFlags flags,
    Boolean valid
);

OPEN_SYSTEMCONFIGURATION_EXPORT Boolean
OpenSystemConfigurationSetReachabilityFlags(
    SCNetworkReachabilityRef target,
    SCNetworkReachabilityFlags flags,
    Boolean valid
);

OPEN_SYSTEMCONFIGURATION_EXPORT uint64_t
OpenSystemConfigurationReachabilityGeneration(void);

#ifdef __cplusplus
}
#endif

#endif
