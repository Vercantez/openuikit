/* Pull AppKit so we can attach CALayers to an off-screen NSWindow.
 * CMakeLists does not link AppKit; Darwin ld honors .linker_option. */
asm(".linker_option \"-framework\", \"AppKit\"");
#import <AppKit/AppKit.h>
#include "test_common.h"
#include <string.h>

static const double kTol = 0.02;

static int nearly(double apple, double qz, const char *tag) {
    double d = apple - qz;
    if (d < 0) d = -d;
    if (d > kTol) {
        fprintf(stderr, "FAIL %s apple=%.6f qz=%.6f diff=%.6f\n", tag, apple, qz, d);
        return 1;
    }
    printf("PASS %s apple=%.6f qz=%.6f\n", tag, apple, qz);
    return 0;
}

static int expect_qz(double got, double want, const char *tag) {
    double d = got - want;
    if (d < 0) d = -d;
    if (d > kTol) {
        fprintf(stderr, "FAIL %s got=%.6f want=%.6f\n", tag, got, want);
        return 1;
    }
    printf("PASS %s %.6f\n", tag, got);
    return 0;
}

static NSValue *val_point(CGFloat x, CGFloat y) {
    return [NSValue valueWithPoint:NSMakePoint(x, y)];
}

static NSValue *val_size(CGFloat w, CGFloat h) {
    return [NSValue valueWithSize:NSMakeSize(w, h)];
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

static CABasicAnimation *basic_anim(NSString *keyPath, id from, id to) {
    CABasicAnimation *anim = [CABasicAnimation animationWithKeyPath:keyPath];
    anim.fromValue = from;
    anim.toValue = to;
    anim.duration = 1.0;
    anim.speed = 0;
    anim.timeOffset = 0.5;
    anim.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionLinear];
    anim.fillMode = kCAFillModeBoth;
    anim.removedOnCompletion = NO;
    return anim;
}

static int test_apple_opacity(void) {
    CALayer *alayer = [CALayer layer];
    alayer.bounds = CGRectMake(0, 0, 40, 40);
    [CATransaction begin];
    [CATransaction setDisableActions:YES];
    alayer.opacity = 0;
    [CATransaction commit];
    commit_layer(alayer);

    CABasicAnimation *anim = basic_anim(@"opacity", @0.0, @1.0);
    [alayer addAnimation:anim forKey:@"opacity"];
    [CATransaction flush];

    CALayer *pres = apple_pres(alayer);
    if (!pres) return qz_fail("apple opacity presentationLayer nil");

    QZLayerRef ql = QZLayerCreate();
    QZLayerSetOpacity(ql, 0);
    QZAnimationRef qa = QZBasicAnimationCreate("opacity");
    QZFloat from = 0, to = 1;
    QZBasicAnimationSetFromValue(qa, &from, 1);
    QZBasicAnimationSetToValue(qa, &to, 1);
    QZAnimationSetDuration(qa, 1);
    QZLayerAddAnimation(ql, qa, "opacity");
    QZLayerRef qp = QZLayerCopyPresentation(ql, 0.5);
    if (!qp) {
        QZAnimationRelease(qa);
        QZLayerRelease(ql);
        return qz_fail("qz opacity presentation");
    }

    int fail = nearly(pres.opacity, QZLayerGetOpacity(qp), "opacity t=0.5");

    QZLayerRelease(qp);
    QZAnimationRelease(qa);
    QZLayerRemoveAllAnimations(ql);
    QZLayerRelease(ql);
    return fail;
}

