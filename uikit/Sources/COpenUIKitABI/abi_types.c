/* SPM requires a compilable source file in a C target; the header is the
 * payload. This also gives both halves of the bridge one place to agree on
 * the vtable size at runtime. */
#include "include/openuikit_abi_types.h"

uint32_t openuikit_abi_hooks_size(void) {
    return (uint32_t)sizeof(openuikit_objc_hooks);
}
