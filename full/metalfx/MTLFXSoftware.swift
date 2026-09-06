import Foundation

/// Software MetalFX objects for isolated-host tests. They snapshot descriptor
/// configuration and store per-frame bindings. `encode` is inert: it does not
/// upscale, denoise, interpolate, or write output texels.

final class MTLFXHostSpatialScaler: NSObject, MTLFXSpatialScaler {
    let colorProcessingMode: MTLFXSpatialScalerColorProcessingMode
    var colorTexture: (any MTLTexture)?
    let colorTextureFormat: MTLPixelFormat
    let colorTextureUsage: MTLTextureUsage
    var fence: (any MTLFence)?
    var inputContentHeight: UInt
    var inputContentWidth: UInt
    let inputHeight: UInt
    let inputWidth: UInt
    let outputHeight: UInt
    var outputTexture: (any MTLTexture)?
    let outputTextureFormat: MTLPixelFormat
    let outputTextureUsage: MTLTextureUsage
    let outputWidth: UInt

    init(descriptor: MTLFXSpatialScalerDescriptor) {
        colorProcessingMode = descriptor.colorProcessingMode
        colorTextureFormat = descriptor.colorTextureFormat
        colorTextureUsage = .unknown
        inputHeight = descriptor.inputHeight
        inputWidth = descriptor.inputWidth
        inputContentHeight = descriptor.inputHeight
        inputContentWidth = descriptor.inputWidth
        outputHeight = descriptor.outputHeight
        outputTextureFormat = descriptor.outputTextureFormat
        outputTextureUsage = .unknown
        outputWidth = descriptor.outputWidth
        super.init()
    }

    func encode(commandBuffer: any MTLCommandBuffer) {
        (commandBuffer as? MetalFXHostCommandBuffer)?.noteEncode()
    }
}

final class MTL4FXHostSpatialScaler: NSObject, MTL4FXSpatialScaler {
    let colorProcessingMode: MTLFXSpatialScalerColorProcessingMode
    var colorTexture: (any MTLTexture)?
    let colorTextureFormat: MTLPixelFormat
    let colorTextureUsage: MTLTextureUsage
    var fence: (any MTLFence)?
    var inputContentHeight: UInt
    var inputContentWidth: UInt
    let inputHeight: UInt
    let inputWidth: UInt
    let outputHeight: UInt
    var outputTexture: (any MTLTexture)?
    let outputTextureFormat: MTLPixelFormat
    let outputTextureUsage: MTLTextureUsage
    let outputWidth: UInt

    init(descriptor: MTLFXSpatialScalerDescriptor) {
        colorProcessingMode = descriptor.colorProcessingMode
        colorTextureFormat = descriptor.colorTextureFormat
        colorTextureUsage = .unknown
        inputHeight = descriptor.inputHeight
        inputWidth = descriptor.inputWidth
        inputContentHeight = descriptor.inputHeight
        inputContentWidth = descriptor.inputWidth
        outputHeight = descriptor.outputHeight
        outputTextureFormat = descriptor.outputTextureFormat
        outputTextureUsage = .unknown
        outputWidth = descriptor.outputWidth
        super.init()
    }

    func encode(commandBuffer: any MTL4CommandBuffer) {
        (commandBuffer as? MetalFXHostMTL4CommandBuffer)?.noteEncode()
    }
}

