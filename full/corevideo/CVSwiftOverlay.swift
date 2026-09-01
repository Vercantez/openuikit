import Foundation

public struct CVImageSize: Hashable, Sendable {
    public var width: Int
    public var height: Int

    public init(width: Int, height: Int) {
        self.width = width
        self.height = height
    }

    public init(_ size: CGSize, rounded rule: FloatingPointRoundingRule = .down) {
        self.width = Int(size.width.rounded(rule))
        self.height = Int(size.height.rounded(rule))
    }

    public static let zero = CVImageSize(width: 0, height: 0)
}

extension CGSize {
    public init(_ size: CVImageSize) {
        self.init(width: CGFloat(size.width), height: CGFloat(size.height))
    }
}

public struct CVPixelFormatType: RawRepresentable, Hashable, Sendable {
    public typealias RawValue = OSType
    public var rawValue: OSType
    public init(rawValue: OSType) { self.rawValue = rawValue }
    public var isCompressionAvailable: Bool {
        CVIsCompressedPixelFormatAvailable(rawValue)
    }
}

@frozen
public struct CVPixelBufferPadding: Hashable, Sendable {
    public var left: Int
    public var right: Int
    public var top: Int
    public var bottom: Int

    public init(left: Int = 0, right: Int = 0, top: Int = 0, bottom: Int = 0) {
        self.left = left
        self.right = right
        self.top = top
        self.bottom = bottom
    }

    public static let zero = CVPixelBufferPadding()
}

@frozen
public struct CVPixelBufferPlaneProperties: Hashable, Sendable {
    public var size: CVImageSize
    public var bytesPerRow: Int
    public init(size: CVImageSize, bytesPerRow: Int) {
        self.size = size
        self.bytesPerRow = bytesPerRow
    }
}

public enum CVImageBufferOriginPosition: Sendable, Hashable {
    case topLeft
    case bottomLeft
}

public protocol CVBufferRepresentable<Buffer>: ~Copyable {
    associatedtype Buffer: CVBuffer
    func withUnsafeBuffer<R>(_ body: (Self.Buffer) throws -> sending R) rethrows -> sending R
}

public protocol CVImageBufferRepresentable: CVBufferRepresentable, ~Copyable {
    var colorSpace: CGColorSpace? { get }
    var displaySize: CGSize { get }
    var encodedSize: CGSize { get }
    var originPosition: CVImageBufferOriginPosition { get }
    var cleanRect: CGRect { get }
}

public protocol CVPixelBufferRepresentable: CVImageBufferRepresentable, ~Copyable {
    var planeCount: Int { get }
    var extendedPixels: CVPixelBufferPadding { get }
    var pixelFormatType: CVPixelFormatType { get }
    var planeProperties: [CVPixelBufferPlaneProperties] { get }
    func isCompatibleWith(_ attributes: CVPixelBufferAttributes) -> Bool
    func isCompatibleWith(_ attributes: CVPixelBufferCreationAttributes) -> Bool
    var creationAttributes: CVPixelBufferCreationAttributes { get }
    func accessUnsafeRawPlaneBytes<R>(
        _ block: ([(properties: CVPixelBufferPlaneProperties, bytes: UnsafeRawBufferPointer)]) throws
            -> sending R
    ) rethrows -> sending R
    func withUnsafeBackingIOSurfaceIfPresent<R>(
        _ block: (IOSurface) throws -> sending R
    ) rethrows -> sending R?
    var size: CVImageSize { get }
    var isPlanar: Bool { get }
}

public struct CVPixelBufferCreationAttributes: Equatable, Sendable {
    public var pixelFormatType: CVPixelFormatType
    public var size: CVImageSize
    public var compatibility: CVPixelFormatDescription.Compatibility
    public var bytesPerRowAlignment: Int?
    public var planeAlignment: Int?
    public var extendedPixels: CVPixelBufferPadding?
    public var backing: Backing

    public enum Backing: Equatable, Sendable {
        case memory
        case ioSurface
        case ioSurfaceWithProperties([String: any Sendable])

        public static func == (lhs: Backing, rhs: Backing) -> Bool {
            switch (lhs, rhs) {
            case (.memory, .memory), (.ioSurface, .ioSurface):
                return true
            case (.ioSurfaceWithProperties(let a), .ioSurfaceWithProperties(let b)):
                return a.keys.sorted() == b.keys.sorted()
            default:
                return false
            }
        }
    }

