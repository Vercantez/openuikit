import Foundation
import GLKit

func testGLKQuaternionMake() {
    let q = GLKQuaternionMake(0, 0, 0, 1)
    glkCheck(q.x == 0 && q.w == 1, "Make")
    glkCheck(GLKQuaternionIdentity.w == 1 && GLKQuaternionIdentity.x == 0, "Identity")
    let fromV = GLKQuaternionMakeWithVector3(GLKVector3Make(1, 2, 3), 4)
    glkCheck(fromV.x == 1 && fromV.y == 2 && fromV.z == 3 && fromV.w == 4, "MakeWithVector3")
    var values: [Float] = [0, 0, 0, 1]
    let fromArray = GLKQuaternionMakeWithArray(&values)
    glkCheck(fromArray.w == 1, "MakeWithArray")
    let fromAxis = GLKQuaternionMakeWithAngleAndAxis(GLKMathDegreesToRadians(90), 0, 0, 1)
    glkCheck(glkNear(GLKQuaternionAngle(fromAxis), GLKMathDegreesToRadians(90)), "MakeWithAngleAndAxis")
    let fromVAxis = GLKQuaternionMakeWithAngleAndVector3Axis(
        GLKMathDegreesToRadians(90),
        GLKVector3Make(0, 0, 1)
    )
    glkCheck(glkNear(fromVAxis.w, fromAxis.w), "MakeWithAngleAndVector3Axis")
}

func testGLKQuaternionAlgebra() {
    let q = GLKQuaternionMake(0, 0, 0, 2)
    glkCheck(GLKQuaternionLength(q) == 2, "length")
    let n = GLKQuaternionNormalize(q)
    glkCheck(glkNear(n.w, 1) && glkNear(GLKQuaternionLength(n), 1), "normalize")
    let conj = GLKQuaternionConjugate(GLKQuaternionMake(1, 2, 3, 4))
    glkCheck(conj.x == -1 && conj.y == -2 && conj.z == -3 && conj.w == 4, "conjugate")
    let inv = GLKQuaternionInvert(GLKQuaternionIdentity)
    glkCheck(glkNear(inv.w, 1) && glkNear(inv.x, 0), "invert identity")
    let a = GLKQuaternionMake(1, 2, 3, 4)
    let b = GLKQuaternionMake(1, 0, 0, 0)
    glkCheck(glkQuatNear(GLKQuaternionAdd(a, b), GLKQuaternionMake(2, 2, 3, 4)), "add")
    glkCheck(glkQuatNear(GLKQuaternionSubtract(a, b), GLKQuaternionMake(0, 2, 3, 4)), "subtract")
    let product = GLKQuaternionMultiply(GLKQuaternionIdentity, q)
    glkCheck(glkNear(product.w, 2), "multiply identity")
}

func testGLKQuaternionRotation() {
    let q = GLKQuaternionMakeWithAngleAndAxis(GLKMathDegreesToRadians(180), 0, 0, 1)
    let rotated = GLKQuaternionRotateVector3(q, GLKVector3Make(1, 0, 0))
    glkCheck(glkNear(rotated.x, -1) && glkNear(rotated.y, 0), "RotateVector3")
    let axis = GLKQuaternionAxis(q)
    glkCheck(glkNear(abs(axis.z), 1), "Axis z")
    glkCheck(glkNear(GLKQuaternionAngle(q), Float.pi), "Angle 180")
    var v3 = [GLKVector3Make(1, 0, 0), GLKVector3Make(0, 1, 0)]
    GLKQuaternionRotateVector3Array(q, &v3, 2)
    glkCheck(glkNear(v3[0].x, -1) && glkNear(v3[1].y, -1), "RotateVector3Array")
    let v4 = GLKQuaternionRotateVector4(q, GLKVector4Make(1, 0, 0, 7))
    glkCheck(glkNear(v4.x, -1) && v4.w == 7, "RotateVector4 preserves w")
    var arr4 = [GLKVector4Make(1, 0, 0, 3)]
    GLKQuaternionRotateVector4Array(q, &arr4, 1)
    glkCheck(glkNear(arr4[0].x, -1) && arr4[0].w == 3, "RotateVector4Array")
    let m3 = GLKMatrix3MakeWithQuaternion(q)
    let fromM3 = GLKQuaternionMakeWithMatrix3(m3)
    let round = GLKQuaternionRotateVector3(fromM3, GLKVector3Make(1, 0, 0))
    glkCheck(glkNear(round.x, -1), "MakeWithMatrix3")
    let m4 = GLKMatrix4MakeWithQuaternion(q)
    let fromM4 = GLKQuaternionMakeWithMatrix4(m4)
    let round4 = GLKQuaternionRotateVector3(fromM4, GLKVector3Make(1, 0, 0))
    glkCheck(glkNear(round4.x, -1), "MakeWithMatrix4")
}

func testGLKQuaternionSlerp() {
    let start = GLKQuaternionIdentity
    let end = GLKQuaternionMakeWithAngleAndAxis(GLKMathDegreesToRadians(90), 0, 0, 1)
    let mid = GLKQuaternionSlerp(start, end, 0)
    glkCheck(glkNear(mid.w, 1), "slerp t=0")
    let other = GLKQuaternionSlerp(start, end, 1)
    let rotated = GLKQuaternionRotateVector3(other, GLKVector3Make(1, 0, 0))
    glkCheck(glkNear(rotated.x, 0) && glkNear(rotated.y, 1), "slerp t=1")
    let half = GLKQuaternionSlerp(start, end, 0.5)
    glkCheck(glkNear(GLKQuaternionLength(half), 1), "slerp unit")
}
