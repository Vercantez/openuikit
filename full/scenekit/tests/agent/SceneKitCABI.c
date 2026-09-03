/* Future EC2 C ABI probe. Not compiled by tests/acceptance/test_host.sh.
 * Isolated Swift sources currently own SCNVector3/SCNMatrix4 identities.
 * A later integrated run should install canonical headers/modulemap and
 * verify unmangled SCN* exports from libSceneKit.dylib.
 */
#include <stdio.h>

int scenekit_c_abi_probe(void) {
    puts("SCENEKIT_C_ABI_PROBE_PREPARED");
    return 0;
}