    public init(
        pixelFormatType: CVPixelFormatType,
        size: CVImageSize,
        compatibility: CVPixelFormatDescription.Compatibility = [],
        bytesPerRowAlignment: Int? = nil,
        planeAlignment: Int? = nil,
        extendedPixels: CVPixelBufferPadding? = nil,
        backing: Backing = .memory
    ) {
        self.pixelFormatType = pixelFormatType
        self.size = size
        self.compatibility = compatibility
        self.bytesPerRowAlignment = bytesPerRowAlignment
        self.planeAlignment = planeAlignment
        self.extendedPixels = extendedPixels
        self.backing = backing
    }

    public init?(_ attributes: CVPixelBufferAttributes) {
        guard let format = attributes.pixelFormatTypes?.first, let size = attributes.size else {
            return nil
        }
        self.init(
            pixelFormatType: format,
            size: size,
            compatibility: attributes.compatibility,
            bytesPerRowAlignment: attributes.bytesPerRowAlignment,
            planeAlignment: attributes.planeAlignment,
            extendedPixels: attributes.extendedPixels,
            backing: attributes.backing ?? .memory
        )
    }

    func dictionary() -> NSMutableDictionary {
        let dict = NSMutableDictionary()
        dict[kCVPixelBufferPixelFormatTypeKey] = _cvNumber(pixelFormatType.rawValue)
        dict[kCVPixelBufferWidthKey] = _cvNumber(size.width)
        dict[kCVPixelBufferHeightKey] = _cvNumber(size.height)
        if let bytesPerRowAlignment {
            dict[kCVPixelBufferBytesPerRowAlignmentKey] = _cvNumber(bytesPerRowAlignment)
        }
        if let planeAlignment {
            dict[kCVPixelBufferPlaneAlignmentKey] = _cvNumber(planeAlignment)
        }
        if let extendedPixels {
            dict[kCVPixelBufferExtendedPixelsLeftKey] = _cvNumber(extendedPixels.left)
            dict[kCVPixelBufferExtendedPixelsRightKey] = _cvNumber(extendedPixels.right)
            dict[kCVPixelBufferExtendedPixelsTopKey] = _cvNumber(extendedPixels.top)
            dict[kCVPixelBufferExtendedPixelsBottomKey] = _cvNumber(extendedPixels.bottom)
        }
        if compatibility.contains(.cgImage) {
            dict[kCVPixelBufferCGImageCompatibilityKey] = _cvNumber(true)
        }
        if compatibility.contains(.cgBitmapContext) {
            dict[kCVPixelBufferCGBitmapContextCompatibilityKey] = _cvNumber(true)
        }
        if compatibility.contains(.metalTexture) {
            dict[kCVPixelBufferMetalCompatibilityKey] = _cvNumber(true)
        }
        return dict
    }
}

@dynamicMemberLookup
public struct CVPixelBufferAttributes: Sendable {
    public var rawAttributes: [String: any Sendable]
    public var pixelFormatTypes: [CVPixelFormatType]?
    var size: CVImageSize?
    var compatibility: CVPixelFormatDescription.Compatibility = []
    var bytesPerRowAlignment: Int?
    var planeAlignment: Int?
    var extendedPixels: CVPixelBufferPadding?
    var backing: CVPixelBufferCreationAttributes.Backing?

    public init(rawAttributes: [String: any Sendable]) {
        self.rawAttributes = rawAttributes
    }

    public init(
        pixelFormatTypes: [CVPixelFormatType]? = nil,
        size: CVImageSize? = nil,
        compatibility: CVPixelFormatDescription.Compatibility = [],
        bytesPerRowAlignment: Int? = nil,
        planeAlignment: Int? = nil,
        extendedPixels: CVPixelBufferPadding? = nil
    ) {
        self.rawAttributes = [:]
        self.pixelFormatTypes = pixelFormatTypes
        self.size = size
        self.compatibility = compatibility
        self.bytesPerRowAlignment = bytesPerRowAlignment
        self.planeAlignment = planeAlignment
        self.extendedPixels = extendedPixels
    }