static int test_apple_position(void) {
    const CGFloat fx = 20, fy = 40, tx = 80, ty = 100;
    CALayer *alayer = [CALayer layer];
    alayer.bounds = CGRectMake(0, 0, 40, 40);
    [CATransaction begin];
    [CATransaction setDisableActions:YES];
    alayer.position = CGPointMake(fx, fy);
    [CATransaction commit];
    commit_layer(alayer);

    CABasicAnimation *anim = basic_anim(@"position", val_point(fx, fy), val_point(tx, ty));
    [alayer addAnimation:anim forKey:@"position"];
    [CATransaction flush];

    CALayer *pres = apple_pres(alayer);
    if (!pres) return qz_fail("apple position presentationLayer nil");

    QZLayerRef ql = QZLayerCreate();
    QZLayerSetPosition(ql, QZPointMake(fx, fy));
    QZAnimationRef qa = QZBasicAnimationCreate("position");
    QZFloat from[2] = {fx, fy}, to[2] = {tx, ty};
    QZBasicAnimationSetFromValue(qa, from, 2);
    QZBasicAnimationSetToValue(qa, to, 2);
    QZAnimationSetDuration(qa, 1);
    QZLayerAddAnimation(ql, qa, "position");
    QZLayerRef qp = QZLayerCopyPresentation(ql, 0.5);
    if (!qp) {
        QZAnimationRelease(qa);
        QZLayerRelease(ql);
        return qz_fail("qz position presentation");
    }

    QZPoint qpos = QZLayerGetPosition(qp);
    int fail = 0;
    fail |= nearly(pres.position.x, qpos.x, "position.x t=0.5");
    fail |= nearly(pres.position.y, qpos.y, "position.y t=0.5");

    QZLayerRelease(qp);
    QZAnimationRelease(qa);
    QZLayerRemoveAllAnimations(ql);
    QZLayerRelease(ql);
    return fail;
}

static int test_apple_corner_and_size(void) {
    CALayer *alayer = [CALayer layer];
    [CATransaction begin];
    [CATransaction setDisableActions:YES];
    alayer.bounds = CGRectMake(0, 0, 10, 20);
    alayer.cornerRadius = 0;
    [CATransaction commit];
    commit_layer(alayer);

    [alayer addAnimation:basic_anim(@"cornerRadius", @0.0, @10.0) forKey:@"cornerRadius"];
    [alayer addAnimation:basic_anim(@"bounds.size", val_size(10, 20), val_size(50, 80))
                  forKey:@"bounds.size"];
    [CATransaction flush];

    CALayer *pres = apple_pres(alayer);
    if (!pres) return qz_fail("apple corner/size presentationLayer nil");

    QZLayerRef ql = QZLayerCreate();
    QZLayerSetBounds(ql, QZRectMake(0, 0, 10, 20));
    QZLayerSetCornerRadius(ql, 0);

    QZAnimationRef cr = QZBasicAnimationCreate("cornerRadius");
    QZFloat cr0 = 0, cr1 = 10;
    QZBasicAnimationSetFromValue(cr, &cr0, 1);
    QZBasicAnimationSetToValue(cr, &cr1, 1);
    QZAnimationSetDuration(cr, 1);
    QZLayerAddAnimation(ql, cr, "cornerRadius");

    QZAnimationRef sz = QZBasicAnimationCreate("bounds.size");
    QZFloat s0[2] = {10, 20}, s1[2] = {50, 80};
    QZBasicAnimationSetFromValue(sz, s0, 2);
    QZBasicAnimationSetToValue(sz, s1, 2);
    QZAnimationSetDuration(sz, 1);
    QZLayerAddAnimation(ql, sz, "bounds.size");

    QZLayerRef qp = QZLayerCopyPresentation(ql, 0.5);
    if (!qp) {
        QZAnimationRelease(cr);
        QZAnimationRelease(sz);
        QZLayerRelease(ql);
        return qz_fail("qz corner/size presentation");
    }

    int fail = 0;
    fail |= nearly(pres.cornerRadius, QZLayerGetCornerRadius(qp), "cornerRadius t=0.5");
    QZRect qb = QZLayerGetBounds(qp);
    fail |= nearly(pres.bounds.size.width, qb.size.width, "bounds.size.width t=0.5");
    fail |= nearly(pres.bounds.size.height, qb.size.height, "bounds.size.height t=0.5");

    QZLayerRelease(qp);
    QZAnimationRelease(cr);
    QZAnimationRelease(sz);
    QZLayerRemoveAllAnimations(ql);
    QZLayerRelease(ql);
    return fail;
}

