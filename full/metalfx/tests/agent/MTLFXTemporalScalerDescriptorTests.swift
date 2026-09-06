import Foundation
import MetalFX

func testTemporalScalerDescriptorConstructible() {
    let descriptor = MTLFXTemporalScalerDescriptor()
    precondition(type(of: descriptor) == MTLFXTemporalScalerDescriptor.self)
}

func testTemporalScalerDescriptorDefaults() {
    let descriptor = MTLFXTemporalScalerDescriptor()
    precondition(descriptor.colorTextureFormat == .invalid)
    precondition(descriptor.depthTextureFormat == .invalid)
    precondition(descriptor.motionTextureFormat == .invalid)
    precondition(descriptor.outputTextureFormat == .invalid)
    precondition(descriptor.reactiveMaskTextureFormat == .invalid)
    precondition(descriptor.inputWidth == 0)
    precondition(descriptor.inputHeight == 0)
    precondition(descriptor.outputWidth == 0)
    precondition(descriptor.outputHeight == 0)
    precondition(descriptor.isAutoExposureEnabled == false)
    precondition(descriptor.requiresSynchronousInitialization == false)
    precondition(descriptor.isInputContentPropertiesEnabled == false)
    precondition(descriptor.isReactiveMaskTextureEnabled == false)
    precondition(descriptor.inputContentMinScale == 1)
    precondition(descriptor.inputContentMaxScale == 1)
}

func testTemporalScalerDescriptorPropertyRoundTrip() {
    let descriptor = MTLFXTemporalScalerDescriptor()
    descriptor.colorTextureFormat = .rgba8Unorm
    descriptor.depthTextureFormat = .depth32Float
    descriptor.motionTextureFormat = .rg16Float
    descriptor.outputTextureFormat = .bgra8Unorm
    descriptor.reactiveMaskTextureFormat = .r8Unorm
    descriptor.inputWidth = 960
    descriptor.inputHeight = 540
    descriptor.outputWidth = 1920
    descriptor.outputHeight = 1080
    descriptor.isAutoExposureEnabled = true
    descriptor.requiresSynchronousInitialization = true
    descriptor.isInputContentPropertiesEnabled = true
    descriptor.isReactiveMaskTextureEnabled = true
    descriptor.inputContentMinScale = 1.25
    descriptor.inputContentMaxScale = 2.5
    precondition(descriptor.colorTextureFormat == .rgba8Unorm)
    precondition(descriptor.depthTextureFormat == .depth32Float)
    precondition(descriptor.motionTextureFormat == .rg16Float)
    precondition(descriptor.outputTextureFormat == .bgra8Unorm)
    precondition(descriptor.reactiveMaskTextureFormat == .r8Unorm)
    precondition(descriptor.inputWidth == 960)
    precondition(descriptor.inputHeight == 540)
    precondition(descriptor.outputWidth == 1920)
    precondition(descriptor.outputHeight == 1080)
    precondition(descriptor.isAutoExposureEnabled)
    precondition(descriptor.requiresSynchronousInitialization)
    precondition(descriptor.isInputContentPropertiesEnabled)
    precondition(descriptor.isReactiveMaskTextureEnabled)
    precondition(descriptor.inputContentMinScale == 1.25)
    precondition(descriptor.inputContentMaxScale == 2.5)
}

func testTemporalScalerDescriptorCopy() {
    let descriptor = MTLFXTemporalScalerDescriptor()
    descriptor.inputWidth = 11
    descriptor.inputHeight = 12
    descriptor.outputWidth = 21
    descriptor.outputHeight = 22
    descriptor.isAutoExposureEnabled = true
    descriptor.inputContentMinScale = 1.5
    let copied = descriptor.copy(with: nil) as! MTLFXTemporalScalerDescriptor
    precondition(copied !== descriptor)
    precondition(copied.inputWidth == 11)
    precondition(copied.inputHeight == 12)
    precondition(copied.outputWidth == 21)
    precondition(copied.outputHeight == 22)
    precondition(copied.isAutoExposureEnabled)
    precondition(copied.inputContentMinScale == 1.5)
    descriptor.inputWidth = 0
    precondition(copied.inputWidth == 11)
}

func testTemporalScalerDescriptorSupportsDeviceFalse() {
    precondition(MTLFXTemporalScalerDescriptor.supportsDevice(MetalFXHostDevice()) == false)
}

func testTemporalScalerDescriptorSupportsMetal4FXFalse() {
    precondition(MTLFXTemporalScalerDescriptor.supportsMetal4FX(MetalFXHostDevice()) == false)
}

func testTemporalScalerDescriptorSupportedInputContentScales() {
    let device = MetalFXHostDevice()
    precondition(MTLFXTemporalScalerDescriptor.supportedInputContentMinScale(device: device) == 1)
    precondition(MTLFXTemporalScalerDescriptor.supportedInputContentMaxScale(device: device) == 1)
}

func testTemporalScalerDescriptorMakeReturnsNil() {
    let descriptor = MTLFXTemporalScalerDescriptor()
    precondition(descriptor.makeTemporalScaler(device: MetalFXHostDevice()) == nil)
}

func testTemporalScalerDescriptorMakeMetal4ReturnsNil() {
    let device = MetalFXHostDevice()
    let compiler = MetalFXHostMTL4Compiler(device: device)
    let descriptor = MTLFXTemporalScalerDescriptor()
    precondition(descriptor.makeTemporalScaler(device: device, compiler: compiler) == nil)
}