    public init?(merging values: [CVPixelBufferAttributes]) {
        guard !values.isEmpty else { return nil }
        var merged = values[0]
        for item in values.dropFirst() {
            if let types = item.pixelFormatTypes { merged.pixelFormatTypes = types }
            if let size = item.size { merged.size = size }
            merged.compatibility.formUnion(item.compatibility)
            if let value = item.bytesPerRowAlignment { merged.bytesPerRowAlignment = value }
            if let value = item.planeAlignment { merged.planeAlignment = value }
            if let value = item.extendedPixels { merged.extendedPixels = value }
        }
        self = merged
    }

    public init(_ attributes: CVPixelBufferCreationAttributes) {
        self.init(
            pixelFormatTypes: [attributes.pixelFormatType],
            size: attributes.size,
            compatibility: attributes.compatibility,
            bytesPerRowAlignment: attributes.bytesPerRowAlignment,
            planeAlignment: attributes.planeAlignment,
            extendedPixels: attributes.extendedPixels
        )
        self.backing = attributes.backing
    }

    public subscript(dynamicMember keyPath: WritableKeyPath<CVPixelBufferCreationAttributes, CVPixelFormatType>)
        -> CVPixelFormatType?
    {
        get {
            if keyPath == \CVPixelBufferCreationAttributes.pixelFormatType {
                return pixelFormatTypes?.first
            }
            return nil
        }
        set {
            if keyPath == \CVPixelBufferCreationAttributes.pixelFormatType {
                pixelFormatTypes = newValue.map { [$0] }
            }
        }
    }

    public subscript(dynamicMember keyPath: WritableKeyPath<CVPixelBufferCreationAttributes, CVImageSize>)
        -> CVImageSize?
    {
        get {
            if keyPath == \CVPixelBufferCreationAttributes.size { return size }
            return nil
        }
        set {
            if keyPath == \CVPixelBufferCreationAttributes.size { size = newValue }
        }
    }

    public subscript(
        dynamicMember keyPath: WritableKeyPath<
            CVPixelBufferCreationAttributes, CVPixelFormatDescription.Compatibility
        >
    ) -> CVPixelFormatDescription.Compatibility {
        get {
            if keyPath == \CVPixelBufferCreationAttributes.compatibility { return compatibility }
            return []
        }
        set {
            if keyPath == \CVPixelBufferCreationAttributes.compatibility { compatibility = newValue }
        }
    }

    public subscript(
        dynamicMember keyPath: WritableKeyPath<CVPixelBufferCreationAttributes, CVPixelFormatDescription?>
    ) -> CVPixelFormatDescription? {
        get { nil }
        set { _ = (keyPath, newValue) }
    }

    public subscript(
        dynamicMember keyPath: WritableKeyPath<CVPixelBufferCreationAttributes, CVPixelBufferPadding?>
    ) -> CVPixelBufferPadding? {
        get {
            if keyPath == \CVPixelBufferCreationAttributes.extendedPixels { return extendedPixels }
            return nil
        }
        set {
            if keyPath == \CVPixelBufferCreationAttributes.extendedPixels { extendedPixels = newValue }
        }
    }

    public subscript(
        dynamicMember keyPath: WritableKeyPath<
            CVPixelBufferCreationAttributes, CVPixelBufferCreationAttributes.Backing
        >
    ) -> CVPixelBufferCreationAttributes.Backing {
        get {
            if keyPath == \CVPixelBufferCreationAttributes.backing { return backing ?? .memory }
            return .memory
        }
        set {
            if keyPath == \CVPixelBufferCreationAttributes.backing { backing = newValue }
        }
    }

    public subscript(dynamicMember keyPath: WritableKeyPath<CVPixelBufferCreationAttributes, Bool>)
        -> Bool?
    {
        get { nil }
        set { _ = (keyPath, newValue) }
    }

    public subscript(dynamicMember keyPath: WritableKeyPath<CVPixelBufferCreationAttributes, Int?>)
        -> Int?
    {
        get {
            if keyPath == \CVPixelBufferCreationAttributes.bytesPerRowAlignment {
                return bytesPerRowAlignment
            }
            if keyPath == \CVPixelBufferCreationAttributes.planeAlignment {
                return planeAlignment
            }
            return nil
        }
        set {
            if keyPath == \CVPixelBufferCreationAttributes.bytesPerRowAlignment {
                bytesPerRowAlignment = newValue
            }
            if keyPath == \CVPixelBufferCreationAttributes.planeAlignment {
                planeAlignment = newValue
            }
        }
    }
}

