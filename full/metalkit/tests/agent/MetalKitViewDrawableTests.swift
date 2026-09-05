import Foundation
import MetalKit

func testViewCurrentDrawable() {
    metalKitRunOnMain {
        let view = MTKView(frame: CGRect(x: 0, y: 0, width: 48, height: 24), device: MTLCreateSystemDefaultDevice())
        view.drawableSize = CGSize(width: 48, height: 24)
        let drawable = view.currentDrawable
        precondition(drawable != nil)
        precondition(drawable!.texture.width == 48)
        precondition(drawable!.texture.height == 24)
        precondition(drawable!.texture.pixelFormat == .bgra8Unorm)
        drawable!.present()
    }
}

func testViewCurrentRenderPassDescriptor() {
    metalKitRunOnMain {
        let view = MTKView(frame: CGRect(x: 0, y: 0, width: 16, height: 8), device: MTLCreateSystemDefaultDevice())
        view.clearColor = MTLClearColor(red: 0.1, green: 0.2, blue: 0.3, alpha: 1)
        let pass = view.currentRenderPassDescriptor
        precondition(pass != nil)
        precondition(pass!.colorAttachments[0].texture != nil)
        precondition(pass!.colorAttachments[0].clearColor.alpha == 1)
        precondition(pass!.colorAttachments[0].loadAction == .clear)
        precondition(pass!.renderTargetWidth == 16)
        precondition(pass!.renderTargetHeight == 8)
    }
}

func testViewRenderPassIncludesDepth() {
    metalKitRunOnMain {
        let view = MTKView(frame: CGRect(x: 0, y: 0, width: 8, height: 8), device: MTLCreateSystemDefaultDevice())
        view.depthStencilPixelFormat = .depth32Float
        view.clearDepth = 0.5
        view.clearStencil = 3
        let pass = view.currentRenderPassDescriptor
        precondition(pass != nil)
        precondition(pass!.depthAttachment.texture != nil)
        precondition(pass!.depthAttachment.clearDepth == 0.5)
        precondition(pass!.stencilAttachment.clearStencil == 3)
    }
}
