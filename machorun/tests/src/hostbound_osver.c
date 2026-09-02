/* os_system_version_get_current_version -- the ninth CHECK 5 name, split
 * out because a by-value struct return was a guess and Darwin SEGFAULTS on
 * it (oracle: exit 139 after hostbound_surface's twelve lines).
 *
 * MEASURED CALLER, not a header (the name is not in sdk/):
 *   libswiftCore `$__swift_stdlib_operatingSystemVersion` lazy invoke
 *   at vmaddr 0x39f9dc (artifacts/swift-macosx/arm64/libswiftCore.dylib):
 *
 *     str  wzr, [sp, #8]
 *     str  xzr, [sp]          ; 12-byte zeroed slot
 *     mov  x0, sp             ; OUT-POINTER in x0
 *     bl   _os_system_version_get_current_version
 *     ldr  x8, [sp]           ; reads MEMORY after the call -- not x0/x1
 *     ldr  w9, [sp, #8]
 *
 * BIND: this C fixture two-level binds it from libSystem
 * (`nm -m`: `(undefined) external _os_system_version_get_current_version
 * (from libSystem)`). libswiftCore binds the same spelling FLAT
 * (`weak external, dynamically looked up`).
 *
 * WHAT IS GRADED: that an out-pointer is written (major|minor|patch != 0).
 * The digits are NOT graded -- Darwin's provider reports the Mac's OS
 * (26.5.2 on the oracle) and ours reports the emulated SDK (26.1.0).
 *
 * No tests/expected/ files: norun:NEEDS_DARWIN_BASELINE until the operator
 * records on macOS.
 */
#include <stdint.h>
#include <stdio.h>

struct os_sysver { uint32_t major, minor, patch; };
void os_system_version_get_current_version(struct os_sysver *out);

int main(void)
{
    struct os_sysver v = { 0, 0, 0 };
    os_system_version_get_current_version(&v);
    printf("os_system_version     wrote=%d\n",
           (v.major | v.minor | v.patch) != 0);
    puts("done");
    return 0;
}
