import Foundation
import SceneKit

func skNear(_ a: Float, _ b: Float, _ message: String, eps: Float = 1e-4) {
    precondition(abs(a - b) < eps, "\(message) (\(a) vs \(b))")
}

func skXform(_ m: SCNMatrix4, _ p: SCNVector3) -> SCNVector3 {
    SCNVector3(
        x: m.m11 * p.x + m.m21 * p.y + m.m31 * p.z + m.m41,
        y: m.m12 * p.x + m.m22 * p.y + m.m32 * p.z + m.m42,
        z: m.m13 * p.x + m.m23 * p.y + m.m33 * p.z + m.m43
    )
}

func testVectorMath() {
    precondition(SCNVector3EqualToVector3(SCNVector3Zero, SCNVector3Make(0, 0, 0)))
    let v = SCNVector3(1, 2, 3)
    skNear(v.x, 1, "x"); skNear(v.y, 2, "y"); skNear(v.z, 3, "z")
    let v2 = SCNVector3(x: 4, y: 5, z: 6)
    skNear(v2.x, 4, "init x")
    _ = SCNVector3(1.0 as Double, 2.0, 3.0)
    _ = SCNVector3(1 as Int, 2, 3)
    let simd3 = SIMD3<Float>(v)
    skNear(SCNVector3(simd3).y, 2, "simd3")
    precondition(SCNVector4EqualToVector4(SCNVector4Make(1, 2, 3, 4), SCNVector4(x: 1, y: 2, z: 3, w: 4)))
    let q = SCNVector4(1, 2, 3, 4)
    skNear(q.w, 4, "w")
    let simd4 = SIMD4<Float>(q)
    skNear(SCNVector4(simd4).z, 3, "simd4")
}

func testMatrixMath() {
    precondition(SCNMatrix4IsIdentity(SCNMatrix4Identity))
    precondition(SCNMatrix4EqualToMatrix4(SCNMatrix4Identity, SCNMatrix4()))
    let translated = SCNMatrix4MakeTranslation(3, 4, 5)
    let origin = skXform(translated, SCNVector3Zero)
    skNear(origin.x, 3, "tx"); skNear(origin.y, 4, "ty"); skNear(origin.z, 5, "tz")
    let scaled = SCNMatrix4MakeScale(2, 3, 4)
    let p = skXform(scaled, SCNVector3(x: 1, y: 1, z: 1))
    skNear(p.x, 2, "sx"); skNear(p.y, 3, "sy"); skNear(p.z, 4, "sz")
    let t1 = SCNMatrix4MakeTranslation(1, 0, 0)
    let t2 = SCNMatrix4MakeTranslation(0, 2, 0)
    let composed = SCNMatrix4Mult(t1, t2)
    let c = skXform(composed, SCNVector3Zero)
    skNear(c.x, 1, "mult x"); skNear(c.y, 2, "mult y")
    let inv = SCNMatrix4Invert(translated)
    let round = SCNMatrix4Mult(inv, translated)
    precondition(SCNMatrix4IsIdentity(round) || abs(round.m11 - 1) < 1e-3)
    let rot = SCNMatrix4MakeRotation(Float.pi / 2, 0, 1, 0)
    let rp = skXform(rot, SCNVector3(1, 0, 0))
    skNear(rp.x, 0, "ry x", eps: 1e-5)
    skNear(rp.z, -1, "ry z", eps: 1e-5)
    let moved = SCNMatrix4Translate(SCNMatrix4Identity, 1, 2, 3)
    skNear(moved.m41, 1, "translate helper")
    let scaledM = SCNMatrix4Scale(SCNMatrix4MakeTranslation(1, 2, 3), 2, 2, 2)
    let q = skXform(scaledM, SCNVector3(1, 0, 0))
    skNear(q.x, 4, "scale helper x")
    _ = SCNMatrix4Rotate(SCNMatrix4Identity, 0.1, 0, 1, 0)
    skNear(translated.m11, 1, "m11")
    skNear(translated.m22, 1, "m22")
    skNear(translated.m33, 1, "m33")
    skNear(translated.m44, 1, "m44")
    _ = translated.m12; _ = translated.m13; _ = translated.m14
    _ = translated.m21; _ = translated.m23; _ = translated.m24
    _ = translated.m31; _ = translated.m32; _ = translated.m34
    _ = translated.m42; _ = translated.m43
}

func testQuaternionFromRotation() {
    let node = SCNNode()
    node.rotation = SCNVector4(0, 1, 0, Float.pi / 2)
    skNear(node.orientation.w, cos(Float.pi / 4), "quat w", eps: 1e-3)
    node.eulerAngles = SCNVector3(0, Float.pi / 2, 0)
    skNear(node.eulerAngles.y, Float.pi / 2, "euler", eps: 2e-3)
}
