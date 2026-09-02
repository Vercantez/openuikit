#import <Foundation/Foundation.h>
#import <CoreGraphics/CoreGraphics.h>
#import <QuartzCore/QuartzCore.h>
#include "layer_backend.h"
#include <cstring>

struct AppleLayers final : LayerTree {
    int W = 0, H = 0;
    CGContextRef ctx = nullptr;
    CGColorSpaceRef cs = nullptr;
    NSMutableArray<CALayer *> *nodes = nil;
    bool txn = false;

    const char *name() const override { return "apple-ca"; }

    bool begin(int w, int h) override {
        end();
        W = w; H = h;
        cs = CGColorSpaceCreateWithName(kCGColorSpaceSRGB);
        ctx = CGBitmapContextCreate(NULL, w, h, 8, (size_t)w * 4, cs,
                                    kCGImageAlphaPremultipliedLast | kCGBitmapByteOrder32Big);
        if (!ctx) return false;
        CGContextClearRect(ctx, CGRectMake(0, 0, w, h));
        nodes = [NSMutableArray array];
        [CATransaction begin];
        [CATransaction setDisableActions:YES];
        txn = true;
        return true;
    }
    void end() override {
        if (ctx) { CGContextRelease(ctx); ctx = nullptr; }
        if (cs) { CGColorSpaceRelease(cs); cs = nullptr; }
        nodes = nil;
        if (txn) { [CATransaction commit]; txn = false; }
    }
    const uint8_t *pixels() const override {
        return (const uint8_t *)CGBitmapContextGetData(ctx);
    }
    size_t bpr() const override { return CGBitmapContextGetBytesPerRow(ctx); }

    CALayer *get(int id) {
        if (id < 0 || id >= (int)nodes.count) return nil;
        return nodes[(NSUInteger)id];
    }
    CGColorRef color(double r, double g, double b, double a) {
        CGFloat c[4] = {(CGFloat)r, (CGFloat)g, (CGFloat)b, (CGFloat)a};
        return CGColorCreate(cs, c);
    }

    int create(const char *kind) override {
        CALayer *l = nil;
        if (kind && strcmp(kind, "shape") == 0) l = [CAShapeLayer layer];
        else if (kind && strcmp(kind, "gradient") == 0) l = [CAGradientLayer layer];
        else l = [CALayer layer];
        [nodes addObject:l];
        return (int)nodes.count - 1;
    }
    void set_frame(int id, double x, double y, double w, double h) override {
        get(id).frame = CGRectMake(x, y, w, h);
    }
    void set_bounds(int id, double x, double y, double w, double h) override {
        get(id).bounds = CGRectMake(x, y, w, h);
    }
    void set_position(int id, double x, double y) override {
        get(id).position = CGPointMake(x, y);
    }
    void set_anchor(int id, double x, double y) override {
        get(id).anchorPoint = CGPointMake(x, y);
    }
    void set_z(int id, double z) override { get(id).zPosition = z; }
    void set_bg(int id, double r, double g, double b, double a) override {
        CGColorRef c = color(r, g, b, a);
        get(id).backgroundColor = c;
        CGColorRelease(c);
    }
    void set_opacity(int id, double o) override { get(id).opacity = (float)o; }
    void set_corner(int id, double radius) override { get(id).cornerRadius = radius; }
    void set_border(int id, double width, double r, double g, double b, double a) override {
        CALayer *l = get(id);
        l.borderWidth = width;
        CGColorRef c = color(r, g, b, a);
        l.borderColor = c;
        CGColorRelease(c);
    }
    void set_masks(int id, bool on) override { get(id).masksToBounds = on; }
    void set_hidden(int id, bool on) override { get(id).hidden = on; }
    void set_affine(int id, QZAffineTransform t) override {
        get(id).affineTransform = CGAffineTransformMake(t.a, t.b, t.c, t.d, t.tx, t.ty);
    }
    void add_sub(int parent, int child) override {
        [get(parent) addSublayer:get(child)];
    }

    void shape_rect(int id, double x, double y, double w, double h) override {
        CAShapeLayer *s = (CAShapeLayer *)get(id);
        CGPathRef p = CGPathCreateWithRect(CGRectMake(x, y, w, h), NULL);
        s.path = p;
        CGPathRelease(p);
    }
    void shape_ellipse(int id, double x, double y, double w, double h) override {
        CAShapeLayer *s = (CAShapeLayer *)get(id);
        CGPathRef p = CGPathCreateWithEllipseInRect(CGRectMake(x, y, w, h), NULL);
        s.path = p;
        CGPathRelease(p);
    }
    void shape_fill(int id, double r, double g, double b, double a) override {
        CAShapeLayer *s = (CAShapeLayer *)get(id);
        CGColorRef c = color(r, g, b, a);
        s.fillColor = c;
        CGColorRelease(c);
    }
    void shape_stroke(int id, double r, double g, double b, double a, double width) override {
        CAShapeLayer *s = (CAShapeLayer *)get(id);
        CGColorRef c = color(r, g, b, a);
        s.strokeColor = c;
        s.lineWidth = width;
        CGColorRelease(c);
    }
    void shape_eofill(int id, bool on) override {
        CAShapeLayer *s = (CAShapeLayer *)get(id);
        s.fillRule = on ? kCAFillRuleEvenOdd : kCAFillRuleNonZero;
    }

    void grad_colors(int id, const double *rgba, const double *loc, int n) override {
        CAGradientLayer *g = (CAGradientLayer *)get(id);
        NSMutableArray *cols = [NSMutableArray array];
        NSMutableArray *locs = [NSMutableArray array];
        for (int i = 0; i < n; i++) {
            CGColorRef c = color(rgba[i * 4], rgba[i * 4 + 1], rgba[i * 4 + 2], rgba[i * 4 + 3]);
            [cols addObject:CFBridgingRelease(c)];
            double L = loc ? loc[i] : (n == 1 ? 0 : (double)i / (n - 1));
            [locs addObject:@(L)];
        }
        g.colors = cols;
        g.locations = locs;
    }
    void grad_points(int id, double x0, double y0, double x1, double y1) override {
        CAGradientLayer *g = (CAGradientLayer *)get(id);
        g.startPoint = CGPointMake(x0, y0);
        g.endPoint = CGPointMake(x1, y1);
    }
    void grad_radial(int id, bool on) override {
        CAGradientLayer *g = (CAGradientLayer *)get(id);
        g.type = on ? kCAGradientLayerRadial : kCAGradientLayerAxial;
    }

    void render(int root) override {
        [get(root) renderInContext:ctx];
    }
};

LayerTree *make_apple_layers() { return new AppleLayers(); }
