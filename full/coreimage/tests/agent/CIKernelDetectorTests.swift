import CoreImage
import Foundation

func testCIKernelFailClosedNoMetal() {
    let callback: CIKernelROICallback = { _, r in r }
    let color = CIImage(color: .red).cropped(to: CGRect(x: 0, y: 0, width: 2, height: 2))
    precondition(CIKernel(source: "kernel vec4 foo() { return vec4(1.0); }") == nil)
    precondition(CIColorKernel(source: "kernel vec4 f() { return vec4(1.0); }") == nil)
    let colorKernel = CIColorKernel()
    precondition(colorKernel.apply(extent: .zero, arguments: []) == nil)
    precondition(CIWarpKernel(source: "kernel") == nil)
    let warp = CIWarpKernel()
    precondition(warp.apply(extent: .zero, roiCallback: callback, image: color, arguments: []) == nil)
    precondition(CIBlendKernel(source: "kernel") == nil)
    precondition(CIKernel.kernelNames(fromMetalLibraryData: Data()).isEmpty)
    do {
        _ = try CIKernel(functionName: "f", fromMetalLibraryData: Data())
        preconditionFailure("metal")
    } catch {
        precondition((error as? CIRenderError) == .unsupported)
    }
    do {
        _ = try CIKernel(functionName: "f", fromMetalLibraryData: Data(), outputPixelFormat: .RGBA8)
        preconditionFailure("metal2")
    } catch {
        precondition((error as? CIRenderError) == .unsupported)
    }
    do {
        _ = try CIKernel.kernels(withMetalString: "kernel")
        preconditionFailure("metal3")
    } catch {
        precondition((error as? CIRenderError) == .unsupported)
    }
    precondition(CIKernel.makeKernels(source: "kernel") == nil)
    precondition(CIKernel(string: "kernel") == nil)
    let kernel = CIKernel()
    precondition(kernel.apply(extent: .zero, roiCallback: callback, arguments: []) == nil)
    _ = CIBlendKernel.sourceOver.apply(foreground: color, background: color, colorSpace: .sRGB)

    precondition(CIImageProcessorKernel.outputFormat == .RGBA8)
    precondition(CIImageProcessorKernel.outputIsOpaque == false)
    precondition(CIImageProcessorKernel.synchronizeInputs)
    do {
        _ = try CIImageProcessorKernel.apply(withExtent: color.extent, inputs: [color], arguments: nil)
        preconditionFailure("proc")
    } catch {
        precondition((error as? CIRenderError) == .unsupported)
    }
}

func testCIDetectorFailClosedNoML() {
    let context = CIContext()
    let image = CIImage(color: .white).cropped(to: CGRect(x: 0, y: 0, width: 8, height: 8))
    guard let face = CIDetector(ofType: CIDetectorTypeFace, context: context, options: [
        CIDetectorAccuracy: CIDetectorAccuracyHigh,
    ]) else {
        preconditionFailure("face detector type is constructible")
    }
    precondition(face.features(in: image).isEmpty)
    guard let qr = CIDetector(ofType: CIDetectorTypeQRCode, context: context, options: nil) else {
        preconditionFailure("qr detector type is constructible")
    }
    precondition(qr.features(in: image, options: nil).isEmpty)
    precondition(CIDetector(ofType: "not-a-detector", context: nil) == nil)

    let faceFeat = CIFaceFeature(bounds: CGRect(x: 1, y: 2, width: 3, height: 4))
    precondition(faceFeat.type == CIFeatureTypeFace)
    precondition(!faceFeat.hasSmile)
    precondition(!faceFeat.hasLeftEyePosition)
    precondition(faceFeat.leftEyePosition == .zero)
}

func testCIColorAndVectorValueSemantics() {
    let a = CIColor(red: 0.2, green: 0.4, blue: 0.6, alpha: 0.8)
    let b = CIColor(string: a.stringRepresentation)
    precondition(a.isEqual(b))
    precondition(a.hash == b.hash)
    precondition(!a.isEqual(CIColor.red))
    precondition(CIColor.gray.red == 0.5)
    let parsed = CIColor(string: "1 0 0 1")
    precondition(parsed.red == 1 && parsed.alpha == 1)

    let v = CIVector(x: 1, y: 2, z: 3, w: 4)
    let w = CIVector(string: v.stringRepresentation)
    precondition(v.isEqual(w))
    precondition(v.hash == w.hash)
    precondition(v.cgRectValue.width == 3)
    let t = CIVector(cgAffineTransform: .identity)
    precondition(t.cgAffineTransformValue.a == 1)
    precondition(!v.isEqual(CIVector(x: 0)))
}
