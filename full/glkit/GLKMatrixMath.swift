import Foundation

public func GLKMatrix3Make(
    _ m00: Float, _ m01: Float, _ m02: Float,
    _ m10: Float, _ m11: Float, _ m12: Float,
    _ m20: Float, _ m21: Float, _ m22: Float
) -> GLKMatrix3 {
    GLKMatrix3(
        m00: m00, m01: m01, m02: m02,
        m10: m10, m11: m11, m12: m12,
        m20: m20, m21: m21, m22: m22
    )
}

public func GLKMatrix3MakeAndTranspose(
    _ m00: Float, _ m01: Float, _ m02: Float,
    _ m10: Float, _ m11: Float, _ m12: Float,
    _ m20: Float, _ m21: Float, _ m22: Float
) -> GLKMatrix3 {
    GLKMatrix3Make(m00, m10, m20, m01, m11, m21, m02, m12, m22)
}

public func GLKMatrix3MakeWithArray(_ values: UnsafeMutablePointer<Float>!) -> GLKMatrix3 {
    GLKMatrix3Make(
        values[0], values[1], values[2],
        values[3], values[4], values[5],
        values[6], values[7], values[8]
    )
}

public func GLKMatrix3MakeWithArrayAndTranspose(_ values: UnsafeMutablePointer<Float>!) -> GLKMatrix3 {
    GLKMatrix3Make(
        values[0], values[3], values[6],
        values[1], values[4], values[7],
        values[2], values[5], values[8]
    )
}

public func GLKMatrix3MakeWithRows(_ row0: GLKVector3, _ row1: GLKVector3, _ row2: GLKVector3) -> GLKMatrix3 {
    GLKMatrix3Make(
        row0.x, row1.x, row2.x,
        row0.y, row1.y, row2.y,
        row0.z, row1.z, row2.z
    )
}

public func GLKMatrix3MakeWithColumns(_ column0: GLKVector3, _ column1: GLKVector3, _ column2: GLKVector3) -> GLKMatrix3 {
    GLKMatrix3Make(
        column0.x, column0.y, column0.z,
        column1.x, column1.y, column1.z,
        column2.x, column2.y, column2.z
    )
}

public func GLKMatrix3MakeWithQuaternion(_ quaternion: GLKQuaternion) -> GLKMatrix3 {
    let q = GLKQuaternionNormalize(quaternion)
    let x = q.x
    let y = q.y
    let z = q.z
    let w = q.w
    let _2x = x + x
    let _2y = y + y
    let _2z = z + z
    let _2w = w + w
    return GLKMatrix3Make(
        1.0 - _2y * y - _2z * z, _2x * y + _2w * z, _2x * z - _2w * y,
        _2x * y - _2w * z, 1.0 - _2x * x - _2z * z, _2y * z + _2w * x,
        _2x * z + _2w * y, _2y * z - _2w * x, 1.0 - _2x * x - _2y * y
    )
}

public func GLKMatrix3MakeScale(_ sx: Float, _ sy: Float, _ sz: Float) -> GLKMatrix3 {
    GLKMatrix3Make(sx, 0, 0, 0, sy, 0, 0, 0, sz)
}

public func GLKMatrix3MakeRotation(_ radians: Float, _ x: Float, _ y: Float, _ z: Float) -> GLKMatrix3 {
    let v = GLKVector3Normalize(GLKVector3Make(x, y, z))
    let cosv = cosf(radians)
    let cosp = 1.0 - cosv
    let sinv = sinf(radians)
    return GLKMatrix3Make(
        cosv + cosp * v.x * v.x,
        cosp * v.x * v.y + v.z * sinv,
        cosp * v.x * v.z - v.y * sinv,
        cosp * v.x * v.y - v.z * sinv,
        cosv + cosp * v.y * v.y,
        cosp * v.y * v.z + v.x * sinv,
        cosp * v.x * v.z + v.y * sinv,
        cosp * v.y * v.z - v.x * sinv,
        cosv + cosp * v.z * v.z
    )
}

public func GLKMatrix3MakeXRotation(_ radians: Float) -> GLKMatrix3 {
    let cosv = cosf(radians)
    let sinv = sinf(radians)
    return GLKMatrix3Make(1, 0, 0, 0, cosv, sinv, 0, -sinv, cosv)
}

public func GLKMatrix3MakeYRotation(_ radians: Float) -> GLKMatrix3 {
    let cosv = cosf(radians)
    let sinv = sinf(radians)
    return GLKMatrix3Make(cosv, 0, -sinv, 0, 1, 0, sinv, 0, cosv)
}

public func GLKMatrix3MakeZRotation(_ radians: Float) -> GLKMatrix3 {
    let cosv = cosf(radians)
    let sinv = sinf(radians)
    return GLKMatrix3Make(cosv, sinv, 0, -sinv, cosv, 0, 0, 0, 1)
}

public func GLKMatrix3GetMatrix2(_ matrix: GLKMatrix3) -> GLKMatrix2 {
    GLKMatrix2(m00: matrix.m00, m01: matrix.m01, m10: matrix.m10, m11: matrix.m11)
}

public func GLKMatrix3GetRow(_ matrix: GLKMatrix3, _ row: Int32) -> GLKVector3 {
    let r = Int(row)
    return GLKVector3Make(matrix[r], matrix[3 + r], matrix[6 + r])
}

