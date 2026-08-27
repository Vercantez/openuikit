/* gradient_probe.c -- the gradient path in C, with no Swift anywhere, at the
 * STOP COUNT OpenUIKit actually uses.
 *
 * The four gradient_* scenes are the last failures in the suite. A first
 * version of this probe used TWO stops -- the number in the scene JSON -- and
 * passed, which was misleading. UIGradientView does not pass the scene's stops
 * to Canvas: _CAGradientColorSpace.densify() piecewise-linearises CA's
 * interpolation with 24 subdivisions per segment, so two scene colours become
 * 25 stops (UIGradientView.swift:113, `let sub = 24`).
 *
 * This walks the stop count so the failure threshold is a measurement rather
 * than a guess.
 */
#include <stdio.h>
#include <quartz/quartz.h>

#define MAXSTOPS 64

static int one(QZContextRef ctx, int nstops)
{
    QZFloat locs[MAXSTOPS];
    QZFloat comps[MAXSTOPS * 4];
    for (int i = 0; i < nstops; i++) {
        double u = (nstops == 1) ? 0.0 : (double)i / (double)(nstops - 1);
        locs[i] = u;
        comps[i * 4 + 0] = 0.878 + (0.098 - 0.878) * u;
        comps[i * 4 + 1] = 0.192 + (0.443 - 0.192) * u;
        comps[i * 4 + 2] = 0.192 + (0.761 - 0.192) * u;
        comps[i * 4 + 3] = 1.0;
    }
    fprintf(stderr, "  stops=%2d  create...", nstops);
    QZGradientRef g = QZGradientCreate(locs, comps, (size_t)nstops);
    if (!g) { fprintf(stderr, " NULL\n"); return 0; }
    fprintf(stderr, " draw...");
    QZContextSaveGState(ctx);
    QZRect clip = { { 20, 20 }, { 80, 100 } };
    QZContextClipToRect(ctx, clip);
    QZPoint s = { 20, 20 }, e = { 20, 120 };
    QZContextDrawLinearGradient(ctx, g, s, e,
                                kQZGradientDrawsBeforeStartLocation |
                                kQZGradientDrawsAfterEndLocation);
    QZContextRestoreGState(ctx);
    QZGradientRelease(g);
    fprintf(stderr, " ok\n");
    return 1;
}

int main(void)
{
    const int W = 640, H = 280;
    QZContextRef ctx = QZBitmapContextCreate(NULL, (size_t)W, (size_t)H, 8, (size_t)W * 4, 0);
    if (!ctx) { fprintf(stderr, "QZBitmapContextCreate returned NULL\n"); return 1; }
    /* The real CTM: QuartzBackend.swift:78-79 y-flips before drawing. */
    QZContextTranslateCTM(ctx, 0, (QZFloat)H);
    QZContextScaleCTM(ctx, 2.0, -2.0);

    static const int counts[] = { 2, 4, 8, 15, 16, 17, 24, 25, 32, 48, 64 };
    for (unsigned i = 0; i < sizeof(counts) / sizeof(counts[0]); i++)
        if (!one(ctx, counts[i])) break;

    fprintf(stderr, "ALL STOP COUNTS OK\n");
    QZContextRelease(ctx);
    return 0;
}