static int test_qz_lerp_clamp(void) {
    QZLayerRef l = QZLayerCreate();
    QZLayerSetOpacity(l, 0.25);
    QZLayerSetPosition(l, QZPointMake(0, 0));
    QZLayerSetBounds(l, QZRectMake(0, 0, 0, 0));
    QZLayerSetCornerRadius(l, 1);

    QZAnimationRef op = QZBasicAnimationCreate("opacity");
    QZFloat of = 0, ot = 1;
    QZBasicAnimationSetFromValue(op, &of, 1);
    QZBasicAnimationSetToValue(op, &ot, 1);
    QZAnimationSetDuration(op, 1);
    QZLayerAddAnimation(l, op, "opacity");

    QZAnimationRef pos = QZBasicAnimationCreate("position");
    QZFloat pf[2] = {10, 20}, pt[2] = {110, 80};
    QZBasicAnimationSetFromValue(pos, pf, 2);
    QZBasicAnimationSetToValue(pos, pt, 2);
    QZAnimationSetDuration(pos, 1);
    QZLayerAddAnimation(l, pos, "position");

    QZAnimationRef cr = QZBasicAnimationCreate("cornerRadius");
    QZFloat cf = 0, ct = 20;
    QZBasicAnimationSetFromValue(cr, &cf, 1);
    QZBasicAnimationSetToValue(cr, &ct, 1);
    QZAnimationSetDuration(cr, 2);
    QZLayerAddAnimation(l, cr, "cornerRadius");

    QZAnimationRef sz = QZBasicAnimationCreate("bounds.size");
    QZFloat sf[2] = {0, 0}, st[2] = {100, 50};
    QZBasicAnimationSetFromValue(sz, sf, 2);
    QZBasicAnimationSetToValue(sz, st, 2);
    QZAnimationSetDuration(sz, 1);
    QZLayerAddAnimation(l, sz, "bounds.size");

    int fail = 0;
    QZLayerRef p0 = QZLayerCopyPresentation(l, 0);
    fail |= expect_qz(QZLayerGetOpacity(p0), 0, "qz opacity t=0");
    fail |= expect_qz(QZLayerGetPosition(p0).x, 10, "qz position.x t=0");
    QZLayerRelease(p0);

    QZLayerRef p05 = QZLayerCopyPresentation(l, 0.5);
    fail |= expect_qz(QZLayerGetOpacity(p05), 0.5, "qz opacity t=0.5");
    fail |= expect_qz(QZLayerGetPosition(p05).x, 60, "qz position.x t=0.5");
    fail |= expect_qz(QZLayerGetPosition(p05).y, 50, "qz position.y t=0.5");
    fail |= expect_qz(QZLayerGetCornerRadius(p05), 5, "qz cornerRadius t=0.5 / dur 2");
    fail |= expect_qz(QZLayerGetBounds(p05).size.width, 50, "qz bounds.w t=0.5");
    fail |= expect_qz(QZLayerGetBounds(p05).size.height, 25, "qz bounds.h t=0.5");
    QZLayerRelease(p05);

    QZLayerRef pneg = QZLayerCopyPresentation(l, -1);
    fail |= expect_qz(QZLayerGetOpacity(pneg), 0, "qz opacity clamp low");
    QZLayerRelease(pneg);

    QZLayerRef p2 = QZLayerCopyPresentation(l, 2);
    fail |= expect_qz(QZLayerGetOpacity(p2), 1, "qz opacity clamp high");
    fail |= expect_qz(QZLayerGetCornerRadius(p2), 20, "qz cornerRadius t=2");
    QZLayerRelease(p2);

    QZAnimationRelease(op);
    QZAnimationRelease(pos);
    QZAnimationRelease(cr);
    QZAnimationRelease(sz);
    QZLayerRemoveAllAnimations(l);
    QZLayerRelease(l);
    return fail;
}

int main(void) {
    int fail = 0;
    fail |= test_qz_lerp_clamp();
    fail |= test_apple_opacity();
    fail |= test_apple_position();
    fail |= test_apple_corner_and_size();
    if (fail) return 1;
    qz_pass("anim");
    return 0;
}