public func GLKMatrix3GetColumn(_ matrix: GLKMatrix3, _ column: Int32) -> GLKVector3 {
    let c = Int(column) * 3
    return GLKVector3Make(matrix[c], matrix[c + 1], matrix[c + 2])
}

public func GLKMatrix3SetRow(_ matrix: GLKMatrix3, _ row: Int32, _ vector: GLKVector3) -> GLKMatrix3 {
    var result = matrix
    let r = Int(row)
    result[r] = vector.x
    result[3 + r] = vector.y
    result[6 + r] = vector.z
    return result
}

public func GLKMatrix3SetColumn(_ matrix: GLKMatrix3, _ column: Int32, _ vector: GLKVector3) -> GLKMatrix3 {
    var result = matrix
    let c = Int(column) * 3
    result[c] = vector.x
    result[c + 1] = vector.y
    result[c + 2] = vector.z
    return result
}

public func GLKMatrix3Transpose(_ matrix: GLKMatrix3) -> GLKMatrix3 {
    GLKMatrix3Make(
        matrix.m00, matrix.m10, matrix.m20,
        matrix.m01, matrix.m11, matrix.m21,
        matrix.m02, matrix.m12, matrix.m22
    )
}

public func GLKMatrix3Multiply(_ matrixLeft: GLKMatrix3, _ matrixRight: GLKMatrix3) -> GLKMatrix3 {
    GLKMatrix3Make(
        matrixLeft.m00 * matrixRight.m00 + matrixLeft.m10 * matrixRight.m01 + matrixLeft.m20 * matrixRight.m02,
        matrixLeft.m01 * matrixRight.m00 + matrixLeft.m11 * matrixRight.m01 + matrixLeft.m21 * matrixRight.m02,
        matrixLeft.m02 * matrixRight.m00 + matrixLeft.m12 * matrixRight.m01 + matrixLeft.m22 * matrixRight.m02,
        matrixLeft.m00 * matrixRight.m10 + matrixLeft.m10 * matrixRight.m11 + matrixLeft.m20 * matrixRight.m12,
        matrixLeft.m01 * matrixRight.m10 + matrixLeft.m11 * matrixRight.m11 + matrixLeft.m21 * matrixRight.m12,
        matrixLeft.m02 * matrixRight.m10 + matrixLeft.m12 * matrixRight.m11 + matrixLeft.m22 * matrixRight.m12,
        matrixLeft.m00 * matrixRight.m20 + matrixLeft.m10 * matrixRight.m21 + matrixLeft.m20 * matrixRight.m22,
        matrixLeft.m01 * matrixRight.m20 + matrixLeft.m11 * matrixRight.m21 + matrixLeft.m21 * matrixRight.m22,
        matrixLeft.m02 * matrixRight.m20 + matrixLeft.m12 * matrixRight.m21 + matrixLeft.m22 * matrixRight.m22
    )
}

public func GLKMatrix3Add(_ matrixLeft: GLKMatrix3, _ matrixRight: GLKMatrix3) -> GLKMatrix3 {
    GLKMatrix3Make(
        matrixLeft.m00 + matrixRight.m00, matrixLeft.m01 + matrixRight.m01, matrixLeft.m02 + matrixRight.m02,
        matrixLeft.m10 + matrixRight.m10, matrixLeft.m11 + matrixRight.m11, matrixLeft.m12 + matrixRight.m12,
        matrixLeft.m20 + matrixRight.m20, matrixLeft.m21 + matrixRight.m21, matrixLeft.m22 + matrixRight.m22
    )
}

public func GLKMatrix3Subtract(_ matrixLeft: GLKMatrix3, _ matrixRight: GLKMatrix3) -> GLKMatrix3 {
    GLKMatrix3Make(
        matrixLeft.m00 - matrixRight.m00, matrixLeft.m01 - matrixRight.m01, matrixLeft.m02 - matrixRight.m02,
        matrixLeft.m10 - matrixRight.m10, matrixLeft.m11 - matrixRight.m11, matrixLeft.m12 - matrixRight.m12,
        matrixLeft.m20 - matrixRight.m20, matrixLeft.m21 - matrixRight.m21, matrixLeft.m22 - matrixRight.m22
    )
}

public func GLKMatrix3Scale(_ matrix: GLKMatrix3, _ sx: Float, _ sy: Float, _ sz: Float) -> GLKMatrix3 {
    GLKMatrix3Make(
        matrix.m00 * sx, matrix.m01 * sx, matrix.m02 * sx,
        matrix.m10 * sy, matrix.m11 * sy, matrix.m12 * sy,
        matrix.m20 * sz, matrix.m21 * sz, matrix.m22 * sz
    )
}

public func GLKMatrix3ScaleWithVector3(_ matrix: GLKMatrix3, _ scaleVector: GLKVector3) -> GLKMatrix3 {
    GLKMatrix3Scale(matrix, scaleVector.x, scaleVector.y, scaleVector.z)
}

public func GLKMatrix3ScaleWithVector4(_ matrix: GLKMatrix3, _ scaleVector: GLKVector4) -> GLKMatrix3 {
    GLKMatrix3Scale(matrix, scaleVector.x, scaleVector.y, scaleVector.z)
}

public func GLKMatrix3Rotate(_ matrix: GLKMatrix3, _ radians: Float, _ x: Float, _ y: Float, _ z: Float) -> GLKMatrix3 {
    GLKMatrix3Multiply(matrix, GLKMatrix3MakeRotation(radians, x, y, z))
}

