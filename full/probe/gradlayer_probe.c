/* gradlayer_probe.c -- the GRADIENT LAYER path in C, no Swift anywhere.
 *
 * Bisected from the four failing gradient_* scenes:
 *   quartz backend + layers compositor      CRASH   (the default)
 *   quartz backend + renderpass compositor  renders
 *   swift  backend + renderpass compositor  renders
 * and a UIGradientView with a 0x0 frame -- whose drawContent returns
 * immediately on `bounds.isEmpty` -- ALSO crashes. So the fault is not in
 * drawing a gradient at all: it is in LayerBridge's QZGradientLayer path,
 * which the layers compositor takes and the render-pass compositor does not.
 *
 * An earlier probe exercised QZContextDrawLinearGradient at 2..64 stops and
 * passed every one, which is what ruled the shading primitive out and pointed
 * here. This one mirrors LayerBridge.configureGradient (LayerBridge.swift:652)
 * exactly: create the layer, set colours/locations/start/end, then render.
 */
#include <stdio.h>
#include <quartz/quartz.h>

int main(void)
{
    const int W = 640, H = 280;
    fprintf(stderr, "QZGradientLayerCreate...\n");
    QZLayerRef l = QZGradientLayerCreate();
    if (!l) { fprintf(stderr, "  returned NULL\n"); return 1; }
    fprintf(stderr, "  layer=%p\n", (void *)l);

    /* two stops, exactly as configureGradient builds them for a 2-colour view */
    QZFloat rgba[8] = { 0.878, 0.192, 0.192, 1.0,
                        0.098, 0.443, 0.761, 1.0 };
    QZFloat locs[2] = { 0.0, 1.0 };

    fprintf(stderr, "QZGradientLayerSetColors(n=2)...\n");
    QZGradientLayerSetColors(l, rgba, locs, 2);
    fprintf(stderr, "QZGradientLayerSetStartPoint...\n");
    QZGradientLayerSetStartPoint(l, (QZPoint){ 0.5, 0.0 });
    fprintf(stderr, "QZGradientLayerSetEndPoint...\n");
    QZGradientLayerSetEndPoint(l, (QZPoint){ 0.5, 1.0 });

    fprintf(stderr, "QZLayerSetFrame...\n");
    QZLayerSetFrame(l, (QZRect){ { 20, 20 }, { 80, 100 } });

    fprintf(stderr, "creating context and rendering the layer...\n");
    QZContextRef ctx = QZBitmapContextCreate(NULL, (size_t)W, (size_t)H, 8, (size_t)W * 4, 0);
    if (!ctx) { fprintf(stderr, "  context NULL\n"); return 1; }
    QZContextTranslateCTM(ctx, 0, (QZFloat)H);
    QZContextScaleCTM(ctx, 2.0, -2.0);
    QZLayerRenderInContext(l, ctx);

    fprintf(stderr, "GRADIENT LAYER OK\n");
    QZContextRelease(ctx);
    QZLayerRelease(l);
    return 0;
}
