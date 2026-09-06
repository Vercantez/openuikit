import Foundation

public protocol MTLFXFrameInterpolatableScaler: NSObjectProtocol {}

public protocol MTLFXSpatialScalerBase: NSObjectProtocol {
    var colorProcessingMode: MTLFXSpatialScalerColorProcessingMode { get }
    var colorTexture: (any MTLTexture)? { get set }
    var colorTextureFormat: MTLPixelFormat { get }
    var colorTextureUsage: MTLTextureUsage { get }
    var fence: (any MTLFence)? { get set }
    var inputContentHeight: UInt { get set }
    var inputContentWidth: UInt { get set }
    var inputHeight: UInt { get }
    var inputWidth: UInt { get }
    var outputHeight: UInt { get }
    var outputTexture: (any MTLTexture)? { get set }
    var outputTextureFormat: MTLPixelFormat { get }
    var outputTextureUsage: MTLTextureUsage { get }
    var outputWidth: UInt { get }
}

public protocol MTLFXSpatialScaler: MTLFXSpatialScalerBase {
    func encode(commandBuffer: any MTLCommandBuffer)
}

public protocol MTL4FXSpatialScaler: MTLFXSpatialScalerBase {
    func encode(commandBuffer: any MTL4CommandBuffer)
}

public protocol MTLFXTemporalScalerBase: MTLFXFrameInterpolatableScaler {
    var colorTexture: (any MTLTexture)? { get set }
    var colorTextureFormat: MTLPixelFormat { get }
    var colorTextureUsage: MTLTextureUsage { get }
    var isDepthReversed: Bool { get set }
    var depthTexture: (any MTLTexture)? { get set }
    var depthTextureFormat: MTLPixelFormat { get }
    var depthTextureUsage: MTLTextureUsage { get }
    var exposureTexture: (any MTLTexture)? { get set }
    var fence: (any MTLFence)? { get set }
    var inputContentHeight: UInt { get set }
    var inputContentMaxScale: Float { get }
    var inputContentMinScale: Float { get }
    var inputContentWidth: UInt { get set }
    var inputHeight: UInt { get }
    var inputWidth: UInt { get }
    var jitterOffsetX: Float { get set }
    var jitterOffsetY: Float { get set }
    var motionTexture: (any MTLTexture)? { get set }
    var motionTextureFormat: MTLPixelFormat { get }
    var motionTextureUsage: MTLTextureUsage { get }
    var motionVectorScaleX: Float { get set }
    var motionVectorScaleY: Float { get set }
    var outputHeight: UInt { get }
    var outputTexture: (any MTLTexture)? { get set }
    var outputTextureFormat: MTLPixelFormat { get }
    var outputTextureUsage: MTLTextureUsage { get }
    var outputWidth: UInt { get }
    var preExposure: Float { get set }
    var reactiveMaskTexture: (any MTLTexture)? { get set }
    var reactiveMaskTextureFormat: MTLPixelFormat { get }
    var reactiveTextureUsage: MTLTextureUsage { get }
    var reset: Bool { get set }
}

public protocol MTLFXTemporalScaler: MTLFXTemporalScalerBase {
    func encode(commandBuffer: any MTLCommandBuffer)
}

public protocol MTL4FXTemporalScaler: MTLFXTemporalScalerBase {
    func encode(commandBuffer: any MTL4CommandBuffer)
}