public func GLKMatrix3RotateWithVector3(_ matrix: GLKMatrix3, _ radians: Float, _ axisVector: GLKVector3) -> GLKMatrix3 {
    GLKMatrix3Rotate(matrix, radians, axisVector.x, axisVector.y, axisVector.z)
}

public func GLKMatrix3RotateWithVector4(_ matrix: GLKMatrix3, _ radians: Float, _ axisVector: GLKVector4) -> GLKMatrix3 {
    GLKMatrix3Rotate(matrix, radians, axisVector.x, axisVector.y, axisVector.z)
}

public func GLKMatrix3RotateX(_ matrix: GLKMatrix3, _ radians: Float) -> GLKMatrix3 {
    GLKMatrix3Multiply(matrix, GLKMatrix3MakeXRotation(radians))
}

public func GLKMatrix3RotateY(_ matrix: GLKMatrix3, _ radians: Float) -> GLKMatrix3 {
    GLKMatrix3Multiply(matrix, GLKMatrix3MakeYRotation(radians))
}

public func GLKMatrix3RotateZ(_ matrix: GLKMatrix3, _ radians: Float) -> GLKMatrix3 {
    GLKMatrix3Multiply(matrix, GLKMatrix3MakeZRotation(radians))
}

public func GLKMatrix3MultiplyVector3(_ matrixLeft: GLKMatrix3, _ vectorRight: GLKVector3) -> GLKVector3 {
    GLKVector3Make(
        matrixLeft.m00 * vectorRight.x + matrixLeft.m10 * vectorRight.y + matrixLeft.m20 * vectorRight.z,
        matrixLeft.m01 * vectorRight.x + matrixLeft.m11 * vectorRight.y + matrixLeft.m21 * vectorRight.z,
        matrixLeft.m02 * vectorRight.x + matrixLeft.m12 * vectorRight.y + matrixLeft.m22 * vectorRight.z
    )
}

public func GLKMatrix3MultiplyVector3Array(_ matrix: GLKMatrix3, _ vectors: UnsafeMutablePointer<GLKVector3>, _ vectorCount: Int) {
    var index = 0
    while index < vectorCount {
        vectors[index] = GLKMatrix3MultiplyVector3(matrix, vectors[index])
        index += 1
    }
}

public func GLKMatrix3Invert(_ matrix: GLKMatrix3, _ isInvertible: UnsafeMutablePointer<Bool>!) -> GLKMatrix3 {
    let det =
        matrix.m00 * (matrix.m11 * matrix.m22 - matrix.m12 * matrix.m21)
        - matrix.m01 * (matrix.m10 * matrix.m22 - matrix.m12 * matrix.m20)
        + matrix.m02 * (matrix.m10 * matrix.m21 - matrix.m11 * matrix.m20)
    if abs(det) < 1e-8 {
        isInvertible?.pointee = false
        return GLKMatrix3Identity
    }
    isInvertible?.pointee = true
    let invDet = 1.0 / det
    return GLKMatrix3Make(
        (matrix.m11 * matrix.m22 - matrix.m12 * matrix.m21) * invDet,
        (matrix.m02 * matrix.m21 - matrix.m01 * matrix.m22) * invDet,
        (matrix.m01 * matrix.m12 - matrix.m02 * matrix.m11) * invDet,
        (matrix.m12 * matrix.m20 - matrix.m10 * matrix.m22) * invDet,
        (matrix.m00 * matrix.m22 - matrix.m02 * matrix.m20) * invDet,
        (matrix.m02 * matrix.m10 - matrix.m00 * matrix.m12) * invDet,
        (matrix.m10 * matrix.m21 - matrix.m11 * matrix.m20) * invDet,
        (matrix.m01 * matrix.m20 - matrix.m00 * matrix.m21) * invDet,
        (matrix.m00 * matrix.m11 - matrix.m01 * matrix.m10) * invDet
    )
}

public func GLKMatrix3InvertAndTranspose(_ matrix: GLKMatrix3, _ isInvertible: UnsafeMutablePointer<Bool>!) -> GLKMatrix3 {
    GLKMatrix3Transpose(GLKMatrix3Invert(matrix, isInvertible))
}

public func GLKMatrix4Make(
    _ m00: Float, _ m01: Float, _ m02: Float, _ m03: Float,
    _ m10: Float, _ m11: Float, _ m12: Float, _ m13: Float,
    _ m20: Float, _ m21: Float, _ m22: Float, _ m23: Float,
    _ m30: Float, _ m31: Float, _ m32: Float, _ m33: Float
) -> GLKMatrix4 {
    GLKMatrix4(
        m00: m00, m01: m01, m02: m02, m03: m03,
        m10: m10, m11: m11, m12: m12, m13: m13,
        m20: m20, m21: m21, m22: m22, m23: m23,
        m30: m30, m31: m31, m32: m32, m33: m33
    )
}

public func GLKMatrix4MakeAndTranspose(
    _ m00: Float, _ m01: Float, _ m02: Float, _ m03: Float,
    _ m10: Float, _ m11: Float, _ m12: Float, _ m13: Float,
    _ m20: Float, _ m21: Float, _ m22: Float, _ m23: Float,
    _ m30: Float, _ m31: Float, _ m32: Float, _ m33: Float
) -> GLKMatrix4 {
    GLKMatrix4Make(
        m00, m10, m20, m30,
        m01, m11, m21, m31,
        m02, m12, m22, m32,
        m03, m13, m23, m33
    )
}

