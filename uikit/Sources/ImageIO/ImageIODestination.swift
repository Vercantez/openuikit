import Foundation
import OpenCoreGraphics
#if canImport(CoreGraphics)
import CoreGraphics
#endif

private let imageioTypeIDDestination: CFTypeID = 0x4949_4401

public final class CGImageDestination: @unchecked Sendable {
    enum Target {
        case data(NSMutableData)
        case url(URL)
#if !canImport(CoreGraphics)
        case consumer(CGDataConsumer)
#endif
    }

    let type: CFString
    let count: Int
    let target: Target
    var properties: CFDictionary?
    var frames: [(image: CGImage, properties: CFDictionary?)] = []
    var finalized = false

    init(type: CFString, count: Int, target: Target) {
        self.type = type
        self.count = count
        self.target = target
    }
}

public func CGImageDestinationGetTypeID() -> CFTypeID { imageioTypeIDDestination }

public func CGImageDestinationCopyTypeIdentifiers() -> CFArray {
    [kUTTypePNG, kUTTypeJPEG] as CFArray
}

public func CGImageDestinationCreateWithData(
    _ data: CFMutableData,
    _ type: CFString,
    _ count: Int,
    _ options: CFDictionary?
) -> CGImageDestination? {
    _ = options
    guard count > 0, imageioSupportsDestination(type) else { return nil }
    return CGImageDestination(type: type, count: count, target: .data(data as NSMutableData))
}

public func CGImageDestinationCreateWithURL(
    _ url: CFURL,
    _ type: CFString,
    _ count: Int,
    _ options: CFDictionary?
) -> CGImageDestination? {
    _ = options
    guard count > 0, imageioSupportsDestination(type) else { return nil }
    return CGImageDestination(type: type, count: count, target: .url(url as URL))
}

public func CGImageDestinationCreateWithDataConsumer(
    _ consumer: CGDataConsumer,
    _ type: CFString,
    _ count: Int,
    _ options: CFDictionary?
) -> CGImageDestination? {
    _ = options
    guard count > 0, imageioSupportsDestination(type) else { return nil }
#if canImport(CoreGraphics)
    // Darwin CoreGraphics.CGDataConsumer has no public Swift put-bytes.
    // Linux lookalike CGDataConsumer.receive is the measured write path.
    _ = consumer
    return nil
#else
    return CGImageDestination(type: type, count: count, target: .consumer(consumer))
#endif
}

public func CGImageDestinationSetProperties(
    _ dest: CGImageDestination,
    _ properties: CFDictionary?
) {
    dest.properties = properties
}

public func CGImageDestinationAddImage(
    _ dest: CGImageDestination,
    _ image: CGImage,
    _ properties: CFDictionary?
) {
    guard !dest.finalized, dest.frames.count < dest.count else { return }
    dest.frames.append((image, properties))
}

public func CGImageDestinationAddImageFromSource(
    _ dest: CGImageDestination,
    _ source: CGImageSource,
    _ index: Int,
    _ properties: CFDictionary?
) {
    guard let image = CGImageSourceCreateImageAtIndex(
        source,
        index,
        Optional<CFDictionary>.none
    ) else { return }
    CGImageDestinationAddImage(dest, image, properties)
}

@discardableResult
public func CGImageDestinationFinalize(_ dest: CGImageDestination) -> Bool {
    guard !dest.finalized, dest.frames.count == dest.count, let first = dest.frames.first else {
        return false
    }
    guard let bitmap = imageioBitmap(from: first.image) else { return false }
    let encoded: [UInt8]?
    if typeEquals(dest.type, kUTTypeJPEG) {
        let quality = imageioJPEGQuality(first.properties)
            ?? imageioJPEGQuality(dest.properties)
            ?? 0.9
        encoded = imageioEncodeJPEG(bitmap, quality: quality)
    } else {
        encoded = imageioEncodePNG(bitmap)
    }
    guard let encoded else { return false }
    dest.finalized = true
    let payload = Data(encoded)
    switch dest.target {
    case .data(let data):
        data.append(payload)
        return true
    case .url(let url):
        do {
            try payload.write(to: url)
            return true
        } catch {
            dest.finalized = false
            return false
        }
#if !canImport(CoreGraphics)
    case .consumer(let consumer):
        consumer.receive(payload)
        return true
#endif
    }
}

private func imageioSupportsDestination(_ type: CFString) -> Bool {
    typeEquals(type, kUTTypePNG) || typeEquals(type, kUTTypeJPEG)
}

private func imageioJPEGQuality(_ properties: CFDictionary?) -> CGFloat? {
    guard let properties else { return nil }
    let ns = properties as NSDictionary
    if let number = ns[kCGImageDestinationLossyCompressionQuality] as? NSNumber {
        return CGFloat(truncating: number)
    }
    return nil
}
