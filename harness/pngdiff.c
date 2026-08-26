/* pngdiff -- say WHERE two PNGs differ, not just that they do.
 *
 *   pngdiff <oracle.png> <actual.png>
 *
 * The drawing fixtures (docs/FIXTURES.md rungs n, o, p) are graded by an EXACT
 * byte comparison of the PNG, which is the right verdict and a useless bug
 * report: `cmp` says "differ at byte 4137" and that is the last thing it can
 * tell you, because everything after the IHDR is deflate-compressed and a
 * single wrong pixel moves every byte downstream of it.
 *
 * So this tool decodes both images and reports, in bitmap coordinates (row 0
 * at the top, matching the probe pixels the fixtures print on stdout):
 *
 *   - the number of differing pixels, and how many differ by more than one
 *     level in any channel. That split is the first question worth asking: a
 *     large count that is entirely +/-1 is a rounding or an ulp story, a small
 *     count with large deltas is a wrong shape;
 *   - the bounding box of the difference, which usually names the drawing
 *     stage on sight;
 *   - the largest delta per channel, alpha included -- a premultiplication bug
 *     shows up as A=0 with large RGB;
 *   - the first few differing pixels with both RGBA values.
 *
 * ZERO differing pixels with differing FILE bytes is itself a finding and is
 * reported as one: the rasteriser agreed and the PNG ENCODER did not, which
 * points at deflate/filter-selection rather than at anything the loader did.
 *
 * Decoding is stb_image, taken from vendor/quartz/third_party -- the same
 * third-party header quartz itself already vendors (see
 * vendor/quartz/PROVENANCE.md; stb is dual MIT / public domain). Using it here
 * rather than adding a dependency keeps the harness buildable with nothing but
 * a C compiler on both hosts, which matters because NOTHING may be installed
 * on the macOS oracle host.
 *
 * Note the asymmetry that is deliberate: this tool NEVER writes anything. It
 * is a reporter. Baselines are written only by `--record`, only on Darwin.
 *
 * Exit status:  0 identical pixels   1 pixels differ
 *               2 geometry differs   3 could not read/decode an input
 */
#define STB_IMAGE_IMPLEMENTATION
#define STBI_ONLY_PNG
#define STBI_NO_LINEAR
#define STBI_NO_HDR
#include "stb_image.h"

#include <stdio.h>
#include <stdlib.h>

#define MAX_SHOWN 8

int main(int argc, char **argv)
{
    if (argc != 3) {
        fprintf(stderr, "usage: pngdiff <oracle.png> <actual.png>\n");
        return 3;
    }

    int aw = 0, ah = 0, an = 0, bw = 0, bh = 0, bn = 0;
    unsigned char *a = stbi_load(argv[1], &aw, &ah, &an, 4);
    if (!a) {
        fprintf(stderr, "pngdiff: cannot decode %s: %s\n", argv[1], stbi_failure_reason());
        return 3;
    }
    unsigned char *b = stbi_load(argv[2], &bw, &bh, &bn, 4);
    if (!b) {
        fprintf(stderr, "pngdiff: cannot decode %s: %s\n", argv[2], stbi_failure_reason());
        stbi_image_free(a);
        return 3;
    }

    printf("      oracle %dx%d (%d channels in file)\n", aw, ah, an);
    printf("      actual %dx%d (%d channels in file)\n", bw, bh, bn);

    if (aw != bw || ah != bh) {
        printf("      GEOMETRY DIFFERS -- there is no pixel correspondence to report.\n");
        stbi_image_free(a); stbi_image_free(b);
        return 2;
    }

    long total = (long)aw * ah;
    long ndiff = 0, nbig = 0;
    int x0 = aw, y0 = ah, x1 = -1, y1 = -1;
    int maxd[4] = { 0, 0, 0, 0 };
    int shown = 0;
    /* Collected first, printed after the summary: the summary is what a reader
     * needs to decide whether to keep reading. */
    struct { int x, y; unsigned char a[4], b[4]; } first[MAX_SHOWN];

    for (int y = 0; y < ah; y++) {
        for (int x = 0; x < aw; x++) {
            const unsigned char *pa = a + ((size_t)y * aw + x) * 4;
            const unsigned char *pb = b + ((size_t)y * aw + x) * 4;
            int worst = 0;
            for (int c = 0; c < 4; c++) {
                int d = pa[c] - pb[c];
                if (d < 0) d = -d;
                if (d > maxd[c]) maxd[c] = d;
                if (d > worst) worst = d;
            }
            if (!worst) continue;
            ndiff++;
            if (worst > 1) nbig++;
            if (x < x0) x0 = x;
            if (y < y0) y0 = y;
            if (x > x1) x1 = x;
            if (y > y1) y1 = y;
            if (shown < MAX_SHOWN) {
                first[shown].x = x; first[shown].y = y;
                for (int c = 0; c < 4; c++) {
                    first[shown].a[c] = pa[c];
                    first[shown].b[c] = pb[c];
                }
                shown++;
            }
        }
    }

    if (ndiff == 0) {
        printf("      pixels IDENTICAL (%ld of %ld) -- the file bytes differ but the\n", total, total);
        printf("      image does not. That is a PNG ENCODER difference (deflate level,\n");
        printf("      filter choice, chunk layout), not a rasteriser one. Look at\n");
        printf("      third_party/stb_image_write.h and at the two zlib paths, not at\n");
        printf("      the loader.\n");
        stbi_image_free(a); stbi_image_free(b);
        return 0;
    }

    printf("      differing pixels: %ld of %ld (%.4f%%), of which %ld differ by >1 level\n",
           ndiff, total, 100.0 * (double)ndiff / (double)total, nbig);
    printf("      bounding box: x %d..%d  y %d..%d  (%dx%d, bitmap coords, row 0 at top)\n",
           x0, x1, y0, y1, x1 - x0 + 1, y1 - y0 + 1);
    printf("      max channel delta: R=%d G=%d B=%d A=%d\n",
           maxd[0], maxd[1], maxd[2], maxd[3]);
    if (nbig == 0)
        printf("      every difference is +/-1 in some channel: a rounding or libm-ulp\n"
               "      story, not a wrong shape. docs/QUARTZ_MACHO.md section 3.\n");
    printf("      first %d differing pixels (x,y  oracle -> actual):\n", shown);
    for (int i = 0; i < shown; i++)
        printf("        (%3d,%3d)  %02x%02x%02x%02x -> %02x%02x%02x%02x\n",
               first[i].x, first[i].y,
               first[i].a[0], first[i].a[1], first[i].a[2], first[i].a[3],
               first[i].b[0], first[i].b[1], first[i].b[2], first[i].b[3]);

    stbi_image_free(a);
    stbi_image_free(b);
    return 1;
}