public func GLKMatrix4MakeWithArray(_ values: UnsafeMutablePointer<Float>!) -> GLKMatrix4 {
    GLKMatrix4Make(
        values[0], values[1], values[2], values[3],
        values[4], values[5], values[6], values[7],
        values[8], values[9], values[10], values[11],
        values[12], values[13], values[14], values[15]
    )
}

public func GLKMatrix4MakeWithArrayAndTranspose(_ values: UnsafeMutablePointer<Float>!) -> GLKMatrix4 {
    GLKMatrix4Make(
        values[0], values[4], values[8], values[12],
        values[1], values[5], values[9], values[13],
        values[2], values[6], values[10], values[14],
        values[3], values[7], values[11], values[15]
    )
}

public func GLKMatrix4MakeWithRows(
    _ row0: GLKVector4, _ row1: GLKVector4, _ row2: GLKVector4, _ row3: GLKVector4
) -> GLKMatrix4 {
    GLKMatrix4Make(
        row0.x, row1.x, row2.x, row3.x,
        row0.y, row1.y, row2.y, row3.y,
        row0.z, row1.z, row2.z, row3.z,
        row0.w, row1.w, row2.w, row3.w
    )
}

public func GLKMatrix4MakeWithColumns(
    _ column0: GLKVector4, _ column1: GLKVector4, _ column2: GLKVector4, _ column3: GLKVector4
) -> GLKMatrix4 {
    GLKMatrix4Make(
        column0.x, column0.y, column0.z, column0.w,
        column1.x, column1.y, column1.z, column1.w,
        column2.x, column2.y, column2.z, column2.w,
        column3.x, column3.y, column3.z, column3.w
    )
}

public func GLKMatrix4MakeWithQuaternion(_ quaternion: GLKQuaternion) -> GLKMatrix4 {
    let q = GLKQuaternionNormalize(quaternion)
    let x = q.x
    let y = q.y
    let z = q.z
    let w = q.w
    let _2x = x + x
    let _2y = y + y
    let _2z = z + z
    let _2w = w + w
    return GLKMatrix4Make(
        1.0 - _2y * y - _2z * z, _2x * y + _2w * z, _2x * z - _2w * y, 0,
        _2x * y - _2w * z, 1.0 - _2x * x - _2z * z, _2y * z + _2w * x, 0,
        _2x * z + _2w * y, _2y * z - _2w * x, 1.0 - _2x * x - _2y * y, 0,
        0, 0, 0, 1
    )
}

public func GLKMatrix4MakeTranslation(_ tx: Float, _ ty: Float, _ tz: Float) -> GLKMatrix4 {
    var m = GLKMatrix4Identity
    m.m30 = tx
    m.m31 = ty
    m.m32 = tz
    return m
}

public func GLKMatrix4MakeScale(_ sx: Float, _ sy: Float, _ sz: Float) -> GLKMatrix4 {
    var m = GLKMatrix4Identity
    m.m00 = sx
    m.m11 = sy
    m.m22 = sz
    return m
}

public func GLKMatrix4MakeRotation(_ radians: Float, _ x: Float, _ y: Float, _ z: Float) -> GLKMatrix4 {
    let v = GLKVector3Normalize(GLKVector3Make(x, y, z))
    let cosv = cosf(radians)
    let cosp = 1.0 - cosv
    let sinv = sinf(radians)
    return GLKMatrix4Make(
        cosv + cosp * v.x * v.x, cosp * v.x * v.y + v.z * sinv, cosp * v.x * v.z - v.y * sinv, 0,
        cosp * v.x * v.y - v.z * sinv, cosv + cosp * v.y * v.y, cosp * v.y * v.z + v.x * sinv, 0,
        cosp * v.x * v.z + v.y * sinv, cosp * v.y * v.z - v.x * sinv, cosv + cosp * v.z * v.z, 0,
        0, 0, 0, 1
    )
}

public func GLKMatrix4MakeXRotation(_ radians: Float) -> GLKMatrix4 {
    let cosv = cosf(radians)
    let sinv = sinf(radians)
    return GLKMatrix4Make(1, 0, 0, 0, 0, cosv, sinv, 0, 0, -sinv, cosv, 0, 0, 0, 0, 1)
}

public func GLKMatrix4MakeYRotation(_ radians: Float) -> GLKMatrix4 {
    let cosv = cosf(radians)
    let sinv = sinf(radians)
    return GLKMatrix4Make(cosv, 0, -sinv, 0, 0, 1, 0, 0, sinv, 0, cosv, 0, 0, 0, 0, 1)
}

public func GLKMatrix4MakeZRotation(_ radians: Float) -> GLKMatrix4 {
    let cosv = cosf(radians)
    let sinv = sinf(radians)
    return GLKMatrix4Make(cosv, sinv, 0, 0, -sinv, cosv, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1)
}

public func GLKMatrix4MakePerspective(_ fovyRadians: Float, _ aspect: Float, _ nearZ: Float, _ farZ: Float) -> GLKMatrix4 {
    let cotan = 1.0 / tanf(fovyRadians / 2.0)
    return GLKMatrix4Make(
        cotan / aspect, 0, 0, 0,
        0, cotan, 0, 0,
        0, 0, (farZ + nearZ) / (nearZ - farZ), -1,
        0, 0, (2.0 * farZ * nearZ) / (nearZ - farZ), 0
    )
}

