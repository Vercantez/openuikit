#import <Cocoa/Cocoa.h>
#import <CoreGraphics/CoreGraphics.h>
#import <QuartzCore/QuartzCore.h>
#include "quartz/quartz.h"
#include "registry.h"

#include <algorithm>
#include <cmath>
#include <cstring>
#include <memory>
#include <string>
#include <vector>

#ifndef M_PI
#define M_PI 3.14159265358979323846
#endif

/* ------------------------------------------------------------------ gallery */

static constexpr int kShowW = 720;
static constexpr int kShowH = 720;

static void qz_clear(QZContextRef c, double r, double g, double b) {
    QZContextSetRGBFillColor(c, r, g, b, 1);
    QZContextFillRect(c, QZRectMake(0, 0, kShowW, kShowH));
}

static QZLayerRef circle_layer(double x, double y, double d,
                               double r, double g, double b, double a) {
    QZLayerRef l = QZShapeLayerCreate();
    QZLayerSetFrame(l, QZRectMake(x - d * 0.5, y - d * 0.5, d, d));
    QZMutablePathRef p = QZPathCreateMutable();
    QZPathAddEllipseInRect(p, nullptr, QZRectMake(0, 0, d, d));
    QZShapeLayerSetPath(l, p);
    QZPathRelease(p);
    QZShapeLayerSetFillColor(l, r, g, b, a);
    QZShapeLayerSetStrokeColor(l, 0, 0, 0, 0);
    return l;
}

static void draw_orbits(QZContextRef c, double t) {
    QZLayerRef root = QZLayerCreate();
    QZLayerSetFrame(root, QZRectMake(0, 0, kShowW, kShowH));
    QZLayerSetBackgroundColor(root, 0.067, 0.055, 0.047, 1);
    const double cx = kShowW * 0.5, cy = kShowH * 0.5;
    double rings[] = {110, 190, 270, 350};
    std::vector<QZLayerRef> live{root};
    for (double rad : rings) {
        QZLayerRef ring = QZShapeLayerCreate();
        QZLayerSetFrame(ring, QZRectMake(0, 0, kShowW, kShowH));
        QZMutablePathRef p = QZPathCreateMutable();
        QZPathAddEllipseInRect(p, nullptr, QZRectMake(cx - rad, cy - rad, rad * 2, rad * 2));
        QZShapeLayerSetPath(ring, p);
        QZPathRelease(p);
        QZShapeLayerSetFillColor(ring, 0, 0, 0, 0);
        QZShapeLayerSetStrokeColor(ring, 0.78, 0.62, 0.28, 0.35);
        QZShapeLayerSetLineWidth(ring, 1.2);
        QZLayerAddSublayer(root, ring);
        live.push_back(ring);
    }
    QZLayerRef sun = circle_layer(cx, cy, 72, 0.93, 0.42, 0.16, 1);
    QZLayerAddSublayer(root, sun);
    live.push_back(sun);
    struct Body { double r, size, speed, phase, cr, cg, cb; };
    Body bodies[] = {
        {110, 18, 1.40, 0.2, 0.85, 0.78, 0.70},
        {190, 28, 0.72, 1.1, 0.20, 0.48, 0.55},
        {270, 22, 0.45, 2.4, 0.89, 0.22, 0.16},
        {350, 14, 0.28, 4.0, 0.62, 0.55, 0.82},
    };
    for (const Body &b : bodies) {
        double a = t * b.speed + b.phase;
        double x = cx + std::cos(a) * b.r, y = cy + std::sin(a) * b.r;
        QZLayerRef p = circle_layer(x, y, b.size, b.cr, b.cg, b.cb, 1);
        QZLayerAddSublayer(root, p);
        live.push_back(p);
        if (b.size > 20) {
            QZLayerRef moon = circle_layer(x + std::cos(t * 3.1) * 26,
                                           y + std::sin(t * 3.1) * 26,
                                           8, 0.92, 0.88, 0.80, 1);
            QZLayerAddSublayer(root, moon);
            live.push_back(moon);
        }
    }
    QZLayerRenderInContext(root, c);
    for (auto it = live.rbegin(); it != live.rend(); ++it) QZLayerRelease(*it);
}

static void draw_fan(QZContextRef c, double t) {
    QZLayerRef root = QZLayerCreate();
    QZLayerSetFrame(root, QZRectMake(0, 0, kShowW, kShowH));
    QZLayerSetBackgroundColor(root, 0.09, 0.08, 0.07, 1);
    std::vector<QZLayerRef> live{root};
    const int n = 9;
    for (int i = 0; i < n; i++) {
        double u = (i - (n - 1) * 0.5) / (n * 0.5);
        double ang = u * 0.55 + std::sin(t * 0.6) * 0.08;
        QZLayerRef card = QZLayerCreate();
        QZLayerSetBounds(card, QZRectMake(0, 0, 210, 300));
        QZLayerSetPosition(card, QZPointMake(kShowW * 0.5, kShowH * 0.42));
        QZLayerSetAnchorPoint(card, QZPointMake(0.5, 0.08));
        QZLayerSetAffineTransform(card, QZAffineTransformMakeRotation(ang));
        QZLayerSetBackgroundColor(card, 0.78 + i * 0.02, 0.18 + i * 0.05, 0.14 + (n - i) * 0.04, 1);
        QZLayerSetCornerRadius(card, 18);
        QZLayerSetBorderWidth(card, 2);
        QZLayerSetBorderColor(card, 0.98, 0.93, 0.86, 0.35);
        QZLayerAddSublayer(root, card);
        live.push_back(card);
    }
    QZLayerRenderInContext(root, c);
    for (auto it = live.rbegin(); it != live.rend(); ++it) QZLayerRelease(*it);
}

static void draw_poster(QZContextRef c, double) {
    qz_clear(c, 0.90, 0.84, 0.74);
    QZContextSetRGBFillColor(c, 0.89, 0.23, 0.14, 1);
    QZContextFillEllipseInRect(c, QZRectMake(80, 160, 420, 420));
    QZContextSaveGState(c);
    QZContextTranslateCTM(c, 430, 280);
    QZContextRotateCTM(c, -0.28);
    QZContextSetRGBFillColor(c, 0.12, 0.11, 0.10, 0.88);
    QZContextFillRect(c, QZRectMake(-40, -210, 120, 420));
    QZContextRestoreGState(c);
    QZContextSetRGBFillColor(c, 0.18, 0.42, 0.44, 0.85);
    QZContextBeginPath(c);
    QZContextMoveToPoint(c, 80, 80);
    QZContextAddLineToPoint(c, 300, 40);
    QZContextAddLineToPoint(c, 640, 220);
    QZContextAddLineToPoint(c, 520, 90);
    QZContextClosePath(c);
    QZContextFillPath(c);
    QZContextSetRGBStrokeColor(c, 0.12, 0.09, 0.07, 1);
    QZContextSetLineWidth(c, 14);
    QZContextSetLineCap(c, kQZLineCapRound);
    QZContextBeginPath(c);
    QZContextAddArc(c, 360, 340, 250, 0.4, 4.1, 0);
    QZContextStrokePath(c);
    QZContextSetRGBFillColor(c, 0.95, 0.82, 0.22, 1);
    for (int i = 0; i < 6; i++) QZContextFillRect(c, QZRectMake(48 + i * 28, 48, 18, 18));
    QZContextSetRGBFillColor(c, 0.12, 0.09, 0.07, 1);
    QZContextBeginPath(c);
    const double cx = 560, cy = 560, R = 70;
    for (int i = 0; i < 5; i++) {
        double a = -M_PI / 2 + i * 4.0 * M_PI / 5.0;
        double x = cx + R * std::cos(a), y = cy + R * std::sin(a);
        if (i == 0) QZContextMoveToPoint(c, x, y);
        else QZContextAddLineToPoint(c, x, y);
    }
    QZContextClosePath(c);
    QZContextEOFillPath(c);
}

static void draw_ribbon(QZContextRef c, double t) {
    qz_clear(c, 0.06, 0.07, 0.09);
    QZContextSetLineCap(c, kQZLineCapRound);
    QZContextSetLineJoin(c, kQZLineJoinRound);
    const double cols[][4] = {
        {0.89, 0.23, 0.16, 1}, {0.93, 0.62, 0.18, 1},
        {0.22, 0.55, 0.52, 1}, {0.85, 0.80, 0.72, 0.7},
    };
    for (int i = 0; i < 4; i++) {
        QZContextSetRGBStrokeColor(c, cols[i][0], cols[i][1], cols[i][2], cols[i][3]);
        QZContextSetLineWidth(c, 22 - i * 4);
        double o = t * (0.4 + i * 0.07) + i;
        QZContextBeginPath(c);
        QZContextMoveToPoint(c, -20, 120 + i * 90);
        for (int k = 1; k <= 8; k++) {
            double x = k * (kShowW / 8.0);
            double y = 180 + i * 80 + std::sin(k * 0.9 + o) * (70 - i * 8);
            QZContextAddCurveToPoint(c, x - 40, y + std::cos(k + o) * 50, x - 10, y - 30, x, y);
        }
        QZContextStrokePath(c);
    }
}

