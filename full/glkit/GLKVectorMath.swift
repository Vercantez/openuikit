import Foundation

public func GLKVector2Make(_ x: Float, _ y: Float) -> GLKVector2 {
    GLKVector2(x: x, y: y)
}

public func GLKVector2MakeWithArray(_ values: UnsafeMutablePointer<Float>!) -> GLKVector2 {
    GLKVector2Make(values[0], values[1])
}

public func GLKVector2Negate(_ vector: GLKVector2) -> GLKVector2 {
    GLKVector2Make(-vector.x, -vector.y)
}

public func GLKVector2Add(_ vectorLeft: GLKVector2, _ vectorRight: GLKVector2) -> GLKVector2 {
    GLKVector2Make(vectorLeft.x + vectorRight.x, vectorLeft.y + vectorRight.y)
}

public func GLKVector2Subtract(_ vectorLeft: GLKVector2, _ vectorRight: GLKVector2) -> GLKVector2 {
    GLKVector2Make(vectorLeft.x - vectorRight.x, vectorLeft.y - vectorRight.y)
}

public func GLKVector2Multiply(_ vectorLeft: GLKVector2, _ vectorRight: GLKVector2) -> GLKVector2 {
    GLKVector2Make(vectorLeft.x * vectorRight.x, vectorLeft.y * vectorRight.y)
}

public func GLKVector2Divide(_ vectorLeft: GLKVector2, _ vectorRight: GLKVector2) -> GLKVector2 {
    GLKVector2Make(vectorLeft.x / vectorRight.x, vectorLeft.y / vectorRight.y)
}

public func GLKVector2AddScalar(_ vector: GLKVector2, _ value: Float) -> GLKVector2 {
    GLKVector2Make(vector.x + value, vector.y + value)
}

public func GLKVector2SubtractScalar(_ vector: GLKVector2, _ value: Float) -> GLKVector2 {
    GLKVector2Make(vector.x - value, vector.y - value)
}

public func GLKVector2MultiplyScalar(_ vector: GLKVector2, _ value: Float) -> GLKVector2 {
    GLKVector2Make(vector.x * value, vector.y * value)
}

public func GLKVector2DivideScalar(_ vector: GLKVector2, _ value: Float) -> GLKVector2 {
    GLKVector2Make(vector.x / value, vector.y / value)
}

public func GLKVector2Maximum(_ vectorLeft: GLKVector2, _ vectorRight: GLKVector2) -> GLKVector2 {
    GLKVector2Make(max(vectorLeft.x, vectorRight.x), max(vectorLeft.y, vectorRight.y))
}

public func GLKVector2Minimum(_ vectorLeft: GLKVector2, _ vectorRight: GLKVector2) -> GLKVector2 {
    GLKVector2Make(min(vectorLeft.x, vectorRight.x), min(vectorLeft.y, vectorRight.y))
}

public func GLKVector2AllEqualToVector2(_ vectorLeft: GLKVector2, _ vectorRight: GLKVector2) -> Bool {
    vectorLeft.x == vectorRight.x && vectorLeft.y == vectorRight.y
}

public func GLKVector2AllEqualToScalar(_ vector: GLKVector2, _ value: Float) -> Bool {
    vector.x == value && vector.y == value
}

public func GLKVector2AllGreaterThanVector2(_ vectorLeft: GLKVector2, _ vectorRight: GLKVector2) -> Bool {
    vectorLeft.x > vectorRight.x && vectorLeft.y > vectorRight.y
}

public func GLKVector2AllGreaterThanScalar(_ vector: GLKVector2, _ value: Float) -> Bool {
    vector.x > value && vector.y > value
}

public func GLKVector2AllGreaterThanOrEqualToVector2(_ vectorLeft: GLKVector2, _ vectorRight: GLKVector2) -> Bool {
    vectorLeft.x >= vectorRight.x && vectorLeft.y >= vectorRight.y
}

