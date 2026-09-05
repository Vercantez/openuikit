import Foundation
import GLKit

func testGLKVector3Make() {
    let made = GLKVector3Make(1, 2, 3)
    glkCheck(made.x == 1 && made.y == 2 && made.z == 3, "GLKVector3Make")
    glkCheck(made.r == 1 && made.g == 2 && made.b == 3, "rgb aliases")
    glkCheck(made.s == 1 && made.t == 2 && made.p == 3, "stp aliases")
    var values: [Float] = [7, 8, 9]
    let fromArray = GLKVector3MakeWithArray(&values)
    glkCheck(fromArray.x == 7 && fromArray.y == 8 && fromArray.z == 9, "MakeWithArray")
}

func testGLKVector3Arithmetic() {
    let a = GLKVector3Make(2, 4, 6)
    let b = GLKVector3Make(1, 1, 1)
    glkCheck(glkVec3Near(GLKVector3Negate(a), GLKVector3Make(-2, -4, -6)), "negate")
    glkCheck(glkVec3Near(GLKVector3Add(a, b), GLKVector3Make(3, 5, 7)), "add")
    glkCheck(glkVec3Near(GLKVector3Subtract(a, b), GLKVector3Make(1, 3, 5)), "sub")
    glkCheck(glkVec3Near(GLKVector3Multiply(a, b), GLKVector3Make(2, 4, 6)), "mul")
    glkCheck(glkVec3Near(GLKVector3Divide(a, GLKVector3Make(2, 2, 2)), GLKVector3Make(1, 2, 3)), "div")
    glkCheck(glkVec3Near(GLKVector3AddScalar(a, 1), GLKVector3Make(3, 5, 7)), "addScalar")
    glkCheck(glkVec3Near(GLKVector3SubtractScalar(a, 1), GLKVector3Make(1, 3, 5)), "subScalar")
    glkCheck(glkVec3Near(GLKVector3MultiplyScalar(a, 0.5), GLKVector3Make(1, 2, 3)), "mulScalar")
    glkCheck(glkVec3Near(GLKVector3DivideScalar(a, 2), GLKVector3Make(1, 2, 3)), "divScalar")
    glkCheck(glkVec3Near(GLKVector3Maximum(a, GLKVector3Make(3, 0, 9)), GLKVector3Make(3, 4, 9)), "max")
    glkCheck(glkVec3Near(GLKVector3Minimum(a, GLKVector3Make(3, 0, 9)), GLKVector3Make(2, 0, 6)), "min")
}

func testGLKVector3Comparisons() {
    let a = GLKVector3Make(2, 4, 6)
    glkCheck(GLKVector3AllEqualToVector3(a, GLKVector3Make(2, 4, 6)), "eq vector")
    glkCheck(GLKVector3AllEqualToScalar(GLKVector3Make(3, 3, 3), 3), "eq scalar")
    glkCheck(GLKVector3AllGreaterThanVector3(a, GLKVector3Make(1, 1, 1)), "gt vector")
    glkCheck(GLKVector3AllGreaterThanScalar(a, 1), "gt scalar")
    glkCheck(GLKVector3AllGreaterThanOrEqualToVector3(a, GLKVector3Make(2, 1, 6)), "ge vector")
    glkCheck(GLKVector3AllGreaterThanOrEqualToScalar(a, 2), "ge scalar")
}

func testGLKVector3Geometry() {
    glkCheck(GLKVector3Length(GLKVector3Make(0, 3, 4)) == 5, "length")
    glkCheck(GLKVector3Distance(GLKVector3Make(0, 0, 0), GLKVector3Make(0, 3, 4)) == 5, "distance")
    glkCheck(GLKVector3DotProduct(GLKVector3Make(1, 0, 0), GLKVector3Make(0, 1, 0)) == 0, "dot")
    let crossed = GLKVector3CrossProduct(GLKVector3Make(1, 0, 0), GLKVector3Make(0, 1, 0))
    glkCheck(GLKVector3AllEqualToVector3(crossed, GLKVector3Make(0, 0, 1)), "cross")
    let n = GLKVector3Normalize(GLKVector3Make(0, 3, 4))
    glkCheck(glkNear(GLKVector3Length(n), 1), "normalize")
    let lerp = GLKVector3Lerp(GLKVector3Make(0, 0, 0), GLKVector3Make(4, 0, 0), 0.5)
    glkCheck(glkVec3Near(lerp, GLKVector3Make(2, 0, 0)), "lerp")
    let projected = GLKVector3Project(GLKVector3Make(2, 2, 0), GLKVector3Make(1, 0, 0))
    glkCheck(glkVec3Near(projected, GLKVector3Make(2, 0, 0)), "project")
}