public func GLKMatrix4MakeFrustum(
    _ left: Float, _ right: Float, _ bottom: Float, _ top: Float, _ nearZ: Float, _ farZ: Float
) -> GLKMatrix4 {
    let rsl = right - left
    let tsb = top - bottom
    let fsn = farZ - nearZ
    return GLKMatrix4Make(
        2.0 * nearZ / rsl, 0, 0, 0,
        0, 2.0 * nearZ / tsb, 0, 0,
        (right + left) / rsl, (top + bottom) / tsb, -(farZ + nearZ) / fsn, -1,
        0, 0, (-2.0 * farZ * nearZ) / fsn, 0
    )
}

public func GLKMatrix4MakeOrtho(
    _ left: Float, _ right: Float, _ bottom: Float, _ top: Float, _ nearZ: Float, _ farZ: Float
) -> GLKMatrix4 {
    let rsl = right - left
    let tsb = top - bottom
    let fsn = farZ - nearZ
    return GLKMatrix4Make(
        2.0 / rsl, 0, 0, 0,
        0, 2.0 / tsb, 0, 0,
        0, 0, -2.0 / fsn, 0,
        -(right + left) / rsl, -(top + bottom) / tsb, -(farZ + nearZ) / fsn, 1
    )
}

public func GLKMatrix4MakeLookAt(
    _ eyeX: Float, _ eyeY: Float, _ eyeZ: Float,
    _ centerX: Float, _ centerY: Float, _ centerZ: Float,
    _ upX: Float, _ upY: Float, _ upZ: Float
) -> GLKMatrix4 {
    let ev = GLKVector3Make(eyeX, eyeY, eyeZ)
    let cv = GLKVector3Make(centerX, centerY, centerZ)
    let uv = GLKVector3Make(upX, upY, upZ)
    let n = GLKVector3Normalize(GLKVector3Add(ev, GLKVector3Negate(cv)))
    let u = GLKVector3Normalize(GLKVector3CrossProduct(uv, n))
    let v = GLKVector3CrossProduct(n, u)
    return GLKMatrix4Make(
        u.x, v.x, n.x, 0,
        u.y, v.y, n.y, 0,
        u.z, v.z, n.z, 0,
        GLKVector3DotProduct(GLKVector3Negate(u), ev),
        GLKVector3DotProduct(GLKVector3Negate(v), ev),
        GLKVector3DotProduct(GLKVector3Negate(n), ev),
        1
    )
}

public func GLKMatrix4GetMatrix3(_ matrix: GLKMatrix4) -> GLKMatrix3 {
    GLKMatrix3Make(
        matrix.m00, matrix.m01, matrix.m02,
        matrix.m10, matrix.m11, matrix.m12,
        matrix.m20, matrix.m21, matrix.m22
    )
}

public func GLKMatrix4GetMatrix2(_ matrix: GLKMatrix4) -> GLKMatrix2 {
    GLKMatrix2(m00: matrix.m00, m01: matrix.m01, m10: matrix.m10, m11: matrix.m11)
}

public func GLKMatrix4GetRow(_ matrix: GLKMatrix4, _ row: Int32) -> GLKVector4 {
    let r = Int(row)
    return GLKVector4Make(matrix[r], matrix[4 + r], matrix[8 + r], matrix[12 + r])
}

public func GLKMatrix4GetColumn(_ matrix: GLKMatrix4, _ column: Int32) -> GLKVector4 {
    let c = Int(column) * 4
    return GLKVector4Make(matrix[c], matrix[c + 1], matrix[c + 2], matrix[c + 3])
}

public func GLKMatrix4SetRow(_ matrix: GLKMatrix4, _ row: Int32, _ vector: GLKVector4) -> GLKMatrix4 {
    var result = matrix
    let r = Int(row)
    result[r] = vector.x
    result[4 + r] = vector.y
    result[8 + r] = vector.z
    result[12 + r] = vector.w
    return result
}

public func GLKMatrix4SetColumn(_ matrix: GLKMatrix4, _ column: Int32, _ vector: GLKVector4) -> GLKMatrix4 {
    var result = matrix
    let c = Int(column) * 4
    result[c] = vector.x
    result[c + 1] = vector.y
    result[c + 2] = vector.z
    result[c + 3] = vector.w
    return result
}

public func GLKMatrix4Transpose(_ matrix: GLKMatrix4) -> GLKMatrix4 {
    GLKMatrix4Make(
        matrix.m00, matrix.m10, matrix.m20, matrix.m30,
        matrix.m01, matrix.m11, matrix.m21, matrix.m31,
        matrix.m02, matrix.m12, matrix.m22, matrix.m32,
        matrix.m03, matrix.m13, matrix.m23, matrix.m33
    )
}

