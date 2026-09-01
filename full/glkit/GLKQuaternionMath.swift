import Foundation

public func GLKQuaternionMake(_ x: Float, _ y: Float, _ z: Float, _ w: Float) -> GLKQuaternion {
    GLKQuaternion(x: x, y: y, z: z, w: w)
}

public func GLKQuaternionMakeWithVector3(_ vector: GLKVector3, _ scalar: Float) -> GLKQuaternion {
    GLKQuaternionMake(vector.x, vector.y, vector.z, scalar)
}

public func GLKQuaternionMakeWithArray(_ values: UnsafeMutablePointer<Float>!) -> GLKQuaternion {
    GLKQuaternionMake(values[0], values[1], values[2], values[3])
}

public func GLKQuaternionMakeWithAngleAndAxis(_ radians: Float, _ x: Float, _ y: Float, _ z: Float) -> GLKQuaternion {
    let half = radians * 0.5
    let s = sinf(half)
    let c = cosf(half)
    let axis = GLKVector3Normalize(GLKVector3Make(x, y, z))
    return GLKQuaternionMake(axis.x * s, axis.y * s, axis.z * s, c)
}

public func GLKQuaternionMakeWithAngleAndVector3Axis(_ radians: Float, _ axisVector: GLKVector3) -> GLKQuaternion {
    GLKQuaternionMakeWithAngleAndAxis(radians, axisVector.x, axisVector.y, axisVector.z)
}

public func GLKQuaternionMakeWithMatrix3(_ matrix: GLKMatrix3) -> GLKQuaternion {
    let trace = matrix.m00 + matrix.m11 + matrix.m22
    if trace > 0 {
        let s = 0.5 / sqrtf(trace + 1.0)
        return GLKQuaternionMake(
            (matrix.m12 - matrix.m21) * s,
            (matrix.m20 - matrix.m02) * s,
            (matrix.m01 - matrix.m10) * s,
            0.25 / s
        )
    }
    if matrix.m00 > matrix.m11 && matrix.m00 > matrix.m22 {
        let s = 2.0 * sqrtf(1.0 + matrix.m00 - matrix.m11 - matrix.m22)
        return GLKQuaternionMake(
            0.25 * s,
            (matrix.m10 + matrix.m01) / s,
            (matrix.m20 + matrix.m02) / s,
            (matrix.m12 - matrix.m21) / s
        )
    }
    if matrix.m11 > matrix.m22 {
        let s = 2.0 * sqrtf(1.0 + matrix.m11 - matrix.m00 - matrix.m22)
        return GLKQuaternionMake(
            (matrix.m10 + matrix.m01) / s,
            0.25 * s,
            (matrix.m21 + matrix.m12) / s,
            (matrix.m20 - matrix.m02) / s
        )
    }
    let s = 2.0 * sqrtf(1.0 + matrix.m22 - matrix.m00 - matrix.m11)
    return GLKQuaternionMake(
        (matrix.m20 + matrix.m02) / s,
        (matrix.m21 + matrix.m12) / s,
        0.25 * s,
        (matrix.m01 - matrix.m10) / s
    )
}

public func GLKQuaternionMakeWithMatrix4(_ matrix: GLKMatrix4) -> GLKQuaternion {
    GLKQuaternionMakeWithMatrix3(GLKMatrix4GetMatrix3(matrix))
}

public func GLKQuaternionLength(_ quaternion: GLKQuaternion) -> Float {
    sqrtf(
        quaternion.x * quaternion.x
            + quaternion.y * quaternion.y
            + quaternion.z * quaternion.z
            + quaternion.w * quaternion.w
    )
}

public func GLKQuaternionConjugate(_ quaternion: GLKQuaternion) -> GLKQuaternion {
    GLKQuaternionMake(-quaternion.x, -quaternion.y, -quaternion.z, quaternion.w)
}

public func GLKQuaternionInvert(_ quaternion: GLKQuaternion) -> GLKQuaternion {
    let scale = 1.0 / (
        quaternion.x * quaternion.x
            + quaternion.y * quaternion.y
            + quaternion.z * quaternion.z
            + quaternion.w * quaternion.w
    )
    return GLKQuaternionMake(
        -quaternion.x * scale,
        -quaternion.y * scale,
        -quaternion.z * scale,
        quaternion.w * scale
    )
}

public func GLKQuaternionNormalize(_ quaternion: GLKQuaternion) -> GLKQuaternion {
    let scale = 1.0 / GLKQuaternionLength(quaternion)
    return GLKQuaternionMake(
        quaternion.x * scale,
        quaternion.y * scale,
        quaternion.z * scale,
        quaternion.w * scale
    )
}

public func GLKQuaternionAdd(_ quaternionLeft: GLKQuaternion, _ quaternionRight: GLKQuaternion) -> GLKQuaternion {
    GLKQuaternionMake(
        quaternionLeft.x + quaternionRight.x,
        quaternionLeft.y + quaternionRight.y,
        quaternionLeft.z + quaternionRight.z,
        quaternionLeft.w + quaternionRight.w
    )
}

