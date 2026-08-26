#include "qz_internal.hpp"

/* OWNED BY package color. */

enum {
    kQZCSDeviceRGB = 0,
    kQZCSDeviceGray = 1,
    kQZCSSRGB = 2
};

struct QZColorSpace {
    int kind = kQZCSDeviceRGB;
    int ref = 1;
};

struct QZColor {
    int ref = 1;
    QZColorSpaceRef space = nullptr;
    QZFloat c[4] = {0, 0, 0, 1};
    size_t n = 4;
};

static QZColorSpaceRef retain_space(QZColorSpaceRef space) {
    if (space) space->ref++;
    return space;
}

static bool space_is_gray(QZColorSpaceRef space) {
    return space && space->kind == kQZCSDeviceGray;
}

QZColorSpaceRef QZColorSpaceCreateDeviceRGB(void) {
    return new QZColorSpace{kQZCSDeviceRGB, 1};
}
QZColorSpaceRef QZColorSpaceCreateDeviceGray(void) {
    return new QZColorSpace{kQZCSDeviceGray, 1};
}
QZColorSpaceRef QZColorSpaceCreateWithNameSRGB(void) {
    return new QZColorSpace{kQZCSSRGB, 1};
}
void QZColorSpaceRelease(QZColorSpaceRef space) {
    if (!space) return;
    if (--space->ref <= 0) delete space;
}

QZColorRef QZColorCreate(QZColorSpaceRef space, const QZFloat *components) {
    if (!space || !components) return nullptr;
    auto *col = new QZColor();
    col->space = retain_space(space);
    if (space_is_gray(space)) {
        col->n = 2;
        col->c[0] = components[0];
        col->c[1] = components[1];
        col->c[2] = 0;
        col->c[3] = 0;
    } else {
        col->n = 4;
        col->c[0] = components[0];
        col->c[1] = components[1];
        col->c[2] = components[2];
        col->c[3] = components[3];
    }
    return col;
}

QZColorRef QZColorCreateGenericRGB(QZFloat r, QZFloat g, QZFloat b, QZFloat a) {
    QZColorSpaceRef space = QZColorSpaceCreateDeviceRGB();
    QZFloat comps[4] = {r, g, b, a};
    QZColorRef col = QZColorCreate(space, comps);
    QZColorSpaceRelease(space);
    return col;
}

QZColorRef QZColorRetain(QZColorRef color) {
    if (color) color->ref++;
    return color;
}

void QZColorRelease(QZColorRef color) {
    if (!color) return;
    if (--color->ref <= 0) {
        QZColorSpaceRelease(color->space);
        delete color;
    }
}

size_t QZColorGetNumberOfComponents(QZColorRef color) {
    return color ? color->n : 0;
}

const QZFloat *QZColorGetComponents(QZColorRef color) {
    return color ? color->c : nullptr;
}

static void color_rgba(QZColorRef color, QZFloat *r, QZFloat *g, QZFloat *b, QZFloat *a) {
    if (color->n == 2 || space_is_gray(color->space)) {
        *r = *g = *b = color->c[0];
        *a = color->c[1];
    } else {
        *r = color->c[0];
        *g = color->c[1];
        *b = color->c[2];
        *a = color->c[3];
    }
}

void QZContextSetFillColorWithColor(QZContextRef ctx, QZColorRef color) {
    if (!ctx || !color) return;
    QZFloat r, g, b, a;
    color_rgba(color, &r, &g, &b, &a);
    QZContextSetRGBFillColor(ctx, r, g, b, a);
}

void QZContextSetStrokeColorWithColor(QZContextRef ctx, QZColorRef color) {
    if (!ctx || !color) return;
    QZFloat r, g, b, a;
    color_rgba(color, &r, &g, &b, &a);
    QZContextSetRGBStrokeColor(ctx, r, g, b, a);
}
