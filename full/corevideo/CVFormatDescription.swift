import Foundation

let _cvFormatRegistryLock = NSLock()
var _cvRegisteredFormatDescriptions: [OSType: NSDictionary] = [:]

func _cvSeedFormat(_ pixelFormat: OSType, name: String, extra: [CFString: Any] = [:]) {
    if _cvRegisteredFormatDescriptions[pixelFormat] != nil { return }
    let dict = NSMutableDictionary()
    dict[kCVPixelFormatName] = _cvCFString(name)
    dict[kCVPixelFormatConstant] = _cvNumber(pixelFormat)
    dict[kCVPixelFormatFourCC] = _cvNumber(pixelFormat)
    for (key, value) in extra {
        dict[key] = value
    }
    _cvRegisteredFormatDescriptions[pixelFormat] = dict
}

func _cvEnsureDefaultFormats() {
    _cvFormatRegistryLock.lock()
    defer { _cvFormatRegistryLock.unlock() }
    if !_cvRegisteredFormatDescriptions.isEmpty { return }
    _cvSeedFormat(
        kCVPixelFormatType_32BGRA,
        name: "32-bit BGRA",
        extra: [
            kCVPixelFormatContainsRGB: _cvNumber(true),
            kCVPixelFormatContainsAlpha: _cvNumber(true),
            kCVPixelFormatBitsPerBlock: _cvNumber(32),
            kCVPixelFormatBlockWidth: _cvNumber(1),
            kCVPixelFormatBlockHeight: _cvNumber(1),
        ]
    )
    _cvSeedFormat(
        kCVPixelFormatType_32ARGB,
        name: "32-bit ARGB",
        extra: [
            kCVPixelFormatContainsRGB: _cvNumber(true),
            kCVPixelFormatContainsAlpha: _cvNumber(true),
            kCVPixelFormatBitsPerBlock: _cvNumber(32),
        ]
    )
    _cvSeedFormat(
        kCVPixelFormatType_32RGBA,
        name: "32-bit RGBA",
        extra: [
            kCVPixelFormatContainsRGB: _cvNumber(true),
            kCVPixelFormatContainsAlpha: _cvNumber(true),
            kCVPixelFormatBitsPerBlock: _cvNumber(32),
        ]
    )
    _cvSeedFormat(
        kCVPixelFormatType_420YpCbCr8BiPlanarVideoRange,
        name: "420v",
        extra: [
            kCVPixelFormatContainsYCbCr: _cvNumber(true),
            kCVPixelFormatComponentRange: kCVPixelFormatComponentRange_VideoRange,
        ]
    )
    _cvSeedFormat(
        kCVPixelFormatType_420YpCbCr8BiPlanarFullRange,
        name: "420f",
        extra: [
            kCVPixelFormatContainsYCbCr: _cvNumber(true),
            kCVPixelFormatComponentRange: kCVPixelFormatComponentRange_FullRange,
        ]
    )
    _cvSeedFormat(
        kCVPixelFormatType_OneComponent8,
        name: "OneComponent8",
        extra: [kCVPixelFormatContainsGrayscale: _cvNumber(true)]
    )
}

public func CVPixelFormatDescriptionCreateWithPixelFormatType(
    _ allocator: CFAllocator?,
    _ pixelFormat: OSType
) -> CFDictionary? {
    _ = allocator
    _cvEnsureDefaultFormats()
    _cvFormatRegistryLock.lock()
    defer { _cvFormatRegistryLock.unlock() }
    return _cvRegisteredFormatDescriptions[pixelFormat]
}

public func CVPixelFormatDescriptionArrayCreateWithAllPixelFormatTypes(
    _ allocator: CFAllocator?
) -> CFArray? {
    _ = allocator
    _cvEnsureDefaultFormats()
    _cvFormatRegistryLock.lock()
    defer { _cvFormatRegistryLock.unlock() }
    let values = _cvRegisteredFormatDescriptions.keys.sorted().map { _cvNumber($0) }
    return values as NSArray
}

public func CVPixelFormatDescriptionRegisterDescriptionWithPixelFormatType(
    _ description: CFDictionary,
    _ pixelFormat: OSType
) {
    _cvEnsureDefaultFormats()
    _cvFormatRegistryLock.lock()
    defer { _cvFormatRegistryLock.unlock() }
    _cvRegisteredFormatDescriptions[pixelFormat] = description as NSDictionary
}

public struct CVPixelFormatDescription: Equatable {
    public var pixelFormatType: CVPixelFormatType
    public var name: String
    public var components: Components
    public var componentRange: ComponentRange?
    public var planeConfiguration: PlaneConfiguration