public func GLKVector2AllGreaterThanOrEqualToScalar(_ vector: GLKVector2, _ value: Float) -> Bool {
    vector.x >= value && vector.y >= value
}

public func GLKVector2Length(_ vector: GLKVector2) -> Float {
    sqrtf(vector.x * vector.x + vector.y * vector.y)
}

public func GLKVector2Distance(_ vectorStart: GLKVector2, _ vectorEnd: GLKVector2) -> Float {
    GLKVector2Length(GLKVector2Subtract(vectorEnd, vectorStart))
}

public func GLKVector2DotProduct(_ vectorLeft: GLKVector2, _ vectorRight: GLKVector2) -> Float {
    vectorLeft.x * vectorRight.x + vectorLeft.y * vectorRight.y
}

public func GLKVector2Normalize(_ vector: GLKVector2) -> GLKVector2 {
    GLKVector2MultiplyScalar(vector, 1.0 / GLKVector2Length(vector))
}

public func GLKVector2Lerp(_ vectorStart: GLKVector2, _ vectorEnd: GLKVector2, _ t: Float) -> GLKVector2 {
    GLKVector2Add(vectorStart, GLKVector2MultiplyScalar(GLKVector2Subtract(vectorEnd, vectorStart), t))
}

public func GLKVector2Project(_ vectorToProject: GLKVector2, _ projectionVector: GLKVector2) -> GLKVector2 {
    let scale = GLKVector2DotProduct(projectionVector, vectorToProject)
        / GLKVector2DotProduct(projectionVector, projectionVector)
    return GLKVector2MultiplyScalar(projectionVector, scale)
}

public func GLKVector3Make(_ x: Float, _ y: Float, _ z: Float) -> GLKVector3 {
    GLKVector3(x: x, y: y, z: z)
}

public func GLKVector3MakeWithArray(_ values: UnsafeMutablePointer<Float>!) -> GLKVector3 {
    GLKVector3Make(values[0], values[1], values[2])
}

public func GLKVector3Negate(_ vector: GLKVector3) -> GLKVector3 {
    GLKVector3Make(-vector.x, -vector.y, -vector.z)
}

public func GLKVector3Add(_ vectorLeft: GLKVector3, _ vectorRight: GLKVector3) -> GLKVector3 {
    GLKVector3Make(vectorLeft.x + vectorRight.x, vectorLeft.y + vectorRight.y, vectorLeft.z + vectorRight.z)
}

public func GLKVector3Subtract(_ vectorLeft: GLKVector3, _ vectorRight: GLKVector3) -> GLKVector3 {
    GLKVector3Make(vectorLeft.x - vectorRight.x, vectorLeft.y - vectorRight.y, vectorLeft.z - vectorRight.z)
}

public func GLKVector3Multiply(_ vectorLeft: GLKVector3, _ vectorRight: GLKVector3) -> GLKVector3 {
    GLKVector3Make(vectorLeft.x * vectorRight.x, vectorLeft.y * vectorRight.y, vectorLeft.z * vectorRight.z)
}

public func GLKVector3Divide(_ vectorLeft: GLKVector3, _ vectorRight: GLKVector3) -> GLKVector3 {
    GLKVector3Make(vectorLeft.x / vectorRight.x, vectorLeft.y / vectorRight.y, vectorLeft.z / vectorRight.z)
}

public func GLKVector3AddScalar(_ vector: GLKVector3, _ value: Float) -> GLKVector3 {
    GLKVector3Make(vector.x + value, vector.y + value, vector.z + value)
}

public func GLKVector3SubtractScalar(_ vector: GLKVector3, _ value: Float) -> GLKVector3 {
    GLKVector3Make(vector.x - value, vector.y - value, vector.z - value)
}

public func GLKVector3MultiplyScalar(_ vector: GLKVector3, _ value: Float) -> GLKVector3 {
    GLKVector3Make(vector.x * value, vector.y * value, vector.z * value)
}

