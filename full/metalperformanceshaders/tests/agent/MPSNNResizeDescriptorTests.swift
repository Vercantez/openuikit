import Foundation
import MetalPerformanceShaders

private func resizeSentinel(_ byte: UInt8) -> MPSImage {
    let image = MPSImage(device: MPSHostDevice.shared,
        imageDescriptor: MPSImageDescriptor(channelFormat: .unorm8, width: 1, height: 1, featureChannels: 1))
    var value = byte
    withUnsafePointer(to: &value) {
        image.writeBytes($0, dataLayout: .HeightxWidthxFeatureChannels, imageIndex: 0)
    }
    return image
}

private func assertResizeRefused(_ kernel: MPSCNNKernel) {
    let source = resizeSentinel(12)
    let destination = resizeSentinel(173)
    MPSHostBoundary.reset()
    kernel.encode(commandBuffer: MPSHostDevice.shared.makeCommandBuffer(), sourceImage: source, destinationImage: destination)
    precondition(MPSHostBoundary.lastRefusedAPI != nil)
    var value: UInt8 = 0
    withUnsafeMutablePointer(to: &value) {
        destination.readBytes($0, dataLayout: .HeightxWidthxFeatureChannels, imageIndex: 0)
    }
    precondition(value == 173)
}

func testMPSNNResizeBilinearConfiguration() {
    let device = MPSHostDevice.shared
    for alignCorners in [true, false] {
        let kernel = MPSNNResizeBilinear(device: device, resizeWidth: 7, resizeHeight: 3, alignCorners: alignCorners)
        kernel.label = "resize-config"
        kernel.options = .skipAPIValidation
        let copied = kernel.copy(with: nil, device: nil)
        precondition(copied !== kernel && copied.device === device)
        precondition(copied.resizeWidth == 7 && copied.resizeHeight == 3 && copied.alignCorners == alignCorners)
        precondition(copied.label == "resize-config" && copied.options == .skipAPIValidation)
        precondition(kernel.resizeWidth == 7 && kernel.resizeHeight == 3 && kernel.alignCorners == alignCorners)
        assertResizeRefused(kernel)
        assertResizeRefused(copied)
    }
    precondition(MPSNNResizeBilinear(coder: NSCoder(), device: device) == nil)
}

func testMPSNNCropAndResizeOwnedRegions() {
    let device = MPSHostDevice.shared
    let first = MPSRegion(origin: MPSOrigin(x: 0.25, y: -0.5, z: 0), size: MPSSize(width: 0.5, height: 1.5, depth: 1))
    let second = MPSRegion(origin: MPSOrigin(x: 0.5, y: 0.125, z: 1), size: MPSSize(width: 0.25, height: 0.75, depth: 1))
    var kernel: MPSNNCropAndResizeBilinear?
    do {
        var input = [first, second]
        kernel = input.withUnsafeBufferPointer {
            MPSNNCropAndResizeBilinear(device: device, resizeWidth: 5, resizeHeight: 2,
                                     numberOfRegions: $0.count, regions: $0.baseAddress!)
        }
        input[0] = second
        precondition(kernel!.regions[0] == first) // Input storage is copied, not borrowed.
    }
    precondition(kernel!.resizeWidth == 5 && kernel!.resizeHeight == 2 && kernel!.numberOfRegions == 2)
    precondition(kernel!.regions[0] == first && kernel!.regions[1] == second)
    kernel!.label = "owned-regions"
    let copied = kernel!.copy(with: nil, device: nil)
    precondition(copied.regions != kernel!.regions)
    assertResizeRefused(kernel!)
    kernel = nil
    precondition(copied.resizeWidth == 5 && copied.resizeHeight == 2 && copied.numberOfRegions == 2)
    precondition(copied.regions[0] == first && copied.regions[1] == second && copied.label == "owned-regions")
    assertResizeRefused(copied)
    precondition(MPSNNCropAndResizeBilinear(coder: NSCoder(), device: device) == nil)
}