extension CVBuffer {
    public typealias OriginPosition = CVImageBufferOriginPosition
    public typealias PlaneProperties = CVPixelBufferPlaneProperties
    public typealias Size = CVImageSize
    public typealias Padding = CVPixelBufferPadding

    @dynamicMemberLookup
    public struct Attributes: Sendable {
        public var rawAttributes: [String: any Sendable]
        public var pixelFormatTypes: [CVPixelFormatType]?
        var size: CVImageSize?
        var compatibility: CVPixelFormatDescription.Compatibility = []
        var bytesPerRowAlignment: Int?
        var planeAlignment: Int?
        var extendedPixels: CVPixelBufferPadding?
        var backing: CreationAttributes.Backing?

        public init(rawAttributes: [String: any Sendable]) {
            self.rawAttributes = rawAttributes
        }

        public init(
            pixelFormatTypes: [CVPixelFormatType]? = nil,
            size: CVImageSize? = nil,
            compatibility: CVPixelFormatDescription.Compatibility = [],
            bytesPerRowAlignment: Int? = nil,
            planeAlignment: Int? = nil,
            extendedPixels: CVPixelBufferPadding? = nil
        ) {
            self.rawAttributes = [:]
            self.pixelFormatTypes = pixelFormatTypes
            self.size = size
            self.compatibility = compatibility
            self.bytesPerRowAlignment = bytesPerRowAlignment
            self.planeAlignment = planeAlignment
            self.extendedPixels = extendedPixels
        }

        public init?(merging values: [Attributes]) {
            guard !values.isEmpty else { return nil }
            var merged = values[0]
            for item in values.dropFirst() {
                if let types = item.pixelFormatTypes { merged.pixelFormatTypes = types }
                if let size = item.size { merged.size = size }
            }
            self = merged
        }

        public init(_ attributes: CreationAttributes) {
            self.init(
                pixelFormatTypes: [attributes.pixelFormatType],
                size: attributes.size,
                compatibility: attributes.compatibility,
                bytesPerRowAlignment: attributes.bytesPerRowAlignment,
                planeAlignment: attributes.planeAlignment,
                extendedPixels: attributes.extendedPixels
            )
            self.backing = attributes.backing
        }

        public subscript(
            dynamicMember keyPath: WritableKeyPath<CreationAttributes, CVImageSize>
        ) -> CVImageSize? {
            get { keyPath == \CreationAttributes.size ? size : nil }
            set { if keyPath == \CreationAttributes.size { size = newValue } }
        }

        public subscript(
            dynamicMember keyPath: WritableKeyPath<CreationAttributes, CVPixelFormatType>
        ) -> CVPixelFormatType? {
            get { keyPath == \CreationAttributes.pixelFormatType ? pixelFormatTypes?.first : nil }
            set {
                if keyPath == \CreationAttributes.pixelFormatType {
                    pixelFormatTypes = newValue.map { [$0] }
                }
            }
        }

        public subscript(
            dynamicMember keyPath: WritableKeyPath<CreationAttributes, CVPixelBufferPadding?>
        ) -> CVPixelBufferPadding? {
            get { keyPath == \CreationAttributes.extendedPixels ? extendedPixels : nil }
            set { if keyPath == \CreationAttributes.extendedPixels { extendedPixels = newValue } }
        }

        public subscript(
            dynamicMember keyPath: WritableKeyPath<
                CreationAttributes, CVPixelFormatDescription.Compatibility
            >
        ) -> CVPixelFormatDescription.Compatibility {
            get { keyPath == \CreationAttributes.compatibility ? compatibility : [] }
            set { if keyPath == \CreationAttributes.compatibility { compatibility = newValue } }
        }

        public subscript(
            dynamicMember keyPath: WritableKeyPath<CreationAttributes, CVPixelFormatDescription?>
        ) -> CVPixelFormatDescription? {
            get { nil }
            set { _ = (keyPath, newValue) }
        }

        public subscript(
            dynamicMember keyPath: WritableKeyPath<CreationAttributes, CreationAttributes.Backing>
        ) -> CreationAttributes.Backing {
            get { keyPath == \CreationAttributes.backing ? (backing ?? .memory) : .memory }
            set { if keyPath == \CreationAttributes.backing { backing = newValue } }
        }

        public subscript(dynamicMember keyPath: WritableKeyPath<CreationAttributes, Bool>) -> Bool? {
            get { nil }
            set { _ = (keyPath, newValue) }
        }