public func GLKQuaternionSubtract(_ quaternionLeft: GLKQuaternion, _ quaternionRight: GLKQuaternion) -> GLKQuaternion {
    GLKQuaternionMake(
        quaternionLeft.x - quaternionRight.x,
        quaternionLeft.y - quaternionRight.y,
        quaternionLeft.z - quaternionRight.z,
        quaternionLeft.w - quaternionRight.w
    )
}

public func GLKQuaternionMultiply(_ quaternionLeft: GLKQuaternion, _ quaternionRight: GLKQuaternion) -> GLKQuaternion {
    GLKQuaternionMake(
        quaternionLeft.w * quaternionRight.x + quaternionLeft.x * quaternionRight.w
            + quaternionLeft.y * quaternionRight.z - quaternionLeft.z * quaternionRight.y,
        quaternionLeft.w * quaternionRight.y - quaternionLeft.x * quaternionRight.z
            + quaternionLeft.y * quaternionRight.w + quaternionLeft.z * quaternionRight.x,
        quaternionLeft.w * quaternionRight.z + quaternionLeft.x * quaternionRight.y
            - quaternionLeft.y * quaternionRight.x + quaternionLeft.z * quaternionRight.w,
        quaternionLeft.w * quaternionRight.w - quaternionLeft.x * quaternionRight.x
            - quaternionLeft.y * quaternionRight.y - quaternionLeft.z * quaternionRight.z
    )
}

public func GLKQuaternionAngle(_ quaternion: GLKQuaternion) -> Float {
    acosf(quaternion.w) * 2.0
}

public func GLKQuaternionAxis(_ quaternion: GLKQuaternion) -> GLKVector3 {
    let scale = sqrtf(max(0, 1.0 - quaternion.w * quaternion.w))
    if scale < 1e-8 {
        return GLKVector3Make(1, 0, 0)
    }
    return GLKVector3Make(quaternion.x / scale, quaternion.y / scale, quaternion.z / scale)
}

public func GLKQuaternionRotateVector3(_ quaternion: GLKQuaternion, _ vector: GLKVector3) -> GLKVector3 {
    let rotated = GLKQuaternionMultiply(
        GLKQuaternionMultiply(
            quaternion,
            GLKQuaternionMakeWithVector3(vector, 0)
        ),
        GLKQuaternionConjugate(quaternion)
    )
    return GLKVector3Make(rotated.x, rotated.y, rotated.z)
}

public func GLKQuaternionRotateVector3Array(
    _ quaternion: GLKQuaternion,
    _ vectors: UnsafeMutablePointer<GLKVector3>,
    _ vectorCount: Int
) {
    var index = 0
    while index < vectorCount {
        vectors[index] = GLKQuaternionRotateVector3(quaternion, vectors[index])
        index += 1
    }
}

public func GLKQuaternionRotateVector4(_ quaternion: GLKQuaternion, _ vector: GLKVector4) -> GLKVector4 {
    let rotated = GLKQuaternionRotateVector3(quaternion, GLKVector3Make(vector.x, vector.y, vector.z))
    return GLKVector4Make(rotated.x, rotated.y, rotated.z, vector.w)
}

public func GLKQuaternionRotateVector4Array(
    _ quaternion: GLKQuaternion,
    _ vectors: UnsafeMutablePointer<GLKVector4>,
    _ vectorCount: Int
) {
    var index = 0
    while index < vectorCount {
        vectors[index] = GLKQuaternionRotateVector4(quaternion, vectors[index])
        index += 1
    }
}

public func GLKQuaternionSlerp(
    _ quaternionStart: GLKQuaternion, _ quaternionEnd: GLKQuaternion, _ t: Float
) -> GLKQuaternion {
    var end = quaternionEnd
    var cosTheta = quaternionStart.x * end.x
        + quaternionStart.y * end.y
        + quaternionStart.z * end.z
        + quaternionStart.w * end.w
    if cosTheta < 0 {
        cosTheta = -cosTheta
        end = GLKQuaternionMake(-end.x, -end.y, -end.z, -end.w)
    }
    if cosTheta > 0.9995 {
        return GLKQuaternionNormalize(
            GLKQuaternionAdd(
                quaternionStart,
                GLKQuaternionMake(
                    (end.x - quaternionStart.x) * t,
                    (end.y - quaternionStart.y) * t,
                    (end.z - quaternionStart.z) * t,
                    (end.w - quaternionStart.w) * t
                )
            )
        )
    }
    let theta = acosf(cosTheta)
    let sinTheta = sinf(theta)
    let startScale = sinf((1.0 - t) * theta) / sinTheta
    let endScale = sinf(t * theta) / sinTheta
    return GLKQuaternionMake(
        quaternionStart.x * startScale + end.x * endScale,
        quaternionStart.y * startScale + end.y * endScale,
        quaternionStart.z * startScale + end.z * endScale,
        quaternionStart.w * startScale + end.w * endScale
    )
}
