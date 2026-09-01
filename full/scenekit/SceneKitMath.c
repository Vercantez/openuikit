#include "SceneKit/SceneKit.h"

#include <math.h>
#include <string.h>

const SCNVector3 SCNVector3Zero = {0.f, 0.f, 0.f};
const SCNVector4 SCNVector4Zero = {0.f, 0.f, 0.f, 0.f};
const SCNMatrix4 SCNMatrix4Identity = {
    1.f, 0.f, 0.f, 0.f,
    0.f, 1.f, 0.f, 0.f,
    0.f, 0.f, 1.f, 0.f,
    0.f, 0.f, 0.f, 1.f
};

bool SCNVector3EqualToVector3(SCNVector3 a, SCNVector3 b) {
    return a.x == b.x && a.y == b.y && a.z == b.z;
}

bool SCNVector4EqualToVector4(SCNVector4 a, SCNVector4 b) {
    return a.x == b.x && a.y == b.y && a.z == b.z && a.w == b.w;
}

bool SCNMatrix4EqualToMatrix4(SCNMatrix4 a, SCNMatrix4 b) {
    return memcmp(&a, &b, sizeof(SCNMatrix4)) == 0;
}

bool SCNMatrix4IsIdentity(SCNMatrix4 matrix) {
    return SCNMatrix4EqualToMatrix4(matrix, SCNMatrix4Identity);
}

static SCNVector3 scn_normalize(SCNVector3 v) {
    float length = sqrtf(v.x * v.x + v.y * v.y + v.z * v.z);
    if (length < 1e-8f) {
        SCNVector3 fallback = {0.f, 0.f, 1.f};
        return fallback;
    }
    SCNVector3 n = {v.x / length, v.y / length, v.z / length};
    return n;
}

SCNMatrix4 SCNMatrix4MakeRotation(float angle, float x, float y, float z) {
    SCNVector3 axis = {x, y, z};
    axis = scn_normalize(axis);
    float c = cosf(angle);
    float s = sinf(angle);
    float t = 1.f - c;
    float ax = axis.x, ay = axis.y, az = axis.z;
    SCNMatrix4 m;
    m.m11 = t * ax * ax + c;
    m.m12 = t * ax * ay + s * az;
    m.m13 = t * ax * az - s * ay;
    m.m14 = 0.f;
    m.m21 = t * ax * ay - s * az;
    m.m22 = t * ay * ay + c;
    m.m23 = t * ay * az + s * ax;
    m.m24 = 0.f;
    m.m31 = t * ax * az + s * ay;
    m.m32 = t * ay * az - s * ax;
    m.m33 = t * az * az + c;
    m.m34 = 0.f;
    m.m41 = 0.f;
    m.m42 = 0.f;
    m.m43 = 0.f;
    m.m44 = 1.f;
    return m;
}

SCNMatrix4 SCNMatrix4Mult(SCNMatrix4 a, SCNMatrix4 b) {
    SCNMatrix4 r;
    r.m11 = b.m11 * a.m11 + b.m12 * a.m21 + b.m13 * a.m31 + b.m14 * a.m41;
    r.m12 = b.m11 * a.m12 + b.m12 * a.m22 + b.m13 * a.m32 + b.m14 * a.m42;
    r.m13 = b.m11 * a.m13 + b.m12 * a.m23 + b.m13 * a.m33 + b.m14 * a.m43;
    r.m14 = b.m11 * a.m14 + b.m12 * a.m24 + b.m13 * a.m34 + b.m14 * a.m44;
    r.m21 = b.m21 * a.m11 + b.m22 * a.m21 + b.m23 * a.m31 + b.m24 * a.m41;
    r.m22 = b.m21 * a.m12 + b.m22 * a.m22 + b.m23 * a.m32 + b.m24 * a.m42;
    r.m23 = b.m21 * a.m13 + b.m22 * a.m23 + b.m23 * a.m33 + b.m24 * a.m43;
    r.m24 = b.m21 * a.m14 + b.m22 * a.m24 + b.m23 * a.m34 + b.m24 * a.m44;
    r.m31 = b.m31 * a.m11 + b.m32 * a.m21 + b.m33 * a.m31 + b.m34 * a.m41;
    r.m32 = b.m31 * a.m12 + b.m32 * a.m22 + b.m33 * a.m32 + b.m34 * a.m42;
    r.m33 = b.m31 * a.m13 + b.m32 * a.m23 + b.m33 * a.m33 + b.m34 * a.m43;
    r.m34 = b.m31 * a.m14 + b.m32 * a.m24 + b.m33 * a.m34 + b.m34 * a.m44;
    r.m41 = b.m41 * a.m11 + b.m42 * a.m21 + b.m43 * a.m31 + b.m44 * a.m41;
    r.m42 = b.m41 * a.m12 + b.m42 * a.m22 + b.m43 * a.m32 + b.m44 * a.m42;
    r.m43 = b.m41 * a.m13 + b.m42 * a.m23 + b.m43 * a.m33 + b.m44 * a.m43;
    r.m44 = b.m41 * a.m14 + b.m42 * a.m24 + b.m43 * a.m34 + b.m44 * a.m44;
    return r;
}

