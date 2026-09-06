import Foundation

/// Linux policy: no Apple GPU / MetalFX hardware, so device support is false
/// and factory methods return `nil`. Exact Darwin scale-range values remain
/// an oracle question; unsupported devices report identity-only 1.0.
private let metalFXUnsupportedInputContentScale: Float = 1.0

open class MTLFXSpatialScalerDescriptor: NSObject, NSCopying {
    public var colorProcessingMode: MTLFXSpatialScalerColorProcessingMode = .perceptual
    public var colorTextureFormat: MTLPixelFormat = .invalid
    public var inputHeight: UInt = 0
    public var inputWidth: UInt = 0
    public var outputHeight: UInt = 0
    public var outputTextureFormat: MTLPixelFormat = .invalid
    public var outputWidth: UInt = 0

    public override init() {
        super.init()
    }

    public func copy(with zone: NSZone? = nil) -> Any {
        let copy = MTLFXSpatialScalerDescriptor()
        copy.colorProcessingMode = colorProcessingMode
        copy.colorTextureFormat = colorTextureFormat
        copy.inputHeight = inputHeight
        copy.inputWidth = inputWidth
        copy.outputHeight = outputHeight
        copy.outputTextureFormat = outputTextureFormat
        copy.outputWidth = outputWidth
        return copy
    }

    public class func supportsDevice(_ device: any MTLDevice) -> Bool {
        _ = device
        return false
    }

    public class func supportsMetal4FX(_ device: any MTLDevice) -> Bool {
        _ = device
        return false
    }

    public func makeSpatialScaler(device: any MTLDevice) -> (any MTLFXSpatialScaler)? {
        _ = device
        return nil
    }

    public func makeSpatialScaler(
        device: any MTLDevice,
        compiler: any MTL4Compiler
    ) -> (any MTL4FXSpatialScaler)? {
        _ = device
        _ = compiler
        return nil
    }

    public func host_makeSoftwareSpatialScaler() -> any MTLFXSpatialScaler {
        MTLFXHostSpatialScaler(descriptor: self)
    }

    public func host_makeSoftwareMetal4SpatialScaler() -> any MTL4FXSpatialScaler {
        MTL4FXHostSpatialScaler(descriptor: self)
    }
}

open class MTLFXTemporalScalerDescriptor: NSObject, NSCopying {
    public var isAutoExposureEnabled: Bool = false
    public var colorTextureFormat: MTLPixelFormat = .invalid
    public var depthTextureFormat: MTLPixelFormat = .invalid
    public var inputContentMaxScale: Float = metalFXUnsupportedInputContentScale
    public var inputContentMinScale: Float = metalFXUnsupportedInputContentScale
    public var isInputContentPropertiesEnabled: Bool = false
    public var inputHeight: UInt = 0
    public var inputWidth: UInt = 0
    public var motionTextureFormat: MTLPixelFormat = .invalid
    public var outputHeight: UInt = 0
    public var outputTextureFormat: MTLPixelFormat = .invalid
    public var outputWidth: UInt = 0
    public var isReactiveMaskTextureEnabled: Bool = false
    public var reactiveMaskTextureFormat: MTLPixelFormat = .invalid
    public var requiresSynchronousInitialization: Bool = false

    public override init() {
        super.init()
    }

    public func copy(with zone: NSZone? = nil) -> Any {
        let copy = MTLFXTemporalScalerDescriptor()
        copy.isAutoExposureEnabled = isAutoExposureEnabled
        copy.colorTextureFormat = colorTextureFormat
        copy.depthTextureFormat = depthTextureFormat
        copy.inputContentMaxScale = inputContentMaxScale
        copy.inputContentMinScale = inputContentMinScale
        copy.isInputContentPropertiesEnabled = isInputContentPropertiesEnabled
        copy.inputHeight = inputHeight
        copy.inputWidth = inputWidth
        copy.motionTextureFormat = motionTextureFormat
        copy.outputHeight = outputHeight
        copy.outputTextureFormat = outputTextureFormat
        copy.outputWidth = outputWidth
        copy.isReactiveMaskTextureEnabled = isReactiveMaskTextureEnabled
        copy.reactiveMaskTextureFormat = reactiveMaskTextureFormat
        copy.requiresSynchronousInitialization = requiresSynchronousInitialization
        return copy
    }