        public subscript(dynamicMember keyPath: WritableKeyPath<CreationAttributes, Int?>) -> Int? {
            get {
                if keyPath == \CreationAttributes.bytesPerRowAlignment { return bytesPerRowAlignment }
                if keyPath == \CreationAttributes.planeAlignment { return planeAlignment }
                return nil
            }
            set {
                if keyPath == \CreationAttributes.bytesPerRowAlignment {
                    bytesPerRowAlignment = newValue
                }
                if keyPath == \CreationAttributes.planeAlignment { planeAlignment = newValue }
            }
        }
    }

    public struct CreationAttributes: Equatable, Sendable {
        public var pixelFormatType: CVPixelFormatType
        public var size: CVImageSize
        public var compatibility: CVPixelFormatDescription.Compatibility
        public var bytesPerRowAlignment: Int?
        public var planeAlignment: Int?
        public var extendedPixels: CVPixelBufferPadding?
        public var backing: Backing

        public enum Backing: Equatable, Sendable {
            case memory
            case ioSurface
            case ioSurfaceWithProperties([String: any Sendable])

            public static func == (lhs: Backing, rhs: Backing) -> Bool {
                switch (lhs, rhs) {
                case (.memory, .memory), (.ioSurface, .ioSurface):
                    return true
                case (.ioSurfaceWithProperties, .ioSurfaceWithProperties):
                    return true
                default:
                    return false
                }
            }
        }

        public init(
            pixelFormatType: CVPixelFormatType,
            size: CVImageSize,
            compatibility: CVPixelFormatDescription.Compatibility = [],
            bytesPerRowAlignment: Int? = nil,
            planeAlignment: Int? = nil,
            extendedPixels: CVPixelBufferPadding? = nil,
            backing: Backing = .memory
        ) {
            self.pixelFormatType = pixelFormatType
            self.size = size
            self.compatibility = compatibility
            self.bytesPerRowAlignment = bytesPerRowAlignment
            self.planeAlignment = planeAlignment
            self.extendedPixels = extendedPixels
            self.backing = backing
        }

        public init?(_ attributes: Attributes) {
            guard let format = attributes.pixelFormatTypes?.first, let size = attributes.size else {
                return nil
            }
            self.init(
                pixelFormatType: format,
                size: size,
                compatibility: attributes.compatibility,
                bytesPerRowAlignment: attributes.bytesPerRowAlignment,
                planeAlignment: attributes.planeAlignment,
                extendedPixels: attributes.extendedPixels,
                backing: attributes.backing ?? .memory
            )
        }
    }
}

func _cvPlaneProperties(of buffer: CVPixelBuffer) -> [CVPixelBufferPlaneProperties] {
    if CVPixelBufferIsPlanar(buffer) {
        return (0..<CVPixelBufferGetPlaneCount(buffer)).map { index in
            CVPixelBufferPlaneProperties(
                size: CVImageSize(
                    width: CVPixelBufferGetWidthOfPlane(buffer, index),
                    height: CVPixelBufferGetHeightOfPlane(buffer, index)
                ),
                bytesPerRow: CVPixelBufferGetBytesPerRowOfPlane(buffer, index)
            )
        }
    }
    return [
        CVPixelBufferPlaneProperties(
            size: CVImageSize(
                width: CVPixelBufferGetWidth(buffer),
                height: CVPixelBufferGetHeight(buffer)
            ),
            bytesPerRow: CVPixelBufferGetBytesPerRow(buffer)
        )
    ]
}

func _cvPadding(of buffer: CVPixelBuffer) -> CVPixelBufferPadding {
    var left = 0
    var right = 0
    var top = 0
    var bottom = 0
    CVPixelBufferGetExtendedPixels(buffer, &left, &right, &top, &bottom)
    return CVPixelBufferPadding(left: left, right: right, top: top, bottom: bottom)
}

func _cvCreationAttributes(of buffer: CVPixelBuffer) -> CVPixelBufferCreationAttributes {
    CVPixelBufferCreationAttributes(
        pixelFormatType: CVPixelFormatType(rawValue: CVPixelBufferGetPixelFormatType(buffer)),
        size: CVImageSize(
            width: CVPixelBufferGetWidth(buffer),
            height: CVPixelBufferGetHeight(buffer)
        ),
        extendedPixels: _cvPadding(of: buffer)
    )
}