static void draw_lattice(QZContextRef c, double t) {
    qz_clear(c, 0.10, 0.09, 0.08);
    QZContextSaveGState(c);
    QZContextBeginPath(c);
    QZContextAddEllipseInRect(c, QZRectMake(70, 70, 580, 580));
    QZContextClip(c);
    double shift = std::fmod(t * 28, 46.0);
    for (int i = -2; i < 24; i++) {
        QZContextSetRGBFillColor(c, 0.86, 0.28, 0.16, (i % 2) ? 0.92 : 0.55);
        QZContextFillRect(c, QZRectMake(0, i * 46.0 + shift, kShowW, 28));
    }
    QZContextRestoreGState(c);
    QZContextSetRGBStrokeColor(c, 0.95, 0.90, 0.82, 1);
    QZContextSetLineWidth(c, 10);
    QZContextStrokeEllipseInRect(c, QZRectMake(70, 70, 580, 580));
    QZContextSetRGBFillColor(c, 0.07, 0.06, 0.05, 1);
    QZContextFillEllipseInRect(c, QZRectMake(300, 300, 120, 120));
}

static void draw_lanterns(QZContextRef c, double t) {
    qz_clear(c, 0.05, 0.05, 0.07);
    struct L { double x, y, d, r, g, b; };
    L ls[] = {
        {160, 200, 140, 0.91, 0.35, 0.12}, {360, 420, 220, 0.88, 0.22, 0.14},
        {520, 180, 160, 0.90, 0.55, 0.16}, {240, 500, 100, 0.20, 0.45, 0.50},
        {560, 480, 130, 0.62, 0.28, 0.55}, {400, 220, 90,  0.95, 0.82, 0.40},
    };
    for (int i = 0; i < 6; i++) {
        double bob = std::sin(t * 1.3 + i) * 12;
        QZContextSetShadowWithColor(c, QZSizeMake(8, -14), 18, 0, 0, 0, 0.55);
        QZContextSetRGBFillColor(c, ls[i].r, ls[i].g, ls[i].b, 0.88);
        QZContextFillEllipseInRect(c, QZRectMake(ls[i].x - ls[i].d * 0.5,
                                                ls[i].y - ls[i].d * 0.5 + bob,
                                                ls[i].d, ls[i].d));
    }
}

struct ShowPiece {
    const char *name;
    const char *blurb;
    bool animated;
    void (*draw)(QZContextRef, double);
};
static const ShowPiece kShow[] = {
    {"ORBITS",   "QZLayer compositor · live clockwork", true,  draw_orbits},
    {"FAN",      "anchor-point cards · affine spin",     true,  draw_fan},
    {"POSTER",   "fills, arcs, even-odd star",           false, draw_poster},
    {"RIBBON",   "cubic strokes · round caps",           true,  draw_ribbon},
    {"LATTICE",  "circle clip · marching bars",          true,  draw_lattice},
    {"LANTERNS", "shadows + translucent discs",          true,  draw_lanterns},
};
static const int kShowCount = 6;

/* ------------------------------------------------------------------ live CA */

static void qz_add_basic(QZLayerRef layer, const char *keyPath, const QZFloat *from,
                         const QZFloat *to, size_t n, double dur, const char *timing,
                         const char *key) {
    QZAnimationRef a = QZBasicAnimationCreate(keyPath);
    QZBasicAnimationSetFromValue(a, from, n);
    QZBasicAnimationSetToValue(a, to, n);
    QZAnimationSetDuration(a, dur);
    if (timing) {
        QZMediaTimingFunctionRef tf = QZMediaTimingFunctionCreate(timing);
        QZAnimationSetTimingFunction(a, tf);
        QZMediaTimingFunctionRelease(tf);
    }
    QZLayerAddAnimation(layer, a, key);
    QZAnimationRelease(a);
}

static CABasicAnimation *apple_basic(NSString *keyPath, id from, id to, double dur, NSString *timing) {
    CABasicAnimation *a = [CABasicAnimation animationWithKeyPath:keyPath];
    a.fromValue = from;
    a.toValue = to;
    a.duration = dur;
    a.removedOnCompletion = NO;
    a.fillMode = kCAFillModeBoth;
    if (timing)
        a.timingFunction = [CAMediaTimingFunction functionWithName:timing];
    return a;
}

static CGColorRef cgcol(double r, double g, double b, double a) {
    return CGColorCreateGenericRGB(r, g, b, a);
}

struct AnimDemo {
    const char *name;
    const char *blurb;
    double duration;
    bool pingpong;
    void (*build_qz)(QZLayerRef root, int w, int h, std::vector<QZLayerRef> *live);
    void (*build_apple)(CALayer *root, int w, int h);
};

static QZLayerRef qz_card(std::vector<QZLayerRef> *live, QZLayerRef parent,
                          double x, double y, double w, double h,
                          double r, double g, double b, double rad) {
    QZLayerRef l = QZLayerCreate();
    QZLayerSetBounds(l, QZRectMake(0, 0, w, h));
    QZLayerSetPosition(l, QZPointMake(x, y));
    QZLayerSetBackgroundColor(l, r, g, b, 1);
    QZLayerSetCornerRadius(l, rad);
    QZLayerAddSublayer(parent, l);
    live->push_back(l);
    return l;
}

static void anim_qz_pulse(QZLayerRef root, int w, int h, std::vector<QZLayerRef> *live) {
    QZLayerSetBackgroundColor(root, 0.10, 0.09, 0.08, 1);
    QZLayerRef c = qz_card(live, root, w * 0.5, h * 0.5, 140, 140, 0.89, 0.23, 0.14, 28);
    QZFloat a0 = 0.18, a1 = 1;
    qz_add_basic(c, "opacity", &a0, &a1, 1, 1.1, "easeInEaseOut", "op");
}
static void anim_apple_pulse(CALayer *root, int w, int h) {
    root.backgroundColor = cgcol(0.10, 0.09, 0.08, 1);
    CALayer *c = [CALayer layer];
    c.bounds = CGRectMake(0, 0, 140, 140);
    c.position = CGPointMake(w * 0.5, h * 0.5);
    c.backgroundColor = cgcol(0.89, 0.23, 0.14, 1);
    c.cornerRadius = 28;
    [root addSublayer:c];
    [c addAnimation:apple_basic(@"opacity", @0.18, @1.0, 1.1,
                                kCAMediaTimingFunctionEaseInEaseOut) forKey:@"op"];
}

static void anim_qz_slide(QZLayerRef root, int w, int h, std::vector<QZLayerRef> *live) {
    QZLayerSetBackgroundColor(root, 0.07, 0.07, 0.08, 1);
    double y = h * 0.5;
    QZLayerRef c = qz_card(live, root, 56, y, 72, 72, 0.95, 0.82, 0.22, 16);
    QZFloat from[2] = {56, y}, to[2] = {(QZFloat)w - 56, y};
    qz_add_basic(c, "position", from, to, 2, 1.4, "easeInEaseOut", "pos");
}
static void anim_apple_slide(CALayer *root, int w, int h) {
    root.backgroundColor = cgcol(0.07, 0.07, 0.08, 1);
    CALayer *c = [CALayer layer];
    c.bounds = CGRectMake(0, 0, 72, 72);
    c.position = CGPointMake(56, h * 0.5);
    c.backgroundColor = cgcol(0.95, 0.82, 0.22, 1);
    c.cornerRadius = 16;
    [root addSublayer:c];
    [c addAnimation:apple_basic(@"position",
                                [NSValue valueWithPoint:NSMakePoint(56, h * 0.5)],
                                [NSValue valueWithPoint:NSMakePoint(w - 56, h * 0.5)],
                                1.4, kCAMediaTimingFunctionEaseInEaseOut) forKey:@"pos"];
}

static void anim_qz_spring(QZLayerRef root, int w, int h, std::vector<QZLayerRef> *live) {
    QZLayerSetBackgroundColor(root, 0.08, 0.07, 0.06, 1);
    QZLayerRef c = qz_card(live, root, w * 0.5, 48, 64, 64, 0.20, 0.55, 0.52, 32);
    QZAnimationRef a = QZSpringAnimationCreate("position");
    QZFloat from[2] = {(QZFloat)(w * 0.5), 48};
    QZFloat to[2] = {(QZFloat)(w * 0.5), (QZFloat)(h - 64)};
    QZBasicAnimationSetFromValue(a, from, 2);
    QZBasicAnimationSetToValue(a, to, 2);
    QZAnimationSetDuration(a, 1.6);
    QZLayerAddAnimation(c, a, "pos");
    QZAnimationRelease(a);
}
static void anim_apple_spring(CALayer *root, int w, int h) {
    root.backgroundColor = cgcol(0.08, 0.07, 0.06, 1);
    CALayer *c = [CALayer layer];
    c.bounds = CGRectMake(0, 0, 64, 64);
    c.position = CGPointMake(w * 0.5, 48);
    c.backgroundColor = cgcol(0.20, 0.55, 0.52, 1);
    c.cornerRadius = 32;
    [root addSublayer:c];
    CASpringAnimation *a = [CASpringAnimation animationWithKeyPath:@"position"];
    a.fromValue = [NSValue valueWithPoint:NSMakePoint(w * 0.5, 48)];
    a.toValue = [NSValue valueWithPoint:NSMakePoint(w * 0.5, h - 64)];
    a.mass = 1;
    a.stiffness = 100;
    a.damping = 10;
    a.duration = 1.6;
    a.removedOnCompletion = NO;
    a.fillMode = kCAFillModeBoth;
    [c addAnimation:a forKey:@"pos"];
}