public func GLKMatrix4Multiply(_ matrixLeft: GLKMatrix4, _ matrixRight: GLKMatrix4) -> GLKMatrix4 {
    GLKMatrix4Make(
        matrixLeft.m00 * matrixRight.m00 + matrixLeft.m10 * matrixRight.m01 + matrixLeft.m20 * matrixRight.m02 + matrixLeft.m30 * matrixRight.m03,
        matrixLeft.m01 * matrixRight.m00 + matrixLeft.m11 * matrixRight.m01 + matrixLeft.m21 * matrixRight.m02 + matrixLeft.m31 * matrixRight.m03,
        matrixLeft.m02 * matrixRight.m00 + matrixLeft.m12 * matrixRight.m01 + matrixLeft.m22 * matrixRight.m02 + matrixLeft.m32 * matrixRight.m03,
        matrixLeft.m03 * matrixRight.m00 + matrixLeft.m13 * matrixRight.m01 + matrixLeft.m23 * matrixRight.m02 + matrixLeft.m33 * matrixRight.m03,
        matrixLeft.m00 * matrixRight.m10 + matrixLeft.m10 * matrixRight.m11 + matrixLeft.m20 * matrixRight.m12 + matrixLeft.m30 * matrixRight.m13,
        matrixLeft.m01 * matrixRight.m10 + matrixLeft.m11 * matrixRight.m11 + matrixLeft.m21 * matrixRight.m12 + matrixLeft.m31 * matrixRight.m13,
        matrixLeft.m02 * matrixRight.m10 + matrixLeft.m12 * matrixRight.m11 + matrixLeft.m22 * matrixRight.m12 + matrixLeft.m32 * matrixRight.m13,
        matrixLeft.m03 * matrixRight.m10 + matrixLeft.m13 * matrixRight.m11 + matrixLeft.m23 * matrixRight.m12 + matrixLeft.m33 * matrixRight.m13,
        matrixLeft.m00 * matrixRight.m20 + matrixLeft.m10 * matrixRight.m21 + matrixLeft.m20 * matrixRight.m22 + matrixLeft.m30 * matrixRight.m23,
        matrixLeft.m01 * matrixRight.m20 + matrixLeft.m11 * matrixRight.m21 + matrixLeft.m21 * matrixRight.m22 + matrixLeft.m31 * matrixRight.m23,
        matrixLeft.m02 * matrixRight.m20 + matrixLeft.m12 * matrixRight.m21 + matrixLeft.m22 * matrixRight.m22 + matrixLeft.m32 * matrixRight.m23,
        matrixLeft.m03 * matrixRight.m20 + matrixLeft.m13 * matrixRight.m21 + matrixLeft.m23 * matrixRight.m22 + matrixLeft.m33 * matrixRight.m23,
        matrixLeft.m00 * matrixRight.m30 + matrixLeft.m10 * matrixRight.m31 + matrixLeft.m20 * matrixRight.m32 + matrixLeft.m30 * matrixRight.m33,
        matrixLeft.m01 * matrixRight.m30 + matrixLeft.m11 * matrixRight.m31 + matrixLeft.m21 * matrixRight.m32 + matrixLeft.m31 * matrixRight.m33,
        matrixLeft.m02 * matrixRight.m30 + matrixLeft.m12 * matrixRight.m31 + matrixLeft.m22 * matrixRight.m32 + matrixLeft.m32 * matrixRight.m33,
        matrixLeft.m03 * matrixRight.m30 + matrixLeft.m13 * matrixRight.m31 + matrixLeft.m23 * matrixRight.m32 + matrixLeft.m33 * matrixRight.m33
    )
}

public func GLKMatrix4Add(_ matrixLeft: GLKMatrix4, _ matrixRight: GLKMatrix4) -> GLKMatrix4 {
    var result = matrixLeft
    var i = 0
    while i < 16 {
        result[i] = matrixLeft[i] + matrixRight[i]
        i += 1
    }
    return result
}

public func GLKMatrix4Subtract(_ matrixLeft: GLKMatrix4, _ matrixRight: GLKMatrix4) -> GLKMatrix4 {
    var result = matrixLeft
    var i = 0
    while i < 16 {
        result[i] = matrixLeft[i] - matrixRight[i]
        i += 1
    }
    return result
}

public func GLKMatrix4Translate(_ matrix: GLKMatrix4, _ tx: Float, _ ty: Float, _ tz: Float) -> GLKMatrix4 {
    var m = matrix
    m.m30 = matrix.m00 * tx + matrix.m10 * ty + matrix.m20 * tz + matrix.m30
    m.m31 = matrix.m01 * tx + matrix.m11 * ty + matrix.m21 * tz + matrix.m31
    m.m32 = matrix.m02 * tx + matrix.m12 * ty + matrix.m22 * tz + matrix.m32
    return m
}

public func GLKMatrix4TranslateWithVector3(_ matrix: GLKMatrix4, _ translationVector: GLKVector3) -> GLKMatrix4 {
    GLKMatrix4Translate(matrix, translationVector.x, translationVector.y, translationVector.z)
}

public func GLKMatrix4TranslateWithVector4(_ matrix: GLKMatrix4, _ translationVector: GLKVector4) -> GLKMatrix4 {
    GLKMatrix4Translate(matrix, translationVector.x, translationVector.y, translationVector.z)
}

public func GLKMatrix4Scale(_ matrix: GLKMatrix4, _ sx: Float, _ sy: Float, _ sz: Float) -> GLKMatrix4 {
    GLKMatrix4Make(
        matrix.m00 * sx, matrix.m01 * sx, matrix.m02 * sx, matrix.m03 * sx,
        matrix.m10 * sy, matrix.m11 * sy, matrix.m12 * sy, matrix.m13 * sy,
        matrix.m20 * sz, matrix.m21 * sz, matrix.m22 * sz, matrix.m23 * sz,
        matrix.m30, matrix.m31, matrix.m32, matrix.m33
    )
}

public func GLKMatrix4ScaleWithVector3(_ matrix: GLKMatrix4, _ scaleVector: GLKVector3) -> GLKMatrix4 {
    GLKMatrix4Scale(matrix, scaleVector.x, scaleVector.y, scaleVector.z)
}

