import Foundation
import MetalFX

func testSpatialScalerDescriptorConstructible() {
    let descriptor = MTLFXSpatialScalerDescriptor()
    precondition(type(of: descriptor) == MTLFXSpatialScalerDescriptor.self)
}

func testSpatialScalerDescriptorDefaults() {
    let descriptor = MTLFXSpatialScalerDescriptor()
    precondition(descriptor.colorProcessingMode == .perceptual)
    precondition(descriptor.colorTextureFormat == .invalid)
    precondition(descriptor.outputTextureFormat == .invalid)
    precondition(descriptor.inputWidth == 0)
    precondition(descriptor.inputHeight == 0)
    precondition(descriptor.outputWidth == 0)
    precondition(descriptor.outputHeight == 0)
}

func testSpatialScalerDescriptorPropertyRoundTrip() {
    let descriptor = MTLFXSpatialScalerDescriptor()
    descriptor.colorProcessingMode = .hdr
    descriptor.colorTextureFormat = .rgba8Unorm
    descriptor.outputTextureFormat = .bgra8Unorm
    descriptor.inputWidth = 1280
    descriptor.inputHeight = 720
    descriptor.outputWidth = 1920
    descriptor.outputHeight = 1080
    precondition(descriptor.colorProcessingMode == .hdr)
    precondition(descriptor.colorTextureFormat == .rgba8Unorm)
    precondition(descriptor.outputTextureFormat == .bgra8Unorm)
    precondition(descriptor.inputWidth == 1280)
    precondition(descriptor.inputHeight == 720)
    precondition(descriptor.outputWidth == 1920)
    precondition(descriptor.outputHeight == 1080)
}

func testSpatialScalerDescriptorCopy() {
    let descriptor = MTLFXSpatialScalerDescriptor()
    descriptor.colorProcessingMode = .linear
    descriptor.colorTextureFormat = .rgba16Float
    descriptor.outputTextureFormat = .rgba16Float
    descriptor.inputWidth = 64
    descriptor.inputHeight = 32
    descriptor.outputWidth = 128
    descriptor.outputHeight = 64
    let copied = descriptor.copy(with: nil) as! MTLFXSpatialScalerDescriptor
    precondition(copied !== descriptor)
    precondition(copied.colorProcessingMode == .linear)
    precondition(copied.colorTextureFormat == .rgba16Float)
    precondition(copied.outputTextureFormat == .rgba16Float)
    precondition(copied.inputWidth == 64)
    precondition(copied.inputHeight == 32)
    precondition(copied.outputWidth == 128)
    precondition(copied.outputHeight == 64)
    descriptor.inputWidth = 99
    precondition(copied.inputWidth == 64)
}

func testSpatialScalerDescriptorSupportsDeviceFalse() {
    let device = MetalFXHostDevice()
    precondition(MTLFXSpatialScalerDescriptor.supportsDevice(device) == false)
}

func testSpatialScalerDescriptorSupportsMetal4FXFalse() {
    let device = MetalFXHostDevice()
    precondition(MTLFXSpatialScalerDescriptor.supportsMetal4FX(device) == false)
}

func testSpatialScalerDescriptorMakeReturnsNil() {
    let device = MetalFXHostDevice()
    let descriptor = MTLFXSpatialScalerDescriptor()
    descriptor.inputWidth = 8
    descriptor.inputHeight = 8
    descriptor.outputWidth = 16
    descriptor.outputHeight = 16
    precondition(descriptor.makeSpatialScaler(device: device) == nil)
}

func testSpatialScalerDescriptorMakeMetal4ReturnsNil() {
    let device = MetalFXHostDevice()
    let compiler = MetalFXHostMTL4Compiler(device: device)
    let descriptor = MTLFXSpatialScalerDescriptor()
    precondition(descriptor.makeSpatialScaler(device: device, compiler: compiler) == nil)
}