static void anim_qz_morph(QZLayerRef root, int w, int h, std::vector<QZLayerRef> *live) {
    QZLayerSetBackgroundColor(root, 0.11, 0.09, 0.08, 1);
    QZLayerRef c = qz_card(live, root, w * 0.5, h * 0.5, 80, 80, 0.89, 0.23, 0.14, 8);
    QZAnimationRef g = QZAnimationGroupCreate();
    QZAnimationSetDuration(g, 1.3);
    QZAnimationRef sz = QZBasicAnimationCreate("bounds.size");
    QZFloat s0[2] = {80, 80}, s1[2] = {200, 120};
    QZBasicAnimationSetFromValue(sz, s0, 2);
    QZBasicAnimationSetToValue(sz, s1, 2);
    QZAnimationSetDuration(sz, 1.3);
    QZAnimationRef cr = QZBasicAnimationCreate("cornerRadius");
    QZFloat r0 = 8, r1 = 40;
    QZBasicAnimationSetFromValue(cr, &r0, 1);
    QZBasicAnimationSetToValue(cr, &r1, 1);
    QZAnimationSetDuration(cr, 1.3);
    QZMediaTimingFunctionRef tf = QZMediaTimingFunctionCreate("easeInEaseOut");
    QZAnimationSetTimingFunction(g, tf);
    QZAnimationGroupAddAnimation(g, sz);
    QZAnimationGroupAddAnimation(g, cr);
    QZLayerAddAnimation(c, g, "morph");
    QZAnimationRelease(sz);
    QZAnimationRelease(cr);
    QZAnimationRelease(g);
    QZMediaTimingFunctionRelease(tf);
}
static void anim_apple_morph(CALayer *root, int w, int h) {
    root.backgroundColor = cgcol(0.11, 0.09, 0.08, 1);
    CALayer *c = [CALayer layer];
    c.bounds = CGRectMake(0, 0, 80, 80);
    c.position = CGPointMake(w * 0.5, h * 0.5);
    c.backgroundColor = cgcol(0.89, 0.23, 0.14, 1);
    c.cornerRadius = 8;
    [root addSublayer:c];
    /* Children stay linear — a timingFunction on both the group and the
     * children double-eases on Apple (very slow start/end). QZ eases only
     * at the group, so match that. */
    CABasicAnimation *sz = apple_basic(@"bounds.size",
                                       [NSValue valueWithSize:NSMakeSize(80, 80)],
                                       [NSValue valueWithSize:NSMakeSize(200, 120)],
                                       1.3, nil);
    CABasicAnimation *cr = apple_basic(@"cornerRadius", @8, @40, 1.3, nil);
    CAAnimationGroup *g = [CAAnimationGroup animation];
    g.animations = @[sz, cr];
    g.duration = 1.3;
    g.removedOnCompletion = NO;
    g.fillMode = kCAFillModeBoth;
    g.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
    [c addAnimation:g forKey:@"morph"];
}

static void anim_qz_keys(QZLayerRef root, int w, int h, std::vector<QZLayerRef> *live) {
    QZLayerSetBackgroundColor(root, 0.06, 0.06, 0.07, 1);
    QZLayerRef c = qz_card(live, root, 48, 48, 36, 36, 0.93, 0.62, 0.18, 18);
    QZAnimationRef a = QZKeyframeAnimationCreate("position");
    QZFloat vals[] = {
        48, 48,
        (QZFloat)w - 48, 48,
        (QZFloat)w - 48, (QZFloat)h - 48,
        48, (QZFloat)h - 48,
        48, 48
    };
    QZKeyframeAnimationSetValues(a, vals, 5, 2);
    QZAnimationSetDuration(a, 2.4);
    QZLayerAddAnimation(c, a, "pos");
    QZAnimationRelease(a);
}
static void anim_apple_keys(CALayer *root, int w, int h) {
    root.backgroundColor = cgcol(0.06, 0.06, 0.07, 1);
    CALayer *c = [CALayer layer];
    c.bounds = CGRectMake(0, 0, 36, 36);
    c.position = CGPointMake(48, 48);
    c.backgroundColor = cgcol(0.93, 0.62, 0.18, 1);
    c.cornerRadius = 18;
    [root addSublayer:c];
    CAKeyframeAnimation *a = [CAKeyframeAnimation animationWithKeyPath:@"position"];
    a.values = @[
        [NSValue valueWithPoint:NSMakePoint(48, 48)],
        [NSValue valueWithPoint:NSMakePoint(w - 48, 48)],
        [NSValue valueWithPoint:NSMakePoint(w - 48, h - 48)],
        [NSValue valueWithPoint:NSMakePoint(48, h - 48)],
        [NSValue valueWithPoint:NSMakePoint(48, 48)],
    ];
    a.duration = 2.4;
    a.removedOnCompletion = NO;
    a.fillMode = kCAFillModeBoth;
    a.calculationMode = kCAAnimationLinear;
    [c addAnimation:a forKey:@"pos"];
}

static void anim_qz_spin(QZLayerRef root, int w, int h, std::vector<QZLayerRef> *live) {
    QZLayerSetBackgroundColor(root, 0.09, 0.08, 0.07, 1);
    QZLayerRef c = qz_card(live, root, w * 0.5, h * 0.5, 160, 48, 0.78, 0.22, 0.16, 8);
    QZFloat a0 = 0, a1 = (QZFloat)M_PI;
    qz_add_basic(c, "transform.rotation.z", &a0, &a1, 1, 1.5, "easeInEaseOut", "rot");
}
static void anim_apple_spin(CALayer *root, int w, int h) {
    root.backgroundColor = cgcol(0.09, 0.08, 0.07, 1);
    CALayer *c = [CALayer layer];
    c.bounds = CGRectMake(0, 0, 160, 48);
    c.position = CGPointMake(w * 0.5, h * 0.5);
    c.backgroundColor = cgcol(0.78, 0.22, 0.16, 1);
    c.cornerRadius = 8;
    [root addSublayer:c];
    [c addAnimation:apple_basic(@"transform.rotation.z", @0, @(M_PI), 1.5,
                                kCAMediaTimingFunctionEaseInEaseOut) forKey:@"rot"];
}

static const AnimDemo kAnim[] = {
    {"PULSE",  "CABasicAnimation opacity · easeInEaseOut", 1.1, true,  anim_qz_pulse,  anim_apple_pulse},
    {"SLIDE",  "position from/to · easeInEaseOut",         1.4, true,  anim_qz_slide,  anim_apple_slide},
    {"SPRING", "CASpringAnimation vs QZSpring",            1.6, false, anim_qz_spring, anim_apple_spring},
    {"MORPH",  "animation group · size + cornerRadius",    1.3, true,  anim_qz_morph,  anim_apple_morph},
    {"KEYS",   "CAKeyframeAnimation position loop",        2.4, false, anim_qz_keys,   anim_apple_keys},
    {"SPIN",   "transform.rotation.z",                     1.5, true,  anim_qz_spin,   anim_apple_spin},
};
static const int kAnimCount = 6;

/* ------------------------------------------------------------------ compare */

struct CatalogItem {
    bool ca = false;
    std::string name;
    void (*cg)(Backend &, int, int) = nullptr;
    void (*ca_build)(LayerTree &, int, int) = nullptr;
    double mae = 0, exact = 0, close = 0;
    int max_err = 0;
    bool scored = false;
};

struct CmpStats {
    double mae = 0, exact = 0, close = 0;
    int max_err = 0;
};

static void pack_rgba(std::vector<uint8_t> &dst, const uint8_t *src, size_t bpr, int w, int h) {
    dst.resize((size_t)w * h * 4);
    for (int y = 0; y < h; y++)
        memcpy(dst.data() + (size_t)y * w * 4, src + (size_t)y * bpr, (size_t)w * 4);
}

static CmpStats compare_pack(const uint8_t *a, size_t abpr, const uint8_t *q, size_t qbpr,
                             int w, int h, std::vector<uint8_t> &diff) {
    diff.assign((size_t)w * h * 4, 0);
    CmpStats s;
    int64_t n = (int64_t)w * h, exact = 0, close = 0;
    double sae = 0;
    int maxe = 0;
    for (int y = 0; y < h; y++) {
        const uint8_t *ar = a + (size_t)y * abpr;
        const uint8_t *qr = q + (size_t)y * qbpr;
        uint8_t *dr = diff.data() + (size_t)y * w * 4;
        for (int x = 0; x < w; x++) {
            int maxc = 0;
            for (int c = 0; c < 4; c++) {
                int d = (int)ar[x * 4 + c] - (int)qr[x * 4 + c];
                if (d < 0) d = -d;
                if (d > maxc) maxc = d;
                sae += d;
            }
            if (maxc == 0) exact++;
            if (maxc <= 8) close++;
            if (maxc > maxe) maxe = maxc;
            int amp = maxc * 8;
            if (amp > 255) amp = 255;
            dr[x * 4 + 0] = (uint8_t)amp;
            dr[x * 4 + 3] = 255;
        }
    }
    s.mae = sae / (n * 4.0);
    s.exact = 100.0 * exact / n;
    s.close = 100.0 * close / n;
    s.max_err = maxe;
    return s;
}

