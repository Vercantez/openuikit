/* 15_quartz -- a plain C Mach-O that DRAWS.
 *
 * The point of this fixture is isolation. Every other route to "a Darwin
 * binary rasterises on Linux" runs through Objective-C, and when a pixel comes
 * out wrong you cannot tell whether the rasteriser, the loader, libSystem's
 * libm or objc_msgSend is at fault. This one has no Objective-C in it at all:
 * C source, C API, one dylib (/usr/lib/libquartz.dylib) plus libSystem. If it
 * is byte-identical on both sides, a later Objective-C failure has one fewer
 * suspect.
 *
 * WHAT IT DRAWS, and why each stage is here rather than a prettier picture:
 *
 *   1 background        the flat-fill path and premultiplied blending
 *   2 axis-aligned rects  integer-boundary coverage; no antialiasing decisions
 *   3 alpha rects       source-over compositing with fractional coverage
 *   4 cubic bezier      flattening tolerance -- the first place two builds of
 *                       the same code can disagree by one pixel
 *   5 dashed stroke     the stroke converter, round caps and joins
 *   6 linear gradient   per-pixel interpolation over a scanline
 *   7 radial gradient   the same, but through a sqrt per pixel
 *   8 ROTATED text-less glyph-ish path   deliberately routed through
 *                       QZContextRotateCTM, because that is the ONE stage that
 *                       reaches a transcendental: cos/sin, which on macOS come
 *                       from Apple's Libm and here from glibc's. IEEE 754 pins
 *                       + - * / and sqrt and says nothing about sin or cos, so
 *                       if the two libms disagree by an ulp this is the stage
 *                       whose checksum moves. Keeping it last and separate is
 *                       what makes that diagnosable instead of mysterious.
 *   9 even-odd clip     clipping with a non-trivial winding rule
 *
 * After every stage it prints a checksum of the WHOLE backing store. Two runs
 * that differ therefore say which stage first differed, on stdout, before the
 * PNG is even written. That is the difference between "the PNG differs" and a
 * bug report.
 *
 * The checksum is FNV-1a: 5 lines, no dependency, and -- unlike a sum -- it
 * moves for a transposition. It is not a security hash and does not need to be.
 *
 * Output path is argv[1], defaulting to quartz_fixture.png in the cwd.
 * Built by tests/build_fixtures.sh with APPLE'S clang on macOS, like every
 * other fixture; see that script and docs/QUARTZ_MACHO.md §5.
 */
#include <quartz/quartz.h>
#include <stdio.h>
#include <string.h>

#define W 256
#define H 256

static unsigned long long fnv1a(const unsigned char *p, size_t n)
{
    unsigned long long h = 1469598103934665603ULL;
    for (size_t i = 0; i < n; i++) { h ^= p[i]; h *= 1099511628211ULL; }
    return h;
}

static int stage_no = 0;

/* Print the backing store's checksum plus a fixed set of probe pixels. The
 * probes are there so a human reading two logs side by side sees actual colour
 * values and not only a hash that says "different". */
static void stage(QZContextRef ctx, const char *what)
{
    const unsigned char *px = (const unsigned char *)QZBitmapContextGetData(ctx);
    size_t bpr = QZBitmapContextGetBytesPerRow(ctx);
    static const int probe[][2] = { {8,8}, {64,64}, {128,128}, {200,60}, {40,210} };
    printf("stage %d %-18s fnv1a=%016llx", ++stage_no, what,
           fnv1a(px, bpr * H));
    for (unsigned i = 0; i < sizeof(probe)/sizeof(probe[0]); i++) {
        const unsigned char *q = px + (size_t)probe[i][1] * bpr + (size_t)probe[i][0] * 4;
        printf("  %02x%02x%02x%02x", q[0], q[1], q[2], q[3]);
    }
    printf("\n");
}

