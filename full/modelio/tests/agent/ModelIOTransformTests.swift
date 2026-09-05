import Foundation
import ModelIO

func testTransformComponentProtocol() {
    let transform: any MDLTransformComponent = MDLTransform()
    transform.matrix = .identity
    transform.resetsTransform = false
    mdlCheck(!transform.resetsTransform, "resets")
    _ = transform.keyTimes
    _ = transform.minimumTime
    _ = transform.maximumTime
    transform.setLocalTransform(.identity)
    transform.setLocalTransform(.identity, forTime: 1)
    let at = transform.localTransform(atTime: 0)
    mdlCheck(at.columns.3.w == 1, "local")
}

func testGlobalTransform() {
    let parent = MDLObject()
    let child = MDLObject()
    let pt = MDLTransform()
    pt.setTranslation(SIMD3(0, 4, 0), forTime: 0)
    parent.transform = pt
    parent.addChild(child)
    let ct = MDLTransform()
    ct.setTranslation(SIMD3(1, 0, 0), forTime: 0)
    child.transform = ct
    let global = MDLTransform.globalTransform(with: child, atTime: 0)
    mdlCheck(mdlNear(global.columns.3.y, 4, eps: 0.01), "parent translation")
}

func testTransformOpProtocol() {
    let stack = MDLTransformStack()
    let op: any MDLTransformOp = stack.addTranslateOp("t", inverse: false)
    mdlCheck(op.name == "t", "name")
    mdlCheck(!op.isInverseOp(), "inverse")
    _ = op.float4x4(atTime: 0)
    _ = op.double4x4(atTime: 0)
}

func testTransformTRS() {
    let identity = MDLTransform(identity: ())
    identity.setIdentity()
    mdlCheck(identity.scale.x == 1, "identity scale")
    let fromMatrix = MDLTransform(matrix: .identity)
    mdlCheck(fromMatrix.matrix.columns.0.x == 1, "matrix init")
    let flagged = MDLTransform(matrix: .identity, resetsTransform: false)
    mdlCheck(!flagged.resetsTransform, "flag")
    let copied = MDLTransform(transformComponent: identity)
    mdlCheck(copied.scale.x == 1, "from component")
    let copied2 = MDLTransform(transformComponent: identity, resetsTransform: true)
    mdlCheck(copied2.resetsTransform, "from component flag")
    let transform = MDLTransform()
    transform.setTranslation(SIMD3(1, 2, 3), forTime: 0)
    transform.setRotation(SIMD3(0, 0.5, 0), forTime: 0)
    transform.setScale(SIMD3(2, 2, 2), forTime: 0)
    transform.setShear(SIMD3(0, 0, 0), forTime: 0)
    transform.setMatrix(.identity, forTime: 1)
    mdlCheck(mdlVec3Near(transform.translation(atTime: 0), SIMD3(1, 2, 3)), "translation at")
    _ = transform.rotation(atTime: 0)
    _ = transform.rotationMatrix(atTime: 0)
    mdlCheck(mdlNear(transform.scale(atTime: 0).x, 2, eps: 0.01) || transform.scale.x == 2, "scale at")
    _ = transform.shear(atTime: 0)
    transform.translation = SIMD3(4, 5, 6)
    transform.rotation = SIMD3()
    transform.scale = SIMD3(1, 1, 1)
    transform.shear = SIMD3()
    mdlCheck(transform.translation.x == 4, "translation prop")
}

func testTransformStack() {
    let stack = MDLTransformStack()
    mdlCheck(stack.count() == 0, "empty")
    let translate = stack.addTranslateOp("T", inverse: false)
    translate.animatedValue.setFloat3(SIMD3(1, 0, 0), atTime: 0)
    let scale = stack.addScaleOp("S", inverse: false)
    scale.animatedValue.setFloat3(SIMD3(2, 2, 2), atTime: 0)
    let rotate = stack.addRotateOp("R", order: .xyz, inverse: false)
    rotate.animatedValue.setFloat3(SIMD3(), atTime: 0)
    let rx = stack.addRotateXOp("X", inverse: false)
    rx.animatedValue.setFloat(0, atTime: 0)
    let ry = stack.addRotateYOp("Y", inverse: false)
    ry.animatedValue.setFloat(0, atTime: 0)
    let rz = stack.addRotateZOp("Z", inverse: false)
    rz.animatedValue.setFloat(0, atTime: 0)
    let orient = stack.addOrientOp("O", inverse: true)
    orient.animatedValue.setFloatQuaternion(.identity, atTime: 0)
    let matrix = stack.addMatrixOp("M", inverse: false)
    matrix.animatedValue.setFloat4x4(.identity, atTime: 0)
    mdlCheck(stack.count() == 8, "ops")
    mdlCheck(stack.transformOps.count == 8, "transformOps")
    mdlCheck(stack.animatedValue(withName: "T") === translate.animatedValue, "lookup")
    let f = stack.float4x4(atTime: 0)
    mdlCheck(f.columns.3.w == 1, "float4x4")
    let d = stack.double4x4(atTime: 0)
    mdlCheck(d.columns.3.w == 1, "double4x4")
    _ = stack.keyTimes
    stack.matrix = .identity
    stack.setLocalTransform(.identity)
    stack.setLocalTransform(.identity, forTime: 0.5)
    mdlCheck(stack.localTransform(atTime: 0).columns.0.x != 0, "local")
    mdlCheck(orient.isInverseOp(), "inverse op")
}