final class MTLFXHostTemporalScaler: NSObject, MTLFXTemporalScaler {
    var colorTexture: (any MTLTexture)?
    let colorTextureFormat: MTLPixelFormat
    let colorTextureUsage: MTLTextureUsage
    var isDepthReversed: Bool = false
    var depthTexture: (any MTLTexture)?
    let depthTextureFormat: MTLPixelFormat
    let depthTextureUsage: MTLTextureUsage
    var exposureTexture: (any MTLTexture)?
    var fence: (any MTLFence)?
    var inputContentHeight: UInt
    let inputContentMaxScale: Float
    let inputContentMinScale: Float
    var inputContentWidth: UInt
    let inputHeight: UInt
    let inputWidth: UInt
    var jitterOffsetX: Float = 0
    var jitterOffsetY: Float = 0
    var motionTexture: (any MTLTexture)?
    let motionTextureFormat: MTLPixelFormat
    let motionTextureUsage: MTLTextureUsage
    var motionVectorScaleX: Float = 1
    var motionVectorScaleY: Float = 1
    let outputHeight: UInt
    var outputTexture: (any MTLTexture)?
    let outputTextureFormat: MTLPixelFormat
    let outputTextureUsage: MTLTextureUsage
    let outputWidth: UInt
    var preExposure: Float = 1
    var reactiveMaskTexture: (any MTLTexture)?
    let reactiveMaskTextureFormat: MTLPixelFormat
    let reactiveTextureUsage: MTLTextureUsage
    var reset: Bool = false

    init(descriptor: MTLFXTemporalScalerDescriptor) {
        colorTextureFormat = descriptor.colorTextureFormat
        colorTextureUsage = .unknown
        depthTextureFormat = descriptor.depthTextureFormat
        depthTextureUsage = .unknown
        inputContentMaxScale = descriptor.inputContentMaxScale
        inputContentMinScale = descriptor.inputContentMinScale
        inputHeight = descriptor.inputHeight
        inputWidth = descriptor.inputWidth
        inputContentHeight = descriptor.inputHeight
        inputContentWidth = descriptor.inputWidth
        motionTextureFormat = descriptor.motionTextureFormat
        motionTextureUsage = .unknown
        outputHeight = descriptor.outputHeight
        outputTextureFormat = descriptor.outputTextureFormat
        outputTextureUsage = .unknown
        outputWidth = descriptor.outputWidth
        reactiveMaskTextureFormat = descriptor.reactiveMaskTextureFormat
        reactiveTextureUsage = .unknown
        super.init()
    }

    func encode(commandBuffer: any MTLCommandBuffer) {
        (commandBuffer as? MetalFXHostCommandBuffer)?.noteEncode()
    }
}

final class MTL4FXHostTemporalScaler: NSObject, MTL4FXTemporalScaler {
    var colorTexture: (any MTLTexture)?
    let colorTextureFormat: MTLPixelFormat
    let colorTextureUsage: MTLTextureUsage
    var isDepthReversed: Bool = false
    var depthTexture: (any MTLTexture)?
    let depthTextureFormat: MTLPixelFormat
    let depthTextureUsage: MTLTextureUsage
    var exposureTexture: (any MTLTexture)?
    var fence: (any MTLFence)?
    var inputContentHeight: UInt
    let inputContentMaxScale: Float
    let inputContentMinScale: Float
    var inputContentWidth: UInt
    let inputHeight: UInt
    let inputWidth: UInt
    var jitterOffsetX: Float = 0
    var jitterOffsetY: Float = 0
    var motionTexture: (any MTLTexture)?
    let motionTextureFormat: MTLPixelFormat
    let motionTextureUsage: MTLTextureUsage
    var motionVectorScaleX: Float = 1
    var motionVectorScaleY: Float = 1
    let outputHeight: UInt
    var outputTexture: (any MTLTexture)?
    let outputTextureFormat: MTLPixelFormat
    let outputTextureUsage: MTLTextureUsage
    let outputWidth: UInt
    var preExposure: Float = 1
    var reactiveMaskTexture: (any MTLTexture)?
    let reactiveMaskTextureFormat: MTLPixelFormat
    let reactiveTextureUsage: MTLTextureUsage
    var reset: Bool = false

