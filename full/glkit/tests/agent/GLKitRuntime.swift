import Dispatch
import Foundation
@_spi(OpenUIKitHost) import GLKit

func require(_ condition: Bool, _ message: String) {
    if !condition {
        fatalError(message)
    }
}

func testVectorMath() {
    require(GLKVector2Length(GLKVector2Make(3, 4)) == 5, "GLKVector2Length")
    require(GLKVector2DotProduct(GLKVector2Make(1, 0), GLKVector2Make(0, 1)) == 0, "GLKVector2DotProduct")
    require(GLKVector3Length(GLKVector3Make(0, 3, 4)) == 5, "GLKVector3Length")
    let crossed = GLKVector3CrossProduct(GLKVector3Make(1, 0, 0), GLKVector3Make(0, 1, 0))
    require(GLKVector3AllEqualToVector3(crossed, GLKVector3Make(0, 0, 1)), "GLKVector3CrossProduct")
    require(GLKVector4AllEqualToScalar(GLKVector4Make(2, 2, 2, 2), 2), "GLKVector4AllEqualToScalar")
}

func testMatrixMath() {
    let identity4 = GLKMatrix4Identity
    var invertible = false
    let inverted = GLKMatrix4Invert(identity4, &invertible)
    require(invertible, "GLKMatrix4Invert identity is invertible")
    require(GLKMatrix4GetColumn(inverted, 0).x == 1, "GLKMatrix4Invert col0")
    require(GLKMatrix4GetColumn(inverted, 3).w == 1, "GLKMatrix4Invert col3")

    let translated = GLKMatrix4MultiplyVector3WithTranslation(
        GLKMatrix4MakeTranslation(1, 2, 3),
        GLKVector3Make(4, 5, 6)
    )
    require(translated.x == 5 && translated.y == 7 && translated.z == 9, "GLKMatrix4MakeTranslation")

    let rotated = GLKMatrix4MultiplyVector3(
        GLKMatrix4MakeZRotation(GLKMathDegreesToRadians(90)),
        GLKVector3Make(1, 0, 0)
    )
    require(abs(rotated.x) < 0.0001, "GLKMatrix4MakeZRotation x")
    require(abs(rotated.y - 1) < 0.0001, "GLKMatrix4MakeZRotation y")

    let look = GLKMatrix4MakeLookAt(0, 0, 1, 0, 0, 0, 0, 1, 0)
    let projected = GLKMatrix4MultiplyAndProjectVector3(look, GLKVector3Make(0, 0, 0))
    require(abs(projected.z + 1) < 0.0001, "GLKMatrix4MakeLookAt")

    var invert3 = false
    let identity3 = GLKMatrix3Invert(GLKMatrix3Identity, &invert3)
    require(invert3, "GLKMatrix3Invert identity")
    require(identity3.m00 == 1 && identity3.m11 == 1 && identity3.m22 == 1, "GLKMatrix3Identity")
}

func testQuaternionAndStack() {
    let q = GLKQuaternionMakeWithAngleAndAxis(GLKMathDegreesToRadians(180), 0, 0, 1)
    let qRotated = GLKQuaternionRotateVector3(q, GLKVector3Make(1, 0, 0))
    require(abs(qRotated.x + 1) < 0.0001, "GLKQuaternionRotateVector3 x")
    require(abs(qRotated.y) < 0.0001, "GLKQuaternionRotateVector3 y")
    require(GLKQuaternionIdentity.w == 1, "GLKQuaternionIdentity")

    let stack = GLKMatrixStack()
    require(GLKMatrixStackSize(stack) == 1, "GLKMatrixStackSize initial")
    GLKMatrixStackTranslate(stack, 2, 0, 0)
    GLKMatrixStackPush(stack)
    require(GLKMatrixStackSize(stack) == 2, "GLKMatrixStackPush")
    GLKMatrixStackScale(stack, 3, 1, 1)
    let stacked = GLKMatrix4MultiplyVector3WithTranslation(
        GLKMatrixStackGetMatrix4(stack),
        GLKVector3Make(1, 0, 0)
    )
    require(stacked.x == 5, "GLKMatrixStackTranslate/Scale")
    GLKMatrixStackPop(stack)
    require(GLKMatrixStackSize(stack) == 1, "GLKMatrixStackPop")
}

func testEnumsAndErrorCodes() {
    require(GLKFogMode.linear != .exp, "GLKFogMode !=")
    require(GLKVertexAttrib.position.rawValue == 0, "GLKVertexAttrib.position")
    require(GLKTextureTarget.target2D.rawValue == 0x0DE1, "GLKTextureTarget.target2D")
    require(GLKTextureTarget.targetCubeMap.rawValue == 0x8513, "GLKTextureTarget.targetCubeMap")
    require(GLKTextureLoaderError.invalidEAGLContext.rawValue == 17, "invalidEAGLContext code")
    require(GLKTextureLoaderError.fileOrURLNotFound.rawValue == 0, "fileOrURLNotFound code")
    require(GLKTextureLoaderError.unsupportedTextureTarget.rawValue == 19, "unsupportedTextureTarget code")
    require(GLKViewDrawableColorFormat.RGBA8888.rawValue == 0, "RGBA8888")
    require(GLKLightingType.perVertex.rawValue == 0, "GLKLightingType")

    var hasher = Hasher()
    GLKFogMode.linear.hash(into: &hasher)
    _ = GLKFogMode.linear.hashValue
    require(GLKFogMode(rawValue: 2) == .linear, "GLKFogMode rawValue")
}

