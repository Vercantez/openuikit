/* Pull AppKit so we can attach CALayers to an off-screen NSWindow.
 * CMakeLists does not link AppKit; Darwin ld honors .linker_option. */
asm(".linker_option \"-framework\", \"AppKit\"");
#import <AppKit/AppKit.h>
#include "test_common.h"
#include <string.h>

static const double kGroupTol = 1e-3;
static const double kSpringTol = 0.02;

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

static int expect_qz(double got, double want, double tol, const char *tag) {
    double d = got - want;
    if (d < 0) d = -d;
    if (d > tol) {
        fprintf(stderr, "FAIL %s got=%.8f want=%.8f\n", tag, got, want);
        return 1;
    }
    printf("PASS %s %.8f\n", tag, got);
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

static CALayer *apple_pres_at(CALayer *layer, CFTimeInterval t) {
    [CATransaction begin];
    [CATransaction setDisableActions:YES];
    layer.speed = 0;
    layer.beginTime = 0;
    layer.timeOffset = t;
    [CATransaction commit];
    [CATransaction flush];
    return apple_pres(layer);
}

static int test_apple_group(void) {
    CALayer *alayer = [CALayer layer];
    alayer.bounds = CGRectMake(0, 0, 40, 40);
    [CATransaction begin];
    [CATransaction setDisableActions:YES];
    alayer.opacity = 0;
    alayer.position = CGPointMake(0, 0);
    [CATransaction commit];
    commit_layer(alayer);

    CAMediaTimingFunction *lin =
        [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionLinear];
    CABasicAnimation *op = [CABasicAnimation animationWithKeyPath:@"opacity"];
    op.fromValue = @0.0;
    op.toValue = @1.0;
    op.duration = 1.0;
    op.timingFunction = lin;

    CABasicAnimation *px = [CABasicAnimation animationWithKeyPath:@"position.x"];
    px.fromValue = @0.0;
    px.toValue = @40.0;
    px.duration = 1.0;
    px.timingFunction = lin;

    CAAnimationGroup *g = [CAAnimationGroup animation];
    g.animations = @[op, px];
    g.duration = 1.0;
    g.speed = 0;
    g.timeOffset = 0.5;
    g.timingFunction = lin;
    g.fillMode = kCAFillModeBoth;
    g.removedOnCompletion = NO;
    [alayer addAnimation:g forKey:@"group"];
    [CATransaction flush];

    CALayer *pres = apple_pres(alayer);
    if (!pres) return qz_fail("apple group presentationLayer nil");

    QZLayerRef ql = QZLayerCreate();
    QZLayerSetOpacity(ql, 0);
    QZLayerSetPosition(ql, QZPointMake(0, 0));

    QZAnimationRef qop = QZBasicAnimationCreate("opacity");
    QZFloat of = 0, ot = 1;
    QZBasicAnimationSetFromValue(qop, &of, 1);
    QZBasicAnimationSetToValue(qop, &ot, 1);
    QZAnimationSetDuration(qop, 1);

    QZAnimationRef qpx = QZBasicAnimationCreate("position.x");
    QZFloat xf = 0, xt = 40;
    QZBasicAnimationSetFromValue(qpx, &xf, 1);
    QZBasicAnimationSetToValue(qpx, &xt, 1);
    QZAnimationSetDuration(qpx, 1);

    QZAnimationRef qg = QZAnimationGroupCreate();
    if (!qg) {
        QZAnimationRelease(qop);
        QZAnimationRelease(qpx);
        QZLayerRelease(ql);
        return qz_fail("group create");
    }
    QZAnimationGroupAddAnimation(qg, qop);
    QZAnimationGroupAddAnimation(qg, qpx);
    QZAnimationSetDuration(qg, 1);
    QZLayerAddAnimation(ql, qg, "group");
    QZLayerRef qp = QZLayerCopyPresentation(ql, 0.5);
    if (!qp) {
        QZAnimationRelease(qg);
        QZAnimationRelease(qop);
        QZAnimationRelease(qpx);
        QZLayerRelease(ql);
        return qz_fail("qz group presentation");
    }

    int fail = 0;
    fail |= nearly(pres.opacity, QZLayerGetOpacity(qp), kGroupTol, "group opacity t=0.5");
    fail |= nearly(pres.position.x, QZLayerGetPosition(qp).x, kGroupTol, "group position.x t=0.5");

    QZLayerRelease(qp);
    QZAnimationRelease(qg);
    QZAnimationRelease(qop);
    QZAnimationRelease(qpx);
    QZLayerRemoveAllAnimations(ql);
    QZLayerRelease(ql);
    return fail;
}

static int test_qz_group_lerp(void) {
    QZLayerRef l = QZLayerCreate();
    QZLayerSetOpacity(l, 0);
    QZLayerSetPosition(l, QZPointMake(0, 10));

    QZAnimationRef op = QZBasicAnimationCreate("opacity");
    QZFloat of = 0, ot = 1;
    QZBasicAnimationSetFromValue(op, &of, 1);
    QZBasicAnimationSetToValue(op, &ot, 1);
    QZAnimationSetDuration(op, 1);

    QZAnimationRef px = QZBasicAnimationCreate("position.x");
    QZFloat xf = 0, xt = 40;
    QZBasicAnimationSetFromValue(px, &xf, 1);
    QZBasicAnimationSetToValue(px, &xt, 1);
    QZAnimationSetDuration(px, 1);

    QZAnimationRef g = QZAnimationGroupCreate();
    QZAnimationGroupAddAnimation(g, op);
    QZAnimationGroupAddAnimation(g, px);
    QZAnimationSetDuration(g, 1);
    QZLayerAddAnimation(l, g, "group");

    int fail = 0;
    QZLayerRef p0 = QZLayerCopyPresentation(l, 0);
    fail |= expect_qz(QZLayerGetOpacity(p0), 0, kGroupTol, "qz group opacity t=0");
    fail |= expect_qz(QZLayerGetPosition(p0).x, 0, kGroupTol, "qz group position.x t=0");
    fail |= expect_qz(QZLayerGetPosition(p0).y, 10, kGroupTol, "qz group position.y t=0");
    QZLayerRelease(p0);

    QZLayerRef p05 = QZLayerCopyPresentation(l, 0.5);
    fail |= expect_qz(QZLayerGetOpacity(p05), 0.5, kGroupTol, "qz group opacity t=0.5");
    fail |= expect_qz(QZLayerGetPosition(p05).x, 20, kGroupTol, "qz group position.x t=0.5");
    fail |= expect_qz(QZLayerGetPosition(p05).y, 10, kGroupTol, "qz group position.y t=0.5");
    QZLayerRelease(p05);

    QZLayerRef p1 = QZLayerCopyPresentation(l, 1);
    fail |= expect_qz(QZLayerGetOpacity(p1), 1, kGroupTol, "qz group opacity t=1");
    fail |= expect_qz(QZLayerGetPosition(p1).x, 40, kGroupTol, "qz group position.x t=1");
    QZLayerRelease(p1);

    QZAnimationRelease(op);
    QZAnimationRelease(px);
    QZAnimationRelease(g);
    QZLayerRemoveAllAnimations(l);
    QZLayerRelease(l);
    return fail;
}

static int test_apple_spring(void) {
    CALayer *alayer = [CALayer layer];
    alayer.bounds = CGRectMake(0, 0, 40, 40);
    [CATransaction begin];
    [CATransaction setDisableActions:YES];
    alayer.opacity = 0;
    [CATransaction commit];
    commit_layer(alayer);

    CASpringAnimation *anim = [CASpringAnimation animationWithKeyPath:@"opacity"];
    anim.fromValue = @0.0;
    anim.toValue = @1.0;
    anim.duration = 1.0;
    anim.speed = 0;
    anim.timeOffset = 0.5;
    anim.fillMode = kCAFillModeBoth;
    anim.removedOnCompletion = NO;
    [alayer addAnimation:anim forKey:@"opacity"];
    [CATransaction flush];

    CALayer *pres = apple_pres(alayer);
    if (!pres) return qz_fail("apple spring presentationLayer nil");

    QZLayerRef ql = QZLayerCreate();
    QZLayerSetOpacity(ql, 0);
    QZAnimationRef qa = QZSpringAnimationCreate("opacity");
    if (!qa) {
        QZLayerRelease(ql);
        return qz_fail("spring create");
    }
    QZFloat from = 0, to = 1;
    QZBasicAnimationSetFromValue(qa, &from, 1);
    QZBasicAnimationSetToValue(qa, &to, 1);
    QZAnimationSetDuration(qa, 1);
    QZLayerAddAnimation(ql, qa, "opacity");
    QZLayerRef qp = QZLayerCopyPresentation(ql, 0.5);
    if (!qp) {
        QZAnimationRelease(qa);
        QZLayerRelease(ql);
        return qz_fail("qz spring presentation");
    }

    int fail = nearly(pres.opacity, QZLayerGetOpacity(qp), kSpringTol, "spring opacity t=0.5");

    QZLayerRelease(qp);
    QZAnimationRelease(qa);
    QZLayerRemoveAllAnimations(ql);
    QZLayerRelease(ql);
    return fail;
}

static int test_apple_spring_times(void) {
    CALayer *alayer = [CALayer layer];
    alayer.bounds = CGRectMake(0, 0, 40, 40);
    [CATransaction begin];
    [CATransaction setDisableActions:YES];
    alayer.opacity = 0;
    alayer.speed = 0;
    alayer.beginTime = 0;
    alayer.timeOffset = 0;
    [CATransaction commit];
    commit_layer(alayer);

    CASpringAnimation *anim = [CASpringAnimation animationWithKeyPath:@"opacity"];
    anim.fromValue = @0.0;
    anim.toValue = @1.0;
    anim.duration = 1.0;
    anim.fillMode = kCAFillModeBoth;
    anim.removedOnCompletion = NO;
    anim.beginTime = 0;
    [alayer addAnimation:anim forKey:@"opacity"];
    [CATransaction flush];
    [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.02]];

    QZLayerRef ql = QZLayerCreate();
    QZLayerSetOpacity(ql, 0);
    QZAnimationRef qa = QZSpringAnimationCreate("opacity");
    QZFloat from = 0, to = 1;
    QZBasicAnimationSetFromValue(qa, &from, 1);
    QZBasicAnimationSetToValue(qa, &to, 1);
    QZAnimationSetDuration(qa, 1);
    QZLayerAddAnimation(ql, qa, "opacity");

    const double times[] = {0.0, 0.25, 0.5, 0.75, 1.0};
    int fail = 0;
    for (size_t i = 0; i < sizeof(times) / sizeof(times[0]); i++) {
        CALayer *pres = apple_pres_at(alayer, times[i]);
        if (!pres) {
            fail |= qz_fail("apple spring times presentationLayer nil");
            break;
        }
        QZLayerRef qp = QZLayerCopyPresentation(ql, (QZFloat)times[i]);
        if (!qp) {
            fail |= qz_fail("qz spring times presentation");
            break;
        }
        char tag[64];
        snprintf(tag, sizeof(tag), "spring opacity t=%.2f", times[i]);
        fail |= nearly(pres.opacity, QZLayerGetOpacity(qp), kSpringTol, tag);
        QZLayerRelease(qp);
    }

    QZAnimationRelease(qa);
    QZLayerRemoveAllAnimations(ql);
    QZLayerRelease(ql);
    return fail;
}

int main(void) {
    int fail = 0;
    fail |= test_qz_group_lerp();
    fail |= test_apple_group();
    fail |= test_apple_spring();
    fail |= test_apple_spring_times();
    if (fail) return 1;
    qz_pass("anim_group");
    return 0;
}
