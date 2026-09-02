/* dup_images.c -- the loader's DEDUPE CONTRACT, and it is an ASYMMETRY.
 *
 * When is one dylib reachable at two paths ONE image, and when is it two?
 * Measured against real dyld (docs/DUP_IMAGES.md), the answer is not "when the
 * install names match" -- it is "when it is the same FILE":
 *
 *   SAME FILE via a symlink, two different LC_LOAD_DYLIB strings  -> ONE image
 *   TWO FILES, byte-identical, sharing one LC_ID_DYLIB            -> TWO images
 *
 * BOTH HALVES ARE HERE ON PURPOSE. A loader that deduped on install name would
 * pass the first and fail the second, and it would fail it in the direction
 * that looks like an improvement -- fewer images, no duplicate-class warnings,
 * a tidier table. That is why this fixture asserts the SPLIT rather than
 * asserting "one image": the interesting failure is over-deduping, and only the
 * second half can see it.
 *
 * The signal is a STATIC'S ADDRESS, not the image count, because it is the
 * thing that actually matters. Two images means two copies of every global the
 * dylib owns; when the dylib is CoreFoundation that is two runtime class
 * tables, two allocator sets and two preferences caches in one process. The
 * count is printed too, but the address is what a wrong answer corrupts.
 *
 * Layout built by tests/build_fixtures.sh:
 *
 *   bin/libdup_link.dylib                 the file
 *   bin/dup_images_alias/libdup_link.dylib   SYMLINK to it
 *   bin/libdup_link_mid.dylib             names it by the ALIAS path
 *   bin/libdup_copy.dylib                 the file
 *   bin/dup_images_alias/libdup_copy.dylib   a real COPY of it
 *   bin/libdup_copy_mid.dylib             names it by the copy's path
 *
 * Each `mid` has its LC_LOAD_DYLIB rewritten with install_name_tool so the two
 * dep STRINGS differ; without that the string test alone would dedupe both and
 * the fixture would grade nothing.
 */
#include <stdio.h>
#include <string.h>
#include <stdint.h>
#include <mach-o/dyld.h>

extern int *dup_link_token(void);      /* from libdup_link.dylib, linked directly */
extern int *dup_link_mid_token(void);  /* the same call, through the symlinked path */
extern int *dup_copy_token(void);      /* from libdup_copy.dylib, linked directly */
extern int *dup_copy_mid_token(void);  /* through the byte-identical COPY */

static int count_images(const char *needle)
{
    uint32_t n = _dyld_image_count(), i;
    int seen = 0;
    for (i = 0; i < n; i++) {
        const char *name = _dyld_get_image_name(i);
        if (name && strstr(name, needle)) seen++;
    }
    return seen;
}

int main(void)
{
    puts("== a SYMLINK is the same file: one image");
    printf("  direct and aliased token agree: %s\n",
           dup_link_token() == dup_link_mid_token() ? "yes" : "no");
    printf("  images named libdup_link.dylib: %d\n", count_images("libdup_link.dylib"));

    puts("== a COPY is a different file, even with the same install name: two images");
    printf("  direct and copied token agree: %s\n",
           dup_copy_token() == dup_copy_mid_token() ? "yes" : "no");
    printf("  images named libdup_copy.dylib: %d\n", count_images("libdup_copy.dylib"));

    puts("done");
    return 0;
}
