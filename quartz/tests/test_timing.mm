/* Pull AppKit so we can attach CALayers to an off-screen NSWindow.
 * CMakeLists does not link AppKit; Darwin ld honors .linker_option. */
asm(".linker_option \"-framework\", \"AppKit\"");
#import <AppKit/AppKit.h>
#include "test_common.h"
#include <string.h>

static const double kCpTol = 1e-5;
static const double kSolveTol = 1e-3;

static int nearly(double apple, double qz, double tol, const char *tag) {
    double d = apple - qz;
    if (d < 0) d = -d;
    if (d > tol) {
        fprintf(stderr, "FAIL %s apple=%.8f qz=%.8f diff=%.8f (tol=%.4g)\n",
                tag, apple, qz, d, tol);
        return 1;
    }
    printf("PASS %s apple=%.8f qz=%.8f\n", tag, apple, qz);
    return 0;
}

static CALayer *host_layer(void) {
    static NSWindow *window = nil;
    static CALayer *host = nil;
    static dispatch_once_t once;
    dispatch_once(&once, ^{
        [NSApplication sharedApplication];
        [NSApp setActivationPolicy:NSApplicationActivationPolicyAccessory];
        window = [[NSWindow alloc]
            initWithContentRect:NSMakeRect(-4000, -4000, 256, 256)
                      styleMask:NSWindowStyleMaskBorderless
                        backing:NSBackingStoreBuffered
                          defer:NO];
        window.contentView.wantsLayer = YES;
        host = window.contentView.layer;
        host.bounds = CGRectMake(0, 0, 256, 256);
        [window orderBack:nil];
        [CATransaction flush];
        [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.05]];
    });
    return host;
}

static void commit_layer(CALayer *layer) {
    CALayer *host = host_layer();
    [host addSublayer:layer];
    [CATransaction flush];
    [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.02]];
}

static CALayer *apple_pres(CALayer *layer) {
    CALayer *pres = layer.presentationLayer;
    if (pres) return pres;
    [CATransaction flush];
    pres = layer.presentationLayer;
    if (pres) return pres;
    [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.05]];
    return layer.presentationLayer;
}

/* Freeze a hosted layer at local time t and read presentation opacity. */
static float apple_opacity_at(CALayer *layer, CFTimeInterval t) {
    [CATransaction begin];
    [CATransaction setDisableActions:YES];
    layer.speed = 0;
    layer.beginTime = 0;
    layer.timeOffset = t;
    [CATransaction commit];
    [CATransaction flush];
    CALayer *pres = apple_pres(layer);
    if (!pres) return -1.f;
    return pres.opacity;
}

static CALayer *make_apple_basic(CAMediaTimingFunction *tf) {
    CALayer *layer = [CALayer layer];
    layer.bounds = CGRectMake(0, 0, 40, 40);
    [CATransaction begin];
    [CATransaction setDisableActions:YES];
    layer.opacity = 0;
    layer.speed = 0;
    layer.beginTime = 0;
    layer.timeOffset = 0;
    [CATransaction commit];
    commit_layer(layer);

    CABasicAnimation *anim = [CABasicAnimation animationWithKeyPath:@"opacity"];
    anim.fromValue = @0.0;
    anim.toValue = @1.0;
    anim.duration = 1.0;
    anim.timingFunction = tf;
    anim.fillMode = kCAFillModeBoth;
    anim.removedOnCompletion = NO;
    anim.beginTime = 0;
    [layer addAnimation:anim forKey:@"opacity"];
    [CATransaction flush];
    [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.02]];
    return layer;
}

static CALayer *make_apple_keyframe(void) {
    CALayer *layer = [CALayer layer];
    layer.bounds = CGRectMake(0, 0, 40, 40);
    [CATransaction begin];
    [CATransaction setDisableActions:YES];
    layer.opacity = 0;
    layer.speed = 0;
    layer.beginTime = 0;
    layer.timeOffset = 0;
    [CATransaction commit];
    commit_layer(layer);

    CAKeyframeAnimation *anim = [CAKeyframeAnimation animationWithKeyPath:@"opacity"];
    anim.values = @[@0.0, @1.0, @0.0];
    anim.keyTimes = @[@0.0, @0.5, @1.0];
    anim.duration = 1.0;
    anim.calculationMode = kCAAnimationLinear;
    anim.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionLinear];
    anim.fillMode = kCAFillModeBoth;
    anim.removedOnCompletion = NO;
    anim.beginTime = 0;
    [layer addAnimation:anim forKey:@"opacity"];
    [CATransaction flush];
    [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.02]];
    return layer;
}

static int test_control_points(void) {
    struct {
        const char *qz_name;
        CAMediaTimingFunctionName apple_name;
    } names[] = {
        {"linear", kCAMediaTimingFunctionLinear},
        {"easeIn", kCAMediaTimingFunctionEaseIn},
        {"easeOut", kCAMediaTimingFunctionEaseOut},
        {"easeInEaseOut", kCAMediaTimingFunctionEaseInEaseOut},
        {"default", kCAMediaTimingFunctionDefault},
    };
    int fail = 0;
    for (size_t n = 0; n < sizeof(names) / sizeof(names[0]); n++) {
        QZMediaTimingFunctionRef qf = QZMediaTimingFunctionCreate(names[n].qz_name);
        CAMediaTimingFunction *af = [CAMediaTimingFunction functionWithName:names[n].apple_name];
        if (!qf || !af) {
            if (qf) QZMediaTimingFunctionRelease(qf);
            return qz_fail("control-point create");
        }
        for (int i = 0; i < 4; i++) {
            QZFloat qp[2] = {0, 0};
            float ap[2] = {0, 0};
            QZMediaTimingFunctionGetControlPoint(qf, i, qp);
            [af getControlPointAtIndex:(size_t)i values:ap];
            char tag[80];
            snprintf(tag, sizeof(tag), "%s cp[%d].x", names[n].qz_name, i);
            fail |= nearly(ap[0], qp[0], kCpTol, tag);
            snprintf(tag, sizeof(tag), "%s cp[%d].y", names[n].qz_name, i);
            fail |= nearly(ap[1], qp[1], kCpTol, tag);
        }
        QZMediaTimingFunctionRelease(qf);
    }
    return fail;
}

