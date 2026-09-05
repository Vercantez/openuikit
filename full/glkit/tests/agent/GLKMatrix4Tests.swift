import Foundation
import GLKit

func testGLKMatrix4Make() {
    let m = GLKMatrix4Make(
        1, 0, 0, 0,
        0, 1, 0, 0,
        0, 0, 1, 0,
        0, 0, 0, 1
    )
    glkCheck(m.m00 == 1 && m.m33 == 1, "Make identity")
    let t = GLKMatrix4MakeAndTranspose(
        1, 2, 3, 4,
        5, 6, 7, 8,
        9, 10, 11, 12,
        13, 14, 15, 16
    )
    glkCheck(t.m00 == 1 && t.m01 == 5 && t.m10 == 2, "MakeAndTranspose")
    var values: [Float] = [
        1, 0, 0, 0,
        0, 1, 0, 0,
        0, 0, 1, 0,
        0, 0, 0, 1
    ]
    let fromArray = GLKMatrix4MakeWithArray(&values)
    glkCheck(fromArray.m00 == 1 && fromArray.m33 == 1, "MakeWithArray")
    var transposed: [Float] = [
        1, 2, 3, 4,
        5, 6, 7, 8,
        9, 10, 11, 12,
        13, 14, 15, 16
    ]
    let fromT = GLKMatrix4MakeWithArrayAndTranspose(&transposed)
    glkCheck(fromT.m00 == 1 && fromT.m01 == 5, "MakeWithArrayAndTranspose")
    let rows = GLKMatrix4MakeWithRows(
        GLKVector4Make(1, 0, 0, 0),
        GLKVector4Make(0, 1, 0, 0),
        GLKVector4Make(0, 0, 1, 0),
        GLKVector4Make(0, 0, 0, 1)
    )
    glkCheck(GLKVector4AllEqualToVector4(GLKMatrix4GetRow(rows, 0), GLKVector4Make(1, 0, 0, 0)), "MakeWithRows")
    let cols = GLKMatrix4MakeWithColumns(
        GLKVector4Make(1, 0, 0, 0),
        GLKVector4Make(0, 1, 0, 0),
        GLKVector4Make(0, 0, 1, 0),
        GLKVector4Make(0, 0, 0, 1)
    )
    glkCheck(cols.m11 == 1 && cols.m33 == 1, "MakeWithColumns")
    let q = GLKQuaternionMakeWithAngleAndAxis(GLKMathDegreesToRadians(90), 0, 0, 1)
    let fromQ = GLKMatrix4MakeWithQuaternion(q)
    let rotated = GLKMatrix4MultiplyVector3(fromQ, GLKVector3Make(1, 0, 0))
    glkCheck(glkNear(rotated.x, 0) && glkNear(rotated.y, 1), "MakeWithQuaternion")
}

func testGLKMatrix4Accessors() {
    let identity = GLKMatrix4Identity
    glkCheck(GLKMatrix4GetMatrix3(identity).m00 == 1, "GetMatrix3")
    glkCheck(GLKMatrix4GetMatrix2(identity).m11 == 1, "GetMatrix2")
    glkCheck(GLKMatrix4GetColumn(identity, 0).x == 1, "GetColumn")
    glkCheck(GLKMatrix4GetRow(identity, 3).w == 1, "GetRow")
    let setRow = GLKMatrix4SetRow(identity, 0, GLKVector4Make(9, 8, 7, 6))
    glkCheck(GLKMatrix4GetRow(setRow, 0).x == 9, "SetRow")
    let setCol = GLKMatrix4SetColumn(identity, 3, GLKVector4Make(1, 2, 3, 4))
    glkCheck(GLKMatrix4GetColumn(setCol, 3).z == 3, "SetColumn")
    let transposed = GLKMatrix4Transpose(GLKMatrix4MakeTranslation(1, 2, 3))
    glkCheck(transposed.m03 == 1 && transposed.m30 == 0, "Transpose")
    let added = GLKMatrix4Add(identity, identity)
    glkCheck(added.m00 == 2 && added.m33 == 2, "Add")
    let sub = GLKMatrix4Subtract(added, identity)
    glkCheck(sub.m00 == 1, "Subtract")
    let product = GLKMatrix4Multiply(GLKMatrix4MakeScale(2, 1, 1), identity)
    glkCheck(product.m00 == 2, "Multiply")
}

