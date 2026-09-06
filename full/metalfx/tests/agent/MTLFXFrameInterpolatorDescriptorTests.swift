import Foundation
import MetalFX

func testFrameInterpolatorDescriptorConstructible() {
    let descriptor = MTLFXFrameInterpolatorDescriptor()
    precondition(type(of: descriptor) == MTLFXFrameInterpolatorDescriptor.self)
}

func testFrameInterpolatorDescriptorDefaults() {
    let descriptor = MTLFXFrameInterpolatorDescriptor()
    precondition(descriptor.colorTextureFormat == .invalid)
    precondition(descriptor.depthTextureFormat == .invalid)
    precondition(descriptor.motionTextureFormat == .invalid)
    precondition(descriptor.outputTextureFormat == .invalid)
    precondition(descriptor.uiTextureFormat == .invalid)
    precondition(descriptor.inputWidth == 0)
    precondition(descriptor.inputHeight == 0)
    precondition(descriptor.outputWidth == 0)
    precondition(descriptor.outputHeight == 0)
    precondition(descriptor.scaler == nil)
}

func testFrameInterpolatorDescriptorPropertyRoundTrip() {
    let descriptor = MTLFXFrameInterpolatorDescriptor()
    descriptor.colorTextureFormat = .rgba8Unorm
    descriptor.depthTextureFormat = .depth32Float
    descriptor.motionTextureFormat = .rg16Float
    descriptor.outputTextureFormat = .bgra8Unorm
    descriptor.uiTextureFormat = .bgra8Unorm
    descriptor.inputWidth = 800
    descriptor.inputHeight = 600
    descriptor.outputWidth = 1600
    descriptor.outputHeight = 1200
    let temporal = MTLFXTemporalScalerDescriptor()
    temporal.inputWidth = 800
    temporal.inputHeight = 600
    temporal.outputWidth = 1600
    temporal.outputHeight = 1200
    let scaler = temporal.host_makeSoftwareTemporalScaler()
    descriptor.scaler = scaler
    precondition(descriptor.colorTextureFormat == .rgba8Unorm)
    precondition(descriptor.depthTextureFormat == .depth32Float)
    precondition(descriptor.motionTextureFormat == .rg16Float)
    precondition(descriptor.outputTextureFormat == .bgra8Unorm)
    precondition(descriptor.uiTextureFormat == .bgra8Unorm)
    precondition(descriptor.inputWidth == 800)
    precondition(descriptor.inputHeight == 600)
    precondition(descriptor.outputWidth == 1600)
    precondition(descriptor.outputHeight == 1200)
    precondition(descriptor.scaler != nil)
    precondition(descriptor.scaler === scaler)
}

func testFrameInterpolatorDescriptorCopy() {
    let descriptor = MTLFXFrameInterpolatorDescriptor()
    descriptor.inputWidth = 4
    descriptor.uiTextureFormat = .rgba8Unorm
    let copied = descriptor.copy(with: nil) as! MTLFXFrameInterpolatorDescriptor
    precondition(copied !== descriptor)
    precondition(copied.inputWidth == 4)
    precondition(copied.uiTextureFormat == .rgba8Unorm)
    descriptor.inputWidth = 9
    precondition(copied.inputWidth == 4)
}

func testFrameInterpolatorDescriptorSupportsDeviceFalse() {
    precondition(MTLFXFrameInterpolatorDescriptor.supportsDevice(MetalFXHostDevice()) == false)
}

func testFrameInterpolatorDescriptorSupportsMetal4FXFalse() {
    precondition(MTLFXFrameInterpolatorDescriptor.supportsMetal4FX(MetalFXHostDevice()) == false)
}

func testFrameInterpolatorDescriptorMakeReturnsNil() {
    let descriptor = MTLFXFrameInterpolatorDescriptor()
    precondition(descriptor.makeFrameInterpolator(device: MetalFXHostDevice()) == nil)
}

func testFrameInterpolatorDescriptorMakeMetal4ReturnsNil() {
    let device = MetalFXHostDevice()
    let compiler = MetalFXHostMTL4Compiler(device: device)
    let descriptor = MTLFXFrameInterpolatorDescriptor()
    precondition(descriptor.makeFrameInterpolator(device: device, compiler: compiler) == nil)
}
