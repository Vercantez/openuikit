#include "layer_backend.h"
#include <cstring>
#include <vector>

struct QZLayers final : LayerTree {
    int W = 0, H = 0;
    QZContextRef ctx = nullptr;
    std::vector<QZLayerRef> nodes;

    const char *name() const override { return "qz-ca"; }
    bool begin(int w, int h) override {
        end();
        W = w; H = h;
        ctx = QZBitmapContextCreate(nullptr, w, h, 8, (size_t)w * 4, kQZImageAlphaPremultipliedLast);
        return ctx != nullptr;
    }
    void end() override {
        for (QZLayerRef l : nodes) QZLayerRelease(l);
        nodes.clear();
        if (ctx) { QZContextRelease(ctx); ctx = nullptr; }
    }
    const uint8_t *pixels() const override {
        return (const uint8_t *)QZBitmapContextGetData(ctx);
    }
    size_t bpr() const override { return QZBitmapContextGetBytesPerRow(ctx); }

    QZLayerRef get(int id) {
        if (id < 0 || id >= (int)nodes.size()) return nullptr;
        return nodes[(size_t)id];
    }

    int create(const char *kind) override {
        QZLayerRef l;
        if (kind && strcmp(kind, "shape") == 0) l = QZShapeLayerCreate();
        else if (kind && strcmp(kind, "gradient") == 0) l = QZGradientLayerCreate();
        else l = QZLayerCreate();
        nodes.push_back(l);
        return (int)nodes.size() - 1;
    }
    void set_frame(int id, double x, double y, double w, double h) override {
        QZLayerSetFrame(get(id), QZRectMake(x, y, w, h));
    }
    void set_bounds(int id, double x, double y, double w, double h) override {
        QZLayerSetBounds(get(id), QZRectMake(x, y, w, h));
    }
    void set_position(int id, double x, double y) override {
        QZLayerSetPosition(get(id), QZPointMake(x, y));
    }
    void set_anchor(int id, double x, double y) override {
        QZLayerSetAnchorPoint(get(id), QZPointMake(x, y));
    }
    void set_z(int id, double z) override { QZLayerSetZPosition(get(id), z); }
    void set_bg(int id, double r, double g, double b, double a) override {
        QZLayerSetBackgroundColor(get(id), r, g, b, a);
    }
    void set_opacity(int id, double o) override { QZLayerSetOpacity(get(id), o); }
    void set_corner(int id, double radius) override { QZLayerSetCornerRadius(get(id), radius); }
    void set_border(int id, double width, double r, double g, double b, double a) override {
        QZLayerSetBorderWidth(get(id), width);
        QZLayerSetBorderColor(get(id), r, g, b, a);
    }
    void set_masks(int id, bool on) override { QZLayerSetMasksToBounds(get(id), on); }
    void set_hidden(int id, bool on) override { QZLayerSetHidden(get(id), on); }
    void set_affine(int id, QZAffineTransform t) override {
        QZLayerSetAffineTransform(get(id), t);
    }
    void add_sub(int parent, int child) override {
        QZLayerAddSublayer(get(parent), get(child));
    }

    void shape_rect(int id, double x, double y, double w, double h) override {
        QZMutablePathRef p = QZPathCreateMutable();
        QZPathAddRect(p, nullptr, QZRectMake(x, y, w, h));
        QZShapeLayerSetPath(get(id), p);
        QZPathRelease(p);
    }
    void shape_ellipse(int id, double x, double y, double w, double h) override {
        QZMutablePathRef p = QZPathCreateMutable();
        QZPathAddEllipseInRect(p, nullptr, QZRectMake(x, y, w, h));
        QZShapeLayerSetPath(get(id), p);
        QZPathRelease(p);
    }
    void shape_fill(int id, double r, double g, double b, double a) override {
        QZShapeLayerSetFillColor(get(id), r, g, b, a);
    }
    void shape_stroke(int id, double r, double g, double b, double a, double width) override {
        QZShapeLayerSetStrokeColor(get(id), r, g, b, a);
        QZShapeLayerSetLineWidth(get(id), width);
    }
    void shape_eofill(int id, bool on) override { QZShapeLayerSetFillEvenOdd(get(id), on); }

    void grad_colors(int id, const double *rgba, const double *loc, int n) override {
        std::vector<QZFloat> C(n * 4), L(n);
        for (int i = 0; i < n; i++) {
            C[i * 4 + 0] = rgba[i * 4 + 0];
            C[i * 4 + 1] = rgba[i * 4 + 1];
            C[i * 4 + 2] = rgba[i * 4 + 2];
            C[i * 4 + 3] = rgba[i * 4 + 3];
            L[i] = loc ? loc[i] : (n == 1 ? 0 : (double)i / (n - 1));
        }
        QZGradientLayerSetColors(get(id), C.data(), L.data(), n);
    }
    void grad_points(int id, double x0, double y0, double x1, double y1) override {
        QZGradientLayerSetStartPoint(get(id), QZPointMake(x0, y0));
        QZGradientLayerSetEndPoint(get(id), QZPointMake(x1, y1));
    }
    void grad_radial(int id, bool on) override { QZGradientLayerSetRadial(get(id), on); }

    void render(int root) override { QZLayerRenderInContext(get(root), ctx); }
};

LayerTree *make_qz_layers() { return new QZLayers(); }
