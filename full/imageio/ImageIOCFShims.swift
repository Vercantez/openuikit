import Foundation

// Isolated Linux host has no CoreFoundation overlay and no CoreGraphics
// module. These spellings match the imported ImageIO C surface. They are
// host lookalikes, not a second Foundation or CoreGraphics identity. The
// later EC2 integration build uses real CF / CG types from the platform
// sysroot via tests/agent/ImageIODependencyIdentity.swift.

public typealias CFString = String
public typealias CFDictionary = [String: Any]
public typealias CFArray = [Any]
public typealias CFTypeRef = Any
public typealias CFData = Data
public typealias CFURL = URL
public typealias CFError = NSError
public typealias CFTypeID = UInt
public typealias CFMutableData = NSMutableData
public typealias OSStatus = Int32

#if canImport(CoreGraphics)
@_exported import CoreGraphics
#else
/// Linux host lookalike for CoreGraphics' RGBA8 bitmap. Not CoreGraphics identity.
public final class CGImage: @unchecked Sendable {
    public let width: Int
    public let height: Int
    public var pixels: [UInt8]

    public init(width: Int, height: Int) {
        self.width = width
        self.height = height
        let count = width > 0 && height > 0 ? width * height * 4 : 0
        self.pixels = [UInt8](repeating: 0, count: count)
    }
}

/// Linux host lookalike for CoreGraphics' data provider. Not CoreGraphics identity.
public final class CGDataProvider: @unchecked Sendable {
    public let data: Data

    public init(data: Data) {
        self.data = data
    }
}

/// Linux host lookalike for CoreGraphics' data consumer. Not CoreGraphics identity.
public final class CGDataConsumer: @unchecked Sendable {
    private let append: (Data) -> Bool
    private let lock = NSLock()
    public private(set) var bytes = Data()

    public init(append: @escaping (Data) -> Bool = { _ in true }) {
        self.append = append
    }

    func receive(_ data: Data) -> Bool {
        lock.lock()
        defer { lock.unlock() }
        bytes.append(data)
        return append(data)
    }
}
#endif

func imageioCFError(code: Int, message: String) -> CFError {
    NSError(
        domain: kCFErrorDomainCGImageMetadata as String,
        code: code,
        userInfo: [NSLocalizedDescriptionKey: message]
    )
}

func imageioWriteError(
    _ err: UnsafeMutablePointer<Unmanaged<CFError>?>?,
    code: Int,
    message: String
) {
    guard let err else { return }
    err.pointee = Unmanaged.passRetained(imageioCFError(code: code, message: message))
}

@inline(__always)
func imageioMakeImage(width: Int, height: Int, pixels: UnsafePointer<UInt8>) -> CGImage? {
    guard width > 0, height > 0,
          width <= Int.max / 4,
          height <= Int.max / (width * 4) else { return nil }
    let byteCount = width * height * 4
    let image = CGImage(width: width, height: height)
    image.pixels.withUnsafeMutableBufferPointer { destination in
        destination.baseAddress?.update(from: pixels, count: byteCount)
    }
    return image
}

@inline(__always)
func imageioMakeImage(width: Int, height: Int, pixels: [UInt8]) -> CGImage? {
    guard pixels.count == width * height * 4 else { return nil }
    return pixels.withUnsafeBufferPointer { buffer in
        guard let base = buffer.baseAddress else { return nil }
        return imageioMakeImage(width: width, height: height, pixels: base)
    }
}