int main(int argc, char **argv)
{
    const char *out = argc > 1 ? argv[1] : "quartz_fixture.png";

    QZContextRef ctx = QZBitmapContextCreate(NULL, W, H, 8, W * 4,
                                             kQZImageAlphaPremultipliedLast);
    if (!ctx) { fprintf(stderr, "QZBitmapContextCreate failed\n"); return 2; }

    printf("quartz fixture %dx%d bpr=%zu\n", (int)QZBitmapContextGetWidth(ctx),
           (int)QZBitmapContextGetHeight(ctx), QZBitmapContextGetBytesPerRow(ctx));

    /* 1 -- background */
    QZContextSetRGBFillColor(ctx, 0.09, 0.11, 0.16, 1.0);
    QZContextFillRect(ctx, QZRectMake(0, 0, W, H));
    stage(ctx, "background");

    /* 2 -- opaque axis-aligned rects on integer boundaries */
    QZContextSetRGBFillColor(ctx, 0.85, 0.24, 0.20, 1.0);
    QZContextFillRect(ctx, QZRectMake(16, 16, 48, 32));
    QZContextSetRGBFillColor(ctx, 0.20, 0.70, 0.35, 1.0);
    QZContextFillRect(ctx, QZRectMake(72, 16, 48, 32));
    stage(ctx, "rects");

    /* 3 -- translucent rects, overlapping, to exercise source-over */
    QZContextSetRGBFillColor(ctx, 0.95, 0.80, 0.10, 0.55);
    QZContextFillRect(ctx, QZRectMake(40.5, 32.25, 60, 40));
    QZContextSetRGBFillColor(ctx, 0.10, 0.45, 0.95, 0.45);
    QZContextFillRect(ctx, QZRectMake(70.75, 44.5, 60, 40));
    stage(ctx, "alpha-rects");

    /* 4 -- a cubic bezier, filled non-zero */
    QZContextBeginPath(ctx);
    QZContextMoveToPoint(ctx, 20, 120);
    QZContextAddCurveToPoint(ctx, 60, 200, 120, 60, 160, 140);
    QZContextAddCurveToPoint(ctx, 180, 180, 120, 210, 60, 190);
    QZContextClosePath(ctx);
    QZContextSetRGBFillColor(ctx, 0.55, 0.35, 0.85, 0.90);
    QZContextFillPath(ctx);
    stage(ctx, "bezier-fill");

    /* 5 -- a dashed stroke with round caps and joins */
    {
        QZFloat dash[2] = { 9.0, 5.0 };
        QZContextSetLineDash(ctx, 2.0, dash, 2);
        QZContextSetLineWidth(ctx, 5.5);
        QZContextSetLineCap(ctx, kQZLineCapRound);
        QZContextSetLineJoin(ctx, kQZLineJoinRound);
        QZContextSetRGBStrokeColor(ctx, 1.0, 0.55, 0.10, 1.0);
        QZContextBeginPath(ctx);
        QZContextMoveToPoint(ctx, 12, 100);
        QZContextAddLineToPoint(ctx, 90, 108);
        QZContextAddLineToPoint(ctx, 140, 70);
        QZContextAddLineToPoint(ctx, 240, 104);
        QZContextStrokePath(ctx);
        QZContextSetLineDash(ctx, 0, NULL, 0);
    }
    stage(ctx, "dashed-stroke");

    /* 6 -- linear gradient, clipped to a rect */
    {
        QZFloat locs[3] = { 0.0, 0.5, 1.0 };
        QZFloat comps[12] = { 1.00, 0.20, 0.30, 1.0,
                              0.20, 0.90, 0.90, 1.0,
                              0.15, 0.20, 0.80, 1.0 };
        QZGradientRef g = QZGradientCreate(locs, comps, 3);
        QZContextSaveGState(ctx);
        QZContextClipToRect(ctx, QZRectMake(150, 150, 90, 40));
        QZContextDrawLinearGradient(ctx, g, QZPointMake(150, 150), QZPointMake(240, 190), 0);
        QZContextRestoreGState(ctx);
        QZGradientRelease(g);
    }
    stage(ctx, "linear-gradient");

    /* 7 -- radial gradient, clipped to an ellipse */
    {
        QZFloat locs[2] = { 0.0, 1.0 };
        QZFloat comps[8] = { 1.0, 1.0, 0.85, 1.0,
                             0.30, 0.10, 0.45, 0.0 };
        QZGradientRef g = QZGradientCreate(locs, comps, 2);
        QZContextSaveGState(ctx);
        QZContextBeginPath(ctx);
        QZContextAddEllipseInRect(ctx, QZRectMake(150, 30, 90, 90));
        QZContextClip(ctx);
        QZContextDrawRadialGradient(ctx, g, QZPointMake(195, 75), 2.0,
                                    QZPointMake(195, 75), 46.0, 0);
        QZContextRestoreGState(ctx);
        QZGradientRelease(g);
    }
    stage(ctx, "radial-gradient");

    /* 8 -- THE TRANSCENDENTAL STAGE. QZContextRotateCTM is cos/sin; on macOS
     * that is Apple's Libm and under machorun it is glibc's, reached through
     * darwin/src/math.c (and, on an Apple target, very likely through the
     * __sincos_stret aggregate ABI rather than two calls). If any stage is
     * going to differ between the two runs, it is this one and the two after
     * it, because the rotation feeds them. */
    QZContextSaveGState(ctx);
    QZContextTranslateCTM(ctx, 196, 196);
    QZContextRotateCTM(ctx, 0.5235987755982988 /* pi/6 */);
    QZContextSetRGBFillColor(ctx, 0.95, 0.95, 0.98, 0.85);
    QZContextFillRect(ctx, QZRectMake(-34, -20, 68, 40));
    QZContextSetRGBStrokeColor(ctx, 0.10, 0.10, 0.12, 1.0);
    QZContextSetLineWidth(ctx, 2.0);
    QZContextStrokeRect(ctx, QZRectMake(-34, -20, 68, 40));
    QZContextRestoreGState(ctx);
    stage(ctx, "rotated");

    /* 9 -- even-odd clip: two overlapping circles, XOR region filled */
    QZContextSaveGState(ctx);
    QZContextBeginPath(ctx);
    QZContextAddEllipseInRect(ctx, QZRectMake(20, 200, 60, 46));
    QZContextAddEllipseInRect(ctx, QZRectMake(50, 200, 60, 46));
    QZContextEOClip(ctx);
    QZContextSetRGBFillColor(ctx, 0.20, 0.95, 0.70, 1.0);
    QZContextFillRect(ctx, QZRectMake(0, 190, 140, 66));
    QZContextRestoreGState(ctx);
    stage(ctx, "eo-clip");

    if (!QZContextWritePNG(ctx, out)) {
        fprintf(stderr, "QZContextWritePNG(%s) failed\n", out);
        QZContextRelease(ctx);
        return 3;
    }
    printf("wrote %s\n", out);

    QZContextRelease(ctx);
    return 0;
}
