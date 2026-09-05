import Foundation
import GLKit

func testGLKMatrix3Make() {
    let m = GLKMatrix3Make(1, 2, 3, 4, 5, 6, 7, 8, 9)
    glkCheck(m.m00 == 1 && m.m01 == 2 && m.m02 == 3, "Make col0")
    glkCheck(m.m10 == 4 && m.m20 == 7, "Make rest")
    let t = GLKMatrix3MakeAndTranspose(1, 2, 3, 4, 5, 6, 7, 8, 9)
    glkCheck(t.m00 == 1 && t.m01 == 4 && t.m02 == 7, "MakeAndTranspose")
    var values: [Float] = [1, 0, 0, 0, 1, 0, 0, 0, 1]
    let fromArray = GLKMatrix3MakeWithArray(&values)
    glkCheck(fromArray.m00 == 1 && fromArray.m11 == 1 && fromArray.m22 == 1, "MakeWithArray identity")
    var transposed: [Float] = [1, 2, 3, 4, 5, 6, 7, 8, 9]
    let fromT = GLKMatrix3MakeWithArrayAndTranspose(&transposed)
    glkCheck(fromT.m00 == 1 && fromT.m01 == 4 && fromT.m10 == 2, "MakeWithArrayAndTranspose")
    let rows = GLKMatrix3MakeWithRows(
        GLKVector3Make(1, 2, 3),
        GLKVector3Make(4, 4, 4),
        GLKVector3Make(5, 5, 5)
    )
    glkCheck(GLKVector3AllEqualToVector3(GLKMatrix3GetRow(rows, 0), GLKVector3Make(1, 2, 3)), "MakeWithRows")
    let cols = GLKMatrix3MakeWithColumns(
        GLKVector3Make(1, 0, 0),
        GLKVector3Make(0, 1, 0),
        GLKVector3Make(0, 0, 1)
    )
    glkCheck(cols.m00 == 1 && cols.m11 == 1 && cols.m22 == 1, "MakeWithColumns identity")
    let scaled = GLKMatrix3MakeScale(2, 3, 4)
    glkCheck(scaled.m00 == 2 && scaled.m11 == 3 && scaled.m22 == 4, "MakeScale")
    let q = GLKQuaternionMakeWithAngleAndAxis(GLKMathDegreesToRadians(90), 0, 0, 1)
    let fromQ = GLKMatrix3MakeWithQuaternion(q)
    let rotated = GLKMatrix3MultiplyVector3(fromQ, GLKVector3Make(1, 0, 0))
    glkCheck(glkNear(rotated.x, 0) && glkNear(rotated.y, 1), "MakeWithQuaternion")
}

func testGLKMatrix3Accessors() {
    let identity = GLKMatrix3Identity
    let m2 = GLKMatrix3GetMatrix2(identity)
    glkCheck(m2.m00 == 1 && m2.m11 == 1 && m2.m01 == 0, "GetMatrix2")
    glkCheck(GLKVector3AllEqualToVector3(GLKMatrix3GetRow(identity, 1), GLKVector3Make(0, 1, 0)), "GetRow")
    glkCheck(GLKVector3AllEqualToVector3(GLKMatrix3GetColumn(identity, 2), GLKVector3Make(0, 0, 1)), "GetColumn")
    let setRow = GLKMatrix3SetRow(identity, 0, GLKVector3Make(9, 8, 7))
    glkCheck(GLKVector3AllEqualToVector3(GLKMatrix3GetRow(setRow, 0), GLKVector3Make(1, 8, 7)) == false, "SetRow writes")
    glkCheck(GLKMatrix3GetRow(setRow, 0).x == 9, "SetRow x")
    let setCol = GLKMatrix3SetColumn(identity, 1, GLKVector3Make(1, 2, 3))
    glkCheck(GLKMatrix3GetColumn(setCol, 1).y == 2, "SetColumn")
    let transposed = GLKMatrix3Transpose(GLKMatrix3Make(1, 2, 3, 4, 5, 6, 7, 8, 9))
    glkCheck(transposed.m01 == 4 && transposed.m10 == 2, "Transpose")
    let added = GLKMatrix3Add(identity, identity)
    glkCheck(added.m00 == 2 && added.m11 == 2, "Add")
    let sub = GLKMatrix3Subtract(added, identity)
    glkCheck(sub.m00 == 1, "Subtract")
}