    init(descriptor: MTLFXTemporalScalerDescriptor) {
        colorTextureFormat = descriptor.colorTextureFormat
        colorTextureUsage = .unknown
        depthTextureFormat = descriptor.depthTextureFormat
        depthTextureUsage = .unknown
        inputContentMaxScale = descriptor.inputContentMaxScale
        inputContentMinScale = descriptor.inputContentMinScale
        inputHeight = descriptor.inputHeight
        inputWidth = descriptor.inputWidth
        inputContentHeight = descriptor.inputHeight
        inputContentWidth = descriptor.inputWidth
        motionTextureFormat = descriptor.motionTextureFormat
        motionTextureUsage = .unknown
        outputHeight = descriptor.outputHeight
        outputTextureFormat = descriptor.outputTextureFormat
        outputTextureUsage = .unknown
        outputWidth = descriptor.outputWidth
        reactiveMaskTextureFormat = descriptor.reactiveMaskTextureFormat
        reactiveTextureUsage = .unknown
        super.init()
    }

    func encode(commandBuffer: any MTL4CommandBuffer) {
        (commandBuffer as? MetalFXHostMTL4CommandBuffer)?.noteEncode()
    }
}

final class MTLFXHostTemporalDenoisedScaler: NSObject, MTLFXTemporalDenoisedScaler {
    var colorTexture: (any MTLTexture)?
    let colorTextureFormat: MTLPixelFormat
    let colorTextureUsage: MTLTextureUsage
    var denoiseStrengthMaskTexture: (any MTLTexture)?
    let denoiseStrengthMaskTextureFormat: MTLPixelFormat
    let denoiseStrengthMaskTextureUsage: MTLTextureUsage
    var isDepthReversed: Bool = false
    var depthTexture: (any MTLTexture)?
    let depthTextureFormat: MTLPixelFormat
    let depthTextureUsage: MTLTextureUsage
    var diffuseAlbedoTexture: (any MTLTexture)?
    let diffuseAlbedoTextureFormat: MTLPixelFormat
    let diffuseAlbedoTextureUsage: MTLTextureUsage
    var exposureTexture: (any MTLTexture)?
    var fence: (any MTLFence)?
    let inputContentMaxScale: Float
    let inputContentMinScale: Float
    let inputHeight: UInt
    let inputWidth: UInt
    var jitterOffsetX: Float = 0
    var jitterOffsetY: Float = 0
    var motionTexture: (any MTLTexture)?
    let motionTextureFormat: MTLPixelFormat
    let motionTextureUsage: MTLTextureUsage
    var motionVectorScaleX: Float = 1
    var motionVectorScaleY: Float = 1
    var normalTexture: (any MTLTexture)?
    let normalTextureFormat: MTLPixelFormat
    let normalTextureUsage: MTLTextureUsage
    let outputHeight: UInt
    var outputTexture: (any MTLTexture)?
    let outputTextureFormat: MTLPixelFormat
    let outputTextureUsage: MTLTextureUsage
    let outputWidth: UInt
    var preExposure: Float = 1
    var reactiveMaskTexture: (any MTLTexture)?
    let reactiveMaskTextureFormat: MTLPixelFormat
    let reactiveTextureUsage: MTLTextureUsage
    var roughnessTexture: (any MTLTexture)?
    let roughnessTextureFormat: MTLPixelFormat
    let roughnessTextureUsage: MTLTextureUsage
    var shouldResetHistory: Bool = false
    var specularAlbedoTexture: (any MTLTexture)?
    let specularAlbedoTextureFormat: MTLPixelFormat
    let specularAlbedoTextureUsage: MTLTextureUsage
    var specularHitDistanceTexture: (any MTLTexture)?
    let specularHitDistanceTextureFormat: MTLPixelFormat
    let specularHitDistanceTextureUsage: MTLTextureUsage
    var transparencyOverlayTexture: (any MTLTexture)?
    let transparencyOverlayTextureFormat: MTLPixelFormat
    let transparencyOverlayTextureUsage: MTLTextureUsage
    var viewToClipMatrix: simd_float4x4 = .identity
    var worldToViewMatrix: simd_float4x4 = .identity