SCNMatrix4 SCNMatrix4Invert(SCNMatrix4 m) {
    float a[4][4] = {
        {m.m11, m.m12, m.m13, m.m14},
        {m.m21, m.m22, m.m23, m.m24},
        {m.m31, m.m32, m.m33, m.m34},
        {m.m41, m.m42, m.m43, m.m44}
    };
    float inv[4][4] = {
        {1.f, 0.f, 0.f, 0.f},
        {0.f, 1.f, 0.f, 0.f},
        {0.f, 0.f, 1.f, 0.f},
        {0.f, 0.f, 0.f, 1.f}
    };
    for (int i = 0; i < 4; i++) {
        int pivot = i;
        float best = fabsf(a[i][i]);
        for (int row = i + 1; row < 4; row++) {
            float value = fabsf(a[row][i]);
            if (value > best) {
                best = value;
                pivot = row;
            }
        }
        if (best < 1e-8f) {
            return SCNMatrix4Identity;
        }
        if (pivot != i) {
            for (int col = 0; col < 4; col++) {
                float tmp = a[i][col];
                a[i][col] = a[pivot][col];
                a[pivot][col] = tmp;
                tmp = inv[i][col];
                inv[i][col] = inv[pivot][col];
                inv[pivot][col] = tmp;
            }
        }
        float diag = a[i][i];
        for (int col = 0; col < 4; col++) {
            a[i][col] /= diag;
            inv[i][col] /= diag;
        }
        for (int row = 0; row < 4; row++) {
            if (row == i) {
                continue;
            }
            float factor = a[row][i];
            for (int col = 0; col < 4; col++) {
                a[row][col] -= factor * a[i][col];
                inv[row][col] -= factor * inv[i][col];
            }
        }
    }
    SCNMatrix4 out;
    out.m11 = inv[0][0]; out.m12 = inv[0][1]; out.m13 = inv[0][2]; out.m14 = inv[0][3];
    out.m21 = inv[1][0]; out.m22 = inv[1][1]; out.m23 = inv[1][2]; out.m24 = inv[1][3];
    out.m31 = inv[2][0]; out.m32 = inv[2][1]; out.m33 = inv[2][2]; out.m34 = inv[2][3];
    out.m41 = inv[3][0]; out.m42 = inv[3][1]; out.m43 = inv[3][2]; out.m44 = inv[3][3];
    return out;
}

SCNMatrix4 SCNMatrix4Rotate(SCNMatrix4 matrix, float angle, float x, float y, float z) {
    return SCNMatrix4Mult(SCNMatrix4MakeRotation(angle, x, y, z), matrix);
}

SCNMatrix4 SCNMatrix4Scale(SCNMatrix4 matrix, float sx, float sy, float sz) {
    return SCNMatrix4Mult(SCNMatrix4MakeScale(sx, sy, sz), matrix);
}
