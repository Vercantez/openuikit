import Foundation
import MetalKit

private func requireLoaderError(_ error: (any Error)?, context: String) {
    let nsError = error as NSError?
    precondition(nsError != nil, context)
    precondition(nsError!.domain == MTKTextureLoader.Error.domain.rawValue, context)
    precondition(nsError!.domain == "MTKTextureLoaderErrorDomain", context)
}

private func waitForAsyncThrow(_ body: @escaping () async throws -> Void) {
    let semaphore = DispatchSemaphore(value: 0)
    var captured: (any Error)?
    Task {
        do {
            try await body()
        } catch {
            captured = error
        }
        semaphore.signal()
    }
    precondition(semaphore.wait(timeout: .now() + 5) == .success)
    requireLoaderError(captured, context: "async")
}

func testTextureLoaderInitAndDevice() {
    let device = MTLCreateSystemDefaultDevice()
    precondition(device != nil)
    let loader = MTKTextureLoader(device: device!)
    precondition(ObjectIdentifier(loader.device as AnyObject) == ObjectIdentifier(device as AnyObject))
}

func testNewTextureFromDataFailsClosed() {
    let loader = MTKTextureLoader(device: MTLCreateSystemDefaultDevice()!)
    do {
        _ = try loader.newTexture(data: Data([0x89, 0x50, 0x4E, 0x47]), options: [.origin: MTKTextureLoader.Origin.topLeft])
        preconditionFailure("data load should fail closed")
    } catch {
        requireLoaderError(error, context: "data")
    }
}

func testNewTextureFromURLFailsClosed() {
    let loader = MTKTextureLoader(device: MTLCreateSystemDefaultDevice()!)
    do {
        _ = try loader.newTexture(URL: URL(fileURLWithPath: "/tmp/missing-metalkit.png"))
        preconditionFailure("url load should fail closed")
    } catch {
        requireLoaderError(error, context: "url")
    }
}

func testNewTextureFromCGImageFailsClosed() {
    let loader = MTKTextureLoader(device: MTLCreateSystemDefaultDevice()!)
    do {
        _ = try loader.newTexture(cgImage: CGImage(width: 2, height: 2), options: [.SRGB: true])
        preconditionFailure("cgImage load should fail closed")
    } catch {
        requireLoaderError(error, context: "cgImage")
    }
}

func testNewTextureFromNameFailsClosed() {
    let loader = MTKTextureLoader(device: MTLCreateSystemDefaultDevice()!)
    do {
        _ = try loader.newTexture(name: "missing", scaleFactor: 2, bundle: nil)
        preconditionFailure("name load should fail closed")
    } catch {
        requireLoaderError(error, context: "name")
    }
}

func testNewTexturesFromURLsErrorPointer() {
    let loader = MTKTextureLoader(device: MTLCreateSystemDefaultDevice()!)
    var boxed: NSError?
    let produced = loader.newTextures(
        URLs: [URL(fileURLWithPath: "/tmp/a.png")],
        options: nil,
        error: &boxed
    )
    precondition(produced.isEmpty)
    requireLoaderError(boxed, context: "error pointer")
}

func testNewTextureAsyncOverloadsFailClosed() {
    let loader = MTKTextureLoader(device: MTLCreateSystemDefaultDevice()!)
    waitForAsyncThrow {
        _ = try await loader.newTexture(data: Data())
    }
    waitForAsyncThrow {
        _ = try await loader.newTexture(URL: URL(fileURLWithPath: "/tmp/b.png"))
    }
    waitForAsyncThrow {
        _ = try await loader.newTexture(cgImage: CGImage(width: 1, height: 1))
    }
    waitForAsyncThrow {
        _ = try await loader.newTexture(name: "x", scaleFactor: 2, bundle: nil)
    }
    waitForAsyncThrow {
        _ = try await loader.newTextures(URLs: [URL(fileURLWithPath: "/tmp/c.png")])
    }
}

func testNewTexturesFromNamesFailsClosed() {
    let loader = MTKTextureLoader(device: MTLCreateSystemDefaultDevice()!)
    waitForAsyncThrow {
        _ = try await loader.newTextures(names: ["x"], scaleFactor: 1, bundle: nil)
    }
}

func testNewTextureFromMDLTextureFailsClosed() {
    let loader = MTKTextureLoader(device: MTLCreateSystemDefaultDevice()!)
    let texture = MDLTexture(width: 4, height: 4, texels: Data(repeating: 255, count: 64))
    do {
        _ = try loader.newTexture(texture: texture)
        preconditionFailure("mdl texture load should fail closed")
    } catch {
        requireLoaderError(error, context: "mdl")
    }
    waitForAsyncThrow {
        _ = try await loader.newTexture(texture: texture)
    }
}

func testTextureLoaderCallbackTypealiases() {
    let callback: MTKTextureLoader.Callback = { _, _ in }
    let arrayCallback: MTKTextureLoader.ArrayCallback = { _, _ in }
    callback(nil, nil)
    arrayCallback([], nil)
}