static bool render_item(const CatalogItem &it, int w, int h,
                        std::vector<uint8_t> &apple, std::vector<uint8_t> &qz,
                        std::vector<uint8_t> &diff, CmpStats &st) {
    if (!it.ca) {
        std::unique_ptr<Backend> A(make_apple_backend());
        std::unique_ptr<Backend> Q(make_qz_backend());
        if (!A->begin(w, h) || !Q->begin(w, h)) return false;
        it.cg(*A, w, h);
        it.cg(*Q, w, h);
        pack_rgba(apple, A->pixels(), A->bpr(), w, h);
        pack_rgba(qz, Q->pixels(), Q->bpr(), w, h);
        st = compare_pack(A->pixels(), A->bpr(), Q->pixels(), Q->bpr(), w, h, diff);
        A->end();
        Q->end();
        return true;
    }
    std::unique_ptr<LayerTree> A(make_apple_layers());
    std::unique_ptr<LayerTree> Q(make_qz_layers());
    if (!A->begin(w, h) || !Q->begin(w, h)) return false;
    it.ca_build(*A, w, h);
    it.ca_build(*Q, w, h);
    pack_rgba(apple, A->pixels(), A->bpr(), w, h);
    pack_rgba(qz, Q->pixels(), Q->bpr(), w, h);
    st = compare_pack(A->pixels(), A->bpr(), Q->pixels(), Q->bpr(), w, h, diff);
    A->end();
    Q->end();
    return true;
}

static CGImageRef cgimage_rgba(const uint8_t *src, int w, int h, bool premul) {
    NSData *data = [NSData dataWithBytes:src length:(size_t)w * h * 4];
    CGDataProviderRef provider = CGDataProviderCreateWithCFData((__bridge CFDataRef)data);
    CGColorSpaceRef cs = CGColorSpaceCreateWithName(kCGColorSpaceSRGB);
    CGBitmapInfo info = (premul ? kCGImageAlphaPremultipliedLast : kCGImageAlphaNoneSkipLast) |
                        kCGBitmapByteOrder32Big;
    CGImageRef img = CGImageCreate((size_t)w, (size_t)h, 8, 32, (size_t)w * 4, cs,
                                   info, provider, nullptr, false, kCGRenderingIntentDefault);
    CGColorSpaceRelease(cs);
    CGDataProviderRelease(provider);
    return img;
}

static CGImageRef cgimage_from_qz(QZContextRef ctx) {
    size_t w = QZBitmapContextGetWidth(ctx);
    size_t h = QZBitmapContextGetHeight(ctx);
    size_t bpr = QZBitmapContextGetBytesPerRow(ctx);
    const uint8_t *src = (const uint8_t *)QZBitmapContextGetData(ctx);
    std::vector<uint8_t> packed;
    pack_rgba(packed, src, bpr, (int)w, (int)h);
    return cgimage_rgba(packed.data(), (int)w, (int)h, true);
}

static NSColor *CInk()    { return [NSColor colorWithCalibratedRed:0.09 green:0.08 blue:0.07 alpha:1]; }
static NSColor *CRail()   { return [NSColor colorWithCalibratedRed:0.12 green:0.10 blue:0.09 alpha:1]; }
static NSColor *CTerr()   { return [NSColor colorWithCalibratedRed:0.89 green:0.23 blue:0.14 alpha:1]; }
static NSColor *CGold()   { return [NSColor colorWithCalibratedRed:0.95 green:0.82 blue:0.22 alpha:1]; }
static NSColor *CCream()  { return [NSColor colorWithCalibratedRed:0.93 green:0.88 blue:0.80 alpha:1]; }
static NSColor *CMute()   { return [NSColor colorWithCalibratedWhite:0.52 alpha:1]; }

/* ------------------------------------------------------------------ views */

@interface BitmapPane : NSView
@property (nonatomic) CGImageRef image;
@property (nonatomic) int srcW;
@property (nonatomic) int srcH;
@property (nonatomic, copy) NSString *caption;
@property (nonatomic, copy) void (^onHover)(int x, int y);
@end

@implementation BitmapPane {
    NSTrackingArea *_track;
}
- (BOOL)isFlipped { return YES; }
- (void)setImage:(CGImageRef)image {
    if (_image) CGImageRelease(_image);
    _image = image ? CGImageRetain(image) : nullptr;
    self.needsDisplay = YES;
}
- (void)dealloc { if (_image) CGImageRelease(_image); }
- (void)updateTrackingAreas {
    [super updateTrackingAreas];
    if (_track) [self removeTrackingArea:_track];
    _track = [[NSTrackingArea alloc] initWithRect:self.bounds
                                          options:NSTrackingMouseMoved | NSTrackingActiveInKeyWindow | NSTrackingInVisibleRect
                                            owner:self userInfo:nil];
    [self addTrackingArea:_track];
}
- (NSRect)imageRect {
    if (_srcW <= 0 || _srcH <= 0) return NSZeroRect;
    CGFloat pad = 28;
    CGFloat aw = self.bounds.size.width - 16;
    CGFloat ah = self.bounds.size.height - pad - 10;
    if (aw < 8 || ah < 8) return NSZeroRect;
    CGFloat s = std::min(aw / _srcW, ah / _srcH);
    /* snap to integer scale when close, so pixels stay crisp */
    if (s >= 1) s = floor(s);
    if (s < 1) s = aw / _srcW < ah / _srcH ? aw / _srcW : ah / _srcH;
    CGFloat dw = _srcW * s, dh = _srcH * s;
    return NSMakeRect((self.bounds.size.width - dw) * 0.5, pad, dw, dh);
}
- (BOOL)hitPixel:(NSPoint)p x:(int *)ox y:(int *)oy {
    NSRect r = [self imageRect];
    if (NSIsEmptyRect(r) || !NSPointInRect(p, r) || _srcW <= 0) return NO;
    *ox = (int)((p.x - r.origin.x) / r.size.width * _srcW);
    *oy = (int)((p.y - r.origin.y) / r.size.height * _srcH);
    if (*ox < 0 || *oy < 0 || *ox >= _srcW || *oy >= _srcH) return NO;
    return YES;
}
- (void)mouseMoved:(NSEvent *)e {
    NSPoint p = [self convertPoint:e.locationInWindow fromView:nil];
    int x = 0, y = 0;
    if ([self hitPixel:p x:&x y:&y] && self.onHover) self.onHover(x, y);
}
- (void)drawRect:(NSRect)dirty {
    [CInk() setFill];
    NSRectFill(self.bounds);
    NSRect ir = [self imageRect];
    if (!NSIsEmptyRect(ir)) {
        /* checker */
        CGFloat cell = 8;
        for (CGFloat y = ir.origin.y; y < NSMaxY(ir); y += cell) {
            for (CGFloat x = ir.origin.x; x < NSMaxX(ir); x += cell) {
                int cx = (int)((x - ir.origin.x) / cell);
                int cy = (int)((y - ir.origin.y) / cell);
                [(cx + cy) & 1 ? [NSColor colorWithWhite:0.16 alpha:1]
                               : [NSColor colorWithWhite:0.12 alpha:1] setFill];
                NSRectFill(NSIntersectionRect(ir, NSMakeRect(x, y, cell, cell)));
            }
        }
        if (_image) {
            CGContextRef cg = [NSGraphicsContext currentContext].CGContext;
            CGContextSaveGState(cg);
            CGContextSetInterpolationQuality(cg, kCGInterpolationNone);
            CGContextDrawImage(cg, NSRectToCGRect(ir), _image);
            CGContextRestoreGState(cg);
        }
        NSBezierPath *stroke = [NSBezierPath bezierPathWithRect:NSInsetRect(ir, -0.5, -0.5)];
        [[NSColor colorWithWhite:1 alpha:0.08] setStroke];
        stroke.lineWidth = 1;
        [stroke stroke];
    }
    if (self.caption) {
        NSDictionary *attrs = @{
            NSFontAttributeName: [NSFont monospacedSystemFontOfSize:10 weight:NSFontWeightBold],
            NSForegroundColorAttributeName: CMute()
        };
        [self.caption drawAtPoint:NSMakePoint(12, 8) withAttributes:attrs];
    }
}
@end

@interface FlippedDoc : NSView
@end
@implementation FlippedDoc
- (BOOL)isFlipped { return YES; }
@end

@interface KeyWindow : NSWindow
@end

@class DemoApp;

static void freeze_layer_time(CALayer *layer, double t) {
    if (!layer) return;
    layer.speed = 0;
    layer.beginTime = 0;
    layer.timeOffset = t;
    for (CALayer *ch in layer.sublayers) freeze_layer_time(ch, t);
}

static void strip_apple_layer(CALayer *layer) {
    if (!layer) return;
    NSArray<CALayer *> *kids = [layer.sublayers copy];
    for (CALayer *ch in kids) {
        strip_apple_layer(ch);
        [ch removeFromSuperlayer];
    }
    [layer removeAllAnimations];
}