public func GLKVector3DivideScalar(_ vector: GLKVector3, _ value: Float) -> GLKVector3 {
    GLKVector3Make(vector.x / value, vector.y / value, vector.z / value)
}

public func GLKVector3Maximum(_ vectorLeft: GLKVector3, _ vectorRight: GLKVector3) -> GLKVector3 {
    GLKVector3Make(
        max(vectorLeft.x, vectorRight.x),
        max(vectorLeft.y, vectorRight.y),
        max(vectorLeft.z, vectorRight.z)
    )
}

public func GLKVector3Minimum(_ vectorLeft: GLKVector3, _ vectorRight: GLKVector3) -> GLKVector3 {
    GLKVector3Make(
        min(vectorLeft.x, vectorRight.x),
        min(vectorLeft.y, vectorRight.y),
        min(vectorLeft.z, vectorRight.z)
    )
}

public func GLKVector3AllEqualToVector3(_ vectorLeft: GLKVector3, _ vectorRight: GLKVector3) -> Bool {
    vectorLeft.x == vectorRight.x && vectorLeft.y == vectorRight.y && vectorLeft.z == vectorRight.z
}

public func GLKVector3AllEqualToScalar(_ vector: GLKVector3, _ value: Float) -> Bool {
    vector.x == value && vector.y == value && vector.z == value
}

public func GLKVector3AllGreaterThanVector3(_ vectorLeft: GLKVector3, _ vectorRight: GLKVector3) -> Bool {
    vectorLeft.x > vectorRight.x && vectorLeft.y > vectorRight.y && vectorLeft.z > vectorRight.z
}

public func GLKVector3AllGreaterThanScalar(_ vector: GLKVector3, _ value: Float) -> Bool {
    vector.x > value && vector.y > value && vector.z > value
}

public func GLKVector3AllGreaterThanOrEqualToVector3(_ vectorLeft: GLKVector3, _ vectorRight: GLKVector3) -> Bool {
    vectorLeft.x >= vectorRight.x && vectorLeft.y >= vectorRight.y && vectorLeft.z >= vectorRight.z
}

public func GLKVector3AllGreaterThanOrEqualToScalar(_ vector: GLKVector3, _ value: Float) -> Bool {
    vector.x >= value && vector.y >= value && vector.z >= value
}

public func GLKVector3Length(_ vector: GLKVector3) -> Float {
    sqrtf(vector.x * vector.x + vector.y * vector.y + vector.z * vector.z)
}

public func GLKVector3Distance(_ vectorStart: GLKVector3, _ vectorEnd: GLKVector3) -> Float {
    GLKVector3Length(GLKVector3Subtract(vectorEnd, vectorStart))
}

public func GLKVector3DotProduct(_ vectorLeft: GLKVector3, _ vectorRight: GLKVector3) -> Float {
    vectorLeft.x * vectorRight.x + vectorLeft.y * vectorRight.y + vectorLeft.z * vectorRight.z
}

public func GLKVector3CrossProduct(_ vectorLeft: GLKVector3, _ vectorRight: GLKVector3) -> GLKVector3 {
    GLKVector3Make(
        vectorLeft.y * vectorRight.z - vectorLeft.z * vectorRight.y,
        vectorLeft.z * vectorRight.x - vectorLeft.x * vectorRight.z,
        vectorLeft.x * vectorRight.y - vectorLeft.y * vectorRight.x
    )
}

public func GLKVector3Normalize(_ vector: GLKVector3) -> GLKVector3 {
    GLKVector3MultiplyScalar(vector, 1.0 / GLKVector3Length(vector))
}

public func GLKVector3Lerp(_ vectorStart: GLKVector3, _ vectorEnd: GLKVector3, _ t: Float) -> GLKVector3 {
    GLKVector3Add(vectorStart, GLKVector3MultiplyScalar(GLKVector3Subtract(vectorEnd, vectorStart), t))
}