func testGLKMatrix4TranslateScaleRotate() {
    let translated = GLKMatrix4MultiplyVector3WithTranslation(
        GLKMatrix4MakeTranslation(1, 2, 3),
        GLKVector3Make(4, 5, 6)
    )
    glkCheck(translated.x == 5 && translated.y == 7 && translated.z == 9, "MakeTranslation")
    let scaled = GLKMatrix4MakeScale(2, 3, 4)
    glkCheck(scaled.m00 == 2 && scaled.m11 == 3 && scaled.m22 == 4, "MakeScale")
    let rotated = GLKMatrix4MultiplyVector3(
        GLKMatrix4MakeZRotation(GLKMathDegreesToRadians(90)),
        GLKVector3Make(1, 0, 0)
    )
    glkCheck(glkNear(rotated.x, 0) && glkNear(rotated.y, 1), "MakeZRotation")
    let rx = GLKMatrix4MultiplyVector3(GLKMatrix4MakeXRotation(GLKMathDegreesToRadians(90)), GLKVector3Make(0, 1, 0))
    glkCheck(glkNear(rx.y, 0) && glkNear(rx.z, 1), "MakeXRotation")
    let ry = GLKMatrix4MultiplyVector3(GLKMatrix4MakeYRotation(GLKMathDegreesToRadians(90)), GLKVector3Make(0, 0, 1))
    glkCheck(glkNear(ry.z, 0) && glkNear(ry.x, 1), "MakeYRotation")
    let axis = GLKMatrix4MakeRotation(GLKMathDegreesToRadians(90), 0, 0, 1)
    glkCheck(glkNear(GLKMatrix4MultiplyVector3(axis, GLKVector3Make(1, 0, 0)).y, 1), "MakeRotation")
    let t = GLKMatrix4Translate(GLKMatrix4Identity, 1, 2, 3)
    glkCheck(t.m30 == 1 && t.m31 == 2 && t.m32 == 3, "Translate")
    glkCheck(GLKMatrix4TranslateWithVector3(identityLike(), GLKVector3Make(1, 2, 3)).m31 == 2, "TranslateWithVector3")
    glkCheck(GLKMatrix4TranslateWithVector4(identityLike(), GLKVector4Make(1, 2, 3, 1)).m32 == 3, "TranslateWithVector4")
    glkCheck(GLKMatrix4Scale(identityLike(), 2, 3, 4).m11 == 3, "Scale")
    glkCheck(GLKMatrix4ScaleWithVector3(identityLike(), GLKVector3Make(2, 3, 4)).m22 == 4, "ScaleWithVector3")
    glkCheck(GLKMatrix4ScaleWithVector4(identityLike(), GLKVector4Make(2, 3, 4, 1)).m00 == 2, "ScaleWithVector4")
    let r = GLKMatrix4Rotate(identityLike(), GLKMathDegreesToRadians(90), 0, 0, 1)
    glkCheck(glkNear(GLKMatrix4MultiplyVector3(r, GLKVector3Make(1, 0, 0)).y, 1), "Rotate")
    let r3 = GLKMatrix4RotateWithVector3(identityLike(), GLKMathDegreesToRadians(90), GLKVector3Make(0, 0, 1))
    glkCheck(glkNear(GLKMatrix4MultiplyVector3(r3, GLKVector3Make(1, 0, 0)).y, 1), "RotateWithVector3")
    let r4 = GLKMatrix4RotateWithVector4(identityLike(), GLKMathDegreesToRadians(90), GLKVector4Make(0, 0, 1, 0))
    glkCheck(glkNear(GLKMatrix4MultiplyVector3(r4, GLKVector3Make(1, 0, 0)).y, 1), "RotateWithVector4")
    glkCheck(glkNear(GLKMatrix4MultiplyVector3(GLKMatrix4RotateX(identityLike(), GLKMathDegreesToRadians(90)), GLKVector3Make(0, 1, 0)).z, 1), "RotateX")
    glkCheck(glkNear(GLKMatrix4MultiplyVector3(GLKMatrix4RotateY(identityLike(), GLKMathDegreesToRadians(90)), GLKVector3Make(0, 0, 1)).x, 1), "RotateY")
    glkCheck(glkNear(GLKMatrix4MultiplyVector3(GLKMatrix4RotateZ(identityLike(), GLKMathDegreesToRadians(90)), GLKVector3Make(1, 0, 0)).y, 1), "RotateZ")
}

private func identityLike() -> GLKMatrix4 { GLKMatrix4Identity }