public func GLKMatrix4ScaleWithVector4(_ matrix: GLKMatrix4, _ scaleVector: GLKVector4) -> GLKMatrix4 {
    GLKMatrix4Scale(matrix, scaleVector.x, scaleVector.y, scaleVector.z)
}

public func GLKMatrix4Rotate(_ matrix: GLKMatrix4, _ radians: Float, _ x: Float, _ y: Float, _ z: Float) -> GLKMatrix4 {
    GLKMatrix4Multiply(matrix, GLKMatrix4MakeRotation(radians, x, y, z))
}

public func GLKMatrix4RotateWithVector3(_ matrix: GLKMatrix4, _ radians: Float, _ axisVector: GLKVector3) -> GLKMatrix4 {
    GLKMatrix4Rotate(matrix, radians, axisVector.x, axisVector.y, axisVector.z)
}

public func GLKMatrix4RotateWithVector4(_ matrix: GLKMatrix4, _ radians: Float, _ axisVector: GLKVector4) -> GLKMatrix4 {
    GLKMatrix4Rotate(matrix, radians, axisVector.x, axisVector.y, axisVector.z)
}

public func GLKMatrix4RotateX(_ matrix: GLKMatrix4, _ radians: Float) -> GLKMatrix4 {
    GLKMatrix4Multiply(matrix, GLKMatrix4MakeXRotation(radians))
}

public func GLKMatrix4RotateY(_ matrix: GLKMatrix4, _ radians: Float) -> GLKMatrix4 {
    GLKMatrix4Multiply(matrix, GLKMatrix4MakeYRotation(radians))
}

public func GLKMatrix4RotateZ(_ matrix: GLKMatrix4, _ radians: Float) -> GLKMatrix4 {
    GLKMatrix4Multiply(matrix, GLKMatrix4MakeZRotation(radians))
}

public func GLKMatrix4MultiplyVector4(_ matrixLeft: GLKMatrix4, _ vectorRight: GLKVector4) -> GLKVector4 {
    GLKVector4Make(
        matrixLeft.m00 * vectorRight.x + matrixLeft.m10 * vectorRight.y + matrixLeft.m20 * vectorRight.z + matrixLeft.m30 * vectorRight.w,
        matrixLeft.m01 * vectorRight.x + matrixLeft.m11 * vectorRight.y + matrixLeft.m21 * vectorRight.z + matrixLeft.m31 * vectorRight.w,
        matrixLeft.m02 * vectorRight.x + matrixLeft.m12 * vectorRight.y + matrixLeft.m22 * vectorRight.z + matrixLeft.m32 * vectorRight.w,
        matrixLeft.m03 * vectorRight.x + matrixLeft.m13 * vectorRight.y + matrixLeft.m23 * vectorRight.z + matrixLeft.m33 * vectorRight.w
    )
}

public func GLKMatrix4MultiplyVector3(_ matrixLeft: GLKMatrix4, _ vectorRight: GLKVector3) -> GLKVector3 {
    let v4 = GLKMatrix4MultiplyVector4(matrixLeft, GLKVector4Make(vectorRight.x, vectorRight.y, vectorRight.z, 0))
    return GLKVector3Make(v4.x, v4.y, v4.z)
}

public func GLKMatrix4MultiplyVector3WithTranslation(_ matrixLeft: GLKMatrix4, _ vectorRight: GLKVector3) -> GLKVector3 {
    let v4 = GLKMatrix4MultiplyVector4(matrixLeft, GLKVector4Make(vectorRight.x, vectorRight.y, vectorRight.z, 1))
    return GLKVector3Make(v4.x, v4.y, v4.z)
}

public func GLKMatrix4MultiplyAndProjectVector3(_ matrixLeft: GLKMatrix4, _ vectorRight: GLKVector3) -> GLKVector3 {
    let v4 = GLKMatrix4MultiplyVector4(matrixLeft, GLKVector4Make(vectorRight.x, vectorRight.y, vectorRight.z, 1))
    return GLKVector3MultiplyScalar(GLKVector3Make(v4.x, v4.y, v4.z), 1.0 / v4.w)
}

public func GLKMatrix4MultiplyVector3Array(_ matrix: GLKMatrix4, _ vectors: UnsafeMutablePointer<GLKVector3>, _ vectorCount: Int) {
    var index = 0
    while index < vectorCount {
        vectors[index] = GLKMatrix4MultiplyVector3(matrix, vectors[index])
        index += 1
    }
}

public func GLKMatrix4MultiplyVector3ArrayWithTranslation(_ matrix: GLKMatrix4, _ vectors: UnsafeMutablePointer<GLKVector3>, _ vectorCount: Int) {
    var index = 0
    while index < vectorCount {
        vectors[index] = GLKMatrix4MultiplyVector3WithTranslation(matrix, vectors[index])
        index += 1
    }
}

public func GLKMatrix4MultiplyAndProjectVector3Array(_ matrix: GLKMatrix4, _ vectors: UnsafeMutablePointer<GLKVector3>, _ vectorCount: Int) {
    var index = 0
    while index < vectorCount {
        vectors[index] = GLKMatrix4MultiplyAndProjectVector3(matrix, vectors[index])
        index += 1
    }
}

public func GLKMatrix4MultiplyVector4Array(_ matrix: GLKMatrix4, _ vectors: UnsafeMutablePointer<GLKVector4>, _ vectorCount: Int) {
    var index = 0
    while index < vectorCount {
        vectors[index] = GLKMatrix4MultiplyVector4(matrix, vectors[index])
        index += 1
    }
}