public func GLKVector3Project(_ vectorToProject: GLKVector3, _ projectionVector: GLKVector3) -> GLKVector3 {
    let scale = GLKVector3DotProduct(projectionVector, vectorToProject)
        / GLKVector3DotProduct(projectionVector, projectionVector)
    return GLKVector3MultiplyScalar(projectionVector, scale)
}

public func GLKVector4Make(_ x: Float, _ y: Float, _ z: Float, _ w: Float) -> GLKVector4 {
    GLKVector4(x: x, y: y, z: z, w: w)
}

public func GLKVector4MakeWithArray(_ values: UnsafeMutablePointer<Float>!) -> GLKVector4 {
    GLKVector4Make(values[0], values[1], values[2], values[3])
}

public func GLKVector4MakeWithVector3(_ vector: GLKVector3, _ w: Float) -> GLKVector4 {
    GLKVector4Make(vector.x, vector.y, vector.z, w)
}

public func GLKVector4Negate(_ vector: GLKVector4) -> GLKVector4 {
    GLKVector4Make(-vector.x, -vector.y, -vector.z, -vector.w)
}

public func GLKVector4Add(_ vectorLeft: GLKVector4, _ vectorRight: GLKVector4) -> GLKVector4 {
    GLKVector4Make(
        vectorLeft.x + vectorRight.x,
        vectorLeft.y + vectorRight.y,
        vectorLeft.z + vectorRight.z,
        vectorLeft.w + vectorRight.w
    )
}

public func GLKVector4Subtract(_ vectorLeft: GLKVector4, _ vectorRight: GLKVector4) -> GLKVector4 {
    GLKVector4Make(
        vectorLeft.x - vectorRight.x,
        vectorLeft.y - vectorRight.y,
        vectorLeft.z - vectorRight.z,
        vectorLeft.w - vectorRight.w
    )
}

public func GLKVector4Multiply(_ vectorLeft: GLKVector4, _ vectorRight: GLKVector4) -> GLKVector4 {
    GLKVector4Make(
        vectorLeft.x * vectorRight.x,
        vectorLeft.y * vectorRight.y,
        vectorLeft.z * vectorRight.z,
        vectorLeft.w * vectorRight.w
    )
}

public func GLKVector4Divide(_ vectorLeft: GLKVector4, _ vectorRight: GLKVector4) -> GLKVector4 {
    GLKVector4Make(
        vectorLeft.x / vectorRight.x,
        vectorLeft.y / vectorRight.y,
        vectorLeft.z / vectorRight.z,
        vectorLeft.w / vectorRight.w
    )
}

public func GLKVector4AddScalar(_ vector: GLKVector4, _ value: Float) -> GLKVector4 {
    GLKVector4Make(vector.x + value, vector.y + value, vector.z + value, vector.w + value)
}

public func GLKVector4SubtractScalar(_ vector: GLKVector4, _ value: Float) -> GLKVector4 {
    GLKVector4Make(vector.x - value, vector.y - value, vector.z - value, vector.w - value)
}

public func GLKVector4MultiplyScalar(_ vector: GLKVector4, _ value: Float) -> GLKVector4 {
    GLKVector4Make(vector.x * value, vector.y * value, vector.z * value, vector.w * value)
}

public func GLKVector4DivideScalar(_ vector: GLKVector4, _ value: Float) -> GLKVector4 {
    GLKVector4Make(vector.x / value, vector.y / value, vector.z / value, vector.w / value)
}

public func GLKVector4Maximum(_ vectorLeft: GLKVector4, _ vectorRight: GLKVector4) -> GLKVector4 {
    GLKVector4Make(
        max(vectorLeft.x, vectorRight.x),
        max(vectorLeft.y, vectorRight.y),
        max(vectorLeft.z, vectorRight.z),
        max(vectorLeft.w, vectorRight.w)
    )
}

