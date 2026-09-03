/* dyld_objc_constant.c -- _dyld_is_objc_constant and _NSGetMachExecuteHeader.
 *
 * Both are dyld APIs Apple's libSystem exports and the x86 overlay links
 * import. Outside a shared cache, _dyld_is_objc_constant is false (there is
 * no shared-cache ObjC constant string). _NSGetMachExecuteHeader returns the
 * main executable's mach_header -- the same invariant dyld_images grades for
 * index 0: MH_MAGIC_64 and MH_EXECUTE.
 *
 * A C string is not an objc constant even on Darwin-with-a-cache, so false
 * is the oracle on both sides. The header shape is dyld's contract.
 *
 * Operator: tests/build_fixtures.sh dyld_objc_constant &&
 * harness/run_macos.sh --record dyld_objc_constant, then flip the manifest
 * oracle cell to `run`.
 */
#include <stdio.h>
#include <mach-o/loader.h>
#include <crt_externs.h>

/* Apple's dyld_priv.h; not in the public SDK we ship. */
extern int _dyld_is_objc_constant(int kind, const void *addr);

int main(void)
{
    static const char not_a_cfstring[] = "hello";
    const struct mach_header_64 *mh;
    int c;

    c = _dyld_is_objc_constant(1 /* dyld_objc_string_kind */, not_a_cfstring);
    printf("dyld_is_objc_constant   false=%d\n", c == 0);

    mh = (const struct mach_header_64 *)_NSGetMachExecuteHeader();
    printf("NSGetMachExecuteHeader  non-NULL=%d\n", mh != 0);
    if (mh) {
        printf("  magic is MH_MAGIC_64: %s\n",
               mh->magic == MH_MAGIC_64 ? "yes" : "NO");
        printf("  filetype is MH_EXECUTE: %s\n",
               mh->filetype == MH_EXECUTE ? "yes" : "NO");
    }
    puts("done");
    return 0;
}
