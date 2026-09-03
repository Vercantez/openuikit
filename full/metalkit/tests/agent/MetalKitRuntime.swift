import Foundation
@_spi(OpenUIKitHost) import MetalKit

enum MetalKitRuntimeFailure: Error {
    case message(String)
}

func expect(_ condition: Bool, _ message: String) throws {
    if !condition {
        throw MetalKitRuntimeFailure.message(message)
    }
}

@MainActor
final class RecordingDelegate: MTKViewDelegate {
    var drawCount = 0
    var sizeChanges: [CGSize] = []

    func draw(in view: MTKView) {
        _ = view.currentDrawable
        drawCount += 1
    }

    func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
        _ = view
        sizeChanges.append(size)
    }
}

func requireTextureLoaderError(_ error: (any Error)?, _ context: String) throws {
    guard let error else {
        throw MetalKitRuntimeFailure.message("\(context): expected fail-closed error")
    }
    let nsError = error as NSError
    try expect(nsError.domain == MTKTextureLoader.Error.domain.rawValue, "\(context): domain")
    try expect(nsError.domain == "MTKTextureLoaderErrorDomain", "\(context): domain payload")
}

func waitForAsyncThrow(_ body: @escaping () async throws -> Void) throws {
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
    try expect(semaphore.wait(timeout: .now() + 5) == .success, "async timeout")
    try requireTextureLoaderError(captured, "async throw")
}

@MainActor
func exerciseView() throws {
    let device = MTLCreateSystemDefaultDevice()
    try expect(device != nil, "software Metal device")
    let view = MTKView(frame: CGRect(x: 0, y: 0, width: 64, height: 32), device: device)
    try expect(view.colorPixelFormat == .bgra8Unorm, "default color format")
    try expect(view.clearDepth == 1, "default clear depth")
    try expect(view.clearStencil == 0, "default clear stencil")
    try expect(view.sampleCount == 1, "default sample count")
    try expect(view.autoResizeDrawable, "auto-resize default")
    try expect(view.preferredFramesPerSecond == 60, "default fps")
    try expect(!view.isPaused, "not paused by default")
    try expect(view.framebufferOnly, "framebufferOnly default")
    try expect(!view.presentsWithTransaction, "presentsWithTransaction default")
    try expect(!view.enableSetNeedsDisplay, "enableSetNeedsDisplay default")
    try expect(view.depthStencilPixelFormat == .invalid, "depth format default")
    try expect(view.depthStencilTexture == nil, "no depth texture when format is invalid")
    try expect(view.multisampleColorTexture == nil, "no GPU MSAA texture")
    try expect(view.currentMTL4RenderPassDescriptor == nil, "no Metal 4 pass")
    try expect(view.preferredDevice != nil, "preferredDevice")
    try expect(view.drawableSize.width == 64, "drawable width")
    try expect(view.drawableSize.height == 32, "drawable height")
    try expect(view.preferredDrawableSize.width == 64, "preferred drawable width")

    let delegate = RecordingDelegate()
    view.delegate = delegate
    view.drawableSize = CGSize(width: 48, height: 24)
    try expect(delegate.sizeChanges.last == CGSize(width: 48, height: 24), "size change callback")

    view.draw()
    try expect(delegate.drawCount == 1, "draw called once")
    let drawable = view.currentDrawable
    try expect(drawable != nil, "software drawable")
    try expect(drawable!.texture.width == 48, "drawable texture width")
    try expect(drawable!.texture.height == 24, "drawable texture height")
    try expect(drawable!.texture.pixelFormat == .bgra8Unorm, "drawable pixel format")

    let pass = view.currentRenderPassDescriptor
    try expect(pass != nil, "render pass")
    try expect(pass!.colorAttachments[0].texture != nil, "color attachment")
    try expect(pass!.colorAttachments[0].clearColor.alpha == 1, "clear alpha")

    view.depthStencilPixelFormat = .depth32Float
    try expect(view.depthStencilTexture != nil, "software depth texture")
    try expect(view.depthStencilTexture!.pixelFormat == .depth32Float, "depth format")

    view.releaseDrawables()
    view.isPaused = true
    let pausedCount = delegate.drawCount
    view.draw()
    try expect(delegate.drawCount == pausedCount, "paused skips draw")

    let coded = MTKView(coder: NSCoder())
    try expect(coded.frame == .zero, "coder init frame")
}