public func GLKMatrix4Invert(_ matrix: GLKMatrix4, _ isInvertible: UnsafeMutablePointer<Bool>?) -> GLKMatrix4 {
    let m = matrix
    let a0 = m.m00 * m.m11 - m.m01 * m.m10
    let a1 = m.m00 * m.m12 - m.m02 * m.m10
    let a2 = m.m00 * m.m13 - m.m03 * m.m10
    let a3 = m.m01 * m.m12 - m.m02 * m.m11
    let a4 = m.m01 * m.m13 - m.m03 * m.m11
    let a5 = m.m02 * m.m13 - m.m03 * m.m12
    let b0 = m.m20 * m.m31 - m.m21 * m.m30
    let b1 = m.m20 * m.m32 - m.m22 * m.m30
    let b2 = m.m20 * m.m33 - m.m23 * m.m30
    let b3 = m.m21 * m.m32 - m.m22 * m.m31
    let b4 = m.m21 * m.m33 - m.m23 * m.m31
    let b5 = m.m22 * m.m33 - m.m23 * m.m32
    let det = a0 * b5 - a1 * b4 + a2 * b3 + a3 * b2 - a4 * b1 + a5 * b0
    if abs(det) < 1e-8 {
        isInvertible?.pointee = false
        return GLKMatrix4Identity
    }
    isInvertible?.pointee = true
    let invDet = 1.0 / det
    return GLKMatrix4Make(
        ( m.m11 * b5 - m.m12 * b4 + m.m13 * b3) * invDet,
        (-m.m01 * b5 + m.m02 * b4 - m.m03 * b3) * invDet,
        ( m.m31 * a5 - m.m32 * a4 + m.m33 * a3) * invDet,
        (-m.m21 * a5 + m.m22 * a4 - m.m23 * a3) * invDet,
        (-m.m10 * b5 + m.m12 * b2 - m.m13 * b1) * invDet,
        ( m.m00 * b5 - m.m02 * b2 + m.m03 * b1) * invDet,
        (-m.m30 * a5 + m.m32 * a2 - m.m33 * a1) * invDet,
        ( m.m20 * a5 - m.m22 * a2 + m.m23 * a1) * invDet,
        ( m.m10 * b4 - m.m11 * b2 + m.m13 * b0) * invDet,
        (-m.m00 * b4 + m.m01 * b2 - m.m03 * b0) * invDet,
        ( m.m30 * a4 - m.m31 * a2 + m.m33 * a0) * invDet,
        (-m.m20 * a4 + m.m21 * a2 - m.m23 * a0) * invDet,
        (-m.m10 * b3 + m.m11 * b1 - m.m12 * b0) * invDet,
        ( m.m00 * b3 - m.m01 * b1 + m.m02 * b0) * invDet,
        (-m.m30 * a3 + m.m31 * a1 - m.m32 * a0) * invDet,
        ( m.m20 * a3 - m.m21 * a1 + m.m22 * a0) * invDet
    )
}

public func GLKMatrix4InvertAndTranspose(_ matrix: GLKMatrix4, _ isInvertible: UnsafeMutablePointer<Bool>?) -> GLKMatrix4 {
    GLKMatrix4Transpose(GLKMatrix4Invert(matrix, isInvertible))
}

public func GLKMathDegreesToRadians(_ degrees: Float) -> Float {
    degrees * (.pi / 180.0)
}

public func GLKMathRadiansToDegrees(_ radians: Float) -> Float {
    radians * (180.0 / .pi)
}

public func GLKMathProject(
    _ object: GLKVector3, _ model: GLKMatrix4, _ projection: GLKMatrix4, _ viewport: UnsafeMutablePointer<Int32>
) -> GLKVector3 {
    let clip = GLKMatrix4MultiplyVector4(
        projection,
        GLKMatrix4MultiplyVector4(model, GLKVector4Make(object.x, object.y, object.z, 1))
    )
    let ndc = GLKVector4MultiplyScalar(clip, 1.0 / clip.w)
    return GLKVector3Make(
        (ndc.x * 0.5 + 0.5) * Float(viewport[2]) + Float(viewport[0]),
        (ndc.y * 0.5 + 0.5) * Float(viewport[3]) + Float(viewport[1]),
        ndc.z * 0.5 + 0.5
    )
}

public func GLKMathUnproject(
    _ window: GLKVector3,
    _ model: GLKMatrix4,
    _ projection: GLKMatrix4,
    _ viewport: UnsafeMutablePointer<Int32>,
    _ success: UnsafeMutablePointer<Bool>?
) -> GLKVector3 {
    var invertible = false
    let inverse = GLKMatrix4Invert(GLKMatrix4Multiply(projection, model), &invertible)
    success?.pointee = invertible
    guard invertible else {
        return GLKVector3Make(0, 0, 0)
    }
    let ndc = GLKVector4Make(
        (window.x - Float(viewport[0])) / Float(viewport[2]) * 2.0 - 1.0,
        (window.y - Float(viewport[1])) / Float(viewport[3]) * 2.0 - 1.0,
        window.z * 2.0 - 1.0,
        1
    )
    let object = GLKMatrix4MultiplyVector4(inverse, ndc)
    return GLKVector3MultiplyScalar(GLKVector3Make(object.x, object.y, object.z), 1.0 / object.w)
}
