import Foundation
import GLKit

func runGLKitRuntime() async {

        precondition(GLKVector2Length(GLKVector2Make(3, 4)) == 5)
        precondition(GLKVector2DotProduct(GLKVector2Make(1, 0), GLKVector2Make(0, 1)) == 0)
        precondition(GLKVector3Length(GLKVector3Make(0, 3, 4)) == 5)
        let crossed = GLKVector3CrossProduct(GLKVector3Make(1, 0, 0), GLKVector3Make(0, 1, 0))
        precondition(GLKVector3AllEqualToVector3(crossed, GLKVector3Make(0, 0, 1)))
        precondition(GLKVector4AllEqualToScalar(GLKVector4Make(2, 2, 2, 2), 2))

        let identity4 = GLKMatrix4Identity
        var invertible = false
        let inverted = GLKMatrix4Invert(identity4, &invertible)
        precondition(invertible)
        precondition(GLKMatrix4GetColumn(inverted, 0).x == 1)
        precondition(GLKMatrix4GetColumn(inverted, 3).w == 1)

        let translated = GLKMatrix4MultiplyVector3WithTranslation(
            GLKMatrix4MakeTranslation(1, 2, 3),
            GLKVector3Make(4, 5, 6)
        )
        precondition(translated.x == 5 && translated.y == 7 && translated.z == 9)

        let rotated = GLKMatrix4MultiplyVector3(
            GLKMatrix4MakeZRotation(GLKMathDegreesToRadians(90)),
            GLKVector3Make(1, 0, 0)
        )
        precondition(abs(rotated.x) < 0.0001)
        precondition(abs(rotated.y - 1) < 0.0001)

        let look = GLKMatrix4MakeLookAt(0, 0, 1, 0, 0, 0, 0, 1, 0)
        let projected = GLKMatrix4MultiplyAndProjectVector3(look, GLKVector3Make(0, 0, 0))
        precondition(abs(projected.z + 1) < 0.0001)

        var invert3 = false
        let identity3 = GLKMatrix3Invert(GLKMatrix3Identity, &invert3)
        precondition(invert3)
        precondition(identity3.m00 == 1 && identity3.m11 == 1 && identity3.m22 == 1)

        let q = GLKQuaternionMakeWithAngleAndAxis(GLKMathDegreesToRadians(180), 0, 0, 1)
        let qRotated = GLKQuaternionRotateVector3(q, GLKVector3Make(1, 0, 0))
        precondition(abs(qRotated.x + 1) < 0.0001)
        precondition(abs(qRotated.y) < 0.0001)

        let stack = GLKMatrixStack()
        precondition(GLKMatrixStackSize(stack) == 1)
        GLKMatrixStackTranslate(stack, 2, 0, 0)
        GLKMatrixStackPush(stack)
        precondition(GLKMatrixStackSize(stack) == 2)
        GLKMatrixStackScale(stack, 3, 1, 1)
        let stacked = GLKMatrix4MultiplyVector3WithTranslation(
            GLKMatrixStackGetMatrix4(stack),
            GLKVector3Make(1, 0, 0)
        )
        precondition(stacked.x == 5)
        GLKMatrixStackPop(stack)
        precondition(GLKMatrixStackSize(stack) == 1)

        precondition(GLKFogMode.linear != .exp)
        precondition(GLKVertexAttrib.position.rawValue == 0)
        precondition(GLKTextureTarget.target2D.rawValue == GL_TEXTURE_2D)
        precondition(GLKTextureLoaderError.invalidEAGLContext.rawValue == 17)
        precondition(GLKTextureLoaderError.errorDomain == GLKTextureLoaderErrorDomain)

        let effect = GLKBaseEffect()
        precondition(effect.useConstantColor == GL_TRUE)
        effect.constantColor = GLKVector4Make(0.1, 0.2, 0.3, 1)
        precondition(effect.constantColor.y == 0.2)
        effect.light0.enabled = GL_TRUE
        effect.light0.position = GLKVector4Make(1, 2, 3, 1)
        precondition(effect.light0.enabled == GL_TRUE)
        effect.transform.modelviewMatrix = GLKMatrix4MakeTranslation(0, 1, 0)
        precondition(effect.transform.modelviewMatrix.m31 == 1)
        effect.prepareToDraw()

        let skybox = GLKSkyboxEffect()
        skybox.xSize = 4
        skybox.prepareToDraw()
        skybox.draw()
        precondition(skybox.textureCubeMap.target == .targetCubeMap)

        let reflection = GLKReflectionMapEffect()
        reflection.matrix = GLKMatrix3Identity
        reflection.prepareToDraw()

        do {
            _ = try GLKTextureLoader.texture(withContentsOfFile: "/tmp/missing.png")
            fatalError("texture loading must fail closed")
        } catch let error as GLKTextureLoaderError {
            precondition(error.code == .invalidEAGLContext)
            precondition(error.errorCode == 17)
        } catch {
            fatalError("expected GLKTextureLoaderError")
        }

        let loader = GLKTextureLoader(sharegroup: EAGLSharegroup())
        do {
            _ = try await loader.texture(withContentsOf: Data(), queue: nil)
            fatalError("async texture loading must fail closed")
        } catch let error as GLKTextureLoaderError {
            precondition(error.code == .invalidEAGLContext)
        } catch {
            fatalError("expected GLKTextureLoaderError")
        }

        do {
            _ = try GLKMesh(mesh: MDLMesh())
            fatalError("GLKMesh must fail closed")
        } catch let error as GLKModelError {
            precondition(error.code == .gpuUnavailable)
        } catch {
            fatalError("expected GLKModelError")
        }

        let float3 = GLKVertexAttributeParametersFromModelIO(.float3)
        precondition(float3.type == GL_FLOAT)
        precondition(float3.size == 3)
        precondition(float3.normalized == GL_FALSE)
        let uchar4n = GLKVertexAttributeParametersFromModelIO(.uChar4Normalized)
        precondition(uchar4n.type == GL_UNSIGNED_BYTE)
        precondition(uchar4n.size == 4)
        precondition(uchar4n.normalized == GL_TRUE)

        let formatted = NSStringFromGLKVector3(GLKVector3Make(1, 2, 3))
        precondition(formatted.contains("1"))
        precondition(formatted.contains("2"))
        precondition(formatted.contains("3"))

        await MainActor.run {
            let view = GLKView(frame: CGRect(x: 0, y: 0, width: 320, height: 240), context: EAGLContext())
            view.drawableColorFormat = .RGBA8888
            view.bindDrawable()
            view.display()
            view.deleteDrawable()
            precondition(view.snapshot.size == .zero)
            let controller = GLKViewController()
            controller.preferredFramesPerSecond = 60
            controller.isPaused = false
            precondition(controller.isPaused == false)
            controller.isPaused = true
        }

        print("GLKIT_AGENT_RUNTIME_OK")
}

await runGLKitRuntime()