public struct CVMutablePixelBuffer: CVPixelBufferRepresentable {
    public typealias Buffer = CVPixelBuffer
    var buffer: CVPixelBuffer

    public init(unsafeBuffer: sending CVPixelBuffer) {
        self.buffer = unsafeBuffer
    }

    public init(_ attributes: CVPixelBufferCreationAttributes) throws {
        if attributes.backing != .memory {
            throw CVError.unsupported
        }
        var created: CVPixelBuffer?
        let status = CVPixelBufferCreate(
            nil,
            attributes.size.width,
            attributes.size.height,
            attributes.pixelFormatType.rawValue,
            attributes.dictionary(),
            &created
        )
        try CVError.check(status)
        guard let created else { throw CVError.allocationFailed }
        self.buffer = created
    }

    public init(
        unsafeBacking ioSurface: IOSurface,
        matching attributes: CVPixelBufferCreationAttributes
    ) throws {
        _ = ioSurface
        _ = attributes
        throw CVError.unsupported
    }

    public func withUnsafeBuffer<R>(_ body: (CVPixelBuffer) throws -> sending R) rethrows -> sending R {
        try body(buffer)
    }

    @discardableResult
    public mutating func fillExtendedPixels() -> Bool {
        CVPixelBufferFillExtendedPixels(buffer) == kCVReturnSuccess
    }

    public mutating func accessUnsafeMutableRawPlaneBytes<R>(
        _ block: ([(properties: CVPixelBufferPlaneProperties, bytes: UnsafeMutableRawBufferPointer)])
            throws -> sending R
    ) rethrows -> sending R {
        _ = CVPixelBufferLockBaseAddress(buffer, [])
        defer { _ = CVPixelBufferUnlockBaseAddress(buffer, []) }
        let planes = _cvPlaneProperties(of: buffer)
        var slices: [(properties: CVPixelBufferPlaneProperties, bytes: UnsafeMutableRawBufferPointer)] =
            []
        if CVPixelBufferIsPlanar(buffer) {
            for (index, properties) in planes.enumerated() {
                let pointer = CVPixelBufferGetBaseAddressOfPlane(buffer, index)
                let count = properties.bytesPerRow * properties.size.height
                slices.append(
                    (
                        properties,
                        UnsafeMutableRawBufferPointer(start: pointer, count: count)
                    )
                )
            }
        } else if let pointer = CVPixelBufferGetBaseAddress(buffer), let properties = planes.first {
            slices.append(
                (
                    properties,
                    UnsafeMutableRawBufferPointer(
                        start: pointer,
                        count: properties.bytesPerRow * properties.size.height
                    )
                )
            )
        }
        return try block(slices)
    }
}

