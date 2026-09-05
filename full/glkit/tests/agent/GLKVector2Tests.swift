import Foundation
import GLKit

func testGLKVector2Make() {
    let made = GLKVector2Make(3, 4)
    glkCheck(made.x == 3 && made.y == 4, "GLKVector2Make")
    glkCheck(made.s == 3 && made.t == 4, "GLKVector2 st aliases")
    var values: [Float] = [5, 6]
    let fromArray = GLKVector2MakeWithArray(&values)
    glkCheck(fromArray.x == 5 && fromArray.y == 6, "GLKVector2MakeWithArray")
    let typed: GLKVector2 = made
    glkCheck(typed.x == 3, "GLKVector2 typealias")
}

func testGLKVector2Arithmetic() {
    let a = GLKVector2Make(3, 4)
    let b = GLKVector2Make(1, 2)
    glkCheck(glkVec2Near(GLKVector2Negate(a), GLKVector2Make(-3, -4)), "negate")
    glkCheck(glkVec2Near(GLKVector2Add(a, b), GLKVector2Make(4, 6)), "add")
    glkCheck(glkVec2Near(GLKVector2Subtract(a, b), GLKVector2Make(2, 2)), "subtract")
    glkCheck(glkVec2Near(GLKVector2Multiply(a, b), GLKVector2Make(3, 8)), "multiply")
    glkCheck(glkVec2Near(GLKVector2Divide(a, b), GLKVector2Make(3, 2)), "divide")
    glkCheck(glkVec2Near(GLKVector2AddScalar(a, 1), GLKVector2Make(4, 5)), "addScalar")
    glkCheck(glkVec2Near(GLKVector2SubtractScalar(a, 1), GLKVector2Make(2, 3)), "subScalar")
    glkCheck(glkVec2Near(GLKVector2MultiplyScalar(a, 2), GLKVector2Make(6, 8)), "mulScalar")
    glkCheck(glkVec2Near(GLKVector2DivideScalar(a, 2), GLKVector2Make(1.5, 2)), "divScalar")
    glkCheck(glkVec2Near(GLKVector2Maximum(a, b), GLKVector2Make(3, 4)), "max")
    glkCheck(glkVec2Near(GLKVector2Minimum(a, b), GLKVector2Make(1, 2)), "min")
}

func testGLKVector2Comparisons() {
    let a = GLKVector2Make(3, 4)
    glkCheck(GLKVector2AllEqualToVector2(a, GLKVector2Make(3, 4)), "eq vector")
    glkCheck(!GLKVector2AllEqualToVector2(a, GLKVector2Make(3, 5)), "neq vector")
    glkCheck(GLKVector2AllEqualToScalar(GLKVector2Make(2, 2), 2), "eq scalar")
    glkCheck(GLKVector2AllGreaterThanVector2(a, GLKVector2Make(1, 1)), "gt vector")
    glkCheck(GLKVector2AllGreaterThanScalar(a, 1), "gt scalar")
    glkCheck(GLKVector2AllGreaterThanOrEqualToVector2(a, GLKVector2Make(3, 1)), "ge vector")
    glkCheck(GLKVector2AllGreaterThanOrEqualToScalar(a, 3), "ge scalar")
}

func testGLKVector2Geometry() {
    let a = GLKVector2Make(3, 4)
    glkCheck(GLKVector2Length(a) == 5, "length")
    glkCheck(GLKVector2Distance(GLKVector2Make(0, 0), a) == 5, "distance")
    glkCheck(GLKVector2DotProduct(GLKVector2Make(1, 0), GLKVector2Make(0, 1)) == 0, "dot")
    let n = GLKVector2Normalize(a)
    glkCheck(glkNear(GLKVector2Length(n), 1), "normalize length")
    let lerp = GLKVector2Lerp(GLKVector2Make(0, 0), GLKVector2Make(4, 0), 0.25)
    glkCheck(glkVec2Near(lerp, GLKVector2Make(1, 0)), "lerp")
    let projected = GLKVector2Project(GLKVector2Make(2, 2), GLKVector2Make(1, 0))
    glkCheck(glkVec2Near(projected, GLKVector2Make(2, 0)), "project")
}