    init(descriptor: MTLFXTemporalDenoisedScalerDescriptor) {
        colorTextureFormat = descriptor.colorTextureFormat
        colorTextureUsage = .unknown
        denoiseStrengthMaskTextureFormat = descriptor.denoiseStrengthMaskTextureFormat
        denoiseStrengthMaskTextureUsage = .unknown
        depthTextureFormat = descriptor.depthTextureFormat
        depthTextureUsage = .unknown
        diffuseAlbedoTextureFormat = descriptor.diffuseAlbedoTextureFormat
        diffuseAlbedoTextureUsage = .unknown
        inputContentMaxScale = 1
        inputContentMinScale = 1
        inputHeight = descriptor.inputHeight
        inputWidth = descriptor.inputWidth
        motionTextureFormat = descriptor.motionTextureFormat
        motionTextureUsage = .unknown
        normalTextureFormat = descriptor.normalTextureFormat
        normalTextureUsage = .unknown
        outputHeight = descriptor.outputHeight
        outputTextureFormat = descriptor.outputTextureFormat
        outputTextureUsage = .unknown
        outputWidth = descriptor.outputWidth
        reactiveMaskTextureFormat = descriptor.reactiveMaskTextureFormat
        reactiveTextureUsage = .unknown
        roughnessTextureFormat = descriptor.roughnessTextureFormat
        roughnessTextureUsage = .unknown
        specularAlbedoTextureFormat = descriptor.specularAlbedoTextureFormat
        specularAlbedoTextureUsage = .unknown
        specularHitDistanceTextureFormat = descriptor.specularHitDistanceTextureFormat
        specularHitDistanceTextureUsage = .unknown
        transparencyOverlayTextureFormat = descriptor.transparencyOverlayTextureFormat
        transparencyOverlayTextureUsage = .unknown
        super.init()
    }

    func encode(commandBuffer: any MTLCommandBuffer) {
        (commandBuffer as? MetalFXHostCommandBuffer)?.noteEncode()
    }
}

final class MTL4FXHostTemporalDenoisedScaler: NSObject, MTL4FXTemporalDenoisedScaler {
    var colorTexture: (any MTLTexture)?
    let colorTextureFormat: MTLPixelFormat
    let colorTextureUsage: MTLTextureUsage
    var denoiseStrengthMaskTexture: (any MTLTexture)?
    let denoiseStrengthMaskTextureFormat: MTLPixelFormat
    let denoiseStrengthMaskTextureUsage: MTLTextureUsage
    var isDepthReversed: Bool = false
    var depthTexture: (any MTLTexture)?
    let depthTextureFormat: MTLPixelFormat
    let depthTextureUsage: MTLTextureUsage
    var diffuseAlbedoTexture: (any MTLTexture)?
    let diffuseAlbedoTextureFormat: MTLPixelFormat
    let diffuseAlbedoTextureUsage: MTLTextureUsage
    var exposureTexture: (any MTLTexture)?
    var fence: (any MTLFence)?
    let inputContentMaxScale: Float
    let inputContentMinScale: Float
    let inputHeight: UInt
    let inputWidth: UInt
    var jitterOffsetX: Float = 0
    var jitterOffsetY: Float = 0
    var motionTexture: (any MTLTexture)?
    let motionTextureFormat: MTLPixelFormat
    let motionTextureUsage: MTLTextureUsage
    var motionVectorScaleX: Float = 1
    var motionVectorScaleY: Float = 1
    var normalTexture: (any MTLTexture)?
    let normalTextureFormat: MTLPixelFormat
    let normalTextureUsage: MTLTextureUsage
    let outputHeight: UInt
    var outputTexture: (any MTLTexture)?
    let outputTextureFormat: MTLPixelFormat
    let outputTextureUsage: MTLTextureUsage
    let outputWidth: UInt
    var preExposure: Float = 1
    var reactiveMaskTexture: (any MTLTexture)?
    let reactiveMaskTextureFormat: MTLPixelFormat
    let reactiveTextureUsage: MTLTextureUsage
    var roughnessTexture: (any MTLTexture)?
    let roughnessTextureFormat: MTLPixelFormat
    let roughnessTextureUsage: MTLTextureUsage
    var shouldResetHistory: Bool = false
    var specularAlbedoTexture: (any MTLTexture)?
    let specularAlbedoTextureFormat: MTLPixelFormat
    let specularAlbedoTextureUsage: MTLTextureUsage
    var specularHitDistanceTexture: (any MTLTexture)?
    let specularHitDistanceTextureFormat: MTLPixelFormat
    let specularHitDistanceTextureUsage: MTLTextureUsage
    var transparencyOverlayTexture: (any MTLTexture)?
    let transparencyOverlayTextureFormat: MTLPixelFormat
    let transparencyOverlayTextureUsage: MTLTextureUsage
    var viewToClipMatrix: simd_float4x4 = .identity
    var worldToViewMatrix: simd_float4x4 = .identity

