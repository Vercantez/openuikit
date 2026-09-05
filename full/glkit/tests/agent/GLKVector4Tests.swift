import Foundation
import GLKit

func testGLKVector4Make() {
    let made = GLKVector4Make(1, 2, 3, 4)
    glkCheck(made.x == 1 && made.y == 2 && made.z == 3 && made.w == 4, "GLKVector4Make")
    glkCheck(made.r == 1 && made.g == 2 && made.b == 3 && made.a == 4, "rgba aliases")
    var values: [Float] = [5, 6, 7, 8]
    let fromArray = GLKVector4MakeWithArray(&values)
    glkCheck(fromArray.w == 8, "MakeWithArray")
    let from3 = GLKVector4MakeWithVector3(GLKVector3Make(1, 2, 3), 9)
    glkCheck(from3.x == 1 && from3.w == 9, "MakeWithVector3")
}

func testGLKVector4Arithmetic() {
    let a = GLKVector4Make(2, 4, 6, 8)
    let b = GLKVector4Make(1, 1, 1, 1)
    glkCheck(glkVec4Near(GLKVector4Negate(a), GLKVector4Make(-2, -4, -6, -8)), "negate")
    glkCheck(glkVec4Near(GLKVector4Add(a, b), GLKVector4Make(3, 5, 7, 9)), "add")
    glkCheck(glkVec4Near(GLKVector4Subtract(a, b), GLKVector4Make(1, 3, 5, 7)), "sub")
    glkCheck(glkVec4Near(GLKVector4Multiply(a, b), GLKVector4Make(2, 4, 6, 8)), "mul")
    glkCheck(glkVec4Near(GLKVector4Divide(a, GLKVector4Make(2, 2, 2, 2)), GLKVector4Make(1, 2, 3, 4)), "div")
    glkCheck(glkVec4Near(GLKVector4AddScalar(a, 1), GLKVector4Make(3, 5, 7, 9)), "addScalar")
    glkCheck(glkVec4Near(GLKVector4SubtractScalar(a, 1), GLKVector4Make(1, 3, 5, 7)), "subScalar")
    glkCheck(glkVec4Near(GLKVector4MultiplyScalar(a, 0.5), GLKVector4Make(1, 2, 3, 4)), "mulScalar")
    glkCheck(glkVec4Near(GLKVector4DivideScalar(a, 2), GLKVector4Make(1, 2, 3, 4)), "divScalar")
    glkCheck(glkVec4Near(GLKVector4Maximum(a, GLKVector4Make(3, 0, 9, 1)), GLKVector4Make(3, 4, 9, 8)), "max")
    glkCheck(glkVec4Near(GLKVector4Minimum(a, GLKVector4Make(3, 0, 9, 1)), GLKVector4Make(2, 0, 6, 1)), "min")
}

func testGLKVector4Comparisons() {
    glkCheck(GLKVector4AllEqualToScalar(GLKVector4Make(2, 2, 2, 2), 2), "eq scalar")
    glkCheck(GLKVector4AllEqualToVector4(GLKVector4Make(1, 2, 3, 4), GLKVector4Make(1, 2, 3, 4)), "eq vector")
    glkCheck(GLKVector4AllGreaterThanVector4(GLKVector4Make(2, 3, 4, 5), GLKVector4Make(1, 1, 1, 1)), "gt vector")
    glkCheck(GLKVector4AllGreaterThanScalar(GLKVector4Make(2, 3, 4, 5), 1), "gt scalar")
    glkCheck(GLKVector4AllGreaterThanOrEqualToVector4(GLKVector4Make(2, 3, 4, 5), GLKVector4Make(2, 1, 4, 0)), "ge vector")
    glkCheck(GLKVector4AllGreaterThanOrEqualToScalar(GLKVector4Make(2, 3, 4, 5), 2), "ge scalar")
}

func testGLKVector4Geometry() {
    glkCheck(glkNear(GLKVector4Length(GLKVector4Make(0, 0, 0, 1)), 1), "length")
    glkCheck(GLKVector4Distance(GLKVector4Make(0, 0, 0, 0), GLKVector4Make(0, 3, 4, 0)) == 5, "distance")
    glkCheck(GLKVector4DotProduct(GLKVector4Make(1, 0, 0, 0), GLKVector4Make(0, 1, 0, 0)) == 0, "dot")
    let crossed = GLKVector4CrossProduct(GLKVector4Make(1, 0, 0, 0), GLKVector4Make(0, 1, 0, 0))
    glkCheck(glkVec4Near(crossed, GLKVector4Make(0, 0, 1, 0)), "cross w=0")
    let n = GLKVector4Normalize(GLKVector4Make(0, 3, 4, 0))
    glkCheck(glkNear(GLKVector4Length(n), 1), "normalize")
    let lerp = GLKVector4Lerp(GLKVector4Make(0, 0, 0, 0), GLKVector4Make(4, 0, 0, 0), 0.25)
    glkCheck(glkVec4Near(lerp, GLKVector4Make(1, 0, 0, 0)), "lerp")
    let projected = GLKVector4Project(GLKVector4Make(2, 2, 0, 0), GLKVector4Make(1, 0, 0, 0))
    glkCheck(glkVec4Near(projected, GLKVector4Make(2, 0, 0, 0)), "project")
}