func testGLKMatrix4Projection() {
    let look = GLKMatrix4MakeLookAt(0, 0, 1, 0, 0, 0, 0, 1, 0)
    let projected = GLKMatrix4MultiplyAndProjectVector3(look, GLKVector3Make(0, 0, 0))
    glkCheck(glkNear(projected.z, -1), "MakeLookAt")
    let persp = GLKMatrix4MakePerspective(GLKMathDegreesToRadians(90), 1, 0.1, 100)
    glkCheck(persp.m11 != 0 && persp.m23 == -1, "MakePerspective")
    let frustum = GLKMatrix4MakeFrustum(-1, 1, -1, 1, 0.1, 100)
    glkCheck(frustum.m00 != 0 && frustum.m23 == -1, "MakeFrustum")
    let ortho = GLKMatrix4MakeOrtho(-1, 1, -1, 1, -1, 1)
    glkCheck(ortho.m00 == 1 && ortho.m11 == 1 && ortho.m33 == 1, "MakeOrtho")
    let v4 = GLKMatrix4MultiplyVector4(GLKMatrix4MakeTranslation(1, 0, 0), GLKVector4Make(2, 0, 0, 1))
    glkCheck(v4.x == 3 && v4.w == 1, "MultiplyVector4")
    let dir = GLKMatrix4MultiplyVector3(GLKMatrix4MakeTranslation(1, 0, 0), GLKVector3Make(1, 0, 0))
    glkCheck(dir.x == 1, "MultiplyVector3 w=0 ignores translation")
}

func testGLKMatrix4Invert() {
    var invertible = false
    let inverted = GLKMatrix4Invert(GLKMatrix4Identity, &invertible)
    glkCheck(invertible, "identity invertible")
    glkCheck(GLKMatrix4GetColumn(inverted, 0).x == 1, "invert col0")
    glkCheck(GLKMatrix4GetColumn(inverted, 3).w == 1, "invert col3")
    var scaleFlag = false
    let scaleInv = GLKMatrix4Invert(GLKMatrix4MakeScale(2, 4, 5), &scaleFlag)
    glkCheck(scaleFlag && glkNear(scaleInv.m00, 0.5) && glkNear(scaleInv.m11, 0.25), "scale invert")
    var itFlag = false
    let invertedT = GLKMatrix4InvertAndTranspose(GLKMatrix4MakeScale(2, 1, 1), &itFlag)
    glkCheck(itFlag && glkNear(invertedT.m00, 0.5), "InvertAndTranspose")
}

func testGLKMatrix4VectorArrays() {
    var v3 = [GLKVector3Make(1, 0, 0), GLKVector3Make(0, 1, 0)]
    GLKMatrix4MultiplyVector3Array(GLKMatrix4MakeZRotation(GLKMathDegreesToRadians(90)), &v3, 2)
    glkCheck(glkNear(v3[0].y, 1) && glkNear(v3[1].x, -1), "MultiplyVector3Array")
    var translated = [GLKVector3Make(1, 0, 0)]
    GLKMatrix4MultiplyVector3ArrayWithTranslation(GLKMatrix4MakeTranslation(2, 0, 0), &translated, 1)
    glkCheck(translated[0].x == 3, "MultiplyVector3ArrayWithTranslation")
    var projected = [GLKVector3Make(0, 0, 0)]
    GLKMatrix4MultiplyAndProjectVector3Array(GLKMatrix4MakeLookAt(0, 0, 1, 0, 0, 0, 0, 1, 0), &projected, 1)
    glkCheck(glkNear(projected[0].z, -1), "MultiplyAndProjectVector3Array")
    var v4 = [GLKVector4Make(1, 0, 0, 1)]
    GLKMatrix4MultiplyVector4Array(GLKMatrix4MakeTranslation(2, 0, 0), &v4, 1)
    glkCheck(v4[0].x == 3, "MultiplyVector4Array")
}

func testGLKMathAngleConversion() {
    glkCheck(glkNear(GLKMathDegreesToRadians(180), Float.pi), "degrees to radians")
    glkCheck(glkNear(GLKMathRadiansToDegrees(Float.pi), 180), "radians to degrees")
}

func testGLKMathProjectUnproject() {
    var viewport: [Int32] = [0, 0, 100, 100]
    let model = GLKMatrix4Identity
    let projection = GLKMatrix4MakeOrtho(0, 100, 0, 100, -1, 1)
    let window = GLKMathProject(GLKVector3Make(50, 25, 0), model, projection, &viewport)
    glkCheck(glkNear(window.x, 50) && glkNear(window.y, 25), "GLKMathProject")
    var success = false
    let object = GLKMathUnproject(window, model, projection, &viewport, &success)
    glkCheck(success, "unproject success")
    glkCheck(glkNear(object.x, 50) && glkNear(object.y, 25), "GLKMathUnproject round-trip")
}
