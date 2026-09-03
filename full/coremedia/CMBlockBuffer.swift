import CoreFoundation
import Foundation

internal protocol CMBlockBufferProtocol: AnyObject {
    var dataLength: Int { get }
    func copyDataBytes(to destination: UnsafeMutableRawBufferPointer) throws
    func dataBytes() throws -> Data
}

public final class CMBlockBuffer: CMBlockBufferProtocol, CMAttachmentBearerProtocol, @unchecked Sendable {
    public struct Flags: OptionSet, Sendable, Hashable {
        public let rawValue: UInt32
        public init(rawValue: UInt32) { self.rawValue = rawValue }
        public static let assureMemoryNow = Flags(rawValue: kCMBlockBufferAssureMemoryNowFlag)
        public static let alwaysCopyData = Flags(rawValue: kCMBlockBufferAlwaysCopyDataFlag)
        public static let dontOptimizeDepth = Flags(rawValue: kCMBlockBufferDontOptimizeDepthFlag)
        public static let permitEmptyReference = Flags(rawValue: kCMBlockBufferPermitEmptyReferenceFlag)
    }

    public struct Error {
        public static let structureAllocationFailed = cmNSError(code: -12700)
        public static let blockAllocationFailed = cmNSError(code: -12701)
        public static let badCustomBlockSource = cmNSError(code: -12702)
        public static let badOffsetParameter = cmNSError(code: -12703)
        public static let badLengthParameter = cmNSError(code: -12704)
        public static let badPointerParameter = cmNSError(code: -12705)
        public static let emptyBlockBuffer = cmNSError(code: -12706)
        public static let unallocatedBlock = cmNSError(code: -12707)
        public static let insufficientSpace = cmNSError(code: -12708)
    }

    private static let processTypeID: CFTypeID = 0x434D_4242
    public static var typeID: CFTypeID { processTypeID }

    public typealias T = CMBlockBuffer
    public typealias CustomBlockAllocator = (Int) -> UnsafeMutableRawPointer?
    public typealias CustomBlockDeallocator = (UnsafeMutableRawPointer, Int) -> Void

    private let lock = CMUnfairLock()
    private var storage: [UInt8]
    public var attachments = CMAttachmentBearerAttachments()
    public var startIndex: Int { 0 }

    public var dataLength: Int {
        lock.locked { storage.count }
    }

    public var isEmpty: Bool { dataLength == 0 }
    public var isContiguous: Bool { true }

    public init() {
        self.storage = []
    }

    public init(copying bytes: UnsafeRawBufferPointer) {
        self.storage = Array(bytes)
    }

    public init(data: Data) {
        self.storage = Array(data)
    }

    public init(referencing object: CMBlockBuffer) {
        self.storage = object.lock.locked { object.storage }
        self.attachments = object.attachments
    }

    public func copyDataBytes(to destination: UnsafeMutableRawBufferPointer) throws {
        try lock.locked {
            if destination.count < storage.count {
                throw Error.insufficientSpace
            }
            if storage.isEmpty { return }
            guard let base = destination.baseAddress else {
                throw Error.badPointerParameter
            }
            storage.withUnsafeBytes { source in
                base.copyMemory(from: source.baseAddress!, byteCount: storage.count)
            }
        }
    }

    public func dataBytes() throws -> Data {
        lock.locked { Data(storage) }
    }

    public func copyDataBytes(
        atOffset offset: Int,
        dataLength length: Int,
        destination: UnsafeMutableRawPointer
    ) throws {
        try lock.locked {
            if offset < 0 { throw Error.badOffsetParameter }
            if length < 0 { throw Error.badLengthParameter }
            if offset > storage.count || length > storage.count - offset {
                throw Error.badOffsetParameter
            }
            if length == 0 { return }
            storage.withUnsafeBytes { source in
                destination.copyMemory(
                    from: source.baseAddress!.advanced(by: offset),
                    byteCount: length
                )
            }
        }
    }

    public func withUnsafeMutableBytes<R>(
        atOffset offset: Int = 0,
        _ body: (UnsafeMutableRawBufferPointer) throws -> R
    ) throws -> R {
        try lock.locked {
            if offset < 0 || offset > storage.count {
                throw Error.badOffsetParameter
            }
            return try storage.withUnsafeMutableBytes { buffer in
                try body(UnsafeMutableRawBufferPointer(rebasing: buffer[offset...]))
            }
        }
    }

    public func assureBlockMemory() throws {}
}

public func CMBlockBufferGetDataLength(_ theBuffer: CMBlockBuffer) -> Int {
    theBuffer.dataLength
}

public func CMBlockBufferIsEmpty(_ theBuffer: CMBlockBuffer) -> Bool {
    theBuffer.isEmpty
}

public func CMBlockBufferGetTypeID() -> CFTypeID {
    CMBlockBuffer.typeID
}

internal func CMBlockBufferIsRangeValid(
    _ theBuffer: CMBlockBuffer,
    atOffset offsetToData: Int,
    dataLength: Int
) -> Bool {
    offsetToData >= 0 && dataLength >= 0 && offsetToData <= theBuffer.dataLength
        && dataLength <= theBuffer.dataLength - offsetToData
}
