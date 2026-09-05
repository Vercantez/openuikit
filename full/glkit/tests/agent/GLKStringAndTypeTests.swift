import Foundation
import GLKit

func testNSStringFromGLKVectors() {
    let v2 = NSStringFromGLKVector2(GLKVector2Make(1, 2))
    glkCheck(v2.contains("1") && v2.contains("2") && v2.contains("{"), "NSStringFromGLKVector2")
    let v3 = NSStringFromGLKVector3(GLKVector3Make(1, 2, 3))
    glkCheck(v3.contains("3") && v3.contains("{"), "NSStringFromGLKVector3")
    let v4 = NSStringFromGLKVector4(GLKVector4Make(1, 2, 3, 4))
    glkCheck(v4.contains("4") && v4.contains("{"), "NSStringFromGLKVector4")
    let q = NSStringFromGLKQuaternion(GLKQuaternionMake(0, 0, 0, 1))
    glkCheck(q.contains("1") && q.contains("{"), "NSStringFromGLKQuaternion")
}

func testNSStringFromGLKMatrices() {
    let m2 = NSStringFromGLKMatrix2(GLKMatrix2(m00: 1, m01: 0, m10: 0, m11: 1))
    glkCheck(m2.contains("1") && m2.contains("{"), "NSStringFromGLKMatrix2")
    let m3 = NSStringFromGLKMatrix3(GLKMatrix3Identity)
    glkCheck(m3.contains("1") && m3.contains("{"), "NSStringFromGLKMatrix3")
    let m4 = NSStringFromGLKMatrix4(GLKMatrix4Identity)
    glkCheck(m4.contains("1") && m4.contains("{"), "NSStringFromGLKMatrix4")
}

func testGLKIdentityConstants() {
    glkCheck(GLKMatrix3Identity.m00 == 1 && GLKMatrix3Identity.m11 == 1 && GLKMatrix3Identity.m22 == 1, "M3")
    glkCheck(GLKMatrix4Identity.m00 == 1 && GLKMatrix4Identity.m33 == 1, "M4")
    glkCheck(GLKQuaternionIdentity.w == 1 && GLKQuaternionIdentity.x == 0, "quat")
}

func testGLKVertexAttributeParameters() {
    let params = GLKVertexAttributeParameters(type: 0x1406, size: 3, normalized: 0)
    glkCheck(params.type == 0x1406, "type")
    glkCheck(params.size == 3, "size")
    glkCheck(params.normalized == 0, "normalized")
}

func testGLKEffectPropertyPrvPtr() {
    var value: Int32 = 7
    withUnsafeMutablePointer(to: &value) { pointer in
        let opaque = OpaquePointer(pointer)
        let alias: GLKEffectPropertyPrvPtr = opaque
        glkCheck(Int(bitPattern: UnsafeRawPointer(alias)) != 0, "GLKEffectPropertyPrvPtr")
    }
}

func testGLKModelErrorConstants() {
    glkCheck(kGLKModelErrorDomain == "kGLKModelErrorDomain", "domain")
    glkCheck(kGLKModelErrorKey == "kGLKModelErrorKey", "key")
}