public protocol MTLFXTemporalDenoisedScalerBase: MTLFXFrameInterpolatableScaler {
    var colorTexture: (any MTLTexture)? { get set }
    var colorTextureFormat: MTLPixelFormat { get }
    var colorTextureUsage: MTLTextureUsage { get }
    var denoiseStrengthMaskTexture: (any MTLTexture)? { get set }
    var denoiseStrengthMaskTextureFormat: MTLPixelFormat { get }
    var denoiseStrengthMaskTextureUsage: MTLTextureUsage { get }
    var isDepthReversed: Bool { get set }
    var depthTexture: (any MTLTexture)? { get set }
    var depthTextureFormat: MTLPixelFormat { get }
    var depthTextureUsage: MTLTextureUsage { get }
    var diffuseAlbedoTexture: (any MTLTexture)? { get set }
    var diffuseAlbedoTextureFormat: MTLPixelFormat { get }
    var diffuseAlbedoTextureUsage: MTLTextureUsage { get }
    var exposureTexture: (any MTLTexture)? { get set }
    var fence: (any MTLFence)? { get set }
    var inputContentMaxScale: Float { get }
    var inputContentMinScale: Float { get }
    var inputHeight: UInt { get }
    var inputWidth: UInt { get }
    var jitterOffsetX: Float { get set }
    var jitterOffsetY: Float { get set }
    var motionTexture: (any MTLTexture)? { get set }
    var motionTextureFormat: MTLPixelFormat { get }
    var motionTextureUsage: MTLTextureUsage { get }
    var motionVectorScaleX: Float { get set }
    var motionVectorScaleY: Float { get set }
    var normalTexture: (any MTLTexture)? { get set }
    var normalTextureFormat: MTLPixelFormat { get }
    var normalTextureUsage: MTLTextureUsage { get }
    var outputHeight: UInt { get }
    var outputTexture: (any MTLTexture)? { get set }
    var outputTextureFormat: MTLPixelFormat { get }
    var outputTextureUsage: MTLTextureUsage { get }
    var outputWidth: UInt { get }
    var preExposure: Float { get set }
    var reactiveMaskTexture: (any MTLTexture)? { get set }
    var reactiveMaskTextureFormat: MTLPixelFormat { get }
    var reactiveTextureUsage: MTLTextureUsage { get }
    var roughnessTexture: (any MTLTexture)? { get set }
    var roughnessTextureFormat: MTLPixelFormat { get }
    var roughnessTextureUsage: MTLTextureUsage { get }
    var shouldResetHistory: Bool { get set }
    var specularAlbedoTexture: (any MTLTexture)? { get set }
    var specularAlbedoTextureFormat: MTLPixelFormat { get }
    var specularAlbedoTextureUsage: MTLTextureUsage { get }
    var specularHitDistanceTexture: (any MTLTexture)? { get set }
    var specularHitDistanceTextureFormat: MTLPixelFormat { get }
    var specularHitDistanceTextureUsage: MTLTextureUsage { get }
    var transparencyOverlayTexture: (any MTLTexture)? { get set }
    var transparencyOverlayTextureFormat: MTLPixelFormat { get }
    var transparencyOverlayTextureUsage: MTLTextureUsage { get }
    var viewToClipMatrix: simd_float4x4 { get set }
    var worldToViewMatrix: simd_float4x4 { get set }
}

public protocol MTLFXTemporalDenoisedScaler: MTLFXTemporalDenoisedScalerBase {
    func encode(commandBuffer: any MTLCommandBuffer)
}

public protocol MTL4FXTemporalDenoisedScaler: MTLFXTemporalDenoisedScalerBase {
    func encode(commandBuffer: any MTL4CommandBuffer)
}

public protocol MTLFXFrameInterpolatorBase: NSObjectProtocol {
    var aspectRatio: Float { get set }
    var colorTexture: (any MTLTexture)? { get set }
    var colorTextureFormat: MTLPixelFormat { get }
    var colorTextureUsage: MTLTextureUsage { get }
    var deltaTime: Float { get set }
    var isDepthReversed: Bool { get set }
    var depthTexture: (any MTLTexture)? { get set }
    var depthTextureFormat: MTLPixelFormat { get }
    var depthTextureUsage: MTLTextureUsage { get }
    var farPlane: Float { get set }
    var fence: (any MTLFence)? { get set }
    var fieldOfView: Float { get set }
    var inputHeight: UInt { get }
    var inputWidth: UInt { get }
    var jitterOffsetX: Float { get set }
    var jitterOffsetY: Float { get set }
    var motionTexture: (any MTLTexture)? { get set }
    var motionTextureFormat: MTLPixelFormat { get }
    var motionTextureUsage: MTLTextureUsage { get }
    var motionVectorScaleX: Float { get set }
    var motionVectorScaleY: Float { get set }
    var nearPlane: Float { get set }
    var outputHeight: UInt { get }
    var outputTexture: (any MTLTexture)? { get set }
    var outputTextureFormat: MTLPixelFormat { get }
    var outputTextureUsage: MTLTextureUsage { get }
    var outputWidth: UInt { get }
    var prevColorTexture: (any MTLTexture)? { get set }
    var shouldResetHistory: Bool { get set }
    var uiTexture: (any MTLTexture)? { get set }
    var isUITextureComposited: Bool { get set }
    var uiTextureFormat: MTLPixelFormat { get }
    var uiTextureUsage: MTLTextureUsage { get }
}

public protocol MTLFXFrameInterpolator: MTLFXFrameInterpolatorBase {
    func encode(commandBuffer: any MTLCommandBuffer)
}

public protocol MTL4FXFrameInterpolator: MTLFXFrameInterpolatorBase {
    func encode(commandBuffer: any MTL4CommandBuffer)
}
