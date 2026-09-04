import Foundation

private let imageioTypeIDDestination: CFTypeID = 0x4949_4401

public final class CGImageDestination: @unchecked Sendable {
    enum Target {
        case data(NSMutableData)
        case url(URL)
        case consumer(CGDataConsumer)
    }

    let type: CFString
    let count: Int
    let target: Target
    var properties: CFDictionary = [:]
    var frames: [(image: CGImage, properties: CFDictionary?, metadata: CGImageMetadata?)] = []
    var copiedSource: CGImageSource?
    var auxiliary: [(CFString, CFDictionary)] = []
    var finalized = false

    init(type: CFString, count: Int, target: Target) {
        self.type = type
        self.count = count
        self.target = target
    }

    public static func == (left: CGImageDestination, right: CGImageDestination) -> Bool {
        left === right
    }

    public static func != (left: CGImageDestination, right: CGImageDestination) -> Bool {
        left !== right
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(ObjectIdentifier(self))
    }

    public var hashValue: Int {
        ObjectIdentifier(self).hashValue
    }
}

public func CGImageDestinationGetTypeID() -> CFTypeID {
    imageioTypeIDDestination
}

public func CGImageDestinationCopyTypeIdentifiers() -> CFArray {
    imageioSupportedDestinationTypes()
}

public func CGImageDestinationCreateWithData(
    _ data: CFMutableData,
    _ type: CFString,
    _ count: Int,
    _ options: CFDictionary?
) -> CGImageDestination? {
    _ = options
    guard count > 0, imageioSupportedDestinationTypes().contains(type) else { return nil }
    return CGImageDestination(type: type, count: count, target: .data(data))
}

public func CGImageDestinationCreateWithURL(
    _ url: CFURL,
    _ type: CFString,
    _ count: Int,
    _ options: CFDictionary?
) -> CGImageDestination? {
    _ = options
    guard count > 0, imageioSupportedDestinationTypes().contains(type) else { return nil }
    return CGImageDestination(type: type, count: count, target: .url(url))
}

public func CGImageDestinationCreateWithDataConsumer(
    _ consumer: CGDataConsumer,
    _ type: CFString,
    _ count: Int,
    _ options: CFDictionary?
) -> CGImageDestination? {
    _ = options
    guard count > 0, imageioSupportedDestinationTypes().contains(type) else { return nil }
    return CGImageDestination(type: type, count: count, target: .consumer(consumer))
}

public func CGImageDestinationSetProperties(
    _ idst: CGImageDestination,
    _ properties: CFDictionary?
) {
    idst.properties = properties ?? [:]
}

public func CGImageDestinationAddImage(
    _ idst: CGImageDestination,
    _ image: CGImage,
    _ properties: CFDictionary?
) {
    guard !idst.finalized else { return }
    idst.frames.append((image, properties, nil))
}

public func CGImageDestinationAddImageAndMetadata(
    _ idst: CGImageDestination,
    _ image: CGImage,
    _ metadata: CGImageMetadata?,
    _ options: CFDictionary?
) {
    guard !idst.finalized else { return }
    idst.frames.append((image, options, metadata))
}

public func CGImageDestinationAddImageFromSource(
    _ idst: CGImageDestination,
    _ isrc: CGImageSource,
    _ index: Int,
    _ properties: CFDictionary?
) {
    guard let image = CGImageSourceCreateImageAtIndex(isrc, index, properties) else { return }
    CGImageDestinationAddImage(idst, image, properties)
}

public func CGImageDestinationAddAuxiliaryDataInfo(
    _ idst: CGImageDestination,
    _ auxiliaryImageDataType: CFString,
    _ auxiliaryDataInfoDictionary: CFDictionary
) {
    guard !idst.finalized else { return }
    idst.auxiliary.append((auxiliaryImageDataType, auxiliaryDataInfoDictionary))
}

public func CGImageDestinationCopyImageSource(
    _ idst: CGImageDestination,
    _ isrc: CGImageSource,
    _ options: CFDictionary?,
    _ err: UnsafeMutablePointer<Unmanaged<CFError>?>?
) -> Bool {
    _ = options
    guard !idst.finalized else {
        imageioWriteError(err, code: Int(CGImageMetadataErrors.badArgument.rawValue),
                          message: "destination already finalized")
        return false
    }
    guard !isrc.data.isEmpty else {
        imageioWriteError(err, code: Int(CGImageMetadataErrors.badArgument.rawValue),
                          message: "source has no data")
        return false
    }
    idst.copiedSource = isrc
    return true
}

public func CGImageDestinationFinalize(_ idst: CGImageDestination) -> Bool {
    guard !idst.finalized else { return false }
    let encoded: Data
    if let source = idst.copiedSource {
        encoded = source.data
    } else {
        guard idst.frames.count == idst.count, let first = idst.frames.first else {
            return false
        }
        guard let bytes = imageioEncode(first.image, type: idst.type) else { return false }
        encoded = bytes
    }
    switch idst.target {
    case .data(let data):
        encoded.withUnsafeBytes { raw in
            if let base = raw.baseAddress {
                data.append(base, length: encoded.count)
            }
        }
    case .url(let url):
        do {
            try encoded.write(to: url, options: .atomic)
        } catch {
            return false
        }
    case .consumer(let consumer):
        guard consumer.receive(encoded) else { return false }
    }
    idst.finalized = true
    return true
}
