import Foundation
import MetalFX

func testTemporalDenoisedScalerDescriptorConstructible() {
    let descriptor = MTLFXTemporalDenoisedScalerDescriptor()
    precondition(type(of: descriptor) == MTLFXTemporalDenoisedScalerDescriptor.self)
}

func testTemporalDenoisedScalerDescriptorDefaults() {
    let descriptor = MTLFXTemporalDenoisedScalerDescriptor()
    precondition(descriptor.colorTextureFormat == .invalid)
    precondition(descriptor.depthTextureFormat == .invalid)
    precondition(descriptor.motionTextureFormat == .invalid)
    precondition(descriptor.diffuseAlbedoTextureFormat == .invalid)
    precondition(descriptor.specularAlbedoTextureFormat == .invalid)
    precondition(descriptor.normalTextureFormat == .invalid)
    precondition(descriptor.roughnessTextureFormat == .invalid)
    precondition(descriptor.specularHitDistanceTextureFormat == .invalid)
    precondition(descriptor.denoiseStrengthMaskTextureFormat == .invalid)
    precondition(descriptor.transparencyOverlayTextureFormat == .invalid)
    precondition(descriptor.outputTextureFormat == .invalid)
    precondition(descriptor.reactiveMaskTextureFormat == .invalid)
    precondition(descriptor.inputWidth == 0)
    precondition(descriptor.inputHeight == 0)
    precondition(descriptor.outputWidth == 0)
    precondition(descriptor.outputHeight == 0)
    precondition(descriptor.isAutoExposureEnabled == false)
    precondition(descriptor.requiresSynchronousInitialization == false)
    precondition(descriptor.isReactiveMaskTextureEnabled == false)
    precondition(descriptor.isSpecularHitDistanceTextureEnabled == false)
    precondition(descriptor.isDenoiseStrengthMaskTextureEnabled == false)
    precondition(descriptor.isTransparencyOverlayTextureEnabled == false)
}

func testTemporalDenoisedScalerDescriptorPropertyRoundTrip() {
    let descriptor = MTLFXTemporalDenoisedScalerDescriptor()
    descriptor.colorTextureFormat = .rgba16Float
    descriptor.depthTextureFormat = .depth32Float
    descriptor.motionTextureFormat = .rg16Float
    descriptor.diffuseAlbedoTextureFormat = .rgba8Unorm
    descriptor.specularAlbedoTextureFormat = .rgba8Unorm
    descriptor.normalTextureFormat = .rgba16Float
    descriptor.roughnessTextureFormat = .r16Float
    descriptor.specularHitDistanceTextureFormat = .r32Float
    descriptor.denoiseStrengthMaskTextureFormat = .r8Unorm
    descriptor.transparencyOverlayTextureFormat = .rgba8Unorm
    descriptor.outputTextureFormat = .rgba16Float
    descriptor.reactiveMaskTextureFormat = .r8Unorm
    descriptor.inputWidth = 640
    descriptor.inputHeight = 360
    descriptor.outputWidth = 1280
    descriptor.outputHeight = 720
    descriptor.isAutoExposureEnabled = true
    descriptor.requiresSynchronousInitialization = true
    descriptor.isReactiveMaskTextureEnabled = true
    descriptor.isSpecularHitDistanceTextureEnabled = true
    descriptor.isDenoiseStrengthMaskTextureEnabled = true
    descriptor.isTransparencyOverlayTextureEnabled = true
    precondition(descriptor.colorTextureFormat == .rgba16Float)
    precondition(descriptor.depthTextureFormat == .depth32Float)
    precondition(descriptor.motionTextureFormat == .rg16Float)
    precondition(descriptor.diffuseAlbedoTextureFormat == .rgba8Unorm)
    precondition(descriptor.specularAlbedoTextureFormat == .rgba8Unorm)
    precondition(descriptor.normalTextureFormat == .rgba16Float)
    precondition(descriptor.roughnessTextureFormat == .r16Float)
    precondition(descriptor.specularHitDistanceTextureFormat == .r32Float)
    precondition(descriptor.denoiseStrengthMaskTextureFormat == .r8Unorm)
    precondition(descriptor.transparencyOverlayTextureFormat == .rgba8Unorm)
    precondition(descriptor.outputTextureFormat == .rgba16Float)
    precondition(descriptor.reactiveMaskTextureFormat == .r8Unorm)
    precondition(descriptor.inputWidth == 640)
    precondition(descriptor.inputHeight == 360)
    precondition(descriptor.outputWidth == 1280)
    precondition(descriptor.outputHeight == 720)
    precondition(descriptor.isAutoExposureEnabled)
    precondition(descriptor.requiresSynchronousInitialization)
    precondition(descriptor.isReactiveMaskTextureEnabled)
    precondition(descriptor.isSpecularHitDistanceTextureEnabled)
    precondition(descriptor.isDenoiseStrengthMaskTextureEnabled)
    precondition(descriptor.isTransparencyOverlayTextureEnabled)
}

func testTemporalDenoisedScalerDescriptorCopy() {
    let descriptor = MTLFXTemporalDenoisedScalerDescriptor()
    descriptor.inputWidth = 7
    descriptor.normalTextureFormat = .rgba16Float
    descriptor.isDenoiseStrengthMaskTextureEnabled = true
    let copied = descriptor.copy(with: nil) as! MTLFXTemporalDenoisedScalerDescriptor
    precondition(copied !== descriptor)
    precondition(copied.inputWidth == 7)
    precondition(copied.normalTextureFormat == .rgba16Float)
    precondition(copied.isDenoiseStrengthMaskTextureEnabled)
    descriptor.inputWidth = 1
    precondition(copied.inputWidth == 7)
}

func testTemporalDenoisedScalerDescriptorSupportsDeviceFalse() {
    precondition(
        MTLFXTemporalDenoisedScalerDescriptor.supportsDevice(MetalFXHostDevice()) == false
    )
}

func testTemporalDenoisedScalerDescriptorSupportsMetal4FXFalse() {
    precondition(
        MTLFXTemporalDenoisedScalerDescriptor.supportsMetal4FX(MetalFXHostDevice()) == false
    )
}

func testTemporalDenoisedScalerDescriptorSupportedInputContentScales() {
    let device = MetalFXHostDevice()
    precondition(
        MTLFXTemporalDenoisedScalerDescriptor.supportedInputContentMinScale(device: device) == 1
    )
    precondition(
        MTLFXTemporalDenoisedScalerDescriptor.supportedInputContentMaxScale(device: device) == 1
    )
}

func testTemporalDenoisedScalerDescriptorMakeReturnsNil() {
    let descriptor = MTLFXTemporalDenoisedScalerDescriptor()
    precondition(descriptor.makeTemporalDenoisedScaler(device: MetalFXHostDevice()) == nil)
}

func testTemporalDenoisedScalerDescriptorMakeMetal4ReturnsNil() {
    let device = MetalFXHostDevice()
    let compiler = MetalFXHostMTL4Compiler(device: device)
    let descriptor = MTLFXTemporalDenoisedScalerDescriptor()
    precondition(
        descriptor.makeTemporalDenoisedScaler(device: device, compiler: compiler) == nil
    )
}
