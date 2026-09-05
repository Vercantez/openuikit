import Dispatch
import Foundation
@_spi(OpenUIKitHost) import GLKit

func testGLKTextureLoaderSyncFailClosed() {
    do {
        _ = try GLKTextureLoader.texture(withContentsOfFile: "/tmp/missing.png")
        preconditionFailure("file texture must fail closed")
    } catch let error as GLKTextureLoaderError {
        glkCheck(error.code == .invalidEAGLContext, "file fail-closed")
        glkCheck(error.errorCode == 17, "file errorCode")
    } catch {
        preconditionFailure("expected GLKTextureLoaderError")
    }
    do {
        _ = try GLKTextureLoader.texture(withContentsOf: Data())
        preconditionFailure("data texture must fail closed")
    } catch let error as GLKTextureLoaderError {
        glkCheck(error.code == .invalidEAGLContext, "data fail-closed")
    } catch {
        preconditionFailure("expected GLKTextureLoaderError")
    }
    do {
        _ = try GLKTextureLoader.texture(withContentsOf: URL(fileURLWithPath: "/tmp/missing.png"))
        preconditionFailure("url texture must fail closed")
    } catch let error as GLKTextureLoaderError {
        glkCheck(error.code == .invalidEAGLContext, "url fail-closed")
    } catch {
        preconditionFailure("expected GLKTextureLoaderError")
    }
    do {
        _ = try GLKTextureLoader.texture(withName: "missing", scaleFactor: 1, bundle: nil)
        preconditionFailure("named texture must fail closed")
    } catch let error as GLKTextureLoaderError {
        glkCheck(error.code == .invalidEAGLContext, "name fail-closed")
    } catch {
        preconditionFailure("expected GLKTextureLoaderError")
    }
}

func testGLKTextureLoaderCubeMapFailClosed() {
    do {
        _ = try GLKTextureLoader.cubeMap(withContentsOfFile: "/tmp/missing.png")
        preconditionFailure("cube file must fail closed")
    } catch let error as GLKTextureLoaderError {
        glkCheck(error.code == .invalidEAGLContext, "cube file")
    } catch {
        preconditionFailure("expected GLKTextureLoaderError")
    }
    do {
        _ = try GLKTextureLoader.cubeMap(withContentsOfFiles: ["a", "b"])
        preconditionFailure("cube files must fail closed")
    } catch let error as GLKTextureLoaderError {
        glkCheck(error.code == .invalidEAGLContext, "cube files")
    } catch {
        preconditionFailure("expected GLKTextureLoaderError")
    }
    do {
        _ = try GLKTextureLoader.cubeMap(withContentsOf: URL(fileURLWithPath: "/tmp/missing.png"))
        preconditionFailure("cube url must fail closed")
    } catch let error as GLKTextureLoaderError {
        glkCheck(error.code == .invalidEAGLContext, "cube url")
    } catch {
        preconditionFailure("expected GLKTextureLoaderError")
    }
}

func testGLKTextureLoaderAsyncFailClosed() {
    let loader = GLKTextureLoader()
    let queue = DispatchQueue(label: "glkit.texture.async")
    func waitOnce(_ body: (@escaping GLKTextureLoaderCallback) -> Void) {
        var invocations = 0
        var callerReturned = false
        let lock = NSLock()
        let gate = DispatchSemaphore(value: 0)
        body { texture, error in
            dispatchPrecondition(condition: .onQueue(queue))
            lock.lock()
            let sawReturn = callerReturned
            invocations += 1
            lock.unlock()
            glkCheck(sawReturn, "callback must not run inline")
            glkCheck(texture == nil, "no texture")
            glkCheck(error != nil, "error required")
            gate.signal()
        }
        lock.lock()
        callerReturned = true
        let atReturn = invocations
        lock.unlock()
        glkCheck(atReturn == 0, "must not fire before return")
        gate.wait()
        glkCheck(invocations == 1, "exactly once")
    }
    waitOnce { handler in
        loader.texture(withContentsOf: Data([0, 1, 2, 3]), options: nil, queue: queue, completionHandler: handler)
    }
    waitOnce { handler in
        loader.texture(withContentsOfFile: "/tmp/missing.png", options: nil, queue: queue, completionHandler: handler)
    }
    waitOnce { handler in
        loader.texture(
            withContentsOf: URL(fileURLWithPath: "/tmp/missing.png"),
            options: nil,
            queue: queue,
            completionHandler: handler
        )
    }
    waitOnce { handler in
        loader.texture(withName: "missing", scaleFactor: 1, bundle: nil, options: nil, queue: queue, completionHandler: handler)
    }
    waitOnce { handler in
        loader.cubeMap(withContentsOfFile: "/tmp/missing.png", options: nil, queue: queue, completionHandler: handler)
    }
    waitOnce { handler in
        loader.cubeMap(withContentsOfFiles: ["a.png"], options: nil, queue: queue, completionHandler: handler)
    }
    waitOnce { handler in
        loader.cubeMap(
            withContentsOf: URL(fileURLWithPath: "/tmp/missing.png"),
            options: nil,
            queue: queue,
            completionHandler: handler
        )
    }
}

func testGLKTextureInfoEmpty() {
    let info = GLKTextureInfo()
    glkCheck(info.name == 0, "name")
    glkCheck(info.target == 0, "target")
    glkCheck(info.width == 0 && info.height == 0 && info.depth == 0, "size")
    glkCheck(info.mimapLevelCount == 0 && info.arrayLength == 0, "mip/array")
    glkCheck(info.alphaState == .none, "alphaState")
    glkCheck(info.textureOrigin == .unknown, "origin")
    glkCheck(info.containsMipmaps == false, "mipmaps")
}

func testGLKTextureLoaderOptionKeys() {
    glkCheck(GLKTextureLoaderApplyPremultiplication == "GLKTextureLoaderApplyPremultiplication", "apply")
    glkCheck(GLKTextureLoaderGenerateMipmaps == "GLKTextureLoaderGenerateMipmaps", "mip")
    glkCheck(GLKTextureLoaderOriginBottomLeft == "GLKTextureLoaderOriginBottomLeft", "origin")
    glkCheck(GLKTextureLoaderGrayscaleAsAlpha == "GLKTextureLoaderGrayscaleAsAlpha", "gray")
    glkCheck(GLKTextureLoaderSRGB == "GLKTextureLoaderSRGB", "srgb")
    glkCheck(GLKTextureLoaderErrorDomain == "GLKTextureLoaderErrorDomain", "domain")
    glkCheck(GLKTextureLoaderErrorKey == "GLKTextureLoaderErrorKey", "error key")
    glkCheck(GLKTextureLoaderGLErrorKey == "GLKTextureLoaderGLErrorKey", "gl error key")
}