    init(descriptor: MTLFXTemporalDenoisedScalerDescriptor) {
        colorTextureFormat = descriptor.colorTextureFormat
        colorTextureUsage = .unknown
        denoiseStrengthMaskTextureFormat = descriptor.denoiseStrengthMaskTextureFormat
        denoiseStrengthMaskTextureUsage = .unknown
        depthTextureFormat = descriptor.depthTextureFormat
        depthTextureUsage = .unknown
        diffuseAlbedoTextureFormat = descriptor.diffuseAlbedoTextureFormat
        diffuseAlbedoTextureUsage = .unknown
        inputContentMaxScale = 1
        inputContentMinScale = 1
        inputHeight = descriptor.inputHeight
        inputWidth = descriptor.inputWidth
        motionTextureFormat = descriptor.motionTextureFormat
        motionTextureUsage = .unknown
        normalTextureFormat = descriptor.normalTextureFormat
        normalTextureUsage = .unknown
        outputHeight = descriptor.outputHeight
        outputTextureFormat = descriptor.outputTextureFormat
        outputTextureUsage = .unknown
        outputWidth = descriptor.outputWidth
        reactiveMaskTextureFormat = descriptor.reactiveMaskTextureFormat
        reactiveTextureUsage = .unknown
        roughnessTextureFormat = descriptor.roughnessTextureFormat
        roughnessTextureUsage = .unknown
        specularAlbedoTextureFormat = descriptor.specularAlbedoTextureFormat
        specularAlbedoTextureUsage = .unknown
        specularHitDistanceTextureFormat = descriptor.specularHitDistanceTextureFormat
        specularHitDistanceTextureUsage = .unknown
        transparencyOverlayTextureFormat = descriptor.transparencyOverlayTextureFormat
        transparencyOverlayTextureUsage = .unknown
        super.init()
    }

    func encode(commandBuffer: any MTL4CommandBuffer) {
        (commandBuffer as? MetalFXHostMTL4CommandBuffer)?.noteEncode()
    }
}

final class MTLFXHostFrameInterpolator: NSObject, MTLFXFrameInterpolator {
    var aspectRatio: Float = 1
    var colorTexture: (any MTLTexture)?
    let colorTextureFormat: MTLPixelFormat
    let colorTextureUsage: MTLTextureUsage
    var deltaTime: Float = 0
    var isDepthReversed: Bool = false
    var depthTexture: (any MTLTexture)?
    let depthTextureFormat: MTLPixelFormat
    let depthTextureUsage: MTLTextureUsage
    var farPlane: Float = 0
    var fence: (any MTLFence)?
    var fieldOfView: Float = 0
    let inputHeight: UInt
    let inputWidth: UInt
    var jitterOffsetX: Float = 0
    var jitterOffsetY: Float = 0
    var motionTexture: (any MTLTexture)?
    let motionTextureFormat: MTLPixelFormat
    let motionTextureUsage: MTLTextureUsage
    var motionVectorScaleX: Float = 1
    var motionVectorScaleY: Float = 1
    var nearPlane: Float = 0
    let outputHeight: UInt
    var outputTexture: (any MTLTexture)?
    let outputTextureFormat: MTLPixelFormat
    let outputTextureUsage: MTLTextureUsage
    let outputWidth: UInt
    var prevColorTexture: (any MTLTexture)?
    var shouldResetHistory: Bool = false
    var uiTexture: (any MTLTexture)?
    var isUITextureComposited: Bool = false
    let uiTextureFormat: MTLPixelFormat
    let uiTextureUsage: MTLTextureUsage

