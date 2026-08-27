/* 37_dyld_images.c -- rung (aj): the _dyld_* image table, which libSystem
 * cannot answer and only the loader can.
 *
 * CoreFoundation walks the loaded images to find bundles and to map addresses
 * back to binaries. On Darwin that table is dyld's; under machorun the loader
 * IS dyld, so MR.images is the table and libSystem has no view of it. That is
 * the same cause as _NSGetExecutablePath needing the MAIN image and dladdr
 * needing the CALLING one -- three gaps that look unrelated in a symbol
 * census and are one thing.
 *
 * WHAT THIS FIXTURE CAN AND CANNOT ASSERT. Not the count: macOS loads a
 * different set of system libraries than machorun does, and even two Macs
 * differ. Not the names or the addresses, for the same reason. What it CAN
 * assert are the INVARIANTS every correct implementation must satisfy and a
 * plausible wrong one would not:
 *
 *   index 0 is the MAIN EXECUTABLE -- dyld's contract, and here a consequence
 *   of registering an image before its dependencies. A loader that appended
 *   dependencies first would put a dylib at 0 and every bundle lookup would
 *   start from the wrong binary.
 *
 *   the header at index 0 really is a Mach-O header -- the magic word is
 *   MH_MAGIC_64, which catches an implementation returning a path, an offset,
 *   or the preferred base rather than the loaded one.
 *
 *   walking past the end returns NULL rather than aborting, because the
 *   standard idiom is to walk until the header comes back NULL, and an
 *   implementation that aborted would turn every correct caller into a crash.
 *
 *   the slide is CONSISTENT with the header: load address minus slide is the
 *   preferred base recorded in the file. That is the one arithmetic relation
 *   that ties the three calls together, and it is what catches a slide
 *   returned as unsigned when an image landed BELOW its preferred base -- a
 *   downward slide read as an enormous positive offset produces addresses
 *   that look like valid pointers and are not.
 *
 * The count is printed only as "more than one", since a process that loaded
 * exactly one image would mean the dylibs never arrived.
 */
#include <stdio.h>
#include <string.h>
#include <stdint.h>
#include <mach-o/dyld.h>
#include <mach-o/loader.h>

int main(void)
{
    uint32_t n = _dyld_image_count();
    const struct mach_header_64 *mh0;
    const char *name0;
    uint32_t i;
    int self_seen = 0;

    puts("== the image table");
    printf("  more than one image: %s\n", n > 1 ? "yes" : "NO");

    puts("== index 0 is the main executable");
    mh0   = (const struct mach_header_64 *)_dyld_get_image_header(0);
    name0 = _dyld_get_image_name(0);
    printf("  header non-NULL: %s  name non-NULL: %s\n",
           mh0 ? "yes" : "NO", name0 ? "yes" : "NO");
    if (mh0) {
        printf("  magic is MH_MAGIC_64: %s\n",
               mh0->magic == MH_MAGIC_64 ? "yes" : "NO");
        /* MH_EXECUTE is what makes it the MAIN image rather than a dylib. A
         * loader that registered dependencies first would report MH_DYLIB. */
        printf("  filetype is MH_EXECUTE: %s\n",
               mh0->filetype == MH_EXECUTE ? "yes" : "NO");
    }
    if (name0) {
        const char *base = strrchr(name0, '/');
        base = base ? base + 1 : name0;
        printf("  names this executable: %s\n",
               strcmp(base, "37_dyld_images") == 0 ? "yes" : "NO");
    }

    puts("== every image is well-formed, and the slide is consistent");
    {
        int bad_magic = 0, null_name = 0, slide_mismatch = 0;

        for (i = 0; i < n; i++) {
            const struct mach_header_64 *mh =
                (const struct mach_header_64 *)_dyld_get_image_header(i);
            const char *nm = _dyld_get_image_name(i);
            intptr_t slide = _dyld_get_image_vmaddr_slide(i);
            const struct load_command *lc;
            uint32_t c;

            if (!mh || mh->magic != MH_MAGIC_64) { bad_magic++; continue; }
            if (!nm) null_name++;

            /* THE ARITHMETIC RELATION. __TEXT's vmaddr in the file is the
             * preferred base; the header's actual address minus the slide must
             * equal it. This is what ties the three calls together, and what a
             * wrong-signed slide fails. */
            lc = (const struct load_command *)(mh + 1);
            for (c = 0; c < mh->ncmds; c++) {
                if (lc->cmd == LC_SEGMENT_64) {
                    const struct segment_command_64 *sg =
                        (const struct segment_command_64 *)lc;
                    if (strcmp(sg->segname, "__TEXT") == 0) {
                        uintptr_t want = (uintptr_t)sg->vmaddr + (uintptr_t)slide;
                        if (want != (uintptr_t)mh) slide_mismatch++;
                        break;
                    }
                }
                lc = (const struct load_command *)((const char *)lc + lc->cmdsize);
            }
            if (nm && strstr(nm, "37_dyld_images")) self_seen = 1;
        }
        printf("  images with a bad magic: %d\n", bad_magic);
        printf("  images with a NULL name: %d\n", null_name);
        printf("  images whose slide disagrees with __TEXT: %d\n", slide_mismatch);
        printf("  this executable appears in the table: %s\n",
               self_seen ? "yes" : "NO");
    }

    puts("== walking past the end returns NULL rather than aborting");
    printf("  header at n: %s  name at n: %s  slide at n: %s\n",
           _dyld_get_image_header(n) ? "NON-NULL" : "NULL",
           _dyld_get_image_name(n)   ? "NON-NULL" : "NULL",
           _dyld_get_image_vmaddr_slide(n) == 0 ? "0" : "NONZERO");
    printf("  header far past the end: %s\n",
           _dyld_get_image_header(n + 1000) ? "NON-NULL" : "NULL");

    puts("done");
    return 0;
}