@interface DemoApp : NSObject <NSApplicationDelegate, NSWindowDelegate>
@property (nonatomic, strong) NSWindow *window;
@property (nonatomic, strong) NSScrollView *listScroll;
@property (nonatomic, strong) NSStackView *list;
@property (nonatomic, strong) NSView *compareBox;
@property (nonatomic, strong) NSView *showBox;
@property (nonatomic, strong) BitmapPane *applePane;
@property (nonatomic, strong) BitmapPane *qzPane;
@property (nonatomic, strong) BitmapPane *diffPane;
@property (nonatomic, strong) BitmapPane *showPane;
@property (nonatomic, strong) NSTextField *titleLabel;
@property (nonatomic, strong) NSTextField *metaLabel;
@property (nonatomic, strong) NSTextField *pixelLabel;
@property (nonatomic, strong) NSTextField *scoreLabel;
@property (nonatomic, strong) NSSegmentedControl *modeSeg;
@property (nonatomic, strong) NSSegmentedControl *filterSeg;
@property (nonatomic, strong) NSSegmentedControl *sizeSeg;
@property (nonatomic) int mode;      /* 0 compare, 1 anim, 2 show */
@property (nonatomic) int filter;    /* 0 all, 1 cg, 2 ca */
@property (nonatomic) int sizeIdx;
@property (nonatomic) int selected;
@property (nonatomic) int showIdx;
@property (nonatomic) int animIdx;
@property (nonatomic, strong) NSWindow *animWin;
@property (nonatomic, strong) CALayer *animHost;
@property (nonatomic, strong) CALayer *appleAnimRoot;
@property (nonatomic) double t;
@property (nonatomic) BOOL paused;
@property (nonatomic, strong) NSTimer *timer;
- (void)keyDown:(NSEvent *)e;
@end

@implementation DemoApp {
    std::vector<CatalogItem> _items;
    std::vector<int> _visible;
    std::vector<uint8_t> _apple, _qz, _diff;
    int _bw, _bh;
    QZLayerRef _qzAnimRoot;
    std::vector<QZLayerRef> _qzAnimLive;
}

- (NSTextField *)label:(NSString *)s size:(CGFloat)size weight:(NSFontWeight)w color:(NSColor *)c {
    NSTextField *f = [NSTextField labelWithString:s];
    f.font = [NSFont systemFontOfSize:size weight:w];
    f.textColor = c;
    f.backgroundColor = [NSColor clearColor];
    f.bordered = NO;
    return f;
}

- (void)applicationDidFinishLaunching:(NSNotification *)n {
    (void)n;
    [self loadCatalog];
    _bw = _bh = 256;
    self.selected = 0;
    self.sizeIdx = 1;
    self.filter = 0;
    self.mode = 0;
    self.animIdx = 0;
    _qzAnimRoot = nullptr;

    NSRect frame = NSMakeRect(0, 0, 1480, 900);
    self.window = [[KeyWindow alloc] initWithContentRect:frame
                                               styleMask:NSWindowStyleMaskTitled | NSWindowStyleMaskClosable |
                                                         NSWindowStyleMaskMiniaturizable | NSWindowStyleMaskResizable
                                                 backing:NSBackingStoreBuffered defer:NO];
    self.window.title = @"Quartz Inspector";
    self.window.appearance = [NSAppearance appearanceNamed:NSAppearanceNameDarkAqua];
    self.window.backgroundColor = CInk();
    self.window.delegate = self;
    self.window.minSize = NSMakeSize(1100, 700);
    [self.window center];

    NSView *root = self.window.contentView;

    NSView *rail = [[NSView alloc] initWithFrame:NSZeroRect];
    rail.translatesAutoresizingMaskIntoConstraints = NO;
    rail.wantsLayer = YES;
    rail.layer.backgroundColor = CRail().CGColor;
    [root addSubview:rail];

    NSTextField *brand = [self label:@"libquartz" size:13 weight:NSFontWeightHeavy color:CTerr()];
    brand.translatesAutoresizingMaskIntoConstraints = NO;
    [rail addSubview:brand];

    self.scoreLabel = [self label:@"scoring…" size:11 weight:NSFontWeightMedium color:CMute()];
    self.scoreLabel.translatesAutoresizingMaskIntoConstraints = NO;
    [rail addSubview:self.scoreLabel];

    self.modeSeg = [NSSegmentedControl segmentedControlWithLabels:@[@"Compare", @"Anim", @"Show"]
                                                     trackingMode:NSSegmentSwitchTrackingSelectOne
                                                           target:self action:@selector(modeChanged:)];
    self.modeSeg.selectedSegment = 0;
    self.modeSeg.translatesAutoresizingMaskIntoConstraints = NO;
    self.modeSeg.segmentStyle = NSSegmentStyleRounded;
    [rail addSubview:self.modeSeg];

    self.filterSeg = [NSSegmentedControl segmentedControlWithLabels:@[@"All", @"CG", @"CA"]
                                                       trackingMode:NSSegmentSwitchTrackingSelectOne
                                                             target:self action:@selector(filterChanged:)];
    self.filterSeg.selectedSegment = 0;
    self.filterSeg.translatesAutoresizingMaskIntoConstraints = NO;
    [rail addSubview:self.filterSeg];

    self.sizeSeg = [NSSegmentedControl segmentedControlWithLabels:@[@"128", @"256", @"384"]
                                                     trackingMode:NSSegmentSwitchTrackingSelectOne
                                                           target:self action:@selector(sizeChanged:)];
    self.sizeSeg.selectedSegment = 1;
    self.sizeSeg.translatesAutoresizingMaskIntoConstraints = NO;
    [rail addSubview:self.sizeSeg];

    self.listScroll = [[NSScrollView alloc] initWithFrame:NSZeroRect];
    self.listScroll.translatesAutoresizingMaskIntoConstraints = NO;
    self.listScroll.hasVerticalScroller = YES;
    self.listScroll.drawsBackground = NO;
    self.listScroll.borderType = NSNoBorder;
    [rail addSubview:self.listScroll];

    self.list = [NSStackView stackViewWithViews:@[]];
    self.list.orientation = NSUserInterfaceLayoutOrientationVertical;
    self.list.alignment = NSLayoutAttributeWidth;
    self.list.spacing = 1;
    self.list.edgeInsets = NSEdgeInsetsMake(4, 0, 8, 0);
    self.list.translatesAutoresizingMaskIntoConstraints = NO;
    FlippedDoc *doc = [[FlippedDoc alloc] initWithFrame:NSMakeRect(0, 0, 248, 40)];
    [doc addSubview:self.list];
    [NSLayoutConstraint activateConstraints:@[
        [self.list.topAnchor constraintEqualToAnchor:doc.topAnchor],
        [self.list.leadingAnchor constraintEqualToAnchor:doc.leadingAnchor],
        [self.list.trailingAnchor constraintEqualToAnchor:doc.trailingAnchor],
        [self.list.bottomAnchor constraintEqualToAnchor:doc.bottomAnchor],
        [self.list.widthAnchor constraintEqualToConstant:248],
    ]];
    self.listScroll.documentView = doc;

    NSTextField *hint = [self label:@"↑↓ scene   space pause\nA anim  C compare  S show" size:10
                             weight:NSFontWeightRegular color:[NSColor colorWithWhite:0.38 alpha:1]];
    hint.translatesAutoresizingMaskIntoConstraints = NO;
    [rail addSubview:hint];

    self.titleLabel = [self label:@"—" size:22 weight:NSFontWeightHeavy color:CCream()];
    self.titleLabel.translatesAutoresizingMaskIntoConstraints = NO;
    [root addSubview:self.titleLabel];

    self.metaLabel = [self label:@"" size:12 weight:NSFontWeightMedium color:CMute()];
    self.metaLabel.translatesAutoresizingMaskIntoConstraints = NO;
    [root addSubview:self.metaLabel];

    self.compareBox = [[NSView alloc] initWithFrame:NSZeroRect];
    self.compareBox.translatesAutoresizingMaskIntoConstraints = NO;
    [root addSubview:self.compareBox];

    self.applePane = [self pane:@"APPLE  ·  CoreGraphics / QuartzCore"];
    self.qzPane = [self pane:@"QZ  ·  libquartz"];
    self.diffPane = [self pane:@"DIFF  ·  |Δ| × 8"];
    NSStackView *panes = [NSStackView stackViewWithViews:@[self.applePane, self.qzPane, self.diffPane]];
    panes.orientation = NSUserInterfaceLayoutOrientationHorizontal;
    panes.distribution = NSStackViewDistributionFillEqually;
    panes.spacing = 8;
    panes.translatesAutoresizingMaskIntoConstraints = NO;
    [self.compareBox addSubview:panes];

    self.pixelLabel = [self label:@"hover a pixel" size:11 weight:NSFontWeightRegular color:CMute()];
    self.pixelLabel.font = [NSFont monospacedSystemFontOfSize:11 weight:NSFontWeightRegular];
    self.pixelLabel.translatesAutoresizingMaskIntoConstraints = NO;
    [self.compareBox addSubview:self.pixelLabel];

    __weak DemoApp *weak = self;
    auto hover = ^(int x, int y) { [weak hoverX:x y:y]; };
    self.applePane.onHover = hover;
    self.qzPane.onHover = hover;
    self.diffPane.onHover = hover;

    self.showBox = [[NSView alloc] initWithFrame:NSZeroRect];
    self.showBox.translatesAutoresizingMaskIntoConstraints = NO;
    self.showBox.hidden = YES;
    [root addSubview:self.showBox];
    self.showPane = [self pane:@""];
    self.showPane.translatesAutoresizingMaskIntoConstraints = NO;
    [self.showBox addSubview:self.showPane];

    [NSLayoutConstraint activateConstraints:@[
        [rail.leadingAnchor constraintEqualToAnchor:root.leadingAnchor],
        [rail.topAnchor constraintEqualToAnchor:root.topAnchor],
        [rail.bottomAnchor constraintEqualToAnchor:root.bottomAnchor],
        [rail.widthAnchor constraintEqualToConstant:268],

        [brand.leadingAnchor constraintEqualToAnchor:rail.leadingAnchor constant:18],
        [brand.topAnchor constraintEqualToAnchor:rail.topAnchor constant:16],
        [self.scoreLabel.leadingAnchor constraintEqualToAnchor:brand.leadingAnchor],
        [self.scoreLabel.topAnchor constraintEqualToAnchor:brand.bottomAnchor constant:2],

        [self.modeSeg.leadingAnchor constraintEqualToAnchor:rail.leadingAnchor constant:16],
        [self.modeSeg.trailingAnchor constraintEqualToAnchor:rail.trailingAnchor constant:-16],
        [self.modeSeg.topAnchor constraintEqualToAnchor:self.scoreLabel.bottomAnchor constant:14],

        [self.filterSeg.leadingAnchor constraintEqualToAnchor:self.modeSeg.leadingAnchor],
        [self.filterSeg.trailingAnchor constraintEqualToAnchor:self.modeSeg.trailingAnchor],
        [self.filterSeg.topAnchor constraintEqualToAnchor:self.modeSeg.bottomAnchor constant:8],

        [self.sizeSeg.leadingAnchor constraintEqualToAnchor:self.modeSeg.leadingAnchor],
        [self.sizeSeg.trailingAnchor constraintEqualToAnchor:self.modeSeg.trailingAnchor],
        [self.sizeSeg.topAnchor constraintEqualToAnchor:self.filterSeg.bottomAnchor constant:8],

        [self.listScroll.leadingAnchor constraintEqualToAnchor:rail.leadingAnchor constant:8],
        [self.listScroll.trailingAnchor constraintEqualToAnchor:rail.trailingAnchor constant:-8],
        [self.listScroll.topAnchor constraintEqualToAnchor:self.sizeSeg.bottomAnchor constant:12],
        [self.listScroll.bottomAnchor constraintEqualToAnchor:hint.topAnchor constant:-12],

        [hint.leadingAnchor constraintEqualToAnchor:rail.leadingAnchor constant:18],
        [hint.bottomAnchor constraintEqualToAnchor:rail.bottomAnchor constant:-16],

        [self.titleLabel.leadingAnchor constraintEqualToAnchor:rail.trailingAnchor constant:24],
        [self.titleLabel.topAnchor constraintEqualToAnchor:root.topAnchor constant:14],
        [self.metaLabel.leadingAnchor constraintEqualToAnchor:self.titleLabel.leadingAnchor],
        [self.metaLabel.topAnchor constraintEqualToAnchor:self.titleLabel.bottomAnchor constant:2],

        [self.compareBox.leadingAnchor constraintEqualToAnchor:rail.trailingAnchor constant:12],
        [self.compareBox.trailingAnchor constraintEqualToAnchor:root.trailingAnchor constant:-12],
        [self.compareBox.topAnchor constraintEqualToAnchor:self.metaLabel.bottomAnchor constant:10],
        [self.compareBox.bottomAnchor constraintEqualToAnchor:root.bottomAnchor constant:-8],

        [self.pixelLabel.leadingAnchor constraintEqualToAnchor:self.compareBox.leadingAnchor constant:8],
        [self.pixelLabel.trailingAnchor constraintEqualToAnchor:self.compareBox.trailingAnchor],
        [self.pixelLabel.bottomAnchor constraintEqualToAnchor:self.compareBox.bottomAnchor constant:-4],

        [panes.leadingAnchor constraintEqualToAnchor:self.compareBox.leadingAnchor],
        [panes.trailingAnchor constraintEqualToAnchor:self.compareBox.trailingAnchor],
        [panes.topAnchor constraintEqualToAnchor:self.compareBox.topAnchor],
        [panes.bottomAnchor constraintEqualToAnchor:self.pixelLabel.topAnchor constant:-6],

        [self.showBox.leadingAnchor constraintEqualToAnchor:self.compareBox.leadingAnchor],
        [self.showBox.trailingAnchor constraintEqualToAnchor:self.compareBox.trailingAnchor],
        [self.showBox.topAnchor constraintEqualToAnchor:self.compareBox.topAnchor],
        [self.showBox.bottomAnchor constraintEqualToAnchor:self.compareBox.bottomAnchor],
        [self.showPane.leadingAnchor constraintEqualToAnchor:self.showBox.leadingAnchor],
        [self.showPane.trailingAnchor constraintEqualToAnchor:self.showBox.trailingAnchor],
        [self.showPane.topAnchor constraintEqualToAnchor:self.showBox.topAnchor],
        [self.showPane.bottomAnchor constraintEqualToAnchor:self.showBox.bottomAnchor],
    ]];

    NSMenu *menubar = [NSMenu new];
    NSMenuItem *appItem = [NSMenuItem new];
    [menubar addItem:appItem];
    NSMenu *appMenu = [NSMenu new];
    [appMenu addItemWithTitle:@"Quit Quartz Inspector" action:@selector(terminate:) keyEquivalent:@"q"];
    appItem.submenu = appMenu;
    NSApp.mainMenu = menubar;

    self.scoreLabel.stringValue = [NSString stringWithFormat:@"%zu scenes — scoring…", _items.size()];
    [self rebuildList];
    [self.window makeKeyAndOrderFront:nil];
    [self.window makeFirstResponder:root];
    [NSApp activateIgnoringOtherApps:YES];
    [self.window layoutIfNeeded];
    [self renderCompare];
    dispatch_async(dispatch_get_main_queue(), ^{ [self renderCompare]; });

    /* Host CALayer tree inside the visible window so presentationLayer exists. */
    root.wantsLayer = YES;
    self.animHost = [CALayer layer];
    self.animHost.masksToBounds = YES;
    self.animHost.anchorPoint = CGPointZero;
    self.animHost.position = CGPointMake(0, 0);
    self.animHost.transform = CATransform3DMakeScale(0.001, 0.001, 1);
    [root.layer addSublayer:self.animHost];

    self.timer = [NSTimer scheduledTimerWithTimeInterval:1.0 / 60.0
                                                  target:self selector:@selector(tick)
                                                userInfo:nil repeats:YES];
    [[NSRunLoop mainRunLoop] addTimer:self.timer forMode:NSRunLoopCommonModes];

    std::vector<CatalogItem> snapshot = _items;
    [self scoreAllAsync:std::move(snapshot)];
}