    init(descriptor: MTLFXFrameInterpolatorDescriptor) {
        colorTextureFormat = descriptor.colorTextureFormat
        colorTextureUsage = .unknown
        depthTextureFormat = descriptor.depthTextureFormat
        depthTextureUsage = .unknown
        inputHeight = descriptor.inputHeight
        inputWidth = descriptor.inputWidth
        motionTextureFormat = descriptor.motionTextureFormat
        motionTextureUsage = .unknown
        outputHeight = descriptor.outputHeight
        outputTextureFormat = descriptor.outputTextureFormat
        outputTextureUsage = .unknown
        outputWidth = descriptor.outputWidth
        uiTextureFormat = descriptor.uiTextureFormat
        uiTextureUsage = .unknown
        super.init()
    }

    func encode(commandBuffer: any MTLCommandBuffer) {
        (commandBuffer as? MetalFXHostCommandBuffer)?.noteEncode()
    }
}

final class MTL4FXHostFrameInterpolator: NSObject, MTL4FXFrameInterpolator {
    var aspectRatio: Float = 1
    var colorTexture: (any MTLTexture)?
    let colorTextureFormat: MTLPixelFormat
    let colorTextureUsage: MTLTextureUsage
    var deltaTime: Float = 0
    var isDepthReversed: Bool = false
    var depthTexture: (any MTLTexture)?
    let depthTextureFormat: MTLPixelFormat
    let depthTextureUsage: MTLTextureUsage
    var farPlane: Float = 0
    var fence: (any MTLFence)?
    var fieldOfView: Float = 0
    let inputHeight: UInt
    let inputWidth: UInt
    var jitterOffsetX: Float = 0
    var jitterOffsetY: Float = 0
    var motionTexture: (any MTLTexture)?
    let motionTextureFormat: MTLPixelFormat
    let motionTextureUsage: MTLTextureUsage
    var motionVectorScaleX: Float = 1
    var motionVectorScaleY: Float = 1
    var nearPlane: Float = 0
    let outputHeight: UInt
    var outputTexture: (any MTLTexture)?
    let outputTextureFormat: MTLPixelFormat
    let outputTextureUsage: MTLTextureUsage
    let outputWidth: UInt
    var prevColorTexture: (any MTLTexture)?
    var shouldResetHistory: Bool = false
    var uiTexture: (any MTLTexture)?
    var isUITextureComposited: Bool = false
    let uiTextureFormat: MTLPixelFormat
    let uiTextureUsage: MTLTextureUsage

    init(descriptor: MTLFXFrameInterpolatorDescriptor) {
        colorTextureFormat = descriptor.colorTextureFormat
        colorTextureUsage = .unknown
        depthTextureFormat = descriptor.depthTextureFormat
        depthTextureUsage = .unknown
        inputHeight = descriptor.inputHeight
        inputWidth = descriptor.inputWidth
        motionTextureFormat = descriptor.motionTextureFormat
        motionTextureUsage = .unknown
        outputHeight = descriptor.outputHeight
        outputTextureFormat = descriptor.outputTextureFormat
        outputTextureUsage = .unknown
        outputWidth = descriptor.outputWidth
        uiTextureFormat = descriptor.uiTextureFormat
        uiTextureUsage = .unknown
        super.init()
    }

    func encode(commandBuffer: any MTL4CommandBuffer) {
        (commandBuffer as? MetalFXHostMTL4CommandBuffer)?.noteEncode()
    }
}
