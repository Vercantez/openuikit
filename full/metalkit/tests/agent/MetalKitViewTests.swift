import Foundation
import MetalKit

func metalKitRunOnMain(_ body: @MainActor () -> Void) {
    if Thread.isMainThread {
        MainActor.assumeIsolated(body)
        return
    }
    DispatchQueue.main.sync {
        MainActor.assumeIsolated(body)
    }
}

func testViewInitWithFrameAndDevice() {
    metalKitRunOnMain {
        let device = MTLCreateSystemDefaultDevice()
        let view = MTKView(frame: CGRect(x: 0, y: 0, width: 64, height: 32), device: device)
        precondition(view.frame.width == 64)
        precondition(view.frame.height == 32)
        precondition(view.device != nil)
    }
}

func testViewInitWithCoder() {
    metalKitRunOnMain {
        let coded = MTKView(coder: NSCoder())
        precondition(coded.frame == .zero)
        precondition(coded.device != nil)
    }
}

func testViewDefaultColorAndClearState() {
    metalKitRunOnMain {
        let view = MTKView(frame: CGRect(x: 0, y: 0, width: 16, height: 16), device: MTLCreateSystemDefaultDevice())
        precondition(view.colorPixelFormat == .bgra8Unorm)
        precondition(view.clearColor.red == 0)
        precondition(view.clearColor.green == 0)
        precondition(view.clearColor.blue == 0)
        precondition(view.clearColor.alpha == 1)
        precondition(view.clearDepth == 1)
        precondition(view.clearStencil == 0)
    }
}

func testViewDefaultFlags() {
    metalKitRunOnMain {
        let view = MTKView(frame: .zero, device: MTLCreateSystemDefaultDevice())
        precondition(view.framebufferOnly)
        precondition(!view.presentsWithTransaction)
        precondition(!view.enableSetNeedsDisplay)
        precondition(view.autoResizeDrawable)
        precondition(!view.isPaused)
        precondition(view.sampleCount == 1)
        precondition(view.preferredFramesPerSecond == 60)
    }
}

func testViewPreferredDevice() {
    metalKitRunOnMain {
        let view = MTKView(frame: .zero, device: nil)
        precondition(view.preferredDevice != nil)
        view.device = view.preferredDevice
        precondition(view.device != nil)
    }
}

func testViewDrawableSizeAndPreferredSize() {
    metalKitRunOnMain {
        let view = MTKView(frame: CGRect(x: 0, y: 0, width: 64, height: 32), device: MTLCreateSystemDefaultDevice())
        precondition(view.drawableSize.width == 64)
        precondition(view.drawableSize.height == 32)
        precondition(view.preferredDrawableSize.width == 64)
        precondition(view.preferredDrawableSize.height == 32)
        view.contentScaleFactor = 2
        view.frame = CGRect(x: 0, y: 0, width: 10, height: 8)
        precondition(view.drawableSize.width == 20)
        precondition(view.drawableSize.height == 16)
    }
}

func testViewPausedSkipsDraw() {
    metalKitRunOnMain {
        let view = MTKView(frame: CGRect(x: 0, y: 0, width: 8, height: 8), device: MTLCreateSystemDefaultDevice())
        let delegate = MetalKitRecordingDelegate()
        view.delegate = delegate
        view.isPaused = true
        view.draw()
        precondition(delegate.drawCount == 0)
        view.isPaused = false
        view.draw()
        precondition(delegate.drawCount == 1)
    }
}

func testViewReleaseDrawables() {
    metalKitRunOnMain {
        let view = MTKView(frame: CGRect(x: 0, y: 0, width: 8, height: 8), device: MTLCreateSystemDefaultDevice())
        let first = view.currentDrawable
        precondition(first != nil)
        view.releaseDrawables()
        let second = view.currentDrawable
        precondition(second != nil)
        precondition(ObjectIdentifier(first as AnyObject) != ObjectIdentifier(second as AnyObject))
    }
}

func testViewDepthStencilTexture() {
    metalKitRunOnMain {
        let view = MTKView(frame: CGRect(x: 0, y: 0, width: 8, height: 8), device: MTLCreateSystemDefaultDevice())
        precondition(view.depthStencilPixelFormat == .invalid)
        precondition(view.depthStencilTexture == nil)
        view.depthStencilPixelFormat = .depth32Float
        view.depthStencilStorageMode = .private
        view.depthStencilAttachmentTextureUsage = .renderTarget
        precondition(view.depthStencilTexture != nil)
        precondition(view.depthStencilTexture!.pixelFormat == .depth32Float)
    }
}

func testViewMultisampleAndMTL4FailClosed() {
    metalKitRunOnMain {
        let view = MTKView(frame: CGRect(x: 0, y: 0, width: 8, height: 8), device: MTLCreateSystemDefaultDevice())
        view.sampleCount = 4
        view.multisampleColorAttachmentTextureUsage = .renderTarget
        precondition(view.multisampleColorTexture == nil)
        precondition(view.currentMTL4RenderPassDescriptor == nil)
    }
}

@MainActor
final class MetalKitRecordingDelegate: MTKViewDelegate {
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