- (BitmapPane *)pane:(NSString *)caption {
    BitmapPane *p = [[BitmapPane alloc] initWithFrame:NSZeroRect];
    p.translatesAutoresizingMaskIntoConstraints = NO;
    p.caption = caption;
    p.wantsLayer = YES;
    return p;
}

- (void)loadCatalog {
    _items.clear();
    for (const Scene &s : qz_all_cg_scenes()) {
        CatalogItem it;
        it.ca = false;
        it.name = s.name;
        it.cg = s.draw;
        _items.push_back(it);
    }
    for (const LayerScene &s : qz_all_ca_scenes()) {
        CatalogItem it;
        it.ca = true;
        it.name = s.name;
        it.ca_build = s.build;
        _items.push_back(it);
    }
}

- (int)currentSize {
    static const int sizes[] = {128, 256, 384};
    return sizes[self.sizeIdx];
}

- (void)rebuildVisible {
    _visible.clear();
    for (int i = 0; i < (int)_items.size(); i++) {
        if (self.filter == 1 && _items[i].ca) continue;
        if (self.filter == 2 && !_items[i].ca) continue;
        _visible.push_back(i);
    }
    std::sort(_visible.begin(), _visible.end(), [&](int a, int b) {
        const CatalogItem &A = _items[a], &B = _items[b];
        if (A.scored && B.scored && std::fabs(A.mae - B.mae) > 1e-9) return A.mae > B.mae;
        return A.name < B.name;
    });
}