public func GLKVector4Minimum(_ vectorLeft: GLKVector4, _ vectorRight: GLKVector4) -> GLKVector4 {
    GLKVector4Make(
        min(vectorLeft.x, vectorRight.x),
        min(vectorLeft.y, vectorRight.y),
        min(vectorLeft.z, vectorRight.z),
        min(vectorLeft.w, vectorRight.w)
    )
}

public func GLKVector4AllEqualToVector4(_ vectorLeft: GLKVector4, _ vectorRight: GLKVector4) -> Bool {
    vectorLeft.x == vectorRight.x
        && vectorLeft.y == vectorRight.y
        && vectorLeft.z == vectorRight.z
        && vectorLeft.w == vectorRight.w
}

public func GLKVector4AllEqualToScalar(_ vector: GLKVector4, _ value: Float) -> Bool {
    vector.x == value && vector.y == value && vector.z == value && vector.w == value
}

public func GLKVector4AllGreaterThanVector4(_ vectorLeft: GLKVector4, _ vectorRight: GLKVector4) -> Bool {
    vectorLeft.x > vectorRight.x
        && vectorLeft.y > vectorRight.y
        && vectorLeft.z > vectorRight.z
        && vectorLeft.w > vectorRight.w
}

public func GLKVector4AllGreaterThanScalar(_ vector: GLKVector4, _ value: Float) -> Bool {
    vector.x > value && vector.y > value && vector.z > value && vector.w > value
}

public func GLKVector4AllGreaterThanOrEqualToVector4(_ vectorLeft: GLKVector4, _ vectorRight: GLKVector4) -> Bool {
    vectorLeft.x >= vectorRight.x
        && vectorLeft.y >= vectorRight.y
        && vectorLeft.z >= vectorRight.z
        && vectorLeft.w >= vectorRight.w
}

public func GLKVector4AllGreaterThanOrEqualToScalar(_ vector: GLKVector4, _ value: Float) -> Bool {
    vector.x >= value && vector.y >= value && vector.z >= value && vector.w >= value
}

public func GLKVector4Length(_ vector: GLKVector4) -> Float {
    sqrtf(vector.x * vector.x + vector.y * vector.y + vector.z * vector.z + vector.w * vector.w)
}

public func GLKVector4Distance(_ vectorStart: GLKVector4, _ vectorEnd: GLKVector4) -> Float {
    GLKVector4Length(GLKVector4Subtract(vectorEnd, vectorStart))
}

public func GLKVector4DotProduct(_ vectorLeft: GLKVector4, _ vectorRight: GLKVector4) -> Float {
    vectorLeft.x * vectorRight.x
        + vectorLeft.y * vectorRight.y
        + vectorLeft.z * vectorRight.z
        + vectorLeft.w * vectorRight.w
}

public func GLKVector4CrossProduct(_ vectorLeft: GLKVector4, _ vectorRight: GLKVector4) -> GLKVector4 {
    GLKVector4Make(
        vectorLeft.y * vectorRight.z - vectorLeft.z * vectorRight.y,
        vectorLeft.z * vectorRight.x - vectorLeft.x * vectorRight.z,
        vectorLeft.x * vectorRight.y - vectorLeft.y * vectorRight.x,
        0
    )
}

public func GLKVector4Normalize(_ vector: GLKVector4) -> GLKVector4 {
    GLKVector4MultiplyScalar(vector, 1.0 / GLKVector4Length(vector))
}

public func GLKVector4Lerp(_ vectorStart: GLKVector4, _ vectorEnd: GLKVector4, _ t: Float) -> GLKVector4 {
    GLKVector4Add(vectorStart, GLKVector4MultiplyScalar(GLKVector4Subtract(vectorEnd, vectorStart), t))
}

public func GLKVector4Project(_ vectorToProject: GLKVector4, _ projectionVector: GLKVector4) -> GLKVector4 {
    let scale = GLKVector4DotProduct(projectionVector, vectorToProject)
        / GLKVector4DotProduct(projectionVector, projectionVector)
    return GLKVector4MultiplyScalar(projectionVector, scale)
}