    public init(
        pixelFormatType: CVPixelFormatType,
        name: String,
        components: Components,
        componentRange: ComponentRange? = nil,
        planeConfiguration: PlaneConfiguration
    ) {
        self.pixelFormatType = pixelFormatType
        self.name = name
        self.components = components
        self.componentRange = componentRange
        self.planeConfiguration = planeConfiguration
    }

    public struct Components: OptionSet, Sendable, Hashable {
        public let rawValue: Int
        public init(rawValue: Int) { self.rawValue = rawValue }
        public static let rgb = Components(rawValue: 1 << 0)
        public static let alpha = Components(rawValue: 1 << 1)
        public static let yCbCr = Components(rawValue: 1 << 2)
        public static let grayscale = Components(rawValue: 1 << 3)
        public static let senselArray = Components(rawValue: 1 << 4)
    }

    public struct Dimensions: Hashable, Sendable {
        public var horizontal: Int
        public var vertical: Int
        public init(horizontal: Int, vertical: Int) {
            self.horizontal = horizontal
            self.vertical = vertical
        }
    }

    public struct PixelLayout: Equatable {
        public var blockSize: CVImageSize
        public var bitsPerBlock: Int
        public var bitsPerComponent: Int?
        public var blockAlignment: Dimensions
        public var subsampling: Dimensions
        public var blackBlock: Data?
        public var fillExtendedPixels: ((inout CVMutablePixelBuffer) -> Void)?
        public var cgBitmapInfo: CGBitmapInfo?

        public init(
            blockSize: CVImageSize = .init(width: 1, height: 1),
            bitsPerBlock: Int,
            bitsPerComponent: Int? = nil,
            blockAlignment: Dimensions = .init(horizontal: 1, vertical: 1),
            subsampling: Dimensions = .init(horizontal: 1, vertical: 1),
            blackBlock: Data? = nil,
            fillExtendedPixels: ((inout CVMutablePixelBuffer) -> Void)? = nil,
            cgBitmapInfo: CGBitmapInfo? = nil
        ) {
            self.blockSize = blockSize
            self.bitsPerBlock = bitsPerBlock
            self.bitsPerComponent = bitsPerComponent
            self.blockAlignment = blockAlignment
            self.subsampling = subsampling
            self.blackBlock = blackBlock
            self.fillExtendedPixels = fillExtendedPixels
            self.cgBitmapInfo = cgBitmapInfo
        }

        public static func == (lhs: PixelLayout, rhs: PixelLayout) -> Bool {
            lhs.blockSize == rhs.blockSize
                && lhs.bitsPerBlock == rhs.bitsPerBlock
                && lhs.bitsPerComponent == rhs.bitsPerComponent
                && lhs.blockAlignment == rhs.blockAlignment
                && lhs.subsampling == rhs.subsampling
                && lhs.blackBlock == rhs.blackBlock
                && lhs.cgBitmapInfo == rhs.cgBitmapInfo
                && (lhs.fillExtendedPixels == nil) == (rhs.fillExtendedPixels == nil)
        }
    }

    public struct Compatibility: OptionSet, Sendable, Hashable {
        public let rawValue: Int
        public init(rawValue: Int) { self.rawValue = rawValue }
        public static let cgImage = Compatibility(rawValue: 1 << 0)
        public static let cgBitmapContext = Compatibility(rawValue: 1 << 1)
        public static let metalTexture = Compatibility(rawValue: 1 << 2)
        public static let ioSurfaceCoreAnimation = Compatibility(rawValue: 1 << 3)
    }

    public enum ComponentRange: Sendable, Hashable {
        case full
        case video
        case wide
    }

    public enum PlaneConfiguration: Equatable {
        case nonPlanar(PixelLayout)
        case planar([PixelLayout])
    }

    public final class Registry: @unchecked Sendable {
        public static let shared = Registry()
        private let lock = NSLock()
        private var storage: [OSType: CVPixelFormatDescription] = [:]

        public var formatDescriptions: [CVPixelFormatDescription] {
            lock.lock()
            defer { lock.unlock() }
            return Array(storage.values)
        }

        public func register(_ formatDescription: CVPixelFormatDescription) {
            lock.lock()
            storage[formatDescription.pixelFormatType.rawValue] = formatDescription
            lock.unlock()
            let dict = NSMutableDictionary()
            dict[kCVPixelFormatName] = _cvCFString(formatDescription.name)
            dict[kCVPixelFormatConstant] = _cvNumber(formatDescription.pixelFormatType.rawValue)
            CVPixelFormatDescriptionRegisterDescriptionWithPixelFormatType(
                dict,
                formatDescription.pixelFormatType.rawValue
            )
        }

        public subscript(pixelFormatType: CVPixelFormatType) -> CVPixelFormatDescription? {
            lock.lock()
            defer { lock.unlock() }
            return storage[pixelFormatType.rawValue]
        }
    }
}