    public class func supportsDevice(_ device: any MTLDevice) -> Bool {
        _ = device
        return false
    }

    public class func supportsMetal4FX(_ device: any MTLDevice) -> Bool {
        _ = device
        return false
    }

    public class func supportedInputContentMinScale(device: any MTLDevice) -> Float {
        _ = device
        return metalFXUnsupportedInputContentScale
    }

    public class func supportedInputContentMaxScale(device: any MTLDevice) -> Float {
        _ = device
        return metalFXUnsupportedInputContentScale
    }

    public func makeTemporalScaler(device: any MTLDevice) -> (any MTLFXTemporalScaler)? {
        _ = device
        return nil
    }

    public func makeTemporalScaler(
        device: any MTLDevice,
        compiler: any MTL4Compiler
    ) -> (any MTL4FXTemporalScaler)? {
        _ = device
        _ = compiler
        return nil
    }

    public func host_makeSoftwareTemporalScaler() -> any MTLFXTemporalScaler {
        MTLFXHostTemporalScaler(descriptor: self)
    }

    public func host_makeSoftwareMetal4TemporalScaler() -> any MTL4FXTemporalScaler {
        MTL4FXHostTemporalScaler(descriptor: self)
    }
}

open class MTLFXTemporalDenoisedScalerDescriptor: NSObject, NSCopying {
    public var isAutoExposureEnabled: Bool = false
    public var colorTextureFormat: MTLPixelFormat = .invalid
    public var isDenoiseStrengthMaskTextureEnabled: Bool = false
    public var denoiseStrengthMaskTextureFormat: MTLPixelFormat = .invalid
    public var depthTextureFormat: MTLPixelFormat = .invalid
    public var diffuseAlbedoTextureFormat: MTLPixelFormat = .invalid
    public var inputHeight: UInt = 0
    public var inputWidth: UInt = 0
    public var motionTextureFormat: MTLPixelFormat = .invalid
    public var normalTextureFormat: MTLPixelFormat = .invalid
    public var outputHeight: UInt = 0
    public var outputTextureFormat: MTLPixelFormat = .invalid
    public var outputWidth: UInt = 0
    public var isReactiveMaskTextureEnabled: Bool = false
    public var reactiveMaskTextureFormat: MTLPixelFormat = .invalid
    public var requiresSynchronousInitialization: Bool = false
    public var roughnessTextureFormat: MTLPixelFormat = .invalid
    public var specularAlbedoTextureFormat: MTLPixelFormat = .invalid
    public var isSpecularHitDistanceTextureEnabled: Bool = false
    public var specularHitDistanceTextureFormat: MTLPixelFormat = .invalid
    public var isTransparencyOverlayTextureEnabled: Bool = false
    public var transparencyOverlayTextureFormat: MTLPixelFormat = .invalid

    public override init() {
        super.init()
    }

    public func copy(with zone: NSZone? = nil) -> Any {
        let copy = MTLFXTemporalDenoisedScalerDescriptor()
        copy.isAutoExposureEnabled = isAutoExposureEnabled
        copy.colorTextureFormat = colorTextureFormat
        copy.isDenoiseStrengthMaskTextureEnabled = isDenoiseStrengthMaskTextureEnabled
        copy.denoiseStrengthMaskTextureFormat = denoiseStrengthMaskTextureFormat
        copy.depthTextureFormat = depthTextureFormat
        copy.diffuseAlbedoTextureFormat = diffuseAlbedoTextureFormat
        copy.inputHeight = inputHeight
        copy.inputWidth = inputWidth
        copy.motionTextureFormat = motionTextureFormat
        copy.normalTextureFormat = normalTextureFormat
        copy.outputHeight = outputHeight
        copy.outputTextureFormat = outputTextureFormat
        copy.outputWidth = outputWidth
        copy.isReactiveMaskTextureEnabled = isReactiveMaskTextureEnabled
        copy.reactiveMaskTextureFormat = reactiveMaskTextureFormat
        copy.requiresSynchronousInitialization = requiresSynchronousInitialization
        copy.roughnessTextureFormat = roughnessTextureFormat
        copy.specularAlbedoTextureFormat = specularAlbedoTextureFormat
        copy.isSpecularHitDistanceTextureEnabled = isSpecularHitDistanceTextureEnabled
        copy.specularHitDistanceTextureFormat = specularHitDistanceTextureFormat
        copy.isTransparencyOverlayTextureEnabled = isTransparencyOverlayTextureEnabled
        copy.transparencyOverlayTextureFormat = transparencyOverlayTextureFormat
        return copy
    }