- (void)rebuildList {
    [self rebuildVisible];
    for (NSView *v in [self.list.arrangedSubviews copy]) {
        [self.list removeArrangedSubview:v];
        [v removeFromSuperview];
    }
    const CGFloat rowW = 248;
    if (self.mode == 2) {
        for (int i = 0; i < kShowCount; i++) {
            [self.list addArrangedSubview:[self rowButton:i
                                                     title:[NSString stringWithFormat:@"  %s", kShow[i].name]
                                                      meta:[NSString stringWithUTF8String:kShow[i].blurb]
                                                    on:(i == self.showIdx)]];
        }
        return;
    }
    if (self.mode == 1) {
        for (int i = 0; i < kAnimCount; i++) {
            [self.list addArrangedSubview:[self rowButton:i
                                                     title:[NSString stringWithFormat:@"  %s", kAnim[i].name]
                                                      meta:[NSString stringWithUTF8String:kAnim[i].blurb]
                                                    on:(i == self.animIdx)]];
        }
        return;
    }
    for (int vis = 0; vis < (int)_visible.size(); vis++) {
        int idx = _visible[vis];
        const CatalogItem &it = _items[idx];
        NSString *title = [NSString stringWithFormat:@"  %s  %s", it.ca ? "CA" : "CG", it.name.c_str()];
        NSString *meta = it.scored
            ? [NSString stringWithFormat:@"exact %5.1f%%   mae %.3f   max %d", it.exact, it.mae, it.max_err]
            : @"scoring…";
        [self.list addArrangedSubview:[self rowButton:vis title:title meta:meta on:(idx == self.selected)]];
    }
    if (self.selected >= (int)_items.size()) self.selected = 0;
    [self.list layoutSubtreeIfNeeded];
    NSSize fit = self.list.fittingSize;
    if (fit.width < rowW) fit.width = rowW;
    if (fit.height < 8) fit.height = 8;
    NSView *doc = self.list.superview;
    doc.frame = NSMakeRect(0, 0, fit.width, fit.height);
}

- (NSButton *)rowButton:(int)tag title:(NSString *)title meta:(NSString *)meta on:(BOOL)on {
    NSButton *b = [NSButton buttonWithTitle:title target:self action:@selector(pick:)];
    b.tag = tag;
    b.bordered = NO;
    b.alignment = NSTextAlignmentLeft;
    b.font = [NSFont monospacedSystemFontOfSize:11 weight:on ? NSFontWeightBold : NSFontWeightMedium];
    b.contentTintColor = on ? CGold() : CCream();
    b.toolTip = meta;
    b.attributedTitle = ({
        NSMutableAttributedString *a = [[NSMutableAttributedString alloc] init];
        NSColor *c = on ? CGold() : CCream();
        [a appendAttributedString:[[NSAttributedString alloc] initWithString:[title stringByAppendingString:@"\n"]
            attributes:@{NSFontAttributeName: [NSFont monospacedSystemFontOfSize:11 weight:NSFontWeightSemibold],
                         NSForegroundColorAttributeName: c}]];
        [a appendAttributedString:[[NSAttributedString alloc] initWithString:meta
            attributes:@{NSFontAttributeName: [NSFont monospacedSystemFontOfSize:9 weight:NSFontWeightRegular],
                         NSForegroundColorAttributeName: CMute()}]];
        a;
    });
    b.translatesAutoresizingMaskIntoConstraints = NO;
    [b.heightAnchor constraintEqualToConstant:38].active = YES;
    return b;
}

- (void)pick:(NSButton *)sender {
    if (self.mode == 2) {
        self.showIdx = (int)sender.tag;
        self.t = 0;
        [self renderShow];
        [self rebuildList];
        return;
    }
    if (self.mode == 1) {
        self.animIdx = (int)sender.tag;
        self.t = 0;
        [self rebuildAnimTrees];
        [self renderAnim];
        [self rebuildList];
        return;
    }
    int vis = (int)sender.tag;
    if (vis < 0 || vis >= (int)_visible.size()) return;
    self.selected = _visible[vis];
    [self renderCompare];
    [self rebuildList];
}

- (void)modeChanged:(NSSegmentedControl *)s {
    self.mode = (int)s.selectedSegment;
    self.compareBox.hidden = self.mode == 2;
    self.showBox.hidden = self.mode != 2;
    self.filterSeg.enabled = self.mode == 0;
    self.sizeSeg.enabled = self.mode != 2;
    self.t = 0;
    [self rebuildList];
    if (self.mode == 0) [self renderCompare];
    else if (self.mode == 1) {
        [self rebuildAnimTrees];
        [self renderAnim];
    } else [self renderShow];
}

- (void)filterChanged:(NSSegmentedControl *)s {
    self.filter = (int)s.selectedSegment;
    [self rebuildVisible];
    if (!_visible.empty()) {
        bool keep = false;
        for (int v : _visible) if (v == self.selected) keep = true;
        if (!keep) self.selected = _visible.front();
    }
    [self rebuildList];
    [self renderCompare];
}

- (void)sizeChanged:(NSSegmentedControl *)s {
    self.sizeIdx = (int)s.selectedSegment;
    if (self.mode == 1) {
        [self rebuildAnimTrees];
        [self renderAnim];
    } else if (self.mode == 0) {
        [self renderCompare];
    }
}

- (void)renderCompare {
    if (_items.empty()) {
        self.titleLabel.stringValue = @"no scenes linked";
        self.metaLabel.stringValue = @"harness catalog is empty";
        return;
    }
    if (self.selected < 0 || self.selected >= (int)_items.size()) self.selected = 0;
    CatalogItem &it = _items[self.selected];
    int w = [self currentSize];
    _bw = _bh = w;
    CmpStats st;
    if (!render_item(it, w, w, _apple, _qz, _diff, st)) {
        self.titleLabel.stringValue = [NSString stringWithUTF8String:it.name.c_str()];
        self.metaLabel.stringValue = @"render failed (backend begin)";
        return;
    }
    it.mae = st.mae; it.exact = st.exact; it.close = st.close; it.max_err = st.max_err; it.scored = true;

    CGImageRef ai = cgimage_rgba(_apple.data(), w, w, true);
    CGImageRef qi = cgimage_rgba(_qz.data(), w, w, true);
    CGImageRef di = cgimage_rgba(_diff.data(), w, w, false);
    self.applePane.srcW = self.qzPane.srcW = self.diffPane.srcW = w;
    self.applePane.srcH = self.qzPane.srcH = self.diffPane.srcH = w;
    self.applePane.image = ai;
    self.qzPane.image = qi;
    self.diffPane.image = di;
    if (ai) CGImageRelease(ai);
    if (qi) CGImageRelease(qi);
    if (di) CGImageRelease(di);

    self.titleLabel.stringValue = [NSString stringWithUTF8String:it.name.c_str()];
    self.metaLabel.stringValue = [NSString stringWithFormat:@"%s  ·  %d×%d  ·  exact %.2f%%  close≤8 %.2f%%  MAE %.4f  max %d",
                                  it.ca ? "Core Animation" : "Core Graphics",
                                  w, w, it.exact, it.close, it.mae, it.max_err];
    self.pixelLabel.stringValue = @"hover a pixel — nearest-neighbor scale, y-down bitmap";
}

- (void)hoverX:(int)x y:(int)y {
    if (_apple.empty() || x < 0 || y < 0 || x >= _bw || y >= _bh) return;
    size_t i = ((size_t)y * _bw + x) * 4;
    const uint8_t *a = _apple.data() + i;
    const uint8_t *q = _qz.data() + i;
    int d0 = abs((int)a[0] - (int)q[0]), d1 = abs((int)a[1] - (int)q[1]);
    int d2 = abs((int)a[2] - (int)q[2]), d3 = abs((int)a[3] - (int)q[3]);
    self.pixelLabel.stringValue = [NSString stringWithFormat:
        @"(%3d,%3d)  apple %3d %3d %3d %3d    qz %3d %3d %3d %3d    Δ %d %d %d %d",
        x, y, a[0], a[1], a[2], a[3], q[0], q[1], q[2], q[3], d0, d1, d2, d3];
}

- (double)animLocalTime {
    const AnimDemo &s = kAnim[self.animIdx];
    double dur = s.duration > 0 ? s.duration : 1;
    if (!s.pingpong) return fmod(self.t, dur);
    double cyc = fmod(self.t, dur * 2.0);
    return cyc <= dur ? cyc : dur * 2.0 - cyc;
}

- (void)rebuildAnimTrees {
    for (auto it = _qzAnimLive.rbegin(); it != _qzAnimLive.rend(); ++it) {
        QZLayerRemoveAllAnimations(*it);
        QZLayerRelease(*it);
    }
    _qzAnimLive.clear();
    _qzAnimRoot = nullptr;

    strip_apple_layer(self.appleAnimRoot);
    [self.appleAnimRoot removeFromSuperlayer];
    self.appleAnimRoot = nil;
    NSArray<CALayer *> *left = [self.animHost.sublayers copy];
    for (CALayer *l in left) {
        strip_apple_layer(l);
        [l removeFromSuperlayer];
    }
    self.animHost.sublayers = nil;

    int w = [self currentSize];
    self.animHost.bounds = CGRectMake(0, 0, w, w);
    self.animHost.speed = 0;
    self.animHost.beginTime = 0;
    self.animHost.timeOffset = 0;

    _qzAnimRoot = QZLayerCreate();
    QZLayerSetFrame(_qzAnimRoot, QZRectMake(0, 0, w, w));
    _qzAnimLive.push_back(_qzAnimRoot);
    kAnim[self.animIdx].build_qz(_qzAnimRoot, w, w, &_qzAnimLive);

    [CATransaction begin];
    [CATransaction setDisableActions:YES];
    CALayer *root = [CALayer layer];
    root.frame = CGRectMake(0, 0, w, w);
    kAnim[self.animIdx].build_apple(root, w, w);
    [self.animHost addSublayer:root];
    self.appleAnimRoot = root;
    self.animHost.speed = 0;
    [CATransaction commit];
    [CATransaction flush];
    [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.03]];
}