func exerciseTextureLoader() throws {
    guard let device = MTLCreateSystemDefaultDevice() else {
        throw MetalKitRuntimeFailure.message("missing software device")
    }
    let loader = MTKTextureLoader(device: device)
    try expect(ObjectIdentifier(loader.device as AnyObject) == ObjectIdentifier(device as AnyObject), "loader device identity")

    try expect(MTKTextureLoader.Option.SRGB.rawValue == "MTKTextureLoaderOptionSRGB", "SRGB option")
    try expect(MTKTextureLoader.Option.allocateMipmaps != MTKTextureLoader.Option.generateMipmaps, "option inequality")
    try expect(MTKTextureLoader.Origin.topLeft.rawValue.contains("TopLeft"), "origin topLeft")
    try expect(MTKTextureLoader.Origin.bottomLeft != MTKTextureLoader.Origin.flippedVertically, "origin inequality")
    try expect(MTKTextureLoader.CubeLayout.vertical.rawValue.contains("Vertical"), "cube layout")
    try expect(MTKTextureLoader.Error.domain.rawValue == "MTKTextureLoaderErrorDomain", "error domain")
    try expect(MTKTextureLoader.Error.key.rawValue == "MTKTextureLoaderErrorKey", "error key")
    try expect(MTKModelError.domain.rawValue == "MTKModelErrorDomain", "model domain")
    try expect(MTKModelError.key.rawValue == "MTKModelErrorKey", "model key")
    try expect(MTKModelError(rawValue: "x").hashValue == MTKModelError(rawValue: "x").hashValue, "model hash")

    var hasher = Hasher()
    MTKTextureLoader.Option.origin.hash(into: &hasher)
    _ = hasher.finalize()

    do {
        _ = try loader.newTexture(data: Data([0x89, 0x50, 0x4E, 0x47]), options: [.origin: MTKTextureLoader.Origin.topLeft])
        throw MetalKitRuntimeFailure.message("data load should fail closed")
    } catch {
        try requireTextureLoaderError(error, "data")
    }

    do {
        _ = try loader.newTexture(URL: URL(fileURLWithPath: "/tmp/missing-metalkit.png"))
        throw MetalKitRuntimeFailure.message("url load should fail closed")
    } catch {
        try requireTextureLoaderError(error, "url")
    }

    do {
        _ = try loader.newTexture(cgImage: CGImage(width: 2, height: 2))
        throw MetalKitRuntimeFailure.message("cgImage load should fail closed")
    } catch {
        try requireTextureLoaderError(error, "cgImage")
    }

    do {
        _ = try loader.newTexture(name: "missing", scaleFactor: 1, bundle: nil)
        throw MetalKitRuntimeFailure.message("name load should fail closed")
    } catch {
        try requireTextureLoaderError(error, "name")
    }

    var boxed: NSError?
    let produced = loader.newTextures(
        URLs: [URL(fileURLWithPath: "/tmp/a.png")],
        options: nil,
        error: &boxed
    )
    try expect(produced.isEmpty, "error-pointer path returns no textures")
    try requireTextureLoaderError(boxed, "error pointer")

    try waitForAsyncThrow {
        _ = try await loader.newTexture(data: Data())
    }
    try waitForAsyncThrow {
        _ = try await loader.newTexture(URL: URL(fileURLWithPath: "/tmp/b.png"))
    }
    try waitForAsyncThrow {
        _ = try await loader.newTexture(cgImage: CGImage(width: 1, height: 1))
    }
    try waitForAsyncThrow {
        _ = try await loader.newTexture(name: "x", scaleFactor: 2, bundle: nil)
    }
    try waitForAsyncThrow {
        _ = try await loader.newTextures(URLs: [URL(fileURLWithPath: "/tmp/c.png")])
    }
    try waitForAsyncThrow {
        _ = try await loader.newTextures(names: ["x"], scaleFactor: 1, bundle: nil)
    }

    let occupied = DispatchSemaphore(value: 0)
    let hold = DispatchSemaphore(value: 0)
    let returned = LockedFlag()
    MetalKitHostControl.enqueueTextureCompletionProbe {
        occupied.signal()
        hold.wait()
    }
    try expect(occupied.wait(timeout: .now() + 5) == .success, "occupy completion queue")
    Task {
        do {
            _ = try await loader.newTexture(data: Data([1]))
        } catch {
            returned.mark()
        }
    }
    Thread.sleep(forTimeInterval: 0.05)
    try expect(!returned.value, "async completion is not inline")
    hold.signal()
    var spins = 0
    while !returned.value && spins < 100 {
        Thread.sleep(forTimeInterval: 0.02)
        spins += 1
    }
    try expect(returned.value, "async completion eventually runs")
}

final class LockedFlag: @unchecked Sendable {
    private let lock = NSLock()
    private var stored = false

    func mark() {
        lock.lock()
        stored = true
        lock.unlock()
    }

    var value: Bool {
        lock.lock()
        defer { lock.unlock() }
        return stored
    }
}

func runOnMain(_ body: @MainActor () throws -> Void) throws {
    var caught: (any Error)?
    if Thread.isMainThread {
        try MainActor.assumeIsolated(body)
        return
    }
    DispatchQueue.main.sync {
        do {
            try MainActor.assumeIsolated(body)
        } catch {
            caught = error
        }
    }
    if let caught {
        throw caught
    }
}

do {
    try runOnMain {
        try exerciseView()
    }
    try exerciseTextureLoader()
    print("METALKIT_AGENT_RUNTIME_OK")
} catch {
    fputs("METALKIT_AGENT_RUNTIME_FAIL: \(error)\n", stderr)
    exit(1)
}