extension CVMutablePixelBuffer {
    public var colorSpace: CGColorSpace? { nil }
    public var displaySize: CGSize { CVImageBufferGetDisplaySize(buffer) }
    public var encodedSize: CGSize { CVImageBufferGetEncodedSize(buffer) }
    public var originPosition: CVImageBufferOriginPosition {
        CVImageBufferIsFlipped(buffer) ? .bottomLeft : .topLeft
    }
    public var cleanRect: CGRect { CVImageBufferGetCleanRect(buffer) }
    public var planeCount: Int {
        let count = CVPixelBufferGetPlaneCount(buffer)
        return count == 0 ? 1 : count
    }
    public var extendedPixels: CVPixelBufferPadding { _cvPadding(of: buffer) }
    public var pixelFormatType: CVPixelFormatType {
        CVPixelFormatType(rawValue: CVPixelBufferGetPixelFormatType(buffer))
    }
    public var planeProperties: [CVPixelBufferPlaneProperties] { _cvPlaneProperties(of: buffer) }
    public func isCompatibleWith(_ attributes: CVPixelBufferAttributes) -> Bool {
        if let created = CVPixelBufferCreationAttributes(attributes) {
            return isCompatibleWith(created)
        }
        return true
    }
    public func isCompatibleWith(_ attributes: CVPixelBufferCreationAttributes) -> Bool {
        CVPixelBufferIsCompatibleWithAttributes(buffer, attributes.dictionary())
    }
    public var creationAttributes: CVPixelBufferCreationAttributes {
        _cvCreationAttributes(of: buffer)
    }
    public func accessUnsafeRawPlaneBytes<R>(
        _ block: ([(properties: CVPixelBufferPlaneProperties, bytes: UnsafeRawBufferPointer)]) throws
            -> sending R
    ) rethrows -> sending R {
        _ = CVPixelBufferLockBaseAddress(buffer, .readOnly)
        defer { _ = CVPixelBufferUnlockBaseAddress(buffer, .readOnly) }
        let planes = _cvPlaneProperties(of: buffer)
        var slices: [(properties: CVPixelBufferPlaneProperties, bytes: UnsafeRawBufferPointer)] = []
        if CVPixelBufferIsPlanar(buffer) {
            for (index, properties) in planes.enumerated() {
                let pointer = CVPixelBufferGetBaseAddressOfPlane(buffer, index)
                slices.append(
                    (
                        properties,
                        UnsafeRawBufferPointer(
                            start: pointer,
                            count: properties.bytesPerRow * properties.size.height
                        )
                    )
                )
            }
        } else if let pointer = CVPixelBufferGetBaseAddress(buffer), let properties = planes.first {
            slices.append(
                (
                    properties,
                    UnsafeRawBufferPointer(
                        start: pointer,
                        count: properties.bytesPerRow * properties.size.height
                    )
                )
            )
        }
        return try block(slices)
    }
    public func withUnsafeBackingIOSurfaceIfPresent<R>(
        _ block: (IOSurface) throws -> sending R
    ) rethrows -> sending R? {
        _ = block
        return nil
    }
    public var size: CVImageSize {
        CVImageSize(width: CVPixelBufferGetWidth(buffer), height: CVPixelBufferGetHeight(buffer))
    }
    public var isPlanar: Bool { CVPixelBufferIsPlanar(buffer) }
}

extension CVMutablePixelBuffer {
    public final class Pool: @unchecked Sendable {
        public struct Configuration: Equatable, Sendable {
            public var ageOutDuration: TimeInterval
            public var minimumBufferCount: Int
            public var prefetchOnAllocation: Bool
            public var name: String?
            public init(ageOutDuration: TimeInterval = 1, minimumBufferCount: Int = 0) {
                self.ageOutDuration = ageOutDuration
                self.minimumBufferCount = minimumBufferCount
                self.prefetchOnAllocation = false
                self.name = nil
            }
        }

        public struct AllocationAttributes: Equatable, Sendable {
            public var allocationThreshold: Int?
            public init(allocationThreshold: Int? = nil) {
                self.allocationThreshold = allocationThreshold
            }
        }

        public let pixelBufferAttributes: CVPixelBufferCreationAttributes
        let pool: CVPixelBufferPool
        public var minimumBufferCount: Int

        public init(
            pixelBufferAttributes attributes: CVPixelBufferCreationAttributes,
            configuration: Configuration = .init()
        ) throws {
            self.pixelBufferAttributes = attributes
            self.minimumBufferCount = configuration.minimumBufferCount
            let poolAttrs = NSMutableDictionary()
            poolAttrs[kCVPixelBufferPoolMinimumBufferCountKey] =
                _cvNumber(configuration.minimumBufferCount)
            var created: CVPixelBufferPool?
            let status = CVPixelBufferPoolCreate(
                nil,
                poolAttrs,
                attributes.dictionary(),
                &created
            )
            try CVError.check(status)
            guard let created else { throw CVError.poolAllocationFailed }
            self.pool = created
        }

        public init(unsafePool: sending CVPixelBufferPool) {
            self.pool = unsafePool
            self.minimumBufferCount = 0
            self.pixelBufferAttributes = CVPixelBufferCreationAttributes(
                pixelFormatType: CVPixelFormatType(rawValue: kCVPixelFormatType_32BGRA),
                size: .zero
            )
        }

        public func makeMutablePixelBuffer(
            _ attributes: AllocationAttributes = .init()
        ) throws -> CVMutablePixelBuffer {
            var aux: NSMutableDictionary?
            if let threshold = attributes.allocationThreshold {
                aux = [kCVPixelBufferPoolAllocationThresholdKey: _cvNumber(threshold)]
            }
            var created: CVPixelBuffer?
            let status = CVPixelBufferPoolCreatePixelBufferWithAuxAttributes(
                nil,
                pool,
                aux,
                &created
            )
            try CVError.check(status)
            guard let created else { throw CVError.poolAllocationFailed }
            return CVMutablePixelBuffer(unsafeBuffer: created)
        }

