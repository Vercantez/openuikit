import Foundation

#if canImport(Glibc)
import Glibc
#elseif canImport(Darwin)
import Darwin
#endif

#if canImport(CoreML)
import CoreML
#endif

#if canImport(CoreGraphics)
import CoreGraphics
#endif

#if canImport(CoreVideo)
import CoreVideo
#endif

#if canImport(ImageIO)
import ImageIO
#endif

/// Probe for a future clean EC2/guest run that links `libCoreML.dylib` against
/// the real Foundation module and, when present, CoreVideo / CoreGraphics.
/// The isolated host gate compiles only `CoreMLRuntime.swift` and does not
/// import those extra modules, so image and pixel-buffer APIs stay deferred
/// here instead of growing lookalike `CGImage` / `CVPixelBuffer` types.
enum CoreMLDependencyIdentity {
    static func main() {
        let data = Data([0x63, 0x6F, 0x72, 0x65, 0x6D, 0x6C])
        let url = URL(fileURLWithPath: "/tmp/missing.mlmodelc")
        let number = NSNumber(value: 2.5)
        let coder = NSCoder()
        precondition(data.count == 6)
        precondition(url.isFileURL)
        precondition(number.doubleValue == 2.5)
        _ = coder

        #if canImport(CoreML)
        precondition(MLModelErrorDomain == "com.apple.CoreML")
        precondition(MLModelConfiguration().computeUnits == .all)
        precondition(MLPredictionOptions().usesCPUOnly == false)
        _ = try? MLModelAsset(url: url)
        _ = try? MLModelAsset(specification: data)
        #endif

        #if canImport(CoreVideo)
        var pixelBuffer: CVPixelBuffer?
        let status = CVPixelBufferCreate(
            kCFAllocatorDefault,
            2,
            2,
            kCVPixelFormatType_32BGRA,
            nil,
            &pixelBuffer
        )
        if status == kCVReturnSuccess, let pixelBuffer {
            _ = pixelBuffer
        }
        #endif

        #if canImport(CoreGraphics)
        let space = CGColorSpaceCreateDeviceRGB()
        var rgba = [UInt8](repeating: 0, count: 16)
        let image = rgba.withUnsafeMutableBytes { raw -> CGImage? in
            guard let base = raw.baseAddress else { return nil }
            let context = CGContext(
                data: base,
                width: 2,
                height: 2,
                bitsPerComponent: 8,
                bytesPerRow: 8,
                space: space,
                bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
            )
            return context?.makeImage()
        }
        _ = image
        #endif

        loadLibCoreML()
        print("COREML_DEPENDENCY_IDENTITY_OK")
    }

    static func loadLibCoreML() {
        let names = [
            "libCoreML.dylib",
            "./libCoreML.dylib",
            "build/libCoreML.dylib"
        ]
        var handle: UnsafeMutableRawPointer?
        for name in names {
            handle = dlopen(name, RTLD_NOW)
            if handle != nil {
                break
            }
        }
        guard let handle else {
            fatalError("libCoreML.dylib must be loadable on the guest/EC2 run")
        }
        defer { dlclose(handle) }
        #if canImport(CoreML)
        let symbol = dlsym(handle, "MLModelErrorDomain")
        _ = symbol
        #endif
    }
}
