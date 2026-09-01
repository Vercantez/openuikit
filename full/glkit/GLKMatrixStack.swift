import CoreFoundation
import Foundation

private let glkMatrixStackTypeID: CFTypeID = 0x474C4B53

open class GLKMatrixStack: NSObject {
    fileprivate var matrices: [GLKMatrix4] = [GLKMatrix4Identity]

    public override init() {
        super.init()
    }

    public override var hash: Int {
        ObjectIdentifier(self).hashValue
    }
}

public func GLKMatrixStackGetTypeID() -> CFTypeID {
    glkMatrixStackTypeID
}

public func GLKMatrixStackCreate(_ alloc: CFAllocator?) -> Unmanaged<GLKMatrixStack>? {
    _ = alloc
    return Unmanaged.passRetained(GLKMatrixStack())
}

public func GLKMatrixStackPush(_ stack: GLKMatrixStack) {
    guard let top = stack.matrices.last else { return }
    stack.matrices.append(top)
}

public func GLKMatrixStackPop(_ stack: GLKMatrixStack) {
    if stack.matrices.count > 1 {
        stack.matrices.removeLast()
    }
}

public func GLKMatrixStackSize(_ stack: GLKMatrixStack) -> Int32 {
    Int32(stack.matrices.count)
}

public func GLKMatrixStackLoadMatrix4(_ stack: GLKMatrixStack, _ matrix: GLKMatrix4) {
    if stack.matrices.isEmpty {
        stack.matrices.append(matrix)
    } else {
        stack.matrices[stack.matrices.count - 1] = matrix
    }
}

public func GLKMatrixStackGetMatrix4(_ stack: GLKMatrixStack) -> GLKMatrix4 {
    stack.matrices.last ?? GLKMatrix4Identity
}

public func GLKMatrixStackGetMatrix3(_ stack: GLKMatrixStack) -> GLKMatrix3 {
    GLKMatrix4GetMatrix3(GLKMatrixStackGetMatrix4(stack))
}

public func GLKMatrixStackGetMatrix2(_ stack: GLKMatrixStack) -> GLKMatrix2 {
    GLKMatrix4GetMatrix2(GLKMatrixStackGetMatrix4(stack))
}

public func GLKMatrixStackGetMatrix4Inverse(_ stack: GLKMatrixStack) -> GLKMatrix4 {
    var invertible = false
    return GLKMatrix4Invert(GLKMatrixStackGetMatrix4(stack), &invertible)
}

public func GLKMatrixStackGetMatrix4InverseTranspose(_ stack: GLKMatrixStack) -> GLKMatrix4 {
    var invertible = false
    return GLKMatrix4InvertAndTranspose(GLKMatrixStackGetMatrix4(stack), &invertible)
}

public func GLKMatrixStackGetMatrix3Inverse(_ stack: GLKMatrixStack) -> GLKMatrix3 {
    var invertible = false
    return GLKMatrix3Invert(GLKMatrixStackGetMatrix3(stack), &invertible)
}

public func GLKMatrixStackGetMatrix3InverseTranspose(_ stack: GLKMatrixStack) -> GLKMatrix3 {
    var invertible = false
    return GLKMatrix3InvertAndTranspose(GLKMatrixStackGetMatrix3(stack), &invertible)
}

public func GLKMatrixStackMultiplyMatrix4(_ stack: GLKMatrixStack, _ matrix: GLKMatrix4) {
    GLKMatrixStackLoadMatrix4(stack, GLKMatrix4Multiply(GLKMatrixStackGetMatrix4(stack), matrix))
}

public func GLKMatrixStackMultiplyMatrixStack(_ stackLeft: GLKMatrixStack, _ stackRight: GLKMatrixStack) {
    GLKMatrixStackMultiplyMatrix4(stackLeft, GLKMatrixStackGetMatrix4(stackRight))
}

public func GLKMatrixStackRotate(_ stack: GLKMatrixStack, _ radians: Float, _ x: Float, _ y: Float, _ z: Float) {
    GLKMatrixStackLoadMatrix4(stack, GLKMatrix4Rotate(GLKMatrixStackGetMatrix4(stack), radians, x, y, z))
}

public func GLKMatrixStackRotateWithVector3(_ stack: GLKMatrixStack, _ radians: Float, _ axisVector: GLKVector3) {
    GLKMatrixStackRotate(stack, radians, axisVector.x, axisVector.y, axisVector.z)
}

public func GLKMatrixStackRotateWithVector4(_ stack: GLKMatrixStack, _ radians: Float, _ axisVector: GLKVector4) {
    GLKMatrixStackRotate(stack, radians, axisVector.x, axisVector.y, axisVector.z)
}

public func GLKMatrixStackRotateX(_ stack: GLKMatrixStack, _ radians: Float) {
    GLKMatrixStackLoadMatrix4(stack, GLKMatrix4RotateX(GLKMatrixStackGetMatrix4(stack), radians))
}

public func GLKMatrixStackRotateY(_ stack: GLKMatrixStack, _ radians: Float) {
    GLKMatrixStackLoadMatrix4(stack, GLKMatrix4RotateY(GLKMatrixStackGetMatrix4(stack), radians))
}

public func GLKMatrixStackRotateZ(_ stack: GLKMatrixStack, _ radians: Float) {
    GLKMatrixStackLoadMatrix4(stack, GLKMatrix4RotateZ(GLKMatrixStackGetMatrix4(stack), radians))
}

public func GLKMatrixStackScale(_ stack: GLKMatrixStack, _ sx: Float, _ sy: Float, _ sz: Float) {
    GLKMatrixStackLoadMatrix4(stack, GLKMatrix4Scale(GLKMatrixStackGetMatrix4(stack), sx, sy, sz))
}

public func GLKMatrixStackScaleWithVector3(_ stack: GLKMatrixStack, _ scaleVector: GLKVector3) {
    GLKMatrixStackScale(stack, scaleVector.x, scaleVector.y, scaleVector.z)
}

public func GLKMatrixStackScaleWithVector4(_ stack: GLKMatrixStack, _ scaleVector: GLKVector4) {
    GLKMatrixStackScale(stack, scaleVector.x, scaleVector.y, scaleVector.z)
}

public func GLKMatrixStackTranslate(_ stack: GLKMatrixStack, _ tx: Float, _ ty: Float, _ tz: Float) {
    GLKMatrixStackLoadMatrix4(stack, GLKMatrix4Translate(GLKMatrixStackGetMatrix4(stack), tx, ty, tz))
}

public func GLKMatrixStackTranslateWithVector3(_ stack: GLKMatrixStack, _ translationVector: GLKVector3) {
    GLKMatrixStackTranslate(stack, translationVector.x, translationVector.y, translationVector.z)
}

public func GLKMatrixStackTranslateWithVector4(_ stack: GLKMatrixStack, _ translationVector: GLKVector4) {
    GLKMatrixStackTranslate(stack, translationVector.x, translationVector.y, translationVector.z)
}