static int test_ease_in_ease_out_solve(void) {
    const double samples[] = {0.0, 0.25, 0.5, 0.75, 1.0};
    const int ns = (int)(sizeof(samples) / sizeof(samples[0]));

    QZMediaTimingFunctionRef qf = QZMediaTimingFunctionCreate("easeInEaseOut");
    if (!qf) return qz_fail("easeInEaseOut create");

    CAMediaTimingFunction *af =
        [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
    CALayer *alayer = make_apple_basic(af);

    QZLayerRef ql = QZLayerCreate();
    QZLayerSetOpacity(ql, 0);
    QZAnimationRef qa = QZBasicAnimationCreate("opacity");
    QZFloat from = 0, to = 1;
    QZBasicAnimationSetFromValue(qa, &from, 1);
    QZBasicAnimationSetToValue(qa, &to, 1);
    QZAnimationSetDuration(qa, 1);
    QZAnimationSetTimingFunction(qa, qf);
    QZLayerAddAnimation(ql, qa, "opacity");

    printf("easeInEaseOut solve (t  apple  qz_solve  qz_pres)\n");
    int fail = 0;
    for (int i = 0; i < ns; i++) {
        double t = samples[i];
        float apple = apple_opacity_at(alayer, t);
        if (apple < 0.f) {
            QZAnimationRelease(qa);
            QZLayerRelease(ql);
            QZMediaTimingFunctionRelease(qf);
            return qz_fail("apple easeInEaseOut presentationLayer nil");
        }
        QZFloat solved = QZMediaTimingFunctionSolve(qf, (QZFloat)t);
        QZLayerRef qp = QZLayerCopyPresentation(ql, (QZFloat)t);
        if (!qp) {
            QZAnimationRelease(qa);
            QZLayerRelease(ql);
            QZMediaTimingFunctionRelease(qf);
            return qz_fail("qz easeInEaseOut presentation");
        }
        QZFloat pres = QZLayerGetOpacity(qp);
        QZLayerRelease(qp);

        printf("  t=%.2f  apple=%.8f  solve=%.8f  pres=%.8f\n", t, apple, solved, pres);

        char tag[80];
        snprintf(tag, sizeof(tag), "easeInEaseOut solve t=%.2f", t);
        fail |= nearly(apple, solved, kSolveTol, tag);
        snprintf(tag, sizeof(tag), "easeInEaseOut pres t=%.2f", t);
        fail |= nearly(apple, pres, kSolveTol, tag);
    }

    QZAnimationRelease(qa);
    QZLayerRemoveAllAnimations(ql);
    QZLayerRelease(ql);
    QZMediaTimingFunctionRelease(qf);
    return fail;
}

static int test_keyframe_opacity(void) {
    const double samples[] = {0.25, 0.75};
    const int ns = (int)(sizeof(samples) / sizeof(samples[0]));

    CALayer *alayer = make_apple_keyframe();

    QZLayerRef ql = QZLayerCreate();
    QZLayerSetOpacity(ql, 0);
    QZAnimationRef qa = QZKeyframeAnimationCreate("opacity");
    QZFloat vals[3] = {0, 1, 0};
    QZFloat times[3] = {0, 0.5, 1};
    QZKeyframeAnimationSetValues(qa, vals, 3, 1);
    QZKeyframeAnimationSetKeyTimes(qa, times, 3);
    QZAnimationSetDuration(qa, 1);
    QZLayerAddAnimation(ql, qa, "opacity");

    printf("keyframe opacity (t  apple  qz)\n");
    int fail = 0;
    for (int i = 0; i < ns; i++) {
        double t = samples[i];
        float apple = apple_opacity_at(alayer, t);
        if (apple < 0.f) {
            QZAnimationRelease(qa);
            QZLayerRelease(ql);
            return qz_fail("apple keyframe presentationLayer nil");
        }
        QZLayerRef qp = QZLayerCopyPresentation(ql, (QZFloat)t);
        if (!qp) {
            QZAnimationRelease(qa);
            QZLayerRelease(ql);
            return qz_fail("qz keyframe presentation");
        }
        QZFloat qop = QZLayerGetOpacity(qp);
        QZLayerRelease(qp);

        printf("  t=%.2f  apple=%.8f  qz=%.8f\n", t, apple, qop);

        char tag[80];
        snprintf(tag, sizeof(tag), "keyframe opacity t=%.2f", t);
        fail |= nearly(apple, qop, kSolveTol, tag);
    }

    QZAnimationRelease(qa);
    QZLayerRemoveAllAnimations(ql);
    QZLayerRelease(ql);
    return fail;
}

int main(void) {
    int fail = 0;
    fail |= test_control_points();
    fail |= test_ease_in_ease_out_solve();
    fail |= test_keyframe_opacity();
    if (fail) return 1;
    qz_pass("timing");
    return 0;
}