    public class func supportsDevice(_ device: any MTLDevice) -> Bool {
        _ = device
        return false
    }

    public class func supportsMetal4FX(_ device: any MTLDevice) -> Bool {
        _ = device
        return false
    }

    public class func supportedInputContentMinScale(device: any MTLDevice) -> Float {
        _ = device
        return metalFXUnsupportedInputContentScale
    }

    public class func supportedInputContentMaxScale(device: any MTLDevice) -> Float {
        _ = device
        return metalFXUnsupportedInputContentScale
    }

    public func makeTemporalDenoisedScaler(
        device: any MTLDevice
    ) -> (any MTLFXTemporalDenoisedScaler)? {
        _ = device
        return nil
    }

    public func makeTemporalDenoisedScaler(
        device: any MTLDevice,
        compiler: any MTL4Compiler
    ) -> (any MTL4FXTemporalDenoisedScaler)? {
        _ = device
        _ = compiler
        return nil
    }

    public func host_makeSoftwareTemporalDenoisedScaler() -> any MTLFXTemporalDenoisedScaler {
        MTLFXHostTemporalDenoisedScaler(descriptor: self)
    }

    public func host_makeSoftwareMetal4TemporalDenoisedScaler() -> any MTL4FXTemporalDenoisedScaler {
        MTL4FXHostTemporalDenoisedScaler(descriptor: self)
    }
}

open class MTLFXFrameInterpolatorDescriptor: NSObject, NSCopying {
    public var colorTextureFormat: MTLPixelFormat = .invalid
    public var depthTextureFormat: MTLPixelFormat = .invalid
    public var inputHeight: UInt = 0
    public var inputWidth: UInt = 0
    public var motionTextureFormat: MTLPixelFormat = .invalid
    public var outputHeight: UInt = 0
    public var outputTextureFormat: MTLPixelFormat = .invalid
    public var outputWidth: UInt = 0
    public var scaler: (any MTLFXFrameInterpolatableScaler)?
    public var uiTextureFormat: MTLPixelFormat = .invalid

    public override init() {
        super.init()
    }

    public func copy(with zone: NSZone? = nil) -> Any {
        let copy = MTLFXFrameInterpolatorDescriptor()
        copy.colorTextureFormat = colorTextureFormat
        copy.depthTextureFormat = depthTextureFormat
        copy.inputHeight = inputHeight
        copy.inputWidth = inputWidth
        copy.motionTextureFormat = motionTextureFormat
        copy.outputHeight = outputHeight
        copy.outputTextureFormat = outputTextureFormat
        copy.outputWidth = outputWidth
        copy.scaler = scaler
        copy.uiTextureFormat = uiTextureFormat
        return copy
    }

    public class func supportsDevice(_ device: any MTLDevice) -> Bool {
        _ = device
        return false
    }

    public class func supportsMetal4FX(_ device: any MTLDevice) -> Bool {
        _ = device
        return false
    }

    public func makeFrameInterpolator(device: any MTLDevice) -> (any MTLFXFrameInterpolator)? {
        _ = device
        return nil
    }

    public func makeFrameInterpolator(
        device: any MTLDevice,
        compiler: any MTL4Compiler
    ) -> (any MTL4FXFrameInterpolator)? {
        _ = device
        _ = compiler
        return nil
    }

    public func host_makeSoftwareFrameInterpolator() -> any MTLFXFrameInterpolator {
        MTLFXHostFrameInterpolator(descriptor: self)
    }

    public func host_makeSoftwareMetal4FrameInterpolator() -> any MTL4FXFrameInterpolator {
        MTL4FXHostFrameInterpolator(descriptor: self)
    }
}