        public func flush(agedOutOnly: Bool = true) {
            CVPixelBufferPoolFlush(pool, agedOutOnly ? .excessBuffers : [])
        }

        public func preallocate(allowMultipleThreads: Bool) throws {
            _ = allowMultipleThreads
            for _ in 0..<max(minimumBufferCount, 0) {
                _ = try makeMutablePixelBuffer()
            }
        }
    }
}

public final class CVReadOnlyPixelBuffer: CVPixelBufferRepresentable, @unchecked Sendable {
    public typealias Buffer = CVPixelBuffer
    let buffer: CVPixelBuffer

    public init(unsafeBuffer: sending CVPixelBuffer) {
        self.buffer = unsafeBuffer
    }

    public init(_ mutableBuffer: consuming CVMutablePixelBuffer) {
        self.buffer = mutableBuffer.buffer
    }

    public func withUnsafeBuffer<R>(_ body: (CVPixelBuffer) throws -> sending R) rethrows -> sending R {
        try body(buffer)
    }

    public var colorSpace: CGColorSpace? { nil }
    public var displaySize: CGSize { CVImageBufferGetDisplaySize(buffer) }
    public var encodedSize: CGSize { CVImageBufferGetEncodedSize(buffer) }
    public var originPosition: CVImageBufferOriginPosition {
        CVImageBufferIsFlipped(buffer) ? .bottomLeft : .topLeft
    }
    public var cleanRect: CGRect { CVImageBufferGetCleanRect(buffer) }
    public var planeCount: Int {
        let count = CVPixelBufferGetPlaneCount(buffer)
        return count == 0 ? 1 : count
    }
    public var extendedPixels: CVPixelBufferPadding { _cvPadding(of: buffer) }
    public var pixelFormatType: CVPixelFormatType {
        CVPixelFormatType(rawValue: CVPixelBufferGetPixelFormatType(buffer))
    }
    public var planeProperties: [CVPixelBufferPlaneProperties] { _cvPlaneProperties(of: buffer) }
    public func isCompatibleWith(_ attributes: CVPixelBufferAttributes) -> Bool {
        if let created = CVPixelBufferCreationAttributes(attributes) {
            return isCompatibleWith(created)
        }
        return true
    }
    public func isCompatibleWith(_ attributes: CVPixelBufferCreationAttributes) -> Bool {
        CVPixelBufferIsCompatibleWithAttributes(buffer, attributes.dictionary())
    }
    public var creationAttributes: CVPixelBufferCreationAttributes {
        _cvCreationAttributes(of: buffer)
    }
    public func accessUnsafeRawPlaneBytes<R>(
        _ block: ([(properties: CVPixelBufferPlaneProperties, bytes: UnsafeRawBufferPointer)]) throws
            -> sending R
    ) rethrows -> sending R {
        _ = CVPixelBufferLockBaseAddress(buffer, .readOnly)
        defer { _ = CVPixelBufferUnlockBaseAddress(buffer, .readOnly) }
        let planes = _cvPlaneProperties(of: buffer)
        var slices: [(properties: CVPixelBufferPlaneProperties, bytes: UnsafeRawBufferPointer)] = []
        if CVPixelBufferIsPlanar(buffer) {
            for (index, properties) in planes.enumerated() {
                let pointer = CVPixelBufferGetBaseAddressOfPlane(buffer, index)
                slices.append(
                    (
                        properties,
                        UnsafeRawBufferPointer(
                            start: pointer,
                            count: properties.bytesPerRow * properties.size.height
                        )
                    )
                )
            }
        } else if let pointer = CVPixelBufferGetBaseAddress(buffer), let properties = planes.first {
            slices.append(
                (
                    properties,
                    UnsafeRawBufferPointer(
                        start: pointer,
                        count: properties.bytesPerRow * properties.size.height
                    )
                )
            )
        }
        return try block(slices)
    }
    public func withUnsafeBackingIOSurfaceIfPresent<R>(
        _ block: (IOSurface) throws -> sending R
    ) rethrows -> sending R? {
        _ = block
        return nil
    }
    public var size: CVImageSize {
        CVImageSize(width: CVPixelBufferGetWidth(buffer), height: CVPixelBufferGetHeight(buffer))
    }
    public var isPlanar: Bool { CVPixelBufferIsPlanar(buffer) }
}