func testEffectStorageRoundTrip() {
    let effect = GLKBaseEffect()
    effect.useConstantColor = 1
    effect.constantColor = GLKVector4Make(0.1, 0.2, 0.3, 1)
    require(effect.useConstantColor == 1, "useConstantColor storage")
    require(effect.constantColor.y == 0.2, "constantColor storage")
    effect.light0.enabled = 1
    effect.light0.position = GLKVector4Make(1, 2, 3, 1)
    require(effect.light0.enabled == 1, "light0.enabled storage")
    require(effect.light0.position.z == 3, "light0.position storage")
    effect.transform.modelviewMatrix = GLKMatrix4MakeTranslation(0, 1, 0)
    require(effect.transform.modelviewMatrix.m31 == 1, "modelviewMatrix storage")
    let normal = effect.transform.normalMatrix
    require(normal.m00 == 1 && normal.m11 == 1 && normal.m22 == 1, "normalMatrix from translation")
    effect.prepareToDraw()

    effect.lightingType = .perPixel
    require(effect.lightingType == .perPixel, "lightingType storage")
    effect.material.shininess = 32
    require(effect.material.shininess == 32, "material.shininess storage")
    effect.fog.enabled = 1
    effect.fog.density = 0.25
    require(effect.fog.enabled == 1 && effect.fog.density == 0.25, "fog storage")
    effect.texture2d0.enabled = 1
    effect.texture2d0.target = .target2D
    require(effect.texture2d0.enabled == 1, "texture2d0.enabled storage")
    effect.light1.diffuseColor = GLKVector4Make(0.5, 0.25, 0.125, 1)
    require(effect.light1.diffuseColor.x == 0.5, "light1.diffuseColor storage")

    let skybox = GLKSkyboxEffect()
    skybox.xSize = 4
    skybox.ySize = 5
    skybox.zSize = 6
    skybox.center = GLKVector3Make(1, 2, 3)
    require(skybox.xSize == 4 && skybox.ySize == 5 && skybox.zSize == 6, "skybox size storage")
    require(skybox.center.y == 2, "skybox.center storage")
    skybox.prepareToDraw()
    skybox.draw()

    let reflection = GLKReflectionMapEffect()
    reflection.matrix = GLKMatrix3Identity
    reflection.prepareToDraw()
    require(reflection.matrix.m00 == 1, "reflection.matrix storage")
}

func testTextureLoaderFailClosedAndCallbacks() {
    do {
        _ = try GLKTextureLoader.texture(withContentsOfFile: "/tmp/missing.png")
        fatalError("texture loading must fail closed")
    } catch let error as GLKTextureLoaderError {
        require(error.code == .invalidEAGLContext, "sync texture fail-closed code")
        require(error.errorCode == 17, "sync texture errorCode")
    } catch {
        fatalError("expected GLKTextureLoaderError")
    }

    do {
        _ = try GLKTextureLoader.texture(withContentsOf: Data())
        fatalError("data texture loading must fail closed")
    } catch let error as GLKTextureLoaderError {
        require(error.code == .invalidEAGLContext, "data texture fail-closed")
    } catch {
        fatalError("expected GLKTextureLoaderError")
    }

    let loader = GLKTextureLoader()
    var callbackInvocations = 0
    var callerReturned = false
    let lock = NSLock()
    let gate = DispatchSemaphore(value: 0)
    let queue = DispatchQueue(label: "glkit.host.texture")
    loader.texture(withContentsOf: Data([0, 1, 2, 3]), options: nil, queue: queue) { texture, error in
        dispatchPrecondition(condition: .onQueue(queue))
        lock.lock()
        let sawReturn = callerReturned
        callbackInvocations += 1
        lock.unlock()
        require(sawReturn, "texture callback must not run inline on the caller")
        require(texture == nil, "fail-closed callback must not vend a texture")
        require(error != nil, "fail-closed callback must pass an error")
        gate.signal()
    }
    lock.lock()
    callerReturned = true
    let invocationsAtReturn = callbackInvocations
    lock.unlock()
    require(invocationsAtReturn == 0, "completion must not fire before texture(withContentsOf:queue:) returns")
    gate.wait()
    require(callbackInvocations == 1, "completion must run exactly once")
}

testVectorMath()
testMatrixMath()
testQuaternionAndStack()
testEnumsAndErrorCodes()
testEffectStorageRoundTrip()
testTextureLoaderFailClosedAndCallbacks()
print("GLKIT_AGENT_RUNTIME_OK")