- (void)renderAnim {
    if (!_qzAnimRoot) [self rebuildAnimTrees];
    const AnimDemo &s = kAnim[self.animIdx];
    int w = [self currentSize];
    _bw = _bh = w;
    double t = [self animLocalTime];

    QZContextRef qctx = QZBitmapContextCreate(nullptr, w, w, 8, (size_t)w * 4,
                                              kQZImageAlphaPremultipliedLast);
    QZLayerRef pres = QZLayerCopyPresentationTree(_qzAnimRoot, t);
    QZLayerRenderInContext(pres, qctx);
    QZLayerReleasePresentationTree(pres);
    pack_rgba(_qz, (const uint8_t *)QZBitmapContextGetData(qctx),
              QZBitmapContextGetBytesPerRow(qctx), w, w);
    QZContextRelease(qctx);

    CGColorSpaceRef cs = CGColorSpaceCreateWithName(kCGColorSpaceSRGB);
    CGContextRef actx = CGBitmapContextCreate(NULL, w, w, 8, (size_t)w * 4, cs,
                                              kCGImageAlphaPremultipliedLast | kCGBitmapByteOrder32Big);
    CGContextClearRect(actx, CGRectMake(0, 0, w, w));
    [CATransaction begin];
    [CATransaction setDisableActions:YES];
    freeze_layer_time(self.animHost, t);
    freeze_layer_time(self.appleAnimRoot, t);
    [CATransaction commit];
    [CATransaction flush];
    CALayer *draw = self.appleAnimRoot.presentationLayer;
    CALayer *child0 = self.appleAnimRoot.sublayers.firstObject;
    CALayer *childPres = child0.presentationLayer;
    if (!draw) draw = self.appleAnimRoot;
    [draw renderInContext:actx];
    BOOL hasPres = self.appleAnimRoot.presentationLayer != nil;
    BOOL hasChild = childPres != nil;
    pack_rgba(_apple, (const uint8_t *)CGBitmapContextGetData(actx),
              CGBitmapContextGetBytesPerRow(actx), w, w);
    CGContextRelease(actx);
    CGColorSpaceRelease(cs);

    CmpStats st = compare_pack(_apple.data(), (size_t)w * 4, _qz.data(), (size_t)w * 4, w, w, _diff);
    CGImageRef ai = cgimage_rgba(_apple.data(), w, w, true);
    CGImageRef qi = cgimage_rgba(_qz.data(), w, w, true);
    CGImageRef di = cgimage_rgba(_diff.data(), w, w, false);
    self.applePane.srcW = self.qzPane.srcW = self.diffPane.srcW = w;
    self.applePane.srcH = self.qzPane.srcH = self.diffPane.srcH = w;
    self.applePane.image = ai;
    self.qzPane.image = qi;
    self.diffPane.image = di;
    if (ai) CGImageRelease(ai);
    if (qi) CGImageRelease(qi);
    if (di) CGImageRelease(di);

    self.titleLabel.stringValue = [NSString stringWithUTF8String:s.name];
    self.metaLabel.stringValue = [NSString stringWithFormat:
        @"%s  ·  t=%.2fs / %.2fs%s  ·  exact %.1f%%  MAE %.3f  max %d",
        s.blurb, t, s.duration, s.pingpong ? "  ping-pong" : "",
        st.exact, st.mae, st.max_err];
    (void)hasPres; (void)hasChild;
}

- (void)renderShow {
    const ShowPiece &s = kShow[self.showIdx];
    QZContextRef ctx = QZBitmapContextCreate(nullptr, kShowW, kShowH, 8, kShowW * 4,
                                             kQZImageAlphaPremultipliedLast);
    s.draw(ctx, self.t);
    CGImageRef img = cgimage_from_qz(ctx);
    self.showPane.srcW = kShowW;
    self.showPane.srcH = kShowH;
    self.showPane.image = img;
    if (img) CGImageRelease(img);
    QZContextRelease(ctx);
    self.titleLabel.stringValue = [NSString stringWithUTF8String:s.name];
    self.metaLabel.stringValue = [NSString stringWithFormat:@"%s  ·  %dx%d  ·  libquartz only",
                                  s.blurb, kShowW, kShowH];
}

- (void)tick {
    if (self.paused) return;
    if (self.mode == 2) {
        if (!kShow[self.showIdx].animated) return;
        self.t += 1.0 / 60.0;
        [self renderShow];
        return;
    }
    if (self.mode == 1) {
        self.t += 1.0 / 60.0;
        [self renderAnim];
    }
}

- (void)scoreAllAsync:(std::vector<CatalogItem>)seed {
    dispatch_async(dispatch_get_global_queue(QOS_CLASS_USER_INITIATED, 0), ^{
        std::vector<CatalogItem> local = seed;
        int n = (int)local.size();
        const int sw = 256;
        double sum_mae = 0, sum_exact = 0, sum_close = 0;
        int worst = 0, scored = 0;
        for (int i = 0; i < n; i++) {
            std::vector<uint8_t> a, q, d;
            CmpStats st;
            if (!render_item(local[i], sw, sw, a, q, d, st)) continue;
            local[i].mae = st.mae;
            local[i].exact = st.exact;
            local[i].close = st.close;
            local[i].max_err = st.max_err;
            local[i].scored = true;
            sum_mae += st.mae;
            sum_exact += st.exact;
            sum_close += st.close;
            if (st.max_err > worst) worst = st.max_err;
            scored++;
        }
        double mae = scored ? sum_mae / scored : 0;
        double exact = scored ? sum_exact / scored : 0;
        double close = scored ? sum_close / scored : 0;
        double score = 0.40 * exact + 0.40 * close + 0.20 * std::max(0.0, 100.0 - mae * 8.0);
        dispatch_async(dispatch_get_main_queue(), ^{
            for (int i = 0; i < n && i < (int)self->_items.size(); i++) {
                self->_items[i].mae = local[i].mae;
                self->_items[i].exact = local[i].exact;
                self->_items[i].close = local[i].close;
                self->_items[i].max_err = local[i].max_err;
                self->_items[i].scored = local[i].scored;
            }
            self.scoreLabel.stringValue = [NSString stringWithFormat:@"SCORE %.2f  ·  %d scenes  ·  worst max %d",
                                           score, scored, worst];
            self.scoreLabel.textColor = CGold();
            [self rebuildVisible];
            if (!self->_visible.empty()) self.selected = self->_visible.front();
            [self rebuildList];
            [self renderCompare];
        });
    });
}

- (void)step:(int)dir {
    if (self.mode == 2) {
        self.showIdx = (self.showIdx + kShowCount + dir) % kShowCount;
        self.t = 0;
        [self renderShow];
        [self rebuildList];
        return;
    }
    if (self.mode == 1) {
        self.animIdx = (self.animIdx + kAnimCount + dir) % kAnimCount;
        self.t = 0;
        [self rebuildAnimTrees];
        [self renderAnim];
        [self rebuildList];
        return;
    }
    if (_visible.empty()) return;
    int pos = 0;
    for (int i = 0; i < (int)_visible.size(); i++) if (_visible[i] == self.selected) pos = i;
    pos = (pos + (int)_visible.size() + dir) % (int)_visible.size();
    self.selected = _visible[pos];
    [self renderCompare];
    [self rebuildList];
}

- (void)keyDown:(NSEvent *)e {
    NSString *ch = e.charactersIgnoringModifiers;
    if (e.keyCode == 125 || e.keyCode == 124) [self step:1];
    else if (e.keyCode == 126 || e.keyCode == 123) [self step:-1];
    else if (e.keyCode == 49) self.paused = !self.paused;
    else if ([ch isEqualToString:@"1"]) { self.sizeSeg.selectedSegment = 0; [self sizeChanged:self.sizeSeg]; }
    else if ([ch isEqualToString:@"2"]) { self.sizeSeg.selectedSegment = 1; [self sizeChanged:self.sizeSeg]; }
    else if ([ch isEqualToString:@"3"]) { self.sizeSeg.selectedSegment = 2; [self sizeChanged:self.sizeSeg]; }
    else if ([ch isEqualToString:@"c"] || [ch isEqualToString:@"C"]) {
        self.modeSeg.selectedSegment = 0; [self modeChanged:self.modeSeg];
    } else if ([ch isEqualToString:@"a"] || [ch isEqualToString:@"A"]) {
        self.modeSeg.selectedSegment = 1; [self modeChanged:self.modeSeg];
    } else if ([ch isEqualToString:@"s"] || [ch isEqualToString:@"S"]) {
        self.modeSeg.selectedSegment = 2; [self modeChanged:self.modeSeg];
    }
}

- (BOOL)applicationShouldTerminateAfterLastWindowClosed:(NSApplication *)sender {
    (void)sender;
    return YES;
}
@end

@implementation KeyWindow
- (BOOL)canBecomeKeyWindow { return YES; }
- (void)keyDown:(NSEvent *)event {
    [(DemoApp *)NSApp.delegate keyDown:event];
}
@end

int main(int argc, const char **argv) {
    (void)argc; (void)argv;
    @autoreleasepool {
        [NSApplication sharedApplication];
        [NSApp setActivationPolicy:NSApplicationActivationPolicyRegular];
        DemoApp *delegate = [DemoApp new];
        NSApp.delegate = delegate;
        [NSApp run];
    }
    return 0;
}
