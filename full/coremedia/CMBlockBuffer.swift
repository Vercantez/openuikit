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
    public var owner: CMBlockBuffer { self }
    public var endIndex: Int { dataLength }

    public init() {
        self.storage = []
    }

    public init(copying bytes: UnsafeRawBufferPointer) {
        self.storage = Array(bytes)
    }

    public init(data: Data) {
        self.storage = Array(data)
    }

    public init(length: Int) {
        self.storage = Array(repeating: 0, count: max(0, length))
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

    public func fillDataBytes(with fillByte: UInt8) throws {
        lock.locked {
            for index in storage.indices {
                storage[index] = fillByte
            }
        }
    }

    public func replaceDataBytes(with sourceBytes: UnsafeRawBufferPointer) throws {
        try lock.locked {
            if sourceBytes.count > storage.count {
                throw Error.insufficientSpace
            }
            for index in 0..<sourceBytes.count {
                storage[index] = sourceBytes[index]
            }
        }
    }

    public func append(length: Int) throws {
        if length < 0 { throw Error.badLengthParameter }
        lock.locked {
            storage.append(contentsOf: Array(repeating: 0, count: length))
        }
    }
}

public struct CMBlockBufferCustomBlockSource {
    public var version: UInt32
    public var AllocateBlock: ((UnsafeMutableRawPointer?, Int) -> UnsafeMutableRawPointer?)?
    public var FreeBlock: ((UnsafeMutableRawPointer?, UnsafeMutableRawPointer, Int) -> Void)?
    public var refCon: UnsafeMutableRawPointer?

    public init() {
        self.version = kCMBlockBufferCustomBlockSourceVersion
        self.AllocateBlock = nil
        self.FreeBlock = nil
        self.refCon = nil
    }

