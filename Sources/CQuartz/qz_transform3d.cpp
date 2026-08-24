#include "qz_internal.hpp"

QZTransform3D QZTransform3DIdentity(void) {
    return {1, 0, 0, 0,  0, 1, 0, 0,  0, 0, 1, 0,  0, 0, 0, 1};
}

QZTransform3D QZTransform3DMakeTranslation(QZFloat tx, QZFloat ty, QZFloat tz) {
    QZTransform3D t = QZTransform3DIdentity();
    t.m41 = tx; t.m42 = ty; t.m43 = tz;
    return t;
}

QZTransform3D QZTransform3DMakeScale(QZFloat sx, QZFloat sy, QZFloat sz) {
    QZTransform3D t = QZTransform3DIdentity();
    t.m11 = sx; t.m22 = sy; t.m33 = sz;
    return t;
}

QZTransform3D QZTransform3DMakeRotation(QZFloat angle, QZFloat x, QZFloat y, QZFloat z) {
    double L = std::sqrt(x * x + y * y + z * z);
    if (L < 1e-20) return QZTransform3DIdentity();
    x /= L; y /= L; z /= L;
    double c = std::cos(angle), s = std::sin(angle), ic = 1 - c;
    QZTransform3D t = QZTransform3DIdentity();
    t.m11 = c + x * x * ic;     t.m12 = x * y * ic + z * s; t.m13 = x * z * ic - y * s;
    t.m21 = y * x * ic - z * s; t.m22 = c + y * y * ic;     t.m23 = y * z * ic + x * s;
    t.m31 = z * x * ic + y * s; t.m32 = z * y * ic - x * s; t.m33 = c + z * z * ic;
    return t;
}

QZTransform3D QZTransform3DConcat(QZTransform3D a, QZTransform3D b) {
    /* t' = a * b with row-vector convention (CG/CA): p' = p * t. */
    QZTransform3D r{};
    const double A[4][4] = {
        {a.m11, a.m12, a.m13, a.m14},
        {a.m21, a.m22, a.m23, a.m24},
        {a.m31, a.m32, a.m33, a.m34},
        {a.m41, a.m42, a.m43, a.m44}
    };
    const double B[4][4] = {
        {b.m11, b.m12, b.m13, b.m14},
        {b.m21, b.m22, b.m23, b.m24},
        {b.m31, b.m32, b.m33, b.m34},
        {b.m41, b.m42, b.m43, b.m44}
    };
    double R[4][4] = {};
    for (int i = 0; i < 4; i++)
        for (int j = 0; j < 4; j++)
            for (int k = 0; k < 4; k++)
                R[i][j] += A[i][k] * B[k][j];
    r.m11 = R[0][0]; r.m12 = R[0][1]; r.m13 = R[0][2]; r.m14 = R[0][3];
    r.m21 = R[1][0]; r.m22 = R[1][1]; r.m23 = R[1][2]; r.m24 = R[1][3];
    r.m31 = R[2][0]; r.m32 = R[2][1]; r.m33 = R[2][2]; r.m34 = R[2][3];
    r.m41 = R[3][0]; r.m42 = R[3][1]; r.m43 = R[3][2]; r.m44 = R[3][3];
    return r;
}

QZTransform3D QZTransform3DInvert(QZTransform3D t) {
    /* Gauss-Jordan on 4x4. */
    double m[4][8] = {
        {t.m11, t.m12, t.m13, t.m14, 1, 0, 0, 0},
        {t.m21, t.m22, t.m23, t.m24, 0, 1, 0, 0},
        {t.m31, t.m32, t.m33, t.m34, 0, 0, 1, 0},
        {t.m41, t.m42, t.m43, t.m44, 0, 0, 0, 1}
    };
    for (int col = 0; col < 4; col++) {
        int piv = col;
        for (int r = col + 1; r < 4; r++)
            if (std::fabs(m[r][col]) > std::fabs(m[piv][col])) piv = r;
        if (std::fabs(m[piv][col]) < 1e-20) return t;
        if (piv != col) for (int c = 0; c < 8; c++) std::swap(m[piv][c], m[col][c]);
        double d = m[col][col];
        for (int c = 0; c < 8; c++) m[col][c] /= d;
        for (int r = 0; r < 4; r++) {
            if (r == col) continue;
            double f = m[r][col];
            for (int c = 0; c < 8; c++) m[r][c] -= f * m[col][c];
        }
    }
    QZTransform3D o;
    o.m11 = m[0][4]; o.m12 = m[0][5]; o.m13 = m[0][6]; o.m14 = m[0][7];
    o.m21 = m[1][4]; o.m22 = m[1][5]; o.m23 = m[1][6]; o.m24 = m[1][7];
    o.m31 = m[2][4]; o.m32 = m[2][5]; o.m33 = m[2][6]; o.m34 = m[2][7];
    o.m41 = m[3][4]; o.m42 = m[3][5]; o.m43 = m[3][6]; o.m44 = m[3][7];
    return o;
}

QZTransform3D QZTransform3DMakeAffineTransform(QZAffineTransform m) {
    QZTransform3D t = QZTransform3DIdentity();
    t.m11 = m.a; t.m12 = m.b;
    t.m21 = m.c; t.m22 = m.d;
    t.m41 = m.tx; t.m42 = m.ty;
    return t;
}

bool QZTransform3DIsAffine(QZTransform3D t) {
    return std::fabs(t.m13) < 1e-12 && std::fabs(t.m14) < 1e-12 &&
           std::fabs(t.m23) < 1e-12 && std::fabs(t.m24) < 1e-12 &&
           std::fabs(t.m31) < 1e-12 && std::fabs(t.m32) < 1e-12 &&
           std::fabs(t.m33 - 1) < 1e-12 && std::fabs(t.m34) < 1e-12 &&
           std::fabs(t.m43) < 1e-12 && std::fabs(t.m44 - 1) < 1e-12;
}

QZAffineTransform QZTransform3DGetAffineTransform(QZTransform3D t) {
    return QZAffineTransformMake(t.m11, t.m12, t.m21, t.m22, t.m41, t.m42);
}