func testGLKMatrix3MultiplyAndTransform() {
    let scaled = GLKMatrix3Scale(GLKMatrix3Identity, 2, 3, 4)
    glkCheck(scaled.m00 == 2 && scaled.m11 == 3 && scaled.m22 == 4, "Scale")
    glkCheck(GLKMatrix3ScaleWithVector3(GLKMatrix3Identity, GLKVector3Make(2, 3, 4)).m11 == 3, "ScaleWithVector3")
    glkCheck(GLKMatrix3ScaleWithVector4(GLKMatrix3Identity, GLKVector4Make(2, 3, 4, 1)).m22 == 4, "ScaleWithVector4")
    let rotZ = GLKMatrix3MakeZRotation(GLKMathDegreesToRadians(90))
    let rotated = GLKMatrix3MultiplyVector3(rotZ, GLKVector3Make(1, 0, 0))
    glkCheck(glkNear(rotated.x, 0) && glkNear(rotated.y, 1), "MakeZRotation")
    let rotX = GLKMatrix3MakeXRotation(GLKMathDegreesToRadians(90))
    let rx = GLKMatrix3MultiplyVector3(rotX, GLKVector3Make(0, 1, 0))
    glkCheck(glkNear(rx.y, 0) && glkNear(rx.z, 1), "MakeXRotation")
    let rotY = GLKMatrix3MakeYRotation(GLKMathDegreesToRadians(90))
    let ry = GLKMatrix3MultiplyVector3(rotY, GLKVector3Make(0, 0, 1))
    glkCheck(glkNear(ry.z, 0) && glkNear(ry.x, 1), "MakeYRotation")
    let axis = GLKMatrix3MakeRotation(GLKMathDegreesToRadians(90), 0, 0, 1)
    let ra = GLKMatrix3MultiplyVector3(axis, GLKVector3Make(1, 0, 0))
    glkCheck(glkNear(ra.x, 0) && glkNear(ra.y, 1), "MakeRotation")
    let product = GLKMatrix3Multiply(GLKMatrix3MakeScale(2, 1, 1), GLKMatrix3Identity)
    glkCheck(product.m00 == 2, "Multiply")
    let r1 = GLKMatrix3Rotate(GLKMatrix3Identity, GLKMathDegreesToRadians(90), 0, 0, 1)
    glkCheck(glkNear(GLKMatrix3MultiplyVector3(r1, GLKVector3Make(1, 0, 0)).y, 1), "Rotate")
    let r2 = GLKMatrix3RotateWithVector3(GLKMatrix3Identity, GLKMathDegreesToRadians(90), GLKVector3Make(0, 0, 1))
    glkCheck(glkNear(GLKMatrix3MultiplyVector3(r2, GLKVector3Make(1, 0, 0)).y, 1), "RotateWithVector3")
    let r3 = GLKMatrix3RotateWithVector4(GLKMatrix3Identity, GLKMathDegreesToRadians(90), GLKVector4Make(0, 0, 1, 0))
    glkCheck(glkNear(GLKMatrix3MultiplyVector3(r3, GLKVector3Make(1, 0, 0)).y, 1), "RotateWithVector4")
    let rxm = GLKMatrix3RotateX(GLKMatrix3Identity, GLKMathDegreesToRadians(90))
    glkCheck(glkNear(GLKMatrix3MultiplyVector3(rxm, GLKVector3Make(0, 1, 0)).z, 1), "RotateX")
    let rym = GLKMatrix3RotateY(GLKMatrix3Identity, GLKMathDegreesToRadians(90))
    glkCheck(glkNear(GLKMatrix3MultiplyVector3(rym, GLKVector3Make(0, 0, 1)).x, 1), "RotateY")
    let rz = GLKMatrix3RotateZ(GLKMatrix3Identity, GLKMathDegreesToRadians(90))
    glkCheck(glkNear(GLKMatrix3MultiplyVector3(rz, GLKVector3Make(1, 0, 0)).y, 1), "RotateZ")
    var vectors = [GLKVector3Make(1, 0, 0), GLKVector3Make(0, 1, 0)]
    GLKMatrix3MultiplyVector3Array(rotZ, &vectors, 2)
    glkCheck(glkNear(vectors[0].y, 1) && glkNear(vectors[1].x, -1), "MultiplyVector3Array")
}

func testGLKMatrix3Invert() {
    var invertible = false
    let inverted = GLKMatrix3Invert(GLKMatrix3Identity, &invertible)
    glkCheck(invertible, "identity invertible")
    glkCheck(inverted.m00 == 1 && inverted.m11 == 1 && inverted.m22 == 1, "identity invert")
    var scaleInvertible = false
    let scaleInv = GLKMatrix3Invert(GLKMatrix3MakeScale(2, 4, 5), &scaleInvertible)
    glkCheck(scaleInvertible, "scale invertible")
    glkCheck(glkNear(scaleInv.m00, 0.5) && glkNear(scaleInv.m11, 0.25) && glkNear(scaleInv.m22, 0.2), "scale invert")
    var itFlag = false
    let invertedT = GLKMatrix3InvertAndTranspose(GLKMatrix3MakeScale(2, 1, 1), &itFlag)
    glkCheck(itFlag && glkNear(invertedT.m00, 0.5), "InvertAndTranspose")
}
