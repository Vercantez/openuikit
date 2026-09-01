#ifndef OPEN_SCENEKIT_C_ABI_H
#define OPEN_SCENEKIT_C_ABI_H

#include <stdbool.h>

#ifdef __cplusplus
extern "C" {
#endif

#if defined(__GNUC__) || defined(__clang__)
#define SCN_EXPORT __attribute__((visibility("default")))
#else
#define SCN_EXPORT
#endif

typedef struct SCNVector3 {
    float x;
    float y;
    float z;
} SCNVector3;

typedef struct SCNVector4 {
    float x;
    float y;
    float z;
    float w;
} SCNVector4;

typedef struct SCNMatrix4 {
    float m11, m12, m13, m14;
    float m21, m22, m23, m24;
    float m31, m32, m33, m34;
    float m41, m42, m43, m44;
} SCNMatrix4;

SCN_EXPORT extern const SCNVector3 SCNVector3Zero;
SCN_EXPORT extern const SCNVector4 SCNVector4Zero;
SCN_EXPORT extern const SCNMatrix4 SCNMatrix4Identity;

SCN_EXPORT bool SCNVector3EqualToVector3(SCNVector3 a, SCNVector3 b);
SCN_EXPORT bool SCNVector4EqualToVector4(SCNVector4 a, SCNVector4 b);
SCN_EXPORT bool SCNMatrix4EqualToMatrix4(SCNMatrix4 a, SCNMatrix4 b);
SCN_EXPORT bool SCNMatrix4IsIdentity(SCNMatrix4 matrix);
SCN_EXPORT SCNMatrix4 SCNMatrix4MakeRotation(float angle, float x, float y, float z);
SCN_EXPORT SCNMatrix4 SCNMatrix4Mult(SCNMatrix4 a, SCNMatrix4 b);
SCN_EXPORT SCNMatrix4 SCNMatrix4Invert(SCNMatrix4 matrix);
SCN_EXPORT SCNMatrix4 SCNMatrix4Rotate(SCNMatrix4 matrix, float angle, float x, float y, float z);
SCN_EXPORT SCNMatrix4 SCNMatrix4Scale(SCNMatrix4 matrix, float sx, float sy, float sz);

static inline SCNVector3 SCNVector3Make(float x, float y, float z) {
    SCNVector3 vector;
    vector.x = x;
    vector.y = y;
    vector.z = z;
    return vector;
}

static inline SCNVector4 SCNVector4Make(float x, float y, float z, float w) {
    SCNVector4 vector;
    vector.x = x;
    vector.y = y;
    vector.z = z;
    vector.w = w;
    return vector;
}

static inline SCNMatrix4 SCNMatrix4MakeTranslation(float tx, float ty, float tz) {
    SCNMatrix4 matrix = SCNMatrix4Identity;
    matrix.m41 = tx;
    matrix.m42 = ty;
    matrix.m43 = tz;
    return matrix;
}

static inline SCNMatrix4 SCNMatrix4MakeScale(float sx, float sy, float sz) {
    SCNMatrix4 matrix = SCNMatrix4Identity;
    matrix.m11 = sx;
    matrix.m22 = sy;
    matrix.m33 = sz;
    return matrix;
}

static inline SCNMatrix4 SCNMatrix4Translate(SCNMatrix4 matrix, float tx, float ty, float tz) {
    return SCNMatrix4Mult(SCNMatrix4MakeTranslation(tx, ty, tz), matrix);
}

#ifdef __cplusplus
}
#endif

#endif /* OPEN_SCENEKIT_C_ABI_H */
