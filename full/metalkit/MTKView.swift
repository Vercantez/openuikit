import CoreGraphics
import Foundation
import Metal
import UIKit

@MainActor
public protocol MTKViewDelegate: AnyObject {
    func draw(in view: MTKView)
    func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize)
}

@MainActor
open class MTKView: UIView {
    public weak var delegate: (any MTKViewDelegate)?

    public var device: (any MTLDevice)? {
        didSet { invalidateDrawables() }
    }

    public var currentDrawable: (any CAMetalDrawable)? {
        if cachedDrawable == nil {
            cachedDrawable = makeSoftwareDrawable()
        }
        return cachedDrawable
    }

    public var framebufferOnly: Bool = true
    public var depthStencilAttachmentTextureUsage: MTLTextureUsage = .renderTarget
    public var multisampleColorAttachmentTextureUsage: MTLTextureUsage = .renderTarget
    public var presentsWithTransaction: Bool = false
    public var colorPixelFormat: MTLPixelFormat = .bgra8Unorm {
        didSet { invalidateDrawables() }
    }
    public var depthStencilPixelFormat: MTLPixelFormat = .invalid {
        didSet {
            cachedDepthTexture = nil
        }
    }
    public var depthStencilStorageMode: MTLStorageMode = .private
    public var sampleCount: Int = 1 {
        didSet { cachedDrawable = nil }
    }
    public var clearColor: MTLClearColor = MTLClearColor(red: 0, green: 0, blue: 0, alpha: 1)
    public var clearDepth: Double = 1
    public var clearStencil: UInt32 = 0
    public var preferredFramesPerSecond: Int = 60
    public var isPaused: Bool = false
    public var enableSetNeedsDisplay: Bool = false
    public var autoResizeDrawable: Bool = true

    public var drawableSize: CGSize {
        didSet {
            if oldValue != drawableSize {
                invalidateDrawables()
                delegate?.mtkView(self, drawableSizeWillChange: drawableSize)
            }
        }
    }

    open override var frame: CGRect {
        didSet {
            if autoResizeDrawable {
                drawableSize = scaledSize(frame.size)
            }
        }
    }

    public var preferredDevice: (any MTLDevice)? {
        MTLCreateSystemDefaultDevice()
    }

    public var preferredDrawableSize: CGSize {
        scaledSize(bounds.size)
    }

    public var depthStencilTexture: (any MTLTexture)? {
        guard depthStencilPixelFormat != .invalid else { return nil }
        if cachedDepthTexture == nil {
            cachedDepthTexture = makeSoftwareTexture(
                pixelFormat: depthStencilPixelFormat,
                usage: depthStencilAttachmentTextureUsage,
                storageMode: depthStencilStorageMode
            )
        }
        return cachedDepthTexture
    }

    public var multisampleColorTexture: (any MTLTexture)? {
        nil
    }

    public var currentRenderPassDescriptor: MTLRenderPassDescriptor? {
        guard let drawable = currentDrawable else { return nil }
        let descriptor = MTLRenderPassDescriptor()
        descriptor.colorAttachments[0].texture = drawable.texture
        descriptor.colorAttachments[0].loadAction = .clear
        descriptor.colorAttachments[0].storeAction = .store
        descriptor.colorAttachments[0].clearColor = clearColor
        descriptor.renderTargetWidth = max(Int(drawableSize.width.rounded(.down)), 1)
        descriptor.renderTargetHeight = max(Int(drawableSize.height.rounded(.down)), 1)
        if let depth = depthStencilTexture {
            descriptor.depthAttachment.texture = depth
            descriptor.depthAttachment.loadAction = .clear
            descriptor.depthAttachment.storeAction = .store
            descriptor.depthAttachment.clearDepth = clearDepth
            descriptor.stencilAttachment.clearStencil = clearStencil
        }
        return descriptor
    }

    public var currentMTL4RenderPassDescriptor: MTL4RenderPassDescriptor? {
        nil
    }

    private var cachedDrawable: (any CAMetalDrawable)?
    private var cachedDepthTexture: (any MTLTexture)?

    public init(frame frameRect: CGRect, device: (any MTLDevice)?) {
        self.device = device
        self.drawableSize = MTKView.scaledSize(frameRect.size, scale: 1)
        super.init(frame: frameRect)
        self.drawableSize = scaledSize(frameRect.size)
    }

    public override init(coder: NSCoder) {
        self.device = MTLCreateSystemDefaultDevice()
        self.drawableSize = .zero
        super.init(coder: coder)
    }

    public func releaseDrawables() {
        invalidateDrawables()
    }

    open func draw() {
        guard !isPaused else { return }
        _ = currentDrawable
        delegate?.draw(in: self)
    }

    open override func draw(_ rect: CGRect) {
        super.draw(rect)
        if enableSetNeedsDisplay {
            draw()
        }
    }

    private func invalidateDrawables() {
        cachedDrawable = nil
        cachedDepthTexture = nil
    }

    private func scaledSize(_ size: CGSize) -> CGSize {
        MTKView.scaledSize(size, scale: contentScaleFactor)
    }

    private static func scaledSize(_ size: CGSize, scale: CGFloat) -> CGSize {
        CGSize(width: max(size.width * scale, 0), height: max(size.height * scale, 0))
    }

    private func makeSoftwareDrawable() -> (any CAMetalDrawable)? {
        guard let texture = makeSoftwareTexture(
            pixelFormat: colorPixelFormat,
            usage: [.shaderRead, .renderTarget],
            storageMode: .shared
        ) else {
            return nil
        }
        return MetalSoftwareDrawable(texture: texture)
    }

    private func makeSoftwareTexture(
        pixelFormat: MTLPixelFormat,
        usage: MTLTextureUsage,
        storageMode: MTLStorageMode
    ) -> (any MTLTexture)? {
        guard let device else { return nil }
        let descriptor = MTLTextureDescriptor.texture2DDescriptor(
            pixelFormat: pixelFormat,
            width: max(Int(drawableSize.width.rounded(.down)), 1),
            height: max(Int(drawableSize.height.rounded(.down)), 1),
            mipmapped: false
        )
        descriptor.usage = usage
        descriptor.storageMode = storageMode
        descriptor.sampleCount = 1
        return device.makeTexture(descriptor: descriptor)
    }
}
