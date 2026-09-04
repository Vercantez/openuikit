import Foundation

private let imageioTypeIDSource: CFTypeID = 0x4949_5301
private let imageioAllowableLock = NSLock()
private var imageioAllowableTypes: Set<String>?

func imageioTypeAllowed(_ type: CFString) -> Bool {
    imageioAllowableLock.lock()
    defer { imageioAllowableLock.unlock() }
    guard let allowed = imageioAllowableTypes else { return true }
    return allowed.contains(type)
}

public func CGImageSourceGetTypeID() -> CFTypeID {
    imageioTypeIDSource
}

public func CGImageSourceCopyTypeIdentifiers() -> CFArray {
    imageioSupportedSourceTypes()
}

public func CGImageSourceGetPrimaryImageIndex(_ isrc: CGImageSource) -> Int {
    0
}

public func CGImageSourceCreateWithURL(
    _ url: CFURL,
    _ options: CFDictionary?
) -> CGImageSource? {
    guard let data = try? Data(contentsOf: url) else { return nil }
    return CGImageSourceCreateWithData(data, options)
}

public func CGImageSourceCreateWithDataProvider(
    _ provider: CGDataProvider,
    _ options: CFDictionary?
) -> CGImageSource? {
    CGImageSourceCreateWithData(provider.data, options)
}

public func CGImageSourceUpdateDataProvider(
    _ isrc: CGImageSource,
    _ provider: CGDataProvider,
    _ final: Bool
) {
    CGImageSourceUpdateData(isrc, provider.data, final)
}

public func CGImageSourceRemoveCacheAtIndex(_ isrc: CGImageSource, _ index: Int) {
    _ = isrc
    _ = index
}

public func CGImageSourceCopyAuxiliaryDataInfoAtIndex(
    _ isrc: CGImageSource,
    _ index: Int,
    _ auxiliaryImageDataType: CFString
) -> CFDictionary? {
    _ = isrc
    _ = index
    _ = auxiliaryImageDataType
    return nil
}

public func CGImageSourceCopyMetadataAtIndex(
    _ isrc: CGImageSource,
    _ index: Int,
    _ options: CFDictionary?
) -> CGImageMetadata? {
    _ = options
    guard index >= 0, index < CGImageSourceGetCount(isrc) else { return nil }
    return CGImageMetadata()
}

public func CGImageSourceSetAllowableTypes(_ allowableTypes: CFArray) -> OSStatus {
    let types = allowableTypes.compactMap { value -> String? in
        if let string = value as? String { return string }
        if let string = value as? NSString { return string as String }
        return nil
    }
    guard !types.isEmpty, types.count == allowableTypes.count else { return -50 }
    imageioAllowableLock.lock()
    imageioAllowableTypes = Set(types)
    imageioAllowableLock.unlock()
    return 0
}

func imageioResetAllowableTypesForTests() {
    imageioAllowableLock.lock()
    imageioAllowableTypes = nil
    imageioAllowableLock.unlock()
}