    public init(
        version: UInt32,
        AllocateBlock: ((UnsafeMutableRawPointer?, Int) -> UnsafeMutableRawPointer?)?,
        FreeBlock: ((UnsafeMutableRawPointer?, UnsafeMutableRawPointer, Int) -> Void)?,
        refCon: UnsafeMutableRawPointer?
    ) {
        self.version = version
        self.AllocateBlock = AllocateBlock
        self.FreeBlock = FreeBlock
        self.refCon = refCon
    }
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

public func CMBlockBufferCreateEmpty(
    allocator structureAllocator: CFAllocator?,
    capacity subBlockCapacity: UInt32,
    flags: CMBlockBufferFlags,
    blockBufferOut: UnsafeMutablePointer<CMBlockBuffer?>
) -> OSStatus {
    _ = (structureAllocator, subBlockCapacity, flags)
    blockBufferOut.pointee = CMBlockBuffer()
    return kCMBlockBufferNoErr
}

public func CMBlockBufferCreateWithMemoryBlock(
    allocator structureAllocator: CFAllocator?,
    memoryBlock: UnsafeMutableRawPointer?,
    blockLength: Int,
    blockAllocator: CFAllocator?,
    customBlockSource: UnsafePointer<CMBlockBufferCustomBlockSource>?,
    offsetToData: Int,
    dataLength: Int,
    flags: CMBlockBufferFlags,
    blockBufferOut: UnsafeMutablePointer<CMBlockBuffer?>
) -> OSStatus {
    _ = (structureAllocator, blockAllocator, customBlockSource, flags)
    if offsetToData < 0 { return kCMBlockBufferBadOffsetParameterErr }
    if dataLength < 0 { return kCMBlockBufferBadLengthParameterErr }
    if offsetToData > blockLength || dataLength > blockLength - offsetToData {
        return kCMBlockBufferBadOffsetParameterErr
    }
    if let memoryBlock {
        let buffer = UnsafeRawBufferPointer(start: memoryBlock.advanced(by: offsetToData), count: dataLength)
        blockBufferOut.pointee = CMBlockBuffer(copying: buffer)
    } else {
        blockBufferOut.pointee = CMBlockBuffer(length: dataLength)
    }
    return kCMBlockBufferNoErr
}

public func CMBlockBufferCreateWithBufferReference(
    allocator structureAllocator: CFAllocator?,
    referenceBuffer bufferReference: CMBlockBuffer,
    offsetToData: Int,
    dataLength: Int,
    flags: CMBlockBufferFlags,
    blockBufferOut: UnsafeMutablePointer<CMBlockBuffer?>
) -> OSStatus {
    _ = (structureAllocator, flags)
    if !CMBlockBufferIsRangeValid(bufferReference, atOffset: offsetToData, dataLength: dataLength) {
        return kCMBlockBufferBadOffsetParameterErr
    }
    do {
        let data = try bufferReference.dataBytes()
        let slice = data.dropFirst(offsetToData).prefix(dataLength)
        blockBufferOut.pointee = CMBlockBuffer(data: Data(slice))
        return kCMBlockBufferNoErr
    } catch {
        return kCMBlockBufferBadPointerParameterErr
    }
}

public func CMBlockBufferCreateContiguous(
    allocator structureAllocator: CFAllocator?,
    sourceBuffer: CMBlockBuffer,
    blockAllocator: CFAllocator?,
    customBlockSource: UnsafePointer<CMBlockBufferCustomBlockSource>?,
    offsetToData: Int,
    dataLength: Int,
    flags: CMBlockBufferFlags,
    blockBufferOut: UnsafeMutablePointer<CMBlockBuffer?>
) -> OSStatus {
    CMBlockBufferCreateWithBufferReference(
        allocator: structureAllocator,
        referenceBuffer: sourceBuffer,
        offsetToData: offsetToData,
        dataLength: dataLength == 0 ? sourceBuffer.dataLength : dataLength,
        flags: flags,
        blockBufferOut: blockBufferOut
    )
}

public func CMBlockBufferCopyDataBytes(
    _ theSourceBuffer: CMBlockBuffer,
    atOffset offsetToData: Int,
    dataLength: Int,
    destination: UnsafeMutableRawPointer
) -> OSStatus {
    do {
        try theSourceBuffer.copyDataBytes(
            atOffset: offsetToData,
            dataLength: dataLength,
            destination: destination
        )
        return kCMBlockBufferNoErr
    } catch let error as NSError {
        return OSStatus(error.code)
    } catch {
        return kCMBlockBufferBadPointerParameterErr
    }
}

public func CMBlockBufferFillDataBytes(
    with fillByte: CChar,
    blockBuffer destinationBuffer: CMBlockBuffer,
    offsetIntoDestination: Int,
    dataLength: Int
) -> OSStatus {
    if !CMBlockBufferIsRangeValid(
        destinationBuffer,
        atOffset: offsetIntoDestination,
        dataLength: dataLength
    ) {
        return kCMBlockBufferBadOffsetParameterErr
    }
    do {
        try destinationBuffer.withUnsafeMutableBytes(atOffset: offsetIntoDestination) { buffer in
            for index in 0..<dataLength {
                buffer[index] = UInt8(bitPattern: fillByte)
            }
        }
        return kCMBlockBufferNoErr
    } catch let error as NSError {
        return OSStatus(error.code)
    } catch {
        return kCMBlockBufferBadPointerParameterErr
    }
}

public func CMBlockBufferReplaceDataBytes(
    with sourceBytes: UnsafeRawPointer,
    blockBuffer destinationBuffer: CMBlockBuffer,
    offsetIntoDestination: Int,
    dataLength: Int
) -> OSStatus {
    if !CMBlockBufferIsRangeValid(
        destinationBuffer,
        atOffset: offsetIntoDestination,
        dataLength: dataLength
    ) {
        return kCMBlockBufferBadOffsetParameterErr
    }
    do {
        try destinationBuffer.withUnsafeMutableBytes(atOffset: offsetIntoDestination) { buffer in
            buffer.baseAddress!.copyMemory(from: sourceBytes, byteCount: dataLength)
        }
        return kCMBlockBufferNoErr
    } catch let error as NSError {
        return OSStatus(error.code)
    } catch {
        return kCMBlockBufferBadPointerParameterErr
    }
}

public func CMBlockBufferAssureBlockMemory(_ theBuffer: CMBlockBuffer) -> OSStatus {
    do {
        try theBuffer.assureBlockMemory()
        return kCMBlockBufferNoErr
    } catch {
        return kCMBlockBufferUnallocatedBlockErr
    }
}

public func CMBlockBufferIsRangeContiguous(
    _ theBuffer: CMBlockBuffer,
    atOffset offset: Int,
    length: Int
) -> Bool {
    CMBlockBufferIsRangeValid(theBuffer, atOffset: offset, dataLength: length) && theBuffer.isContiguous
}

public func CMBlockBufferAppendMemoryBlock(
    _ theBuffer: CMBlockBuffer,
    memoryBlock: UnsafeMutableRawPointer?,
    length: Int,
    blockAllocator: CFAllocator?,
    customBlockSource: UnsafePointer<CMBlockBufferCustomBlockSource>?,
    offsetToData: Int,
    dataLength: Int,
    flags: CMBlockBufferFlags
) -> OSStatus {
    _ = (blockAllocator, customBlockSource, flags)
    if length < 0 || dataLength < 0 { return kCMBlockBufferBadLengthParameterErr }
    if offsetToData < 0 { return kCMBlockBufferBadOffsetParameterErr }
    do {
        if let memoryBlock {
            let slice = UnsafeRawBufferPointer(
                start: memoryBlock.advanced(by: offsetToData),
                count: dataLength
            )
            try theBuffer.lockAppend(slice)
        } else {
            try theBuffer.append(length: dataLength)
        }
        return kCMBlockBufferNoErr
    } catch let error as NSError {
        return OSStatus(error.code)
    } catch {
        return kCMBlockBufferBadPointerParameterErr
    }
}

public func CMBlockBufferAppendBufferReference(
    _ theBuffer: CMBlockBuffer,
    targetBBuf: CMBlockBuffer,
    offsetToData: Int,
    dataLength: Int,
    flags: CMBlockBufferFlags
) -> OSStatus {
    _ = flags
    do {
        let data = try targetBBuf.dataBytes()
        if offsetToData < 0 || offsetToData > data.count { return kCMBlockBufferBadOffsetParameterErr }
        let slice = data.dropFirst(offsetToData).prefix(dataLength == 0 ? data.count - offsetToData : dataLength)
        try slice.withUnsafeBytes { bytes in
            try theBuffer.lockAppend(bytes)
        }
        return kCMBlockBufferNoErr
    } catch let error as NSError {
        return OSStatus(error.code)
    } catch {
        return kCMBlockBufferBadPointerParameterErr
    }
}

extension CMBlockBuffer {
    fileprivate func lockAppend(_ bytes: UnsafeRawBufferPointer) throws {
        lock.locked {
            storage.append(contentsOf: bytes)
        }
    }
}

internal func CMBlockBufferIsRangeValid(
    _ theBuffer: CMBlockBuffer,
    atOffset offsetToData: Int,
    dataLength: Int
) -> Bool {
    offsetToData >= 0 && dataLength >= 0 && offsetToData <= theBuffer.dataLength
        && dataLength <= theBuffer.dataLength - offsetToData
}
